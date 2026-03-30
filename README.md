# Interview Questions (Italiano)

Repository dedicato a domande da colloquio tecnico in lingua italiana.

## Struttura
- `.cursor/rules/`: regole globali per FE, BE, DevOps, DB.
- `.cursor/skills/`: skill specializzate per tecnologia.
- `.cursor/subagents/`: catalogo subagent con mapping `rule + skill`.

## Set disponibili
1. **FE**: JavaScript, TypeScript, Angular.
2. **BE**: Java, Spring Boot, paradigmi, pattern, best practice.
3. **DevOps**: Docker, Kubernetes, OpenShift, pipeline, Helm.
4. **DB**: relazionale e NoSQL (sequence, index, consistency, tuning).

## Standard di risposta
- Domanda.
- Risposta breve e precisa.
- Spiegazione con trade-off.
- Snippet breve se utile.

## Esempio
- **Domanda**: Differenza tra array e list?
- **Risposta**: Un array ha dimensione tipicamente fissa e accesso indicizzato diretto; una list e dinamica e ottimizzata per operazioni diverse a seconda dell'implementazione.

## Guida web (MkDocs)
- Installazione: `py -m pip install -r requirements.txt`
- Avvio locale: `py -m mkdocs serve`
- Build statica: `mkdocs build`
- Cartella output: `site/`
- Policy di veridicità (fatto vs opinione, fonti, disclaimer): vedi [Per nuove risorse — Veridicità e policy](docs/per-nuove-risorse.md#veridicità-e-policy-delle-guide).

## Avvio rapido (Windows)
- `.\run.ps1`
