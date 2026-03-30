# PostgreSQL

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [MVCC e concorrenza](#mvcc-e-concorrenza)
- [Tipi e estensioni](#tipi-e-estensioni)
- [Indici](#indici)
- [Replica e alta disponibilità](#replica-e-alta-disponibilita)
- [Connection pooling](#connection-pooling)
- [Quando usare PostgreSQL vs altri RDBMS](#quando-usare-postgresql-vs-altri-rdbms)
- [Errori comuni](#errori-comuni)

## Panoramica

PostgreSQL è un RDBMS open source che rispetta ACID, supporta SQL standard avanzato e offre tipi di dati ricchi, estensioni (JSONB, PostGIS, full-text) e replica solida. È adatto a carichi OLTP e analitici, API con dati semi-strutturati (JSON) e contesti dove conta la consistenza e la flessibilità dello schema senza rinunciare al relazionale.

!!! tip "Prova a spiegarlo"
    Spiega a voce: cos'è il **MVCC** in PostgreSQL e perché si usa **pgBouncer** (o un pooler) davanti al DB. Poi verifica nelle sezioni sotto.

---

## MVCC e concorrenza

**Definizione**  
Il Multi-Version Concurrency Control (MVCC) permette letture consistenti senza bloccare le scritture: ogni transazione vede uno snapshot dei dati; le righe aggiornate o eliminate restano visibili alle transazioni già avviate fino al commit, evitando lock di lettura.

**Caso d'uso**  
Alto throughput con molte letture concorrenti e scritture; report lunghi che non devono bloccare gli aggiornamenti; livello di isolamento `READ COMMITTED` (default) o `REPEATABLE READ` per evitare dirty read e, nel secondo caso, non-repeatable read.

**Esempio**

```sql
-- Sessione A
BEGIN;
SELECT * FROM ordini WHERE id = 1;  -- vede versione N

-- Sessione B aggiorna e fa COMMIT

-- Sessione A (stesso statement, nuova lettura in READ COMMITTED)
SELECT * FROM ordini WHERE id = 1;  -- vede versione N+1
COMMIT;
```

**Impatto su performance e consistenza**  
MVCC riduce la contenzione tra lettori e scrittori; le versioni vecchie delle righe (tuple) occupano spazio fino alla VACUUM. Livelli di isolamento più alti (`REPEATABLE READ`, `SERIALIZABLE`) aumentano la ritenzione di versioni e il rischio di conflitti (serialization failure).

**Errore tipico**  
Trascurare VACUUM (o autovacuum): tabelle con molte UPDATE/DELETE accumulano dead tuple e bloat; monitorare `pg_stat_user_tables.n_dead_tup` e intervenire se necessario.

---

## Tipi e estensioni

**Definizione**  
PostgreSQL offre tipi nativi avanzati (array, JSON/JSONB, range, UUID, geometrici) e un sistema di estensioni (es. PostGIS per geospaziale, pg_trgm per similarità testo). JSONB memorizza JSON in formato binario con indici GIN per query su chiavi/valori.

**Caso d'uso**  
Colonne semi-strutturate (attributi variabili, configurazioni), ricerca full-text, dati geografici (distanze, contenimento), campi array per tag o liste ordinate.

**Esempio**

```sql
-- JSONB e indice GIN
CREATE TABLE prodotti (
  id BIGSERIAL PRIMARY KEY,
  attributi JSONB
);
CREATE INDEX idx_prodotti_attributi ON prodotti USING GIN (attributi);

-- Query su chiave JSON
SELECT * FROM prodotti WHERE attributi @> '{"colore": "rosso"}';
```

**Impatto su performance e consistenza**  
JSONB è più costoso in scrittura del testo JSON grezzo ma permette indici e query efficienti. Le estensioni aggiungono funzioni e tipi; vanno abilitate per database (CREATE EXTENSION).

**Errore tipico**  
Usare JSONB per dati con relazioni stabili e molte query per chiave: in quel caso il relazionale normalizzato con colonne e indici è di solito più efficiente.

---

## Indici

**Definizione**  
Oltre agli indici B-tree (default per chiavi, range, ordinamento), PostgreSQL supporta GIN (full-text, JSONB, array), GiST (geospaziale, range, full-text), BRIN (tabelle molto grandi ordinate per blocco). CREATE INDEX CONCURRENTLY evita lock esclusivo prolungato.

**Caso d'uso**  
B-tree per WHERE/JOIN/ORDER BY su colonne scalari; GIN per contenuto JSONB o full-text; GiST per operatori geometrici o di range; BRIN per colonne con ordine fisico (es. timestamp) su tabelle enormi.

**Esempio**

```sql
-- B-tree composito (ordine colonne conta per range/ordinamento)
CREATE INDEX idx_ordini_cliente_data ON ordini(cliente_id, created_at DESC);

-- GIN per JSONB
CREATE INDEX idx_log_meta ON log_eventi USING GIN (metadata);

-- Indice senza bloccare le scritture
CREATE INDEX CONCURRENTLY idx_ordini_stato ON ordini(stato);
```

**Impatto su performance e consistenza**  
Ogni indice accelera le letture selettive ma aumenta il costo di INSERT/UPDATE/DELETE. CONCURRENTLY richiede più tempo ma non blocca le transazioni in scrittura.

**Errore tipico**  
Creare indici compositi in ordine sbagliato rispetto alle condizioni (es. (A, B) non aiuta una query che filtra solo su B); creare indici senza analizzare il piano (EXPLAIN ANALYZE).

---

## Replica e alta disponibilità

**Definizione**  
La replica streaming (WAL shipping) invia i segmenti WAL dal primary alle standby per replica fisica; la replica logical (logical decoding, sottoscrizioni) permette di replicare subset di tabelle o trasformare i dati. Failover manuale o con tool (Patroni, pg_auto_failover).

**Caso d'uso**  
HA: una o più standby per failover in caso di guasto del primary. Read replica: instradare le SELECT sulle standby (con ritardo di replica e consistenza eventuale). Logical replication per ETL, multi-tenant o upgrade major.

**Esempio**

Configurazione tipica: primary con `wal_level=replica`, standby che esegue `pg_basebackup` e poi si tiene aggiornato tramite WAL streaming. Letture su standby: l'app connette al primary per scritture e a un endpoint read-only per le query di lettura.

**Impatto su performance e consistenza**  
Replica streaming ha ritardo ridotto (ordine di secondi o meno); le letture su standby vedono dati potenzialmente non aggiornati (lag). Il primary sopporta il carico di scrittura; le standby scalano le letture.

**Errore tipico**  
Eseguire scritture sulla standby (è read-only per replica fisica); ignorare il lag di replica quando si servono letture critiche dalla standby.

---

## Connection pooling

**Definizione**  
Un connection pool (es. PgBouncer, pgpool-II) mantiene un insieme di connessioni aperte verso PostgreSQL e le riassegna alle richieste delle applicazioni, riducendo il costo di apertura/chiusura connessioni e il numero di processi backend sul server.

**Caso d'uso**  
Applicazioni con molti worker/thread che aprono connessioni brevi; limitare `max_connections` sul server evitando di saturare le risorse; modalità transaction o session a seconda del bisogno (prepared statement, variabili di sessione).

**Esempio**

PgBouncer in modalità transaction: ogni transazione dell'app usa una connessione dal pool e la restituisce al termine; non si possono usare prepared statement con nome (perché la connessione cambia). In modalità session una connessione è dedicata alla sessione client per tutta la durata.

**Impatto su performance e consistenza**  
Riduce latenza di connessione e carico sul DB; con pool in modalità transaction, funzionalità legate alla sessione (es. SET, prepared statement con nome) non sono garantite tra una transazione e l'altra.

**Errore tipico**  
Usare prepared statement con nome con PgBouncer in modalità transaction; dimensionare il pool troppo grande (più connessioni del `max_connections` del DB).

---

## Quando usare PostgreSQL vs altri RDBMS

**Definizione**  
PostgreSQL è una scelta forte per progetti nuovi in ambito open source, quando servono tipi avanzati (JSONB, array, estensioni), replica e HA ben integrate, e licenza senza costi di licenza. Oracle e SQL Server dominano in contesti enterprise con contratti e tooling consolidato; MySQL/MariaDB sono molto usati per stack LAMP e semplicità operativa.

**Caso d'uso**  
Scegliere PostgreSQL per: API con dati semi-strutturati (JSON), geospaziale (PostGIS), full-text, necessità di SQL avanzato e consistenza forte; migrazioni da altri RDBMS con minimizzazione lock-in. Valutare Oracle/SQL Server quando il contesto aziendale richiede stack già in uso, RAC/Always On o tool specifici.

**Impatto**  
PostgreSQL riduce costi di licenza e offre estensibilità; l’ecosistema di hosting e operatori è ampio. In ambienti già Oracle-centrici, integrazione e competenze possono favorire Oracle.

**Errore tipico**  
Sottovalutare le competenze operative (backup, replica, tuning) o assumere che “open source = zero costi” senza considerare supporto e gestione.

---

## Errori comuni

- **Transazioni lunghe**: molte operazioni in un unico BEGIN/COMMIT bloccano righe e aumentano il rischio di deadlock; preferire transazioni corte e retry.
- **N+1 a livello applicativo**: eseguire una query per ogni riga parent invece di una query con JOIN o IN; risolvere con eager loading o batch.
- **Indici mancanti o sbagliati**: query lente senza indice su colonne in WHERE/JOIN; indici compositi in ordine non allineato alle query; usare EXPLAIN (ANALYZE) per verificare.
- **VACUUM trascurato**: tabelle con molte UPDATE/DELETE senza autovacuum adeguato o VACUUM manuale; bloat e degradazione performance.
- **CREATE INDEX senza CONCURRENTLY**: su tabelle grandi l’indice blocca le scritture; usare CREATE INDEX CONCURRENTLY in produzione.

---

## In sintesi

- PostgreSQL: RDBMS open source ACID, MVCC, tipi ricchi (JSONB, array), estensioni (PostGIS, full-text).
- MVCC: letture senza lock di lettura; gestire dead tuple con VACUUM/autovacuum.
- Indici: B-tree default; GIN (JSONB, full-text), GiST (geospaziale), BRIN per tabelle ordinate; CREATE INDEX CONCURRENTLY in produzione.
- Replica: streaming WAL per HA e read replica; logical replication per ETL e subset.
- Connection pooling (PgBouncer) per ridurre connessioni e latenza; attenzione a modalità transaction vs session e prepared statement.

## Vedi anche

- [Database](database.md) — Concetti generali: ACID, normalizzazione, indici, replica.
- [Oracle DB](oracle-db.md) — RDBMS enterprise, RAC, Data Guard.
- [MongoDB](mongodb.md) — NoSQL document per dati semi-strutturati e schema flessibile.
