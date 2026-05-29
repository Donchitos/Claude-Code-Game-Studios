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

function makeHttp(statusSequence: number[] = [200]): { http: IHttpAdapter; calls: number } {
  let idx = 0;
  let calls = 0;
  return {
    get calls() { return calls; },
    http: {
      post: async () => {
        calls++;
        const status = statusSequence[Math.min(idx++, statusSequence.length - 1)];
        return { status };
      },
    },
  };
}

function nullLogger() {
  return createLogger({ level: 'fatal', destination: new Writable({ write: (_c, _e, cb) => cb() }) });
}

function buildService(opts: {
  http?: IHttpAdapter;
  storage?: IStorageAdapter;
  batchSize?: number;
  flushIntervalMs?: number;
  maxRetries?: number;
}) {
  const { adapter: storage, store } = makeStorage();
  const logger = nullLogger();
  const service = new AnalyticsService({
    userId: 'u1',
    sessionId: 's1',
    analyticsConsent: true,
    platform: 'ios',
    appVersion: '1.0.0',
    flushUrl: 'http://localhost/analytics',
    storage: opts.storage ?? storage,
    http: opts.http ?? { post: async () => ({ status: 200 }) },
    logger,
    batchSize: opts.batchSize,
    flushIntervalMs: opts.flushIntervalMs,
    maxRetries: opts.maxRetries,
  });
  return { service, store };
}

// ---------------------------------------------------------------------------
// AC-04: Interval flush
// ---------------------------------------------------------------------------

describe('batch-flush — interval (AC-04)', () => {
  it('test_intervalFlush_flushesQueuedEvents', async () => {
    let postCount = 0;
    const http: IHttpAdapter = { post: async () => { postCount++; return { status: 200 }; } };
    const { service } = buildService({ http });

    for (let i = 0; i < 5; i++) service.track('MATCH_ENDED', { i });
    expect(service.queueSize).toBe(5);

    await service.flush();

    expect(postCount).toBe(1);
    expect(service.queueSize).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// AC-05: Size threshold triggers immediate flush
// ---------------------------------------------------------------------------

describe('batch-flush — size threshold (AC-05)', () => {
  it('test_sizeThreshold_triggersFlushAt50', async () => {
    let postCount = 0;
    const http: IHttpAdapter = { post: async () => { postCount++; return { status: 200 }; } };
    const { service } = buildService({ http, batchSize: 50 });

    // Enqueue 49 — no flush yet
    for (let i = 0; i < 49; i++) service.track('MATCH_ENDED', { i });
    // Flush is async; give it a tick
    await Promise.resolve();
    expect(postCount).toBe(0);

    // 50th event triggers flush
    service.track('MATCH_ENDED', { i: 49 });
    await Promise.resolve();
    expect(postCount).toBe(1);
  });

  it('test_sizeThreshold_queueClearedAfterFlush', async () => {
    const http: IHttpAdapter = { post: async () => ({ status: 200 }) };
    const { service } = buildService({ http, batchSize: 10 });

    for (let i = 0; i < 10; i++) service.track('MATCH_ENDED', { i });
    await Promise.resolve();
    await Promise.resolve(); // flush is async; two ticks to settle

    expect(service.queueSize).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// AC-06: Background flush (app backgrounded → flush)
// ---------------------------------------------------------------------------

describe('batch-flush — background (AC-06)', () => {
  it('test_backgroundFlush_triggeredManually', async () => {
    let postCount = 0;
    const http: IHttpAdapter = { post: async () => { postCount++; return { status: 200 }; } };
    const { service } = buildService({ http });

    for (let i = 0; i < 10; i++) service.track('MATCH_ENDED', { i });

    // Simulate AppState background event — caller calls flush() directly
    await service.flush();

    expect(postCount).toBe(1);
    expect(service.queueSize).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// AC-07: Crash recovery — load from storage on restart
// ---------------------------------------------------------------------------

describe('batch-flush — crash recovery (AC-07)', () => {
  it('test_crashRecovery_loadsFromStorageOnInit', async () => {
    const { adapter: storage, store } = makeStorage();

    // Simulate 20 events persisted before crash
    const fakeEvents = Array.from({ length: 20 }, (_, i) => ({
      eventId: `evt-${i}`,
      userId: 'u1',
      sessionId: 's1',
      clientTimestamp: Date.now(),
      serverTimestamp: Date.now(),
      eventName: 'MATCH_ENDED',
      eventVersion: '1',
      platform: 'ios',
      appVersion: '1.0.0',
      properties: { i },
    }));
    store['analytics_queue'] = JSON.stringify(fakeEvents);

    const logger = nullLogger();
    const service = new AnalyticsService({
      userId: 'u1',
      sessionId: 's1',
      analyticsConsent: true,
      platform: 'ios',
      appVersion: '1.0.0',
      flushUrl: 'http://localhost/analytics',
      storage,
      http: { post: async () => ({ status: 200 }) },
      logger,
    });

    // Simulate app restart: loadQueue()
    await service.loadQueue();
    expect(service.queueSize).toBe(20);
  });
});
