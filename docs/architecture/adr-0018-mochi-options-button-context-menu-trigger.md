# ADR-0018: Mochi Options Button as the Context Menu Trigger

## Status
Accepted (2026-07-27 — Lean review mode: Producer/TD/QA-lead director gates skipped per `production/review-mode.txt`. User-directed decision: keep ADR-0016's tap=PLEASED semantics unchanged; resolve via a new dedicated UI trigger rather than reopening ADR-0016 or repurposing a reserved future gesture.)

## Date
2026-07-27

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | UI (Flutter overlay widget layer — no new Flame input mixin, no change to `MochiComponent`'s gesture handling) |
| **Knowledge Risk** | LOW — a plain Flutter `IconButton`/`InkWell` inside an existing `GameWidget` overlay (`'chrome'` key, Story 006's already-established pattern). No new Flame API surface, no gesture-arena interaction to reason about. |
| **References Consulted** | `docs/architecture/adr-0016-pet-interaction-input-handling.md` (Accepted, unchanged by this ADR), `docs/architecture/adr-0017-pet-room-screen-rendering-interaction-contract.md` (Accepted, unchanged — this ADR is an additive extension of its `'chrome'`/`showModal` contract), `design/gdd/pet-interaction.md` (Core Rule 2, AC-1, Open Question #1), `design/gdd/pet-room-screen-ui.md` (Core Rule 5), `production/epics/pet-room-screen-ui/story-007-context-menu-wardrobe-bottom-sheet.md` (where this conflict was discovered) |
| **Post-Cutoff APIs Used** | None. |
| **Verification Required** | None beyond this project's standard widget-test coverage — no physical-device-specific behavior introduced. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0016 (Pet Interaction Input Handling, Accepted) — this ADR explicitly does NOT modify ADR-0016's Decision; it depends on that decision staying exactly as ratified (tap on Mochi's sprite → `petInteracted`/PLEASED, `DragCallbacks`-only, no `TapCallbacks`). ADR-0017 (Pet Room Screen Rendering & Interaction Contract, Accepted) — this ADR extends ADR-0017's `'chrome'` overlay and `showModal`/`dismissModal` contract, does not alter it. |
| **Enables** | Pet Room Screen UI Story 007's context menu becomes reachable by a real player action (it was implemented and tested, but had zero production callers before this ADR — see Story 007's own Implementation Record). |
| **Blocks** | None. |
| **Ordering Note** | This ADR owns exactly one thing: what UI element calls `PetRoomGame.showModal('context_menu')`. It does not own the context menu's own content/behavior (Story 007, already Complete), the modal mutual-exclusivity mechanism (ADR-0017), or Mochi's tap/swipe gesture classification (ADR-0016). |

## Context

### Problem Statement

Pet Room Screen UI Story 007 implemented and tested the context menu (`PetRoomContextMenu`) and Wardrobe sheet in full, but discovered during implementation that nothing in its own scope — nor any other story or ADR — ever wired up what triggers `game.showModal('context_menu')` in the first place. Two ratified sources make conflicting claims about this:

- `pet-interaction.md` Core Rule 2 + **AC-1 (BLOCKING)**: a tap on Mochi's sprite emits `GameEvent(petInteracted, InteractionType.tap)`, which Pet State Machine (#6) turns into the PLEASED wiggle animation. This is implemented, tested, and part of the already-Accepted ADR-0016.
- `pet-room-screen-ui.md`'s prose (Overview, Core Rule 5, pre-correction): "tap-on-Mochi mở context menu" ("tap-on-Mochi opens the context menu").

Both cannot be true of the same gesture. As shipped before this ADR, tapping Mochi always runs the PLEASED path (ADR-0016's real, tested behavior) — the context menu had no reachable trigger at all. Both flame-widget-specialist and qa-tester flagged this as a real product gap during Story 007's code review, not just a documentation inconsistency.

### Constraints
- Must not reopen or modify ADR-0016's Decision — it is Accepted, implemented, and tested across 5 completed Pet Interaction epic stories. The user directed: keep tap=PLEASED unchanged.
- Must not repurpose long-press — `pet-interaction.md`'s own Open Question #1 explicitly reserves long-press for a possible future "3rd interaction" ("ôm Mochi" / hug Mochi), deferred past MVP, owned by Game Designer. Using it here would collide with that reservation and would itself require reopening design discussion this ADR is not chartered to have.
- Must not add a second gesture mixin (e.g. `TapCallbacks` alongside `DragCallbacks`) to `MochiComponent` — ADR-0016 Decision §1 explicitly rejected combining `TapCallbacks` and `DragCallbacks` on the same component due to a documented, flame-specialist-confirmed gesture-arena conflict (the drag recognizer tends to claim the pointer before the tap recognizer resolves fairly). Any new on-canvas gesture on Mochi risks reintroducing exactly that conflict.
- Must go through `PetRoomGame.showModal('context_menu')` — the sole sanctioned mutation path for the `context_menu`/`wardrobe` overlay keys (ADR-0017's forbidden-pattern rule, unchanged).
- Child-facing app: the trigger must be reliably discoverable and performable by a young child — favor a persistent, visible affordance over a gesture that has to be learned or held for a duration.

## Decision

Introduce a small, persistent, always-visible **"Mochi Options" icon button** — a plain Flutter overlay widget, not a new Flame gesture — as the sole sanctioned trigger for `PetRoomGame.showModal('context_menu')`. Mochi's own tap/swipe handling (ADR-0016) is completely untouched.

### Why a dedicated button over the alternatives

| Option | Verdict | Reason |
|---|---|---|
| Reuse tap-on-Mochi | Rejected | Already bound to PLEASED by Accepted, tested ADR-0016; reassigning it means reopening that ADR and breaking 5 completed stories' worth of tested behavior. User explicitly ruled this out. |
| Long-press on Mochi | Rejected | Reserved by `pet-interaction.md`'s Open Question #1 for a distinct, not-yet-designed future interaction ("ôm Mochi"). Repurposing it here would collide with that reservation and pre-empt a Game Designer decision that hasn't happened. |
| A second gesture mixin (`TapCallbacks` + `DragCallbacks`) | Rejected | ADR-0016 Decision §1 already identified and rejected exactly this combination due to a real, confirmed gesture-arena conflict. Reintroducing it here would risk the same unreliable/double-fired input ADR-0016 was written to avoid. |
| Dedicated UI button | **Accepted** | Zero interaction with Mochi's own gesture handling — no gesture-arena risk, no ADR-0016 change. A visible, persistent, tap-once affordance is more reliably discoverable and performable by a young child than a hidden or timing-dependent gesture (long-press). Matches this project's existing pattern of Flutter overlay widgets living alongside the Flame canvas (Story 006's status row, Story 007's context menu/Wardrobe themselves). |

### Key Interfaces

```dart
/// Small, persistent, always-visible icon button — the sole trigger for
/// opening the context menu. Mounted as part of the 'chrome' overlay
/// (alongside PetRoomStatusRow, Story 006), anchored near Mochi's
/// position/size (same technique PetRoomContextMenu's own speech-bubble
/// anchor already uses) so it stays spatially associated with Mochi per
/// the GDD's own "context menu is ABOUT Mochi" framing (Visual/Audio
/// Requirements).
class MochiOptionsButton extends StatelessWidget {
  const MochiOptionsButton({super.key, required this.game});
  final PetRoomGame game;

  // onTap: game.showModal('context_menu') — direct call, the same
  // sanctioned path Story 007's own menu options already use.
}
```

Mounted in `pet_room_screen.dart`'s `'chrome'` overlay builder, alongside `PetRoomStatusRow` (not inside it — `PetRoomStatusRow`'s own scope is mood/energy only, per Story 006's Acceptance Criteria; this button is a separate, independently-testable widget in the same overlay slot).

### Architecture Diagram

```
'chrome' overlay (always mounted, Story 003/006)
  ├── PetRoomStatusRow        (mood icon + energy bar — Story 006, unchanged)
  └── MochiOptionsButton      (NEW, this ADR)
        onTap → game.showModal('context_menu')   (ADR-0017's sanctioned path, unchanged)

MochiComponent (Flame canvas, DragCallbacks-only — ADR-0016, UNCHANGED)
  tap  → petInteracted(tap)   → PLEASED animation
  swipe → petInteracted(swipe) → PLEASED animation (spin variant)
```

## Alternatives Considered

### Alternative 1: Reuse tap-on-Mochi for the context menu
- **Description**: Repurpose Mochi's own tap gesture to open the context menu instead of (or before) triggering PLEASED.
- **Pros**: Matches the GDD's original (pre-correction) prose without a code-side UI addition.
- **Cons**: Directly contradicts ADR-0016's Accepted Decision and `pet-interaction.md`'s own BLOCKING AC-1; would require re-testing/re-validating 5 already-Complete Pet Interaction epic stories.
- **Rejection Reason**: User explicitly directed keeping tap=PLEASED unchanged.

### Alternative 2: Long-press on Mochi
- **Description**: Add a long-press gesture recognizer to `MochiComponent`, distinct from the existing tap/swipe classification, to open the context menu.
- **Pros**: Keeps the interaction "on Mochi" spatially, no new persistent UI element.
- **Cons**: Collides with `pet-interaction.md`'s Open Question #1 (long-press reserved for a future "hug Mochi" interaction, not yet designed); requires new gesture-recognizer wiring on `MochiComponent` with its own gesture-arena risk relative to the existing `DragCallbacks`-only design; less discoverable/reliable for young children than a visible button (a long-press has no visual affordance and requires sustained, accurate contact).
- **Rejection Reason**: Pre-empts an undesigned future decision and reintroduces gesture-arena risk ADR-0016 deliberately avoided.

### Alternative 3: Dedicated Mochi Options button (chosen)
- **Description**: See Decision above.
- **Pros**: Zero risk to ADR-0016's tested behavior, no gesture-arena interaction, highly discoverable/reliable for a child-facing app, consistent with this epic's existing Flutter-overlay-widget pattern.
- **Cons**: Adds a small always-visible UI element near Mochi that wasn't in the original visual design; needs a `/asset-spec`-level icon choice at some point (placeholder `Icons.more_horiz` acceptable for MVP, matching this epic's other interim-placeholder precedents, e.g. Mochi's own interim sprite in Story 003).
- **Rejection Reason**: None — accepted.

## Consequences

### Positive
- Pet Room Screen UI Story 007's context menu becomes reachable by a real player action for the first time.
- ADR-0016's tap=PLEASED behavior, and all 5 completed Pet Interaction epic stories built on it, remain completely untouched — zero regression risk to already-tested code.
- `pet-interaction.md`'s Open Question #1 (long-press as a future "3rd interaction") remains available for Game Designer to design later, unconstrained by this decision.

### Negative
- A new small persistent UI element must be added to the 'chrome' overlay — a minor addition to the screen's visual composition beyond what Story 006 originally specified (mood/energy status row + level bar only).
- The GDD's own icon/visual design for this button is not yet spec'd at the Art Bible level (interim `Icons.more_horiz` placeholder, consistent with this epic's precedent of shipping interim visuals pending a dedicated asset pass).

### Risks
- **Risk**: A future contributor unaware of this ADR might try to "restore" tap-on-Mochi as the context-menu trigger, reintroducing the conflict. *Mitigation*: this ADR, plus the corrected GDD prose (Core Rule 5, Overview) and `PetRoomContextMenu`'s/`MochiOptionsButton`'s own doc comments, all cross-reference this decision explicitly.
- **Risk**: The button's placement (anchored near Mochi's current, not-yet-55%-positioned location — see Story 007's own noted gap that Mochi's true vertical anchor isn't implemented by any story yet) may need revisiting once that placement work happens. *Mitigation*: documented as a known follow-on, not a regression this ADR introduces.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| `pet-room-screen-ui.md` | Core Rule 5 (context menu) — corrected prose: menu opens via a dedicated button, not tap-on-Mochi | Defines the `MochiOptionsButton` widget and its `showModal('context_menu')` call as the sanctioned trigger |
| `pet-interaction.md` | Core Rule 2 / AC-1 (tap → PLEASED) — left fully intact | This ADR makes no change to Mochi's gesture handling; explicitly documents why, so the two GDDs no longer conflict |

## Performance Implications
- **CPU**: Negligible — one additional static Flutter widget in an already-mounted overlay, no new Flame component, no new per-frame work.
- **Memory**: Negligible.
- **Load Time**: None.
- **Network**: None.

## Migration Plan
Additive only — no existing code path is removed or changed. `pet_room_screen.dart`'s `'chrome'` overlay builder gains a second child widget alongside the existing `PetRoomStatusRow`. `MochiComponent`/ADR-0016 are untouched.

## Validation Criteria
- A widget test proves tapping `MochiOptionsButton` calls `game.showModal('context_menu')` and the menu becomes reachable.
- A widget test proves tapping Mochi's sprite still triggers PLEASED (regression guard — already covered by Pet Interaction epic's own existing suite; this ADR does not need a new test for that side, only to confirm it doesn't touch that code path).
- `flutter analyze` clean, full suite green.

## Related Decisions
- ADR-0016: Pet Interaction Input Handling (Accepted, unchanged, depended upon)
- ADR-0017: Pet Room Screen Rendering & Interaction Contract (Accepted, unchanged, extended)
- `production/epics/pet-room-screen-ui/story-007-context-menu-wardrobe-bottom-sheet.md` — where this gap was discovered and documented
