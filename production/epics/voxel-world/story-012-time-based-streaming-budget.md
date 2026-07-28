# Story 012: Time-based per-frame page-in / eviction budget

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-24 — 497/497 suite green, parent-verified)
> **Layer**: Presentation (world-storage residency tier)
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-053`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015 — primary
**ADR Decision Summary**: Streaming budget is TIME-BASED, not a fixed chunk count. Page-in and eviction are each bounded per frame by a time budget (`page_budget_ms`/`evict_budget_ms`, validated at 4.0 ms each — leaving ~12 ms of the 16.6 ms frame for game work). The budget is re-checked after EVERY single integrated item, so a burst of ready items in one frame cannot collectively exceed it — the excess defers to a later frame.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: A fixed chunks-per-frame count (ADR-0014's `stream_chunk_budget = 2`, tuned for ~25 c/s) under-provisions ~12× at the game's real max camera speed (144 c/s ⇒ ~24 new chunks/frame), producing a chronic backlog that climbs memory ~5.7× and blows the frame budget.

**Control Manifest Rules (this layer)**:
- Required: time-based `page_budget_ms`/`evict_budget_ms`, re-checked after EVERY single integrated item; excess defers to a later frame.
- Forbidden: never a fixed chunks-per-frame streaming count at 16k scale.
- Guardrail: 4.0 ms each budget; worst frame 13.3–14.5 ms (budget 16.6) across a repeated full-16k-span traverse.

---

## Acceptance Criteria

- [ ] Page-in and eviction are each bounded per frame by a time budget (`page_budget_ms`/`evict_budget_ms`), not a fixed chunk count. [TR-voxel-world-053]
- [ ] The budget is re-checked after every single integrated item; a burst of ready items in one frame cannot collectively exceed the budget — the excess defers to a later frame. [TR-voxel-world-053]

---

## Implementation Notes

*Derived from ADR-0015 Decision §1:*

- Integrate ready page-in results and process evictions in a per-frame loop that checks elapsed time against `page_budget_ms` / `evict_budget_ms` (config knobs, default 4.0 ms each) BEFORE each item and AFTER integrating each item — so one over-long item cannot blow the budget and a burst cannot accumulate past it. Remaining items stay queued for the next frame.
- Budgets are separate for page-in vs eviction. Reuse ADR-0014's staggered-unload discipline for eviction bursts (the slice's single 133 ms hitch came from an unload burst).

---

## Out of Scope

- Story 011: the async dispatch itself (this story governs how many ready results get integrated per frame).
- Story 016: measuring/recording the budget values as config with rationale.

---

## QA Test Cases

- **AC-1 (time-based, not count-based)**: [TR-voxel-world-053]
  - Given: many ready page-in results queued (simulated mass approach)
  - When: one frame's integration loop runs with `page_budget_ms = 4.0`
  - Then: integration stops when the 4.0 ms budget is reached, not at a fixed item count; the rest stay queued
  - Edge cases: a single item that alone exceeds the budget is integrated (progress guaranteed) but the loop then stops
- **AC-2 (per-item re-check bounds bursts)**: [TR-voxel-world-053]
  - Given: a burst of N ready items in one frame
  - When: the loop integrates them
  - Then: total integration time per frame is bounded near `page_budget_ms`; excess deferred to later frames; measured worst frame stays under the 16.6 ms budget across a full-span traverse

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/voxel_world/time_based_streaming_budget_test.gd` OR documented playtest — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 010 (resident set), Story 011 (async results to integrate)
- Unlocks: Story 016 (budget value tuning)
