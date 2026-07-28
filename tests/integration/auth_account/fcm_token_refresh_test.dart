// Run with:
//   cd src && flutter test ../tests/integration/auth_account/fcm_token_refresh_test.dart
//
// Uses the same hand-rolled minimal Firestore fake pattern as
// parent_login_test.dart (fake_cloud_firestore is incompatible with
// cloud_firestore ^6.7.1 — see that file's header comment), but this file's
// `_FakeDocumentReference.set()` DOES implement `SetOptions(merge: true)`
// semantics (merging into the existing stored map rather than replacing it),
// unlike parent_login_test.dart's simpler always-replace fake — this story's
// whole point is proving `updateFcmToken` only touches the `fcmToken` field,
// so a fake that ignored merge would let a real regression (accidentally
// dropping `merge: true`) pass undetected. NOTE: the merge is a shallow
// top-level-key spread, not Firestore's real recursive nested-map merge, and
// `SetOptions.mergeFields` isn't handled — correct for this story's one flat
// string field, but don't reuse this fake as-is for a story that merges
// nested map fields.
//
// firebase_messaging has no equivalent to firebase_auth_mocks, so
// `_FakeFirebaseMessaging` is a small hand-rolled fake exposing a
// controllable `onTokenRefresh` stream via a broadcast StreamController.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/auth_repository.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/providers/auth_providers.dart';

class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocumentSnapshot(this._data);
  final Map<String, dynamic>? _data;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => _data != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  Map<String, dynamic>? stored;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return _FakeDocumentSnapshot(stored);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (options?.merge == true && stored != null) {
      stored = {...stored!, ...data};
    } else {
      stored = data;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  final _docs = <String, _FakeDocumentReference>{};

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _docs.putIfAbsent(path, () => _FakeDocumentReference());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseMessaging implements FirebaseMessaging {
  final _controller = StreamController<String>.broadcast();

  @override
  Stream<String> get onTokenRefresh => _controller.stream;

  void emitToken(String token) => _controller.add(token);

  bool get hasListener => _controller.hasListener;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const parentId = 'parent-123';

  group('AuthRepository.updateFcmToken (unit)', () {
    test(
        'test_updateFcmToken_writes_only_the_fcmToken_field_via_merge',
        () async {
      final firestore = _FakeFirestore();
      final doc = firestore.doc(FirestorePaths.family(parentId))
          as _FakeDocumentReference;
      doc.stored = {'email': 'parent@example.com', 'fcmToken': 'old-token'};
      final repo = AuthRepository(
        auth: MockFirebaseAuth(),
        firestore: firestore,
      );

      await repo.updateFcmToken(parentId: parentId, token: 'new-token');

      expect(doc.stored!['fcmToken'], 'new-token');
      expect(doc.stored!['email'], 'parent@example.com'); // untouched
      expect(doc.stored!.length, 2); // no stray fields added
    });

    test(
        'test_updateFcmToken_on_a_brand_new_family_doc_creates_it_with_just_fcmToken',
        () async {
      final firestore = _FakeFirestore();
      final repo = AuthRepository(auth: MockFirebaseAuth(), firestore: firestore);

      await repo.updateFcmToken(parentId: parentId, token: 'first-token');

      final doc = firestore.doc(FirestorePaths.family(parentId))
          as _FakeDocumentReference;
      expect(doc.stored, {'fcmToken': 'first-token'});
    });
  });

  group('fcmTokenRefreshListenerProvider (provider layer)', () {
    ProviderContainer buildContainer({
      required FirebaseAuth auth,
      required FirebaseFirestore firestore,
      required FirebaseMessaging messaging,
    }) {
      return ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firebaseFirestoreProvider.overrideWithValue(firestore),
          firebaseMessagingProvider.overrideWithValue(messaging),
        ],
      );
    }

    Future<User> waitForSignedInUser(
      ProviderContainer container,
      MockFirebaseAuth auth,
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
      auth.signInWithEmailAndPassword(email: 'parent@example.com', password: 'x');
      return completer.future.timeout(const Duration(seconds: 5));
    }

    test(
        'test_onTokenRefresh_writes_new_token_to_familyDoc_when_signed_in',
        () async {
      final auth = MockFirebaseAuth();
      final firestore = _FakeFirestore();
      final messaging = _FakeFirebaseMessaging();
      final container = buildContainer(
        auth: auth,
        firestore: firestore,
        messaging: messaging,
      );
      addTearDown(container.dispose);

      final user = await waitForSignedInUser(container, auth);
      final doc = firestore.doc(FirestorePaths.family(user.uid))
          as _FakeDocumentReference;
      doc.stored = {'email': 'parent@example.com'};

      // Establish the listener (mirrors main.dart's ref.watch keeping it live).
      final listenerSub =
          container.listen(fcmTokenRefreshListenerProvider, (_, _) {});
      addTearDown(listenerSub.close);
      expect(messaging.hasListener, isTrue);

      messaging.emitToken('refreshed-token-abc');
      await Future<void>.delayed(Duration.zero); // let the stream event land

      expect(doc.stored!['fcmToken'], 'refreshed-token-abc');
      expect(doc.stored!['email'], 'parent@example.com'); // untouched
    });

    test(
        'test_fcmTokenRefreshListener_does_not_subscribe_when_signed_out',
        () async {
      final auth = MockFirebaseAuth(); // unsigned
      final firestore = _FakeFirestore();
      final messaging = _FakeFirebaseMessaging();
      final container = buildContainer(
        auth: auth,
        firestore: firestore,
        messaging: messaging,
      );
      addTearDown(container.dispose);

      final listenerSub =
          container.listen(fcmTokenRefreshListenerProvider, (_, _) {});
      addTearDown(listenerSub.close);

      expect(messaging.hasListener, isFalse);
    });

    test(
        'test_fcmTokenRefreshListener_cancels_old_subscription_on_sign_out',
        () async {
      final auth = MockFirebaseAuth();
      final firestore = _FakeFirestore();
      final messaging = _FakeFirebaseMessaging();
      final container = buildContainer(
        auth: auth,
        firestore: firestore,
        messaging: messaging,
      );
      addTearDown(container.dispose);

      await waitForSignedInUser(container, auth);
      final listenerSub =
          container.listen(fcmTokenRefreshListenerProvider, (_, _) {});
      addTearDown(listenerSub.close);
      expect(messaging.hasListener, isTrue);

      await auth.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(messaging.hasListener, isFalse);
    });

    test(
        'test_fcmTokenRefreshListener_resubscribes_and_writes_to_new_user_after_sign_out_sign_in',
        () async {
      // Regression from code review: only the teardown half of the
      // sign-out/sign-in cycle was previously tested — this proves the
      // listener actually comes back, not just that it goes away.
      final auth = MockFirebaseAuth();
      final firestore = _FakeFirestore();
      final messaging = _FakeFirebaseMessaging();
      final container = buildContainer(
        auth: auth,
        firestore: firestore,
        messaging: messaging,
      );
      addTearDown(container.dispose);

      await waitForSignedInUser(container, auth);
      final listenerSub =
          container.listen(fcmTokenRefreshListenerProvider, (_, _) {});
      addTearDown(listenerSub.close);
      expect(messaging.hasListener, isTrue);

      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(messaging.hasListener, isFalse);

      final secondUser = await waitForSignedInUser(container, auth);
      await Future<void>.delayed(Duration.zero);
      expect(messaging.hasListener, isTrue);

      messaging.emitToken('post-resignin-token');
      await Future<void>.delayed(Duration.zero);

      final doc = firestore.doc(FirestorePaths.family(secondUser.uid))
          as _FakeDocumentReference;
      expect(doc.stored!['fcmToken'], 'post-resignin-token');
    });

    test(
        'test_fcmTokenRefreshListener_logs_and_does_not_crash_on_write_failure',
        () async {
      final auth = MockFirebaseAuth();
      final messaging = _FakeFirebaseMessaging();
      final container = buildContainer(
        auth: auth,
        firestore: _AlwaysFailingFirestore(),
        messaging: messaging,
      );
      addTearDown(container.dispose);

      await waitForSignedInUser(container, auth);
      final listenerSub =
          container.listen(fcmTokenRefreshListenerProvider, (_, _) {});
      addTearDown(listenerSub.close);

      messaging.emitToken('token-that-fails-to-write');
      // The regression this guards against is an unhandled Future rejection
      // reaching the zone's uncaught-error handler and failing the test —
      // if `updateFcmToken`'s error isn't caught internally, this await
      // surfaces it here instead of silently, which is exactly what we want
      // to prove does NOT happen.
      await Future<void>.delayed(Duration.zero);
    });
  });
}

class _AlwaysFailingDocumentReference
    implements DocumentReference<Map<String, dynamic>> {
  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) {
    throw Exception('simulated permission-denied');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AlwaysFailingFirestore implements FirebaseFirestore {
  @override
  DocumentReference<Map<String, dynamic>> doc(String path) =>
      _AlwaysFailingDocumentReference();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
