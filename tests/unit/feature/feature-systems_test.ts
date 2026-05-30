/**
 * Consolidated Feature layer tests covering economy, progression, and MMR systems.
 */
import {
  CurrencySystem, InventorySystem, XpSystem, MmrSystem, RewardSystem,
  InsufficientFundsError, CannotRevokeFreCharacterError,
  IEconomyDb, Balance,
} from '../../../server/src/economy/economySystems';

// ---------------------------------------------------------------------------
// In-memory DB adapter for tests
// ---------------------------------------------------------------------------

function makeDb(): { adapter: IEconomyDb; store: Record<string, unknown> } {
  const transactions = new Map<string, unknown>();
  const entitlements = new Map<string, Set<string>>();
  const balances = new Map<string, Balance>();
  const xpGrants = new Map<string, boolean>();

  const adapter: IEconomyDb = {
    query: async <T = unknown>(sql: string, params?: unknown[]): Promise<T[]> => { const _cast = (x: unknown): T => x as T;
      if (sql.includes('FROM economy_transactions WHERE idempotency_key')) {
        const key = params![0] as string;
        const row = transactions.get(key);
        return row ? [_cast(row)] : [];
      }
      if (sql.includes('FROM entitlements WHERE idempotency_key')) {
        const key = params![0] as string;
        return transactions.has('ent:' + key) ? [_cast({})] : [];
      }
      if (sql.includes('FROM entitlements WHERE user_id')) {
        const uid = params![0] as string;
        const iid = params![1] as string;
        const has = entitlements.get(uid)?.has(iid) ?? false;
        return has ? [_cast({})] : [];
      }
      if (sql.includes('FROM player_profiles WHERE user_id')) {
        const uid = params![0] as string;
        const bal = balances.get(uid) ?? { coins: 0, diamonds: 0 };
        return [_cast({ coins: bal.coins, diamonds: bal.diamonds })];
      }
      if (sql.includes('FROM xp_grants WHERE idempotency_key')) {
        return xpGrants.has(params![0] as string) ? [_cast({})] : [];
      }
      return [];
    },
    execute: async (sql, params) => {
      if (sql.includes('UPDATE player_profiles SET coin_balance')) {
        const uid = params![2] as string;
        const delta = params![0] as number;
        const ceil = params![1] as number;
        const cur = balances.get(uid) ?? { coins: 0, diamonds: 0 };
        cur.coins = Math.min(cur.coins + delta, ceil);
        balances.set(uid, cur);
      } else if (sql.includes('UPDATE player_profiles SET diamond_balance')) {
        const delta = params![0] as number;
        const uid = params![1] as string;
        const cur = balances.get(uid) ?? { coins: 0, diamonds: 0 };
        cur.diamonds += delta;
        balances.set(uid, cur);
      } else if (sql.includes('INSERT INTO economy_transactions')) {
        const key = params![0] as string;
        const uid = params![1] as string;
        const bal = balances.get(uid) ?? { coins: 0, diamonds: 0 };
        transactions.set(key, { coins: bal.coins, diamonds: bal.diamonds });
      } else if (sql.includes('INSERT INTO entitlements')) {
        const uid = params![0] as string;
        const iid = params![1] as string;
        const key = params![2] as string;
        if (!entitlements.has(uid)) entitlements.set(uid, new Set());
        entitlements.get(uid)!.add(iid);
        transactions.set('ent:' + key, true);
      } else if (sql.includes('DELETE FROM entitlements')) {
        const uid = params![0] as string;
        const iid = params![1] as string;
        entitlements.get(uid)?.delete(iid);
      } else if (sql.includes('INSERT INTO xp_grants')) {
        xpGrants.set(params![0] as string, true);
      }
      return { rowCount: 1 };
    },
  };

  return { adapter, store: { balances, transactions, entitlements } };
}

// ---------------------------------------------------------------------------
// Currency System — match-flow + currency-system epics
// ---------------------------------------------------------------------------

describe('currency-system — creditCoins (AC-econ-001)', () => {
  it('test_creditCoins_increasesBalance', async () => {
    const { adapter } = makeDb();
    const currency = new CurrencySystem(adapter);
    const result = await currency.creditCoins('u1', 50, 'match_reward', 'key-1');
    expect(result.coins).toBe(50);
  });

  it('test_creditCoins_clampsAt50000', async () => {
    const { adapter } = makeDb();
    const currency = new CurrencySystem(adapter);
    await currency.creditCoins('u1', 49_990, 'src', 'k1');
    const result = await currency.creditCoins('u1', 100, 'src', 'k2');
    expect(result.coins).toBe(50_000);
  });

  it('test_creditCoins_idempotent', async () => {
    const { adapter } = makeDb();
    const currency = new CurrencySystem(adapter);
    await currency.creditCoins('u1', 100, 'src', 'same-key');
    const result = await currency.creditCoins('u1', 100, 'src', 'same-key');
    expect(result.coins).toBe(100); // not 200
  });

  it('test_debitCoins_insufficientFunds', async () => {
    const { adapter } = makeDb();
    const currency = new CurrencySystem(adapter);
    await expect(currency.debitCoins('u1', 50, 'spend', 'k1')).rejects.toBeInstanceOf(InsufficientFundsError);
  });
});

// ---------------------------------------------------------------------------
// Inventory / Entitlements — inventory-entitlements epic
// ---------------------------------------------------------------------------

describe('inventory-entitlements (AC-inv-001)', () => {
  it('test_grantItem_idempotent', async () => {
    const { adapter } = makeDb();
    const inv = new InventorySystem(adapter);
    const r1 = await inv.grantItem('u1', 'character:fen', 'k1');
    const r2 = await inv.grantItem('u1', 'character:fen', 'k1');
    expect(r1.duplicate).toBe(false);
    expect(r2.duplicate).toBe(true);
  });

  it('test_hasItem_afterGrant', async () => {
    const { adapter } = makeDb();
    const inv = new InventorySystem(adapter);
    expect(await inv.hasItem('u1', 'character:fen')).toBe(false);
    await inv.grantItem('u1', 'character:fen', 'k1');
    expect(await inv.hasItem('u1', 'character:fen')).toBe(true);
  });

  it('test_revokeItem_freeCharacter_throws', async () => {
    const { adapter } = makeDb();
    const inv = new InventorySystem(adapter);
    await expect(inv.revokeItem('u1', 'character:vex')).rejects.toBeInstanceOf(CannotRevokeFreCharacterError);
  });
});

// ---------------------------------------------------------------------------
// XP & Progression — xp-progression epic
// ---------------------------------------------------------------------------

describe('xp-progression (AC-xp-001)', () => {
  it('test_computePlayerXp_winBonus', () => {
    const xp = new XpSystem({ query: async () => [], execute: async () => ({ rowCount: 0 }) });
    const winner = xp.computePlayerXp(true, 3, 300);
    const loser = xp.computePlayerXp(false, 1, 200);
    expect(winner).toBeGreaterThan(loser);
    expect(winner).toBe(50 + 100 + 75 + 1); // 50 base + 100 win + 3*25 kills + floor(300/200)
  });

  it('test_grantXp_idempotent', async () => {
    const { adapter } = makeDb();
    const xp = new XpSystem(adapter);
    const r1 = await xp.grantXp('u1', 'character:vex', 100, 50, 'match:abc:xp');
    const r2 = await xp.grantXp('u1', 'character:vex', 100, 50, 'match:abc:xp');
    expect(r1.playerXp).toBe(100);
    expect(r2.playerXp).toBe(0); // idempotent second call returns 0
  });
});

// ---------------------------------------------------------------------------
// MMR / Ranked — mmr-ranked epic
// ---------------------------------------------------------------------------

describe('mmr-ranked (AC-mmr-001)', () => {
  const mmr = new MmrSystem({ kProvisional: 32, kEstablished: 16 });

  it('test_1v1_winnerGainsMmr', () => {
    const deltas = mmr.computeDeltas([
      { userId: 'a', mmr: 1000, isProvisional: false, placement: 1 },
      { userId: 'b', mmr: 1000, isProvisional: false, placement: 2 },
    ]);
    const winner = deltas.find(d => d.playerId === 'a')!;
    const loser = deltas.find(d => d.playerId === 'b')!;
    expect(winner.mmrDelta).toBeGreaterThan(0);
    expect(loser.mmrDelta).toBeLessThan(0);
    expect(winner.mmrDelta + loser.mmrDelta).toBe(0); // zero-sum
  });

  it('test_provisional_higherKFactor', () => {
    const deltas = mmr.computeDeltas([
      { userId: 'a', mmr: 1000, isProvisional: true, placement: 1 },
      { userId: 'b', mmr: 1000, isProvisional: true, placement: 2 },
    ]);
    const winner = deltas.find(d => d.playerId === 'a')!;
    expect(winner.mmrDelta).toBe(16); // K=32 * 0.5 expected = 16
  });

  it('test_mmr_doesNotGoNegative', () => {
    const deltas = mmr.computeDeltas([
      { userId: 'a', mmr: 5, isProvisional: false, placement: 2 },
      { userId: 'b', mmr: 2000, isProvisional: false, placement: 1 },
    ]);
    const loser = deltas.find(d => d.playerId === 'a')!;
    expect(loser.newMmr).toBeGreaterThanOrEqual(0);
  });
});

// ---------------------------------------------------------------------------
// Reward System — reward-system epic
// ---------------------------------------------------------------------------

describe('reward-system (AC-reward-001)', () => {
  it('test_winner_getsBaseAndBonus', async () => {
    const { adapter } = makeDb();
    const currency = new CurrencySystem(adapter);
    const rewards = new RewardSystem(currency, { baseCoins: 20, winBonus: 30 });
    const grant = await rewards.calculateAndGrant('match-1', 'u1', 1, false);
    expect(grant!.coinsGranted).toBe(50);
  });

  it('test_loser_getsBaseOnly', async () => {
    const { adapter } = makeDb();
    const currency = new CurrencySystem(adapter);
    const rewards = new RewardSystem(currency, { baseCoins: 20, winBonus: 30 });
    const grant = await rewards.calculateAndGrant('match-1', 'u1', 2, false);
    expect(grant!.coinsGranted).toBe(20);
  });

  it('test_bot_getsNoReward', async () => {
    const { adapter } = makeDb();
    const rewards = new RewardSystem(new CurrencySystem(adapter));
    const grant = await rewards.calculateAndGrant('match-1', 'bot-1', 1, true);
    expect(grant).toBeNull();
  });
});
