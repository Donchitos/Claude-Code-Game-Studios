# ADR-0013: Parent Approval Transaction Architecture

## Status
Proposed

## Date
2026-07-18

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | Core / Economy + Progression (Firestore `runTransaction`, Riverpod repository/provider pattern — Platform-layer; no Flame) |
| **Knowledge Risk** | LOW — this is the exact `runTransaction` shape already Accepted and shipped in ADR-0003 (approve/reject example), ADR-0009 (idempotency-read-first), and ADR-0011 (Shop's read-before-write idempotency pattern). No new post-cutoff surface; this ADR composes already-verified primitives. |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`; `design/gdd/parent-approval.md`; ADR-0003, ADR-0004, ADR-0005, ADR-0008, ADR-0009, ADR-0011, ADR-0012; `docs/registry/architecture.yaml`; `design/registry/entities.yaml`; flame-specialist validation (2026-07-18) |
| **Post-Cutoff APIs Used** | None new — reuses `runTransaction`/`FieldValue.increment`/`FieldValue.serverTimestamp`, all already confirmed stable for the pinned `cloud_firestore` version (ADR-0003's 2026-07-13 correction). |
| **Verification Required** | None beyond what ADR-0003/0011 already required for `runTransaction` generally. The two-device race (GDD Edge Case 3 / AC "Two-device race") depends on Firestore's optimistic-concurrency auto-retry, already relied upon by ADR-0011 without incident. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0003 (Firestore Schema — `runTransaction` mechanism, already named this exact approve/reject example), ADR-0004 (Event Bridge — `taskApproved`/`petLeveledUp` event types, already defined), ADR-0005 (Time & Decay — `lastApprovedAt` reset contract), ADR-0008 (Currency — `xuBalance` increment-only rule), ADR-0009 (Task Lifecycle — the `pending`/`approved`/`rejected` status this transaction transitions, and the `xuReward`/`energyReward` this transaction trusts as already-validated), ADR-0012 (Seed Buffer — the `seedCount -= 1` contract this ADR fulfills) |
| **Enables** | Parent Dashboard UI (#21) — `pendingTasksProvider` + `approveTask()`/`rejectTask()` are its data layer |
| **Blocks** | Any Parent Approval implementation story; any Parent Dashboard UI story that calls approve/reject |
| **Ordering Note** | This ADR is the sole writer (in MVP) of Pet Leveling (#16)'s `totalXuEarned`/`petLevel` and Gacha/Loot (#12)'s `approvedTaskCount`/`chestCount` fields — neither system has its own ADR or epic yet. This ADR registers those write mechanisms now (increment-only, matching the already-registered `absolute_set_on_balance_or_counters` exception list) rather than blocking on epics that don't exist. If/when Pet Leveling or Gacha/Loot get their own ADRs, those ADRs must not contradict the write contract established here without an explicit supersession. |

## Context

### Problem Statement

Task Library (#8) creates tasks; Seed Buffer (#10) gives instant feedback on submit. But nothing yet turns an approved task into an actual reward — xu, energy, level-up, chest. Parent Approval is the single atomic operation that does this: one Firestore transaction that touches five different systems' fields (Task Library, Currency, Time & Decay, Seed Buffer, Pet Leveling, Gacha/Loot) and must guarantee no double-grant under three concrete failure modes the GDD names explicitly: a parent double-tapping Approve, two parent devices approving the same task within the ~150-439ms sync window, and a transaction failing partway through.

### Constraints
- **Read-before-write is mandatory, not optional**: level-up detection requires reading `totalXuEarned`/`petLevel` before deciding what to write — this rules out `WriteBatch` (ADR-0003's `atomic_write_mechanism` entry already states this).
- **Idempotency read must be the task's own `status` field, and must be the FIRST read inside the transaction** — a separate pre-check outside the transaction is a TOCTOU race (GDD Core Rule 2, explicit).
- **No `cancelled`/`un-reject` state** (ADR-0009) — this transaction only ever transitions `pending → approved` or `pending → rejected`, never back.
- **Every field this transaction writes is increment-only** — `xuBalance`, `seedCount`, `chestCount`, `approvedTaskCount`, `storedEnergy`, `totalXuEarned` are all named in the registered `absolute_set_on_balance_or_counters` forbidden pattern. `petLevel` is the one field this transaction sets to an absolute new value (`petLevel += 1`, itself expressible as `FieldValue.increment(1)` — still not an absolute `set()`).
- **One transaction per task, never a batch of tasks** (GDD Core Rule 4) — matches Pet Leveling's own "one level-up check per approve event" invariant.
- **Offline-first**: the transaction runs client-side; a client-side offline pre-check (`connectivity_plus`) is a UX optimization, not the actual safety mechanism — the unified error path is.

### Requirements
- Single `runTransaction` for Approve: idempotency-gated on `task.status`, reads `xuReward`/`energyReward`/`totalXuEarned`/`petLevel`/`approvedTaskCount`, computes `leveledUp`/`hitChestMilestone`/`chestDelta`, writes all affected fields atomically, returns a result the caller uses to emit `taskApproved` (+ `petLeveledUp` if leveled up) only when a real commit happened.
- Single `runTransaction` for Reject: same idempotency gate, writes only `status`/`rejectedAt`/`seedCount`, no economy fields touched, no `GameEvent` emitted (UI-local wither only).
- Unified error handling regardless of failure cause (offline, transient, or other) — re-enable buttons, generic retry message, no partial state.
- `nextLevelThreshold(petLevel)` and `xuBonus(newLevel)` — pure lookup functions Pet Leveling's GDD assigns ownership of the *formula* to, but which have no code anywhere yet (no Pet Leveling epic/ADR exists). This ADR's implementation must create them, sourced from the already-registered `entities.yaml` constants (`pet_level_threshold_l2..l5` = 150/400/900/1800, `pet_levelup_xu_bonus` = `level*25+25`) — not invented values.

## Decision

**1. `ParentApprovalRepository` — a new repository class, matching the established per-system convention.**
Following the exact shape `TaskRepository`/`CustomTaskRepository` already established (constructor-injected `FirebaseFirestore` via `ref.watch(firebaseFirestoreProvider)`, one focused method per operation, no monolithic `PersistenceRepository`): a new `ParentApprovalRepository` class owning `approveTask()` and `rejectTask()`. **This explicitly supersedes ADR-0003's own Key Interfaces entry**, which declared `Future<ApproveResult> approveTask(...)` on a monolithic `PersistenceRepository` that was never actually built that way (the real, established convention — confirmed again by flame-specialist validation of this ADR — is one small repository per write concern). The `ApproveResult` return-value *shape* ADR-0003 anticipated is kept (see §2 below); only its home class changes.

**2. `approveTask()` — single `runTransaction`, exact read/write order per the GDD. Returns a result; does NOT emit events itself.**

Found in this ADR's own validation pass (flame-specialist, 2026-07-18) — an early draft of this section made the exact mistake Seed Buffer Story 001's code review already found and fixed once in this codebase: a repository calling `GameEventBus().emit()` directly. ADR-0004 §3 names exactly two sanctioned adapters (`ref.listen` in a `ConsumerWidget`, or a Flame component's tap/drag handler) and is explicit that "no third path is permitted." A repository's post-transaction callback is neither adapter, regardless of whether the emit is conditional on a real state change. **`approveTask()` therefore returns a result value and emits nothing** — event emission is the future Parent Dashboard `ConsumerWidget`'s job, reacting to the awaited result, matching `TaskRepository`'s own precedent exactly.

```dart
/// null == idempotent no-op (task was already approved/rejected — the
/// double-tap / two-device-race path). A non-null result means this call
/// genuinely committed the transaction; the CALLER (a future ConsumerWidget,
/// per ADR-0004 §3 adapter (a)) is responsible for emitting `taskApproved`/
/// `petLeveledUp` off of it — this repository never touches GameEventBus.
/// [newPetLevel] is populated whenever [leveledUp] is true — the ALREADY-
/// REGISTERED `game_event_bus` contract (`docs/registry/architecture.yaml`)
/// declares `petLeveledUp`'s payload type as `int`, not `null` (found while
/// cross-checking this ADR's own Related Decisions against the registry) —
/// the caller must emit `GameEvent(GameEventType.petLeveledUp, newPetLevel)`,
/// not a null payload, to honor that pre-existing contract.
class ApproveResult {
  const ApproveResult({required this.leveledUp, this.newPetLevel});
  final bool leveledUp;
  final int? newPetLevel; // non-null iff leveledUp
}

Future<ApproveResult?> approveTask({
  required String parentId,
  required String childId,
  required String taskId,
}) {
  return _firestore.runTransaction<ApproveResult?>((transaction) async {
    final taskRef = _firestore.doc(FirestorePaths.task(parentId, childId, taskId));
    final childRef = _firestore.doc(FirestorePaths.child(parentId, childId));

    // FIRST read, inside the transaction — the idempotency gate. Not a
    // separate pre-check (TOCTOU race); this is what Firestore's per-
    // document transaction serialization actually protects (GDD Core Rule 2).
    final taskSnap = await transaction.get(taskRef);
    final taskData = taskSnap.data();
    if (taskData == null || taskData['status'] != 'pending') {
      return null; // Idempotent no-op — double-tap or two-device race, both silent.
    }

    final childSnap = await transaction.get(childRef);
    final childData = childSnap.data() ?? {};
    final xuReward = (taskData['xuReward'] as num).toInt();
    final energyReward = (taskData['energyReward'] as num).toInt();
    final totalXuEarned = (childData['totalXuEarned'] as num?)?.toInt() ?? 0;
    final petLevel = (childData['petLevel'] as num?)?.toInt() ?? 1;
    final approvedTaskCount = (childData['approvedTaskCount'] as num?)?.toInt() ?? 0;

    final newTotalXuEarned = totalXuEarned + xuReward;
    final leveledUp = petLevel < 5 && newTotalXuEarned >= nextLevelThreshold(petLevel);
    final newApprovedTaskCount = approvedTaskCount + 1;
    final hitChestMilestone = newApprovedTaskCount % gachaFreeChestMilestone == 0;
    final chestDelta = (leveledUp ? 1 : 0) + (hitChestMilestone ? 1 : 0);
    final newPetLevel = leveledUp ? petLevel + 1 : petLevel;
    var xuIncrement = xuReward;
    if (leveledUp) xuIncrement += xuBonus(newPetLevel);

    transaction.update(taskRef, {'status': 'approved', 'approvedAt': FieldValue.serverTimestamp()});
    transaction.update(childRef, {
      'xuBalance': FieldValue.increment(xuIncrement),
      // .toDouble() — storedEnergy is a real double field (Time & Decay,
      // ADR-0005); the increment literal's type must match, per ADR-0003's
      // own explicit mitigation (found in this ADR's own validation pass).
      'storedEnergy': FieldValue.increment(energyReward.toDouble()),
      'lastApprovedAt': FieldValue.serverTimestamp(), // resets Time & Decay's clock, ADR-0005
      'seedCount': FieldValue.increment(-1), // clamp-at-0 is seedCountProvider's job (ADR-0012 §3), not this write's
      'totalXuEarned': FieldValue.increment(xuReward),
      'approvedTaskCount': FieldValue.increment(1),
      if (leveledUp) ...{
        'petLevel': FieldValue.increment(1),
        // Keeps ADR-0003's stored nextLevelThreshold schema field in sync
        // with petLevel on every level-up this transaction is the sole
        // writer of (found in this ADR's own validation pass — the original
        // draft computed this in-memory for the leveledUp check but never
        // wrote it back, silently going stale after the very first level-up).
        // null at max level (no "next" threshold beyond L5).
        'nextLevelThreshold': newPetLevel < 5 ? nextLevelThreshold(newPetLevel) : null,
      },
      if (chestDelta > 0) 'chestCount': FieldValue.increment(chestDelta),
    });

    return ApproveResult(
      leveledUp: leveledUp,
      newPetLevel: leveledUp ? newPetLevel : null,
    );
  });
}
```

**3. `rejectTask()` — same idempotency shape, minimal writes, no events.**

```dart
Future<void> rejectTask({
  required String parentId,
  required String childId,
  required String taskId,
}) async {
  await _firestore.runTransaction((transaction) async {
    final taskRef = _firestore.doc(FirestorePaths.task(parentId, childId, taskId));
    final childRef = _firestore.doc(FirestorePaths.child(parentId, childId));

    final taskSnap = await transaction.get(taskRef);
    if (taskSnap.data()?['status'] != 'pending') {
      return;
    }

    transaction.update(taskRef, {'status': 'rejected', 'rejectedAt': FieldValue.serverTimestamp()});
    transaction.update(childRef, {'seedCount': FieldValue.increment(-1)});
  });
  // No GameEvent — wither is a UI-local animation Task Management UI (#19) owns
  // directly off the task list transition, not a Pet State Machine trigger
  // (GDD Core Rule 3, explicit: "không qua Pet State Machine triggered state").
}
```

**4. `nextLevelThreshold()`/`xuBonus()`/`gachaFreeChestMilestone` — new pure lookup functions/constant, sourced from already-registered data, not invented.**
Pet Leveling (#16) and Gacha/Loot (#12) have no ADR or epic yet, but their formulas are already fully resolved in `design/registry/entities.yaml` (added 2026-07-04/07-01, unchanged since). This ADR's implementation creates:
```dart
int nextLevelThreshold(int currentLevel) => switch (currentLevel) {
  1 => 150, 2 => 400, 3 => 900, 4 => 1800,
  _ => throw ArgumentError('no next threshold at max level — callers must guard petLevel < 5 first'),
}; // pet_level_threshold_l2..l5, entities.yaml
int xuBonus(int newLevel) => newLevel * 25 + 25; // pet_levelup_xu_bonus, entities.yaml
const gachaFreeChestMilestone = 5; // entities.yaml
```
These are placed alongside `ParentApprovalRepository` (not a separate Pet Leveling/Gacha module, since no such module exists) with a doc comment flagging that ownership formally belongs to those future systems' GDDs — matching the same "contract now, implement fully later" shape ADR-0012 used for Parent Approval's own `-1` decrement contract. `nextLevelThreshold()` throws outside 1–4 by design (found in this ADR's own validation pass) — every call site in this ADR's own code guards `petLevel < 5`/`newPetLevel < 5` first, and any future caller (e.g. a level-progress-bar UI) must do the same.

**5. Unified error handling.** Per GDD Core Rule 5: any `runTransaction` throw (offline, transient, or other) is caught identically — no cause-specific branching. The UI layer (Parent Dashboard, out of this ADR's scope) disables the button on tap and re-enables + shows a generic retry message on any exception, matching `CustomTaskRepository`'s let-it-throw pattern (this repository does not catch/swallow).

### Architecture Diagram
```
[Parent taps Approve] ──► ParentApprovalRepository.approveTask() ──► ApproveResult?
                                    │                                       │
                          runTransaction<ApproveResult?>:                  │
                            1. get(taskRef)          ← idempotency gate, FIRST read
                               if status != 'pending' → return null (silent no-op)
                            2. get(childRef)          ← totalXuEarned, petLevel, approvedTaskCount
                            3. compute leveledUp, hitChestMilestone, chestDelta (pure, in-memory)
                            4. update(taskRef):   status='approved', approvedAt
                               update(childRef):  xuBalance+=, storedEnergy+= (double), lastApprovedAt=now,
                                                   seedCount-=1, totalXuEarned+=, approvedTaskCount+=1,
                                                   [petLevel+=1, nextLevelThreshold=], [chestCount+=chestDelta]
                            5. return ApproveResult(leveledUp)              │
                                                                            ▼
                                                          [future Parent Dashboard ConsumerWidget]
                                                          awaits result — if non-null:
                                                            emit GameEvent(taskApproved, null)
                                                            emit GameEvent(petLeveledUp, newPetLevel)  [if leveledUp]
                                                          — NOT this repository (ADR-0004 §3 adapter (a));
                                                          newPetLevel payload matches the ALREADY-REGISTERED
                                                          game_event_bus contract (petLeveledUp→int, not null)
```

### Key Interfaces
```dart
class ApproveResult {
  const ApproveResult({required this.leveledUp, this.newPetLevel});
  final bool leveledUp;
  final int? newPetLevel; // non-null iff leveledUp — payload for GameEventType.petLeveledUp
}
class ParentApprovalRepository {
  ParentApprovalRepository({required FirebaseFirestore firestore});
  Future<ApproveResult?> approveTask({required String parentId, required String childId, required String taskId});
  Future<void> rejectTask({required String parentId, required String childId, required String taskId});
  // approveTask returns null on idempotent no-op, non-null on real commit.
  // Emitting GameEvent(taskApproved)/(petLeveledUp) off that result is the
  // CALLER's job (a future ConsumerWidget) — this class never touches
  // GameEventBus. rejectTask has no analogous result: reject never emits
  // any GameEvent (GDD Core Rule 3 — wither is UI-local, not a bus event).
}
int nextLevelThreshold(int currentLevel); // 150/400/900/1800, entities.yaml — throws outside 1-4
int xuBonus(int newLevel);                 // level*25+25, entities.yaml
```

## Alternatives Considered

### Alternative A (chosen): Single client-side `runTransaction`, GDD's own design
- **Pros**: Matches the GDD exactly (already fully specified down to read order); one atomic unit, no partial-commit window; offline-capable per ADR-0003's offline-first pillar; reuses every already-Accepted increment pattern.
- **Cons**: The transaction touches 6+ fields across conceptually distinct systems in one function — a lot of cross-cutting knowledge concentrated in one repository. Accepted: the GDD itself frames this as Parent Approval's entire purpose ("System này không sở hữu bất kỳ field nào nó chạm vào... việc của Parent Approval là trở thành nơi duy nhất lắp ráp").
- **Rejection Reason**: N/A — chosen.

### Alternative B: Client writes task status only; Cloud Function computes level-up/chest/rewards asynchronously
- **Pros**: Keeps the client transaction small; centralizes reward-computation logic server-side.
- **Cons**: Breaks the GDD's own Latency Contract (<500ms worst-case bloom animation) — a Cloud Function round-trip cannot hit that. Breaks offline-first: approve must work with no connectivity beyond the client's own Firestore write.
- **Rejection Reason**: Incompatible with two explicit GDD requirements (latency contract, offline capability) — same rejection shape as Seed Buffer's own Alternative C.

### Alternative C: `WriteBatch` with a separate optimistic idempotency check
- **Description**: Read `task.status` once outside a transaction, then `WriteBatch` if still pending.
- **Pros**: Slightly simpler API.
- **Cons**: TOCTOU race — the read and the batch write aren't atomic together, so the two-device race (GDD Edge Case 3) is NOT actually prevented. This is exactly why ADR-0003's `atomic_write_mechanism` entry already excludes `WriteBatch` for read-dependent writes.
- **Rejection Reason**: Does not satisfy the idempotency requirement that is this ADR's central safety property.

## Consequences

### Positive
- Single, atomic, testable operation closes the entire "task → reward" loop other systems have been contracting toward (Seed Buffer's `-1`, Time & Decay's `lastApprovedAt` reset) since their own ADRs.
- Idempotency is structurally guaranteed by transaction semantics, not by application-level locking — the GDD's own reasoning (Firestore serializes same-document transactions) is correct and matches Alternative C's rejection.
- Registers `total_xu_earned`/`pet_level`/`approved_task_count`/`chest_count` write mechanisms now, unblocking Parent Dashboard UI without waiting on Pet Leveling/Gacha epics that don't exist yet.

### Negative
- `nextLevelThreshold()`/`xuBonus()` are implemented inside this ADR's scope on behalf of systems that don't have their own ADR yet — if Pet Leveling later gets its own ADR with a different formula, that ADR must explicitly supersede this contract, not silently diverge (flagged in ADR Dependencies above).
- The transaction has real complexity (6 fields, 2 conditional writes) concentrated in one function — mitigated by the GDD's own explicit formulas (Contract 1) and this ADR's exact worked example matching it.

### Risks
- **Risk**: A future system copies this transaction's shape for a case that doesn't need idempotency, adding unnecessary transaction overhead. **Mitigation**: `atomic_write_mechanism`'s registry entry already distinguishes read-dependent (`runTransaction`) from independent (`WriteBatch`) writes — this ADR reinforces, not redefines, that line.
- **Risk**: `nextLevelThreshold()`/`xuBonus()` living inside Parent Approval's module rather than a dedicated Pet Leveling module could be missed by a future Pet Leveling epic author. **Mitigation**: doc comments explicitly flag formal ownership; this ADR's own Migration Plan below states what must happen if/when Pet Leveling gets its own ADR.
- **Risk**: `storedEnergy` can transiently exceed 100 after this transaction commits (GDD Edge Case 10) — already a known, accepted, separately-solved risk (`onTaskApproved` Cloud Function's cap correction, ADR-0003 §6), not something this ADR needs to re-solve.
- **Risk, pre-existing but newly exploitable (found in this ADR's own validation pass, flame-specialist, 2026-07-18)**: `GameEventBus` (ADR-0004 §5) caches and replays the LAST event per `GameEventType` to any newly-subscribing listener — correct and necessary for *state* events (`petMoodChanged`, `energyChanged`), but `taskApproved`/`petLeveledUp` are one-shot *trigger* events with no distinguishing identity in their payload. Once any task has ever been approved, EVERY later remount of a subscribing Flame component (screen nav away/back, `IndexedStack` rebuild — exactly the scenario ADR-0004 §5's own 2026-07-13 correction was written for) will receive a spurious replay and incorrectly re-trigger the bounce/level-up animation. This gap already existed in ADR-0004's design (both event types were already in the enum, already consumed by `MochiComponent`'s test suite) — this ADR is the first to actually make it reachable by being the first thing that ever emits them for real. **Mitigation**: not resolved here — resolving it means revising ADR-0004's replay mechanism (e.g. excluding trigger-type events from the replay cache, or giving components a way to recognize "already-handled" event identity), which is a cross-cutting change beyond this ADR's scope. Flagged explicitly so a future ADR-0004 revision (or a Parent Dashboard UI story discovering this the hard way) has this written down rather than rediscovering it from scratch.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| `parent-approval.md` | Approve transaction: single atomic `runTransaction`, idempotency-gated, credits xu/energy/seedCount/totalXuEarned/approvedTaskCount, level-up + chest milestone detection | Decision §2 |
| `parent-approval.md` | Reject transaction: same idempotency gate, minimal writes, no `GameEvent` | Decision §3 |
| `parent-approval.md` | Unified error handling regardless of failure cause | Decision §5 |
| `parent-approval.md` | Chest Delta contract (`chestDelta = [leveledUp] + [hitChestMilestone]`, 0-2, both stack) | Decision §2, matches `entities.yaml`'s `chest_delta` formula exactly |
| `pet-leveling-evolution.md` | `nextLevelThreshold`/`xuBonus` formulas (TR-leveling-002/003) | Decision §4, sourced from already-registered `entities.yaml` constants, not invented |
| `gacha-loot.md` | `chestCount += chestDelta` via increment, never absolute set | Decision §2, `entities.yaml`'s `gacha_free_chest_milestone` = 5 |
| `seed-buffer.md` | The `-1` decrement contract ADR-0012 §2 left unimplemented | Decision §2/§3, `FieldValue.increment(-1)` inside this transaction |

## Performance Implications
- **CPU**: Negligible — one transaction with 2 reads + up to 2 writes; formula computation is pure in-memory arithmetic.
- **Memory**: No new persistent state; transaction closure is short-lived.
- **Load Time**: None.
- **Network**: One `runTransaction` round-trip per approve/reject (existing Firestore transaction cost, not new); matches GDD's own measured latency contract (avg 151ms, worst-case 439ms, spike-validated in `prototypes/firebase-multidevice-sync-spike-2026-07-03/`).

## Migration Plan
Greenfield — no existing code to migrate. **Forward note**: if Pet Leveling (#16) or Gacha/Loot (#12) later get their own ADRs, those ADRs must either (a) explicitly adopt this ADR's `nextLevelThreshold()`/`xuBonus()`/`gachaFreeChestMilestone` as their own Key Interfaces (simple case — just relocate the code, same values), or (b) explicitly supersede this ADR's Decision §4 if the formulas change. Do not let a future ADR silently redefine these without cross-referencing this one.

**Follow-up item, found in this ADR's own validation pass**: this transaction keeps `nextLevelThreshold` in sync on every level-up, but never sets its *initial* value (150, per `pet_level_threshold_l2`) — that's the child-profile-creation flow's job (Auth & Account, already Complete), which was written before this field's existence was fully worked through and does not currently set it. Not fixed here (out of this ADR's scope — Auth & Account's own code is a different epic); flagged as a real gap a Parent Approval or Auth & Account implementer must close, likely via a small follow-up story, before the first level-up can be trusted to read a real prior value rather than `null`.

## Validation Criteria
`parent-approval.md`'s Acceptance Criteria, in particular:
- Normal approve path, level-up-only, chest-milestone-only, and both-combo — all 4 unit-testable against the pure `chestDelta`/`leveledUp`/`hitChestMilestone` computation, independent of Firestore.
- Idempotency (already-approved/rejected task) and double-tap — testable via a mocked transaction returning a non-`'pending'` status.
- Two-device race — this project's established no-emulator constraint means this can only be verified via Firestore's documented optimistic-concurrency behavior, not a live two-client test in this environment (same category of gap as Seed Buffer Story 003's transaction-with-query verification).
- Transaction failure — testable via a mocked rejected transaction, verifying no partial state (matches the pattern already established in Seed Buffer Story 003's `test_reconcileSeedCountDrift_propagates_a_rejected_transaction`).

## Related Decisions
- ADR-0003 (Firestore Schema) — the `runTransaction` mechanism this ADR implements the already-named example of.
- ADR-0004 (Event Bridge) — `taskApproved`/`petLeveledUp` event types, and the §3 two-sanctioned-adapters rule this ADR's repository deliberately stays outside of (emission is the caller's job).
- ADR-0005 (Time & Decay) — `lastApprovedAt` reset contract this transaction fulfills.
- ADR-0008 (Currency) — `xuBalance` increment-only rule.
- ADR-0009 (Task Lifecycle) — the task status this transaction transitions, and the reward-integrity guarantee this transaction trusts.
- ADR-0012 (Seed Buffer) — the `seedCount -= 1` contract this ADR fulfills.
- `design/gdd/parent-approval.md` — the GDD this ADR implements.
