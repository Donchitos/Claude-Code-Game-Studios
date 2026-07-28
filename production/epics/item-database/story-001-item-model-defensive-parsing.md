# Story 001: ItemModel + Defensive Firestore Parsing

> **Epic**: Item Database
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/item-database.md`
**Requirement**: `TR-item-database-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Item Catalog Data Access Pattern, Key Interfaces (`ItemModel`, `fromFirestore` parsing rules)

**Engine**: Dart / `cloud_firestore ^6.7.1` | **Risk**: LOW — a data model + parsing factory, no realtime/offline-transaction complexity. The ADR's own "implementation landmines" are well-documented and mechanical to apply correctly.

**Control Manifest Rules (this layer)**:
- Required: "Type the factory param as `QueryDocumentSnapshot<Map<String, dynamic>>` (guaranteed non-null `.data()`)" — source: ADR-0006
- Required: "`slot` MUST parse as `data['slot'] as String?`, NOT `as String` (12/30 MVP items store `slot: null`)" — source: ADR-0006
- Required: "`price`/`sortOrder` MUST parse as `(data['price'] as num).toInt()`, NOT `as int`" — source: ADR-0006
- Required: "`source` field is acquisition-location only, not a visibility flag; filtering is Shop/Gacha's concern" — source: ADR-0006 (this story stores the field faithfully, does not filter)
- Forbidden: "No rarity system on items — differentiation is price + source only" — source: ADR-0006

---

## Acceptance Criteria

*From `design/gdd/item-database.md`'s Core Rules §1 (Item Schema) and ADR-0006 Key Interfaces:*

- [x] `ItemModel` has exactly these fields, matching the ADR's Key Interfaces: `itemId, name, description, category, slot, price, source, assetId, sortOrder`.
- [x] `category` is one of `'mochi_outfit' | 'room_decoration' | 'special'` (stored as the raw String — an enum is optional but the 3 documented values must round-trip correctly).
- [x] `slot` is nullable (`String?`) — parses correctly for both a present slot value (`'body_outfit'`, `'hat'`, `'accessory'`) and a genuinely absent/null value (room decorations, special items).
- [x] `ItemModel.fromFirestore` accepts a `QueryDocumentSnapshot<Map<String, dynamic>>` (not `DocumentSnapshot`) — matching what `snap.docs` yields from a `.get()` query, whose `.data()` is guaranteed non-null.
- [x] `slot` parses via `data['slot'] as String?` — does NOT throw on a document where `slot` is Firestore `null`.
- [x] `price` and `sortOrder` both parse via `(data[...] as num).toInt()` — does NOT throw whether the underlying Firestore value is stored as an int or a double (e.g. an admin-entered `10.0`).
- [x] Parsing the real MVP 30-item shape (18 `mochi_outfit` with a slot, 10 `room_decoration` + 2 `special` with `slot: null` — 12/30 null-slot items total, per the GDD's own category counts) succeeds with zero exceptions.
- [x] `source` is stored verbatim as one of `'shop' | 'gacha' | 'both'` — this story does not filter or interpret it; that is explicitly Shop/Gacha's concern per ADR-0006 Decision §5.

---

## Implementation Notes

*From ADR-0006 Key Interfaces and its explicitly-flagged "implementation landmines":*

```dart
// ItemModel: itemId, name, description,
//   category('mochi_outfit'|'room_decoration'|'special'),
//   slot('body_outfit'|'hat'|'accessory'|null), price(int),
//   source('shop'|'gacha'|'both'), assetId, sortOrder(int).
```
- `fromFirestore` parsing rules (verbatim from the ADR, do not "simplify"):
  - Factory parameter type: `QueryDocumentSnapshot<Map<String, dynamic>>`.
  - `slot`: `data['slot'] as String?` — NOT `as String`. 12 of 30 MVP items (`room_decoration` + `special`) store `slot: null`; a non-nullable cast throws `TypeError` on ~40% of the catalog at load.
  - `price`/`sortOrder`: `(data['price'] as num).toInt()` / `(data['sortOrder'] as num).toInt()` — NOT `as int`. Firestore's wire format doesn't reliably preserve int-vs-double; an admin-entered `10.0` or a float-writing seed script would crash an `as int` cast.
- Follow this project's established model-file convention (see `src/lib/core/models/child_profile.dart` for the pattern of a plain immutable Dart class with a `fromFirestore` factory) — likely `src/lib/core/models/item_model.dart`.
- This story does NOT implement the Riverpod provider, the Firestore query, or the `lookupById` accessor — those are Story 002's scope. This story is the model + parsing factory only, fully unit-testable without any Firestore connection (construct fake `QueryDocumentSnapshot` instances directly, matching this project's established hand-rolled-fake pattern from `pin_verification_test.dart`).

---

## Out of Scope

- Story 002 (this epic): `itemCatalogProvider`, the `.orderBy('sortOrder').get()` query, `lookupById`, the `FirestorePaths.items` path constant, empty-catalog handling, session-caching semantics.
- Any filtering by `category`/`source`/`slot` — that's Shop (#13)/Gacha (#12)/Pet Equipment (#15)'s concern per ADR-0006 Decision §5; this story stores fields faithfully only.
- Firestore Security Rules — already deployed and reviewed (Data Persistence Layer Story 002, `firestore.rules` lines 37-41, `security-engineer`-approved).
- Any UI rendering (thumbnails, Shop grid, equip slots) — Shop UI (#20) and Pet Room Screen UI (#18)'s concern.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. Derived from ADR-0006's Validation Criteria and Key Interfaces' explicitly-flagged landmines:*

```
Test: ItemModel.fromFirestore parses a complete mochi_outfit item correctly
  Given: a QueryDocumentSnapshot with itemId='wizard-hat', name, description, category='mochi_outfit',
    slot='hat', price=60, source='shop', assetId, sortOrder=5 (all fields present, well-typed)
  When: ItemModel.fromFirestore(doc) is called
  Then: every field on the resulting ItemModel matches the input exactly

Test: fromFirestore does not throw on a document with slot: null
  Given: a QueryDocumentSnapshot representing a room_decoration item with slot=null
  When: ItemModel.fromFirestore(doc) is called
  Then: it does not throw, and the resulting ItemModel.slot is null

Test: fromFirestore does not throw when price is stored as a double
  Given: a QueryDocumentSnapshot with price=10.0 (double, not int) in the underlying Firestore data
  When: ItemModel.fromFirestore(doc) is called
  Then: it does not throw, and ItemModel.price == 10 (as an int)

Test: fromFirestore does not throw when sortOrder is stored as a double
  Given: a QueryDocumentSnapshot with sortOrder=5.0 (double)
  When: ItemModel.fromFirestore(doc) is called
  Then: it does not throw, and ItemModel.sortOrder == 5 (as an int)

Test: parsing the real MVP 30-item shape succeeds with zero exceptions
  Given: 30 QueryDocumentSnapshots matching the GDD's real category distribution (18 mochi_outfit
    with a non-null slot, 10 room_decoration + 2 special with slot: null — 12/30 null-slot total)
  When: ItemModel.fromFirestore is called on each
  Then: all 30 parse without throwing; exactly 12 have slot == null and exactly 18 have a non-null slot

Test: source field is stored verbatim, not filtered or interpreted
  Given: three QueryDocumentSnapshots with source='shop', source='gacha', source='both' respectively
  When: ItemModel.fromFirestore is called on each
  Then: each resulting ItemModel.source exactly matches its input string — no filtering applied
```

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/item_database/item_model_test.dart` — must exist and pass

**Status**: [x] Created — `tests/unit/item_database/item_model_test.dart`, 7 tests, all passing.

---

## Dependencies

- Depends on: None (pure Dart, no dependency on any other epic's code — Foundation layer, zero upstream dependencies per the GDD's own Dependencies section).
- Unlocks: Story 002 (this epic) — `itemCatalogProvider` calls `ItemModel.fromFirestore` on each queried document.

---

## Completion Notes

**Implementation**: `src/lib/core/models/item_model.dart` — plain immutable `ItemModel` class + `fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>>)` factory, matching this project's established model-file convention (`ChildProfile.fromFirestore`). Both ADR-0006-flagged landmines implemented correctly: `slot: data['slot'] as String?` (nullable) and `price`/`sortOrder` via `(data[...] as num).toInt()`.

**Tests**: `tests/unit/item_database/item_model_test.dart` — 7 tests, all passing: complete-item parse, null-slot parse, double-typed price/sortOrder parse, the real MVP 30-item shape (12/30 null-slot), source stored verbatim, and a missing-required-field test added after code review (see below) — proving a genuinely absent field crashes loudly (`TypeError`), not silently, since this is the accepted failure mode for malformed seed data.

**Code review**: `flame-specialist` — **APPROVED**, zero required changes (reviewed jointly with Story 002). `qa-tester` — **GAPS** (one finding relevant to this story, fixed): the "missing required field" edge case (as opposed to explicitly-null) was untested — added `test_fromFirestore_throws_TypeError_on_document_missing_a_required_field`.

**Deviations from scope**: None.
**Manifest version**: 2026-07-16 (current at time of implementation — no drift).
