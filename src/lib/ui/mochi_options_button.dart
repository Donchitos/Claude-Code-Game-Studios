import 'package:flutter/material.dart';

import '../gameplay/pet_room_game.dart';
import 'app_colors.dart';

/// The sole sanctioned trigger for [PetRoomGame.showModal]`('context_menu')`
/// (ADR-0018: Mochi Options Button as the Context Menu Trigger). A small,
/// persistent, always-visible icon button — deliberately NOT a new Flame
/// gesture on `MochiComponent` — anchored near Mochi's position/size (same
/// technique `PetRoomContextMenu`'s own speech-bubble anchor uses) so it
/// stays spatially associated with Mochi per the GDD's "context menu is
/// ABOUT Mochi" framing, without touching Mochi's own tap/swipe handling
/// (ADR-0016, unchanged — a tap on Mochi's sprite still triggers PLEASED).
///
/// Part of the `'chrome'` overlay, mounted alongside (not inside)
/// [PetRoomStatusRow] — that widget's own scope is mood/energy only (Story
/// 006's Acceptance Criteria), so this button is a separate, independently
/// testable widget in the same overlay slot rather than an addition to it.
///
/// Ignores taps while Mochi's non-interruptible LEVELING_UP celebration is
/// playing — see [_onTap]'s own doc comment (GDD Edge Case 5's intent,
/// carried over from the pre-ADR-0018 tap-on-Mochi mechanism).
class MochiOptionsButton extends StatelessWidget {
  const MochiOptionsButton({super.key, required this.game});

  final PetRoomGame game;

  static const buttonKey = Key('mochiOptionsButton');

  /// GDD `pet-room-screen-ui.md` Edge Case 5 predates ADR-0018 but its
  /// underlying intent survives the trigger-mechanism change: the context
  /// menu must not open while Mochi's non-interruptible LEVELING_UP
  /// celebration (Pet State Machine #6's highest-priority Triggered State,
  /// `triggered_state.dart`) is playing. The original wording described
  /// this as "tap Mochi during LEVELING_UP doesn't open the menu"; with the
  /// menu now opening via this button instead of tap-on-Mochi, the guard
  /// moves here. Scoped to LEVELING_UP specifically (not every Triggered
  /// State) — the GDD never asked for the menu to be blocked during
  /// BOUNCING/EXCITED/PLEASED/SHOWING_OFF, only the one truly
  /// non-interruptible state.
  void _onTap() {
    if (game.mochi?.isCelebratingNonInterruptibly ?? false) return;
    game.showModal('context_menu');
  }

  /// `game.size` (kept in sync every layout pass by Flame's own
  /// `onGameResize`), NOT `MediaQuery.sizeOf(context)` — the same fix Story
  /// 007's code review applied to `PetRoomContextMenu`/`PetRoomWardrobe`:
  /// this overlay lives inside the `GameWidget`'s own local box (below the
  /// `AppBar`), which `MediaQuery.sizeOf` does not reflect.
  @override
  Widget build(BuildContext context) {
    final mochi = game.mochi;
    final screenWidth = game.size.x;
    final screenHeight = game.size.y;

    double left;
    double top;
    if (mochi != null) {
      // Bottom-right corner of Mochi's own hit-area box — a small badge
      // "attached" to Mochi, distinct from Mochi's own tappable sprite
      // region so it never competes with Mochi's own tap/swipe hit-test.
      left = (mochi.position.x + mochi.size.x - _buttonSize / 2)
          .clamp(_edgeMargin, screenWidth - _buttonSize - _edgeMargin);
      top = (mochi.position.y + mochi.size.y - _buttonSize / 2)
          .clamp(_edgeMargin, screenHeight - _buttonSize - _edgeMargin);
    } else {
      // Defensive fallback (mochi is only null before onLoad resolves) —
      // never a crash.
      left = screenWidth - _buttonSize - _edgeMargin;
      top = screenHeight * 0.4;
    }

    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        key: buttonKey,
        // Minimum 48×48dp tap target (technical-preferences.md) — this is
        // a child-facing app.
        width: _buttonSize,
        height: _buttonSize,
        child: Semantics(
          label: 'Tùy chọn Mochi',
          button: true,
          child: Tooltip(
            message: 'Tùy chọn Mochi',
            child: Material(
              color: AppColors.creamIvory.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _onTap,
                child: const Icon(
                  Icons.more_horiz,
                  color: AppColors.primaryText,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _buttonSize = 48.0;
const _edgeMargin = 12.0;
