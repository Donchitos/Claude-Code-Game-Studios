# ADR-0002: Auth & PIN Security Architecture

## Status
Accepted (2026-07-11 — accepted post independent /architecture-review; flame-specialist-validated at authoring)

## Date
2026-07-07

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | Core / Security (Firebase Auth, Firestore, secure storage — Platform-layer, not Flame rendering) |
| **Knowledge Risk** | LOW-MEDIUM — the security primitives (PBKDF2, Firebase Auth email/password) are stable and well within LLM training data; the only post-cutoff elements are Firebase package major versions (`firebase_auth ^5.x`, `cloud_firestore ^5.x`, `firebase_messaging ^15.x`), verified against `docs/engine-reference/flutter-flame/deprecated-apis.md`. |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`, `deprecated-apis.md`, `current-best-practices.md`; `design/gdd/auth-account.md`; flame-specialist + security-engineer validation (2026-07-07) |
| **Post-Cutoff APIs Used** | `firebase_auth ^5.x` (`invalid-credential` consolidated error code — see Decision §6), `cloud_firestore ^5.x`. `flutter_secure_storage`, `pointycastle ^3.9.0` (PBKDF2), `flutter_riverpod` — Riverpod version not yet pinned (see Risks). ⚠️ **Superseded 2026-07-15** — see Correction note below; actual resolved versions are `firebase_auth ^6.5.6`, `firebase_messaging ^16.4.3`, `pointycastle ^4.0.0`, `flutter_riverpod ^3.3.2`. |
| **Verification Required** | (1) `flutter_secure_storage` lockout-reset behavior differs by platform — iOS Keychain typically *survives* app reinstall, Android EncryptedSharedPreferences does not; verify both during QA. (2) ⚠️ Superseded 2026-07-13 — Firestore persistence-settings API was verified by ADR-0003, and the verification was **wrong** (see ADR-0003's Correction note); `PersistentCacheSettings` does not exist in the actually-resolved `cloud_firestore` 6.6.0. Not this ADR's direct concern, but the risk this line originally flagged ("verify... before ADR-0003 locks it in") was real and materialized. (3) PBKDF2 must run off the main isolate — verify no jank on low-end Android. (4) ⚠️ **New 2026-07-13**: `AsyncValue.valueOrNull` (prescribed below for `sessionStateProvider`) was removed in `riverpod` 3.x — `.value` is the safe nullable accessor there instead. Verify which applies against the exact `riverpod` version pinned for production before implementing `sessionStateProvider` (see Correction note in Decision §5). |

> **Correction (2026-07-13, from `/vertical-slice` self-test + `/gate-check` Pre-Production→Production exit-criteria #1)**: this ADR's Key Interfaces (Decision §5, below) prescribed `AsyncValue.valueOrNull` as the mandatory safe accessor, explicitly warning that `.value` "RETHROWS on AsyncError." The vertical slice, built against the actually-resolved `riverpod` 3.3.2, found this backwards for that version: **`riverpod` 3.x removed `AsyncValue.valueOrNull` entirely** — `AsyncValue.value` is now itself the safe, non-throwing nullable accessor (confirmed by reading `riverpod-3.3.2`'s `CHANGELOG.md`: "Breaking: `AsyncValue.value` now returns `null` during errors" / "Breaking: removed `AsyncValue.valueOrNull` (use `.value` instead)"). The *principle* (never use whichever accessor rethrows on error for routing-critical state) is unchanged and still correct — only the specific method name was version-dependent and wrong for 3.x. **Re-verify this against whichever exact `riverpod` version is pinned for production** before implementing `sessionStateProvider`.

> **Correction (2026-07-15, from scaffolding `src/pubspec.yaml` via `flutter pub add` against a live pub.dev resolution)**: this ADR's Engine Compatibility table assumed `firebase_auth ^5.x` and (jointly with the Push Notification ADR) `firebase_messaging ^15.x`. Actual resolution against Flutter 3.44.6/Dart 3.12.2 pins **`firebase_auth ^6.5.6`** and **`firebase_messaging ^16.4.3`** — both a major version ahead of what this ADR assumed. Also newly confirmed at scaffold time: `pointycastle` resolves to `^4.0.0` (not `^3.9.0`), consistent with the already-corrected `riverpod 3.3.2`/`cloud_firestore 6.6.0` findings from 2026-07-13. ~~**Action needed before Story 001/Story 006 implementation**: re-verify Decision §6's claim...~~ **RESOLVED 2026-07-16** (Story 010 code review): confirmed directly against the installed `firebase_auth ^6.5.6` package source (`lib/src/firebase_auth.dart`'s `signInWithEmailAndPassword` doc comment) that `network-request-failed` is real/documented for this method, AND that `invalid-credential` consolidating `wrong-password`/`user-not-found` under email-enumeration protection (default since Sept 2023) still holds verbatim on `^6.5.6` — the consolidation persisted across the major version bump. `AuthRepository.signIn()` (Story 001, extended Story 010) correctly relies on this: it never branches per credential-error-code, and separately distinguishes only `network-request-failed` (a different category — transport failure, not a credential-rejection code) for the Login Screen's distinct "no connection" UI state.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None — Foundation layer, first-in-build-order security decision (only ADR-0001, an unrelated rendering decision, precedes it). |
| **Enables** | Firestore Schema & Persistence Strategy (next ADR — owns the credential sub-document schema this ADR recommends); and every downstream ADR/system that scopes data by `parentId`/`childId` (Data Persistence #4, Bridge #5, Currency #7, Task Library #8, Push Notification #9, and all Feature/Presentation systems transitively). |
| **Blocks** | Any implementation epic touching auth, session routing, or Firestore access — none may begin until this ADR is Accepted. |
| **Ordering Note** | This ADR intentionally does NOT define the full Firestore schema or Security Rules in detail — it establishes the auth/session/PIN *decisions* and the security *boundary stance*. The Firestore Schema & Persistence Strategy ADR owns the concrete schema (including the credential sub-document path) and the complete Security Rules. |

## Context

### Problem Statement

PetQuest's entire data model scopes on `parentId` and `childId` — every Firestore document, Riverpod provider, and push notification. Before any of that can be built, the foundation must decide: how does a parent authenticate, how does a child select their profile, how is the child PIN stored and verified, what is the single source of truth for routing between session states, and — critically — what security boundary does the PIN actually enforce. The `auth-account.md` GDD specifies an approach in detail; this ADR ratifies it, corrects one factually-wrong security claim in it, and makes the PIN's real (deliberately limited) security scope explicit so that eight downstream systems build against an honest boundary rather than an assumed one.

### Constraints
- **COPPA/GDPR**: children under 13 must have NO separate auth identity. All child data lives under the parent's Firebase Auth account. This is a hard legal constraint and it directly determines the PIN's security ceiling (see Non-Goals).
- **Offline-first**: a child must be able to enter their PIN and start playing without a network connection (the pillar is a simple daily ritual). This rules out any server-round-trip PIN verification.
- **Shared device**: the app runs on the parent's phone/tablet; multiple children in one family use the same physical device and the same parent auth session.
- **Package versions**: Firebase suite on major v5.x (auth/firestore) / v15.x (messaging), per `deprecated-apis.md`.

### Requirements
- Parent auth via email/password; up to 4 child profiles per parent (MVP).
- PIN never stored plaintext; never bare SHA-256; per-child salt.
- A brute-force throttle (lockout) that survives app force-close.
- A single derived routing source of truth (`sessionStateProvider`) covering all 4 session states, that go_router reads and no other system re-derives.
- Parent override into the dashboard from a live child session, without logging the child out.
- Recursive cascade delete of a child profile (Firestore does not cascade subcollections).

## Decision

**1. Parent-only Firebase Auth; children are Firestore documents.**
The parent authenticates with Firebase Auth email/password (`signInWithEmailAndPassword`). A child is NOT a Firebase Auth principal — a child is a document `families/{parentId}/children/{childId}` identified by an auto-generated Firestore document ID (not an Auth UID).

**2. Client-side PIN verification (no server round-trip).**
On PIN entry, the parent-authed client reads the child's `pinHash` + `pinSalt`, computes `PBKDF2-HMAC-SHA256(rawPin, salt, iterations=100000, keyLength=32)` locally (via `pointycastle`), and compares to the stored hash. This is deliberately client-side to satisfy the offline-first constraint. The PBKDF2 computation MUST run off the main isolate (`Isolate.run` / `compute`) to avoid UI jank on low-end Android.

**3. PBKDF2 is retained for correct reasons — but the real defense against guessing is the lockout, not the KDF.**
PBKDF2 with per-child 16-byte random salt is kept because it is correct practice: it beats bare SHA-256, and per-child salting prevents rainbow-table attacks and cross-child hash comparison. **However, the iteration count provides negligible resistance against offline brute force of a 4-digit PIN** — the keyspace is only 10,000 values, which any commodity cracking rig exhausts in seconds once a `pinHash`/`pinSalt` pair is on-device (and it always is, by §2). The actual defense against *guessing* is the online lockout (§4), which is a UI-layer control, not a cryptographic one. This ADR explicitly corrects the GDD's claim that "PBKDF2 @ 100k iterations makes brute-force take hours" — that is false for this keyspace, and no realistic iteration count changes it. Do not over-correct into Argon2 or longer PINs; the threat model (see Non-Goals) does not warrant it.

**4. Lockout state in `flutter_secure_storage`, client-enforced.**
`failCount` (0–3) and `lockUntil` (Unix ms) live in `flutter_secure_storage` under keys `pin_fail_{childId}` / `pin_lock_{childId}` (stored as strings — `toString()`/`int.parse()` at the boundary). 3 consecutive failures → 60s lock. This survives app force-close (not bypassable by killing the app) and costs no Firestore writes per failed attempt. It is client-enforced only — acceptable under the threat model, with a named residual bypass risk (see Risks).

**5. `sessionStateProvider` is the single derived routing source of truth.**
A Riverpod `Provider<SessionState>` derives the 4-state enum from three upstream providers. go_router's redirect reads only this provider; no other system re-implements the derivation. **Because a plain Riverpod `Provider` is not `Listenable`, go_router requires an explicit refresh bridge** (`GoRouterRefreshStream` over the session stream, or `ref.listen(sessionStateProvider, (_, __) => router.refresh())`) — without it the value updates but the redirect never re-runs. This is a binding contract item, not an implementation detail. ⚠️ **Corrected 2026-07-15** (Story 003 implementation): `GoRouterRefreshStream` was removed from the `go_router` package itself in v5.0.0 and is not re-exported by `go_router ^17.3.0` (verified against the installed package source — it exists only in old CHANGELOG entries, not in `lib/`). It is not a stream-wrapping helper available to import; a team could still hand-roll an equivalent `ChangeNotifier`, but `ref.listen(sessionStateProvider, ...)` is the only one of these two options that works directly against `sessionStateProvider` (which is a `Provider`, not a `Stream`, anyway) without extra plumbing. Story 003 implements the `ref.listen` bridge.

**6. Parent override uses re-authentication, not fresh sign-in.**
The "Bố/Mẹ" override from a child session verifies the parent password via `user.reauthenticateWithCredential(EmailAuthProvider.credential(...))` — NOT a second `signInWithEmailAndPassword` (which is the wrong semantic and can churn `authStateChanges()`, flickering the session state). On success, `parentOverrideProvider = true` (→ `parentView`); on "done", `parentOverrideProvider = false` returns directly to `childSelected` with no PIN re-entry. Firebase Auth error handling catches `FirebaseAuthException` generically and shows one message — `firebase_auth ^5.x` already consolidates `wrong-password`/`user-not-found` into `invalid-credential` server-side to prevent email enumeration, so do NOT resurrect per-code branching from older examples.

**7. Credentials stored in a private sub-document (recommended; schema owned by the next ADR).**
`pinHash`/`pinSalt` should live in a `children/{childId}/private/credentials` sub-document, fetched only at PIN-entry, NOT on the `children/{childId}` document used to render the profile-selection list (avatar + name). This is defense-in-depth (smaller memory-exposure window). ADR-0002 recommends this pattern; the exact schema path and its Security Rule are decided by the Firestore Schema & Persistence Strategy ADR, which owns the schema.

**8. Cloud Functions for cascade delete and GDPR erasure.**
`onChildProfileDelete` (2nd-gen Firestore trigger, `onDocumentDeleted`) recursively deletes `children/{childId}/` and subcollections via Admin SDK `firestore.recursiveDelete(ref)`. **GDPR right-to-erasure** (previously an open question in the GDD) is decided here: a Cloud Function that (a) recursively deletes `families/{parentId}/` one level higher — same pattern — and (b) deletes the Firebase Auth user record. Implementation may land later, but the decision is recorded now with a **must-land-before-launch** flag; owner: whoever owns the account-deletion epic.

### Architecture Diagram

```
Firebase Auth (parent only)
  authStateChanges() ─► authStateProvider : StreamProvider<User?>
                                   │
Child PIN (client-side verify)     │   activeChildProvider : StateProvider<ChildProfile?>
  read children/{id}/private/       │   parentOverrideProvider : StateProvider<bool>
  credentials → PBKDF2 compare      │            │
  (off-isolate) + secure_storage    ▼            ▼
  lockout             sessionStateProvider : Provider<SessionState>   ◄── SINGLE routing SoT
                                   │
                    GoRouterRefreshStream (explicit Listenable bridge)
                                   │
                              go_router redirect

Firestore Security Rules: request.auth.uid == parentId   (family-tree scope)
  └─ PIN is a UI boundary ABOVE this, NOT enforced by these rules (see Non-Goals)

Cloud Functions (Admin SDK): onChildProfileDelete (recursiveDelete)
                             onParentAccountErase  (recursiveDelete + Auth user delete)  [before launch]
```

### Key Interfaces

```dart
enum SessionState { unauthenticated, parentAuthed, childSelected, parentView }

// Firebase Auth's native stream.
// ⚠️ Corrected 2026-07-13 (see Correction note below) — use the SAFE NULLABLE
// ACCESSOR on AsyncValue, whichever name that is for the pinned `riverpod`
// version. Do NOT use whichever accessor RETHROWS on AsyncError for that
// version — that would crash routing on any auth-stream hiccup.
final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);
final activeChildProvider    = StateProvider<ChildProfile?>((ref) => null);
final parentOverrideProvider = StateProvider<bool>((ref) => false);

// Single routing source of truth.
final sessionStateProvider = Provider<SessionState>((ref) {
  final user = ref.watch(authStateProvider).value;   // riverpod 3.x: .value is the safe accessor (see Correction note)
  if (user == null) return SessionState.unauthenticated;
  final activeChild = ref.watch(activeChildProvider);
  if (activeChild == null) return SessionState.parentAuthed;
  return ref.watch(parentOverrideProvider)
      ? SessionState.parentView
      : SessionState.childSelected;
});

// PIN verification — client-side PBKDF2 compare + lockout gate. Hashing runs
// off the main isolate. Returns false (and increments failCount) on mismatch.
Future<bool> verifyChildPin({required String childId, required String rawPin});

// PIN reset (Core Rule 6, called by Parent Dashboard UI #21): fresh 16-byte
// salt, re-hash, reset failCount to 0, does not kick an active session.
Future<void> resetChildPin({required String childId, required String newPin});
```

## Alternatives Considered

### Alternative A: Ratify the GDD's approach (chosen)
- **Description**: Parent-only Firebase Auth + client-side PBKDF2 PIN verify + secure_storage lockout + derived `sessionStateProvider`.
- **Pros**: Satisfies offline-first and COPPA no-child-identity constraints directly; no PIN-entry latency; matches the already-Approved GDD; per-child salt correctly prevents rainbow/cross-child attacks.
- **Cons**: PIN is only a UI boundary, not a data-access boundary (see Non-Goals); lockout is client-enforced and bypassable by a technical actor (see Risks).
- **Rejection Reason**: N/A — chosen, with the GDD's overstated crypto rationale corrected.

### Alternative B: Give each child their own Firebase Auth identity (anonymous or custom-token)
- **Description**: Each child profile backed by a real auth principal, enabling Firestore rules to scope per-child.
- **Pros**: Firestore rules could enforce true per-child data isolation; PIN could gate an actual token.
- **Cons**: Directly violates the COPPA constraint (children under 13 must not have separate accounts); custom-token issuance needs a server + online dependency, breaking offline-first; massively more complex for a "sibling on a shared device" threat that doesn't justify it.
- **Rejection Reason**: COPPA-incompatible and solves for a threat actor outside the calibrated model.

### Alternative C: Server-side PIN verification via Cloud Function
- **Description**: PIN sent to a Cloud Function that verifies against a hash the client never sees, enforcing lockout server-side.
- **Pros**: Client never holds `pinHash`; lockout not bypassable by clearing local storage.
- **Cons**: Requires network for every PIN entry — breaks the offline-first daily-ritual pillar; adds latency; and delivers **zero net security gain**, because Firestore rules already grant any session on the shared device full access to all child data regardless of how PIN is verified — the PIN gates the UI, not the data.
- **Rejection Reason**: Real cost (offline dependency + latency) for no actual security improvement under this threat model.

## Non-Goals / Accepted Limitations

This is a deliberate scope statement, not an oversight — eight downstream systems build on it:

- **The PIN is a UI / psychological boundary, not a Firestore-enforced access-control boundary.** Because Security Rules scope only on `request.auth.uid == parentId` (and COPPA forbids per-child identities), Firestore cannot distinguish "parent holding the device" from "child holding the device." Any session on the shared device can, at the data layer, read every sibling's `pinHash`/`pinSalt` and every sibling's currency/task/pet data. The PIN gates only the shipped app UI.
- **The parent-password override and PIN-reset gates are likewise UI speed bumps**, for the same reason — Firestore cannot tell a parent-triggered write from a child-triggered one under one shared auth identity.
- **In scope**: protection against a 6–10-year-old sibling using the normal app UI on a shared device.
- **Explicitly out of scope**: a technically capable actor with direct Firestore/REST access, a modified client, or device-level tooling. Defending against that would require per-child identities (COPPA-incompatible) or server-side verification (breaks offline-first) for no benefit proportionate to the risk.

## Consequences

### Positive
- Offline-first PIN entry preserved; COPPA constraint satisfied by construction.
- One honest, explicitly-scoped security boundary for all downstream systems — no system builds on an assumed protection that isn't there.
- `sessionStateProvider` gives routing a single, testable source of truth.

### Negative
- Two metrics of trust to hold in mind: the PIN protects the UI, the parent account protects the data — developers must not conflate them.
- Client-enforced lockout and client-readable hashes are accepted weaknesses (bounded by the threat model).

### Risks
- **Client-side lockout is bypassable** via Android "Clear storage" or uninstall/reinstall (both wipe `failCount`), letting a determined actor grind the 10,000 keyspace in 3-guess batches. *Mitigation*: named accepted residual risk — effort (tens of seconds per clear/relaunch cycle) vastly exceeds the reward (a sibling's virtual pet state) for the target age group; server-side lockout rejected (Alt C).
- **`flutter_secure_storage` reset-on-uninstall differs by platform** — iOS Keychain typically survives reinstall (a *stricter* lockout, not weaker), Android does not. *Mitigation*: verify both in QA; note that iOS persistence is not a security regression.
- **PBKDF2 on the UI isolate would jank low-end Android.** *Mitigation*: mandate `Isolate.run`/`compute` (Decision §2).
- **Offline-first bootstrap edge**: a brand-new child profile's first PIN entry on a device that has never been online since the profile was created will find no cached credential document and fail. *Mitigation*: add to Edge Cases; require at least one online sync before first offline PIN entry, with a clear message otherwise.
- **Never log raw PIN / pinHash / pinSalt.** *Mitigation*: mask PIN text-field input from Crashlytics/Sentry breadcrumbs (auto text-field capture is a common leak vector); enforce per `coding-standards.md`.
- **Riverpod version not pinned** anywhere in the engine reference. *Mitigation*: technical-director to pin `flutter_riverpod`; confirm `StateProvider` usage isn't flagged by `riverpod_lint` in the chosen version (recent Riverpod steers toward `@riverpod`/`Notifier`).
- **COPPA verifiable parental consent** is not established by this design (the no-child-identity argument covers account creation, not consent-before-collection). *Mitigation*: flag to onboarding/legal owner — consent capture (an explicit "I am the parent/guardian" attestation + timestamp) must exist at parent signup; tracked as a gap, not owned by this ADR.
- **GDPR right-to-access/export + data-retention period** unaddressed here. *Mitigation*: cross-referenced gap, owner: account/legal — not blocking this ADR.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| auth-account.md | PBKDF2-HMAC-SHA256 100k iters, 16-byte per-child salt, never SHA-256 (TR-auth-account-003) | Ratified in Decision §2–3; corrects the GDD's overstated "hours" rationale to the accurate lockout-is-the-defense framing |
| auth-account.md | PIN fail-lockout in `flutter_secure_storage`, not Firestore (TR-auth-account-004) | Decision §4; adds named bypass risk + per-platform verification |
| auth-account.md | `sessionStateProvider` derived 4-state enum as routing SoT (TR-auth-account-005) | Decision §5; adds the safe-nullable-AsyncValue-accessor correctness fix (`.value` on `riverpod` 3.x, corrected 2026-07-13 — see Correction note above) + the go_router refresh-bridge contract |
| auth-account.md | Parent-override must not dispose the child session (TR-auth-account-006) | Decision §6 via `reauthenticateWithCredential` + `parentOverrideProvider` toggle |
| auth-account.md | `resetChildPin()` fresh salt/hash, reset failCount, no session kick (TR-auth-account-009) | Key Interfaces; unchanged from GDD |
| auth-account.md | Cloud Function `onChildProfileDelete` recursive Admin-SDK delete (TR-auth-account-007) | Decision §8; specifies 2nd-gen trigger + `recursiveDelete`; adds the GDPR parent-erasure decision |
| auth-account.md | FCM token refresh listener → `families/{parentId}.fcmToken` (TR-auth-account-008) | Retained as-is (owned jointly with Push Notification ADR) |
| auth-account.md | PIN as parent-controlled child access; max 4 profiles (TR-auth-account-001,002) | Decision §1; Non-Goals section makes the PIN's true boundary explicit |

## Performance Implications
- **CPU**: PBKDF2 100k iterations is CPU-heavy but one-shot per PIN entry — moved off the main isolate to avoid frame drops. Negligible steady-state cost.
- **Memory**: Credential sub-document (Decision §7) keeps `pinHash`/`pinSalt` out of the profile-list working set.
- **Load Time**: PIN verify is local (no round-trip) — sub-frame after hash completes.
- **Network**: Zero for PIN entry (offline-first). Firebase Auth sign-in is the only networked auth step.

## Migration Plan
No existing code — greenfield. The GDD's `sessionStateProvider` code snippet and Formulas rationale are corrected alongside this ADR (see GDD sync).

## Validation Criteria
- Unit test: `verifyChildPin` accepts the correct PIN and rejects wrong ones; failCount increments and 3-fail lockout engages for 60s; correct PIN resets failCount.
- Unit test: `sessionStateProvider` returns the correct state for all combinations of (user null/non-null) × (activeChild null/non-null) × (override true/false), including that an `authStateProvider` error degrades to `unauthenticated` rather than throwing.
- Integration: go_router redirects on session-state change (proves the refresh bridge works).
- QA: lockout persistence across force-close on both platforms; iOS-vs-Android reset-on-reinstall behavior documented.
- Security check: confirm PBKDF2 runs off-isolate (no jank); confirm no PIN/hash/salt in logs or crash breadcrumbs.

## Related Decisions
- ADR-0001 (draw-call budget) — unrelated domain; no interaction.
- Firestore Schema & Persistence Strategy ADR (next) — owns the credential sub-document schema + full Security Rules this ADR references.
- `design/gdd/auth-account.md` — the ratified design; `data-persistence-layer.md`, `push-notification.md` — downstream scoping.
