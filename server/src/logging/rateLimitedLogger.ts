import { ILogger } from './logger';

export interface RateLimiterOptions {
  /** Max log lines per errorCode per window. Default: 10. */
  limitPerCode?: number;
  /** Window duration in milliseconds. Default: 5000. */
  windowMs?: number;
  /** Injectable clock for deterministic tests. Default: `Date.now`. */
  now?: () => number;
}

interface BucketState {
  count: number;
  windowStartMs: number;
  suppressionEmitted: boolean;
}

/**
 * Wraps an {@link ILogger} and applies per-errorCode rate limiting to
 * non-FATAL log calls.
 *
 * - Lines without `meta.errorCode` are never rate-limited.
 * - `fatal()` always bypasses rate limiting — every FATAL is written.
 * - When a bucket exceeds the limit for the first time in a window, one
 *   suppression notice is emitted at WARN level.
 *
 * Usage:
 * ```ts
 * const baseLogger = createLogger();
 * const log = new RateLimitedLogger(baseLogger, { limitPerCode: 10 });
 * ```
 */
export class RateLimitedLogger implements ILogger {
  private readonly inner: ILogger;
  private readonly limitPerCode: number;
  private readonly windowMs: number;
  private readonly now: () => number;
  private readonly buckets = new Map<string, BucketState>();

  constructor(inner: ILogger, opts: RateLimiterOptions = {}) {
    this.inner = inner;
    this.limitPerCode = opts.limitPerCode ?? 10;
    this.windowMs = opts.windowMs ?? 5_000;
    this.now = opts.now ?? (() => Date.now());
  }

  /**
   * Returns `true` if the log should be written, `false` if it should be dropped.
   * Emits a suppression notice WARN on the first drop within a window.
   */
  private shouldWrite(errorCode: string | undefined): boolean {
    if (!errorCode) return true;

    const ts = this.now();
    let bucket = this.buckets.get(errorCode);

    if (!bucket || ts - bucket.windowStartMs >= this.windowMs) {
      // New or expired window — reset
      bucket = { count: 0, windowStartMs: ts, suppressionEmitted: false };
      this.buckets.set(errorCode, bucket);
    }

    bucket.count++;

    if (bucket.count <= this.limitPerCode) {
      return true;
    }

    // Over limit — emit suppression notice on first drop only
    if (!bucket.suppressionEmitted) {
      bucket.suppressionEmitted = true;
      this.inner.warn(`Log rate limit reached for errorCode "${errorCode}" — subsequent lines suppressed for this window`, {
        event: 'log_rate_limited',
        errorCode,
        limitPerCode: this.limitPerCode,
        windowMs: this.windowMs,
      });
    }

    return false;
  }

  debug(msg: string, meta?: Record<string, unknown>): void {
    if (this.shouldWrite(meta?.errorCode as string | undefined)) {
      this.inner.debug(msg, meta);
    }
  }

  info(msg: string, meta?: Record<string, unknown>): void {
    if (this.shouldWrite(meta?.errorCode as string | undefined)) {
      this.inner.info(msg, meta);
    }
  }

  warn(msg: string, meta?: Record<string, unknown>): void {
    if (this.shouldWrite(meta?.errorCode as string | undefined)) {
      this.inner.warn(msg, meta);
    }
  }

  error(msg: string, meta?: Record<string, unknown>): void {
    if (this.shouldWrite(meta?.errorCode as string | undefined)) {
      this.inner.error(msg, meta);
    }
  }

  /** FATAL always bypasses rate limiting. Every fatal line is written. */
  fatal(msg: string, meta?: Record<string, unknown>): void {
    this.inner.fatal(msg, meta);
  }

  withCorrelation(correlationId: string): ILogger {
    return new RateLimitedLogger(
      this.inner.withCorrelation(correlationId),
      { limitPerCode: this.limitPerCode, windowMs: this.windowMs, now: this.now },
    );
  }
}
