import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/firebase_providers.dart';
import '../core/firestore_paths.dart';
import '../core/models/item_model.dart';

/// The global item catalog (ADR-0006 Decision §1) — fetched once per app
/// session via a one-shot `.get()`, cached for the session's lifetime.
/// Deliberately NOT `.autoDispose`: session-lifetime caching is the entire
/// point of this provider — an `.autoDispose` variant would silently
/// re-fetch every time the last consumer unmounts and a new one subscribes,
/// breaking the one-read-per-session cost claim. Deliberately NOT
/// `snapshots()`: the catalog is static within a session (changes only via
/// admin seed), so a realtime listener would be pure read-cost waste.
///
/// The default `get()` source (`Source.serverAndCache`) already gives
/// fresh-when-online / cache-fallback-when-offline — no `GetOptions`
/// argument is needed.
///
/// Data-scale constraint (TR-item-database-004, ADR-0006): a single
/// unpaginated `.get()` is only appropriate up to a **500-item hard cap**
/// (MVP ships 30). No pagination logic exists here — if the catalog ever
/// approaches 500 items, this provider must be revisited before adding more.
///
/// `retry: (retryCount, error) => null` disables riverpod 3.3.2's
/// `ProviderContainer.defaultRetry`, which silently retries any provider
/// whose build throws a plain `Exception` (this includes `FirebaseException`
/// — e.g. a `permission-denied` query failure) up to 10 times over ~38s
/// before ever exposing a terminal `AsyncError` — during those retries
/// `.when()` reports `isLoading: true`, not `error`, delaying the GDD's own
/// required degraded state ("Shop hiển thị 'Chưa có items' placeholder")
/// for up to 38s on a real failure. Same gap already found and fixed for
/// `childProfilesProvider` (auth-account Story 011,
/// `control-manifest.md`'s 2026-07-16 Required Pattern) — found again here
/// while writing this provider's own query-failure test, which hit the
/// retry window's ~38s duration and timed out against the test runner's
/// 30s default.
final itemCatalogProvider = FutureProvider<List<ItemModel>>(
  (ref) async {
    final snap = await ref
        .watch(firebaseFirestoreProvider)
        .collection(FirestorePaths.items)
        .orderBy('sortOrder')
        .get();
    return snap.docs.map(ItemModel.fromFirestore).toList();
  },
  retry: (retryCount, error) => null,
);

/// O(1)-after-first-call lookup by [itemId], for Gacha/Pet Equipment.
/// Returns `null` for an unknown id — callers render a placeholder rather
/// than crash (ADR-0006 Decision §3: the accepted limitation of a
/// one-time-load cache when an item is added mid-session).
extension ItemCatalogLookup on List<ItemModel> {
  ItemModel? lookupById(String itemId) {
    final byId = {for (final item in this) item.itemId: item};
    return byId[itemId];
  }
}
