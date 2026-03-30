# Vue.js

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Componenti e Composition API](#componenti-e-composition-api)
- [Reattività: ref e reactive](#reattività-ref-e-reactive)
- [Direttive e template](#direttive-e-template)
- [State e routing (cenni)](#state-e-routing-cenni)
- [Provide/inject e slots](#provideinject-e-slots)
- [Lifecycle e Teleport](#lifecycle-e-teleport)
- [Performance e testing](#performance-e-testing)
- [SSR e Nuxt (cenni)](#ssr-e-nuxt-cenni)
- [Confronto con Angular e React](#confronto-con-angular-e-react)

## Panoramica

Vue.js è un framework progressivo per costruire interfacce utente: core sulla view layer, con ecosistema opzionale (routing, state management, build tool). Vue 3 introduce la Composition API (oltre all’Options API), reattività basata su Proxy e TypeScript. È un’alternativa a Angular e React per ruoli full-stack e FE; la scelta dipende da preferenze di sintassi, dimensione team e integrazione con il backend.

---

## Componenti e Composition API

### Componente single-file (SFC) e Options API

- **Domanda**: Come è strutturato un componente Vue?
- **Risposta breve**: Un file `.vue` contiene template, script e style. Con Options API si definiscono `data`, `methods`, `computed`, `lifecycle hooks` in un oggetto.
- **Spiegazione estesa**: SFC permette di tenere markup, logica e stili nello stesso file. Options API è intuitiva per chi viene da OOP; la Composition API (setup, `ref`/`reactive`) raggruppa la logica per funzionalità e favorisce il riuso (composables).
- **Snippet**:

```vue
<template>
  <div>{{ count }}</div>
  <button @click="increment">+1</button>
</template>
<script>
export default {
  data() {
    return { count: 0 };
  },
  methods: {
    increment() {
      this.count++;
    },
  },
};
</script>
```

- **Errori comuni da evitare**: Mutare props dal figlio; usare `data` come oggetto condiviso tra istanze (deve essere una funzione che restituisce l’oggetto).

### Composition API e setup

- **Domanda**: A cosa serve la Composition API?
- **Risposta breve**: Raggruppa la logica in funzioni e variabili reattive (`ref`, `reactive`) invece che in opzioni sparse; facilita il riuso con composables.
- **Spiegazione estesa**: In `<script setup>` le variabili e le funzioni sono esposte al template. I composables sono funzioni che usano ref/reactive e lifecycle; si riusano tra componenti (analogo agli hooks in React).
- **Snippet**:

```vue
<script setup>
import { ref, onMounted } from "vue";
const count = ref(0);
function increment() {
  count.value++;
}
onMounted(() => console.log("mounted"));
</script>
<template>
  <div>{{ count }}</div>
  <button @click="increment">+1</button>
</template>
```

- **Errori comuni da evitare**: Dimenticare `.value` su `ref` nello script (nel template è unwrapped); usare `reactive` con tipi primitivi (usare `ref` per number/string).

---

## Reattività: ref e reactive

### ref vs reactive

- **Domanda**: Quando usare ref e quando reactive?
- **Risposta breve**: `ref` per qualsiasi valore (primitivi e oggetti); `reactive` solo per oggetti; sostituire un intero oggetto reattivo è più semplice con ref.
- **Spiegazione estesa**: `ref` espone il valore in `.value` nello script; nel template Vue fa unwrap. `reactive` è solo per oggetti; non si può riassegnare l’intero oggetto mantenendo la reattività. Per oggetti che possono essere sostituiti (es. risultato di una fetch) ref è più comodo.
- **Snippet**:

```js
const count = ref(0);
const state = reactive({ name: "", items: [] });
// state = reactive({ ... }) non riassegnabile; meglio ref({ name: "", items: [] })
```

- **Errori comuni da evitare**: Riassegnare una variabile che era `reactive` (si perde reattività); destrutturare reactive senza toRefs (si perde reattività).

### Computed e watch

- **Domanda**: Differenza tra computed e watch?
- **Risposta breve**: `computed` è un valore derivato (cache, si ricalcola quando cambiano le dipendenze); `watch` esegue side effect quando una fonte reattiva cambia.
- **Spiegazione estesa**: Per valori derivati da stato (es. lista filtrata) usare computed; per logica asincrona o side effect (chiamate API, log) usare watch.
- **Snippet**:

```js
const filtered = computed(() => items.value.filter((i) => i.active));
watch(count, (newVal, oldVal) => { /* side effect */ });
```

- **Errori comuni da evitare**: Mutare dati dentro un computed (devono essere puri); usare watch per derivazioni sincrone (preferire computed).

---

## Direttive e template

### Direttive principali

- **Domanda**: Quali direttive Vue usi spesso?
- **Risposta breve**: `v-model` (two-way binding), `v-if` / `v-else` / `v-show`, `v-for` (con key), `v-bind` (`:attr`), `v-on` (`@event`), `v-slot` (slot).
- **Spiegazione estesa**: `v-model` su input/componenti è zucchero per `:value` + `@input`. `v-if` rimuove/aggiunge al DOM; `v-show` toglie solo la visibilità (display). In `v-for` usare sempre una `key` stabile (id), non l’indice se la lista è dinamica.
- **Snippet**:

```vue
<input v-model="name" />
<div v-if="visible">...</div>
<li v-for="item in items" :key="item.id">{{ item.name }}</li>
```

- **Errori comuni da evitare**: Usare indice come key in liste che si riordinano o si modificano; confondere v-if con v-show (costo iniziale vs costo toggle).

---

## State e routing (cenni)

### Pinia (state management)

- **Domanda**: Come si gestisce lo stato globale in Vue 3?
- **Risposta breve**: Pinia è lo store ufficiale raccomandato (sostituisce Vuex per Vue 3); si definiscono store con `defineStore` e si usano nei componenti.
- **Spiegazione estesa**: Store con state, getters e actions; composables-style. Per app piccole può bastare provide/inject o stato condiviso; per stato globale complesso Pinia semplifica il flusso.
- **Errori comuni da evitare**: Usare lo store per stato puramente locale; non tipizzare gli store in TypeScript.

### Vue Router

- **Domanda**: Come si fa il routing in Vue?
- **Risposta breve**: Vue Router: definizione route (path, component), `<router-view>`, `router-link`, guard (beforeEach, beforeEnter) per proteggere route e redirect.
- **Spiegazione estesa**: Route lazy-loaded con `() => import('./View.vue')`; guard per auth (redirect a login se non autenticato); meta campi per titolo o permessi.
- **Errori comuni da evitare**: Non proteggere le route che richiedono autenticazione; dimenticare il fallback (404) e la modalità history (configurare il server per SPA).

---

## Provide/inject e slots

### Provide e inject
- **Domanda**: Quando usare provide/inject invece delle props?
- **Risposta breve**: `provide` nel componente antenato e `inject` nei discendenti permettono di passare dati (o funzioni) senza prop drilling attraverso tutti i livelli intermedi.
- **Spiegazione estesa**: Utile per tema, locale, configurazione o servizi che devono essere disponibili in molti componenti figli. Trade-off: meno esplicito delle props, più difficile tracciare la provenienza; preferire per dati “contesto” piuttosto che per dati che cambiano spesso.
- **Snippet**:
```vue
<!-- parent -->
<script setup>
provide("theme", "dark");
provide("updateTheme", (v) => { ... });
</script>
<!-- child (qualsiasi livello sotto) -->
<script setup>
const theme = inject("theme");
const updateTheme = inject("updateTheme");
</script>
```
- **Errori comuni da evitare**: Inject senza valore di default quando il provide è opzionale (inject può ricevere secondo argomento come default); provide valori non reattivi se servono aggiornamenti (usare ref/reactive).

### Slots (default, named, scoped)
- **Domanda**: Come usare gli slot in Vue?
- **Risposta breve**: Slot default per il contenuto tra i tag del componente; slot nominati con `<template #header>` e `<slot name="header">`; scoped slot espone dati dal figlio al parent tramite `v-slot="props"` (o `#default="props"`).
- **Spiegazione estesa**: Default e named slot per layout (header, footer, body). Scoped slot quando il contenuto proiettato deve dipendere da dati del figlio (es. lista con azioni per riga). Il parent riceve un oggetto (es. `{ item, index }`) e decide come renderizzare.
- **Snippet**:
```vue
<!-- child -->
<slot name="header" />
<slot :item="row" :index="i" />
<!-- parent -->
<MyList>
  <template #header>Titolo</template>
  <template #default="{ item, index }">{{ index }}: {{ item.name }}</template>
</MyList>
```
- **Errori comuni da evitare**: Confondere l’ordine slot default vs named; aspettarsi che lo scoped slot riceva reattività senza passare ref/reactive.

---

## Lifecycle e Teleport

### Lifecycle hooks (Composition API): onMounted, onUnmounted, watch vs watchEffect
- **Domanda**: Quali lifecycle hook usare in Composition API e quando preferire watch a watchEffect?
- **Risposta breve**: `onMounted` per accesso al DOM o side effect dopo il mount; `onUnmounted` per cleanup (listener, timer, subscription). `watch` esegue solo quando le fonti cambiano; `watchEffect` esegue subito e traccia le dipendenze reattive usate al suo interno.
- **Spiegazione estesa**: watch(fn, deps) con optional `{ immediate: true }` per esecuzione iniziale. watchEffect non ha array dipendenze esplicito: qualsiasi ref/reactive letto dentro viene tracciato. Per cleanup si ritorna una funzione da watch o watchEffect. Preferire watch quando le dipendenze sono esplicite e non vuoi esecuzione immediata.
- **Snippet**:
```js
onMounted(() => { chartRef.value?.init(); });
onUnmounted(() => { sub.unsubscribe(); });
watch([count, name], ([newC, newN]) => { fetch(newC, newN); });
watchEffect(() => { console.log(count.value); });
```
- **Errori comuni da evitare**: Accedere al DOM prima di onMounted; dimenticare cleanup in onUnmounted (memory leak).

### Teleport
- **Domanda**: A cosa serve Teleport?
- **Risposta breve**: `<Teleport to="selector">` renderizza i figli in un altro elemento DOM (es. body o un div #modal), mantenendo logica e contesto Vue nel componente che li definisce.
- **Spiegazione estesa**: Come i Portals in React: utile per modali, tooltip, notifiche che devono uscire da overflow/z-index del parent. Gli eventi e provide/inject restano nella gerarchia del componente; solo il DOM è spostato.
- **Snippet**:
```vue
<Teleport to="#modal-root">
  <div class="modal">...</div>
</Teleport>
```
- **Errori comuni da evitare**: Il target deve esistere nel DOM al mount; su SSR il contenuto viene renderizzato nella posizione originale se il target non è disponibile.

---

## Performance e testing

### Performance: v-memo e ottimizzazioni
- **Domanda**: Quando usare v-memo e quali altre ottimizzazioni considerare?
- **Risposta breve**: `v-memo` (Vue 3.2+) memorizza un sotto-albero e lo ri-renderizza solo quando un array di dipendenze cambia; utile per liste grandi con righe costose.
- **Spiegazione estesa**: v-memo accetta un array: se i valori sono uguali (referenza) al render precedente, il blocco viene saltato. Altre ottimizzazioni: key stabile in v-for, computed per valori derivati, shallowRef per oggetti grandi che si sostituiscono per intero, evitare reattività su dati immutabili che non servono in template.
- **Snippet**:
```vue
<div v-for="item in list" :key="item.id" v-memo="[item.id, item.updated]">
  {{ item.name }}
</div>
```
- **Errori comuni da evitare**: v-memo con dipendenze che cambiano sempre (nessun beneficio); over-ottimizzazione senza misurare.

### Testing (Vitest, component testing)
- **Domanda**: Come strutturare i test in Vue (Vitest e component testing)?
- **Risposta breve**: Vitest come runner (compatibile con API Jest); per i componenti si usa @vue/test-utils: mount, wrapper.find, wrapper.emitted, setValue, trigger.
- **Spiegazione estesa**: mount(Component, { props, global: { plugins, stubs } }) crea il wrapper; query con getByRole, findComponent; simulare eventi con trigger. Per testare composables si monta un componente che li usa o si testa la funzione in isolamento con ref reattivi. Mock di provide o router con global.provide e global.mocks.
- **Snippet**:
```js
import { mount } from "@vue/test-utils";
import MyForm from "./MyForm.vue";
test("emits submit with value", async () => {
  const wrapper = mount(MyForm);
  await wrapper.find("input").setValue("test");
  await wrapper.find("form").trigger("submit");
  expect(wrapper.emitted("submit")).toEqual([["test"]]);
});
```
- **Errori comuni da evitare**: Testare dettagli implementativi invece del comportamento; dimenticare await dopo setValue/trigger (aggiornamento reattivo asincrono).

---

## SSR e Nuxt (cenni)

### Quando scegliere SSR con Vue (Nuxt)
- **Domanda**: Quando usare SSR con Vue e cosa offre Nuxt?
- **Risposta breve**: SSR (Server-Side Rendering) restituisce HTML dal server per primo paint e SEO; Nuxt è il framework full-stack su Vue che offre routing, SSR/SSG, data fetching e convenzioni di progetto.
- **Spiegazione estesa**: Utile per siti pubblici, e-commerce, landing. Nuxt 3 con useFetch/useAsyncData per data fetching su server; componenti che usano solo composables e props compatibili con SSR. Limitazioni: niente window/document nel setup senza check (useNuxtApp, import.meta.server); idratazione e mismatch da evitare (stato deterministico).
- **Quando usarlo**: Contenuti indicizzabili, performance first load, app che beneficiano di API e routing integrati.
- **Quando evitarlo**: Dashboard o app dietro login dove CSR basta; quando non si vuole gestire la complessità di deploy e idratazione.
- **Errori comuni da evitare**: Accedere a browser API nel percorso di render server; non gestire loading/error negli useFetch.

---

## Confronto con Angular e React

### Quando scegliere Vue

- **Domanda**: Vue vs Angular vs React?
- **Risposta breve**: Vue: curva dolce, template familiare, Composition API vicina a React hooks; Angular: framework completo, enterprise, TypeScript-first; React: ecosistema enorme, solo view, massima flessibilità.
- **Spiegazione estesa**: Vue è un buon compromesso tra struttura (template, direttive) e flessibilità (Composition API, composables). Angular offre più “batterie incluse” (DI, routing, form, HTTP) e convenzioni forti. React richiede più scelte (routing, state) ma domina in adoption e librerie. La scelta dipende da team, codebase esistente e requisiti (SEO, performance, integrazione backend).
- **Errori comuni da evitare**: Considerare Vue “meno enterprise” di Angular: Vue 3 + TypeScript + Pinia + Router sono adatti a progetti grandi; la differenza è soprattutto di stile e ecosistema.

## In sintesi

- Composition API: setup(), ref, reactive; composables per logica riusabile; Options API ancora supportata.
- Reattività: ref per primitivi, reactive per oggetti; Proxy-based; evitare destructuring che perde reattività.
- Provide/inject per evitare prop drilling; slots (default, named, scoped) per composizione; Teleport per modali/tooltip.
- Lifecycle: onMounted, onUnmounted; watch vs watchEffect per side effect; v-memo per liste costose.
- Testing: Vitest e @vue/test-utils; SSR/Nuxt per SEO e first paint. Direttive: v-if/v-show, v-for (key stabile), v-model; Vue Router e Pinia per routing e state.
- Confronto: Vue compromesso struttura/flessibilità; Angular più completo; React massima flessibilità.

## Vedi anche

- [JavaScript](javascript.md) e [TypeScript](typescript.md) — Base.
- [Angular](angular.md) e [React](react.md) — Confronto framework.
