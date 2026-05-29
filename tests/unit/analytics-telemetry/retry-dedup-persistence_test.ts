import { AnalyticsService, IStorageAdapter, IHttpAdapter } from '../../../server/src/analytics/analyticsService';
import { createLogger } from '../../../server/src/logging/logger';
import { Writable } from 'stream';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeStorage(): { adapter: IStorageAdapter; store: Record<string, string> } {
  const store: Record<string, string> = {};
  return {
    store,
    adapter: {
      getItem: async (k) => store[k] ?? null,
      setItem: async (k, v) => { store[k] = v; },
    },
  };
}

function nullLogger() {
  return createLogger({ level: 'fatal', destination: new Writable({ write: (_c, _e, cb) => cb() }) });
}

function buildService(opts: {
  statusSequence?: number[];
  batchSize?: number;
  maxRetries?: number;
  analyticsConsent?: boolean;
  storage?: IStorageAdapter;
}) {
  const { adapter: storage, store } = makeStorage();
  let callIdx = 0;
  const seq = opts.statusSequence ?? [200];
  let httpCallCount = 0;
  const http: IHttpAdapter = {
    post: async () => {
      httpCallCount++;
      const status = seq[Math.min(callIdx++, seq.length - 1)];
      return { status };
    },
  };
  const service = new AnalyticsService({
    userId: 'u1',
    sessionId: 's1',
    analyticsConsent: opts.analyticsConsent ?? true,
    platform: 'ios',
    appVersion: '1.0.0',
    flushUrl: 'http://localhost/analytics',
    storage: opts.storage ?? storage,
    http,
    logger: nullLogger(),
    batchSize: opts.batchSize ?? 100,
    maxRetries: opts.maxRetries ?? 3,
  });
  return { service, store: opts.storage ? {} as Record<string, string> : store, getHttpCalls: () => httpCallCount };
}

// ---------------------------------------------------------------------------
// AC-08: Retry on server error — 3 attempts total
// ---------------------------------------------------------------------------

describe('retry — on server error (AC-08)', () => {
  it('test_retry_deliversOnThirdAttempt', async () => {
    const { service, getHttpCalls } = buildService({ statusSequence: [500, 500, 200], maxRetries: 3 });

    service.track('MATCH_ENDED', { x: 1 });

    // Three flush calls to simulate retries
    await service.flush();
    await service.flush();
    await service.flush();

    expect(getHttpCalls()).toBe(3);
    expect(service.queueSize).toBe(0); // cleared on success
  });

  it('test_retry_keepsQueueAfterMaxRetries', async () => {
    const { service, getHttpCalls } = buildService({ statusSequence: [500, 500, 500, 500], maxRetries: 3 });

    service.track('MATCH_ENDED', { x: 1 });

    await service.flush();
    await service.flush();
    await service.flush();
    await service.flush(); // 4th call — maxRetries exceeded, resets counter, keeps queue

    // Events remain in queue (not discarded — held for next natural interval)
    expect(service.queueSize).toBe(1);
  });
});

// ---------------------------------------------------------------------------
// AC-09: Deduplication — same eventId batch sent twice
// ---------------------------------------------------------------------------

describe('dedup — processBatch (AC-09)', () => {
  it('test_dedup_ignoresSeenEventIds', () => {
    const { service } = buildService({});
    const logger = nullLogger();
    const now = Date.now();

    const events = Array.from({ length: 5 }, (_, i) => ({
      eventId: `evt-${i}`,
      userId: 'u1',
      sessionId: 's1',
      clientTimestamp: now,
      serverTimestamp: now,
      eventName: 'MATCH_ENDED',
      eventVersion: '1',
      platform: 'ios',
      appVersion: '1.0.0',
      properties: { i },
    }));

    // First batch — all 5 processed
    const first = service.processBatch(events, now, logger);
    expect(first).toHaveLength(5);

    // Second batch — same eventIds — all deduplicated
    const second = service.processBatch(events, now, logger);
    expect(second).toHaveLength(0);
  });

  it('test_dedup_returnsNewEventsAlongside', () => {
    const { service } = buildService({});
    const logger = nullLogger();
    const now = Date.now();

    const batch1 = [{ eventId: 'a', userId: 'u1', sessionId: 's1', clientTimestamp: now,
      serverTimestamp: now, eventName: 'MATCH_ENDED', eventVersion: '1', platform: 'ios', appVersion: '1.0.0', properties: {} }];
    const batch2 = [
      { ...batch1[0], eventId: 'a' }, // duplicate
      { ...batch1[0], eventId: 'b' }, // new
    ];

    service.processBatch(batch1, now, logger);
    const result = service.processBatch(batch2, now, logger);
    expect(result).toHaveLength(1);
    expect(result[0].eventId).toBe('b');
  });
});

// ---------------------------------------------------------------------------
// AC-10: Consent revocation purges Tier 1 from queue
// ---------------------------------------------------------------------------

describe('consent-revocation — purges Tier 1 (AC-10)', () => {
  it('test_revokeConsent_removesTier1_keepsTier0', async () => {
    const { adapter: storage, store } = makeStorage();
    const service = new AnalyticsService({
      userId: 'u1',
      sessionId: 's1',
      analyticsConsent: true,
      platform: 'ios',
      appVersion: '1.0.0',
      flushUrl: 'http://localhost/analytics',
      storage,
      http: { post: async () => ({ status: 200 }) },
      logger: nullLogger(),
      batchSize: 1000,
    });

    // Enqueue 30 Tier 1 + 5 Tier 0 events
    for (let i = 0; i < 30; i++) service.track('ECONOMY_DIAMOND_SPENT', { i });
    for (let i = 0; i < 5; i++) service.track('MATCH_ENDED', { i });
    expect(service.queueSize).toBe(35);

    await service.revokeConsent();

    expect(service.queueSize).toBe(5);

    // Storage should also only have Tier 0 events
    const stored = JSON.parse(store['analytics_queue'] ?? '[]') as Array<{ eventName: string }>;
    expect(stored).toHaveLength(5);
    expect(stored.every(e => e.eventName === 'MATCH_ENDED')).toBe(true);
  });
});
