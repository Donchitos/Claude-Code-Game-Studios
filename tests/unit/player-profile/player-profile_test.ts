import {
  PlayerProfileService, PlayerProfile,
  IDbAdapter, IRedisAdapter, ISocketServer,
} from '../../../server/src/profile/playerProfileService';
import { createLogger } from '../../../server/src/logging/logger';
import { Writable } from 'stream';

// ---------------------------------------------------------------------------
// Test infrastructure
// ---------------------------------------------------------------------------

function nullLogger() {
  return createLogger({ level: 'fatal', destination: new Writable({ write: (_c, _e, cb) => cb() }) });
}

interface InMemoryDb {
  adapter: IDbAdapter;
  rows: Map<string, PlayerProfile>;
}

function makeDb(initialRows: PlayerProfile[] = []): InMemoryDb {
  const rows = new Map<string, PlayerProfile>(initialRows.map(r => [r.user_id, r]));
  const adapter: IDbAdapter = {
    query: async <T>(sql: string, params?: unknown[]) => {
      if (sql.includes('FROM player_profiles WHERE user_id')) {
        const uid = params?.[0] as string;
        const row = rows.get(uid);
        return (row ? [row] : []) as T[];
      }
      if (sql.includes('FROM player_profiles WHERE LOWER(display_name)')) {
        const name = params?.[0] as string;
        const exists = [...rows.values()].some(r => r.display_name.toLowerCase() === name.toLowerCase());
        return (exists ? [{}] : []) as T[];
      }
      return [] as T[];
    },
    execute: async (sql, params) => {
      if (sql.includes('INSERT INTO player_profiles')) {
        const uid = params?.[0] as string;
        if (!rows.has(uid)) {
          rows.set(uid, {
            user_id: uid,
            display_name: params?.[1] as string,
            avatar_id: 'default_avatar',
            region: 'auto',
            created_at: new Date().toISOString(),
            last_seen_at: new Date().toISOString(),
            total_matches: 0, wins: 0, losses: 0, kills: 0,
            preferred_character_id: null,
            mmr: 1000, peak_mmr: 1000, is_provisional: true,
            diamond_balance: 0, has_no_ads: false, has_play_pass: false,
            xp: 0, level: 1,
            unlocked_character_ids: ['character:vex', 'character:zook', 'character:sera'],
            analytics_consent: true,
          });
        }
        return { rowCount: rows.has(uid) ? 1 : 0 };
      }
      if (sql.includes('UPDATE player_profiles SET wins')) {
        const uid = params?.[params.length - 1] as string;
        const row = rows.get(uid);
        if (row) {
          // Parse simple +N increments from params
          const p = params as number[];
          if (sql.includes('wins = wins')) row.wins += p[0] ?? 0;
          if (sql.includes('total_matches = total_matches')) row.total_matches += p[p.length > 2 ? 1 : 0] ?? 0;
        }
        return { rowCount: 1 };
      }
      return { rowCount: 0 };
    },
  };
  return { adapter, rows };
}

function makeRedis(): { adapter: IRedisAdapter; store: Map<string, string> } {
  const store = new Map<string, string>();
  return {
    store,
    adapter: {
      get: async (k) => store.get(k) ?? null,
      set: async (k, v) => { store.set(k, v); },
      del: async (k) => { store.delete(k); },
    },
  };
}

function makeSocket(): { adapter: ISocketServer; events: Array<{ userId: string; event: string }> } {
  const events: Array<{ userId: string; event: string }> = [];
  return {
    events,
    adapter: { emitToUser: (userId, event) => events.push({ userId, event }) },
  };
}

function makeService(db: IDbAdapter, redis: IRedisAdapter, socket: ISocketServer) {
  return new PlayerProfileService(db, redis, socket, nullLogger());
}

// ---------------------------------------------------------------------------
// Story 001: Profile creation (AC-PP-01, AC-PP-02)
// ---------------------------------------------------------------------------

describe('player-profile — story-001: profile creation', () => {
  it('test_createProfile_setsAllDefaults', async () => {
    const { adapter: db } = makeDb();
    const { adapter: redis } = makeRedis();
    const { adapter: socket } = makeSocket();
    const svc = makeService(db, redis, socket);

    const profile = await svc.createProfile('user-abc');
    expect(profile.user_id).toBe('user-abc');
    expect(profile.mmr).toBe(1000);
    expect(profile.level).toBe(1);
    expect(profile.xp).toBe(0);
    expect(profile.diamond_balance).toBe(0);
    expect(profile.is_provisional).toBe(true);
    expect(profile.unlocked_character_ids).toContain('character:vex');
    expect(profile.display_name).toMatch(/^Player_[A-F0-9]{6}$/);
  });

  it('test_createProfile_idempotent_sameUserId', async () => {
    const { adapter: db, rows } = makeDb();
    const { adapter: redis } = makeRedis();
    const { adapter: socket } = makeSocket();
    const svc = makeService(db, redis, socket);

    await svc.createProfile('user-xyz');
    await svc.createProfile('user-xyz'); // second call — ON CONFLICT DO NOTHING
    expect(rows.size).toBe(1); // still only 1 row
  });
});

// ---------------------------------------------------------------------------
// Story 002: Read path — cache hit / miss / Redis down (AC-PP-03, 04, 05)
// ---------------------------------------------------------------------------

describe('player-profile — story-002: read path', () => {
  it('test_getProfile_cacheHit_noDbQuery', async () => {
    let dbQueries = 0;
    const db: IDbAdapter = {
      query: async () => { dbQueries++; return []; },
      execute: async () => ({ rowCount: 0 }),
    };
    const { adapter: redis, store } = makeRedis();
    const profile = { user_id: 'u1', display_name: 'Test', level: 5 } as PlayerProfile;
    store.set('profile:u1', JSON.stringify(profile));
    const svc = makeService(db, redis, makeSocket().adapter);

    const result = await svc.getProfile('u1');
    expect(result?.level).toBe(5);
    expect(dbQueries).toBe(0); // served from cache
  });

  it('test_getProfile_cacheMiss_fetchesFromDb', async () => {
    const profile: PlayerProfile = {
      user_id: 'u2', display_name: 'Test', level: 3, mmr: 1000, peak_mmr: 1000,
      avatar_id: 'x', region: 'eu', created_at: '', last_seen_at: '',
      total_matches: 5, wins: 3, losses: 2, kills: 10, preferred_character_id: null,
      is_provisional: true, diamond_balance: 0, has_no_ads: false, has_play_pass: false,
      xp: 100, unlocked_character_ids: [], analytics_consent: true,
    };
    const { adapter: db } = makeDb([profile]);
    const { adapter: redis, store } = makeRedis();
    const svc = makeService(db, redis, makeSocket().adapter);

    const result = await svc.getProfile('u2');
    expect(result?.level).toBe(3);
    expect(store.has('profile:u2')).toBe(true); // cached after fetch
  });

  it('test_getProfile_redisDown_servesFromDb', async () => {
    const profile: PlayerProfile = {
      user_id: 'u3', display_name: 'FallbackTest', level: 7, mmr: 1200, peak_mmr: 1200,
      avatar_id: 'x', region: 'us', created_at: '', last_seen_at: '',
      total_matches: 10, wins: 6, losses: 4, kills: 20, preferred_character_id: null,
      is_provisional: false, diamond_balance: 50, has_no_ads: false, has_play_pass: false,
      xp: 500, unlocked_character_ids: [], analytics_consent: true,
    };
    const { adapter: db } = makeDb([profile]);
    const brokenRedis: IRedisAdapter = {
      get: async () => { throw new Error('ECONNREFUSED'); },
      set: async () => { throw new Error('ECONNREFUSED'); },
      del: async () => {},
    };
    const svc = makeService(db, brokenRedis, makeSocket().adapter);

    const result = await svc.getProfile('u3');
    expect(result?.level).toBe(7); // served from DB despite Redis down
  });
});

// ---------------------------------------------------------------------------
// Story 003: Display name change (AC-PP-06, 07, 08, 09)
// ---------------------------------------------------------------------------

describe('player-profile — story-003: display name validation', () => {
  it('test_displayName_tooShort_throws', async () => {
    const svc = makeService(makeDb().adapter, makeRedis().adapter, makeSocket().adapter);
    await expect(svc.updateDisplayName('u1', 'ab')).rejects.toThrow('DISPLAY_NAME_TOO_SHORT');
  });

  it('test_displayName_tooLong_throws', async () => {
    const svc = makeService(makeDb().adapter, makeRedis().adapter, makeSocket().adapter);
    await expect(svc.updateDisplayName('u1', 'a'.repeat(21))).rejects.toThrow('DISPLAY_NAME_TOO_LONG');
  });

  it('test_displayName_invalidChars_throws', async () => {
    const svc = makeService(makeDb().adapter, makeRedis().adapter, makeSocket().adapter);
    await expect(svc.updateDisplayName('u1', 'Hello World')).rejects.toThrow('DISPLAY_NAME_INVALID_CHARS');
  });

  it('test_displayName_valid_accepts', async () => {
    const profile: PlayerProfile = {
      user_id: 'u1', display_name: 'OldName', level: 1, mmr: 1000, peak_mmr: 1000,
      avatar_id: 'x', region: 'eu', created_at: '', last_seen_at: '',
      total_matches: 0, wins: 0, losses: 0, kills: 0, preferred_character_id: null,
      is_provisional: true, diamond_balance: 0, has_no_ads: false, has_play_pass: false,
      xp: 0, unlocked_character_ids: [], analytics_consent: true,
    };
    const { adapter: db, rows } = makeDb([profile]);
    const svc = makeService(db, makeRedis().adapter, makeSocket().adapter);
    await svc.updateDisplayName('u1', 'VexKing99');
    // Verify no exception thrown
  });
});

// ---------------------------------------------------------------------------
// Story 006: Concurrent stat increments (AC-PP-12)
// ---------------------------------------------------------------------------

describe('player-profile — story-006: concurrent stat increments', () => {
  it('test_incrementStats_bothWinsApplied', async () => {
    const profile: PlayerProfile = {
      user_id: 'u1', display_name: 'Test', level: 1, mmr: 1000, peak_mmr: 1000,
      avatar_id: 'x', region: 'eu', created_at: '', last_seen_at: '',
      total_matches: 0, wins: 0, losses: 0, kills: 0, preferred_character_id: null,
      is_provisional: true, diamond_balance: 0, has_no_ads: false, has_play_pass: false,
      xp: 0, unlocked_character_ids: [], analytics_consent: true,
    };
    const { adapter: db, rows } = makeDb([profile]);
    const svc = makeService(db, makeRedis().adapter, makeSocket().adapter);

    await Promise.all([
      svc.incrementStats('u1', { wins: 1, totalMatches: 1 }),
      svc.incrementStats('u1', { wins: 1, totalMatches: 1 }),
    ]);

    const updated = rows.get('u1')!;
    expect(updated.wins).toBe(2);
    expect(updated.total_matches).toBe(2);
  });
});

// ---------------------------------------------------------------------------
// Story 009: Computed fields (AC-PP-15, AC-PP-17)
// ---------------------------------------------------------------------------

describe('player-profile — story-009: computed fields', () => {
  it('test_winRate_computedAtReadTime', () => {
    const profile = { wins: 37, total_matches: 63 } as PlayerProfile;
    const rate = PlayerProfileService.computeWinRate(profile);
    expect(rate).toBeCloseTo(0.587, 3);
  });

  it('test_publicProfile_excludesSensitiveFields', () => {
    const svc = makeService(makeDb().adapter, makeRedis().adapter, makeSocket().adapter);
    const profile: PlayerProfile = {
      user_id: 'u1', display_name: 'Test', level: 5, mmr: 1200, peak_mmr: 1300,
      avatar_id: 'ava1', region: 'us', created_at: '', last_seen_at: '',
      total_matches: 50, wins: 30, losses: 20, kills: 100, preferred_character_id: 'character:vex',
      is_provisional: false, diamond_balance: 500, has_no_ads: true, has_play_pass: true,
      xp: 2000, unlocked_character_ids: ['character:vex'], analytics_consent: false,
    };
    const pub = svc.toPublic(profile);
    expect((pub as Record<string, unknown>).diamond_balance).toBeUndefined();
    expect((pub as Record<string, unknown>).has_play_pass).toBeUndefined();
    expect((pub as Record<string, unknown>).analytics_consent).toBeUndefined();
    expect(pub.mmr).toBe(1200);
    expect(pub.display_name).toBe('Test');
  });

  it('test_winRate_zeroMatchesReturnsZero', () => {
    expect(PlayerProfileService.computeWinRate({ wins: 0, total_matches: 0 } as PlayerProfile)).toBe(0);
  });
});
