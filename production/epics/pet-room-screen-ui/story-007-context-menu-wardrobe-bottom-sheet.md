# Story 007: Tap-on-Mochi Context Menu & Wardrobe Bottom Sheet

> **Epic**: Pet Room Screen UI
> **Status**: Complete with Notes
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: 3-4h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-26

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

- [x] **AC-CR5-1**: GIVEN the context menu is open, WHEN bé taps "Vuốt ve", THEN the PLEASED trigger (#14) is called AND the menu closes immediately, no delay. — Implemented, verified.
- [x] **AC-CR5-2**: GIVEN the context menu is open, WHEN bé taps "Đóng", THEN the menu dismisses with no other action triggered. — Implemented, verified.
- [x] **AC-CR5-3**: GIVEN the context menu is open, WHEN bé taps "Thay đồ", THEN the menu closes immediately AND the Wardrobe bottom sheet begins opening — at no point are both modals mounted. — Implemented, verified.
- [x] **AC-CR6-1**: GIVEN the Wardrobe bottom sheet is open, THEN exactly 3 slot tabs display (icon + name) and the item grid shows items matching the selected `slot`, read from `itemCatalogProvider`. — Implemented, verified (all 3 slots individually proven, per qa-tester review).
- [x] **AC-CR6-2**: GIVEN Wardrobe is open, WHEN bé taps "Đóng" OR taps outside the sheet, THEN the sheet dismisses. — Implemented, verified.
- [x] **AC-EC6-1**: GIVEN `itemCatalogProvider` is in a loading state when Wardrobe opens, THEN the grid shows a skeleton/shimmer state — no crash, no empty-looking grid. — Implemented, verified.
- [x] **AC-EC6-2**: GIVEN `itemCatalogProvider` returns `AsyncError`, THEN the grid shows an inline error state ("Không tải được đồ — Thử lại" + retry button) — no crash, no empty-looking grid. — Implemented, verified (retry re-invocation proven via a build-count instrumented provider override, not just presence of the retry button).

**Known gap, not an AC of this story but found while implementing it — flagged by both code reviewers, not just documented in a code comment**: `game.showModal('context_menu')` has **no production call site anywhere in `src/lib/`**. This story's Dependencies/Out-of-Scope never assigned "what gesture opens the context menu" to it, and Pet Interaction epic's own already-ratified GDD (Core Rule 2, AC-1, BLOCKING) and ADR-0016 already bind a tap on Mochi's sprite directly to the PLEASED wiggle animation — a genuine, ratified conflict with this story's own GDD prose ("tap-on-Mochi mở context menu"). Resolving it requires either reopening ADR-0016's accepted tap semantics or inventing a new gesture (long-press is already earmarked for a different, deferred future interaction per `pet-interaction.md`). **As shipped, the context menu this story built is fully implemented and tested but unreachable by any real player action.** Needs a follow-up ADR/story to reconcile the two GDDs before this feature is actually playable.

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

**Status**: [x] Created — `tests/integration/pet-room-screen-ui/context_menu_wardrobe_test.dart`, 9 tests, all passing (`cd src && flutter test ../tests/integration/pet-room-screen-ui/context_menu_wardrobe_test.dart`).

---

## Dependencies

- Depends on: Story 001 (Formula 2 — context menu anchor reads `MochiComponent.size`/position), Story 003 (Flame Canvas Composition — needs `'context_menu'`/`'wardrobe'` overlay keys and `showModal`/`.dismissModal`)
- Unlocks: None

---

## Implementation Record

**Files created**:
- `src/lib/ui/pet_room_context_menu.dart` — `PetRoomContextMenu`, the 3-option speech-bubble-anchored context menu ("Thay đồ" / "Vuốt ve" / "Đóng").
- `src/lib/ui/pet_room_wardrobe.dart` — `PetRoomWardrobe`, the bottom-anchored Wardrobe sheet (3 slot tabs, item grid filtered by `ItemModel.slot`, loading shimmer / inline error + retry via `itemCatalogProvider.when()`).
- `tests/integration/pet-room-screen-ui/context_menu_wardrobe_test.dart` — 9 tests covering all 7 ACs.

**Files modified**:
- `src/lib/ui/pet_room_screen.dart` — `'context_menu'`/`'wardrobe'` overlays now build the real widgets above; the two dead Story 003 placeholder classes removed.
- `src/lib/gameplay/pet_room_game.dart` — removed a stale `@visibleForTesting` annotation on the `mochi` field. Its own doc comment already named "Story 007's context-menu content" as a sanctioned production consumer; the annotation was never removed when that consumer was actually written and tripped `invalid_use_of_visible_for_testing_member` the moment `pet_room_context_menu.dart` read `game.mochi` exactly as documented. flame-widget-specialist confirmed: the only non-test production reference is this story's own anchor-position read, and reading Flame render-geometry from an overlay widget is a standard integration pattern, not an ADR-0004 bridge violation.
- `tests/integration/pet-room-screen-ui/composition_and_modal_exclusivity_test.dart` (Story 003's own file) — two pre-existing tests updated since Story 007 replaced that story's placeholder overlay widgets with real content: one retargeted its tap coordinate from the overlay root's center (which hit Story 003's static decorative box) to `PetRoomContextMenu.cardKey` directly, since the real menu anchors near Mochi's position, not screen-center (the Control Manifest forbids a center-screen dialog here). The second ("tap the menu itself must not dismiss") was substantively rewritten: it originally tapped the card's geometric center, which — discovered via a throwaway diagnostic test — lands on a real button ("Vuốt ve", the middle option), correctly dismissing the menu as that button's own intended behavior, not a scrim-fallthrough bug. Retargeted to tap a `Divider` between menu options instead, isolating "does the card absorb a stray tap on its own body" from "does a specific button do its own thing." qa-tester independently confirmed this retarget is still meaningful and non-tautological.

**Code review — flame-widget-specialist**, 2 Required Changes found and fixed:
1. Both widgets read `MediaQuery.sizeOf(context)` for their layout math — the wrong size source. Confirmed via a real diagnostic test that `GameWidget`'s local box (`game.size`, kept in sync by Flame's own `onGameResize`) is `kToolbarHeight` shorter than `MediaQuery.sizeOf`, since the overlay lives inside the `Scaffold` body, below the `AppBar`. Concretely: Wardrobe was rendering at ~68% of the *actual visible* canvas height, not the Control Manifest's required ~60–65%, eating into the headroom meant to keep Mochi's head visible. Fixed: both widgets now read `game.size` instead of `MediaQuery.sizeOf(context)`.
2. `_MenuOption`'s tap target measured ~46dp tall, under `technical-preferences.md`'s stated 48×48dp minimum (this is a child-facing app, where this matters more). Fixed: wrapped in `ConstrainedBox(minHeight: 48)`.

Non-blocking: tightened `_onPet()`'s doc comment, which overstated directness — the emitted `petInteracted` event actually goes through Story 004's modal-defer/replay mechanism (since the context menu is itself an open modal at that moment), not straight to `_play()`; functionally still satisfies AC-CR5-1's "no delay" (same microtask-flush window), but a future reader debugging trigger timing shouldn't assume synchronous immediacy.

Both the `@visibleForTesting` removal and the decision to leave tap-on-Mochi gesture wiring unresolved (see Acceptance Criteria's "Known gap" note above) were independently confirmed correct by flame-widget-specialist.

**Code review — qa-tester**, 3 Required Changes found and fixed:
1. `context_menu_wardrobe_test.dart` was missing `GameEventBus().resetForTesting()` in `setUp` (the sibling Story 003 test file already establishes this pattern) — several tests snapshot/compare `peekLastEvent(petInteracted)` before/after a tap, and without a reset this relied on an implicit, fragile "no test before this one emitted this event type" invariant. Fixed: added the same `setUp`.
2. AC-CR6-1's slot-filtering test only positively proved 2 of 3 slots (`body_outfit` default + `hat` after tapping); `accessory` was only ever asserted absent, never asserted present-when-selected. Fixed: added the missing tap + assertions.
3. No test proved a tap on the Wardrobe sheet's own body (not a button) is absorbed rather than falling through to the scrim behind it — the identical construct as the context menu's card, and this exact fall-through failure mode is a previously-real, live-tested bug in this codebase (per `composition_and_modal_exclusivity_test.dart`'s own header comment). Fixed: added `test_tapOnSheetBody_doesNotFallThroughToScrim`.

Non-blocking suggestions not actioned (logged here, not silently dropped): `_ItemGrid`'s empty-list branch has no dedicated test; AC-CR6-1's literal "icon + name" wording isn't checked at the text/icon level, only `Key` presence; no invocation-count proof that `petInteracted` fires exactly once (no spy seam exists on the `GameEventBus` singleton); no rapid-double-tap coverage (Flutter's gesture arena/`InkWell` generally protects against this, no AC calls for it).

**Test results**: Full suite 608/608 passing (1 pre-existing unrelated skip). `flutter analyze`: 0 issues in any file this story touched (13 pre-existing unrelated `info`-level issues elsewhere, unchanged from baseline).

**No git commit made yet** — pending explicit user go-ahead per this project's established pattern.
