# Python

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Mutabilità, immutabilità e passaggio argomenti](#mutabilita-immutabilita-e-passaggio-argomenti)
- [OOP e stile funzionale](#oop-e-stile-funzionale)
- [Type hints e dataclass](#type-hints-e-dataclass)
- [Contenitori: list, dict, set](#contenitori-list-dict-set)
- [Context manager e decorator](#context-manager-e-decorator)
- [Async e asyncio](#async-e-asyncio)
- [Ambiente: virtualenv, venv, pip](#ambiente-virtualenv-venv-pip)
- [Eccezioni e buone pratiche](#eccezioni-e-buone-pratiche)
- [Descriptor, property e iteratori](#descriptor-property-e-iteratori)
- [Pattern matching e import](#pattern-matching-e-import)
- [Logging e packaging](#logging-e-packaging)
- [Concorrenza: thread, processi, async](#concorrenza-thread-processi-async)

## Panoramica

Python è un linguaggio interpretato, tipizzato dinamicamente, con enfasi su leggibilità e produttività. Supporta paradigmi multipli (OOP, funzionale, imperativo), garbage collection automatico e un ecosistema ricco per scripting, backend e data. In produzione si appoggia su type hints per manutenibilità, contenitori built-in per dati, async per I/O bound e ambienti isolati (venv) per le dipendenze.

---

## Mutabilità, immutabilità e passaggio argomenti

### Passaggio per riferimento e mutabilità

**Definizione tecnica**  
In Python gli argomenti sono passati per **assegnazione di riferimento**: la funzione riceve il riferimento all’oggetto, non una copia. Se l’oggetto è mutabile (list, dict), le modifiche in-place sono visibili al chiamante; riassegnare il nome dentro la funzione non modifica l’oggetto originale.

**Differenze pratiche**  
- Tipi immutabili: `int`, `str`, `tuple`, `frozenset` — non si può cambiare il valore “sul posto”; ogni “modifica” crea un nuovo oggetto.  
- Tipi mutabili: `list`, `dict`, `set` — modifiche con `.append()`, `dict[k] = v` ecc. si riflettono ovunque sia usato lo stesso riferimento.  
- `id(obj)` restituisce l’identità dell’oggetto in memoria; due riferimenti allo stesso oggetto hanno lo stesso `id`.

**Best practice applicabile**  
Evitare di mutare argomenti ricevuti in funzione se non è esplicitamente il contratto; per “restituire” più valori preferire tuple o dataclass. Usare copie esplicite (`list(seq)`, `dict.copy()`, `copy.deepcopy`) quando serve isolamento.

**Mini snippet**

```python
def append_item(lst, item):
    lst.append(item)  # modifica l'oggetto condiviso

def replace_list(lst, item):
    lst = lst + [item]  # crea nuova list, non modifica l'originale

a = [1, 2]
append_item(a, 3)   # a diventa [1, 2, 3]
replace_list(a, 4)  # a resta [1, 2, 3]
```

**Errori comuni e rischi**  
- **Rischio**: Default mutabili in firma (`def f(x=[])`) creano un’unica lista condivisa tra tutte le chiamate senza argomento.  
- **Mitigazione**: Usare `def f(x=None)` e `if x is None: x = []` per default immutabili in pratica.

---

### list vs tuple: quando usare quale

**Definizione tecnica**  
`list` è una sequenza mutabile, indicizzata e ordinata; `tuple` è una sequenza immutabile. Entrambe sono ordinati e supportano indicizzazione e slice.

**Differenze pratiche**  
- **list**: per collezioni che cambiano (append, remove, sort); uso tipico: risultati dinamici, buffer, accumuli.  
- **tuple**: per record fissi (es. coordinate, righe di DB), chiavi di dizionario, valori di ritorno multipli; hashable se tutti gli elementi lo sono, quindi utilizzabile in `set` e come chiave in `dict`.

**Best practice applicabile**  
Preferire tuple per dati che non devono cambiare (immutabilità come documento); usare list quando serve modificare la collezione. Tuple spesso più leggere in memoria e leggermente più veloci per accesso.

**Mini snippet**

```python
# Record immutabile
point = (10, 20)
user_row = (1, "Mario", "mario@example.com")

# Chiave in dict (solo hashable)
cache = {}
cache[(1, 2)] = "valore"

# Ritorno multiplo
def get_user():
    return 1, "Mario"  # tuple implicita
```

**Errori comuni**  
- Modificare un elemento di una tuple causa `TypeError`; per “cambiare” si crea una nuova tuple (slice o unpack).

---

## OOP e stile funzionale

### OOP in Python: classi, ereditarietà e composizione

**Definizione tecnica**  
Python è OOP: tutto è oggetto; le classi definiscono attributi e metodi; l’ereditarietà permette di estendere e sovrascrivere; il polimorfismo è duck typing (l’interfaccia è l’uso, non la dichiarazione).

**Differenze pratiche**  
- Ereditarietà: `class B(A)`; `super()` per delegare al padre; multipla consentita (MRO).  
- Composizione: preferibile quando non c’è relazione “is-a” forte; si incapsulano altri oggetti come attributi invece di ereditare.

**Best practice applicabile**  
Preferire composizione a ereditarietà per ridurre accoppiamento; usare type hints e (se utile) `@dataclass` per chiarezza; evitare gerarchie profonde.

**Mini snippet**

```python
class Repository:
    def __init__(self, connection):
        self._conn = connection  # composizione

class UserService:
    def __init__(self, repo: Repository):
        self._repo = repo
```

**Rischi**  
- Ereditarietà multipla e MRO possono generare comportamenti non ovvi; limitare a mix-in ben definiti.

---

### Stile funzionale: first-class, map, filter, quando preferirlo

**Definizione tecnica**  
Le funzioni sono first-class: si possono assegnare, passare e restituire. `map`, `filter`, funzioni in `functools` (es. `reduce`) e list comprehension permettono stile dichiarativo.

**Differenze pratiche**  
- **map/filter**: trasformazioni e filtri su iterabili; in Python 3 restituiscono iteratori (lazy).  
- **List/dict comprehension**: spesso più leggibili per trasformazioni semplici; controllare che non diventino troppo lunghe.

**Best practice applicabile**  
Usare stile funzionale per pipeline di trasformazione dati; preferire comprehension quando è più leggibile di map/filter annidati. Per logica complessa, un ciclo esplicito è spesso più chiaro.

**Mini snippet**

```python
names = [u["name"] for u in users if u.get("active")]
squares = [x**2 for x in range(10)]
```

**Errori comuni**  
- `map`/`filter` con lambda lunghe riducono leggibilità; in quel caso loop o comprehension sono preferibili.

---

### *args e **kwargs: significato e uso

**Definizione tecnica**  
`*args` raccoglie gli argomenti posizionali in una tuple; `**kwargs` raccoglie gli argomenti a parola chiave in un dict. Servono per funzioni variadiche o per inoltrare parametri senza conoscerli tutti.

**Differenze pratiche**  
- `*args`: numero variabile di argomenti posizionali.  
- `**kwargs`: numero variabile di keyword arguments; utile per opzioni e configurazioni passate in blocco.

**Best practice applicabile**  
Usarli in wrapper, decorator e API che devono inoltrare chiamate; documentare quali keyword sono supportate quando si usa `**kwargs`.

**Mini snippet**

```python
def log_call(f):
    def wrapper(*args, **kwargs):
        print("Calling", f.__name__)
        return f(*args, **kwargs)
    return wrapper
```

**Rischi**  
- Mascherare la firma reale della funzione; preferire firme esplicite quando il numero di parametri è stabile.

---

## Type hints e dataclass

### Type hints e dataclass: perché e quando

**Definizione tecnica**  
I type hints annotano tipi di parametri, ritorno e attributi; non sono verificati a runtime ma abilitano tool (mypy, IDE). `@dataclass` (da Python 3.7) genera automaticamente `__init__`, `__repr__` e opzionalmente `__eq__` per classi che sono soprattutto “contenitori di dati”.

**Differenze pratiche**  
- Type hints: migliorano documentazione e manutenibilità; mypy trova molti errori prima dell’esecuzione.  
- dataclass: riducono boilerplate rispetto a una classe con `__init__` manuale; adatte a DTO, configurazioni, record.

**Best practice applicabile**  
Usare type hints sulle API pubbliche e sui punti di ingresso; adottare dataclass per strutture dati senza logica complessa. `frozen=True` per dataclass immutabili.

**Mini snippet**

```python
from dataclasses import dataclass

@dataclass
class User:
    id: int
    name: str
    email: str | None = None
```

**Errori comuni**  
- Non eseguire mypy in CI: gli hint restano solo documentazione. Includere mypy (o pyright) nel flusso di qualità.

---

## Contenitori: list, dict, set

### list, dict, set: caratteristiche e complessità

**Definizione tecnica**  
`list`: array dinamico, accesso per indice O(1), append ammortizzato O(1), insert in mezzo O(n). `dict`: hash table, lookup/insert/delete O(1) ammortizzato; chiavi devono essere hashable. `set`: insieme di elementi unici, hashable; operazioni membership O(1) ammortizzato.

**Differenze pratiche**  
- **list**: ordinata, duplicati ammessi, indicizzata.  
- **dict**: coppie chiave-valore, chiavi uniche.  
- **set**: solo chiavi, unicità, nessun ordine garantito (in Python 3.7+ dict mantiene ordine di inserimento).

**Best practice applicabile**  
Usare set per membership e unicità; dict per lookup per chiave; list per sequenze ordinate e quando serve indicizzazione.

**Mini snippet**

```python
seen = set()
for x in items:
    if x in seen:
        continue
    seen.add(x)
    process(x)
```

**Errori comuni**  
- Mettere in set o come chiave di dict oggetti mutabili (es. list) causa `TypeError`; usare tuple o frozenset se servono collezioni hashable.

---

### List comprehension vs generator: memoria e lazy evaluation

**Definizione tecnica**  
List comprehension `[expr for x in it]` costruisce subito una lista in memoria. Generator expression `(expr for x in it)` restituisce un iteratore: valori prodotti on-demand (lazy). Una funzione con `yield` è una generator function.

**Differenze pratiche**  
- Comprehension: tutto in memoria; uso quando serve accedere più volte o per indice.  
- Generator: un solo valore alla volta; ideale per pipeline lunghe o dati grandi; si consuma una sola volta.

**Best practice applicabile**  
Preferire generator (o generator expression) per flussi di dati grandi o infiniti; usare list comprehension quando serve materializzare la sequenza.

**Mini snippet**

```python
# Tutto in memoria
squares_list = [x**2 for x in range(1_000_000)]

# Lazy, un valore alla volta
squares_gen = (x**2 for x in range(1_000_000))
total = sum(squares_gen)
```

**Errori comuni**  
- Iterare due volte sullo stesso generator: la seconda volta è vuoto. Se serve riuso, materializzare in list (se la dimensione è accettabile).

---

## Context manager e decorator

### Context manager: with, __enter__, __exit__

**Definizione tecnica**  
Un context manager garantisce codice di setup e teardown (es. apri/chiudi risorsa). Si usa con `with cm(): ...`. Implementazione: metodi `__enter__` e `__exit__`; oppure `contextlib.contextmanager` con generator che fa `yield`.

**Differenze pratiche**  
- `__exit__` riceve eventuale eccezione; se restituisce valore truthy, l’eccezione viene soppressa (usare con cautela).  
- `contextlib.contextmanager` riduce il boilerplate per casi semplici.

**Best practice applicabile**  
Usare `with` per file, lock, connessioni e qualsiasi risorsa che deve essere rilasciata; preferire `contextlib` per manager semplici.

**Mini snippet**

```python
from contextlib import contextmanager

@contextmanager
def managed_conn():
    conn = open_connection()
    try:
        yield conn
    finally:
        conn.close()

with managed_conn() as c:
    c.execute(...)
```

**Rischi**  
- Sopprimere eccezioni in `__exit__` senza rilanciare o loggare può nascondere bug; in `finally` rilasciare sempre la risorsa.

---

### Decorator: funzione che prende una funzione

**Definizione tecnica**  
Un decorator è una funzione (o callable) che prende una funzione e ne restituisce un’altra, tipicamente un wrapper che aggiunge comportamento (logging, cache, auth). Sintassi: `@deco` sopra la definizione della funzione.

**Differenze pratiche**  
- Senza parametri: `deco` riceve la funzione e restituisce il wrapper.  
- Con parametri: serve un livello in più (decorator che restituisce un decorator).

**Best practice applicabile**  
Usare `functools.wraps(f)` nel wrapper per preservare `__name__` e `__doc__`; limitare la logica nel decorator a cross-cutting concerns.

**Mini snippet**

```python
from functools import wraps

def log_calls(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        print(f"Calling {f.__name__}")
        return f(*args, **kwargs)
    return wrapper

@log_calls
def compute():
    return 42
```

**Errori comuni**  
- Dimenticare `wraps`: stack trace e help mostrano il wrapper invece della funzione originale. Decorator che mutano firma o ritorno in modo non documentato rendono il codice difficile da capire.

---

## Async e asyncio

### GIL: cos’è e implicazioni per CPU-bound vs I/O-bound

**Definizione tecnica**  
Il Global Interpreter Lock (GIL) è un mutex che in CPython permette a un solo thread di eseguire bytecode Python alla volta. I thread condividono la stessa memoria ma non sfruttano multipli core per codice Python puro.

**Differenze pratiche**  
- **I/O-bound**: thread o async vanno bene; durante le operazioni I/O il GIL viene rilasciato, quindi altri thread possono girare.  
- **CPU-bound**: un solo core usato per codice Python; per parallelismo CPU-bound usare `multiprocessing` o delegare a librerie che rilasciano il GIL (es. numpy, C extension).

**Best practice applicabile**  
Per I/O-bound (API, DB, file) preferire asyncio o thread a seconda del contesto; per CPU-bound usare `multiprocessing` o job in processi separati.

**Errori comuni**  
- Aspettarsi speedup lineare con `threading` su carichi CPU-bound; non accade a causa del GIL.

---

### asyncio base: async/await, I/O bound, run_in_executor

**Definizione tecnica**  
`asyncio` offre un event loop e coroutine: funzioni dichiarate con `async def` che possono `await` altre coroutine o operazioni non bloccanti. Ideale per I/O-bound concorrente (molte connessioni, attese su rete/DB).

**Differenze pratiche**  
- `async def`: la funzione restituisce una coroutine; va eseguita con `await` o dall’event loop.  
- `await`: cede il controllo fino al completamento dell’operazione; non blocca il thread.  
- Codice sincrono bloccante (es. `time.sleep`, I/O sincrono) blocca l’intero loop; per eseguirlo senza bloccare usare `run_in_executor`.

**Best practice applicabile**  
Usare librerie async-native per DB e HTTP (es. `asyncpg`, `httpx`); non chiamare routine bloccanti dentro una coroutine senza `run_in_executor`. Avviare l’applicazione con `asyncio.run()` nel punto di ingresso.

**Mini snippet**

```python
import asyncio

async def fetch(url):
    # simulazione: in pratica usare httpx o aiohttp
    await asyncio.sleep(0.1)
    return url

async def main():
    results = await asyncio.gather(fetch("u1"), fetch("u2"))
    return results

asyncio.run(main())
```

**Rischi**  
- Mescolare I/O bloccante in coroutine senza `run_in_executor` degrada le performance e annulla i benefici dell’async.

---

## Ambiente: virtualenv, venv, pip

### virtualenv e venv: isolamento dipendenze

**Definizione tecnica**  
Un ambiente virtuale è una directory che contiene un’installazione Python isolata e una propria `site-packages`. Le dipendenze installate con `pip` restano confinate all’ambiente; si attiva con `source venv/bin/activate` (Unix) o `venv\Scripts\activate` (Windows).

**Differenze pratiche**  
- `python -m venv .venv`: modulo built-in (Python 3.3+), nessun pacchetto aggiuntivo.  
- `virtualenv`: strumento esterno, più opzioni (es. Python diversi). Per la maggior parte dei progetti `venv` è sufficiente.

**Best practice applicabile**  
Un ambiente per progetto; non committare la cartella dell’ambiente; documentare in README il comando di attivazione; usare `requirements.txt` (o pyproject.toml) per le dipendenze.

**Mini snippet**

```bash
python -m venv .venv
.venv\Scripts\activate   # Windows
pip install -r requirements.txt
pip freeze > requirements.txt  # aggiornare dipendenze
```

**Errori comuni**  
- Eseguire l’applicazione senza aver attivato l’ambiente: si usano i pacchetti di sistema e si possono avere versioni incoerenti. In CI/CD creare e attivare sempre un venv prima di `pip install`.

---

## Eccezioni e buone pratiche

### Gerarchia eccezioni, catch mirato, rilancio

**Definizione tecnica**  
Le eccezioni sono classi che ereditano da `BaseException`; per il codice applicativo si usa `Exception`. `try/except/finally` gestiscono il flusso; `raise` rilancia; `raise from` preserva la catena delle cause.

**Differenze pratiche**  
- Catch il più specifico possibile: evitare `except Exception` se si può gestire solo `ValueError` o `KeyError`.  
- `except Exception as e: raise RuntimeError("context") from e` mantiene la causa in `__cause__` e negli stack trace.

**Best practice applicabile**  
Non catturare senza gestire (evitare `except: pass`); loggare e/o rilanciare con contesto; usare `finally` per cleanup; definire eccezioni custom per il dominio quando utile.

**Mini snippet**

```python
try:
    value = int(text)
except ValueError as e:
    logger.warning("Invalid input: %s", text)
    raise ValidationError(f"Expected number, got {text!r}") from e
```

**Errori comuni**  
- Catturare `Exception` in punti troppo ampi nasconde bug; catturare solo ciò che si sa gestire e rilanciare il resto.

---

## Descriptor, property e iteratori

### Descriptor e @property
**Definizione tecnica**  
Un descriptor è un oggetto che implementa `__get__`, `__set__` o `__delete__` e controlla l'accesso ad attributi su altre classi. `@property` è un descriptor built-in: trasforma un metodo in attributo in lettura (e opzionalmente in scrittura con setter/deleter).

**Differenze pratiche**  
- property: validazione, valori derivati, attributi read-only; si usa per API pulita senza getter/setter espliciti.  
- Descriptor protocol: usato da property, classmethod, staticmethod; per librerie e framework (ORM, validazione).  
- setter/deleter: `@prop.setter`, `@prop.deleter` per assegnazione e del.

**Best practice applicabile**  
Usare property per attributi derivati o con validazione; evitare logica pesante in property (lazy o metodo esplicito); per descriptor custom documentare il comportamento.

**Mini snippet**

```python
class C:
    def __init__(self): self._x = 0
    @property
    def x(self): return self._x
    @x.setter
    def x(self, v):
        if v < 0: raise ValueError("must be >= 0")
        self._x = v
```

**Errori comuni**  
- Property che ha side effect pesanti o I/O; usare property per operazioni che l'utente non si aspetta siano lente.

### Iteratori e generatori (yield)
**Definizione tecnica**  
Un iteratore implementa `__iter__` e `__next__`; un generatore è una funzione che usa `yield` e restituisce un iterator senza definire una classe. I generatori sono lazy: producono valori on demand e consumano meno memoria.

**Differenze pratiche**  
- `for x in gen()` consuma un valore alla volta; con list(gen()) si materializza tutto.  
- yield from delega a un sub-generatore.  
- Generator expression: `(x*2 for x in seq)` è un generatore (parentesi tonde); list comprehension con [] materializza.

**Best practice applicabile**  
Usare generatori per flussi grandi o infiniti; evitare di iterare due volte sullo stesso generatore (è consumato); per pipeline di trasformazioni, generatori concatenati sono efficienti.

**Mini snippet**

```python
def read_lines(path):
    with open(path) as f:
        for line in f:
            yield line.strip()
```

**Errori comuni**  
- Iterare due volte sullo stesso generatore; mescolare return con yield (return termina il generatore).

---

## Pattern matching e import

### Pattern matching (match/case) Python 3.10+
**Definizione tecnica**  
`match`/`case` permette di confrontare un valore con pattern (literal, sequence, mapping, class con attributi). Sostituisce catene di if/elif su tipo o struttura; supporta guard con `if` nella case.

**Differenze pratiche**  
- case con tipo: `case int(x):` cattura un int e lo lega a x.  
- case con struttura: `case [a, b, *rest]:` per liste; `case {"key": val}` per dict.  
- _ per wildcard; | per più alternative in un case.

**Best practice applicabile**  
Usare per dispatch su tipo o su strutture (risposte API, AST); evitare match troppo profondi che riducono leggibilità.

**Mini snippet**

```python
match response:
    case {"status": 200, "data": data}:
        return data
    case {"status": 404}:
        raise NotFound()
    case _:
        raise UnknownStatus()
```

**Errori comuni**  
- Catturare tutto con case _ senza gestire casi inattesi; pattern che catturano troppo (es. dict senza controllare chiavi).

### Import e namespace: __all__, circular import
**Definizione tecnica**  
`import lib` carica il modulo e crea il nome `lib`; `from lib import x` aggiunge `x` nello namespace corrente. `__all__` in un modulo definisce cosa viene esportato con `from m import *`. Circular import: A importa B e B importa A; si risolve spostando l'import dentro le funzioni o riorganizzando i moduli.

**Differenze pratiche**  
- importlib.reload(m) per ricaricare in sviluppo.  
- Circular: evitare import a livello modulo in cima a entrambi; usare import locale o dependency injection.  
- __all__: utile per API pubbliche di un package; limita * e documenta l'API.

**Best practice applicabile**  
Import assoluti per progetti con package; evitare import * in produzione; __all__ nei package pubblici; risolvere circular con struttura o import lazy.

**Mini snippet**

```python
# pkg/__init__.py
__all__ = ["PublicClass", "public_func"]
```

**Errori comuni**  
- Circular import non risolto (ImportError o comportamento inconsistente); import * senza __all__ che espone nomi interni.

---

## Logging e packaging

### Logging (logging module)
**Definizione tecnica**  
Il modulo `logging` fornisce logger gerarchici (per nome, es. `logging.getLogger(__name__)`), livelli (DEBUG, INFO, WARNING, ERROR, CRITICAL), handler (Stream, File, SysLog) e formatter. La configurazione può essere a codice o con dictConfig/fileConfig.

**Differenze pratiche**  
- getLogger(__name__) per logger per modulo; propagazione verso root.  
- Formatter: %(name)s, %(levelname)s, %(message)s, %(asctime)s.  
- In produzione: livello INFO o WARNING; handler su file o syslog; evitare print per log strutturati.

**Best practice applicabile**  
Configurare in un solo punto (all'avvio); usare livello appropriato (DEBUG in dev, INFO in prod); per JSON strutturato usare formatter custom o librerie (structlog).

**Mini snippet**

```python
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s %(message)s")
logger = logging.getLogger(__name__)
logger.info("User %s logged in", user_id)
```

**Errori comuni**  
- Configurare logging in ogni modulo; loggare stringhe formattate con % con dati sensibili; non ruotare i file di log.

### Packaging (pyproject.toml, setuptools)
**Definizione tecnica**  
`pyproject.toml` (PEP 518/621) è il file di configurazione per build system e metadati del package. Con setuptools si definiscono dipendenze, entry point, package da includere. Build: `python -m build`; install in editable: `pip install -e .`.

**Differenze pratiche**  
- [build-system] requires e build-backend; [project] name, version, dependencies, optional-dependencies.  
- Entry points per plugin e CLI: `[project.scripts]` o `[project.entry-points.group]`.  
- Per pubblicare: twine upload su PyPI.

**Best practice applicabile**  
Versionare le dipendenze con range (>=, ~=); usare optional-dependencies per feature (dev, test); evitare versioni fisse dove non necessario.

**Mini snippet**

```toml
[project]
name = "myapp"
version = "0.1.0"
dependencies = ["fastapi>=0.100", "pydantic>=2"]
[project.optional-dependencies]
dev = ["pytest", "ruff"]
```

**Errori comuni**  
- Non includere tutti i file necessari (MANIFEST.in o pyproject include); dipendenze mancanti in install_requires.

---

## Concorrenza: thread, processi, async

### Threading vs multiprocessing vs async
**Definizione tecnica**  
- **threading**: più thread nello stesso processo; condividono memoria; GIL limita l'uso della CPU a un thread per volta per il bytecode Python. Adatto a I/O bound.  
- **multiprocessing**: più processi; nessun GIL; memoria separata; overhead di comunicazione (pickle, queue). Adatto a CPU bound.  
- **asyncio**: single-thread, I/O non bloccante; coroutine con async/await; adatto a I/O bound con molte connessioni.

**Differenze pratiche**  
- I/O bound (rete, disco): asyncio o threading; asyncio scala meglio con molte connessioni.  
- CPU bound (calcoli): multiprocessing o esternalizzare (C extension, altro processo).  
- Non mescolare threading e asyncio senza attenzione (run_in_executor per bloccare in async).

**Best practice applicabile**  
Scegliere in base al collo di bottiglia; asyncio per API e client HTTP; multiprocessing per batch pesanti; evitare troppi thread per GIL.

**Mini snippet**

```python
# asyncio per I/O
async def fetch_all(): return await asyncio.gather(*[fetch(url) for url in urls])
# multiprocessing per CPU
with multiprocessing.Pool(4) as p: results = p.map(heavy_func, data)
```

**Errori comuni**  
- Usare thread per CPU bound (GIL); bloccare il loop asyncio con codice sincrono; dimenticare join/await per cleanup.

---

## In sintesi

- Tipizzazione: type hints per documentazione e tool; runtime non enforced; usare typing e generics per API chiare.
- List vs tuple: lista mutabile, tuple immutabile e hashable; generator per flussi lazy e memoria.
- Context manager: `with` per risorse; `contextlib.contextmanager` per manager semplici; decorator con `functools.wraps`.
- GIL: un thread per bytecode; I/O-bound con asyncio o thread; CPU-bound con multiprocessing.
- asyncio: `async`/`await`, `asyncio.gather`; non bloccare il loop con I/O sincrono; usare `run_in_executor` per codice bloccante.
- venv per isolamento dipendenze; eccezioni: catch specifico, `raise from` per catena.
- property e descriptor; iteratori e generatori (yield); pattern matching (match/case); import e circular; logging; pyproject.toml; threading vs multiprocessing vs asyncio.

## Vedi anche

- [Django](django.md) e [FastAPI](fastapi.md) — Framework backend Python.
- [Database](database.md) — ORM e connessioni.
