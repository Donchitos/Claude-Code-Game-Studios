import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../providers/router_provider.dart';

/// Ends Parent Override and returns directly to Pet Room — the exact action
/// a future Parent Dashboard "Xong"/"Quay lại" button (Parent Dashboard UI
/// epic #21, not yet built) will invoke on tap (Implementation Note 6). Two
/// real callers exist today: [ParentShellScaffold]'s back-press `PopScope`
/// (AC-13, `parent_shell_scaffold.dart`) and this story's own test coverage,
/// which calls this function directly to simulate the not-yet-built button
/// (AC-14).
///
/// Deliberately a plain top-level function, not a `Provider`-wrapped action
/// class (unlike [ParentOverrideActions] in `auth_providers.dart`, which this
/// function calls into) — it needs both a [WidgetRef] (to reach the
/// already-tested [parentOverrideActionsProvider]) and a [BuildContext] (to
/// call `context.go`), and `BuildContext` has no place inside a Riverpod
/// provider. `.end()` (auth-account, already tested in
/// `tests/integration/auth_account/parent_override_test.dart`) flips
/// `parentOverrideProvider` back to `false` without touching
/// `activeChildProvider` — the child session was never disposed, so landing
/// directly on [AppRoutes.childPetRoom] requires no re-PIN (AC-14).
void endParentOverrideAndReturnToPetRoom(WidgetRef ref, BuildContext context) {
  ref.read(parentOverrideActionsProvider).end();
  context.go(AppRoutes.childPetRoom);
}
