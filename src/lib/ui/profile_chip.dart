import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import 'app_colors.dart';
import 'parent_override_trigger.dart';

/// The Profile chip (`design/ux/hud.md` HUD Elements §1) — avatar circle
/// (32dp) + child's name (16sp bold), floating pill, grouped in the top-left
/// cluster adjacent to [XuChip] (`xu_chip.dart`) with a visible gap, never
/// fused into one shape (positioning owned by `floating_chip_cluster.dart`,
/// not this widget).
///
/// Content is "static per session — re-renders only if the active child
/// profile changes" (hud.md §1's own wording) for free: `ref.watch
/// (activeChildProvider)` only triggers a rebuild of THIS widget's own
/// Element when that provider's value actually changes (Riverpod's normal
/// scoping), never on unrelated provider changes (e.g. xu balance ticking) —
/// satisfying the control manifest's rebuild-scoping rule without any extra
/// `select`.
///
/// The long-press gesture (≥600ms → "Chuyển sang tài khoản bố/mẹ?" sheet) is
/// Main Navigation Shell Story 004's already-built, already-tested
/// [ParentOverrideTrigger] — wrapped around this widget's own visual content
/// rather than reimplemented (main-navigation-shell Story 006 Implementation
/// Note 1 / Out of Scope). No avatar art asset pipeline exists yet (no
/// `avatarId` → image mapping anywhere in this codebase) — a plain icon
/// placeholder is used, matching Story 004's own original placeholder
/// styling, rather than inventing bespoke generated art.
class ProfileChip extends ConsumerWidget {
  const ProfileChip({super.key});

  static const avatarDiameter = 32.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChild = ref.watch(activeChildProvider);

    return ParentOverrideTrigger(
      child: ConstrainedBox(
        // ≥48×48dp touch target (control manifest, this story's own AC) even
        // though the chip is only interactive via the long-press wrapper
        // above, not a tap — future-proofing per hud.md's Platform & Input
        // Variants section.
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.lavenderSoft,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: ProfileChip.avatarDiameter / 2,
                  backgroundColor: AppColors.cloudWhite,
                  child: Icon(
                    Icons.person,
                    color: AppColors.primaryText,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 96),
                  child: Text(
                    activeChild?.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
