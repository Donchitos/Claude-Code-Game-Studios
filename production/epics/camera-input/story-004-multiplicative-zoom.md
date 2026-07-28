# Story 004: Zoom — multiplicative, clamped, rapid-event safe

> **Epic**: Camera & Input
> **Status: Complete (2026-07-24 — 355/355 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 0.5–1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/camera-input.md`
**Requirement**: `TR-camera-input-024`, `TR-camera-input-044`, `TR-camera-input-030`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (config-driven tunables) — primary
**ADR Decision Summary**: Mouse-wheel zoom scales distance multiplicatively per wheel event, clamped to `[distance_min, distance_max]`; the clamp holds regardless of event count.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: Wheel fires discretely — `zoom_factor` is per wheel event, not per frame. Multiplicative scaling with a clamp cannot overshoot regardless of rapid event count. Raw-delta contract still applies (zoom is instant per event).

**Control Manifest Rules (this layer)**:
- Required: multiplicative zoom per wheel event, clamped; tunables from config.
- Forbidden: additive zoom; hardcoded factors/limits.
- Guardrail: zoom latency ~16ms (instant response to the wheel event).

---

## Acceptance Criteria

- [ ] A single wheel event multiplies distance by `zoom_factor_in`/`out` and clamps to `[distance_min, distance_max]` (AC4). [TR-camera-input-024]
- [ ] N sequential rapid zoom events still respect the clamp regardless of N (AC5). [TR-camera-input-044]

---

## Implementation Notes

*Derived from ADR-0002:*

- `distance = clamp(distance * zoom_factor, distance_min, distance_max)` where `zoom_factor` = `zoom_factor_in` (0.9) on wheel-up-in / `zoom_factor_out` (1.1) on wheel-down-out. Apply once per wheel event.
- No accumulation state — each event applies independently; the clamp bounds overshoot.

---

## Out of Scope

- Story 003 (rotation), Story 005 (pan), Story 007 (Suspended freezes zoom).

---

## QA Test Cases

- **AC-1 (multiplicative clamp)**: [TR-camera-input-024]
  - Given: distance=18.0, `zoom_factor_in=0.9`
  - When: one zoom-in event
  - Then: distance = 16.2; a zoom-out at distance_max stays at distance_max
- **AC-2 (rapid events respect clamp)**: [TR-camera-input-044]
  - Given: distance near distance_min
  - When: 50 rapid zoom-in events
  - Then: distance never drops below distance_min; no compounding overshoot
  - Edge cases: alternating in/out events return toward the start value without drift past clamps

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/camera_input/multiplicative_zoom_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (config + derivation), Story 002 (input actions)
- Unlocks: Story 007 (Suspended freezes zoom)
