# Per nuove risorse

Questa sezione rende la guida utile a **chi entra in azienda** e deve apprendere stack, terminologia e pratiche in modo strutturato. Oltre alla preparazione al colloquio, puoi usarla come **onboarding tecnico**: percorsi per ruolo, autovalutazione, riferimenti rapidi e timeline suggerita.

---

## Indice

- [Come usare la guida per apprendere](#come-usare-la-guida-per-apprendere)
- [Veridicità e policy delle guide](#veridicità-e-policy-delle-guide)
- [Timeline suggerita (primi giorni / settimane)](#timeline-suggerita-primi-giorni--settimane)
- [Mappa delle dipendenze tra guide](#mappa-delle-dipendenze-tra-guide)
- [Autovalutazione e da dove partire](#autovalutazione-e-da-dove-partire)
- [Riferimenti rapidi e cheat sheet](#riferimenti-rapidi-e-cheat-sheet)
- [Risorse esterne e approfondimenti](#risorse-esterne-e-approfondimenti)

---

## Come usare la guida per apprendere

1. Se manca l’ambiente (Git, editor, Node.js, Python), parti da **[Primi passi](primi-passi.md)**. Questa pagina spiega come studiare, non come installare.
2. **Identifica il tuo ruolo** (Backend, Frontend, Full-stack, DevOps) e apri i **[Percorsi di studio](percorsi.md)**: usa la checklist come piano di lettura.
3. **Parti dalle basi**: linguaggio e framework del tuo stack (es. Java + Spring Boot, oppure JavaScript + React). Evita di saltare ai temi “avanzati” (es. Kafka, CQRS) senza aver consolidato REST, DB e concetti di servizi.
4. **Usa l’indice interno** di ogni guida: ogni pagina ha link alle sezioni; salta alle voci che ti servono per il contesto in cui lavori.
5. **Verifica te stesso**: dopo aver letto un blocco di guide, usa **[Verifica te stesso](verifica-te-stesso.md)** per richiamare i concetti a mente; apri la risposta solo dopo aver provato a rispondere.
6. **Glossario**: quando incontri un termine nuovo, cercalo nel **[Glossario](glossario.md)** per una definizione breve e il link alla guida di riferimento.
7. **Ricerca**: usa la ricerca del sito (icona lente) per trovare un concetto in tutte le guide (es. “idempotenza”, “consumer group”).

---

## Veridicità e policy delle guide

Le guide sono orientate al colloquio tecnico e all'onboarding: contengono **fatti verificabili** (comportamento di linguaggi, API, comandi) e **raccomandazioni** (best practice, trade-off). Per mantenere informazioni corrette e trasparenti:

**Classificazione del contenuto**

| Tipo | Esempio | Come verificare |
|------|---------|------------------|
| **Fatto** | Comportamento di un comando, semantica di un costrutto | Documentazione ufficiale, help CLI, esecuzione snippet con versione dichiarata |
| **Default / versione** | "Django usa PBKDF2 di default", "IDENTITY da Oracle 12c" | Release notes e doc versionata; indicare la versione di riferimento nella guida |
| **Sicurezza / standard** | OWASP, JWT, header, CORS | Fonti primarie (OWASP, RFC, documentazione del framework) |
| **Raccomandazione** | "In enterprise si preferisce…", "sempre definire requests" | Esplicitare il criterio (sicurezza, manutenibilità, costo); non presentare come unica verità |

**Per il lettore**

- Il contenuto va verificato sulla **documentazione ufficiale** per versioni specifiche del linguaggio, framework o prodotto.
- Licenze e costi (es. Oracle) vanno confermati con il fornitore; le guide non sostituiscono consulenza legale o commerciale.
- Le "best practice" sono linee guida contestuali; in produzione valuta sempre il tuo contesto (team, carico, vincoli).

**Per chi contribuisce**

- Per **fatti e comandi**: usare come fonte la doc ufficiale (link alla sezione quando possibile); per snippet, testare con una versione LTS/stable dichiarata.
- Per **raccomandazioni**: evitare affermazioni assolute ("sempre", "mai") senza criterio; preferire "è consigliato… quando…".
- **Revisione**: le guide vanno riviste periodicamente (es. a ogni major del stack); in [Panoramica](index.md) è indicato lo stack di riferimento e la data di ultima revisione.

---

## Timeline suggerita (primi giorni / settimane)

Ordine indicativo per **chi deve apprendere** in vista di un ruolo; adatta in base al tempo disponibile e al focus del team.

| Fase | Backend (Java) | Backend (Python) | Frontend | DevOps |
|------|----------------|------------------|----------|--------|
| **Settimana 1** | [Java](java.md), [Spring Boot](springboot.md) base | [Python](python.md), [Django](django.md) o [FastAPI](fastapi.md) base | [JavaScript](javascript.md), [TypeScript](typescript.md), framework (Angular/React) | [Docker](docker.md), [Kubernetes](kubernetes.md) base |
| **Settimana 2** | [Database](database.md), REST e API | [Database](database.md), API e async | [Angular](angular.md) o [React](react.md) in profondità, [GraphQL](graphql.md) se usato | [Pipeline](pipeline.md), [Helm](helm.md); [OpenShift](openshift.md) se rilevante |
| **Settimana 3+** | [Architettura](architettura.md), [Sicurezza](sicurezza.md), [Kafka](kafka.md) / [RabbitMQ](rabbitmq.md) se usati | Idem + [Redis e cache](redis-cache.md) se usato | [Sicurezza](sicurezza.md), performance, testing | Rollout, rollback, osservabilità, [Redis](redis-cache.md) se in pipeline |

Per **messaggistica (Kafka / RabbitMQ)**:
- Conviene aver già chiaro: REST, microservizi, eventual consistency e idempotenza (in [Architettura](architettura.md)).
- Poi: [RabbitMQ](rabbitmq.md) per code e task; [Kafka](kafka.md) per event streaming e throughput alto.

---

## Mappa delle dipendenze tra guide

Per **apprendere in ordine sensato**, tieni presente queste dipendenze concettuali:

- **REST / API** → utile prima di Architettura, Sicurezza, microservizi.
- **Database** → utile prima di Architettura (CQRS, consistenza), Spring Boot (JPA), Django/FastAPI (ORM).
- **Architettura (event-driven, broker)** → utile prima di Kafka e RabbitMQ (perché usare code/eventi, at-least-once, idempotenza).
- **Docker** → consigliato prima di Kubernetes, OpenShift, Pipeline (build e deploy di container).
- **Kubernetes** → prima di Helm (packaging) e OpenShift (estensione enterprise).

Non è obbligatorio seguire l’ordine alla lettera, ma riduce confusione se i concetti “di sistema” (architettura, messaggistica) arrivano dopo linguaggio, framework e dati.

---

## Autovalutazione e da dove partire

- **Livello nelle guide**: in cima a ogni guida trovi un’indicazione tipo *Livello: Junior / Mid / Senior*: usa quella per dare priorità (es. prima le guide “da Junior”, poi le altre).
- **Percorsi per ruolo**: i **[Percorsi di studio](percorsi.md)** sono pensati come checklist; segna ciò che hai letto e cosa ti manca.
- **Verifica te stesso**: **[Verifica te stesso](verifica-te-stesso.md)** ti dice se hai davvero assimilato: leggi la domanda, rispondi a mente, poi apri il blocco. Se fai fatica, rileggi la guida collegata.
- **Domanda pratica**: “So spiegare a un collega perché usiamo X invece di Y?” (es. Kafka vs RabbitMQ, cache-aside vs write-through). Se sì, hai un buon livello operativo; se no, torna alla guida e alla sezione “Trade-off” / “Quando usare”.

---

## Riferimenti rapidi e cheat sheet

Per **consultazione veloce** durante il lavoro (comandi, concetti in una pagina):

- **Docker**: [Docker — Comandi e concetti](docker.md#panoramica): build, run, volumi, reti.
- **Kubernetes**: [Kubernetes](kubernetes.md): Pod, Deployment, Service, Ingress, ConfigMap/Secret; comandi `kubectl` nelle sezioni operative.
- **Pipeline**: [Pipeline](pipeline.md): stage tipici, quality gate, strategie di release, rollback.
- **Database**: [Database](database.md): indici, transazioni, normalizzazione; [Redis e cache](redis-cache.md): TTL, cache-aside, invalidazione.
- **Messaggistica**: [RabbitMQ](rabbitmq.md) (exchange, queue, binding); [Kafka](kafka.md) (topic, partition, consumer group, offset).

All’interno di ogni guida, le sezioni **“In sintesi”** in fondo sono pensate come ripasso rapido prima di un colloquio o di una discussione tecnica.

---

## Risorse esterne e approfondimenti

Quando vuoi andare **oltre la guida** (documentazione ufficiale, corsi, best practice):

- **Linguaggi e framework**: documentazione ufficiale (Java, Python, Spring, Angular, React, Vue) e, se disponibili, “Getting started” e “Best practices”.
- **Database**: doc del DB che usate (PostgreSQL, MySQL, MongoDB, ecc.) su indici, locking, backup.
- **Docker/Kubernetes**: [Docker Docs](https://docs.docker.com/), [Kubernetes Docs](https://kubernetes.io/docs/); per OpenShift, [Red Hat OpenShift Docs](https://docs.openshift.com/).
- **Kafka**: [Apache Kafka Documentation](https://kafka.apache.org/documentation/); concetti: topic, partition, consumer group, retention.
- **RabbitMQ**: [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html); concetti: exchange types, queue, binding, dead letter.

Usa la guida come **spina dorsale** (definizioni, trade-off, errori comuni) e le risorse esterne per dettagli implementativi e versioni aggiornate.

---

## In sintesi

- Usa **[Percorsi di studio](percorsi.md)** come piano di lettura per ruolo e **[Verifica te stesso](verifica-te-stesso.md)** per l’autovalutazione.
- Segui una **timeline** (es. prima settimana: linguaggio + framework; seconda: DB e API; terza: architettura e messaggistica).
- Rispetta le **dipendenze** tra guide (REST/DB prima di Architettura; Architettura prima di Kafka/RabbitMQ; Docker prima di K8s/Helm).
- Usa **Glossario** e **ricerca** per trovare rapidamente termini e concetti; le sezioni **“In sintesi”** come cheat sheet.

## Vedi anche

- [Panoramica e come usare la guida](index.md)
- [Percorsi di studio](percorsi.md)
- [Verifica te stesso](verifica-te-stesso.md)
- [Glossario](glossario.md)
