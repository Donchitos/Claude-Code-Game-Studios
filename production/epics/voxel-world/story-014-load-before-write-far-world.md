# Story 014: Load-before-write for far-world (non-resident) mutations

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-24 — 662/662 suite green, parent-verified — closes the last ADR-0015 invariant with vox-013)
> **Layer**: Presentation (world-storage residency tier)
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-051`, `TR-voxel-world-053`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015 — primary
**ADR Decision Summary**: Any write to a cell in a non-resident chunk (dig order, building write, save flush) MUST first page in that chunk's region, apply the write to the resident copy, mark it dirty, and let staggered eviction flush it. This rule lives in ONE place — Voxel World's single batched write path — not in every caller. A write is never applied to disk blind or dropped.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: Far-world writes are low-frequency and player-directed at MVP/slice scope; they run asynchronously (page-in on the WorkerThreadPool), never blocking the frame.

**Control Manifest Rules (this layer)**:
- Required: load-before-write for any non-resident write — page-in → resident-copy write → mark dirty → staggered flush; centralized in the single batched write path.
- Forbidden: never apply a far-world write to disk blind, and never drop it.
- Guardrail: one page-in per far-world write; asynchronous, never frame-blocking.

---

## Acceptance Criteria

- [ ] A write to a cell in a non-resident chunk first pages in that chunk's region, applies the write to the resident copy, marks it dirty, and lets staggered eviction flush it — the write is never applied to disk blind or dropped. [TR-voxel-world-053]
- [ ] The rule lives in ONE place (the single batched write path), not in each caller (dig order / building write / save flush all inherit it). [TR-voxel-world-051, -053]

---

## Implementation Notes

*Derived from ADR-0015 Decision §3:*

- In the single batched write path (Story 003), before applying any per-cell write, check chunk residency. If non-resident, enqueue an async page-in (Story 011), and once the resident copy exists, apply the write, mark the chunk dirty, and let staggered eviction (Story 012) flush it. The in-flight-write cache (Story 013) covers a re-read arriving before the flush completes.
- Do NOT duplicate this logic in callers (dig-order path Story 009, building writes, save flush) — they call the same batched write path and inherit load-before-write for free.
- The write is queued/deferred until page-in completes; it is never applied to the region file directly and never silently dropped.

---

## Out of Scope

- Story 012: the eviction/flush budget mechanics.
- Story 013: the in-flight-write cache read path.

---

## QA Test Cases

- **AC-1 (page-in before far write)**: [TR-voxel-world-053]
  - Given: a cell in a non-resident chunk on disk
  - When: a write targets that cell
  - Then: the chunk's region is paged in, the resident copy is written, the chunk is marked dirty, and eventual eviction flushes it — the region file is never written blind
  - Edge cases: two far writes to the same non-resident chunk coalesce onto one page-in
- **AC-2 (no blind write, no drop)**: [TR-voxel-world-053]
  - Given: a far-world write while the page-in is still in flight
  - When: the write path processes it
  - Then: the write is deferred until the resident copy exists, then applied — never dropped, never written straight to disk
- **AC-3 (single-location rule)**: [TR-voxel-world-051]
  - Given: the dig-order path (Story 009) targeting a non-resident cell
  - When: it applies through the batched write path
  - Then: it inherits load-before-write with no dig-order-specific residency code

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/voxel_world/load_before_write_test.gd` OR documented playtest — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (batched write path), Story 010 (residency), Story 011 (async page-in), Story 013 (in-flight cache)
- Unlocks: far-world dig orders (Story 009) and building writes at 16k scale
