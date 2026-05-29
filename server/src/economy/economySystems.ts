import { randomUUID } from 'crypto';

// ---------------------------------------------------------------------------
// Shared types
// ---------------------------------------------------------------------------

export class InsufficientFundsError extends Error {
  constructor(
    public readonly userId: string,
    public readonly requestedDebit: number,
    public readonly currentBalance: number,
  ) {
    super(`InsufficientFunds: user ${userId} has ${currentBalance}, tried to debit ${requestedDebit}`);
  }
}

export class CannotRevokeFreCharacterError extends Error {
  constructor(public readonly characterId: string) {
    super(`CANNOT_REVOKE_FREE_CHARACTER: ${characterId}`);
  }
}

export interface IEconomyDb {
  query<T = unknown>(sql: string, params?: unknown[]): Promise<T[]>;
  execute(sql: string, params?: unknown[]): Promise<{ rowCount: number }>;
}

// ---------------------------------------------------------------------------
// Currency System (ADR-0008)
// ---------------------------------------------------------------------------

const COIN_CEILING = 50_000;
const FREE_CHARACTER_IDS = new Set([
  'character:vex', 'character:zook', 'character:sera',
  'character:fen', 'character:grim', 'character:dash',
  'character:colt', 'character:nyx',
]);

export interface Balance {
  coins: number;
  diamonds: number;
}

export class CurrencySystem {
  constructor(private readonly db: IEconomyDb) {}

  async creditCoins(userId: string, amount: number, source: string, idempotencyKey: string): Promise<Balance> {
    return this.upsertBalance(userId, { coinDelta: amount }, idempotencyKey, source);
  }

  async debitCoins(userId: string, amount: number, source: string, idempotencyKey: string): Promise<Balance> {
    const current = await this.getBalance(userId);
    if (current.coins < amount) throw new InsufficientFundsError(userId, amount, current.coins);
    return this.upsertBalance(userId, { coinDelta: -amount }, idempotencyKey, source);
  }

  async creditDiamonds(userId: string, amount: number, source: string, idempotencyKey: string): Promise<Balance> {
    return this.upsertBalance(userId, { diamondDelta: amount }, idempotencyKey, source);
  }

  async getBalance(userId: string): Promise<Balance> {
    const rows = await this.db.query<{ coins: number; diamonds: number }>(
      'SELECT coin_balance AS coins, diamond_balance AS diamonds FROM player_profiles WHERE user_id = $1',
      [userId],
    );
    return rows[0] ?? { coins: 0, diamonds: 0 };
  }

  private async upsertBalance(
    userId: string,
    delta: { coinDelta?: number; diamondDelta?: number },
    idempotencyKey: string,
    source: string,
  ): Promise<Balance> {
    // Check idempotency
    const existing = await this.db.query<{ coins: number; diamonds: number }>(
      'SELECT final_coins AS coins, final_diamonds AS diamonds FROM economy_transactions WHERE idempotency_key = $1',
      [idempotencyKey],
    );
    if (existing.length > 0) return existing[0];

    // Apply delta with ceiling
    const coinChange = delta.coinDelta ?? 0;
    const diamondChange = delta.diamondDelta ?? 0;

    const sql = coinChange !== 0
      ? `UPDATE player_profiles SET coin_balance = LEAST(coin_balance + $1, $2) WHERE user_id = $3`
      : `UPDATE player_profiles SET diamond_balance = diamond_balance + $1 WHERE user_id = $2`;

    const params = coinChange !== 0
      ? [coinChange, COIN_CEILING, userId]
      : [diamondChange, userId];

    await this.db.execute(sql, params);
    await this.db.execute(
      'INSERT INTO economy_transactions (idempotency_key, user_id, source, coin_delta, diamond_delta) VALUES ($1,$2,$3,$4,$5)',
      [idempotencyKey, userId, source, coinChange, diamondChange],
    );

    return this.getBalance(userId);
  }
}

// ---------------------------------------------------------------------------
// Inventory / Entitlements (ADR-0008)
// ---------------------------------------------------------------------------

export interface GrantResult {
  duplicate: boolean;
  itemId: string;
}

export class InventorySystem {
  constructor(private readonly db: IEconomyDb) {}

  async grantItem(userId: string, itemId: string, idempotencyKey: string): Promise<GrantResult> {
    const existing = await this.db.query(
      'SELECT 1 FROM entitlements WHERE idempotency_key = $1',
      [idempotencyKey],
    );
    if (existing.length > 0) return { duplicate: true, itemId };

    await this.db.execute(
      'INSERT INTO entitlements (user_id, item_id, idempotency_key, granted_at) VALUES ($1,$2,$3,NOW())',
      [userId, itemId, idempotencyKey],
    );
    return { duplicate: false, itemId };
  }

  async hasItem(userId: string, itemId: string): Promise<boolean> {
    const rows = await this.db.query(
      'SELECT 1 FROM entitlements WHERE user_id = $1 AND item_id = $2',
      [userId, itemId],
    );
    return rows.length > 0;
  }

  async revokeItem(userId: string, itemId: string): Promise<void> {
    if (FREE_CHARACTER_IDS.has(itemId)) {
      throw new CannotRevokeFreCharacterError(itemId);
    }
    await this.db.execute('DELETE FROM entitlements WHERE user_id = $1 AND item_id = $2', [userId, itemId]);
  }
}

// ---------------------------------------------------------------------------
// XP & Progression System (ADR-0013)
// ---------------------------------------------------------------------------

export interface XpGrant {
  playerXp: number;
  characterXp: number;
  leveledUp: boolean;
  slot2Unlocked?: string; // characterId if slot 2 just unlocked
}

const BASE_MATCH_XP = 50;
const WIN_BONUS_XP = 100;
const KILL_XP = 25;

export class XpSystem {
  constructor(private readonly db: IEconomyDb) {}

  computePlayerXp(isWinner: boolean, kills: number, damageDealt: number): number {
    return BASE_MATCH_XP + (isWinner ? WIN_BONUS_XP : 0) + kills * KILL_XP + Math.floor(damageDealt / 200);
  }

  computeCharacterXp(kills: number): number {
    return 30 + kills * 15;
  }

  async grantXp(
    userId: string,
    characterId: string,
    playerXpGain: number,
    characterXpGain: number,
    idempotencyKey: string,
  ): Promise<XpGrant> {
    // Idempotency check
    const existing = await this.db.query('SELECT 1 FROM xp_grants WHERE idempotency_key = $1', [idempotencyKey]);
    if (existing.length > 0) return { playerXp: 0, characterXp: 0, leveledUp: false };

    await this.db.execute(
      'UPDATE player_profiles SET xp = xp + $1 WHERE user_id = $2',
      [playerXpGain, userId],
    );
    await this.db.execute(
      `INSERT INTO character_xp (user_id, character_id, xp) VALUES ($1,$2,$3)
       ON CONFLICT (user_id, character_id) DO UPDATE SET xp = character_xp.xp + $3`,
      [userId, characterId, characterXpGain],
    );
    await this.db.execute(
      'INSERT INTO xp_grants (idempotency_key, user_id, player_xp, character_xp) VALUES ($1,$2,$3,$4)',
      [idempotencyKey, userId, playerXpGain, characterXpGain],
    );

    return {
      playerXp: playerXpGain,
      characterXp: characterXpGain,
      leveledUp: false, // level-up logic omitted for brevity
    };
  }
}

// ---------------------------------------------------------------------------
// MMR / Ranked System (ADR-0010)
// ---------------------------------------------------------------------------

export interface MmrDelta {
  playerId: string;
  mmrDelta: number;
  newMmr: number;
}

export class MmrSystem {
  private readonly kFactorProvisional: number;
  private readonly kFactorEstablished: number;

  constructor(opts: { kProvisional?: number; kEstablished?: number } = {}) {
    this.kFactorProvisional = opts.kProvisional ?? 32;
    this.kFactorEstablished = opts.kEstablished ?? 16;
  }

  /**
   * Computes Elo MMR deltas for a 1v1 match result.
   * Uses K-factor of 32 for provisional players, 16 for established.
   */
  computeDeltas(
    players: Array<{ userId: string; mmr: number; isProvisional: boolean; placement: number }>,
  ): MmrDelta[] {
    if (players.length !== 2) {
      // For non-1v1, use simplified delta: +15 win / -15 loss
      return players.map((p) => {
        const delta = p.placement === 1 ? 15 : -15;
        return { playerId: p.userId, mmrDelta: delta, newMmr: Math.max(0, p.mmr + delta) };
      });
    }

    const [a, b] = players;
    const kA = a.isProvisional ? this.kFactorProvisional : this.kFactorEstablished;
    const kB = b.isProvisional ? this.kFactorProvisional : this.kFactorEstablished;

    const expectedA = 1 / (1 + Math.pow(10, (b.mmr - a.mmr) / 400));
    const actualA = a.placement < b.placement ? 1 : a.placement === b.placement ? 0.5 : 0;

    const deltaA = Math.round(kA * (actualA - expectedA));
    const deltaB = -deltaA;

    return [
      { playerId: a.userId, mmrDelta: deltaA, newMmr: Math.max(0, a.mmr + deltaA) },
      { playerId: b.userId, mmrDelta: deltaB, newMmr: Math.max(0, b.mmr + deltaB) },
    ];
  }
}

// ---------------------------------------------------------------------------
// Reward System (ADR-0010)
// ---------------------------------------------------------------------------

export interface RewardGrant {
  coinsGranted: number;
  idempotencyKey: string;
}

export class RewardSystem {
  private readonly currency: CurrencySystem;
  private readonly baseCoins: number;
  private readonly winBonus: number;

  constructor(currency: CurrencySystem, opts: { baseCoins?: number; winBonus?: number } = {}) {
    this.currency = currency;
    this.baseCoins = opts.baseCoins ?? 20;
    this.winBonus = opts.winBonus ?? 30;
  }

  async calculateAndGrant(
    matchId: string,
    userId: string,
    placement: number,
    isBot: boolean,
  ): Promise<RewardGrant | null> {
    if (isBot) return null;
    const isWinner = placement === 1;
    const coins = this.baseCoins + (isWinner ? this.winBonus : 0);
    const key = `${matchId}:reward:${userId}`;
    await this.currency.creditCoins(userId, coins, 'match_reward', key);
    return { coinsGranted: coins, idempotencyKey: key };
  }
}
