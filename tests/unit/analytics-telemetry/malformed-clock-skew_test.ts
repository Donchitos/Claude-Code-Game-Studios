import { AnalyticsService } from '../../../server/src/analytics/analyticsService';
import { createLogger } from '../../../server/src/logging/logger';
import { Writable } from 'stream';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeCapture() {
  const chunks: string[] = [];
  const stream = new Writable({ write: (c: Buffer, _e: BufferEncoding, cb: () => void) => { chunks.push(c.toString()); cb(); } });
  const logger = createLogger({ level: 'debug', destination: stream });
  const lines = () => chunks.join('').split('\n').filter(l => l.trim()).map(l => JSON.parse(l));
  return { logger, lines };
}

function nullLogger() {
  return createLogger({ level: 'fatal', destination: new Writable({ write: (_c, _e, cb) => cb() }) });
}

function buildService(opts: {
  userId?: string;
  analyticsConsent?: boolean;
  uiEventSampleRate?: number;
  random?: () => number;
  logger?: ReturnType<typeof createLogger>;
}) {
  return new AnalyticsService({
    userId: opts.userId ?? 'u1',
    sessionId: 's1',
    analyticsConsent: opts.analyticsConsent ?? true,
    platform: 'ios',
    appVersion: '1.0.0',
    flushUrl: 'http://localhost/analytics',
    storage: { getItem: async () => null, setItem: async () => {} },
    http: { post: async () => ({ status: 200 }) },
    logger: opts.logger ?? nullLogger(),
    uiEventSampleRate: opts.uiEventSampleRate,
    random: opts.random,
    batchSize: 10_000,
  });
}

// ---------------------------------------------------------------------------
// AC-11: Clock skew detected server-side
// ---------------------------------------------------------------------------

describe('clock-skew — server-side detection (AC-11)', () => {
  it('test_clockSkew_flaggedWhenOver60s', () => {
    const { logger, lines } = makeCapture();
    const service = buildService({ logger: nullLogger() }); // skew is in processBatch

    const serverNow = 1_000_000_000;
    const clientTs = serverNow - 90_000; // 90s behind

    const event = {
      eventId: 'e1', userId: 'u1', sessionId: 's1',
      clientTimestamp: clientTs, serverTimestamp: clientTs,
      eventName: 'MATCH_ENDED', eventVersion: '1',
      platform: 'ios', appVersion: '1.0.0', properties: {},
    };

    const { logger: processingLogger, lines: processingLines } = makeCapture();
    const result = service.processBatch([event], serverNow, processingLogger);

    expect(result).toHaveLength(1);
    expect(result[0].clockSkewSec).toBe(90);
    expect(result[0].serverTimestamp).toBe(serverNow);

    const warnLines = processingLines().filter(l => l.level === 'warn');
    expect(warnLines.length).toBeGreaterThanOrEqual(1);
  });

  it('test_clockSkew_notFlaggedUnder60s', () => {
    const service = buildService({});
    const { logger, lines } = makeCapture();

    const serverNow = 1_000_000_000;
    const event = {
      eventId: 'e2', userId: 'u1', sessionId: 's1',
      clientTimestamp: serverNow - 30_000, // 30s behind — under threshold
      serverTimestamp: serverNow - 30_000,
      eventName: 'MATCH_ENDED', eventVersion: '1',
      platform: 'ios', appVersion: '1.0.0', properties: {},
    };

    const result = service.processBatch([event], serverNow, logger);
    expect(result[0].clockSkewSec).toBeUndefined();
  });
});

// ---------------------------------------------------------------------------
// AC-12: Sample rate applied to UI events
// ---------------------------------------------------------------------------

describe('sample-rate — UI events (AC-12)', () => {
  it('test_sampleRate_exactlyHalfWithAlternatingRandom', () => {
    let toggle = false;
    // Alternates: 0.4 (below 0.5 threshold → enqueue), 0.6 (above → skip)
    const deterministicRandom = () => { toggle = !toggle; return toggle ? 0.4 : 0.6; };

    const service = buildService({ uiEventSampleRate: 0.5, random: deterministicRandom });

    for (let i = 0; i < 1000; i++) {
      service.track('UI_SCREEN_VIEWED', { screen: `Screen${i}` });
    }

    // With alternating random: exactly 500 pass (0.4 <= 0.5) and 500 skip (0.6 > 0.5)
    expect(service.queueSize).toBe(500);
  });

  it('test_sampleRate_1_0_keepsAllEvents', () => {
    const service = buildService({ uiEventSampleRate: 1.0 });
    for (let i = 0; i < 100; i++) service.track('UI_SCREEN_VIEWED', { i });
    expect(service.queueSize).toBe(100);
  });

  it('test_sampleRate_0_dropsAllEvents', () => {
    const service = buildService({ uiEventSampleRate: 0, random: () => 0.001 });
    for (let i = 0; i < 100; i++) service.track('UI_SCREEN_VIEWED', { i });
    // 0.001 > 0 is true → all dropped
    expect(service.queueSize).toBe(0);
  });

  it('test_nonSampledEvents_notAffectedBySampleRate', () => {
    const service = buildService({ uiEventSampleRate: 0, random: () => 0.001 });
    // MATCH_ENDED is not a sampled event — not subject to sample rate
    service.track('MATCH_ENDED', { matchId: 'x' });
    expect(service.queueSize).toBe(1);
  });
});

// ---------------------------------------------------------------------------
// AC-13: Malformed event dropped client-side
// ---------------------------------------------------------------------------

describe('malformed-events — dropped with WARN (AC-13)', () => {
  it('test_missingUserId_dropsEventAndWarns', async () => {
    const { logger, lines } = makeCapture();
    const service = buildService({ userId: '', logger }); // empty userId = missing

    service.track('MATCH_ENDED', { matchId: 'abc' });

    expect(service.queueSize).toBe(0);
    const warnLines = lines().filter(l => l.level === 'warn');
    expect(warnLines.length).toBeGreaterThanOrEqual(1);
    expect(JSON.stringify(warnLines[0])).toContain('userId');
  });

  it('test_missingEventName_dropsEvent', () => {
    const { logger, lines } = makeCapture();
    const service = buildService({ logger });

    // Pass empty string as event name
    service.track('', { matchId: 'abc' });

    expect(service.queueSize).toBe(0);
    const warnLines = lines().filter(l => l.level === 'warn');
    expect(warnLines.length).toBeGreaterThanOrEqual(1);
  });

  it('test_validEvent_noWarnEmitted', () => {
    const { logger, lines } = makeCapture();
    const service = buildService({ logger });

    service.track('MATCH_ENDED', { matchId: 'abc' });

    expect(service.queueSize).toBe(1);
    const warnLines = lines().filter(l => l.level === 'warn');
    expect(warnLines).toHaveLength(0);
  });
});
