# Story 007: Hover-suppression shared gate & drag-release immunity

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/hud.md` (P2 world-pick gate) · `design/ux/villager-panel.md` (Entry & Exit — the reciprocal consumer)
**Requirement**: `TR-building-ui-028`, `TR-building-ui-029`, `TR-building-ui-069`, `TR-building-ui-072`, `TR-villager-info-ui-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 (Cross-System UI/World Input Arbitration) §1–§3
**ADR Decision Summary**: New-click ownership is **structural** — Godot routes `_input()` → GUI `_gui_input()` → `_unhandled_input()`, so a click on an HUD Control with default `mouse_filter = STOP` never reaches Camera & Input at all; TR-camera-input-020's "exactly one owner per click" holds with zero code in Camera & Input. The hover flag is an explicit **redundant safety net** checked only when STARTING a new pick/selection, and it additionally gates **ghost refresh** (hover alone generates no consumable click, so native routing cannot cover that case). An in-progress drag switches its release listening to `_input()` — which fires before any Control consumption — and claims the event via `set_input_as_handled()`, so the release is never swallowed regardless of cursor position.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: ADR-0010 records `godot-specialist` validation (2026-07-11) that propagation order, hover-vs-focus independence, and `set_input_as_handled()` semantics are **accurate for 4.7 and unchanged 4.4→4.7**. Do not re-verify or re-litigate — the ADR is the answer. 4.6's dual-focus system is about **keyboard** focus and is explicitly out of scope for this hover/mouse-routing story (it is story 015's blocker, not this one's).

**Control Manifest Rules (this layer)**:
- Required (Presentation): the hover flag is **one shared gate for EVERY world-pick consumer** — Building System's ghost/placement pick AND Villager Info UI's villager-selection query both honor it. The ghost hiding is one consequence, not the flag's scope.
- Forbidden: a naive whole-zone `mouse_filter = STOP` that swallows an in-progress drag's release; a per-consumer copy of the flag; the HUD interpreting a world click for **placement**.
- Guardrail: hover suppression applies to **starting** picks, never to active drags.

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md` Rule 11 + Edge Cases 5/9, scoped to this story:*

- [ ] `is_hover_suppressing_world_pick() -> bool` exists on the Building UI module as the single queryable gate, updated **event-driven** from each HUD zone's `mouse_entered`/`mouse_exited` and ORed across every zone (Z1–Z7) — never a per-frame mouse-position poll (`TR-building-ui-028`).
- [ ] **AC15**: Given the cursor over any HUD element, Then hover-suppression reports active and the Building ghost hides (`TR-building-ui-028`).
- [ ] Ghost/preview **refresh** is gated by the flag even with no click at all — hover alone stops the preview from updating behind the HUD (ADR-0010 §2's named case).
- [ ] The **same** flag gates Villager Info UI's villager-hit query: a click over the HUD can neither select a villager rendered behind it nor deselect (`TR-villager-info-ui-002`). Assert one flag, two consumers — not two flags.
- [ ] **AC23 (advisory)**: Given a drag begun in the world, When the cursor enters HUD space, Then the drag is **NOT** canceled; When released over the HUD, Then the commit uses the **last valid world preview** — the preview locks when the cursor enters HUD space (Edge Case 5, `TR-building-ui-069`).
- [ ] The HUD never consumes the pointer-release of an in-progress world drag. The mechanism is ADR-0010 §3's `_input()` + `set_input_as_handled()`, owned by `PlacementPick` — this story asserts the HUD's `mouse_filter` configuration does not defeat it (`TR-building-ui-029`).
- [ ] **AC24 (advisory)**: Given a toast dismissal click in a live viewport, Then the click is consumed — nothing beneath receives it (Edge Case 9, `TR-building-ui-072`).
- [ ] A click on any panel's non-interactive area is consumed — no world-pick through the panel (P2; applies to Z4, Z5, Z7 alike).
- [ ] The flag is **false** whenever the HUD is hidden (Suspended) — a hidden HUD suppresses nothing.

---

## Implementation Notes

*Derived from ADR-0010's Decision §1–§3:*

- The landed `PlacementPick` **already implements ADR-0010 §3**: its `_unhandled_input()` handles the press and its `_input()` handles the release (see its class doc comment, "the drag-ownership `_unhandled_input()` press → `_input()` release switch"). This story does **not** re-implement it — it verifies the HUD does not break it.
- Wire `mouse_entered`/`mouse_exited` on each zone's **outer container**, not on every child. The flag is `zone1 or zone2 or ... or zone7`; keep it a single derived boolean, not N booleans consumers must combine.
- `PlacementPick.set_extra_solid()` and its `_process`-driven `update_pick()` are the ghost-refresh path to gate. Gating means "do not call `update_pick()`", not "call it and discard" — the ADR's point is that the pick does not start.
- Expose the flag as a plain method, not a signal. Consumers check it at the moment a NEW press reaches their own handler (the ADR is explicit about where the check lives).
- Landed `CameraInput` listens on `_unhandled_input()` and its `action_fired` passthrough is opaque — nothing there needs changing, per ADR-0010 §1. Confirm by absence of a diff, and say so in the story close.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: the Build Mode gate (a *sibling* condition on the same NEW-press path, ADR-0010 §4).
- Story 010: what a surviving non-placement click resolves **to** (villager vs project Selection).
- Story 008: the always-on hover highlight itself.
- `PlacementPick`'s drag/commit mechanism — already landed (building-020/021).

---

## QA Test Cases

- **AC15**: Given a mocked `mouse_entered` on Z6, Then `is_hover_suppressing_world_pick()` is true and no `update_pick()` call occurs; `mouse_exited`, Then false and picking resumes.
- **Multi-zone OR**: Given `mouse_entered` on Z2 then Z6 then `mouse_exited` on Z2, Then the flag is still true; `mouse_exited` on Z6, Then false.
- **Shared consumer**: Given the flag true, When a villager-selection query is attempted, Then it does not run and the Selection is unchanged (neither select nor deselect).
- **Suspended**: Given the HUD hidden by Suspended, Then the flag is false regardless of the last hover state.
- **AC23 (advisory, live viewport)**: Drag from world into HUD space and release — walkthrough doc must record that the commit occurred and used the locked preview cell.
- **AC24 (advisory, live viewport)**: Click a toast over the toolbar — walkthrough doc must record that the toolbar button beneath did not activate.

---

## Test Evidence

**Story Type**: Integration — the flag/gating half is **BLOCKING**; the two live-viewport ACs (23, 24) are **ADVISORY** per the GDD's own split and `.claude/docs/coding-standards.md`.
**Required evidence (blocking)**: `neues-spiel/tests/unit/ui/hover_suppression_gate_test.gd` — must exist and pass.
**Required evidence (advisory)**: `production/qa/evidence/building-ui-007-drag-over-hud-walkthrough.md`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001, 002.
- Unlocks: 008, 010; **and the villager-info-ui epic's story 002** (its HUD-hover gate consumes this exact flag).
