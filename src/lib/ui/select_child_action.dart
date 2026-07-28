import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/router_provider.dart';

/// The "Chọn bé" app bar action (GDD Core Rule 5 / UX spec
/// `design/ux/parent-dashboard-ui.md` Component Inventory) — shared verbatim
/// by BOTH Parent Shell tabs: `ParentDashboardTasksTab` (Parent Dashboard UI
/// Story 001, this epic's canonical owner per Story 003's own doc comment:
/// "giống Tab Nhiệm vụ... Core Rule 5, same implementation as Story 001 — do
/// not reimplement") and `ParentDashboardFamilyTab` (Story 003, which built
/// its own local, provisional copy only because Story 001 hadn't landed
/// yet).
///
/// This is the absorption: `ParentDashboardFamilyTab` has been refactored to
/// use this shared widget instead of its own local `TextButton.icon` —
/// collapsing exactly the tech debt Story 003's own doc comment flagged.
/// Same precedent as `ParentOverrideTrigger`'s absorption into `ProfileChip`
/// (main-navigation-shell epic) — see `chip_cluster_test.dart`'s
/// "ParentOverrideTrigger absorption sanity" group for the shape of a test
/// that proves genuine sharing, not two look-alike implementations.
class SelectChildAction extends StatelessWidget {
  const SelectChildAction({super.key});

  /// Applied directly to the tappable [TextButton.icon] itself (not merely
  /// to this wrapper widget), so `find.byKey`/`tester.tap` resolve to the
  /// same real hit-testable control regardless of which tab embeds this
  /// widget.
  static const actionKey = Key('selectChildAction');

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: actionKey,
      onPressed: () => context.push(AppRoutes.selectChild),
      icon: const Icon(Icons.switch_account_outlined),
      label: const Text('Chọn bé'),
    );
  }
}
