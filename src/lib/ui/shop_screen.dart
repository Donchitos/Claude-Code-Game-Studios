import 'package:flutter/material.dart';

/// Child Shell's Shop tab (main-navigation-shell Story 002, ADR-0014
/// Decision §2) — a bare placeholder `Scaffold`, same shape as the
/// pre-existing `_PlaceholderScreen` pattern in `router_provider.dart`. Real
/// content belongs to Shop & Reward UI (#20), an epic that doesn't exist yet
/// (this story's Out of Scope note).
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Shop')));
  }
}
