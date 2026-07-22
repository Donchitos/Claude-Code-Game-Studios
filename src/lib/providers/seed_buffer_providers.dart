import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/firebase_providers.dart';
import '../core/firestore_paths.dart';
import 'auth_providers.dart';

/// The active child's realtime seed count (ADR-0012 Decision §3, Story 002
/// of the Seed Buffer epic) — the pending-task counter the Seed Badge will
/// eventually render. Read-only: the write side (+1 on submit) is Story 001
/// of this epic; the -1 decrement is contracted to Parent Approval (#11),
/// not implemented yet; drift correction (the actual document-level fix for
/// a persistent negative/incorrect value) is Story 003 of this epic. This
/// provider never corrects the underlying Firestore document — it only
/// clamps what is *displayed* (AC-4).
///
/// Scoped to the active child + signed-in parent, mirroring
/// `xuBalanceProvider` (`currency_providers.dart`, ADR-0008 Decision §4)
/// exactly: resolves to `0` (not an error, not a hang) when either is
/// absent — e.g. between screens, or signed out. A negative stored value
/// (a hypothetical double-decrement bug, per ADR-0012's own framing) is
/// clamped to `0` here — never surfaced to consumers.
///
/// Deliberately NOT `.autoDispose`: the Seed Badge is a persistent,
/// frequently-rendered UI element per the GDD's own Visual Requirements —
/// same rationale as `xuBalanceProvider`.
///
/// Corrected from ADR-0012 §3's own illustrative snippet in two ways, found
/// by checking the actually-built sibling `xuBalanceProvider` rather than
/// copying the ADR verbatim (see this story's Implementation Notes):
/// (1) `FirebaseFirestore.instance` -> `ref.watch(firebaseFirestoreProvider)`
/// — the mandatory injectable seam (`firebase_providers.dart`'s own doc
/// comment); (2) `const Stream.empty()` -> `Stream.value(0)` on the
/// null-guard — a `StreamProvider` fed `Stream.empty()` never emits, so its
/// `AsyncValue` would stay perpetually loading rather than resolving to a
/// usable default.
final seedCountProvider = StreamProvider<int>(
  (ref) {
    final childId = ref.watch(activeChildProvider)?.childId;
    final parentId = ref.watch(authStateProvider).value?.uid;
    if (parentId == null || childId == null) return Stream.value(0);

    return ref
        .watch(firebaseFirestoreProvider)
        .doc(FirestorePaths.child(parentId, childId))
        .snapshots()
        .map((doc) {
      final raw = (doc.data()?['seedCount'] as num?)?.toInt() ?? 0;
      return raw < 0 ? 0 : raw;
    });
  },
  // `retry: (retryCount, error) => null` — same fix applied to the sibling
  // `xuBalanceProvider` (`currency_providers.dart` — see that provider's own
  // doc comment for the full, code-review-corrected trace against installed
  // riverpod-3.3.2 source: `.hasError` flips immediately on first failure,
  // it does NOT stay `isLoading` for ~38s, for any consumer reading
  // `.hasError`/`.value` directly). Kept here for the same narrower reasons:
  // matches the established codebase convention (`childProfilesProvider`,
  // `itemCatalogProvider`), avoids a pointless background retry `Timer`
  // against a persistent failure, and protects any future `.when()`-based
  // consumer. Not currently exercised by a failing test in this codebase
  // (`ContextualBadgeChip` treats any error the same as `0` — hidden — so no
  // test observes a pending-`Timer` leak the way `xuBalanceProvider`'s did).
  retry: (retryCount, error) => null,
);
