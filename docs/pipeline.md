# Pipeline

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Quality gate](#quality-gate)
- [Build e artefatti](#build-e-artefatti)
- [Release strategy](#release-strategy)
- [Deploy e ambienti](#deploy-e-ambienti)
- [Rollback](#rollback)
- [Osservabilità pipeline](#osservabilita-pipeline)
- [Pipeline as code, artefatti e approval](#pipeline-as-code-artefatti-e-approval)
- [Cache, parallelizzazione e security](#cache-parallelizzazione-e-security)

## Panoramica

Una **pipeline** CI/CD automatizza build, test e deploy: dal codice sorgente all’ambiente di esecuzione. In uno stack tipico la pipeline costruisce [immagini Docker](docker.md), le pusha su un registry e deploya su [Kubernetes](kubernetes.md) o [OpenShift](openshift.md), spesso usando [Helm](helm.md) per il packaging dei manifest. Quality gate, strategia di release e rollback sono elementi chiave per affidabilità e tracciabilità in produzione.

Stadi tipici (il passaggio allo stadio successivo è condizionato ai quality gate):

``` mermaid
flowchart LR
  A[Source] --> B[Test]
  B --> C[Build]
  C --> D[Registry]
  D --> E[Deploy Staging]
  E --> F[Deploy Prod]
```

---

## Quality gate

### Concetto

I **quality gate** sono controlli automatici che devono passare prima di promuovere un artefatto (es. image o branch) allo stadio successivo (es. staging, produzione). Includono test (unitari, integrazione, e2e), lint, scan vulnerabilità e policy di sicurezza. Se un gate fallisce, la pipeline blocca la promozione e opzionalmente notifica.

### Flusso operativo

1. Ogni stage della pipeline esegue i gate previsti (test, lint, scan).
2. Il passaggio allo stage successivo è condizionato al successo di tutti i gate (e opzionalmente a review/approval per prod).
3. Fallimento: pipeline in failure, nessun deploy automatico; si correggono gli errori e si riavvia.

### Comando/esempio

```yaml
# Esempio concettuale (Jenkinsfile / GitLab CI)
stages:
  - test
  - lint
  - security-scan
  - build
  - deploy-staging
  - deploy-prod  # solo se staging ok + approval

test:
  script:
    - npm ci
    - npm run test
  allow_failure: false

security-scan:
  script:
    - docker run --rm -v /var/run/docker.sock:/var/run/docker.sock scanner image:tag
  allow_failure: false
```

### Failure mode comune

Gate disabilitati o impostati come `allow_failure: true` per “sbloccare” una release: i problemi si propagano in produzione. Oppure gate troppo lenti che ritardano ogni run senza valore (test ridondanti o scan non ottimizzati).

### Best practice

Gate obbligatori per test e sicurezza; non saltare i gate per velocità; ottimizzare tempi (parallelizzazione, cache); in prod aggiungere approval manuale o canary dove richiesto dalla compliance.

---

## Build e artefatti

### Concetto

Lo **stage di build** compila il codice, esegue i test e produce **artefatti** versionati: JAR, image Docker, chart Helm. Le image vengono pushate su un registry con tag univoci (versione o commit SHA). Gli artefatti sono l’input per il deploy; non si ricompila in produzione ma si deploya l’artefatto già validato.

### Flusso operativo

1. Checkout codice → install dipendenze → build (compile, bundle).
2. Build image Docker (multi-stage); tag con versione o Git SHA; push su registry.
3. (Opzionale) Package Helm chart; salvare come artefatto o in repository chart.

### Comando/esempio

```bash
# Build image e push con tag versionato
docker build -t registry.company.com/myapp:${CI_COMMIT_TAG} .
docker push registry.company.com/myapp:${CI_COMMIT_TAG}

# Senza tag semantico: usare short SHA
docker tag myapp registry.company.com/myapp:${CI_COMMIT_SHORT_SHA}
docker push registry.company.com/myapp:${CI_COMMIT_SHORT_SHA}
```

### Failure mode comune

Build non riproducibili (dipendenze non fissate, cache incoerente): stessi input producono output diversi. Deploy con tag `latest` o artefatto non versionato: impossibile rollback deterministico.

### Best practice

Build deterministici (lockfile, versioni fisse); artefatti sempre versionati (tag, SHA); registry privato e scan su ogni image; conservare artefatti per un periodo definito (retention policy).

---

## Release strategy

### Concetto

La **release strategy** definisce come si assegnano le versioni e come si promuove il software tra ambienti. Comprende versioning semantico (o equivalente), uso di tag Git, branch strategy (main, release/*) e criteri per cui un build diventa “release” (es. tag, merge su main). Staging e produzione sono ambienti distinti con promozione esplicita.

### Flusso operativo

1. Sviluppo su branch; merge su main (o release branch) dopo review e pipeline verde.
2. Tag per release: `v1.2.3` → la pipeline builda e produce artefatti con quella versione.
3. Promozione: stesso artefatto (stessa image/versione) deployato prima su staging, poi su prod dopo gate e eventuale approval.

### Comando/esempio

```bash
# Tag release (trigger pipeline)
git tag v1.2.3
git push origin v1.2.3

# La pipeline: build con tag v1.2.3 → push image myapp:1.2.3
# Deploy staging con myapp:1.2.3; dopo validazione, deploy prod con myapp:1.2.3
```

### Failure mode comune

Deploy in prod con artefatti diversi da quelli testati in staging (rebuild invece di promozione): comportamento diverso in prod. Oppure nessuna strategia di versioning: impossibile riferire una release a un preciso commit/artefatto.

### Best practice

Promuovere lo stesso artefatto da staging a prod; versioning semantico e tag Git; documentare il processo di release e i criteri di go/no-go per la produzione.

---

## Deploy e ambienti

### Concetto

Il **deploy** è l’applicazione dello stato desiderato sull’ambiente target: applicare manifest [Kubernetes](kubernetes.md) (o [Helm](helm.md)), aggiornare [OpenShift](openshift.md) (Route, BuildConfig, Deployment), oppure invocare API cloud. Gli **ambienti** (dev, staging, prod) sono separati per cluster, namespace o progetto; ogni ambiente ha la propria config (values, Secret, URL).

### Flusso operativo

1. Pipeline ottiene credenziali/kubeconfig per l’ambiente target (vault, variabili protette).
2. Applica manifest: `kubectl apply -f`, `helm upgrade --install`, oppure `oc apply`; usa valori specifici per ambiente (values-dev.yaml, values-prod.yaml).
3. Verifica post-deploy: health check, smoke test; in caso di fallimento si può attivare il rollback.

### Comando/esempio

```bash
# Helm deploy per ambiente
helm upgrade --install myapp ./chart -f values-prod.yaml --set image.tag=1.2.3 -n prod --wait

# Kubectl
kubectl apply -k overlays/prod
kubectl rollout status deployment/myapp -n prod
```

### Failure mode comune

Stesso set di valori (o secret) usato per tutti gli ambienti: config di prod esposta in dev o viceversa. Credenziali di prod nella pipeline senza protezione: rischio di leak.

### Best practice

Config per ambiente (values, ConfigMap, Secret) separata e protetta; credenziali da secret manager; deploy idempotente (helm upgrade, kubectl apply); post-deploy check e alert su failure.

---

## Rollback

### Concetto

Il **rollback** ripristina una versione precedente dell’applicazione dopo un deploy problematico. Deve essere rapido e deterministico: usare la stessa pipeline o gli stessi comandi che si usano per il deploy, ma con la revisione/versione precedente. Criterio operativo: “rollback in un click” (o comando unico) senza ricostruire da zero.

### Flusso operativo

1. Rilevare il problema (monitoring, error rate, alert).
2. Decidere il rollback; identificare la revisione/versione precedente stabile.
3. Eseguire rollback: Helm `helm rollback`, Kubernetes `kubectl rollout undo`, oppure ridistribuire l’artefatto precedente dalla pipeline.

### Comando/esempio

```bash
# Kubernetes
kubectl rollout undo deployment/myapp -n prod
kubectl rollout status deployment/myapp -n prod

# Helm
helm rollback myapp <revision> -n prod
helm history myapp -n prod
```

### Failure mode comune

Nessuna storia delle revisioni o artefatti non più disponibili: rollback impossibile o non riproducibile. Rollback manuale ad hoc senza documentazione: errori e tempi lunghi.

### Best practice

Mantenere storia di release (Helm revision, tag image); documentare la procedura di rollback; automatizzare dove possibile (step “rollback” in pipeline o runbook); testare il rollback in staging periodicamente.

---

## Osservabilità pipeline

### Concetto

L’**osservabilità della pipeline** permette di capire stato, durata e causa di failure: log degli stage, durata per stage, artefatti prodotti, notifiche su failure o su deploy in prod. Integrazione con ticket (Jira, etc.) o chat (Slack, Teams) migliora la reattività del team.

### Flusso operativo

1. Ogni run della pipeline produce log e metadati (duration, status, commit, branch/tag).
2. Failure: alert e notifica; link al run e ai log per analisi.
3. Metriche (opzionali): tempo di build, frequenza di deploy, tasso di successo; dashboard per miglioramento continuo.

### Comando/esempio

```yaml
# Notifica su failure (es. GitLab CI)
notify_on_failure:
  script:
    - curl -X POST "$SLACK_WEBHOOK" -d '{"text":"Pipeline failed: $CI_PIPELINE_URL"}'
  when: on_failure
```

### Failure mode comune

Pipeline senza notifiche: i failure restano invisibili fino a quando qualcuno non controlla. Log non conservati o non accessibili: difficile debug su failure intermittenti.

### Best practice

Notifiche su failure (e opzionalmente su deploy prod); conservare log per un periodo definito; link al commit e all’artefatto in ogni run; metriche su durata e success rate per ottimizzare.

## In sintesi

- Quality gate: test, lint, security scan; nessuna promozione se un gate fallisce; approval per prod dove richiesto.
- Build: artefatti versionati (image con tag, chart); push su registry; non ricompilare in prod.
- Release: tag semantico o Git SHA; deploy staging prima di prod; strategia blue/green o rolling.
- Rollback: procedura documentata; Helm rollback o kubectl rollout undo; notifiche e metriche su failure.
- Pipeline as code in repo; artefatti versionati (semver/SHA) e immutabili; approval manuale per prod; cache dipendenze; parallelizzazione stage; secret in vault/variabili; signed build per integrità.

## Vedi anche

- [Docker](docker.md), [Kubernetes](kubernetes.md), [Helm](helm.md) — Build e deploy.
- [OpenShift](openshift.md) — Deploy su cluster Red Hat.
