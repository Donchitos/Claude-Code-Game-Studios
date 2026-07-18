// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does the ADR-0004-corrected onMount()/onRemove()
// GameEventBus subscription pattern actually work in real Flame 1.37, and does
// the parent-approve -> child-visible latency feel instant?
// Date: 2026-07-13

import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../core/game_event_bus.dart';
import 'pet_mood_provider.dart';

enum TriggeredState { none, excited }

class MochiComponent extends PositionComponent {
  MochiComponent({
    required Vector2 position,
    required Vector2 size,
    PetMood initialMood = PetMood.content,
  })  : _baseMood = initialMood,
        super(position: position, size: size, anchor: Anchor.center);

  // REAL BUG (caught via self-test, 2026-07-13): this component used to
  // hardcode `PetMood.content` regardless of the constructor's initialMood -
  // harmless on the very FIRST app launch (GameEventBridge's one-time
  // cold-start seed papers over it), but the moment PetRoomScreen is
  // recreated (e.g. after navigating to Parent Dashboard and back), a brand
  // new MochiComponent mounts with no petMoodChanged event on the way (the
  // bridge's ref.listen only fires on a CHANGE, and the mood had already
  // settled before this new instance existed) - so it silently reverted to
  // the wrong color. This also means ADR-0004's "replay last known state"
  // requirement (TR-bridge-005) is doing real work here, not just covering
  // app-background/foreground - it needs to cover ANY fresh subscriber, which
  // this slice only handles via constructor injection, not a true bus-level
  // replay. Worth a real fix in production - see REPORT.md.
  PetMood _baseMood;
  TriggeredState _triggered = TriggeredState.none;
  late final RectangleComponent _body;
  StreamSubscription<GameEvent>? _sub;

  @override
  Future<void> onLoad() async {
    _body = RectangleComponent(
      size: size,
      paint: Paint()..color = _colorForMood(_baseMood),
      anchor: Anchor.topLeft,
    );
    await add(_body);
  }

  /// Subscribe in onMount(), NOT onLoad() - isMounted is false throughout
  /// onLoad(), silently dropping events (ADR-0004 SS4, verified against real
  /// Flame 1.37 source).
  @override
  void onMount() {
    super.onMount();
    _sub = GameEventBus().stream.listen(_onEvent);
  }

  @override
  void onRemove() {
    _sub?.cancel();
    super.onRemove();
  }

  void _onEvent(GameEvent event) {
    if (!isMounted) return;
    switch (event.type) {
      case GameEventType.petMoodChanged:
        _baseMood = event.data as PetMood;
        if (_triggered == TriggeredState.none) {
          _body.paint.color = _colorForMood(_baseMood);
        }
        break;
      case GameEventType.taskApproved:
        _playExcited();
        break;
    }
  }

  void _playExcited() {
    _triggered = TriggeredState.excited;
    _body.paint.color = const Color(0xFFFFD060); // Honey Gold, Art Bible
    _clearEffects();
    add(
      SequenceEffect(
        [
          ScaleEffect.to(Vector2.all(1.25), EffectController(duration: 0.4, curve: Curves.easeOut)),
          ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.4, curve: Curves.easeIn)),
        ],
        onComplete: () {
          _triggered = TriggeredState.none;
          _body.paint.color = _colorForMood(_baseMood);
        },
      ),
    );
  }

  void _clearEffects() {
    children.whereType<ScaleEffect>().toList().forEach((e) => e.removeFromParent());
    children.whereType<SequenceEffect>().toList().forEach((e) => e.removeFromParent());
  }

  Color _colorForMood(PetMood mood) {
    switch (mood) {
      case PetMood.sleeping:
        return const Color(0xFF9E9E9E);
      case PetMood.sad:
        return const Color(0xFF8FA3C0);
      case PetMood.tired:
        return const Color(0xFFC0A898); // Art Bible disabled-text warm neutral
      case PetMood.content:
        return const Color(0xFFFFB6A3); // Peach Glow
      case PetMood.happy:
        return const Color(0xFFFFD060); // Honey Gold
    }
  }
}
