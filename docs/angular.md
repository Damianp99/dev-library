# Angular

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Lifecycle e Hook](#lifecycle-e-hook)
- [Change Detection e Zone.js](#change-detection-e-zonejs)
- [Input e Output](#input-e-output)
- [Signals e computed](#signals-e-computed)
- [Dependency Injection](#dependency-injection)
- [RxJS](#rxjs)
- [Standalone vs NgModule](#standalone-vs-ngmodule)
- [Routing e Auth Guard](#routing-e-auth-guard)
- [Content projection e query](#content-projection-e-query)
- [Pipe e performance](#pipe-e-performance)
- [Lazy loading e SSR](#lazy-loading-e-ssr)
- [Testing](#testing)
- [HttpClient](#httpclient)
- [Forms](#forms)

## Panoramica
Questa guida raccoglie domande su Angular con risposte sintetiche e pratiche.
Il focus è su SPA enterprise: lifecycle, moduli/standalone e routing sicuro.

!!! tip "Prova a spiegarlo"
    Spiega a voce: quando usare **ngOnInit** e quando **ngOnChanges**, e perché con OnPush la change detection è più efficiente. Poi verifica in [Lifecycle](angular.md#lifecycle-e-hook) e [Change Detection](angular.md#change-detection-e-zonejs).

## Lifecycle e Hook

### `ngOnChanges`

=== "In un colpo d'occhio"
    **Risposta breve**: Si attiva quando cambiano `@Input` e riceve il delta come `SimpleChanges`. Si attiva solo se cambia la **reference**, non per mutazioni in-place.

=== "Dettaglio"
    - **Domanda**: Quando si usa `ngOnChanges` e cosa riceve?
    - **Spiegazione estesa**: È utile per reagire a input esterni senza accedere direttamente al parent. Edge case: si attiva solo se cambia la reference, non per mutazioni in-place di oggetti.
    - **Scelta progettuale**: Preferire input immutabili per rendere `ngOnChanges` affidabile.
    - **Snippet**:

    ```typescript
    ngOnChanges(changes: SimpleChanges) {
      if (changes["user"]) this.loadProfile(changes["user"].currentValue);
    }
    ```
    - **Errori comuni da evitare**: Mutare l'oggetto input e aspettarsi il trigger.

### `ngOnInit`

=== "In un colpo d'occhio"
    **Risposta breve**: Inizializza logica dopo il binding degli input. È il punto giusto per chiamare servizi o inizializzare stream; non usare il constructor per side effect.

=== "Dettaglio"
    - **Domanda**: A cosa serve `ngOnInit`?
    - **Spiegazione estesa**: È il punto giusto per chiamare servizi o inizializzare stream. Edge case: non è chiamato di nuovo su cambi input, quindi non sostituisce `ngOnChanges`.
    - **Scelta progettuale**: Mettere qui la logica di setup, non nel constructor.
    - **Snippet**:

    ```typescript
    ngOnInit() {
      this.data$ = this.service.getData();
    }
    ```
    - **Errori comuni da evitare**: Avviare side effect nel constructor.

### `ngDoCheck`
- **Domanda**: Quando usare `ngDoCheck`?
- **Risposta breve**: Per controlli custom di change detection quando Angular non basta.
- **Spiegazione estesa**: Utile con dati mutabili o integrazioni legacy, ma costoso.
  Edge case: se la logica è pesante, degrada drasticamente le performance.
- **Scelta progettuale**: Usarlo solo con misurazioni e alternative esaurite.
- **Snippet**:
```typescript
ngDoCheck() {
  if (this.prev !== this.model.version) this.syncView();
  this.prev = this.model.version;
}
```
- **Errori comuni da evitare**: Eseguire calcoli complessi ad ogni ciclo.

### `ngAfterContentInit`
- **Domanda**: Cosa segnala `ngAfterContentInit`?
- **Risposta breve**: Che il contenuto proiettato (`ng-content`) è stato inizializzato.
- **Spiegazione estesa**: Serve per leggere query su content projection (`ContentChild`).
  Edge case: si chiama una sola volta, per aggiornamenti usare `ngAfterContentChecked`.
- **Scelta progettuale**: Usarlo per setup di contenuti proiettati, non per update continui.
- **Snippet**:
```typescript
@ContentChild("slot") slot!: ElementRef;
ngAfterContentInit() { this.decorate(this.slot.nativeElement); }
```
- **Errori comuni da evitare**: Aspettarsi che si richiami su ogni cambio.

### `ngAfterContentChecked`
- **Domanda**: Quando entra in gioco `ngAfterContentChecked`?
- **Risposta breve**: Dopo ogni check del contenuto proiettato.
- **Spiegazione estesa**: Utile per validare stato del content, ma può causare loop.
  Edge case: modificare il DOM qui può generare `ExpressionChangedAfterItHasBeenCheckedError`.
- **Scelta progettuale**: Evitare side effect; usare solo per lettura/validazione.
- **Snippet**:
```typescript
ngAfterContentChecked() {
  this.hasProjected = !!this.slot;
}
```
- **Errori comuni da evitare**: Aggiornare lo stato che influenza il template.

### `ngAfterViewInit`
- **Domanda**: A cosa serve `ngAfterViewInit`?
- **Risposta breve**: Indica che la view e le view child sono pronte.
- **Spiegazione estesa**: Punto ideale per accedere a `ViewChild` e librerie DOM.
  Edge case: in SSR o prerendering alcune API DOM non sono disponibili.
- **Scelta progettuale**: Usare per integrazioni DOM, non per fetch dati.
- **Snippet**:
```typescript
@ViewChild("input") input!: ElementRef<HTMLInputElement>;
ngAfterViewInit() { this.input.nativeElement.focus(); }
```
- **Errori comuni da evitare**: Accedere a `ViewChild` prima di questo hook.

### `ngAfterViewChecked`
- **Domanda**: Quando si usa `ngAfterViewChecked`?
- **Risposta breve**: Dopo ogni check della view del componente.
- **Spiegazione estesa**: Utile per verifiche di rendering, ma è costoso.
  Edge case: aggiornare il modello qui può creare cicli infiniti di change detection.
- **Scelta progettuale**: Usarlo solo per letture; preferire `async` pipe e OnPush.
- **Snippet**:
```typescript
ngAfterViewChecked() {
  this.isEmpty = this.listRef.nativeElement.children.length === 0;
}
```
- **Errori comuni da evitare**: Cambiare stato che ritriggerà il render.

### `ngOnDestroy`
- **Domanda**: Perché è importante `ngOnDestroy`?
- **Risposta breve**: Serve a rilasciare risorse e prevenire memory leak.
- **Spiegazione estesa**: In enterprise, gestisce unsubscribe, timer e listener globali.
  Edge case: dimenticare `takeUntil` su stream lunghi porta a leak silenziosi.
- **Scelta progettuale**: Centralizzare la cleanup con `Subject` o `DestroyRef`.
- **Snippet**:
```typescript
private readonly destroy$ = new Subject<void>();
ngOnDestroy() { this.destroy$.next(); this.destroy$.complete(); }
```
- **Errori comuni da evitare**: Non chiudere subscription su servizi esterni.

## Change Detection e Zone.js

### Change Detection: Default vs OnPush
- **Domanda**: Qual è la differenza tra change detection Default e OnPush?
- **Risposta breve**: Default controlla tutto l'albero a ogni evento; OnPush controlla solo quando cambiano input, eventi o Observable con async pipe.
- **Spiegazione estesa**: Default usa Zone.js per intercettare eventi async e triggerare il check su tutto l'albero. OnPush riduce i check verificando solo reference di `@Input`, emissioni di `EventEmitter` e `async` pipe. Edge case: con OnPush, mutazioni in-place di oggetti non attivano il check; serve immutabilità o `ChangeDetectorRef.markForCheck()`.
- **Quando usarlo**: OnPush per componenti leaf, liste grandi, dashboard con molti widget; Default per componenti root o con stato complesso e mutabile.
- **Quando evitarlo**: OnPush se non puoi garantire immutabilità degli input; Default se hai molti componenti e performance critiche.
- **Snippet**:
```typescript
@Component({
  selector: "app-user-list",
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `{{ users().length }} utenti`
})
export class UserListComponent {
  users = input.required<User[]>();
}
```
- **Errori comuni da evitare**: Mutare oggetti con OnPush senza `markForCheck`; usare Default ovunque senza misurare.

### Zone.js
- **Domanda**: A cosa serve Zone.js in Angular?
- **Risposta breve**: Intercetta operazioni async (setTimeout, HTTP, eventi) per triggerare automaticamente la change detection.
- **Spiegazione estesa**: Zone.js "monkey-patcha" le API async del browser. Quando una Promise o un evento si risolve, Angular sa che deve eseguire il check. Edge case: codice fuori da Zone (es. Web Worker, librerie esterne) non triggera il check; serve `NgZone.run()` o `ChangeDetectorRef.detectChanges()`.
- **Quando usarlo**: Default: lasciare Zone attivo per change detection automatica. Con Signals/OnPush può essere ridotto o rimosso (experimental).
- **Quando evitarlo**: Non disabilitare Zone senza migrare a OnPush + Signals o `runOutsideAngular` per operazioni pesanti.
- **Snippet**:
```typescript
constructor(private ngZone: NgZone) {}
heavyWork() {
  this.ngZone.runOutsideAngular(() => {
    // calcoli pesanti senza triggerare CD
    const result = compute();
    this.ngZone.run(() => this.result.set(result));
  });
}
```
- **Errori comuni da evitare**: Eseguire loop lunghi dentro Zone; aspettarsi CD da callback di librerie non patched.

## Input e Output

### `@Input` e comunicazione parent-child
- **Domanda**: Come passa dati un componente parent a un child?
- **Risposta breve**: Tramite `@Input`, che espone una proprietà bindabile dal template parent.
- **Spiegazione estesa**: L'input è one-way: il parent passa valori, il child li riceve in sola lettura.
  Edge case: se passi un oggetto e lo muti nel parent, il child vede il cambio solo se la reference cambia o con OnPush + immutabilità.
- **Quando usarlo**: Dati da parent a child, configurazione di componenti riusabili.
- **Quando evitarlo**: Per stato condiviso bidirezionale, preferire servizi o signals.
- **Snippet**:
```typescript
@Component({ selector: "app-user-card", ... })
export class UserCardComponent {
  @Input() user!: User;
  @Input({ required: true }) title!: string;
}
```
- **Errori comuni da evitare**: Mutare l'oggetto input nel child; dimenticare `required` per input obbligatori.

### `@Output` e EventEmitter
- **Domanda**: Come comunica un child al parent?
- **Risposta breve**: Tramite `@Output` con `EventEmitter`, che emette eventi verso l'alto.
- **Spiegazione estesa**: Il child emette valori; il parent ascolta con `(evento)="handler($event)"`.
  Edge case: `EventEmitter` estende `Subject`; evitare `subscribe` nel child, usare solo `emit()`.
- **Quando usarlo**: Azioni utente (click, submit), conferme, selezione da liste.
- **Quando evitarlo**: Per aggiornamenti frequenti o stato complesso, preferire servizi o signals.
- **Snippet**:
```typescript
@Output() userSelected = new EventEmitter<User>();
onSelect(u: User) { this.userSelected.emit(u); }
```
- **Errori comuni da evitare**: Chiamare `emit` in costruttore o prima del render; usare Output per passare dati verso il basso.

### `model()` e two-way binding
- **Domanda**: Come fare two-way binding con `@Input` e `@Output`?
- **Risposta breve**: Usare `model()` (Angular 17+) che combina input e output con convenzione `prop` / `propChange`.
- **Spiegazione estesa**: Sostituisce il pattern `[(ngModel)]` custom con sintassi dichiarativa.
  Edge case: `model()` richiede Angular 17+; in versioni precedenti usare `@Input` + `@Output` con `propChange`.
- **Quando usarlo**: Form controls custom, toggle, select che devono sincronizzare valore con parent.
- **Quando evitarlo**: Per dati read-only o eventi one-off, usare Input/Output separati.
- **Snippet**:
```typescript
@Component({ ... })
export class ToggleComponent {
  value = model<boolean>(false);
}
// Parent: <app-toggle [(value)]="isOn" />
```
- **Errori comuni da evitare**: Usare `model()` per dati complessi o liste; preferire eventi espliciti.

## Signals e computed

### Cosa sono i Signals
- **Domanda**: Cosa sono i Signals in Angular?
- **Risposta breve**: Primitivi reattivi che contengono un valore e notificano i consumer al cambio.
- **Spiegazione estesa**: Introdotti in Angular 16, migliorano change detection e riducono zone.js.
  Un signal è un getter che ritorna il valore; `set()`/`update()` lo modificano. I consumer si ri-eseguono automaticamente.
- **Quando usarlo**: Stato locale reattivo, integrazione con `computed`, sostituzione di `BehaviorSubject` per stato semplice.
- **Quando evitarlo**: Stream complessi con operatori RxJS; preferire Observable in quel caso.
- **Snippet**:
```typescript
@Component({ ... })
export class CounterComponent {
  count = signal(0);
  increment() { this.count.update(c => c + 1); }
}
// Template: {{ count() }}
```
- **Errori comuni da evitare**: Chiamare `count` senza `()` nel template; mutare oggetti in-place invece di `set`/`update`.

### `computed` e valori derivati
- **Domanda**: A cosa serve `computed`?
- **Risposta breve**: Crea un valore derivato da altri signals, ricalcolato solo quando le dipendenze cambiano.
- **Spiegazione estesa**: `computed` è lazy e memoizzato: esegue la funzione solo quando un signal usato al suo interno cambia.
  Edge case: la funzione deve essere pura; side effect o letture non-signal non creano dipendenze.
- **Quando usarlo**: Filtri su liste, totali, formattazione, view model derivato da più signals.
- **Quando evitarlo**: Calcoli con side effect; dati che arrivano da Observable (usare `toSignal`).
- **Snippet**:
```typescript
filteredUsers = computed(() =>
  this.users().filter(u => u.role === this.roleFilter())
);
```
- **Errori comuni da evitare**: Inserire side effect in `computed`; leggere signal in async callback (perde tracciabilità).

### Signals vs Observable
- **Domanda**: Quando preferire Signals rispetto a Observable?
- **Risposta breve**: Signals per stato sincrono e derivato; Observable per stream asincroni (HTTP, eventi, timer).
- **Spiegazione estesa**: Signals sono sincroni, non richiedono unsubscribe e si integrano con `computed`.
  Observable resta ideale per operazioni async, operatori complessi e integrazioni esterne.
- **Quando usarlo**: Signals per stato UI, form state, filtri; Observable per API, websocket, debounce.
- **Quando evitarlo**: Signals per stream che emettono molte volte senza "stato" (es. mousemove); Observable per stato semplice locale.
- **Snippet**:
```typescript
// Signal per stato locale
selectedId = signal<string | null>(null);
// Observable per HTTP
users$ = this.http.get<User[]>("/api/users");
users = toSignal(this.users$, { initialValue: [] });
```
- **Errori comuni da evitare**: Mischiare pattern senza criterio; usare `toSignal` su stream che non completano senza `initialValue`.

## Dependency Injection

### `@Injectable` e providedIn
- **Domanda**: Cosa fa `providedIn` in `@Injectable` e quali scope esistono?
- **Risposta breve**: Definisce dove il servizio è fornito: `root` (singleton app-wide), `platform`, modulo specifico o `null` (solo dove dichiarato).
- **Spiegazione estesa**: `providedIn: 'root'` registra il servizio nel root injector: un'unica istanza per tutta l'app. `providedIn: SomeModule` lo limita al modulo. `null` richiede dichiarazione esplicita in `providers`. Edge case: servizi con stato in `root` sono condivisi; per stato per-route usare `providers` nel route config.
- **Quando usarlo**: `root` per servizi stateless (API, auth, logging); modulo per feature isolata; `null` per servizi da fornire in contesti specifici.
- **Quando evitarlo**: `root` per servizi con stato che deve essere isolato (es. form state per route); modulo per servizi globali.
- **Snippet**:
```typescript
@Injectable({ providedIn: "root" })
export class UserService { }

@Injectable({ providedIn: null })
export class FormStateService {
  // fornito solo dove serve: providers: [FormStateService]
}
```
- **Errori comuni da evitare**: Usare `root` per servizi con stato condiviso indesiderato; dimenticare `providers` con `providedIn: null`.

### `inject()` con RxJS (guard, service, function)
- **Domanda**: Come usare `inject()` in guard, servizi e funzioni con RxJS?
- **Risposta breve**: `inject()` funziona solo in injection context; nelle classi Angular è corretto usarlo in field initializer (o constructor), nelle guard/resolver/factory nel body della funzione.
- **Spiegazione estesa**: `inject()` è disponibile in constructor, field initializer e injection context (guard, resolver, factory, interceptor function). Con RxJS, inietti una volta la dipendenza nel field initializer e poi la usi nei metodi/pipe. Edge case: chiamare `inject()` dentro metodi come `ngOnInit` o callback (`setTimeout`, `subscribe`) lancia errore per assenza di injection context.
- **Quando usarlo**: Field injection in componenti/servizi, guard functional, interceptor function, provider factory.
- **Quando evitarlo**: In callback async puri, in classi non create da DI, dentro metodi invocati dopo la creazione dell'istanza.
- **Snippet**:
```typescript
export const authGuard: CanActivateFn = (route) => {
  const auth = inject(AuthService);
  const router = inject(Router);
  return auth.isLoggedIn$.pipe(
    take(1),
    map((ok) => ok || router.createUrlTree(["/login"]))
  );
};

@Injectable({ providedIn: "root" })
export class UserService {
  private readonly http = inject(HttpClient); // field initializer: corretto

  getData(): Observable<User[]> {
    return this.http.get<User[]>("/api/users");
  }
}
```
- **Errori comuni da evitare**: Chiamare `inject()` in callback fuori dal context; usare `inject()` in `ngOnInit` o in un metodo qualsiasi invece che nel constructor/field initializer.

## RxJS

### Observable vs Promise
- **Domanda**: Qual è la differenza tra `Observable` e `Promise`?
- **Risposta breve**: `Observable` gestisce stream multipli e cancellabili; `Promise` è singolo valore.
- **Spiegazione estesa**: In Angular, `Observable` è lo standard per HTTP, eventi e state.
  Edge case: senza unsubscribe, uno stream hot può creare leak.
- **Quando usarlo**: Stream di eventi, polling, websocket, form valueChanges.
- **Quando evitarlo**: Operazioni one-shot semplici dove una `Promise` è sufficiente.
- **Snippet**:
```typescript
this.data$ = this.http.get<User[]>("/api/users");
```
- **Errori comuni da evitare**: Convertire tutto in `Promise` e perdere cancellazione.

### `Subject` vs `BehaviorSubject`
- **Domanda**: Quando usare `Subject` e quando `BehaviorSubject`?
- **Risposta breve**: `Subject` non ha valore iniziale; `BehaviorSubject` emette l'ultimo valore.
- **Spiegazione estesa**: `BehaviorSubject` è utile per stato condiviso in componenti.
  Edge case: usare `Subject` per stato fa perdere il valore ai late-subscriber.
- **Quando usarlo**: `BehaviorSubject` per stato; `Subject` per eventi one-off.
- **Quando evitarlo**: `BehaviorSubject` per eventi; `Subject` per stato persistente.
- **Snippet**:
```typescript
state$ = new BehaviorSubject<User | null>(null);
state$.next(user);
```
- **Errori comuni da evitare**: Esporre il subject direttamente invece di `asObservable()`.

### `switchMap` vs `mergeMap` vs `concatMap`
- **Domanda**: Quale operatore usare per chiamate async concorrenti?
- **Risposta breve**: `switchMap` cancella la richiesta precedente; `mergeMap` concatena in parallelo;
  `concatMap` serializza in ordine.
- **Spiegazione estesa**: `switchMap` è ideale per ricerche live; `mergeMap` per batch concorrenti;
  `concatMap` per evitare race condition in sequenza.
- **Quando usarlo**: `switchMap` per autocomplete; `mergeMap` per notifiche; `concatMap` per write sequenziali.
- **Quando evitarlo**: `mergeMap` quando l'ordine è critico; `switchMap` se non vuoi cancellazioni.
- **Snippet**:
```typescript
this.results$ = this.termCtrl.valueChanges.pipe(
  debounceTime(300),
  distinctUntilChanged(),
  switchMap((q) => this.api.search(q))
);
```
- **Errori comuni da evitare**: Usare `mergeMap` e ottenere risultati out-of-order.

### `debounceTime` e `distinctUntilChanged`
- **Domanda**: A cosa servono e quando combinarli?
- **Risposta breve**: `debounceTime` riduce le emissioni; `distinctUntilChanged` filtra duplicati.
- **Spiegazione estesa**: In input veloci evitano richieste eccessive. Edge case: `distinctUntilChanged`
  su oggetti confronta per reference; serve una custom comparator.
- **Quando usarlo**: Input search, resize/scroll, form valueChanges.
- **Quando evitarlo**: Stream dove ogni evento è significativo (es. audit).
- **Snippet**:
```typescript
this.termCtrl.valueChanges.pipe(
  debounceTime(300),
  distinctUntilChanged()
);
```
- **Errori comuni da evitare**: Aspettarsi che `distinctUntilChanged` funzioni su oggetti complessi.

### `combineLatest` vs `withLatestFrom`
- **Domanda**: Differenze tra `combineLatest` e `withLatestFrom`?
- **Risposta breve**: `combineLatest` emette a ogni update di qualsiasi stream; `withLatestFrom`
  emette solo quando lo stream sorgente emette.
- **Spiegazione estesa**: `combineLatest` è utile per derivare stato da più sorgenti; `withLatestFrom`
  per arricchire un evento con l'ultimo stato disponibile.
- **Quando usarlo**: `combineLatest` per view model; `withLatestFrom` per action + state.
- **Quando evitarlo**: `combineLatest` con stream che non emettono mai (serve `startWith`).
- **Snippet**:
```typescript
this.vm$ = combineLatest([this.user$, this.settings$]).pipe(
  map(([u, s]) => ({ user: u, settings: s }))
);
```
- **Errori comuni da evitare**: Dimenticare `startWith` e non ricevere emissioni.

### `shareReplay`
- **Domanda**: Perché usare `shareReplay`?
- **Risposta breve**: Condivide una richiesta e riusa l'ultimo valore per nuovi subscriber.
- **Spiegazione estesa**: Evita chiamate HTTP duplicate in più componenti. Edge case: usare
  `shareReplay` senza `refCount` può mantenere la subscription attiva a lungo.
- **Quando usarlo**: Cache di dati read-only con più subscriber.
- **Quando evitarlo**: Stream con side effect che non devono essere riusati.
- **Snippet**:
```typescript
this.users$ = this.http.get<User[]>("/api/users").pipe(
  shareReplay({ bufferSize: 1, refCount: true })
);
```
- **Errori comuni da evitare**: Creare memory leak con replay infinito.

## Standalone vs NgModule

### Differenza tra standalone e NgModule
- **Domanda**: Qual è la differenza tra component standalone e NgModule?
- **Risposta breve**: I component standalone dichiarano direttamente le dipendenze,
  mentre gli NgModule le aggregano a livello di modulo.
- **Spiegazione estesa**: Standalone riduce boilerplate e migliora tree-shaking.
  NgModule è utile per compatibilità legacy e librerie condivise.
  Edge case: in codebase ibrida, import incoerenti generano duplicazioni e bundle più grandi.
- **Scelta progettuale**: Nuovi feature in standalone; mantenere NgModule per legacy stabili.
- **Snippet**:
```typescript
@Component({
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `...`
})
export class UserCardComponent {}
```
- **Errori comuni da evitare**: Mischiare import di moduli e standalone senza regole.

## Routing e Auth Guard

### `provideRouter` (standalone routing)
- **Domanda**: Cos'è `provideRouter` e come si usa per il routing standalone?
- **Risposta breve**: Funzione che fornisce il router in app standalone, sostituendo `RouterModule.forRoot()`.
- **Spiegazione estesa**: Con `bootstrapApplication()`, non si importa `RouterModule`; si passa `provideRouter(routes)` in `providers`. Supporta `withRouterConfig`, `withComponentInputBinding`, `withViewTransitions`. Edge case: per preload strategy custom usare `withPreloading(MyPreloadStrategy)`.
- **Quando usarlo**: App standalone (Angular 14+); nuova configurazione da zero.
- **Quando evitarlo**: App basata su NgModule; usare `RouterModule.forRoot()`.
- **Snippet**:
```typescript
bootstrapApplication(AppComponent, {
  providers: [
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient()
  ]
});
```
- **Errori comuni da evitare**: Mischiare `RouterModule` e `provideRouter`; dimenticare `provideRouter` e avere route non funzionanti.

### Routing: autenticazione e autorizzazione
- **Domanda**: Come gestire auth e ruoli nel routing Angular?
- **Risposta breve**: Usare guard per proteggere route e validare sessione/ruoli.
- **Spiegazione estesa**: Lato client serve per UX e prevenzione accessi banali.
  Edge case: le guard non sostituiscono i controlli server-side, che restano obbligatori.
- **Scelta progettuale**: Usare guard leggere e delegare la logica di policy al backend.
- **Snippet**:
```typescript
{ path: "admin", canActivate: [AuthGuard], data: { role: "admin" } }
```
- **Errori comuni da evitare**: Basarsi solo sul routing per la sicurezza.

### Tipi di Auth Guard
- **Domanda**: Quali tipi di guard esistono e quando usarli?
- **Risposta breve**: `canActivate`, `canActivateChild`, `canDeactivate`, `canMatch`
  (e `canLoad`, deprecato).
- **Spiegazione estesa**: `canActivate` blocca l'accesso, `canActivateChild` protegge
  sotto-rotte, `canDeactivate` evita perdita dati, `canMatch` decide il match.
  Edge case: `canLoad` in lazy loading è deprecato, preferire `canMatch`.
- **Scelta progettuale**: Centralizzare la logica auth in un guard con policy riusabili.
- **Snippet**:
```typescript
export const authGuard: CanActivateFn = (route) =>
  inject(AuthService).hasRole(route.data["role"]);
```
- **Errori comuni da evitare**: Logica duplicata in più guard senza policy condivisa.

### Lazy loading di moduli e route
- **Domanda**: Come implementare il lazy loading in Angular?
- **Risposta breve**: Usare `loadChildren` con callback che ritorna un `import()` dinamico del modulo o delle route; il bundle della feature viene caricato solo al primo accesso.
- **Spiegazione estesa**: Riduce il bundle iniziale e migliora time-to-interactive. Con standalone (Angular 17+) si usa `loadComponent` per caricare un componente. Edge case: preload strategy (PreloadAllModules o custom) bilancia tra carico iniziale e navigazione successiva.
- **Quando usarlo**: Route per feature secondarie, area admin, wizard; sempre per route non critiche al primo caricamento.
- **Quando evitarlo**: Home o route di login se devono essere istantaneee.
- **Snippet**:
```typescript
{ path: "admin", loadChildren: () => import("./admin/admin.routes").then(m => m.ADMIN_ROUTES) }
```
- **Errori comuni da evitare**: Import statico nel loadChildren; dimenticare export delle route in un file separato.

## Content projection e query

### Content projection (ng-content, multi-slot)
- **Domanda**: Quando usare la content projection invece di passare dati con @Input?
- **Risposta breve**: La projection permette al parent di inserire template HTML (e componenti) dentro il child; con multi-slot si usano più `ng-content` con `select`.
- **Spiegazione estesa**: Trade-off tra flessibilità del layout e semplicità. Utile per card, modal, layout con header/footer variabili. Preferirla agli Input quando il contenuto è markup strutturato o componenti.
- **Quando usarlo**: Wrapper riutilizzabili (card, tab, drawer), layout con slot fissi (header, body, footer).
- **Quando evitarlo**: Per passare solo dati o stringhe; preferire @Input.
- **Snippet**:
```html
<!-- child -->
<ng-content select="[header]"></ng-content>
<ng-content></ng-content>
<!-- parent -->
<app-card><span header>Titolo</span><p>Corpo</p></app-card>
```
- **Errori comuni da evitare**: Select troppo specifici che rompono con cambi di struttura; proiettare troppi livelli annidati.

### ViewChild e ContentChild
- **Domanda**: Quando usare ViewChild e ContentChild?
- **Risposta breve**: `ViewChild` / `ViewChildren` referenziano elementi o componenti nel template del componente; `ContentChild` / `ContentChildren` referenziano contenuto proiettato (ng-content). Disponibili dopo le hook di view/content.
- **Spiegazione estesa**: ViewChild è risolto dopo `ngAfterViewInit`; ContentChild dopo `ngAfterContentInit`. Con `{ read: Token }` si ottiene un token diverso (es. FormControl). Edge case: con *ngIf il riferimento può essere undefined fino al render successivo; usare optional chaining o signal/input.
- **Quando usarlo**: Accesso a componenti figli per API imperativa; focus, misurazioni, integrazioni con librerie DOM.
- **Quando evitarlo**: Preferire @Input/@Output quando possibile; evitare dipendenze da ordine di render.
- **Snippet**:
```typescript
@ViewChild("input") inputRef!: ElementRef<HTMLInputElement>;
@ContentChild(ItemComponent) firstItem!: ItemComponent;
ngAfterViewInit() { this.inputRef?.nativeElement.focus(); }
```
- **Errori comuni da evitare**: Leggere ViewChild in ngOnInit (ancora undefined); non gestire il caso undefined con *ngIf.

## Pipe e performance

### Pipe puri vs impure e custom pipe
- **Domanda**: Qual è la differenza tra pipe puri e impure?
- **Risposta breve**: Le pipe pure (default) vengono ricalcolate solo quando la reference dell'input cambia; le impure (`pure: false`) ad ogni change detection.
- **Spiegazione estesa**: Le pure sono efficienti e prevedibili; le impure servono per input mutabili (oggetti che cambiano in-place) ma costano in performance. Custom pipe: dichiarare `pure: true` e evitare side effect.
- **Quando usarlo**: Pipe pure per trasformazioni senza side effect; impure solo se l'input è mutabile e non si può usare immutabilità.
- **Quando evitarlo**: Impure per liste grandi; pipe che fanno I/O o chiamate API.
- **Snippet**:
```typescript
@Pipe({ name: "fullName", pure: true })
export class FullNamePipe implements PipeTransform {
  transform(user: User) { return `${user.name} ${user.surname}`; }
}
```
- **Errori comuni da evitare**: Pipe impure con logica pesante; dimenticare che le pure non vedono mutazioni in-place.

### TrackBy in ngFor
- **Domanda**: Perché usare trackBy in *ngFor?
- **Risposta breve**: `trackBy` associa ogni elemento a un'identità stabile (es. id); Angular riusa i nodi DOM invece di ricrearli, migliorando performance e preservando stato (focus, animazioni).
- **Spiegazione estesa**: Senza trackBy, Angular usa l'identity dell'oggetto: se la lista viene sostituita con nuovi oggetti (stessi dati), tutti i nodi vengono distrutti e ricreati. Con trackBy solo gli elementi effettivamente cambiati vengono aggiornati.
- **Quando usarlo**: Liste dinamiche con più di qualche decina di elementi; liste con oggetti che hanno id univoco.
- **Quando evitarlo**: Liste statiche piccole dove il costo è trascurabile.
- **Snippet**:
```typescript
*ngFor="let item of items; trackBy: byId"
// byId = (i, item) => item.id
```
- **Errori comuni da evitare**: TrackBy che ritorna valori non univoci; usare indice come unica chiave se l'ordine cambia.

## Lazy loading e SSR

### Server-Side Rendering (SSR) con Angular (cenni)
- **Domanda**: Quando e come usare SSR con Angular?
- **Risposta breve**: Angular Universal (o il supporto SSR integrato da Angular 17+) esegue l'app sul server per il primo HTML, migliorando SEO e first paint; poi l'app si "idrata" sul client.
- **Spiegazione estesa**: Utile per pagine pubbliche indicizzabili e per ridurre LCP. Limitazioni: evitare API browser-only nel costruttore o in ngOnInit; usare PLATFORM_ID e isPlatformBrowser per codice solo client. Hydration può causare mismatch se stato server/client diverge.
- **Quando usarlo**: Siti con contenuto pubblico, landing, e-commerce; quando SEO è requisito.
- **Quando evitarlo**: App dashboard dietro login; quando la complessità di deploy e debugging non è giustificata.
- **Snippet**:
```typescript
constructor(@Inject(PLATFORM_ID) private pid: Object) {}
ngOnInit() {
  if (isPlatformBrowser(this.pid)) window.analytics?.track();
}
```
- **Errori comuni da evitare**: Accedere a `window` o `document` senza check di piattaforma; stato non deterministico tra server e client.

## Testing

### Testing unitario e integration (TestBed, fixture, mock)
- **Domanda**: Come strutturare test unitari e di integrazione in Angular?
- **Risposta breve**: `TestBed.configureTestingModule` prepara un modulo di test con componenti e servizi; `fixture = TestBed.createComponent(Comp)` crea l'istanza; si mockano i servizi con `providers: [{ provide: X, useValue: mock }]`.
- **Spiegazione estesa**: Test unitari: isolare il componente mockando le dipendenze; test di integrazione: usare servizi reali o mock realistici. Per HTTP: `HttpClientTestingModule` e `HttpTestingController` per controllare le richieste. Async con `fakeAsync`/`tick` o `async`/`waitForAsync`.
- **Quando usarlo**: Test unitari per logica e binding; integration per flussi critici (login, form submit).
- **Quando evitarlo**: Test e2e per tutto; mock eccessivi che non riflettono il comportamento reale.
- **Snippet**:
```typescript
TestBed.configureTestingModule({
  imports: [MyComponent],
  providers: [{ provide: UserService, useValue: { getUsers: () => of([]) } }]
});
const fixture = TestBed.createComponent(MyComponent);
fixture.detectChanges();
expect(fixture.nativeElement.textContent).toContain("Expected");
```
- **Errori comuni da evitare**: Non chiamare `fixture.detectChanges()` e aspettarsi binding aggiornati; dimenticare di verificare le chiamate HTTP con HttpTestingController.

## HttpClient

### Interceptors
- **Domanda**: A cosa servono gli HTTP interceptors e come si usano?
- **Risposta breve**: Intercettano richieste/risposte per aggiungere header, log, retry o gestione errori centralizzata.
- **Spiegazione estesa**: Un interceptor implementa `HttpInterceptor` e `intercept(req, next)`. La catena è ordinata: ogni interceptor può modificare la richiesta o la risposta. Edge case: interceptors sono singleton; non usare stato per-request senza attenzione (es. request ID in header).
- **Quando usarlo**: Auth token, logging, retry, error handling globale, trasformazione response.
- **Quando evitarlo**: Logica specifica di un solo componente; preferire operatori RxJS nel servizio.
- **Snippet**:
```typescript
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);
  const token = auth.getToken();
  const cloned = token
    ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
    : req;
  return next(cloned);
};
// providers: provideHttpClient(withInterceptors([authInterceptor]))
```
- **Errori comuni da evitare**: Interceptor che non chiama `next()`; modificare `req` invece di `req.clone()`.

### Error handling
- **Domanda**: Come gestire gli errori HTTP in Angular?
- **Risposta breve**: Usare `catchError` nel pipe, interceptor per errori globali, o `HttpErrorResponse` per tipizzare.
- **Spiegazione estesa**: `HttpClient` emette errori invece di completare; senza `catchError` l'errore propaga e si può usare un interceptor per log/toast globale. Edge case: `catchError` deve ritornare un Observable (anche `of(null)`) per non rompere lo stream.
- **Quando usarlo**: `catchError` nel servizio per fallback per-request; interceptor per toast/redirect 401 globale.
- **Quando evitarlo**: Swallow errori senza log o feedback utente; gestire tutto nell'interceptor senza contesto.
- **Snippet**:
```typescript
this.users$ = this.http.get<User[]>("/api/users").pipe(
  catchError((err: HttpErrorResponse) => {
    if (err.status === 401) inject(Router).navigate(["/login"]);
    return throwError(() => err);
  })
);
```
- **Errori comuni da evitare**: `catchError(() => of([]))` che nasconde l'errore; non ritornare Observable in `catchError`.

## Forms

### Reactive vs Template-driven
- **Domanda**: Qual è la differenza tra Reactive Forms e Template-driven Forms?
- **Risposta breve**: Reactive: modello in classe, validazione programmatica, testabile. Template-driven: binding nel template, validazione dichiarativa, meno boilerplate.
- **Spiegazione estesa**: Reactive usa `FormGroup`, `FormControl`, `FormArray` in TS; il template si lega con `[formGroup]`. Template-driven usa `ngModel` e direttive (`required`, `minlength`). Reactive è più scalabile per form complessi e validazione custom. Edge case: con Template-driven, il modello è creato da Angular; con Reactive hai controllo totale.
- **Quando usarlo**: Reactive per form complessi, validazione custom, dynamic forms, test unitari; Template-driven per form semplici (login, search).
- **Quando evitarlo**: Reactive per form banali (1-2 campi); Template-driven per form con validazione asincrona complessa.
- **Snippet**:
```typescript
// Reactive
form = new FormGroup({
  email: new FormControl("", [Validators.required, Validators.email]),
  password: new FormControl("", Validators.minLength(8))
});
// Template: [formGroup]="form" formControlName="email"

// Template-driven
// <input [(ngModel)]="email" name="email" required email />
```
- **Errori comuni da evitare**: Mischiare `formControlName` e `ngModel` sullo stesso controllo; dimenticare `FormsModule` o `ReactiveFormsModule`.

## In sintesi

- Lifecycle: `ngOnInit` per setup dopo binding; `ngOnChanges` solo se cambia la reference dell'input; evitare logica pesante in `ngDoCheck`.
- Change detection: Zone.js monkey-patch; OnPush riduce i check; Signals (Angular 16+) per reattività fine.
- Input/Output: comunicazione parent-child; preferire immutabilità per trigger affidabili di `ngOnChanges`.
- Content projection: ng-content e multi-slot per layout flessibili; ViewChild/ContentChild dopo le hook di view/content.
- Pipe: pure (default) vs impure; trackBy in ngFor per liste dinamiche e performance.
- Lazy loading: loadChildren con import() dinamico; SSR per SEO e first paint, attenzione a codice solo-browser.
- Testing: TestBed, fixture, mock di servizi e HttpClientTestingModule per HTTP.
- DI: gerarchia di injector; `providedIn: 'root'` per singleton; token e `useClass` per testing.
- RxJS: unsubscribe (takeUntilDestroyed, async pipe); operatori map, filter, switchMap; evitare subscribe annidati.
- Routing: lazy load; guard per auth e autorizzazione; `RouterModule` e `ActivatedRoute`.

## Vedi anche

- [TypeScript](typescript.md) — Linguaggio base di Angular.
- [JavaScript](javascript.md) — Fondamentali e event loop.
- [Sicurezza](sicurezza.md) — Auth e guard per route protette.
