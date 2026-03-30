# Sicurezza

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [Autenticazione e autorizzazione](#autenticazione-e-autorizzazione)
- [Sicurezza API](#sicurezza-api)
- [OWASP Top 10 e mitigazioni](#owasp-top-10-e-mitigazioni)
- [Security headers e secrets](#security-headers-e-secrets)
- [Audit, SAST/DAST e dependency](#audit-sastdast-e-dependency)
- [mTLS, pinning e RBAC](#mtls-pinning-e-rbac)

## Panoramica

La sicurezza è trasversale a backend e frontend: autenticazione, protezione delle API e mitigazione delle vulnerabilità comuni (OWASP Top 10). In questa guida si richiamano i concetti generali; per l’implementazione si rimanda a [Spring Boot](springboot.md#sicurezza-base), [FastAPI](fastapi.md) e [Angular](angular.md) (es. guard, HTTP interceptors) dove applicabile.

Le definizioni sono semplificate per il colloquio; per standard e dettagli normativi fai riferimento a [OWASP](https://owasp.org/), [RFC 7519 (JWT)](https://datatracker.ietf.org/doc/html/rfc7519), [RFC 6749 (OAuth2)](https://datatracker.ietf.org/doc/html/rfc6749) e alla documentazione del framework in uso.

---

## Autenticazione e autorizzazione

### JWT vs session

**Definizione**  
- **Session**: il server mantiene lo stato (es. in memoria o in store condiviso); al login viene creata una sessione e al client viene inviato un identificativo (cookie `session_id`). Le richieste successive inviano il cookie; il server risolve la sessione e l’utente.  
- **JWT (JSON Web Token)**: token firmato (HMAC o RSA) che contiene claim (es. `sub`, `exp`, `roles`). Il server non tiene stato: verifica la firma e legge i claim. Stateless lato server.

**Caso d’uso**  
Session: controllo centralizzato, revoca immediata (invalidare la sessione), cookie httpOnly per ridurre rischio XSS. JWT: scalabilità orizzontale senza store condiviso, adatto a API e microservizi; la revoca richiede blacklist o token con vita breve + refresh token.

**Trade-off**  
JWT non può essere “annullato” prima della scadenza senza un meccanismo aggiuntivo (blacklist, short expiry). Session richiede storage e gestione sessioni; in cluster serve store condiviso (Redis, DB). Dove conservare i token: vedi sotto.

**Link**  
Spring Boot: filter/middleware per validare JWT o gestire sessioni; FastAPI: dependency per estrarre e validare token; Angular: intercettore per allegare token o cookie.

### OAuth2 e OIDC (cenni)

**Definizione**  
OAuth2 delega l’autorizzazione: un client (es. la tua app) ottiene un token per accedere a risorse per conto dell’utente, senza gestire la password. Ruoli: Resource Owner (utente), Client (app), Authorization Server (emette token), Resource Server (API che protegge le risorse). OIDC (OpenID Connect) estende OAuth2 con identità: id_token (JWT) con claim sull’utente (sub, email, ecc.).

**Flow tipico (Authorization Code)**  
1. Redirect utente all’Authorization Server (login + consent).  
2. Callback con `code` al client.  
3. Client scambia `code` con token (backend, con client_secret).  
4. Client usa access_token per chiamare le API.

**Caso d’uso**  
Login con Google/GitHub/Microsoft; Single Sign-On; API che accettano token emessi da un IdP esterno. Per solo login “social” spesso basta un flow Authorization Code con PKCE su client pubblici (SPA).

**Link**  
Spring Security OAuth2/OIDC; librerie frontend (Angular: OAuth2/OIDC client) per il redirect e lo scambio del code.

### Refresh token e dove conservare i token (frontend)

**Definizione**  
L’access token ha vita breve (es. 15 min); il refresh token (vita lunga, es. 7 giorni) serve a ottenere un nuovo access token senza far rifare login. Il refresh token va usato solo dal backend (o da un endpoint sicuro) per evitare che sia esposto al JS.

**Dove conservare**  
- **httpOnly cookie**: il token non è leggibile da JavaScript; riduce il rischio XSS che rubi il token. Adeguato per session_id o per access/refresh token se l’API è sullo stesso dominio (o CORS/cookie SameSite configurati).  
- **localStorage/sessionStorage**: accessibile da JS; vulnerabile a XSS. Se si usa JWT in localStorage, mitigare XSS (escape, CSP, evitare eval e DOM non sanitizzato).  
- **In memoria**: massima sicurezza contro XSS che legge storage, ma il token si perde al refresh; spesso usato insieme a refresh in httpOnly cookie.

**Rischio XSS/CSRF**  
Con token in cookie: attenzione a CSRF (SameSite, token CSRF in header/body). Con token in localStorage: attenzione a XSS (non esporre token a script malevoli). Best practice: preferire httpOnly per token sensibili; CSP; validazione e sanitization lato server.

**Link**  
Angular: non mettere token in localStorage se non necessario; usare intercettori per allegare token da storage o cookie; Spring Boot/FastAPI: cookie sicuri, SameSite, opzione refresh endpoint.

---

## Sicurezza API

### HTTPS

**Definizione**  
Tutte le comunicazioni client–server devono usare TLS (HTTPS) in produzione per confidenzialità e integrità. I cookie sensibili vanno impostati con flag `Secure` (solo HTTPS).

**Best practice**  
Certificati validi (Let’s Encrypt, CA aziendale); redirect HTTP → HTTPS; HSTS header dove possibile. In sviluppo si può usare HTTP solo in localhost.

### CORS

**Definizione**  
CORS (Cross-Origin Resource Sharing) è un meccanismo del browser: le richieste verso un’origine diversa (dominio/porta/protocollo) sono “cross-origin”. Il server risponde con header (es. `Access-Control-Allow-Origin`, `Allow-Methods`) per autorizzare il browser a leggere la risposta. Le richieste “non semplici” (es. custom header, method diverso da GET/POST) richiedono una preflight (OPTIONS).

**Perché esiste**  
Senza CORS il browser blocca l’accesso alla risposta per policy same-origin. Il server deve esplicitamente whitelistare le origini (o usare pattern sicuri), non `*` in produzione con credenziali.

**Best practice**  
Whitelist di origini note; non usare `Access-Control-Allow-Origin: *` con cookie/credenziali; configurare metodi e header ammessi in modo restrittivo. Vedi [Spring Boot](springboot.md), [FastAPI](fastapi.md), [Node.js](nodejs.md) per configurazione CORS.

### Rate limiting

**Definizione**  
Limitare il numero di richieste per client (IP, user_id, API key) in un intervallo di tempo per mitigare abuso, DDoS e brute force.

**Dove applicarlo**  
Sul gateway, sul reverse proxy (nginx, cloud) o in middleware dell’applicazione. Per login e recupero password: limiti stretti; per API pubbliche: limiti per tier (anonimo vs autenticato).

**Esempio**  
Regola: 100 req/min per IP per endpoint API; 5 tentativi/min per login. Oltre la soglia: 429 Too Many Requests e possibile backoff indicato negli header.

**Link**  
Implementazione in [Node.js](nodejs.md) (middleware Express/Fastify), Spring Boot (filter o librerie tipo Bucket4j), FastAPI (middleware o dipendenze).

### Validazione input e sanitization output

**Definizione**  
- **Validazione input**: controllare tipo, formato, lunghezza e vincoli su tutti gli input (body, query, path, header). Sempre lato server; il client può validare per UX ma non per sicurezza.  
- **Sanitization output**: escape dell’output in HTML per evitare XSS; encoding in contesti (HTML, attributi, JS, URL). Per dati da utente o da DB non fidarsi mai “as is” in HTML.

**Best practice**  
Usare librerie di validazione (Bean Validation, Pydantic, express-validator) e whitelist; per l’output usare templating che fa escape di default (React, Angular, Thymeleaf) e evitare `innerHTML`/`dangerouslySetInnerHTML` con contenuto non sanitizzato.

**Link**  
[Spring Boot](springboot.md) (Bean Validation, @Valid); [FastAPI](fastapi.md) (Pydantic); [Angular](angular.md) (binding sicuro, sanitizer).

---

## OWASP Top 10 e mitigazioni

### Injection (SQL, NoSQL)

**Definizione**  
L’attaccante inserisce input malevolo che viene interpretato come parte di un comando (SQL, comandi OS, LDAP, ecc.). SQL injection: concatenare input nell’SQL permette di modificare la query. NoSQL injection: payload in JSON che alterano query (es. operatori `$gt`, `$where`).

**Mitigazione**  
- **Parametrizzazione**: sempre query parametrizzate o prepared statement; mai concatenare stringhe per SQL.  
- **ORM**: JPA/Hibernate, Prisma, Mongoose con API sicure (no raw string con input).  
- **NoSQL**: evitare `$where` con input utente; sanitizzare oggetti di query; whitelist sui campi.

**Link**  
[Spring Boot](springboot.md) (JPA, JdbcTemplate parametrizzato); [Database](database.md) per best practice query.

### XSS (Cross-Site Scripting)

**Definizione**  
Script malevoli iniettati in una pagina e eseguiti nel contesto di un altro utente. Reflected: input restituito subito nella risposta (es. query in URL). Stored: input salvato (es. commenti) e poi mostrato ad altri. DOM-based: la modifica avviene lato client.

**Mitigazione**  
- **Escape output**: codificare caratteri speciali HTML (`<`, `>`, `"`, `'`, `&`) quando si inserisce contenuto in HTML.  
- **CSP (Content-Security-Policy)**: restringere origini di script e risorse; riduce l’impatto di XSS.  
- **Evitare** `innerHTML` / `dangerouslySetInnerHTML` con dati non sanitizzati; preferire textContent o binding sicuri.

**Link**  
[Angular](angular.md) (sanitizer, binding); [React](react.md) (evitare dangerouslySetInnerHTML con user input); backend: escape in template server-side.

### CSRF (Cross-Site Request Forgery)

**Definizione**  
Un sito malevolo induce il browser dell’utente autenticato a inviare una richiesta non voluta al sito vittima (es. POST di modifica). Il browser invia automaticamente i cookie (inclusa la session).

**Mitigazione**  
- **CSRF token**: token casuale in form o header, verificato dal server; il sito malevolo non può leggerlo (same-origin).  
- **SameSite cookie**: `SameSite=Strict` o `Lax` riducono l’invio di cookie in richieste cross-site.  
- **Check Origin/Referer** (in aggiunta): il server verifica che la richiesta provenga da origini consentite.

**Link**  
Spring Security: CSRF token abilitato per form; Angular: HttpClient con credenziali e token in header; conservare token in cookie httpOnly con SameSite.

### Altri (cenni)

- **Broken Authentication**: password deboli, sessioni non invalidate, credential stuffing. Mitigazione: policy password, MFA, limiti login, gestione sessioni e logout.  
- **Sensitive Data Exposure**: dati sensibili in log, risposte o storage non cifrato. Mitigazione: cifratura a riposo e in transito, non loggare token/PII, mascherare in UI.  
- **XML External Entities (XXE)**: parser XML che elaborano entità esterne. Mitigazione: disabilitare DTD/entità esterne; preferire JSON o parser sicuri.  
- **Security Misconfiguration**: default insicuri, stack trace in produzione, directory listing. Mitigazione: hardening, review configurazione, dependency check.

Per ogni voce: definizione chiara, mitigazione lato BE e FE dove rilevante, e rimando alle guide (Spring Boot, FastAPI, Angular) per l’implementazione concreta.

## In sintesi

- Auth vs Authz: autenticazione (chi sei) e autorizzazione (cosa puoi fare); JWT stateless, OAuth2 per delegazione, sessioni per stateful.
- Sicurezza API: HTTPS, CORS, rate limiting, validazione input; non esporre stack trace; token in header, non in URL.
- OWASP Top 10: injection (parametrizzare, ORM), XSS (escape output), CSRF (token), broken auth (MFA, policy password).
- Security headers: CSP, HSTS, X-Frame-Options; secrets in vault, mai in codice; audit log per compliance; SAST/DAST e dependency scanning (CVE, SBOM); mTLS e pinning; least privilege e RBAC/ABAC.

## Riferimenti (fonti primarie)

- [OWASP Top 10](https://owasp.org/Top10/) — Elenco e mitigazioni delle vulnerabilità più comuni.
- [RFC 7519 — JWT](https://datatracker.ietf.org/doc/html/rfc7519) — JSON Web Token.
- [RFC 6749 — OAuth 2.0](https://datatracker.ietf.org/doc/html/rfc6749) — Authorization framework.
- [OpenID Connect](https://openid.net/connect/) — Identità su OAuth2 (id_token, userinfo).

## Vedi anche

- [Spring Boot](springboot.md), [FastAPI](fastapi.md), [Angular](angular.md) — Implementazione auth e guard.
- [Architettura](architettura.md) — API design e versioning.
