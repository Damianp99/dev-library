# Spring Boot

*Livello: da Junior a Senior.*

- [Panoramica](#panoramica)
- [IoC e Dependency Injection](#ioc-e-dependency-injection)
- [REST API](#rest-api)
- [JPA e persistenza](#jpa-e-persistenza)
- [Profili e configurazione](#profili-e-configurazione)
- [Sicurezza base](#sicurezza-base)
- [Starter e auto-configuration](#starter-e-auto-configuration)
- [Actuator e health](#actuator-e-health)
- [Test (slice e integration)](#test-slice-e-integration)
- [Caching e scheduling](#caching-e-scheduling)
- [Eventi applicativi](#eventi-applicativi)
- [OpenAPI e graceful shutdown](#openapi-e-graceful-shutdown)

## Panoramica

Spring Boot è un framework che estende Spring per semplificare lo sviluppo di applicazioni enterprise: riduce la configurazione boilerplate, offre opinionated defaults e auto-configuration basata sul classpath. È orientato a delivery rapido, deployabilità (fat JAR) e integrazione con ecosistema cloud. In produzione si appoggia su IoC/DI, starter, profili e configurazione esterna per adattarsi agli ambienti senza ricompilare.

!!! tip "Prova a spiegarlo"
    Spiega a voce: cos'è l'**IoC** e perché preferire il **constructor injection** al @Autowired su campo. Poi verifica in [IoC e Dependency Injection](springboot.md#ioc-e-dependency-injection).

---

## IoC e Dependency Injection

### Cos'è l'IoC e perché preferire il constructor injection

**Definizione tecnica**  
L'**Inversion of Control (IoC)** è un principio per cui il controllo sulla creazione e sul ciclo di vita degli oggetti non è più del codice applicativo ma di un **container** (in Spring: l'ApplicationContext). Il container crea i bean, risolve le dipendenze e li inietta dove servono. La **Dependency Injection (DI)** è il meccanismo con cui le dipendenze vengono fornite dall'esterno (costruttore, setter, campo) invece di essere create direttamente dalla classe.

**Perché preferire il constructor injection a @Autowired su campo**

- **Immutabilità**: i campi possono essere `final`; le dipendenze sono obbligatorie alla costruzione e non possono essere cambiate dopo.
- **Testabilità**: nei test si passano i mock al costruttore senza usare reflection né dover avviare Spring.
- **Dipendenze esplicite**: il costruttore rende evidente da quali componenti dipende la classe; con l'injection su campo le dipendenze sono “nascoste”.
- **Ordine di inizializzazione**: con il costruttore le dipendenze sono disponibili prima di qualsiasi metodo; con @Autowired su campo l’injection avviene dopo la costruzione, con possibili NPE se si accede ai campi troppo presto.

**Mini snippet**

```java
// Preferibile: constructor injection
@Service
public class OrderService {
    private final OrderRepository orderRepository;
    public OrderService(OrderRepository orderRepository) {
        this.orderRepository = orderRepository;
    }
}

// Evitare: field injection (meno testabile, campi non final)
@Service
public class OrderServiceBad {
    @Autowired
    private OrderRepository orderRepository;
}
```

**In sintesi**: IoC = il container gestisce i bean e le dipendenze; DI = le dipendenze vengono iniettate. Constructor injection è da preferire per immutabilità, test e chiarezza.

---

### `@Component` vs `@Service` vs `@Repository`: differenze e quando usarli

**Definizione tecnica**  
Tutte e tre sono annotazioni di stereotipo che indicano a Spring di creare un bean e includerlo nel component scanning. Tecnicamente sono equivalenti per il meccanismo di registrazione nel contesto.

**Differenze pratiche**  
- `@Component`: generico, per qualsiasi bean gestito da Spring.  
- `@Service`: semantica di servizio applicativo/business logic.  
- `@Repository`: semantica di accesso dati; abilita automaticamente la traduzione delle eccezioni di persistenza in `DataAccessException`.

**Best practice applicabile**  
Usare lo stereotipo più specifico per comunicare intento e abilitare comportamenti dedicati (es. `@Repository` per la traduzione eccezioni). Evitare `@Component` quando esiste uno stereotipo appropriato.

**Mini snippet**

```java
@Service
public class OrderService {
    private final OrderRepository orderRepository;
    public OrderService(OrderRepository orderRepository) { this.orderRepository = orderRepository; }
}

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {}
```

**Rischi e mitigazioni**  
- **Rischio**: Mescolare stereotipi senza criterio riduce leggibilità e sfrutta meno le feature di Spring.  
- **Edge case**: `@Repository` su interfaccia JPA non aggiunge codice, ma su implementazione custom attiva la traduzione eccezioni; se si usa `@Component` su un DAO custom, le eccezioni JPA non vengono tradotte automaticamente.  
- **Mitigazione**: Adottare convenzioni di naming e stereotipi coerenti nel team.

---

### Bean lifecycle e scope: singleton vs prototype

**Definizione tecnica**  
Il lifecycle di un bean Spring prevede creazione, inizializzazione (post-construct), uso e distruzione (pre-destroy). Lo scope determina quante istanze esistono nel contesto: `singleton` (default) una sola, `prototype` una per ogni richiesta.

**Differenze pratiche**  
- **Singleton**: condiviso, thread-safe solo se stateless; ideale per servizi, repository, client HTTP.  
- **Prototype**: nuova istanza a ogni `getBean()` o injection; utile per oggetti con stato mutabile o non thread-safe.

**Best practice applicabile**  
Preferire singleton per la maggior parte dei bean; usare prototype solo quando serve stato isolato per richiesta. Per stato per-request usare `RequestScope` o `ThreadLocal` con attenzione.

**Mini snippet**

```java
@Component
@Scope(ConfigurableBeanFactory.SCOPE_PROTOTYPE)
public class ReportGenerator {
    private final List<String> rows = new ArrayList<>();
    public void addRow(String row) { rows.add(row); }
}
```

**Rischi e mitigazioni**  
- **Rischio**: Singleton con stato condiviso causa race condition e bug difficili da riprodurre.  
- **Edge case**: Iniettare un bean prototype in un singleton fa sì che il singleton riceva sempre la stessa istanza prototype (iniettata una sola volta); per ottenere una nuova istanza a ogni chiamata usare `ObjectFactory<T>` o `@Lookup`.  
- **Mitigazione**: Mantenere i servizi stateless; per stato per-request usare scope appropriati o `ObjectFactory`.

---

## REST API

### `@RestController` vs `@Controller`: quando usare quale

**Definizione tecnica**  
`@Controller` restituisce il nome di una view (risolto da un `ViewResolver`); `@RestController` è `@Controller` + `@ResponseBody`, quindi il valore di ritorno viene serializzato direttamente nel body della risposta (tipicamente JSON).

**Differenze pratiche**  
- **@Controller**: per applicazioni MVC con rendering server-side (JSP, Thymeleaf).  
- **@RestController**: per API REST che espongono JSON/XML; ogni metodo ritorna dati, non nomi di view.

**Best practice applicabile**  
Per API REST usare sempre `@RestController`. Per applicazioni ibride (API + pagine) separare i controller: `@RestController` per gli endpoint API, `@Controller` per le pagine.

**Mini snippet**

```java
@RestController
@RequestMapping("/api/orders")
public class OrderApiController {
    @GetMapping("/{id}")
    public OrderDto getOrder(@PathVariable Long id) {
        return orderService.findById(id);
    }
}
```

**Rischi e mitigazioni**  
- **Rischio**: Usare `@Controller` senza `@ResponseBody` su un endpoint che dovrebbe restituire JSON produce errori 404 o risposte inattese (Spring cerca una view).  
- **Edge case**: In un `@Controller`, un metodo con `@ResponseBody` sul singolo metodo funziona, ma è incoerente; preferire `@RestController` per intere classi API.  
- **Mitigazione**: Convenzione: classi con `/api/` → `@RestController`.

---

### Validazione e gestione centralizzata degli errori

**Definizione tecnica**  
La validazione si fa con Bean Validation (`@Valid`, `@NotNull`, `@Size`, ecc.) sui DTO; Spring invalida automaticamente prima dell’invocazione del metodo. La gestione centralizzata usa `@ControllerAdvice` + `@ExceptionHandler` per mappare eccezioni in risposte HTTP coerenti.

**Differenze pratiche**  
Validazione: fail-fast sui constraint; `@Valid` su `@RequestBody` blocca la richiesta se i campi non rispettano le annotazioni. `@ControllerAdvice` evita duplicazione di try-catch e standardizza il formato degli errori.

**Best practice applicabile**  
Validare sempre i DTO in ingresso; usare un `@ControllerAdvice` globale per `MethodArgumentNotValidException`, `ConstraintViolationException` e eccezioni di business; esporre un formato errore unico (es. RFC 7807 o struttura custom).

**Mini snippet**

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        var errors = ex.getBindingResult().getFieldErrors().stream()
            .collect(Collectors.toMap(FieldError::getField, FieldError::getDefaultMessage));
        return ResponseEntity.badRequest().body(new ErrorResponse("VALIDATION_ERROR", errors));
    }
}
```

**Rischi e mitigazioni**  
- **Rischio**: Non validare l’input espone a dati malformati e possibili vulnerabilità.  
- **Edge case**: `@Valid` non si applica automaticamente a `@RequestParam`/`@PathVariable`; per parametri path/query usare `@Validated` sulla classe e constraint sui parametri.  
- **Mitigazione**: Validare tutti i punti di ingresso; evitare di esporre stack trace in produzione.

---

## JPA e persistenza

### Fetch strategy e problema N+1

**Definizione tecnica**  
La fetch strategy determina quando JPA carica le associazioni: `EAGER` al caricamento dell’entità, `LAZY` al primo accesso. Il problema N+1 si verifica con `LAZY` quando si itera su una collezione e ogni accesso genera una query aggiuntiva.

**Differenze pratiche**  
- **EAGER**: rischio di over-fetching e join pesanti; sconsigliato per collezioni.  
- **LAZY**: carica on-demand; preferibile per default, ma richiede attenzione alle query in loop.

**Best practice applicabile**  
Usare `LAZY` come default; risolvere N+1 con `JOIN FETCH` o `@EntityGraph` nelle query che devono caricare associazioni. Evitare `EAGER` su collezioni.

**Mini snippet**

```java
@Query("SELECT o FROM Order o JOIN FETCH o.items WHERE o.id = :id")
Optional<Order> findByIdWithItems(@Param("id") Long id);

// Alternativa con EntityGraph
@EntityGraph(attributePaths = {"items"})
Optional<Order> findById(Long id);
```

**Rischi e mitigazioni**  
- **Rischio**: N+1 in produzione può generare centinaia di query e degradare le performance.  
- **Edge case**: `JOIN FETCH` su più collezioni può produrre cartesian product; usare `@EntityGraph` con `type = EntityGraph.EntityGraphType.FETCH` o query multiple distinte.  
- **Mitigazione**: Profilare le query (Hibernate `show_sql`, `spring.jpa.show-sql` in dev); usare `JOIN FETCH`/`EntityGraph` dove serve.

---

### `@Transactional`: propagazione e isolamento

**Definizione tecnica**  
`@Transactional` dichiara che un metodo (o una classe) partecipa a una transazione. La propagazione definisce il comportamento quando il metodo è chiamato da un contesto già transazionale; l’isolamento definisce il livello di isolamento della transazione.

**Differenze pratiche**  
- **REQUIRED** (default): usa la transazione esistente o ne crea una nuova.  
- **REQUIRES_NEW**: sospende la transazione corrente e ne apre una nuova (commit/rollback indipendenti).  
- **NOT_SUPPORTED**: esegue senza transazione anche se chiamato da contesto transazionale.

**Best practice applicabile**  
Usare `REQUIRED` per la maggior parte dei casi; `REQUIRES_NEW` per operazioni che devono committare anche se il chiamante fa rollback (es. audit log). Evitare transazioni lunghe; delimitare al livello di servizio, non nel repository.

**Mini snippet**

```java
@Transactional(propagation = Propagation.REQUIRED, rollbackFor = Exception.class)
public Order createOrder(OrderRequest request) {
    Order order = orderRepository.save(mapToEntity(request));
    auditService.logCreation(order.getId());
    return order;
}
```

**Rischi e mitigazioni**  
- **Rischio**: Transazioni lunghe tengono lock e connessioni; `REQUIRES_NEW` può causare deadlock se non usato con attenzione.  
- **Edge case**: `@Transactional` su metodi `private` o sullo stesso bean (self-invocation) non funziona: il proxy AOP non intercetta le chiamate interne.  
- **Mitigazione**: Chiamare metodi transazionali da un altro bean; usare `rollbackFor` per includere checked exception nel rollback.

---

## Profili e configurazione

### Profile e configurazione per ambiente

**Definizione tecnica**  
I profili Spring (`spring.profiles.active`) permettono di attivare set di bean e proprietà specifici per ambiente (dev, test, prod). I file `application-{profile}.yml` vengono caricati in base al profilo attivo e sovrascrivono `application.yml`.

**Differenze pratiche**  
- **application.yml**: configurazione base condivisa.  
- **application-dev.yml**: override per sviluppo (DB H2, log dettagliati).  
- **application-prod.yml**: override per produzione (DB reale, log ridotti, sicurezza).

**Best practice applicabile**  
Non mettere segreti nei file di configurazione; usare variabili d’ambiente o secret manager. Separare chiaramente dev/test/prod; in prod attivare solo i profili necessari.

**Mini snippet**

```yaml
# application.yml
spring:
  datasource:
    url: ${DB_URL:jdbc:h2:mem:app}

---
# application-prod.yml
spring:
  config:
    activate:
      on-profile: prod
  datasource:
    url: ${DB_URL}
    hikari:
      maximum-pool-size: 20
```

**Rischi e mitigazioni**  
- **Rischio**: Profilo sbagliato in produzione (es. `dev` attivo) espone dati sensibili e configurazioni non adatte.  
- **Edge case**: Più profili attivi (`dev,local`) caricano entrambi i file; l’ordine di precedenza può creare confusione se le stesse chiavi sono definite in più file.  
- **Mitigazione**: Definire il profilo tramite variabile d’ambiente (`SPRING_PROFILES_ACTIVE`); validare la configurazione all’avvio con `@ConfigurationProperties` e `@Validated`.

---

## Sicurezza base

### Configurazione base di Spring Security

**Definizione tecnica**  
Spring Security fornisce autenticazione e autorizzazione tramite una catena di filtri. La configurazione moderna usa `SecurityFilterChain` come bean per definire regole di accesso, form login, JWT, ecc.

**Differenze pratiche**  
- **Form login**: session-based, adatto a applicazioni web classiche.  
- **Stateless (JWT)**: token in header, adatto a API e SPA.  
- **Basic auth**: semplice ma poco adatto a produzione (credenziali in chiaro se non HTTPS).

**Best practice applicabile**  
Proteggere per default; whitelist esplicita per endpoint pubblici (`/api/public/**`, `/health`); usare HTTPS in produzione; non loggare password o token.

**Mini snippet**

```java
@Configuration
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/public/**", "/actuator/health").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated())
            .csrf(csrf -> csrf.disable())  // solo se API stateless
            .build();
    }
}
```

**Rischi e mitigazioni**  
- **Rischio**: Configurazione permissiva espone endpoint sensibili.  
- **Edge case**: Disabilitare CSRF su API REST è comune ma richiede che il client non usi cookie di sessione per l’auth; con JWT in header il rischio CSRF è ridotto.  
- **Mitigazione**: Audit periodico delle regole di autorizzazione; rate limiting su login; rotazione segreti.

---

## Starter e auto-configuration

### Come funziona l’auto-configuration di Spring Boot

**Definizione tecnica**  
L’auto-configuration crea bean condizionali in base al classpath, alle proprietà e ad altri bean presenti. I file `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` (o `spring.factories` nelle versioni precedenti) dichiarano le classi di auto-config da caricare.

**Differenze pratiche**  
- **Condizionale**: `@ConditionalOnClass`, `@ConditionalOnProperty` ecc. decidono se creare un bean.  
- **Ordine**: `@AutoConfigureAfter`/`@AutoConfigureBefore` controllano l’ordine rispetto ad altre auto-config.

**Best practice applicabile**  
Usare `@ConditionalOn*` per evitare bean inutili; esporre proprietà per disabilitare auto-config (`spring.autoconfigure.exclude`) quando serve; non duplicare logica già presente negli starter ufficiali.

**Mini snippet**

```java
@Configuration
@ConditionalOnClass(DataSource.class)
@ConditionalOnProperty(name = "app.feature.audit", havingValue = "true")
public class AuditAutoConfiguration {
    @Bean
    public AuditService auditService(DataSource dataSource) {
        return new AuditService(dataSource);
    }
}
```

**Rischi e mitigazioni**  
- **Rischio**: Auto-config troppo aggressive creano bean indesiderati e conflitti.  
- **Edge case**: Due auto-config che definiscono lo stesso bean con condizioni diverse possono attivarsi entrambe e causare `BeanDefinitionOverrideException` se non si usa `spring.main.allow-bean-definition-overriding=true` (sconsigliato).  
- **Mitigazione**: Condizioni strette; test con `@SpringBootTest` e profili per verificare che i bean attesi siano presenti.

---

### Creare un custom starter

**Definizione tecnica**  
Un custom starter è un modulo che fornisce dipendenze e auto-configuration per una funzionalità riusabile. Tipicamente contiene: (1) `pom` con dipendenze, (2) modulo `-autoconfigure` con `@Configuration` condizionali, (3) file di registrazione delle auto-config.

**Differenze pratiche**  
- **Starter “fat”**: un solo modulo con tutto.  
- **Starter “thin”**: modulo starter (dipendenze) + modulo autoconfigure (logica); più pulito e testabile.

**Best practice applicabile**  
Seguire la convenzione di naming `{name}-spring-boot-starter`; usare `@ConfigurationProperties` per le opzioni; documentare le proprietà con `spring-configuration-metadata.json`; fornire `spring.factories` o `AutoConfiguration.imports` corretti.

**Mini snippet**

```java
// my-starter-autoconfigure
@Configuration
@EnableConfigurationProperties(MyStarterProperties.class)
@ConditionalOnClass(MyClient.class)
public class MyStarterAutoConfiguration {
    @Bean
    @ConditionalOnMissingBean
    public MyClient myClient(MyStarterProperties props) {
        return new MyClient(props.getEndpoint(), props.getTimeout());
    }
}
```

```properties
# META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
com.example.MyStarterAutoConfiguration
```

**Rischi e mitigazioni**  
- **Rischio**: Starter mal progettati inquinano il contesto e rendono il debug difficile.  
- **Edge case**: Se lo starter ha dipendenze transitive pesanti, ogni applicazione che lo usa le eredita; usare `optional` in Maven per dipendenze non sempre necessarie.  
- **Mitigazione**: Starter minimali; `@ConditionalOnMissingBean` per permettere override; test di integrazione con applicazione sample.

---

## Actuator e health

### Actuator, health e liveness per Kubernetes
**Definizione tecnica**  
Spring Boot Actuator espone endpoint per monitoraggio e gestione: health, metrics, info, env. Con `management.endpoints.web.exposure.include` si scelgono gli endpoint da esporre. Per K8s, `livenessProbe` e `readinessProbe` usano tipicamente `/actuator/health/liveness` e `/actuator/health/readiness` (o `/actuator/health` con gruppi).

**Differenze pratiche**  
- Health aggregato: include DB, disco, custom components; `management.health.livenessstate.enabled` e `readinessstate.enabled` per separare liveness (sono vivo) da readiness (posso ricevere traffico).  
- In produzione esporre solo health e info; proteggere con sicurezza (stesso contesto o rete interna); non esporre env e beans in produzione.

**Best practice applicabile**  
Configurare gruppi health (liveness, readiness) per K8s; custom HealthIndicator per dipendenze critiche; disabilitare endpoint sensibili in prod.

**Mini snippet**

```yaml
management:
  endpoint:
    health:
      probes:
        enabled: true
  endpoints:
    web:
      exposure:
        include: health,info
```

**Rischi e mitigazioni**  
- **Rischio**: Endpoint actuator pubblici senza auth espongono informazioni; in K8s readiness errato causa traffico a pod non pronti.  
- **Mitigazione**: Restringere exposure; usare gruppi health separati per liveness (leggero) e readiness (con DB/cache).

---

## Test (slice e integration)

### @WebMvcTest, @DataJpaTest, @SpringBootTest
**Definizione tecnica**  
- **@WebMvcTest**: carica solo il layer web (controller, MockMvc); i bean sono mockati o caricati con @MockBean.  
- **@DataJpaTest**: configura H2 (o DB di test), JPA, repository; transazione rollback per test; non carica servizi o controller.  
- **@SpringBootTest**: carica il contesto completo (integration test); con @AutoConfigureMockMvc si aggiunge MockMvc; con webEnvironment si può usare server reale o mock.

**Differenze pratiche**  
Slice test sono veloci e focalizzati; @SpringBootTest è più lento ma verifica l'integrazione end-to-end. Per repository: @DataJpaTest; per controller in isolamento: @WebMvcTest con @MockBean per i servizi.

**Best practice applicabile**  
Preferire slice per unità; integration test per flussi critici (login, ordine). Usare profilo di test e DB in-memory o Testcontainers per @SpringBootTest.

**Mini snippet**

```java
@WebMvcTest(OrderController.class)
class OrderControllerTest {
    @Autowired MockMvc mvc;
    @MockBean OrderService orderService;
    @Test void getOrder() throws Exception {
        when(orderService.findById(1L)).thenReturn(Optional.of(new Order()));
        mvc.perform(get("/orders/1")).andExpect(status().isOk());
    }
}
```

**Rischi e mitigazioni**  
- **Rischio**: @SpringBootTest con contesto completo lento; dipendenze esterne (API) vanno mockate.  
- **Edge case**: @DataJpaTest con rollback: le query vedono dati inseriti nello stesso test; per isolamento tra test usare @DirtiesContext o DB pulito.

---

## Caching e scheduling

### Caching: CacheManager, @Cacheable, key e invalidazione
**Definizione tecnica**  
Spring Cache astrae una cache (ConcurrentMap, Caffeine, Redis) tramite `CacheManager`. `@Cacheable("cacheName")` sul metodo memorizza il risultato; `key` (SpEL) e `condition` controllano quando cachare. `@CacheEvict` e `@CachePut` per invalidazione e aggiornamento.

**Differenze pratiche**  
- Senza key esplicita si usa una key derivata dai parametri; per parametri complessi definire key generator.  
- Condition: `@Cacheable(condition = "#id > 0")` per evitare di cachare valori non validi.  
- Cache provider: configurare con `spring.cache.type` e dipendenze (es. caffeine, redis).

**Best practice applicabile**  
Usare per dati letti spesso e poco volatili; TTL e dimensione massima (Caffeine) per evitare crescita indefinita; @CacheEvict su metodi di scrittura o con schedule.

**Mini snippet**

```java
@Cacheable(value = "users", key = "#id", unless = "#result == null")
public User findById(Long id) { return repo.findById(id).orElse(null); }
@CacheEvict(value = "users", key = "#user.id")
public User save(User user) { return repo.save(user); }
```

**Rischi e mitigazioni**  
- **Rischio**: Cache incoerente con DB se eviction non allineata; serializzazione per cache distribuita (Redis).  
- **Edge case**: Metodi nello stesso bean chiamati tra loro: la proxy non si applica, la cache non viene usata; chiamare da un altro bean o self-inject.

### Scheduling: @Scheduled, cron, fixedRate
**Definizione tecnica**  
`@EnableScheduling` e `@Scheduled` su un metodo: esecuzione periodica con `fixedRate` (intervallo tra inizio e inizio), `fixedDelay` (tra fine e inizio), o `cron` (espressione cron). Il task gira in un thread del pool (default single-thread; configurare TaskScheduler per concorrenza).

**Differenze pratiche**  
- fixedRate: se il task dura più dell'intervallo, la successiva parte dopo il termine della precedente (con single thread).  
- Cron: per orari fissi (es. "0 0 2 * * ?" ogni notte alle 2).  
- Per ambienti multipli usare lock distribuito (es. ShedLock) per evitare esecuzione duplicata.

**Best practice applicabile**  
Usare per job leggeri (cleanup, sync); per job pesanti preferire queue (RabbitMQ, Kafka) e worker; documentare il comportamento in cluster.

**Mini snippet**

```java
@Scheduled(cron = "0 0 2 * * ?")
public void nightlySync() { ... }
@Scheduled(fixedDelayString = "${app.sync.interval:60000}")
public void poll() { ... }
```

**Rischi e mitigazioni**  
- **Rischio**: Nessun lock in cluster: più istanze eseguono lo stesso job; ShedLock o flag in DB per single-run.  
- **Edge case**: Eccezione nel metodo scheduled: il task si considera completato; loggare e gestire errori per evitare silenzio.

---

## Eventi applicativi

### @EventListener e @TransactionalEventListener
**Definizione tecnica**  
Spring Event: il publisher invia `ApplicationEvent` (o oggetto da Spring 4.2+); i listener con `@EventListener` ricevono l'evento. `@TransactionalEventListener(phase = ...)` lega l'esecuzione a una transazione: AFTER_COMMIT (default), AFTER_ROLLBACK, BEFORE_COMMIT, AFTER_COMPLETION.

**Differenze pratiche**  
- @EventListener: esecuzione sincrona nel thread della pubblicazione; per async usare @Async (e @EnableAsync).  
- @TransactionalEventListener: utile per side effect che devono avvenire solo dopo commit (invio email, notifiche) o dopo rollback (compensazione).

**Best practice applicabile**  
Usare per decoupling tra moduli; evitare logica pesante nel listener sincrono; per operazioni post-commit usare phase esplicita; gestire eccezioni per non far fallire la transazione se il listener fallisce (dipende dal design).

**Mini snippet**

```java
@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
public void onOrderPlaced(OrderPlacedEvent e) {
    notificationService.send(e.getOrderId());
}
```

**Rischi e mitigazioni**  
- **Rischio**: Listener che lancia eccezione: in sincrono propaga al publisher; in async gestire con AsyncUncaughtExceptionHandler.  
- **Edge case**: Evento pubblicato fuori transazione: @TransactionalEventListener non viene chiamato; usare @EventListener se deve sempre eseguire.

---

## OpenAPI e graceful shutdown

### OpenAPI/Swagger: integrazione e documentazione API
**Definizione tecnica**  
Springdoc OpenAPI (o springfox) genera documentazione OpenAPI 3 da controller, DTO e annotazioni; espone Swagger UI e JSON/YAML. Dipendenza `springdoc-openapi-starter-webmvc-ui`; configurazione con `springdoc.api-docs.path`, gruppi, sicurezza.

**Differenze pratiche**  
- Annotazioni su controller: @Operation, @ApiResponse; su DTO: @Schema per descrizione e esempio.  
- Integrazione con Spring Security: esporre endpoint doc e UI solo in dev o con auth; in prod spesso si limita l'accesso.

**Best practice applicabile**  
Documentare parametri e response; usare DTO dedicati per API (non entity JPA); versioning e gruppi per API multiple.

**Mini snippet**

```java
@Operation(summary = "Get user by ID")
@ApiResponse(responseCode = "404", description = "User not found")
@GetMapping("/users/{id}")
public UserDto get(@Parameter(description = "User ID") @PathVariable Long id) { ... }
```

**Rischi e mitigazioni**  
- **Rischio**: Esporre doc in produzione senza protezione; documentazione desincronizzata dal codice.  
- **Mitigazione**: Gruppi per versione; nascondere endpoint interni; integrare in pipeline (contract test).

### Graceful shutdown e gestione segnali
**Definizione tecnica**  
Con `server.shutdown=graceful`, Spring Boot alla ricezione di SIGTERM smette di accettare nuove richieste, aspetta che le richieste in corso completino (con timeout configurabile) e poi chiude il contesto. Utile in K8s e durante rollout.

**Differenze pratiche**  
- `spring.lifecycle.timeout-per-shutdown-phase`: tempo massimo di attesa (default 30s).  
- I bean che implementano SmartLifecycle possono partecipare alla fase di shutdown in ordine.  
- In K8s: terminationGracePeriodSeconds deve essere >= timeout di shutdown + tempo per terminare i thread.

**Best practice applicabile**  
Abilitare graceful in produzione; dimensionare il timeout in base al tempo medio delle richieste; evitare task lunghi che bloccano lo shutdown (interrupt o timeout).

**Mini snippet**

```yaml
server:
  shutdown: graceful
spring:
  lifecycle:
    timeout-per-shutdown-phase: 30s
```

**Rischi e mitigazioni**  
- **Rischio**: Timeout troppo breve: connessioni tagliate; troppo lungo: rollout lento.  
- **Edge case**: Thread pool (async, scheduled) che non rispettano l'interrupt; configurare awaitTermination sul pool.

## In sintesi

- IoC/DI: container gestisce i bean; `@Autowired` o constructor injection; preferire constructor per immutabilità e test.
- REST: `@RestController`, `@GetMapping`/`@PostMapping`; ResponseEntity per status e header; validazione con `@Valid`.
- JPA: `@Entity`, repository; transazioni con `@Transactional`; attenzione a N+1 e lazy loading.
- Profili: `application-{profile}.yml`; `spring.profiles.active`; configurazione per ambiente senza ricompilare.
- Sicurezza: Spring Security; form login, JWT o OAuth2; configurare CORS e CSRF in base al frontend.
- Starter e auto-configuration: convenzione sul classpath; `@ConditionalOn*` per attivare bean in base a dipendenze.
- Actuator: health, liveness/readiness per K8s; proteggere endpoint in prod. Test: @WebMvcTest, @DataJpaTest, @SpringBootTest.
- Caching: @Cacheable, key, @CacheEvict; Scheduling: @Scheduled, cron, lock in cluster. Eventi: @EventListener, @TransactionalEventListener.
- OpenAPI per documentazione API; graceful shutdown per deploy e K8s.

## Vedi anche

- [Java](java.md) — Linguaggio e ecosistema.
- [Database](database.md) — Transazioni, JPA e connection pool.
- [Sicurezza](sicurezza.md) — JWT, OAuth2 e best practice.
