# Glossario

Raccolta di **termini tecnici** ricorrenti nei colloqui, con definizione breve e link alla guida di riferimento per approfondire.

---

## Indice

- [A–C](#a-c)
- [D–J](#d-j)
- [K–O](#k-o)
- [P–Z](#p-z)

---

## A–C

| Termine | Definizione breve | Guida |
|--------|-------------------|-------|
| **ACID** | Proprietà delle transazioni: Atomicità, Consistenza, Isolamento, Durabilità. | [Database](database.md) |
| **API REST** | Architettura per API HTTP basata su risorse, metodi HTTP e stateless. | [Architettura](architettura.md) |
| **Auth / Autorizzazione** | Autenticazione (chi sei) e autorizzazione (cosa puoi fare). JWT, OAuth2, sessioni. | [Sicurezza](sicurezza.md) |
| **Change detection** | Meccanismo con cui il framework aggiorna la vista quando cambiano i dati (es. Angular). | [Angular](angular.md) |
| **CI/CD** | Continuous Integration e Continuous Delivery/Deployment: build, test e rilascio automatizzati. | [Pipeline](pipeline.md) |
| **Container** | Unità di esecuzione isolata (es. Docker) che condividono il kernel dell’host. | [Docker](docker.md) |
| **Consumer group** | In Kafka: gruppo di consumer che condividono il consumo di un topic; ogni partition è letta da un solo consumer del gruppo. | [Kafka](kafka.md) |
| **CQRS** | Command Query Responsibility Segregation: separazione tra comandi (scrittura) e query (lettura). | [Architettura](architettura.md) |
| **Content projection** | In Angular: inserire template del parent nel child tramite ng-content (slot). | [Angular](angular.md) |
| **Contract testing** | Verifica che consumer e provider rispettino un contratto (es. Pact); usato in pipeline. | [Architettura](architettura.md) |

## D–J

| Termine | Definizione breve | Guida |
|--------|-------------------|-------|
| **Data Guard** | Replica e disaster recovery in Oracle: primary e standby (fisico o logico); failover e switchover. | [Oracle DB](oracle-db.md) |
| **Dead letter queue (DLQ)** | Coda che riceve messaggi non processabili (nack, TTL scaduto); usata per retry o analisi. | [RabbitMQ](rabbitmq.md) |
| **Deployment (K8s)** | Oggetto Kubernetes che dichiara lo stato desiderato dei pod (repliche, immagine, rollout). | [Kubernetes](kubernetes.md) |
| **Exchange (RabbitMQ)** | Componente che riceve i messaggi dal producer e li instrada alle queue in base al tipo (direct, topic, fanout) e ai binding. | [RabbitMQ](rabbitmq.md) |
| **DI (Dependency Injection)** | Pattern per fornire le dipendenze dall’esterno; usato in Spring, Angular, ecc. | [Spring Boot](springboot.md), [Angular](angular.md) |
| **Dockerfile** | File di istruzioni per costruire un’immagine Docker (layer, multi-stage). | [Docker](docker.md) |
| **Event loop** | Modello di concorrenza in JavaScript: una coda di task e un singolo thread che li esegue. | [JavaScript](javascript.md) |
| **Helm chart** | Pacchetto di risorse Kubernetes con valori parametrizzabili e versioning. | [Helm](helm.md) |
| **Ingress** | Oggetto Kubernetes per esporre servizi HTTP/HTTPS all’esterno del cluster. | [Kubernetes](kubernetes.md) |
| **JWT** | JSON Web Token: token stateless per autenticazione/claims, firmato (HMAC o RSA). | [Sicurezza](sicurezza.md) |
| **DataLoader** | Pattern/libreria per batch e cache di caricamenti (es. in GraphQL) e riduzione N+1. | [GraphQL](graphql.md) |
| **Error Boundary** | In React: componente che cattura errori nel subtree di rendering e mostra fallback. | [React](react.md) |

## K–O

| Termine | Definizione breve | Guida |
|--------|-------------------|-------|
| **Kafka** | Piattaforma di event streaming: log distribuito con topic, partition, consumer group; alto throughput, retention, replay. | [Kafka](kafka.md) |
| **Join (SQL)** | Operazione che combina righe di due o più tabelle in base a una condizione. | [Database](database.md) |
| **Normalizzazione** | Processo di progettazione del DB per ridurre ridondanza e anomalie (1NF, 2NF, 3NF). | [Database](database.md) |
| **NoSQL** | Famiglia di DB non relazionali: key-value, document, column-family; trade-off su consistenza. | [Database](database.md) |
| **OOP** | Programmazione orientata agli oggetti: incapsulamento, ereditarietà, polimorfismo. | [Java](java.md), [Python](python.md) |
| **OpenShift** | Piattaforma Kubernetes enterprise (Red Hat) con route, SCC, operator e tooling integrato. | [OpenShift](openshift.md) |
| **Idempotency key** | Identificatore inviato dal client per operazioni non ripetibili; il server restituisce stesso risultato per stessa key. | [Architettura](architettura.md) |
| **Liveness / Readiness** | Probe Kubernetes: liveness = sono vivo; readiness = posso ricevere traffico. | [Kubernetes](kubernetes.md), [Spring Boot](springboot.md) |

## P–Z

| Termine | Definizione breve | Guida |
|--------|-------------------|-------|
| **MVCC** | Multi-Version Concurrency Control: letture senza lock su snapshot; usato in PostgreSQL (e altri DB) per concorrenza. | [PostgreSQL](postgresql.md) |
| **Partition (Kafka)** | Suddivisione di un topic: log ordinato con offset; l'ordine è garantito solo dentro una partition. | [Kafka](kafka.md) |
| **PgBouncer** | Connection pooler per PostgreSQL: riduce connessioni attive e latenza; modalità transaction o session. | [PostgreSQL](postgresql.md) |
| **Pod** | Unità minima deployabile in Kubernetes: uno o più container che condividono rete e storage. | [Kubernetes](kubernetes.md) |
| **Polimorfismo** | Possibilità di usare un tipo base per riferirsi a sottotipi; binding del metodo a runtime. | [Java](java.md) |
| **RAC** | Real Application Clusters (Oracle): più istanze su stesso database (storage condiviso) per HA e scalabilità. | [Oracle DB](oracle-db.md) |
| **RabbitMQ** | Message broker: exchange, queue, binding; task queue, routing (direct, topic, fanout), DLQ. | [RabbitMQ](rabbitmq.md) |
| **Reactive / RxJS** | Programmazione reattiva con stream e operatori (map, filter, merge); usata in Angular. | [Angular](angular.md) |
| **Replica set** | In MongoDB: gruppo di nodi (primary + secondary) che replicano i dati; HA e letture da secondary. | [MongoDB](mongodb.md) |
| **Rollback** | Ritorno a una versione precedente dopo un deploy problematico; strategie in K8s/Helm. | [Kubernetes](kubernetes.md), [Helm](helm.md), [Pipeline](pipeline.md) |
| **Route (OpenShift)** | Esposizione di un servizio tramite hostname e TLS; analogo a Ingress in K8s. | [OpenShift](openshift.md) |
| **Service (K8s)** | Astrazione che espone un set di pod come endpoint di rete stabile (clusterIP, NodePort, LoadBalancer). | [Kubernetes](kubernetes.md) |
| **Sharding** | Partizionamento orizzontale dei dati su più nodi per scalare letture/scritture. | [Database](database.md) |
| **Stream API (Java)** | API per elaborare sequenze di dati in modo dichiarativo (map, filter, reduce). | [Java](java.md) |
| **Type safety** | Controllo dei tipi a compile-time per ridurre errori; TypeScript aggiunge tipi a JavaScript. | [TypeScript](typescript.md) |
| **Volume (Docker/K8s)** | Persistenza dei dati oltre il ciclo di vita del container; bind mount, volume named. | [Docker](docker.md), [Kubernetes](kubernetes.md) |
| **PDB (PodDisruptionBudget)** | In Kubernetes: vincolo su quanti pod devono restare disponibili durante voluntary disruption (drain). | [Kubernetes](kubernetes.md) |
| **Schema Registry** | Registro degli schema (Avro, JSON Schema) per messaggi Kafka; evoluzione e compatibilità. | [Kafka](kafka.md) |
| **Strict mode** | In JavaScript: "use strict" disattiva comportamenti silenziosi e riduce bug. | [JavaScript](javascript.md) |
| **TrackBy** | In Angular *ngFor: funzione che associa ogni elemento a un'identità stabile per performance. | [Angular](angular.md) |

---

*Puoi usare la **ricerca** del sito (icona lente) per trovare altri termini nelle guide.*
