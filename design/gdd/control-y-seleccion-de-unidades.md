# Control y Selección de Unidades

> **Status**: In Design
> **Author**: usuario + agentes
> **Last Updated**: 2026-07-23
> **Implements Pillar**: Preparación Ritual, Clímax Explosivo (Pilar 3); soporte a Sacrificio con Peso (Pilar 1)

## Overview

El sistema de Control y Selección de Unidades es la capa que traduce las intenciones crudas del jugador (emitidas por el Input) en acciones concretas sobre el mundo: resuelve qué unidad recibe un clic, qué unidades caen dentro de un rectángulo de selección, adónde se dirige una orden de movimiento, y controla la cámara RTS (paneo y zoom). Toma las señales abstractas del Input (`select_requested`, `box_select_requested`, `move_commanded`, `pan_requested`, `zoom_requested`) y les da sentido espacial usando la escala del mundo (`world_unit_scale`=48px/tile). Es el punto de contacto táctil entre el jugador y su ejército: durante la Preparación, es cómo el jugador posiciona deliberadamente sus fuerzas (Pilar 3); durante el Clímax, es cómo comanda con precisión bajo presión. Su responsabilidad hacia el Pilar 1 es que la selección nunca sea ambigua — un héroe jamás debe recibir una orden fatal porque el jugador creyó haber seleccionado a otra unidad.

## Player Fantasy

La fantasía de este sistema es la de un comandante cuyo ejército responde con precisión — la sensación de que tu mano y tu intención son una sola cosa con las unidades en pantalla. Su capa directa se siente en cada clic de selección que aterriza en la unidad correcta, en cada rectángulo de arrastre que reúne exactamente al grupo que querías, en cada paneo de cámara que se detiene donde esperabas. Referencias como Warcraft 3 y StarCraft nailean esto: la selección se siente *instantánea y sin ambigüedad*, y la cámara es una extensión invisible de la atención del jugador. Su capa de infraestructura — resolver colisiones de punto, calcular qué cae en un rectángulo, transformar coordenadas de pantalla a mundo — es invisible cuando funciona. Pero la promesa emocional más importante es la del Pilar 1: en un juego donde la muerte es permanente, la confianza en el control debe ser absoluta. El jugador debe poder decir "yo elegí esto" y nunca "el juego seleccionó la unidad equivocada". La precisión aquí no es solo comodidad — es la base sobre la que descansa el peso de cada sacrificio.

## Detailed Design

### Core Rules

1. **Resolución de selección con desempate por prioridad**: al recibir `select_requested(screen_pos)` del Input, el sistema convierte `screen_pos` a coordenadas de mundo y busca unidades bajo/cerca del punto. Regla de desempate en orden estricto: (a) si hay uno o más héroes dentro del radio de selección, se selecciona el **héroe más cercano al punto de clic** (dentro de la misma prioridad de tipo, gana la distancia); (b) si no hay héroe pero hay tropas, se selecciona la tropa más cercana al punto; (c) si nada está dentro del radio, se deselecciona todo (clic en terreno vacío). Esta prioridad héroe>tropa protege el Pilar 1 — un clic ambiguo nunca prioriza una tropa sobre un héroe cercano.
2. **Box-select filtra por tipo**: al recibir `box_select_requested(rect)`, se seleccionan todas las unidades del jugador cuyo centro cae dentro del rectángulo (borde **inclusivo** — un centro exactamente sobre el borde cuenta como dentro). Si el rectángulo contiene tanto héroes como tropas, se seleccionan ambos (el arrastre es una intención explícita de "todo lo que está aquí", a diferencia del clic simple).
3. **Modelo de comando directo (estilo Warcraft 3)**: con unidades seleccionadas, `move_commanded(screen_pos)` envía a todas las unidades seleccionadas hacia esa posición de mundo. El sistema no valida el pathfinding en sí (eso pertenece al movimiento de unidades) — solo resuelve el destino y notifica a las unidades seleccionadas.
4. **Selección solo de unidades propias**: el jugador solo puede seleccionar sus propias unidades (héroes y tropas). Clic sobre un kaiju/esbirro no los selecciona — puede emitir una intención de "objetivo" para un comando de ataque, pero nunca los agrega al conjunto de selección del jugador.
5. **Control de cámara RTS**: el sistema posee la `Camera2D`. Consume `pan_requested(delta)` y `zoom_requested(delta)` del Input (solo activos en `RTS_COMMAND`), aplicando `camera_pan_speed`=30 world units/sec y clamp de zoom a `[zoom_min, zoom_max]` = `[0.5, 1.5]`. La cámara está acotada a los límites del mapa de la era activa (no se puede panear infinitamente al vacío).
6. **Cursor virtual para gamepad**: en modo gamepad (detectado vía `active_input_method` del Input), se muestra un cursor virtual movido por el stick analógico, con snap suave (magnetismo) hacia la unidad seleccionable más cercana. Esto preserva la metáfora espacial de selección del mouse sin forzar un remapeo directo. El cursor virtual solo existe en modo gamepad; se oculta al detectar mouse.

### States and Transitions

| Estado | Descripción | Transición desde | Transición hacia |
|---|---|---|---|
| `NONE_SELECTED` | Ninguna unidad seleccionada | Inicio, deselección, muerte de la última unidad seleccionada | `SINGLE_SELECTED`, `MULTI_SELECTED` |
| `SINGLE_SELECTED` | Exactamente una unidad seleccionada | Clic sobre una unidad | `NONE_SELECTED`, `MULTI_SELECTED`, `SINGLE_SELECTED` (otra unidad) |
| `MULTI_SELECTED` | Dos o más unidades seleccionadas | Box-select con 2+ unidades | `NONE_SELECTED`, `SINGLE_SELECTED`, `MULTI_SELECTED` (otro box) |

- La selección se limpia automáticamente si todas las unidades seleccionadas mueren o dejan de existir (ver Edge Cases).
- El control de cámara es ortogonal a estos estados — funciona en cualquiera de los tres.

### Interactions with Other Systems

| Sistema | Dirección | Interfaz |
|---|---|---|
| Input | Input → este sistema | Consume `select_requested(screen_pos)`, `box_select_requested(rect)`, `move_commanded(screen_pos)`, `pan_requested(delta)`, `zoom_requested(delta)` |
| Sistema de Tropas | bidireccional | Consulta posiciones/hitboxes de tropas para resolver selección; notifica órdenes de movimiento a las tropas seleccionadas |
| Sistema de Héroes | bidireccional | Consulta posiciones/hitboxes de héroes (con prioridad de desempate); notifica órdenes a los héroes seleccionados |
| Datos de Era/Civilización | consumidor | Lee los límites del mapa de la era activa (para acotar la cámara) y `world_unit_scale` para transformar pantalla↔mundo |
| Combate/Daño | este sistema → Combate | Provee el conjunto de unidades seleccionadas y el objetivo de un comando de ataque (clic sobre enemigo) |
| UI/HUD | este sistema → UI | Expone el conjunto de selección actual para que la UI muestre indicadores de selección (art bible Sección 3.3, contorno Acero Violeta-Ceniza) |

*(Nota: Sistema de Tropas y Sistema de Héroes ya tienen GDD y sus interfaces están confirmadas. Combate/Daño y UI/HUD aún no tienen GDD — esas dos interfaces siguen siendo contratos propuestos. La interfaz con Input está confirmada bidireccionalmente contra `design/gdd/input.md`.)*

## Formulas

*(Nota: box-select no necesita fórmula — es un test punto-en-rectángulo trivial tras convertir las esquinas del rect vía la Fórmula 2. Pertenece a las reglas de implementación, no aquí.)*

### Fórmula 1 — Radio de Selección (`select_radius_world`)

Radio proporcional al tamaño del sprite (no plano), para que la "aura de ambigüedad" del héroe quede acotada a cuánto ocupa realmente en pantalla — clave para el Pilar 1.

`select_radius_world = unit_visual_radius_world + (click_tolerance_px × zoom / world_unit_scale)`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Radio visual de unidad | `unit_visual_radius_world` | float | tropa ≈ 0.33–0.5, héroe ≈ 0.5–1.0 (world units) | Mitad del diámetro clicable del sprite en world units. Propiedad per-tipo de las futuras GDDs de Tropas/Héroes (`sprite_diameter_px / world_unit_scale / 2`) |
| Tolerancia de clic | `click_tolerance_px` | float | 4–10 (tuning knob de este sistema) | Perdón plano en píxeles de pantalla de referencia, uniforme a todo tipo de unidad |
| Zoom | `zoom` | float | [0.5, 1.5] | Zoom de cámara actual (registrado) |
| Escala de mundo | `world_unit_scale` | int | 48 (constante registrada) | px por world unit a zoom 1.0 |
| **Radio de selección** | `select_radius_world` | float | ≈ 0.35–1.2 (world units) | Radio en el que un clic se considera "sobre" esta unidad |

**Ejemplo**: héroe de 64px → `64/48/2 = 0.667`. Con `click_tolerance_px=6`, `zoom=1.0` → término de tolerancia `6×1.0/48 = 0.125`. `select_radius_world = 0.792` world units (≈38px a zoom 1.0). Una tropa de 40px con el mismo setup: `0.417 + 0.125 = 0.542` (≈26px).

La conversión usa `zoom / world_unit_scale` para mantener el perdón de clic constante en píxeles de pantalla a cualquier zoom (más precisión al acercar, más world-units de tolerancia al alejar), mientras el radio visual de la unidad se mantiene constante en el espacio de mundo.

### Fórmula 2 — Transformación Pantalla→Mundo (`world_pos`)

**Crítico para la corrección del Pilar 1.** El `zoom` de `Camera2D` en Godot es **inverso** a la magnificación: valor de zoom menor = más acercado (más px por world unit), valor mayor = más alejado. Esto coincide con `zoom_min=0.5` documentado como "acercamiento táctico". Invertir esto es un bug clásico que rompería silenciosamente toda resolución clic→unidad.

`world_pos = camera_position_world + (screen_pos_px − viewport_size_px / 2) × (zoom / world_unit_scale)`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Posición de pantalla | `screen_pos_px` | Vector2(px) | [0, ancho]×[0, alto] | Posición cruda de clic/cursor en px de viewport |
| Tamaño de viewport | `viewport_size_px` | Vector2(px) | dependiente de resolución (ej. 1920×1080) | Dimensiones del viewport actual |
| Posición de cámara | `camera_position_world` | Vector2(world units) | acotada a límites del mapa de la era (Regla 5) | Centro de cámara en espacio de mundo |
| Zoom | `zoom` | float | [0.5, 1.5] | Zoom de cámara actual (registrado) |
| Escala de mundo | `world_unit_scale` | int | 48 (registrado) | px por world unit a zoom 1.0 |
| **Posición de mundo** | `world_pos` | Vector2(world units) | acotada a límites del mapa | Equivalente en mundo del clic de pantalla |

**Ejemplo**: viewport 1920×1080 (centro 960,540), clic en `(1200, 540)` (240px a la derecha del centro), `camera_position_world=(50,50)`, `zoom=1.0`. `world_units_per_px = 1.0/48 = 0.02083`. Offset `= (5.0, 0)`. `world_pos = (55.0, 50.0)` — coincide con `240px / 48 = 5 world units`. A `zoom=0.5`, el mismo offset resuelve a `240×0.5/48 = 2.5` world units (acercado → misma distancia de pantalla cubre menos mundo, correcto).

La inversa (`px_per_world_unit = world_unit_scale / zoom`) la necesitarán UI/HUD, minimapa y VFX para colocar marcadores sobre unidades.

### Fórmula 3 — Snap Magnético del Cursor Virtual de Gamepad

El pull nunca excede una fracción acotada del input crudo del stick (el jugador siempre puede salir de un "pozo"), y solo asiste cuando la dirección del stick ya concuerda con la dirección hacia la unidad — así empujar hacia otro lado nunca se siente peleado. Reutiliza el mismo desempate héroe>tropa de la Regla 1 para consistencia entre inputs (Pilar 1).

```
alignment = max(dot(stick_input_dir, to_unit_dir), 0)
falloff = clamp(1 − distance / snap_radius, 0, 1)
cursor_velocity_world = stick_input_dir × stick_input_mag × virtual_cursor_speed
                       + to_unit_dir × snap_strength × virtual_cursor_speed × falloff × alignment
```

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Dirección de stick | `stick_input_dir` | Vector2 (norm) | vector unitario o cero | Dirección del input crudo tras zona muerta (`stick_dead_zone`=0.20 de `input.md`) |
| Magnitud de stick | `stick_input_mag` | float | [0, 1] | Magnitud de deflexión tras remap de zona muerta |
| Dirección a unidad | `to_unit_dir` | Vector2 (norm) | vector unitario | Dirección del cursor a la unidad seleccionable más cercana (desempate héroe>tropa) |
| Distancia | `distance` | float | ≥ 0 (world units) | Distancia del cursor a esa unidad |
| Radio de snap | `snap_radius` | float | 0.6–1.5 (world units), default 1.0 | Radio en el que el magnetismo se activa |
| Fuerza de snap | `snap_strength` | float | 0.25–0.55, default 0.4 | Tope del pull como fracción de `virtual_cursor_speed` |
| Velocidad de cursor | `virtual_cursor_speed` | float | 18–26 world units/sec, default 22 | Velocidad de traslación propia del cursor |
| **Velocidad de cursor** | `cursor_velocity_world` | Vector2(world units/sec) | ≤ `(1+snap_strength) × virtual_cursor_speed` | Velocidad del cursor este frame |

**Ejemplo**: `distance=0.5`, `snap_radius=1.0` → `falloff=0.5`. Stick apuntando exacto a la unidad (`alignment=1`), deflexión completa (`stick_input_mag=1.0`), `virtual_cursor_speed=22`, `snap_strength=0.4`. Componente crudo = `22 units/sec`. Pull = `0.4×22×0.5×1 = 4.4 units/sec`. Total ≈ `26.4 units/sec` hacia la unidad — ~20% de asistencia cuando ya se apunta al objetivo, cayendo a cero al divergir el stick o salir de `snap_radius`. Como `snap_strength ≤ 0.55`, la asistencia nunca aporta más del 55% de la velocidad cruda: el jugador siempre retiene autoridad sobre la dirección final.

### Fórmula 4 — Paneo de Cámara Compensado por Zoom (Opción 2: compensación completa)

`effective_pan_speed_world = camera_pan_speed × zoom`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Velocidad base de paneo | `camera_pan_speed` | float | 30 (constante registrada) | world units/sec a zoom de referencia (owned por Datos de Era/Civilización) |
| Zoom | `zoom` | float | [0.5, 1.5] | Zoom de cámara actual (registrado) |
| **Velocidad efectiva de paneo** | `effective_pan_speed_world` | float | 15–45 (world units/sec) | Velocidad de traslación real aplicada este frame |

**Decisión**: se elige compensación completa para que la velocidad *percibida en pantalla* sea constante en todos los niveles de zoom (~1440 px/sec), en vez del comportamiento sin compensar que producía un swing de 3x (paneo más rápido justo en el modo táctico acercado, en tensión con el Pilar 3). A `zoom=1.0` (referencia) da exactamente `camera_pan_speed`=30, así que **no contradice el AC 23 del GDD de Input** (que mide a zoom 1.0). Efecto: paneo más lento en world-units al acercar (más control táctico), más rápido al alejar (traversal más ágil) — encaje natural con el Pilar 3.

**Ejemplo**: a `zoom=0.5` (acercado), `effective = 30×0.5 = 15` world units/sec → `15×96px = 1440 px/sec`. A `zoom=1.5` (alejado), `effective = 30×1.5 = 45` world units/sec → `45×32px = 1440 px/sec`. Velocidad de pantalla idéntica en ambos extremos.

## Edge Cases

- **Si una tropa está adyacente a un héroe** (~1 world unit): parte del espacio entre ambos cae dentro del `select_radius_world` del héroe, y un clic ahí resuelve al héroe por el desempate. Esto es *intencional* (Pilar 1, protege contra sub-seleccionar al héroe) — para seleccionar la tropa adyacente, hacer clic fuera del radio del héroe o usar box-select. El `click_tolerance_px` acotado (default 6) mantiene esa aura pequeña.
- **Si el jugador hace box-select sin arrastrar suficiente** (por debajo del `drag_threshold_px`=5 del Input): el Input ya lo resuelve como clic simple antes de llegar aquí — este sistema nunca recibe un `box_select_requested` con un rectángulo degenerado.
- **Si todas las unidades seleccionadas mueren** (ej. permadeath de un héroe seleccionado): la selección se limpia automáticamente a `NONE_SELECTED` en el mismo frame en que la última unidad deja de existir. No queda una "selección fantasma" apuntando a una unidad muerta.
- **Si el jugador ordena movimiento con selección mixta (héroes + tropas)**: todas las unidades seleccionadas reciben la orden hacia el mismo destino. Cada unidad resuelve su propio pathfinding (no es responsabilidad de este sistema); no hay formación impuesta en el MVP.
- **Si el clic de selección ocurre exactamente sobre un kaiju/esbirro** (unidad no seleccionable): no se agrega a la selección (Regla 4). Si había unidades propias seleccionadas, esto puede emitir una intención de "objetivo de ataque" a Combate/Daño; si no había selección, el clic se ignora (no deselecciona).
- **Si varios candidatos caen dentro del `snap_radius` del cursor de gamepad** (multitud): se elige el más cercano por distancia usando la misma prioridad héroe>tropa de la Regla 1 — nunca un peso distinto, para que gamepad y mouse se comporten idénticamente.
- **Si la cámara intenta panear más allá de los límites del mapa de la era**: se hace clamp a los límites (Regla 5) — la cámara nunca muestra el vacío fuera del mapa jugable, en ningún nivel de zoom.
- **Si el jugador hace zoom mientras panea simultáneamente**: ambas operaciones se aplican en el mismo frame de forma independiente; el clamp de zoom `[0.5, 1.5]` y el clamp de límites de mapa se aplican después de ambas.
- **Si se recibe una orden de movimiento con `NONE_SELECTED`** (ningún seleccionado): la orden se ignora silenciosamente — no hay a quién comandar, no es un error.

## Dependencies

**Dependencias hacia arriba (upstream — sistemas que este necesita):**

| Sistema | Tipo | Interfaz | Estado |
|---|---|---|---|
| Input | Dura | Consume `select_requested`, `box_select_requested`, `move_commanded`, `pan_requested`, `zoom_requested`, `active_input_method` | ✅ Diseñado — contrato confirmado bidireccionalmente contra `design/gdd/input.md` |
| Datos de Era/Civilización | Dura | Lee límites del mapa de la era activa (acotar cámara) y `world_unit_scale`=48 (transformar pantalla↔mundo) | ✅ Diseñado |
| Sistema de Tropas | Dura | Consulta posiciones/hitboxes de tropas + `unit_visual_radius_world` (Fórmula 1) | Sin GDD (contrato propuesto) |
| Sistema de Héroes | Dura | Consulta posiciones/hitboxes de héroes + `unit_visual_radius_world` (Fórmula 1) | ✅ Diseñado — contrato confirmado (`design/gdd/sistema-de-heroes.md`, prioridad héroe>tropa y radio ≥0.5) |

**Dependientes hacia abajo (downstream — sistemas que dependen de este):**

| Sistema | Tipo | Interfaz |
|---|---|---|
| Combate/Daño | Dura | Recibe el conjunto de unidades seleccionadas y el objetivo de un comando de ataque |
| UI/HUD | Dura | Recibe el conjunto de selección actual para renderizar indicadores (art bible Sección 3.3) |

**Nota bidireccional**: Sistema de Tropas y Sistema de Héroes ya tienen GDD y confirman su relación con este sistema (respetan la Fórmula 1 `select_radius` y la prioridad héroe>tropa). Falta que Combate/Daño y UI/HUD, cuando se diseñen, listen su relación con este sistema y respeten los contratos de la Sección C. La interfaz con Input y Datos de Era/Civilización ya está confirmada contra sus GDDs existentes.

## Tuning Knobs

| Knob | Símbolo | Tipo | Default | Rango seguro | Qué se rompe en extremos |
|---|---|---|---|---|---|
| Tolerancia de clic | `click_tolerance_px` | float | 6 | 4–10 | <4: clics precisos fallan por temblor de mano; >10: infla el aura de ambigüedad del héroe, arriesgando selección errónea (Pilar 1) |
| Fuerza de snap de gamepad | `snap_strength` | float | 0.4 | 0.25–0.55 | <0.25: el snap casi no ayuda, selección de gamepad frustrante; >0.55: el cursor "pelea" al jugador, difícil elegir una unidad específica en multitud |
| Radio de snap de gamepad | `snap_radius` | float | 1.0 (world units) | 0.6–1.5 | <0.6: el magnetismo casi nunca se activa; >1.5: el cursor salta entre unidades lejanas, sensación errática |
| Velocidad de cursor virtual | `virtual_cursor_speed` | float | 22 (world units/sec) | 18–26 | <18: cursor lento/sluggish; >26: difícil de detener con precisión |

**Enforcement**: los valores fuera de rango se clampan al límite más cercano al cargarse (consistente con el patrón ya establecido en el GDD de Guardado/Persistencia).

**Constantes consumidas de otros sistemas (no se duplican aquí, fuente de verdad indicada):**
- `camera_pan_speed`=30, `zoom_min`=0.5, `zoom_max`=1.5, `world_unit_scale`=48 → propiedad de **Datos de Era/Civilización** (registrados). Este sistema los aplica (Fórmula 4 compensa el paneo por zoom) pero no los redefine.
- `stick_dead_zone`=0.20, `zoom_step_fraction`=0.10, `drag_threshold_px`=5 → propiedad del **Sistema de Input**. Alimentan la resolución de cursor/zoom/box-select pero se tunean allá.

## Visual/Audio Requirements

Este sistema no renderiza el mundo, pero genera dos elementos visuales cuyo diseño detallado pertenece a UI/HUD y al art bible:
- **Rectángulo de box-select**: el contorno de arrastre mientras el jugador selecciona en área (debe seguir el lenguaje diegético del art bible; color Acero Violeta-Ceniza para consistencia con el estado de selección).
- **Feedback de audio de comando**: emitir señales que el sistema de Audio pueda escuchar (confirmación de selección, orden de movimiento) — este sistema provee el disparador, no el sonido.

## UI Requirements

- **Indicador de selección**: por cada unidad seleccionada, la UI muestra un contorno (art bible Sección 3.3/4.4 — Acero Violeta-Ceniza en alto valor/baja saturación, solo contorno delgado sin relleno). Este sistema expone el conjunto de selección; UI/HUD lo renderiza.
- **Cursor virtual de gamepad**: en modo gamepad, se muestra un cursor movido por stick con snap magnético (Fórmula 3). Su apariencia visual pertenece al art bible/UI, pero su comportamiento lo posee este sistema.
- **Rectángulo de box-select**: contorno de arrastre en vivo durante la selección en área.

**📌 UX Flag — Control y Selección de Unidades**: Este sistema tiene requisitos de UI. En Pre-Producción, ejecutar `/ux-design` para especificar el indicador de selección, el cursor virtual de gamepad y el rectángulo de box-select antes de escribir epics. Las stories que referencien esta UI deben citar `design/ux/[pantalla].md`.

## Acceptance Criteria

*(Validado por `qa-lead`. Formato GIVEN-WHEN-THEN. Criterios marcados [BLOQUEANTE, Pilar 1] tienen máxima prioridad.)*

### Core Rules

**AC-01** [BLOQUEANTE, Pilar 1]. Given un héroe y una o más tropas están ambos dentro del `select_radius_world` del punto de clic, When `select_requested(screen_pos)` se dispara, Then se selecciona el héroe y ninguna tropa, sin importar qué unidad esté geométricamente más cerca del punto.

**AC-02** [BLOQUEANTE, Pilar 1]. Given ningún héroe está dentro del `select_radius_world` pero una o más tropas sí, When `select_requested` se dispara, Then se selecciona la tropa más cercana al punto.

**AC-03** [BLOQUEANTE, Pilar 1]. Given dos o más tropas (sin héroe) caen dentro del radio, When `select_requested` se dispara, Then se selecciona la tropa cuyo centro está más cerca del punto de clic, y las demás no.

**AC-04** [BLOQUEANTE, Pilar 1]. Given ninguna unidad está dentro del radio del punto de clic, When `select_requested` se dispara, Then todas las unidades seleccionadas se deseleccionan y el estado pasa a `NONE_SELECTED`.

**AC-05** [BLOQUEANTE, Pilar 1, test negativo]. Given un héroe existe pero está fuera del `select_radius_world` del punto, y una tropa está dentro de su propio radio, When `select_requested` se dispara, Then se selecciona la tropa y NO el héroe fuera de rango — confirma que la prioridad aplica solo dentro-del-radio, nunca por búsqueda global héroe-primero.

**AC-05b** [BLOQUEANTE, Pilar 1, desempate multi-héroe]. Given dos héroes están ambos dentro del `select_radius_world` del punto de clic, When `select_requested` se dispara, Then se selecciona el héroe cuyo centro está más cerca del punto, y el otro no.

**AC-06** [BLOQUEANTE, Pilar 1]. Given un rectángulo de arrastre que contiene los centros de dos o más tropas y ningún héroe, When `box_select_requested(rect)` se dispara, Then todas las tropas contenidas se seleccionan y el estado pasa a `MULTI_SELECTED`.

**AC-07** [BLOQUEANTE, Pilar 1]. Given un rectángulo que contiene el centro de al menos un héroe y al menos una tropa, When `box_select_requested` se dispara, Then héroe(s) y tropa(s) se seleccionan juntos (box-select no aplica la exclusividad héroe>tropa del clic).

**AC-08**. Given el sprite de una unidad se superpone visualmente al borde del rectángulo pero el centro de la unidad cae *fuera*, When `box_select_requested` se dispara, Then esa unidad NO se selecciona. (Un centro exactamente *sobre* el borde SÍ cuenta como dentro — borde inclusivo, Regla 2.)

**AC-09** [Integration parcialmente bloqueado]. Given una o más unidades seleccionadas, When `move_commanded(screen_pos)` se dispara, Then cada unidad seleccionada recibe una orden hacia el mismo `world_pos` resuelto, y no ocurre validación de pathfinding en este sistema.

**AC-10** [Integration]. Given el punto de clic resuelve sobre un kaiju o esbirro, When `select_requested` se dispara, Then el kaiju/esbirro NO se agrega al conjunto de selección del jugador, y la selección previa no se ve afectada.

**AC-11**. Given el contexto `RTS_COMMAND` activo, When `pan_requested(delta)` se dispara a un `zoom` dado, Then la cámara se traslada a `effective_pan_speed_world = camera_pan_speed × zoom` (ver AC-F7/F8/F9).

**AC-12**. Given un `zoom_requested(delta)` que empujaría el zoom fuera de `[0.5, 1.5]`, When se aplica el zoom, Then el valor resultante se clampa al límite más cercano (0.5 o 1.5), nunca lo excede.

**AC-13**. Given `active_input_method` cambia de gamepad a mouse, When se detecta el cambio, Then el cursor virtual se oculta inmediatamente; al volver a gamepad, reaparece.

### State Transitions

**AC-14**. Given estado `NONE_SELECTED`, When el jugador hace clic sobre exactamente una unidad seleccionable, Then el estado pasa a `SINGLE_SELECTED` con esa unidad.

**AC-15**. Given estado `NONE_SELECTED`, When el jugador box-selecciona 2+ unidades, Then el estado pasa a `MULTI_SELECTED`.

**AC-16**. Given estado `SINGLE_SELECTED`, When el jugador box-selecciona un rectángulo con 2+ unidades, Then el estado pasa a `MULTI_SELECTED` con el nuevo resultado reemplazando la selección única previa.

**AC-17**. Given estado `SINGLE_SELECTED` con unidad A, When el jugador hace clic sobre una unidad seleccionable distinta B, Then el estado permanece `SINGLE_SELECTED` pero el conjunto cambia de {A} a {B} (A se deselecciona).

**AC-18** [BLOQUEANTE, Pilar 1, Integration parcialmente bloqueado]. Given `SINGLE_SELECTED` o `MULTI_SELECTED` con todas las unidades seleccionadas muriendo/siendo removidas en el mismo frame, When se procesa la muerte/remoción de la última, Then el estado pasa a `NONE_SELECTED` en ese mismo frame, sin referencia obsoleta a una unidad muerta en el conjunto.

**AC-19**. Given `MULTI_SELECTED` con 3 unidades y solo 1 muere, When se procesa la muerte, Then el estado permanece `MULTI_SELECTED` con las 2 supervivientes aún seleccionadas.

### Formulas

**AC-F1**. Given un héroe de sprite 64px con `world_unit_scale=48`, `click_tolerance_px=6`, `zoom=1.0`, When se computa `select_radius_world`, Then el resultado es `0.792` world units (±0.001), i.e. `64/48/2 + 6×1.0/48`.

**AC-F2**. Given el mismo setup con una tropa de sprite 40px, When se computa, Then el resultado es `0.542` world units (±0.001).

**AC-F3** [BLOQUEANTE, Pilar 1]. Given viewport `1920×1080`, `camera_position_world=(50,50)`, `zoom=1.0`, clic en `(1200, 540)`, When se computa `world_pos` vía Fórmula 2, Then el resultado es `(55.0, 50.0)` (±0.01) — un offset de 240px resuelve a exactamente 5.0 world units.

**AC-F4** [BLOQUEANTE, Pilar 1]. Given el mismo setup pero `zoom=0.5`, When se computa, Then el offset resuelve a `2.5` world units (no `10.0`) — prueba que el zoom se aplica como `zoom/world_unit_scale` (magnificación inversa). Es el test de regresión de mayor valor de toda la GDD: un signo invertido aquí rompería silenciosamente toda resolución clic→unidad.

**AC-F5**. Given `distance=0.5`, `snap_radius=1.0`, `alignment=1.0`, `stick_input_mag=1.0`, `virtual_cursor_speed=22`, `snap_strength=0.4`, When se computa `cursor_velocity_world`, Then la magnitud hacia la unidad es `26.4` world units/sec (±0.05): crudo `22.0` + pull `4.4`.

**AC-F6** [property test]. Given cualquier combinación de `distance`, `alignment`∈[0,1], `stick_input_mag`∈[0,1], y `snap_strength` en su máximo seguro 0.55, When se computa `cursor_velocity_world` sobre combinaciones con semilla fija, Then el componente de pull nunca excede `0.55 × virtual_cursor_speed` — el jugador siempre retiene autoridad direccional.

**AC-F7**. Given `camera_pan_speed=30`, `zoom=0.5`, When se computa `effective_pan_speed_world` y se convierte a px/sec (`×96`), Then el resultado es `15` world units/sec = `1440` px/sec.

**AC-F8**. Given el mismo setup pero `zoom=1.5` (`×32`), When se computa, Then el resultado es `45` world units/sec = `1440` px/sec — velocidad de pantalla idéntica a AC-F7, confirmando compensación completa.

**AC-F9**. Given `zoom=1.0`, When se computa `effective_pan_speed_world`, Then el resultado es exactamente `30` world units/sec, coincidiendo con el AC 23 del GDD de Input (medido a zoom 1.0) sin contradicción.

### Edge Cases

**AC-20**. Given una tropa a ~1 world unit de un héroe, y un clic cae entre ambos pero dentro del `select_radius_world` del héroe, When `select_requested` se dispara, Then se selecciona el héroe (coincide con AC-01) — documentado como intencional; la suite de regresión nunca debe "arreglar" esto cambiando el orden de desempate.

**AC-21** [valida el contrato del Input, no este sistema]. Given una distancia de arrastre por debajo de `drag_threshold_px=5`, When el gesto completa, Then este sistema recibe un `select_requested` (clic), nunca un `box_select_requested` con rect degenerado.

**AC-24** [Integration bloqueado]. Given unidades seleccionadas y el clic resuelve sobre un kaiju/esbirro, When `select_requested` se dispara, Then el conjunto de selección no cambia y se emite una intención de objetivo-de-ataque hacia el kaiju/esbirro clicado.

**AC-25**. Given ninguna unidad seleccionada y el clic resuelve sobre un kaiju/esbirro, When `select_requested` se dispara, Then no se emite intención de ataque ni cambio de selección (el clic se ignora por completo).

**AC-26**. Given dos o más unidades seleccionables dentro del `snap_radius` del cursor de gamepad, incluyendo al menos un héroe, When corre la resolución de snap, Then se elige el héroe; si solo hay tropas en rango, la más cercana — mismo orden de prioridad que AC-01/AC-02.

**AC-27**. Given la cámara en el borde de los límites del mapa de la era activa, When un `pan_requested` la movería más allá, Then la posición se clampa exactamente en el límite y no muestra área fuera del mapa jugable, en ningún zoom.

**AC-28**. Given `pan_requested` y `zoom_requested` disparan en el mismo frame, When ambos se procesan, Then ambos efectos se aplican independientemente primero, y los clamps de zoom `[0.5,1.5]` y de límites de mapa se aplican después — ninguna operación se salta.

**AC-29**. Given estado `NONE_SELECTED`, When `move_commanded(screen_pos)` se dispara, Then no ocurre error, ninguna unidad se mueve, y no hay cambio de estado.

### Tuning Knobs (clamping)

**AC-30**. Given un valor de `click_tolerance_px` de `2` (bajo) o `15` (alto), When se carga, Then se clampa a `4` y `10` respectivamente.

**AC-31**. Given un valor de `snap_strength` de `0.1` o `0.7`, When se carga, Then se clampa a `0.25` y `0.55` respectivamente.

**AC-32**. Given un valor de `snap_radius` de `0.3` o `2.0`, When se carga, Then se clampa a `0.6` y `1.5` respectivamente.

**AC-33**. Given un valor de `virtual_cursor_speed` de `10` o `30`, When se carga, Then se clampa a `18` y `26` respectivamente.

### Clasificación de tipo de story (para el gate de evidencia)

| AC # | Tipo | Evidencia | Gate |
|---|---|---|---|
| AC-01 a AC-08, AC-05b, AC-11 a AC-19, AC-F1 a AC-F9, AC-20, AC-25 a AC-29 | Logic | Unit test automatizado (`tests/unit/selection/`) | Bloqueante |
| AC-09 (recibo de orden), AC-10, AC-18 (integración muerte), AC-24 | Integration | Integration test / playtest documentado | Bloqueante (parcialmente diferido) |
| AC-21 | Logic | Pertenece a la suite de Input, no de este sistema | Advisory |
| AC-30 a AC-33 | Config/Data | Smoke check | Advisory |

**Nota**: AC-F3/AC-F4 (inversión de zoom en la transformación pantalla→mundo) es el test de regresión de mayor valor de toda la GDD.

### Huecos/no-testeables marcados

1. **AC-09/AC-18 (mitad de integración)** bloqueados hasta las GDDs de Sistema de Tropas y Sistema de Héroes — la lógica de este sistema es testeable hoy vía listeners simulados; el cableado real de recibo de orden/evento de muerte no.
2. **AC-24 (emisión de objetivo de ataque)** bloqueado hasta la GDD de Combate/Daño — la emisión es testeable en aislamiento, pero no hay consumidor que verifique el recibo.
3. **AC-F1/AC-F2 (`unit_visual_radius_world`)**: la fórmula es testeable con un escalar simulado; los valores autorales por defecto (héroe 64px, tropa 40px) quedan sin confirmar hasta las GDDs de Tropas/Héroes.
4. **Consumo de la selección por UI/HUD**: fuera del alcance de la suite propia; cuando se diseñe UI/HUD, sus indicadores de selección necesitarán su propio AC referenciando el contrato de conjunto-de-selección de este sistema.

## Open Questions

| Pregunta | Owner | Resolución objetivo |
|---|---|---|
| Los valores autorales de `unit_visual_radius_world` (diámetro clicable por tipo de unidad) deben definirse en las GDDs de Sistema de Tropas y Sistema de Héroes; este sistema solo define la fórmula que los consume (Fórmula 1) | game-designer | Al diseñar Tropas/Héroes |
| ¿El MVP incluye grupos de control persistentes (Ctrl+1, etc.)? Se decidió comando directo estilo Warcraft 3 sin grupos para el MVP — revisitar si el playtest muestra que la gestión de selección se siente insuficiente | game-designer | Post-playtest del MVP |
| El flujo de "jugar sin gamepad conectado en PC" (heredado del GDD de Input) interactúa con el cursor virtual — si no hay gamepad, el cursor virtual nunca se muestra; confirmar que esto es suficiente | game-designer / UI-HUD | Antes de implementar input de consola |
| Las interfaces con Sistema de Tropas, Sistema de Héroes, Combate/Daño y UI/HUD son contratos propuestos — confirmar bidireccionalmente cuando cada uno tenga su GDD | game-designer | Al diseñar cada sistema dependiente |
