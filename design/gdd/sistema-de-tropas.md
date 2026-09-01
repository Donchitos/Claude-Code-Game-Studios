# Sistema de Tropas

> **Status**: In Design
> **Author**: usuario + agentes
> **Last Updated**: 2026-07-23
> **Implements Pillar**: Sacrificio con Peso (Pilar 1); Preparación Ritual, Clímax Explosivo (Pilar 3)

## Overview

El Sistema de Tropas define y gobierna las unidades rasas del jugador: soldados uniformes que se instancian desde el `unit_roster` de la era activa (leído de Datos de Era/Civilización), se mueven por el mapa cuando reciben órdenes, y forman la masa numérica del ejército. A nivel de datos, cada tipo de tropa es una definición tipada con stats básicos (vida, velocidad, footprint de un tile) y un `unit_visual_radius_world` que el sistema de Control y Selección consume para resolver clics. A nivel de jugador, las tropas cumplen un rol emocional peculiar y deliberado: son **prescindibles por diseño**. Su uniformidad visual y su bajo costo individual (art bible Sección 5.1) existen precisamente para que gastarlas no genere fricción — y ese contraste es lo que hace que la muerte de un héroe *sí* pese (Pilar 1). Sin las tropas, no habría una "masa" contra la cual medir el valor único de un héroe; son el telón mortal sobre el que se recorta la tragedia.

## Player Fantasy

La fantasía de las tropas es la del **peso de los números** — la sensación de comandar una hueste, de ver una masa de soldados avanzar y chocar contra fuerzas mayores. Pero es una fantasía deliberadamente incompleta, y esa incompletitud es el punto. A diferencia de un RTS tradicional donde cada unidad puede llegar a importar, aquí las tropas están diseñadas para que el jugador *no* se encariñe con ninguna en particular. Son intercambiables, uniformes, sin nombre. El jugador las gasta como recurso, no como individuos. Esta frialdad calculada es lo que da forma al contraste emocional del juego (Pilar 1): cuando el jugador ha pasado horas gastando tropas sin remordimiento, la primera vez que un *héroe* —una unidad con nombre, silueta única y arco propio— está en peligro, la diferencia se siente en el cuerpo. Las tropas enseñan al jugador, a través de la repetición desapegada, qué se siente cuando algo *sí* importa. Su fantasía no es que las ames; es que su abundancia haga insoportable la escasez de lo que viene después.

## Detailed Design

### Core Rules

1. **Tipos de tropa data-driven**: cada tipo de tropa es una `Resource` tipada (`TroopDefinition`) con campos: `troop_id`, `troop_name`, `max_health`, `move_speed` (world units/sec), `unit_visual_radius_world` (consumido por Control y Selección, fórmula `select_radius`), `sprite_footprint` (1 tile por regla), y un rol táctico (`melee` / `ranged` / `support`). El MVP soporta **2-3 tipos** por civilización, leídos del `unit_roster` de la era ACTIVE.
2. **Aprovisionamiento por dotación fija + refuerzos limitados**: el jugador comienza cada era con un ejército definido por la `EraDefinition`. Durante la fase de **Preparación** (antes de que el temporizador del kaiju inicie), puede reclutar refuerzos hasta un tope (`max_reinforcements`). No hay construcción de base ni producción continua — coincide con el anti-pilar "no construcción de base masiva".
3. **Uniformidad deliberada**: todas las tropas del mismo tipo son mecánicamente idénticas — mismos stats, sin individualización, sin nombres, sin progresión individual. Esto es intencional (Pilar 1, art bible Sección 5.1): la masa debe sentirse intercambiable.
4. **Movimiento por orden**: las tropas se mueven solo cuando reciben una orden de Control y Selección (`move_commanded` resuelto a un destino de mundo). Cada tropa resuelve su propio pathfinding hacia el destino (vía `NavigationAgent2D`); no hay formación impuesta en el MVP — llegan al área del destino de forma orgánica.
5. **Prioridad de selección por debajo de héroes**: las tropas siempre ceden prioridad de selección a los héroes cercanos (regla ya fijada en Control y Selección) — un clic ambiguo nunca selecciona una tropa si hay un héroe en el radio.
6. **Muerte no permanente-narrativa**: la muerte de una tropa es definitiva dentro de una era (no reaparece), pero a diferencia de los héroes, **no dispara permadeath ni forja de legado** — una tropa muerta es solo una baja, no una tragedia. Esto es lo que las distingue mecánicamente de los héroes y protege el peso del Pilar 1.

### States and Transitions

| Estado | Descripción | Transición desde | Transición hacia |
|---|---|---|---|
| `IDLE` | En el campo, sin orden activa, en posición | Instanciación, llegada a destino | `MOVING`, `ENGAGED`, `DEAD` |
| `MOVING` | Ejecutando pathfinding hacia un destino ordenado | Orden de movimiento | `IDLE` (llega), `ENGAGED` (entra en combate), `DEAD` |
| `ENGAGED` | En combate (delegado a Combate/Daño) | Contacto con enemigo, orden de ataque | `IDLE` (enemigo muere/se retira), `MOVING` (orden de reposicionar), `DEAD` |
| `DEAD` | Vida ≤ 0, removida del campo | Cualquier estado al llegar vida a 0 | — (terminal; la selección se limpia si estaba seleccionada) |

- La resolución real del combate (cálculo de daño) pertenece a Combate/Daño; este sistema solo mantiene el estado y la vida de la tropa, y reacciona a los eventos de daño.

### Interactions with Other Systems

| Sistema | Dirección | Interfaz |
|---|---|---|
| Datos de Era/Civilización | Datos → este sistema | Lee `unit_roster` (porción de tropas) de la era ACTIVE para instanciar tipos |
| Control y Selección de Unidades | bidireccional | Provee posición/hitbox y `unit_visual_radius_world` para resolución de selección; recibe órdenes de movimiento para las tropas seleccionadas |
| Combate/Daño | bidireccional | Delega el cálculo de daño; recibe eventos de daño que reducen la vida de la tropa; notifica el estado `ENGAGED`/`DEAD` |
| Encuentro con Kaiju | este sistema → Kaiju | Las tropas son objetivos válidos para los ataques del kaiju/esbirros; expone posiciones para la IA del kaiju |
| Guardado/Persistencia | este sistema → Guardado | El conteo/estado de tropas vivas es parte del estado de era guardable (aunque las tropas individuales no son entidades de legado) |

*(Nota provisional: Combate/Daño y Encuentro con Kaiju aún no tienen GDD — esas interfaces son contratos propuestos. Datos de Era/Civilización, Control y Selección y Guardado/Persistencia SÍ están diseñados y sus contratos son confirmados.)*

## Formulas

### Stats base por tipo de tropa (MVP, tuneables)

Tres arquetipos, diferenciados solo por los tres campos que esta GDD posee (`max_health`, `move_speed`, tamaño de sprite → `unit_visual_radius_world`). Sin tipos de armadura ni resistencias — eso pertenece a Combate/Daño.

| Tipo | `sprite_diameter_px` | `max_health` | `move_speed` (u/s) | `unit_visual_radius_world` | Rol |
|---|---|---|---|---|---|
| Infantería melee | 44 | 40 | 4.0 | 0.4583 | Más resistente, más lenta, visualmente mayor — masa de vanguardia |
| A distancia (ranged) | 32 | 20 | 5.0 | 0.3333 | Más frágil, más rápida, visualmente menor — silueta de hostigamiento |
| Soporte | 40 | 28 | 4.5 | 0.4167 | Punto medio en los tres stats |

*(Nota de dependencia — ✅ RESUELTO 2026-08-09: los valores de `max_health` (melee = 2× ranged, soporte = 1.4× ranged) fueron confirmados por Combate/Daño: con sus `CombatProfile` los mirror-matchups quedan a ~5s entre sí (melee 5.0s, ranged 4.8s) — los golpes-para-matar se sienten correctos por tipo, no requieren revisión. Ver `combate-dano.md` Formulas.)*

### Fórmula A — Radio visual desde el tamaño de sprite

`unit_visual_radius_world = sprite_diameter_px / world_unit_scale / 2`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Diámetro de sprite | `sprite_diameter_px` | int | 32–48 (art bible) | Diámetro renderizado del sprite de este tipo |
| Escala de mundo | `world_unit_scale` | int | 48 (constante registrada) | px por world unit |
| **Radio visual** | `unit_visual_radius_world` | float | 0.33–0.5 (banda de tropa) | Mitad del diámetro clicable, en world units |

**Ejemplos**: melee `44/48/2 = 0.4583`; ranged `32/48/2 = 0.3333`; soporte `40/48/2 = 0.4167`. Estos valores se enchufan en la fórmula registrada `select_radius` (owned por Control y Selección) y todos quedan estrictamente por debajo del radio de héroe más pequeño (0.5), manteniendo la consistencia visual de la prioridad héroe>tropa.

### Fórmula B — Velocidad de movimiento relativa al paneo de cámara

`move_speed_troop = camera_pan_speed × speed_ratio_troop`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Velocidad de paneo | `camera_pan_speed` | float | 30 (constante registrada, u/s) | Velocidad de referencia que una tropa nunca debe acercarse/exceder |
| Ratio de velocidad | `speed_ratio_troop` | float | 0.10–0.20 (banda segura) | Fracción de la velocidad de paneo por tipo |
| **Velocidad de tropa** | `move_speed_troop` | float | 3.0–6.0 u/s | Velocidad de movimiento resultante |

**Ejemplos** (camera_pan_speed=30): melee `30×0.133 = 4.0`; soporte `30×0.150 = 4.5`; ranged `30×0.167 = 5.0`. Incluso la tropa más rápida (ranged, 5.0 u/s) es solo ~17% de la velocidad de paneo — margen de seguridad amplio, la cámara siempre supera a un grupo de tropas.

### Fórmula C — Tope de refuerzos por tipo (reset por ciclo de Preparación)

`max_reinforcements_[tipo] = clamp(round(starting_count_[tipo] × reinforcement_ratio), min_reinforcements, max_reinforcements_hard_cap)`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Conteo inicial del tipo | `starting_count_[tipo]` | int | ≥0 | Cantidad de ese tipo en el `unit_roster` al inicio de la era |
| Ratio de refuerzo | `reinforcement_ratio` | float | 0.15–0.35 (tuning knob) | Fracción de la fuerza inicial reclutable en Preparación |
| Piso de refuerzos | `min_reinforcements` | int | 2 (piso duro) | Evita resultados degenerados de 0-1 en rosters pequeños |
| Techo duro | `max_reinforcements_hard_cap` | int | 8 (techo por tipo) | Evita resultados desbocados en rosters grandes |
| **Tope por tipo** | `max_reinforcements_[tipo]` | int | [2, 8] | Refuerzos de ese tipo reclutables en esta Preparación |

**Decisiones fijadas**: tope **separado por tipo** (el jugador no puede convertir todos sus refuerzos en el tipo más fuerte) y **reset en cada ciclo de Preparación** (mantiene la tensión de atrición en cada beat). *(El reset por ciclo es provisional — depende del ritmo de Kaiju/Temporizador, aún sin GDD; si una era resulta tener un solo ciclo, el reset es equivalente a un presupuesto único.)*

**Ejemplo**: era con 10 melee, `reinforcement_ratio=0.25` → `round(10×0.25)=2.5→3` → `clamp(3, 2, 8) = 3` refuerzos melee disponibles esta Preparación. Con 6 ranged → `round(1.5)=2` → `clamp(2,2,8)=2` refuerzos ranged.

### Fórmula D — Umbral de muerte de tropa

`is_dead = (current_health <= 0)`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Vida actual | `current_health` | int | [0, max_health] | Reducida solo por eventos de daño de Combate/Daño |
| ¿Muerta? | `is_dead` | bool | {true, false} | Si la tropa transiciona a `DEAD` este frame |

Trivial pero formal. **No se captura data de circunstancia de muerte** — sin `killer_id`, ubicación, timestamp ni causa. Esta es la distinción mecánica deliberada respecto a los héroes (Pilar 1) y evita cualquier acoplamiento accidental al sistema de legado/forja. Combate/Daño hace clamp de `current_health` a un mínimo de 0 al aplicar daño, para que `DEAD` dispare exactamente en el cruce por 0.

### Fórmula E — Tope de banda del jugador y `band_headroom`

El tope de **tropas** simultáneas vivas del jugador es un valor autorado por era, `max_band_size` (propiedad de Datos de Era/Civilización). Este sistema es el dueño del **enforcement** y expone el margen restante:

`band_headroom = max(0, max_band_size − alive_troop_count)`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Tope de banda | `max_band_size` | int | `≥ Σ starting_count_[tipo]` | Máx. tropas simultáneas vivas del jugador esta era. Propiedad de Datos de Era (validado loud-fail al cargar). **NO cuenta héroes** |
| Tropas vivas | `alive_troop_count` | int | `[0, max_band_size]` | Conteo actual de tropas vivas del jugador (todos los tipos), propiedad de este sistema |
| Margen de banda | `band_headroom` | int | `[0, max_band_size]` | Read-only para Reliquias (`rally`) y UI/HUD (RU-3b) |

**Reconciliación de los dos grifos de refuerzo (cierra F2-B5 / Reliquias OQ-RB7-b):** dos mecánicas distintas alimentan la banda, y ambas respetan `max_band_size` como techo total:
- **Reclutamiento en PREPARACIÓN** (Fórmula C): acotado **por tipo y por ciclo** (`max_reinforcements_[tipo]`) **y además** por el gate global — una recluta se rechaza si `band_headroom == 0`, aunque el tope por tipo aún no se haya alcanzado.
- **`rally` en CLIMAX** (Reliquias): surte `spawned = min(rally_N, band_headroom)` tropas instantáneas; si `band_headroom == 0` es no-op (Reliquias AC-RB40 — la carga se gasta igual). `rally` **no** consume del presupuesto por-tipo/por-ciclo de Preparación; es un grifo independiente, acotado solo por `max_band_size`.

Los dos son complementarios: el tope por tipo/ciclo throttlea la *recuperación de atrición* en Preparación; `max_band_size` acota el *total en campo* en todo momento (Preparación y CLIMAX). El cap es sobre la masa reemplazable (tropas), no sobre el roster con nombre (héroes).

**Ejemplo**: `max_band_size=30`, 16 tropas iniciales; tras bajas quedan 22 vivas → `band_headroom=8`. Un `rally` Legendaria (`N=5`) surte 5 (→27 vivas, headroom 3). Un `rally` Sólida (`N=3`) surte `min(3,3)=3` (→30, headroom 0). Un tercer `rally` es no-op, carga gastada.

## Edge Cases

- **Si el jugador intenta reclutar más refuerzos de un tipo que su `max_reinforcements_[tipo]`**: la recluta se bloquea al alcanzar el tope; la UI no debe permitir exceder el límite. No es un error, es el comportamiento esperado.
- **Si `starting_count_[tipo]` es 0** (la era no incluye ese tipo): un tipo ausente del `unit_roster` de la era tiene tope de refuerzo **0**, no se ofrece en absoluto — el piso de 2 de la Fórmula C solo aplica a tipos que **sí** existen en la era.
- **Si `band_headroom == 0`** (la banda está en su tope `max_band_size`, Fórmula E): el reclutamiento de Preparación se rechaza globalmente **aunque el tope por tipo aún no se haya alcanzado**, y un `rally` de CLIMAX es no-op (surte 0 tropas). No es un error — es el techo total de banda. En `rally`, la carga se gasta igual (Reliquias AC-RB40).
- **Si una tropa muere mientras estaba seleccionada**: se remueve del conjunto de selección (Control y Selección limpia la referencia el mismo frame, cubierto por su AC-18/19). Si era la última seleccionada, el estado pasa a `NONE_SELECTED`.
- **Si una tropa recibe una orden de movimiento a un destino inalcanzable** (bloqueado por geometría del mapa): `NavigationAgent2D` la lleva al punto navegable más cercano al destino; la tropa entra en `IDLE` ahí, no queda atascada en `MOVING` indefinidamente.
- **Si dos tropas intentan ocupar el mismo tile simultáneamente**: el avoidance del pathfinding de Godot las separa orgánicamente; no hay apilamiento perfecto ni bloqueo mutuo. Sin formación impuesta en el MVP, la resolución exacta la maneja `NavigationAgent2D`.
- **Si la vida de una tropa es reducida por debajo de 0 en un solo golpe** (overkill): Combate/Daño hace clamp a 0; `is_dead` dispara en el cruce por 0. No se preserva vida negativa en el estado.
- **Si el jugador ordena mover una tropa durante `DEATH_HOLD`** (beat de muerte de héroe): el Input ya suprime todo input durante `DEATH_HOLD` (edge case fijado en Input) — la orden nunca llega a este sistema.
- **Si todas las tropas del jugador mueren pero un héroe sigue vivo**: la era continúa; no hay condición de derrota por pérdida total de tropas (los héroes son el eje de la victoria/derrota, no la masa). El jugador simplemente pelea solo con héroes.
- **Si un tipo de tropa tiene `move_speed` mal configurado por encima de `camera_pan_speed`** (error de tuning): se clampa `speed_ratio_troop` a su banda segura [0.10, 0.20] al cargar, garantizando que ninguna tropa pueda superar a la cámara.

## Dependencies

**Dependencias hacia arriba (upstream):**

| Sistema | Tipo | Interfaz | Estado |
|---|---|---|---|
| Datos de Era/Civilización | Dura | Lee `unit_roster` (porción de tropas) de la era ACTIVE para instanciar tipos | ✅ Diseñado |
| Control y Selección de Unidades | Dura (bidireccional) | Provee posición/hitbox y `unit_visual_radius_world`; recibe órdenes de movimiento de él | ✅ Diseñado — contrato confirmado (`select_radius` registrada) |

**Dependientes hacia abajo (downstream):**

| Sistema | Tipo | Interfaz |
|---|---|---|
| Combate/Daño | Dura (bidireccional) | Delega cálculo de daño; recibe eventos de daño que reducen vida; notifica `ENGAGED`/`DEAD` |
| Encuentro con Kaiju | Dura | Las tropas son objetivos válidos del kaiju/esbirros; expone posiciones para la IA del kaiju |
| Guardado/Persistencia | Dura | El conteo/estado de tropas vivas es parte del estado de era guardable (las tropas no son entidades de legado) |
| Reliquias/Bendiciones | Dura (efecto `rally`) | El efecto `rally` invoca la API de refuerzo/spawn de tropas de este sistema y surte `min(rally_N, band_headroom)` tropas (**F2-B5 resuelto 2026-08-21**: `max_band_size` autorado por Datos de Era es el techo total; este sistema expone `band_headroom` read-only y hace el enforcement — Fórmula E). `rally` es un grifo independiente del refuerzo por-tipo de Preparación. La firma exacta de la API sigue siendo detalle de implementación (Reliquias OQ-RB7-a). Los modificadores de instancia de bendición se aplican vía la capa `CombatState` de Combate (ADR-0001), no directo a este sistema |

**Nota bidireccional (actualizada 2026-08-21)**: Combate/Daño, Encuentro con Kaiju y Reliquias/Bendiciones **ya tienen GDD** — sus contratos están confirmados (la fila recíproca de Reliquias se añadió en la reconciliación cross-GDD, cierra parte de Reliquias OQ-RB3). Datos de Era/Civilización, Control y Selección y Guardado/Persistencia también.

## Tuning Knobs

| Knob | Símbolo | Tipo | Default | Rango seguro | Qué se rompe en extremos |
|---|---|---|---|---|---|
| Ratio de refuerzo | `reinforcement_ratio` | float | 0.25 | 0.15–0.35 | <0.15: la atrición se siente irrecuperable, frustrante; >0.35: reemplazar bajas es trivial, se pierde la tensión del Pilar 1 |
| Ratio de velocidad por tipo | `speed_ratio_troop` | float | 0.13–0.17 (por tipo) | 0.10–0.20 | <0.10: las tropas se sienten pegajosas/lentas; >0.20: se acercan a superar la cámara, sensación de descontrol |
| Piso de refuerzos | `min_reinforcements` | int | 2 | 1–3 | 0: rosters pequeños quedan sin margen de recuperación; >3: infla refuerzos en rosters diminutos |
| Techo duro de refuerzos por tipo | `max_reinforcements_hard_cap` | int | 8 | 5–12 | <5: limita demasiado en eras grandes; >12: permite masas de refuerzo que diluyen la tensión |

Los stats por-tipo (`max_health`, `move_speed`, `sprite_diameter_px`) también son tuneables por tipo de tropa (viven en cada `TroopDefinition` Resource), pero son datos de contenido, no knobs globales del sistema.

**Enforcement**: los valores fuera de rango se clampan al límite más cercano al cargar (consistente con Guardado/Persistencia y Control y Selección).

**Constantes/valores consumidos** (no se duplican): `camera_pan_speed`=30, `world_unit_scale`=48 y `max_band_size` (autorado por era) → propiedad de Datos de Era/Civilización (registradas). `max_band_size` es el techo total de la Fórmula E; este sistema lo consume y hace el enforcement, no lo posee.

## Visual/Audio Requirements

La dirección visual de las tropas ya está autorada a fondo en el **art bible Sección 5.1** (producto del art-director) — se referencia aquí como fuente de verdad en vez de re-especificarla:
- **Silueta**: "astilla vertical" uniforme e indiferenciada — todas las tropas del mismo tipo comparten silueta idéntica (art bible 5.1, 3.1). Sub-diseño deliberado: son la masa gastable.
- **Color**: Hueso (aliado, con vida) por defecto; drena hacia Sangre Vieja al recibir daño (art bible 4.2). Nunca dorado — las tropas no son entidades de legado.
- **Escala**: 32-48px, encajan en tiles de 48px (art bible 8.3). Nivel de LOD 1 únicamente — sin renderizado de detalle Nivel 2 (reservado para permadeath de héroes; las tropas nunca lo activan, art bible 8.4).
- **VFX de este sistema**: feedback de daño (destello breve), muerte de tropa (efecto de caída/disolución acorde al gótico pixelado — pero deliberadamente menos dramático que la muerte de un héroe, sin beat sostenido). Distinción clave: la muerte de una tropa NUNCA debe verse tan significativa como la de un héroe (refuerza el Pilar 1).
- **Audio**: las tropas emiten señales que el sistema de Audio escucha (orden de movimiento, contacto, muerte) — este sistema provee el disparador, no el sonido. La muerte de tropa tiene un sonido más tenue/masivo que la de un héroe.

📌 **Asset Spec** — Requisitos Visual/Audio definidos. Tras aprobar el art bible, ejecutar `/asset-spec system:sistema-de-tropas` para producir descripciones visuales por-asset, dimensiones y prompts de generación desde esta sección.

## UI Requirements

- **Contador de refuerzos por tipo**: durante Preparación, la UI muestra cuántos refuerzos de cada tipo quedan disponibles (`max_reinforcements_[tipo]` menos los ya reclutados). No debe permitir exceder el tope (AC-18). Su diseño visual pertenece a la GDD de UI/HUD (lenguaje diegético del art bible Sección 7).
- **Indicador de vida de tropa**: barra/indicador de vida por tropa (Hueso→Sangre Vieja), renderizado por UI/HUD desde el estado que este sistema expone.
- **Indicador de selección**: cuando una tropa está seleccionada, la UI muestra el contorno de selección (delegado a Control y Selección + UI/HUD).

📌 **UX Flag — Sistema de Tropas**: Este sistema tiene requisitos de UI (contador de refuerzos, indicador de vida). En Pre-Producción, ejecutar `/ux-design` para especificar el contador de refuerzos de Preparación antes de escribir epics. Las stories que referencien esta UI deben citar `design/ux/[pantalla].md`.

## Acceptance Criteria

*(Validado por `qa-lead`. Criterios [BLOQUEADO] no testeables hasta que exista la GDD del sistema mencionado.)*

### Core Rules

**AC-01**. Given una era cuyo `unit_roster` lista 3 tipos (melee, ranged, soporte), When la era carga e instancia tropas, Then se instancian exactamente los tipos presentes en `unit_roster` — ni más ni menos — cada uno con su `TroopDefinition` completo, y ningún tipo fuera del roster de la era ACTIVE se instancia.

**AC-02** [Integration, hueco de fase Preparación]. Given una era en Preparación con `starting_count_melee`=10 y `max_reinforcements_melee`=3, When el jugador recluta, Then se pueden reclutar hasta 3 tropas melee adicionales, nunca se expone producción continua/construcción de base, y los intentos más allá del tope se rechazan.

**AC-03**. Given dos tropas melee A y B del mismo `TroopDefinition`, When se comparan sus stats, Then todos los campos son idénticos, y ninguna expone nombre individualizado, progresión única, ni campo de historial de muerte.

**AC-04**. Given una tropa idle seleccionada, When se emite una orden de movimiento a la posición P, Then su `NavigationAgent2D` navega a P independientemente de cualquier otra tropa seleccionada, sin offset de formación.

**AC-05**. Given un héroe y una tropa ambos dentro del radio de clic del cursor, When el jugador hace clic en esa posición ambigua, Then se selecciona el héroe y no la tropa (cross-ref: prioridad héroe>tropa de Control y Selección) — confirma que `unit_visual_radius_world` nunca anula esa prioridad.

**AC-06** [BLOQUEANTE, Pilar 1 — test negativo]. Given la vida de una tropa llega a 0, When transiciona a `DEAD`, Then no dispara resolución de permadeath, no se crea entrada de Forja de Legado, y no se registra ningún campo de circunstancia de muerte (`killer_id`, ubicación, timestamp, causa) en ninguna parte; **y como caso de control en la misma corrida de test, un héroe llegando a 0 de vida SÍ dispara el camino de permadeath/legado** — probando que la distinción se hace cumplir, no que está ausente por omisión. *(Test de regresión automatizado. Un refactor futuro que fusione el manejo de muerte de héroe/tropa es la forma más plausible de romper silenciosamente el Pilar 1.)*

### States and Transitions

**AC-07**. Given una tropa en `IDLE`, When recibe una orden de movimiento válida, Then transiciona a `MOVING` el mismo frame y `NavigationAgent2D` comienza a navegar.

**AC-08**. Given una tropa en `MOVING`, When `NavigationAgent2D` reporta llegada, Then transiciona a `IDLE` y deja de emitir input de movimiento.

**AC-09** [BLOQUEADO — pendiente GDD de Combate/Daño]. Given una tropa en `MOVING` o `IDLE`, When contacta un enemigo o recibe una orden de ataque según el contrato de contacto de Combate/Daño, Then transiciona a `ENGAGED`. *(Interim: mock de señal `contact_detected`, test Logic solo.)*

**AC-10**. Given una tropa en `IDLE`, `MOVING` o `ENGAGED` con `current_health` en 0, When se procesa la actualización de vida, Then transiciona a `DEAD` incondicionalmente y `DEAD` es terminal. *(Testeable hoy vía mutación directa de vida — no requiere la lógica de aplicación de daño de Combate/Daño.)*

**AC-11** [BLOQUEADO — pendiente GDD de Combate/Daño]. Given una tropa en `ENGAGED`, When el enemigo muere o se retira según la resolución de Combate/Daño, Then transiciona a `IDLE`. *(Interim mock, test Logic solo.)*

### Formulas

**AC-12**. Given `sprite_diameter_px` = 44/32/40 y `world_unit_scale`=48, When se computa `unit_visual_radius_world = sprite_diameter_px/world_unit_scale/2`, Then los resultados son exactamente 0.4583 (melee), 0.3333 (ranged), 0.4167 (soporte), ±0.0001, y los tres estrictamente por debajo del radio de héroe más pequeño (0.5).

**AC-13**. Given `camera_pan_speed`=30 y `speed_ratio_troop`=0.133 (melee), When se computa `move_speed_troop = camera_pan_speed × speed_ratio_troop`, Then el resultado es 4.0 u/s (±0.01); ratio 0.150 (soporte) → 4.5; ratio 0.167 (ranged) → 5.0.

**AC-14** [invariante]. Given cada `TroopDefinition` definido y cualquier tipo futuro con `speed_ratio_troop`∈[0.10, 0.20], When se computa `move_speed_troop` para cada uno, Then todo resultado es estrictamente menor a 30 u/s — la tropa más rápida (ranged, 5.0) es ~17% de la velocidad de cámara, y el tope de la banda (0.20×30=6.0) sigue por debajo. *(Test de regresión de roster completo, re-correr al añadir un tipo.)*

**AC-15**. Given `starting_count_melee`=10, `reinforcement_ratio`=0.25, When se computa `max_reinforcements_melee = clamp(round(10×0.25), 2, 8)`, Then `round(2.5)=3`, `clamp(3,2,8)=3` → tope 3; con `starting_count_ranged`=6 mismo ratio, `round(1.5)=2`, `clamp(2,2,8)=2` → tope 2.

**AC-16**. Given un `unit_roster` con cero entradas de "soporte" (`starting_count_support`=0), When se computa `max_reinforcements_support`, Then el resultado es 0 — el piso `min_reinforcements` de 2 NO aplica a un tipo ausente de la era, y soporte no se ofrece como opción de refuerzo.

**AC-17**. Given una tropa con `current_health`=1, When se reduce a 0 por un evento de daño, Then `is_dead` evalúa true y entra a `DEAD` en la misma actualización; con `current_health`=0 exacto (borde), `is_dead` también es true (umbral es `<=`, no `<` estricto).

### Edge Cases

**AC-18** (EC-01). Given `max_reinforcements_melee`=3 y 3 ya reclutados este ciclo de Preparación, When se intenta un 4to, Then la acción se rechaza y el conteo queda en 3. *(Lógica de enforcement testeable ahora; el gating de UI "no debe permitir" bloqueado — ver huecos.)*

**AC-19** (EC-02). Given un tipo con cero entradas en el roster de la era, When se consulta su tope de refuerzo en Preparación, Then el tope es 0 y nunca aparece como opción reclutable.

**AC-20** (EC-03). Given una tropa en el conjunto de selección, When llega a `DEAD`, Then se remueve del conjunto el mismo frame; si era la única, la selección pasa a `NONE_SELECTED` (cross-ref: Control y Selección AC-18/19).

**AC-21** (EC-04). Given una orden de movimiento a un destino bloqueado por geometría del mapa, When `NavigationAgent2D` la procesa, Then la tropa navega al punto navegable más cercano y entra a `IDLE` ahí — no queda en `MOVING` indefinidamente.

**AC-22** (EC-05) [correctitud bloqueante; suavidad visual advisory]. Given dos tropas ordenadas al mismo tile, When ambas llegan en proximidad, Then el avoidance las separa en posiciones no superpuestas sin apilamiento permanente ni deadlock mutuo (ambas eventualmente en `IDLE`, verificable en simulación headless con assertion de timeout).

**AC-23** (EC-06) [threshold testeable; clamp bloqueado hasta Combate/Daño]. Given `current_health`=5, When se aplica un evento de 999 de daño, Then `current_health` hace clamp a 0 (nunca negativo) e `is_dead` evalúa true esa actualización.

**AC-24** (EC-07). Given un héroe en `DEATH_HOLD`, When el jugador intenta mover una tropa, Then el Input suprime el input por completo y el Sistema de Tropas nunca recibe un evento `move_commanded`. *(Recomendado: este test vive en la suite de Input, con el handler de movimiento de tropas como receptor espiado.)*

**AC-25** (EC-08) [BLOQUEADO — nadie posee la evaluación de victoria/derrota de era]. Given todas las tropas en `DEAD` y ≥1 héroe vivo, When se evalúa la condición de victoria/derrota de la era, Then no se dispara derrota por pérdida total de tropas y la era continúa.

**AC-26** (EC-09). Given un `TroopDefinition` cargado con `speed_ratio_troop`=0.45 (fuera de [0.10, 0.20]), When carga, Then el ratio se clampa a 0.20 y se usa `move_speed_troop` = 30×0.20 = 6.0 u/s.

### Save/Load (ambos sistemas diseñados — cobertura testeable hoy)

**AC-31** [Integration con Guardado/Persistencia]. Given N tropas de cada tipo vivas a mitad de era, When el juego guarda y recarga, Then se restauran las mismas N tropas de los mismos tipos/estados (excluyendo data de circunstancia de muerte, que no existe per AC-06).

### Tuning Knobs (clamping)

**AC-27**. Given `reinforcement_ratio` configurado en 0.50, When carga, Then se clampa a 0.35 y la Fórmula C usa 0.35.
**AC-28**. Given `speed_ratio_troop` configurado en 0.05, When carga, Then se clampa a 0.10 y `move_speed_troop` = 30×0.10 = 3.0 u/s.
**AC-29**. Given `min_reinforcements` configurado en 0, When carga, Then se clampa a 1.
**AC-30**. Given `max_reinforcements_hard_cap` configurado en 20, When carga, Then se clampa a 12.

**AC-32** (Fórmula E) [Logic/unit]. Given `max_band_size`=30 y `alive_troop_count`=22, When se consulta `band_headroom`, Then es `8`; y dado un `rally` con `rally_N`=5, When resuelve, Then surte `min(5,8)=5` tropas y `alive_troop_count` pasa a 27.

**AC-33** (Fórmula E, gate global) [Logic/unit]. Given `band_headroom`=0 (`alive_troop_count == max_band_size`), When el jugador intenta reclutar un refuerzo en Preparación de un tipo cuyo `max_reinforcements_[tipo]` **aún no** está agotado, Then la recluta se rechaza igual (gate global de banda); y When se invoca un `rally` de CLIMAX, Then surte 0 tropas (no-op) — la carga de invocación se gasta igual (cross-ref Reliquias AC-RB40).

**AC-34** (Fórmula E, validación de config) [Logic/unit]. Given una `EraDefinition` con `max_band_size` menor que `Σ starting_count_[tipo]` del `unit_roster`, When se carga la era, Then falla ruidosamente (loud-fail, el roster inicial no cabe en el tope) — validado en el camino de carga centralizado de era (mismo patrón que los checks cross-resource de Kaiju AC-K74/K85).

### Clasificación de tipo de story (para el gate de evidencia)

| AC # | Tipo | Evidencia | Gate |
|---|---|---|---|
| AC-03, AC-06, AC-07, AC-08, AC-10, AC-12 a AC-19, AC-23 (mitad threshold), AC-26 a AC-30 | Logic | Unit test (`tests/unit/troops/`) | Bloqueante |
| AC-01, AC-02, AC-04, AC-05, AC-20, AC-21, AC-22, AC-24, AC-31 | Integration | Integration test / playtest documentado | Bloqueante |
| AC-09, AC-11, AC-25 | Integration | Bloqueado, ver huecos | Bloqueante (diferido) |
| AC-18 (mitad UI), AC-22 (suavidad visual) | UI / Visual | Walkthrough / screenshot + sign-off | Advisory |

**AC-06 es la excepción a la fuerza normal de gating Logic**: aunque es un test Logic, es **bloqueante y crítico de Pilar 1** — cualquier PR que toque los caminos de muerte de héroe/tropa debe requerir que este test corra, no solo que CI pase incidentalmente.

### Huecos/no-testeables marcados

1. **AC-09/AC-11** (transiciones ENGAGED) bloqueados hasta el contrato de contacto/resolución de Combate/Daño. Interim: tests Logic con señal simulada.
2. **AC-23** (clamp de overkill) — el mecanismo de clamp a 0 lo posee Combate/Daño; bloqueado para end-to-end.
3. **AC-25** (pérdida total de tropas ≠ derrota) — bloqueado, y es un hueco de la tabla de dependencias: ningún sistema listado posee la evaluación de victoria/derrota de era (probablemente Transición de Era o Encuentro con Kaiju).

## Open Questions

| Pregunta | Owner | Resolución objetivo |
|---|---|---|
| ~~¿Qué sistema posee la evaluación de victoria/derrota de era? (bloquea AC-25 — "pérdida total de tropas ≠ derrota")~~ ✅ **RESUELTO 2026-08-12**: Encuentro con Kaiju (Approved) es el dueño (Regla 9) y confirma directamente que **las tropas NO son condición de derrota** (AC-K53) — la derrota es la muerte del último héroe vivo, aunque queden tropas. Desbloquea AC-25 | game-designer | ✅ Cerrado (Encuentro Regla 9/AC-K53) |
| ¿Qué sistema posee la fase de Preparación y su temporizador? (afecta AC-02 y el reset por-ciclo de refuerzos) — referenciado como "fase de Preparación" pero sin owner en la tabla de dependencias | game-designer | Al diseñar Temporizador de Preparación/Ritual |
| El reset de refuerzos por ciclo de Preparación depende del ritmo de Kaiju/Temporizador (ambos **Approved**). Encuentro con Kaiju usa un reloj de clímax propio (`climax_elapsed_s`) independiente del de Temporizador; el número de ciclos de Preparación por era es un dato de `EraDefinition`. Si una era tiene un solo ciclo, el reset equivale a un presupuesto único | game-designer | Al fijar el ritmo de era (Datos de Era) |
| La interfaz "las tropas exponen posiciones al kaiju" — Encuentro con Kaiju (**Approved**) la concreta: las tropas son candidatos de la selección de objetivo por amenaza del kaiju (Regla 3/F1, con `hero_threat_bonus` favoreciendo héroes sobre tropas). Ya no es una fila de dependencia sin mecánica | game-designer | ✅ Cubierto por Encuentro Regla 3 |
| ~~Los `max_health` por tipo son baselines provisionales — revisar cuando Combate/Daño defina daño-por-golpe~~ ✅ **RESUELTO 2026-08-09**: Combate/Daño confirmó que los baselines se sostienen (mirror-matchups ~5s); sin revisión requerida | systems-designer | ✅ Cerrado |
| El contrato de contacto/aggro (qué dispara `ENGAGED`) lo define Combate/Daño — bloquea AC-09/AC-11 | game-designer | Al diseñar Combate/Daño |
