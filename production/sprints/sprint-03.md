# Sprint 3 — Working Days 21–30 (nominal anchor 2026-07-23)

> Duration is expressed in **working days** per the milestone and re-baseline
> (`production/estimates/estimate-rebaseline-2026-07-23.md`). Calendar span depends on
> session cadence. **Calendar note (honest, now twice-confirmed):** Sprint 1 (8 stories)
> and Sprint 2 (9 stories) each landed in a single back-to-back session — measured
> throughput ran far above the 1-story/agent-day planning rate when stories run
> consecutively. The per-story estimate is kept as the *planning anchor*; it is not a
> calendar prediction.
> Review mode: **lean** — PR-SPRINT feasibility gate skipped (`production/review-mode.txt`).

## Sprint Goal

Push all five Foundation tracks toward *epic-close* and open the Core layer: land the
global `tick` signal (the single highest-leverage unlock — every tick-driven Building and
Villager behavior keys off it), the Voxel World bulk-write + DDA-picking primitives that
unlock the mesher tech-debt and the Building placement pick, first camera motion (orbit),
the RID boot-validation pipeline, close the Scene/World Management epic with its
transition-signal contract, and open Villager AI — the highest-complexity Core epic — with
its config/DI/FSM scaffold so its engine risk is surfaced early, not at end-of-milestone.

## Capacity

- **Total days:** 10 working days
- **Buffer (20%):** 2 days reserved — absorbs the +20% wiring/integration overhead and
  unplanned work
- **Available:** 8 days
- **Measured velocity:** ~1 story/agent-day planning anchor
  (`estimate-rebaseline-2026-07-23.md`); Sprints 1–2 delivered 8/8 and 9/9 in single
  sessions — throughput is *not* the binding constraint, the specialist queue is (see Risks).
  Mitigated this sprint by running **three** parallel owner-lanes.
- **Committed:** 9 stories = 8.5 story-days (Must 7.0 + Should 1.5)

Must-Have (7.0 days) fits inside the 8 available with 1.0 to spare. Both Should-Have
stories landing takes the total to 8.5, dipping 0.5 day into the 2-day buffer and leaving
1.5 day intact — the identical margin discipline Sprint 2 committed and delivered. Two
sprints of calibration now stand behind this: both closed 100% at the production bar with
the full suite green, so the fuller commit is evidenced, not speculative.

### Sprint 2 actuals (calibration context)

- **9/9 stories Complete** (spine-004/005, rid-003, tick-002, cam-002, vox-002,
  scene-001, tick-003, scene-002) — including both Should-Have stories.
- **Foundation Spine epic CLOSED (5/5)** — headless boot test green (Milestone
  Success-Criterion #1) and CONTRACTS.md published.
- **Test suite: 121 → 198 passing** headless (GdUnit4) — +77 tests, zero red.
- **Zero unplanned rework, zero carryover.**
- Calendar compression again: the 10 nominal-day plan ran to completion in one session.
  Kept the per-story estimate as the planning anchor.

## Tasks

### Must Have (Critical Path — advance every Foundation track + open Core)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| tick-004 | Tick accumulator + global `tick` signal (drift-free); **AC-6 joint assertion with tick-003 lands here** | `production/epics/time-tick-system/story-004-tick-accumulator-signal.md` | godot-gdscript-specialist | 1 | tick-002 ✓, tick-003 ✓ (both S2 DONE) | Accumulator advances on `game_delta` only; fixed 4.0 ticks/sec cadence drift-free over long runs; zero ticks while paused (joint assert with tick-003 pause state); ticks derive from counts not wall-clock; `_physics_process` step re-verified for 4.7; passing unit test |
| vox-003 | Bulk write + batched signal (per-cell before/after, exactly-one-signal) | `production/epics/voxel-world/story-003-bulk-write-batched-signal.md` | godot-gdscript-specialist | 1 | vox-002 ✓ (S2 DONE) | `bulk_write` applies N cells, emits exactly one `cells_changed_batch` carrying per-cell before/after; partial-failure semantics defined; no torn reads; reads never mutate; passing unit test |
| vox-004 | Neighbor lookup + DDA cell-picking (raycast on the data layer) | `production/epics/voxel-world/story-004-neighbors-and-dda-raycast.md` | godot-gdscript-specialist | 1 | vox-002 ✓ (S2 DONE) | `get_neighbors` 6/26 correct at bounds; DDA grid-walk returns first occupied cell + face along a ray, zero physics colliders; empty-space ray → miss; deterministic; 4.7 raycast math verified; passing unit test |
| rid-004 | Boot validation — per-entry schema checks + structured result | `production/epics/resource-item-database/story-004-boot-validation-schema-checks.md` | godot-gdscript-specialist | 1 | rid-002 ✓ (S1 DONE) | Each definition checked against schema (required fields, typed `visual_asset`, category/tier vocabulary); structured per-entry result accumulated; malformed entry flagged not crashed; no write API touched; passing unit test |
| cam-003 | Orbit rotation — mmb drag + Q/E, pitch clamp | `production/epics/camera-input/story-003-orbit-rotation.md` | godot-specialist | 1 | cam-001 ✓ (S1), cam-002 ✓ (S2) | mmb-drag and Q/E rotate yaw/pitch; pitch clamped to configured range; runs on raw delta (controllable while paused); no hardcoded device id; spherical derivation reused from cam-001; passing integration test/playtest |
| scene-003 | Transition-signal contract surface + transition state machine — **CLOSES the Scene/World Management epic (3/3)** | `production/epics/scene-world-management/story-003-transition-signal-contract-surface.md` | godot-specialist | 1 | scene-002 ✓ (S2 DONE) | `transition_begun()`/`transition_ended(success)` emitted; one-begin→one-complete/abort invariant; state resolves Booting→Active after boot; banned scene APIs grep-zero; consumers (Camera Suspended, Building undo-clear) can bind to it; passing integration test |
| villager-ai-001 | Villager AI config resource + DI scaffold + FSM state enum — **opens the Core layer** | `production/epics/villager-ai-behavior/story-001-config-and-scaffold.md` | ai-programmer | 1 | None (Boot/DI/config spine — Foundation Spine epic DONE) | Injected-tier module wired via DI; tunables (budgets, watchdog thresholds) load from typed `.tres`; FSM state enum defined per GDD; headless-mockable (no Autoload, no file I/O in test); zero nav/thread APIs introduced; passing unit test |

### Should Have (in-sprint dependency chains — the natural cut lever)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| rid-005 | Boot validation — reserved ids, retired ledger, tier-0 coverage, aggregate report + terminal Failed | `production/epics/resource-item-database/story-005-boot-validation-invariants-terminal-halt.md` | godot-gdscript-specialist | 1 | rid-004 (in-sprint — must land first) | Reserved-id + retired-ledger rejection; tier-0 coverage invariant; aggregate report; any Failed → terminal HALT (same severity as config blocking-invariants), zero downstream `setup()`; HALT is non-progression, not `SceneTree.paused`; passing unit test |
| tick-005 | Max-ticks-per-frame safety cap | `production/epics/time-tick-system/story-005-max-ticks-per-frame-cap.md` | godot-gdscript-specialist | 0.5 | tick-004 (in-sprint — must land first) | Per-frame tick count capped at configured max (spiral-of-death guard); dropped-time behavior defined and deterministic; cap value from config; accumulator untouched below the cap; passing unit test |

### Nice to Have (parallel-lane fill — pull only if the godot-specialist camera lane runs ahead)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| cam-004 | Zoom — multiplicative, clamped, rapid-safe | `production/epics/camera-input/story-004-multiplicative-zoom.md` | godot-specialist | 1 | cam-001 ✓, cam-002 ✓ | Multiplicative zoom clamped to range; rapid input safe (no overshoot/NaN); raw-delta; passing unit test |
| cam-005 | WASD pan — yaw-relative, distance-scaled, bound + delta clamp | `production/epics/camera-input/story-005-wasd-pan.md` | godot-specialist | 1 | cam-001 ✓, cam-002 ✓ | Yaw-relative pan, distance-scaled, bound to world; per-frame delta clamped; raw-delta; passing unit test |

> The camera-motion trio (cam-003 Must + cam-004/cam-005 Nice) together make the camera
> fully controllable and are the exact prerequisites for cam-007 (Active/Suspended). The
> godot-specialist lane carries only 2 Must-days (cam-003 + scene-003); if it clears early,
> cam-004/005 are the highest-value pull because they are fully independent (deps cam-001/002
> only) and unblock the camera Suspended state that Building System's tool state machine
> (building-019) needs before it can open in Sprint 4.

## Core-Layer Decision — open with Villager AI (villager-ai-001), NOT Building System (building-019)

**Decision: open the Core layer this sprint with `villager-ai-001` (config + DI scaffold +
FSM enum). Defer `building-019` (tool state machine) to Sprint 4.** Rationale:

1. **Dependency readiness (verified against the real story files):** `villager-ai-001`
   `Depends on: None` — it needs only the Boot/DI/config spine, and the Foundation Spine
   epic is CLOSED. `building-019` `Depends on: Camera & Input (action signals, **Suspended
   state**)`. Action signals (cam-002) are DONE, but the camera **Suspended state (cam-007)
   is not** — and cam-007 depends on cam-003/004/005/006, which are not all landing this
   sprint. The tool state machine's `Suspended` micro-state binds to that. building-019's
   dependency is therefore **not cleanly satisfiable in Sprint 3**.
2. **Milestone sequencing + Building System's own gate:** the Building System EPIC states it
   "depends on all five Foundation systems being integrated first." Foundation is not yet
   fully closed (Voxel mesher/residency and Camera motion still open). Villager AI's opener
   needs nothing but the spine.
3. **Risk front-loading:** Villager AI is the highest-complexity, highest-engine-risk Core
   epic (25 stories, HIGH — manual `AStar3D` graph management; **`AStarGrid3D` does not exist
   in 4.7**). Opening it now with a pure low-risk scaffold surfaces that setup early and
   mirrors the proven Sprint-1 track-opener pattern (tick-001/cam-001/vox-001 were exactly
   this shape).
4. **Parallelism:** routing villager-ai-001 to **ai-programmer** opens a *third* owner-lane,
   directly cutting the single-specialist serialization risk instead of lengthening the
   gdscript-specialist queue.

`building-019` becomes the natural Sprint-4 Core opener once cam-003/004/005/007 (camera
Suspended) land and this sprint's vox-004 DDA pick is available for its placement pick (020).

## Critical Path

**`tick-004`** is the single highest-leverage story: the global `tick` signal is what
Building System's construction loop (story-029) and Villager AI's deciding scheduler
(story-005) drive their simulation off — the entire Core layer's timing depends on it.
Sequence it first on the gdscript lane. **`vox-003` + `vox-004`** are the secondary critical
pair: they unlock the mesher CW-winding tech-debt (vox-007 uses `get_neighbors`) and the
Building placement pick (DDA) — both Must-Ship milestone items. They depend only on vox-002
(DONE) and on each other not at all, so they parallelize cleanly.

**Owner lanes (serialization mitigation):**
- **godot-gdscript-specialist:** tick-004 → vox-003 → vox-004 → rid-004 (+ rid-005, tick-005) — the binding lane (~5 story-days with Should)
- **godot-specialist:** cam-003 → scene-003 (+ cam-004/005 Nice) — 2 Must-days, headroom for the Nice pulls
- **ai-programmer:** villager-ai-001 — 1 day, deliberately a single-story open (do not overload a newly-opened epic)

In-sprint chains to sequence parents-first: **rid-004 → rid-005**, **tick-004 → tick-005**.
Each chain's child is a Should-Have and is the pre-designated cut if its parent runs hot.

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| None | Sprint 2 delivered 9/9 — no carryover, zero unplanned rework | — |

## Out of Scope (deferred to Sprint 4+)

- **tick-006 (cross-system integration guarantees), tick-007 (per-tick re-tune)** — tick-006
  depends on tick-004 (in-sprint) but is an integration guarantee consumed by the E2E LOOP
  test (needs the integrated build); tick-007 needs the integrated build + the Villager AI
  re-tune half + a designer decision. Both Sprint 4+.
- **rid-006 (visual-asset validation), rid-007 (missing_item fallback), rid-008 (footprint),
  rid-009 (MVP content)** — rid-006/008 chain off rid-004; rid-007 needs rid-005; rid-009 is
  content. The validation *mechanism* (rid-004/005) is this sprint's need; content + the
  remaining checks are Sprint 4.
- **cam-006 (world-ray API), cam-007 (Active/Suspended), cam-008 (click arbitration),
  cam-009 (raw-delta/pause contract)** — cam-006 (Building DDA-pick consumer) and cam-007
  (needs the full motion trio) follow the motion stories; Sprint 4.
- **vox-005–017 (iterate_occupied, terrain gen, mesher CW-winding, floor/dig write paths,
  residency tier, ADR-0015 C1/C4)** — the mesher rewrite (vox-007, TECH DEBT 1) and residency
  tuning (vox-016/017, TECH DEBT 3) are Sprint 4 targets; they need vox-003 (batched write)
  and vox-006 (terrain has geometry to mesh) first, both sequenced from this sprint's storage.
- **Building System (all 33 stories)** — opens Sprint 4 with building-019 once camera Suspended
  (cam-007) and the DDA pick (vox-004, this sprint) are available. See Core-Layer Decision.
- **villager-ai-002+ (walkability, occupancy, AStar3D, FSM behaviors)** — follow the scaffold
  (villager-ai-001) opened this sprint; Sprint 4+.
- **CD-protected items (ambient-life wave 1, loop-payoff scaffolding)** — Presentation/environment
  work with no Foundation/Core module (epics index §CD-item mapping gap); scheduled against the
  Presentation pass, surfaced at the Sprint-3-start milestone review per the review schedule.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **Single-specialist serialization** — 6 of 9 stories route to `godot-gdscript-specialist`; the ~1/day anchor assumes parallel agents, a single queue serializes wall-clock | Medium | Low-Med | Three parallel owner-lanes this sprint (gdscript / godot-specialist / **ai-programmer**), up from two in Sprint 2. The gdscript lane (~5 story-days) is the binding constraint; the 2-day buffer absorbs residual; both Should-Have chain-children are droppable without touching the critical path. |
| **NEEDS-DECISION on scene-001 (main-menu boot-flow)** — straight-to-Valley (GDD) vs. MainMenu state (approved main-menu.md, Alpha-tier); needs ADR-0012 amendment. scene-003 now *closes* the epic while this remains open | High (unresolved) | Low for M01 | Does NOT block M01 — the epic ships boot-straight-to-Valley as written. Resolution owner: **technical-director**, before the Main Menu ships (Alpha). Carried forward from Sprints 1–2 so it is not lost when the epic closes. |
| **Godot 4.7 API deviation** — vox-004 (DDA raycast, **HIGH** rendering/picking domain) and tick-004 (`_physics_process` fixed-step must still be 60Hz for the accumulator) touch flagged post-cutoff facts | Medium | Med | Every API cross-referenced against `docs/engine-reference/godot/` before use, enforced per story Engine Notes. vox-004 carries the sprint's only HIGH engine-risk — sequence it with buffer headroom, not on the last day. CONTRACTS.md (now published) reduces the *contract*-onboarding half of this risk. |
| **In-sprint dependency chains** — rid-005←004, tick-005←004; a parent slip strands the child | Medium | Low | Sequence parents first (rid-004, tick-004 early — both Must); if a parent runs hot, its Should-Have child is the pre-designated cut. |
| **Core epic engine risk surfaces late** — Villager AI (HIGH; no `AStarGrid3D` in 4.7, manual `AStar3D`) is the milestone's riskiest epic | Medium | Med | Open it THIS sprint with a low-risk scaffold (villager-ai-001) so the setup/config/DI shape is proven early rather than at end-of-milestone. Assigned to the domain owner (ai-programmer). |
| **Milestone scope vs. estimate** — M01 is budgeted ~22 working days / ~3 sprints, but the Foundation + Core epics carry ~100 stories (many VS-tier/M02, but the M01-scoped subset still far exceeds 3 sprints at ~9 stories/session). Sprint 3 is the *pre-milestone review* point per the schedule | Medium | Med | **Producer flag:** run `/milestone-review current` at Sprint 3 start (already on the review schedule) to re-baseline M01 scope vs. duration and confirm which epic stories are truly M01 vs. deferred. This sprint plan does not resolve it — it surfaces it for the milestone review. |
| **Recurring typed-Array crash class** (0 in Sprint 1, 0 in Sprint 2) | Low | Low | Keep the regression call in the E2E gate; preview paths deliberately untyped; budgeted inside buffer. Two clean sprints — retained but low. |
| **CONTRACTS.md now published (spine-005 DONE)** — *risk reducer, not a risk* | — | — | The four spine contracts (DI/Config/Boot/Data-Definition) plus the accumulated GdUnit4/engine pitfalls documented in CONTRACTS.md materially reduce onboarding risk for the RID validation stories and the Core-layer opener. |

## Dependencies on External Factors

- **Control-manifest version 2026-07-23** — all Sprint 3 stories embed this version. Confirmed
  current for Sprints 1–2; re-confirm unchanged before tick-004 starts. Owner: technical-director.
- No art/audio external dependency for the committed set (Foundation logic + scene contract +
  Villager AI scaffold; no assets consumed). CD-protected experience items remain unplaced
  (epics index §CD mapping gap) — surface at the Sprint-3-start milestone review, do not silently defer.

## Definition of Done for this Sprint

- [ ] All Must Have stories completed (Scene/World Management epic closed: scene-003 lands 3/3)
- [ ] All tasks pass acceptance criteria
- [ ] Every Logic story (tick-004, tick-005, vox-003, vox-004, rid-004, rid-005, villager-ai-001)
      has a passing GdUnit4 headless unit test in `neues-spiel/tests/unit/...` — BLOCKING
- [ ] Every Integration story (cam-003, scene-003) has a passing headless integration
      test in `neues-spiel/tests/integration/...` — BLOCKING
- [ ] Tests deterministic, isolated, DI-mockable (no Autoload registration, no file I/O)
- [ ] QA plan exists for Sprint 3 (`production/qa/qa-plan-sprint-3-*.md`) — run `/qa-plan sprint`
      before implementation begins (none exists yet — see warning below)
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No open S1 or S2 bugs in delivered stories
- [ ] Design/ADR docs updated for any deviation discovered during implementation
- [ ] Code reviewed and merged (trunk-based)

> ⚠️ **No QA Plan**: This sprint was planned without a Sprint-3 QA plan (only sprint-1 and
> sprint-2 QA plans exist). Run `/qa-plan sprint` before the last story is implemented. The
> Production → Polish gate requires a QA sign-off report, which requires a QA plan.

## Notes

- **Dependencies-satisfied check:** every Sprint-3 story was verified against its real story
  file's `## Dependencies` section (not the request list). All Must-Have external dependencies
  resolve to Sprint-1/2 DONE stories; all in-sprint dependencies (rid-005←004, tick-005←004) are
  sequenced within this sprint. building-019 was **rejected** for Sprint 3 because its
  Camera-Suspended dependency (cam-007) is not satisfiable this sprint — see the Core-Layer
  Decision. No unsatisfied dependency in the committed set.
- **Scope check:** all 9 committed stories are drawn from existing epics with no additions
  beyond epic scope. Run `/scope-check sprint-3` before implementation if any story grows.
- **Milestone review due:** the review schedule places the pre-milestone review + CD check on
  protected items at Sprint 3 start. Run `/milestone-review current` — it also addresses the
  milestone-scope-vs-estimate risk flagged above.
- **Next step:** run `/qa-plan sprint` to define test cases per story before `/dev-story`.
