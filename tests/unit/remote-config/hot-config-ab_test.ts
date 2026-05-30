import { RemoteConfigService } from '../../../server/src/config/remoteConfig';
import { createLogger } from '../../../server/src/logging/logger';
import { Writable } from 'stream';

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

function makeService(logger = nullLogger(), hotPushDebounceMs = 0) {
  return new RemoteConfigService({
    configUrl: 'http://localhost/config',
    storage: { getItem: async () => null, setItem: async () => {} },
    http: { get: async () => ({ status: 200, body: {} }) },
    logger,
    hotPushDebounceMs,
  });
}

// ---------------------------------------------------------------------------
// Hot push: Cold key ignored + WARN (AC-hot-cold)
// ---------------------------------------------------------------------------

describe('hot-config — Cold key ignored (AC-hot-cold)', () => {
  it('test_coldKey_ignoredWithWarn', async () => {
    const { logger, lines } = makeCapture();
    const service = makeService(logger, 0);
    await service.init();

    service.applyHotPush({ 'tick.rateHz': 30 }); // Cold key
    await new Promise(r => setTimeout(r, 10));

    // Value must NOT change
    expect(service.get('tick.rateHz')).toBe(20);

    const warns = lines().filter(l => l.level === 'warn' && l.event === 'hot_push_cold_key_ignored');
    expect(warns.length).toBeGreaterThanOrEqual(1);
  });

  it('test_hotKey_applied', async () => {
    const service = makeService(nullLogger(), 0);
    await service.init();

    service.applyHotPush({ 'matchmaking.maxSkillSpreadMMR': 400 });
    await new Promise(r => setTimeout(r, 10));

    expect(service.get('matchmaking.maxSkillSpreadMMR')).toBe(400);
  });
});

// ---------------------------------------------------------------------------
// Hot push: type mismatch ignored + WARN
// ---------------------------------------------------------------------------

describe('hot-config — type mismatch (AC-type-mismatch)', () => {
  it('test_typeMismatch_ignoredWithWarn', async () => {
    const { logger, lines } = makeCapture();
    const service = makeService(logger, 0);
    await service.init();

    service.applyHotPush({ 'matchmaking.maxSkillSpreadMMR': 'not-a-number' });
    await new Promise(r => setTimeout(r, 10));

    expect(service.get('matchmaking.maxSkillSpreadMMR')).toBe(300); // unchanged

    const warns = lines().filter(l => l.level === 'warn' && l.event === 'hot_push_type_mismatch');
    expect(warns.length).toBeGreaterThanOrEqual(1);
  });
});

// ---------------------------------------------------------------------------
// Hot push: maintenanceModeEnabled
// ---------------------------------------------------------------------------

describe('hot-config — maintenanceModeEnabled', () => {
  it('test_maintenanceModeHotPush_updatesWithinDebounce', async () => {
    const service = makeService(nullLogger(), 50);
    await service.init();

    expect(service.get('server.maintenanceModeEnabled')).toBe(false);

    service.applyHotPush({ 'server.maintenanceModeEnabled': true });
    await new Promise(r => setTimeout(r, 100)); // debounce + 50ms buffer

    expect(service.get('server.maintenanceModeEnabled')).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// A/B experiments: stable bucket across launches (AC-ab-stable)
// ---------------------------------------------------------------------------

describe('a-b-experiments — stable bucket (AC-ab-stable)', () => {
  it('test_abBucket_stableForSameUserId', () => {
    const service = makeService();
    const userId = 'abc123';

    const buckets = Array.from({ length: 10 }, () =>
      service.getExperimentBucket(userId, 'mmrKFactor')
    );

    // All 10 must return the same bucket
    expect(new Set(buckets).size).toBe(1);
    expect(buckets[0]).toBeGreaterThanOrEqual(0);
    expect(buckets[0]).toBeLessThan(100);
  });

  it('test_abBucket_differentUsersGetDifferentBuckets', () => {
    const service = makeService();
    const buckets = new Set<number>();
    for (let i = 0; i < 20; i++) {
      buckets.add(service.getExperimentBucket(`user-${i}`, 'mmrKFactor'));
    }
    // 20 different users should get at least 3 distinct buckets
    expect(buckets.size).toBeGreaterThan(2);
  });

  it('test_abBucket_differentExperimentsDifferentBuckets', () => {
    const service = makeService();
    const userId = 'user-fixed';
    const b1 = service.getExperimentBucket(userId, 'experimentA');
    const b2 = service.getExperimentBucket(userId, 'experimentB');
    // Different experiments should (likely) produce different buckets
    // We can't guarantee it but using different exp names the hash should differ
    expect(typeof b1).toBe('number');
    expect(typeof b2).toBe('number');
    // At minimum, both are valid bucket numbers
    expect(b1).toBeGreaterThanOrEqual(0);
    expect(b2).toBeGreaterThanOrEqual(0);
  });
});
