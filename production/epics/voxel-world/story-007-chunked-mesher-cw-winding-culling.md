# Story 007: Chunked face-culled mesher — CW winding + backface culling ENABLED (TECH DEBT 1)

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-24 — 335/335 suite green; evidence PNGs parent-inspected: oblique angle clean, culling ON)
> **Layer**: Presentation (Voxel World mesher tier)
> **Type**: Visual/Feel
> **Estimate**: 1.5 days
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-052`, `TR-voxel-world-025`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014 (Chunked Voxel Rendering) — primary
**ADR Decision Summary**: Committed blocks render via a chunked mesher: 16×16-column chunks, one `ArrayMesh` per chunk, faces emitted only where a cell borders air, whole-chunk rebuild on any cell change. **Faces wind CW with backface culling ENABLED** — Godot 4.7's front-face convention is clockwise (an engine fact). The slice's CCW + `CULL_DISABLED` mitigation is now EXPIRED.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: **Godot 4.7 front-face winding is CLOCKWISE (CW).** Auditing against a self-stored CCW assumption was the slice's multi-session "missing faces" root cause. Face-winding audits MUST validate against the engine's ACTUAL documented convention (cross-reference `docs/engine-reference/godot/`), never a self-stored one. Material ships with culling enabled.

**Control Manifest Rules (this layer)**:
- Required: 16×16-column chunks, one `ArrayMesh` per chunk, faces only where a cell borders air, whole-chunk rebuild on cell change; faces wind CW with culling ENABLED.
- Forbidden: never CCW winding or `CULL_DISABLED` for committed-block materials; never `GridMap`; never full greedy meshing / GDExtension mesher until measurement demands them.
- Guardrail: whole-chunk rebuild measured ~1.1 ms; 60 FPS on the production window with culling re-enabled (headroom expected — slice held 60 FPS at 2× faces on `CULL_DISABLED`).

---

## Acceptance Criteria

- [ ] The mesher generates faces only where a cell borders air; whole-chunk rebuild triggers on `cell_changed`/`cells_changed_batch`. [TR-voxel-world-025]
- [ ] Generated triangle winding matches Godot's clockwise (CW) front-face convention with backface culling ENABLED, verified against the engine's actual documented behavior — not a self-stored assumption (AC24). [TR-voxel-world-052]
- [ ] No missing-face regressions versus a fully-solid reference chunk (every exposed face visible from outside). [TR-voxel-world-052]

---

## Implementation Notes

*Derived from ADR-0014:*

- Written fresh to production standards (slice code is reference-only). Do NOT reproduce the slice's CCW + `CULL_DISABLED` mitigation — implement CW + culling-enabled from the start; the "rewrite" framing is relative to the slice's shipped state.
- Emit a face only where the neighboring cell (via Story 004 `get_neighbors`/`get_cell`) is air. Build one `ArrayMesh` per 16×16 column chunk; rebuild the whole chunk on any change signal for that chunk.
- Wind every emitted quad's two triangles CW per the engine convention; set the material to cull back-faces.
- Verification is by screenshot against a reference solid block set — confirm no missing faces from any orbit angle and that interior/back faces are culled.

---

## Out of Scope

- Story 015: per-frame view-window build/unload budgeting (which chunks are meshed as the camera moves).
- Ghost/blueprint preview meshes (Building System slice).
- State-color rendering on world geometry (forbidden — lives on ghost/overlay presentation only).

---

## QA Test Cases

*Visual/Feel — manual verification (screenshot + lead sign-off).*

- **AC-1 (CW winding + culling, no missing faces)**: [TR-voxel-world-052]
  - Setup: generate a small solid block cluster; enable the committed-block material with culling on
  - Verify: orbit the camera a full 360°/pitch range and screenshot; confirm every outward-facing face renders and no face is missing/see-through
  - Pass condition: zero missing faces from any angle; back-faces are culled (interior not visible through gaps); winding confirmed against `docs/engine-reference/godot/` convention notes, not a project assumption
- **AC-2 (rebuild on change)**: [TR-voxel-world-025]
  - Setup: place then remove a block inside a meshed chunk
  - Verify: screenshot before/after
  - Pass condition: the chunk mesh updates to reflect the new air/solid boundary (new face appears on removal, face disappears on placement)

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/chunked-mesher-cw-winding-culling-evidence.md` + lead sign-off
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (storage + `cell_changed`); uses Story 004 (`get_neighbors`)
- Unlocks: Story 015 (mesh view-window streaming)
- **Producer note**: milestone risk register flags this as "do early, before asset scale-up" — the 2× overdraw headroom will not survive a large jump in scene complexity. Schedule right after storage (Story 002) is stable, ahead of the write-path and residency clusters where sequencing permits.
