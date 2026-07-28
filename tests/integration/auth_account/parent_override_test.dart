// Run with:
//   cd src && flutter test ../tests/integration/auth_account/parent_override_test.dart
//
// Uses firebase_auth_mocks' MockFirebaseAuth/MockUser + mock_exceptions'
// whenCalling(...).on(...).thenThrow(...) — same pattern as
// parent_login_test.dart. `Invocation.method(#reauthenticateWithCredential,
// [anything])` uses the matcher package's `anything` as a positional-arg
// wildcard (mock_exceptions matches invocations via `equals()`, which treats
// Matcher elements specially) rather than trying to construct an
// AuthCredential that compares equal — AuthCredential has no meaningful `==`.
//
// Two real gotchas found writing this file:
//
// 1. `mock_exceptions`' `expectations` registry is a top-level `Map<Object,
//    ...>` shared across the whole test file, keyed by `==`/`hashCode` — NOT
//    by identity. `MockUser` mixes in `Equatable` keyed on uid/email/etc, so
//    two different `MockUser` instances built with the same uid in two
//    different tests compare `==` and collide in that registry: a
//    `.thenThrow(...)` registered in one test silently applies to an
//    unrelated `MockUser` in a later test. Fix: give every test's mock user a
//    distinct uid (`signedInAuth(uid: ...)` below), even when the test
//    doesn't otherwise care what the uid is.
//
// 2. `MockFirebaseAuth(signedIn: true, ...)` fires its initial
//    `authStateChanges()` event synchronously inside the constructor — before
//    a `ProviderContainer`/`authStateProvider` exists to receive it. Reading
//    `sessionStateProvider` synchronously right after building the container
//    can observe `SessionState.unauthenticated` because the stream event
//    hasn't been delivered through Riverpod's subscription yet. Fix: build
//    `MockFirebaseAuth()` unsigned, `container.listen(authStateProvider,
//    ...)` first, then call `signInWithEmailAndPassword` and await a
//    completer for the resulting non-null user — the same pattern
//    `parent_login_test.dart`'s `waitForSignedInUser` helper already uses.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart' show anything;
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:pet_quest/core/auth_repository.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/providers/auth_providers.dart';

void main() {
  const parentPassword = 'correct-horse-battery-staple';
  const activeChild = ChildProfile(
    childId: 'child-1',
    name: 'Bé An',
    avatarId: 'avatar-1',
    mochiName: 'Mochi',
  );

  MockFirebaseAuth signedInAuth({required String uid}) => MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: uid, email: '$uid@example.com'),
      );

  Future<User> waitForSignedInUser(
    ProviderContainer container,
    MockFirebaseAuth auth,
    String uid,
  ) {
    final completer = Completer<User>();
    late final ProviderSubscription<AsyncValue<User?>> sub;
    sub = container.listen(authStateProvider, (previous, next) {
      final user = next.value;
      if (user != null && !completer.isCompleted) {
        completer.complete(user);
      }
    });
    completer.future.whenComplete(sub.close);
    auth.signInWithEmailAndPassword(email: '$uid@example.com', password: 'x');
    return completer.future.timeout(const Duration(seconds: 5));
  }

  group('AuthRepository.reauthenticate (unit)', () {
    test(
        'test_reauthenticate_success_completes_without_throwing_for_signed_in_user',
        () async {
      final auth = signedInAuth(uid: 'unit-success');
      final repo = AuthRepository(auth: auth, firestore: _unusedFirestore());

      await expectLater(
        repo.reauthenticate(password: parentPassword),
        completes,
      );
    });

    test(
        'test_reauthenticate_wrong_password_throws_generic_AuthReauthenticationFailure',
        () async {
      final auth = signedInAuth(uid: 'unit-wrong-password');
      whenCalling(Invocation.method(#reauthenticateWithCredential, [anything]))
          .on(auth.currentUser!)
          .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
      final repo = AuthRepository(auth: auth, firestore: _unusedFirestore());

      await expectLater(
        () => repo.reauthenticate(password: 'wrong-password'),
        throwsA(isA<AuthReauthenticationFailure>().having(
          (e) => e.message,
          'message',
          isNot(contains('wrong-password')), // generic, never echoes input
        )),
      );
    });

    test(
        'test_reauthenticate_with_no_signed_in_user_throws_AuthReauthenticationFailure',
        () async {
      final auth = MockFirebaseAuth(); // signedIn: false (default)
      final repo = AuthRepository(auth: auth, firestore: _unusedFirestore());

      await expectLater(
        () => repo.reauthenticate(password: parentPassword),
        throwsA(isA<AuthReauthenticationFailure>()),
      );
    });
  });

  group('parentOverrideActionsProvider (provider layer)', () {
    ProviderContainer buildContainer(FirebaseAuth auth) {
      return ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          // authRepositoryProvider also watches firebaseFirestoreProvider,
          // even though reauthenticate() itself never touches Firestore —
          // must override it too or provider construction hits the real
          // FirebaseFirestore.instance (no live Firebase app in tests).
          firebaseFirestoreProvider.overrideWithValue(_unusedFirestore()),
        ],
      );
    }

    test(
        'test_attemptParentOverride_success_sets_true_and_preserves_activeChild',
        () async {
      final auth = signedInAuth(uid: 'provider-success');
      final container = buildContainer(auth);
      addTearDown(container.dispose);
      container.read(activeChildProvider.notifier).state = activeChild;

      await container
          .read(parentOverrideActionsProvider)
          .attempt(password: parentPassword);

      expect(container.read(parentOverrideProvider), isTrue);
      expect(container.read(activeChildProvider), activeChild);
      expect(container.read(activeChildProvider)?.childId, 'child-1');
    });

    test(
        'test_attemptParentOverride_wrong_password_leaves_parentOverride_false_and_rethrows',
        () async {
      final auth = signedInAuth(uid: 'provider-wrong-password');
      whenCalling(Invocation.method(#reauthenticateWithCredential, [anything]))
          .on(auth.currentUser!)
          .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
      final container = buildContainer(auth);
      addTearDown(container.dispose);
      container.read(activeChildProvider.notifier).state = activeChild;

      await expectLater(
        () => container
            .read(parentOverrideActionsProvider)
            .attempt(password: 'wrong'),
        throwsA(isA<AuthReauthenticationFailure>()),
      );

      expect(container.read(parentOverrideProvider), isFalse);
      expect(container.read(activeChildProvider), activeChild);
    });

    test(
        'test_endParentOverride_returns_directly_to_childSelected_no_intermediate_state',
        () async {
      const uid = 'provider-end-override';
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: uid, email: '$uid@example.com'),
      ); // unsigned — see header comment gotcha 2
      final container = buildContainer(auth);
      addTearDown(container.dispose);

      await waitForSignedInUser(container, auth, uid);
      container.read(activeChildProvider.notifier).state = activeChild;
      container.read(parentOverrideProvider.notifier).state = true;
      expect(container.read(sessionStateProvider), SessionState.parentView);

      final observedStates = <SessionState>[];
      container.listen(
        sessionStateProvider,
        (_, next) => observedStates.add(next),
        fireImmediately: false,
      );

      container.read(parentOverrideActionsProvider).end();

      expect(container.read(parentOverrideProvider), isFalse);
      expect(container.read(sessionStateProvider), SessionState.childSelected);
      // Only one transition observed, and it lands directly on
      // childSelected — never passes through unauthenticated/parentAuthed.
      expect(observedStates, [SessionState.childSelected]);
    });

    test(
        'test_attemptParentOverride_does_not_emit_a_new_authStateChanges_event',
        () async {
      // Regression for ADR-0002 Decision §6: using reauthenticateWithCredential
      // (not a second signInWithEmailAndPassword) must not re-trigger
      // authStateChanges(), which sessionStateProvider would otherwise
      // misread as a fresh login.
      const uid = 'provider-no-reemit';
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: uid, email: '$uid@example.com'),
      );
      final container = buildContainer(auth);
      addTearDown(container.dispose);

      await waitForSignedInUser(container, auth, uid);
      container.read(activeChildProvider.notifier).state = activeChild;

      var emissionCount = 0;
      container.listen(authStateProvider, (_, _) => emissionCount++);

      await container
          .read(parentOverrideActionsProvider)
          .attempt(password: parentPassword);

      expect(emissionCount, 0);
    });

    test(
        'test_endParentOverride_called_when_already_false_is_a_no_op',
        () async {
      // Regression from code review: a redundant "back" tap after override
      // already ended must not misbehave (e.g. re-notify listeners or throw).
      const uid = 'provider-end-idempotent';
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: uid, email: '$uid@example.com'),
      );
      final container = buildContainer(auth);
      addTearDown(container.dispose);
      await waitForSignedInUser(container, auth, uid);
      container.read(activeChildProvider.notifier).state = activeChild;
      expect(container.read(parentOverrideProvider), isFalse);

      container.read(parentOverrideActionsProvider).end();

      expect(container.read(parentOverrideProvider), isFalse);
      expect(container.read(sessionStateProvider), SessionState.childSelected);
    });

    test(
        'test_attemptParentOverride_called_twice_in_a_row_stays_true',
        () async {
      // Regression from code review: a double-tap on the override button
      // (e.g. a slow network response) must not leave state inconsistent —
      // the second call re-verifies the password and re-sets true, it does
      // not toggle or throw.
      const uid = 'provider-attempt-idempotent';
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: uid, email: '$uid@example.com'),
      );
      final container = buildContainer(auth);
      addTearDown(container.dispose);
      await waitForSignedInUser(container, auth, uid);
      container.read(activeChildProvider.notifier).state = activeChild;

      final actions = container.read(parentOverrideActionsProvider);
      await actions.attempt(password: parentPassword);
      await actions.attempt(password: parentPassword);

      expect(container.read(parentOverrideProvider), isTrue);
      expect(container.read(activeChildProvider), activeChild);
    });

    test(
        'test_reauthenticate_lets_non_FirebaseAuthException_propagate_unchanged',
        () async {
      // Documents the intended contract (matches Story 001's signIn()
      // precedent): AuthRepository.reauthenticate only narrows
      // FirebaseAuthException into AuthReauthenticationFailure. Any other
      // exception type is a real, unhandled failure (e.g. a network error)
      // and must surface as-is, not be silently swallowed or mislabeled.
      const uid = 'provider-non-firebase-exception';
      final mockUser = MockUser(uid: uid, email: '$uid@example.com');
      final auth = MockFirebaseAuth(mockUser: mockUser);
      whenCalling(Invocation.method(#reauthenticateWithCredential, [anything]))
          .on(mockUser)
          .thenThrow(const _SimulatedNetworkFailure());
      final container = buildContainer(auth);
      addTearDown(container.dispose);
      await waitForSignedInUser(container, auth, uid);

      await expectLater(
        () => container
            .read(parentOverrideActionsProvider)
            .attempt(password: parentPassword),
        throwsA(isA<_SimulatedNetworkFailure>()),
      );
      expect(container.read(parentOverrideProvider), isFalse);
    });
  });
}

/// A FirebaseFirestore that must never be touched by AuthRepository.reauthenticate.
FirebaseFirestore _unusedFirestore() => _UnusedFirestore();

class _UnusedFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('AuthRepository.reauthenticate must not touch Firestore');
}

/// A stand-in for a non-`FirebaseAuthException` failure (e.g. a network
/// error) — anything that isn't the one type `reauthenticate()` narrows.
class _SimulatedNetworkFailure implements Exception {
  const _SimulatedNetworkFailure();
}
