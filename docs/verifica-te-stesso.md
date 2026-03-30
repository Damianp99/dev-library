# Verifica te stesso

Usa questa pagina per **richiamare attivamente** i concetti: leggi la domanda, prova a rispondere a mente, poi apri il blocco per verificare. La risposta è breve; per il dettaglio segui il link alla guida.

---

## Java

??? "Quando usare ArrayList e quando LinkedList?"
    **ArrayList**: accesso per indice O(1), iterazione efficiente, overhead minore. **LinkedList**: inserimenti in testa/coda O(1) se hai il riferimento al nodo, ma accesso per indice O(n). In dubbio preferire ArrayList. Dettaglio: [Java — Collections](java.md#arraylist-vs-linkedlist-quando-usare-quale).

??? "Qual è il contratto tra equals e hashCode?"
    Se `a.equals(b)` allora `a.hashCode() == b.hashCode()`; oggetti uguali devono avere lo stesso hash. Override sempre entrambi insieme e usa gli stessi campi significativi. Dettaglio: [Java — OOP](java.md#equals-e-hashcode-contratto-e-implicazioni).

??? "Cosa significa che gli Stream sono lazy?"
    Le operazioni intermedie (map, filter) non eseguono subito: costruiscono una pipeline che viene valutata quando viene invocata un'operazione terminale (collect, forEach). Dettaglio: [Java — Stream API](java.md#stream-lazy-vs-eager-valutazione-e-side-effect).

??? "Checked vs unchecked exception: quando usare quale?"
    Checked per errori recuperabili che il chiamante deve gestire (IOException, SQLException); unchecked per bug e errori di programmazione (NullPointerException, IllegalArgumentException). In produzione non ingoiare eccezioni. Dettaglio: [Java — Eccezioni](java.md#checked-vs-unchecked-quando-usare-quale-e-gestione-in-produzione).

??? "Cosa sono heap, stack e Metaspace nella JVM?"
    Heap: oggetti e array; stack: frame di metodo e variabili locali; Metaspace: metadati delle classi (sostituisce PermGen). Il GC opera principalmente sull'heap. Dettaglio: [Java — JVM Basics](java.md#garbage-collection-e-memory-model-heap-stack-tipi-di-gc).

??? "Quando usare un record invece di una classe in Java?"
    Record per DTO immutabili, chiavi, risultati di query: il compilatore genera costruttore, equals, hashCode, getter. Evitare per entità JPA (serve proxy e mutabilità) o dove serve ereditarietà. Dettaglio: [Java — Records e sealed](java.md#records-e-sealed).

---

## Spring Boot

??? "Cos'è l'IoC e come si realizza la Dependency Injection?"
    IoC: il container gestisce la creazione e il ciclo di vita dei bean; la DI inietta le dipendenze (constructor, setter, field). Preferire constructor injection per immutabilità e test. Dettaglio: [Spring Boot — IoC e DI](springboot.md#ioc-e-dependency-injection).

??? "A cosa servono i profili e come si attivano?"
    Separano la configurazione per ambiente (dev, prod). File `application-{profile}.yml`; attivazione con `spring.profiles.active` (env, JVM, config). Dettaglio: [Spring Boot — Profili](springboot.md#profili-e-configurazione).

??? "Come si espone un endpoint REST che restituisce 201 Created?"
    `@PostMapping` su un metodo che restituisce `ResponseEntity<...>`. Usare `ResponseEntity.status(HttpStatus.CREATED).body(oggetto)` oppure `ResponseEntity.created(uri).body(oggetto)`. Dettaglio: [Spring Boot — REST API](springboot.md#rest-api).

??? "Perché preferire constructor injection a @Autowired su campo?"
    Constructor injection permette campi final (immutabilità), rende le dipendenze esplicite e facilita i test (si passano mock senza reflection). Dettaglio: [Spring Boot — IoC e DI](springboot.md#ioc-e-dependency-injection).

??? "A cosa servono liveness e readiness in Spring Boot Actuator?"
    Separano "sono vivo" (liveness: il processo risponde) da "posso ricevere traffico" (readiness: DB e dipendenze pronte). In Kubernetes si usano per probe: liveness failure riavvia il pod; readiness lo esclude dal Service. Dettaglio: [Spring Boot — Actuator e health](springboot.md#actuator-e-health).

---

## Angular

??? "Quando si usa ngOnInit e quando ngOnChanges?"
    **ngOnInit**: una volta dopo il primo binding degli input; ideale per setup e chiamate a servizi. **ngOnChanges**: ogni volta che cambia un @Input (solo se cambia la reference, non mutazioni in-place). Dettaglio: [Angular — Lifecycle](angular.md#lifecycle-e-hook).

??? "Cos'è la Change Detection e come si riduce con OnPush?"
    Angular controlla periodicamente se i dati sono cambiati per aggiornare la vista. OnPush: il componente viene controllato solo se cambiano i reference degli @Input o vengono emessi eventi da Observable a cui è sottoscritto con async pipe. Dettaglio: [Angular — Change Detection](angular.md#change-detection-e-zonejs).

??? "Come si protegge una route con un guard?"
    Si crea un guard che implementa `CanActivate` (o `CanActivateFn`): se restituisce true la navigazione prosegue, altrimenti si può fare redirect (es. al login). Il guard si registra nella configurazione delle route. Dettaglio: [Angular — Routing e Auth Guard](angular.md#routing-e-auth-guard).

??? "Perché è importante fare unsubscribe dagli Observable?"
    Se non ci si disconnette, le subscription restano attive anche dopo la distruzione del componente, causando memory leak e possibili errori. Usare takeUntilDestroyed, async pipe o manualmente unsubscribe in ngOnDestroy. Dettaglio: [Angular — RxJS](angular.md#rxjs).

??? "Perché usare trackBy in *ngFor?"
    Senza trackBy Angular usa l'identità dell'oggetto: se la lista viene sostituita con nuovi oggetti (stessi dati), tutti i nodi DOM vengono ricreati. Con trackBy (es. byId) solo gli elementi effettivamente cambiati vengono aggiornati, con migliore performance e stato preservato. Dettaglio: [Angular — Pipe e performance](angular.md#pipe-e-performance).

---

## Database

??? "Cosa significano ACID e quando conta averli?"
    Atomicità, Consistenza, Isolamento, Durabilità: proprietà delle transazioni in DB relazionali. Contano quando serve garantire che operazioni multiple siano tutte applicate o nessuna (es. bonifico tra conti). Dettaglio: [Database — Transazioni ACID](database.md#transazioni-acid).

??? "Quando creare un indice e quali rischi comporta?"
    Creare indici su colonne usate in WHERE, JOIN e ORDER BY per velocizzare le query. Rischio: rallentano INSERT/UPDATE perché l'indice va aggiornato; troppi indici aumentano lo spazio e la manutenzione. Dettaglio: [Database — Indici](database.md#indici).

??? "Eventual consistency vs strong consistency: trade-off?"
    Strong: ogni lettura vede l'ultima scrittura; semplice ma limita scalabilità e disponibilità. Eventual: dopo un tempo finito il sistema converge; permette scale-out e alta disponibilità ma il client può vedere dati temporaneamente non aggiornati. Dettaglio: [Database — NoSQL](database.md#consistency-eventual-vs-strong).

??? "Cos'è il problema N+1 e come si mitiga?"
    Una query per ottenere N entità e N query aggiuntive (es. per caricare una relazione per ogni entità). Mitigazione: eager load (JOIN o select_related/prefetch_related), batch load o DataLoader. Dettaglio: [Database](database.md) e guide ORM (JPA, Django).

??? "Cos'è il connection pooling e perché usarlo?"
    Il pool mantiene connessioni aperte verso il DB e le riusa per le richieste, evitando il costo di apertura/chiusura per ogni operazione. Dimensionamento: pool size in linea con max_connections del DB e numero di istanze app. Dettaglio: [Database — Connection pooling](database.md#connection-pooling).

---

## DevOps (Docker, Kubernetes, Pipeline)

??? "Perché in produzione non si usa il tag latest?"
    Il tag latest non è versionato: non si sa quale versione dell'image è in esecuzione e il rollback diventa non deterministico. Usare tag semantici (1.2.3) o digest (sha256:...). Dettaglio: [Docker — Registry e tag](docker.md#registry-e-tag).

??? "Cosa fa un Deployment in Kubernetes?"
    Dichiarazione dello stato desiderato: quante repliche del Pod, quale image, strategia di rollout, probe. Il controller Kubernetes riconcilia lo stato reale con quello desiderato (crea/aggiorna Pod, gestisce rollout). Dettaglio: [Kubernetes — Deployment](kubernetes.md#deployment-e-rollout).

??? "A cosa servono i quality gate in una pipeline?"
    Controlli automatici (test, lint, security scan) che devono passare prima di promuovere l'artefatto allo stadio successivo. Se un gate fallisce, la pipeline non procede al deploy; evita di portare bug o vulnerabilità in produzione. Dettaglio: [Pipeline — Quality gate](pipeline.md#quality-gate).

??? "Cosa fa helm rollback?"
    Ripristina una release Helm a una revisione precedente: riapplica i manifest di quella revisione. Utile per annullare un deploy problematico; richiede che le revisioni siano conservate e che image/values di quella revisione siano ancora disponibili. Dettaglio: [Helm — Rollback](helm.md#rollback).

??? "Differenza tra Route (OpenShift) e Ingress (Kubernetes)?"
    Entrambi espongono servizi HTTP all'esterno. In Kubernetes si usa Ingress + controller; in OpenShift la Route è integrata, gestisce host e TLS (edge/passthrough/reencrypt) e si crea con oc expose. Dettaglio: [OpenShift — Route](openshift.md#route), [Kubernetes — Ingress](kubernetes.md#ingress).

??? "A cosa serve un PodDisruptionBudget (PDB)?"
    Dichiarare quanti pod devono restare disponibili durante voluntary disruption (drain nodo, aggiornamento). minAvailable o maxUnavailable; l'evictor rispetta il PDB e termina i pod gradualmente, evitando downtime. Dettaglio: [Kubernetes — Risorse, Job, RBAC e PDB](kubernetes.md#risorse-job-rbac-e-pdb).

??? "Perché in pipeline si usano approval manuali per la produzione?"
    Per ambienti critici si richiede un gate manuale prima del deploy: un utente autorizzato deve approvare. Fornisce controllo umano e audit (chi ha approvato e quando); la pipeline riprende dopo l'approvazione. Dettaglio: [Pipeline — Pipeline as code, artefatti e approval](pipeline.md#pipeline-as-code-artefatti-e-approval).

---

## Kafka e RabbitMQ

??? "Kafka: cos'è un consumer group e come scala?"
    Un consumer group è un insieme di consumer con lo stesso group.id che condividono il consumo di un topic. Ogni partition è assegnata a un solo consumer del gruppo; il parallelismo massimo di lettura è pari al numero di partition. Aggiungendo consumer oltre le partition, gli extra restano idle. Dettaglio: [Kafka — Consumer group](kafka.md#consumer-group-e-scaling).

??? "Perché il consumer in Kafka (e in generale in messaggistica) deve essere idempotente?"
    Con at-least-once delivery lo stesso messaggio può essere consegnato più volte (rebalance, retry, crash). Elaborare due volte deve produrre lo stesso effetto (es. upsert per chiave, non "incrementa" senza deduplicazione); altrimenti si hanno duplicati o inconsistenza. Dettaglio: [Kafka — Idempotenza](kafka.md#idempotenza-e-exactly-once), [Architettura — Idempotenza consumer](architettura.md#idempotenza-consumer-e-deduplicazione).

??? "RabbitMQ: differenza tra exchange direct, topic e fanout?"
    **Direct**: messaggio alla queue il cui binding ha la stessa routing key. **Topic**: routing key come pattern (es. order.*, *.created). **Fanout**: ignora la key, invia a tutte le queue bindate (broadcast). Dettaglio: [RabbitMQ — Tipi di exchange](rabbitmq.md#tipi-di-exchange).

??? "Quando scegliere Kafka e quando RabbitMQ?"
    **Kafka**: event streaming, throughput molto alto, retention lunga, replay, più consumer indipendenti sullo stesso stream. **RabbitMQ**: task queue (un messaggio = un job), routing complesso, priorità, TTL per messaggio, pattern request/reply, volumi non estremi. Dettaglio: [Architettura — Message broker](architettura.md#message-broker-rabbitmq-e-kafka), [Kafka](kafka.md), [RabbitMQ](rabbitmq.md).
