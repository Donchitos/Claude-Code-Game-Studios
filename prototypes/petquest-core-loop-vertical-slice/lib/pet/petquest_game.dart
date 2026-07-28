// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does the Flame canvas draw-call budget (ADR-0001) hold
// for this trivial scene, and does GameWidget host cleanly inside a
// StatefulShellRoute-style screen?
// Date: 2026-07-13
//
// Uses the default MaxViewport (fills the GameWidget's actual canvas size)
// rather than CameraComponent.withFixedResolution - the fixed-resolution
// letterbox approach rendered at a literal 400x600 pixel patch instead of
// scaling to fill the screen in this session's testing; not worth the extra
// debugging time for a vertical slice validating the core loop, not visual
// fidelity across screen sizes.

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'mochi_component.dart';
import 'pet_mood_provider.dart';

class PetQuestGame extends FlameGame {
  final PetMood initialMood;
  PetQuestGame({required this.initialMood});

  RectangleComponent? background;
  MochiComponent? mochi;

  @override
  Future<void> onLoad() async {
    background = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFFFFF3E0), // Cream Ivory
    );
    await add(background!);
    mochi = MochiComponent(
      position: size / 2,
      size: Vector2(120, 120),
      initialMood: initialMood,
    );
    await add(mochi!);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    background?.size = size;
    mochi?.position = size / 2;
  }
}
