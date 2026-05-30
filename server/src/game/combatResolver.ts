import { StatusEffect, StatusEffectType, PlayerAbilityState } from './abilitySystem';

export interface CombatPlayerState {
  playerId: string;
  hp: number;
  maxHp: number;
  isAlive: boolean;
  position: { x: number; y: number };
  statusEffects: StatusEffect[];
}

export interface HitResult {
  damage: number;
  appliedToHp: boolean;       // false if absorbed by shield
  shieldAbsorbed: number;     // how much shield HP was depleted
  remainingHp: number;
  remainingShieldHp: number;
}

export interface ResolveHitInput {
  baseDamage: number;
  damageType: 'normal' | 'burning' | 'skill';
  nowMs: number;
}

/**
 * CombatResolver handles all damage and status effect interactions.
 *
 * Key rule (per ADR-0003 + GDD combat-system.md):
 * - BURNING damage bypasses SHIELDED and applies directly to HP.
 * - All other damage: depletes shield HP first; overflow goes to player HP.
 * - No negative HP — floor at 0.
 */
export class CombatResolver {

  /**
   * Resolves a hit against a target player.
   * Returns the breakdown of damage applied.
   */
  resolveHit(target: CombatPlayerState, input: ResolveHitInput): HitResult {
    const shield = this.getActiveShield(target, input.nowMs);
    const isBurning = input.damageType === 'burning';

    if (!isBurning && shield) {
      // Normal damage: depletes shield first
      const absorbed = Math.min(shield.magnitude, input.baseDamage);
      const overflow = input.baseDamage - absorbed;
      shield.magnitude -= absorbed;
      const newHp = Math.max(0, target.hp - overflow);
      target.hp = newHp;
      if (newHp === 0) target.isAlive = false;
      return {
        damage: input.baseDamage,
        appliedToHp: overflow > 0,
        shieldAbsorbed: absorbed,
        remainingHp: newHp,
        remainingShieldHp: shield.magnitude,
      };
    }

    // BURNING or no shield: damage goes directly to HP
    const newHp = Math.max(0, target.hp - input.baseDamage);
    target.hp = newHp;
    if (newHp === 0) target.isAlive = false;
    return {
      damage: input.baseDamage,
      appliedToHp: true,
      shieldAbsorbed: 0,
      remainingHp: newHp,
      remainingShieldHp: shield?.magnitude ?? 0,
    };
  }

  /**
   * Applies BURNING tick damage (every 500ms = 10 ticks at 20Hz).
   * BURNING bypasses SHIELDED — always applied to HP directly.
   */
  applyBurningTick(target: CombatPlayerState, effect: StatusEffect, nowMs: number): number {
    if (effect.type !== 'BURNING' || effect.expiresAt <= nowMs) return 0;
    const damage = effect.magnitude;
    target.hp = Math.max(0, target.hp - damage);
    if (target.hp === 0) target.isAlive = false;
    return damage;
  }

  /**
   * Calculates the lag-compensation rewind amount in ticks.
   * Formula: floor(min(playerRttMs, 200) / 50)
   * Applies to hit detection only, not damage.
   */
  static lagCompensateTick(playerRttMs: number): number {
    return Math.floor(Math.min(playerRttMs, 200) / 50);
  }

  /**
   * Returns the active SHIELDED effect if one exists and hasn't expired.
   * Returns null if no shield is active.
   */
  private getActiveShield(target: CombatPlayerState, nowMs: number): StatusEffect | null {
    return target.statusEffects.find(
      (e) => e.type === 'SHIELDED' && e.expiresAt > nowMs && e.magnitude > 0,
    ) ?? null;
  }
}
