# ADR-0005: Time & Decay Calculation Strategy

## Status
Accepted (2026-07-11 — accepted post independent /architecture-review; flame-specialist-validated at authoring)

## Date
2026-07-07

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | Core / Business Logic (pure Dart time arithmetic; no Flame, no direct Firestore) |
| **Knowledge Risk** | LOW — pure Dart `DateTime`/`Duration` math and a Riverpod provider. No engine APIs, no post-cutoff surface. The only genuine correctness risk is `DateTime`/Firestore `Timestamp`/timezone handling (see Verification Required) — not a version-drift issue. |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`; `design/gdd/time-decay.md`; ADR-0003; flame-specialist validation (2026-07-07) |
| **Post-Cutoff APIs Used** | None. `cloud_firestore` `Timestamp.toDate()` is read indirectly (the value is delivered via a provider fed by the repository, not read here directly). |
| **Verification Required** | Timezone/DST is a **confirmed non-issue** (flame-specialist, 2026-07-07): Dart `DateTime` stores an absolute instant; `isUtc` is a presentation flag only, and `Duration`-based arithmetic (`.difference()`) operates on the raw instant regardless of either operand's flag — so DST/timezone changes cannot corrupt `hoursElapsed`. The design uses `.difference()`, so it is zone-safe by construction. One residual smoke-check at implementation: print `Timestamp.now().toDate().isUtc` against the installed `cloud_firestore ^5.x` and confirm it matches expectations (expected `false`; the underlying instant is correct regardless). |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0003 (Firestore Schema) — reads `storedEnergy` (float) and `lastApprovedAt` (Timestamp) from the `children/{childId}` schema. NOT dependent on ADR-0004 (energy reaches the Flame layer via the `energyChanged` event, but that wiring is the Bridge/Pet State Machine's concern, not this system's). |
| **Enables** | Pet State Machine (#6) — consumes `currentEnergy` to derive mood. |
| **Blocks** | Pet State Machine implementation (needs the energy value + the ownership boundary this ADR sets). |
| **Ordering Note** | This ADR owns the energy VALUE and its computation. It explicitly does NOT own the energy→mood lookup table (assigned to the Pet State Machine ADR) — even though both GDDs currently print that table. See Decision §4. |

## Context

### Problem Statement

Mochi's mood is a function of energy, and energy decays with real elapsed time since the last approved task. The system must compute "how much energy right now" reliably offline, without draining battery, without a persistent timer, and without becoming a second writer of the energy fields (which the persistence layer + Parent Approval already own). It must also resist naive clock manipulation (a child setting the device clock forward/back). And it must not double-own the energy→mood mapping that the Pet State Machine also describes. The `time-decay.md` GDD specifies all of this; this ADR ratifies the pure-calculation approach and pins the ownership boundary.

### Constraints
- **Offline-first**: energy must compute from local data only (`DateTime.now()` + the cached `lastApprovedAt`). No network.
- **No background work**: no timer, no scheduled job, no per-second recalculation — compute once on app-foreground/resume.
- **Not a writer**: this system owns zero Firestore writes. `storedEnergy` is written by Parent Approval via the repository's atomic contract (ADR-0003) using `FieldValue.increment()`; `lastApprovedAt` is written in the same transaction via `FieldValue.serverTimestamp()` (a Timestamp cannot be `increment()`-ed).
- **Anti-punishment calibration**: energy floors at 10 (never 0), so a normal night's sleep never leaves Mochi "dying."

### Requirements
- A pure function `computeEnergy(storedEnergy, lastApprovedAt, now)` → clamped float in [10, 100].
- A clock-manipulation guard: `hoursElapsed` clamped to `[0, 168]`.
- A `null lastApprovedAt` path (new profile): baseline `initialEnergy = 70`, use `createdAt`.
- Exposed via a Riverpod provider scoped to `activeChildProvider`.
- Deterministic and unit-testable (inject `now`; no reliance on wall-clock in tests).

## Decision

**1. Pure, on-foreground calculation — no timer, no writes.**
Energy is computed by a pure function evaluated when the app foregrounds/resumes, not on a running timer and not per-second during a session. The function is total and side-effect-free:
```
currentEnergy = max(minEnergy, storedEnergy - hoursElapsed × decayRate)
```
It performs no Firestore writes. `storedEnergy` is mutated only by Parent Approval through the persistence repository (ADR-0003 `FieldValue.increment()` contract); `lastApprovedAt` by the same transaction via `FieldValue.serverTimestamp()`. This system is a *reader + calculator*.

**2. Clock-manipulation guard.**
```dart
final Duration elapsed = now.difference(lastApprovedAt);   // NOT now - lastApprovedAt (no operator- on DateTime)
final double hoursElapsed = (elapsed.inMicroseconds / Duration.microsecondsPerHour)
    .clamp(0.0, maxHoursElapsed)                            // .clamp on num returns num...
    .toDouble();                                            // ...so .toDouble() to satisfy the double target
```
Negative elapsed (clock set back) clamps to 0 (no free energy); elapsed > `maxHoursElapsed` (default 168h — clock set way forward or a genuine long absence) clamps to that ceiling, which floors energy at `minEnergy`. Use `inMicroseconds / Duration.microsecondsPerHour`, not `inMinutes / 60.0` — the latter truncates sub-minute elapsed to 0 (a small always-low bias). The ceiling references the `maxHoursElapsed` tuning knob, not a hardcoded literal. `now` is **injected** into `computeEnergy` (not read from the wall clock inside it) so tests are deterministic — the provider is the impure boundary that supplies the real clock (§Key Interfaces).

**3. New-profile baseline.**
When `lastApprovedAt` is null (no approved task yet), use `createdAt` as the baseline and treat `storedEnergy` as `initialEnergy = 70` (CONTENT). Never crash on null.

**4. Ownership boundary — this system owns the energy VALUE; Pet State Machine owns the energy→mood lookup.**
Both `time-decay.md` and `pet-state-machine.md` currently print the energy→mood table (80–100 HAPPY, 50–79 CONTENT, 20–49 TIRED, 10–19 SAD, =10 SLEEPING). To avoid double-ownership drift, **the lookup table is owned by the Pet State Machine ADR/system** (per TR-petstate-002, "Mood = pure lookup on energy float"). Time & Decay outputs the `currentEnergy` float via its provider; the Pet State Machine maps float→mood. Time & Decay's copy of the table is documentation/reference only — the authoritative mapping lives in #6.

**5. Recovery is not computed here — and `lastApprovedAt` MUST be written on approve.**
`newEnergy = min(100, currentEnergy + task.energyReward)` happens inside Parent Approval's transaction (the `energyReward` value is owned per-category by Task Library #8; fallback 25). The post-commit cap at 100 is enforced by the `onTaskApproved` Cloud Function (ADR-0003). Time & Decay only defines the decay half.

**Critically, Parent Approval's approve transaction MUST write `children/{childId}.lastApprovedAt = FieldValue.serverTimestamp()`** — this is the field that resets the decay clock, and without it the entire recovery-resets-decay half of the design is inert. `serverTimestamp()` (not client `DateTime.now()`) is chosen for tamper-resistance at the write side, complementing the read-side `[0,168]` clamp. This is safe from the `serverTimestamp`-resolves-null-until-acked pitfall **because approve is transaction-based** (`runTransaction` requires connectivity and does not apply optimistically to the local cache), so there is no optimistic-write window where a pending null could be read. `parent-approval.md`'s write list currently omits this field — corrected alongside this ADR (see GDD sync).

### Architecture Diagram
```
Firestore children/{childId}: storedEnergy, lastApprovedAt   (written by Parent Approval via repository)
        │  read via provider (scoped to activeChildProvider)
        ▼
energyProvider = computeEnergy(storedEnergy, lastApprovedAt, now)   ← PURE, on-foreground
        │  clamp hoursElapsed ∈ [0,168]; result ∈ [10,100]; no writes
        ▼
Pet State Machine (#6): float → MoodState  (lookup table OWNED HERE, not in Time&Decay)
```

### Key Interfaces
```dart
// Pure, deterministic, injectable clock — no wall-clock read inside. Test with a fixed `now`.
double computeEnergy({
  required double storedEnergy,      // 10..100 (or initialEnergy=70 if null profile)
  required DateTime? lastApprovedAt, // null → use createdAt baseline
  required DateTime createdAt,
  required DateTime now,             // injected for testability
  double decayRate = 3.0,            // tuning knob (1.0–5.0)
  double minEnergy = 10,
  double maxEnergy = 100,
  double maxHoursElapsed = 168,      // referenced by the clamp, not a hardcoded literal
});

// A plain Provider recomputes only when a watched dependency changes — DateTime.now()
// and "app resumed" are not watchable by default. So energyProvider needs an explicit
// resume-tick dependency plus the Firestore-backed doc stream:
final resumeTickProvider = StateProvider<int>((ref) => 0);   // ++ on app resume

// Wired once near app root (AppLifecycleListener, stable since Flutter 3.13):
//   AppLifecycleListener(onResume: () => ref.read(resumeTickProvider.notifier).state++)
// Only onResume ticks — matches "recalc on resume from background", not pause/inactive.

final energyProvider = Provider<double>((ref) {
  ref.watch(resumeTickProvider);                    // recompute on foreground/resume
  final child = ref.watch(activeChildDocProvider);  // StreamProvider<ChildDoc> (snapshots), scoped to activeChild
  // activeChildDocProvider is AsyncValue-wrapped — handle loading/error (offline cache
  // resolves near-instantly; define a sane default while loading).
  return computeEnergy(
    storedEnergy: child.storedEnergy,
    lastApprovedAt: child.lastApprovedAt,
    createdAt: child.createdAt,
    now: DateTime.now(),                            // the deliberately impure boundary
  );
});
```

## Alternatives Considered

### Alternative A: Pure on-foreground calculation (chosen)
- **Description**: Compute once on foreground from `DateTime.now()` + `lastApprovedAt`; no timer; no writes.
- **Pros**: Fully offline; zero battery cost; trivially unit-testable with injected `now`; no second writer of energy fields (no race with Parent Approval).
- **Cons**: Energy is "stale" between foregrounds — but that's invisible to the player (they only see it when the app is open), and it's the correct model for a mood that reflects real elapsed time.
- **Rejection Reason**: N/A — chosen.

### Alternative B: Background timer / scheduled local recalculation
- **Description**: A periodic timer (or WorkManager/BGTaskScheduler) recomputes energy in the background.
- **Pros**: Energy always "current" even before foreground.
- **Cons**: Battery drain; platform background-execution limits (iOS especially); pointless since the value is only observed on foreground; adds complexity and a persistence question (where does the background value go?).
- **Rejection Reason**: Cost with no player-visible benefit.

### Alternative C: Server-computed energy (Cloud Function)
- **Description**: A Cloud Function computes energy server-side.
- **Pros**: Tamper-resistant clock (server time).
- **Cons**: Breaks offline (the core-loop pillar); network latency to see Mochi's mood; unjustified for a pure time calculation whose worst-case abuse (clock manipulation) is already bounded by the `[0,168]` clamp and whose stakes are cosmetic (mood, not currency).
- **Rejection Reason**: Breaks offline for a non-economy, cosmetic value; clamp already bounds the abuse.

## Consequences

### Positive
- Zero battery/network cost; fully offline; deterministic and testable.
- No second writer of `storedEnergy`/`lastApprovedAt` → no race with Parent Approval's transaction.
- Ownership boundary explicit — the energy→mood table has one owner (#6), eliminating drift risk.

### Negative
- Energy is only as fresh as the last foreground — acceptable and correct for this model.
- Clock manipulation can still shift mood within the clamp bounds (cosmetic only; accepted).

### Risks
- **`DateTime`/`Timestamp`/timezone mismatch** in `now - lastApprovedAt`. *Mitigation*: Verification Required — compare both operands in UTC; confirm `Timestamp.toDate()` zone; test across a simulated timezone/DST change. The `[0,168]` clamp bounds the damage but does not fix a systematic zone bug.
- **Double-ownership drift** of the energy→mood table if both GDDs are edited independently. *Mitigation*: Decision §4 assigns sole ownership to #6; Time & Decay's copy is marked reference-only (see GDD sync).
- **Clock manipulation** for cosmetic gain. *Mitigation*: `[0,168]` clamp; accepted as cosmetic-only (energy is not currency).
- **Tripwire (contingent safety)**: `serverTimestamp()` for `lastApprovedAt` is null-safe here *only because approve is transaction-based*. If a future latency optimization moves the approve write to a plain `set()`/`update()`/`WriteBatch` (which DO apply optimistically to the cache), `serverTimestamp()` would resolve to `null` until the server acks — and that transient null would wrongly fall into this ADR's "null = no approved task ever → initialEnergy 70" branch mid-flight, resetting a real pet's energy. *Mitigation*: documented tripwire; if approve ever leaves `runTransaction`, this null-handling must be revisited.
- **B1 dependency**: this ADR is inert until `parent-approval.md` actually writes `lastApprovedAt`. *Mitigation*: corrected in the GDD sync below; ADR-0005 should not reach Accepted before that write exists in the Parent Approval spec.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| time-decay.md | Energy computed on app-foreground only, no background timer (TR-time-decay-001) | Decision §1 |
| time-decay.md | Decay = f(now − lastApprovedAt); no persistent per-second recalc (TR-time-decay-002) | Decision §1–2, injectable `now` |
| time-decay.md | Clock-manipulation guard: clamp `hoursElapsed` to [0,168] (TR-time-decay-003) | Decision §2 |
| time-decay.md | Pure calculation — owns zero Firestore writes, exposes via provider (TR-time-decay-004) | Decision §1, §5; Key Interfaces |
| pet-state-machine.md | Mood = pure lookup on energy float (TR-petstate-002) | Decision §4 — assigns the lookup to #6; Time & Decay supplies the float only |

## Performance Implications
- **CPU**: One subtraction + clamp per foreground — negligible.
- **Memory**: None.
- **Load Time**: None (computed synchronously on foreground from already-cached data).
- **Network**: None — fully offline.

## Migration Plan
Greenfield. GDD syncs landing alongside this ADR:
1. **`parent-approval.md` (the real blocker, B1)** — add `children/{childId}.lastApprovedAt = FieldValue.serverTimestamp()` to the approve transaction's write list, and correct the acceptance criterion that currently says "no other field in `children/{childId}` changes." Without this the decay clock never resets.
2. **`data-persistence-layer.md`** — the Approve Task Batch contract lists `lastApprovedAt = now`; change to `FieldValue.serverTimestamp()` for consistency with §5.
3. **`time-decay.md`** — annotate Core Rule 4 (the energy→mood table) as reference-only, authoritative ownership → Pet State Machine (Decision §4); no values change.

## Validation Criteria
- Unit (deterministic, injected `now`): 8h→76 (CONTENT), 24h→28 (TIRED), 48h→10 (SLEEPING); recovery cases per the GDD's calibration table.
- Unit: negative elapsed (clock back) → clamp 0, energy unchanged; elapsed > 168h → floors at 10.
- Unit: null `lastApprovedAt` → uses `createdAt`, `storedEnergy` treated as 70, no crash.
- **Verification**: timezone/DST correctness of the elapsed calc (UTC-consistent operands; `Timestamp.toDate()` zone confirmed).

## Related Decisions
- ADR-0003 (Firestore Schema) — owns the `storedEnergy`/`lastApprovedAt` fields this reads and the increment contract Parent Approval uses to write them.
- Pet State Machine ADR (next) — owns the energy→mood lookup this ADR delegates to it.
- Parent Approval ADR (upcoming) — owns the recovery half (`+energyReward` inside the transaction).
- `design/gdd/time-decay.md` — the ratified design.
