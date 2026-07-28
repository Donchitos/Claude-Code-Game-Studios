// PROTOTYPE - NOT FOR PRODUCTION
// Question: Flutter-Flame State Bridge — MochiComponent reacts to events
// Date: 2026-06-26

import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'game_event_bus.dart';
import 'pet_state.dart';

/// A simple circle that represents Mochi.
/// Subscribes to GameEventBus and reacts to petMoodChanged events
/// entirely within the Flame game loop — no direct Flutter dependency.
class MochiComponent extends CircleComponent {
  StreamSubscription<GameEvent>? _subscription;

  static const double _baseRadius = 60;

  MochiComponent()
      : super(
          radius: _baseRadius,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xFFFFCBA4), // Peach Glow neutral
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _subscription = GameEventBus().stream.listen(_onEvent);

    // Eyes — two small circles, positioned relative to Mochi center
    await add(CircleComponent(
      radius: 6,
      position: Vector2(-18, -10),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFF5D4037),
    ));
    await add(CircleComponent(
      radius: 6,
      position: Vector2(18, -10),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFF5D4037),
    ));
  }

  void _onEvent(GameEvent event) {
    if (event.type != GameEventType.petMoodChanged) return;
    if (!isMounted) return; // Guard: component may have been removed

    final mood = event.data as PetMood;
    _clearEffects();

    switch (mood) {
      case PetMood.happy:
        paint.color = const Color(0xFFA8E6CF); // Mint Breeze
        // Bounce: scale up then back
        add(ScaleEffect.by(
          Vector2.all(1.3),
          EffectController(duration: 0.2, reverseDuration: 0.2),
        ));
      case PetMood.sad:
        paint.color = const Color(0xFFC5A3E0); // Lavender Soft
        // Shrink slightly
        add(ScaleEffect.to(
          Vector2.all(0.8),
          EffectController(duration: 0.4),
        ));
      case PetMood.neutral:
        paint.color = const Color(0xFFFFCBA4); // Peach Glow
        add(ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: 0.3),
        ));
    }
  }

  void _clearEffects() {
    // Remove any running scale effects before adding new ones
    children.whereType<ScaleEffect>().toList().forEach(remove);
  }

  @override
  void onRemove() {
    _subscription?.cancel();
    super.onRemove();
  }
}
