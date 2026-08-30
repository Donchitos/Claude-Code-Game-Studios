# Guardado/Persistencia

> **Status**: In Design
> **Author**: usuario + agentes
> **Last Updated**: 2026-08-15 — corregido el dueño del trigger de autosave de muerte de héroe: Sistema de Héroes (`DYING`, AC-H26), no Permadeath (Rule 1, Interactions, Dependencies, AC-01/AC-01b, nota de diseño de la Regla `retry_delay_ms`) — cierra `design/gdd/permadeath.md` OQ-P6 #3. Previo: 2026-08-09 — añadido contrato de persistencia con Temporizador de Preparación/Ritual (`elapsed_s`/`current_phase`); corregido Rule 2/AC-05 (el reloj corre desde el instante ACTIVE, sin ventana de Preparación previa)
> **Implements Pillar**: Sacrificio con Peso (Pilar 1); El Pasado es Poder (Pilar 2)

## Overview

El sistema de Guardado/Persistencia es la capa de infraestructura que escribe y lee el estado mutable del juego a disco: qué héroes murieron y cómo, qué reliquias se forjaron, qué era está activa, y qué progreso del panteón se ha acumulado. No contiene lógica de juego — expone una API de lectura/escritura que otros sistemas (Datos de Era/Civilización, Forja de Legado, Salón Conmemorativo/Panteón, Transición de Era) consultan para persistir sus decisiones entre sesiones. Su diseño existe en función directa del Pilar 1 (Sacrificio con Peso): si el estado de un héroe muerto pudiera revertirse recargando una partida guardada de un punto anterior a su muerte, el juego rompería su promesa central. Este sistema es, en un sentido literal, el que hace que las consecuencias sean permanentes.

## Player Fantasy

Este sistema no tiene fantasía propia — es la infraestructura silenciosa que hace posible una fantasía ajena: la de que las decisiones importan. El jugador nunca "interactúa" con el guardado; lo experimenta únicamente en su ausencia — la ausencia de un botón de "cargar partida anterior a la muerte", la ausencia de la posibilidad de deshacer un sacrificio. Esa ausencia es intencional y es, en sí misma, la manifestación mecánica del Pilar 1 (Sacrificio con Peso): un sistema de guardado que permitiera revertir una muerte de héroe no sería un bug, sería una traición al contrato emocional del juego. Su segunda responsabilidad silenciosa, ligada al Pilar 2 (El Pasado es Poder), es asegurar que el panteón de reliquias del jugador sobreviva entre sesiones — que cerrar el juego nunca signifique perder la historia acumulada.

## Detailed Design

### Core Rules

1. **Autosave obligatorio e inmediato en eventos de consecuencia**: la muerte de un héroe (disparado por Sistema de Héroes al entrar a `DYING` — no por Permadeath, ver Interactions), la forja de una reliquia (Forja de Legado), y el fin de una era (Transición de Era) disparan un autosave automático y no configurable. La escritura debe completarse antes de que el juego continúe a la siguiente pantalla/estado, para que un crash o cierre forzado inmediatamente después del evento no pueda revertirlo.
2. **Guardado manual solo en puntos de pausa segura**: el jugador puede guardar manualmente durante las fases `PREPARATION`/`IMMINENT` del Temporizador de Preparación/Ritual, o en el Salón Conmemorativo. (El temporizador de acercamiento del kaiju corre desde el instante en que la era pasa a `ACTIVE` — no existe una ventana de Preparación previa sin reloj corriendo, ver `design/gdd/temporizador-de-preparacion-ritual.md` Regla 2.) Nunca está disponible durante `CLIMAX` (Combate) ni durante el beat sostenido `DEATH_HOLD` (coincide con el edge case ya fijado en el GDD de Input, que suprime todo input durante ese beat).
3. **Un solo slot de guardado por legado**: cada partida sobrescribe siempre el mismo archivo. No existen "guardados paralelos" — coincide con el diseño de panteón acumulativo y personal.
4. **Persistencia por referencia, nunca por copia**: el archivo de guardado almacena únicamente estado mutable (qué `era_id` está activa/archivada, qué IDs de reliquia se forjaron, contadores de progreso del panteón, `elapsed_s`/`current_phase` del Temporizador de Preparación/Ritual de la era activa) — nunca copia los datos inmutables de `EraDefinition` (coincide con la regla ya fijada en Datos de Era/Civilización).
5. **Escritura atómica**: se escribe primero a un archivo temporal (`save.tmp`), y solo se reemplaza el archivo final tras confirmar que la escritura fue exitosa (rename atómico) — previene corrupción si el proceso se interrumpe a mitad de escritura.
6. **Versionado de esquema**: cada guardado almacena un campo `schema_version: int`, comparado contra una constante `CURRENT_SCHEMA_VERSION` (inicia en 1, incrementa en 1 con cada cambio de esquema que rompa compatibilidad). Si `save.schema_version < CURRENT_SCHEMA_VERSION`, se ejecuta una cadena lineal de migraciones, cada una responsable solo de `v → v+1` (nunca salta versiones). Si `save.schema_version > CURRENT_SCHEMA_VERSION` (el jugador volvió a una build más antigua), no se intenta downgrade — se bloquea con un mensaje explícito, nunca se adivina silenciosamente una migración hacia atrás.
7. **Checksum de corrupción**: al escribir, se calcula un checksum sobre el payload serializado y se almacena junto a los datos. Al cargar, se recalcula el checksum y se compara contra el almacenado. Si no coinciden, el estado transiciona a `CORRUPTED` — sin auto-reparación, sin ignorar silenciosamente el fallo.

### States and Transitions

| Estado | Descripción | Transición desde | Transición hacia |
|---|---|---|---|
| `NO_SAVE_EXISTS` | No hay archivo de guardado — partida nueva | — | `SAVING` (al primer autosave) |
| `SAVING` | Escritura atómica en progreso (breve) | `NO_SAVE_EXISTS`, `SAVE_EXISTS` | `SAVE_EXISTS` (éxito), `CORRUPTED` (fallo de escritura) |
| `SAVE_EXISTS` | Guardado válido en disco, cargable | `SAVING` | `SAVING` (siguiente autosave/guardado manual) |
| `CORRUPTED` | El archivo existe pero falla la validación/lectura | `SAVING` (fallo) | — (ver Edge Cases) |

### Interactions with Other Systems

| Sistema | Dirección | Interfaz |
|---|---|---|
| Sistema de Héroes | consumidor → escritura | Dispara autosave obligatorio inmediatamente al transicionar un héroe a `DYING` (AC-H26) — no es Permadeath quien dispara este autosave, aunque ocurre antes de que Permadeath reciba el payload o el beat `DEATH_HOLD` comience (corregido 2026-08-15). El snapshot persistido debe incluir el payload de muerte completo (`hero_id`, `hero_name`, `relic_category`, `relic_quality` ya computada, D/T/P) marcado como *muerte pendiente de sellar* — no solo `state=DYING` — para que el flujo de carga pueda coaccionar `DYING→DEAD` y forjar la reliquia si el juego crashea a mitad del beat sostenido de Permadeath (contrato con `design/gdd/permadeath.md` Regla 6/8b, `design/gdd/sistema-de-heroes.md` AC-H26/AC-H27c) |
| Forja de Legado | consumidor → escritura | Dispara autosave tras crear una nueva reliquia |
| Transición de Era | bidireccional | Dispara autosave al completar una era; lee/escribe qué `era_id` está `ACTIVE`/`ARCHIVED` |
| Datos de Era/Civilización | lectura únicamente | Lee referencias inmutables (`era_id`) para saber qué `EraDefinition` cargar; nunca escribe en `EraDefinition` |
| Salón Conmemorativo/Panteón | lectura + guardado manual | Lee el estado persistido para mostrar el panteón acumulado; es uno de los puntos de pausa segura para guardado manual |
| UI/HUD | consumidor | Puede mostrar un indicador breve de "guardando..." durante el estado `SAVING` (a definir en detalle en UI Requirements) |
| Temporizador de Preparación/Ritual | bidireccional | Persiste `elapsed_s` y `current_phase` como parte del estado guardable; en autosave o guardado manual durante `PREPARATION`/`IMMINENT` se capturan en ese frame; al recargar, el Temporizador reanuda desde `elapsed_s` y recomputa la fase vía su Fórmula F3 (no confía en el valor de fase persistido) — contrato confirmado en `design/gdd/temporizador-de-preparacion-ritual.md` |

*(Nota provisional: Forja de Legado, Transición de Era, Salón Conmemorativo/Panteón y UI/HUD aún no tienen GDD — estas interfaces son contratos propuestos. Sistema de Héroes y Permadeath ya tienen GDD [`design/gdd/sistema-de-heroes.md`, `design/gdd/permadeath.md`] — el trigger del autosave de muerte de héroe es Sistema de Héroes en `DYING`, no Permadeath, corregido 2026-08-15.)*

## Formulas

Este sistema tiene una única fórmula real — el backoff de reintento de escritura fallida. El resto de valores de timing (ej. umbral de indicador de UI) son constantes/tuning knobs sin relación computada, no fórmulas, y viven en sus secciones correspondientes.

### `retry_delay_ms` (backoff de reintento de escritura)

`retry_delay_ms(attempt) = base_delay_ms × backoff_multiplier^(attempt − 1)`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Intento | `attempt` | int | 1–max_retries | Qué número de reintento es (1 = primer reintento tras la escritura inicial fallida) |
| Retraso base | `base_delay_ms` | int (constante) | 50–200 | Tiempo de espera antes del primer reintento |
| Multiplicador de backoff | `backoff_multiplier` | float (constante) | 1.5–3.0 | Tasa de crecimiento del retraso por intento sucesivo |
| Reintentos máximos | `max_retries` | int (constante) | 2–5 | Total de intentos permitidos antes de exponer el fallo al jugador |
| **Retraso de reintento** | `retry_delay_ms` | int (salida) | ms | Tiempo de espera antes del intento dado |

**Rango de salida**: acotado por la suma de todos los retrasos de reintento — una ventana deliberadamente corta, ya que los reintentos solo ayudan con fallos transitorios (disco lleno o permisos no se resuelven esperando, así que escalar indefinidamente solo estancaría el juego sin beneficio).

**Ejemplo trabajado** (defaults: `base_delay_ms` = 100, `backoff_multiplier` = 2.0, `max_retries` = 3):

| attempt | retry_delay_ms |
|---|---|
| 1 | 100 |
| 2 | 200 |
| 3 | 400 |

Estancamiento máximo total antes de exponer el fallo ≈ **700ms**. Tras el 3er reintento fallido, el juego debe **detenerse y mostrar un estado de fallo bloqueante al jugador** en vez de continuar a la siguiente pantalla — esto aplica la Regla Núcleo 1 ("debe completarse antes de que el juego continúe") también al camino de fallo, no solo al de éxito.

**Nota de diseño (confirmada contra Permadeath, `design/gdd/permadeath.md`)**: la escritura de guardado no necesita un "timeout" propio — dado que el payload es solo un puñado de IDs y contadores por referencia (Regla Núcleo 4) más el payload de circunstancia de muerte completo (Regla Núcleo 1 actualizada), una escritura bloqueante de `FileAccess` es de duración sub-milisegundo a unos pocos ms. El autosave dispara al entrar a `DYING` (Sistema de Héroes AC-H26) — *antes* de que Permadeath reciba el payload y *antes de liberar* el beat `DEATH_HOLD` (ver Interactions) — así que la secuencia ya garantiza corrección independientemente de cuánto dure ninguno de los dos; no hace falta una fórmula de acoplamiento entre duración de guardado y duración de `DEATH_HOLD`. La duración mínima de `DEATH_HOLD` la fija Permadeath (`death_hold_min_duration_s`, MVP 2.0s) por sensación/ritmo, no por esta restricción técnica.

## Edge Cases

- **Si la escritura al archivo temporal falla** (disco lleno, permisos): tras agotar los reintentos de `retry_delay_ms`, el guardado anterior válido permanece completamente intacto y cargable (nunca se tocó). La respuesta correcta es "este evento específico no se pudo persistir, tu guardado previo está a salvo" — **no** transiciona a `CORRUPTED`.
- **Si el rename atómico en sí falla a mitad de operación** (raro, casi garantizado atómico a nivel de OS, pero no imposible en algunos filesystems): este es el único caso de escritura que amerita `CORRUPTED`, ya que puede dejar un estado ambiguo en disco.
- **Si `save.schema_version > CURRENT_SCHEMA_VERSION`** (el jugador volvió a una build más antigua tras jugar una más nueva): no se intenta downgrade. Se bloquea la carga con un mensaje explícito y no se ofrece "continuar de todos modos" — adivinar una migración hacia atrás arriesga corromper el panteón, violando el Pilar 2.
- **Si el checksum no coincide al cargar**: transiciona a `CORRUPTED` sin auto-reparación ni opción de "ignorar y continuar".
- **Si se intenta un guardado manual durante un estado no permitido** (Clímax de Combate, `DEATH_HOLD`): la UI no debe ni exponer la opción en esos estados; si la señal se dispara de todos modos (bug/edge), el sistema la ignora silenciosamente sin error — a diferencia de un autosave fallido, esto no representa pérdida de una decisión de consecuencia.
- **Si ocurre un crash o corte de energía exactamente durante `SAVING`** (antes de completar el rename): al reiniciar, se detecta cualquier `save.tmp` huérfano y se descarta sin usarlo — se carga el `save` final anterior, que sigue siendo válido gracias al patrón de escritura atómica.
- **Si dos eventos de consecuencia ocurren en rápida sucesión** (ej. la muerte de un héroe completa la era en el mismo frame): los autosaves se serializan, nunca se ejecutan en paralelo — el segundo evento se encola hasta que el primer `SAVING` complete.

## Dependencies

Este sistema no depende de ningún otro (capa Foundation).

Sistemas que dependen de este (todas duras):

| Sistema | Tipo | Interfaz |
|---|---|---|
| Sistema de Héroes | Dura | Dispara autosave obligatorio al transicionar un héroe a `DYING` (AC-H26) — el payload persistido debe incluir el contrato de muerte completo (incl. `relic_quality`) marcado como pendiente de sellar, para la coacción `DYING→DEAD` que el flujo de carga ejecuta si el juego crashea a mitad del beat de Permadeath (ver `design/gdd/permadeath.md` Regla 8b, `design/gdd/sistema-de-heroes.md` AC-H27c) |
| Forja de Legado | Dura | Dispara autosave tras crear una nueva reliquia |
| Transición de Era | Dura (bidireccional) | Dispara autosave al completar una era; lee/escribe qué `era_id` está `ACTIVE`/`ARCHIVED` |
| Datos de Era/Civilización | Dura (bidireccional) | Este sistema almacena qué `era_id` está activa/completada, referenciando sus datos inmutables sin copiarlos (relación ya documentada en `design/gdd/datos-de-era-civilizacion.md`) |
| Salón Conmemorativo/Panteón | Dura | Lee el estado persistido para mostrar el panteón acumulado; punto de pausa segura para guardado manual |
| UI/HUD | Dura | Lee el estado `SAVING` para mostrar el indicador de "guardando..." |
| Temporizador de Preparación/Ritual | Dura (bidireccional) | Este sistema almacena `elapsed_s`/`current_phase` como estado mutable de la era activa, referenciando el contrato ya documentado en `design/gdd/temporizador-de-preparacion-ritual.md` — contrato confirmado bidireccionalmente |

*(Nota provisional: Permadeath, Forja de Legado, Transición de Era, Salón Conmemorativo/Panteón y UI/HUD aún no tienen GDD — estas interfaces son contratos propuestos, salvo las relaciones con Datos de Era/Civilización y Temporizador de Preparación/Ritual, que ya están confirmadas bidireccionalmente en ambos documentos.)*

## Tuning Knobs

| Knob | Símbolo | Tipo | Default | Rango seguro | Qué se rompe en extremos |
|---|---|---|---|---|---|
| Retraso base de reintento | `base_delay_ms` | int | 100 | 50–200 | <50: no da tiempo a que se libere un bloqueo transitorio de archivo (ej. antivirus); >200: alarga innecesariamente el estancamiento total sin mejorar la tasa de éxito |
| Multiplicador de backoff | `backoff_multiplier` | float | 2.0 | 1.5–3.0 | <1.5: los reintentos quedan muy juntos, poco tiempo real para que se resuelva el bloqueo; >3.0: el estancamiento total crece demasiado rápido, empeorando la percepción de "juego congelado" |
| Reintentos máximos | `max_retries` | int | 3 | 2–5 | <2: casi no da margen a fallos transitorios reales; >5: el estancamiento total (ver Formulas) se vuelve perceptible por el jugador antes de fallar visiblemente |
| Umbral de indicador de UI de guardado | `save_indicator_display_threshold_ms` | int | 200 | 150–250 | <150: el indicador "parpadea" en escrituras normales de <16ms, generando ruido visual innecesario; >250: el jugador podría percibir el juego como colgado antes de recibir cualquier feedback de que algo está pasando |

**Interacción**: los tres primeros knobs son parámetros de la fórmula `retry_delay_ms` (ver Formulas) — cambiarlos afecta directamente el estancamiento máximo total (~700ms con los defaults) antes de que un fallo de escritura se exponga al jugador. El umbral de indicador de UI es independiente y solo controla cuándo aparece el feedback visual de "guardando...".

**Mecanismo de enforcement**: cualquier valor configurado fuera de su rango seguro se **clampa automáticamente al límite más cercano** al cargarse — el juego nunca falla ni se bloquea por una configuración de knob inválida.

## Visual/Audio Requirements

Este sistema no tiene requisitos visuales o de audio propios más allá del feedback de UI descrito abajo. Un posible SFX sutil de confirmación de guardado podría considerarse en la GDD de Audio, pero no es un requisito de este sistema.

## UI Requirements

Este sistema contribuye tres elementos a la UI, cuyo diseño visual detallado pertenece a la futura GDD de UI/HUD (deben seguir el lenguaje diegético del art bible Sección 7):

1. **Indicador de "guardando..."**: aparece durante el estado `SAVING` únicamente si la escritura excede `save_indicator_display_threshold_ms` (default 200ms) — evita parpadeos en escrituras normales sub-16ms. Discreto, no bloqueante.
2. **Diálogo de fallo de guardado bloqueante**: se muestra cuando se agotan los reintentos (AC-26/AC-35). Debe comunicar que este evento específico no se persistió pero el guardado previo está a salvo, y no debe permitir "continuar" hasta que el jugador reconozca el fallo.
3. **Mensaje de guardado incompatible/corrupto**: dos variantes textualmente distintas (AC-29) — "guardado de versión más nueva" (rollback de build) vs. "guardado dañado" (checksum fallido/`CORRUPTED`) — para que el jugador nunca confunda un caso con el otro.

**📌 UX Flag — Guardado/Persistencia**: Este sistema tiene requisitos de UI. En Pre-Producción, ejecutar `/ux-design` para crear una especificación UX de estos tres elementos (indicador de guardado + los dos diálogos de fallo) antes de escribir epics. Las stories que referencien esta UI deben citar `design/ux/[pantalla].md`, no esta GDD directamente.

## Acceptance Criteria

*(Validado por `qa-lead`. Los criterios marcados [BLOQUEADO] no son testeables hasta que exista la GDD del sistema mencionado.)*

### Core Rules

**AC-01.** Given un evento de muerte de héroe disparado en la API del sistema de Guardado (llamada simulada, sin Sistema de Héroes real), When se dispara el trigger, Then comienza un autosave automáticamente sin input del jugador, y el juego no avanza a la siguiente pantalla/estado hasta que la escritura se resuelve (`SAVE_EXISTS` o un fallo bloqueante expuesto).

**AC-01b** [antes bloqueado en GDD de Permadeath; hoy bloqueado solo en implementación — corregido 2026-08-15]: el trigger real es la transición `DYING` de Sistema de Héroes (AC-H26), no una señal de Permadeath — ese contrato ya está fijado en `design/gdd/sistema-de-heroes.md` y `design/gdd/permadeath.md`. La muerte real de un héroe disparando el autosave de punta a punta es testeable como Integration test una vez exista una era jugable implementada con Sistema de Héroes; ya no depende de diseño pendiente.

**AC-02.** Given un evento de reliquia forjada disparado en la API (llamada simulada), When se dispara el trigger, Then el autosave comienza y completa antes de que el juego proceda más allá de la confirmación de forja.

**AC-02b** [BLOQUEADO — pendiente GDD de Forja de Legado].

**AC-03.** Given un evento de era completada disparado en la API (llamada simulada), When se dispara el trigger, Then el autosave comienza y completa antes de que el juego proceda a la pantalla de la siguiente era.

**AC-03b** [BLOQUEADO — pendiente GDD de Transición de Era].

**AC-04.** Given cualquier autosave de evento de consecuencia en progreso (`SAVING`), When el juego intenta proceder a la siguiente pantalla/estado, Then la transición se retiene/bloquea hasta que `SAVING` resuelve a `SAVE_EXISTS` o se expone el camino de fallo (AC-35).

**AC-05.** Given el juego está en la fase `PREPARATION` o `IMMINENT` del Temporizador de Preparación/Ritual (el reloj de acercamiento del kaiju ya está corriendo — no existe una fase de Preparación sin temporizador activo), When el jugador dispara guardado manual, Then el guardado ejecuta normalmente `NO_SAVE_EXISTS/SAVE_EXISTS → SAVING → SAVE_EXISTS`, y el payload persistido incluye el `elapsed_s`/`current_phase` del Temporizador en ese frame.

**AC-06.** Given el juego está en el Salón Conmemorativo, When el jugador dispara guardado manual, Then el guardado ejecuta normalmente.

**AC-07** [BLOQUEADO — pendiente GDD de UI/HUD]: que la UI no presente la opción de guardado manual durante Clímax/`DEATH_HOLD` no es testeable hasta que exista la especificación de la superficie de interacción del menú de guardado.

**AC-08.** Given ya existe un archivo de guardado en la ruta única, When ocurre cualquier guardado (auto o manual), Then el archivo existente se sobrescribe en el mismo lugar — no se crea un nuevo archivo en otra ruta.

**AC-09** [BLOQUEADO — pendiente GDD de UI/HUD, advisory]: verificar que no existe una ruta de UI para iniciar un segundo slot concurrente no es testeable sin una especificación de UI.

**AC-10.** Given una escritura de guardado completa, When se inspecciona el payload serializado, Then contiene únicamente `era_id`, IDs de reliquia forjada, contadores de progreso del panteón, y `elapsed_s`/`current_phase` del Temporizador de Preparación/Ritual — ningún campo de `EraDefinition` (nombre, descripción, valores de balance, etc.) está presente en ningún lugar del payload.

**AC-11.** Given un guardado que referencia `era_id = X`, When el contenido de `EraDefinition` para `X` cambia en una actualización de contenido/datos y el guardado se recarga, Then el juego cargado refleja el contenido actualizado de `EraDefinition` (prueba de que el guardado sostiene una referencia viva, no una copia obsoleta). Requiere coordinación con fixtures de test de Datos de Era/Civilización (ya diseñado, no bloqueado).

**AC-12** [BLOQUEANTE — crítico para Pilares 1/2]. Given se dispara un guardado, When comienza la escritura, Then los datos se escriben primero a `save.tmp`, y los bytes del archivo de guardado final permanecen sin modificar durante toda la duración de esa escritura.

**AC-13** [BLOQUEANTE]. Given `save.tmp` se escribió completa y exitosamente, When se ejecuta el rename atómico, Then es la *única* operación que modifica el archivo de guardado final, y lo reemplaza completamente o no lo toca en absoluto (ningún estado parcial es observable).

**AC-14** [BLOQUEANTE]. Given el proceso se mata después de que `save.tmp` se escribió completamente pero antes de que el rename complete, When el juego reinicia, Then el archivo de guardado final previo es idéntico byte a byte a su estado previo a la escritura y carga exitosamente.

**AC-15** [BLOQUEANTE]. Given un guardado con `schema_version < CURRENT_SCHEMA_VERSION`, When se carga, Then las migraciones corren secuencialmente una versión a la vez (v→v+1, nunca saltando una versión) hasta que `schema_version == CURRENT_SCHEMA_VERSION`.

**AC-16** [BLOQUEANTE]. Given un guardado 3 versiones detrás de `CURRENT_SCHEMA_VERSION`, When se carga, Then exactamente 3 migraciones corren en orden — no 1, no 2, no fuera de orden.

**AC-17** [BLOQUEANTE]. Given un guardado con `schema_version > CURRENT_SCHEMA_VERSION`, When se intenta cargar, Then la carga se bloquea con un mensaje explícito al jugador, ninguna migración corre, y ninguna opción de "continuar de todos modos" se presenta en ningún punto del flujo.

**AC-18** [BLOQUEANTE]. Given un guardado con `schema_version == CURRENT_SCHEMA_VERSION`, When se carga, Then cero migraciones corren y el guardado carga directamente.

**AC-19** [BLOQUEANTE]. Given una escritura de guardado completa, When se inspecciona el archivo, Then un checksum calculado sobre el payload serializado está presente y almacenado junto a los datos.

**AC-20** [BLOQUEANTE]. Given un guardado cuyo checksum almacenado coincide con un checksum recalculado de su payload, When se carga, Then carga normalmente sin transición a `CORRUPTED`.

**AC-21** [BLOQUEANTE]. Given un guardado cuyo checksum almacenado NO coincide con su checksum recalculado, When se intenta cargar, Then el estado transiciona a `CORRUPTED`, ninguna escritura de auto-reparación ocurre, y ninguna opción de "ignorar y continuar" se presenta.

### States and Transitions

**AC-22.** Given estado == `NO_SAVE_EXISTS`, When se dispara el primer guardado (auto o manual), Then la secuencia observada es `NO_SAVE_EXISTS → SAVING → SAVE_EXISTS` en éxito.

**AC-23.** Given estado == `SAVE_EXISTS`, When se dispara un guardado subsecuente, Then la secuencia observada es `SAVE_EXISTS → SAVING → SAVE_EXISTS` en éxito (camino de re-guardado, mismo archivo sobrescrito según AC-08).

**AC-24.** Given estado == `SAVING`, When el paso de rename atómico falla, Then el estado transiciona `SAVING → CORRUPTED`.

**AC-25.** Given estado == `SAVING`, When el fallo ocurre en el paso de escritura del archivo temporal (no en el rename), Then el estado **no** transiciona a `CORRUPTED` — permanece/regresa al estado válido previo (`SAVE_EXISTS` o `NO_SAVE_EXISTS`), consistente con que el guardado previo permanece intacto.

### Edge Cases

**AC-26** (EC1). Given existe un guardado previo válido, When la escritura de `save.tmp` falla en cada intento de reintento (ej. disco lleno simulado) hasta agotar `max_retries`, Then se expone un fallo bloqueante al jugador, el archivo de guardado previo no cambia y sigue siendo cargable, y el estado **no** es `CORRUPTED`.

**AC-27** (EC2). Given `save.tmp` se escribió completamente, When el rename atómico en sí falla, Then el estado transiciona a `CORRUPTED`.

**AC-28** (discriminador EC1 vs EC2 — pedido explícitamente por la advertencia del propio GDD contra confundirlos). Given dos inyecciones de fallo separadas — una en el paso de escritura temporal, otra en el paso de rename — When ambas se reproducen en la misma sesión de test, Then el fallo de escritura temporal afirma `estado != CORRUPTED AND archivo_previo_sin_cambios == true`, mientras que el fallo de rename afirma `estado == CORRUPTED`. Un test que solo verifica "la operación de guardado reportó fallo" sin comprobar cuál de estos dos estados resultó no satisface este criterio.

**AC-29** (EC3). Given un guardado con `schema_version > CURRENT_SCHEMA_VERSION`, When se muestra el mensaje de bloqueo, Then su texto comunica explícitamente "este guardado es de una versión más nueva del juego" (o equivalente), distinto del mensaje genérico de `CORRUPTED` usado en AC-30 — el jugador no debe poder confundir "volviste a una build anterior" con "tu guardado está dañado".

**AC-30** (EC4). Given se detecta un desajuste de checksum al cargar, When la carga fallida completa, Then ninguna operación de escritura de ningún tipo ocurre contra el archivo de guardado durante ese intento de carga (prueba de que no hay auto-reparación o auto-reescritura silenciosa).

**AC-31** (EC5). Given el juego está en Clímax de Combate o `DEATH_HOLD`, When una señal de guardado manual se dispara directamente contra la API del sistema (sin pasar por la UI — ej. un bug o un test automatizado), Then la solicitud se descarta sin transición de estado, sin diálogo de error, y sin escritura a disco.

**AC-32** (EC6). Given el proceso se termina abruptamente mientras estado == `SAVING` (existe un `save.tmp` huérfano, el archivo final aún no reemplazado), When el juego reinicia, Then el `save.tmp` huérfano se detecta y se descarta sin usarlo, y el guardado final previo carga exitosamente con estado == `SAVE_EXISTS`.

**AC-33** (EC7). Given un autosave de muerte de héroe y un autosave de era completada se disparan ambos dentro del mismo frame, When ambos se encolan, Then ejecutan estrictamente en secuencia — la segunda escritura no comienza hasta que el primer `SAVING` resolvió completamente a `SAVE_EXISTS` o `CORRUPTED`. Ninguna escritura intercalada/paralela es observable.

### Timing de Fórmula (`retry_delay_ms`)

**AC-34.** Given tuning por defecto (`base_delay_ms=100`, `backoff_multiplier=2.0`, `max_retries=3`) y una escritura de guardado que falla en cada intento, When se miden los reintentos, Then el intento 1 ocurre ~100ms después del fallo inicial, el intento 2 ocurre ~200ms después del fallo del intento 1, y el intento 3 ocurre ~400ms después del fallo del intento 2 (± tolerancia razonable del scheduler).

**AC-35.** Given el mismo tuning por defecto, When los 3 reintentos fallan, Then el tiempo total de estancamiento desde el fallo inicial hasta que el fallo bloqueante se expone al jugador es ~700ms (100+200+400), y el estado de fallo bloqueante aparece en ese punto — ni antes, ni indefinidamente después.

**AC-36.** Given `max_retries=3` (default), When el 3er reintento falla, Then no se programa un 4to intento — el fallo se expone inmediatamente tras el fallo del 3er reintento.

### Tuning Knobs — Clamping de Rango Seguro

**AC-37.** Given `base_delay_ms` configurado por debajo de 50 (ej. 10), When el valor se carga, Then el valor efectivo usado por `retry_delay_ms` se clampa a 50.

**AC-38.** Given `base_delay_ms` configurado por encima de 200 (ej. 500), When se carga, Then el valor efectivo se clampa a 200.

**AC-39.** Given `backoff_multiplier` configurado por debajo de 1.5 (ej. 1.0), When se carga, Then el valor efectivo se clampa a 1.5.

**AC-40.** Given `backoff_multiplier` configurado por encima de 3.0 (ej. 5.0), When se carga, Then el valor efectivo se clampa a 3.0.

**AC-41.** Given `max_retries` configurado por debajo de 2 (ej. 1 o 0), When se carga, Then el valor efectivo se clampa a 2.

**AC-42.** Given `max_retries` configurado por encima de 5 (ej. 10), When se carga, Then el valor efectivo se clampa a 5.

**AC-43.** Given `save_indicator_display_threshold_ms` configurado por debajo de 150, When se carga, Then el valor efectivo se clampa a 150.

**AC-44.** Given `save_indicator_display_threshold_ms` configurado por encima de 250, When se carga, Then el valor efectivo se clampa a 250.

### Clasificación de tipo de story (para el gate de evidencia)

| AC # | Tipo | Evidencia | Gate |
|---|---|---|---|
| AC-01 a AC-06, AC-08, AC-10, AC-12 a AC-25, AC-30 a AC-42 | Logic | Unit test automatizado (`tests/unit/save-persistence/`) | Bloqueante |
| AC-11 | Integration | Integration test con Datos de Era/Civilización | Bloqueante (no bloqueado — esa GDD ya existe) |
| AC-26 a AC-29, AC-31 a AC-33 | Logic | Unit test automatizado | Bloqueante |
| AC-34 a AC-36 | Logic | Unit test automatizado | Bloqueante |
| AC-43, AC-44 | Config/Data | Smoke check | Advisory |
| AC-07, AC-09 | Integration/UI | Bloqueado, ver huecos | Advisory |
| AC-01b, AC-02b, AC-03b | Integration | Bloqueado, ver huecos | Bloqueante una vez desbloqueado |

### Huecos conocidos (a resolver cuando existan las GDDs dependientes)

1. **AC-01b/02b/03b** bloqueados hasta que existan las GDDs de Permadeath, Forja de Legado y Transición de Era — el contrato propio de este sistema (escribir-antes-de-proceder, reintento/atomicidad/checksum) es completamente testeable hoy vía triggers simulados; el cableado real de punta a punta no.
2. **AC-07** bloqueado hasta la GDD de UI/HUD — la lógica de "ignorar si se dispara de todos modos" (AC-31) no depende de esto y es testeable ahora.
3. **AC-09** bloqueado hasta la GDD de UI/HUD (y posiblemente un futuro flujo de menú principal).
4. **AC-06** solo testeable a nivel de flag de estado hoy — confianza completa requiere que la GDD del Salón Conmemorativo/Panteón confirme que entrar a esa escena efectivamente activa el flag que este sistema revisa.
5. El comportamiento visual del indicador de UI (aparece/desaparece en el umbral) está bloqueado hasta la GDD de UI/HUD — solo el clamping numérico de la constante (AC-43/44) es testeable en aislamiento ahora.

## Open Questions

| Pregunta | Owner | Resolución objetivo |
|---|---|---|
| ¿Qué algoritmo de checksum usar (CRC32, `hash()` de Godot, u otro)? Es una decisión de implementación/rendimiento, no de diseño — no necesita ser criptográficamente seguro (defiende contra corrupción/escrituras parciales, no contra manipulación) | godot-gdscript-specialist / technical-director | Al implementar (ADR) |
| La duración mínima de `DEATH_HOLD` debe elegirse por sensación/ritmo en la GDD de Permadeath, independiente de la latencia de escritura de guardado — la secuencia (autosave-antes-de-liberar) ya garantiza corrección sin importar la duración | game-designer | Al diseñar Permadeath |
| ¿Debería registrarse `CURRENT_SCHEMA_VERSION` en el registro de constantes? Aún no lo referencia ningún otro GDD; revisitar cuando exista un doc de release/patch-notes que dependa de él | game-designer | Al establecer el proceso de release |
| Las interfaces con Permadeath, Forja de Legado, Transición de Era, Salón Conmemorativo/Panteón y UI/HUD son contratos propuestos — confirmar bidireccionalmente cuando cada uno tenga su GDD | game-designer | Al diseñar cada sistema dependiente |
