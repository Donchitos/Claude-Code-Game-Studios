import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/seed_buffer_providers.dart';
import 'app_colors.dart';

/// Pop-in-with-overshoot tween (scale 0 -> 1.1 -> 1.0, `hud.md` HUD Elements
/// §3) — plays once, the moment [_SeedBadgeContent] first mounts (i.e. the
/// instant the badge appears from a hidden/zero state).
final _popInTween = TweenSequence<double>([
  TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.1), weight: 7),
  TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 3),
]);

/// Single-pulse tween (scale 1.0 -> 1.15 -> 1.0, `hud.md` HUD Elements §3) —
/// plays each time the count increments further while already visible, "so a
/// second pending seed doesn't go unnoticed while the badge is already
/// visible" (hud.md's own wording).
final _pulseTween = TweenSequence<double>([
  TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
  TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
]);

/// The Contextual Badge chip (`design/ux/hud.md` HUD Elements §3) — top-right
/// floating pill, Honey Gold fill (never an alert/red color — a pending seed
/// is a positive state, not a warning).
///
/// **Binding scope (main-navigation-shell Story 006 — documented gap, not an
/// oversight):** this story binds ONLY to [seedCountProvider] (Seed Buffer
/// #10, Complete). `chestCount` (Gacha/Loot #12) has no dedicated provider
/// yet — only a raw Firestore field written via `FieldValue.increment()` in
/// `parent_approval_repository.dart`'s level-up/milestone path, with no
/// epic/ADR of its own establishing its read contract. `hud.md` §3 also
/// states the seed-vs-chest choice is "determined by the screen's own UX
/// spec" — but neither the Task Management UI nor the Shop screen (the two
/// screens that would make this decision) has a UX spec yet. Rather than
/// invent a `chestCountProvider` or a per-screen binding mechanism ahead of
/// either of those, this chip is wired to `seedCountProvider` unconditionally
/// as a placeholder (explicitly permitted by this story's Out of Scope
/// note). Wiring the chest variant, and any per-screen binding decision, is
/// left to whichever future story lands Task Management UI / Shop with a
/// real UX spec.
///
/// A `seedCountProvider` [AsyncValue.hasError] is treated the same as `0` —
/// hidden — rather than a distinct error affordance: this chip has no error
/// state in `hud.md`'s spec (unlike [XuChip]'s explicit "— xu"), and "hidden"
/// is always a safe, non-crashing degradation for a purely informational,
/// positive-state badge.
///
/// Hidden entirely — not opacity/greyed, not a zero-size box — when the bound
/// count is `0`: [ContextualBadgeChip.build] simply does not construct
/// [_SeedBadgeContent] at all in that case, so `find.byType` on the content
/// widget finds nothing (AC-4's exact wording). This also means every
/// 0->positive transition constructs a FRESH [_SeedBadgeContent], whose own
/// `initState` naturally plays the pop-in animation on every reappearance,
/// not just the first ever.
class ContextualBadgeChip extends ConsumerWidget {
  const ContextualBadgeChip({super.key});

  /// Test seam — [_SeedBadgeContent] is library-private, so its own
  /// `ScaleTransition` key is exposed here on the public class instead (test
  /// files outside this library cannot reference a private class member).
  static const badgeKey = Key('contextualBadgeChip');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(seedCountProvider).value ?? 0;
    if (count <= 0) return const SizedBox.shrink();
    return _SeedBadgeContent(count: count);
  }
}

class _SeedBadgeContent extends StatefulWidget {
  const _SeedBadgeContent({required this.count});

  final int count;

  @override
  State<_SeedBadgeContent> createState() => _SeedBadgeContentState();
}

class _SeedBadgeContentState extends State<_SeedBadgeContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scale;
  bool _startedInitialAnimation = false;

  bool get _reducedMotion => MediaQuery.of(context).disableAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = _popInTween.animate(_controller);
    // Deliberately NOT started here: `MediaQuery.of(context)` must not be
    // called from `initState()` (Flutter's own inherited-widget-dependency
    // rule — an ancestor `InheritedWidget` isn't safely readable yet at this
    // point in the Element lifecycle). Started from `didChangeDependencies`
    // instead, which runs immediately after `initState` on first build (and
    // again on any later `MediaQuery` change) — the framework-endorsed place
    // for this exact kind of context-dependent initialization.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedInitialAnimation) return;
    _startedInitialAnimation = true;
    if (_reducedMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _SeedBadgeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > oldWidget.count) {
      if (_reducedMotion) return; // stays settled at scale 1.0
      setState(() {
        _controller.duration = const Duration(milliseconds: 200);
        _scale = _pulseTween.animate(_controller);
      });
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      key: ContextualBadgeChip.badgeKey,
      scale: _scale,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.honeyGold,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Center(
              child: Text(
                '🌱 ${widget.count}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
