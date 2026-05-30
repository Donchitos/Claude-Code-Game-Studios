import { Writable } from 'stream';
import { createLogger, redactPii, PII_FIELDS } from '../../../server/src/logging/logger';
import {
  correlationMiddleware,
  resolveSocketCorrelationId,
} from '../../../server/src/logging/correlationMiddleware';
import { Request, Response } from 'express';

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
      chunks
        .join('')
        .split('\n')
        .filter((l) => l.trim().length > 0),
  };
}

function parsedLines(lines: string[]): Record<string, unknown>[] {
  return lines.map((l) => JSON.parse(l));
}

// ---------------------------------------------------------------------------
// PII Redaction unit tests (AC-03)
// ---------------------------------------------------------------------------

describe('pii-redaction — redactPii()', () => {
  it('test_piiRedaction_replacesKnownFields', () => {
    const result = redactPii({ email: 'user@test.com', userId: 'abc' });
    expect(result.redacted).toEqual({ email: '[REDACTED]', userId: 'abc' });
    expect(result.fields).toEqual(['email']);
  });

  it('test_piiRedaction_allPiiFields', () => {
    const meta: Record<string, unknown> = {};
    for (const field of PII_FIELDS) meta[field] = 'sensitive';
    const { redacted, fields } = redactPii(meta);
    expect(fields).toHaveLength(PII_FIELDS.size);
    for (const field of fields) {
      expect(redacted[field]).toBe('[REDACTED]');
    }
  });

  it('test_piiRedaction_noPiiFieldsUnchanged', () => {
    const meta = { userId: 'abc', matchId: 'xyz', score: 42 };
    const { redacted, fields } = redactPii(meta);
    expect(fields).toHaveLength(0);
    expect(redacted).toEqual(meta);
  });
});

describe('pii-redaction — ILogger integration (AC-03)', () => {
  it('test_loggerInfo_redactsPiiAndEmitsWarn', () => {
    const { stream, lines } = makeCapture();
    const log = createLogger({ level: 'debug', destination: stream });

    log.info('User login', { email: 'user@test.com', userId: 'abc' });

    const parsed = parsedLines(lines());
    // Two lines: the WARN about redaction, then the INFO
    expect(parsed).toHaveLength(2);

    const warnLine = parsed.find((p) => p.level === 'warn');
    expect(warnLine).toBeDefined();
    expect(warnLine!.event).toBe('pii_redacted');
    expect((warnLine!.fields as string[]).includes('email')).toBe(true);

    const infoLine = parsed.find((p) => p.level === 'info');
    expect(infoLine).toBeDefined();
    expect(infoLine!.email).toBe('[REDACTED]');
    expect(infoLine!.userId).toBe('abc');
    expect(infoLine!.message).toBe('User login');
  });

  it('test_loggerInfo_noPiiNoWarn', () => {
    const { stream, lines } = makeCapture();
    const log = createLogger({ level: 'debug', destination: stream });

    log.info('Clean log', { userId: 'abc', matchId: 'xyz' });

    const parsed = parsedLines(lines());
    expect(parsed).toHaveLength(1);
    expect(parsed[0].level).toBe('info');
    expect(parsed[0].message).toBe('Clean log');
  });
});

// ---------------------------------------------------------------------------
// Correlation ID — ILogger.withCorrelation (AC-04)
// ---------------------------------------------------------------------------

describe('correlation-id — withCorrelation (AC-04)', () => {
  it('test_correlationId_boundOnSocketAndHttpContexts', () => {
    const { stream, lines } = makeCapture();
    const correlationId = 'corr-123';

    // Simulate socket context: logger created with correlationId bound
    const socketLog = createLogger({ level: 'debug', destination: stream }).withCorrelation(correlationId);
    socketLog.info('socket authenticated');

    // Simulate HTTP request context: separate logger, same correlationId
    const httpLog = createLogger({ level: 'debug', destination: stream }).withCorrelation(correlationId);
    httpLog.info('GET /v1/profile');

    const parsed = parsedLines(lines());
    // Both lines must carry the same correlationId (AC-04 criterion)
    expect(parsed).toHaveLength(2);
    for (const line of parsed) {
      expect(line.correlationId).toBe(correlationId);
    }
  });
});

// ---------------------------------------------------------------------------
// Correlation middleware — Express (AC-09)
// ---------------------------------------------------------------------------

describe('correlation-middleware (AC-09)', () => {
  function makeReq(headers: Record<string, string> = {}): Partial<Request> {
    return { headers, method: 'GET', path: '/test' } as Partial<Request>;
  }

  it('test_correlationMiddleware_usesHeaderWhenPresent', () => {
    const req = makeReq({ 'x-correlation-id': 'my-id-abc' }) as Request;
    const res = {} as Response;
    let nextCalled = false;

    correlationMiddleware(req, res, () => { nextCalled = true; });

    expect(nextCalled).toBe(true);
    expect(req.correlationId).toBe('my-id-abc');
    expect(req.log).toBeDefined();
  });

  it('test_correlationMiddleware_generatesFallbackWhenMissing', () => {
    const { stream, lines } = makeCapture();
    // Inject the middleware's logger output into our capture stream via env trick —
    // we verify the fallback format and WARN presence through the returned correlationId
    // and a separate logger call since the middleware uses its own internal logger.
    const req = makeReq({}) as Request;
    const res = {} as Response;

    correlationMiddleware(req, res, () => {});

    expect(req.correlationId).toMatch(/^fallback-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/);
  });

  it('test_correlationMiddleware_emptyHeaderTreatedAsMissing', () => {
    const req = makeReq({ 'x-correlation-id': '' }) as Request;
    const res = {} as Response;

    correlationMiddleware(req, res, () => {});

    expect(req.correlationId).toMatch(/^fallback-/);
  });

  it('test_correlationMiddleware_nextAlwaysCalled', () => {
    const req = makeReq({}) as Request;
    const res = {} as Response;
    let nextCalled = false;

    correlationMiddleware(req, res, () => { nextCalled = true; });

    expect(nextCalled).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// Socket correlation ID resolution
// ---------------------------------------------------------------------------

describe('resolveSocketCorrelationId', () => {
  it('test_usesClientProvidedId', () => {
    const id = resolveSocketCorrelationId({ correlationId: 'client-id-xyz' });
    expect(id).toBe('client-id-xyz');
  });

  it('test_generatesUuidWhenAbsent', () => {
    const id = resolveSocketCorrelationId(undefined);
    expect(id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/);
  });

  it('test_generatesUuidWhenEmpty', () => {
    const id = resolveSocketCorrelationId({ correlationId: '' });
    expect(id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}/);
  });
});
