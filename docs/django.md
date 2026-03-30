# Django

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Architettura MTV](#architettura-mtv)
- [Model, QuerySet e ORM](#model-queryset-e-orm)
- [Migrazioni](#migrazioni)
- [View: function-based e class-based](#view-function-based-e-class-based)
- [Middleware e request lifecycle](#middleware-e-request-lifecycle)
- [Sicurezza: CSRF, XSS, auth](#sicurezza-csrf-xss-auth)
- [Admin e gestione dati](#admin-e-gestione-dati)
- [Configurazione e ambienti](#configurazione-e-ambienti)
- [Signals, caching e comandi](#signals-caching-e-comandi)
- [Testing e Celery (cenni)](#testing-e-celery-cenni)
- [Django REST framework e logging](#django-rest-framework-e-logging)

## Panoramica

Django è un framework web full-stack per Python, orientato alla produttività e al principio “batteries included”. Offre ORM integrato, admin automatico, sistema di routing, template, gestione utenti e sicurezza (CSRF, XSS, auth). In produzione si appoggia sull’architettura MTV, sulle migrazioni per lo schema DB, sul middleware per il request lifecycle e su convenzioni chiare per manutenibilità e deploy.

---

## Architettura MTV

### Model-Template-View e flusso request

**Definizione tecnica**  
MTV (Model-Template-View) è il pattern architetturale di Django: il **Model** rappresenta dati e logica di dominio; il **Template** è la presentazione (HTML); la **View** contiene la logica di presentazione (quali dati passare e quale template usare). Il flusso è: request → URLconf → View → (opzionalmente Model/ORM) → Template → response.

**Confronto con MVC**  
In MVC il Controller gestisce input e coordina Model e View; in Django la “View” è più vicina al Controller (logica di presentazione), e il Template è la View di presentazione. Django usa il termine View per il componente che risponde alla richiesta e sceglie i dati e il template.

**Caso d’uso**  
Separare chiaramente: dove vivono i dati (Model), come vengono scelti e preparati (View), come vengono renderizzati (Template). Questo migliora testabilità e manutenibilità.

**Mini snippet**

```python
# urls.py
urlpatterns = [path("users/", views.user_list)]

# views.py
def user_list(request):
    users = User.objects.filter(is_active=True)
    return render(request, "users/list.html", {"users": users})
```

**Errore tipico**  
Mettere logica di business pesante nella View invece che in Model o in servizi dedicati: la View diventa difficile da testare e riusare. Soluzione: estrarre la logica in funzioni/servizi chiamati dalla View.

---

## Model, QuerySet e ORM

### Model e QuerySet: filter, exclude, annotate, lazy evaluation

**Definizione tecnica**  
Un Model è una classe Python che mappa su una tabella; gli attributi sono campi (CharField, IntegerField, ForeignKey, ecc.). Un QuerySet è una rappresentazione lazy di una query: la query SQL viene eseguita solo quando il QuerySet è “valutato” (iterazione, len, list, slice, ecc.).

**Differenze pratiche**  
- `filter()` / `exclude()`: restituiscono un nuovo QuerySet (nessuna query ancora).  
- `annotate()`: aggiunge campi calcolati (aggregati, espressioni) a livello SQL.  
- Chaining: `User.objects.filter(is_active=True).order_by("name")` costruisce la query; l’esecuzione avviene al primo accesso ai risultati.

**Best practice**  
Sfruttare la lazy evaluation per costruire query in più passaggi; evitare di valutare più volte lo stesso QuerySet se i dati potrebbero cambiare (materializzare con `list(qs)` se serve). Usare `only()`/`defer()` solo quando si è certi di ridurre colonne lette senza N+1 successivi.

**Mini snippet**

```python
from django.db import models

class User(models.Model):
    name = models.CharField(max_length=100)
    is_active = models.BooleanField(default=True)

# Query costruita, eseguita solo quando iterata
active = User.objects.filter(is_active=True).order_by("name")
count = active.count()   # esegue SELECT COUNT
for u in active:         # esegue SELECT * ... LIMIT
    print(u.name)
```

**Impatto performance**  
Ogni valutazione può generare una query; ripetere `count()` e poi iterare significa due query. Per riuso sicuro in una view, valutare una volta (es. `list(qs)`) se la lista è piccola.

---

### N+1 e ottimizzazione: select_related e prefetch_related

**Definizione tecnica**  
Il problema N+1: per ogni oggetto di una query si esegue un’altra query per caricare una relazione (es. profilo utente). Con N righe si ottengono 1 + N query. **select_related** risolve per ForeignKey e OneToOne: fa una JOIN e carica tutto in una query. **prefetch_related** risolve per ManyToMany e reverse ForeignKey: fa una seconda query e fa il join in Python.

**Quando usare quale**  
- **select_related**: relazioni “verso un solo oggetto” (ForeignKey, OneToOne).  
- **prefetch_related**: relazioni “più oggetti” (ManyToMany, reverse FK). Non si possono mescolare con select_related sulla stessa relazione; per relazioni annidate si usa Prefetch object.

**Caso d’uso**  
Lista di ordini con cliente e righe ordine: `Order.objects.select_related("customer").prefetch_related("items")` riduce da 1 + N + N a 1 + 1 + 1 query (ordini, clienti, righe).

**Mini snippet**

```python
# N+1: una query per user + una per ogni profile
users = User.objects.all()
for u in users:
    print(u.profile.bio)  # profile è ForeignKey su User

# Ottimizzato: una query con JOIN
users = User.objects.select_related("profile").all()
for u in users:
    print(u.profile.bio)
```

**Errore tipico**  
Usare `prefetch_related` per una ForeignKey: funziona ma è meno efficiente di `select_related` (due query invece di una JOIN). Usare `select_related` su una ManyToMany non è supportato; usare `prefetch_related`.

---

## Migrazioni

### makemigrations, migrate, conflitti e rollback

**Definizione tecnica**  
Le migrazioni sono file che descrivono le modifiche allo schema (creazione tabelle, aggiunta colonne, indici). **makemigrations** genera nuove migrazioni confrontando i Model con lo stato attuale delle migrazioni. **migrate** applica le migrazioni pendenti al DB. Ogni migrazione è atomica (transazione dove possibile).

**Conflitti**  
Su branch paralleli si possono generare migrazioni con lo stesso “genitore”; Django segnala conflitti e chiede di creare una migrazione di merge (o di riordinare le migrazioni). In team: comunicare quando si toccano gli stessi Model e risolvere i conflitti prima di unire.

**Migrazioni dati**  
Per spostare o trasformare dati si scrive una migrazione che usa `RunPython`: nella funzione si accede ai model con `apps.get_model` e si opera sui dati. Preferire migrazioni dati separate da quelle di schema quando possibile, per rollback più chiari.

**Rollback**  
`migrate app_name migration_name` riporta l’app allo stato di quella migrazione. Attenzione: migrazioni che rimuovono colonne o tabelle possono perdere dati; in produzione pianificare backup e finestre di manutenzione.

**Mini snippet**

```bash
python manage.py makemigrations
python manage.py migrate
python manage.py migrate myapp 0001  # rollback a 0001
```

**Errore tipico**  
Modificare a mano una migrazione già applicata su altri ambienti: crea incoerenza. Soluzione: creare una nuova migrazione che applica la correzione desiderata.

---

## View: function-based e class-based

### FBV vs CBV: pro/contro e quando preferirli

**Definizione tecnica**  
**Function-Based Views (FBV)**: una funzione che riceve `request` e restituisce `HttpResponse`. **Class-Based Views (CBV)**: una classe con metodi che rispondono ai verbi HTTP (`get`, `post`); Django fornisce viste generiche (ListView, DetailView, FormView, ecc.) che riducono boilerplate.

**Differenze pratiche**  
- **FBV**: semplici da leggere, facili da testare, massima flessibilità; ripetizione su pattern comuni (lista, dettaglio, form).  
- **CBV**: riuso tramite ereditarietà e mixin; meno codice per CRUD standard; curva di apprendimento per capire MRO e quali metodi sovrascrivere.

**Quando preferire**  
FBV per endpoint singoli o logica molto custom; CBV per liste, dettagli, form e tutto ciò che mappa bene su generic views (risparmio di codice e convenzioni chiare).

**Mini snippet**

```python
# FBV
def user_list(request):
    users = User.objects.filter(is_active=True)
    return render(request, "users/list.html", {"users": users})

# CBV equivalente
class UserListView(ListView):
    model = User
    queryset = User.objects.filter(is_active=True)
    template_name = "users/list.html"
    context_object_name = "users"
```

**Errore tipico**  
Sovrascrivere metodi CBV senza chiamare `super()` dove richiesto (es. `form_valid`), rompendo il flusso. Soluzione: leggere la documentazione della generic view e chiamare sempre `super()` quando si estende il comportamento.

---

## Middleware e request lifecycle

### Ordine di esecuzione e esempio (logging, auth)

**Definizione tecnica**  
Il middleware è una classe con metodi `__call__` (o `process_request` / `process_response` in stile vecchio) che viene invocata per ogni request e response. L’ordine in `MIDDLEWARE` determina: in request, il primo in lista è il primo eseguito; in response, l’ordine è invertito (stack).

**Flusso**  
Request: Middleware 1 → 2 → … → View. Response: View → … → Middleware 2 → 1. Un middleware può cortocircuitare restituendo una response senza arrivare alla view.

**Caso d’uso**  
Logging request, autenticazione, CORS, gestione lingua, injection di attributi in `request` (es. utente corrente dopo auth middleware).

**Mini snippet**

```python
class LoggingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        print(f"Request: {request.path}")
        response = self.get_response(request)
        print(f"Response: {response.status_code}")
        return response
```

**Errore tipico**  
Mettere middleware che dipende dall’auth prima del middleware di autenticazione: `request.user` non sarà ancora popolato. Soluzione: rispettare l’ordine (es. AuthenticationMiddleware prima dei propri middleware che usano `request.user`).

---

## Sicurezza: CSRF, XSS, auth

### CSRF: token, template, API

**Definizione tecnica**  
Il Cross-Site Request Forgery (CSRF) sfrutta il fatto che il browser invia automaticamente i cookie di sessione. Un sito malevolo può far inviare una richiesta indesiderata all’app. La protezione Django si basa su un token CSRF inviato con il form e verificato lato server.

**Template**  
Nei form HTML usare `{% csrf_token %}`; il token va incluso nei POST. Per richieste AJAX, includere l’header `X-CSRFToken` con il valore del token (lettura da cookie o da un meta tag).

**API**  
Per API stateless (es. REST con token Bearer) si può escludere la view dalla verifica CSRF con `@csrf_exempt`; usare solo dove l’autenticazione è basata su token/sessioni esterne e si è consapevoli dei rischi. Per API consumate da frontend sulla stessa origine, mantenere CSRF.

**Best practice**  
Mantenere CSRF attivo per tutte le view che modificano stato e usano sessioni cookie-based; per API solo-token documentare perché si usa `@csrf_exempt` e quali alternative si adottano (es. SameSite, CORS restrittivo).

**Errore tipico**  
Dimenticare `{% csrf_token %}` in un form: la richiesta POST viene rifiutata con 403. Soluzione: includere il token in ogni form POST verso il sito.

---

### XSS e escaping nei template

**Definizione tecnica**  
XSS (Cross-Site Scripting) si verifica quando input utente viene restituito in HTML senza escape e viene eseguito come script. Django template escaping è attivo di default: le variabili sono escaped a meno che non si marchino come `safe` o si usi `mark_safe`.

**Pratica**  
Non disabilitare l’escaping per contenuto utente; usare `|safe` solo per contenuto di cui si è certi (es. markup generato da una libreria trusted). Per contenuto HTML parziale usare filtri sicuri o librerie che sanitizzano (es. bleach).

**Errore tipico**  
Passare input utente in `{{ user_input }}` e in un altro punto usare `{{ user_input|safe }}` per “risolvere” un problema di visualizzazione: si introduce XSS. Soluzione: mantenere sempre l’escape per dati utente; correggere il modello dati o il template se serve mostrare HTML controllato.

---

### Auth: User, authenticate, login, logout, permessi

**Definizione tecnica**  
Django fornisce il model `User` (o un modello custom via `AUTH_USER_MODEL`), il backend di autenticazione (`authenticate()` che controlla credenziali), e le funzioni di sessione `login(request, user)` e `logout(request)`. I permessi sono legati a User e Group (permessi modello: add, change, delete, view; permessi custom).

**Flusso tipico**  
Ricevere username/password → `authenticate()` → se user non None, `login(request, user)` → redirect. Per richiedere login su una view: `@login_required` o, in CBV, `LoginRequiredMixin`. Il logout invalida la sessione con `logout(request)`.

**Permessi**  
Controllo in view: `user.has_perm("app.add_model")`, `user.has_perm("app.change_model", obj)`. Nei template: `{% if perms.app.add_model %}`. Assegnare permessi tramite Group o direttamente all’User.

**Mini snippet**

```python
from django.contrib.auth import authenticate, login

def login_view(request):
    user = authenticate(request, username=request.POST["username"], password=request.POST["password"])
    if user is not None:
        login(request, user)
        return redirect("home")
    return render(request, "login.html", {"error": "Invalid credentials"})
```

**Errore tipico**  
Salvare la password in chiaro: Django usa hash (PBKDF2 di default); non si deve mai impostare `user.password = "raw"`. Usare `user.set_password("raw")` per aggiornare la password.

---

## Admin e gestione dati

### Registrazione model, list_display, search_fields

**Definizione tecnica**  
L’admin Django è un’interfaccia CRUD generata a partire dai Model. Si registra un model con `admin.site.register(MyModel)` o con una classe `ModelAdmin` personalizzata. **list_display** definisce le colonne nella lista; **search_fields** abilita la ricerca su quei campi; **list_filter** aggiunge filtri laterali.

**Customizzazione base**  
- `list_display`: campi e callable (es. metodo che restituisce uno stato calcolato).  
- `search_fields`: campi su cui fare LIKE (es. `["username", "email"]`).  
- `list_filter`: campi per filtri (es. `is_active`, `date_joined`).  
- `readonly_fields`, `fieldsets` per la scheda di dettaglio.

**Caso d’uso**  
Backoffice interno, gestione contenuti, ispezione dati; limitare l’accesso con permessi e solo a staff.

**Mini snippet**

```python
from django.contrib import admin
from .models import User

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ("username", "email", "is_active", "date_joined")
    search_fields = ("username", "email")
    list_filter = ("is_active",)
```

**Errore tipico**  
Includere in `list_display` un campo ManyToMany senza ottimizzazione: una query per riga (N+1). Soluzione: usare `list_select_related` o annotazioni per ridurre le query.

---

## Configurazione e ambienti

### DEBUG, SECRET_KEY, variabili d’ambiente, split settings

**Definizione tecnica**  
`DEBUG=True` abilita pagine di errore dettagliate e disabilita alcune ottimazioni; non deve mai essere True in produzione. `SECRET_KEY` è usata per signing e sessioni; deve essere unica e segreta. Entrambe vanno gestite per ambiente (dev, staging, prod).

**Variabili d’ambiente**  
Leggere `DEBUG` e `SECRET_KEY` da `os.environ` (o da un file `.env` con python-decouple/django-environ), mai hardcoded nel repository. In produzione usare secret manager o variabili del deployment.

**Split settings**  
Struttura comune: `settings/base.py`, `settings/dev.py`, `settings/prod.py`; i file per ambiente importano da base e sovrascrivono ciò che serve. `DJANGO_SETTINGS_MODULE` (o `manage.py` / wsgi) punta al modulo corretto (es. `myapp.settings.prod`).

**Best practice**  
Un solo `SECRET_KEY` per ambiente; ruotarla in caso di compromissione. Non committare `.env` con segreti; documentare le variabili richieste in README o in un `.env.example`.

**Errore tipico**  
Lasciare `DEBUG=True` in produzione: esposizione di stack trace e informazioni sensibili. Soluzione: variabile d’ambiente `DEBUG=False` in prod e controlli in CI/deploy.

---

## Signals, caching e comandi

### Signals (pre_save, post_save, ecc.)
**Definizione tecnica**  
I signal sono meccanismi di decoupling: il sender emette un evento (es. `post_save` su un Model) e i receiver registrati vengono chiamati. Si connettono con `Signal.connect(receiver)` o con il decorator `@receiver(post_save, sender=User)`.

**Caso d'uso**  
Log di audit, invalidazione cache, notifiche, sincronizzazione con sistemi esterni. Evitare logica pesante o transazionale nel receiver: può rallentare ogni save e complicare il rollback.

**Errore tipico**  
Mettere nel receiver operazioni che dovrebbero essere nella business logic del Model o in un servizio; non gestire eccezioni (il receiver che fallisce può far fallire la transazione). Soluzione: receiver leggeri, side effect in task asincroni (Celery).

### Caching framework
**Definizione tecnica**  
Django offre un layer di cache con backend configurabili: locale (memoria), file, database, Redis/Memcached. Si usa con `cache.get(key)`, `cache.set(key, value, timeout)` o con il decorator `@cache_page` per le view.

**Caso d'uso**  
Cache di risposta HTTP per view pesanti; cache di query o di oggetti serializzati; session backend. Per cache distribuita in produzione: Redis; per invalidation granulare: chiavi per risorsa e invalidazione su save/delete.

**Errore tipico**  
Cachare senza TTL o senza strategia di invalidazione; usare backend locale in ambiente multi-process (ogni processo ha la sua cache). Soluzione: TTL ragionevole; Redis per cluster; cache key che includono versione o ID.

### Management commands
**Definizione tecnica**  
I management command sono comandi CLI eseguibili con `python manage.py <command>`. Si creano in `app/management/commands/<name>.py` con una classe che estende `BaseCommand` e implementa `handle(self, *args, **options)`.

**Caso d'uso**  
Job batch (import, export, report), pulizie periodiche, migrazioni dati one-off. Si possono schedulare con cron o con Celery Beat.

**Errore tipico**  
Comandi che non usano il DB Django (transazioni, connection) o che non gestiscono errori; comandi lunghi senza output di progresso. Soluzione: usare ORM e transaction.atomic; logging e print progressivo.

---

## Testing e Celery (cenni)

### Testing: TestCase, Client, factory
**Definizione tecnica**  
`django.test.TestCase` fornisce transazione per test (rollback dopo ogni test), `Client` per simulare richieste HTTP (get, post, login), e assertion su response (status, redirect, template). Factory (es. factory_boy) creano istanze di Model per dati di test senza ripetere fixture.

**Caso d'uso**  
Test unitari su view e form; test di integrazione su flussi (registrazione, checkout); test API con Client e assert su JSON.

**Errore tipico**  
Test che dipendono da ordine di esecuzione o da dati globali; fixture pesanti che rallentano i test. Soluzione: test isolati; factory per dati minimi; usare `setUp` per dati comuni.

### Celery (cenni)
**Definizione tecnica**  
Celery è un task queue: si definiscono task (funzioni con decorator `@app.task`) che vengono accodati in un broker (Redis, RabbitMQ) e eseguiti da worker. Celery Beat pianifica task periodici (cron-like).

**Caso d'uso**  
Email asincrone, elaborazione file, sync con servizi esterni, report notturni. In Django si configura con `CELERY_BROKER_URL` e si usano i task da view o da signal (dopo commit).

**Errore tipico**  
Task che accedono a oggetti ORM dopo essere stati serializzati (stale); task lunghi senza timeout o retry. Soluzione: passare ID e rileggere dal DB nel task; idempotenza e retry con backoff.

---

## Django REST framework e logging

### Django REST framework (cenni)
**Definizione tecnica**  
DRF aggiunge a Django API REST tipizzate: serializer per validazione e serializzazione, ViewSet e Router per CRUD con poche righe, autenticazione (session, token, JWT), permessi e throttling.

**Caso d'uso**  
API per SPA o mobile; stessa codebase Django per admin e API; contratti REST con versioning e documentazione (schema).

**Errore tipico**  
Esporre Model direttamente senza serializer (rischio di esporre campi sensibili); non configurare permessi (API pubbliche per default). Soluzione: Serializer dedicati; permission_classes su ViewSet; throttling per rate limit.

### Logging e monitoring
**Definizione tecnica**  
Django usa il modulo `logging` di Python. La configurazione è in `LOGGING` (dictConfig): logger per nome (django, django.request, app), handler (file, console), formatter. Per monitoring: integrare con strumenti (Sentry, Datadog) tramite handler o middleware che catturano eccezioni e metriche.

**Caso d'uso**  
Log di request/response per audit; log di errore con stack trace; metriche di latenza e throughput per APM.

**Errore tipico**  
Log eccessivo in produzione (DEBUG); log non ruotati; dati sensibili nei log. Soluzione: livello INFO in prod; RotatingFileHandler; sanitizzare PII e secret nei formatter.

---

## In sintesi

- ORM: Model, QuerySet lazy, select_related/prefetch_related per evitare N+1; migrazioni per schema.
- FBV vs CBV: function-based per logica custom; class-based (ListView, FormView) per CRUD e convenzioni; chiamare super() dove richiesto.
- Middleware: ordine conta (request in ordine, response inverso); auth prima dei middleware che usano request.user.
- CSRF: {% csrf_token %} nei form; XSS: non usare |safe su input utente; auth con authenticate/login/logout.
- Admin: list_display, search_fields, list_filter; DEBUG e SECRET_KEY da variabili d'ambiente.
- Signals per decoupling (evitare logica pesante); caching con backend Redis; management commands per job; testing con TestCase e Client; Celery per task async; DRF per API REST; logging con LOGGING e monitoring.

## Vedi anche

- [Python](python.md) — Linguaggio e async.
- [Database](database.md) — Modellazione e query.
- [Sicurezza](sicurezza.md) — OWASP e best practice.
