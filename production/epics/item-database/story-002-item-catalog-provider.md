# Story 002: itemCatalogProvider (Session-Cached Read)

> **Epic**: Item Database
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/item-database.md`
**Requirement**: `TR-item-database-002`, `TR-item-database-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Item Catalog Data Access Pattern, Decision §1 (session-cached `FutureProvider`), §3 (graceful degradation), §4 (scoped exception to the repository-path rule)

**Engine**: Flutter 3.44.4 / `cloud_firestore ^6.7.1` / `flutter_riverpod ^3.3.2` | **Risk**: LOW — a one-time Firestore `get()` + a Riverpod `FutureProvider` are stable, pre-cutoff patterns (per ADR-0006's own Knowledge Risk rating). The `itemCatalogProvider` pattern itself is already an established precedent in this codebase (`childProfilesProvider`, auth-account Story 005, uses the identical one-shot `get()`/`FutureProvider` shape).

**Control Manifest Rules (this layer)**:
- Required: "Catalog is a global `items/{itemId}` top-level collection, NOT scoped under `families/{parentId}`" — source: ADR-0006
- Required: "Fetch once per session via `.orderBy('sortOrder').get()`, cached in `itemCatalogProvider` (`FutureProvider<List<ItemModel>>`)" — source: ADR-0006
- Required: "`itemCatalogProvider` must NOT be `.autoDispose`" — source: ADR-0006
- Required: "Catalog path constant lives in centralized path constants" — source: ADR-0006
- Required: "Read served by `itemCatalogProvider`'s cached `get()`, not `PersistenceRepository` mutation methods (scoped exception to ADR-0003's repository rule)" — source: ADR-0006
- Required: "Empty catalog → provider returns `[]`; consumers render empty state, never crash" — source: ADR-0006
- Required: "Post-load missing-item lookup returns null → consumer renders placeholder, may re-fetch" — source: ADR-0006
- Forbidden: "Never use a realtime `snapshots()` listener on the item catalog" — source: ADR-0006
- Forbidden: "Never bundle the catalog as a local app asset (JSON)" — source: ADR-0006
- Forbidden: "Never read `items/` ad-hoc outside `itemCatalogProvider`" — source: ADR-0006
- Forbidden: "No rarity system on items — differentiation is price + source only" — source: ADR-0006

## Already Established (do not re-derive)

- `ItemModel`/`ItemModel.fromFirestore` already exist from Story 001 (this epic) — this story wires them to a real Firestore query, does not re-implement parsing.
- `FirestorePaths` (`src/lib/core/firestore_paths.dart`) already exists (Data Persistence Layer, Complete) — this story ADDS a new `items` constant to it, following the established centralized-path-constant convention.
- The exact "one-shot `get()`/`FutureProvider`" shape is already proven in this codebase by `childProfilesProvider` (auth-account Story 005) — reuse that established pattern rather than inventing a new one.
- Firestore Security Rules for `items/{itemId}` are ALREADY deployed and `security-engineer`-reviewed (Data Persistence Layer Story 002, `firestore.rules` lines 37-41) — this story does not touch rules.

---

## Acceptance Criteria

*From `design/gdd/item-database.md`'s Acceptance Criteria section and ADR-0006 Decision §1, §3:*

- [x] `FirestorePaths.items` is a new centralized path constant (`'items'`, a top-level collection — NOT nested under `families/{parentId}`).
- [x] `itemCatalogProvider` (`FutureProvider<List<ItemModel>>`) queries `.collection(FirestorePaths.items).orderBy('sortOrder').get()` and maps each doc through `ItemModel.fromFirestore`.
- [x] `itemCatalogProvider` is NOT `.autoDispose` — verified by inspection (no `.autoDispose` modifier) and/or a test proving the provider's cached value survives across multiple `container.read()` calls without a second Firestore query.
- [x] Given 30 seeded documents, `itemCatalogProvider` returns exactly 30 `ItemModel` objects, ordered by `sortOrder` ascending.
- [x] Given an empty `items/` collection (unseeded), `itemCatalogProvider` resolves to `[]` — does not throw, does not resolve to `null`.
- [x] A `lookupById(String itemId)` extension/accessor on `List<ItemModel>` exists: returns the matching `ItemModel` for a known id, returns `null` (not a thrown exception) for an unknown id.
- [x] The 500-item hard cap (MVP=30) is documented as a data-scale constraint in code comments — no pagination logic is implemented in this story (not needed until the catalog approaches that size); the requirement is satisfied by NOT breaking at the real MVP scale (30 items), not by building unused pagination machinery.
- [x] No `.snapshots()` call exists anywhere in this story's code — verified by inspection.

---

## Implementation Notes

*From ADR-0006 Decision §1 and Key Interfaces (the exact provider shape to implement):*

```dart
// NOT .autoDispose (see Decision §1). Default get() source is already serverAndCache.
final itemCatalogProvider = FutureProvider<List<ItemModel>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(FirestorePaths.items)   // centralized path constant (ADR-0003 intent)
      .orderBy('sortOrder')
      .get();
  return snap.docs.map(ItemModel.fromFirestore).toList();
});

// Lookup accessor for Gacha/Pet Equipment (O(1) after building a Map once).
extension ItemCatalogLookup on List<ItemModel> {
  ItemModel? lookupById(String itemId);  // null → caller renders placeholder
}
```
- The default `get()` source (`Source.serverAndCache`) already gives fresh-when-online / cache-fallback-when-offline — no `GetOptions` argument is required (per ADR-0006's own resolved Verification Required note); do not add one.
- Use `ref.watch(firebaseFirestoreProvider)` (the project's existing injectable Firestore accessor, see `time_decay_providers.dart`/`firebase_providers.dart`) rather than a bare `FirebaseFirestore.instance` static reference, matching this project's established dependency-injection convention for testability — the ADR's own code sketch uses the static reference for brevity, but this codebase's established pattern injects it.
- `lookupById`: build a `Map<String, ItemModel>` once (e.g. via `{for (final item in this) item.itemId: item}`) rather than a linear `firstWhere` scan per call — O(1) after the map is built, matching the ADR's own "(O(1) after building a Map once)" annotation. Since the extension method itself is called potentially many times (once per Gacha roll, once per equip slot lookup), avoid rebuilding the map on every single `lookupById` call if that becomes a measurable concern — for the MVP 30-item scale this is not a hard requirement, but prefer the map-based approach as the default implementation since it is no more complex to write.
- This story does not need to import `PersistenceRepository` at all — per ADR-0006 Decision §4's scoped carve-out, this read path is intentionally separate from the mutation repository.

---

## Out of Scope

- Story 001 (this epic): `ItemModel`/`fromFirestore` parsing itself — this story only wires them into a real query.
- Firestore Security Rules — already deployed (Data Persistence Layer Story 002); this story does not touch `firestore.rules`.
- Any pagination logic — not needed until the catalog approaches the 500-item cap; MVP ships 30.
- Filtering by `category`/`source`/`slot` — Shop (#13)/Gacha (#12)/Pet Equipment (#15)'s concern; this provider exposes the full, unfiltered catalog.
- Any UI (Shop grid, equip screen, Wardrobe) — future Feature/Presentation-layer epics' concern.
- Seed script for the real 30 MVP items in the actual Firebase project — a GDD-flagged Open Question with no assigned owner yet; out of scope for this story, which is tested against fake/mocked Firestore data, not the live project.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. Derived from ADR-0006's Validation Criteria and this story's own Acceptance Criteria:*

```
Test: itemCatalogProvider returns 30 ItemModel ordered by sortOrder given 30 seeded documents
  Given: a fake Firestore collection at FirestorePaths.items with 30 documents, sortOrder values
    shuffled (not pre-sorted in the fake's own storage order)
  When: itemCatalogProvider is read
  Then: resolves to exactly 30 ItemModel objects, in ascending sortOrder order

Test: itemCatalogProvider resolves to an empty list for an empty collection
  Given: a fake Firestore collection at FirestorePaths.items with zero documents
  When: itemCatalogProvider is read
  Then: resolves to [] — does not throw, does not resolve to null

Test: itemCatalogProvider is not .autoDispose — cached value survives across multiple reads
  Given: a fake Firestore that would flag/throw if queried more than once
  When: itemCatalogProvider is read multiple times from the same container (or after all
    listeners have momentarily unsubscribed and resubscribed, simulating widget rebuild)
  Then: only one underlying Firestore query is ever made; all reads return the same cached result

Test: lookupById returns the matching ItemModel for a known id
  Given: a resolved list of ItemModel including one with itemId='wizard-hat'
  When: list.lookupById('wizard-hat') is called
  Then: returns the exact matching ItemModel

Test: lookupById returns null for an unknown id, not a thrown exception
  Given: a resolved list of ItemModel not containing itemId='nonexistent-item'
  When: list.lookupById('nonexistent-item') is called
  Then: returns null — does not throw

Test: no .snapshots() call exists anywhere in the provider's source
  Given: the itemCatalogProvider implementation file's source
  When: inspected (static check)
  Then: no `.snapshots()` call appears anywhere in the file
```

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/item_database/item_catalog_provider_test.dart` — must exist and pass

**Status**: [x] Created — `tests/unit/item_database/item_catalog_provider_test.dart`, 7 tests, all passing.

---

## Dependencies

- Depends on: Story 001 (this epic) — `ItemModel`/`fromFirestore` must exist first. Also depends on Data Persistence Layer (Complete) — `FirestorePaths`, the already-deployed `items/{itemId}` Security Rule.
- Unlocks: Shop System (#13), Gacha/Loot (#12), Pet Equipment (#15), Pet Room Screen UI (#18) — all future Feature/Presentation-layer epics that read the catalog via `itemCatalogProvider`.

---

## Completion Notes

**Implementation**: `src/lib/providers/item_catalog_provider.dart` — `itemCatalogProvider` (`FutureProvider<List<ItemModel>>`, one-shot `.orderBy('sortOrder').get()`, injects `firebaseFirestoreProvider` per this project's established DI seam rather than a bare static reference) and a `lookupById` extension on `List<ItemModel>`. New `FirestorePaths.items` constant added to the existing centralized path-constants file, correctly scoped as a bare top-level path per ADR-0006 Decision §4's carve-out.

**Real production bug found and fixed, via this story's own test-writing**: `itemCatalogProvider` throws `FirebaseException` (implements `Exception`) on a query failure — this triggers riverpod 3.3.2's `ProviderContainer.defaultRetry`, which silently retries up to 10 times over ~38s before exposing a terminal `AsyncError`. This is the SAME gap already found and fixed once this session for `childProfilesProvider` (auth-account Story 011) — found again here because the query-failure test itself hung for the full ~38s retry window (exceeding the 30s default test timeout) before the fix was applied, which is what surfaced it. Fixed by adding `retry: (retryCount, error) => null`, matching the established pattern; `control-manifest.md`'s existing 2026-07-16 Required Pattern note revised to record this second occurrence and to state the rule now applies to every `FutureProvider`/`StreamProvider` in this codebase, not just ones with a known UI retry affordance. A follow-up task was flagged (not blocking this story) to audit the 3 remaining un-checked providers (`authStateProvider`, `parentProfileProvider`, `_activeChildEnergyDocProvider`).

**Tests**: `tests/unit/item_database/item_catalog_provider_test.dart` — 7 tests, all passing: 30-item ordered-by-sortOrder retrieval (using shuffled `sortOrder` values to prove the provider's own ordering, not insertion-order luck), empty-collection → `[]`, not-`.autoDispose` (a call-counter fake proving exactly one query across multiple reads/listener churn), a query-failure surfaces as `AsyncError` (added after the retry-gap discovery above — uses `container.listen` + delay rather than `container.read(provider.future)` + `expectLater(throwsA(...))`, since the latter pattern is itself what originally hung for 38s), `lookupById` known/unknown id, and a static no-`.snapshots()` source check.

**Code review**: `flame-specialist` — **APPROVED**, zero required changes (reviewed jointly with Story 001; confirmed both landmines, correct DI, correct path scoping, no anti-patterns). `qa-tester` — **GAPS** (3 findings, all fixed): (1) the 500-item-cap AC required a code comment that didn't yet exist — added; (2) the empty-catalog test didn't distinguish "empty" from "query failed" — added the query-failure test (which is also what surfaced the retry-gap bug above); (3) Story 001's missing-required-field edge case — see Story 001's own Completion Notes.

**Deviations from scope**: None.
**Manifest version**: 2026-07-16 (current at time of implementation — no drift; this story's own fix updated the manifest's dated note).
