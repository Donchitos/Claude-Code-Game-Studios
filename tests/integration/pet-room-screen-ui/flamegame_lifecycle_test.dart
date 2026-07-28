// Run with:
//   cd src && flutter test ../tests/integration/pet-room-screen-ui/flamegame_lifecycle_test.dart
//
// Story 005 (FlameGame Lifecycle — Never Init/Reset on Tab Return), Pet
// Room Screen UI epic. ADR-0017 Decision → TR-petroom-005 + ADR-0014
// (Navigation Shell — StatefulShellRoute/IndexedStack never-dispose
// guarantee this story relies on, main-navigation-shell Story 002's AC-5).
// This story requires NO functional code change — it ratifies already-
// correct, already-tested behavior via 3 tests:
//   - AC-CR9-1: a triggered-state animation keeps running (via the real
//     game loop, not paused) while Pet Room is offstage.
//   - AC-CR9-2: the animation settles to its final state even though
//     nothing was watching while it completed offstage — no replay, no
//     snap back.
//   - AC-TR005-1: static source-scan regression — `PetRoomGame(` (a
//     constructor call) appears exactly once anywhere in `src/lib/`, in
//     `pet_room_screen.dart`'s `_PetRoomScreenState` field declaration.
//
// Reuses the exact container/pump/fake-Firestore setup pattern from
// `tests/integration/main-navigation-shell/child_shell_test.dart` (that
// file's own header comment: private helpers can't be shared across test
// files, so duplicated here) — this story explicitly exercises Pet Room's
// own screen with a real triggered-state animation running, not just the
// generic Navigation Shell placeholder AC-5 test.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/core/triggered_state.dart';
import 'package:pet_quest/gameplay/pet_room_game.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/router_provider.dart';

/// Duplicated from `child_shell_test.dart` — see that file's own header
/// comment for why these fakes exist (`childProfilesProvider` +
/// `FloatingChipCluster`'s `xuBalanceProvider`/`seedCountProvider` reads).
class _EmptyQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async =>
      _EmptyQuerySnapshot();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  Map<String, dynamic>? data() => null;

  @override
  bool get exists => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      Stream.value(_FakeDocumentSnapshot());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _FakeCollectionReference();

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) => _FakeDocumentReference();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpSteps(
  WidgetTester tester,
  int steps, {
  Duration step = const Duration(milliseconds: 16),
}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

/// Drives a fresh app through unauthenticated -> parentAuthed -> childSelected,
/// landing on `/child/pet-room`. Identical to `child_shell_test.dart`'s own
/// `_reachChildPetRoom` — duplicated per that file's own "can't be shared"
/// note.
Future<ProviderContainer> _reachChildPetRoom(WidgetTester tester) async {
  final mockAuth = MockFirebaseAuth();
  final container = ProviderContainer(
    overrides: [
      firebaseAuthProvider.overrideWithValue(mockAuth),
      firebaseFirestoreProvider.overrideWithValue(_FakeFirestore()),
    ],
  );
  addTearDown(container.dispose);

  final routerSubscription = container.listen(routerProvider, (_, _) {});
  addTearDown(routerSubscription.close);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: routerSubscription.read()),
    ),
  );
  await tester.pumpAndSettle();

  await mockAuth.signInWithEmailAndPassword(
    email: 'parent@example.com',
    password: 'irrelevant-for-this-test',
  );
  await tester.pumpAndSettle();

  container.read(activeChildProvider.notifier).state = const ChildProfile(
    childId: 'child-1',
    name: 'Bé An',
    avatarId: 'avatar-1',
    mochiName: 'Mochi',
  );
  await _pumpSteps(tester, 6);

  return container;
}

PetRoomGame _currentPetRoomGame(WidgetTester tester) =>
    tester.widget<GameWidget<PetRoomGame>>(find.byType(GameWidget<PetRoomGame>)).game!;

void main() {
  group('AC-CR9-1/9-2: triggered-state animation survives an offstage round-trip', () {
    testWidgets(
        'test_bouncingAnimation_keepsAdvancing_whileOffstage_andSettlesCorrectly_onReturn',
        (tester) async {
      await _reachChildPetRoom(tester);
      final game = _currentPetRoomGame(tester);
      final mochi = game.mochi!;

      // Start a real triggered-state animation while Pet Room is onstage —
      // BOUNCING (seedReceived's trigger), 1.0s duration per
      // `triggered_state.dart`'s `_duration` map, driven by a
      // `_TriggerTimer` component (update(dt)-ticked, no natural
      // `Effect.onComplete` hook at this scope) — the exact mechanism GDD
      // `pet-room-screen-ui.md` Core Rule 9 ("Offscreen persistence")
      // claims completes off-screen with no special-case code.
      mochi.onTrigger(TriggeredState.bouncing);
      await _pumpSteps(tester, 2);
      expect(mochi.currentTriggeredState, TriggeredState.bouncing);
      final tickBeforeSwitch = game.updateTickCount;

      // Switch away — same offstage mechanism as main-navigation-shell
      // Story 002's AC-5 (StatefulShellRoute.indexedStack's Offstage/
      // TickerMode(false) wrapper never gates Flame's own raw Ticker).
      await tester.tap(find.text('Nhiệm vụ'));
      await _pumpSteps(tester, 3);
      expect(
        game.updateTickCount,
        greaterThan(tickBeforeSwitch),
        reason: 'AC-CR9-1: the game loop must keep running (not paused) '
            'offstage while a triggered-state animation is in progress',
      );

      // qa-tester code review: cycle through all 3 branches before
      // returning, not just a 2-branch round trip — parity with the
      // sibling AC-5 test's own "QA edge case" this story's QA Test Cases
      // cites as its pattern.
      await tester.tap(find.text('Shop'));
      await _pumpSteps(tester, 2);

      // Pump enough elapsed time offstage for BOUNCING (1.0s) to fully
      // complete — 15 steps of 100ms (1.5s, ~50% margin) rather than the
      // originally-reviewed 12/1.2s, per flame-specialist/qa-tester code
      // review's suggestion to widen the margin defensively.
      await _pumpSteps(tester, 15, step: const Duration(milliseconds: 100));

      // Return to Pet Room.
      await tester.tap(find.text('Nhà'));
      await _pumpSteps(tester, 2);

      expect(
        identical(_currentPetRoomGame(tester), game),
        isTrue,
        reason: 'the same FlameGame instance must be observed on return',
      );
      expect(
        mochi.currentTriggeredState,
        isNull,
        reason: 'AC-CR9-2: the animation must have settled to its final '
            '(post-animation) state while offstage — no replay, no snap '
            'back to the pre-animation state on return',
      );

      // No restart: pumping further frames must not re-trigger BOUNCING.
      await _pumpSteps(tester, 3);
      expect(mochi.currentTriggeredState, isNull);
    });
  });

  group('AC-TR005-1: PetRoomGame is constructed exactly once, at the screen layer', () {
    test(
        'test_PetRoomGame_constructorCall_existsExactlyOnce_inPetRoomScreen_fieldDeclaration',
        () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final matches = <String>[];
      for (final file in dartFiles) {
        if (_codeOnly(file.readAsStringSync()).contains('PetRoomGame(')) {
          matches.add(file.path);
        }
      }

      expect(
        matches,
        ['lib/ui/pet_room_screen.dart'],
        reason: 'ADR-0017 Decision → TR-petroom-005: PetRoomGame() must be '
            'constructed exactly once, in _PetRoomScreenState\'s field '
            'declaration — no other file may call the constructor (no '
            'inline rebuild-on-every-build(), no re-init on tab return)',
      );

      final screenSource =
          _codeOnly(File('lib/ui/pet_room_screen.dart').readAsStringSync());
      final occurrenceCount = 'PetRoomGame('.allMatches(screenSource).length;
      expect(
        occurrenceCount,
        1,
        reason: 'exactly 1 constructor call within the one file that has any',
      );
    });
  });
}

/// Strips `//`/`///`-prefixed comment lines before the AC-TR005-1 scan —
/// flame-specialist code review: this codebase's own convention (visible
/// throughout `pet_room_game.dart`/`mochi_component.dart`'s doc comments,
/// even in this file's own `reason:` strings) is to quote exact
/// `ClassName()` call syntax in prose when cross-referencing forbidden
/// patterns. Without this, a future doc comment merely *mentioning*
/// `PetRoomGame(` would false-positive this regression check. Line-based
/// only (no `/* */` block-comment handling) — this codebase does not use
/// block comments, so that's not a gap in practice.
String _codeOnly(String source) => source
    .split('\n')
    .where((line) => !line.trim().startsWith('//'))
    .join('\n');
