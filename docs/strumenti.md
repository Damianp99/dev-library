# Strumenti

Download e primo avvio su Windows. Per macOS e Linux, in ogni sezione c'è il link della stessa pagina ufficiale: l'installer cambia, i passi successivi no.

Verifica sempre la versione sulla documentazione del prodotto. Lo stack citato nelle guide da colloquio (Node 20 LTS, Python 3.12, PostgreSQL 16) è il riferimento degli esempi, non l'unica versione installabile.

---

## Indice

- [Account GitHub](#account-github)
- [Git per Windows](#git-per-windows)
- [Scegli un editor](#scegli-un-editor)
- [Node.js](#nodejs)
- [Python, Django e FastAPI](#python-django-e-fastapi)
- [SQL e DBeaver](#sql-e-dbeaver)

---

## Account GitHub

1. Apri [github.com/signup](https://github.com/signup).
2. Crea l'account con un'email che controlli.
3. Conferma l'email e, quando GitHub lo chiede, attiva l'autenticazione a due fattori.
4. Accedi e tieni a portata il nome utente: serve per clonare i repository.

Il modo di usare commit, branch e push è in [Git e commit](git.md).

---

## Git per Windows

1. Scarica l'installer da [git-scm.com/download/win](https://git-scm.com/download/win).
2. Durante l'installazione lascia il default "Git from the command line and also from 3rd-party software", così `git` funziona in PowerShell.
3. Chiudi e riapri il terminale, poi controlla:

```powershell
git --version
```

Deve stampare un numero di versione, non "termine non riconosciuto".

Su macOS: [git-scm.com/download/mac](https://git-scm.com/download/mac). Su Linux: [git-scm.com/download/linux](https://git-scm.com/download/linux).

---

## Scegli un editor

Ne basta uno. Gli altri restano alternative.

### VS Code

Editor gratuito di Microsoft, adatto a HTML, CSS, JavaScript e Python.

1. Scarica l'installer da [code.visualstudio.com/download](https://code.visualstudio.com/download) (Windows, User Installer).
2. All'avvio apri la cartella del progetto con File → Open Folder.

### Cursor

Editor con agente integrato, per gli stessi tipi di progetto.

1. Scarica la build Windows da [cursor.com/download](https://cursor.com/download) (su PC comuni: Windows x64 User).
2. Accedi con l'account Cursor quando l'app lo chiede.

### Claude Code

Agente da terminale, non un IDE. La guida ufficiale è [code.claude.com/docs/en/setup](https://code.claude.com/docs/en/setup): da lì puoi anche scaricare l'app desktop. In PowerShell l'installazione nativa documentata è:

```powershell
irm https://claude.ai/install.ps1 | iex
```

Apri un terminale nuovo e controlla con `claude --version`, poi nella cartella del progetto lancia `claude` e accedi all'account Anthropic. Su Windows è utile avere già Git, installato nel passo precedente.

Se il comando fallisce, usa la pagina di setup ufficiale: il metodo può cambiare.

### WebStorm e IntelliJ IDEA

[WebStorm](https://www.jetbrains.com/webstorm/download/) è l'IDE JetBrains per JavaScript e TypeScript. [IntelliJ IDEA Community](https://www.jetbrains.com/idea/download/) è l'IDE gratuito per Java.

WebStorm, per studio, open source senza compenso e progetti personali, si attiva con la licenza **Non-commercial use** e un account JetBrains. Per lavoro retribuito o per un'azienda serve una licenza a pagamento. Dettaglio e limiti: [FAQ sulla licenza non commerciale](https://sales.jetbrains.com/hc/en-gb/articles/18950890312210-The-free-non-commercial-licensing-FAQ).

1. Installa WebStorm dalla pagina di download.
2. All'avvio scegli **Non-commercial use**, accedi con un JetBrains Account e accetta i termini.
3. Serve una versione che supporti quella licenza (dalla 2024.2.4 in poi). Se la voce non compare, aggiorna l'IDE.

---

## Node.js

Node.js è il runtime JavaScript fuori dal browser. Include npm. Serve per Tailwind, per gli strumenti frontend e per il backend descritto in [Node.js](nodejs.md).

HTML, CSS e JavaScript aperti nel browser non richiedono Node.

1. Scarica la versione **LTS** da [nodejs.org/en/download](https://nodejs.org/en/download).
2. Esegui l'installer. Su Windows lascia l'opzione che aggiunge Node al PATH.
3. Chiudi e riapri il terminale:

```powershell
node -v
npm -v
```

Entrambi devono stampare un numero di versione.

---

## Python, Django e FastAPI

Python si scarica. Django e FastAPI sono librerie: si installano con `pip` dentro un ambiente virtuale. I concetti da colloquio sono in [Python](python.md), [Django](django.md) e [FastAPI](fastapi.md).

### Python

1. Scarica l'installer Windows da [python.org/downloads/windows](https://www.python.org/downloads/windows/). Su macOS o Linux parti da [python.org/downloads](https://www.python.org/downloads/).
2. Nel primo schermo dell'installer Windows seleziona **Add python.exe to PATH**, poi Install.
3. Terminale nuovo:

```powershell
py --version
```

### Django

In una cartella nuova:

```powershell
mkdir prova-django
cd prova-django
py -m venv .venv
.venv\Scripts\Activate.ps1
py -m pip install django
django-admin startproject config .
py manage.py runserver
```

Apri `http://127.0.0.1:8000/`. Per fermare il server: Ctrl+C.

Se PowerShell blocca `Activate.ps1`, esegui una volta `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` e rilancia l'attivazione.

La cartella `.venv` non si committa. Aggiungila al `.gitignore` del progetto.

### FastAPI

In un'altra cartella, con il suo ambiente:

```powershell
mkdir prova-fastapi
cd prova-fastapi
py -m venv .venv
.venv\Scripts\Activate.ps1
py -m pip install "fastapi[standard]"
```

Crea `main.py`:

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "ok"}
```

Avvia con `fastapi dev main.py` e apri l'URL che stampa il comando (di solito `http://127.0.0.1:8000`). Il tutorial completo è su [fastapi.tiangolo.com](https://fastapi.tiangolo.com/tutorial/).

---

## SQL e DBeaver

SQL è il linguaggio per interrogare un database relazionale. Le domande da colloquio (modello, indici, transazioni, JOIN) sono in [Database](database.md). DBeaver è il programma con cui ti colleghi e lanci le query.

1. Scarica **DBeaver Community** da [dbeaver.io/download](https://dbeaver.io/download/).
2. Installa e apri DBeaver.
3. Database → New Database Connection, scegli il motore (per questa guida, PostgreSQL) e compila host, porta, database e utente.

### PostgreSQL locale (opzionale)

DBeaver da solo non contiene i dati. Per un database sul PC:

1. Installa PostgreSQL da [postgresql.org/download/windows](https://www.postgresql.org/download/windows/).
2. Annota la password dell'utente `postgres` scelta durante il setup. Porta predefinita: `5432`. Database iniziale: `postgres`. Host: `localhost`.
3. In DBeaver usa questi valori nella connessione e testa con Test Connection prima di salvare.

Concetti e amministrazione di PostgreSQL: [PostgreSQL](postgresql.md).

---

## In sintesi

- GitHub è l'account. Git è il programma. L'editor è uno solo, a scelta.
- Node.js LTS e Python vanno nel PATH. Django e FastAPI si installano nel `venv`.
- DBeaver Community è il client SQL. Il server, se ti serve in locale, è un passo a parte.

## Vedi anche

- [Primi passi](primi-passi.md)
- [Git e commit](git.md)
- [HTML, CSS e Tailwind](html-css-tailwind.md)
- [JavaScript](javascript.md)
- [Node.js](nodejs.md)
- [Python](python.md)
- [Django](django.md)
- [FastAPI](fastapi.md)
- [Database](database.md)
