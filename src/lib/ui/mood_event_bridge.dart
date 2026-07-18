import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/game_event_bus.dart';
import '../core/pet_mood.dart';
import '../providers/pet_state_providers.dart';

/// The sanctioned Flutter→Flame emit adapter for Base Mood (ADR-0004 §3(a):
/// "`ref.listen` in a `ConsumerWidget`", ADR-0007 Decision §1) — the ONLY
/// place [GameEventType.petMoodChanged] is emitted onto [GameEventBus]. Wrap
/// the widget that hosts the Flame `GameWidget`/canvas (Pet Room Screen UI
/// #18, a future epic) with this widget so `MochiComponent` receives Base
/// Mood updates. This widget renders no UI of its own — it forwards `child`
/// unchanged; it exists purely for the event-bridge side effect.
///
/// `ref.listenManual(..., fireImmediately: true)` in [State.initState]
/// satisfies both ADR-0007 requirements in one call: the cold-start seed
/// (emits once immediately with the current [petMoodProvider] value, since a
/// plain `ref.listen` fires only on *change* and would leave a
/// freshly-mounted `MochiComponent` with a null Base Mood) and ongoing
/// on-change forwarding. `listenManual` (not `ref.listen` inside `build`) is
/// required here because the one-time `fireImmediately` setup must happen
/// exactly once, not on every rebuild — `listenManual`'s own subscription is
/// disposed automatically when this widget is disposed, per its
/// documentation, so no manual `dispose()` override is needed.
class MoodEventBridge extends ConsumerStatefulWidget {
  const MoodEventBridge({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<MoodEventBridge> createState() => _MoodEventBridgeState();
}

class _MoodEventBridgeState extends ConsumerState<MoodEventBridge> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<MoodState>(
      petMoodProvider,
      (previous, next) => _emit(next),
      fireImmediately: true,
    );
  }

  void _emit(MoodState mood) {
    GameEventBus().emit(GameEvent(GameEventType.petMoodChanged, mood));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
