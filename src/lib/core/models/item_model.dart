import 'package:cloud_firestore/cloud_firestore.dart';

/// A single `items/{itemId}` catalog entry (ADR-0006 Key Interfaces) — the
/// full schema from `design/gdd/item-database.md` Core Rules §1. Pure data;
/// no rarity tier (differentiation is [price] + [source] only).
class ItemModel {
  const ItemModel({
    required this.itemId,
    required this.name,
    required this.description,
    required this.category,
    required this.slot,
    required this.price,
    required this.source,
    required this.assetId,
    required this.sortOrder,
  });

  final String itemId;
  final String name;
  final String description;

  /// `'mochi_outfit' | 'room_decoration' | 'special'`.
  final String category;

  /// `'body_outfit' | 'hat' | 'accessory' | null` — null for room
  /// decorations and special (inventory-only) items.
  final String? slot;

  final int price;

  /// `'shop' | 'gacha' | 'both'` — acquisition location only, NOT a
  /// visibility flag (ADR-0006 Decision §5). Filtering by this field is
  /// Shop/Gacha's concern, not modeled here.
  final String source;

  final String assetId;
  final int sortOrder;

  /// Parses a single catalog document. Takes a
  /// `QueryDocumentSnapshot<Map<String, dynamic>>` (what `.get()`'s
  /// `snap.docs` yields), not a plain `DocumentSnapshot` — its `.data()` is
  /// guaranteed non-null (ADR-0006 Key Interfaces).
  ///
  /// `slot` uses `as String?` (not `as String`): 12 of 30 MVP items
  /// (`room_decoration` + `special`) store `slot: null`; a non-nullable
  /// cast would throw on ~40% of the catalog. `price`/`sortOrder` use
  /// `(x as num).toInt()` (not `as int`): Firestore's wire format doesn't
  /// reliably preserve int-vs-double, so an admin-entered `10.0` would
  /// crash an `as int` cast.
  factory ItemModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ItemModel(
      itemId: data['itemId'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      category: data['category'] as String,
      slot: data['slot'] as String?,
      price: (data['price'] as num).toInt(),
      source: data['source'] as String,
      assetId: data['assetId'] as String,
      sortOrder: (data['sortOrder'] as num).toInt(),
    );
  }
}
