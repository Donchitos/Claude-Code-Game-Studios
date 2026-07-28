# Story 003: Orbit rotation — middle-mouse drag + Q/E, pitch clamp

> **Epic**: Camera & Input
> **Status: Complete (2026-07-23 — 266/266 suite green, parent-verified; windowed feel-check ADVISORY deferred to first rendered world, vox-007)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/camera-input.md`
**Requirement**: `TR-camera-input-022`, `TR-camera-input-023`, `TR-camera-input-040`, `TR-camera-input-030`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (config-driven tunables) — primary
**ADR Decision Summary**: Rotation reads `mouse_drag_sensitivity` and `q_e_rotate_step` from config; pitch is clamped to the fixed pole-safety bounds. All camera motion runs on raw engine delta, never Time & Tick's `game_delta`.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Camera motion uses RAW engine delta (raw-delta contract) — camera feel is identical at 1x/2x/3x warp and while paused. Pitch clamp prevents pole degeneration.

**Control Manifest Rules (this layer)**:
- Required: rotation tunables from config; pitch clamp silent at bounds; raw-delta for camera motion.
- Forbidden: `game_delta` for camera feel; hardcoded sensitivity/step; `MOUSE_MODE_CAPTURED` during drags (cursor stays visible/free).
- Guardrail: rotate latency ~16ms (1 frame), 1:1 feel.

---

## Acceptance Criteria

- [ ] Middle-mouse horizontal drag changes yaw proportional to `mouse_drag_sensitivity`; vertical drag changes pitch, clamped to `[pitch_min, pitch_max]` (AC2). [TR-camera-input-022]
- [ ] Q/E rotate yaw by ±`q_e_rotate_step` per press (AC3). [TR-camera-input-023]
- [ ] Pitch pushed beyond bounds clamps silently, no error (AC8). [TR-camera-input-040]
- [ ] Rotation is driven by raw engine delta, not `game_delta` (AC — raw-delta contract). [TR-camera-input-030]

---

## Implementation Notes

*Derived from ADR-0002:*

- Middle-mouse-drag: yaw += horizontal_delta * `mouse_drag_sensitivity`; pitch += vertical_delta * `mouse_drag_sensitivity`, then `clamp(pitch, pitch_min, pitch_max)`. Q/E: yaw ±= `q_e_rotate_step` per press.
- Never set `MOUSE_MODE_CAPTURED` during drags. Drive on raw delta.
- The rotate-drag cursor icon (TR-camera-input-045) is out of scope pending the art-director's cursor asset (GDD Open Question 1) — flagged, not implemented here.

---

## Out of Scope

- Story 004 (zoom), Story 005 (pan), Story 007 (Suspended state freezing rotation).
- Rotate-drag cursor icon asset (art-director OQ1).

---

## QA Test Cases

- **AC-1 (drag rotation)**: [TR-camera-input-022]
  - Given: `mouse_drag_sensitivity = 0.008`
  - When: a horizontal drag of D pixels, then a vertical drag of D pixels
  - Then: yaw changes by D*0.008; pitch changes by D*0.008 clamped to [0.15,1.5]
  - Edge cases: a vertical drag that would exceed a pitch bound clamps silently
- **AC-2 (Q/E step)**: [TR-camera-input-023]
  - Given: `q_e_rotate_step = 0.12`
  - When: Q then E pressed
  - Then: yaw −0.12 then +0.12 (net 0)
- **AC-3 (raw-delta)**: [TR-camera-input-030]
  - Given: time-warp at 3x and pause toggled
  - When: rotation is applied
  - Then: rotation magnitude per frame is unaffected by warp/pause (uses raw delta)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/camera_input/orbit_rotation_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (config + derivation), Story 002 (input actions)
- Unlocks: Story 007 (Suspended freezes rotation), Story 009 (raw-delta/pause verification)
