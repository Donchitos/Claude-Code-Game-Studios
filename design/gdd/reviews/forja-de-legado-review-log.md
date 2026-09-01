# Review Log — Forja de Legado

## Review — 2026-08-17 — Verdict: NEEDS REVISION → revisado y aceptado (Approved)
Scope signal: M
Specialists: game-designer, systems-designer, qa-lead, godot-specialist, creative-director (senior)
Blocking items: 2 | Recommended: 8
Prior verdict resolved: First review

**Veredicto del creative-director (síntesis):** documento fuerte, disciplinado y thin-by-design, honesto sobre sus deferrals. Dos ítems bloqueantes tocaban la única garantía que Forja existe para proteger (una muerte → exactamente una reliquia, nunca cero): la clave de dedup podía producir un cero-reliquia silencioso, y la contradicción con el piso de Héroes podía hacer loud-fail en cada muerte accidental. Ambos contract-level, no cosméticos. NEEDS REVISION, no MAJOR.

### Bloqueantes (2) — aplicados
1. **[systems-designer] Clave de dedup insegura.** `(source_hero_id, origin_era_id)` podía tragar una 2ª reliquia legítima porque la unicidad de `hero_id` no estaba especificada en ningún GDD. **Fix:** Regla 8 declara el contrato de instancia única de héroe (no respawn; `DEAD` terminal, Héroes AC-H27b) + nuevo **AC-FL26** (loud-fail si un roster de era tiene `hero_id` duplicado).
2. **[systems-designer] Contradicción cross-GDD del piso.** `base_accidental` de Héroes permitía `0.05` (rango 0.05–0.15); en `D=0` la salida H4 ES `base_accidental`, cayendo bajo el dominio `[0.10,1.00]` de Forja → loud-fail en cada muerte accidental. **Fix (upstream):** rango de `base_accidental` estrechado a **0.10–0.15** en `sistema-de-heroes.md` (2 lugares) + registry `entities.yaml`; nota de reconciliación en Forja Regla 5.

### Recomendados (8) — aplicados
- R1: FL1 gana tolerancia `EPSILON_TIER = 1e-6` para comparar boundaries de floats computados (riesgo real en 0.70, alcanzable vía T≈0.857).
- R2: `relic_id` declarado `String`, único global al legado, estable (Regla 4 + OQ-FL5).
- R3: OQ-FL4 gana 4 ítems de scope obligatorio (mismo-frame/sin-deferred para AC-FL15; `assert()`+`push_error()` activo en release; serialización int64; bloqueo gateado por `await`).
- R4: símbolo de entrada `receive_relic` nombrado para los greps de CI (AC-FL02/FL12/FL18); ruta de módulo diferida a OQ-FL4.
- R5: AC-FL13 reescrito para aseverar membresía en registro (M→M+1), no forma del record (era redundante con FL03/FL08/FL01).
- R6: AC-FL09 inline del producto 3×3 categoría×tier.
- R7: AC-FL24 nombra el seam de inyección (`ActiveEraProvider` stub).
- R8: nota de serialización de `forge_counter` (int64 vía `store_var`/`get_var`, no JSON) en Edge Cases + ADR.

### Corregido en el review mismo
- **"Tier Sólida inalcanzable"** (systems-designer, repetido por el CD): **incorrecto**. Conjunto real de `relic_quality` con constantes MVP = `{0.10} ∪ [0.40, 1.00]`; Sólida `[0.35,0.70)` es alcanzable desde `0.40`. Solo la franja `[0.35,0.40)` no se produce. Documentado como nota informativa en FL1, no bloqueante.

### Disagreements surfaced (adjudicados)
1. **Anti-nihilismo socava stakes** (game-designer vs. CD + pilar lockeado): el CD dictaminó que el pilar se sostiene (stakes viven en tier/héroe nombrado, no existencia-vs-nada); no se revisita. Confirmado por el usuario.
2. **Ownership de "0.35 inalcanzable"** (systems-designer lo enmarcó como Forja; CD lo ruleó como señal de tuning de Héroes): resuelto como corrección numérica (ver arriba) — no era ni de Forja ni realmente un problema.

### Registrado como riesgo/nota (sin cambio de reglas)
- **Pilar 2 diferido** (game-designer): riesgo de programa top-line en el header — el payoff jugable de Forja depende 100% de #12/#14 (sin GDD).
- **Epitaph** (game-designer): documentado el modelo — identidad narrativa única = `hero_name + origin_era_id + relic_category`; `epitaph` es etiqueta terse por diseño.

### Housekeeping
- **OQ-FL1 resuelto**: Forja añadida a Dependientes de Datos de Era; fila de systems-index ya completa.
- Nota de Player Fantasy de modo lean actualizada (creative-director consultado en este review).
