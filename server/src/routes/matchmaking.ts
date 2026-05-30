import { Router, Request, Response } from 'express';

const SOCKET_ONLY_MESSAGE = 'Queue management is socket-only. Connect via WebSocket to join queue.';

/**
 * Informational matchmaking HTTP stubs.
 *
 * These endpoints exist so HTTP clients (health checks, dashboards) can
 * discover the queue API contract. Actual queue operations run over Socket.io.
 *
 * All endpoints return 200 with an informational message — they perform no
 * side effects and require no authentication.
 *
 * Endpoints:
 *   GET  /matchmaking/queue/:mode     — queue info stub
 *   POST /matchmaking/queue/join      — join stub (redirects to socket)
 *   POST /matchmaking/queue/cancel    — cancel stub (redirects to socket)
 */
export function createMatchmakingRouter(): Router {
  const router = Router();

  /** GET /matchmaking/queue/:mode */
  router.get('/queue/:mode', (_req: Request, res: Response): void => {
    res.json({ message: SOCKET_ONLY_MESSAGE });
  });

  /** POST /matchmaking/queue/join */
  router.post('/queue/join', (_req: Request, res: Response): void => {
    res.json({ message: SOCKET_ONLY_MESSAGE });
  });

  /** POST /matchmaking/queue/cancel */
  router.post('/queue/cancel', (_req: Request, res: Response): void => {
    res.json({ message: SOCKET_ONLY_MESSAGE });
  });

  return router;
}
