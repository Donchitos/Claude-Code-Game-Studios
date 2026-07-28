# Story 027: Block tool — single-cell place / replace

> **Epic**: Building System
> **Status: Complete — place mode (2026-07-25 — 900/900 suite green, parent-verified; remove mode deferred to story-031 routing per sprint scope)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 0.5 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-047`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary
**ADR Decision Summary**: A valid commit creates blueprint cells grouped into a project; the block tool is single-cell place (attach/replace) or remove.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: No post-cutoff APIs. The remove branch routes to the removal-tool base (Story 031) / draft-eraser branch (Story 015).

**Control Manifest Rules (this layer — Core):**
- Required: single-cell place (attach per surface-aware targeting, or replace-in-place); blueprint cell only.
- Forbidden: never write grid blocks on commit (blueprint cell); replace-in-place of terrain is invalid (Story 022).
- Guardrail: single-cell command — trivially within the cap.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] The block tool places a single cell (attach to the picked face, or replace the picked block in place per Core Rule 3). [TR-047]
- [ ] The block tool's remove mode targets a single cell and routes to the removal path (Story 031 / Story 015). [TR-047]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Core Rule 7, TR-047:*

- Place mode: single-cell blueprint at the picked target (attach to the picked block's face, or replace the picked block in place per surface-aware targeting, Story 020). Validity per Story 022 (replace-in-place of terrain invalid).
- Remove mode: single-cell removal — delegates to the removal-tool micro-state branch (Story 031 base + Story 015 for the full Draft/Queued/Built branching). This story wires the block tool's remove action to that path, it does not re-implement removal.
- Emit the single blueprint cell to the commit pipeline (Story 021).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 031 / Story 015: the actual removal branching logic (this story routes to it).
- Story 021/022/023: pipeline, validity, rendering.

---

## QA Test Cases

**Place single cell**
- Given: the block tool, a valid pick.
- When: `build_place` fires.
- Then: exactly one blueprint cell is created (attach or replace per pick mode).
- Edge cases: replace-in-place of terrain is rejected (Story 022); attach to a terrain face is valid.

**Remove routes to removal path**
- Given: the block tool in remove mode targeting a cell.
- When: `build_remove` fires.
- Then: the removal micro-state branch (Story 031/015) handles it — no separate removal logic here.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/block_tool_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 021 (commit pipeline), Story 020 (pick), Story 022 (validity). Remove mode depends on Story 031.
- Unlocks: the free single-block verb.
