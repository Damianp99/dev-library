# Database

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [DB relazionali](#db-relazionali)
  - [Normalizzazione](#normalizzazione)
  - [Transazioni ACID](#transazioni-acid)
  - [Indici](#indici)
  - [Join](#join)
  - [Query plan e ottimizzazione](#query-plan-e-ottimizzazione)
  - [Lock e concorrenza](#lock-e-concorrenza)
  - [Backup e replica](#backup-e-replica)
- [NoSQL](#nosql)
  - [Modelli: key-value, document, column-family](#modelli-key-value-document-column-family)
  - [Consistency: eventual vs strong](#consistency-eventual-vs-strong)
  - [Sharding](#sharding)
  - [Quando usare NoSQL vs relazionale](#quando-usare-nosql-vs-relazionale)
- [Sequence, viste e partizionamento](#sequence-viste-e-partizionamento)
- [Connection pooling e read replica](#connection-pooling-e-read-replica)
- [NoSQL graph e migrazioni](#nosql-graph-e-migrazioni)

## Panoramica

Questa guida copre domande ricorrenti su database per ruoli BE e full-stack: modellazione, performance e consistenza. I DB **relazionali** (SQL) offrono schema rigido, transazioni ACID e integrità referenziale; i **NoSQL** privilegiano scalabilità orizzontale, schema flessibile e modelli di consistenza diversi. La scelta dipende dal carico, dalle relazioni tra entità e dai requisiti di consistenza e latenza.

!!! tip "Prova a spiegarlo"
    Spiega a voce: cosa sono le proprietà **ACID** e quando ha senso usare un DB **NoSQL** invece del relazionale. Poi verifica in [Transazioni ACID](database.md#transazioni-acid) e [Quando usare NoSQL vs relazionale](database.md#quando-usare-nosql-vs-relazionale).

---

## DB relazionali

### Normalizzazione

**Definizione**  
La normalizzazione è un processo di progettazione che organizza i dati in tabelle riducendo ridondanza e anomalie (update, insert, delete) tramite forme normali.

**Caso d'uso**  
Applicare 1NF–3NF quando le relazioni tra entità sono stabili e si vogliono aggiornamenti coerenti senza duplicazioni. Denormalizzare (introdurre ridondanza controllata) quando le letture dominano e si accetta un costo maggiore in scrittura.

**Esempio**

Prima (ridondanza): una tabella ordini con nome cliente ripetuto per ogni riga ordine.

Dopo (3NF): `clienti(id, nome, email)`, `ordini(id, cliente_id, data)`, `righe_ordine(id, ordine_id, prodotto_id, qty)`.

```sql
-- 3NF: nessun attributo non chiave dipende da un altro non chiave
CREATE TABLE ordini (
  id BIGINT PRIMARY KEY,
  cliente_id BIGINT NOT NULL REFERENCES clienti(id),
  created_at TIMESTAMP NOT NULL
);
```

**Impatto su performance e consistenza**  
Normalizzazione riduce spazio e mantiene un'unica fonte di verità (update in un solo punto); le query complesse richiedono più join (costo lettura). Denormalizzazione riduce i join e accelera le letture a scapito di aggiornamenti multipli e rischio inconsistenza.

**Errore tipico**  
Normalizzare eccessivamente (tabelle con una sola colonna utile oltre alla PK) o denormalizzare senza strategia di aggiornamento: dati stale e bug difficili da correggere.

---

### Transazioni ACID

**Definizione**  
ACID: **A**tomicity (tutto o niente), **C**onsistency (vincoli rispettati a fine transazione), **I**solation (concorrenza controllata), **D**urability (persistenza dopo commit).

**Caso d'uso**  
Operazioni che coinvolgono più tabelle o più righe devono essere atomiche e durabili; il livello di isolamento bilancia consistenza e concorrenza.

**Esempio**

```sql
BEGIN;
  UPDATE conti SET saldo = saldo - 100 WHERE id = 1;
  UPDATE conti SET saldo = saldo + 100 WHERE id = 2;
  -- Se la seconda riga fallisce, la prima viene annullata
COMMIT;
-- Oppure in caso di errore: ROLLBACK;
```

Isolation level: `READ COMMITTED` (default in molti DB) evita dirty read ma permette non-repeatable read; `SERIALIZABLE` garantisce isolamento massimo con più lock e possibile riduzione del throughput.

**Impatto su performance e consistenza**  
Livelli di isolamento più alti aumentano lock e contenzione; livelli bassi riducono la latenza ma espongono a anomalie (phantom read, lost update). Durability implica flush su disco (fsync), con costo in latenza.

**Errore tipico**  
Usare transazioni lunghissime (molte operazioni in un unico BEGIN/COMMIT) bloccando righe a lungo; preferire transazioni corte e retry in caso di deadlock.

---

### Indici

**Definizione**  
Un indice è una struttura dati (tipicamente B-tree) che permette di trovare righe per valore di una o più colonne senza scansionare l'intera tabella.

**Caso d'uso**  
Aggiungere indici sulle colonne usate in `WHERE`, `JOIN`, `ORDER BY` e `GROUP BY` quando il pattern di accesso è stabile. Evitare indici su tabelle piccole o colonne con pochi valori distinti (bassa cardinalità) se le scritture sono frequenti.

**Esempio**

```sql
-- Indice singolo
CREATE INDEX idx_ordini_created_at ON ordini(created_at);

-- Indice composito: ordine colonne importante per range/ordinamento
CREATE INDEX idx_ordini_customer_date ON ordini(customer_id, created_at DESC);
```

La query `SELECT * FROM ordini WHERE customer_id = 5 ORDER BY created_at DESC` può usare l'indice composito per lookup e ordinamento senza sort aggiuntivo.

**Impatto su performance e consistenza**  
Ogni indice accelera le letture selettive ma aumenta il costo delle scritture (INSERT/UPDATE/DELETE devono aggiornare l'indice). Troppi indici su tabelle write-heavy degradano le performance; collegare sempre l'indice al pattern di accesso reale.

**Errore tipico**  
Indicizzare ogni colonna "per sicurezza" o creare indici compositi in ordine sbagliato rispetto alle condizioni della query (es. (A, B) non aiuta una query che filtra solo su B).

---

### Join

**Definizione**  
Il join combina righe di due o più tabelle in base a una condizione (tipicamente uguaglianza tra chiavi). INNER restituisce solo le righe con match in entrambe le tabelle; LEFT include tutte le righe della tabella sinistra anche senza match a destra.

**Caso d'uso**  
INNER per relazioni obbligatorie (es. ordini con cliente); LEFT per dati opzionali (es. cliente con eventuale indirizzo); RIGHT meno usato, spesso sostituibile con LEFT invertendo le tabelle.

**Esempio**

```sql
-- Ordini con nome cliente (solo ordini con cliente valido)
SELECT o.id, o.created_at, c.nome
FROM ordini o
INNER JOIN clienti c ON o.cliente_id = c.id;

-- Tutti i clienti con conteggio ordini (anche zero)
SELECT c.id, c.nome, COUNT(o.id) AS num_ordini
FROM clienti c
LEFT JOIN ordini o ON o.cliente_id = c.id
GROUP BY c.id, c.nome;
```

**Impatto su performance e consistenza**  
Join su grandi tabelle senza indice sulle colonne di join causano full scan e prodotti cartesiani in memoria. N+1: una query per ogni riga padre (es. ordini + righe) invece di un join o di una query in batch; risolvere con JOIN, IN con lista id, o batch load.

**Errore tipico**  
Eseguire join su colonne non indicizzate o molti join su tabelle grandi senza filtri; dimenticare la cardinalità (uno-a-molti) e ottenere righe duplicate se non si usa DISTINCT o GROUP BY correttamente.

---

### Query plan e ottimizzazione

**Definizione**  
Il query plan è la strategia scelta dal motore (scan, index seek, join algorithm) per eseguire una query. EXPLAIN (e EXPLAIN ANALYZE dove disponibile) mostra il piano e i costi stimati o reali.

**Caso d'uso**  
Usare il piano per capire perché una query è lenta: seq scan su tabella grande, mancanza di indice, sort in memoria, join costosi.

**Esempio**

```sql
EXPLAIN ANALYZE
SELECT * FROM ordini WHERE customer_id = 5 AND created_at > '2024-01-01';
```

Interpretazione: cercare "Seq Scan" su tabelle grandi (spesso segnale di indice mancante); "Index Scan" o "Index Only Scan" come positivo; "Sort" con costi alti può indicare bisogno di indice per ORDER BY. Costi e righe stimate vs effettive (con ANALYZE) guidano il tuning.

**Impatto su performance e consistenza**  
Un piano sbagliato (es. full scan ripetuto) impatta direttamente latenza e carico CPU/I/O. Gli indici e le statistiche (ANALYZE/VACUUM in PostgreSQL) influenzano la bontà del piano.

**Errore tipico**  
Ottimizzare senza guardare il piano o senza aggiornare le statistiche; assumere che "più indici" sia sempre meglio senza verificare l'uso effettivo nel piano.

---

### Lock e concorrenza

**Definizione**  
I lock proteggono i dati durante le transazioni: row-level lock (blocco sulla singola riga) vs table-level lock (blocco su tutta la tabella). Il deadlock si verifica quando due o più transazioni si aspettano reciprocamente il rilascio di un lock.

**Caso d'uso**  
Row lock permette concorrenza alta su tabelle con accessi distribuiti; table lock è più semplice ma riduce il parallelismo. Deadlock tipico: T1 lock A poi chiede B, T2 lock B poi chiede A.

**Esempio**

```sql
-- Row lock implicito in UPDATE
BEGIN;
UPDATE ordini SET stato = 'evaso' WHERE id = 1;  -- lock sulla riga 1
-- Altra transazione può aggiornare id = 2
COMMIT;
```

Mitigazione deadlock: ordinare sempre l'acquisizione dei lock (es. sempre prima tabella A poi B); usare transazioni corte; retry con backoff in caso di errore deadlock.

**Impatto su performance e consistenza**  
Lock lunghi aumentano attesa e rischio deadlock; isolation level più alti aumentano lock e riducono throughput. Timeout e retry sono essenziali in ambienti concorrenti.

**Errore tipico**  
Eseguire in transazione operazioni lente (chiamate HTTP, I/O) tenendo lock attivi; non gestire l'eccezione di deadlock con retry.

---

### Backup e replica

**Definizione**  
Backup: copia dei dati per recovery (full, incrementale, differenziale). Replica: copia del DB attiva per read scaling o failover; read replica riceve le modifiche dal primary e serve query di lettura.

**Caso d'uso**  
Backup regolari per RPO (Recovery Point Objective); replica per alta disponibilità e distribuzione del carico di lettura. Failover: promozione di una replica a primary in caso di guasto.

**Esempio (concettuale)**

- Full backup: dump completo (es. `pg_dump`, `mysqldump`) su schedule.
- Incrementale: solo blocchi modificati dall'ultimo backup (dipende dal motore).
- Replica: streaming WAL (PostgreSQL) o binlog (MySQL) dal primary alle repliche.

RTO (Recovery Time Objective): tempo massimo per tornare operativi; RPO: perdita massima di dati accettabile (es. ultimo backup = RPO fino a quel punto).

**Impatto su performance e consistenza**  
Backup full può caricare I/O e rete; replica introduce ritardo (replication lag): letture su replica possono essere leggermente stale. Failover automatico richiede monitoraggio e test periodici.

**Errore tipico**  
Non testare il restore; assumere zero lag sulle read replica e usarle per query che richiedono letture sempre aggiornate; non definire RTO/RPO e backup schedule.

---

## NoSQL

### Modelli: key-value, document, column-family

**Definizione**  
- **Key-value**: accesso per chiave (stringa o binario); valore opaco. Es. Redis, DynamoDB (modalità key-value).
- **Document**: valore strutturato (JSON/BSON); query su campi del documento. Es. MongoDB.
- **Column-family**: dati organizzati per colonna/famiglia; ottimizzato per letture per colonna su grandi volumi. Es. Cassandra, HBase.

**Caso d'uso**  
Key-value per cache, sessioni, contatori. Document per entità con struttura variabile e query per attributi annidati. Column-family per serie temporali o dati molto grandi con pattern di accesso per colonna.

**Esempio**

Key-value (Redis): `SET session:abc123 "{...}"` / `GET session:abc123`.

Document (MongoDB):

```json
{
  "orderId": "O-1001",
  "customer": { "id": "C-11", "name": "Luca" },
  "items": [{ "sku": "A1", "qty": 2 }],
  "createdAt": "2024-03-01T10:00:00Z"
}
```

Column-family (Cassandra): chiave di riga + column family + colonne; letture per row key e subset di colonne.

**Impatto su performance e consistenza**  
Denormalizzazione nei document riduce join e roundtrip; gli update che toccano più documenti richiedono gestione applicativa. Modellazione query-driven: strutturare il documento in base a come si legge, non solo a come si scrive.

**Errore tipico**  
Usare un document store come un relazionale con molti "join" applicativi; non considerare la cardinalità (documenti che crescono senza limite, es. array di sottodocumenti illimitato).

---

### Consistency: eventual vs strong

**Definizione**  
**Strong consistency**: dopo una scrittura, ogni lettura vede il valore aggiornato. **Eventual consistency**: le repliche convergono nel tempo; per un periodo una lettura può restituire un valore non ancora aggiornato. Teorema CAP: in presenza di partizione di rete si deve scegliere tra consistenza (C) e disponibilità (A).

**Caso d'uso**  
Strong per dati critici (saldo conto, inventario dove conta l’accuratezza). Eventual per dati che tollerano ritardo (contatori di like, feed, cache) per ottenere minore latenza e maggiore throughput.

**Esempio**  
Sistema con due datacenter: strong consistency richiede coordinazione (quorum, 2PC) e può aumentare la latenza; eventual consistency permette di scrivere in un DC e leggere da entrambi accettando un ritardo di propagazione.

**Impatto su performance e consistenza**  
Strong consistency implica più round-trip o lock; eventual consistency riduce la latenza e permette scale-out geografico a costo di finestre di inconsistenza. La scelta va fatta in base al carico e ai requisiti di business.

**Errore tipico**  
Assumere che "NoSQL sia sempre più veloce" senza considerare il modello di consistenza; usare eventual consistency per dati che richiedono letture sempre aggiornate (es. saldo).

---

### Sharding

**Definizione**  
Sharding è il partizionamento orizzontale dei dati: le righe (o i documenti) sono distribuiti su più nodi in base a una chiave di sharding (partition key). Ogni shard gestisce un sottoinsieme dei dati.

**Caso d'uso**  
Quando un singolo nodo non basta per volume o throughput; tipico in NoSQL e in DB relazionali molto grandi. La chiave di sharding determina la distribuzione del carico (hot spot se la chiave è sbilanciata).

**Esempio**  
Sharding per `user_id`: utente A su shard 1, utente B su shard 2. Query che filtrano per `user_id` vanno su un solo shard; query che cercano "tutti gli ordini dell’ultimo giorno" richiedono fan-out su tutti gli shard (costoso). Strategia: scegliere una partition key che distribuisce il carico e che corrisponde al pattern di query dominante.

**Impatto su performance e consistenza**  
Sharding permette scale-out ma complica le query cross-shard (join, aggregazioni globali). Rebalancing e migrazione dati sono operazioni delicate. Throughput complessivo aumenta; la latenza di query che toccano più shard può crescere.

**Errore tipico**  
Scegliere una chiave di sharding con distribuzione skew (pochi valori molto caldi); progettare query che richiedono sempre scan su tutti gli shard.

---

### Quando usare NoSQL vs relazionale

**Definizione**  
Scelta architetturale basata su schema, relazioni, requisiti di consistenza e scalabilità. Non è "NoSQL sempre più veloce": dipende dal modello di dati e dal carico.

**Criteri sintetici**

| Criterio | Relazionale | NoSQL |
|----------|-------------|--------|
| Schema | Rigido, vincoli forti | Flessibile, schema-less o flessibile |
| Relazioni complesse | Join, FK, integrità referenziale | Modellazione denormalizzata, join applicativi |
| Consistenza forte | ACID nativo | Limitata (o configurabile con vincoli) |
| Scale-out | Principalmente verticale (o sharding complesso) | Sharding e replica nativi |
| Query | SQL ricco, ad-hoc | Query su chiave/campi, spesso predefinite |

**Caso d'uso**  
Relazionale: domini con molte relazioni (ordini, fatture, anagrafiche), report complessi, requisiti ACID. NoSQL: alto throughput su dati per chiave o documento, schema che evolve spesso, scale-out orizzontale prioritario, eventual consistency accettabile dove serve.

**Errore tipico**  
Scegliere NoSQL "per moda" senza un motivo (scale-out, schema flessibile, pattern di accesso); oppure usare il relazionale per carichi molto skew e write-heavy senza piano di scaling.

---

## Sequence, viste e partizionamento

### Sequence e identity
**Definizione**  
Le sequence (Oracle, PostgreSQL) e le colonne identity/auto-increment generano valori univoci per chiavi primarie. La sequence è un oggetto separato (NEXTVAL/CURRVAL); identity è legata alla colonna e gestita dal motore.

**Caso d'uso**  
ID surrogate per tabelle; bulk insert: con identity/sequence l'ordine e l'unicità sono garantiti. In replica: attenzione a sequence non sincronizzate tra nodi (conflitti su ID); in alcuni DB si usano range per nodo o UUID.

**Impatto**  
Sequence/identity evitano round-trip per generare ID lato applicativo; in scenari multi-writer (replica, sharding) valutare UUID o ID generati da servizio centralizzato.

**Errore tipico**  
Assumere che sequence sia gapless; in molti DB non lo è (gap dopo rollback o restart). Per audit consecutivi usare timestamp o log separato.

### Viste e materialized view
**Definizione**  
Una vista è una query salvata (alias); non memorizza dati. La materialized view memorizza il risultato della query e si aggiorna con REFRESH (periodico o on commit, a seconda del DB).

**Caso d'uso**  
Viste per semplificare query complesse e permessi (mascherare colonne). Materialized view per aggregati pesanti e report: si paga il refresh in cambio di letture veloci.

**Impatto**  
Viste: costo a ogni lettura (query sottostante). Materialized view: spazio e tempo di refresh; consistenza tra refresh (dati potenzialmente stale).

**Errore tipico**  
Materialized view su dati che cambiano continuamente senza strategia di refresh; vista con join pesanti usata in hot path senza caching.

### Partizionamento tabelle (range, list, hash)
**Definizione**  
Il partizionamento divide una tabella in partizioni (range di valori, lista di valori, hash della chiave). Le query possono essere pruned (solo partizioni rilevanti); la manutenzione (backup, indice) può essere per partizione.

**Caso d'uso**  
Tabelle molto grandi (fatti, log); partizione per data (range) per retention e archivio; partizione per regione (list) per distribuzione; hash per distribuire il carico.

**Impatto**  
Query con filtro sulla chiave di partizione beneficiano del partition pruning; senza filtro si scansionano tutte le partizioni. Gestione: drop partizione vecchia invece di DELETE massivo.

**Errore tipico**  
Partizionare senza che le query filtrino sulla chiave di partizione; troppe partizioni (overhead del motore).

---

## Connection pooling e read replica

### Connection pooling
**Definizione**  
Il connection pool mantiene un insieme di connessioni aperte verso il DB e le riusa per le richieste applicative, evitando il costo di apertura/chiusura per ogni operazione.

**Caso d'uso**  
Applicazioni con molte richieste concorrenti; limitare il numero massimo di connessioni (max pool size) per non saturare il DB. PgBouncer (o analoghi) come proxy di pooling per PostgreSQL.

**Impatto**  
Throughput migliore e latenza più stabile; dimensionamento: pool size in linea con connessioni max del DB e numero di istanze app. Pool troppo piccolo: coda; troppo grande: sovraccarico DB.

**Errore tipico**  
Pool size totale (tutte le istanze) superiore al max_connections del DB; connessioni non restituite al pool (leak) per eccezioni non gestite.

### Read replica e split read/write
**Definizione**  
La read replica è una copia del DB in sola lettura (replica asincrona). L'applicazione instrada le SELECT sulla replica e le scritture sul primary; si ottiene scale-out delle letture e riduzione del carico sul primary.

**Caso d'uso**  
Report, dashboard, ricerche; carichi read-heavy. Consistenza eventuale: la replica è in ritardo (replication lag); per letture che devono vedere l’ultima scrittura usare il primary.

**Impatto**  
Latenza di replica: da millisecondi a secondi; transazioni che leggono dopo write sullo stesso primary sono consistenti; lettura su replica dopo write può vedere dato non ancora replicato.

**Errore tipico**  
Leggere su replica dati appena scritti e aspettarsi consistenza immediata; non monitorare il lag di replica (replica troppo indietro = dati molto stale).

---

## NoSQL graph e migrazioni

### NoSQL: modelli graph (cenni)
**Definizione**  
I graph DB modellano entità come nodi e relazioni come archi; le query attraversano il grafo (es. "amici degli amici", path, raccomandazioni). Esempi: Neo4j, Amazon Neptune.

**Caso d'uso**  
Relazioni complesse e traversali (social, recommendation, fraud detection, knowledge graph). Quando le relazioni sono first-class e le query sono "n hop da X".

**Impatto**  
Scalano per relazione e traversali; meno adatti a aggregazioni massive su intera tabella. Spesso si usano insieme a relazionale o document per dati operativi e graph per analisi/query su relazioni.

**Errore tipico**  
Usare graph DB per dati prevalentemente tabellari senza traversali complessi; sovrastimare il bisogno di graph (relazionale con indici può bastare).

### Migrazioni schema e zero-downtime
**Definizione**  
Le migrazioni applicano cambi allo schema (nuove colonne, indici, tabelle) in modo versionato e ripetibile. Zero-downtime: strategie per deploy senza bloccare le letture/scritture (es. aggiungere colonna nullable, backfill, poi rendere NOT NULL in release successiva).

**Caso d'uso**  
Aggiunta colonna: in una release si aggiunge nullable e si backfilla; nella successiva si rende NOT NULL e si rimuove il default. Indici: creare CONCURRENTLY (PostgreSQL) per evitare lock prolungati.

**Impatto**  
Migrazioni bloccanti (ALTER con lock) causano downtime o latenza alta; pianificare migrazioni grandi in finestre di manutenzione o con strategie expand/contract.

**Errore tipico**  
ALTER TABLE ADD COLUMN NOT NULL senza default su tabella grande (lock e riscrittura); migrazione che fallisce a metà senza rollback pianificato.

---

## In sintesi

- Normalizzazione: ridurre ridondanza e anomalie; 1NF, 2NF, 3NF; denormalizzare solo con motivo (performance).
- ACID: atomicità, consistenza, isolamento, durabilità; livelli di isolamento e trade-off (dirty read, phantom read).
- Indici: velocizzano SELECT e JOIN; rallentano INSERT/UPDATE; creare in base al pattern di accesso reale.
- Join: INNER, LEFT, RIGHT, FULL; piano di esecuzione e cardinalità; evitare N+1 a livello applicativo.
- NoSQL: key-value, document, column-family; eventual vs strong consistency; sharding per scale-out.
- Backup e replica: point-in-time recovery; replica per HA e letture scale-out.
- Sequence/identity per ID; viste e materialized view; partizionamento per tabelle grandi; connection pooling e PgBouncer; read replica e split read/write (consistenza eventuale); graph DB per relazioni traversali; migrazioni zero-downtime (expand/contract).

## Vedi anche

- [Architettura](architettura.md) — CQRS, event sourcing e consistenza distribuita.
- [Java](java.md) / [Spring Boot](springboot.md) — JPA e transazioni in contesto Java.
- [Redis e cache](redis-cache.md) — Cache e sessioni.
