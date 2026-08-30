# UI/HUD

> **Status**: Approved (design-review 2026-08-14 — blocking items 1–3 aplicados y aceptados)
> **Author**: user + agents (systems-designer, art-director, qa-lead)
> **Last Updated**: 2026-08-14
> **Implements Pillar**: Pilar 4 (Historia Jugada, No Contada); soporte a Pilar 1 (Sacrificio con Peso) y Pilar 3 (Ritual→Clímax)

## Overview

UI/HUD es la capa de presentación que convierte el estado crudo expuesto por Combate/Daño, Sistema de Héroes, Control y Selección de Unidades, Temporizador de Preparación/Ritual y Encuentro con Kaiju en señales legibles para el jugador durante una sesión activa: vida y estado de combate, selección y prioridad héroe/tropa, la cuenta atrás ritual hacia el clímax, el veredicto emergente de la muerte de un héroe, y las advertencias de telegrafío/marcado del kaiju. No posee ningún dato de juego propio — solo lee eventos y estado expuestos por otros sistemas, y decide cómo, cuándo y con qué intensidad mostrarlos. Para el jugador, es el sistema que hace posible el Pilar 4 (Historia Jugada, No Contada) sin una sola línea de texto editorializante: cada decisión táctica (a quién proteger, cuándo sacrificar, cuándo retirarse) se vuelve visible a través de forma, movimiento y color — nunca a través de un cartel que le diga al jugador qué sentir. El alcance de este GDD es la superposición HUD durante una sesión activa (preparación + clímax); los menús (pausa, ajustes, resultado, panteón, transición de era) quedan fuera y se diseñarán en sistemas o pasadas de UI posteriores.

## Player Fantasy

> **Framing**: Directo — el jugador interactúa con UI/HUD en cada instante de la sesión activa; es su ventana perceptual constante al estado del combate y del ritual.

La fantasía que sirve UI/HUD es la de un comandante que **siempre sabe la verdad exacta del campo de batalla, sin que nadie se la suavice**. No hay iconos de "¡Peligro!" ni "¡Victoria!" que le digan al jugador qué sentir — solo formas, movimiento y color que comunican con precisión fría cuánto tiempo de vida le queda a un héroe, qué tan cerca está el clímax, y qué reliquia está naciendo de una muerte. Es la claridad de un HUD de Warcraft 3 (barras de vida legibles a simple vista en un enjambre de unidades) combinada con la honestidad emocional de los "boons" de Hades (un ícono nunca miente sobre lo que hace) — pero aplicada a apuestas permanentes: cuando el HUD le dice al jugador que un héroe está en la ventana de ~30 segundos antes de morir, esa lectura es literal, no drama de UI.

Esto sirve directamente al **Pilar 1 (Sacrificio con Peso)** — la UI es el instrumento que hace la apuesta legible en tiempo real — y al **Pilar 4 (Historia Jugada, No Contada)** — el test de diseño de la UI es: si un jugador puede sentir la pérdida de un aliado como un momento importante *solo* por lo que ve en pantalla, sin ningún texto que se lo explique, el sistema cumplió su propósito.

*Test de diseño de este sistema*: si una señal de la UI necesita texto para comunicar su urgencia o significado, el diseño visual falló y debe rehacerse con forma/movimiento/color antes de añadir texto.

*(Autoría en modo lean reservó especialistas para D/H; el `/design-review` completo del 2026-08-14 sí consultó `creative-director` (síntesis senior) + game-designer/ux-designer sobre esta sección — ver review-log.)*

## Detailed Design

*(Autoría en modo lean no spawneó especialistas aquí; el `/design-review` completo del 2026-08-14 consultó game-designer, ux-designer, ui-programmer y godot-specialist sobre esta sección — hallazgos aplicados: Core Rule 6b, 11 mouse_filter, tabla de estados. Ver review-log.)*

### Core Rules

1. **UI/HUD es puramente de lectura (read-only)** — nunca escribe estado de vuelta a ningún sistema que consume, con la única excepción de la retroalimentación visual de Sacrificio (Regla 7), que es un contrato provisional de solo-feedback, no de autoridad de comando.
2. **Composición de regiones**: panel inferior (comando/selección), timer superior-centro (fase ritual), overlays de mundo anclados a entidades que se mueven con la cámara (barras de vida, ancla del readout de veredicto del héroe, marcas/anillo del kaiju), viñeta de pantalla periférica (aviso de telegrafío). Sin minimapa en MVP.
3. **Barras de vida**: visibles solo si la unidad está seleccionada O por debajo de vida máxima (resuelve CV-5 de Combate/Daño — decisión tomada en este GDD). Usan la misma paleta Hueso→Sangre Vieja que el flash de impacto (CU-1).
4. **Selección**: cada unidad seleccionada recibe un contorno (Acero Violeta-Ceniza, solo contorno, sin relleno) derivado del selection set de Control y Selección de Unidades; cuando una selección resuelve a un héroe sobre una tropa superpuesta, el marcador del héroe usa grafía de forma distinta, no solo tamaño (resuelve U-6/AC-H33).
5. **Timer ritual**: forma diegética (vasija que se drena / arco que se consume), nunca un reloj digital. Las 3 fases (PREPARATION/IMMINENT/CLIMAX) son distinguibles a simple vista; la escalada de IMMINENT es multi-canal (forma/movimiento primero, color solo terciario).
6. **Readout de veredicto del héroe** (implementa U-1..U-4 de Sistema de Héroes): visible solo si el héroe está en riesgo activo — gateado por `time_to_death`/`incoming_damage_rate_total`, nunca por HP% — o está seleccionado. Anclado al elemento asimétrico del héroe. 3 estados discretos de tier (Delgada/Sólida/Legendaria) diferenciados por forma, no por gradiente de color. Se congela al entrar `DYING`. El gate de riesgo tiene **dos caminos** (F1): el camino normal con histéresis (`T_show`+debounce) y un **camino de disparo instantáneo** que salta `T_show` y el debounce cuando `danger_time_s < T_instant`=5.0s — de modo que una muerte por ráfaga (héroe a vida plena eliminado dentro de la ventana de debounce de 0.5s) nunca ocurre sin readout. El camino instantáneo garantiza el compromiso de "informar, nunca emboscar" del Pilar 4.
6b. **Director de atención de muerte de héroe** (resuelve el hueco de muerte silenciosa detectado en review): cuando un héroe cruza a `AT_RISK` (vía cualquiera de los dos caminos de F1) o a `DYING` **mientras está fuera de pantalla o no seleccionado**, UI/HUD dispara una señal redundante multi-canal para que el jugador nunca pierda el beat de permadeath — la única excepción deliberada a la regla de "sin indicadores de fuera de pantalla" (justificada por las apuestas de permadeath, Pilar 1). Tres canales simultáneos: **(a)** un marcador direccional de borde de pantalla que apunta hacia el héroe endangered (solo para `AT_RISK`/`DYING`, no para daño rutinario), reproyectado/clamped al borde vía F2; **(b)** un sting de audio breve + pulso háptico en la transición; **(c)** un empujón de cámara (hint de auto-paneo o bloom de borde) hacia el héroe al entrar `DYING`. Los tres respetan la regla de ≥3 canales redundantes y no editorializan (Regla 10). El marcador de borde y el empujón de cámara cesan en cuanto el héroe entra al viewport o se confirma `DEAD`.
7. **Retroalimentación de Sacrificio (contrato PROVISIONAL — ver Open Questions)**: al emitir la orden, el cursor/reticle cambia a una forma distinta de la de mover/atacar mientras la orden está pendiente; al aceptarse, la silueta del héroe recibe un pulso de confirmación de un frame. UI/HUD solo posee esta retroalimentación visual — el verbo de entrada y el gate de `D` siguen siendo de Control/Combate (OQ-2 en ambos, sin resolver).
8. **Telegrafío del kaiju**: los 3 tercios explícitos sobre `telegraph_duration_s`=14.0s en el cuerpo del kaiju son posesión de Encuentro con Kaiju (fuera de este GDD) — pero el canal periférico no-audio (viñeta de borde de pantalla + rumble de gamepad) desde el tercio 1, escalando con el mismo ritmo, es posesión de UI/HUD. Tope de 3 flashes/seg (fotosensibilidad); un toggle de flash reducido sustituye la pulsación por una rampa continua de brillo.
9. **Marcas del kaiju**: el anillo secundario de `guard_radius`=4.0 alrededor de `marked_target` (vía defensiva, KV-2) es renderizado por UI/HUD; la runa de suelo en sí y la lectura de `marked_threat` en el cuerpo del kaiju (KV-3) son posesión visual de Encuentro con Kaiju/art-director.
10. **Sin texto editorializante en ningún elemento** (resuelve CU-4/U-5/KU-3) — solo estado/números cuando corresponda, nunca frases de sentimiento ("¡Peligro!", "¡Muerte heroica!").
11. **Ningún elemento de HUD acepta input directo**, salvo el cursor virtual de gamepad (cuyo comportamiento de snap magnético pertenece a Control — UI/HUD solo dibuja su apariencia). UI/HUD es estrictamente de salida. **Mecanismo (Godot 4.6)**: los overlays anclados a mundo se implementan como nodos `Control` dentro de un `CanvasLayer` (posicionados por-frame vía F2), y **cada uno debe fijar `mouse_filter = MOUSE_FILTER_IGNORE`** — de lo contrario consumirían silenciosamente los clics de selección de unidad destinados a las unidades por debajo (Godot 4.6 separa el foco mouse/touch del de teclado/gamepad; un `Control` con filtro por defecto captura el clic). AC-U28 verifica el síntoma; esta regla fija el mecanismo.

### States and Transitions

| Elemento | Transición | Disparador |
|---|---|---|
| Barra de vida | `HIDDEN → VISIBLE` | unidad seleccionada O `current_health < max_health` |
| Barra de vida | `VISIBLE → HIDDEN` | unidad deseleccionada Y `current_health == max_health` |
| Readout de veredicto del héroe | `HIDDEN → AT_RISK` (camino histéresis) | `danger_time_s ≤ T_show`=30.0s sostenido ≥`debounce_on_s`=0.5s (F1) |
| Readout de veredicto del héroe | `HIDDEN → AT_RISK` (camino instantáneo) | `danger_time_s < T_instant`=5.0s — salta `T_show` y debounce (F1, muerte por ráfaga) |
| Readout de veredicto del héroe | `HIDDEN/AT_RISK → SELECTED_VIEW` | héroe seleccionado por el jugador (visible independientemente del riesgo) |
| Readout de veredicto del héroe | `AT_RISK/SELECTED_VIEW → FROZEN` | héroe entra a `DYING` (snapshot D/T/P, deja de actualizar) |
| Readout de veredicto del héroe | `HIDDEN → FROZEN` (muerte súbita, nunca renderizado) | héroe entra a `DYING` sin haber cruzado F1 ni estar seleccionado — se toma el snapshot D/T/P igual; se renderiza solo si el jugador lo trae a vista antes de `DEAD` (ver Edge Cases) |
| Readout de veredicto del héroe | `FROZEN → HIDDEN` | héroe confirmado `DEAD` (Permadeath resuelve el beat) |
| Director de atención (marcador de borde + cámara) | `OFF → ACTIVE` | héroe cruza a `AT_RISK`/`DYING` **fuera de pantalla o no seleccionado** (Core Rule 6b) |
| Director de atención (marcador de borde + cámara) | `ACTIVE → OFF` | el héroe entra al viewport O se confirma `DEAD` |
| Timer ritual | `PREPARATION → IMMINENT → CLIMAX` | señales `entered_imminent`/`entered_climax` del Temporizador (consumidas, no re-derivadas) |
| Viñeta de telegrafío | `OFF → THIRD_1 → THIRD_2 → THIRD_3` | `telegraph_progress` cruza 0.33 / 0.66 / 1.0 (consumido de Encuentro con Kaiju, KU-1) |
| Viñeta de telegrafío | `THIRD_3 → OFF` | `STRIKING` resuelto O cancelado (razón expuesta por KU-1) |
| Feedback de Sacrificio | `IDLE → PENDING → CONFIRMED → IDLE` | orden emitida → aceptada por Combate/Control → siguiente frame vuelve a `IDLE` |

### Interactions with Other Systems

- **Combate/Daño → UI/HUD** (lee): `current_health`/`max_health` por unidad, estado de enganche (`NO_TARGET`/`TARGET_ACQUIRED`/`ATTACKING`), eventos de golpe (disparan flash de una silueta), tasa de daño entrante reciente. Nada fluye en sentido inverso.
- **Sistema de Héroes → UI/HUD** (lee): tier proyectado de `relic_quality` (mapeado vía U-1/U-2), snapshot D/T/P al entrar `DYING`, estado de prioridad de selección hero>tropa, `asymmetric_element`/`relic_category` (identidad visual). Nada fluye en sentido inverso.
- **Control y Selección de Unidades → UI/HUD** (lee): selection set activo, método de input activo (mouse vs gamepad — determina si el cursor virtual se dibuja), rectángulo de box-select durante el arrastre, posición del cursor virtual de gamepad. Nada fluye en sentido inverso — UI/HUD no decide selección, solo la dibuja.
- **Temporizador de Preparación/Ritual → UI/HUD** (lee): `current_phase`, `time_remaining_to_climax_s`, `imminent_local_progress`.
- **Encuentro con Kaiju → UI/HUD** (lee): estado del ciclo de intención (`SEEKING`/`TELEGRAPHING`/`STRIKING`/`STAGGERED`), flag `ENRAGED`, `telegraph_progress` `[0.0,1.0]`, identidad de `marked_target`/`marked_threat` + razón de cancelación de marca, `time_to_death` e `incoming_damage_rate_total` por héroe, `stagger_duration_s` restante, un único evento discreto de victoria/derrota (UI/HUD no posee ni renderiza la pantalla de resultado — solo puede mostrar un acuse de recibo breve antes del hand-off, per decisión de alcance de este GDD).
- **Reliquias/Bendiciones → UI/HUD** (contrato **confirmado — `reliquias-bendiciones.md` Approved 2026-08-18**): expone `invocation_charges_remaining` (RU-1), `can_invoke`/`first_invocation_available` (RU-2/RU-2b), `blessing_offer` 3-choose-1 con identidad glanceable + `band_headroom` (RU-3/RU-3b), y `active_blessings: list` con ticks de expiración (RU-4). **Nota de carga cognitiva:** el draft de invocación corre durante `CLIMAX` (en cámara lenta, `offering_time_scale`, no en pausa) — OQ-U8 (riesgo de overload del HUD de CLIMAX) debe **re-contar el draft** como stream activo adicional; el análisis original lo predata.
- **Datos de Era/Civilización → UI/HUD** (constantes registradas): `world_unit_scale`=48, `camera_pan_speed`=30, `zoom_min`=0.5, `zoom_max`=1.5 — usados junto con la inversa de `screen_to_world_transform` para posicionar overlays de mundo sobre unidades/kaiju.

## Formulas

*(`systems-designer` consultado — MANDATORY incluso en modo lean, Sección D es de alto riesgo de implementación.)*

### F1 — `hero_risk_threshold` (resuelve Héroes OQ-6 + Encuentro con Kaiju OQ-14)

The `hero_risk_threshold` formula is defined as:

`hero_risk_state = (danger_time_s < T_instant) OR hysteresis(danger_time_s, T_show, T_hide, min_visible_s, debounce_on_s)`
`danger_time_s = min(time_to_death, hero_current_health / max(incoming_damage_rate_total, ε))`

El primer término es el **camino de disparo instantáneo**: en cuanto `danger_time_s` cae por debajo de `T_instant`, el readout se enciende ese mismo frame, saltando `T_show` y el debounce. Esto cierra la ventana de "muerte por ráfaga" (un héroe eliminado más rápido que `debounce_on_s`=0.5s) y cubre caídas discontinuas de `time_to_death` (p. ej. un recálculo por `ENRAGED`, cuya tasa de cambio es propiedad de Encuentro con Kaiju — ver OQ-U7). El segundo término (histéresis) sigue gobernando el peligro sostenido no letal y su banda muerta anti-parpadeo. Una vez ON por cualquiera de los dos caminos, `min_visible_s` sigue aplicando antes de poder apagarse.

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Proyección solo-kaiju | `time_to_death` | float | [18.5, ∞) s | De Encuentro con Kaiju (locked) |
| DPS todas las fuentes | `incoming_damage_rate_total` | float | [0.0, ∞) | De Encuentro con Kaiju (locked) |
| Vida actual del héroe | `hero_current_health` | float | (0, hero_max_health] | Stat en vivo |
| Guarda epsilon | `ε` | float | 0.001 (const) | Previene división por cero |
| Tiempo de peligro combinado | `danger_time_s` | float | [0, ∞) | Señal "segundos hasta la muerte" comensurable |
| Umbral de disparo instantáneo | `T_instant` | float | 5.0 s (const) | Salta `T_show`+debounce; cierra la ventana de muerte por ráfaga |
| Umbral de aparición | `T_show` | float | 30.0 s (const) | Ancla el objetivo de ~30s de Héroes |
| Umbral de desaparición | `T_hide` | float | 38.0 s (const) | ~27% sobre T_show; ancho de banda muerta |
| Duración mínima visible | `min_visible_s` | float | 4.0 s (const) | Una vez ON, permanece al menos esto |
| Ventana de debounce ON | `debounce_on_s` | float | 0.5 s (const) | La condición debe sostenerse antes de ON |
| Estado de salida | `hero_risk_state` | bool | {OFF, ON} | Controla visibilidad del readout U-3 |

**Output Range:** booleano; a lo sumo un ciclo ON→OFF por ventana `min_visible_s + debounce` bajo oscilación de peor caso.
**Example:** `hero_current_health=340`, `incoming_damage_rate_total=52.0` → tiempo por HP = 6.54s. `time_to_death=26.0s`. `danger_time_s=min(26.0,6.54)=6.54s` → readout se enciende (sostenido 0.5s). Luego `danger_time_s` sube a 41s → se apaga (≥38s, y llevaba visible >4s).
**Nota de diseño:** `min()` en vez de promedio — así un enjambre rápido de esbirros no queda enmascarado por un timer de kaiju lento. El HP se divide por el DPS para volver `incoming_damage_rate_total` (una tasa) comensurable con `time_to_death` (un tiempo).

### F2 — `world_to_screen_transform` (inversa formal de `screen_to_world_transform`)

The `world_to_screen_transform` formula is defined as:

`world_to_screen_transform = viewport_size_px / 2 + (world_position_world - camera_position_world) × (world_unit_scale / zoom)`

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Posición objetivo | `world_position_world` | Vector2 | world units | Posición a proyectar (héroe/marcador) |
| Posición de cámara | `camera_position_world` | Vector2 | world units | Foco actual de la cámara |
| Tamaño de viewport | `viewport_size_px` | Vector2 | px | Dimensiones del viewport actual |
| Zoom | `zoom` | float | [0.5, 1.5] | Rango registrado (zoom_min/zoom_max) |
| Escala de unidad de mundo | `world_unit_scale` | float | 48 (const) | px por unidad de mundo a zoom 1.0 |
| Salida | `screen_pos_px` | Vector2 | (-∞, ∞) px | Coordenadas en píxeles, puede caer fuera del viewport |

**Output Range:** sin acotar — un resultado válido puede caer fuera de `[0, viewport_size_px]` (héroe detrás de cámara o fuera de pantalla). Elementos que deben permanecer visibles fuera de pantalla (marcador direccional del director de atención, Core Rule 6b) aplican su propio clamp/reproyección al borde; esta fórmula solo da la proyección cruda.
**Example:** cámara en (100,50), zoom=1.0, viewport 1920×1080, objetivo en (120,50) → `screen_pos_px=(1920,540)` — un punto 20 unidades de mundo a la derecha de la cámara cae exactamente en el borde derecho del viewport. (Convención de `zoom` idéntica a la de Datos de Era/Civilización: `zoom`<1 acerca — a `zoom_min`=0.5 la escala es 48/0.5=**96 px/unidad**, sprites al doble de tamaño; `zoom_max`=1.5 aleja, 32 px/unidad, mayor densidad de unidades en pantalla.)
**Nota de implementación (Godot 4.6 — MANDATORIA, resuelve blocking item de review):** F2 es la *definición matemática* de la proyección, **no la vía de implementación**. La implementación NO debe re-derivar esta transformada a mano: debe leer la transformada de canvas que Godot usa realmente para renderizar, vía `CanvasItem.get_global_transform_with_canvas()` (o el `get_canvas_transform()` del viewport) y, para el centro de cámara, `Camera2D.get_screen_center_position()` — **no** el `.position` crudo del nodo. Motivo: con `position_smoothing_enabled` o drag margins activos (y `camera_pan_speed`=30 produce paneos rápidos), el centro renderizado *retrasa* la posición del nodo, y una fórmula manual haría que los overlays anclados a mundo **se deslicen respecto de sus entidades** durante el paneo. La transformada nativa también absorbe gratis el `content_scale_mode` del proyecto (canvas_items vs viewport) y el escalado DPI/resize; la fórmula manual no. El mundo usa **Camera2D** (2D puro; confirmado contra el framing de tiles de Datos de Era/Civilización). Sin término de rotación porque la cámara no rota en MVP — si se añade rotación de cámara, F2 manual se rompería; otra razón para deferir a la transformada nativa. AC-U26 debe testear contra la salida real de la transformada de Godot, no solo la aritmética de F2.

### F3 — `telegraph_vignette_intensity` (canal periférico propio de UI/HUD, KV-1b)

The `telegraph_vignette_intensity` formula is defined as:

`telegraph_vignette_intensity = clamp(base(third) + amplitude × abs(sin(π × freq(third) × elapsed_in_third_s)), 0.0, 1.0)` (modo flash)
Modo flash-reducido sustituye el término oscilante por una rampa lineal: `clamp(base(third) + amplitude × progress_within_third, 0.0, 1.0)`.

**El `clamp()` es obligatorio, no cosmético**: sin él, la salida excede 1.0 en el extremo del rango seguro del knob `amplitude`. En el tercio 3 (`base(2)`=0.75) con `amplitude`=0.35 (techo del rango seguro documentado), el pico oscilante da `0.75 + 0.35 = 1.10 > 1.0`. El clamp explícito garantiza el rango `[0.0,1.0]` que AC-U22 verifica; la garantía algebraica anterior solo se sostenía en `amplitude`=0.25 exacto.

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Progreso crudo | `telegraph_progress` | float | [0.0, 1.0] | Leído de Encuentro con Kaiju |
| Índice de tercio | `third` | int | {0,1,2} | `floor(telegraph_progress × 3)`, clamped |
| Progreso dentro del tercio | `progress_within_third` | float | [0.0, 1.0) | `(telegraph_progress × 3) − third` |
| Tiempo transcurrido en el tercio | `elapsed_in_third_s` | float | [0, 4.667) s | `progress_within_third × (telegraph_duration_s/3)` |
| Base escalonada | `base(third)` | float | {0.25, 0.50, 0.75} | `0.25 + 0.25 × third` |
| Frecuencia de pulso | `freq(third)` | float | {1.0, 2.0, 3.0} Hz | `min(1.0 + third, 3.0)` — tope de fotosensibilidad (KV-10) |
| Amplitud de pulso | `amplitude` | float | 0.25 (const) | Altura de oscilación/rampa sobre la base |
| Salida | resultado | float | [0.0, 1.0] | Alpha de viñeta, clamped |

**Output Range:** [0.0, 1.0], garantizado por el `clamp()` explícito; ambos modos comparten `base()` para preservar paridad de accesibilidad.
**Example (modo flash):** `telegraph_progress=0.50` → tercio 1, `elapsed_in_third_s≈2.33s`, `freq=2.0Hz` → `base=0.50`. Término oscilante = `0.25 × abs(sin(π × 2.0 × 2.33))` = `0.25 × abs(sin(14.66 rad))` = `0.25 × 0.866` = **0.217** → intensidad = `0.50 + 0.217` ≈ **0.72**. **Equivalente flash-reducido:** `0.50 + 0.25×0.50 = 0.625`, suave y sin parpadeo. *(Nota: el modo flash pulsa por encima del modo flash-reducido en la cresta del seno — ambos comparten la misma `base()` de piso, que es lo que preserva la paridad de accesibilidad; los picos difieren por diseño.)*
**Nota de diseño:** el salto escalonado de `base()` da identidad de "qué tercio" instantánea incluso antes de que se lea un pulso; `freq()` escala 1→2→3Hz, aterrizando exactamente en el techo de fotosensibilidad en el tercio final, nunca por encima.

## Edge Cases

*(Autoría en modo lean no spawneó especialistas aquí; el `/design-review` completo del 2026-08-14 (systems-designer, game-designer, ux-designer) revisó y amplió esta sección — añadidos: muerte por ráfaga, director fuera de pantalla, corrección de zoom F2, apilamiento N-simultáneo. Ver review-log.)*

- **Si dos o más héroes están simultáneamente `AT_RISK`**: cada uno renderiza su propio readout de peligro, anclado independientemente a su propio héroe — la apuesta de cada héroe es individualmente legible (Pilar 1). **Pero la legibilidad *por-héroe* no garantiza legibilidad *de escena*** cuando 3+ readouts coinciden con el timer, la viñeta, los anillos, las barras y los contornos durante el CLIMAX (el momento de mayor densidad de señal). El apilamiento sin límite ni prioridad, más el coste de draw calls de N overlays independientes contra el presupuesto de <1000 (technical-preferences.md), es un riesgo real de sobrecarga sensorial y de rendimiento — se necesita una regla de priorización/agregación (p. ej. una tira de roster compacta que resuma múltiples héroes en riesgo) y un tope suave de overlays concurrentes. No resuelto numéricamente aquí; flageado como OQ-U8 para vertical slice. (La legibilidad bajo N readouts simultáneos también carece de AC — ver AC-U32.)
- **Si `incoming_damage_rate_total = 0`** (sin esbirros enganchados, kaiju no apunta a este héroe): el término HP/DPS de F1 resuelve, vía la guarda `ε`, a un valor efectivamente inalcanzable, así que `danger_time_s` cae en `time_to_death` solo — sin división por cero, sin parpadeo.
- **Muerte por ráfaga (héroe a vida plena eliminado dentro de la ventana de debounce)**: si el daño entrante proyecta la muerte en menos de `debounce_on_s`=0.5s, el camino de histéresis de F1 nunca alcanzaría a encender el readout — pero el **camino de disparo instantáneo** (`danger_time_s < T_instant`=5.0s) lo enciende ese mismo frame, sin esperar debounce. Ningún héroe muere sin readout por ser demasiado rápido. Esto también cubre una caída discontinua de `time_to_death` (recálculo por `ENRAGED`): en cuanto el valor recomputado cae bajo `T_instant`, dispara.
- **Si un héroe entra a `AT_RISK` o `DYING` fuera de pantalla o sin estar seleccionado**: (1) el readout se congela en el snapshot D/T/P igual, aunque nada se renderice — si el jugador luego selecciona ese héroe o lo trae a vista antes de que se confirme `DEAD`, el estado congelado se renderiza de inmediato, sin re-disparar el congelamiento; y (2) el **director de atención** (Core Rule 6b) dispara sus tres canales redundantes — marcador direccional de borde de pantalla, sting de audio + pulso háptico, y empujón de cámara — para que el beat de permadeath nunca ocurra en silencio total. El marcador y el empujón cesan al entrar el héroe al viewport o confirmarse `DEAD`. (Esto reemplaza el hueco anterior donde una muerte fuera de pantalla no tenía ninguna señal, dado que no hay minimapa en MVP y la viñeta F3 es solo del kaiju.)
- **Si la viñeta de `TELEGRAPHING` del kaiju (F3) y la escalada `IMMINENT` del timer ritual compitieran por el borde de pantalla**: no hay conflicto real — `IMMINENT` solo ocurre durante `PREPARATION` y `TELEGRAPHING` solo durante `CLIMAX`; las fases del Temporizador están bloqueadas a ocurrir estrictamente antes de `CLIMAX` (nunca concurrentes), así que solo un efecto de borde de pantalla está activo a la vez.
- **Si el jugador activa el toggle de flash reducido**: se aplica globalmente a todo elemento de HUD que parpadee (viñeta de telegrafío F3 Y la señal de escalada `IMMINENT`, si esa señal también pulsa) — no solo al telegrafío del kaiju. Un toggle por-elemento dejaría un hueco de fotosensibilidad.
- **Si una orden de Sacrificio pendiente (Core Rule 7, estado `PENDING`) es rechazada** por Combate/Control (target/D-gate no satisfecho): el reticle vuelve de `PENDING` a `IDLE` con una señal de rechazo distintiva de un frame (pulso de forma/color distinto al pulso de `CONFIRMED`) — nunca silencioso, pero nunca texto (Regla 10 sigue aplicando).
- **Si dos unidades seleccionadas (un héroe y una tropa superpuesta) se renderizan al footprint de sprite más pequeño** (`zoom_max`=1.5 — la vista alejada de encuadre de kaiju, donde `zoom`>1 produce 32 px/unidad, la máxima densidad de unidades y el sprite más pequeño en pantalla; **corregido en review** — la versión previa citaba `zoom_min`=0.5, pero por la convención de Datos de Era/Civilización `zoom`<1 *acerca* y produce el sprite más grande, no el más pequeño): la distinción de grafía de forma (Regla 4/U-6) debe seguir siendo legible a esa escala — el tamaño mínimo legible exacto es asunto de art-bible/technical-artist, flageado en Visual/Audio Requirements, no resuelto numéricamente aquí.
- **Si `game_time_paused` se vuelve verdadero** (p. ej. durante el beat `DEATH_HOLD` de Permadeath — contrato aún no formalizado en ningún GDD Approved): todas las animaciones de HUD dirigidas por datos (drenado de barras de vida, cuenta atrás del timer ritual, pulso de viñeta de telegrafío) se congelan en su lugar en vez de seguir animando contra un reloj de juego pausado — provisional, flageado en Open Questions pendiente del GDD de Permadeath.
- **Si el tier de `relic_quality` de un héroe cruza un límite** (p. ej. Sólida→Legendaria) mientras el readout ya está visible (`AT_RISK` o `SELECTED_VIEW`): la forma/marco se actualiza de inmediato al nuevo tier — sin animación de transición especificada más allá del cambio discreto instantáneo (U-2 de Héroes rechaza explícitamente un gradiente de color, y ninguna animación intra-tier está definida; Héroes OQ-8 ya flagea si se necesita una señal intra-banda como pregunta de playtest, no resuelta aquí). **Flag de playtest (añadido en review)**: un corte discreto instantáneo en un momento de peso narrativo (Sólida→Legendaria justo antes de una muerte) puede leerse como glitch en vez de como declaración deliberada; validar en playtest si necesita un breve destello de confirmación de un frame (no un gradiente) para leerse como intencional. Owner: `ux-designer` + `art-director`; agrupar con Héroes OQ-8.
- **Si `world_to_screen_transform` (F2) proyecta un marcador fuera del viewport actual** (héroe detrás de cámara, fuera de pantalla): el elemento anclado a mundo afectado (barra de vida, readout de peligro, anillo de `guard_radius`) simplemente no se dibuja ese frame — ningún indicador/flecha de fuera-de-pantalla está especificado en este GDD (sería una adición de nivel Discovery, fuera del alcance MVP por la decisión de "solo HUD en sesión activa").

## Dependencies

**Cross-reference check** (bidireccionalidad contra los 5 GDDs de dependencia, confirmada vía grep): Combate/Daño, Control y Selección de Unidades, Temporizador de Preparación/Ritual y Encuentro con Kaiju **ya listan a UI/HUD** como dependiente hacia abajo (actualmente etiquetados "Sin GDD" — a des-flaggear en Fase 5). **Hueco encontrado**: la tabla de Dependencies de `sistema-de-heroes.md` no tenía fila para UI/HUD pese a poseer los UI Requirements U-1..U-7 que este GDD implementa directamente (Sección C, Core Rule 6) — corregido en esta sesión.

**Dependencias hacia arriba (upstream):**

| Sistema | Tipo | Interfaz | Estado |
|---|---|---|---|
| Combate/Daño | Dura | `current_health`/`max_health`, estado de enganche, eventos de golpe, tasa de daño entrante (CU-1/CU-2/CU-3) | ✅ Approved |
| Sistema de Héroes | Dura | Tier de `relic_quality`, snapshot D/T/P, prioridad de selección, `asymmetric_element`/`relic_category` (U-1..U-7) | ✅ Approved |
| Control y Selección de Unidades | Dura | Selection set, método de input activo, rectángulo de box-select, posición del cursor virtual | Designed |
| Input | Dura | Consume las acciones `ui_*` en contextos de menú/`BLESSING_SELECT`, `active_input_method` (iconos de prompt; NO para visibilidad del anillo de foco — ver `input.md` Regla Núcleo 3), e `input_lockout_active` (freeze de HUD durante `DEATH_HOLD`). La pantalla de remapeo de controles la posee UI/HUD y lee/escribe el InputMap que Input expone | Designed (`input.md`) — bidireccionalidad registrada 2026-08-19 |
| Temporizador de Preparación/Ritual | Dura | `current_phase`, `time_remaining_to_climax_s`, `imminent_local_progress` | ✅ Approved |
| Encuentro con Kaiju | Dura | Estado del ciclo de intención, `ENRAGED`, `telegraph_progress`, marcas + razón de cancelación, `time_to_death`, `incoming_damage_rate_total`, `STAGGERED`, evento de victoria/derrota | ✅ Approved |
| Datos de Era/Civilización | Dura | Constantes `world_unit_scale`=48, `camera_pan_speed`=30, `zoom_min`=0.5, `zoom_max`=1.5 | Designed |
| Reliquias/Bendiciones | Dura | Expone cargas (RU-1), `can_invoke`/onboarding (RU-2/2b), oferta 3-choose-1 con identidad glanceable + `band_headroom` (RU-3/3b), `active_blessings: list` (RU-4). El draft corre en `CLIMAX` en cámara lenta | ✅ Approved (`reliquias-bendiciones.md`) — desbloquea AC-U30/OQ-U4 |

**Dependientes hacia abajo (downstream):**

| Sistema | Tipo | Interfaz |
|---|---|---|
| Accesibilidad | Dura | Consume los toggles/contratos de accesibilidad que este GDD define (flash reducido global, ≥3 canales redundantes por daltonismo) como base sobre la que construye |

**Alcance del contrato de accesibilidad (aclarado en review)**: lo que este GDD define y garantiza es el **toggle de flash reducido global** (F3 + escalada IMMINENT) y la **redundancia de ≥3 canales sin depender de color** (HU-10, verificado por AC-U29). Lo que este GDD **NO** define y queda como responsabilidad del sistema de Accesibilidad downstream: escala de UI / tamaño de texto, la elección concreta de la herramienta/método de simulación CVD y su barra de aprobación, y cualquier exposición a lector de pantalla. **Nota Godot 4.6 (godot-specialist)**: la integración AccessKit de 4.5 (exposición del árbol de `Control` a tecnología asistiva / lector de pantalla) es un concern downstream *separado y no relacionado* del contrato de tasa de flash — AccessKit no provee límite de fotosensibilidad ni "reduced motion" a nivel de motor, así que F3 permanece como implementación custom correcta. No conflacionar ambos.

**Nota bidireccional**: la relación con Reliquias/Bendiciones está **confirmada** — `reliquias-bendiciones.md` (Approved 2026-08-18) define el contrato en su sección UI Requirements (RU-1..RU-6), coincidiendo con lo que este GDD asumía. AC-U30/OQ-U4 desbloqueados.

## Tuning Knobs

*(Derivado directamente de las tablas de variables de F1–F3 — sin re-spawn de especialista; las fórmulas ya llevan rangos definidos.)*

| Knob | Symbol | Type | Default | Safe Range | Qué se rompe en extremos |
|---|---|---|---|---|---|
| Umbral de disparo instantáneo | `T_instant` | float | 5.0s | 3.0–8.0s | <3.0s: una muerte en ~3–4s aún puede colarse con poco aviso; >8.0s: el readout salta abruptamente para amenazas que la histéresis habría surfaceado de forma suave, añadiendo ruido. Debe mantenerse `T_instant < T_show` siempre. |
| Umbral de aparición del readout | `T_show` | float | 30.0s | 20.0–40.0s | <20s: la ventana de visibilidad cae bajo el objetivo de ~30s de Héroes (OQ-6); >40s: el readout aparece demasiado pronto y pierde urgencia, compitiendo por atención con el resto del HUD |
| Umbral de desaparición del readout | `T_hide` | float | 38.0s | `T_show`+4 a `T_show`+15 | Por debajo del piso: la banda muerta se estrecha demasiado y vuelve el parpadeo; por encima del techo: el readout queda "pegado" mucho después de que el peligro pasó |
| Duración mínima visible | `min_visible_s` | float | 4.0s | 2.0–8.0s | <2.0s: aún vulnerable a parpadeo bajo oscilación rápida; >8.0s: respuesta lenta a una recuperación real del héroe |
| Ventana de debounce de entrada | `debounce_on_s` | float | 0.5s | 0.2–1.5s | <0.2s: picos de un solo frame disparan falsos positivos; >1.5s: el peligro real tarda en anunciarse, violando "informar, nunca emboscar" (Pilar 4) |
| Amplitud de pulso de viñeta | `amplitude` | float | 0.25 | 0.15–0.35 | <0.15: el pulso es casi invisible sobre la base, anulando su propósito de canal redundante; >0.35: combinado con la base del tercio 3 (0.75) satura cerca de 1.0, perdiendo granularidad de escalada |
| Duración del pulso de feedback de Sacrificio | `sacrifice_feedback_pulse_s` | float | 0.15s | 0.08–0.3s | <0.08s: imperceptible en pantallas de alta tasa de refresco; >0.3s: se siente lento, retrasa la siguiente orden del jugador. *(Refina Core Rule 7: "un frame" era dependiente de framerate — este knob lo vuelve una duración real.)* |

**Dependencia de tuning conjunto (flageada en review)**: el default de `T_hide`=38.0s solo cae dentro de su propio rango seguro (`T_show`+4 a `T_show`+15) cuando `T_show`=30.0. Si `T_show` se re-tunea a un extremo sin re-tunear `T_hide`, el default queda fuera de banda — p. ej. a `T_show`=20.0 el techo seguro es 35.0s, por debajo del default 38.0s. **Regla**: al mover `T_show`, recomputar y re-validar `T_hide` (y confirmar `T_instant < T_show`). Estos tres no son independientes.

**No son knobs propios (referenciados, no duplicados)**: `base(third)` {0.25, 0.50, 0.75} y `freq(third)` {1,2,3 Hz} están bloqueados por la identidad de "3 tercios" y el tope duro de fotosensibilidad (KV-10) — no se exponen como configurables. `telegraph_duration_s` (dueño: Encuentro con Kaiju) y `guard_radius` (dueño: Sistema de Héroes) son consumidos por F3 y el anillo de marca respectivamente, pero cambiarlos se hace en sus GDDs dueños — re-escalan este sistema automáticamente sin tocar UI/HUD.

## Visual/Audio Requirements

*(`art-director` consultado — REQUIRED, no opcional, para sistemas de categoría UI. Leyó `design/art/art-bible.md` completo.)*

**Health bars** (CU-1, CV-1): fill drena Hueso→Sangre Vieja (art bible 4.4), animación lineal sin rebote elástico (7.3 — el rebote lee como arcade, rompe el tono reverente). Marco en Tier 1 de 7.4 (rectángulo simple con reborde emplomado, Hueso) — nunca dorado, no es de origen relicario. Umbrales (50%/25%/crítico) disparan una señal diegética adicional (grietas extendiéndose en el marco, o un motivo de brasa/vela apagándose) + escalera de audio + pulso háptico en crítico — el tercer canal redundante más allá de la longitud de la barra.

**Contorno de selección** (3.3/4.4): Acero Violeta-Ceniza, solo contorno sin relleno, con pulso de "respiración" + carillón suave (7.5). Prioridad hero>tropa se lee por una muesca de forma en el contorno del héroe, posicionada en su elemento asimétrico — no por tamaño. Tropa = anillo cerrado simple; héroe = mismo anillo con una interrupción de forma.

**Timer ritual**: sin precedente directo en el art bible — vasija/arco en Ocre/Piedra Fría, con el tinte del relleno escalando hacia Acero Violeta-Ceniza a medida que crece el dread (NO hacia Hueso/Sangre Vieja, que 4.2 reserva estrictamente para el campo semántico vida/costo). `PREPARATION`: drenaje lento, mínimo movimiento. `IMMINENT`: reutiliza el motivo de grieta de vitral de 2.2/2.5 — fracturas capilares avanzan sobre la vasija, la tasa de drenaje se acelera visualmente. `CLIMAX`: las fracturas se resuelven / la vasija se rompe o se enciende hacia el estado de combate. El tinte de color permanece terciario, según el requisito de escalada multi-canal. *Open Question: la silueta exacta del contenedor no está especificada en ningún lado del art bible — necesita un pase de concepto, no solo una regla escrita.*

**Readout de veredicto del héroe** (U-1..U-4): anclado al elemento asimétrico (5.1/5.2), mapeado sobre la lógica de tiers de marco ya existente en 7.4 en vez de inventar una gramática nueva. Delgada = tratamiento tipo Tier-1 (línea simple delgada) sobre el elemento. Sólida = tratamiento tipo Tier-2 (sólido/más grueso, con detalle de esquina), aún en Hueso/Piedra Fría — sin dorado. **Legendaria**: acento dorado restringido — una línea emplomada dorada delgada trabajada en la construcción de la silueta, no el bloom/glow completo que 4.5 reserva como sello exclusivo del dorado post-muerte. *(Decisión del usuario: SÍ introducir este acento dorado pre-muerte, distinto del tratamiento de reliquia confirmada — riesgo aceptado conscientemente.)*

**Viñeta periférica de telegrafío del kaiju** (KV-1b): eco de pantalla del motivo de grieta 2.2, ya poseído por el telegrafío del cuerpo del kaiju (encuentro-con-kaiju.md). Tercio 1 (0–4.6s): pulso tenue, lento, de borde suave. Tercio 2 (4.6–9.3s): frecuencia de pulso sube, fracturas capilares avanzan desde el borde. Tercio 3 (9.3–14s): pulso más rápido (tope duro ≤3/seg, KV-10), fracturas totalmente formadas, viñeta de mayor contraste; el color vira hacia un eco cálido de borde (espejando la inversión "luz a través del kaiju" de 2.2) como cue estrictamente terciario. Modo flash-reducido sustituye por una rampa suave de brillo/densidad a través de los mismos tercios, sin parpadeo discreto. *Open Question: la escalada de audio no está especificada en el art bible — coordinar cadencia con sound-designer.*

**Anillo de `guard_radius`**: anillo delgado sin relleno (convención de 4.4), pero en la familia de color de esbirros/kaiju (`#5A6B72`, 4.2/4.4) en vez del Acero de selección del jugador — mantiene sin ambigüedad de quién es el marcador (concepto de targeting propiedad del kaiju, no de selección del jugador). Sin pulso por defecto; el lenguaje de pulso queda reservado para selección (7.5) salvo que encuentro-con-kaiju.md especifique lo contrario.

**Feedback de orden de Sacrificio** (contrato provisional, Core Rule 7): vocabulario nuevo, sin precedente en el art bible — adoptado conscientemente en esta sesión. Cursor pendiente: silueta solemne de reliquiario, Piedra Fría/Hueso neutro, sin dorado (la muerte aún no ocurrió, el test de la Principio A no se cumple). Pulso de confirmación: bloom lento único sobre la silueta del héroe, eco del motivo de luz cálida única de 2.3 (anticipatorio, no dorado pleno). Pulso de rechazo: flash frío de Acero con firma de movimiento distinta (doble parpadeo rápido vs. el bloom lento único de aceptación) — el color nunca es el único diferenciador. *(Decisión del usuario: adoptado como propuesto; queda como candidato a incorporarse formalmente al art bible cuando se audite ese documento.)*

**Regla dura en todos los elementos anteriores**: sin texto editorializante en ningún caso, sin números de daño flotantes, ≥3 canales redundantes por cada señal de escalada (forma/marco + movimiento como primarios, color como terciario).

📌 **UX Flag**: `/ux-design` debe correr contra este HUD antes de escribir epics — la silueta de la vasija del timer, el vocabulario del cursor de Sacrificio, y el detalle de targeting con gamepad/sin cursor necesitan un pase de flujo de interacción más allá de la dirección de arte.

## UI Requirements

Como UI/HUD *es* el sistema de UI, esta sección consolida los requisitos numerados y testeables establecidos en Detailed Design y Visual/Audio en un checklist limpio que Acceptance Criteria mapea directamente:

- **HU-1**: Barras de vida visibles solo si la unidad está seleccionada O por debajo de vida máxima (Core Rule 3).
- **HU-2**: El contorno de selección diferencia héroe de tropa por una muesca de forma, nunca solo por tamaño o color (Core Rule 4, hereda U-6/AC-H33 de Héroes).
- **HU-3**: El timer ritual siempre muestra la fase actual + tiempo restante mientras la era está activa, en forma diegética, con las 3 fases distinguibles a simple vista (Core Rule 5).
- **HU-4**: El readout de veredicto del héroe es visible solo cuando `hero_risk_state=ON` (F1, por cualquiera de sus dos caminos — histéresis o disparo instantáneo `<T_instant`) o el héroe está seleccionado; se congela al entrar `DYING`; usa 3 estados discretos por forma, nunca gradiente de color (Core Rule 6).
- **HU-11**: Cuando un héroe cruza a `AT_RISK`/`DYING` fuera de pantalla o no seleccionado, el director de atención dispara sus 3 canales redundantes (marcador de borde direccional + sting de audio/háptico + empujón de cámara) y cesa al entrar el héroe a vista o confirmarse `DEAD` (Core Rule 6b).
- **HU-5**: El feedback de orden de Sacrificio muestra señales distintas para `PENDING`/`CONFIRMED`/rechazo, nunca texto (Core Rule 7).
- **HU-6**: La viñeta de telegrafío del kaiju pulsa en 3 tercios explícitos, con tope de 3 flashes/seg, y el toggle de flash reducido se aplica globalmente a todo elemento que parpadee (Core Rule 8 + Edge Case correspondiente).
- **HU-7**: El anillo de `guard_radius` se renderiza al radio correcto (4.0 world units) en un color distinto al de selección del jugador (Core Rule 9).
- **HU-8**: Ningún elemento del sistema muestra texto editorializante en ningún momento (Core Rule 10).
- **HU-9**: Ningún elemento de HUD acepta input directo salvo el cursor virtual de gamepad, cuya apariencia (no comportamiento) posee este sistema (Core Rule 11).
- **HU-10**: Toda señal de escalada (readout de peligro, tier de reliquia, fase IMMINENT, telegrafío) es distinguible usando ≥3 canales redundantes, verificable sin depender del canal de color.

## Acceptance Criteria

*(`qa-lead` consultado — MANDATORY, Sección H de alto riesgo. Formato Dado/Cuando/Entonces + etiqueta de tipo de evidencia. ACs bloqueadas llevan tag explícito + línea "Mock Contract Assumptions", siguiendo el patrón de AC-H11/H25/H29 de Héroes y AC-K58 de Encuentro con Kaiju.)*

**AC-U01 — Contrato read-only** **[Integration]**. Dado un ciclo de frames con Combate/Héroes/Control/Temporizador/Kaiju mockeados, cuando UI/HUD procesa su estado, entonces ningún método de escritura de esos sistemas es invocado, salvo el pulso de feedback de Sacrificio (ver AC-U17/U18).

**AC-U02 — Composición de regiones** **[Integration]** (re-taggeado desde [UI] en review: es una verificación estructural del árbol de escena, no de "feel" subjetivo). Dado el HUD activo, cuando se inspecciona el árbol de nodos, entonces existen exactamente panel inferior, timer superior-centro, overlays anclados a mundo (en `CanvasLayer`, cada uno con `mouse_filter=MOUSE_FILTER_IGNORE`) y viñeta periférica — y ningún minimapa.

**AC-U03 — Gate de barra de vida** **[Logic/unit]**. Dado `selected` y `current_health<max_health` como inputs booleanos puros, cuando cualquiera es verdadero la barra pasa a `VISIBLE`; cuando ambos son falsos, pasa a `HIDDEN`.

**AC-U04 — Paleta de barra de vida** **[Logic/unit]** (re-taggeado en review desde [Visual/Feel]: es determinista y automatable). Dado el fill de una barra visible muestreado a 0% / 50% / 100% de drenado, cuando cada color muestreado se compara contra las paradas de gradiente Hueso→Sangre Vieja definidas en CU-1/art-bible 4.4, entonces cada uno coincide dentro de **ΔE ≤ 2** (CIE76).

**AC-U05 — Grafía héroe-sobre-tropa** **[UI]**. Dado una selección que resuelve a héroe sobre tropa superpuesta, cuando se renderiza el marcador, entonces usa una forma distinta (muesca), no solo tamaño/color.

**AC-U06 — Contorno de tropa** **[Visual/Feel]**. Dado una tropa seleccionada, cuando se renderiza, entonces el contorno es un anillo cerrado sin relleno.

**AC-U07 — Timer nunca digital** **[UI]**. Dado cualquier fase del timer, cuando se inspecciona el elemento, entonces no existe ningún readout numérico de reloj digital como forma primaria.

**AC-U08 — 3 fases distinguibles** **[Visual/Feel]**. Dado screenshots de PREPARATION/IMMINENT/CLIMAX con el canal de color desactivado y sin texto de HUD, cuando ≥3 testers independientes identifican la fase solo por forma+movimiento, entonces los 3 coinciden en la fase correcta en las 3 fases (9/9 identificaciones correctas).

**AC-U09 — Escalada IMMINENT multi-canal** **[UI]**. Dado IMMINENT activo con el canal de color desactivado (simulación), cuando se observa el elemento, entonces sigue siendo legible vía forma/movimiento.

**AC-U10 — F1 min() elige la fuente más urgente** **[Logic/unit]**. Dado `hero_current_health=340`, `incoming_damage_rate_total=52.0`, `time_to_death=26.0`, cuando se evalúa F1, entonces `danger_time_s=6.54` (no 26.0), replicando el worked example del GDD.

**AC-U11 — Guarda de división por cero** **[Logic/unit]**. Dado `incoming_damage_rate_total=0`, cuando se evalúa F1, entonces `danger_time_s` cae en `time_to_death` sin excepción ni NaN.

**AC-U12 — Histéresis, encendido** **[Logic/unit]**. Dado `danger_time_s≤30.0` (pero `≥T_instant`=5.0) sostenido ≥`debounce_on_s`=0.5s, cuando se evalúa, entonces `hero_risk_state` pasa a ON; un pico de un frame no lo activa.

**AC-U12b — Disparo instantáneo salta debounce (muerte por ráfaga)** **[Logic/unit]**. Dado `danger_time_s < T_instant`=5.0s en un solo frame (sin sostén previo) y `hero_risk_state=OFF`, cuando se evalúa F1, entonces `hero_risk_state` pasa a ON ese mismo frame, sin esperar `debounce_on_s`. Confirma que una muerte más rápida que la ventana de debounce nunca queda sin readout.

**AC-U13 — Histéresis, apagado (temporizado)** **[Logic/unit]** (reescrito en review: la versión previa mezclaba precondición, disparo y resultado diferido sin reloj de referencia). Dado `hero_risk_state` pasa a ON en `t=0` y `danger_time_s≥T_hide`=38.0 a partir de `t=2.0s`, cuando se muestrea el estado a `t=2.0s / t=3.9s / t=4.0s`, entonces permanece ON hasta `t=3.9s` (cumpliendo `min_visible_s`=4.0s desde el encendido) y pasa a OFF exactamente en `t=4.0s`.

**AC-U13b — Histéresis, cancelación de apagado pendiente** **[Logic/unit]** (caso reset, companion de AC-U13). Dado `hero_risk_state=ON` con un apagado pendiente (`danger_time_s≥T_hide` pero aún dentro de `min_visible_s`), cuando `danger_time_s` vuelve a caer por debajo de `T_hide` antes de cumplirse `min_visible_s`, entonces el apagado pendiente se cancela y el estado permanece ON (no parpadea a OFF).

**AC-U14 — Visibilidad = riesgo O selección** **[Logic/unit]**. Dado `hero_risk_state=OFF` y `selected=true` (o viceversa), cuando se evalúa la OR pura, entonces el readout se muestra en ambos casos.

**AC-U15 — 3 tiers por forma** **[UI]**. Dado Delgada/Sólida/Legendaria, cuando se comparan en escala de grises, entonces siguen siendo distinguibles por silueta, no por gradiente.

**AC-U16 — Freeze al entrar DYING** **[Integration]**. Dado un héroe que cruza a `DYING` con snapshot D/T/P, cuando llegan actualizaciones posteriores del mock de Héroes, entonces el readout no cambia hasta `DEAD`.

**AC-U17 — Cursor PENDING distinto** **(bloqueado — verbo de Sacrificio y D-gate sin resolver: Combate OQ-2/Héroes OQ-2/Control OQ-2)** **[UI]**. *Mock Contract Assumptions: mock expone `order_state ∈ {IDLE,PENDING,CONFIRMED,REJECTED}`.* Dado `order_state=PENDING` del mock, cuando se renderiza, entonces el cursor usa una silueta distinta de mover/atacar.

**AC-U18 — Pulso confirm/reject distintos** **(mismo bloqueo que AC-U17)** **[UI]**. Dado `order_state` pasa a `CONFIRMED` o `REJECTED` desde el mock, cuando se renderiza el pulso, entonces confirm (bloom lento) y reject (doble parpadeo frío) son distinguibles por forma/movimiento, no solo color.

**AC-U19 — F3 tope de frecuencia** **[Logic/unit]**. Dado los 3 tercios, cuando se evalúa `freq(third)`, entonces el máximo es exactamente 3.0Hz, nunca superado.

**AC-U20 — F3 modo flash-reducido** **[Logic/unit]**. Dado modo flash-reducido activo, cuando se evalúa la intensidad en cualquier punto del tercio, entonces es una rampa monótona sin término oscilante.

**AC-U21 — F3 identidad de tercio** **[Logic/unit]**. Dado `telegraph_progress` cruzando 0.33/0.66, cuando se evalúa `base(third)`, entonces salta discretamente entre 0.25/0.50/0.75.

**AC-U22 — F3 clamp de salida** **[Logic/unit]**. Dado inputs de borde (`third=2`, pico de oscilación), cuando se evalúa la fórmula completa, entonces la salida permanece en `[0.0,1.0]`.

**AC-U23 — Toggle de flash-reducido es global** **[Integration]**. Dado el toggle activado, cuando se inspeccionan todos los elementos que pulsan (viñeta F3 y escalada IMMINENT), entonces ambos cambian a modo sin parpadeo, no solo el kaiju.

**AC-U24 — Anillo de guard_radius** **[Integration]**. Dado `marked_target` expuesto por el mock de Encuentro con Kaiju (contrato Approved), cuando se renderiza el anillo, entonces su radio en pantalla corresponde a 4.0 world units vía F2.

**AC-U25 — Color del anillo distinto** **[Visual/Feel]**. Dado el anillo de guard_radius junto a un contorno de selección, cuando se comparan, entonces usan paletas distintas (familia kaiju vs. Acero de selección).

**AC-U26 — F2 proyección** **[Logic/unit]**. Dado cámara (100,50), zoom=1.0, viewport 1920×1080, objetivo (120,50), cuando se evalúa F2, entonces `screen_pos_px=(1920,540)`; dado un objetivo fuera de cámara, entonces el resultado no se clampea al viewport.

**AC-U27 — Sin texto editorializante** **[Logic/unit]** — BLOCKING (re-taggeado desde [UI]/advisory en review: es un barrido determinista contra una lista fija, y hace cumplir una "regla dura", Core Rule 10 — corresponde gate bloqueante). Dado un barrido de todos los elementos con texto, cuando se comparan contra una lista constante de frases prohibidas ("¡Peligro!", "¡Muerte heroica!", etc.), entonces ninguna coincide (comparación exacta, sin juicio del tester).

**AC-U28 — Sin input directo salvo cursor gamepad** **[Integration]**. Dado un click/tap sobre cualquier elemento de HUD, cuando se procesa el input, entonces no es consumido por el HUD, excepto el dibujo de apariencia del cursor virtual de gamepad.

**AC-U29 — ≥3 canales sin color (HU-10)** **[Visual/Feel]**. Dado readout de riesgo, tier de reliquia, IMMINENT y viñeta de telegrafío bajo simulación de **protanopia + deuteranopia + tritanopia** (los tres tipos), cuando un tester identifica el estado actual de cada elemento usando solo forma/movimiento sobre una muestra fija de N estados por elemento, entonces la tasa de identificación correcta es **100%** en las tres simulaciones. (Herramienta de simulación CVD nombrada en el plan de QA; ver contrato de accesibilidad en Visual/Audio Requirements.)

**AC-U30 — Bendiciones activas en CLIMAX** **[Integration]** *(desbloqueado 2026-08-18 — Reliquias/Bendiciones Approved expone `active_blessings: list` vía RU-4, ya no es mock).* Dado la `active_blessings: list` real de Reliquias durante CLIMAX, cuando se renderiza, entonces el HUD la muestra sin mutarla (read-only). *(El contrato real reemplaza el Mock Contract Assumption previo.)*

**AC-U31 — `game_time_paused` congela animaciones** **(bloqueado — Permadeath en In Design, contrato no Approved)** **[Integration]**. *Mock Contract Assumptions: mock expone `game_time_paused: bool` por Permadeath Core Rule 4.* Dado el flag en `true` durante varios frames, cuando se muestrea el estado de cada animación del HUD dirigida por datos — **específicamente: (a) drenado de barra de vida, (b) cuenta atrás del timer ritual, (c) pulso de viñeta de telegrafío F3** — entonces ninguna de las tres avanza (verificación por-canal, no un chequeo genérico único).

**AC-U32 — Director de atención de muerte fuera de pantalla** **[Integration]**. Dado un héroe que cruza a `AT_RISK`/`DYING` mientras `world_to_screen_transform` (F2) lo proyecta fuera del viewport y no está seleccionado, cuando se procesa el frame, entonces se activan los tres canales del director (Core Rule 6b): (a) un marcador direccional clampeado al borde apuntando al héroe, (b) un evento de sting de audio + pulso háptico disparado una vez en la transición, (c) un evento de empujón de cámara; y cuando el héroe entra al viewport o se confirma `DEAD`, los tres cesan.

**AC-U33 — Legibilidad bajo N readouts simultáneos** **[Visual/Feel]** (cubre el hueco de escena señalado en review; advisory). Dado 3+ héroes simultáneamente `AT_RISK` durante CLIMAX junto con timer, viñeta, anillos y barras activos, cuando ≥3 testers inspeccionan una captura, entonces cada uno identifica correctamente el número de héroes en riesgo y su tier, y ninguno reporta oclusión que impida leer un readout individual. (Si falla, dispara la regla de priorización/agregación de OQ-U8.)

---

**Resumen de cobertura**: Core Rules 1–11 (incl. 6b) y HU-1..HU-10 cubiertos; F1 (ambos caminos: histéresis AC-U12/U13/U13b + instantáneo AC-U12b), F2 (AC-U26) y F3 (AC-U19..U22) cubiertos. Edge Cases ahora con AC dedicada donde faltaba: muerte por ráfaga (AC-U12b), director fuera de pantalla (AC-U32), apilamiento N-simultáneo (AC-U33). **Bloqueadas** (backfill pendiente cuando desbloqueen sus GDDs upstream, excluidas de la afirmación de cobertura hasta entonces): AC-U17/U18 (verbo de Sacrificio — Combate/Héroes/Control OQ-2; **riesgo mayor** — el mock asume una *máquina de estados completa* `order_state ∈ {IDLE,PENDING,CONFIRMED,REJECTED}` para un verbo aún inexistente; si upstream aterriza en un sacrificio instantáneo sin confirmación, la *forma* del mock será incorrecta, no solo incompleta — reescribir, no backfillear), AC-U30 (Reliquias/Bendiciones sin GDD), AC-U31 (Permadeath en In Design, no Approved).

## Open Questions

- **OQ-U1 — Silueta concreta de la vasija/arco del timer ritual**: el art bible no especifica la forma del contenedor diegético. Owner: `ux-designer` + `art-director` (pase de concepto en `/ux-design`). Target: Pre-Producción, antes de epics.
- **OQ-U2 — Escalada de audio de la viñeta de telegrafío**: F3 define el canal visual de 3 tercios, pero la cadencia de audio que lo acompaña no está especificada en el art bible. Owner: `sound-designer` (coordinar con Encuentro con Kaiju KA-1). Target: al diseñar Audio (sistema #16).
- **OQ-U3 — Verbo y confirm-step del comando Sacrificio (bloqueante compartido)**: UI/HUD define solo el feedback visual provisional (Core Rule 7, AC-U17/U18 bloqueadas). El verbo de entrada real y el D-gate siguen sin resolver en Combate OQ-2 / Héroes OQ-2 / Control OQ-2. Owner: `game-designer` + `gameplay-programmer`. Target: al resolver el trío de OQ-2 upstream (idealmente antes del vertical slice).
- **OQ-U4 — RESUELTO (2026-08-18)**: `reliquias-bendiciones.md` (Approved) define el contrato del HUD de CLIMAX en RU-1..RU-6 — cargas, `can_invoke`, oferta 3-choose-1, `active_blessings: list`. AC-U30 desbloqueada. *(Queda vivo OQ-U8: el análisis de overload del HUD de CLIMAX debe re-contar el draft de invocación como stream activo — flageado como bloqueante B2 en el cross-review 2026-08-18.)*
- **OQ-U5 — Contrato `game_time_paused` pendiente de Permadeath Approved**: Permadeath (In Design, sesión paralela) ya formaliza `game_time_paused` como flag de polling cooperativo en su Core Rule 4, pero aún no está Approved (AC-U31 bloqueada hasta entonces). Bajo riesgo — la forma del contrato ya se conoce. Owner: verificar al aprobar Permadeath. Target: cuando Permadeath llegue a Approved.
- **OQ-U6 — Valores de umbral/histéresis del readout de peligro afinables en playtest**: F1 fija defaults (`T_instant`=5s, `T_show`=30s, `T_hide`=38s, `min_visible_s`=4s, `debounce_on_s`=0.5s) que anclan el objetivo de ~30s de Héroes OQ-6, pero el balance real entre "aviso a tiempo" y "ruido de HUD" solo se valida jugando. Owner: `systems-designer` + `ux-designer`. Target: vertical slice.
- **OQ-U7 — Tasa de cambio de `time_to_death` no acotada por contrato**: F1 asume que `danger_time_s` decrece de forma razonablemente continua, pero solo el *rango de valor* de `time_to_death` está bloqueado por Encuentro con Kaiju ([18.5,∞)); su *tasa de cambio* (p. ej. un salto discontinuo por recálculo `ENRAGED`) no. El camino de disparo instantáneo (`T_instant`=5s) mitiga el peor caso, pero conviene que Encuentro con Kaiju confirme si un salto hacia abajo mayor que ~10s/frame es posible. Owner: `systems-designer` + verificar con Encuentro con Kaiju. Target: antes del vertical slice.
- **OQ-U8 — Regla de priorización/agregación y tope de overlays bajo apilamiento N-simultáneo**: sin límite ni prioridad, 3+ readouts `AT_RISK` durante CLIMAX (más timer/viñeta/anillos/barras) arriesgan sobrecarga sensorial y el presupuesto de <1000 draw calls. Se necesita una regla de agregación (p. ej. tira de roster compacta) y un tope suave. AC-U33 detecta el fallo. Owner: `ux-designer` + `ui-programmer`. Target: vertical slice.
