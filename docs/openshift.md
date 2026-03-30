# OpenShift

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Route](#route)
- [Security Context Constraints](#security-context-constraints)
- [BuildConfig e ImageStream](#buildconfig-e-imagestream)
- [Operator e lifecycle](#operator-e-lifecycle)
- [Differenze da Kubernetes vanilla](#differenze-da-kubernetes-vanilla)
- [S2I, Template e risorse](#s2i-template-e-risorse)
- [Monitoring, GitOps e Tekton](#monitoring-gitops-e-tekton)
- [Failure mode e best practice](#failure-mode-e-best-practice)

## Panoramica

OpenShift è una piattaforma Kubernetes enterprise (Red Hat) che aggiunge route, Security Context Constraints (SCC), build integrati (BuildConfig, ImageStream), operator e strumenti di sviluppo. I container sono costruiti con [Docker](docker.md) o direttamente su OpenShift; il runtime è [Kubernetes](kubernetes.md) con estensioni. In uno stack tipico OpenShift orchestra i workload, espone le applicazioni tramite Route e gestisce build e immagini con ImageStream; le [Pipeline](pipeline.md) possono deployare su OpenShift e usare [Helm](helm.md) dove appropriato.

---

## Route

### Concetto

La **Route** è la risorsa OpenShift per esporre un Service HTTP/HTTPS verso l'esterno. Gestisce hostname, TLS (edge, passthrough, reencrypt) e integrazione con il router del cluster. È l'equivalente operativo dell'Ingress in Kubernetes, con gestione TLS e dominio spesso più integrata.

### Flusso operativo

1. Creare un Service che espone i Pod dell'applicazione.
2. Esporre il Service con una Route: `oc expose svc/nome` o manifest Route con host e TLS.
3. Il router OpenShift instrada il traffico esterno al Service (e ai Pod).

### Comando/esempio

```bash
# Esposizione rapida (host auto-generato)
oc expose svc/my-api --name=my-api-route

# Verifica
oc get route my-api-route

# Con host e TLS (manifest)
# spec.host, spec.tls (termination: edge|passthrough|reencrypt)
```

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: my-api
spec:
  host: api.myapp.example.com
  to:
    kind: Service
    name: my-api
  tls:
    termination: edge
  port:
    targetPort: 8080
```

### Failure mode comune

Route con host errato o Service inesistente: il router non instrada correttamente; verificare `oc get route` e `oc get svc` e che il Service abbia endpoint (selector che matcha i Pod).

### Best practice

Usare Route per HTTP/HTTPS esterno; TLS in produzione; naming coerente Route/Service; in cluster multi-tenant rispettare limiti e quote di progetto.

---

## Security Context Constraints

### Concetto

Le **Security Context Constraints (SCC)** sono policy cluster-wide che limitano quali security context possono usare i Pod (runAsUser, runAsGroup, fsGroup, capability, volume types, ecc.). OpenShift applica SCC di default più restrittive di Kubernetes: ad esempio **restricted-v2** richiede runAsNonRoot e blocca l'uso di root. Se il Pod richiede privilegi non consentiti dalla SCC assegnata al progetto/ServiceAccount, la creazione del Pod viene rifiutata.

### Flusso operativo

1. Il Pod viene creato con un security context (es. runAsUser, allowPrivilegeEscalation).
2. OpenShift valuta le SCC disponibili per il ServiceAccount del Pod; se nessuna SCC soddisfa i requisiti, il Pod resta in stato di failure (es. "violates PodSecurity").
3. Verificare: `oc describe pod`, eventi; eventualmente usare SCC custom o aggiungere il ServiceAccount a una SCC esistente (con attenzione alla sicurezza).

### Comando/esempio

```bash
# SCC disponibili
oc get scc

# Dettaglio su una SCC
oc describe scc restricted-v2

# Verificare perché un Pod non parte (eventi)
oc get events
oc describe pod <pod-name>
```

### Failure mode comune

Image o Dockerfile che richiedono root (USER root o nessun USER): il Pod viene rifiutato da SCC restricted; l'app non parte. Soluzione: buildare image con utente non-root e eventualmente adattare fsGroup/runAsUser nei limiti della SCC.

### Best practice

Mantenere sicurezza by default; preferire image che girano come non-root; creare SCC custom solo quando necessario e con scope minimo; documentare i requisiti di sicurezza per ogni applicazione.

---

## BuildConfig e ImageStream

### Concetto

**BuildConfig** definisce come OpenShift costruisce un'image (da Dockerfile, da source con S2I, da altro build). **ImageStream** è un riferimento a un'image (tag) nel registry interno; semplifica il riferimento a immagini prodotte da build o importate. Il build pusha l'output verso un ImageStream; i Deployment referenziano l'ImageStream (o l'image direttamente).

### Flusso operativo

1. Creare BuildConfig (source Git + strategy Dockerfile o S2I, output ImageStream).
2. Eseguire il build: `oc start-build nome-buildconfig` o trigger su push Git.
3. L'image viene pushata nel registry del cluster e aggiorna l'ImageStream; il Deployment può usare `image: imageStreamTag` per il roll-out automatico su nuova image.

### Comando/esempio

```bash
# Build da Dockerfile (es. da bc esistente)
oc start-build myapp --follow

# Verifica ImageStream
oc get is
oc describe is myapp

# Deploy che usa ImageStream
# spec.containers[].image: image-registry.openshift-image-registry.svc:5000/progetto/myapp:latest
```

### Failure mode comune

BuildConfig che punta a repo/context errati: build fallisce; ImageStream non aggiornato e il deploy usa image vecchia. Verificare log del build e permessi su Git/registry.

### Best practice

Usare ImageStream per riferire le image prodotte nel cluster; evitare `latest` in produzione (tag espliciti); integrare build con pipeline (webhook, trigger) per build automatici; scan vulnerabilità sulle image buildate.

---

## Operator e lifecycle

### Concetto

Un **Operator** estende Kubernetes con logica applicativa: combina Custom Resource Definition (CRD) e controller che reagiscono agli eventi sulle risorse custom. In OpenShift gli Operator sono il modello per gestire componenti come DB, monitoraggio, middleware: installazione, upgrade, backup, configurazione dichiarativa tramite risorse custom invece che solo manifest statici.

### Flusso operativo

1. Installare un Operator (da OLM o manifest) nel cluster; l'Operator registra CRD e avvia i controller.
2. L'utente crea risorse custom (es. `PostgresCluster`); il controller applica lo stato desiderato (crea Pod, Service, PVC, ecc.) e gestisce il lifecycle.

### Comando/esempio

```bash
# Operator installati nel cluster
oc get clusterserviceversion

# Risorse custom gestite da un Operator
oc get postgrescluster
oc describe postgrescluster my-db
```

### Failure mode comune

Operator non aggiornato o CRD incompatibili dopo upgrade: le risorse custom possono non essere riconciliate correttamente; verificare compatibility matrix e procedure di upgrade dell'Operator.

### Best practice

Usare Operator da cataloghi certificati; versionare e testare upgrade in staging; documentare le CRD usate e le dipendenze tra Operator; limitare i permessi RBAC degli Operator al minimo necessario.

---

## Differenze da Kubernetes vanilla

| Aspetto | Kubernetes | OpenShift |
|--------|-------------|-----------|
| Esposizione HTTP esterna | Ingress + controller | Route (integrata, TLS) |
| Sicurezza Pod | Pod Security Standards / admission | SCC (restricted-v2, anyuid, ecc.) |
| Build image | Esterno (CI, Docker build) | BuildConfig + ImageStream (integrato) |
| Registry | Esterno o installato | Registry interno + ImageStream |
| CLI | kubectl | oc (superset: build, route, project) |
| Multitenancy | Namespace | Project (namespace + quota, limit) |

### Impatto operativo

- Su OpenShift i Pod devono rispettare le SCC; le image che richiedono root vanno adattate o si usano SCC meno restrittive con giustificazione.
- Route sostituisce spesso l'Ingress per semplicità e integrazione TLS.
- Build e image possono restare nel cluster (BuildConfig → ImageStream) riducendo dipendenze da registry esterni per lo sviluppo.

---

## Failure mode e best practice

### Failure mode comuni

- **Pod bloccato da SCC**: security context non consentito; correggere image (non-root) o valutare SCC custom con approval sicurezza.
- **Route non raggiungibile**: host errato, Service senza endpoint, firewall/DNS; verificare route, svc, selector e connettività dal router.
- **Build fallito**: Git inaccessibile, Dockerfile errato, risorse insufficienti; controllare log del build e BuildConfig.

### Best practice enterprise

- Sicurezza by default: image non-root, SCC restrittive, scan image.
- Usare ImageStream e BuildConfig per tracciabilità e build riproducibili nel cluster.
- Documentare Route, host e TLS per ogni ambiente; evitare secret in chiaro nei manifest.
- Operator: scelta da cataloghi ufficiali, upgrade pianificati e testati; rollback procedure per Operator e CR.

---

## S2I, Template e risorse

### Source-to-Image (S2I)
**Concetto**  
S2I costruisce image da codice sorgente senza Dockerfile: un'image builder (es. node, python) clona il repo, esegue script di build (assemble) e produce un'image runnable. BuildConfig con strategy source e image builder; il risultato viene pushato in ImageStream.

**Flusso operativo**  
Creare BuildConfig con source (Git URI) e strategy type Source; image builder scelto in base al linguaggio. Build avviata da webhook o da `oc start-build`; output in ImageStream.

**Failure mode comune**  
Build che fallisce per dipendenze mancanti o script assemble errato; cache dipendenze per velocizzare. Best practice: usare builder image ufficiali; testare assemble in locale se possibile.

### Templates e parametrizzazione
**Concetto**  
Un **Template** è un oggetto OpenShift che contiene una lista di risorse (Deployment, Service, Route, ecc.) con parametri sostituibili (`${PARAM}`). L'utente istanzia il template fornendo i valori; OpenShift crea le risorse. Utile per cataloghi e deploy ripetibili per ambiente.

**Flusso operativo**  
`oc process -f template.yaml -p KEY=value | oc apply -f -`; oppure da web console compilando i parametri. Parametri con default e descrizione per chiarezza.

**Failure mode comune**  
Parametri obbligatori mancanti; template che crea risorse in namespace sbagliato. Best practice: documentare parametri; usare LimitRange/ResourceQuota nel template dove appropriato.

### LimitRange e ResourceQuota
**Concetto**  
**LimitRange**: definisce default e limiti min/max per richieste e limiti di risorse (CPU, memoria) dei container in un namespace. **ResourceQuota**: limita il totale di risorse (CPU, memoria, numero di pod, PVC) utilizzabili nel namespace.

**Flusso operativo**  
LimitRange evita che i pod vengano creati senza requests/limits; ResourceQuota evita che un namespace esaurisca le risorse del cluster. Essenziali in multi-tenant.

**Failure mode comune**  
Quota troppo stretta che blocca deploy; LimitRange con default troppo alti. Best practice: quota per namespace per ambiente; LimitRange con default ragionevoli.

### Network policy e SDN OpenShift
**Concetto**  
OpenShift usa un SDN (Software-Defined Network) che assegna pod network e policy. Le **NetworkPolicy** (risorsa Kubernetes) restringono traffico ingress/egress; OpenShift può avere policy default per namespace (multitenancy). Documentare il plugin SDN in uso (OVN, OpenShiftSDN).

**Failure mode comune**  
Policy che blocca traffico necessario (DNS, API server); isolamento eccessivo che rompe comunicazione tra servizi. Best practice: policy esplicite per app critiche; test in staging.

---

## Monitoring, GitOps e Tekton

### Monitoring e logging (OpenShift)
**Concetto**  
OpenShift può includere stack di monitoring (Prometheus, Grafana) e logging (Loki, Elasticsearch, Fluentd) tramite operator (Observability Operator, OpenShift Logging). Metriche su nodi, pod, container e applicazioni; log centralizzati da stdout dei container.

**Caso d'uso**  
Dashboard e alert su utilizzo risorse, latenza, error rate; log per debug e audit. Integrazione con pipeline per notifiche su failure.

**Best practice**  
Retention e storage per metriche e log; alert su soglie e su failure deploy; non loggare secret.

### GitOps su OpenShift (cenni)
**Concetto**  
GitOps: stato desiderato del cluster (manifest, Helm, Kustomize) in repo Git; uno strumento (ArgoCD, Flux) riconcilia il cluster con il repo. Su OpenShift si deployano Route, BuildConfig, Deployment come in Kubernetes; l'operator legge da Git e applica.

**Caso d'uso**  
Deploy dichiarativo e auditable; rollback tramite revert commit; ambienti multipli con branch o directory diverse.

**Failure mode comune**  
Drift tra cluster e Git non rilevato; secret in Git (usare Sealed Secrets o Vault). Best practice: repo separati o path per ambiente; PR per cambi a prod.

### Pipeline OpenShift (Tekton)
**Concetto**  
Tekton è un framework CI/CD nativo per Kubernetes/OpenShift: Task e Pipeline come CRD; risorse (PipelineResource o workspace) per codice e artefatti. Integrazione con BuildConfig: una pipeline può avviare build e deploy da ImageStream.

**Flusso operativo**  
Definire Task (step container) e Pipeline (sequenza di Task); Trigger (webhook, cron) avviano PipelineRun. Output verso registry e cluster; integrazione con OpenShift per Route e deploy.

**Failure mode comune**  
Task che non puliscono workspace; secret non iniettati correttamente. Best practice: Task riutilizzabili; workspace per passaggio artefatti; uso di cataloghi Tekton per task comuni.

## In sintesi

- Route: esposizione HTTP/TLS; oc expose svc; host e TLS configurabili; alternativa a Ingress.
- SCC: Security Context Constraints; Pod devono rispettarle; image non-root; anyuid con cautela.
- BuildConfig e ImageStream: build nel cluster; ImageStream per tracciare image; deploy da ImageStream.
- Operator: estensioni CRD e controller; oc get clusterserviceversion; usare da cataloghi certificati.
- S2I per build da sorgente; Template per parametrizzazione; LimitRange e ResourceQuota; Network policy; monitoring e logging; GitOps (ArgoCD/Flux); Tekton per pipeline nel cluster.

## Vedi anche

- [Kubernetes](kubernetes.md) — Base e workload.
- [Docker](docker.md) — Image e build.
- [Pipeline](pipeline.md) e [Helm](helm.md) — Deploy e packaging.
