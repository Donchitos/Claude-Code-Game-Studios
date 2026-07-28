# Time & Tick System

> **Status**: Approved (2026-07-10 — full review APPROVED-with-patches, applied; see design/gdd/reviews/time-tick-system-review-log.md) — **amended 2026-07-23** (Slice revision 2026-07-23, tick-rate/furniture resolution): `ticks_per_second` raised 2.0 → 4.0 — the vertical slice ran at 4.0 throughout and the user adopted that pace ("villagers should work more")
> **Author**: user + Claude Code Game Studios agents
> **Last Updated**: 2026-07-23
> **Last Verified**: 2026-07-09 (full review); tick-rate amendment not yet re-reviewed
> **Implements Pillar**: Pillar 3 (Cozy, but with stakes) — owns the "real-time with pause and time-warp" mechanism

## Summary

Time & Tick System owns the game's simulated clock — a "game delta-time"
that every simulation system (Villager AI, Needs, Production, Building's
build-over-time) must use instead of raw engine delta, incorporating a
player-toggleable Pause state and a 3-step time-warp speed (1x/2x/3x). It
does NOT own raw frame delta (every node gets that for free from the
engine) — Camera & Input intentionally bypasses this system to stay
responsive even while paused/warped.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

Time & Tick System is the source of truth for "how much game time passed
this frame" — the mechanism behind the concept's stated "real-time with
pause and time-warp." Every system that simulates something over time
(villagers moving through their day, needs decaying, resources being
produced, a wall finishing construction) queries this system's game
delta-time rather than the engine's raw frame delta, so pausing or speeding
up the game uniformly affects all simulation at once. Pause is a distinct,
player-toggleable state — pausing sets game delta-time to zero without
discarding the previously selected time-warp speed, so resuming returns to
that speed, not to 1x. This system does not decide individual simulation
rates (mood decay, movement speed, etc.) — it decides how fast the game
world's own clock runs. Crucially, per Scene/World Management's Core Rule 4,
this clock never stops for scene transitions — only the player-facing Pause
toggle stops it.

## Player Fantasy

Pause and time-warp give the player power over the *pace* of their own
cozy life in the valley — not urgency, but calm control over time itself.
Someone working through a tricky building decision pauses; someone wanting
to skip an uneventful quiet night speeds through it. The directly felt
sensation is: "I set the pace, not the game." This serves Pillar 3 (cozy,
but with stakes) — pause is the moment the player can breathe and plan
before the next challenge — and Pillar 4 (clarity): a visible, legible speed
indicator instead of an opaque simulation tick running in the background.

*(`creative-director` not consulted — Lean mode skips non-high-risk sections.)*

## Detailed Design

*(No specialist consulted — Lean mode skips non-high-risk sections. Review
manually before production.)*

### Core Rules

1. Every frame, this system computes **game delta-time** = raw engine delta
   × time-warp multiplier × (0 if paused, else 1). [TR-time-tick-system-021]
   All simulation systems
   query this value, never raw engine delta. [TR-time-tick-system-022]
2. Time-warp has three fixed speeds: 1x, 2x, 3x, switchable via player input
   (UI trigger RESOLVED 2026-07-10: Building UI owns the MVP time controls —
   pause on Space, speed on +/− or direct 1x/2x/3x buttons, top-right HUD;
   see building-ui.md Rules 1/10). [TR-time-tick-system-023]
3. Pause is a separate, independent toggle. Enabling it sets game delta to
   0 WITHOUT discarding the stored time-warp speed; disabling it resumes at
   that exact speed. [TR-time-tick-system-024]
4. This system does NOT use Godot's global `Engine.time_scale` — it
   maintains its own multiplier, so non-simulation systems (Camera & Input,
   UI animations) remain unaffected by pause/warp and stay fully responsive. [TR-time-tick-system-025]
5. Raw engine delta (from `_process`/`_physics_process`) remains available
   to every system as normal — this system does not intercept or replace
   it, it only additionally computes and exposes "game delta" as a derived
   value. [TR-time-tick-system-026]
6. This system's game delta-time is NOT paused or altered by Scene/World
   Management's Transitioning state — per that GDD's Core Rule 4,
   simulation must continue uninterrupted through scene transitions. Only
   the player's explicit Pause toggle affects it. [TR-time-tick-system-027]
7. In addition to the continuous game delta, this system emits a discrete
   **tick** signal at a fixed rate (`ticks_per_second`, scaled by
   time-warp) — for systems that don't need per-frame precision (villager
   schedules, needs-decay steps) and prefer a "a game tick happened" event.
   This decouples simulation step rate from render frame rate. [TR-time-tick-system-028]
8. Ticks do NOT fire while paused (consistent with Rule 3). [TR-time-tick-system-029]

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|-----------------|-----------------|----------|
| Running | Default; Pause is disabled | Player enables Pause | Game delta = raw delta × time-warp; ticks fire at `ticks_per_second × time-warp` [TR-time-tick-system-021] [TR-time-tick-system-028] |
| Paused | Player enables Pause | Player disables Pause | Game delta = 0; no ticks fire; the time-warp value stays stored, not reset [TR-time-tick-system-024] [TR-time-tick-system-029] |

### Interactions with Other Systems

- **Scene/World Management**: this system does NOT depend on Scene/World
  Management (unlike Camera & Input) — its clock keeps running unchanged
  through scene transitions. **REVISED 2026-07-10**: the former
  time-warp-reset call from Scene/World Management was REMOVED (its
  re-review found the reset created an irreversible warp trap in dungeon
  scenes, where the warp controls don't exist). Time-warp and pause are
  global game state that persists unchanged across all scene transitions;
  no system calls into this one on transition events. [TR-time-tick-system-030] The time-warp-reset
  function is retired from the contract.
- **Camera & Input**: deliberately uses RAW engine delta, not this system's
  game delta — stays fully responsive during pause/warp. No dependency in
  this direction.
- **Villager AI & Behavior, Needs & Mood System, Gathering & Production
  Chains, Squad & Combat System, Audio System** (downstream, various
  tiers): consume either the continuous game delta or the discrete tick
  signal, depending on their needs.
- **Building System** (MVP, downstream): construction progress advances
  per tick event (its Formula F3, incl. a burst rule capping completions
  per frame); pause halts construction, time-warp accelerates it.
- **Building UI** (MVP, downstream): owns the MVP time controls (pause on
  Space, 1x/2x/3x buttons top-right — building-ui.md Rules 1/10).
- **Main Menu & Settings** (Alpha, downstream): settings-level options
  only; formerly expected to host the
  pause/speed control UI (Cross-Reference, GDD not yet authored).

## Formulas

*(`systems-designer` and `godot-specialist` consulted — mandatory for this
high-risk section even in Lean mode. Key decision resolved during
consultation: the tick accumulator runs in `_physics_process` (fixed 60Hz
step), not `_process`, for deterministic, frame-rate-independent simulation
— matching the project's dependency-injection/testability preference over
Godot's global `Engine.time_scale`/`SceneTree.paused`.)*

### Game Delta-Time

`game_delta = clamp(raw_delta, 0, max_raw_delta) * time_warp * (paused ? 0 : 1)` [TR-time-tick-system-021] [TR-time-tick-system-031]

*(Canonical form REVISED 2026-07-10 review: the `max_raw_delta` clamp was
previously stated only in Edge Cases while the formula here read as if
unclamped — the formula is the authoritative statement, so the clamp now
lives in it.)*

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| raw_delta | `raw_delta` | float | > 0.0 (~0.0167s @60fps) | Raw engine delta from `_physics_process`, unmodified |
| max_raw_delta | `max_raw_delta` | float (constant) | **0.1s** (Tuning Knobs, safe 0.05–0.2) | Clamp ceiling applied to `raw_delta` before all use in this system (Edge Cases) |
| time_warp | `time_warp` | int | {1, 2, 3} | Player-selected speed, stored independently of pause |
| paused | `paused` | bool | {true, false} | Pause state |
| game_delta | `game_delta` | float | 0.0–unbounded | Simulated time elapsed this frame |

**Example**: `raw_delta=0.0167, time_warp=2, paused=false` →
`game_delta=0.0334s`. Same frame with `paused=true` → `0.0`.

### Tick Accumulator (drift-free — subtracts, never resets to 0)

`tick_accumulator += game_delta`
`while tick_accumulator >= tick_interval: fire tick(); tick_accumulator -= tick_interval` [TR-time-tick-system-032]
where `tick_interval = 1 / ticks_per_second`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| ticks_per_second | `ticks_per_second` | float (constant) | **4.0** *(Slice revision 2026-07-23, tick-rate/furniture resolution — raised from 2.0)* | Base tick rate at 1x — time-warp is already baked into `game_delta`, so ticks naturally fire at `ticks_per_second × time_warp` |
| tick_interval | `tick_interval` | float | derived, `1/ticks_per_second` = 0.25s | Game-time between ticks |

Runs in `_physics_process` (fixed step) for deterministic, frame-rate-
independent simulation. [TR-time-tick-system-033] **Assumption (2026-07-10 review)**: this relies on
the project default `physics_ticks_per_second = 60`; if that project
setting is ever changed, `raw_delta` and all worked examples here change
with it. The accumulator MUST be float64 (GDScript `float` — not a
32-bit shader/packed float) so long sessions don't lose sub-tick
precision. [TR-time-tick-system-034]

**Example** *(recomputed at `ticks_per_second=4.0`, Slice revision
2026-07-23, tick-rate/furniture resolution)*: `time_warp=2`, accumulator
already at 0.2200 → `+0.0334` → `0.2534` → **tick fires** (crosses
`tick_interval=0.25`), `-0.25` → `0.0034` carries forward (no drift).

### Max-Ticks-Per-Frame Safety Cap

`raw_ticks = floor(tick_accumulator / tick_interval)`
`ticks_to_fire = min(raw_ticks, max_ticks_per_frame)` — excess time beyond
the cap is discarded, not deferred [TR-time-tick-system-035]

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| max_ticks_per_frame | `max_ticks_per_frame` | int (constant) | **12** *(Sprint 8 re-tune 2026-07-25, `design/quick-specs/tick-rate-retune-2026-07-25.md` — raised from 10)* | Upper bound on ticks fired in one frame |

**Example** *(recomputed at `ticks_per_second=4.0` / `max_ticks_per_frame=12`,
Sprint 8 re-tune 2026-07-25,
`design/quick-specs/tick-rate-retune-2026-07-25.md`)*: an alt-tab stall →
accumulator = 12.3s → `raw_ticks=49` (`tick_interval=0.25`) → capped to
12, the remaining 9.3s silently discarded (instead of causing a cascade of
catch-up ticks the following frame too).

**Consumer caveat (2026-07-10 review)**: any downstream invariant phrased
as "exactly N ticks per game-time interval" (e.g. Villager AI's
chained-build heartbeat, "exactly 36 ticks at defaults") holds only
*barring a discard event*. A discard permanently drops simulated time —
consumers must derive durations from tick COUNTS they observe, never from
wall-clock or game-clock arithmetic that assumes no tick was ever lost. [TR-time-tick-system-036]
The reciprocal caveat is noted in villager-ai-behavior.md.

*(Godot note: deliberately NOT `Engine.time_scale`/`SceneTree.paused`/
`Timer` node — these are global and would slow Camera & Input too. A
self-owned, explicitly-queried multiplier is more auditable and matches the
project's dependency-injection-over-singleton preference.)*

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|-------------------|-----------|
| Raw delta-time itself is unusually large (e.g. after an alt-tab stall, several seconds) | `raw_delta` is clamped to `max_raw_delta` BEFORE `game_delta` is computed | Prevents huge one-frame jumps for continuous consumers (build progress, movement) — not just the tick accumulator [TR-time-tick-system-031] |
| The tick catch-up cap (12) is repeatedly hit across consecutive frames | No special handling in this system — this is a performance signal that the simulation is too slow for the current warp/tick rate, must be fixed via profiling | This system can only bound overload, not fix it [TR-time-tick-system-037] |
| Game boot (Scene/World Management's Booting state) | Defaults to `paused = false`, `time_warp = 1` | Matches the "learn by doing" onboarding approach — no reason to start paused [TR-time-tick-system-038] |
| Player toggles Pause and time-warp rapidly in succession | Each toggle is processed immediately and independently, no debounce needed | Discrete, simple toggles — no accumulation problem expected [TR-time-tick-system-039] |
| Time-warp speed is changed while paused | The change is accepted and stored, but has no effect until resumed (since `game_delta` is 0 while paused) | Consistent with Core Rule 3 — pause and time-warp speed are independent [TR-time-tick-system-040] |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|----------------------|
| *(none)* | This system depends on | Foundation layer — zero upstream dependencies |
| Scene/World Management | (edge retired 2026-07-10) | Formerly called the time-warp-reset function on transition begin — removed; warp/pause persist across transitions as global state [TR-time-tick-system-030] |
| Villager AI & Behavior | Depended on by | Consumes game delta and/or tick signal |
| Needs & Mood System | Depended on by | Consumes tick signal for decay steps |
| Gathering & Production Chains | Depended on by | Consumes tick signal for production steps |
| Building System | Depended on by | Consumes tick events for build-over-time construction progress (its Formula F3) |
| Squad & Combat System | Depended on by | Consumes game delta and/or tick signal |
| Audio System | Depended on by | Likely uses tick/game delta for ambient timing (TBD when authored) |
| Building UI | Depended on by | Owns the MVP time controls — calls the pause/warp API, displays the returned state (Core Rule 2 resolution; added 2026-07-10, cross-review fix) [TR-time-tick-system-041] |
| Main Menu & Settings | Depended on by (Alpha) | Settings-level time options only — the in-game pause/speed controls belong to Building UI (corrected 2026-07-10) |
| Camera & Input | (explicitly NOT a dependent) | Uses raw engine delta directly — documented for clarity, not a real edge |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|---------------|------------|---------------------|---------------------|
| `time_warp_options` | {1, 2, 3} | fixed (see Open Questions for more steps) | — | — |
| `ticks_per_second` | 4.0 *(Slice revision 2026-07-23, tick-rate/furniture resolution — raised from 2.0; slice-validated pace, user decision "villagers should work more")* | 1.0–5.0 | Faster AI/needs checks, more compute cost | Cheaper but more "sluggish"-feeling simulation |
| `max_ticks_per_frame` | 12 *(Sprint 8 re-tune 2026-07-25, `design/quick-specs/tick-rate-retune-2026-07-25.md` — raised from 10; ~50% margin over the 8 ticks strictly needed to keep a `max_raw_delta`-clamped frame "honest" under the debug 20x warp gear)* | 5–30 | More catch-up capacity after stalls, but more peak load in one frame | More time discarded after stalls, but smoother per-frame load |
| `max_raw_delta` | 0.1s | 0.05–0.2s | Larger possible simulation jumps after a stall | Simulation visibly "lags" instead of jumping |

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|------------------|-----------------|----------|
| Pause enabled | Slight screen dim/desaturation + pause icon | Ambient audio slightly dampened, not muted | Must Have (MVP) |
| Pause disabled | Dim/desaturation clears | Ambient returns to normal volume | Must Have (MVP) |
| Time-warp speed changes | Speed indicator updates (1x/2x/3x) | Optional light UI click | Should Have (MVP) |

📌 **Asset Spec** — Once the art bible is approved, run
`/asset-spec system:time-tick-system` to derive the pause-dim/speed-indicator
assets from this section.

## Game Feel

### Feel Reference

Instant, satisfying toggle — like RimWorld's speed buttons: a crisp state
change with no transition delay on the toggle itself; the visibly sped-up
simulation is the actual "reward."

### Input Responsiveness

Pause/time-warp toggling must register within 1 frame (~16ms). [TR-time-tick-system-042]

### Weight / Transition

No ease-in/out on pause/resume — an instant, clear switch so there's no felt
lag between pressing the key and its effect.

### Feel Acceptance Criteria

- [ ] Playtesters describe pause/speed toggling as "instant," never "delayed"

## UI Requirements

Pause indicator (icon/overlay) and speed indicator (1x/2x/3x) — likely part
of a small "Time HUD" element. [TR-time-tick-system-043] Exact placement to be defined in `/ux-design`.

> **📌 UX Flag — Time & Tick System**: This system has UI requirements (pause
> indicator, speed indicator). In Phase 4 (Pre-Production), run `/ux-design`
> to create a UX spec for this before writing epics. Stories referencing this
> UI should cite `design/ux/[screen].md`, not this GDD directly.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|---------------------------|-----------|-------------------------------|--------|
| "Time-warp persists unchanged across transitions" | `design/gdd/scene-world-management.md` | Edge Case (REVISED 2026-07-10): warp is global state; the reset call was retired | Rule dependency |
| "This system's clock is NOT suspended by transitions" | `design/gdd/scene-world-management.md` | Core Rule 4 | Rule dependency |
| "Camera & Input uses raw engine delta, not game delta" | `design/gdd/camera-input.md` | Formulas section (Pan formula uses raw delta) | Rule dependency |
| "ticks_per_second, max_ticks_per_frame will be consumed by Villager AI, Needs, Production" | `design/gdd/villager-ai-behavior.md`, `design/gdd/needs-mood-system.md`, `design/gdd/gathering-production-chains.md` (not yet authored) | Tick rate constants | Data dependency |

## Acceptance Criteria

*(`qa-lead` consulted — mandatory for this high-risk section even in Lean
mode. Verdict: GAPS on first draft → the biggest gap was the time-warp-reset
function (referenced in 3 tables, zero ACs) — now covered, plus 4 more
missing criteria and 2 precision fixes.)*

1. **GIVEN** `raw_delta`, `time_warp`, `paused`, **WHEN** `game_delta` is
   computed, **THEN** it equals `raw_delta * time_warp * (0 if paused else
   1)`, within floating-point tolerance (1e-6). *[Logic]* [TR-time-tick-system-021]
2. **GIVEN** the player selects a time-warp speed, **WHEN** selected,
   **THEN** it is exactly one of {1, 2, 3}. *[Logic]* [TR-time-tick-system-023]
3. **GIVEN** Pause is enabled, **WHEN** toggled, **THEN** `game_delta`
   becomes 0 and the stored time-warp value is unchanged. *[Logic]* [TR-time-tick-system-024]
4. **GIVEN** Pause is disabled, **WHEN** toggled, **THEN** `game_delta`
   resumes using the previously stored time-warp value (not reset to 1).
   *[Logic]* [TR-time-tick-system-024]
5. **GIVEN** time-warp is changed while paused, **WHEN** changed, **THEN**
   the new value is stored but has no effect on `game_delta` until Pause is
   disabled. *[Logic]* [TR-time-tick-system-040]
6. **GIVEN** Godot's `Engine.time_scale`, **WHEN** inspected during
   gameplay, **THEN** it remains at its default (1.0) regardless of this
   system's pause/warp state. *[Integration]* [TR-time-tick-system-025]
7. **GIVEN** a scene transition begins, **WHEN** it does, **THEN** this
   system's `game_delta` continues to be computed normally (not suspended).
   *[Integration]* [TR-time-tick-system-027]
8. **GIVEN** any `time_warp`/pause state, **WHEN** a scene transition
   begins and completes, **THEN** this system's state (`time_warp`,
   `paused`, accumulator) is untouched — no API of this system is invoked
   by transition events. *(REVISED 2026-07-10: replaces the retired
   time-warp-reset criterion.)* *[Integration]* [TR-time-tick-system-030]
9. **GIVEN** the tick accumulator, **WHEN** `game_delta` is added each
   physics frame, **THEN** a tick fires each time the accumulator crosses
   `tick_interval`, via subtraction (not reset). *[Logic]* [TR-time-tick-system-032]
10. **GIVEN** `time_warp = N`, **WHEN** ticks are measured over one
    real-time second, **THEN** they fire at `ticks_per_second × N`.
    *[Logic]* [TR-time-tick-system-028]
11. **GIVEN** more ticks are due than `max_ticks_per_frame`, **WHEN**
    processed, **THEN** only `max_ticks_per_frame` ticks fire and excess
    accumulated time is discarded. *[Logic]* [TR-time-tick-system-035]
12. **GIVEN** `raw_delta` exceeds `max_raw_delta`, **WHEN** `game_delta` is
    computed, **THEN** `raw_delta` is clamped first. *[Logic]* [TR-time-tick-system-031]
13. **GIVEN** the game is paused, **WHEN** ticks would otherwise be due,
    **THEN** none fire. *[Logic]* [TR-time-tick-system-029]
14. **GIVEN** game boot completes, **WHEN** this system initializes,
    **THEN** `paused=false` and `time_warp=1` by default. *[Integration]* [TR-time-tick-system-038]
15. **GIVEN** raw engine delta, **WHEN** this system computes `game_delta`,
    **THEN** raw delta remains unmodified and available to any other
    system. *[Logic]* [TR-time-tick-system-026]
16. **GIVEN** Pause/time-warp are toggled multiple times in quick
    succession, **WHEN** each toggle is processed, **THEN** it is applied
    immediately and independently, with no debounce delay. *[Logic]* [TR-time-tick-system-039]
17. **Performance**: `game_delta` and tick-accumulator computation stay
    under 0.5ms combined per physics frame. *[DEFERRED — requires full
    build + profiling]* [TR-time-tick-system-044]
18. No hardcoded values — `time_warp_options`, `ticks_per_second`,
    `max_ticks_per_frame`, and `max_raw_delta` are all read from config.
    *[Config/Data, Advisory]* [TR-time-tick-system-020]

**Added by the 2026-07-10 design review:**
19. **GIVEN** the game is already paused, **WHEN** pause is requested again (idempotency), **THEN** state is unchanged and no duplicate pause side effects (audio dampening, signal emissions) occur. *[Logic]* [TR-time-tick-system-045]
20. **GIVEN** the game is paused at warp 3x, **WHEN** the player changes warp to 2x and later unpauses, **THEN** the game resumes at 2x — pause survived the warp change, the warp change survived the pause. *[Logic]* [TR-time-tick-system-040]
21. **GIVEN** any external event that changes `time_warp`, **WHEN** it is applied, **THEN** the tick accumulator's stored value is NOT modified — warp changes only affect future `game_delta`, never banked time. *[Logic]* [TR-time-tick-system-046]
22. **GIVEN** multiple systems subscribed to the tick signal, **WHEN** a tick fires, **THEN** exactly ONE global broadcast occurs per tick — consumers share the same emission, no per-consumer timers exist anywhere in the project. *[Integration]* [TR-time-tick-system-007]
23. **GIVEN** a deterministic test harness running 10,000 ticks at fixed `raw_delta`, **WHEN** total simulated time is compared against `10000 × tick_interval`, **THEN** accumulated drift is under one `tick_interval` (the subtract-not-reset guarantee at scale). *[Logic]* [TR-time-tick-system-032]

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should more/different time-warp steps be added later than 1x/2x/3x (based on playtest feedback)? | game-designer | After initial playtests | — |
| Exact UI trigger for cycling time-warp (keyboard shortcut vs. clickable buttons)? | ux-designer | At `/ux-design` | **RESOLVED 2026-07-10**: Building UI owns the MVP time controls — Space = pause, +/− or direct 1x/2x/3x buttons, top-right HUD (building-ui.md Rules 1/10) |
| Is "dampened" ambient audio during pause correct, or should it fully mute? | audio-director | At the Audio System GDD | — |
| Does `ticks_per_second` fit the granularity Villager AI/Needs decay need? | systems-designer / ai-programmer | At those GDDs | **RESOLVED 2026-07-23 (Slice revision, tick-rate/furniture resolution)**: raised from 2.0 to 4.0 — the vertical slice ran at 4.0 throughout and the user adopted that pace ("villagers should work more") |
| Reciprocal of villager-ai-behavior.md OQ9: does any Villager AI duration math implicitly assume zero discard events? (See the Consumer caveat under Max-Ticks-Per-Frame.) *(2026-07-10 review)* | ai-programmer | Pre-VS spike | — |
| **Required re-tuning pass** *(flagged 2026-07-23, Slice revision, tick-rate/furniture resolution)*: doubling `ticks_per_second` (2.0→4.0) doubles the real-time speed of every downstream **per-tick rate** (decay/recovery/etc.) unless that rate is explicitly halved. Needs & Mood System's Tuning Knobs documents several rates as real-time-equivalents assuming `ticks_per_second=2.0` (e.g. `decay_per_tick[sleep]` ≈ 9 min to urgent, `base_recovery_per_tick[sleep]` ≈ 70s in bed) — these are now stale and read ~2× faster in real time than their stated/tuned targets. This is NOT auto-corrected by this GDD; per-tick rate values must be revisited and re-tuned (not silently halved) in a dedicated balance pass before those numbers are trusted again. | systems-designer / game-designer | Before next Needs & Mood balance pass | Open — tracked here, not yet actioned |
