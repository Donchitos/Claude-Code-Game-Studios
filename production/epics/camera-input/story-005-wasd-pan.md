# Story 005: WASD pan — yaw-relative, distance-scaled, bound + delta clamp

> **Epic**: Camera & Input
> **Status: Complete (2026-07-24 — 370/370 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/camera-input.md`
**Requirement**: `TR-camera-input-025`, `TR-camera-input-026`, `TR-camera-input-043`, `TR-camera-input-049`, `TR-camera-input-030`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (config-driven tunables) — primary
**ADR Decision Summary**: WASD pans the orbit target along the ground plane, direction relative to current camera yaw, scaled by delta-time and current distance; the target is clamped to the Voxel World's horizontal bounds (plus a small margin, default 0). Delta-time is clamped to `max_delta_time` first.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Pan uses raw engine delta, clamped to `max_delta_time` to prevent a huge jump after a hitch. The world-bound clamp reads Voxel World's `world_width_cells`/`world_depth_cells * cell_size`; margin 0 is a valid configuration. Camera & Input reads those bounds as config values (no direct Voxel World call).

**Control Manifest Rules (this layer)**:
- Required: pan tunables from config; delta clamped to `max_delta_time`; target clamped to world bounds; raw-delta.
- Forbidden: `game_delta` for pan; blocking input at a bound (input still registers, just yields zero delta); screen-edge panning (deliberately excluded at MVP).
- Guardrail: pan latency ~16ms; margin 0 valid.

---

## Acceptance Criteria

- [ ] WASD moves the target in the yaw-rotated input direction, scaled by delta-time and current distance (AC6). [TR-camera-input-025]
- [ ] At a world bound, further outward WASD yields zero delta in that direction with no error; input is not blocked (AC7). [TR-camera-input-026]
- [ ] Delta-time is clamped to `max_delta_time` before the pan formula (AC13). [TR-camera-input-043]
- [ ] Margin 0 (default) is valid: hard against a world edge the clamp still yields zero further delta, no error (AC20). [TR-camera-input-049]
- [ ] Pan is driven by raw engine delta (AC — raw-delta contract). [TR-camera-input-030]

---

## Implementation Notes

*Derived from ADR-0002:*

- `target = clamp_to_bounds(target + input_dir.normalized().rotated(UP, yaw) * delta * distance * pan_speed_factor)`, where `delta = clamp(raw_delta, 0, max_delta_time)`. Bounds = `[0, world_width_cells*cell_size] × [0, world_depth_cells*cell_size]` (+ margin, default 0). Camera reads world bounds from config, never calls Voxel World.
- At a bound the clamp produces zero delta in that axis; input still processes (no exception, no block).

---

## Out of Scope

- Story 007 (Suspended freezes pan), Story 009 (raw-delta/pause verification suite).
- Voxel World's actual bounds source (Camera reads them as config values).

---

## QA Test Cases

- **AC-1 (yaw-relative distance-scaled pan)**: [TR-camera-input-025]
  - Given: yaw=0, distance=18, `pan_speed_factor=0.7`, W held
  - When: pan runs for a clamped delta
  - Then: target moves "forward relative to view", magnitude ∝ delta*distance*0.7; panning is faster when zoomed out (larger distance)
- **AC-2 (bound clamp, no block)**: [TR-camera-input-026, -049]
  - Given: target at the world edge, margin 0
  - When: WASD keeps pushing outward
  - Then: zero further delta in that direction, no error raised, input still registers
- **AC-3 (delta clamp)**: [TR-camera-input-043]
  - Given: a very large raw_delta (post-hitch)
  - When: pan runs
  - Then: delta is clamped to `max_delta_time` first — no huge camera jump
- **AC-4 (raw-delta)**: [TR-camera-input-030]
  - Given: warp 3x / paused
  - When: pan applied
  - Then: pan magnitude per frame unaffected by warp/pause

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/camera_input/wasd_pan_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (config + derivation), Story 002 (input actions)
- Unlocks: Story 007 (Suspended freezes pan), Story 009 (raw-delta/pause contract)
