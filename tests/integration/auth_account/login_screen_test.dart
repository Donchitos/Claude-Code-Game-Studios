// Run with:
//   cd src && flutter test ../tests/integration/auth_account/login_screen_test.dart
//
// UI story (Test Evidence gate: ADVISORY per coding-standards.md) — this
// automated widget test is written in addition to (and substitutes for) the
// manual-walkthrough evidence doc the story names, matching this project's
// established pattern of preferring real automated coverage over manual
// evidence wherever feasible ("Verification-Driven Development",
// coding-standards.md).
//
// Uses the same hand-rolled minimal Firestore fake pattern as
// parent_login_test.dart, plus MockFirebaseAuth + mock_exceptions to
// simulate FirebaseAuthException scenarios (wrong credentials, network
// failure) without a live Firebase backend.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/providers/router_provider.dart';
import 'package:pet_quest/ui/login_screen.dart';
import 'package:pet_quest/ui/register_screen.dart';

/// A [FirebaseAuth] whose sign-in call never resolves until the test
/// explicitly completes it — lets a test observe the "mid-flight" UI state
/// deterministically, unlike [MockFirebaseAuth] (whose rejected Futures
/// resolve within a microtask, too fast for a single `pump()` to observe
/// reliably).
class _ControllableAuth implements FirebaseAuth {
  Completer<UserCredential> _completer = Completer<UserCredential>();
  int callCount = 0;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    callCount++;
    return _completer.future;
  }

  void completeWithError(Object error) => _completer.completeError(error);

  /// Resets to a fresh, still-pending call for the next invocation —
  /// [signInWithEmailAndPassword] always returns the same in-flight future
  /// otherwise, which would make a second call resolve instantly with the
  /// first call's (already-completed) outcome instead of staying pending.
  void resetPending() => _completer = Completer<UserCredential>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return _FakeDocumentSnapshot(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  @override
  DocumentReference<Map<String, dynamic>> doc(String path) => _FakeDocumentReference();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const email = 'parent@example.com';
  const password = 'correct-password';

  Future<void> pumpLoginScreen(WidgetTester tester, FirebaseAuth auth) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firebaseFirestoreProvider.overrideWithValue(_FakeFirestore()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
  }

  testWidgets('test_LoginScreen_renders_email_password_fields_and_CTA',
      (tester) async {
    await pumpLoginScreen(tester, MockFirebaseAuth());

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
  });

  testWidgets(
      'test_LoginScreen_wrong_credentials_shows_generic_error_and_clears_password',
      (tester) async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #signInWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'invalid-credential'));
    await pumpLoginScreen(tester, auth);

    await tester.enterText(find.byType(TextField).first, email);
    await tester.enterText(find.byType(TextField).last, password);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Sai email hoặc mật khẩu.'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget); // P8
    final passwordField = tester.widget<TextField>(find.byType(TextField).last);
    expect(passwordField.controller!.text, isEmpty);
  });

  testWidgets('test_LoginScreen_network_failure_shows_distinct_error_message',
      (tester) async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #signInWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    await pumpLoginScreen(tester, auth);

    await tester.enterText(find.byType(TextField).first, email);
    await tester.enterText(find.byType(TextField).last, password);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Không có kết nối mạng — thử lại'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget); // P8
    expect(find.text('Sai email hoặc mật khẩu.'), findsNothing);
  });

  testWidgets(
      'test_LoginScreen_network_failure_does_not_clear_the_password_field',
      (tester) async {
    // A network blip is unrelated to whether the typed credentials are
    // correct — discarding a correctly-typed password would force needless
    // re-entry (found in code review — code-review 2026-07-16).
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #signInWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    await pumpLoginScreen(tester, auth);

    await tester.enterText(find.byType(TextField).first, email);
    await tester.enterText(find.byType(TextField).last, password);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    final passwordField = tester.widget<TextField>(find.byType(TextField).last);
    expect(passwordField.controller!.text, password);
  });

  testWidgets('test_LoginScreen_success_calls_signIn_and_shows_no_error',
      (tester) async {
    final auth = MockFirebaseAuth(); // no exception registered -> succeeds
    await pumpLoginScreen(tester, auth);

    await tester.enterText(find.byType(TextField).first, email);
    await tester.enterText(find.byType(TextField).last, password);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNotNull);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  testWidgets(
      'test_LoginScreen_unexpected_non_FirebaseAuthException_still_shows_a_message',
      (tester) async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #signInWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(Exception('simulated unexpected failure'));
    await pumpLoginScreen(tester, auth);

    await tester.enterText(find.byType(TextField).first, email);
    await tester.enterText(find.byType(TextField).last, password);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Có lỗi xảy ra, vui lòng thử lại'), findsOneWidget);
    // The CTA must re-enable — it must not be left permanently disabled.
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('test_LoginScreen_retyping_after_an_error_clears_it',
      (tester) async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #signInWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'invalid-credential'));
    await pumpLoginScreen(tester, auth);

    await tester.enterText(find.byType(TextField).first, email);
    await tester.enterText(find.byType(TextField).last, password);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Sai email hoặc mật khẩu.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'new-password');
    // The error zone fades out over 150ms (AnimatedSwitcher) rather than
    // vanishing instantly — settle past that before asserting it's gone.
    await tester.pumpAndSettle();

    expect(find.text('Sai email hoặc mật khẩu.'), findsNothing);
  });

  testWidgets('test_LoginScreen_email_format_hint_is_non_blocking',
      (tester) async {
    await pumpLoginScreen(tester, MockFirebaseAuth());

    await tester.enterText(find.byType(TextField).first, 'not-an-email');
    await tester.pump();
    expect(find.text('Email chưa đúng định dạng'), findsOneWidget);

    // Non-blocking: the CTA is still enabled and tappable.
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);

    await tester.enterText(find.byType(TextField).first, email);
    await tester.pump();
    expect(find.text('Email chưa đúng định dạng'), findsNothing);
  });

  testWidgets('test_LoginScreen_double_tap_only_calls_signIn_once',
      (tester) async {
    // Proves the P1 single-flight guard structurally AND behaviorally: a
    // literal second tap while mid-flight must not reach the handler. Uses
    // a Completer-controlled fake auth so the mid-flight window is
    // deterministically observable (MockFirebaseAuth's rejection resolves
    // within a microtask, too fast for a single pump() to reliably catch).
    final auth = _ControllableAuth();

    await pumpLoginScreen(tester, auth);
    await tester.enterText(find.byType(TextField).first, email);
    await tester.enterText(find.byType(TextField).last, password);

    await tester.tap(find.text('Đăng nhập'));
    await tester.pump(); // one frame — mid-flight, signIn() future still pending
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Đăng nhập'), findsNothing); // label replaced by spinner
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    // A literal second tap while mid-flight — Flutter ignores taps on a
    // null-onPressed button, so this must not increment callCount.
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    expect(auth.callCount, 1);

    auth.completeWithError(FirebaseAuthException(code: 'invalid-credential'));
    await tester.pumpAndSettle();
    expect(find.text('Sai email hoặc mật khẩu.'), findsOneWidget);
  });

  testWidgets(
      'test_LoginScreen_disposed_while_signIn_pending_does_not_throw',
      (tester) async {
    // Locks in the `mounted` check in _submit()'s catch/finally blocks
    // (found missing on 2 of 3 branches in code review — code-review
    // 2026-07-16).
    final auth = _ControllableAuth();
    await pumpLoginScreen(tester, auth);
    await tester.enterText(find.byType(TextField).first, email);
    await tester.enterText(find.byType(TextField).last, password);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump(); // mid-flight

    await tester.pumpWidget(const SizedBox()); // dispose LoginScreen
    auth.completeWithError(FirebaseAuthException(code: 'invalid-credential'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('test_LoginScreen_forgot_password_tap_is_a_noop', (tester) async {
    await pumpLoginScreen(tester, MockFirebaseAuth());

    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('test_LoginScreen_toggle_password_visibility', (tester) async {
    await pumpLoginScreen(tester, MockFirebaseAuth());

    final passwordFieldFinder = find.byType(TextField).last;
    expect(tester.widget<TextField>(passwordFieldFinder).obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(tester.widget<TextField>(passwordFieldFinder).obscureText, isFalse);
  });

  testWidgets(
      'test_LoginScreen_CTA_and_forgot_password_link_meet_minimum_tap_target',
      (tester) async {
    await pumpLoginScreen(tester, MockFirebaseAuth());

    final ctaSize = tester.getSize(find.byType(FilledButton));
    expect(ctaSize.height, greaterThanOrEqualTo(48));

    // Two TextButtons now exist ("Quên mật khẩu?" and Story 013's "Chưa có
    // tài khoản? Đăng ký") — every tappable element must meet the tap
    // target, not just the first.
    for (final buttonFinder in find.byType(TextButton).evaluate()) {
      final size = tester.getSize(find.byWidget(buttonFinder.widget));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('test_LoginScreen_register_link_renders', (tester) async {
    // Render-only — the actual navigation is proven separately below, by
    // tapping the link through a real GoRouter (found under-covered in code
    // review, qa-tester, 2026-07-16: a same-named test previously claimed
    // navigation coverage in its name/comment but never called
    // tester.tap(), so nothing anywhere in the suite actually proved this
    // direction of the mirror-link AC — fixed here).
    await pumpLoginScreen(tester, MockFirebaseAuth());

    expect(find.text('Chưa có tài khoản? Đăng ký'), findsOneWidget);
  });

  testWidgets(
      'test_LoginScreen_register_link_navigates_to_register_route_via_real_router',
      (tester) async {
    // The reverse of register_screen_test.dart's
    // test_RegisterScreen_login_link_navigates_to_login_route_via_real_router
    // — both directions of the mirror link are now proven through a real
    // GoRouter, not just MaterialApp-only rendering.
    final auth = MockFirebaseAuth();
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        firebaseFirestoreProvider.overrideWithValue(_FakeFirestore()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: container.read(routerProvider)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}
