# Cross-GDD Review Report

**Date:** 2026-08-18
**GDDs Reviewed:** 13 system GDDs + concept + registry
**Systems Covered:** Input, Datos de Era, Guardado, Control, Tropas, Héroes, Temporizador, Combate, Encuentro con Kaiju, Permadeath, Forja de Legado, Reliquias/Bendiciones, UI/HUD

> **✅ Reporte completo.** Los tres pases corrieron: **Holismo de Diseño (Fase 3)** el 2026-08-18 (abajo, con adenda de resolución de la misma fecha); **Consistencia cross-GDD (Fase 2)** y **Walkthrough de escenarios (Fase 4)** re-corridos en sesión limpia el 2026-08-18 (2 agentes de consistencia en paralelo + 1 de escenarios). La consistencia de VALORES está adicionalmente cubierta por el `/consistency-check` dedicado del mismo día (PASS, 0 conflictos — `docs/consistency-report-2026-08-18.md`). **Veredicto consolidado: FAIL — no avanzar a `/create-architecture` hasta resolver los bloqueantes (ver Verdict al final).**
>
> *Nota de orden de lectura: las secciones aparecen como Fase 3 (holismo) → Fase 2 (consistencia) → Fase 4 (escenarios) → GDDs flaggeados → Verdict consolidado → Adenda de resolución de Fase 3. Los ids de hallazgo de Fase 2 usan prefijo `F2-`; los de Fase 4 usan `S#`; los de Fase 3 usan `B#/W#`.*

---

## Game Design Issues (Fase 3 — completa)

### 🔴 Blocking

**B1 — La Regla 10 de Reliquias contradice el requisito #3 del MVP.**
`reliquias-bendiciones.md` Regla 10 (aplicada 2026-08-18) prohíbe que las muertes intra-era entren al pool. `game-concept.md` MVP Definition requiere "2-3 reliquias heredables generadas a partir de la muerte del héroe" en una **sola era**. Mutuamente excluyentes. El workaround (pre-sembrar panteón "era 0", OQ-RB5) hace que el MVP demuestre la invocación con reliquias de héroes que el jugador nunca vio morir — debilitando el design-test de la propia fantasía. *Nota: esta tensión es consecuencia directa del fix del bloqueante #4 del design-review; requiere decisión de scope MVP.*

**B2 — Sobrecarga de atención en CLIMAX (~6-8 sistemas activos vs. techo 3-4).** Control de unidades, telegrafío del kaiju, readout de peligro ×3 (`ui-hud.md` OQ-U8 sin resolver), esbirros, decisiones P de marcado, timing de Sacrificio, Furia (b), y el draft 3-choose-1 + cargas + band_headroom + timers. La cámara lenta (Regla 7b) mitiga la *aditividad* del draft pero no la densidad base. `ui-hud.md` OQ-U8 predata este GDD y su fila de dependencias aún dice Reliquias "sin GDD" — nunca contó el draft.

**B3 — "Farmear muertes" es la meta óptima; Furia la premia.** Cada muerte → 1 reliquia permanente (`forja-de-legado.md` Regla 5); héroes resetean por era sin costo cross-era; muertes deliberadas tardías dan Sólida/Legendaria fiable. Peor: la barra de Furia (b) se calcula sobre héroes **vivos** (`encuentro-con-kaiju.md` Regla 10b), así que matar héroes relaja la presión anti-turtle. Cross-GDD (Encuentro × Permadeath × Forja).

**B4 — Reliquias = fuente infinita sin sumidero.** `pool_cap=16` FIFO es throttle de visibilidad, no sumidero (AC-RB38: RelicRecord nunca se borra). Toda la escasez la carga `invocation_charges`. *(Nota del revisor senior: parcialmente by-design — el panteón es una colección que crece, no un consumible; el problema real es B3, el farmeo, no la acumulación en sí. La retórica "finitas, no farmeables" del concepto sí es engañosa y conviene reencuadrarla.)*

**B5 — `relic_category` es pre-autorado en `HeroDefinition`**, fijado antes de que el héroe pelee (`sistema-de-heroes.md` Regla 1/AC-H06). El Unique Hook dice "su poder mecánico refleja exactamente cómo murió" — pero solo el *tier* (magnitud) refleja la muerte; la *categoría* (tipo de efecto) refleja quién era el héroe. Con OQ-RB10 (9 combos + epitafios de plantilla), la capa mecánica se acerca a rareza ARPG diferenciada por retrato. *(Nota senior: lectura defendible — categoría = identidad del héroe, tier = calidad de la muerte; pero el lenguaje del concepto promete más. Decisión a nivel concepto.)*

### ⚠️ Warnings

- **W1** — Anclaje ofensivo/defensivo unilateral (cuenta golpes comprados, no golpes esperados recibidos en la ventana); `rally` sin ancla y a menudo lee 0 vía band_headroom → el 3-choose-1 degrada a 2 opciones vivas. OQ-RB8d insuficiente por sí solo.
- **W2** — Peor caso F-RB1 (25→79 con 3 Legendarias ofensivas distintas) excede el techo de legibilidad 43 que el propio argumento de anclaje asume.
- **W3** — Legendaria `rally` (5 unidades instantáneas) bypassa la economía de attrition que protege `reinforcement_ratio` (`sistema-de-tropas.md`).
- **W4** — Nadie posee el escalado cross-era kaiju-vs-pool ("cada kaiju exige combinaciones más específicas"); Transición de Era #15 Not Started.
- **W5** — Fantasía de "drafter Hades" de Reliquias en tensión con la identidad deliberada-reverente de los otros GDDs; la cámara lenta es un parche UX, no una reconciliación de fantasía.
- **W6** — `game_time_paused` (Permadeath Regla 4, stop total) × `offering_time_scale` (Reliquias 7b, nunca pausa) sin contrato de interacción; un héroe que muere durante `OFFERING` es edge case reconocido. OQ-RB9 no incluye a Permadeath.

---

## Consistency Issues (Fase 2 — COMPLETA, re-corrida 2026-08-18 sesión limpia)

Re-corrida con 2 agentes paralelos (wiring: bidireccionalidad 2a / stale-refs 2c / ownership 2d — general-purpose; semántica: contradicciones de reglas 2b / rangos de fórmula 2e / cross-check de ACs 2f — systems-designer). Cobertura completa, sin truncar. Los hallazgos se agrupan aquí por causa raíz; varios fueron detectados independientemente por ambos agentes (convergencia = señal fuerte). El `/consistency-check` dedicado del día ya confirmó que los **valores registrados no tienen conflicto** (PASS) — esta fase cubre estructura (wiring) y semántica (reglas/fórmulas/ACs), no valores.

### 🔴 Blocking

**F2-B1 — El hook de daño del Pilar 2 no tiene dueño (detectado por 2A-consistencia-C2/D4 y 2B-semántica-B1).**
`effective_attack_damage()` aparece **11× en `reliquias-bendiciones.md`, 0× en `combate-dano.md`**. El `CombatProfile` de Combate es estrictamente **por tipo** (F1 lee un `attack_damage` estático); no existe capa de modificador de instancia en ninguna parte. El peor caso que la propia Reliquias computa (`25 → 79` con 3 Legendarias ofensivas, F-RB1) **no puede fluir por la fórmula de daño de Combate tal como está escrita**. El registro lo anota `source: reliquias / referenced_by: combate # PROVISIONAL`, pero es aspiracional — el modelo de tuning de Combate (solo-por-tipo, explícito en sus Tuning Knobs) lo contradice. **Requiere un ADR que decida quién posee la capa de instancia antes de implementar cualquiera de los dos sistemas.** OQ-RB1 abierta.

**F2-B2 — Dos GDDs *Approved* especifican superficies de API opuestas (2A-C1).**
Forja dice que #12 y #14 *exponen* `get_relic_combat_inputs()` / `list_relics()`; Reliquias dice que **Forja** los expone y #12 los *llama*. Ambos son read-hooks sobre el registro `RelicRecord` de Forja (la lectura de Reliquias es la coherente), pero el diseño de check estático de CI de Forja está construido sobre su versión invertida. Hay que elegir un dueño.

**F2-B3 — Reliquias es huérfana en el wiring de ≥5 vecinos (2A-A1, confirma OQ-RB3).**
Reliquias reclama 7 dependencias upstream; **5 filas recíprocas de dependiente faltan genuinamente** — Temporizador, Tropas, Héroes, Guardado y Datos de Era nunca la reconocen. La mitad de `systems-index.md` (tabla de enumeración) ya está bien; faltan solo las filas del lado GDD. Verbatim de las filas a reciprocar: Reliquias L249–253.

**F2-B4 — La arista Reliquias↔Permadeath no está declarada en ninguna tabla, y nadie posee el reloj `offering_time_scale` (2A-A2/D2, 2B-W3).**
La precedencia de pausa Permadeath (`game_time_paused`, stop total) sobre la cámara lenta de la oferta (`offering_time_scale`, nunca pausa) está escrita solo en OQ-RB9 de Reliquias, no en Reglas, y su propio texto dice que "bloquea la implementación". La lista de consumidores de `game_time_paused` de Permadeath Regla 4 nombra solo Combate y Kaiju — **no Reliquias**. Y `offering_time_scale` no tiene dueño: Reliquias OQ-RB9 admite que "solicita" pero "no posee" el reloj de simulación; ningún otro GDD lo reclama; no está en `entities.yaml`. Ver también Fase 4 S2/S6.

**F2-B5 — `band_headroom` / tope de ejército indefinido + colisión de faucets de refuerzo (2A-D3, 2B-W4).**
La bendición `rally` y su UI RU-3b dependen de un concepto de capacidad de banda que **no existe** en Tropas ni Datos de Era (grep: cero matches). El único concepto adyacente, `max_reinforcements_[tipo]`, está scopeado a reclutamiento por-tipo en fase PREPARATION — pero `rally` es solo-CLIMAX. Además `rally_reinforce_base` (Reliquias) y `reinforcement_ratio` (Tropas) son dos faucets a la misma banda sin reconciliación. Ver Fase 4 S5.

**F2-B6 — El "Dependency Map" de `systems-index.md` contradice su propia tabla de enumeración (2A-A7).**
Mismo archivo, dos secciones, dos grafos: el Map omite Datos-de-Era de Permadeath, 5 deps de Reliquias, Permadeath de Kaiju, etc. — 8 sistemas afectados. Y "Circular Dependencies: ninguna encontrada" no está soportado (≥5 pares se auto-describen `Dura (bidireccional)`). Un arquitecto no puede saber cuál grafo es autoritativo.

**F2-B7 — Batch de "sin GDD / bloqueado" stale que gatea ACs vivas (2A-2c).**
Numerosos marcadores "sin GDD" ahora son **factualmente falsos** y dejan ACs mockeadas que deberían estar desbloqueadas: Forja↔Reliquias (AC-FL19, OQ-FL2), Permadeath↔Forja (AC-P16, OQ-P3), Combate↔Permadeath (AC-C52/C42), Héroes/Tropas/Kaiju/Temporizador↔UI-HUD, y varias filas de dep bidireccionales. `encuentro-con-kaiju.md` L306 y `ui-hud.md` L167 **ya diagnosticaron su propia obsolescencia y el fix nunca corrió**. Mecánico de arreglar, pero gatea ACs → resolver antes de arquitectura. Lista completa: 2A sección 2c (15 ítems blocking + ~15 warning). *(NO flaggear: referencias a Panteón #14, Transición #15, Audio #16, Narrativa #17, Accesibilidad #18 como "sin GDD" — verificadas correctas, deben quedarse.)*

### ⚠️ Warnings / Concerns

- **F2-W1 — Ancla defensiva se rompe bajo Furia (2B-C3).** La garantía "Legendaria defensiva compra estrictamente >1 golpe de kaiju": +68 ÷ 68 (daño Furia) = **exactamente 1.0**, viola el invariante. Ninguno de los dos docs se cruza con el otro.
- **F2-W2 — `kaiju_max_health` indefinido en todo el corpus (2B-C4, ya OQ-1 de Kaiju).** No se puede evaluar si bendiciones apiladas trivializan la victoria de era. Mantener abierto hasta autorar `kaiju_definition.max_health`.
- **F2-W3 — Combate Regla 5 es silente sobre Furia (2B-W1).** Kaiju llama a la escala de Furia "la única excepción documentada de Combate Regla 5", pero Combate nunca la menciona (a diferencia de la excepción de leash, documentada en ambos lados). Igual para el carve-out de expiración de buff (F-RB4) fuera de `apply_damage`.
- **F2-W4 — `game_time_paused` nunca llega al Temporizador (2B-W2, OQ-P4 abierta).** Impacto estrecho (el reloj de acercamiento ya está congelado en CLIMAX) pero es una brecha auto-reconocida.
- **F2-W5 — `camera_pan_speed`/`zoom_min`/`zoom_max`: definidos como knobs en `input.md`, pero el registro + 4 docs dicen que Datos de Era los posee — y Datos de Era no define ninguno (2A-D1).** El rango `zoom_max` de Input (→2.0) excede el dominio [0.5,1.5] documentado de las fórmulas de transformación de UI-HUD/Control.
- **F2-W6 — Indicador de guardado de UI/HUD huérfano (2A-A3, 2B-W5).** Guardado presupuesta un knob de indicador `SAVING`, pero `ui-hud.md` nunca referencia `SAVING`/"guardado" (0 hits). AC-07 de Guardado tiene blocker stale.
- **F2-W7 — `invocation_charges`/`draw_size`/`pool_cap`: knob global vs override por-era sin resolver (2A-D5, OQ-RB4).** Declarados como knobs de Reliquias Y candidatos a campos de `EraDefinition`; Datos de Era no los tiene en su schema ni conoce a Reliquias.
- **F2-W8 — Kaiju `attack_damage`/`attack_cooldown_s`: tuneados en Combate, restringidos en Kaiju, invisible desde el lado de tuning (2A-D6, OQ-10 abierta).** El loud-fail al cargar `EraDefinition` (AC-K74) atrapa violaciones, pero la tabla de tuning de Combate no tiene puntero de vuelta.
- **F2-W9 — Deriva menor de wiring:** Héroes coloca 2 sistemas upstream (Temporizador, Encuentro) en su tabla de *dependientes* (2A-A10); AC-H23 cita el rango superseded `0.05–0.15` (correcto: `0.10–0.15` desde 2026-08-17) (2A); filas de dependiente faltantes de bajo impacto: Datos-de-Era←Control (A8), Guardado←Tropas (A9), Datos-de-Era←{Combate (A4), UI-HUD (A5)}; aristas rotas Input→{Reliquias, UI-HUD, Permadeath} (A6, conflicto de dirección con Permadeath).

### ✅ Verificado limpio (Fase 2)

Ownership de la ruta de muerte (Héroes→Permadeath→Forja→Guardado) totalmente reconciliada; Reliquias R10 vs Forja R5 ortogonales (sin contradicción — Forja forja siempre, Reliquias decide *cuándo* es invocable); Furia-(b)-vs-sacrificio **sin contradicción a nivel de regla** (el umbral se recomputa hacia abajo, intencional — el problema es estrategia emergente, ver Fase 4 S7, no inconsistencia); `receive_relic`, cortes de tier `[0.10,0.35)/[0.35,0.70)/[0.70,1.00]`, `base_accidental`=0.10, campos de `RelicRecord`, y ~23 de ~25 símbolos cross-GDD resuelven a un dueño con semántica coincidente. La disciplina anti-duplicación (secciones "knobs que no existen" en Forja/Permadeath/Reliquias) es real y generalizada — F2-B/W son las excepciones, no el patrón. Cadenas de fórmula limpias verificadas: daño/telegrafío de kaiju → histéresis de UI (F1); origen del reloj de Temporizador vs reloj de enrage de Kaiju (secuenciales, sin conflicto); resolución de tick de dos fases de Combate ↔ modelo de expiración F-RB4.

*Nota de fórmula (2B-C1, no es contradicción cross-doc): la banda Tier 1 "Delgada" `[0.10,0.35)` es alcanzable en un solo punto (`0.10` exacto) — el conjunto real de H4 es `{0.10} ∪ [0.40,1.00]`, auto-documentado en FL1. Probablemente intencional (muertes accidentales planas), confirmar antes de que UI/telemetría asuma varianza en Delgada.*

## Cross-System Scenario Issues (Fase 4 — COMPLETA, re-corrida 2026-08-18 sesión limpia)

7 escenarios recorridos (5 pre-identificados + 2 añadidos), agente game-designer, sin truncar. Cada hallazgo cita sistema, paso exacto de falla y la regla/AC que lo cubre o no.

**Escenarios:** S1 death→forge→pool en CLIMAX bajo Regla 10 · S2 `offering_time_scale` × telegrafío del kaiju · S3 expiración de buff defensivo en HP crítico · S4 autosave/reload con estado efímero de invocación · S5 rally en tope de banda · S6 muerte durante un `OFFERING` abierto (añadido) · S7 Furia disparador (b) relajado por la muerte que otorga reliquia (añadido).

### 🔴 Blockers

**S1 — La Regla 10 (el pool excluye muertes intra-era) no tiene mecanismo implementable.** El contrato de lectura declarado de Reliquias (Regla 1) **omite `origin_era_id`** de los campos que consume del `RelicRecord`, y F-RB5 (`active_pool_size = min(total_relics_forged, pool_cap)`) nunca filtra por era. La regla que resolvió el B1 de la corrida previa es inimplementable como está escrita. Alcanzable cada vez que un héroe muere en CLIMAX. Sin señal de HUD de que la reliquia recién forjada está inerte esta era (→ Warning S1).

**S2 — Ownership/mecanismo de `offering_time_scale` es un Open Question (OQ-RB9) dentro de un GDD Approved.** Ningún doc dice si el reloj de cooldown/tick de daño de Combate lo respeta; la tabla de Interactions de Combate solo nombra `game_time_paused`. Dos implementaciones divergentes sin adjudicar (global `Engine.time_scale` ralentiza el reloj de Furia de Kaiju; multiplicador solo-unidades hace que tus tropas hiper-ataquen a un kaiju al ralentí). **Loop de stalling no acotado:** abrir la oferta es gratis (commit-on-choice), así abrir→cancelar→cooldown 3s→reabrir da cámara lenta 0.2× casi continua toda la CLIMAX; si ralentiza `climax_elapsed_s` también estanca el temporizador anti-turtle de Furia (a). Ni Reliquias ni Kaiju lo tratan en Edge Cases.

**S4 — La tabla de Interactions Approved de Guardado omite Reliquias por completo.** Persistencia de cargas gastadas, modificadores activos y estado de `OFFERING` marcados como "contrato a coordinar" (sin resolver). Alcanzable en cualquier crash/quit mid-CLIMAX tras gastar una carga: el default (hasta que un implementador lo note) **refunda la carga**, revirtiendo la decisión anti-abuso explícita ("cargas gastadas NO se devuelven"). **Segundo blocker:** `expiry_tick` de F-RB4 es relativo a un contador de tick de física que resetea en recarga, **sin contrato de rebasing** → el modificador resucita como permanente, o expira inmediatamente.

**S5 — `band_headroom` / tope total de ejército indefinido.** Concepto load-bearing para una mecánica Approved (`rally`, RU-3b) que no existe en Tropas ni Datos de Era (grep: cero). Ver F2-B5.

**S6 — La precedencia pausa-Permadeath-vs-slow-mo-`OFFERING` es un Open Question, no una regla ratificada.** OQ-RB9 la esboza pero dice que "bloquea la implementación". Permadeath Regla 4 (dueño canónico de `game_time_paused`) lista solo Combate y Kaiju — Reliquias ausente. **Segundo blocker:** ningún doc especifica el mecanismo de máquina de estados para "preservar" la oferta durante la pausa (¿`offering_soft_timeout_s` sondea `game_time_paused`? ¿`offering_time_scale` se sobreescribe a 0?). **Tercer blocker (compuesto):** si el objetivo de la bendición en vuelo es el héroe que murió, la resolución difiere a un *segundo* OQ (OQ-RB7) — sobre un mecanismo de selección de objetivo de bendición single-hero que Reliquias nunca especifica.

**S7 — Alcance de congelamiento ambiguo para la ventana de desenganche de Furia durante `DEATH_HOLD`.** Kaiju Regla 11 enumera los relojes congelados durante `game_time_paused` pero **omite `hero_disengage_window_s`** (F5), y Furia se describe como "ortogonal" al ciclo de intención que Regla 11 congela. Si la ventana deslizante sigue avanzando durante un beat multi-muerte comprimido (Permadeath Regla 8), la cadena podría caminar el roster hacia un disparo involuntario de Furia con cero agencia del jugador — lo opuesto a lo que una mecánica anti-turtle "el jugador eligió desenganchar" debe castigar.

### ⚠️ Warnings

- **S1** — Sin señal de UI de que una reliquia recién forjada está inerte esta era (el contrato RU-1..RU-4 solo expone cargas/oferta/activas).
- **S5** — "Carga gastada para efecto cero" sigue siendo riesgo real incluso una vez definido `band_headroom`, porque la única salvaguarda es un pre-aviso de UI (RU-3b) gateado en una cantidad indefinida, y el recurso desperdiciado carga peso emocional (Pilar 1/2).
- **S7 — Estrategia dominante emergente (cara de escenario del B3 de la corrida previa, aún solo trackeada como OQ-15 sin aplicar):** sacrificar deliberadamente un héroe desenganchado (idealmente con `D=1`, que además maximiza `relic_quality`) para relajar `required_engaged_heroes` del roster sobreviviente y comprar espacio de turtle — el loophole exacto que el comentario de Kaiju Regla 10b intenta prevenir, no flaggeado como tradeoff aceptado.

### ℹ️ Info

- **S1** — Mismatch de estado de doc: Combate Edge Cases aún describen el contrato `game_time_paused` como "a confirmar", mientras Permadeath Regla 4 lo trata como satisfecho vía AC-C52 (convergen en la misma conducta).
- **S3 — Expiración de buff defensivo "nunca mata" está formula-verificada verdadera** (`min(current_health, new_max_health)` con `base_stat ≥ 1` no puede producir ≤0). El `time_to_death` de Kaiju (F2, snapshot en telegrafío) puede quedar stale tras un clamp de expiración mid-telegraph, pero el readout visible (`danger_time_s`, UI-HUD F1) se auto-corrige vía su término de HP en vivo — la garantía "nunca emboscar" se sostiene, aunque esa compensación nunca se declara intencional.
- **S3/S4** — El clamp de expiración (F-RB4) bypassa la autoridad única de `apply_damage` de Combate Regla 1 — excepción deliberada del lado de Reliquias, no cross-reconocida en Combate (ver F2-W3).
- **S4** — Perder un `OFFERING` en progreso (draw mostrado, sin pick) en crash/reload es baja severidad (ninguna carga gastada aún) pero no descrito como conducta esperada.

### Brechas adyacentes no expandidas (para una futura pasada)
(a) Si el targeting de bendición single-hero ofensiva/defensiva es elegido por el jugador o auto-seleccionado (surgió en S6). (b) Interacción entre el freeze de Kaiju Regla 11 y el contrato de pausa de cooldown de Combate cuando un beat `DEATH_HOLD` y una ventana `STAGGERED` están activos simultáneamente (adyacente a S1).

---

## GDDs Flagged for Revision (consolidado Fase 2 + 3 + 4)

| GDD | Razón (id de hallazgo) | Tipo | Prioridad |
|-----|--------|------|----------|
| reliquias-bendiciones.md | F2-B1 (effective_attack_damage), F2-B3 (5 filas de dep faltan), F2-B4 (arista Permadeath + owner de offering_time_scale), F2-B5 (rally/band cap), S1 (mecanismo Regla 10), S4 (persistencia), S6 (muerte durante OFFERING + targeting); Fase 3 B1/B4/W1/W6 | Consistency+Design | Blocking |
| combate-dano.md | F2-B1 (capa de instancia / hook effective_attack_damage), F2-W3 (silente sobre Furia + carve-out de expiración), F2-B7 (residuo "sin GDD") | Consistency | Blocking |
| guardado-persistencia.md | S4 (tabla de Interactions omite Reliquias; contrato de rebasing de tick), F2-W6 (AC-07 stale) | Consistency | Blocking |
| forja-de-legado.md | F2-B2 (conflicto de superficie de API get_relic_combat_inputs/list_relics), F2-B7 (residuo #12) | Consistency | Blocking |
| encuentro-con-kaiju.md | S7 (alcance de freeze de ventana de Furia), F2-W1 (ancla defensiva bajo Furia), F2-W2 (kaiju_max_health), S7-W (loophole de sacrificio = OQ-15); Fase 3 B3 | Design+Consistency | Blocking |
| permadeath.md | F2-B4 (Regla 4 debe listar Reliquias), F2-W4 (game_time_paused→Temporizador, OQ-P4), F2-B7 (etiquetas stale); Fase 3 W6 | Consistency | Blocking |
| systems-index.md | F2-B6 (Dependency Map contradice tabla de enumeración; "sin circulares" no soportado; estado de Permadeath) | Consistency | Blocking |
| game-concept.md | Fase 3 B1/B5 (RESUELTOS en adenda — mantener flag hasta re-verificar) | Design | Resuelto/verificar |
| sistema-de-tropas.md | F2-B5 (tope de banda/rally), F2-B3 (fila de dep de Reliquias), F2-B7 (residuo) | Consistency | Warning |
| datos-de-era-civilizacion.md | F2-W5 (ownership de knobs de cámara/zoom), F2-W7 (cargas por-era), F2-W9 (filas de dependiente faltantes) | Consistency | Warning |
| ui-hud.md | F2-W6 (indicador de guardado huérfano), F2-W9 (ruteo de active_input_method), F2-B7 (etiquetas stale); Fase 3 B2 (overload OQ-U8 → /ux-design) | Consistency | Warning |
| input.md | F2-W5 (knobs de cámara/zoom vs dueño del registro), F2-W9 (3 aristas downstream rotas) | Consistency | Warning |
| sistema-de-heroes.md | F2-W9 (2 sistemas upstream en tabla de dependientes; rango stale 0.05–0.15 en AC-H23; residuo) | Consistency | Warning |

---

## Verdict: FAIL

**Ahora con los 3 pases completos** (Fase 2 consistencia + Fase 3 holismo + Fase 4 escenarios). ~8 clústeres de causa raíz bloqueantes; la mayoría traza a que `reliquias-bendiciones.md` (#12) fue cableada al corpus *después* de que sus vecinos se congelaron, y su hook de daño nunca se aterrizó en Combate.

**Dos son decisiones de arquitectura, no limpieza de docs** — requieren ADR antes de `/create-architecture`:
1. **F2-B1** — quién posee la capa de modificador de instancia que `effective_attack_damage` necesita (Combate solo-por-tipo vs Reliquias). Detectado por los dos agentes de consistencia independientemente y confirmado por Fase 4.
2. **F2-B4 / S2** — quién posee y aplica el reloj `offering_time_scale`, y su interacción con `game_time_paused` de Permadeath y el tick fijo de física.

**El resto es reconciliación de Reliquias que nunca corrió tras aprobar #12**: 5 filas de dep recíprocas (F2-B3), tabla de Guardado (S4), mecanismo de Regla 10 (S1), tope de banda para rally (F2-B5), muerte durante OFFERING (S6), y el batch de residuo "sin GDD" que gatea ACs (F2-B7). Más el auto-contradictorio Dependency Map del índice (F2-B6) y el alcance de freeze de Furia (S7).

**No avanzar a `/create-architecture`.** Orden sugerido: (1) triar F2-B1 y F2-B4/S2 con el usuario → ADRs; (2) reconciliación de wiring de Reliquias (F2-B3/B7, S4, S6) — mecánico, alto volumen, mejor en su propia sesión; (3) F2-B5/S5, S1, S7 — decisiones de diseño acotadas; (4) re-verificar B1/B5 de Fase 3 (adenda) siguen sostenidos. Fase 3 no se re-corrió esta pasada (su holismo sigue vigente + adenda de resolución de la misma fecha).

---

## Adenda de Resolución (2026-08-18, misma sesión — decisiones del usuario aplicadas)

- **B1 — RESUELTO (reencuadre de hipótesis MVP).** `game-concept.md` MVP Definition reescrita: el MVP valida la *producción* de reliquias (permadeath→forja de muertes presenciadas, in-era) y el *feel de invocación* (con panteón pre-sembrado) **por separado**; la unión cross-era ("usar tu propia muerte presenciada") se difiere al Vertical Slice. Coherente con la Regla 10 de Reliquias y con el onboarding del concepto. Contradicción cerrada.
- **B5 — RESUELTO (reencuadre del lenguaje del hook).** `game-concept.md` Unique Hook + Core Mechanic #2 reescritos: el poder refleja "quién fue y cómo cayó" (rol → tipo de bendición; calidad de la muerte → potencia), no "exactamente cómo murió". Nota de fidelidad Pilar 2 añadida. Se acepta el split categoría-autorada / tier-derivado como diseño.
- **B2 — PARCIAL (fix concreto aplicado; overload de fondo diferido).** `ui-hud.md` reconciliado: filas de dependencia de Reliquias des-stale-adas (era "sin GDD"), AC-U30 desbloqueada, OQ-U4 resuelta. OQ-U8 (overload del HUD de CLIMAX) explícitamente marcada para **re-contar el draft** como stream activo → queda para `/ux-design` del overlay de invocación (ya flageado en el UX Flag de Reliquias).
- **B3/B4 — PARCIAL (reencuadre aplicado; guard de Furia propuesto, no mutado).** Retórica "finitas/no farmeables" reencuadrada en `reliquias-bendiciones.md` (panteón = colección que crece; lo escaso son las cargas/era) y en `game-concept.md`. Interacción farmeo × Furia(b) documentada como **OQ-15 en `encuentro-con-kaiju.md`** con guard preciso propuesto (una muerte D=1 no relaja `required_engaged_heroes`) — **no aplicado a la fórmula F5** para no regresionar AC-K63c/d/e sin la validación de escenario (Fase 4). Cotas existentes documentadas: disparador (a) time-cap roster-independiente + gating de `relic_quality`.
- **W6 — RESUELTO (contrato de precedencia).** `reliquias-bendiciones.md` OQ-RB9 ampliada: si un héroe muere durante `OFFERING`, la pausa total de Permadeath (`game_time_paused`) tiene precedencia sobre `offering_time_scale`; la oferta se preserva y reanuda. Permadeath añadido a la lista de coordinación.

**Estado post-adenda:** B1/B5/W6 cerrados; B2/B3 con fix parcial + deferral explícito; **Fase 2 (consistencia completa) y Fase 4 (escenarios) siguen pendientes de re-correr en sesión limpia**. El veredicto FAIL se mantiene hasta ese re-run — no avanzar a `/create-architecture` antes.
