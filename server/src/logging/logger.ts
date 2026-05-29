import pino, { Logger as PinoLogger } from 'pino';
import { config } from '../config';

/**
 * Structured logger interface — depend on this, not on the concrete pino type.
 *
 * All log lines are emitted as newline-delimited JSON to stdout with the
 * following guaranteed fields: timestamp (ISO 8601), level (string),
 * service ("brawlzone-server"), message, and any caller-supplied metadata.
 *
 * WARNING: Avoid constructing expensive `meta` objects inside the 20 Hz
 * server tick loop. Even when a level is suppressed, argument evaluation
 * still allocates. Prefer pre-built meta objects or omit meta in hot paths.
 */
export interface ILogger {
  debug(msg: string, meta?: Record<string, unknown>): void;
  info(msg: string, meta?: Record<string, unknown>): void;
  warn(msg: string, meta?: Record<string, unknown>): void;
  error(msg: string, meta?: Record<string, unknown>): void;
  fatal(msg: string, meta?: Record<string, unknown>): void;
  /** Returns a child logger with `correlationId` bound to every log line. */
  withCorrelation(correlationId: string): ILogger;
}

/** Options for {@link createLogger}. */
export interface LoggerOptions {
  /**
   * Minimum log level. Defaults to `LOG_LEVEL_PRODUCTION` env var or
   * `'debug'` in development / `'info'` in production.
   */
  level?: string;
  /**
   * Output destination. Defaults to `process.stdout`.
   * Pass a writable stream to redirect output — use this in unit tests to
   * capture log lines without printing to the real stdout.
   */
  destination?: NodeJS.WritableStream;
}

/**
 * Known PII field names. Values for these keys are replaced with `[REDACTED]`
 * and a WARN is emitted identifying the redacted fields.
 * Only top-level metadata keys are checked (no recursive deep scan).
 */
export const PII_FIELDS: ReadonlySet<string> = new Set([
  'email',
  'password',
  'phone',
  'ip',
  'token',
  'refreshToken',
  'accessToken',
]);

/**
 * Scans `meta` for known PII keys. Returns a redacted copy and the list of
 * field names that were redacted. Non-PII fields are passed through unchanged.
 */
export function redactPii(meta: Record<string, unknown>): {
  redacted: Record<string, unknown>;
  fields: string[];
} {
  const redacted: Record<string, unknown> = {};
  const fields: string[] = [];
  for (const [key, value] of Object.entries(meta)) {
    if (PII_FIELDS.has(key)) {
      redacted[key] = '[REDACTED]';
      fields.push(key);
    } else {
      redacted[key] = value;
    }
  }
  return { redacted, fields };
}

function resolveLevel(override?: string): string {
  if (override) return override;
  if (process.env.LOG_LEVEL_PRODUCTION && !config.isDev) {
    return process.env.LOG_LEVEL_PRODUCTION;
  }
  return config.isDev ? 'debug' : 'info';
}

class PinoAdapter implements ILogger {
  constructor(private readonly inner: PinoLogger) {}

  /** Emits a log line, redacting any PII in meta and warning about redacted fields. */
  private emit(
    levelFn: (obj: object, msg: string) => void,
    msg: string,
    meta?: Record<string, unknown>,
  ): void {
    if (!meta) {
      levelFn.call(this.inner, {}, msg);
      return;
    }
    const { redacted, fields } = redactPii(meta);
    if (fields.length > 0) {
      // Emit WARN before the original log line so the redaction is traceable
      this.inner.warn({ event: 'pii_redacted', fields }, `PII redacted from log metadata: ${fields.join(', ')}`);
    }
    levelFn.call(this.inner, redacted, msg);
  }

  debug(msg: string, meta?: Record<string, unknown>): void {
    this.emit(this.inner.debug, msg, meta);
  }

  info(msg: string, meta?: Record<string, unknown>): void {
    this.emit(this.inner.info, msg, meta);
  }

  warn(msg: string, meta?: Record<string, unknown>): void {
    this.emit(this.inner.warn, msg, meta);
  }

  error(msg: string, meta?: Record<string, unknown>): void {
    this.emit(this.inner.error, msg, meta);
  }

  fatal(msg: string, meta?: Record<string, unknown>): void {
    this.emit(this.inner.fatal, msg, meta);
  }

  /**
   * Returns a new ILogger that binds `correlationId` to every emitted line.
   * The parent logger is not affected.
   */
  withCorrelation(correlationId: string): ILogger {
    return new PinoAdapter(this.inner.child({ correlationId }));
  }
}

/**
 * Creates a new {@link ILogger} instance.
 *
 * **Prefer this factory in all unit-tested modules** so the logger can be
 * injected as a dependency and swapped for a stream-capturing logger in tests.
 * The module-level {@link logger} singleton cannot be replaced at test time.
 */
export function createLogger(opts: LoggerOptions = {}): ILogger {
  const level = resolveLevel(opts.level);

  const pinoOptions: pino.LoggerOptions = {
    level,
    // Emit "service" on every line from the base binding
    base: { service: 'brawlzone-server' },
    // Rename pino's default "msg" field to "message" per AC-01 contract
    messageKey: 'message',
    // Rename pino's default "time" field to "timestamp" per AC-01 contract
    timestamp: () => `,"timestamp":"${new Date().toISOString()}"`,
    // Emit level as a human-readable string ("info") instead of an integer (30)
    formatters: {
      level: (label) => ({ level: label }),
    },
  };

  const inner = opts.destination
    ? pino(pinoOptions, opts.destination as pino.DestinationStream)
    : pino(pinoOptions);

  return new PinoAdapter(inner);
}

/**
 * Default singleton logger — writes structured JSON to `process.stdout`.
 *
 * **Use {@link createLogger} for unit-tested modules.** This singleton cannot
 * be swapped in tests; inject a stream-capturing logger via `createLogger`
 * instead to keep tests hermetic.
 */
export const logger: ILogger = createLogger();
