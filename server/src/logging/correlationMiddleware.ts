import { Request, Response, NextFunction } from 'express';
import { randomUUID } from 'crypto';
import { createLogger, ILogger } from './logger';

// Extend Express Request type to carry the correlation ID and a bound logger
declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      /** Correlation ID propagated from `X-Correlation-ID` header or auto-generated. */
      correlationId: string;
      /** Per-request logger with `correlationId` pre-bound on every line. */
      log: ILogger;
    }
  }
}

const middlewareLogger = createLogger();

/**
 * Express middleware that guarantees every request carries a correlation ID.
 *
 * - If the request includes a non-empty `X-Correlation-ID` header, that value
 *   is used as-is.
 * - Otherwise a `fallback-{uuid}` ID is generated and a WARN is logged.
 *
 * Attaches `req.correlationId` (string) and `req.log` (ILogger with the ID
 * bound) for use by downstream handlers.
 */
export function correlationMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction,
): void {
  const headerValue = req.headers['x-correlation-id'];
  const fromHeader = typeof headerValue === 'string' && headerValue.length > 0;

  const correlationId = fromHeader
    ? (headerValue as string)
    : `fallback-${randomUUID()}`;

  if (!fromHeader) {
    middlewareLogger.warn('Request missing X-Correlation-ID header', {
      correlationId,
      method: req.method,
      path: req.path,
    });
  }

  req.correlationId = correlationId;
  req.log = createLogger().withCorrelation(correlationId);

  next();
}

/**
 * Returns the correlationId to attach to a Socket.io socket after authentication.
 * Call this in the Socket.io auth middleware and store the result on `socket.data`.
 *
 * If the client passes `auth.correlationId`, it is used as-is.
 * Otherwise a new UUID is generated.
 */
export function resolveSocketCorrelationId(
  auth: Record<string, unknown> | undefined,
): string {
  const fromClient = typeof auth?.correlationId === 'string' && (auth.correlationId as string).length > 0;
  return fromClient ? (auth!.correlationId as string) : randomUUID();
}
