// Run with:
//   cd src && flutter test ../tests/unit/auth_account/session_state_provider_test.dart
//
// Pure Logic unit test — overrides authStateProvider/activeChildProvider/
// parentOverrideProvider directly rather than going through the full
// Firebase Auth mock stack (that's Integration-test territory, see
// tests/integration/auth_account/parent_login_test.dart). Reuses
// firebase_auth_mocks' MockUser as a convenient concrete `User` instance —
// no MockFirebaseAuth wiring needed since firebaseAuthProvider is never
// touched here.
//
// Uses `authStateProvider.overrideWithValue(AsyncValue...)` rather than
// `.overrideWith((ref) => stream)` — the latter compiled but the resulting
// container never left AsyncLoading in practice (every test timed out at
// 30s when actually run, not just assumed to work from the API surface).
// `overrideWithValue` injects the resolved AsyncValue directly with no
// stream-subscription step, sidestepping that entirely — confirmed working
// by running the tests, not assumed from reading the API alone.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/providers/auth_providers.dart';

void main() {
  final mockUser = MockUser(uid: 'parent-123', email: 'parent@example.com');
  // Field values below are irrelevant to sessionStateProvider (it only
  // null-checks activeChildProvider) — filled with placeholders since
  // ChildProfile's fields became required once Story 005 widened it.
  const mockChild = ChildProfile(
    childId: 'child-abc',
    name: 'Test Child',
    avatarId: 'avatar-1',
    mochiName: 'Mochi',
  );

  ProviderContainer buildContainer({
    required AsyncValue<User?> authState,
    ChildProfile? activeChild,
    bool override = false,
  }) {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWithValue(authState),
        activeChildProvider.overrideWith((ref) => activeChild),
        parentOverrideProvider.overrideWith((ref) => override),
      ],
    );
    return container;
  }

  test('test_no_user_returns_unauthenticated', () {
    final container = buildContainer(authState: const AsyncData(null));
    addTearDown(container.dispose);

    expect(container.read(sessionStateProvider), SessionState.unauthenticated);
  });

  test('test_user_signed_in_no_active_child_returns_parentAuthed', () {
    final container = buildContainer(authState: AsyncData(mockUser));
    addTearDown(container.dispose);

    expect(container.read(sessionStateProvider), SessionState.parentAuthed);
  });

  test('test_user_signed_in_child_active_no_override_returns_childSelected', () {
    final container = buildContainer(
      authState: AsyncData(mockUser),
      activeChild: mockChild,
    );
    addTearDown(container.dispose);

    expect(container.read(sessionStateProvider), SessionState.childSelected);
  });

  test('test_user_signed_in_child_active_with_override_returns_parentView', () {
    final container = buildContainer(
      authState: AsyncData(mockUser),
      activeChild: mockChild,
      override: true,
    );
    addTearDown(container.dispose);

    expect(container.read(sessionStateProvider), SessionState.parentView);
  });

  test('test_authStateProvider_error_degrades_to_unauthenticated_not_throwing', () {
    final container = buildContainer(
      authState: AsyncError<User?>(Exception('auth stream hiccup'), StackTrace.current),
    );
    addTearDown(container.dispose);

    // The point of this test: reading sessionStateProvider must not throw
    // even though the upstream state is an error.
    expect(() => container.read(sessionStateProvider), returnsNormally);
    expect(container.read(sessionStateProvider), SessionState.unauthenticated);
  });

  test('test_authStateProvider_loading_returns_unauthenticated_not_throwing', () {
    // Not in the story's literal 6-case scope, but added during code review:
    // on first app launch, before Firebase's very first emission,
    // authStateProvider sits in AsyncLoading (no prior data) — `.value` on a
    // bare AsyncLoading<User?>() is null (verified by reading
    // riverpod-3.3.2's async_value.dart, same as AsyncData(null)'s branch),
    // but that fact was previously only confirmed by reading source, never
    // by an executable test — the same category of "assumed API behavior"
    // that produced the .valueOrNull correction earlier in this project.
    // Closing that gap here rather than leaving it as an unverified claim.
    final container = buildContainer(authState: const AsyncLoading<User?>());
    addTearDown(container.dispose);

    expect(() => container.read(sessionStateProvider), returnsNormally);
    expect(container.read(sessionStateProvider), SessionState.unauthenticated);
  });

  test('test_sessionState_enum_has_exactly_4_values', () {
    expect(SessionState.values, hasLength(4));
    expect(SessionState.values, containsAll(<SessionState>[
      SessionState.unauthenticated,
      SessionState.parentAuthed,
      SessionState.childSelected,
      SessionState.parentView,
    ]));
  });
}
