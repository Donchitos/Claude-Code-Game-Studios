# ADR-0009: Task Lifecycle & Reward Integrity

## Status
Accepted (2026-07-11 — accepted post independent /architecture-review; flame-specialist-validated at authoring)

## Date
2026-07-08

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | Core / Economy + Security (Firestore Security Rules, Cloud Functions, composite queries — Platform-layer; no Flame) |
| **Knowledge Risk** | LOW-MEDIUM — task lifecycle + Riverpod stream queries are stable/inherited from ADR-0003. The MEDIUM piece is expressing the reward-table validation in Firestore Security Rules (map-literal comparison in rules is a real but less-commonly-written feature — verify the exact rules syntax). |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`; `design/gdd/task-library.md`; ADR-0002, ADR-0003, ADR-0008; flame-specialist validation (2026-07-08) |
| **Post-Cutoff APIs Used** | `cloud_firestore ^5.x` composite queries + Security Rules v2; Firebase Functions 2nd-gen (`onTaskApproved` reconcile). Riverpod `StreamProvider`. All inherited from ADR-0003. |
| **Verification Required** | Confirm the Security Rules syntax for validating `xuReward`/`energyReward` against a map-literal category table keyed by `categoryId` (e.g. `request.resource.data.xuReward == rewardTable[request.resource.data.categoryId].xu`), including handling an unknown/`custom` categoryId. Confirm the two composite indexes (pending: status+submittedAt; history: status(whereIn)+submittedAt-range) in `firestore.indexes.json`. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0003 (Firestore Schema — `tasks`/`customTasks` schema, composite indexes, the reward-integrity CF slot, Security Rules file), ADR-0002 (Auth — scoping), ADR-0008 (Currency — the `xuReward` this validates feeds the increment). |
| **Enables** | Parent Approval (#11 — reads the now-trustworthy stored reward + grants it), Seed Buffer (#10), Task Management UI (#19), Push Notification (#9). |
| **Blocks** | Any implementation epic that creates, approves, or lists tasks. |
| **Ordering Note** | This ADR owns the task **lifecycle**, the **reward lookup table** (the authoritative source that Currency/Time&Decay defer to), and the **reward-integrity mechanism**. It does NOT own the approve *transaction* mechanics (Parent Approval ADR) — it makes the stored reward trustworthy so that transaction can grant it safely. |

## Context

### Problem Statement

Tasks are the real-world effort that powers the whole economy: a child submits a task, a parent approves, and xu + energy are granted. Because approval is a client-side offline transaction (ADR-0003) that reads `xuReward`/`energyReward` from the task document and grants them, those stored values are directly on the economy's trust path. A modified client could write an inflated `xuReward` at task creation, then approve it for an arbitrary xu grant — the exact economy-integrity hole that ADR-0003 §5 and ADR-0008 both deferred to "the Task Lifecycle & Reward Integrity ADR." This ADR fixes the lifecycle, owns the authoritative reward table, and closes that hole by making the stored reward trustworthy *before* it can be approved.

### Constraints
- **Offline-first approve** (ADR-0003): approval is a client-side `runTransaction`; it cannot depend on a synchronous server call to derive rewards.
- **Client-created tasks** (offline submit): the child's device writes the task document, including the reward fields — so those fields are client-controlled at write time unless gated.
- **Reward table is the shared source of truth** for Currency (#7) and Time & Decay (#2), which defer their reward values here.
- **No `cancelled` state** — a submitted task can't be withdrawn (anti-gaming).
- **Composite indexes** required for the pending + history queries (ADR-0003).

### Requirements
- Lifecycle: `pending → approved | rejected`; one document per submission; no withdrawal.
- A category→(xu, energy) reward table, re-derived from `categoryId` (never hand-set by the parent for custom tasks).
- A server-side integrity guard that rejects mismatched reward values **synchronously, before approval is possible**.
- `customTasks` templates (family-scoped, no `status`/reward fields — reward re-derived when the child submits).
- `pendingTasksProvider` + `taskHistoryProvider` (30-day window) via composite-indexed queries, scoped to active child.

## Decision

**1. Task lifecycle: `pending → approved | rejected`, one-shot, no cancel.**
Each "Đã xong!" tap creates one `tasks/{taskId}` document with `status: 'pending'`. Approve → `approved` + reward grant (via Parent Approval's transaction). Reject → `rejected`, no reward. No `cancelled` state (a child can't retract a submission — anti-gaming). No auto-expire; a stale `pending` task waits indefinitely.

**2. Authoritative reward table (owned here).**
```
study:  25 xu / 20 energy      chores: 15 / 25       helping: 10 / 30
arts:   25 xu / 20 energy      sport:  15 / 25       custom:  15 / 25   (fallback for unknown/invalid)
```
This is the single source of truth; Currency (#7) and Time & Decay (#2) reference it. It exists in three mirrored places that must stay in sync: the app (client submit), the Security Rules (integrity gate, §3), and the registry (`entities.yaml` constants). An invalid/unknown `categoryId` falls back to the `custom` tier (15/25) — not exploitable (it's mid-tier, not max).

**3. Reward integrity: a Security Rule rejects mismatched rewards at write time (primary); a Cloud Function reconciles (defense-in-depth).**

⚠️ **This amends ADR-0003 §5.** Firestore Security Rules are **OR'd across all matching `match` blocks** (if *any* matching block allows, the write is allowed — there is no "narrowest wins"). ADR-0003 §5's blanket `match /families/{parentId}/{document=**} { allow write: if request.auth.uid == parentId }` matches `tasks/` and grants unconditional write — so a stricter `tasks` block *added alongside it* would be inert. Therefore ADR-0003's blanket recursive wildcard is **replaced with explicit nested per-collection `match` blocks** (see ADR-0003 §5, amended). Every collection keeps the same permissive parent-scope as before (ADR-0003's accepted client-economy tradeoff still stands for `xuBalance`, `storedEnergy`, inventory, etc.) — **only `tasks` reward/`categoryId` fields are additionally gated.**

The **primary, synchronous** guard on `tasks`: `xuReward`/`energyReward` MUST equal the category table for the written `categoryId` on **create**, and reward/category fields MUST be **immutable on update** (else create-correct-then-update-to-anything bypasses the gate). Because this is enforced at write time, no incorrect reward is ever stored, so the offline client-side approve can safely trust `task.xuReward`. The table is a rules map literal with **quoted CEL string keys** (JS-style bare-key shorthand does NOT parse in the rules language):
```
// firestore.rules (rules v2) — reward table with QUOTED keys (CEL, not JS object literal)
function rewardTable() {
  return {
    'study':  {'xu': 25, 'energy': 20}, 'arts':   {'xu': 25, 'energy': 20},
    'chores': {'xu': 15, 'energy': 25}, 'sport':  {'xu': 15, 'energy': 25},
    'helping':{'xu': 10, 'energy': 30}, 'custom': {'xu': 15, 'energy': 25},
  };
}
function rewardOk(d) {
  return d.categoryId in rewardTable()                      // unknown categoryId → false (CEL absorbs the
    && d.xuReward     == rewardTable()[d.categoryId].xu     //   out-of-range index error under &&, denies)
    && d.energyReward == rewardTable()[d.categoryId].energy;
}
match /families/{parentId}/children/{childId}/tasks/{taskId} {
  allow read:   if request.auth.uid == parentId;
  allow create: if request.auth.uid == parentId
    && request.resource.data.status == 'pending'
    && rewardOk(request.resource.data);
  allow update: if request.auth.uid == parentId
    && request.resource.data.xuReward     == resource.data.xuReward       // reward fields immutable
    && request.resource.data.energyReward == resource.data.energyReward
    && request.resource.data.categoryId   == resource.data.categoryId;
    // the pending→approved/rejected status-transition constraint lives in THIS block
    // (owned by the Parent Approval ADR) — it must not be in a broader match, or it's bypassable again.
}
```
**Defense-in-depth**: the existing `onTaskApproved` Cloud Function (ADR-0003, already caps `storedEnergy`) additionally reconciles the granted reward against `categoryId` — flags/corrects any drift past the rule. The rule is the gate; the function is the backstop. This is the server-side reward validation ADR-0003 §5 / ADR-0008 named.

**4. `customTasks` are templates, structurally distinct from task instances.**
`families/{parentId}/customTasks/{customTaskId}` holds `{ title, categoryId, targetChildId, createdAt }` — **no `status`, no `xuReward`, no `energyReward`**. A parent creating a template is not "a task done"; the real `tasks/{taskId}` instance (with `status: 'pending'` + reward re-derived from `categoryId`) is created only when the child picks the template and taps "Đã xong!". This preserves Rule 5.1 (a child submits only after real-world completion). The parent cannot set reward values — they're always re-derived from `categoryId` (protected by §3).

**5. Query providers (composite-indexed, scoped, path-constant).**
- `pendingTasksProvider`: `where(status == 'pending').orderBy(submittedAt desc)` → 1 composite index.
- `taskHistoryProvider`: `where(status, whereIn: ['approved','rejected']).where(submittedAt >= now-30d).orderBy(submittedAt desc)` → 1 composite index, with `submittedAt` indexed **descending** to match the `orderBy`. This shape (a plain `in` + a range on a different field + matching `orderBy`) is a **supported** Firestore query — deliberately `whereIn`, NOT `not-in` (which cannot combine with a range on a different field). Do not "simplify" to `not-in`.
Both scoped to `activeChildProvider`, both use `FirestorePaths` constants + the safe nullable AsyncValue accessor (`.value` on `riverpod` 3.x — corrected 2026-07-13, see ADR-0002 Correction note) + the null-guard returning `Stream.value([])` (per ADR-0008's `realtime_read_stream_path_access`). Task Management UI reverses `pending` client-side to show oldest-first (its concern, not the query's).

### Architecture Diagram
```
Child submit (offline) ─► tasks/{taskId}.set({categoryId, xuReward, energyReward, status:'pending', ...})
                             │
                    Security Rule (SYNCHRONOUS GATE, §3): reject unless
                    xuReward/energyReward == rewardTable[categoryId]  ◄── no bad reward EVER stored
                             │  (only correct rewards persist)
                             ▼
   Parent Approval (#11) client-side runTransaction reads task.xuReward → grants (SAFE to trust)
                             │
                    onTaskApproved Cloud Function: cap storedEnergy@100 + reconcile reward vs categoryId (defense-in-depth)

customTasks/{id} = {title, categoryId, targetChildId}  (TEMPLATE — no status/reward; reward re-derived on child submit)

Reads: pendingTasksProvider / taskHistoryProvider (composite-indexed, scoped, path-constant)
```

### Key Interfaces
```dart
// Reward lookup — the authoritative table (mirrors rules + registry).
({int xu, int energy}) rewardFor(String categoryId); // unknown → custom (15,25)

// Providers (composite-indexed; safe nullable AsyncValue accessor per riverpod version; Stream.value([]) on null; FirestorePaths).
final pendingTasksProvider = StreamProvider<List<TaskModel>>(...);   // status==pending, orderBy submittedAt
final taskHistoryProvider  = StreamProvider<List<TaskModel>>(...);   // status in [approved,rejected], 30d, orderBy

// customTasks template write (Parent Dashboard #21) — no reward fields.
Future<void> createCustomTaskTemplate({required String childId, required String title, required String categoryId});
```
Security-rule reward table + `firestore.indexes.json` composite indexes are part of this ADR's deliverable (merged into the single rules/index files per ADR-0003/0006).

## Alternatives Considered

### Alternative A: Security Rule at creation (primary) + Cloud Function reconcile (defense-in-depth) — chosen
- **Description**: Synchronous rule rejects mismatched rewards at write; CF backstops at approve.
- **Pros**: No incorrect reward is ever stored, so the offline client-side approve can trust `task.xuReward` without a server round-trip; synchronous; offline-first intact.
- **Cons**: The reward table is mirrored in Security Rules (must stay in sync with app + registry) — small, stable table; a rules-syntax verification is needed.
- **Rejection Reason**: N/A — chosen.

### Alternative B: Cloud Function validation at creation only
- **Description**: `onTaskCreated` validates/corrects after the write.
- **Pros**: Reward table lives only in the function (one server copy).
- **Cons**: Asynchronous — a parent could approve the task (granting the client-written reward via the offline transaction) *before* the function runs. No synchronous gate = the bad grant can already have happened. Fundamentally weaker for the offline-approve model.
- **Rejection Reason**: No synchronous protection at the moment that matters (before approval).

### Alternative C: Re-derive reward at approve time
- **Description**: Approve ignores the stored `xuReward` and re-derives from `categoryId`.
- **Pros**: Stored reward never trusted.
- **Cons**: Approve is a client-side offline transaction, so the derivation table would be client-side (client-controlled) — no security gain — unless approve becomes a Cloud Function, which breaks offline-first. Collapses into needing the Security Rule anyway.
- **Rejection Reason**: Adds no security over the rule without breaking offline; effectively Alt A with extra steps.

## Consequences

### Positive
- Closes the economy hole ADR-0003/0008 flagged: the reward on the approve trust-path is guaranteed correct at write time.
- Offline-first submit + approve both preserved (the rule is a write-time gate, not a server round-trip on approve).
- One authoritative reward table; custom tasks can't be over-rewarded.

### Negative
- The reward table is mirrored in three places (app, rules, registry) — must be kept in sync; a change is a 3-file edit.
- Security-rule map-literal validation is a slightly advanced rules feature (verification needed).

### Risks
- **Reward-table drift across the 3 mirrors.** *Mitigation*: registry `entities.yaml` is the canonical source; a test asserts app table == registry; the rules table is reviewed against the registry on any reward change (LP-CODE-REVIEW). Consider a generated rules snippet post-MVP.
- **Security-rule syntax for map-literal comparison** may differ from the illustrative form. *Mitigation*: Verification Required — confirm against the emulator before shipping.
- **Missing composite index** fails the pending/history query loudly. *Mitigation*: define both in `firestore.indexes.json` (ADR-0003 pattern).
- **`custom`/unknown categoryId** could be a soft spot. *Mitigation*: falls back to the mid-tier `custom` reward (15/25) — not max, not exploitable; the rule still requires the written reward to equal that fallback.
- **GDD provider code** uses inline paths + an unguarded `.value` + `Stream.empty()`. *Mitigation*: GDD sync (below) to path-constant + the safe nullable AsyncValue accessor (`.value` on `riverpod` 3.x, was documented as `.valueOrNull` before the 2026-07-13 correction — see ADR-0002) + `Stream.value([])`.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| task-library.md | Lifecycle pending→approved/rejected, no cancelled (TR-tasklib-001) | Decision §1 |
| task-library.md | Reward Integrity Guard — server-side validation of xu/energy vs category table (TR-tasklib-002) | Decision §3 (Security Rule primary + CF backstop) |
| task-library.md | `customTasks` template collection, structurally distinct from instances (TR-tasklib-003) | Decision §4 |
| task-library.md | `pendingTasksProvider`/`taskHistoryProvider` composite queries (status + orderBy + 30d) (TR-tasklib-004) | Decision §5 + composite indexes |
| task-library.md | Reward values data-driven lookup, never hardcoded per-task or client-settable (TR-tasklib-005) | Decision §2 (table) + §3 (rule enforces it) |

## Performance Implications
- **CPU**: Negligible — rule evaluation per task write; query mapping is small lists.
- **Memory**: Bounded task lists (30-day history window + tuning-knob caps).
- **Load Time**: Composite-indexed queries return quickly; offline cache serves instantly.
- **Network**: 2 realtime listeners (pending, history) per active child; task writes are single small docs.

## Migration Plan
Greenfield. Changes landing with this ADR:
1. **Amend ADR-0003 §5** — replace the blanket `match /families/{parentId}/{document=**}` with explicit nested per-collection matches so the `tasks` reward gate is effective (see Decision §3). Same permissiveness for all other collections; only `tasks` reward/`categoryId` fields gated.
2. **GDD sync (`task-library.md`)**: `pendingTasksProvider` AND `taskHistoryProvider` both need `FirestorePaths` constants + the safe nullable AsyncValue accessor (`.value` on `riverpod` 3.x — corrected 2026-07-13) + `Stream.value(const [])` — note `pendingTasksProvider` currently lacks even the null-guard that `taskHistoryProvider` has, so fix both, not just one.
3. **GDD edge-case correction (`task-library.md`)**: the "invalid `categoryId` → approve-time fallback (15/25)" edge case + acceptance criterion become unreachable once the create rule rejects unknown `categoryId` outright — reword to "rejected at creation; approve-time fallback is only a defensive net for legacy/corrupted data."
4. Add the reward table + 2 composite indexes (`submittedAt` **descending**) to the shared `firestore.rules` / `firestore.indexes.json` (per ADR-0003/0006 single-file rule). Consider writing the rules table `energy` values as `20.0` etc. or confirm int/float auto-widening in the emulator (the schema stores `energyReward` as double).

## Validation Criteria
- Rules test (emulator): a task create with `xuReward` not matching `categoryId`'s table value is **denied**; a matching one is allowed; an unknown `categoryId` is denied unless it equals the `custom` fallback.
- Integration: approve reads the (rule-guaranteed-correct) stored reward and grants exactly it; `onTaskApproved` reconciliation flags no drift on a correct task.
- Unit: `rewardFor('study')==(25,20)`, `rewardFor('helping')==(10,30)`, `rewardFor('bogus')==(15,25)`.
- Integration: `pendingTasksProvider` returns only pending, newest-first; `taskHistoryProvider` returns only approved/rejected within 30 days; both empty (not erroring) when signed out.
- Test: app reward table == registry `entities.yaml` values (drift guard).

## Related Decisions
- ADR-0003 (Firestore Schema) — schema, composite indexes, the CF slot, single rules file this rule joins.
- ADR-0008 (Currency) — the `xuReward` this ADR guarantees feeds the increment.
- ADR-0002 (Auth) — scoping.
- Parent Approval (#11) ADR (upcoming) — grants the now-trustworthy reward; owns the approve transaction.
- `design/gdd/task-library.md` — the ratified design.
