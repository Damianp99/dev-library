# GraphQL

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Schema e tipi](#schema-e-tipi)
- [Query e mutation](#query-e-mutation)
- [Resolver e N+1](#resolver-e-n1)
- [Confronto con REST](#confronto-con-rest)
- [Quando usare GraphQL](#quando-usare-graphql)
- [Subscription, batching e DataLoader](#subscription-batching-e-dataloader)
- [Federation, errori e versioning](#federation-errori-e-versioning)
- [Introspection e testing](#introspection-e-testing)

## Panoramica

GraphQL è un linguaggio di query e un runtime: il client descrive esattamente i dati che vuole e il server risponde con un JSON che rispetta la forma richiesta. Si definisce uno **schema** (tipi, query, mutation) e **resolver** che popolano i campi. È un’alternativa a REST per API flessibili, client eterogenei (web, mobile) e riduzione di over-fetching e under-fetching.

---

## Schema e tipi

### Definizione

**Definizione**  
Lo schema GraphQL descrive i tipi e le operazioni disponibili: tipi scalari (ID, String, Int, Float, Boolean), tipi oggetto (entità con campi), enum, input per mutation. Le **query** sono operazioni di lettura; le **mutation** modificano i dati.

**Caso d’uso**  
Modellare il dominio come grafo: entità e relazioni (User, Order, Product) con campi opzionali o obbligatori. Il client può chiedere solo i campi necessari.

**Esempio**

```graphql
type User {
  id: ID!
  email: String!
  name: String
  orders: [Order!]!
}

type Order {
  id: ID!
  total: Float!
  user: User!
}

type Query {
  user(id: ID!): User
  users(limit: Int): [User!]!
}

type Mutation {
  createOrder(userId: ID!, total: Float!): Order!
}
```

`!` indica non-nullable; `[Order!]!` è lista non-null di Order non-null.

**Trade-off**  
Schema forte migliora tooling e validazione; cambi breaking (rimozione campi, cambio tipo) vanno gestiti con versioning o evoluzione backward-compatible (campi deprecati, nuovi campi opzionali).

**Errore tipico**  
Schema troppo “piatto” senza relazioni (perde il vantaggio del grafo); tipi che espongono dettagli implementativi (es. ID interni del DB).

---

## Query e mutation

### Query

**Definizione**  
La query è una richiesta di lettura; il client specifica i campi (e sotto-campi) desiderati. Il server esegue i resolver e restituisce un JSON con la stessa struttura della query.

**Esempio**

```graphql
query {
  user(id: "1") {
    name
    email
    orders {
      id
      total
    }
  }
}
```

Risposta: `{ "data": { "user": { "name": "...", "email": "...", "orders": [...] } } }.`

### Mutation

**Definizione**  
Le mutation modificano i dati (create, update, delete). Semantica: una mutation può restituire il tipo creato/aggiornato o un tipo payload (es. `CreateOrderPayload` con `order` e `errors`).

**Esempio**

```graphql
mutation {
  createOrder(userId: "1", total: 99.99) {
    id
    total
  }
}
```

**Trade-off**  
Mutation “REST-like” (una mutation per risorsa) vs mutation più granulari; design dei payload per includere errori di validazione senza fare eccezioni globali.

**Errore tipico**  
Usare query per operazioni con side effect; mutation che restituiscono solo ID senza dare al client i dati aggiornati (costringendo a un’altra query).

---

## Resolver e N+1

### Resolver

**Definizione**  
Un resolver è una funzione che, per un tipo e un campo, restituisce il valore di quel campo. Il runtime GraphQL invoca i resolver in base alla query; per campi annidati (es. `user.orders`) il resolver del campo `orders` riceve il parent (user) e il contesto.

**Caso d’uso**  
Collegare GraphQL al DB o a servizi: nel resolver di `User.orders` si esegue la query degli ordini per quell’utente. Senza attenzione si cade nel problema N+1: un resolver per ogni `User` che fa una query ordini (N query per N utenti).

**Mitigazione N+1**  
- **DataLoader**: batching e caching per richiesta. Le chiamate a `load(userId)` nella stessa “tick” vengono raggruppate; DataLoader esegue una sola query “WHERE id IN (...)” e distribuisce i risultati.  
- **Join o query batch**: nel resolver del parent (es. lista utenti) caricare in una volta sola gli ordini per tutti gli utenti e passarli nel contesto o tramite DataLoader.

**Snippet concettuale (DataLoader)**  
Creare un DataLoader che, dati N id utente, esegue una query `SELECT * FROM orders WHERE user_id IN (...)` e restituisce ordini raggruppati per user_id. Il resolver di `orders` usa `ordersLoader.load(parent.id)`.

**Errore tipico**  
Un resolver per campo che fa una query DB per ogni singolo parent (N+1); non usare DataLoader o batch quando si espongono liste annidate.

---

## Confronto con REST

### Over-fetching e under-fetching

**Definizione**  
- **REST**: un endpoint restituisce una struttura fissa (es. GET /users/1 con tutti i campi utente e magari embed degli ordini). Il client che vuole solo nome e email riceve comunque tutto (over-fetching). Per avere utente + ordini + prodotti degli ordini servono più chiamate o endpoint custom (under-fetching o endpoint “grassi”).  
- **GraphQL**: il client chiede esattamente i campi necessari in una sola richiesta; niente over-fetching; under-fetching si risolve con una query che include le relazioni desiderate.

**Trade-off**  
GraphQL richiede un layer (schema + resolver) e gestione di caching e autorizzazione a livello di campo. REST è più semplice da cacheare (GET per URL) e da esporre come “risorsa”. REST con query params (es. `?fields=name,email`) può avvicinarsi ma senza standard unico.

**Errore tipico**  
Assumere che GraphQL sia “meglio” in ogni caso: per API semplici e risorse ben definite, REST può essere più che sufficiente.

---

## Quando usare GraphQL

**Definizione**  
GraphQL ha senso quando: client eterogenei (web, mobile, partner) con esigenze di dati diverse; riduzione del numero di round-trip e controllo fine sui campi; aggregazione di più backend in un’unica API (schema unificato). Meno adatto quando: API molto semplici; team piccoli senza esperienza GraphQL; caching a livello di HTTP/URL è prioritario.

**Caso d’uso**  
- App mobile con limiti di banda: query che chiedono solo i campi visibili nello schermo.  
- Dashboard che aggrega dati da più microservizi: un solo endpoint GraphQL che delega ai servizi nei resolver.  
- Evoluzione API senza versioning esplicito: aggiungere campi e tipi senza rompere i client che non li richiedono.

**Errore tipico**  
Adottare GraphQL “per moda” senza problemi concreti di over/under-fetching o senza risorse per mantenere schema e resolver; esporre tutto il DB senza limiti (rischio performance e sicurezza: limitare profondità e complessità delle query).

## In sintesi

- Schema: tipi, Query e Mutation; client chiede solo i campi necessari; risposta a forma di query.
- Resolver: una funzione per campo; attenzione a N+1 (DataLoader o batch); confronto con REST (over/under-fetching).
- Quando usare: client eterogenei, evoluzione API senza versioning; evitare se team piccolo e API semplici.
- Subscription per real-time (WebSocket); DataLoader per N+1; Federation per schema multipli; errori parziali e nullability; evoluzione con deprecation; introspection da limitare in prod; testing con snapshot e mock.

## Vedi anche

- [Architettura](architettura.md) — REST e API design.
- [Database](database.md) — Query e N+1.
