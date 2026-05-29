import { Router, Request, Response } from 'express';
import { PlayerProfileService } from '../profile/playerProfileService';
import { ILogger } from '../logging/logger';

// ---------------------------------------------------------------------------
// Local auth interface — avoids global namespace augmentation
// ---------------------------------------------------------------------------

interface AuthenticatedRequest extends Request {
  userId: string;
}

/** Cast helper to keep route handlers concise. */
function auth(req: Request): AuthenticatedRequest {
  return req as AuthenticatedRequest;
}

// ---------------------------------------------------------------------------
// Mock profile returned when Supabase / DB is unavailable (local dev)
// ---------------------------------------------------------------------------

function buildMockProfile(userId: string) {
  return {
    user_id: userId,
    display_name: 'LocalPlayer',
    avatar_id: 'default_avatar',
    region: 'auto',
    created_at: new Date().toISOString(),
    last_seen_at: new Date().toISOString(),
    total_matches: 0,
    wins: 0,
    losses: 0,
    kills: 0,
    preferred_character_id: null,
    mmr: 1000,
    peak_mmr: 1000,
    is_provisional: true,
    diamond_balance: 0,
    has_no_ads: false,
    has_play_pass: false,
    xp: 0,
    level: 1,
    coin_balance: 0,
    unlocked_character_ids: ['character:vex', 'character:zook', 'character:sera'],
    analytics_consent: true,
  };
}

// ---------------------------------------------------------------------------
// Route factory
// ---------------------------------------------------------------------------

/**
 * Mounts profile REST endpoints onto the provided router.
 *
 * All routes require the calling middleware to have populated `req.userId`
 * (set by the auth middleware in index.ts before reaching these handlers).
 *
 * Endpoints:
 *   GET  /profile/me          — own full profile
 *   GET  /profile/:userId     — public profile of another player
 *   PUT  /profile/me/name     — update own display name
 */
export function createProfileRouter(
  service: PlayerProfileService,
  logger: ILogger,
): Router {
  const router = Router();

  /** GET /profile/me */
  router.get('/me', async (req: Request, res: Response): Promise<void> => {
    const userId = auth(req).userId;
    try {
      let profile = await service.getProfile(userId);
      if (!profile) {
        profile = await service.createProfile(userId);
      }
      res.json({ profile });
    } catch (err) {
      logger.warn('PROFILE_DB_UNAVAILABLE', { userId, err: String(err) });
      // Return mock profile so the game remains playable without a DB connection
      res.json({ profile: buildMockProfile(userId), _mock: true });
    }
  });

  /** GET /profile/:userId */
  router.get('/:userId', async (req: Request, res: Response): Promise<void> => {
    const targetId = req.params['userId'];
    try {
      const profile = await service.getProfile(targetId);
      if (!profile) {
        res.status(404).json({ error: 'PROFILE_NOT_FOUND' });
        return;
      }
      res.json({ profile: service.toPublic(profile) });
    } catch (err) {
      logger.warn('PROFILE_DB_UNAVAILABLE', { targetId, err: String(err) });
      res.status(503).json({ error: 'PROFILE_SERVICE_UNAVAILABLE' });
    }
  });

  /** PUT /profile/me/name */
  router.put('/me/name', async (req: Request, res: Response): Promise<void> => {
    const userId = auth(req).userId;
    const { displayName } = req.body as { displayName?: string };

    if (!displayName || typeof displayName !== 'string') {
      res.status(400).json({ error: 'MISSING_DISPLAY_NAME' });
      return;
    }

    try {
      const updated = await service.updateDisplayName(userId, displayName);
      res.json({ profile: updated });
    } catch (err: unknown) {
      const typed = err as { message?: string; code?: number };
      const knownCodes = ['DISPLAY_NAME_TOO_SHORT', 'DISPLAY_NAME_TOO_LONG', 'DISPLAY_NAME_INVALID_CHARS'];
      if (knownCodes.some(c => typed.message?.startsWith(c))) {
        res.status(typed.code ?? 400).json({ error: typed.message });
        return;
      }
      logger.error('PROFILE_UPDATE_NAME_FAILED', { userId, err: String(err) });
      res.status(500).json({ error: 'INTERNAL_ERROR' });
    }
  });

  return router;
}
