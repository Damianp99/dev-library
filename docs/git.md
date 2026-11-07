# Git e commit

Git registra la storia del progetto sul tuo computer. GitHub ospita quella storia e la condivide. Prima servono l'[account](strumenti.md#account-github) e [Git installato](strumenti.md#git-per-windows).

Riferimento del formato dei messaggi: [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).

---

## Indice

- [Nome ed email](#nome-ed-email)
- [Clonare un repository](#clonare-un-repository)
- [Il ciclo di lavoro](#il-ciclo-di-lavoro)
- [Branch](#branch)
- [Conventional Commits](#conventional-commits)

---

## Nome ed email

Ogni commit porta un autore. Impostalo una volta, con il nome e l'email dell'account GitHub:

```powershell
git config --global user.name "Il Tuo Nome"
git config --global user.email "tu@example.com"
```

Controlla con `git config --global --list`.

---

## Clonare un repository

Sulla pagina GitHub del progetto: Code → HTTPS, copia l'URL.

```powershell
git clone https://github.com/UTENTE/REPOSITORY.git
cd REPOSITORY
```

Se il repository è tuo e ancora solo online, `clone` scarica la copia su cui lavori. Se la cartella esiste già in locale ed è collegata a GitHub, non clonare di nuovo: entra nella cartella e usa `git pull`.

---

## Il ciclo di lavoro

Da una copia già collegata al remoto:

1. Aggiorna prima di modificare:

```powershell
git pull
```

2. Dopo le modifiche, guarda cosa è cambiato:

```powershell
git status
git diff
```

`status` elenca i file. `diff` mostra le righe.

3. Metti in stage solo ciò che vuoi nel commit:

```powershell
git add percorso/file
```

4. Crea il commit con un messaggio nel formato sotto:

```powershell
git commit -m "docs: descrive la modifica in modo concreto"
```

5. Pubblica sul branch corrente:

```powershell
git push
```

La prima volta che pubblichi un branch nuovo, il passo è nella sezione [Branch](#branch).

Per leggere la storia locale: `git log --oneline`.

!!! warning "Cosa non va nel commit"
    Password, token, file `.env` e la cartella `.venv` non si aggiungono a Git. Se un segreto è finito nello stage, toglilo con `git restore --staged percorso` prima del commit e ruota quel segreto.

---

## Branch

Un branch isola un lavoro dal branch principale (`main`).

```powershell
git switch -c feat/nome-breve
```

Lavora, poi `add` e `commit` come sopra. Al primo push di quel branch:

```powershell
git push -u origin feat/nome-breve
```

Su GitHub apri una Pull Request verso `main` quando il lavoro è pronto per la revisione. I push successivi sullo stesso branch usano solo `git push`.

Per tornare al branch principale: `git switch main`.

---

## Conventional Commits

Formato:

```text
tipo(scope): descrizione
```

Lo scope, tra parentesi, è facoltativo. La descrizione è in imperativo, breve, senza punto finale. Dice cosa cambia per chi legge la storia.

| Tipo | Quando usarlo |
|------|----------------|
| `feat` | Una funzionalità nuova |
| `fix` | Una correzione |
| `docs` | Solo documentazione |
| `refactor` | Stessa funzione, struttura diversa |
| `test` | Solo test |
| `chore` | Manutenzione che non cambia il comportamento (dipendenze, config) |

Esempi:

```text
feat(auth): aggiunge il login con JWT
fix(api): gestisce la lista ordini vuota
docs: aggiorna la guida su Git
refactor(cart): estrae il calcolo del totale
test(auth): copre il token scaduto
chore: aggiorna le dipendenze di sviluppo
```

Se serve il perché, lascialo nel corpo, dopo una riga vuota:

```text
feat(api): aggiunge il filtro per stato

Il client deve poter chiedere solo gli ordini aperti.
```

Una modifica incompatibile con chi già usa il progetto si segnala nel footer:

```text
feat(api): cambia il campo id in uuid

BREAKING CHANGE: i client che leggono id numerico vanno aggiornati.
```

Messaggi da evitare: `update`, `fix stuff`, `wip`, un punto alla fine, e un commit che mescola una feature e una modifica non correlata. Un commit, un motivo.

---

## In sintesi

- `pull`, `status`, `diff`, `add`, `commit`, `push` è il giro normale.
- Il branch si crea con `git switch -c` e si pubblica con `git push -u origin nome-branch`.
- Il messaggio è `tipo(scope): descrizione`, con scope facoltativo.

## Vedi anche

- [Strumenti — account GitHub e installazione di Git](strumenti.md)
- [Primi passi](primi-passi.md)
- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
