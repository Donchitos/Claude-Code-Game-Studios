# Architecture Review Report

**Date:** 2026-08-21
**Engine:** Godot 4.6 (pinned 2026-02-12)
**GDDs Reviewed:** 13 system GDDs + concept + systems-index
**ADRs Reviewed:** 2 (ADR-0001, ADR-0002 — both `Proposed`)
**Mode:** full
**Verdict:** **CONCERNS**

> Loaded 13 GDDs, 2 ADRs, engine Godot 4.6. TR registry was empty before this run
> (first review) — 399 TR-IDs newly assigned. Architecture registry: 2 state_ownership,
> 2 interfaces, 0 performance_budgets, 0 api_decisions, 4 forbidden_patterns.
> `docs/architecture/architecture.md` does not exist yet.

---

## Traceability Summary

| Metric | Count |
|--------|-------|
| Total technical requirements extracted | **399** |
| ✅ Covered by an accepted-scope ADR | ~19 |
| ⚠️ Partial | ~8 |
| ❌ Gap (no ADR) | ~372 |
| **Coverage** | **~5%** |

Per-system TR counts: input 29 · era 20 · save 24 · control 25 · tropas 25 · heroes 33 ·
combate 38 · kaiju 44 · temporizador 19 · permadeath 32 · forja 29 · reliquias 41 · ui 40.

The ~5% figure is **not** a defect signal. It is what a two-ADR architecture looks like
against a 13-system corpus. The meaningful question is not "why are 372 uncovered" — most
await ADRs that were never meant to exist at this stage — but **"do the GDDs self-declare
architecture decisions that remain unwritten?"** The answer is yes: roughly **seven**
beyond the two that exist.

---

## What the Two ADRs Cover (and cover well)

**ADR-0001 — instance combat-stat modifier layer.** Lands the Pillar-2 damage hook:
`effective_attack_damage()`, `CombatState`, flat-additive per-instance modifiers,
refresh-on-repick dedup, expiry-before-phase-1, "expiry never kills." Covers
`TR-reliquias-003/004/005/006/007/009/021/022` and honours the Combate single-damage-path
constraint. This is exactly **F2-B1** from the 2026-08-18 cross-review.

**ADR-0002 — `TimeControl` service.** Lands time-regime authority: `PAUSED > SLOWED >
NORMAL` precedence, `game_time_paused` with identical prior semantics, `game_tick`
pause/scale-aware integer clock superseding the provisional `Engine.get_physics_frames()`.
Covers `TR-permadeath-003/004`, `TR-reliquias-024/025/026`, `TR-combate-029`,
`TR-kaiju-029`, `TR-temporizador-010`. This is exactly **F2-B4/S2**.

The cross-review named two architecture blockers; both now have sound ADRs.

---

## Cross-ADR Conflict Detection

**No blocking conflicts.** The two ADRs own disjoint state (`instance_combat_stats` vs
`game_time_regime`) and the architecture registry records both without contradiction.

- **Near-cycle, resolved by stated ordering.** ADR-0002 `Depends On: ADR-0001`, while
  ADR-0001's expiry sweep reads ADR-0002's `game_tick`. Not a true cycle: ADR-0001's core
  (modifier layer + effective-stat computation) needs no clock; only the *sweep timing*
  consumes `game_tick`. Clean order: **ADR-0001 structure → ADR-0002 clock → wire expiry.**
- **Minor internal inconsistency (not a cross-ADR conflict).** ADR-0001 Verification
  Required item 1 still asserts in present tense that `Engine.get_physics_frames()` "es la
  llamada correcta"; ADR-0002 supersedes it. Fix the stale text at Accepted-time (the
  Risks / Related-Decisions sections already frame it correctly).

### Recommended ADR Implementation Order (topologically sorted)

```
Foundation (no ADR dependencies):
  1. ADR-0001  Instance combat-stat modifier layer
Depends on Foundation:
  2. ADR-0002  TimeControl (requires ADR-0001)
```

Both must reach `Accepted` before any dependent epic — stories referencing a `Proposed`
ADR are auto-blocked, and ADR-0002 cannot be safely implemented until ADR-0001 is
`Accepted`.

---

## Engine Compatibility (Phase 5 + godot-specialist consultation)

**Verdict: both ADRs are engine-safe to move to `Accepted`. No blocking engine issue.**

Audit results:

- Engine consistency: both declare Engine Compatibility, both agree Godot 4.6 — no drift.
- Deprecated API references: **zero** across both ADRs.
- Post-cutoff APIs: both declare "Ninguna"; ADR-0002 actively *rejects* `Engine.time_scale`
  and `SceneTree.paused`.
- Shared invariant: both assert `Engine.physics_ticks_per_second == 60` at startup.
- The one real post-cutoff change in scope (4.5 3D-interpolation rearchitecture) is
  correctly ruled 3D-only, irrelevant to this 2D MVP.
- Engine Compatibility section coverage: 2 / 2 ADRs.

### Engine Specialist Findings

- **[MEDIUM · ADR-0002]** `TimeControl` per-frame ordering vs. consumers is assumed, not
  enforced. "Sweep before phase-1 damage" needs `TimeControl._physics_process` to advance
  `game_tick` before Combat reads it; today that holds only by Autoload registration
  artifact. **Fix:** explicit `process_physics_priority = -1000` + a CI/test assertion.
  A stale read is a silent off-by-one expiry — contradicts the project's loud-fail standard.
- **[LOW · ADR-0002]** Actually set `PROCESS_MODE_ALWAYS` on `TimeControl` (make the
  documented defense real).
- **[LOW · ADR-0001]** Reconcile the stale `Engine.get_physics_frames()` present-tense text
  in Verification Required item 1.
- **[LOW · both]** Document the `StringName` (`source_id`) vs `String` (`source_relic_id`)
  type-choice rationale so the asymmetry reads as intentional.
- **[LOW · ADR-0001]** Note the `CombatProfile` default-cache-mode (`CACHE_MODE_REUSE`)
  assumption that underpins "shared by type."
- **[LOW · ADR-0002]** Add a slow-mo-smoothness validation criterion (continuous scaled
  delta, never frame-skip) — ADVISORY per the Visual/Feel test-evidence tier.

---

## GDD Revision Flags (Architecture → Design feedback)

One flag, **low severity**:

| GDD | Assumption | Reality (ADR-0002) | Action |
|-----|-----------|--------------------|--------|
| sistema-de-heroes.md (V-5/V-6 note), permadeath.md (Regla 4 corollary) | `PROCESS_MODE_ALWAYS` is *required* for the death-beat clock/animation to survive pause | ADR-0002: the real exemption is "exempt systems never poll TimeControl — they read real-time delta directly"; `PROCESS_MODE_ALWAYS` is defensive, **not** load-bearing (nothing sets `SceneTree.paused`) | Reconcile the *why* (not the *what* — marking it ALWAYS is harmless) |

**Resolution (user decision, 2026-08-21):** fold into ADR-0002's acceptance reconciliation
(permadeath.md is already on ADR-0002's Migration Plan list). **No systems-index status
change** — this is a *why-not-what* clarification and nothing breaks.

---

## Coverage Gaps That Matter — Required ADRs

The GDDs self-declare **~7 architecture decisions the two existing ADRs do not cover.**
Prioritized, Foundation first.

### Foundation layer (highest priority)

- ❌ **Save / Persistence ADR** — checksum algorithm (Save GDD: "a resolver en un ADR"),
  serialization format, ephemeral-invocation-state round-trip (`OQ-RB2`), **`expiry_tick`
  rebasing across reload**, `forge_counter` int64 via `store_var`/`get_var`, schema
  migration chain. This is cross-review blocker **S4**, and *both existing ADRs explicitly
  defer to it.* Engine Risk: MEDIUM. Suggested: `/architecture-decision save-persistence`
- ❌ **Era lifecycle / init-ordering ADR** — `LOADING→LOADED` async load, era-`LOADED`
  signal contract, Autoloads reading roster on era-`LOADED` not `_ready()` (`TR-era-011`,
  `TR-permadeath-017`), per-era cap re-validation. Engine Risk: MEDIUM.
- ❌ **Camera/zoom constant-ownership ADR** — `world_unit_scale` / `camera_pan_speed` /
  `zoom_min` / `zoom_max` (Datos de Era vs Control), `Camera2D.zoom` sign mapping
  (`OQ-INPUT-2`). Resolves cross-review **F2-W5**. Small but unblocks a live dispute.
- ❌ **Input context-enforcement ADR** — `current_context` get-only +
  `request_context_transition()` as cross-cutting contract (`OQ-INPUT-5`), plus
  frame-ordering of the distributed Pillar-1 invariant Input→Control→Permadeath
  (`OQ-INPUT-1`).

### Feature layer

- ❌ **`CombatProfile` storage ADR** — Combate `OQ-1` (embedded in `TroopDefinition` /
  `HeroDefinition` vs parallel referenced resource). The combate GDD marks it "requiere ADR
  antes de implementar"; **ADR-0001 explicitly left it open.**
- ❌ **Relic-registry representation ADR** — Forja `OQ-FL4/FL5` + Reliquias `OQ-RB6`:
  `RelicRecord` runtime home (Autoload vs node), serialization, same-frame no-deferred
  deposit, `relic_id` encoding, seeded-RNG injection. A coordinated pair.
- ❌ **Kaiju intent-controller ADR** — the GDD's "Aún para el ADR": where the intent FSM
  lives, immediate (non-`CONNECT_DEFERRED`) `apply_damage` wiring, and the hard requirement
  that the kaiju is the *sole* caller of `apply_damage`, excluded from Combate's generic
  auto-attack loop.
- ❌ **Permadeath implementation-pattern ADR** — `OQ-P5`: Autoload vs node vs event-bus,
  `reset_queue()` ownership + the input-suppression softlock class, `animation_done` /
  `force_relic_reveal_final()` hook forms (`OQ-P2`), and the 4.6 engine spike
  (`PROCESS_MODE_ALWAYS` + unscaled delta + `Engine.time_scale` independence — the pinned
  reference docs do **not** cover these, so the spike the GDD asks for is genuinely needed).

### Cross-cutting convention (ADR or control-manifest)

- ❌ **Config-enforcement + determinism convention** — the **loud-fail-on-load vs
  clamp-on-load split** is currently *undecided across ~10 GDDs* (Héroes/Combate/Permadeath/
  Kaiju/Reliquias/Forja = loud-fail; Tropas/Save/Control = clamp). Kaiju specifies a precise
  4.6 mechanism (custom setter + `push_error()` + halt — **not** `assert()` alone,
  `@export_range`, or `_validate_property`). Plus the recurring seeded-RNG /
  monotonic-`entity_id`-not-`get_instance_id()` determinism seam (Kaiju AC-K71, Reliquias
  AC-RB18, Forja Regla 4). No ADR ratifies either; both belong in the control-manifest at
  minimum.

---

## Architecture Document Coverage (Phase 6)

`docs/architecture/architecture.md` **does not exist** — no master blueprint to validate
systems against yet. Expected: `/create-architecture` has not run, and the cross-review
says not to run it until the blockers clear. Recorded as the reason a full system↔layer
coverage check cannot be performed at this stage.

---

## Pre-Gate Checklist (Phase 9)

| Artifact | Status | Action |
|----------|--------|--------|
| `tests/unit/`, `tests/integration/` | ❌ | run `/test-setup` |
| `.github/workflows/tests.yml` | ❌ | run `/test-setup` |
| `design/ux/interaction-patterns.md` | ❌ | run `/ux-design` |
| `design/accessibility-requirements.md` / `design/ux/accessibility-requirements.md` | ❌ | run `/ux-design` |

`/gate-check pre-production` is **not** offerable — test infrastructure and UX/accessibility
artifacts are absent, on top of the ADR gaps above.

---

## Verdict: CONCERNS

- The two ADRs that exist are **sound, mutually consistent, engine-safe, and correctly
  target the two architecture blockers the cross-review named.** After the minor cleanups
  (stale `get_physics_frames()` text; the MEDIUM ordering guard), **both are ready to move
  `Proposed → Accepted`.**
- But the architecture as a body is **early and incomplete**: the GDDs self-declare **~7
  further ADR-level decisions**, several Foundation-layer (Save/persistence most urgently —
  both existing ADRs defer to it). **This cannot pass the Pre-Production gate yet.**

Not FAIL: no blocking cross-ADR conflict, and the existing decisions are not broken.
Not PASS: named Foundation-layer requirements sit uncovered.

### Immediate actions (highest-impact first)

1. Apply the two ADR cleanups, then move ADR-0001 + ADR-0002 to `Accepted` (in that order).
2. Write the **Save/Persistence ADR** — Foundation *and* the explicit dependency of both
   existing ADRs.
3. Write the **`CombatProfile` storage ADR** (Combate OQ-1) and the **Era init-ordering ADR**.

Re-run `/architecture-review` after each new ADR to verify coverage improves.
