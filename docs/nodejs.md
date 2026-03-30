# Node.js

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Event loop](#event-loop)
- [Moduli: CommonJS vs ESM](#moduli-commonjs-vs-esm)
- [Async/await e gestione errori](#asyncawait-e-gestione-errori)
- [Express e Fastify](#express-e-fastify)
- [Confronto con Go/Java e uso in produzione](#confronto-con-gojava-e-uso-in-produzione)
- [Worker Threads e Stream](#worker-threads-e-stream)
- [Script, env e logging](#script-env-e-logging)
- [Sicurezza e testing](#sicurezza-e-testing)

## Panoramica

Node.js è un runtime JavaScript (V8) per il backend: single-thread, I/O non bloccante tramite event loop e callback/Promise. È adatto a applicazioni I/O bound (API, proxy, real-time) e consente stack full-stack JavaScript/TypeScript. In produzione si usa per servizi HTTP, worker, script e tooling.

---

## Event loop

### Concetto e fasi

**Definizione tecnica**  
L’event loop è il meccanismo che permette a Node.js di eseguire codice asincrono senza bloccare il thread unico. Le operazioni I/O (file, rete, timer) vengono delegate al sistema operativo o a thread pool (libuv); al termine vengono accodate nelle code delle fasi (timers, I/O callbacks, idle, poll, check, close) e processate in ordine.

**Flusso operativo**  
1. Esecuzione del codice sincrono (call stack).  
2. Quando una chiamata async completa (timer scaduto, socket ready), il callback viene messo nella coda della fase appropriata.  
3. A ogni “tick” l’event loop processa una fase, esegue i callback pronti e passa alla fase successiva.  
4. Il thread non resta in attesa su I/O: può servire altre richieste mentre aspetta disco/rete.

**Snippet / diagramma testuale**

```
timers (setTimeout/setInterval)
    → pending callbacks (I/O completati)
    → idle, prepare
    → poll (nuovi I/O, attesa se necessario)
    → check (setImmediate)
    → close callbacks
    → ripeti
```

**Failure mode comune**  
Eseguire logica CPU-intensive (calcoli pesanti, JSON grandi) nel thread principale: blocca l’event loop e ritarda tutte le altre richieste. Soluzione: delegare a worker thread o a un servizio esterno.

**Best practice**  
Mantenere il main thread libero per I/O e orchestrazione; usare `setImmediate` o `process.nextTick` con criterio per differire lavoro; monitorare il lag dell’event loop (strumenti come clinic.js o metriche custom).

---

## Moduli: CommonJS vs ESM

### Definizione e differenze

**Definizione tecnica**  
CommonJS (CJS): `require()` e `module.exports`; caricamento sincrono; è il formato storico di Node. ESM (ECMAScript Modules): `import` / `export`; caricamento asincrono; standard JavaScript. Node supporta entrambi; il tipo di modulo è stabilito dall’estensione (`.cjs` / `.mjs`) o dal campo `"type": "module"` in `package.json`.

**Differenze pratiche**  
- CJS: `const x = require('pkg')`; `module.exports = { ... }`. Sincrono, adatto a script e compatibilità.  
- ESM: `import x from 'pkg'`; `export default ...` o `export { ... }`. Top-level await, tree-shaking migliore, interoperabilità con bundler e browser.  
- In un progetto con `"type": "module"`, i file `.js` sono ESM; i file `.cjs` restano CJS. In progetti senza `type`, `.js` è CJS e `.mjs` è ESM.

**Snippet**

```javascript
// CommonJS
const { readFile } = require("fs");
module.exports = { myFn };

// ESM (file .mjs o "type": "module")
import { readFile } from "fs";
import pkg from "pkg";
export default myFn;
export { helper };
```

**Failure mode comune**  
Mescolare `require` in file ESM o `import` in file CJS senza transpilazione; usare `__dirname` in ESM (non definito, usare `import.meta.url` e path).

**Best practice**  
Preferire ESM per progetti nuovi; per librerie mantenere CJS o dual package se si deve supportare ambienti vecchi. Non usare estensioni nelle import ESM (a parte `.mjs`/`.cjs` dove richiesto).

---

## Async/await e gestione errori

### Promise, try/catch, propagazione

**Definizione tecnica**  
Le operazioni asincrone in Node sono basate su callback (stile error-first) o su Promise. `async/await` è zucchero sintattico sulle Promise: `await` sospende la funzione fino al resolve; il reject viene propagato come eccezione e si gestisce con try/catch.

**Flusso**  
1. Funzione `async` restituisce una Promise.  
2. `await promise` restituisce il valore risolto o lancia un’eccezione in caso di reject.  
3. try/catch nella funzione async gestisce errori sincroni e reject.  
4. Promise non gestite (unhandled rejection) vanno evitate: usare catch sulla Promise o gestori globali (`process.on('unhandledRejection')`).

**Snippet**

```javascript
async function fetchUser(id) {
  const res = await fetch(`/api/users/${id}`);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

async function main() {
  try {
    const user = await fetchUser(1);
    console.log(user);
  } catch (err) {
    console.error(err);
  }
}
main();
```

**Failure mode comune**  
Dimenticare try/catch o .catch(): unhandled rejection può far terminare il processo (a seconda della versione e delle opzioni). Chiamare async senza await in punti critici (es. fire-and-forget senza gestione errori).

**Best practice**  
Sempre gestire gli errori (try/catch o .catch()); in Express/Fastify usare middleware di error handling centralizzato; non lasciare promise “floating” senza catch.

---

## Express e Fastify

### Middleware, routing, integrazione DB

**Definizione tecnica**  
Express è il framework HTTP più usato in Node: middleware in sequenza (req, res, next), routing per metodo e path, integrazione con template e API. Fastify offre API simile con performance migliori, schema validation (JSON Schema) e plugin system.

**Flusso operativo**  
1. Richiesta entra nel primo middleware.  
2. Ogni middleware può modificare req/res, chiamare next() per passare al successivo o inviare la risposta (res.send, res.json).  
3. Il routing abbina metodo e path e invoca il handler (o una catena di middleware).  
4. Connessione DB: creare un pool (pg, mysql2, ecc.) all’avvio e iniettarlo in req o usare un modulo condiviso; nelle route eseguire query async e restituire JSON.

**Snippet**

```javascript
// Express
const express = require("express");
const app = express();
app.use(express.json());
app.get("/users/:id", async (req, res, next) => {
  try {
    const user = await db.query("SELECT * FROM users WHERE id = $1", [req.params.id]);
    res.json(user.rows[0] || {});
  } catch (err) {
    next(err);
  }
});
app.use((err, req, res, next) => {
  res.status(500).json({ error: err.message });
});
```

**Differenza Express vs Fastify**  
Fastify usa un modello a plugin, validazione integrata sui body/params e serializzazione ottimizzata; in benchmark ha throughput maggiore. Express ha ecosistema più grande e documentazione molto diffusa.

**Failure mode comune**  
Non chiamare next() in un middleware che non termina la richiesta: la richiesta resta “appesa”. Non usare try/catch (o next(err)) negli handler async: Express non gestisce i reject delle Promise da solo (in Express 5 sì; in 4 serve wrapper o middleware che fa catch e next(err)).

**Best practice**  
Middleware di errore centralizzato; validazione input (es. express-validator o schema Fastify); pool DB connesso una volta; logging e correlation id per tracciabilità.

---

## Confronto con Go/Java e uso in produzione

### Single-thread vs multithread

**Definizione tecnica**  
Node è single-thread per il codice applicativo: un solo call stack, un solo event loop per processo. Go e Java usano più thread (o goroutine/thread) per sfruttare più core. Node scala in orizzontale (più processi, es. cluster o PM2) o delegando lavoro pesante a worker thread.

**Quando Node è adatto**  
- I/O bound: API REST, proxy, WebSocket, aggregazione di servizi esterni.  
- Real-time e alta concorrenza di connessioni con poco lavoro per richiesta.  
- Stack unificato JS/TS con il frontend.

**Quando è meno adatto**  
- CPU intensive: elaborazione immagini, crittografia pesante, calcoli scientifici (valutare worker threads o servizio separato in Go/Java).  
- Requisiti di multithreading nativo (molti core su singola macchina con stato condiviso complesso).

**Worker threads e cluster**  
Worker threads: eseguire codice CPU-bound in un thread separato senza bloccare l’event loop. Cluster: avviare più processi Node che condividono la stessa porta (load balancing dal kernel o da un reverse proxy). In produzione spesso si usano PM2 o Kubernetes per gestire più istanze.

**Best practice produzione**  
- Variabili d’ambiente per config (porta, DB URL, segreti); niente secret in codice.  
- Graceful shutdown: chiudere il server e le connessioni DB al segnale SIGTERM.  
- Logging strutturato (JSON) e health check endpoint.  
- Rate limiting e sicurezza (HTTPS, CORS, validazione input) come in [Sicurezza](sicurezza.md).

---

## Worker Threads e Stream

### Worker Threads
**Definizione tecnica**  
Il modulo `worker_threads` permette di eseguire codice JavaScript in thread separati (con V8 isolate per thread). Si usa per lavoro CPU-bound senza bloccare l'event loop: calcoli pesanti, crittografia, parsing di grandi file. I dati si passano con `postMessage` (structured clone) o con `SharedArrayBuffer` per memoria condivisa.

**Differenze pratiche**  
- Creare un Worker con `new Worker("./worker.js", { workerData: ... })`; in worker.js si riceve con `workerData` e si risponde con `parentPort.postMessage()`.  
- Non condividere oggetti non clonabili (funzioni, handle); per grandi buffer considerare Transferable.

**Best practice**  
Usare worker solo per task misurabilmente costosi; riusare worker (pool) invece di crearne uno per richiesta; evitare per I/O (l'event loop già lo gestisce).

**Snippet**

```js
const { Worker } = require("worker_threads");
const w = new Worker("./compute.js", { workerData: { n: 42 } });
w.on("message", (result) => { ... });
```

**Failure mode**  
Worker che non termina (leak); passare dati troppo grandi per postMessage (lento). Soluzione: timeout e terminate(); stream o chunk per dati grandi.

### Stream (Readable, Writable, pipeline)
**Definizione tecnica**  
Le stream sono astrazioni per dati in flusso: Readable (lettura), Writable (scrittura), Duplex, Transform. `stream.pipeline(from, transform, to, cb)` gestisce errori e cleanup. Il backpressure è automatico: la Writable segnala quando è piena e la Readable si ferma.

**Differenze pratiche**  
- Readable: `createReadStream`, `readable.on("data")` o async iterator.  
- Evitare di accumulare tutto in memoria; per file e risposta HTTP usare stream.  
- pipeline sostituisce pipe() con gestione errori centralizzata.

**Best practice**  
Usare pipeline per catene di stream; gestire eventi "error" e "close"; non ignorare backpressure (scrivere solo quando write ritorna true o dopo "drain").

**Snippet**

```js
const { pipeline } = require("stream");
const fs = require("fs");
pipeline(
  fs.createReadStream("in.txt"),
  transformStream,
  fs.createWriteStream("out.txt"),
  (err) => { if (err) console.error(err); }
);
```

**Failure mode**  
Stream non chiusi (file handle leak); scrivere senza rispettare backpressure (memory spike). Soluzione: sempre gestire "finish"/"end" e distruggere stream in errore.

---

## Script, env e logging

### NPM scripts, nodemon, variabili d'ambiente
**Definizione tecnica**  
In `package.json`, `scripts` definisce comandi (es. `"start": "node server.js"`, `"dev": "nodemon server.js"`). Le variabili d'ambiente si leggono con `process.env`; in sviluppo si usano file `.env` con dotenv (o variabili di sistema). Nodemon riavvia il processo al cambio file.

**Differenze pratiche**  
- Script: `npm run dev`, `npm start` (default); pre/post script con `predev`, `postdev`.  
- Env: non committare `.env` con secret; usare `.env.example` con placeholder; in produzione iniettare env da orchestrazione (K8s, pipeline).

**Best practice**  
Un solo punto di configurazione (env); validare variabili obbligatorie all'avvio; nodemon per dev con ignore su node_modules.

**Failure mode**  
Secret in codice o in .env committato; app che parte senza variabili critiche (DB URL). Soluzione: env per tutto; fail fast se variabili mancanti.

### Logging e diagnostica
**Definizione tecnica**  
Log strutturato (JSON) con librerie come pino o winston; livelli (info, warn, error); correlazione con request ID (middleware che assegna id e lo propaga). Node offre `process.report` e flag `--diagnostic-report-*` per report su signal o uncaughtException.

**Differenze pratiche**  
- In produzione: JSON su stdout per raccolta da container/orchestrator; evitare console.log per log applicativo.  
- Diagnostica: heap snapshot, report su SIGUSR2; utile per incident post-mortem.

**Best practice**  
Livelli coerenti; non loggare secret o PII; request ID in ogni log di request; metriche (latency, status) per APM.

---

## Sicurezza e testing

### Sicurezza: helmet, validazione input
**Definizione tecnica**  
`helmet` è un middleware Express che imposta header di sicurezza (X-Content-Type-Options, X-Frame-Options, CSP, ecc.). La validazione input (body, query, params) va fatta con librerie (joi, zod, express-validator) per evitare injection e payload malformati.

**Differenze pratiche**  
- Helmet: configurabile per disabilitare singoli header se necessario (es. CSP in sviluppo).  
- Validazione: sempre whitelist (schema atteso), mai fidarsi di input utente; sanitizzare output (escape HTML se si restituisce HTML).

**Best practice**  
Helmet in produzione; validare e limitare dimensione body; rate limiting (express-rate-limit); HTTPS e cookie sicuri.

**Failure mode**  
Header mancanti (clickjacking, XSS); input non validato (NoSQL/command injection). Soluzione: helmet di default; validazione centralizzata (middleware o schema su route).

### Testing (Jest/Vitest, supertest)
**Definizione tecnica**  
Jest o Vitest come test runner (describe, it, expect); per test su API HTTP si usa supertest: `request(app).get("/path").expect(200)` senza avviare il server. Mock di moduli con jest.mock() o vi.mock(); per DB e API esterne usare mock o container di test.

**Differenze pratiche**  
- supertest: integra con Express/Fastify; supporta cookie e redirect.  
- Test async: async/await in it(); setup/teardown con beforeAll/afterAll (es. connessione DB test).

**Best practice**  
Test unitari su logica isolata; test di integrazione su endpoint critici; non dipendere da ordine; usare factory o fixture per dati.

**Snippet**

```js
const request = require("supertest");
const app = require("../app");
it("GET /health returns 200", async () => {
  await request(app).get("/health").expect(200);
});
```

**Failure mode**  
Test che dipendono da stato globale o da ordine; mock non allineati con contratto reale. Soluzione: test isolati; contract test separati per API esterne.

## In sintesi

- Event loop: single-thread, I/O non bloccante; fasi (timers, I/O, check, close); microtask (Promise) prima dei macrotask.
- CommonJS (require/module.exports) vs ESM (import/export); package.json "type": "module" per ESM.
- Async/await e gestione errori: try/catch su async; evitare Promise non gestite; Express/Fastify per HTTP.
- Adatto a I/O-bound e real-time; per CPU-bound usare worker threads o cluster; graceful shutdown e health check.
- Worker threads per CPU-bound; stream e pipeline per I/O efficiente; NPM scripts e env per config; logging strutturato; helmet e validazione per sicurezza; Jest/supertest per test.

## Vedi anche

- [JavaScript](javascript.md) e [TypeScript](typescript.md) — Linguaggio e tipi.
- [Database](database.md) — Connessioni e pool.
- [Sicurezza](sicurezza.md) — Auth e API sicure.
