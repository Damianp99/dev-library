# Docker

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Image e container](#image-e-container)
- [Dockerfile e multi-stage build](#dockerfile-e-multi-stage-build)
- [Layer e caching](#layer-e-caching)
- [Volumi](#volumi)
- [Reti](#reti)
- [Registry e tag](#registry-e-tag)
- [Docker Compose, health check e risorse](#docker-compose-health-check-e-risorse)
- [BuildKit, log e sicurezza](#buildkit-log-e-sicurezza)
- [Failure mode e best practice](#failure-mode-e-best-practice)

## Panoramica

Docker è una piattaforma per creare, distribuire ed eseguire applicazioni in container. Fornisce isolamento a livello di processo, riproducibilità degli ambienti e un modello image/container che è la base per l'orchestrazione (ad esempio [Kubernetes](kubernetes.md) e [OpenShift](openshift.md)). In uno stack tipico, le image Docker sono l'unità di deploy che Kubernetes e OpenShift schedulano e gestiscono.

!!! tip "Prova a spiegarlo"
    Spiega a voce: perché in produzione **non** si usa il tag `latest` e cosa sono i **multi-stage build**. Poi verifica in [Registry e tag](docker.md#registry-e-tag) e [Dockerfile](docker.md#dockerfile-e-multi-stage-build).

---

## Image e container

### Concetto

- **Image**: artefatto immutabile, read-only, che contiene filesystem e metadati (entrypoint, env, ecc.). Si costruisce con `docker build` da un Dockerfile.
- **Container**: istanza in esecuzione di un'image; ha uno strato scrivibile effimero sopra l'image. Più container possono condividere la stessa image.

### Flusso operativo

1. Scrivere Dockerfile → `docker build -t nome:tag .`
2. Eseguire: `docker run nome:tag` (crea e avvia un container)
3. Distribuire: `docker push registry/nome:tag`

### Comando/esempio

```bash
# Build image
docker build -t myapp:1.0 .

# Run container (effimero: dati persi allo stop)
docker run --rm -p 8080:8080 myapp:1.0

# Lista container e image
docker ps -a
docker images
```

### Failure mode comune

Usare `docker run` senza volumi per dati che devono persistere: allo stop del container i dati nello strato scrivibile si perdono.

### Best practice

Usare tag espliciti (no `latest` in produzione); preferire image ufficiali o da registry controllati; un processo per container.

---

## Dockerfile e multi-stage build

### Concetto

Il Dockerfile definisce i layer dell'image: base (FROM), dipendenze (RUN, COPY), punto di ingresso (ENTRYPOINT/CMD). Il multi-stage build usa più stage (più FROM) per separare ambiente di build da ambiente di runtime, riducendo dimensione e superficie d'attacco.

### Flusso operativo

1. Stage di build: compilazione, package (Maven, npm, ecc.).
2. Stage finale: solo runtime (JRE, node) + artefatto copiato con `COPY --from=build`.

### Comando/esempio

```dockerfile
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY . .
RUN mvn -q -DskipTests package

FROM eclipse-temurin:21-jre
COPY --from=build /app/target/app.jar /app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
```

### Failure mode comune

Dockerfile a stadio singolo con compilatore e tool di build nell'image finale: image pesante e più vulnerabile.

### Best practice

Multi-stage per app compilate; usare utente non-root nello stage finale; `.dockerignore` per escludere file non necessari dal contesto di build.

---

## Layer e caching

### Concetto

Ogni istruzione del Dockerfile (RUN, COPY, ADD) crea un layer. Docker riusa la cache dei layer: se un'istruzione e il contesto non sono cambiati, il layer viene riusato. L'ordine delle istruzioni determina quando la cache si invalida.

### Flusso operativo

1. Docker valida i layer dall'alto: primo layer non corrispondente invalida tutti i successivi.
2. Mettere prima le istruzioni che cambiano meno (es. COPY package.json + RUN npm install), poi il codice (COPY . .).

### Comando/esempio

```dockerfile
# Buono: dipendenze cached finché package.json non cambia
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
RUN npm run build
```

### Failure mode comune

Mettere `COPY . .` all'inizio: ogni modifica al codice invalida tutta la cache e rallenta il build.

### Best practice

Ordine dal meno volatile al più volatile; usare cache mount dove supportato (`RUN --mount=type=cache` per package manager) per velocizzare i build.

---

## Volumi

### Concetto

I volumi persistono i dati oltre il ciclo di vita del container. **Bind mount**: path dell'host mappato nel container. **Named volume**: volume gestito da Docker, indipendente dal path dell'host; ideale per dati di database o condivisione tra container.

### Flusso operativo

1. Named: `docker volume create mydata`; in run: `-v mydata:/var/lib/data`.
2. Bind: `-v /host/path:/container/path` (dipende dalla struttura dell'host).

### Comando/esempio

```bash
# Named volume (portabile, gestito da Docker)
docker run -v dbdata:/var/lib/postgresql/data postgres:16

# Bind mount (sviluppo: codice locale nel container)
docker run -v "$(pwd)/src:/app/src" myapp:dev
```

### Failure mode comune

Dimenticare il volume per dati critici (DB, upload): al riavvio del container i dati sono persi.

### Best practice

Named volume per dati di produzione; bind mount per sviluppo locale; documentare i path di volume nelle guide deploy.

---

## Reti

### Concetto

Docker crea reti isolate. I container sulla stessa rete si raggiungono per nome (DNS interno). La rete **bridge** di default permette ai container di parlare tra loro e all'host di esporre porte con `-p`.

### Flusso operativo

1. Rete di default: `docker run` attacca il container alla bridge; `-p 8080:80` mappa porta host:container.
2. Rete custom: `docker network create mynet`; `docker run --network mynet ...`; i container si risolvono per nome.

### Comando/esempio

```bash
docker network create backend
docker run -d --name db --network backend postgres:16
docker run -d --name app -p 8080:8080 --network backend myapp:1.0
# L'app risolve "db" come hostname del container postgres
```

### Failure mode comune

Container su reti diverse non si vedono; aspettarsi "localhost" dall'host per un servizio che gira in un container (serve `-p` o un proxy).

### Best practice

Rete dedicata per stack correlati; evitare di esporre tutte le porte; usare nomi di container stabili per la risoluzione DNS.

---

## Registry e tag

### Concetto

Un registry è un server che memorizza image (Docker Hub, Harbor, registry OpenShift, ecc.). Il **tag** identifica una versione dell'image (es. `1.0`, `sha256:...`). In produzione evitare il tag `latest` per avere tracciabilità e rollback deterministici.

### Flusso operativo

1. Tag per registry: `docker tag myapp:1.0 registry.example.com/myapp:1.0`
2. Push: `docker push registry.example.com/myapp:1.0`
3. Pull su altro host: `docker pull registry.example.com/myapp:1.0`

### Comando/esempio

```bash
docker tag myapp:1.0 registry.company.com/myapp:1.0
docker push registry.company.com/myapp:1.0
docker pull registry.company.com/myapp:1.0
```

### Failure mode comune

Deploy in produzione con `latest`: nessuna garanzia su quale versione sia effettivamente in esecuzione; rollback difficile.

### Best practice

Tag semantici o digest (`@sha256:...`); scan vulnerabilità su image prima del deploy; registry privato per artefatti aziendali.

---

## Failure mode e best practice

### Failure mode comuni

- **Container effimero**: dati persi senza volume; usare volumi per stato e dati critici.
- **Image troppo grande**: build monostage con tool di build; usare multi-stage e base image slim.
- **Run as root**: aumenta il rischio in caso di compromissione; usare `USER` nel Dockerfile.
- **Secret in chiaro**: non mettere password o token in Dockerfile o in env in chiaro; usare secret manager o build-time secret con attenzione.

### Best practice enterprise

- User non-root nello stage finale del Dockerfile.
- Multi-stage build per ridurre dimensione e superficie d'attacco.
- `.dockerignore` per escludere `.git`, `node_modules`, file di build locali.
- Tag versionati e registry controllato; niente `latest` in prod.
- Policy di scan (CVE) e firma image dove richiesto dalla sicurezza.

---

## Docker Compose, health check e risorse

### Docker Compose
**Concetto**  
Docker Compose (file `docker-compose.yml`) definisce servizi multipli, reti e volumi in un unico file. Comando `docker compose up` avvia tutti i servizi; utile per sviluppo locale (app + DB + cache) e test integrati.

**Flusso operativo**  
Definire servizi con build o image, dipendenze (depends_on), porte, volumi e rete condivisa. Comando: `docker compose up -d`, `down`, `logs -f servizio`.

**Comando/esempio**  
`docker compose up -d`; nel file: servizi con nome, rete comune, volume per dati DB.

**Failure mode comune**  
Servizi che partono prima che il DB sia pronto; usare healthcheck sul DB e `depends_on: condition: service_healthy`. Porte in conflitto con host.

**Best practice**  
Compose per dev; in prod usare orchestrazione (K8s). Non committare secret nel file; usare env file esclusi da git.

### Health check in Dockerfile e runtime
**Concetto**  
`HEALTHCHECK` nel Dockerfile (o in `docker run`) definisce un comando che il motore esegue periodicamente; lo stato del container diventa healthy/unhealthy. Gli orchestrator (Kubernetes, Swarm) usano questa informazione per routing e restart.

**Flusso operativo**  
HEALTHCHECK CMD curl -f http://localhost:8080/health || exit 1; intervallo e timeout configurabili. In K8s si usano probe (liveness/readiness) indipendenti, ma l'immagine può fornire un endpoint coerente.

**Failure mode comune**  
Health check troppo pesante o lento; endpoint che dipende da dipendenze esterne (DB) e fallisce quando il DB è lento (meglio readiness separata in K8s).

**Best practice**  
Endpoint leggero (solo app viva); per readiness (posso ricevere traffico) usare probe che verificano DB/cache dove necessario.

### Limitare risorse (CPU, memoria)
**Concetto**  
`docker run --memory=512m --cpus=0.5` limita l'uso di memoria e CPU del container. Senza limiti un container può consumare tutte le risorse dell'host (OOM kill, starvation).

**Flusso operativo**  
In produzione sempre impostare limiti coerenti con le richieste Kubernetes (requests/limits). Memoria: oltre il limit il container viene killato (OOMKilled).

**Failure mode comune**  
Limite memoria troppo basso: OOMKilled frequenti; troppo alto: un container può affamare gli altri. Non impostare limiti in dev può mascherare leak.

**Best practice**  
Allineare a K8s requests/limits; monitorare uso effettivo e adattare; documentare i limiti per ogni servizio.

---

## BuildKit, log e sicurezza

### BuildKit e cache avanzata
**Concetto**  
BuildKit è il backend di build moderno (DOCKER_BUILDKIT=1); supporta cache esportabile/importabile (`--cache-from`, `--cache-to`), multi-stage ottimizzato e sintassi estesa (RUN --mount=type=cache per dipendenze).

**Flusso operativo**  
In CI: esportare cache su registry o su volume; build successivi importano cache per layer invariati. Riduce tempo di build per progetti grandi.

**Failure mode comune**  
Cache corrotta o non invalidata dopo cambio dipendenze; verificare che il layer che cambia (es. COPY package.json) sia prima del RUN install.

**Best practice**  
Abilitare BuildKit; in pipeline usare cache esterna (registry) per build cross-node; multi-stage con stage di build e stage finale minimale.

### Log driver e gestione log
**Concetto**  
I log stdout/stderr del container sono gestiti da un log driver (json-file default, syslog, journald, awslogs, ecc.). Limite di dimensione e rotazione (max-size, max-file) per evitare che i log riempiano il disco.

**Flusso operativo**  
Configurare in daemon.json o per container: `docker run --log-driver json-file --log-opt max-size=10m --log-opt max-file=3`. In K8s i log vanno su stdout e sono raccolti dall'infrastruttura (Fluentd, Loki).

**Failure mode comune**  
Log senza rotazione: disco pieno; driver che perde log in crash. In produzione preferire invio a sistema centralizzato (non solo file locale).

**Best practice**  
Rotazione obbligatoria; non loggare secret; formato strutturato (JSON) per parsing; in orchestrazione delegare a sidecar o collector.

### .dockerignore e riduzione contesto
**Concetto**  
Il contesto di build è l'insieme di file inviati al daemon (di solito la directory corrente). `.dockerignore` esclude file e directory (node_modules, .git, .env, build) riducendo dimensione e tempo di upload; evita anche di includere file sensibili nel contesto.

**Flusso operativo**  
Creare `.dockerignore` con righe come `node_modules`, `*.log`, `.git`; il build invia solo ciò che serve per COPY/ADD.

**Failure mode comune**  
Dimenticare .dockerignore: build lento e contesto enorme; includere .env o key per sbaglio (rischio sicurezza).

**Best practice**  
Sempre .dockerignore; escludere tutto ciò che non serve al COPY; non includere artefatti di build locali che devono essere rigenerati nel container.

## In sintesi

- Image immutabili; container effimeri; dati persistenti con volumi (named o bind mount).
- Dockerfile: multi-stage per dimensione ridotta; ordine layer per cache; USER non-root.
- Reti: bridge di default; rete custom per stack; risoluzione DNS per nome container.
- Registry e tag: evitare latest in prod; tag semantici o digest; scan vulnerabilità.
- Docker Compose per dev multi-servizio; HEALTHCHECK per stato container; limiti CPU/memoria; BuildKit e cache; log driver e rotazione; .dockerignore per contesto ridotto.

## Vedi anche

- [Kubernetes](kubernetes.md) e [OpenShift](openshift.md) — Orchestrazione.
- [Pipeline](pipeline.md) — Build image e deploy.
