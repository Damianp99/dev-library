# AGENTE_CONTESTO

Ultimo aggiornamento: 30/03/2026

## Indice
- [1. Stato attuale](#1-stato-attuale)
- [2. Contesto operativo](#2-contesto-operativo)
- [3. Changelog](#3-changelog)
- [4. Prossimi passi](#4-prossimi-passi)

## 1. Stato attuale
- Il repository contiene una guida tecnica in italiano per preparazione colloqui e onboarding, organizzata per macro-aree: Frontend, Backend, Database, Architettura e integrazione, DevOps.
- La documentazione vive in `docs/` ed e pubblicata tramite MkDocs Material con configurazione centrale in `mkdocs.yml`.
- Le guide coprono stack e temi principali gia presenti nel sito: JavaScript, TypeScript, Angular, React, Vue, Java, Spring Boot, Go, Python, Django, FastAPI, Database, PostgreSQL, Oracle DB, MongoDB, Architettura, Sicurezza, GraphQL, Redis, Kafka, RabbitMQ, Docker, Kubernetes, OpenShift, Pipeline, Helm.
- L'avvio locale e previsto via `run.ps1`, che installa le dipendenze Python da `requirements.txt` e lancia `mkdocs serve` con watch su `docs` e `styles.css`.
- Esiste una base di governance per gli agenti in `.cursor/`, con regole per aree tecniche e una rule sempre attiva che impone l'aggiornamento di questo file quando si completa un lavoro significativo.
- E presente un piano iniziale di validazione snippet in `scripts/verify-snippets/README.md`, con copertura esplicita per JavaScript e backlog per Python, Go e verifiche manuali su SQL/comandi.
- Stato Git osservato al bootstrap: branch `main` con tracking remoto degradato (`origin/main [gone]`) e molti file ancora non tracciati nella working tree.

## 2. Contesto operativo
- Fonte di verita: README, contenuti effettivi in `docs/`, configurazione `mkdocs.yml` e script realmente presenti nel repo.
- Obiettivo editoriale: risposte da colloquio in italiano, sintetiche ma operative, con trade-off, snippet brevi e riferimento a casi enterprise/onboarding.
- Policy contenuti: distinguere fatti verificabili da raccomandazioni; per versioni specifiche o comportamenti runtime fare riferimento alla documentazione ufficiale e, dove possibile, a snippet verificati.
- Stack di riferimento dichiarato nella panoramica: Node 20 LTS, Java 21, Python 3.12, Kubernetes 1.29+, PostgreSQL 16, MongoDB 7.
- Questo file va mantenuto ad alto livello: milestone, stato reale del progetto, decisioni e backlog. Evitare micro-log di singoli rename o formattazioni.

## 3. Changelog
| Data | Cosa | Come | Perché |
|------|------|------|---------|
| 30/03/2026 | Bootstrap contesto progetto | Sintesi iniziale derivata da `README.md`, `docs/index.md`, `docs/per-nuove-risorse.md`, `mkdocs.yml` e `scripts/verify-snippets/README.md` | Fornire handoff operativo affidabile agli agenti successivi e allineare il contesto allo stato reale del repo |

## 4. Prossimi passi
1. Verificare e sistemare il versionamento Git: capire se il remote va ripristinato o ridefinito e portare i file attuali sotto versionamento coerente.
2. Formalizzare la validazione snippet oltre JavaScript, iniziando da Python e Go, con script/versioni di riferimento esplicite.
3. Valutare l'aggiornamento di `.gitignore` per artefatti generati come `site/` se non devono essere committati.
4. Continuare il mantenimento editoriale delle guide: revisioni periodiche di versioni, link interni, trade-off e coerenza tra percorsi, glossario e verifica.
5. Valutare una CI minima per `mkdocs build` e per gli script di verifica snippet gia disponibili.
