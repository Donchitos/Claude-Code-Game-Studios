# Story 001: Base Mood Pure Lookup + Providers

> **Epic**: Pet State Machine
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/pet-state-machine.md`
**Requirement**: `TR-petstate-002`, `TR-petstate-001` (Base Mood layer half only — the Triggered-state layer is Stories 002-004)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Pet State Machine Architecture, Decision §1 (Base Mood home) and §2 (energy→mood lookup)

**Engine**: Dart / `flutter_riverpod ^3.3.2` | **Risk**: LOW — pure lookup + Riverpod derivation, no Flame/game-loop dependency, no post-cutoff API surface for this story specifically (the ADR's MEDIUM risk rating is driven entirely by Flame `TimerComponent` semantics, which belong to Stories 003/004).

**Control Manifest Rules (this layer)**:
- Required: "Base Mood is a pure Riverpod derivation (`petMoodProvider`) from `energyProvider`" — source: ADR-0007
- Required: "Energy→mood lookup (owned here): SLEEPING=10, SAD 11–19, TIRED 20–49, CONTENT 50–79, HAPPY ≥80" — source: ADR-0007
- Required: "Emit `petMoodChanged` only when the mood BAND changes, not every energy tick" — source: ADR-0007 (the emission mechanism itself — the widget-level `ref.listen` bridge adapter — is Story 002's scope; this story only needs `petMoodProvider` to *produce a value that changes only on band crossings*, which it does automatically as a pure function of `energyProvider`)
- Forbidden: "Never compute Base Mood inside the Flame game loop — untestable, forces a forbidden Flame→Flutter path for UI" — source: ADR-0007

---

## Acceptance Criteria

*From `design/gdd/pet-state-machine.md`'s Formulas section and ADR-0007 Decision §2 + Validation Criteria:*

- [x] `_moodForEnergy(double energy) -> MoodState` returns the correct band at every documented value and boundary: `energy == 10 → sleeping`, `10 < energy <= 19 → sad`, `20 <= energy <= 49 → tired`, `50 <= energy <= 79 → content`, `energy >= 80 → happy`.
- [x] Boundary values are tested explicitly: 10, 19, 20, 49, 50, 79, 80, 100 (the exact edges where the GDD's table and ADR-0007 §2 could disagree with an off-by-one implementation).
- [x] `petMoodProvider` (`Provider<MoodState>`) watches `energyProvider` (Time & Decay, ADR-0005) and returns `_moodForEnergy(energy)` — a pure derivation, no independent state.
- [x] `petEnergyProvider` (`Provider<double>`) is a passthrough of `energyProvider`'s raw value (0–100 range) for the energy bar — exists as its own provider per ADR-0007 Key Interfaces, not something callers derive by re-reading `energyProvider` directly (keeps the Base-Mood surface self-contained per the ADR's stated intent).
- [x] `MoodState` enum matches ADR-0007 Key Interfaces exactly: `{ happy, content, tired, sad, sleeping }` (this declared order is NOT the priority order — no priority applies to Base Mood, only Triggered States in Story 003).

---

## Implementation Notes

*From ADR-0007 Decision §1-§2 and Key Interfaces (the exact provider shapes to implement):*

```dart
enum MoodState { happy, content, tired, sad, sleeping }

final petMoodProvider = Provider<MoodState>((ref) {
  final energy = ref.watch(energyProvider);   // ADR-0005, Time & Decay #2 — already exists
  return _moodForEnergy(energy);              // the lookup this ADR owns
});
// petEnergyProvider: the raw energy passthrough for the energy bar (0..100).
final petEnergyProvider = Provider<double>((ref) => ref.watch(energyProvider));
```
- `_moodForEnergy` should be a private top-level function (or a `@visibleForTesting` one, matching this project's established pattern for pure calculation helpers — see `computeEnergy` in `src/lib/core/compute_energy.dart`, Time & Decay Story 001) so it is directly unit-testable without going through the provider layer.
- This story does not emit `petMoodChanged` — that is the widget-level `ref.listen` adapter, Story 002's scope (ADR-0004's sanctioned emit-adapter rule: only a `ConsumerWidget`'s `ref.listen`, never inside the provider itself, may push onto `GameEventBus`).
- File location: follow this project's established `lib/providers/` convention (see `src/lib/providers/time_decay_providers.dart`) — likely `src/lib/providers/pet_state_providers.dart`, keeping `MoodState`/`_moodForEnergy` either in the same file or a small `src/lib/core/pet_mood.dart` pure-logic file, whichever better matches how `compute_energy.dart` was kept separate from `time_decay_providers.dart` in the sibling epic. Prefer the separated-file approach for consistency with that precedent.

---

## Out of Scope

- Story 002 (this epic): the `ref.listen` widget-level bridge adapter that actually emits `petMoodChanged` onto `GameEventBus`, plus `MochiComponent`'s caching of `_baseMood` from that event and the cold-start seed requirement.
- Story 003 (this epic): `TriggeredState`, priority ordering, LEVELING_UP non-interruptibility, SLEEPING gate — none of that is Base Mood.
- Story 004 (this epic): background pause/resume of triggered-state timers — irrelevant to this story, which has no timer at all.
- `TriggeredState` enum and any Flame code — this story is pure Dart/Riverpod only, no Flame import.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. ADR-0007's Validation Criteria specifies the required coverage:*

> "Unit (pure): `_moodForEnergy` returns the correct band at every boundary (10, 19/20, 49/50, 79/80, 100); no `petMoodChanged` emitted when energy changes within a band." (the "no petMoodChanged emitted" half is Story 002's concern, since emission doesn't exist yet in this story — covered here only as "petMoodProvider's *value* doesn't change within a band," the precondition Story 002's emit-adapter relies on)

```
Test: energy exactly 10 returns sleeping
  Given: energy = 10
  When: _moodForEnergy(energy) is called
  Then: returns MoodState.sleeping

Test: energy in the sad band (11-19) returns sad
  Given: energy = 19 (upper boundary) and energy = 11 (lower boundary, just above sleeping)
  When: _moodForEnergy(energy) is called for each
  Then: both return MoodState.sad

Test: energy 20 (tired lower boundary) returns tired, not sad
  Given: energy = 20
  When: _moodForEnergy(energy) is called
  Then: returns MoodState.tired (proves the 19/20 boundary is correctly exclusive/inclusive per the ADR table)

Test: energy 49 (tired upper boundary) returns tired, not content
  Given: energy = 49
  When: _moodForEnergy(energy) is called
  Then: returns MoodState.tired

Test: energy 50 (content lower boundary) returns content, not tired
  Given: energy = 50
  When: _moodForEnergy(energy) is called
  Then: returns MoodState.content

Test: energy 79 (content upper boundary) returns content, not happy
  Given: energy = 79
  When: _moodForEnergy(energy) is called
  Then: returns MoodState.content

Test: energy 80 (happy lower boundary) returns happy
  Given: energy = 80
  When: _moodForEnergy(energy) is called
  Then: returns MoodState.happy

Test: energy 100 (maximum) returns happy
  Given: energy = 100
  When: _moodForEnergy(energy) is called
  Then: returns MoodState.happy

Test: petMoodProvider derives from energyProvider without independent state
  Given: energyProvider overridden to return a fixed value (e.g. 85.0)
  When: petMoodProvider is read
  Then: returns the same MoodState _moodForEnergy(85.0) would produce directly (cross-check
    against the pure function, not a hardcoded expectation)

Test: petMoodProvider value is stable within a mood band (precondition for Story 002's
  "no petMoodChanged on same-band change" requirement)
  Given: energyProvider overridden to 85.0, then to 90.0 (both HAPPY band)
  When: petMoodProvider is read before and after the energyProvider change
  Then: both reads return MoodState.happy (same value — proves no spurious band-crossing)

Test: petEnergyProvider passes through energyProvider's raw value unchanged
  Given: energyProvider overridden to a fixed value (e.g. 42.5)
  When: petEnergyProvider is read
  Then: returns exactly 42.5
```

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/pet_state_machine/pet_mood_provider_test.dart` — must exist and pass

**Status**: [x] Created — `tests/unit/pet_state_machine/pet_mood_provider_test.dart`, 11 tests, all passing.

---

## Dependencies

- Depends on: Time & Decay epic (Complete) — `energyProvider` must exist. Already satisfied.
- Unlocks: Story 002 (this epic) — the bridge wiring reads `petMoodProvider`'s value to seed/emit `petMoodChanged`.

---

## Completion Notes

**Implementation**: `src/lib/core/pet_mood.dart` — `MoodState` enum (`{happy, content, tired, sad, sleeping}`, matching ADR-0007 Key Interfaces exactly) and public `moodForEnergy(double energy)` (a cumulative `<=` ladder producing identical results to the ADR's discrete bands at every boundary). `src/lib/providers/pet_state_providers.dart` — `petMoodProvider` (pure `ref.watch(energyProvider)` derivation, no independent state) and `petEnergyProvider` (passthrough), following the `compute_energy.dart`/`time_decay_providers.dart` file-separation precedent from Time & Decay Story 001.

**Real finding, fixed during implementation**: `moodForEnergy` was initially marked `@visibleForTesting`, following the story's own Implementation Notes suggestion ("a private top-level function (or a `@visibleForTesting` one)"). `flutter analyze` correctly flagged this as `invalid_use_of_visible_for_testing_member` — the function has a genuine production caller (`petMoodProvider`), so `@visibleForTesting` was the wrong choice (that annotation is for test-only-exposed helpers with no real caller outside tests). Fixed by making it a plain public function; `flame-specialist` review independently confirmed this was the only correct fix.

**Tests**: `tests/unit/pet_state_machine/pet_mood_provider_test.dart` — 11 tests, all passing: all 8 documented boundary values (10, 11/19, 20, 49, 50, 79, 80, 100), `petMoodProvider` cross-checked against `moodForEnergy` directly (not a hardcoded expectation), a same-band-stability test (the precondition Story 002's "emit only on band change" behavior relies on), and `petEnergyProvider`'s passthrough.

**Code review**: `flame-specialist` — **APPROVED**, zero required changes. Confirmed boundary correctness, enum order, no Riverpod anti-patterns, no forbidden Flame imports, and independently verified the `@visibleForTesting` fix was correct.

**Deviations from scope**: None.
**Manifest version**: 2026-07-16 (current at time of implementation — no drift).
