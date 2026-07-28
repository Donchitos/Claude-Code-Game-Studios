# Story 001: onTaskSubmitted Cloud Function

> **Epic**: Push Notification
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/push-notification.md`
**Requirement**: `TR-pushnotif-001`, `TR-pushnotif-002`, `TR-pushnotif-004`, `TR-pushnotif-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Push Notification Delivery Architecture, Decision §1 (trigger), §2 (payload), §6 (delivery guarantees)

**Engine**: Node.js/TypeScript (Firebase Cloud Functions, `functions/` — a different runtime from `src/`, see `docs/architecture/adr-0002-auth-pin-security-architecture.md` §8) | **Risk**: MEDIUM — the 2nd-gen `onDocumentCreated` trigger/payload-shape logic itself is LOW risk (stable, pre-cutoff pattern, already proven twice in this codebase via `onChildProfileDelete`/`onTaskApproved`/`onTaskRewardReconciliation`); the ADR's own overall MEDIUM rating is driven by the iOS permission/APNs behavior this story does NOT touch (that's Story 002 + the epic-level TestFlight gate).

**Already Established (do not re-derive)**:
- `families/{parentId}.fcmToken` already exists and is kept fresh — Auth & Account Story 008 (`onTokenRefresh` listener). This story only *reads* it, never writes (ADR-0010 §Ordering Note: token lifecycle is Auth's).
- The 2nd-gen Cloud Function extraction pattern (`export async function pureLogic(...)` + thin `export const trigger = onDocumentCreated/onDocumentUpdated(...)` wrapper, `jest.mock` against `firebase-admin`, `.run(event)` test seam) is already proven 3× in `functions/src/index.ts` (`cascadeDeleteChildSubcollections`, `enforceStoredEnergyCap`, `reconcileTaskReward`) — follow it exactly, do not invent a new shape.
- Task documents are already write-time reward-validated (ADR-0009's Security Rule) — an invalid task is never created, so this trigger never needs to validate the task itself, only construct and send the notification.
- No Java Runtime is available in this environment (established, existing constraint) — the Firestore/Cloud Functions emulator cannot run here; this story's tests use the same `jest.mock`-against-`firebase-admin` + `.run(event)` pattern as the 3 existing functions, not a live emulator.

**Control Manifest Rules (this layer)**:
- Required: "Cloud Function trigger MUST be 2nd-gen `onDocumentCreated` (not `onWrite` + manual guard)" — source: ADR-0010
- Required: "Payload contract fixed shape: `notification{title,body}`, `data{type,taskId,childId,deepLink}` (all data values STRINGS), `android.priority:high`, `apns.headers['apns-priority']:10`" — source: ADR-0010
- Required: "Title truncated ≤50 chars, body ≤80 chars, truncated before send" — source: ADR-0010
- Required: "`data.deepLink` fixed as `petquest://parent/tasks/pending`" — source: ADR-0010
- Required: "MVP ships with retry DISABLED" — source: ADR-0010
- Required: "Function memory config uses v2 `MemoryOption` string enum (e.g. `'256MiB'`), not a bare number" — source: ADR-0010
- Required: "Null/empty token → log + exit (task still created); invalid-token error → log, NO retry, NO token delete" — source: ADR-0010
- Forbidden: "Never send FCM directly from the client" — source: ADR-0010
- Forbidden: "Do not enable `retry:true` for MVP" — source: ADR-0010
- Forbidden: "Do not use `onWrite` + manual `before.data==null` guard" — source: ADR-0010

---

## Acceptance Criteria

*From `design/gdd/push-notification.md` Acceptance Criteria AC-1/2/3/4/6/7 and ADR-0010 Decision §1/§2/§6:*

- [x] `onTaskSubmitted` is a 2nd-gen `onDocumentCreated` trigger on `families/{parentId}/children/{childId}/tasks/{taskId}` — create-only by definition, no manual `before == null` guard.
- [x] On trigger, reads `task.title`/`task.categoryId` from the created document, `child.name` from `families/{parentId}/children/{childId}`, and `families/{parentId}.fcmToken`, then sends exactly one FCM message via the Admin SDK `messaging().send()` matching the fixed payload contract (title `"<childName> vừa hoàn thành nhiệm vụ! 🎉"`, body `"<taskTitle> — Hãy kiểm tra và approve nhé!"`, `data.type == 'task_submitted'`, `data.taskId`, `data.childId`, `data.deepLink == 'petquest://parent/tasks/pending'` — all `data` values are strings, `android.priority: 'high'`, `apns.headers['apns-priority']: '10'`).
- [x] **AC-2 (null token guard)**: if `families/{parentId}.fcmToken` is null/empty, logs a warning and exits cleanly — no exception thrown, no FCM call attempted. (Task document itself is already created by the time this trigger fires — nothing to roll back.)
- [x] **AC-3 (invalid token handling)**: if the Admin SDK's `send()` call rejects with an invalid-token-shaped error (e.g. `messaging/registration-token-not-registered`), logs the error and exits cleanly — no retry, no attempt to delete/clear the token from Firestore (token cleanup is Auth's job via `onTokenRefresh`).
- [x] **AC-4 (title truncation)**: `taskTitle` longer than 80 characters is truncated to 80 chars + `"…"` in the notification body before send; `childName`-derived title is truncated to ≤50 chars per the same rule.
- [x] **AC-6 (concurrent multi-child correctness)**: two independent trigger invocations (different `childId`s, same or different `parentId`) each read and send their OWN correct `childName`/`taskTitle` — no shared mutable state between invocations that could leak one invocation's data into another's payload.
- [x] **AC-7 (no permission granted)**: functionally identical code path to AC-2 from this Cloud Function's perspective — if the parent never granted permission, no valid `fcmToken` was ever stored, so the null/empty-token guard already covers this case. No additional code needed; note in Completion Notes that this AC is satisfied by the AC-2 guard, not a separate code path.
- [x] `retry` is NOT enabled on this trigger (no `retry: true` in trigger config) — matches the MVP-disabled default.
- [x] Memory config uses the v2 `MemoryOption` string enum (e.g. `'256MiB'`), not a bare number.

---

## Implementation Notes

*From ADR-0010 Decision §1/§2/§6 and Key Interfaces:*

```ts
export const onTaskSubmitted = onDocumentCreated(
  { document: "families/{parentId}/children/{childId}/tasks/{taskId}",
    memory: "256MiB" },
  async (event) => { /* ... */ }
);
```
- Extract the payload-construction + send logic as its OWN plain, directly-unit-testable function (matching `reconcileTaskReward`'s established pattern) — do not embed inline in the trigger handler body. Suggested shape: `export async function sendTaskSubmittedNotification({ taskData, childName, fcmToken }): Promise<void>` — takes already-read data, not raw snapshots, so the read-3-documents step and the send step can be tested independently if useful, OR takes the raw snapshots/refs if that's simpler to wire — follow whichever shape keeps the function pure and easy to construct fake inputs for, consistent with `enforceStoredEnergyCap`'s snapshot-argument precedent.
- Reads needed: the created task document (already in `event.data`, no extra read needed), the child document (`families/{parentId}/children/{childId}` — 1 extra read for `name`), the family document (`families/{parentId}` — 1 extra read for `fcmToken`). Two extra reads per invocation, both trivial per ADR-0010's own Performance Implications.
- Truncation: title-max-50 applies to the interpolated notification `title` field as a whole (which embeds `childName`), NOT literally `childName` alone truncated to 50 — read the payload contract literally: `"<childName> vừa hoàn thành nhiệm vụ! 🎉"` is the full title string, and IT must not exceed 50 chars (childName itself is expected to be short in practice — do not over-engineer a separate childName-only truncation path unless the 50-char title budget is actually exceeded).
- Body: `"<taskTitle (≤80 chars, else …)> — Hãy kiểm tra và approve nhé!"` — per the ADR's own payload example, truncation applies to `taskTitle` specifically (not the whole body string) before interpolating the fixed suffix. Follow this literally — truncate `taskTitle` to a length such that title+suffix stays reasonable, using 80 chars on `taskTitle` itself as the story's AC states (do not truncate the suffix).
- `android.priority`/`apns.headers['apns-priority']` are fixed constants, not derived from anything — hardcode per the contract.
- Mirror `reconcileTaskReward`'s error-handling shape: a `try/catch` (or `.catch()`) around the `send()` call specifically, distinguishing "FCM rejected the token" (log, exit) from any other unexpected throw (let it propagate — Cloud Functions' own execution-failure handling applies, consistent with retry being disabled).
- No retry config on the trigger definition (retry defaults to disabled/false when omitted — confirm this by reading the actual `onDocumentCreated` options type in `node_modules/firebase-functions`, do not assume).

---

## Out of Scope

- Everything client-side (permission request, iOS reminder, foreground `onMessage` handling) — Story 002 (permission logic only) + Parent Dashboard UI (#21, no epic yet, foreground banner) + Onboarding Flow (#24, no epic yet, permission-dialog UI hosting).
- `fcmToken` write/refresh — Auth & Account Story 008 (Complete).
- Deep-link route resolution for `petquest://parent/tasks/pending` — Main Navigation Shell (#17, no epic yet); this story only puts the fixed URI string in the payload.
- Actual end-to-end delivery-latency measurement (<10s target/<60s worst-case) on real infrastructure — this story's tests verify the function CONSTRUCTS and ATTEMPTS the send correctly given valid inputs (mocked Admin SDK), not real FCM network latency. The <60s AC is testable in this story only as "the function completes and calls `send()` without hanging" — true end-to-end latency is an Integration/manual concern per the ADR's own Validation Criteria, not fully verifiable without live infrastructure.
- The iOS TestFlight hardware validation gate (ADR-0010 §3) — epic-level blocker, not this story's concern (this story is 100% server-side).

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. Derived from ADR-0010's Validation Criteria and this story's own Acceptance Criteria:*

```
Test: onTaskSubmitted sends a correctly-shaped FCM payload for a valid task
  Given: a task document created with title, categoryId, a child with a name, a valid fcmToken
  When: the trigger fires
  Then: messaging().send() is called exactly once with the fixed payload contract shape —
    correct title/body interpolation, data.type/taskId/childId/deepLink all present as strings,
    android.priority='high', apns.headers['apns-priority']='10'

Test: null/empty fcmToken is a clean no-op (AC-2)
  Given: families/{parentId}.fcmToken is null (or empty string)
  When: the trigger fires
  Then: messaging().send() is never called; a warning is logged; the function resolves without throwing

Test: an invalid-token FCM error is logged, not retried, token not touched (AC-3)
  Given: messaging().send() rejects with a registration-token-not-registered-shaped error
  When: the trigger's send attempt fails
  Then: the error is logged; the function resolves without throwing; no Firestore write is
    attempted to clear/modify fcmToken

Test: a 120-char taskTitle is truncated to 80 chars + "…" in the body (AC-4)
  Given: task.title is a 120-character string
  When: the payload is constructed
  Then: the body contains the first 80 characters of the title followed by "…", not the full title

Test: two concurrent invocations for different children do not leak data across each other (AC-6)
  Given: two separate trigger invocations, childId-A/taskTitle-A and childId-B/taskTitle-B,
    fired independently (no shared module-level mutable state between calls)
  When: both run (in any order, including interleaved via Promise.all)
  Then: invocation A's sent payload contains only childId-A's data, invocation B's only childId-B's —
    no cross-contamination

Test: the trigger does not enable retry
  Given: the exported onTaskSubmitted function's own __endpoint metadata
  When: inspected
  Then: retry is not set to true (absent or explicitly false)

Test: memory config uses the v2 string enum, not a bare number
  Given: the trigger's own __endpoint metadata
  When: inspected
  Then: availableMemoryMb or equivalent reflects '256MiB' was passed as a MemoryOption string, not
    a bare numeric literal in the source (source-level check, since __endpoint may normalize the
    string to a number internally — verify by reading the actual source definition, not just the
    endpoint's post-normalization value, if the endpoint doesn't preserve the string form)
```

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `functions/test/index.test.ts` (extends the existing suite) — must exist and pass

**Status**: [x] Created — `functions/test/index.test.ts`, 60/60 passing (full suite; ~24 new/extended for this story).

---

## Dependencies

- Depends on: Auth & Account Story 008 (Complete) — `families/{parentId}.fcmToken` exists and stays fresh. Also depends on Data Persistence Layer Story 001 (Complete) — the `tasks/{taskId}` schema this trigger reads.
- Unlocks: Nothing within this epic depends on this story being first (Story 002 is independent, client-side). Unlocks the epic's own TestFlight validation gate (this story's payload contract must be correct before that manual validation is meaningful).

---

## Completion Notes

**Closed**: 2026-07-16

Implemented `sendTaskSubmittedNotification()` (plain, directly-testable function) and `onTaskSubmitted` (the thin 2nd-gen `onDocumentCreated` trigger wrapper) in `functions/src/index.ts`, following the established `enforceStoredEnergyCap`/`reconcileTaskReward` extraction pattern.

**Code review**: flame-specialist (APPROVED WITH SUGGESTIONS) + qa-tester (GAPS) run in parallel — both independently converged on the same two real findings, plus qa-tester found 2 more coverage gaps and 1 pre-existing infra gap:

1. **Confirmed bug (both reviewers)**: `taskTitle` was read with no default (`snapshot.data().title as string`) while `childName` had one — `firestore.rules`' `rewardOk()` create-rule validates reward fields but does NOT require `title` to exist, so a task document missing `title` would throw a `TypeError` inside `truncateWithEllipsis` *before* the try/catch. Fixed: `(snapshot.data().title as string | undefined) ?? ""`, mirroring `childName`'s existing pattern. Added a regression test.
2. **Confirmed edge case (flame-specialist)**: `truncateWithEllipsis` sliced by UTF-16 code unit, not Unicode code point — a truncation cut landing inside a surrogate pair (e.g. an emoji in a child-entered task title) would produce a malformed/unpaired surrogate in the sent payload. Fixed with `Array.from(value)` code-point-safe slicing. Added a regression test proving a 2-code-unit emoji straddling the cut boundary survives intact.
3. **Gaps closed (qa-tester)**: the one integration-level `.run()` test under-asserted the full payload shape (only checked 5 of 9 fields) — tightened to a full `toHaveBeenCalledWith(...)` exact match. Added missing-child-document and missing-family-document coverage at the `.run()` level (both were already safe by construction via optional chaining, but unverified by a test).
4. **Pre-existing infra gap flagged, not fixed here (qa-tester)**: `functions/` Jest suite is not wired into CI at all (`.github/workflows/tests.yml` only runs the Flutter suite) — applies to all 3 prior Cloud Functions too, not new to this story. Filed as a separate background task (`task_20ffd1eb`) rather than expanding this story's scope.

**Real version drift found independently, corrected**: none new to this story beyond the two bugs above — `retry`/`memory` option assumptions were both independently verified correct by qa-tester against the actual `firebase-functions` v2 runtime source (including confirming a bare-number `memory` regression would fail to compile, not just fail a runtime assertion).

**Test evidence**: `functions/test/index.test.ts` — 60/60 passing (full suite). `npx tsc --noEmit` and `npm run build` both clean. Full Dart suite unaffected (254/254 passing) since this story touches only `functions/`.
