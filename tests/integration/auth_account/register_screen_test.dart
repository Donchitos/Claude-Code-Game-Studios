// Run with:
//   cd src && flutter test ../tests/integration/auth_account/register_screen_test.dart
//
// Same widget-test pattern as login_screen_test.dart (see that file's header
// comment) — MockFirebaseAuth + mock_exceptions to simulate
// FirebaseAuthException scenarios without a live Firebase backend.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/providers/router_provider.dart';
import 'package:pet_quest/ui/login_screen.dart';
import 'package:pet_quest/ui/register_screen.dart';

/// A [FirebaseAuth] whose account-creation call never resolves until the
/// test explicitly completes it — same rationale as login_screen_test.dart's
/// `_ControllableAuth`: [MockFirebaseAuth]'s calls resolve within a
/// microtask, too fast for a single `pump()` to reliably observe a
/// mid-flight UI state.
class _ControllableAuth implements FirebaseAuth {
  Completer<UserCredential> _completer = Completer<UserCredential>();
  int callCount = 0;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    callCount++;
    return _completer.future;
  }

  void completeWithError(Object error) => _completer.completeError(error);

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
  Map<String, dynamic>? stored;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return _FakeDocumentSnapshot(stored);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    stored = data;
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

void main() {
  const email = 'new.parent@example.com';
  const password = 'a-strong-password';

  Future<void> pumpRegisterScreen(WidgetTester tester, FirebaseAuth auth) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          firebaseFirestoreProvider.overrideWithValue(_FakeFirestore()),
        ],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );
  }

  Future<void> enterEmailPasswordConfirm(
    WidgetTester tester, {
    required String email,
    required String password,
    required String confirm,
  }) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), password);
    await tester.enterText(fields.at(2), confirm);
  }

  testWidgets(
      'test_RegisterScreen_renders_email_password_confirm_fields_and_CTA',
      (tester) async {
    await pumpRegisterScreen(tester, MockFirebaseAuth());

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
    expect(find.text('Đăng ký'), findsOneWidget);
    expect(find.text('Đã có tài khoản? Đăng nhập'), findsOneWidget);
  });

  testWidgets(
      'test_RegisterScreen_mismatched_passwords_blocks_submission_without_calling_signUp',
      (tester) async {
    // Uses the call-counting _ControllableAuth (not a plain MockFirebaseAuth
    // + currentUser==null proxy) per the story's own QA Test Case spec's
    // explicit request for a call-count proof — currentUser==null doesn't
    // distinguish "never called" from "called and failed for some other
    // reason" (found in code review, qa-tester, 2026-07-16).
    final auth = _ControllableAuth();
    await pumpRegisterScreen(tester, auth);

    await enterEmailPasswordConfirm(
      tester,
      email: email,
      password: password,
      confirm: 'a-different-password',
    );
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu xác nhận không khớp.'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget); // P8
    expect(auth.callCount, 0); // signUp() genuinely never called
  });

  testWidgets(
      'test_RegisterScreen_empty_password_blocks_submission_without_calling_signUp',
      (tester) async {
    // register_screen.dart's empty-password branch (`if
    // (_passwordController.text.isEmpty) { ... }`) is only reachable when
    // BOTH fields are blank — if only one were empty, the mismatch check
    // above it would fire first with a different message. Previously
    // untested (found in code review, qa-tester, 2026-07-16).
    final auth = _ControllableAuth();
    await pumpRegisterScreen(tester, auth);

    await enterEmailPasswordConfirm(tester, email: email, password: '', confirm: '');
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
    expect(auth.callCount, 0);
  });

  testWidgets(
      'test_RegisterScreen_empty_email_blocks_submission_without_calling_signUp',
      (tester) async {
    // register_screen.dart's non-empty-email check, added alongside the
    // pre-existing password checks for consistency (found missing in code
    // review — qa-tester, 2026-07-16).
    final auth = _ControllableAuth();
    await pumpRegisterScreen(tester, auth);

    await enterEmailPasswordConfirm(tester, email: '', password: password, confirm: password);
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập email.'), findsOneWidget);
    expect(auth.callCount, 0);
  });

  testWidgets(
      'test_RegisterScreen_success_calls_signUp_and_shows_no_error',
      (tester) async {
    final auth = MockFirebaseAuth(); // no exception registered -> succeeds
    await pumpRegisterScreen(tester, auth);

    await enterEmailPasswordConfirm(
      tester,
      email: email,
      password: password,
      confirm: password,
    );
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNotNull);
    expect(auth.currentUser!.email, email);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  testWidgets(
      'test_RegisterScreen_email_already_in_use_shows_its_own_distinct_message',
      (tester) async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #createUserWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
    await pumpRegisterScreen(tester, auth);

    await enterEmailPasswordConfirm(
      tester,
      email: email,
      password: password,
      confirm: password,
    );
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Email này đã được đăng ký — hãy đăng nhập.'), findsOneWidget);
  });

  testWidgets(
      'test_RegisterScreen_weak_password_shows_its_own_distinct_message',
      (tester) async {
    // Screen-level coverage of the remaining FirebaseAuthException codes —
    // previously only proven at the repository level (found in code
    // review, qa-tester, 2026-07-16).
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #createUserWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'weak-password'));
    await pumpRegisterScreen(tester, auth);

    await enterEmailPasswordConfirm(
      tester,
      email: email,
      password: password,
      confirm: password,
    );
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu quá yếu — cần tối thiểu 6 ký tự.'), findsOneWidget);
  });

  testWidgets(
      'test_RegisterScreen_invalid_email_shows_its_own_distinct_message',
      (tester) async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #createUserWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'invalid-email'));
    await pumpRegisterScreen(tester, auth);

    await enterEmailPasswordConfirm(
      tester,
      email: email,
      password: password,
      confirm: password,
    );
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Email không hợp lệ.'), findsOneWidget);
  });

  testWidgets(
      'test_RegisterScreen_unrecognized_code_falls_back_to_generic_message',
      (tester) async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #createUserWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'some-unrecognized-code'));
    await pumpRegisterScreen(tester, auth);

    await enterEmailPasswordConfirm(
      tester,
      email: email,
      password: password,
      confirm: password,
    );
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Có lỗi xảy ra, vui lòng thử lại'), findsOneWidget);
  });

  testWidgets(
      'test_RegisterScreen_network_failure_shows_distinct_error_message',
      (tester) async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(
      #createUserWithEmailAndPassword,
      null,
      {#email: email, #password: password},
    )).on(auth).thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    await pumpRegisterScreen(tester, auth);

    await enterEmailPasswordConfirm(
      tester,
      email: email,
      password: password,
      confirm: password,
    );
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Không có kết nối mạng — thử lại'), findsOneWidget);
    expect(find.text('Email này đã được đăng ký — hãy đăng nhập.'), findsNothing);
  });

  testWidgets('test_RegisterScreen_double_tap_only_calls_createUser_once',
      (tester) async {
    // P1 single-flight guard, same proof shape as LoginScreen's — a literal
    // second tap while mid-flight must not reach the handler.
    final auth = _ControllableAuth();
    await pumpRegisterScreen(tester, auth);
    await enterEmailPasswordConfirm(
      tester,
      email: email,
      password: password,
      confirm: password,
    );

    await tester.tap(find.text('Đăng ký'));
    await tester.pump(); // one frame — mid-flight, signUp() future still pending
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    expect(auth.callCount, 1);

    auth.completeWithError(FirebaseAuthException(code: 'email-already-in-use'));
    await tester.pumpAndSettle();
    expect(find.text('Email này đã được đăng ký — hãy đăng nhập.'), findsOneWidget);
  });

  testWidgets('test_RegisterScreen_toggle_password_visibility_affects_both_fields',
      (tester) async {
    await pumpRegisterScreen(tester, MockFirebaseAuth());

    final passwordField = find.byType(TextField).at(1);
    final confirmField = find.byType(TextField).at(2);
    expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
    expect(tester.widget<TextField>(confirmField).obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
    expect(tester.widget<TextField>(confirmField).obscureText, isFalse);
  });

  testWidgets(
      'test_RegisterScreen_CTA_and_login_link_meet_minimum_tap_target',
      (tester) async {
    await pumpRegisterScreen(tester, MockFirebaseAuth());

    final ctaSize = tester.getSize(find.byType(FilledButton));
    expect(ctaSize.height, greaterThanOrEqualTo(48));

    final linkSize = tester.getSize(find.byType(TextButton));
    expect(linkSize.height, greaterThanOrEqualTo(48));
  });

  testWidgets(
      'test_RegisterScreen_disposed_while_signUp_pending_does_not_throw',
      (tester) async {
    // Locks in the mounted-check discipline LoginScreen already established
    // (found missing there in code review — code-review 2026-07-16) — proves
    // RegisterScreen's _submit() mirrors it rather than silently regressing.
    final auth = _ControllableAuth();
    await pumpRegisterScreen(tester, auth);
    await enterEmailPasswordConfirm(
      tester,
      email: email,
      password: password,
      confirm: password,
    );
    await tester.tap(find.text('Đăng ký'));
    await tester.pump(); // mid-flight

    await tester.pumpWidget(const SizedBox()); // dispose RegisterScreen
    auth.completeWithError(FirebaseAuthException(code: 'weak-password'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'test_RegisterScreen_login_link_navigates_to_login_route_via_real_router',
      (tester) async {
    // The existing render test only proves the link text exists — this
    // proves tapping it actually navigates, through the app's real
    // GoRouter (the reverse of login_screen_test.dart's register-link
    // test, which only checks rendering since it hosts LoginScreen without
    // a router at all).
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

    container.read(routerProvider).go(AppRoutes.register);
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    await tester.tap(find.text('Đã có tài khoản? Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
