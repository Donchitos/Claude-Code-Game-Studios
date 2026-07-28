# Story 003: Transition-signal contract surface + transition state machine

> **Epic**: Scene/World Management
> **Status**: Complete (2026-07-24 — 276/276 suite green)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-24

## Context

**GDD**: `design/gdd/scene-world-management.md` (Core Rule 6 & 7 three-signal contract, States table, Interactions with Camera & Input)
**Requirement**: `TR-scene-world-management-010`, `TR-scene-world-management-043`, `TR-scene-world-management-044`, `TR-scene-world-management-045`, `TR-scene-world-management-047`, `TR-scene-world-management-048`, `TR-scene-world-management-049`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time.)*

**ADR Governing Implementation**: ADR-0001: Inter-System Reference & DI Pattern (primary — the signal contract is Scene/World Management's public surface, consumed by injected-tier peers); ADR-0013 (secondary, VS-tier — the multi-scene transitions these signals will eventually drive); ADR-0012 (secondary, VS-tier — savepoint binds to `transition_ended(success=true)`)
**ADR Decision Summary**: Scene/World Management exposes `transition_begun()` / `transition_ended(success)` and `get_transition_state()` (Booting | Active | Transitioning). Exactly one of complete/abort fires per begin, exactly once. Camera & Input enters Suspended on begin and exits on complete OR abort. At MVP only the boot→Active path is exercised; actual dungeon entry/exit transitions are VS-tier.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: default signal connections are **synchronous** (in the `emit()` call stack, connection order). `_input`/`_unhandled_input` are dispatched SceneTree-global (relevant when the VS-tier multi-scene transitions land, not at MVP). Cross-reference `docs/engine-reference/godot/`. Do not use `SceneTree.paused`/`Engine.time_scale` (project-wide forbidden) — transitions run on raw delta.

**Control Manifest Rules (Foundation + Presentation):**
- Required (Foundation): injected-tier module; the transition signals are the public contract peers bind to (`transition_begun`/`transition_ended` — Camera & Input Suspended entry/exit, Building System undo-clear on COMPLETE only, per Data Flow §2 event path).
- Forbidden: `change_scene_to_file`/`current_scene` for handoff; `SceneTree.paused`/`Engine.time_scale` for pause/warp.
- Guardrail: signals are event-driven; exactly one of complete/abort per begin.

---

## Acceptance Criteria

*From `design/gdd/scene-world-management.md`, scoped to this story (MVP contract surface; dungeon-transition ACs are VS+ and deferred):*

- [ ] The public surface exists: `signal transition_begun()`, `signal transition_ended(success: bool)`, and `get_transition_state() -> TransitionState` with `TransitionState = { Booting, Active, Transitioning }`.
- [ ] The one-begin → exactly-one-of-complete/abort invariant is enforced structurally (Core Rule 7): a begin is always followed by exactly one `transition_ended` (success true or false), exactly once.
- [ ] Boot resolves the state to `Active` after the gate completes (story 002), so peers can observe a stable post-boot state; `Booting` is reported until then.
- [ ] Camera & Input's Suspended contract is bindable: entering Suspended on `transition_begun` and exiting on `transition_ended` (either outcome) is wired via the signals only — no direct call coupling (TR-scene-world-management-049: all effects reach consumers via signals).
- [ ] The signals carry no scene-specific payload beyond `success` (opaque contract — consumers bind by effect class, not by transition identity).

---

## Implementation Notes

*Derived from GDD Core Rule 7 (three-signal contract) + Data Flow §2 event path:*

- This is the **contract surface** the Milestone-01 build needs so Foundation systems "run together in one scene" and Camera & Input has a signal to bind Suspended to. At MVP there is **no actual dungeon transition** — the begin/complete/abort machinery is built as the durable contract, but only the boot→Active path is exercised.
- Defer to VS-tier (do NOT build in M01): dungeon entry/exit transitions (AC3–6), the load-failure abort path (AC8), the double-trigger debounce (AC7, Logic/VS+), the transition overlay animation + cues (AC20), savepoint binding (ADR-0012), and all multi-scene topology (ADR-0013). Build the signal/state *surface* and the one-begin→one-end invariant so those VS stories slot in without changing the contract.
- Keep the invariant testable in isolation: a unit/integration test can drive a synthetic begin→end cycle and assert exactly-one-end, without any real scene load.
- Building System's undo-clear-on-COMPLETE and Camera & Input's Suspended are *consumers* — their reactions live in their own epics; this story only guarantees the signals fire correctly and are bindable.

---

## Out of Scope

*Handled by neighbouring stories / other epics — do not implement here:*

- Actual dungeon entry/exit transitions, the abort/load-failure path, the debounce, transition overlay visuals/cues — all VS-tier (Milestone 02+).
- Savepoint binding to `transition_ended(success=true)` (ADR-0012) — VS-tier.
- Multi-scene topology (ADR-0013 offset / per-scene toggles) — VS-tier.
- Camera & Input's Suspended *reaction* and Building System's undo-clear *reaction* — their own epics (this story provides the signals they bind to).
- Story 001/002: World Root topology and the boot gate.

---

## QA Test Cases

*Automated test specs — the developer implements against these:*

- **AC (public surface exists)**:
  - Given: the Scene/World Management module.
  - When: its API is inspected.
  - Then: `transition_begun`, `transition_ended(success: bool)`, and `get_transition_state()` returning a `TransitionState` enum value are all present.
  - Edge cases: `get_transition_state()` returns `Booting` before the gate completes and `Active` after.

- **AC (one-begin → exactly-one-end invariant)**:
  - Given: a synthetic transition begun.
  - When: the transition resolves (success or failure driven in the test).
  - Then: exactly one `transition_ended` fires, exactly once, with the correct `success` value.
  - Edge cases: a second resolve attempt on the same begin does not fire a second `transition_ended`.

- **AC (Camera-Suspended bindable via signals)**:
  - Given: a listener bound to `transition_begun`/`transition_ended` (standing in for Camera & Input).
  - When: a synthetic begin then end is driven.
  - Then: the listener observes Suspended-entry on begin and Suspended-exit on the end signal (either outcome), with no direct method call from Scene/World Management.
  - Edge cases: end with `success=false` still fires the exit binding (abort must never strand a consumer in Suspended).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration test at `neues-spiel/tests/integration/scene_world_management/transition_contract_surface_test.gd` — must exist and pass headless (surface presence + one-begin→one-end invariant + signal-driven Suspended binding).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (boot gate integration — the state resolves to Active after boot) DONE.
- Unlocks: VS-tier dungeon-transition stories (Milestone 02+); Camera & Input's Suspended binding and Building System's undo-clear consumers (their own epics bind to this contract).
