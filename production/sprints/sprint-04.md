# Sprint 4 — Working Days 31–40 (nominal anchor 2026-07-24)

> Duration is expressed in **working days** per the milestone re-baseline
> (`production/estimates/estimate-rebaseline-2026-07-23.md`). Calendar span depends on
> session cadence. **Calendar note (thrice-confirmed):** Sprints 1–3 each landed their full
> commit in single back-to-back sessions (8/8, 9/9, 9/9) — measured throughput ran far above
> the 1-story/agent-day planning rate. The per-story estimate is kept as the *planning anchor*;
> it is not a calendar prediction.
> Review mode: **lean** — PR-SPRINT feasibility gate skipped (`production/review-mode.txt`).
>
> **This sprint implements milestone-review CONDITION 1 (front-load the critical chain).**
> The Voxel mesher CW-rewrite (vox-007) — the single chain that gates FIVE M01 exit criteria
> (#3 mesher, #5 residency, #6 Building, #7 Villager AI, #12 culling-perf, #8 E2E LOOP) — is
> sequenced FIRST here, deliberately concentrating the milestone's top risk into one sprint
> while the two hardest Core epics have not yet scaled up. This concentration is intentional
> (see Risks).

## Sprint Goal

Retire the milestone's critical path: land the **chunked mesher CW-winding + backface-culling
rewrite** (vox-007 — THE critical story) on top of freshly generated terrain (vox-006), so the
voxel world *renders* for the first time; complete the **camera motion set** (cam-004 zoom +
cam-005 pan, joining the S3 orbit) so the player can look at that rendered world — the sprint's
demonstrable payoff, the **windowed feel check**; deliver the Save/Load iteration primitive
(vox-005); advance the Core layer with its first real logic story, the shared **walkability
predicates** (villager-ai-002); and, capacity permitting, close the camera **Active/Suspended**
state (cam-006 ray + cam-007) to cleanly unblock Building System's opener for Sprint 5.

## Capacity

- **Total days:** 10 working days
- **Buffer (20%):** 2 days reserved — absorbs the +20% wiring/integration overhead, the mesher's
  known rework risk, and unplanned work
- **Available:** 8 days
- **Measured velocity:** ~1 story/agent-day planning anchor
  (`estimate-rebaseline-2026-07-23.md`); Sprints 1–3 delivered 8/8, 9/9, 9/9 in single sessions —
  throughput is *not* the binding constraint, the specialist queue is (see Risks).
  Mitigated by running **three** parallel owner-lanes.
- **Committed:** 8 stories = 8.5 story-days (Must 6.5 + Should 2.0)

Must-Have (6.5 days) fits inside the 8 available with 1.5 to spare — headroom deliberately left on
the binding-risk lane for the HIGH-risk mesher. Both Should-Have stories landing takes the total to
8.5, dipping 0.5 day into the 2-day buffer and leaving 1.5 intact — the identical margin discipline
Sprints 2 and 3 committed and delivered at 100%.

### Sprint 3 actuals (calibration context)

- **9/9 stories Complete** (tick-004, vox-003, vox-004, rid-004, cam-003, scene-003,
  villager-ai-001, + Should rid-005, tick-005) — including both Should-Have stories.
- **Scene/World Management epic CLOSED (3/3)**; **Villager AI epic OPENED** (villager-ai-001
  scaffold, Core layer opened); **Foundation Spine** already CLOSED in S2.
- **Test suite: 198 → 311 passing** headless (GdUnit4), zero red.
- **Zero unplanned rework, zero carryover.** cam-004/cam-005 (S3 Nice-to-have) were not pulled —
  they roll into this sprint's Must set as the feel-check camera motion.

## Tasks

### Must Have (Critical Path — the mesher chain + the feel check + open Core logic)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| vox-006 | Procedural terrain generation + single batched gen signal | `production/epics/voxel-world/story-006-procedural-terrain-generation.md` | godot-gdscript-specialist | 1 | vox-001 ✓, vox-002 ✓, vox-003 ✓ (all S1–S3 DONE) | Every in-bounds cell terrain-or-empty, Uninitialized→Generated; height ∈ [min_y,max_y]; `base_height>max_y` clamps flat + warning, no crash; at most ONE batched gen signal (never per-cell); deterministic seeded noise; passing unit test |
| vox-007 | **Chunked mesher — CW winding + backface culling ENABLED (TECH DEBT 1) — THE critical story** | `production/epics/voxel-world/story-007-chunked-mesher-cw-winding-culling.md` | godot-gdscript-specialist | 1.5 | vox-002 ✓, uses vox-004 ✓ (S2/S3 DONE) | Faces only where a cell borders air; whole-chunk rebuild on change; **CW winding + culling ENABLED verified against the engine's ACTUAL documented convention** (not a self-stored assumption); zero missing faces from any orbit angle; 60 FPS on the production window with culling re-enabled; screenshot evidence + lead sign-off |
| vox-005 | iterate_occupied API — occupied-cells iteration, torn-read-free | `production/epics/voxel-world/story-005-iterate-occupied.md` | godot-gdscript-specialist | 1 | vox-002 ✓ (S2 DONE) | `iterate_occupied()` yields only non-empty cells, never exposes chunk layout; observes only fully-committed states (serialization invariant asserted, no locks); empty grid yields nothing; passing integration test |
| cam-004 | Zoom — multiplicative, clamped, rapid-event safe | `production/epics/camera-input/story-004-multiplicative-zoom.md` | godot-specialist | 1 | cam-001 ✓, cam-002 ✓ (S1/S2 DONE) | Single wheel event multiplies distance by `zoom_factor`, clamped to `[distance_min,distance_max]`; N rapid events still respect clamp (no compounding overshoot); raw-delta; tunables from config; passing unit test |
| cam-005 | WASD pan — yaw-relative, distance-scaled, bound + delta clamp | `production/epics/camera-input/story-005-wasd-pan.md` | godot-specialist | 1 | cam-001 ✓, cam-002 ✓ (S1/S2 DONE) | Yaw-relative pan scaled by delta×distance; at a world bound zero further delta, no error, input not blocked; delta clamped to `max_delta_time` first; margin 0 valid; raw-delta; passing unit test |
| villager-ai-002 | Walkability predicates (`is_standable` / `is_step_legal`) — shared pure functions — **first real Core logic story** | `production/epics/villager-ai-behavior/story-002-walkability-predicates.md` | ai-programmer | 1 | villager-ai-001 ✓ (S3 DONE) | `is_standable` (solid-below + 3-cell clearance) and `is_step_legal` (\|dy\|≤1; diagonal only if both flankers passable — no corner-cutting) as pure side-effect-free functions over Voxel World occupancy; Planned blueprint cells non-solid; shared constants (no inline literals); the single source of truth every consumer calls (no second copy); passing unit test |

### Should Have (complete the camera Active/Suspended set — the natural cut lever + Sprint-5 unblock)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| cam-006 | Mouse world-ray API + ground-plane intersection (always computable) | `production/epics/camera-input/story-006-mouse-world-ray-api.md` | godot-specialist | 1 | cam-001 ✓ (S1 DONE) | `get_world_ray()` always computable (incl. Suspended); origin+direction from the same screen point same frame; round-trip within 1px; never calls Voxel World (grep-clean); passing unit test |
| cam-007 | Active/Suspended state machine — scene-transition suspend, exact-state restore | `production/epics/camera-input/story-007-active-suspended-state.md` | godot-specialist | 1 | cam-003 ✓ (S3); cam-004, cam-005, cam-006 (in-sprint — must land first) | Suspended on transition-begin (no rotate/zoom/pan/dispatch); released on complete OR abort (never complete alone); exact yaw/pitch/distance/target restore within 1e-4; held rotate button dropped; Suspended ≠ Pause; passing integration test |

### Nice to Have (parallel-lane fill — pull only if the gdscript voxel lane clears early)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| vox-008 | Floor/terrain replace write path | `production/epics/voxel-world/story-008-floor-terrain-replace-write-path.md` | godot-gdscript-specialist | 1 | vox-003 ✓, vox-006 (in-sprint) | Only pull if vox-006→vox-007 clears with lane headroom; a write-path story that chains off terrain gen and feeds the Building voxel-write seam later. Do NOT pull if it would crowd vox-007's buffer. |

> The camera set completes here: S3 landed cam-003 (orbit); this sprint's cam-004 (zoom) + cam-005
> (pan) are Must (the feel check needs full motion), and cam-006 (ray) + cam-007 (Suspended) are the
> Should pair that closes the Active/Suspended state machine. cam-007's only in-sprint prerequisite
> from the Should tier is cam-006 (cam-004/005 are Must and will already be down) — a depth-2 chain,
> the same shape as S3's rid-004→005. Completing cam-007 is what cleanly unblocks Building System's
> tool state machine (building-019) for Sprint 5.

## Core-Layer Decision — DEFER building-019 to Sprint 5; open Core *logic* this sprint with villager-ai-002

**Decision: do NOT open Building System with `building-019` (tool state machine) this sprint.
Defer it to Sprint 5. Advance Core this sprint with `villager-ai-002` (walkability predicates)
instead.** Rationale (verified against the real story files):

1. **building-019's hard dependency is still not DONE at sprint start.** `building-019`
   `Depends on: Camera & Input (action signals, **Suspended state**)`. Action signals (cam-002)
   are DONE, but the **Suspended state is cam-007**, and cam-007 itself `Depends on: cam-003
   (✓), cam-004, cam-005, cam-006` — a depth-4 in-sprint camera chain. Even with cam-006/cam-007
   pulled in as Should-Have this sprint, cam-007 only goes green at the *end* of that chain.
   building-019 could therefore not start until the final sprint day, making it a **depth-5
   in-sprint chain landing on day 10** — deeper and more fragile than any chain S1–S3 ran (those
   were depth-2). And its own **AC37** ("Suspended entered mid-drag → drag aborts") cannot be
   tested at all until cam-007's Suspended state exists to drive it. Pulling it in would be a
   fake unblock.
2. **This sprint's mandate is front-loading the mesher critical chain (Condition 1).** vox-007 is
   HIGH-risk (1.5 days, the slice's known multi-session "missing faces" rewrite). Concentrating
   the mesher risk AND a depth-5 dependency chain AND the largest Core epic's opener into one
   sprint would over-load the sprint's risk budget. The disciplined move is to retire the mesher
   first and open Building on a stable, already-DONE camera Suspended state next sprint.
3. **Core still advances — with real logic, not just a scaffold.** S3 opened the Core layer with
   the villager *scaffold* (villager-ai-001). This sprint lands the first real Core logic story,
   `villager-ai-002` (the shared walkability predicates), whose only dependency (villager-ai-001)
   is DONE. These pure functions are the single source of truth the AStar graph (007), watchdog
   rescue BFS (014), and Build Validation all later call — high-leverage, low-integration-risk
   Core progress that keeps the third lane productive without forcing the camera→building chain.
4. **building-019 opens Sprint 5 cleanly** once cam-004/005/006/007 have landed and stabilized
   here (exactly the sequencing the S3 plan itself anticipated: "building-019 becomes the natural
   Sprint-4 Core opener once cam-003/004/005/007 land" — but cam-007 only *lands* this sprint, so
   the opener is Sprint 5, not Sprint 4). This is a deliberate, documented deferral with milestone
   visibility, not a silent slip.

## Critical Path

**`vox-007`** (chunked mesher, CW winding + culling) is THE critical story — the milestone risk
register flags it as the single chain gating five exit criteria. Sequence it FIRST on the gdscript
lane, immediately after **`vox-006`** (which gives it terrain geometry to mesh and demonstrate
against). `vox-005` (iterate_occupied) is independent (a Save/Load primitive, depends only on
vox-002) and is the lane's flexible fill — slot it around the vox-006→vox-007 priority pair, not
ahead of it. Keep the gdscript lane deliberately light (3.5 story-days) so vox-007's 1.5 days carry
buffer headroom rather than a queue behind them.

**The windowed feel check lands exactly when vox-007 does.** Until the mesher renders, there is
nothing to look at; once it does, cam-003 (orbit, S3) + cam-004 (zoom) + cam-005 (pan) make the
rendered terrain fully inspectable — the sprint's demonstrable payoff and the first proof the
voxel world is real. If vox-007 slips, the feel check slips with it (the camera motion lands
regardless, but has nothing to frame).

**Owner lanes (serialization mitigation):**
- **godot-gdscript-specialist** (voxel critical chain — the risk lane): vox-006 → vox-007 → vox-005
  (~3.5 story-days; kept light on purpose for mesher headroom; vox-008 is the Nice pull if it clears)
- **godot-specialist** (camera — the binding lane if both Should land): cam-004 → cam-005 (Must) →
  cam-006 → cam-007 (Should) — ~4 story-days
- **ai-programmer** (Core logic): villager-ai-002 — 1 day, a single-story load on the newly-opened epic

In-sprint chain to sequence parents-first: **cam-006 → cam-007** (cam-007 also needs cam-004/005,
which are Must and land first). cam-007 is a Should-Have and is the pre-designated cut if the camera
lane runs hot.

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| None | Sprint 3 delivered 9/9 — no carryover, zero unplanned rework | — |

*(cam-004 and cam-005 were S3 Nice-to-have, never committed there — they are promoted to this
sprint's Must set as the feel-check camera motion, not carried-over incomplete work.)*

## Out of Scope (deferred to Sprint 5+)

- **vox-015 (mesh view-window streaming)** — **NOT sequenceable this sprint.** Its real story file
  `Depends on: Story 007 (✓ this sprint), Story 010 (residency), Story 012 (time-budget discipline)`
  — but **010 and 012 are the ADR-0015 residency cluster, neither DONE nor in this sprint's scope.**
  vox-015 streams *meshes* but its dependencies require the data-residency tier (010) and the
  time-based streaming budget (012) to exist first. It defers to Sprint 5 alongside the residency
  cluster (vox-010/011/012). The Sprint-4 mesher (vox-007) renders the world for the feel check;
  view-window streaming is the perform-at-scale story that follows residency, not this sprint.
- **building-019 (tool state machine)** — deferred to Sprint 5 per the Core-Layer Decision above
  (its cam-007 Suspended dependency only *lands* this sprint; the opener is next sprint).
- **vox-009–014, vox-016/017 (dig write path, residency tier, ADR-0015 C1/C4)** — the residency
  cluster (Condition 1's second half) follows the mesher; sequence in Sprint 5 with vox-015. The
  storage-residency-spike prototype (active in the working tree) continues de-risking it ahead of
  the production stories.
- **cam-008 (click arbitration), cam-009 (raw-delta/pause contract)** — follow cam-007; Sprint 5.
- **Building System (all 33 stories)** — opens Sprint 5 with building-019 once cam-007 is DONE and
  vox-004 DDA pick (S3) + vox-007 mesher (this sprint) are available for its placement pick.
- **villager-ai-003+ (body-column, deterministic position, deciding scheduler, AStar3D, FSM
  behaviors)** — follow the predicates (villager-ai-002) opened this sprint; Sprint 5+.
- **CD-protected items (ambient-life wave 1, loop-payoff scaffolding)** — now homed in the new
  `presentation-experience` micro-epic (created 2026-07-24, closing the epics-index CD-mapping gap
  and milestone Action Item #3). Dependency-gated behind vox-007 (this sprint) + the villager
  FSM/movement stories; scheduled for the Presentation pass (Sprint 5+). Cutting either requires
  CD sign-off.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **Critical-chain concentration THIS sprint is DELIBERATE** — vox-007 gates five exit criteria and the entire feel check keys off one HIGH-risk story landing. This is not an accident of planning; it is milestone-review Condition 1 (retire the critical path before Building/Villager scale up) | High (by design) | High if it slips | **Chosen concentration, stated openly.** Mitigations: gdscript lane kept light (3.5d) so vox-007 carries buffer headroom, not a queue; its deps (vox-002/003/004) are all DONE and green; sequence vox-006→vox-007 EARLY, never on the last day; the storage-residency-spike prototype already de-risks the adjacent storage tier. The alternative — spreading the mesher across two sprints — leaves the milestone's top risk live longer and blocks Building/Villager. |
| **Mesher rework risk** — vox-007 is the slice's known multi-session "missing faces" pain (CCW-vs-CW winding). A second pass could cascade into the feel check and everything downstream | Medium | High | Written **fresh** to CW + culling-enabled from the start (slice code is reference-only; do NOT port its CCW + `CULL_DISABLED` mitigation). Winding validated against `docs/engine-reference/godot/`'s ACTUAL documented convention — never a self-stored assumption (that assumption WAS the slice's root cause). Visual/Feel screenshot evidence from a full 360°/pitch orbit + lead sign-off; the slice held 60 FPS at 2× faces on `CULL_DISABLED`, so culling-on has headroom. |
| **The feel check lands only when vox-007 lands** — if the mesher slips, the sprint's demonstrable payoff (orbit rendered terrain) slips with it | Medium | Med | Sequence vox-006→vox-007 first, not last; camera motion (cam-004/005) is fully independent (deps cam-001/002 DONE) and lands regardless, so the camera half of the feel check is never blocked — only the thing it frames is. vox-007 given 1.5d + lane headroom. |
| **Godot 4.7 API deviation** — vox-007 (ArrayMesh + CW winding, **HIGH** rendering domain) and cam-007 (transition-signal contract binding) touch flagged post-cutoff facts | Medium | Med | Every rendering/signal API cross-referenced against `docs/engine-reference/godot/` before use, enforced per story Engine Notes. vox-007 carries the sprint's only HIGH engine-risk on the render path — scheduled with buffer headroom, not on the last day. CONTRACTS.md (published S2) reduces the contract-onboarding half. |
| **building-019 deferral** — the largest Core epic (Building, 33 stories) does not open this sprint; its opener slips to S5 | Medium | Low-Med | Deliberate and documented (Core-Layer Decision). Core still advances via villager-ai-002 (real logic, not just scaffold). cam-006/007 (Should) tee up building-019's clean S5 open. Not a silent slip — milestone-visible, and cutting/reshaping tracked. |
| **Single-specialist serialization** — the godot-specialist camera lane is the binding lane at ~4 story-days (cam-004/005/006/007); the ~1/day anchor assumes parallel agents, a single queue serializes wall-clock | Medium | Low-Med | Three parallel owner-lanes (gdscript / godot-specialist / ai-programmer). cam-006/007 are Should-Have — the cut levers if the camera lane runs hot; the Must set (cam-004/005 only, 2d) fits comfortably. The 2-day buffer absorbs residual. |
| **In-sprint chain cam-006 → cam-007** — a parent slip strands the child | Medium | Low | Sequence cam-006 before cam-007; cam-007 is the pre-designated cut (Should-Have) if cam-006 or the Must camera stories run hot. Same discipline as S3's rid-004→005, tick-004→005 (both delivered). |
| **Recurring typed-Array crash class** (0 in S1/S2/S3) | Low | Low | Keep the regression call in the E2E gate; preview/mesh-build paths watched; budgeted inside buffer. Three clean sprints — retained but low. |

## Dependencies on External Factors

- **Control-manifest version 2026-07-23** — all Sprint 4 stories embed this version. Confirmed
  current for Sprints 1–3; re-confirm unchanged before vox-006 starts. Owner: technical-director.
- **No art/audio external dependency** for the committed set (Foundation voxel/camera logic +
  first Core predicate). vox-007's evidence is a screenshot pass — it needs the mesher output
  itself, not external art assets. The CD-protected experience items (now homed in
  `presentation-experience`) are gated behind this sprint's mesher + the villager FSM and land in
  the Presentation pass — no external dependency blocks Sprint 4.

## Definition of Done for this Sprint

- [ ] All Must Have stories completed (the voxel world renders: vox-006 terrain + vox-007 mesher green)
- [ ] All tasks pass acceptance criteria
- [ ] Every Logic story (vox-006, cam-004, cam-005, villager-ai-002, + Should cam-006) has a passing
      GdUnit4 headless unit test in `neues-spiel/tests/unit/...` — BLOCKING
- [ ] Every Integration story (vox-005, + Should cam-007) has a passing headless integration test in
      `neues-spiel/tests/integration/...` — BLOCKING
- [ ] vox-007 (Visual/Feel) has screenshot evidence + lead sign-off in
      `production/qa/evidence/chunked-mesher-cw-winding-culling-evidence.md` — BLOCKING for the
      culling-re-enabled exit criterion (#12); winding confirmed against the engine reference
- [ ] The windowed feel check demonstrated: orbit/zoom/pan around rendered terrain, 60 FPS with
      culling enabled
- [ ] Tests deterministic, isolated, DI-mockable (no Autoload registration, no file I/O)
- [ ] QA plan exists for Sprint 4 (`production/qa/qa-plan-sprint-4-*.md`) — run `/qa-plan sprint`
      before implementation begins (none exists yet — see warning below)
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No open S1 or S2 bugs in delivered stories
- [ ] Design/ADR docs updated for any deviation discovered during implementation (esp. any mesher
      finding that should amend ADR-0014)
- [ ] Code reviewed and merged (trunk-based)

> ⚠️ **No QA Plan**: This sprint was planned without a Sprint-4 QA plan (only sprint-1 and sprint-2
> QA plans exist; sprint-3 also lacked one). Run `/qa-plan sprint` before the last story is
> implemented. The Production → Polish gate requires a QA sign-off report, which requires a QA plan.
> vox-007's Visual/Feel screenshot gate in particular needs its pass conditions defined up front.

## Notes

- **Dependencies-satisfied check:** every Sprint-4 committed story was verified against its real
  story file's `## Dependencies` section (not the request list). vox-005/006/007 resolve to S1–S3
  DONE voxel stories (002/003/004) and each other; cam-004/005/006 to DONE camera stories (001/002);
  cam-007 to cam-003 (DONE) + in-sprint cam-004/005/006; villager-ai-002 to villager-ai-001 (DONE).
  **vox-015 was REJECTED** for Sprint 4 — its residency (010) and time-budget (012) dependencies are
  neither DONE nor in scope. **building-019 was DEFERRED** to Sprint 5 — its cam-007 Suspended
  dependency only lands this sprint (see the Core-Layer Decision). No unsatisfied dependency in the
  committed set.
- **Scope check:** all 8 committed stories are drawn from existing epics with no additions beyond
  epic scope. Run `/scope-check sprint-4` before implementation if any story grows (vox-007 is the
  one to watch — mesher rework has historically expanded).
- **Milestone recalibration due (Action Item #4):** re-baseline the M01 calendar estimate after the
  first 3–4 Core stories + the mesher/residency chain land — this sprint lands the mesher and the
  first Core logic story (villager-ai-002), so mid-Sprint-4 is the first true Core-velocity
  measurement point. Owner: producer.
- **Next step:** run `/qa-plan sprint` to define test cases per story (especially vox-007's
  screenshot pass conditions) before `/dev-story`.
