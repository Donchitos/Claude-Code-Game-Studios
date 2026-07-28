# Story 021: Commit pipeline — click-vs-drag discrimination + bounds clamp (pick→preview→commit)

> **Epic**: Building System
> **Status: Complete (2026-07-24 — 615/615 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-24

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-002` (commit half), `TR-building-system-081`, `TR-building-system-083`, `TR-building-system-086`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary; ADR-0010 (input arbitration) — secondary
**ADR Decision Summary**: Every placement tool follows one pipeline pick → preview → commit; nothing is ever created without its preview having been visible. A valid commit creates blueprint cells (not grid blocks) grouped into a project.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Drag-release handled via ADR-0010 §3's `_input()` window (Story 019). No post-cutoff APIs. `cursor_travel_px` is screen-space pixels, not world cells.

**Control Manifest Rules (this layer — Core):**
- Required: one pipeline pick → preview → commit; a valid commit creates blueprint (Draft) cells owned by this system, invisible to Voxel World's data layer; the preview clamps to bounds and the commit creates exactly what the preview showed.
- Forbidden: never write blocks into the grid on commit (blueprint cells only); never create anything without a visible preview.
- Guardrail: click-vs-drag is a single screen-space threshold check (F4); commit size bounded by `max_cells_per_command` (Story 022 enforces the cap).

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC4: GIVEN an armed tool with a valid pick, WHEN `build_place` commits, THEN blueprint cells are created exactly matching the visible preview. [TR-002]
- [ ] AC6: GIVEN a wall click below the drag threshold, WHEN committed, THEN the click path is taken (single-column commit) (F4). [TR-081]
- [ ] AC9: GIVEN a drag extending past world bounds, WHEN committed, THEN only the in-bounds portion shown by the preview is created (Edge Case 1). [TR-083]
- [ ] AC38: GIVEN no valid pick (ray misses the world), WHEN `build_place` fires, THEN nothing happens and the ghost is hidden (Edge Case 4). [TR-086]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Core Rule 2 + F4 + Edge Cases 1/4, TR-002/081/083/086:*

- Click-vs-drag discrimination (F4): `is_drag = cursor_travel_px >= drag_threshold_px` while `build_place` is held; release below threshold is a click (single commit), at/above is a drag.
- Commit pipeline: on `build_place`, validate (Story 022), then create **blueprint (Draft) cells** — NOT grid blocks — matching exactly the visible preview. Blueprint cells are owned by this system and invisible to Voxel World's data layer.
- Bounds clamp (Edge 1): a drag extending past world bounds previews and commits only the in-bounds portion; a drag entirely out of bounds commits nothing.
- No valid pick (Edge 4): ghost hidden, `build_place` is a no-op — no error spam.
- The new blueprint cells are handed to grouping (Story 003) to assign project membership. Per-tool cell-set geometry (which cells) comes from Stories 024–028; this story owns the discrimination + clamp + blueprint-creation trigger.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 022: the full validity rejection rules and cap.
- Story 023: rendering the preview ghosts.
- Stories 024–028: the per-tool cell-set formulas.
- Story 003: assigning the created blueprint cells to a project.

---

## QA Test Cases

**AC4 — commit matches preview**
- Given: an armed tool, valid pick, a visible preview of N cells.
- When: `build_place` commits.
- Then: exactly N blueprint (Draft) cells are created; zero grid blocks written.

**AC6 — click path below threshold**
- Given: `cursor_travel_px < drag_threshold_px` on release.
- When: committed.
- Then: the click (single) path is taken, not the drag path.
- Edge cases: exactly-at-threshold takes the drag path (`>=`).

**AC9 — bounds clamp**
- Given: a drag extending past world bounds.
- When: committed.
- Then: only the in-bounds portion (as previewed) is created; a fully-out-of-bounds drag commits nothing.

**AC38 — no valid pick is a no-op**
- Given: the ray misses the world.
- When: `build_place` fires.
- Then: nothing is created; ghost hidden.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/commit_pipeline_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 020 (pick), Story 019 (tool SM).
- Unlocks: Stories 022 (validity), 024–028 (tools), 003 (grouping consumes created cells).
