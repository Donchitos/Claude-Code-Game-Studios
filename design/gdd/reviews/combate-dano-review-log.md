# Review Log — Combate/Daño

## Review 1 — 2026-08-09 — Verdict: NEEDS REVISION → fixes aplicados → Approved
Scope signal: L (multi-system integration — Tropas, Héroes, Control, provisional Kaiju/Permadeath; 5 fórmulas; ≥2 ADRs probables — CombatProfile storage OQ-1, mecanismo loud-fail)
Specialists: game-designer, systems-designer, qa-lead, ai-programmer, godot-specialist + creative-director (synthesis)
Blocking items: 5 (todos resueltos en esta sesión) | Recommended: ~11 (diferidos a backlog) | Nice-to-have: ~5

### Hallazgos y resolución
**BLOCKING (5/5 resueltos en esta sesión):**
- **B1 [godot-specialist, promovido a bloqueante por creative-director] — sin garantía de orden para el freeze de D/P "en el mismo frame".** Regla 7/8 depende de que D/P se congelen contra un instante coherente de cruce por 0, pero nada especificaba el orden de resolución dentro de un tick — una implementación ingenua podría disparar `DYING` de un héroe antes de que el golpe letal simultáneo de otro se aplicara, rompiendo en silencio la garantía de mutual-kill (AC-C42). **Fix:** Regla 1 ahora exige resolución en dos fases estrictas por tick — (1) aplicar todo el daño pendiente, (2) solo entonces disparar notificaciones de muerte y computar D/P.
- **B2 [godot-specialist] — loop de combate sin especificar (reproducibilidad de TTK).** Los TTK exactos de F3 (AC-C21–C24) solo son reproducibles si el tick corre en paso fijo; en `_process` serían framerate-dependientes. **Fix:** Regla 1 fija el tick de combate a `_physics_process`; nota de convención en F3 actualizada.
- **B3 [systems-designer] — contradicción AC-C05 vs AC-C43 (cooldown).** AC-C43 (el cooldown persiste tras perder/cambiar objetivo) y AC-C05 (un objetivo recién adquirido siempre espera un cooldown completo) quedaban indefinidos en su intersección — abría un exploit de "banking" de cooldown en `NO_TARGET`. **Fix (resolución de creative-director, confirmada por el usuario):** mecánica de doble compuerta — el cooldown heredado nunca se resetea (compuerta 1) y además se aplica un "piso de adquisición" que nunca permite un golpe antes de un `attack_cooldown_s` completo desde la adquisición (compuerta 2). Regla 3 reescrita; AC-C05/AC-C43 amendadas; **AC-C43b** nueva prueba el exploit directamente.
- **B4 [systems-designer] — invariante F5 no satisfacible para el Kaiju.** Enforcement exigía loud-fail uniforme sobre `attack_range ≤ aggro_range ≤ leash_range`, pero el `leash_range` del Kaiju es un centinela `provisional*` sin valor real — el juego no podía arrancar. **Fix (confirmado por el usuario):** excepción nombrada explícita — F5 no evalúa el tramo `≤ leash_range` del Kaiju mientras sea centinela; el resto del invariante sigue con loud-fail normal. Añadido a Formulas F5, Enforcement, Tuning Knobs y OQ-7; **AC-C27b** nueva prueba el límite de la excepción.
- **B5 [ai-programmer] — "posición de retención" (ancla de leash) sin definir.** Regla 4/AC-C07/AC-C44 medían distancia de leash contra ella sin decir cuándo se fija — afectaba materialmente cuánto puede derivar una unidad de su formación en cadenas de kills. **Fix (confirmado por el usuario):** se fija en el instante de entrada a `TARGET_ACQUIRED`, no se actualiza durante la persecución, y se re-fija en cada nueva adquisición (incluida tras encadenar un kill). Regla 4 y States/Transitions actualizadas; **AC-C07b** nueva la prueba.

**Decisiones del usuario (desbloquearon B3, B4, B5):** las tres resoluciones recomendadas por creative-director/specialists fueron confirmadas explícitamente vía pregunta multi-opción antes de aplicar cualquier edición — doble compuerta para cooldown (no reset-on-switch ni instant-on-stale), excepción nombrada (no valor centinela numérico) para F5/Kaiju, y ancla fija-en-adquisición (no pinned-a-idle ni continuamente actualizada) para el leash.

**Disagreement adjudicado por creative-director:** severidad del riesgo de "mismo frame" — qa-lead lo calificó MINOR/no-bloqueante (nota de test-flakiness); godot-specialist lo calificó IMPORTANT (riesgo de corrección, no solo de test). Creative-director confirmó a godot-specialist y lo promovió a bloqueante (B1) — la garantía de "congelado en ese mismo frame" es la columna mecánica del Pilar 1 en este sistema.

**RECOMMENDED diferidos a backlog (no bloqueantes, no aplicados en esta sesión):**
- [game-designer, adjudicado por creative-director] Sacrificio sin costo hace D=1 trivialmente declarable — escalar a OQ-2 con la restricción explícita "Sacrificio debe llevar un costo de declaración pagado antes de conocer el resultado" (ownership de Control/Permadeath, no de este clasificador). *Aún no aplicado a OQ-2 — pendiente.*
- [systems-designer] Sin cota superior de enforcement para `attack_damage`/DPS.
- [ai-programmer] Desempate de "más cercano" (AC-C06) sin regla determinista para empates exactos.
- [ai-programmer] Stickiness de re-adquisición sin especificar (¿una unidad ya enganchada re-evalúa por un enemigo más cercano que entra en rango?).
- [systems-designer] Ownership de `health_current` como split-brain — merece su propia Open Question, paralela a OQ-1.
- [qa-lead] AC-C-NEG no especifica mecanismo de verificación (schema vs. valor) — riesgo de passing gameable.
- [qa-lead] AC-C33 y la mitad bloqueada de AC-C42 sin Mock Contract Assumptions, a diferencia de sus pares AC-C32/AC-C52.
- [qa-lead] AC-C41 solo prueba rechazo de daño, no el segundo mecanismo del edge case (aliados nunca son objetivo válido de aggro).
- [ai-programmer] Riesgo de `queue_free()` diferido — un objetivo "muerto" podría seguir pasando checks de rango el resto del frame.
- [ai-programmer] Chequeos de leash/aggro/attack puramente por distancia (sin pathfinding) — riesgo de persecuciones rotas visualmente; falta como Open Question.
- [main review] Nota stale en `sistema-de-heroes.md` AC-H21 ("sin GDD" para Combate/Daño) — ya no es precisa, ahora existe este GDD; el bloqueo real es OQ-2 de Control. Fix pertenece a ese archivo, no a este.

**NICE-TO-HAVE (sin aplicar):**
- [ai-programmer] FSM de un-solo-objetivo-por-combatiente sin hook para cleave/AOE futuro del Kaiju.
- [systems-designer] Matriz de TTK implícitamente 1v1, sin advertencia sobre combate grupal.
- Formato de decimales de DPS inconsistente (2 decimales tropas, 1 decimal héroes/kaiju).
- AC-C42 no marcada `(bloqueado)` en la columna Tipo de la tabla de gating, solo en Evidencia.
- Ítem de acción ya completado ("Nota cross-GDD" de HP en `sistema-de-tropas.md`) — ese archivo ya muestra "✅ RESUELTO 2026-08-09".

### Estado final
Verdict: **APPROVED** (tras revisión — usuario aceptó sin re-review completo). `systems-index.md` actualizado (Combate/Daño: Designed → Approved).
Prior verdict resolved: N/A — primera revisión de este documento.
