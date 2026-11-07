# HTML, CSS e Tailwind

Due prove separate. La prima è un file aperto nel browser, senza installare nulla oltre l'editor. La seconda usa Node.js e Tailwind, con i comandi della guida Vite ufficiale. Se quei comandi cambiano con una major nuova, segui [l'installazione con Vite](https://tailwindcss.com/docs/installation/using-vite).

JavaScript come linguaggio è in [JavaScript](javascript.md). Il runtime per il backend è in [Node.js](nodejs.md). Node va installato prima di Tailwind: [Node.js LTS](strumenti.md#nodejs).

---

## Indice

- [Prima pagina HTML](#prima-pagina-html)
- [CSS in un file](#css-in-un-file)
- [Tailwind con Vite](#tailwind-con-vite)

---

## Prima pagina HTML

1. Crea una cartella `prima-pagina`.
2. Dentro, crea `index.html`:

```html
<!DOCTYPE html>
<html lang="it">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Prima pagina</title>
    <link rel="stylesheet" href="styles.css">
  </head>
  <body>
    <h1>Prima pagina</h1>
    <p>Se leggi questo testo nel browser, HTML e CSS sono collegati.</p>
  </body>
</html>
```

3. Apri `index.html` con un doppio clic, oppure trascinalo nel browser.

Il titolo nella scheda e il titolo in pagina vengono da `<title>` e da `<h1>`. Il testo visibile sta nel `<body>`.

Per aggiungere JavaScript più avanti, crea `app.js` e, subito prima di `</body>`, inserisci `<script src="app.js"></script>`. Il linguaggio si studia nella guida [JavaScript](javascript.md).

---

## CSS in un file

Nella stessa cartella crea `styles.css`:

```css
body {
  font-family: sans-serif;
  margin: 2rem;
}

h1 {
  color: #3949ab;
}
```

Ricarica la pagina. Se il titolo non cambia colore, controlla che `href="styles.css"` e il nome del file coincidano, cartella inclusa.

HTML descrive la struttura. CSS descrive l'aspetto. Tenerli in file diversi evita di mescolare contenuto e presentazione.

---

## Tailwind con Vite

Tailwind genera il CSS dalle classi scritte nell'HTML (`text-3xl`, `font-bold`, …). Con Vite il percorso ufficiale è il plugin `@tailwindcss/vite`.

In una cartella diversa da `prima-pagina`, con Node già installato:

```powershell
npm create vite@latest mio-sito -- --template vanilla
cd mio-sito
npm install
npm install tailwindcss @tailwindcss/vite
```

Apri `vite.config.js` e registra il plugin. Su un progetto vanilla appena creato il file diventa:

```javascript
import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [tailwindcss()],
})
```

Sostituisci il contenuto di `src/style.css` con:

```css
@import "tailwindcss";
```

`src/main.js` del template importa già `./style.css`: non serve un secondo collegamento manuale.

In `index.html`, dentro `<body>`, aggiungi un titolo con classi Tailwind:

```html
<h1 class="text-3xl font-bold underline">Ciao da Tailwind</h1>
```

Avvia:

```powershell
npm run dev
```

Apri l'indirizzo locale che Vite stampa (di solito `http://localhost:5173`). Il titolo deve essere grande, in grassetto e sottolineato. Per fermare il server: Ctrl+C.

Le classi vanno scritte per intero nel sorgente. Tailwind non vede nomi di classe costruiti a runtime concatenando stringhe.

---

## In sintesi

- Una pagina statica è `index.html` più `styles.css`, aperti nel browser.
- Tailwind si installa nel progetto Vite con `tailwindcss` e `@tailwindcss/vite`, poi `@import "tailwindcss";` nel CSS.
- JavaScript e Node hanno guide proprie: qui non si ripete il ripasso da colloquio.

## Vedi anche

- [Primi passi](primi-passi.md)
- [Strumenti](strumenti.md)
- [JavaScript](javascript.md)
- [Node.js](nodejs.md)
- [Tailwind CSS con Vite](https://tailwindcss.com/docs/installation/using-vite)
