# ADR-0013: Progression & Ability Unlock Gating (XP Gates + Character XP)

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director, Game Designer

## Summary

Player XP and Character XP are separate tracks. Player XP gates profile level and unlocks Play Pass tiers. Character XP unlocks the second ability slot for each character. Ability ownership (deck slot eligibility) is checked by the Deck/Loadout Validator at match entry. This ADR defines the XP formulas, unlock gates, and the validation boundary.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | Core |
| **Knowledge Risk** | LOW |
| **References Consulted** | `design/gdd/xp-progression.md`, `design/gdd/character-system.md`, `design/gdd/deck-loadout.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0005 (player_profiles schema), ADR-0008 (XP grants idempotent) |
| **Enables** | XP System implementation, Deck/Loadout Validator |
| **Blocks** | XP grant logic, character progression, deck validation |
| **Ordering Note** | Must be Accepted before XP System or Deck/Loadout Validator are implemented |

## Context

### Problem Statement

Progression must gate content access (ability unlocks, level rewards) without creating pay-to-win imbalance. The Deck/Loadout validator is a server-side bottleneck for ability slot eligibility — it must reject invalid loadouts before match start, not during play.

### Current State

No progression or unlock gating implemented.

### Constraints

- All 8 characters have identical base stats — progression affects ability access, not power ceiling
- Ability unlock is per-character, not global — a player must play a specific character to unlock slot 2
- Validation happens at `character_confirmed` socket event — invalid loadouts rejected before match starts
- XP grants are idempotent (ADR-0008) — match end can be retried safely

### Requirements

- Player XP: earned per match; gates account level (1–50+); awards cosmetic rewards and coins at level-up
- Character XP: earned per match on the played character; gates ability slot 2 unlock
- Ability slot 1 (basic attack): always available on any character
- Ability slot 2: locked until character XP threshold met (per-character, defined in catalog)
- Deck/Loadout Validator enforces: slot count (exactly 2), ability ownership (catalog lookup), character ownership (entitlements check), ability slot eligibility (XP gate)

## Decision

XP is stored in `player_profiles` (Player XP) and `character_xp` table (per-character XP). Unlock thresholds are defined in the Content Catalog (`CharacterDefinition.xpToUnlock` for slot 2). Deck/Loadout Validator runs at `character_confirmed` and rejects invalid loadouts before match creation.

### Architecture

```
MATCH END (via Match Flow fan-out)
  │
  ├── XPSystem.grantXP(matchId, results, idempotencyKey)
  │     for each human player in results:
  │       playerXpGained = BASE_XP + WIN_BONUS + KILL_BONUS + DAMAGE_BONUS
  │       charXpGained = CHAR_BASE_XP + (kills * KILL_CHAR_XP_BONUS)
  │       UPDATE player_profiles SET xp = xp + playerXpGained
  │       UPSERT character_xp SET xp = xp + charXpGained WHERE (userId, characterId)
  │       if new xp >= NEXT_LEVEL_THRESHOLD: levelUp(userId)
  │       if new charXp >= catalog.get(characterId).xpToUnlock: unlock slot 2

CHARACTER_CONFIRMED (socket event):
  │
  ├── DeckLoadoutValidator.validate(userId, characterId, deckSlots)
  │     1. Character ownership: inventory.hasItem(userId, characterId) OR free character
  │     2. Ability existence: catalog.get(abilityId) != null for each slot
  │     3. Ability eligibility: slot[0] always valid; slot[1] requires charXp >= xpToUnlock
  │     4. Slot count: exactly 2 slots provided
  │     → ValidationResult: { valid: boolean; error?: string }
  │
  └── if !valid: emit validation_error to player; reject character_confirmed

XP FORMULAS:
  playerXpGained = 50 + (isWinner ? 100 : 0) + (kills * 25) + floor(damageDealt / 200)
  charXpGained   = 30 + (kills * 15)

LEVEL THRESHOLDS (stored in catalog, not hardcoded):
  level N requires: sum of XP for levels 1..N
  level 1→2: 500 XP, level 2→3: 1000 XP, etc. (catalog-defined array)

CHARACTER XP TO UNLOCK SLOT 2:
  catalog.get('character:{slug}').xpToUnlock  (e.g. 500 for Vex, Zook; 800 for others)
```

### Key Interfaces

```typescript
interface IXPSystem {
  grantXP(matchId: string, results: PlayerResult[], idempotencyKey: string): Promise<void>;
  // Writes player XP + character XP in single transaction per player
  // Emits profile:refresh after each player's write
}

interface IDeckLoadoutValidator {
  validate(userId: string, characterId: string, deckSlots: [string, string]): Promise<ValidationResult>;
}

interface ValidationResult {
  valid: boolean;
  error?: 'CHARACTER_NOT_OWNED' | 'ABILITY_NOT_FOUND' | 'SLOT2_LOCKED' | 'WRONG_SLOT_COUNT';
}

// DB schema additions
// character_xp table
CREATE TABLE character_xp (
  user_id UUID REFERENCES player_profiles(user_id),
  character_id TEXT NOT NULL,   -- 'character:{slug}'
  xp INTEGER NOT NULL DEFAULT 0,
  slot2_unlocked BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (user_id, character_id)
);
```

### Implementation Guidelines

- XP grant must include `idempotencyKey` derived from `matchId+userId` (ADR-0008) — double-grant on retry is prevented by the UNIQUE constraint
- Slot 2 unlock is a one-time write per `(userId, characterId)` — set `slot2_unlocked = TRUE` when `charXp >= xpToUnlock`; never recalculate from XP total (avoid re-locking if formula changes)
- `DeckLoadoutValidator` is called at `character_confirmed` event; invalid loadout → socket event `validation_error` with specific error code; player can re-confirm with corrected deck within the character select window
- Free characters are hardcoded in the validator: `['character:vex', 'character:zook', 'character:sera', 'character:fen', 'character:grim', 'character:dash', 'character:colt', 'character:nyx']`
- Level-up rewards (coins, cosmetics) are granted by the Reward System; XP System only updates XP and triggers a callback

## Alternatives Considered

### Alternative 1: Global Ability Ownership (Not Per-Character)

- **Description**: A player who unlocks ability `piercing_shot` can use it on any character.
- **Pros**: Simpler inventory model; fewer rows in `character_xp`.
- **Cons**: Breaks the Ludus differentiator (deck-building per character); makes characters equivalent except for passive.
- **Rejection Reason**: Per-character ability XP is a core design pillar (Deck/Loadout GDD).

### Alternative 2: Client-Side Lock Display Only (No Server Validation)

- **Description**: Client shows slot 2 as locked; server trusts the deck submitted.
- **Pros**: No server-side validation complexity.
- **Cons**: Exploitable — any player could submit a slot 2 ability they haven't unlocked.
- **Rejection Reason**: Architecture Principle 1 (server authoritative) eliminates client-trusted game state.

## Consequences

### Positive

- Deck validation at match entry catches invalid loadouts before any game state is created
- XP grants are idempotent — safe to retry entire match-end flow
- Per-character XP creates meaningful progression depth per character

### Negative

- `character_xp` table grows with (users × characters played) — manageable at MVP scale
- Validator must do 3 async lookups (inventory, catalog, charXp) — adds ~10ms to character_confirmed processing

### Neutral

- All 8 characters have identical base stats — XP gates ability access, not combat power (W-D-03 warning: options, not power)

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| XP formula produces runaway leveling | Low | Low | Formula values in catalog; remote config overlay can tune without redeploy |
| character_xp unlock not idempotent | Low | Medium | UPSERT with `slot2_unlocked = GREATEST(slot2_unlocked, new_value)` — once true, stays true |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Deck validation (character_confirmed) | — | ≤20ms | 50ms |
| XP grant per player (match end) | — | ≤30ms | 100ms |

## Migration Plan

New project. `character_xp` table added to initial schema.

**Rollback plan**: Remove slot-2 gating — set `slot2_unlocked = TRUE` for all rows; no structural change needed.

## Validation Criteria

- [ ] Player with 0 character XP cannot submit a slot 2 ability; `SLOT2_LOCKED` error returned
- [ ] Player with sufficient character XP can submit slot 2 ability; character_confirmed accepted
- [ ] XP grant is idempotent: running twice for same match → second run is no-op
- [ ] Level-up triggers correctly at XP threshold boundary
- [ ] Validator rejects character not in player inventory; `CHARACTER_NOT_OWNED` returned

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/xp-progression.md` | XP | Player XP + Character XP separate tracks | Both stored; character_xp table defined |
| `design/gdd/character-system.md` | Character | Per-character XP gates slot 2 unlock | `xpToUnlock` in catalog; `slot2_unlocked` in character_xp |
| `design/gdd/deck-loadout.md` | Deck/Loadout | Server validates loadout at match entry | DeckLoadoutValidator at character_confirmed event |

## Related

- ADR-0008: XP grants use idempotency keys
- ADR-0007: Content Catalog provides `xpToUnlock` per character
- ADR-0010: Match Flow fan-out calls XPSystem.grantXP()
