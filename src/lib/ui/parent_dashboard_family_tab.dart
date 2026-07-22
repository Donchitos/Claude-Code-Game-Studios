import 'package:flutter/material.dart';

/// Parent Shell's Family tab (main-navigation-shell Story 003, ADR-0014
/// Decision §3) — a bare placeholder `Scaffold`, same shape as
/// `TaskManagementScreen`/`ShopScreen` from Story 002. Real content belongs
/// to Parent Dashboard UI (#21), an epic that is currently Blocked pending
/// this epic (this story's Out of Scope note).
///
/// Named `ParentDashboardFamilyTab` to match ADR-0014 Decision §3's own code
/// sample exactly (`parentShellRoute`'s branch builder), not an invented
/// placeholder name.
class ParentDashboardFamilyTab extends StatelessWidget {
  const ParentDashboardFamilyTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gia đình')),
      body: const Center(child: Text('Gia đình')),
    );
  }
}
