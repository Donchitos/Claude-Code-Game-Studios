# Story 004: Modal Defer for Wardrobe / Competing GameEvent

> **Epic**: Pet Room Screen UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: 2-3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-23

## Context

**GDD**: `design/gdd/pet-room-screen-ui.md`
**Requirement**: `TR-petroom-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: Pet Room Screen Rendering & Interaction Contract (Decision → TR-petroom-004) + ADR-0004 (Flutter-Flame Event Bridge — one-way bridge contract being extended) + ADR-0007 (Pet State Machine — existing triggered-state priority/queue logic being extended, not replaced).
**ADR Decision Summary**: Adds `GameEventType.modalVisibilityChanged` (payload: `bool`, `true` = a modal just opened, `false` = closed), emitted from the exact call sites that call `PetRoomGame.showModal()`/`.dismissModal()` (Story 003). `MochiComponent` subscribes to it, tracks `_modalOpen` + one pending-visual slot (`_pendingVisual`), and gates `onTrigger()`: while a modal is open, do not play/queue as normal — instead keep only the highest-priority pending trigger in `_pendingVisual` (reusing the same priority comparison `_queueHighest` already uses) and replay it via `onTrigger` once the modal closes. Still strictly one-way Flutter→Flame — no new reverse-direction case (the only sanctioned one remains `petInteracted`, ADR-0004 §3b).

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: MEDIUM
**Engine Notes**: This mechanism is scoped to **any** open modal (context menu or Wardrobe), not just Wardrobe — deliberately safer and no extra cost. `_pendingVisual` (this story) and `_queued` (ADR-0007's existing LEVELING_UP-interrupt queue) are independent gates that never need to interact directly — being inside a non-interruptible LEVELING_UP animation and having a modal open are checked at different points in the same `onTrigger` method.

**Control Manifest Rules (this layer)**:
- Required: Never subscribe to `GameEventBus` in a Flame component's `onLoad()` — always `onMount()`, with an `isMounted` guard and `.cancel()` in `onRemove()` (source: ADR-0004, reaffirmed ADR-0007) — `MochiComponent` already follows this pattern via `GameEventSubscriber`; this story only adds one new subscribed event type, not a new subscription mechanism.
- Required: `GameEventBus` payload-per-type switch discipline — switch on `event.type` before casting `event.data` (source: ADR-0004).
- Forbidden: a second reverse-direction (Flame→Flutter) bridge case — this story's event is Flutter→Flame only (source: ADR-0004 §3b, ADR-0017 Alternative 4).
- Forbidden: a Flame component reading Riverpod/`ProviderContainer` directly, e.g. as an alternative mechanism to the event (source: ADR-0004, ADR-0007; ADR-0017 Alternative 4 explicitly rejects this for this exact case).

---

## Acceptance Criteria

*From GDD `design/gdd/pet-room-screen-ui.md`, scoped to this story:*

- [ ] **AC-EC4-1**: GIVEN the Wardrobe bottom sheet is open, WHEN `petLeveledUp` (or a similar `GameEvent`) fires via `GameEventBus`, THEN Pet State Machine's internal state updates immediately (verified via provider/state value, not just UI) — but no animation/sprite-swap visual appears layered over the Wardrobe sheet.
- [ ] **AC-EC4-2**: GIVEN the same situation as AC-EC4-1, WHEN Wardrobe closes, THEN the visual (e.g. LEVELING_UP animation) plays reflecting the state that was updated while the modal was open — no event lost, no wrong-state animation.

---

## Implementation Notes

*Derived from ADR-0017 Decision → TR-petroom-004:*

- Extend `GameEventType` (`src/lib/core/game_event_bus.dart`) with one new member: `modalVisibilityChanged` (payload: `bool`).
- Emit from the exact call sites that call `PetRoomGame.showModal()`/`.dismissModal()` (Story 003):
  ```dart
  GameEventBus().emit(GameEvent(GameEventType.modalVisibilityChanged, true));
  showModal(overlayKey);
  // ...
  dismissModal();
  GameEventBus().emit(GameEvent(GameEventType.modalVisibilityChanged, false));
  ```
- `MochiComponent`: add `modalVisibilityChanged` to `subscribedEventTypes`; add a `bool _modalOpen` field and a `TriggeredState? _pendingVisual` field:
  ```dart
  case GameEventType.modalVisibilityChanged:
    _modalOpen = event.data as bool;
    if (!_modalOpen && _pendingVisual != null) {
      final t = _pendingVisual!;
      _pendingVisual = null;
      onTrigger(t);
    }
  ```
- `onTrigger` gains one new guard at its top: if `_modalOpen == true`, do not call `_play`/`_queueHighest` — instead keep only the highest-priority pending trigger (same `triggeredStatePriority` comparison `_queueHighest` already uses) in `_pendingVisual`, then return.
- Add a required doc comment on the `modalVisibilityChanged` payload clarifying it means "is a modal open within Pet Room", not "is Pet Room screen itself visible" (regression guard called out in ADR-0017 Consequences → Negative).
- **Concurrency note**: like Story 001, this story edits `src/lib/gameplay/mochi_component.dart` and may overlap with Pet Interaction Story 001's concurrent edits and/or this epic's own Story 001 (Formula 2, which also migrates the base class). Re-read the file fresh immediately before editing; if Story 001 has already landed its `SpriteComponent` migration, build on top of it rather than reverting to `PositionComponent`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: the `showModal`/`dismissModal` methods themselves and the overlay-key contract — this story only adds event emission around those existing call sites.
- Story 007: the actual Wardrobe bottom sheet / context menu widget content that calls `showModal`/`dismissModal` — this story only wires the event, not the UI that triggers it.
- ADR-0007's existing `_queued`/LEVELING_UP-interrupt logic — extended (new guard added), not replaced or refactored.

---

## QA Test Cases

*Concrete test cases (lean review mode — written directly into the story, no qa-lead gate spawned per `production/review-mode.txt`).*

- **AC-EC4-1**: Given a `MochiComponent` in a mounted `FlameGame` test harness (`testWithFlameGame`) with `_modalOpen` driven `true` via `GameEventBus().emit(GameEvent(modalVisibilityChanged, true))` — When: `GameEventBus().emit(GameEvent(petLeveledUp, ...))` fires — Then: assert `MochiComponent.currentTriggeredState` stays `null` (no visual played) AND `queuedTriggeredState`/`_pendingVisual`-equivalent test accessor reflects `TriggeredState.levelingUp` pending. Edge cases: a second, lower-priority trigger arriving while modal is open must not overwrite a higher-priority pending one (reuses `_queueHighest`'s existing priority-comparison test coverage pattern).
- **AC-EC4-2**: Given the state from AC-EC4-1 (modal open, `LEVELING_UP` pending) — When: `GameEventBus().emit(GameEvent(modalVisibilityChanged, false))` fires — Then: assert `MochiComponent.currentTriggeredState == TriggeredState.levelingUp` (the pending visual now plays) and the pending slot is cleared.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/pet-room-screen-ui/modal_defer_triggered_visuals_test.dart` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (Flame Canvas Composition & Modal Mutual Exclusivity — needs `showModal`/`dismissModal` to exist as emission call sites)
- Unlocks: None
