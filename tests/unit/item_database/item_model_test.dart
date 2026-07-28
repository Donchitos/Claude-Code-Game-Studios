// Run with:
//   cd src && flutter test ../tests/unit/item_database/item_model_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/models/item_model.dart';

class _FakeQueryDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDocumentSnapshot(this._data);
  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _mochiOutfitData({
  String itemId = 'wizard-hat',
  String slot = 'hat',
  Object price = 60,
  Object sortOrder = 5,
  String source = 'shop',
}) {
  return {
    'itemId': itemId,
    'name': 'Mũ Phù Thủy',
    'description': 'Huyền bí và đáng yêu',
    'category': 'mochi_outfit',
    'slot': slot,
    'price': price,
    'source': source,
    'assetId': 'asset-wizard-hat',
    'sortOrder': sortOrder,
  };
}

void main() {
  test('test_fromFirestore_parses_a_complete_mochi_outfit_item_correctly',
      () {
    final doc = _FakeQueryDocumentSnapshot(_mochiOutfitData());

    final item = ItemModel.fromFirestore(doc);

    expect(item.itemId, 'wizard-hat');
    expect(item.name, 'Mũ Phù Thủy');
    expect(item.description, 'Huyền bí và đáng yêu');
    expect(item.category, 'mochi_outfit');
    expect(item.slot, 'hat');
    expect(item.price, 60);
    expect(item.source, 'shop');
    expect(item.assetId, 'asset-wizard-hat');
    expect(item.sortOrder, 5);
  });

  test('test_fromFirestore_does_not_throw_on_a_document_with_slot_null', () {
    final data = {
      'itemId': 'cozy-rug',
      'name': 'Thảm Ấm Áp',
      'description': 'Một chiếc thảm êm ái',
      'category': 'room_decoration',
      'slot': null,
      'price': 30,
      'source': 'shop',
      'assetId': 'asset-cozy-rug',
      'sortOrder': 20,
    };
    final doc = _FakeQueryDocumentSnapshot(data);

    final item = ItemModel.fromFirestore(doc);

    expect(item.slot, isNull);
  });

  test('test_fromFirestore_does_not_throw_when_price_is_stored_as_a_double',
      () {
    final doc = _FakeQueryDocumentSnapshot(_mochiOutfitData(price: 10.0));

    final item = ItemModel.fromFirestore(doc);

    expect(item.price, 10);
    expect(item.price, isA<int>());
  });

  test(
      'test_fromFirestore_does_not_throw_when_sortOrder_is_stored_as_a_double',
      () {
    final doc = _FakeQueryDocumentSnapshot(_mochiOutfitData(sortOrder: 5.0));

    final item = ItemModel.fromFirestore(doc);

    expect(item.sortOrder, 5);
    expect(item.sortOrder, isA<int>());
  });

  test(
      'test_parsing_the_real_mvp_30_item_shape_succeeds_with_zero_exceptions',
      () {
    // GDD category distribution: 18 mochi_outfit (non-null slot) + 10
    // room_decoration + 2 special (both slot: null) = 12/30 null-slot items.
    final docs = <_FakeQueryDocumentSnapshot>[
      for (var i = 0; i < 18; i++)
        _FakeQueryDocumentSnapshot({
          'itemId': 'outfit-$i',
          'name': 'Outfit $i',
          'description': 'desc',
          'category': 'mochi_outfit',
          'slot': i % 3 == 0
              ? 'body_outfit'
              : i % 3 == 1
                  ? 'hat'
                  : 'accessory',
          'price': 10 + i,
          'source': 'shop',
          'assetId': 'asset-outfit-$i',
          'sortOrder': i,
        }),
      for (var i = 0; i < 10; i++)
        _FakeQueryDocumentSnapshot({
          'itemId': 'room-$i',
          'name': 'Room Item $i',
          'description': 'desc',
          'category': 'room_decoration',
          'slot': null,
          'price': 30 + i,
          'source': 'shop',
          'assetId': 'asset-room-$i',
          'sortOrder': 18 + i,
        }),
      for (var i = 0; i < 2; i++)
        _FakeQueryDocumentSnapshot({
          'itemId': 'special-$i',
          'name': 'Special $i',
          'description': 'desc',
          'category': 'special',
          'slot': null,
          'price': 200,
          'source': 'gacha',
          'assetId': 'asset-special-$i',
          'sortOrder': 28 + i,
        }),
    ];

    final items = docs.map(ItemModel.fromFirestore).toList();

    expect(items, hasLength(30));
    expect(items.where((i) => i.slot == null), hasLength(12));
    expect(items.where((i) => i.slot != null), hasLength(18));
  });

  test('test_source_field_is_stored_verbatim_not_filtered_or_interpreted',
      () {
    final shopItem =
        ItemModel.fromFirestore(_FakeQueryDocumentSnapshot(
            _mochiOutfitData(itemId: 'a', source: 'shop')));
    final gachaItem =
        ItemModel.fromFirestore(_FakeQueryDocumentSnapshot(
            _mochiOutfitData(itemId: 'b', source: 'gacha')));
    final bothItem =
        ItemModel.fromFirestore(_FakeQueryDocumentSnapshot(
            _mochiOutfitData(itemId: 'c', source: 'both')));

    expect(shopItem.source, 'shop');
    expect(gachaItem.source, 'gacha');
    expect(bothItem.source, 'both');
  });

  test(
      'test_fromFirestore_throws_TypeError_on_document_missing_a_required_field',
      () {
    // A required field entirely ABSENT from the document (not explicitly
    // null, just missing) is a loud crash (TypeError), not a silent wrong
    // value — the accepted, documented failure mode for malformed seed
    // data (the ADR discusses null slot/price-type defensively, but not
    // missing-field entirely; this test proves the current behavior is a
    // clear crash, not silent corruption).
    final data = _mochiOutfitData()..remove('itemId');
    final doc = _FakeQueryDocumentSnapshot(data);

    expect(() => ItemModel.fromFirestore(doc), throwsA(isA<TypeError>()));
  });
}
