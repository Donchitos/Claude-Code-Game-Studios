// PROTOTYPE - NOT FOR PRODUCTION
// Question: Flutter-Flame State Bridge — GameEventBus pattern
// Date: 2026-06-26

import 'dart:async';

/// All event types that Flutter can send to the Flame game loop.
enum GameEventType {
  petMoodChanged,
}

class GameEvent {
  final GameEventType type;
  final dynamic data;
  const GameEvent(this.type, this.data);
}

/// Singleton broadcast StreamController.
/// Flutter layer emits → Flame layer subscribes.
/// No import of Flutter or Flame — pure Dart. Both sides can depend on this.
class GameEventBus {
  static final GameEventBus _instance = GameEventBus._internal();
  factory GameEventBus() => _instance;
  GameEventBus._internal();

  final StreamController<GameEvent> _controller =
      StreamController<GameEvent>.broadcast();

  Stream<GameEvent> get stream => _controller.stream;

  void emit(GameEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() => _controller.close();
}
