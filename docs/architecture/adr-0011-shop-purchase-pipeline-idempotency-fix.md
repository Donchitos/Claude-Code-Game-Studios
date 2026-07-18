# ADR-0011: Shop Purchase Pipeline & Idempotency Fix

## Status
Accepted (2026-07-11 — accepted post independent /architecture-review; flame-specialist-validated at authoring)

## Date
2026-07-11

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | Core / Data Persistence & Concurrency (Firestore `runTransaction` + Security Rules — Platform layer; no Flame surface at all) |
| **Knowledge Risk** | LOW — `runTransaction`, `FieldValue.increment()`, and Security Rules `match` composition are stable, pre-cutoff Firestore semantics, already governed by ADR-0003/ADR-0009. No new post-cutoff API surface. |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md` (no transaction-related entries found); `design/gdd/shop-system.md`, `design/gdd/shop-reward-ui.md`, `design/gdd/parent-approval.md`; ADR-0003, ADR-0006, ADR-0008, ADR-0009 |
| **Post-Cutoff APIs Used** | None new. `cloud_firestore ^5.x` `runTransaction`/`FieldValue.increment()` inherited from ADR-0003. |
| **Verification Required** | flame-specialist to confirm the client-generated-idempotency-token lifecycle (§ Decision 3) and the offline-blocking behavior of `runTransaction` against current `cloud_firestore ^5.x` semantics — same verification class as ADR-0009's parent-approval precedent, not new ground, but worth a second confirmation since this ADR generalizes the pattern to a second system. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0003 (Firestore Schema & Persistence) — amends its `atomic_write_mechanism` decision (buy-item moves from `WriteBatch` to `runTransaction`). ADR-0006 (Item Catalog) — relies on `item_catalog`'s `write:if false` guarantee that `item.price` cannot be client-forged. ADR-0008 (Currency & Balance Mutation) — this ADR is the explicitly-deferred "deeper server-side idempotency" backstop ADR-0008 named (QQ-01/TR-shop-003); does not change ADR-0008's single-flight guard requirement, which stays mandatory. |
| **Enables** | Shop System (#13) implementation epic (TR-shop-001..004) and Shop & Reward UI (#20)'s `navLocked` guard (TR-shopui-002), which needs the `onAnimationComplete` interface this ADR defines. |
| **Blocks** | Shop System (#13) and Shop & Reward UI (#20) implementation — both are gated on this ADR reaching Accepted per `architecture.md`'s Required ADRs list (item #13). |
| **Ordering Note** | Amends ADR-0003 §"Atomic write contracts" in place (same pattern ADR-0009 used on ADR-0003 §5) — both should be reviewed together. Does not touch ADR-0008's file; ADR-0008's own text already named this ADR as the destination for the backstop it deferred. |

## Context

### Problem Statement

`shop-system.md`'s purchase write is a `WriteBatch`: `FieldValue.increment(-item.price)` on `xuBalance` plus an `inventory/{itemId}.set()` (items) or `chestCount` increment (Paid Chest) — no read-before-write. `inventory/{itemId}.set()` is naturally idempotent (document ID = itemId), but the balance decrement is not: two purchase requests for the *same* item/chest that both commit — two devices on one account, or a client that perceived a failure when the write had actually landed and the child tapped "Mua" again — each fire their own decrement. `shop-system.md`'s own Edge Case section and AC-9 already flag this as a real gap, not a theoretical one, and recommend `runTransaction`. This is tracked as **QQ-01 / TR-shop-003**, surfaced independently by `/architecture-review`'s **C1**, and named directly by `architecture.md`'s Architecture Principle #4 ("Shop's TR-shop-003 gap is a violation of this principle — motivating its Required ADR"). ADR-0008 (Currency) explicitly deferred the "transactional server-side backstop" for this exact race to this ADR. This ADR also resolves **QQ-04**: the `onAnimationComplete` handoff interface between Shop's Paid Chest purchase animation and Shop & Reward UI (#20)'s `navLocked` guard, referenced in `shop-system.md` Core Rule 4 and `shop-reward-ui.md` Formula 1 but never formally defined.

### Constraints
- **No-Refund Rule** (`shop-system.md` Rule 5) — there is no refund flow, so a duplicate decrement cannot be corrected after the fact by returning xu; it must be prevented at write time.
- **Offline-first is the project default** (ADR-0003) — but Parent Approval (#11) already established the accepted precedent that a read-before-write idempotency check requires `runTransaction`, which does **not** queue offline (unlike `WriteBatch`/plain writes). This ADR knowingly extends that same tradeoff to Shop.
- **`item.price` is not client-forgeable** (ADR-0006, `write:if false` on `items/{itemId}`) — this ADR does not need a reward-integrity-style write-time rule on price; the only gap is write-time *idempotency*, not price *authenticity*.
- **The mandatory single-flight guard (ADR-0008) stays in force** — it closes the honest-client, same-device, different-item-cards race. This ADR closes the race the guard cannot reach: genuinely concurrent requests from *different* purchase calls (2 devices, or a client-perceived-failure retry) for the *same* purchase.
- **Security Rules must use explicit nested matches, never a blanket wildcard** (`blanket_recursive_firestore_rule`, ADR-0009) — any new collection this ADR introduces needs its own explicit `match` block.

### Requirements
- A duplicate commit for the same item purchase must decrement `xuBalance` **exactly once**, regardless of how many independent purchase calls reach the server (AC-9).
- A duplicate commit for the same Paid Chest purchase *attempt* must decrement `xuBalance`/increment `chestCount` **exactly once** — while a *second, distinct* Paid Chest purchase (a child legitimately buying two chests) must still succeed normally.
- The mechanism must not depend on the client behaving honestly (this ADR is explicitly the backstop for the case ADR-0008's single-flight guard cannot reach).
- Define the `onAnimationComplete` interface Shop & Reward UI (#20) needs for the Paid Chest → ceremony handoff (QQ-04).

## Decision

**1. Regular item purchase: `runTransaction`, gated on the natural key (`inventory/{itemId}`).**

The transaction reads `inventory/{itemId}` (and `children/{childId}` for balance re-check) *before* any write. If the inventory doc already exists, the transaction is a no-op — it returns `PurchaseResult.alreadyOwned` without touching `xuBalance` again. This requires no new collection and no client-generated token: item ownership is itself a `set()`-idempotent, natural dedupe key, so *any* number of duplicate purchase calls for the same item — from 2 devices or a retry — collapse to exactly one decrement. Firestore's transaction contention handling (auto-retry on a conflicting concurrent write to a document already read) makes this correct even when both commits race genuinely simultaneously, not just sequentially.

```dart
Future<PurchaseResult> buyItem(String parentId, String childId, ItemModel item) {
  final childRef = FirestorePaths.child(parentId, childId);
  final invRef = FirestorePaths.inventoryItem(parentId, childId, item.id);
  // SDK defaults (maxAttempts: 5, exponential backoff, ~30s overall timeout) are used
  // as-is — not overridden. Contention-exhausted retries throw into the unified error
  // path (§4), same as any other transaction failure.
  return FirebaseFirestore.instance.runTransaction((txn) async {
    // ALL reads before ANY writes — Firestore transaction requirement.
    final invSnap = await txn.get(invRef);
    if (invSnap.exists) return PurchaseResult.alreadyOwned;      // idempotent replay, no decrement
    final childSnap = await txn.get(childRef);
    final balance = (childSnap.data()?['xuBalance'] as num?)?.toInt() ?? 0;
    if (balance < item.price) return PurchaseResult.insufficientFunds;  // server-side re-check
    txn.update(childRef, {'xuBalance': FieldValue.increment(-item.price)});
    txn.set(invRef, {
      'itemId': item.id,
      'acquiredAt': FieldValue.serverTimestamp(),
      'source': 'shop',
    });
    return PurchaseResult.success;
  });
}
```

The server-side balance re-check is new relative to `shop-system.md`'s current design (which only pre-checks client-side) — it is not a separate decision, it is what naturally falls out of the transaction already being open for the idempotency read. This directly delivers the "transactional re-check for the truly-concurrent / modified-client case" ADR-0008 deferred to this ADR, at no extra round-trip cost.

**2. Paid Chest purchase: `runTransaction`, gated on a client-generated idempotency token.**

`chestCount` has no natural per-purchase document — owning "a chest" isn't idempotent the way owning a specific item is (buying two chests is a legitimate distinct action). The transaction is keyed instead on a **client-generated `purchaseId` (UUID v4)**, checked against a small `purchaseLog` doc read inside the same transaction before any write:

```dart
Future<PurchaseResult> buyPaidChest(String parentId, String childId, String purchaseId) {
  final childRef = FirestorePaths.child(parentId, childId);
  final logRef = FirestorePaths.purchaseLog(parentId, childId, purchaseId);
  // paidChestPrice sourced from the registry constant `gacha_paid_chest_price` (=50, xu) —
  // the same value gacha-loot.md/shop-system.md already reference. Not a fresh literal
  // (coding-standards.md: gameplay values must be data-driven, never hardcoded).
  return FirebaseFirestore.instance.runTransaction((txn) async {
    final logSnap = await txn.get(logRef);
    if (logSnap.exists) return PurchaseResult.alreadyProcessed;   // idempotent replay, no decrement
    final childSnap = await txn.get(childRef);
    final balance = (childSnap.data()?['xuBalance'] as num?)?.toInt() ?? 0;
    if (balance < paidChestPrice) return PurchaseResult.insufficientFunds;
    txn.update(childRef, {
      'xuBalance': FieldValue.increment(-paidChestPrice),
      'chestCount': FieldValue.increment(1),
    });
    txn.set(logRef, {
      'purchaseId': purchaseId,
      'type': 'paidChest',
      'processedAt': FieldValue.serverTimestamp(),
    });
    return PurchaseResult.success;
  });
}
```

**Token lifecycle (the load-bearing correctness rule):** `purchaseId` MUST be generated **once**, when the child taps "Mua Rương," and held in the purchase flow's local state for the lifetime of that logical purchase attempt — including across a manual retry after a perceived failure (re-tapping "Mua" after an error toast reuses the SAME `purchaseId`, it does not generate a fresh one). A new `purchaseId` is generated only when the child starts a genuinely new purchase (after a *successful* commit, or after backing out of the flow entirely). This is what makes the retry-after-perceived-failure case safe: if the earlier attempt actually committed server-side despite the client seeing an error, the retry's transaction reads the same `purchaseLog/{purchaseId}` doc, finds it already exists, and no-ops. Regenerating the ID on every tap would silently defeat this guard — each "retry" would look like a brand-new, legitimately-distinct purchase to the transaction.

**3. Offline behavior: purchases require connectivity, blocked with a clear message (same posture as Parent Approval).**

`runTransaction` does not queue offline — its internal `.get()` calls bypass the local persistence cache entirely (unlike plain `snapshots()`/`.get()`, which do serve cached data offline), so there is no scenario where a "warm" cache lets a purchase transaction commit without actually reaching the backend. (Confirmed by flame-specialist against `cloud_firestore ^5.x` semantics — this is the same posture already established in `parent-approval.md` Edge Case 1/7, just confirmed independently for this ADR.) Both `buyItem` and `buyPaidChest` follow the exact pattern `parent-approval.md` already established: a `connectivity_plus` pre-check disables the "Mua" button and every purchase button (reusing the existing single-flight-guard disable surface) when offline, showing **"Cần kết nối mạng để mua"** — no write attempt is made. If the device reports online but Firestore is actually unreachable, the transaction throws and falls into the same unified error path as any other transaction failure (§4) — there is no separate offline-vs-transient-error branch, matching Parent Approval's Edge Case 7 precedent.

**4. Unified transaction failure handling.**

Any `runTransaction` throw — offline, transient backend error, or contention exhausted after Firestore's internal retries — is handled identically: re-enable the purchase button(s), show the existing "Mua không thành công, thử lại" toast (`shop-system.md` AC-8, unchanged), `xuBalance`/`inventory`/`chestCount` unchanged (the transaction guarantees all-or-nothing). No client-side automatic retry loop — a new tap by the child is the retry, and per §2 that retry reuses the same `purchaseId` for the Paid Chest path.

**5. `onAnimationComplete` interface (closes QQ-04).**

This is a plain Flutter callback, not a `GameEventBus` event — no Flame component is involved; it signals a local widget-tree animation completing, per `shop-reward-ui.md`'s Formula 1 timing contract. Owned by Shop (#13), consumed by Shop & Reward UI (#20), which passes it in when composing Shop's Paid Chest purchase widget:

```dart
typedef PurchaseAnimationCompleteCallback = void Function();

class PaidChestCard extends StatefulWidget {
  final PurchaseAnimationCompleteCallback onAnimationComplete;
  const PaidChestCard({required this.onAnimationComplete, ...});
}
// Fired exactly once per successful Paid Chest purchase, from the local
// AnimationController's forward().whenComplete(...) — AFTER the transaction
// in §2 has already committed (shop-system.md Core Rule 4's existing sequence:
// transaction commits → animation plays silently → callback fires → navigate).
// Never fired for PurchaseResult.alreadyProcessed / insufficientFunds / failure —
// only on a fresh PurchaseResult.success.
```

**6. New Security Rule for `purchaseLog` — explicit nested match, not a wildcard.**

`purchaseLog` is a new collection under the child subtree; per `blanket_recursive_firestore_rule` (ADR-0009), it needs its own explicit block rather than assuming a catch-all covers it:

```
match /families/{parentId}/children/{childId}/purchaseLog/{purchaseId} {
  allow read, write: if request.auth.uid == parentId;   // same permissive parent-scope as inventory/xuBalance
}
```

No special field-level gating is needed (unlike `tasks`' reward gate) — `purchaseLog` docs carry no economically-sensitive value a client could forge to grant itself xu or items; the actual grant lives entirely in the transaction's `increment()` calls, which follow the same accepted client-economy tradeoff every other balance mutation already operates under (ADR-0003/ADR-0008).

### Architecture Diagram
```
Item purchase:                                  Paid Chest purchase:
  [Mua tap] → single-flight guard engages          [Mua Rương tap] → single-flight guard engages
       │                                                │  purchaseId generated ONCE, held in local state
       ▼                                                ▼
  connectivity_plus check ──offline──► "Cần kết nối mạng để mua" (no write attempt)
       │ online
       ▼                                                ▼
  runTransaction:                                  runTransaction:
    read inventory/{itemId}                          read purchaseLog/{purchaseId}
    ├─ exists → alreadyOwned (no-op)                  ├─ exists → alreadyProcessed (no-op)
    └─ absent → read xuBalance                        └─ absent → read xuBalance
         ├─ insufficient → insufficientFunds                ├─ insufficient → insufficientFunds
         └─ sufficient → decrement + inventory.set()         └─ sufficient → decrement + chestCount++ + purchaseLog.set()
       │                                                │
       ▼ (success)                                      ▼ (success)
  purchase animation → equip prompt                 purchase animation (silent) → onAnimationComplete()
                                                          │
                                                          ▼
                                                     Shop & Reward UI #20's navLocked guard unlocks, auto-navigates

  throw (any reason) ──► unified error path: re-enable button(s), "Mua không thành công, thử lại", no partial write
```

### Key Interfaces
```dart
enum PurchaseResult { success, alreadyOwned, alreadyProcessed, insufficientFunds }

// Owned by the persistence repository (ADR-0003), called by Shop (#13):
Future<PurchaseResult> buyItem(String parentId, String childId, ItemModel item);
Future<PurchaseResult> buyPaidChest(String parentId, String childId, String purchaseId);

// Owned by Shop (#13), consumed by Shop & Reward UI (#20):
typedef PurchaseAnimationCompleteCallback = void Function();

// New path constants (FirestorePaths, ADR-0003 convention — no inline paths):
FirestorePaths.inventoryItem(parentId, childId, itemId)
FirestorePaths.purchaseLog(parentId, childId, purchaseId)
```

## Alternatives Considered

### Alternative A: `runTransaction` + natural document key (chosen for items)
- **Description**: Read the natural idempotency key (`inventory/{itemId}`) inside the transaction before deciding to write.
- **Pros**: No new collection; correct regardless of retry count, device count, or cause; the item ID itself is the dedupe key, so nothing extra to generate or persist client-side.
- **Cons**: Requires online connectivity (no offline queueing) — a real behavior change from the current `WriteBatch`.
- **Rejection Reason**: N/A — chosen for items. Not usable as-is for Paid Chest, which has no natural per-purchase key.

### Alternative B: Keep `WriteBatch`, add Cloud Function reconciliation
- **Description**: Leave the write as a cheap `WriteBatch`; add an `onWrite`/scheduled CF that detects an anomalous double-decrement pattern and refunds it after the fact.
- **Pros**: No connectivity requirement change; cheaper hot path (no transaction read).
- **Cons**: Async — the overspend is real and visible to the child for a window before the CF corrects it, directly colliding with the No-Refund Rule's spirit (the child would see, then lose, an item/chest). Detecting "this double-decrement was actually a duplicate" heuristically (especially for Paid Chest, no natural key) is materially harder than preventing it synchronously.
- **Rejection Reason**: Violates the "prevent, don't correct" requirement implied by No-Refund; asymmetric complexity for a worse guarantee than Alternative A/C.

### Alternative C: Client-generated idempotency token (chosen for Paid Chest)
- **Description**: A UUID per purchase attempt, checked inside a transaction against a small log collection, before applying the write.
- **Pros**: Works for state with no natural per-purchase key (Paid Chest). Same guarantee class as Alternative A once the token lifecycle rule (§ Decision 2) is followed.
- **Cons**: New collection (`purchaseLog`); correctness depends on the client obeying the token-reuse-on-retry rule — a client bug that regenerates the token on every tap silently defeats the guard (this is why the rule is stated explicitly and flagged for flame-specialist validation).
- **Rejection Reason**: N/A for Paid Chest — chosen. Rejected as the *uniform* mechanism for items (assumption confirm, Alternatives question) because items already have a free, unconditionally-correct natural key that needs no new collection or client-side state.

## Consequences

### Positive
- Closes TR-shop-003 / QQ-01 / C1 completely for both purchase paths — AC-9's exact scenario (two near-simultaneous commits for the same item) is now provably safe by construction, not just "recommended."
- Delivers the transactional server-side re-check ADR-0008 deferred here, closing its "truly-concurrent / modified-client" residual risk as a side effect of the idempotency fix, at no extra round-trip.
- Defines the `onAnimationComplete` interface (QQ-04), unblocking Shop & Reward UI (#20)'s `navLocked` guard implementation.
- Item-purchase idempotency needs zero new state (`inventory/{itemId}` is already the schema) — the cheapest possible fix for the higher-frequency purchase path.

### Negative
- Shop purchases (both items and Paid Chest) now require connectivity — a genuine behavior regression from the current offline-capable `WriteBatch`, though consistent with the precedent Parent Approval already set for the same underlying reason.
- New `purchaseLog` collection grows unboundedly with repeat Paid Chest purchases (one small doc per purchase, no TTL/cleanup in this ADR) — negligible per-doc cost at MVP scale, flagged as a future housekeeping item, not blocking.
- Two different idempotency mechanisms (natural key vs. client token) for two purchase paths in the same system — a necessary asymmetry (items have a natural key, Paid Chest doesn't), documented explicitly here so implementers don't try to unify them incorrectly.

### Risks
- **`purchaseId` regenerated on retry instead of reused** — would silently defeat the Paid Chest guard, reproducing the exact double-charge this ADR exists to prevent, with no error signal (the second transaction would just see a fresh, absent log doc and proceed normally). *Mitigation*: the token-lifecycle rule is stated as a load-bearing Decision point (§2), not a footnote; flame-specialist validation requested specifically on this; add a Validation Criterion that exercises retry-with-same-token explicitly.
- **Offline purchase blocking regresses UX** for a game whose core loop is offline-first. *Mitigation*: accepted, matches Parent Approval's existing precedent — one documented pattern project-wide rather than two divergent offline stories; the blocking message is immediate and clear, not a failed-then-retried write.
- **`purchaseLog` unbounded growth**. *Mitigation*: accepted MVP tradeoff, negligible at expected purchase volumes; flagged for a future cleanup/TTL pass, not required for MVP.
- **New Security Rule match block for `purchaseLog` omitted or written as a wildcard** — would either default-deny (breaking Paid Chest entirely) or reintroduce the exact OR-semantics inertness bug ADR-0009 found. *Mitigation*: explicit rule given in Decision §6; LP-CODE-REVIEW / rules-emulator test in Validation Criteria.
- **Hot-document contention on `childRef`** — every purchase transaction both reads and writes the child doc, so two purchases in quick succession (same or different items/chest, one or two devices) contend on `childRef` even when their `invRef`/`logRef` targets differ. *Mitigation*: not a defect — the SDK auto-retries (default `maxAttempts: 5`, exponential backoff) transparently; under a genuine burst that exhausts retries, it throws and lands in the unified error path (§4), same as any other transaction failure. Confirmed by flame-specialist as an expected, already-handled contention mode, distinct from the same-item/same-token races this ADR specifically targets.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| shop-system.md | Purchase idempotency: `xuBalance` decremented exactly once under a concurrent duplicate purchase of the same item (TR-shop-003) | Decision §1 — `runTransaction` gated on `inventory/{itemId}` |
| shop-system.md | Affordability check followed by an atomic batch purchase write (TR-shop-002) | Decision §1/§2 — upgraded from `WriteBatch` to `runTransaction` with a server-side re-check |
| shop-system.md | Paid Chest purchase hands off to the ceremony via an `onAnimationComplete` callback (TR-shop-004) | Decision §5 — interface defined |
| shop-reward-ui.md | `navLocked` guard is driven by an `onAnimationComplete` callback, with a timer only as fallback ceiling (TR-shopui-002) | Decision §5 — the callback this requirement consumes |

## Performance Implications
- **CPU**: Negligible — one additional document read per purchase (the idempotency-key read), inside a transaction that was already going to touch the child document.
- **Memory**: One extra small doc (`purchaseLog/{purchaseId}`) per Paid Chest purchase; no memory impact for items (no new documents beyond the existing `inventory/{itemId}`).
- **Load Time**: None.
- **Network**: Purchases now require an active connection (§ Decision 3) — this is the main network-behavior change, not raw bandwidth.

## Migration Plan
Greenfield — no existing shipped purchases to migrate.
1. Update `data-persistence-layer.md`'s atomic-write contract table: buy-item moves from the `WriteBatch` row to the `runTransaction` row (mirrors ADR-0009's approve/reject entry).
2. **Amend ADR-0003's inventory-idempotency sentence** ("uses `itemId` as the document ID — idempotent, re-purchase overwrites `acquiredAt`, never duplicates") — that describes the old `WriteBatch` behavior where a duplicate `set()` still fires and overwrites `acquiredAt`. Under this ADR's §1, a duplicate purchase never reaches `set()` at all (short-circuits at `PurchaseResult.alreadyOwned`) — `acquiredAt` is not touched on replay. Same amend-in-place pattern ADR-0009 used on ADR-0003 §5.
3. `shop-system.md` GDD sync: Firestore writes section replaces both `batch.update`/`batch.set` snippets with the `runTransaction` versions above; Core Rule 3/4 sequence diagrams gain the offline pre-check step; AC-9 updated to assert exactly-one-decrement via the transaction mechanism explicitly (it already asserts the outcome, this makes the mechanism non-optional rather than a "recommendation").
4. Add the `purchaseLog` explicit match block (Decision §6) to the shared `firestore.rules` file (ADR-0003/0006/0009 single-file convention).
5. Add `FirestorePaths.inventoryItem()` and `FirestorePaths.purchaseLog()` constants alongside the existing `FirestorePaths.child()`/`.items()`/`.tasks()`.
6. Wire `paidChestPrice` from the registry constant `gacha_paid_chest_price` (=50 xu, already referenced by `gacha-loot.md`/`shop-system.md`) rather than a fresh Dart literal, per `coding-standards.md`'s data-driven-values rule.

## Validation Criteria
- Integration: two concurrent `buyItem()` calls for the same item (simulated via emulator, two near-simultaneous transaction attempts) → exactly one `xuBalance` decrement, exactly one `inventory/{itemId}` doc, the second call returns `PurchaseResult.alreadyOwned`.
- Integration: two concurrent `buyPaidChest()` calls with the **same** `purchaseId` (simulating a client retry reusing its token) → exactly one decrement/increment, second call returns `PurchaseResult.alreadyProcessed`.
- Integration: two `buyPaidChest()` calls with **different** `purchaseId`s (a genuinely new, distinct chest purchase) → both succeed, `chestCount` rises by 2, `xuBalance` falls by 100 — confirms the token mechanism does not block legitimate repeat purchases.
- Integration: `buyItem()`/`buyPaidChest()` with `xuBalance < price` → `PurchaseResult.insufficientFunds`, no write, matching the existing client-side affordability gate.
- Rules test (emulator): `purchaseLog` write succeeds for `request.auth.uid == parentId`, denied otherwise.
- Manual/offline test: device offline → "Mua" button disabled with "Cần kết nối mạng để mua", no transaction attempt logged.
- Review: no `purchaseId` regeneration on retry anywhere in the Paid Chest purchase flow code (the load-bearing correctness rule from Decision §2).

## Related Decisions
- ADR-0003 (Firestore Schema) — amended: buy-item's atomic-write mechanism moves to `runTransaction`.
- ADR-0006 (Item Catalog) — price integrity this ADR relies on (not re-litigated here).
- ADR-0008 (Currency & Balance Mutation) — this ADR is the backstop ADR-0008 deferred to for QQ-01/TR-shop-003; the single-flight guard ADR-0008 mandates remains in force, unchanged.
- ADR-0009 (Task Lifecycle & Reward Integrity) — precedent for the explicit-nested-match Security Rule pattern this ADR follows for `purchaseLog`.
- Parent Approval (#11) ADR (upcoming) — the original precedent for `runTransaction`'s offline-blocking behavior this ADR extends to Shop.
- `design/gdd/shop-system.md`, `design/gdd/shop-reward-ui.md` — the ratified designs this ADR implements against.
