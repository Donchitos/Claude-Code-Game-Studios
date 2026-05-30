import { IContentCatalog, CatalogRecord } from '../catalog/contentCatalog';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface AbilityDefinition extends CatalogRecord {
  type: 'ability';
  abilityType: 'active' | 'passive';
  cooldownSec: number;
  damage: number;
  range_units: number;
  aoeRadius_units: number;
  projectile: boolean;
  effectType: StatusEffectType | null;
  effectMagnitude: number;
  effectDuration_ms: number;
  castTimeMs: number;
  affinityBonus: number;
  affinityCharacterIds: string[];
}

export type StatusEffectType = 'BURNING' | 'SHIELDED' | 'STUNNED' | 'SLOWED' | 'INVISIBLE';

export interface StatusEffect {
  type: StatusEffectType;
  magnitude: number;
  expiresAt: number; // server time ms
}

export interface AbilityCooldownState {
  abilityId: string;
  cooldownExpiresAt: number; // server time ms; 0 = ready
}

export interface PlayerAbilityState {
  playerId: string;
  characterId: string;
  slots: [AbilityCooldownState, AbilityCooldownState];
  statusEffects: StatusEffect[];
  activePassiveState: Record<string, unknown>;
  isAlive: boolean;
  isCasting: boolean;
  castCompletesAt: number;
}

export type AbilityRejectionReason = 'COOLDOWN' | 'INELIGIBLE' | 'SLOT_LOCKED';

export interface AbilityResult {
  accepted: boolean;
  rejectionReason?: AbilityRejectionReason;
  cooldownRemainingMs?: number;
  damage?: number;
  statusEffect?: StatusEffect;
}

// ---------------------------------------------------------------------------
// AbilityRegistry
// ---------------------------------------------------------------------------

export class AbilityRegistry {
  private readonly catalog: IContentCatalog;

  constructor(catalog: IContentCatalog) {
    this.catalog = catalog;
  }

  get(id: string): AbilityDefinition | null {
    return this.catalog.get<AbilityDefinition>(id);
  }

  isValid(id: string): boolean {
    return this.catalog.get(id) !== null;
  }

  getAll(): AbilityDefinition[] {
    return this.catalog.getAll<AbilityDefinition>('ability');
  }

  /** Validates all ability definitions in the catalog. Returns names of invalid abilities. */
  validateAll(): string[] {
    const invalid: string[] = [];
    for (const ab of this.getAll()) {
      if (ab.abilityType === 'active' && ab.cooldownSec <= 0) invalid.push(`${ab.id}: active ability missing cooldown`);
      if (ab.projectile && ab.range_units <= 0) invalid.push(`${ab.id}: projectile ability missing range`);
      if (ab.aoeRadius_units > 0 && ab.range_units < 0) invalid.push(`${ab.id}: AoE with negative range`);
      if (ab.affinityBonus < 0 || ab.affinityBonus > 1) invalid.push(`${ab.id}: affinityBonus out of range`);
    }
    return invalid;
  }
}

// ---------------------------------------------------------------------------
// AbilityExecutor
// ---------------------------------------------------------------------------

const CDR_MINIMUM_SEC = 1.0;

export class AbilityExecutor {
  private readonly registry: AbilityRegistry;

  constructor(registry: AbilityRegistry) {
    this.registry = registry;
  }

  /**
   * Attempts to execute an ability for a player.
   * Returns the result including whether it was accepted and any damage/effect.
   */
  execute(
    player: PlayerAbilityState,
    slotIndex: 0 | 1,
    nowMs: number,
  ): AbilityResult {
    const slot = player.slots[slotIndex];
    const def = this.registry.get(slot.abilityId);
    if (!def) return { accepted: false, rejectionReason: 'INELIGIBLE' };

    // Dead player can't use abilities
    if (!player.isAlive) return { accepted: false, rejectionReason: 'INELIGIBLE' };

    // STUNNED blocks all abilities
    if (this.hasEffect(player, 'STUNNED', nowMs)) {
      return { accepted: false, rejectionReason: 'INELIGIBLE' };
    }

    // Currently casting blocks second slot
    if (player.isCasting && nowMs < player.castCompletesAt) {
      return { accepted: false, rejectionReason: 'INELIGIBLE' };
    }

    // Cooldown check
    if (nowMs < slot.cooldownExpiresAt) {
      return {
        accepted: false,
        rejectionReason: 'COOLDOWN',
        cooldownRemainingMs: slot.cooldownExpiresAt - nowMs,
      };
    }

    // Resolve effective cooldown (Nyx opener CDR handled externally via passive)
    const effectiveCooldownSec = Math.max(CDR_MINIMUM_SEC, def.cooldownSec);

    // Resolve damage with affinity bonus
    const hasAffinity = def.affinityCharacterIds.includes(player.characterId);
    const damage = Math.round(def.damage * (hasAffinity ? 1 + def.affinityBonus : 1));

    // Apply cast time if present
    if (def.castTimeMs > 0) {
      player.isCasting = true;
      player.castCompletesAt = nowMs + def.castTimeMs;
      // Cooldown starts after cast completes
      slot.cooldownExpiresAt = player.castCompletesAt + effectiveCooldownSec * 1000;
    } else {
      slot.cooldownExpiresAt = nowMs + effectiveCooldownSec * 1000;
    }

    // Remove INVISIBLE on any active ability use
    this.removeEffect(player, 'INVISIBLE', nowMs);

    const result: AbilityResult = { accepted: true, damage };

    if (def.effectType) {
      result.statusEffect = {
        type: def.effectType,
        magnitude: def.effectMagnitude * (hasAffinity ? 1 : 1), // affinity only affects damage, not effect
        expiresAt: nowMs + def.effectDuration_ms,
      };
    }

    return result;
  }

  /** Applies a status effect to a target, handling no-stacking rule. */
  applyStatusEffect(target: PlayerAbilityState, effect: StatusEffect): void {
    const existing = target.statusEffects.find((e) => e.type === effect.type);
    if (existing) {
      // No stacking: highest magnitude wins; re-application refreshes duration
      existing.magnitude = Math.max(existing.magnitude, effect.magnitude);
      existing.expiresAt = Math.max(existing.expiresAt, effect.expiresAt);
    } else {
      target.statusEffects.push({ ...effect });
    }
  }

  /** Removes expired status effects and returns the cleaned list. */
  tickStatusEffects(player: PlayerAbilityState, nowMs: number): void {
    player.statusEffects = player.statusEffects.filter((e) => e.expiresAt > nowMs);
  }

  private hasEffect(player: PlayerAbilityState, type: StatusEffectType, nowMs: number): boolean {
    return player.statusEffects.some((e) => e.type === type && e.expiresAt > nowMs);
  }

  private removeEffect(player: PlayerAbilityState, type: StatusEffectType, nowMs: number): void {
    player.statusEffects = player.statusEffects.filter((e) => e.type !== type);
  }
}
