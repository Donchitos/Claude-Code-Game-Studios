# Story 002: Build Mode gate, tool arming/highlight & the four-step Esc chain

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/hud.md` (E1 toolbar, Default Key Bindings, Dynamic Behaviors 1/6)
**Requirement**: `TR-building-ui-044`, `TR-building-ui-045`, `TR-building-ui-067`, `TR-building-ui-075`, `TR-building-ui-076`, `TR-building-ui-065`, `TR-building-ui-060`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 (Cross-System UI/World Input Arbitration) §4
**ADR Decision Summary**: The Build Mode master toggle and the resulting click routing are an **extension of the existing hover-suppression gate, not a new mechanism**. Building UI exposes the current interaction mode (WorldNav vs Build Mode); the mode is checked at the same point, and with the same precedence, as `is_hover_suppressing_world_pick()` — one additional gate condition on the NEW-press path, never a second dispatch mechanism. Placement itself is still Camera & Input → Building System's pipeline, untouched.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Every action this story fires is **already registered** in `project.godot` and listed in `CameraInput.OWNED_ACTIONS` (verified 2026-07-26): `tool_select_1..5`, `tool_select_room`, `tool_select_roof`, `tool_select_house`, `build_mode_toggle`. `CameraInput.action_fired(action_name)` is the opaque one-shot passthrough — Camera & Input never interprets the name, this system does. **Tab is never used** (Godot's built-in `ui_focus_next` collision, GDD Open Question 7).

**Control Manifest Rules (this layer)**:
- Required (Presentation): exactly one tool ever appears active; the armed tool is mirrored from Building System's state, never latched locally. Firing a tool-select action from WorldNav enters Build Mode AND arms the tool **in the same frame**.
- Forbidden: the HUD setting Building System's tool state directly (it emits intents); any tool arming while in World Navigation; an Esc press resolving more than one chain step.
- Guardrail: `armed_tool_count <= 1` is an invariant over every interleaving of mocked state sequences (AC21).

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md` Rules 3/13/14 + Edge Cases 2/19, scoped to this story:*

- [ ] **AC1**: Given any tool selected in the Building System (mocked signal), When it arrives, Then the matching button highlights and all others un-highlight, **same frame** (`TR-building-ui-044`).
- [ ] **AC2**: Given key 1–5 pressed, When the action fires, Then the corresponding tool-select **intent is emitted** — the UI sends intents, never sets Building state directly (`TR-building-ui-044`).
- [ ] **AC3**: Given a tool armed, When cancel fires, Then the UI returns to Build-Mode/Idle, the context panel hides, and the previously-armed button un-highlights (`TR-building-ui-044`).
- [ ] **AC17**: Given rapid interleaved tool-select events (spam 1–5), Then last-input-wins with exactly one highlight and no stale panel at every step (Edge Case 2, `TR-building-ui-067`).
- [ ] **AC21**: Given arbitrary interleaved mocked state sequences, Then at no point do two tools appear active simultaneously — an invariant, not a spot check (`TR-building-ui-044`).
- [ ] **AC42**: Given WorldNav, When `build_mode_toggle` fires, Then the state becomes Build-Mode/Idle and the tool + higher-level-tool buttons become available (`TR-building-ui-075`).
- [ ] **AC43**: Given WorldNav, When any tool-select action fires (button, key 1–5, or a higher-level-tool key), Then Build Mode enters AND the tool arms in the same frame — **no intermediate Build-Mode/Idle frame is ever observable** (Rule 13 auto-enter, `TR-building-ui-075`).
- [ ] No base tool and none of Room / Auto-roof / House stamp can arm while in World Navigation (Rule 13, `TR-building-ui-075`).
- [ ] **AC44**: Given a tool armed inside Build Mode, When Esc fires, Then the state returns to Build-Mode/Idle **only** — never further (Rule 14, chain step 2).
- [ ] **AC45**: Given Build-Mode/Idle with no tool armed and an active Selection, When Esc fires, Then the Selection clears and Build Mode remains ON (chain step 3).
- [ ] **AC46**: Given Build-Mode/Idle with no tool armed and no active Selection, When Esc fires, Then the state returns to WorldNav (chain step 4).
- [ ] **Chain step 1 precedence**: Given a toast or the expanded anchor holds HUD keyboard focus, When Esc fires, Then that focus is released **only** — never a dismissal, never a fall-through (`TR-building-ui-060`).
- [ ] **AC (Edge Case 19)**: Given a tool armed, a Selection active, and Build Mode on simultaneously, Then three Esc presses are required to reach WorldNav — never fewer — and no press ever resolves two steps (`TR-building-ui-076`).
- [ ] A press with no applicable chain step (WorldNav, nothing selected, no focus) is a **no-op** (`TR-building-ui-076`).
- [ ] **AC22 / AC36 (partial)**: Given the InputMap at boot, Then `tool_select_1..5`, `tool_select_room/roof/house`, `build_mode_toggle`, `time_pause`, `time_speed_up/down` exist as registered actions — a smoke check, not a registration (`TR-building-ui-065`).
- [ ] **State table**: WorldNav shows only the "Bauen" toggle + time controls (no context panel, no build grid); Build-Mode/Idle shows the toolbar + tool buttons + higher-level tools; ToolArmed shows the armed tool's context panel.

---

## Implementation Notes

*Derived from ADR-0010 §4 and the landed `ToolStateMachine`:*

- **The mode gate is a boolean this system owns and Building System reads.** Expose it the same way `is_hover_suppressing_world_pick()` is exposed (ADR-0010 §2's precedent) — one queryable flag, checked on the NEW-press path alongside hover suppression.
- The landed `ToolStateMachine` is exactly four states (`IDLE`/`TOOL_ARMED`/`DRAGGING`/`SUSPENDED`) and its own doc states the **outer Build Mode gate and the Esc chain's final link are out of scope there** (they belong to `building-001`). This story wraps that machine — it does not modify it. `arm_tool()` never consults a Build Mode flag today; the auto-enter of AC43 is this system's ordering guarantee (set mode, then arm, within one frame, emitting one intent).
- The landed `ToolStateMachine` resolves Suspended-exit to `IDLE` with no tool armed, deliberately. Whether Build **Mode** itself persists across Suspended is not specified there — the GDD's state table implies it does (Selection persists across a Build Mode toggle and across Slice changes; it is UI state, not render state). Restore Build Mode on reactivation, arm nothing.
- Mirror `tool_armed(tool_id)` and `state_changed(old, new)` from `ToolStateMachine` for highlight state — the highlight is a mirror, never a local latch. `state_changed` deliberately does **not** fire on ToolArmed→ToolArmed re-arm; use `tool_armed` for that case (its own doc comment says so). Getting this wrong is exactly how AC17/AC21 fail.
- The Esc chain is a single ordered `match`/`if` ladder with an early return per step. Implement it as one pure function over (has_hud_focus, armed_tool, selection, build_mode) so AC44–46 and Edge Case 19 are testable without a scene.
- Consume Esc via the HUD's own input path so chain step 1 wins before anything else sees it; only an Esc with no HUD focus falls through to world-level handlers (this is the reciprocal clause villager-info-ui's Rule 1 depends on).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003/004: the context panel's *contents* (this story only shows/hides it).
- Story 007: the hover-suppression flag itself and drag-release routing.
- Story 010: what a Selection actually *is* and how a world click produces one — this story only consumes "is a Selection active" for chain step 3.
- Story 015: HUD keyboard focus cycling — this story only honors "does focus exist" for chain step 1.
- Story 017: the higher-level tools' behavior (this story only gates their arming).

---

## QA Test Cases

- **AC1/AC21**: Given a randomized interleaving of 200 mocked `tool_armed`/`state_changed` events, When each is applied, Then exactly one button is highlighted after every single event.
- **AC43**: Given WorldNav, When `tool_select_3` fires, Then within the same frame the mode is Build Mode AND the armed tool is 3; assert no observer ever saw (Build Mode, no tool).
- **AC44/45/46 + Edge Case 19**: Given (focus, tool, selection, mode) = (none, wall, project, on), Then press 1 → tool cleared only; press 2 → selection cleared only; press 3 → WorldNav; press 4 → no-op.
- **Chain step 1**: Given HUD focus held and a tool armed, When Esc fires, Then focus released and the tool is STILL armed.
- **AC22**: Given the InputMap at boot, When each named action is queried, Then `InputMap.has_action` is true for all of them.
- **WorldNav lock**: Given WorldNav and a direct `arm_tool` intent suppressed, Then no tool arms without the mode transition — assert via the emitted intent, not internal state.

---

## Test Evidence

**Story Type**: Logic (state machine) — **BLOCKING** per `.claude/docs/coding-standards.md`.
**Required evidence**: `neues-spiel/tests/unit/ui/build_mode_and_esc_chain_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001 (HUD scaffold); `building-001` (build editor mode — Cluster 0).
- Unlocks: 003, 005, 006, 007, 010, 017.
