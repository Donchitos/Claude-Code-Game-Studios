// Run with:
//   cd src && flutter test ../tests/unit/bridge/game_event_bus_dispose_test.dart
//
// Kept in its own file, deliberately: GameEventBus is a true singleton with
// no reset hook (the ADR gives it exactly one dispose(), for app
// termination only), so calling dispose() here permanently closes the
// shared singleton for the rest of THIS file's isolate. Dart spawns each
// test file in its own isolate, so this can't poison game_event_bus_test.dart
// or any other file — removing the declaration-order fragility a shared
// file would have (found in code review).

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/game_event_bus.dart';

void main() {
  test('test_emit_after_dispose_is_a_silent_no_op_and_does_not_throw', () {
    final bus = GameEventBus();
    final received = <GameEvent>[];
    final sub = bus.stream
        .where((e) => e.type == GameEventType.taskApproved)
        .listen(received.add);
    addTearDown(sub.cancel);

    bus.dispose();

    expect(
      () => bus.emit(const GameEvent(GameEventType.taskApproved, null)),
      returnsNormally,
    );
    // Second dispose() call must also not throw (double-dispose safety).
    expect(bus.dispose, returnsNormally);
  });

  test('test_emit_after_dispose_actually_invokes_the_warning_log_seam', () {
    final loggedMessages = <String>[];
    final originalLogWarning = GameEventBus.logWarning;
    GameEventBus.logWarning = loggedMessages.add;
    addTearDown(() => GameEventBus.logWarning = originalLogWarning);

    final bus = GameEventBus();
    bus.dispose(); // already closed by the previous test, but idempotent

    bus.emit(const GameEvent(GameEventType.energyChanged, 42.0));

    expect(loggedMessages, hasLength(1));
    expect(loggedMessages.single, contains('emit() called after dispose()'));
    expect(loggedMessages.single, contains('energyChanged'));
  });
}
