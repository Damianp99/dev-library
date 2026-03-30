# Java

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [OOP](#oop)
- [Collections](#collections)
- [Stream API](#stream-api)
- [Concorrenza](#concorrenza)
- [Eccezioni](#eccezioni)
- [JVM Basics](#jvm-basics)
- [Records e sealed](#records-e-sealed)
- [Pattern matching](#pattern-matching)
- [Optional e try-with-resources](#optional-e-try-with-resources)
- [Module system (JPMS)](#module-system-jpms)
- [CompletableFuture](#completablefuture)

## Panoramica

Java è un linguaggio object-oriented, tipizzato staticamente, che gira sulla JVM. Offre garbage collection automatico, modello di concorrenza basato su thread e un ecosistema maturo per applicazioni enterprise. In produzione si appoggia su OOP per modellare il dominio, collections e stream per manipolare dati, gestione esplicita delle eccezioni e comprensione della JVM per tuning e troubleshooting.

---

## OOP

### Incapsulamento, ereditarietà e polimorfismo: differenze e quando applicarli

**Definizione tecnica**  
L'incapsulamento nasconde lo stato interno esponendo solo interfacce pubbliche; l'ereditarietà permette di estendere una classe riusando codice e contratto; il polimorfismo consente di trattare oggetti di sottotipi tramite il tipo base, con binding dinamico del metodo a runtime.

**Differenze pratiche**  
- **Incapsulamento**: `private`/`protected` sui campi, getter/setter o builder; riduce accoppiamento e permette di cambiare implementazione senza impattare i client.  
- **Ereditarietà**: relazione "is-a"; utile per gerarchie stabili (es. `Exception`), ma crea accoppiamento forte. Esempio: `Dog` estende `Animal`.  
- **Polimorfismo**: permette sostituibilità (Liskov); lo stesso metodo chiamato su `Animal` esegue l'override di `Dog`/`Cat`. Preferire composizione su ereditarietà quando la relazione non è naturale.

**Best practice applicabile**  
Preferire composizione a ereditarietà per flessibilità; usare interfacce per polimorfismo e testabilità; mantenere classi finali quando non serve estensione; evitare ereditarietà profonda (max 2-3 livelli).

**Mini snippet**

```java
abstract class Animal {
    private final String name;
    protected Animal(String name) { this.name = name; }
    public String getName() { return name; }
    public abstract String speak();
}

class Dog extends Animal {
    public Dog(String name) { super(name); }
    @Override public String speak() { return "bau"; }
}

class Cat extends Animal {
    public Cat(String name) { super(name); }
    @Override public String speak() { return "miao"; }
}

// Polimorfismo: stesso tipo base, comportamento diverso
List<Animal> animals = List.of(new Dog("Fido"), new Cat("Luna"));
for (Animal a : animals) {
    System.out.println(a.getName() + ": " + a.speak());
}
```

**Rischi e mitigazioni**  
- **Rischio**: Ereditarietà usata per riuso di codice invece che per relazione semantica produce gerarchie fragili.  
- **Edge case**: Override di metodi che cambiano il contratto (es. eccezioni checked, pre/post condizioni) viola Liskov; i sottotipi devono essere sostituibili senza rompere il comportamento atteso.  
- **Mitigazione**: Design by contract; documentare invarianti; preferire delega e interfacce.

!!! tip "Prova a spiegarlo"
    Spiega a voce: quando usare **ArrayList** vs **LinkedList** e perché. Poi verifica nella sezione [Collections](java.md#arraylist-vs-linkedlist-quando-usare-quale).

---

### `equals` e `hashCode`: contratto e implicazioni

=== "In un colpo d'occhio"
    Se `a.equals(b)` allora `a.hashCode() == b.hashCode()`. Override sempre **entrambi** insieme; usare gli stessi campi significativi; con `record` sono generati automaticamente.

=== "Dettaglio"
    **Definizione tecnica**  
    `equals` definisce uguaglianza logica tra oggetti; `hashCode` restituisce un intero usato da strutture hash-based (`HashMap`, `HashSet`). Il contratto: se `a.equals(b)` allora `a.hashCode() == b.hashCode()`; oggetti uguali devono avere lo stesso hash; hash diversi non implicano oggetti diversi.

    **Differenze pratiche**  
    - **equals**: default `==` (identità); override necessario per uguaglianza semantica (es. due `User` con stesso `id`).  
    - **hashCode**: usato per bucket in `HashMap`; collisioni gestite con liste; hash incoerente con equals rompe `HashSet`/`HashMap`.

    **Best practice applicabile**  
    Override sempre entrambi insieme; usare gli stessi campi "significativi" per entrambi; con `record` (Java 16+) equals/hashCode sono generati automaticamente; evitare campi mutabili che influenzano equals/hashCode se l'oggetto è usato in strutture hash.

    **Mini snippet**

    ```java
    public record User(Long id, String email) {}

    // Oppure manuale
    public class User {
        private final Long id;
        private final String email;

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof User user)) return false;
            return Objects.equals(id, user.id);
        }

        @Override
        public int hashCode() {
            return Objects.hash(id);
        }
    }
    ```

    **Rischi e mitigazioni**  
    - **Rischio**: Modificare un oggetto dopo averlo inserito in `HashSet`/`HashMap` (cambiando campi usati in hashCode) lo rende irraggiungibile.  
    - **Edge case**: `Float.NaN` e `Double.NaN` hanno `equals` true tra loro ma `hashCode` può variare; per tipi con NaN serve gestione esplicita.  
    - **Mitigazione**: Usare campi immutabili per equals/hashCode; preferire `record` quando possibile.

---

## Collections

### `ArrayList` vs `LinkedList`: quando usare quale

=== "In un colpo d'occhio"
    **ArrayList**: accesso O(1) per indice, ottimo per iterazione e accesso random. **LinkedList**: lista collegata, accesso O(n) per indice; inserimenti in testa/coda O(1) con riferimento al nodo. In dubbio preferire ArrayList (o ArrayDeque per code).

=== "Dettaglio"
    **Differenze pratiche**  
    - **ArrayList**: migliore per accesso random, iterazione sequenziale, cache-friendly; overhead di memoria minore.  
    - **LinkedList**: ogni nodo ha overhead (prev/next); inserimenti in testa con `addFirst` O(1), ma per inserire in mezzo serve comunque O(n) per trovare la posizione.

    **Best practice applicabile**  
    Preferire `ArrayList` nella maggior parte dei casi; usare `LinkedList` solo per code FIFO con `Deque` (es. `ArrayDeque` è spesso migliore); evitare `LinkedList` per accesso per indice.

    **Mini snippet**

    ```java
    // Accesso random - ArrayList
    List<String> list = new ArrayList<>();
    list.add("A");
    String first = list.get(0);

    // Coda FIFO - preferire ArrayDeque
    Deque<String> queue = new ArrayDeque<>();
    queue.offer("task");
    String next = queue.poll();
    ```

    **Rischi e mitigazioni**  
    - **Rischio**: `LinkedList` per `list.get(i)` in loop è O(n²); `ArrayList` è O(n).  
    - **Mitigazione**: Profilare prima di ottimizzare; `ArrayDeque` spesso batte `LinkedList` anche come coda.

---

### `HashMap` vs `ConcurrentHashMap`: thread-safety e performance

**Definizione tecnica**  
`HashMap` non è thread-safe; modifiche concorrenti possono corrompere la struttura o causare loop infiniti in iterazione. `ConcurrentHashMap` usa lock per segmento (o CAS per Java 8+) e permette letture concorrenti senza lock.

**Differenze pratiche**  
- **HashMap**: nessun lock; veloce in single-thread; in multi-thread serve `Collections.synchronizedMap()` o accesso esterno sincronizzato.  
- **ConcurrentHashMap**: operazioni atomiche (`putIfAbsent`, `compute`, `merge`); letture non bloccanti; `null` non supportato come chiave o valore.

**Best practice applicabile**  
Per cache concorrente usare `ConcurrentHashMap`; evitare `Hashtable` (legacy, lock globale); per operazioni composite usare `compute`/`merge` invece di get-modify-put; non usare `HashMap` condiviso tra thread senza sincronizzazione.

**Mini snippet**

```java
// Aggiornamento atomico in ConcurrentHashMap
ConcurrentHashMap<String, AtomicInteger> counters = new ConcurrentHashMap<>();
counters.compute("key", (k, v) -> v == null ? new AtomicInteger(1) : new AtomicInteger(v.incrementAndGet()));

// Oppure merge
counters.merge("key", 1, Integer::sum);
```

**Rischi e mitigazioni**  
- **Rischio**: `HashMap` con thread concorrenti può portare a corruzione dati e `ConcurrentModificationException` in iterazione.  
- **Edge case**: `ConcurrentHashMap.compute` può essere chiamato ricorsivamente; se la funzione di mapping fa `get` sulla stessa mappa si rischia deadlock (la mappa non è rientrante per il compute stesso).  
- **Mitigazione**: Usare `ConcurrentHashMap` per dati condivisi; evitare operazioni pesanti dentro `compute`; preferire `merge` per aggregazioni semplici.

---

## Stream API

### Stream lazy vs eager: valutazione e side-effect

**Definizione tecnica**  
Le operazioni intermedie sono lazy: non eseguono finché non c'è un'operazione terminale. Le operazioni terminali sono eager: triggerano l'esecuzione dell'intera pipeline. Una pipeline viene consumata una sola volta.

**Differenze pratiche**  
- **Lazy**: `filter`, `map`, `flatMap` non processano elementi finché non serve un risultato; permette short-circuit (es. `limit(1)` interrompe dopo il primo elemento).  
- **Eager**: `forEach`, `collect`, `reduce` consumano lo stream; dopo una terminale lo stream è "closed".

**Best practice applicabile**  
Evitare side-effect nelle operazioni intermedie (`filter`, `map`); usare `forEach` solo per effetti collaterali finali; preferire `collect` per risultati; non riusare lo stream dopo operazione terminale; per operazioni costose sfruttare la lazy evaluation.

**Mini snippet**

```java
List<String> result = list.stream()
    .filter(s -> s.length() > 2)   // lazy
    .map(String::toUpperCase)      // lazy
    .limit(10)                     // lazy, short-circuit
    .collect(Collectors.toList()); // eager, consuma stream

// Errore: stream già consumato
Stream<String> s = list.stream();
s.collect(Collectors.toList());
s.count(); // IllegalStateException
```

**Rischi e mitigazioni**  
- **Rischio**: Side-effect in `filter`/`map` (es. log, modifiche stato) rendono il comportamento non deterministico con parallel stream.  
- **Edge case**: Stream parallelo con `forEach` non garantisce ordine; per ordine usare `forEachOrdered`; `findFirst` preserva ordine, `findAny` no in parallelo.  
- **Mitigazione**: Mantenere operazioni intermedie pure; usare `collect` per aggregazioni; documentare se lo stream è usato in contesto parallelo.

---

### Immutabilità e collezioni non modificabili

**Definizione tecnica**  
L'immutabilità garantisce che un oggetto non cambi dopo la creazione; riduce bug da stato condiviso e semplifica thread-safety. Le collezioni possono essere rese non modificabili con `List.of()`, `Map.of()`, `Collections.unmodifiableList()`.

**Differenze pratiche**  
- **`List.of()`**: lista immutabile; null non supportato; `UnsupportedOperationException` su add/remove.  
- **`Collections.unmodifiableList(list)`**: vista sulla lista originale; se la lista sottostante cambia, la vista riflette le modifiche; non è una copia.

**Best practice applicabile**  
Preferire `List.of()`, `Map.of()` per dati costanti; usare `Collections.unmodifiableList(new ArrayList<>(...))` per copia difensiva; restituire collezioni immutabili da API pubbliche per evitare che i client modifichino lo stato interno; per record con `List` usare copie immutabili.

**Mini snippet**

```java
// Immutabile e null-free
List<String> fixed = List.of("a", "b", "c");

// Copia difensiva
List<String> defensive = Collections.unmodifiableList(new ArrayList<>(mutableList));

// Record con lista immutabile
public record Config(List<String> keys) {
    public Config(List<String> keys) {
        this.keys = List.copyOf(keys);
    }
}
```

**Rischi e mitigazioni**  
- **Rischio**: Restituire la lista interna senza copia permette ai client di modificarla; `unmodifiableList` su lista condivisa non protegge se qualcuno ha il riferimento alla lista originale.  
- **Edge case**: `List.of()` con `null` lancia `NullPointerException`; `List.of().add("x")` lancia `UnsupportedOperationException`; `Map.of("a", 1, "a", 2)` lancia `IllegalArgumentException` per chiave duplicata.  
- **Mitigazione**: Costruttori di record che copiano collezioni con `List.copyOf`; validare input prima di `List.of()`; documentare se le API restituiscono viste o copie.

---

## Concorrenza

### `synchronized` vs `ReentrantLock`: quando usare quale

**Definizione tecnica**  
`synchronized` è un costrutto del linguaggio che acquisisce il monitor dell'oggetto; `ReentrantLock` è una classe che offre lock espliciti con funzionalità aggiuntive (tryLock, lock timeout, fairness).

**Differenze pratiche**  
- **synchronized**: sintassi più semplice; rilascio automatico; nessun lock ordering esplicito (rischio deadlock).  
- **ReentrantLock**: `tryLock(timeout)` per evitare deadlock; `lockInterruptibly`; fairness opzionale; richiede `unlock` in `finally`.

**Best practice applicabile**  
Preferire `synchronized` per casi semplici; usare `ReentrantLock` quando serve tryLock, timeout o lock ordering; evitare lock a livello di metodo su oggetti esposti; usare `java.util.concurrent` (es. `ConcurrentHashMap`) invece di lock manuali quando possibile.

**Mini snippet**

```java
// synchronized semplice
public synchronized void increment() {
    count++;
}

// ReentrantLock con tryLock
ReentrantLock lock = new ReentrantLock();
public boolean tryIncrement() {
    if (lock.tryLock()) {
        try {
            count++;
            return true;
        } finally {
            lock.unlock();
        }
    }
    return false;
}
```

**Rischi e mitigazioni**  
- **Rischio**: Deadlock con lock multipli; ordine inconsistente (thread A lock X poi Y, thread B lock Y poi X).  
- **Edge case**: `synchronized` su un metodo non blocca altri metodi; per bloccare l'intero oggetto serve `synchronized(this)` o `synchronized` su tutti i metodi; `ReentrantLock` senza `unlock` in `finally` lascia il lock acquisito in caso di eccezione.  
- **Mitigazione**: Lock ordering globale (es. sempre X prima di Y); timeout su tryLock; usare `try-finally` per unlock.

---

### `ExecutorService` e gestione del thread pool

**Definizione tecnica**  
`ExecutorService` astrae l'esecuzione di task asincroni; gestisce un pool di thread riutilizzabili. `ThreadPoolExecutor` permette di configurare core size, max size, queue e rejection policy.

**Differenze pratiche**  
- **Fixed thread pool**: numero fisso di thread; `LinkedBlockingQueue` illimitata; rischio di OOM se i task arrivano più veloci di quanto vengono processati.  
- **Cached thread pool**: thread creati on-demand; adatto a task brevi e burst; può creare molti thread sotto carico.  
- **Scheduled pool**: per task periodici o ritardati.

**Best practice applicabile**  
Dimensionare il pool in base a CPU-bound vs I/O-bound; per I/O usare più thread di core; usare `submit` con `Future` per risultati; shutdown graceful con `awaitTermination`; evitare pool illimitati in produzione senza bounded queue.

**Mini snippet**

```java
ExecutorService executor = Executors.newFixedThreadPool(
    Runtime.getRuntime().availableProcessors(),
    new ThreadFactoryBuilder().setNameFormat("worker-%d").build()
);

Future<Result> future = executor.submit(() -> heavyComputation());
Result result = future.get(5, TimeUnit.SECONDS);

executor.shutdown();
if (!executor.awaitTermination(30, TimeUnit.SECONDS)) {
    executor.shutdownNow();
}
```

**Rischi e mitigazioni**  
- **Rischio**: Queue illimitata con `FixedThreadPool` può crescere fino a OOM; task non gestiti possono far terminare il thread silenziosamente.  
- **Edge case**: `Future.get()` blocca il thread chiamante; in servlet/API può bloccare il thread di I/O; usare `CompletableFuture` o callback per non bloccare; `RejectedExecutionException` se la queue è piena e la policy è Abort.  
- **Mitigazione**: Bounded queue con `ThreadPoolExecutor` custom; `UncaughtExceptionHandler` sul thread factory; monitoraggio della queue size e del pool.

---

## Eccezioni

### Checked vs unchecked: quando usare quale e gestione in produzione

**Definizione tecnica**  
Le eccezioni checked estendono `Exception` (non `RuntimeException`) e devono essere dichiarate o catturate; le unchecked estendono `RuntimeException` e non richiedono dichiarazione. Le eccezioni sono oggetti che propagano informazioni su errore e stack trace.

**Differenze pratiche**  
- **Checked**: per condizioni recuperabili che il chiamante deve gestire (es. `IOException`, `SQLException`); obbligano il caller a decidere.  
- **Unchecked**: per bug, invarianti violate, errori di programmazione; non obbligano il caller; in Spring la maggior parte delle eccezioni sono unchecked.

**Best practice applicabile**  
Usare checked per errori recuperabili dal chiamante; unchecked per errori di programmazione; non catturare `Exception` generico senza rethrow; wrappare checked in unchecked solo se serve (es. in lambda); loggare con contesto e stack trace; evitare `printStackTrace()` in produzione.

**Mini snippet**

```java
// Checked: il caller deve gestire
public void processFile(String path) throws IOException {
    try (var reader = Files.newBufferedReader(Path.of(path))) {
        // ...
    }
}

// Unchecked: eccezione di business
public void processOrder(Order order) {
    if (order.getItems().isEmpty()) {
        throw new IllegalStateException("Order must have at least one item");
    }
}

// Rethrow con contesto
try {
    externalService.call();
} catch (IOException e) {
    throw new BusinessException("Failed to call external service", e);
}
```

**Rischi e mitigazioni**  
- **Rischio**: Swallow di eccezioni (`catch (Exception e) {}`) nasconde errori; `throws Exception` su firma perde informazione.  
- **Edge case**: `Throwable` include `Error` (OutOfMemoryError, ecc.); non catturare `Throwable` a meno di necessità estrema; in `finally` un'eccezione può mascherare quella del try.  
- **Mitigazione**: Catch specifico; preservare cause con costruttore a due argomenti; `@ControllerAdvice` per gestione centralizzata in API; log strutturato con correlation ID.

---

## JVM Basics

### Garbage collection e memory model: heap, stack, tipi di GC

**Definizione tecnica**  
Lo heap contiene gli oggetti; lo stack contiene frame per thread (variabili locali, riferimenti). Il GC recupera memoria da oggetti non più raggiungibili. Generazioni: Young (Eden, Survivor) per oggetti short-lived; Old per oggetti long-lived.

**Differenze pratiche**  
- **Serial GC**: single-thread, per app piccole.  
- **Parallel GC**: multi-thread per throughput, minor pause.  
- **G1 GC**: balance throughput/latency; pause target configurabili; default da Java 9.  
- **ZGC/Shenandoah**: pause ultra-basse, indipendenti dalla heap size; per applicazioni low-latency.

**Best practice applicabile**  
Dimensionare heap con `-Xms` e `-Xmx` uguali per evitare resize; monitorare con GC logs e metriche; per microservizi con limiti di memoria usare G1; per latenza critica valutare ZGC; evitare riferimenti inutili che impediscono il GC (es. listener non rimossi).

**Mini snippet**

```bash
# Esempio di avvio con G1
java -Xms512m -Xmx512m -XX:+UseG1GC \
     -XX:MaxGCPauseMillis=200 \
     -Xlog:gc*:file=gc.log \
     -jar app.jar
```

**Rischi e mitigazioni**  
- **Rischio**: Heap troppo piccolo causa GC frequenti e pause; heap troppo grande aumenta pause con GC non low-latency.  
- **Edge case**: Memory leak in Java: oggetti non più usati ma ancora referenziati (es. cache senza eviction, listener non registrati); `OutOfMemoryError` può essere su heap o su Metaspace (classi); `-XX:MaxMetaspaceSize` per limitare Metaspace.  
- **Mitigazione**: Heap dump con `-XX:+HeapDumpOnOutOfMemoryError`; profilare con VisualVM/JFR; weak/soft reference per cache; evitare retention di oggetti grandi in collezioni statiche.

---

## Records e sealed

### Records (Java 16+)
**Definizione tecnica**  
Un record è un tipo immutabile che dichiara solo lo stato (componenti): il compilatore genera costruttore canonico, `equals`, `hashCode`, `toString` e accessor. Ideale per DTO, chiavi, risultato di query.

**Differenze pratiche**  
- Record è final; non può estendere altre classi; può implementare interfacce.  
- I campi sono `private final`; non si possono aggiungere campi di istanza (solo static).  
- Compact constructor per validazione senza dichiarare parametri esplicitamente.

**Best practice applicabile**  
Usare record per dati che non mutano e dove uguaglianza per valore ha senso; evitare per entità JPA (serve proxy e mutabilità per lazy loading) o dove serve ereditarietà.

**Mini snippet**

```java
public record UserId(String value) {
    public UserId { if (value == null || value.isBlank()) throw new IllegalArgumentException(); }
}
record Point(int x, int y) {}
```

**Rischi e mitigazioni**  
- **Rischio**: Serializzazione: assicurarsi che componenti siano serializzabili; in JPA preferire class/entity.  
- **Edge case**: Record con un solo componente: il nome dell'accessor è quello del componente (non "getValue").

### Sealed classes e interfaces (Java 17+)
**Definizione tecnica**  
Una sealed class/interface limita quali classi possono estenderla o implementarla; permette exhaustive switch e pattern matching senza default branch per tutti i sottotipi noti.

**Differenze pratiche**  
- Si dichiara `sealed class Shape permits Circle, Rectangle, Square`.  
- I permessi devono essere sottotipi diretti (stesso modulo o stesso package).  
- I sottotipi devono essere final, sealed o non-sealed.

**Best practice applicabile**  
Usare per gerarchie chiuse (comandi, eventi, nodi AST) dove si vogliono esaurire i casi in uno switch; migliora manutenibilità (aggiungere un nuovo sottotipo obbliga a gestirlo).

**Mini snippet**

```java
sealed interface Result<T> permits Ok<T>, Err<T> {}
record Ok<T>(T value) implements Result<T> {}
record Err<T>(Exception e) implements Result<T> {}
```

**Rischi e mitigazioni**  
- **Rischio**: Refactoring: aggiungere un nuovo permesso richiede aggiornare tutti gli switch che usano il tipo; pianificare i permessi in anticipo.

---

## Pattern matching

### Pattern matching per instanceof e switch (Java 16+ / 21+)
**Definizione tecnica**  
`instanceof` con pattern: `if (obj instanceof String s)` introduce la variabile `s` già castata nello scope del blocco. Switch con pattern: `switch (obj)` può avere case con tipi e pattern, con possibile exhaustiveness.

**Differenze pratiche**  
- instanceof pattern evita cast esplicito e riduce boilerplate.  
- Switch expressions con pattern (Java 21): `case Point(int x, int y) -> x + y`; null case esplicito; guarded pattern con `when`.

**Best practice applicabile**  
Usare per sostituire catene if-instanceof-cast; per sealed/record, lo switch può essere esauriente senza default. Evitare pattern troppo annidati che riducono leggibilità.

**Mini snippet**

```java
if (obj instanceof String s && s.length() > 0) {
    return s.toUpperCase();
}
return switch (result) {
    case Ok(var v) -> v;
    case Err(Exception e) -> throw e;
};
```

**Rischi e mitigazioni**  
- **Edge case**: La variabile del pattern è in scope solo dove è "definitivamente assegnata"; attenzione con early return o eccezioni.

---

## Optional e try-with-resources

### Optional: uso corretto
**Definizione tecnica**  
`Optional<T>` rappresenta un valore che può essere assente; evita null e rende esplicita l'assenza. Metodi: `of`, `ofNullable`, `empty`, `isPresent`, `ifPresent`, `orElse`, `orElseGet`, `orElseThrow`, `map`, `flatMap`, `filter`.

**Differenze pratiche**  
- Non usare `Optional.get()` senza aver verificato `isPresent()`: lancia NoSuchElementException se vuoto.  
- Preferire `orElseThrow()` per "obbligatorio" e `orElseGet()` per fallback costoso (lazy).  
- Optional non è pensato per campi di entità o parametri; preferire per ritorno di metodi che possono "non trovare" un valore.

**Best practice applicabile**  
Usare Optional come tipo di ritorno; evitare Optional come campo (serializzazione, JPA); non usare in collezioni (List<Optional<T>> è anti-pattern; preferire lista senza null).

**Mini snippet**

```java
return userRepository.findById(id)
    .orElseThrow(() -> new NotFoundException("User " + id));
Optional.ofNullable(value).ifPresent(v -> log.info(v));
```

**Rischi e mitigazioni**  
- **Rischio**: Optional.get() senza check; wrapping null in Optional.of() (usare ofNullable).  
- **Mitigazione**: Preferire orElseThrow con eccezione di dominio; evitare Optional per parametri (overhead e poco valore).

### Try-with-resources e AutoCloseable
**Definizione tecnica**  
Try-with-resources garantisce la chiusura di risorse che implementano `AutoCloseable` (e quindi `Closeable`); la chiusura avviene in ordine inverso alla dichiarazione; le eccezioni soppresse vengono aggiunte a quella principale.

**Differenze pratiche**  
- Sintassi: `try (var r = new Resource()) { ... }`; multipla: `try (var a = ...; var b = ...)`.  
- `close()` viene chiamato anche in caso di eccezione nel blocco; se sia il blocco sia close() lanciano, l'eccezione di close è soppressa (getSuppressed()).

**Best practice applicabile**  
Usare sempre try-with-resources per stream, connection, reader/writer; evitare finally manuale per chiudere; le risorse devono essere effectively final nel try.

**Mini snippet**

```java
try (var conn = dataSource.getConnection();
     var stmt = conn.prepareStatement("SELECT 1")) {
    var rs = stmt.executeQuery();
    // ...
}
```

**Rischi e mitigazioni**  
- **Rischio**: Risorsa non AutoCloseable; eccezione in close() che nasconde l'eccezione originale (controllare getSuppressed()).  
- **Edge case**: Risorse che possono essere null: dichiarare nella clausola solo se non null o usare Optional/if.

---

## Module system (JPMS)

### Moduli Java 9+: exports e readability
**Definizione tecnica**  
Il Java Platform Module System (JPMS) introduce il file `module-info.java` che dichiara nome del modulo, dipendenze (`requires`) e pacchetti esportati (`exports`). Il classpath viene sostituito (o affiancato) dal module path.

**Differenze pratiche**  
- `requires moduleName`: il modulo corrente dipende da un altro; `exports pkg`: il pacchetto è pubblico per altri moduli.  
- `requires transitive`: il modulo che richiede il nostro vede anche le nostre dipendenze transitive.  
- `opens pkg`: necessario per reflection (JPA, Jackson) su tipi non pubblici.

**Best practice applicabile**  
In progetti enterprise, modulare per strong encapsulation e dipendenze esplicite; le librerie legacy senza module-info sono "automatic modules". Evitare `opens` indiscriminato per sicurezza.

**Mini snippet**

```java
module com.app.service {
    requires transitive com.app.domain;
    exports com.app.service.api;
    opens com.app.service.impl to spring.core;
}
```

**Rischi e mitigazioni**  
- **Rischio**: Reflection (Spring, JPA) richiede `opens` sui pacchetti con bean/entity; altrimenti IllegalAccessException.  
- **Edge case**: Migrazione da classpath: verificare tutti i requires e le split package (stesso package in più JAR).

---

## CompletableFuture

### Async composable vs ExecutorService
**Definizione tecnica**  
`CompletableFuture<T>` rappresenta un risultato asincrono componibile con `thenApply`, `thenCompose`, `thenCombine`, `allOf`, `anyOf`; si completa con `complete(value)` o `completeExceptionally`. Sostituisce in molti casi Future + ExecutorService per pipeline async.

**Differenze pratiche**  
- ExecutorService: submit task e si ottiene Future; per concatenare servono callback manuali o bloccare con get().  
- CompletableFuture: non bloccare; usare thenApply/thenCompose per catene; supplyAsync/runAsync per avviare su un Executor; eccezioni con handle/exceptionally.

**Best practice applicabile**  
Usare CompletableFuture per chiamate async multiple da combinare (es. più API); passare un Executor dedicato a supplyAsync per non saturare il common pool; evitare get() senza timeout in codice non bloccante.

**Mini snippet**

```java
CompletableFuture<User> user = CompletableFuture.supplyAsync(() -> userRepo.find(id), executor);
CompletableFuture<List<Order>> orders = user.thenCompose(u -> orderRepo.findByUser(u.getId()));
CompletableFuture.allOf(user, orders).thenRun(() -> { ... });
```

**Rischi e mitigazioni**  
- **Rischio**: Eccezioni non gestite in thenApply che falliscono silenziosamente; usare handle o exceptionally.  
- **Edge case**: Thread pool: supplyAsync senza executor usa ForkJoinPool.commonPool(); in container (es. Tomcat) preferire pool dedicato per evitare starvation.

## In sintesi

- Incapsulamento, ereditarietà e polimorfismo: preferire composizione e interfacce; evitare ereditarietà profonda.
- `equals` e `hashCode` vanno overridati insieme e devono essere coerenti; usare gli stessi campi significativi; con `record` sono generati automaticamente.
- `ArrayList` per accesso per indice O(1); `LinkedList` per inserimenti in testa/coda con riferimento al nodo; in dubbio preferire `ArrayList`.
- Stream sono lazy; evitare side effect nelle operazioni intermedie; usare collezioni non modificabili dove possibile.
- `synchronized` vs `ReentrantLock`: il primo più semplice, il secondo per timeout e fairness; preferire `ExecutorService` per gestione pool.
- Eccezioni checked per errori recuperabili e contratto; unchecked per bug e validazione; non ingoiare eccezioni.
- GC: heap, stack, Metaspace; G1 per bassa latenza; profilare con JFR/VisualVM in caso di pause.
- Record per DTO immutabili; sealed per gerarchie chiuse; pattern matching per instanceof e switch; Optional per ritorni opzionali; try-with-resources per risorse; JPMS per moduli; CompletableFuture per async composable.

## Vedi anche

- [Spring Boot](springboot.md) — IoC, DI e contesto applicativo Java.
- [Database](database.md) — Transazioni, connection pool e integrazione con JPA.
