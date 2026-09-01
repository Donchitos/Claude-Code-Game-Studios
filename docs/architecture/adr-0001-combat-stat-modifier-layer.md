# ADR-0001: Capa de modificadores de stat por instancia (dueño: Combate/Daño)

## Status
Accepted (2026-08-21)

## Date
2026-08-18

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting (modelo de datos de combate) |
| **Knowledge Risk** | LOW |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` (no existe módulo Core/Scripting en la referencia; el dominio no toca Physics/Rendering) |
| **Post-Cutoff APIs Used** | Ninguna. Composición por nodos, `Array[T]` tipado, `RefCounted`, y `_physics_process` de paso fijo son estables desde Godot 4.0 — no dependen de nada introducido en 4.4/4.5/4.6 |
| **Verification Required** | (1) Confirmar que el contador de tick que alimenta `expiry_tick` es **la misma fuente** en Combate y en Reliquias (F-RB4). **SUPERSEDED por ADR-0002 (Accepted 2026-08-21): la fuente es `TimeControl.game_tick` (pause-aware / scale-aware), NO `Engine.get_physics_frames()`** (que no se detiene en pausa — ver Risks). `sweep_expired(tick)` se ancla a `TimeControl.game_tick`; una divergencia de fuente rompería la expiración. (2) Confirmar en 4.6 que un `Array[StatModifier]` tipado sobre una subclase de `RefCounted` se limpia sin fugas al liberar la instancia de unidad. (3) **Assert al arranque `Engine.physics_ticks_per_second == 60`** — `F-RB4` computa `duration_ticks` sobre un supuesto fijo de 60 tps; si un project setting cambia el tps, `duration_ticks` se desincroniza de la duración en segundos sin error. (4) Verificar en inspector/`.tres` que `CombatProfile.resource_local_to_scene` sea `false` (default) — si estuviera `true`, Godot duplicaría el Resource por instancia de escena silenciosamente (rompe "compartido por tipo" sin aviso). |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR futuro de `offering_time_scale` / pausa (F2-B4/S2) puede asumir que la capa de instancia ya existe; ADR futuro de persistencia de Guardado (define cómo/si se serializan los modificadores activos — F2-B7/S4) |
| **Blocks** | Epic de Combate/Daño y epic de Reliquias/Bendiciones no pueden empezar implementación hasta que este ADR sea Accepted (definen la superficie `CombatState` + API de modificadores) |
| **Ordering Note** | Primer ADR del proyecto. Debe ser Accepted antes de `/create-epics` sobre Combate o Reliquias. La persistencia del estado efímero de invocación queda explícitamente fuera de alcance y se difiere al ADR de Guardado. |

## Context

### Problem Statement
La cadena del Pilar 2 (muerte → reliquia → bendición → poder en combate) no tiene dónde vivir en el modelo de datos actual. `reliquias-bendiciones.md` (F-RB1) requiere un **stat efectivo por instancia** — `effective_stat(u, s, t) = base_stat(u_type, s) + Σ magnitude(m)` — que Combate debe leer **en el momento de resolver un golpe**, vía un read-hook que Reliquias llama `effective_attack_damage(instancia)`. Pero `combate-dano.md` modela el `CombatProfile` estrictamente **por tipo de unidad** (Regla 2/F1); `apply_damage` lee un `attack_damage` estático y no existe ninguna capa de instancia. El símbolo `effective_attack_damage` aparece 11× en Reliquias y 0× en Combate; el registro lo marca `PROVISIONAL`. La revisión cross-GDD 2026-08-18 lo elevó a bloqueante de arquitectura (F2-B1, detectado independientemente por los dos agentes de consistencia y confirmado por el walkthrough de Fase 4). Reliquias declara además que **nunca escribe en `CombatProfile`** — necesita un canal explícito para depositar modificadores sin mutar el Resource compartido por tipo.

### Constraints
- **Combate/Daño Regla 1** — "un solo camino de daño"; todo el daño pasa por una única operación `apply_damage`. El valor efectivo debe computarse **dentro** de Combate, no en un cálculo paralelo aguas arriba.
- **Combate/Daño Regla 5** — daño plano, sin multiplicadores de tipo (única excepción nombrada hoy: la Furia del Kaiju, ×1.5). Los modificadores de bendición son **planos aditivos** (`+N` enteros), así que respetan la regla sin ampliarla.
- **`CombatProfile` es contenido por tipo** — un Resource compartido entre todas las instancias de un tipo. Nunca debe mutarse en runtime (mutarlo afectaría a todas las instancias de ese tipo y corrompería el dato-fuente).
- **DI sobre singletons** (coding-standards del proyecto) — los sistemas deben ser testeables en aislamiento; nada de acoplamiento a Autoloads por nombre.
- **Loud-fail sobre clamp silencioso** (precedente de Héroes/Combate) — config inválida falla ruidosamente al cargar.
- **Determinismo por tick de física** — F-RB4 ancla la expiración al paso fijo de física, nunca a wall-clock/`_process(delta)`.
- **Capas** — Reliquias (Legado, Feature) ya depende de Combate (Gameplay, Feature, Approved). La solución no debe invertir esa dirección ni crear un ciclo.

### Requirements
- Combate debe exponer un stat **efectivo por instancia** legible en resolución de golpe, sobre el `CombatProfile` por tipo, sin mutar el Resource.
- Reliquias debe poder **añadir/retirar** modificadores planos aditivos por instancia, por stat, con un `expiry_tick`, sin tocar `CombatProfile`.
- El modelo debe soportar los dos stats del MVP: `attack_damage` y `max_health`.
- La dedup "una instancia activa por `relic_id` por unidad, refresh-on-repick" (F-RB1) debe ser expresable.
- La expiración debe verificarse **al inicio de cada tick, antes de la fase-1 de daño de Combate** (F-RB4), sin ambigüedad de orden.
- Testeable sin escena completa; sin RNG ni I/O en el cálculo del stat efectivo.

## Decision

**Combate/Daño posee una capa de stat de combate por instancia que se apoya sobre el `CombatProfile` por tipo.** Se introduce un componente `CombatState` por instancia de unidad que contiene una referencia **solo-lectura** al `CombatProfile` compartido del tipo más una lista de modificadores activos. Combate expone:

- una **API de escritura** que las fuentes de modificadores (Reliquias en el MVP) llaman para depositar/retirar bonos planos aditivos, y
- un **read-hook** `effective_attack_damage(instance)` (y en general `effective_stat`) que Combate lee **internamente** al resolver un golpe en `apply_damage`.

Reliquias posee la **política** (qué modificador, qué magnitud, qué duración, cuándo) pero **no** la aplicación en resolución de golpe. Combate posee la **aplicación** y la **expiración**. Reliquias nunca lee ni escribe `CombatProfile`; solo llama la API de modificadores. Esto mantiene toda la matemática de daño dentro de Combate (Regla 1), mantiene los bonos planos aditivos (Regla 5, sin ampliarla), y conserva la dirección de dependencia Reliquias→Combate (sin ciclo).

**Cómputo pull + barrido de expiración en Combate.** `effective_attack_damage` suma los modificadores activos **bajo demanda** en `apply_damage` (el stack es ≤3; coste despreciable). Cada modificador lleva su `expiry_tick`; la capa de Combate trata `t ≥ expiry_tick` como inactivo y **barre** los expirados al inicio del tick, antes de la fase-1 de daño. Reliquias nunca sondea: llama `add_modifier(…, expiry_tick)` y se olvida. Esto satisface el orden de F-RB4 dentro del sistema dueño.

**`StatModifier` es un objeto de runtime liviano** (subclase de `RefCounted`), no un Resource: `{ stat, magnitude, expiry_tick, source_relic_id }`. Sin overhead de serialización a disco; `source_relic_id` habilita la dedup refresh-on-repick (F-RB1) y deja que el futuro ADR de persistencia decida por separado si/cómo se guardan los modificadores activos.

**Alcance MVP: dos stats** — `attack_damage` y `max_health` (los que nombra F-RB1). La estructura es extensible a más stats sin cambio de forma, pero este ADR solo se compromete a esos dos.

### Architecture Diagram

```
  CombatProfile (Resource, POR TIPO — contenido, inmutable en runtime)
        │  attack_damage, max_health, attack_range, aggro_range, leash_range, attack_cooldown_s
        │  (referencia solo-lectura, compartida por todas las instancias del tipo)
        ▼
  ┌───────────────────────────────────────────────┐
  │  CombatState  (POR INSTANCIA — dueño: Combate) │
  │  - base_profile: CombatProfile  (read-only)    │
  │  - _modifiers: Array[StatModifier]             │
  │                                                │
  │  + effective(stat) -> int   (pull, on-read)    │
  │  + effective_attack_damage() -> int            │
  │  + add_modifier(mod) / remove_by_source(id)    │
  │  + sweep_expired(tick)  (inicio de tick)       │
  └───────────────────────────────────────────────┘
        ▲ escribe modificadores                 ▲ lee effective_* en apply_damage
        │ (add/remove)                          │ (interno a Combate)
        │                                       │
  Reliquias/Bendiciones                     Combate/Daño (apply_damage, Regla 1)
  (política: qué/cuándo/cuánto)             (aplicación + expiración)

  Furia del Kaiju: NO pasa por esta capa. Sigue su propio camino
  apply_damage(target, amount, source) con `amount` computado por el
  controlador del Kaiju (×1.5, excepción multiplicativa nombrada, Regla 5).
```

### Key Interfaces

```gdscript
# StatModifier — objeto efímero de runtime (RefCounted), no Resource.
class_name StatModifier extends RefCounted
enum Stat { ATTACK_DAMAGE, MAX_HEALTH }   # alcance MVP: 2 stats
var stat: Stat
var magnitude: int          # bono plano aditivo, ≥1 (loud-fail si <1)
var expiry_tick: int        # tick de física de expiración; −1 = instantáneo/no-temporizado
var source_relic_id: String # dedup refresh-on-repick (F-RB1) + trazabilidad

# CombatState — componente por instancia (miembro del script de la unidad), dueño: Combate/Daño.
# RefCounted, NO Node: sweep_expired lo invoca el bucle de Combate (no es auto-conducido) y
# nada aquí usa árbol de escena / señales / _physics_process, así que no necesita ser Node.
# Se auto-libera por refcount al liberar la unidad (sin ordenar queue_free). Tradeoff aceptado:
# un RefCounted no aparece en el panel Remote Scene Tree del editor — el debug de buffs activos
# se hace vía un test/volcado dedicado, no por inspección en vivo del árbol.
class_name CombatState extends RefCounted
var base_profile: CombatProfile          # referencia solo-lectura, compartida por tipo

func effective(stat: StatModifier.Stat) -> int      # pull: base + Σ modificadores activos
func effective_attack_damage() -> int               # read-hook nombrado (grep CI)
func add_modifier(mod: StatModifier) -> void         # refresh-on-repick por source_relic_id+stat
func remove_by_source(source_relic_id: String) -> void
func sweep_expired(current_tick: int) -> void        # llamado al inicio de tick, antes de fase-1

# Dedup (F-RB1): add_modifier con un (source_relic_id, stat) ya presente NO apila —
# refresca expiry_tick de la instancia existente (la magnitud no cambia; mismo tier).
```

**Contrato de invariantes (loud-fail al añadir / al cargar):**
- `magnitude ≥ 1` para todo modificador plano.
- `stat ∈ {ATTACK_DAMAGE, MAX_HEALTH}` en el MVP.
- `expiry_tick > applied_tick` para modificadores temporizados (o `−1` para instantáneos).
- La capa **nunca** muta `base_profile` (el `CombatProfile` compartido). Un intento de escritura es un bug de programación, no un extremo válido.

## Alternatives Considered

### Alternative 1: Reliquias posee el stack; Combate lo consulta
- **Description**: Reliquias mantiene el registro de modificadores por instancia y expone una query; Combate llama a Reliquias (o a un servicio que Reliquias posee) al resolver el golpe.
- **Pros**: Reliquias tiene toda su lógica en un lugar; Combate no crece.
- **Cons**: Invierte la dirección de capas — Combate (core Approved) dependería de Reliquias (feature Legado). Crea exactamente el ciclo que `systems-index.md` afirma hoy que no existe. Rompe Combate Regla 1 (el valor efectivo se computaría fuera del único camino de daño). Deja a Combate inservible sin Reliquias presente, aunque el combate base no necesita bendiciones.
- **Rejection Reason**: Acoplamiento y dirección de dependencia inaceptables; viola Regla 1.

### Alternative 2: Servicio neutral de modificadores en capa Core (poseído por nadie)
- **Description**: Un componente genérico de modificadores de stat por instancia en una capa inferior, del que dependen tanto Combate como Reliquias.
- **Pros**: Separación más limpia; reutilizable por Furia y futuros buffs; ambos sistemas como clientes simétricos.
- **Cons**: Más abstracción de la que el MVP necesita; introduce un sistema foundational nuevo que no está en el systems-index (cambio de alcance); Combate ya se declara el dueño del camino de daño, así que "poseído por nadie" duplica autoridad que Regla 1 ya asigna.
- **Rejection Reason**: Sobre-ingeniería para el MVP. Se puede refactorizar hacia esto más tarde si Furia u otras fuentes necesitan la misma capa; hoy Reliquias es la única fuente aditiva y Combate ya es el dueño natural. (Registrado como posible evolución en Consequences → Risks.)

## Consequences

### Positive
- La cadena de daño del Pilar 2 tiene un hogar concreto; `effective_attack_damage` deja de ser un símbolo fantasma.
- Toda la matemática de daño permanece dentro de Combate (Regla 1 intacta); los modificadores planos aditivos no amplían Regla 5.
- `CombatProfile` sigue siendo contenido inmutable por tipo; el estado por instancia vive aparte.
- Testeable en aislamiento: `CombatState` es un `RefCounted` que se instancia con `.new()` sin árbol de escena, con dependencias inyectables, sin Autoload, sin RNG, sin I/O.
- La expiración vive junto a la aplicación (un solo dueño del ciclo de vida del modificador en resolución), resolviendo el orden de F-RB4 sin polling cross-sistema.
- Da forma concreta al contrato que Reliquias marca provisional (cierra OQ-RB1 en cuanto se acepte y se refleje en ambos GDDs).

### Negative
- Combate crece: gana un componente por instancia y una API de modificadores que antes no tenía.
- Cada instancia de unidad ahora carga un `CombatState` (`RefCounted` + lista). Coste de memoria pequeño pero real a escala de banda (decenas de unidades).
- Introduce un acoplamiento de escritura Reliquias→API-de-Combate que debe reflejarse en ambos GDDs (hoy Combate no lista la API; Reliquias la marca provisional).

### Risks
- **Fuente de tick divergente**: si Combate y Reliquias leen contadores de tick distintos, `expiry_tick` se desincroniza. *Mitigación*: fijar una única fuente de tick de física en implementación (Verification Required) y grep de CI sobre el símbolo.
- **Mutación accidental de `CombatProfile`**: un programador podría escribir sobre `base_profile`. *Mitigación*: `base_profile` como referencia tratada solo-lectura + assert/`push_error` en debug si se detecta mutación; documentar en el control-manifest.
- **Evolución a Furia/otros buffs**: si Furia u otros efectos futuros necesitan modificadores, la Alternative 2 (servicio neutral) puede volverse preferible. *Mitigación*: `CombatState` como componente (no Autoload) hace ese refactor local; la API de modificadores ya es agnóstica de la fuente (`source_relic_id` es solo un id de trazabilidad).
- **Persistencia**: los modificadores activos son estado efímero; guardarlos/restaurarlos (recarga a mitad de era) NO se resuelve aquí. *Mitigación*: diferido explícitamente al ADR de Guardado (S4/F2-B7); `StatModifier` lleva los campos suficientes (`source_relic_id`, `expiry_tick`) para que ese ADR decida el rebasing de tick.
- **`resource_local_to_scene` (validación godot-specialist)**: si `CombatProfile.resource_local_to_scene` estuviera `true` (por accidente en el `.tres` o en una escena que herede), Godot **duplicaría** el Resource por instancia de escena en silencio — lo opuesto a "compartido por tipo", y sin error: los cambios de balance por tipo dejarían de propagarse. *Mitigación*: mantenerlo en `false` (default) y verificarlo (ver Verification Required 4).
- **`Engine.get_physics_frames()` no es pause-aware (validación godot-specialist)**: el contador global de física sigue avanzando bajo `SceneTree.paused` (la pausa detiene `_process`/`_physics_process`, no el contador del motor). Si la intención de diseño fuera "las bendiciones no expiran mientras el juego está pausado", anclar `expiry_tick` a `Engine.get_physics_frames()` **no** da esa conducta gratis. *Mitigación*: el **ADR futuro de `game_time_paused`/`offering_time_scale` debe decidir** entre (a) aceptar que los ticks avancen en pausa, o (b) introducir un contador de tick pause-aware, **antes** de fijar la semántica de `expiry_tick`. Registrado como input directo a ese ADR (ver Related Decisions).

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `reliquias-bendiciones.md` | F-RB1 `effective_stat(u,s,t)` por instancia; read-hook `effective_attack_damage(instancia)`; "nunca escribe `CombatProfile`"; dedup refresh-on-repick por `relic_id` | Combate expone `CombatState.effective_attack_damage()` y una API `add_modifier/remove_by_source`; Reliquias solo llama esa API; dedup por `(source_relic_id, stat)` |
| `reliquias-bendiciones.md` | F-RB4 expiración por tick, chequeada antes de la fase-1 de daño; "expirar nunca mata" (clamp de `current_health`, no `apply_damage`) | `sweep_expired(tick)` al inicio de tick dentro de Combate; el clamp defensivo de `max_health`/`current_health` lo aplica el dueño del stat (Combate) sin pasar por `apply_damage` |
| `combate-dano.md` | Regla 1 (un solo camino de daño); Regla 5 (plano, sin multiplicadores); `CombatProfile` por tipo inmutable | El valor efectivo se computa dentro de `apply_damage`; modificadores planos aditivos; `CombatProfile` referenciado solo-lectura, nunca mutado |
| `encuentro-con-kaiju.md` | Furia ×1.5 como excepción multiplicativa nombrada (Regla 10) | La Furia **no** pasa por esta capa aditiva; sigue su camino `apply_damage(target, amount, source)` con `amount` del controlador del Kaiju. Registrado para cerrar la incoherencia F2-W3/W1 (Combate debe reconocer la excepción en su texto, cross-GDD aparte) |

## Performance Implications
- **CPU**: Suma de ≤3 enteros por golpe resuelto (pull on-read) + un barrido de expiración O(nº modificadores) al inicio de tick. Despreciable frente al presupuesto de combate.
- **Memory**: Un `CombatState` (`RefCounted` + `Array[StatModifier]`) por instancia de unidad — sin registro en árbol de escena. A escala de banda (decenas de unidades) es pequeño; los modificadores son ≤3 por instancia y efímeros.
- **Load Time**: Nulo — sin assets nuevos; `CombatProfile` ya se carga por tipo.
- **Network**: N/A (sin multijugador en el MVP).

## Migration Plan
No hay código aún (fase de diseño). En implementación: (1) `apply_damage` y el bucle de ataque leen `combat_state.effective_attack_damage()` en vez de `profile.attack_damage`; para unidades sin modificadores, `effective` devuelve el valor base (comportamiento idéntico al actual). (2) La forma del `CombatProfile` por tipo no cambia. (3) `combate-dano.md` gana la API de modificadores en su contrato; `reliquias-bendiciones.md` des-marca F-RB1/`effective_attack_damage` de "provisional" y cierra OQ-RB1 — edición cross-GDD a hacer al aceptar este ADR.

## Validation Criteria
- Test unitario: `effective_attack_damage()` sin modificadores == `base_profile.attack_damage`.
- Test unitario: con dos modificadores ofensivos distintos activos, devuelve `base + m1 + m2`; con el mismo `source_relic_id` re-añadido, no apila (refresca `expiry_tick`).
- Test unitario: un modificador con `expiry_tick == t` no cuenta en el golpe del tick `t` (barrido antes de fase-1).
- Test unitario: expiración de bono defensivo de `max_health` con `current_health` alto → clampa hacia abajo, nunca lleva `current_health` a ≤0 (F-RB4 "expirar nunca mata").
- Test de integración: Reliquias `add_modifier` → un golpe de Combate refleja el bono; tras `expiry_tick`, vuelve al base.
- CI: grep del símbolo `effective_attack_damage` presente en el código de Combate (contrato materializado, no fantasma).
- Loud-fail: `magnitude < 1`, `stat` fuera de dominio, o `expiry_tick ≤ applied_tick` en un temporizado → error ruidoso.

## Related Decisions
- Futuro ADR: dueño y aplicación de `offering_time_scale` × `game_time_paused` × tick de física (F2-B4/S2) — asumirá esta capa de instancia **y debe decidir la semántica pause-aware de `expiry_tick`** (`Engine.get_physics_frames()` no se detiene en pausa — ver Risks).
- **ADR-0003** (persistencia de Guardado — `docs/architecture/adr-0003-save-persistence-serialization.md`, Proposed): resuelve la persistencia del estado efímero de invocación y de los modificadores activos. Se persiste `remaining_ticks` (relativo), **NO** el `expiry_tick` absoluto, rebasado al cargar contra `TimeControl.game_tick` (F2-B7/S4). Cierra el hand-off de persistencia que este ADR difirió.
- `design/gdd/gdd-cross-review-2026-08-18.md` — F2-B1 (origen de este ADR).
- `design/gdd/combate-dano.md`, `design/gdd/reliquias-bendiciones.md` — GDDs a reconciliar al aceptar.
