# Sprint 1 — Working Days 1–10 (nominal anchor 2026-07-23)

> Duration is expressed in **working days** per the milestone and re-baseline
> (`production/estimates/estimate-rebaseline-2026-07-23.md`). Calendar span depends on
> session cadence (the slice's 5 build days spanned 11 calendar days).
> Review mode: **lean** — PR-SPRINT feasibility gate skipped (`production/review-mode.txt`).

## Sprint Goal

Stand up the Foundation spine — the boot gate, DI scaffold, and config pattern every
module attaches to — and open the three independent Foundation tracks (Time & Tick,
Camera, Voxel data) with their first config-and-contract stories, so that end-of-sprint
we can prove DI-mockable modules boot behind the RID gate.

## Capacity

- **Total days:** 10 working days
- **Buffer (20%):** 2 days reserved — absorbs the measured +20% wiring/integration
  overhead (recurring typed-Array crash class, CONTRACTS wiring gaps) plus unplanned work
- **Available:** 8 days
- **Measured velocity:** ~1 story/agent-day (`estimate-rebaseline-2026-07-23.md`)
- **Committed:** 8 stories = 8 story-days

Committing **8, not 9**, deliberately: this is the first production sprint at the new
quality bar (data-driven config, DI-over-singletons, blocking tests per logic AC). The
re-baseline rates the production-vs-slice quality delta only Medium-confidence, so the
9th slot is held as margin until we have one sprint of calibration. If Sprint 1 lands
ahead, the first Sprint-2 story pulls forward trivially.

**Throughput caveat:** 7 of 8 stories route to `godot-gdscript-specialist` (all `.gd`
per the file-routing rule). The ~1 story/day velocity assumes *parallel* agents; a
single-specialist queue serializes toward ~1/day wall-clock. The 2-day buffer covers
this and is why the sprint was not packed to 9.

## Tasks

### Must Have (Critical Path — the spine + RID gate)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| spine-001 | GameWorld root + injected-tier DI scaffold (`setup()` wiring) | `production/epics/foundation-spine/story-001-gameworld-di-scaffold.md` | godot-gdscript-specialist | 1 | None ✓ (epic leaf) | Reference module DI-mockable headless; `setup()` asserts wiring; no Autoload `@export`; no `_ready()` dep reads |
| rid-001 | ItemDefinition two-type split + getter-only immutability | `production/epics/resource-item-database/story-001-item-definition-two-type-split.md` | godot-gdscript-specialist | 1 | None ✓ (Foundation leaf) | 11-field round-trip; getter-only (zero setters); cache integrity across intervening queries |
| rid-002 | RID Autoload + load-once + Ready state + boot-gate signal | `production/epics/resource-item-database/story-002-autoload-boot-gate.md` | godot-gdscript-specialist | 1 | rid-001 ✓ (in-sprint) | Ready on valid data; load-once rejected; non-Ready query → error; `validation_complete` drives gate |
| spine-002 | Boot-sequencing gate — BootState machine + RID Ready/Failed gate | `production/epics/foundation-spine/story-002-boot-sequencing-gate.md` | godot-gdscript-specialist | 1 | spine-001 ✓; tests vs mock RID double (not hard-blocked on rid-002) | Failed → no `setup()`, HALT; Ready (sync + signal) → each `setup()` once, ACTIVE; single choke point |
| spine-003 | Config Resource pattern — typed `.tres` + `validate()` two-tier clamp/halt | `production/epics/foundation-spine/story-003-config-resource-pattern.md` | godot-gdscript-specialist | 1 | spine-001, spine-002 ✓ (in-sprint) | Valid config → no issues; single-field → warn+clamp+proceed; blocking invariant → terminal halt (reuses gate); read-only enforced |

### Should Have (independent early-track starters — the natural cut lever)

| ID | Task | Story File | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-----------|-------------|-----------|-------------|--------------------|
| tick-001 | Time & Tick Autoload skeleton + config resource + boot defaults | `production/epics/time-tick-system/story-001-autoload-config-boot-defaults.md` | godot-gdscript-specialist | 1 | None ✓ (consumes nothing) | 4 tunables config-driven; boots `paused=false`, `warp=1`; `validate()` clamps; Autoload zero-upstream |
| cam-001 | Camera config + spherical position derivation | `production/epics/camera-input/story-001-camera-config-spherical-derivation.md` | godot-specialist | 1 | None ✓ (module foundation) | Position = target + spherical offset (never stored); pitch clamp 0.15–1.5 rad; tunables from config |
| vox-001 | Grid config + coordinate math + bounds | `production/epics/voxel-world/story-001-grid-config-and-coordinate-math.md` | godot-gdscript-specialist | 1 | None ✓ (module foundation) | Bounded grid, no negative cells; Cell↔World (center / floor); out-of-grid sentinel; `min_y≤max_y` blocking invariant |

### Nice to Have

None. First production sprint — no speculative pull-forward staged against an
uncalibrated quality bar.

## Critical Path

`spine-001 → spine-002 → spine-003`. The config pattern (spine-003) gates every module's
`.tres`; the boot gate (spine-002) gates every module's `setup()` — any slip here
cascades to all of Sprint 2. Second-priority chain: `rid-001 → rid-002` (supplies the
real gate signal shape). The three Should-Have starters are fully parallel and are the
clean cut lever if the spine runs hot.

## Carryover from Previous Sprint

None — this is Sprint 1.

## Out of Scope (deferred to Sprint 2+; 18 of the 26-story candidate pool)

- **spine-004 (headless boot integration test), spine-005 (CONTRACTS.md finalize)** —
  004 needs real RID (rid-002) + config (spine-003) wired together; it is the S1/S2 seam
  integration proof, best early Sprint 2. 005 finalizes after 004.
- **rid-003 (lookup API), rid-004–009 (validation pipeline + content)** — the Ready/Failed
  gate is the S1 need; query surface + full validation land Sprint 2.
- **tick-002–004 (game_delta, pause/warp, tick accumulator)** — depend on tick-001; Sprint 2.
- **cam-002–006 (InputMap, orbit, zoom, pan, world-ray)** — depend on cam-001; the input
  pipeline + `get_world_ray()` (consumed by Building System's pick) are Sprint 2.
- **vox-002–006 (chunk storage, bulk write, DDA, iterate_occupied, terrain)** — Sprint 2
  (milestone Voxel S1–S2 target).
- **scene-world-management 001–002** — 001 depends on spine-001, 002 on spine-002; both
  fit early Sprint 2 once the spine is DONE. Held out of S1 to keep the spine chain
  unblocked and capacity honest. (001 carries a NEEDS-DECISION flag — see Risks.)
- **Re-tune / tech-debt stories (LATER material):** mesher CW-winding (vox-007), ADR-0015
  C1/C4 (vox-016/017), per-tick re-tune tick-budget half (tick-007) + `max_deciding_per_tick`
  half (villager epic). All need the *integrated* build to measure against production load.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| NEEDS-DECISION on scene-world 001 (boot-flow: straight-to-Valley vs. Main-Menu state; ADR-0012 amendment) | High (unresolved) | Low for M01 | Does not block M01; story implements boot-straight-to-Valley as written and is out of *this* sprint. Resolution owner: technical-director, before Main Menu ships (Alpha). Carried so it is not lost. |
| PROVISIONAL cross-system re-tune halves (tick-007 tick-budget ↔ villager `max_deciding_per_tick`, recorded once with shared rationale) | Medium | Low | Correctly deferred — needs integrated build to measure. Flagged so the coordination is not forgotten when it lands. |
| Production quality bar costs more than slice standards (Medium-confidence variable) | Medium | Medium | Spine sequenced FIRST (this sprint) so quality scaffolding exists before feature work; committed 8 not 9 to hold margin. |
| Single-specialist throughput — 7/8 stories on godot-gdscript-specialist serializes the parallel-agent velocity assumption | Medium | Low-Med | 2-day buffer absorbs it; cam-001 split to godot-specialist; Should-Have starters droppable without touching critical path. |
| Recurring typed-Array crash class (3 incidents in 5 slice days) | Medium | Low | Keep regression call in E2E gate; preview paths deliberately untyped; budgeted inside buffer. |
| Godot 4.7 API deviations beyond LLM cutoff (rendering not yet touched; input/resource MEDIUM) | Medium | Low-Med | Every API cross-referenced against `docs/engine-reference/godot/` before use — enforced per story Engine Notes. |

## Dependencies on External Factors

- **Control-manifest refresh (gate blocker #1):** all stories embed manifest version
  2026-07-23. Confirm current before spine-001 starts — a stale manifest risks rework.
  Owner: technical-director.
- No art/audio external dependency for Sprint 1 (pure Foundation logic; no assets consumed).

## Definition of Done for this Sprint

- [ ] All Must Have stories completed
- [ ] All tasks pass acceptance criteria
- [ ] Every Logic story (rid-001, spine-002, spine-003, cam-001, vox-001) has a passing GdUnit4 headless unit test in `neues-spiel/tests/unit/...` — BLOCKING
- [ ] Every Integration story (spine-001, rid-002, tick-001) has a passing headless integration test in `neues-spiel/tests/integration/...` — BLOCKING
- [ ] Tests deterministic, isolated, DI-mockable (no Autoload registration, no file I/O)
- [ ] QA plan exists (`production/qa/qa-plan-sprint-1.md`) — run `/qa-plan sprint` before implementation begins
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No open S1 or S2 bugs in delivered stories
- [ ] Design/ADR docs updated for any deviation discovered during implementation
- [ ] Code reviewed and merged (trunk-based)

## Notes

- **Scope check:** all 8 stories are drawn from existing epics with no additions beyond
  epic scope. Run `/scope-check sprint-1` before implementation if any story grows.
- **Next step:** run `/qa-plan sprint` to define test cases per story before `/dev-story`.
