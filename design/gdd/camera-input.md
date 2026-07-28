# Camera & Input

> **Status**: Approved (2026-07-10 — full review APPROVED-with-patches, applied; see design/gdd/reviews/camera-input-review-log.md)
> **Author**: user + Claude Code Game Studios agents
> **Last Updated**: 2026-07-09
> **Last Verified**: 2026-07-09
> **Implements Pillar**: None directly — Foundation infrastructure enabling Pillar 1 (building) and Pillar 4 (clarity)

## Summary

Camera & Input owns the game's raw input pipeline (InputMap actions,
mouse/keyboard events) and the single free-orbit camera through which the
player views and navigates the valley — bounded to stay within/near the
Voxel World's extent. It exposes camera state and the current mouse
world-ray to every other system, but does not interpret what a click means
(that's each consuming system's job, e.g. the Building System).

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

Camera & Input is the system the player touches every second of play — an
orbit camera (drag to rotate, wheel to zoom, WASD to pan), bounded to the
valley so the player never drifts into empty void, plus the raw input
pipeline (InputMap actions, mouse/keyboard capture) that every other system
builds on. This system owns HOW input is captured and HOW the camera moves;
it does NOT decide WHAT an input means gameplay-wise — a left-click reaching
the Building System still has to be interpreted there as "place a block."
MVP needs exactly one camera mode: free orbit. Additional modes (e.g., a
future combat-focus camera) are deliberately out of scope until a system
actually needs one.

## Player Fantasy

Unlike Scene/World Management or Voxel World, the player feels this system
directly and continuously — every rotation, zoom, and pan is immediate
feedback. The camera fantasy is still one of *invisibility through quality*:
it should feel smooth, predictable, and responsive enough that all of the
player's attention stays on what's being built, not on the camera itself.
The building prototype already confirmed this — camera/orbit/snapping never
became the friction the concept doc feared. Success here doesn't mean "the
player never notices the camera," it means "the player never notices it
*because* it's good" — a subtle but important distinction from the purely
invisible Foundation systems.

*(`creative-director` not consulted — Lean mode skips non-high-risk sections.)*

## Detailed Design

*(No specialist consulted — Lean mode skips non-high-risk sections. Drafted
using the building prototype's validated camera values as reference. Review
manually before production.)*

### Core Rules

1. The camera orbits a target point (a look-at point in world space) at a
   configurable distance, yaw, and pitch — position is derived from
   target + spherical offset, not stored independently. [TR-camera-input-021]
2. Middle-mouse-drag rotates the camera: horizontal drag changes yaw,
   vertical drag changes pitch (within the pitch clamp bounds). [TR-camera-input-022]
3. Q/E keys rotate yaw by a fixed step per press (an alternative to mouse
   drag). [TR-camera-input-023]
4. The mouse wheel zooms by scaling distance **multiplicatively** (not
   additively), clamped to a min/max distance range. [TR-camera-input-024]
5. WASD pans the orbit target along the ground plane, direction relative to
   the camera's current yaw ("W" always means "forward relative to view"),
   scaled by delta-time and current distance (panning feels proportionally
   faster when zoomed out). [TR-camera-input-025] Screen-edge panning is deliberately NOT
   included in MVP — a decision, not an omission: edge-pan fights the
   mouse-driven building workflow (the cursor lives at the screen edges
   during placement) *(made explicit 2026-07-10 review; revisit at
   playtest if players ask for it)*.
6. The orbit target is clamped to the Voxel World's horizontal bounds (plus
   a small margin) so panning cannot drift into the void beyond the world edge. [TR-camera-input-026] *(Clarified 2026-07-11, large-world decision: the clamp is the WORLD edge - free camera roaming across the whole 2000x2000 world is intended, exploration pillar; the camera is not restricted to the settlement core.)*
7. This system owns the InputMap action definitions (e.g., `build_place`,
   `build_remove`, `camera_rotate_left`) but does NOT interpret what an
   action means — it only reports "this action fired" via signal; the
   consuming system (Building System, etc.) owns interpretation. [TR-camera-input-027]
8. This system exposes a "current mouse world-ray" query (derived from the
   camera's projection and the mouse's screen position), so any system
   (e.g., the Building System, which forwards it to Voxel World's raycast)
   can convert the mouse position into a world-space ray without
   recomputing the camera projection itself. [TR-camera-input-028] The ray is ALWAYS computable —
   in every state, including Suspended (frozen transform) — callers never
   need a "is the ray available?" branch *(clarified 2026-07-10 review)*. [TR-camera-input-029]
9. **Raw-delta contract** *(authored 2026-07-10 review — building-ui.md and
   villager-info-ui.md already cite this contract; it was implied by the
   Formulas but never stated as a rule)*: all camera motion (rotate, zoom,
   pan) is driven by RAW engine delta-time, never by Time & Tick's
   `game_delta`. Camera feel is identical at 1x, 2x, 3x warp. [TR-camera-input-030]
10. **Pause contract** *(authored 2026-07-10 review, same provenance)*:
    game pause does NOT suspend this system — the camera remains fully
    controllable and input dispatch continues while paused, so the player
    can inspect their village and queue plans. **Suspended ≠ Pause**:
    Suspended is exclusively the scene-transition state (see States); the
    two conditions are independent and neither implies the other. [TR-camera-input-031]
11. **Action registration** *(authored 2026-07-10 review)*: the InputMap
    actions this system owns are registered in the Godot project settings
    (project.godot) at project scope, not created in code at runtime — the
    authoritative list is the union of actions named by downstream GDDs
    (Building System, Building UI, Villager Info UI), collected at
    `/create-architecture` into the input ADR. [TR-camera-input-032]

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|-----------------|-----------------|----------|
| Active | Default; also entered from Suspended when a scene transition ends — on transition-complete OR transition-abort *(abort path added 2026-07-10, reciprocal with Scene/World Management's Core Rule 7 three-signal contract: without it, a failed load stranded the camera in Suspended permanently)* [TR-camera-input-033] | A scene transition begins (see Scene/World Management) | Full camera control (rotate/zoom/pan) and input dispatch are enabled |
| Suspended | A scene transition begins (Scene/World Management's Transitioning state) | Scene transition completes OR aborts (either end-signal releases Suspended — never complete alone) | Camera position freezes; no rotate/zoom/pan; input events are not dispatched to gameplay systems. [TR-camera-input-034] **Ordering** *(2026-07-10 review)*: suspension takes effect the moment the transition-begin signal is processed — an input event arriving later in the SAME frame is already ignored; an input processed earlier that frame stands (single-frame greyzone accepted, invisible at 60fps) [TR-camera-input-035] |

*(Directly implements Scene/World Management's Core Rule 6 — "neither scene
receives input" during a transition.)*

### Interactions with Other Systems

- **Scene/World Management** (Foundation sibling): this system suspends
  itself during the Transitioning state (see that GDD's Core Rule 6); its
  own root also lives under the loaded scene.
- **Voxel World** (Foundation sibling): **no direct connection.** This
  system only provides the mouse world-ray; the Building System fetches
  that ray and forwards it to Voxel World's raycast API. Camera & Input
  never calls Voxel World itself. [TR-camera-input-036]
- **Building System** (MVP, downstream): consumes InputMap action signals
  (e.g., `build_place`) and the mouse-world-ray query to interpret player
  input and perform picking (via Voxel World).

## Formulas

*(`systems-designer` and `godot-specialist` consulted — mandatory for this
high-risk section even in Lean mode. Formalizes the concept prototype's
already-proven values rather than inventing new ones.)*

### Camera Position from Spherical Coordinates

`camera_position = target + Vector3(distance * sin(yaw) * cos(pitch), distance * sin(pitch), distance * cos(yaw) * cos(pitch))` [TR-camera-input-021]

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| target | `target` | Vector3 | see Pan formula | Orbit target point (ground plane) |
| distance | `distance` | float | 4.0–60.0 | Spherical radius |
| yaw | `yaw` | float (rad) | unbounded, wraps | Horizontal orbit angle |
| pitch | `pitch` | float (rad) | **0.15–1.5** (safety margin from the poles, see note below) | Vertical orbit angle |
| camera_position | `camera_position` | Vector3 | derived | Resulting camera world position |

**Example**: `target=(32,0,32), distance=18.0, yaw=0.7, pitch=0.95` →
`camera_position ≈ (38.75, 14.63, 40.02)`. Recomputed every frame, never
stored independently.

**Important Godot note**: `pitch` must never approach the poles (±90°) — the
spherical-to-Cartesian derivation degenerates there (the yaw axis becomes
undefined). The 0.15–1.5 rad range (≈8.6°–86°) is exactly this safety
margin, not an arbitrary choice. [TR-camera-input-037]

### Zoom (multiplicative)

`distance' = clamp(distance * zoom_factor, 4.0, 60.0)` [TR-camera-input-024]

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| distance | `distance` | float | 4.0–60.0 | Current orbit distance |
| zoom_factor | `zoom_factor` | float | {0.9 in, 1.1 out} | Factor **per wheel event** (not per frame — the wheel fires discretely) |

**Example**: `distance=18.0`, zoom in → `18.0 * 0.9 = 16.2`.

### Pan (yaw-relative, distance-scaled)

`target' = clamp_to_bounds(target + input_dir.normalized().rotated(UP, yaw) * delta * distance * 0.7)` [TR-camera-input-025]

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| input_dir | `input_dir` | Vector3 | WASD combination | Raw direction before yaw rotation |
| delta | `delta` | float | ~0–0.05 | Frame delta-time |
| distance | `distance` | float | 4.0–60.0 | Faster pan when zoomed out |
| target' | `target'` | Vector3 | clamped to `[0, world_width_cells*cell_size] × [0, world_depth_cells*cell_size]` | New orbit target |

### Mouse World-Ray — deliberately NOT a Formula

`origin = camera.project_ray_origin(mouse_screen_pos)`,
`direction = camera.project_ray_normal(mouse_screen_pos)` — native Godot 4.7
API (unchanged since 4.3), no tunable value of our own. **Important**: both
must be computed from the same screen point in the same frame (don't cache
one and recompute the other later, or Suspended-state freezes could desync
them). [TR-camera-input-038]

### Godot 4.7 clarification: device ID is irrelevant here

The 4.7 change (`DEVICE_ID_MOUSE`/`DEVICE_ID_KEYBOARD` replacing hardcoded
`0`) only concerns which physical device generated an event. Nothing in this
system branches on device identity (actions route through named InputMap
actions and typed event checks) — deliberately a non-issue, so no one adds
unnecessary device-ID logic here later. [TR-camera-input-039]

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|-------------------|-----------|
| Mouse-drag would push `pitch` beyond its bounds (0.15/1.5) | Silently clamps to the boundary, no error | Standard clamp behavior, prevents pole degeneration [TR-camera-input-040] |
| WASD held while the target is already at the world bound | Target stays clamped, no further movement in that direction, no error | Prevents drifting into the void without blocking input [TR-camera-input-026] |
| A scene transition begins while the rotate mouse button is held | Camera immediately enters Suspended; the held button is ignored until released and re-pressed | Prevents a "stuck" drag state from surviving the transition [TR-camera-input-041] |
| Camera returns from Suspended to Active | Resumes with the exact same yaw/pitch/distance/target it had when frozen — no snap, no catching up on queued input | Prevents disorientation after a scene transition [TR-camera-input-042] |
| Very large delta-time in one frame (e.g., a hitch, or the window was minimized) | Delta-time is clamped to a maximum before entering the Pan formula | Prevents a huge camera jump after a stall [TR-camera-input-043] |
| Mouse wheel fires very rapidly (fast scrolling) | Each event independently applies the zoom factor; the clamp (4.0–60.0) prevents overshoot regardless of event count | No compounding issue from the multiplicative formula [TR-camera-input-044] |
| The mouse world-ray query is called while Suspended | Remains technically computable (camera transform is frozen but valid) — consuming systems shouldn't act on it anyway, since input dispatch is disabled during the transition | No special case needed in the ray calculation itself; consistency comes from input suspension [TR-camera-input-029] |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|----------------------|
| Scene/World Management | This system depends on | Listens for the transition signals: Suspended entered on begin, exited on complete OR abort (abort listener added 2026-07-10, reciprocal with that GDD's Core Rule 7) [TR-camera-input-033] |
| Voxel World | (indirect only, via Building System) | See Interactions — no direct call |
| Building System | Depended on by | Consumes InputMap action signals and the mouse-world-ray query |
| Building UI | Depended on by | Registers its bindings (`tool_select_1..5`, `time_pause`, `time_speed_up/down`) under this system's action ownership (its Rule 12); follows Suspended (added 2026-07-10, cross-review bidirectional fix) [TR-camera-input-032] |
| Villager Info UI | Depended on by | Consumes the mouse-world-ray + click action in Idle for villager selection; follows Suspended (added 2026-07-10, cross-review bidirectional fix) |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|---------------|------------|---------------------|---------------------|
| `start_distance` | 18.0 | 4.0–60.0 | Starts more zoomed out | Starts closer in |
| `start_yaw` | 0.7 rad | any | — | — |
| `start_pitch` | 0.95 rad | 0.15–1.5 | Steeper starting top-down angle | Flatter starting view angle |
| `distance_min` / `distance_max` | 4.0 / 60.0 | — | Larger zoom range, more load at very far distances | Tighter zoom range, may feel restrictive |
| `zoom_factor_in` / `zoom_factor_out` | 0.9 / 1.1 | 0.8–0.95 / 1.05–1.2 | Snappier zoom steps | Smoother but slower zoom |
| `pitch_min` / `pitch_max` | 0.15 / 1.5 rad | fixed (pole safety margin, see Formulas) | — | — |
| `q_e_rotate_step` | 0.12 rad | 0.05–0.3 | Faster key-based rotation | Finer, slower key-based rotation |
| `mouse_drag_sensitivity` | 0.008 | 0.003–0.02 | More sensitive mouse rotation | Less responsive mouse rotation |
| `pan_speed_factor` | 0.7 | 0.3–1.5 | Faster panning | Slower panning |
| `max_delta_time` | 0.1s | 0.05–0.2s | Larger possible camera jumps after a hitch | Camera visibly "lags" through a hitch instead of jumping |

*(Provenance corrected by the 2026-07-10 review — the earlier claim "all
values come directly from the playtested prototype" overstated: the
prototype's REPORT.md contains no camera-value findings. The values were
carried over from the prototype's source configuration, which playtesting
did not flag as wrong — that is weaker evidence than a positive finding.
All values are therefore `[assumption — prototype-sourced defaults]`
except `pitch_min`/`pitch_max` (pole-degeneracy math, see Formulas) and
`max_delta_time` (engineering judgment). First playtest validates them.)*

## Visual/Audio Requirements

This system has almost no dedicated visual/audio events of its own — its
"feedback" IS the camera motion itself. Two light touches are worth
specifying: (1) the mouse cursor should change during an active rotate-drag
(e.g., to a grab/orbit icon) to signal the drag is engaged [TR-camera-input-045]; (2) reaching a
pan boundary is deliberately silent — no additional VFX/audio cue — matching
Pillar 4 (clarity over complexity) and avoiding noise during normal building
flow.

## Game Feel

### Feel Reference

Should feel like a smooth colony-sim orbit camera (Stonehearth/Cities:
Skylines-adjacent) — buttery, no perceptible lag on rotate, but panning
carries a touch of glide rather than a robotic snap. NOT like a flight-sim
free camera (too many degrees of freedom, disorienting), NOT like a rigid
grid-locked RTS camera (too stiff for an "orbit around your creation" feel).

### Input Responsiveness

| Action | Max Input-to-Response Latency (ms) | Frame Budget (at 60fps) | Notes |
|--------|-------------------------------------|--------------------------|-------|
| Mouse-drag rotate | ~16ms (1 frame) | 1 frame | Must feel 1:1, zero perceptible lag [TR-camera-input-046] |
| Zoom (wheel) | ~16ms | 1 frame | Instant response to the wheel event [TR-camera-input-046] |
| WASD pan | ~16ms | 1 frame | Input registers the same frame it's pressed [TR-camera-input-046] |

### Animation Feel Targets / Impact Moments

N/A — no keyframed animation, only continuous formula-driven movement; no
combat-hit equivalent for this system.

### Weight and Responsiveness Profile

Light and reactive, not heavy/deliberate — the camera should feel like an
extension of the mouse, not a vehicle with momentum. High player control at
all times (no forced inertia beyond the input itself). Smooth/analog, not
stepped. Instant start/stop on rotate/pan (arcade feel, no ease-in/out) —
matching the already-validated prototype feel. Hitting a boundary
(pan/pitch) should read as a gentle stop, not a jarring bounce.

### Feel Acceptance Criteria

- [ ] Playtesters describe the camera as "smooth"/"responsive" unprompted,
      never "laggy" or "floaty"
- [ ] No playtester reports disorientation from rotation or zoom
- [ ] Reaching a boundary is described as a "gentle stop," not jarring

## UI Requirements

Minimal — only the mouse cursor state (see Visual/Audio). [TR-camera-input-045] No dedicated HUD
element. Camera settings (e.g., sensitivity) belong to Main Menu & Settings
(Alpha tier) later, not here.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|---------------------------|-----------|-------------------------------|--------|
| "Listens for the transition-begin/-complete/-abort signals" | `design/gdd/scene-world-management.md` | Transition signals (Core Rule 7 three-signal contract) | State trigger |
| "Suspended state directly implements 'neither scene receives input'" | `design/gdd/scene-world-management.md` | Core Rule 6 | Rule dependency |
| "world_width_cells, world_depth_cells, cell_size bound the pan target" | `design/gdd/voxel-world.md` | Tuning Knobs + `cell_size` constant | Data dependency |
| "InputMap action results feed the Building System's interpretation" | `design/gdd/building-system.md` (not yet authored) | Action signal consumption | Data dependency |

## Acceptance Criteria

*(`qa-lead` consulted — mandatory for this high-risk section even in Lean
mode. Verdict: GAPS on first draft → 2 missing criteria added (mouse-ray
during Suspended, rapid-zoom clamp), 2 reworded for testability (bound-pan
behavior, InputMap non-interpretation as a positive checkable contract).)*

1. **GIVEN** the camera is active, **WHEN** position is computed, **THEN** it
   always equals target + spherical offset (never independently stored).
   *[Logic]* [TR-camera-input-021]
2. **GIVEN** middle-mouse-drag, **WHEN** dragged horizontally, **THEN** yaw
   changes proportionally by `mouse_drag_sensitivity`; vertical drag changes
   pitch, clamped to `[pitch_min, pitch_max]`. *[Logic]* [TR-camera-input-022]
3. **GIVEN** Q or E is pressed, **WHEN** the press registers, **THEN** yaw
   changes by ±`q_e_rotate_step`. *[Logic]* [TR-camera-input-023]
4. **GIVEN** a single mouse wheel event, **WHEN** it fires, **THEN** distance
   is multiplied by `zoom_factor_in`/`out` and clamped to
   `[distance_min, distance_max]`. *[Logic]* [TR-camera-input-024]
5. **GIVEN** N sequential zoom-in wheel events (rapid scrolling), **WHEN**
   each fires, **THEN** distance still respects the clamp regardless of N.
   *[Logic]* [TR-camera-input-044]
6. **GIVEN** WASD input, **WHEN** held, **THEN** the target moves in the
   yaw-rotated input direction, scaled by delta-time and current distance.
   *[Logic]* [TR-camera-input-025]
7. **GIVEN** the target is already at a world bound and WASD keeps pushing
   outward, **WHEN** pan is applied repeatedly, **THEN** it produces zero
   further delta in that direction with no exception raised (input is not
   blocked, it simply has no further effect). *[Logic]* [TR-camera-input-026]
8. **GIVEN** pitch would exceed its bounds, **WHEN** rotation input is
   applied, **THEN** it clamps silently without error. *[Logic]* [TR-camera-input-040]
9. **GIVEN** a scene transition begins, **WHEN** the signal fires, **THEN**
   the camera immediately enters Suspended (no rotate/zoom/pan, no input
   dispatch). *[Integration]* [TR-camera-input-034]
10. **GIVEN** the camera is Suspended, **WHEN** the transition completes —
    OR aborts on load failure *(abort case added 2026-07-10, reciprocal
    with Scene/World Management Core Rule 7)* — **THEN** it returns to
    Active with the exact same yaw/pitch/distance/target it had when
    suspended. *[Integration]* [TR-camera-input-033] [TR-camera-input-042]
11. **GIVEN** the rotate mouse button is held when a transition begins,
    **WHEN** suspended, **THEN** the held button is ignored until released
    and re-pressed. *[Integration]* [TR-camera-input-041]
12. **GIVEN** the camera is Suspended, **WHEN** the mouse world-ray is
    queried, **THEN** it returns a valid ray from the frozen transform — no
    error, no special-case branch. *[Logic]* [TR-camera-input-029]
13. **GIVEN** a very large delta-time (e.g., after a stall), **WHEN** the pan
    formula runs, **THEN** delta-time is clamped to `max_delta_time` first.
    *[Logic]* [TR-camera-input-043]
14. **GIVEN** the mouse world-ray query is called, **WHEN** invoked, **THEN**
    origin and direction are computed from the same screen point in the same
    frame. *[Logic]* [TR-camera-input-038]
15. **GIVEN** an InputMap action fires (e.g. `build_place`), **WHEN** this
    system processes it, **THEN** the emitted signal payload contains only
    the action name string, and the emitting code path contains no branch on
    that string's value. *[Advisory — code-review check, re-tiered
    2026-07-10: "contains no branch" is verified by reading the code, not
    by a runtime assertion]* [TR-camera-input-027]
16. **Performance**: camera position recomputation and input processing
    complete within budget every frame. *[DEFERRED — requires full build +
    profiling]* [TR-camera-input-047]
17. No hardcoded values — all tuning knob values are read from config/
    exported vars, verified by code review. *[Config/Data, Advisory]* [TR-camera-input-019]

**Added by the 2026-07-10 design review** *(precision note: all "exact
same value" comparisons in ACs above — e.g. AC10's restored
yaw/pitch/distance/target — mean equality within 1e-4, not bitwise float
equality [TR-camera-input-048])*:
18. **GIVEN** project boot, **WHEN** the InputMap is inspected, **THEN** every action name any downstream GDD references (`build_place`, `build_remove`, camera actions, UI shortcuts) exists as a registered action — no consumer ever queries an unregistered action name. *[Integration]* [TR-camera-input-032]
19. **GIVEN** a mouse click that a UI element consumes (Building UI / Villager Info UI click-ownership), **WHEN** the click is handled by the UI layer, **THEN** this system does NOT also emit the corresponding world-action signal for that same click — exactly one owner per click. *[Integration]* [TR-camera-input-020]
20. **GIVEN** the pan-bound margin is configured to 0 (the current default), **WHEN** the target is panned hard against a world edge, **THEN** the clamp still behaves per AC7 (zero further delta, no error) — margin 0 is a valid configuration, not an edge case. *[Logic]* [TR-camera-input-049]
21. **GIVEN** the mouse is at screen position P, **WHEN** the world-ray is queried and intersected with the ground plane, **THEN** re-projecting that intersection back to screen space yields P within 1 pixel (round-trip projection correctness). *[Logic]* [TR-camera-input-050]

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Exact cursor icon/asset for the rotate-drag state? | art-director | At the art bible | — |
| Exact margin value for the pan-bound clamp ("plus a small margin," Core Rule 6)? | game-designer | Alongside the Building System GDD (depends on how close to the edge building must reach) | **RESOLVED 2026-07-09**: no building-driven extra margin needed — building must reach the world edge, and the world-extent clamp already permits that (building-system.md, Interactions). Any small aesthetic margin is a pure camera-feel value; keep default 0 until playtest says otherwise |
| Is gamepad camera control needed at MVP, or only later (per technical-preferences.md "partial... later")? | game-designer | Before Alpha | — |
| Is `max_delta_time` = 0.1s the right value, or does it need adjusting during the performance spike (see Voxel World GDD)? | technical-director | At the performance spike before Vertical Slice | — |
