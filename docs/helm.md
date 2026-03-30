# Helm

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Chart e struttura](#chart-e-struttura)
- [Values e parametrizzazione](#values-e-parametrizzazione)
- [Dependency](#dependency)
- [Upgrade e revision](#upgrade-e-revision)
- [Rollback](#rollback)
- [Best practice](#best-practice)
- [Hooks, template functions e test](#hooks-template-functions-e-test)
- [Subchart, secret e GitOps](#subchart-secret-e-gitops)

## Panoramica

Helm è il package manager per [Kubernetes](kubernetes.md): un **chart** è un pacchetto di manifest (Deployment, Service, ConfigMap, ecc.) templatizzati e parametrizzati tramite **values**. Helm gestisce il ciclo di vita dell’installazione (install, upgrade, rollback) e mantiene una **revision history** per ogni release. In uno stack tipico le [Pipeline](pipeline.md) usano Helm per deployare su cluster Kubernetes o [OpenShift](openshift.md); le image sono costruite con [Docker](docker.md) e referenziate nei values del chart.

---

## Chart e struttura

### Concetto

Un **chart** è una directory con una struttura fissa: `Chart.yaml` (metadati e versione del chart), `values.yaml` (valori di default), e la directory `templates/` con manifest Kubernetes in formato Go template. Helm genera i manifest finali sostituendo i placeholder con i values e li applica al cluster; ogni installazione è una **release** con un nome e una revisione.

### Flusso operativo

1. Creare la struttura del chart: `helm create myapp` oppure directory manuale con Chart.yaml, values.yaml, templates/.
2. Definire i template (Deployment, Service, ecc.) usando `{{ .Values.* }}` e funzioni Helm.
3. Validare: `helm template` o `helm install --dry-run`; installare: `helm install` o `helm upgrade --install`.

### Comando/esempio

```bash
# Struttura minima
myapp/
  Chart.yaml
  values.yaml
  templates/
    deployment.yaml
    service.yaml
```

```yaml
# Chart.yaml
apiVersion: v2
name: myapp
version: 0.1.0
description: My App Helm chart
```

```yaml
# templates/deployment.yaml (estratti)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "myapp.fullname" . }}
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
        - name: app
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: {{ .Values.service.port }}
```

### Failure mode comune

Template con sintassi errata o values mancanti: `helm template` o install falliscono con errore di rendering; sempre testare con `helm template` o `--dry-run` prima di installare.

### Best practice

Usare `helm create` come base; nomi delle release e dei chart coerenti; versionare il chart in Chart.yaml; non mettere secret in chiaro nei values.

---

## Values e parametrizzazione

### Concetto

I **values** sono la configurazione del chart: definiti in `values.yaml`, sovrascrivibili da `-f values-prod.yaml`, `--set key=value` o `--set-file`. Servono per differenziare ambienti (dev, staging, prod) senza duplicare i template. I secret non vanno messi in values in chiaro: usare Secret Kubernetes gestiti fuori dal chart (external secrets, pipeline) o `--set` da variabili protette.

### Flusso operativo

1. Valori di default in `values.yaml`.
2. Override per ambiente: `values-prod.yaml` con repository image, replicaCount, risorse, ecc.
3. Pipeline: `helm upgrade --install -f values-prod.yaml --set image.tag=$TAG`.

### Comando/esempio

```yaml
# values.yaml
replicaCount: 1
image:
  repository: myregistry.com/myapp
  tag: "1.0.0"
service:
  port: 8080
```

```bash
# Override da file e da set
helm upgrade --install myapp ./chart -f values-prod.yaml --set image.tag=1.2.3 -n prod
```

### Failure mode comune

Secret (password, token) in values.yaml o in file versionati: rischio di esposizione in repo. Valori sensibili vanno iniettati con Secret esterni o `--set` da variabili d’ambiente protette nella pipeline.

### Best practice

Valori per ambiente in file separati (values-dev, values-prod); nessun secret in values; usare `--set` solo per override puntuali; documentare le chiavi obbligatorie e i valori ammessi.

---

## Dependency

### Concetto

Un chart può dipendere da altri chart (**subchart**): si dichiara in `Chart.yaml` nella sezione `dependencies` (nome, repository, versione). Prima di package o install si eseguono `helm dependency update` (scarica i chart in `charts/`) e opzionalmente `helm dependency build`. Le dipendenze possono avere i propri values; i values del chart padre possono sovrascrivere quelli del subchart con la chiave che corrisponde al nome del subchart.

### Flusso operativo

1. Aggiungere in Chart.yaml la sezione dependencies (repository, nome chart, version).
2. Eseguire `helm dependency update` per scaricare i chart in `charts/`.
3. Valori del subchart: in values.yaml sotto una chiave con il nome del subchart.

### Comando/esempio

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "13.x.x"
    repository: https://charts.bitnami.com/bitnami
```

```bash
helm dependency update
helm install myapp . -n prod
```

### Failure mode comune

Repository non raggiungibile o versione del dependency non più disponibile: `helm dependency update` fallisce; verificare URL e versioni. Dependency non aggiornate: vulnerabilità o incompatibilità; pianificare aggiornamenti e test.

### Best practice

Fissare la versione delle dependency (no range troppo ampi in prod); usare repository affidabili; documentare le dependency e le versioni testate; rieseguire `helm dependency update` in pipeline prima del deploy.

---

## Upgrade e revision

### Concetto

**Upgrade** applica una nuova versione del chart o degli stessi template con values aggiornati; Helm crea una nuova **revision** e aggiorna i manifest nel cluster. Con `--install` si installa se la release non esiste. La **storia delle revisioni** (`helm history`) permette di sapere quale configurazione era attiva e di fare rollback a una revisione precedente.

### Flusso operativo

1. Modifica di template o values; `helm upgrade myapp ./chart -f values-prod.yaml -n prod`.
2. Helm calcola il diff e applica le modifiche; la release passa alla nuova revisione.
3. Verificare: `helm list`, `helm history myapp -n prod`.

### Comando/esempio

```bash
# Upgrade (install se non esiste)
helm upgrade --install myapp ./chart -f values-prod.yaml --set image.tag=1.2.4 -n prod --wait

# Storia revisioni
helm list -n prod
helm history myapp -n prod
```

### Failure mode comune

Upgrade con values errati (es. image inesistente): i Pod non partono; la revisione è comunque registrata. Controllare lo stato dei Pod dopo l’upgrade e avere una procedura di rollback rapida.

### Best practice

Usare `--wait` (e opzionalmente `--timeout`) per attendere che i Pod siano Ready; versionare il chart e i values; in pipeline loggare la revisione deployata per tracciabilità.

---

## Rollback

### Concetto

Il **rollback** ripristina una release alla revisione precedente (o a una specifica): Helm riapplica i manifest di quella revisione. È l’equivalente operativo di “annullare l’ultimo deploy”; per problemi più complessi si può fare un nuovo upgrade con la versione desiderata. Su [Kubernetes](kubernetes.md) si può anche usare `kubectl rollout undo` sul Deployment; Helm rollback è a livello di intera release (tutte le risorse del chart).

### Flusso operativo

1. Identificare la revisione stabile: `helm history myapp -n prod`.
2. Eseguire: `helm rollback myapp <revision> -n prod`.
3. Helm riapplica lo stato della revisione scelta; verificare con `kubectl get pods` e `helm list`.

### Comando/esempio

```bash
helm history myapp -n prod
helm rollback myapp 3 -n prod
helm status myapp -n prod
```

### Failure mode comune

Rollback a una revisione con image o config già ritirati: i Pod potrebbero non partire. Mantenere disponibili le image e i values delle ultime N revisioni.

### Best practice

Documentare la procedura di rollback; in pipeline prevedere uno step o un runbook per rollback; limitare il numero di revisioni conservate (`helm history` mostra fino al limite configurato) e allineare con retention degli artefatti.

---

## Best practice

### Riepilogo

- **Versioning**: Chart e app versionati in Chart.yaml e nei values (image.tag); coerenza con la strategia di release della pipeline.
- **Valori per ambiente**: File values separati (values-dev, values-prod); nessun secret in values; secret da Secret Kubernetes o da strumenti esterni (Vault, sealed secrets).
- **Dependency**: Versioni fissate; `helm dependency update` in CI prima del deploy; repository affidabili.
- **Rollback**: Revisioni conservate; procedura di rollback testata e documentata; allineamento con pipeline (stesso artefatto per deploy e rollback dove possibile).
- **Sicurezza**: Nessun secret in chiaro; limitare i permessi dell’account usato da Helm (RBAC); validare template con `helm template` o `--dry-run` in pipeline.

### Confronto con kubectl rollout undo

- **kubectl rollout undo**: opera sul singolo Deployment (o altro workload); ripristina il ReplicaSet precedente; non tocca altre risorse (Service, ConfigMap, ecc.).
- **helm rollback**: ripristina l’intera release alla revisione scelta (tutti i manifest del chart); coerente quando l’applicazione è gestita interamente da un unico chart.

Usare Helm rollback quando il deploy è fatto con Helm; usare `kubectl rollout undo` per interventi rapidi su un singolo Deployment senza toccare il resto della release.

---

## Hooks, template functions e test

### Hooks (pre-install, post-upgrade, ecc.)
**Concetto**  
Gli hook eseguono Job (o risorse) in momenti specifici del ciclo di vita Helm: pre-install, post-install, pre-upgrade, post-upgrade, pre-delete, post-delete, e altri. Le risorse con annotazione `helm.sh/hook` vengono create e gestite da Helm in quel punto; hook con weight per ordinare hook dello stesso tipo.

**Flusso operativo**  
Aggiungere annotazione al manifest: `helm.sh/hook: post-install`; opzionale `helm.sh/hook-weight: "-5"` (ordine). Hook che falliscono (Job in fail) possono bloccare il release (hook-delete-policy).

**Failure mode comune**  
Hook che non termina (Job bloccato); hook che modifica risorse fuori dal controllo di Helm. Best practice: hook per migrazioni DB o post-install one-shot; timeout e retry limit; documentare dipendenze.

### Template functions e pipeline (Sprig, default, range)
**Concetto**  
Helm usa Go template con funzioni aggiuntive (Sprig): string (upper, lower, trim), default, required, range, with, if, e funzioni Helm (include, toYaml). Pipeline: `{{ .Values.name | default "app" | quote }}` per concatenare funzioni.

**Flusso operativo**  
Valori condizionali: `{{ if .Values.ingress.enabled }} ... {{ end }}`. Iterazioni: `{{ range .Values.replicas }}`. Valore obbligatorio: `{{ required "image.tag is required" .Values.image.tag }}`.

**Failure mode comune**  
Template che fallisce a render per valore nil (usare default); indent errato in YAML (indent function). Best practice: default per campi opzionali; helm template per validare prima del deploy.

### Chart testing (helm test, lint)
**Concetto**  
`helm test RELEASE` esegue i test definiti nel chart (risorse con annotazione helm.sh/hook: test): tipicamente Job che verificano che l'app risponda (curl, grpc health). `helm lint` controlla sintassi e best practice del chart (warning ed error).

**Flusso operativo**  
Aggiungere in templates/ un Job con hook test; dopo install/upgrade eseguire helm test. In pipeline: lint in ogni PR; test dopo deploy in staging.

**Failure mode comune**  
Test che dipendono da risorse non ancora pronte (ordine); test che modificano stato. Best practice: test idempotenti; timeout; lint in CI.

---

## Subchart, secret e GitOps

### Subchart e global values
**Concetto**  
Un chart può dipendere da **subchart** (dependency in Chart.yaml); i values del parent possono sovrascrivere i values del subchart. I **global values** (sotto .Values.global) vengono propagati a tutti i subchart: utile per image registry, dominio, label comuni.

**Flusso operativo**  
Chart.yaml: dependencies con name, version, repository. values.yaml: sezione con nome del subchart per override; global per valori condivisi. helm dependency update per scaricare i subchart.

**Failure mode comune**  
Override che rompe il subchart; versioni di dependency non fissate (build non riproducibile). Best practice: versioni fissate; test con valori override; documentare global usati.

### Secrets e valori sensibili (Helm secrets, external secrets)
**Concetto**  
Non mettere secret in values in chiaro. Opzioni: **Helm secrets** (plugin che cifra valori con SOPS/Vault e decifra prima di helm install); **External Secrets Operator**: risorse che sincronizzano secret da Vault/AWS Secrets Manager in Secret Kubernetes; valori sensibili iniettati a deploy time dalla pipeline.

**Flusso operativo**  
Template che referenziano Secret creati fuori da Helm (nome fisso) o da ExternalSecret; values solo per nomi o path, non per contenuti. In pipeline: generare Secret da vault e applicare prima di Helm o usare helm-secrets con chiave da CI.

**Failure mode comune**  
Secret in values committati; Secret in log o in history. Best practice: mai secret in repo; RBAC limitato per l'account che fa helm install.

### Helm e GitOps (ArgoCD/Flux)
**Concetto**  
In un flusso GitOps, ArgoCD o Flux leggono il repo (chart, values per ambiente) e eseguono `helm template` + `kubectl apply` (o helm upgrade) per riconciliare il cluster. Nessun tiller lato server (Helm 3 è client-only); l'operator nel cluster applica i manifest generati.

**Flusso operativo**  
Applicazione ArgoCD con source Helm (repo + chart + version + values file); sync periodico o webhook. Rollback tramite revert del commit o cambio revisione in Git.

**Failure mode comune**  
Drift tra cluster e Git; valori sensibili in Git. Best practice: repo separato per valori prod o Sealed Secrets; approvazione su cambio a valori prod.

### Confronto con Kustomize
**Concetto**  
**Kustomize** sovrascrive e compone manifest YAML senza linguaggio di template: patch (patch strategico, json patch) e overlay (base + env). **Helm** usa template e package versionati; più adatto a chart riutilizzabili e parametrizzazione complessa.

**Quando preferire**  
Helm: applicazioni con molti parametri, chart da condividere, dipendenze tra chart. Kustomize: repo già in manifest raw, pochi override per ambiente, preferenza per YAML dichiarativo senza template. In GitOps entrambi sono supportati (ArgoCD, Flux).

## In sintesi

- Chart: template + values; Chart.yaml, values.yaml; install/upgrade/rollback.
- Dependency: chart dipendenti versionati; helm dependency update in CI; secret non in values.
- Upgrade e revision: helm upgrade --install; --wait per attendere Pod; history per rollback.
- Best practice: versioning chart e image; values per ambiente; nessun secret in chiaro.
- Hooks per migrazioni e post-install; template functions (Sprig, default, range); helm lint e test; subchart e global values; secret fuori da values (Helm secrets, External Secrets); Helm con ArgoCD/Flux; confronto con Kustomize.

## Vedi anche

- [Kubernetes](kubernetes.md) — Risorse e manifest.
- [Pipeline](pipeline.md) — Deploy automatizzato.
- [Docker](docker.md) — Image referenziate nei values.
