# MongoDB

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Modello document e BSON](#modello-document-e-bson)
- [Collezioni e documenti](#collezioni-e-documenti)
- [Indici](#indici)
- [Aggregation pipeline](#aggregation-pipeline)
- [Replica set](#replica-set)
- [Sharding](#sharding)
- [Transazioni multi-document](#transazioni-multi-document)
- [Quando usare MongoDB vs relazionale](#quando-usare-mongodb-vs-relazionale)
- [Errori comuni](#errori-comuni)

## Panoramica

MongoDB è un database NoSQL di tipo document: i dati sono memorizzati in documenti BSON (simile a JSON) organizzati in collezioni. Offre schema flessibile, indici su campi e sotto-campi, aggregation pipeline per analisi e, da MongoDB 4.0+, transazioni ACID multi-document. Replica set garantiscono HA; lo sharding permette scalabilità orizzontale. Adatto a dati semi-strutturati, gerarchie e carichi con alta variabilità dello schema.

!!! tip "Prova a spiegarlo"
    Spiega a voce: differenza tra **replica set** e **sharding** in MongoDB, e quando ha senso usare le **transazioni multi-document**. Poi verifica nelle sezioni sotto.

---

## Modello document e BSON

**Definizione**  
I documenti sono strutture chiave-valore annidate (come JSON); MongoDB li memorizza in BSON (Binary JSON), che aggiunge tipi (Date, ObjectId, BinData, ecc.) e permette indici e query efficienti su sotto-campi. Non c’è schema obbligatorio a livello di collezione: ogni document può avere campi diversi.

**Caso d'uso**  
Dati con struttura variabile (attributi opzionali, evoluzione nel tempo); gerarchie e oggetti annidati che in relazionale richiederebbero molti join; log, eventi, profili utente con campi non uniformi.

**Esempio**

```javascript
// Document con campi variabili e annidati
{
  _id: ObjectId("..."),
  nome: "Mario Rossi",
  email: "mario@example.com",
  indirizzi: [
    { tipo: "casa", città: "Roma", cap: "00100" },
    { tipo: "lavoro", città: "Milano" }
  ],
  preferenze: { lingua: "it", newsletter: true },
  created_at: ISODate("2024-01-15T10:00:00Z")
}
```

**Impatto su performance e consistenza**  
Schema flessibile riduce migrazioni ma richiede disciplina (validazione opzionale, convenzioni di naming). Documenti molto grandi (oltre 16 MB) non sono supportati; strutture troppo annidate possono complicare indici e query.

**Errore tipico**  
Modellare come in relazionale con riferimenti ovunque: in MongoDB spesso si denormalizza e si incorporano sotto-documenti dove le letture sono dominate da “leggimi tutto insieme”; evitare documenti che crescono senza limite (array illimitati).

---

## Collezioni e documenti

**Definizione**  
Una collezione è un contenitore di documenti; non impone schema. Il campo `_id` è obbligatorio e univoco per document; se non fornito, MongoDB genera un ObjectId. Le operazioni CRUD (insert, find, update, delete) lavorano su documenti; update supportano operatori ($set, $push, $inc, ecc.) per modifiche parziali.

**Caso d'uso**  
Una collezione per “tipo” logico (es. utenti, ordini, eventi); scelta tra embed e reference in base al pattern di accesso (embed per lettura frequente insieme, reference per entità condivise o molto grandi).

**Esempio**

```javascript
// Inserimento
db.ordini.insertOne({
  _id: 1,
  cliente_id: 100,
  righe: [
    { prodotto_id: 10, qty: 2, prezzo: 25.50 },
    { prodotto_id: 20, qty: 1, prezzo: 100 }
  ],
  totale: 151,
  stato: "confermato"
});

// Query con filtro e proiezione
db.ordini.find(
  { stato: "confermato", "righe.prodotto_id": 10 },
  { cliente_id: 1, totale: 1, _id: 0 }
);

// Update parziale
db.ordini.updateOne(
  { _id: 1 },
  { $set: { stato: "spedito" }, $currentDate: { updated_at: true } }
);
```

**Impatto su performance e consistenza**  
Embed riduce round-trip e join logici ma duplica dati e complica aggiornamenti su molti documenti. Reference richiede lookup (aggregation $lookup o query multiple); coerenza tra documenti collegati va gestita a livello applicativo se non si usano transazioni.

**Errore tipico**  
Embeddare array che crescono senza limite (es. tutti i messaggi di un utente in un unico document); fare N+1: una query per ogni parent invece di $in o $lookup in batch.

---

## Indici

**Definizione**  
MongoDB supporta indici su uno o più campi (singolo, composto), indici multikey su array, TTL (scadenza automatica documenti), text (full-text), geospaziale (2dsphere). Senza indice le query fanno collection scan; con indice si usano B-tree (o strutture dedicate) per lookup e sort.

**Caso d'uso**  
Indici su campi usati in filtro, sort e join logico ($lookup su campo indicizzato); indice composto per query che combinano più campi; TTL per dati temporanei (sessioni, log); text per ricerca full-text.

**Esempio**

```javascript
// Indice singolo
db.ordini.createIndex({ cliente_id: 1 });

// Indice composto (ordine conta per range e sort)
db.ordini.createIndex({ cliente_id: 1, created_at: -1 });

// TTL: rimuovi documenti dopo 24 ore
db.sessioni.createIndex({ created_at: 1 }, { expireAfterSeconds: 86400 });

// Testo
db.articoli.createIndex({ titolo: "text", descrizione: "text" });
db.articoli.find({ $text: { $search: "mongodb guida" } });
```

**Impatto su performance e consistenza**  
Ogni indice accelera le letture ma rallenta le scritture e occupa spazio. Indici su array (multikey) possono aumentare molto la dimensione; troppi indici su collezioni write-heavy degradano le performance.

**Errore tipico**  
Non creare indici per le query più frequenti (collection scan su grandi collezioni); creare indici in ordine sbagliato per le condizioni (es. (A, B) non aiuta query che filtra solo su B); dimenticare il limite di 64 indici per collezione.

---

## Aggregation pipeline

**Definizione**  
L’aggregation pipeline è un flusso di stadi ($match, $project, $group, $lookup, $sort, $limit, ecc.) che trasformano i documenti in sequenza. Ogni stadio riceve l’output dello stadio precedente; permette filtri, raggruppamenti, join logici ($lookup), calcoli e reshaping senza caricare tutto in memoria in un colpo solo (se possibile).

**Caso d'uso**  
Report, analytics, join tra collezioni, calcolo di totali e medie, unwind di array e raggruppamento; alternativa potente alle query find() quando servono trasformazioni complesse.

**Esempio**

```javascript
// Ordini per cliente con totale e numero ordini
db.ordini.aggregate([
  { $match: { stato: "confermato" } },
  { $group: {
      _id: "$cliente_id",
      totale_ordini: { $sum: 1 },
      somma_importi: { $sum: "$totale" }
  }},
  { $sort: { somma_importi: -1 } },
  { $limit: 10 }
]);

// Lookup (join) con collezione clienti
db.ordini.aggregate([
  { $lookup: {
      from: "clienti",
      localField: "cliente_id",
      foreignField: "_id",
      as: "cliente"
  }},
  { $unwind: "$cliente" },
  { $project: { totale: 1, "cliente.nome": 1 } }
]);
```

**Impatto su performance e consistenza**  
Pipeline ben costruite ($match all’inizio per ridurre documenti) sono efficienti; pipeline che portano troppo in memoria (senza $match early, $group su grandi volumi) possono consumare RAM; usare allowDiskUse per stage che superano il limite memoria.

**Errore tipico**  
Mettere $match tardi nella pipeline; fare $lookup su collezioni grandi senza indice su foreignField; non usare $project per limitare i campi tra uno stadio e l’altro (spreco di memoria).

---

## Replica set

**Definizione**  
Un replica set è un gruppo di nodi MongoDB che mantengono gli stessi dati: un primary (scritture e letture) e uno o più secondary (replica da primary, letture opzionali). In caso di guasto del primary, gli altri nodi eleggono un nuovo primary (election). Le scritture sono replicate in modo asincrono (o con w: "majority" per write concern più forte).

**Caso d'uso**  
Alta disponibilità: nessun single point of failure per il nodo dati; read replica: instradare letture sui secondary per scalare le read (con possibile ritardo di replica). Write concern e read concern permettono di bilanciare consistenza e performance.

**Esempio**

Architettura tipica: 3 nodi (1 primary, 2 secondary). L’applicazione si connette al replica set (connection string con più host); il driver indirizza le scritture al primary e può leggere dai secondary (read preference secondary o secondaryPreferred). Dopo un failover, il driver si riconnette al nuovo primary.

**Impatto su performance e consistenza**  
Le letture da secondary vedono dati potenzialmente in ritardo (replication lag). readConcern: "majority" e writeConcern: { w: "majority" } garantiscono che le letture vedano le scritture confermate dalla maggioranza dei nodi, con possibile latenza maggiore.

**Errore tipico**  
Leggere da secondary assumendo dati sempre aggiornati; non gestire riconnessione e retry dopo failover; configurare meno di 3 nodi in produzione (2 nodi: nessuna maggioranza in caso di split).

---

## Sharding

**Definizione**  
Lo sharding distribuisce i dati su più shard (replica set) in base a una shard key. Il mongos (router) indirizza le query allo shard corretto. Chunk sono range o hash di valori della shard key; il balancer sposta i chunk per bilanciare il carico. Shard key influisce fortemente su distribuzione e performance (jumbo chunk, hotspot).

**Caso d'uso**  
Collezioni che superano la capacità di un singolo nodo; carico di scrittura o lettura che richiede scale-out orizzontale; distribuzione dati per geografia o tenant (shard key su tenant_id).

**Esempio**

Shard key su campo usato spesso nei filtri (es. user_id o range di date). Range-based: chunk per range di valori (rischio hotspot se le scritture sono sequenziali su una chiave). Hash-based: distribuzione più uniforme, ma query per range sulla shard key non sono efficienti (scatter-gather).

**Impatto su performance e consistenza**  
Shard key va scelta con cura: chiave con alta cardinalità e distribuzione uniforme; evitare chiavi monotoniche se le scritture sono tutte sull’ultimo chunk. Query che non includono la shard key possono andare su tutti gli shard (scatter-gather).

**Errore tipico**  
Scegliere una shard key a bassa cardinalità (es. booleano) o che crea hotspot; cambiare la shard key dopo aver già dati (richiede resharding complesso).

---

## Transazioni multi-document

**Definizione**  
Da MongoDB 4.0 sono supportate transazioni ACID multi-document su replica set; da 4.2 anche su shard cluster. Si usano con startTransaction(), operazioni sulla sessione e commitTransaction() / abortTransaction(). Garantiscono atomicità su più documenti e collezioni.

**Caso d'uso**  
Operazioni che devono aggiornare più documenti in modo atomico (es. trasferimento tra conti, ordine + movimento magazzino); migrazione da relazionale dove le transazioni multi-tabella sono la norma.

**Esempio**

```javascript
const session = client.startSession();
try {
  session.startTransaction();
  await ordini.insertOne({ _id: 1, totale: 100 }, { session });
  await conti.updateOne(
    { _id: "cliente1" },
    { $inc: { saldo: -100 } },
    { session }
  );
  await session.commitTransaction();
} catch (e) {
  await session.abortTransaction();
} finally {
  session.endSession();
}
```

**Impatto su performance e consistenza**  
Le transazioni hanno overhead (WiredTiger snapshot, lock); durata breve e retry in caso di conflitto (WriteConflict) sono best practice. Con write concern majority si ha durabilità e consistenza forte.

**Errore tipico**  
Transazioni lunghe che tengono lock; non usare retry con backoff per errori transiente (TransientTransactionError); assumere che le transazioni siano “gratis” come in un RDBMS ottimizzato per esse.

---

## Quando usare MongoDB vs relazionale

**Definizione**  
MongoDB è adatto quando: lo schema è variabile o evolve spesso; i dati sono gerarchici e si leggono spesso insieme; si preferisce scalabilità orizzontale (sharding) e schema flessibile. Il relazionale è preferibile quando: le relazioni sono molte e complesse, servono join frequenti, transazioni multi-riga/multi-tabella pesanti e integrità referenziale forte con FK.

**Caso d'uso**  
MongoDB: cataloghi con attributi variabili, profili utente, eventi e log, contenuti (CMS), carrelli e ordini con righe embed. Relazionale: contabilità, ordini con molte relazioni normalizzate, reporting con join complessi e vincoli referenziali stringenti.

**Impatto**  
Throughput e latenza dipendono dal pattern di accesso: MongoDB eccelle su accesso per chiave e aggregazioni su documenti; il relazionale su join e vincoli. Nessuno dei due è “sempre più veloce”; la scelta va fatta sul modello dati e sui requisiti di consistenza.

**Errore tipico**  
Usare MongoDB “perché è più veloce” senza modellare bene (embed vs reference, indici); usare il relazionale per dati fortemente gerarchici e variabili senza valutare il costo di migrazioni schema e join.

---

## Errori comuni

- **N+1**: eseguire una query per ogni parent invece di $in o $lookup; ridurre round-trip con batch e pipeline.
- **Indici mancanti**: query lente con COLLSCAN; creare indici in base a filtri, sort e $lookup; monitorare slow query log.
- **Documenti troppo grandi**: superare 16 MB; array che crescono senza limite; preferire reference o collezioni separate per sotto-entità grandi.
- **Schema non disciplinato**: campi con nomi incoerenti, tipi misti per lo stesso campo; definire convenzioni e, se utile, schema validation.
- **Letture da secondary senza gestione del lag**: assumere dati sempre aggiornati; usare read preference e read concern appropriati e gestire ritardo di replica.

---

## In sintesi

- MongoDB: DB document NoSQL, BSON, collezioni senza schema obbligatorio; embed vs reference in base al pattern di accesso.
- Indici: singolo, composto, multikey, TTL, text, geospaziale; evitare collection scan sulle query hot.
- Aggregation pipeline: $match, $group, $lookup, $sort; mettere $match presto e limitare campi con $project.
- Replica set: primary + secondary, HA e read scaling; attenzione a replication lag e write/read concern.
- Sharding: scale-out orizzontale; scelta della shard key critica per distribuzione e performance.
- Transazioni multi-document (4.x+): ACID su più documenti; usare per operazioni atomiche, con transazioni corte e retry.

## Vedi anche

- [Database](database.md) — Concetti generali: ACID, NoSQL, indici, consistenza.
- [PostgreSQL](postgresql.md) — RDBMS e JSONB per dati semi-strutturati.
- [Oracle DB](oracle-db.md) — RDBMS enterprise per contesti corporate.
