# Review Log — Encuentro con Kaiju

Historial de revisiones de diseño de `design/gdd/encuentro-con-kaiju.md`.

## Review — 2026-08-11 — Verdict: MAJOR REVISION NEEDED
Scope signal: L–XL
Specialists: game-designer, systems-designer, ai-programmer, qa-lead, level-designer, godot-specialist, ux-designer, creative-director (síntesis senior)
Blocking items: 9 | Recommended: 7 | Disagreements adjudicados: 2
Prior verdict resolved: First review

**Resumen (síntesis del creative-director)**: La artesanía del documento es fuerte (ciclo de intención, marcado-vía-telegrafío, disciplina de contratos cross-sistema), pero tres de los cuatro pilares tenían un hueco bloqueante y había un riesgo de integridad cross-GDD. Verdict estructural, no de pulido; los arreglos son aditivos.

**9 items bloqueantes identificados:**
1. [game-designer] El exploit de matar solo con tropas esquiva el Pilar 1 (los héroes son la única condición de derrota pero nada obliga a arriesgarlos).
2. [systems-designer] Los stats "locked" del kaiju (`attack_damage=45`/`attack_cooldown_s=4.5`) NO están locked en Combate/Daño — son knobs tunables; AC-H29 (~30s) depende de ellos sin trigger de re-verificación.
3. [ux/level/systems] `time_to_death` proyecta contando solo el kaiju; daño de esbirros simultáneo lo vuelve silenciosamente erróneo en la dirección fatal (viola Pilar 4).
4. [level-designer] Acumulación no acotada de esbirros (hasta 48, sin despawn/cap) + sin cota de duración del clímax (Temporizador OQ-4 se difirió aquí y quedó sin responder).
5. [systems-designer] El borde del rango seguro de F4 rompe la propiedad "una tropa sola no neutraliza" (acoplamiento `neutralize_hits_equivalent × telegraph_duration_s` no documentado).
6. [systems-designer] La derivación `telegraph_duration_s ≥ 12.0s` de F2 no es robusta frente al rango de HP válido de Héroes `[120,200]` (un héroe de 120 HP rompe AC-H29).
7. [ai-programmer] El auto-ataque del FSM base de Combate/Daño nunca se suprime durante el telegrafío (el kaiju golpearía antes/durante su propio telegrafío).
8. [ai-programmer] La tabla States and Transitions omite la transición de telegrafío cancelado (objetivo muerto/fuera de rango) que Edge Cases/AC-K06/K46 exigen.
9. [qa-lead] Los mocks de AC-K58/K59 no prueban sus contratos documentados (falta `time_to_death` en el payload; falta parámetro de tercio para KA-1).

**Desacuerdos adjudicados por el usuario (2026-08-11):**
- Screening de tropas: NO es una capa táctica del MVP (retirada binaria intencional; "el kaiju viene por ti"). Revisar tras playtest (OQ-8).
- Ventana de telegrafío (¿demasiado fácil vs. demasiado corta?): diferido a tuneo de playtest; piso de aviso fiable fijado en el tercio 2 + canal numérico desde el frame 1 (nota KV-1).

**Decisiones de diseño elegidas (recomendadas):**
- Anti-turtle + cota de duración → **Furia/enrage** (Regla 10, F5): dispara por tiempo (`enrage_time_threshold_s=150`) o por desenganche de héroes (`hero_disengage_window_s=15`); escala telegrafío y daño; latcheada.
- Honestidad de daño → **`incoming_damage_rate_total`** (Regla 6b, F6): expone DPS combinado de todas las fuentes; el readout de Héroes refleja la fuente más peligrosa.
- Concurrencia de esbirros → **`max_concurrent_esbirros`** (Regla 8b): las oleadas debidas se difieren al llegar al cap.

**Revisión aplicada en la misma sesión (todos los bloqueantes + recomendados):** Reglas 4 (gate de ataque)/6b/8b/10 nuevas; F5/F6 nuevas; ACs añadidos AC-K61–K73; AC-K01/K05/K14/K17 divididos; AC-K58/K59 mocks enriquecidos; F1 algoritmo de ventana deslizante; RNG inyectable + framerate-independencia (AC-K70/K71); nota `@export_range` (loud-fail, no clamp); KV-9/KA-6 (Furia); reencuadre de stats "locked" (F2) + OQ-10/OQ-11/OQ-12; OQ-3 resuelto.

**Nota cross-GDD pendiente para el re-review / consistency-check:**
- OQ-10: formalizar el lock o trigger de re-verificación de `attack_damage`/`attack_cooldown_s` del kaiju en `combate-dano.md` (no editado en esta sesión — manejado como constraint documentado en este GDD).
- OQ-4 (acción Phase 5 original): des-flaggear las notas "Encuentro con Kaiju sin GDD" en Combate/Daño y Héroes y re-verificar sus mocks contra el contrato real.

**Estado tras la revisión:** GDD revisado, `Status: In Design (pendiente re-review)`. systems-index.md sin cambios (sigue "Designed", no "Approved") — a la espera de un re-review con contexto limpio (7 agentes).

## Review — 2026-08-12 — Verdict: NEEDS REVISION → revisado en la misma sesión
Scope signal: L (sistema); M (la revisión)
Specialists: game-designer, systems-designer, ai-programmer, qa-lead, level-designer, godot-specialist, ux-designer, creative-director (síntesis senior)
Blocking items: 6 | Recommended: 8 | Prior verdict resolved: No (parcial — ver abajo)

**Resumen (síntesis del creative-director)**: Doc genuinamente mejorado — 5 de los 9 items previos sólidamente cerrados y la disciplina de AC es la más fuerte del proyecto — pero 4 especialistas encontraron cada uno un bloqueante de *coherencia* (no de pulido), más 2 semi-bloqueantes. Meta-patrón central: los "arreglos" previos de los items 4/5/6 **reetiquetaron** huecos como "riesgo de disciplina de autor" en prosa en lugar de cerrarlos con el loud-fail que este GDD exige en todas partes — y 2 de esos 3 eran *computables*, así que declinar enforcement era el problema real. qa-lead habría aprobado (revisa testabilidad, no coherencia).

**6 items bloqueantes identificados (y resueltos en la misma sesión):**
1. [ai-programmer] Contradicción del golpe de `STRIKING` vs. piso de adquisición del FSM base de Combate/Daño (el primer golpe se retrasaría un cooldown o saltaría el gate sin documentar). → Override explícito en Regla 4 + tabla de estados + AC-K75.
2. [systems-designer] La garantía ≥30s (F2/AC-H29) se rompe con valores individualmente válidos de dos GDDs Approved (`telegraph_duration_s=14.0` default + `hero_max_health=120`); enforcement era solo prosa. → Loud-fail obligatorio al cargar `EraDefinition` (OQ-11 resuelto) + AC-K74.
3. [systems-designer] Falso positivo del disparador (b) de Furia en el piso `hero_disengage_window_s=8` (retirada táctica legítima latchea Furia). → Piso subido 8→15 + edge case + AC-K63d.
4. [level-designer] El enrage es escalada, no cota de duración; la duración total del clímax sigue sin techo. → Corregida la afirmación imprecisa; cota dura total **aceptada conscientemente como riesgo documentado post-MVP** (decisión del usuario, OQ-12).
5. [game-designer] El disparador (b) permitía "héroe-cebo único" (cumple la letra del anti-turtle, rompe el Pilar 1). → Disparador consciente del roster + knob `hero_engagement_fraction` (decisión del usuario) + AC-K63/K63b/K63c.
6. [ux-designer] KV-1 apoyaba la garantía de Pilar 4 en un número del HUD; faltaba límite de fotosensibilidad y contrato de cancelación. → KA-1 tercio-1 como backstop diegético + KV-10 (flash-rate) + KU-1 (razón de cancelación).

**Decisiones del usuario (2026-08-12):** (a) Furia anti-cebo → disparador consciente del roster; (b) cota de duración → aceptar como riesgo documentado post-MVP; (c) piso de desenganche → subir a 15s.

**Recomendados aplicados:** `_validate_property`→setter custom/`validate()` (godot-specialist, prerrequisito de los loud-fail); polling directo para el gate de dos FSM; reencuadre de copy de `P` defensiva (Player Fantasy — no hay redirect vivo del kaiju); F6 rama `kaiju_projected_dps=0` (edge case + AC-K78); AC-K76 (framerate de ventana F1 + contador de neutralización); AC-K77 (timing de tercios, mueve el "medio timing" de Pilar 4 a gate blocking); techo de `max_concurrent_esbirros` 24→16 recomendado; regla de autoría `first_wave_delay_s ≥ telegraph_duration_s`; OQ-13/OQ-14 (audio tercio-1 / histéresis dual).

**No accionados (pertenecen a otros docs):** OQ-10 (formalizar lock/trigger de los stats del kaiju en `combate-dano.md`); des-flaggeo cross-GDD de notas "sin GDD" stale en Combate/Héroes/Temporizador (acción de OQ-4).

**Estado tras la revisión:** GDD revisado a 2026-08-12, `Status: In Design (pendiente re-review con contexto limpio)`. systems-index.md sin cambios (sigue "Designed"). Próximo paso recomendado por el usuario: **re-review en sesión nueva tras `/clear`** (7 agentes, contexto limpio) → si pasa, marcar Approved.

## Review — 2026-08-12 (3er re-review) — Verdict: NEEDS REVISION → revisado en la misma sesión → ACEPTADO como Approved
Scope signal: M (revisión); L del sistema
Specialists: game-designer, systems-designer, ai-programmer, qa-lead, level-designer, godot-specialist, ux-designer, creative-director (síntesis senior)
Blocking items: 4 (consolidados de 7 findings bloqueantes de especialistas) | Recommended: ~11 | Prior verdict resolved: Sí (los 6 del round 2 se sostienen; estos son nuevos)

**Resumen (síntesis del creative-director)**: El doc mejoró, pero el meta-patrón del round 2 recurrió — gaps *computables* dejados como prosa de disciplina de autor en lugar de cerrarse con el loud-fail que el doc exige en todas partes — y, peor, el *mecanismo* de loud-fail estaba roto. "Una loud-fail doctrine que compila a silencio en release es peor que ninguna: fabrica falsa confianza." Bloqueante de coherencia, no de pulido. Todos cerrables en sesión salvo la pregunta de identidad de diseño (Furia vs. fantasía), que el usuario resolvió reconciliando la prosa.

**4 bloqueantes (consolidados) — resueltos en la misma sesión:**
1. [godot-specialist] `assert()` es no-op en builds exportados → toda la loud-fail doctrine no validaba en release. → Reemplazado doc-wide por `push_error()` + halt explícito (con ejemplo de código); centralizar carga de era.
2. [qa-lead + systems-designer] Patrón recurrente: (a) 6 de 10 loud-fail configs sin AC → AC-K79–K84; (b) acoplamiento F4×F2 solo-prosa mientras su gemelo F2×HP-héroe tenía AC-K74 → enforced como loud-fail cross-resource (AC-K85), corregido min→max troop DPS, con flag de excepción `allow_single_troop_neutralize`.
3. [systems-designer] Furia (b) degeneraba en N=2 con el default f=0.5 (`ceil(0.5×2)=1`, cebo único evadía) → fórmula a `floor(f×N)+1` (>N/2 en default), dominio estrechado `(0,1]`→`[0.34,1.0]`, AC-K63/b/c/d actualizados + AC-K86.
4. [ai-programmer] Cluster de determinismo: `entity_id` indefinido (si es `get_instance_id()` no es reproducible), cita errónea a AC-C06 (no tiene cláusula de empate), doble `apply_damage` en el frame de `STRIKING`, race de prioridad de victoria. → `entity_id` definido como contador de spawn estable; cita corregida; kaiju excluido del bucle de auto-ataque base (dueño único de `apply_damage`) + abort síncrono tras cruce de 0 (AC-K87/K88); RNG acotada a same-plataforma (AC-K71).

**Decisiones del usuario (2026-08-12):** (a) F4×F2 → enforce loud-fail; (b) N=2 Furia → `>N/2` (floor(f×N)+1); (c) Furia esbirro-collateral + fantasía → exención de esbirros (cuenta daño a kaiju o esbirros, AC-K63e) + reencuadre de Player Fantasy (Furia = presión de tempo, no redirect oculto); (d) KA-1 accesibilidad → canal no-auditivo de tercio 1 (viñeta de borde + rumble, KV-1b/KV-10).

**Desacuerdo adjudicado:** systems-designer marcó AC-K74 como posible bloqueante de computabilidad; verificado contra `datos-de-era-civilizacion.md` que `EraDefinition` anida `unit_roster` (porción de héroes) + `kaiju_definition` y bloquea hasta `LOADED` → es computable; degradado a un doc-gap de una línea (tabla Dependencies actualizada). godot-specialist concurrió.

**Recomendados NO accionados (siguen advisory):** F5×F4 margen de neutralización casi nulo en los pisos de rango; baseline MVP de histéresis de KU-2; separabilidad perceptual KV-9/KV-10; reward hook de esbirros + solape de oleadas en steady-state; medición de `max_concurrent_esbirros`; mock de AC-K58 (forma escalar-vs-mapa). Candidatos a Open Questions / próximo `/ux-design` / playtest.

**No accionados (pertenecen a otros docs):** OQ-10 (lock/trigger de stats del kaiju en `combate-dano.md`); des-flaggeo cross-GDD de notas "sin GDD" stale (OQ-4).

**Estado tras la revisión:** GDD `Status: Approved` (2026-08-12). systems-index.md actualizado a **Approved** (#9); reviewed 3→4, approved 3→4. Aceptado por el usuario sin 4ª pasada de agentes. Recomendación técnica pendiente: `/architecture-decision` para el nodo dueño del ciclo de intención + orden de tick (el GDD ya fija los requisitos duros; el ADR los ejecuta).
