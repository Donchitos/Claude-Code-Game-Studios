// Run with:
//   cd src && flutter test ../tests/unit/item_database/item_catalog_provider_test.dart
//
// Hand-rolled minimal Firestore fake, same established pattern as
// pin_verification_test.dart / energy_provider_test.dart (fake_cloud_firestore
// is incompatible with cloud_firestore ^6.7.1).

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/firebase_providers.dart';
import 'package:pet_quest/core/firestore_paths.dart';
import 'package:pet_quest/core/models/item_model.dart';
import 'package:pet_quest/providers/item_catalog_provider.dart';

class _FakeQueryDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDocumentSnapshot(this._data);
  final Map<String, dynamic> _data;

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

class _CallCounter {
  int getCalls = 0;
}

class _FakeCollectionReference
    implements CollectionReference<Map<String, dynamic>> {
  _FakeCollectionReference(this._docs, this._counter);

  final List<Map<String, dynamic>> _docs;
  final _CallCounter _counter;
  String? _orderByField;

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    _orderByField = field as String;
    return this;
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    _counter.getCalls++;
    final sorted = [..._docs];
    if (_orderByField != null) {
      sorted.sort(
        (a, b) =>
            (a[_orderByField] as num).compareTo(b[_orderByField] as num),
      );
    }
    return _FakeQuerySnapshot(
      sorted.map(_FakeQueryDocumentSnapshot.new).toList(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  _FakeFirestore(this._docs, {_CallCounter? counter})
      : _counter = counter ?? _CallCounter();

  final List<Map<String, dynamic>> _docs;
  final _CallCounter _counter;

  int get getCalls => _counter.getCalls;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    if (path != FirestorePaths.items) {
      throw ArgumentError('Unexpected collection path in test fake: $path');
    }
    return _FakeCollectionReference(_docs, _counter);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingCollectionReference
    implements CollectionReference<Map<String, dynamic>> {
  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) =>
      this;

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'test-injected failure',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingFirestore implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _ThrowingCollectionReference();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _item({
  required String itemId,
  required int sortOrder,
}) {
  return {
    'itemId': itemId,
    'name': 'Item $itemId',
    'description': 'desc',
    'category': 'mochi_outfit',
    'slot': 'hat',
    'price': 10,
    'source': 'shop',
    'assetId': 'asset-$itemId',
    'sortOrder': sortOrder,
  };
}

void main() {
  test(
      'test_itemCatalogProvider_returns_30_ItemModel_ordered_by_sortOrder_given_30_seeded_documents',
      () async {
    // Shuffled sortOrder values (not pre-sorted in the fake's own storage
    // order) to prove the provider's own .orderBy('sortOrder') is doing the
    // sorting, not an accident of insertion order.
    final docs = [
      for (var i = 0; i < 30; i++)
        _item(itemId: 'item-$i', sortOrder: 29 - i),
    ];
    final firestore = _FakeFirestore(docs);
    final container = ProviderContainer(
      overrides: [firebaseFirestoreProvider.overrideWithValue(firestore)],
    );
    addTearDown(container.dispose);

    final items = await container.read(itemCatalogProvider.future);

    expect(items, hasLength(30));
    for (var i = 0; i < items.length - 1; i++) {
      expect(items[i].sortOrder, lessThan(items[i + 1].sortOrder));
    }
  });

  test('test_itemCatalogProvider_resolves_to_an_empty_list_for_an_empty_collection',
      () async {
    final firestore = _FakeFirestore([]);
    final container = ProviderContainer(
      overrides: [firebaseFirestoreProvider.overrideWithValue(firestore)],
    );
    addTearDown(container.dispose);

    final items = await container.read(itemCatalogProvider.future);

    expect(items, isEmpty);
  });

  test(
      'test_itemCatalogProvider_is_not_autoDispose_cached_value_survives_across_multiple_reads',
      () async {
    final firestore = _FakeFirestore([_item(itemId: 'a', sortOrder: 0)]);
    final container = ProviderContainer(
      overrides: [firebaseFirestoreProvider.overrideWithValue(firestore)],
    );
    addTearDown(container.dispose);

    await container.read(itemCatalogProvider.future);
    // Subscribe/unsubscribe a listener (simulating a widget rebuild) then
    // read again — an .autoDispose provider would have been torn down and
    // re-fetched here.
    final sub = container.listen(itemCatalogProvider, (_, __) {});
    sub.close();
    await container.read(itemCatalogProvider.future);
    await container.read(itemCatalogProvider.future);

    expect(firestore.getCalls, 1);
  });

  test(
      'test_itemCatalogProvider_surfaces_a_query_failure_as_AsyncError_not_an_empty_list',
      () async {
    // Distinguishes "empty because no data" from "the query itself failed" —
    // a query exception must not be silently swallowed into an empty list.
    final container = ProviderContainer(
      overrides: [
        firebaseFirestoreProvider.overrideWithValue(_ThrowingFirestore()),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(itemCatalogProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final result = container.read(itemCatalogProvider);
    expect(result.hasError, isTrue);
    expect(result.error, isA<FirebaseException>());
  });

  test('test_lookupById_returns_the_matching_ItemModel_for_a_known_id', () {
    final items = [
      const ItemModel(
        itemId: 'wizard-hat',
        name: 'Mũ Phù Thủy',
        description: 'd',
        category: 'mochi_outfit',
        slot: 'hat',
        price: 60,
        source: 'shop',
        assetId: 'a',
        sortOrder: 0,
      ),
    ];

    expect(items.lookupById('wizard-hat'), items.first);
  });

  test('test_lookupById_returns_null_for_an_unknown_id_not_a_thrown_exception',
      () {
    final items = <ItemModel>[];

    expect(items.lookupById('nonexistent-item'), isNull);
  });

  test('test_no_snapshots_call_exists_anywhere_in_the_providers_source', () {
    final source =
        File('lib/providers/item_catalog_provider.dart').readAsStringSync();

    expect(source.contains('.snapshots()'), isFalse);
  });
}
