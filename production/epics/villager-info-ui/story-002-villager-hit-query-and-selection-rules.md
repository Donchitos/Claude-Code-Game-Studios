# Story 002: Villager hit query, selection rules & Esc/tool-arm routing

> **Epic**: Villager Info UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-info-ui.md`
**UX Spec**: `design/ux/villager-panel.md` (Entry & Exit Points, Interaction Map) · `design/gdd/building-ui.md` Rules 14/15 (the owning chain)
**Requirement**: `TR-villager-info-ui-028`, `TR-villager-info-ui-001`, `TR-villager-info-ui-002`, `TR-villager-info-ui-029`, `TR-villager-info-ui-030`, `TR-villager-info-ui-039`, `TR-villager-info-ui-043`, `TR-villager-info-ui-014`, `TR-villager-info-ui-015`, `TR-villager-info-ui-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 (Physics Backend & Picking Strategy) — the query mechanism; ADR-0010 (§2/§4) — the gate and the routing
**ADR Decision Summary**: Building System's placement pick is a **zero-physics manual DDA grid-walk** — structurally incapable of hitting a villager. Villager hit-testing is therefore a **separate `Area3D` query on a dedicated villager collision layer**, never consulted by the block pick; the two hits are merged by comparing **world-unit ray distances**. ADR-0010: this system's query is one of the two named consumers of the **one** shared hover-suppression flag, and it runs only when no tool is consuming the pick.

**Engine**: Godot 4.7-stable | **Risk**: **HIGH — substrate missing**
**Engine Notes**: **⚑ Known Conflict 1.** `VillagerAi extends Node` (not `Node3D`); `Valley.tscn` hosts a bare `VillagerAi` `Node` with no mesh and no collider; a repo-wide grep for `Area3D`/`CollisionShape` under `src/` returns only doc-comment mentions. `_visual_position` is private with **no public getter** — the only public position API is `get_current_cell() -> Vector3i` (deliberately the discrete cell, never interpolated). There is nothing to hit-test. Godot 4.6 made **Jolt the default** physics backend (ADR-0004, no override) — verify layer/mask semantics against `docs/engine-reference/godot/` when the collider lands.

**Control Manifest Rules (this layer)**:
- Required (Presentation): selection exists **only in Idle** (no build tool armed). While any build tool is armed, **all** clicks belong to the Building pipeline — selection is untouchable.
- Forbidden: the villager query consulting or being consulted by the block pick; a second hover-suppression flag; Building's placement raycast seeing the villager layer (no ghost flicker from villagers walking through the pick); **new InputMap actions** (this system reuses the existing click action in the unclaimed Idle niche).
- Guardrail: the villager wins within `pick_tie_epsilon`; the block wins strictly beyond it. `pick_tie_epsilon` is a **correctness constant, not a tuning knob.**

---

## Acceptance Criteria

*From GDD `design/gdd/villager-info-ui.md` Rule 1 + Edge Cases 2/3/7, scoped to this story:*

- [ ] **AC1**: Given Idle mode and a mocked villager hit, When click fires, Then that villager is selected and the panel opens (`TR-villager-info-ui-028`).
- [ ] **AC2**: Given Idle and a mocked **empty** hit, When click fires, Then selection clears; Given Esc (with no HUD focus), Then likewise (`TR-villager-info-ui-028`).
- [ ] **AC3**: Given villager A selected and a hit on B, When click fires, Then selection switches to B **in one step** (`TR-villager-info-ui-028`).
- [ ] **AC4**: Given any build tool armed (mocked), When a click fires, Then **no selection change** — clicks belong to Building (Rule 1, `TR-villager-info-ui-001`).
- [ ] **AC5**: Given a selected villager and a mocked tool-arm event, Then the panel closes and selection clears — a clean mode switch (Edge Case 7, `TR-villager-info-ui-043`).
- [ ] **AC21 (HUD-hover gate)**: Given the **shared** hover-suppression flag active (mocked cursor-over-HUD), When a click fires over a villager rendered behind the HUD, Then **no selection change occurs — neither select nor deselect** (Rule 1's HUD-hover gate, `TR-villager-info-ui-002`).
- [ ] **AC22 (Esc routing)**: Given a villager selected **AND** a Building UI element holding keyboard focus (mocked), When Esc fires, Then the HUD focus releases and the selection is **UNCHANGED**; When Esc fires again with no HUD focus, Then the villager deselects — a deterministic two-step, no double-fire (`TR-villager-info-ui-029`). **Implemented as Building UI's four-step chain** (Known Conflict 6): this system supplies step 3's predicate and consumes its clear.
- [ ] **AC15**: Given a mocked ray with a villager and a **nearer** block, Then the block wins; given overlap/tie, Then the villager wins (Edge Case 2, `TR-villager-info-ui-015`).
- [ ] **AC26**: Given a mocked villager-hit at distance t₁ and a block-hit at t₂ with `|t₁ − t₂| < pick_tie_epsilon`, Then the **villager** wins; given the block strictly nearer beyond epsilon, Then the **block** wins (Edge Case 2's explicit tolerance — replaces the untestable float-tie) (`TR-villager-info-ui-015`).
- [ ] **AC16**: Given a mocked ray hitting villagers A/B/C at different distances, Then the **nearest** is selected — deterministic and repeatable; equal-distance villagers break ties by **stable villager processing order**, matching Villager AI's determinism convention (Edge Case 3, `TR-villager-info-ui-016`).
- [ ] **Query separation**: villager hit-testing is a dedicated query on a dedicated villager collision layer, **distinct from and never consulted by** the block-picking DDA; Building's own placement raycast **ignores** the villager layer (`TR-villager-info-ui-014`).
- [ ] **No new InputMap actions** are introduced — this system reuses the existing click action in the unclaimed Idle niche (`TR-villager-info-ui-039`).
- [ ] **Keyboard-selection exemption recorded, not implemented**: MVP ships selection as **mouse-only**, a *stated* exemption from "no persistent element is mouse-only" — not an oversight. The keyboard path (select-cycle / focus-nearest-distressed) is committed to the VS revision alongside the roster view (`TR-villager-info-ui-030`).
- [ ] Selecting a villager clears any project Selection and vice versa — mutual exclusivity is Building UI's Rule 15, consumed here (`TR-building-ui-077`).

---

## Implementation Notes

*Derived from ADR-0004's query separation and ADR-0010's gate:*

- **⚑ This story cannot start until Known Conflict 1 is decided.** Villagers need a `Node3D`-rooted visual body with an `Area3D` + `CollisionShape3D` on a dedicated layer, and a public interpolated world-position accessor. `VillagerAi extends Node` today and `_visual_position` is private. That change belongs to **villager-ai / technical-director**, not to this story. Until it lands, drive every AC against an **injected villager-hit provider** interface — which is also the right long-term shape, since it keeps the merge logic testable headlessly.
- **The merge is the testable core.** Write it as a pure function `resolve_pick(villager_hits: Array, block_hit_t: float, epsilon: float) -> Result`: sort villager hits by `t`, take nearest (stable id order on exact ties), then apply the epsilon rule against the block. AC15/AC16/AC26 are all cases of that one function.
- `pick_tie_epsilon` lives on the config as a typed field for data-drivenness, with a doc comment stating it is a **correctness constant, not a tuning knob** (the GDD's Tuning Knobs section is explicit that this system has none).
- Read the shared gate via Building UI's `is_hover_suppressing_world_pick()` — **do not** duplicate it. AC21's real assertion is "one flag, two consumers".
- The tool-armed predicate comes from Building System's tool state (`ToolStateMachine.get_state()` / `get_armed_tool()`), read as a mirror. AC4 and AC5 are two directions of the same rule.
- Building's placement raycast must ignore the villager layer. Landed `PlacementPick` is zero-physics DDA, so this holds **by construction** today (its own doc comment says it is "structurally incapable of hitting a villager"). Assert it by absence and record that the guarantee is structural, not configured.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: the panel host, the Selection field itself, Suspended, and the mirror loop.
- Story 006: the hover affordance and selection outline (what a *hoverable* villager looks like).
- `building-ui` story 007: the hover-suppression flag's definition; `building-ui` story 002: the Esc chain; `building-ui` story 010: villager-vs-project routing.
- Creating the villager collider/body — **villager-ai / technical-director** (Known Conflict 1).
- Any keyboard selection path (VS-tier, explicitly exempted).

---

## QA Test Cases

- **AC1/AC2/AC3**: Given a mocked hit provider, exercise select → empty-click deselect → select A → select B, asserting one-step switching and exactly one selected id throughout.
- **AC4**: Given tool `wall` armed, When a click with a villager hit fires, Then `get_selection()` is unchanged and no `villager_selected` fired.
- **AC5**: Given villager A selected, When a tool-arm event fires, Then selection is empty and the panel hidden.
- **AC21**: Given the shared flag mocked true and a villager hit, When click fires, Then neither select nor deselect occurred — assert both negatives.
- **AC22**: Given selection + HUD focus, Esc → focus released, selection unchanged; Esc again → deselected. Assert exactly one step per press.
- **AC15/AC26**: table-driven over `(t_villager, t_block)` pairs spanning both sides of `pick_tie_epsilon` plus the exact-boundary case.
- **AC16**: Given villagers at t = 5, 3, 9 with ids 7, 2, 4, Then id 2 wins; given two at t = 3 with ids 9 and 2, Then id 2 wins (stable order), repeated 100× for determinism.
- **Query separation**: Given the source, When grepped, Then the block-pick path contains no villager-layer reference and the villager query contains no `raycast_cells` call.
- **No new actions**: Given the InputMap at boot, Then this module registered nothing.

---

## Test Evidence

**Story Type**: Logic (pure merge/precedence rules + routing) — **BLOCKING**.
**Required evidence**: `neues-spiel/tests/unit/ui/villager_selection_pick_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001; `building-ui` stories 002 (Esc chain), 007 (hover gate), 010 (Selection routing); **Known Conflict 1** — the villager body/collision-layer decision must land first (technical-director + villager-ai). **This is the epic's critical path.**
- Unlocks: 003, 005, 006.
