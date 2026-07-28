// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does the one-way Flutter->Flame GameEventBus pattern
// from ADR-0004 actually deliver events with the latency the spike measured?
// Date: 2026-07-13

import 'dart:async';

/// Every event type owns a distinct payload shape (ADR-0004 - payload types
/// must never be shared across event types).
enum GameEventType { petMoodChanged, taskApproved }

class GameEvent {
  final GameEventType type;
  final Object data;
  const GameEvent(this.type, this.data);
}

/// Pure-Dart broadcast singleton, app-lifetime. Imports neither Flutter nor
/// Flame (ADR-0004 "Required Patterns"). Constructed once at app root;
/// disposed only at app termination, never per-screen.
///
/// StreamController.broadcast() is created WITHOUT `sync: true` (the default),
/// so emitting from a tap callback is reentrancy-safe per ADR-0004.
class GameEventBus {
  GameEventBus._internal();
  static final GameEventBus _instance = GameEventBus._internal();
  factory GameEventBus() => _instance;

  final StreamController<GameEvent> _controller =
      StreamController<GameEvent>.broadcast();

  Stream<GameEvent> get stream => _controller.stream;

  void emit(GameEvent event) {
    if (_controller.isClosed) {
      // ignore: avoid_print
      print('[GameEventBus] emit() called after dispose - silent no-op');
      return;
    }
    _controller.add(event);
  }

  void dispose() => _controller.close();
}
