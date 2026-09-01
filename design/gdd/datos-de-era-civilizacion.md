# Datos de Era/Civilización

> **Status**: In Design
> **Author**: usuario + agentes
> **Last Updated**: 2026-08-16 — `EraDefinition` gana el accesor derivado `get_hero_roster_count()` (nuevo AC-1b) + fila de Interactions/Dependencies para Permadeath; cierra `design/gdd/permadeath.md` OQ-P6 #6. Previo: 2026-08-09 — schema de `EraDefinition` ampliado con `approach_duration_s`/`imminent_window_s` (contrato con Temporizador de Preparación/Ritual confirmado tras su design-review)
> **Implements Pillar**: El Pasado es Poder (Pilar 2); Historia Jugada, No Contada (Pilar 4)

## Overview

El sistema de Datos de Era/Civilización es la capa de contenido estático que define cada "capítulo" jugable del juego: qué civilización es, qué roster de tropas y héroes tiene disponibles, qué kaiju la amenaza, y qué vocabulario visual de tileset usa (art bible Sección 6.1). No contiene lógica de juego — es una colección de definiciones tipadas (`Resource` de Godot) que otros sistemas consultan para saber "qué existe en esta era". Cada era también registra qué reliquias de eras anteriores pueden aparecer como props persistentes (Pilar 2), y qué constantes de escala del mundo (`world_unit_scale`, ver Open Questions del GDD de Input) rigen su geometría. Sin este sistema, ningún otro sistema del juego sabría qué unidades, kaiju o entorno cargar para la civilización actual — es el sistema del que depende la mayor cantidad de otros sistemas del MVP.

## Player Fantasy

Este sistema no tiene una fantasía propia — su fantasía es prestada de todo lo que hace posible. Cuando el jugador entra a una nueva era y ve un roster de unidades distinto, un kaiju con silueta y comportamiento únicos, y un entorno que reutiliza el vocabulario angular-gótico con acentos de temperatura de color propios (art bible Sección 4.3), está sintiendo el trabajo de este sistema sin saber que existe. Su responsabilidad silenciosa conecta directamente con el Pilar 2 (El Pasado es Poder): es este sistema el que hace posible que una reliquia forjada en la Era 1 aparezca como prop arquitectónico literal en la Era 3 — la sensación de "esto es historia acumulada, no contenido genérico" depende enteramente de que estos datos estén bien estructurados y correctamente vinculados entre eras.

## Detailed Design

### Core Rules

1. **`EraDefinition` como Resource tipado**: cada era es un `Resource` de Godot (`.tres`) con campos: `era_id`, `era_name`, `civilization_name`, `narrative_order` (índice de secuencia), `unit_roster` (referencias a definiciones de tropa/héroe), `kaiju_definition` (referencia), `tileset_vocabulary` (referencia a assets de arte, art bible Sección 6.1), `color_accent` (desplazamiento de Ocre/Piedra por era, art bible Sección 4.3), `legacy_props` (lista de IDs de reliquias de eras anteriores que pueden aparecer como props), `world_unit_scale` (constante que resuelve la pregunta abierta del GDD de Input), `approach_duration_s` (float, segundos totales del acercamiento del kaiju antes del clímax — consumido por Temporizador de Preparación/Ritual F1), `imminent_window_s` (float, duración de la ventana final de aviso `IMMINENT` antes del clímax — consumido por Temporizador de Preparación/Ritual F3), `max_band_size` (int, **tope de tropas simultáneas vivas del jugador** en esta era — dueño de este campo; NO cuenta héroes; consumido por Sistema de Tropas Fórmula E y por el efecto `rally` de Reliquias/Bendiciones vía `band_headroom`). La validación de rango de estos dos últimos (`approach_duration_s > 0`, `0 < imminent_window_s < approach_duration_s`, loud-fail si inválidos) es responsabilidad del Temporizador de Preparación/Ritual al inicializarse (ver ese GDD, Edge Cases/AC-T17/AC-T18) — este sistema solo garantiza que los campos existen con el tipo correcto (float). **Accesor derivado (contrato nuevo con Permadeath, 2026-08-16 — cierra OQ-P6 #6 de `design/gdd/permadeath.md`):** `EraDefinition` expone `get_hero_roster_count() -> int`, calculado leyendo la porción de héroes de `unit_roster` en el momento en que la era alcanza `LOADED` — no es un campo autoral nuevo ni una copia, deriva del mismo dato que Sistema de Héroes ya consume, evitando una segunda fuente de verdad que pudiera desincronizarse del roster real. Es el único dato que Permadeath lee de este sistema, usado exclusivamente para validar la feasibilidad de su cap de bloqueo total (`death_hold_total_lockout_cap_s ≥ N_max × death_hold_min_compressed_s`, Permadeath Regla 8) — no participa de ninguna lógica de contenido de este sistema. **Validación de `max_band_size` (cross-resource, loud-fail al cargar la era — 2026-08-21):** `max_band_size ≥ Σ starting_count_[tipo]` sobre el `unit_roster` (el roster inicial de tropas debe caber en el tope, o la era está rota) — se valida en el mismo camino de carga centralizado que los checks cross-resource de Kaiju (AC-K74/K85). Advisory (warning, no fail, mismo patrón que el tier-3 del Temporizador): `max_band_size + max_concurrent_esbirros` debería quedar dentro del presupuesto de entidades en pantalla (legibilidad/perf — art bible; Kaiju TR/AC-K84).
2. **100% autoral, sin generación procedural**: coincide con el Pilar 4 y el Anti-Pilar del concepto — cada era se define a mano, nunca se genera. La única aleatoriedad del juego vive en Reliquias/Bendiciones, no aquí.
3. **Inmutable en runtime**: las definiciones de era son datos de solo lectura cargados desde Resources. El estado mutable (qué reliquias se ganaron, qué era está activa) vive en Guardado/Persistencia, que referencia estos datos por `era_id`, nunca los duplica.
4. **Props de legado por referencia, no por copia**: `legacy_props` almacena IDs de reliquia, no una copia embebida — evita duplicación de datos y mantiene a Forja de Legado como única fuente de verdad de qué reliquias existen.
5. **Data-driven, nunca hardcodeado**: coincide con el estándar de codificación del proyecto — ningún sistema consumidor debe tener nombres de era, kaiju o unidades escritos en código; todo se resuelve vía referencias a `EraDefinition`.

### States and Transitions

| Estado | Descripción | Transición desde | Transición hacia |
|---|---|---|---|
| `UNLOADED` | La era existe como definición en disco, no cargada en memoria | — | `LOADING` (al iniciarse la era o precargarse) |
| `LOADING` | Godot está deserializando el Resource y sus referencias | `UNLOADED` | `LOADED` |
| `LOADED` | Datos en memoria, disponibles para consulta, pero no es la era jugada actualmente | `LOADING`, `ACTIVE` (al salir) | `ACTIVE`, `UNLOADED` (descarga) |
| `ACTIVE` | Es la era actualmente jugada — sus datos alimentan Tropas, Héroes, Kaiju, Temporizador | `LOADED` | `ARCHIVED` (al completarse la era) |
| `ARCHIVED` | La era ya se jugó; sus datos siguen disponibles solo para consulta de legado (props, panteón) | `ACTIVE` | — (permanece archivada) |

### Interactions with Other Systems

| Sistema | Dirección | Interfaz |
|---|---|---|
| Sistema de Tropas | Datos → consumidor | Lee `unit_roster` (porción de tropas) y `max_band_size` (tope de tropas simultáneas) de la era `ACTIVE` |
| Sistema de Héroes | Datos → consumidor | Lee `unit_roster` (porción de héroes) de la era `ACTIVE` |
| Encuentro con Kaiju | Datos → consumidor | Lee `kaiju_definition` de la era `ACTIVE` |
| Temporizador de Preparación/Ritual | Datos → consumidor | Lee `approach_duration_s` e `imminent_window_s` de la era `ACTIVE` |
| Transición de Era | bidireccional | Lee `narrative_order` para determinar la siguiente era; marca la era actual como `ARCHIVED` |
| Narrativa Ambiental | Datos → consumidor | Lee `legacy_props` y `tileset_vocabulary` para poblar props de eras anteriores |
| Guardado/Persistencia | bidireccional | Este sistema provee datos inmutables; Guardado/Persistencia almacena qué `era_id` está activa/completada, nunca copia los datos de era en sí |
| Permadeath | Datos → consumidor (solo lectura) | Lee `get_hero_roster_count()` de la era `ACTIVE` sobre la señal era-`LOADED` (no en el `_ready()` de Permadeath) para validar la feasibilidad de su cap de bloqueo total (Regla 8 de `design/gdd/permadeath.md`) — la única lectura cross-system de Permadeath. *(Contrato nuevo, 2026-08-16 — cierra OQ-P6 #6)* |

*(Nota provisional: Sistema de Tropas, Encuentro con Kaiju, Transición de Era y Narrativa Ambiental aún no tienen GDD — estas interfaces son contratos propuestos. Sistema de Héroes, Temporizador, Guardado/Persistencia y Permadeath ya tienen GDD propio.)*

## Formulas

Este sistema no tiene fórmulas de balance de juego, pero es la fuente de verdad de las constantes de escala del mundo que otros sistemas (incluido el GDD de Input) necesitan.

### `world_unit_scale`
**1 unidad-mundo = 1 tile = 48px a zoom 1.0**

| Variable | Símbolo | Tipo | Valor | Descripción |
|---|---|---|---|---|
| Escala de unidad-mundo | `world_unit_scale` | int (px/unidad) | 48 (fijo) | Tamaño de tile confirmado (ver Sección 6.1 del art bible) |

**Justificación**: definir 1 unidad-mundo = 1 tile (en vez de 1 unidad = 1px) mantiene el grid de pathfinding, el footprint de unidades, el espaciado de formaciones y los límites de cámara razonando en el mismo espacio entero, independiente del tamaño de tile en píxeles. A 48px, la tropa más grande (48px) encaja exactamente en una celda; los héroes (48-96px) dan 1-2 tiles limpios. A 32px, la tropa más grande desbordaría la celda en 50%.

### `camera_pan_speed` (resuelve la pregunta abierta del GDD de Input)
`camera_pan_speed = viewport_width_units / pan_duration_target_s`

| Variable | Símbolo | Tipo | Valor/Rango | Descripción |
|---|---|---|---|---|
| Ancho de viewport | `viewport_width_px` | int | 1920 (referencia 1080p) | Coincide con la referencia de `drag_threshold_px` del GDD de Input |
| Ancho en unidades | `viewport_width_units` | float (derivado) | 40 | `1920 / 48` |
| Duración objetivo de paneo | `pan_duration_target_s` | float | 1.2–1.5 | Segundos para cruzar el viewport completo a zoom 1.0 |
| **Velocidad de paneo** | `camera_pan_speed` | float | **30** | 27–33 | unidades-mundo/seg |

**Ejemplo trabajado**: 1920/48 = 40 unidades de ancho a zoom de referencia. Con 30 unidades/seg → 40/30 ≈ 1.33s de cruce (dentro del rango 1.2-1.5s ya fijado en el GDD de Input, y equivalente a 75%/seg, dentro de la regla general de 60-80%/seg).

### `zoom_min` / `zoom_max` (resuelve la pregunta abierta del GDD de Input)

Convención: multiplicador estilo Camera2D donde 1.0 = escala nativa; valores <1 acercan (zoom in), valores >1 alejan (zoom out).

| Variable | Símbolo | Tipo | Valor | Rango seguro | Descripción |
|---|---|---|---|---|---|
| Zoom mínimo (acercamiento táctico) | `zoom_min` | float | 0.5 | 0.4–0.6 | Tropas renderizan al doble de su tamaño nativo — precisión de clic/cursor de gamepad |
| Zoom máximo (encuadre de kaiju) | `zoom_max` | float | 1.5 | 1.4–2.0 | Un kaiju a escala completa (512px) ocupa ~30% de la altura del viewport de referencia, con contexto de batalla visible alrededor |

**Verificación de pasos**: de 0.5 a 1.5 con `zoom_step_fraction` = 0.10 (ya fijado en el GDD de Input) ≈ 11-12 notches de scroll — granularidad razonable, sin necesidad de re-tunear esa constante.

*(Nota: `zoom_max` = 2.0 es el extremo superior del rango seguro y cambia el balance hacia vista estratégica general en vez de prominencia del kaiju — marcar para playtest una vez existan sprites de kaiju reales.)*

## Edge Cases

- **Si `legacy_props` referencia una reliquia aún no forjada** (el héroe correspondiente sigue vivo): el prop no aparece en absoluto en el entorno de la era nueva. Esto es distinto de la convención de "nichos vacíos" del Salón Conmemorativo (que pertenece a su propio GDD) — aquí, simplemente no se instancia el prop.
- **Si solo existe una era definida** (alcance del MVP): `narrative_order` = 0, sin siguiente era. Transición de Era consulta si existe una era con `narrative_order` superior; si no la encuentra, simplemente no se activa — no es un error, es el estado esperado del MVP.
- **Si un sistema solicita `unit_roster` mientras la era está en `LOADING`**: la solicitud se bloquea/encola hasta que el estado sea `LOADED`. Nunca se retornan datos parciales.
- **Si una referencia a `kaiju_definition` está rota o el Resource no se encuentra**: falla ruidosamente en tiempo de carga/editor (error visible en desarrollo), nunca sustituye silenciosamente un kaiju por defecto — coincide con el Pilar 4 (todo debe ser autoral y específico).
- **Si dos eras distintas referencian el mismo ID de reliquia en `legacy_props`**: permitido — una reliquia puede aparecer como prop persistente en múltiples eras posteriores, ya que el Pilar 2 establece que el legado se acumula, no se consume en una sola aparición.
- **Si `color_accent` no está definido para una era** (arte aún no finalizado en producción): usa como fallback los valores neutrales base del sistema de color (Ocre de Tumba/Piedra Fría, art bible Sección 4.1) en builds de release; en builds de desarrollo puede mostrar un color de placeholder visible para flagging.
- **Si una era `ARCHIVED` descarga sus assets de `tileset_vocabulary` de memoria por rendimiento, y Narrativa Ambiental o el Panteón necesitan consultarla después**: los datos se recargan al estado `LOADED` bajo demanda (no `ACTIVE`) — consultar legado no requiere activación completa de gameplay.

## Dependencies

Este sistema no depende de ningún otro (capa Foundation).

Sistemas que dependen de este (todas duras — no pueden funcionar sin estos datos):

| Sistema | Tipo | Interfaz |
|---|---|---|
| Sistema de Tropas | Dura | Lee `unit_roster` (porción de tropas) y `max_band_size` (tope de tropas simultáneas — Fórmula E de Tropas, `band_headroom`) |
| Sistema de Héroes | Dura | Lee `unit_roster` (porción de héroes) |
| Temporizador de Preparación/Ritual | Dura | Lee `approach_duration_s` e `imminent_window_s` de la era `ACTIVE` (contrato confirmado — ver `design/gdd/temporizador-de-preparacion-ritual.md`) |
| Encuentro con Kaiju | Dura | Lee `kaiju_definition` |
| Transición de Era | Dura | Lee `narrative_order`; escribe estado `ARCHIVED` |
| Narrativa Ambiental | Dura | Lee `legacy_props` y `tileset_vocabulary` |
| Guardado/Persistencia | Dura (bidireccional) | Almacena qué `era_id` está activa/completada, referenciando estos datos sin copiarlos |
| Permadeath | Dura (solo lectura, load-time) | Lee `get_hero_roster_count()` de la era `ACTIVE`, sobre la señal era-`LOADED`, para la cross-validación de feasibilidad de su cap de bloqueo total (Regla 8) — única lectura cross-system de Permadeath. *(Contrato nuevo, 2026-08-16 — `design/gdd/permadeath.md` está In Design; desbloquea Permadeath AC-P08c)* |
| Forja de Legado | Dura (solo lectura) | Lee qué `era_id` está `ACTIVE` para etiquetar el `origin_era_id` de cada reliquia forjada; también valida unicidad de `hero_id` sobre el roster de héroes de la era `ACTIVE` (Forja AC-FL26). La referencia inversa `EraDefinition.legacy_props → relic_id` (Regla 4) hace la relación bidireccional. *(Contrato confirmado 2026-08-17 — cierra Forja de Legado OQ-FL1; `design/gdd/forja-de-legado.md` Approved)* |
| Reliquias/Bendiciones | Dura (solo lectura, autoría por era) | Lee `invocation_charges` (y posiblemente `draw_size`/`pool_cap`) del `EraDefinition` de la era `ACTIVE` para fijar la economía de invocación por era (Reliquias Regla 5 / AC-RB17), **y el `era_id` de la era ACTIVE** (`active_era_id`) para la exclusión intra-era del pool (Reliquias Regla 10 / F-RB5 — `origin_era_id ≠ active_era_id`). *(Fila recíproca añadida en reconciliación cross-GDD 2026-08-21 — cierra parte de Reliquias OQ-RB3)* |

*(Bidireccionalidad pendiente de confirmar formalmente cuando cada sistema dependiente tenga su propia GDD — por ahora estas interfaces son contratos propuestos por este documento.)*

## Tuning Knobs

| Knob | Símbolo | Tipo | Default | Rango seguro | Qué se rompe en extremos |
|---|---|---|---|---|---|
| Límite de props de legado visibles por era | `max_legacy_props_visible` | int | 10 | 4–20 | <4: el legado se siente invisible/intrascendente, contradice el peso narrativo del Pilar 2; >20: satura la densidad visual incluso en Preparación (que permite máxima densidad según art bible Sección 6.3), compitiendo por atención con la lectura táctica de unidades |
| Tope de tropas simultáneas del jugador | `max_band_size` | int (autoral por era) | — (por era) | `≥ Σ starting_count_[tipo]`; recom. ~1.5–2× el roster inicial de tropas | = roster inicial: `rally` y el reclutamiento de Preparación siempre son no-op (`band_headroom=0`), la atrición se vuelve irrecuperable. Demasiado alto: diluye la escasez de tropas del Pilar 3 y arriesga el presupuesto de entidades en pantalla (legibilidad/perf, junto con `max_concurrent_esbirros`) |

**Interacción**: este knob no afecta la cantidad *real* de reliquias en `legacy_props` (esas se acumulan sin límite, per Pilar 2) — solo cuántas se renderizan simultáneamente en el entorno de una era dada. Si `legacy_props` excede el límite, el sistema debe priorizar cuáles mostrar (regla de priorización pendiente — ver Open Questions).

## Visual/Audio Requirements

Este sistema no tiene requisitos visuales o de audio propios — es una capa de datos pura. Los assets visuales (tileset_vocabulary, definiciones de kaiju/unidades) son referenciados aquí pero especificados por el art bible y los futuros GDDs de los sistemas consumidores (Sistema de Tropas, Sistema de Héroes, Encuentro con Kaiju, Narrativa Ambiental).

## UI Requirements

Este sistema no expone UI propia. Los datos que provee (nombre de era, civilización) pueden aparecer en pantallas de otros sistemas (ej. Transición de Era, Salón Conmemorativo), pero el diseño de esas pantallas pertenece a sus GDDs correspondientes.

## Acceptance Criteria

*(Validado por `qa-lead`. AC-22 queda explícitamente bloqueado — ver Open Questions.)*

### Core Rules

**AC-1** (Config/Data — advisory, smoke check): Given el script `EraDefinition`, When se carga un `.tres` que lo instancia, Then debe exponer todos los campos (era_id, era_name, civilization_name, narrative_order, unit_roster, kaiju_definition, tileset_vocabulary, color_accent, legacy_props, world_unit_scale, approach_duration_s, imminent_window_s) con los tipos declarados correctos, sin error de tipo.

**AC-1b** (Logic — bloqueante, unit test automatizado): Given un `EraDefinition` cargado en estado `LOADED` con un `unit_roster` de tamaño de héroes conocido, When se invoca `get_hero_roster_count()`, Then retorna exactamente ese conteo, recalculado desde `unit_roster` en cada llamada (no cacheado de forma que pueda desincronizarse) — sin campo autoral separado que pueda contradecir el roster real. *(Contrato nuevo con Permadeath — desbloquea Permadeath AC-P08c; ver `design/gdd/permadeath.md` OQ-P6 #6.)*

**AC-2** (Config/Data — advisory, smoke check): Given el set de archivos `.tres` de era comprometidos, When se escanea el contenido de era del proyecto, Then no se encuentra ningún dato de era/kaiju/unidad generado en runtime — verificado por grep estático de sistemas consumidores buscando llamadas de generación.

**AC-3** (Logic — bloqueante, unit test automatizado): Given un `EraDefinition` cargado en estado ACTIVE, When cualquier sistema intenta escribir uno de sus campos en runtime, Then la escritura es rechazada o no tiene efecto persistido, y releer el campo retorna el valor autoral original.

**AC-4** (Integration — bloqueante, integration test/playtest documentado; BLOQUEADO parcialmente hasta GDD de Guardado/Persistencia): Given un jugador ganó una reliquia ligada a la era X, When el sistema de guardado registra ese estado, Then el registro almacena solo una referencia a `era_id` y al ID de reliquia, y el `EraDefinition` de la era X permanece idéntico byte a byte a su `.tres` autoral.

**AC-5** (Logic — bloqueante, unit test automatizado): Given una lista `EraDefinition.legacy_props`, When se inspecciona la lista, Then cada entrada es un ID de reliquia (string/enum) y nunca una estructura de datos de reliquia embebida.

**AC-6** (Integration — bloqueante, diferido hasta GDDs de Sistema de Tropas/Héroes/Encuentro con Kaiju): Given un sistema consumidor, When muestra o referencia contenido de era, Then ningún nombre de era/kaiju/unidad está hardcodeado en su código fuente — verificable por grep una vez esos sistemas existan.

### States and Transitions

**AC-7** (Logic — bloqueante): Given una referencia `EraDefinition` en UNLOADED, When se solicita una carga, Then el estado transiciona a LOADING y ningún campo es legible como valor final durante este estado.

**AC-8** (Logic — bloqueante): Given un `EraDefinition` en LOADING, When el recurso termina de cargar exitosamente, Then el estado transiciona a LOADED y todos los campos están completamente poblados y son legibles.

**AC-9** (Logic — bloqueante): Given un `EraDefinition` en LOADED, When la era se establece como la era de juego actual, Then el estado transiciona a ACTIVE y exactamente un `EraDefinition` está ACTIVE a la vez (en el caso de una sola era del MVP, trivialmente satisfecho pero debe probarse como invariante).

**AC-10** (Logic — bloqueante): Given un `EraDefinition` en ACTIVE, When una era distinta se vuelve ACTIVE (o la era se retira explícitamente), Then la era previa transiciona a ARCHIVED y su estado deja de reportarse como ACTIVE.

**AC-11** (Logic — bloqueante, transición inválida): Given un `EraDefinition` en ARCHIVED, When se intenta una transición directa a ACTIVE sin pasar por una recarga LOADED fresca, Then la transición es rechazada (error o no-op), y el estado permanece ARCHIVED hasta que ocurra primero un ciclo LOADING→LOADED.

**AC-12** (Logic — bloqueante): Given un `EraDefinition` en ARCHIVED, When se solicita explícitamente una recarga, Then el estado transiciona ARCHIVED → LOADING → LOADED (nunca directo a ACTIVE).

### Edge Cases

**AC-13** (Integration — bloqueante, parcialmente diferido hasta el diseño del Salón Conmemorativo): Given la lista `legacy_props` de una era contiene un ID de reliquia cuyo héroe sigue vivo (no forjada), When se consultan los props de legado de la era para renderizado, Then ese ID de reliquia se omite silenciosamente del set retornado/renderizado — sin objeto placeholder en esta capa.

**AC-14** (Logic — bloqueante): Given el set de eras del MVP contiene exactamente un `EraDefinition` con narrative_order = 0, When Transición de Era verifica si existe una "siguiente era", Then no encuentra ninguna y no se activa, sin lanzar error/excepción.

**AC-15** (Logic — bloqueante): Given un `EraDefinition` en LOADING, When se solicita `unit_roster`, Then la solicitud se bloquea/encola hasta alcanzar LOADED, y el valor eventualmente retornado nunca es un roster parcial/incompleto.

**AC-16** (Logic — bloqueante): Given un `EraDefinition` cuya referencia `kaiju_definition` está rota o ausente, When el recurso se carga en un build de desarrollo, Then la carga falla ruidosamente (error/assert visible), y el sistema nunca sustituye silenciosamente un kaiju por defecto.

**AC-17** (Logic — bloqueante): Given el mismo ID de reliquia aparece en `legacy_props` de la era A y la era B (B narrativamente posterior), When se consultan los props de legado de ambas eras independientemente, Then el ID de reliquia está presente en ambos resultados — confirmando que el legado se acumula en vez de consumirse una sola vez.

**AC-18** (Config/Data — advisory, smoke check): Given un `EraDefinition` con `color_accent` sin definir, When la era se carga en un build de release, Then el sistema usa como fallback los valores neutrales base (Ocre de Tumba/Piedra Fría) sin error visible; When se carga en un build de desarrollo, Then se muestra un color de placeholder visiblemente distinto en vez del fallback neutral.

**AC-19** (Logic — bloqueante para la parte de máquina de estados; Integration diferida hasta GDDs de Narrativa Ambiental/Panteón): Given un `EraDefinition` en ARCHIVED con `tileset_vocabulary` descargado, When Narrativa Ambiental o el Panteón consultan los datos de tileset de esa era, Then la era se recarga a estado LOADED (no ACTIVE) y retorna datos de tileset válidos.

### Tuning Knobs

**AC-20** (Logic — bloqueante): Given `max_legacy_props_visible` se establece fuera del rango seguro (ej. 2 o 25), When el valor se carga/aplica, Then se hace clamp al rango seguro [4, 20] antes de usarse, y el tamaño real de la lista `legacy_props` nunca se trunca por este límite (solo el subset renderizado/visible se limita).

**AC-21** (Config/Data — advisory, smoke check): Given no hay override explícito para `max_legacy_props_visible`, When se carga una era, Then el valor efectivo usado para renderizado es 10 (el default documentado).

### Clasificación de tipo de story (para el gate de evidencia)

| AC # | Tipo | Evidencia requerida | Nivel de gate |
|---|---|---|---|
| AC-1, AC-2 | Config/Data | Smoke check | Advisory |
| AC-3, AC-5, AC-7 a AC-12, AC-14 a AC-17, AC-19, AC-20 | Logic | Unit test automatizado | Bloqueante |
| AC-4, AC-6, AC-13 | Integration | Integration test / playtest documentado (parcial, diferido) | Bloqueante |
| AC-18, AC-21 | Config/Data | Smoke check | Advisory |

### Huecos/no-testeables marcados (no escritos como criterios)

1. **AC-6** — no se puede verificar "sin nombres hardcodeados" en sistemas que aún no existen (Sistema de Tropas, Héroes, Encuentro con Kaiju). Aplicar retroactivamente cuando esos GDDs/implementaciones existan.
2. **AC-4 y AC-19** — el comportamiento de ida y vuelta completo depende de interfaces de Guardado/Persistencia y Narrativa Ambiental/Panteón que aún no existen. El lado de `EraDefinition` es testeable ahora en aislamiento; el camino de consulta/guardado cruzado no.
3. **AC-13** — el comportamiento de renderizado de placeholder del Salón Conmemorativo está fuera de alcance de este GDD; solo la mitad de "omisión en la capa de consulta" es testeable ahora.
4. **AC-22 (regla de prioridad al exceder `max_legacy_props_visible`)** — genuinamente bloqueado, no diferido: no existe una regla contra la cual testear. Debe volver como pregunta de diseño abierta antes de escribir un criterio (ver Open Questions).
5. **world_unit_scale / camera_pan_speed / zoom_min / zoom_max** — son constantes de fórmula ya fijadas, pero pertenecen conceptualmente a un sistema de *cámara*, no a `EraDefinition` en sí. No se escribe AC aquí; se recomienda que el futuro sistema de cámara/Control y Selección de Unidades cargue el AC de timing de paneo (1.2–1.5s) como criterio de Integration/Feel.

## Open Questions

| Pregunta | Owner | Resolución objetivo |
|---|---|---|
| ¿Qué regla de prioridad decide qué props de legado mostrar cuando `legacy_props.size()` excede `max_legacy_props_visible`? (bloquea AC-22) | game-designer | Antes de implementar el renderizado de props de legado |
| ¿`world_unit_scale`, `camera_pan_speed`, `zoom_min`/`zoom_max` deberían moverse conceptualmente a un futuro GDD de Cámara/Control y Selección de Unidades en vez de vivir aquí? Se definieron en este documento por necesidad (bloqueaban al GDD de Input), pero pertenecen más a cámara que a datos de era | game-designer | Al diseñar Control y Selección de Unidades |
| Las interfaces bidireccionales con Encuentro con Kaiju, Transición de Era y Narrativa Ambiental son contratos propuestos — deben confirmarse formalmente cuando cada uno tenga su propia GDD. (Sistema de Tropas, Sistema de Héroes y Temporizador de Preparación/Ritual ya tienen GDD propia y sus contratos con este sistema están confirmados — Temporizador confirmado 2026-08-09 con la adición de `approach_duration_s`/`imminent_window_s` al schema.) | game-designer | Al diseñar cada sistema dependiente restante |
