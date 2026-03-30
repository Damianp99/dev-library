# Redis e cache

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Pattern cache-aside](#pattern-cache-aside)
- [TTL e scadenza](#ttl-e-scadenza)
- [Invalidazione](#invalidazione)
- [Uso in backend e in pipeline](#uso-in-backend-e-in-pipeline)
- [Session store, pub/sub e strutture dati](#session-store-pubsub-e-strutture-dati)
- [Persistence, cluster e rate limiting](#persistence-cluster-e-rate-limiting)
- [Cache stampede e locking](#cache-stampede-e-locking)

## Panoramica

Redis è un datastore in-memory spesso usato come cache, session store, pub/sub e (con strutture dati) per code e rate limiting. In questa guida il focus è sul suo uso come **cache** in backend e in pipeline: pattern cache-aside, TTL, invalidazione e failure mode comuni (dati stale, thundering herd).

---

## Pattern cache-aside

### Concetto e flusso

**Definizione**  
Nel pattern cache-aside (lazy loading) l’applicazione gestisce la cache: prima legge dalla cache; in caso di miss interroga la fonte (DB, API) e scrive in cache il risultato; le letture successive usano la cache fino a scadenza o invalidazione.

**Flusso operativo**  
1. Ricevi richiesta (es. chiave `user:123`).  
2. Leggi dalla cache (Redis GET).  
3. Se hit: restituisci il valore.  
4. Se miss: leggi dal DB (o API); scrivi in cache (SET con eventuale TTL); restituisci il valore.

**Snippet**

```javascript
async function getUser(id) {
  const key = `user:${id}`;
  const cached = await redis.get(key);
  if (cached) return JSON.parse(cached);
  const user = await db.query("SELECT * FROM users WHERE id = $1", [id]);
  await redis.setex(key, 3600, JSON.stringify(user)); // TTL 1h
  return user;
}
```

**Failure mode comune**  
- **Dati stale**: cache non invalidata dopo update nel DB; i client vedono dati vecchi fino a TTL. Mitigazione: invalidazione su write (vedi sotto) o TTL breve.  
- **Thundering herd**: dopo scadenza molti request fanno miss contemporaneamente e tutti colpiscono il DB. Mitigazione: lock (es. Redis SETNX) per un solo processo che riempie la cache; gli altri attendono o usano valore stale se accettabile.

**Best practice**  
Chiavi con prefisso e formato coerente (`entity:id`); serializzazione (JSON, MessagePack) e gestione errori (se Redis non disponibile, fallback a DB e log); monitoraggio hit/miss ratio.

---

## TTL e scadenza

### Definizione e politiche

**Definizione**  
Il TTL (Time To Live) è il tempo dopo il quale la chiave viene rimossa automaticamente. In Redis si imposta con `SETEX`, `EXPIRE` o opzione `EX` in `SET`. Evita che la cache cresca senza limite e limita la “finestra” di dati stale.

**Politiche**  
- TTL fisso (es. 5 min, 1 ora): semplice; i dati possono essere stale fino a TTL.  
- TTL per tipo di dato: dati poco volatili (catalogo) TTL lungo; dati più volatili (prezzi, disponibilità) TTL breve.  
- Sliding expiration: rinnovare il TTL a ogni lettura (in Redis con GET + EXPIRE o pattern con Lua); utile per “sessioni” di utilizzo.

**Snippet**

```bash
# Redis
SET user:123 "..." EX 3600
EXPIRE user:123 3600
```

**Failure mode comune**  
TTL troppo lungo su dati che cambiano spesso: utenti vedono dati obsoleti. TTL troppo corto: molti miss e carico sul DB. Trovare un compromesso o usare invalidazione esplicita dove serve.

**Best practice**  
Impostare sempre un TTL di default per le chiavi di cache (evitare chiavi “eternità”); documentare TTL per dominio (es. sessioni 24h, API response 1–5 min).

---

## Invalidazione

### Time-based vs event-based

**Definizione**  
- **Time-based**: la cache scade dopo TTL; nessuna azione esplicita. Adeguata per dati che tollerano ritardo.  
- **Event-based (invalidazione su write)**: quando la fonte di verità cambia (DB update, evento), si invalida la cache (DELETE o SET con nuovo valore). Il prossimo read farà miss e caricherà il valore aggiornato.

**Caso d’uso**  
Dopo UPDATE su tabella `users` per `id = 123`: eliminare `user:123` (o aggiornare con il nuovo valore). In architetture event-driven: il consumer che applica l’update invalida la chiave corrispondente.

**Snippet**

```javascript
async function updateUser(id, data) {
  await db.query("UPDATE users SET ... WHERE id = $1", [id, ...]);
  await redis.del(`user:${id}`);
  // oppure: await redis.setex(`user:${id}`, ttl, JSON.stringify(updated));
}
```

**Failure mode comune**  
Invalidazione dimenticata: aggiornamento DB senza invalidare la cache (stale). Invalidazione troppo aggressiva (es. invalidare tutte le chiavi utente a ogni singolo update) con picchi di miss. Pattern “write-through” (scrivere sempre prima in cache e poi in DB) riduce il rischio stale ma aumenta complessità e coerenza da gestire.

**Best practice**  
Invalidare (o aggiornare) in prossimità della write; usare chiavi granulari (per id) invece di una sola chiave “tutti gli utenti”; in sistemi distribuiti considerare messaggi di invalidazione (pub/sub) se la cache è locale per processo.

---

## Uso in backend e in pipeline

### Backend: sessioni e API response cache

**Definizione**  
- **Sessioni**: lo stato di sessione (session_id → user_id, dati) viene salvato in Redis; stateless sull’app server: ogni istanza può leggere/aggiornare la sessione. TTL uguale alla durata massima della sessione.  
- **API response cache**: risposte di GET costose (aggregazioni, chiamate esterne) memorizzate con chiave che identifica la richiesta (es. hash di path + query); TTL in base a quanto sono “freschi” i dati accettabili.

**Caso d’uso**  
Login → crea sessione in Redis → cookie con session_id. Richiesta API “dashboard” → chiave `dashboard:user:123` → se hit restituisci; se miss calcola, salva in Redis, restituisci.

**Best practice**  
Non mettere dati sensibili in chiaro in Redis senza necessità; cifrare il payload delle sessioni se contiene PII; usare prefissi (`session:`, `api:`) per evitare collisioni e per pattern di flush.

### Pipeline: job e lock

**Definizione**  
Redis può essere usato per code di job (LIST con LPUSH/BRPOP), per lock distribuiti (SET NX con TTL) e per rate limiting (INCR + EXPIRE o strutture dedicate). In pipeline CI/CD o worker: lock per evitare esecuzione concorrente dello stesso job; coda per distribuire task.

**Caso d’uso**  
- **Lock**: prima di eseguire un job “nightly-report”, acquisire lock `lock:nightly-report` (SET key NX EX 300); se ok eseguire, poi rilasciare (DEL); se fallito ritentare più tardi.  
- **Queue**: producer LPUSH in `queue:emails`; worker BRPOP; TTL su messaggio o su lock del consumer per evitare messaggi persi se il worker muore.

**Failure mode comune**  
Lock senza TTL: se il processo che tiene il lock crasha, il lock resta per sempre (deadlock). Lock con TTL troppo lungo: in caso di crash un altro processo deve aspettare la scadenza. Redlock (multi-instanza Redis) è un pattern per HA, con [trade-off e documentazione ufficiale](https://redis.io/docs/latest/develop/clients/patterns/distributed-locks/) in letteratura; in produzione preferire librerie collaudate e documentazione ufficiale Redis.

**Best practice**  
Sempre TTL sui lock; valore unico nel lock (token) per rilasciare solo il lock del proprio processo; preferire librerie collaudate (es. Bull/BullMQ per code) invece di implementazioni custom; per lock distribuiti multi-nodo valutare la documentazione Redis e le limitazioni del proprio scenario.

---

## Session store, pub/sub e strutture dati

### Redis come session store
**Definizione**  
Le sessioni HTTP possono essere memorizzate in Redis invece che in memoria o su DB: il server scrive session_id in cookie e a ogni request legge lo stato da Redis. Failover: con Redis Sentinel o cluster le sessioni restano disponibili anche in caso di failover.

**Caso d'uso**  
App multi-istanza che condividono stato sessione; TTL sulla chiave sessione per expiry; evitare perdita sessioni al restart del singolo nodo.

**Best practice**  
TTL allineato al timeout sessione; serializzazione sicura (no dati sensibili in chiaro); connettere con retry e timeout.

### Pub/Sub Redis
**Definizione**  
Redis Pub/Sub: publisher invia messaggio su canale; i subscriber ricevono in tempo reale. Messaggio non persistito: se nessuno è in ascolto il messaggio si perde. Diverso da Kafka/RabbitMQ: no retention, no garantita delivery, no consumer group.

**Caso d'uso**  
Notifiche in-app, invalidation cache tra istanze (broadcast "invalida key X"), eventi real-time con basso volume. Per messaggistica affidabile e retention usare Kafka o RabbitMQ.

**Failure mode**  
Subscriber disconnesso perde messaggi; scaling subscriber: ogni istanza riceve tutti i messaggi (no load balancing come in queue). Usare per broadcast, non per task queue.

### Strutture dati: hash, set, sorted set
**Definizione**  
- **Hash**: campi/valori per una chiave (es. user:123 → name, email); HGETALL, HSET; utile per oggetti.  
- **Set**: insieme non ordinato, unicità; SADD, SISMEMBER; utile per tag, membri, dedup.  
- **Sorted set**: insieme ordinato per score; ZADD, ZRANGE; utile per leaderboard, timeline, delay queue (score = timestamp).

**Caso d'uso**  
Leaderboard: ZADD con punteggio, ZREVRANGE per top N. Dedup: SADD id messaggi già processati. Oggetto: HGETALL user:123.

**Failure mode**  
Strutture grandi (hash con molti campi, set enormi): preferire chiavi più piccole o sharding; ZRANGE su range molto grande: paginare.

---

## Persistence, cluster e rate limiting

### Persistence (RDB vs AOF)
**Definizione**  
- **RDB**: snapshot periodico del dataset su file; ripristino veloce; dati tra due snapshot persi in caso di crash.  
- **AOF**: log di ogni comando di scrittura; ripristino riapplicando il log; più lento ma più granulare. Configurazione: RDB + AOF per durabilità; fsync every second come compromesso.

**Caso d'uso**  
Cache pura: RDB o nessuna persistence. Sessioni o dati importanti: AOF con fsync appropriato; valutare costo I/O.

**Failure mode**  
AOF con fsync always: latenza alta; RDB con snapshot rari: perdita dati significativa. Monitorare dimensione file e tempo di rewrite.

### Cluster e Sentinel
**Definizione**  
- **Sentinel**: HA per Redis standalone; monitoraggio e failover automatico; client che chiedono al Sentinel l'indirizzo del master.  
- **Cluster**: sharding dei dati su più nodi (slot); routing lato client (o proxy); replica per nodo per HA.

**Caso d'uso**  
Sentinel: pochi nodi, failover automatico. Cluster: dataset grande, scale-out; attenzione a key hash tag per tenere chiavi correlate sullo stesso nodo.

**Failure mode**  
Cluster: operazioni multi-key su chiavi in slot diversi non supportate (MGET su chiavi in nodi diversi); usare hash tag {user}:123 e {user}:456.

### Rate limiting con Redis
**Definizione**  
Implementare rate limit (es. N richieste per minuto per IP) con Redis: chiave per client (es. ratelimit:ip:1.2.3.4), INCR e EXPIRE; finestra sliding con sorted set (ZADD con timestamp, ZREMRANGEBYSCORE per pulire vecchi, ZCARD per contare) o token bucket.

**Caso d'uso**  
API pubbliche, login (limite tentativi); sliding window per limite più preciso; token bucket per burst controllato.

**Snippet (concetto)**  
INCR key; EXPIRE key 60 se prima volta; se INCR > 100 allora 429. Per sliding: ZADD key now now; ZREMRANGEBYSCORE key -inf (now-60); ZCARD key.

---

## Cache stampede e locking

### Cache stampede e single-flight
**Definizione**  
Cache stampede: alla scadenza della chiave molte richieste fanno miss contemporaneamente e tutte colpiscono il DB. Mitigazioni: lock (solo il primo ricarica, gli altri aspettano o leggono stale); probabilistic early expiry (ricalcolare prima della scadenza con probabilità crescente); single-flight (una sola "flight" per chiave, le altre attendono il risultato).

**Caso d'uso**  
Chiavi molto richieste (homepage, top products); lock con TTL breve per evitare deadlock se il ricaricatore crasha.

**Best practice**  
Lock con valore unico (UUID) per rilasciare solo il proprio; TTL sul lock (es. 10s); fallback a dati stale se DB lento invece di bloccare tutte le richieste.

## In sintesi

- Cache-aside: app legge da cache; se miss, legge da DB, scrive in cache, restituisce; write-through/write-behind come alternative.
- TTL obbligatorio per evitare dati stale; invalidazione esplicita su write (delete key) o pattern (tag, version).
- Thundering herd: molti request su miss; mitigare con lock o probabilistic early expiration.
- Redis per sessioni, rate limiting, lock distribuiti; in pipeline per cache tra stage.
- Session store con failover; Pub/Sub per broadcast (no retention); hash, set, sorted set per strutture; RDB vs AOF; Sentinel e Cluster; rate limiting con INCR/sliding window; cache stampede e single-flight.

## Vedi anche

- [Database](database.md) — Sorgente dati e consistenza.
- [Architettura](architettura.md) — Event-driven e code.
