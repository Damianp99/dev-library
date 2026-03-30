# Kafka

*Livello: Mid–Senior.*

- [Panoramica](#panoramica)
- [Topic, partition e log](#topic-partition-e-log)
- [Producer e consumer](#producer-e-consumer)
- [Consumer group e scaling](#consumer-group-e-scaling)
- [Offset e retention](#offset-e-retention)
- [Idempotenza e exactly-once](#idempotenza-e-exactly-once)
- [Failure mode e operatività](#failure-mode-e-operatività)
- [Schema Registry e Kafka Streams](#schema-registry-e-kafka-streams)
- [Compaction, monitoring e sicurezza](#compaction-monitoring-e-sicurezza)

## Panoramica

Apache Kafka è una piattaforma di **event streaming** distribuita: messaggi sono scritti in **topic** partizionati (log ordinati e persistiti); i consumer leggono in base all’**offset** e possono rileggere (replay). È adatta ad alto throughput, retention lunga e integrazione tra molti produttori e consumer. In questa guida: modello log, partition, consumer group, offset, retention, idempotenza e failure mode comuni.

**Quando usare Kafka (vs RabbitMQ)**  
Kafka: stream di eventi, throughput molto alto, retention configurabile, replay, più consumer indipendenti sullo stesso stream. Meno adatto a task queue con ack per singolo messaggio o routing complesso tipo exchange.

---

## Topic, partition e log

### Definizione

Un **topic** è un nome logico (es. `orders`, `payments`) sotto cui vengono scritti i messaggi. Ogni topic è diviso in una o più **partition**: ogni partition è un **log append-only** ordinato e immutabile. I messaggi in una partition hanno un **offset** sequenziale (0, 1, 2, …). L’ordine è garantito **solo dentro una partition**, non tra partition diverse.

**Partition key**  
Il producer può associare una chiave al messaggio; Kafka usa la chiave (hash) per decidere in quale partition scrivere. Messaggi con la stessa chiave finiscono nella stessa partition (utile per ordinamento per chiave).

**Caso d’uso**  
Topic `orders`: partition per `orderId` per avere tutti gli eventi di un ordine nello stesso ordine; oppure partizioni senza chiave per distribuzione round-robin e massimo parallelismo.

**Trade-off**  
Più partition = più parallelismo (più consumer in un group), ma più overhead e più file su disco. Una sola partition = ordine globale ma nessun parallelismo di consumo.

**Errore tipico**  
Topic con una sola partition quando servono molti consumer in parallelo; oppure troppe partition per carico modesto (complessità inutile).

---

## Producer e consumer

### Producer

Il **producer** invia record (chiave, valore, eventuale partition/timestamp) a un topic. Può specificare la partition oppure lasciare che il broker la scelga in base alla chiave. Modalità di acknowledgment: `acks=0` (fire and forget), `acks=1` (leader), `acks=all` (leader + replica in sync) per durabilità.

**Snippet concettuale**

```text
Produce → record (key, value) → topic
Broker assegna partition (key hash o round-robin)
Ritorno: offset e partition (se acks > 0)
```

**Caso d’uso**  
`acks=all` in produzione per non perdere messaggi; `acks=1` come compromesso latenza/durabilità; idempotenza producer (Kafka 3+) per evitare duplicati in caso di retry.

### Consumer

Il **consumer** legge record da uno o più topic (e partition) a partire da un offset. Legge in batch; dopo l’elaborazione committa l’offset (manuale o automatico) per riprendere da lì in caso di riavvio.

**Trade-off**  
Commit automatico: semplice ma rischio di perdere messaggi se il consumer crasha dopo la lettura e prima del commit. Commit manuale dopo l’elaborazione: at-least-once se si committa dopo il process; attenzione a non committare prima di aver finito (duplicati al replay).

---

## Consumer group e scaling

### Definizione

Un **consumer group** è un insieme di consumer che condividono un `group.id`. Ogni **partition** del topic è assegnata a **al massimo un** consumer del gruppo. Aggiungendo consumer, si può scalare il consumo fino a un massimo di consumer = numero di partition; consumer in più restano idle.

**Rebalance**  
Quando un consumer entra o esce, il coordinator riassegna le partition (rebalance). Durante il rebalance il consumo può fermarsi brevemente; evitare rebalance frequenti (session timeout, heartbeat).

**Caso d’uso**  
Gruppo `order-processors` con 3 consumer e topic a 6 partition: ogni consumer gestisce 2 partition. Throughput di lettura = somma del throughput dei consumer attivi.

**Errore tipico**  
Più consumer che partition (gli extra non ricevono messaggi); non dimensionare le partition in anticipo per il numero di consumer desiderato.

---

## Offset e retention

### Offset

L’**offset** è l’indice del messaggio dentro una partition. Il consumer group mantiene l’offset committato (in Kafka `__consumer_offsets` o storage esterno). Al riavvio il consumer riprende dall’ultimo offset committato.

**Politiche di reset**  
`earliest`: dall’inizio del log (replay completo). `latest`: solo messaggi nuovi. In produzione attenzione a non usare `latest` per gruppi nuovi se serve processare anche messaggi già presenti.

### Retention

I messaggi restano nel log per un tempo o una dimensione massima configurabile (**retention**). Scaduti vengono rimossi. Retention lunga permette replay e riprocessamento; costa spazio e può aumentare latenza di compattazione.

**Caso d’uso**  
Log di eventi per analitica: retention 7–30 giorni. Stream operativo: retention più breve (es. 1 giorno) se non serve replay lungo.

---

## Idempotenza e exactly-once

### Idempotenza consumer

Con at-least-once delivery lo stesso messaggio può essere consegnato più volte (rebalance, retry). Il **consumer deve essere idempotente**: processare due volte lo stesso record deve dare lo stesso effetto (es. upsert per chiave, non “incrementa contatore” senza deduplicazione).

**Tecniche**  
Tabella “già processati” (message key/offset + id consumer); oppure operazioni naturalmente idempotenti (es. “imposta stato a X” con chiave business).

### Exactly-once (cenni)

Kafka supporta exactly-once semantics con transazioni producer e consumer (read-process-write in una transazione). Complessità operativa e limitazioni (es. sink esterni); in molti contesti at-least-once + idempotenza consumer è il compromesso adottato.

**Errore tipico**  
Assumere exactly-once senza aver configurato transazioni e idempotenza; “inserisci riga” senza chiave univoca o controllo duplicati.

---

## Failure mode e operatività

### Failure mode comuni

| Problema | Causa tipica | Mitigazione |
|----------|--------------|-------------|
| Messaggi persi | Producer con `acks=0` o `acks=1` e leader che fallisce prima della replica | `acks=all`; replica factor ≥ 2 |
| Duplicati in consumo | Commit prima dell’elaborazione; crash dopo read, prima di commit | Commit dopo process; consumer idempotente |
| Lag consumer alto | Consumer troppo lenti o troppo pochi | Aumentare partition e consumer; ottimizzare elaborazione; parallelismo interno |
| Rebalance frequenti | Timeout sessione corto; elaborazione lunga senza heartbeat | Aumentare `session.timeout`; processare in batch più piccoli; heartbeat in thread separato |
| Retention troppo corta | Configurazione | Aumentare retention se serve replay; monitorare spazio disco |

### Best practice operative

- **Monitoring**: lag per consumer group, throughput producer/consumer, error rate, retention e spazio.
- **Partition**: dimensionare il numero di partition in base al throughput e al numero di consumer desiderato; aumentare partition è possibile ma può richiedere piani di migrazione.
- **Schema**: usare schema registry (Avro, Protobuf) per evoluzione compatibile dei payload.
- **Security**: SSL/TLS e SASL in produzione; ACL su topic e consumer group.

---

## Schema Registry e Kafka Streams

### Schema Registry (Avro, JSON Schema)
**Definizione**  
Lo Schema Registry (Confluent o compatibili) memorizza gli schema dei messaggi (Avro, JSON Schema, Protobuf) e assegna un ID per versione. Producer e consumer serializzano/deserializzano usando l'ID nello header del messaggio; evoluzione controllata con politiche di compatibilità (backward, forward, full).

**Caso d'uso**  
Evoluzione dello schema senza rompere consumer vecchi; validazione in ingresso; riduzione della dimensione del payload (Avro binario con ID invece di schema inline).

**Failure mode**  
Registry non disponibile: producer/consumer non possono serializzare; caching locale degli schema e retry. Compatibilità: aggiungere campi opzionali è backward compatible; rimuovere campi richiede forward compatibility o nuova versione.

### Kafka Streams (cenni)
**Definizione**  
Kafka Streams è una libreria per elaborare stream: leggere da topic, trasformare, aggregare, join e scrivere su altri topic. Modello stream: record per record (o windowed); stato locale (store) per aggregazioni e join.

**Caso d'uso**  
Enrichment (join con tabella), aggregazioni (conteggi, somme per chiave), filtri, trasformazioni. Scaling: come i consumer, più istanze con stesso application.id condividono le partition.

**Failure mode**  
Stato locale: da backuppare e da dimensionare; changelog topic per recovery. Non sostituisce un motore batch (Spark) per job one-off molto pesanti.

---

## Compaction, monitoring e sicurezza

### Compaction log
**Definizione**  
La log compaction mantiene per ogni chiave l'ultimo valore (o l'ultimo N valori); rimuove i record obsoleti per chiave. Utile per topic che rappresentano stato (es. snapshot di entità): solo l'ultimo stato per chiave resta, riducendo lo spazio e permettendo consumer che leggono "stato attuale".

**Caso d'uso**  
Changelog per materialized view, cache distribuita (topic come key-value), snapshot di entità. Non per eventi che non hanno chiave o dove tutti i messaggi devono essere conservati (usare retention per tempo).

**Failure mode**  
Compaction in ritardo: topic cresce; tuning di min.cleanable.dirty.ratio e segment size.

### Monitoring: lag, throughput, broker
**Definizione**  
Metriche chiave: **consumer lag** (differenza tra ultimo offset del topic e offset committato dal consumer group) — lag alto indica consumer lenti o sotto-dimensionati. Throughput: messaggi/sec per topic/partition. Broker: disco, CPU, under-replicated partition (replica in ritardo).

**Caso d'uso**  
Alert su lag oltre soglia; dashboard su throughput e latenza; capacità planning (partition e broker). Tool: Kafka Manager, Confluent Control Center, Prometheus + JMX exporter.

**Failure mode**  
Lag che cresce senza alert; under-replicated partition non risolte (perdita repliche in caso di failure).

### Multi-datacenter e replica
**Definizione**  
Replica tra datacenter: MirrorMaker 2 (o Confluent Replicator) consuma da cluster sorgente e produce su cluster destinazione; configurazione per topic filter e offset sync. Use case: DR, geo-distribuzione, aggregazione da più regioni.

**Failure mode**  
Replication lag; ordinamento non preservato tra DC; failover e sincronizzazione offset da pianificare.

### Security (SASL, TLS, ACL)
**Definizione**  
- **TLS**: cifratura e autenticazione server (e client con mTLS).  
- **SASL**: autenticazione (PLAIN, SCRAM, GSSAPI/Kerberos).  
- **ACL**: permessi per risorse (topic, consumer group, cluster); principal (utente) e operazione (Read, Write, Describe, ecc.).

**Caso d'uso**  
Produzione: TLS per trasporto; SASL per identità; ACL per limitare chi può produrre/consumare su quali topic. Principio least privilege: un servizio solo sui topic che gli servono.

**Failure mode**  
ACL troppo permissivi; certificati scaduti; principal condivisi tra servizi (no audit granulare).

## In sintesi

- Kafka è un **log distribuito**: topic, partition, offset; ordine per partition, non globale.
- **Consumer group**: una partition = un consumer del gruppo; scaling fino a N consumer = N partition.
- **Retention** configurabile: permette replay e riprocessamento; trade-off con spazio e latenza.
- **At-least-once** + **idempotenza consumer** è il modello più comune; exactly-once possibile con transazioni.
- **Failure mode**: perdita messaggi (acks), duplicati (commit timing), lag (throughput/partition), rebalance (timeout/heartbeat).
- Schema Registry per evoluzione schema e compatibilità; Kafka Streams per elaborazione stream; compaction per topic stato; monitoring (lag, throughput, under-replicated); replica multi-DC; SASL, TLS, ACL in produzione.

## Vedi anche

- [Architettura — Event-driven e messaggistica](architettura.md#event-driven-e-messaggistica)
- [Architettura — Message broker: RabbitMQ e Kafka](architettura.md#message-broker-rabbitmq-e-kafka)
- [RabbitMQ](rabbitmq.md) — Confronto con code e exchange (quando usare quale)
