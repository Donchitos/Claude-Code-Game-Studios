# ADR-0002: Regímenes de tiempo de juego — servicio `TimeControl` (pausa, cámara lenta, game-tick)

## Status
Accepted (2026-08-21)

## Date
2026-08-18

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting (bucle de juego, orquestación de tiempo) |
| **Knowledge Risk** | LOW-MEDIUM |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/breaking-changes.md` (L38 — rearquitectura de interpolación de física **3D** en 4.5, movida de RenderingServer a SceneTree); `docs/engine-reference/godot/current-best-practices.md` (L35 — física **2D sin cambios** en 4.6) |
| **Post-Cutoff APIs Used** | Ninguna. La decisión **evita deliberadamente** `Engine.time_scale` y `SceneTree.paused` como mecanismo; usa un flag/escala cooperativos leídos por polling (patrón ya elegido por Permadeath Regla 4). `_physics_process` de paso fijo y contadores propios son estables desde 4.0. |
| **Verification Required** | (1) Confirmar en 4.6 que escalar el avance de lógica por `time_scale` (unidades avanzan `scale × delta_fijo` por frame de física, con física a 60 tps constante) produce movimiento suave bajo interpolación de física 2D — no cambiamos `physics_ticks_per_second`, así que la interpolación sigue teniendo un tick real por frame. *La rearquitectura L38 es solo de física **3D**; la 2D del MVP no se ve afectada (current-best-practices L35), así que esto es una verificación de suavidad, no un riesgo de la migración.* (2) Confirmar que ningún sistema de tiempo de juego lee `_process(delta)`/wall-clock en vez de `TimeControl` (grep de CI). (3) Assert al arranque `Engine.physics_ticks_per_second == 60` (compartido con ADR-0001). |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (capa de modificadores de stat por instancia) — este ADR fija la fuente de tick pause-aware que ADR-0001 dejó abierta; ADR-0001 debe estar Accepted antes de que la implementación de expiración se ancle a `TimeControl.game_tick` |
| **Enables** | ADR futuro de persistencia de Guardado (F2-B7/S4) — el rebasing de `expiry_tick` en recarga se define contra `TimeControl.game_tick`, no contra un contador de motor |
| **Blocks** | Epics de Permadeath, Reliquias/Bendiciones, Temporizador de Preparación/Ritual, Combate/Daño y Encuentro con Kaiju no pueden empezar implementación de su lógica dependiente-de-tiempo hasta que este ADR sea Accepted (todos consumen `TimeControl`) |
| **Ordering Note** | Segundo ADR. Junto con ADR-0001 son los dos gates de arquitectura del review cross-GDD 2026-08-18 (F2-B1, F2-B4/S2). Resuelve además OQ-P4/F2-W4, OQ-RB9/S6 y la semántica pause-aware que ADR-0001 difirió. |

## Context

### Problem Statement
Tres regímenes de tiempo de juego conviven en el MVP y hoy **nadie los posee**:
- **Pausa total** — Permadeath Regla 4 expone `game_time_paused=true` durante el beat `DEATH_HOLD` (mecanismo **cooperativo**: un flag booleano sondeado por consumidores, **nunca** `SceneTree.paused`, para que el reloj propio del beat y la UI sigan corriendo). Consumidores confirmados: Combate (cooldowns, AC-C52), Kaiju (congela su ciclo de intención, Regla 11/AC-K89), Input (suprime entrada).
- **Cámara lenta de la oferta** — Reliquias Regla 7b/`offering_time_scale`=0.2 quiere ralentizar **uniformemente** la simulación completa (kaiju, telegrafío, unidades) mientras una invocación está abierta. Reliquias declara explícitamente (OQ-RB9) que **no posee** el reloj de simulación y que el mecanismo es "de nivel motor/loop principal".
- **Tiempo normal** — todo lo demás.

De aquí salen cuatro bloqueantes/huecos del review cross-GDD 2026-08-18:
- **F2-B4 / S2**: nadie aplica `offering_time_scale`; Combate no lo lista como autoridad de tiempo (solo `game_time_paused`); dos lecturas divergentes (global vs por-sistema) sin adjudicar; y un loop de stalling de la oferta puede estancar el temporizador anti-turtle de Furia.
- **OQ-RB9 / S6**: la precedencia pausa>cámara-lenta está escrita solo en un Open Question de Reliquias, no ratificada; Permadeath no lista a Reliquias como consumidor de `game_time_paused`; no hay mecanismo de máquina de estados que "preserve" la oferta durante la pausa.
- **OQ-P4 / F2-W4**: el Temporizador (Approved) **nunca** lee `game_time_paused` — su reloj de era no está garantizado que se congele durante un beat.
- **Hand-off de ADR-0001**: `Engine.get_physics_frames()` no es pause-aware; la semántica pause-aware de `expiry_tick` se difirió explícitamente a este ADR.

El patrón cooperativo (flag + polling, no `SceneTree.paused`/`Engine.time_scale`) ya fue elegido conscientemente por los GDDs para poder **eximir** sistemas selectivamente (el reloj del beat, la UI). La rearquitectura de interpolación de física 3D de 4.5 (breaking-changes L38) es una razón más para no escalar la física globalmente vía `Engine.time_scale`.

### Constraints
- **Mecanismo cooperativo, no engine-native** — no usar `SceneTree.paused` (detiene TODOS los callbacks de proceso, imposibilita eximir el reloj del beat/UI sin gimnasia de `process_mode`) ni `Engine.time_scale` (escala la física global, incluidos sistemas que deben correr en tiempo real).
- **Permadeath Regla 4** — la pausa es una regla dura, un stop total; el reloj propio del beat corre en tiempo real (unscaled) para no deadlockear.
- **Determinismo por tick de física** — F-RB4 (Reliquias) cuenta expiración en ticks enteros; la física corre a 60 tps fijos.
- **DI sobre singletons** (coding-standards) — testeable en aislamiento; nada de acoplamiento a Autoloads por nombre para estado ajeno.
- **Precedencia ya pre-decidida por diseño** (OQ-RB9) — pausa > cámara lenta; la muerte es el beat emocional mayor (Pilar 1) y ya posee un stop total.
- **No romper contratos Approved** — Combate AC-C52, Kaiju Regla 11/AC-K89 ya leen `game_time_paused`; el nuevo dueño debe seguir exponiendo ese flag con la misma semántica.

### Requirements
- Un único dueño del régimen de tiempo de juego (normal / cámara lenta / pausa) con precedencia definida.
- Exponer `game_time_paused` (== pausa) con semántica idéntica a la actual, para los consumidores ya Approved.
- Aplicar `offering_time_scale` uniformemente a los sistemas de tiempo de juego, con exenciones explícitas (reloj del beat, UI).
- Un contador `game_tick` **pause-aware y scale-aware** que la expiración de bendiciones (ADR-0001/F-RB4) lea, en vez de `Engine.get_physics_frames()`.
- El Temporizador consume este reloj compartido (cierra OQ-P4).
- Testeable: inyectable, sin RNG ni I/O en la lógica de régimen.

## Decision

**Se introduce un servicio Core `TimeControl` que posee el régimen canónico de tiempo de juego.** Es la única autoridad sobre "qué hora es en el juego" y sobre si el tiempo de juego está pausado o ralentizado.

**Superficie:**
- `time_scale: float` — 1.0 normal, `offering_time_scale` (0.2) en cámara lenta, 0.0-efectivo en pausa.
- `game_time_paused: bool` (alias `is_paused`) — mismo flag y misma semántica que hoy expone Permadeath; los consumidores Approved (Combate AC-C52, Kaiju Regla 11, Input) ahora lo leen de `TimeControl`, no de Permadeath.
- `game_tick: int` — contador entero monótono de **tiempo de juego**: avanza a ritmo escalado y **se congela en pausa** (ver representación abajo). Es el reloj que la expiración de F-RB4/ADR-0001 lee.

**Régimen por pila de precedencia (request/release).** Las fuentes **solicitan** un régimen; el efectivo es el de mayor precedencia activo: `PAUSED > SLOWED > NORMAL`.
- Permadeath solicita `PAUSED` al entrar un beat a `HOLDING`, lo libera al resolverse (única fuente de pausa en el MVP).
- Reliquias solicita `SLOWED` al abrir un `OFFERING`, lo libera al cerrar/cancelar (única fuente de cámara lenta en el MVP).
- Si una muerte ocurre durante un `OFFERING`: la solicitud `SLOWED` de la oferta **permanece registrada** pero queda **superada** por `PAUSED`; la oferta se preserva (su `offering_soft_timeout_s` lee `game_time`, que está congelado, así que no corre); al liberarse `PAUSED`, `SLOWED` vuelve a tomar efecto. Esto ratifica la precedencia de OQ-RB9 como contrato (cierra S6).

**Consumo cooperativo (no engine-native).** Los sistemas de tiempo de juego avanzan su lógica leyendo `TimeControl` por polling: multiplican su delta por `time_scale` y/o comparan contra `game_tick`, y chequean `game_time_paused`. `TimeControl` **nunca** setea `SceneTree.paused` ni `Engine.time_scale`. Esto preserva el mecanismo cooperativo existente y permite eximir sistemas selectivamente.

**Exenciones (corren en tiempo real, unscaled — NO leen `game_time`):** el reloj del beat `DEATH_HOLD` de Permadeath (`elapsed_s`, debe correr durante la pausa o deadlockea), la UI de la oferta y el HUD general. **El mecanismo de exención es simplemente que estos sistemas nunca sondean `TimeControl` — leen `_process(delta)`/tiempo real directamente.** (Nota: como esta decisión **nunca** setea `SceneTree.paused`, `PROCESS_MODE_ALWAYS` NO es lo que hace funcionar la exención; se deja como defensa documentada por si otro sistema introdujera `SceneTree.paused` en el futuro, no como el mecanismo.)

**`game_tick` — entero vía acumulador escalado (preserva F-RB4).** La física corre a 60 tps fijos. Cada frame de física, `TimeControl` acumula `time_scale`; cuando el acumulador `≥ 1.0`, incrementa `game_tick` en 1 y resta 1.0. En pausa, `time_scale=0` no aporta al acumulador → `game_tick` se congela. Así `duration_ticks = ceil(duration_s × 60)` y `expiry_tick = applied_tick + duration_ticks` (F-RB4/ADR-0001) siguen siendo **enteros y deterministas**, pero medidos en tiempo de juego (se congelan en pausa, se ralentizan en la oferta) en vez de wall-clock. **Esto supersede el uso provisional de `Engine.get_physics_frames()` de ADR-0001.**

**Alcance de la ralentización (decisión de diseño ratificada aquí):** la cámara lenta es uniforme sobre el tiempo de juego, así que una bendición de 20 s aplicada antes/durante una oferta dura 20 s de **tiempo de juego** (se ralentiza junto con todo lo demás), no 20 s de wall-clock. Coherente con "todo se ralentiza uniformemente" (Regla 7b) y con que `game_tick` es la base de la expiración.

### Architecture Diagram

```
   Fuentes de régimen (solicitan)                TimeControl (Core, dueño del régimen)
   ┌───────────────────────┐                     ┌────────────────────────────────────┐
   │ Permadeath  ──request_regime(PAUSED)──────► │  pila de precedencia:              │
   │ (beat HOLDING)         │                     │    PAUSED > SLOWED > NORMAL         │
   │ Reliquias   ──request_regime(SLOWED)──────► │  effective = max(activos)          │
   │ (OFFERING abierto)     │                     │                                    │
   └───────────────────────┘                     │  expone:                           │
                                                  │   time_scale: float                │
   Consumidores (leen por polling)               │   game_time_paused: bool           │
   ┌───────────────────────────────────────────┐ │   game_tick: int (acumulador       │
   │ Combate/Daño  ── game_time_paused (AC-C52) │ │      escalado, congela en pausa)   │
   │ Encuentro Kaiju ─ game_time_paused (R.11)  │◄┤                                    │
   │ Input ─────────── game_time_paused         │ │  request_regime(src, regime)       │
   │ Temporizador ──── game_tick / time_scale   │ │  release_regime(src)               │
   │   (cierra OQ-P4)                            │ └────────────────────────────────────┘
   │ Combate/CombatState.sweep_expired(game_tick)│
   │   (expiración de bendiciones, ADR-0001)     │   EXENTOS (tiempo real, no leen game_time):
   └───────────────────────────────────────────┘     - reloj del beat DEATH_HOLD (Permadeath elapsed_s)
                                                      - UI de la oferta + HUD general
```

### Key Interfaces

```gdscript
# TimeControl — servicio Core. Autoload que sostiene el reloj canónico, PERO inyectado
# por referencia (no llamado como TimeControl.* por nombre) para que los tests pinchen un
# reloj falso. Un reloj de juego canónico es un concern transversal legítimo; la inyección
# preserva la testabilidad que la regla DI-sobre-singletons del proyecto exige.
# INYECCIÓN: los consumidores reciben la referencia en UNA pasada de wiring (composition
# root) — p. ej. un setter desde el padre o un `NodePath` exportado. Prohibido `get_node(
# "/root/TimeControl")` disperso por el código de consumidor: eso reintroduce el acoplamiento
# global-por-nombre bajo apariencia de DI (grep de CI sobre esa ruta).
class_name TimeControl extends Node

enum Regime { NORMAL = 0, SLOWED = 1, PAUSED = 2 }   # valor entero = precedencia

var time_scale: float          # 1.0 / offering_time_scale / 0.0-en-pausa  (read-only para consumidores)
var game_time_paused: bool     # == régimen efectivo PAUSED; semántica idéntica a Permadeath R4 hoy
var game_tick: int             # tiempo de juego entero; avanza escalado, congela en pausa

func request_regime(source_id: StringName, regime: Regime) -> void   # fuente pide un régimen
func release_regime(source_id: StringName) -> void                   # fuente lo suelta
# effective_regime = máx precedencia entre solicitudes activas; time_scale/paused derivan de él.
# offering_time_scale (0.2) es el time_scale del régimen SLOWED (parámetro, no hardcode).

# Avance del reloj (interno, en _physics_process con paso fijo):
#   _accum += time_scale                      # time_scale=0 en pausa → no avanza
#   while _accum >= 1.0: game_tick += 1; _accum -= 1.0
```

**Contrato de invariantes (loud-fail):**
- `0.0 < offering_time_scale < 1.0` (ya en Reliquias §Tuning Knobs; `TimeControl` lo valida al recibirlo).
- `game_tick` monótono no-decreciente; nunca retrocede.
- En pausa, `game_tick` no avanza y `time_scale == 0.0`.
- **El `_physics_process` de `TimeControl` corre incondicionalmente cada frame de física** (esta decisión nunca toca `SceneTree.paused`); el acumulador se congela en pausa **porque suma `time_scale == 0.0`**, no porque el nodo deje de procesar. (Sin esto, el reloj no podría "descongelarse" al liberar la pausa.) Como defensa (godot-specialist, revisión 2026-08-21) `TimeControl.process_mode = PROCESS_MODE_ALWAYS`, por si otro sistema introdujera `SceneTree.paused` en el futuro (no es el mecanismo, es cinturón-y-tirantes).
- **`TimeControl` debe avanzar `game_tick` ANTES de que cualquier consumidor lo lea en el mismo frame de física.** El orden de `_physics_process` entre nodos no está garantizado por Godot salvo por posición de árbol / `process_physics_priority`; hoy funciona solo por el artefacto de registro de Autoloads. Se fija explícitamente **`TimeControl.process_physics_priority = -1000`** para garantizar que corra primero sin importar el orden de árbol o de lista de Autoloads, más un test/assert de CI de que `game_tick` ya avanzó cuando un consumidor observa un frame dado (godot-specialist MEDIUM, revisión 2026-08-21). Una lectura de `game_tick` con 1 tick de retraso produce una expiración off-by-one silenciosa — inaceptable bajo la política loud-fail del proyecto.
- Una `source_id` no puede tener dos solicitudes activas simultáneas (re-request reemplaza).
- Consumidores de tiempo de juego **nunca** leen wall-clock/`_process(delta)` para lógica de simulación (grep CI).

## Alternatives Considered

### Alternative 1: Engine-native (`Engine.time_scale` + `SceneTree.paused`)
- **Description**: Cámara lenta vía `Engine.time_scale=0.2`; pausa vía `SceneTree.paused=true`.
- **Pros**: Cero código de reloj propio; el motor hace el trabajo.
- **Cons**: `SceneTree.paused` detiene **todos** los callbacks de proceso — el reloj del beat y la UI necesitarían `PROCESS_MODE_ALWAYS` por nodo, exactamente la gimnasia que los GDDs evitaron al elegir el flag cooperativo; `Engine.time_scale` escala la física global (incluida la parte que debe correr en tiempo real) e interactúa con la interpolación de física 3D rearquitecturada en 4.5; `Engine.get_physics_frames()` no es pause-aware (hueco heredado de ADR-0001). No soporta exención selectiva limpia.
- **Rejection Reason**: Contradice el mecanismo cooperativo ya elegido y la exención selectiva; reintroduce el hueco pause-aware.

### Alternative 2: Sin dueño central — cada sistema se auto-coordina
- **Description**: Permadeath sigue dueño del flag de pausa, Reliquias dueño de la escala; cada sistema dependiente lee ambos directamente.
- **Pros**: Sin sistema nuevo.
- **Cons**: Es el estado roto actual — wiring N×M (cada sistema de tiempo debe conocer a Permadeath **y** a Reliquias), las filas de dependencia faltantes (F2-B3/A2), sin autoridad única de precedencia, y el Temporizador (OQ-P4) queda fuera. La "preservación de la oferta durante la pausa" habría que reimplementarla ad hoc.
- **Rejection Reason**: Exactamente lo que el review marcó como bloqueante; no escala a una tercera fuente de tiempo.

### Alternative 3: El Temporizador de Preparación/Ritual lo posee
- **Description**: OQ-RB9 sugiere que el Temporizador "ya posee el tiempo de fase"; extenderlo para poseer pausa + cámara lenta globales.
- **Pros**: Reutiliza un dueño de tiempo existente.
- **Cons**: El Temporizador posee el **reloj de acercamiento de la era** (un concepto de dominio Gameplay), no el régimen global de tiempo. Sobrecargarlo haría que Permadeath (Legado) y Reliquias (Legado) dependieran de un sistema Gameplay-Feature para pausar/ralentizar — inversión de capas. Además el reloj de acercamiento se detiene en `CLIMAX`, justo donde vive la cámara lenta de la oferta.
- **Rejection Reason**: Inversión de capas y solapamiento de responsabilidades; el régimen global es Core, no Gameplay.

## Consequences

### Positive
- Un único dueño y una única precedencia para el tiempo de juego; F2-B4/S2 cerrado.
- `game_time_paused` sobrevive con semántica idéntica — Combate/Kaiju/Input no cambian su contrato, solo la fuente de lectura (Permadeath → TimeControl). El wiring huérfano Permadeath↔Reliquias se resuelve haciéndolos ambos clientes del hub.
- OQ-P4/F2-W4 cerrado: el Temporizador consume el reloj compartido y se congela/ralentiza gratis.
- OQ-RB9/S6 ratificado como contrato: pausa > cámara lenta, oferta preservada.
- La expiración de bendiciones (ADR-0001/F-RB4) queda pause-aware y scale-aware sin lógica cross-sistema; cierra el hand-off que ADR-0001 dejó abierto.
- Extensible: una tercera fuente de tiempo futura (p. ej. bullet-time de otra mecánica) solo solicita un régimen en la pila.

### Negative
- Sistema Core nuevo que **no** estaba en el systems-index (cambio de alcance de infraestructura — añadir como sistema/servicio de soporte).
- Todo sistema de tiempo de juego gana una dependencia a `TimeControl` (aunque reemplaza dependencias directas a Permadeath/Reliquias, así que a menudo es neutro o más limpio).
- Disciplina requerida: cualquier lógica de simulación que use `_process(delta)` wall-clock es un bug; hay que enforcalo por revisión/CI.

### Risks
- **Autoload vs DI**: `TimeControl` como Autoload roza la regla "DI sobre singletons". *Mitigación*: sostener el reloj en el Autoload pero **inyectar la referencia** (no `TimeControl.` por nombre); los tests pinchan un `FakeClock` con el mismo interfaz. Registrar la excepción explícita (concern transversal legítimo, como un bus de eventos) en el control-manifest.
- **Sistema que olvida leer `time_scale`/`game_time_paused`** y corre en wall-clock → se desincroniza de la pausa/cámara lenta. *Mitigación*: grep de CI sobre `_process(delta)` en scripts de simulación; checklist en el control-manifest de qué sistemas son de tiempo de juego vs exentos.
- **Suavidad visual bajo cámara lenta**: escalar el avance de lógica sin tocar `physics_ticks_per_second` mantiene un tick real por frame; conviene verificar suavidad visual bajo cámara lenta (Verification Required 1). La rearquitectura de interpolación de la breaking-changes L38 es **solo de física 3D**; la 2D del MVP no cambia en 4.6 (current-best-practices L35), así que no hay riesgo de migración aquí — solo una verificación de feel.
- **Fuga entre régimen y expiración**: si `game_tick` avanzara fraccional o no-monótono, la expiración se rompe. *Mitigación*: acumulador entero con invariante de monotonía loud-fail.
- **Semántica de duración en cámara lenta**: se decide que las bendiciones duran tiempo de **juego** (se ralentizan). Si playtest mostrara que se siente mal (un buff que "dura demasiado" en wall-clock durante una oferta), es un cambio de política acotado a cómo `game_tick` alimenta la expiración — no un rediseño. *Registrado para validación en vertical slice.*

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `permadeath.md` | Regla 4 `game_time_paused` cooperativo (no `SceneTree.paused`); reloj del beat corre unscaled; OQ-P4 (¿la pausa alcanza al Temporizador?) | Permadeath solicita `PAUSED`; `TimeControl` expone `game_time_paused` con semántica idéntica; el reloj del beat queda exento (tiempo real); el Temporizador ahora lee el reloj compartido → OQ-P4 cerrado |
| `reliquias-bendiciones.md` | Regla 7b `offering_time_scale` uniforme; OQ-RB9 (dueño del reloj + precedencia pausa>cámara-lenta + preservar la oferta) | Reliquias solicita `SLOWED` con `offering_time_scale`; `TimeControl` lo aplica uniformemente; precedencia `PAUSED>SLOWED` ratificada; la oferta se preserva porque su soft-timeout lee `game_time` congelado |
| `reliquias-bendiciones.md` / ADR-0001 | F-RB4 expiración por tick determinista, pause-aware | `game_tick` entero, scale-aware y pause-aware; `sweep_expired(game_tick)` de ADR-0001 lo lee; supersede `Engine.get_physics_frames()` |
| `temporizador-de-preparacion-ritual.md` | El reloj de acercamiento/fase debe congelarse en un beat de muerte y ralentizarse en una oferta (hoy solo conoce el menú de pausa global, AC-T22) | El Temporizador consume `TimeControl.game_tick`/`time_scale` en vez de su wall-clock; F2-W4 cerrado (edición cross-GDD a aplicar al aceptar) |
| `combate-dano.md` / `encuentro-con-kaiju.md` | Combate AC-C52 y Kaiju Regla 11/AC-K89 leen `game_time_paused` | Siguen leyendo el mismo flag, ahora desde `TimeControl` (fuente de lectura cambia, semántica no) |

## Performance Implications
- **CPU**: `TimeControl` hace O(1) por frame de física (acumulador + resolución de precedencia sobre un puñado de solicitudes). Los consumidores hacen una lectura de flag/escala. Despreciable.
- **Memory**: Un servicio + una pila de solicitudes pequeña. Trivial.
- **Load Time**: Nulo.
- **Network**: N/A (sin multijugador en el MVP).

## Migration Plan
No hay código aún. En implementación: (1) crear `TimeControl` (Autoload + interfaz inyectable + `FakeClock` de test). (2) Permadeath deja de exponer `game_time_paused` como dueño y pasa a **solicitar** `PAUSED`; su reloj de beat se marca exento. (3) Reliquias solicita `SLOWED`. (4) Combate/Kaiju/Input cambian su lectura de `game_time_paused` de Permadeath a `TimeControl` (semántica idéntica — cambio mecánico). (5) Temporizador consume `game_tick`/`time_scale`. (6) La expiración de ADR-0001 se ancla a `TimeControl.game_tick`. **Ediciones cross-GDD a aplicar al aceptar**: `permadeath.md` (OQ-P4 cerrado, fuente de `game_time_paused` movida a TimeControl), `reliquias-bendiciones.md` (OQ-RB9 cerrado, dueño del reloj = TimeControl), `temporizador-de-preparacion-ritual.md` (consume el reloj compartido), nota en `combate-dano.md`/`encuentro-con-kaiju.md` (fuente de lectura). Añadir `TimeControl` al systems-index como servicio Core de soporte.

## Validation Criteria
- Test unitario: sin solicitudes → régimen NORMAL, `time_scale==1.0`, `game_tick` avanza 1/tick de física.
- Test unitario: `request_regime(reliquias, SLOWED)` → `time_scale==0.2`, `game_tick` avanza ~1 cada 5 ticks de física.
- Test unitario: `request_regime(permadeath, PAUSED)` con SLOWED activo → efectivo PAUSED, `game_time_paused==true`, `game_tick` congelado; al `release_regime(permadeath)` → vuelve a SLOWED (oferta preservada).
- Test unitario: `game_tick` monótono no-decreciente en toda transición de régimen.
- Test de integración: una bendición de 20 s aplicada, luego una oferta abierta 5 s (wall-clock) → la expiración se corre en tiempo de juego (dura 20 s de juego, no 20 s de wall-clock).
- Test de integración: muerte durante una oferta → la oferta no cancela ni corre su soft-timeout durante el beat; reanuda cámara lenta al terminar (cierra S6).
- CI: grep de `_process(delta)` en scripts de simulación de tiempo de juego → cero (deben usar `TimeControl`).
- Loud-fail: `offering_time_scale ∉ (0,1)`, `game_tick` no-monótono → error ruidoso.

## Related Decisions
- ADR-0001 (capa de modificadores de stat por instancia) — este ADR fija la fuente de tick pause-aware que ADR-0001 difirió; `sweep_expired`/`expiry_tick` se anclan a `TimeControl.game_tick`.
- **ADR-0003** (persistencia de Guardado — `docs/architecture/adr-0003-save-persistence-serialization.md`, Proposed): el rebasing de `expiry_tick` en recarga se define contra `TimeControl.game_tick` — se persiste `remaining_ticks` (relativo) y se rebasa al cargar (fresh `game_tick=0` + `remaining_ticks`). Prohíbe persistir `game_tick`/`expiry_tick` absolutos (forbidden pattern `persisting_absolute_game_tick`). Cierra el hand-off de persistencia (F2-B7/S4).
- `design/gdd/gdd-cross-review-2026-08-18.md` — F2-B4/S2 (origen), OQ-P4/F2-W4, OQ-RB9/S6.
- GDDs a reconciliar al aceptar: `permadeath.md`, `reliquias-bendiciones.md`, `temporizador-de-preparacion-ritual.md`, `combate-dano.md`, `encuentro-con-kaiju.md`.
