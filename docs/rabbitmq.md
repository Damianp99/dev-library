# RabbitMQ

*Livello: Mid–Senior.*

- [Panoramica](#panoramica)
- [Exchange, queue e binding](#exchange-queue-e-binding)
- [Tipi di exchange](#tipi-di-exchange)
- [Producer e consumer](#producer-e-consumer)
- [Ack, re-delivery e dead letter](#ack-re-delivery-e-dead-letter)
- [Pattern tipici](#pattern-tipici)
- [Failure mode e operatività](#failure-mode-e-operatività)
- [Priority, TTL e quorum queue](#priority-ttl-e-quorum-queue)
- [Shovel, Federation e confronto Kafka](#shovel-federation-e-confronto-kafka)

## Panoramica

RabbitMQ è un **message broker** che instrada messaggi da **exchange** a **queue** in base a **binding** e tipo di exchange. I consumer leggono dalle queue; il broker gestisce consegna, ack, re-delivery e (con configurazione) dead letter. È adatto a task queue, routing per topic o broadcast, volumi moderati e latenza bassa. In questa guida: exchange, queue, binding, tipi di exchange, ack, DLQ e pattern comuni.

**Quando usare RabbitMQ (vs Kafka)**  
RabbitMQ: code di task (un messaggio = un job), routing complesso (topic, fanout), priorità messaggi, TTL per messaggio, pattern request/reply. Meno adatto a stream con retention lunga, replay e throughput estremo (dove Kafka è più naturale).

---

## Exchange, queue e binding

### Definizione

- **Exchange**: riceve i messaggi dal producer e li instrada alle queue. Non memorizza messaggi (salvo buffer temporanei); il routing dipende dal **tipo** di exchange e dai **binding**.
- **Queue**: memorizza i messaggi fino al consumo. I consumer sottoscrivono una queue e ricevono i messaggi (push model).
- **Binding**: regola che collega un’exchange a una queue, spesso con una **routing key** o pattern (a seconda del tipo di exchange).

**Flusso**  
Producer → publish su exchange (con routing key) → exchange valuta binding → messaggi copiati nelle queue legate → consumer consumano dalle queue.

**Caso d’uso**  
Exchange `orders` (tipo topic), binding `order.created` → queue `notifications`; binding `order.*` → queue `analytics`. Un messaggio con routing key `order.created` va a entrambe le queue.

---

## Tipi di exchange

| Tipo | Comportamento | Caso d’uso |
|------|---------------|------------|
| **Direct** | Messaggio alla queue il cui binding ha la stessa routing key | Una key = una coda (es. `order.created` → coda notifiche ordini) |
| **Topic** | Routing key come pattern (es. `order.*`, `*.created`) | Routing per categoria/tipo evento |
| **Fanout** | Ignora routing key; invia a tutte le queue bindate | Broadcast (es. aggiornamento cache a N servizi) |
| **Headers** | Match su header invece che routing key | Routing per attributi (meno comune) |

**Trade-off**  
Direct: semplice, una key = una coda. Topic: flessibile, ma pattern da progettare bene. Fanout: massima semplicità per broadcast.

**Errore tipico**  
Usare fanout quando serve routing selettivo (messaggi inutili a molti consumer); dimenticare di fare bind tra exchange e queue (messaggi scartati).

---

## Producer e consumer

### Producer

Il producer pubblica su un **exchange** con una **routing key** (e opzionalmente headers). Non invia direttamente alla queue (eccetto con default exchange e nome queue come routing key). Può usare **publisher confirms** per sapere quando il broker ha accettato il messaggio (durabilità).

**Persistenza**  
Queue e messaggi possono essere **durable**: sopravvivono al riavvio del broker. Message mode: `persistent` per scrivere su disco (trade-off latenza/throughput).

### Consumer

Il consumer sottoscrive una **queue** (push: il broker invia i messaggi). Dopo l’elaborazione invia **ack** (acknowledgment); se non ack o nack con requeue, il messaggio può essere ri-consegnato. **Prefetch** (QoS): quanti messaggi non ancora ack può avere un consumer; basso = load balancing migliore, alto = più throughput se il process è veloce.

**Trade-off**  
Ack automatico dopo delivery: semplice ma messaggio perso se il consumer crasha prima di averlo processato. Ack manuale dopo il process: at-least-once; stesso messaggio può essere ri-consegnato (idempotenza consumer obbligatoria).

---

## Ack, re-delivery e dead letter

### Ack e nack

- **Ack**: messaggio rimosso dalla queue; elaborazione completata con successo.
- **Nack (requeue=true)**: messaggio rimesso in coda (o in testa); può essere ri-consegnato subito (rischio loop se errore persistente).
- **Nack (requeue=false)** o scadenza senza ack: il messaggio può essere inviato a una **dead letter queue** (DLQ) se configurata.

### Dead letter queue (DLQ)

Una **dead letter queue** riceve messaggi che non sono stati consumati (nack senza requeue, TTL scaduto, queue piena, ecc.). Evita che messaggi “problematici” blocchino la coda e permette analisi e retry manuale o riconciliazione.

**Best practice**  
Configurare sempre una DLQ per code critiche; monitorare la DLQ e definire processo (retry, alert, archiviazione).

**Errore tipico**  
Requeue a oltranza su errore non transiente (loop infinito); non avere DLQ e perdere traccia dei messaggi falliti.

---

## Pattern tipici

### Task queue (worker)

Una exchange (es. direct) → una queue → N consumer. Un messaggio = un task; un solo consumer lo processa (load balancing). Ideale per job asincroni (invio email, resize immagini).

### Pub/sub (fanout)

Una exchange fanout → più queue (una per “tipo” di subscriber). Ogni messaggio va a tutte le queue. Utile per notifiche a più sottosistemi (cache, analytics, notifiche).

### Routing per topic

Exchange topic + routing key gerarchica (es. `order.created`, `order.shipped`) e binding con pattern (`order.*`, `#`). Un evento va solo alle queue il cui binding matcha.

### Request/reply (RPC)

Queue di risposta (reply_to, correlation_id); consumer elabora e pubblica la risposta sulla queue indicata. Kafka non è pensato per questo; RabbitMQ sì (con più complessità).

**Quando RabbitMQ vs Kafka**  
RabbitMQ: task queue, routing complesso, priorità, TTL per messaggio, request/reply. Kafka: event streaming, retention lunga, replay, throughput molto alto, molti consumer indipendenti sullo stesso stream.

---

## Failure mode e operatività

### Failure mode comuni

| Problema | Causa tipica | Mitigazione |
|----------|--------------|-------------|
| Messaggi persi | Queue/messaggi non durable; broker crash | Queue e messaggi durable; publisher confirms |
| Duplicati in consumo | Re-delivery dopo crash senza ack; consumer non idempotente | Consumer idempotente; ack dopo process |
| Coda che cresce | Consumer lenti o in errore; producer più veloci | Scalare consumer; prefetch; DLQ per messaggi falliti |
| Loop di re-delivery | Nack con requeue su errore persistente | Nack senza requeue + DLQ; retry con backoff e max retry |
| Connessione persa | Timeout di rete; broker restart | Client reconnection; connection recovery; idempotenza |

### Best practice operative

- **Durability**: queue e messaggi persistent dove serve garantire delivery; trade-off con latenza.
- **Publisher confirms**: abilitare per non perdere messaggi in invio.
- **Prefetch**: non troppo alto per evitare che un consumer lento trattenga troppi messaggi; non troppo basso per non limitare il throughput.
- **Monitoring**: lunghezza code, rate publish/consume, DLQ, connessioni.
- **Security**: TLS e autenticazione in produzione; permessi su vhost/queue/exchange.

---

## Priority, TTL e quorum queue

### Priority queue
**Definizione**  
Una queue può essere dichiarata con `x-max-priority` (es. 10): i messaggi possono avere un header `priority` (0–max); il broker consegna prima i messaggi a priorità più alta. Limitazione: la priorità è effettiva solo quando la queue ha messaggi; messaggi già in coda non vengono riordinati dinamicamente in tutte le versioni.

**Caso d'uso**  
Task con urgenza diversa (job critici prima di batch); attenzione al starvation (messaggi a bassa priorità che non vengono mai consumati se arriva sempre priorità alta).

**Failure mode**  
Priorità su queue senza x-max-priority ignorata; troppi livelli di priorità che riducono l'efficacia del riordino.

### TTL messaggi e queue
**Definizione**  
- **TTL messaggio**: il producer può impostare `expiration` (ms) sul messaggio; il broker scarta il messaggio se non è consumato entro quel tempo.  
- **TTL queue**: `x-message-ttl` sulla queue: tutti i messaggi senza expiration ereditano questo TTL. I messaggi scaduti possono essere mandati a una dead letter exchange (configurazione `x-dead-letter-exchange`).

**Caso d'uso**  
Messaggi obsoleti (offerte a tempo, cache); delay queue: messaggio con TTL che va in DLQ e poi viene repubblicato (o si usa plugin delay). Evitare TTL troppo corto rispetto al tempo di elaborazione.

**Failure mode**  
TTL e DLQ: assicurarsi che la DLQ non abbia consumer che requeue all'infinito; messaggi persi se nessuno consuma dalla DLQ.

### Quorum queue vs classica
**Definizione**  
Le **quorum queue** (RabbitMQ 3.8+) sono replicate su N nodi (Raft-like); sopravvivono al failure di minoranza dei nodi. Le queue classiche (mirrored con policy) sono il modello storico; le quorum queue sono il replacement raccomandato per durabilità e HA.

**Caso d'uso**  
Alta disponibilità senza single point of failure; preferire quorum queue per nuove code critiche; queue classiche per carichi leggeri o dove la mirroring policy è già in uso.

**Failure mode**  
Quorum: più overhead e latenza; minoranza di nodi down può bloccare le scritture. Dimensionare il cluster (es. 3 nodi per tollerare 1 failure).

---

## Shovel, Federation e confronto Kafka

### Shovel e Federation
**Definizione**  
- **Shovel**: sposta messaggi da una queue (o exchange) a un'altra queue/exchange, anche su un broker remoto. Utile per migrazione, DR, collegamento tra cluster.  
- **Federation**: replica di exchange o queue tra broker (o cluster): i messaggi pubblicati su un exchange federato vengono inoltrati all'upstream; per code, i consumer federati prelevano dall'upstream.

**Caso d'uso**  
Multi-datacenter: shovel per copia messaggi; federation per topologia distribuita con consumer locali che attingono da upstream. Monitoring: verificare lag e connettività.

**Failure mode**  
Shovel/Federation down: messaggi che non fluiscono; retry e buffer da configurare; ordine non garantito tra nodi.

### Monitoring (management UI, metriche)
**Definizione**  
La management UI (plugin management) espone code, exchange, connessioni, consumer; metriche su publish rate, deliver rate, message count. Prometheus/Grafana con plugin prometheus o exporter per alert su lunghezza code, rate, consumer senza ack.

**Best practice**  
Alert su queue depth oltre soglia; su DLQ con messaggi; su consumer che non fanno ack (blocco); retention e rotazione log del broker.

### Confronto con Kafka (sintesi)
**Definizione**  
- **Throughput e retention**: Kafka: log con retention lunga, replay, throughput molto alto; RabbitMQ: messaggio consumato e rimosso (o TTL), throughput moderato.  
- **Ordering**: Kafka: per partition; RabbitMQ: per queue (single consumer per messaggio).  
- **Use case**: Kafka: event streaming, replay, molti consumer sullo stesso stream; RabbitMQ: task queue, routing complesso, priorità, TTL per messaggio, request/reply.

**Quando scegliere**  
Kafka per pipeline di eventi, log aggregati, retention e riprocessamento. RabbitMQ per job queue, routing per topic/fanout, latenza bassa e pattern richiesta/risposta. Vedi [Architettura — Message broker](architettura.md#message-broker-rabbitmq-e-kafka) e [Kafka](kafka.md) per dettagli.

## In sintesi

- RabbitMQ: **exchange** instrada a **queue** tramite **binding**; tipi principali: direct, topic, fanout.
- **Consumer** ricevono da queue (push); **ack** dopo elaborazione; **prefetch** per load balancing.
- **Dead letter queue** per messaggi non processabili; evitare requeue infinito.
- Pattern: task queue (N worker), pub/sub (fanout), routing (topic), request/reply.
- **Quando usare**: task queue, routing complesso, priorità, TTL; per stream/replay/throughput estremo valutare Kafka.
- Priority queue con x-max-priority; TTL su messaggio e queue, DLQ per scaduti; quorum queue per HA; Shovel e Federation per multi-DC; monitoring su depth e rate; confronto con Kafka (stream vs task queue).

## Vedi anche

- [Architettura — Event-driven e messaggistica](architettura.md#event-driven-e-messaggistica)
- [Architettura — Message broker: RabbitMQ e Kafka](architettura.md#message-broker-rabbitmq-e-kafka)
- [Kafka](kafka.md) — Confronto con event streaming (quando usare quale)
