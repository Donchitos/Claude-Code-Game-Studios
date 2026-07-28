# Quick Design Spec: Parent Account Registration (Sign Up)

**Type**: Addition
**System**: Auth & Account
**GDD Reference**: `design/gdd/auth-account.md` — Core Rules §3 ("Login Flow"), Edge Cases ("Nếu families/{parentId} document không tồn tại sau khi login")
**Date**: 2026-07-16

## Change Summary

Adds the missing account-creation half of Auth & Account: a `signUp()` repository method (Firebase Auth `createUserWithEmailAndPassword` + first-time `families/{parentId}` document bootstrap) and a `RegisterScreen` UI, linked bidirectionally with the existing `LoginScreen`.

## Motivation

The Auth & Account epic (12 stories, Complete) fully implements sign-IN, PIN entry, PIN reset, parent override, FCM token refresh, and profile deletion — but never implements how a parent's account is created in the first place. The GDD's own Core Rule 3 ("Login Flow") step 3 says *"Nếu document chưa tồn tại: first-time setup flow (tạo family document)"*, and `AuthRepository.getParentProfile()`'s own doc comment says it returns null as *"the caller's signal for first-time setup"* — both anticipate this flow, but nothing implements it. Confirmed by direct grep: no `signUp`/`createUserWithEmailAndPassword` call anywhere in `src/lib/`, and the login screen has no register link. Without this, the app cannot onboard a genuinely new user at all — verified today by loading the live app, which shows only a login form.

## Design Delta

Current GDD says (`design/gdd/auth-account.md`, Core Rules §3):

> 1. Email + Password → Firebase Auth `signInWithEmailAndPassword()`
> 2. On success: load `families/{parentId}` từ Firestore
> 3. Nếu document chưa tồn tại: first-time setup flow (tạo family document)

This spec adds the missing prerequisite step — how an email+password credential and its family document come to exist in the first place — as a parallel, explicit flow (not a fallback branch of Login):

**New Rule — Registration Flow:**
1. Parent fills Email + Password + Confirm Password on a new `RegisterScreen`.
2. Client-side: passwords must match and be non-empty before submission (loose hint only, same philosophy as Login's email-format hint — the real validation is Firebase's own response).
3. `AuthRepository.signUp({email, password})`:
   a. `_auth.createUserWithEmailAndPassword(email, password)`.
   b. On success, immediately write `families/{parentId}`: `{ email, displayName: <derived from email local-part>, createdAt: FieldValue.serverTimestamp() }` — `fcmToken` omitted (not written), matching `ParentProfile.fromFirestore`'s existing nullable handling; Auth Story 008's `onTokenRefresh` listener fills it in once established.
4. `authStateProvider` emits the new user automatically (Firebase Auth's native stream) → `sessionStateProvider` derives `parentAuthed` → routes to Child Profile Selection, same as a normal login.

**Design decision — `displayName` default**: derived from the email's local-part (e.g. `quang.dao` from `quang.dao@gmail.com`), not collected as a separate form field. Rationale: `ParentProfile.email`/`displayName` are both non-nullable per the existing model, but no built UI currently surfaces `displayName` anywhere, and the GDD's Player Fantasy explicitly wants setup "<3 phút, không phức tạp." Adding a name field would be free-standing scope creep against that fantasy for a value nothing displays yet.

**Design decision — error handling deliberately diverges from `signIn()`'s pattern**: ADR-0002 Decision §6 forbids per-`FirebaseAuthException.code` branching for *sign-in* specifically (to prevent email enumeration — Firebase already consolidates `wrong-password`/`user-not-found` server-side). Registration is a different case, for two independent reasons:
1. **Firebase's own API already treats them differently.** Sign-in's `wrong-password`/`user-not-found` are deliberately consolidated into one `invalid-credential` code server-side specifically so client apps can't easily leak this distinction — but `email-already-in-use` on registration is NOT consolidated into anything; it's its own permanent, always-present code. Firebase's own security model already exposes "this email exists" as an inherent, unavoidable property of the create-account API surface — hiding the client-side message provides no real protection (the signal is derivable from success/failure alone), only worse UX for a legitimate user who mistyped or forgot they'd already signed up.
2. **This codebase's own threat model is scoped to sibling misuse, not external enumeration.** ADR-0002's Non-Goals section states the security model is explicitly *"in scope: protection against a 6–10-year-old sibling using the normal app UI on a shared device"* and *"explicitly out of scope: a technically capable actor with direct Firestore/REST access... or device-level tooling."* Telling a user "this email is already registered" carries no exploit value for that in-scope threat.

⚠️ **Corrected 2026-07-16 (code review, flame-widget-specialist)**: an earlier draft of this rationale cited "429/CAPTCHA friction" as a mitigating factor — this codebase has no `firebase_app_check`/reCAPTCHA package configured (confirmed via `pubspec.yaml`), so that claim referenced an unconfigured, unverified mitigation and has been removed. The two reasons above stand independently of it.

`signUp()` therefore branches on exactly 3 codes:
- `email-already-in-use` → *"Email này đã được đăng ký — hãy đăng nhập."*
- `weak-password` → *"Mật khẩu quá yếu — cần tối thiểu 6 ký tự."* (Firebase Auth's own enforced minimum)
- `invalid-email` → *"Email không hợp lệ."*
- `network-request-failed` → same `AuthNetworkFailure` type `signIn()` already throws (distinct "no connection" UI state, not a credential rejection).
- Anything else → one generic fallback message (`AuthSignUpFailure`, a new type mirroring `AuthSignInFailure`).

**Design decision — atomicity is NOT strengthened, by choice**: if step 3a succeeds but 3b (Firestore write) fails (e.g. network drop mid-flow), the resulting state — a Firebase Auth account with no family document — is EXACTLY the pre-existing scenario the GDD's own Edge Cases section already names (*"Trường hợp này xảy ra nếu user tạo Firebase Auth nhưng app crash trước khi tạo Firestore document"*) and already assigns a recovery path to ("Redirect đến first-time setup, không crash"). That recovery screen is not itself built yet (separate, pre-existing gap — see Affected Systems). This spec does not expand scope to build it; it only avoids making the gap worse. A real (rare) failure here currently surfaces as a generic error on the Register screen with the Auth account already created — the parent can recover by using the same email on a future "Login → account exists but Firestore doc missing" path once that recovery screen exists.

## New Rules / Values

```dart
// AuthRepository — new method, same file/class as existing signIn()/reauthenticate()
Future<void> signUp({required String email, required String password}) async {
  final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
  // ... catch email-already-in-use / weak-password / invalid-email / network-request-failed
  final displayName = email.split('@').first;
  await _firestore.doc(FirestorePaths.family(credential.user!.uid)).set({
    'email': email,
    'displayName': displayName,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
```

New route: `AppRoutes.register = '/register'`, registered in `router_provider.dart` alongside the existing routes, reachable while `sessionStateProvider == unauthenticated` (same guard tier as `/login`).

New screen: `lib/ui/register_screen.dart`, structurally mirroring `login_screen.dart` (single-flight `_isSubmitting` guard, `AnimatedSwitcher` error display, same `AppColors`/button styling) — Email, Password, Confirm Password fields, "Đăng ký" button, and a "Đã có tài khoản? Đăng nhập" link back to `/login`. `LoginScreen` gets the mirror link: "Chưa có tài khoản? Đăng ký" → `/register`.

## Affected Systems

| System | Impact | Action Required |
|--------|--------|-----------------|
| Auth & Account | New method + screen added to an already-Complete epic | New story (013) with its own tests + code review, same rigor as the other 12 |
| Data Persistence Layer | First write to `families/{parentId}` now has a real code path (previously only read/updated after the fact) | No schema change — `email`/`displayName`/`createdAt` already defined fields, no action needed |
| Main Navigation Shell / router | New unauthenticated-tier route | Add `AppRoutes.register` + one `GoRoute` entry |
| **Not addressed (pre-existing, separate gap)** | "First-time setup redirect" for an Auth account with no family doc (the GDD's own already-anticipated edge case) has no screen today, before or after this spec | Flag as a follow-up if the crash-mid-registration case is ever hit in practice — out of this Addition's scope |

## Acceptance Criteria

- [ ] `signUp()` creates a Firebase Auth user AND writes `families/{parentId}` with `email`, `displayName` (derived from email local-part), `createdAt` — in that order, only after the Auth call succeeds
- [ ] `email-already-in-use` surfaces a distinct, actionable message (not the generic sign-in message) — verified by a specific test, not lumped with the generic-error test
- [ ] `weak-password` and `invalid-email` each surface their own distinct message
- [ ] A network failure during sign-up throws the same `AuthNetworkFailure` type `signIn()` already uses
- [ ] `RegisterScreen` blocks submission client-side when passwords don't match, without calling `signUp()`
- [ ] Register ↔ Login navigation links both work
- [ ] No regression: `signIn()`'s existing behavior and its full test suite are unaffected

## GDD Update Required?

**Yes** — `design/gdd/auth-account.md` Core Rules should gain a new numbered rule (between current §2 "App Session States" and §3 "Login Flow", or as 3a) spelling out the Registration Flow above, since the GDD currently only gestures at it ("first-time setup flow") without defining it. Will ask separately, showing exact old/new text, before editing.
