import { Router, Request, Response } from 'express';
import { IContentCatalog, ContentType } from '../catalog/contentCatalog';
import { ILogger } from '../logging/logger';

const VALID_CONTENT_TYPES: ReadonlySet<string> = new Set<ContentType>([
  'character', 'ability', 'mode', 'map', 'iap_pack', 'cosmetic', 'quest_template', 'battle_pass_season',
]);

/**
 * Mounts catalog REST endpoints onto the provided router.
 *
 * If `catalog` is null (startup load failed), all endpoints return 503.
 *
 * Endpoints:
 *   GET /catalog/:type          — list all records of a content type
 *   GET /catalog/record/:id     — get a single record by full ID
 */
export function createCatalogRouter(
  catalog: IContentCatalog | null,
  logger: ILogger,
): Router {
  const router = Router();

  /** Guard: catalog failed to load at startup. */
  function unavailable(res: Response): boolean {
    if (!catalog) {
      res.status(503).json({ error: 'CATALOG_UNAVAILABLE' });
      return true;
    }
    return false;
  }

  /** GET /catalog/:type */
  router.get('/:type', (req: Request, res: Response): void => {
    if (unavailable(res)) return;

    const { type } = req.params;
    if (!VALID_CONTENT_TYPES.has(type)) {
      res.status(400).json({ error: 'UNKNOWN_CONTENT_TYPE', valid: Array.from(VALID_CONTENT_TYPES) });
      return;
    }

    const records = catalog!.getAll(type as ContentType);
    res.json({ type, count: records.length, records });
  });

  /** GET /catalog/record/:id — must be mounted BEFORE /:type to avoid shadowing */
  router.get('/record/:id', (req: Request, res: Response): void => {
    if (unavailable(res)) return;

    const { id } = req.params;
    const record = catalog!.get(id);
    if (!record) {
      res.status(404).json({ error: 'RECORD_NOT_FOUND', id });
      return;
    }
    res.json({ record });
  });

  logger.info('CATALOG_ROUTER_MOUNTED', { available: catalog !== null });
  return router;
}
