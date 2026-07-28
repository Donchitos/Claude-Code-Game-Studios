# Story 008: Exactly-one-owner-per-click arbitration

> **Epic**: Camera & Input
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/camera-input.md`
**Requirement**: `TR-camera-input-020`, `TR-camera-input-027`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 (Cross-System UI/World Input Arbitration) — primary
**ADR Decision Summary**: New-click ownership via native propagation — HUD Controls keep default `mouse_filter = STOP`; world systems listen in `_unhandled_input()`; Camera & Input needs zero new arbitration code and never emits a world action for a UI-consumed click. A drag validly begun in `_unhandled_input()` switches release-listening to `_input()` for the drag, then reverts.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Input routing order is `_input()` → `_gui_input()` → `_unhandled_input()`; `set_input_as_handled()` from `_input()` stops later stages. This ordering is load-bearing for exactly-one-owner. A click consumed by a HUD Control never reaches `_unhandled_input()`, so no world action fires.

**Control Manifest Rules (this layer)**:
- Required: new-click ownership via native propagation (HUD `mouse_filter = STOP`, world systems in `_unhandled_input()`); drag switches to `_input()` for the drag window then reverts, calling `set_input_as_handled()` on release.
- Forbidden: Camera & Input emitting a world action for a UI-consumed click; restructuring `mouse_filter` geometry to solve drag-release.
- Guardrail: `_input()` is actively listened to only during an in-progress drag window.

---

## Acceptance Criteria

- [ ] When a mouse click is consumed by a UI element, Camera & Input does NOT also emit the corresponding world-action signal for that same click — exactly one owner per click (AC19). [TR-camera-input-020]
- [ ] Camera & Input never interprets action names in the arbitration path — it only reports the passthrough (AC15). [TR-camera-input-027]

---

## Implementation Notes

*Derived from ADR-0010:*

- Rely on native propagation: world-action emission happens in `_unhandled_input()`, so a HUD Control with `mouse_filter = STOP` consuming the click prevents the world action by construction — Camera & Input adds zero arbitration code.
- Drag ownership: a drag begun in `_unhandled_input()` calls `set_process_input(true)` to listen for release in `_input()` for the drag's duration; on release, immediately `get_viewport().set_input_as_handled()` then revert to `_unhandled_input()`-only.
- Testable in isolation with a stub `Control` (`mouse_filter = STOP`) standing in for the not-yet-built Building UI / Villager Info UI HUD zones.

---

## Out of Scope

- Building UI / Villager Info UI's own hover-suppression flag and Selection routing (later epics; ADR-0010 Decision §4).
- Consumer interpretation of the passthrough action.

---

## QA Test Cases

- **AC-1 (UI-consumed click fires no world action)**: [TR-camera-input-020]
  - Given: a stub HUD Control with `mouse_filter = STOP` over the cursor
  - When: a click lands on the Control
  - Then: the click is consumed by `_gui_input`; `_unhandled_input()` never sees it; no world action is emitted
  - Edge cases: a click on empty (non-HUD) space DOES reach `_unhandled_input()` and emits the world action (exactly one owner, the world)
- **AC-2 (drag release ownership)**: [TR-camera-input-020]
  - Given: a drag begun in `_unhandled_input()`
  - When: the release lands on a widget
  - Then: `_input()` claims the release and calls `set_input_as_handled()`; listening reverts to `_unhandled_input()` after
- **AC-3 (no name interpretation)**: [TR-camera-input-027]
  - Given: the arbitration source
  - When: grep the path
  - Then: no branch on action-name string in Camera & Input

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/camera_input/exactly_one_owner_click_test.gd` OR documented playtest — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (action passthrough), Story 006 (world-ray for world clicks)
- Unlocks: Building UI / Villager Info UI click routing (later epics)
