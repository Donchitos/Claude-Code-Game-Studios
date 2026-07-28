# Sprint 6 — Working Days 51–60 (nominal anchor 2026-07-25) — THE INTEGRATION SPRINT

> Duration is expressed in **working days** per the milestone re-baseline
> (`production/estimates/estimate-rebaseline-2026-07-23.md`). Calendar span depends on session
> cadence. **Calendar note (five-times-confirmed):** Sprints 1–5 each landed their full commit in
> single back-to-back sessions (8/8, 9/9, 9/9, 8/8, 8/8) — measured throughput ran far above the
> 1-story/agent-day planning rate. The per-story estimate is the *planning anchor*, not a calendar
> prediction.
> Review mode: **lean** — PR-SPRINT feasibility gate skipped (`production/review-mode.txt`).
>
> **This is the sprint the milestone has been sequencing toward since the M01 review: make the
> integrated E2E LOOP LIVE.** Sprint 5 opened both hard Core epics (Building through building-020,
> Villager through the position model) and stood up + closed the ADR-0015 residency cluster
> (vox-010/011/012). Nothing has yet *assembled* those systems into one playable scene. This sprint
> wires grid + mesher + camera + building + villager into GameWorld and proves the loop headlessly:
> **place a block via the pick pipeline AND a villager walks.** That assembly — milestone exit
> criterion **#8**, the milestone's true completion signal — is this sprint's crown.

## Sprint Goal

Make the build-and-inhabit loop live in one assembled build: stand up the **minimal placeable-block
path** (building-021 commit → building-029 construction-tick Voxel World write) and the **minimal
walking-villager path** (villager-ai-005 deciding scheduler → 006 activity loop; 007 AStar3D graph →
008 incremental patching → 009 traveling state), then **assemble grid + mesher + camera + building +
villager into GameWorld's `injected_tier_modules`** and land the headless **E2E LOOP test**
(scene-004, THE CROWN) as the commit-gate regression for criterion #8. Capacity-permitting, harden
the block path (building-022 validity), close the last two ADR-0015 invariants (vox-013 in-flight-write
cache, vox-014 load-before-write), and land the cross-system tick guarantee the loop test consumes
(tick-006).

## Capacity

- **Total days:** 10 working days
- **Buffer (20%):** 2 days reserved — **reserved primarily for the crown's integration surprises**
  (the +20% wiring overhead the re-baseline budgets exists exactly for this: assembly is where wiring
  gaps historically surface), plus unplanned work
- **Available:** 8 days
- **Measured velocity:** ~1 story/agent-day planning anchor
  (`estimate-rebaseline-2026-07-23.md`); Sprints 1–5 delivered 8/8…8/8 in single sessions — throughput
  is *not* the binding constraint; the **binding lane** is (see Critical Path / Risks).
- **Committed:** Must 8 stories = 8.5 story-days; Should 4 stories = 3.5 story-days.

**Parallel-lane capacity model (as S5 used):** the 8-available figure is **per-lane wall-clock**, not
a serial story-day sum. Three parallel owner-lanes run concurrently; the binding lane is
**ai-programmer** (the villager chain, 5.0 story-days), after which the **crown** (1.5, godot-specialist)
assembles. Critical path ≈ villager 5.0 → crown 1.5 = **~6.5 lane-days**, inside 8 available with ~1.5
headroom. During those days the godot-specialist lane clears building-021/029 (+022 Should) and the
gdscript lane clears vox-013/014 + tick-006 (Should). The Must story-day **sum** (8.5) exceeding 8 is
expected under parallelism — S5 committed 9 story-days the same way. Should stories sit on the two
non-binding lanes and are the cut levers; the buffer is reserved for the crown, not the Should set.

### Sprint 5 actuals (calibration context)

- **8/8 stories Complete** (vox-010, vox-011, building-019, building-020, villager-ai-003 + Should
  vox-012, villager-ai-004, presentation-002) — including all three Should-Have stories.
- **Building opens through building-020** (tool SM + DDA placement pick); **the ADR-0015 residency
  cluster stood up AND closed** (vox-010 region-file residency, vox-011 async I/O, vox-012 streaming
  budget — all green); **villager position model done** (villager-ai-004 deterministic position on the
  003 body-column); **presentation-002 CD-approved** (loop-payoff scaffolding, criterion #10 half).
- **Test suite green at 524 headless** (GdUnit4), zero red.
- **Zero unplanned rework, zero carryover.**

## Tasks

### Must Have (Critical Path — make the E2E LOOP live)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| building-021 | **Commit pipeline** — click-vs-drag + bounds clamp; pick→preview→commit blueprint | `production/epics/building-system/story-021-commit-pipeline.md` | godot-specialist | 1.0 | building-019 ✓ (S5), building-020 ✓ (S5) | Commit creates blueprint cells exactly matching the visible preview (zero grid blocks); click-vs-drag threshold (F4); out-of-bounds drag commits only the in-bounds portion; no-pick is a no-op; passing unit test |
| building-029 | **Construction tick loop** — Planned→UnderConstruction→Built; issues the real Voxel World write | `production/epics/building-system/story-029-construction-tick-loop.md` | godot-specialist | 1.0 | building-021 (in-sprint), Time & Tick ✓ | A blueprint cell fed `base_build_ticks` via a mocked on-site job → the Voxel World write occurs and the cell is Built (AC20, unit-testable without Villager AI); warp-invariant; paused halts progress; per-villager burst rule; passing unit test |
| villager-ai-005 | **Deciding scheduler** — FIFO queue + `max_deciding_per_tick` budget | `production/epics/villager-ai-behavior/story-005-deciding-scheduler-budget.md` | ai-programmer | 1.0 | villager-ai-001 ✓ (S3) | Budget caps passes STARTED per tick (never interrupts a pass); stable FIFO villager order; burst ≤1 re-eval per processed tick; passing unit test |
| villager-ai-006 | **Activity priority decision loop** — need > work > wander | `production/epics/villager-ai-behavior/story-006-activity-priority-loop.md` | ai-programmer | 1.0 | villager-ai-005 (in-sprint) | Strict discrete priority (urgent need > job > wander); graceful preemption on `decision_interval`; sticky claims (no job-vs-job re-selection); state assigned before next tick; passing unit test |
| villager-ai-007 | **AStar3D graph build & shortest-path query** | `production/epics/villager-ai-behavior/story-007-astar-graph-build-query.md` | ai-programmer | 1.0 | villager-ai-002 ✓ (S4) | Graph built once from `is_standable`/`is_step_legal`; deterministic bit-packed `Vector3i→int64` IDs (no counter); `get_id_path()` returns shortest path (~1.0/1.4 costs); region-bounded, never full-world; **AStar3D/nav APIs cross-referenced against `docs/engine-reference/godot/` (AStarGrid3D absent in 4.7)**; passing unit test |
| villager-ai-008 | **Incremental AStar3D patching on cell writes** | `production/epics/villager-ai-behavior/story-008-incremental-graph-patching.md` | ai-programmer | 1.0 | villager-ai-007 (in-sprint), villager-ai-004 ✓ (S5) | Patches only touched cells + clearance envelope (never a full rebuild); dig/demolition writes patch identically; negative filter → re-path call-count == 0 for non-intersecting writes; idempotent IDs; **synchronous `cell_changed` is load-bearing**; passing integration test |
| villager-ai-009 | **Traveling state** — path following + mid-travel re-path | `production/epics/villager-ai-behavior/story-009-traveling-state-repath.md` | ai-programmer | 1.0 | villager-ai-008 (in-sprint), villager-ai-006 (in-sprint), villager-ai-004 ✓ (S5) | Follows the AStar3D path cell-by-cell; arrival transitions to the next state; a blocking write re-paths from `current_cell`; a dead target exits to Deciding (never travels toward a dead target); redirect in the synchronous call stack; passing integration test |
| scene-004 | **GameWorld scene assembly + headless E2E LOOP test — THE CROWN** (criterion #8) | `production/epics/scene-world-management/story-004-gameworld-assembly-e2e-loop.md` | godot-specialist | 1.5 | building-021 + building-029 (in-sprint), villager-ai-009 (in-sprint), vox-007 ✓, vox-010 ✓, scene-001 ✓, spine-001 ✓ | Grid+mesher+camera+building+villager wired into the Valley via `injected_tier_modules` (DI, ADR-0001), booting behind the ADR-0005 gate; **place-a-block** via the real pick pipeline (ray→DDA→commit→tick) yields a real Voxel World cell write + one batched signal; **a villager walks** (decides→paths→follows to arrival on discrete `current_cell`); the **E2E LOOP test is headless and in the commit gate** (typed-Array regression call included) |

### Should Have (harden the block path + close the last ADR-0015 invariants — parallel-lane cut levers)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| building-022 | **Placement validity checks** — hardens the block path | `production/epics/building-system/story-022-placement-validity.md` | godot-specialist | 1.0 | building-021 (in-sprint) | Rejects occupied/terrain/replace-in-place/over-cap/no-material commits with visible feedback and zero blueprint cells; blueprint counts as occupied in the combined view; geometric availability only (never livability); passing unit test |
| vox-013 | **Read-through in-flight-write cache** — closes an ADR-0015 invariant | `production/epics/voxel-world/story-013-read-through-inflight-write-cache.md` | godot-gdscript-specialist | 1.0 | vox-011 ✓ (S5) | A re-needed evicting-dirty chunk is served from in-flight bytes, never a torn region read; region read resumes after flush completes; passing integration test |
| vox-014 | **Load-before-write for far-world mutations** — the seam far-world building writes inherit | `production/epics/voxel-world/story-014-load-before-write-far-world.md` | godot-gdscript-specialist | 1.0 | vox-003 ✓, vox-010 ✓, vox-011 ✓, vox-013 (in-sprint) | A non-resident write pages-in → resident-copy write → mark dirty → staggered flush; the rule lives in ONE place (the batched write path); no blind write, no drop; passing integration test |
| tick-006 | **Cross-system integration guarantees** — consumed by the E2E LOOP test | `production/epics/time-tick-system/story-006-cross-system-integration-guarantees.md` | godot-gdscript-specialist | 0.5 | tick-003 ✓, tick-004 ✓ (both S2/S3) | `time_scale`/transition non-suspension guarantees the loop test asserts; advances Time & Tick 5/7 → 6/7 |

### Nice to Have (parallel-lane fill — pull only if a lane clears early)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| vox-015 | Mesh view-window streaming — **unlocks the #12 60-FPS-with-culling measurement** | `production/epics/voxel-world/story-015-mesh-view-window-streaming.md` | godot-gdscript-specialist | 1.0 | vox-007 ✓, vox-010 ✓, vox-012 ✓ (all DONE) | Streamed build+unload budgets on the production window. Once it lands, criterion #12 (60 FPS with culling) becomes **measurable**. All deps are DONE — Nice only because it is off the crown critical path. |

## Critical Path

**The crown (scene-004) is the sprint's whole point, and it is gated by the ai-programmer villager
chain.** The binding lane is Villager AI: `villager-ai-005 → 006` (decide) converging with
`007 → 008 → 009` (path + follow) at story-009 — a **depth-3 convergent chain** (the proven S5 shape,
same depth as vox-010→011→012). The crown cannot assemble until 009 (walk) AND building-021→029
(place-a-block write) land. Sequence the villager lane FIRST and never let 009 sit on the last day.

**Owner lanes (serialization mitigation):**
- **ai-programmer** (the binding lane — villager decide→path→walk): villager-ai-005 → 006 (Must);
  villager-ai-007 → 008 → 009 (Must) — ~5.0 Must story-days, dependency depth 3. This lane gates the
  crown; it carries the buffer.
- **godot-specialist** (block path + the crown): building-021 → building-029 (Must) →
  building-022 (Should) → **scene-004 crown (Must, sequenced LAST — waits on villager-009)** —
  ~4.5 story-days, but the crown idles until the ai lane delivers 009, so this lane has slack for 022.
- **godot-gdscript-specialist** (close ADR-0015 + feed the loop test): vox-013 → vox-014 (Should) +
  tick-006 (Should) → vox-015 (Nice) — ~3.5 story-days, fully off the crown critical path.

In-sprint chains to sequence parents-first: **villager-ai-005 → 006 → 009** and
**villager-ai-007 → 008 → 009** (converge at 009); **building-021 → 029 (→ 022)**;
**vox-013 → vox-014**. The crown (scene-004) depends on the tails of both the villager and building
chains and is sequenced last of all.

## Integration-story gap — FLAGGED and RESOLVED (story created this sprint)

The M01 review and the S5 plan both named the **Integrated E2E LOOP (criterion #8)** as the
milestone's true completion signal — but **no story existed for it.** The milestone Feature List's
"Integration-to-playable (CONTRACTS.md, headless E2E)" row had no epic/story; the
`scene-world-management` epic was CLOSED 3/3 on World-Root, boot-gate, and transition-contract — none
of which *assembles* grid+mesher+camera+building+villager into a playable loop or runs an E2E LOOP
test. That is a genuine story-gap, and this sprint's crown cannot exist without it.

**Decision:** created **`scene-world-management/story-004-gameworld-assembly-e2e-loop.md`** (per
create-stories conventions), **re-opening scene-world-management 3/3 → 4 (1 remaining)**.

**Rationale (my call):** scene-world-management's charter *is* scene composition — story-001 (World
Root + Valley attach) and story-002 (boot-gate integration) already own the assembly seam; wiring the
tier modules into GameWorld's `injected_tier_modules` and attaching the Valley behind the ADR-0005
gate is the direct capstone of that epic. `foundation-spine` owns the DI *scaffold* (spine-001) and
the *boot* test (spine-004, proves systems boot); the *playable-loop* assembly (build → villager) is
world/scene composition, which is scene-world-management's domain. Placing the crown here keeps the
E2E LOOP test with the epic that owns "the world is assembled and running," and reuses the scene-002
boot-gate precedent. Owner remains godot-specialist per the milestone's Integration-to-playable row.

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| None | Sprint 5 delivered 8/8 — no carryover, zero unplanned rework | — |

## Out of Scope (deferred, with honest reasons)

- **building-033 (Voxel World write seam — batched bulk-write + self-write exemption)** — **BLOCKED by
  building-032 (undo/redo stack core)**, which is not in this sprint. The minimal real voxel write
  the crown needs is issued directly by building-029 (AC20); 033 hardens it into the batched seam with
  self-write exemption **next sprint, alongside 032**. Not silently dropped — dependency-gated.
- **tick-007 (per-tick re-tune pass — milestone criterion #4)** — the crown clears its *"the
  integrated build must exist"* precondition, but tick-007 **still needs two things this sprint cannot
  supply**: (a) **villager-ai-022** (`max_deciding_per_tick` half — one coordinated config change,
  recorded jointly), and (b) a **systems-designer / game-designer VALUE DECISION** on the numbers (a
  GDD Open Question). Deferred to **Sprint 7**, sequenced LAST, once the crown is measurable and a
  designer decision lands. **Action:** producer to surface the value decision to systems-designer /
  game-designer NOW so S7 is not blocked. tick-006 (its parent guarantee) IS pulled this sprint (Should).
- **Fully-closed job loop (building-030 job queue + villager-ai-011/012 claim→build→report)** — "a
  villager *builds the placed block*" end-to-end closure. **Sprint 7.** This sprint proves the two
  halves live in one assembled scene (place-a-block writes voxel; a villager walks); binding them into
  a single claim→build→completion loop is the next step, not the crown's minimal acceptance.
- **presentation-001 (ambient-life wave 1, CD-protected)** — dependency-gated behind the villager
  FSM/movement stories, which land THIS sprint (005–009). It therefore becomes **sequenceable in
  Sprint 7**; surfaced here so it is not silently deferred (cutting requires CD sign-off). Not in this
  sprint's committed set.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **The villager chain is the binding lane and gates the crown** — 005→006 + 007→008→009 must all land before scene-004 can assemble; a slip in the ai lane strands the crown and the E2E loop does not go live | Medium | High (it is the sprint's whole point) | Depth-3 convergent chain (the proven S5 shape, vox-010→012). Sequence the ai lane FIRST, 009 never on the last day. The 2-day buffer is reserved for this lane + the crown. Everything else (022, vox-013/014, tick-006, vox-015) is a cut lever on the non-binding lanes — none is Must, so the ai lane + crown own the full Must budget with headroom. |
| **Integration/wiring gaps surface only at assembly (the crown)** — E2E cannot catch wiring it isn't wired for; this is the historical failure mode | Medium | Med-High | The +20% slice overhead exists exactly for this — buffer reserved for crown surprises. Crown sequenced LAST with explicit, independent headless ACs (place-a-block AND villager-walk asserted separately), so a half-failure is diagnosable, not a monolithic red. |
| **AStar3D / Navigation HIGH engine-risk** (villager-ai-007/008/009) — `AStarGrid3D` does NOT exist in 4.7 (manual `AStar3D` only); IDs never auto-recycled; synchronous `cell_changed` is load-bearing for the race closure — post-cutoff facts the LLM (~4.3) does not know | Medium | Med-High | Every nav/threading API cross-referenced against `docs/engine-reference/godot/` before use (enforced per story Engine Notes). Deterministic bit-pack IDs; grep-verify zero `NavigationServer3D`/`NavigationAgent3D`. This is the ai lane's own top risk and sits behind buffer. |
| **building-029 issues the real voxel write WITHOUT building-033's batched seam** (033 blocked by 032) | Low-Med | Med | 029's write is per-completion via the DONE `bulk_write` (vox-003) with its exactly-one-signal guarantee — the crown asserts the single batched `cells_changed_batch`, so write correctness is testable now. 033's batching + self-write exemption is next-sprint hardening, not a loop blocker. |
| **Must set is heavy (8.5 story-days, no dip-free margin)** — if the binding lane stalls there is little slack | Medium | Med | Three parallel lanes; only the ai lane (5.0) is binding; Should (022, vox-013/014, tick-006 = 3.5) are cut levers on the lighter lanes and can be dropped without touching the crown. Buffer reserved for the crown. If the ai lane runs hot, the crown still lands by cutting all Should. |
| **tick-007 (#4 re-tune) blocked again — needs a designer value decision + villager-ai-022** | Medium (visibility) | Med | Honest deferral to S7. The crown makes it *measurable* (integrated load exists). Escalate the value decision to systems-designer / game-designer NOW (producer action) so S7 is unblocked. Stated in Out of Scope + Action Items, not a silent slip. |
| **CD-protected presentation-001 (ambient-life) unblocks but is not committed** — schedule could push it out | Medium | Medium | Its dependency (villager FSM/movement) lands this sprint, so it becomes sequenceable S7. Surfaced here and in status; **cut only with CD sign-off** — never silently deferred. |
| **Recurring typed-Array crash class** (0 in S1–S5) | Low | Low | Regression call retained — it now lives inside the crown's own E2E LOOP test (the commit gate). Five clean sprints; low but watched on the residency page-in/out and building-commit paths. |

## Dependencies on External Factors

- **Control-manifest version 2026-07-23** — all Sprint 6 stories embed this version. Confirmed current
  for Sprints 1–5; re-confirm unchanged before the villager and building lanes start. Owner:
  technical-director.
- **Systems-designer / game-designer VALUE DECISION for tick-007 (per-tick re-tune)** — the crown
  clears the integrated-build precondition, but the numeric re-tune is a balance decision the designers
  own (GDD Open Question). Producer to surface it this sprint so Sprint 7 can land tick-007 +
  villager-ai-022 as the coordinated re-tune. Not a blocker for this sprint's committed set.
- **No art/audio external dependency** for the committed set (integration + Building logic + Villager
  AI logic + residency invariants). presentation-001 (ambient-life) is *not* committed this sprint.

## Definition of Done for this Sprint

- [ ] All Must Have stories completed — **the crown (scene-004) is green**: grid+mesher+camera+building+
      villager assemble into GameWorld; place-a-block writes a real Voxel World cell; a villager walks;
      the E2E LOOP test runs headless and is wired into the commit gate (**criterion #8 begins here**)
- [ ] All tasks pass acceptance criteria
- [ ] Every Logic story (building-021/029, +Should building-022; villager-ai-005/006/007) has a passing
      GdUnit4 headless unit test in `neues-spiel/tests/unit/...` — BLOCKING
- [ ] Every Integration story (villager-ai-008/009, scene-004, +Should vox-013/014) has a passing
      headless integration test in `neues-spiel/tests/integration/...` — BLOCKING
- [ ] The E2E LOOP test asserts BOTH halves independently (place-a-block AND villager-walk) and
      includes the typed-Array crash-class regression call — BLOCKING
- [ ] All AStar3D / nav / threading APIs confirmed against `docs/engine-reference/godot/` — BLOCKING
- [ ] Tests deterministic, isolated, DI-mockable (no Autoload registration, no real file I/O in unit
      tests — residency I/O tests use temp/injected paths and tear down)
- [ ] QA plan exists for Sprint 6 (`production/qa/qa-plan-sprint-6-*.md`) — run `/qa-plan sprint`
      before implementation begins (none exists yet — see warning below)
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No open S1 or S2 bugs in delivered stories
- [ ] Design/ADR docs updated for any deviation (esp. any residency finding that amends ADR-0015 toward
      Accept; any wiring finding that should update CONTRACTS.md)
- [ ] Code reviewed and merged (trunk-based)

> ⚠️ **No QA Plan**: This sprint was planned without a Sprint-6 QA plan. Run `/qa-plan sprint` before
> the last story is implemented. The Production → Polish gate requires a QA sign-off report, which
> requires a QA plan. The crown's place-a-block and villager-walk pass conditions in particular need
> defining up front.

## Notes

- **Dependencies-satisfied check:** every Sprint-6 committed story was verified against its real story
  file's `## Dependencies` section (not the request list). building-021 → 019✓/020✓; building-029 →
  021(in-sprint)/tick✓; villager-ai-005 → 001✓; 006 → 005(in-sprint); 007 → 002✓; 008 →
  007(in-sprint)/004✓; 009 → 008(in-sprint)/006(in-sprint)/004✓; scene-004 → 021+029+009(in-sprint) +
  007✓/010✓/scene-001✓/spine-001✓; building-022 → 021(in-sprint); vox-013 → 011✓; vox-014 →
  003✓/010✓/011✓/013(in-sprint); tick-006 → 003✓/004✓; vox-015 → 007✓/010✓/012✓ (all DONE).
  **building-033 REJECTED** (blocked by 032, not in sprint). **tick-007 REJECTED** (needs villager-ai-022
  + a designer value decision even though the crown clears the integrated-build precondition). No
  unsatisfied dependency in the committed set.
- **Scope check:** all committed stories are drawn from existing epics — EXCEPT the crown (scene-004),
  which is a **newly-created story closing a real gap** (the integration-to-playable / E2E LOOP work
  the milestone named but never storyed). Run `/scope-check sprint-6` before implementation; the crown
  is a discovered-requirement addition (justified), not creep.
- **Milestone recalibration (Action Item #4):** the M01 review deferred the calendar re-baseline until
  "the first 3–4 Core stories + the mesher/residency chain land" — those landed in S4/S5. This sprint
  lands the integrated loop itself, the true Core-velocity + integration-cost measurement point.
  Re-baseline the M01 calendar estimate once the crown lands. Owner: producer.
- **Milestone-criteria coverage this sprint:** **#8 INTEGRATED E2E LOOP** — the crown targets it (the
  milestone's true completion signal begins here); **#2 Foundation systems integrated** — the crown
  assembles all five into one running scene (advances from IN PROGRESS); **#6 Building playable** —
  021/029 (+022 Should) advance the lifecycle to a real block write; **#7 Villager AI playable** —
  005/006/007/008/009 stand up decide→path→walk; **#5 ADR-0015 residency** — vox-013/014 (Should) close
  the last in-flight-write + load-before-write invariants; **#12 60-FPS-with-culling** — vox-015 (Nice)
  makes it measurable; **#4 per-tick re-tune** — tick-006 (Should) lands the cross-system guarantee;
  tick-007 re-tune deferred to S7 (designer decision); **#13 sustained stability** — the crown's E2E
  LOOP enters the commit gate, beginning the sustained-green window; **#9 ambient-life** — presentation-001
  unblocks after villager movement, sequenceable S7.
- **Next step:** run `/qa-plan sprint` to define test cases per story (especially the crown's
  place-a-block + villager-walk pass conditions, and villager-ai-008/009's synchronous-signal race
  assertions) before `/dev-story`.


---

## Sprint Result — CLOSED 2026-07-24

**13/13 stories complete** (5 Must villager lane, 2 Must building lane, 1 Must crown, 4 Should, 1 Nice). Suite grew 587 -> 682, green on every story commit, no open regressions.

Highlights:
- **THE CROWN (scene-004) landed**: headless E2E over the assembled GameWorld — real pipeline block placement (ray->DDA->commit->blueprint->4 build ticks->voxel write) AND a villager deciding->pathing->walking to arrival. Milestone M01 criterion #8 MET.
- Villager binding lane complete (005-009): scheduler, activity loop, AStar graph, incremental synchronous patching, traveling state with mid-travel re-path.
- ADR-0015 fully certified: vox-013 (read-through in-flight write cache) + vox-014 (load-before-write, never blind/never dropped) close the last residency invariants.
- vox-015 mesh view-window streaming lands the machinery for criterion #12 (60FPS measurement is milestone work).
- tick-006: cross-system tick guarantees locked by regression guards (no code changes needed — the system already held them).

Engine facts recorded this sprint: GdUnit CLI runner is fail-fast PER SUITE; Godot 4.7 hard-rejects plain Array into typed Array params; Node-typed @export cannot be wired via hand-authored NodePath in a text .tscn (code-assign in _ready instead).

Carried to Sprint 7 (unchanged from plan): building-030 + villager-ai-011/012 closed job loop, tick-007 + villager-ai-022 coordinated re-tune (needs a designer value decision), building-032->033, presentation-001 ambient-life wave 1, criterion #12 measurement.
