import { RemoteConfigService, IConfigHttpAdapter } from '../../../server/src/config/remoteConfig';
import { createLogger } from '../../../server/src/logging/logger';
import { Writable } from 'stream';

function nullLogger() {
  return createLogger({ level: 'fatal', destination: new Writable({ write: (_c, _e, cb) => cb() }) });
}
function nullStorage() {
  return { getItem: async () => null as string | null, setItem: async () => {} };
}

// ---------------------------------------------------------------------------
// AC: 409 sets requiresForceUpdate
// ---------------------------------------------------------------------------

describe('version-compatibility (AC-02)', () => {
  it('test_409_setsRequiresForceUpdate', async () => {
    const http: IConfigHttpAdapter = {
      get: async () => ({ status: 409, body: { code: 'config_incompatible', minVersion: 2 } }),
    };
    const service = new RemoteConfigService({
      configUrl: 'http://localhost/config',
      storage: nullStorage(),
      http,
      logger: nullLogger(),
      forceRefreshOnStart: true,
    });
    await service.init();

    expect(service.requiresForceUpdate).toBe(true);
  });

  it('test_200_doesNotSetForceUpdate', async () => {
    const http: IConfigHttpAdapter = {
      get: async () => ({ status: 200, body: {} }),
    };
    const service = new RemoteConfigService({
      configUrl: 'http://localhost/config',
      storage: nullStorage(),
      http,
      logger: nullLogger(),
      forceRefreshOnStart: true,
    });
    await service.init();

    expect(service.requiresForceUpdate).toBe(false);
  });

  it('test_networkError_doesNotSetForceUpdate', async () => {
    const http: IConfigHttpAdapter = {
      get: async () => { throw new Error('ECONNREFUSED'); },
    };
    const service = new RemoteConfigService({
      configUrl: 'http://localhost/config',
      storage: nullStorage(),
      http,
      logger: nullLogger(),
      forceRefreshOnStart: true,
    });
    await service.init();

    // Network failure ≠ 409 — no force update; use defaults
    expect(service.requiresForceUpdate).toBe(false);
    expect(service.get('matchmaking.maxSkillSpreadMMR')).toBe(300);
  });
});
