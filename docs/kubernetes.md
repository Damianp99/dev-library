# Kubernetes

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Pod e workload](#pod-e-workload)
- [Deployment e rollout](#deployment-e-rollout)
- [Service e discovery](#service-e-discovery)
- [ConfigMap e Secret](#configmap-e-secret)
- [Ingress](#ingress)
- [Scaling (HPA)](#scaling-hpa)
- [Osservabilità e rollback](#osservabilita-e-rollback)
- [Risorse, Job, RBAC e PDB](#risorse-job-rbac-e-pdb)
- [NetworkPolicy, StatefulSet e init](#networkpolicy-statefulset-e-init)

## Panoramica

Kubernetes è un sistema di orchestrazione per container: pianifica, esegue e mantiene in salute i workload su un cluster. I container sono tipicamente costruiti con [Docker](docker.md) e distribuiti come image; Kubernetes gestisce pod, replica, rete, configurazione e rollout. In ambienti enterprise viene spesso usato [OpenShift](openshift.md), che estende Kubernetes con route, sicurezza e build integrati. Il packaging delle applicazioni per Kubernetes può essere gestito con [Helm](helm.md); il deploy in produzione è spesso automatizzato da [Pipeline](pipeline.md) CI/CD.

!!! tip "Prova a spiegarlo"
    Spiega a voce: cosa fa un **Deployment** e a cosa servono **liveness e readiness probe**. Poi verifica in [Deployment e rollout](kubernetes.md#deployment-e-rollout) e [Osservabilità e rollback](kubernetes.md#osservabilita-e-rollback).

---

## Pod e workload

### Concetto

Il **Pod** è l'unità minima deployabile: uno o più container che condividono rete e storage (volumi), schedulati insieme su uno stesso nodo. **ReplicaSet** mantiene un numero desiderato di repliche di un template di Pod. **Deployment** gestisce ReplicaSet e aggiornamenti dichiarativi (rolling update). **StatefulSet** è per workload con identità stabile e storage persistente (DB, cluster); **DaemonSet** per un pod per nodo (agent, collector).

### Flusso operativo

1. Si definisce un Deployment (selector, replicas, template Pod).
2. Il controller crea un ReplicaSet che crea i Pod.
3. Per app stateless: Deployment; per stato e identità stabile: StatefulSet.

### Comando/esempio

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
        - name: api
          image: myregistry/api:1.0
          ports:
            - containerPort: 8080
```

### Failure mode comune

Usare un Deployment per un database che richiede storage persistente e identità stabile: preferire StatefulSet (e PersistentVolume) per quel tipo di workload.

### Best practice

Workload stateless con Deployment; StatefulSet solo quando serve identità e storage; risorse (requests/limits) sempre definite per scheduling e qualità del servizio.

---

## Deployment e rollout

### Concetto

Il **Deployment** dichiara lo stato desiderato (repliche, image, risorse). A ogni modifica del template viene creato un nuovo ReplicaSet e viene eseguito un **rolling update**: i pod vecchi vengono terminati progressivamente mentre quelli nuovi vengono creati. Il **rollback** ripristina una revisione precedente.

### Flusso operativo

1. Modifica dell'image o del template → `kubectl apply -f deployment.yaml`.
2. Il controller effettua rolling update; si può seguire con `kubectl rollout status`.
3. In caso di problemi: `kubectl rollout undo deployment/nome`.

### Comando/esempio

```bash
kubectl apply -f deployment.yaml
kubectl rollout status deployment/api
kubectl rollout history deployment/api
kubectl rollout undo deployment/api
kubectl rollout undo deployment/api --to-revision=2
```

### Failure mode comune

Rolling update bloccato per readiness errata (probe che falliscono) o risorse insufficienti; i pod nuovi restano in CrashLoopBackOff o Not Ready.

### Best practice

Definire readiness/liveness probe; usare limiti di risorse; testare rollout e rollback in staging; in pipeline prevedere rollback automatico in caso di failure post-deploy.

---

## Service e discovery

### Concetto

Il **Service** espone un set di Pod (selezionati da label) come endpoint di rete stabile. **ClusterIP** (default): IP virtuale interno al cluster, raggiungibile solo da dentro. **NodePort**: porta su ogni nodo. **LoadBalancer**: integrazione con LB del cloud. I Pod si risolvono tramite DNS: `nome-servizio.namespace.svc.cluster.local`.

### Flusso operativo

1. Creare un Service con selector che matcha le label dei Pod del Deployment.
2. Il controllo plane assegna ClusterIP e aggiorna gli endpoint; i client usano il nome del Service per risolvere e connettersi.

### Comando/esempio

```yaml
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector:
    app: api
  ports:
    - port: 80
      targetPort: 8080
  type: ClusterIP
```

### Failure mode comune

Selector del Service che non matcha nessuna label dei Pod: il Service esiste ma ha 0 endpoint; le connessioni falliscono o restano in attesa.

### Best practice

Label coerenti tra Deployment e Service; usare ClusterIP per traffico interno; LoadBalancer o Ingress per traffico esterno; evitare NodePort in produzione se non necessario.

---

## ConfigMap e Secret

### Concetto

**ConfigMap** e **Secret** separano la configurazione (e i dati sensibili) dai manifest dell'applicazione. ConfigMap per file di config o variabili non sensibili; Secret per password, token, certificati (memorizzati in base64, in produzione preferire encryption at rest e/o external secret store). Si montano come file o variabili d'ambiente nei Pod.

### Flusso operativo

1. Creare ConfigMap/Secret (da file, da literal o da manifest).
2. Nel Pod: `envFrom`, `env.valueFrom`, o `volumeMount` per iniettare la config.

### Comando/esempio

```yaml
# ConfigMap (riferimento nel Pod)
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  LOG_LEVEL: "info"
  config.json: |
    {"endpoint": "http://api:80"}
---
# Nel Pod
spec:
  containers:
    - name: app
      envFrom:
        - configMapRef:
            name: app-config
```

### Failure mode comune

Secret in chiaro nei manifest (YAML in repo): rischio di esposizione; usare strumenti esterni (Sealed Secrets, Vault, provider cloud) e non committare segreti.

### Best practice

Niente secret in chiaro nei YAML; preferire external secret provider; ConfigMap per config non sensibile; aggiornare ConfigMap/Secret e riavviare/rollout solo se l'app legge a runtime (altrimenti serve rollout per rileggere).

---

## Ingress

### Concetto

L'**Ingress** è una risorsa che definisce routing HTTP/HTTPS verso Service (host, path, TLS). Richiede un **Ingress controller** (es. NGINX, Traefik) che interpreta le regole e gestisce il traffico. Un solo punto di ingresso per più servizi riduce l'uso di LoadBalancer per servizio.

### Flusso operativo

1. Installare/configurare un Ingress controller nel cluster.
2. Creare risorse Ingress che referenziano i Service (backend); opzionale TLS con Secret per certificati.

### Comando/esempio

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
spec:
  ingressClassName: nginx
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api
                port:
                  number: 80
```

### Failure mode comune

Ingress senza controller installato: la risorsa esiste ma non ha effetto; oppure host/path errati che non matchano le richieste.

### Best practice

Usare un Ingress per più servizi; TLS per produzione; annotazioni dipendenti dal controller scelto; in OpenShift preferire [Route](openshift.md#route) dove integrato.

---

## Scaling (HPA)

### Concetto

L'**Horizontal Pod Autoscaler (HPA)** regola il numero di repliche di un Deployment (o altro scalabile) in base a metriche (CPU, memoria o custom). Definisci min/max repliche e target di utilizzo; il controller periodicamente adatta le repliche.

### Flusso operativo

1. Abilitare metriche (metrics-server o adapter per metriche custom).
2. Creare HPA che referenzia il Deployment e imposta target (es. 70% CPU).
3. Il controller HPA modifica le repliche in base alle metriche.

### Comando/esempio

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

### Failure mode comune

HPA senza metriche disponibili (metrics-server non installato o pod senza requests): l'HPA non può calcolare l'utilizzo e non scala.

### Best practice

Definire sempre requests (CPU/memory) sui container per permettere il calcolo delle percentuali; testare min/max in staging; combinare con limiti di risorse per evitare saturazione nodi.

---

## Osservabilità e rollback

### Liveness e readiness probe: cosa sono e a cosa servono

**Concetto**

- **Readiness probe**: verifica se il container è pronto a ricevere traffico. Se fallisce, il pod viene tolto dagli endpoint del Service (non riceve richieste) ma non viene riavviato. Serve a evitare di inviare traffico a pod ancora in avvio o temporaneamente non pronti (es. dipendenze non pronte).
- **Liveness probe**: verifica se l'applicazione è ancora viva. Se fallisce ripetutamente, Kubernetes riavvia il container. Serve a recuperare da deadlock o stati bloccati senza attendere timeout esterni.

**Flusso operativo**

1. All'avvio: la readiness determina quando il pod entra in Ready e viene aggiunto al Service.
2. Durante la vita: la liveness controlla periodicamente; fallimenti consecutivi (secondo threshold) portano al restart del container.
3. Readiness può fallire anche a runtime (es. app sovraccarica): il pod viene temporaneamente escluso dal load balancing.

**Comando/esempio**

```yaml
spec:
  containers:
    - name: api
      image: myregistry/api:1.0
      readinessProbe:
        httpGet:
          path: /ready
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 10
      livenessProbe:
        httpGet:
          path: /health
          port: 8080
        initialDelaySeconds: 15
        periodSeconds: 20
```

**Failure mode comune**

Readiness e liveness sullo stesso endpoint con soglie aggressive: un'app lenta a rispondere può essere riavviata (liveness) mentre era solo temporaneamente non ready. Endpoint che dipendono da dipendenze esterne (DB) per la liveness: un DB down causa restart a catena. Preferire endpoint leggeri e distinti (es. `/health` per liveness, `/ready` per readiness con check dipendenze).

**Best practice**

Endpoint dedicati per probe; readiness che verifica dipendenze (DB, cache); liveness solo controllo “processo vivo”; initialDelaySeconds adeguato per avvio; failureThreshold e periodSeconds bilanciati per evitare falsi positivi; in pipeline prevedere rollback su fallimento health check post-deploy.

---

### Concetto

**Osservabilità**: log (`kubectl logs`), metriche (Prometheus/metrics-server), eventi (`kubectl get events`) e stato dei Pod/Deployment permettono di capire perché un deploy è fallito o un pod non è Ready. **Rollback**: ripristino di una revisione precedente del Deployment per annullare un rilascio problematico.

### Flusso operativo

1. Controllare stato: `kubectl get pods`, `kubectl describe pod`, `kubectl logs`.
2. Verificare eventi e readiness/liveness.
3. Rollback: `kubectl rollout undo deployment/nome` oppure `--to-revision=N`.

### Comando/esempio

```bash
kubectl get pods -l app=api
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous
kubectl get events --sort-by='.lastTimestamp'
kubectl rollout undo deployment/api
kubectl rollout history deployment/api
```

### Failure mode comune

Non definire probe: Kubernetes non sa se l'app è davvero pronta; i pod vengono considerati Ready e ricevono traffico prima di esserlo, con errori 5xx o timeout.

### Best practice

Liveness e readiness probe appropriati; log in stdout; metriche esposte (Prometheus) e alert su failure; strategia di rollback documentata e possibilmente automatizzata in pipeline (es. rollback su fallimento health check post-deploy).

## In sintesi

- Pod: unità minima; Deployment per replica e rollout; Service per discovery e load balancing; Ingress per HTTP esterno.
- ConfigMap e Secret: configurazione e segreti; montati come env o file; non committare secret.
- HPA per scaling su CPU/custom metriche; probe liveness/readiness obbligatori; rollback con kubectl rollout undo.
- Requests/limits e QoS; Job e CronJob per batch; RBAC (ServiceAccount, Role, RoleBinding); PDB per drain sicuro; NetworkPolicy; StatefulSet per workload con identità; init container e sidecar.

## Vedi anche

- [Docker](docker.md) — Image e container.
- [OpenShift](openshift.md) — Estensione enterprise.
- [Helm](helm.md) e [Pipeline](pipeline.md) — Packaging e deploy.
