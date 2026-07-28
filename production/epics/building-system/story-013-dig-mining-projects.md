# Story 013: Dig / mining-zone projects (dig-kind lifecycle)

> **Epic**: Building System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-121` (secondary: `TR-voxel-world-051`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary
**ADR Decision Summary**: Dig projects reuse the project entity lifecycle (Draft → BUILDING → PAUSED/DONE) with terminal per-cell state Removed; grouping/merge applies within kind only; released dig cells respect `max_cells_per_command` — mining is bounded, never a free-form terraform.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (ADR-0016 knowledge risk LOW)
**Engine Notes**: Removal goes through the SAME batched write API as every other removal (no special dig-order API surface); emits the standard `cell_changed` so downstream re-evaluates room/shelter analysis (TR-voxel-world-051). Only terrain-band/sand values (1..5 family, EXCLUDING water and trunk/leaves) may be dug.

**Control Manifest Rules (this layer — Core)**:
- Required: dig projects follow the same DRAFT → BUILDING → PAUSED/DONE lifecycle with terminal per-cell state Removed; removal routes through the single batched write path; released dig cells respect `max_cells_per_command`.
- Forbidden: a dig-kind project must NEVER merge with a build-kind project even if 26-adjacent (kind is a hard partition); terrain is never removed instantly or unbounded.
- Guardrail: mining is bounded by `max_cells_per_command` per released command; grouping bounded by the batch neighborhood.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC71: GIVEN the removal tool targets a terrain cell, WHEN committed, THEN Draft dig cells are created in a new or existing `dig`-kind project, and this project never merges with an adjacent `build`-kind project even if 26-adjacent (Rule 14m, Edge Case 14). [TR-121]
- [ ] Dig projects follow the DRAFT → BUILDING (released) → PAUSED/DONE lifecycle; terminal per-cell state is Removed (not Built). [TR-121]
- [ ] Released dig cells are subject to the same `max_cells_per_command` cap as any other command. [TR-121]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Rule 14m, TR-121; TR-voxel-world-051:*

- The removal tool, when it targets terrain instead of a player cell, marks **Draft dig cells** inside a new or existing project of **kind `dig`**. Rule 14c's 26-adjacency/merge (Story 003) applies identically, BUT a dig-kind project only ever merges with other dig-kind projects — it never merges with a build-kind project even if spatially adjacent (Edge 14). Add `kind` to the grouping's same-kind predicate.
- Dig projects follow the exact same DRAFT → BUILDING → PAUSED/DONE lifecycle (Stories 002/004/006); the terminal per-cell state is **Removed**, not Built.
- Released dig cells respect `max_cells_per_command` (Core Rule 9) — mining is bounded, never a free-form terraform.
- Removal on completion routes through Voxel World's single batched write path (no special dig-order API surface); the standard `cell_changed` signal lets downstream consumers re-evaluate room/shelter analysis (TR-voxel-world-051). Only terrain-band/sand values (1..5 family, EXCLUDING water and trunk/leaves) are diggable — enforce the diggable-value guard.
- The dig-job on-site exclusion (villager must not stand on the dug cell) is Story 014.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 014: the dig-job on-site exclusion amendment.
- Story 009: block demolition orders (a distinct player-cell teardown path; dig targets terrain).
- Story 015: the removal-tool micro-state branch for player cells (this story handles the terrain-target branch).
- Voxel World's diggable-value data contract details (TR-voxel-world-051) — Voxel World epic.

---

## QA Test Cases

**AC71 — dig project + kind partition**
- Given: the removal tool targets a terrain cell.
- When: committed.
- Then: Draft dig cells are created in a `dig`-kind project.
- Edge cases (Edge 14): a dig-kind draft 26-adjacent to a build-kind project does NOT merge — a separate project is created even though cells touch; two adjacent dig commits DO merge (same kind).

**Dig lifecycle + Removed terminal**
- Given: a dig project.
- When: released and its cells complete.
- Then: it follows DRAFT → BUILDING → PAUSED/DONE; each completed cell's terminal state is Removed (not Built); removal routes through the batched write path and emits `cell_changed`.

**Bounded mining**
- Given: a dig command exceeding `max_cells_per_command`.
- When: committed.
- Then: rejected with feedback (same cap as any command).
- Edge cases: a dig targeting water or trunk/leaves values is rejected (diggable-value guard).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/dig_mining_projects_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (project entity + lifecycle), Story 003 (grouping — extended with kind partition), Story 009 (demolition/removal job execution pattern). Coordinates with Voxel World TR-voxel-world-051.
- Unlocks: Story 014 (dig on-site exclusion).
