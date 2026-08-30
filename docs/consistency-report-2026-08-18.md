# Consistency Check Report

**Date:** 2026-08-18
**Registry entries checked:** 4 entities, 1 item, 10 formulas, 10 constants
**Scope:** Focused on the 2026-08-18 design-review revision of `reliquias-bendiciones.md` (stacking model, cámara-lenta knobs, cross-category anchoring) against all 13 system GDDs
**GDDs scanned:** input, datos-de-era-civilizacion, guardado-persistencia, control-y-seleccion-de-unidades, sistema-de-tropas, sistema-de-heroes, temporizador-de-preparacion-ritual, combate-dano, encuentro-con-kaiju, permadeath, forja-de-legado, reliquias-bendiciones, ui-hud

---

## Conflicts Found (must resolve before architecture)

**None.** 🔴 0 conflicts.

---

## Stale Registry Entries (registry behind the GDD)

**None.** The `effective_attack_damage` note was re-synced to the new refresh-on-repick stacking rule during today's revision (registry `last_updated` = 2026-08-18). All other Reliquias-owned registry values were unchanged by the revision.

---

## Verified Clean (Reliquias-owned values cross-checked post-revision)

- ✅ **`invocation_charges` = 3** — registry matches GDD Tuning Knobs; no other GDD states a conflicting value (Datos de Era/UI-HUD listed as `posibles referenciadores`, no value stated).
- ✅ **`draw_size` = 3** — registry matches GDD; consistent across F-RB3, ACs, knobs.
- ✅ **`pool_cap` = 16** — registry matches GDD F-RB5 / knobs / AC-RB37/38.
- ✅ **`blessing_magnitude`** (offensive 8/12/18, defensive 30/45/68, rally 2/3/5) — unchanged by revision; registry note matches GDD table.
- ✅ **`effective_attack_damage`** — registry note re-synced to `(relic_id, unit)` refresh-on-repick (AC-RB31/RB31b); matches GDD F-RB1. Combate read-hook still provisional (OQ-RB1), correctly flagged in both docs — not a conflict.
- ✅ **`relic_record`** — Reliquias reads `relic_id, relic_category, tier, source_hero_name, epitaph, forge_index`; registry `fields` list matches; read-only (Regla 1) consistent with Forja ownership.

## Anchor entities the new cross-category rules depend on (verified against owners)

- ✅ **`melee_infantry.attack_damage` = 8** (registry, owned Combate) — Reliquias `offensive_damage_base=8` anchored to it. Consistent.
- ✅ **`kaiju.attack_damage` = 45** (registry + `combate-dano.md` line 150) — Reliquias defensive anchor "Sólida (45) = exactly one kaiju hit". Consistent.
- ✅ **Vanguardia `attack_damage` = 25** (`combate-dano.md` lines 86/148, owner) — Reliquias offensive ceiling anchor "25+18=43 < kaiju 45". Consistent. *(The héroes-GDD `3.5× / 140` for Vanguardia is `hero_max_health`, a different stat — no conflict.)*

---

## Informational Notes (no conflict, no blocking action)

ℹ️ **Hero CombatProfiles are not in the entity registry.** `Vanguardia.attack_damage=25` is a genuine cross-system fact (owned by `combate-dano.md`, consumed by `reliquias-bendiciones.md` for balance anchors, referenced by `sistema-de-heroes.md`), but no hero entity is registered. Registering it is arguably premature: `sistema-de-heroes.md` (line 496) flags Vanguardia/Portaestandarte/Guardián as *illustrative archetypes*, with the real roster deferred to Datos de Era/Civilización. **Recommendation:** register hero CombatProfiles when the first-era roster is fixed, not before — until then the values live authoritatively in `combate-dano.md`.

ℹ️ **`offering_time_scale` × fixed physics tick is a design OQ, not a value conflict.** The new cámara-lenta knob interacts with F-RB4's tick-based expiration (`physics_ticks_per_second`, MVP 60) and Combate's fixed-tick two-phase damage order (Combate Core Rule 1). The models are consistent (Reliquias checks expiry *before* Combate's phase-1, as Combate's order requires), but *how* a global time-scale composes with the fixed step is correctly captured as **OQ-RB9** (to be resolved in the modifier-pattern ADR). No numeric conflict.

ℹ️ **New Reliquias knobs are system-internal, unregistered by design.** `offering_time_scale`, `offering_soft_timeout_s`, `offering_cooldown_s` are referenced by no other GDD — per registry rules (only cross-boundary facts are registered), they are correctly left out.

---

## Verdict: PASS

No cross-document value conflicts. The 2026-08-18 Reliquias revision introduced no registry inconsistencies. Two design-level interactions (hero-CombatProfile registration timing; slow-mo × fixed tick) are correctly routed as deferred/OQ items, not conflicts. Safe to proceed to `/review-all-gdds`.
