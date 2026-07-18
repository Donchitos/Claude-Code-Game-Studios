// PROTOTYPE - NOT FOR PRODUCTION
// Question: Flutter-Flame State Bridge — Flame game host
// Date: 2026-06-26

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'mochi_component.dart';

class MochiGame extends FlameGame {
  late final MochiComponent _mochi;

  @override
  Color backgroundColor() => const Color(0xFFFFFDF0); // Cream Ivory

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _mochi = MochiComponent()
      ..position = Vector2(size.x / 2, size.y / 2);

    await add(_mochi);
  }
}
