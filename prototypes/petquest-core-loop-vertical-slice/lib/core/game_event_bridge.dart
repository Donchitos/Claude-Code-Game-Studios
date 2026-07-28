// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: is `ref.listen` in a ConsumerWidget a clean, single
// sanctioned place for every Flutter->Flame emission (ADR-0004), rather than
// ad-hoc GameEventBus.emit() calls scattered across button callbacks?
// Date: 2026-07-13

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'game_event_bus.dart';
import '../pet/pet_mood_provider.dart';

/// Fires once per approved task; the payload is the xu reward granted.
/// Incrementing an int "nonce" lets ref.listen distinguish repeat approvals
/// of different tasks from a no-op rebuild.
final taskApprovedNonceProvider = StateProvider<int>((ref) => 0);
final lastApprovedXuRewardProvider = StateProvider<int>((ref) => 0);

/// The one sanctioned Flutter->Flame emission point for this slice. Mount
/// once near the app root so it is always alive to seed + relay events.
class GameEventBridge extends ConsumerStatefulWidget {
  final Widget child;
  const GameEventBridge({super.key, required this.child});

  @override
  ConsumerState<GameEventBridge> createState() => _GameEventBridgeState();
}

class _GameEventBridgeState extends ConsumerState<GameEventBridge> {
  bool _seeded = false;

  @override
  Widget build(BuildContext context) {
    // Cold-start seed (ADR-0007 "Required Patterns"): emit petMoodChanged
    // once with the current mood so a freshly-mounted MochiComponent has a
    // starting color without waiting for the mood to actually change.
    if (!_seeded) {
      _seeded = true;
      final initialMood = ref.read(petMoodProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GameEventBus().emit(GameEvent(GameEventType.petMoodChanged, initialMood));
      });
    }

    ref.listen(petMoodProvider, (previous, next) {
      if (previous != next) {
        GameEventBus().emit(GameEvent(GameEventType.petMoodChanged, next));
      }
    });

    ref.listen(taskApprovedNonceProvider, (previous, next) {
      if (previous != next) {
        final xu = ref.read(lastApprovedXuRewardProvider);
        GameEventBus().emit(GameEvent(GameEventType.taskApproved, xu));
      }
    });

    return widget.child;
  }
}
