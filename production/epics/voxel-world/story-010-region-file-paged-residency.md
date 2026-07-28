# Story 010: Region-file format + paged residency working set

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-24 — 455/455 suite green, parent-verified)
> **Layer**: Presentation (world-storage residency tier)
> **Type**: Integration
> **Estimate**: 1.5 days
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-053`, `TR-voxel-world-041`, `TR-voxel-world-021`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015 (Large-World Storage & Residency) — primary; ADR-0014 secondary
**ADR Decision Summary**: World storage = paged region-file residency. The resident working set = camera-near chunks (ADR-0014 view radius) ∪ active-settlement chunks (ADR-0007 nav region). Resident memory is a function of footprint, NOT world size. Everything else lives in on-disk region files (fixed-size chunk groups, `region_size_chunks`, `store_var` on the same `PackedByteArray`-class storage), paged in on approach, evicted staggered on leaving the margin. The public accessor API is UNCHANGED — the residency tier is transparent. **Production code written fresh; the spike (`prototypes/storage-residency-spike/`) is reference-only.**

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: Per-region header I/O (the `SLOTS_PER_REGION` offset table) is read/created synchronously ONCE per region — the ONE sanctioned synchronous exception (never per-tick). All other region I/O is async (Story 011). Region files are user data (`.gitignore`d), never designer-authored or git-tracked.

**Control Manifest Rules (this layer)**:
- Required: resident set = camera-near ∪ active-settlement chunks; on-disk region files; public accessor API unchanged (transparent residency); one-time-per-region header I/O only.
- Forbidden: a full-world packed-array allocation at boot; exposing residency to consumers.
- Guardrail: residency memory FLAT vs world size (spike peak 43.9–83.7 MB, ~1–2% of the 4 GB ceiling).

---

## Acceptance Criteria

- [ ] The resident working set is bounded by footprint (camera-near ∪ settlement chunks), not world size; boot allocates the initial residency set, NOT the full world. [TR-voxel-world-053]
- [ ] Non-resident chunks live in on-disk region files (fixed-size chunk groups) and page in on approach; the public accessor API (`get`/`set` by `Vector3i`, `cell_changed`, `raycast_cells`) is unchanged and transparent to consumers. [TR-voxel-world-041, -053]
- [ ] Per-region header (offset table) I/O happens synchronously exactly once per region, never per-tick. [TR-voxel-world-053]

---

## Implementation Notes

*Derived from ADR-0015 Decision §1/§2/§6:*

- Region file = fixed-size group of chunks (`region_size_chunks`, config knob), each chunk serialized via `store_var` on its `PackedByteArray`-class buffer. A per-region header holds a `SLOTS_PER_REGION` offset table, read/created synchronously once when the region is first touched.
- Maintain the resident set as camera-near chunks (ADR-0014 view radius) ∪ active-settlement chunks (ADR-0007 nav region). Boot loads only this initial set (ADR-0005 boot note), not a full-world allocation.
- Keep `get_cell`/`set_cell`/`raycast_cells` signatures and semantics identical — residency is internal. A cell in a non-resident chunk triggers a page-in (async, Story 011; load-before-write for writes, Story 014).
- Write fresh; treat the spike prototype as reference for measured behavior only.

---

## Out of Scope

- Story 011: async I/O on the WorkerThreadPool (this story defines the format + resident-set membership; the async dispatch mechanism is 011).
- Story 012: the time-based per-frame page/evict budget.
- Story 013: the in-flight-write cache.

---

## QA Test Cases

- **AC-1 (resident set membership)**: [TR-voxel-world-053]
  - Given: a configured world larger than one region, an injected camera focus point and a settlement region
  - When: the resident set is queried
  - Then: it contains exactly camera-near ∪ settlement chunks; distant chunks are non-resident (on disk)
  - Edge cases: overlapping camera/settlement footprints counted once
- **AC-2 (transparent page-in + round-trip)**: [TR-voxel-world-041]
  - Given: a chunk written, evicted to a region file, then re-approached
  - When: `get_cell` reads a cell in that chunk
  - Then: the value matches what was written (region-file round-trip is lossless); the accessor signature is unchanged
- **AC-3 (header I/O once)**: [TR-voxel-world-053]
  - Given: a region touched repeatedly over many ticks
  - When: header (offset table) reads are counted
  - Then: synchronous header I/O occurs exactly once for that region, never per-tick

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/voxel_world/region_file_residency_test.gd` OR documented playtest — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (chunked storage); consumes an injected camera focus point (see Camera & Input epic — a focus point can be injected/stubbed for isolated tests)
- Unlocks: Story 011, Story 012, Story 013, Story 014
