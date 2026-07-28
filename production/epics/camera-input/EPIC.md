# Epic: Camera & Input

> **Layer**: Foundation
> **GDD**: design/gdd/camera-input.md
> **Architecture Module**: Camera & Input (camera position derivation; all InputMap action registration/ownership; world-ray query API; Active/Suspended state)
> **Manifest Version**: 2026-07-23
> **Status**: Ready
> **Stories**: 9 stories created

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Camera config + spherical position derivation | Logic | Ready | ADR-0002 |
| 002 | InputMap action registration + action_fired passthrough | Integration | Ready | ADR-0010 |
| 003 | Orbit rotation — mmb drag + Q/E, pitch clamp | Logic | Ready | ADR-0002 |
| 004 | Zoom — multiplicative, clamped, rapid-safe | Logic | Ready | ADR-0002 |
| 005 | WASD pan — yaw-relative, distance-scaled, bound + delta clamp | Logic | Ready | ADR-0002 |
| 006 | Mouse world-ray API + ground-plane intersection | Logic | Ready | ADR-0004 |
| 007 | Active/Suspended state machine (exact-state restore) | Integration | Ready | ADR-0010 |
| 008 | Exactly-one-owner-per-click arbitration | Integration | Ready | ADR-0010 |
| 009 | Raw-delta + pause contract (controllable while paused) | Integration | Ready | ADR-0002 |

## Overview

Camera & Input owns the raw input pipeline (InputMap actions, mouse/keyboard
events) and the single free-orbit camera through which the player views the
valley. It exposes `action_fired(name)` as an opaque passthrough (it never
interprets action names or branches on device id), `get_world_ray()` (always
computable, even Suspended), and `get_ground_plane_intersection()`. It guarantees
exactly-one-owner-per-click: if a Control consumed the click, no world-action
fires. It enters Suspended on Scene/World Management's transition signals. Mouse-
driven placement is the project's core interaction, so its ray API is consumed by
Building System's DDA pick and Villager Info UI's villager hit-test.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0010: Cross-System UI/World Input Arbitration | New-click ownership via native propagation (HUD Controls `mouse_filter = STOP`, world systems in `_unhandled_input()`); drag-release switches to `_input()` for the drag window; Camera & Input needs zero new arbitration code and never emits a world action for a UI-consumed click | MEDIUM |
| ADR-0004: Physics Backend & Picking Strategy | `get_world_ray()` drives both the DDA block pick and the villager `Area3D` `intersect_ray` (with `collide_with_areas=true`) — Camera & Input owns the ray, not the pick semantics | HIGH (shared) |
| ADR-0002 / ADR-0001 | Camera/input tunables from typed `.tres` config; injected-tier module | MEDIUM |

Engine-risk basis (4.7 policy): **MEDIUM**. Input is a flagged HIGH-risk domain
(4.7 changed mouse/keyboard device IDs from hardcoded `0` to `DEVICE_ID_MOUSE`/
`DEVICE_ID_KEYBOARD`), but the design already avoids the risk by never branching
on device id — reducing the practical risk to MEDIUM. Still verify against
`docs/engine-reference/godot/`: `Camera3D.project_ray_origin/project_ray_normal`
must be re-confirmed for 4.7, and the input routing order
(`_input` → `_gui_input` → `_unhandled_input`) is load-bearing for
exactly-one-owner. Do not introduce hardcoded device id `0`.

## GDD Requirements

32 TRs registered (`TR-camera-input-*`). Coverage:

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-camera-input-020 | Exactly-one-owner-per-click; no world action on UI-consumed click | ADR-0010 ✅ |
| TR-camera-input-019 | All camera/input tunables from config | ADR-0002 ✅ |
| (world-ray API) | `get_world_ray()` always computable, drives DDA + villager pick | ADR-0004 ✅ |

**Coverage summary**: All ADR-worthy TRs trace to Accepted ADRs; remaining TRs
are GDD-specified (camera derivation, orbit bounds, Suspended behavior). No
untraced requirements.

**At-risk / deferred**: `project_ray_*` 4.7 signature re-verification is a
MEDIUM-risk API check, not an open decision. No VS-tier deferral.

## Milestone 01 Notes

- No tech-debt or CD-protected item lands here.
- M01 scope = full camera + InputMap + `world_ray()` + Active/Suspended, as a
  Foundation system that runs in the integrated scene and feeds Building System's
  placement pick.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/camera-input.md` are verified
- A test proves exactly-one-owner-per-click and always-computable `get_world_ray()`
- Logic/Integration stories have passing test files in `tests/`

## Next Step

Run `/create-stories camera-input` to break this epic into implementable stories.
