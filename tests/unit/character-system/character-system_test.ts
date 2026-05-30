import * as path from 'path';
import { ContentCatalogService } from '../../../server/src/catalog/contentCatalog';
import { CharacterSystem, CharacterDefinition, IInventoryService } from '../../../server/src/game/characterSystem';

const CATALOG_PATH = path.join(__dirname, '../../../server/src/data/content-catalog.json');

function makeSystem(inventory?: IInventoryService) {
  const catalog = ContentCatalogService.init(CATALOG_PATH);
  return new CharacterSystem(catalog, inventory);
}

// ---------------------------------------------------------------------------
// Story 001: Startup loading & validation (AC-CHAR-001, 002, 003)
// ---------------------------------------------------------------------------

describe('character-system — startup loading', () => {
  it('test_getRoster_returns8Characters', () => {
    const sys = makeSystem();
    expect(sys.getAvailableRoster().length).toBeGreaterThanOrEqual(8);
  });

  it('test_allRosterCharacters_haveValidDefinitions', () => {
    const sys = makeSystem();
    for (const char of sys.getAvailableRoster()) {
      expect(char.passiveType).toBeTruthy();
      expect(Array.isArray(char.availableAbilities)).toBe(true);
      expect(char.availableAbilities.length).toBeGreaterThanOrEqual(1);
      expect(char.availableAbilities.length).toBeLessThanOrEqual(2);
    }
  });
});

// ---------------------------------------------------------------------------
// Story 002: Availability check (AC-AVAIL-001 through 007)
// ---------------------------------------------------------------------------

describe('character-system — availability', () => {
  it('test_freeCharacter_alwaysAvailable', async () => {
    const sys = makeSystem();
    const result = await sys.getAvailability('user-1', 'character:vex');
    expect(result.available).toBe(true);
    expect(result.reason).toBe('free');
  });

  it('test_nonFreeCharacter_notOwnedWithoutInventory', async () => {
    const sys = makeSystem(); // no inventory
    const result = await sys.getAvailability('user-1', 'character:fen');
    expect(result.available).toBe(false);
    expect(result.reason).toBe('not_owned');
  });

  it('test_nonFreeCharacter_ownedWithInventory', async () => {
    const inventory: IInventoryService = { hasItem: async () => true };
    const sys = makeSystem(inventory);
    const result = await sys.getAvailability('user-1', 'character:nyx');
    expect(result.available).toBe(true);
    expect(result.reason).toBe('owned');
  });

  it('test_nonFreeCharacter_notOwnedWithInventory', async () => {
    const inventory: IInventoryService = { hasItem: async () => false };
    const sys = makeSystem(inventory);
    const result = await sys.getAvailability('user-1', 'character:grim');
    expect(result.available).toBe(false);
    expect(result.reason).toBe('not_owned');
  });

  it('test_unknownCharacter_unavailable', async () => {
    const sys = makeSystem();
    const result = await sys.getAvailability('user-1', 'character:ghost');
    expect(result.available).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// Story 003: Balance overlay & runtime stats (AC-OVERLAY-001 through 006)
// ---------------------------------------------------------------------------

describe('character-system — runtime stats', () => {
  it('test_getRuntimeStats_returnsBaseStats', () => {
    const sys = makeSystem();
    const stats = sys.getRuntimeStats('character:vex');
    expect(stats).not.toBeNull();
    expect(stats!.maxHp).toBe(100);
    expect(stats!.baseSpeed).toBe(5.0);
  });

  it('test_getRuntimeStats_unknownCharacterReturnsNull', () => {
    const sys = makeSystem();
    expect(sys.getRuntimeStats('character:ghost')).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// Story 004: Selection validation (via getAvailability)
// ---------------------------------------------------------------------------

describe('character-system — selection validation', () => {
  it('test_validCharacterAndOwned_available', async () => {
    const inv: IInventoryService = { hasItem: async (_, itemId) => itemId === 'character:fen' };
    const sys = makeSystem(inv);
    const result = await sys.getAvailability('u1', 'character:fen');
    expect(result.available).toBe(true);
  });

  it('test_multipleCharacters_independentAvailability', async () => {
    const inv: IInventoryService = {
      hasItem: async (_, itemId) => itemId === 'character:fen' || itemId === 'character:grim',
    };
    const sys = makeSystem(inv);
    expect((await sys.getAvailability('u1', 'character:fen')).available).toBe(true);
    expect((await sys.getAvailability('u1', 'character:grim')).available).toBe(true);
    expect((await sys.getAvailability('u1', 'character:dash')).available).toBe(false);
  });
});
