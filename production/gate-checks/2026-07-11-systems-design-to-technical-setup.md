# Gate Check: Systems Design → Technical Setup

> **Date**: 2026-07-11
> **Checked by**: gate-check skill (review mode: lean — all four PHASE-GATEs ran)
> **Verdict**: **CONCERNS — advanced** (user decision; matches the Concept→Systems-Design precedent)
> **Stage updated**: production/stage.txt → "Technical Setup"

## Required Artifacts: 3/3 present

- [x] `design/gdd/systems-index.md` — 32 systems (11 MVP), dependency map,
  high-risk table, resolved circular dependency, progress tracker current
  (11 designed / 11 reviewed / 11 approved).
- [x] All 11 MVP GDDs individually reviewed and **APPROVED** (2026-07-09 →
  2026-07-11), each with a review log in `design/gdd/reviews/`. Review arc:
  every GDD passed an adversarial multi-specialist review; 7 required
  in-session revision cycles (building-ui went through a MAJOR verdict +
  toast-subsystem rebuild); all approvals gated on fresh-agent verification
  passes (approve-on-clean pattern).
- [x] Cross-GDD review report `design/gdd/gdd-cross-review-2026-07-10.md` —
  verdict CONCERNS → resolved to PASS-equivalent (5 consistency warnings +
  2 design findings all resolved in-session, user-approved).

## Quality Checks: 6/6 passing

- [x] All 11 MVP GDDs: 8/8 required sections (grep-verified)
- [x] No unresolved MAJOR REVISION verdict
- [x] Cross-GDD verdict not FAIL; flagged issues resolved or explicitly
  accepted (D1 cozy-carport → VS priority #1; D2 test-scope note)
- [x] Dependencies bidirectionally consistent
- [x] MVP priority tier defined (4-tier staging)
- [~] Stale references: substantially clean; gate CoV found 6 residual
  stale status references (5 "Draft" headers + 1 "In Review" row) —
  cosmetic, fixed as part of this gate's bookkeeping.

## Director Panel Assessment

| Director | Verdict |
|----------|---------|
| Creative Director | **READY** |
| Technical Director | **CONCERNS** |
| Producer | **CONCERNS** |
| Art Director | **READY** |

**CD (READY)**: MVP set collectively delivers the core fantasy and Pillars
1/2/4; the two accepted gaps (inert walls → VS #1; no-stakes MVP → Wave
Defense quarantined behind /prototype) are sound sequencing. Advisories:
name Township "prosperity" before its GDD; carry the Pillar-3 10-minute
lockout test into wave-prototype criteria; never-blocks guarantee is a
pillar commitment for the building/AI ADR.

**TD (CONCERNS — carry-forward risk register items)**:
1. Jolt-default + D3D12-default (Godot 4.6) not tied to a decision —
   physics-backend selection needs an ADR line item, picking downstream.
2. Rendering ADR must verify 4.7 GridMap/MeshLibrary changes against the
   engine reference (TD-ENGINE-RISK before Accepted).
3. Pre-VS perf spike needs named pass/fail thresholds (draw calls + memory
   at township block-count).
4. Save/Load serialization = highest-uncertainty Core unknown; ADR before
   any persistence code.
Foundation boundaries are ADR-ready; [TO BE CONFIGURED] fields are the
phase's job, not a blocker.

**PR (CONCERNS — non-blocking)**:
1. No /estimate baseline exists (the index's own re-baseline instruction
   was never honored) — run during Technical Setup, before implementation.
2. Documentation-staleness pattern (recurred ~4 sessions + again in this
   gate's CoV) becomes more dangerous once ADRs cite GDD contracts —
   grep-based de-staling sweep before ADR authoring; treat each GDD's Open
   Questions as the authoritative ADR input queue.
3. Voxel World rendering ADR = keystone, author FIRST, as
   provisional-pending-spike.

**AD (READY)**: Visual foundation coherent; the Note's commitments traced
into every consuming GDD without drift; no red-green/hue-only violations;
art bible can start against validated constraints.

## Blockers

**None.** No director returned NOT READY.

## Recommendations (Technical Setup opening work items, in order)

1. Open an architecture risk register seeded with TD items 1–4 + CD's
   three advisories (input to /create-architecture).
2. De-staling sweep before ADR authoring (the 6 found references were
   fixed at this gate; sweep again when ADRs begin citing contracts).
3. Run /estimate on the MVP set for the first timeline baseline.
4. Author the Voxel World rendering ADR first, provisional-pending-spike,
   with a TD-ENGINE-RISK check against the 4.7 reference.

## Chain-of-Verification

5 questions checked — verdict unchanged. Two tool actions: grep across all
12 review logs confirmed APPROVED verdicts + cross-review verdict re-read;
header re-scan found the 6 stale status references (new evidence for PR
concern #2; authoritative records were correct throughout).

## Carried forward (beyond the gate)

- /prototype wave-defense REQUIRED before the Wave Defense GDD (VS).
- UX Flags: /ux-design build-hud + villager-panel in Pre-Production.
- Registry candidates: starting_villager_count (from villager-ai revision).
