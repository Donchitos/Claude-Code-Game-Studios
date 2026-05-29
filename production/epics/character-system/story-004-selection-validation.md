# Story 004: Server-Side Character Selection Validation

> **Epic**: Character System
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: XS
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/character-system.md`
**Requirement**: `TR-char-???`

**ADR Governing Implementation**: ADR-0013: Progression & Ability Unlock Gating; ADR-0012: Session & Match Lifecycle
**ADR Decision Summary**: `character_confirmed` socket event triggers DeckLoadoutValidator; invalid selection → `validation_error` emitted to player; player can re-confirm within the character select window.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] Valid character + valid deck → `character_confirmed` accepted; player recorded in session
- [ ] Character not in player's entitlements → `CHARACTER_NOT_OWNED` validation error returned
- [ ] Character not in active roster (excluded at startup) → selection rejected
- [ ] Slot 2 ability requires XP unlock; if not unlocked → `SLOT2_LOCKED` error returned
- [ ] Player can re-submit `character_confirmed` with corrected selection within the 30-second window

---

## Implementation Notes

- Socket handler: `socket.on('character_confirmed', async ({ characterId, deckSlots }) => { ... })`
- Validation sequence:
  1. `CharacterSystem.getAvailability(userId, characterId)` → must be true
  2. `DeckLoadoutValidator.validate(userId, characterId, deckSlots)` → must return `{ valid: true }`
  3. If valid: `sessionManager.onCharacterConfirmed(matchId, userId, characterId, deckSlots)`
  4. If invalid: `socket.emit('validation_error', { code, message })`
- Multiple `character_confirmed` events allowed within the 30s window; last valid one wins

---

## QA Test Cases

- **AC-valid**: Valid selection accepted
  - Given: Player owns character:vex; valid deck [ability:fireball, ability:shield]
  - When: `character_confirmed { characterId: 'character:vex', deckSlots: [...] }` emitted
  - Then: Session records Vex + deck for player; no `validation_error` emitted

- **AC-not-owned**: Character not in entitlements
  - Given: Player has no entitlement for `character:nyx`
  - When: `character_confirmed { characterId: 'character:nyx', ... }`
  - Then: `validation_error { code: 'CHARACTER_NOT_OWNED' }` emitted to player socket

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/character-system/selection-validation_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (availability), Story 003 (overlay), Deck/Loadout epic
- Unlocks: Match Server epic (match can start after all players confirmed)
