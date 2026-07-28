# Story 013: Camera hosting — the shipped game has no camera

> **Epic**: Camera & Input
> **Status**: Complete (2026-07-27 — 1493/1493 suite green, 0 orphans, parent-verified; live scene tree now reports 'Camera3D nodes hosted by the shipped Valley: 1')
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-27

## Context

**GDD**: `design/gdd/camera-input.md`
**ADR Governing Implementation**: ADR-0010 (Cross-System UI/World Input Arbitration) — primary;
ADR-0001 (DI), ADR-0005 (boot sequencing) also apply.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM

### How this was found

Not by a test — by running the game and counting. `tools/settlement_overview_capture.gd`
walks the live scene tree after the real boot gate reaches ACTIVE and reports:

```
settlement_overview_capture: REPORT — Camera3D nodes hosted by the shipped Valley: 0
```

Every piece of camera behaviour exists and is covered: `CameraInput` is hosted in
`Valley.tscn`, its orbit/pan/zoom math is tested, `PlacementPick` consumes its ray
origin and direction. What does not exist anywhere in the production scene chain is
a `Camera3D`. `camera_input.gd`'s own class doc states this plainly — "This class has
never held a live Camera3D … the real driven Camera3D lives in a SEPARATE node/scene
that mirrors it" — and points at `tools/camera_sandbox.gd`, a tool scene.

The consequence: a human launching `game_world.tscn` today sees nothing at all. The
world generates, villagers spawn and wander, the build chain is hosted (scene-007) —
and none of it is rendered to any viewport.

This is the sixth instance of the same failure mode this project has hit: code that
is green-tested and never called by the running game (world generation, roster spawn,
need initialisation, the furniture registry, the build-tool chain — and now the
camera). It is the most visible one, because it is the difference between a game a
person can look at and one they cannot.

---

## Acceptance Criteria

- [x] AC1: The shipped scene chain (`game_world.tscn` → `Valley.tscn`) hosts exactly one
      `Camera3D`, and it is `current` once boot reaches ACTIVE.
- [x] AC2: That camera's transform is driven every frame from the hosted `CameraInput`'s
      own `get_camera_position()` / `get_target()` — the camera mirrors the module, the
      module never reads back from the camera (no ordering hazard; this is exactly the
      relationship `camera_input.gd`'s class doc already specifies and `camera_sandbox.gd`
      already implements).
- [x] AC3: `CameraInput` is not modified to hold a camera. The mirroring lives in the
      hosting layer, so the "why no live Camera3D" rationale in its class doc stays true.
- [x] AC4: On boot the camera is framed on the starting roster's actual location, not on
      the world origin — a player must see their settlement without touching the mouse.
- [x] AC5: Input arbitration is unchanged (ADR-0010): the camera consumes only what
      `CameraInput` already owns; no new `_input`/`_unhandled_input` handler is introduced
      outside it.
- [x] AC6: A boot-invariant assertion is added to Valley's existing block: exactly one
      `Camera3D` is hosted and current after boot. This is the anti-regression lever —
      the invariant that would have caught this in the first place.

## Anti-Vacuity Lever

A test asserting "a camera exists" passes trivially once anyone adds a camera node.
The load-bearing assertion is AC2 + AC4 together: after boot, the hosted camera's
`global_position` must equal the value `CameraInput.get_camera_position()` reports, and
that position must be within the roster's neighbourhood rather than at the origin. On
today's build there is no camera at all, so this cannot pass vacuously; after a naive
"drop a Camera3D into the scene" fix it still fails, because an undriven camera sits
wherever the scene file put it.

## Out of Scope

- Camera feel/tuning changes — the values in `CameraInputConfig` are not touched here.
- Any HUD or UI hosting (`building-ui-001` is separately blocked on the TD ruling).
- Retiring `tools/camera_sandbox.gd`; it remains the windowed feel-check harness.

## QA Test Cases

**AC1/AC6 — exactly one current camera after boot**
- Given: the real `game_world.tscn` booted to ACTIVE.
- Then: exactly one `Camera3D` in the tree below Valley, and it is `current`.

**AC2 — the camera mirrors CameraInput, and only in that direction**
- Given: boot complete; `CameraInput` driven to a known orbit/zoom state.
- Then: the camera's transform equals `get_camera_position()` looking at `get_target()`.
- And: mutating the camera's transform directly leaves `CameraInput`'s reported state
  unchanged (proves the dependency is one-way).

**AC4 — the player sees the settlement, not the origin**
- Given: boot complete, starting roster spawned near world centre.
- Then: the camera's target is within the roster's neighbourhood, not at (0, 0, 0).
