import { RemoteConfigService } from '../../../server/src/config/remoteConfig';
import { CONFIG_REGISTRY, ConfigKey } from '../../../server/src/config/configRegistry';
import { createLogger } from '../../../server/src/logging/logger';
import { Writable } from 'stream';

function nullLogger() {
  return createLogger({ level: 'fatal', destination: new Writable({ write: (_c, _e, cb) => cb() }) });
}
function makeService() {
  return new RemoteConfigService({
    configUrl: 'http://localhost/config',
    storage: { getItem: async () => null, setItem: async () => {} },
    http: { get: async () => ({ status: 503, body: {} }) },
    logger: nullLogger(),
    forceRefreshOnStart: true,
  });
}

// ---------------------------------------------------------------------------
// AC-defaults: all keys have non-null defaults
// ---------------------------------------------------------------------------

describe('isolation — all keys have defaults (AC-defaults)', () => {
  it('test_allRegistryKeys_haveNonNullDefaults', async () => {
    const service = makeService();
    await service.init();

    for (const key of Object.keys(CONFIG_REGISTRY) as ConfigKey[]) {
      const val = service.get(key);
      expect(val).not.toBeNull();
      expect(val).not.toBeUndefined();
    }
  });

  it('test_totalRegistryKeys_greaterThanTen', () => {
    // Ensure the registry is populated (not empty)
    expect(Object.keys(CONFIG_REGISTRY).length).toBeGreaterThan(10);
  });
});

// ---------------------------------------------------------------------------
// AC-performance: get() completes in under 1ms
// ---------------------------------------------------------------------------

describe('isolation — performance (AC-performance)', () => {
  it('test_get_completesUnder1MsPerCall', async () => {
    const service = makeService();
    await service.init();

    const ITERATIONS = 10_000;
    const start = performance.now();
    for (let i = 0; i < ITERATIONS; i++) {
      service.get('matchmaking.maxSkillSpreadMMR');
    }
    const elapsed = performance.now() - start;

    // 10,000 calls must complete in < 10,000ms (≤ 1ms each)
    expect(elapsed).toBeLessThan(ITERATIONS);
  });

  it('test_get_synchronous_noAwait', async () => {
    const service = makeService();
    await service.init();

    // get() must return synchronously (not a Promise)
    const result = service.get('matchmaking.maxSkillSpreadMMR');
    expect(typeof (result as unknown as Promise<unknown>)?.then).not.toBe('function');
    expect(result).toBe(300);
  });
});

// ---------------------------------------------------------------------------
// Registry integrity checks
// ---------------------------------------------------------------------------

describe('isolation — registry integrity', () => {
  it('test_allRegistryEntries_haveCorrectStructure', () => {
    for (const [key, entry] of Object.entries(CONFIG_REGISTRY)) {
      expect(entry.default).not.toBeUndefined();
      expect(entry.default).not.toBeNull();
      expect(['Hot', 'Cold']).toContain(entry.tier);
      expect(['number', 'boolean', 'string', 'string[]']).toContain(entry.type);
      expect(entry.description.length).toBeGreaterThan(0);
    }
  });

  it('test_defaultValues_matchDeclaredTypes', () => {
    for (const [key, entry] of Object.entries(CONFIG_REGISTRY)) {
      if (entry.type === 'string[]') {
        expect(Array.isArray(entry.default)).toBe(true);
      } else {
        expect(typeof entry.default).toBe(entry.type);
      }
    }
  });
});
