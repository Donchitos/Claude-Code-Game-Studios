# ADR-0007: Pet State Machine Architecture

## Status
Accepted (2026-07-11 — accepted post independent /architecture-review; flame-specialist-validated at authoring)

## Date
2026-07-07

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | Core / Rendering (Flame component state + `TimerComponent` + Riverpod derivation) |
| **Knowledge Risk** | MEDIUM — Flame `TimerComponent`/`Timer` and component-update semantics changed idiom post-cutoff, and the load-bearing question (does a `TimerComponent` pause with the game loop on app background, or keep counting on wall-clock?) is exactly the kind of behavior that must be verified against 1.37, not assumed. Riverpod derivation is LOW. |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`, `current-best-practices.md`, `deprecated-apis.md`; `design/gdd/pet-state-machine.md`; ADR-0004, ADR-0005; flame-specialist validation (2026-07-07) |
| **Post-Cutoff APIs Used** | Flame `TimerComponent` / `Timer` (triggered-state duration), `Component.update(dt)`, `onMount`/`onRemove`/`isMounted` (per ADR-0004). |
| **Verification Required** | **Confirmed against Flame 1.37.0 source (flame-specialist, 2026-07-07)** — no open unknown. `Timer.update`/`TimerComponent.update` are purely `update(dt)`-driven (no wall-clock); and `FlameGame` pauses the loop on background *automatically* (`GameRenderBox` is a `WidgetsBindingObserver` → `lifecycleStateChange` → `pauseWhenBackgrounded=true` by default → `pauseEngine()` stops the ticker, so `update()` is not called at all while backgrounded). So a triggered-state timer pauses and resumes correctly by construction. The only remaining "verification" is the acceptance test (interrupt an animation by backgrounding → confirm resume). **Standing constraint**: nothing may set `pauseWhenBackgrounded=false` on the shared `FlameGame` — see Risks. **Confirmed 2026-07-16 (Story 004 follow-up, real `GameWidget`/`Ticker` harness)**: pause/resume correctness holds for both the `Effect`-driven states (EXCITED, SHOWING_OFF) and the `TimerComponent`-driven ones (LEVELING_UP, PLEASED, BOUNCING) — verified via `flame_test`'s `FlameTester.testGameWidget` + `WidgetsBinding.instance.handleAppLifecycleStateChanged(...)`, driving a genuine `GameRenderBox → GameLoop → Ticker` pipeline rather than a simulated pause. One minor, benign artifact found: the real `Ticker`'s first callback after any `GameLoop.start()` (initial mount OR a resume-from-pause) reports a near-zero `dt` (`GameLoop._previous` resets to `Duration.zero` on `stop()`, and the underlying `Ticker` restarts its own elapsed-time reference on `start()`), costing roughly one frame of real progress at each such boundary — not a correctness bug (confirmed by direct `scale.x`/timer-progress instrumentation: progress resumes smoothly and completes at the expected total, just ~one frame later than a naive boundary calculation would predict). Anything asserting an exact triggered-state completion boundary after a resume (tests, or future gameplay logic) should budget for this one-frame slack. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0004 (Flutter-Flame Event Bridge) — consumes `GameEvent`s (taskApproved, petInteracted, itemEquipped, seedReceived, petLeveledUp) to drive triggered states, subject to the bridge's onMount/isMounted/cancel + payload-per-type rules. ADR-0005 (Time & Decay) — reads `energyProvider` and realizes the energy→mood lookup ADR-0005 delegated here. |
| **Enables** | Pet Interaction (#14), Pet Equipment (#15), Pet Leveling (#16), Seed Buffer (#10) — all fire triggers into this machine; Pet Room Screen UI (#18) — renders mood + energy bar. |
| **Blocks** | Any implementation epic animating Mochi's mood/reactions. |
| **Ordering Note** | This ADR now OWNS the energy→mood lookup table (ADR-0005 delegated it). It does NOT own the trigger *sources* (who emits `petLeveledUp` etc. — that's the emitting systems' ADRs) nor the SHOWING_OFF particle spec (owned by Pet Equipment #15). |

## Context

### Problem Statement

Mochi is the emotional center of the game and the surface the child interacts with most — it must feel alive and reactive, never a static sprite. Its state has two independent layers that must not be conflated: a **persistent Base Mood** derived from energy (HAPPY/CONTENT/TIRED/SAD/SLEEPING), and **transient Triggered States** (EXCITED/PLEASED/SHOWING_OFF/BOUNCING/LEVELING_UP) that briefly override the animation in response to events, then return to Base Mood without changing energy. Getting the architecture right means deciding where each layer lives, how triggered states are prioritized and timed, how LEVELING_UP stays non-interruptible, and — critically — that the triggered-state timers survive app backgrounding correctly. The `pet-state-machine.md` GDD specifies the behavior; this ADR pins the layer boundary and the timer mechanism.

### Constraints
- **One-way event flow** (ADR-0004): triggers arrive as `GameEvent`s; the machine never calls back into Flutter.
- **Base Mood is a pure function of energy** (ADR-0005 delegation): no independent mood formula; it's the energy→mood lookup, owned here.
- **Triggered states never mutate energy or Base Mood** — they are animation-layer only.
- **Timers must pause/resume with the app** (TR-petstate-004): a triggered animation interrupted by backgrounding must resume, not restart or skip.
- **60fps / draw-call budget** (ADR-0001): Mochi + overlays are part of the ≤200 Flame-canvas budget.

### Requirements
- Base Mood: instant transition when energy crosses a threshold; no event emitted if the mood band doesn't change (avoid needless re-render).
- Triggered states with strict priority: LEVELING_UP > EXCITED > SHOWING_OFF > PLEASED > BOUNCING.
- LEVELING_UP non-interruptible: once playing, no trigger (even EXCITED) resets/overrides it; others queue and replay after.
- SLEEPING accepts only EXCITED (approve wakes) and LEVELING_UP; ignores ordinary triggers.
- `petMoodProvider` / `petEnergyProvider` (Riverpod) as the readable Base-Mood surface for UI.

## Decision

**1. Two layers, two homes — Base Mood in Riverpod, Triggered State in Flame.**
- **Base Mood** is a pure Riverpod derivation from `energyProvider` (ADR-0005) via the energy→mood lookup this ADR owns. Exposed as `petMoodProvider` (`Provider<MoodState>`) — testable, no game-loop dependency. It emits a `petMoodChanged` event through the Bridge only when the mood *band* changes (85→90 stays HAPPY → no event).
- **Triggered State** is **Flame-side ephemeral only**: `MochiComponent` holds the current triggered state and a `TimerComponent` (or `Timer`) for its duration. It is never persisted and never mirrored into Riverpod, because it is pure animation with no other consumer. It is applied when a trigger `GameEvent` arrives and cleared (return to Base Mood animation) when the timer completes.
- **`MochiComponent` caches the Base Mood locally from `petMoodChanged`, never by reading Riverpod.** The component needs the current Base Mood for two reasons — to know which idle animation to *return to* after a triggered animation, and to gate "SLEEPING accepts only EXCITED/LEVELING_UP." It gets it by handling a `petMoodChanged` case in the **same** `_onEvent` switch it already uses for triggers (same single subscription — no second listener, no `ProviderContainer`, no `ref.read` in the component; reading Riverpod from a Flame component is the ADR-0004 Alternative-B anti-pattern). **Cold-start seed**: `ref.listen` fires only on *change*, so on first load no `petMoodChanged` fires and `_baseMood` would be null. The hosting widget must seed it once — emit `petMoodChanged` with `ref.read(petMoodProvider)` during initial build (in addition to `ref.listen` for changes), or pass the initial mood into `MochiComponent`'s constructor. A one-time value handoff, not an ongoing Riverpod dependency — one-way-flow-safe.

**2. Energy→mood lookup (owned here).**
```
MoodState = SLEEPING  if energy == 10
          = SAD       if 10 < energy <= 19
          = TIRED     if 20 <= energy <= 49
          = CONTENT   if 50 <= energy <= 79
          = HAPPY     if energy >= 80
```
This is the single authoritative copy (ADR-0005's table is reference-only). Pure lookup, no independent formula.

**3. Triggered-state priority + non-interruptible LEVELING_UP.**
Priority high→low: **LEVELING_UP > EXCITED > SHOWING_OFF > PLEASED > BOUNCING**. On a new trigger: if higher priority than the current triggered state, reset the timer and play the new animation; if lower/equal, ignore. **LEVELING_UP is the exception**: while it is playing, all other triggers (including EXCITED) are *queued*, not applied — after LEVELING_UP's 3s completes, the highest-priority queued trigger (if any) replays. SLEEPING ignores ordinary triggers but still accepts EXCITED (wake) and LEVELING_UP.

**4. Triggered-state timing via Flame's frame-ticked timer — pauses with the loop (confirmed).**
The triggered-state duration is driven by a Flame `TimerComponent`/`Timer` advanced by `update(dt)`, NOT by a wall-clock (`DateTime`/`Future.delayed`) timer. When the app backgrounds, `FlameGame` stops the ticker (`pauseWhenBackgrounded=true` default), so a frame-ticked timer *pauses* and resumes from where it left off on foreground — exactly TR-petstate-004's requirement. A wall-clock timer would keep counting while backgrounded and the animation would appear to have "jumped." (Confirmed against 1.37 source — see Engine Compatibility.) Note: `AppLifecycleState.inactive` alone (brief control-center swipe, call banner) does NOT pause — only `paused`/`detached`/`hidden` — which is the correct "actually backgrounded" boundary.

**Prefer one clock per triggered state.** For triggered states whose visual is a Flame `Effect` (EXCITED scale-bounce, SHOWING_OFF 360° spin), drive the state's lifecycle off that `Effect`'s own `onComplete` rather than running a separate parallel `TimerComponent` — one clock avoids drift if a duration is ever edited in only one place. If reusing a single `Timer` across activations, call `.start()` on retrigger (not just mutate `.limit` — a stopped timer won't restart on a `.limit` change); simpler and review-safer is to construct a fresh `TimerComponent` per activation (matches the "reset the timer" language in §3 literally).

**5. Events consumed from the Bridge (per ADR-0004).**
Triggers: `taskApproved → EXCITED` · `petInteracted → PLEASED` · `itemEquipped → SHOWING_OFF` · `seedReceived → BOUNCING` · `petLeveledUp → LEVELING_UP`. Plus `petMoodChanged → cache _baseMood` (Decision §1 — the Base-Mood the component returns to and gates SLEEPING against). All handled in one `_onEvent` switch. `MochiComponent` subscribes in `onMount()`, guards with `isMounted`, cancels in `onRemove()` (ADR-0004). Each handler switches on `event.type` before casting (payload-per-type rule). Rapid same-type events clear the prior effect before applying the next (`_clearEffects()` — **required correctness for transform effects, see Risks**, not just polish).

> **Clarification (2026-07-16, Pet State Machine Story 003 code review)**: "rapid same-type events clear the prior effect" describes what happens when a *higher-priority* retrigger replaces the current triggered state (e.g. LEVELING_UP interrupting a lower-priority state) — `_clearEffects()` fires as part of that replace path. It does NOT mean a same-priority same-type retrigger (e.g. a second EXCITED arriving while EXCITED is already playing) reaches `_clearEffects()` — per Decision §3's strict `priority(t) > priority(_current!)` comparison, an equal-priority retrigger is ignored entirely and never reaches `_play()`. Story 003's own test suite (`mochi_component_triggered_state_test.dart`) validates the clear-before-add invariant using a genuinely higher-priority interrupt (LEVELING_UP), not a literal same-type retrigger, which is unsatisfiable under this ADR's own priority rule.

### Architecture Diagram
```
energyProvider (ADR-0005) ──► petMoodProvider : Provider<MoodState>   [RIVERPOD, Base Mood]
   │  energy→mood lookup (owned here); emits petMoodChanged only on band change
   ▼
GameEventBus (ADR-0004) ──► MochiComponent (onMount subscribe)         [FLAME, Triggered State]
   triggers: taskApproved→EXCITED, petInteracted→PLEASED, itemEquipped→SHOWING_OFF,
             seedReceived→BOUNCING, petLeveledUp→LEVELING_UP
   base:     petMoodChanged→cache _baseMood (return-to target + SLEEPING gate; seeded once at cold start)
        │  priority: LEVELING_UP > EXCITED > SHOWING_OFF > PLEASED > BOUNCING
        │  LEVELING_UP non-interruptible (others queue + replay)
        │  TimerComponent (frame-ticked → pauses with loop on background)
        ▼
   render: triggered animation for duration → clear → Base Mood animation
   (Triggered State is NEVER persisted, NEVER mirrored to Riverpod)
```

### Key Interfaces
```dart
enum MoodState { happy, content, tired, sad, sleeping }
enum TriggeredState { levelingUp, excited, showingOff, pleased, bouncing }

// RIVERPOD — Base Mood, pure derivation, testable. Owned here.
final petMoodProvider = Provider<MoodState>((ref) {
  final energy = ref.watch(energyProvider);   // ADR-0005
  return _moodForEnergy(energy);              // the lookup this ADR owns
});
// petEnergyProvider: the raw energy passthrough for the energy bar (0..100).

// FLAME — Triggered State, ephemeral. Inside MochiComponent:
//   MoodState? _baseMood;                   // cached from petMoodChanged (NOT ref.read); seeded at cold start
//   TriggeredState? _current;               // null = showing Base Mood (_baseMood)
//   TimerComponent? _timer;                 // frame-ticked; pauses with loop (see §4)
//   void _onEvent(GameEvent e) {
//     if (!isMounted) return;               // ADR-0004
//     switch (e.type) {                     // switch on type BEFORE casting data
//       case GameEventType.petMoodChanged: _baseMood = e.data as MoodState; break;  // cache, no Riverpod read
//       case GameEventType.taskApproved:    onTrigger(TriggeredState.excited); break;
//       // ... other trigger cases
//     }
//   }
//   void onTrigger(TriggeredState t) {
//     if (_current == TriggeredState.levelingUp) { _queueHighest(t); return; }       // non-interruptible
//     if (_baseMood == MoodState.sleeping && t != TriggeredState.excited && t != TriggeredState.levelingUp) return; // SLEEPING gate
//     if (_current == null || priority(t) > priority(_current!)) { _play(t); }        // else ignore
//   }
```
`priority`: `levelingUp:5, excited:4, showingOff:3, pleased:2, bouncing:1`. **Use this explicit map — never `TriggeredState.index`** (the enum is declared in the opposite order of priority; `.index` would invert it).

## Alternatives Considered

### Alternative A: Base Mood in Riverpod, Triggered State Flame-side (chosen)
- **Description**: The GDD's split — derived Base Mood provider + ephemeral Flame triggered state via TimerComponent.
- **Pros**: Base Mood is a pure, unit-testable derivation with no game-loop dependency; triggered state stays where it's used (animation) with zero cross-boundary chatter; frame-ticked timer gives correct background pause/resume for free.
- **Cons**: Two homes to reason about — but they map to two genuinely different concerns (persistent vs. ephemeral).
- **Rejection Reason**: N/A — chosen.

### Alternative B: Full state machine in Riverpod (both layers)
- **Description**: Model triggered states as Riverpod state too.
- **Pros**: One place for all state.
- **Cons**: Triggered state is pure animation ephemera with no consumer besides the sprite — pushing it into Riverpod adds provider churn and cross-boundary events for something the game loop already owns; and a Riverpod timer (wall-clock) wouldn't pause with the loop, breaking TR-petstate-004.
- **Rejection Reason**: Wrong home for animation-only state; breaks the background-pause requirement.

### Alternative C: Full state machine in Flame (both layers, incl. Base Mood)
- **Description**: Compute Base Mood inside the game loop too.
- **Pros**: One home (the component).
- **Cons**: Duplicates the energy→mood logic inside the loop instead of a pure, testable provider; makes Base Mood untestable without a running game; UI (energy bar, mood indicator) would need a Flame→Flutter path, violating one-way flow.
- **Rejection Reason**: Loses testability and would force a forbidden Flame→Flutter dependency.

## Consequences

### Positive
- Base Mood is trivially unit-testable (pure function of energy); the lookup has one owner (ends the ADR-0005 double-ownership).
- Triggered state stays ephemeral and loop-local — no persistence, no cross-boundary chatter.
- Frame-ticked timer makes background pause/resume correct by construction (pending verification).

### Negative
- The two-home split must be understood by implementers (documented here + diagram).
- Triggered-state priority/queue logic is bespoke (small, but must be tested).

### Risks
- **`TimerComponent` background behavior**: confirmed frame-ticked + auto-paused by `FlameGame` (Engine Compatibility). *Standing constraint*: **nothing may set `pauseWhenBackgrounded=false` on the shared `FlameGame`, and any override of `lifecycleStateChange()` must call `super`** — otherwise TR-petstate-004 breaks invisibly to this ADR (e.g. an audio ADR wanting BGM to continue backgrounded could be tempted to flip that flag; it must not, or must solve BGM another way). Tie this to whichever ADR owns the root `FlameGame` subclass (the Pet Room UI ADR).
- **Transform effects compound, they don't override.** `ScaleEffect`/`Transform2DEffect`-family apply incrementally (`scale += delta`), so two overlapping scale/spin effects on Mochi (e.g. EXCITED re-triggering without clearing) visibly overshoot. *Mitigation*: `_clearEffects()` (`removeWhere((c) => c is Effect)`) before adding the next effect is **required correctness for any transform-based triggered state**, not polish.
- **Component removal is next-tick, not synchronous.** `removeWhere`/`removeFromParent` enqueue removal; the old effect is still present (though flagged) until the queue drains. *Mitigation*: the "prior effect cleared before next" validation must assert after a subsequent `update()`/tick, not synchronously in the same call stack.
- **Subscription lifecycle** (per ADR-0004): subscribe in `onMount()`, `isMounted` guard, `cancel()` in `onRemove()` — forbidden to skip. *Mitigation*: inherited rule + review.
- **Payload mis-cast** (per ADR-0004): switch on `event.type` before casting. *Mitigation*: payload-per-type rule; the `_onEvent` switch (Key Interfaces) does this.
- **`_baseMood` null at cold start** (ref.listen fires only on change). *Mitigation*: cold-start seed (Decision §1) — emit `petMoodChanged` once with `ref.read(petMoodProvider)` at initial build, or pass into the constructor.
- **LEVELING_UP queue correctness**: a burst of triggers during LEVELING_UP must not lose the highest-priority one or replay a storm. *Mitigation*: queue keeps only the single highest-priority pending trigger; unit-tested.
- **No-op mood re-render**: emitting `petMoodChanged` on every energy tick would thrash the sprite. *Mitigation*: emit only on mood-band change (Decision §1).

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| pet-state-machine.md | Two-layer model: persistent Base Mood + temporary Triggered State (TR-petstate-001) | Decision §1 (two homes) |
| pet-state-machine.md | Mood = pure lookup on energy float (TR-petstate-002) | Decision §2 — the owned lookup (ADR-0005 delegation) |
| pet-state-machine.md | Triggered-state priority order + non-interruptible LEVELING_UP (TR-petstate-003) | Decision §3 |
| pet-state-machine.md | Triggered-state timers pause/resume correctly across app background (TR-petstate-004) | Decision §4 + Verification Required |
| time-decay.md | energy→mood table (delegated ownership) | Decision §2 — authoritative copy lives here |

## Performance Implications
- **CPU**: Base Mood is a lookup per energy change; triggered state is one component + one timer — negligible.
- **Memory**: A handful of sprite sets + one active timer; within budget.
- **Load Time**: None beyond sprite loading.
- **Network**: None — reads local providers/events only.
- **Rendering**: Mochi + triggered animation counts against ADR-0001's ≤200 Flame-canvas draw calls (well within — Pet Room's tally is 5).

## Migration Plan
Greenfield. No GDD sync required — the GDD already matches this architecture (two-layer model, priority order, TimerComponent, SHOWING_OFF particle delegated to #15). The energy→mood ownership was already annotated in `time-decay.md` during ADR-0005's GDD sync; this ADR is the receiving owner.

## Validation Criteria
- Unit (pure): `_moodForEnergy` returns the correct band at every boundary (10, 19/20, 49/50, 79/80, 100); no `petMoodChanged` emitted when energy changes within a band.
- Unit: trigger priority — higher-priority replaces + resets timer; lower/equal ignored; LEVELING_UP queues others and replays the single highest-priority one after 3s; SLEEPING accepts only EXCITED + LEVELING_UP.
- Component/manual: a triggered animation interrupted by app background **resumes** (not restart/skip) on foreground — the TR-petstate-004 acceptance check; this is also the Verification gate for TimerComponent behavior.
- Component: rapid same-type events clear the prior effect before the next (`_clearEffects`).

## Related Decisions
- ADR-0004 (Bridge) — event delivery + subscriber lifecycle this depends on.
- ADR-0005 (Time & Decay) — energy input; delegated the energy→mood lookup here.
- ADR-0001 (draw-call budget) — Mochi rendering counts against the Flame-canvas budget.
- Pet Leveling (#16) ADR (upcoming) — owns the `petLeveledUp` emission + evolution sprite swap that LEVELING_UP renders.
- Pet Equipment (#15) ADR (upcoming) — owns the SHOWING_OFF particle spec.
- `design/gdd/pet-state-machine.md` — the ratified design.
