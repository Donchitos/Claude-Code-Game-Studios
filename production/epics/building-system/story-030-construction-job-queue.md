# Story 030: Construction job queue — claim/report pipeline + on-site + occupied-cell defer + unreachable feedback

> **Epic**: Building System
> **Status: Complete (2026-07-24 — 731/731 suite green, parent-verified; AC21/AC36b PROVISIONAL until crown villager-ai-012)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-053`, `TR-building-system-054`, `TR-building-system-055`, `TR-building-system-056`, `TR-building-system-037`, `TR-building-system-087`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary; ADR-0007 (AI Pathfinding/job execution) — secondary; ADR-0009 (occupancy) — secondary
**ADR Decision Summary**: Released project cells become jobs villagers claim and execute (ADR-0007 job flow). The queue semantics are owned by Building System; claim locking, travel/arrival, and abandonment are Villager AI's. Occupancy reads discrete `current_cell`.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (Integration seam with Villager AI)
**Engine Notes**: "On site" = the villager occupies the target cell or an orthogonally adjacent cell (incl. below/above). Occupancy reads the discrete `current_cell`/body-column (ADR-0009), never `_visual_position`.

**Control Manifest Rules (this layer — Core):**
- Required: every blueprint cell of a BUILDING-state project is one job; one job per villager at a time; per-cell claims allow parallelism; "on site" = target cell or orthogonal neighbour; the queue is ordered by commit time (availability/tie-breaking).
- Forbidden: the queue semantics are owned HERE and not renegotiable without revising the GDD; never force servicing order (job selection is Villager AI's criteria).
- Guardrail: unreachable jobs stay queued and are retried; never auto-canceled.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC21 [PROVISIONAL — Villager AI]: GIVEN a real villager and a queued job, WHEN it claims, paths to site, and works, THEN the full claim→build→report cycle completes (integration test once that GDD lands). [TR-053]
- [ ] AC35: GIVEN a blueprint cell no villager can reach, WHEN any amount of game time passes, THEN the job remains queued and the ghost is never auto-canceled (Edge Case 5). [TR-087]
- [ ] AC36: GIVEN a mocked "cell occupied" state for a construction-in-progress job, WHEN construction would start, THEN that cell's progress is skipped and the job stays queued while all other queued cells process normally (Edge Case 6 — Building-owned half). [TR-037]
- [ ] AC36b [PROVISIONAL — Villager AI]: GIVEN a real character occupying a construction target cell, WHEN construction would start, THEN the nudge-aside/deferral behaves per Villager AI. [TR-037]
- [ ] AC48: GIVEN a job is reported unreachable, WHEN the report registers, THEN the affected ghost switches to the pulsing orange unreachable tint and a non-modal UI hint appears; WHEN the obstruction is removed and the job is claimed again, THEN the ghost returns to the normal Planned visual. [TR-087]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Core Rule 12 + Edge Cases 5/6, TR-053/054/055/056/037/087:*

- Every blueprint cell of a BUILDING-state project is one job (Story 004 gates eligibility). The queue is ordered by commit time (display/tie-breaking, not forced servicing order — Villager AI chooses among available jobs).
- `claim_job` records the claiming villager (feeds Story 005 attribution). One job per villager at a time. Per-cell claims allow parallelism (N villagers on N distinct cells, incl. same command).
- "On site" = the villager occupies the target cell or an orthogonally adjacent cell (incl. directly below/above); progress advances per tick only while a claiming villager is on site.
- Occupied-cell defer (Edge 6, Building-owned half): if the construction target is occupied by a character, defer that cell; other queued cells process normally. Occupancy reads discrete `current_cell` (ADR-0009). The nudge-aside itself (AC36b) is Villager AI's — PROVISIONAL.
- Unreachable feedback (Edge 5): a job reported unreachable (by Villager AI pathing failure) keeps its ghost (never auto-canceled), switches it to a pulsing orange tint, and shows a non-modal UI hint; on re-claim the ghost returns to normal Planned. `unreachable_retry_ticks` is owned by Villager AI's tuning.
- The claim/travel/arrival/abandon mechanics are Villager AI's (contract confirmed) — mark AC21/36b PROVISIONAL; unit-test the Building-owned halves (queue ordering, on-site predicate, occupied-defer, unreachable-ghost signal) with mocks now.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 029: the tick loop that advances a claimed on-site cell (this story feeds it claims).
- Story 005: worker attribution recording (this story exposes `claim_job`; 005 records the id).
- Villager AI's claim locking, pathing, nudge-aside, abandonment — Villager AI epic.

---

## QA Test Cases

**AC35 — unreachable stays queued**
- Given: a blueprint cell no villager can reach.
- When: game time passes.
- Then: the job stays queued; the ghost is never auto-canceled.

**AC36 — occupied-cell defer (mocked)**
- Given: a mocked "target cell occupied" state.
- When: construction would start.
- Then: that cell is skipped/deferred; other queued cells process normally.

**AC48 — unreachable feedback**
- Given: a job reported unreachable (mocked pathing-failure report).
- When: the report registers.
- Then: the ghost pulses orange + a non-modal hint appears; on re-claim it returns to normal Planned.

**On-site predicate**
- Given: candidate standing cells.
- When: on-site eligibility is evaluated for a build job.
- Then: the target cell and orthogonal neighbours (incl. below/above) count as on-site; non-adjacent cells do not.

**AC21 / AC36b — full cycle (PROVISIONAL)**
- Given: a real villager (once Villager AI lands).
- When: claim → path → work → report.
- Then: the full cycle completes; nudge-aside behaves per Villager AI. Integration test, not blocking M01 for this epic's half.

---

## Test Evidence

**Story Type**: Integration (Building-owned halves unit-testable with mocks now; full cycle PROVISIONAL pending Villager AI)
**Required evidence**: `tests/integration/building_system/construction_job_queue_test.gd`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 029 (tick loop), Story 004 (release/eligibility). Coordinates with Villager AI (claim/path/abandon).
- Unlocks: Story 005 (attribution), Story 009 (demolition reuses the on-site/claim contract), the playable build loop.
