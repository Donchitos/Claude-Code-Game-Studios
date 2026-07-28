# Story 013: Read-through in-flight-write cache

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-24 — 655/655 suite green, parent-verified)
> **Layer**: Presentation (world-storage residency tier)
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-24

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-053`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015 — primary
**ADR Decision Summary**: When a dirty chunk is evicted its flush runs asynchronously; if that chunk is re-needed before its flush completes, the read MUST be served from the in-memory not-yet-durable bytes (`_write_in_flight_data`), NEVER re-read from the region file (which may be mid-write/incomplete).

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: A region file being flushed may be mid-write and incomplete — reading it before the flush completes returns torn/partial data. The in-flight-write cache is the correctness mechanism.

**Control Manifest Rules (this layer)**:
- Required: read-through in-flight-write cache; re-needed evicting-dirty chunk served from `_write_in_flight_data`.
- Forbidden: never re-read an evicting dirty chunk from its region file before its flush completes.
- Guardrail: correctness mechanism, not a perf optimization — the file may be incomplete.

---

## Acceptance Criteria

- [x] When a dirty chunk is evicted, its flush runs asynchronously; if the chunk is re-needed before the flush completes, the read is served from the in-memory in-flight bytes, never re-read from the region file. [TR-voxel-world-053]

---

## Implementation Notes

*Derived from ADR-0015 Decision §3:*

- On eviction of a dirty chunk, move its bytes into `_write_in_flight_data` (keyed by chunk coord) and dispatch the async flush (Story 011). While an entry is in-flight, any page-in / `get_cell` for that chunk resolves against `_write_in_flight_data` first — a hit serves those bytes and cancels/skips the redundant region read.
- Only after the flush task confirms completion (via the mutex-guarded result, Story 011) is the in-flight entry cleared. Reads then resume from the region file normally.

---

## Out of Scope

- Story 011: the async flush dispatch itself.
- Story 014: the far-world load-before-write path (a write, not a read; but both interact with the same dirty/in-flight lifecycle).

---

## QA Test Cases

- **AC-1 (serve from in-flight cache)**: [TR-voxel-world-053]
  - Given: a dirty chunk evicted with its flush deliberately delayed (in-flight)
  - When: the same chunk is re-needed and `get_cell` reads it
  - Then: the value served matches the last written (in-flight) bytes; no region-file read occurs while the flush is in-flight
  - Edge cases: read arriving exactly as the flush completes resolves to the same value from either source (consistency)
- **AC-2 (region read resumes after flush)**: [TR-voxel-world-053]
  - Given: an in-flight entry whose flush has now completed
  - When: the chunk is paged in again later
  - Then: the in-flight entry is cleared and the read comes from the region file, matching the flushed bytes

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/voxel_world/read_through_inflight_cache_test.gd` OR documented playtest — must exist and pass
**Status**: [x] Created — 4 test functions, full suite green (655/655, 0 failures)

---

## Dependencies

- Depends on: Story 011 (async flush + mutex-guarded completion)
- Unlocks: Story 014 (shares the dirty/in-flight lifecycle)
