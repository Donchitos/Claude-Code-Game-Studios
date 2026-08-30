# Consistency Check Report — 2026-08-12

**Trigger:** Post-approval of `encuentro-con-kaiju.md` (system #9).
**Registry checked:** 4 entities, 0 items, 5 formulas, 6 constants.
**GDDs scanned (9):** input, control-y-seleccion-de-unidades, sistema-de-heroes,
datos-de-era-civilizacion, guardado-persistencia, temporizador-de-preparacion-ritual,
sistema-de-tropas, combate-dano, encuentro-con-kaiju.

## Verdict: PASS (0 value conflicts)

### 🔴 Conflicts — cross-GDD value contradictions
**None.** Every registered value Encuentro con Kaiju touches agrees with its source:
- ✅ `kaiju` CombatProfile `45 / 2.5 / 4.5 / 10.0` — matches `combate-dano.md:89` and registry; `leash_range` nulled per Encuentro Regla 2 (consistent with registry note).
- ✅ `telegraph_duration_s` `14.0`, range `[12.5,17.0]`, hard min `12.0` — single-source, self-consistent.
- ✅ `time_to_death` formula + output range `[18.5, null]` — Encuentro (owner) and Héroes (consumer) agree.
- ✅ `melee_infantry` DPS `8` (=8/1.0) — matches Encuentro F4 sanity-check.
- ✅ `guard_radius` `4.0` — Héroes (owner), Encuentro (KV-2), Combate (AC-C32) all agree.

### ⚠️ Stale Registry (1) — ✅ APPLIED
- `kaiju_timer_remaining_ratio.referenced_by` now includes `encuentro-con-kaiju.md`
  (read-only consumer, AC-K04); stale "sin GDD aún" comment removed; `revised: 2026-08-12`.

### Registry Gaps (2) — ✅ APPLIED
- `guard_radius` (constant, `4.0`, safe range 2.5–6.0) — registered; source Héroes, referenced_by Héroes + Encuentro + Combate.
- `incoming_damage_rate_total` (formula) — registered; source Encuentro F6, referenced_by Encuentro + Héroes.

### Internal Fix Applied
- `encuentro-con-kaiju.md:333` read `min_troop_dps` while the F4 box + AC-K85 use
  `max_single_troop_dps` (a loose end from the round-3 F4 enforcement edit). Corrected.

## OQ-4 Cross-GDD Cleanup — APPLIED (de-flag + re-verify blocked mocks)

Encuentro con Kaiju is Approved, so four GDDs' "sin GDD / Provisional" references were
de-flagged and their blocked ACs re-verified against Encuentro's real contract:

**Combate/Daño** (Approved)
- Interactions + Dependencies rows → Approved reference.
- AC-C32/C33/C34 (`P`-side) → **desbloqueados** — Encuentro Regla 5/AC-K43/K44 define marking; verifiable without mock.
- AC-C35 → **partial** — Kaiju side resolved; D-side still blocked on Control's Sacrificio verb (OQ-2).
- OQ-5 (~30s window) → resolved by Encuentro F2. OQ-7 (kaiju leash) → resolved by Regla 2. OQ-8 (victory/defeat owner) → resolved by Regla 9.
- Line-91 leash rationale updated.

**Temporizador de Preparación/Ritual** (Approved)
- Interactions + Dependencies rows → Approved reference.
- AC-T03b (consume-not-own) → **desbloqueado** — confirmed by Encuentro AC-K04 (read-only, never writes back).
- AC-T07b → **partial** — Kaiju side resolved; UI/Audio still sin GDD.
- OQ-2 (victory/defeat) → resolved by Encuentro Regla 9. OQ-4 (climax internal timer / enrage) → resolved by Regla 10. OQ-5 (consume-not-own) → resolved by AC-K04.

**Sistema de Héroes** (Approved)
- Interactions row → Approved; notes `time_to_death` (F2) + `incoming_damage_rate_total` (F6), readout reflects most-dangerous source (AC-K68).
- AC-H29 → data contract resolved (Encuentro F2/F6); remains Integration pending playable era + Control's Sacrificio verb.
- AC-H30 → design contracts Approved; remains Integration pending an implemented era (vertical slice).
- AC-H32b → data contract resolved; concrete threshold value still open (OQ-6 / Encuentro OQ-14).
- Out-of-scope (left as-is): AC-H11/H21/H25/H34 reference Permadeath / Control Sacrificio / Audio — not Encuentro.

**Sistema de Tropas** (Designed)
- Victory/defeat owner OQ → resolved (Encuentro Regla 9/AC-K53: troops are NOT a defeat condition — unblocks Tropas AC-25).
- Reinforcement-reset OQ + "troops expose positions" OQ → updated (Encuentro/Temporizador now Approved; targeting covered by Regla 3).

**Encuentro con Kaiju** — its own OQ-4 marked ✅ Resolved.

## Remaining Open (not actioned)
- OQ-10 — formalize a lock / re-verify trigger for the kaiju's `attack_damage`/`attack_cooldown_s` in `combate-dano.md` (belongs in that doc; AC-H29 depends on those values via Encuentro F2).
- `sistema-de-heroes.md:379` AC-H21 says "Combate/Daño, sin GDD" — factually stale (Combate is Approved; real blocker is Control's Sacrificio verb). Minor pre-existing wording issue, outside this OQ-4 pass.
