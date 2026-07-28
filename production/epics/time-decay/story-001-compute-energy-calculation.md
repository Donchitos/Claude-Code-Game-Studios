# Story 001: computeEnergy Pure Calculation

> **Epic**: Time & Decay
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/time-decay.md`
**Requirement**: `TR-time-decay-001`, `TR-time-decay-002`, `TR-time-decay-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Time & Decay Calculation Strategy, Decision §1, §2, §3

**Engine**: Dart (pure — no Flutter, no Flame, no Firestore) | **Risk**: LOW — pure `DateTime`/`Duration` arithmetic, no engine API surface. ADR-0005 already confirms timezone/DST is a non-issue by construction (`.difference()` operates on the absolute instant regardless of either operand's zone flag).

**Control Manifest Rules (this layer)**:
- Required: "`computeEnergy` is evaluated ONLY on app-foreground/resume — no timer, no per-second recalculation" — source: ADR-0005 (this story's function itself has no knowledge of *when* it's called — that's Story 002's concern — but must not be written in a way that invites per-tick calling, e.g. no internal caching that assumes single-call-per-session)
- Required: "`computeEnergy` is pure/side-effect-free and performs no Firestore writes" — source: ADR-0005
- Required: "Use `now.difference(lastApprovedAt)` (`Duration`), NOT `now - lastApprovedAt` (no `operator-` on `DateTime`)" — source: ADR-0005
- Required: "Clamp `hoursElapsed` to `[0, maxHoursElapsed]` (default 168) — clock-manipulation guard" — source: ADR-0005
- Required: "Use `elapsed.inMicroseconds / Duration.microsecondsPerHour`, NOT `inMinutes / 60.0` (truncates sub-minute elapsed to 0)" — source: ADR-0005
- Required: "`now` MUST be injected into `computeEnergy`, never read from the wall clock inside it" — source: ADR-0005
- Required: "Null `lastApprovedAt` (new profile) → use `createdAt` baseline, treat `storedEnergy` as `initialEnergy = 70`; never crash on null" — source: ADR-0005
- Forbidden: implementing the energy→mood lookup table here — that's Pet State Machine's (#6) ownership per ADR-0005 Decision §4; this story outputs a `double` only.
- Forbidden: implementing the recovery formula (`newEnergy = min(100, currentEnergy + energyReward)`) here — per ADR-0005 §5, recovery is computed inside Parent Approval's (#11) transaction, not here.

---

## Acceptance Criteria

*From `design/gdd/time-decay.md`'s Formulas and Acceptance Criteria sections, and ADR-0005 Decision §1–3:*

- [x] `computeEnergy({required storedEnergy, required lastApprovedAt, required createdAt, required now, decayRate = 3.0, minEnergy = 10, maxEnergy = 100, maxHoursElapsed = 168})` returns `max(minEnergy, storedEnergy - hoursElapsed * decayRate)`, clamped to `[minEnergy, maxEnergy]`.
- [x] 8 hours elapsed from `storedEnergy = 100` → returns `76` (the GDD's own calibration check).
- [x] 24 hours elapsed from `storedEnergy = 100` → returns `28`.
- [x] 48 hours elapsed from `storedEnergy = 100` → returns `10` (floored at `minEnergy`).
- [x] `lastApprovedAt == null` → uses `createdAt` as the baseline for elapsed-time calculation, and treats `storedEnergy` as `initialEnergy = 70` regardless of whatever `storedEnergy` value was passed in — does not crash.
- [x] Negative elapsed time (`now` before `lastApprovedAt` — clock set backward) → `hoursElapsed` clamps to `0`, so `computeEnergy` returns exactly `storedEnergy` unchanged (no free energy from clock manipulation).
- [x] Elapsed time exceeding `maxHoursElapsed` (168h default) → `hoursElapsed` clamps to `maxHoursElapsed`, producing the same floored-at-`minEnergy` result as any longer elapsed duration (e.g. 200h and 1000h both floor to the same value as 168h).
- [x] The function uses `now.difference(lastApprovedAt)` and `.inMicroseconds / Duration.microsecondsPerHour` exactly as the manifest requires — verified by a test that would fail if either substitution (`now - lastApprovedAt` or `.inMinutes / 60.0`) were used instead (a sub-minute elapsed duration test catches the `inMinutes` truncation bug specifically).
- [x] `now` is a required named parameter, never read from `DateTime.now()` inside the function body — verified by the function producing identical output across repeated calls with the same fixed `now` (no hidden wall-clock dependency).

---

## Implementation Notes

*From ADR-0005 Decision §1–3 and Key Interfaces (the exact function signature to implement):*

```dart
double computeEnergy({
  required double storedEnergy,
  required DateTime? lastApprovedAt,
  required DateTime createdAt,
  required DateTime now,
  double decayRate = 3.0,
  double minEnergy = 10,
  double maxEnergy = 100,
  double maxHoursElapsed = 168,
});
```
- Resolve the baseline: if `lastApprovedAt == null`, the elapsed-time calculation uses `createdAt` as the reference point AND `storedEnergy` is treated as `initialEnergy = 70` — both substitutions happen together for the null case, not just one.
- `hoursElapsed` computation: `now.difference(effectiveLastApprovedAt).inMicroseconds / Duration.microsecondsPerHour`, then `.clamp(0.0, maxHoursElapsed)` (note: `num.clamp` returns `num`, so `.toDouble()` the result to satisfy a `double` target — the manifest's own snippet shows this exact gotcha).
- Final result: `(effectiveStoredEnergy - hoursElapsed * decayRate).clamp(minEnergy, maxEnergy)`.
- This story does not need to import `cloud_firestore` or `flutter_riverpod` at all — keep it pure Dart, matching `pin_crypto.dart`'s existing precedent for a self-contained, dependency-free calculation module in `lib/core/`.

---

## Out of Scope

- Story 002 (this epic): the `energyProvider` Riverpod wiring, the Firestore-backed read of `storedEnergy`/`lastApprovedAt`/`createdAt`, and the `resumeTickProvider`/`AppLifecycleListener` plumbing that actually calls this function with a real `now`.
- The energy→mood lookup table — owned by Pet State Machine (#6) per ADR-0005 Decision §4; this story's copy of the table (if referenced in comments) is documentation only.
- The recovery formula (`+energyReward`) — Parent Approval's (#11) responsibility, computed inside its own transaction, not here.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. ADR-0005's Validation Criteria specifies the required coverage:*

> "Unit (deterministic, injected `now`): 8h→76 (CONTENT), 24h→28 (TIRED), 48h→10 (SLEEPING); recovery cases per the GDD's calibration table." (the recovery half is Parent Approval's story, not tested here — see Out of Scope)
> "Unit: negative elapsed (clock back) → clamp 0, energy unchanged; elapsed > 168h → floors at 10."
> "Unit: null `lastApprovedAt` → uses `createdAt`, `storedEnergy` treated as 70, no crash."

```
Test: 8 hours elapsed from full energy
  Given: storedEnergy=100, lastApprovedAt=T, now=T+8h
  When: computeEnergy is called
  Then: returns 76.0

Test: 24 hours elapsed from full energy
  Given: storedEnergy=100, lastApprovedAt=T, now=T+24h
  When: computeEnergy is called
  Then: returns 28.0

Test: 48 hours elapsed from full energy floors at minEnergy
  Given: storedEnergy=100, lastApprovedAt=T, now=T+48h
  When: computeEnergy is called
  Then: returns 10.0 (not a negative value — the max(minEnergy, ...) floor)

Test: null lastApprovedAt uses createdAt baseline and initialEnergy=70
  Given: storedEnergy=45 (an arbitrary, deliberately-wrong value to prove it's ignored),
    lastApprovedAt=null, createdAt=T, now=T+8h
  When: computeEnergy is called
  Then: returns the same result as if storedEnergy had been 70 (i.e. 70 - 8*3 = 46.0),
    proving storedEnergy=45 was correctly ignored in favor of initialEnergy=70
  Edge cases: does not throw

Test: negative elapsed time clamps to zero, no free energy
  Given: storedEnergy=80, lastApprovedAt=T, now=T-5h (clock set backward)
  When: computeEnergy is called
  Then: returns 80.0 unchanged (hoursElapsed clamped to 0, not -5)

Test: elapsed time beyond maxHoursElapsed floors at the same value as the ceiling itself
  Given: storedEnergy=100, lastApprovedAt=T
  When: computeEnergy is called once with now=T+168h and once with now=T+1000h
  Then: both calls return the identical result (the ceiling clamp, not an ever-more-negative value)

Test: sub-minute elapsed time is not truncated to zero
  Given: storedEnergy=100, lastApprovedAt=T, now=T+90 seconds (1.5 minutes)
  When: computeEnergy is called
  Then: returns a value measurably less than 100 (proves inMicroseconds/microsecondsPerHour
    is used, not inMinutes/60.0 which would truncate 1.5 minutes to 0 minutes → 0 hours → no decay)

Test: computeEnergy never reads the wall clock — deterministic across repeated calls
  Given: fixed storedEnergy, lastApprovedAt, createdAt, now
  When: computeEnergy is called twice with identical arguments (possibly with a real
    Future.delayed between calls, to prove real elapsed wall-clock time doesn't leak in)
  Then: both calls return the exact same value
```

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/time_decay/compute_energy_test.dart` — must exist and pass

**Status**: [x] Created — `tests/unit/time_decay/compute_energy_test.dart`, 9 tests, all passing.

---

## Dependencies

- Depends on: None (pure Dart, no dependency on any other epic's code)
- Unlocks: Story 002 (this epic) — `energyProvider` calls this function with real Firestore-backed values and the real clock. Also unlocks Pet State Machine (#6), which consumes the resulting energy float.

---

## Completion Notes

**Implementation**: `src/lib/core/compute_energy.dart` — pure `computeEnergy()` function, no Flutter/Firestore imports. Matches ADR-0005's Key Interfaces signature exactly. `.difference()` used (not `now - lastApprovedAt`), `inMicroseconds / Duration.microsecondsPerHour` used (not `inMinutes / 60.0`), both `hoursElapsed` and the final result use `.clamp(...).toDouble()` per the manifest's flagged `num.clamp` gotcha. Null `lastApprovedAt` substitutes both `createdAt` (baseline) and `initialEnergy = 70` (stored energy) together, per ADR-0005 Decision §3.

**Tests**: `tests/unit/time_decay/compute_energy_test.dart` — 9 tests, all passing on first run: 8h→76, 24h→28, 48h→10 calibration checks; null-`lastApprovedAt` baseline with a deliberately-wrong `storedEnergy=45` to prove it's ignored; negative-elapsed clamp-to-zero; 168h-vs-1000h ceiling equivalence; sub-minute (30s) elapsed not truncated to zero; determinism across repeated calls (real `Future.delayed` between calls, same fixed `now`); result never exceeds `maxEnergy`.

**Code review**: `flame-specialist` — **APPROVED**, zero required changes. Re-verified against ADR-0005 Decision §1–3 line-by-line; confirmed no wall-clock read inside the function.

**Deviations from scope**: None.
**Manifest version**: 2026-07-16 (current at time of implementation — no drift).
