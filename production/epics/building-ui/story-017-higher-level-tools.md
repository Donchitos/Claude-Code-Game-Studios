# Story 017: Higher-level tools — Room, Auto-roof & House stamp

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/hud.md` (toolbar zone Z6 — the three additional tool icons) · `design/ux/projects-panel.md` (each tool's commit produces ONE Draft project)
**Requirement**: `TR-building-ui-082`, `TR-building-ui-083`, `TR-building-ui-084`, `TR-building-ui-075`, `TR-building-ui-065`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle)
**ADR Decision Summary**: A commit creates blueprint (Draft) cells owned by the Building System, grouped into a persistent project entity — never a direct grid write. Each higher-level tool's whole result is **ONE draft project**, not N separate commands: the Room tool's perimeter run, the Auto-roof's cap (joining the **same** project id), and the House stamp's floor+walls+roof.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `tool_select_room`, `tool_select_roof`, `tool_select_house` are **already registered** in `project.godot` (keys 6/7/8) and listed in `CameraInput.OWNED_ACTIONS` (verified 2026-07-26); their key defaults are `[assumption]` per GDD Open Question 13.

**Control Manifest Rules (this layer)**:
- Required (Presentation): all three arm **only in Build Mode** (Rule 13) and follow the **same** pick → preview → commit pipeline as the base tools (Building System Core Rule 2). This story owns the HUD/interaction surface only.
- Forbidden: **implementing the cell-generation algorithms here.** Rule 19 states plainly that the mechanical cell generation is Building System's domain and requires that GDD's own propagation. A partial stamp of any kind.
- Guardrail: an ineligible commit shows the standard invalid-commit cue (Rule 8) and **creates nothing** — never a partial result.

---

## ⚑ Blocked at the design level — read before starting

GDD **Open Question 9** is open: *"Building System needs its own revision to formally own the room / auto-roof / house-stamp cell-generation algorithms (Rule 19, reusing F1/F2/F5 over a computed footprint)."* `design/gdd/building-system.md` has **not** been revised, and no Room/Auto-roof/House tool class exists in `neues-spiel/src/building_system/`. This story cannot produce the algorithms; it produces the arming, preview, precondition-gating and commit-routing surface **around** them.

Run `/propagate-design-change` per `prototypes/last-seal-vertical-slice/REPORT.md`'s recommendation first. Owner: game-designer + technical-director.

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md` Rule 19 + Edge Cases 16/17/20, scoped to this story:*

- [ ] All three tools arm **only** in Build Mode; firing their tool-select action from WorldNav enters Build Mode and arms in the same frame (Rule 13 auto-enter, `TR-building-ui-075`), and each follows the shared pick → preview → commit pipeline.
- [ ] **AC58 (Room)**: Given the Room tool with a **4×5** ground-plane drag, When committed, Then a **single** draft project is created containing the full perimeter wall run at the current `wall_height` plus **exactly one** camera-facing door-gap cell omitted from that run (`TR-building-ui-082`).
- [ ] The door gap is omitted from whichever perimeter edge faces the camera **at commit time** — recomputed on commit, not at drag start (the player may orbit mid-drag) (`TR-building-ui-082`).
- [ ] **AC59**: Given the Room tool dragged below the **3×3 minimum**, When committed, Then the invalid-commit cue appears and **no project is created** (Edge Case 20, `TR-building-ui-082`).
- [ ] **AC60 (Auto-roof)**: Given Auto-roof clicked on a cell belonging to an existing project, When committed, Then a **Flat** roof is generated over that project's bounding box at its top height and **joins the SAME project id** (`TR-building-ui-083`).
- [ ] **AC61**: Given Auto-roof clicked on a cell belonging to **no** project (bare terrain or an unowned lone block), When committed, Then the invalid-commit cue appears and nothing is created (Edge Case 16, `TR-building-ui-083`).
- [ ] **AC62 (House stamp)**: Given the House stamp clicked on a **7×7-eligible** footprint (uniform terrain height, clear volume up to roof height), When committed, Then **exactly ONE** new draft project is created containing the flush floor, perimeter walls with one door gap, and a Flat roof at wall-height above (`TR-building-ui-084`).
- [ ] **AC63**: Given the House stamp clicked on a footprint with a height-stepped cell or an obstruction, When committed, Then the invalid-commit cue appears and **no project is created — never a partial stamp** (Edge Case 17, `TR-building-ui-084`).
- [ ] Each tool has its own toolbar icon (3 new assets, Art Bible §7.3) and its own preview presentation reusing story 009's ghost vocabulary — draft alpha, State-Orange invalid override.
- [ ] The preview shows the **full** generated cell set before commit, so an ineligible footprint reads as invalid before the click resolves.
- [ ] **AC22 (partial)**: Given the InputMap at boot, Then `tool_select_room`, `tool_select_roof`, `tool_select_house` exist as registered actions (`TR-building-ui-065`).
- [ ] The commit routes through `CommitPipeline` exactly as a base tool does — one cell-set resolver, one all-or-nothing validity gate, one `blueprint_cells_created` emission.

---

## Implementation Notes

*Derived from Rule 19 and the landed tool/commit shape:*

- Landed base tools (`WallTool`, `FloorTool`, `RoofTool`, `BlockTool`) all expose `resolve_cell_set(is_drag, press_cell, release_cell) -> Array[Vector3i]` and plug into `CommitPipeline.set_cell_set_resolver()`. The three higher-level tools take the **same shape** — which is exactly why their algorithms belong in `src/building_system/`, not in the UI module.
- Reuse `WallTool.rasterize_run`/`extrude_column` for the Room perimeter and `RoofTool.flat_roof_cell_set` for both roof cases. The GDD is explicit that no new formula is introduced — these are F1/F2/F5 over a computed footprint.
- **Camera-facing edge at commit time**: derive from `CameraInput.get_yaw()` at the moment the release resolves, mapping to one of four perimeter edges. Record the mapping convention (which yaw quadrant → which edge) in the story; it is the kind of detail that silently drifts.
- Auto-roof's "join the SAME project" uses `BuildProjectRegistry.project_at_cell(cell)` to find the id, then routes the generated cells into that project rather than creating a new one. `BuildProjectRegistry.assign_cells()` is the landed seam.
- **Preconditions are all-or-nothing and must be evaluated on the preview**, not only at commit: 3×3 minimum (Room), owning-project existence (Auto-roof), uniform height + clear volume (House). The invalid path reuses Rule 8's single cue — do not add a second rejection channel.
- Only `FLAT` is implemented in `RoofTool.resolve_cell_set` (milestone Out of Scope: roof formations beyond Flat are VS-tier). Both roof-producing tools therefore produce Flat only, by design.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- The cell-generation algorithms themselves — **Building System's**, pending GDD Open Question 9's propagation.
- Story 009: the ghost/invalid presentation vocabulary this story reuses.
- Story 011/012: the Projects Panel that renders the resulting project.
- Story 018: door-gap discoverability (Rule 22) — a separate affordance requirement.

---

## QA Test Cases

- **AC58**: Given a 4×5 drag with the camera facing +Z, When committed, Then exactly one project id was created, its cell set equals the perimeter extrusion minus one contiguous 1-cell gap, and that gap lies on the +Z edge.
- **Camera recompute**: Given the same drag with the camera orbited to face −X **between press and release**, Then the gap lies on the −X edge — proving commit-time recompute.
- **AC59**: Given a 2×3 drag, Then zero projects created and the invalid cue fired once.
- **AC60**: Given a cell of project #4 clicked, Then the resulting roof cells all belong to project id 4 — assert no new id was registered.
- **AC61**: Given bare terrain clicked, Then zero cells created and the invalid cue fired once.
- **AC62**: Given an eligible 7×7 footprint, Then exactly one project contains floor + wall + roof cells and the wall run has exactly one gap.
- **AC63**: Given a footprint with one height-stepped cell, Then zero cells created — assert the project registry size is unchanged, not merely that the commit "failed".
- **Build Mode gate**: Given WorldNav, When `tool_select_house` fires, Then Build Mode is on and the House tool is armed in the same frame.

---

## Test Evidence

**Story Type**: Integration — precondition gating, project-identity routing and the camera-facing edge rule are **BLOCKING**; the preview appearance is **ADVISORY**.
**Required evidence (blocking)**: `neues-spiel/tests/unit/ui/higher_level_tools_test.gd` — must exist and pass.
**Required evidence (advisory)**: `production/qa/evidence/building-ui-017-higher-level-tools-walkthrough.md`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002 (Build Mode + arming), 009 (ghost/invalid presentation), 011 (projects exist to join); `building-003`/`005` (project registry + assignment); **GDD Open Question 9's propagation into `design/gdd/building-system.md`** — a **design-level blocker**; **Known Conflict 5** for any dig-order interaction.
- Unlocks: —
