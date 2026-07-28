import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/child_profile.dart';
import '../providers/auth_providers.dart';
import '../providers/router_provider.dart';
import 'app_colors.dart';

const int _maxProfiles = 4;

/// Child Profile Selection Screen (Story 011), per
/// `design/ux/child-profile-selection-screen.md`. 2×2 grid of profile cards
/// (up to 4, per GDD Tuning Knobs) + a "Thêm bé" card when a slot is free.
/// The delete-profile confirmation dialog does NOT belong here — resolved to
/// Parent Dashboard epic #21 (user decision, 2026-07-16, see the UX spec's
/// Open Questions).
class ChildProfileSelectionScreen extends ConsumerWidget {
  const ChildProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(childProfilesProvider);
    return Scaffold(
      backgroundColor: AppColors.creamIvory,
      body: SafeArea(
        child: Center(
          child: profilesAsync.when(
            loading: () => const _LoadingGrid(),
            error: (error, stackTrace) => _ErrorState(
              onRetry: () => ref.invalidate(childProfilesProvider),
            ),
            data: (profiles) => _ProfileGrid(profiles: profiles),
          ),
        ),
      ),
    );
  }
}

/// P5: skeleton shimmer while `childProfilesProvider`'s first snapshot is
/// pending — never a blank screen or a spinner-with-character.
class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return _GridLayout(
      children: List.generate(
        _maxProfiles,
        (_) => const _ShimmerCard(),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cloudWhite,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.primaryText, size: 32),
        const SizedBox(height: 12),
        const Text(
          'Không tải được danh sách hồ sơ',
          style: TextStyle(color: AppColors.primaryText),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onRetry,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.lavenderSoft,
            foregroundColor: AppColors.primaryText,
          ),
          child: const Text('Thử lại'),
        ),
      ],
    );
  }
}

/// P6: empty state for 0 profiles — friendly copy, "Thêm bé" stays usable.
class _ProfileGrid extends StatelessWidget {
  const _ProfileGrid({required this.profiles});

  final List<ChildProfile> profiles;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Chưa có hồ sơ nào — hãy thêm bé đầu tiên!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.primaryText),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 140,
            height: 140,
            child: _AddChildCard(),
          ),
        ],
      );
    }

    final cells = <Widget>[
      for (final profile in profiles) _ProfileCard(profile: profile),
      if (profiles.length < _maxProfiles) const _AddChildCard(),
    ];
    return _GridLayout(children: cells);
  }
}

/// 2×2 grid, centered — matches the UX spec's Layout Zones exactly (up to 4
/// cells; fewer than 4 cells simply leaves the grid short, no placeholder
/// blanks needed since `GridView` sizes to its children count via `shrinkWrap`).
class _GridLayout extends StatelessWidget {
  const _GridLayout({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
        children: children,
      ),
    );
  }
}

class _ProfileCard extends StatefulWidget {
  const _ProfileCard({required this.profile});

  final ChildProfile profile;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool _pressed = false;
  bool _navigating = false;

  /// P1 single-flight guard — a fast double-tap must not push PIN entry
  /// twice (UX spec Accessibility section). Resets once the pushed route is
  /// popped back to, since this is a `push` (screen stays mounted
  /// underneath), not a `pushReplacement`.
  Future<void> _handleTap() async {
    if (_navigating) return;
    setState(() => _navigating = true);
    await context.push(AppRoutes.pinEntryFor(widget.profile.childId));
    if (mounted) setState(() => _navigating = false);
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.cloudWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pets, size: 40, color: AppColors.lavenderSoft),
          const SizedBox(height: 8),
          Text(
            widget.profile.name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(color: AppColors.primaryText),
          ),
        ],
      ),
    );

    // Reduced motion: press feedback becomes opacity-only, not a scale
    // transform (UX spec Transitions & Animations section).
    final pressFeedback = reducedMotion
        ? AnimatedOpacity(
            opacity: _pressed ? 0.7 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: content,
          )
        : AnimatedScale(
            scale: _pressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: content,
          );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: _handleTap,
        child: pressFeedback,
      ),
    );
  }
}

/// Tap destination is TBD (no "add child" flow exists anywhere in the
/// project yet — `design/ux/child-profile-selection-screen.md`'s Open
/// Questions). No-op for this story.
class _AddChildCard extends StatelessWidget {
  const _AddChildCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // "Thêm bé" destination is TBD — out of scope for this story.
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.secondaryText),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 32, color: AppColors.secondaryText),
            SizedBox(height: 4),
            Text('Thêm bé', style: TextStyle(color: AppColors.secondaryText)),
          ],
        ),
      ),
    );
  }
}
