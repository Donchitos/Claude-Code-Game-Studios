# Story 009: Raw-delta + pause contract (camera fully controllable while paused)

> **Epic**: Camera & Input
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/camera-input.md`
**Requirement**: `TR-camera-input-030`, `TR-camera-input-031`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (config/tier) — primary; Time & Tick relationship (raw vs `game_delta`)
**ADR Decision Summary**: All camera motion (rotate, zoom, pan) is driven by RAW engine delta, never Time & Tick's `game_delta` — camera feel is identical at 1x/2x/3x warp. Game pause does NOT suspend Camera & Input — the camera stays fully controllable and input dispatch continues while paused, so the player can inspect the village and queue plans. Suspended (scene transition) and Pause are independent; neither implies the other.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Never use `SceneTree.paused` or `Engine.time_scale` (project-wide forbidden — they would freeze the camera/UI that must run on raw delta). Pause is owned by Time & Tick (`game_delta = 0`); the camera reads raw engine delta directly.

**Control Manifest Rules (this layer)**:
- Required: camera/UI/overlays run on raw engine delta; camera fully controllable while game-paused; Suspended ≠ Pause.
- Forbidden: `SceneTree.paused`, `Engine.time_scale`; blending raw delta and `game_delta` for one piece of state.
- Guardrail: camera feel identical at 1x/2x/3x warp and while paused.

---

## Acceptance Criteria

- [ ] All camera motion is driven by raw engine delta; feel is identical at 1x/2x/3x warp (AC — raw-delta contract). [TR-camera-input-030]
- [ ] Game pause does NOT suspend Camera & Input — camera stays controllable and input dispatch continues while paused; Suspended and Pause are independent (AC — pause contract). [TR-camera-input-031]

---

## Implementation Notes

*Derived from GDD Rules 9/10 + Time & Tick relationship:*

- Verify every motion path (rotate/zoom/pan, Stories 003–005) reads the raw engine `delta` (`_process`/`_physics_process` raw delta), never Time & Tick's `game_delta`. This story is the consolidated verification + guard that no motion path accidentally consumes `game_delta`.
- Assert that toggling game pause (Time & Tick `game_delta = 0`) leaves the camera fully controllable and dispatching input — pause only affects simulation, not camera. Confirm `SceneTree.paused`/`Engine.time_scale` are never touched (grep-clean).

**Story-level note — pause-menu.md camera-halt trigger (OQ3, M02 scope):** the Pause Menu (M02+) is the ONE place where pause ≠ "camera still interactive" — it will require a distinct, Pause-Menu-driven input-halt trigger on Camera & Input (see Story 007's note and `design/ux/pause-menu.md` World Freeze §2). That trigger is NOT this contract and NOT in M01: this story implements the ORDINARY game-pause behavior (camera stays live), which the Pause Menu deliberately diverges from later.

---

## Out of Scope

- The Pause-Menu-driven halt trigger (M02 — see note; Story 007 also flags it).
- Time & Tick's own pause/warp implementation (separate system).

---

## QA Test Cases

- **AC-1 (raw-delta invariance)**: [TR-camera-input-030]
  - Given: camera motion under warp 1x, 2x, 3x
  - When: an identical input sequence is applied at each warp
  - Then: per-frame camera motion magnitude is identical across warps (uses raw delta); grep confirms no `game_delta` in motion paths
- **AC-2 (controllable while paused)**: [TR-camera-input-031]
  - Given: game paused (`game_delta = 0`)
  - When: the player rotates/zooms/pans
  - Then: the camera moves normally and input still dispatches; pausing/unpausing does not enter Suspended
  - Edge cases: paused AND a scene transition begins → Suspended applies independently of pause; on resume both states restore correctly
- **AC-3 (forbidden APIs untouched)**: [TR-camera-input-031]
  - Given: the source
  - When: grep `SceneTree.paused|Engine.time_scale`
  - Then: zero matches

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/camera_input/raw_delta_pause_contract_test.gd` OR documented playtest — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003, Story 004, Story 005 (motion paths to verify), Story 007 (Suspended, to prove independence from Pause)
- Unlocks: integrated build (camera usable while paused for inspection/queuing)
