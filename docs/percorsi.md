# Percorsi di studio

Usa questa pagina come **checklist** per prepararti al colloquio. Segna le guide che hai letto o ripassato (puoi usare un editor che supporta le task list, oppure tenere a mente i passi).

L’ordine suggerito è per **ruolo**; adatta in base all’annuncio e al livello (junior / mid / senior). Le guide sono in **Guide** per macro-area (es. Guide > Database > PostgreSQL).

---

## Indice

- [Backend (Java)](#backend-java)
- [Backend (JavaScript/TypeScript)](#backend-javascripttypescript)
- [Backend (Python)](#backend-python)
- [Frontend](#frontend)
- [Full-stack](#full-stack)
- [DevOps](#devops)

---

## Backend (Java)

- [ ] [Java](java.md) — OOP, collections, stream, concorrenza, eccezioni, JVM
- [ ] [Spring Boot](springboot.md) — IoC/DI, REST, JPA, profili, sicurezza base
- [ ] [Database](database.md) — Schema, query, indici, transazioni, ACID. *(Se in uso)* [PostgreSQL](postgresql.md), [Oracle DB](oracle-db.md)
- [ ] *(Consigliato per senior)* [Architettura](architettura.md) — REST, microservizi, event-driven
- [ ] *(Se usate in azienda)* [Kafka](kafka.md), [RabbitMQ](rabbitmq.md) — Messaggistica e event streaming
- [ ] *(Consigliato per senior)* [Sicurezza](sicurezza.md) — JWT, OAuth2, OWASP

## Backend (JavaScript/TypeScript)

- [ ] [JavaScript](javascript.md) — Scope, closure, event loop, async
- [ ] [TypeScript](typescript.md) — Tipi, generics, utility types
- [ ] [Node.js](nodejs.md) — Runtime, moduli, API, concorrenza
- [ ] [Database](database.md) — Modellazione, query, NoSQL se rilevante. *(Se in uso)* [PostgreSQL](postgresql.md), [MongoDB](mongodb.md)
- [ ] [Architettura](architettura.md) — API design, message broker
- [ ] *(Se usate)* [Kafka](kafka.md), [RabbitMQ](rabbitmq.md)
- [ ] [Sicurezza](sicurezza.md) — Auth, API sicure

## Backend (Python)

- [ ] [Python](python.md) — Paradigmi, typing, async, best practice
- [ ] [Django](django.md) oppure [FastAPI](fastapi.md) — ORM, API, middleware/auth
- [ ] [Database](database.md) — Relazionale e/o NoSQL in base allo stack. *(Se in uso)* [PostgreSQL](postgresql.md), [MongoDB](mongodb.md)

## Frontend

- [ ] [JavaScript](javascript.md) — Fondamentali
- [ ] [TypeScript](typescript.md) — Type safety, generics
- [ ] [Angular](angular.md) **oppure** [React](react.md) — Framework principale
- [ ] *(Opzionale)* [Vue.js](vue.md), [GraphQL](graphql.md)

## Full-stack

Completa un percorso **Backend** + **Frontend** sopra, poi:

- [ ] [Database](database.md). *(Se in uso)* [PostgreSQL](postgresql.md), [Oracle DB](oracle-db.md), [MongoDB](mongodb.md)
- [ ] [Architettura](architettura.md) — REST, microservizi, CQRS
- [ ] *(Se usate)* [Kafka](kafka.md), [RabbitMQ](rabbitmq.md)
- [ ] [Sicurezza](sicurezza.md) — JWT, OAuth2, OWASP Top 10
- [ ] *(Opzionale)* [Redis e cache](redis-cache.md)

## DevOps

- [ ] [Docker](docker.md) — Image, container, volumi, reti, Dockerfile
- [ ] [Kubernetes](kubernetes.md) — Pod, Deployment, Service, Ingress, ConfigMap/Secret
- [ ] [Pipeline](pipeline.md) — CI/CD, quality gate, strategie di release, rollback
- [ ] [Helm](helm.md) — Chart, values, upgrade/revision
- [ ] *(Se ambiente Red Hat)* [OpenShift](openshift.md) — Route, SCC, operator

---

## Come usare i percorsi

1. **Scegli il ruolo** più vicino alla posizione per cui ti candidi.
2. **Segui l’ordine** della checklist: prima le basi (linguaggio + framework), poi DB e architettura.
3. **Usa il [Glossario](glossario.md)** per ripassare i termini e saltare alla guida giusta.
4. **Usa la ricerca** del sito (icona lente) per trovare rapidamente un concetto in tutte le guide.
