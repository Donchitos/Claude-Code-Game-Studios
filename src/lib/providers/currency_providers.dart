import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/firebase_providers.dart';
import '../core/firestore_paths.dart';
import 'auth_providers.dart';

/// Mochi's owner's realtime xu balance (ADR-0008 Decision §4) — the ONLY
/// piece of Currency System this codebase can build yet: ADR-0008's own Key
/// Interfaces section states there is no Currency-owned mutation method.
/// Balance changes happen inside the earning/spending systems' own atomic
/// operations (Parent Approval, Gacha, Shop) — none of which exist as
/// epics yet. This provider is read-only.
///
/// Scoped to the active child + signed-in parent. Resolves to `0` (not an
/// error, not a hang) when either is absent — e.g. between screens, or
/// signed out. A negative stored value (bug/rule-bypass scenario, ADR-0008
/// Decision §5) is clamped to `0` here — never surfaced to consumers.
///
/// Deliberately NOT `.autoDispose`: the wallet is always visible, so one
/// shared session-lifetime listener is correct — an `.autoDispose` variant
/// would tear down and resubscribe every time the last watching widget
/// unmounts (e.g. into a full-screen ceremony), causing needless listener
/// churn (ADR-0008 Decision §4).
final xuBalanceProvider = StreamProvider<int>(
  (ref) {
    final childId = ref.watch(activeChildProvider)?.childId;
    final parentId = ref.watch(authStateProvider).value?.uid;
    if (childId == null || parentId == null) return Stream.value(0);

    return ref
        .watch(firebaseFirestoreProvider)
        .doc(FirestorePaths.child(parentId, childId))
        .snapshots()
        .map((doc) {
      final raw = (doc.data()?['xuBalance'] as num?)?.toInt() ?? 0;
      return raw < 0 ? 0 : raw;
    });
  },
  // `retry: (retryCount, error) => null` disables riverpod 3.3.2's
  // `ProviderContainer.defaultRetry`, which silently retries any provider
  // whose build/stream throws a plain `Exception` (this includes
  // `FirebaseException`, e.g. a real `permission-denied` snapshot error) up
  // to 10 times over ~38s. **Corrected in code review** (verified directly
  // against installed `riverpod-3.3.2` source,
  // `element.dart:758-789`/`async_value.dart:125`): `AsyncValue.hasError`
  // flips `true` IMMEDIATELY on the first failure, even mid-retry — so
  // `XuChip`, which reads `.hasError`/`.value` directly (not `.when()`),
  // was never actually blocked for 38s; that framing was wrong. The real,
  // narrower justifications for keeping this fix: (1) it matches the
  // established codebase convention already applied to `childProfilesProvider`
  // (`auth_providers.dart`) and `itemCatalogProvider`
  // (`item_catalog_provider.dart`) — control-manifest.md's 2026-07-16
  // Required Pattern flags this as applying to EVERY `StreamProvider`/
  // `FutureProvider`, "other existing declarations still have not been fully
  // audited"; (2) it avoids leaving a background retry `Timer` running with
  // no purpose against a persistent (non-transient) failure — the actual
  // test failure that surfaced this (`chip_cluster_test.dart`'s AC-7 test)
  // was a leftover pending `Timer` after teardown, not a stuck-loading
  // widget; (3) it protects any FUTURE `.when()`-based consumer of this
  // provider, where the `isLoading`-before-`error` behavior genuinely would
  // apply.
  retry: (retryCount, error) => null,
);
