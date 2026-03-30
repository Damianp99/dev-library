# Go

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Tipi, zero value e puntatori](#tipi-zero-value-e-puntatori)
- [Struct, metodi e composizione](#struct-metodi-e-composizione)
- [Interfacce](#interfacce)
- [Gestione errori](#gestione-errori)
- [Concorrenza: goroutine e channel](#concorrenza-goroutine-e-channel)
- [Package e moduli](#package-e-moduli)
- [Standard library: HTTP e JSON](#standard-library-http-e-json)
- [Testing](#testing)
- [Context, defer, panic e recover](#context-defer-panic-e-recover)
- [Generics e sync](#generics-e-sync)
- [Benchmark, profiling e go mod](#benchmark-profiling-e-go-mod)

## Panoramica

Go (Golang) è un linguaggio compilato, tipizzato staticamente, con garbage collection e modello di concorrenza nativo (goroutine e channel). Punta a semplicità, compilazione veloce e tooling integrato (formatter, test, moduli). In produzione si usa per servizi backend, CLI, microservizi e infrastruttura (Docker, Kubernetes sono scritti in Go). Non ha classi né ereditarietà: si lavora con struct, composizione e interfacce implicite; la gestione errori è esplicita (no eccezioni).

---

## Tipi, zero value e puntatori

### Concetto

Ogni tipo in Go ha uno **zero value** (0 per numeri, `""` per string, `nil` per puntatori, slice, map, channel). Non esiste "uninitialized": una variabile dichiarata è sempre inizializzata allo zero value. I **puntatori** (`*T`) referenziano un valore in memoria; `&x` restituisce l’indirizzo di `x`; la dereferenza è `*p`. Go passa gli argomenti per valore: per modificare la variabile originale o per evitare copie grandi si usa un puntatore.

### Differenze pratiche

- **Passaggio per valore**: la funzione riceve una copia; modifiche non si riflettono al chiamante (tranne per slice, map, channel che sono reference types).
- **Passaggio per puntatore**: la funzione può modificare il valore puntato; usare per struct grandi o quando serve mutazione visibile al chiamante.
- **nil**: puntatore non inizializzato; dereferenziare `nil` causa panic; sempre verificare prima dell’uso o usare pattern "value, ok".

### Best practice applicabile

Preferire il passaggio per valore quando non serve mutazione; usare puntatori per receiver quando il metodo modifica il ricevente o la struct è grande. Evitare puntatori a tipi built-in piccoli (int, bool) se non serve modifica; per API pubbliche documentare se il puntatore può essere nil.

### Mini snippet

```go
func double(n int) int {
    return n * 2
}

func appendToSlice(s []int, x int) []int {
    return append(s, x) // può riallocare; il chiamante deve usare il valore restituito
}

type Config struct{ Host string }
func (c *Config) SetHost(h string) { c.Host = h }
```

### Rischi e mitigazioni

- **Rischio**: Dereferenza di puntatore nil → panic; slice/map/channel sono reference types, passarli per valore è sufficiente per modificarne il contenuto, ma non per riassegnare la slice stessa nel chiamante.
- **Edge case**: Modificare una map o una slice in una goroutine mentre un’altra la legge può causare race; usare sync.Mutex o channel per coordinare.
- **Mitigazione**: Inizializzare puntatori con `new(T)` o `&T{}`; per slice da restituire dopo append, restituire sempre il valore di ritorno di `append`.

---

## Struct, metodi e composizione

### Concetto

Le **struct** sono tipi che raggruppano campi; non esiste ereditarietà: si compone incorporando altre struct (embedding). I **metodi** sono funzioni con receiver `(t T)` o `(t *T)`; il receiver per puntatore permette di modificare l’istanza e evita copie per struct grandi. L’**embedding** espone i campi e i metodi della struct incorporata come se fossero sulla struct esterna (delegazione implicita).

### Differenze pratiche

- **Receiver per valore**: ogni chiamata copia la struct; adatto a struct piccole e immutabili.
- **Receiver per puntatore**: modifica visibile, una sola copia del puntatore; idiomatico per la maggior parte dei metodi che mutano stato.
- **Composizione vs ereditarietà**: in Go si “incorpora” una struct (`struct{ User; Role string }`); non si sovrascrivono metodi in senso classico, ma si possono ridefinire metodi sulla struct esterna.

### Best practice applicabile

Preferire composizione (embedding) a “simulare” ereditarietà; usare receiver puntatore per metodi che mutano o per struct con molti campi; mantenere struct piccole e coerenti.

### Mini snippet

```go
type User struct {
    ID   int
    Name string
}

func (u *User) SetName(name string) { u.Name = name }

type Admin struct {
    User
    Role string
}
// Admin ha User embedded: admin.User.Name, admin.SetName(), admin.Name
```

### Rischi e mitigazioni

- **Rischio**: Embedding espone tutti i metodi della tipo incorporato; se si vuole nascondere qualcosa, usare un campo con nome (non embedding) e delegare esplicitamente.
- **Edge case**: Promozione di metodi: se sia la struct esterna sia quella incorporata hanno un metodo con lo stesso nome, viene usato quello della struct esterna; evitare ambiguità con naming chiaro.
- **Mitigazione**: Usare embedding solo quando la relazione “ha-un” è chiara; per interfacce pubbliche preferire interfacce piccole.

---

## Interfacce

### Concetto

Un’**interfaccia** è un insieme di metodi; un tipo soddisfa un’interfaccia **implicitamente** (non serve dichiarare “implementa X”). Non c’è parola chiave “implements”: se un tipo ha tutti i metodi richiesti dall’interfaccia, può essere usato dove si richiede quell’interfaccia. Le interfacce sono tipizzati per comportamento, non per gerarchia.

### Differenze pratiche

- **Interfacce piccole**: idiomatico in Go; una o poche firme (es. `io.Reader` con `Read(p []byte) (n int, err error)`).
- **Interfaccia vuota `interface{}`** (o `any` da Go 1.18): accetta qualsiasi tipo; si usa quando serve massima flessibilità (es. generics prima di Go 1.18); perdita di type safety.
- **Type assertion**: `v, ok := x.(ConcreteType)` per estrarre il tipo concreto da un’interfaccia; senza `ok` una assertion fallita causa panic.

### Best practice applicabile

Definire interfacce dove vengono consumate (lato chiamante), non dove vengono implementate; preferire interfacce piccole; usare `any`/generics con criterio per non perdere type safety.

### Mini snippet

```go
type Reader interface {
    Read(p []byte) (n int, err error)
}

func ReadAll(r Reader) ([]byte, error) {
    return io.ReadAll(r)
}
// Qualsiasi tipo con metodo Read([]byte)(int, error) può essere passato

var x interface{} = 42
n, ok := x.(int)
if !ok { /* tipo non int */ }
```

### Rischi e mitigazioni

- **Rischio**: Interfacce troppo grandi rendono difficile implementarle e testare; type assertion ripetute indicano spesso un design da rivedere (preferire interfacce più specifiche o generics).
- **Edge case**: `nil` come valore di interfaccia: un’interfaccia è (tipo, valore); se il valore concreto è nil ma il tipo no, `if x == nil` può essere falso; verificare sia il valore che il tipo quando si gestisce nil.
- **Mitigazione**: Accettare interfacce, restituire struct (o tipi concreti); definire interfacce nel package che le usa.

---

## Gestione errori

### Concetto

In Go gli errori sono **valori**: si restituiscono come ultimo valore di ritorno (`result, err error`). Non ci sono eccezioni per il flusso normale: il chiamante deve controllare `err` dopo ogni chiamata che può fallire. Il tipo `error` è un’interfaccia con un solo metodo: `Error() string`. Errori multipli e wrapping si gestiscono con `fmt.Errorf("context: %w", err)` e `errors.Is` / `errors.As`.

### Differenze pratiche

- **Errori sentinella**: `var ErrNotFound = errors.New("not found")`; il chiamante confronta con `errors.Is(err, ErrNotFound)`.
- **Wrapping**: `%w` in `fmt.Errorf` permette di wrappare un errore; `errors.Unwrap`, `errors.Is`, `errors.As` per risalire la catena.
- **Panic**: per condizioni irrecuperabili; in produzione spesso si recupera con `recover` solo ai confini (es. HTTP handler) e si logga; non usare panic per flusso normale.

### Best practice applicabile

Controllare sempre l’errore; non ignorare con `_` senza motivo; wrappare con contesto (`%w`) per dare tracciabilità; usare `errors.Is`/`errors.As` invece di confronti diretti su errori wrappati.

### Mini snippet

```go
func GetUser(id int) (*User, error) {
    u, err := db.Find(id)
    if err != nil {
        return nil, fmt.Errorf("get user %d: %w", id, err)
    }
    return u, nil
}
if errors.Is(err, sql.ErrNoRows) { ... }
var e *ValidationError
if errors.As(err, &e) { ... }
```

### Rischi e mitigazioni

- **Rischio**: Ignorare `err` porta a bug silenti; panic usati per controllo di flusso rende il codice fragile e difficile da testare.
- **Edge case**: Restituire `nil, nil` per “nessun errore e nessun risultato” può confondere; preferire pattern espliciti (es. puntatore nil + err nil solo se “non trovato” è un caso valido e documentato).
- **Mitigazione**: Lint (errcheck, staticcheck); wrappare con contesto; definire errori custom quando serve comportamento interrogabile (`errors.As`).

---

## Concorrenza: goroutine e channel

### Concetto

Una **goroutine** è un’unità di esecuzione leggera gestita dal runtime Go; si avvia con `go f()`. I **channel** sono tipi che permettono di inviare e ricevere valori tra goroutine (`ch <- v`, `v := <-ch`); possono essere buffered o unbuffered. Lo slogan è “Don’t communicate by sharing memory; share memory by communicating”: preferire channel (o pipeline di channel) per coordinare goroutine invece di lock condivisi.

### Differenze pratiche

- **Unbuffered channel**: send blocca finché qualcuno non riceve; sincronizzazione implicita.
- **Buffered channel**: send non blocca finché il buffer non è pieno; riduce accoppiamento temporale ma richiede gestione della capacità.
- **select**: scelta tra più channel (send/recv) o default; usato per timeout e multiplexing.
- **sync.Mutex**: quando serve proteggere stato condiviso (es. cache in memoria); channel non sempre più chiari per ogni caso.

### Best practice applicabile

Preferire channel per passaggio di dati e segnali tra goroutine; usare context per cancellazione e timeout; evitare goroutine che non terminano mai (leak); per stato condiviso usare mutex con scope limitato.

### Mini snippet

```go
ch := make(chan int)
go func() {
    ch <- 42
}()
v := <-ch

// Select con timeout
select {
case v := <-ch:
    return v
case <-time.After(2 * time.Second):
    return errors.New("timeout")
}
```

### Rischi e mitigazioni

- **Rischio**: Goroutine leak: goroutine bloccate su channel senza mai ricevere/send; channel non chiusi quando non più usati (chiudere dal produttore, non dal consumatore).
- **Edge case**: Inviare su channel chiuso causa panic; ricevere da channel chiuso restituisce zero value e ok false; chiudere una sola volta.
- **Mitigazione**: Usare `context.Context` per cancellazione; pattern worker pool con channel di job e chiusura esplicita; race detector (`go build -race`).

---

## Package e moduli

### Concetto

Il **modulo** è l’unità di distribuzione e versioning (go.mod); definisce il module path e le dipendenze con versione. I **package** sono directory di file `.go` che condividono lo stesso nome di package; il path del package è il path della directory rispetto al module root. Le variabili e le funzioni con iniziale maiuscola sono **esportate** (pubbliche); minuscola = non esportate (private al package).

### Differenze pratiche

- **go mod init**, **go mod tidy**: inizializzazione e allineamento dipendenze con l’uso nel codice.
- **Versioning**: v0 per instabilità; v1+ per compatibilità (semantic versioning); `go get module@v1.2.3` per aggiornare.
- **Replace e vendor**: `replace` in go.mod per dipendenze locali o fork; `go mod vendor` per copia dipendenze nel repo.

### Best practice applicabile

Un package = una responsabilità coerente; esporre solo ciò che serve all’esterno; usare go.sum e commitarlo; in CI eseguire `go mod tidy` e `go build ./...` per rilevare dipendenze mancanti o incompatibili.

### Mini snippet

```go
// go.mod
module github.com/org/myapp
go 1.21
require example.com/lib v1.0.0
```

### Rischi e mitigazioni

- **Rischio**: Dipendenze non fissate (nessun go.sum o versioni floating) possono rompere build nel tempo; breaking change in dipendenze.
- **Mitigazione**: go.sum sempre in repo; aggiornamenti dipendenze in branch dedicati con test; valutare tool (es. Renovate, Dependabot) per aggiornamenti minori.

---

## Standard library: HTTP e JSON

### Concetto

**net/http** fornisce client e server HTTP: `http.ListenAndServe`, `http.HandlerFunc`, `http.ServeMux` (router); middleware come funzioni `func(http.Handler) http.Handler`. **encoding/json** serializza e deserializza: `json.Marshal`/`Unmarshal`; tag struct `json:"field_name"` per mapping nomi e opzioni (omitempty).

### Differenze pratiche

- **Handler**: interfaccia `ServeHTTP(ResponseWriter, *Request)`; spesso si usa `http.HandlerFunc(f)` per adattare una funzione.
- **Context**: `r.Context()` per timeout e cancellazione; passare context nelle chiamate downstream.
- **JSON**: tipi non esportati (minuscola) non vengono serializzati; per campi opzionali usare puntatori o `omitempty`.

### Best practice applicabile

Usare middleware per logging, recovery, timeout; validare input e limitare dimensioni body; per API complesse considerare router di terze parti (gorilla, chi, echo) ma la stdlib è sufficiente per molti casi.

### Mini snippet

```go
type User struct {
    ID   int    `json:"id"`
    Name string `json:"name,omitempty"`
}
data, _ := json.Marshal(user)
json.Unmarshal(data, &user)

http.HandleFunc("/users", func(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodGet { w.WriteHeader(405); return }
    // ...
})
http.ListenAndServe(":8080", nil)
```

### Rischi e mitigazioni

- **Rischio**: Server senza timeout può essere vulnerabile a slowloris; body non limitato a DoS; deserializzazione JSON su input non fidato (dimensioni, profondità).
- **Mitigazione**: Timeout su server e client; `http.MaxBytesReader`; validazione e limiti su decode JSON.

---

## Testing

### Concetto

Il tool **testing** della standard library: file `*_test.go`, funzioni `func TestXxx(t *testing.T)`. **Table-driven tests**: un slice di casi (input, atteso) e un loop che esegue e confronta. **Benchmark**: `func BenchmarkXxx(b *testing.B)`. **Mock e dipendenze**: si iniettano interfacce; in test si passano implementazioni fake o mock. Il modulo **testing** non ha assert built-in; si usa `t.Error`/`t.Fatal` o librerie (testify) se il team le adotta.

### Differenze pratiche

- **Test nello stesso package**: test white-box (accedono a simboli non esportati); test in `package_test` con import del package: black-box (solo simboli esportati).
- **Coverage**: `go test -cover`; `-coverprofile` per report dettagliato.
- **Go 1.20+**: subtest e setup/teardown con `t.Run`; parallel test con `t.Parallel()`.

### Best practice applicabile

Table-driven test per coprire molti casi con poco codice; interfacce per iniettare dipendenze e mockare; evitare test che dipendono da ordine o da stato globale; eseguire test in CI con race detector quando rilevante.

### Mini snippet

```go
func TestAdd(t *testing.T) {
    cases := []struct {
        a, b, want int
    }{
        {1, 2, 3},
        {0, 0, 0},
    }
    for _, tc := range cases {
        got := Add(tc.a, tc.b)
        if got != tc.want {
            t.Errorf("Add(%d,%d)=%d; want %d", tc.a, tc.b, got, tc.want)
        }
    }
}
```

### Rischi e mitigazioni

- **Rischio**: Test che dipendono da risorse esterne (DB, API) sono fragili e lenti; test che non controllano tutti gli output rilevanti (false positive).
- **Mitigazione**: Usare interfacce e mock per dipendenze esterne; test di integrazione separati e opzionali; mantenere test veloci per feedback rapido.

---

## Context, defer, panic e recover

### Context: cancellazione e timeout
**Concetto**  
`context.Context` propaga segnali di cancellazione e deadline attraverso le chiamate (HTTP request, gRPC, worker). Si crea con `context.WithCancel`, `WithTimeout`, `WithDeadline`; si passa come primo parametro; si controlla con `ctx.Done()` e `ctx.Err()`.

**Differenze pratiche**  
- WithCancel: il chiamante invoca cancel() per segnalare stop.  
- WithTimeout/WithDeadline: cancellazione automatica dopo un tempo.  
- In handler HTTP: `req.Context()` si annulla quando il client chiude la connessione; passarlo a tutte le chiamate downstream.

**Best practice applicabile**  
Passare context come primo argomento; rispettare la cancellazione (controllare Done() in loop, passare context a chiamate I/O); non memorizzare context in struct (passarlo esplicitamente).

**Mini snippet**

```go
ctx, cancel := context.WithTimeout(req.Context(), 5*time.Second)
defer cancel()
result, err := repo.FindByID(ctx, id)
if ctx.Err() == context.DeadlineExceeded { ... }
```

**Rischi e mitigazioni**  
- **Rischio**: Context già cancellato passato a funzioni che non controllano Done(); goroutine che non si fermano.  
- **Edge case**: Creare context da context.Background() solo a livello root (main, test); non usare Background() dentro un handler.

### Defer, panic e recover
**Concetto**  
`defer` esegue una funzione al ritorno dalla funzione corrente (LIFO: ultimo defer eseguito per primo). `panic` interrompe l'esecuzione normale e risale lo stack fino a un `recover` (solo dentro defer) o alla terminazione del programma.

**Differenze pratiche**  
- defer: utile per close di file, unlock, cleanup; gli argomenti sono valutati al momento del defer, non all'esecuzione.  
- recover() restituisce il valore passato a panic; fuori da defer non fa nulla.  
- In produzione preferire restituire error invece di panic; panic per bug irrecoverabili (nil pointer, assert).

**Best practice applicabile**  
Usare defer per risorse; per recuperare da panic in goroutine (es. HTTP handler) wrappare il handler in un defer recover e loggare; non usare panic per flusso normale.

**Mini snippet**

```go
defer func() {
    if r := recover(); r != nil {
        log.Printf("recovered: %v", r)
    }
}()
```

**Rischi e mitigazioni**  
- **Rischio**: panic in goroutine non recuperata fa terminare tutto il programma; recover solo nella stessa goroutine.  
- **Edge case**: defer con chiamata a funzione: `defer f()` vs `defer func() { f() }()` (con parametri la valutazione è immediata).

---

## Generics e sync

### Generics (Go 1.18+): type parameters e constraint
**Concetto**  
I generics permettono di scrivere funzioni e tipi parametrizzati da tipi: `func F[T constraint](t T) T`. I constraint (es. `comparable`, `any`, interfacce con type set) limitano quali tipi possono essere usati.

**Differenze pratiche**  
- Type parameter: `[T any]`, `[K comparable, V any]`; si usano per slice, map, funzioni di utilità.  
- Constraint: interfacce che possono includere type set (es. `~int` per tutti i tipi il cui underlying è int).  
- Limiti: no method su type param (solo constraint con metodi); no generics su metodi (solo su funzioni e tipi).

**Best practice applicabile**  
Usare per container riutilizzabili (slice filter, map keys) e per evitare interface{} e type assertion; non abusare dove una interfaccia basta.

**Mini snippet**

```go
func Map[T, U any](s []T, f func(T) U) []U {
    out := make([]U, len(s))
    for i, v := range s { out[i] = f(v) }
    return out
}
```

**Rischi e mitigazioni**  
- **Rischio**: Codice generico complesso e difficile da leggere; binary size può aumentare per ogni istanziazione.  
- **Edge case**: Constraint con type set: `type Number interface{ ~int | ~int64 }` per accettare solo numeri.

### Sync package: WaitGroup, Mutex, Once
**Concetto**  
`sync.WaitGroup` per attendere il completamento di N goroutine; `sync.Mutex` per accesso esclusivo a dati condivisi; `sync.Once` per eseguire un'azione una sola volta (es. init).

**Differenze pratiche**  
- WaitGroup: Add(n), Done() (decrementa), Wait() blocca fino a zero.  
- Mutex: Lock/Unlock; RWMutex per letture concorrenti e scrittura esclusiva.  
- Once: Do(f) esegue f una sola volta anche con più goroutine; per singleton lazy.

**Best practice applicabile**  
Preferire channel per coordinamento quando possibile; usare Mutex per stato condiviso semplice; evitare lock annidati (deadlock); defer mu.Unlock() dopo Lock().

**Mini snippet**

```go
var wg sync.WaitGroup
for _, item := range items {
    wg.Add(1)
    go func(i Item) { defer wg.Done(); process(i) }(item)
}
wg.Wait()
```

**Rischi e mitigazioni**  
- **Rischio**: Add chiamato dopo avvio goroutine o con valore negativo; Wait senza Add sufficiente (panic o deadlock).  
- **Edge case**: Mutex copiato per valore invalida il lock; usare puntatore a Mutex se deve essere condiviso.

---

## Benchmark, profiling e go mod

### Benchmark (testing.B) e profiling (pprof)
**Concetto**  
I benchmark si scrivono in file `_test.go` con funzione `func BenchmarkX(b *testing.B)`; si eseguono con `go test -bench=.`. Il package `runtime/pprof` e `go test -cpuprofile`/`-memprofile` producono profili per analisi (flame graph, allocazioni).

**Differenze pratiche**  
- b.N: numero di iterazioni; il benchmark gira fino a stabilizzare il tempo per iterazione.  
- Evitare lavoro che il compilatore può eliminare (usare risultato in b.StopTimer/b.StartTimer per setup escluso).  
- pprof: `go tool pprof cpu.prof` per analisi interattiva; integrazione con trace per concorrenza.

**Best practice applicabile**  
Benchmark rappresentativi (stessi dati e condizioni di prod); confrontare prima/dopo refactoring; profilare prima di ottimizzare.

**Mini snippet**

```go
func BenchmarkSort(b *testing.B) {
    data := loadTestData()
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        sort.Slice(data, ...)
    }
}
```

**Rischi e mitigazioni**  
- **Rischio**: Benchmark su dati troppo piccoli o artificiali; ottimizzazione prematura senza dati.  
- **Edge case**: Il compilatore può ottimizzare via codice "morto"; assegnare il risultato a una variabile esportata (benchmark.Result) per evitarlo.

### go mod, vendoring e replace
**Concetto**  
`go.mod` definisce il modulo (path e versione Go) e le dipendenze; `go get` aggiorna le dipendenze; `go mod vendor` copia le dipendenze in `vendor/` per build offline o riproducibile. `replace` in go.mod reindirizza un modulo a un path locale o a un fork.

**Differenze pratiche**  
- go mod tidy: rimuove dipendenze inutilizzate e aggiunge quelle mancanti.  
- replace: utile per fork temporanei o moduli in sviluppo locale (`replace example.com/pkg => ../pkg`).  
- vendor: il build usa prima i file in vendor se presenti; in CI spesso si usa -mod=vendor per riproducibilità.

**Best practice applicabile**  
Commit go.mod e go.sum; usare replace solo per sviluppo o patch; documentare fork e replace; in pipeline usare -mod=vendor se si vuole build senza rete.

**Mini snippet**

```go
// go.mod
module myapp
go 1.21
require example.com/lib v1.2.3
replace example.com/lib => ./local/lib
```

**Rischi e mitigazioni**  
- **Rischio**: replace dimenticato che punta a path locale; build che fallisce su altro ambiente.  
- **Edge case**: Dipendenze indirette con vulnerabilità: `go list -m -u all` e aggiornamento mirato.

### Interfacce vuote e type assertion (interface{}, any)
**Concetto**  
`interface{}` o `any` (alias da Go 1.18) è il tipo che accetta qualsiasi valore. La type assertion `v.(T)` estrae il tipo T da un'interfaccia; la forma "comma-ok" `v, ok := x.(T)` evita il panic se il tipo non è T.

**Differenze pratiche**  
- any è preferibile a interface{} per chiarezza.  
- Type assertion senza comma-ok: panic se x non è di tipo T.  
- Type switch: `switch x.(type) { case int: ... case string: ... }` per gestire più tipi.

**Best practice applicabile**  
Limitare l'uso di any ai boundary (JSON, plugin); preferire generics o interfacce tipizzate; usare sempre comma-ok quando il tipo non è garantito.

**Mini snippet**

```go
func handle(v any) {
    if s, ok := v.(string); ok {
        fmt.Println(s)
    }
}
```

**Rischi e mitigazioni**  
- **Rischio**: Type assertion errata causa panic; validare input prima di assert.  
- **Edge case**: any con nil: type assertion su nil interface fallisce; controllare nil prima.

## In sintesi

- Tipi e zero value: ogni tipo ha zero value (0, "", nil); puntatori per mutabilità e optionalità.
- Struct e composizione (no ereditarietà); metodi con receiver; interfacce implicite (implementazione senza dichiarare).
- Errori come valori: restituire `(T, error)`; controllare sempre l'errore; wrap con `fmt.Errorf` e `%w`.
- Goroutine e channel: concorrenza con `go f()`; channel per comunicazione; select per multiplexing; evitare leak (channel o goroutine non chiusi).
- Moduli: `go.mod` per dipendenze; package path e visibilità (maiuscola = esportato).
- Context per cancellazione e timeout; defer per cleanup; panic/recover per errori irrecoverabili; generics per codice riutilizzabile; sync (WaitGroup, Mutex, Once); benchmark e pprof; go mod e replace.

## Vedi anche

- [Database](database.md) — Integrazione DB e driver.
- [Architettura](architettura.md) — REST e microservizi.
- [Docker](docker.md) e [Kubernetes](kubernetes.md) — Stack scritto in Go.
