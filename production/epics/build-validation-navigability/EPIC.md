# Epic: Build Validation & Navigability

> **Layer**: Feature
> **GDD**: design/gdd/build-validation-navigability.md
> **Architecture Module**: Build Validation & Navigability (pure analysis layer — owns no world data, mutates nothing; independent BFS/flood-fill over the shared walkability predicates; room/sealed classification; shelter flag; four-signal contract)
> **Manifest Version**: 2026-07-23
> **Status**: Ready
> **Stories**: 10 stories created (see Stories table below)

## Overview

Build Validation & Navigability is the game's structural analyst. It watches what
the player builds (via the Building System's batched `construction_completed`
signal) and answers the two questions the builder systems deliberately don't —
*"is this a room?"* (candidate interior cells: standable + roofed, orthogonally
connected, at least `min_room_cells`) and *"can a villager actually get there?"*
(a full-reachability trace from the region's interior to an open-sky standable
cell, walking **Villager AI's exact movement graph**, never a plain 4/8-neighbor
flood-fill). It never blocks, reverts, or auto-fixes anything (Building System
Core Rule 10) and never moves a villager (its own Rule 9): it recognizes,
confirms, and gently warns. Its one mechanical output is the **sheltered** flag
that Needs & Mood's three-rung recovery ladder consumes; its three presentational
outputs are the room-recognized confirmation, the sealed-space warning, and the
unsheltered-in-the-open info hint.

This epic is the head of **Milestone 02 Cluster A** — the payoff mechanic. It
owns milestone criteria **#1** (all Logic ACs green), **#2** (the AC36
reachability property corpus in CI under 60 s), the analysis half of **#5** (the
live-pair payoff loop — shelter is what makes recovery mean something), and **#7**
(`presentation-002`'s scaffolding finally receiving real signals). Cluster A is
**PROTECTED** — nothing in this epic is on the cut lever.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: AI Pathfinding, Navigation & Room Analysis | **Primary.** Build Validation runs its **own independent BFS/flood-fill**, calling Villager AI's shared `is_standable`/`is_step_legal` predicates directly; it never touches Villager AI's `AStar3D` instance and never duplicates the rules or the constants. Resolves TR-019 in favor of cell-rule flood-fill: **zero `NavigationServer3D`/`NavigationAgent3D`/`NavigationRegion3D`** (grep-verifiable). Reference trace shape is given in the ADR's Key Interfaces (`_trace_reachability`) | HIGH |
| ADR-0001: Inter-System Reference & DI Pattern | Injected-tier module: typed `@export` refs wired in `GameWorld.tscn`, all wiring/validation in an explicitly-callable `setup()` that asserts its deps; headless-instantiable via `Node.new()` + mocks | MEDIUM |
| ADR-0002: Tuning/Config Data Strategy | One `Resource`-derived config class, typed `@export` per Tuning Knob, `.tres`; `validate() -> Array[String]` called once at boot; single-field range issue → warn + clamp + proceed; **GDD-declared BLOCKING cross-value invariant → terminal boot-halt** (AC27's lockstep invariant). Documented cross-module exception: this module reads the Building System's `wall_height` bound | MEDIUM |
| ADR-0016: Build-Project Entity Lifecycle | The `construction_completed(cells: Array[Vector3i])` seam (story building-033, `TR-building-system-075`) is the analysis trigger — emitted once per tick dispatch that completes at least one job, carrying every cell completed in that dispatch | MEDIUM |
| ADR-0012: Save/Load Serialization Strategy | **Build Validation is NOT deserialized — full re-derive on load.** Nothing to serialize (GDD Rule 4); the transient snapshot is rebuilt by the load pass. VS-tier; AC26 stays deferred | LOW |

Engine-risk basis (4.7 policy): **HIGH** — this epic sits inside the flagged
Navigation/AI-Pathfinding domain. The load-bearing post-cutoff facts are the same
ones Villager AI carries: `AStarGrid3D` does **not** exist in Godot 4.7, and
`NavigationServer3D` is forbidden here by ADR-0007 (a navmesh cannot express the
exact cell rules). Default signal connections are synchronous — load-bearing for
Rule 10's "all emissions of one analysis pass are delivered synchronously within
one frame" contract. Cross-reference `docs/engine-reference/godot/` before any
engine API use.

## GDD Requirements

51 TRs registered (`TR-build-validation-navigability-*`). ADR-worthy coverage:

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-build-validation-navigability-008 / -009 / -010 / -020 | Movement graph consumed verbatim; open-sky trace; no duplicated rules/constants; unbounded per-event flood-fill | ADR-0007 ✅ |
| TR-build-validation-navigability-019 | Deferred engine-capability decision (NavigationServer3D vs. cell flood-fill) | ADR-0007 ✅ (RESOLVED — cell flood-fill) |
| TR-build-validation-navigability-016 / -061 / -062 | Blocking config-load invariant; ladder-ordering courtesy check; all values data-driven | ADR-0002 ✅ |
| TR-build-validation-navigability-006 / -052 | Event-driven never per-frame; incremental snapshot patching; batched construction signal | ADR-0007 + ADR-0016 ✅ |
| TR-build-validation-navigability-028 | No persistent identity — nothing serialized, full re-derive on load | ADR-0012 ✅ (VS) |

**Coverage summary**: All ADR-worthy TRs trace to Accepted ADRs. The remaining TRs
are GDD-specified rule/signal/edge-case requirements with no architectural
ambiguity. No untraced requirements.

**At-risk / deferred**:
- **AC26** (save/load re-derive equivalence) — **deferred to Vertical Slice** per
  `milestone-02-mvp-completion.md` Out of Scope. Explicitly excluded from
  criterion #1. Story 005 covers the load-pass *mechanism*; the save-round-trip
  assertion waits for Save/Load.
- **AC36's property corpus** is the milestone's named riskiest test artifact
  (M02 risk R3) — 5,000 cross-implementation verdicts under a 60 s CI ceiling.
  Own story, own time-box, own cut order (reduce sampled pairs before seeds).
- **Region-size cost** (GDD Open Question 5b/5c) is a **documented accepted-risk
  boundary**, not an open decision: the Control Manifest records "Build Validation
  BFS exceeds one frame above ~12k connected cells" (ADR-0007 + spike report).
  The pre-VS spike owns closing it; MVP ships the unbounded, uncached flood-fill.
- **Edge Case 6 (roof-on-pillars "cozy carport")** is an accepted MVP design gap,
  not a defect — AC10 asserts the carport IS a valid room. The wall-coverage
  requirement is the GDD's VS priority #1 (Open Question 1). Do not "fix" it here.

## Milestone 02 Notes — Cluster A head (PROTECTED)

- Delivers criterion **#1** (every Logic AC — AC1–AC35, AC37, AC38 — has a passing
  blocking test), **#2** (the reachability property corpus green in CI ≤ 60 s),
  the analysis half of **#5** (shelter classification is what makes the recovery
  ladder mean anything), and **#7** (`presentation-002`'s scaffolding fires off
  real `room_recognized`/`shelter_status_changed`, with a grep-guard proving no
  placeholder emitter remains).
- **This epic unblocks the payoff chain.** Story 006 (`shelter_status_changed`) is
  the single output Needs & Mood consumes — sequence it as early as its
  dependencies allow, ahead of the presentational stories, so the needs-mood epic
  is not gated on warnings/pacing work it does not need.
- **Cluster A synergy**: room recognition creates the occupancy host the unwired
  chimney-smoke ambient component needs (criterion #8) — scheduling this epic
  early is what makes Cluster B cheap.
- No item in this epic is on the cut lever. Cutting any part requires escalation
  per the milestone's Cut-Lever Policy.

## Known Conflicts With Landed Code — RESOLUTION STATUS (2026-07-26)

> **All five conflicts are now ruled on.** Rulings 1/2/4 are technical-director
> (`production/architecture-decisions-m02-preflight-2026-07-26.md`, items BV-1 /
> BV-2 / BV-4); conflict 5 is creative-director
> (`production/creative-decisions-m02-preflight-2026-07-26.md`, Ruling 2).
> **Both documents are PROVISIONAL, pending user ratification** — binding on story
> authoring once ratified, and the planning assumption until then. Conflict 3 was
> always report-only.

| # | Status | Resolution | Lands in |
|---|--------|-----------|----------|
| 1 | **RESOLVED (BV-1)** | Furniture is **not voxel data** — it never enters `VoxelWorldGrid`. `CellContents` unchanged; a Building-System-owned furniture registry (`building-028`) holds item identity + cells; `ConstructionTickLoop` must exclude `Category.FURNITURE` from `bulk_write` (**blocking AC on `building-028`**). Rule 1 transparency is then satisfied **by construction**, with no branch in Build Validation. | **002 drops the `building-028` dependency entirely** (proof-by-construction test). **006 keeps it for per-item enumeration only** and is developed against a mocked, nil-safe provider. |
| 2 | **RESOLVED (BV-2)** | Single structural trigger = `VoxelWorldGrid.cells_changed_batch`. **Never** `construction_completed` — that signal can name cells whose deferred write has not landed (ADR-0015 load-before-write), so a pass triggered by it would analyse stale data. `cells_changed_batch` is a strict superset (demolition, undo, dig) and page-in is silent. | **005**; adds an AC covering a deferred/paged write. `building-009` no longer owes this module a signal. |
| 3 | Report-only, unchanged | Batching is per-TICK (4.0/s), coarser than per-frame, so AC19's guarantee holds a fortiori — but write the AC19 test against tick dispatches. Owner: producer. | 005 |
| 4 | **RESOLVED (BV-4)** | **Extract a pure static twin.** New `villager-ai-026` extracts `VillagerWalkabilityRules` (static only; the two constants declared there, re-exported as aliases on `VillagerAi`; `VillagerAi`'s methods become one-line delegations). Build Validation calls it **statically**, injects nothing, holds no villager reference. | **001** (smaller DI surface), **002**. **`villager-ai-026` MUST land before story 001.** |
| 5 | **RESOLVED (CD Ruling 2)** | `payoff_signaled` stays **byte-identical**; an additive **optional typed `PayoffDetail` sidecar** carries `celebrate` / `group_id` / `subjects` / `cells`, written **before** the emit. `subject = pass_group_id` for celebrations; shelter is **one** type with the flag in the detail. TD still owns the final implementation form. | **009**; embeds the CD's six assertable minimums as ACs. |

### Original conflict text (retained for traceability)

1. **Furniture occupancy has no representation in the voxel layer.** GDD Rule 1 /
   `TR-022` requires furniture cells to evaluate **as if empty** (never floor,
   wall, or roof). Landed `CellContents` carries only `block_type_id` +
   `material_id` — a built furniture cell would read non-empty, i.e. *solid*, and
   would both count as structure and break `is_standable`'s clearance check.
   `BlueprintCell.Category.FURNITURE` exists but `BlueprintCell.contents` is
   documented as a placeholder. **Build Validation needs an injected
   furniture-occupancy source (`building-028`), not a `CellContents` read.**
   Owner: technical-director + building-system. Blocks story 002's
   furniture-transparency AC and story 006 entirely.
2. **No "construction removed" signal exists.** GDD Rule 7 names *construction
   completed OR built cell removed* as the trigger pair. Landed Building System
   emits only `ConstructionTickLoop.construction_completed(cells)`; demolition is
   `building-009`, not landed. Interim removal trigger is
   `VoxelWorldGrid.cells_changed_batch`. Owner: technical-director. Affects story
   005's trigger wiring.
3. **Batching is per-TICK, not per-FRAME.** The GDD's Interactions section and
   AC19 are written in frames; `construction_completed` fires once per
   `_on_tick()` dispatch (base tick rate 4.0/s). A per-tick batch is *coarser*
   than per-frame, so the "at most one pass per frame" guarantee holds a fortiori
   — but AC19's test must assert against tick dispatches, not frames. Owner:
   producer (recorded); no code change implied.
4. **The shared predicates are instance methods on `VillagerAi`**, a `Node`
   carrying `villager_id`, config, and a `voxel_world` ref — not a standalone
   shared module. Build Validation must inject a `VillagerAi` reference as its
   walkability provider (satisfying "call the same functions"), or a pure static
   twin must be extracted (the codebase already has this precedent:
   `VoxelWorldGrid._pure_terrain_height`, `classify_step_length_cells`).
   `Valley` exposes exactly one via `get_villager_ai()` today; `villager-ai-021`
   (starting roster) changes that. Owner: technical-director. Affects story 001's
   DI shape — **decide before story 001 starts.**
5. **`LoopPayoffSignalSurface` cannot carry the pacing contract.** Its sole signal
   is `payoff_signaled(payoff_type: StringName, subject: StringName)`, and its own
   doc states a new payoff kind is a new `payoff_type` value, *"never a new signal
   or a reshaped parameter list."* Criterion #7 requires `room_recognized`'s
   `celebrate: bool` / `pass_group_id` contract to survive the wiring. Owner:
   technical-director + creative-director (the celebration is a CD-protected
   presentation beat). Blocks story 009's AC shape.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- Every Logic AC from `design/gdd/build-validation-navigability.md` (AC1–AC35,
  AC37, AC38) has a passing blocking test; AC26 is explicitly deferred to VS
- AC36's property corpus is checked in, green, and recorded at **≤ 60 s** in CI
- Grep proves zero `NavigationServer3D`/`NavigationAgent3D`/`NavigationRegion3D`
  and zero duplicated walkability constants in this module
- Mock call-count tests prove the module never blocks a placement (AC25) and never
  calls a villager movement/behavior API (AC33)
- `presentation-002`'s surface fires off real emissions with a passing grep-guard
  that no placeholder emitter remains on the payoff path (criterion #7)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Config resource, DI scaffold & blocking lockstep invariant | Integration | Ready | ADR-0001/0002 |
| 002 | Candidate interior cell predicate (standable + roofed, furniture-transparent) | Logic | Ready | ADR-0007 |
| 003 | Candidate region formation & affected-region scoping | Logic | Ready | ADR-0007 |
| 004 | Outside-connection trace & Room/Sealed verdict | Logic | Ready | ADR-0007 |
| 005 | Analysis pass lifecycle, batched trigger, snapshot & never-blocks guards | Integration | Ready | ADR-0007/0016/0012 |
| 006 | Shelter classification & `shelter_status_changed` | Logic | Ready | ADR-0007 |
| 007 | `room_recognized` continuity & celebration pacing | Logic | Ready | ADR-0007 |
| 008 | Warning/Info tiers, exclusivity & load-pass emissions | Logic | Ready | ADR-0007 |
| 009 | Loop-payoff surface receives real signals (criterion #7) | Integration | Ready | ADR-0001 |
| 010 | AC36 reachability property corpus (criterion #2) | Integration | Ready | ADR-0007 |

**Type totals**: 6 Logic, 4 Integration.

**Dependency order**: **`villager-ai-026`** → 001 → 002 → 003 → 004 → 005 →
**006** → 007 → 008 → 009, with 010 unblocked after 004 and runnable in parallel
with 005–009.

**Needs-decision / flags** (updated 2026-07-26 against the pre-flight rulings):
- **`villager-ai-026` is a new hard prerequisite for 001** — the
  `VillagerWalkabilityRules` extraction (BV-4). Schedule it first.
- **001**: DI shape RESOLVED (BV-4) — call the static twin, inject nothing. The DI
  surface is smaller than originally planned.
- **002**: **no longer blocked on `building-028`** (BV-1) — furniture transparency
  is proven by construction. It can start as soon as 001 does.
- **006**: still needs `building-028` for **per-item enumeration only**, and may be
  developed against a mocked nil-safe provider (BV-1). **Still the payoff-chain
  unblocker for the needs-mood epic; protect its position in the sequence.**
- **005**: trigger RESOLVED (BV-2) — one subscription, simpler than planned; carries
  a new deferred/paged-write AC. Known Conflict 3 (per-tick wording) remains
  report-only.
- **009**: signal shape RESOLVED (CD Ruling 2). **Remaining input**: TD concurrence
  on the implementation form.
- **`building-028` inherits two blocking ACs from BV-1** (not owned by this epic):
  FURNITURE-category completion never `bulk_write`s to the grid; the registry
  exposes a placed/removed signal + item enumeration as a duck-typed, nil-safe
  provider.
- **010**: M02 risk R3, technical-director-owned. Time-box it; if the 60 s ceiling
  is missed, **reduce sampled pairs per seed before reducing seed count**, then
  escalate.

## Next Step

Run `/story-readiness production/epics/build-validation-navigability/story-001-config-and-scaffold.md`,
then `/dev-story` to begin. Work stories in dependency order — each story's
`Depends on:` field lists what must be DONE first. Resolve the five Known
Conflicts above before the stories they block.
