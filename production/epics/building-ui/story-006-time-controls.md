# Story 006: Time controls (pause + 1x/2x/3x)

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/hud.md` (zone Z1, element E3/E11, P7)
**Requirement**: `TR-building-ui-064`, `TR-building-ui-043`, `TR-building-ui-070`, `TR-building-ui-065`, `TR-building-ui-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (Inter-System Reference & DI Pattern)
**ADR Decision Summary**: Autoload-tier modules are called by **global singleton name directly** in method bodies everywhere (`TimeTickSystem.pause()`), never injected — `@export`-ing an Autoload is grep-forbidden. `TimeTickSystem` therefore carries no `class_name` (Godot 4.7 hard-errors when a `class_name` shadows an Autoload) and is reached only via its registered global name.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: `time_pause`, `time_speed_up`, `time_speed_down` are **already registered** in `project.godot` (Space, +, −) and listed in `CameraInput.OWNED_ACTIONS` (verified 2026-07-26). Landed API: `pause() -> void`, `resume() -> void`, `set_warp(int) -> bool`, plus public `paused: bool` / `time_warp: int` fields and `signal time_state_changed(paused, time_warp)`. Default signal connections are **synchronous** — that is what makes the re-read pattern below correct.

**Control Manifest Rules (this layer)**:
- Required (Presentation): the time controls' display is written **exclusively from the authoritative state observed at the synchronous call**, never from a UI-local latch. State signals are consumed only for changes this HUD did not initiate, and a signal must never overwrite a newer observed state.
- Forbidden: `SceneTree.paused` and `Engine.time_scale` (project-wide Forbidden Patterns — pause and warp are owned by Time & Tick); the HUD computing time itself.
- Guardrail: pause state and warp state are **independent** — a warp change survives a pause and a pause survives a warp change, in both directions.

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md` Rules 1/2/10 + Edge Cases 7/12, scoped to this story:*

- [ ] **AC13** *(restated per Known Conflict 7)*: Given Space pressed, Then `TimeTickSystem`'s pause toggle is called and the control reflects the **authoritative state re-read immediately after that synchronous call** — never a UI-local pause. `pause()`/`resume()` return `void`; the authoritative values are the public `paused`/`time_warp` fields, and the re-read is equivalent because emission is synchronous (`TR-building-ui-064`).
- [ ] **AC14**: Given paused at stored 2x, When `+` fires, Then the **stored** speed changes without unpausing, and the control shows **both facts** — paused AND the pending speed (Edge Case 7, `TR-building-ui-070`).
- [ ] **AC (Edge Case 12)**: Given two Space presses faster than one mirrored update, Then the control shows Time & Tick's authoritative state after the second call; a queued state **signal** from press 1 can never overwrite press 2's newer observed state (`TR-building-ui-043`).
- [ ] The speed control is radio-style with the current state **always visible**, and clicking 1x/2x/3x directly is equivalent to cycling with `+`/`−` (Rule 10).
- [ ] An out-of-range warp is rejected by `set_warp()` returning `false` with no state change — the control must not render a speed the system rejected.
- [ ] The paused state is **visually unmistakable**: the pause icon state in Z1 **plus** the full-screen world dim/desaturation treatment (hud.md E11, Dynamic Behavior 4). Exact dim strength is an Art Bible §7 delegation; the behavior (instant, full HUD usability) is fixed here.
- [ ] The entire HUD stays fully usable while paused — building, selection and dismissal all work on a paused frame (`TR-building-ui-005`, hud.md Dynamic Behavior 4).
- [ ] **AC22 (partial)**: Given the InputMap at boot, Then `time_pause`, `time_speed_up`, `time_speed_down` exist as registered actions (`TR-building-ui-065`).
- [ ] Z1 is the only permanently-visible top-right element and the only global (non-build) HUD element in MVP — it renders identically in WorldNav and Build Mode (Rule 1, hud.md "two quiet permanent elements").
- [ ] A grep over the UI module returns **zero** matches for `SceneTree.paused`, `get_tree().paused`, and `Engine.time_scale`.

---

## Implementation Notes

*Derived from Rule 2's returned-state-only writer clause and the landed `TimeTickSystem`:*

- **The single writer rule is the whole story.** Implement one private `_apply_observed_time_state(paused, warp)` and give it exactly two callers: (a) immediately after any `pause()`/`resume()`/`set_warp()` call this HUD makes, reading `TimeTickSystem.paused`/`.time_warp`; (b) `time_state_changed`, but **only when this HUD did not initiate the change**. Guard (b) with a re-entrancy flag set around the HUD's own calls — otherwise the synchronous emission from (a)'s call re-enters and the "no stale writer" property becomes accidental rather than structural.
- `pause()`/`resume()` are **idempotent** — an already-paused `pause()` is a no-op with no duplicate emission. `set_warp()` likewise returns `true` for a valid value whether or not anything changed. So the toggle must branch on the current authoritative value, not blindly call one of the two.
- The valid warp set is `TimeTickConfig.time_warp_options`, not a hardcoded `[1,2,3]`. Build the radio from that list so a config change cannot desync the control.
- The pause dim is a full-screen `Control`/`CanvasLayer` overlay that must **not** consume input (the HUD stays fully usable while paused) and must sit below the HUD zones in draw order.
- This story resolves `design/gdd/time-tick-system.md` Core Rule 2's open UI-trigger question ("Building UI/HUD"). Note the resolution in that GDD's cross-reference at close.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: Z1's anchoring and the Suspended hide (this story only fills the zone).
- Story 013/014: toast timers' pause-immunity — a separate concern with the same "wall-clock" wording.
- Any change to `TimeTickSystem` itself. If the returned-state wording proves insufficient in review, escalate per Known Conflict 7 rather than adding a return value here.

---

## QA Test Cases

- **AC13**: Given a mocked Time & Tick at `paused = false`, When the pause action fires, Then `pause()` was called exactly once and the rendered state equals the mock's post-call `paused` value — assert the render reads the mock, not a local bool.
- **AC14**: Given `paused = true, time_warp = 2`, When `time_speed_up` fires, Then `set_warp(3)` was called, `paused` is still true, and the control renders both "paused" and "3x".
- **Edge Case 12**: Given two pause actions in one frame with a deferred `time_state_changed` carrying press-1's state, When both resolve, Then the final render equals press-2's observed state — the stale signal is discarded.
- **Rejected warp**: Given `set_warp` mocked to return `false`, Then the control's rendered speed is unchanged.
- **Independence**: Given warp 3 then pause then resume, Then warp is still 3 — never reset to 1.
- **Forbidden-pattern grep**: Given the UI module source, When grepped, Then zero `SceneTree.paused` / `get_tree().paused` / `Engine.time_scale`.

---

## Test Evidence

**Story Type**: Logic (state mirror with a writer-precedence rule) — **BLOCKING**.
**Required evidence**: `neues-spiel/tests/unit/ui/time_controls_test.gd` — must exist and pass.
**Also**: `production/qa/evidence/building-ui-006-pause-treatment.md` (ADVISORY) — paused-vs-running screenshot pair for the dim treatment.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001 (Z1 zone + raw-delta host).
- Unlocks: —
