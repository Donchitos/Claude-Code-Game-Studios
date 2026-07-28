# ADR-0003: Firestore Schema & Persistence Strategy

## Status
Accepted (2026-07-11 — accepted post independent /architecture-review; flame-specialist-validated at authoring)

## Date
2026-07-07

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | Core / Persistence (Cloud Firestore, offline cache, Cloud Functions — Platform-layer) |
| **Knowledge Risk** | MEDIUM — Firestore offline-persistence settings API is a real point of drift between package versions; **the flame-specialist claim below was wrong and has been corrected 2026-07-13** (see Correction note). Batch/transaction/`FieldValue.increment`/2nd-gen Cloud Function triggers/`recursiveDelete` all verified stable (LOW). |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`, `deprecated-apis.md`, `current-best-practices.md`; `design/gdd/data-persistence-layer.md`; ADR-0002; flame-specialist validation (2026-07-07); **`prototypes/petquest-core-loop-vertical-slice/` — actual compiled `cloud_firestore` 6.6.0 (2026-07-13), see Correction note** |
| **Post-Cutoff APIs Used** | `cloud_firestore` persistence configuration (see Decision §1 + Correction note below — API shape must be re-verified at final production version pinning). `FieldValue.increment()`, `WriteBatch`, `runTransaction` (stable, unaffected by this correction). Cloud Functions 2nd-gen Firestore triggers + Admin SDK `recursiveDelete`. |
| **Verification Required** | ⚠️ **Superseded 2026-07-13 — see Correction note directly below.** (Original text, kept for audit trail: "Persistence-settings API confirmed by flame-specialist (2026-07-07): the old `Settings(persistenceEnabled:/cacheSizeBytes:)` pair is `@Deprecated` in `cloud_firestore ^5.x`; the current form is `Settings(cacheSettings: PersistentCacheSettings(...))`." This was never actually compiled against a real package version at authoring time and turned out to be wrong.) |

> **Correction (2026-07-13, from `/vertical-slice` self-test + `/gate-check` Pre-Production→Production exit-criteria #1)**: the claim above — that `persistenceEnabled`/`cacheSizeBytes` is `@Deprecated` and `cacheSettings: PersistentCacheSettings(...)` replaced it in `cloud_firestore ^5.x` — is **factually wrong** for at least one real, currently-installable version. The vertical slice ran `flutter pub add cloud_firestore`, which resolved to `cloud_firestore 6.6.0` / `cloud_firestore_platform_interface 8.0.3`. Direct inspection of that package's `Settings` class (`lib/src/settings.dart`) shows **no `cacheSettings` or `PersistentCacheSettings` parameter exists at all** — the constructor only has `persistenceEnabled`, `host`, `sslEnabled`, `cacheSizeBytes`, and web-specific long-polling options. The "old, deprecated" pair is the only one that compiles. This was never verified against a real package at ADR-authoring time — the flame-specialist consultation described a plausible-sounding API evolution that doesn't match reality for this version. **Corrected Decision §1 below accordingly. Before implementation, pin the exact production `cloud_firestore` version and re-verify this section against that specific version's `Settings` class — package APIs do change over time, and 6.6.0 (2026-07-13) is a snapshot, not a permanent guarantee.**

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (Auth & PIN Security) — must be Accepted first; the schema scopes on `parentId`/`childId` from Auth, and this ADR owns the `children/{childId}/private/credentials` sub-document ADR-0002 deferred here. |
| **Enables** | Every Core/Feature system that reads or writes Firestore: Currency (#7), Task Library (#8), Parent Approval (#11), Gacha/Loot (#12), Shop (#13), Pet Equipment (#15), Pet Leveling (#16), Time & Decay (#2), Seed Buffer (#10), Parent Dashboard (#21). Their ADRs cite this schema + contract set. |
| **Blocks** | Any implementation epic that reads/writes Firestore — none may begin until this ADR is Accepted. |
| **Ordering Note** | This ADR owns the schema, offline config, Security Rules, and the *generic* write contracts (batch/transaction/increment). It does NOT own per-system business logic — e.g. the reward-integrity guard is owned by the Task Lifecycle & Reward Integrity ADR; the approve/reject transaction detail by the Parent Approval ADR. Those cite this ADR's contracts. |

## Context

### Problem Statement

PetQuest's Pillar 1 ("real discipline → real reward, no effort lost") makes durable persistence the single most important non-negotiable: if a child completes a task and the write is lost, the pillar is violated. Every system reads and writes through Firestore. Before any of them can be built, one ADR must fix the complete schema, the offline-first persistence configuration, the atomic-write contracts (when to use `WriteBatch` vs `runTransaction`), the Security Rules boundary, and the required Cloud Functions — so no system invents its own paths, its own consistency model, or its own security assumptions. The `data-persistence-layer.md` GDD specifies all of this; this ADR ratifies it, corrects a post-cutoff API drift, absorbs ADR-0002's deferred credential sub-document, and states the economy-integrity boundary honestly.

### Constraints
- **Offline-first is a hard pillar**: every player-visible mutation (submit, approve, buy, equip) must commit to the local cache immediately and sync later. This forbids routing core-loop mutations through a Cloud Function (that would add an online dependency to the core loop).
- **COPPA no-child-identity** (from ADR-0002): Firestore rules can only scope on the parent's `request.auth.uid` — they cannot distinguish parent-on-device from child-on-device.
- **`cloud_firestore ^5.x`**: persistence-settings API differs from training data (see Verification Required).
- **Document size < 1MB** (Firestore hard limit) — the schema stays far under (~500 bytes/child doc).

### Requirements
- One complete, authoritative schema; no system defines its own paths.
- Offline persistence enabled once in `main()` before any Firestore call.
- Atomic multi-field mutations that can't leave partial state (approve-task, buy-item).
- Concurrency-safe balance mutation under simultaneous offline edits from two devices.
- A security boundary consistent with ADR-0002's threat model.
- Cascade delete of a child subtree (Firestore does not cascade subcollections).

## Decision

**1. Offline-first persistence, configured once in `main()`.**
Enable Firestore offline persistence with an unlimited cache before the first Firestore operation. **(Corrected 2026-07-13 — see Correction note above.)** As verified against the actually-resolved `cloud_firestore` 6.6.0 (2026-07-13), the correct API is the `persistenceEnabled`/`cacheSizeBytes` pair — there is no `cacheSettings`/`PersistentCacheSettings` parameter on `Settings` in this version:
```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```
`Settings.CACHE_SIZE_UNLIMITED` is still the correct sentinel. Fallback tuning knob: `cacheSizeBytes: 50 * 1024 * 1024` (50MB) if old devices report storage pressure. **Re-verify this exact API shape against whichever `cloud_firestore` version is finally pinned for production** — this is a snapshot confirmed for 6.6.0, not a permanent guarantee, and this ADR was already wrong about the API once.

**2. The complete schema (ratified from the GDD, with the credential sub-document from ADR-0002).**
```
families/{parentId}
  email, displayName, fcmToken, createdAt

families/{parentId}/children/{childId}
  name, avatarId, mochiName, createdAt          (profile — rendered in selection list)
  xuBalance:int (Currency), seedCount:int (Seed Buffer),
  chestCount:int + approvedTaskCount:int (Gacha),
  storedEnergy:float + lastApprovedAt:Timestamp (Time & Decay),
  petLevel:int + totalXuEarned:int + nextLevelThreshold:int (Pet Leveling),
  equippedItems:Map<slotId,itemId> (Pet Equipment)

families/{parentId}/children/{childId}/private/credentials   ← MOVED here (ADR-0002 §7)
  pinHash:String, pinSalt:String                (owned by Auth; NOT on the profile doc,
                                                  so PIN material is not pulled into the
                                                  profile-selection working set)

families/{parentId}/children/{childId}/tasks/{taskId}
  title, flavorText, categoryId, status('pending'|'approved'|'rejected'),
  xuReward:int, energyReward:float, submittedAt, approvedAt?, rejectedAt?

families/{parentId}/customTasks/{customTaskId}   (family-scoped template; no status/reward)
  title, categoryId, targetChildId, createdAt

families/{parentId}/children/{childId}/inventory/{itemId}   (itemId = doc ID → idempotent)
  itemId, acquiredAt, source('shop'|'gacha')
```

**3. Write contracts.**
- **Predictable-ID writes** use `set(merge:true)`/`update()`; **task instances** use auto-generated IDs; **inventory** uses `itemId` as the document ID (idempotent — re-purchase overwrites `acquiredAt`, never duplicates).
- **All balance/counter mutation uses `FieldValue.increment()`, never absolute `set()`** — server-side atomic, avoids last-write-wins races when two devices sync.
- **`WriteBatch`** for independent multi-field atomic writes that need no read-before-write: *buy-item* (`increment(-price)` on xuBalance + inventory doc set). All-or-nothing.
- **`runTransaction`** for mutations requiring read-before-write (idempotency check, level-up calc): *approve/reject task*. The idempotency read (`status=='pending'`) is the FIRST read inside the transaction (owned in detail by the Parent Approval ADR; this ADR fixes only that transactions are the mechanism for read-dependent economy writes).

**4. Read contracts.**
- Child profile + economy fields: `snapshots()` streams via Riverpod `StreamProvider`, scoped to `activeChildProvider` (ADR-0002) — i.e. the single *active* child's live data, post-selection.
- Task lists: `snapshots()` with composite queries (status filter + orderBy + 30-day range → needs a composite index).
- Item catalog: one-time `get()`, session-cached — NOT `snapshots()` (owned by the Item Catalog ADR).
- Credentials sub-doc: `get()` only at PIN-entry time, never streamed.

> **Amendment (2026-07-15, Story 005 — Child Profile Data Access)**: this ADR's "child profile + economy fields → `snapshots()`" line, read literally, could be mistaken to also cover the *profile-selection list* (all ≤4 children shown on the picker screen, before any child is selected) — `design/gdd/data-persistence-layer.md`'s own Read Rules §4 phrases it as a blanket "child profile data" rule without the `activeChildProvider` qualifier this ADR uses. Clarifying explicitly: **the stream requirement is scoped to the single active child only** (matching this ADR's own "scoped to `activeChildProvider`" wording above). The pre-selection list is a separate, one-time `get()`/`FutureProvider` read (`childProfilesProvider` in `lib/providers/auth_providers.dart`) — same exception category as the item catalog line directly below, for the same reason (no realtime requirement: a sibling profile can only be added from Parent Dashboard, a session state that can't coexist with this screen being open, per ADR-0002's session-state model). `data-persistence-layer.md`'s Read Rules §4 should be updated to carry the same `activeChildProvider`-scoped qualifier next time that file is touched, to remove the ambiguity at the source.

**5. Security Rules — parent-scoped, explicit nested matches (amended by ADR-0009).**

> **Amended 2026-07-08 (ADR-0009).** The original draft used a single blanket recursive wildcard `match /families/{parentId}/{document=**} { allow read, write: if request.auth.uid == parentId }`. That is **replaced with explicit nested per-collection `match` blocks**, because Firestore rules are OR'd across matching blocks — a blanket wildcard would make any stricter per-collection rule (e.g. ADR-0009's `tasks` reward gate) inert. The permissiveness is **unchanged for every collection except `tasks`**: `xuBalance`/`petLevel`/`storedEnergy` on the child doc, inventory, and customTasks remain client-writable (the accepted MVP tradeoff below still holds for them). Only `tasks` reward/`categoryId` fields are additionally gated — see ADR-0009 §3 for the `tasks` block.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Global read-only catalog (ADR-0006)
    match /items/{itemId} { allow read: if request.auth != null; allow write: if false; }

    match /families/{parentId} {
      allow read, write: if request.auth.uid == parentId;              // family doc
      match /customTasks/{customTaskId} { allow read, write: if request.auth.uid == parentId; }
      match /children/{childId} {
        allow read, write: if request.auth.uid == parentId;            // child doc: xuBalance/petLevel/
                                                                       // storedEnergy etc. still client-writable
        match /private/credentials { allow read, write: if request.auth.uid == parentId; }
        match /inventory/{itemId}  { allow read, write: if request.auth.uid == parentId; }
        match /tasks/{taskId}      { /* reward-gated — see ADR-0009 §3 (create-validate + update-lock) */ }
      }
    }
  }
}
```
The client can still write economy fields (`xuBalance`, `petLevel`, `storedEnergy`) directly — a **deliberate, accepted MVP tradeoff**, required by offline-first (the approve/buy batches do client-side `FieldValue.increment()` — routing them server-side would break the offline core loop) and consistent with ADR-0002's Non-Goals and the accepted client-side gacha roll. Economy integrity is defended by **server-side Cloud Functions** (§6) + the `tasks` reward gate (ADR-0009), not by locking every economy field. **Post-MVP hardening** (server-authoritative economy for `xuBalance` etc.) is a tracked open question, not an MVP requirement. See Non-Goals.

**6. Cloud Functions (required).**
- `onTaskApproved` (2nd-gen Firestore trigger, `onDocumentUpdated`): post-commit cap enforcement — if `storedEnergy > 100` after an approve, set it to 100. Firestore's `increment` is atomic but does not cap.
- `onChildProfileDelete` (2nd-gen `onDocumentDeleted`): Admin SDK `firestore.recursiveDelete()` of `children/{childId}/` and all subcollections (Firestore does not cascade subcollections; client-side recursive delete is unreliable on mobile).
- (Reward-integrity server-side validation — validating `xuReward`/`energyReward` against the category table — is owned by the Task Lifecycle & Reward Integrity ADR, and is the primary economy defense given §5. Named here as a required dependency.)

### Architecture Diagram
```
main(): Settings(persistent cache, unlimited)  ← before ANY Firestore call
        │
   ┌────┴─────────────────────────────────────────────┐
   │  Firestore (local cache ⇄ cloud, offline-first)   │
   └────┬─────────────────────────────────────────────┘
        │ reads: snapshots() streams (scoped to activeChildProvider) + get() (catalog, credentials)
        │ writes: WriteBatch (buy) · runTransaction (approve/reject) · increment() (all counters)
        │
   Security Rules: request.auth.uid == parentId  (blanket family-tree scope, MVP)
        │
   Cloud Functions: onTaskApproved (cap) · onChildProfileDelete (recursiveDelete)
                    [reward-integrity validation → Task Lifecycle ADR]
```

### Key Interfaces
```dart
// Repository layer (the ONLY module that touches Firestore paths directly).
class PersistenceRepository {
  // Buy: atomic batch — increment(-price) on xuBalance + inventory/{itemId}.set(...)
  Future<void> buyItem({required String childId, required String itemId, required int price, required String source});
  // Approve/reject: runTransaction (idempotency read first) — detail in Parent Approval ADR
  Future<ApproveResult> approveTask({required String childId, required String taskId});
  Future<void> rejectTask({required String childId, required String taskId});
  // Submit: single set() with auto-ID
  Future<void> submitTask({required String childId, required TaskDraft draft});
  // Equip: single update() on equippedItems
  Future<void> equipItem({required String childId, required String slotId, required String itemId});
}
// Path constants centralized here — no system builds Firestore paths by hand.
```

## Alternatives Considered

### Alternative A: Ratify the GDD's offline-first Firestore design (chosen)
- **Description**: Client-side WriteBatch/transaction/increment, offline persistence, blanket parent-scoped rules, Cloud Functions for cap + cascade, with the credential sub-doc + persistence-API corrections.
- **Pros**: Satisfies the offline-first pillar directly; matches the already-Approved GDD; `increment()` handles the multi-device sync race correctly; idempotent inventory by doc-ID.
- **Cons**: Client can write economy fields directly (accepted MVP tradeoff, §5); post-commit cap enforcement means `storedEnergy` can momentarily exceed 100 before the Cloud Function corrects it.
- **Rejection Reason**: N/A — chosen.

### Alternative B: Server-authoritative writes (all mutations via Cloud Functions, client read-only)
- **Description**: Client never writes; every mutation is a Cloud Function call.
- **Pros**: Full economy integrity; client can't forge balances.
- **Cons**: Breaks offline-first — the core loop (submit/approve/buy) would need connectivity; adds latency; contradicts Pillar 1's "no effort lost, even offline."
- **Rejection Reason**: Directly violates the offline-first pillar. Rejected.

### Alternative C: Hybrid — client-side for non-economy state, server-side for balance/level
- **Description**: Non-economy writes (equip, submit) client-side; economy writes (xuBalance, petLevel) via Cloud Functions.
- **Pros**: Protects the economy while keeping some offline capability.
- **Cons**: The approve-task flow — the single most important offline moment (parent approves, child sees reward offline) — is exactly an economy write, so it would still require connectivity. Splits the write model into two hard-to-reason-about halves for little practical gain under the child-on-shared-device threat model.
- **Rejection Reason**: Fails the most important offline case; complexity not justified for MVP. Reconsider post-MVP as the hardening path.

## Non-Goals / Accepted Limitations
- **Client-side economy integrity is NOT enforced by Security Rules for MVP.** A modified client (outside the calibrated threat model — a child on a shared device using the shipped UI) could write economy fields directly. Accepted, consistent with ADR-0002 and client-side gacha. Server-side Cloud Functions provide post-hoc defense; full server-authoritative economy is deferred (see Open Questions in the master architecture doc).
- **`onTaskApproved` cap is post-commit**, so `storedEnergy` can briefly read >100 between the client increment and the Cloud Function correction. Acceptable — the UI clamps display, and the corrected value converges within the function's execution window.

## Consequences

### Positive
- One authoritative schema + contract set; no system invents paths or consistency models.
- Offline-first pillar fully satisfied; `increment()` makes multi-device sync safe by construction.
- Credential material isolated from the profile-selection working set (ADR-0002 §7 realized).

### Negative
- Two atomic mechanisms to reason about (WriteBatch vs runTransaction) — but the split is principled (read-dependent → transaction).
- Economy integrity depends on Cloud Functions + honest documentation of the client-write limitation, not on the rules themselves.

### Risks
- **`FieldValue.increment()` takes a `num` and can silently widen a field's type.** `xuBalance` is `int`; `storedEnergy` is `double`. Passing a `double` increment to an `int` field (or vice-versa) will widen/narrow the stored type and break downstream `as int` casts. *Mitigation*: in the repository write contracts, the increment literal's type MUST match the target field's stored type (`int` reward → `int` increment on `xuBalance`; `double` energy → `double` increment on `storedEnergy`).
- **`recursiveDelete` is not atomic** — a mid-run failure can leave a partial subtree. *Mitigation*: delete is idempotent, so a retry is safe. (It correctly deletes descendants by path prefix even though `onDocumentDeleted` fires after the parent doc is already gone; descendant count is well under any timeout given the ≤100 tasks / ≤500 inventory tuning knobs.)
- **`onTaskApproved` triggers on ANY update to the child doc** (buy, equip, level-up all touch it), not only on task approval — so it runs needlessly on non-approval writes. *Mitigation*: self-limiting (the cap-correction write converges `storedEnergy` ≤100, no infinite loop); the Task Lifecycle & Reward Integrity ADR (which owns this function's detail) may narrow the trigger or early-return when `storedEnergy ≤ 100`.
- **Composite index required** for the task queries (status equality + range + `orderBy(submittedAt)`). *Mitigation*: define in `firestore.indexes.json` at implementation; a missing index fails loudly with a console link. Indexes are direction-specific — if both ascending and descending `orderBy(submittedAt)` are ever needed, both index entries are required.
- **`CACHE_SIZE_UNLIMITED` storage pressure on old devices**. *Mitigation*: documented 50MB `cacheSizeBytes: 50 * 1024 * 1024` fallback tuning knob.
- **Economy write forgery by a modified client** (out of threat-model scope). *Mitigation*: Cloud Function validation (reward-integrity ADR) + accepted-limitation documentation; post-MVP server-authoritative hardening tracked.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| data-persistence-layer.md | Offline persistence + unlimited cache set once in `main()` (TR-data-persistence-001) | Decision §1 (+ persistence-API verification note) |
| data-persistence-layer.md | Full schema: families/children/tasks/customTasks/inventory (TR-data-persistence-002) | Decision §2, with credential sub-doc added |
| data-persistence-layer.md | Atomic WriteBatch contracts: approve (5 fields), buy (2 fields) (TR-data-persistence-003) | Decision §3 — approve upgraded to runTransaction (read-dependent), buy stays batch |
| data-persistence-layer.md | All balance/counter mutation via `FieldValue.increment()` (TR-data-persistence-004) | Decision §3 |
| data-persistence-layer.md | Cloud Function `onTaskApproved` cap enforcement (TR-data-persistence-005) | Decision §6 |
| data-persistence-layer.md | Cloud Function `onChildProfileDelete` recursive delete (TR-data-persistence-006) | Decision §6 |
| data-persistence-layer.md | Security Rules scoped on `request.auth.uid == parentId` (TR-data-persistence-007) | Decision §5 + Non-Goals |
| data-persistence-layer.md | Document size budget < 1MB (TR-data-persistence-008) | Decision §2 (schema ~500 bytes/doc) |
| auth-account.md | PIN credentials storage location (ADR-0002 §7 deferral) | Decision §2 — `children/{childId}/private/credentials` sub-doc |

## Performance Implications
- **CPU**: Negligible — Firestore SDK handles cache/sync off the main path.
- **Memory**: Unlimited cache can grow on-device; 50MB fallback knob. Credential sub-doc keeps PIN material out of the profile-list read set.
- **Load Time**: Cold start reads from local cache first (instant), syncs in background.
- **Network**: Each `snapshots()` listener = 1 read per change (cost-model open question at 1000+ families — flagged, not MVP-blocking).

## Migration Plan
Greenfield — no existing data. Doc-level updates land alongside this ADR (see GDD sync):
1. `data-persistence-layer.md` schema — move `pinHash`/`pinSalt` into `children/{childId}/private/credentials`.
2. `data-persistence-layer.md` Core Rule 1 (lines ~31-36) — use the `persistenceEnabled`/`cacheSizeBytes` form (corrected 2026-07-13 — see Correction note under Engine Compatibility above; this is the reverse of this item's original wording).
3. `docs/engine-reference/flutter-flame/current-best-practices.md` (lines ~129-135) — same persistence-settings snippet fix (corrected 2026-07-13), so the engine reference stops teaching the nonexistent `cacheSettings`/`PersistentCacheSettings` form.
4. `docs/architecture/control-manifest.md` — regenerate/patch (lines ~98-100, ~319) to match the corrected API (corrected 2026-07-13, see `docs/architecture/architecture-review-2026-07-11.md`-adjacent gate-check history for context).

## Validation Criteria
- Integration: submit/approve/buy while offline → writes appear from cache immediately, sync on reconnect with no loss.
- Unit/integration: approve transaction rolls back fully on mid-commit failure (no `xuBalance` increment without `status=='approved'`).
- Unit: re-buying an owned item creates no duplicate inventory doc and debits `xuBalance` exactly once.
- Deploy check: `onTaskApproved` caps `storedEnergy` at 100; `onChildProfileDelete` leaves no orphaned subcollection docs.
- Rules test (emulator): a session with `request.auth.uid != parentId` is denied all access to that family tree.
- Confirm the persistence-settings constructor against the live FlutterFire changelog before shipping.

## Related Decisions
- ADR-0002 (Auth & PIN Security) — upstream; owns the credential fields this schema hosts.
- Task Lifecycle & Reward Integrity ADR (upcoming) — owns the server-side reward-validation Cloud Function that is the primary economy defense given §5.
- Parent Approval ADR (upcoming) — owns the approve/reject transaction detail that uses §3's transaction mechanism.
- `design/gdd/data-persistence-layer.md` — the ratified design.
