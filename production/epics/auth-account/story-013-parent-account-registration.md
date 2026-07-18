# Story 013: Parent Account Registration (Sign Up)

> **Epic**: Auth & Account
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/auth-account.md`
**Requirement**: `TR-auth-account-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Auth & PIN Security Architecture (Accepted)
**Quick Design Spec**: `design/quick-specs/parent-account-registration-2026-07-16.md` — this story's real source of implementation detail; the GDD's new Core Rule 2a is a summary of it, not a superset.

**Engine**: Flutter 3.44.4 / `firebase_auth ^6.5.6` (actual resolved version, confirmed in `pubspec.lock` — matches ADR-0002's 2026-07-15 Correction note) | **Risk**: LOW — reuses the exact `AuthRepository`/`LoginScreen` patterns Story 001/010 already proved out; the only new API surface is `createUserWithEmailAndPassword`, a stable pre-cutoff Firebase Auth method.

**Already Established (do not re-derive)**:
- `AuthRepository.signIn()` (Story 001, extended Story 010) is the pattern to mirror: constructor-injected `FirebaseAuth`/`FirebaseFirestore`, generic `FirebaseAuthException` catch with a distinct `AuthNetworkFailure` type for `network-request-failed`.
- `LoginScreen` (Story 010) is the UI pattern to mirror: single-flight `_isSubmitting` guard, `AnimatedSwitcher` error zone, `AppColors` constants, no manual `navigate()` call on success (Story 003's route guard reacts to `sessionStateProvider` automatically).
- `ParentProfile.email`/`.displayName` are both non-nullable `String` fields (`src/lib/core/models/parent_profile.dart`) — the family-doc write in this story must supply both.
- **No formal UX spec exists for a Register screen** (`design/ux/register-screen.md` does not exist). Per this story's own Quick Design Spec scope (an "Addition," not a new UI-epic story), the spec's own "New Rules / Values" section is the UI's implementation guidance — deliberately skipping the full `/ux-design` pipeline Story 010 went through, consistent with quick-design's purpose. If this screen later needs deeper UX treatment (animations, accessibility audit beyond mirroring Login's already-audited patterns), that's a follow-up, not this story.

**Control Manifest Rules (this layer)**:
- Required: "Parent authenticates via Firebase Auth `signInWithEmailAndPassword`; a child is NOT a Firebase Auth principal" — source: ADR-0002 (unaffected by this story — still true for the child tier)
- Required: "Use the safe nullable accessor on `authStateProvider`... `.value`" — source: ADR-0002 (already correctly used; this story doesn't touch that provider)
- **Deliberate, scoped exception to an existing rule**: "Catch `FirebaseAuthException` generically — do not branch per error code" (source: ADR-0002 Decision §6) applies to **sign-in** specifically (prevents email-enumeration via login attempts). This story's `signUp()` DOES branch on `email-already-in-use`/`weak-password`/`invalid-email` — a deliberate, documented divergence (see the Quick Design Spec's "Design decision — error handling" section for the full rationale: registration necessarily reveals email-taken status as standard UX, a different threat model than login). Flag this to the reviewer explicitly rather than let it read as an accidental ADR violation.

---

## Acceptance Criteria

*From `design/quick-specs/parent-account-registration-2026-07-16.md`:*

- [x] `signUp()` creates a Firebase Auth user AND writes `families/{parentId}` with `email`, `displayName` (derived from the email's local-part, e.g. `quang.dao` from `quang.dao@gmail.com`), `createdAt` — in that order, only after the Auth call succeeds.
- [x] `email-already-in-use` surfaces a distinct, actionable message ("Email này đã được đăng ký — hãy đăng nhập.") — not the generic sign-in message, verified by its own test.
- [x] `weak-password` surfaces "Mật khẩu quá yếu — cần tối thiểu 6 ký tự."
- [x] `invalid-email` surfaces "Email không hợp lệ."
- [x] A network failure during sign-up throws the same `AuthNetworkFailure` type `signIn()` already uses (not a new/different type).
- [x] Any other `FirebaseAuthException` falls back to one generic message via a new `AuthSignUpFailure` type (mirrors `AuthSignInFailure`).
- [x] `RegisterScreen` blocks submission client-side when password and confirm-password don't match, without calling `signUp()` at all.
- [x] `RegisterScreen` has a "Đã có tài khoản? Đăng nhập" link to `/login`; `LoginScreen` gets the mirror "Chưa có tài khoản? Đăng ký" link to `/register`.
- [x] `AppRoutes.register = '/register'` is reachable while `sessionStateProvider == unauthenticated` (same guard tier as `/login`) — registering and having `authStateProvider` emit the new user must route to Child Profile Selection automatically, same as a normal login (no manual `navigate()` call).
- [x] No regression: `signIn()`'s existing behavior and its full existing test suite pass unmodified.

---

## Implementation Notes

*From the Quick Design Spec's "New Rules / Values" section — read that file in full before implementing, this is a condensed pointer, not a replacement:*

```dart
// AuthRepository — new method alongside existing signIn()/reauthenticate()/getParentProfile()
Future<void> signUp({required String email, required String password}) async {
  final UserCredential credential;
  try {
    credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
  } on FirebaseAuthException catch (e) {
    if (e.code == 'network-request-failed') throw const AuthNetworkFailure();
    if (e.code == 'email-already-in-use') {
      throw const AuthSignUpFailure('Email này đã được đăng ký — hãy đăng nhập.');
    }
    if (e.code == 'weak-password') {
      throw const AuthSignUpFailure('Mật khẩu quá yếu — cần tối thiểu 6 ký tự.');
    }
    if (e.code == 'invalid-email') {
      throw const AuthSignUpFailure('Email không hợp lệ.');
    }
    throw const AuthSignUpFailure('Có lỗi xảy ra, vui lòng thử lại');
  }
  final displayName = email.split('@').first;
  await _firestore.doc(FirestorePaths.family(credential.user!.uid)).set({
    'email': email,
    'displayName': displayName,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
```
- `AuthSignUpFailure` is a NEW exception type — do not reuse `AuthSignInFailure` even though the shape is identical, since they're distinct call sites per the established `AuthReauthenticationFailure` precedent (Story 006 already established "distinct type per call site even with an identical generic-catch shape").
- `RegisterScreen` (`lib/ui/register_screen.dart`) structurally mirrors `LoginScreen` — copy its single-flight guard, `AnimatedSwitcher` error zone, and `AppColors` usage exactly. Fields: Email, Password (obscured + toggle), Confirm Password (obscured, no separate toggle needed — can share the Password field's visibility state). Client-side check: `_passwordController.text == _confirmPasswordController.text` and both non-empty, checked in `_submit()` before calling `signUp()` — show a local validation message, do not call the repository at all if they don't match.
- Route registration in `router_provider.dart`: add `static const register = '/register';` to `AppRoutes`, and one `GoRoute(path: AppRoutes.register, pageBuilder: ...)` alongside the existing `login` route — same redirect-guard tier (unauthenticated only).
- `LoginScreen` needs one small addition: a `TextButton` below the existing "Quên mật khẩu" link (or alongside it), navigating to `AppRoutes.register` via `context.go(...)`.

---

## Out of Scope

- The "first-time setup redirect" recovery screen for an Auth account that exists with no family document (pre-existing gap, already named in the GDD's Edge Cases before this story — see the Quick Design Spec's Affected Systems table for the full reasoning on why this story doesn't expand to fix it).
- Any UX spec authoring (`/ux-design register-screen`) — deliberately skipped per this story's Quick Design Spec scope.
- Forgot-password flow — already out of scope for Story 010 too, unrelated to this story.
- Email verification (`sendEmailVerification()`) — not mentioned anywhere in the GDD or ADR-0002; not invented here.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. Derived from the Quick Design Spec's own Acceptance Criteria:*

```
Test: signUp writes the Firebase Auth user AND the family doc, in that order
  Given: a fake FirebaseAuth that succeeds createUserWithEmailAndPassword, a fake Firestore
  When: signUp(email: '...', password: '...') is called
  Then: the family doc at families/{uid} contains exactly email/displayName/createdAt;
    displayName equals the email's local-part; the Firestore write only happens after the
    Auth call resolves (not before/in parallel)

Test: email-already-in-use surfaces its own distinct message
  Given: createUserWithEmailAndPassword throws FirebaseAuthException(code: 'email-already-in-use')
  When: signUp(...) is called
  Then: throws AuthSignUpFailure with the email-already-in-use-specific message — not the
    generic fallback, not AuthSignInFailure

Test: weak-password and invalid-email each surface their own message
  Given: the respective FirebaseAuthException codes
  When: signUp(...) is called for each
  Then: each throws AuthSignUpFailure with its own distinct, matching message

Test: network-request-failed throws the SAME AuthNetworkFailure type signIn() uses
  Given: createUserWithEmailAndPassword throws FirebaseAuthException(code: 'network-request-failed')
  When: signUp(...) is called
  Then: throws AuthNetworkFailure (not a new/different network-failure type)

Test: an unrecognized FirebaseAuthException code falls back to one generic message
  Given: createUserWithEmailAndPassword throws FirebaseAuthException(code: 'some-other-code')
  When: signUp(...) is called
  Then: throws AuthSignUpFailure with the generic fallback message

Test: RegisterScreen blocks submission when passwords don't match
  Given: RegisterScreen with Password='abc123', Confirm='abc124'
  When: submit is tapped
  Then: a local validation message shows, signUp() is never called (verify via a fake
    AuthRepository's call count)

Test: signIn()'s existing test suite is unaffected
  Given: the existing signIn()/reauthenticate() tests from Story 001/006/010
  When: the full auth_account test suite is re-run after this story's changes
  Then: all pre-existing tests still pass — no regression
```

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/auth_account/parent_registration_test.dart` (repository logic) + `tests/integration/auth_account/register_screen_test.dart` (screen-level, mirroring `login_screen_test.dart`'s widget-test pattern) — both must exist and pass

**Status**: [x] Created — `tests/unit/auth_account/parent_registration_test.dart` (10 tests), `tests/integration/auth_account/parent_registration_test.dart` (2 tests, provider-wiring + displayName edge case), `tests/integration/auth_account/register_screen_test.dart` (13 tests). All passing.

---

## Dependencies

- Depends on: Story 001 (Complete) — `AuthRepository`/`AuthSignInFailure`/`AuthNetworkFailure` established. Story 003 (Complete) — the route guard this story's success path relies on. Story 010 (Complete) — the `LoginScreen`/`AppColors`/fade-transition patterns this story mirrors.
- Unlocks: Genuinely new-user onboarding on the live app (previously impossible — no code path created a first account).

---

## Completion Notes

**Closed**: 2026-07-16

Implemented `AuthRepository.signUp()` + `AuthSignUpFailure` (`src/lib/core/auth_repository.dart`), `RegisterScreen` (`src/lib/ui/register_screen.dart`, mirroring `LoginScreen`), a new `AppRoutes.register` route + widened `unauthenticated` redirect guard (`src/lib/providers/router_provider.dart`), and a mirror "Chưa có tài khoản? Đăng ký" link on `LoginScreen`.

**Origin**: found via direct app testing — loaded the live web build, discovered no registration screen existed anywhere, confirmed by code search (no `signUp`/`createUserWithEmailAndPassword` call in the codebase). Traced to a real, already-anticipated-but-never-built gap: the GDD's own Core Rule 3 ("first-time setup flow") and `AuthRepository.getParentProfile()`'s own doc comment ("the caller's signal for first-time setup") both assumed this would exist. Scoped as a Quick Design Spec Addition (`design/quick-specs/parent-account-registration-2026-07-16.md`) rather than a full new UX-spec-driven epic story, deliberately reusing `LoginScreen`'s already-audited patterns.

**Code review**: flame-widget-specialist (APPROVED WITH SUGGESTIONS) + qa-tester (GAPS) run in parallel. All findings actioned:
1. **Both reviewers independently found the same issue**: a test (`test_LoginScreen_register_link_navigates_to_register_route`) claimed navigation coverage in its name/comment but never called `tester.tap()` — meaning nothing in the suite actually proved the Login→Register direction of the mirror link through a real router. Fixed: renamed the render-only test accurately, added a new real-`GoRouter` tap-and-navigate test (mirroring the existing Register→Login test).
2. **flame-widget-specialist**: the quick-spec's justification for `signUp()` deliberately branching per error code (diverging from ADR-0002's "no per-code branching" sign-in rule) leaned partly on an unconfigured mitigation (CAPTCHA/rate-limiting — no `firebase_app_check` package exists in this codebase). Corrected the rationale in the quick-spec, the story, and the code's own doc comment: the real justification is (a) Firebase's own API already treats `email-already-in-use` as a permanent, non-consolidated code (unlike login's deliberately-consolidated `invalid-credential`), so client-side message suppression provides no real protection, and (b) ADR-0002's own Non-Goals scope this codebase's threat model to sibling misuse on a shared device, not external enumeration.
3. **flame-widget-specialist** also found an unlisted duplicate test file (`tests/integration/auth_account/parent_registration_test.dart`, 7 tests) that re-covered 5 of 7 scenarios already in the unit test file with no incremental value. Trimmed to the 2 tests with genuine unique value (real provider/DI-container wiring, and a `+`-alias `displayName` edge case).
4. **qa-tester**: found 3 untested edge cases (empty email, whitespace-padded email, malformed `@`-less email) and one real missing guard — `RegisterScreen` validated password-match/non-empty client-side but never checked email non-empty, unlike the established pattern. Added the missing guard (`if (_emailController.text.isEmpty)`) plus tests for all 3 edge cases (2 unit-level, 1 widget-level for the new guard).

Both reviewers independently confirmed: `signUp()`'s Auth-then-Firestore sequencing is correct (Dart's definite-assignment analysis + the catch block always throwing guarantees `credential` is only read post-success); `credential.user!.uid`'s force-unwrap is bounded (Firebase's own contract guarantees non-null on success, and even a hypothetical null would surface as a caught, non-crashing generic error); `RegisterScreen._submit()`'s `mounted` checks correctly mirror `LoginScreen`'s post-review-fixed pattern in all 4 branches; the router redirect-guard widening has no loop risk and is both unit- and integration-tested; and the `displayName`-from-email-local-part design choice is reasonable and already self-documented as a bounded trade-off.

**Test evidence**: 25 total new/extended tests across 3 files (10 unit repository + 2 integration provider-wiring/edge-case + 13 screen), all passing. Full analyzer clean (baseline 11 pre-accepted `prefer_initializing_formals` lints unchanged). Full project suite: 286/286 passing (1 pre-existing, unrelated skip).
