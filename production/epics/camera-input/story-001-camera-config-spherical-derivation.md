# Story 001: Camera config + spherical position derivation

> **Epic**: Camera & Input
> **Status: Complete (2026-07-23 — 69/69 suite green, parent-verified; GDD worked-example digit slip flagged, exact formula asserted)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/camera-input.md`
**Requirement**: `TR-camera-input-021`, `TR-camera-input-037`, `TR-camera-input-019`, `TR-camera-input-048`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (Tuning/Config Data Strategy) — primary; ADR-0001 (DI) secondary
**ADR Decision Summary**: One `Resource`-derived config class per module, typed `@export` fields (one per Tuning Knob, GDD defaults), stored as `.tres`; injected-tier module wired in `GameWorld.tscn`; `validate()` at boot.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Camera position is derived every frame from `target + spherical offset`; never stored independently. Pitch must never approach ±90° (spherical derivation degenerates) — the 0.15–1.5 rad clamp is this fixed pole-safety margin, not an arbitrary tunable. "Exact same value" comparisons mean equality within 1e-4, not bitwise float equality.

**Control Manifest Rules (this layer)**:
- Required: config = one custom `Resource`, typed `@export`, `.tres`; `validate() -> Array[String]` in `setup()`; injected-tier module.
- Forbidden: `ConfigFile`/JSON for tuning; writing a config field at runtime; hardcoded tuning literals; `@export`-ing an Autoload.
- Guardrail: config loads once at boot; wiring resolves once at scene load.

---

## Acceptance Criteria

- [ ] Camera position always equals `target + spherical offset` (distance, yaw, pitch), never independently stored (AC1). [TR-camera-input-021]
- [ ] Pitch is clamped to `[pitch_min, pitch_max]` (0.15–1.5 rad), the fixed pole-safety margin (AC8 basis). [TR-camera-input-037]
- [ ] All tuning-knob values are read from config/exported vars, not literals (AC17). [TR-camera-input-019]

---

## Implementation Notes

*Derived from ADR-0002 / ADR-0001:*

- Create `CameraInputConfig extends Resource` with typed `@export` fields for every Tuning Knob (`start_distance`, `start_yaw`, `start_pitch`, `distance_min`, `distance_max`, `zoom_factor_in`, `zoom_factor_out`, `pitch_min`, `pitch_max`, `q_e_rotate_step`, `mouse_drag_sensitivity`, `pan_speed_factor`, `max_delta_time`) with GDD defaults. `pitch_min`/`pitch_max` are fixed pole-safety values.
- Position: `camera_position = target + Vector3(distance*sin(yaw)*cos(pitch), distance*sin(pitch), distance*cos(yaw)*cos(pitch))`. Recompute every frame; never cache position independently.
- Module is injected-tier: config arrives as `@export`; `validate()` runs in `setup()`. Provenance: all values are `[assumption — prototype-sourced defaults]` except `pitch_min/max` (pole math) and `max_delta_time` (engineering judgment).

---

## Out of Scope

- Story 003/004/005: the rotation/zoom/pan input that mutates yaw/pitch/distance/target.
- Story 006: the world-ray query.

---

## QA Test Cases

- **AC-1 (derived position)**: [TR-camera-input-021]
  - Given: target=(32,0,32), distance=18.0, yaw=0.7, pitch=0.95
  - When: position is computed
  - Then: position ≈ (38.75, 14.63, 40.02) within 1e-4; recomputing yields the same value (no independent store)
  - Edge cases: yaw wraps (2π equivalence); distance at min/max
- **AC-2 (pitch pole clamp)**: [TR-camera-input-037]
  - Given: pitch set to 0.0 and to π/2
  - When: clamped
  - Then: results land within [0.15, 1.5]; the derivation never degenerates
- **AC-3 (config-driven)**: [TR-camera-input-019]
  - Given: the Camera & Input source
  - When: grep for numeric tuning literals in code
  - Then: knob values come from config/exported vars, not inline literals

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/camera_input/camera_config_spherical_derivation_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (module foundation)
- Unlocks: Story 002, Story 003, Story 004, Story 005, Story 006
