---
name: project-heroes-system-ac-status
description: Status of Sistema de Héroes GDD's Acceptance Criteria and which ACs are blocked on undesigned Permadeath / Encuentro con Kaiju, as of 2026-08-06
metadata:
  type: project
---

`design/gdd/sistema-de-heroes.md` is the Pilar-1-eje GDD (hero permadeath / relic-quality
formula). As of 2026-08-06 its Acceptance Criteria section (AC-H01–AC-H32, Dado/Cuando/Entonces
format) was drafted, approved by the user, and written to the file.

Same pattern as [[project-troop-system-ac-status]] and [[project-save-persistence-status]]:
several ACs are blocked on undesigned downstream GDDs and are only verifiable today via a
mocked contract at Sistema de Héroes' own boundary:
- **AC-H11** (`DYING → DEAD` only after the sustained beat releases) — blocked on Permadeath,
  which owns the beat timing. Sistema de Héroes only owns entering/holding `DYING`.
- **AC-H25** (serialized death beats when two heroes die same frame — no two simultaneous
  `DEATH_HOLD`s) — blocked on Permadeath, which owns serialization. Sistema de Héroes only
  owns snapshotting each hero's D/T/P independently (that part, AC-H24, IS testable today).
- **AC-H29** (~30s tactical-decision window before an inevitable death changes the D/T/P
  outcome — Test de Diseño 1) — blocked on Encuentro con Kaiju, which owns encounter design
  and the kaiju timer. Verifiable today only with a mock encounter exposing the same hooks.

Distinction worth preserving (mirrors the troop-system note): when a GDD *exposes* a contract
at its own boundary vs. *consumes/controls* a downstream system's behavior, the exposure side
is testable now even if the consumer is undesigned. **AC-H12** (Sistema de Héroes exposes the
full death-circumstance payload — hero_id, hero_name, relic_category, snapshotted D/T/P — to
Permadeath) is fully testable today via a mock listener, even though AC-H11/AC-H25 (what
Permadeath *does* with the beat timing) are not.

**Why**: Sistema de Héroes is the load-bearing system for Pilar 1 (Sacrificio con Peso) — the
`relic_quality` gate formula (D as gate, T/w_stakes and P/w_purpose as bonuses) is the
mechanical proof that intention, not circumstance alone, determines legacy quality. The
negative-agency test (AC-H13/H14: D=0 caps quality at 0.10 regardless of T/P) is the single
most safety-critical unit test in this GDD — any refactor of the relic_quality formula should
re-run it first.

**How to apply**: when Permadeath or Encuentro con Kaiju GDDs get authored, circle back to
`sistema-de-heroes.md` to backfill AC-H11, AC-H25, and AC-H29 against the real contracts (not
mocks), and confirm Permadeath's own GDD satisfies the exposure contract Sistema de Héroes
already committed to in AC-H12 (hero_id/hero_name/relic_category/D-T-P snapshot). Also check
whether Forja de Legado (also undesigned) needs to confirm it consumes the relic_quality→tier
mapping (AC-H19/AC-H20 boundaries) unchanged.

**2026-08-07 adversarial pass — additional findings not yet actioned in the GDD file:**

1. **AC-H21 belongs in the blocked-AC list too, and isn't tagged.** AC-H21 tests the
   destination-match rule that decides `D` ("orden emitida con destino X pero murió en otro
   lugar → D=0") — but the Dependencies table assigns *providing* the D classification to
   Combate/Daño (OQ-2, undesigned). AC-H21 is only verifiable today via a mock Combate/Daño
   that happens to implement exactly this destination-match rule — same structural risk as
   AC-H11/H25/H29. It should carry a **(bloqueado)** tag and be added to this file's backfill
   list, keyed to OQ-2, not just OQ-3/OQ-4. By contrast AC-H13/H16-H20/H22 are fine unblocked —
   they test the `relic_quality` formula given D/T/P as opaque inputs, which is source-agnostic.

2. **AC-H23 doesn't test joint-extreme knob combinations, and there's a real bug hiding here.**
   `relic_quality` at D=1,T=1,P=1 reduces algebraically to exactly
   `base_deliberate + w_stakes + w_purpose` (the `base_accidental` terms cancel). At the
   **joint minimum** of each knob's individually-clamped safe range (0.30 + 0.20 + 0.15 =
   0.65), Tier 3 Legendaria (needs ≥0.70) becomes **mathematically unreachable even in the
   best possible circumstance** — confirmed by hand calc, not yet caught by any AC. At the
   **joint maximum** (0.50 + 0.40 + 0.30 = 1.20), the outer `clamp(...,0,1)` silently
   saturates, flattening the intended distinction between "good" and "perfect" circumstances.
   The Tuning Knobs "Enforcement" text only clamps individual knob values, not the sum — this
   is a genuine spec gap (route to game-designer/systems-designer: decide whether to normalize
   the three weights to always sum to 1.00, or reject config load if sum drifts too far) before
   a new AC-H23b (joint-minimum reachability) / AC-H23c (joint-maximum saturation) can be
   written definitively. This matches what systems-designer's parallel review is independently
   checking on the troop/kaiju side — coordinate findings before either GDD gets a fix.

3. **AC-H32 is now stale and should be split, not just refreshed.** UI Requirements
   (U-1..U-7) are fully written as of this file's last read — the "placeholder, advisory not
   gate" note under AC-H32 no longer applies. Split into AC-H32a (3-state discrete tier
   transition, U-2), AC-H32b (visibility threshold gating — testable structurally today via a
   mock threshold even though OQ-6's exact number is still open), AC-H32c (freeze-on-DYING,
   U-4 — Integration tier, ties to the AC-H15 snapshot), AC-H32d (no editorializing text
   present, U-5). Also: **U-6** (selection marker visually differentiates hero vs. troop) has
   **no covering AC at all** — AC-H07 only tests selection *priority* logic, not the marker's
   visual differentiation. Gap to close when AC-H32 gets rewritten.

4. **Core Rule 4 (irreversibility) has a coverage gap.** AC-H27 only tests irreversibility
   through a crash/reload. No AC tests an in-session attempt to act on a `DEAD` hero (heal
   target validation, order issuance, etc.) being rejected/no-op. Propose AC-H27b.
