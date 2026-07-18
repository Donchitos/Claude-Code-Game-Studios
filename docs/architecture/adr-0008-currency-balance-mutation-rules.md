# ADR-0008: Currency & Balance Mutation Rules

## Status
Accepted (2026-07-11 — accepted post independent /architecture-review; flame-specialist-validated at authoring)

## Date
2026-07-07

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | Core / Economy (Firestore `FieldValue.increment` + Riverpod `StreamProvider` — Platform-layer; no Flame) |
| **Knowledge Risk** | LOW — `FieldValue.increment()` and a Riverpod `StreamProvider` over `snapshots()` are stable, pre-cutoff patterns fully governed by ADR-0003. No new post-cutoff surface. |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`; `design/gdd/currency-system.md`; ADR-0002, ADR-0003; flame-specialist validation (2026-07-07) |
| **Post-Cutoff APIs Used** | `cloud_firestore ^5.x` `FieldValue.increment()`; `flutter_riverpod` `StreamProvider`. All inherited from ADR-0003. |
| **Verification Required** | None new — the increment/atomicity behavior is validated under ADR-0003. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0003 (Firestore Schema & Persistence) — `xuBalance` is a field in that schema, mutated via the `FieldValue.increment()` contract and the atomic write/transaction mechanisms defined there. ADR-0002 (Auth) — `xuBalanceProvider` scopes on `activeChildProvider`. |
| **Enables** | Shop System (#13) — reads balance + decrements on purchase; Gacha/Loot (#12) — increments on chest reward; Main Nav Shell (#17) + Shop & Reward UI (#20) — display balance. Parent Approval (#11) increments on approve (via its transaction). |
| **Blocks** | Any implementation epic that earns, spends, or displays xu. |
| **Ordering Note** | This ADR owns the `xuBalance` **state semantics** (single currency, increment-only, floor-ownership). It does NOT own the atomic-write *mechanism* (ADR-0003) nor the per-category `xuReward` values (Task Library #8) nor the affordability-check UX (Shop #13) — it defines the rules those systems must satisfy when touching the balance. |

## Context

### Problem Statement

xu is the single proof of real effort (Pillar 1) — earned only by task approval, spent only in the Shop. Every system that touches the balance (Parent Approval, Gacha, Shop) must agree on exactly how it mutates, or the economy corrupts: a lost update on concurrent approvals, a negative balance from an unchecked purchase, or a second currency that opens a pay-to-win path all violate the pillar. This ADR fixes the balance semantics — one currency, increment-only mutation, who enforces the ≥0 floor, and how the balance is read — so those systems build against one contract. Most of the *mechanism* is inherited from ADR-0003; this ADR pins the *economy rules* on top of it.

### Constraints
- **Single currency** — no premium coin, no IAP, no ad-reward xu (Pillar 1: xu only from real effort).
- **Offline-first** (ADR-0003) — mutations are client-side `FieldValue.increment()` in the persistence layer's atomic contracts.
- **Concurrent-safe** — two approvals syncing from two devices must both apply (no lost update).
- **No negative balance** — but Firestore Security Rules can't cheaply enforce "result ≥ 0" (needs a read), and offline-first forbids a server round-trip on every spend.

### Requirements
- Earn only on approval; spend only in Shop; no other source or sink.
- All balance mutation via `FieldValue.increment()`, never absolute `set()`.
- A ≥0 floor with a clearly-owned enforcement point.
- A realtime `xuBalanceProvider` (int) scoped to the active child.
- Graceful handling of a (bug-induced) negative balance: display 0, block spending, log — never crash.

## Decision

**1. Single currency (xu), increment-only mutation.**
xu is the only currency. All balance changes use `FieldValue.increment(±N)` — never absolute `set()` — inheriting ADR-0003's `atomic_write_mechanism` and honoring the registered `absolute_set_on_balance_or_counters` forbidden pattern. This makes concurrent approvals from two offline devices both apply correctly (server-side additive resolution, no lost update). No dual currency, no IAP, no ad-reward path.

**2. Sources and sinks are closed.**
- **Sources**: task approval (`+task.xuReward`, via Parent Approval's transaction) and Gacha chest reward (`+chest.xuBonus`/`+xuConsolation`, via Gacha's write). Nothing else.
- **Sinks**: Shop item purchase (`−item.price`) and Paid Chest purchase (`−50`), both via Shop's atomic batch.
- The per-category `xuReward` values are owned by Task Library (#8); this ADR only requires that any earn is an `increment(+xuReward)`.

**3. The ≥0 floor is enforced by consuming systems pre-write — NOT by Currency, NOT by Security Rules — and MUST use a screen-level single-flight guard.**
Before any decrement, the **consuming system (Shop)** checks `xuBalance >= cost` and only then issues the decrement batch; the "Mua" button is disabled when unaffordable. Currency does not expose a guarded-decrement method, and Security Rules do not enforce `result ≥ 0`. Rationale for not centralizing the floor: (a) Firestore rules can't check a post-increment result without a read, and a rules-read on every write is costly and still racy; (b) offline-first forbids routing spends through a server function.

**Mandatory single-flight guard (closes an honest-client race).** The affordability check reads the balance from the `xuBalanceProvider` stream and the decrement is a separate batch — a read-then-write with a gap. Without a guard, a child double-tapping "Mua" on **two different item cards** before the first purchase's optimistic balance update propagates back through the stream will have both checks pass against the same stale balance, both decrements fire, and the child receives **both items with an overspent (negative) balance**. This is reachable by a normal, unmodified client — not a modified-client concern. Therefore Shop MUST hold a **screen-scoped `isPurchasing` single-flight guard that disables ALL purchase buttons (not just the tapped one)** while any purchase batch is in flight, released on completion/failure. This closes the in-scope race while keeping the cheap `WriteBatch` (no per-purchase transaction). Deeper server-side idempotency (a transactional re-check for the truly-concurrent / modified-client case) is owned by the **Shop Purchase Pipeline & Idempotency Fix ADR (QQ-01 / TR-shop-003)** — this guard is the honest-client floor; that ADR is the backstop.

**4. `xuBalanceProvider` — realtime read, scoped to active child, via a centralized path constant.**
```dart
final xuBalanceProvider = StreamProvider<int>((ref) {
  final childId  = ref.watch(activeChildProvider)?.id;
  final parentId = ref.watch(authStateProvider).value?.uid;   // riverpod 3.x safe accessor (corrected 2026-07-13, see ADR-0002 Correction note)
  if (childId == null || parentId == null) return Stream.value(0);   // not signed in / no child
  return FirebaseFirestore.instance
      .doc(FirestorePaths.child(parentId, childId))   // centralized path constant, not inline string
      .snapshots()
      .map((doc) => (doc.data()?['xuBalance'] as num?)?.toInt() ?? 0); // num→int, 0 if absent/negative-guard in UI
});
```
This is a realtime **read** — it uses the centralized `FirestorePaths` constant (satisfying ADR-0003's `systems_building_own_firestore_paths` *intent* of no inline path strings) but is not routed through the mutation repository (the repository rule governs atomic *writes*; realtime read streams are the read layer — the same carve-out shape as the item catalog in ADR-0006). Registered as a general clarification (see registry). **Not `.autoDispose`** — deliberate: the wallet is always visible, so one shared session-lifetime listener is correct; an `.autoDispose` variant would tear down and resubscribe whenever the last watching widget unmounts (e.g. into a full-screen ceremony), causing needless listener churn.

**5. Negative-balance defense.**
If `xuBalance` is ever negative (bug / rule bypass), the UI displays `0` and disables all purchases; the value is logged. Never crash, never render a negative. (Read-side clamp for display; the stored value is not auto-corrected here — that would be a Cloud Function concern.)

### Architecture Diagram
```
SOURCES (increment +):                         SINKS (increment −):
  Parent Approval #11 → +xuReward  (txn)         Shop #13 → −item.price  (batch, AFTER affordability check)
  Gacha #12 → +xuBonus/+consolation (batch)      Shop #13 → −50 Paid Chest (batch, AFTER check)
        │                                              │
        └────────────► xuBalance (int, children/{childId}) ◄───────┘
                         mutated ONLY via FieldValue.increment() (ADR-0003)
                         ≥0 floor enforced by Shop pre-write (NOT here, NOT in rules)
                         │ snapshots()
                         ▼
       xuBalanceProvider : StreamProvider<int> (scoped to activeChild, path constant)
                         │  display clamps negative→0
                         ├──► Main Nav Shell #17 (wallet)
                         └──► Shop & Reward UI #20 (header + affordability)
```

### Key Interfaces
```dart
// READ — realtime, scoped, display-clamped (see Decision §4).
final xuBalanceProvider = StreamProvider<int>(...);

// WRITE — there is NO Currency-owned mutation method. Balance changes happen inside
// the persistence repository's atomic operations (ADR-0003), which the earning/spending
// systems call:
//   Parent Approval:  runTransaction → increment(xuBalance, +task.xuReward)
//   Gacha:            WriteBatch     → increment(xuBalance, +xuBonus)
//   Shop:             affordability check (xuBalance >= cost) THEN
//                     WriteBatch → increment(xuBalance, -cost) + inventory/chest write
// Currency defines the RULES (single currency, increment-only, ≥0 by caller); the
// repository provides the mechanism.
```

## Alternatives Considered

### Alternative A: Single currency, increment-only, consumer-enforced floor (chosen)
- **Description**: One currency; all mutation via increment; Shop checks affordability before decrementing.
- **Pros**: Concurrent-safe by construction; offline-first intact; simplest model a child can understand (Pillar 1); no extra transaction on spends.
- **Cons**: The ≥0 floor relies on the consumer doing the check (a modified client could over-spend into negative — accepted MVP tradeoff, same posture as ADR-0003, and display clamps it).
- **Rejection Reason**: N/A — chosen.

### Alternative B: Currency-layer-enforced floor (guarded read-then-decrement)
- **Description**: A `spend()` method that reads the balance and refuses if it would go negative, inside a transaction.
- **Pros**: Floor enforced centrally; harder to over-spend.
- **Cons**: Forces a `runTransaction` on every purchase (read-before-write), heavier than the Shop batch; duplicates the affordability check Shop already does for its UX (disabled button); still can't stop a fully-modified client (which wouldn't call `spend()` anyway).
- **Rejection Reason**: Extra transaction cost for a guarantee the accepted threat model doesn't require; Shop's pre-check already covers the real UX case.

### Alternative C: Dual currency / premium coin
- **Description**: A second, purchasable currency.
- **Pros**: Common monetization lever.
- **Cons**: Opens a pay-to-win path — directly violates Pillar 1 ("xu only from real effort, never shortcuts").
- **Rejection Reason**: Pillar violation. Rejected outright.

## Consequences

### Positive
- One clear balance contract for all four touching systems; concurrent-safe; offline-first.
- No extra transaction on the hot path (spends are batches, not transactions).
- Single-currency simplicity reinforces the game's core message about effort.

### Negative
- ≥0 floor is a consumer responsibility, not a hard invariant. The **honest-client double-tap race** (§3) is closed by the mandatory single-flight guard; a **truly-concurrent / modified-client** over-spend remains possible (bounded, display-clamped) and is backstopped by the QQ-01 idempotency ADR.
- Economy integrity for xu (like the rest of the economy) leans on the single-flight guard + Cloud Function server-side validation, not write-time rule guards.

### Risks
- **Honest-client double-tap over-spend** (two different item cards, stale-balance window) — reachable by a normal client, grants both items + negative balance. *Mitigation*: **mandatory screen-level single-flight guard disabling ALL purchase buttons while any purchase is in flight** (§3) — this is a required rule, not optional. Validation Criteria covers it.
- **Truly-concurrent / modified-client over-spend** (out of the single-flight guard's reach). *Mitigation*: display clamp to 0 + disabled buttons; the Shop Purchase Pipeline & Idempotency Fix ADR (QQ-01 / TR-shop-003) provides the transactional server-side backstop; accepted MVP tradeoff per ADR-0003.
- **Absolute `set()` on `xuBalance` by mistake** (would reintroduce lost-update races). *Mitigation*: registered `absolute_set_on_balance_or_counters` forbidden pattern (ADR-0003); LP-CODE-REVIEW checklist.
- **Inline path string in `xuBalanceProvider`** (the GDD's current code). *Mitigation*: use the `FirestorePaths` constant (Decision §4); GDD sync.
- **`xuBalance` read as `int` when stored as `double`** (Firestore int/double ambiguity, same class as ADR-0006). *Mitigation*: `(x as num?)?.toInt()`, not `as int`.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| currency-system.md | Single currency (xu), no dual-currency, no IAP (TR-currency-001) | Decision §1, Alt C rejected |
| currency-system.md | All balance mutation via `FieldValue.increment()` only (TR-currency-002) | Decision §1 (inherits ADR-0003) |
| currency-system.md | Balance floor (≥0) enforced pre-write by consuming systems (TR-currency-003) | Decision §3 |
| currency-system.md | `xuBalanceProvider`: realtime stream scoped to activeChild (TR-currency-004) | Decision §4 |

## Performance Implications
- **CPU**: Negligible — one `snapshots()` map per balance change.
- **Memory**: A single int per active child.
- **Load Time**: None.
- **Network**: One realtime listener per active child (the wallet is always visible — 1 stream, shared via the provider, not per-widget).

## Migration Plan
Greenfield. One GDD sync: `currency-system.md`'s `xuBalanceProvider` snippet is not just a style issue — it calls `.collection('families/$parentId/children/$childId').snapshots()`, which returns a `QuerySnapshot` (a `CollectionReference` stream), and then calls `.data()` on it — **`QuerySnapshot` has no `.data()`, so the code as written does not compile.** Fix to `.doc(FirestorePaths.child(parentId, childId)).snapshots().map((doc) => (doc.data()?['xuBalance'] as num?)?.toInt() ?? 0)`, and use the safe nullable accessor on `authStateProvider` per ADR-0002's convention (`.value` on `riverpod` 3.x — corrected 2026-07-13, see ADR-0002 Correction note; was `.valueOrNull` at original authoring).

## Validation Criteria
- Unit/integration: two concurrent `+20` approvals (offline sync) → balance rises by exactly 40 (no lost update).
- Integration: purchase with `balance >= price` decrements by exactly the price once; purchase attempt with `balance < price` is blocked (button disabled), no decrement.
- Integration (race): two rapid taps on two different affordable item cards, before the balance stream updates, result in exactly ONE purchase proceeding (the single-flight guard disables all purchase buttons after the first tap) — never two decrements against the same stale balance, never both items granted.
- Unit: `xuBalanceProvider` maps a missing/absent field to 0; a negative stored value renders as 0 in the display path.
- Review: no absolute `set()` on `xuBalance` anywhere; no inline Firestore path string in the provider.

## Related Decisions
- ADR-0003 (Firestore Schema) — owns the increment mechanism + atomic contracts + the path rule this reads under.
- ADR-0002 (Auth) — `activeChildProvider` scoping.
- Task Lifecycle & Reward Integrity ADR (upcoming) — owns the server-side reward/spend validation that is xu's real integrity backstop.
- Shop (#13) / Gacha (#12) / Parent Approval (#11) ADRs — the systems that mutate the balance under these rules.
- `design/gdd/currency-system.md` — the ratified design.
