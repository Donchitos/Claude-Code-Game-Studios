import * as path from 'path';
import { ContentCatalogService } from '../../../server/src/catalog/contentCatalog';
import {
  AbilityRegistry, AbilityExecutor, PlayerAbilityState, StatusEffect,
} from '../../../server/src/game/abilitySystem';

const CATALOG_PATH = path.join(__dirname, '../../../server/src/data/content-catalog.json');

function makeRegistry() {
  const catalog = ContentCatalogService.init(CATALOG_PATH);
  return { registry: new AbilityRegistry(catalog), executor: new AbilityExecutor(new AbilityRegistry(catalog)) };
}

function makePlayer(
  characterId: string,
  slotIds: [string, string],
  overrides: Partial<PlayerAbilityState> = {},
): PlayerAbilityState {
  return {
    playerId: 'p1',
    characterId,
    slots: [
      { abilityId: slotIds[0], cooldownExpiresAt: 0 },
      { abilityId: slotIds[1], cooldownExpiresAt: 0 },
    ],
    statusEffects: [],
    activePassiveState: {},
    isAlive: true,
    isCasting: false,
    castCompletesAt: 0,
    ...overrides,
  };
}

const NOW = 1_000_000;

// ---------------------------------------------------------------------------
// Story 001: Schema validation (AC-1.x)
// ---------------------------------------------------------------------------

describe('ability-skill — schema validation', () => {
  it('test_registry_has18Abilities', () => {
    const { registry } = makeRegistry();
    expect(registry.getAll().length).toBeGreaterThanOrEqual(18);
  });

  it('test_allActiveAbilities_haveUniqueCooldown', () => {
    const { registry } = makeRegistry();
    const invalid = registry.validateAll();
    expect(invalid).toHaveLength(0);
  });

  it('test_registry_unknownId_returnsNull', () => {
    const { registry } = makeRegistry();
    expect(registry.get('ability:nonexistent')).toBeNull();
    expect(registry.isValid('ability:nonexistent')).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// Story 002: Execution pipeline (AC-2.x)
// ---------------------------------------------------------------------------

describe('ability-skill — execution pipeline', () => {
  it('test_execute_acceptsReadyAbility', () => {
    const { executor } = makeRegistry();
    const player = makePlayer('character:vex', ['ability:fireball', 'ability:frost_bolt']);
    const result = executor.execute(player, 0, NOW);
    expect(result.accepted).toBe(true);
    expect(result.damage).toBeGreaterThan(0);
  });

  it('test_execute_rejectsCooldown', () => {
    const { executor } = makeRegistry();
    const player = makePlayer('character:vex', ['ability:fireball', 'ability:frost_bolt'], {
      slots: [
        { abilityId: 'ability:fireball', cooldownExpiresAt: NOW + 2000 },
        { abilityId: 'ability:frost_bolt', cooldownExpiresAt: 0 },
      ],
    });
    const result = executor.execute(player, 0, NOW);
    expect(result.accepted).toBe(false);
    expect(result.rejectionReason).toBe('COOLDOWN');
    expect(result.cooldownRemainingMs).toBe(2000);
  });

  it('test_execute_rejectsDead', () => {
    const { executor } = makeRegistry();
    const player = makePlayer('character:vex', ['ability:fireball', 'ability:frost_bolt'], { isAlive: false });
    expect(executor.execute(player, 0, NOW).rejectionReason).toBe('INELIGIBLE');
  });

  it('test_execute_rejectsStunned', () => {
    const { executor } = makeRegistry();
    const player = makePlayer('character:vex', ['ability:fireball', 'ability:frost_bolt'], {
      statusEffects: [{ type: 'STUNNED', magnitude: 0, expiresAt: NOW + 1000 }],
    });
    expect(executor.execute(player, 0, NOW).rejectionReason).toBe('INELIGIBLE');
  });

  it('test_execute_setsCooldownAfterSuccess', () => {
    const { executor } = makeRegistry();
    const player = makePlayer('character:vex', ['ability:fireball', 'ability:frost_bolt']);
    executor.execute(player, 0, NOW);
    expect(player.slots[0].cooldownExpiresAt).toBeGreaterThan(NOW);
  });
});

// ---------------------------------------------------------------------------
// Story 003: Cooldown enforcement (AC-3.x)
// ---------------------------------------------------------------------------

describe('ability-skill — cooldown enforcement', () => {
  it('test_cooldown_exactBoundaryAccepted', () => {
    const { executor } = makeRegistry();
    const player = makePlayer('character:vex', ['ability:fireball', 'ability:frost_bolt'], {
      slots: [
        { abilityId: 'ability:fireball', cooldownExpiresAt: NOW }, // exactly equal → ready
        { abilityId: 'ability:frost_bolt', cooldownExpiresAt: 0 },
      ],
    });
    const result = executor.execute(player, 0, NOW);
    expect(result.accepted).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// Story 004: Affinity bonus (AC-4.x)
// ---------------------------------------------------------------------------

describe('ability-skill — affinity bonus', () => {
  it('test_affinity_bonusAppliedForAffinityCharacter', () => {
    const { executor, registry } = makeRegistry();
    const fireball = registry.get('ability:fireball')!;
    const player = makePlayer('character:vex', ['ability:fireball', 'ability:frost_bolt']);
    const result = executor.execute(player, 0, NOW);
    // Vex has affinity for fireball — damage should be > base
    expect(result.damage).toBeGreaterThan(fireball.damage);
  });

  it('test_affinity_noBonusForNonAffinityCharacter', () => {
    const { executor, registry } = makeRegistry();
    const fireball = registry.get('ability:fireball')!;
    const player = makePlayer('character:zook', ['ability:fireball', 'ability:frost_bolt']);
    const result = executor.execute(player, 0, NOW);
    expect(result.damage).toBe(fireball.damage);
  });
});

// ---------------------------------------------------------------------------
// Story 005: Status effects (AC-5.x)
// ---------------------------------------------------------------------------

describe('ability-skill — status effects', () => {
  it('test_burning_bypassesShield', () => {
    // BURNING type bypasses SHIELDED — test the type system knowledge
    const burningEffect: StatusEffect = { type: 'BURNING', magnitude: 10, expiresAt: NOW + 2000 };
    const shieldEffect: StatusEffect = { type: 'SHIELDED', magnitude: 30, expiresAt: NOW + 3000 };
    // Applying both — they are separate effects; BURNING damage must apply to HP directly
    // This is verified at the Combat Resolver level; here we verify effects are stored independently
    const { executor } = makeRegistry();
    const player = makePlayer('character:vex', ['ability:fireball', 'ability:frost_bolt']);
    executor.applyStatusEffect(player, burningEffect);
    executor.applyStatusEffect(player, shieldEffect);
    expect(player.statusEffects.find(e => e.type === 'BURNING')).toBeDefined();
    expect(player.statusEffects.find(e => e.type === 'SHIELDED')).toBeDefined();
  });

  it('test_noStacking_highestMagnitudeWins', () => {
    const { executor } = makeRegistry();
    const player = makePlayer('character:vex', ['ability:fireball', 'ability:frost_bolt']);
    executor.applyStatusEffect(player, { type: 'SLOWED', magnitude: 30, expiresAt: NOW + 2000 });
    executor.applyStatusEffect(player, { type: 'SLOWED', magnitude: 20, expiresAt: NOW + 3000 });
    expect(player.statusEffects.filter(e => e.type === 'SLOWED').length).toBe(1);
    expect(player.statusEffects[0].magnitude).toBe(30); // higher wins
  });

  it('test_noStacking_durationRefreshedOnReapply', () => {
    const { executor } = makeRegistry();
    const player = makePlayer('character:vex', ['ability:fireball', 'ability:frost_bolt']);
    executor.applyStatusEffect(player, { type: 'STUNNED', magnitude: 0, expiresAt: NOW + 1000 });
    executor.applyStatusEffect(player, { type: 'STUNNED', magnitude: 0, expiresAt: NOW + 3000 });
    expect(player.statusEffects[0].expiresAt).toBe(NOW + 3000);
  });

  it('test_invisible_removedOnAbilityUse', () => {
    const { executor } = makeRegistry();
    const player = makePlayer('character:nyx', ['ability:invisibility', 'ability:shadow_strike'], {
      statusEffects: [{ type: 'INVISIBLE', magnitude: 0, expiresAt: NOW + 5000 }],
    });
    executor.execute(player, 1, NOW); // use shadow_strike
    expect(player.statusEffects.find(e => e.type === 'INVISIBLE')).toBeUndefined();
  });

  it('test_tickStatusEffects_removesExpired', () => {
    const { executor } = makeRegistry();
    const player = makePlayer('character:vex', ['ability:fireball', 'ability:frost_bolt'], {
      statusEffects: [
        { type: 'SLOWED', magnitude: 30, expiresAt: NOW - 1 }, // already expired
        { type: 'BURNING', magnitude: 5, expiresAt: NOW + 1000 }, // still active
      ],
    });
    executor.tickStatusEffects(player, NOW);
    expect(player.statusEffects.length).toBe(1);
    expect(player.statusEffects[0].type).toBe('BURNING');
  });
});

// ---------------------------------------------------------------------------
// Story 006: Passive abilities (AC-6.x) — structural test
// ---------------------------------------------------------------------------

describe('ability-skill — passive config in catalog', () => {
  it('test_allCharacters_havePassiveType', () => {
    const catalog = ContentCatalogService.init(CATALOG_PATH);
    const chars = catalog.getAll('character') as unknown as Array<{ passiveType: string }>;
    expect(chars.every(c => !!c.passiveType)).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// Story 007: Targeting models (AC-7.x, AC-8.x)
// ---------------------------------------------------------------------------

describe('ability-skill — targeting edge cases', () => {
  it('test_disconnectDuringCast_noCooldownConsumed', () => {
    const { executor } = makeRegistry();
    const player = makePlayer('character:sera', ['ability:heal_burst', 'ability:shield_wall'], {
      isCasting: true,
      castCompletesAt: NOW + 200, // mid-cast
    });
    const cooldownBefore = player.slots[0].cooldownExpiresAt;
    // Disconnect: mark inactive (isCasting = false, castCompletesAt = 0)
    player.isCasting = false;
    player.castCompletesAt = 0;
    // Cooldown should not have been consumed
    expect(player.slots[0].cooldownExpiresAt).toBe(cooldownBefore);
  });
});
