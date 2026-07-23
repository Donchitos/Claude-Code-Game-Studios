# Story 007: Tap-on-Mochi Context Menu & Wardrobe Bottom Sheet

> **Epic**: Pet Room Screen UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: 3-4h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-23

## Context

**GDD**: `design/gdd/pet-room-screen-ui.md`
**Requirement**: `TR-petroom-001` (modal-content half — the `'context_menu'`/`'wardrobe'` overlay key contract itself is Story 003's scope; this story fills them with real content)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: Pet Room Screen Rendering & Interaction Contract (Decision → TR-petroom-001, `'context_menu'`/`'wardrobe'` overlays) + ADR-0016 (Pet Interaction — `petInteracted`/PLEASED trigger this menu's "Vuốt ve" option calls).
**ADR Decision Summary**: Context menu and Wardrobe are both Flutter overlay widgets (not Flame components), opened/closed exclusively via `PetRoomGame.showModal()`/`.dismissModal()` (Story 003) — at no point are both mounted simultaneously. "Thay đồ" closes the menu immediately, then opens Wardrobe (still no overlap). "Vuốt ve" triggers Pet Interaction's PLEASED state directly and closes the menu immediately, with no delay.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: LOW-MEDIUM
**Engine Notes**: Pure Flutter widget work above the Flame canvas — no new Flame component, no draw-call budget impact. Context menu's anchor position reads `MochiComponent`'s position/size (Story 001's `size` output) to place its speech-bubble "tail" toward Mochi. Wardrobe's grid content reads `itemCatalogProvider` (Item Database #3).

**Control Manifest Rules (this layer)**:
- Required: warm scrim (`#3D2B1F` at ~20-25% opacity), never a standard black/dark scrim — direct consequence of the Art Bible's dark-vignette/harsh-shadow ban (source: GDD Visual/Audio Requirements, Art Bible Section 2).
- Required: Wardrobe sheet height capped at ~60-65% of screen height — Mochi's head/upper body must remain visible above the sheet's edge while open (source: GDD Visual/Audio Requirements; enables Pet Equipment's AC-1 outfit-overlay-update-in-1-frame to be observable live).
- Forbidden: a dialog rendered center-screen for the context menu — must anchor to Mochi's position (speech-bubble style), not use a generic centered dialog (source: GDD Visual/Audio Requirements).
- Forbidden: calling `game.overlays.add`/`.remove` on `'context_menu'`/`'wardrobe'` directly from this story's widgets — must go through `PetRoomGame.showModal`/`.dismissModal` (source: Story 003, ADR-0017).

---

## Acceptance Criteria

*From GDD `design/gdd/pet-room-screen-ui.md`, scoped to this story:*

- [ ] **AC-CR5-1**: GIVEN the context menu is open, WHEN bé taps "Vuốt ve", THEN the PLEASED trigger (#14) is called AND the menu closes immediately, no delay.
- [ ] **AC-CR5-2**: GIVEN the context menu is open, WHEN bé taps "Đóng", THEN the menu dismisses with no other action triggered.
- [ ] **AC-CR5-3**: GIVEN the context menu is open, WHEN bé taps "Thay đồ", THEN the menu closes immediately AND the Wardrobe bottom sheet begins opening — at no point are both modals mounted.
- [ ] **AC-CR6-1**: GIVEN the Wardrobe bottom sheet is open, THEN exactly 3 slot tabs display (icon + name) and the item grid shows items matching the selected `slot`, read from `itemCatalogProvider`.
- [ ] **AC-CR6-2**: GIVEN Wardrobe is open, WHEN bé taps "Đóng" OR taps outside the sheet, THEN the sheet dismisses.
- [ ] **AC-EC6-1**: GIVEN `itemCatalogProvider` is in a loading state when Wardrobe opens, THEN the grid shows a skeleton/shimmer state — no crash, no empty-looking grid.
- [ ] **AC-EC6-2**: GIVEN `itemCatalogProvider` returns `AsyncError`, THEN the grid shows an inline error state ("Không tải được đồ — Thử lại" + retry button) — no crash, no empty-looking grid.

---

## Implementation Notes

*Derived from GDD Core Rules 5-6, Edge Case 6, and Visual/Audio Requirements:*

- Context menu: 3 options — "Thay đồ" (`showModal('context_menu')` → immediately `showModal('wardrobe')`, never both mounted since `showModal` itself enforces exclusivity), "Vuốt ve" (call the Pet Interaction PLEASED trigger path directly, then `dismissModal()`), "Đóng" (`dismissModal()`, no other action).
- Context menu placement: anchored at Mochi's canvas position (speech-bubble card with a "tail" pointing to Mochi), positioned relative to the current vertical anchor (55% from top per Tuning Knobs) — not a generic center-screen dialog.
- Wardrobe: 3 slot tabs (`body_outfit`, `hat`, `accessory`, per Pet Equipment #15's 3-slot model) + item grid for the selected slot, sourced from `itemCatalogProvider`'s `category`/`slot`/`source` fields. Height capped ~60-65% of screen height so Mochi's head remains visible above the sheet.
- Scrim for both modals: warm dark brown `#3D2B1F` at ~20-25% opacity — never a standard black scrim.
- Loading/error states (Edge Case 6) apply to the Wardrobe grid specifically — shimmer placeholder tiles for loading, inline error card + retry button for `AsyncError` (retry re-invokes the provider, does not crash or close the sheet).
- All open/close transitions go through `PetRoomGame.showModal()`/`.dismissModal()` (Story 003) — this story's widgets call those methods, never `game.overlays.add`/`.remove` directly.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: the `'context_menu'`/`'wardrobe'` overlay key contract and `showModal`/`.dismissModal` mutual-exclusivity mechanism itself.
- Story 001: `MochiComponent`'s `size`/position this story's context-menu anchor reads — this story only consumes that output.
- Story 004: the `modalVisibilityChanged` event emission around `showModal`/`.dismissModal` calls — this story's widgets call `showModal`/`.dismissModal`, Story 004 wires what happens on the Flame side as a result.
- Pet Equipment #15's own equip-callback/SHOWING_OFF-trigger implementation (no epic yet) — this story only hosts the Wardrobe UI shell and item selection UI, not the equip transaction logic itself.
- Pet Interaction #14's own PLEASED-trigger implementation — this story only calls it from "Vuốt ve", it doesn't implement it.

---

## QA Test Cases

*Concrete test cases (lean review mode — written directly into the story, no qa-lead gate spawned per `production/review-mode.txt`).*

- **AC-CR5-1**: Given the context menu open — When: "Vuốt ve" tapped — Then: assert the PLEASED-trigger call site fired exactly once AND `game.overlays.value` no longer contains `'context_menu'`, both within the same frame/no artificial delay.
- **AC-CR5-2**: Given the context menu open — When: "Đóng" tapped — Then: assert `'context_menu'` removed from overlays and no PLEASED-trigger/Wardrobe-open call occurred.
- **AC-CR5-3**: Given the context menu open — When: "Thay đồ" tapped — Then: assert `'context_menu'` is removed and `'wardrobe'` is added, and at no intermediate `overlays.value` snapshot do both keys appear together.
- **AC-CR6-1**: Given Wardrobe open with `itemCatalogProvider` returning a populated catalog — When: pumped — Then: assert exactly 3 slot tab widgets found, and the grid shows only items whose `slot` matches the currently selected tab.
- **AC-CR6-2**: Given Wardrobe open — When: "Đóng" tapped, and separately, a tap registered outside the sheet's bounds — Then: assert `'wardrobe'` removed from overlays in both cases.
- **AC-EC6-1**: Given `itemCatalogProvider` overridden to an `AsyncLoading` state — When: Wardrobe opens — Then: assert shimmer/skeleton placeholder widgets are found, no exception thrown, grid is not empty-looking.
- **AC-EC6-2**: Given `itemCatalogProvider` overridden to `AsyncError` — When: Wardrobe opens — Then: assert the inline error text + retry button are found; tapping retry re-invokes the provider without closing the sheet or throwing.

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/pet-room-context-menu-wardrobe-evidence.md` (manual walkthrough) OR `tests/integration/pet-room-screen-ui/context_menu_wardrobe_test.dart` (interaction test) — advisory gate per `coding-standards.md`'s Testing Standards table (UI stories are ADVISORY), automated widget test preferred given the mechanically-checkable assertions above.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (Formula 2 — context menu anchor reads `MochiComponent.size`/position), Story 003 (Flame Canvas Composition — needs `'context_menu'`/`'wardrobe'` overlay keys and `showModal`/`.dismissModal`)
- Unlocks: None
