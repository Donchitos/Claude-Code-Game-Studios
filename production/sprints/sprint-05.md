# Sprint 5 — Working Days 41–50 (nominal anchor 2026-07-25)

> Duration is expressed in **working days** per the milestone re-baseline
> (`production/estimates/estimate-rebaseline-2026-07-23.md`). Calendar span depends on
> session cadence. **Calendar note (four-times-confirmed):** Sprints 1–4 each landed their full
> commit in single back-to-back sessions (8/8, 9/9, 9/9, 8/8) — measured throughput ran far above
> the 1-story/agent-day planning rate. The per-story estimate is kept as the *planning anchor*;
> it is not a calendar prediction.
> Review mode: **lean** — PR-SPRINT feasibility gate skipped (`production/review-mode.txt`).
>
> **This sprint opens the Core layer at scale and the ADR-0015 residency cluster.** With the
> mesher critical chain retired in S4 (vox-007 CW+culling landed, mesher criterion #3 now MET
> pending formal signoff; camera COMPLETE through cam-007 Suspended), the milestone-review
> Condition-1 second half — the **ADR-0015 residency cluster** — opens here, and the two hardest
> Core epics (Building, Villager AI) start their real functional stories. This is the sprint where
> the milestone's remaining risk concentration shifts from the mesher to fresh residency
> production code (see Risks).

## Sprint Goal

Open the two hardest Core epics on now-DONE Foundation and stand up the ADR-0015 residency tier:
land the **Building System opener** (building-019 tool state machine on the DONE cam-007 Suspended
state, then building-020 DDA placement pick on cam-006 ray + vox-004 DDA); stand up the **paged
region-file residency** (vox-010) and its **async I/O** (vox-011), the ADR-0015 cluster the spike
de-risked; advance **Villager AI** with its first spatial-logic story, **body-column occupancy**
(villager-ai-003); and — capacity permitting — extend each chain (residency time-budget vox-012,
deterministic position villager-ai-004) and close the CD-protected **loop-payoff scaffolding half**
(presentation-002, milestone criterion #10).

## Capacity

- **Total days:** 10 working days
- **Buffer (20%):** 2 days reserved — absorbs the +20% wiring/integration overhead, the residency
  cluster's fresh-production-code risk, and unplanned work
- **Available:** 8 days
- **Measured velocity:** ~1 story/agent-day planning anchor
  (`estimate-rebaseline-2026-07-23.md`); Sprints 1–4 delivered 8/8, 9/9, 9/9, 8/8 in single
  sessions — throughput is *not* the binding constraint, the specialist queue is (see Risks).
  Mitigated by running **three** parallel owner-lanes.
- **Committed:** 8 stories = 9.0 story-days (Must 6.0 + Should 3.0)

Must-Have (6.0 days) fits inside the 8 available with 2.0 to spare — headroom deliberately left on
the binding-risk lane (residency) for the fresh production-code risk. All three Should-Have stories
landing takes the total to 9.0, dipping 1.0 day into the 2-day buffer and leaving 1.0 intact. This
is a slightly tighter Should margin than S4 (which left 1.5) — deliberate, because the risk this
sprint sits in the Must set (residency), so the Should stories are the true cut levers and the
buffer is reserved for the Must lane, not the Should.

### Sprint 4 actuals (calibration context)

- **8/8 stories Complete** (vox-006, vox-007, vox-005, cam-004, cam-005, villager-ai-002, + Should
  cam-006, cam-007) — including both Should-Have stories; vox-008 (Nice) was not pulled.
- **The voxel world renders:** vox-007 chunked mesher landed **CW-winding + backface-culling ENABLED**
  with parent-inspected screenshot evidence — mesher tech-debt #1 retired, exit criterion #3 now
  **MET pending formal signoff**. **Camera epic COMPLETE through cam-007** (Active/Suspended state),
  so **building-019's Suspended-state dependency is now DONE as planned** — the clean S5 opener the
  S4 plan sequenced for.
- **Test suite: 311 → 421 passing** headless (GdUnit4), zero red.
- **Zero unplanned rework, zero carryover.** The windowed feel check demonstrated (orbit/zoom/pan
  around rendered terrain).

## Tasks

### Must Have (Critical Path — open Core at scale + stand up ADR-0015 residency)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| vox-010 | **Region-file paged residency — opens the ADR-0015 cluster** | `production/epics/voxel-world/story-010-region-file-paged-residency.md` | godot-gdscript-specialist | 1.5 | vox-002 ✓ (S2 DONE); injected camera focus point (stubbable in isolated tests) | Region format read/write round-trips losslessly; resident set paged in/out around an injected focus point; out-of-window regions evicted without corrupting committed cell state; deterministic; passing integration test. Spike (`prototypes/storage-residency-spike/`, incl. `regions_real_*/`, `regions_stress_*/`) is **reference only** — production code written fresh to ADR-0015 |
| vox-011 | Async region I/O — WorkerThreadPool off-main-thread load/save | `production/epics/voxel-world/story-011-async-region-io-workerpool.md` | godot-gdscript-specialist | 1.5 | vox-010 (in-sprint — must land first), vox-006 ✓ (S4 DONE) | Region load/save runs off the main thread; results integrated on the main thread only (no torn reads of committed state); far-region terrain-gen runs async; no frame-time spike on page-in; **WorkerThreadPool/FileAccess APIs cross-referenced against `docs/engine-reference/godot/` (post-cutoff, HIGH engine-risk)**; passing integration test |
| building-019 | **Tool state machine — THE Building System opener** | `production/epics/building-system/story-019-tool-state-machine.md` | godot-specialist | 1 | Camera & Input action signals (cam-002 ✓) + **Suspended state (cam-007 ✓, S4 DONE)** | Tool SM transitions across idle/armed/placing; Suspended (cam-007) freezes tool dispatch (AC37: Suspended mid-drag → drag aborts, now testable because cam-007 exists); config-driven, no inline literals; passing unit test |
| building-020 | DDA placement pick — screen ray → voxel cell | `production/epics/building-system/story-020-dda-placement-pick.md` | godot-specialist | 1 | building-019 (in-sprint — must land first), `get_world_ray()` (cam-006 ✓, S4 DONE), `raycast_cells()` (vox-004 ✓ DDA, S3 DONE) | Screen point resolves to a placement cell via camera ray + voxel DDA; consistent origin/direction same frame; never mutates voxel state (pick is read-only); passing integration test |
| villager-ai-003 | Body-column occupancy / clearance — **first Villager spatial-logic story** | `production/epics/villager-ai-behavior/story-003-body-column-clearance.md` | ai-programmer | 1 | villager-ai-002 ✓ (walkability predicates + clearance constant, S4 DONE) | Body-column reads the shared clearance constant (no second copy); occupancy of the villager's column computed over Voxel World data; Planned blueprint cells treated per the predicate contract; pure/side-effect-free; passing unit test |

### Should Have (extend each chain — the natural cut levers)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| vox-012 | Time-based streaming budget — per-frame page-in cap | `production/epics/voxel-world/story-012-time-based-streaming-budget.md` | godot-gdscript-specialist | 1 | vox-010 + vox-011 (in-sprint) | Page-in/out work bounded by a per-frame time budget (data-driven); async results (vox-011) drained within budget; no frame overrun on burst focus movement; passing unit test. Depth-3 in-lane chain — cut lever if the residency lane runs hot |
| villager-ai-004 | Deterministic position model | `production/epics/villager-ai-behavior/story-004-deterministic-position-model.md` | ai-programmer | 1 | villager-ai-001 ✓ (scaffold), villager-ai-003 (in-sprint — reads current_cell) | Position model is deterministic and order-independent (ADR-0009 foundation); reads body-column current_cell (villager-ai-003); no float nondeterminism in the authoritative position; passing unit test. Depth-2 chain — same shape as S3's rid-004→005 |
| presentation-002 | Loop-payoff communication scaffolding (CD-protected — **closes exit criterion #10's scaffolding half**) | `production/epics/presentation-experience/story-002-loop-payoff-communication-scaffolding.md` | godot-specialist | 1 | `foundation-spine` ✓ (DI + typed-signal contract, CLOSED S2) — **only hard dep, DONE** | The *surface* only (not the mechanic): warm-light reward-feedback cue/hook layer wired to the typed-signal contract, ready for the Feature-layer loop-payoff mechanic (M02) to bind. **CD-protected — cutting requires CD sign-off.** Passing interaction/smoke evidence |

### Nice to Have (parallel-lane fill — pull only if a lane clears early)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| building-021 | Commit pipeline — placement → committed cells | `production/epics/building-system/story-021-commit-pipeline.md` | godot-specialist | 1 | building-020 + building-019 (in-sprint) | Only pull if the building lane clears 019+020 with headroom. Depth-3 in-lane chain — do NOT pull if it would crowd building-020's landing. |
| vox-015 | Mesh view-window streaming — **unlocks the #12 60-FPS-with-culling measurement** | `production/epics/voxel-world/story-015-mesh-view-window-streaming.md` | godot-gdscript-specialist | 1 | vox-007 ✓ (mesher, S4 DONE), vox-010 + vox-012 (in-sprint) | Only pull if the residency chain (010→011→012) fully clears. Depth-4 in-lane chain — honest late link. Once it lands, exit criterion #12 (60 FPS on the production window with culling) becomes **measurable** (a streamed view-window is the scale at which #12 is meaningfully profiled). |
| tick-006 | Cross-system integration guarantees | `production/epics/time-tick-system/story-006-cross-system-integration-guarantees.md` | godot-gdscript-specialist | 0.5 | tick-003 ✓ + tick-004 ✓ (both DONE) | Small filler — pull if the gdscript lane clears. Integration guarantee consumed by the milestone E2E LOOP test; advances Time & Tick toward epic-close (5/7 → 6/7). |

## Critical Path

**The ADR-0015 residency cluster (`vox-010 → vox-011 → vox-012`)** is this sprint's risk
concentration and the milestone-review Action-Item-#1 second half. Sequence **vox-010 FIRST** on the
gdscript lane — its only dependency (vox-002) is DONE and green, and the `storage-residency-spike`
prototype (active in the working tree, now with `regions_real_32/64` and `regions_stress_32/64`
fixtures) has de-risked the *architecture*. The **production code is fresh**, so keep vox-010 early
and never on the last day; vox-011 (async) and vox-012 (budget) chain behind it.

**The Building System opens cleanly** exactly as the S4 plan sequenced: building-019's Suspended-state
dependency (cam-007) landed DONE in S4, so building-019 is a true unblock (not the fake depth-5 chain
S4 correctly refused). building-019 → building-020 is a **depth-2 in-sprint chain** — the proven shape
S1–S3 ran (rid-004→005, tick-004→005) and S4 ran (cam-006→cam-007). building-021 is deliberately held
to Nice-to-have to keep the Building Must set at the proven depth-2, not a depth-3 first outing.

**Owner lanes (serialization mitigation):**
- **godot-gdscript-specialist** (ADR-0015 residency — the risk lane): vox-010 → vox-011 (Must) →
  vox-012 (Should) → vox-015 (Nice, only if the chain clears) → tick-006 (Nice filler)
  (~3.0 Must story-days; kept focused so vox-010 carries buffer headroom, not a queue)
- **godot-specialist** (Building opener + CD scaffolding): building-019 → building-020 (Must) →
  presentation-002 (Should) → building-021 (Nice) — ~3.0 Must+Should story-days
- **ai-programmer** (Villager Core logic): villager-ai-003 (Must) → villager-ai-004 (Should) —
  a depth-2 chain, ~2 story-days

In-sprint chains to sequence parents-first: **vox-010 → vox-011 → vox-012 (→ vox-015)**;
**building-019 → building-020 (→ building-021)**; **villager-ai-003 → villager-ai-004**. Every child's
parent is in the same lane and sequenced ahead of it.

## Core-Layer note — building-019 is now a REAL unblock (contrast with S4)

S4 correctly *refused* to open Building with building-019 because its Suspended-state dependency
(cam-007) was only *landing* that sprint (a depth-5 fake unblock). **That dependency is now DONE**
(cam-007 Complete, S4). building-019 therefore opens this sprint as a genuine unblock with all
dependencies satisfied at sprint start — exactly the deliberate, documented sequencing S4 set up.
The Building Must set is held to the opener + pick (019+020, depth-2); the commit pipeline (021) and
validity (022) follow as Nice/next-sprint, so the largest Core epic ramps up on a proven chain shape
rather than a deep first outing.

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| None | Sprint 4 delivered 8/8 — no carryover, zero unplanned rework | — |

*(vox-008, an S4 Nice-to-have, was never committed there — it remains available as a future
voxel-world write-path story, not carried-over incomplete work.)*

## Out of Scope (deferred to Sprint 6+)

- **tick-007 (per-tick re-tune pass — milestone criterion #4)** — **NOT sequenceable this sprint.**
  Its real story file `Depends on: Stories 001–006 DONE + the integrated build existing (S3) + the
  villager max_deciding_per_tick re-tune coordination + a systems-designer/game-designer decision on
  the values`. The re-tune is explicitly *against production load* — but the **integrated E2E LOOP
  build does not exist yet** (criterion #8 unstarted; Building + Villager only *open* this sprint,
  they do not yet form a loop). You cannot re-tune against a production load that has not been built.
  tick-006 (its parent) is pulled as a Nice filler this sprint; tick-007 defers to Sprint 6, after a
  minimal integrated loop exists to measure against.
- **building-022 (placement validity)** and **building-023+ (tools)** — follow the commit pipeline
  (021); the Building epic ramps across S5–S6. This sprint commits the opener + pick only.
- **villager-ai-005+ (deciding scheduler, AStar3D, FSM behaviors, anti-stuck watchdog)** — follow the
  body-column + deterministic-position primitives opened this sprint; Sprint 6+.
- **Integrated E2E LOOP test (criterion #8)** — cannot begin until a *minimal* Building placement +
  Villager movement loop exists. This sprint opens both epics but does not complete the loop; the E2E
  LOOP remains the milestone's true completion signal, targeted once the Building commit pipeline and
  Villager movement/FSM stories land (Sprint 6). Flagged, not silently deferred.
- **presentation-001 (ambient-life wave 1, CD-protected)** — dependency-gated behind the villager
  FSM/movement stories (not yet landed); scheduled for the Presentation pass alongside the villager
  behaviors. presentation-002 (scaffolding, spine-only dep) is pulled forward this sprint as a Should.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **ADR-0015 residency cluster is the new HIGH-risk concentration** — vox-010→011→012 is fresh production code on a paged-region-file architecture the spike de-risked but never shipped to production standards; async I/O (vox-011) touches post-cutoff Godot APIs (WorkerThreadPool/FileAccess) | High (by design — this is the milestone's remaining top risk moving off the mesher) | High if it slips | **Spike is reference, not ported** — production code written fresh to ADR-0015 (`prototypes/storage-residency-spike/` incl. `regions_real_*/`, `regions_stress_*/` fixtures de-risk the format/eviction logic). vox-010's only dep (vox-002) is DONE + green; sequence vox-010 EARLY, never last day; gdscript Must lane kept to 3.0 story-days so vox-010 carries buffer headroom. vox-012/015 are Should/Nice — the cut levers if the lane runs hot. |
| **Async I/O engine-risk** — vox-011 uses WorkerThreadPool + FileAccess return types, both flagged post-cutoff (4.4 FileAccess changes, threading model); the LLM's ~4.3 knowledge does not cover them | Medium | Med-High | Every threading/file API cross-referenced against `docs/engine-reference/godot/` before use, enforced per story Engine Notes. Main-thread-only integration of results asserted (no torn reads of committed state — the same serialization-invariant discipline vox-005 shipped). vox-011 is the sprint's only HIGH engine-risk — scheduled behind vox-010 with buffer, not on the last day. |
| **Building chain length** — the Building epic's natural chain is 019→020→021→022 (depth-4); a first-outing deep chain landing all in one sprint would over-load the Building lane | Medium | Med | **Must set held to depth-2 (019→020)** — the proven shape S1–S4 all ran. building-021 (depth-3) is Nice-to-have (pull only if 019+020 clear); building-022 is out-of-scope. The largest Core epic ramps on a proven chain shape, not a deep first outing. |
| **E2E integration (criterion #8) still unstarted** — the integrated build→workers-build→villagers-navigate LOOP cannot begin until Building + Villager minimally loop; this sprint *opens* both epics but does not close the loop | Medium (schedule visibility) | Med | Deliberate and milestone-visible: #8 is the milestone's true completion signal and targets Sprint 6 once the Building commit pipeline (021) and Villager movement/FSM land. tick-007 (#4 re-tune) is correctly deferred with it (can't re-tune against a load that isn't built). Not a silent slip — stated in Out of Scope + milestone Action Item #4. |
| **Single-specialist serialization** — the gdscript residency lane is the binding lane at ~3.0 Must story-days (vox-010/011); the ~1/day anchor assumes parallel agents, a single queue serializes wall-clock | Medium | Low-Med | Three parallel owner-lanes (gdscript / godot-specialist / ai-programmer). vox-012/015/tick-006 are Should/Nice — the cut levers if the residency lane runs hot; the Must set (vox-010/011 only, 3.0d) fits comfortably. The 2-day buffer absorbs residual and is reserved for this Must lane. |
| **In-sprint chains** (vox-010→011→012, building-019→020, villager-003→004) — a parent slip strands its children | Medium | Low | Sequence parents-first within each lane; the deepest Must chain is depth-2 (building-019→020, villager-003→004) — the proven S1–S4 shape. vox-012 (depth-3) and vox-015 (depth-4) are Should/Nice, so the deep links carry no Must commitment. |
| **CD-protected presentation-002** — schedule pressure could push the loop-payoff scaffolding out; it is Should-Have | Medium | Medium | Its only hard dep (foundation-spine) is DONE, so it is technically unblocked and small (1d). Marked Should and **cut only with CD sign-off** — surfaced here and in sprint status so it is never silently deferred (milestone Action Item #3). |
| **Recurring typed-Array crash class** (0 in S1–S4) | Low | Low | Keep the regression call in the E2E gate; residency page-in/out and building commit paths watched; budgeted inside buffer. Four clean sprints — retained but low. |

## Dependencies on External Factors

- **Control-manifest version 2026-07-23** — all Sprint 5 stories embed this version. Confirmed
  current for Sprints 1–4; re-confirm unchanged before vox-010 starts. Owner: technical-director.
- **No art/audio external dependency** for the committed set (residency tier + Building logic + first
  Villager spatial story). presentation-002 is scaffolding wired to the typed-signal contract — it
  needs the Art-Bible-approved cue/hook spec (§5.6, APPROVED 2026-07-23), not new art assets. No
  external dependency blocks Sprint 5.
- **Systems-designer/game-designer value decision** for tick-007 (per-tick re-tune) — a prerequisite
  that, together with the not-yet-built integrated loop, keeps tick-007 out of scope this sprint.

## Definition of Done for this Sprint

- [ ] All Must Have stories completed (residency tier stands up: vox-010 + vox-011 green; Building
      opens: building-019 + building-020 green; Villager advances: villager-ai-003 green)
- [ ] All tasks pass acceptance criteria
- [ ] Every Logic story (building-019, villager-ai-003, + Should villager-ai-004) has a passing
      GdUnit4 headless unit test in `neues-spiel/tests/unit/...` — BLOCKING
- [ ] Every Integration story (vox-010, vox-011, building-020, + Should vox-012) has a passing
      headless integration test in `neues-spiel/tests/integration/...` — BLOCKING
- [ ] Async I/O (vox-011) asserts main-thread-only integration of committed state (no torn reads),
      and all threading/file APIs are confirmed against `docs/engine-reference/godot/` — BLOCKING
- [ ] Tests deterministic, isolated, DI-mockable (no Autoload registration, no real file I/O in unit
      tests — residency I/O tests use temp/injected paths and tear down)
- [ ] presentation-002 (if landed) has interaction/smoke evidence in `production/qa/evidence/`
- [ ] QA plan exists for Sprint 5 (`production/qa/qa-plan-sprint-5-*.md`) — run `/qa-plan sprint`
      before implementation begins (none exists yet — see warning below)
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No open S1 or S2 bugs in delivered stories
- [ ] Design/ADR docs updated for any deviation discovered during implementation (esp. any residency
      finding that should amend ADR-0015 — this cluster moves ADR-0015 toward Accept)
- [ ] Code reviewed and merged (trunk-based)

> ⚠️ **No QA Plan**: This sprint was planned without a Sprint-5 QA plan. Run `/qa-plan sprint` before
> the last story is implemented. The Production → Polish gate requires a QA sign-off report, which
> requires a QA plan. vox-010/011's residency-invariant and async-torn-read conditions in particular
> need their pass conditions defined up front.

## Notes

- **Dependencies-satisfied check:** every Sprint-5 committed story was verified against its real story
  file's `## Dependencies` section (not the request list). vox-010 → vox-002 (S2 DONE) + stubbable
  camera focus; vox-011 → vox-010 (in-sprint) + vox-006 (S4 DONE); building-019 → cam-002 (S2 DONE) +
  cam-007 (S4 DONE); building-020 → building-019 (in-sprint) + cam-006 (S4 DONE) + vox-004 (S3 DONE);
  villager-ai-003 → villager-ai-002 (S4 DONE); vox-012 → vox-010/011 (in-sprint); villager-ai-004 →
  villager-ai-001 (S3 DONE) + villager-ai-003 (in-sprint); presentation-002 → foundation-spine
  (CLOSED S2). **tick-007 was REJECTED** for Sprint 5 — it requires the not-yet-built integrated loop
  and a designer value decision (see Out of Scope). **building-021/022 held to Nice/out-of-scope** to
  keep the Building Must set at proven depth-2. No unsatisfied dependency in the committed set.
- **Scope check:** all 8 committed stories are drawn from existing epics (voxel-world, building-system,
  villager-ai-behavior, presentation-experience) with no additions beyond epic scope. Run
  `/scope-check sprint-5` before implementation if any story grows (vox-010/011 residency is the one
  to watch — storage tiers have historically expanded).
- **Milestone recalibration (Action Item #4):** this sprint lands the first Building + Villager
  *functional* stories and the residency cluster — the first true Core-velocity measurement point the
  milestone review flagged. Re-baseline the M01 calendar estimate once vox-010/011 + building-019/020
  + villager-ai-003 land. Owner: producer.
- **Milestone-criteria coverage this sprint:** #5 residency tuning (vox-010/011, +vox-012 Should),
  #6 Building playable (building-019/020 open it), #7 Villager AI playable (villager-ai-003, +004
  Should), #10 loop-payoff scaffolding half (presentation-002 Should), #12 60-FPS-with-culling
  *measurability* (vox-015 Nice). #3 mesher now MET pending formal signoff (S4). #4 per-tick re-tune
  and #8 E2E LOOP remain honestly deferred to S6 (integrated loop must exist first).
- **Next step:** run `/qa-plan sprint` to define test cases per story (especially vox-010/011's
  residency-invariant + async-torn-read pass conditions) before `/dev-story`.
