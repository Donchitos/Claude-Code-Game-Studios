import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/firebase_providers.dart';
import '../core/parent_approval_repository.dart';

/// [ParentApprovalRepository] instance (Parent Dashboard UI Story 001,
/// TR-parentdash-001) — same constructor-injected-Firestore shape as
/// [customTaskRepositoryProvider] (`task_providers.dart`) /
/// [childProfileRepositoryProvider] (`auth_providers.dart`). Lives in its own
/// file rather than either of those, because `ParentApprovalRepository` is a
/// Parent Approval (#11) type (ADR-0013), a distinct domain from Task
/// Library's `task_providers.dart` or Auth & Account's `auth_providers.dart`
/// — matching the same one-domain-per-provider-file convention
/// `customTaskRepositoryProvider`'s own doc comment states. This is the
/// FIRST Riverpod provider anywhere in the codebase wrapping
/// [ParentApprovalRepository]: ADR-0013 built the repository as a plain,
/// constructor-injectable class and deliberately left the provider wiring to
/// "a future Parent Dashboard `ConsumerWidget`" (ADR-0013 §1/§2) — this
/// story is that widget.
final parentApprovalRepositoryProvider =
    Provider<ParentApprovalRepository>((ref) {
  return ParentApprovalRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

/// [Connectivity] instance (`connectivity_plus` 7.3.0), constructor-injected
/// via a `Provider` for the same DI-over-singleton testability reason as
/// [firebaseFirestoreProvider] et al. (`firebase_providers.dart`) — a test
/// can override this with a fake `implements Connectivity` the same way this
/// codebase's existing fakes already `implements FirebaseFirestore`/
/// `implements User` elsewhere (Dart's implicit-interfaces feature lets a
/// fake satisfy a concrete class's public interface without needing to
/// invoke its constructor).
///
/// **Post-cutoff API note** (Story 001 Implementation Note 9 / GDD Core Rule
/// 2): `connectivity_plus` was added to `pubspec.yaml` today at ^7.3.0 — its
/// API is past this project's LLM training cutoff
/// (`docs/engine-reference/flutter-flame/VERSION.md`), so its shape was
/// verified directly against the INSTALLED package source (pub-cache path:
/// `connectivity_plus-7.3.0/lib/connectivity_plus.dart`, 2026-07-22) rather
/// than assumed from memory. The verified shape: `Connectivity()` is a
/// factory singleton exposing `checkConnectivity()` (returns a `Future` of a
/// `ConnectivityResult` list) and `onConnectivityChanged` (a `Stream` of the
/// same) — NOT the pre-v6 single-`ConnectivityResult` shape an older
/// training cutoff would suggest. The package's own doc comments on
/// both members state the returned/emitted list is NEVER empty and
/// [ConnectivityResult.none] is the ONLY value ever present ALONE (i.e. if
/// the list contains `none`, that is the list's sole element) — this is what
/// makes [isDeviceOffline]'s `contains(none)` check equivalent to an exact
/// `[none]` match without needing a separate length check.
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

/// `true` iff [connectivity]'s CURRENT radio status reports no connectivity
/// at all (see [connectivityProvider]'s doc comment for the verified
/// `contains(none)` equivalence). A one-shot check via `checkConnectivity()`,
/// NOT a reactively-watched `onConnectivityChanged` stream — Story 001
/// Implementation Note 9 frames this as a tap-time PRE-CHECK layered in
/// front of Parent Approval's own unified error handling (ADR-0013 §5), not
/// a continuously-driven UI affordance that proactively disables buttons
/// ahead of a tap. `approveTask()`/`rejectTask()`'s own unified error path —
/// not this pre-check — is what actually protects correctness if
/// connectivity flaps between this check and the real write (ADR-0013
/// Constraints: "a client-side offline pre-check ... is a UX optimization,
/// not the actual safety mechanism").
Future<bool> isDeviceOffline(Connectivity connectivity) async {
  final results = await connectivity.checkConnectivity();
  return results.contains(ConnectivityResult.none);
}
