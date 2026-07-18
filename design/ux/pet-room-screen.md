# UX Spec: Pet Room Screen

> **Status**: Started (skeleton + objective sections) — 2026-07-08
> **Author**: [ux-designer + user]
> **Last Updated**: 2026-07-08
> **Journey Phase(s)**: [unknown — no `design/player-journey.md` yet]
> **Template**: UX Spec
> **Source GDD**: `design/gdd/pet-room-screen-ui.md` (#18); also pet-state-machine #6, pet-interaction #14, pet-equipment #15, time-decay #2, currency #7, bridge #5
>
> ⚠️ This spec is **started, not complete**. The objective/GDD-derived sections below are pre-filled; sections marked **[To be designed — collaborative]** need the creative director (you) and should be authored via `/ux-design pet-room-screen` section-by-section. Do NOT treat the filled sections as final aesthetic decisions.

---

## Purpose & Player Need
The child's home base and the emotional core of the game: see Mochi, feel its mood (a mirror of their real-world effort — Pillar 2), interact with it (pet/swipe), and see equipped items. The player arrives wanting to *check on and connect with Mochi*. If this screen is dull or unresponsive, the entire emotional feedback loop collapses. (Derived from pet-room-screen-ui #18 + pet-state-machine #6 Player Fantasy.)

## Player Context on Arrival
Voluntary and frequent — the daily ritual (open app → PIN → Pet Room). Emotional state: calm/curious, sometimes anticipatory (after submitting a task, waiting for approval → Mochi celebration). Never time-pressured (no timers — accessibility §4). Arrives from PIN entry (cold start) or by tab switch from Tasks/Shop.

## Navigation Position
`[root] → Child shell (StatefulShellRoute) → Pet Room tab (default/home tab)`. Always reachable as a top-level tab (P13). Also the auto-navigate target of "Mặc ngay" after equip-from-Shop (P14) and the destination of level-up/celebration ceremonies.

## Entry & Exit Points
| Entry Source | Trigger | Player carries |
|---|---|---|
| PIN entry (cold start) | correct PIN → childSelected | activeChild scope |
| Tasks / Shop tab | bottom-nav tab tap (branch preserved) | — |
| Shop "Mặc ngay" | post-equip auto-navigate (P14) | just-equipped item visible |
| Level-up / chest ceremony | ceremony completes | new level/evolution sprite |

| Exit Destination | Trigger | Notes |
|---|---|---|
| Tasks / Shop tab | bottom-nav tab tap | branch NOT disposed (P13) |
| Parent Dashboard | long-press avatar → override (P3) | child session preserved |

## Layout Specification
**[To be designed — collaborative]** — information hierarchy, layout zones, component inventory, ASCII wireframe. Known fixed content to place (from GDDs): the Flame `GameWidget` canvas (Mochi + background + ≤3 equipment overlays = 5 draw calls, ADR-0001), a mood indicator (icon, no text — #6), an energy bar (fill %, never red — #2/§2), the xu wallet (P12, app-bar), and entry to the Wardrobe (P3 bottom sheet, modal-exclusive with any context menu). Aesthetic/zone arrangement is the creative director's call.

## States & Variants
**[To be designed — collaborative]** — must cover: 5 Base Moods (HAPPY/CONTENT/TIRED/SAD/SLEEPING) × triggered animations; cold-start loading (P5 skeleton); `itemCatalogProvider` AsyncError (retry inline — #18 Edge Case 6); evolution-stage sprite (pure function of petLevel — ADR-0007).

## Interaction Map
**[To be designed — collaborative]** — touch-only. Known: tap/swipe on Mochi (P9, cooldowns 1.0s/2.0s, ≥80dp hit-area); tap Wardrobe → bottom sheet (P3); tab switches (P13). Map immediate feedback + outcome per control.

## Events Fired
Consumes (not fires) via `GameEventBus` (P9/ADR-0004): subscribes petMoodChanged, taskApproved→EXCITED, itemEquipped→SHOWING_OFF, seedReceived→BOUNCING, petLeveledUp→LEVELING_UP. Emits: petInteracted (from tap/swipe). **[Analytics events: To be designed]**.

## Transitions & Animations
**[To be designed — collaborative]** — screen enter/exit; triggered-state animations (durations from #6: EXCITED 1.5s, PLEASED 2s, SHOWING_OFF 2s, BOUNCING 1s, LEVELING_UP 3s non-interruptible). **Must define reduced-motion variants** (accessibility §6).

## Data Requirements
| Data | Source System | Read/Write | Notes |
|---|---|---|---|
| currentEnergy | Time & Decay #2 (`energyProvider`) | Read | pure calc, on-foreground |
| Base Mood | Pet State Machine #6 (`petMoodProvider`) | Read | derived from energy |
| equippedItems | Pet Equipment #15 | Read | Map<slot,itemId> |
| item assetId/slot | Item Catalog #3 (`itemCatalogProvider`) | Read | cached get() |
| xuBalance | Currency #7 (`xuBalanceProvider`) | Read | realtime, display-clamped |
| petLevel / evolution | Pet Leveling #16 | Read | evolution = f(petLevel) |
Read-only screen — no writes except interaction events (one-way to Flame, P9). No UI-owned game state (ADR-0004 forbids Flame→Flutter).

## Accessibility
Inherits the Kid-Touch Baseline (`design/accessibility-requirements.md`): ≥80dp Mochi hit-area; mood/energy communicated by icon+fill not color (no red); no timers; reduced-motion variants for animations; no hover. **[Per-element focus/contrast pass: To be designed with the layout.]**

## Localization Considerations
**[To be designed — collaborative]** — minimal text on this screen (mood is iconographic). Watch the xu counter number formatting and any Wardrobe labels.

## Acceptance Criteria
**[To be designed — collaborative]** — must include (per skill minimums): a load-time criterion, a tab-switch-preserves-state criterion (P13), an empty/error state (itemCatalog AsyncError), an accessibility criterion (≥80dp hit-area), and a core-purpose criterion (mood animation matches energy within one frame — #6 AC). Cross-reference #18's existing acceptance criteria.

## Open Questions
- Player journey map not yet created (`design/player-journey.md`) — journey phase/emotional context assumed. Template at `.claude/docs/templates/player-journey.md`.
- Mochi sprite sizes per evolution stage are provisional pending Art Bible §5 (#18 Open Question).
- Run `/ux-design pet-room-screen` to author the collaborative sections, then `/ux-review pet-room-screen`.
