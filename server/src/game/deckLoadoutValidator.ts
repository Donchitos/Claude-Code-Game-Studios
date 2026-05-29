import { IContentCatalog } from '../catalog/contentCatalog';
import { CharacterDefinition } from './characterSystem';
import { AbilityDefinition } from './abilitySystem';

export type LoadoutValidationError =
  | 'CHARACTER_NOT_OWNED'
  | 'ABILITY_NOT_FOUND'
  | 'SLOT2_LOCKED'
  | 'WRONG_SLOT_COUNT'
  | 'ABILITY_NOT_VALID_FOR_CHARACTER';

export interface ValidationResult {
  valid: boolean;
  error?: LoadoutValidationError;
}

export interface ICharacterXpStore {
  /** Returns the player's XP for a specific character, or 0 if never played. */
  getCharacterXp(userId: string, characterId: string): Promise<number>;
}

/**
 * Validates a player's deck/loadout submission at `character_confirmed` time.
 *
 * Validation order (per ADR-0013):
 * 1. Character owned (or free)
 * 2. Slot count == 2
 * 3. Each ability exists in catalog
 * 4. Slot 1 ability: no XP gate (always available)
 * 5. Slot 2 ability: player must have sufficient character XP
 */
export class DeckLoadoutValidator {
  private readonly catalog: IContentCatalog;
  private readonly xpStore: ICharacterXpStore;

  constructor(catalog: IContentCatalog, xpStore: ICharacterXpStore) {
    this.catalog = catalog;
    this.xpStore = xpStore;
  }

  async validate(
    userId: string,
    characterId: string,
    deckSlots: string[],
    ownedCharacterIds: string[],
  ): Promise<ValidationResult> {
    const charDef = this.catalog.get<CharacterDefinition>(characterId);

    // 1. Character must exist and be owned (free or entitlement)
    if (!charDef) return { valid: false, error: 'CHARACTER_NOT_OWNED' };
    if (!charDef.isFree && !ownedCharacterIds.includes(characterId)) {
      return { valid: false, error: 'CHARACTER_NOT_OWNED' };
    }

    // 2. Must have exactly 2 slots
    if (deckSlots.length !== 2) {
      return { valid: false, error: 'WRONG_SLOT_COUNT' };
    }

    // 3. Each ability must exist in catalog
    for (const abilityId of deckSlots) {
      const ab = this.catalog.get<AbilityDefinition>(abilityId);
      if (!ab) return { valid: false, error: 'ABILITY_NOT_FOUND' };
    }

    // 4. Slot 2: check XP gate
    const slot2Id = deckSlots[1];
    const charXp = await this.xpStore.getCharacterXp(userId, characterId);
    const xpRequired = charDef.xpToUnlock ?? 500;
    if (charXp < xpRequired) {
      return { valid: false, error: 'SLOT2_LOCKED' };
    }

    return { valid: true };
  }
}
