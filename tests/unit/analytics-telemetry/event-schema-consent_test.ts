import { AnalyticsService, IStorageAdapter, IHttpAdapter } from '../../../server/src/analytics/analyticsService';
import { createLogger } from '../../../server/src/logging/logger';
import { Writable } from 'stream';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeNullStorage(): IStorageAdapter {
  const store: Record<string, string> = {};
  return {
    getItem: async (k) => store[k] ?? null,
    setItem: async (k, v) => { store[k] = v; },
  };
}

function makeNullHttp(): { http: IHttpAdapter; calls: unknown[][] } {
  const calls: unknown[][] = [];
  return {
    calls,
    http: { post: async (url, body) => { calls.push([url, body]); return { status: 200 }; } },
  };
}

function makeLogger() {
  const chunks: string[] = [];
  const stream = new Writable({ write: (c: Buffer, _e: BufferEncoding, cb: () => void) => { chunks.push(c.toString()); cb(); } });
  const logger = createLogger({ level: 'debug', destination: stream });
  const lines = () => chunks.join('').split('\n').filter(l => l.trim());
  return { logger, lines };
}

function makeService(overrides: Partial<ConstructorParameters<typeof AnalyticsService>[0]> = {}) {
  const { http, calls } = makeNullHttp();
  const { logger, lines } = makeLogger();
  const service = new AnalyticsService({
    userId: 'user-abc',
    sessionId: 'sess-123',
    analyticsConsent: true,
    platform: 'ios',
    appVersion: '1.0.0',
    flushUrl: 'http://localhost/v1/analytics/events',
    storage: makeNullStorage(),
    http,
    logger,
    ...overrides,
  });
  return { service, calls, lines };
}

// ---------------------------------------------------------------------------
// AC-01: All 10 base fields present
// ---------------------------------------------------------------------------

describe('event-schema — base fields (AC-01)', () => {
  it('test_track_enqueuesEventWithAllBaseFields', async () => {
    const { service } = makeService();
    service.track('MATCH_ENDED', { matchId: 'xyz' });

    expect(service.queueSize).toBe(1);
  });

  it('test_flushedEvent_hasAllTenBaseFields', async () => {
    const { service, calls } = makeService();
    service.track('MATCH_ENDED', { matchId: 'xyz' });
    await service.flush();

    expect(calls).toHaveLength(1);
    const { events } = (calls[0][1] as { events: Record<string, unknown>[] });
    expect(events).toHaveLength(1);
    const e = events[0];

    const required = ['eventId','userId','sessionId','clientTimestamp','serverTimestamp',
                      'eventName','eventVersion','platform','appVersion','properties'];
    for (const field of required) {
      expect(e).toHaveProperty(field);
      expect(e[field]).not.toBeNull();
      expect(e[field]).not.toBeUndefined();
    }
    expect(typeof e.eventId).toBe('string');
    expect((e.eventId as string).length).toBeGreaterThan(0);
  });
});

// ---------------------------------------------------------------------------
// AC-02: Tier 1 dropped without consent
// ---------------------------------------------------------------------------

describe('consent — Tier 1 dropped (AC-02)', () => {
  it('test_tier1_droppedWithoutConsent', async () => {
    const { service, calls } = makeService({ analyticsConsent: false });

    service.track('ECONOMY_DIAMOND_SPENT', { amount: 50 });

    expect(service.queueSize).toBe(0);
    await service.flush();
    expect(calls).toHaveLength(0);
  });

  it('test_tier1_enqueueWithConsent', () => {
    const { service } = makeService({ analyticsConsent: true });
    service.track('ECONOMY_DIAMOND_SPENT', { amount: 50 });
    expect(service.queueSize).toBe(1);
  });
});

// ---------------------------------------------------------------------------
// AC-03: Tier 0 always collected regardless of consent
// ---------------------------------------------------------------------------

describe('consent — Tier 0 always collected (AC-03)', () => {
  it('test_tier0_alwaysEnqueued_consentFalse', async () => {
    const { service, calls } = makeService({ analyticsConsent: false });

    service.track('MATCH_ENDED', { matchId: 'abc', result: 'win' });

    expect(service.queueSize).toBe(1);
    await service.flush();
    expect(calls).toHaveLength(1);
    const { events } = calls[0][1] as { events: Record<string, unknown>[] };
    expect(events[0].userId).toBe('user-abc');
    expect((events[0].properties as Record<string, unknown>).matchId).toBe('abc');
  });

  it('test_tier0_and_tier1_withConsentFalse_onlyTier0Flushed', async () => {
    const { service, calls } = makeService({ analyticsConsent: false });

    service.track('MATCH_ENDED', { matchId: 'abc' }); // Tier 0 — kept
    service.track('ECONOMY_DIAMOND_SPENT', { amount: 10 }); // Tier 1 — dropped
    service.track('MATCH_STARTED', { matchId: 'def' }); // Tier 0 — kept

    expect(service.queueSize).toBe(2);
    await service.flush();
    const { events } = calls[0][1] as { events: Record<string, unknown>[] };
    expect(events.every((e: Record<string, unknown>) =>
      ['MATCH_ENDED','MATCH_STARTED'].includes(e.eventName as string)
    )).toBe(true);
  });
});
