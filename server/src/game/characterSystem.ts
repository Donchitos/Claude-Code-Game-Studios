import { IContentCatalog, CatalogRecord } from '../catalog/contentCatalog';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface CharacterDefinition extends CatalogRecord {
  type: 'character';
  name: string;
  maxHp: number;
  baseSpeed: number;
  passiveType: string;
  passiveConfig: Record<string, number>;
  defaultSkinId: string;
  availableAbilities: string[];
  xpToUnlock: number;
  isFree: boolean;
  // Runtime stats (may be patched by overlay)
  effectiveMaxHp?: number;
  effectiveBaseSpeed?: number;
}

export interface CharacterRuntimeStats {
  characterId: string;
  maxHp: number;
  baseSpeed: number;
}

export interface IInventoryService {
  hasItem(userId: string, itemId: string): Promise<boolean>;
}

export interface AvailabilityResult {
  available: boolean;
  reason?: 'free' | 'owned' | 'not_owned' | 'inactive';
}

// ---------------------------------------------------------------------------
// CharacterSystem
// ---------------------------------------------------------------------------

const OVERLAY_MIN = 0.5;
const OVERLAY_MAX = 1.5;

export class CharacterSystem {
  private readonly catalog: IContentCatalog;
  private readonly inventory?: IInventoryService;

  constructor(catalog: IContentCatalog, inventory?: IInventoryService) {
    this.catalog = catalog;
    this.inventory = inventory;
  }

  /**
   * Returns all characters that passed startup validation.
   * Excludes characters with invalid `passiveType` or missing abilities.
   */
  getAvailableRoster(): CharacterDefinition[] {
    return this.catalog
      .getAll<CharacterDefinition>('character')
      .filter((c) => this.isValidDefinition(c));
  }

  /** Validates a single CharacterDefinition. Returns false if it should be excluded. */
  private isValidDefinition(c: CharacterDefinition): boolean {
    if (!c.passiveType) return false;
    if (!Array.isArray(c.availableAbilities) || c.availableAbilities.length < 1) return false;
    if (c.availableAbilities.some((id) => !this.catalog.get(id))) return false;
    if (typeof c.availableAbilities.length !== 'number' || c.availableAbilities.length > 2) return false; // slot_count must be ≤2
    return true;
  }

  /**
   * Checks whether a player has access to a character.
   * Free characters (isFree=true) are always available.
   * Others require an active inventory entitlement.
   */
  async getAvailability(userId: string, characterId: string): Promise<AvailabilityResult> {
    const record = this.catalog.get<CharacterDefinition>(characterId);
    if (!record || record.status === 'inactive') {
      return { available: false, reason: 'inactive' };
    }
    if (record.isFree) return { available: true, reason: 'free' };
    if (!this.inventory) return { available: false, reason: 'not_owned' };

    const owned = await this.inventory.hasItem(userId, characterId);
    return owned
      ? { available: true, reason: 'owned' }
      : { available: false, reason: 'not_owned' };
  }

  /**
   * Returns the effective stats for a character at match initialisation.
   * Applies any overlay multipliers from the catalog (clamped to [0.5, 1.5]).
   */
  getRuntimeStats(characterId: string): CharacterRuntimeStats | null {
    const def = this.catalog.get<CharacterDefinition>(characterId);
    if (!def) return null;

    return {
      characterId: def.id,
      maxHp: this.clampOverlay(def.effectiveMaxHp ?? def.maxHp, def.maxHp),
      baseSpeed: this.clampOverlay(def.effectiveBaseSpeed ?? def.baseSpeed, def.baseSpeed),
    };
  }

  private clampOverlay(effective: number, base: number): number {
    const ratio = effective / base;
    const clamped = Math.max(OVERLAY_MIN, Math.min(OVERLAY_MAX, ratio));
    return Math.round(base * clamped * 100) / 100;
  }
}
