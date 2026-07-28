# Story 016: ADR-0015 C1 — async concurrency cap + bounded per-chunk gen cost (measured)

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-26 — 944/944 suite green, parent-verified; #5 upgraded to measured values)
> **Layer**: Presentation (world-storage residency tier)
> **Type**: Config/Data
> **Estimate**: 0.5–1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-26

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-053`, `TR-voxel-world-023`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015 (carried tuning item C1) — primary
**ADR Decision Summary**: The async concurrency cap value (`MAX_CONCURRENT_ASYNC_TASKS`) is non-critical (worst frame moved ~0.3 ms between cap 32 and 64) BECAUSE cap-miss = "stay queued", not "run sync". The per-chunk generation cost must be bounded. Both are recorded as config changes with measured rationale, not open decisions.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Residency memory is FLAT vs world size (spike peak 43.9–83.7 MB); `io_worst`/`regen_worst` = 0.00 ms by construction. This tuning confirms values against production load; it does not reopen the async architecture.

**Control Manifest Rules (this layer)**:
- Required: tunables from typed `.tres` config; values recorded as config changes with rationale (Foundation Spine `.tres` + rationale pattern).
- Forbidden: hardcoded literals for the cap or gen-cost bound; treating these as open architecture decisions.
- Guardrail: cap value non-critical by construction; worst frame stays under the 16.6 ms budget.

---

## Acceptance Criteria

- [ ] `MAX_CONCURRENT_ASYNC_TASKS` is set from config to a measured value, recorded as a config change with rationale (not a hardcoded literal, not an open decision). [TR-voxel-world-053, -023]
- [ ] The per-chunk terrain-generation cost is bounded, with the bound recorded as a config change with measured rationale. [TR-voxel-world-053]
- [ ] Measured worst-frame time under a full-span traverse stays within the 16.6 ms frame budget with the chosen values. [TR-voxel-world-053]

---

## Implementation Notes

*Derived from ADR-0015 (carried tuning item C1):*

- Expose `MAX_CONCURRENT_ASYNC_TASKS` and the per-chunk gen-cost bound as `VoxelWorldConfig` `@export` fields. Measure worst-frame behavior across a repeated full-span traverse (reference the spike's method, `prototypes/storage-residency-spike/`, but measure fresh against production code) and record the chosen values with a rationale comment/change note using the Foundation Spine `.tres` + rationale pattern.
- Because cap-miss = "stay queued" (Story 011), the cap value is non-critical — document that property in the rationale so the value is not later mistaken for a hard correctness threshold.

---

## Out of Scope

- Story 011: the async dispatch mechanism itself (this story only tunes its cap).
- Story 017: the C4 completion-driven drain.

---

## QA Test Cases

*Config/Data — smoke check.*

- **AC-1 (measured config values, no literals)**: [TR-voxel-world-053]
  - Given: the residency config and Voxel World source
  - When: reviewing the async cap and gen-cost bound
  - Then: both come from `.tres` config with a recorded rationale; grep confirms no hardcoded literals in code
  - Pass condition: smoke check passes; rationale note present
- **AC-2 (worst-frame within budget)**: [TR-voxel-world-053]
  - Given: the chosen values
  - When: a full-span traverse smoke run
  - Then: worst frame < 16.6 ms; recorded in the smoke check with the measured number

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: smoke check pass (`production/qa/smoke-*.md`) with the measured values + rationale
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 011 (async pool), Story 012 (time budget), Story 015 (mesh streaming under load)
- Unlocks: Milestone-01 Must-Ship "ADR-0015 C1/C4 residency tuning" (with Story 017)
