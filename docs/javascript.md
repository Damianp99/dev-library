# JavaScript

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Fondamentali](#fondamentali)
- [Async e Runtime](#async-e-runtime)
- [Prototipi e Moduli](#prototipi-e-moduli)
- [Performance UI](#performance-ui)

## Panoramica
Questa guida raccoglie 30 domande con risposte su JavaScript per colloqui tecnici.
Le risposte includono definizione, differenze, trade-off e un esempio essenziale
quando utile, con focus su casi reali enterprise (performance e manutenzione).

## Fondamentali

### Var vs Let/Const
- **Domanda**: Differenza tra `var`, `let` e `const`?
- **Risposta breve**: `var` ha scope di funzione e hoisting permissivo; `let/const`
  hanno block scope e TDZ, riducendo bug di ridefinizione.
- **Spiegazione estesa**: Il trade-off è tra compatibilità legacy (`var`) e
  sicurezza logica (`let/const`). In codice enterprise, `const` migliora la
  leggibilità e riduce side effect, mentre `let` serve solo se c'è riassegnazione.
- **Quando usarlo**: `const` come default, `let` per variabili mutabili in blocco.
- **Quando evitarlo**: `var` in codebase moderni per evitare scope leakage.
- **Snippet**:
```javascript
for (var i = 0; i < 2; i++) setTimeout(() => console.log(i), 0); // 2,2
for (let j = 0; j < 2; j++) setTimeout(() => console.log(j), 0); // 0,1
```
- **Errori comuni da evitare**: Usare `let` quando `const` basta; affidarsi al
  hoisting di `var` in moduli moderni.

### Hoisting: function vs function expression
- **Domanda**: Come cambia l'hoisting tra function declaration e expression?
- **Risposta breve**: Le function declaration sono hoistate con corpo; le
  expression sono hoistate solo come variabile non inizializzata.
- **Spiegazione estesa**: Il trade-off è tra flessibilità e sicurezza. Con le
  declaration puoi chiamare prima della definizione, ma in team grandi è più
  chiaro mantenere ordine top-down per leggibilità e review.
- **Quando usarlo**: Declaration per helper condivisi stabili; expression per
  mantenere flusso top-down.
- **Quando evitarlo**: Evitare call-before-define in moduli complessi.
- **Snippet**:
```javascript
hello(); // ok
function hello() { return "hi"; }

say(); // TypeError
const say = () => "hi";
```
- **Errori comuni da evitare**: Confondere `var` hoistato con expression valida.

### Closure e lifetime dei dati
- **Domanda**: Cos'è una closure e perché è utile?
- **Risposta breve**: Una closure è una funzione che cattura variabili dal suo
  scope esterno, mantenendole vive anche dopo l'esecuzione del contesto.
- **Spiegazione estesa**: Trade-off tra incapsulamento e rischio di memory leak.
  In enterprise è utile per factory di funzioni configurate, ma attenzione a
  reference non necessarie che bloccano il GC.
- **Quando usarlo**: Factory, memoization, handler con stato locale.
- **Quando evitarlo**: In loop su grandi dataset se trattieni oggetti pesanti.
- **Snippet**:
```javascript
function makeCounter() {
  let count = 0;
  return () => ++count;
}
const c = makeCounter();
c(); // 1
```
- **Errori comuni da evitare**: Catturare variabili mutate in loop asincroni.

### `this` e binding
- **Domanda**: Come funziona `this` in JS e in cosa differisce dalle arrow?
- **Risposta breve**: `this` dipende dal contesto di chiamata; le arrow non
  rilegano `this` e catturano quello lessicale.
- **Spiegazione estesa**: Trade-off tra flessibilità (call/apply/bind) e
  prevedibilità (arrow). In codice enterprise, usare arrow per callback riduce
  bug, ma per metodi di classe può servire `bind` esplicito.
- **Quando usarlo**: Arrow in callback; `bind` per passare metodi come handler.
- **Quando evitarlo**: Arrow come method prototype se serve `this` dinamico.
- **Snippet**:
```javascript
const obj = {
  id: 1,
  getId() { return this.id; }
};
const fn = obj.getId;
fn(); // undefined (strict mode)
```
- **Errori comuni da evitare**: Usare `this` in callback senza binding.

### Uguaglianza: `==` vs `===`
- **Domanda**: Differenza tra `==` e `===`?
- **Risposta breve**: `===` confronta valore e tipo senza coercizione; `==`
  applica conversioni implicite e può produrre risultati inattesi.
- **Spiegazione estesa**: Il trade-off è tra concisione e prevedibilità. In
  enterprise si preferisce `===` per evitare bug di coercizione su input sporchi.
- **Quando usarlo**: `===` come default; `== null` solo per check su `null`/`undefined`.
- **Quando evitarlo**: `==` in logica core o validazioni critiche.
- **Snippet**:
```javascript
0 == "0";   // true
0 === "0";  // false
```
- **Errori comuni da evitare**: Usare `==` con valori misti provenienti da API.

### Destructuring e default
- **Domanda**: Perché usare il destructuring con valori di default?
- **Risposta breve**: Migliora leggibilità e riduce boilerplate per estrarre
  campi opzionali con fallback sicuri.
- **Spiegazione estesa**: Trade-off tra chiarezza e rischio di nascondere bug se
  il default maschera dati mancanti. In enterprise è utile su DTO non affidabili.
- **Quando usarlo**: Parametri con molte opzioni e fallback definiti.
- **Quando evitarlo**: Quando serve distinguere tra `undefined` e valore assente.
- **Snippet**:
```javascript
function buildUser({ name = "guest", role = "viewer" } = {}) {
  return { name, role };
}
```
- **Errori comuni da evitare**: Default che sovrascrive valori falsy validi.

### Rest/Spread e immutabilità
- **Domanda**: Come rest/spread aiutano l'immutabilità?
- **Risposta breve**: Consentono di creare nuove copie superficiali senza
  mutare l'oggetto originale.
- **Spiegazione estesa**: Trade-off tra semplicità e costo: copie superficiali
  non proteggono da mutazioni annidate e possono impattare performance.
- **Quando usarlo**: Aggiornamenti di stato in UI o reducers.
- **Quando evitarlo**: Strutture molto grandi o deep copy frequenti.
- **Snippet**:
```javascript
const user = { id: 1, name: "Ana" };
const updated = { ...user, name: "Anna" };
```
- **Errori comuni da evitare**: Credere che lo spread faccia deep clone.

### Truthy/Falsy e coercizione
- **Domanda**: Cosa significa che un valore è truthy o falsy?
- **Risposta breve**: In JS alcuni valori si valutano come `false` in contesti
  booleani, anche se non sono booleani.
- **Spiegazione estesa**: Trade-off tra concisione e ambiguità. In enterprise,
  coercizione implicita può introdurre bug su input utente e dati API.
- **Quando usarlo**: Check rapidi di esistenza in logica non critica.
- **Quando evitarlo**: Validazioni dove `0`, `""` o `false` sono valori validi.
- **Snippet**:
```javascript
if ("") console.log("no"); // non entra
if ("0") console.log("si"); // entra
```
- **Errori comuni da evitare**: Usare `if (value)` quando serve un check esplicito.

### `const` vs `Object.freeze`
- **Domanda**: `const` rende un oggetto immutabile?
- **Risposta breve**: No, `const` blocca la riassegnazione del riferimento, non
  la mutazione delle proprietà.
- **Spiegazione estesa**: Trade-off tra sicurezza e performance. `Object.freeze`
  aiuta a prevenire mutazioni accidentali ma è superficiale e ha costo.
- **Quando usarlo**: Config statiche o oggetti di sola lettura.
- **Quando evitarlo**: Strutture molto grandi o mutate spesso.
- **Snippet**:
```javascript
const cfg = { debug: true };
cfg.debug = false; // ok
Object.freeze(cfg);
```
- **Errori comuni da evitare**: Pensare che `freeze` faccia deep immutability.

### Map/Set vs Object/Array
- **Domanda**: Quando scegliere `Map`/`Set` rispetto a `Object`/`Array`?
- **Risposta breve**: `Map`/`Set` offrono API semantiche e performance migliori
  per grandi collezioni e chiavi non stringa.
- **Spiegazione estesa**: Trade-off tra compatibilità e chiarezza. In enterprise,
  `Map` evita collisioni di chiavi e semplifica cache e deduplica.
- **Quando usarlo**: Cache, lookup frequenti, chiavi complesse.
- **Quando evitarlo**: JSON serialization diretta o interop legacy.
- **Snippet**:
```javascript
const cache = new Map();
cache.set(userId, user);
```
- **Errori comuni da evitare**: Usare `Object` e poi gestire manualmente le chiavi.

### Strict mode
- **Domanda**: Cos'è lo strict mode e quando usarlo?
- **Risposta breve**: Lo strict mode (`"use strict"`) disattiva comportamenti silenziosi
  e incoraggia codice più sicuro (variabili non dichiarate, delete limitato, ecc.).
- **Spiegazione estesa**: Trade-off tra compatibilità con codice legacy e riduzione
  di bug. In enterprise, usare strict in tutti i moduli e nel bundle; alcuni
  minifier lo abilitano di default.
- **Quando usarlo**: Sempre in progetti nuovi; per file o funzione, in testa al file
  o alla function.
- **Quando evitarlo**: Solo in script legacy non migrati dove la modifica romperebbe.
- **Snippet**:
```javascript
"use strict";
x = 1; // ReferenceError (senza strict creerebbe global)
function fn() { "use strict"; delete Object.prototype; } // TypeError
```
- **Errori comuni da evitare**: Mescolare file strict e non-strict senza verificare.

## Async e Runtime

### Event loop: microtask vs macrotask
- **Domanda**: Differenza tra microtask e macrotask?
- **Risposta breve**: Le microtask (Promise) vengono eseguite prima delle
  macrotask (setTimeout, I/O) a fine tick.
- **Spiegazione estesa**: Trade-off tra reattività e starvation. Abusare di
  microtask può ritardare rendering o I/O. In app enterprise, bilanciare per UX.
- **Quando usarlo**: Promise per sequenze asincrone coerenti; timer per delay UI.
- **Quando evitarlo**: Catene infinite di microtask che bloccano il main thread.
- **Snippet**:
```javascript
setTimeout(() => console.log("macro"), 0);
Promise.resolve().then(() => console.log("micro"));
// Output: micro, macro
```
- **Errori comuni da evitare**: Aspettarsi che setTimeout(0) esegua subito.

### Promise vs callback
- **Domanda**: Perché preferire Promise rispetto ai callback?
- **Risposta breve**: Le Promise migliorano la composizione e la gestione errori,
  evitando il callback hell.
- **Spiegazione estesa**: Trade-off tra overhead minimo e chiarezza. In sistemi
  enterprise, Promise e async/await rendono il flusso più testabile e leggibile.
- **Quando usarlo**: Pipeline asincrone, coordinamento di più I/O.
- **Quando evitarlo**: Funzioni sincrone semplici dove il callback e overkill.
- **Snippet**:
```javascript
fetch("/api/user")
  .then(r => r.json())
  .catch(err => console.error(err));
```
- **Errori comuni da evitare**: Dimenticare `return` nelle catene di `then`.

### async/await: sequenziale vs parallelo
- **Domanda**: Come evitare `await` sequenziali inutili?
- **Risposta breve**: Avviare le Promise prima e poi attenderle con `Promise.all`.
- **Spiegazione estesa**: Trade-off tra ordine e performance. In enterprise,
  `Promise.all` riduce latenza quando le chiamate sono indipendenti.
- **Quando usarlo**: Operazioni indipendenti (es. fetch multipli).
- **Quando evitarlo**: Quando serve ordine o c'è dipendenza tra risultati.
- **Snippet**:
```javascript
const userP = fetch("/api/user");
const permsP = fetch("/api/perms");
const [user, perms] = await Promise.all([userP, permsP]);
```
- **Errori comuni da evitare**: Usare `Promise.all` con dipendenze.

### Error handling con async/await
- **Domanda**: Come gestire errori con `async/await`?
- **Risposta breve**: Usare `try/catch` attorno agli `await` e propagare errori
  con `throw` per mantenere il flusso controllato.
- **Spiegazione estesa**: Trade-off tra chiarezza e granularità. In enterprise,
  isolare blocchi `try/catch` riduce il rischio di catturare errori non correlati.
- **Quando usarlo**: I/O che può fallire (API, storage, parsing).
- **Quando evitarlo**: Catch generici che nascondono l'origine dell'errore.
- **Snippet**:
```javascript
try {
  const res = await fetch("/api/user");
  return await res.json();
} catch (err) {
  throw new Error("User load failed");
}
```
- **Errori comuni da evitare**: Dimenticare `await` e perdere la stack trace reale.

### `Promise.all` vs `Promise.allSettled`
- **Domanda**: Quando usare `Promise.allSettled` invece di `Promise.all`?
- **Risposta breve**: `all` fallisce al primo errore; `allSettled` restituisce
  esito di tutte le Promise, utile quando alcuni fallimenti sono accettabili.
- **Spiegazione estesa**: Trade-off tra fail-fast e resilienza. In enterprise,
  `allSettled` evita che un errore blocchi il recupero di dati parziali.
- **Quando usarlo**: Aggregazioni dove ogni risposta e indipendente.
- **Quando evitarlo**: Quando il fallimento di una richiesta invalida tutto.
- **Snippet**:
```javascript
const results = await Promise.allSettled([p1, p2]);
const ok = results.filter(r => r.status === "fulfilled");
```
- **Errori comuni da evitare**: Usare `allSettled` e ignorare i rejection.

### Cancellazione fetch con AbortController
- **Domanda**: Come cancellare una richiesta `fetch`?
- **Risposta breve**: Con `AbortController` si interrompe la fetch e si evita
  di aggiornare la UI con risposte obsolete.
- **Spiegazione estesa**: Trade-off tra complessità e UX. In enterprise,
  cancellare evita race condition in search-as-you-type.
- **Quando usarlo**: Richieste correlate a input rapido o navigazione.
- **Quando evitarlo**: Operazioni critiche che devono completarsi.
- **Snippet**:
```javascript
const controller = new AbortController();
fetch("/api/search?q=a", { signal: controller.signal });
controller.abort();
```
- **Errori comuni da evitare**: Non gestire l'errore di abort nel catch.

### Timeout con `Promise.race`
- **Domanda**: Come implementare un timeout su una Promise?
- **Risposta breve**: Si usa `Promise.race` con una Promise che rifiuta dopo un
  tempo limite.
- **Spiegazione estesa**: Trade-off tra semplicità e gestione risorse. In enterprise,
  è importante cancellare la richiesta reale per evitare lavoro inutile.
- **Quando usarlo**: Chiamate esterne non affidabili o lente.
- **Quando evitarlo**: Operazioni che non devono essere interrotte.
- **Snippet**:
```javascript
const timeout = ms => new Promise((_, r) => setTimeout(() => r("timeout"), ms));
await Promise.race([fetch("/api"), timeout(2000)]);
```
- **Errori comuni da evitare**: Non annullare la fetch dopo il timeout.

### `queueMicrotask` vs `setTimeout`
- **Domanda**: Quando usare `queueMicrotask` invece di `setTimeout`?
- **Risposta breve**: `queueMicrotask` pianifica una microtask che gira prima del
  prossimo repaint, con latenza minore.
- **Spiegazione estesa**: Trade-off tra priorita e rischio starvation. In enterprise,
  utile per post-processing leggero senza bloccare rendering.
- **Quando usarlo**: Micro operazioni di cleanup o chaining logico.
- **Quando evitarlo**: Cicli che potrebbero saturare la coda microtask.
- **Snippet**:
```javascript
queueMicrotask(() => console.log("micro"));
setTimeout(() => console.log("macro"), 0);
```
- **Errori comuni da evitare**: Usare microtask per lavori pesanti.

### Unhandled Promise Rejection
- **Domanda**: Cosa succede con una Promise rifiutata senza catch?
- **Risposta breve**: In runtime moderni genera un unhandled rejection e può
  terminare il processo o loggare errori critici.
- **Spiegazione estesa**: Trade-off tra velocità di sviluppo e affidabilità.
  In enterprise, va sempre gestita per evitare crash o alert rumorosi.
- **Quando usarlo**: Sempre gestire `catch` o `try/catch` su `await`.
- **Quando evitarlo**: Lasciare Promise pendenti senza consumer.
- **Snippet**:
```javascript
doAsync().catch(err => report(err));
```
- **Errori comuni da evitare**: Dimenticare `return` su catene di Promise.

### Error handling e stack trace
- **Domanda**: Come gestire errori e sfruttare la stack trace in produzione?
- **Risposta breve**: Usare `try/catch` per logica sincrona; per async, `try/catch`
  su `await` o `.catch()`. La stack trace aiuta il debug ma va preservata (no
  re-throw senza causa).
- **Spiegazione estesa**: Trade-off tra fail-fast e resilienza. In enterprise,
  loggare errori con stack e contesto (request id); source map in staging per
  mappare bundle a sorgente; in prod valutare di non esporre stack al client.
- **Quando usarlo**: Sempre gestire errori su I/O; preservare stack con `Error.captureStackTrace` (Node) o new Error().
- **Quando evitarlo**: Catch vuoto che nasconde l'errore; loggare stack in chiaro al client.
- **Snippet**:
```javascript
try {
  await riskyOp();
} catch (err) {
  console.error(err.message, err.stack);
  throw err; // propaga mantenendo stack
}
```
- **Errori comuni da evitare**: `catch (e) { throw "failed"; }` perde la stack originale.

## Prototipi e Moduli

### Prototipi vs class syntax
- **Domanda**: Qual è la differenza tra prototipi e `class`?
- **Risposta breve**: `class` e sintassi sopra il prototipo; l'ereditarieta resta
  prototipale.
- **Spiegazione estesa**: Trade-off tra chiarezza (class) e flessibilità
  prototipale. In team grandi, `class` aiuta la leggibilità e l'onboarding.
- **Quando usarlo**: `class` per modelli dominio e API pubbliche.
- **Quando evitarlo**: Modifiche dinamiche a runtime in codice complesso.
- **Snippet**:
```javascript
class User { constructor(id){ this.id = id; } }
User.prototype.isAdmin = function(){ return false; };
```
- **Errori comuni da evitare**: Pensare che `class` usi un modello a classi reale.

### ESM vs CommonJS
- **Domanda**: Differenza tra ES Modules e CommonJS?
- **Risposta breve**: ESM ha import statico e tree-shaking; CJS usa require
  dinamico, meno ottimizzabile.
- **Spiegazione estesa**: Trade-off tra compatibilità legacy (CJS) e performance
  build/runtime (ESM). In enterprise, ESM migliora bundle size e analisi statica.
- **Quando usarlo**: ESM in progetti moderni o bundler; CJS solo per legacy.
- **Quando evitarlo**: Mixing parziale senza strategia di migrazione.
- **Snippet**:
```javascript
// ESM
import { readFile } from "fs";
// CJS
const { readFile } = require("fs");
```
- **Errori comuni da evitare**: Interoperabilità non gestita tra ESM e CJS.

### Catena dei prototipi e `hasOwnProperty`
- **Domanda**: Come distinguere proprietà proprie da quelle ereditate?
- **Risposta breve**: `obj.hasOwnProperty` controlla solo le proprietà proprie,
  mentre l'operatore `in` considera anche la catena dei prototipi.
- **Spiegazione estesa**: Trade-off tra sicurezza e flessibilità. In enterprise,
  distinguere evita bug nei mapper o nei validatori.
- **Quando usarlo**: Validazione di payload o serializzazione selettiva.
- **Quando evitarlo**: Iterare su oggetti creati senza prototipo standard.
- **Snippet**:
```javascript
const obj = Object.create({ inherited: 1 });
obj.own = 2;
"inherited" in obj; // true
obj.hasOwnProperty("inherited"); // false
```
- **Errori comuni da evitare**: Usare `for...in` senza filtro su proprietà proprie.

### Iteratori e for..of (Symbol.iterator)
- **Domanda**: Cos'è un iteratore e come usare `for..of`?
- **Risposta breve**: Un iteratore è un oggetto con metodo `next()` che restituisce
  `{ value, done }`. Gli iterabili espongono `Symbol.iterator`; `for..of` li consuma.
- **Spiegazione estesa**: Trade-off tra standardizzazione e complessità. In enterprise,
  iteratori permettono API lazy e composabili (generatori, Map, Set, NodeList).
- **Quando usarlo**: Collezioni custom, stream di dati, integrazione con librerie.
- **Quando evitarlo**: Semplici loop su array con indice quando serve l'indice.
- **Snippet**:
```javascript
const iterable = { [Symbol.iterator]: function* () { yield 1; yield 2; } };
for (const x of iterable) console.log(x); // 1, 2
```
- **Errori comuni da evitare**: Confondere iterabile (ha Symbol.iterator) con iteratore (ha next()).

### Import dinamico
- **Domanda**: Quando usare `import()` dinamico?
- **Risposta breve**: Serve per caricare moduli on-demand riducendo il bundle
  iniziale e migliorando il tempo di avvio.
- **Spiegazione estesa**: Trade-off tra performance e complessità. In enterprise,
  code-splitting riduce time-to-interactive ma richiede gestione errori di load.
- **Quando usarlo**: Feature rare o route poco usate.
- **Quando evitarlo**: Moduli core necessari al primo render.
- **Snippet**:
```javascript
const chart = await import("./chart.js");
chart.render();
```
- **Errori comuni da evitare**: Assumere che `import()` sia sincrono.

### `Symbol` come chiavi sicure
- **Domanda**: Perché usare `Symbol` come chiave di proprietà?
- **Risposta breve**: `Symbol` crea chiavi uniche che evitano collisioni con
  proprietà esistenti o di librerie.
- **Spiegazione estesa**: Trade-off tra sicurezza e debuggabilita. In enterprise,
  utile per metadati interni senza inquinare il namespace.
- **Quando usarlo**: Metadata su oggetti condivisi tra moduli.
- **Quando evitarlo**: Quando serve serializzare in JSON.
- **Snippet**:
```javascript
const meta = Symbol("meta");
obj[meta] = { internal: true };
```
- **Errori comuni da evitare**: Aspettarsi che `JSON.stringify` includa Symbol.

### `Proxy` per validazione e tracing
- **Domanda**: Quando usare `Proxy`?
- **Risposta breve**: Intercetta operazioni su oggetti (get/set) per validare,
  loggare o controllare accessi.
- **Spiegazione estesa**: Trade-off tra potenza e overhead. In enterprise,
  utile per instrumentation ma può rallentare hot path.
- **Quando usarlo**: Debugging, tracking, validazioni centralizzate.
- **Quando evitarlo**: Se la performance e critica.
- **Snippet**:
```javascript
const p = new Proxy(user, { set: (t, k, v) => (t[k] = v, true) });
```
- **Errori comuni da evitare**: Usare `Proxy` come default in produzione.

### Reflect
- **Domanda**: A cosa serve `Reflect` e quando usarlo con `Proxy`?
- **Risposta breve**: `Reflect` espone come funzioni le stesse operazioni che il
  motore usa (get, set, has, deleteProperty); in un trap di Proxy si usa spesso
  `Reflect.*` per il comportamento default.
- **Spiegazione estesa**: Trade-off tra controllo e manutenibilità. In Proxy,
  delegare a `Reflect.get(target, key)` evita di reimplementare la logica standard
  e riduce bug.
- **Quando usarlo**: Dentro i trap di Proxy per invocare il comportamento default.
- **Quando evitarlo**: Quando non si usa Proxy o non serve delegazione.
- **Snippet**:
```javascript
const p = new Proxy(obj, {
  get(target, key) {
    log(key);
    return Reflect.get(target, key);
  }
});
```
- **Errori comuni da evitare**: Implementare manualmente get/set nel trap invece di Reflect.

### WeakMap e WeakSet
- **Domanda**: Quando usare WeakMap/WeakSet invece di Map/Set?
- **Risposta breve**: WeakMap e WeakSet tengono riferimenti "deboli": se l'oggetto
  non è più usato altrove, può essere garbage-collected; le chiavi devono essere oggetti.
- **Spiegazione estesa**: Trade-off tra memoria e limitazioni (no iterazione, no size).
  In enterprise, utili per cache associate a oggetti DOM o a istanze senza
  prolungarne la vita.
- **Quando usarlo**: Metadata su oggetti esterni, cache per istanza, dedup senza trattenere riferimenti.
- **Quando evitarlo**: Quando serve iterare, avere size o usare chiavi primitive.
- **Snippet**:
```javascript
const cache = new WeakMap();
cache.set(domNode, computedValue); // domNode può essere GC quando non usato
```
- **Errori comuni da evitare**: Usare WeakMap con chiavi primitive (non consentito).

## Performance UI

### Debounce vs Throttle
- **Domanda**: Quando usare debounce e quando throttle?
- **Risposta breve**: Debounce aspetta l'inattivita; throttle limita la frequenza.
- **Spiegazione estesa**: Trade-off tra reattivita e riduzione carico. In UI
  enterprise, debounce è ideale per search-as-you-type; throttle per scroll.
- **Quando usarlo**: Debounce su input; throttle su eventi ad alta frequenza.
- **Quando evitarlo**: Debounce su click critici; throttle su input con validazioni.
- **Snippet**:
```javascript
const debounce = (fn, ms) => {
  let t;
  return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), ms); };
};
```
- **Errori comuni da evitare**: Non cancellare timer, creando leak di handler.

### Event delegation
- **Domanda**: Perché usare l'event delegation?
- **Risposta breve**: Si registra un solo listener su un contenitore per gestire
  eventi di molti figli, riducendo handler e memoria.
- **Spiegazione estesa**: Trade-off tra semplicità e controllo. In enterprise,
  migliora performance su liste dinamiche ma richiede filtro del target.
- **Quando usarlo**: Liste grandi o contenuti generati dinamicamente.
- **Quando evitarlo**: Eventi non bubbling o logica molto specifica per elemento.
- **Snippet**:
```javascript
list.addEventListener("click", e => {
  if (e.target.matches("button.remove")) removeItem(e.target);
});
```
- **Errori comuni da evitare**: Non gestire click su elementi annidati.

### `requestAnimationFrame` vs `setTimeout`
- **Domanda**: Quando usare `requestAnimationFrame`?
- **Risposta breve**: Per aggiornare UI/animazioni sincronizzandosi con il render
  del browser, evitando frame drop.
- **Spiegazione estesa**: Trade-off tra accuratezza temporale e fluidita. In
  enterprise, `requestAnimationFrame` migliora la UX ma va cancellato correttamente.
- **Quando usarlo**: Animazioni o misure layout in loop.
- **Quando evitarlo**: Task non legati al rendering o timer di business logic.
- **Snippet**:
```javascript
let id;
function tick() { /* update */ id = requestAnimationFrame(tick); }
id = requestAnimationFrame(tick);
```
- **Errori comuni da evitare**: Dimenticare `cancelAnimationFrame` on teardown.

### Listener passivi
- **Domanda**: Cosa sono i listener passivi e quando usarli?
- **Risposta breve**: `passive: true` segnala al browser che non chiamerai
  `preventDefault`, migliorando lo scrolling.
- **Spiegazione estesa**: Trade-off tra controllo e performance. In enterprise,
  riduce jank su mobile ma limita la gestione di gesture custom.
- **Quando usarlo**: Scroll, touch e wheel su pagine pesanti.
- **Quando evitarlo**: Quando devi bloccare lo scroll con `preventDefault`.
- **Snippet**:
```javascript
window.addEventListener("scroll", onScroll, { passive: true });
```
- **Errori comuni da evitare**: Usare passive e poi chiamare `preventDefault`.

### Reflow/repaint e layout thrashing
- **Domanda**: Cos'è il layout thrashing?
- **Risposta breve**: Letture e scritture alternate di layout causano reflow
  multipli e rallentano il rendering.
- **Spiegazione estesa**: Trade-off tra semplicità e performance. In enterprise,
  batchare letture/scritture riduce il costo di rendering.
- **Quando usarlo**: Separare letture DOM da scritture (batch).
- **Quando evitarlo**: Misurare layout dentro loop di animazione senza caching.
- **Snippet**:
```javascript
const w = box.offsetWidth; // read
box.style.width = (w + 10) + "px"; // write
```
- **Errori comuni da evitare**: Alternare read/write in loop su molti elementi.

### Web Workers e OffscreenCanvas (cenni)
- **Domanda**: Quando delegare lavoro pesante a un Web Worker?
- **Risposta breve**: I Worker eseguono script in un thread separato; utili per
  calcoli CPU-bound (crypto, parsing, elaborazione dati) senza bloccare il main thread.
- **Spiegazione estesa**: Trade-off tra complessità (messaging, serializzazione)
  e fluidità UI. OffscreenCanvas permette di disegnare da un Worker per
  animazioni o rendering pesante.
- **Quando usarlo**: Algoritmi pesanti, parsing di file grandi, rendering complesso.
- **Quando evitarlo**: I/O o logica che richiede DOM; overhead non giustificato.
- **Snippet**:
```javascript
const w = new Worker("./worker.js");
w.postMessage({ data: bigArray });
w.onmessage = (e) => updateUI(e.data);
```
- **Errori comuni da evitare**: Passare oggetti non clonabili (funzioni, DOM) a postMessage.

## In sintesi

- `var` ha function scope e hoisting; `let`/`const` hanno block scope e TDZ; preferire `let`/`const`.
- Closure: funzione che "ricorda" il suo scope; attenzione a loop e riferimenti mutabili.
- Event loop: call stack, task queue, microtask (Promise) prima dei macrotask; evitare bloccare il main thread.
- `async/await` è zucchero sintattico sulle Promise; gestire errori con try/catch.
- Prototipi: catena per property lookup; `Object.create`, `new` e `class`; evitare mutare `Object.prototype`.
- Strict mode: riduce bug e comportamenti silenziosi; usare in tutti i moduli.
- Iteratori e `for..of`: iterabili con `Symbol.iterator`; WeakMap/WeakSet per cache senza trattenere riferimenti.
- Error handling: try/catch e stack trace; in prod preservare stack lato server, valutare source map.

## Vedi anche

- [TypeScript](typescript.md) — Type safety e tooling su JavaScript.
- [Angular](angular.md) e [React](react.md) — Framework che usano JavaScript/TypeScript.
