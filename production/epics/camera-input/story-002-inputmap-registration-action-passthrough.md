# Story 002: InputMap action registration + action_fired passthrough

> **Epic**: Camera & Input
> **Status: Complete (2026-07-23 — 157/157 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/camera-input.md`
**Requirement**: `TR-camera-input-032`, `TR-camera-input-027`, `TR-camera-input-039`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 (Cross-System UI/World Input Arbitration) — primary; ADR-0001 secondary
**ADR Decision Summary**: Camera & Input owns InputMap action definitions but never interprets action names and never branches on device id. Actions are registered at project scope (project.godot); the system reports "action fired" via a signal whose payload is the action name string.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: 4.7 changed mouse/keyboard device IDs from hardcoded `0` to `DEVICE_ID_MOUSE`/`DEVICE_ID_KEYBOARD`, but nothing here branches on device identity — actions route through named InputMap actions and typed event checks only. Do NOT introduce hardcoded device id `0`. Actions are registered in project.godot at project scope, not created in code at runtime.

**Control Manifest Rules (this layer)**:
- Required: owned InputMap actions registered in project.godot at project scope; `action_fired` payload is only the action name string.
- Forbidden: Camera & Input never interprets action names; never branch on device identity; never hardcoded device id `0`.
- Guardrail: the authoritative action list is the union of actions named by downstream GDDs (Building System, Building UI, Villager Info UI).

---

## Acceptance Criteria

- [ ] Every action name any downstream GDD references (`build_place`, `build_remove`, camera actions, UI shortcuts) exists as a registered project-scope action — no consumer ever queries an unregistered action name (AC18). [TR-camera-input-032]
- [ ] When an InputMap action fires, the emitted signal payload contains only the action name string, and the emitting code path contains no branch on that string's value (AC15). [TR-camera-input-027]
- [ ] Nothing branches on input device identity (AC — device-id irrelevance). [TR-camera-input-039]

---

## Implementation Notes

*Derived from ADR-0010 / ADR-0001:*

- Register the union of downstream-referenced actions in `project.godot` at project scope (the input ADR's collected list). Camera & Input emits `action_fired(action_name: StringName)` as an opaque passthrough; consumers (Building System, etc.) interpret.
- The emitting path must have zero `match`/`if` on the action name and zero read of `event.device`. Verify by code review + grep.

---

## Out of Scope

- Story 008: exactly-one-owner-per-click arbitration (this story only emits the passthrough; ownership is 008).
- Consumer interpretation of actions (Building System, later epic).

---

## QA Test Cases

- **AC-1 (all downstream actions registered)**: [TR-camera-input-032]
  - Given: project boot with project.godot loaded
  - When: the InputMap is inspected for every downstream-referenced action name
  - Then: each exists as a registered action; querying any of them does not error
  - Edge cases: an action referenced by a not-yet-built consumer still exists at boot
- **AC-2 (opaque passthrough, no branch)**: [TR-camera-input-027]
  - Given: the Camera & Input source
  - When: an action fires and grep reviews the emit path
  - Then: `action_fired` payload is only the action-name string; no branch on the string; no read of `event.device`
- **AC-3 (no hardcoded device id)**: [TR-camera-input-039]
  - Given: the source
  - When: grep for hardcoded device id `0`
  - Then: zero matches

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/camera_input/inputmap_registration_test.gd` OR documented playtest — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (module exists)
- Unlocks: Story 003, Story 004, Story 005 (input drives motion), Story 008 (arbitration)
