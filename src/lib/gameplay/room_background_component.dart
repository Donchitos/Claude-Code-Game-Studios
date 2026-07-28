import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';

/// Pet Room's background layer (Story 003, ADR-0017 Decision → TR-petroom-001,
/// component tree diagram: `RoomBackgroundComponent`, `priority: 0`, direct
/// `World` child, painted behind [MochiComponent]). A minimal `SpriteComponent`
/// placeholder — the real Art Bible background asset (room illustration) is a
/// separate content task, not this story's blocker (story text, Implementation
/// Notes: "the structural contract... is what this story proves, not the final
/// art").
///
/// The placeholder is a solid-fill sprite generated in code via
/// `PictureRecorder`/`Canvas`/`Picture.toImage` — the same technique
/// `MochiComponent._createPlaceholderSprite()` uses for its own transparent
/// 1x1 placeholder, except this one paints an actual fill color so the room
/// reads as "a room" rather than "nothing" (this story fixes a literal black
/// screen — see Story 003's Context). The color is [kRoomBackgroundColor],
/// Cream Ivory (`#FFFDF0`) — the Art Bible's (`design/art/art-bible.md`
/// Section 4, Primary Palette) main world background color, also the base
/// tone the Art Bible's own Per-Area Color Temperature table assigns to Pet
/// Room ("Cream Ivory + Peach Glow (warm)"). Peach Glow is not used here —
/// it is documented as an accent/gradient color (header gradient, reward
/// popups), not a full-fill background tone; Cream Ivory alone is the correct
/// "warm, clean" base fill this story's placeholder needs.
///
/// Sized to always fill the game's actual current canvas — [onGameResize]
/// is called by Flame on every component at initial mount AND whenever the
/// `GameWidget`'s Flutter-side size changes (`component.dart:466`, `961-977`
/// — the framework calls it on the whole component tree from
/// `FlameGame.onGameResize`, not just once). Found via live user testing (a
/// real visible bug): an earlier version used a fixed `Vector2(400, 800)`
/// constant, which only ever painted a 400×800 patch starting at the
/// world-origin corner, leaving the rest of any wider/taller real canvas
/// black — this is the actual, load-bearing fix, not a cosmetic one.
class RoomBackgroundComponent extends SpriteComponent {
  // `autoResize: false` is REQUIRED here, not cosmetic: `SpriteComponent`'s
  // default (`_autoResize = autoResize ?? size == null`,
  // `sprite_component.dart:40`) is `true` whenever no explicit `size` is
  // passed to the constructor, and its `sprite` setter — called from
  // `onLoad()` below — auto-resizes `size` to match the SPRITE's own native
  // pixel dimensions when that flag is on. This placeholder's fill sprite is
  // a 1×1px generated image, so leaving `autoResize` at its default would
  // shrink `size` to `Vector2(1, 1)` the moment `sprite ??= ...` runs,
  // silently undoing whatever [onGameResize] had set — a real, confirmed
  // regression found via live user testing after the first `onGameResize`
  // fix alone did not resolve the "background doesn't fill the canvas" bug.
  RoomBackgroundComponent()
    : super(priority: 0, size: Vector2.zero(), autoResize: false);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite ??= await _createFillSprite(kRoomBackgroundColor);
  }

  static Future<Sprite> _createFillSprite(Color color) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1, 1),
      Paint()..color = color,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    return Sprite(image);
  }
}

/// Cream Ivory (`#FFFDF0`) — Art Bible Section 4, Primary Palette: "Background
/// chính — nền của thế giới, ấm và sạch" (main background — the world's base,
/// warm and clean). Used unchanged here as this story's placeholder fill.
const Color kRoomBackgroundColor = Color(0xFFFFFDF0);
