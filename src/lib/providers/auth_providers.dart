import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `StateProvider` moved to the legacy export in riverpod 3.x (no longer in
// the main `flutter_riverpod.dart` barrel) — confirmed against the actual
// installed riverpod-3.3.2 source, matching the risk ADR-0002 flagged
// ("recent Riverpod steers toward @riverpod/Notifier").
import 'package:flutter_riverpod/legacy.dart';

import '../core/auth_repository.dart';
import '../core/child_profile_repository.dart';
import '../core/firebase_providers.dart';
import '../core/models/child_profile.dart';
import '../core/models/parent_profile.dart';
import '../core/pin_reset_repository.dart';
import '../core/pin_verification_repository.dart';
import '../core/secure_storage_provider.dart';

/// Single-file Riverpod provider contract for Auth & Account, per
/// `design/gdd/auth-account.md` ("all downstream systems import from
/// `lib/providers/auth_providers.dart` — không tự tạo providers riêng").
///
/// Story 001: [authRepositoryProvider], [authStateProvider],
/// [parentProfileProvider]. Story 002 (this): [SessionState],
/// [activeChildProvider], [parentOverrideProvider], [sessionStateProvider].
/// PIN verification (Story 004) writes real values into
/// [activeChildProvider]; parent override (Story 006) writes real values
/// into [parentOverrideProvider] — this story only declares the contract and
/// the derivation logic, it does not implement either write path.

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

/// Who is currently signed in (Firebase Auth user). ADR-0002 Key Interfaces.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// The signed-in parent's `families/{parentId}` document, or null if it
/// doesn't exist yet (first-time setup signal — never throws for that case).
final parentProfileProvider = FutureProvider<ParentProfile?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).getParentProfile(user.uid);
});

/// The 4 App Session States (GDD Core Rule 2 / ADR-0002 Key Interfaces).
/// [sessionStateProvider] below is the sole derivation of this enum — no
/// other system may re-derive session state (ADR-0002 Decision §5).
enum SessionState { unauthenticated, parentAuthed, childSelected, parentView }

/// Child profile currently active in this session, or null if none selected
/// yet. Written by Story 004 (`verifyChildPin`) on successful PIN entry —
/// this story only declares the provider.
final activeChildProvider = StateProvider<ChildProfile?>((ref) => null);

/// True while the parent is viewing the dashboard from within a live child
/// session (Core Rule 5 "Parent Override") — does NOT dispose the child
/// session. Written by Story 006 — this story only declares the provider.
final parentOverrideProvider = StateProvider<bool>((ref) => false);

/// Single derived routing source of truth (ADR-0002 Decision §5). go_router
/// (Story 003) reads only this provider; no other system re-implements the
/// derivation.
///
/// Uses `.value` (not `.valueOrNull`, which does not exist on `riverpod`
/// 3.3.2 — see ADR-0002's 2026-07-13 correction note) as the safe nullable
/// accessor, so an `authStateProvider` `AsyncError` degrades to
/// [SessionState.unauthenticated] rather than rethrowing and crashing
/// routing.
final sessionStateProvider = Provider<SessionState>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return SessionState.unauthenticated;
  final activeChild = ref.watch(activeChildProvider);
  if (activeChild == null) return SessionState.parentAuthed;
  return ref.watch(parentOverrideProvider)
      ? SessionState.parentView
      : SessionState.childSelected;
});

final childProfileRepositoryProvider = Provider<ChildProfileRepository>((ref) {
  return ChildProfileRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

/// Child profiles for the profile-selection screen (max 4 per Tuning
/// Knobs — this provider surfaces the count via `.length`; enforcing the
/// cap on creation belongs to whichever "add child" flow exists, not yet
/// scoped to any story). Resolves to `[]` (not an error) if the parent has
/// no children yet.
///
/// `retry: (retryCount, error) => null` disables riverpod 3.3.2's default
/// `ProviderContainer.defaultRetry` — verified against the installed
/// `riverpod-3.3.2` source (`provider_container.dart`): by default, ANY
/// provider whose build throws a plain `Exception` (not a Dart `Error` or
/// `ProviderException`, and `FirebaseException` is an `Exception`) is
/// silently retried up to 10 times with exponential backoff (200ms→6.4s,
/// ~38s total) BEFORE the `AsyncValue` ever becomes a terminal `AsyncError`
/// — during those retries `.when()` reports `isLoading: true`, not `error`.
/// Found in Story 011 code review (2026-07-16) via the screen's own error-state
/// test never observing the error UI: real Firestore failures would leave
/// the profile-selection screen stuck on the loading skeleton for up to
/// ~38s, silently pre-empting the UX spec's manual "Thử lại" retry button.
/// Disabled here so a fetch failure surfaces immediately — user-initiated
/// retry (the spec's intent) replaces riverpod's silent one.
final childProfilesProvider = FutureProvider<List<ChildProfile>>(
  (ref) async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const [];
    return ref.watch(childProfileRepositoryProvider).getChildProfiles(user.uid);
  },
  retry: (retryCount, error) => null,
);

/// The Parent Dashboard override actions (Story 006). Exposed as a bound
/// object rather than bare top-level functions because `Ref` (used inside
/// providers) and `WidgetRef` (used in widgets) are separate, non-unifiable
/// types in riverpod 3.x — a `Provider<ParentOverrideActions>` is always
/// built with the container's real `Ref`, so `ref.read(parentOverrideActionsProvider)`
/// works identically from a widget's `WidgetRef.read` and from a
/// `ProviderContainer.read` in tests.
class ParentOverrideActions {
  ParentOverrideActions(this._ref);

  final Ref _ref;

  /// Verifies the parent's password and, only on success, flips
  /// [parentOverrideProvider] to `true`. [activeChildProvider] is
  /// deliberately untouched — override is not logout (ADR-0002 Decision §6).
  /// On failure, [parentOverrideProvider] is left `false` — the write only
  /// happens after `reauthenticate` returns successfully, so a rethrown
  /// [AuthReauthenticationFailure] can never leave the provider in an
  /// inconsistent `true` state.
  Future<void> attempt({required String password}) async {
    await _ref.read(authRepositoryProvider).reauthenticate(password: password);
    _ref.read(parentOverrideProvider.notifier).state = true;
  }

  /// Ends the parent override, returning directly to `childSelected` with
  /// the same active child — no PIN re-entry, because the child session was
  /// never disposed (GDD Riverpod Provider Contract section).
  void end() {
    _ref.read(parentOverrideProvider.notifier).state = false;
  }
}

final parentOverrideActionsProvider = Provider<ParentOverrideActions>((ref) {
  return ParentOverrideActions(ref);
});

/// Establishes the FCM token-refresh listener once a parent is signed in —
/// writes each new token to `families/{parentId}.fcmToken`
/// (TR-auth-account-008). Depends directly on [authStateProvider] (not
/// [sessionStateProvider]): this only cares about parent-level auth, not
/// which child is selected. Rebuilds (cancelling the old subscription via
/// `ref.onDispose` and establishing a fresh one) whenever the signed-in user
/// changes, including to/from null — no listener runs while signed out.
///
/// Must be kept actively watched (e.g. `ref.watch(fcmTokenRefreshListenerProvider)`
/// in the app root, same as [parentOverrideActionsProvider]'s dependency
/// [authStateProvider] more generally) — riverpod pauses a `StreamProvider`'s
/// underlying subscription when nothing keeps it live (see Story 003's
/// `router_provider.dart` for the same class of gotcha, verified there
/// against actual riverpod 3.3.2 behavior).
final fcmTokenRefreshListenerProvider = Provider<void>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return;

  final parentId = user.uid;
  final messaging = ref.watch(firebaseMessagingProvider);
  final repository = ref.watch(authRepositoryProvider);
  final subscription = messaging.onTokenRefresh.listen((token) {
    // Not awaited (the listener callback can't be async) — must not let a
    // failed write become an unhandled Future rejection. Skip-and-log, not
    // retry: no ADR/GDD decision exists yet for retry/backoff on this path,
    // and a dropped token write just means push notifications lag until the
    // next refresh (found in Story 008 code review).
    repository
        .updateFcmToken(parentId: parentId, token: token)
        .catchError((Object e) {
      debugPrint('fcmTokenRefreshListenerProvider: failed to write token '
          'for $parentId: $e');
    });
  });
  ref.onDispose(subscription.cancel);
});

final pinVerificationRepositoryProvider =
    Provider<PinVerificationRepository>((ref) {
  return PinVerificationRepository(
    childProfileRepository: ref.watch(childProfileRepositoryProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

/// Thrown when [PinVerificationRepository.verify] confirmed the PIN is
/// correct but no matching [ChildProfile] exists in [childProfilesProvider]
/// — a data-integrity violation (e.g. the profile doc was deleted between
/// profile-selection and PIN-entry) that should never happen under normal
/// operation. Deliberately NOT swallowed into a `false`/wrong-PIN result:
/// returning `true` with [activeChildProvider] left unset would violate
/// `verifyChildPin`'s own contract (AC1) and leave the caller in a silently
/// stuck `parentAuthed` state with no error signal (found in code review —
/// code-review 2026-07-15).
class VerifiedChildProfileMissing implements Exception {
  const VerifiedChildProfileMissing(this.childId);

  final String childId;

  @override
  String toString() =>
      'VerifiedChildProfileMissing: PIN verified for $childId but no '
      'matching ChildProfile was found in childProfilesProvider';
}

/// Child PIN verification (Story 004). Exposed as a bound object for the
/// same reason as [ParentOverrideActions] — `Ref`/`WidgetRef` don't unify in
/// riverpod 3.x.
class PinVerificationActions {
  PinVerificationActions(this._ref);

  final Ref _ref;

  /// Matches ADR-0002 Key Interfaces' `verifyChildPin({childId, rawPin})`
  /// signature exactly — `parentId` is resolved internally from
  /// [authStateProvider], not a caller-supplied parameter. On success,
  /// resolves the matching [ChildProfile] from [childProfilesProvider] and
  /// sets [activeChildProvider] — this always happens together with
  /// returning `true`; if no matching profile can be found, throws
  /// [VerifiedChildProfileMissing] rather than returning `true` with
  /// [activeChildProvider] left unset. On a wrong PIN or lockout (`false`)
  /// or a thrown [PinCredentialsUnavailable], [activeChildProvider] is left
  /// untouched.
  Future<bool> verifyChildPin({
    required String childId,
    required String rawPin,
  }) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return false;

    final verified = await _ref.read(pinVerificationRepositoryProvider).verify(
          parentId: user.uid,
          childId: childId,
          rawPin: rawPin,
        );
    if (verified) {
      final profiles = await _ref.read(childProfilesProvider.future);
      ChildProfile? matched;
      for (final profile in profiles) {
        if (profile.childId == childId) {
          matched = profile;
          break;
        }
      }
      if (matched == null) {
        throw VerifiedChildProfileMissing(childId);
      }
      _ref.read(activeChildProvider.notifier).state = matched;
    }
    return verified;
  }

  /// Exposes [PinVerificationRepository.getLockUntil] for the PIN Entry
  /// Screen's countdown display (Story 012) — see that method's doc comment.
  Future<DateTime?> getLockUntil(String childId) {
    return _ref.read(pinVerificationRepositoryProvider).getLockUntil(childId);
  }
}

final pinVerificationActionsProvider = Provider<PinVerificationActions>((ref) {
  return PinVerificationActions(ref);
});

final pinResetRepositoryProvider = Provider<PinResetRepository>((ref) {
  return PinResetRepository(
    childProfileRepository: ref.watch(childProfileRepositoryProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

/// PIN reset (Story 007) — a separate action from [PinVerificationActions]
/// (matches the ADR's two distinct interface functions, `verifyChildPin` and
/// `resetChildPin`). Exposed as a bound object for the same `Ref`/`WidgetRef`
/// reason as the other `*Actions` classes.
class PinResetActions {
  PinResetActions(this._ref);

  final Ref _ref;

  /// Matches ADR-0002 Key Interfaces' `resetChildPin({childId, newPin})`
  /// signature exactly — `parentId` resolved internally from
  /// [authStateProvider]. Deliberately does NOT touch [activeChildProvider]
  /// or any session state — a reset has zero effect on a currently-active
  /// child session by design; the new PIN only applies at the next
  /// PIN-entry (Implementation Notes §6).
  Future<void> resetChildPin({
    required String childId,
    required String newPin,
  }) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      throw StateError('resetChildPin requires an authenticated parent');
    }
    await _ref.read(pinResetRepositoryProvider).resetChildPin(
          parentId: user.uid,
          childId: childId,
          newPin: newPin,
        );
  }
}

final pinResetActionsProvider = Provider<PinResetActions>((ref) {
  return PinResetActions(ref);
});
