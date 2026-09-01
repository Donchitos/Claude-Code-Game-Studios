# ADR-0004: Ciclo de vida de era y orden de inicialización — servicio `EraManager`

## Status
Proposed

## Date
2026-08-21

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (carga de recursos, orden de inicialización de Autoloads, orquestación de arranque) |
| **Knowledge Risk** | MEDIUM |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/breaking-changes.md` (4.5: `duplicate_deep()` para Resources anidados — **no** usado aquí, el `EraDefinition` es read-only); `docs/engine-reference/godot/deprecated-apis.md` (sin entradas de I/O de recursos o carga) |
| **Post-Cutoff APIs Used** | Ninguna. La decisión usa `ResourceLoader.load()` **síncrono** (estable desde 4.0) y el orden de init de Autoloads (estable). La API threaded (`load_threaded_request`/`get_status`/`get`) queda como camino de migración explícito, **no** usada en el MVP. |
| **Verification Required** | (1) Confirmar en 4.6 el orden de init de Autoloads: se inicializan en el orden listado en `project.godot`, **antes** del árbol de la escena principal — la regla de init-ordering depende de esto (confirmado por godot-specialist 2026-08-21: estable, sin cambios hasta 4.6). (2) Confirmar que `ResourceLoader.load(path)` síncrono con `CACHE_MODE_REUSE` (default) devuelve la misma instancia compartida del `.tres` de era en cargas repetidas (confirmado; coherente con "inmutable, compartido por era"). (3) Una referencia de sub-recurso `@export` rota (`kaiju_definition`/roster ausente) dentro de un `.tres` que **sí** parsea deja ese campo en **`null`** y Godot imprime un mensaje a consola **no atrapable** desde GDScript — **no** hay un error de retorno/excepción que inspeccionar. El único señal observable programáticamente es el campo `null`, así que el gate lo atrapa con un **check explícito de resolución de referencias** (no esperando un valor de retorno de `ResourceLoader.load`). Distinto del recurso top-level ausente, donde `ResourceLoader.load` sí devuelve `null` (ver Decision). |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (duro). Interactúa en el arranque con ADR-0002 (`TimeControl`, Autoload) y ADR-0003 (`SaveService`, Autoload): el orden de los tres Autoloads y la secuencia de boot se fijan aquí, pero ninguno es prerequisito de Accepted del otro. |
| **Enables** | Epics de todo sistema que lee datos de era en el momento correcto (Tropas, Héroes, Kaiju, Temporizador, Permadeath, Reliquias, Forja); el ADR futuro de Transición de Era (#15) hereda esta máquina de estados; el ADR de Cámara/Control puede reubicar `world_unit_scale`/`camera_pan_speed`/`zoom_*` sin tocar este contrato |
| **Blocks** | Ningún epic puede implementar lectura de datos de era hasta que este ADR sea Accepted (define cuándo/cómo es seguro leer una era y quién conduce el ciclo de vida) |
| **Ordering Note** | Cuarto ADR. Segundo gap Foundation del `/architecture-review 2026-08-21` (tras Save/Persistencia S4). No bloquea a ADR-0003 ni al revés, pero la secuencia de boot (SaveService → EraManager → era_loaded → consumidores) los ata en implementación. |

## Context

### Problem Statement

`datos-de-era-civilizacion.md` (Foundation, el sistema del que más otros dependen) ya define la máquina de estados de una era — `UNLOADED → LOADING → LOADED → ACTIVE → ARCHIVED` (States and Transitions, AC-7..AC-12/AC-15/AC-19) — y ya establece contratos clave que la asumen:
- **Permadeath** lee `get_hero_roster_count()` **sobre la señal era-`LOADED`, explícitamente no en su propio `_ready()`** (Datos de Era Interactions/Dependencies, cierra Permadeath OQ-P6 #6) — para validar la feasibilidad de su cap de bloqueo total (Regla 8).
- El GDD exige **loud-fail al cargar `EraDefinition`** para varias validaciones cross-resource: `max_band_size ≥ Σ starting_count_[tipo]` (R1, 2026-08-21, Tropas AC-34), y "en el mismo camino de carga centralizado que los checks cross-resource de Kaiju (AC-K74/K85)". El Temporizador valida `approach_duration_s > 0` y `0 < imminent_window_s < approach_duration_s` al inicializarse (AC-T17/T18). Permadeath valida su cap contra `get_hero_roster_count()`.
- Edge Case: "si un sistema solicita `unit_roster` mientras la era está en `LOADING`, la solicitud se bloquea/encola hasta `LOADED`; nunca datos parciales" (AC-15).

Pero **nada de esto tiene un dueño ni un mecanismo fijado**:
- **Nadie conduce la máquina de estados.** El `EraDefinition` es un `Resource` puro de datos (Regla 1/3: inmutable, sin lógica) — no puede poseer su propio ciclo de carga, validación, ni emitir señales. No hay un sistema que ejecute `UNLOADED→LOADING→LOADED→ACTIVE→ARCHIVED`.
- **El mecanismo de carga async (`LOADING→LOADED`) no está fijado** — ni síncrono ni threaded.
- **El contrato de la señal era-`LOADED` no está formalizado.** Permadeath lo asume, pero no hay firma, dueño, ni una regla general de que *todos* los consumidores lean en esa señal.
- **La regla de init-ordering no está escrita** — y es la trampa central: en Godot, el `_ready()` de un Autoload corre al arranque del motor, **antes** de que ninguna era esté cargada. Un sistema que lea datos de era en su `_ready()` (roster, kaiju, `max_band_size`, `get_hero_roster_count`, `invocation_charges`, `approach_duration_s`…) leería `null`/basura. Este es exactamente el bug que el contrato de Permadeath evita puntualmente, pero sin una regla general todos los demás consumidores pueden caer en él.
- **Las validaciones cross-resource loud-fail están dispersas** entre GDDs (Datos de Era, Kaiju, Temporizador, Permadeath, Tropas) sin un gate único que las ejecute en un solo punto antes de que ningún consumidor lea.

El `/architecture-review 2026-08-21` marcó esto como el segundo gap Foundation (`TR-era-011`, `TR-permadeath-017`).

### Constraints

- **`EraDefinition` es un `Resource` puro, inmutable, sin lógica** (Datos de Era Reglas 1/3/5) — el ciclo de vida NO puede vivir dentro del Resource; necesita un servicio separado.
- **Loud-fail sobre degradación silenciosa** (precedente Héroes/Combate/ADR-0001/0002/0003) — una era con datos inválidos (config cross-resource rota, referencia ausente) debe fallar ruidosamente al cargar, nunca activarse parcialmente ni sustituir defaults (Datos de Era AC-16).
- **DI sobre singletons** (coding-standards) — testeable en aislamiento; el ciclo de vida no debe acoplarse a Autoloads por nombre global; los tests inyectan una era falsa / una ruta de test.
- **Exactamente una era `ACTIVE` a la vez** (Datos de Era AC-9), y `ARCHIVED→ACTIVE` prohibido sin un ciclo `LOADING→LOADED` fresco (AC-11/AC-12).
- **Interacción de arranque con dos Autoloads ya decididos**: `SaveService` (ADR-0003) determina **qué** `era_id` cargar (el save persiste el `era_id` activo por referencia, nunca copia `EraDefinition`); `TimeControl` (ADR-0002) es independiente de la era pero comparte el espacio de orden de Autoloads. La secuencia de boot debe quedar definida.
- **MVP de una sola era**: el invariante de "una `ACTIVE`" y las transiciones deben probarse aunque el MVP tenga `narrative_order=0` sin siguiente era (Datos de Era AC-14).

### Requirements

- Un dueño único del ciclo de vida de era que conduzca `UNLOADED→LOADING→LOADED→ACTIVE→ARCHIVED`.
- Un mecanismo de carga fijado para `LOADING→LOADED`.
- Una señal `era_loaded` con firma y contrato definidos, y una **regla de init-ordering** explícita: los sistemas leen datos de era en `era_loaded`, nunca en `_ready()`.
- Un **gate de validación centralizado** que ejecute todas las validaciones cross-resource loud-fail en un solo punto, antes de que ningún consumidor lea.
- Una secuencia de boot definida entre `SaveService` → `EraManager` → consumidores.
- Testeable: inyectable, sin RNG ni I/O real en la lógica de estados (mock de carga / era falsa).

## Decision

**Se introduce un servicio Core `EraManager` que posee y conduce el ciclo de vida de era.** El `EraDefinition` permanece un `Resource` de datos puro e inmutable; `EraManager` es el único que lo carga, valida, transiciona entre estados y anuncia esos cambios por señal. Ningún otro sistema conduce el ciclo ni instancia eras directamente.

**Carga síncrona (`ResourceLoader.load()`), `LOADING→LOADED` instantáneo en un frame.** `EraManager.load_era(era_id)` transiciona `UNLOADED→LOADING`, llama `ResourceLoader.load(path)` (bloqueante, `CACHE_MODE_REUSE` default → instancia compartida del `.tres`), y **antes de nada chequea si el retorno es `null`**: un recurso top-level ausente/no-parseable (ej. `era_id` inexistente de un save manipulado o corrupto, o un typo de ruta en dev) hace que `ResourceLoader.load()` devuelva `null` — el flujo va directo a `FAILED` con la razón `"era_resource_not_found"`, **sin** invocar el gate (llamar `_validate(null)` o acceder a cualquier campo de una era nula crashearía, rompiendo el invariante "nunca crashea, siempre `FAILED`"). Este caso es distinto de una **referencia de sub-recurso rota dentro** de un `.tres` que sí parsea (ej. `kaiju_definition` no resuelve): ahí `ResourceLoader.load()` devuelve un `EraDefinition` **no-nulo** con el campo roto en `null`, y Godot imprime un error a consola (no una excepción atrapable); ese caso lo atrapa el check explícito de resolución de referencias del gate. Solo si el retorno es no-nulo se ejecuta el gate y se transiciona a `LOADED`. Para el MVP de una era con `.tres` pequeños esto es determinista y sin polling; el Edge Case "encolar solicitudes durante `LOADING`" (AC-15) se satisface trivialmente porque la ventana `LOADING` es una sola llamada síncrona. **La máquina de estados se diseña para admitir carga threaded después sin cambiar el contrato**: si en producción aparecen hitches o se quiere una pantalla de carga entre eras, `LOADING` pasa a ser un estado multi-frame conducido por `ResourceLoader.load_threaded_request`/`get_status`/`get`, y `era_loaded` sigue emitiéndose igual al completar — los consumidores no cambian.

**Gate de validación centralizado en `LOADING→LOADED`, antes de `era_loaded`.** `EraManager` ejecuta **todas** las validaciones cross-resource loud-fail en una sola pasada al terminar la carga, antes de emitir `era_loaded`:
- `max_band_size ≥ Σ starting_count_[tipo]` sobre `unit_roster` (Datos de Era R1 / Tropas AC-34).
- Feasibilidad de la garantía de ≥30s de Kaiju: `ceil(hero_max_health / kaiju_attack_damage) × kaiju_attack_cooldown_s + telegraph_duration_s ≥ 30` (Kaiju F2 / AC-K74) y los checks cross-resource de AC-K85.
- Feasibilidad del cap de bloqueo total de Permadeath: `death_hold_total_lockout_cap_s ≥ get_hero_roster_count() × death_hold_min_compressed_s` (Permadeath Regla 8).
- Rangos del Temporizador: `approach_duration_s > 0`, `0 < imminent_window_s < approach_duration_s` (Temporizador AC-T17/T18).
- Resolución de referencias: `kaiju_definition` y las referencias del `unit_roster` cargan (no rotas/ausentes) — Datos de Era AC-16.

**Semántica de fallo — hard stop, nunca activación parcial.** Si cualquier validación falla, `era_loaded` **NO se emite**, la era entra a un estado terminal **`FAILED`** (extensión de la máquina de estados del GDD para el camino de error), se emite `era_load_failed(era_id, razones)`, y la era **nunca alcanza `ACTIVE`**. El control de flujo (no emitir `era_loaded`, llegar a `FAILED`, emitir `era_load_failed`) es **build-agnóstico** — se comporta igual en dev y en release, no depende de visibilidad de build. Se acompaña de `push_error()` (siempre se ejecuta, dev y release) para dejar traza; un `assert()` adicional es un trampa **solo de dev, suplementaria, nunca load-bearing** para el control de flujo (se compila a no-op en export de release — misma distinción que ADR-0002 dibuja para sus asserts defensivos). Un `EraDefinition` con config cross-resource rota es un error de autoría que jamás debe llegar a jugarse; el gate lo atrapa en un punto, no diez sistemas a medias. (Cada GDD dueño de un check retiene la **especificación** del invariante; `EraManager` es el punto único de **ejecución** — no reimplementa la lógica de dominio, invoca a cada validador.)

**Señal `era_loaded(era: EraDefinition)` + regla de init-ordering.** Los consumidores se conectan a `era_loaded` y leen los datos de era **en el handler de esa señal**, recibiendo el `EraDefinition` por referencia. La regla dura: **ningún sistema lee datos de era en su `_ready()` / en la inicialización de Autoload** — el `_ready()` corre al arranque del motor, antes de que exista ninguna era `LOADED`, así que una lectura ahí devuelve `null`/basura. Esto generaliza el contrato puntual que Permadeath ya tiene (leer `get_hero_roster_count()` en era-`LOADED`, no en `_ready()`) a **todos** los consumidores. Se registra como patrón prohibido (grep CI: lecturas de campos de `EraDefinition` en `_ready()`).

**Secuencia de boot (orquestación entre Autoloads).** Los tres Autoloads Core (`EraManager`, `TimeControl`, `SaveService`) en su `_ready()` **solo se cablean** — ninguno lee datos de era. Un composition root (la escena principal / un orquestador de arranque) conduce:
1. `SaveService.request_load()` → determina el `era_id` activo (o `NO_SAVE_EXISTS` → partida nueva → era con `narrative_order = 0`).
2. `EraManager.load_era(era_id)` → `UNLOADED→LOADING` (`ResourceLoader.load`) → gate de validación → `LOADED` (emite `era_loaded(era)`) **o** `FAILED` (loud-fail).
3. Los consumidores conectados a `era_loaded` leen sus porciones; el estado persistido **por era** (cargas de invocación, modificadores activos con `remaining_ticks` — ADR-0003) se aplica en este punto.
4. `EraManager.activate_era()` → `LOADED→ACTIVE` (emite `era_activated(era)`).

`TimeControl` es independiente de la era (su `game_tick` arranca en 0 por sesión — ADR-0002/0003); no participa de esta secuencia salvo por compartir el orden de Autoloads.

**Restricción de posición del composition root (evita la carrera de señal perdida — godot-specialist, revisión 2026-08-21).** Como la carga es síncrona, `era_loaded` se emite **dentro del mismo call stack** de `load_era()` — no hay ventana multi-frame, y las señales de Godot **no se re-emiten** para suscriptores tardíos. Que "todos los consumidores estén conectados antes de que `load_era()` corra" **no** lo garantiza el orden Autoload-vs-escena por sí solo; depende de dónde viva el composition root en el árbol. El `_ready()` intra-escena de Godot es **bottom-up** (hijos antes que el padre), así que la garantía se sostiene si y solo si **el composition root es ancestro de todos los consumidores de `era_loaded` y dispara `load_era()` desde su propio `_ready()` (o más tarde)** — para entonces los `_ready()` de todos los consumidores descendientes ya corrieron y ya conectaron. Esta es una restricción de posición en el árbol, no solo de orden de Autoloads; se documenta en el control-manifest.

**Nodos instanciados post-boot (tropa spawneada a mitad de partida, panel de UI perezoso).** Por definición `era_loaded` ya se emitió cuando existen, así que **no** pueden depender de atraparla — leen el estado de era llamando **`EraManager.get_active_era()` directamente** (seguro una vez hay una era `ACTIVE`). Corolario para el enforcement: el grep de CI "sin lecturas de `EraDefinition` en `_ready()`" debe **exceptuar explícitamente** las lecturas vía `get_active_era()` en `_ready()` cuando ya hay una era `ACTIVE` — es un patrón legítimo para nodos dinámicos post-boot; la regla prohíbe leer campos de era en `_ready()` **asumiendo que ya hay era cargada al boot**, no leer vía el accesor cuando genuinamente ya la hay.

**Wiring: Autoload sostenido pero inyectado por referencia** (mismo patrón que `TimeControl` de ADR-0002 y `SaveService` de ADR-0003). Un ciclo de vida de era canónico es un concern transversal legítimo; la inyección preserva la testabilidad DI-sobre-singletons. Prohibido `get_node("/root/EraManager")` disperso: los consumidores reciben la referencia en una pasada de wiring (composition root) o se conectan a `era_loaded` vía esa referencia.

### Architecture Diagram

```
   Boot (composition root / escena principal):
     SaveService.request_load()  ──► era_id activo (o narrative_order=0 en partida nueva)
                                        │
                                        ▼
   ┌──────────────────────────────────────────────────────────────┐
   │  EraManager (Core Autoload, inyectado por referencia)         │
   │                                                                │
   │  load_era(era_id):                                            │
   │    UNLOADED → LOADING   (ResourceLoader.load, síncrono)        │
   │      │                                                         │
   │      ▼  gate de validación (una pasada, loud-fail):           │
   │        · max_band_size ≥ Σ starting_count  (Tropas AC-34)     │
   │        · Kaiju ≥30s feasibility            (Kaiju AC-K74/K85) │
   │        · Permadeath cap ≥ roster×min       (Permadeath R8)    │
   │        · Temporizador approach/imminent     (AC-T17/T18)       │
   │        · refs kaiju/roster resuelven        (Datos AC-16)      │
   │      │                                                         │
   │      ├─ pasa → LOADED ──emit era_loaded(era)──┐               │
   │      └─ falla → FAILED (push_error, NUNCA ACTIVE)             │
   │                                                │               │
   │  activate_era(): LOADED → ACTIVE ─emit era_activated(era)     │
   │  archive_active_era(): ACTIVE → ARCHIVED ─emit era_archived   │
   └────────────────────────────────────────────────┼─────────────┘
                                                     │ era_loaded(era)
        Consumidores (leen en el handler, NUNCA en _ready()):
        Tropas(unit_roster,max_band_size) · Héroes(roster) · Kaiju(kaiju_definition)
        · Temporizador(approach/imminent) · Permadeath(get_hero_roster_count)
        · Reliquias(invocation_charges) · Forja(origin_era_id de la era ACTIVE)
        · SaveService (aplica estado persistido por-era)

   REGLA DE INIT-ORDERING: el _ready() de un Autoload corre al boot, ANTES de
   que ninguna era esté LOADED. Leer datos de era en _ready() = null/basura.
   → Todo consumidor lee en era_loaded, nunca en _ready(). (patrón prohibido, grep CI)
```

### Key Interfaces

```gdscript
# EraManager — servicio Core. Autoload que sostiene el ciclo de vida, PERO inyectado por
# referencia (no EraManager.* por nombre disperso). Los tests inyectan un cargador falso /
# un EraDefinition de test para probar la máquina de estados sin ResourceLoader ni disco.
class_name EraManager extends Node

enum EraState { UNLOADED, LOADING, LOADED, ACTIVE, ARCHIVED, FAILED }

signal era_loaded(era: EraDefinition)             # SOLO tras pasar el gate de validación
signal era_activated(era: EraDefinition)
signal era_archived(era: EraDefinition)
signal era_load_failed(era_id: StringName, reasons: PackedStringArray)  # compañero loud-fail

var current_state: EraState = EraState.UNLOADED
var active_era: EraDefinition = null              # null hasta que una era esté ACTIVE

func load_era(era_id: StringName) -> void
# UNLOADED->LOADING: var era := ResourceLoader.load(_path_for(era_id)) (síncrono, CACHE_MODE_REUSE).
#   if era == null:  -> FAILED + push_error + emit era_load_failed(era_id, ["era_resource_not_found"])
#                       (recurso top-level ausente/corrupto; NO se llama _validate, evita crash null-ref)
# Solo si era != null: corre _validate(era); si pasa -> LOADED + emit era_loaded(era);
#   si devuelve violaciones -> FAILED + push_error + emit era_load_failed(era_id, violaciones).
# NUNCA llega a LOADED/ACTIVE con una era nula o con validaciones rotas.
func activate_era() -> void       # LOADED -> ACTIVE (exactamente una ACTIVE); emit era_activated
func archive_active_era() -> void # ACTIVE -> ARCHIVED; emit era_archived; active_era = null
func get_active_era() -> EraDefinition   # null si ninguna ACTIVE

# Gate de validación centralizado (loud-fail, corre antes de era_loaded).
# EraManager EJECUTA; cada GDD dueño retiene la ESPECIFICACIÓN del invariante.
func _validate(era: EraDefinition) -> PackedStringArray   # devuelve violaciones; vacío = ok
#   - max_band_size >= sum(starting_count_[tipo])                    (Tropas AC-34 / Datos R1)
#   - ceil(hero_max_health/kaiju_attack_damage)*attack_cooldown_s
#       + telegraph_duration_s >= 30                                 (Kaiju F2/AC-K74)
#   - checks cross-resource de Kaiju AC-K85
#   - death_hold_total_lockout_cap_s
#       >= era.get_hero_roster_count() * death_hold_min_compressed_s (Permadeath R8)
#   - approach_duration_s > 0 ; 0 < imminent_window_s < approach_duration_s (Temporizador AC-T17/18)
#   - kaiju_definition y refs de unit_roster resuelven (no rotas)    (Datos AC-16)
```

**Contrato de invariantes (loud-fail):**
- `era_loaded` se emite **solo** tras pasar el gate completo — nunca con una violación pendiente.
- Exactamente una era en `ACTIVE` en todo momento (Datos de Era AC-9). `activate_era()` desde un estado ≠ `LOADED` es un error.
- `ARCHIVED→ACTIVE` sin un ciclo `LOADING→LOADED` fresco está prohibido (AC-11/AC-12).
- Ningún sistema lee campos de `EraDefinition` en su `_ready()` / init de Autoload **asumiendo que ya hay era cargada al boot** — los consumidores de boot leen en el handler de `era_loaded`. Excepción legítima (no viola la regla): un nodo instanciado **post-boot** puede leer vía `EraManager.get_active_era()` en su `_ready()` cuando ya hay una era `ACTIVE`. El grep de CI exceptúa las lecturas vía `get_active_era()`.
- `FAILED` es terminal para ese intento de carga; se sale de él solo con un nuevo `load_era` (nunca se "repara" una era inválida en sitio).
- `EraManager` **nunca** muta el `EraDefinition` (Resource inmutable, Datos de Era R3/AC-3).

## Alternatives Considered

### Alternative 1: Plegar el ciclo de vida en `SaveService` (ADR-0003)
- **Description**: `SaveService` ya determina qué `era_id` cargar; extenderlo para también cargar el `EraDefinition`, validarlo y emitir `era_loaded`.
- **Pros**: Un Autoload menos; la secuencia "qué era → cargar era" queda en un solo lugar.
- **Cons**: Mezcla dos concerns distintos — `SaveService` es infraestructura de *serialización de estado mutable* (ADR-0003), agnóstica de dominio; el ciclo de vida de era es *orquestación de contenido* con un gate de validación cross-resource específico del dominio. Acoplarlos hace a `SaveService` conocer la validación de Kaiju/Permadeath/Tropas, rompiendo su neutralidad de dominio. Además Transición de Era (#15) conducirá `ACTIVE→ARCHIVED→siguiente` — eso es lógica de era, no de guardado.
- **Rejection Reason**: Viola la separación de concerns que ADR-0003 fijó explícitamente (`SaveService` no conoce el significado de los campos). El ciclo de vida es un dueño Core propio.

### Alternative 2: Sin dueño — cada consumidor carga y valida su porción
- **Description**: Cada sistema carga el `EraDefinition` (o su porción) cuando lo necesita y valida su propio slice en `era_loaded`.
- **Pros**: Sin servicio nuevo; cada sistema "posee" lo que le importa.
- **Cons**: Es el estado roto actual — sin dueño de la máquina de estados, sin punto único que garantice "una `ACTIVE`", validaciones loud-fail dispersas que dejan que una era rota active parcialmente antes de que un consumidor la atrape, y N cargas del mismo Resource. La regla de init-ordering no tendría un emisor canónico de `era_loaded`.
- **Rejection Reason**: Exactamente lo que el review marcó como gap; no da atomicidad de "válida o nada" ni un dueño de las transiciones.

### Alternative 3: Carga threaded (`load_threaded_*`) desde el MVP
- **Description**: Usar `ResourceLoader.load_threaded_request`/`get_status`/`get` para una carga async real en hilo de fondo desde el inicio.
- **Pros**: `LOADING` es un estado multi-frame genuino; permite pantalla de carga y escala a eras grandes.
- **Cons**: Añade polling de estado, gestión de hilo y una superficie de estados más compleja que el MVP de una sola era con `.tres` pequeños no necesita. La rearquitectura de interpolación de física 3D de 4.5 no aplica aquí, pero la carga threaded tiene sus propias aristas (orden de completado, errores async) que no vale la pena pagar hoy.
- **Rejection Reason**: Sobre-ingeniería para el MVP. La máquina de estados se diseña para admitirlo después sin cambiar el contrato de `era_loaded` — migración local cuando (si) haga falta. Registrado como evolución en Consequences → Risks.

## Consequences

### Positive
- Cierra el segundo gap Foundation del review: el ciclo de vida de era tiene un dueño, un mecanismo de carga, un contrato de señal, una regla de init-ordering y un gate de validación único.
- La regla de init-ordering elimina una clase entera de bugs de arranque (leer era en `_ready()` → `null`) para *todos* los consumidores, no solo Permadeath.
- El gate centralizado da atomicidad "era válida o ninguna": una config cross-resource rota (autoría) falla en un punto, nunca activa a medias.
- `EraDefinition` sigue siendo un Resource puro (Datos de Era R1/R3 intactos); la lógica vive en `EraManager`, no en el dato.
- Testeable en aislamiento: la máquina de estados y el gate se prueban inyectando un `EraDefinition` de test y un cargador falso, sin disco ni Autoload por nombre.
- Da a Transición de Era (#15) una máquina de estados y un dueño ya definidos sobre los que construir `ACTIVE→ARCHIVED→siguiente`.

### Negative
- Sistema Core nuevo (`EraManager`) que no estaba numerado en el systems-index — añadir como servicio Core de soporte (igual que `TimeControl` y `SaveService`).
- Disciplina requerida: cada consumidor debe conectarse a `era_loaded` y **no** leer en `_ready()` — enforced por revisión/CI, no por el compilador.
- `EraManager` centraliza la *ejecución* de validaciones cuya *especificación* vive en 4-5 GDDs distintos; hay que mantener el gate sincronizado si un GDD dueño cambia su invariante (mitigado: el gate invoca a cada validador, no reimplementa la lógica).

### Risks
- **Deriva entre el gate y las specs de los GDDs**: si Kaiju/Permadeath/Tropas cambian un invariante y el gate no se actualiza, una era rota podría pasar. *Mitigación*: el gate llama a un validador por dominio (idealmente un método del propio Resource/sistema dueño), no copia la fórmula; test de CI que cruza los invariantes documentados con los checks del gate.
- **Evolución a carga threaded**: si aparecen hitches de carga o se quiere pantalla de carga entre eras. *Mitigación*: la máquina de estados ya contempla `LOADING` como estado nombrado; el cambio es local a `load_era` y no toca `era_loaded` ni a los consumidores.
- **Orden de Autoloads mal configurado**: si `EraManager`/`SaveService`/`TimeControl` se listan en un orden que rompa el boot. *Mitigación*: ninguno lee era en `_ready()` (solo se cablean), así que el orden de _init_ de Autoloads no importa para corrección; la secuencia real la conduce el composition root explícitamente, no el orden de la lista. Documentar en el control-manifest.
- **`CACHE_MODE_REUSE` y mutación accidental**: como el `.tres` se comparte por `CACHE_MODE_REUSE`, una mutación accidental afectaría a todas las referencias. *Mitigación*: `EraDefinition` es read-only por contrato (Datos de Era R3/AC-3); assert/`push_error` en debug ante escritura, documentado en control-manifest (mismo patrón que `CombatProfile` en ADR-0001). **Nota (godot-specialist):** un ciclo "fresco" `ARCHIVED→LOADING→LOADED` (AC-11/12) re-corre el gate de validación contra la **misma instancia en memoria** cacheada, **no** re-lee bytes del disco — "fresco" significa "re-entra al ciclo de estados y re-valida", no "re-cargado desde disco". Es el comportamiento deseado dado que `EraDefinition` es inmutable; la re-validación es barata y no puede divergir del disco porque nada mutó la instancia.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `datos-de-era-civilizacion.md` | Máquina de estados `UNLOADED→LOADING→LOADED→ACTIVE→ARCHIVED` (AC-7..12); "una `ACTIVE`" (AC-9); `ARCHIVED→ACTIVE` prohibido sin recarga (AC-11/12); encolar durante `LOADING` (AC-15); loud-fail de refs rotas (AC-16) | `EraManager` conduce la máquina de estados con esos invariantes; carga síncrona hace la ventana `LOADING` una llamada (AC-15 trivial); refs rotas → `FAILED` (AC-16) |
| `datos-de-era-civilizacion.md` | `max_band_size ≥ Σ starting_count_[tipo]` loud-fail al cargar (R1, 2026-08-21) | Parte del gate de validación centralizado, antes de `era_loaded` |
| `permadeath.md` | Lee `get_hero_roster_count()` sobre era-`LOADED`, **no** en `_ready()`; feasibilidad del cap Regla 8 | La regla de init-ordering generaliza este contrato; la feasibilidad del cap es un check del gate (`TR-permadeath-017`) |
| `encuentro-con-kaiju.md` | Garantía ≥30s loud-fail al cargar `EraDefinition` (F2/AC-K74) + cross-resource AC-K85 | Checks del gate centralizado, ejecutados por `EraManager`, spec retenida por Kaiju |
| `sistema-de-tropas.md` | `max_band_size` enforcement (Fórmula E); validación AC-34 | Check del gate; `unit_roster`/`max_band_size` leídos por Tropas en `era_loaded`, no en `_ready()` |
| `temporizador-de-preparacion-ritual.md` | `approach_duration_s > 0`, `0 < imminent_window_s < approach_duration_s` (AC-T17/T18) | Checks del gate centralizado |
| `reliquias-bendiciones.md` / `forja-de-legado.md` | Reliquias lee `invocation_charges` por era (AC-RB17); Forja etiqueta `origin_era_id` de la era `ACTIVE` (AC-FL01/FL26) | Ambos leen en `era_loaded`/consultan `get_active_era()`; `origin_era_id` = `era_id` de la era `ACTIVE` |

## Performance Implications
- **CPU**: `ResourceLoader.load` síncrono de un `.tres` pequeño + una pasada de validación O(nº checks) por carga de era — sub-milisegundo a unos ms, una vez por transición de era (raro). Despreciable.
- **Memory**: Un `EraDefinition` compartido en memoria por era `LOADED`/`ACTIVE` (`CACHE_MODE_REUSE`), más el servicio. Trivial.
- **Load Time**: La carga síncrona bloquea un frame en la transición de era; aceptable para el MVP (una era). Si crece, migrar a threaded (ver Risks).
- **Network**: N/A.

## Migration Plan
No hay código aún. En implementación: (1) crear `EraManager` (Core Autoload + interfaz inyectable + cargador falso de test). (2) Definir la secuencia de boot en el composition root: `SaveService.request_load()` → `EraManager.load_era(era_id)` → `era_loaded` → consumidores → `activate_era()`. (3) Cada consumidor (Tropas, Héroes, Kaiju, Temporizador, Permadeath, Reliquias, Forja) conecta a `era_loaded` y **mueve toda lectura de datos de era fuera de `_ready()`**. (4) Consolidar las validaciones cross-resource dispersas en `_validate()`, invocando el validador de cada dominio. **Ediciones cross-GDD a aplicar al aceptar**: `datos-de-era-civilizacion.md` (nombrar a `EraManager` como conductor del ciclo de vida y dueño del gate; añadir el estado `FAILED` a la tabla de States; nota de init-ordering), nota en `permadeath.md`/`sistema-de-tropas.md`/`encuentro-con-kaiju.md`/`temporizador-de-preparacion-ritual.md` (leen en `era_loaded`, validación ejecutada por el gate). Añadir `EraManager` al systems-index como servicio Core de soporte.

## Validation Criteria
- Test unitario: `load_era` con un `EraDefinition` de test válido → `UNLOADED→LOADING→LOADED`, emite `era_loaded` exactamente una vez.
- Test unitario: `load_era` con un `era_id` inexistente (el cargador falso devuelve `null`) → `FAILED` con razón `"era_resource_not_found"`, `era_loaded` **no** se emite, **sin** crash null-ref (no se invoca el gate).
- Test unitario: `load_era` con `max_band_size < Σ starting_count` → `FAILED`, `era_loaded` **no** se emite, `era_load_failed` sí, con la razón correcta.
- Test unitario: nodo instanciado post-boot (tras `era_activated`) que llama `get_active_era()` en su `_ready()` → obtiene la era `ACTIVE`; no depende de `era_loaded` (ya emitida).
- Test unitario: gate atrapa cada violación (Kaiju ≥30s, cap de Permadeath, rangos del Temporizador, ref rota) — un caso por check.
- Test unitario: `activate_era()` desde `LOADED` → `ACTIVE`, exactamente una `ACTIVE`; desde un estado ≠ `LOADED` → error.
- Test unitario: `ARCHIVED→ACTIVE` directo → rechazado; requiere `LOADING→LOADED` primero (AC-11/12).
- Test de integración: un consumidor que lee `unit_roster` en `era_loaded` obtiene el roster completo; el mismo consumidor no lee nada en `_ready()` (grep CI).
- CI: grep de lecturas de campos de `EraDefinition` en `_ready()` / init de Autoload → cero.
- Loud-fail: era con config cross-resource inválida nunca alcanza `ACTIVE`.

## Related Decisions
- ADR-0002 (`TimeControl`) — Autoload Core hermano; independiente de la era pero comparte el orden de Autoloads y el patrón inyectado-por-referencia.
- ADR-0003 (`SaveService`) — determina qué `era_id` cargar; la secuencia de boot los ata (SaveService → EraManager → era_loaded → aplicar estado persistido por-era).
- Futuro ADR: Transición de Era (#15) hereda esta máquina de estados para `ACTIVE→ARCHIVED→siguiente`.
- Futuro ADR: Cámara/Control — puede reubicar `world_unit_scale`/`camera_pan_speed`/`zoom_*` (hoy en Datos de Era por necesidad) sin tocar este contrato.
- `docs/architecture/architecture-review-2026-08-21.md` — gap Foundation Era lifecycle (`TR-era-011`, `TR-permadeath-017`).
- GDDs a reconciliar al aceptar: `datos-de-era-civilizacion.md`, `permadeath.md`, `sistema-de-tropas.md`, `encuentro-con-kaiju.md`, `temporizador-de-preparacion-ritual.md`.
