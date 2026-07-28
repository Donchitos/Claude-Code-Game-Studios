import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/compute_energy.dart';
import '../core/firebase_providers.dart';
import '../core/firestore_paths.dart';
import 'auth_providers.dart';

/// Incremented once per app-resume (ADR-0005 Key Interfaces) — the only
/// lifecycle event [energyProvider] recomputes on (never pause/inactive).
/// Ticked by [appLifecycleListenerProvider].
final resumeTickProvider = StateProvider<int>((ref) => 0);

/// Constructs a single `AppLifecycleListener` for the app's lifetime, ticking
/// [resumeTickProvider] on `onResume` only — never `onPause`/`onInactive`
/// (ADR-0005 Key Interfaces: "Only onResume ticks the resume provider").
/// Same "side-effecting `Provider<void>`, kept alive via `ref.watch` at app
/// root" pattern as [fcmTokenRefreshListenerProvider] in `auth_providers.dart`
/// — constructed once, disposed via `ref.onDispose`, never per-screen.
final appLifecycleListenerProvider = Provider<void>((ref) {
  final listener = AppLifecycleListener(
    onResume: () => ref.read(resumeTickProvider.notifier).state++,
  );
  ref.onDispose(listener.dispose);
});

/// The 3 fields this system needs from `children/{childId}`, read directly
/// rather than by extending `ChildProfile` (which deliberately excludes
/// economy fields — see that model's own doc comment). Private: not a
/// public model competing with `ChildProfile`.
class _EnergyDoc {
  const _EnergyDoc({
    required this.storedEnergy,
    required this.lastApprovedAt,
    required this.createdAt,
  });

  final double storedEnergy;
  final DateTime? lastApprovedAt;
  final DateTime createdAt;
}

/// Realtime stream of the active child's energy-relevant fields, scoped to
/// `activeChildProvider` + the signed-in parent — the established
/// active-child-economy-field pattern (ADR-0003: `snapshots()`, not `get()`).
/// Resolves to `null` while no child is active (between screens) rather
/// than throwing.
///
/// `retry: (_, _) => null` disables Riverpod's default automatic
/// retry-with-backoff on a stream error — found necessary, not cosmetic,
/// while wiring Pet Room Screen UI Story 006's status row into production
/// (the first real consumer of [energyProvider] besides tests): a genuine
/// Firestore stream error here (e.g. a permission-denied security-rule
/// violation) will not resolve itself by blindly retrying, and the
/// automatically-scheduled retry `Timer` was found to outlive a widget
/// tree's disposal in a real test (`flutter_test`'s "Timer is still pending
/// even after the widget tree was disposed" assertion) — a real leak, not
/// just a test-teardown nuisance, since the same unresolvable-retry-loop
/// would run in the production app too. On error, [energyProvider] below
/// keeps returning whatever it last computed from the most recent
/// successfully-received doc (Riverpod's `AsyncError` preserves the prior
/// `.value` via `copyWithPrevious` — verified against the installed
/// riverpod 3.3.2 source), not `0.0`; `0.0` is only ever seen when no
/// doc — success or error — has arrived yet (`doc == null` below). This is
/// the more resilient behavior (stale-but-known energy survives a
/// transient error instead of visibly flashing to empty), so disabling the
/// retry only removes the redundant, resource-wasting `Timer` — it does
/// not change what the UI displays either way.
final _activeChildEnergyDocProvider = StreamProvider<_EnergyDoc?>((ref) {
  final user = ref.watch(authStateProvider).value;
  final child = ref.watch(activeChildProvider);
  if (user == null || child == null) {
    return Stream.value(null);
  }
  final path = FirestorePaths.child(user.uid, child.childId);
  return ref.watch(firebaseFirestoreProvider).doc(path).snapshots().map((snapshot) {
    final data = snapshot.data();
    if (data == null) return null;
    // Missing storedEnergy (a profile whose economy fields were never
    // initialized — no "create child profile" story exists yet to
    // guarantee this) falls back to initialEnergy=70, the same fallback
    // computeEnergy itself applies for a null lastApprovedAt, rather than
    // crashing on an unsafe cast.
    final storedEnergy = (data['storedEnergy'] as num?)?.toDouble() ?? 70.0;
    final lastApprovedAt = (data['lastApprovedAt'] as Timestamp?)?.toDate();
    // createdAt is a required field per ADR-0003's schema and should never
    // actually be absent; DateTime.now() here is a defensive fallback only,
    // not a documented behavior — same nullable-cast-then-fallback style as
    // storedEnergy above.
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return _EnergyDoc(
      storedEnergy: storedEnergy,
      lastApprovedAt: lastApprovedAt,
      createdAt: createdAt,
    );
  });
}, retry: (retryCount, error) => null);

/// Mochi's current energy (ADR-0005 Key Interfaces), recomputed whenever
/// [resumeTickProvider] ticks (app foreground) or the active child's energy
/// doc changes. Read + calculate only — this provider performs zero
/// Firestore writes. Returns `0.0` both when no child is active AND during
/// the brief window before the active child's first Firestore snapshot
/// arrives (ADR-0005 sanctions "a sane default while loading") — these two
/// cases are intentionally not distinguished here; callers that need to tell
/// "not loaded yet" apart from "no child" should check `activeChildProvider`
/// directly rather than inferring it from this value.
final energyProvider = Provider<double>((ref) {
  ref.watch(resumeTickProvider);
  final doc = ref.watch(_activeChildEnergyDocProvider).value;
  if (doc == null) return 0.0;
  return computeEnergy(
    storedEnergy: doc.storedEnergy,
    lastApprovedAt: doc.lastApprovedAt,
    createdAt: doc.createdAt,
    now: DateTime.now(),
  );
});
