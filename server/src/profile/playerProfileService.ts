import { randomBytes } from 'crypto';
import { ILogger } from '../logging/logger';

// ---------------------------------------------------------------------------
// Adapters
// ---------------------------------------------------------------------------

export interface IDbAdapter {
  query<T = unknown>(sql: string, params?: unknown[]): Promise<T[]>;
  execute(sql: string, params?: unknown[]): Promise<{ rowCount: number }>;
}

export interface IRedisAdapter {
  get(key: string): Promise<string | null>;
  set(key: string, value: string, ttlSeconds?: number): Promise<void>;
  del(key: string): Promise<void>;
}

export interface ISocketServer {
  emitToUser(userId: string, event: string, data: unknown): void;
}

// ---------------------------------------------------------------------------
// Player Profile types
// ---------------------------------------------------------------------------

export interface PlayerProfile {
  user_id: string;
  display_name: string;
  avatar_id: string;
  region: string;
  created_at: string;
  last_seen_at: string;
  total_matches: number;
  wins: number;
  losses: number;
  kills: number;
  preferred_character_id: string | null;
  mmr: number;
  peak_mmr: number;
  is_provisional: boolean;
  diamond_balance: number;
  has_no_ads: boolean;
  has_play_pass: boolean;
  xp: number;
  level: number;
  unlocked_character_ids: string[];
  analytics_consent: boolean;
}

export type PublicProfile = Pick<
  PlayerProfile,
  'user_id' | 'display_name' | 'avatar_id' | 'level' | 'mmr' | 'peak_mmr' |
  'total_matches' | 'wins' | 'losses' | 'kills' | 'preferred_character_id'
>;

const PROFILE_CACHE_TTL_SECONDS = 300;
const PROFILE_CACHE_KEY = (userId: string) => `profile:${userId}`;
const FREE_CHARACTER_IDS = ['character:vex', 'character:zook', 'character:sera'];
const DEFAULT_MMR = 1000;

// ---------------------------------------------------------------------------
// PlayerProfileService
// ---------------------------------------------------------------------------

export class PlayerProfileService {
  constructor(
    private readonly db: IDbAdapter,
    private readonly redis: IRedisAdapter,
    private readonly io: ISocketServer,
    private readonly logger: ILogger,
  ) {}

  /** Read path: Redis-first, PostgreSQL fallback. */
  async getProfile(userId: string): Promise<PlayerProfile | null> {
    // Cache check
    try {
      const cached = await this.redis.get(PROFILE_CACHE_KEY(userId));
      if (cached) return JSON.parse(cached) as PlayerProfile;
    } catch {
      this.logger.warn('Redis unavailable, serving profile from PostgreSQL', { userId });
    }

    const rows = await this.db.query<PlayerProfile>(
      'SELECT * FROM player_profiles WHERE user_id = $1 AND is_deleted = false',
      [userId],
    );
    if (rows.length === 0) return null;

    const profile = rows[0];
    await this.cacheProfile(profile);
    return profile;
  }

  /**
   * Creates a default profile for a new user.
   * Uses ON CONFLICT DO NOTHING to handle concurrent first-login race conditions.
   */
  async createProfile(userId: string): Promise<PlayerProfile> {
    const displayName = await this.generateUniqueDisplayName();
    const now = new Date().toISOString();

    await this.db.execute(
      `INSERT INTO player_profiles (
        user_id, display_name, avatar_id, region, created_at, last_seen_at,
        total_matches, wins, losses, kills, mmr, peak_mmr, is_provisional,
        provisional_match_count, diamond_balance, has_no_ads, has_play_pass,
        xp, level, unlocked_character_ids, analytics_consent, is_deleted
      ) VALUES (
        $1, $2, 'default_avatar', 'auto', $3, $3,
        0, 0, 0, 0, $4, $4, true,
        0, 0, false, false,
        0, 1, $5, true, false
      ) ON CONFLICT (user_id) DO NOTHING`,
      [userId, displayName, now, DEFAULT_MMR, JSON.stringify(FREE_CHARACTER_IDS)],
    );

    const profile = await this.getProfile(userId);
    if (!profile) throw new Error(`PROFILE_CREATION_FAILED: ${userId}`);
    return profile;
  }

  /** Changes the display name; enforces validation and cooldown. */
  async updateDisplayName(userId: string, newName: string): Promise<PlayerProfile> {
    this.validateDisplayName(newName);

    await this.db.execute(
      `UPDATE player_profiles
       SET display_name = $1, display_name_last_changed_at = NOW()
       WHERE user_id = $2 AND (display_name_last_changed_at IS NULL OR
         display_name_last_changed_at < NOW() - INTERVAL '30 days')`,
      [newName, userId],
    );

    await this.redis.del(PROFILE_CACHE_KEY(userId));
    const updated = await this.getProfile(userId);
    if (!updated) throw new Error('PROFILE_NOT_FOUND');
    return updated;
  }

  /** Increments stats atomically (additive SQL — no read-modify-write). */
  async incrementStats(
    userId: string,
    delta: { wins?: number; losses?: number; kills?: number; totalMatches?: number },
  ): Promise<void> {
    const parts: string[] = [];
    const params: unknown[] = [];
    let idx = 1;
    if (delta.wins)         { parts.push(`wins = wins + $${idx++}`);           params.push(delta.wins); }
    if (delta.losses)       { parts.push(`losses = losses + $${idx++}`);       params.push(delta.losses); }
    if (delta.kills)        { parts.push(`kills = kills + $${idx++}`);         params.push(delta.kills); }
    if (delta.totalMatches) { parts.push(`total_matches = total_matches + $${idx++}`); params.push(delta.totalMatches); }
    if (parts.length === 0) return;
    params.push(userId);
    await this.db.execute(`UPDATE player_profiles SET ${parts.join(', ')} WHERE user_id = $${idx}`, params);
    await this.redis.del(PROFILE_CACHE_KEY(userId));
  }

  /** Called after any economy mutation — pushes profile:refresh to the player. */
  async pushProfileRefresh(userId: string): Promise<void> {
    await this.redis.del(PROFILE_CACHE_KEY(userId));
    const profile = await this.getProfile(userId);
    if (profile) this.io.emitToUser(userId, 'profile:refresh', { profile });
  }

  /** Returns the public-safe subset of a profile. */
  toPublic(profile: PlayerProfile): PublicProfile {
    return {
      user_id: profile.user_id,
      display_name: profile.display_name,
      avatar_id: profile.avatar_id,
      level: profile.level,
      mmr: profile.mmr,
      peak_mmr: profile.peak_mmr,
      total_matches: profile.total_matches,
      wins: profile.wins,
      losses: profile.losses,
      kills: profile.kills,
      preferred_character_id: profile.preferred_character_id,
    };
  }

  /** Computes win_rate at read time (never stored). */
  static computeWinRate(profile: PlayerProfile): number {
    if (profile.total_matches === 0) return 0;
    return Math.round((profile.wins / profile.total_matches) * 1000) / 1000;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  private async cacheProfile(profile: PlayerProfile): Promise<void> {
    try {
      await this.redis.set(PROFILE_CACHE_KEY(profile.user_id), JSON.stringify(profile), PROFILE_CACHE_TTL_SECONDS);
    } catch {
      // Cache failure is non-fatal
    }
  }

  private async generateUniqueDisplayName(attempts = 5): Promise<string> {
    for (let i = 0; i < attempts; i++) {
      const suffix = randomBytes(3).toString('hex').toUpperCase();
      const name = `Player_${suffix}`;
      const rows = await this.db.query(
        'SELECT 1 FROM player_profiles WHERE LOWER(display_name) = LOWER($1)',
        [name],
      );
      if (rows.length === 0) return name;
    }
    return `Player_${randomBytes(4).toString('hex').toUpperCase().slice(0, 8)}`;
  }

  private validateDisplayName(name: string): void {
    if (name.length < 3) throw Object.assign(new Error('DISPLAY_NAME_TOO_SHORT'), { code: 400 });
    if (name.length > 20) throw Object.assign(new Error('DISPLAY_NAME_TOO_LONG'), { code: 400 });
    if (!/^[A-Za-z0-9_-]+$/.test(name)) throw Object.assign(new Error('DISPLAY_NAME_INVALID_CHARS'), { code: 400 });
  }
}
