# Story 007: Active/Suspended state machine (scene-transition suspend, exact-state restore)

> **Epic**: Camera & Input
> **Status: Complete (2026-07-24 — 421/421 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/camera-input.md`
**Requirement**: `TR-camera-input-034`, `TR-camera-input-033`, `TR-camera-input-035`, `TR-camera-input-042`, `TR-camera-input-041`, `TR-camera-input-031`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 (input arbitration) — primary; ADR-0013 (multi-scene / transitions) secondary
**ADR Decision Summary**: On a scene transition begin, Camera & Input enters Suspended (position freezes, no rotate/zoom/pan, no input dispatch). It exits Suspended on transition-complete OR transition-abort (never complete alone — the three-signal contract). On return it resumes with the exact same yaw/pitch/distance/target (within 1e-4). Suspended ≠ Pause.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Suspension takes effect the moment the transition-begin signal is processed — a later same-frame input is already ignored; an earlier-processed input stands (accepted single-frame greyzone at 60fps). The abort listener is required — without it a failed load strands the camera in Suspended permanently.

**Control Manifest Rules (this layer)**:
- Required: Suspended entered on transition-begin, released on transition-complete OR transition-abort; exact-state restore (1e-4); Suspended is exclusively the scene-transition state.
- Forbidden: releasing Suspended on complete alone (must also handle abort); snapping/catching up on queued input at resume.
- Guardrail: single-frame suspension greyzone accepted, invisible at 60fps.

---

## Acceptance Criteria

- [ ] A scene-transition begin makes the camera enter Suspended: no rotate/zoom/pan, no input dispatch (AC9). [TR-camera-input-034]
- [ ] Suspended is released and Active re-entered on transition-complete OR transition-abort — never complete alone (AC10). [TR-camera-input-033]
- [ ] On return the camera resumes with the exact same yaw/pitch/distance/target it had when frozen, within 1e-4 — no snap, no queued-input catch-up (AC10). [TR-camera-input-042]
- [ ] A rotate mouse button held when a transition begins is ignored until released and re-pressed (AC11). [TR-camera-input-041]
- [ ] Suspended and Pause are independent (Suspended ≠ Pause). [TR-camera-input-031]

---

## Implementation Notes

*Derived from ADR-0010 / ADR-0013:*

- State enum `{Active, Suspended}`. On Scene/World Management's transition-begin, snapshot yaw/pitch/distance/target, freeze position, stop dispatching input to gameplay. On transition-complete OR transition-abort, restore the snapshot exactly and re-enter Active. Connect BOTH end signals — abort must release Suspended (three-signal contract).
- A held rotate button at suspension is dropped; require a fresh press after resume.
- Suspended is exclusively the scene-transition state — do NOT reuse it for game pause (that is Story 009's separate contract).

**Story-level note — pause-menu.md flagged camera-halt trigger (OQ3, M02 scope, NOT implemented here):** `design/ux/pause-menu.md` requires Camera & Input to gain a SECOND, distinct input-halt trigger with the SAME exact-state-restore contract as Suspended, fired by Pause Menu open/close rather than a scene transition — because that GDD reserves Suspended exclusively for scene transitions. This is a documented cross-doc dependency, Milestone-02 scope (the Pause Menu is not in M01), and must land via a `camera-input.md` revision (`/propagate-design-change`). Do NOT overload Suspended to serve it. Flagged here so the state machine is designed to accept a second halt trigger cleanly later.

---

## Out of Scope

- The second (Pause-Menu) halt trigger itself (M02 — see note above).
- Story 009: the raw-delta/pause contract (game pause, distinct from Suspended).

---

## QA Test Cases

- **AC-1 (suspend on begin)**: [TR-camera-input-034]
  - Given: an Active camera
  - When: a transition-begin signal fires
  - Then: rotate/zoom/pan produce no motion; input is not dispatched to gameplay
- **AC-2 (release on complete OR abort, exact restore)**: [TR-camera-input-033, -042]
  - Given: a Suspended camera with snapshot S
  - When: transition-complete fires (and, separately, transition-abort)
  - Then: either signal returns the camera to Active with yaw/pitch/distance/target == S within 1e-4; no snap
  - Edge cases: abort (load failure) must release Suspended — never stranded
- **AC-3 (held button dropped)**: [TR-camera-input-041]
  - Given: rotate button held when transition begins
  - When: suspended then resumed
  - Then: the held button is ignored until released and re-pressed

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/camera_input/active_suspended_state_test.gd` OR documented playtest — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003, Story 004, Story 005 (motion to suspend), Story 006 (ray stays computable while Suspended)
- Unlocks: Story 009 (pause contract distinguished from Suspended); integrated build scene transitions
