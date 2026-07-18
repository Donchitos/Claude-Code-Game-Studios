# Story 004: Triggered-State Timer Backgrounding Pause/Resume

> **Epic**: Pet State Machine
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 2h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/pet-state-machine.md`
**Requirement**: `TR-petstate-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Pet State Machine Architecture, Decision §4 (frame-ticked timer, pause/resume) and Engine Compatibility (Verification Required)

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: LOW-MEDIUM — the underlying mechanism was already confirmed against real Flame 1.37.0 source during ADR authoring (`FlameGame` is a `WidgetsBindingObserver`, `pauseWhenBackgrounded=true` by default stops the ticker on background, so a frame-ticked timer pauses/resumes "by construction"). This story's job is to write the acceptance test the ADR itself calls out as the remaining open item, and to guard the standing constraint that nothing may quietly disable that behavior.

**Control Manifest Rules (this layer)**:
- Required: "Triggered-state duration driven by Flame's frame-ticked `TimerComponent`/`Timer` (`update(dt)`), NOT wall-clock" — source: ADR-0007
- Required: "Nothing may set `pauseWhenBackgrounded=false` on the shared `FlameGame`; any `lifecycleStateChange()` override must call `super`" — source: ADR-0007

## Already Established (do not re-derive)

- The mechanism itself is already source-verified (ADR-0007 Engine Compatibility: "Confirmed against Flame 1.37.0 source... no open unknown"): `FlameGame`'s default `pauseWhenBackgrounded=true` stops the game loop's ticker on `AppLifecycleState.paused`/`detached`/`hidden` (NOT on `inactive` alone — a brief control-center swipe or call banner does not pause). This story does not need to re-derive or re-verify that mechanism from scratch; it writes the test that exercises it and asserts the standing constraint holds.
- Story 003's `TriggeredState` machine and `TimerComponent` usage must already exist — this story needs an active triggered state with a running timer to pause against.

---

## Acceptance Criteria

*From ADR-0007 Decision §4, Risks, and Validation Criteria:*

- [x] A triggered-state animation interrupted by the game pausing (`FlameGame.pauseEngine()`, simulating `AppLifecycleState.paused`/`detached`/`hidden`) does NOT advance its timer while paused — confirmed by ticking simulated time forward during the pause and observing the triggered state has not changed/completed.
- [x] On resume (`FlameGame.resumeEngine()`), the timer continues counting from exactly where it left off — it does not restart from zero and does not skip/fast-forward to account for the paused duration.
- [x] `AppLifecycleState.inactive` alone (the brief, non-backgrounded case) does NOT pause the timer — only `paused`/`detached`/`hidden` do. If the root `FlameGame` doesn't already distinguish these (Flame's default behavior should), this story's test documents and confirms the distinction rather than assuming it.
- [x] A static/inspection check (or equivalent code-review-checklist item, documented in this story if a fully automated check isn't practical) confirms `pauseWhenBackgrounded` is never set to `false` anywhere on the shared root `FlameGame`, and any `lifecycleStateChange()` override (if one exists anywhere in the codebase) calls `super.lifecycleStateChange(...)`.
- [x] The test scenario matches the ADR's own stated acceptance check verbatim: "a triggered animation interrupted by backgrounding → confirm resume" (not restart, not skip).

---

## Implementation Notes

*From ADR-0007 Decision §4 and Engine Compatibility:*

- This story is primarily a TEST story — the underlying pause/resume behavior is a property of Flame's `FlameGame`/`TimerComponent` used correctly (already true if Story 003 followed its own Implementation Notes), not new production code to write. If the test reveals a gap (e.g. some code path does disable `pauseWhenBackgrounded`), fix that gap as part of this story — but do not invent new pause/resume machinery; Flame's default behavior is what ADR-0007 relies on.
- `flame_test`'s `testWithFlameGame`/`testWithGame<T>` gives a real `FlameGame` instance — use `game.pauseEngine()` and `game.resumeEngine()` directly (verify these exact method names against the installed Flame 1.37.0 source before use, per this project's established practice of verifying post-cutoff-adjacent APIs rather than assuming) and confirm `update(dt)` calls made while paused do not advance any child `TimerComponent`'s progress.
- Recommended test shape: trigger a triggered state (e.g. EXCITED, 1.5s), advance time partway (e.g. 0.5s via `game.update(dt)` calls), call `pauseEngine()`, attempt further `update(dt)` calls (these should have no effect on the timer while paused — if `flame_test`'s harness doesn't naturally stop calling `update` on a paused game, this may require directly asserting the timer's internal progress value hasn't changed, or checking `game.paused`), call `resumeEngine()`, then advance the remaining 1.0s and confirm the triggered state completes (returns to Base Mood) at the correct total elapsed time, not early or late.
- If a genuinely automated test of `pauseEngine()`/`update(dt)` interaction proves impractical within `flame_test`'s harness (verify this empirically before assuming so), fall back to a documented manual/component verification step in this story's Test Evidence (per the ADR's own Validation Criteria: "Component/manual... this is also the Verification gate") — but attempt the automated route first, since `flame_test` gives direct access to a real `FlameGame` instance without needing an actual OS-level lifecycle event.

---

## Out of Scope

- Story 003 (this epic): the triggered-state priority/queue machine itself — this story only verifies its timer's pause/resume behavior, does not re-implement it.
- Any change to `FlameGame`'s default `pauseWhenBackgrounded` behavior — this story verifies the default is correct and never disabled, it does not modify Flame's own pause mechanism.
- The root `FlameGame` subclass's own definition/ownership — per ADR-0007's Risks section, that belongs to whichever ADR owns the Pet Room UI's `FlameGame` subclass (a future epic); this story only asserts the constraint holds wherever that subclass currently is (or notes if it doesn't exist yet, which would make part of this story's acceptance criteria N/A until that epic lands — flag this explicitly if encountered during implementation).

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. Derived directly from ADR-0007's Decision §4, Risks, and Validation Criteria sections:*

```
Test: a triggered-state timer does not advance while the game is paused
  Given: a MochiComponent with an active EXCITED triggered state (1.5s duration), 0.5s elapsed
    via update(dt) ticks
  When: game.pauseEngine() is called, then further time is simulated (either via update(dt) calls
    that should have no effect while paused, or by directly confirming the timer's progress is
    unchanged)
  Then: the triggered state is still EXCITED, not yet returned to Base Mood, and the timer's
    recorded progress matches the pre-pause 0.5s exactly (no drift)

Test: a paused triggered-state timer resumes from exactly where it left off, not from zero
  Given: the same paused-at-0.5s-of-1.5s scenario above
  When: game.resumeEngine() is called, then update(dt) ticks advance the remaining 1.0s
  Then: the triggered state completes (returns to Base Mood) at exactly 1.0s of further simulated
    time after resume — not immediately (which would mean it ignored the pause and kept a stale
    total), and not requiring a fresh 1.5s (which would mean it incorrectly restarted)

Test: game.paused reflects pauseEngine()/resumeEngine() state correctly
  Given: a fresh FlameGame (via flame_test)
  When: pauseEngine() is called, then resumeEngine()
  Then: game.paused is true after pauseEngine(), false after resumeEngine() — confirms the
    harness-level pause state this story's other tests depend on is itself correct

Test: pauseWhenBackgrounded is never disabled on the shared root FlameGame
  Given: the codebase's FlameGame subclass(es), if any exist yet
  When: inspected (static check)
  Then: pauseWhenBackgrounded is never explicitly set to false, and any lifecycleStateChange()
    override calls super.lifecycleStateChange(...)
  Edge cases: if no root FlameGame subclass exists yet in the codebase at implementation time,
    document this as N/A-for-now rather than fabricating a check against nothing — flag it as a
    follow-up for whichever future epic introduces that subclass
```

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/pet_state_machine/mochi_component_background_pause_test.dart` — must exist and pass

**Status**: [x] Created — `tests/integration/pet_state_machine/mochi_component_background_pause_test.dart`, 8 tests, all passing.

---

## Dependencies

- Depends on: Story 003 (this epic) — needs an active `TriggeredState`/`TimerComponent` to pause against.
- Unlocks: None within this epic — this is the epic's final story. Unlocks confident downstream use of triggered states by Pet Interaction (#14), Pet Equipment (#15), Pet Leveling (#16), Seed Buffer (#10), all of which rely on this pause/resume guarantee holding.

---

## Completion Notes

**Implementation**: No new production code — as anticipated, this story is purely verification (Stories 002/003's `MochiComponent`/`TimerComponent`/`Effect` usage already implements the correct mechanism via Flame's own default behavior).

**Real design finding, central to this story**: `FlameGame.pauseEngine()`/`resumeEngine()` only stop/start the REAL `GameRenderBox`'s `GameLoop` (verified against installed Flame 1.37.0 source), which wraps a real Flutter `Ticker` — neither exists in `flame_test`'s headless `testWithFlameGame` harness. Critically, `FlameGame.updateTree(dt)` does NOT check `paused` at all — pause is enforced entirely by the ticker scheduler choosing not to invoke `update()`, not by `update()` self-guarding. This means naively calling `game.update(dt)` after `pauseEngine()` in a headless test would still tick everything and prove nothing. Discovered by reading Flame's own bundled test suite (`~/.pub-cache/hosted/pub.dev/flame-1.37.0/test/game/flame_game_test.dart:340-356`), which uses `game.lifecycleStateChange(AppLifecycleState.paused)` + `game.paused` bookkeeping directly rather than relying on a real ticker.

**Test design, informed by that finding**: two groups. (1) `game.paused`/`lifecycleStateChange()` bookkeeping tested fully real, no faking — confirms `pauseWhenBackgrounded=true` by default, `paused`/`detached`/`hidden` all pause, `inactive` alone does not (matches ADR-0007's explicit claim, independently re-verified against source: `flame_game.dart`'s lifecycle switch groups `inactive` with `resumed`, not with the pausing states). (2) A `_advanceRespectingPause()` helper that only calls `game.update(dt)` while `!game.paused` — explicitly modeling the real ticker's gating behavior (not a tautology, since group 1 independently proves `game.paused` itself is real, unmocked Flame state) — used to verify both an Effect-driven (EXCITED) and a TimerComponent-driven (LEVELING_UP) triggered state correctly stop advancing while paused and resume from exactly where they left off, not restarted or skipped.

**Code review**: `flame-specialist` — **APPROVED WITH SUGGESTIONS**, zero required changes. Independently re-verified every source claim above against the installed Flame 1.37.0 package. Confirmed the `_advanceRespectingPause` design is legitimate, not circular. One suggestion (not required, spun off as a follow-up task rather than blocking this story): `flame_test` also exposes `testGameWidget`/`GameWidgetTester`, which pumps a real `GameWidget` giving a genuine `GameRenderBox → GameLoop → Ticker` pipeline — rewriting the pause/resume tests on top of that would be strictly more direct evidence than the modeled helper. Also confirmed the final "no `FlameGame` subclass exists yet" placeholder test is a legitimate, non-fabricated N/A guard (grepped `lib/` directly to confirm), not a check against nothing.

**Tests**: `tests/integration/pet_state_machine/mochi_component_background_pause_test.dart` — 8 tests, all passing: `pauseWhenBackgrounded` true by default, `paused`/`detached`/`hidden` all pause, `inactive` alone does not, `resumed` un-pauses, a triggered-state timer does not advance while paused, a paused timer resumes from exactly where it left off, LEVELING_UP's `TimerComponent`-driven mechanism also pauses/resumes correctly (not just the Effect-driven one), and the N/A placeholder for the standing `pauseWhenBackgrounded` constraint.

**Follow-up completed (2026-07-16, same day, per user request)**: `flame-specialist`'s one suggestion — a stronger real-`GameWidget`/real-`Ticker` variant of these tests — was implemented rather than left as a background task. New file: `tests/integration/pet_state_machine/mochi_component_background_pause_real_ticker_test.dart`, 3 tests, using `flame_test`'s `FlameTester.testGameWidget` (pumps a real `GameWidget` inside `tester.runAsync`, giving a genuine `GameRenderBox → GameLoop → Ticker` pipeline) + `WidgetsBinding.instance.handleAppLifecycleStateChanged(...)` for real OS-level lifecycle events. Verifies both the Effect-driven (EXCITED) and TimerComponent-driven (LEVELING_UP) mechanisms pause/resume correctly through the actual production pause pathway, plus the `inactive`-does-not-pause case.

**Real finding during this follow-up, root-caused and resolved**: an initial version using single large `tester.pump(duration)` calls produced results that looked like the triggered-state progress was being reset/lost across a pause/resume cycle — investigated via direct instrumentation of `MochiComponent.scale.x` (a temporary debug build, since removed) rather than accepted at face value. Root cause: (1) a single large `tester.pump(duration)` call does not reliably deliver that much effective `dt` to the real ticker in this harness — switched to a loop of many small pumps (`_pumpRealTicker`), which is also how a real device actually drives the ticker one frame at a time; (2) once measured correctly, progress WAS being preserved correctly across pause/resume — the apparent "reset" was a measurement artifact of the single-large-pump approach, not a real bug. A separate, genuinely real, benign artifact was also found and documented: the real ticker's first callback after any `GameLoop.start()` (both the initial mount and every resume-from-pause) reports a near-zero `dt`, costing roughly one frame's worth of real progress at each such boundary — documented in ADR-0007's Verification Required field (2026-07-16 addendum) and handled with a small overshoot margin in the new tests, the same pattern as `_tolerance` in the sibling simulated-pause test file for its own distinct floating-point artifact.

**Tests (follow-up)**: `tests/integration/pet_state_machine/mochi_component_background_pause_real_ticker_test.dart` — 3 tests, all passing, verified stable across repeated runs: Effect-driven (EXCITED) pause/resume through the real ticker, TimerComponent-driven (LEVELING_UP) pause/resume through the real ticker, `inactive` alone does not pause the real ticker.

**Deviations from scope**: None.
**Manifest version**: 2026-07-16 (current at time of implementation — no drift).
