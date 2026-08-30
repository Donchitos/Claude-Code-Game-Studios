# ADR-0003: Serialización y contrato de runtime de Guardado/Persistencia

## Status
Proposed

## Date
2026-08-21

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (I/O de archivos / serialización) |
| **Knowledge Risk** | MEDIUM |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/breaking-changes.md` (4.3→4.4: `FileAccess.store_*` — incl. `store_var` — pasan de `void` a devolver `bool`); `docs/engine-reference/godot/deprecated-apis.md` (sin entradas de I/O de archivos o serialización) |
| **Post-Cutoff APIs Used** | `FileAccess.store_var`/`get_var` con su valor de retorno `bool` (post-4.4) usado como señal de fallo de escritura de primera clase — mi training data pre-4.4 asumiría `void` y necesitaría un mecanismo distinto (try/reopen) para detectar el mismo fallo |
| **Verification Required** | (1) Confirmar en 4.6 que `store_var`/`store_buffer` devuelven `false` de forma fiable ante un fallo real de disco a mitad de escritura (no solo ante errores triviales de argumento). (2) Confirmar que `hash()` (Variant hash) es determinista dentro de una misma versión de motor para el mismo `Dictionary` de payload — no se requiere estabilidad *entre* versiones de motor, ver Decision/Risks. (3) `Engine.physics_ticks_per_second == 60` ya se assertea por ADR-0001/ADR-0002; este ADR no añade un nuevo assert, pero el rebasing de `expiry_tick` (ver Decision) depende de ese supuesto seguir siendo cierto. (4) **Semántica de rename sobre archivo existente en el target Windows del proyecto** (godot-specialist, revisión 2026-08-21): POSIX `rename()` reemplaza el destino atómicamente, pero las semánticas de rename-sobre-archivo-existente de Windows han tenido históricamente más aristas; la referencia de motor no confirma cómo se comporta `DirAccess.rename()` cross-platform en 4.6. Probar manualmente en el target Windows real que el rename `save.tmp`→`save` reemplaza atómicamente el archivo existente (garantía de AC-27) antes de confiar en ello. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Accepted) — forma de `StatModifier`/`expiry_tick`/`source_relic_id`; ADR-0002 (Accepted) — `TimeControl.game_tick` como fuente de tick pause-aware/scale-aware que este ADR debe rebasear entre sesiones |
| **Enables** | El futuro ADR de Forja de Legado (OQ-FL4 — representación de `RelicRecord`, Resource vs dato serializado) puede apoyarse en la API de serialización elegida aquí sin reabrirla; epics de Salón Conmemorativo/Panteón (#14) y Transición de Era (#15), ambos dependientes duros de Guardado/Persistencia |
| **Blocks** | Epic de Guardado/Persistencia (#3, Foundation) no puede empezar implementación hasta que este ADR sea Accepted; Reliquias/Bendiciones AC-RB46 (bloqueada, OQ-RB2); Forja de Legado AC-FL11 (round-trip de `forge_counter`); Permadeath (recuperación por crash del payload de muerte pendiente, AC-H27c) |
| **Ordering Note** | Tercer ADR del proyecto. Ambos ADRs previos (Accepted 2026-08-21) **difieren explícitamente** a este — bloqueante de arquitectura **S4** de la revisión cross-GDD 2026-08-18/21, el gap de Foundation más urgente según `/architecture-review`. |

## Context

### Problem Statement

`guardado-persistencia.md` ya fija las **reglas** del sistema de guardado (Core Rules 1–7, Approved-ready en diseño): slot único, escritura atómica vía `save.tmp` + rename, `schema_version` con cadena de migración lineal, checksum de corrupción sin auto-reparación. Pero dos decisiones de implementación quedan explícitamente abiertas en el propio GDD (tabla de Open Questions) y **ambos ADRs previos difieren aquí de forma explícita**:

- **ADR-0001** difiere la persistencia del estado efímero de invocación y el rebasing de `expiry_tick` en recarga (Related Decisions).
- **ADR-0002** difiere que el rebasing de `expiry_tick` se defina contra `TimeControl.game_tick`, no contra un contador de motor — pero `game_tick` es un contador **por sesión** (arranca en 0 con `TimeControl`, un `Node`/Autoload que se recrea en cada carga), así que un `expiry_tick` absoluto persistido de una sesión anterior no significa nada frente a un `game_tick` que reinició a 0.
- **Forja de Legado (OQ-FL4, punto 3 del scope obligatorio del ADR)** exige que `forge_counter` (contador monótono de índice de forja) sobreviva como **`int64` real** — JSON trunca enteros a 53 bits de precisión (double IEEE 754), lo cual rompe silenciosamente el contrato de unicidad de `relic_id` en legados muy largos.
- **Reliquias/Bendiciones (OQ-RB2, AC-RB46, bloqueada)** necesita que `invocation_charges_remaining` y la lista de `StatModifier` activos (con su tiempo de expiración restante) se restauren correctamente en una recarga a mitad de era.
- **Sistema de Héroes (AC-H26/AC-H27c)** persiste un payload de muerte marcado "pendiente de sellar" para que el flujo de carga pueda coaccionar `DYING→DEAD` si el juego crashea a mitad del beat `DEATH_HOLD` de Permadeath.
- El propio GDD deja abierto **qué algoritmo de checksum usar** (tabla de Open Questions: "no necesita ser criptográficamente seguro").

Ninguna de estas piezas cambia las *reglas* ya fijadas en `guardado-persistencia.md` — todas son la mecánica concreta de *cómo* se serializa, se verifica, y se rebasa el estado entre sesiones. Esto es lo que este ADR fija.

### Constraints

- **Las reglas del GDD ya están fijadas y no se reabren aquí**: slot único (Regla 3), persistencia por referencia (Regla 4), escritura atómica `save.tmp`→rename (Regla 5), versionado de esquema con migración lineal v→v+1 (Regla 6), checksum sin auto-reparación (Regla 7). Este ADR es puramente el *mecanismo* bajo esas reglas.
- **Fidelidad `int64` obligatoria** para `forge_counter` (Forja OQ-FL4 pt.3) — cualquier formato que pase por un `double` de 53 bits de mantisa es inaceptable como contrato general de serialización.
- **`game_tick` es un contador por sesión**, no un reloj persistente — ADR-0002 lo diseñó para congelarse en pausa y escalar con `time_scale`, no para sobrevivir cierres de proceso. Rebasear `expiry_tick` contra él implica que el propio `game_tick` no puede ser el dato persistido.
- **DI sobre singletons** (coding-standards) — el mecanismo de guardado debe ser testeable sin tocar disco real (inyectar una ruta de archivo temporal o una capa de I/O simulable) y sin depender de `TimeControl` por nombre global.
- **Loud-fail sobre clamp silencioso** (precedente Héroes/Combate/ADR-0001/ADR-0002) — versión futura, checksum inválido, y fallo de migración deben fallar ruidosamente, nunca degradarse en silencio.
- **Sin lógica de juego en la capa de guardado** (Overview del GDD) — el mecanismo elegido debe mantener el guardado como infraestructura opaca: no necesita entender *qué significa* cada campo, solo transportarlo con fidelidad.

### Requirements

- Un formato de serialización único que preserve `int64` exacto.
- Un checksum calculado sobre el payload serializado, sin requerir librería externa.
- Una envoltura (`schema_version` + payload) con migración lineal v→v+1, ejecutable sobre datos aún no deserializados a tipos fuertes.
- Un contrato de round-trip para el estado efímero de invocación (cargas + modificadores activos) que sobreviva la recarga sin depender de que `game_tick` conserve su valor entre sesiones.
- Un contrato de round-trip para el payload de muerte pendiente de sellar (Héroes/Permadeath).
- Testeable sin escena completa: inyección de ruta de archivo o mock de la capa de I/O, sin RNG.

## Decision

**Se introduce un servicio Core `SaveService` que posee el mecanismo de serialización, el envoltorio versionado, el checksum, y la orquestación de escritura atómica — pero no conoce el significado de ningún campo de dominio.** Cada sistema dependiente (Forja, Reliquias, Temporizador, Datos de Era, Héroes/Permadeath, Transición de Era) implementa un contrato simétrico `serialize_state() -> Dictionary` / `deserialize_state(data: Dictionary) -> void`; `SaveService` ensambla estos sub-diccionarios bajo una clave por sistema en un único payload raíz, sin inspeccionar su contenido.

**Formato de serialización: `FileAccess.store_var` / `get_var` (binario nativo de Godot) sobre un `Dictionary` anidado.** Se descarta JSON como formato general — `JSON.stringify`/`parse` representa todo número como `double` de 53 bits de mantisa, lo cual truncaría silenciosamente `forge_counter` en legados largos (el escenario exacto que OQ-FL4 punto 3 marca como obligatorio de evitar). `store_var`/`get_var` preserva `int` de Godot (64 bits) sin conversión ni codificación especial, para todo campo de todo sistema — no solo para `forge_counter` — eliminando la necesidad de una regla especial por campo que un futuro sistema podría olvidar aplicar.

**Checksum: `hash()` (Variant hash) de Godot sobre el `Dictionary` del payload, calculado antes de escribir y comparado tras recalcularlo al cargar.** El GDD (Edge Cases / Open Questions) es explícito en que el checksum defiende contra corrupción y escrituras parciales, **no** contra manipulación adversarial — no necesita ser criptográficamente fuerte ni estable entre versiones de motor (el guardado no está pensado para portarse entre versiones de Godot; una migración de motor sería, en todo caso, un evento manual y auditado, fuera del alcance de este mecanismo). Usar la función integrada evita añadir una implementación manual de CRC32 para un requisito que el propio diseño ya acotó como más débil.

**Escritura atómica usando el retorno `bool` de `store_var`/`store_buffer` (post-4.4) como señal temprana de fallo.** Cada llamada de escritura a `save.tmp` revisa su valor de retorno; un `false` en cualquier paso aborta la escritura inmediatamente y dispara el camino de reintento de `retry_delay_ms` (ya fijado en el GDD) **sin** intentar el rename — el archivo final permanece intacto (Regla 5 / AC-25/AC-26). El rename atómico en sí (`DirAccess.rename` o equivalente) es la única operación que puede dejar un estado ambiguo si falla a mitad de camino (AC-27), consistente con el GDD.

**Rebasing de `expiry_tick`: se persiste duración restante relativa, nunca el tick absoluto ni `game_tick` mismo.** `TimeControl.game_tick` (ADR-0002) **no se persiste en absoluto** — cada sesión arranca `game_tick` en 0 por diseño, congruente con su propósito (contador de tiempo de juego por sesión, pause-aware/scale-aware, no un reloj de pared). Para cada `StatModifier` activo, `SaveService`/Reliquias persiste `remaining_ticks = expiry_tick − game_tick` calculado **en el momento del guardado**. Al cargar, cada modificador se re-añade con `expiry_tick = game_tick_al_cargar (0, sesión fresca) + remaining_ticks`. Esto desacopla por completo el formato de guardado de cuánto dure una sesión — nunca hay que razonar sobre "cuánto tiempo real pasó con el juego cerrado", que es información que el diseño (Regla: las bendiciones duran tiempo de *juego*, ADR-0002) nunca quiso modelar.

**Payload de muerte pendiente de sellar (Héroes AC-H26/Permadeath AC-H27c):** se persiste como un sub-diccionario opaco más bajo la clave del Sistema de Héroes, con un campo explícito `sealed: bool = false` hasta que Permadeath complete el beat `DEATH_HOLD` y confirme `DEAD`. Al cargar con `sealed == false`, el flujo de carga invoca el mismo camino de coacción `DYING→DEAD` que ya usaría un crash en vivo (contrato ya fijado en `sistema-de-heroes.md`/`permadeath.md` — este ADR no lo redefine, solo confirma que viaja intacto en el payload serializado).

**Migraciones sobre `Dictionary` crudo, antes de deserializar a tipos fuertes.** Cada migración es una función pura `migrate_vN_to_vNplus1(data: Dictionary) -> Dictionary` registrada en una tabla ordenada por versión; `SaveService` las aplica secuencialmente desde `save.schema_version` hasta `CURRENT_SCHEMA_VERSION` **antes** de invocar `deserialize_state` de ningún sistema — los sistemas dependientes nunca ven un esquema viejo.

### Architecture Diagram

```
  Sistemas dependientes (contrato simétrico, opaco para SaveService)
  ┌─────────────────────────────────────────────────────────────┐
  │ Forja de Legado ─────► serialize_state() -> {forge_counter,  │
  │                         relic_records: [...]}                │
  │ Reliquias/Bendiciones ► serialize_state() -> {charges,        │
  │                         active_modifiers: [{stat, magnitude,  │
  │                         remaining_ticks, source_relic_id}]}   │
  │ Sistema de Héroes ────► serialize_state() -> {pending_death:  │
  │                         {..., sealed: bool}}                  │
  │ Temporizador ─────────► serialize_state() -> {elapsed_s,      │
  │                         current_phase}                        │
  │ Datos de Era/Civ. ────► serialize_state() -> {era_id activa}  │
  │ Transición de Era ────► serialize_state() -> {era_id/ARCHIVED}│
  └─────────────────────────────────────────────────────────────┘
        ▲ deserialize_state(data)          │ serialize_state()
        │ (tras migraciones)               ▼
  ┌─────────────────────────────────────────────────────────────┐
  │  SaveService (Core) — NO conoce el significado de los campos │
  │                                                                │
  │  payload = { schema_version, sistemas: { <clave>: <dict> } } │
  │  checksum = hash(payload)                                    │
  │                                                                │
  │  request_save():                                             │
  │    store_var(save.tmp, payload+checksum) -> bool en cada paso│
  │    bool==false en cualquier paso → retry_delay_ms, sin rename│
  │    éxito → rename atómico save.tmp → save                    │
  │                                                                │
  │  request_load():                                             │
  │    get_var(save) -> payload; recompute hash; comparar        │
  │    mismatch → CORRUPTED (sin auto-reparación)                │
  │    payload.schema_version > CURRENT → bloqueo explícito       │
  │    payload.schema_version < CURRENT → migrar v→v+1 en cadena  │
  │    despachar sub-dict a cada sistema.deserialize_state()      │
  └─────────────────────────────────────────────────────────────┘
        │ rebasing de expiry_tick (Reliquias, al deserializar):
        ▼ expiry_tick_nuevo = TimeControl.game_tick (0, sesión fresca)
                              + remaining_ticks_persistido
```

### Key Interfaces

```gdscript
# SaveService — servicio Core. Inyectado por referencia (composition root), igual que
# TimeControl (ADR-0002) — NO se llama SaveService.* por nombre global disperso.
# Los tests inyectan una ruta de archivo temporal (o un FileAccess-like fake) para
# evitar tocar disco real.
class_name SaveService extends Node

const CURRENT_SCHEMA_VERSION: int = 1
const SAVE_PATH: String = "user://save.dat"
const SAVE_TMP_PATH: String = "user://save.tmp"

enum LoadResult { NO_SAVE_EXISTS, SAVE_EXISTS, CORRUPTED, VERSION_TOO_NEW }

# Contrato simétrico que cada sistema dependiente implementa (no un método de SaveService):
#   func serialize_state() -> Dictionary
#   func deserialize_state(data: Dictionary) -> void
# SaveService los invoca por una lista de referencias inyectadas (composition root),
# nunca por búsqueda de nodo/autoload por nombre.

func register_persistable(system_key: StringName, node: Node) -> void
# node debe implementar serialize_state()/deserialize_state(Dictionary); loud-fail si no.

func request_save() -> bool
# Ensambla payload = {schema_version: CURRENT_SCHEMA_VERSION, sistemas: {...}},
# calcula checksum = hash(payload), y escribe atómicamente el sobre externo
# {payload: payload, checksum: checksum} (checksum como clave HERMANA, no dentro
# del dict hasheado). Abre save.tmp con FileAccess.open(WRITE) y chequea
# get_open_error() ANTES de store_var; un open fallido o un store_var()==false
# aborta sin rename y entra al reintento retry_delay_ms (GDD Formulas). Serializa el
# estado de invocación de Reliquias como remaining_ticks (ver rebasing en Decision),
# NUNCA como expiry_tick absoluto ni como TimeControl.game_tick. Retorna éxito/fallo.

func request_load() -> LoadResult
# FileAccess.open(SAVE_PATH, READ) + get_open_error() (si falla la apertura y no hay
# archivo -> NO_SAVE_EXISTS; si existe pero no abre -> CORRUPTED). get_var(allow_objects
# = false) del sobre; recalcula hash(sobre.payload), compara con sobre.checksum. Si
# payload.schema_version > CURRENT_SCHEMA_VERSION -> VERSION_TOO_NEW (bloqueo, sin
# migración, ver Edge Cases del GDD). Si < CURRENT -> aplica la cadena de migraciones
# registrada, en orden, v->v+1 exclusivamente. Despacha cada sub-dict a
# deserialize_state() del sistema correspondiente. Detecta y descarta cualquier
# save.tmp huérfano antes de leer save.

# Migraciones: tabla ordenada de funciones puras sobre Dictionary crudo (pre-tipos fuertes).
# func migrate_v1_to_v2(data: Dictionary) -> Dictionary  # ejemplo de forma, v2 aún no existe
```

**Contrato de invariantes (loud-fail):**
- `forge_counter` (y cualquier campo declarado `int64` por un sistema dependiente) se serializa con `store_var`, nunca convertido a `float`/`String` en el camino — un intento de pasar por JSON en cualquier sub-sistema es un bug de programación.
- `TimeControl.game_tick` **nunca** aparece en el payload serializado de ningún sistema — solo `remaining_ticks` (relativo). Un campo `game_tick`/`expiry_tick` absoluto en un `serialize_state()` es un error de diseño de ese sistema, detectable por revisión/CI (grep del símbolo `game_tick` fuera de `time_control.gd`).
- **`serialize_state()` devuelve únicamente `Variant` planos: `Dictionary`/`Array`/primitivos — nunca instancias `RefCounted`/`Resource`/`Object`** (p. ej. un `StatModifier` vivo). `store_var`/`get_var` mantienen sus parámetros `full_objects`/`allow_objects` en su default `false`: deserializar Objetos desde un archivo es superficie de ataque (instanciación arbitraria desde un save manipulado), no solo estilo. Los sistemas convierten su estado a `Dictionary` plano **antes** de entregarlo a `SaveService` (grep CI: ningún `store_var(..., true)`/`get_var(..., true)` en el código de guardado). (godot-specialist, revisión 2026-08-21.)
- **El handle de `FileAccess` se valida antes de cualquier `store_var`/`get_var`.** El retorno `bool` de `store_var` solo cubre fallos *con un handle ya abierto*; si `FileAccess.open(SAVE_TMP_PATH, WRITE)` falla (disco lleno, permisos, `user://` no escribible), devuelve `null` y llamar `.store_var()` sobre él crashea. `request_save`/`request_load` chequean `FileAccess.get_open_error()` inmediatamente tras cada `open()`, antes de tocar el archivo — un `open()` fallido entra al camino de reintento de `retry_delay_ms` (escritura) o a `CORRUPTED`/`NO_SAVE_EXISTS` (lectura), nunca a un crash de referencia nula. (godot-specialist, revisión 2026-08-21.)
- El checksum se calcula **después** de que todos los `serialize_state()` completaron y **antes** de escribir a `save.tmp` — nunca sobre datos parcialmente ensamblados. **Envoltura explícita**: el payload se escribe como `{ payload: {schema_version, sistemas:{...}}, checksum: int }` — el `checksum` es una clave **hermana externa** al `Dictionary` que se hashea, no una clave insertada dentro de él (evita el riesgo de hashear un dict que ya contiene un `checksum: 0` placeholder). Al cargar, se recalcula `hash(payload)` y se compara con `checksum`. (godot-specialist, revisión 2026-08-21.)
- Una migración nunca salta versiones (v→v+2 directo prohibido, ya fijado en el GDD Regla 6 — este ADR no lo cambia, solo fija que las migraciones operan sobre `Dictionary` crudo, no sobre instancias ya deserializadas a clases tipadas). Nota: `get_var` no reconstruye el *tipado estático* de un `Array[T]`/`Dictionary` tipado — por eso los sistemas entregan `Array`/`Dictionary` planos (p. ej. `active_modifiers` como `Array` de dicts sin tipar), congruente con que las migraciones operan sobre `Dictionary` crudo.
- `sealed: bool` del payload de muerte pendiente nunca se omite — un sistema que no lo incluya rompe el contrato de recuperación por crash (AC-H27c) de forma silenciosa.

## Alternatives Considered

### Alternative 1: JSON (`store_string` + `JSON.stringify`/`parse`)
- **Description**: Serializar el payload como texto JSON legible por humanos.
- **Pros**: Diffable, editable a mano durante desarrollo, inspeccionable sin abrir Godot.
- **Cons**: Todo número pasa por `double` (53 bits de mantisa) — `forge_counter` se trunca silenciosamente en legados largos, violando el requisito explícito de OQ-FL4 punto 3. Requeriría una codificación especial (p. ej. campo como `String`) solo para ese campo, con el riesgo de que un futuro campo `int64` (p. ej. un contador similar en otro sistema) olvide aplicar la misma regla especial.
- **Rejection Reason**: Rompe un requisito ya explícito de un GDD Approved (Forja de Legado); la legibilidad no compensa un bug de truncamiento silencioso en un contador que garantiza unicidad de `relic_id`.

### Alternative 2: Híbrido — JSON con campos `int64` codificados como `String`
- **Description**: Mantener JSON para la mayoría de campos (legibilidad), pero serializar cualquier campo `int64` como texto y parsearlo de vuelta a `int` al cargar.
- **Pros**: Conserva la inspeccionabilidad de JSON para la mayoría del guardado.
- **Cons**: Introduce una regla asimétrica por tipo de campo que cada sistema dependiente debe recordar aplicar correctamente — exactamente el tipo de disciplina manual perpetua que el proyecto prefiere evitar (precedente: "loud-fail sobre disciplina manual" en ADR-0001/0002). Un futuro sistema con su propio contador de 64 bits podría usar un `int` JSON normal por descuido y fallar solo en producción, tras muchas horas de juego — el peor momento para un truncamiento silencioso.
- **Rejection Reason**: Añade complejidad y una fuente de error recurrente y sistémica para resolver un problema que `store_var` resuelve uniformemente sin reglas especiales.

### Alternative 3: Persistir `TimeControl.game_tick` absoluto entre sesiones (en vez de rebasing relativo)
- **Description**: Guardar el valor de `game_tick` junto con `expiry_tick` absoluto de cada modificador; al cargar, restaurar `game_tick` al valor persistido en vez de reiniciar en 0.
- **Pros**: No requiere una operación de rebasing explícita — los ticks absolutos siguen siendo válidos si `game_tick` continúa donde quedó.
- **Cons**: Convierte `game_tick` en un reloj de pared disfrazado que sobrevive cierres de proceso — exactamente lo que ADR-0002 evitó al diseñarlo como contador de tiempo de *juego* por sesión (congela en pausa, escala con `time_scale`, sin semántica definida para "cuánto tiempo real pasó con el juego cerrado"). Acopla el formato de guardado a la vida útil de `TimeControl`, y arriesga overflow/drift en legados de sesiones muy largas sin ningún beneficio de diseño — el GDD nunca pidió que las bendiciones "seguende corriendo" mientras el juego está cerrado.
- **Rejection Reason**: Contradice el propósito de diseño de `game_tick` fijado en ADR-0002; el rebasing relativo (Decision) logra el mismo resultado observable sin la deuda conceptual.

### Alternative 4: CRC32 manual para el checksum
- **Description**: Implementar CRC32 sobre los bytes del payload serializado.
- **Pros**: Algoritmo estándar, ampliamente entendido, portable entre implementaciones.
- **Cons**: Godot no expone un CRC32 de propósito general integrado para `PackedByteArray` arbitrario — requeriría una implementación manual (tabla de lookup o cálculo bit a bit) para un requisito que el propio GDD (Open Questions) ya acota como "no necesita ser criptográficamente segura, defiende contra corrupción/escrituras parciales, no contra manipulación".
- **Rejection Reason**: Código adicional sin beneficio medible frente a `hash()` integrado, dado el requisito real (detectar corrupción/escritura parcial, no resistir manipulación adversarial ni portarse entre motores).

## Consequences

### Positive
- Cierra el bloqueante de arquitectura **S4**: los tres huecos que ambos ADRs previos dejaron abiertos (formato de serialización, checksum, rebasing de `expiry_tick`) quedan resueltos con una sola decisión coherente.
- `forge_counter` (Forja AC-FL11) y cualquier futuro contador `int64` se serializan sin riesgo de truncamiento, sin reglas especiales por campo.
- El rebasing relativo de `expiry_tick` desbloquea Reliquias AC-RB46 sin que `TimeControl` tenga que cambiar su diseño (ADR-0002 permanece intacto — `game_tick` sigue siendo puramente por sesión).
- El contrato `serialize_state()`/`deserialize_state()` mantiene a `SaveService` genuinamente agnóstico de dominio (Overview del GDD: "no contiene lógica de juego") — añadir un nuevo sistema persistible (Transición de Era, Panteón) no requiere tocar `SaveService`, solo implementar el contrato.
- El payload de muerte pendiente (`sealed: bool`) hace explícito y testeable el camino de recuperación por crash que Héroes/Permadeath ya diseñaron (AC-H27c), en vez de dejarlo implícito en la forma del dato.

### Negative
- `store_var`/`get_var` produce un archivo binario no legible por humanos — depurar un guardado de un jugador reportando un bug requiere abrir el proyecto en Godot (o un script standalone) en vez de leer un archivo de texto directamente.
- El contrato simétrico `serialize_state()`/`deserialize_state()` es disciplina perpetua: cada sistema dependiente nuevo (Panteón, Transición de Era, y cualquier sistema futuro) debe implementarlo correctamente, incluyendo la regla `remaining_ticks`-nunca-`game_tick`/`expiry_tick`-absoluto para cualquier duración temporizada que introduzca.
- Las migraciones sobre `Dictionary` crudo (antes de tipos fuertes) significan que el código de migración no tiene la seguridad de tipos del resto del proyecto — un error de clave (`data.get("froge_counter")`, typo) solo se detecta en tiempo de ejecución, no en compilación.

### Risks
- **Colisión de `hash()`**: `hash()` de Godot devuelve un hash de **32 bits** (extendido con ceros al `int` de 64 bits de GDScript), no un hash de 64 bits ni criptográfico — la probabilidad de colisión ante un payload corrupto es del orden de 1-en-~4·10⁹, no "astronómica" (godot-specialist, revisión 2026-08-21). Sigue siendo aceptable dado el requisito real del GDD (detectar corrupción/escritura parcial, no resistir manipulación), pero un lector futuro no debe sobre-confiar en el ancho de bits. *Mitigación*: ninguna requerida más allá de lo ya aceptado en el GDD; si algún día se quisiera más margen, el algoritmo de checksum es un detalle intercambiable sin cambiar el resto del contrato.
- **`FileAccess.open()` fallido devuelve `null`, no un `false`**: el retorno `bool` de `store_var` solo cubre fallos con un handle ya abierto; una apertura fallida (disco lleno, permisos, `user://` no escribible) devuelve `null` y llamar `.store_var()` sobre él crashea. *Mitigación*: chequeo obligatorio de `FileAccess.get_open_error()` inmediatamente tras cada `open()`, antes de cualquier `store_var`/`get_var` (ver invariantes) — un modo de fallo distinto del que cubre el retorno `bool`, ambos enrutados al camino de reintento/`CORRUPTED`, nunca a un crash.
- **Deserialización de Objetos como superficie de ataque**: si un sistema entregara una instancia `RefCounted`/`Resource` viva a `store_var` (o alguien activara `allow_objects=true` al cargar), un save manipulado podría instanciar Objetos arbitrarios. *Mitigación*: invariante loud-fail — `serialize_state()` solo devuelve `Variant` planos; `full_objects`/`allow_objects` quedan en su default `false`; grep CI sobre `store_var(..., true)`/`get_var(..., true)`. El diseño ya lo evita (cada sistema entrega un `Dictionary` plano), pero se hace regla explícita en vez de detalle implícito del diagrama.
- **Determinismo de `hash()` entre versiones de Godot**: si el proyecto migrara de motor en el futuro, un guardado viejo podría fallar su checksum simplemente por el cambio de versión, no por corrupción real. *Mitigación*: fuera de alcance de este ADR — una migración de motor sería un evento manual, auditado, y `CURRENT_SCHEMA_VERSION` ya provee el mecanismo para tratar guardados de una build distinta explícitamente (aunque hoy el eje de versión es de contenido/esquema, no de motor). Registrado como riesgo aceptado, no bloqueante.
- **Disciplina de `remaining_ticks` no enforced automáticamente**: nada impide hoy que un futuro sistema serialice un `expiry_tick` absoluto por error. *Mitigación*: grep de CI sobre el símbolo `game_tick`/`expiry_tick` fuera de los módulos de `TimeControl`/rebasing dedicados (mismo patrón de enforcement que ADR-0002 usa para `_process(delta)`), documentado en el control-manifest.
- **`store_var`/`store_buffer` retorno `bool` no verificado en cada punto de escritura**: si un programador olvida chequear el retorno en un paso intermedio, un fallo de disco a mitad de escritura podría pasar desapercibido hasta el rename. *Mitigación*: `request_save()` centraliza todos los pasos de escritura en un solo método de `SaveService` — no hay puntos de escritura dispersos por el código de otros sistemas que puedan omitir el chequeo.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `guardado-persistencia.md` | Regla 5 (escritura atómica `save.tmp`→rename); AC-12/13/14/24/25/26/27 | `request_save()` centraliza la escritura, usa el retorno `bool` de `store_var`/`store_buffer` (post-4.4) para abortar antes del rename en fallo de escritura temporal; el rename es la única operación que puede producir `CORRUPTED` |
| `guardado-persistencia.md` | Regla 6 (versionado de esquema, migración lineal v→v+1); AC-15/16/17/18 | Migraciones como funciones puras sobre `Dictionary` crudo, aplicadas antes de `deserialize_state`; `schema_version > CURRENT` bloquea sin migrar (`VERSION_TOO_NEW`) |
| `guardado-persistencia.md` | Regla 7 (checksum sin auto-reparación); AC-19/20/21/30; Open Question de algoritmo | `hash()` de Godot sobre el payload; recalculado y comparado al cargar; mismatch → `CORRUPTED`, ninguna escritura de reparación (resuelve el Open Question del GDD) |
| `forja-de-legado.md` | OQ-FL4 punto 3 (fidelidad `int64` de `forge_counter`); AC-FL11 | `store_var`/`get_var` preserva `int` de 64 bits nativamente, sin codificación especial — `forge_counter` nunca pasa por un `double` |
| `reliquias-bendiciones.md` | OQ-RB2 / AC-RB46 (round-trip de `invocation_charges_remaining` y modificadores activos con expiración restante) | Contrato `serialize_state()` de Reliquias persiste `charges_remaining` + `remaining_ticks` por modificador (no `expiry_tick` absoluto); rebasing al cargar contra `TimeControl.game_tick` fresco (0) |
| ADR-0001 (`combate-dano.md`/`reliquias-bendiciones.md`) | Persistencia diferida del estado efímero de invocación y de `StatModifier`, incl. rebasing de `expiry_tick` | Resuelto vía `remaining_ticks` relativo — `game_tick` nunca se persiste; `StatModifier.expiry_tick` se reconstruye al cargar |
| ADR-0002 (`permadeath.md`/`reliquias-bendiciones.md`/`temporizador...md`) | Rebasing de `expiry_tick` definido contra `TimeControl.game_tick`, no un contador de motor | `remaining_ticks` se calcula contra `game_tick` en el momento de guardar; `game_tick` en sí permanece puramente por sesión, sin cambios a su diseño |
| `sistema-de-heroes.md` / `permadeath.md` | AC-H26/AC-H27c (payload de muerte pendiente de sellar, recuperación por crash mid-beat) | Sub-diccionario opaco con campo explícito `sealed: bool`; el flujo de carga invoca la misma coacción `DYING→DEAD` que un crash en vivo |

## Performance Implications
- **CPU**: `store_var`/`get_var` sobre un payload de decenas de campos (referencias/IDs/contadores, nunca copias de `EraDefinition` — Regla 4 del GDD) es sub-milisegundo, consistente con la nota de diseño ya presente en el GDD (Formulas). El cálculo de `hash()` es O(tamaño del payload), despreciable al mismo orden de magnitud.
- **Memory**: Sin estructuras persistentes adicionales en memoria — el payload se ensambla y se libera por guardado/carga.
- **Load Time**: Nulo más allá de la lectura de un único archivo pequeño; las migraciones (cuando existan) son transformaciones de `Dictionary` en memoria, sin I/O adicional.
- **Network**: N/A (sin multijugador en el MVP).

## Migration Plan
No hay código aún (fase de diseño). En implementación: (1) crear `SaveService` (Core, inyectable, con `FakeFileAccess`/ruta temporal para tests). (2) Cada sistema dependiente (Forja, Reliquias, Temporizador, Datos de Era, Héroes, Transición de Era) implementa `serialize_state()`/`deserialize_state()` y se registra vía `register_persistable`. (3) Reliquias adapta su estado de invocación activo para computar `remaining_ticks` en `serialize_state()` en vez de exponer `expiry_tick` absoluto. (4) Héroes incluye el campo `sealed` en su payload de muerte pendiente. (5) `CURRENT_SCHEMA_VERSION` arranca en 1; la primera migración real se escribe cuando el primer cambio de esquema lo requiera (no antes — no hay migraciones especulativas). **Ediciones cross-GDD a aplicar al aceptar**: `reliquias-bendiciones.md` (OQ-RB2 cerrado, contrato real de round-trip reemplaza el mock `save_ephemeral_invocation_state`/`load_ephemeral_invocation_state`), `forja-de-legado.md` (OQ-FL4 punto 3 confirmado — `store_var`/`get_var` es la API elegida), `guardado-persistencia.md` (Open Question de algoritmo de checksum resuelto → `hash()`).

## Validation Criteria
- Test unitario: `request_save()`/`request_load()` round-trip de un payload con un `int` de valor `> 2^53` (p. ej. `forge_counter` simulado) preserva el valor exacto — prueba directa de que `store_var` no trunca donde JSON lo haría.
- Test unitario: checksum recalculado sobre un payload sin modificar coincide; sobre un payload con un byte alterado, no coincide → `CORRUPTED`.
- Test unitario: un modificador activo con `remaining_ticks = 300` persistido, cargado con `TimeControl.game_tick` reiniciado en 0, produce `expiry_tick == 300` tras la carga (no arrastra el `game_tick` de la sesión anterior).
- Test unitario: `request_save()` cuyo paso de escritura a `save.tmp` retorna `false` (mock de fallo de disco) aborta antes del rename; el archivo de guardado final no cambia.
- Test de integración: una cadena de 2 migraciones simuladas (`v1→v2→v3`) se aplica en orden estricto sobre un `Dictionary` con `schema_version=1`, nunca salta a `v3` directamente.
- Test de integración: payload de muerte pendiente con `sealed=false` al cargar dispara la coacción `DYING→DEAD` (mock del hook de Permadeath/Héroes).
- Loud-fail: `schema_version` del guardado mayor que `CURRENT_SCHEMA_VERSION` → bloqueo explícito, cero migraciones ejecutadas, cero intento de "continuar de todos modos".
- CI: grep del símbolo `game_tick`/`expiry_tick` fuera de `time_control.gd` y del código de rebasing de guardado dedicado → cero apariciones sin justificar.

## Related Decisions
- ADR-0001 (capa de modificadores de stat por instancia) — este ADR resuelve el hand-off de persistencia que ADR-0001 dejó explícitamente abierto.
- ADR-0002 (servicio `TimeControl`) — este ADR resuelve el rebasing de `expiry_tick` contra `game_tick` que ADR-0002 dejó explícitamente abierto, sin modificar el diseño de `TimeControl`.
- Futuro ADR: representación de `RelicRecord` (Forja de Legado, OQ-FL4 — Resource `.tres` vs dato serializado) puede apoyarse en la elección de `store_var`/`get_var` de este ADR.
- `docs/architecture/architecture-review-2026-08-21.md` — bloqueante **S4** (origen de este ADR).
- `design/gdd/guardado-persistencia.md`, `design/gdd/forja-de-legado.md`, `design/gdd/reliquias-bendiciones.md`, `design/gdd/sistema-de-heroes.md`, `design/gdd/permadeath.md` — GDDs a reconciliar al aceptar.
