# Cross-GDD Review Report

> **Date**: 2026-07-10
> **Mode**: full (consistency + design theory + cross-system scenario walkthrough)
> **GDDs Reviewed**: 11 (all MVP systems) + game-concept.md + systems-index.md
> **Reviewers**: consistency agent (general-purpose), design-holism agent (game-designer), scenario walkthrough (main session)
> **Registry baseline**: 16 entries (4 items, 1 formula, 11 constants) — pre-verified by /consistency-check same day (PASS)

Systems covered: Scene/World Management, Voxel World, Camera & Input,
Time & Tick, Resource & Item Database, Building System, Villager AI &
Behavior, Needs & Mood, Build Validation & Navigability, Building UI,
Villager Info UI.

---

## Consistency Issues

### Blocking
**None.** The blueprint/job pipeline contracts, occupancy rules
(blueprints non-solid everywhere), the 3-tier recovery ladder values,
pause/warp semantics, the Valley-never-pauses rule, and all cross-GDD
acceptance-criteria pairs are consistent across all 11 documents.

### Warnings — ALL RESOLVED IN-SESSION (2026-07-10, user-approved patches)
1. **Dependency table asymmetries** (7 missing reciprocal rows across
   camera-input, time-tick, voxel-world, scene-world-management,
   building-system, villager-ai-behavior, building-ui) → all reciprocal
   rows added, including formalizing the Building ↔ Villager AI mutual
   seam in both downstream tables.
2. **Time & Tick self-contradiction** (Core Rule 2 said "RESOLVED:
   Building UI" while its own Open Questions row was still open and
   Interactions/Dependencies still assigned the pause/speed UI to Main
   Menu & Settings) → Open Question closed, Main Menu row demoted to
   settings-only, Building UI rows added.
3. **`unsheltered_bed_multiplier` ownership drift** (registry + Build
   Validation declare Needs & Mood the owner, but the knob was only
   tabled in Build Validation) → knob row added to the owner's Tuning
   Knobs table with the ordering invariant.
4. **Lockstep invariant one-sided** (`max_room_height ≥ wall_height`
   stated only in Build Validation + registry) → lockstep note added to
   Building System's `wall_height` knob row (incl. the
   `villager_clearance` = default `wall_height` relationship).
5. ℹ️ **Stale two-tier wording** in Villager AI's resolved OQ1 (predated
   the 3-tier ladder) → updated to the 3-tier description.

Formula-range compatibility (2e) and AC cross-checks (2f): CLEAN as
found — no changes needed.

---

## Game Design Issues

### Blocking
**None remaining** — the two heavy findings below were decided by the
user in-session and are now documented design decisions, not open flaws.

### Decided in-session (were 🔴-grade findings)
**D1 — Walls are mechanically inert at MVP ("cozy carport" is the
optimum).** A 4-pillar + roof + bed structure reaches full shelter (1.0)
at zero cost — identical to an elaborate house — failing Pillar 1's own
design test for walls. **User decision: accept as a KNOWN MVP
scope-narrowing.** Documented in build-validation-navigability.md Edge
Case 6 (now explicitly marked a known gap) and its Open Question 1
(elevated to VS priority #1: wall-coverage requirement, decided together
with doors).

**D2 — No scarcity means the MVP tests the first ~10 minutes, not
sustained engagement.** The concept's hypothesis wording implied more
than the 1-villager/1-need/free-materials scope can test. **User
decision: document the limitation explicitly.** A test-scope note now
sits under the MVP hypothesis in game-concept.md, defining what a PASS
looks like and naming the two accepted gaps.

### Warnings (accepted, no change)
**D3 — Attention budget is sparse post-first-room** (1 active system;
steady-state after the first sleep cycle). Consequence of D2's accepted
scope — revisit attention budget when Alpha systems land (noted for the
Alpha design pass; systems-index already tracks the loop-competition
risk for Alpha).

Clean checks: progression-loop singularity (exactly one loop at MVP),
difficulty curves (N/A), pillar alignment (11/11 systems mapped,
anti-pillars structurally intact), player-fantasy coherence (one
steward identity across all systems).

---

## Cross-System Scenario Issues

Scenarios walked (5): the MVP golden path (draw room → villager builds →
room recognized → move-in → sleep); undo during active construction;
pause-planning then 3x-warp burst; sleep-interruption chain (bed removed
mid-travel); scene transition with construction continuing.

### Blockers
**None.** Undo/revoke ordering, burst caps (per-villager, per-frame),
celebration coordination (command flourish vs. room-recognized cue),
seal-in handling, and toast re-assertion are all explicitly specified.

### Warnings — RESOLVED IN-SESSION
**S1 — Shelter flag flip mid-recovery was only implicitly defined**
(roof completes while the villager is already asleep in the unsheltered
bed). → New Edge Case 11 in needs-mood-system.md: the source→rate table
re-evaluates per tick, the new rate applies next tick, no restart/no
signal/no lost progress; downgrade behaves symmetrically.

### Info
**S2 — Toast backlog after dungeon return**: Build Validation events
fired during Suspended queue up; the max-3 + FIFO rules bound the pile.
Accepted as-is.

---

## GDDs Flagged for Revision

**None outstanding** — all flagged items were patched in-session with
user approval (see above). Status fields in systems-index.md remain
unchanged (no GDD is in "Needs Revision" state).

---

## Verdict: **CONCERNS → resolved to PASS-equivalent**

Formal verdict at review time: **CONCERNS** (5 consistency warnings, 2
design findings requiring user decisions, 1 scenario warning — zero
blockers). All warnings were patched and both design findings were
decided and documented in the same session. **Post-resolution state: no
open items.** Architecture work (/create-architecture) is not blocked.

### Notes for the next phase
- The individual-GDD review requirement for the Systems Design →
  Technical Setup gate is still outstanding (10 GDDs unreviewed;
  Building System is In Review awaiting re-review after its revision).
- /prototype wave-defense remains required before the Wave Defense GDD
  (Vertical Slice).
- UX Flags to honor in Pre-Production: /ux-design build-hud,
  /ux-design villager-panel.
