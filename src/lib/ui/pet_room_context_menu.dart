import 'package:flutter/material.dart';

import '../core/game_event_bus.dart';
import '../core/interaction_type.dart';
import '../gameplay/pet_room_game.dart';
import 'app_colors.dart';

/// Tap-on-Mochi context menu (Story 007, Pet Room Screen UI epic — GDD Core
/// Rule 5 / AC-CR5-1/5-2/5-3): 3 options — "Thay đồ", "Vuốt ve", "Đóng".
/// Mounted via the `'context_menu'` overlay key (Story 003, ADR-0017);
/// opened/closed exclusively through [PetRoomGame.showModal]/[dismissModal]
/// — never mutates `game.overlays` directly (Story 003's forbidden pattern).
///
/// **Scope gap found while implementing this story**: nothing in this
/// story's own Acceptance Criteria, Implementation Notes, Dependencies, or
/// Out of Scope wires up *what gesture calls* `game.showModal('context_menu')`
/// in the first place — only the menu's own content and button behavior
/// once open. The GDD's Overview prose says "tap-on-Mochi mở context menu",
/// but Pet Interaction #14's own ratified GDD (Core Rule 2, AC-1) and
/// ADR-0016 already map a tap on Mochi's sprite directly to the PLEASED
/// wiggle animation via `petInteracted` — not to opening this menu. Wiring
/// a real trigger would mean either overriding Pet Interaction's ratified
/// tap semantics (a cross-epic, ADR-level conflict, not a small UI
/// addition) or inventing a new gesture (e.g. long-press) with no
/// GDD/ADR backing. Left unresolved deliberately — `showModal('context_menu')`
/// has no production caller yet; this widget only implements what happens
/// once it's called.
class PetRoomContextMenu extends StatelessWidget {
  const PetRoomContextMenu({super.key, required this.game});

  final PetRoomGame game;

  /// Card root — what tests target for presence/position assertions.
  static const cardKey = Key('petRoomContextMenuCard');
  static const changeOutfitButtonKey = Key('petRoomContextMenuChangeOutfit');
  static const petButtonKey = Key('petRoomContextMenuPet');
  static const closeButtonKey = Key('petRoomContextMenuClose');

  /// "Thay đồ": Implementation Notes — `showModal('wardrobe')` alone is
  /// enough; [PetRoomGame.showModal] itself removes `'context_menu'` before
  /// adding `'wardrobe'`, so calling it directly (rather than
  /// `dismissModal()` followed by a second `showModal()` call) is what
  /// guarantees no intermediate frame exists with neither, or both, modal
  /// keys active (AC-CR5-3).
  void _onChangeOutfit() => game.showModal('wardrobe');

  /// "Vuốt ve": AC-CR5-1 — calls Pet Interaction #14's PLEASED trigger path
  /// via the same `GameEventBus`/`petInteracted` mechanism
  /// `MochiComponent`'s own on-canvas tap/swipe handling already uses
  /// (`mochi_component.dart`'s `_handleClassifiedGesture`) — not by
  /// reaching into `game.mochi`'s `@visibleForTesting onTrigger` directly,
  /// which would bypass ADR-0004's Flutter→Flame bridge and trip the
  /// `invalid_use_of_visible_for_testing_member` lint outside test code.
  /// `InteractionType.tap` is used for the payload (this is a menu button
  /// tap, not an on-canvas swipe) — cooldown/guard logic in
  /// `MochiComponent._handleInteractionAttempt` does NOT apply here, since
  /// that machinery only runs for gestures classified from real canvas
  /// `DragCallbacks`; emitting `petInteracted` goes straight to
  /// `MochiComponent.onGameEvent`'s handler, bypassing that gesture/
  /// cooldown layer entirely — matching the story's own wording ("triggers
  /// Pet Interaction's PLEASED state directly").
  ///
  /// flame-widget-specialist code review: "directly" above is about
  /// bypassing the cooldown/gesture-classification layer, NOT about
  /// bypassing Story 004's modal-defer/replay mechanism, which this DOES
  /// still go through — this menu is itself an open modal at the moment
  /// this method runs, so `MochiComponent._modalOpen` is still `true` when
  /// `onGameEvent` calls `onTrigger(pleased)`; the trigger is queued into
  /// `_pendingVisual` and only actually plays once `dismissModal()`'s own
  /// `modalVisibilityChanged(false)` (emitted below) replays it. AC-CR5-1's
  /// "no delay" is still satisfied — `GameEventBus`'s single controller
  /// delivers both events in the same microtask-flush window — but a
  /// future reader debugging trigger *timing* should not assume this call
  /// applies PLEASED synchronously.
  void _onPet() {
    GameEventBus().emit(GameEvent(GameEventType.petInteracted, InteractionType.tap));
    game.dismissModal();
  }

  void _onClose() => game.dismissModal();

  @override
  Widget build(BuildContext context) {
    // Speech-bubble anchor: Mochi's own position/size (Story 001's output —
    // this story only consumes it, per its own Out of Scope). Today this
    // places the card near Mochi's current on-canvas position, which is
    // world (0,0) top-left — no story has yet implemented the GDD Tuning
    // Knobs' "55% from top" vertical placement for Mochi itself (a visual-
    // polish concern tracked separately, not a regression this story
    // introduces). Flame world coordinates are read directly as
    // Flutter-local pixel coordinates within the `GameWidget`'s box — valid
    // here since `PetRoomGame`'s camera applies no zoom (`onLoad`'s only
    // camera change is `viewfinder.anchor`).
    final mochi = game.mochi;
    // `game.size` (kept in sync every layout pass by Flame's own
    // `onGameResize`), NOT `MediaQuery.sizeOf(context)` — flame-widget-
    // specialist code review, source-verified against `game_widget.dart`:
    // the overlay `Stack` this widget builds into is laid out within the
    // `GameWidget`'s own local box (the `Scaffold` body, below the
    // `AppBar`), while `MediaQuery.sizeOf` always returns the full
    // app-window size regardless of nesting. Confirmed empirically (a
    // throwaway diagnostic test) that these differ by exactly
    // `kToolbarHeight` — using `MediaQuery` here would clamp against the
    // wrong, larger bound. `mochi.position`/`.size` are themselves already
    // in this same `game.size` coordinate space, so this is also the
    // coordinate-space-consistent choice, not just the correct clamp bound.
    final screenWidth = game.size.x;
    final screenHeight = game.size.y;
    double left;
    double top;
    if (mochi != null) {
      left = (mochi.position.x + mochi.size.x / 2 - _cardWidth / 2)
          .clamp(_edgeMargin, screenWidth - _cardWidth - _edgeMargin);
      top = (mochi.position.y + mochi.size.y + _tailGap)
          .clamp(_edgeMargin, screenHeight - _cardHeight - _edgeMargin);
    } else {
      // Defensive fallback (mochi is only null before onLoad resolves,
      // which is before 'chrome' — let alone a modal — could ever be
      // opened in practice): center-ish placement, never a crash.
      left = (screenWidth - _cardWidth) / 2;
      top = screenHeight * 0.4;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onClose,
            // Warm scrim (`#3D2B1F` ~20-25% opacity) — Control Manifest
            // Required pattern; never a standard black/dark scrim (Art
            // Bible's dark-vignette ban).
            child: ColoredBox(color: AppColors.primaryText.withValues(alpha: 0.22)),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // Absorb taps landing on the card itself.
            child: Container(
              key: cardKey,
              width: _cardWidth,
              decoration: BoxDecoration(
                color: AppColors.creamIvory,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MenuOption(
                    key: changeOutfitButtonKey,
                    icon: Icons.checkroom,
                    label: 'Thay đồ',
                    onTap: _onChangeOutfit,
                  ),
                  const Divider(height: 1, color: AppColors.disabledText),
                  _MenuOption(
                    key: petButtonKey,
                    icon: Icons.favorite,
                    label: 'Vuốt ve',
                    onTap: _onPet,
                  ),
                  const Divider(height: 1, color: AppColors.disabledText),
                  _MenuOption(
                    key: closeButtonKey,
                    icon: Icons.close,
                    label: 'Đóng',
                    onTap: _onClose,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const _cardWidth = 200.0;
const _cardHeight = 160.0;
const _tailGap = 8.0;
const _edgeMargin = 12.0;

class _MenuOption extends StatelessWidget {
  const _MenuOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        // flame-widget-specialist code review: content-only height was
        // ~46dp (22dp icon + 24dp vertical padding), under
        // technical-preferences.md's stated 48×48dp minimum tap target —
        // this app is child-facing, where that minimum matters more, not
        // less.
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryText, size: 22),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: AppColors.primaryText, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
