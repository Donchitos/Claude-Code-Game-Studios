import 'package:flutter/material.dart';

import 'contextual_badge_chip.dart';
import 'profile_chip.dart';
import 'xu_chip.dart';

/// The Floating Chip Cluster (main-navigation-shell Story 006; layout per
/// `design/ux/hud.md` Layout Zones) — [ProfileChip] + [XuChip] grouped in the
/// top-left corner (small visible gap, never fused into one shape) and
/// [ContextualBadgeChip] in the top-right corner.
///
/// Rendered as a `Stack` overlay above `navigationShell` inside
/// `ChildShellScaffold` (`child_shell_scaffold.dart`) — never inside
/// `StatefulShellRoute`'s `IndexedStack`-managed branch content (control
/// manifest, this story's own Forbidden rule). This widget itself is a
/// `StatelessWidget` that watches nothing — each chip is its own
/// `ConsumerWidget`/`ConsumerStatefulWidget` scoped to exactly the provider
/// it needs, so a balance/seed-count change rebuilds only that one chip, not
/// this cluster or its siblings (control manifest rebuild-scoping rule).
///
/// `SafeArea` wraps the whole cluster (both corners at once) so it never
/// renders under a notch/Dynamic Island/camera cutout — matching
/// [ParentOverrideTrigger]'s (`parent_override_trigger.dart`) prior
/// placeholder-era pattern, generalized here to cover all three chips with a
/// single `SafeArea` rather than one per chip.
class FloatingChipCluster extends StatelessWidget {
  const FloatingChipCluster({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileChip(),
              // Small visible gap between Profile and Xu chips — never
              // fused into one shape (hud.md HUD Elements §1/§2).
              const SizedBox(width: 8),
              const XuChip(),
              const Spacer(),
              const ContextualBadgeChip(),
            ],
          ),
        ),
      ),
    );
  }
}
