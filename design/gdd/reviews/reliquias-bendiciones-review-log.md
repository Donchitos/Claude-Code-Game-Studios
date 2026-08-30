# Review Log — Reliquias/Bendiciones (#12)

Historial de revisiones de `design/gdd/reliquias-bendiciones.md`. Cada entrada registra veredicto, alcance y hallazgos clave para que las re-reviews puedan rastrear qué cambió.

---

## Review — 2026-08-18 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: game-designer, systems-designer, economy-designer, qa-lead, ux-designer, audio-director + creative-director (síntesis senior)
Blocking items: 7 | Recommended: 9 | Nice-to-have: 4
Prior verdict resolved: First review

**Resumen (síntesis creative-director):** El andamiaje mecánico es sólido —disciplina de fuente-de-verdad, RNG determinista, invariantes loud-fail, tick math correcto, desbloquea 4 contratos downstream— pero la entrega de la Player Fantasy (la razón de ser del sistema, un eje del Pilar 2) no se cumplía en la capa mecánica. Tres bloqueantes elevados a co-blocking por el senior: (1) stacking sin cap → burst 25→79; (2) drafteo intra-era que contradecía el tono trágico y el onboarding del concepto; (3) gap de entrega de fantasía (9 combos categoría×tier + epitafio de plantilla = "drop genérico con nombre", agravado por el draft en tiempo real ilegible bajo presión de kaiju). Convergencia más fuerte: **stacking sin cap**, hallado independientemente por game-designer, economy-designer y systems-designer. El senior bajó 2 hallazgos: pool_cap como "dead config MVP" (es higiene forward-scoped, no defecto) y colisión de vocabulario coral de audio (arbitraje de mezcla en producción, no gate de diseño).

**7 bloqueantes (todos aplicados el 2026-08-18 en la misma sesión):**
1. Stacking sin cap → **F-RB1 refresh-on-repick por `(relic_id, unit)`** + cota worst-case computable (AC-RB31/RB31b, AC-RB27 re-keyeado).
2. Categorías no cross-ancladas → reglas de **anclaje cross-categoría** en Formulas + validación de dominancia en OQ-RB8(d).
3. Fantasía no entregada → **identidad glanceable** (retrato/silueta + nombre) como canal primario (RV-2/RU-3); nota de individuación honesta; **OQ-RB10** enruta individuación más profunda a Forja.
4. Drafteo intra-era → **Regla 10** (pool solo de eras previas, nunca same-fight; MVP pre-siembra un panteón de prueba); **OQ-RB5 resuelto** (política fijada).
5. OFFERING vs. control de unidades sin especificar → **Regla 7b cámara lenta** (`offering_time_scale` 0.2×, unidades vivas, sin emboscada); commit-on-choice + soft-timeout + cooldown; 3 knobs nuevos; cascada a Regla 6, tabla de estados, AC-RB15/15b.
6. AC-RB13 dependencia oculta del hook no confirmado de Combate → acotado a `effective_stat`; integración diferida a AC-RB32 (ya bloqueado).
7. AC-RB22 sin barra estadística → concreto: N=1000 sorteos, semillas fijas [1..1000], 0 violaciones.

**Fixes de soporte también aplicados:** RU-2b (`first_invocation_available` onboarding), RU-3b (`band_headroom` para evitar el trap de rally-whiff sin aviso). Registry (`effective_attack_damage`) re-sincronizado con la nueva regla de stacking.

**Recomendados NO aplicados (para re-review/backlog):** AC-RB38b (race de retiro mid-OFFERING), AC-RB40b (relleno parcial de rally), invariante F-RB2 con paso mínimo perceptible (no solo `>`), F-RB5 accounting de reliquias withdrawn-for-offer vs. pool_cap, split AC-RB18/RB23, arbitraje de ducking de audio vs. telegrafío (OQ), motivo de audio por tier.

**Decisiones de diseño del usuario (AskUserQuestion 2026-08-18):** pre-seed sin same-fight relics; one-instance-per-relic_id refresh; slow-mo durante OFFERING; anclaje cross-categoría + defer rally.

**Nuevas Open Questions:** OQ-RB9 (propiedad del mecanismo de escala de tiempo global durante OFFERING), OQ-RB10 (individuación de reliquias más allá de categoría×tier, coordinación con Forja).

**Estado:** revisión aplicada y **aceptada por el usuario como Approved el 2026-08-18 sin re-review adversarial** (decisión explícita del usuario: "marcalo como approved, debemos avanzar"). Salvedad registrada: 3 de los 7 fixes tocaron diseño no trivial (modelo de stacking refresh-on-repick, cascada de charge-timing por la cámara lenta, anclaje cross-categoría) y no fueron verificados por una re-review de especialistas. Los recomendados no aplicados (AC-RB38b, AC-RB40b, invariante F-RB2 con paso mínimo, F-RB5 accounting withdrawn-for-offer, split AC-RB18/RB23, arbitraje de audio) y la detección de regresiones quedan diferidos a `/consistency-check` + `/review-all-gdds` antes de arquitectura.
