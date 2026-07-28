# Story 017: ADR-0015 C4 — completion-driven residency drain loop

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-26 — 951/951 suite green, parent-verified; #5 measured-values upgrade complete)
> **Layer**: Presentation (world-storage residency tier)
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-26

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-053`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015 (carried tuning item C4) — primary
**ADR Decision Summary**: The residency drain loop should be completion-driven — re-examine only items whose background task just completed, not poll `is_task_completed` across the whole queue each tick (ADR-0015 §6 production note). This is the event-driven, not-polled cross-cutting principle applied to the residency tier.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Polling `is_task_completed` across the entire in-flight queue each tick is the anti-pattern this story removes — it scales with queue size, not with actual completions.

**Control Manifest Rules (this layer)**:
- Required: completion-driven drain — re-examine only just-completed items; event-driven, not polled.
- Forbidden: per-tick polling of `is_task_completed` across the whole queue.
- Guardrail: drain cost scales with completions, not queue size.

---

## Acceptance Criteria

- [x] The residency drain loop re-examines only items whose background task just completed, never polling `is_task_completed` across the whole queue each tick. [TR-voxel-world-053]
- [x] Drain work per tick scales with the number of completions, not with total in-flight queue size. [TR-voxel-world-053]

---

## Implementation Notes

*Derived from ADR-0015 §6 production note + manifest Cross-Cutting Constraints:*

- Replace any whole-queue polling with a completion-driven mechanism: a completed background task (Story 011) signals/records its completion into the mutex-guarded structure, and only those just-completed items are drained into the resident set (respecting the time budget, Story 012). Items still in-flight are not re-examined.
- This is the "event-driven, not polled" principle (boot gate, hover flag, timer expiry) applied to residency. Verify by asserting the drain touches only completed entries.

---

## Out of Scope

- Story 011: task dispatch and the mutex-guarded result structure.
- Story 012: the time-budget on how many completed items get integrated per frame.

---

## QA Test Cases

- **AC-1 (completion-driven, not polled)**: [TR-voxel-world-053]
  - Given: a large in-flight queue with only a few tasks completing this tick
  - When: the drain loop runs
  - Then: it examines only the just-completed items; instrumentation shows no whole-queue `is_task_completed` scan
  - Edge cases: zero completions this tick → drain does no per-item work
- **AC-2 (cost scales with completions)**: [TR-voxel-world-053]
  - Given: queues of increasing size with a fixed small number of completions
  - When: drain cost is measured
  - Then: cost stays roughly constant (tracks completions), not growing with queue size

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/voxel_world/completion_driven_drain_test.gd` OR documented playtest — must exist and pass
**Status**: [x] Created — 7 test functions, all passing (see `production/qa/evidence/voxel-world-completion-driven-drain-evidence-20260726-vox017.md` for the quantitative AC-2 measurement)

---

## Dependencies

- Depends on: Story 011 (async pool + mutex-guarded completion)
- Unlocks: Milestone-01 Must-Ship "ADR-0015 C1/C4 residency tuning" (with Story 016)
