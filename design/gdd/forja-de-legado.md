# Forja de Legado

> **Status**: Approved (2026-08-17) — design-review con 5 agentes: NEEDS REVISION → 2 bloqueantes + 8 recomendados aplicados → aceptado. Ver `design/gdd/reviews/forja-de-legado-review-log.md`
> **Author**: usuario + agentes
> **Last Updated**: 2026-08-17
> **Implements Pillar**: El Pasado es Poder (Pilar 2 — **gozne de datos**); Sacrificio con Peso (Pilar 1)

> **⚠️ Riesgo de programa (top-line, registrado en design-review 2026-08-17):** Forja es el *gozne de datos* del Pilar 2, pero **no entrega payoff jugable por sí sola** — su contribución al Pilar 2 depende al 100% de que se construyan los sistemas downstream sin GDD aún (Reliquias/Bendiciones #12 para el poder en combate, Salón Conmemorativo/Panteón #14 para la exhibición). Hasta que #12/#14 existan, la cadena del Pilar 2 termina en una estructura de datos que ningún jugador percibe. Forja es honesta sobre ser "fontanería" (ver Player Fantasy) — este aviso solo hace explícita esa dependencia como riesgo, no como defecto.

## Overview

Forja de Legado es el sistema que **cierra la cadena central del juego**: recibe de Permadeath el veredicto final de una muerte de héroe (`hero_id`, `hero_name`, `relic_category`, `relic_quality`) y lo transforma en una **Reliquia** — un objeto de datos permanente, con el nombre del héroe caído, que la civilización hereda. Es la mitad ejecutora del Pilar 2 ("El Pasado es Poder"): donde Permadeath sella *que* la muerte fue definitiva, Forja de Legado hace literal la promesa de que esa muerte *produce algo* — nunca nada. A nivel de datos es una capa delgada de transformación y persistencia: consume el tier ya resuelto por Héroes (Delgada/Sólida/Legendaria, vía `relic_quality`) sin recalcularlo, construye la estructura de la Reliquia (identidad, categoría, tier, y la procedencia narrativa de cómo murió el héroe), dispara el autosave obligatorio (Guardado/Persistencia) para que la reliquia sobreviva a un cierre inmediato, y la deposita en el panteón acumulado del jugador. **No** decide qué hace la reliquia en combate (eso es Reliquias/Bendiciones), ni cómo se muestra el panteón (eso es Salón Conmemorativo/Panteón) — su responsabilidad es *nacer la reliquia y volverla permanente*, no *usarla* ni *exhibirla*. A nivel de jugador, es el momento —presenciado justo después del beat de muerte— en que la tragedia se convierte en un objeto sagrado con nombre propio: la espada que otro héroe empuñará generaciones después llevará el nombre del que la forjó con su caída. Sin este sistema, Permadeath tendría un veredicto sin destino y el panteón no tendría de dónde nacer: Forja de Legado es el gozne que convierte el peso del **Pilar 1** en el poder del **Pilar 2**.

## Player Fantasy

*(Encuadre validado por `creative-director` en el design-review 2026-08-17: la fantasía de "testigo, no forjador" se sostiene y es coherente con el pilar; la garantía anti-nihilismo NO se considera que socave las stakes — estas viven en el *tier/calidad* de la reliquia y en el *héroe nombrado*, no en existencia-vs-nada, lo cual está lockeado a nivel de concepto ["la derrota nunca es game-over"]. Ver el Riesgo de programa top-line arriba: el payoff jugable de esta fantasía depende de #12/#14.)*

**El jugador es quien ve su tragedia volverse permanente y suya.** Justo después del beat de muerte —cuando la silueta del héroe se agrietó en fragmentos de vitral y se resolvió en un ícono dorado (el momento que Héroes/Permadeath escenifican)— Forja de Legado es lo que hace que ese ícono **deje de ser una imagen y se vuelva un objeto real que el jugador posee**: una Reliquia con el nombre del héroe caído, que a partir de ahora existe en su panteón y que ninguna derrota futura, ningún cierre del juego, puede borrar. La fantasía no es "yo forjo" como una acción que el jugador ejecuta con un botón —no hay botón, igual que en Permadeath no hay "deshacer"— sino "yo *veo nacer* algo que llevará el nombre de quien perdí, y sé que es mío para siempre". Es el instante exacto en que la palabra del concepto se cumple: *"cada reliquia legendaria tiene el nombre de un héroe que tú viste morir"*. El dolor del Pilar 1 (lo perdí) se convierte, ante sus ojos, en el poder del Pilar 2 (lo tengo, ahora como arma para el futuro) — y esa conversión es la única fuente de brillo dorado en un mundo por lo demás apagado (art bible Principio A: "El Legado es Luz").

Debajo del momento presenciado hay una capa que el jugador nunca ve directamente pero de la que depende toda la honestidad de la fantasía: la transformación del veredicto en datos, la escritura a disco que vuelve la reliquia irreversible, el depósito en el panteón. Esa capa no tiene emoción propia —es fontanería— pero es la que garantiza que la promesa sea verdadera: si una reliquia pudiera perderse por un crash mal manejado, o si una muerte pudiera no producir nada, la fantasía de "el pasado es poder" sería una mentira. Forja de Legado existe para que **nunca lo sea**: toda muerte de héroe produce exactamente una reliquia, siempre, y esa reliquia sobrevive a todo lo que venga después.

**Test de diseño (este sistema debe hacerlo cumplir):** si alguna muerte de héroe llegara a producir *cero* reliquias —por un tier degenerado, un payload incompleto, o un fallo de guardado silencioso— el diseño está roto. La válvula anti-nihilismo de Héroes (piso `relic_quality`=0.10) solo tiene sentido si Forja la honra sin excepción: una reliquia Delgada y triste sigue siendo una reliquia con nombre.

## Detailed Design

### Core Rules

1. **Único punto de creación de Reliquia.** Forja de Legado es el único sistema que construye una Reliquia. Recibe de Permadeath, en la transición a `RESOLVED`, el veredicto final (`hero_id`, `hero_name`, `relic_category`, `relic_quality`) — **exactamente una vez por héroe** (garantizado por Permadeath AC-P16, hand-off idempotente). Cada invocación produce **exactamente una** Reliquia. Forja nunca crea reliquias por ninguna otra vía ni a partir de la muerte de una tropa (solo héroes generan legado, Pilar 1).

2. **Mapeo `relic_quality → tier` (consume los cortes de Héroes, no los recalcula).** Forja deriva el tier discreto de la reliquia desde el `relic_quality` recibido, usando los mismos cortes ya fijados por Héroes y consumidos por UI: **Delgada `[0.10, 0.35)`, Sólida `[0.35, 0.70)`, Legendaria `[0.70, 1.00]`** (límites inferiores inclusivos, coherente con Héroes AC-H19/H20). Forja **nunca recomputa** `relic_quality` (eso lo posee Héroes vía H4) — solo lo mapea a una banda. Guarda **ambos**: el `relic_quality` float exacto (para consumidores futuros y desempates) y el `tier` discreto (para consumidores que solo necesitan la banda).

3. **Estructura de la Reliquia (`RelicRecord`).** La Reliquia forjada es un registro con estos campos:
   - `relic_id` — identificador estable y único, asignado por Forja (Regla 4)
   - `source_hero_id`, `source_hero_name` — identidad del héroe caído (transportados)
   - `relic_category` — `offensive` / `defensive` / `rally` (transportada, nunca reasignada)
   - `relic_quality` — float `[0.10, 1.00]` (transportado exacto)
   - `tier` — `Delgada` / `Sólida` / `Legendaria` (derivado, Regla 2)
   - `origin_era_id` — de qué era/civilización provino (Regla 6)
   - `forge_index` — orden de forja dentro del legado (contador monótono, Regla 4)
   - `epitaph` — descriptor de procedencia derivado de `relic_category × tier` (p. ej. plantilla "Guardián caído — reliquia sólida"); es *narrativa de procedencia*, no efecto mecánico

   **Modelo de "historia" de la reliquia (aclaración de diseño, design-review 2026-08-17).** El concepto promete que cada reliquia "refleja cómo murió" el héroe. En el schema actual, la **identidad narrativa única** de cada reliquia la portan `source_hero_name` + `origin_era_id` + `relic_category` (los tres, únicos/estables por héroe caído): *quién* cayó, *en qué era*, y *qué tipo de legado* dejó (la categoría **es** la codificación de "cómo murió" — fija por héroe, Héroes AC-H06). El `epitaph` es, **por diseño, una etiqueta de procedencia terse** (1 de 9 plantillas `categoría×tier`), NO una narrativa por-muerte: dos reliquias `offensive×Legendaria` comparten el mismo texto de `epitaph` pero **no** la misma identidad (distinto `source_hero_name`/`origin_era_id`). Forja no incluye un token de contexto-de-muerte (D/T/P) en la `RelicRecord` — esa evidencia se congela y consume aguas arriba (Héroes/Permadeath). Si el Panteón #14 llegara a necesitar variación de texto por-muerte más fina que `categoría×tier`, es una ampliación de schema a coordinar cuando #14 se diseñe (ver OQ-FL3), no una deuda oculta de este GDD.

4. **`relic_id` y `forge_index`: estables, únicos, nunca reutilizados.** Forja mantiene un contador de forja **monótono persistido** en el guardado; `forge_index` es su valor en el momento de forjar (0, 1, 2, … a lo largo de todo el legado, nunca reiniciado entre eras). `relic_id` se deriva de forma determinista y única a partir de ese contador (nunca del `get_instance_id()` de Godot — mismo criterio anti-reciclaje que Kaiju `entity_id`: debe ser reproducible y estable a través de guardados/cargas). Este `relic_id` es el mismo que Guardado persiste ("qué IDs de reliquia se forjaron", Guardado Regla 4) y el que `EraDefinition.legacy_props` referencia (Datos de Era Regla 4) — es la **fuente de verdad canónica** del ID de una reliquia.

   **Tipo y alcance de unicidad de `relic_id` (fijado en design-review 2026-08-17; el esquema de *encoding* sigue en OQ-FL5).** `relic_id` es de tipo **`String`** (no `int`), **único a través de todo el legado** (global al save, no solo por era), y estable a través de guardados/cargas. El GDD fija estas tres propiedades del contrato (tipo, alcance global, estabilidad); el *formato exacto* de derivación desde `forge_index` (¿`"relic_%d" % forge_index`? ¿`"{origin_era_id}:{forge_index}"`? ¿un hash estable?) es de implementación y se decide en el ADR de OQ-FL5. Se elige `String` sobre `int` crudo para que el encoding pueda incorporar la era u otro prefijo sin cambiar el tipo del campo que Guardado/Datos de Era ya referencian.

5. **Anti-nihilismo: toda muerte produce exactamente una reliquia, nunca cero** (Pilar 2, honra la válvula de Héroes). Incluso una muerte desperdiciada (`relic_quality = 0.10`, Tier Delgada) produce una reliquia real con el nombre del héroe. Forja nunca descarta, funde ni "salta" una muerte por tener tier bajo — una reliquia Delgada y triste sigue siendo una reliquia. Un `relic_quality` fuera de `[0.10, 1.00]` es un contrato roto de Héroes y **falla ruidosamente** en build de desarrollo, nunca se clampa en silencio para producir cero.

   **Reconciliación del piso 0.10 con Héroes (design-review 2026-08-17).** El piso `0.10` es responsabilidad de Héroes (`base_accidental`, válvula anti-nihilismo de H4), pero su tuning knob permitía antes un rango `0.05–0.15` — un `base_accidental = 0.05` legítimo habría producido `relic_quality = 0.05` en cada muerte accidental (`D=0`), **fuera** del dominio `[0.10, 1.00]` que Forja asume, disparando el loud-fail de Forja en cada muerte desperdiciada. Se corrigió aguas arriba: el rango seguro de `base_accidental` en `sistema-de-heroes.md` se **estrechó a `0.10–0.15`** (coherente con el "Rango de salida [0.10,1.00]" que el propio Héroes ya declaraba), de modo que H4 nunca puede emitir por debajo del piso de dominio de Forja. El loud-fail de Forja queda como red de seguridad ante un contrato roto, no como ruta esperable.

6. **Depósito en el registro + autosave obligatorio (orden fijo).** Tras construir la `RelicRecord`, Forja: (a) la **añade al registro de reliquias del jugador** — Forja es la única fuente de verdad de qué reliquias existen (coherente con Datos de Era Regla 4 y Guardado Regla 4); (b) **dispara el autosave obligatorio** (Guardado AC-02) para persistirla. El orden es estricto: la reliquia se añade al registro **antes** de disparar el autosave, para que la escritura capture la reliquia recién forjada. El juego no continúa hasta que el autosave resuelve (Guardado Regla 1 / AC-04) — la reliquia es irreversible en cuanto el `SAVING` completa.

7. **Forja no posee el efecto de combate ni la exhibición.** Forja produce y persiste la `RelicRecord`; **no** define qué otorga la reliquia en combate (eso lo consume Reliquias/Bendiciones #12, leyendo `relic_category` + `tier`), ni cómo se muestra el panteón (eso lo consume Salón Conmemorativo/Panteón #14, leyendo el registro). Ambos son contratos **provisionales** — ninguno tiene GDD aún; Forja define la forma del dato que deberán respetar (igual que Permadeath definió el hand-off que Forja respeta).

8. **Deduplicación defensiva.** Si Forja recibiera dos veces un veredicto para el mismo `source_hero_id` en la misma `origin_era_id` (bug de doble entrega, que Permadeath AC-P16/AC-P17 ya previene aguas arriba), Forja **no** forja una segunda reliquia — una muerte = una reliquia. La segunda invocación es un no-op registrado con advertencia en build de desarrollo, no un duplicado silencioso.

   **Por qué la clave `(source_hero_id, origin_era_id)` es segura — contrato de unicidad de instancia de héroe (fijado en design-review 2026-08-17).** La clave de dedup solo es correcta si `source_hero_id` identifica una **instancia de héroe única**, no un arquetipo/plantilla compartido. Contrato confirmado: **cada héroe es una unidad nombrada única dentro del roster de su era** — los héroes NO se refuerzan ni reaparecen dentro de una era (a diferencia de las tropas, que sí tienen `reinforcement_ratio`), y el estado `DEAD` es terminal (Héroes AC-H27b). Por tanto un héroe muere **a lo sumo una vez por era**, y `(source_hero_id, origin_era_id)` identifica unívocamente una muerte. La única forma de colisión legítima sería un **error de autoría de datos**: dos entradas del roster de una era con el mismo `hero_id`. Forja se protege de eso validando, al activarse una era (`LOADED`), que los `hero_id` del roster de héroes sean únicos — **loud-fail** ante un duplicado (ver AC-FL26), en vez de arriesgar que la dedup trague silenciosamente una segunda muerte legítima. *(Si en el futuro se introdujera respawn/refuerzo de héroes, la clave de dedup debería migrar a un token de instancia-de-muerte por muerte en el payload de Permadeath — cambio cross-GDD; hoy explícitamente fuera de alcance.)*

### States and Transitions

*(Estado por reliquia en curso de forja — no un estado global del sistema. Una reliquia se procesa de forma esencialmente síncrona; los estados marcan los puntos de compromiso para el manejo de fallos.)*

| Estado | Descripción | Transición desde | Transición hacia |
|---|---|---|---|
| `RECEIVED` | Veredicto recibido de Permadeath en `RESOLVED`; validado (4 campos presentes, `relic_quality ∈ [0.10,1.00]`) | Hand-off de Permadeath | `FORGED` (validación OK); *loud-fail* (payload incompleto/fuera de rango, Edge Cases) |
| `FORGED` | `RelicRecord` construido: `relic_id`/`forge_index` asignados, `tier` derivado, `epitaph` compuesto | `RECEIVED` | `DEPOSITED` |
| `DEPOSITED` | Reliquia añadida al registro en memoria (fuente de verdad); autosave disparado | `FORGED` | `PERSISTED` (autosave OK); fallo bloqueante de guardado (Guardado AC-35, el juego no continúa) |
| `PERSISTED` | Autosave resuelto a `SAVE_EXISTS`; la reliquia es irreversible y visible para consumidores | `DEPOSITED` | — (terminal) |

### Interactions with Other Systems

| Sistema | Dirección | Interfaz |
|---|---|---|
| Permadeath | Permadeath → Forja | Recibe el veredicto final (`hero_id`, `hero_name`, `relic_category`, `relic_quality`) en `RESOLVED`, una sola vez. **Cierra Permadeath OQ-P3 / AC-P16** (Forja era el consumidor crítico sin GDD) |
| Guardado/Persistencia | Forja → Guardado | Dispara el autosave obligatorio tras forjar (Guardado AC-02); Forja posee los datos de reliquia, Guardado los escribe. El juego no continúa hasta `SAVE_EXISTS` |
| Datos de Era/Civilización | Datos → Forja (solo lectura) | Lee qué `era_id` está `ACTIVE` para etiquetar `origin_era_id` de la reliquia. `EraDefinition.legacy_props` referencia los `relic_id` que Forja asignó (Datos de Era Regla 4) |
| Reliquias/Bendiciones | Forja → #12 | Expone la `RelicRecord` (`relic_category` + `tier`) como input para determinar el efecto de combate. *Contrato provisional — sin GDD* |
| Salón Conmemorativo/Panteón | Forja → #14 | Expone el registro de reliquias para exhibición (nombre, categoría, tier, epitafio, era). *Contrato provisional — sin GDD* |
| Transición de Era | Forja → #15 | El registro de reliquias es parte del legado que persiste entre eras. *Contrato provisional — sin GDD* |
| Narrativa Ambiental | Forja → #17 (indirecta) | Consume `legacy_props` (IDs de reliquia de eras anteriores, vía Datos de Era) para poblar props; esos IDs son los `relic_id` de Forja. *Contrato provisional — sin GDD* |

> **Nota de fuente de verdad**: Forja de Legado es el **dueño canónico** de los datos de una reliquia. Guardado persiste el registro por referencia (IDs + campos), Datos de Era lo referencia vía `legacy_props`, y el Panteón/Reliquias lo leen — pero ninguno duplica ni redefine la `RelicRecord`. Coherente con la regla de "persistencia por referencia, nunca por copia" de Guardado (Regla 4) y Datos de Era (Regla 4).

## Formulas

Forja de Legado es un sistema de transformación/persistencia; no tiene fórmulas de balance (el `relic_quality` ya lo resolvió Héroes vía H4, y el efecto de combate de la reliquia es de Reliquias/Bendiciones #12). Su única lógica numérica es un mapeo escalón determinista y un contador. *(Modo lean: `systems-designer` no spawneado — no hay balance ni curvas que evaluar, solo un escalón que consume cortes ya registrados y un contador monótono; mismo criterio que Permadeath P1.)*

### Fórmula FL1 — Mapeo `relic_quality → tier`

Función escalón que asigna la banda discreta de la reliquia. **Consume los cortes ya fijados por Héroes** (registrados en `relic_quality`) — no los redefine.

`tier(relic_quality) = Delgada    si 0.10 ≤ relic_quality < 0.35`
`                    = Sólida     si 0.35 ≤ relic_quality < 0.70`
`                    = Legendaria si 0.70 ≤ relic_quality ≤ 1.00`

| Variable | Símbolo | Tipo | Rango | Descripción |
|----------|---------|------|-------|-------------|
| Calidad de reliquia | `relic_quality` | float | `[0.10, 1.00]` | Recibido de Permadeath; computado por Héroes H4. Fuera de rango → loud-fail (Regla 5) |
| **Tier de reliquia** | `tier` | enum | {Delgada, Sólida, Legendaria} | Banda discreta consumida por #12 (efecto) y #14 (exhibición) |

**Rango de salida**: exactamente 3 valores discretos. Límites inferiores **inclusivos**, superiores exclusivos (salvo el tope 1.00, inclusivo) — idéntico a Héroes AC-H19 (0.35 → Sólida) y AC-H20 (0.70 → Legendaria). Sin división: estructuralmente no hay divide-by-zero.

**Comparación de boundary con tolerancia epsilon (fijado en design-review 2026-08-17).** `relic_quality` NO es un valor autoral: Héroes lo computa en H4 vía una cadena `clamp(base_accidental + D×(base_deliberate − base_accidental + w_stakes×T + w_purpose×P), …)`, donde `T` es un float continuo (`1 − elapsed_s/approach_duration_s`). Por tanto un valor que "debería" caer exacto en un boundary (0.70 es alcanzable resolviendo `0.35·T = 0.30` → `T ≈ 0.857142…`) puede computarse como `0.6999999997` o `0.7000000003` por aritmética de punto flotante. FL1 **debe** comparar los boundaries con una tolerancia `EPSILON_TIER = 1e-6`: un valor dentro de `±EPSILON_TIER` de un corte se clasifica en el tier **superior** (coherente con "límite inferior inclusivo" — `0.70 − ε` cuenta como `0.70` → Legendaria). Sin esta tolerancia, una decisión climática que el jugador "ganó" en el boundary podría degradarse al tier inferior por ruido de bits. *(El boundary `0.35` no es alcanzable por la fórmula real — ver nota de conjunto alcanzable abajo — pero la tolerancia se aplica uniformemente a ambos cortes por robustez.)*

**Nota de conjunto alcanzable (informativa, no un defecto — design-review 2026-08-17).** Con las constantes MVP (`base_accidental=0.10`, `base_deliberate=0.40`), el conjunto de valores que H4 realmente produce es `{0.10} ∪ [0.40, 1.00]`: una muerte accidental (`D=0`) da exactamente `0.10`, y una deliberada (`D=1`) da como mínimo `0.40` (T=0, P=0). Consecuencia sobre los tiers de FL1: **Delgada `[0.10,0.35)` ⟺ muerte accidental** (solo el valor `0.10` la alcanza); la franja `[0.35, 0.40)` y el punto exacto `0.35` **nunca** se producen en juego real; **Sólida `[0.35,0.70)` es alcanzable** desde `0.40` hacia arriba, y **Legendaria** normalmente. Esto es un mapeo limpio y probablemente intencional (accidental → Delgada; deliberada → Sólida/Legendaria), **propiedad del tuning de Héroes, no de Forja** — Forja mapea cortes que no posee. Los boundary-tests de FL1 (AC-FL04) siguen siendo defensa válida aunque su valor exacto no se produzca en la tubería integrada.

**Ejemplos** (mismos boundaries que Héroes ya testea):
1. `relic_quality = 0.10` → Delgada (piso anti-nihilismo, una muerte desperdiciada igual produce reliquia)
2. `relic_quality = 0.3499` → Delgada; `relic_quality = 0.35` → Sólida (boundary inclusivo abajo)
3. `relic_quality = 0.6999` → Sólida; `relic_quality = 0.70` → Legendaria (boundary inclusivo abajo)
4. `relic_quality = 1.00` → Legendaria (tope inclusivo)

### Fórmula FL2 — Asignación del índice de forja

`forge_index(nueva_reliquia) = forge_counter` (valor actual, antes de incrementar)
`forge_counter ← forge_counter + 1` (tras asignar)

| Variable | Símbolo | Tipo | Rango | Descripción |
|----------|---------|------|-------|-------------|
| Contador de forja | `forge_counter` | int | `[0, ∞)` | Monótono, persistido en el guardado, nunca reiniciado entre eras |
| Índice de forja | `forge_index` | int | `[0, ∞)` | Valor asignado a la reliquia; único y estable por reliquia dentro del legado |

**Rango de salida**: enteros no negativos, estrictamente crecientes. Arranca en 0 en un legado nuevo (sin guardado previo). Al cargar, continúa desde el valor persistido — nunca retrocede ni reutiliza un índice. `relic_id` se deriva de este índice de forma determinista (Regla 4), garantizando unicidad sin depender de IDs de instancia del engine.

**Ejemplo**: legado nuevo, mueren 3 héroes en secuencia → `forge_index` = 0, 1, 2; `forge_counter` queda en 3 y se persiste. Tras recargar y forjar una 4ª → `forge_index` = 3 (continúa, no reinicia).

## Edge Cases

- **Si llega un payload incompleto o nulo** (falta `hero_id`, `hero_name`, `relic_category`, o `relic_quality`): **falla ruidosamente** al recibirlo en build de desarrollo — Forja no construye una reliquia con datos incompletos. Es la contraparte de Permadeath AC-P03 (que ya valida aguas arriba); Forja se protege igual, porque una reliquia es permanente y no puede nacer corrupta. Nunca sustituye un default silencioso.

- **Si `relic_quality` llega fuera de `[0.10, 1.00]`** (contrato roto de Héroes): **loud-fail** (Regla 5) — nunca se clampa para producir un tier fuera de banda ni una reliquia "cero". El piso 0.10 es responsabilidad de Héroes (válvula anti-nihilismo); si se viola, es un bug que debe gritar, no absorberse.

- **Si `relic_quality` cae exactamente en un boundary de tier** (`0.35` o `0.70`): FL1 resuelve con límite inferior inclusivo — `0.35` → Sólida, `0.70` → Legendaria. Idéntico a Héroes AC-H19/H20. No es ambigüedad ni bug.

- **Si `relic_category` no es `offensive`/`defensive`/`rally`** (dato roto): **loud-fail** — Forja nunca inventa ni sustituye una categoría por defecto. La categoría es fija por héroe (Héroes AC-H06); un valor desconocido es un error de datos de Héroes/era.

- **Si el autosave falla tras forjar** (disco lleno, permisos): Guardado agota sus reintentos y expone un fallo **bloqueante** (Guardado Regla 1 / AC-35) — el juego no continúa. La `RelicRecord` está en el registro en memoria (`DEPOSITED`) pero **no** alcanzó `PERSISTED`. Forja **no reintenta por su cuenta** — delega enteramente en Guardado. Si el jugador cierra sin que el guardado resuelva, la reliquia de esta sesión se pierde, pero el guardado previo sigue intacto (contrato de Guardado: "este evento específico no se pudo persistir, tu guardado previo está a salvo"). Coherente con el Pilar 1: una reliquia solo es irreversible una vez en disco.

- **Si el juego crashea entre `RESOLVED` y el fin del autosave de Forja** (reliquia forjada en memoria, no persistida): al recargar, la reliquia **no** está en el registro persistido — pero el autosave de `DYING` (Héroes AC-H26) sí persistió el payload de *muerte pendiente de sellar* (incl. `relic_quality`). El flujo de carga coacciona `DYING→DEAD` y **re-forja la reliquia desde el payload persistido** (Héroes AC-H27c / Permadeath Regla 8b). La deduplicación de Forja (Regla 8) garantiza que, si la reliquia sí llegó a persistirse antes del crash, no se forje una segunda; si no, se forja ahora. Resultado: exactamente una reliquia por héroe, incluso a través de un crash a mitad de la cadena — nunca cero, nunca dos.

- **Si Forja recibe dos veces un veredicto para el mismo `source_hero_id` en la misma `origin_era_id`** (doble entrega, que Permadeath AC-P16/AC-P17 ya previene): la segunda invocación es un **no-op** registrado con advertencia en build de desarrollo (Regla 8) — una muerte = una reliquia, nunca un duplicado silencioso con dos `relic_id` distintos.

- **Si no hay ninguna era en estado `ACTIVE` al momento de forjar** (no debería ocurrir — una muerte de héroe ocurre siempre dentro de una era jugándose): **loud-fail** defensivo — Forja no puede etiquetar `origin_era_id` sin una era activa, y una reliquia sin era de origen rompe la referencia de `legacy_props` (Datos de Era). Nunca asigna un `origin_era_id` por defecto.

- **Si Reliquias/Bendiciones (#12) aún no existe** (estado actual del proyecto): Forja funciona igual — acumula reliquias en el registro y las persiste; simplemente nadie consume aún su efecto de combate. Forja **no depende** de #12 para operar. Hoy verificable con un mock del consumidor en el límite de este sistema.

- **Si el `forge_counter` creciera sin cota** (legado muy largo): es un `int` de 64 bits en Godot; el número de héroes que pueden morir en un legado es finito y ridículamente menor que ese techo. No se acota artificialmente — un límite configurable sería complejidad sin beneficio. *(Nota de serialización, design-review 2026-08-17: la afirmación "64 bits" solo sobrevive el round-trip de guardado si Guardado/Persistencia serializa con `FileAccess.store_var`/`get_var` — que preserva `int64` exacto. Si Guardado usara `JSON` (que decodifica todo número como `float`/double, 53 bits de precisión entera), la fidelidad de 64 bits NO se garantiza. Es irrelevante en la práctica —los conteos de muertes por legado son diminutos, muy por debajo de 2⁵³— pero el formato de serialización de Guardado hoy no está especificado en su GDD; a fijar en el ADR de OQ-FL4, cruzado con Guardado.)*

## Dependencies

**Dependencias hacia arriba (upstream) — lo que este sistema necesita:**

| Sistema | Tipo | Interfaz | Estado |
|---|---|---|---|
| Permadeath | Dura (**productor crítico**) | Recibe el veredicto final (`hero_id`, `hero_name`, `relic_category`, `relic_quality`) en `RESOLVED`, una sola vez (Permadeath AC-P16). Es el único input que dispara una forja | ✅ In Design — **cierra Permadeath OQ-P3/AC-P16**; el contrato de hand-off ya está definido en `design/gdd/permadeath.md` (Regla 5) |
| Guardado/Persistencia | Dura | Forja dispara el autosave obligatorio tras forjar (Guardado AC-02); el juego no continúa hasta `SAVE_EXISTS`. Guardado escribe, Forja posee el dato | ✅ Designed — Guardado ya lista a Forja de Legado en sus Interactions/Dependencies (AC-02) |
| Datos de Era/Civilización | Dura (**solo lectura**) | Lee qué `era_id` está `ACTIVE` para etiquetar `origin_era_id`. La referencia inversa (`EraDefinition.legacy_props` → `relic_id`) hace la relación bidireccional | ⚠️ **Contrato provisional** — Datos de Era **no lista hoy a Forja** en su tabla de Dependientes (igual que le pasó a Permadeath con `N_max`). Requiere añadir la fila en una pasada de reconciliación — ver Open Questions OQ-FL1 |

**Dependientes hacia abajo (downstream) — dependen de este:**

| Sistema | Tipo | Interfaz |
|---|---|---|
| Reliquias/Bendiciones | Dura (**consumidor crítico**) | Consume `relic_category` + `tier` de cada `RelicRecord` para determinar el efecto de combate/bendición. *Sin GDD aún — Forja define el contrato provisional que #12 respetará* |
| Salón Conmemorativo/Panteón | Dura | Consume el registro de reliquias (nombre, categoría, tier, epitafio, era) para exhibirlo. *Sin GDD aún — contrato provisional* |
| Transición de Era | Dura | El registro de reliquias es parte del legado que persiste entre eras; Transición lo arrastra al cambiar de civilización. *Sin GDD aún — contrato provisional* |
| Narrativa Ambiental | Blanda (indirecta) | Consume `legacy_props` (IDs de reliquia de eras anteriores, vía Datos de Era) para poblar props; esos IDs son los `relic_id` de Forja. *Sin GDD aún — contrato provisional* |

**Nota de consistencia bidireccional:**
- Permadeath lista a Forja de Legado como "consumidor crítico" downstream (✅ coincide con este upstream; cierra su OQ-P3).
- Guardado/Persistencia lista a Forja de Legado como consumidor que dispara autosave (✅ coincide, AC-02).
- Datos de Era/Civilización **no** lista a Forja en su tabla de Dependientes (⚠️ ver OQ-FL1) — a corregir en reconciliación.
- `systems-index.md` lista la fila de Forja con "Depends On: Permadeath" únicamente — debería añadir **Guardado/Persistencia** y **Datos de Era/Civilización** (⚠️ ver Fase 5 / OQ-FL1).

**Relación con Reliquias/Bendiciones y Panteón (sin GDD):** Forja es el productor del cual ambos dependen. Como ninguno existe aún, Forja **define la forma del dato** (`RelicRecord`) que deberán consumir — igual que Permadeath definió el hand-off que Forja respeta. Estos contratos son provisionales hasta que esos GDDs se escriban.

## Tuning Knobs

Forja de Legado tiene deliberadamente **muy pocos knobs** — es un sistema de transformación/persistencia, no de balance. Los cortes de tier los posee Héroes (`relic_quality`, no se duplican aquí) y el efecto de combate de la reliquia lo posee Reliquias/Bendiciones (#12). Los únicos ajustes de este sistema son de *contenido/presentación de procedencia*, no de balance de juego.

| Knob | Símbolo | Tipo | Default | Rango seguro | Qué se rompe en extremos |
|---|---|---|---|---|---|
| Tabla de plantillas de epitafio | `epitaph_templates` | data (dict `categoría×tier → string`) | 9 entradas (3 categorías × 3 tiers) | 9 entradas pobladas, ninguna vacía | Una entrada faltante deja una reliquia sin descriptor de procedencia legible → loud-fail al cargar la tabla en build de desarrollo (una reliquia sin epitafio rompe el Pilar 2 en la presentación). No es balance: es cobertura de contenido |

**Knobs que NO existen (decisiones conscientes):**
- **No hay knob de cortes de tier**: los boundaries `[0.10,0.35)/[0.35,0.70)/[0.70,1.00]` los posee Héroes (`relic_quality`, registro). Forja los consume vía FL1; duplicarlos como knob crearía dos fuentes de verdad que podrían desincronizarse (mismo criterio anti-duplicación que Datos de Era/Guardado Regla 4).
- **No hay knob de efecto/poder de la reliquia**: eso es Reliquias/Bendiciones (#12). Forja no toca balance de combate — meterlo aquí contradiría el alcance delgado y pisaría #12.
- **No hay knob de tope de reliquias en el panteón**: el panteón crece sin límite por diseño (Pilar 2 — el legado se acumula). El límite de cuántas se *renderizan* a la vez es de Datos de Era (`max_legacy_props_visible`) o del Panteón (#14), no de Forja.
- **No hay knob de on/off de la forja**: toda muerte de héroe forja una reliquia (Regla 5), regla dura no configurable — desactivarla rompería el Pilar 2.

## Visual/Audio Requirements

*Referencia rectora: Art Bible Principio A ("El Legado es Luz"). **Forja de Legado no diseña la escenificación** — la revelación del ícono durante el beat la poseen Héroes (V-6: silueta → fragmentos de vitral → ícono de reliquia) y el timing de Permadeath (PV-5); la exhibición en el panteón la posee Salón Conmemorativo/Panteón (#14). Esta sección fija únicamente el **contrato de identidad del ícono** que Forja posee.*

**FV-1 — Forja posee la identidad del ícono final de la reliquia, no su escenificación.** Héroes V-6 cede el ícono final a Forja ("el ícono final es propiedad de Forja de Legado; este sistema solo provee `relic_category` + `relic_quality`"). El ícono de una reliquia se determina por `relic_category` (silueta base: arma/estandarte/reliquia-defensiva) + `tier` (grado de acabado dorado). Forja garantiza que cada `RelicRecord` referencia un ícono resoluble; **no** anima la revelación ni compone la escena.

**FV-2 — El dorado es exclusivo del legado (Principio A).** El ícono de reliquia es uno de los pocos elementos con tratamiento dorado/luminoso pleno del juego — es literalmente un objeto nacido de una muerte permanente, el caso central del test del Principio A ("¿esto existe porque un héroe murió por ello?"). El grado de brillo/acabado escala con el `tier` (Delgada = plomo dorado apenas insinuado; Legendaria = acabado dorado pleno), reforzando visualmente que una muerte bien gastada produce un objeto más radiante. *(El diseño pictórico concreto lo posee el art bible / art-director; Forja solo fija que `tier` es el input de grado de acabado.)*

**FV-3 — Audio de la forja: handoff, sin verbo propio.** El momento sonoro del nacimiento de la reliquia (si lo hay) se sincroniza al hit-point de revelación de V-6 (Héroes A-1/Permadeath PV-4), no lo posee Forja como diseñador de sonido. Coherente con el understatement anti-melodrama del proyecto. *(Contrato provisional — sin Dirección de Audio aún.)*

## UI Requirements

*Forja de Legado **no tiene HUD propio** (igual que Permadeath). Esta sección fija su única frontera con la UI.*

**FU-1 — Sin UI de forja en sesión.** Forja no expone ninguna pantalla, prompt ni readout durante el juego. La revelación de la reliquia al morir el héroe la maneja el beat de Permadeath/Héroes (V-6); la exhibición del panteón acumulado la maneja Salón Conmemorativo/Panteón (#14). Forja solo produce y persiste el dato.

**FU-2 — Sin editorializar (understatement).** Coherente con Héroes U-5 / Permadeath PU-3: Forja no dispara ningún texto de sistema ("Reliquia forjada", "Legado creado"). El epitafio (`epitaph`) es *dato de procedencia* que consumidores (Panteón #14) pueden mostrar en su propio contexto — Forja no lo renderiza ni decide cuándo se ve.

## Acceptance Criteria

*Convención: formato Dado/Cuando/Entonces + etiqueta de tipo de evidencia (`[Logic/unit]`, `[Integration]`). Los AC marcados **(bloqueado)** dependen de un sistema sin GDD aún (Reliquias/Bendiciones #12, Panteón #14) — hoy verificables solo con mock en el límite de este sistema. Permadeath, Guardado/Persistencia y Datos de Era/Civilización **sí** tienen GDD — los AC contra esos contratos NO están bloqueados, solo pendientes de implementación (mismo criterio que `permadeath.md` aplicó tras su reconciliación OQ-P6).*

### A. Recepción y creación de la Reliquia (Regla 1)

**AC-FL01 — Un veredicto de Permadeath produce exactamente una Reliquia** **[Integration]**
Dado un veredicto (`hero_id`, `hero_name`, `relic_category`, `relic_quality`) recibido de Permadeath en `RESOLVED`, cuando Forja lo procesa, entonces construye exactamente una `RelicRecord` y la lleva a `FORGED` — ninguna invocación produce cero ni dos reliquias.

**AC-FL02 — Solo héroes forjan reliquias; no existe punto de entrada para tropas** **[Logic/unit]**
Dado el contrato de entrada de Forja (el único hand-off que consume es el de Permadeath `RESOLVED`, propio de la muerte de un héroe, expuesto como el símbolo de entrada provisional **`receive_relic(hero_id, hero_name, relic_category, relic_quality)`** — mismo hook que Permadeath AC-P16 asume en su mock), cuando se audita la superficie pública de Forja, entonces `receive_relic` es su **único** punto de entrada de creación y no expone ningún otro método ni escucha ninguna señal que acepte la muerte de una tropa como input — la creación de reliquias está estructuralmente acotada a héroes. *(Se complementa con un check estático de CI que grepea invocaciones de `receive_relic` fuera de Permadeath — ver nota de testabilidad al final. El nombre exacto del símbolo se confirma en el ADR OQ-FL4; hasta entonces `receive_relic` es el contrato provisional que da al grep un target concreto.)*

### B. Mapeo `relic_quality → tier` (Regla 2, Fórmula FL1)

**AC-FL03 — Piso anti-nihilismo: 0.10 → Delgada** **[Logic/unit]**
Dado `relic_quality = 0.10`, cuando FL1 se evalúa, entonces `tier = Delgada` — el piso de Héroes produce una reliquia real, nunca ninguna.

**AC-FL04 — Boundary inferior 0.35 (inclusivo)** **[Logic/unit]**
Dado `relic_quality = 0.3499`, cuando FL1 se evalúa, entonces `tier = Delgada`; dado `relic_quality = 0.35` exacto, entonces `tier = Sólida` (límite inferior inclusivo, coherente con Héroes AC-H19).

**AC-FL05 — Boundary inferior 0.70 (inclusivo)** **[Logic/unit]**
Dado `relic_quality = 0.6999`, cuando FL1 se evalúa, entonces `tier = Sólida`; dado `relic_quality = 0.70` exacto, entonces `tier = Legendaria` (límite inferior inclusivo, coherente con Héroes AC-H20).

**AC-FL06 — Tope superior 1.00 (inclusivo)** **[Logic/unit]**
Dado `relic_quality = 1.00`, cuando FL1 se evalúa, entonces `tier = Legendaria`.

**AC-FL07 — Forja nunca recomputa `relic_quality`; almacena ambos valores exactos** **[Logic/unit]**
Dado un `relic_quality` recibido, cuando Forja construye la `RelicRecord`, entonces el campo `relic_quality` almacenado es idéntico byte-a-byte al recibido (nunca recalculado) y el campo `tier` es el resultado de FL1 sobre ese mismo valor — ambos coexisten en el registro.

### C. Estructura de la Reliquia (Regla 3)

**AC-FL08 — `RelicRecord` contiene todos los campos requeridos con los valores transportados** **[Logic/unit]**
Dado un veredicto de entrada y una era `ACTIVE` conocida, cuando Forja construye la `RelicRecord`, entonces el registro resultante contiene exactamente `relic_id`, `source_hero_id`, `source_hero_name`, `relic_category`, `relic_quality`, `tier`, `origin_era_id`, `forge_index`, `epitaph` — sin campos faltantes, y los campos transportados (`source_hero_id`, `source_hero_name`, `relic_category`, `relic_quality`) son idénticos a los recibidos del veredicto.

**AC-FL09 — `epitaph` se deriva de `relic_category × tier`; tabla incompleta → loud-fail al cargar** **[Logic/unit]**
Dado la tabla `epitaph_templates` con las 9 entradas requeridas —el producto cartesiano de las 3 categorías `{offensive, defensive, rally}` × los 3 tiers `{Delgada, Sólida, Legendaria}`— cuando se carga con cualquiera de esas 9 claves faltante o con string vacío, entonces la carga falla ruidosamente en build de desarrollo, nombrando la(s) clave(s) faltante(s) — nunca se forja una reliquia con un `epitaph` nulo o por defecto.

### D. Índice de forja y `relic_id` estables (Regla 4, Fórmula FL2)

**AC-FL10 — `forge_index` monótono desde 0 en un legado nuevo** **[Logic/unit]**
Dado un legado nuevo (sin guardado previo) donde mueren 3 héroes en secuencia, cuando cada uno se forja, entonces `forge_index` asignado es 0, 1, 2 en ese orden y `forge_counter` queda en 3.

**AC-FL11 — `forge_counter` persistido continúa tras recarga, nunca reinicia ni reutiliza** **[Integration]**
Dado un `forge_counter` persistido en 3 tras una sesión previa (incl. a través de un cambio de era), cuando el juego recarga y se forja una 4ª reliquia, entonces `forge_index = 3` (continúa desde el valor persistido) — nunca vuelve a 0 ni reutiliza 0-2.

**AC-FL12 — `relic_id` determinista y único, sin depender de IDs de instancia del engine** **[Logic/unit]**
Dado dos invocaciones de forja con el mismo `forge_counter` de entrada (misma posición del contador, sesiones simuladas distintas), cuando se deriva `relic_id`, entonces el resultado es idéntico entre ambas invocaciones (determinismo) y, para `forge_counter` distintos, `relic_id` nunca colisiona (unicidad) — mismo criterio anti-reciclaje que Kaiju `entity_id`. *(La cláusula negativa "nunca usa `get_instance_id()`" se enforza con un check estático de CI — ver nota de testabilidad al final.)*

### E. Anti-nihilismo (Regla 5)

**AC-FL13 — En el piso, el registro crece en exactamente una entrada (no cero)** **[Logic/unit]**
Dado un registro con `M` reliquias y un veredicto con `relic_quality = 0.10` (Tier Delgada, el peor caso anti-nihilismo), cuando Forja procesa el veredicto hasta `DEPOSITED`, entonces el conteo del registro es exactamente `M + 1` (nunca `M` — la muerte de tier bajo no se descarta ni se "salta") y la nueva entrada es recuperable por su `relic_id`. *(Complementa AC-FL03 [mapeo de tier en el piso] y AC-FL08 [forma completa del `RelicRecord`] con la aserción distinta de **membresía en el registro**: que una muerte desperdiciada efectivamente incrementa el panteón, no solo que produce un record bien formado.)*

**AC-FL14 — `relic_quality` fuera de `[0.10, 1.00]` → loud-fail, nunca clamp** **[Logic/unit]**
Dado un veredicto con `relic_quality = 0.05` o `relic_quality = 1.05` (fuera de rango, contrato roto de Héroes), cuando Forja lo recibe, entonces falla ruidosamente en build de desarrollo — nunca clampa a un valor válido ni produce una reliquia "cero".

### F. Depósito + autosave obligatorio (Regla 6, Estados)

**AC-FL15 — Orden estricto: registro antes de autosave** **[Logic/unit]**
Dado una `RelicRecord` recién construida (`FORGED`), cuando Forja la deposita, entonces la llamada de adición al registro en memoria ocurre **antes** de la llamada que dispara el autosave (verificable con spies ordenados) — nunca al revés.

**AC-FL16 — El juego no continúa hasta `SAVE_EXISTS`; la reliquia es irreversible tras `SAVING`** **[Integration]**
Dado una `RelicRecord` en `DEPOSITED` con el autosave disparado, cuando el autosave resuelve a `SAVE_EXISTS` (Guardado AC-02/AC-04), entonces la reliquia transiciona a `PERSISTED` y el flujo del juego continúa recién en ese punto — ningún consumidor observa la reliquia como definitiva antes de `SAVE_EXISTS`.

**AC-FL17 — Fallo bloqueante de autosave deja la reliquia en `DEPOSITED`, sin reintento propio** **[Integration]**
Dado un autosave que agota sus reintentos y falla (Guardado AC-35), cuando Forja observa el fallo, entonces la `RelicRecord` permanece en `DEPOSITED` (no alcanza `PERSISTED`), el juego no continúa, y Forja no reintenta el guardado por su cuenta — delega enteramente en Guardado.

### G. Alcance: Forja no posee efecto de combate ni exhibición (Regla 7)

**AC-FL18 — Forja completa `RECEIVED→PERSISTED` sin que exista ningún consumidor de #12/#14** **[Integration]**
Dado un entorno de test sin ningún mock de Reliquias/Bendiciones ni de Salón Conmemorativo/Panteón conectado, cuando Forja procesa un veredicto completo, entonces alcanza `PERSISTED` exitosamente — Forja no requiere que #12/#14 existan para cumplir su propia responsabilidad (confirma el desacople estructural de la Regla 7 sin depender de una interfaz aún no diseñada).

**AC-FL19 — `RelicRecord` expone `relic_category` + `tier` en forma consumible por Reliquias/Bendiciones** **(bloqueado — Reliquias/Bendiciones #12 sin GDD)** **[Integration]**
*Mock Contract Assumption: el mock de #12 expone un único hook de lectura `get_relic_combat_inputs() → {relic_category, tier}` sobre una `RelicRecord` dada. Re-verificar contra el GDD real de Reliquias/Bendiciones cuando exista.*
Dado una `RelicRecord` en `PERSISTED`, cuando el mock de #12 la consulta, entonces recibe `relic_category` y `tier` sin necesidad de leer `relic_quality` ni ningún otro campo interno — confirma que la superficie mínima que #12 necesitará ya está expuesta.

**AC-FL20 — El registro de reliquias expone lectura consumible por el Panteón** **(bloqueado — Salón Conmemorativo/Panteón #14 sin GDD)** **[Integration]**
*Mock Contract Assumption: el mock de #14 expone un único hook de lectura `list_relics() → [RelicRecord]` sobre el registro completo. Re-verificar contra el GDD real de Panteón cuando exista.*
Dado un registro con N reliquias `PERSISTED`, cuando el mock de #14 lo consulta, entonces recibe la lista completa con `source_hero_name`, `relic_category`, `tier`, `epitaph`, `origin_era_id` de cada una — confirma que la superficie mínima de exhibición ya está expuesta.

### H. Deduplicación defensiva (Regla 8)

**AC-FL21 — Doble entrega del mismo `source_hero_id`+`origin_era_id` → no-op, nunca dos `relic_id`** **[Logic/unit]**
Dado un veredicto ya forjado para `source_hero_id=X` en `origin_era_id=Y`, cuando Forja recibe un segundo veredicto idéntico en `hero_id`+`origin_era_id`, entonces la segunda invocación es un no-op registrado con advertencia en build de desarrollo — el registro sigue conteniendo exactamente una `RelicRecord` para ese héroe en esa era, con un único `relic_id`.

**AC-FL26 — `hero_id` único por roster de era → la clave de dedup es segura; roster con `hero_id` duplicado → loud-fail al activar la era** **[Logic/unit]**
Dado el roster de héroes de una era que se está activando (`LOADED`), cuando Forja (o el validador de carga) inspecciona los `hero_id` de ese roster, entonces: (a) si todos son únicos, la validación pasa —confirmando la precondición de unicidad de instancia sobre la que descansa la dedup de Regla 8 (dos muertes nunca comparten `(hero_id, origin_era_id)` salvo doble entrega, ya cubierta por AC-FL21)—; (b) si dos entradas del roster comparten `hero_id`, la activación de la era **falla ruidosamente** en build de desarrollo, nombrando el `hero_id` colisionante — nunca se permite un roster donde la dedup pudiera tragar silenciosamente una segunda muerte legítima. *(Inyectable vía el mismo `ActiveEraProvider` stub de AC-FL24: el roster se provee como fixture, desacoplado de Datos de Era real.)*

### I. Edge Cases

**AC-FL22 — Payload incompleto o nulo → loud-fail** **[Logic/unit]**
Dado un veredicto con cualquier campo faltante o nulo (`hero_id`, `hero_name`, `relic_category`, o `relic_quality`), cuando Forja lo recibe en `RECEIVED`, entonces falla ruidosamente en build de desarrollo — nunca construye una `RelicRecord` con datos incompletos ni sustituye un default silencioso.

**AC-FL23 — `relic_category` desconocida → loud-fail** **[Logic/unit]**
Dado un veredicto con `relic_category` fuera de `{offensive, defensive, rally}`, cuando Forja lo recibe, entonces falla ruidosamente — nunca inventa ni sustituye una categoría por defecto.

**AC-FL24 — Sin era `ACTIVE` al forjar → loud-fail** **[Logic/unit]**
Dado un momento de forja donde ninguna era está en estado `ACTIVE` —inyectado vía un **proveedor de era stubeado** (`ActiveEraProvider` mock que retorna `null`/none en lugar de leer Datos de Era real, mismo seam que Permadeath AC-P08b usa para su lectura de roster)— cuando Forja intenta etiquetar `origin_era_id`, entonces falla ruidosamente — nunca asigna un `origin_era_id` por defecto ni nulo. *(El seam concreto —parámetro inyectado vs. autoload stubeado— se fija con el patrón de implementación del ADR OQ-FL4; el AC solo exige que la lectura de era ACTIVE sea inyectable para poder forzar el caso "sin era" sin una era real cargada.)*

**AC-FL25 — Recuperación por crash entre `RESOLVED` y el autosave de Forja: re-forja desde el payload de `DYING`, dedup evita el duplicado** **[Integration]**
Dado un crash ocurrido entre la confirmación `RESOLVED` de Permadeath y el fin del autosave de Forja (la `RelicRecord` nunca alcanzó `PERSISTED`), cuando el juego recarga, entonces el flujo de carga coacciona `DYING → DEAD` (Héroes AC-H27c / Permadeath Regla 8b) y re-forja la reliquia desde el payload persistido de `DYING`; la deduplicación de Forja (Regla 8) garantiza que, si la reliquia sí había alcanzado `PERSISTED` antes del crash, la re-forja es un no-op — el resultado final es exactamente una reliquia por héroe, nunca cero, nunca dos.

### Clasificación de tipo de story (gate de evidencia)

| AC # | Tipo | Evidencia | Gate |
|---|---|---|---|
| AC-FL02, FL03, FL04, FL05, FL06, FL07, FL08, FL09, FL10, FL12, FL13, FL14, FL15, FL21, FL22, FL23, FL24, FL26 | Logic | Unit test (`tests/unit/forja-de-legado/`) | Bloqueante |
| AC-FL01, FL11, FL16, FL17, FL18, FL25 | Integration | Integration test | Bloqueante |
| AC-FL19, FL20 | Integration (bloqueado) | Integration test con mock (Reliquias/Bendiciones #12 / Panteón #14 — sin GDD) | Bloqueante (hoy solo vía mock) |

*(Nota: ningún AC de Forja depende de Permadeath, Guardado/Persistencia o Datos de Era/Civilización estando "sin GDD" — los tres ya tienen GDD, así que esos AC son Integration normal, pendientes solo de implementación, no de diseño aguas arriba. Solo AC-FL19/FL20 están bloqueados, y únicamente porque dependen de #12/#14.)*

**Nota de testabilidad (checks estáticos de CI que complementan los unit tests):**

*Ambos checks dependen de que el ADR de OQ-FL4 fije la ubicación del módulo de Forja (directorio/autoload) y confirme el nombre del símbolo de entrada. Hasta entonces, los targets abajo son **provisionales** — nombrados aquí para que el check sea accionable en cuanto exista el layout de código, no para bloquear su escritura hoy.*

- **Regla 1 ("solo héroes forjan") y Regla 7 (ownership de alcance)** son afirmaciones de superficie/ownership, no de runtime — no hay input de "muerte de tropa" ni "efecto de combate" que Forja pueda rechazar en caja negra porque ese código no existe. AC-FL02 y AC-FL18 las cubren como auditoría de superficie y como aserción positiva de ciclo de vida; se complementan con un **grep estático de CI**: `grep -rn "receive_relic(" src/ --exclude-dir=<módulo-de-forja>` no debe arrojar ninguna invocación fuera del módulo de Permadeath (el único productor legítimo). *(Target provisional: símbolo `receive_relic`; ruta del módulo a fijar en OQ-FL4.)*
- **Regla 4 ("`relic_id` nunca de `get_instance_id()`")** es una cláusula negativa no verificable por el valor resultante. AC-FL12 prueba las propiedades observables (determinismo, unicidad); la cláusula negativa se enforza con un **grep estático de CI**: `grep -rn "get_instance_id()" <ruta-del-módulo-de-forja>` no debe arrojar ninguna coincidencia. *(La "ruta del módulo de Forja" —p. ej. `src/legacy/forge/` o el archivo del autoload de forja— se fija en el ADR OQ-FL4; hasta que exista ese layout, el grep no tiene scope concreto y este check queda pendiente de OQ-FL4, no accionable hoy.)*

## Open Questions

**OQ-FL1 — ✅ RESUELTO 2026-08-17 (al pasar Forja a Approved).**
Forja lee qué `era_id` está `ACTIVE` (para `origin_era_id`) y `EraDefinition.legacy_props` referencia los `relic_id` que Forja produce — relación bidireccional. Reconciliación aplicada: (a) Datos de Era/Civilización ahora lista a Forja de Legado en su tabla de Dependientes (fila solo-lectura de era `ACTIVE`); (b) `systems-index.md` ya lista la fila de Forja con "Depends On: Permadeath, Guardado/Persistencia, Datos de Era/Civilización" (completa). Fue cosmético/estructural, sin cambio de diseño — mismo patrón que se resolvió para Permadeath↔Datos de Era el 2026-08-16.

**OQ-FL2 — Contrato provisional con Reliquias/Bendiciones (#12, sin GDD).**
Forja expone `relic_category` + `tier` de cada `RelicRecord` como input del efecto de combate/bendición. La forma exacta (método de lectura, estructura del evento) es provisional (AC-FL19 bloqueado). **Acción**: confirmar al diseñar Reliquias/Bendiciones (#12) — es el consumidor crítico downstream que cierra la cadena Pilar 2 (muerte → reliquia → **poder en combate**). Forja define la forma del dato; #12 la respetará.

**OQ-FL3 — Contrato provisional con Salón Conmemorativo/Panteón (#14, sin GDD).**
Forja expone el registro completo de reliquias para exhibición. La forma exacta de lectura es provisional (AC-FL20 bloqueado). **Acción**: confirmar al diseñar el Panteón (#14).

**OQ-FL4 — Representación de la `RelicRecord`: ¿Resource (`.tres`) o dato serializado en el save? → becomes an ADR.**
El GDD define *qué campos* lleva una reliquia y *qué significan*, no *cómo se serializa*. Como el registro es estado mutable persistido (no dato autoral inmutable como `EraDefinition`), probablemente viva serializado dentro del save de Guardado (por referencia, Guardado Regla 4), no como `.tres` autoral. Pero la decisión concreta (estructura de datos, formato de serialización, dónde vive el registro en runtime — Autoload vs. nodo) es de arquitectura. **Acción**: crear un ADR con `/architecture-decision` antes de implementar, coordinado con el patrón de implementación de Permadeath (OQ-P5) y el esquema de save de Guardado.

**Scope obligatorio del ADR (añadido en design-review 2026-08-17 — el `godot-specialist` flageó que estos tres puntos tocan directamente la garantía de persistencia y NO deben quedar implícitos):**
1. **Mismo frame, sin llamadas diferidas en la ruta depósito→autosave.** La garantía de orden de AC-FL15 (añadir-al-registro **antes** de disparar el autosave) se rompe si el depósito o el disparo usan `call_deferred()` / `CONNECT_DEFERRED`: el orden se vuelve no determinista entre frames y el test con spies pasaría en aislamiento mientras el hand-off real corre en carrera. El ADR debe fijar que la mutación del registro y el disparo del autosave ocurren en el **mismo call frame**, sin llamadas diferidas en esa ruta.
2. **`assert()` no basta para la validación que cruza frontera de confianza.** Los loud-fail del GDD (payload incompleto, `relic_quality` fuera de rango, `relic_category` desconocida, `epitaph_templates` incompleta) validan datos que **llegan de otros sistemas** (no bugs internos). Como `assert()` se compila fuera en builds exportados, confiar solo en él enviaría **cero validación** al jugador → `RelicRecord` malformadas silenciosas o crashes por claves faltantes, socavando la propia garantía anti-nihilismo. El ADR (o una nota de coding-standard) debe especificar el patrón: `assert()` (señal ruidosa en dev) **emparejado con** un `if`-guard + `push_error()` + ruta de fallo seguro que **permanezca activa en release**.
3. **Serialización de `forge_counter` como `int64`.** Ver la nota de serialización en Edge Cases: si se requiere fidelidad de 64 bits como contrato, usar `FileAccess.store_var`/`get_var` (no `JSON`, que trunca a 53 bits). Coordinar con el formato de save de Guardado (hoy no especificado en su GDD).
4. **Bloqueo no-congelante en el autosave (Regla 6).** "El juego no continúa hasta `SAVE_EXISTS`" debe implementarse como `await` sobre la señal de completado de Guardado (cede al main loop, mantiene el render del indicador "guardando…"), **nunca** como ejecución literalmente síncrona ni `OS.delay_msec()`. La sección "States and Transitions" describe el proceso como "esencialmente síncrono" — el ADR debe aclarar que eso significa una corrutina gateada por `await`, no un bloqueo del hilo.

**OQ-FL5 — Esquema exacto de *encoding* de `relic_id` desde `forge_index`.**
La Regla 4 fija que `relic_id` se deriva de forma determinista y única del `forge_index` (nunca de `get_instance_id()`), pero no fija el *formato* exacto (¿`"relic_%d" % forge_index`? ¿`"{origin_era_id}:{forge_index}"`? ¿un hash estable?). **Acción**: fijar en el mismo ADR de OQ-FL4. **Restricciones de diseño ya fijadas (design-review 2026-08-17, ver Regla 4):** tipo **`String`**; **único en todo el legado** (global al save); **estable** a través de guardados/cargas. Solo resta la elección del *encoding* concreto, que es de implementación.
