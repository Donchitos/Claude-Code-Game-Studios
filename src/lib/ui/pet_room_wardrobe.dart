import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/item_model.dart';
import '../gameplay/pet_room_game.dart';
import '../providers/item_catalog_provider.dart';
import 'app_colors.dart';

/// The 3 equipment slots (Pet Equipment #15's 3-slot model), in tab display
/// order — matches this story's own Implementation Notes list order.
const List<({String slot, String label, IconData icon})> _slots = [
  (slot: 'body_outfit', label: 'Trang phục', icon: Icons.checkroom),
  (slot: 'hat', label: 'Mũ', icon: Icons.school),
  (slot: 'accessory', label: 'Phụ kiện', icon: Icons.diamond),
];

/// Wardrobe bottom sheet (Story 007, Pet Room Screen UI epic — GDD Core
/// Rule 6 / AC-CR6-1/6-2, Edge Case 6 / AC-EC6-1/6-2). Mounted via the
/// `'wardrobe'` overlay key (Story 003, ADR-0017); opened/closed
/// exclusively through [PetRoomGame.showModal]/[dismissModal] — never
/// mutates `game.overlays` directly (Story 003's forbidden pattern).
///
/// Deliberately a hand-built `Positioned`/`Align`-bottom sheet, not
/// Flutter's `showModalBottomSheet` — that API mounts via the `Navigator`,
/// entirely bypassing `game.overlays`/`showModal`/`.dismissModal`, which
/// Story 003's forbidden-pattern rule requires as the sole modal-mutation
/// path.
///
/// Item selection is display-only here — tapping a tile does nothing yet.
/// The equip transaction/callback is Pet Equipment #15's own future story
/// (this story's Out of Scope: "this story only hosts the Wardrobe UI
/// shell and item selection UI, not the equip transaction logic itself").
class PetRoomWardrobe extends ConsumerStatefulWidget {
  const PetRoomWardrobe({super.key, required this.game});

  final PetRoomGame game;

  static const sheetKey = Key('petRoomWardrobeSheet');
  static const closeButtonKey = Key('petRoomWardrobeClose');
  static const gridKey = Key('petRoomWardrobeGrid');
  static const shimmerKey = Key('petRoomWardrobeShimmer');
  static const errorKey = Key('petRoomWardrobeError');
  static const retryButtonKey = Key('petRoomWardrobeRetry');

  /// Key for the tab corresponding to [slot] — exposed so tests don't need
  /// to duplicate the `'petRoomWardrobeSlotTab_$slot'` string format.
  static Key slotTabKey(String slot) => Key('petRoomWardrobeSlotTab_$slot');

  /// Sheet height cap — GDD Visual/Audio Requirements / Control Manifest:
  /// "~60-65% of screen height", so Mochi's head/upper body stays visible
  /// above the sheet's edge while open. A single point value (like Story
  /// 006's `_EnergyBar.trackWidth`) from the middle of that range.
  static const heightFraction = 0.62;

  @override
  ConsumerState<PetRoomWardrobe> createState() => _PetRoomWardrobeState();
}

class _PetRoomWardrobeState extends ConsumerState<PetRoomWardrobe> {
  String _selectedSlot = _slots.first.slot;

  @override
  Widget build(BuildContext context) {
    // `game.size` (kept in sync every layout pass by Flame's own
    // `onGameResize`), NOT `MediaQuery.sizeOf(context)` — flame-widget-
    // specialist code review: this overlay's `Stack` is laid out within the
    // `GameWidget`'s own local box (the `Scaffold` body, below the
    // `AppBar`), while `MediaQuery.sizeOf` returns the full app-window
    // size regardless of nesting — confirmed empirically to differ by
    // `kToolbarHeight`. Using the wrong (larger) source here meant the
    // sheet rendered taller than the Control Manifest's ~60-65% cap
    // relative to the canvas actually visible below the AppBar (a real
    // ~68% in one measured case), eating into the headroom the cap exists
    // to protect (Mochi's head/upper body staying visible above the sheet).
    final screenHeight = widget.game.size.y;
    final catalogAsync = ref.watch(itemCatalogProvider);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.game.dismissModal,
            // Warm scrim — same Control Manifest rule as the context menu.
            child: ColoredBox(color: AppColors.primaryText.withValues(alpha: 0.22)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // Absorb taps on the sheet so they don't dismiss it.
            child: Container(
              key: PetRoomWardrobe.sheetKey,
              width: double.infinity,
              height: screenHeight * PetRoomWardrobe.heightFraction,
              decoration: const BoxDecoration(
                color: AppColors.creamIvory,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  _Header(onClose: widget.game.dismissModal),
                  _SlotTabs(
                    selectedSlot: _selectedSlot,
                    onSelect: (slot) => setState(() => _selectedSlot = slot),
                  ),
                  Expanded(
                    child: catalogAsync.when(
                      loading: () => const _ShimmerGrid(key: PetRoomWardrobe.shimmerKey),
                      error: (error, stackTrace) => _ErrorState(
                        key: PetRoomWardrobe.errorKey,
                        onRetry: () => ref.invalidate(itemCatalogProvider),
                      ),
                      data: (items) => _ItemGrid(
                        key: PetRoomWardrobe.gridKey,
                        items: items.where((item) => item.slot == _selectedSlot).toList(),
                      ),
                    ),
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

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tủ đồ',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            key: PetRoomWardrobe.closeButtonKey,
            icon: const Icon(Icons.close, color: AppColors.primaryText),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _SlotTabs extends StatelessWidget {
  const _SlotTabs({required this.selectedSlot, required this.onSelect});

  final String selectedSlot;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final s in _slots)
          _SlotTab(
            key: PetRoomWardrobe.slotTabKey(s.slot),
            icon: s.icon,
            label: s.label,
            selected: s.slot == selectedSlot,
            onTap: () => onSelect(s.slot),
          ),
      ],
    );
  }
}

class _SlotTab extends StatelessWidget {
  const _SlotTab({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryText : AppColors.disabledText;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// AC-EC6-1: shimmer/skeleton loading state — same static-colored-tile
/// technique as `child_profile_selection_screen.dart`'s `_ShimmerCard`
/// (no shimmer animation library in this project's dependencies).
class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: List.generate(
        6,
        (_) => Container(
          decoration: BoxDecoration(
            color: AppColors.cloudWhite,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// AC-EC6-2: inline error + retry — same pattern as
/// `child_profile_selection_screen.dart`'s `_ErrorState`.
class _ErrorState extends StatelessWidget {
  const _ErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.primaryText, size: 32),
          const SizedBox(height: 12),
          const Text(
            'Không tải được đồ',
            style: TextStyle(color: AppColors.primaryText),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: PetRoomWardrobe.retryButtonKey,
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lavenderSoft,
              foregroundColor: AppColors.primaryText,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({super.key, required this.items});

  final List<ItemModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có đồ nào ở đây',
          style: TextStyle(color: AppColors.secondaryText),
        ),
      );
    }
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [for (final item in items) _ItemTile(item: item)],
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});

  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cloudWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.checkroom, color: AppColors.primaryText, size: 28),
          const SizedBox(height: 4),
          Text(
            item.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.primaryText, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
