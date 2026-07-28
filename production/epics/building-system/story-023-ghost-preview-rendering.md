# Story 023: Ghost preview rendering + drag re-rasterization + degradation + state tint

> **Epic**: Building System
> **Status: Complete (2026-07-26 — 1175/1175 suite green 0 orphans, parent-verified; evidence captured against the real booting world)
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-26

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-003`, `TR-building-system-026`, `TR-building-system-035`, `TR-building-system-039`, `TR-building-system-093`, `TR-building-system-069`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014 (Chunked Voxel Rendering & Large-World Storage) — primary
**ADR Decision Summary**: Blueprint ghosts = pooled `MeshInstance3D` nodes with `material_override` tint; bounded by `max_cells_per_command = 512`, outline-degrade above `preview_degradation_threshold`. State colours live on ghost/overlay presentation, never committed-block materials.

**Engine**: Godot 4.7-stable | **Risk**: HIGH (rendering domain — pooled `MeshInstance3D` + `material_override`; verify against `docs/engine-reference/godot/`)
**Engine Notes**: Ghost tint via `material_override`, never per-instance custom-data plumbing. Preview updates on the raw-input path (responsive even while paused). Godot 4.7 front-face winding is CW.

**Control Manifest Rules (this layer — Presentation):**
- Required: blueprint ghosts = pooled `MeshInstance3D` with `material_override` tint, bounded by `max_cells_per_command`, outline-degrade above `preview_degradation_threshold`; ghost previews use the colorblind-safe blue (valid) / orange (invalid) state axis; Planned vs UnderConstruction visually distinct.
- Forbidden: state colors never render on committed-block geometry — build-state coloring lives on ghost/overlay only; never per-instance custom-data plumbing for ghost tint.
- Guardrail: above `preview_degradation_threshold` cells the live drag preview degrades to an outline to protect the frame budget; the eventual commit stays cell-exact.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC1: GIVEN no active tool, WHEN a tool is selected, THEN the state is ToolArmed and a ghost preview follows the pick each frame. [TR-026]
- [ ] AC50: GIVEN a drag whose pending cell count exceeds `preview_degradation_threshold`, WHEN the preview updates, THEN it renders as an outline/bounding representation rather than per-cell ghosts, while the eventual commit remains cell-exact. [TR-039]
- [ ] The preview re-rasterizes every frame as the cursor moves — the full pending result is always current, never frozen at drag start. [TR-003]
- [ ] Valid preview = cool blue-tinted translucent ghost; invalid = unmistakable orange tint (never red-green). [TR-093]
- [ ] Planned vs UnderConstruction are visually distinct. [TR-069]

---

## Implementation Notes

*Derived from ADR-0014 §4 + building-system Visual Requirements + Dragging state, TR-003/026/035/039/069/093:*

- Ghost previews are pooled `MeshInstance3D` nodes with `material_override` tint (valid = blue, invalid = orange — colorblind-safe blue–orange axis, never red-green). Pool bounded by `max_cells_per_command` (512).
- ToolArmed: the ghost follows the pick each frame (raw-input path — responsive even while paused).
- Dragging: the preview re-rasterizes every frame from the current cursor (wall segment / floor rect / roof footprint always current). Above `preview_degradation_threshold` (128) cells, degrade to an outline/bounding representation while keeping the commit cell-exact.
- Planned vs UnderConstruction must read distinctly (Planned = static translucent ghost via `draft_ghost_alpha`/`queued_ghost_alpha`; UnderConstruction = visible progress fill — exact treatment to the art bible).
- State colors live on ghost/overlay only — never baked into committed-block materials.
- Consumes the validity bool (Story 022) for tint and the picked cell/surface (Story 020) for anchoring.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 022: computing validity (this story only renders the resulting tint).
- Story 029: the UnderConstruction progress-fill data (this story renders the distinct visual state).
- The exact art-bible material/animation curves — art-director's domain.

---

## QA Test Cases

**AC1 — ghost follows pick (manual/screenshot)**
- Setup: arm a tool with a valid pick.
- Verify: a ghost preview appears and tracks the cursor each frame.
- Pass condition: ghost visibly follows the pick with no perceptible lag; hidden at Idle.

**AC50 — degradation (manual/screenshot)**
- Setup: drag a pending cell count above `preview_degradation_threshold`.
- Verify: the preview renders as an outline/bounding box, not per-cell ghosts; the committed result is still cell-exact.
- Pass condition: no frame-budget hitch on the large drag; commit matches the outlined region exactly.

**Valid/invalid tint (manual/screenshot)**
- Setup: hover a valid target, then an invalid one.
- Verify: valid = blue translucent, invalid = orange; never red-green.
- Pass condition: tint flips with validity; colorblind-safe axis.

**Planned vs UnderConstruction distinctness (manual/screenshot)**
- Setup: a Planned cell and an UnderConstruction cell in view.
- Verify: the two states are visually distinct (alpha tiers / progress fill).
- Pass condition: a viewer can tell them apart at a glance.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/ghost-preview-rendering-evidence.md` (screenshots) + lead sign-off.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 020 (pick anchor), Story 022 (validity bool), Story 019 (tool SM).
- Unlocks: the visible pick→preview→commit loop for all tools.
