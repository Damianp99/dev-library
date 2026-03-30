# Zero to Hero IT

## Obiettivo

Questa guida supporta la **preparazione ai colloqui tecnici** e il **ripasso** per ruoli backend, frontend, full-stack e DevOps. Ogni pagina è una reference con domande ricorrenti, risposte sintetiche, spiegazioni con trade-off e snippet dove utile. Puoi usarla per studiare in vista di un colloquio o per consolidare concetti sul lavoro.

!!! info "Veridicità e revisione"
    Il contenuto è **orientato al colloquio**; per versioni specifiche di linguaggi, framework e prodotti verifica sempre la **documentazione ufficiale**. Stack di riferimento usato per esempi e snippet: Node 20 LTS, Java 21, Python 3.12, Kubernetes 1.29+, PostgreSQL 16, MongoDB 7. Le guide sono riviste periodicamente; policy e criteri (fatto vs raccomandazione, fonti) sono descritti in [Per nuove risorse — Veridicità e policy](per-nuove-risorse.md#veridicità-e-policy-delle-guide).

## Come usare la guida

- Le guide sono organizzate per **macro-area**: Frontend, Backend, Database, Architettura e integrazione, DevOps (es. Guide > Backend > Java, Guide > DevOps > Docker).
- Scegli un **set** in base al tuo ruolo o alla tecnologia richiesta (vedi sotto).
- Usa i **[Percorsi di studio](percorsi.md)** come checklist per ruolo (Backend, Frontend, Full-stack, DevOps).
- Ogni guida ha un **indice interno** con link alle sezioni: usa l’indice per saltare all’argomento che ti interessa.
- Le risposte seguono uno schema coerente: domanda, risposta breve, spiegazione estesa e, quando serve, uno snippet o un esempio pratico.
- Per un percorso completo full-stack: parti da linguaggio e framework (es. [JavaScript](javascript.md) + [React](react.md) o [Java](java.md) + [Spring Boot](springboot.md)), aggiungi [Database](database.md), poi [Architettura](architettura.md) e [Sicurezza](sicurezza.md).
- Usa il **[Glossario](glossario.md)** per trovare rapidamente un termine e il link alla guida di riferimento.
- Usa **[Verifica te stesso](verifica-te-stesso.md)** per richiamare i concetti: leggi la domanda, rispondi a mente, poi apri il blocco per verificare.

### Per chi entra in azienda (onboarding)

Se **entri in azienda** e devi apprendere stack e pratiche in modo strutturato, la guida può essere usata come **onboarding tecnico**:

- **[Per nuove risorse](per-nuove-risorse.md)** — Come usare la guida per apprendere, timeline suggerita (primi giorni/settimane), mappa delle dipendenze tra guide, autovalutazione, riferimenti rapidi e link a risorse esterne.
- **Percorsi per ruolo** (tabella sotto) + **[Percorsi di studio](percorsi.md)** come checklist.
- **Timeline**: prima settimana linguaggio + framework; seconda DB e API; terza architettura, messaggistica ([Kafka](kafka.md), [RabbitMQ](rabbitmq.md)) e sicurezza se rilevanti.

## Percorsi per ruolo

| Ruolo | Parti da… |
|-------|------------|
| **Backend (Java)** | [Java](java.md), [Spring Boot](springboot.md), [Database](database.md) |
| **Backend (JS/TS)** | [Node.js](nodejs.md), [Database](database.md), [Architettura](architettura.md) |
| **Backend (Python)** | [Python](python.md), [Django](django.md) / [FastAPI](fastapi.md), [Database](database.md) |
| **Frontend** | [JavaScript](javascript.md), [TypeScript](typescript.md), [Angular](angular.md) o [React](react.md) |
| **Full-stack** | Un linguaggio BE + un framework FE + [Database](database.md) + [Architettura](architettura.md) e [Sicurezza](sicurezza.md) |
| **DevOps** | [Docker](docker.md), [Kubernetes](kubernetes.md), [Pipeline](pipeline.md), [Helm](helm.md); [OpenShift](openshift.md) se in ambito enterprise |

## Temi trasversali

Questi temi riguardano più ruoli e stack; conviene affrontarli dopo le basi di linguaggio e framework:

- **[Database](database.md)** — Modellazione, query, indici, transazioni; relazionale e NoSQL. Guide specifiche: [PostgreSQL](postgresql.md), [Oracle DB](oracle-db.md), [MongoDB](mongodb.md). Utile per BE e full-stack.
- **[Architettura](architettura.md)** — REST, microservizi, event-driven, CQRS, message broker. Tipico da senior/architect.
- **[Kafka](kafka.md)** e **[RabbitMQ](rabbitmq.md)** — Messaggistica e event streaming: quando usare quale, concetti operativi (topic/partition/consumer group vs exchange/queue/binding).
- **[Sicurezza](sicurezza.md)** — Auth (JWT, OAuth2), sicurezza API, OWASP Top 10. Rilevante per BE, FE e full-stack.

## Set disponibili
1. **FE**: JavaScript, TypeScript, Angular, [React](react.md).
2. **BE**: Java, Go, Spring Boot, paradigmi, pattern, best practice; [Node.js](nodejs.md) per backend JavaScript/TypeScript.
3. **BE (Python)**: Python, Django, FastAPI (type hints, ORM, API, async).
4. **DB**: [Database](database.md) (concetti generali); [PostgreSQL](postgresql.md), [Oracle DB](oracle-db.md), [MongoDB](mongodb.md) – relazionale (ACID, indici, replica) e NoSQL document (schema flessibile, aggregation, sharding).
5. **Architettura e design**: [Architettura](architettura.md) (REST, microservizi, event-driven, CQRS, message broker); [Kafka](kafka.md) e [RabbitMQ](rabbitmq.md) (messaggistica e event streaming); [Sicurezza](sicurezza.md) (auth, API, OWASP Top 10).
6. **Altre tecnologie**: [Vue.js](vue.md), [GraphQL](graphql.md), [Redis e cache](redis-cache.md).
7. **DevOps**: Docker, Kubernetes, OpenShift, pipeline, Helm. La documentazione DevOps è organizzata in cinque guide collegate: [Docker](docker.md) (base container), [Kubernetes](kubernetes.md) (orchestrazione), [OpenShift](openshift.md) (enterprise), [Pipeline](pipeline.md) (CI/CD), [Helm](helm.md) (packaging).

## Cosa trovi in questa documentazione

- **Ricerca full-text** (icona lente): cerca una parola o un concetto in tutte le guide.
- **Navigazione**: menu laterale con **Guide**, Glossario, Percorsi, Verifica; sotto Guide le macro-aree (**Frontend**, **Backend**, **Database**, ecc.) si **aprono e chiudono** cliccando sul titolo o sulla freccia. Footer con link *Precedente* / *Successivo* in ogni pagina.
- **Diagrammi**: dove utile, le guide usano diagrammi Mermaid (flussi, sequenze, architetture).
- **Copia codice**: pulsante per copiare gli snippet negli appunti.
- **Tema chiaro/scuro**: commutazione in base alle preferenze di sistema o scelta manuale.
- **[Per nuove risorse](per-nuove-risorse.md)**: onboarding tecnico — timeline suggerita, mappa dipendenze tra guide, autovalutazione, riferimenti rapidi.
- **[Glossario](glossario.md)**: termini tecnici con definizione breve e link alla guida.
- **[Percorsi di studio](percorsi.md)**: checklist per ruolo per organizzare lo studio.
- **[Verifica te stesso](verifica-te-stesso.md)**: domande per area con risposta nascosta in blocchi espandibili; utile per richiamo attivo prima del colloquio.
- **In sintesi** e **Vedi anche**: in coda a ogni guida, una sezione "In sintesi" (punti da portare al colloquio) e "Vedi anche" (link alle guide correlate).
- **Livello** (Junior/Mid/Senior): in cima a ogni guida una indicazione per prioritizzare lo studio in base all’annuncio.
- **Prova a spiegarlo**: in alcune guide (Java, Spring Boot, Angular, Database, Docker, Kubernetes) un prompt che invita a spiegare a voce il concetto appena letto.
- **Tab "In un colpo d'occhio" | "Dettaglio"**: in alcune domande (es. [Java](java.md), [Angular](angular.md)) la risposta è in due tab: sintesi rapida e dettaglio con snippet.
