# React

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Componenti](#componenti)
- [Hooks](#hooks)
- [State management](#state-management)
- [Virtual DOM e reconciliation](#virtual-dom-e-reconciliation)
- [useMemo e useCallback](#usememo-e-usecallback)
- [Testing](#testing)
- [SSR e Next.js](#ssr-e-nextjs)

## Panoramica

React è una libreria per costruire interfacce utente basata su componenti e stato dichiarativo. A differenza di Angular (framework full-stack), React si occupa principalmente della view: routing, HTTP e state globale sono delegati a librerie esterne. È molto richiesto per ruoli full-stack e FE, spesso in abbinamento a TypeScript e a un backend Node o altro stack.

---

## Componenti

### Componente funzione vs classe: quando usare quale

- **Domanda**: Si usano ancora i componenti a classe?
- **Risposta breve**: I componenti funzionali con hooks sono lo standard; le classi restano per codice legacy o casi molto specifici.
- **Spiegazione estesa**: React raccomanda i function component: meno boilerplate, hooks solo nelle funzioni, migliore tree-shaking. I class component espongono lifecycle (`componentDidMount`, ecc.) e `this.state`; con i hooks si ottiene lo stesso risultato in modo più composabile.
- **Snippet**:

```tsx
// Preferito: function component
function Welcome({ name }: { name: string }) {
  return <h1>Ciao, {name}</h1>;
}

// Con stato: hooks
function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

- **Errori comuni da evitare**: Mescolare logica pesante nel return; non tipizzare le props in TypeScript.

### Props e composizione

- **Domanda**: Come passare dati e figli in React?
- **Risposta breve**: Tramite `props` (attributi e `children`); la composizione si fa incapsulando componenti in altri componenti o con slot espliciti (props che accettano JSX).
- **Spiegazione estesa**: Le props sono read-only. `children` è la prop speciale per il contenuto tra i tag. Per layout flessibili si usano props che accettano elementi (es. `header`, `footer`) invece di un solo `children`.
- **Snippet**:

```tsx
function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="card">
      <h2>{title}</h2>
      {children}
    </div>
  );
}
```

- **Errori comuni da evitare**: Mutare le props nel figlio; usare troppi livelli di prop drilling (meglio Context o state management).

### Controlled vs uncontrolled

- **Domanda**: Differenza tra controlled e uncontrolled component?
- **Risposta breve**: Controlled: il valore dell’input è guidato dallo stato React (`value` + `onChange`). Uncontrolled: il valore vive nel DOM, si legge con `ref`.
- **Spiegazione estesa**: Controlled dà un’unica fonte di verità e validazione in tempo reale; uncontrolled è più semplice per form molto grandi o integrazioni con librerie che gestiscono il DOM. Per form standard e accessibilità preferire controlled.
- **Snippet**:

```tsx
// Controlled
const [text, setText] = useState("");
<input value={text} onChange={e => setText(e.target.value)} />;

// Uncontrolled
const inputRef = useRef<HTMLInputElement>(null);
<input ref={inputRef} defaultValue="" />;
// valore: inputRef.current?.value
```

- **Errori comuni da evitare**: Mescolare `value` e `defaultValue` sullo stesso input; dimenticare `onChange` in controlled (l’input diventa read-only).

---

### Error boundaries
- **Domanda**: Cos'è un Error Boundary e quando usarlo?
- **Risposta breve**: Un Error Boundary è un componente a classe che implementa `static getDerivedStateFromError` e/o `componentDidCatch`; cattura errori nel subtree di rendering e mostra una UI di fallback invece di far cadere l'intera app.
- **Spiegazione estesa**: Non cattura errori in event handler, async, SSR o dentro l'Error Boundary stesso. Si posiziona a livelli strategici (route, feature) per contenere i failure. In React 19+ è previsto supporto per function component (cenni).
- **Snippet**:
```tsx
class ErrorBoundary extends React.Component<Props, { hasError: boolean }> {
  state = { hasError: false };
  static getDerivedStateFromError() { return { hasError: true }; }
  componentDidCatch(err, info) { logError(err, info); }
  render() {
    if (this.state.hasError) return <Fallback />;
    return this.props.children;
  }
}
```
- **Errori comuni da evitare**: Pensare che catturi errori in onClick o useEffect; mettere un solo boundary per tutta l'app.

### Portals
- **Domanda**: A cosa servono i Portals?
- **Risposta breve**: `ReactDOM.createPortal(children, container)` renderizza i figli in un nodo DOM fuori dalla gerarchia del componente (es. modal, tooltip, layer fuori da overflow hidden).
- **Spiegazione estesa**: Il comportamento React (eventi, context) resta nella gerarchia dei componenti; solo il DOM è attaccato altrove. Utile per modali, dropdown e overlay che devono uscire da z-index/overflow del parent.
- **Snippet**:
```tsx
function Modal({ children }) {
  return createPortal(children, document.getElementById("modal-root")!);
}
```
- **Errori comuni da evitare**: Dimenticare di gestire focus e click-outside per l'accessibilità; container non montato (null) causa fallback al render nel parent.

### Compound components e render props
- **Domanda**: Quando usare compound components o render props?
- **Risposta breve**: Compound components: un componente padre che gestisce stato e figli che condividono contesto (es. Tabs + TabList + Tab + TabPanel). Render props: il padre riceve una funzione `(data) => JSX` per rendere con dati derivati.
- **Spiegazione estesa**: Entrambi favoriscono API dichiarative e riuso. Compound components riducono prop drilling tramite Context; render props espongono dati calcolati senza esporre lo stato. Scelta in base a preferenza di markup (compound) vs flessibilità di rendering (render props).
- **Snippet**:
```tsx
<Tabs defaultValue="1">
  <TabList><Tab value="1">Uno</Tab><Tab value="2">Due</Tab></TabList>
  <TabPanel value="1">Contenuto 1</TabPanel>
</Tabs>
// Render props
<DataFetcher url="/api/users">{({ data, loading }) => loading ? <Spinner /> : <List data={data} />}</DataFetcher>
```
- **Errori comuni da evitare**: Compound components senza Context condiviso; render props che ricevono troppi argomenti (meglio un oggetto).

---

## Hooks

### useState: updater function e lazy init

- **Domanda**: Perché usare la forma funzionale di setState?
- **Risposta breve**: Per aggiornamenti basati sul valore precedente si usa `setState(prev => newValue)` per evitare stale closure.
- **Spiegazione estesa**: In eventi asincroni o batch, lo stato “corrente” in closure può essere obsoleto. La updater function riceve l’ultimo stato e restituisce il prossimo. Lazy init: `useState(() => computeInitial())` evita di ricalcolare il valore iniziale a ogni render.
- **Snippet**:

```tsx
const [count, setCount] = useState(0);
setCount(c => c + 1); // sicuro anche con updates concorrenti

const [state, setState] = useState(() => expensiveInit());
```

- **Errori comuni da evitare**: Usare `setCount(count + 1)` dentro timeout o effetti dove `count` può essere stale; mutare lo stato in luogo invece di restituire un nuovo oggetto/array.

### useEffect: dipendenze e cleanup

- **Domanda**: Quando si esegue useEffect e a cosa serve il cleanup?
- **Risposta breve**: Si esegue dopo il commit del render; le dipendenze (array) controllano quando ri-eseguirlo. Il cleanup (funzione restituita) viene eseguito prima del re-run e allo unmount.
- **Spiegazione estesa**: Senza array di dipendenze l’effetto gira dopo ogni render; con `[]` solo al mount. Il cleanup serve per annullare subscription, timer o listener per evitare memory leak e aggiornamenti su componenti smontati.
- **Snippet**:

```tsx
useEffect(() => {
  const id = setInterval(() => tick(), 1000);
  return () => clearInterval(id);
}, []);

useEffect(() => {
  const sub = api.subscribe(onData);
  return () => sub.unsubscribe();
}, [api]);
```

- **Errori comuni da evitare**: Omettere dipendenze usate nell’effetto (o usare eslint exhaustive-deps); dimenticare il cleanup per subscription/timer; fare side effect pesanti senza dipendenze corrette.

### useContext: consumo e prop drilling

- **Domanda**: Quando usare useContext?
- **Risposta breve**: Per condividere dati “globali” per un sottoalbero (tema, utente, lingua) senza passare props a ogni livello.
- **Spiegazione estesa**: Si crea un context con `createContext`, si fornisce con `<Context.Provider value={...}>` e si consuma con `useContext(Context)`. Ogni volta che `value` cambia, tutti i consumer si ri-renderizzano; per valori diversi (es. stato + setter) può essere utile splittare context o usare state management esterno.
- **Snippet**:

```tsx
const ThemeContext = createContext<"light" | "dark">("light");
function App() {
  const [theme, setTheme] = useState("light");
  return (
    <ThemeContext.Provider value={theme}>
      <Page />
    </ThemeContext.Provider>
  );
}
function Page() {
  const theme = useContext(ThemeContext);
  return <div className={theme}>...</div>;
}
```

- **Errori comuni da evitare**: Mettere un oggetto inline in `value` (crea nuovo riferimento a ogni render e ri-renderizza tutti i consumer); usare Context per dati che cambiano spesso e sono usati da molti componenti (valutare Redux/Zustand).

### Regole degli hooks

- **Domanda**: Quali sono le regole degli hooks?
- **Risposta breve**: Chiamare gli hooks solo al top level (no loop, condizione, funzioni annidate) e solo da componenti React o custom hooks.
- **Spiegazione estesa**: React si affida all’ordine di invocazione degli hooks per associare stato ed effetti al componente. Chiamarli in modo condizionale rompe quell’ordine e porta a bug. Stessa cosa per i custom hook: devono chiamare altri hooks in modo incondizionato.
- **Errori comuni da evitare**: `if (x) useState(0)`; chiamare hooks dentro `useEffect` o callback; creare hook che non chiamano altri hook ma si chiamano “use…” (confusione).

---

## State management

### Context vs Redux vs Zustand

- **Domanda**: Quando basta Context e quando serve Redux (o Zustand)?
- **Risposta breve**: Context per pochi valori che cambiano raramente (tema, locale, utente). Redux/Zustand per stato globale complesso, aggiornamenti frequenti o logica di update centralizzata.
- **Spiegazione estesa**: Context non è un “state manager”: ogni cambio di value ri-renderizza tutti i consumer. Redux (azioni, reducer, store) centralizza lo stato e gli update; Zustand offre un’API più semplice con meno boilerplate. Scelta in base a dimensione app, bisogno di DevTools, middleware (logging, persist).
- **Snippet** (Zustand minimo):

```tsx
import { create } from "zustand";
const useStore = create((set) => ({
  count: 0,
  inc: () => set((s) => ({ count: s.count + 1 })),
}));
// in componente: const { count, inc } = useStore();
```

- **Errori comuni da evitare**: Usare Context per tutto lo stato dell’app; introdurre Redux “per moda” in app piccole.

### Redux: azioni, reducer, store

- **Domanda**: Come è strutturato Redux?
- **Risposta breve**: Lo stato è in un unico store; le modifiche avvengono tramite azioni (plain object) e reducer (funzioni pure che ritornano il nuovo stato). I componenti si connettono con `useSelector` e `useDispatch`.
- **Spiegazione estesa**: Unidirectional data flow: dispatch(action) → reducer → new state → subscribe. I reducer non devono mutare lo stato né avere side effect; le side effect si gestiscono con middleware (es. redux-thunk, redux-saga).
- **Errori comuni da evitare**: Mutare lo stato nel reducer; mettere dati non serializzabili nello store.

---

## Virtual DOM e reconciliation

### Cos’è il Virtual DOM e come funziona la reconciliation

- **Domanda**: A cosa serve il Virtual DOM?
- **Risposta breve**: È una rappresentazione in memoria del DOM; React la confronta (reconciliation) con la precedente e aggiorna il DOM reale solo dove serve, riducendo i costi delle operazioni dirette sul DOM.
- **Spiegazione estesa**: A ogni render React costruisce un tree di elementi (Virtual DOM); il reconciler confronta con il tree precedente (diffing) e applica solo le differenze. La “key” sugli elementi in liste aiuta React a capire quali nodi sono stati aggiunti/rimossi/riordinati invece di trattare tutto come sostituzione.
- **Snippet**:

```tsx
{items.map((item) => (
  <ListItem key={item.id} data={item} />
))}
```

- **Errori comuni da evitare**: Usare l’indice come `key` quando la lista è dinamica (riordino, inserimenti); usare `key` non stabili che cambiano a ogni render.

### Quando React ri-renderizza

- **Domanda**: In quali casi un componente si ri-renderizza?
- **Risposta breve**: Quando cambiano le sue props, il suo stato, o il contesto che consuma; oppure quando si ri-renderizza il parent (a meno che non si ottimizzi con memo/useMemo).
- **Spiegazione estesa**: Il setState (e l’update del context value) causano re-render del componente e di tutti i figli. I figli possono essere “salvati” dal re-render con `React.memo` se le props sono uguali (riferimento); per callback come props servono `useCallback` per evitare riferimenti sempre nuovi.

---

## useMemo e useCallback

### useMemo: quando usarlo

- **Domanda**: A cosa serve useMemo e quando ha senso?
- **Risposta breve**: Memorizza il risultato di un calcolo costoso; il calcolo viene rieseguito solo quando cambiano le dipendenze nell’array.
- **Spiegazione estesa**: Utile per derivazioni pesanti (filtri, sort, aggregazioni) che dipendono da props/state. Non usarlo per ogni calcolo: il confronto delle dipendenze e la memorizzazione hanno un costo; usarlo solo quando il calcolo è misurabilmente costoso.
- **Snippet**:

```tsx
const sorted = useMemo(
  () => [...items].sort((a, b) => a.name.localeCompare(b.name)),
  [items]
);
```

- **Errori comuni da evitare**: Usare useMemo ovunque “per sicurezza”; dipendenze sbagliate (manca una variabile usata nel calcolo).

### useCallback: referenza stabile per callback

- **Domanda**: Perché useCallback?
- **Risposta breve**: Restituisce una funzione con referenza stabile tra i render, utile quando la funzione è passata come prop a figli memoizzati o è dipendenza di useEffect.
- **Spiegazione estesa**: A ogni render una funzione definita inline è una nuova referenza; un figlio avvolto in `React.memo` si ri-renderizza comunque perché la prop “funzione” è cambiata. useCallback(fn, deps) restituisce la stessa referenza finché deps non cambiano.
- **Snippet**:

```tsx
const onSave = useCallback(() => {
  api.save(data);
}, [data]);
return <Form onSave={onSave} />;
```

- **Errori comuni da evitare**: Usare useCallback per ogni callback; dimenticare dipendenze (la closure diventa stale).

### useRef e useImperativeHandle
- **Domanda**: Quando usare useRef e useImperativeHandle?
- **Risposta breve**: `useRef` tiene un valore mutabile che non causa re-render; si usa per riferimento a nodo DOM o per tenere istanze/valori tra i render. `useImperativeHandle` espone un'API imperativa custom dal componente figlio al parent tramite ref.
- **Spiegazione estesa**: ref su DOM: accesso a focus, misurazioni, integrazioni con librerie. useImperativeHandle: il figlio dichiara `forwardRef` e `useImperativeHandle(ref, () => ({ focus, scroll }))`; il parent può chiamare `childRef.current.focus()`. Utile per nascondere dettagli DOM e esporre solo metodi necessari.
- **Snippet**:
```tsx
const inputRef = useRef<HTMLInputElement>(null);
useEffect(() => { inputRef.current?.focus(); }, []);

const FancyInput = forwardRef((props, ref) => {
  const innerRef = useRef<HTMLInputElement>(null);
  useImperativeHandle(ref, () => ({ focus: () => innerRef.current?.focus() }));
  return <input ref={innerRef} />;
});
```
- **Errori comuni da evitare**: Mutare ref.current durante il render; usare useImperativeHandle per sostituire completamente props/state (preferire dichiarativo).

### Code splitting e React.lazy
- **Domanda**: Come fare code splitting in React?
- **Risposta breve**: `React.lazy(() => import('./Component'))` carica il componente solo quando viene renderizzato; va usato con `<Suspense fallback={...}>` per mostrare un placeholder durante il caricamento.
- **Spiegazione estesa**: Riduce il bundle iniziale; le route secondarie sono candidate ideali. Il dynamic import ritorna una Promise del modulo; React sospende il render fino al resolve. Preload: si può preloadare con `import()` in anticipo (es. on hover del link).
- **Snippet**:
```tsx
const Admin = React.lazy(() => import("./Admin"));
<Suspense fallback={<Spinner />}>
  <Admin />
</Suspense>
```
- **Errori comuni da evitare**: Lazy senza Suspense (errore in React 18); fallback assente o troppo pesante.

### Concurrent features (cenni)
- **Domanda**: Cosa sono useTransition e useDeferredValue?
- **Risposta breve**: `useTransition` segna aggiornamenti di stato come non urgenti (React può interrompere il render e mostrare prima aggiornamenti urgenti). `useDeferredValue` ritarda la “versione” di un valore per dare priorità ad altri aggiornamenti.
- **Spiegazione estesa**: Utili per UI che risponde subito (es. input) mentre liste o filtri pesanti si aggiornano in secondo piano. Riduce jank su dispositivi lenti. Sono parti del Concurrent Rendering di React 18+.
- **Snippet**:
```tsx
const [isPending, startTransition] = useTransition();
const deferredQuery = useDeferredValue(query);
startTransition(() => setSearchQuery(input));
// isPending per mostrare indicatore; deferredQuery per filtrare lista
```
- **Errori comuni da evitare**: Usare transition per ogni setState (solo per update costosi); aspettarsi che useDeferredValue blocchi il valore (è un hint, non una garanzia temporale).

---

## Testing

### React Testing Library: filosofia e uso

- **Domanda**: Come si testano i componenti React con RTL?
- **Risposta breve**: Si testa il comportamento dall’ottica dell’utente: render, query sul DOM (getByRole, getByLabelText), fireEvent o userEvent, assert su risultato. Evitare di testare i dettagli implementativi.
- **Spiegazione estesa**: RTL incoraggia query accessibili (role, label) e interazioni realistiche. Jest fornisce il runner e expect; RTL fornisce render, screen, waitFor. Per chiamate async (fetch) si usano mock o MSW.
- **Snippet**:

```tsx
import { render, screen, fireEvent } from "@testing-library/react";
import UserForm from "./UserForm";

test("submits form with name", async () => {
  render(<UserForm onSubmit={jest.fn()} />);
  fireEvent.change(screen.getByLabelText(/nome/i), { target: { value: "Mario" } });
  fireEvent.click(screen.getByRole("button", { name: /invia/i }));
  await waitFor(() => {
    expect(screen.getByText(/grazie/)).toBeInTheDocument();
  });
});
```

- **Errori comuni da evitare**: Testare lo stato interno o i hook in isolamento invece del risultato visibile; usare getByTestId come prima scelta (preferire role/label).

---

## SSR e Next.js

### Cos’è SSR e quando usarlo

- **Domanda**: Differenza tra CSR e SSR?
- **Risposta breve**: CSR (Client-Side Rendering): il browser scarica JS e React renderizza tutto lato client. SSR: il server restituisce HTML già renderizzato per il primo paint e SEO; poi React “idrata” la pagina lato client.
- **Spiegazione estesa**: SSR migliora perceived performance e indicizzazione; è utile per contenuti pubblici e SEO. Next.js offre SSR (getServerSideProps nelle Pages, o Server Components nell’App Router), SSG (getStaticProps / generateStaticParams) e route API. Scelta in base a dinamicità dei dati e necessità di SEO.
- **Errori comuni da evitare**: Usare SSR per dashboard interne dove il contenuto è tutto dietro login; non gestire correttamente idratazione (mismatch server/client su date o window).

### Next.js: cenni su App Router e data fetching

- **Domanda**: Come si caricano i dati in Next.js?
- **Risposta breve**: Nelle Pages: getServerSideProps (SSR), getStaticProps (SSG). Nell’App Router: Server Components fetch di default sul server; Client Components con useEffect o librerie (SWR, React Query).
- **Spiegazione estesa**: L’App Router (Next 13+) distingue Server e Client Components; i Server Components possono fare fetch e accedere a DB/API senza esporre dati al client. Per dati che dipendono da interazione utente si usano Client Components e fetch lato client con cache.
- **Errori comuni da evitare**: Chiamare API di backend da Server Component con URL assoluto interno (usare variabili d’ambiente e host corretti); mescolare logica client (useState, useEffect) in componenti che dovrebbero essere server.

## In sintesi

- Componenti funzionali e dichiarativi; props in ingresso, state locale con useState; evitare mutazione diretta.
- Hooks: useState, useEffect (side effect e cleanup); regole: solo in top-level e da componenti funzionali.
- State management: contesto per dati condivisi; Redux/Zustand per stato globale complesso; evitare prop drilling eccessivo.
- Virtual DOM e reconciliation: diff e update efficiente; key stabile nelle liste; evitare indici come key se la lista cambia ordine.
- useMemo e useCallback: memorizzare calcoli e funzioni per evitare rerender inutili; misurare prima di ottimizzare.
- Error Boundary: cattura errori in rendering, mostra fallback; Portals per render fuori dalla gerarchia DOM.
- useRef/useImperativeHandle: ref per DOM o valore persistente; API imperativa esposta al parent.
- Code splitting: React.lazy + Suspense; useTransition/useDeferredValue per priorità di rendering (Concurrent).
- Compound components e render props: API dichiarative e riuso; SSR/Next.js: primo paint e SEO; Server Components vs Client Components.

## Vedi anche

- [JavaScript](javascript.md) e [TypeScript](typescript.md) — Base del linguaggio.
- [Node.js](nodejs.md) — Runtime e API per full-stack.
