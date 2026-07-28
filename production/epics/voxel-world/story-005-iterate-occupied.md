# Story 005: iterate_occupied API — occupied-cells iteration, torn-read-free

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-24 — 343/343 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 0.5–1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-021`, `TR-voxel-world-048`, `TR-voxel-world-033`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014 (chunked storage) — primary; ADR-0012 (Save/Load) secondary
**ADR Decision Summary**: Voxel World exposes an iteration API over occupied (non-empty) cells so Save/Load needs no internal-storage knowledge. Mutations are serialized, so iteration observes only fully-committed states. (The full Save/Load orchestrator is VS-tier — out of scope for M01; only this iteration API is built here.)

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: No concurrent writes exist (serialized Mutating state) — torn-read safety comes from that serialization, not from locks.

**Control Manifest Rules (this layer)**:
- Required: iteration returns only non-empty cells; iteration observes only fully-committed cell states.
- Forbidden: exposing internal chunk storage layout to callers.
- Guardrail: mutations are serialized one at a time.

---

## Acceptance Criteria

- [ ] The Save/Load iteration API returns only non-empty (occupied) cells (AC15). [TR-voxel-world-021]
- [ ] Iteration observes only fully-committed states, never a partial/in-progress write (AC14). [TR-voxel-world-048]

---

## Implementation Notes

*Derived from ADR-0014 / ADR-0012:*

- Implement `iterate_occupied()` yielding occupied cells (chunk-by-chunk internally, but callers see only `(cell, occupant)`), skipping empty cells.
- Torn-read prevention is inherited from the serialized write path (Story 002): an iteration step never overlaps an in-progress write. Do not add locks; assert the serialization invariant in a test.
- Note: the region-file save format (ADR-0012 finalized as ADR-0015 region files) is out of scope; this story delivers only the iteration primitive that a future save orchestrator (VS-tier) will consume.

---

## Out of Scope

- The Save/Load orchestrator itself (VS-tier, Milestone 02+).
- Region-file serialization (Story 010 delivers the region format for residency, not the save flow).

---

## QA Test Cases

- **AC-1 (occupied-only)**: [TR-voxel-world-021]
  - Given: a grid with 100 occupied cells among a large empty extent
  - When: `iterate_occupied()` is consumed to completion
  - Then: exactly the 100 occupied cells are yielded; no empty cell appears
- **AC-2 (committed-state only)**: [TR-voxel-world-048]
  - Given: an iteration in progress
  - When: a write is applied between iteration steps
  - Then: each yielded cell reflects a fully-committed state (no half-written record); the serialized-mutation invariant holds
  - Edge cases: empty grid yields nothing

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/voxel_world/iterate_occupied_test.gd` OR documented playtest — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (storage)
- Unlocks: Save/Load orchestrator (VS-tier, future); Story 014 (save-flush write path references iteration)
