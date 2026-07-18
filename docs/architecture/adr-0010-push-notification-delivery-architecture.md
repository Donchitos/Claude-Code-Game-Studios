# ADR-0010: Push Notification Delivery Architecture

## Status
Accepted (2026-07-11 — accepted post independent /architecture-review; flame-specialist-validated at authoring)

## Date
2026-07-08

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | Core / Platform (FCM, Firebase Cloud Functions, iOS/Android notification permission — Platform-layer; no Flame) |
| **Knowledge Risk** | MEDIUM — the iOS `requestAuthorization` one-shot-per-install behavior + APNs specifics and the 2nd-gen Cloud Functions trigger/retry API are post-cutoff areas that must be verified, not assumed. FCM payload shape is stable (LOW). |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`, `current-best-practices.md`, `deprecated-apis.md`; `design/gdd/push-notification.md`; ADR-0002, ADR-0003, ADR-0009; flame-specialist validation (2026-07-08) |
| **Post-Cutoff APIs Used** | `firebase_messaging ^15.x` (`requestPermission`/`onMessage`/`onTokenRefresh`); Firebase Functions 2nd-gen Firestore trigger (`onDocumentCreated`) + Admin SDK `messaging().send()`; `go_router` deep-link handling (config owned by Nav Shell ADR). |
| **Verification Required** | (1) iOS `requestAuthorization` one-shot-per-install behavior + the Settings deep-link fallback — **must be tested on real TestFlight hardware**, not simulator (per `game-concept.md` risk). (2) 2nd-gen `onDocumentCreated` retry config (`retry: true` opt-in, max attempts, backoff) — confirm the exact option name/semantics. (3) `go_router` deep-link parsing of the `petquest://` scheme (owned by Nav Shell ADR, verified there). |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0003 (Firestore Schema — the `tasks/{taskId}` trigger path + 2nd-gen CF pattern), ADR-0002 (Auth — `families/{parentId}.fcmToken` + token refresh lifecycle), ADR-0009 (Task Lifecycle — task-create is the trigger; invalid tasks are rejected at the reward rule so never fire a notification). |
| **Enables** | Parent Dashboard UI (#21 — owns the foreground `onMessage` banner + the iOS permission reminder), Main Navigation Shell (#17 — owns the deep-link route handling). |
| **Blocks** | The notification epic + any epic depending on the parent being notified of submissions. |
| **Ordering Note** | This ADR owns the **delivery mechanism** (trigger, Cloud Function, payload contract, permission contract, URI scheme). It does NOT own: token lifecycle (Auth #1), the foreground in-app banner UI (Parent Dashboard #21), or the deep-link *route resolution* (Nav Shell #17 — this ADR defines the URI, that ADR routes it). |

## Context

### Problem Statement

Pillar 4 (parent as ally) collapses without instant notification: a child submits a task, and the parent must learn of it in near-real-time to approve while the moment still matters — not hours later when they happen to open the app. The system is a pure event router: a task-create event triggers a Cloud Function that sends one FCM message to the parent's device. The decisions to fix: what triggers it (and how, on the 2nd-gen runtime), the payload contract downstream systems parse, how iOS's one-shot permission model is handled, the deep-link URI, and the delivery guarantees (fire-and-forget, accepted duplicates). The `push-notification.md` GDD specifies this; this ADR ratifies it and corrects the trigger API to the 2nd-gen idiom.

### Constraints
- **Server-side send** — FCM sends must originate from a trusted server (Admin SDK in a Cloud Function), never the client (the client can't hold the server credential, and the submitting device is often the child's).
- **Offline-first submit coexistence** — the task write may sync from an offline device later; the trigger fires when the write reaches the server, not at the child's tap.
- **iOS one-shot permission** — `requestAuthorization` shows the system dialog **once per install**; a later re-request is a silent no-op. A reminder must deep-link to Settings, not re-call it.
- **Token lifecycle is Auth's** (ADR-0002) — this system only *reads* `fcmToken`.
- **2nd-gen Cloud Functions** — consistent with ADR-0003/0009's function runtime.

### Requirements
- One trigger (MVP): task document created with `status: 'pending'` → notify the parent.
- A payload contract (notification + data + platform priority) that Parent Dashboard (foreground) and the deep-link handler both consume.
- Null/invalid-token graceful handling; fire-and-forget; accepted duplicate-push tradeoff.
- iOS permission reminder deep-links to Settings; Android may re-prompt.
- End-to-end latency target <10s / worst-case <60s (the test asserts against 60s).

## Decision

**1. Server-side, Firestore-triggered Cloud Function — `onDocumentCreated` (not `onWrite`).**
A 2nd-gen Cloud Function `onTaskSubmitted` triggers on **`onDocumentCreated`** (`firebase-functions/v2/firestore`) at `families/{parentId}/children/{childId}/tasks/{taskId}` — the create-only trigger, which needs no manual `before == null` guard. (The manual guard is unnecessary regardless of generation once a dedicated create trigger is used — `onCreate` in 1st-gen, `onDocumentCreated` in 2nd-gen; this ADR standardizes on the 2nd-gen idiom for consistency with ADR-0003/0009. The multi-wildcard subcollection path is valid for a 2nd-gen Firestore trigger.) It reads `task.title`/`categoryId`, the child's `name`, and `families/{parentId}.fcmToken`, then sends one FCM message via the Admin SDK (`messaging().send()`). Because ADR-0009's reward Security Rule rejects invalid tasks at write time, only valid `pending` tasks ever exist to trigger this — no notification fires for a task that would be invalidated.

**2. Payload contract.**
```json
{ "token": "<fcmToken>",
  "notification": { "title": "<childName> vừa hoàn thành nhiệm vụ! 🎉",
                    "body": "<taskTitle (≤80 chars, else …)> — Hãy kiểm tra và approve nhé!" },
  "data": { "type": "task_submitted", "taskId": "<id>", "childId": "<id>",
            "deepLink": "petquest://parent/tasks/pending" },
  "android": { "priority": "high" },
  "apns": { "headers": { "apns-priority": "10" } } }
```
Title truncated ≤50 chars, body ≤80 (Cloud Function truncates before send). The `data` block is the machine-readable contract for foreground handling + deep-linking; both platforms carry the same shape.

**3. iOS one-shot permission + Settings deep-link (the platform-specific rule).**
The client requests permission once during onboarding via `FirebaseMessaging.instance.requestPermission()` (the Dart plugin method; `requestAuthorization` is the underlying native iOS symbol — implementer-facing code calls `requestPermission()`). If declined: the app still works (parent opens the app manually). **On iOS, a later reminder MUST deep-link to Settings (`UIApplication.openSettingsURLString`), NOT re-call `requestPermission()`** — the second call resolves silently against the existing status and shows no dialog. Before branching the reminder logic (re-prompt vs open Settings), the client MUST read `FirebaseMessaging.instance.getNotificationSettings().authorizationStatus` (`AuthorizationStatus` enum: `authorized`/`denied`/`notDetermined`/`provisional`) to know whether the one-shot dialog has already fired. Android may re-prompt normally. Parent Dashboard (#21) owns the reminder UI but must branch on platform + status per this contract. (`provisional` authorization — a promptless quiet-notification tier — is a known future lever if reminder friction ever needs reducing; not MVP.) **This flow MUST be validated on real TestFlight hardware** (simulator does not reflect real APNs/permission behavior) before it's considered done.

> ⚠️ **Corrected 2026-07-16 (Push Notification Story 002)**: this Decision originally listed a 5th `AuthorizationStatus.ephemeral` value. Verified against the actually-resolved `firebase_messaging ^16.4.3` / `firebase_messaging_platform_interface 4.9.2`: the real enum has only 4 values (`authorized`/`denied`/`notDetermined`/`provisional`) — `ephemeral` does not exist in this version and referencing it is a compile error. Corrected here; re-verify against whatever version production ultimately pins, same as this project's other post-cutoff API corrections.

**4. Foreground handoff.**
When the app is foregrounded, the OS suppresses the tray notification; `FirebaseMessaging.onMessage` fires with the payload. Parent Dashboard (#21) owns rendering the in-app banner from that payload; this ADR only guarantees the payload is delivered to that stream.

**5. Deep-link URI (contract here; routing owned by Nav Shell).**
The `data.deepLink` is `petquest://parent/tasks/pending`. This ADR owns the **URI scheme contract**; the `go_router` deep-link parsing/route resolution (and the OS-level scheme registration in `Info.plist`/`AndroidManifest`) is owned by the Main Navigation Shell ADR (#17), which routes it to the parent pending-tasks view (respecting the session-state route guard).

**6. Delivery guarantees: fire-and-forget, accepted duplicates, no server dedup. MVP ships WITHOUT retry.**
The function sends once. FCM-level errors (invalid token) are logged, not retried (token cleanup is Auth's job via `onTokenRefresh`). For network-transient *function-execution* failures, 2nd-gen offers an opt-in `retry: true` option — but **MVP ships with retry disabled** (the safe default). Important: 2nd-gen `retry: true` is **NOT attempt-count-bounded** — it retries the same event with exponential backoff until success or the event exceeds the platform retry-age window (a time bound). There is no "max 3 attempts" knob at this API surface; a systematic handler failure could therefore produce *many* duplicate pushes over a long window, not the "2–3 rings" a bounded-retry model would imply. **Therefore: do not enable `retry: true` for MVP.** If it is ever enabled later, the handler MUST add an explicit event-staleness guard (`if (Date.now() - Date.parse(event.time) > 60_000) return;`) to bound the window — this is Google's own recommended idempotency pattern for retried event functions. A missed notification on a rare transient failure is acceptable (the parent sees the task on next app open). No dedup-key infrastructure. No server-side rate limiting (FCM's 1 msg/device/sec is ample); OS notification-tray grouping handles burst UX. (The accepted-duplicate tradeoff still applies for the ordinary case of two independent submits, and remains harmless — non-mutating + idempotent approve.)

### Architecture Diagram
```
Child "Đã xong!" ─► tasks/{taskId} created (status:'pending')   [may sync from offline later]
                       │  (reward-rule-validated at write — ADR-0009; invalid never created)
                       ▼
   Cloud Function onTaskSubmitted  (2nd-gen onDocumentCreated)
     reads task.title/categoryId + child.name + families/{parentId}.fcmToken (Auth owns lifecycle)
     truncates title/body → Admin SDK messaging().send()
       ├─ null/empty token → log + exit (task still created)
       ├─ invalid-token error → log, NO retry, NO token delete (Auth cleans up)
       └─ success → FCM → parent device
                       │
        ┌──────────────┴───────────────┐
   background: OS tray (grouped)    foreground: onMessage stream → Parent Dashboard #21 banner
                       │
        tap → deepLink petquest://parent/tasks/pending → go_router (Nav Shell #17 routes it)
```

### Key Interfaces
```
// Cloud Function (Node, 2nd-gen) — server-side, owned here.
onTaskSubmitted = onDocumentCreated(
  { document: 'families/{parentId}/children/{childId}/tasks/{taskId}',
    memory: '256MiB' },          // v2 MemoryOption string enum, NOT a bare number (1st-gen style)
  handler)                       // MVP: NO retry (see §6). If ever retry:true → add event.time staleness guard.

// Payload data contract (consumed by Parent Dashboard #21 + the deep-link handler):
//   data.type == 'task_submitted', data.taskId, data.childId,   // all data values are STRINGS
//   data.deepLink == 'petquest://parent/tasks/pending'          // (not Firestore refs)

// Client (Flutter) responsibilities defined here, implemented in Auth/#21/#17:
//   - request permission once at onboarding (positive framing)
//   - iOS reminder → openSettings, NOT re-requestAuthorization
//   - FirebaseMessaging.onMessage → hand payload to Parent Dashboard banner
```

## Alternatives Considered

### Alternative A: Server-side Firestore-triggered Cloud Function (chosen)
- **Description**: Task-create fires a 2nd-gen `onDocumentCreated` function that sends FCM via Admin SDK.
- **Pros**: Send originates from a trusted server (no client credential exposure); fires whenever the write reaches the server (offline-submit-safe); zero client involvement in delivery.
- **Cons**: Cold-start can add latency (~30s worst case — acceptable, within the 60s contract); duplicate-push possible if retry enabled (accepted).
- **Rejection Reason**: N/A — chosen.

### Alternative B: Client-side FCM send
- **Description**: The client calls FCM directly when a task is submitted.
- **Pros**: No Cloud Function.
- **Cons**: Requires the server key on the client (a credential leak); the submitting device is usually the child's — it can't reliably send to the parent, and an offline submit couldn't send at all.
- **Rejection Reason**: Insecure and doesn't work for the offline-submit / cross-device case.

### Alternative C: Scheduled/polling notification
- **Description**: The parent app periodically polls for new pending tasks and self-notifies.
- **Pros**: No push infra.
- **Cons**: Defeats the "instant" pillar (poll interval = delay); battery/quiet-background cost; iOS background execution limits make it unreliable.
- **Rejection Reason**: Not instant; platform-hostile.

## Consequences

### Positive
- Pillar 4's instant parent-awareness delivered; send is server-trusted and offline-submit-safe.
- The `onDocumentCreated` trigger is simpler and less error-prone than `onWrite` + a manual create condition.
- ADR-0009's write-time reward gate means no notification ever fires for an invalid task (a bonus consistency win — resolves the GDD's post-create-validation race).

### Negative
- Duplicate push possible (if retry enabled) — accepted, harmless (non-mutating, idempotent approve).
- Single `fcmToken` = single parent device notified (MVP; multi-device deferred to Alpha).
- Cold-start latency spikes possible (within the 60s worst-case contract).

### Risks
- **iOS permission one-shot + Settings deep-link** — the highest-risk area. *Mitigation*: Verification Required — must be validated on real TestFlight hardware; Parent Dashboard reminder branches iOS→Settings, Android→re-prompt.
- **2nd-gen retry is time-window-bounded, not attempt-count-bounded** — a systematic handler failure with `retry: true` could produce many duplicate pushes over a long window (not the "2–3 rings" a bounded model implies). *Mitigation*: MVP ships with retry **disabled** (§6); if ever enabled, an `event.time` staleness guard is mandatory. Corrected the GDD's "3-attempts" knob (GDD sync).
- **Deep-link routing not owned here** — a dangling URI if Nav Shell doesn't register/route it. *Mitigation*: explicit dependency on the Nav Shell ADR (#17); the URI contract is fixed here so both sides agree.
- **Cold start latency** up to ~30s. *Mitigation*: within the 60s contract; acceptable, notification is not on the gameplay hot path.
- **`onMessage` foreground handler missing** → no in-app indicator when foregrounded. *Mitigation*: AC-5 is BLOCKING; owned by Parent Dashboard #21, contract defined here.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| push-notification.md | Firestore `onWrite` trigger scoped to document-CREATE only (TR-pushnotif-001) | Decision §1 — corrected to 2nd-gen `onDocumentCreated` (create-only by definition) |
| push-notification.md | FCM payload: notification + data + platform-priority headers (TR-pushnotif-002) | Decision §2 |
| push-notification.md | iOS `requestAuthorization` one-shot; reminder deep-links to Settings (TR-pushnotif-003) | Decision §3 + TestFlight verification |
| push-notification.md | No dedup/idempotency infra — accepted duplicate-push tradeoff (TR-pushnotif-004) | Decision §6 |
| push-notification.md | Deep link URI `petquest://parent/tasks/pending` needs app-level config (TR-pushnotif-005) | Decision §5 (URI here; routing → Nav Shell ADR) |
| push-notification.md | Delivery latency <10s target / <60s worst, fire-and-forget, no retry-on-invalid-token (TR-pushnotif-006) | Decision §6 + Constraints |

## Performance Implications
- **CPU**: Trivial per invocation (read a few docs + one FCM send); 256MB function is generous.
- **Memory**: Minimal.
- **Load Time**: N/A (server-side).
- **Network**: One FCM send per task submit; one Firestore read set per invocation. Cold-start adds latency, not sustained cost.

## Migration Plan
Greenfield. GDD syncs to `push-notification.md`:
1. **Trigger**: reword the `onWrite` + manual `before.data == null` condition to the 2nd-gen `onDocumentCreated` trigger (create-only by definition; no manual guard).
2. **Retry (correction)**: the Formulas "Retry Policy" + the Tuning-Knobs row "FCM retry (Firebase Runtime) | 3 lần | 1–5" wrongly imply an attempt-count knob. Correct to: `retry: true` is time-window-bounded (not attempt-bounded), there is no max-attempts config, and MVP ships with retry disabled; if ever enabled, add an `event.time` staleness guard.
3. **AC-8 naming**: uses `requestAuthorization` (native symbol) — the Dart plugin method is `requestPermission()`; reword AC-8 + Core Rule 5 to `requestPermission()` and add the `getNotificationSettings().authorizationStatus` pre-check.
Everything else in the GDD (payload, iOS one-shot behavior, latency contract, null-token handling) already matches. Also note the (now-resolved) edge case: with ADR-0009's write-time reward rule an invalid task is never created, so the GDD's "notification for a just-invalidated task" race no longer applies to invalid-reward tasks.

## Validation Criteria
- Integration (AC-1): task-create → parent receives FCM within 60s (assert 60s, track 10s as metric); title has child name, body has task title.
- Unit (AC-2/3): null token → log + clean exit, task still created; invalid-token FCM error → log, no retry, no token delete.
- Unit (AC-4): 120-char title → body truncated to ≤80 + "…".
- Integration (AC-5): foreground submit → no tray notification, `onMessage` fires the correct payload.
- Unit (AC-6): two children submit concurrently → two correct notifications, no cross-invocation variable bleed (correct child/task each).
- Integration (AC-7): no permission granted → no crash, task created, FCM fails silently.
- Integration (AC-8): iOS declined → reminder opens Settings, does NOT re-call `requestAuthorization`.
- **Manual/TestFlight**: the full iOS permission + APNs delivery path on real hardware.

## Related Decisions
- ADR-0002 (Auth) — owns `fcmToken` + refresh lifecycle this reads.
- ADR-0003 (Firestore Schema) — trigger path + 2nd-gen CF pattern.
- ADR-0009 (Task Lifecycle) — task-create is the trigger; write-time reward rule keeps invalid tasks from firing.
- Main Navigation Shell (#17) ADR (upcoming) — owns the `petquest://` deep-link routing this defines the URI for.
- Parent Dashboard UI (#21) ADR (upcoming) — owns the foreground banner + iOS permission reminder UI.
- `design/gdd/push-notification.md` — the ratified design.
