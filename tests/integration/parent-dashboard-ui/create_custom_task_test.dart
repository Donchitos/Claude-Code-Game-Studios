// Run with:
//   cd src && flutter test ../tests/integration/parent-dashboard-ui/create_custom_task_test.dart
//
// Story: parent-dashboard-ui/story-002-create-custom-task — Test Evidence
// section. Covers all 8 Acceptance Criteria bullets from the story,
// including the story's own BLOCKING criterion (`targetChildId` read-back —
// see `test_BLOCKING_singleChild_targetChildId_matchesKnownChildId_onReadBack`
// below, written first per Implementation Note 6).
//
// This is the first story in the `parent-dashboard-ui` epic to reach
// implementation — `tests/integration/parent-dashboard-ui/` is a new
// directory.
//
// Backend under test (`CustomTaskRepository.createCustomTaskTemplate`,
// `CustomTaskTemplate.toFirestoreMap`, `knownCategoryIds`) is already built
// and already unit-tested in
// `tests/unit/task_library/custom_task_test.dart` — this file does NOT
// re-test that logic; it tests the widget layer wired on top of it
// (`CreateCustomTaskSheet`), using the same hand-rolled minimal Firestore
// fake pattern as that file and `child_profile_selection_screen_test.dart`
// (`fake_cloud_firestore` is incompatible with the installed
// `cloud_firestore ^6.7.1` — see `parent_login_test.dart`'s header comment
// for the original finding).
//
// The BLOCKING read-back test asserts against `firestore.collection(...)
// .get()` — the SAME fake-Firestore read path `childProfilesProvider`
// itself uses elsewhere in this codebase — not against any UI state or the
// sheet's own internal fields, satisfying the story's "not inferred from UI
// state" requirement (a wrong `targetChildId` would leave zero UI symptom;
// the sheet closes and the snackbar shows regardless).
//
// Pump strategy: NEVER `pumpAndSettle()` in this file. `CreateCustomTaskSheet`
// renders an indeterminate `CircularProgressIndicator()` in TWO places —
// while `childProfilesProvider` is loading, and while `_isSubmitting` is
// true during Save — and an indeterminate spinner schedules frames forever,
// so `pumpAndSettle()` would hang/time out for as long as either is
// mounted, even transiently (same class of gotcha already documented in
// `tests/integration/main-navigation-shell/parent_override_test.dart`'s
// header comment, there caused by a Flame `Ticker` instead). This file uses
// a local bounded `_pumpSteps` helper (fixed frame count) everywhere
// instead, copied in spirit from that same file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/core/models/child_profile.dart';
import 'package:pet_quest/providers/auth_providers.dart';
import 'package:pet_quest/ui/create_custom_task_sheet.dart';

class _FakeUser implements User {
  _FakeUser(this.uid);
  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this.path);
  @override
  final String path;

  @override
  String get id => path.split('/').last;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQueryDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDocumentSnapshot(this._id, this._data);
  final String _id;
  final Map<String, dynamic> _data;

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _FakeQuerySnapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A collection reference backed by [_FakeFirestore]'s shared per-path
/// document store. Supports both `.add()` (`CustomTaskRepository`'s write
/// path, auto-ID) and `.get()` (`childProfilesProvider`'s read path for
/// `children`, AND this test's own genuine read-back of whatever `.add()`
/// wrote to `customTasks` — the same call shape a real caller would use).
class _FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  _FakeCollectionReference(this.path, this._firestore);
  final String path;
  final _FakeFirestore _firestore;

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
    Map<String, dynamic> data,
  ) async {
    if (_firestore.failNextWrite) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'simulated-failure',
        message: 'Simulated Firestore write failure for test',
      );
    }
    final docs = _firestore.store.putIfAbsent(path, () => {});
    final id = 'doc-${_firestore.nextId++}';
    docs[id] = data;
    return _FakeDocumentReference('$path/$id');
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final docs = _firestore.store[path] ?? const <String, Map<String, dynamic>>{};
    return _FakeQuerySnapshot([
      for (final entry in docs.entries)
        _FakeQueryDocumentSnapshot(entry.key, entry.value),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  /// path -> (docId -> data). Shared backing store for both the `children`
  /// collection (seeded, read via `childProfilesProvider`) and the
  /// `customTasks` collection (written by `CustomTaskRepository`, read back
  /// by this test's own assertions).
  final store = <String, Map<String, Map<String, dynamic>>>{};
  int nextId = 1;
  bool failNextWrite = false;

  void seedChildren(String parentId, List<ChildProfile> children) {
    final docs = store.putIfAbsent(FirestorePaths.children(parentId), () => {});
    for (final child in children) {
      docs[child.childId] = {
        'name': child.name,
        'avatarId': child.avatarId,
        'mochiName': child.mochiName,
      };
    }
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _FakeCollectionReference(path, this);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const parentId = 'parent-1';
  const singleChild =
      ChildProfile(childId: 'child-1', name: 'Bé An', avatarId: 'avatar-1', mochiName: 'Mochi An');
  const childB =
      ChildProfile(childId: 'child-2', name: 'Bé Bình', avatarId: 'avatar-2', mochiName: 'Mochi Bình');
  const childC =
      ChildProfile(childId: 'child-3', name: 'Bé Chi', avatarId: 'avatar-3', mochiName: 'Mochi Chi');
  const childD =
      ChildProfile(childId: 'child-4', name: 'Bé Dung', avatarId: 'avatar-4', mochiName: 'Mochi Dung');

  /// Fixed-frame-count pump, never `pumpAndSettle()` — see header comment.
  Future<void> pumpSteps(WidgetTester tester,
      [int steps = 20, Duration step = const Duration(milliseconds: 16)]) async {
    for (var i = 0; i < steps; i++) {
      await tester.pump(step);
    }
  }

  /// Pumps a minimal host screen with a button that opens the sheet, then
  /// taps it and pumps enough frames for the slide-up (P3, 250ms) and the
  /// `childProfilesProvider` async resolution to complete.
  Future<void> pumpAndOpenSheet(
    WidgetTester tester, {
    required _FakeFirestore firestore,
    String uid = parentId,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseFirestoreProvider.overrideWithValue(firestore),
          authStateProvider.overrideWith((ref) => Stream.value(_FakeUser(uid))),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showCreateCustomTaskSheet(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await pumpSteps(tester);
  }

  group('AC — Conditional child selector (P18)', () {
    testWidgets(
        'test_CreateCustomTaskSheet_exactlyOneChild_hidesChildSelector',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [singleChild]);
      await pumpAndOpenSheet(tester, firestore: firestore);

      expect(find.byKey(CreateCustomTaskSheet.childDropdownKey), findsNothing);
      expect(find.byKey(CreateCustomTaskSheet.titleFieldKey), findsOneWidget);
    });

    testWidgets(
        'test_CreateCustomTaskSheet_twoChildren_showsChildSelectorWithBoth',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [singleChild, childB]);
      await pumpAndOpenSheet(tester, firestore: firestore);

      expect(find.byKey(CreateCustomTaskSheet.childDropdownKey), findsOneWidget);

      await tester.tap(find.byKey(CreateCustomTaskSheet.childDropdownKey));
      await pumpSteps(tester);

      expect(find.text(singleChild.name), findsWidgets);
      expect(find.text(childB.name), findsWidgets);
    });

    testWidgets(
        'test_CreateCustomTaskSheet_fourChildren_maxCap_showsChildSelectorWithAllFour',
        (tester) async {
      final firestore = _FakeFirestore()
        ..seedChildren(parentId, [singleChild, childB, childC, childD]);
      await pumpAndOpenSheet(tester, firestore: firestore);

      expect(find.byKey(CreateCustomTaskSheet.childDropdownKey), findsOneWidget);

      await tester.tap(find.byKey(CreateCustomTaskSheet.childDropdownKey));
      await pumpSteps(tester);

      for (final child in [singleChild, childB, childC, childD]) {
        expect(find.text(child.name), findsWidgets);
      }
    });

    testWidgets(
        'test_CreateCustomTaskSheet_zeroChildren_disablesSaveAndShowsMessage',
        (tester) async {
      // Defensive path (`_buildForm`'s `children.isEmpty` branch, `_canSave`'s
      // explicit `children.isEmpty` guard) had zero automated coverage
      // (found in code review's QA testability pass) — no test seeded an
      // empty children list.
      final firestore = _FakeFirestore(); // no seedChildren() call at all
      await pumpAndOpenSheet(tester, firestore: firestore);

      expect(
        find.text('Cần có ít nhất 1 bé trong gia đình để tạo nhiệm vụ.'),
        findsOneWidget,
      );
      expect(find.byKey(CreateCustomTaskSheet.childDropdownKey), findsNothing,
          reason: 'P18: no children to select from, so no selector at all — '
              'same shape as the 1-child auto-assign case, not an error state');

      final button = tester.widget<FilledButton>(
        find.byKey(CreateCustomTaskSheet.saveButtonKey),
      );
      expect(button.onPressed, isNull,
          reason: 'Save must stay disabled with no child to assign the task to');
    });
  });

  group('AC — Category dropdown', () {
    testWidgets(
        'test_CreateCustomTaskSheet_categoryDropdown_exposesExactlyTheFiveRealCategories',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [singleChild]);
      await pumpAndOpenSheet(tester, firestore: firestore);

      await tester.tap(find.byKey(CreateCustomTaskSheet.categoryDropdownKey));
      await pumpSteps(tester);

      const expectedLabels = ['Học tập', 'Nghệ thuật', 'Việc nhà', 'Thể thao', 'Giúp đỡ'];
      for (final label in expectedLabels) {
        expect(find.text(label), findsOneWidget);
      }
      // `custom` is Task Library's fallback-only tag — must never be a
      // selectable option here (GDD Core Rule 3 / Story Implementation
      // Note 3).
      expect(find.text('custom'), findsNothing);
      expect(
        find.byWidgetPredicate((w) => w is DropdownMenuItem<String>),
        findsNWidgets(expectedLabels.length),
      );
    });
  });

  group('AC — Empty title validation', () {
    /// Selects a category (single-child family — no child selector to
    /// satisfy) so the Save gate under test isolates title behavior, per
    /// the story's Edge Case 2 framing.
    Future<void> selectCategory(WidgetTester tester, String label) async {
      await tester.tap(find.byKey(CreateCustomTaskSheet.categoryDropdownKey));
      await pumpSteps(tester);
      await tester.tap(find.text(label).last);
      await pumpSteps(tester);
    }

    testWidgets(
        'test_CreateCustomTaskSheet_emptyOrWhitespaceOnlyTitle_disablesSave',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [singleChild]);
      await pumpAndOpenSheet(tester, firestore: firestore);
      await selectCategory(tester, 'Học tập');

      // Empty title.
      var button = tester.widget<FilledButton>(
        find.byKey(CreateCustomTaskSheet.saveButtonKey),
      );
      expect(button.onPressed, isNull, reason: 'empty title must disable Save');

      // Whitespace-only title (spaces and tabs).
      await tester.enterText(
        find.byKey(CreateCustomTaskSheet.titleFieldKey),
        '   \t  ',
      );
      await pumpSteps(tester);
      button = tester.widget<FilledButton>(find.byKey(CreateCustomTaskSheet.saveButtonKey));
      expect(button.onPressed, isNull,
          reason: 'whitespace-only title must disable Save');
    });

    testWidgets(
        'test_CreateCustomTaskSheet_nonWhitespaceTitle_enablesSave',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [singleChild]);
      await pumpAndOpenSheet(tester, firestore: firestore);
      await selectCategory(tester, 'Học tập');

      await tester.enterText(
        find.byKey(CreateCustomTaskSheet.titleFieldKey),
        'Đọc sách mỗi tối',
      );
      await pumpSteps(tester);

      final button = tester.widget<FilledButton>(
        find.byKey(CreateCustomTaskSheet.saveButtonKey),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  group('AC — Save writes correct document / BLOCKING targetChildId read-back', () {
    Future<void> fillAndSave(
      WidgetTester tester, {
      required String title,
      required String categoryLabel,
    }) async {
      await tester.enterText(find.byKey(CreateCustomTaskSheet.titleFieldKey), title);
      await pumpSteps(tester);
      await tester.tap(find.byKey(CreateCustomTaskSheet.categoryDropdownKey));
      await pumpSteps(tester);
      await tester.tap(find.text(categoryLabel).last);
      await pumpSteps(tester);
      await tester.tap(find.byKey(CreateCustomTaskSheet.saveButtonKey));
      await pumpSteps(tester);
    }

    testWidgets(
        'test_CreateCustomTaskSheet_singleChild_savesExactly4FieldsNoStatus_closesSheet_showsSnackbar',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [singleChild]);
      await pumpAndOpenSheet(tester, firestore: firestore);

      await fillAndSave(tester, title: 'Đọc sách mỗi tối', categoryLabel: 'Học tập');

      // Sheet closed.
      expect(find.byKey(CreateCustomTaskSheet.titleFieldKey), findsNothing);
      expect(find.text('Đã thêm nhiệm vụ'), findsOneWidget);

      final snap =
          await firestore.collection(FirestorePaths.customTasks(parentId)).get();
      expect(snap.docs, hasLength(1));
      final data = snap.docs.single.data();
      expect(data.keys.toSet(), {'title', 'categoryId', 'targetChildId', 'createdAt'});
      expect(data.containsKey('status'), isFalse);
      expect(data['title'], 'Đọc sách mỗi tối');
      expect(data['categoryId'], 'study');
    });

    testWidgets(
        'test_BLOCKING_singleChild_targetChildId_matchesKnownChildId_onReadBack',
        (tester) async {
      // GIVEN a family with exactly 1 child, child ID known ahead of time.
      final firestore = _FakeFirestore()..seedChildren(parentId, [singleChild]);
      await pumpAndOpenSheet(tester, firestore: firestore);

      // WHEN Save is called with valid title/category (no child selector
      // exists to pick from — the single child's ID must be auto-assigned).
      await fillAndSave(tester, title: 'Dọn phòng', categoryLabel: 'Việc nhà');

      // THEN: read the just-written document back from the fake Firestore's
      // own store via its public `.collection(path).get()` API — NOT
      // inferred from any UI state (the sheet closing / snackbar showing
      // would look identical even if `targetChildId` were wrong).
      final snap =
          await firestore.collection(FirestorePaths.customTasks(parentId)).get();
      expect(snap.docs, hasLength(1));
      expect(
        snap.docs.single.data()['targetChildId'],
        singleChild.childId,
        reason: 'a wrong targetChildId silently corrupts data with zero UI '
            'symptom — this must be a genuine backend read-back, not a UI '
            'inference',
      );
    });

    testWidgets(
        'test_CreateCustomTaskSheet_multipleChildren_savesWithExplicitlySelectedChildId',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [singleChild, childB]);
      await pumpAndOpenSheet(tester, firestore: firestore);

      await tester.enterText(
        find.byKey(CreateCustomTaskSheet.titleFieldKey),
        'Tập thể dục',
      );
      await pumpSteps(tester);
      await tester.tap(find.byKey(CreateCustomTaskSheet.categoryDropdownKey));
      await pumpSteps(tester);
      await tester.tap(find.text('Thể thao').last);
      await pumpSteps(tester);
      await tester.tap(find.byKey(CreateCustomTaskSheet.childDropdownKey));
      await pumpSteps(tester);
      await tester.tap(find.text(childB.name).last);
      await pumpSteps(tester);

      await tester.tap(find.byKey(CreateCustomTaskSheet.saveButtonKey));
      await pumpSteps(tester);

      final snap =
          await firestore.collection(FirestorePaths.customTasks(parentId)).get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.single.data()['targetChildId'], childB.childId);
    });

    testWidgets(
        'test_CreateCustomTaskSheet_rapidDoubleTapSave_writesExactlyOneDocument',
        (tester) async {
      // Rapid-double-tap-on-a-submit-button was a REAL bug found in 3
      // separate stories of the sibling main-navigation-shell epic (not a
      // theoretical risk) — `_canSave`/`_isSubmitting` looks sound by code
      // inspection alone, but that epic's whole pattern was that inspection
      // kept being wrong in practice. Proven here, not just inspected (found
      // missing in code review's QA testability pass).
      final firestore = _FakeFirestore()..seedChildren(parentId, [singleChild]);
      await pumpAndOpenSheet(tester, firestore: firestore);

      await tester.enterText(
        find.byKey(CreateCustomTaskSheet.titleFieldKey),
        'Đọc sách mỗi tối',
      );
      await pumpSteps(tester);
      await tester.tap(find.byKey(CreateCustomTaskSheet.categoryDropdownKey));
      await pumpSteps(tester);
      await tester.tap(find.text('Học tập').last);
      await pumpSteps(tester);

      await tester.tap(find.byKey(CreateCustomTaskSheet.saveButtonKey));
      // No pump() here — the second tap must land before the first's
      // setState(_isSubmitting = true) has been observed by a fresh pump,
      // proving the button is already disabled at the earliest possible
      // re-tap point, not just "eventually". `warnIfMissed: false` because a
      // hit-test MISS on this second tap is the expected, correct outcome —
      // the button has `onPressed: null` while submitting.
      await tester.tap(
        find.byKey(CreateCustomTaskSheet.saveButtonKey),
        warnIfMissed: false,
      );
      await pumpSteps(tester);

      final snap =
          await firestore.collection(FirestorePaths.customTasks(parentId)).get();
      expect(
        snap.docs,
        hasLength(1),
        reason: 'a rapid double-tap on Save must write exactly one document, '
            'never two',
      );
    });
  });

  group('AC — Duplicate title allowed', () {
    testWidgets(
        'test_CreateCustomTaskSheet_twoSavesWithIdenticalTitle_bothDocumentsExist_noDedup',
        (tester) async {
      final firestore = _FakeFirestore()..seedChildren(parentId, [singleChild]);
      await pumpAndOpenSheet(tester, firestore: firestore);

      Future<void> fillAndSave() async {
        await tester.enterText(
          find.byKey(CreateCustomTaskSheet.titleFieldKey),
          'Đọc sách mỗi tối',
        );
        await pumpSteps(tester);
        await tester.tap(find.byKey(CreateCustomTaskSheet.categoryDropdownKey));
        await pumpSteps(tester);
        await tester.tap(find.text('Học tập').last);
        await pumpSteps(tester);
        await tester.tap(find.byKey(CreateCustomTaskSheet.saveButtonKey));
        await pumpSteps(tester);
      }

      await fillAndSave();
      expect(find.byKey(CreateCustomTaskSheet.titleFieldKey), findsNothing,
          reason: 'first sheet must have closed before reopening');

      // Reopen the sheet for the second create.
      await tester.tap(find.text('Open'));
      await pumpSteps(tester);
      await fillAndSave();

      final snap =
          await firestore.collection(FirestorePaths.customTasks(parentId)).get();
      expect(snap.docs, hasLength(2));
      expect(snap.docs.every((d) => d.data()['title'] == 'Đọc sách mỗi tối'), isTrue);
    });
  });

  group('AC — Save error state', () {
    testWidgets(
        'test_CreateCustomTaskSheet_writeFails_showsInlineError_sheetStaysOpen_saveReEnabled',
        (tester) async {
      final firestore = _FakeFirestore()
        ..seedChildren(parentId, [singleChild])
        ..failNextWrite = true;
      await pumpAndOpenSheet(tester, firestore: firestore);

      await tester.enterText(
        find.byKey(CreateCustomTaskSheet.titleFieldKey),
        'Đọc sách mỗi tối',
      );
      await pumpSteps(tester);
      await tester.tap(find.byKey(CreateCustomTaskSheet.categoryDropdownKey));
      await pumpSteps(tester);
      await tester.tap(find.text('Học tập').last);
      await pumpSteps(tester);

      await tester.tap(find.byKey(CreateCustomTaskSheet.saveButtonKey));
      await pumpSteps(tester);

      expect(find.text('Không thêm được nhiệm vụ — thử lại'), findsOneWidget);
      expect(find.byKey(CreateCustomTaskSheet.titleFieldKey), findsOneWidget,
          reason: 'sheet must NOT auto-close on failure');

      final button = tester.widget<FilledButton>(
        find.byKey(CreateCustomTaskSheet.saveButtonKey),
      );
      expect(button.onPressed, isNotNull, reason: 'Save must re-enable after failure');

      final snap =
          await firestore.collection(FirestorePaths.customTasks(parentId)).get();
      expect(snap.docs, isEmpty, reason: 'a failed write must not land any document');
    });
  });
}
