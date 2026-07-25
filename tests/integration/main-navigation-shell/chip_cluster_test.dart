// Run with:
//   cd src && flutter test ../tests/integration/main-navigation-shell/chip_cluster_test.dart
//
// Story 006 (Floating Chip Cluster — Profile, Xu, Contextual Badge Wiring,
// main-navigation-shell epic, LAST story in this epic) — covers this story's
// own 9 acceptance criteria (Profile chip render, Xu chip normal/error/
// count-up/pulse/decrease, Contextual badge hidden/seed-variant/pop-in/
// further-pulse, touch target, safe area) plus the "absorbed, not
// duplicated" ParentOverrideTrigger regression already covered end-to-end by
// `parent_override_test.dart` in this same directory (this file adds one
// direct sanity check of its own per this story's own Test Evidence
// requirement, not a full re-test of that story's 6 ACs), plus 3 gaps found
// in code review: a strengthened mutual-exclusivity test (both seed AND
// chest positive at once, not just chest-alone), reduced-motion coverage
// (hud.md's Dynamic Behaviors calls this a hard requirement, not previously
// tested), and a chip-persistence-across-tab-switch test proving the
// Forbidden "chips must never render inside IndexedStack branch content"
// rule structurally holds (same "assert identity, don't just trust the doc
// comment" standard Story 002's own AC-5 applied to Pet Room's FlameGame).
//
// Reuses `parent_override_test.dart`'s own `_reachChildPetRoom`/`_pumpSteps`
// helper shape (signed-in `MockFirebaseAuth` from the start, bounded-step
// pumps once Pet Room's `GameWidget`/Ticker is mounted — never
// `pumpAndSettle()` from that point on, same file-wide gotcha documented in
// every sibling file in this directory) — extended here with a combined
// Firestore fake that ALSO supports `.doc(...).snapshots()` with a
// `seed()`/`seedError()` mutation seam (the pattern established by
// `tests/unit/currency_system/xu_balance_provider_test.dart` /
// `tests/unit/seed_buffer/seed_count_provider_test.dart`), since this file —
// unlike its siblings — actually needs to drive `xuBalance`/`seedCount`
// values, not just avoid crashing on the `.doc()` call.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/providers/router_provider.dart';
import 'package:pet_quest/ui/contextual_badge_chip.dart';
import 'package:pet_quest/ui/floating_chip_cluster.dart';
import 'package:pet_quest/ui/parent_override_trigger.dart';
import 'package:pet_quest/ui/parent_switch_mode_sheet.dart';
import 'package:pet_quest/ui/profile_chip.dart';
import 'package:pet_quest/ui/xu_chip.dart';

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

/// Mirrors the unit-test-level `_FakeDocumentReference` (`xu_balance_provider_test.dart`
/// / `seed_count_provider_test.dart`) — a live, mutable `.doc().snapshots()`
/// stream this file can `seed()`/`seedError()` to drive `xuBalance`/
/// `seedCount` scenarios.
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
  final _controller = StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();
  Map<String, dynamic>? _data;

  void seed(Map<String, dynamic>? data) {
    _data = data;
    _controller.add(_FakeDocumentSnapshot(data));
  }

  void seedError(Object error) => _controller.addError(error);

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return Stream.multi((controller) {
      controller.add(_FakeDocumentSnapshot(_data));
      final sub = _controller.stream.listen(controller.add, onError: controller.addError);
      controller.onCancel = sub.cancel;
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  final _docs = <String, _FakeDocumentReference>{};

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _FakeCollectionReference();

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) =>
      _docs.putIfAbsent(path, () => _FakeDocumentReference());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _activeChild = ChildProfile(
  childId: 'child-1',
  name: 'Bé An',
  avatarId: 'avatar-1',
  mochiName: 'Mochi',
);

Future<void> _pumpSteps(
  WidgetTester tester,
  int steps, {
  Duration step = const Duration(milliseconds: 16),
}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

/// Mirrors `parent_override_test.dart`'s own `_reachChildPetRoom` — a
/// SIGNED-IN `MockFirebaseAuth` from the start, landing on `/child/pet-room`.
/// Returns the [ProviderContainer] and the [_FakeDocumentReference] backing
/// the active child's document, so callers can `seed()`/`seedError()`
/// `xuBalance`/`seedCount` directly for a subsequent, genuinely-observed
/// TRANSITION.
///
/// [initialXuBalance]/[initialSeedCount] are seeded on the child document
/// BEFORE the widget tree is even pumped — critical, not cosmetic: both
/// [XuChip] and the Contextual badge treat their FIRST-ever observed value as
/// a snap (no count-up/pulse/pop-in "transition" animation — see
/// `xu_chip.dart`'s `_hasObservedFirstValue` / `contextual_badge_chip.dart`'s
/// fresh-mount-on-`0`->positive design). If a test instead left the document
/// unseeded (defaulting to `0` on first snapshot) and only called
/// `docRef.seed(...)` AFTER reaching Pet Room, that `.seed()` call would
/// itself be observed as a real `0 -> N` transition and trigger an animation
/// the test isn't expecting — found empirically while writing these tests
/// (an assertion checking for a settled/final value instead observed a
/// mid-animation intermediate one).
Future<(ProviderContainer, _FakeDocumentReference)> _reachChildPetRoom(
  WidgetTester tester, {
  String uid = 'parent-1',
  int initialXuBalance = 0,
  int initialSeedCount = 0,
}) async {
  final mockAuth = MockFirebaseAuth(
    signedIn: true,
    mockUser: MockUser(uid: uid, email: '$uid@example.com'),
  );
  final firestore = _FakeFirestore();
  final docRef = firestore.doc(FirestorePaths.child(uid, _activeChild.childId))
      as _FakeDocumentReference;
  docRef.seed({'xuBalance': initialXuBalance, 'seedCount': initialSeedCount});

  final container = ProviderContainer(
    overrides: [
      firebaseAuthProvider.overrideWithValue(mockAuth),
      firebaseFirestoreProvider.overrideWithValue(firestore),
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
  // Safe: no GameWidget/Ticker exists yet at /select-child (this file starts
  // already signed in, same as parent_override_test.dart).
  await tester.pumpAndSettle();

  container.read(activeChildProvider.notifier).state = _activeChild;
  // From here on: bounded steps only (Pet Room's GameWidget/Ticker gotcha,
  // documented in every sibling file in this directory).
  await _pumpSteps(tester, 6);

  return (container, docRef);
}

void main() {
  group('AC-3 / hud.md §1: Profile chip', () {
    testWidgets(
        'test_profileChip_rendersAvatarAndName_adjacentToXuChip_withVisibleGap_notFused',
        (tester) async {
      await _reachChildPetRoom(tester);

      expect(find.byType(ProfileChip), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('Bé An'), findsOneWidget);

      final avatarSize = tester.getSize(find.byType(CircleAvatar));
      expect(avatarSize.width, 32, reason: '32dp avatar circle (hud.md §1)');
      expect(avatarSize.height, 32);

      final nameText = tester.widget<Text>(find.text('Bé An'));
      expect(nameText.style?.fontSize, 16, reason: '16sp per hud.md §1');
      expect(nameText.style?.fontWeight, FontWeight.bold);

      // Adjacent with a visible gap — never fused into one shape.
      final profileRight = tester.getTopRight(find.byType(ProfileChip)).dx;
      final xuLeft = tester.getTopLeft(find.byKey(XuChip.chipKey)).dx;
      expect(
        xuLeft,
        greaterThan(profileRight),
        reason: 'Xu chip must start to the right of where Profile chip ends — no overlap',
      );
      expect(
        xuLeft - profileRight,
        greaterThanOrEqualTo(4),
        reason: 'a real visible gap, not a 0px seam (fused shape)',
      );
    });
  });

  group('AC-6/AC-7: Xu chip normal + error', () {
    testWidgets('test_AC6_xuBalance75_displaysCoinIconAndNumber75', (tester) async {
      // Seeded as the INITIAL value (before mount) — AC-6 is a static
      // "GIVEN the provider has value 75" given, not a transition, so the
      // first-observed-value snap path is exactly what's under test here.
      await _reachChildPetRoom(tester, initialXuBalance: 75);
      await _pumpSteps(tester, 3);

      expect(find.text('🪙'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(XuChip.balanceTextKey)).data,
        '75',
      );
    });

    testWidgets('test_AC7_xuBalanceProviderError_displaysDashXu_noCrash', (tester) async {
      final (_, docRef) = await _reachChildPetRoom(tester, initialXuBalance: 10);
      await _pumpSteps(tester, 3);
      expect(tester.widget<Text>(find.byKey(XuChip.balanceTextKey)).data, '10');

      docRef.seedError(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
      await _pumpSteps(tester, 3);

      expect(
        tester.widget<Text>(find.byKey(XuChip.balanceTextKey)).data,
        '— xu',
        reason: 'AC-7 exact wording',
      );
      // No crash: the widget tree is still pumpable/inspectable afterward.
      expect(find.byType(XuChip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Xu chip animation: count-up + reward pulse + decrease', () {
    testWidgets(
        'test_xuChip_increase50to75_animatesCountUpOver400ms_notInstantJump',
        (tester) async {
      final (_, docRef) = await _reachChildPetRoom(tester, initialXuBalance: 50);
      await _pumpSteps(tester, 3);
      expect(tester.widget<Text>(find.byKey(XuChip.balanceTextKey)).data, '50');

      docRef.seed({'xuBalance': 75});
      await tester.pump(); // observe the change
      await tester.pump(const Duration(milliseconds: 200)); // mid-animation

      final midValue = int.parse(tester.widget<Text>(find.byKey(XuChip.balanceTextKey)).data!);
      expect(
        midValue,
        allOf(greaterThan(50), lessThan(75)),
        reason: 'at ~half the 400ms count-up window, the displayed value must '
            'be strictly between 50 and 75 — not an instant jump to 75',
      );

      await tester.pump(const Duration(milliseconds: 250)); // finish the sweep
      expect(tester.widget<Text>(find.byKey(XuChip.balanceTextKey)).data, '75');
    });

    testWidgets('test_xuChip_increase_playsScalePulse_1_0_to_1_15_and_back',
        (tester) async {
      final (_, docRef) = await _reachChildPetRoom(tester, initialXuBalance: 50);
      await _pumpSteps(tester, 3);

      double scaleOf() => tester.widget<ScaleTransition>(find.byKey(XuChip.pulseKey)).scale.value;
      expect(scaleOf(), 1.0, reason: 'settled, no pulse in flight yet');

      docRef.seed({'xuBalance': 75});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100)); // mid-pulse (~half of 200ms)

      expect(
        scaleOf(),
        greaterThan(1.0),
        reason: 'mid-pulse the chip must be scaled up above 1.0 (peak 1.15)',
      );

      await tester.pump(const Duration(milliseconds: 150)); // pulse finished
      expect(scaleOf(), 1.0, reason: 'pulse settles back to 1.0 after ~200ms');
    });

    testWidgets('test_xuChip_decrease_snapsInstantly_noPulse_noCountUp', (tester) async {
      final (_, docRef) = await _reachChildPetRoom(tester, initialXuBalance: 75);
      await _pumpSteps(tester, 3);
      expect(tester.widget<Text>(find.byKey(XuChip.balanceTextKey)).data, '75');

      docRef.seed({'xuBalance': 50}); // purchase (decrease)
      await tester.pump();

      expect(
        tester.widget<Text>(find.byKey(XuChip.balanceTextKey)).data,
        '50',
        reason: 'a decrease snaps immediately — no count-up sweep to observe',
      );
      expect(
        tester.widget<ScaleTransition>(find.byKey(XuChip.pulseKey)).scale.value,
        1.0,
        reason: 'hud.md §2: purchases (decrease) have no pulse',
      );
    });
  });

  group('Contextual badge (seed binding): hidden/shown + animations', () {
    testWidgets(
        'test_AC4_contextualBadge_hiddenAtZero_genuinelyAbsentFromWidgetTree_notOpacityOrZeroBox',
        (tester) async {
      final (_, docRef) = await _reachChildPetRoom(tester);
      docRef.seed({'seedCount': 0});
      await _pumpSteps(tester, 3);

      expect(
        find.byKey(ContextualBadgeChip.badgeKey),
        findsNothing,
        reason: 'genuinely absent — not a zero-opacity/zero-size placeholder',
      );
      expect(find.textContaining('🌱'), findsNothing);
    });

    testWidgets('test_AC5_contextualBadge_seedVariant_showsSeedIconAndCount',
        (tester) async {
      final (_, docRef) = await _reachChildPetRoom(tester);
      docRef.seed({'seedCount': 2});
      await _pumpSteps(tester, 3);

      expect(find.byKey(ContextualBadgeChip.badgeKey), findsOneWidget);
      expect(find.text('🌱 2'), findsOneWidget);
    });

    testWidgets(
        'test_contextualBadge_mutualExclusivity_seedZero_chestPositive_noBadge',
        (tester) async {
      // Documents this story's own scoped decision (Out of Scope §5 / this
      // story's Implementation Note 3): `chestCount` has no dedicated
      // provider yet, so the badge is wired to `seedCountProvider`
      // unconditionally. Seeding a `chestCount` field on the same document
      // must have zero effect on the badge when seedCount is 0.
      final (_, docRef) = await _reachChildPetRoom(tester);
      docRef.seed({'seedCount': 0, 'chestCount': 3});
      await _pumpSteps(tester, 3);

      expect(
        find.byKey(ContextualBadgeChip.badgeKey),
        findsNothing,
        reason: 'seedCount is 0 — chestCount must not surface a badge on its own',
      );
    });

    testWidgets(
        'test_contextualBadge_mutualExclusivity_seedAndChestBothPositive_showsSeedOnly_neverBoth',
        (tester) async {
      // Strengthens the case above (found in code review — the seedCount:0
      // case alone doesn't distinguish "chest is ignored" from "nothing
      // renders because both happen to be falsy"). This is the actual
      // conflict case hud.md §3's mutual-exclusivity rule guards against:
      // BOTH counts positive at once. Proves exactly one binding is active
      // (seed) and no chest-related content ever appears alongside it —
      // never both simultaneously.
      final (_, docRef) = await _reachChildPetRoom(tester);
      docRef.seed({'seedCount': 2, 'chestCount': 3});
      await _pumpSteps(tester, 3);

      expect(find.byKey(ContextualBadgeChip.badgeKey), findsOneWidget);
      expect(find.text('🌱 2'), findsOneWidget,
          reason: 'seed variant must render even with a positive chestCount present');
      expect(find.textContaining('🎁'), findsNothing,
          reason: 'no chest icon/content must ever render alongside the seed variant');
      expect(find.textContaining('3'), findsNothing,
          reason: 'the chestCount value (3) must never leak into the badge text');
    });

    testWidgets(
        'test_contextualBadge_firstAppearFromZero_playsPopInWithOvershoot',
        (tester) async {
      final (_, docRef) = await _reachChildPetRoom(tester);
      docRef.seed({'seedCount': 0});
      await _pumpSteps(tester, 3);
      expect(find.byKey(ContextualBadgeChip.badgeKey), findsNothing);

      docRef.seed({'seedCount': 1});
      await tester.pump(); // mount + first animation frame
      await tester.pump(const Duration(milliseconds: 150)); // mid pop-in (of 300ms, overshoot phase)

      final midScale =
          tester.widget<ScaleTransition>(find.byKey(ContextualBadgeChip.badgeKey)).scale.value;
      expect(
        midScale,
        greaterThan(0.0),
        reason: 'pop-in must have started growing from 0',
      );

      await tester.pump(const Duration(milliseconds: 200)); // finish the pop-in
      expect(
        tester.widget<ScaleTransition>(find.byKey(ContextualBadgeChip.badgeKey)).scale.value,
        1.0,
        reason: 'pop-in settles back to 1.0 after the overshoot (0 -> 1.1 -> 1.0)',
      );
    });

    testWidgets(
        'test_contextualBadge_furtherIncrementWhileVisible_playsSinglePulse_notAnotherPopIn',
        (tester) async {
      final (_, docRef) = await _reachChildPetRoom(tester);
      docRef.seed({'seedCount': 1});
      await _pumpSteps(tester, 3); // let the pop-in settle
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        tester.widget<ScaleTransition>(find.byKey(ContextualBadgeChip.badgeKey)).scale.value,
        1.0,
      );
      // Same State instance persists across this increment — proven by the
      // widget/State identity, not just a passing assertion.
      final stateBefore = tester.state(find.byType(ContextualBadgeChip));

      docRef.seed({'seedCount': 2});
      await tester.pump();
      expect(find.text('🌱 2'), findsOneWidget);
      expect(identical(tester.state(find.byType(ContextualBadgeChip)), stateBefore), isTrue);

      await tester.pump(const Duration(milliseconds: 100)); // mid pulse (of 200ms)
      final midScale =
          tester.widget<ScaleTransition>(find.byKey(ContextualBadgeChip.badgeKey)).scale.value;
      expect(midScale, greaterThan(1.0), reason: 'a further increment pulses above 1.0');

      await tester.pump(const Duration(milliseconds: 150));
      expect(
        tester.widget<ScaleTransition>(find.byKey(ContextualBadgeChip.badgeKey)).scale.value,
        1.0,
      );
    });
  });

  group('Reduced motion — hard requirement per hud.md Dynamic Behaviors, found untested in code review', () {
    testWidgets(
        'test_xuChip_reducedMotion_increaseSnapsInstantly_noPulse_noCountUp',
        (tester) async {
      // Established codebase pattern (`pin_entry_screen_test.dart`) —
      // `platformDispatcher.accessibilityFeaturesTestValue` makes
      // `MediaQuery.of(context).disableAnimations` return true for every
      // widget in the tree, without needing to re-pump/replace it.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

      final (_, docRef) = await _reachChildPetRoom(tester, initialXuBalance: 50);
      await _pumpSteps(tester, 3);

      docRef.seed({'xuBalance': 75});
      await tester.pump(); // a single frame — no animation window to observe

      expect(
        tester.widget<Text>(find.byKey(XuChip.balanceTextKey)).data,
        '75',
        reason: 'reduced motion must settle instantly, no count-up sweep',
      );
      expect(
        tester.widget<ScaleTransition>(find.byKey(XuChip.pulseKey)).scale.value,
        1.0,
        reason: 'reduced motion must never scale-pulse, even on a reward increase',
      );
    });

    testWidgets(
        'test_contextualBadge_reducedMotion_firstAppearSettlesInstantly_noPopIn',
        (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

      final (_, docRef) = await _reachChildPetRoom(tester);
      docRef.seed({'seedCount': 0});
      await _pumpSteps(tester, 3);

      docRef.seed({'seedCount': 1});
      await tester.pump(); // a single frame — no pop-in window to observe

      expect(find.byKey(ContextualBadgeChip.badgeKey), findsOneWidget);
      expect(find.text('🌱 1'), findsOneWidget);
      expect(
        tester.widget<ScaleTransition>(find.byKey(ContextualBadgeChip.badgeKey)).scale.value,
        1.0,
        reason: 'reduced motion must settle directly at scale 1.0, no overshoot',
      );
    });
  });

  group('Chip persistence across Child Shell tab switches — Forbidden pattern check, found untested in code review', () {
    testWidgets(
        'test_floatingChipCluster_survivesTabSwitch_sameStateIdentity_neverRebuiltByIndexedStack',
        (tester) async {
      // This story's own Control Manifest Rules list as FORBIDDEN: "chips
      // must never render inside Story 002/003's IndexedStack-managed branch
      // content — they belong in the Stack overlay above navigationShell."
      // floating_chip_cluster.dart's own doc comment claims exactly this
      // placement, and child_shell_scaffold.dart structurally does place it
      // as a Stack SIBLING of navigationShell, not inside it — but nothing
      // in this file had actually proven it survives a real tab switch
      // (Story 002's own AC-5 applied this same "assert instance identity,
      // don't just read the doc comment" standard to Pet Room's FlameGame;
      // applying it here too).
      // Seeded as the INITIAL value (not via a post-mount .seed() call) —
      // per _reachChildPetRoom's own doc comment, seeding after mount would
      // be observed as a real 0->50/0->1 transition and leave the count-up/
      // pop-in animation still in flight when captured below (found the
      // hard way: an earlier version of this test read a mid-animation
      // value here instead of the settled 50).
      await _reachChildPetRoom(
        tester,
        initialXuBalance: 50,
        initialSeedCount: 1,
      );
      await _pumpSteps(tester, 3);

      final xuStateBefore = tester.state(find.byType(XuChip));
      final badgeStateBefore = tester.state(find.byType(ContextualBadgeChip));

      // Switch to Tasks, then Shop, before returning — same "cycle through
      // all branches" rigor as child_shell_test.dart's own AC-5 test.
      await tester.tap(find.text('Nhiệm vụ'));
      await _pumpSteps(tester, 2);
      expect(find.byType(XuChip), findsOneWidget,
          reason: 'chips must remain mounted on the Tasks tab too — they are '
              'NOT branch content');

      await tester.tap(find.text('Shop'));
      await _pumpSteps(tester, 2);
      await tester.tap(find.text('Nhà'));
      await _pumpSteps(tester, 2);

      expect(
        identical(tester.state(find.byType(XuChip)), xuStateBefore),
        isTrue,
        reason: 'the SAME XuChip State instance must persist across the full '
            'branch cycle — proves it was never rebuilt/torn down by '
            'IndexedStack, since it structurally sits outside it',
      );
      expect(
        identical(tester.state(find.byType(ContextualBadgeChip)), badgeStateBefore),
        isTrue,
        reason: 'same proof for ContextualBadgeChip',
      );
      // Balance/seed values also survived unchanged — not just the instance.
      expect(tester.widget<Text>(find.byKey(XuChip.balanceTextKey)).data, '50');
      expect(find.text('🌱 1'), findsOneWidget);
    });
  });

  group('AC-7 (touch target) / Safe area', () {
    testWidgets('test_touchTarget_profileAndXuChip_meetMinimum48x48dp', (tester) async {
      await _reachChildPetRoom(tester);

      final profileSize = tester.getSize(find.byType(ProfileChip));
      expect(profileSize.width, greaterThanOrEqualTo(48));
      expect(profileSize.height, greaterThanOrEqualTo(48));

      final xuSize = tester.getSize(find.byKey(XuChip.chipKey));
      expect(xuSize.width, greaterThanOrEqualTo(48));
      expect(xuSize.height, greaterThanOrEqualTo(48));
      // Upper-bound regression check (flame-widget-specialist code-review
      // finding): a real, live-tested bug had XuChip's `Center` expand to
      // fill FloatingChipCluster's Row-provided loose-but-finite max height
      // (near the full screen height, hundreds of dp) instead of
      // shrink-wrapping to its pill content. The lower-bound-only
      // assertions above would NOT have caught that regression (an exploded
      // chip still trivially satisfies `>= 48`) — this does. 60dp is a
      // generous ceiling for a single-line icon+digit pill with 8dp
      // vertical padding (well above any real content height, comfortably
      // below "obviously exploded").
      expect(
        xuSize.height,
        lessThan(60),
        reason: 'a pill-shaped chip must shrink-wrap to its content height, '
            "not expand to fill the cluster Row's available height "
            '(regression check for the Center(widthFactor/heightFactor: 1) fix)',
      );
    });

    testWidgets(
        'test_touchTarget_contextualBadgeChip_meetsMinimumAndDoesNotExplode',
        (tester) async {
      final (_, docRef) = await _reachChildPetRoom(tester);
      docRef.seed({'seedCount': 2});
      await _pumpSteps(tester, 3);

      // `ContextualBadgeChip` received the identical `Center(widthFactor:
      // 1, heightFactor: 1)` fix as `XuChip` but had ZERO layout-size test
      // coverage before this (flame-widget-specialist code-review finding)
      // — its existing tests only checked `find.byKey`/`find.text`
      // presence, never `RenderBox.size`.
      final badgeSize = tester.getSize(find.byKey(ContextualBadgeChip.badgeKey));
      expect(badgeSize.width, greaterThanOrEqualTo(48));
      expect(badgeSize.height, greaterThanOrEqualTo(48));
      expect(
        badgeSize.height,
        lessThan(60),
        reason: 'same shrink-wrap regression check as XuChip above — a '
            "bare Center() here would expand to the cluster Row's full "
            'available height instead of the pill content height',
      );
    });

    testWidgets(
        'test_safeArea_chipsPushedBelowInjectedTopInset_neverRenderUnderNotch',
        (tester) async {
      addTearDown(tester.view.resetPadding);
      // `FakeViewPadding` is specified in PHYSICAL pixels — pinning
      // `devicePixelRatio` to 1.0 makes physical == logical so the assertion
      // below can compare directly against the injected value (found
      // empirically: the test environment's default device pixel ratio
      // otherwise silently divides the injected padding down before it
      // reaches `MediaQueryData.padding`).
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 60);

      await _reachChildPetRoom(tester);

      expect(find.byType(SafeArea), findsWidgets);
      final profileTop = tester.getTopLeft(find.byType(ProfileChip)).dy;
      expect(
        profileTop,
        greaterThanOrEqualTo(60),
        reason: 'the injected 60px top inset must push the chip cluster down '
            '— it must never render under a notch/Dynamic Island/cutout',
      );
    });
  });

  group('ParentOverrideTrigger absorption sanity', () {
    testWidgets(
        'test_parentOverrideTrigger_absorbedIntoProfileChip_longPressStillOpensSwitchModeSheet',
        (tester) async {
      // Not a full re-test of Story 004's 6 ACs (already covered end-to-end
      // by parent_override_test.dart in this directory) — just proves the
      // ABSORPTION itself: the same `ParentOverrideTrigger.triggerKey` now
      // lives inside the real Profile chip (not a second standalone
      // placeholder widget), and long-pressing it still opens the real
      // switch-mode sheet.
      await _reachChildPetRoom(tester);

      expect(find.byKey(ParentOverrideTrigger.triggerKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(ParentOverrideTrigger.triggerKey),
          matching: find.byType(ProfileChip),
        ),
        findsNothing,
        reason: 'ParentOverrideTrigger wraps ProfileChip\'s visual content as '
            'its child — ProfileChip is the ANCESTOR (it builds the '
            'trigger), not a descendant of it',
      );
      expect(
        find.ancestor(
          of: find.byKey(ParentOverrideTrigger.triggerKey),
          matching: find.byType(ProfileChip),
        ),
        findsOneWidget,
        reason: 'the trigger is mounted INSIDE ProfileChip, not beside it as '
            'a second standalone widget',
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(ParentOverrideTrigger.triggerKey)),
      );
      await tester.pump(kParentOverrideLongPressDuration + const Duration(milliseconds: 50));
      await gesture.up();
      await _pumpSteps(tester, 10);

      expect(find.text('Chuyển sang tài khoản bố/mẹ?'), findsOneWidget);
      expect(find.byType(ParentSwitchModeSheet), findsOneWidget);
    });
  });
}
