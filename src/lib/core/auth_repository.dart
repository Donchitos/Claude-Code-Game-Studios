import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_paths.dart';
import 'models/parent_profile.dart';

/// A single, non-branching sign-in failure. Deliberately does not expose the
/// underlying `FirebaseAuthException.code` — `firebase_auth` (pinned
/// `^6.5.6`) consolidates `wrong-password`/`user-not-found` into
/// `invalid-credential` on projects with email enumeration protection
/// enabled (the default since September 2023), but this repository does not
/// depend on that fact holding: catching generically and never branching per
/// code is correct regardless of which code is actually returned
/// (ADR-0002 Decision §6; control-manifest.md — "do not resurrect
/// per-error-code branching").
class AuthSignInFailure implements Exception {
  const AuthSignInFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthSignInFailure: $message';
}

/// Thrown when [AuthRepository.signIn] fails because the request never
/// reached Firebase (`FirebaseAuthException.code == 'network-request-failed'`,
/// a real, documented code — verified in the installed `firebase_auth`
/// ^6.5.6 source). Deliberately a DISTINCT type from [AuthSignInFailure]:
/// this is not the per-credential-error-code branching the ADR forbids
/// (wrong-password vs. user-not-found, which would leak whether an email is
/// registered) — it's a different category entirely, "the request never
/// reached the server" vs. "the server rejected it". `design/ux/login-screen.md`'s
/// States & Variants requires the UI to show a distinct "no connection"
/// message rather than the generic wrong-credentials one (found while
/// implementing Story 010 — code-review 2026-07-16).
class AuthNetworkFailure implements Exception {
  const AuthNetworkFailure();

  @override
  String toString() => 'AuthNetworkFailure';
}

/// A single, non-branching parent-override reauthentication failure — same
/// generic-catch shape as [AuthSignInFailure], kept as a distinct type
/// because a reauthenticate failure (Story 006) and a sign-in failure
/// (Story 001) are different call sites with different callers, even though
/// neither branches per `FirebaseAuthException.code`.
class AuthReauthenticationFailure implements Exception {
  const AuthReauthenticationFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthReauthenticationFailure: $message';
}

/// A registration failure with a message specific to the [FirebaseAuthException]
/// code that caused it (`email-already-in-use`/`weak-password`/`invalid-email`,
/// or one generic fallback for anything else). Deliberately a DISTINCT type
/// from [AuthSignInFailure] even though the shape is identical — same
/// distinct-type-per-call-site precedent as [AuthReauthenticationFailure]
/// (Story 006). Unlike [AuthSignInFailure]/[signIn], [signUp] DOES branch per
/// error code — a deliberate, scoped exception to ADR-0002 Decision §6's
/// "no per-code branching" rule (which exists to prevent email enumeration
/// via LOGIN attempts specifically, where Firebase deliberately consolidates
/// `wrong-password`/`user-not-found` into one code server-side). Registration
/// is different: `email-already-in-use` is NOT consolidated into anything by
/// Firebase's own API — it's a permanent, always-present code, so the
/// create-account API surface already exposes "this email exists" as an
/// inherent property regardless of what message this client shows. ADR-0002's
/// own Non-Goals also scope this codebase's threat model to sibling misuse on
/// a shared device, not external enumeration — see Story 013
/// (`design/quick-specs/parent-account-registration-2026-07-16.md`) for the
/// full rationale, corrected 2026-07-16 to drop an earlier, unconfigured
/// CAPTCHA/rate-limit claim.
class AuthSignUpFailure implements Exception {
  const AuthSignUpFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthSignUpFailure: $message';
}

/// Owns the parent-authentication, family-bootstrap (Story 001), and
/// parent-override reauthentication (Story 006) calls for Auth & Account.
/// Constructor-injected so it is unit-testable against fake Firebase SDK
/// implementations (coding-standards.md — dependency injection over
/// singletons).
class AuthRepository {
  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Signs the parent in. Throws [AuthNetworkFailure] if the request never
  /// reached Firebase, or [AuthSignInFailure] with one generic message for
  /// any other [FirebaseAuthException] — never reveals whether the email
  /// exists.
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw const AuthNetworkFailure();
      }
      throw const AuthSignInFailure('Sai email hoặc mật khẩu.');
    }
  }

  /// Verifies the signed-in parent's password for the Parent Dashboard
  /// override — deliberately `reauthenticateWithCredential`, NOT a second
  /// `signInWithEmailAndPassword`: the latter re-triggers `authStateChanges()`,
  /// which `sessionStateProvider` (Story 002) could misread as a fresh login
  /// rather than an override, flickering the session state (ADR-0002 Decision
  /// §6). Throws [AuthReauthenticationFailure] with one generic message on
  /// any [FirebaseAuthException] — same no-per-code-branching rule as
  /// [signIn]. Does not touch `activeChildProvider`; that's the caller's job
  /// and is deliberately out of this repository's I/O-only scope.
  Future<void> reauthenticate({required String password}) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AuthReauthenticationFailure('Không tìm thấy phiên đăng nhập của bố mẹ.');
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } on FirebaseAuthException catch (_) {
      throw const AuthReauthenticationFailure('Sai mật khẩu.');
    }
  }

  /// Writes a refreshed FCM token to `families/{parentId}.fcmToken` — the
  /// single field, via merge, so no other field on that document is touched
  /// (TR-auth-account-008; GDD interaction table "Push Notification →
  /// fcmToken of parent, stored in families/{parentId}"). Consuming
  /// `fcmToken` to actually send notifications is Push Notification epic #9,
  /// out of this repository's scope.
  Future<void> updateFcmToken({
    required String parentId,
    required String token,
  }) async {
    await _firestore
        .doc(FirestorePaths.family(parentId))
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  /// Reads `families/{parentId}`. Returns null (does not throw) when the
  /// document doesn't exist yet — the caller's signal for first-time setup.
  Future<ParentProfile?> getParentProfile(String parentId) async {
    final snapshot = await _firestore.doc(FirestorePaths.family(parentId)).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return ParentProfile.fromFirestore(parentId, data);
  }

  /// Creates a new parent account (GDD Core Rule 2a, Story 013;
  /// `design/quick-specs/parent-account-registration-2026-07-16.md`) — the
  /// previously-missing account-creation half of Auth & Account. Creates the
  /// Firebase Auth user FIRST via `createUserWithEmailAndPassword`, then —
  /// only after that succeeds — writes the first-time `families/{parentId}`
  /// document (`email`, `displayName` derived from the email's local-part,
  /// `createdAt`) — never the reverse (control-manifest.md, Story 013
  /// bullet). `displayName` is not collected as a separate form field —
  /// deliberate, keeps setup "<3 phút, không phức tạp" per the GDD's Player
  /// Fantasy; nothing currently displays it. `fcmToken` is omitted (not
  /// written null) — Story 008's `onTokenRefresh` listener fills it in once
  /// established.
  ///
  /// Throws [AuthNetworkFailure] for `network-request-failed` (same type
  /// [signIn] uses), or [AuthSignUpFailure] with a code-specific message for
  /// `email-already-in-use`/`weak-password`/`invalid-email`, or one generic
  /// [AuthSignUpFailure] for anything else.
  Future<void> signUp({required String email, required String password}) async {
    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'network-request-failed':
          throw const AuthNetworkFailure();
        case 'email-already-in-use':
          throw const AuthSignUpFailure('Email này đã được đăng ký — hãy đăng nhập.');
        case 'weak-password':
          throw const AuthSignUpFailure('Mật khẩu quá yếu — cần tối thiểu 6 ký tự.');
        case 'invalid-email':
          throw const AuthSignUpFailure('Email không hợp lệ.');
        default:
          throw const AuthSignUpFailure('Có lỗi xảy ra, vui lòng thử lại');
      }
    }
    final displayName = email.split('@').first;
    await _firestore.doc(FirestorePaths.family(credential.user!.uid)).set({
      'email': email,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
