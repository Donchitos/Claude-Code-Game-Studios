# Story 008: Incremental AStar3D patching on cell writes (incl. dig-order writes)

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-24 — 587/587 suite green, parent-verified)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-012`, `TR-villager-ai-behavior-036`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (AI Pathfinding) — primary; ADR-0009 (synchronous-signal race closure)
**ADR Decision Summary**: The AStar3D graph is incrementally patched — never rebuilt — on `cell_changed`, adding/removing points and connections only for the cells actually touched. This matches the GDD's re-path-filtering contract: a write triggers re-evaluation for a moving villager only if the changed cell(s) intersect the remaining movement's cells or their clearance envelope.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: `AStar3D` IDs are never auto-recycled on `remove_point()` — the deterministic bit-pack keeps patches collision-free and idempotent. Voxel World's `cell_changed` fires synchronously (Godot default) — the re-path filter redirects in the same call stack. Dig-order writes (Planned dig / demolition) also change standability and must patch the graph.

**Control Manifest Rules (this layer)**:
- Required (Feature): incrementally patched on `cell_changed`, never rebuilt — add/remove points & connections only for the touched cells + their clearance/step neighborhood. Re-path filter: a write triggers re-evaluation for a moving villager ONLY if the changed cells intersect the remaining movement cells or their clearance envelope (each movement cell + the two cells above + flanking orthogonals for diagonals). Writes elsewhere are ignored by design.
- Required (Core): load-before-write for far-world mutations lives in Voxel World's write path — Villager AI consumes the resulting `cell_changed`, never applies writes itself.
- Forbidden: full graph rebuild per edit; the villager mutating the grid.
- Guardrail: spike-measured patch avg 0.46 ms.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] On a `cell_changed` that alters standability/step-legality, the graph adds/removes only the affected cell's points/connections + its clearance/step neighborhood — never a full rebuild.
- [ ] Dig-order and demolition writes (which change standability) patch the graph identically to build writes.
- [ ] A Voxel World write that blocks a moving villager's remaining path triggers a re-path evaluation (AC18 — the re-path itself is Story 009).
- [ ] A Voxel World write NOT intersecting a moving villager's remaining movement cells or their clearance envelope triggers ZERO re-path evaluations for that villager — assert call-count == 0 (AC49, the filter's entire perf purpose).
- [ ] After a patch, IDs remain the deterministic bit-pack — re-adding a previously-removed cell reuses the same ID (idempotent).

---

## Implementation Notes

*Derived from ADR-0007/0009 Implementation Guidelines:*

- `_on_voxel_world_cell_changed(cell, before, after)`: recompute standability for `cell` and its clearance/step neighborhood; `add_point`/`remove_point` and `connect_points`/`disconnect_points` only for those.
- The clearance envelope is defined exactly: each movement cell + the two cells directly above + (for diagonals) both flanking orthogonals. This filter is independent of any throttling the scheduler adds.
- Rely on synchronous `cell_changed` emission for the race closure (Story 009 handles the redirect).
- The re-path filter must apply to ALL moving villagers — Traveling, a Wandering step, a Breather step-away, or an F4 vacate step.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: the actual re-path/redirect of a Traveling villager.
- Voxel World's write path / load-before-write (owned by Voxel World epic).

---

## QA Test Cases

- **AC (incremental patch)**: Given a `cell_changed` that turns a standable cell solid, When patched, Then only that cell's neighborhood points/connections change; other points untouched (assert no full rebuild).
- **AC (dig write)**: Given a dig/demolition write that turns a solid cell to air, When patched, Then new standable cells gain points/connections.
- **AC49 (negative filter)**: Given a write outside a moving villager's remaining-movement clearance envelope, When the signal fires, Then re-path evaluation call-count == 0 for that villager.
- **AC18 (positive filter)**: Given a write intersecting the remaining path, Then a re-path evaluation is triggered.
- Edge cases: re-adding a removed cell reuses its deterministic ID (idempotency).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/villager_ai/graph_patching_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 007 (AStar3D graph), 004 (moving-villager movement cells / clearance envelope)
- Unlocks: 009
