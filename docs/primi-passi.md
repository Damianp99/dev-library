# Primi passi

Checklist per mettere su il computer e arrivare alla prima pagina web. Ogni voce linka il dettaglio: i comandi stanno nelle pagine collegate, non qui.

Le guide in **Guide** restano il ripasso da colloquio (JavaScript, Python, Django, FastAPI, SQL). Qui c'è solo l'ordine con cui installare e da dove continuare.

---

## Indice

- [Ordine consigliato](#ordine-consigliato)
- [Poi studia](#poi-studia)

---

## Ordine consigliato

1. [ ] [Account GitHub](strumenti.md#account-github)
2. [ ] [Git per Windows](strumenti.md#git-per-windows) — su macOS o Linux usa il link indicato in quella sezione
3. [ ] [Ciclo di Git e Conventional Commits](git.md)
4. [ ] [Un editor](strumenti.md#scegli-un-editor): VS Code, Cursor, Claude Code oppure WebStorm
5. [ ] [Node.js LTS](strumenti.md#nodejs)
6. [ ] [Python, Django e FastAPI](strumenti.md#python-django-e-fastapi)
7. [ ] [DBeaver e SQL](strumenti.md#sql-e-dbeaver)
8. [ ] [Prima pagina HTML e CSS](html-css-tailwind.md#prima-pagina-html)
9. [ ] [Tailwind con Vite](html-css-tailwind.md#tailwind-con-vite)

HTML, CSS e JavaScript nel browser non si scaricano: li esegue il browser. Node.js serve a npm, a Tailwind e al backend JavaScript.

---

## Poi studia

Quando gli strumenti rispondono ai comandi di verifica (`git --version`, `node -v`, `py --version`), passa alle guide di contenuto:

| Stack | Da leggere |
|-------|------------|
| Frontend | [HTML, CSS e Tailwind](html-css-tailwind.md), poi [JavaScript](javascript.md) |
| Backend JavaScript | [Node.js](nodejs.md) |
| Backend Python | [Python](python.md), poi [Django](django.md) oppure [FastAPI](fastapi.md) |
| Dati | [Database](database.md) e, se hai installato PostgreSQL, [PostgreSQL](postgresql.md) |

Per il ripasso per ruolo usa i [Percorsi di studio](percorsi.md).

---

## In sintesi

- Un account GitHub, Git, un solo editor, Node.js LTS, Python e DBeaver bastano per iniziare.
- Django, FastAPI e Tailwind si installano con un package manager, non con un installer separato dal linguaggio.
- Le guide di linguaggio e framework sono già nel sito: da qui si linkano, non si riscrivono.

## Vedi anche

- [Strumenti](strumenti.md)
- [Git e commit](git.md)
- [HTML, CSS e Tailwind](html-css-tailwind.md)
- [Per nuove risorse](per-nuove-risorse.md)
