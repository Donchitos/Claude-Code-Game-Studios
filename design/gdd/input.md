# Sistema de Input

> **Status**: Needs Revision (design-review 2026-08-19: NEEDS REVISION → 7 bloqueantes aplicados esta sesión — disconnect×DEATH_HOLD, dirección de zoom, feedback de lockout, invariante Pilar 1 distribuida, gate AC 22, fórmulas sin especificar, bidireccionalidad. Ver design/gdd/reviews/input-review-log.md)
> **Author**: usuario + agentes
> **Last Updated**: 2026-08-19
> **Implements Pillar**: Preparación Ritual, Clímax Explosivo (soporte); infraestructura para todos los pilares
> **Creative Director Review (CD-GDD-ALIGN)**: Omitido — Modo lean

## Overview

El Sistema de Input es la capa fundacional que traduce las acciones físicas del jugador (mouse, teclado, gamepad) en eventos de intención abstractos que el resto del juego consume — selección de unidades, movimiento de cámara, invocación de bendiciones, navegación de UI. No implementa ninguna lógica de juego por sí mismo: define y expone un conjunto de Input Actions con nombre (ej. `select_unit`, `command_move`, `invoke_blessing`, `pause_menu`) que se mapean a múltiples dispositivos de entrada simultáneamente, permitiendo que PC (mouse+teclado) y consola (gamepad) compartan la misma capa de intención sin que ningún otro sistema necesite conocer qué dispositivo generó la acción. Sin este sistema, ningún otro sistema del juego podría recibir input del jugador de forma consistente entre plataformas.

## Player Fantasy

El Sistema de Input no tiene una fantasía propia — es invisible por diseño. Su éxito se mide en que el jugador nunca piense en él: durante la Preparación, el control debe sentirse preciso y deliberado (cada clic de posicionamiento importa, según el Pilar 3); durante el Clímax, debe sentirse instantáneo y confiable, sin fricción entre la intención del jugador y la acción en pantalla. La única vez que el input "se siente" es cuando falla — y dado que el Pilar 1 (Sacrificio con Peso) exige que la muerte de un héroe sea siempre una decisión legítima del jugador, nunca un accidente técnico, este sistema tiene una responsabilidad silenciosa pero crítica en su parte del contrato: **la fidelidad de la señal cruda** — cada intención física del jugador se captura sin ambigüedad ni pérdida (zonas muertas, umbrales, ventanas de doble-clic bien afinados). La entrada del jugador debe ser tan confiable que cuando ocurra una pérdida, el jugador nunca pueda culpar al control — solo a su propia decisión.

> **Invariante Pilar 1 distribuida (no la garantiza Input solo).** La promesa completa —"un héroe jamás muere por un input mal registrado o ambiguo"— es un **invariante cross-system con dueños nombrados**, no una garantía que este documento pueda cumplir por sí mismo. Input **solo** posee la fidelidad de la señal cruda (emite `screen_pos`/`select_requested` sin decidir qué unidad). La resolución de *cuál* unidad recibe un clic o una orden fatal la posee **Control y Selección de Unidades** (desempate héroe>tropa, `select_radius`); la evaluación de letalidad y el sellado la posee **Permadeath/Combate**. Ningún documento aislado cumple el Pilar 1: se cumple si y solo si los tres respetan sus handoffs. Dos costuras concretas quedan como contratos requeridos (ver Open Questions OQ-INPUT-1): (a) la resolución clic→unidad de Control no debe convertir un clic ambiguo en una orden letal; (b) el **orden de frame** entre Input (orden de rescate de último segundo), Control (aplicarla) y Permadeath (evaluar la muerte) debe estar especificado, para que un accidente de orden-de-actualización nunca sea indistinguible de una decisión legítima del jugador.

## Detailed Design

### Core Rules

1. **Abstracción por Input Actions**: todo dispositivo físico se mapea a un conjunto fijo de acciones con nombre (`StringName`). Ningún sistema consumidor lee dispositivos crudos — solo consultan acciones abstractas. Uso de `&"action_name"` (StringName) en rutas calientes, nunca literales de string; se recomienda definirlas como `const` `StringName` en un único autoload (p. ej. `const ACTION_SELECT_UNIT := &"select_unit"`) para reducir riesgo de typo. **Excepción explícita — señales de ciclo de vida de dispositivo:** la regla "sin dispositivos crudos" prohíbe polling de HID/estado por-eje, **no** las señales de dispositivo del motor. Input **debe** conectarse a `Input.joy_connection_changed(device, connected)` de Godot para detectar conexión/desconexión de gamepad (`Input.is_action_pressed` **no** expone un evento discreto de desconexión — solo deja de reportar `true`). El identificador "gamepad activo" se rastrea por **identidad estable (GUID / `Input.get_joy_name`)**, no por índice `device`, porque el backend SDL3 de Godot 4.5+ puede reasignar índices al reconectar. *(Verificar el comportamiento exacto de reasignación de índices contra los docs de 4.6 antes de implementar — ver `docs/engine-reference/godot/`.)*
2. **Contexto de Input activo (fuente única, gating centralizado)**: existe exactamente un contexto de input activo a la vez, gestionado por una máquina de estados **dentro del propio sistema de Input**. El contexto determina qué acciones están habilitadas y cómo se enrutan. **El gating por contexto es centralizado**: los handlers `_input`/`_unhandled_input` de Input consultan `current_context` y **nunca emiten una señal de intención** para una acción no habilitada en el contexto activo — el gating no se delega a cada consumidor (un consumidor que olvide chequear su contexto no debe poder actuar). **Enforcement de `current_context` (AC 4):** dado que GDScript no tiene privacidad de campo ni en 4.6, la mutación externa directa se previene con un patrón explícito — campo privado `_current_context` accesible solo por lectura (`get`-only) y transiciones exclusivamente vía un método `request_context_transition(new) -> bool` que valida y devuelve si el cambio se aceptó. *(Este contrato cross-cutting — lo honran UI/HUD, Reliquias, Permadeath — merece un ADR; ver Open Questions.)*
3. **Detección de método de input**: el sistema rastrea el último método de input usado (mouse/teclado vs. gamepad) y expone esa señal `active_input_method`. Godot 4.6 separa el foco de mouse/touch del foco de teclado/gamepad (sistema de foco dual, confirmado contra `docs/engine-reference/godot/modules/ui.md`). **Alcance de `active_input_method` (corregido en review):** esta señal sirve para elegir *iconos de prompt* ("Presiona A" vs "Presiona Enter"), **no** para decidir la visibilidad del anillo de foco. El foco dual permite que ambos estados (mouse-hover y foco de teclado/gamepad) estén visualmente activos **simultáneamente en `Control`s distintos** — la retroalimentación de foco la maneja cada nodo vía su `focus_mode`/`has_focus()` + `mouse_entered`/`mouse_exited`, no un broadcast global de método. *(Nota para UI/HUD: verificar la API de foco de `Control` en 4.6 antes de fijar el patrón de feedback de foco — no derivarlo de `active_input_method`.)*
4. **Sin lógica de juego**: el sistema solo emite señales de intención (`unit_selected_at`, `move_commanded_to`, `blessing_invoke_requested`, etc.). No decide qué unidad se selecciona ni si un movimiento es válido — eso pertenece a los sistemas consumidores.

### States and Transitions

| Contexto | Acciones habilitadas | Se entra desde | Se sale hacia |
|---|---|---|---|
| `RTS_COMMAND` | select_unit, box_select, command_move, invoke_blessing, pan_camera, zoom_camera, open_pause | Inicio de era, cerrar menú, fin de BLESSING_SELECT | MENU_NAVIGATION (pausa/panteón), BLESSING_SELECT, DEATH_HOLD |
| `MENU_NAVIGATION` | ui_up, ui_down, ui_left, ui_right, ui_accept, ui_cancel | open_pause desde RTS_COMMAND, transición a Panteón | RTS_COMMAND (cerrar menú) |
| `BLESSING_SELECT` | ui_navigate (entre bendiciones ofrecidas), ui_accept (confirmar), ui_cancel (abortar) | invoke_blessing desde RTS_COMMAND | RTS_COMMAND (confirmar o cancelar) |
| `DEATH_HOLD` | ninguna (todo input de jugador suprimido) | Disparo de permadeath de héroe | RTS_COMMAND (cuando el beat sostenido se libera, controlado por el sistema de Permadeath, no por input) |

- Solo el sistema puede cambiar de contexto; los cambios se disparan por eventos de otros sistemas (ej. Permadeath fuerza `DEATH_HOLD`), no por el jugador directamente.
- La transición a `DEATH_HOLD` es inmediata y descarta cualquier input en cola — ninguna orden emitida justo antes de una muerte "sobrevive" al beat.

### Interactions with Other Systems

| Sistema | Dirección | Interfaz |
|---|---|---|
| Control y Selección de Unidades | Input → consumidor | Emite `select_requested(screen_pos)`, `box_select_requested(rect)`, `move_commanded(screen_pos)`; el consumidor resuelve qué unidad/posición |
| Reliquias/Bendiciones | bidireccional | Reliquias solicita entrar a `BLESSING_SELECT`; Input emite `blessing_choice_confirmed(index)` o `blessing_selection_cancelled` |
| Permadeath | Permadeath → Input | Permadeath fuerza el contexto `DEATH_HOLD` al iniciar el beat y lo libera al terminarlo; Input no controla el timing |
| UI/HUD | Input → UI | En `MENU_NAVIGATION`/`BLESSING_SELECT`, Input emite acciones `ui_*`; también expone `active_input_method` para el feedback de foco dual (4.6) |
| Cámara (parte de Control de Unidades) | Input → consumidor | Emite `pan_requested(delta)`, `zoom_requested(delta)` solo en `RTS_COMMAND` |

*(Actualización 2026-08-19: Control y Selección de Unidades, Reliquias/Bendiciones, Permadeath y UI/HUD **ya tienen GDD**. Las interfaces de esta tabla están confirmadas contra esos documentos; la bidireccionalidad se registró en cada uno — ver Dependencies. La costura clic→unidad y el orden de frame de la muerte quedan como contratos requeridos en OQ-INPUT-1.)*

## Formulas

Este sistema no tiene fórmulas de balance de juego — solo constantes de umbral de input con rangos definidos.

### 1. Zona muerta de gamepad (con remap)
`stick_dead_zone` = magnitud radial mínima para registrar input analógico.

| Variable | Símbolo | Tipo | Default | Rango | Qué se rompe en extremos |
|---|---|---|---|---|---|
| Zona muerta | `stick_dead_zone` | float | 0.20 | 0.10–0.30 | <0.10: deriva de cámara con pads gastados; >0.30: se pierde control fino cerca del centro |

Zona muerta radial/circular, no por-eje, para evitar sesgo diagonal.

**Expresión (fuente de verdad — `control-y-seleccion-de-unidades.md` Fórmula 3 consume `stick_input_dir`/`stick_input_mag` de aquí):**

```
raw_mag  = sqrt(stick_x² + stick_y²)                       # magnitud cruda ∈ [0, 1]
if raw_mag ≤ stick_dead_zone:
    stick_input_mag = 0.0                                  # dentro de zona muerta → sin input
    stick_input_dir = Vector2.ZERO
else:
    stick_input_mag = (raw_mag − stick_dead_zone) / (1 − stick_dead_zone)   # remap [dead,1] → [0,1]
    stick_input_dir = Vector2(stick_x, stick_y) / raw_mag                    # dirección unitaria cruda
```

- El remap `(raw_mag − dead) / (1 − dead)` reescala el rango útil a `[0,1]` completo, evitando un "salto" de magnitud al cruzar el umbral (sin remap, el primer input registrado saltaría de 0 a `stick_dead_zone`).
- **Inclusividad:** la comparación es `≤` (magnitud exactamente igual a `stick_dead_zone` = sin input). `stick_input_mag` resultante siempre ∈ `[0,1]`; nunca negativo (garantizado por la guarda `raw_mag > dead`).
- La dirección se toma de la magnitud cruda (antes del remap) para no distorsionar el ángulo.

### 2. Umbral de arrastre para box-select
`drag_threshold_px` = distancia mínima en píxeles (a 1080p de referencia) antes de que un clic-sostenido se resuelva como arrastre.

| Variable | Símbolo | Tipo | Default | Rango | Qué se rompe en extremos |
|---|---|---|---|---|---|
| Umbral de arrastre | `drag_threshold_px` | int | 5 | 3–8 | <3: temblor de mano causa box-selects accidentales; >8: arrastres rápidos fallan como clic |

**Expresión de escalado por resolución/DPI (obligatoria, no hand-wave):** el valor de la tabla es a **1080p de referencia**; el umbral efectivo escala con la altura del viewport:

```
drag_threshold_px_effective = drag_threshold_px × (viewport_height_px / 1080.0)
```

- Motivo: sin escalar, un mismo movimiento físico de mano produce ~2× los deltas de píxel a 4K (2160p) que a 1080p, así que el default de 5px se comportaría como ~2.5px efectivos a 4K sin compensar — cayendo en el modo de falla "<3: temblor causa box-selects accidentales" que la tabla misma marca. El escalado mantiene el perdón *físico* constante entre resoluciones.
- El clamp del rango seguro (3–8) se aplica al valor **de referencia** (el knob), no al efectivo; el efectivo es una función derivada de la resolución activa.
- Este knob también alimenta el sistema de **Accesibilidad** (ver Tuning Knobs): el temblor de mano es explícitamente su modo de falla, por lo que la accesibilidad puede necesitar un techo de referencia mayor que el rango de tuning del jugador mediano (a coordinar con el sistema de Accesibilidad, igual que `double_click_window_s`).

### 3. Ventana de doble-clic
`double_click_window_s` = segundos máximos entre dos clics para registrar doble-clic (ej. "seleccionar todas las unidades del mismo tipo").

| Variable | Símbolo | Tipo | Default | Rango | Qué se rompe en extremos |
|---|---|---|---|---|---|
| Ventana doble-clic | `double_click_window_s` | float | 0.3 | 0.2–0.5 | <0.2: físicamente difícil de acertar; >0.5: dos clics deliberados separados se fusionan por error |

Implementar con timer manual comparando `Time.get_ticks_msec()` entre eventos `InputEventMouseButton`, no detección de doble-clic a nivel de OS (inconsistente entre plataformas).

### 4. Velocidad de paneo de cámara
`camera_pan_speed` = velocidad base de traslación en **unidades-de-mundo/segundo** (no píxeles/segundo, para mantener consistencia espacial entre niveles de zoom).

| Variable | Símbolo | Tipo | Default | Rango | Qué se rompe en extremos |
|---|---|---|---|---|---|
| Velocidad de paneo | `camera_pan_speed` | float | **30** | 27–33 | world units/sec | <27: se siente lento para cruzar el viewport; >33: pierde precisión de posicionamiento fino |

**Resuelto** (ver `design/gdd/datos-de-era-civilizacion.md` Sección Formulas): `world_unit_scale` = 48px/unidad (1 unidad-mundo = 1 tile). A zoom de referencia (1.0), el viewport de 1920px = 40 unidades-mundo de ancho; con `camera_pan_speed` = 30 unidades/seg, un paneo de ancho completo toma ~1.33s (dentro del rango objetivo 1.2–1.5s, y equivalente a 75%/seg, dentro del 60–80%/seg esperado).

**Nota de aplicación** (ver `design/gdd/control-y-seleccion-de-unidades.md` Fórmula 4): `camera_pan_speed`=30 es el valor a zoom de referencia. La *aplicación* de esta velocidad a otros niveles de zoom la compensa el sistema de Control y Selección de Unidades (dueño de la cámara) mediante `effective_pan_speed_world = camera_pan_speed × zoom`, para mantener la velocidad percibida en pantalla constante. El AC 23 de este documento (medido a zoom 1.0) permanece válido sin cambios.

### 5. Paso de zoom de cámara
`zoom_step_fraction` = cambio multiplicativo del nivel de zoom por notch de scroll o botón.

| Variable | Símbolo | Tipo | Default | Rango | Qué se rompe en extremos |
|---|---|---|---|---|---|
| Paso de zoom | `zoom_step_fraction` | float | 0.10 | 0.05–0.15 | <0.05: zoom lento/sluggish; >0.15: saltos "pop" visibles que desorientan |

**Convención de dirección (fijada en review 2026-08-19 — resuelve la contradicción AC 13↔AC 24):** el escalar de zoom sigue la semántica del GDD dueño de la cámara (`control-y-seleccion-de-unidades.md` Fórmula 2): **`zoom_min` = 0.5 = acercado/táctico** (más px por unidad-mundo), **`zoom_max` = 1.5 = alejado/vista amplia** (encuadre de kaiju a escala completa). Por tanto **zoom-IN reduce el escalar hacia 0.5**, y zoom-OUT lo aumenta hacia 1.5.

**Mapeo físico:** scroll-up (rueda de mouse arriba) / gatillo-derecho o stick-derecho-arriba (gamepad) = **zoom-IN**. `invert_zoom` (tuning knob) intercambia el mapeo para el jugador que prefiere lo contrario. El escalar de dirección no cambia con `invert_zoom` — solo cambia qué input físico dispara `zoom_in` vs `zoom_out`.

**Expresiones (dos, una por dirección — no un `±` ambiguo):**

```
zoom_in :  zoom = clamp(zoom × (1 − zoom_step_fraction), zoom_min, zoom_max)   # baja hacia 0.5
zoom_out:  zoom = clamp(zoom × (1 + zoom_step_fraction), zoom_min, zoom_max)   # sube hacia 1.5
```

Multiplicativo (no aditivo) para que el cambio percibido escale con la razón, no con el delta absoluto.

> **Nota de deriva de ida-y-vuelta (no bloqueante, a vigilar):** `(1−f)` y `(1+f)` **no** son inversos exactos: un ciclo in→out multiplica el escalar por `(1−f²)` (a `f`=0.15, −2.25% por ciclo; a `f`=0.05, −0.25%). Un jugador que hace scroll adelante-y-atrás en cantidades iguales verá el zoom derivar levemente hacia `zoom_min` hasta que `clamp()` lo fije. Es benigno (el clamp lo acota) pero si el playtest muestra deriva perceptible, usar el verdadero inverso para zoom-out: `zoom = clamp(zoom / (1 − zoom_step_fraction), …)`. Cubierto por AC 13b.

**Propiedad del mapeo escalar→`Camera2D.zoom` (contrato, no lo posee Input):** este documento define el **escalar de zoom de diseño**; la traducción a la propiedad `Camera2D.zoom` (Vector2) de Godot 4.6 la posee **Control y Selección de Unidades** (dueño del nodo `Camera2D`, su Regla 5 / Fórmula 2). Ese GDD debe fijar el mapeo de forma que `zoom_min`=0.5 resulte visualmente *acercado* — un signo invertido ahí rompería silenciosamente tanto la resolución clic→unidad (su AC-F4) como la compensación de paneo `effective_pan_speed_world = camera_pan_speed × zoom`. Ver OQ-INPUT-2.

**Resuelto** (ver `design/gdd/datos-de-era-civilizacion.md` Sección Formulas): `zoom_min` = 0.5 (rango seguro 0.4–0.6, acercamiento táctico), `zoom_max` = 1.5 (rango seguro 1.4–2.0, encuadre de kaiju a escala completa con contexto de batalla). De 0.5 a 1.5 con `zoom_step_fraction` = 0.10 son ~11-12 notches de scroll.

## Edge Cases

- **Si un dispositivo de gamepad se desconecta a mitad de partida** (detectado vía `Input.joy_connection_changed`, Regla Núcleo 1): el sistema conserva el último contexto de input activo, emite `input_device_changed(keyboard_mouse)`, solicita pausar el juego y muestra un prompt de reconexión. Esto aplica tanto en consola (estándar de certificación) como en PC — incluso siendo el mouse/teclado el input primario en PC, una desconexión de gamepad a mitad de partida pausa para evitar pérdida accidental de control durante el combate.
  - **Excepción crítica — desconexión durante `DEATH_HOLD` (contrato duro con Permadeath):** si la desconexión ocurre mientras un beat `DEATH_HOLD` está activo (`HOLDING`), la solicitud de **pausa real del motor NO se dispara** — `permadeath.md` Regla 4 / AC-P07c prohíben que `SceneTree.paused` se active durante el beat (ningún `RESOLVED` puede ocurrir fuera de la vista del jugador). El sistema **difiere** la solicitud de pausa hasta que Permadeath libere el beat (2–8s), momento en el cual se emite. El prompt de reconexión (que no pausa el motor) sí puede mostrarse inmediatamente, visualmente distinguible del congelamiento del beat para que el jugador no confunda "tu control se desconectó" con "el ritual de muerte está corriendo". Ver AC 17b.
- **Al arranque, antes de cualquier evento de input físico** (`active_input_method` sin valor de input aún): el valor por defecto se determina por **plataforma detectada, no por input** — `KEYBOARD_MOUSE` en PC, `GAMEPAD` en consola. Esto evita que un jugador de PC sin gamepad conectado vea prompts o resaltado de foco estilo-gamepad en el primer frame antes de tocar nada. Es responsabilidad de Input (dueño de la señal). Ver AC 5b. *(Resuelve parcialmente la Open Question de "jugar sin gamepad en PC" en su tramo de primer arranque; el flujo completo de "nunca hay gamepad" sigue en OQ-INPUT-3.)*
- **Si el jugador cambia de método de input (mouse → gamepad) a mitad de acción**: "acción en curso" = **cualquier acción actualmente ligada a un input físico sostenido** (arrastre de box-select, paneo sostenido, zoom sostenido, navegación sostenida en `BLESSING_SELECT`) — no solo box-select. El sistema completa esa acción en curso con el dispositivo original y aplica el nuevo método solo a la siguiente acción; `active_input_method` se actualiza para que la UI refleje el cambio. **Debounce/histéresis (evita flicker):** un cambio de método requiere una **pulsación deliberada** (un `pressed` de acción o una deflexión de stick sostenida ≥ un umbral mínimo de frames), no un roce incidental — apoyar la mano en un gamepad o rozar un stick por debajo de un umbral no debe alternar el método ni la UI de foco dual. El umbral concreto es un contrato que Input posee; los consumidores (p. ej. el cursor virtual de Control) no deben reimplementar su propia histéresis.
- **Si el input llega durante `DEATH_HOLD`**: se **descarta sin encolar** (comportamiento correcto y deliberado — reproducir una orden formada *antes* de la muerte violaría la ficción; **no** se debe bufferear ni reejecutar). Ninguna orden emitida durante el beat sostenido se ejecuta al liberarse. **Pero el descarte no es silencioso a nivel de sistema:** Input expone `input_lockout_active = true` durante todo el `DEATH_HOLD` (ver Visual/Audio Requirements), para que el jugador que instintivamente mashea controles reciba una señal de "input retenido a propósito", no la ausencia de respuesta que se lee como cuelgue. El descarte de la *orden* es total; la *retroalimentación de que fue intencional* es obligatoria — coincide con el congelamiento de UI del art bible (Sección 7.3).
- **Si box-select y un clic simple ocurren en el mismo frame** (arrastre por debajo del umbral): se resuelve como clic simple; el umbral `drag_threshold_px` es el desempate único.
- **Si dos acciones mapeadas al mismo botón físico entran en conflicto** (ejemplo concreto: el clic izquierdo mapea a `select_unit` en el contexto `RTS_COMMAND` y a `ui_accept` en el contexto `MENU_NAVIGATION`): el contexto activo determina cuál acción dispara — nunca ambas simultáneamente, ya que solo un contexto está activo a la vez. Un clic izquierdo en `RTS_COMMAND` emite `select_requested`; el mismo clic en `MENU_NAVIGATION` emite `ui_accept`.
- **Si se abre el menú de pausa durante `BLESSING_SELECT`**: la selección de bendición se cancela (equivalente a `blessing_selection_cancelled`) antes de transicionar a `MENU_NAVIGATION` — no se anidan contextos.
- **Si el jugador mantiene una orden de movimiento presionada mientras se dispara `DEATH_HOLD`**: la orden se descarta; al liberarse el beat y volver a `RTS_COMMAND`, el jugador debe reemitir la orden (no se auto-reanuda).
- **Si un valor de zoom queda fuera de `[zoom_min, zoom_max]` por un cambio de configuración**: se hace clamp al rango válido en el siguiente frame de input, nunca se permite un zoom fuera de límites.
- **Si el jugador hace clic exactamente en el borde entre dos unidades**: el sistema emite la posición de pantalla cruda (`select_requested(screen_pos)`); la resolución de cuál unidad se selecciona pertenece al sistema de Control y Selección de Unidades, no al Input.

## Dependencies

**Dependencias hacia arriba (upstream — sistemas que Input necesita):**
- **Ninguna.** Input es un sistema Foundation puro. Solo depende del motor (API de Input de Godot 4.6), no de otros sistemas del juego.

**Dependientes hacia abajo (downstream — sistemas que dependen de Input):**

| Sistema | Tipo | Interfaz de datos |
|---|---|---|
| Control y Selección de Unidades | Dura | Consume `select_requested(screen_pos)`, `box_select_requested(rect)`, `move_commanded(screen_pos)`, `pan_requested(delta)`, `zoom_requested(delta)` |
| Reliquias/Bendiciones | Dura | Solicita entrar a `BLESSING_SELECT`; consume `blessing_choice_confirmed(index)`, `blessing_selection_cancelled` |
| Permadeath | Dura | Fuerza contexto `DEATH_HOLD`; Input suprime todo input mientras dure |
| UI/HUD | Dura | Consume acciones `ui_*` en contextos de menú; consume `active_input_method` para feedback de foco dual (4.6) |
| Temporizador de Preparación/Ritual | Suave | No consume input directamente, pero el cambio de fase Preparación→Clímax puede coincidir con cambios de contexto que Input gestiona |

**Nota bidireccional (actualizada 2026-08-19):** las GDDs de Control y Selección de Unidades, Reliquias/Bendiciones, Permadeath y UI/HUD **ya existen**, y cada una debe registrar "depende de: Input" y respetar los contratos de señal de la Sección C. Estado de registro tras esta revisión:
- Control y Selección de Unidades — ✅ ya lista a Input (contrato confirmado bidireccionalmente en su GDD).
- Permadeath — ✅ lista a Input en su tabla de Dependientes (libera el contexto `DEATH_HOLD`).
- UI/HUD — ✅ fila de Input **añadida** en esta revisión (consume acciones `ui_*`, `active_input_method`, `input_lockout_active`).
- Reliquias/Bendiciones — ✅ fila de Input **añadida** en esta revisión (solicita `BLESSING_SELECT`; consume `blessing_choice_confirmed`/`blessing_selection_cancelled`).
- `systems-index.md` — ✅ Dependency Map actualizado para listar Input como dependencia de UI/HUD y Reliquias/Bendiciones.

## Tuning Knobs

| Knob | Default | Rango seguro | Interacción / qué se rompe |
|---|---|---|---|
| `stick_dead_zone` | 0.20 | 0.10–0.30 | Muy alto = pérdida de control fino; muy bajo = deriva. Debe exponerse en opciones de accesibilidad (pads gastados varían) |
| `drag_threshold_px` | 5 | 3–8 | Escala con resolución/DPI. Interactúa con la precisión percibida de box-select |
| `double_click_window_s` | 0.3 | 0.2–0.5 | Debe exponerse en accesibilidad (jugadores con dificultades motoras necesitan ventanas más amplias) |
| `camera_pan_speed` | 30 (world units/sec) | 27–33 | Resuelto vía `world_unit_scale` (48px/unidad, definido en Datos de Era/Civilización). Interactúa con `zoom_step_fraction`: paneo demasiado rápido a zoom lejano marea |
| `zoom_step_fraction` | 0.10 | 0.05–0.15 | Interactúa con `zoom_min`/`zoom_max`: si el paso es grande y el rango angosto, pocos notches cubren todo el rango |
| `zoom_min` | 0.5 | 0.4–0.6 | Límite de acercamiento táctico; interactúa con `camera_pan_speed` (a más cerca, el mismo mundo/seg se siente más rápido) |
| `zoom_max` | 1.5 | 1.4–2.0 | Límite de alejamiento; permite ver el kaiju a escala completa con contexto de batalla (art bible Principio B) |
| `edge_scroll_enabled` | true (PC) / false (gamepad) | bool | El edge-scroll no aplica a gamepad; debe poder desactivarse en PC por preferencia |
| `invert_zoom` | false | bool | Preferencia de accesibilidad/comodidad estándar |

Varios de estos knobs (`stick_dead_zone`, `double_click_window_s`, `drag_threshold_px`, `invert_zoom`) alimentan directamente el sistema de Accesibilidad (Alpha) — se referencian aquí como fuente de verdad, no se duplican allá. **`drag_threshold_px` se incluye explícitamente** porque su propio modo de falla documentado es el temblor de mano ("<3: temblor de mano causa box-selects accidentales") — omitirlo del conjunto de accesibilidad sería una autocontradicción. La accesibilidad puede requerir un techo de referencia mayor que el rango de tuning del jugador mediano (3–8), igual que `double_click_window_s`; el rango de accesibilidad se coordina con ese sistema, no se limita al rango de feel estándar.

## Visual/Audio Requirements

- El Input no renderiza nada por sí mismo, pero expone `active_input_method` (mouse/teclado vs. gamepad) para que otros sistemas ajusten su feedback visual — crítico para el sistema de foco dual de Godot 4.6 (la UI diegética muestra estados de foco distintos según el método activo).
- Feedback de audio: los cambios de contexto de input no producen sonido directamente, pero el sistema debe emitir señales que el sistema de Audio pueda escuchar (ej. entrar a `MENU_NAVIGATION` puede disparar un sonido de UI). El Input provee el disparador, no el sonido.
- Cursor: el sistema debe soportar mostrar/ocultar el cursor de mouse según el contexto (visible en `RTS_COMMAND`/`MENU_NAVIGATION`, **oculto durante `DEATH_HOLD`** — requisito firme, no "potencialmente").
- **Contrato de feedback de lockout (`DEATH_HOLD`) — obligatorio (Pilar 1).** Durante `DEATH_HOLD`, Input expone `input_lockout_active = true` y **oculta el cursor** (arriba). Input **provee el disparador, no la puesta en escena**: el congelamiento de UI y la desaturación/ducking del art bible **Sección 7.3** (y Héroes A-1 / V-5→V-6) son quienes *muestran* que el momento es un ritual deliberado y no un cuelgue. La razón de que esto sea obligatorio y no cosmético: el descarte total de input en el instante de una muerte de héroe, sin ninguna confirmación de intencionalidad, se lee como "el juego se congeló" justo cuando el Pilar 1 más necesita que la pérdida se sienta legítima. La distinción "estoy bloqueado a propósito" vs "el juego se colgó" debe ser resoluble por el jugador. Ver AC 15b.

## UI Requirements

- No tiene pantallas propias, pero es la fuente de las acciones `ui_*` que la UI de menús consume, y de `active_input_method` para el feedback de foco dual.
- Debe existir una pantalla de **remapeo de controles** (opciones) que lea/escriba el InputMap — esta pantalla es responsabilidad de la GDD de UI/HUD, pero depende de que el Input exponga las acciones nombradas de forma legible.

## Acceptance Criteria

Formato GIVEN-WHEN-THEN. Clasificación de tipo de story para el gate de evidencia de test indicada por criterio.

### Regla Núcleo 1: Solo acciones abstractas, sin lectura de dispositivos crudos
1. **GIVEN** el InputMap tiene una acción `move_commanded` ligada a una tecla/botón físico, **WHEN** un sistema consumidor solicita input, **THEN** consulta `Input.is_action_pressed("move_commanded")` o la señal equivalente — nunca `Input.is_key_pressed()`/`Input.is_joy_button_pressed()` directamente. *(Chequeo de code-review/lint — grep de llamadas crudas fuera del directorio del Input System, propiedad de godot-gdscript-specialist, no QA de caja negra.)*
2. **GIVEN** el jugador rebindea una tecla en opciones, **WHEN** usa esa acción en cualquier parte del juego, **THEN** el comportamiento cambia consistentemente sin rutas de dispositivo crudo remanentes. *(Proxy conductual de caja negra para QA.)*

### Regla Núcleo 2: Contexto único activo, propiedad de la máquina de estados
3. **GIVEN** el sistema está en `RTS_COMMAND`, **WHEN** el sistema de Permadeath emite un evento de muerte, **THEN** `current_context == DEATH_HOLD` y no existe ningún otro flag/estado de contexto en `true` simultáneamente (el contexto es un **único campo enum** `_current_context`, no un conjunto de booleanos — la aserción es sobre ese único campo). *(Unit test del state machine expuesto.)*
4. **GIVEN** el sistema está en `MENU_NAVIGATION`, **WHEN** un sistema de UI intenta setear `current_context` directamente (asignación externa) en vez de llamar `request_context_transition()`, **THEN** el cambio es rechazado **por ausencia de setter** — `current_context` es `get`-only, la asignación externa falla en runtime y `_current_context` permanece en `MENU_NAVIGATION`. *(Unit test: la aserción es que el valor no cambió y que la vía válida es el método de transición.)*

### Regla Núcleo 3: Rastreo del último método de input
5. **GIVEN** el jugador venía usando mouse/teclado, **WHEN** presiona cualquier botón de gamepad (una **pulsación deliberada**, no un roce por debajo del umbral de debounce), **THEN** el sistema emite `input_method_changed(GAMEPAD)` en el mismo frame en que se registra el input.
5b. **GIVEN** el juego recién arrancó y no se ha registrado ningún evento de input físico, **WHEN** un consumidor consulta `active_input_method`, **THEN** devuelve el default por plataforma detectada — `KEYBOARD_MOUSE` en PC, `GAMEPAD` en consola — nunca un valor sin inicializar ni un default de gamepad en PC.
5c. **GIVEN** el jugador usa el mouse con una mano apoyada en un gamepad, **WHEN** el stick del gamepad se deflecta por **debajo** del umbral de debounce (roce incidental), **THEN** `active_input_method` permanece en `KEYBOARD_MOUSE` y no se emite `input_method_changed` (sin flicker de método).

### Regla Núcleo 4: Sin lógica de juego, solo señales de intención
6. **GIVEN** el jugador hace clic en la posición de pantalla de una unidad, **WHEN** el clic se registra, **THEN** el Input emite `unit_selected_at(screen_pos)` y no realiza lógica de selección propia (sin lookup de unidad, sin mutación de estado) — la señal carga solo datos de posición/intención cruda. *(Chequeo de code-review.)*

### Fórmula: stick_dead_zone = 0.20
7. **GIVEN** contexto `RTS_COMMAND` y un stick de gamepad, **WHEN** el stick se empuja a 0.19 de deflexión máxima, **THEN** no se emite señal de paneo de cámara.
8. **GIVEN** el mismo setup, **WHEN** el stick se empuja a 0.21 de deflexión máxima, **THEN** se emite una señal de paneo de cámara.

### Fórmula: drag_threshold_px = 5 (a 1080p)
9. **GIVEN** contexto `RTS_COMMAND` a resolución 1080p, **WHEN** el jugador presiona mouse-abajo y suelta dentro de 4px de la posición inicial, **THEN** el sistema emite intención de clic simple, no de box-select.
10. **GIVEN** el mismo setup, **WHEN** el jugador arrastra 6px o más antes de soltar, **THEN** el sistema emite intención de box-select, no de clic simple.

### Fórmula: double_click_window_s = 0.3
11. **GIVEN** contexto `RTS_COMMAND`, **WHEN** dos clics sobre la misma unidad ocurren a 0.29s de distancia, **THEN** se emite intención de doble-clic.
12. **GIVEN** el mismo setup, **WHEN** dos clics ocurren a 0.31s de distancia, **THEN** se emiten dos intenciones de clic simple separadas, no un doble-clic.

### Fórmula: zoom_step_fraction = 0.10 (dirección fijada: zoom-in → hacia zoom_min)
13. **GIVEN** nivel de zoom actual Z dentro de `[zoom_min, zoom_max]`, **WHEN** se registra un input de **zoom-in** (scroll-up con `invert_zoom=false`), **THEN** el nuevo nivel de zoom es `Z × (1 − 0.10)` = `Z × 0.90` (± tolerancia de float), con clamp a `zoom_min` (0.5) si el resultado baja de él — porque zoom-in **acerca** (escalar hacia 0.5), coherente con `control-y-seleccion-de-unidades.md` Fórmula 2. *(Regresión anti-inversión: si un impl hiciera `Z × 1.10` aquí, contradiría AC 24 y la semántica del GDD dueño de la cámara.)*
13a. **GIVEN** nivel de zoom actual Z dentro de `[zoom_min, zoom_max]`, **WHEN** se registra un input de **zoom-out** (scroll-down con `invert_zoom=false`), **THEN** el nuevo nivel es `Z × (1 + 0.10)` = `Z × 1.10`, con clamp a `zoom_max` (1.5) si se excede.
13b. **GIVEN** `invert_zoom=true`, **WHEN** el jugador usa scroll-up, **THEN** se aplica la expresión de **zoom-out** (el escalar de dirección no cambia; solo se intercambia qué input físico dispara cada expresión).

### Edge Case: supresión de input en DEATH_HOLD (prioridad máxima — dependencia del Pilar 1)
14. **GIVEN** contexto `RTS_COMMAND` con un input de orden-de-movimiento sostenido, **WHEN** el sistema de Permadeath dispara un evento de muerte, **THEN** el contexto transiciona a `DEATH_HOLD` inmediatamente (mismo frame) y la orden sostenida se descarta, no se encola ni ejecuta al soltar.
15. **GIVEN** contexto `DEATH_HOLD` activo, **WHEN** el jugador presiona cualquier acción (movimiento, selección, bendición), **THEN** no se emite ninguna señal de intención, y no se bufferea input para replay al terminar `DEATH_HOLD`.
15b. **GIVEN** contexto `DEATH_HOLD` activo, **WHEN** se inicia el beat, **THEN** `input_lockout_active == true` durante toda su duración y el cursor de mouse está oculto; al liberarse el beat, `input_lockout_active` vuelve a `false` y el cursor reaparece según el contexto de destino. *(Verifica el contrato de feedback de lockout — Pilar 1: el descarte de input debe ser señalizado como intencional, no silencioso.)*
16. **GIVEN** contexto `DEATH_HOLD` activo y un input presionado 100ms antes de la transición y aún sostenido, **WHEN** la transición se completa, **THEN** el input previamente en cola/en vuelo se descarta (verifica "descarta input en cola" de la Sección C).

### Edge Case: desconexión de gamepad a mitad de partida (consola Y PC)
17. **GIVEN** contexto `RTS_COMMAND` (en consola o PC), **WHEN** el gamepad activo se desconecta (evento `Input.joy_connection_changed(device, false)`), **THEN** el sistema emite una solicitud de pausa y una señal de prompt de reconexión dentro de un frame del evento de desconexión.
17b. **GIVEN** contexto `DEATH_HOLD` activo (beat `HOLDING` sostenido por Permadeath), **WHEN** el gamepad activo se desconecta, **THEN** el sistema emite la señal de prompt de reconexión, pero **NO** dispara/honra una solicitud de pausa real del motor (`SceneTree.paused` permanece `false`) — la solicitud de pausa se **difiere** hasta que Permadeath libere el beat, momento en que se emite. *(Respeta `permadeath.md` Regla 4 / AC-P07c: ningún `RESOLVED` puede ocurrir detrás de una pausa. Un impl literal de AC 17 durante `DEATH_HOLD` violaría el contrato de Permadeath.)*

### Edge Case: cambio de método de input a mitad de acción
18. **GIVEN** el jugador inicia un arrastre de box-select con mouse, **WHEN** se presiona un input de gamepad antes de soltar el botón del mouse, **THEN** el box-select se completa usando las coordenadas del mouse (dispositivo original) y el input de gamepad no se aplica a la acción en curso.

### Edge Case: pausa durante BLESSING_SELECT
19. **GIVEN** contexto `BLESSING_SELECT` activo, **WHEN** se registra un input de pausa, **THEN** la selección de bendición se cancela (se emite intención de cancelar) antes/al transicionar de contexto.

### Edge Case: conflicto de botón resuelto por contexto
20. **GIVEN** el clic izquierdo mapea a `select_unit` en `RTS_COMMAND` y a `ui_accept` en `MENU_NAVIGATION`, **WHEN** el jugador hace clic izquierdo en `RTS_COMMAND`, **THEN** se emite `select_requested` y no `ui_accept`; **WHEN** hace el mismo clic en `MENU_NAVIGATION`, **THEN** se emite `ui_accept` y no `select_requested`.

### Edge Case: clic en borde entre unidades
21. **GIVEN** contexto `RTS_COMMAND`, **WHEN** el jugador hace clic en una posición exactamente en el límite visual entre dos unidades, **THEN** el sistema emite `unit_selected_at(screen_pos)` solo con las coordenadas crudas — no resuelve ni emite cuál unidad fue seleccionada.

### Performance
22. **GIVEN** el juego corriendo a 60 FPS (presupuesto de frame 16.6ms) **en hardware objetivo**, **WHEN** se registra cualquier evento de input físico por el OS, **THEN** la señal de intención correspondiente se emite dentro del mismo frame (≤1 frame / ≤16.6ms de latencia), medido en una muestra de 60 segundos con 0 eventos caídos o retrasados por 2+ frames.
    - **Tipo: Integration/Performance (on-device), NO unit test headless.** Esta AC mide latencia real de OS/driver, que un runner headless no puede reproducir (inyectar `InputEvent` sintéticos vía `Input.parse_input_event()` mide solo el pipeline interno, no la latencia física que es el punto). Evidencia: medición instrumentada en hardware objetivo en `tests/performance/input/`, no `tests/unit/input/`. Sigue siendo **BLOQUEANTE** para sign-off de capa Foundation (dependencia del Pilar 1), pero con ruta de evidencia on-device.
    - **Mecanismo de medición (requerido, no asumido):** un harness que registre el timestamp del evento en el callback `_input`/`_unhandled_input` y el timestamp de la emisión de la señal de intención, sobre la misma muestra de 60s, contando (a) eventos con `Δframe > 1` y (b) eventos coalescidos/descartados. La captura debe considerar que múltiples eventos de OS pueden llegar entre frames (varios `mouse_motion`/poll de gamepad) — el criterio "0 caídos" exige definir qué coalescencia es aceptable (p. ej. coalescer motion es OK; descartar un `pressed` no lo es).
    - **Presupuesto de frame de Input (gap flageado):** ningún renglón de "Input" existe hoy en la tabla de presupuesto de frame-time del estudio. Requiere decisión de `technical-director` sobre cuántos de los 16.6ms puede consumir Input y dónde se rastrea. Ver OQ-INPUT-4.

### Fórmula: camera_pan_speed = 30 world units/sec (resuelto vía world_unit_scale)
23. **GIVEN** contexto `RTS_COMMAND` a zoom de referencia (1.0) y resolución 1080p (viewport = 40 unidades-mundo de ancho), **WHEN** el jugador mantiene presionado un input de paneo durante exactamente 1.33 segundos, **THEN** la cámara se ha desplazado 40 unidades-mundo (± tolerancia de float), cruzando el ancho completo del viewport.

### Fórmula: zoom_min/zoom_max = 0.5/1.5
24. **GIVEN** el nivel de zoom está en `zoom_min` (0.5), **WHEN** el jugador registra un input de zoom-in adicional, **THEN** el nivel de zoom permanece en 0.5 (clamp, no se acerca más — coherente con la convención zoom-in→hacia 0.5).
25. **GIVEN** el nivel de zoom está en `zoom_max` (1.5), **WHEN** el jugador registra un input de zoom-out adicional, **THEN** el nivel de zoom permanece en 1.5 (clamp, no se aleja más).
24b. **GIVEN** un cambio de configuración deja el valor de zoom fuera de `[zoom_min, zoom_max]` (p. ej. una config cargada con zoom = 2.0), **WHEN** se procesa el siguiente frame de input, **THEN** el valor se clampa al rango válido (1.5) en ese frame — nunca se permite un zoom fuera de límites (cubre el edge case de "valor de zoom fuera de rango por cambio de configuración" de la Sección D, distinto del clamp por input del jugador de AC 24/25).

### Clasificación de tipo de story (para el gate de evidencia)
- Reglas núcleo (AC 1-6), fórmulas y edge cases de DEATH_HOLD (AC 14-16, 15b) → tipo **Logic** → BLOQUEANTE, requieren unit tests automatizados en `tests/unit/input/`.
- **AC 5b (default de arranque por plataforma), 5c (debounce), 19 (pausa en BLESSING_SELECT), 20 (conflicto de botón por contexto), 21 (clic en borde)** → tipo **Logic** → requieren unit tests en `tests/unit/input/`. *(Clasificación añadida en review 2026-08-19 — antes sin tipo asignado, por tanto sin evidencia requerida.)*
- Desconexión de gamepad (AC 17), **AC 17b (desconexión durante DEATH_HOLD)**, cambio de método de input a mitad de acción (AC 18) → tipo **Integration** → BLOQUEANTE, requieren test de integración o playtest documentado.
- **AC 15b (feedback de lockout)** → tipo **Visual/Feel** → ADVISORY (screenshot + sign-off del lead): el *estado* `input_lockout_active`/cursor es Logic-testeable, pero que "se lea como intencional, no como cuelgue" es de feel, a validar en playtest.
- **Performance (AC 22)** → tipo **Integration/Performance (on-device)** → BLOQUEANTE para sign-off de capa Foundation → evidencia en `tests/performance/input/`, **no** unit test headless (ver la nota de AC 22).
- AC 23 (camera_pan_speed), 13/13a/13b (dirección de zoom), 24/24b/25 (zoom clamp) → tipo **Logic** → BLOQUEANTE, requieren unit tests en `tests/unit/input/` (dependen de `world_unit_scale` de Datos de Era/Civilización).

## Open Questions

| Pregunta | Owner | Resolución objetivo |
|---|---|---|
| ~~`world_unit_scale` no está definido~~ | ✅ Resuelto en `design/gdd/datos-de-era-civilizacion.md` (48px/unidad) | 2026-07-23 |
| ~~`zoom_min`/`zoom_max` sin definir~~ | ✅ Resuelto en `design/gdd/datos-de-era-civilizacion.md` (0.5 / 1.5) | 2026-07-23 |
| **OQ-INPUT-1 — Invariante Pilar 1 distribuida.** Contratos requeridos: (a) la resolución clic→unidad de Control no debe convertir un clic ambiguo en orden letal; (b) el orden de frame Input→Control→Permadeath para una orden de rescate de último segundo vs. la evaluación de muerte debe especificarse (un accidente de orden-de-update no puede ser indistinguible de una decisión legítima). | game-designer + technical-director (cross-GDD: Input / Control / Permadeath) | Antes de `/create-architecture` — candidato a ADR |
| **OQ-INPUT-2 — Mapeo escalar→`Camera2D.zoom`.** El GDD dueño de la cámara (Control y Selección de Unidades) debe fijar el mapeo de forma que `zoom_min`=0.5 sea visualmente *acercado*, sin invertir el signo (rompería su AC-F4 y la compensación de paneo). Verificar la convención de `Camera2D.zoom` contra docs de 4.6. | godot-specialist + Control y Selección de Unidades | Al fijar el contrato de cámara, antes de implementar |
| **OQ-INPUT-3 — Flujo "jugar sin gamepad conectado" en PC.** El default de primer arranque ya está resuelto (AC 5b: `KEYBOARD_MOUSE` en PC). Falta el flujo completo cuando *nunca* hay gamepad (el cursor virtual nunca aparece — confirmar que basta). | GDD de UI/HUD + este sistema | Antes de implementar el input de consola |
| **OQ-INPUT-4 — Presupuesto de frame-time de Input.** No hay renglón "Input" en la tabla de presupuesto del estudio; decidir cuántos de los 16.6ms puede consumir y dónde se rastrea la latencia (gate AC 22). | technical-director | Antes de sign-off de capa Foundation |
| **OQ-INPUT-5 — ADR de enforcement de `current_context`.** El patrón `get`-only + `request_context_transition()` es un contrato cross-cutting (UI/HUD, Reliquias, Permadeath); documentarlo en un ADR. | godot-gdscript-specialist | Antes de `/dev-story` del sistema de Input |
