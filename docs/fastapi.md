# FastAPI

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Path operations e routing](#path-operations-e-routing)
- [Pydantic e validazione](#pydantic-e-validazione)
- [Dependency Injection](#dependency-injection)
- [Async e performance](#async-e-performance)
- [OpenAPI e documentazione](#openapi-e-documentazione)
- [Confronto con Flask e Django REST](#confronto-con-flask-e-django-rest)
- [Middleware, status code e best practice](#middleware-status-code-e-best-practice)
- [WebSocket, testing e versioning](#websocket-testing-e-versioning)
- [Logging, lifespan e sicurezza](#logging-lifespan-e-sicurezza)

## Panoramica

FastAPI è un framework web moderno per API in Python, basato su type hints e su Starlette (ASGI). Offre validazione automatica dei dati con Pydantic, dependency injection nativa, supporto async e documentazione OpenAPI (Swagger/ReDoc) generata automaticamente. In produzione si appoggia su tipizzazione forte per manutenibilità, su async per I/O bound e su DX (developer experience) per delivery rapido.

---

## Path operations e routing

### Path operations: GET, POST, path/query/body params

**Definizione tecnica**  
Le path operations sono funzioni (o metodi) decorate con `@app.get`, `@app.post`, ecc. che mappano verbi HTTP su percorsi. I parametri possono essere **path** (nella URL), **query** (dopo il `?`), **body** (corpo della richiesta, tipicamente JSON). FastAPI risolve i parametri dalla firma della funzione in base ai type hints e ai nomi.

**Differenze pratiche**  
- **Path**: `@app.get("/items/{item_id}")` → `item_id: int` nel parametro.  
- **Query**: parametri non dichiarati come path né come body sono query; es. `skip: int = 0`, `limit: int = 10`.  
- **Body**: un modello Pydantic o più parametri con `Body()`; FastAPI legge il JSON e valida.

**Best practice**  
Usare type hints su tutti i parametri; valori di default per query opzionali; modelli Pydantic per body complessi; evitare troppi parametri in una sola operazione (raggruppare in body o in un modello query).

**Mini snippet**

```python
from fastapi import FastAPI, Query

app = FastAPI()

@app.get("/items/{item_id}")
def get_item(item_id: int, q: str | None = Query(None, alias="query")):
    return {"item_id": item_id, "q": q}

@app.post("/items")
def create_item(name: str, price: float):
    return {"name": name, "price": price}
```

**Pro/contro**  
- **Pro**: routing dichiarativo, validazione e serializzazione coerenti con i tipi.  
- **Contro**: bisogna conoscere le convenzioni (path vs query vs body) per non sbagliare la firma.

---

## Pydantic e validazione

### BaseModel, validazione, Field, response_model

**Definizione tecnica**  
Pydantic permette di definire modelli con type hints; a runtime i dati in ingresso vengono validati e convertiti. FastAPI usa questi modelli per il body delle richieste e per la serializzazione delle risposte. **Field** aggiunge vincoli e metadati (es. `min_length`, `description`). **response_model** sulla path operation definisce lo schema della response e filtra/serializza l’output.

**Differenze pratiche**  
- **BaseModel**: attributi tipizzati; validazione su `Model(**dict)`; `.model_dump()` per esportare in dict.  
- **Field**: validatori, alias, default; utile per documentazione OpenAPI e messaggi di errore chiari.  
- **response_model**: garantisce che la risposta rispetti il contratto (es. esclude campi interni, rinomina chiavi).

**Best practice**  
Modelli separati per request e response quando differiscono (es. password in input, mai in output); usare `response_model_exclude_unset` per omettere campi non impostati; validatori custom con `@field_validator` quando serve logica oltre ai tipi.

**Mini snippet**

```python
from pydantic import BaseModel, Field

class ItemCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    price: float = Field(ge=0)

class ItemResponse(BaseModel):
    id: int
    name: str
    price: float

@app.post("/items", response_model=ItemResponse)
def create_item(item: ItemCreate):
    db_item = save_item(item)
    return db_item
```

**Pro/contro**  
- **Pro**: validazione automatica, errori 422 strutturati, documentazione OpenAPI aggiornata.  
- **Contro**: per modelli molto dinamici o con molti optional la definizione può diventare verbosa; si può estendere con Union e modelli discriminati.

---

## Dependency Injection

### Depends(), funzione come dependency, dipendenze annidate

**Definizione tecnica**  
FastAPI gestisce la dependency injection tramite **Depends()**. Una “dependency” è una funzione (o callable) i cui parametri sono a loro volta risolti da FastAPI. La dependency viene chiamata una volta per request (cached per default nello scope della request); il risultato viene iniettato nel parametro della path operation.

**Differenze pratiche**  
- Dipendenza come funzione: `def get_db(): ... yield db`; ideale per risorse con cleanup (DB, client).  
- Dipendenze annidate: una dependency può dichiarare `Depends(get_db)` e ricevere il DB; la path operation dichiara `Depends(get_current_user)` che a sua volta usa `Depends(get_db)`.  
- Uso tipico: sessione DB, utente corrente, client HTTP, configurazione.

**Best practice**  
Usare dependency per tutto ciò che è “per-request” (DB session, utente); evitare stato globale; per dipendenze costose sfruttare il caching di FastAPI (stesso scope = una chiamata per request).

**Mini snippet**

```python
from fastapi import Depends

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)):
    user = decode_and_get_user(db, token)
    if not user:
        raise HTTPException(401)
    return user

@app.get("/me")
def me(user: User = Depends(get_current_user)):
    return user
```

**Pro/contro**  
- **Pro**: testabilità (si può sovrascrivere `app.dependency_overrides`), riuso, ordine di risoluzione chiaro.  
- **Contro**: dipendenze molto annidate possono rendere il flusso meno ovvio; documentare le dipendenze critiche (es. auth).

---

## Async e performance

### Quando usare async def, I/O bound, attenzione al codice sync

**Definizione tecnica**  
Le path operations possono essere `async def` o `def`. Con **async def** l’event loop può sospendere la coroutine durante le operazioni I/O (await), servendo altre richieste. Con **def** FastAPI esegue la funzione in un thread pool per non bloccare l’event loop; utile per codice sincrono bloccante (librerie DB sync, CPU-bound breve).

**Quando usare async**  
- **async def**: quando si fa I/O “async-native” (await su client HTTP async, DB async come asyncpg, lettura file async).  
- **def**: quando si chiamano solo librerie sincrone (es. ORM Django, requests, psycopg2); FastAPI le manda in thread pool.

**Attenzione**  
Codice sincrono bloccante dentro una coroutine (es. `time.sleep`, chiamata sync a DB) blocca l’intero event loop e annulla i benefici dell’async. Per operazioni bloccanti usare `run_in_executor` o esporre l’endpoint come `def` (thread pool).

**Mini snippet**

```python
@app.get("/async-route")
async def async_route():
    async with httpx.AsyncClient() as client:
        r = await client.get("https://api.example.com/data")
    return r.json()

@app.get("/sync-route")
def sync_route():
    # FastAPI esegue in thread pool
    return requests.get("https://api.example.com/data").json()
```

**Pro/contro**  
- **Pro**: molti client concorrenti con poche thread se si usa async ovunque nell’I/O.  
- **Contro**: mischiare sync pesante in async peggiora le performance; bisogna conoscere quali librerie sono async.

---

## OpenAPI e documentazione

### Doc automatica, /docs, /redoc, descrizioni ed esempi

**Definizione tecnica**  
FastAPI genera lo schema OpenAPI (JSON) a partire da path operations, modelli Pydantic e parametri. Le UI **/docs** (Swagger) e **/redoc** (ReDoc) sono servite automaticamente e consentono di provare le API. Titoli, descrizioni ed esempi si aggiungono con parametri di FastAPI e con **Field(description=..., example=...)** nei modelli.

**Differenze pratiche**  
- **summary** e **description** su path operation e su parametri arricchiscono la doc.  
- **Field(description="...", examples=[...])** (Pydantic v2) migliora la documentazione dei body.  
- In produzione si può disabilitare o proteggere /docs e /openapi.json se necessario.

**Best practice**  
Compilare summary e description per le operazioni principali; usare esempi sui modelli per facilitare chi consuma l’API; mantenere response_model per avere response schema corretti nella doc.

**Mini snippet**

```python
@app.get(
    "/items/{item_id}",
    summary="Ottiene un item",
    description="Restituisce l'item con l'id specificato se esiste.",
)
def get_item(item_id: int):
    ...
```

**Pro/contro**  
- **Pro**: documentazione sempre allineata al codice; testing interattivo senza Postman.  
- **Contro**: per API molto grandi la doc può diventare pesante; si può segmentare con tag e raggruppamenti.

---

## Confronto con Flask e Django REST

### Velocità sviluppo, validazione, async, documentazione

**Definizione tecnica**  
- **Flask**: micro-framework, minimo di default; estensioni per ORM, auth, API; niente validazione automatica né OpenAPI out-of-the-box; sync di default (async supportato da Flask 2).  
- **Django REST Framework (DRF)**: stack su Django; serializers per validazione e serializzazione; auth e permessi integrati; niente OpenAPI automatica (servono pacchetti esterni); view sync (async in Django 4.1+ con adattatori).  
- **FastAPI**: stack ASGI; validazione e OpenAPI native; async first; meno “batteries” di Django (niente ORM/admin), più vicino a Flask per minimalismo con type hints.

**Quando preferire FastAPI**  
- API pure (microservizi, BFF); team che vuole type hints e doc automatica; carichi I/O-bound con molti concorrenti; preferenza per async.  
- Quando preferire Django/DRF: applicazione full-stack con admin, ORM Django, auth Django già in uso.  
- Quando preferire Flask: applicazioni minimali senza bisogno di validazione forte o doc OpenAPI, massima libertà di scelta librerie.

**Pro/contro**  
- **FastAPI**: pro = validazione, OpenAPI, async, DX; contro = ecosistema più piccolo di Django, niente admin/ORM integrato.  
- **DRF**: pro = integrazione Django, serializers maturi; contro = più boilerplate, doc OpenAPI non nativa.  
- **Flask**: pro = flessibilità; contro = validazione e doc da costruire a mano.

---

## Middleware, status code e best practice

### Status code, HTTPException, response model

**Definizione tecnica**  
Lo status code si imposta con **status_code** nel decorator (`@app.post(..., status_code=201)`) o restituendo **Response**/**JSONResponse** con codice esplicito. **HTTPException** solleva un’eccezione che FastAPI converte in response JSON con il codice e il dettaglio indicati.

**Best practice**  
Usare codici appropriati (200/201 per successo, 400 per bad request, 401/403 per auth, 404 per not found, 422 per validation error); lanciare `HTTPException` con messaggio chiaro e eventuale headers; definire response_model (e response_model_exclude_*) per garantire forma della response.

**Mini snippet**

```python
from fastapi import HTTPException

@app.get("/items/{item_id}")
def get_item(item_id: int):
    item = find_item(item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return item
```

---

### BackgroundTasks: quando usare e limiti

**Definizione tecnica**  
**BackgroundTasks** permette di accodare funzioni da eseguire dopo aver inviato la response al client. Utile per operazioni non critiche per la risposta (invio email, log, aggiornamento contatori). Le task vengono eseguite nello stesso processo dopo il flush della response.

**Quando usare**  
Per piccoli job “fire-and-forget” che non richiedono retry né persistenza. Per job pesanti, retry o code con picchi di carico usare una coda esterna (Celery, Redis Queue, job su DB).

**Limitazioni**  
Le task non sopravvivono al riavvio del processo; non c’è retry automatico; un’eccezione in una task non viene propagata al client (già risposto). Non usare per operazioni critiche o lunghe.

**Mini snippet**

```python
from fastapi import BackgroundTasks

def send_notification(email: str):
    # invio email
    pass

@app.post("/signup")
def signup(background_tasks: BackgroundTasks, user: UserCreate):
    user = create_user(user)
    background_tasks.add_task(send_notification, user.email)
    return {"id": user.id}
```

**Pro/contro**  
- **Pro**: zero dipendenze esterne, semplice da usare.  
- **Contro**: non adatto a carichi pesanti o a garanzie di delivery; per quelli serve una queue dedicata.

---

## WebSocket, testing e versioning

### WebSocket
**Definizione tecnica**  
FastAPI espone endpoint WebSocket con `@app.websocket("/ws")`; la funzione riceve `WebSocket` e usa `await websocket.accept()`, `await websocket.receive_text()`/`receive_json()`, `await websocket.send_text()`/`send_json()`. Per gestione connessioni multiple: tenere una struttura (dict, set) di connessioni attive e broadcast quando serve.

**Differenze pratiche**  
- Connessione persistente; adatto a notifiche real-time, chat, dashboard live.  
- Chiusura: gestire disconnect e rimuovere la connessione dalla lista; heartbeat per rilevare client morti.

**Best practice**  
Limitare messaggi per evitare DoS; validare payload con Pydantic; usare dependency per auth (token in query o header) anche su WebSocket.

**Mini snippet**

```python
@app.websocket("/ws")
async def ws_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_json()
            await websocket.send_json({"echo": data})
    except WebSocketDisconnect:
        pass
```

### Testing (TestClient, pytest)
**Definizione tecnica**  
`from fastapi.testclient import TestClient`; `TestClient(app)` fornisce get, post, ecc. sincroni che chiamano l'app senza avviare il server. Si usano fixture pytest per app e client; si mockano le dependency con `app.dependency_overrides`.

**Differenze pratiche**  
- TestClient è sincrono: le coroutine vengono eseguite in un event loop interno.  
- Per testare codice async diretto usare pytest-asyncio con `@pytest.mark.asyncio`.  
- Override: `app.dependency_overrides[get_db] = lambda: ...` per iniettare DB di test o mock.

**Best practice**  
Fixture per client e dati di test; test su status code, body JSON e header; test di auth con override del dependency di sicurezza.

**Mini snippet**

```python
def test_create_item(client: TestClient):
    r = client.post("/items", json={"name": "x", "price": 1.0})
    assert r.status_code == 201
    assert r.json()["name"] == "x"
```

### Versioning API
**Definizione tecnica**  
Strategie comuni: prefix URL (`/v1/items`, `/v2/items`), header (`Accept: application/vnd.api+v1`), query param. In FastAPI si realizza con router inclusi sotto un prefix: `app.include_router(v1_router, prefix="/v1")` e duplicare o condividere logica tra versioni.

**Differenze pratiche**  
- Prefix: semplice, cache-friendly, chiaro per client.  
- Header: stesso URL, contenuto diverso; più complesso da testare e da documentare.  
- Deprecation: mantenere v1 per un periodo e documentare sunset; redirect o 410 Gone dopo.

**Best practice**  
Scegliere una strategia e mantenerla; documentare breaking change tra versioni; evitare troppe versioni attive (max 2-3).

---

## Logging, lifespan e sicurezza

### Structured logging e correlazione (request_id)
**Definizione tecnica**  
Middleware che aggiunge un `request_id` (UUID) a ogni request e lo propaga nei log (contextvars o passaggio esplicito). Log in formato JSON (structlog, python-json-logger) per ingest in sistemi di log (ELK, Datadog).

**Differenze pratiche**  
- contextvars: impostare il request_id all'ingresso e leggerlo nei servizi senza passare parametri.  
- In risposta: header `X-Request-ID` per correlazione client-side.

**Best practice**  
Log strutturato con livello, timestamp, request_id, endpoint; evitare log di body sensibili; livelli appropriati (DEBUG in dev, INFO in prod).

### Graceful shutdown e lifespan
**Definizione tecnica**  
FastAPI (Starlette) supporta eventi di lifespan con `@asynccontextmanager`: codice eseguito all'avvio e allo shutdown dell'app. Si usa per aprire connessioni (DB, Redis), caricare modelli, e per chiuderle correttamente al SIGTERM.

**Differenze pratiche**  
- `yield` separa startup da shutdown: prima dello yield = startup, dopo = shutdown.  
- In produzione il process manager (uvicorn, gunicorn) invia SIGTERM; uvicorn gestisce il segnale e chiude le connessioni in ascolto dopo aver servito le richieste in corso (con timeout).

**Best practice**  
Registrare risorse in uno state (dict) nel lifespan e chiuderle in ordine inverso; timeout di shutdown coerente con il deployment (K8s terminationGracePeriodSeconds).

**Mini snippet**

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.db = await open_db()
    yield
    await app.state.db.close()
app = FastAPI(lifespan=lifespan)
```

### Security: OAuth2PasswordBearer, API key
**Definizione tecnica**  
FastAPI integra OpenAPI con schemi di sicurezza. `OAuth2PasswordBearer(tokenUrl="token")` definisce un flow password; la dependency estrae il token dall'header Authorization e può validarlo (JWT, session). API key: dependency che legge header o query e verifica la chiave.

**Differenze pratiche**  
- OAuth2PasswordBearer: dependency che ritorna il token (o 401 se assente); la logica di verifica (JWT decode, DB lookup) va in un'altra dependency.  
- API key: `APIKeyHeader("X-API-Key")` o `APIKeyQuery("api_key")`; confronto con valore in env o in DB.

**Best practice**  
Non loggare token o chiavi; usare HTTPS; documentare in OpenAPI quali endpoint richiedono auth (automatico con dependency).

**Mini snippet**

```python
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")
def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    payload = decode_jwt(token)
    return get_user(payload["sub"])
```

---

## In sintesi

- Path operations con decoratori; Pydantic per validazione e serializzazione automatica; response_model e status_code.
- Dependency Injection: Depends() per riuso e testing; dipendenze a cascata; evitare logica pesante nelle dep.
- Async nativo: preferire async def per endpoint I/O-bound; sync in thread pool; OpenAPI/Swagger auto-generata.
- Confronto: FastAPI per API moderne e tipizzate; Flask per semplicità; Django REST per ecosistema Django.
- WebSocket per real-time; TestClient e dependency_overrides per test; versioning con prefix o header; logging strutturato e request_id; lifespan per startup/shutdown; OAuth2PasswordBearer e API key per sicurezza in OpenAPI.

## Vedi anche

- [Python](python.md) — Type hints e async.
- [Django](django.md) — Alternativa full-stack.
- [Architettura](architettura.md) — REST e API design.
