# ADR-0012: Seed Buffer Derivation Strategy

## Status
Accepted

## Date
2026-07-17

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | Core / Economy (Firestore `FieldValue.increment` + `WriteBatch` + Riverpod `StreamProvider` + Cloud Function `runTransaction` — Platform-layer; no Flame) |
| **Knowledge Risk** | LOW — same stable, pre-cutoff Firestore/Riverpod patterns already Accepted in ADR-0003, ADR-0008, ADR-0009. No new post-cutoff surface. |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`; `design/gdd/seed-buffer.md`; ADR-0003, ADR-0008, ADR-0009; `docs/registry/architecture.yaml`; flame-specialist validation (2026-07-17) |
| **Post-Cutoff APIs Used** | None new — reuses the established `FieldValue.increment()` / `WriteBatch` / `runTransaction` patterns from ADR-0003. |
| **Verification Required** | LOW — `WriteBatch.update()`/`FieldValue.increment` are confirmed stable (ADR-0003 2026-07-13 correction). One item not yet emulator-verified: Decision §4's drift-correction transaction reads a collection query (`tasks where status == 'pending'`) inside `runTransaction` — supported server-side via the Admin SDK, but implementers should confirm against the Firestore emulator before shipping, given this project's prior history of an unverified Firestore-API assumption (ADR-0003 2026-07-13 correction). |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0003 (Firestore Schema — `WriteBatch`/`runTransaction` mechanism choices, centralized path constants), ADR-0008 (Currency & Balance Mutation Rules — `num?` cast precedent, negative-clamp `StreamProvider` pattern), ADR-0009 (Task Lifecycle — owns the `status: 'pending'` field this derivation counts and the task create/approve/reject transitions) |
| **Enables** | Parent Approval (#11) — the `-1` write this ADR defines the contract for; Task Management UI (#19) — pending list + count badge; Main Navigation Shell (#17) — Seed Badge tab-icon count |
| **Blocks** | Any Seed Buffer implementation story; any Parent Approval story that writes `seedCount` |
| **Ordering Note** | This ADR owns HOW `seedCount` stays consistent (write contract, read-side clamp, drift correction) — it does NOT own the approve/reject transaction mechanics themselves (owned by Parent Approval #11's own ADR, not yet written). Same split pattern as ADR-0009/Parent Approval. |

## Context

### Problem Statement

`seedCount` is a denormalized `int` field on `children/{childId}` that must always equal `COUNT(tasks WHERE status == 'pending')` (the GDD's own invariant). Three write paths touch it — task submit (+1), approve (-1), reject (-1) — which are simple increments. But the GDD also requires drift detection and correction (AC-8): when `seedCount` diverges from the actual pending count, a Cloud Function must recalculate and **overwrite** it with the correct value. That overwrite is an absolute `set()`, which directly conflicts with the architecture registry's existing forbidden pattern `absolute_set_on_balance_or_counters` — which names `seedCount` explicitly as a field that must only ever be mutated via `FieldValue.increment(delta)`. This ADR resolves that conflict and defines the concrete write/read contract.

### Constraints

- Task submit's `+1` must be atomic with task document creation, client-side, and offline-capable (GDD Core Rule 3: "client-side, atomic with task create").
- Approve/reject's `-1` belongs to Parent Approval's own batch (GDD: "Parent Approval (#11) batch write") — not implemented in this epic, only contracted here.
- `seedCount` must never be *displayed* as negative (AC-4), even though the underlying field could transiently go negative under a hypothetical double-decrement bug.
- The registry's `absolute_set_on_balance_or_counters` forbids direct `set()`/`update()` with an absolute value on `seedCount` — any drift-correction mechanism must either honor this or carry an explicit, justified, narrowly-scoped exception.
- `seedCount` is read via a live `StreamProvider` (per the GDD's own illustrative snippet) — the badge is a frequently-rendered, persistent UI element (pulse animation every 3s per GDD Visual Requirements), so the read path must stay O(1) (a single document field), not a live aggregation query.

### Requirements

- Must support `seedCount += 1` atomic with task creation (client, offline-capable).
- Must define the `-1` decrement contract Parent Approval's batch follows (increment only, never absolute set).
- Must never let the UI display a negative `seedCount`.
- Must support drift detection + correction without violating the increment-only rule for client-driven writes.

## Decision

**1. Increment (+1) on submit — client-side `WriteBatch`, no prior read.**
The existing task-submission flow (Task Library #8) creates the `tasks/{taskId}` document; Seed Buffer's contribution is one additional operation in that same `WriteBatch`: `FieldValue.increment(1)` on `families/{parentId}/children/{childId}.seedCount`. No `runTransaction` is needed — this is an unconditional, no-prior-read-required atomic write, matching the registry's `atomic_write_mechanism` entry ("WriteBatch for independent multi-field atomic writes with no idempotency read needed"). The child document is guaranteed to exist before any task is created under it (a child profile is created before any task can be submitted against it), so `WriteBatch.update()`'s `NOT_FOUND`-if-missing behavior is not a risk here.

This amends ADR-0003's `submitTask` Key Interface (previously a single `set()`) to a two-write `WriteBatch`; the batch is mediated by the same `PersistenceRepository` boundary ADR-0003 established, not called directly from UI code.

**2. Decrement (-1) on approve/reject — contract only, not implemented here.**
Parent Approval (#11)'s own batch/transaction must include `FieldValue.increment(-1)` on `seedCount` as one of its writes. This ADR does not implement that write (it belongs to Parent Approval's own ADR, not yet written) — it fixes the contract: **always `increment(-1)`, never an absolute set**, consistent with the registry rule.

**3. Read-side clamp — resolves AC-4 entirely within Seed Buffer's own scope.**
`seedCountProvider` clamps any raw negative value to `0` before exposing it:

```dart
final seedCountProvider = StreamProvider<int>((ref) {
  final childId = ref.watch(activeChildProvider)?.childId;
  final parentId = ref.watch(authStateProvider).value?.uid;
  if (parentId == null || childId == null) return const Stream.empty();
  return FirebaseFirestore.instance
    .doc(FirestorePaths.child(parentId, childId))   // centralized path constant, not inline string
    .snapshots()
    .map((doc) {
      final raw = (doc.data()?['seedCount'] as num?)?.toInt() ?? 0;
      return raw < 0 ? 0 : raw;
    });
});
```

Note the `as num?` cast, not `as int?` — Firestore can round-trip a numeric field as either `int` or `double` depending on write path; ADR-0008 already hit this exact cast-failure class for `xuBalance` and mandates the `num?` form project-wide. This clamp is a pure, directly unit-testable mapping — the `[LOGIC]` BLOCKING test AC-4 requires can assert against it without any Firestore integration.

A transient negative value in the raw Firestore document (from a hypothetical double-decrement bug elsewhere) is therefore invisible to the UI immediately, and self-heals via drift correction below — the clamp does not fix the underlying document, only what's displayed.

**4. Drift correction — scoped exception to `absolute_set_on_balance_or_counters`, server-only.**
A `runTransaction`-based reconciliation runs **only** inside the existing `onTaskApproved` Cloud Function (ADR-0003 §6 — an `onDocumentUpdated` trigger on the child document, already reused by ADR-0009 for reward reconciliation; it fires on both approve and reject since both write the child doc), never client-triggered: read the actual pending count (`tasks` where `status == 'pending'`) and the current `seedCount` in the same transaction; if they differ, write the corrected value within that transaction. This is a scoped carve-out — same shape as the existing `item_catalog_access` carve-out from `systems_building_own_firestore_paths` — justified because:
- The forbidden pattern's stated *reason* is multi-device **client** races (last-write-wins clobbering offline sync). This correction never runs on a client device.
- Firestore transactions are optimistic-concurrency-safe by construction (auto-retry on contention), matching the registry's own `atomic_write_mechanism` entry for read-dependent writes.
- The correction is idempotent — it recomputes from source of truth (actual pending count) rather than blind-decrementing, so even under 2nd-gen Cloud Functions' more aggressive retry/concurrency behavior, re-running it produces the same correct result.

### Key Interfaces

```dart
// Owned by Seed Buffer — read path.
final seedCountProvider = StreamProvider<int>((ref) { /* see Decision §3 */ });

// Contract only — implemented by Parent Approval (#11).
// Parent Approval's batch/transaction MUST include:
//   FieldValue.increment(-1) on families/{parentId}/children/{childId}.seedCount
// NEVER an absolute set().

// Contract only — hosted by the existing onTaskApproved Cloud Function (ADR-0003 §6).
// Drift reconciliation MUST run inside runTransaction(), server-side only:
//   1. read actual pending count: tasks where status == 'pending'
//   2. read current seedCount
//   3. if different, write the corrected value (within the same transaction)
```

## Alternatives Considered

### Alternative A (chosen): Client increment/decrement + CF transactional drift-correction + provider read clamp

- **Description**: As detailed in Decision above.
- **Pros**: Matches the GDD exactly; O(1) reads (no query cost) for a frequently-rendered badge; consistent with existing registry patterns (`WriteBatch` for independent writes, `runTransaction` for read-dependent corrections); AC-4 satisfied cleanly and testably at the provider layer.
- **Cons**: Requires a scoped, documented exception to `absolute_set_on_balance_or_counters` — one more "read the fine print" case future ADR authors must be aware of.
- **Rejection Reason**: N/A — chosen.

### Alternative C: Cloud-Function-owned-only writes (client never increments; a CF recomputes and sets `seedCount` after every task-status change)

- **Description**: No client-side increment at all. Every submit/approve/reject only writes the `tasks` document; a Cloud Function trigger recomputes and sets `seedCount` afterward.
- **Pros**: Single writer — `seedCount` can never drift by construction, since it's always recomputed from source of truth.
- **Cons**: Breaks AC-1's <1-second seed-drop latency requirement (a CF round-trip cannot be instant), and breaks entirely while offline — no CF triggers until reconnect, directly contradicting the GDD's explicit offline-submit edge case ("Task document được tạo trong Firestore local cache ngay lập tức... `seedCount += 1` cũng write vào cache").
- **Rejection Reason**: Incompatible with two explicit GDD requirements (AC-1 instant feedback, AC-5 offline submit sync).

**Considered and rejected, not evaluated as a peer alternative**: replacing the stored `seedCount` field entirely with a live Firestore `count()` aggregation query on every badge render. `count()` aggregation queries are a real Firestore feature but are billed as a distinct read operation and are not used anywhere else in this project; querying live on every render of a persistent, pulsing UI badge would add unnecessary read cost and latency for a value already reliably denormalized elsewhere in this same codebase (`xuBalance`, `storedEnergy`, `petLevel` are the identical denormalized-counter pattern, all Accepted).

## Consequences

### Positive
- Seed badge reads stay O(1) — a single document field read via the existing `StreamProvider` pattern, no new query cost.
- AC-4 ("never display negative") is satisfied by a pure, directly unit-testable function, entirely within Seed Buffer's own scope — no dependency on Parent Approval's write path being bug-free.
- Drift correction reuses an already-established, previously-reviewed pattern (transactional read-then-correct) rather than inventing a new mechanism.
- Zero new engine risk — every API used is pre-cutoff and already Accepted elsewhere in this project.

### Negative
- Adds one more scoped, documented exception to `absolute_set_on_balance_or_counters` that future ADR authors must know about (mitigated by the registry entry itself, see below).
- `seedCount`'s underlying Firestore value can be transiently wrong (too high from a failed corresponding decrement, or momentarily negative pre-clamp) between the causing event and the next CF reconciliation pass — accepted per the GDD's own framing ("Drift không gây data loss — chỉ gây visual glitch").

### Risks
- **Risk**: A future system copies the "just `set()` the counter" pattern seen in the CF reconciliation without realizing it's a scoped, server-only exception. **Mitigation**: registry entry explicitly marks it CF-only/transactional; code comment in the Cloud Function points at this ADR.
- **Risk**: The provider's read-side clamp silently masks a real, persistent bug (e.g., a system incorrectly double-decrementing on every approve, permanently drifting negative, always displayed as 0, never surfaced to anyone). **Mitigation**: the CF reconciliation pass is the actual fix (it corrects the underlying document); the provider clamp is purely a display safeguard for the transient window. No drift-alerting/monitoring is scoped for MVP — accepted per the GDD's own "harmless visual glitch" framing; revisit if drift proves non-rare in practice.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| `seed-buffer.md` | TR-seedbuffer-001 — `seedCount` invariant (`== COUNT(pending tasks)`), maintained via +1/-1 on submit/approve/reject | `WriteBatch` `increment(+1)` on submit (client-owned here); `increment(-1)` contract for Parent Approval's batch (implemented by #11) |
| `seed-buffer.md` | TR-seedbuffer-002 — `seedCount` never displays negative (AC-4) | `seedCountProvider` read-side clamp, pure and unit-testable |
| `seed-buffer.md` | TR-seedbuffer-003 — Drift detection + correction (AC-8, Formulas §"Drift detection") | CF-side `runTransaction` recalculate-and-correct; scoped exception to `absolute_set_on_balance_or_counters`, justified above |

## Performance Implications
- **CPU**: Negligible — one additional field in an existing `WriteBatch`; no new computation.
- **Memory**: Negligible — no new client-side state beyond the existing `StreamProvider` pattern.
- **Load Time**: None.
- **Network**: No new read/write beyond what the GDD already specifies — the drift-correction transaction only runs inside the existing `onTaskApproved` Cloud Function invocation (ADR-0003 §6), not as a separate network round-trip.

## Migration Plan
N/A — new system, no existing code to migrate.

## Validation Criteria
`seed-buffer.md`'s Acceptance Criteria AC-1 through AC-8, in particular:
- AC-4 (clamp at zero) — verified by a unit test directly against `seedCountProvider`'s mapping function.
- AC-8 (drift recalculation) — verified by an integration/emulator test against the CF's `runTransaction` reconciliation (or the project's established dry-run substitute if the emulator is unavailable in this environment, per the Data Persistence Layer / Task Library precedent).

## Related Decisions
- ADR-0003 (Firestore Schema & Persistence Strategy) — `WriteBatch`/`runTransaction` mechanism choices this ADR reuses.
- ADR-0008 (Currency & Balance Mutation Rules) — the `int?`/`num?` cast precedent and the `StreamProvider` negative-clamp pattern this ADR follows.
- ADR-0009 (Task Lifecycle & Reward Integrity) — owns the `status: 'pending'` field this derivation counts.
- `design/gdd/seed-buffer.md` — the GDD this ADR implements.
