# Story 009: Ghost, marker & invalid-commit presentation

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/hud.md` (element E8 invalid cue, P6) · `design/art/art-bible.md` §7.1 (ghost tint, alpha-as-commitment, same-hue-differs-by-shape), §7.3 (shape budget), §9 Prohibition 2
**Requirement**: `TR-building-ui-080`, `TR-building-ui-081`, `TR-building-ui-049`, `TR-building-ui-037`, `TR-building-ui-040`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (Tuning/Config Data Strategy) — the alpha knobs and their cross-value invariant; ADR-0011 — the invalid-cue fade timer
**ADR Decision Summary**: Every player-visible value is a typed `@export` on one `Resource`-derived config, `.tres` text, validated once at boot; a single-field range issue clamps and warns, boot proceeds. `ghost_alpha_released`'s **floor tracks `ghost_alpha_draft`** rather than a fixed number, so retuning one can never collapse the draft→released ordering invariant that carries the "increased commitment" read. The invalid-cue fade is one keyed record in the centralized `UITimerManager`, never a `Tween` or a `Timer` node.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Reuse ADR-0014's established ghost-rendering precedent — pooled `MeshInstance3D` + `material_override` tint — rather than a new draw path. `VoxelWorldMesher.get_shared_material()` returns the world's `ShaderMaterial`; ghosts must **not** share it (state colors never render on world geometry). Cross-check `docs/engine-reference/godot/` before any transparency/sort-order API (4.7 changed HDR output and material handling).

**Control Manifest Rules (this layer)**:
- Required (Presentation): the ghost renders as a translucent tint of the **actual material selected for placement** — not a generic blueprint hue. The alpha step alone communicates commitment level; no new hue is introduced.
- Forbidden: the slice's **red** demolition tint (Art Bible §9 Prohibition 2 — markers stay in the State-Orange family); distinguishing replace-vs-dig markers by shade or pulse-timing alone; a second invalid channel beside Rule 8's.
- Guardrail: **Invalid overrides everything.** In any state, an invalid placement replaces the material tint with State Orange — one invalid channel, not two.

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md` Rules 8/18, scoped to this story:*

- [ ] **AC55**: Given a Draft ghost cell, Then it renders at `ghost_alpha_draft`; Given the same cell **Released**, Then it renders at `ghost_alpha_released` — a visibly different alpha, **same material tint** (`TR-building-ui-080`).
- [ ] Ghost tint derives from the actual selected placement material's color family (via the item's `visual_asset`/material family), never a generic blueprint hue (Rule 18).
- [ ] **AC56**: Given any tool's preview resolves **invalid**, Then the ghost renders in the **State-Orange** tint regardless of the selected material — the override wins in every state (`TR-building-ui-080`).
- [ ] **AC57**: Given a terrain-replace marker and a dig/demolition marker both visible, Then both render as **inflated overlay boxes** (visibly larger than a flush ghost) but with **distinct icon/overlay SHAPE** — never distinguished by shade or pulse-timing alone (`TR-building-ui-081`, Art Bible §7.1).
- [ ] Both marker kinds sit in the **State-Orange family**; the slice's red demolition tint does **not** survive (Art Bible §9 Prohibition 2). Grep proves no red-family constant in the marker path.
- [ ] **AC10**: Given an invalid-commit event, Then the at-cursor cue appears and auto-fades within `invalid_cue_fade` **±10 %**, blocking no input (`TR-building-ui-049`).
- [ ] The invalid cue optionally carries a **one-line reason** ("occupied", "too many cells") mapped from `CommitPipeline.commit_rejected(reason, cells)`'s `RejectReason` enum; it is never modal and never blocks input (Rule 8).
- [ ] The invalid cue uses the orange accent per the state axis **plus** the gentle negative sound; the sound's visible counterpart is the cue itself (A6 — usable muted).
- [ ] The invalid cue's fade is one keyed `UITimerManager` record — zero `Timer`/`Tween` nodes (`TR-building-ui-040`).
- [ ] `ghost_alpha_draft` (default 0.50, range 0.30–0.70) and `ghost_alpha_released` (default 0.70, floor = current `ghost_alpha_draft`, ceiling 0.90) and `invalid_cue_fade` (default 1 s, 0.5–2 s) all come from `BuildingUiConfig` — never literals (`TR-building-ui-037`).
- [ ] **Flagged, not decided here**: the exact orange-family shade + silhouette **pairing** for terrain-replace vs dig/demolition is an Art Bible §7.3 shape-budget item (GDD Open Question 12). Ship two demonstrably distinct silhouettes and record them as **proposals** for the first production icon pass.

---

## Implementation Notes

*Derived from Rule 18 and the landed commit pipeline:*

- `CommitPipeline` already emits `commit_rejected(reason: RejectReason, cells: Array[Vector3i])` and `blueprint_cells_created(cells: Array[BlueprintCell])` — those two signals are this story's entire input surface for invalid and for ghost state. `BlueprintCell` carries `MicroState` (`PLANNED`/…/`BUILT`) and `Category`; the Draft-vs-Released alpha step reads `BuildProject.state` (DRAFT vs BUILDING) for the owning project, not the cell alone.
- **Alpha is the only commitment channel.** Do not add an outline, a pulse, or a second hue for Released — the GDD is explicit that the alpha step itself communicates commitment.
- The invalid override must be applied at the *material* level, after the material tint is chosen, so no code path can produce an invalid ghost still wearing its material color.
- Inflated boxes: a uniform scale factor above 1.0 on the pooled ghost mesh, plus a distinct billboarded overlay glyph per marker kind. The scale factor is the shared "content is changing to something not-yet-real" tell; the glyph is the differentiator.
- The invalid cue lives **at the cursor**, not in a HUD zone — it is a transient world/screen-space marker (hud.md's "at cursor" row), and must not enter the Visual Budget's element count.
- Reason strings are UI-owned chrome text (German at MVP, localization-ready), mapped from the enum — never composed from upstream free text.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: the hover wireframe/hit-face quad and the build grid.
- Story 013/014: Build Validation's toasts — a different feedback channel with its own severity model. The invalid cue is Building System's, not Build Validation's.
- Story 018: the final icon art and the Art Bible §7.3 reconciliation.
- `building-023`'s ghost **renderer** itself — this story supplies the presentation rules that renderer applies.

---

## QA Test Cases

- **AC55**: Given a cell in a DRAFT project, Then the resolved alpha == `config.ghost_alpha_draft`; Given the same cell after `release_project()`, Then == `config.ghost_alpha_released`, and the resolved tint color is byte-identical in both cases.
- **AC56**: Given material `stone` selected and the preview invalid, Then the resolved tint is State Orange, not stone's family — assert for a Draft cell AND a Released cell.
- **AC57**: Given one replace marker and one dig marker, Then both scales are > 1.0 and equal, and their glyph ids differ; assert both base hues are in the orange family.
- **AC10**: Given `invalid_cue_fade = 1.0` and a `commit_rejected` emission, When 1.1 s of raw delta elapse, Then the cue is gone; at 0.9 s it is still present.
- **Reason mapping**: Given each `RejectReason` value in turn, Then a distinct non-empty one-line string renders.
- **Config**: Given `ghost_alpha_draft = 0.65` and `ghost_alpha_released = 0.60` authored, When `validate()` runs, Then released is clamped to ≥ 0.65 with a warning and boot proceeds.
- **Grep**: zero `Tween`/`Timer` in the cue path; zero red-family constants in the marker path.

---

## Test Evidence

**Story Type**: Integration — the alpha/tint/override resolution and the fade timing are **BLOCKING** (pure functions over state); the rendered appearance and shape distinctness are **ADVISORY**.
**Required evidence (blocking)**: `neues-spiel/tests/unit/ui/ghost_marker_presentation_test.gd` — must exist and pass.
**Required evidence (advisory)**: `production/qa/evidence/building-ui-009-ghost-marker-screenshots.md` — draft/released/invalid/replace/dig, plus a grayscale pass proving shape-only distinctness (A1).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 003 (selected material), 008 (pick data); `building-023` (ghost preview renderer — Cluster 0).
- Unlocks: 017, 018.
