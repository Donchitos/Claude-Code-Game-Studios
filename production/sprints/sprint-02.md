# Sprint 2 — Working Days 11–20 (nominal anchor 2026-07-23)

> Duration is expressed in **working days** per the milestone and re-baseline
> (`production/estimates/estimate-rebaseline-2026-07-23.md`). Calendar span depends on
> session cadence. **Sprint 1 calendar note (honest):** the 8 nominal working-day plan
> landed in a single back-to-back session — measured throughput ran far above the
> 1-story/agent-day planning rate when stories are run consecutively. The per-story
> estimate is kept as the *planning anchor*; it is not a calendar prediction.
> Review mode: **lean** — PR-SPRINT feasibility gate skipped (`production/review-mode.txt`).

## Sprint Goal

Close out the Foundation Spine — prove the boot path is headless-green (the milestone's
Success-Criterion-#1 boot test) and publish CONTRACTS.md — and advance every one of the
five Foundation tracks one story past its Sprint-1 starter: RID's read-only query surface,
Time & Tick's `game_delta` + pause/warp state, Camera & Input's InputMap passthrough,
Voxel World's chunked cell storage, and Scene/World Management's World-Root/Valley
topology with its boot gate. End-of-sprint the spine is *done* and each track has a
consumable API for the Core-layer work that follows.

## Capacity

- **Total days:** 10 working days
- **Buffer (20%):** 2 days reserved — absorbs the measured +20% wiring/integration
  overhead (typed-Array crash class, CONTRACTS wiring gaps) plus unplanned work
- **Available:** 8 days
- **Measured velocity:** ~1 story/agent-day (`estimate-rebaseline-2026-07-23.md`), and
  Sprint 1 delivered 8/8 in one session — throughput is *not* the binding constraint;
  the single-specialist queue is (see Risks).
- **Committed:** 9 stories = 8.5 story-days (Must 6.5 + Should 2.0)

Must-Have (6.5 days) fits inside the 8 available with 1.5 to spare. Both Should-Have
stories landing takes the total to 8.5, dipping 0.5 day into the 2-day buffer and
leaving 1.5 day of buffer intact. This mirrors Sprint 1's deliberate hold of margin,
now with one sprint of calibration behind it: Sprint 1 landed 8/8 at the production
quality bar with the full suite green (121/121), so the quality-delta risk that capped
Sprint 1 at 8-of-9 is now evidenced as absorbable — Sprint 2 commits the fuller set.

### Sprint 1 actuals (calibration context)

- **8/8 stories Complete** (spine-001/002/003, rid-001/002, tick-001, cam-001, vox-001).
- **Test suite: 121/121 passing** headless (GdUnit4).
- **Three upstream doc defects found-and-fixed, not shipped** — caught during
  implementation before they reached the build (the +20% wiring-overhead budget is what
  paid for finding them; keep the budget).
- Calendar compression: the 8 nominal-day plan ran to completion in one back-to-back
  session. Kept the per-story estimate as a planning anchor; do not re-baseline the rate
  off a single compressed run.

## Tasks

### Must Have (Critical Path — complete the spine + one story per Foundation track)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| spine-004 | Headless boot integration test — DI wiring + gate + config reads green (Milestone Success-Criterion #1) | `production/epics/foundation-spine/story-004-headless-boot-integration-test.md` | godot-gdscript-specialist | 1 | spine-001, spine-002, spine-003 ✓ (all S1 DONE) | Mock-RID Ready → boot reaches ACTIVE, each injected module `setup()` exactly once; ≥1 module reads injected config (not literal); Failed → HALTED + zero `setup()`; green via `tests/run-tests.cmd`; deterministic |
| spine-005 | CONTRACTS.md — spine contract sheet (DI/Config/Boot/Data-Definition) + immutability contract | `production/epics/foundation-spine/story-005-contracts-md-and-data-definition-contract.md` | godot-gdscript-specialist | 0.5 | spine-001–003 ✓ (S1); spine-004 (in-sprint — finalize after it lands) | Four contracts present, each cites governing ADR + TR-IDs; shared terminal-halt severity noted; authored fresh (not slice copy); RID epic implementable from it alone |
| rid-003 | Read-only lookup API — `get_by_id` + listing queries (getter-only wrappers) | `production/epics/resource-item-database/story-003-lookup-api.md` | godot-gdscript-specialist | 1 | rid-001, rid-002 ✓ (both S1 DONE) | get-by-id + list-by-{category,family,tier} + list-all; unknown id → explicit not-found + log, no crash; empty category → empty list; no write API; passing unit test |
| tick-002 | `game_delta` computation — formula, clamp precedence, raw-delta preservation | `production/epics/time-tick-system/story-002-game-delta-computation.md` | godot-gdscript-specialist | 1 | tick-001 ✓ (S1 DONE) | `game_delta = clamp(raw,0,max)*warp*(paused?0:1)` within 1e-6; clamp before warp; raw engine delta untouched; `max_raw_delta` from config; passing unit test |
| cam-002 | InputMap action registration + `action_fired` opaque passthrough | `production/epics/camera-input/story-002-inputmap-registration-action-passthrough.md` | godot-specialist | 1 | cam-001 ✓ (S1 DONE) | Every downstream-referenced action registered at project scope; `action_fired` payload = action-name string only, zero branch on it; no `event.device` branch; no hardcoded device id `0`; passing integration test/playtest |
| vox-002 | Chunked packed-array storage + O(1) accessors + single-cell `cell_changed` | `production/epics/voxel-world/story-002-chunked-cell-storage-and-accessors.md` | godot-gdscript-specialist | 1 | vox-001 ✓ (S1 DONE) | One occupant/cell, no layering; `get_cell` = last write; `set_cell` returns prev + emits one `cell_changed(cell,before,after)`; reads never mutate; ids opaque (no RID call); packed arrays not Dictionary; passing unit test |
| scene-001 | World Root + single-Valley attach topology ⚠️ NEEDS-DECISION (see Risks) | `production/epics/scene-world-management/story-001-world-root-valley-attach.md` | godot-specialist | 1 | Foundation Spine spine-001 ✓ (S1 DONE — World Root IS GameWorld's root) | Boot → Valley active, no menu/loading (M01 behavior); Valley child of persistent World Root; World Root never freed; scene handoff via child add/remove — banned APIs grep-zero; passing integration test |

### Should Have (in-sprint dependency chains — the natural cut lever)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| tick-003 | Pause & time-warp state — toggle, store, independence, idempotency | `production/epics/time-tick-system/story-003-pause-warp-state.md` | godot-gdscript-specialist | 1 | tick-002 (in-sprint — must land first) | Warp ∈ {1,2,3}; pause sets `game_delta`=0 preserving stored warp; warp-while-paused stored, applies on resume; idempotent pause (no duplicate side effects); no debounce; accumulator untouched by warp; passing unit test |
| scene-002 | Boot-gate integration — Valley attaches only after RID Ready; DB-fail → terminal HALT | `production/epics/scene-world-management/story-002-boot-gate-integration.md` | godot-specialist | 1 | scene-001 (in-sprint) + Foundation Spine spine-002 ✓ (S1 DONE) | Ready → Valley attaches then Building/Villager `setup()` (ordered by gate); Failed → HALT screen, no Valley node, zero `setup()`; HALT is non-progression, not `SceneTree.paused`; passing integration test |

### Nice to Have

None. tick-004 (tick accumulator), rid-004+ (validation pipeline), cam-003+ (orbit/zoom/pan),
vox-003+ (bulk write/DDA), and scene-003 (transition contract) all depend on a Should-Have
story landing first and are the natural head of Sprint 3 — not speculatively pulled forward
against in-sprint parents that must complete first.

## Critical Path

**`spine-004 → spine-005`** is the critical path: spine-004 is Milestone Success-Criterion #1
(the headless boot test the whole milestone is verified against) and it unblocks spine-005
(CONTRACTS.md, a Must-Ship milestone deliverable). Completing both *closes the Foundation
Spine epic* — every downstream Core story inherits a proven boot substrate and a written
contract sheet. Sequence spine-004 first; draft spine-005 in parallel, finalize once 004 is green.

Two secondary in-sprint chains: **`tick-002 → tick-003`** (pause is a factor inside the
`game_delta` formula) and **`scene-001 → scene-002`** (the gate reaction needs the topology
first). rid-003, cam-002, and vox-002 are fully independent of each other and of the chains —
they are the clean parallelization lever and the safe first pulls if a chain runs hot.

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| None | Sprint 1 delivered 8/8 — no carryover | — |

## Out of Scope (deferred to Sprint 3+)

- **tick-004 (tick accumulator/signal), tick-005 (max-ticks cap), tick-006 (cross-system
  integration)** — depend on tick-003; the `tick` signal surface lands Sprint 3.
- **rid-004–009 (validation schema/invariants, visual-asset checks, missing-item fallback,
  footprint validation, MVP content)** — the read API (rid-003) is this sprint's need; the
  full boot-validation pipeline + shipped content are Sprint 3.
- **cam-003–009 (orbit, zoom, pan, world-ray, arbitration, raw-delta contract)** — the
  input *motion* pipeline and `get_world_ray()` (consumed by Building System's pick) follow
  the passthrough (cam-002); Sprint 3.
- **vox-003–017 (bulk write, DDA raycast, iterate_occupied, terrain gen, mesher CW-winding,
  paged residency, ADR-0015 C1/C4)** — Sprint 3 (mesher rewrite + residency tuning are the
  M01 tech-debt items, targeted S2–S3 in the milestone; they need the storage layer first).
- **scene-003 (transition-signal contract surface)** — depends on scene-002; Sprint 3.
- **Building System / Villager AI (Core layer)** — begin once the Foundation tracks expose
  their consumable APIs (this sprint's output); Sprint 3+.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **Single-specialist serialization** — 6 of 9 stories route to `godot-gdscript-specialist`; ~1/day velocity assumes parallel agents, a single queue serializes toward ~1/day wall-clock | Medium | Low-Med | Improved from Sprint 1's 7/8 — 3 stories (cam-002, scene-001, scene-002) split to godot-specialist, so the two specialists run in parallel. 2-day buffer absorbs the residual; Should-Have chain is droppable without touching the critical path. |
| **NEEDS-DECISION on scene-001** — boot-flow: straight-to-Valley (GDD) vs. MainMenu state before InValley (approved main-menu.md, Alpha-tier); needs ADR-0012 amendment | High (unresolved) | Low for M01 | Does NOT block M01. scene-001 implements boot-straight-to-Valley *as written*; the AC even guards that no `MainMenu` node exists in the M01 tree. Resolution owner: **technical-director**, before the Main Menu ships (Alpha). Carried forward from Sprint 1 so it is not lost. |
| **Production quality bar vs slice standards** (was Medium-confidence variable) | Low-Med (down from Medium) | Medium | Sprint 1 calibration: 8/8 landed at the production bar, suite 121/121, three doc defects caught pre-ship. The delta is now *evidenced as absorbable* — which is why Sprint 2 commits 9 stories, not 8. Keep the +20% wiring budget that paid for the defect catches. |
| **Godot 4.7 API deviation** — Sprint 2 first touches input (cam-002: 4.7 changed device IDs to `DEVICE_ID_MOUSE`/`_KEYBOARD`) and voxel storage (vox-002 rated **HIGH** — packed-array vs Dictionary, chunk indexing) | Medium | Med (up from Low-Med) | Every API cross-referenced against `docs/engine-reference/godot/` before use, enforced per story Engine Notes. vox-002 carries the epic's only HIGH engine-risk this sprint — sequence it with buffer headroom, not on the last day. |
| **In-sprint dependency chains** — spine-005←004, tick-003←002, scene-002←001; a parent slip strands the child mid-sprint | Medium | Low-Med | Sequence parents first (spine-004, tick-002, scene-001 early); the three chain-heads (spine-004, tick-002, scene-001) are all Must-Have. If a parent runs hot, its Should-Have child (tick-003/scene-002) is the pre-designated cut. |
| **Recurring typed-Array crash class** (3 incidents in 5 slice days; 0 in Sprint 1) | Low-Med | Low | Keep the regression call in the E2E gate; preview paths deliberately untyped; budgeted inside buffer. Downgraded from Sprint 1 after a clean sprint but not retired. |
| **PROVISIONAL cross-system re-tune halves** (tick-007 tick-budget ↔ villager `max_deciding_per_tick`) | Medium | Low | Correctly deferred — needs the integrated build to measure. Flagged so the paired coordination is not forgotten when it lands (S3+). |

## Dependencies on External Factors

- **Control-manifest version 2026-07-23** — all Sprint 2 stories embed this version.
  Confirmed current for Sprint 1; re-confirm unchanged before spine-004 starts. Owner:
  technical-director.
- No art/audio external dependency for Sprint 2 (pure Foundation logic + scene topology;
  no assets consumed). CD-protected experience items (ambient-life, loop-payoff scaffolding)
  are Sprint-3 targets — not in this sprint.

## Definition of Done for this Sprint

- [ ] All Must Have stories completed (Foundation Spine epic closed: spine-004 + spine-005)
- [ ] All tasks pass acceptance criteria
- [ ] Every Logic story (rid-003, tick-002, tick-003, vox-002) has a passing GdUnit4 headless
      unit test in `neues-spiel/tests/unit/...` — BLOCKING
- [ ] Every Integration story (spine-004, cam-002, scene-001, scene-002) has a passing headless
      integration test in `neues-spiel/tests/integration/...` — BLOCKING
- [ ] spine-005 (Config/Data) has a smoke-check pass recorded confirming CONTRACTS.md
      completeness against the four ADRs
- [ ] Tests deterministic, isolated, DI-mockable (no Autoload registration, no file I/O)
- [ ] QA plan exists for Sprint 2 (`production/qa/qa-plan-sprint-2-*.md`) — run `/qa-plan sprint`
      before implementation begins (none exists yet — see warning below)
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No open S1 or S2 bugs in delivered stories
- [ ] Design/ADR docs updated for any deviation discovered during implementation
- [ ] Code reviewed and merged (trunk-based)

> ⚠️ **No QA Plan**: This sprint was planned without a Sprint-2 QA plan (only
> `production/qa/qa-plan-sprint-1-2026-07-23.md` exists). Run `/qa-plan sprint` before the
> last story is implemented. The Production → Polish gate requires a QA sign-off report,
> which requires a QA plan.

## Notes

- **Dependencies-satisfied check:** every Sprint-2 story was verified against its real story
  file's `## Dependencies` section (not the request list). All Must-Have external dependencies
  resolve to Sprint-1 DONE stories; all in-sprint dependencies (spine-005←004, tick-003←002,
  scene-002←001) are sequenced within this sprint. No unsatisfied dependency.
- **Scope check:** all 9 stories are drawn from existing Foundation epics with no additions
  beyond epic scope. Run `/scope-check sprint-2` before implementation if any story grows.
- **Next step:** run `/qa-plan sprint` to define test cases per story before `/dev-story`.
