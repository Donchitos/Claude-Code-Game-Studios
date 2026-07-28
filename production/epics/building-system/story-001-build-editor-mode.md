# Story 001: Build/Editor Mode state machine

> **Epic**: Building System
> **Status: Complete (2026-07-26 — 1198/1198 suite green 0 orphans, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-102`, `TR-building-system-103`, `TR-building-system-104`, `TR-building-system-105`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 (Cross-System UI/World Input Arbitration) — primary; ADR-0016 (Build-Project Entity Lifecycle) — secondary
**ADR Decision Summary**: Build-Mode-gated click routing: an armed tool routes a world press to the placement pipeline; with no tool consuming the pick, a surviving world press routes to Selection. Building UI exposes the interaction mode; Building System owns the mode state.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Input routing order `_input()` → `_gui_input()` → `_unhandled_input()`; `set_input_as_handled()` from `_input()` stops later stages. Verify against `docs/engine-reference/godot/` before touching input dispatch.

**Control Manifest Rules (this layer — Core / Presentation input surface)**:
- Required: Build-Mode-gated click routing + Selection arbitration (ADR-0010 §4); world systems listen in `_unhandled_input()`; hover-suppression flag checked before starting any new pick/drag/selection.
- Forbidden: Camera & Input never interprets action names and never emits a world action for a UI-consumed click (exactly-one-owner).
- Guardrail: hover flag is event-driven (boundary-crossing only), never per-frame polling.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC52: GIVEN Build Mode Off, WHEN a tool-select action fires, THEN Build Mode transitions to On and the selected tool arms in the same action (Rule 8b). [TR-102/103]
- [ ] AC53: GIVEN Build Mode On at Idle (no tool armed), WHEN Esc fires, THEN Build Mode transitions to Off and world clicks return to selection; GIVEN a tool armed or a drag in progress, WHEN Esc fires, THEN only that layer exits and Build Mode remains On (Esc chain, Rule 8c). [TR-104]
- [ ] AC54: GIVEN Build Mode Off, WHEN a world click fires, THEN this system does not consume it at all — no tool, ghost, or commit is reachable (Rule 8d). [TR-105]
- [ ] Off is the default state after boot and after the Esc chain's final link. [TR-105]

---

## Implementation Notes

*Derived from ADR-0010 §4 + building-system Rules 8a–8d:*

- Two-state machine: `Off` (boot default) / `On`. Enter `On` via explicit UI toggle OR by arming any tool from the palette (arming auto-enters On first, one player action). Exit `On` only via explicit toggle or the Esc chain — never as a side effect of a single tool deactivation.
- Esc chain is layered with Build Mode always the LAST link: from Dragging → abort drag; from ToolArmed → Idle (still On); from Idle → exit to Off. A single Esc never skips a link (closing a drag never also closes Build Mode in the same press).
- While Off, this system does not consume world clicks at all — they belong to villager/project selection per ADR-0010 §4 arbitration. (The one exception — clicking a project cell selects it even while Off — is Story 008, not implemented here.)
- Expose the interaction mode so Building UI can mirror it (WorldNav vs Build Mode); Building System owns the state, UI renders/routes.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: project click-selection while Build Mode Off (the AC54 exception).
- The tool state machine internals (ToolArmed/Dragging picking/preview) — pre-slice Building System foundation, assumed available.
- The UI toggle widget itself — Building UI's domain.

---

## QA Test Cases

**AC52 — auto-enter Build Mode on tool arm**
- Given: Build Mode is Off, no tool armed.
- When: a tool-select action is dispatched.
- Then: mode == On AND the selected tool is armed, in one action.
- Edge cases: arming a second tool while already On does not re-toggle the mode; arming from Off vs from On both leave the tool armed.

**AC53 — layered Esc chain**
- Given: (a) On + Dragging, (b) On + ToolArmed + Idle-drag, (c) On + Idle no tool.
- When: Esc fires once.
- Then: (a) drag aborts, mode stays On; (b) returns to Idle, mode stays On; (c) mode → Off, clicks return to selection.
- Edge cases: one Esc never crosses two links in a single press; Esc while already Off is a no-op.

**AC54 — no world-click consumption while Off**
- Given: Build Mode Off.
- When: a world press is dispatched through `_unhandled_input()`.
- Then: Building System does not mark the input handled and creates no tool/ghost/commit.
- Edge cases: default post-boot state is Off; state after Esc final link is Off.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/building_system/build_editor_mode_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Camera & Input (action signals, world-ray) and the pre-slice tool state machine foundation. None within this story set.
- Unlocks: Story 008 (click-selection AC54 exception); all placement-tool stories gate through Build Mode.
