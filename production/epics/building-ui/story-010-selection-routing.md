# Story 010: Selection routing — villager XOR project XOR none

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/projects-panel.md` (Selection Model) · `design/ux/villager-panel.md` (Entry & Exit Points)
**Requirement**: `TR-building-ui-077`, `TR-building-ui-086`, `TR-building-ui-076`, `TR-villager-info-ui-028`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 (Cross-System UI/World Input Arbitration) §4
**ADR Decision Summary**: Selection routing is a **routing decision** — which consumer's query owns a world click — of the same class as hover suppression, and adds **no new event-routing primitive**. When no tool is consuming the pick (WorldNav, or Build Mode Idle), a world press that survives the hover-suppression gate routes to Selection instead of placement. Placement is untouched: Camera & Input → Building System still own that pipeline.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: The villager hit-test is a **separate query on a dedicated villager collision layer** (ADR-0004's `Area3D` query), distinct from and never consulted by the DDA block pick; the two hits are merged by comparing world-unit distances. **⚑ That layer does not exist yet** — see the villager-info-ui epic's Known Conflict 1. Until it lands, drive this story's ACs against a mocked villager-hit provider.

**Control Manifest Rules (this layer)**:
- Required (Presentation): Selection is **mutually exclusive** — villager XOR project XOR none. Selecting one clears the other, mirroring the existing "exactly one tool active" invariant.
- Forbidden: two independent Selection states (the world outline and the panel highlight are two renders of ONE value); Selection surviving as render state (it is UI state — a Slice-View cutoff never touches it).
- Guardrail: **villager wins ties** — a person is always the more specific target than the space they occupy.

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md` Rule 15 + Edge Cases 14/18, scoped to this story:*

- [ ] **AC47**: Given WorldNav, When a world click resolves to a cell occupied by **both** a villager and a project, Then the villager claims the Selection and the project is **NOT** selected (Rule 15 precedence, Edge Case 14, `TR-building-ui-077`).
- [ ] **AC48**: Given WorldNav, When a world click resolves to a project cell with no villager on it, Then that project becomes the Selection, its world-space outline renders, and its Projects Panel card highlights **the same frame** (`TR-building-ui-077`).
- [ ] Given a click on bare terrain, water, or empty space, Then any existing Selection **clears** (Rule 15's third branch).
- [ ] Selection is mutually exclusive: selecting a villager clears a project Selection and vice versa; at no point are both non-null (`TR-building-ui-077`).
- [ ] **AC49**: Given a project selected via its Projects Panel card, Then the **identical** world-space outline appears as a world-click selection would produce — one Selection, two renders (`TR-building-ui-086`).
- [ ] Selecting a project **never requires Build Mode to be on** — it is selectable from World Navigation with no tool armed (projects-panel.md Selection Model, the stated Rule 8d exception).
- [ ] Selection **persists across a Build Mode toggle** (select a project, then enter Build Mode to edit it — it stays selected) and across Slice View changes (`TR-building-ui-085`, Edge Case 18).
- [ ] **AC65**: Given a slice level hiding the villager or project that is the current Selection, Then the Selection state is **unchanged** (still queryable, panel highlight still shows) even though no world-space outline renders — it is UI state, not render state.
- [ ] Selection routing runs **only** when no tool is consuming the pick, and **only** after the hover-suppression gate passes (story 007) and the Build Mode gate (story 002) — one additional condition on the NEW-press path, in that documented precedence.
- [ ] The villager-hit query and the block-pick query are **separate mechanisms**, merged by ray-parametric world-unit distance; the villager wins within `pick_tie_epsilon`, the block wins strictly beyond it (`TR-villager-info-ui-015`).
- [ ] The project world-space outline traces the project's **full footprint**, not a single cell (projects-panel.md).
- [ ] Esc chain step 3 clears the Selection and **nothing else** — Build Mode remains on, the panel stays open (`TR-building-ui-076`, AC45).

---

## Implementation Notes

*Derived from ADR-0010 §4 and `design/ux/projects-panel.md`'s Selection Model:*

- **One value, two renders.** Store `Selection` as a single tagged value (`{kind: NONE|VILLAGER|PROJECT, id: int}`) on the Building UI module. The world outline, the Projects Panel highlight, and the villager panel all *read* it; none of them owns a copy. Every AC in this story falls out of that shape.
- Resolve "which project owns this cell" via `BuildProjectRegistry.project_at_cell(cell) -> int` (landed) — do not re-derive ownership by scanning `get_cells()`.
- The tie rule is distance-based, not layer-priority-based: compute `t_villager` and `t_block` in world units and apply `|t_v − t_b| < pick_tie_epsilon → villager`. `pick_tie_epsilon` is a **correctness constant**, not a tuning knob (villager-info-ui Tuning Knobs) — put it in `BuildingUiConfig` with a comment saying so.
- Selection is **never serialized** (villager-info-ui Rule 3; projects-panel.md Events Fired). Assert its absence from any save path.
- Emit `project_selected(id)` and let villager-info-ui emit its own `villager_selected(id)` — the two panels are separate consumers of one exclusive value, not two coordinating owners.
- **Known Conflict (villager side)**: villagers have no collision layer, no visual body, and `VillagerAi extends Node` (not `Node3D`). Implement the merge against an injected villager-hit provider interface so the real query drops in later without touching this logic.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 011: the Projects Panel card that *renders* a project Selection.
- Story 016: the Slice View cutoff itself (this story only asserts Selection is unaffected by it).
- villager-info-ui story 002: the villager hit query's own implementation and the villager panel's open/close.
- Story 007: the hover-suppression gate.

---

## QA Test Cases

- **AC47**: Given a mocked cell with both a villager hit at t=10.0 and a project cell at t=10.0, Then the Selection kind is VILLAGER and no `project_selected` fired.
- **AC48**: Given a project cell hit with no villager, Then Selection kind is PROJECT with the registry's id, `project_selected` fired once, and the outline cell set equals the project's full footprint.
- **Clear**: Given a Selection and a click resolving to bare terrain, Then Selection kind is NONE.
- **Exclusivity**: Given villager A selected, When a project cell is clicked, Then kind is PROJECT and the villager id is cleared — assert both in one step, no intermediate both-set state observable.
- **AC49**: Given a card click and a world-cell click on the same project in separate runs, Then the produced outline cell sets are identical.
- **Persistence**: Given a project selected in WorldNav, When Build Mode is entered and a tool armed and then canceled, Then the Selection is unchanged throughout.
- **AC65**: Given a slice level hiding every cell of the selected project, Then `get_selection()` is unchanged and the panel highlight is still set while the outline renders nothing.
- **Tie epsilon**: Given `t_villager = 10.00`, `t_block = 10.00 + epsilon*2`, Then the villager loses (block strictly nearer beyond epsilon → block wins) — assert both sides of the boundary.

---

## Test Evidence

**Story Type**: Logic (routing/precedence rules) — **BLOCKING**.
**Required evidence**: `neues-spiel/tests/unit/ui/selection_routing_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002 (mode gate), 007 (hover gate), 008 (pick data); a villager-hit provider (mocked until the villager-info-ui epic's Known Conflict 1 is resolved).
- Unlocks: 011, 012; **and the villager-info-ui epic's story 002**.
