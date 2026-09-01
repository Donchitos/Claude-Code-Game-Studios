# Reliquias/Bendiciones

> **Status**: In Design
> **Author**: usuario + agentes
> **Last Updated**: 2026-08-18 (design-review 2026-08-18: NEEDS REVISION → 7 bloqueantes aplicados; pendiente re-review en sesión limpia)
> **Implements Pillar**: El Pasado es Poder (Pilar 2 — sistema eje); Preparación Ritual, Clímax Explosivo (Pilar 3)

## Overview

Reliquias/Bendiciones es el sistema que cierra la cadena central del juego (Permadeath → Forja de Legado → **Reliquias/Bendiciones** → Panteón): toma las Reliquias que Forja de Legado ya forjó a partir de muertes de héroes de eras anteriores y las convierte en **bendiciones invocables durante el clímax de combate** contra el kaiju. A nivel de datos, es la capa de traducción y balance de la cadena de legado: define qué efecto mecánico corresponde a cada combinación de `relic_category` (`offensive`/`defensive`/`rally`) × `tier` (Delgada/Sólida/Legendaria) sin romper la regla de daño plano de Combate/Daño, gestiona el pool acumulado de reliquias del que se sortea (estilo Hades — el jugador elige 1 de varias opciones ofrecidas), y limita cuántas veces se puede invocar una bendición por era (recurso finito, deliberadamente no farmeable — coherente con el core loop del concepto). A nivel de jugador, es el momento exacto en que el legado deja de ser un objeto pasivo exhibido en el panteón y se vuelve **poder activo en la mano del jugador**: la reliquia con el nombre de un héroe caído aparece como una opción táctica real en medio del enfrentamiento contra el próximo kaiju, y elegirla es reafirmar, en el fragor del combate, que esa muerte importó. Sin este sistema, Forja de Legado produciría reliquias sin propósito jugable y Permadeath un veredicto sin consecuencia mecánica visible — Reliquias/Bendiciones es lo que hace que el **Pilar 2** ("El Pasado es Poder") sea literalmente cierto en el momento que más importa: el clímax.

## Player Fantasy

*(Nota: el GDD se autoró en modo lean sin `creative-director`; el encuadre fue revisado por `creative-director` en el design-review del 2026-08-18, que confirmó que la fantasía es la razón de ser del sistema y exigió cerrar el gap de entrega —identidad glanceable + reconciliación de la oferta sin-pausa con el telegrafío del kaiju— aplicado en esta revisión. `art-director` aún pendiente para producción de VFX/íconos.)*

**El jugador es el comandante que empuña, en pleno fragor de combate, el arma forjada con la muerte de alguien que perdió.** El momento de invocar una bendición no es elegir un ítem de una lista genérica — es un instante de reconocimiento: entre las opciones ofrecidas hay reliquias con nombre propio, cada una la huella mecánica de una tragedia específica y vivida por el propio jugador en una era anterior. La tensión de "¿cuál elijo?" (estilo Hades — tres opciones, decisión rápida bajo presión de clímax) se funde con una pregunta que Hades nunca hace: *"¿a cuál de mis muertos invoco ahora?"*. Es la diferencia entre un power-up y una invocación.

Debajo de ese instante directo hay una capa que el jugador siente sin verla: la escasez. **Precisión de qué es escaso (reconciliación cross-review 2026-08-18):** el panteón de reliquias *crece* con el tiempo — es una colección, no un consumible; las reliquias no se gastan al usarse (vuelven al pool). Lo verdaderamente escaso, lo que no se puede "farmear" ni acumular, son las **`invocation_charges` por era**: pocas, se resetean por era, no se acumulan entre eras. Esa cota por-era es lo que vuelve significativa cada elección — no cuántas reliquias tengas, sino cuántas veces puedes invocar *esta* era. Si el jugador pudiera invocar sin límite, el panteón se volvería un inventario más; la escasez de cargas es lo que preserva el peso del Pilar 1 dentro del Pilar 2 — cada invocación gasta algo real. *(Nota: la calidad de las reliquias acumuladas sí está gateada por `relic_quality` — una muerte descuidada solo da Delgada; ver la interacción con el anti-turtle de Furia en encuentro-con-kaiju.md OQ-15.)*

**Test de diseño (este sistema debe hacerlo cumplir):** si el efecto de una bendición pudiera pertenecer, sin cambiar una palabra, a un drop de loot genérico sin nombre — fallamos. Toda bendición debe sentirse indisociable del héroe y la circunstancia que la forjó (categoría + tier + epitafio), nunca intercambiable con "una poción +10% daño" cualquiera. Referencia directa: Darkest Dungeon logra este peso con las cicatrices de sus héroes; Hades lo logra con la excitación del draft — este sistema necesita ambas cosas a la vez, no una eligiendo sobre la otra.

## Detailed Design

### Core Rules

1. **Fuente única del pool (solo lectura sobre Forja de Legado).** El pool de invocación se construye leyendo el registro de Reliquias que **posee Forja de Legado** (la `RelicRecord`). Reliquias/Bendiciones **nunca** forja, modifica ni borra una reliquia — solo consume `relic_id`, `relic_category`, `tier`, `source_hero_name`, `epitaph` y `origin_era_id` de cada registro. El `origin_era_id` es lo que permite a F-RB5 excluir del pool las reliquias forjadas en la era en curso (Regla 10, mecanismo de exclusión intra-era). Esto **cierra Forja OQ-FL2 / desbloquea AC-FL19** (Forja definió el contrato provisional; este sistema lo confirma).

2. **Mapeo `relic_category → tipo de efecto` (fijo, temático).** Cada categoría tiene una identidad mecánica invariable y legible:
   - **`offensive`** → efecto **ofensivo**: bono de daño plano aditivo a un héroe/banda y/o una **acción ofensiva invocable** (p. ej. un golpe único de área).
   - **`defensive`** → efecto de **supervivencia**: bono plano de vida máxima temporal, mitigación temporal, o un aura defensiva anclada (conceptualmente pariente de `guard_radius`).
   - **`rally`** → efecto de **grupo/tropas**: refuerzo instantáneo o buff plano aplicado a toda la banda del jugador.
   La categoría es fija por reliquia (transportada de Forja/Héroes, nunca reasignada). El *qué* hace una bendición lo determina su categoría, no su tier.

3. **Mapeo `tier → magnitud` (escalonado, mismo efecto).** El tier (`Delgada`/`Sólida`/`Legendaria`, derivado por Forja vía FL1) escala **solo la magnitud** del efecto de su categoría: Delgada = base, Sólida = base × `solid_factor`, Legendaria = base × `legendary_factor` (factores = knobs, afinados en Formulas). El tier **nunca** cambia *qué* hace la bendición, solo *cuánto* — preserva la legibilidad ("una muerte mejor gastada da una bendición más fuerte, no una distinta"). Reliquias/Bendiciones **consume** el tier ya resuelto por Forja; **nunca recalcula** `relic_quality` ni redefine los cortes de tier (los posee Héroes).

4. **Todo efecto respeta la Regla 5 de Combate/Daño (daño plano, sin multiplicadores de tipo).** Ningún bono de daño es un multiplicador porcentual sobre la fórmula de daño. Los bonos ofensivos son **aditivos y planos** (`+N` al daño por golpe, aplicado como modificador de instancia temporal); las **acciones invocables** (golpe de área, refuerzo) usan el camino `apply_damage` / spawn **ya existente** de los sistemas dueños, con montos fijos — nunca introducen una fórmula de daño nueva. Un golpe de área se implementa como **múltiples llamadas `apply_damage` de un solo objetivo** sobre los enemigos dentro de un radio (Combate es single-target, sin hook de cleave — se respeta iterando, no ampliando la fórmula). Esta regla es la que mantiene el Pilar 3 legible.

5. **Cargas de invocación: recurso finito por era (anti-farmeo).** El jugador dispone de `invocation_charges` por era (knob, MVP pocas — ~2–3; posible config por `EraDefinition`). Invocar gasta **exactamente una** carga. Sin cargas restantes, no se puede invocar. Las cargas **se resetean al valor de la era, no se acumulan entre eras** — es lo que hace literal el core loop del concepto ("recurso limitado, no se puede abusar") y preserva el peso del Pilar 1 dentro del Pilar 2.

6. **Invocación = sorteo 3-choose-1 desde el pool acumulado (estilo Hades).** Al **abrir** una invocación (con ≥1 carga disponible), el sistema **sortea `draw_size` reliquias** (knob, MVP 3) del pool acumulado y las ofrece; el jugador **elige 1** y en ese momento **se gasta exactamente una carga** (commit-on-choice, Regla 7b); se aplica el efecto de la reliquia elegida. Las **no elegidas vuelven al pool** (no se consumen — una reliquia no se "gasta", lo que se gasta es la carga). El sorteo usa un RNG **inyectable/semilla-controlable** (misma disciplina que Encuentro con Kaiju para tests deterministas).

7. **Ventana de invocación: durante el `CLIMAX` (contra el kaiju).** La invocación está disponible mientras el Temporizador esté en fase `CLIMAX` (el enfrentamiento activo) — es donde el concepto ubica las bendiciones (Core Mechanic #3) y donde el Pilar 3 alcanza su pico. *(Si conviene permitir bendiciones defensivas/rally de preparación en `PREPARATION`, se decide como afinación — ver Open Questions; el MVP arranca solo-`CLIMAX` por simplicidad.)*

7b. **La oferta corre en cámara lenta, no en pausa (`offering_time_scale`).** Mientras el estado es `OFFERING` (oferta abierta, esperando la elección del jugador), la simulación se **ralentiza** a `offering_time_scale` (knob, MVP 0.2×) en lugar de detenerse. Consecuencias, todas deliberadas: **(a)** el jugador conserva el control de sus unidades durante la oferta (puede seguir dando órdenes — la pelea no se congela); **(b)** el kaiju y su telegrafío también se ralentizan al mismo factor, de modo que **leer una reliquia nunca puede provocar una emboscada** (el telegrafío no puede completarse "a espaldas" del jugador mientras lee) — esto reconcilia el momento de reconocimiento con la regla de "sin pausa" (Pilar 3): el tiempo no se detiene, solo se dilata; **(c)** el jugador **sigue siendo vulnerable** — puede recibir daño en cámara lenta si ya estaba en la trayectoria de un golpe, así que la oferta no es un refugio de invulnerabilidad. **Timing de la carga (commit-on-choice, no commit-on-open).** La carga se gasta en el **momento de elegir** (`OFFERING`→`RESOLVING`), no al abrir la oferta — coherente con AC-RB40 ("la carga se gasta al elegir"). Abrir una oferta y cancelarla **no cuesta carga**. Para evitar que la cámara lenta se explote como stall gratuito e ilimitado, dos frenos: **(1) soft-timeout** (`offering_soft_timeout_s`, knob, MVP 8.0s de tiempo real): al expirar sin elección, la oferta se auto-cancela (vuelve a `READY`) sin gastar carga; **(2) cooldown post-cancelación** (`offering_cooldown_s`, knob, MVP 3.0s de tiempo real a velocidad normal): tras cualquier cancelación (timeout o manual), `can_invoke=false` durante el cooldown, así el jugador no puede re-abrir la cámara lenta de inmediato. Juntos acotan la cámara lenta a ráfagas cortas y espaciadas, sin penalizar la indecisión con una carga perdida. La propiedad del mecanismo de escala de tiempo global es un contrato a coordinar (ver OQ-RB9).

8. **Reliquias/Bendiciones no posee combate, stats base ni la fórmula de daño.** Es **productor de efectos, consumidor de APIs existentes**: delega todo daño en Combate/Daño (`apply_damage`), los refuerzos/buffs de tropa en Sistema de Tropas, y los buffs de héroe en Sistema de Héroes. Los bonos se aplican como **modificadores de instancia temporales** (duración = knob), **nunca** mutando el `CombatProfile`/`HeroDefinition`/`TroopDefinition` persistente — la fuente de verdad de stats no se ensucia.

9. **Sistema inerte sin legado (onboarding natural).** Si el pool está vacío (no hay reliquias forjadas todavía — el caso de la primera era antes de la primera muerte), **no se ofrece invocación** y el sistema es inerte. Esto realiza el gate de onboarding del concepto ("las bendiciones aleatorias no se exponen hasta la 2ª partida") **sin un candado artificial** — simplemente no hay nada que invocar hasta que la cadena de legado produce su primera reliquia.

10. **El pool se construye SOLO de reliquias de eras anteriores; nunca de muertes de la era en curso (decisión fijada, cierra OQ-RB5).** El pool de invocación de una era se puebla exclusivamente con reliquias forjadas en eras **previas** (el panteón heredado). Una muerte de héroe **durante** el CLIMAX en curso forja su reliquia (vía Permadeath→Forja) pero esa reliquia **no** entra al pool invocable de este mismo combate — recién queda disponible a partir de la era siguiente. Esto preserva el peso trágico (Pilar 1/2): una muerte no se convierte en un ítem de vending-machine que el jugador draftea 90 segundos después en la misma pelea, sino en poder heredado por la próxima civilización. **Para el MVP de una sola era**, esto implica que el pool debe **pre-sembrarse** desde un panteón de prueba (roster de muertes de una "era 0" ficticia) para poder demostrar el hook de bendiciones — de lo contrario la primera era arranca con pool vacío y el sistema es inerte toda la partida (coherente con la Regla 9 y con la curva de onboarding del concepto: las bendiciones no se exponen en la 1ª partida). *(La forma exacta del panteón de prueba pre-sembrado — cuántas reliquias, qué mezcla de categoría/tier — se fija al poblar el save inicial; ver OQ-RB5.)*

### States and Transitions

*(Ciclo por-invocación — no un estado global del sistema. Un estado global ligero por-era, `CHARGES_AVAILABLE` vs `DEPLETED`, envuelve este ciclo.)*

| Estado | Descripción | Transición desde | Transición hacia |
|---|---|---|---|
| `READY` | Hay ≥1 carga, el pool no está vacío, fase = `CLIMAX`, y no en cooldown post-cancelación | Inicio de `CLIMAX`; fin de una invocación previa con cargas restantes; fin del cooldown post-cancelación | `OFFERING` (jugador abre la oferta — aún NO gasta carga) |
| `OFFERING` | Oferta abierta: `draw_size` reliquias sorteadas y ofrecidas; **simulación en cámara lenta (`offering_time_scale`)**; esperando elección; carga **aún NO gastada** | `READY` | `RESOLVING` (jugador elige → gasta 1 carga); `READY` (cancelación manual o soft-timeout → **sin gasto de carga**, entra a cooldown) |
| `RESOLVING` | Reliquia elegida; **carga gastada al elegir**; efecto aplicándose vía la API del sistema dueño; simulación vuelve a velocidad normal | `OFFERING` | `ACTIVE` (efecto con duración) o directamente `SPENT` (efecto instantáneo) |
| `ACTIVE` | Efecto temporal en curso (duración corriendo) | `RESOLVING` | `SPENT` (duración expira) |
| `SPENT` | Efecto terminado; carga consumida; no-elegidas devueltas al pool | `RESOLVING` / `ACTIVE` | `READY` (quedan cargas) / `DEPLETED` (0 cargas) |
| `DEPLETED` | 0 cargas restantes esta era; no se puede invocar | `SPENT` | — (hasta reset de la próxima era) |

### Interactions with Other Systems

| Sistema | Dirección | Interfaz |
|---|---|---|
| **Forja de Legado** | Forja → este (**solo lectura**) | Lee el registro de `RelicRecord` (`relic_id`, `relic_category`, `tier`, `source_hero_name`, `epitaph`, `forge_index`, **`origin_era_id`**) para construir el pool — `origin_era_id` es el campo que implementa la exclusión intra-era de la Regla 10 (F-RB5). **Cierra Forja OQ-FL2 / desbloquea AC-FL19** — confirma y extiende el contrato provisional `get_relic_combat_inputs() → {relic_category, tier}` para incluir también los campos de identidad (nombre/epitafio) que la UI necesita mostrar. Nunca escribe |
| **Combate/Daño** | este → Combate | Los efectos ofensivos con daño llaman `apply_damage` (camino single-target existente; área = iterar sobre objetivos en radio). Bonos de daño = modificadores planos aditivos temporales. **Llena la interfaz downstream placeholder de Combate** ("las bendiciones se invocan/resuelven en combate… su interfaz exacta se define al diseñarse"). ✅ Combate Approved |
| **Sistema de Tropas** | este → Tropas | Efectos `rally` (refuerzo instantáneo) vía las APIs de Tropas, surtiendo `min(N, band_headroom)` (Tropas Fórmula E; `max_band_size` es autorado por Datos de Era). Este sistema lee `band_headroom` read-only, no posee el tope. ✅ Designed (F2-B5 resuelto) |
| **Sistema de Héroes** | este → Héroes | Efectos ofensivos/defensivos que buffean a un héroe aplicados como modificadores de instancia temporales (nunca al `HeroDefinition` persistente). ✅ Approved |
| **UI/HUD** | este → UI/HUD | Expone `active_blessings: list` y la oferta de sorteo (3-choose-1) para renderizar durante `CLIMAX`. **Cierra UI/HUD AC-U30 / OQ-U4** (owner era `game-designer` "cuando este GDD exista"). ✅ Approved |
| **Temporizador de Preparación/Ritual** | Temporizador → este (solo lectura) | Lee la **fase** (`CLIMAX`) para habilitar la ventana de invocación (Regla 7). Consume, nunca posee. ✅ Approved |
| **Datos de Era/Civilización** | Datos → este (solo lectura) | `invocation_charges` (y posiblemente `draw_size`) pueden autorarse por era vía `EraDefinition`; además, lee el `era_id` de la era ACTIVE (`active_era_id`) para la exclusión intra-era del pool (Regla 10 / F-RB5). ✅ Designed |
| **Guardado/Persistencia** | este ↔ Guardado | El pool (panteón) lo persiste Forja; las **cargas gastadas y el estado de invocación intra-era** deben restaurarse en una recarga a mitad de era. Contrato a coordinar — ver Open Questions. ✅ Designed |
| **Salón Conmemorativo/Panteón** (#14) | — (sin dependencia directa) | Ambos leen el mismo registro de Forja; el Panteón exhibe, este invoca. Sin GDD aún |

> **Nota de fuente de verdad:** Reliquias/Bendiciones **no duplica** ningún dato de reliquia — el dueño canónico es Forja de Legado (`RelicRecord`). Este sistema mantiene únicamente estado **efímero de invocación** (cargas restantes, efectos activos, oferta actual), no datos de legado.

## Formulas

*(Especialistas consultados, MANDATORY en lean: `economy-designer` (primary — números de balance/economía) + `systems-designer` (mecánica/determinismo), en paralelo. Convergieron; los valores abajo son su propuesta conjunta, aprobada por el usuario.)*

Reliquias/Bendiciones no calcula daño (eso es Combate/Daño vía `apply_damage`) — sus fórmulas gobiernan **magnitud del efecto por tier**, **apilado de modificadores temporales**, **el sorteo**, **la expiración por tick** y **la composición del pool**. Todos los efectos son bonos planos aditivos (Regla 4 / Combate Regla 5); ningún multiplicador porcentual.

### Efectos MVP por categoría (un efecto limpio por categoría)

| Categoría | Efecto MVP | Timing | Base (Delgada) | Sólida (×1.5) | Legendaria (×2.25) | Anclaje |
|---|---|---|---|---|---|---|
| `offensive` | `+N` daño plano por golpe a un héroe | Temporizado | +8 | +12 | +18 | Base = daño de un `melee_infantry` (8); +72% al daño de Vanguardia (25) en Legendaria, dentro de una ventana limitada |
| `defensive` | `+N` vida máxima temporal a un héroe | Temporizado | +30 | +45 | +68 | Sólida (45) = exactamente un golpe de kaiju (45): "compra un golpe que te mataría" |
| `rally` | `N` refuerzos instantáneos a la banda | Instantáneo | 2 | 3 | 5 | Conteos redondean **hacia arriba** (4.5→5) — nunca escatimar el tier alto en un entero visible |

*Diferido a post-MVP (fuera de alcance MVP, no borrado): golpe de área ofensivo (AoE), mitigación plana defensiva (chocaría con la regla "sin armadura MVP" de Combate), aura defensiva anclada, buff de banda `rally` temporizado.*

**Anclaje cross-categoría (las tres categorías deben ser competitivas entre sí, no solo dentro de su categoría).** El riesgo de diseño es que una categoría domine matemáticamente: el bono ofensivo (+18 Legendaria) es **valor incondicional** (siempre daña más), mientras el defensivo (+68 vida máx) es **valor contingente** (solo vale si el héroe estuvo a punto de morir en la ventana), y el `rally` aún no está anclado (OQ-RB8). Bajo economía de valor esperado, el valor incondicional domina al contingente salvo que la probabilidad de muerte sea alta — lo que haría de ofensivo la elección "correcta" la mayoría de las corridas y colapsaría la tensión "¿cuál invoco?". **Reglas de anclaje explícitas para el MVP:**

- **El anclaje defensivo se define por golpes-de-kaiju-comprados, no por vida cruda.** Sólida defensiva (+45) = exactamente 1 golpe de kaiju (45); Legendaria defensiva (+68) = 1.51 golpes. Esto es deliberado: la Legendaria defensiva debe comprar **estrictamente más de un golpe** (>1.0) para justificar el tier, pero **no dos** (evita el "héroe casi inmortal" que el knob `defensive_hp_base` flagea en su rango). El valor se lee contra el daño del kaiju, la única amenaza cuyo timing el jugador no controla.
- **El techo del ofensivo se ancla a la legibilidad del Pilar 3, no al DPS.** Legendaria ofensiva (+18) mantiene al daño de Vanguardia buffeado (25+18=43) **por debajo** del umbral de one-shot sobre esbirros de referencia y **por debajo** del daño del kaiju (45), preservando que el clímax siga siendo legible (ningún golpe de héroe trivializa un tramo). El knob `offensive_damage_base` ya codifica este techo (>12 rompe legibilidad).
- **La comparación se valida por telemetría, no se asume resuelta.** Con `effect_duration_s=20` cubriendo ~un ciclo de telegrafío del kaiju, el ofensivo casi siempre ve uso; el defensivo solo si el héroe recibe daño en la ventana. Si la telemetría de vertical slice muestra que ofensivo se elige >X% frente a defensivo/rally independientemente del contexto, es señal de dominancia a corregir (subir el piso de valor incondicional del defensivo — p. ej. la mitigación plana diferida — o bajar el ofensivo). **Flageado en OQ-RB8.**
- **`rally` no tiene anclaje numérico confirmado en el MVP** (su valor depende del tamaño típico de banda en CLIMAX, un dato que aún no existe): sus números (2/3/5 refuerzos) son provisionales y **no cross-validables** contra ofensivo/defensivo hasta vertical slice (OQ-RB8). Se documenta como pendiente, no como resuelto.

### F-RB1 — Stat efectivo con modificadores temporales de instancia

La fórmula del stat efectivo de una unidad se define como:

`effective_stat(u, s, t) = base_stat(u_type, s) + Σ magnitude(m)  para cada m en active_modifiers(u, s, t)`

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|----------|---------|------|-------|-------------|
| Instancia de unidad | `u` | id de instancia | — | El héroe/tropa concreto, **no** su tipo |
| Stat | `s` | enum | `{attack_damage, max_health}` (MVP) | Qué stat se modifica |
| Stat base | `base_stat(u_type, s)` | int | ≥1 | Leído **solo-lectura** del `CombatProfile`/`HeroDefinition` del tipo — nunca mutado |
| Modificadores activos | `active_modifiers(u, s, t)` | set | tamaño ≥0 | Todas las instancias de bendición activas sobre `u` para `s` en el tick `t` |
| Magnitud por modificador | `magnitude(m)` | int | ≥1 | Bono plano por modificador (F-RB2) |
| **Stat efectivo** | `effective_stat` | int | `[base_stat, ∞)` | Lo que Combate lee al resolver un golpe |

**Rango de salida:** `[base_stat, ∞)` — los bonos solo suman (las bendiciones nunca debuffean). Sin cap en el MVP: el limitador anti-abuso ya es la economía de cargas (2–3/era), no un tope de stack.

**Apilado (regla explícita):** **aditivo entre reliquias distintas; una sola instancia activa por `relic_id` por unidad (refresh-on-repick).** Bendiciones de reliquias *distintas* activas sobre el mismo héroe suman. Pero re-elegir una reliquia que **ya tiene una instancia activa sobre esa misma unidad** NO apila una segunda instancia: **refresca la duración** de la instancia existente a un `expiry_tick` completo nuevo (la magnitud no cambia — el tier es el mismo). Esto elimina el burst degenerado de una sola reliquia: 3 cargas sobre la misma Legendaria ofensiva ya **no** producen 25→79; producen 25→43 (una instancia, refrescada dos veces). Cada `relic_id` activo sobre una unidad tiene a lo sumo un modificador; reliquias distintas mantienen modificadores independientes, cada uno con su propio `expiry_tick`.

**Cota de poder simultáneo (worst-case computable — cierra el gap "sin fórmula" de la nota de knobs).** El bono máximo a un stat de una unidad está acotado por:
`max_stat_bonus(s) = Σ (magnitude de las hasta D reliquias distintas del stat s de mayor magnitud que el jugador puede tener activas simultáneamente)`, donde `D = min(invocation_charges, nº de reliquias distintas del stat s en el pool, nº de reliquias del stat s que caben en effect_duration_s antes de que la primera expire)`. Con MVP `invocation_charges=3` y `max_legendary_per_draw=1`, el peor caso realista para `attack_damage` requiere **3 reliquias Legendaria ofensivas DISTINTAS** en el pool, las tres sorteadas y elegidas sobre el mismo héroe dentro de la ventana → 25 + 3×18 = 79. El refresh-on-repick lo hace **mucho menos probable** (ya no basta que reaparezca una sola Legendaria), pero el stacking entre reliquias distintas sigue siendo aditivo por diseño (combinar legados de héroes distintos es temáticamente válido). Este residual queda **flageado para validación por telemetría en vertical slice** (ver OQ-RB8) — no se clampa en runtime (coherente con la filosofía loud-fail del proyecto), pero ahora es una cantidad *computable y acotada*, no unbounded.

**Contrato de Combate (resuelto — ADR-0001, Accepted 2026-08-21):** Combate expone el read-hook `effective_attack_damage(instancia)` (y la API de escritura `add_modifier`/`remove_by_source`/`sweep_expired`) sobre una capa `CombatState` **por instancia** que capa este stack de modificadores sobre el `CombatProfile` del tipo **en el momento de resolver el golpe**. Este sistema deposita modificadores planos aditivos vía esa API y **nunca** escribe en `CombatProfile`. Ver `docs/architecture/adr-0001-combat-stat-modifier-layer.md`. Cierra OQ-RB1.

**Ejemplo:** Vanguardia (`attack_damage`=25) con una bendición ofensiva Sólida (+12) y otra ofensiva Delgada (+8) → `effective_stat = 25 + 12 + 8 = 45`.

### F-RB2 — Magnitud por tier (escalonada)

`magnitude(base_value, tier) = round_half_up(base_value × tier_factor(tier))`
donde `tier_factor(Delgada)=1.0`, `tier_factor(Sólida)=solid_factor`, `tier_factor(Legendaria)=legendary_factor`.

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|----------|---------|------|-------|-------------|
| Valor base | `base_value` | int | ≥1 | Magnitud Delgada del efecto (por categoría, tabla arriba) |
| Factor Sólida | `solid_factor` | float | >1.0 (MVP 1.5) | Escala del tier medio |
| Factor Legendaria | `legendary_factor` | float | `> solid_factor` (MVP 2.25) | Escala del tier alto |
| **Magnitud** | `magnitude` | int | ≥`base_value` | Bono plano aplicado, redondeado a entero |

**Rango de salida:** `[base_value, ∞)`, estrictamente creciente entre tiers por el invariante de abajo. El tier **nunca** cambia *qué* hace la bendición, solo *cuánto*. Consume el tier de Forja (FL1); nunca recalcula `relic_quality`.

**Invariante loud-fail (carga, no clamp — precedente del proyecto):** para cada `base_value` en uso, verificar `magnitude(_,Sólida) > magnitude(_,Delgada)` y `magnitude(_,Legendaria) > magnitude(_,Sólida)`. El redondeo puede colapsar silenciosamente una brecha de tier débil (p. ej. `base_value=1, solid_factor=1.3 → round(1.3)=1` = Delgada) — eso debe fallar ruidosamente al cargar, no shippear como "Sólida se siente igual que Delgada".

**Ejemplo:** `base_value=8` (offensive), factors 1.5/2.25 → Delgada 8, Sólida `round(12.0)=12`, Legendaria `round(18.0)=18`. Estrictamente creciente ✓.

### F-RB3 — Sorteo 3-choose-1 (muestreo sin reemplazo, RNG semillado)

`k_effective = min(draw_size, P)`
`offer = fisher_yates_partial(pool, k_effective, rng_seeded)`

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|----------|---------|------|-------|-------------|
| Pool | `pool` | lista ordenada de `relic_id` | tamaño `P ≥ 0` | Pool activo (F-RB5), ordenado por `forge_index` ascendente (determinista) |
| Tamaño de sorteo | `draw_size` | int | ≥1 (MVP 3) | Cuántas reliquias se ofrecen |
| RNG | `rng_seeded` | instancia RNG | inyectable/semilla | Misma disciplina que Encuentro con Kaiju (AC-K71) |
| **Oferta** | `offer` | lista de `relic_id` | tamaño `k_effective` | Lo presentado al jugador |

**Rango de salida:** `|offer| = min(P, draw_size)`. **Si `P < draw_size`** (caso MVP real, justo tras la primera muerte): se ofrecen las que haya (p. ej. `P=2, draw_size=3` → 2-choose-1), nunca se rellena ni se lanza error. **Si `P=0`:** no se alcanza en la práctica (Regla 9 / estado `READY` exige pool no vacío); loud-fail defensivo si se invoca con `P=0` (indica bug de máquina de estados aguas arriba).

**Techo de Legendaria por sorteo (Rule B):** ningún `offer` contiene más de `max_legendary_per_draw` reliquias Legendaria (MVP **1**). Garantiza que una Legendaria ofrecida nunca compite contra otra Legendaria — mantiene su singularidad, independiente de cuán Legendaria-pesado sea el pool. El algoritmo exacto (sub-pool ponderado vs. reroll de exceso) es de implementación.

**Ejemplo:** `pool=[R1..R5]` (orden forge_index), `draw_size=3`, con ≤1 Legendaria → `offer` = 3 reliquias, bit-idéntico para el mismo seed+pool.

### F-RB4 — Expiración por tick (disciplina de física, coordinada con Combate Regla 1)

`duration_ticks = ceil(duration_s × physics_ticks_per_second)`
`expiry_tick = applied_tick + duration_ticks`
`is_active(t) = applied_tick ≤ t < expiry_tick`  (intervalo semiabierto)

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|----------|---------|------|-------|-------------|
| Duración | `duration_s` | float | >0 (MVP 20.0) | Duración de efectos temporizados (knob) |
| Ticks/seg | `physics_ticks_per_second` | int | setting (MVP 60) | Paso fijo de física — **nunca** `_process(delta)`/wall-clock |
| Tick de aplicación | `applied_tick` | int | ≥0 | Contador de tick al aplicar (RESOLVING→ACTIVE) |
| Tick de expiración | `expiry_tick` | int | `> applied_tick` | Tick en que se remueve el modificador |

**Rango de salida:** `expiry_tick > applied_tick` siempre (por `duration_s>0`). La expiración se chequea **al inicio de cada tick, antes** de la fase-1 de daño de Combate — un modificador con `expiry_tick == t` ya no existe para ningún `apply_damage` del tick `t` (sin ambigüedad de orden). Efectos **instantáneos** (refuerzo): aplicados una vez en RESOLVING, sin bookkeeping de ticks, van directo a `SPENT`.

**Expiración defensiva segura (edge case preempted):** el bono de vida máxima se aplica `+N` a `max_health` **y** `current_health` a la vez (heal+shield). Al expirar, `max_health` baja `−N` y `current_health = min(current_health, nuevo_max_health)` (clamp hacia abajo, **nunca** vía `apply_damage`). La expiración solo puede *topar* la vida actual, nunca empujarla por debajo de lo que un golpe real ya podría — **expirar nunca mata a un héroe.**

**Ejemplo:** `duration_s=20`, 60 ticks/s → `duration_ticks=1200`. `applied_tick=1000` → activo en `[1000, 2200)` = exactamente 20.0s de tiempo de juego, independiente del framerate.

### F-RB5 — Composición del pool activo (Rule A: exclusión intra-era + tope + retiro FIFO)

`eligible_relics_count = count(reliquias con origin_era_id ≠ active_era_id)`
`active_pool_size = min(eligible_relics_count, pool_cap)`

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|----------|---------|------|-------|-------------|
| Era activa | `active_era_id` | id | — | `era_id` de la era en estado ACTIVE (leído de Datos de Era/Civilización) |
| Reliquias elegibles | `eligible_relics_count` | int | ≥0 | Reliquias forjadas en eras **distintas** de la activa (`origin_era_id ≠ active_era_id`) — implementa Regla 10 |
| Tope de pool | `pool_cap` | int | ≥1 (MVP 16, rango [10,24]) | Máximo de reliquias invocables a la vez |
| **Tamaño de pool activo** | `active_pool_size` | int | `[0, pool_cap]` | Cuántas reliquias están en el pool de sorteo |

**Exclusión intra-era (Regla 10 — mecanismo).** El pool **excluye toda reliquia cuyo `origin_era_id` sea la era ACTIVE**: una muerte de héroe durante el CLIMAX en curso forja su reliquia (Permadeath→Forja) pero esa reliquia **no** entra al pool invocable de este mismo combate — recién es elegible a partir de la era siguiente. Esto es lo que hace implementable la Regla 10 (antes el contrato de lectura omitía `origin_era_id` y esta fórmula no filtraba por era). *(En el MVP de una sola era con panteón pre-sembrado desde una "era 0" ficticia, todas las pre-sembradas tienen `origin_era_id ≠ active_era_id` y pasan el filtro — el hook de bendiciones se demuestra sin exponer una muerte intra-era como ítem invocable.)* **Warning S1 (feedback de UX, no mecanismo):** la reliquia recién forjada simplemente **no aparece** en ninguna oferta esta era (no está en el pool elegible), lo cual resuelve el mecanismo — pero el jugador podría no entender *por qué* la reliquia de su héroe caído no es invocable. Un cue diegético opcional ("consagrada — disponible la próxima era") es una mejora de UX del overlay de invocación, **diferida a `/ux-design`** (mismo destino que OQ-U8); no bloquea el MVP.

**Rango de salida:** `[0, pool_cap]`. Cuando `eligible_relics_count > pool_cap`, la reliquia elegible de **menor `forge_index`** **se retira del pool invocable** → pasa a **solo-exhibición en Panteón** (sigue mostrada y honrada, nunca borrada — la `RelicRecord` no se toca; solo cambia el estado efímero "está en mi pool de sorteo" que este sistema posee). El retiro FIFO opera sobre las reliquias **elegibles**, ordenadas por `forge_index`, determinista. Da al Panteón (#14) un rol narrativo: retirada ≠ olvidada, retirada = consagrada.

**Por qué dos reglas (A + B):** un pool más grande **no** da más ni mayores bendiciones por invocación (la magnitud F-RB2 nunca lee el tamaño del pool). El riesgo real es doble: (1) crecimiento ilimitado diluye la promesa narrativa de "reliquia con nombre propio" → **Rule A** (tope); (2) drift de composición (sorteos cada vez más Legendaria-pesados) → **Rule B** (techo por sorteo, F-RB3). Juntas acotan tamaño Y magnitud por invocación, independiente del nº de eras.

### Invariantes loud-fail (carga)

- `draw_size ≥ 1`; `invocation_charges ≥ 1`; `duration_s > 0` para todo efecto temporizado.
- `solid_factor > 1.0` **y** `legendary_factor > solid_factor`.
- `magnitude` estrictamente creciente entre los 3 tiers para cada `base_value` (atrapa el colapso por redondeo).
- `base_value ≥ 1` para todo bono plano; `pool_cap ≥ 1`; `0 ≤ max_legendary_per_draw ≤ draw_size`.

Cada violación es config rota, no un extremo válido — falla ruidosa, nunca clamp silencioso (precedente de Héroes/Combate).

## Edge Cases

- **Si el pool está vacío al entrar a `CLIMAX`** (primera era sin muertes previas): no se ofrece invocación y el sistema permanece inerte (`READY` nunca se alcanza — exige pool no vacío, Regla 9). No es bug: es el gate de onboarding natural. El HUD no muestra affordance de invocación.

- **Si `P < draw_size`** (pool más chico que el sorteo — p. ej. 2 reliquias forjadas, `draw_size=3`): se ofrecen las `P` que haya (2-choose-1), nunca se rellena con duplicados ni se lanza error (F-RB3). Estado esperado de "corrida temprana", no UX degradada.

- **Si el jugador re-elige la misma `relic_id` sobre la misma unidad en una invocación posterior** (posible y frecuente con pool chico, donde las mismas reliquias aparecen en cada sorteo): si esa reliquia **ya tiene una instancia activa sobre esa unidad**, no se apila una segunda — se **refresca la duración** de la existente a una ventana completa nueva (F-RB1, AC-RB31). El bono de esa reliquia a ese stat nunca excede una sola magnitud. Esto es deliberado: acota el burst degenerado de una sola reliquia (era el vector unbounded principal). *(Re-elegirla sobre una unidad **distinta** sí crea un modificador propio en esa otra unidad — el límite es por-`relic_id`-por-unidad, no global.)*

- **Si el jugador intenta invocar sin cargas restantes** (`DEPLETED`): la acción se rechaza; el HUD indica no-disponibilidad sin texto editorializante (understatement del proyecto). No consume nada.

- **Si el jugador intenta invocar fuera de `CLIMAX`** (durante `PREPARATION`/`IMMINENT` en el MVP): la invocación no está disponible (Regla 7). El affordance solo aparece en `CLIMAX`.

- **Si un efecto temporizado de vida máxima expira** (`defensive`): `max_health` baja `−N` y `current_health = min(current_health, nuevo_max_health)` — clamp hacia abajo, **nunca** vía `apply_damage` (F-RB4). La expiración solo puede topar la vida actual hacia un valor ya alcanzable por combate normal: **expirar nunca mata a un héroe**, ni dispara `DYING`/permadeath.

- **Si el héroe con un buff temporizado activo muere antes de que el efecto expire**: el modificador se descarta con la instancia del héroe al entrar a `DYING` (el buff no sobrevive a su portador ni se transfiere). La muerte se clasifica normalmente por Combate (`D`/`P`) sin que el buff altere la clasificación — un bono de daño no cuenta como "propósito servido".

- **Si un refuerzo `rally` instantáneo se invoca y no hay sitio/límite de banda** (tope de unidades de la era alcanzado): se refuerza hasta el límite disponible; si el límite ya está saturado, el refuerzo es un no-op parcial/nulo pero **la carga igual se gasta** (la carga se gasta al elegir, no al surtir efecto — coherente con Regla 5). **Mitigación del trap:** la oferta expone `band_headroom` por cada opción `rally` (RU-3b), de modo que UI/HUD puede señalar (no-textual) que un `rally` rendiría 0 o parcial **antes** de que el jugador elija — el jugador no "gasta a su amigo caído para nada" sin previo aviso. Caso a coordinar con el tope de banda de Sistema de Tropas/Datos de Era.

- **Si el jugador recibe daño mientras la oferta está abierta (`OFFERING`)**: sí puede recibirlo — la simulación corre en cámara lenta, no en pausa (`offering_time_scale`, Regla 7b). Un golpe que ya estaba en trayectoria conecta en cámara lenta; la oferta **no** es un refugio de invulnerabilidad. Pero como el telegrafío del kaiju también se ralentiza al mismo factor, **ningún telegrafío puede completarse "a espaldas" del jugador** mientras lee — no hay emboscada causada por abrir la oferta. Si el héroe elegido como objetivo de un buff muere durante la oferta, ver la regla de descarte de buff por muerte (el modificador nunca se aplica a una unidad muerta; si era el único objetivo válido, la elección puede reofertar o resolver como no-op según la categoría — coordinar en implementación, OQ-RB7).

- **Si el juego se recarga a mitad de era** (autosave/crash): el pool (panteón) lo restaura Forja/Guardado; las **cargas gastadas y los efectos temporizados activos** deben restaurarse al estado guardado. *(La forma exacta de persistir el estado efímero de invocación — cargas restantes, modificadores activos con su tick de expiración restante — es un contrato a coordinar con Guardado; ver Open Questions. Decisión de diseño ya fijada: las cargas gastadas NO se devuelven por recargar — anti-abuso.)*

- **Si `total_relics_forged` cruza `pool_cap`** durante la era (una muerte intra-era forja la reliquia nº 17 con `pool_cap=16`): la reliquia de menor `forge_index` en el pool activo se retira a solo-exhibición en Panteón (F-RB5, FIFO determinista) en el momento del depósito. La `RelicRecord` nunca se borra. Si esto ocurre mientras esa reliquia estaba siendo ofrecida en un sorteo abierto (`OFFERING`), la oferta en curso se respeta hasta resolverse (no se retira una reliquia bajo los pies del jugador a mitad de elección); el retiro aplica al siguiente sorteo.

- **Si dos efectos modifican el mismo stat del mismo héroe con timers desfasados**: ambos suman mientras ambos estén activos (F-RB1, sin cap); al expirar el primero, su `−N` se remueve y el segundo sigue hasta su propio `expiry_tick`. Sin interacción entre timers — cada modificador es independiente.

- **Si el efecto ofensivo diferido (AoE) se referencia por error en el MVP**: no existe punto de entrada — está fuera de alcance (tabla de efectos). Un `relic_category=offensive` produce únicamente el buff de daño plano temporizado en el MVP.

## Dependencies

**Dependencias hacia arriba (upstream) — lo que este sistema necesita:**

| Sistema | Tipo | Interfaz | Estado |
|---|---|---|---|
| **Forja de Legado** | Dura (**productor crítico**) | Lee el registro de `RelicRecord` (solo lectura) para construir el pool: `relic_id`, `relic_category`, `tier`, `source_hero_name`, `epitaph`, `forge_index`, **`origin_era_id`** (este último implementa la exclusión intra-era de la Regla 10 / F-RB5). **Cierra Forja OQ-FL2 / desbloquea AC-FL19** — este GDD confirma y extiende su contrato provisional `get_relic_combat_inputs()` para incluir los campos de identidad | ✅ Designed (`forja-de-legado.md`) — pendiente su propio design-review |
| **Combate/Daño** | Dura (bidireccional) | Los efectos con daño llaman `apply_damage` (camino single-target). **Requiere un read-hook nuevo** `effective_attack_damage(instancia)` que capa los modificadores temporales sobre el `CombatProfile` del tipo — no existe en `combate-dano.md` hoy | ⚠️ **Contrato provisional** — Combate Approved, pero el read-hook es un añadido pequeño a su contrato (ver OQ-RB1). Llena la interfaz downstream placeholder que Combate ya reservó para este sistema |
| **Temporizador de Preparación/Ritual** | Dura (**solo lectura**) | Lee la fase (`CLIMAX`) para habilitar la ventana de invocación (Regla 7). Consume, nunca posee | ✅ Approved (`temporizador-de-preparacion-ritual.md`) |
| **Sistema de Tropas** | Dura | Aplica efectos `rally` (refuerzo instantáneo) vía las APIs de Tropas, surtiendo `min(N, band_headroom)`; lee `band_headroom` read-only (Tropas Fórmula E, tope `max_band_size` de Datos de Era). Nunca muta el `TroopDefinition` persistente | ✅ Designed (`sistema-de-tropas.md`) — F2-B5 resuelto 2026-08-21 |
| **Sistema de Héroes** | Dura | Aplica buffs ofensivos/defensivos como modificadores de instancia sobre el héroe; nunca muta el `HeroDefinition` persistente | ✅ Approved (`sistema-de-heroes.md`) |
| **Datos de Era/Civilización** | Blanda (datos, solo lectura) | `invocation_charges` (y posiblemente `draw_size`, `pool_cap`) pueden autorarse por era vía `EraDefinition`; además lee `active_era_id` (el `era_id` ACTIVE) para la exclusión intra-era del pool (Regla 10 / F-RB5) | ✅ Designed (`datos-de-era-civilizacion.md`) |
| **Guardado/Persistencia** | Dura (bidireccional) | El pool lo persiste Forja; el **estado efímero de invocación** (cargas gastadas, modificadores activos con tick de expiración restante) debe restaurarse en recarga a mitad de era | ✅ Designed — forma exacta del contrato a coordinar (ver OQ-RB2) |
| **Input** | Dura (bidireccional) | Este sistema solicita a Input entrar al contexto `BLESSING_SELECT`; Input emite `blessing_choice_confirmed(index)` / `blessing_selection_cancelled` que este sistema consume para el draft 3-choose-1 (RU-2 delega la entrada que dispara la invocación a Input/Control). El draft corre en `CLIMAX` en cámara lenta | ✅ Designed (`input.md`) — bidireccionalidad registrada 2026-08-19; contrato de señal en `input.md` Sección Interactions |

**Dependientes hacia abajo (downstream) — dependen de este:**

| Sistema | Tipo | Interfaz |
|---|---|---|
| **UI/HUD** | Dura | Consume `active_blessings: list` y la oferta de sorteo (3-choose-1) para renderizar durante `CLIMAX`. **Cierra UI/HUD AC-U30 / OQ-U4** (owner era `game-designer` "cuando este GDD exista"). ✅ Approved |
| **Salón Conmemorativo/Panteón** (#14) | Blanda | Exhibe las reliquias, incluidas las **retiradas del pool activo** por el tope FIFO (F-RB5) — "retirada = consagrada". Ambos leen el registro de Forja; sin dependencia directa entre sí. *Sin GDD aún — contrato provisional* |

**Nota de consistencia bidireccional:**
- **Forja de Legado** lista a Reliquias/Bendiciones como consumidor crítico downstream (OQ-FL2, AC-FL19 bloqueado) → ✅ coincide con este upstream; este GDD lo **desbloquea**.
- **UI/HUD** tiene `AC-U30` bloqueado + `OQ-U4` esperando este GDD → ✅ coincide con este downstream; **desbloqueado**.
- **Combate/Daño** lista a Reliquias/Bendiciones como dependiente downstream con interfaz placeholder ("su interfaz exacta se define al diseñarse") → ✅ este GDD la llena; y el read-hook `effective_attack_damage` **ya está absorbido por Combate vía ADR-0001 (Accepted 2026-08-21)** — la capa `CombatState` por instancia es dueña de la aplicación y la expiración. OQ-RB1 cerrada.
- **Temporizador** ya expone la fase `CLIMAX` que este sistema consume → sin edición requerida.
- `systems-index.md` lista la fila de Reliquias/Bendiciones con "Depends On: Forja de Legado, Combate/Daño" → debería añadir **Temporizador de Preparación/Ritual**, **Sistema de Tropas**, **Sistema de Héroes**, **Guardado/Persistencia** y **Datos de Era/Civilización** (⚠️ ver Fase 5 / OQ-RB3).

**Nota provisional:** Salón Conmemorativo/Panteón (#14) aún no tiene GDD — su contrato es propuesto por este documento. Todos los demás sistemas listados ya tienen GDD (Designed o Approved); sus contratos con este sistema están confirmados salvo el read-hook de Combate (OQ-RB1).

## Tuning Knobs

| Knob | Símbolo | Tipo | Default MVP | Rango seguro | Qué se rompe en extremos |
|---|---|---|---|---|---|
| Factor Sólida | `solid_factor` | float | 1.5 | 1.3–1.75 | <1.3: Sólida ≈ Delgada, el tier deja de leerse como progresión. >1.75: se acerca demasiado a Legendaria, debilita la escalera de 3 tiers |
| Factor Legendaria | `legendary_factor` | float | 2.25 | 1.8–2.75 | <1.8: Legendaria no se siente ganada (el band `[0.70,1.00]` de `relic_quality` es difícil de lograr, el payoff debe verse). >2.75: una sola Legendaria trivializa un tramo del CLIMAX y erosiona la decisión de qué invocar |
| Cargas por era | `invocation_charges` | int | 3 | 2–4 | <2: una sola decisión en un CLIMAX largo, degrada a un pre-buff único. >4: erosiona la escasez y sube la carga cognitiva en tiempo real (no hay pausa) |
| Tamaño de sorteo | `draw_size` | int | 3 | 2–4 (≥1 duro) | 1: no hay elección (deja de ser draft). >4: demasiadas opciones que leer bajo presión de clímax sin pausa |
| Duración de efectos temporizados | `effect_duration_s` | float | 20.0 | 15.0–30.0 | <15: el buff expira a mitad del telegrafío del kaiju (ciclo ~14s+), rompe la fantasía "invoqué esto para sobrevivir el próximo golpe". >30: casi-permanente, las cargas dejan de ser el limitador principal |
| Escala de tiempo de la oferta | `offering_time_scale` | float | 0.2 | 0.1–0.5 (0<x<1 duro) | →0: casi-pausa, contradice "sin pausa" del Pilar 3. →1: sin ralentización, la oferta no es legible bajo presión (revierte al problema de blind-pick). Nunca ≥1 (no aceleraría) ni ≤0. *Dueño del reloj: **TimeControl** (ADR-0002, Accepted); este sistema solicita el régimen SLOWED con este valor vía `request_regime`, no aplica la escala directamente.* |
| Soft-timeout de la oferta | `offering_soft_timeout_s` | float | 8.0 | 5.0–15.0 (tiempo real) | <5: no alcanza a leer 3 opciones aun en cámara lenta. >15: la cámara lenta se estira demasiado, diluye la tensión de tiempo real |
| Cooldown post-cancelación | `offering_cooldown_s` | float | 3.0 | 1.5–6.0 (tiempo real) | <1.5: la cámara lenta se puede re-abrir casi sin fricción (farmeable). >6: castiga en exceso una cancelación honesta, el jugador evita abrir por miedo al lockout |
| Tope de pool activo | `pool_cap` | int | 16 | 10–24 | <10: la variedad de sorteo colapsa (mismas reliquias repetidas, mata la frescura Hades). >24: reliquias individuales dejan de ser reconocibles/especiales; el rol narrativo "reliquia consagrada" del Panteón nunca se usa |
| Techo de Legendaria por sorteo | `max_legendary_per_draw` | int | 1 | 1–2 (0 prohibido) | 0: ninguna Legendaria aparece jamás — contradice todo el payoff de ganar una. >2 (=`draw_size`): revierte a sorteo uniforme, reabre el drift de composición (riesgo ALTO flageado) |
| Base ofensiva (daño plano) | `offensive_damage_base` | int | 8 | 4–12 | <4: bono ofensivo imperceptible incluso en Legendaria. >12: Legendaria (×2.25=27) rivaliza con el daño base de Vanguardia (25), one-shots que rompen la legibilidad del Pilar 3 |
| Base defensiva (vida máx) | `defensive_hp_base` | int | 30 | 20–40 | <20: no compra ni un golpe de kaiju (45), el efecto no se siente. >40: Legendaria (×2.25=90) = dos golpes de kaiju, un héroe casi inmortal por 20s |
| Base rally (refuerzos) | `rally_reinforce_base` | int | 2 | 1–3 | <1: no refuerza nada. >3: Legendaria (×2.25→7) inunda la banda, diluye la escasez de tropas del Pilar 3 |

**Interacción entre knobs:**
- `solid_factor` y `legendary_factor` están acoplados por el invariante de monotonía (F-RB2): `1.0 < solid_factor < legendary_factor`, verificado con loud-fail contra cada `base_value`. Bajar un `*_base` demasiado puede colapsar la brecha de tier por redondeo — el invariante lo atrapa al cargar.
- `invocation_charges` × `draw_size` × `effect_duration_s` gobiernan juntos cuánto poder simultáneo puede tener el jugador. Subir los tres a la vez multiplica el poder de forma no obvia — coordinar cambios.
- `pool_cap` y `max_legendary_per_draw` son las dos palancas del balance de pool a largo plazo (F-RB5/F-RB3, riesgo ALTO): tamaño y magnitud por invocación respectivamente. Son independientes del nº de eras por diseño.

**Knobs que NO existen (decisiones conscientes):**
- **No hay knob de cortes de tier**: los boundaries `[0.10,0.35)/[0.35,0.70)/[0.70,1.00]` los posee Héroes (`relic_quality`); este sistema los consume vía Forja FL1, no los duplica (evita segunda fuente de verdad).
- **No hay knob de multiplicador porcentual de daño**: prohibido por la Regla 4 / Combate Regla 5 (daño plano). Todo bono es aditivo.
- **No hay knob de pausa**: la invocación es tiempo real por decisión de diseño (Pilar 3), no configurable.
- **No hay knob de duración por tier**: el tier escala solo magnitud (Regla 3), no duración — meterlo compondría poder de forma runaway en Legendaria.

## Visual/Audio Requirements

*Referencia rectora: Art Bible Principio A ("El Legado es Luz") — la reliquia dorada es el caso central del principio. **Reliquias/Bendiciones no diseña el ícono de la reliquia** (lo posee Forja de Legado, FV-1) ni la escenificación de la muerte (Héroes V-6/Permadeath). Esta sección fija el contrato visual/sonoro del **momento de invocación en combate** — lo único que este sistema posee. Modo lean: `art-director` no spawneado (categoría no-visual-required estricta, mismo criterio que Forja); flag de re-visita manual antes de producción.*

**RV-1 — El dorado del legado entra al combate solo en la invocación.** El mundo de combate es apagado (Principio A: dorado reservado al legado). El único dorado pleno durante `CLIMAX` aparece en el **momento de invocación**: la oferta de reliquias y el destello del efecto al aplicarse. Fuera de ese instante, el combate no tiene dorado (coherente con Combate CV-1/Principio A: "nunca dorado en combate rutinario"). Esto hace que invocar se *sienta* como traer el pasado sagrado al presente.

**RV-2 — La oferta 3-choose-1 usa el ícono de reliquia de Forja + identidad glanceable del héroe.** Cada opción del sorteo se presenta con el **ícono dorado que Forja ya determinó** (`relic_category` × `tier`, FV-1) más su identidad. El **canal de reconocimiento primario es glanceable, no textual**: retrato o silueta del héroe caído + su nombre, legible de un vistazo bajo presión de clímax (aun en cámara lenta, RU-3) — porque el momento "¿a cuál de mis muertos invoco?" debe resolverse por *quién* fue, no por leer prosa. El `epitaph` es canal **secundario** (procedencia que refuerza, no de la que depende el reconocimiento). El grado de acabado dorado escala con `tier` (Delgada = plomo apenas insinuado; Legendaria = dorado pleno) — el jugador *ve* qué tier elige sin leer un número. Reliquias/Bendiciones no crea íconos nuevos; compone la oferta con los de Forja + el retrato del héroe (owned por Héroes/Forja — ver nota de individuación abajo).

> **Nota de individuación (limitación conocida, honesta con el design-test de la Sección Player Fantasy).** El efecto mecánico y el `epitaph` de una reliquia derivan solo de `relic_category` × `tier` — **9 combinaciones**, con el `epitaph` tomado de una tabla-plantilla de 9 entradas (owned por Forja, AC-FL09). Esto significa que dos reliquias ofensivas-Sólida de héroes distintos son idénticas en efecto y en plantilla de epitafio, diferenciándose solo por **quién** las forjó. El canal glanceable (retrato + nombre) es lo que las individualiza en el momento de la oferta; sin él, el sistema fallaría su propio design-test ("nunca intercambiable con un drop genérico"). **Individuación mecánica/textual más profunda** (epitafios que citen la circunstancia específica de la muerte, no solo la plantilla categoría×tier) **requiere coordinación con Forja** — está fuera del alcance de este GDD porque el `epitaph` lo posee Forja; se flagea como recomendación cross-GDD (ver OQ-RB10).

**RV-3 — El efecto de bendición se telegrafía por categoría, no por número.** Al aplicarse, cada categoría tiene un lenguaje visual distinto y legible a escala RTS (Principio: distinción por forma/canal, no solo color): `offensive` (realce dorado sobre el arma/silueta del héroe buffeado), `defensive` (aura/envoltura dorada breve sobre el héroe), `rally` (destello dorado sobre la banda + aparición de refuerzos). La **magnitud (tier)** se lee por intensidad/duración del realce, redundante con el ícono elegido — nunca solo por color (daltonismo, coherente con UI/HUD HU-10 ≥3 canales).

**RV-4 — Sin dorado persistente que ensucie la legibilidad del clímax.** Los realces de bendición son **temporales** (ligados a `effect_duration_s`) y no deben competir con el telegrafío del kaiju (Encuentro KV-1) ni con el readout de peligro del héroe (UI/HUD). Un buff activo se indica de forma sostenida-pero-sutil (no un pulso dorado constante que distraiga); el pico dorado es el instante de aplicación, luego decae a un indicador tenue. Límite con UI/HUD: *cuándo/cómo* se ancla el indicador sostenido lo decide UI/HUD (Sección UI).

**Audio *(provisional — sin dirección de audio aún, mismo estatus que Combate/Héroes)*:**

**RA-1 — La invocación tiene un verbo sonoro propio, coral/sagrado.** A diferencia de Combate (cuyo audio de muerte de héroe es handoff a Permadeath, understatement), la invocación **sí** es un momento sonoro afirmativo — el pasado respondiendo al llamado. Registro coral/orquestal breve (coherente con el tono trágico-sagrado del concepto), categóricamente distinto del lecho de combate. Se duckea el lecho de combate en el instante de aplicación, luego retorna.

**RA-2 — El tier modula la magnitud sonora, no el motivo.** Una Legendaria suena más plena/resonante que una Delgada, pero es reconociblemente el mismo verbo de "invocación" — el jugador oye *qué tan potente* fue la muerte que forjó esa reliquia, sin un motivo distinto por tier (coherente con RV-3 y con el outcome-blind-pero-identity-varied de Héroes A-3).

📌 **Asset Spec** — Con Visual/Audio definido, tras aprobar el art bible se puede correr `/asset-spec system:reliquias-bendiciones` para producir specs de VFX por-asset (realce de invocación por categoría, destello de aplicación, indicador de buff sostenido).

## UI Requirements

*Reliquias/Bendiciones no diseña pantallas — expone datos y eventos que UI/HUD renderiza con el lenguaje diegético del art bible (Sección 7). Esta sección fija el **contrato de qué fluye a UI/HUD**, desbloqueando su `AC-U30`/`OQ-U4`. El *cómo* se ve lo decide UI/HUD.*

**RU-1 — Exposición de cargas restantes.** Expone `invocation_charges_remaining` (int) y su tope de la era, para que UI/HUD muestre cuántas invocaciones quedan durante `CLIMAX`. Read-only para UI/HUD.

**RU-2 — Affordance de invocación gateada por estado.** Expone si la invocación está **disponible ahora** (`can_invoke`: fase = `CLIMAX` **∧** cargas > 0 **∧** pool no vacío **∧** no en cooldown post-cancelación, Regla 7b). UI/HUD muestra/oculta el affordance en función de este booleano; la entrada que dispara la invocación la posee Input/Control (este sistema solo expone disponibilidad y consume el evento de "invocar").

**RU-2b — Onboarding de la primera invocación (`first_invocation_available`).** Para que un jugador de primera partida **descubra** que la invocación existe (el affordance aparece por primera vez a mitad de un combate contra el kaiju), este sistema expone un evento único `first_invocation_available` la primera vez que `can_invoke` pasa a `true` en la campaña del jugador (distinto del `can_invoke` de estado estable). UI/HUD lo consume para un beat de onboarding (resalte/one-time cue) — el *cómo* lo decide UI/HUD, pero el dato existe para construirlo. Se dispara a lo sumo una vez por save.

**RU-3 — La oferta 3-choose-1 (`blessing_offer`).** Al abrir una invocación, expone la oferta como una lista de vistas de reliquia (tamaño `k_effective`, 1–`draw_size`): por cada una, `relic_id`, ícono (de Forja, `relic_category`×`tier`), **identidad glanceable** (`source_hero_name` + retrato/silueta del héroe, ver RV-2 — el canal de reconocimiento primario, legible de un vistazo), `relic_category`, `tier`, y `epitaph` (canal **secundario** — texto de procedencia que se lee si el jugador tiene tiempo, no la señal de la que depende el reconocimiento). UI/HUD la renderiza como draft de opciones; el jugador elige una; UI/HUD devuelve el `relic_id` elegido. **En cámara lenta, no en pausa** (Regla 7b, `offering_time_scale`) — la simulación se ralentiza mientras la oferta está abierta, de modo que el momento de reconocimiento ("¿a cuál de mis muertos invoco?") es legible sin congelar el juego ni exponer al jugador a una emboscada. El reconocimiento debe poder resolverse por la **identidad glanceable** (quién + tier por brillo del ícono), no por leer prosa de epitafio bajo presión.

**RU-3b — Headroom de banda visible en ofertas `rally` (evita el trap de whiff).** Para cada opción `rally` de la oferta, **relaya** `band_headroom` (int ≥0): cuántos refuerzos caben realmente dada la ocupación actual de banda vs. el tope de la era. **Fuente (F2-B5 resuelto 2026-08-21):** `band_headroom` lo **posee Sistema de Tropas** (Fórmula E, `= max(0, max_band_size − alive_troop_count)`); `max_band_size` es autorado por Datos de Era. Este sistema solo lo lee y lo pasa por opción; un `rally` de tier `N` surtirá `min(N, band_headroom)` tropas. UI/HUD lo usa para señalar (no-textual, coherente con RU-5) cuándo un `rally` rendiría 0 o parcial **antes** de que el jugador gaste la carga — cerrando el "gasté a mi amigo caído para nada" sin previo aviso (ver Edge Case de `rally` en tope de banda).

**RU-4 — Bendiciones activas (`active_blessings: list`) — desbloquea UI/HUD AC-U30.** Expone la lista de efectos temporizados activos: por cada uno, categoría, tier, y **tiempo/tick de expiración restante** (para un indicador de duración). Esto es exactamente la `active_blessings: list` que UI/HUD `AC-U30`/`OQ-U4` asumía como mock — este contrato la vuelve real. UI/HUD la renderiza sin mutarla (read-only).

**RU-5 — Sin editorializar (understatement).** Coherente con Combate CU-4 / Héroes U-5: este sistema no expone texto de "¡Bendición invocada!" ni juicios. Expone estado estructurado (cargas, oferta, activos) e identidad de reliquia (nombre/epitafio, que son *dato de procedencia*, no editorial). La lectura del momento es visual/sonora (RV-1..3/RA-1), no un banner de sistema.

**RU-6 — Feedback de rechazo no-silencioso, no-texto.** Si el jugador intenta invocar sin cargas o fuera de `CLIMAX` (`can_invoke=false`), expone un evento de rechazo que UI/HUD refleja con un cue no-textual (coherente con el patrón de rechazo de Sacrificio de UI/HUD) — nunca un silencio ambiguo ni un texto editorializante.

📌 **UX Flag — Reliquias/Bendiciones**: Este sistema alimenta la UI de invocación en combate (affordance de cargas, oferta 3-choose-1, indicador de bendiciones activas) — la interacción más densa del HUD de `CLIMAX`, en tiempo real sin pausa. En Pre-Producción, correr `/ux-design` para la pantalla/overlay de invocación **antes** de escribir epics; las stories que referencien esa UI deben citar el spec de UX, no este GDD. Coordinar con el HUD de `CLIMAX` de UI/HUD (ya Approved) para no duplicar ni colisionar con el telegrafío del kaiju y el readout de peligro del héroe.

## Acceptance Criteria

*Convención: formato Dado/Cuando/Entonces + etiqueta de tipo de evidencia (`[Logic/unit]`, `[Integration]`). Los AC marcados **(bloqueado)** dependen de un contrato no confirmado hoy — hoy verificables solo con mock en el límite de este sistema. Forja de Legado, Temporizador, Sistema de Tropas, Sistema de Héroes, Datos de Era/Civilización y Guardado/Persistencia **sí** tienen GDD — los AC contra esos contratos NO están bloqueados, solo pendientes de implementación (mismo criterio que `forja-de-legado.md` aplicó). Solo bloquean: el read-hook `effective_attack_damage` de Combate/Daño (OQ-RB1, no está en `combate-dano.md` hoy), el contrato de persistencia de estado efímero de invocación con Guardado (OQ-RB2, a coordinar), y el Salón Conmemorativo/Panteón (#14, sin GDD).*

### A. Fuente del pool — solo lectura sobre Forja de Legado (Regla 1)

**AC-RB01 — El pool se construye leyendo `RelicRecord` de Forja; nunca escribe** **[Integration]**
Dado el registro de `RelicRecord` que posee Forja de Legado, cuando Reliquias/Bendiciones construye su pool de invocación, entonces lee únicamente `relic_id`, `relic_category`, `tier`, `source_hero_name`, `epitaph`, `forge_index`, `origin_era_id` de cada registro (`origin_era_id` implementa la exclusión intra-era de la Regla 10, F-RB5) — no invoca ningún método de forja, edición o borrado sobre Forja.

**AC-RB02 — Reliquias/Bendiciones nunca forja, modifica ni borra una reliquia** **[Logic/unit]**
Dado la superficie pública de Reliquias/Bendiciones hacia Forja de Legado, cuando se audita qué métodos invoca, entonces solo llama hooks de lectura (p. ej. `list_relics()`/`get_relic_combat_inputs()`) — no expone ni invoca ningún método capaz de crear, editar o eliminar una `RelicRecord`. *(Se complementa con un check estático de CI — ver nota de testabilidad al final.)*

### B. `relic_category` → tipo de efecto, fijo (Regla 2)

**AC-RB03 — `offensive` siempre produce el efecto ofensivo** **[Logic/unit]**
Dado una reliquia con `relic_category = offensive` de cualquier tier, cuando se resuelve su efecto, entonces el efecto aplicado es el bono de daño plano por golpe (tabla MVP) — nunca un efecto defensivo o `rally`.

**AC-RB04 — `defensive` siempre produce el efecto de supervivencia** **[Logic/unit]**
Dado una reliquia con `relic_category = defensive` de cualquier tier, cuando se resuelve su efecto, entonces el efecto aplicado es el bono temporal de vida máxima — nunca ofensivo o `rally`.

**AC-RB05 — `rally` siempre produce el efecto de grupo/tropas** **[Logic/unit]**
Dado una reliquia con `relic_category = rally` de cualquier tier, cuando se resuelve su efecto, entonces el efecto aplicado son refuerzos instantáneos a la banda — nunca ofensivo o defensivo.

**AC-RB06 — La categoría nunca se reasigna; el tier no cambia el tipo de efecto** **[Logic/unit]**
Dado una misma reliquia observada hipotéticamente en Delgada, Sólida y Legendaria, cuando se resuelve el tipo de efecto en cada caso, entonces el tipo permanece idéntico a través de los tres tiers — solo cambia la magnitud (F-RB2), nunca el *qué*.

### C. `tier` → magnitud, escalonado (Regla 3, Fórmula F-RB2)

**AC-RB07 — Delgada = magnitud base (`tier_factor = 1.0`)** **[Logic/unit]**
Dado un `base_value` de cualquier categoría, cuando se evalúa F-RB2 con `tier = Delgada`, entonces `magnitude = base_value` sin escalar.

**AC-RB08 — Sólida = `base_value × solid_factor` (1.5), redondeado** **[Logic/unit]**
Dado `base_value = 8` (offensive), cuando se evalúa F-RB2 con `tier = Sólida`, entonces `magnitude = round_half_up(12.0) = 12`.

**AC-RB09 — Legendaria = `base_value × legendary_factor` (2.25), redondeado** **[Logic/unit]**
Dado `base_value = 8` (offensive), cuando se evalúa F-RB2 con `tier = Legendaria`, entonces `magnitude = round_half_up(18.0) = 18`.

**AC-RB10 — `round_half_up` aplica sobre los tres `base_value` de la tabla MVP** **[Logic/unit]**
Dado `base_value = 30` (defensive) y `base_value = 2` (rally), cuando se evalúan Sólida/Legendaria, entonces los resultados son `{45, 68}` y `{3, 5}` respectivamente (`round_half_up(4.5) = 5`, nunca hacia abajo).

**AC-RB11 — Invariante loud-fail: magnitud estrictamente creciente entre los 3 tiers, por `base_value`** **[Logic/unit]**
Dado un `base_value` donde el redondeo colapsaría la brecha entre tiers (p. ej. `base_value = 1`, `solid_factor = 1.3` → `round(1.3) = 1` = igual a Delgada), cuando se carga la configuración, entonces falla ruidosamente en build de desarrollo — nunca shipea un tier que "se siente igual" al anterior.

**AC-RB12 — Reliquias/Bendiciones consume el tier de Forja (FL1); nunca recalcula `relic_quality` ni redefine cortes de tier** **[Logic/unit]**
Dado un `tier` recibido de una `RelicRecord`, cuando este sistema resuelve la magnitud del efecto, entonces usa ese `tier` tal cual — no invoca ninguna lógica de mapeo `relic_quality → tier` propia (esa lógica es de Forja FL1 exclusivamente).

### D. Daño plano, sin multiplicadores porcentuales (Regla 4 / Combate Regla 5)

**AC-RB13 — El bono ofensivo es aditivo plano, nunca un multiplicador porcentual** **[Logic/unit]**
Dado un bono ofensivo de cualquier tier, cuando se aplica sobre `effective_stat` (F-RB1, la capa de modificadores propia de este sistema), entonces se suma como cantidad fija `+N` — nunca se expresa ni aplica como porcentaje del stat base. *(Verificable hoy contra F-RB1 sin depender del read-hook de Combate: la integración con `effective_attack_damage` la cubre AC-RB32, que sí está bloqueado por OQ-RB1.)*

**AC-RB14 — Los efectos MVP usan APIs de daño/spawn ya existentes, nunca una ruta nueva** **[Integration]**
Dado el efecto `rally` (refuerzos instantáneos), cuando se aplica, entonces invoca la API de spawn/reclutamiento ya existente de Sistema de Tropas — Reliquias/Bendiciones no introduce un camino de spawn ni de daño propio, ni siquiera para el golpe de área diferido a post-MVP (fuera de alcance hoy — ningún punto de entrada existe para él).

### E. Cargas de invocación — recurso finito por era, anti-farmeo (Regla 5)

**AC-RB15 — Elegir una reliquia gasta exactamente 1 carga; abrir la oferta no gasta** **[Logic/unit]**
Dado `invocation_charges_remaining = N > 0`, cuando el jugador **abre** una oferta (`READY`→`OFFERING`) la carga **no** cambia (`= N`); cuando luego **elige** una reliquia (`OFFERING`→`RESOLVING`), entonces `invocation_charges_remaining = N - 1` — exactamente una carga, nunca 0 ni 2, y solo en el momento de elegir (commit-on-choice, Regla 7b).

**AC-RB15b — Cancelar una oferta (manual o soft-timeout) no gasta carga y entra a cooldown** **[Logic/unit]**
Dado una oferta abierta (`OFFERING`) con `invocation_charges_remaining = N`, cuando el jugador cancela manualmente o transcurre `offering_soft_timeout_s` sin elección, entonces el estado vuelve a `READY` con `invocation_charges_remaining = N` (sin gasto), y `can_invoke = false` durante `offering_cooldown_s` de tiempo real — impidiendo re-abrir la cámara lenta de inmediato.

**AC-RB16 — Sin cargas restantes → no se puede invocar** **[Logic/unit]**
Dado `invocation_charges_remaining = 0` (`DEPLETED`), cuando el jugador intenta invocar, entonces la acción se rechaza sin gastar nada y sin sortear ninguna oferta.

**AC-RB17 — Las cargas se resetean al valor de la era; nunca se acumulan entre eras** **[Integration]**
Dado un valor `invocation_charges` autorado en `EraDefinition` para la era N+1, cuando la era N+1 se activa, entonces `invocation_charges_remaining` se fija a ese valor de la nueva era — independientemente de cuántas cargas quedaran sin gastar (o se gastaran) al final de la era N.

### F. Sorteo 3-choose-1 (Regla 6, Fórmula F-RB3)

**AC-RB18 — El sorteo ofrece `min(draw_size, P)` reliquias con RNG inyectable/semillado** **[Logic/unit]**
Dado un pool de `P ≥ draw_size` reliquias y un `rng_seeded` con semilla fija, cuando se invoca F-RB3, entonces `|offer| = draw_size` y el resultado es reproducible bit-idéntico para el mismo seed y el mismo pool.

**AC-RB19 — `P < draw_size` → se ofrecen las `P` que haya, nunca se rellena ni se lanza error** **[Logic/unit]**
Dado un pool con `P = 2` y `draw_size = 3` (caso real justo tras la primera muerte), cuando se invoca F-RB3, entonces `offer` contiene exactamente 2 reliquias (2-choose-1) — nunca se duplica una reliquia para completar 3, nunca se lanza una excepción.

**AC-RB20 — `P = 0` → loud-fail defensivo, nunca alcanzado en la práctica** **[Logic/unit]**
Dado un pool con `P = 0` invocado de forma forzada (bypaseando el gate de estado `READY`), cuando se invoca F-RB3, entonces falla ruidosamente en build de desarrollo — señal de bug de máquina de estados aguas arriba (Regla 9 debería haber impedido llegar aquí).

**AC-RB21 — Las reliquias no elegidas vuelven íntegras al pool; solo la carga se gastó** **[Logic/unit]**
Dado una oferta de 3 reliquias donde el jugador elige 1, cuando la invocación resuelve, entonces las 2 no elegidas permanecen disponibles en el pool para sorteos futuros — ninguna se consume ni se marca como usada.

**AC-RB22 — Ninguna oferta contiene más de `max_legendary_per_draw` Legendarias (Rule B)** **[Logic/unit]**
Dado un pool con ≥5 Legendarias y `max_legendary_per_draw = 1` (MVP), cuando se corre F-RB3 para **N = 1000 sorteos** con la lista de semillas fija `[1..1000]`, entonces **0 de los 1000** sorteos contienen más de 1 Legendaria — el test falla si **cualquier** sorteo individual excede el techo. *(Muestra y semillas fijas para determinismo reproducible; el pass/fail es binario: cero violaciones.)*

**AC-RB23 — Determinismo: mismo seed + mismo pool → oferta idéntica** **[Logic/unit]**
Dado el mismo `rng_seeded` y el mismo estado de pool, cuando F-RB3 se invoca dos veces de forma independiente, entonces `offer` es idéntico en ambas invocaciones (mismos `relic_id`, mismo orden).

### G. Ventana de invocación — solo `CLIMAX` (Regla 7)

**AC-RB24 — La invocación está disponible mientras la fase es `CLIMAX`** **[Integration]**
Dado el Temporizador en fase `CLIMAX` con `invocation_charges_remaining > 0` y pool no vacío, cuando se evalúa `can_invoke`, entonces es `true` y el estado del sistema es `READY`.

**AC-RB25 — La invocación se rechaza fuera de `CLIMAX`** **[Integration]**
Dado el Temporizador en fase `PREPARATION` o `IMMINENT`, cuando el jugador intenta invocar, entonces `can_invoke = false` y la acción se rechaza sin gastar carga ni sortear oferta — independientemente de cuántas cargas o reliquias haya disponibles.

### H. Alcance: no posee combate/stats; modificadores de instancia, nunca mutación persistente (Regla 8)

**AC-RB26 — Reliquias/Bendiciones nunca muta `CombatProfile`/`HeroDefinition`/`TroopDefinition` persistente** **[Logic/unit]**
Dado la superficie de escritura de Reliquias/Bendiciones hacia Combate, Héroes y Tropas, cuando se audita qué campos modifica, entonces nunca escribe sobre el recurso de tipo persistente (`CombatProfile`/`HeroDefinition`/`TroopDefinition`) — toda modificación vive exclusivamente en la capa de modificadores de instancia efímeros de este sistema. *(Guard arquitectónico análogo al Pilar 1 — se complementa con un check estático de CI, ver nota de testabilidad al final.)*

**AC-RB27 — Todo bono se aplica como modificador de instancia temporal, keyeado por `(relic_id, unidad)`** **[Logic/unit]**
Dado una invocación resuelta, cuando se crea (o refresca) su modificador, entonces queda asociado a la instancia concreta del héroe/tropa buffeado — nunca a su tipo/definición — e identificado por la clave `(relic_id, unit_instance_id)`: si ya existe un modificador con esa clave se refresca su duración (AC-RB31); si no, se crea uno nuevo. El modificador nunca muta el recurso persistente del tipo (AC-RB26).

### I. Sistema inerte con pool vacío (Regla 9)

**AC-RB28 — Pool vacío → `READY` nunca se alcanza; invocación no se ofrece** **[Logic/unit]**
Dado un pool con 0 reliquias (antes de la primera muerte de héroe en el legado), cuando se entra a `CLIMAX`, entonces el sistema no alcanza `READY` y no se ofrece ningún affordance de invocación.

**AC-RB29 — El pool vacío es onboarding natural, no un candado artificial ni un error** **[Logic/unit]**
Dado un pool vacío, cuando se audita el motivo por el que `can_invoke = false`, entonces la razón es exclusivamente "pool vacío" (Regla 9) — no existe ninguna bandera de "sistema bloqueado por progreso" separada; en cuanto Forja deposita la primera reliquia, `can_invoke` puede volverse `true` sin ninguna otra condición de desbloqueo.

### J. Stat efectivo con modificadores temporales de instancia (Fórmula F-RB1)

**AC-RB30 — `effective_stat = base_stat + Σ magnitude(m)`, aditivo, sin cap** **[Logic/unit]**
Dado un héroe con `base_stat(attack_damage) = 25` y dos modificadores activos de magnitud 12 y 8, cuando se evalúa F-RB1, entonces `effective_stat = 45` — sin ningún tope superior aplicado por este sistema.

**AC-RB31 — Re-elegir una reliquia ya activa sobre la misma unidad refresca su duración; NO apila una segunda instancia** **[Logic/unit]**
Dado un héroe con un modificador activo de la reliquia X (aplicado en `t=1000`, expira en `t=2200`), cuando el jugador vuelve a elegir la reliquia X sobre ese mismo héroe en una invocación posterior (p. ej. en `t=1600`), entonces **no** se crea un segundo modificador — el modificador existente de X sobre ese héroe **refresca su `expiry_tick`** a una ventana completa nueva (`applied_tick` = tick actual → nuevo `expiry_tick`) y su magnitud permanece igual (mismo tier). El bono a ese stat por la reliquia X **nunca** excede una sola magnitud de X, sin importar cuántas veces se re-elija. *(Reliquias distintas sobre el mismo héroe sí mantienen modificadores independientes — ver AC-RB30.)*

**AC-RB31b — Reliquias distintas del mismo stat apilan aditivamente; el bono total está acotado por la cota worst-case** **[Logic/unit]**
Dado un héroe con modificadores activos de **dos reliquias distintas** (X e Y) que modifican `attack_damage`, cuando se evalúa F-RB1, entonces ambas magnitudes suman (apilado entre reliquias distintas permitido) y el bono total nunca excede `max_stat_bonus(attack_damage)` según la cota computable de F-RB1 — verificado contra el peor caso MVP (3 Legendarias ofensivas distintas → +54).

**AC-RB32 — Read-hook `effective_attack_damage(instancia)` de Combate/Daño** **(desbloqueado — ADR-0001, Accepted 2026-08-21)** **[Integration]**
*Contrato real (ADR-0001): Combate expone `CombatState.effective_attack_damage() → int` sobre la capa de modificadores por instancia; ya no es un mock. La API de escritura es `add_modifier(mod)`/`remove_by_source(source_relic_id)`, y Combate barre expirados con `sweep_expired(current_tick)`.*
Dado un héroe con modificadores activos, cuando Combate resuelve un golpe, entonces lee el valor ya capeado por `effective_attack_damage()` (no el `base_stat` crudo) — confirma el resultado de F-RB1 contra el contrato aceptado de Combate.

### K. Expiración por tick (Fórmula F-RB4)

**AC-RB33 — `duration_ticks = ceil(duration_s × physics_ticks_per_second)`, intervalo semiabierto** **[Logic/unit]**
Dado `duration_s = 20.0` y `physics_ticks_per_second = 60`, cuando se aplica un modificador en `applied_tick = 1000`, entonces `duration_ticks = 1200`, `expiry_tick = 2200`, y `is_active(t)` es `true` para `1000 ≤ t < 2200` y `false` en `t = 2200`.

> **Fuente de tick (ADR-0002, Accepted 2026-08-21):** el contador `t`/`applied_tick`/`expiry_tick` es **`TimeControl.game_tick`** (entero, pause-aware y scale-aware), **no** `Engine.get_physics_frames()`. La fórmula `duration_ticks = ceil(duration_s × 60)` no cambia, pero como `game_tick` se congela en pausa y avanza escalado bajo `offering_time_scale`, las bendiciones duran **tiempo de juego** (se ralentizan/congelan con el régimen), no wall-clock. El barrido de expiración lo ejecuta Combate (`sweep_expired(game_tick)`, ADR-0001) al inicio del tick, antes de la fase-1 de daño.

**AC-RB34 — La expiración se chequea al inicio del tick, antes de la fase-1 de daño de Combate** **[Integration]**
Dado un modificador con `expiry_tick = t`, cuando el tick `t` comienza, entonces el modificador ya fue removido **antes** de que Combate resuelva cualquier `apply_damage` de ese tick — ningún golpe del tick `t` puede leer un modificador que expiró justo en `t`.

**AC-RB35 — Los efectos instantáneos omiten el bookkeeping de ticks y van directo a `SPENT`** **[Logic/unit]**
Dado un efecto `rally` (instantáneo), cuando se resuelve en `RESOLVING`, entonces transiciona directamente a `SPENT` sin pasar por `ACTIVE` ni registrar `applied_tick`/`expiry_tick`.

**AC-RB36 — Expiración de vida máxima defensiva: clamp únicamente, nunca vía `apply_damage`, nunca mata a un héroe** **[Integration]**
Dado un héroe con `max_health` elevado `+N` por un modificador defensivo activo y `current_health` cercano al nuevo máximo, cuando el modificador expira, entonces `max_health` baja `−N` y `current_health = min(current_health, nuevo_max_health)` mediante clamp directo — la expiración nunca invoca `apply_damage`, nunca dispara `DYING`, y `current_health` resultante nunca es ≤ 0 por efecto de la expiración en sí.

### L. Composición del pool activo — tope + retiro FIFO (Fórmula F-RB5)

**AC-RB37 — `active_pool_size = min(eligible_relics_count, pool_cap)`, con `eligible_relics_count = count(origin_era_id ≠ active_era_id)` (exclusión intra-era, Regla 10)** **[Logic/unit]**
Dado 10 reliquias forjadas, de las cuales **8 tienen `origin_era_id ≠ active_era_id`** (2 fueron forjadas en la era ACTIVE) y `pool_cap = 16`, cuando se evalúa F-RB5, entonces `eligible_relics_count = 8` y `active_pool_size = 8` — las 2 reliquias intra-era quedan **excluidas** del pool invocable (Regla 10). Dado 20 elegibles con el mismo `pool_cap`, entonces `active_pool_size = 16` (tope FIFO sobre las elegibles, por `forge_index`). Dado 0 elegibles (todas las forjadas son de la era ACTIVE), entonces `active_pool_size = 0` y el estado `READY` nunca se alcanza (AC-RB28).

**AC-RB38 — Al exceder `pool_cap`, la reliquia de menor `forge_index` se retira del pool activo (flag efímero); la `RelicRecord` nunca se borra** **[Logic/unit]**
Dado un pool activo en su tope (`pool_cap = 16`) y una nueva reliquia forjada (`forge_index` 17º), cuando se deposita, entonces la reliquia con el menor `forge_index` entre las activas cambia su estado efímero "en pool de sorteo" a `false` — su `RelicRecord` en el registro de Forja permanece intacta y sin borrar; la nueva reliquia entra al pool activo.

**AC-RB39 — La reliquia retirada se exhibe en el Panteón como solo-display** **(bloqueado — Salón Conmemorativo/Panteón #14 sin GDD)** **[Integration]**
*Mock Contract Assumption: el mock de Panteón expone un único hook de lectura `list_retired_relics() → [RelicRecord]` para las reliquias marcadas fuera del pool activo. Re-verificar contra el GDD real de Salón Conmemorativo/Panteón cuando exista.*
Dado una reliquia recién retirada del pool activo (AC-RB38), cuando el mock de Panteón consulta `list_retired_relics()`, entonces la recibe con su identidad completa (nombre, categoría, tier, epitafio, era) — confirma que la mitad de "retirada = consagrada" (exhibición) tiene una superficie mínima ya expuesta, distinta de la mitad de retiro-del-pool (AC-RB38, testeable hoy sin mock).

### M. Edge cases de anti-abuso y coordinación cross-sistema

**AC-RB40 — La carga se gasta incluso si el efecto resulta en no-op/whiff** **[Integration]**
Dado un efecto `rally` invocado cuando la banda ya está en su tope de unidades (`band_headroom == 0`, donde `band_headroom = max(0, max_band_size − alive_troop_count)`; `max_band_size` autorado por Datos de Era, enforcement en Tropas Fórmula E), cuando la invocación resuelve, entonces el refuerzo surte `min(N, 0) = 0` (no-op) pero `invocation_charges_remaining` se decrementa igual — la carga se gasta al elegir, no al surtir efecto (cross-ref Tropas AC-33).

**AC-RB41 — Un buff activo se descarta si el héroe muere antes de expirar; no altera la clasificación D/T/P** **[Integration]**
Dado un héroe con un modificador ofensivo activo que entra a `DYING` antes de que el modificador expire, cuando Héroes procesa la transición, entonces el modificador se descarta junto con la instancia del héroe (no se transfiere, no sobrevive) y Combate clasifica la muerte (`D`/`P`) sin que el bono de daño altere esa clasificación.

### N. Invariantes loud-fail (carga)

**AC-RB42 — `draw_size ≥ 1` y `invocation_charges ≥ 1`** **[Logic/unit]**
Dado una configuración con `draw_size = 0` o `invocation_charges = 0`, cuando se carga, entonces falla ruidosamente en build de desarrollo — ninguno de los dos puede ser 0 (un sorteo de tamaño 0 no es elección; 0 cargas es un sistema inerte por config, no por diseño).

**AC-RB43 — `duration_s > 0` para todo efecto temporizado** **[Logic/unit]**
Dado `effect_duration_s = 0` o negativo para un efecto ofensivo/defensivo (temporizado), cuando se carga, entonces falla ruidosamente — un efecto temporizado no puede tener duración nula o negativa.

**AC-RB44 — `solid_factor > 1.0` y `legendary_factor > solid_factor`** **[Logic/unit]**
Dado `solid_factor = 1.0` (o `legendary_factor ≤ solid_factor`), cuando se carga, entonces falla ruidosamente — rompería la monotonía de tier que AC-RB11 protege en tiempo de ejecución.

**AC-RB45 — `base_value ≥ 1`; `pool_cap ≥ 1`; `0 ≤ max_legendary_per_draw ≤ draw_size`** **[Logic/unit]**
Dado cualquier `*_base` en 0, `pool_cap = 0`, o `max_legendary_per_draw` fuera de `[0, draw_size]`, cuando se carga la configuración, entonces falla ruidosamente en build de desarrollo — ninguno de estos límites se clampa en silencio.

### O. Persistencia del estado efímero de invocación (recarga a mitad de era)

**AC-RB46 — Cargas gastadas y modificadores activos se restauran en una recarga a mitad de era; las cargas gastadas nunca se devuelven** **(bloqueado — contrato de persistencia a coordinar con Guardado, OQ-RB2)** **[Integration]**
*Mock Contract Assumption: el mock de Guardado expone `save_ephemeral_invocation_state(charges_remaining, active_modifiers)` / `load_ephemeral_invocation_state() → {charges_remaining, active_modifiers}` como el contrato provisional de round-trip. Re-verificar contra la coordinación real con Guardado cuando OQ-RB2 se resuelva.*
Dado un estado con `invocation_charges_remaining = 1` (de 3) y un modificador activo con `expiry_tick` restante, cuando el juego recarga desde el mock de Guardado, entonces `invocation_charges_remaining` se restaura en `1` (no vuelve a 3 — las cargas gastadas no se devuelven por recargar, decisión de diseño anti-abuso ya fijada) y el modificador activo se restaura con su tiempo de expiración restante correctamente calculado.

### Clasificación de tipo de story (gate de evidencia)

| AC # | Tipo | Evidencia | Gate |
|---|---|---|---|
| AC-RB02, RB03–RB13, RB15, RB15b, RB16, RB18–RB23, RB26, RB27–RB31, RB31b, RB33, RB35, RB37, RB38, RB42–RB45 | Logic | Unit test (`tests/unit/reliquias-bendiciones/`) | Bloqueante |
| AC-RB01, RB14, RB17, RB24, RB25, RB34, RB36, RB40, RB41 | Integration | Integration test | Bloqueante |
| AC-RB32 | Integration | Integration test contra el contrato real de Combate/Daño (read-hook `effective_attack_damage` confirmado por ADR-0001, Accepted) | Bloqueante (pendiente solo de implementación) |
| AC-RB39 | Integration (bloqueado) | Integration test con mock (Salón Conmemorativo/Panteón #14 — sin GDD) | Bloqueante (hoy solo vía mock) |
| AC-RB46 | Integration (bloqueado) | Integration test con mock (Guardado — contrato de estado efímero a coordinar, OQ-RB2) | Bloqueante (hoy solo vía mock) |

*(Nota: ningún AC de Reliquias/Bendiciones depende de Forja de Legado, Temporizador, Sistema de Tropas, Sistema de Héroes, Datos de Era/Civilización o Guardado/Persistencia estando "sin GDD" — los seis ya tienen GDD, así que esos AC son Integration normal, pendientes solo de implementación. AC-RB32 quedó **desbloqueado** por ADR-0001 (Accepted). Quedan bloqueados solo RB39 y RB46, por dos contratos abiertos: #14 [Panteón, sin GDD], OQ-RB2 [Guardado].)*

**Nota de testabilidad (checks estáticos de CI que complementan los unit tests):**

- **Regla 1 ("nunca forja/modifica/borra una reliquia") y Regla 8 ("nunca muta `CombatProfile`/`HeroDefinition`/`TroopDefinition` persistente")** son afirmaciones de superficie/ownership, no de runtime — no hay ningún input de "escritura sobre Forja" o "mutación de un `Definition` persistente" que este sistema pueda rechazar en caja negra, porque esa ruta de código simplemente no debe existir. AC-RB02 y AC-RB26 las cubren como auditoría de superficie; se complementan con un **grep estático de CI** sobre el módulo de Reliquias/Bendiciones que verifica que ningún símbolo de escritura de Forja (`forge_relic`, `delete_relic`, etc.) ni ninguna asignación directa a un campo de `CombatProfile`/`HeroDefinition`/`TroopDefinition` aparece fuera de la capa de modificadores de instancia efímeros. *(Target y ruta exactos del módulo a fijar en el futuro ADR de este sistema, mismo patrón que Forja OQ-FL4.)*

## Open Questions

**OQ-RB1 — ✅ RESUELTO 2026-08-21 — ADR-0001 (Accepted).**
Los efectos ofensivos requerían que Combate expusiera `effective_attack_damage(instancia)` capando los modificadores de instancia sobre el `CombatProfile` del tipo (F-RB1). **ADR-0001 (`docs/architecture/adr-0001-combat-stat-modifier-layer.md`, Accepted 2026-08-21) lo resolvió**: Combate posee una capa `CombatState` por instancia con `effective_attack_damage()` (read-hook) y `add_modifier`/`remove_by_source`/`sweep_expired` (API de escritura que este sistema llama). La expiración vive en Combate y se ancla a `TimeControl.game_tick` (ADR-0002). Desbloquea AC-RB32.

**OQ-RB2 — Persistencia del estado efímero de invocación (contrato con Guardado a coordinar).**
El pool (panteón) lo persiste Forja; pero las **cargas gastadas** y los **modificadores activos con su tick de expiración restante** deben restaurarse en una recarga a mitad de era, sin devolver cargas gastadas (anti-abuso, decisión fijada). La forma exacta del round-trip (qué se serializa, cómo se recalcula el tiempo restante de un modificador a través de una recarga) es un contrato a coordinar con `guardado-persistencia.md`. **Acción**: confirmar el contrato con Guardado; bloquea AC-RB46.

**OQ-RB3 — ✅ CASI RESUELTO 2026-08-21 (reconciliación cross-GDD).**
La fila de `systems-index.md` ya lista las 8 dependencias upstream. Las **filas recíprocas de dependiente** que faltaban se añadieron en la reconciliación cross-GDD del 2026-08-21: **Temporizador**, **Sistema de Tropas**, **Sistema de Héroes** y **Datos de Era/Civilización** ahora reconocen a Reliquias/Bendiciones como dependiente. **Pendiente solo la fila de `guardado-persistencia.md`** — diferida al ADR de Save/Persistencia (ADR-0003, en curso), que reconcilia toda la superficie de persistencia de este sistema (estado efímero de invocación, OQ-RB2). Cosmético/estructural, no cambia diseño.

**OQ-RB4 — Ventana de invocación en `PREPARATION` (afinación).**
El MVP arranca con invocación solo-`CLIMAX` (Regla 7). Queda abierto si conviene permitir bendiciones defensivas/rally de *preparación* durante `PREPARATION` (posicionar antes del clímax) — el core loop del concepto menciona "decidir cuándo invocar" durante el posicionamiento. **Acción**: afinar en Pre-Producción/vertical slice tras playtest; el MVP valida solo-`CLIMAX` primero por simplicidad.

**OQ-RB5 — Forma exacta del panteón de prueba pre-sembrado (política ya decidida).**
**RESUELTO (política): el pool se puebla SOLO de reliquias de eras anteriores; nunca de muertes intra-era** (Regla 10). La cadena de legado es cross-era por naturaleza (muerte en era N → reliquia usable en era N+1); una muerte durante el CLIMAX en curso forja su reliquia pero no la vuelve draftable en la misma pelea (preserva el peso trágico y la curva de onboarding "las bendiciones no se exponen en la 1ª partida"). Para el MVP de una sola era esto obliga a **pre-sembrar un panteón de prueba** (roster de muertes de una "era 0" ficticia) — de lo contrario el pool arranca vacío y el sistema es inerte toda la partida. **Queda abierto solo el contenido del pre-sembrado**: cuántas reliquias (la MVP Definition del concepto pide "2-3 reliquias heredables"), y qué mezcla de `relic_category`×`tier` demuestra mejor el hook (idealmente ≥1 de cada categoría y ≥1 tier alto para exhibir la escalera). **Acción**: fijar el contenido del panteón de prueba al poblar el save inicial de la primera era; coordinar con Datos de Era/Civilización (roster) y con la hipótesis central del MVP. *(La política de "solo eras anteriores" ya no es una pregunta abierta.)*

**OQ-RB6 — Representación e implementación (→ ADR; parcialmente resuelto).**
**Ya decidido por ADR-0001/0002 (Accepted 2026-08-21):** la estructura del stack de modificadores de instancia (`StatModifier`/`CombatState`, dueño Combate) y la fuente de tick de expiración (`TimeControl.game_tick`, pause/scale-aware). **Queda abierto** para el ADR propio de este sistema: dónde vive el estado efímero de invocación en runtime (Autoload vs. nodo), el algoritmo exacto del techo de Legendaria por sorteo (sub-pool ponderado vs. reroll de exceso, Rule B/F-RB3), y el patrón de inyección del RNG semillado. **Acción**: crear ese ADR con `/architecture-decision` antes de implementar, coordinado con el ADR de Forja (OQ-FL4/FL5).

**OQ-RB7 — API exacta de refuerzo `rally` (firma) — tope de banda ✅ RESUELTO 2026-08-21 (F2-B5).**
El efecto `rally` invoca la API de spawn/reclutamiento de Sistema de Tropas; el comportamiento en tope de banda ya está decidido (no-op parcial, carga igual se gasta — AC-RB40). **La relación con el tope de banda quedó resuelta** (Fórmula E de `sistema-de-tropas.md`): el tope de tropas simultáneas es `max_band_size`, un valor **autorado por era** (propiedad de Datos de Era/Civilización); Tropas hace el enforcement y expone `band_headroom = max(0, max_band_size − alive_troop_count)`, read-only para este sistema. `rally` surte `spawned = min(rally_N, band_headroom)` tropas y nunca empuja las unidades vivas por encima de `max_band_size`; si `band_headroom == 0` es no-op (AC-RB40). Es un grifo independiente del presupuesto por-tipo/por-ciclo de PREPARATION (`max_reinforcements_[tipo]`); ambos respetan `max_band_size` como techo total (cierra F2-B5). **Queda abierto solo** la firma exacta de la API de spawn. **Acción**: confirmar la firma al implementar, contra `sistema-de-tropas.md` (Fórmula E, AC-32/33/34).

**OQ-RB8 — Validaciones de balance diferidas a vertical slice (economy-designer).**
Cuatro cosas quedan pendientes de validar contra datos que aún no existen: (a) el buff de banda `rally` contra el tamaño típico de banda en `CLIMAX` (sus números 2/3/5 son provisionales y no cross-validables hasta tener ese dato); (b) los efectos ofensivos/AoE contra los `CombatProfile` de esbirros (era-definidos, sin valores MVP aún); (c) `effect_duration_s=20` contra el timing real del ciclo del kaiju; (d) **dominancia cross-categoría** — medir la tasa de elección ofensivo vs. defensivo vs. `rally`; si ofensivo domina independientemente del contexto (valor incondicional > contingente), corregir subiendo el piso de valor del defensivo (p. ej. la mitigación plana diferida) o bajando el ofensivo (ver "Anclaje cross-categoría" en Formulas). **Acción**: afinar en vertical slice con telemetría/playtest; (d) es la validación que decide si el anclaje cross-categoría del MVP fue suficiente.

**OQ-RB9 — ✅ RESUELTO 2026-08-21 — ADR-0002 (Accepted).**
La cámara lenta de la oferta (`offering_time_scale`, Regla 7b) ralentiza la simulación completa (kaiju, telegrafío, unidades) de forma uniforme. **ADR-0002 (`docs/architecture/adr-0002-time-control-service.md`) lo resolvió**: el dueño del régimen de tiempo de juego es el servicio Core **TimeControl**; Reliquias/Bendiciones **solicita** el régimen `SLOWED` con `offering_time_scale` vía `request_regime(source_id, SLOWED)` mientras `OFFERING` está abierto, y lo libera al cerrar/cancelar — **no posee** el reloj. TimeControl NO usa `Engine.time_scale` ni `SceneTree.paused`: los consumidores escalan su delta por `time_scale` por polling. La expiración por tick (F-RB4) sigue correcta porque `TimeControl.game_tick` es un contador entero scale-aware. Exentos de la ralentización (corren en tiempo real): la UI de la oferta, el HUD, y el reloj del beat `DEATH_HOLD`. **Interacción con la pausa de muerte de Permadeath (`game_time_paused`) — precedencia ratificada como contrato.** Permadeath Regla 4 detiene el tiempo por completo (`game_time_paused=true`, input suprimido) en la muerte de un héroe. Si un héroe muere **durante** un `OFFERING` abierto (edge case reconocido), la **pausa total de Permadeath tiene precedencia** sobre la cámara lenta de la oferta: el `offering_time_scale` se suspende mientras dure la pausa de muerte, la oferta se **preserva** (no se cancela ni corre su soft-timeout durante la pausa), y reanuda su cámara lenta cuando la pausa de muerte termina. Razón: la muerte es el beat emocional mayor (Pilar 1) y Permadeath ya posee un stop total; anidar dos regímenes de tiempo con la muerte ganando es lo coherente. **Acción**: coordinar con technical-director/Temporizador/Combate **y Permadeath** (añadir Reliquias a la lista de consumidores de `game_time_paused` de Permadeath Regla 4); capturar en el ADR de patrón de este sistema (OQ-RB6). Bloquea la implementación de la Regla 7b (no el diseño).

**OQ-RB10 — Individuación de reliquias más allá de las 9 combinaciones categoría×tier (coordinación con Forja).**
El efecto y el `epitaph` de una reliquia derivan solo de `relic_category` × `tier` (9 combinaciones; `epitaph` de una tabla-plantilla de 9 entradas owned por Forja, AC-FL09). El canal glanceable (retrato + nombre del héroe, RV-2) individualiza la oferta en el momento de elegir, lo que **satisface el design-test mínimo** ("no intercambiable con un drop genérico") — pero dos reliquias del mismo categoría×tier siguen siendo mecánica y textualmente idénticas salvo por quién las forjó. Individuación más profunda (epitafios que citen la circunstancia específica de la muerte: qué kaiju, qué acción, a quién protegía) **requiere extender el dato que posee Forja**, no este sistema. **Acción**: recomendación cross-GDD para Forja de Legado — evaluar si el `epitaph` debe incorporar detalle por-muerte (más allá de la plantilla categoría×tier) para reforzar el Pilar 2. No bloquea el MVP (el canal glanceable basta para el design-test), pero es la vía para que el sistema supere su propio test con holgura, no al mínimo.
