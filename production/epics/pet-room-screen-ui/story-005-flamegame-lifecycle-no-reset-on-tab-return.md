# Story 005: FlameGame Lifecycle — Never Init/Reset on Tab Return

> **Epic**: Pet Room Screen UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: 1-2h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-23

## Context

**GDD**: `design/gdd/pet-room-screen-ui.md`
**Requirement**: `TR-petroom-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: Pet Room Screen Rendering & Interaction Contract (Decision → TR-petroom-005) + ADR-0014 (Navigation Shell — `StatefulShellRoute`/`IndexedStack` never-dispose guarantee this story relies on).
**ADR Decision Summary**: Ratifies the existing `src/lib/ui/pet_room_screen.dart` pattern (`final PetRoomGame _game = PetRoomGame();` as a `State` field, constructed once, reused across every `build()`) as the permanent, binding pattern — no code change required for the happy path, since ADR-0014 Story 002 already implemented and tested it (AC-5). What this story adds: two explicit, enforceable forbidden patterns for every future Pet Room story, plus the regression/lint check that verifies them.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: LOW (ratifies already-correct, already-tested code; this story's own work is a code-review/static check, not new runtime behavior)
**Engine Notes**: `StatefulShellRoute`'s `IndexedStack` never disposes an inactive branch (ADR-0014) — `PetRoomGame`'s `GameLoop` drives itself via a raw `Ticker`, bypassing `TickerProvider`/`TickerMode`, so it is never muted by the `TickerMode(enabled: false)` wrapper above an inactive branch. This is why triggered-state animations can complete off-screen (GDD Core Rule 9) without any special-case code in this story.

**Control Manifest Rules (this layer)**:
- Required: `PetRoomGame()` construction happens exactly once, in the `State`'s field declaration/`initState()` — never inline inside `build()` (source: ADR-0017 Decision → TR-petroom-005).
- Forbidden: calling any lifecycle-reset-shaped method (`game.reset()`, manually re-invoking `onLoad()`, removing-then-re-adding the full component tree) from any "on tab return" hook, including a future `activeChildBranchIndexProvider` listener (source: ADR-0017 Decision → TR-petroom-005; `docs/registry/architecture.yaml`'s `activeChildBranchIndexProvider` entry already cites this TR-ID).
- Required: if Pet Room ever needs to know "am I the active tab," it reads `activeChildBranchIndexProvider` — but must not use that signal to trigger any `FlameGame` init/reset call (source: ADR-0017).

---

## Acceptance Criteria

*From GDD `design/gdd/pet-room-screen-ui.md`, scoped to this story:*

- [ ] **AC-CR9-1**: GIVEN a triggered-state animation (BOUNCING/EXCITED/LEVELING_UP) starts while bé is on `/child/pet-room`, WHEN bé switches to another tab before it finishes, THEN the Flame game loop is NOT disposed/paused — the animation continues to completion even though nothing is watching.
- [ ] **AC-CR9-2**: GIVEN the animation finished while bé was on another tab, WHEN bé returns to `/child/pet-room`, THEN Mochi displays the correct final (post-animation) state — no replay, no snap back to the pre-animation state.
- [ ] **AC-TR005-1** (regression/static check): no `PetRoomGame(` constructor call exists anywhere outside `_PetRoomScreenState`'s field declaration.

---

## Implementation Notes

*Derived from ADR-0017 Decision → TR-petroom-005:*

- **No functional code change is required** for AC-CR9-1/AC-CR9-2 — `src/lib/ui/pet_room_screen.dart`'s existing `_game` `State` field + `GameWidget<PetRoomGame>(game: _game)` line, combined with ADR-0014's already-implemented, already-tested `StatefulShellRoute`/`IndexedStack` guarantee (AC-5, main-navigation-shell Story 002), already satisfies this behavior. This story's job is to (a) add a regression test that specifically exercises Pet Room's own screen (not just the generic Navigation Shell placeholder test) with a real triggered-state animation running, and (b) add the static/lint check for AC-TR005-1.
- **AC-TR005-1 static check**: a `grep`-based or `analyzer`-based check (implementer's choice, document whichever is used) confirming `PetRoomGame(` appears exactly once in `src/lib/ui/pet_room_screen.dart` (the field declaration) and nowhere else in `src/lib/`. This can be a lightweight test-suite check (e.g. a `test()` that greps the source tree) rather than a full custom lint rule, consistent with this story's LOW risk / small estimate.
- Do not add a `activeChildBranchIndexProvider` listener to `PetRoomScreen` as part of this story — the GDD does not require one yet, and ADR-0017 only pre-emptively forbids what such a listener must NOT do if one is ever added later.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Any new "on tab return" behavior beyond what already exists — this story is a ratification + guard, not a new feature.
- Story 003's component tree / Story 004's modal-defer mechanism — both already correctly assume the singleton `_game` field this story ratifies; no change needed here to accommodate them.

---

## QA Test Cases

*Concrete test cases (lean review mode — written directly into the story, no qa-lead gate spawned per `production/review-mode.txt`).*

- **AC-CR9-1**: Given `/child/pet-room` is active and a triggered-state animation is started on `MochiComponent` (e.g. via `onTrigger(TriggeredState.bouncing)`) — When: the app navigates to a different tab (simulated via the shell's branch-switch mechanism, matching ADR-0014 Story 002's AC-5 test pattern) — Then: assert `PetRoomGame.updateTickCount` (or the real animation's internal timer/effect) keeps advancing while the branch is offstage — same harness pattern as `tests/integration/main-navigation-shell/` uses for AC-5.
- **AC-CR9-2**: Given the animation completes while the branch is offstage — When: the app navigates back to `/child/pet-room` — Then: assert `MochiComponent.currentTriggeredState == null` (animation finished, state settled) and no animation restarts.
- **AC-TR005-1**: Given the full `src/lib/` source tree — When: grepping for `PetRoomGame(` — Then: assert exactly 1 match, located in `src/lib/ui/pet_room_screen.dart`'s `_PetRoomScreenState` field declaration.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/pet-room-screen-ui/flamegame_lifecycle_test.dart` — must exist and pass. Relies on and does not duplicate ADR-0014 Story 002's existing AC-5 test.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (ratifies already-existing, already-tested code)
- Unlocks: None
