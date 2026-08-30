# Combate/Daño

> **Status**: In Design
> **Author**: usuario + agentes
> **Last Updated**: 2026-08-09
> **Implements Pillar**: Preparación Ritual, Clímax Explosivo (Pilar 3); habilita Sacrificio con Peso (Pilar 1)

## Overview

Combate/Daño es el sistema de **resolución de combate** del juego: decide cuándo dos fuerzas entran en contacto, cuánto daño se inflige por golpe, cuándo una unidad muere, y —de forma única en este juego— **bajo qué circunstancias murió un héroe**. A nivel de datos, es la capa que las tropas, los héroes y (por contrato) el kaiju delegan para todo cálculo de daño: posee el contrato de **contacto/aggro** que dispara el estado de combate, aplica el **daño-por-golpe** que determina cuántos golpes matan a cada tipo de unidad, hace clamp de la vida a 0 en overkill, y notifica `DYING` (héroe) / `DEAD` (tropa). A nivel de jugador, es donde vive el clímax del **Pilar 3**: los choques breves e intensos contra el kaiju que la fase de Preparación anticipa. Pero su rol más importante es silencioso: es el sistema que **clasifica las circunstancias de la muerte de un héroe** —si fue deliberada (`D`), si sirvió un propósito (`P`)— y entrega ese veredicto a Permadeath, que lo convierte en la calidad de la reliquia. Sin Combate/Daño no habría clímax que resolver ni, más importante, un puente entre "un héroe murió" y "qué compró esa muerte" — es el sistema que hace que el **Pilar 1** tenga consecuencias mecánicas, no solo narrativas.

## Player Fantasy

**El jugador es el comandante en el choque decisivo.** El combate es el momento en que la Preparación cobra o pierde su sentido: las tropas posicionadas, los héroes comprometidos, todo se resuelve en enfrentamientos **breves, densos e intensos** (Pilar 3). No es la fantasía del micro frenético de APM alto — es la del general de Warcraft 3, con pocas unidades que importan, donde cada choque tiene peso porque las tropas son finitas y los héroes irremplazables. La satisfacción táctil de dos fuerzas colisionando, pero siempre al servicio de una aritmética mayor: no estás optimizando DPS, estás decidiendo qué se gasta y por qué.

Su carga emocional más honda es que **el combate es donde la tragedia se ejecuta**. Cuando un héroe entra en combate, el jugador no está maximizando daño — está decidiendo, con las manos, qué compra esa vida. Aquí, en el choque, es donde la diferencia entre una muerte desperdiciada y una bien gastada se vuelve un acto concreto y no una abstracción: el sistema que traduce "cómo peleaste" en "qué reliquia nace" (`D`/`P`) vive precisamente en este momento. Combate/Daño es lo que hace que el Pilar 1 tenga dientes: sin él, "el sacrificio pesa" sería una frase; con él, es una decisión táctica que el jugador toma y siente.

La honestidad de la fantasía descansa, otra vez, en la **legibilidad**: el jugador debe poder leer quién gana el choque, qué está muriendo y quién está en peligro, para que su decisión de comprometer o retirar sea informada y no una lotería. La tragedia legítima es la de decidir bajo un choque legible — no la de ser sorprendido por matemática opaca. Un combate cuyo resultado el jugador no pudo anticipar ni influir no es tensión táctica; es azar, y traiciona el Pilar 4 (Historia Jugada, No Contada).

## Detailed Design

### Core Rules

1. **Autoridad única de daño**: *todo* daño en el juego (unidad↔unidad y kaiju↔unidad) se aplica a través de una única operación `apply_damage(target, amount, source)` que hace clamp de la vida a `[0, max_health]` y dispara la notificación de muerte. Un solo camino de daño y muerte — no hay vías paralelas. Los valores de ataque son data-driven (ver `CombatProfile`, Regla 2). **Combate resuelve en el tick de física (`_physics_process`, paso fijo), nunca en `_process`** — es la única forma de que los TTK exactos de Formulas (F3) sean reproducibles y no dependan del framerate. **Cada tick se resuelve en dos fases, en este orden estricto**: (1) se aplican *todos* los `apply_damage` pendientes del tick contra el estado de vida vigente al inicio del tick — ningún golpe de este tick ve el resultado de otro golpe del mismo tick; (2) solo cuando la fase (1) termina para *todos* los combatientes, se disparan *todas* las notificaciones de muerte (`DEAD`/`DYING`) y se computa `D`/`P` (Regla 8) contra el estado de mundo post-daño. Esto es lo que garantiza que un mutual kill simultáneo (ver Edge Cases) sea real — ninguna unidad puede leer o reaccionar a la muerte de otra que murió en el mismo tick antes de que la fase (2) empiece.

2. **`CombatProfile` por tipo de unidad (owned por este sistema)**: cada tipo de unidad (tropa, héroe) y el kaiju tienen un `CombatProfile` con `attack_damage` (int), `attack_range` (world units), `attack_cooldown_s` (float), `aggro_range` (≥ `attack_range`) y `leash_range`. Estos son los stats de combate que Tropas/Héroes deliberadamente **no** poseen (Tropas difirió armadura/daño a este sistema). *(Dónde se almacena el `CombatProfile` — embebido en `TroopDefinition`/`HeroDefinition` vs. resource paralelo — es una decisión de arquitectura, ver Open Questions.)*

3. **Ataque en tiempo real por cooldown**: cuando una unidad tiene un objetivo válido dentro de `attack_range` y su cooldown está listo, inflige `attack_damage` vía `apply_damage` y reinicia el cooldown (`attack_cooldown_s`). Sin proyectiles con viaje en el MVP (impacto instantáneo al resolver el golpe); el rol `ranged` se modela con mayor `attack_range`, no con física de proyectil. **El cooldown nunca se resetea por perder o cambiar de objetivo** — sigue corriendo igual en `NO_TARGET` que en cualquier otro estado (anti-exploit, ver Edge Cases). Al adquirir un objetivo (nuevo o el mismo tras reordenar) se aplica además un **piso de adquisición**: el primer golpe contra ese objetivo nunca cae antes de que transcurra un `attack_cooldown_s` completo desde el instante de esa adquisición, incluso si el cooldown heredado ya había llegado a 0 mientras la unidad estaba `NO_TARGET`. El atacante golpea cuando **ambas** condiciones se cumplen — cooldown heredado en 0 **y** piso de adquisición cumplido — cerrando tanto el reset-por-cambio-de-objetivo como el farmeo de golpes instantáneos por banking de cooldown en `NO_TARGET`.

4. **Aggro híbrido con auto-persecución acotada**: una unidad **sin orden explícita** auto-adquiere al enemigo válido más cercano dentro de `aggro_range` y lo persigue hasta atacarlo, sin alejarse más de `leash_range` de su posición de retención (si el enemigo escapa el leash, la unidad vuelve a retener). Una **orden explícita** de Control (attack-target o attack-move) sobreescribe la adquisición automática: attack-target fija un objetivo hasta que muere/sale de rango o se reordena; attack-move avanza al destino auto-enganchando enemigos en el camino. **La posición de retención se fija en el instante en que la unidad entra a `TARGET_ACQUIRED`** (el momento de adquisición) y no se actualiza mientras dura esa persecución/enganche. Si la unidad mata a su objetivo y auto-adquiere uno nuevo (encadenando kills), la posición de retención se **re-fija** en ese nuevo instante de adquisición — cada persecución individual queda acotada a `leash_range` desde donde empezó, aunque una cadena de kills sucesivos puede desplazar a la unidad más allá del `leash_range` original en conjunto.

5. **Daño plano por golpe (sin armadura en el MVP)**: el defensor pierde exactamente `attack_damage`; no hay mitigación, armadura ni multiplicadores de tipo. `kill_time = ceil(defender_HP / attacker_damage)` — legible por diseño (Player Fantasy). El overkill se descarta: la vida hace clamp a 0, nunca negativa. *(Hooks de armadura/tipo se dejan para post-MVP; ver Open Questions.)*

   **Excepciones nombradas a "sin multiplicadores / camino único" (reconciliación cross-GDD 2026-08-21):**
   - **Furia del Kaiju (×1.5)** — la única excepción **multiplicativa** del proyecto (Encuentro con Kaiju Regla 10/F5, `attack_damage_effective = round(attack_damage × 1.5)`). Combate **no** aplica el multiplicador: el controlador del Kaiju computa el `amount` ya escalado y lo pasa por el camino único `apply_damage(target, amount, source)` (Regla 1 intacta). Los bonos de bendición **no** son multiplicativos — son planos aditivos vía la capa `CombatState` (ADR-0001), así que no amplían esta regla.
   - **Clamp de expiración de bendición defensiva (F-RB4)** — cuando un modificador defensivo expira, `max_health` baja `−N` y `current_health = min(current_health, nuevo_max_health)` por **clamp directo**, NO vía `apply_damage`. Es un carve-out deliberado del camino único de la Regla 1, propiedad del barrido de expiración de `CombatState` (ADR-0001); "expirar nunca mata" (nunca dispara `DYING`). Reliquias AC-RB36.

6. **Notificación de combate (Combate no posee el estado de la unidad)**: cuando una unidad adquiere objetivo, Combate notifica `ENGAGED` (tropa) / `ALIVE_ENGAGED` (héroe) a su sistema dueño; cuando pierde el objetivo y no hay otro en `aggro_range`, notifica el fin de combate. La vida y el estado de vida (IDLE/MOVING/ENGAGED/DEAD, ALIVE_*/DYING/DEAD) los **poseen** Tropas/Héroes; Combate solo dispara las transiciones y almacena la vida a través de la operación de daño.

7. **Muerte por cruce de 0**: cuando `apply_damage` lleva la vida a ≤0, Combate hace clamp a 0 y notifica:
   - **Tropa** → `DEAD`, **sin** capturar ningún dato de circunstancia (`killer_id`, ubicación, timestamp, causa) — Pilar 1, coherente con Tropas AC-06.
   - **Héroe** → `DYING`, y **en ese mismo frame de cruce por 0 Combate computa y expone `D` y `P`** (Regla 8) para que el snapshot de Héroes los congele junto con `T` (que Héroes lee del Temporizador).

8. **Clasificación `D`/`P` como clasificador puro (al morir un héroe)**: en el frame de muerte de un héroe, Combate **computa** los booleanos leyendo estado externo — no posee ni el verbo Sacrificio ni el marcado:
   - **`D=1`** sii, leyendo el estado de comando de **Control/órdenes**: hay un comando **Sacrificio** activo/no-cancelado sobre este héroe **Y** la muerte ocurrió dentro de `sacrifice_radius` (=3.0, knob de Héroes) del destino ordenado. Si no, `D=0`.
   - **`P=1`** sii, leyendo el estado marcado de **Encuentro con Kaiju**: la muerte ocurrió dentro de `guard_radius` (=4.0, knob de Héroes) de un objetivo/aliado marcado (vía **defensiva**) **O** el héroe neutralizó una amenaza crítica marcada del kaiju (vía **ofensiva**). Si no, `P=0`.
   - Combate **no** computa `T` (eso lo provee el Temporizador y lo lee Héroes). Combate solo produce `D`/`P` y los entrega a Héroes, que los reenvía a Permadeath en su payload.

9. **Combate no evalúa victoria/derrota de era** (mismo hueco abierto que Tropas y Héroes): solo resuelve daño y notifica muertes; quién declara el fin de la era es Encuentro con Kaiju o Transición de Era.

### States and Transitions

Combate **no** posee el ciclo de vida de la unidad (eso es de Tropas/Héroes). Lo que sí modela es el **ciclo de enganche de combate por combatiente**:

| Estado de enganche | Descripción | Transición desde | Transición hacia |
|---|---|---|---|
| `NO_TARGET` | Sin objetivo; escaneando `aggro_range` (si sin orden) | Inicio; objetivo perdido; retorno por leash | `TARGET_ACQUIRED` |
| `TARGET_ACQUIRED` | Objetivo fijado (por aggro u orden); persiguiendo/posicionando si fuera de `attack_range` | `NO_TARGET`; reorden | `ATTACKING`, `NO_TARGET` (objetivo muere/escapa leash) |
| `ATTACKING` | Objetivo dentro de `attack_range`; infligiendo `attack_damage` cada `attack_cooldown_s` | `TARGET_ACQUIRED` | `TARGET_ACQUIRED` (objetivo sale de rango), `NO_TARGET` (objetivo muere) |

- La entrada a `TARGET_ACQUIRED`/`ATTACKING` dispara la notificación `ENGAGED`/`ALIVE_ENGAGED` al sistema dueño; el retorno a `NO_TARGET` sin otro objetivo dispara el fin de combate.
- La **posición de retención** se fija en el instante de entrada a `TARGET_ACQUIRED` (Regla 4) — no se actualiza mientras la unidad persigue; se re-fija en cada nueva adquisición, incluida tras encadenar un kill.
- Este ciclo aplica igual a tropas, héroes y al kaiju (el kaiju es un combatiente con su propio `CombatProfile`, aunque su selección de objetivo la dirige la IA de Encuentro con Kaiju).

### Interactions with Other Systems

| Sistema | Dirección | Interfaz |
|---|---|---|
| Sistema de Tropas | bidireccional | Combate lee el `CombatProfile` de la tropa, aplica daño a su vida, y notifica `ENGAGED`/fin-de-combate/`DEAD` (sin data de circunstancia). Tropas posee vida y estado de vida. ✅ Diseñado |
| Sistema de Héroes | bidireccional | Igual que Tropas, y además: al cruzar 0, Combate computa y expone `D`/`P` para el snapshot de Héroes; notifica `DYING`. ✅ Diseñado |
| Control y Selección de Unidades | Control → Combate | Combate lee las órdenes explícitas de ataque (attack-target, attack-move) y el **estado del comando Sacrificio activo** por héroe (para `D`). Control posee la emisión de órdenes. ⚠️ **Parcial** — Control tiene GDD para selección/movimiento, pero el **comando Sacrificio y los verbos attack-target/attack-move aún NO están definidos** en `control-y-seleccion-de-unidades.md`; el lado `D` de la clasificación depende de esa adición (ver Open Questions OQ-2) |
| Encuentro con Kaiju | bidireccional | Combate aplica el daño kaiju→unidad y unidad→kaiju (autoridad centralizada); lee las definiciones de ataque del kaiju y el **estado de objetivos/amenazas marcadas** (para `P`). Kaiju posee su IA de objetivo y el marcado. ✅ **Approved** (`encuentro-con-kaiju.md`) — el marcado (`marked_targets`/`marked_threats`) lo produce Encuentro Regla 5 (AC-K43/K44); resuelve OQ-5/OQ-7/OQ-8 |
| Sistema de Héroes → Permadeath | indirecto | Combate provee `D`/`P`; Héroes los reenvía en su payload de muerte a Permadeath. Combate no habla con Permadeath directamente |
| Temporizador de Preparación/Ritual | ninguna directa | Combate **no** lee ni computa `T`; se aclara aquí para evitar la conflación — `T` lo provee el Temporizador y lo lee Héroes |
| Datos de Era/Civilización | Datos → Combate | Los `CombatProfile` se autoran por tipo de unidad del roster de la era; Combate los consume vía las definiciones de unidad |

> **Nota de contrato desbloqueado**: esta sección resuelve el "contrato de contacto/aggro" que Tropas (AC-09/AC-11) y Héroes esperaban de este sistema — `ENGAGED` se dispara al entrar a `TARGET_ACQUIRED`/`ATTACKING`.

## Formulas

Combate resuelve daño con daño plano por golpe (sin armadura/mitigación en el MVP). Todas las unidades y el kaiju tienen un `CombatProfile`; las fórmulas convierten esos stats en tiempos de muerte legibles.

### CombatProfile por tipo (valores MVP, tuning knobs por tipo)

> **Capa de modificadores por instancia (ADR-0001, Accepted 2026-08-21).** El `CombatProfile` es **por tipo** e inmutable en runtime. Sobre él, Combate posee una capa **`CombatState` por instancia** (referencia solo-lectura al `CombatProfile` + lista de `StatModifier` planos aditivos). `apply_damage` lee el stat **efectivo** vía `effective_attack_damage()` (= base + Σ modificadores activos); Reliquias/Bendiciones deposita modificadores con `add_modifier`/`remove_by_source`. Combate barre los expirados con `sweep_expired(TimeControl.game_tick)` al inicio del tick, antes de la fase-1 de daño (Regla 1 intacta: toda la matemática de daño sigue dentro de Combate). Nunca se muta el `CombatProfile` compartido. Ver `docs/architecture/adr-0001-combat-stat-modifier-layer.md`.

| Unidad | `attack_damage` | `attack_range` (wu) | `attack_cooldown_s` | DPS | `aggro_range` (wu) | `leash_range` (wu) |
|---|---|---|---|---|---|---|
| melee_infantry (40 HP) | 8 | 1.0 | 1.0 | 8.00 | 5.0 | 8.0 |
| ranged_troop (20 HP) | 5 | 4.0 | 1.2 | 4.17 | 6.0 | 9.0 |
| support_troop (28 HP) | 4 | 2.5 | 1.5 | 2.67 | 5.0 | 8.0 |
| Vanguardia (140 HP, ofensivo) | 25 | 1.2 | 0.9 | 27.8 | 7.0 | 12.0 |
| Portaestandarte (150 HP, rally) | 14 | 1.2 | 1.1 | 12.7 | 5.5 | 8.0 |
| Guardián (200 HP, defensivo) | 18 | 1.3 | 1.4 | 12.9 | 5.0 | 6.0 |
| Kaiju (aprox.) | 45 | 2.5 | 4.5 | 10.0 | 10.0 | provisional* |

*Racional: tropas melee cambian rango por HP/daño; ranged cambia HP por alcance. Héroes son 3-18× más letales que tropas (fantasía: el héroe destroza masa — 2 golpes matan a un melee). Guardián tiene el leash más corto (aguanta la línea, no persigue — coherente con la vía defensiva de `P`); Vanguardia el más largo (skirmisher agresivo). *El leash del kaiju lo anula por completo Encuentro con Kaiju (Approved, Regla 2 — persecución ilimitada durante `CLIMAX`, el campo nunca se lee); el centinela `provisional*` refleja esa anulación, no un valor pendiente.*

### F1 — `apply_damage` / clamp

`health_after = clamp(health_before − attack_damage, 0, max_health)`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Vida antes | `health_before` | int | [0, max_health] | HP antes del golpe |
| Daño de ataque | `attack_damage` | int | ≥1 | Daño plano por golpe |
| Vida máxima | `max_health` | int | ≥1 | HP máximo de la unidad |
| **Vida después** | `health_after` | int | [0, max_health] | Resultado — clampeado, overkill descartado |

**Ejemplo**: `health_before=5`, `attack_damage=45` (kaiju), `max_health=40` → `clamp(5−45, 0, 40) = 0`.

### F2 — `kill_time_hits`

`kill_time_hits = ceil(defender_HP / attacker_damage)`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Vida del defensor | `defender_HP` | int | ≥1 | HP al iniciar el enganche |
| Daño del atacante | `attacker_damage` | int | ≥1 | `attack_damage` del atacante |
| **Golpes para matar** | `kill_time_hits` | int | ≥1 | Golpes requeridos (sin cota superior) |

**Ejemplo**: tropa melee (40 HP) vs melee (dmg 8) → `ceil(40/8) = 5` golpes.

### F3 — `time_to_kill_s`

`time_to_kill_s = kill_time_hits × attacker_cooldown_s`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Golpes para matar | `kill_time_hits` | int | ≥1 | De F2 |
| Cooldown del atacante | `attacker_cooldown_s` | float | >0 | `attack_cooldown_s` |
| **Tiempo para matar** | `time_to_kill_s` | float | ≥cooldown | Segundos de reloj hasta la muerte |

**Convención (confirmada — godot-specialist, ver Regla 1/Regla 3)**: el cooldown **no** está pre-cargado — el primer golpe cae tras un cooldown completo, no instantáneo al adquirir; se aplica como piso de adquisición sobre el tick de física (`_physics_process`), no sobre framerate variable. La lectura "listo-al-adquirir" restaría un cooldown a cada TTK. **Ejemplo**: 5 golpes × 1.0s = 5.0s.

### F4 — `dps`

`dps = attack_damage / attack_cooldown_s` (>0, sin cota superior). **Ejemplo**: kaiju 45/4.5 = 10.0.

### F5 — Invariante de rangos

`attack_range ≤ aggro_range ≤ leash_range`

Si `aggro_range < attack_range` hay una **zona muerta**: un enemigo entre ambos radios está en rango de golpe pero nunca se auto-adquiere. Si `leash_range < aggro_range`, una unidad que auto-adquiere no puede perseguir (vuelve al instante). Ambos casos → loud-fail al cargar.

**Excepción nombrada — Kaiju**: el `leash_range` del Kaiju es un valor centinela (`provisional*`, ver tabla `CombatProfile`) hasta que Encuentro con Kaiju defina su IA de persecución (OQ-7). Mientras ese campo permanezca marcado como centinela, F5 **no** evalúa el tramo `≤ leash_range` para el Kaiju — el loader lo excluye explícitamente de ese chequeo puntual, no como una omisión silenciosa sino como la única excepción nombrada a la regla de Enforcement. El tramo `attack_range ≤ aggro_range` del Kaiju sigue validándose con loud-fail normal. La excepción se retira en cuanto Encuentro con Kaiju asigne un `leash_range` real.

### Matriz de time-to-kill (segundos)

| Enfrentamiento | HP | dmg | cd | golpes | TTK |
|---|---|---|---|---|---|
| melee vs melee | 40 | 8 | 1.0 | 5 | **5.0s** |
| ranged vs ranged | 20 | 5 | 1.2 | 4 | **4.8s** |
| Vanguardia → tropa melee | 40 | 25 | 0.9 | 2 | **1.8s** |
| kaiju → tropa | 20-40 | 45 | 4.5 | 1 | **4.5s** (casi instantáneo, intencional) |
| kaiju → Vanguardia/Portaestandarte | 140/150 | 45 | 4.5 | 4 | **18.0s** |
| kaiju → Guardián | 200 | 45 | 4.5 | 5 | **22.5s** |

Los enfrentamientos son breves e intensos (Pilar 3) y legibles (kill_time es aritmética simple). El kaiju one-shotea tropas y tarda 4-5 golpes en un héroe.

### Enforcement (loud-fail, precedente de Héroes — no clamp)

Cada campo de `CombatProfile` fuera de su dominio válido **falla ruidosamente al cargar** (no se clampa) — cada caso es una fórmula rota, no un extremo válido:
- `attack_damage ≥ 1` (0 = objetivo inmatable)
- `attack_cooldown_s ≥ 0.1` (0 = DPS ÷0 / exploit de DPS infinito)
- invariante F5 `attack_range ≤ aggro_range ≤ leash_range` — **única excepción nombrada**: el tramo `≤ leash_range` del Kaiju queda exento mientras su `leash_range` sea el centinela `provisional*` (ver F5); la excepción se retira cuando Encuentro con Kaiju lo defina
- sin valores negativos

### Nota cross-GDD

Los baselines de HP de tropas (melee 40 = 2× ranged; support 28 = 1.4× ranged) **se sostienen** contra estos números — los mirror-matchups quedan a ~5s entre sí. **Se recomienda des-flaggear** la nota provisional de HP en Sistema de Tropas (no requiere revisión). Ver Phase 5 / Open Questions.

## Edge Cases

- **Config inválido de `CombatProfile`** (`attack_damage < 1`, `attack_cooldown_s < 0.1`, invariante F5 violado `attack_range ≤ aggro_range ≤ leash_range`, o cualquier negativo): **loud-fail al cargar** (no clamp) — cada caso es una fórmula rota (objetivo inmatable, DPS ÷0, zona muerta de aggro), no un extremo válido.
- **`apply_damage` sobre una unidad ya `DEAD`/`DYING`**: se rechaza (no-op) — no se puede dañar un cadáver ni re-disparar la muerte de un héroe ya en `DYING`. Coherente con Héroes AC-H27b (`DEAD` es inaccionable).
- **Sin fuego amigo en el MVP**: `apply_damage` solo se aplica entre facciones opuestas (jugador↔kaiju/esbirros). Una unidad nunca daña a una aliada; los ataques solo adquieren enemigos válidos.
- **Dos combatientes se matan en el mismo frame** (golpes letales simultáneos): ambos `apply_damage` se resuelven; ambos mueren. Si ambos son héroes, ambos entran a `DYING` y **Permadeath serializa los beats** (contrato de Héroes) — Combate solo aplica ambos daños, no ordena los beats.
- **El objetivo muere a mitad del cooldown del atacante**: el atacante vuelve a `NO_TARGET` (o auto-adquiere el siguiente enemigo en `aggro_range`), pero **su cooldown en curso sigue corriendo** — cambiar de objetivo **no** refresca un cooldown a medio cargar. Cierra el exploit de "reset de cooldown por target-switching".
- **El objetivo sale de `attack_range` a mitad del cooldown**: el atacante lo persigue (dentro de `leash_range`) y reanuda al reentrar en rango; el cooldown sigue corriendo. Si el objetivo escapa `leash_range`, el atacante vuelve a su posición de retención y a `NO_TARGET`.
- **Orden attack-target cuyo objetivo muere**: la orden se consume; la unidad revierte a auto-aggro (comportamiento idle). Una orden attack-move, en cambio, continúa hacia su destino auto-enganchando en el camino.
- **Un héroe muere sin comando Sacrificio ni objetivo/amenaza marcada** (`D=0, P=0`): Combate reporta `D=0, P=0`; la reliquia resultante es Tier 1 Delgada (válvula anti-nihilismo de Héroes). No es un bug — es el sistema funcionando; Combate solo reporta la clasificación, no la juzga.
- **El kaiju llega a 0 de vida** (daño unidad→kaiju): Combate aplica el daño y notifica que el kaiju cruzó 0, pero **no declara victoria** — la evaluación de fin de era la posee Encuentro con Kaiju / Transición de Era (Regla 9, mismo hueco que Tropas/Héroes).
- **Sin línea de visión en el MVP**: `attack_range` es distancia pura; no hay chequeo de line-of-sight (un ranged puede disparar "a través" de obstáculos). Simplificación deliberada del MVP por legibilidad; hook de LoS diferido (ver Open Questions).
- **Resolución de combate durante el beat `DEATH_HOLD`**: si el beat de muerte de héroe pausa el tiempo de juego (timing propiedad de Permadeath), los cooldowns de combate se pausan con él — Combate sigue la misma escala de tiempo de juego que el Temporizador (independiente de framerate/tiempo real). Si el beat no pausa el tiempo, el combate continúa. Contrato a confirmar con Permadeath.

## Dependencies

**Dependencias hacia arriba (upstream) — lo que este sistema necesita:**

| Sistema | Tipo | Interfaz | Estado |
|---|---|---|---|
| Sistema de Tropas | Dura (bidireccional) | Combate lee el `CombatProfile` de la tropa, aplica daño, notifica `ENGAGED`/fin-de-combate/`DEAD`. Tropas posee vida y estado | ✅ Diseñado — **resuelve Tropas AC-09/AC-11** (el contrato de contacto que esperaban) |
| Sistema de Héroes | Dura (bidireccional) | Igual que Tropas, y computa/expone `D`/`P` al `DYING` | ✅ Diseñado — **formaliza el contrato de clasificación `D`/`P`** que Héroes esperaba |
| Control y Selección de Unidades | Dura | Combate lee órdenes de ataque (attack-target/attack-move) y el estado del comando **Sacrificio** activo por héroe (para `D`) | ⚠️ **Parcial** — GDD existe para selección/movimiento, pero el comando Sacrificio y los verbos attack-target/attack-move **no están definidos aún** en su GDD; el lado `D` los necesita (ver OQ-2) |
| Datos de Era/Civilización | Blanda (datos) | Los `CombatProfile` se autoran por tipo de unidad del roster de la era; Combate los consume vía las definiciones | ✅ Diseñado |

**Dependientes hacia abajo (downstream — dependen de este):**

| Sistema | Tipo | Interfaz |
|---|---|---|
| Encuentro con Kaiju | Dura (bidireccional) | Combate aplica el daño kaiju↔unidad (autoridad centralizada); lee las defs de ataque del kaiju y el estado de marcado (para `P`). Kaiju posee su IA y el marcado. ✅ **Approved** — contrato real en `encuentro-con-kaiju.md` (Regla 3 selección de objetivo, Regla 5 marcado, Regla 9 victoria/derrota) |
| Permadeath | Dura (indirecto) | Recibe `D`/`P` a través del payload de muerte que Héroes le reenvía; Combate no habla con Permadeath directamente. *Sin GDD* |
| Reliquias/Bendiciones | Dura (API de modificadores, ADR-0001) | Combate posee una capa `CombatState` **por instancia** sobre el `CombatProfile` por tipo: expone `effective_attack_damage()` (read-hook leído internamente en `apply_damage`) y la API de escritura `add_modifier`/`remove_by_source`/`sweep_expired`. Reliquias deposita modificadores planos aditivos vía esa API y nunca escribe `CombatProfile`. Combate posee la aplicación y la expiración (`sweep_expired(TimeControl.game_tick)` al inicio del tick, antes de fase-1). ✅ Definido — `docs/architecture/adr-0001-combat-stat-modifier-layer.md` (Accepted) + `reliquias-bendiciones.md` |
| UI/HUD | Dura | Renderiza vida, feedback de daño y estado de combate desde lo que este sistema expone. *Sin GDD* |

**Nota cross-GDD (acción Phase 5)**: Combate confirma que los baselines de HP de tropas se sostienen — se recomienda **des-flaggear** la nota provisional de HP en `sistema-de-tropas.md` (Formulas y Open Questions). Se aplicará en la fase de registro.

**Nota (actualizada 2026-08-21)**: Encuentro con Kaiju, Permadeath, Reliquias/Bendiciones y UI/HUD **ya tienen GDD**; sus contratos con este sistema están confirmados. Los dos que tocan a Combate a nivel de arquitectura están cerrados por ADRs Accepted: la capa de modificadores por instancia (Reliquias) por **ADR-0001**, y la fuente de `game_time_paused`/tick por **ADR-0002** (servicio TimeControl). Tropas, Héroes, Control y Datos de Era ya estaban confirmados.

## Tuning Knobs

Los knobs de este sistema son los cinco campos del `CombatProfile`, **por tipo de unidad** (viven en cada Resource, como los stats de Tropas — son contenido, no sliders globales). Valores por defecto en la tabla de Formulas.

| Knob | Tipo | Rango seguro | Qué se rompe en extremos |
|---|---|---|---|
| `attack_damage` | int (por tipo) | ≥ 1 | <1: objetivo inmatable (**loud-fail**); demasiado alto: one-shots que rompen la legibilidad de `kill_time` y el "breve pero con tensión" del Pilar 3 |
| `attack_cooldown_s` | float (por tipo) | ≥ 0.1 | <0.1: DPS ÷0 / DPS efectivamente infinito (**loud-fail**); demasiado alto: el combate se arrastra, pierde el "intenso" del Pilar 3 |
| `attack_range` | float wu (por tipo) | >0, ≤ `aggro_range` | demasiado corto: melee nunca alcanza; demasiado largo: ranged dispara desde fuera de pantalla, ilegible |
| `aggro_range` | float wu (por tipo) | `attack_range` ≤ x ≤ `leash_range` | < `attack_range`: zona muerta de aggro (**loud-fail**, F5); demasiado grande: las unidades enganchan todo el mapa, caos ingobernable |
| `leash_range` | float wu (por tipo) | ≥ `aggro_range` | < `aggro_range`: no puede perseguir lo que adquiere (**loud-fail**, F5); demasiado grande: las unidades se alejan persiguiendo y la formación se dispersa |

**Interacción entre knobs**: los tres rangos están acoplados por el invariante F5 (`attack_range ≤ aggro_range ≤ leash_range`). `kill_time` depende de `attack_damage` contra el HP del objetivo (que poseen Tropas/Héroes) — cambiar HP en esos GDDs re-balancea el combate aquí; coordinar cambios cross-GDD. El Kaiju es la única excepción nombrada al acoplamiento — su `leash_range` queda exento de F5 mientras sea el centinela `provisional*` (ver Formulas F5, OQ-7).

**Enforcement**: **loud-fail al cargar** para todos los casos fuera de dominio (precedente de Héroes; no clamp) — ver la sección Enforcement de Formulas. Cada violación es una fórmula rota, no un extremo de feel.

**Constantes consumidas (no se duplican)**: HP de unidades (`melee_infantry`=40, `ranged_troop`=20, `support_troop`=28, héroes 120-200 — de Tropas/Héroes); `sacrifice_radius`=3.0 y `guard_radius`=4.0 (de Héroes, aplicados por Combate en la clasificación `D`/`P`).

## Visual/Audio Requirements

*Referencia rectora: Art Bible Secciones 2.2 (Clímax de Combate), 2.3 (Muerte/Sacrificio), 3.4 (jerarquía visual del ojo), 4.2 (uso semántico del color), 5.4/8.4 (niveles de LOD), 7.0/7.5 (UI diegética). Audio es un **contrato provisional** — mismo estatus que Héroes A-1..A-3 y Temporizador — sin audio bible ni dirección de audio aún.*

### Visual

**CV-1 — Hit feedback en la silueta, no en overlay (art bible 4.2).** Cada golpe dispara un destello breve de un frame sobre la propia silueta del objetivo, reutilizando el drenaje Hueso→Sangre Vieja (4.2) ya usado en las barras de vida — el sprite mismo "sangra" el mismo lenguaje de color que su barra. Sin flash blanco genérico ni números de daño flotantes: a escala 24-32px con muchas unidades trocando golpes, ese ruido rompería la legibilidad justo cuando más se necesita.

**CV-2 — Muerte de tropa: LOD-1, sin beat (art bible 5.4, 8.4; Pilar 1).** `DEAD` dispara la animación de caída/disolución de Nivel 1 ya incluida en el set base de toda tropa (8.4) — dura lo mismo que cualquier transición de estado, sin pausa de cámara, sin luz dedicada, sin desaturación. Deliberado, no recorte: Combate no captura circunstancia de muerte de tropa (Regla 7), así que no hay dato que un tratamiento sostenido pudiera mostrar. Cualquier VFX futuro que le dé pausa/cámara-lenta a una muerte de tropa se rechaza en review — es el fallo exacto que el Pilar 1 prohíbe.

**CV-3 — Muerte de héroe: Combate dispara el cruce, no escenifica el beat (Héroes V-5/V-6, art bible 2.3).** Al cruzar 0, Combate notifica `DYING` — ahí termina su responsabilidad visual. La puesta en escena sostenida (luz clave, desaturación circundante, silueta agrietándose en vitral) es de Permadeath. Lo único que Combate garantiza: el estado de enganche del héroe se congela con él en ese frame — ningún atacante/objetivo sigue animando un intercambio contra una unidad ya en `DYING`.

**CV-4 — Golpe de kaiju: contraste brutal y telegrafiado (Principio B, art bible 2.2, 9.5/9.6).** El impacto nunca suaviza la desproporción de escala para "encajar" visualmente. Con `attack_cooldown_s`=4.5s el ataque debe telegrafiarse antes de caer (fisuras/espinas iluminándose) — el jugador lee "esto va a golpear" con tiempo de reacción; la tragedia es de decisión, no de sorpresa.

**CV-5 — Legibilidad de clash y su límite con UI/HUD (art bible 3.4, 7.5).** Quién gana un choque se lee por la jerarquía de forma (kaiju>héroe>masa) y por CV-1, no por barras flotantes constantes. **Límite**: Combate expone el dato (vida, estado de enganche) y el feedback en la silueta; cómo/cuándo UI/HUD superpone barras diegéticas (siempre vs. solo bajo umbral, 7.5) es responsabilidad de UI/HUD.

### Audio *(provisional)*

**CA-1 — Impacto melee vs ranged distinto.** Percusivo-cercano vs. ligero-a-distancia, reforzando `attack_range` sin mirar el sprite; el golpe de kaiju es categóricamente más grave/grande, reforzando CV-4.

**CA-2 — Muerte de tropa tenue, masa en clashes.** Tenue individualmente, se vuelve masa/textura en clashes con muertes simultáneas (espejo de Tropas) — nunca compite con CA-3.

**CA-3 — Muerte de héroe es handoff, no verbo propio de Combate.** Al notificar `DYING`, el audio pasa a Permadeath (Héroes A-1/A-2 — filtrado del lecho, understatement, silencio permitido). Combate solo garantiza que su propio lecho de combate se ducke primero al dispararse el beat.

**Principios rectores**: A (art bible 4.2, drenaje de color — nunca dorado en combate rutinario), B (2.2/3.4/9.5-9.6, escala del kaiju), C (2.3, el beat que Combate dispara pero no escenifica), 5.4/8.4 (LOD-1 rutinario, LOD-2 exclusivo de permadeath), 7.0/7.5 (frontera con UI/HUD).

📌 **Asset Spec** — Con Visual/Audio definido, tras aprobar el art bible se puede correr `/asset-spec system:combate-dano` para producir specs de VFX por-asset (hit flash, muerte de tropa, telegrafío de kaiju).

## UI Requirements

*Combate no diseña pantallas — expone datos que UI/HUD renderiza con el lenguaje diegético del art bible (Sección 7). Esta sección fija el contrato de qué datos fluyen, no cómo se ven.*

**CU-1 — Exposición de estado por unidad para UI/HUD.** Combate expone, por unidad: `current_health`/`max_health`, el estado de enganche (`NO_TARGET`/`TARGET_ACQUIRED`/`ATTACKING`) y los eventos de daño. UI/HUD consume esto para renderizar barras de vida (drenaje Hueso→Sangre Vieja, art bible 4.2) e indicadores de combate. El *cuándo* mostrar barras (siempre vs. bajo umbral) lo decide UI/HUD (art bible 7.5).

**CU-2 — Evento de golpe/impacto.** Cada resolución de golpe emite un evento que UI/HUD y VFX enganchan para el hit feedback (CV-1). Combate provee el disparador (quién golpeó a quién, cuánto), no el render.

**CU-3 — Tasa de daño entrante (para estimaciones downstream).** Combate expone el daño entrante reciente por unidad. Esto es un **insumo** que Encuentro con Kaiju puede usar para su proyección de `time_to_death` (el trigger del readout de veredicto de Héroes U-3/AC-H29) — pero la proyección misma la posee Kaiju, no Combate (ver la tensión de la ventana de ~30s en Open Questions). Combate solo provee el dato crudo.

**CU-4 — Sin editorializar el resultado de combate.** Coherente con el understatement del juego: Combate no expone texto de "¡Victoria!"/"¡Baja!" ni juicios — solo estado numérico y eventos. La lectura del choque es visual (CV-5), no textual.

📌 **UX Flag — Combate/Daño**: Este sistema alimenta UI de combate (barras de vida, feedback de daño, estado de enganche). En Pre-Producción, correr `/ux-design` para el HUD de combate **antes** de escribir epics; las stories que referencien esa UI deben citar el spec de UX, no este GDD.

## Acceptance Criteria

*Convención: cada AC usa formato Dado/Cuando/Entonces y una etiqueta de tipo de evidencia (`[Logic/unit]`, `[Integration]`). Los AC marcados **(bloqueado)** dependen de un sistema — o de una porción no escrita de un sistema — sin contrato confirmado hoy; solo verificables mediante un mock en el límite de este sistema. Salvo indicación, los valores de ejemplo usan la tabla `CombatProfile` MVP (Formulas). (La numeración salta C15 y C49 — entradas reservadas eliminadas.)*

### A. Reglas Core (1-9)

**AC-C01 — Autoridad única de daño** **[Logic/unit]**
Dado cualquier fuente de daño (unidad↔unidad, kaiju↔unidad), cuando se resuelve un golpe, entonces la única vía por la que `health_current` decrece es `apply_damage(target, amount, source)` — no existe otro camino de código que mute la vida directamente.

**AC-C02 — Clamp de `apply_damage` a `[0, max_health]`** **[Logic/unit]**
Dado `apply_damage` con cualquier `amount ≥ 1`, cuando `health_before − amount` cae fuera de `[0, max_health]`, entonces `health_after` se clampa estrictamente a ese rango — nunca negativo.

**AC-C03 — `CombatProfile` data-driven, sin hardcode** **[Logic/unit]**
Dado un `CombatProfile` poblado para tropa, héroe o kaiju, cuando Combate resuelve un golpe o adquisición para esa unidad, entonces usa exclusivamente esos valores del resource — cambiar el `.tres` cambia el comportamiento sin tocar código. El kaiju usa el mismo ciclo de enganche (solo su selección de objetivo la dirige la IA de Kaiju).

**AC-C04 — Ataque por cooldown: golpe al expirar, reset** **[Logic/unit]**
Dado un atacante con objetivo válido dentro de `attack_range` y cooldown listo, cuando se procesa el tick de combate, entonces se invoca `apply_damage` con `attack_damage` y el cooldown se reinicia a `attack_cooldown_s`.

**AC-C05 — Cooldown no precargado al adquirir (convención F3, piso de adquisición)** **[Logic/unit]**
Dado un atacante que acaba de adquirir un objetivo, cuando pasa el primer tick con el objetivo en rango, entonces el primer golpe NO cae instantáneamente — transcurre un `attack_cooldown_s` completo antes del primer `apply_damage`. Esto se cumple **incluso si el atacante traía un cooldown heredado ya en 0** desde un objetivo anterior (piso de adquisición, Regla 3) — adquirir nunca produce un golpe instantáneo, sin importar el estado del cooldown heredado.

**AC-C06 — Auto-aggro: adquiere el enemigo válido más cercano en `aggro_range`** **[Logic/unit]**
Dado una unidad sin orden explícita y ≥1 enemigo válido dentro de `aggro_range`, cuando se evalúa la adquisición, entonces se selecciona el más cercano — no el primero detectado ni uno aleatorio.

**AC-C07 — Leash: retorno a retención si el objetivo escapa `leash_range`** **[Logic/unit]**
Dado una unidad persiguiendo un objetivo auto-adquirido, cuando la distancia a su posición de retención excede `leash_range`, entonces abandona la persecución, vuelve a retener y transiciona a `NO_TARGET`.

**AC-C07b — Posición de retención se fija en la adquisición, se re-fija en cada re-adquisición** **[Logic/unit]**
Dado una unidad que adquiere un objetivo A en la posición X, cuando la unidad se desplaza persiguiendo a A, entonces su posición de retención permanece fija en X (no sigue al atacante); dado que la unidad mata a A y auto-adquiere un objetivo B en la posición Y, cuando comienza la persecución de B, entonces la posición de retención se re-fija a Y.

**AC-C08 — Orden explícita sobreescribe auto-aggro** **[Integration]**
Dado una unidad con un enemigo auto-adquirido, cuando Control emite attack-target sobre otro enemigo, entonces la unidad abandona el auto-adquirido y persigue/ataca el ordenado hasta que muere, sale de rango o se reordena.

**AC-C09 — attack-move auto-engancha en el trayecto** **[Integration]**
Dado una unidad con orden attack-move hacia un destino, cuando un enemigo entra en su `aggro_range`, entonces se engancha automáticamente sin abandonar la intención de attack-move (reanuda hacia el destino tras resolver/perder el enganche).

**AC-C10 — Daño plano, sin armadura** **[Logic/unit]**
Dado un defensor con `health_current=H` y un atacante con `attack_damage=D`, cuando se aplica un golpe, entonces `health_current` decrece exactamente en `D`, sin mitigación ni multiplicador, sin importar el tipo de defensor.

**AC-C11 — `ENGAGED`/`ALIVE_ENGAGED` notificado al adquirir; Combate no posee el estado** **[Integration]**
Dado una unidad que transiciona a `TARGET_ACQUIRED`/`ATTACKING`, cuando ocurre la transición, entonces Combate invoca únicamente el método de notificación del sistema dueño (Tropas/Héroes) — nunca escribe directamente el campo de estado de vida.

**AC-C12 — Fin de combate notificado sin objetivo de reemplazo** **[Integration]**
Dado una unidad en combate cuyo objetivo muere o sale de `leash_range`, cuando no hay otro enemigo válido en `aggro_range`, entonces Combate notifica fin de combate y la unidad vuelve a `NO_TARGET`.

**AC-C13 — Muerte de tropa: `DEAD` sin datos de circunstancia** **[Logic/unit]**
Dado una tropa cuya vida cruza 0, cuando `apply_damage` clampa a 0, entonces transiciona a `DEAD` y Combate no captura ni expone `killer_id`, ubicación, timestamp ni causa — ningún campo de circunstancia existe.

**AC-C14 — Muerte de héroe: `DYING` + D/P computados y congelados en el mismo frame** **[Logic/unit]**
Dado un héroe cuya vida cruza 0 con entradas mockeadas arbitrarias de comando/marcado, cuando `apply_damage` clampa a 0, entonces transiciona a `DYING` y Combate computa `D`/`P` en ese mismo frame, congelándolos — no se releen en frames posteriores. (Verifica el snapshot-timing; la corrección de la clasificación está en el Grupo C.)

**AC-C16 — Combate no evalúa victoria/derrota** **[Logic/unit]**
Dado el kaiju u otra unidad llegando a 0, cuando Combate procesa la muerte, entonces no emite ninguna señal ni llamada de evaluación de victoria/derrota — solo notifica la muerte individual.

### B. Fórmulas (F1-F5)

**AC-C17 — F1 exacto con overkill del kaiju** **[Logic/unit]**
Dado `health_before=5`, `attack_damage=45`, `max_health=40`, cuando se aplica `apply_damage`, entonces `health_after=0` exactamente.

**AC-C18 — F1 invariante general** **[Logic/unit]**
Dado cualquier `health_before ∈ [0,max_health]` y `attack_damage ≥ 1` válidos, cuando se aplica `apply_damage`, entonces `health_after` siempre cae en `[0, max_health]`.

**AC-C19 — F2 exacto: melee vs melee → 5 golpes** **[Logic/unit]**
Dado `defender_HP=40`, `attacker_damage=8`, cuando se calcula `kill_time_hits`, entonces el resultado es exactamente `5`.

**AC-C20 — F2 redondea hacia arriba en división no exacta** **[Logic/unit]**
Dado `defender_HP=41`, `attacker_damage=8`, cuando se calcula `kill_time_hits`, entonces el resultado es `6`, nunca `5`.

**AC-C21 — F3 exacto: TTK melee vs melee** **[Logic/unit]**
Dado `kill_time_hits=5`, `attacker_cooldown_s=1.0`, cuando se calcula `time_to_kill_s`, entonces el resultado es exactamente `5.0s`.

**AC-C22 — F3 exacto: el kaiju one-shotea una tropa** **[Logic/unit]**
Dado `defender_HP=40` y el kaiju (`dmg=45, cd=4.5`), cuando se calculan F2/F3, entonces `kill_time_hits=1` y `time_to_kill_s=4.5s`.

**AC-C23 — F3 exacto: matriz kaiju vs héroes** **[Logic/unit]**
Dado el kaiju contra `defender_HP=140/150` y `200`, cuando se calculan F2/F3, entonces `4 golpes / 18.0s` para 140 y 150 HP, y `5 golpes / 22.5s` para 200 HP.

**AC-C24 — F4 exacto: DPS del kaiju** **[Logic/unit]**
Dado `attack_damage=45`, `attack_cooldown_s=4.5`, cuando se calcula `dps`, entonces el resultado es exactamente `10.0`.

**AC-C25 — F5 invariante válido carga sin error** **[Logic/unit]**
Dado un `CombatProfile` con `attack_range=1.0 ≤ aggro_range=5.0 ≤ leash_range=8.0`, cuando se carga, entonces la carga se completa sin error.

**AC-C26 — F5 loud-fail: zona muerta (`aggro_range < attack_range`)** **[Logic/unit]**
Dado un `CombatProfile` con `aggro_range < attack_range`, cuando se carga, entonces falla ruidosamente.

**AC-C27 — F5 loud-fail: `leash_range < aggro_range`** **[Logic/unit]**
Dado un `CombatProfile` con `leash_range < aggro_range`, cuando se carga, entonces falla ruidosamente.

**AC-C27b — F5 excepción nombrada: Kaiju con `leash_range` centinela carga sin error** **[Logic/unit]**
Dado el `CombatProfile` del Kaiju con `leash_range` marcado como el centinela `provisional*` y `attack_range ≤ aggro_range` válido, cuando se carga, entonces la carga se completa sin error — el tramo `≤ leash_range` del invariante F5 no se evalúa para este campo mientras sea centinela. Dado el mismo `CombatProfile` pero con `attack_range > aggro_range` (violación del tramo no exento), cuando se carga, entonces sigue fallando ruidosamente — la excepción cubre únicamente `leash_range`.

### C. Clasificación D/P (Regla 8) — el contrato más intrincado del sistema

*Nota: la tabla de Dependencias marca Control "✅ Diseñado", pero `control-y-seleccion-de-unidades.md` no define hoy el comando Sacrificio, su confirm-step, ni attack-target/attack-move como verbos distintos. Por eso los AC del lado `D` se tratan como **(bloqueado)**, igual que el lado `P` (Kaiju, sin GDD). Ver Open Questions OQ-2.*

**AC-C28 — `D=1` sii las tres condiciones se cumplen** **(bloqueado — comando Sacrificio no definido en Control; ver OQ-2)** **[Logic/unit]**
*Mock Contract Assumptions: el mock de Control expone `sacrifice_command_active(hero_id) -> bool`, `sacrifice_command_destination(hero_id) -> Vector2`, y garantiza que el confirm-step ya se resolvió antes de marcar `active=true`. Re-verificar contra el GDD real cuando Control defina el comando.*
Dado un héroe con comando Sacrificio activo hacia destino X, cuando muere con el comando aún activo y dentro de `sacrifice_radius` de X, entonces `D=1`; si cualquiera de las tres condiciones falla, entonces `D=0`.

**AC-C29 — `D=1` tolera knockback dentro del radio** **(bloqueado — mismo mock que AC-C28)** **[Logic/unit]**
Dado un héroe con Sacrificio activo hacia X, cuando un knockback lo desplaza del punto exacto pero muere dentro de `sacrifice_radius` de X, entonces `D=1`.

**AC-C30 — `D=0` si el comando se cancela antes del frame de muerte** **(bloqueado)** **[Logic/unit]**
Dado un héroe cuyo comando Sacrificio se cancela en el frame N, cuando muere en el frame N+k (k>0), entonces `D=0` — se lee el estado del frame de cruce.

**AC-C31 — `D=0` si el confirm-step no se completó** **(bloqueado)** **[Logic/unit]**
Dado un tap sin confirmar sobre Sacrificio (el mock nunca marca `active=true`), cuando el héroe muere, entonces `D=0`.

**AC-C32 — `P=1` vía defensiva: muerte dentro de `guard_radius` de objetivo marcado** **(desbloqueado — Encuentro con Kaiju Approved)** **[Integration]**
*Contrato real (ya no mock): Encuentro con Kaiju expone `marked_targets`/`marked_threats` al entrar a `TELEGRAPHING` (Regla 5, AC-K43); `guard_radius=4.0` lo posee Héroes (Approved). Verificable sin mock contra ambos contratos reales, mismo patrón que AC-C50.*
Dado un objetivo/aliado marcado en posición Y (vía Encuentro Regla 5/AC-K43), cuando un héroe muere dentro de `guard_radius` de Y, entonces `P=1`.

**AC-C33 — `P=1` vía ofensiva: neutralizar amenaza marcada** **(desbloqueado — Encuentro con Kaiju Approved)** **[Integration]**
*Contrato real: la amenaza marcada (`marked_threat`) y su neutralización las define Encuentro Regla 5/Regla 7 (AC-K44); el crédito en mutual-kill lo cubre AC-C42/Encuentro AC-K38.*
Dado una amenaza crítica marcada del kaiju (Encuentro Regla 5/AC-K44), cuando el héroe muere en la misma acción que la neutraliza, entonces `P=1` — mismo peso que la vía defensiva (nota de simetría H4).

**AC-C34 — `P=0` si ninguna vía se cumple** **(desbloqueado — Encuentro con Kaiju Approved)** **[Logic/unit]**
Dado un héroe que muere sin estar en `guard_radius` de ningún marcado y sin neutralizar ninguna amenaza marcada (ambas vías definidas por Encuentro Regla 5), cuando se computa `P`, entonces `P=0`.

**AC-C35 — Combate es clasificador puro (arquitectura)** **(parcial — lado Kaiju Approved; lado Control aún bloqueado por el comando Sacrificio no escrito, OQ-2)** **[Integration]**
Dado el cómputo de D/P en el frame de muerte, cuando se inspecciona qué estado escribe Combate, entonces Combate solo LEE los getters documentados de Control/Kaiju — nunca emite un comando Sacrificio, nunca marca un objetivo/amenaza, y no cachea D/P entre frames.

**AC-C36 — Combate no computa `T`** **[Logic/unit]**
Dado el payload de muerte de un héroe, cuando Combate expone D y P, entonces el payload NO incluye ningún campo `T`/`kaiju_timer_remaining_ratio` — ese input lo provee el Temporizador y lo lee Héroes.

### D. Edge Cases

**AC-C37 — Loud-fail: `attack_damage < 1`** **[Logic/unit]**
Dado un `CombatProfile` con `attack_damage=0` o negativo, cuando carga, entonces falla ruidosamente.

**AC-C38 — Loud-fail: `attack_cooldown_s < 0.1`** **[Logic/unit]**
Dado un `CombatProfile` con `attack_cooldown_s < 0.1`, cuando carga, entonces falla ruidosamente (evita DPS ÷0).

**AC-C39 — Loud-fail: valores negativos en cualquier campo** **[Logic/unit]**
Dado un `CombatProfile` con cualquier campo negativo, cuando carga, entonces falla ruidosamente sin excepción.

**AC-C40 — `apply_damage` rechazado sobre `DEAD`/`DYING`** **[Logic/unit]**
Dado una unidad en `DEAD` o un héroe en `DYING`, cuando se invoca `apply_damage` sobre ella, entonces es no-op — no decrece vida ni re-dispara notificación de muerte.

**AC-C41 — Sin fuego amigo** **[Logic/unit]**
Dado dos unidades de la misma facción, cuando una intenta atacar a la otra, entonces `apply_damage` se rechaza — solo entre facciones opuestas.

**AC-C42 — Mutual kill simultáneo** **(mitad final bloqueada — serialización de beats de Permadeath)** **[Integration]**
Dado dos combatientes cuyos golpes letales se resuelven en el mismo frame, cuando ambos `apply_damage` se procesan, entonces ambos mueren — si ambos son héroes, ambos entran a `DYING` y Combate solo aplica ambos daños; la serialización de beats es de Permadeath (ver AC-C52 y Héroes AC-H25).

**AC-C43 — Cooldown persiste tras target-switch (anti-exploit)** **[Logic/unit]**
Dado un atacante con cooldown a medio cargar cuyo objetivo muere o se reordena, cuando adquiere un nuevo objetivo, entonces el cooldown en curso sigue corriendo — cambiar de objetivo nunca lo resetea.

**AC-C43b — Piso de adquisición cierra el exploit de banking de cooldown** **[Logic/unit]**
Dado un atacante cuyo cooldown heredado llega a 0 mientras está en `NO_TARGET` (sin objetivo), cuando adquiere un nuevo objetivo, entonces el primer golpe NO cae instantáneamente — se aplica el piso de adquisición completo (`attack_cooldown_s` desde la adquisición, Regla 3/AC-C05) sin importar que el cooldown heredado ya estuviera en 0. Cierra el exploit de "esperar en `NO_TARGET` hasta que expire el cooldown, luego adquirir para un golpe gratis".

**AC-C44 — Objetivo sale de `attack_range` a mitad de cooldown: persigue, cooldown no se resetea** **[Logic/unit]**
Dado un atacante en `ATTACKING` cuyo objetivo sale de `attack_range`, cuando lo persigue dentro de `leash_range` y reentra, entonces reanuda con el mismo cooldown en curso; si el objetivo escapa `leash_range`, vuelve a retención y a `NO_TARGET`.

**AC-C45 — Orden attack-target cuyo objetivo muere: se consume, revierte a auto-aggro** **[Integration]**
Dado una unidad con orden attack-target activa cuyo objetivo muere, cuando se procesa la muerte, entonces la orden se consume y la unidad revierte a auto-aggro — a diferencia de attack-move, que continúa hacia su destino.

**AC-C46 — `D=0, P=0` se reporta sin juzgar** **[Logic/unit]**
Dado un héroe que muere sin comando Sacrificio ni marcado, cuando Combate computa la clasificación, entonces reporta `D=0, P=0` sin evaluarlo (el Tier 1 resultante es de H4 de Héroes, no de este sistema).

**AC-C47 — El kaiju llegando a 0 no declara victoria** **[Logic/unit]**
Dado el kaiju cuya vida cruza 0, cuando Combate procesa la muerte, entonces notifica el cruce pero no declara victoria ni emite señal de fin de era.

**AC-C48 — Sin line-of-sight en el MVP** **[Logic/unit]**
Dado un atacante ranged con un enemigo dentro de `attack_range` pero detrás de un obstáculo, cuando se evalúa si puede atacar, entonces sí puede — `attack_range` es distancia pura, sin LoS en el MVP.

**AC-C52 — Cooldowns siguen la escala de tiempo de juego (pausa durante `DEATH_HOLD`)** **(desbloqueado — ADR-0002, Accepted 2026-08-21)** **[Integration]**
*Contrato real (ADR-0002): el dueño del flag es el servicio Core **TimeControl**, no Permadeath. Permadeath solicita el régimen `PAUSED`; Combate lee `TimeControl.game_time_paused` (y en general avanza sus cooldowns por `TimeControl.game_tick`/`time_scale`), no lo decide.*
Dado un beat `DYING` con `TimeControl.game_time_paused=true`, cuando transcurre tiempo real, entonces ningún cooldown de combate avanza; si `game_time_paused=false`, los cooldowns continúan a `time_scale` (normal o `SLOWED` bajo una oferta de Reliquias).

### E. Cross-system: el hand-off D/P a Héroes

**AC-C50 — Hand-off D/P en el frame de cruce es testeable HOY (Héroes ya diseñado)** **[Integration]**
Dado D/P como valores boolean opacos provistos por Combate (sin importar su fuente — separado del Grupo C, que sí está bloqueado), cuando un héroe cruza 0, entonces Héroes los recibe en ese mismo frame y los usa junto con `T` (leído del Temporizador) para calcular `relic_quality` — mismo patrón de cross-check que AC-T12, sin mock porque el lado receptor (Héroes) ya está Approved. La corrección de D/P en sí sigue bloqueada (AC-C28–C35).

**AC-C51 — CU-3: tasa de daño entrante cruda, sin proyección** **[Logic/unit]**
Dado una unidad que recibe golpes en una ventana reciente, cuando se consulta la tasa de daño entrante que Combate expone (CU-3), entonces el valor refleja el daño real aplicado — Combate expone el dato crudo; NO computa `time_to_death` (eso es de Encuentro con Kaiju; la tensión de la ventana de ~30s es un contrato conjunto Kaiju/Héroes).

**AC-C-NEG — Control negativo Pilar 1: tropa sin datos vs. héroe con D/P, en la misma corrida** **[Logic/unit]** — **BLOQUEANTE, crítico de Pilar 1 (mirror de Tropas AC-06)**
Dado, en la misma corrida de test: (a) una tropa que cruza 0 sin comando/marcado, y (b) un héroe que cruza 0 en condiciones equivalentes mockeadas; cuando ambas transiciones se procesan, entonces (a) la tropa transiciona a `DEAD` sin ningún campo D/P/circunstancia, mientras que (b) el héroe transiciona a `DYING` y Combate SÍ computa y expone D/P (aunque resulten `D=0, P=0`) — probando que la distinción de la Regla 7 se hace cumplir activamente en el mismo binario, no por omisión. *Test de regresión: un refactor que fusione los caminos de muerte tropa/héroe es la forma más plausible de romper el Pilar 1, y ese riesgo vive en `apply_damage`.*

### Clasificación de tipo de story (para el gate de evidencia)

| AC # | Tipo | Evidencia requerida | Nivel de gate |
|---|---|---|---|
| AC-C01–C07, C07b, C10, C13, C14, C16, C17–C27, C27b | Logic | Unit test (`tests/unit/combat/`) | Bloqueante |
| AC-C08, C09, C11, C12 | Integration | Integration test | Bloqueante |
| AC-C28–C34 | Logic (bloqueado) | Unit test con mock de contrato | Bloqueante (hoy solo vía mock) |
| AC-C35, C52 | Integration (bloqueado) | Integration test con mock (Control+Kaiju / Permadeath) | Bloqueante (hoy solo vía mock) |
| AC-C36–C41, C43, C43b, C44, C46–C48, C51 | Logic | Unit test | Bloqueante |
| AC-C42, C45 | Integration | Integration test (C42 mitad bloqueada) | Bloqueante |
| AC-C50 | Integration | Integration test (Héroes ya diseñado, sin mock) | Bloqueante |
| AC-C-NEG | Logic | Unit test — **excepción de gating**: bloqueante/crítico de Pilar 1, debe correr en cualquier PR que toque `apply_damage` o los caminos de muerte | Bloqueante |

### Huecos/bloqueados marcados (no diferidos silenciosamente)

1. **AC-C28–C31, C35 (lado D)** — dependen de que `control-y-seleccion-de-unidades.md` defina el comando Sacrificio (verbo, confirm-step, estado activo/cancelado). Control tiene GDD pero esa porción no está escrita. Ver OQ-2.
2. **AC-C32–C34 (lado P)** — ✅ desbloqueados: Encuentro con Kaiju Approved (`encuentro-con-kaiju.md`) define el marcado (Regla 5/AC-K43/K44); verificables sin mock contra el contrato real. **AC-C35 (lado P)** desbloqueado; su lado D sigue dependiendo del comando Sacrificio de Control (OQ-2).
3. **AC-C42 (mitad final), C52** — dependen de Permadeath (sin GDD): serialización de beats simultáneos y pausa de cooldowns durante `DEATH_HOLD` (mismo hueco que Héroes AC-H11/AC-H25).
4. **AC-C51 / CU-3** — Combate expone la tasa cruda; la ventana de ~30s sigue siendo un contrato conjunto Kaiju/Héroes (ver Héroes AC-H29 y Open Questions).

## Open Questions

| # | Pregunta | Owner | Resolución objetivo |
|---|---|---|---|
| OQ-1 | Dónde se almacena el `CombatProfile` — embebido en `TroopDefinition`/`HeroDefinition` vs. resource paralelo referenciado. Decisión de arquitectura, no de diseño. **Nota (2026-08-21):** distinta de la capa de modificadores **por instancia** (`CombatState`), que ya la resolvió ADR-0001 (Accepted); OQ-1 es solo sobre dónde vive el `CombatProfile` **por tipo**. Sigue abierta | technical-director | ADR antes de implementar Combate |
| OQ-2 | El **comando Sacrificio** (verbo + confirm-step) y los verbos **attack-target/attack-move** no están definidos en `control-y-seleccion-de-unidades.md`. El lado `D` de la clasificación (AC-C28–C31) los necesita. ¿Se añaden a Control/órdenes o se especifican aquí? Alinear con Héroes OQ-2 | game-designer | Al revisar Control o al diseñar el sistema de órdenes |
| OQ-3 | ~~Convención de cooldown: el primer golpe cae tras un cooldown completo (F3, actual) vs. "listo-al-adquirir". Afecta cada TTK en un cooldown~~ ✅ **RESUELTO 2026-08-09**: confirmado por godot-specialist en `/design-review` — no precargado (F3), combate resuelto en `_physics_process` con resolución en dos fases (Regla 1) y piso de adquisición (Regla 3/AC-C05/AC-C43b) para cerrar el exploit de banking de cooldown | godot-specialist | ✅ Cerrado |
| OQ-4 | ✅ **RESUELTO 2026-08-21 (ADR-0002, Accepted).** El beat `DEATH_HOLD` pausa el tiempo de juego vía el servicio Core TimeControl: Permadeath solicita `PAUSED`, Combate lee `TimeControl.game_time_paused` y sus cooldowns se congelan (AC-C52). | — | Cerrado |
| OQ-5 | ~~**Tensión de la ventana de ~30s**: el kaiju mata a un héroe en 18–22.5s, menos que los ~30s que exige Héroes AC-H29~~ ✅ **RESUELTO 2026-08-12**: Encuentro con Kaiju (Approved) define `time_to_death = telegraph_duration_s + kill_time_hits×attack_cooldown_s` (F2) — proyección pre-contacto desde el inicio del telegrafío, no desde el primer golpe. Con `telegraph_duration_s=14.0` da 32.0s (Vanguardia) / 36.5s (Guardián), sostiene AC-H29 sin tocar el daño del kaiju | systems-designer / game-designer | ✅ Cerrado (Encuentro F2/AC-K19–K22) |
| OQ-6 | Armadura/mitigación y line-of-sight son hooks post-MVP (el MVP usa daño plano y sin LoS por legibilidad). Revisitar si el daño plano se siente demasiado swingy o si ranged sin LoS se siente mal | systems-designer | Playtest del MVP |
| OQ-7 | ~~El `leash_range` del kaiju es un valor centinela — la IA de Encuentro con Kaiju gobierna la persecución y puede sobreescribir ese campo~~ ✅ **RESUELTO 2026-08-12**: Encuentro con Kaiju (Approved) Regla 2 **anula el campo por completo** (persecución ilimitada durante `CLIMAX`, nunca se lee — AC-K05a/b). La exención de F5 deja de ser "mientras sea centinela": el campo es no-leído por decisión final | game-designer | ✅ Cerrado (Encuentro Regla 2) |
| OQ-8 | ~~¿Quién evalúa victoria/derrota de era? Combate solo notifica muertes (Regla 9)~~ ✅ **RESUELTO 2026-08-12**: Encuentro con Kaiju (Approved) es el dueño — declara victoria al cruzar 0 la vida del kaiju y derrota al morir el último héroe vivo (Regla 9/AC-K49–K53). Combate sigue solo notificando muertes | game-designer | ✅ Cerrado (Encuentro Regla 9) |
