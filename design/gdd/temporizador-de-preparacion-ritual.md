# Temporizador de Preparación/Ritual

> **Status**: Approved (revisado post design-review, 5 bloqueantes aplicados, aceptado sin re-review — 2026-08-09)
> **Author**: usuario + agentes
> **Last Updated**: 2026-08-09
> **Implements Pillar**: Preparación Ritual, Clímax Explosivo (Pilar 3 — sistema eje)

## Overview

El Temporizador de Preparación/Ritual es el reloj maestro que gobierna el ritmo central del juego (Pilar 3): la alternancia entre una **fase de Preparación** —pausada, de posicionamiento de tropas y decisiones rituales— y un **Clímax** explosivo cuando el kaiju de la era llega. A nivel de datos, es una máquina de estados de fase que lee su configuración de timing por era desde `EraDefinition` (Datos de Era/Civilización) y expone, en todo momento, en qué fase está el encuentro y cuánto falta para el clímax. A nivel de jugador, es un **temporizador visible** cuya cuenta atrás convierte la calma en tensión: el jugador ve al kaiju acercarse y decide, contra ese reloj, cuándo mover fuerzas, cuándo invocar un recurso limitado y —para los héroes— cuándo una muerte vale más. Sin este sistema no existiría el Pilar 3: no habría una estructura que separe la construcción pausada del enfrentamiento intenso, ni la fuente de tiempo compartida de la que otros sistemas derivan sus propias apuestas (notablemente la "estaca del kaiju" que pondera la calidad de reliquia en el Sistema de Héroes). Es puro pacing hecho sistema: no calcula combate ni daño, solo *cuándo* las cosas pasan y con cuánta presión.

## Player Fantasy

**El jugador vive bajo un reloj que no puede detener.** El kaiju siempre llega — eso es fijo, como es fija la muerte de un héroe. Lo que el temporizador le da al jugador no es la esperanza de evitar el clímax, sino la pregunta de **cómo gasta el tiempo que le queda antes de que llegue**. Cada segundo de la fase de Preparación es una moneda: ¿coloco una tropa más, invoco una reliquia ahora o la guardo, comprometo a este héroe mientras la estaca aún es baja o espero a que el reloj toque fondo? La calma nunca es ociosa — el reloj visible la carga de decisión.

Es la fantasía del **general en la víspera de la batalla**: la tensión no viene de la sorpresa (sabes que la bestia viene, y aproximadamente cuándo) sino de la administración de una cuenta atrás inexorable. El pico de dread es máximo justo antes del choque, cuando el margen para reposicionar se agota; el Clímax es la liberación de toda esa presión acumulada. Este ritmo —calma preñada de decisión → estallido breve e intenso— es el latido que el Pilar 3 promete ("El ritmo alterna entre construcción/posicionamiento pausado y enfrentamientos breves e intensos contra el kaiju"), y el temporizador es su corazón: sin él, la Preparación sería un sandbox sin urgencia y el combate un evento sin crescendo.

La honestidad de la fantasía descansa en una regla: **el reloj informa, nunca miente ni sorprende injustamente.** El jugador siempre puede leer cuánto falta y en qué fase está, porque toda la tensión de diseño (Pilar 3) es la de *decidir bajo un límite conocido*, no la de ser emboscado por un límite oculto. Un clímax que llega sin aviso legible no es tensión ritual — es un gotcha, y se rediseña. (Esta legibilidad rima con la ventana de decisión de ~30s que el Sistema de Héroes exige para que una muerte sea "bien gastada".)

## Detailed Design

### Core Rules

1. **Reloj por era, data-driven**: el temporizador lee su configuración de timing desde el `EraDefinition` de la era `ACTIVE` (Datos de Era/Civilización) — al menos `approach_duration_s` (tiempo total del acercamiento del kaiju) y `imminent_window_s` (duración de la fase final de aviso). Ningún valor de timing está hardcodeado; cada era define su propio ritmo.

2. **Tres fases, una sola cuenta atrás monótona**: `PREPARATION → IMMINENT → CLIMAX`. Un único reloj cuenta desde `approach_duration_s` hasta 0; las fases son umbrales sobre ese reloj, no relojes separados. `IMMINENT` es la ventana final (`imminent_window_s`) antes del clímax.

3. **Dueño único de `kaiju_timer_remaining_ratio`** (resuelve Héroes OQ-3): este sistema es la **fuente de verdad** del "cuán cerca del clímax estamos". Expone `kaiju_timer_remaining_ratio ∈ [0,1]` = `tiempo_restante_al_clímax / approach_duration_s`, que va de **1.0** al inicio de `PREPARATION` a **0.0** al inicio de `CLIMAX`. El Sistema de Héroes deriva su input `T = 1 − kaiju_timer_remaining_ratio` leyendo este valor en el frame de muerte; Encuentro con Kaiju lo **consume** (no lo posee).

4. **Puramente temporizado, monótono**: el clímax se dispara solo cuando el reloj llega a 0. El jugador **no** puede acelerar, pausar (fuera del menú de pausa global) ni revertir la cuenta atrás desde el gameplay — es "el reloj que no puedes detener" (Player Fantasy). No hay trigger anticipado en el MVP (ver Open Questions).

5. **Legibilidad garantizada**: la fase actual y el tiempo restante son siempre consultables y se exponen a UI/HUD. El clímax nunca llega sin que la fase `IMMINENT` lo haya anunciado de forma legible (regla de la fantasía: informar, nunca emboscar).

6. **`CLIMAX` fija el ratio en 0**: al entrar a `CLIMAX`, `kaiju_timer_remaining_ratio` se fija en 0.0 y **permanece** en 0 durante todo el combate contra el kaiju — toda muerte durante el clímax tiene estaca máxima (`T=1`). Este sistema no cronometra el interior del combate del clímax (duración de la pelea, enrage, etc.) — eso pertenece a Encuentro con Kaiju.

7. **Solo pacing, no combate**: el temporizador emite **señales de cambio de fase** (`entered_imminent`, `entered_climax`) y expone el ratio; **no** instancia al kaiju, no corre IA ni calcula daño. Los consumidores (Encuentro con Kaiju, UI, Audio) reaccionan a sus señales. Separación de responsabilidades: este sistema decide *cuándo*, no *qué pasa*.

### States and Transitions

| Estado | Descripción | Transición desde | Transición hacia |
|---|---|---|---|
| `PREPARATION` | Fase calma; reloj corriendo; ratio de 1.0 hasta `(1 − imminent_window_s/approach_duration_s)` | Era pasa a `ACTIVE` (estado inicial) | `IMMINENT` |
| `IMMINENT` | Ventana final de aviso (`imminent_window_s`); reloj corriendo hacia 0; ratio bajando a 0 | `PREPARATION` (al cruzar el umbral de tiempo) | `CLIMAX` |
| `CLIMAX` | Kaiju llegó; ratio fijado en 0; el reloj de acercamiento deja de contar | `IMMINENT` (reloj llega a 0) | — (terminal para este sistema; el fin de la era lo evalúa otro sistema) |

- Las transiciones `PREPARATION→IMMINENT→CLIMAX` son unidireccionales y disparadas solo por el paso del tiempo. No hay retroceso de fase.
- El fin del `CLIMAX` (victoria/derrota de la era) **no lo posee este sistema** — mismo hueco abierto que en Tropas y Héroes; lo evalúa Encuentro con Kaiju o Transición de Era. Este sistema solo lleva el encuentro *hasta* el clímax.

### Interactions with Other Systems

| Sistema | Dirección | Interfaz |
|---|---|---|
| Datos de Era/Civilización | Datos → este sistema | Lee `approach_duration_s` e `imminent_window_s` de la era `ACTIVE` |
| Encuentro con Kaiju | este sistema → Kaiju | Consume las señales `entered_imminent`/`entered_climax` y `kaiju_timer_remaining_ratio` para cronometrar aparición/comportamiento del kaiju. **No posee el ratio.** ✅ **Approved** — contrato confirmado (Encuentro AC-K04, consume read-only) |
| Sistema de Héroes | este sistema → Héroes | Fuente de verdad de `kaiju_timer_remaining_ratio`; el snapshot de muerte de héroe (D/T/P) lee este valor para el input `T`. **Resuelve Héroes OQ-3** |
| UI/HUD | este sistema → UI | Provee `current_phase` y `time_remaining_to_climax_s` para el temporizador visible y la escalada de aviso de `IMMINENT` *(Provisional — sin GDD)* |
| Audio | este sistema → Audio | Las señales de cambio de fase y el ratio dirigen el crescendo musical/ambiental prep→clímax *(Provisional — sin GDD)* |
| Guardado/Persistencia | bidireccional | `elapsed_s` y la fase actual son parte del estado guardable (la fase se recomputa vía F3 al cargar, nunca se confía en el valor de fase persistido — ver Edge Cases y AC-T23); en autosave (p. ej. muerte de héroe) o guardado manual durante `PREPARATION`/`IMMINENT` se capturan en ese frame y al recargar el reloj reanuda desde `elapsed_s`. Contrato confirmado en `design/gdd/guardado-persistencia.md` (Rule 2/4, AC-05/AC-10) |

> **Nota de distinción (evita conflación cross-system)**: la ventana `IMMINENT` es una **escalada global del encuentro** ("el kaiju está por golpear"), distinta de la ventana de decisión de ~30s *por héroe* del Sistema de Héroes (AC-H29), que se basa en el `time_to_death` de un héroe concreto provisto por Encuentro con Kaiju, no en este reloj global. Son señales relacionadas pero separadas.

## Formulas

Este sistema no calcula combate ni daño — sus fórmulas son puramente de pacing: convierten el tiempo transcurrido en una fase, un ratio de estaca y valores de escalada para UI/Audio.

**Convención de comparación de punto flotante (aplica a toda AC de este documento)**: salvo que se indique lo contrario, las comparaciones de valores float no enteros usan una tolerancia de ±0.0001 (p. ej. `assert_almost_eq` en GUT), nunca igualdad estricta. Varios de los ratios resultantes de F4 son fracciones periódicas no representables exactamente en punto flotante binario (p. ej. `15/45 = 0.3̄3`, `35/45 = 0.7̄7`); comparaciones contra un literal decimal truncado (`0.3333`) fallarían con una implementación correcta si se exigiera igualdad estricta.

### F1 — `time_remaining_to_climax_s`

`time_remaining_to_climax_s = max(approach_duration_s − elapsed_s, 0)`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Tiempo transcurrido | `elapsed_s` | float | [0, ∞) | Segundos desde que inició `PREPARATION` |
| Duración del acercamiento | `approach_duration_s` | float (config era) | >0 | Tiempo total del acercamiento (validado al cargar, loud-fail si ≤0) |
| **Tiempo restante** | `time_remaining_to_climax_s` | float | [0, approach_duration_s] | Valor de la cuenta atrás visible (UI) |

**Ejemplo**: `approach_duration_s=600`, `elapsed_s=30` → `time_remaining_to_climax_s = 570`.

### F2 — `kaiju_timer_remaining_ratio` (salida clave — consumida por Héroes)

`kaiju_timer_remaining_ratio = clamp(time_remaining_to_climax_s / approach_duration_s, 0.0, 1.0)`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| **Ratio de tiempo restante** | `kaiju_timer_remaining_ratio` | float | [0.0, 1.0] | 1.0 al inicio de `PREPARATION` → 0.0 al inicio de `CLIMAX`; fijado en 0 durante `CLIMAX` |

Es la **fuente de verdad** del "cuán cerca del clímax". El Sistema de Héroes deriva `T = 1 − kaiju_timer_remaining_ratio` (Héroes Fórmula H4). **Output range**: [0.0, 1.0] siempre; el `clamp` y el `max` de F1 garantizan que nunca sea negativo ni >1.

**Ejemplo**: con `time_remaining_to_climax_s=570`, `approach_duration_s=600` → `ratio = 570/600 = 0.95` → Héroes `T = 0.05`.

### F3 — Predicado de fase

```
imminent_threshold_s = approach_duration_s − imminent_window_s

phase = PREPARATION   si  elapsed_s <  imminent_threshold_s
        IMMINENT      si  imminent_threshold_s ≤ elapsed_s < approach_duration_s
        CLIMAX        si  elapsed_s ≥ approach_duration_s
```

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Ventana de aviso | `imminent_window_s` | float (config era) | 0 < x < approach_duration_s | Duración de la fase final `IMMINENT` (validado al cargar) |
| Umbral de aviso | `imminent_threshold_s` | float (derivado) | (0, approach_duration_s) | Frontera de `elapsed_s` para PREPARATION→IMMINENT |

**Convención de boundary**: inclusive-lower. En `elapsed_s == imminent_threshold_s` exacto la fase ya es `IMMINENT`; en `elapsed_s == approach_duration_s` exacto ya es `CLIMAX`. No hay frame ambiguo entre fases.

### F4 — `imminent_local_progress` (derivado — para escalada de UI/Audio)

`imminent_local_progress = clamp((elapsed_s − imminent_threshold_s) / imminent_window_s, 0.0, 1.0)`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| **Progreso local de IMMINENT** | `imminent_local_progress` | float | [0.0, 1.0] | 0.0 al entrar a `IMMINENT`, 1.0 al inicio de `CLIMAX`; monótono. Solo significativo mientras `phase == IMMINENT` |

Alimenta rampas de crescendo (audio) y escalada visual del aviso (UI) sin exponer segundos crudos.

### Valores por defecto (MVP)

Ambos son tuning knobs por era (ver Tuning Knobs), no constantes fijas:

| Knob | Default MVP | Rango seguro | Justificación |
|---|---|---|---|
| `approach_duration_s` | **600 (10 min)** | 300–1800 (5–30 min) | El loop corto del concepto es 5-15 min; 10 min permite 1-2 ciclos de recursos/posicionamiento antes del clímax, dentro de una era de 30-120 min |
| `imminent_window_s` | **45** | 30–90 (siempre < 20% de `approach_duration_s`) | Contiene con margen la ventana de decisión de ~30s por héroe (Héroes AC-H29); corto para leerse como "recta final", no una segunda calma |

**Cross-check con Héroes** (Fórmula H4, ejemplos canónicos): muerte temprana `elapsed_s=30` → `ratio=0.95` → `T=0.05` ✓ (Ejemplo 2 de Héroes); muerte climática `elapsed_s=570` (dentro de `IMMINENT`, pues `555 ≤ 570 < 600`) → `ratio=0.05` → `T=0.95` ✓ (Ejemplo 3); muerte en `CLIMAX` → `ratio=0` → `T=1` ✓ (Regla 6).

## Edge Cases

- **Si `approach_duration_s ≤ 0`** (error de datos de era): falla ruidosamente al cargar el `EraDefinition` (F1/F2 dividirían por cero) — nunca se corre el reloj con una duración inválida. Mismo patrón loud-fail que Datos de Era con `kaiju_definition` rota.
- **Si `imminent_window_s ≥ approach_duration_s` o `imminent_window_s ≤ 0`** (error de datos): falla ruidosamente al cargar — dejaría a `PREPARATION` sin duración o produciría un `imminent_threshold_s` fuera de rango. Se exige `0 < imminent_window_s < approach_duration_s`.
- **Si `elapsed_s` supera `approach_duration_s`** (ya en `CLIMAX`): `time_remaining_to_climax_s` queda clampeado a 0 por el `max(...,0)` de F1 y `kaiju_timer_remaining_ratio` en 0 por el `clamp` de F2. El reloj deja de avanzar `elapsed_s` internamente al entrar a `CLIMAX` (evita crecimiento no acotado), pero aunque avanzara, los guards ya garantizan valores válidos.
- **Si un solo paso de tiempo (delta grande, p. ej. tras un stall) cruzaría de `PREPARATION` directo a `CLIMAX` saltándose la ventana `IMMINENT`**: el sistema **igual emite `entered_imminent` y luego `entered_climax` en orden** dentro de ese paso — ningún consumidor (Audio, UI, Kaiju) puede perderse la señal de `IMMINENT` por un hipo de framerate. Las señales de fase se emiten en secuencia, nunca se omiten.
- **El reloj usa tiempo de juego, no tiempo real**: `elapsed_s` acumula el delta de **tiempo de juego** derivado del servicio Core **TimeControl** (ADR-0002, Accepted 2026-08-21) — el Temporizador consume `TimeControl.game_tick`/`time_scale`, no conteo de frames ni reloj de pared. Como `game_tick` se **congela** bajo `PAUSED` (beat `DEATH_HOLD` de Permadeath) y avanza **escalado** bajo `SLOWED` (oferta de Reliquias), el reloj del kaiju se detiene/ralentiza con esos regímenes "gratis", sin cableado directo a Permadeath/Reliquias. Esto **cierra OQ-P4/F2-W4** (antes el `game_time_paused` de Permadeath no llegaba a este sistema). El pacing sigue siendo independiente del framerate.
- **Menú de pausa global (régimen ORTOGONAL a TimeControl)**: si el jugador abre el menú de pausa global (`SceneTree.paused=true`, AC-T22), `elapsed_s` no avanza y reanuda al despausar. Ese es un régimen de motor distinto del régimen de tiempo de juego de TimeControl (que NO usa `SceneTree.paused`): la pausa de menú detiene todo el árbol; el régimen `PAUSED` de TimeControl es cooperativo y selectivo. La pausa de menú no es un "trigger anticipado" ni una vía de gameplay para detener el reloj (Regla 4).
- **Si ocurre un autosave (p. ej. muerte de héroe) durante `IMMINENT` o `CLIMAX`**: el `elapsed_s` y la fase se capturan en ese frame como parte del estado guardado; esto es coherente con el snapshot de Héroes, que lee `kaiju_timer_remaining_ratio` en el mismo frame de muerte.
- **Si se recarga una partida guardada a mitad del acercamiento**: el reloj reanuda desde el `elapsed_s` persistido, y la **fase se recomputa determinísticamente** desde `elapsed_s` vía F3 (no se confía en una fase almacenada que pudiera haber derivado) — garantiza consistencia fase↔tiempo tras la carga.
- **Si se consulta `kaiju_timer_remaining_ratio` antes de que la era esté `ACTIVE`** (reloj no iniciado): el temporizador solo corre mientras su era está `ACTIVE`; fuera de eso no expone un ratio de encuentro en curso (los consumidores no deben leerlo sin un encuentro activo).
- **Si `CLIMAX` se alcanza pero nadie evalúa el fin de la era** (victoria/derrota es de otro sistema): el reloj permanece en `CLIMAX` con ratio=0 indefinidamente — no es función de este sistema terminar la era, solo llevarla hasta el clímax (ver States and Transitions).

## Dependencies

**Dependencias hacia arriba (upstream) — lo único que este sistema necesita para funcionar:**

| Sistema | Tipo | Interfaz | Estado |
|---|---|---|---|
| Datos de Era/Civilización | Dura | Lee `approach_duration_s` e `imminent_window_s` de la era `ACTIVE` | ✅ Diseñado — Datos de Era ya lista a este sistema como consumidor de "configuración de timing por era"; contrato bidireccional confirmado |

**Dependientes hacia abajo (downstream — sistemas que dependen de este):**

| Sistema | Tipo | Interfaz | Estado |
|---|---|---|---|
| Sistema de Héroes | Dura | Lee `kaiju_timer_remaining_ratio` para su input `T` (snapshot en el frame de muerte). **Este sistema es el dueño del ratio** | ✅ Approved — Héroes OQ-3 ya resuelto (2026-08-07), atribuye correctamente el ratio a este sistema |
| Encuentro con Kaiju | Dura | Consume `kaiju_timer_remaining_ratio` y las señales `entered_imminent`/`entered_climax` para cronometrar aparición/comportamiento del kaiju | ✅ Approved — `encuentro-con-kaiju.md` (AC-K04, consume read-only) |
| Reliquias/Bendiciones | Dura (solo lectura) | Lee `current_phase` para gatear la ventana de invocación a `CLIMAX` (Reliquias Regla 7 / AC-RB24/RB25). Consume la fase, no la posee ni la re-deriva | ✅ Confirmado — reconciliación cross-GDD 2026-08-21 (cierra parte de Reliquias OQ-RB3) |
| UI/HUD | Dura | Consume `current_phase`, `time_remaining_to_climax_s` e `imminent_local_progress` para el temporizador visible y la escalada de aviso | Sin GDD (contrato propuesto) |
| Audio | Dura | Consume las señales de fase e `imminent_local_progress` para el crescendo prep→clímax | Sin GDD (contrato propuesto) |
| Guardado/Persistencia | Dura (bidireccional) | Persiste `elapsed_s` y la fase actual; al recargar, el reloj reanuda y la fase se recomputa vía F3 | ✅ Diseñado — contrato propuesto por este lado, a confirmar en el GDD de Guardado |

**Nota de consistencia bidireccional (resuelta)**: el Sistema de Héroes (Approved) originalmente tenía **OQ-3** afirmando que `kaiju_timer_remaining_ratio` lo proveía *Encuentro con Kaiju*. Este GDD reclamó la propiedad del ratio para el Temporizador (decisión de diseño: un único reloj visible, una sola fuente de verdad). **Resuelto**: Héroes OQ-3 ya fue actualizado (2026-08-07) para atribuir el ratio a este sistema; Encuentro con Kaiju queda como consumidor paralelo, no dueño.

**Nota (actualizada 2026-08-21)**: Encuentro con Kaiju (Approved), UI/HUD (Approved) y Reliquias/Bendiciones ya tienen GDD; sus contratos están confirmados. Solo **Audio** sigue sin GDD (Not Started) — su interfaz es contrato propuesto. Datos de Era/Civilización, Sistema de Héroes y Guardado/Persistencia ya existen.

## Tuning Knobs

| Knob | Símbolo | Tipo | Default | Rango seguro | Qué se rompe en extremos |
|---|---|---|---|---|---|
| Duración del acercamiento | `approach_duration_s` | float (s, config era) | 600 (10 min) | 300–1800 (5–30 min) | <300: la Preparación se siente apresurada, sin tiempo para 1-2 ciclos de recursos/posicionamiento — el Pilar 3 pierde su fase de "calma"; >1800: la Preparación se alarga sin tensión, el dread se diluye, contradice el "clímax explosivo" |
| Ventana de aviso | `imminent_window_s` | float (s, config era) | 45 | 30–90 (y siempre < 20% de `approach_duration_s`) | <30: no cabe la ventana de decisión de ~30s por héroe (Héroes AC-H29) — el aviso es demasiado corto para reaccionar; >90 (o >20% del acercamiento): `IMMINENT` se vuelve una segunda fase de calma en vez de "recta final", el aviso pierde urgencia |

**Interacción entre knobs**: `imminent_window_s` es relativa a `approach_duration_s` — la guía de diseño "< 20%" evita que la recta final canibalice la fase de calma. Cambiar `approach_duration_s` sin revisar `imminent_window_s` puede violar esa proporción.

**Enforcement** (coherente con la política loud-fail del proyecto — Héroes, Datos de Era con datos rotos):
1. **Constraints estructurales, loud-fail al cargar** (no se clampan — producirían división por cero o fases inválidas): `approach_duration_s > 0` y `0 < imminent_window_s < approach_duration_s`. Ver Edge Cases y AC.
2. **Rangos seguros de feel** (`approach_duration_s ∈ [300,1800]`, `imminent_window_s ∈ [30,90]`): fuera de rango → loud-fail en builds de desarrollo, para que un valor de era mal autorado se detecte al cargar y no produzca un pacing roto silenciosamente.
3. La proporción `imminent_window_s < 0.20 × approach_duration_s` es una **guía de diseño advisory** (no loud-fail): se recomienda pero no bloquea, porque es una preferencia de feel, no una condición de correctitud.

**Constantes consumidas** (no se duplican): ninguna del registro global — la configuración de timing es propiedad de `EraDefinition` (Datos de Era/Civilización), leída por era.

## Visual/Audio Requirements

*Contrato provisional — sin audio bible ni dirección de audio aún (mismo estatus que el audio del Sistema de Héroes); re-verificar cuando existan.*

**VA-1 — Crescendo prep→clímax (audio, el requisito principal)**
La escalada musical/ambiental es dirigida por `kaiju_timer_remaining_ratio` (continuo, durante toda `PREPARATION`) e `imminent_local_progress` (continuo, solo durante `IMMINENT`): `PREPARATION` **no** es un lecho estático — es una intensificación lenta y continua mapeada al descenso de `kaiju_timer_remaining_ratio` (1.0 → `1 − imminent_window_s/approach_duration_s`), deliberadamente sutil/sub-umbral (para no competir con la lectura táctica) pero perceptible si el jugador se detiene a escuchar; `IMMINENT` = rampa de tensión marcadamente más pronunciada (mapeada a `imminent_local_progress` 0→1 — el "cambio de marcha" evidente); `CLIMAX` = intensidad plena. Dirección de Música puede anclar un beat discreto de mitad de recorrido (p. ej. al cruzar `kaiju_timer_remaining_ratio≈0.5`) sobre esta misma señal continua como parte de su propia composición — no requiere una señal nueva de este sistema. Es el paralelo sonoro del Pilar 3 (calma **tensa** → estallido, no calma plana → estallido). El *timing* lo provee este sistema (señales de fase + ratio continuo); la composición pertenece a Dirección de Música.

**VA-2 — Cues discretos de cambio de fase (canal periférico)**
`entered_imminent` y `entered_climax` disparan cada uno un cue audible discreto, para que el jugador registre la transición aunque no esté mirando el temporizador (el sonido es el mejor canal periférico en un RTS ocupado — mismo principio que Héroes A-4). Refuerza la regla de la fantasía: informar, nunca emboscar.

**VA-3 — Visual mínimo propio**
Este sistema no posee VFX de mundo. Su representación visual es UI (ver UI Requirements). Cualquier telegrafío visual de "el kaiju se acerca" (silueta creciente en el horizonte) pertenece a la presentación de Encuentro con Kaiju, aunque puede ser *disparado* por las señales de fase de este sistema. La UI del temporizador usa la paleta apagada base (art bible 4.1); la urgencia de `IMMINENT` nunca se comunica solo por color (accesibilidad, art bible 4.5 — ver UI Requirements).

## UI Requirements

*Referencia rectora: Art Bible Sección 7 (UI 100% diegética). El diseño de pantalla concreto pertenece a UI/HUD; esta sección fija el contrato de qué debe comunicar.*

**U-1 — Temporizador visible durante todo encuentro activo**
Mientras la era está `ACTIVE`, la UI muestra en todo momento la fase actual y una representación del tiempo restante al clímax (`time_remaining_to_climax_s`). La cuenta atrás es siempre legible (regla de la fantasía).

**U-2 — Escalada de `IMMINENT` multi-canal (no solo color)**
Al entrar a `IMMINENT`, la UI escala visiblemente (dirigida por `imminent_local_progress`) para comunicar "recta final". La urgencia se señaliza por **forma/movimiento + color como refuerzo terciario**, nunca solo por color (art bible 4.5, mismo patrón multi-canal que Héroes U-1/U-2, por accesibilidad de daltonismo).

**U-3 — Las 3 fases son distinguibles de un vistazo**
`PREPARATION`, `IMMINENT` y `CLIMAX` se leen como estados visualmente distintos; la transición a `CLIMAX` es inequívoca.

**U-4 — Forma diegética, no reloj digital**
La representación sigue el estilo diegético del art bible (Sección 7) — un motivo ritual (p. ej. un recipiente que se vacía, un arco que se consume, una silueta que se acerca), no un cronómetro numérico estéril. La **forma concreta es una decisión de UX** (ver Open Questions / UX Flag).

> **📌 UX Flag**: Este sistema tiene requisitos de UI (cuenta atrás visible + escalada de `IMMINENT`). En Pre-Producción, correr `/ux-design` para la forma diegética del temporizador **antes** de escribir epics — las stories deben citar el spec de UX, no este GDD directamente.

## Acceptance Criteria

*Convención: cada AC usa formato Dado/Cuando/Entonces y una etiqueta de tipo de evidencia (`[Logic/unit]`, `[Integration]`) según la taxonomía de evidencia de testing del proyecto. Los AC marcados **(bloqueado)** dependen de un sistema sin GDD aún (Encuentro con Kaiju, UI/HUD) — hoy solo verificables mediante un mock del contrato en el límite de este sistema; deben re-verificarse contra el GDD real cuando exista. Salvo que se indique lo contrario, todos los valores numéricos de ejemplo usan los defaults MVP: `approach_duration_s=600`, `imminent_window_s=45` → `imminent_threshold_s=555`.*

### A. Reglas Core (1-7)

**AC-T01 — Carga de timing data-driven por era (Regla 1)** **[Logic/unit]**
Dado un `EraDefinition` con `approach_duration_s` e `imminent_window_s` poblados, cuando el temporizador se inicializa para la era `ACTIVE`, entonces lee ambos valores exclusivamente desde ese resource — ningún valor de timing está hardcodeado en el código del sistema (verificable por inspección: cambiar los valores del `.tres` cambia el comportamiento sin tocar código).

**AC-T02 — Un solo reloj, fases como umbrales (Regla 2)** **[Logic/unit]**
Dado el temporizador corriendo, cuando `elapsed_s` cruza el umbral que separa dos fases (p. ej. `PREPARATION→IMMINENT`), entonces `elapsed_s` es continuo a través del cruce (no se resetea a 0 ni salta) — confirma que las fases son umbrales sobre un único reloj, no relojes independientes reiniciados por fase.

**AC-T03 — `kaiju_timer_remaining_ratio` correcto y expuesto (Regla 3, valor)** **[Logic/unit]**
Dado `time_remaining_to_climax_s=570` y `approach_duration_s=600`, cuando se lee `kaiju_timer_remaining_ratio`, entonces el valor es `0.95` (dentro de tolerancia ±0.0001) y es consultable públicamente en cualquier frame mientras la era está `ACTIVE`.

**AC-T03b — Encuentro con Kaiju consume, no posee (Regla 3, contrato)** **(desbloqueado — Encuentro con Kaiju Approved)** **[Integration]**
*Contrato real (ya no mock): Encuentro con Kaiju (Approved) confirma explícitamente el consumidor read-only — su AC-K04 audita que "solo lee `entered_climax` y `kaiju_timer_remaining_ratio`, nunca escribe de vuelta", y su Dependencies declara "nunca escribe de vuelta hacia Temporizador". El GDD real **no** introdujo ninguna vía de escritura (no hay pausa de reloj por cinemática), así que la asunción del mock se sostiene — verificable sin mock contra Encuentro AC-K04.*
Dado Encuentro con Kaiju suscrito a las señales de fase, cuando el ratio cambia en este sistema, entonces solo lee el valor — ninguna llamada modifica `kaiju_timer_remaining_ratio` ni el `elapsed_s` interno de este sistema (cross-check contra Encuentro AC-K04).

**AC-T04 — Puramente temporizado: sin aceleración/pausa/reversa desde gameplay (Regla 4a)** **[Logic/unit]**
Dado el temporizador corriendo en `PREPARATION` o `IMMINENT`, cuando se invoca cualquier acción de gameplay disponible al jugador (mover tropas, invocar recursos, comandos de héroe), entonces ninguna de esas acciones altera `elapsed_s` ni la fase — solo el paso del tiempo de juego lo hace.

**AC-T04b — Monotonía de `elapsed_s` en juego activo (Regla 4b)** **[Logic/unit]**
Dado el temporizador corriendo sin pausa ni carga de partida, cuando se muestrean N lecturas sucesivas de `elapsed_s` a través de frames consecutivos, entonces cada lectura es siempre ≥ la anterior — `elapsed_s` nunca decrece durante juego activo.

**AC-T05 — Legibilidad: fase y tiempo restante siempre consultables (Regla 5a)** **[Logic/unit]**
Dado el temporizador corriendo en cualquier fase mientras la era está `ACTIVE`, cuando se consulta `current_phase` y `time_remaining_to_climax_s`, entonces ambos valores están disponibles y son correctos según F1/F3 en ese mismo frame — nunca hay un frame donde estos valores sean nulos o estén desactualizados.

**AC-T05b — Consumidor de UI/HUD recibe legibilidad en tiempo real (Regla 5b)** **(bloqueado — UI/HUD sin GDD)** **[Integration]**
*Mock Contract Assumptions: el mock de UI/HUD hace polling (o se suscribe a un signal de actualización) de `current_phase` y `time_remaining_to_climax_s` cada frame, sin caché ni retraso propio. Si el GDD real de UI/HUD introduce throttling de actualización, re-verificar el límite de legibilidad de esta AC.*
Dado un mock de UI/HUD consumiendo `current_phase`/`time_remaining_to_climax_s`, cuando la fase cambia, entonces el mock refleja el nuevo valor en el mismo frame del cambio — nunca se observa un HUD mostrando la fase anterior tras la transición.

**AC-T06 — `CLIMAX` fija el ratio en 0 y lo sostiene (Regla 6)** **[Logic/unit]**
Dado el temporizador entrando a `CLIMAX` (elapsed_s=600), cuando transcurre tiempo de juego adicional dentro del combate del clímax (p. ej. 100s más), entonces `kaiju_timer_remaining_ratio` permanece exactamente en `0.0` durante todo ese intervalo — nunca vuelve a subir ni fluctúa.

**AC-T07 — Contrato de superficie: solo pacing, sin combate (Regla 7a)** **[Logic/unit]**
Dado el temporizador instanciado en aislamiento (sin ningún sistema de combate, IA de kaiju, o cálculo de daño presente), cuando se ejecuta un ciclo completo `PREPARATION→IMMINENT→CLIMAX`, entonces el ciclo se completa sin error de dependencia faltante — la única superficie pública son las señales `entered_imminent`/`entered_climax` y los getters de fase/ratio/tiempo, sin métodos de instanciación, IA o daño.

**AC-T07b — Consumidores solo usan la superficie documentada (Regla 7b)** **(parcial — Encuentro con Kaiju Approved; UI/Audio aún sin GDD)** **[Integration]**
*Contrato real (Kaiju) + mock (UI/Audio): Encuentro con Kaiju (Approved) solo consume `entered_climax` y `kaiju_timer_remaining_ratio` vía getter/suscripción (AC-K04, Dependencies) — dentro de la superficie documentada, sin API adicional. Los mocks de UI y Audio (aún sin GDD) siguen asumiendo que solo invocan los getters documentados (`current_phase`, `time_remaining_to_climax_s`, `kaiju_timer_remaining_ratio`, `imminent_local_progress`) y se suscriben a `entered_imminent`/`entered_climax`. Re-verificar el contrato de superficie cuando UI/Audio reciban GDD.*
Dado mocks de Encuentro con Kaiju, UI y Audio conectados a este sistema, cuando se ejecuta un ciclo completo del encuentro, entonces ningún mock invoca un método fuera de la superficie pública documentada.

### B. Fórmulas (F1-F4)

**AC-T08 — F1 exacto** **[Logic/unit]**
Dado `approach_duration_s=600` y `elapsed_s=30`, cuando se calcula `time_remaining_to_climax_s`, entonces el resultado es exactamente `570`.

**AC-T09 — F2 exacto y con invariante de rango** **[Logic/unit]**
Dado `time_remaining_to_climax_s=570` y `approach_duration_s=600`, cuando se calcula `kaiju_timer_remaining_ratio`, entonces el resultado es `0.95` (dentro de tolerancia ±0.0001); y para cualquier combinación válida de `elapsed_s ≥ 0` y `approach_duration_s > 0`, el resultado siempre cae en `[0.0, 1.0]` (nunca negativo, nunca >1).

**AC-T10 — F3 exacto en rangos no-boundary** **[Logic/unit]**
Dado los defaults MVP, cuando se evalúa la fase para `elapsed_s=100`, `elapsed_s=580` y `elapsed_s=650`, entonces el resultado es `PREPARATION`, `IMMINENT` y `CLIMAX` respectivamente.

**AC-T11 — F4 exacto** **[Logic/unit]**
Dado los defaults MVP y `elapsed_s=570` (dentro de `IMMINENT`, pues `555 ≤ 570 < 600`), cuando se calcula `imminent_local_progress`, entonces el resultado es `15/45 = 1/3` (≈`0.3333`, dentro de tolerancia ±0.0001 — 1/3 es una fracción periódica, no el literal truncado `0.3333` exacto).

**AC-T11b — F4 monótono** **[Logic/unit]**
Dado los defaults MVP, cuando se calcula `imminent_local_progress` en `elapsed_s=555`, `elapsed_s=570` y `elapsed_s=590`, entonces los resultados son `0.0`, `1/3` (≈`0.3333`) y `7/9` (≈`0.7778`) respectivamente, todos dentro de tolerancia ±0.0001 — estrictamente creciente conforme `elapsed_s` avanza dentro de `IMMINENT`.

**AC-T12 — Cross-check con Héroes (3 ejemplos canónicos)** **[Integration]**
Dado los defaults MVP, cuando se evalúan los tres puntos canónicos citados en este GDD, entonces (todos los ratios/T dentro de tolerancia ±0.0001): `elapsed_s=30` → `ratio=0.95` → Héroes `T=0.05`; `elapsed_s=570` → `ratio=0.05` → Héroes `T=0.95`; entrada a `CLIMAX` → `ratio=0.0` → Héroes `T=1.0` (valores exactos, sin tolerancia necesaria). Confirma que la salida de F2 de este sistema alimenta correctamente la Fórmula H4 (ya Approved) del Sistema de Héroes sin necesidad de mock — Héroes es un sistema diseñado, no bloqueado.

### C. Boundaries de Transición de Fase (F3, convención inclusive-lower)

**AC-T13 — Boundary inferior exacto: `PREPARATION→IMMINENT`** **[Logic/unit]**
Dado los defaults MVP, cuando `elapsed_s == imminent_threshold_s` exactamente (`555`), entonces la fase ya es `IMMINENT` en ese mismo frame — no `PREPARATION`.

**AC-T14 — Boundary superior exacto: `IMMINENT→CLIMAX`** **[Logic/unit]**
Dado los defaults MVP, cuando `elapsed_s == approach_duration_s` exactamente (`600`), entonces la fase ya es `CLIMAX`, `time_remaining_to_climax_s=0` y `kaiju_timer_remaining_ratio=0.0` en ese mismo frame.

**AC-T15 — Un instante antes del boundary inferior** **[Logic/unit]**
Dado los defaults MVP, cuando `elapsed_s=554.999`, entonces la fase es aún `PREPARATION`.

**AC-T16 — Un instante antes del boundary superior** **[Logic/unit]**
Dado los defaults MVP, cuando `elapsed_s=599.999`, entonces la fase es aún `IMMINENT` y `kaiju_timer_remaining_ratio` es un valor positivo pequeño (`> 0.0`), nunca `0.0` antes del boundary exacto.

### D. Edge Cases

**AC-T17 — Loud-fail: `approach_duration_s ≤ 0`** **[Logic/unit]**
Dado un `EraDefinition` con `approach_duration_s=0` o negativo, cuando el temporizador intenta inicializarse para esa era, entonces la carga falla ruidosamente (error/assert en build de desarrollo) y el reloj nunca corre con esa duración.

**AC-T18 — Loud-fail: `imminent_window_s` fuera de `(0, approach_duration_s)`** **[Logic/unit]**
Dado un `EraDefinition` con `imminent_window_s ≥ approach_duration_s` (p. ej. igual) **o** con `imminent_window_s ≤ 0`, cuando el temporizador intenta inicializarse, entonces la carga falla ruidosamente en ambos casos — nunca se corre con un `imminent_threshold_s` fuera de rango.

**AC-T19 — Orden de señales preservado ante un salto de delta grande** **[Logic/unit]**
Dado el temporizador en `PREPARATION` cerca del final de la fase, cuando un único paso de tiempo (delta grande, p. ej. tras un stall) avanza `elapsed_s` de un valor `< imminent_threshold_s` a un valor `≥ approach_duration_s` en un solo frame, entonces el sistema emite `entered_imminent` y luego `entered_climax`, en ese orden, dentro del mismo frame — nunca se omite `entered_imminent`.

**AC-T20 — `elapsed_s` se congela al entrar a `CLIMAX`** **[Logic/unit]**
Dado el temporizador entrando a `CLIMAX` con `elapsed_s=600`, cuando transcurre tiempo de juego adicional, entonces el `elapsed_s` interno permanece en `600` (no crece sin límite) — verificable independientemente del invariante de clamp de F1/F2 (AC-T09), que ya cubre el caso de que no se congelara.

**AC-T21 — Independencia de framerate (tiempo de juego, no tiempo real)** **[Logic/unit]**
Dado dos simulaciones que acumulan el mismo total de tiempo de juego (1.0s) mediante pasos de tamaño distinto (p. ej. 60 pasos de 1/60s vs. 30 pasos de 1/30s), cuando se compara `elapsed_s`, fase y `kaiju_timer_remaining_ratio` resultantes entre ambas simulaciones, entonces los tres valores son idénticos — el pacing no depende del framerate.

**AC-T22 — Pausa global (menú, `SceneTree.paused`) congela `elapsed_s`** **[Logic/unit]**
Dado el temporizador corriendo, cuando el jugador abre el menú de pausa global y transcurre tiempo real mientras está pausado, entonces `elapsed_s` no avanza; al despausar, el reloj reanuda exactamente desde el valor que tenía al pausar. *(Régimen ortogonal al de TimeControl: el menú usa `SceneTree.paused`; la pausa/cámara-lenta de tiempo de juego llega vía `TimeControl.game_tick`/`time_scale` — ver AC-T21 y las reglas del reloj. Ambos congelan `elapsed_s`, por vías distintas.)*

**AC-T23 — Guardado/carga recomputa la fase desde `elapsed_s` vía F3 (no confía en fase almacenada)** **[Logic/unit]**
Dado un estado guardado con `elapsed_s=570` pero un campo de fase almacenado deliberadamente desincronizado (p. ej. `PREPARATION` en vez de `IMMINENT`), cuando se recarga la partida, entonces la fase efectiva tras la carga es `IMMINENT` (recomputada vía F3 desde `elapsed_s=570`), ignorando el valor de fase persistido incorrecto.

**AC-T24 — Guard de ratio antes de que la era esté `ACTIVE`** **[Logic/unit]**
Dado una era que aún no está `ACTIVE` (reloj no iniciado), cuando se consulta `kaiju_timer_remaining_ratio` o `current_phase`, entonces el sistema no retorna un valor que sugiera un encuentro en curso (p. ej. `1.0`/`PREPARATION` engañoso) — retorna un estado "no activo" explícito y documentado.

**AC-T25 — `CLIMAX` persiste indefinidamente sin evaluación externa de fin de era** **[Logic/unit]**
Dado el temporizador en `CLIMAX`, cuando transcurre un período de tiempo de juego arbitrariamente largo sin que ningún sistema externo (Encuentro con Kaiju, Transición de Era) llame a evaluar el fin del encuentro, entonces la fase permanece `CLIMAX` y el ratio permanece `0.0` indefinidamente — este sistema nunca transiciona por sí mismo fuera de `CLIMAX`.

### E. Tuning Knobs — Enforcement

*Los constraints estructurales (`approach_duration_s > 0`, `0 < imminent_window_s < approach_duration_s`) ya están cubiertos por AC-T17/AC-T18 arriba. Esta sección cubre los dos niveles adicionales de enforcement descritos en Tuning Knobs: rango seguro de feel y la proporción advisory.*

**AC-T26 — Loud-fail en dev por rango de feel, aun con constraint estructural satisfecho** **[Logic/unit]**
Dado un `EraDefinition` con `approach_duration_s=100` (estructuralmente válido, `>0`, pero fuera del rango seguro `[300,1800]`) **o** con `imminent_window_s=200` (estructuralmente válido, `0 < 200 < approach_duration_s`, pero fuera del rango seguro `[30,90]`), cuando el temporizador intenta inicializarse en un build de desarrollo, entonces la carga falla ruidosamente en ambos casos — un valor mal autorado se detecta al cargar, no en runtime silencioso.

**AC-T27 — La proporción <20% es advisory, no bloqueante (confirma que SÍ carga)** **[Logic/unit]**
Dado un `EraDefinition` con `approach_duration_s=300` e `imminent_window_s=90` (ambos individualmente dentro de sus rangos seguros, pero `90/300=30% > 20%`, violando la guía de proporción), cuando el temporizador se inicializa en un build de desarrollo, entonces la carga **se completa sin error** — confirma que la guía "<20%" es una recomendación de diseño, no una condición de correctitud que bloquee la carga (distinto de AC-T26).

### Clasificación de tipo de story (para el gate de evidencia)

| AC # | Tipo | Evidencia requerida | Nivel de gate |
|---|---|---|---|
| AC-T01, AC-T02, AC-T03, AC-T04, AC-T04b, AC-T05, AC-T06, AC-T07 | Logic | Unit test automatizado | Bloqueante |
| AC-T08 a AC-T27 (excepto AC-T12) | Logic | Unit test automatizado | Bloqueante |
| AC-T03b, AC-T05b, AC-T07b | Integration (bloqueado) | Integration test con mock de contrato; re-verificar contra GDD real | Bloqueante (hoy verificable solo vía mock) |
| AC-T12 | Integration | Integration test (Héroes ya diseñado, sin mock necesario) | Bloqueante |

### Huecos/bloqueados marcados (no diferidos silenciosamente)

1. **AC-T03b** — ✅ desbloqueado (2026-08-12): Encuentro con Kaiju Approved confirma el consumo read-only (AC-K04); verificable sin mock. **AC-T07b** parcial: lado Kaiju resuelto, sigue bloqueado en UI/Audio (sin GDD).
2. **AC-T05b** — la legibilidad en tiempo real hacia UI/HUD depende del GDD real de UI/HUD (incluyendo si introduce throttling de actualización). Re-verificar cuando exista.
3. **AC-T07b** — el contrato de "solo superficie documentada" para los tres consumidores (Kaiju, UI, Audio) es hoy un mock conjunto; cualquiera de los tres GDDs reales podría requerir una API no contemplada aquí. Re-verificar cuando existan.
4. **VA-1..3 y U-1..4 (Visual/Audio, UI Requirements)** — deliberadamente sin AC en este documento: son contratos provisionales sin GDD propietario (UI/HUD, Audio). Recomendación: sus ACs se escriben en los futuros GDDs de UI/HUD y Audio, citando este sistema como fuente de señales/ratio — no aquí, para evitar fijar un contrato de UI/Audio antes de que exista su propio diseño (ver UX Flag en este GDD).

## Open Questions

| # | Pregunta | Owner | Resolución objetivo |
|---|---|---|---|
| OQ-1 | ¿Se añade un trigger anticipado del clímax (el jugador provoca al kaiju antes)? Descartado para el MVP (puramente temporizado); revisitar si el playtest muestra que los jugadores quieren provocar el clímax temprano | game-designer | Playtest del MVP |
| OQ-2 | ~~¿Quién evalúa victoria/derrota al final del `CLIMAX`?~~ ✅ **RESUELTO 2026-08-12**: Encuentro con Kaiju (Approved) es el dueño (Regla 9/AC-K49–K53) — declara victoria al morir el kaiju y derrota al morir el último héroe. Este sistema sigue llevando el encuentro solo *hasta* el clímax | game-designer | ✅ Cerrado (Encuentro Regla 9) |
| OQ-3 | Forma diegética concreta del temporizador visible (recipiente/arco/silueta/motivo) | ux-designer | Al diseñar UI/HUD (`/ux-design`) |
| OQ-4 | ~~¿El `CLIMAX` necesita su propio timer interno (duración de pelea / enrage)?~~ ✅ **RESUELTO 2026-08-12**: sí, y vive en Encuentro con Kaiju (Approved) — la Furia (`ENRAGED`, Regla 10/F5) dispara por tiempo (`enrage_time_threshold_s`) o por desenganche de roster, acotando la escalada del clímax. La cota dura *total* se aceptó como riesgo documentado post-MVP (Encuentro OQ-12) | systems-designer / game-designer | ✅ Cerrado (Encuentro Regla 10) |
| OQ-5 | ~~Confirmar que Encuentro con Kaiju **consume** (no posee) `kaiju_timer_remaining_ratio`~~ ✅ **RESUELTO 2026-08-12**: Encuentro con Kaiju (Approved) lo consume read-only (AC-K04, Dependencies); la propiedad es de este sistema. Confirmado en AC-T03b | game-designer | ✅ Cerrado (Encuentro AC-K04) |
