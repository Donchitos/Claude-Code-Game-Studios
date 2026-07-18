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
});

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
