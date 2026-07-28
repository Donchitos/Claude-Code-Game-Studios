// Pure design-time arithmetic contract (GDD Formula 1, ADR-0001 Draw-Call
// Budget Scope) — not a live render-tree measurement. No Flutter, no Flame,
// mirroring `hit_area_formula.dart`'s / `compute_energy.dart`'s pattern.
//
// ADR-0001 scopes the ≤200 draw-call budget to the Flame canvas only
// (post-`SpriteBatch` `SpriteComponent`-level render calls); Flutter overlay
// compositing (chrome, context menu, Wardrobe) is governed separately and
// must never be folded into this count.

/// 1 mounted `RoomBackgroundComponent` (Story 003).
const int kDrawCallsBackground = 1;

/// 1 mounted `MochiComponent` base sprite (Story 003).
const int kDrawCallsMochiBase = 1;

/// Pet Equipment #15's 3 always-mounted slots (`body_outfit`, `hat`,
/// `accessory`) — each slot is always 1 `SpriteComponent`, even holding the
/// default/"none" item, so this is a fixed constant, not a function of what
/// (if anything) is equipped.
const int kEquipmentSlotCount = 3;

/// GDD Formula 1: `drawCalls_sceneFlame = drawCalls_background +
/// drawCalls_mochiBase + slotCount`. Deliberately takes no "equipped items"
/// parameter — AC-F1-2's equip/unequip independence is proven by this
/// signature alone, not by a separate runtime check.
int computeSceneFlameDrawCalls({
  int drawCallsBackground = kDrawCallsBackground,
  int drawCallsMochiBase = kDrawCallsMochiBase,
  int slotCount = kEquipmentSlotCount,
}) =>
    drawCallsBackground + drawCallsMochiBase + slotCount;
