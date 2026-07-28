# Sprint 7 — Working Days 61–70 (nominal anchor 2026-07-25) — THE CLOSED-LOOP SPRINT

> Duration is expressed in **working days** per the milestone re-baseline
> (`production/estimates/estimate-rebaseline-2026-07-23.md`). Calendar span depends on session
> cadence. **Calendar note (six-times-confirmed):** Sprints 1–6 each landed their full commit in
> single back-to-back sessions (8/8, 9/9, 9/9, 8/8, 8/8, 13/13) — measured throughput ran far above
> the 1-story/agent-day planning rate. The per-story estimate is the *planning anchor*, not a calendar
> prediction.
> Review mode: **lean** — PR-SPRINT feasibility gate skipped (`production/review-mode.txt`).
>
> **Sprint 6 made the loop LIVE in one scene (the crown, criterion #8): place-a-block writes voxel AND
> a villager walks.** But those two halves still run *side by side* — the villager does not yet build
> the block the player draws. This sprint **binds the two halves into a single claim→build→report
> loop**: the player draws a building, a villager selects the job, claims it, paths to the site, works
> on-site over ticks, and the cell transitions to Built via the Building System's write. That is
> milestone exit criterion **#2 full-depth integration** ("build a house → workers build it → villagers
> navigate it"), and closing it is this sprint's crown (`villager-ai-012`, the AC40 full-cycle
> integration test running against **real** Building System components).

## Sprint Goal

Close the build-and-inhabit loop end-to-end — **villagers build what the player draws**. Stand up the
Building System's project-lifecycle → release → job-queue chain (**building-002 → 004 → 030**) and the
Villager AI job-selection → claim → on-site-build cycle (**villager-ai-010 → 011 → 012**), converging on
the **full claim→build→report crown** (`villager-ai-012`, AC40 with the real Building System). Capacity-
permitting, close worker attribution (building-005), stand up the undo/redo stack core (building-032),
and land **ambient-life wave 1 Sub-scope A** (presentation-001, CD-protected, criterion #9). Set up the
still-blocked coordinated re-tune (criterion #4) and criterion #12 measurement by producing the perf
measurement basis (villager-ai-025), surfacing the designer value decision, and flagging the missing
#12 measurement story.

## Capacity

- **Total days:** 10 working days
- **Buffer (20%):** 2 days reserved — **reserved primarily for the crown's cross-lane convergence**
  (`villager-ai-012` needs BOTH the AI chain's `011` AND the Building chain's `030` — a cross-lane
  join, the historical wiring-surprise surface), plus unplanned work.
- **Available:** 8 days
- **Measured velocity:** ~1 story/agent-day planning anchor
  (`estimate-rebaseline-2026-07-23.md`); Sprints 1–6 delivered 8/8…13/13 in single sessions —
  throughput is *not* the binding constraint; the **binding join** is the cross-lane crown (see
  Critical Path / Risks).
- **Committed:** Must 6 stories = 6.0 story-days; Should 3 stories = 3.5 story-days.

**Parallel-lane capacity model (as S5/S6 used):** the 8-available figure is **per-lane wall-clock**,
not a serial story-day sum. Three parallel owner-lanes run concurrently. Unlike S6 (one deep binding
lane), S7's crown is a **cross-lane join**: `villager-ai-012` cannot close until BOTH the ai chain
(`010 → 011`, 2.0 story-days) AND the building chain (`002 → 004 → 030`, 3.0 story-days) land. Critical
path ≈ building 3.0 → crown 1.0 = **~4.0 lane-days**, inside 8 with ~4 headroom. The buffer is reserved
for the join, not the Should set. The Must story-day **sum** (6.0) fits inside 8 even before
parallelism — this is a *lighter* Must set than S6 (8.5) by design, because the risk this sprint is
integration-shape (cross-lane join + real-Building-System integration test), not lane depth.

### Sprint 6 actuals (calibration context)

- **13/13 stories Complete** (5 Must villager lane, 2 Must building lane, 1 Must crown, 4 Should,
  1 Nice) — including every Should and the one Nice.
- **THE CROWN (scene-004) landed:** headless E2E over the assembled GameWorld — real-pipeline block
  placement (ray→DDA→commit→blueprint→4 build ticks→voxel write) AND a villager
  deciding→pathing→walking to arrival. **Milestone M01 criterion #8 MET.**
- **Villager binding lane complete (005–009):** scheduler, activity loop, AStar graph, incremental
  synchronous patching, traveling state with mid-travel re-path.
- **ADR-0015 fully certified:** vox-013 (read-through in-flight-write cache) + vox-014 (load-before-
  write) closed the last residency invariants; vox-015 landed the mesh view-window streaming machinery.
- **Test suite 587 → 682**, green on every story commit, zero open regressions.
- **Zero unplanned rework, zero carryover.**
- Engine facts recorded: GdUnit CLI runner is fail-fast PER SUITE; Godot 4.7 hard-rejects plain Array
  into typed-Array params; Node-typed `@export` cannot be wired via hand-authored NodePath in a text
  `.tscn` (code-assign in `_ready` instead).

## Tasks

### Must Have (Critical Path — close the claim→build→report loop)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| building-002 | **Project entity + blueprint-cell lifecycle rollup** — the persistent DRAFT⇄BUILDING⇄PAUSED→DONE entity the loop hangs on | `production/epics/building-system/story-002-project-entity-lifecycle.md` | godot-gdscript-specialist | 1.0 | pre-slice commit pipeline (building-021 ✓ S6 produces blueprint cells) | State is a rollup over cell micro-states (never an independent flag); Draft cell is structurally invisible to `claim_job`; DONE persists (not deleted); entity deleted only when its cell set is empty; passing unit test |
| building-004 | **Release ("Bau starten") + job-eligibility transition** — flips Draft cells into claimable BUILDING work | `production/epics/building-system/story-004-release-job-eligibility.md` | godot-gdscript-specialist | 1.0 | building-002 (in-sprint) | `release_project` moves every Draft cell → BUILDING job-eligible; `claim_job` serves BUILDING only (never DRAFT/PAUSED/unreleased batch); queue ordered by commit time (advisory, not forced servicing); passing unit test |
| building-030 | **Construction job queue** — claim/report pipeline + on-site predicate + occupied-cell defer + unreachable feedback | `production/epics/building-system/story-030-construction-job-queue.md` | godot-gdscript-specialist | 1.0 | building-029 ✓ (S6 tick loop), building-004 (in-sprint) | Every BUILDING blueprint cell is one job; `claim_job` records the claiming villager; on-site = target or orthogonal neighbour (incl. above/below); occupied-cell defer (Building half, mocked); unreachable jobs stay queued + ghost pulses orange; passing integration test (Building-owned halves; AC21/36b PROVISIONAL until the crown wires the real villager) |
| villager-ai-010 | **F2 job selection** — nearest-reachable, bounded candidates (argmin true-path over Chebyshev pre-filter) | `production/epics/villager-ai-behavior/story-010-job-selection-f2.md` | ai-programmer | 1.0 | villager-ai-007 ✓ (S6 AStar3D true-path) | Selects true-path-nearest among the Chebyshev-nearest `job_candidate_count`; deterministic ties (older commit → lexicographic y,x,z); bounded pathfinds (≤ `max_selection_candidates`, never full-queue); reachability discovered lazily; passing unit test |
| villager-ai-011 | **Job claim/release + worker attribution** — atomic claim, sticky, deterministic contention, id recording | `production/epics/villager-ai-behavior/story-011-job-claim-attribution.md` | ai-programmer | 1.0 | villager-ai-010 (in-sprint), villager-ai-006 ✓ (S6 priority loop) | One job per villager; atomic claim (exactly one winner, loser tries next); stable-order contention; sticky (abandon only on preempt/revoke/path-fail); claiming villager id recorded for `worker_ids`; all-unreachable → falls through to Wandering; passing integration test |
| villager-ai-012 | **On-site work & full claim→build→report cycle — THE CROWN** (criterion #2 full-depth integration) | `production/epics/villager-ai-behavior/story-012-onsite-work-build-cycle.md` | ai-programmer | 1.0 | villager-ai-011 (in-sprint), villager-ai-009 ✓ (S6 travel), **building-030 (in-sprint — the real Building System the AC40 test runs against)** | Progress accrues only on-site (target/orthogonal-adjacent), first increment tick-boundary-credited never partial; **the full cycle: a real villager claims → travels → accrues ticks → the cell transitions to Built via the Building System's write → the job leaves the queue → the villager re-enters Deciding (AC40, closes Building AC21)**; deferred-then-vacated resumes without re-claiming; mid-work revoke exits cleanly; **integration test uses REAL Building System components** |

### Should Have (complete attribution + harden the plan + CD-protected ambient life — parallel-lane cut levers)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| building-005 | **Worker attribution on job claim** — `on_job_claimed` records `worker_ids` for the Projects Panel | `production/epics/building-system/story-005-worker-attribution.md` | godot-gdscript-specialist | 1.0 | building-004 (in-sprint) | `on_job_claimed(project_id, villager_id)` de-dup records onto the project `worker_ids`; display/save-state only, never a control channel (no scheduling branches on it); `serialize()` contract shape included; passing test (mocked claim now; full cycle PROVISIONAL) |
| building-032 | **Undo/redo stack core** — command model, bounded depth, redo-branch clear, transition-COMPLETE clear | `production/epics/building-system/story-032-undo-redo-stack-core.md` | godot-specialist | 1.0 | building-021 ✓ (commands), building-022 ✓ (redo re-validation), scene-003 ✓ (transition signals) | One drag = one undo step; bounded `undo_stack_depth` (oldest discarded silently); new command clears redo branch; stack clears on transition-COMPLETE ONLY (aborted transition leaves it intact); plan-only invariant hook in place; passing unit test |
| presentation-001 | **Ambient-life wave 1 — Sub-scope A (environmental)** — smoke on occupied/lit, foliage sway, interior clutter, torch flicker (CD-protected, criterion #9) | `production/epics/presentation-experience/story-001-ambient-life-wave-1.md` | godot-specialist (shader-specialist consult on vertex-wind + flicker) | 1.5 | vox-007 ✓ (mesher renders the world) | Chimney smoke as small GPUParticles3D **only on occupied/lit buildings** (absence = "nobody home"); foliage vertex-shader wind; static interior clutter; torch flicker **asserted sub-3Hz (A5)**; nothing baked into committed-block materials; all post-cutoff rendering APIs cross-referenced against `docs/engine-reference/godot/`; **AD/CD sign-off is the binding gate**. *Sub-scope B (villager idle behaviors) deferred — see Out of Scope.* |

### Nice to Have (parallel-lane fill — pull only if a lane clears early)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| building-033 | Voxel World write seam — batched bulk-write + self-write exemption + completion signal | `production/epics/building-system/story-033-voxel-write-seam.md` | godot-specialist | 1.0 | building-029 ✓, building-032 (in-sprint) | Self-originated writes ignored by the undo-invalidation listener (no re-entrant self-invalidation on synchronous signals); N same-frame completions → ONE batched write signal; stale undo entries skipped; per-frame batched construction-completed signal. Pull only after building-032 lands. |
| building-003 | Grouping/merge (26-neighbourhood) + cell→project reverse index | `production/epics/building-system/story-003-grouping-merge-reverse-index.md` | godot-gdscript-specialist | 1.0 | building-002 (in-sprint) | Commit-time cell→project assignment + 26-neighbourhood merge + reverse index. Pull only if the gdscript lane clears the Must building chain + building-005 with headroom. |
| villager-ai-025 | Perf stress validation (30-villager) — **produces the measurement basis the #4 re-tune needs** | `production/epics/villager-ai-behavior/story-025-perf-stress-validation.md` | ai-programmer | 1.0 | villager-ai-005 ✓, villager-ai-009 ✓, villager-ai-012 (in-sprint) | Synthetic 30-villager stress (unreachable-dense + write-storm at 3x + mass-Deciding spikes); p95 frame time recorded against production code. **Advisory/Performance** — not an MVP-Done blocker, but its recorded envelope is the production-load measurement `villager-ai-022`/`tick-007` need (de-risks S8's re-tune). Pull after the crown (012) lands. |

## Critical Path

**The crown (`villager-ai-012`) is a CROSS-LANE JOIN** — the shape difference from S6. Where S6's crown
sat behind one deep binding lane, S7's crown needs BOTH chains to converge:

- **Building chain (feeds the crown):** `building-002 → 004 → 030` — depth-3, ~3.0 story-days. This is
  the **longer feeder**, so it is the binding chain. `building-030` (the real job queue) is what
  `villager-ai-012`'s AC40 integration test runs against — it MUST land before the crown closes.
- **AI chain:** `villager-ai-010 → 011` — depth-2, ~2.0 story-days — then the crown `villager-ai-012`
  (owned by ai-programmer) joins the two chains.
- Critical path ≈ building `002→004→030` (3.0) → crown `012` (1.0) = **~4.0 lane-days**, inside 8 with
  headroom. Sequence the **building chain FIRST and never let `030` sit on the last day** — the crown
  idles until it lands.

**Owner lanes (serialization mitigation):**
- **godot-gdscript-specialist** (the binding feeder — Building lifecycle → queue): `building-002 → 004 →
  030` (Must, 3.0d) → `building-005` (Should) → `building-003` (Nice). This lane gates the crown; keep
  it early, `030` off the last day.
- **ai-programmer** (job selection → claim → the crown): `villager-ai-010 → 011` (Must, 2.0d) →
  `villager-ai-012` **crown (Must, sequenced LAST — waits on both `011` and `030`)** →
  `villager-ai-025` (Nice, after the crown). ~3.0 Must story-days; idles briefly waiting on `030`.
- **godot-specialist** (CD-protected life + plan hardening): `presentation-001` Sub-scope A (Should,
  1.5d) + `building-032` (Should) → `building-033` (Nice). Fully off the crown critical path.

In-sprint chains to sequence parents-first: **building-002 → 004 → 030 (→ 005, → 003)**;
**villager-ai-010 → 011 → 012**; **building-032 → 033**. The crown (`villager-ai-012`) depends on the
tails of BOTH the building and AI chains and is sequenced last of all.

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| None | Sprint 6 delivered 13/13 — no carryover, zero unplanned rework. The S6 "carried to S7" set (closed job loop, re-tune, undo/write-seam, ambient-life) is scheduled/flagged below as planned, not as incomplete carryover. | — |

## Out of Scope (deferred, with honest reasons)

- **Coordinated per-tick re-tune — `tick-007` + `villager-ai-022` (milestone criterion #4)** — **STILL
  BLOCKED, and the block is not schedule capacity, it is a DECISION.** Both stories' headers require a
  **systems-designer / game-designer VALUE DECISION on the numbers** (`ticks_per_second`,
  `max_ticks_per_frame`, `max_deciding_per_tick`) — a GDD Open Question flagged "Open — tracked, not
  yet actioned." The integrated build now exists (S6 crown) AND this sprint produces the production-
  load measurement (`villager-ai-025`, Nice), so the *only* remaining blocker after this sprint is the
  designer decision. **Deferred to Sprint 8, sequenced as ONE coordinated config change with shared
  rationale once the decision lands.** **Producer action (TOP PRIORITY this sprint):** surface the
  value decision to systems-designer / game-designer NOW so S8 is not blocked a fourth time (deferred
  S5, S6, and now S7 on the same missing decision).
- **presentation-001 Sub-scope B (villager idle behaviors hook)** — the story is explicitly
  **split-schedulable by dependency gate** (its own Implementation Notes: "do not block A on B").
  Sub-scope A (environmental) is cleanly unblocked on the mesher (vox-007 ✓) and IS committed (Should).
  Sub-scope B formally depends on **`villager-ai-019` (wandering micro-behaviors)**, which is NOT
  scheduled this sprint; the Idle/Wandering FSM *states* exist (villager-ai-006/009 ✓) but the richer
  micro-behaviors `019` provides do not. **Sub-scope B deferred to the sprint that schedules
  `villager-ai-019`.** CD-protected — surfaced here, not silently dropped; cutting Sub-scope A itself
  would require CD sign-off (it is committed as Should).
- **building-006 (pause/resume), building-007 (change orders), building-008 (click-selection),
  building-009 (demolition orders)** — the remaining project-lifecycle stories. The loop closes on the
  DRAFT→BUILDING→build→DONE happy path (002/004/030); pause/change-orders/demolition are lifecycle
  breadth, not loop-closure, and follow next sprint. Not dropped — dependency-ordered after the crown.
- **vox-016 (C1 async-cap / gen-cost tuning), vox-017 (C4 completion-driven drain)** — the formal
  ADR-0015 C1/C4 residency-**tuning** stories (milestone criterion #5, "the two carried tuning items
  implemented as stories with measured values"). The verified sprint context treats ADR-0015 as fully
  certified via vox-013/014 (S6). **These two stories nonetheless still exist as un-run "measured-value"
  closures of criterion #5** — flagged so the milestone review can confirm whether #5 is met by
  certification or still wants vox-016/017's measured values. Not committed this sprint; producer to
  confirm #5's closure basis at milestone review.

## Missing Stories (flagged — do NOT fabricate; create before scheduling)

- **Criterion #12 — 60 FPS on the production window with culling RE-ENABLED — has NO measurement
  story.** `vox-015` (S6) landed the mesh view-window streaming *machinery*, but the milestone's
  KNOWN-OPEN item is the **live Valley wiring + rendering measurement** (stream the view-window into the
  assembled GameWorld Valley and profile the 60-FPS-with-culling target on the production window). No
  story file covers this: `villager-ai-025` measures *villager-load* frame budget (CPU/AI), not the
  *rendering/culling* 60-FPS target. **Action:** run `/create-stories` for a new story (suggested
  `voxel-world/story-018-live-view-window-valley-wiring-and-60fps-measurement.md` or a
  `scene-world-management` measurement story) before criterion #12 can be scheduled. Listed here rather
  than fabricated into the plan.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **The crown is a CROSS-LANE JOIN** — `villager-ai-012` needs BOTH the AI chain (`011`) AND the Building chain's `030`; a slip in *either* lane strands the crown and criterion #2 does not close | Medium | High (it is the sprint's whole point) | The building chain (`002→004→030`, 3.0d) is the longer feeder and thus binding — sequence it FIRST, `030` never on the last day. The AI chain (`010→011`, 2.0d) has slack. The 2-day buffer is reserved for the join. Everything else (005, 032, presentation-001, 033, 003, 025) is a cut lever on the non-binding lanes. |
| **The AC40 crown test integrates REAL Building System components** (not mocks) — the historical failure mode is wiring gaps that only surface when two real systems meet (S6 saw this exact class at assembly) | Medium | Med-High | The +20% slice overhead / 2-day buffer exists exactly for this. The crown test asserts each cycle stage independently (claim → travel → on-site accrual → Built write → job removed → re-Deciding), so a half-failure is diagnosable, not a monolithic red. The two halves already proved live *separately* in S6's crown — this sprint binds them, reducing the unknown surface. |
| **AStar3D true-path at selection scale** (`villager-ai-010`) — F2 does per-candidate true-path checks; the HIGH-engine-risk AStar3D fact (no `AStarGrid3D` in 4.7, manual `AStar3D`) carries from S6 | Low-Med | Med | `villager-ai-007` already shipped the AStar3D graph + `get_id_path` in S6 (green); `010` consumes that proven API with a bounded candidate cap (never full-queue). Determinism asserted. Cross-reference `docs/engine-reference/godot/` per story Engine Notes. |
| **presentation-001 is HIGH engine-risk** — GPUParticles3D, vertex-shader wind, light-energy flicker all sit in the post-cutoff rendering domain; particle/VFX budget is the debrief's #1 reserved-budget gap | Medium | Med | Sub-scope A only this sprint (environmental — the bulk of criterion #9's visible payoff); shader-specialist consult on the vertex-wind + flicker shaders; every API cross-referenced against `docs/engine-reference/godot/`; flicker rate asserted sub-3Hz (not eyeballed); stay inside the §8.9 budget. It is Should (a cut lever), fully off the crown path. |
| **Criterion #4 re-tune blocked a THIRD time on the same missing designer decision** (deferred S5, S6, now S7) | Medium (visibility/credibility) | Med | The decision is now the *sole* remaining blocker (integrated build ✓, and `villager-ai-025` produces the measurement this sprint). **Escalated as the TOP producer action + an external dependency + an action item** — not a silent slip. If the decision lands mid-sprint, `tick-007` + `villager-ai-022` become pullable as a coordinated Nice add. |
| **Criterion #12 has no story** (rendering/culling 60-FPS measurement) — it cannot be scheduled or closed until one is created | Medium (schedule visibility) | Med | Flagged explicitly under Missing Stories with a concrete `/create-stories` action; `villager-ai-025` covers the *CPU/AI* frame-budget half but NOT the rendering target. Producer to create the measurement story before it can enter a sprint. |
| **Building lifecycle stories (002/004/030/005/003) are a first outing for the project-entity data model** — five building-lifecycle stories land on one lane; a parent slip (002) strands the whole chain | Medium | Med | Only three (`002→004→030`) are Must; `005`/`003` are Should/Nice cut levers. The chain is the proven parents-first shape (depth-3, same as S5's residency and S6's villager chains). ADR-0016 knowledge-risk is LOW (settled data-model/state-machine, no post-cutoff APIs). Buffer reserved for the crown, not this chain. |
| **Recurring typed-Array crash class** (0 in S1–S6) | Low | Low | Regression call retained inside the crown's E2E gate. Six clean sprints; low but watched on the new job-queue claim/report and Building-write paths this sprint exercises. |

## Dependencies on External Factors

- **Systems-designer / game-designer VALUE DECISION for the coordinated re-tune (`tick-007` +
  `villager-ai-022`, criterion #4)** — the numbers (`ticks_per_second`, `max_ticks_per_frame`,
  `max_deciding_per_tick`) are a balance decision the designers own (GDD Open Question). The integrated
  build exists and this sprint produces the measurement (`villager-ai-025`); the decision is the ONLY
  remaining blocker. **Producer to surface it this sprint (top action)** so Sprint 8 lands the re-tune.
  Also decide during that story whether the slice's 10x/20x debug warp gears return as debug-only
  data-driven warps (carried note from tick-001).
- **Art-director / creative-director sign-off on presentation-001 Sub-scope A** — the binding CD-
  protected acceptance gate for the ambient-life mood result. The cue/hook spec (Art Bible §6.5,
  CONFIRMED 2026-07-23) is approved; this needs the mood sign-off on the result, not new assets.
- **Control-manifest version 2026-07-23** — all Sprint 7 stories embed this version. Confirmed current
  for Sprints 1–6; re-confirm unchanged before the building and villager lanes start. Owner:
  technical-director.
- **No art/audio external dependency** for the committed *logic* set (Building lifecycle + Villager AI
  job cycle). presentation-001 Sub-scope A needs the approved §6.5 spec, not new art assets.

## Definition of Done for this Sprint

- [ ] All Must Have stories completed — **the crown (`villager-ai-012`) is green**: a real villager
      selects → claims → paths to → builds on-site → the cell transitions to Built via the Building
      System's write → the job leaves the queue → the villager re-enters Deciding, verified by an
      integration test against **real Building System components** (**criterion #2 full-depth
      integration closes here**)
- [ ] All tasks pass acceptance criteria
- [ ] Every Logic story (building-002/004, villager-ai-010; +Should building-032) has a passing GdUnit4
      headless unit test in `neues-spiel/tests/unit/...` — BLOCKING
- [ ] Every Integration story (building-030, villager-ai-011/012; +Should building-005) has a passing
      headless integration test in `neues-spiel/tests/integration/...` — BLOCKING
- [ ] The crown's AC40 integration test asserts each cycle stage independently (claim → travel →
      on-site accrual → Built write → job removed → re-Deciding) and includes the typed-Array
      crash-class regression call — BLOCKING
- [ ] All AStar3D / nav / rendering / particle APIs confirmed against `docs/engine-reference/godot/` —
      BLOCKING (villager-ai-010 nav; presentation-001 rendering if landed)
- [ ] Tests deterministic, isolated, DI-mockable (no Autoload registration, no real file I/O in unit
      tests)
- [ ] presentation-001 (if landed) has AD/CD sign-off + screenshot evidence in
      `production/qa/evidence/`; torch-flicker sub-3Hz asserted
- [ ] QA plan exists for Sprint 7 (`production/qa/qa-plan-sprint-7-*.md`) — run `/qa-plan sprint`
      before implementation begins (none exists yet — see warning below)
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No open S1 or S2 bugs in delivered stories
- [ ] Design/ADR docs updated for any deviation (esp. any job-queue/claim finding that should update
      CONTRACTS.md or amend ADR-0016)
- [ ] Code reviewed and merged (trunk-based)

> ⚠️ **No QA Plan**: This sprint was planned without a Sprint-7 QA plan. Run `/qa-plan sprint` before
> the last story is implemented. The Production → Polish gate requires a QA sign-off report, which
> requires a QA plan. The crown's claim→build→report cycle-stage assertions and building-030's
> on-site/occupied-defer/unreachable pass conditions in particular need defining up front.

## Notes

- **Dependencies-satisfied check:** every Sprint-7 committed story was verified against its real story
  file's `## Dependencies` section (not the request list). building-002 → pre-slice commit pipeline
  (building-021 ✓ S6); building-004 → 002 (in-sprint); building-030 → 029 ✓ (S6) + 004 (in-sprint);
  villager-ai-010 → 007 ✓ (S6); villager-ai-011 → 010 (in-sprint) + 006 ✓ (S6); villager-ai-012 → 011
  (in-sprint) + 009 ✓ (S6) + real building-030 (in-sprint, for the AC40 test); building-005 → 004
  (in-sprint); building-032 → 021 ✓/022 ✓ (S6) + scene-003 ✓ (S3); building-033 → 029 ✓ + 032
  (in-sprint); building-003 → 002 (in-sprint); villager-ai-025 → 005 ✓/009 ✓ + 012 (in-sprint).
  **`tick-007` + `villager-ai-022` REJECTED** for the committed set (need a designer value decision —
  see Out of Scope). **presentation-001 Sub-scope B REJECTED** (needs villager-ai-019). No unsatisfied
  dependency in the committed set.
- **Request-vs-reality correction (dependency depth):** the delegation named the closed job loop as
  "building-030 + villager-ai-011/012." Verified against the story files, that set is **not
  dependency-complete**: building-030 requires building-004 (release/eligibility) ← building-002
  (project entity), and villager-ai-011 requires villager-ai-010 (F2 selection) — **none of
  building-001–009 nor villager-ai-010 appear in any sprint history**. The loop therefore needs the
  full depth-3 building chain (002→004→030) and depth-3 AI chain (010→011→012), which is what this plan
  schedules. The "seams" the S6 crown left (`ConstructionTickLoop.claim_job`, villager `job_queue`
  duck-type, `PursuedActivity.WORK`) let the crown *assemble* the two halves, but the real
  release→queue→select→claim machinery is these six stories.
- **Scope check:** all committed stories are drawn from existing epics (building-system,
  villager-ai-behavior, presentation-experience) — no fabricated stories, no additions beyond epic
  scope. Run `/scope-check sprint-7` before implementation.
- **Milestone-criteria coverage this sprint:** **#2 full-depth integration** — the crown
  (villager-ai-012) closes "build → workers build → villagers navigate" end-to-end (advances from IN
  PROGRESS toward MET); **#6 Building playable** — building-002/004/030 (+005/032/003) stand up
  project lifecycle → release → job queue → attribution → undo; **#7 Villager AI playable** —
  villager-ai-010/011/012 stand up job selection → claim → on-site build cycle; **#9 ambient-life
  wave 1** — presentation-001 Sub-scope A (environmental, CD-protected); **#13 sustained stability** —
  the crown enters the commit gate, extending the sustained-green window; **#4 per-tick re-tune** —
  BLOCKED on the designer decision (measurement produced via villager-ai-025 Nice); **#12
  60-FPS-with-culling** — measurement story MISSING (flagged for creation); **#5 ADR-0015 C1/C4** —
  certified via vox-013/014 per verified context; vox-016/017 flagged for milestone-review confirmation.
- **Milestone re-baseline (S6 Action Item):** the crown landed in S6, the true Core-velocity +
  integration-cost measurement point. Re-baseline the M01 calendar estimate now that both criterion #8
  (S6) and criterion #2 (this sprint) close the integrated loop. Owner: producer. After this sprint,
  run `/milestone-review current` to assess M01 Go/No-Go — the remaining open criteria (#4 designer
  decision, #9 Sub-scope B + CD sign-off, #12 missing story, #13 stability window) are the milestone's
  closing checklist.
- **Next step:** run `/qa-plan sprint` to define test cases per story (especially the crown's
  claim→build→report cycle-stage assertions and building-030's on-site/occupied-defer/unreachable pass
  conditions) before `/dev-story`.


---

## Sprint Result — CLOSED 2026-07-24

**12/12 stories complete** (6 Must, 3 Should, 3 Nice; presentation-001 = Sub-A with CD sign-off APPROVED WITH ADVISORIES, Sub-B formally open awaiting villager-ai-019). Suite grew 682 -> 843 blocking + 5 advisory perf tests, green with 0 orphans on every story commit.

Highlights:
- **THE CROWN (villager-ai-012) landed: the closed job loop** — release -> queue -> F2 select -> claim -> travel -> on-site work -> construction ticks -> real voxel write -> report -> re-decide, all real components; assembled E2E converted to the worker-driven path (manual claim_job removed, grep-guarded). Milestone M01 criterion #2 MET.
- Building chain: BuildProject entity + release + job queue + worker attribution + registry (union-find grouping/merge, reverse index).
- Undo/redo core: plan-only (grep-guarded), bounded, transition-aware; write-seam batching with self-write tag (undo never invalidates own construction writes).
- Ambient life wave 1 Sub-A: smoke/sway/clutter/flicker per Art Bible, CD-approved with 7 advisories for later waves.
- Perf stress basis for the re-tune decision: worst per-tick 3.02ms @30 villagers (5.5x under budget); FINDING: Rule 2 periodic recheck keeps the deciding queue chronically full (bounded, never quiescent) — key re-tune input.

Process incidents: one gate near-miss — presentation-001's agent reported exit 0 but the suite exited 101 (5 test orphans from unparented GPUParticles3D under headless); caught by parent verification, root-caused, fixed same-day. Engine facts recorded: RefCounted/Object not @export-able; tests/performance/ correctly outside the blocking gate (README doc gap flagged).

Open for Sprint 8: re-tune value decision (designer numbers; measurement basis now exists), criterion #12 measurement story (file must be created), Sub-B via villager-ai-019, building-006/007/008/009 lifecycle breadth, golden-hour ambient re-shoot at Valley integration (CD advisory #2).
