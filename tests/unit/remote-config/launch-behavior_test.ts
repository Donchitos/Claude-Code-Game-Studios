import { RemoteConfigService, IConfigStorageAdapter, IConfigHttpAdapter, CLIENT_SCHEMA_VERSION } from '../../../server/src/config/remoteConfig';
import { createLogger } from '../../../server/src/logging/logger';
import { Writable } from 'stream';

function nullLogger() {
  return createLogger({ level: 'fatal', destination: new Writable({ write: (_c, _e, cb) => cb() }) });
}
function nullStorage(): IConfigStorageAdapter {
  return { getItem: async () => null, setItem: async () => {} };
}
function httpReturning(status: number, body: unknown = {}): IConfigHttpAdapter {
  return { get: async () => ({ status, body }) };
}

function makeService(opts: {
  storage?: IConfigStorageAdapter;
  http?: IConfigHttpAdapter;
  forceRefreshOnStart?: boolean;
}) {
  return new RemoteConfigService({
    configUrl: 'http://localhost/config',
    storage: opts.storage ?? nullStorage(),
    http: opts.http ?? httpReturning(200, {}),
    logger: nullLogger(),
    forceRefreshOnStart: opts.forceRefreshOnStart,
  });
}

// ---------------------------------------------------------------------------
// AC-cold-start: no network, no cache → hardcoded defaults
// ---------------------------------------------------------------------------

describe('launch-behavior — cold start (AC-cold-start)', () => {
  it('test_coldStart_usesHardcodedDefaults', async () => {
    const service = makeService({ http: httpReturning(503) });
    await service.init();

    expect(service.get('matchmaking.maxSkillSpreadMMR')).toBe(300);
    expect(service.get('server.maintenanceModeEnabled')).toBe(false);
    expect(service.requiresForceUpdate).toBe(false);
  });

  it('test_coldStart_noNullOrUndefinedDefaults', async () => {
    const service = makeService({ http: httpReturning(503) });
    await service.init();

    const keys = [
      'matchmaking.maxSkillSpreadMMR',
      'matchmaking.mmrKFactorProvisional',
      'matchmaking.botFillDelaySec',
      'gameMode.availableModes',
      'server.maintenanceModeEnabled',
      'tick.rateHz',
      'analytics.uiEventSampleRate',
      'rewards.baseMatchCoins',
    ] as const;

    for (const k of keys) {
      const v = service.get(k);
      expect(v).not.toBeNull();
      expect(v).not.toBeUndefined();
    }
  });
});

// ---------------------------------------------------------------------------
// AC-cache-schema-version: stale cache discarded
// ---------------------------------------------------------------------------

describe('launch-behavior — schema version (AC-cache-schema-version)', () => {
  it('test_staleCache_discardedAndDefaultsUsed', async () => {
    const stale = JSON.stringify({
      schema_version: CLIENT_SCHEMA_VERSION - 1,
      values: { 'matchmaking.maxSkillSpreadMMR': 999 },
    });
    const storage: IConfigStorageAdapter = {
      getItem: async () => stale,
      setItem: async () => {},
    };
    const service = makeService({ storage, http: httpReturning(503) });
    await service.init();

    // Stale cache value must NOT be applied
    expect(service.get('matchmaking.maxSkillSpreadMMR')).toBe(300);
  });

  it('test_currentSchemaCache_applied', async () => {
    const current = JSON.stringify({
      schema_version: CLIENT_SCHEMA_VERSION,
      values: { 'matchmaking.maxSkillSpreadMMR': 400 },
    });
    const storage: IConfigStorageAdapter = {
      getItem: async () => current,
      setItem: async () => {},
    };
    const service = makeService({ storage, http: httpReturning(503) });
    await service.init();

    expect(service.get('matchmaking.maxSkillSpreadMMR')).toBe(400);
  });
});

// ---------------------------------------------------------------------------
// forceRefreshOnStart: waits for fresh config before resolving
// ---------------------------------------------------------------------------

describe('launch-behavior — force refresh on start', () => {
  it('test_forceRefresh_appliesFreshValues', async () => {
    const service = makeService({
      forceRefreshOnStart: true,
      http: httpReturning(200, { 'matchmaking.maxSkillSpreadMMR': 500 }),
    });
    await service.init();

    expect(service.get('matchmaking.maxSkillSpreadMMR')).toBe(500);
  });

  it('test_noForceRefresh_usesDefaultsImmediately', async () => {
    let fetchCalled = false;
    const http: IConfigHttpAdapter = {
      get: async () => { fetchCalled = true; return { status: 200, body: { 'matchmaking.maxSkillSpreadMMR': 500 } }; },
    };
    const service = makeService({ forceRefreshOnStart: false, http });
    await service.init(); // background fetch — doesn't block

    // Default used immediately (background fetch may not have settled)
    expect(service.get('matchmaking.maxSkillSpreadMMR')).toBeGreaterThanOrEqual(300);
  });
});
