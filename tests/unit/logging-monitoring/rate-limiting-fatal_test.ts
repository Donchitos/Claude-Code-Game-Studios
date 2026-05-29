import { Writable } from 'stream';
import { createLogger } from '../../../server/src/logging/logger';
import { RateLimitedLogger } from '../../../server/src/logging/rateLimitedLogger';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeCapture(): { stream: Writable; lines: () => string[] } {
  const chunks: string[] = [];
  const stream = new Writable({
    write(chunk: Buffer | string, _enc: BufferEncoding, cb: () => void) {
      chunks.push(chunk.toString());
      cb();
    },
  });
  return {
    stream,
    lines: () =>
      chunks.join('').split('\n').filter((l) => l.trim().length > 0),
  };
}

function parsedLines(lines: string[]): Record<string, unknown>[] {
  return lines.map((l) => JSON.parse(l));
}

// ---------------------------------------------------------------------------
// AC-07: Rate limiting — 100 errors → 10 written + 1 suppression notice
// ---------------------------------------------------------------------------

describe('RateLimitedLogger — rate limiting (AC-07)', () => {
  it('test_rateLimiting_allows10ThenSuppresses', () => {
    const { stream, lines } = makeCapture();
    const base = createLogger({ level: 'debug', destination: stream });
    let t = 0;
    const log = new RateLimitedLogger(base, { limitPerCode: 10, windowMs: 5_000, now: () => t });

    // All 100 calls within the same window (t stays at 0)
    for (let i = 0; i < 100; i++) {
      log.error('DB timeout', { errorCode: 'DB_TIMEOUT' });
    }

    const parsed = parsedLines(lines());
    // 10 error lines + 1 suppression notice WARN = 11 total
    expect(parsed).toHaveLength(11);

    const errorLines = parsed.filter((p) => p.level === 'error');
    expect(errorLines).toHaveLength(10);

    const suppressionLines = parsed.filter((p) => p.level === 'warn' && p.event === 'log_rate_limited');
    expect(suppressionLines).toHaveLength(1);
    expect(suppressionLines[0].errorCode).toBe('DB_TIMEOUT');
  });

  it('test_rateLimiting_suppressionEmittedOnce', () => {
    const { stream, lines } = makeCapture();
    const base = createLogger({ level: 'debug', destination: stream });
    let t = 0;
    const log = new RateLimitedLogger(base, { limitPerCode: 5, windowMs: 5_000, now: () => t });

    for (let i = 0; i < 50; i++) {
      log.error('err', { errorCode: 'CONN_ERR' });
    }

    const parsed = parsedLines(lines());
    const suppressions = parsed.filter((p) => p.event === 'log_rate_limited');
    expect(suppressions).toHaveLength(1); // only one suppression per window
  });

  it('test_rateLimiting_noErrorCodePassesThrough', () => {
    const { stream, lines } = makeCapture();
    const base = createLogger({ level: 'debug', destination: stream });
    const log = new RateLimitedLogger(base, { limitPerCode: 2 });

    // 10 errors WITHOUT errorCode — all should pass through
    for (let i = 0; i < 10; i++) {
      log.error('plain error', { userId: 'abc' });
    }

    const parsed = parsedLines(lines());
    expect(parsed).toHaveLength(10);
  });
});

// ---------------------------------------------------------------------------
// AC-08: FATAL bypasses rate limiting — all 50 written
// ---------------------------------------------------------------------------

describe('RateLimitedLogger — FATAL bypass (AC-08)', () => {
  it('test_fatalBypassesRateLimit_allWritten', () => {
    const { stream, lines } = makeCapture();
    const base = createLogger({ level: 'debug', destination: stream });
    let t = 0;
    const log = new RateLimitedLogger(base, { limitPerCode: 10, windowMs: 5_000, now: () => t });

    for (let i = 0; i < 50; i++) {
      log.fatal('Tick overrun', { errorCode: 'TICK_OVERRUN' });
    }

    const parsed = parsedLines(lines());
    expect(parsed).toHaveLength(50);
    for (const line of parsed) {
      expect(line.level).toBe('fatal');
    }
  });

  it('test_fatalNoSuppression_separateBucketForErrors', () => {
    const { stream, lines } = makeCapture();
    const base = createLogger({ level: 'debug', destination: stream });
    let t = 0;
    const log = new RateLimitedLogger(base, { limitPerCode: 2, windowMs: 5_000, now: () => t });

    // Fill up error bucket then call fatal with same errorCode
    log.error('err1', { errorCode: 'X' });
    log.error('err2', { errorCode: 'X' });
    log.error('err3 suppressed', { errorCode: 'X' });
    log.fatal('fatal1', { errorCode: 'X' });
    log.fatal('fatal2', { errorCode: 'X' });

    const parsed = parsedLines(lines());
    const errors = parsed.filter((p) => p.level === 'error');
    const fatals = parsed.filter((p) => p.level === 'fatal');
    const suppressions = parsed.filter((p) => p.event === 'log_rate_limited');

    expect(errors).toHaveLength(2);
    expect(fatals).toHaveLength(2); // both fatals written despite errorCode bucket being full
    expect(suppressions).toHaveLength(1);
  });
});

// ---------------------------------------------------------------------------
// AC-window-reset: Counter resets after window expires
// ---------------------------------------------------------------------------

describe('RateLimitedLogger — window reset (AC-window-reset)', () => {
  it('test_windowReset_allowsNewLogsAfterExpiry', () => {
    const { stream, lines } = makeCapture();
    const base = createLogger({ level: 'debug', destination: stream });
    let t = 0;
    const log = new RateLimitedLogger(base, { limitPerCode: 3, windowMs: 5_000, now: () => t });

    // Fill the window
    log.error('e1', { errorCode: 'ERR' });
    log.error('e2', { errorCode: 'ERR' });
    log.error('e3', { errorCode: 'ERR' });
    log.error('e4 suppressed', { errorCode: 'ERR' }); // over limit

    // Advance past window boundary
    t = 5_001;

    // New window — should allow logs again
    log.error('e5 new window', { errorCode: 'ERR' });

    const parsed = parsedLines(lines());
    const errors = parsed.filter((p) => p.level === 'error');
    // e1, e2, e3, e5 = 4 errors (e4 was suppressed)
    expect(errors).toHaveLength(4);
    expect(errors[3].message).toBe('e5 new window');
  });
});
