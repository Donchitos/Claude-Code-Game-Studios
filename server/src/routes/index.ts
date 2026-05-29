import { Router, Request, Response, NextFunction } from 'express';
import { SupabaseClient } from '@supabase/supabase-js';
import { ILogger } from '../logging/logger';
import { PlayerProfileService } from '../profile/playerProfileService';
import { IContentCatalog } from '../catalog/contentCatalog';
import { createProfileRouter } from './profile';
import { createCatalogRouter } from './catalog';
import { createMatchmakingRouter } from './matchmaking';

// ---------------------------------------------------------------------------
// Auth middleware — validates Supabase JWT, injects userId into req
// ---------------------------------------------------------------------------

interface AuthenticatedRequest extends Request {
  userId: string;
}

/**
 * Express middleware that validates the Bearer token from the Authorization
 * header using Supabase auth. On success, attaches `req.userId`.
 * On failure, responds 401 and does NOT call next().
 */
function makeAuthMiddleware(supabase: SupabaseClient, logger: ILogger) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    const authHeader = req.headers['authorization'];
    if (!authHeader?.startsWith('Bearer ')) {
      res.status(401).json({ error: 'AUTH_REQUIRED' });
      return;
    }

    const token = authHeader.slice(7);
    try {
      const { data, error } = await supabase.auth.getUser(token);
      if (error || !data.user) {
        res.status(401).json({ error: 'AUTH_INVALID' });
        return;
      }
      (req as AuthenticatedRequest).userId = data.user.id;
      next();
    } catch (err) {
      logger.error('AUTH_MIDDLEWARE_FAILED', { err: String(err) });
      res.status(503).json({ error: 'AUTH_SERVICE_UNAVAILABLE' });
    }
  };
}

// ---------------------------------------------------------------------------
// Router factory
// ---------------------------------------------------------------------------

export interface ApiRouterDeps {
  supabase: SupabaseClient;
  profileService: PlayerProfileService;
  catalog: IContentCatalog | null;
  logger: ILogger;
}

/**
 * Creates the top-level API router and mounts all sub-routers.
 *
 * Route map:
 *   /profile/*      — authenticated, PlayerProfileService-backed
 *   /catalog/*      — public, ContentCatalogService-backed (503 if unavailable)
 *   /matchmaking/*  — public, informational stubs only
 */
export function createApiRouter(deps: ApiRouterDeps): Router {
  const { supabase, profileService, catalog, logger } = deps;
  const router = Router();

  const authMiddleware = makeAuthMiddleware(supabase, logger);

  // Profile routes — require auth
  router.use('/profile', authMiddleware, createProfileRouter(profileService, logger));

  // Catalog routes — public (no auth)
  router.use('/catalog', createCatalogRouter(catalog, logger));

  // Matchmaking stubs — public (no auth)
  router.use('/matchmaking', createMatchmakingRouter());

  return router;
}
