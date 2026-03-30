# TypeScript

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Type inference](#type-inference)
- [Interface vs type](#interface-vs-type)
- [Union e intersection](#union-e-intersection)
- [Discriminated union](#discriminated-union)
- [Generics](#generics)
- [Utility types](#utility-types)
- [Typing vs runtime](#typing-vs-runtime)
- [readonly e immutabilità](#readonly-e-immutabilità)
- [unknown vs any](#unknown-vs-any)
- [Type narrowing e type guard](#type-narrowing-e-type-guard)
- [never](#never)
- [Template literal types](#template-literal-types)
- [Mapped types e keyof](#mapped-types-e-keyof)
- [Conditional types (basics)](#conditional-types-basics)
- [Const assertions e inferenza letterale](#const-assertions-e-inferenza-letterale)
- [Branded types](#branded-types)
- [Decoratori (experimental)](#decoratori-experimental)
- [Configurazione tsconfig](#configurazione-tsconfig)

---

## Panoramica

TypeScript è un superset tipizzato di JavaScript che aggiunge annotazioni di tipo statiche e inferenza. Il compilatore elimina i tipi in fase di transpilazione: **non esiste validazione a runtime**. Il valore sta nel catch degli errori in fase di sviluppo, nell'autocompletamento e nella documentazione implicita del codice.

**Quando usare TypeScript**: progetti con team multipli, API pubbliche, integrazioni complesse. **Quando evitare**: script rapidi, prototipi monouso dove il setup rallenta l'iterazione.

---

## Type inference

### Domanda
Quando affidarsi all'inferenza e quando annotare esplicitamente?

### Risposta breve
Usa inferenza per codice semplice e variabili locali; annotazioni esplicite per API pubbliche, parametri di funzione e confini di modulo.

### Spiegazione estesa
L'inferenza riduce boilerplate e mantiene il tipo sincronizzato con l'implementazione. Le annotazioni esplicite chiariscono i contratti per chi consuma il codice e per il tooling. In contesti enterprise, le firme pubbliche (export) dovrebbero essere sempre tipate per evitare breaking change silenziosi.

**Edge case**: variabili inizializzate con `null` o `undefined` vengono inferite come quel tipo letterale; serve un type esplicito per permettere assegnazioni successive.

### Snippet

```typescript
let id = 1;              // inferred: number
let userId: number | null = null;  // senza annotazione: inferred null

function fetchUser(id: number): Promise<User> {  // annotazione su API pubblica
  return api.get(`/users/${id}`);
}
```

### Errori comuni da evitare
- Esporre funzioni o oggetti senza type chiaro negli export.
- Annotare ogni variabile locale quando l'inferenza è ovvia (over-engineering).

---

## Interface vs type

### Domanda
Qual è la differenza tra `interface` e `type`? Quando usare l'uno o l'altro?

### Risposta breve
`interface` supporta estensione e declaration merging; `type` è più flessibile per union, intersection e tipi mappati.

### Spiegazione estesa
- **interface**: dichiarazione nominale, può essere estesa con `extends`, supporta declaration merging (più dichiarazioni con lo stesso nome si fondono). Ideale per API stabili e contratti di oggetti.
- **type**: alias di tipo, non supporta merging. Necessario per union (`A | B`), intersection (`A & B`), tuple, tipi condizionali e mappati.

**Criterio di scelta**: preferisci `interface` per oggetti e contratti; usa `type` quando devi combinare o derivare tipi complessi.

### Snippet

```typescript
interface User {
  id: string;
  name: string;
}

// type per union e modelli complessi
type ApiResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: string };

// interface: declaration merging (utile per estensioni di librerie)
interface Window {
  myCustomProp: string;
}
```

### Errori comuni da evitare
- Usare `type` e aspettarsi declaration merging.
- Creare `interface` per union o tipi che richiedono `&` o `|`.

---

## Union e intersection

### Domanda
A cosa servono union e intersection? Qual è la differenza pratica?

### Risposta breve
Union (`|`) rappresenta alternative: un valore può essere di tipo A **oppure** B. Intersection (`&`) combina proprietà: un valore deve soddisfare **entrambi** i tipi.

### Spiegazione estesa
- **Union**: modella varianti, stati mutuamente esclusivi, risposte API con successo/errore. Il narrowing (restringimento) avviene con `if`, `switch` o type guard.
- **Intersection**: compone feature o mixin. Ogni proprietà deve essere compatibile; se due tipi definiscono lo stesso campo con tipi diversi, si ottiene `never` per quel campo.

**Edge case**: intersection di tipi con campi incompatibili genera tipi inutilizzabili o `never`.

### Snippet

```typescript
type Id = string | number;

type Audited = { createdAt: Date };
type User = { id: string; name: string } & Audited;

// union per varianti
type Status = "pending" | "success" | "error";
```

### Errori comuni da evitare
- Creare intersection con campi che si sovrascrivono con tipi incompatibili.
- Usare union senza discriminante quando servono oggetti con strutture diverse (preferire discriminated union).

---

## Discriminated union

### Domanda
Perché usare le discriminated union? Come funzionano?

### Risposta breve
Rendono il type narrowing sicuro e automatico grazie a un campo discriminante (literal) condiviso da tutte le varianti.

### Spiegazione estesa
Sono ideali per stati a macchina, risposte API, eventi. Il discriminante deve essere un literal (`"success"`, `"error"`, `0`, `1`), non un `boolean` generico. Dopo un check sul discriminante, TypeScript restringe correttamente il tipo e permette l'accesso ai campi specifici di ogni variante.

**Edge case**: se il discriminante non è literal o è opzionale, il narrowing non funziona.

### Snippet

```typescript
type Result<T> =
  | { ok: true; data: T }
  | { ok: false; error: string };

function handle<T>(r: Result<T>): T {
  if (r.ok) return r.data;  // r.data accessibile
  throw new Error(r.error);  // r.error accessibile
}
```

### Errori comuni da evitare
- Usare `boolean` generico invece di literal `true` | `false` come discriminante.
- Omettere il discriminante in una delle varianti della union.

---

## Generics

### Domanda
Perché usare generics? Quando servono i vincoli con `extends`?

### Risposta breve
I generics rendono funzioni e tipi riusabili mantenendo la type safety. I vincoli (`extends`) impongono requisiti minimi sul tipo parametrico.

### Spiegazione estesa
Senza generics si duplica codice o si perde precisione con `any`. Con generics il tipo "fluisce" dall'input all'output. I vincoli limitano i tipi ammessi e abilitano l'accesso a proprietà o metodi specifici.

**Edge case**: vincoli troppo larghi annullano i benefici; vincoli troppo stretti riducono la riusabilità.

### Snippet

```typescript
function getId<T extends { id: string }>(v: T): string {
  return v.id;
}

// generics su classi e tipi
type ApiResult<T> = { ok: true; data: T } | { ok: false; error: string };
```

### Errori comuni da evitare
- Usare generics quando un tipo concreto basta (evitare over-engineering).
- Vincoli ridondanti che non aggiungono sicurezza.

---

## Utility types

### Domanda
Quando usare gli utility types? Quali sono i più utili?

### Risposta breve
Per derivare tipi da altri senza duplicare definizioni: DTO, input di update, configurazioni parziali.

### Spiegazione estesa
- **Partial&lt;T&gt;**: rende tutte le proprietà opzionali.
- **Required&lt;T&gt;**: rende tutte le proprietà obbligatorie.
- **Pick&lt;T, K&gt;**: seleziona solo le chiavi K da T.
- **Omit&lt;T, K&gt;**: esclude le chiavi K da T.
- **Record&lt;K, V&gt;**: mappa chiavi K a valori V.
- **Readonly&lt;T&gt;**: rende tutte le proprietà readonly.

**Edge case**: `Partial` e `Readonly` sono shallow; non agiscono in profondità sugli oggetti annidati. Per tipi annidati serve un `DeepPartial` custom.

### Snippet

```typescript
type User = { id: string; name: string; role: string };

type UserUpdate = Partial<Pick<User, "name" | "role">>;

type UserById = Record<string, User>;

type ReadonlyUser = Readonly<User>;
```

### Errori comuni da evitare
- Credere che `Partial` renda opzionali anche gli oggetti annidati.
- Creare index su ogni colonna senza criterio (riferito a Record per mappe dinamiche).

---

## Typing vs runtime

### Domanda
TypeScript garantisce la validazione a runtime?

### Risposta breve
No. I tipi spariscono in fase di compilazione; non esiste alcun controllo a runtime.

### Spiegazione estesa
TypeScript è un sistema di tipi statici: il compilatore verifica il codice prima dell'esecuzione, ma il JavaScript risultante non contiene informazioni di tipo. Qualsiasi dato proveniente dall'esterno (JSON, API, input utente) va validato a runtime con librerie come Zod, io-ts o class-validator.

**Edge case**: usare `as User` su `JSON.parse(raw)` senza validazione può causare crash o comportamenti imprevedibili se i dati non rispettano il tipo.

### Snippet

```typescript
type User = { id: string; name: string };

// pericoloso: nessuna validazione
const user = JSON.parse(raw) as User;

// corretto: validazione runtime
const user = UserSchema.parse(JSON.parse(raw));
```

### Errori comuni da evitare
- Confondere type assertion (`as`) con validazione.
- Assumere che dati esterni rispettino i tipi dichiarati.

---

## readonly e immutabilità

### Domanda
Come usare `readonly`? Quali vantaggi offre?

### Risposta breve
Previene mutazioni accidentali su proprietà o array. Migliora prevedibilità e facilita il ragionamento sul flusso dati.

### Spiegazione estesa
`readonly` può essere applicato a proprietà di interfacce/tipi o a array (`ReadonlyArray<T>`). Il compilatore blocca riassegnazioni e mutazioni dirette (es. `push` su `ReadonlyArray`). Utile per dati condivisi, stato immutabile e pattern funzionali.

**Edge case**: `readonly` è shallow; non protegge oggetti o array annidati dalla mutazione.

### Snippet

```typescript
type User = { readonly id: string; name: string };

const ids: ReadonlyArray<string> = ["a", "b"];
// ids.push("c");  // errore di compilazione
```

### Errori comuni da evitare
- Pensare che `readonly` blocchi mutazioni profonde.
- Usare `readonly` su dati che devono essere effettivamente mutati.

---

## unknown vs any

### Domanda
Quando usare `unknown` invece di `any`?

### Risposta breve
`unknown` obbliga a validare o fare narrowing prima dell'uso; `any` disattiva la type safety e permette qualsiasi operazione.

### Spiegazione estesa
- **any**: opt-out totale. Puoi chiamare metodi, accedere proprietà, assegnare a qualsiasi tipo senza errori. Pericoloso perché gli errori si propagano silenziosamente.
- **unknown**: tipo sicuro per "valore di tipo sconosciuto". Non puoi usare il valore senza prima fare `typeof`, `instanceof` o type guard. Ideale per boundary: JSON, API esterne, input utente.

**Criterio**: preferisci sempre `unknown` quando il tipo non è noto; usa `any` solo come ultima risorsa (es. integrazione con librerie non tipizzate).

### Snippet

```typescript
function parse(input: unknown): string {
  if (typeof input === "string") return input.toUpperCase();
  if (typeof input === "number") return String(input);
  return "";
}

// any: nessun controllo
function dangerous(x: any) {
  return x.foo.bar();  // compila, può crashare a runtime
}
```

### Errori comuni da evitare
- Propagare `any` su tutta la codebase.
- Usare `any` per "sbrigarsi" invece di modellare correttamente il tipo.

---

## Type narrowing e type guard

### Domanda
Come funziona il narrowing e quando usare una type guard personalizzata?

### Risposta breve
Il compilatore restringe il tipo dopo check (`typeof`, `instanceof`, confronti). Le type guard (`x is T`) permettono di incapsulare logica di validazione riusabile.

### Spiegazione estesa
Il narrowing avviene con controlli built-in (`typeof`, `instanceof`, `in`, confronti con literal) o con funzioni che ritornano `x is T`. Le type guard sono utili per union di oggetti con strutture diverse, dove un check superficiale non basta.

**Edge case**: type guard che non valida davvero la struttura espongono a bug a runtime; la guard deve essere affidabile.

### Snippet

```typescript
function isUser(v: unknown): v is { id: string; name: string } {
  return (
    typeof v === "object" &&
    v !== null &&
    "id" in v &&
    typeof (v as { id: unknown }).id === "string"
  );
}
```

### Errori comuni da evitare
- Type guard che ritornano `true` senza validare la struttura.
- Check su campi opzionali che lasciano il tipo ancora ambiguo.

---

## never

### Domanda
Cosa indica il tipo `never`?

### Risposta breve
Rappresenta valori che non esistono mai: funzioni che non ritornano (throw), rami inaccessibili, switch esaustivi.

### Spiegazione estesa
`never` è il sottotipo di ogni tipo. Viene usato per segnalare codice morto o per forzare l'exhaustiveness check negli switch: se aggiungi una nuova variante a una union e dimentichi di gestirla, l'assegnazione a `never` fallisce e il compilatore segnala l'errore.

### Snippet

```typescript
function assertNever(x: never): never {
  throw new Error(`Unexpected value: ${x}`);
}

type Status = "a" | "b";
function handle(s: Status) {
  switch (s) {
    case "a": return 1;
    case "b": return 2;
    default: return assertNever(s);  // errore se aggiungi "c" a Status
  }
}
```

### Errori comuni da evitare
- Ignorare warning di non esaustività negli switch.
- Usare `never` come tipo di ritorno per funzioni che in realtà ritornano.

---

## Template literal types

### Domanda
A cosa servono i template literal types e quando usarli?

### Risposta breve
Permettono di costruire tipi stringa da literal e da altri tipi, combinando stringhe in modo type-safe (es. route, API path, messaggi).

### Spiegazione estesa
La sintassi `` `...${T}...` `` con un tipo `T` che estende `string | number | boolean | bigint` produce un tipo stringa. Utile per route (`/users/${id}`), chiavi derivate, event names. Si combinano con union per generare tutte le varianti.

### Snippet

```typescript
type EventName = "click" | "scroll";
type Handler = `on${Capitalize<EventName>}`;  // "onClick" | "onScroll"

type ApiRoute = "users" | "posts";
type Path = `/${ApiRoute}/${string}`;  // "/users/..." | "/posts/..."
```

### Errori comuni da evitare
- Usare template literal types con tipi non primitivi (non stringifiable).
- Creare union esplosive con troppe varianti.

---

## Mapped types e keyof

### Domanda
Come usare `keyof` e mapped types per derivare tipi da oggetti esistenti?

### Risposta breve
`keyof T` è l'union delle chiavi di `T`. I mapped types `{ [K in keyof T]: ... }` iterano sulle chiavi e producono un nuovo tipo (es. tutte optional, tutte readonly).

### Spiegazione estesa
`keyof` è utile per tipi generici che accettano solo chiavi valide. I mapped types permettono di trasformare ogni proprietà (Partial, Required, Pick sono implementati così). Con `as` in mapped types (TS 4.1+) si può filtrare o rinominare chiavi.

### Snippet

```typescript
type User = { id: string; name: string; role: string };
type UserKeys = keyof User;  // "id" | "name" | "role"

type Nullable<T> = { [K in keyof T]: T[K] | null };
type ReadonlyUser = { readonly [K in keyof User]: User[K] };
```

### Errori comuni da evitare
- Confondere `keyof` con l'oggetto stesso; keyof restituisce un tipo union di stringhe.
- Mapped type su union: il risultato è l'union dei mapped su ogni membro.

---

## Conditional types (basics)

### Domanda
A cosa servono i conditional types e quando usarli?

### Risposta breve
La forma `T extends U ? X : Y` seleziona il tipo `X` o `Y` in base al fatto che `T` sia assegnabile a `U`; utile per tipi che dipendono da un parametro generico.

### Spiegazione estesa
Usati nelle utility types (Exclude, Extract, NonNullable) e per overload di funzioni complesse. Si possono annidare per logica più articolata. Infer con `infer` per estrarre un tipo da un altro (es. tipo di ritorno di una funzione).

### Snippet

```typescript
type IsString<T> = T extends string ? true : false;
type A = IsString<"hi">;   // true
type B = IsString<number>; // false

type ReturnType<T> = T extends (...args: unknown[]) => infer R ? R : never;
```

### Errori comuni da evitare
- Conditional type con union: si distribuisce sui membri (distributive conditional type); usare tuple per evitare distribuzione se serve.
- Conditional troppo profondi che rendono l'errore del compilatore illeggibile.

---

## Const assertions e inferenza letterale

### Domanda
Cosa fa `as const` e quando usarlo?

### Risposta breve
`as const` fa sì che TypeScript inferisca il tipo più stretto possibile: literal invece di string/number, readonly per array e oggetti.

### Spiegazione estesa
Senza `as const`, un array è inferito come `string[]`; con `as const` diventa readonly tuple di literal. Utile per configurazioni, route, union di stringhe senza dichiararle esplicitamente.

### Snippet

```typescript
const routes = ["/", "/users", "/admin"] as const;
type Route = typeof routes[number];  // "/" | "/users" | "/admin"

const config = { port: 3000, env: "prod" } as const;
// config.port è 3000, non number; config.env è "prod"
```

### Errori comuni da evitare
- Usare `as const` su oggetti che devono essere mutati in seguito.
- Dimenticare che gli oggetti diventano readonly e le proprietà non sono più assegnabili.

---

## Branded types

### Domanda
Come distinguere tipi strutturalmente uguali (es. UserId vs OrderId)?

### Risposta breve
Si aggiunge una proprietà "marca" (brand) opzionale e non utilizzata a runtime; il tipo diventa nominalmente diverso pur restando strutturale; si usano type assertion per creare valori "marcati".

### Spiegazione estesa
TypeScript è structural: due tipi con la stessa forma sono compatibili. Per evitare di passare un id sbagliato (UserId dove serve OrderId) si usa un branded type: una intersection con `{ readonly __brand: "UserId" }`. A runtime non si assegna nulla a __brand; è solo per il compilatore.

### Snippet

```typescript
type UserId = string & { readonly __brand: "UserId" };
type OrderId = string & { readonly __brand: "OrderId" };
function getOrder(id: OrderId) { /* ... */ }
const uid = "u1" as UserId;
getOrder(uid);  // errore: UserId non assegnabile a OrderId
```

### Errori comuni da evitare
- Creare branded type senza documentare che il valore va creato con assertion.
- Usare branded types dove la distinzione non porta valore (over-engineering).

---

## Decoratori (experimental)

### Domanda
Cosa sono i decoratori TypeScript e quando usarli?

### Risposta breve
Decoratori sono funzioni che annotano classi, metodi, proprietà o parametri; attualmente richiedono `experimentalDecorators` in tsconfig; lo standard ECMAScript è in evoluzione.

### Spiegazione estesa
Angular usa decoratori (@Component, @Injectable). In TS sono sperimentali: si applicano a runtime (o in fase di build con emitDecoratorMetadata). Limitazioni: non cambiano la forma del tipo; i parametri richiedono `emitDecoratorMetadata` per preservare i tipi nei metadata. Evitare logica pesante nel decorator; preferire funzioni esplicite quando non si usa un framework che li richiede.

### Snippet

```typescript
function Log(target: unknown, key: string, desc: PropertyDescriptor) {
  const fn = desc.value;
  desc.value = function (...args: unknown[]) {
    console.log(key, args);
    return fn.apply(this, args);
  };
}
class C { @Log foo() {} }
```

### Errori comuni da evitare
- Affidarsi ai decoratori per tipi o validazione a runtime senza librerie dedicate (es. class-validator).
- Usare decoratori in progetti che non li richiedono (Angular sì, React/Vue spesso no).

---

## Configurazione tsconfig

### Domanda
Quali opzioni tsconfig sono rilevanti per build e type checking?

### Risposta breve
`target` (ES output), `module` (CommonJS/ESNext), `strict` (famiglia di check rigorosi), `paths` (alias), `skipLibCheck`, `noEmit` (solo check). Scelte diverse impattano compatibilità e bundle size.

### Spiegazione estesa
- **target**: ES5/ES2015/ESNext; più basso = più compatibilità, più polyfill.
- **module**: determina come vengono emessi import/export; ESNext per bundler, CommonJS per Node diretto.
- **strict**: include strictNullChecks, noImplicitAny, strictFunctionTypes; in enterprise è consigliato per ridurre bug.
- **paths**: mappano alias (es. `@/components`) a percorsi; il bundler deve supportarli (es. vite/webpack).
- **skipLibCheck**: salta il check dei .d.ts delle dipendenze; accelera la build, nasconde errori nelle librerie.

### Snippet

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "strict": true,
    "paths": { "@/*": ["./src/*"] },
    "noEmit": true
  },
  "include": ["src"]
}
```

### Errori comuni da evitare
- Disabilitare `strict` per "sistemare dopo"; accumula debito tecnico.
- paths senza configurazione corrispondente nel bundler (build fallisce a runtime).

## In sintesi

- Type inference: il compilatore inferisce tipi da contesto; annotare quando serve documentazione o limitare tipi.
- `interface` estendibile; `type` per union/intersection e mapped types; in pratica spesso intercambiabili.
- Union e intersection: union = A | B (uno dei due); intersection = A & B (entrambi); discriminated union con literal per narrowing.
- Generics: riuso type-safe; constraint con `extends`; evitare `any`, preferire `unknown` e type guard.
- Utility types: `Partial`, `Required`, `Pick`, `Omit`, `Record`; `never` per exhaustiveness check.
- Template literal types e mapped types: costruire tipi da stringhe e da chiavi di oggetti; conditional types per logica dipendente da generics.
- `as const` per literal e readonly; branded types per distinguere tipi strutturalmente uguali.
- Decoratori: sperimentali, usati da Angular; tsconfig: target, module, strict, paths.

## Vedi anche

- [JavaScript](javascript.md) — Base su cui TypeScript aggiunge i tipi.
- [Angular](angular.md) e [React](react.md) — Framework che usano TypeScript.
