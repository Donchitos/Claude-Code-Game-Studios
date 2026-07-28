import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/currency_providers.dart';
import 'app_colors.dart';

/// Scale-pulse tween (1.0 -> 1.15 -> 1.0, `hud.md` HUD Elements §2) driving
/// [XuChip]'s reward-pulse animation.
final _pulseTween = TweenSequence<double>([
  TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
  TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
]);

/// The Xu Balance chip (`design/ux/hud.md` HUD Elements §2) — coin icon +
/// integer balance, floating pill, Honey Gold fill. Self-contained
/// `ConsumerStatefulWidget` scoped to [xuBalanceProvider] ONLY (control
/// manifest rebuild-scoping rule, this story's Implementation Note 2) —
/// `ref.watch` lives inside THIS widget's own `build`, so only this Element
/// rebuilds on a balance change; sibling chips in `floating_chip_cluster.dart`
/// never do.
///
/// Uses the safe nullable `AsyncValue.value` accessor (riverpod 3.x; never
/// `.valueOrNull`, removed) per the control manifest — on
/// [AsyncValue.hasError], renders the literal `"— xu"` text (AC-7), never
/// crashes, never rethrows.
///
/// **Known simplification (documented per this story's Implementation Note
/// 2):** [xuBalanceProvider] (`currency_providers.dart`) is a plain
/// `StreamProvider<int>` with no reward-vs-purchase "cause" signal at all —
/// Currency System (#7) exposes no such contract. Every OBSERVED INCREASE is
/// therefore treated as a task-reward pulse (scale 1.0->1.15->1.0, ~200ms);
/// every decrease snaps instantly with no animation and no pulse (`hud.md`
/// §2: "Purchases (decrease) have no pulse"). A future Currency System
/// revision that adds a real cause signal (e.g. a `lastChangeReason` field)
/// should replace this blanket rule, not this widget's animation mechanics.
class XuChip extends ConsumerStatefulWidget {
  const XuChip({super.key});

  static const chipKey = Key('xuChip');
  static const pulseKey = Key('xuChipPulse');
  static const balanceTextKey = Key('xuChipBalanceText');

  @override
  ConsumerState<XuChip> createState() => _XuChipState();
}

class _XuChipState extends ConsumerState<XuChip> with SingleTickerProviderStateMixin {
  // Constructed eagerly in `initState` (NOT a `late final` field initializer,
  // which defers construction to first access) — found via a real
  // regression in `tests/integration/auth_account/router_redirect_test.dart`:
  // under a rapid multi-step session-transition sequence, `XuChip`'s Element
  // was inflated and torn down again before `build()` ever ran, leaving a
  // lazy `late final` field never constructed. `dispose()` then triggered
  // the FIRST-EVER construction of `AnimationController(vsync: this)`, whose
  // `createTicker()` looks up an ancestor `TickerMode` — but by that point
  // the Element was already deactivating, throwing "Looking up a
  // deactivated widget's ancestor is unsafe." Eager construction in
  // `initState` (always called exactly once, always before `dispose`,
  // regardless of whether `build` ever runs) closes this gap entirely.
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  /// The count-up target value — [TweenAnimationBuilder] (see `build` below)
  /// always animates from wherever it's CURRENTLY rendered toward this new
  /// `end` whenever the tween object changes; it does not honor an explicit
  /// `begin` past its very first build (verified empirically while writing
  /// this widget's tests — a `begin`/`end` pair that were EQUAL on a
  /// mid-lifecycle update still visibly swept from the previous value,
  /// proving `TweenAnimationBuilder` ignores a stale/matching `begin` on
  /// `didUpdateWidget` and instead continues from its last evaluated value).
  /// [_countUpDuration] is therefore the ONLY real snap-vs-animate control:
  /// `Duration.zero` settles instantly regardless of the distance between
  /// old and new value; the 400ms duration is what actually produces the
  /// count-up sweep.
  int _displayValue = 0;
  Duration _countUpDuration = Duration.zero;
  bool _hasObservedFirstValue = false;

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleBalanceChange(int? previous, int next) {
    if (!mounted) return;
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    if (!_hasObservedFirstValue) {
      // Cold start / first resolved value — snap, no count-up, no pulse.
      _hasObservedFirstValue = true;
      setState(() {
        _displayValue = next;
        _countUpDuration = Duration.zero;
      });
      return;
    }
    if (previous == null || next == previous) return;

    if (next > previous) {
      setState(() {
        _displayValue = next;
        _countUpDuration = reducedMotion ? Duration.zero : const Duration(milliseconds: 400);
      });
      if (!reducedMotion) {
        _pulseController.forward(from: 0);
      }
    } else {
      // Decrease (purchase) — snap instantly, no count-up, no pulse
      // (`hud.md` §2).
      setState(() {
        _displayValue = next;
        _countUpDuration = Duration.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncBalance = ref.watch(xuBalanceProvider);
    ref.listen<AsyncValue<int>>(xuBalanceProvider, (previous, next) {
      final nextValue = next.value;
      if (nextValue == null) return; // error/loading — nothing to animate to
      _handleBalanceChange(previous?.value, nextValue);
    });

    final hasError = asyncBalance.hasError;

    return ConstrainedBox(
      key: XuChip.chipKey,
      // ≥48×48dp touch target (control manifest, this story's own AC) even
      // though display-only at MVP — future-proofing per hud.md.
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.honeyGold,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          // widthFactor/heightFactor: 1 forces this to shrink-wrap to its
          // child's size instead of expanding to fill the incoming
          // constraint — a bare Center() here would grow to fill the full
          // available height, since FloatingChipCluster's Row hands its
          // children a LOOSE-but-FINITE max height (the full screen height
          // under Positioned.fill), and Align's default (non-shrink-wrap)
          // sizing expands to that max when it is finite. The chip still
          // honors the ≥48dp minHeight from the ConstrainedBox above (via
          // BoxConstraints.constrain clamping child size up to the min),
          // so the touch-target guarantee is unaffected.
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: hasError
                ? const Text(
                    '— xu',
                    key: XuChip.balanceTextKey,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  )
                : ScaleTransition(
                    key: XuChip.pulseKey,
                    scale: _pulseTween.animate(_pulseController),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: _displayValue),
                          duration: _countUpDuration,
                          curve: Curves.easeOut,
                          builder: (context, animatedValue, _) => Text(
                            '$animatedValue',
                            key: XuChip.balanceTextKey,
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
      ),
    );
  }
}
