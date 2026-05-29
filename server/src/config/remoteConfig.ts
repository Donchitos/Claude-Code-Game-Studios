import { CONFIG_REGISTRY, ConfigKey, ConfigValue, ConfigValueType, getDefault } from './configRegistry';
import { ILogger } from '../logging/logger';

export const CLIENT_SCHEMA_VERSION = 1;
const STORAGE_KEY = 'remote_config';

// ---------------------------------------------------------------------------
// Adapter interfaces
// ---------------------------------------------------------------------------

export interface IConfigStorageAdapter {
  getItem(key: string): Promise<string | null>;
  setItem(key: string, value: string): Promise<void>;
}

export interface IConfigHttpAdapter {
  get(url: string, headers?: Record<string, string>): Promise<{ status: number; body: unknown }>;
}

// ---------------------------------------------------------------------------
// Cached payload shape
// ---------------------------------------------------------------------------

interface CachedConfig {
  schema_version: number;
  values: Partial<Record<ConfigKey, unknown>>;
  experiments?: Record<string, ExperimentAssignment>;
}

interface ExperimentAssignment {
  bucket: number; // 0–99
  variant: string;
}

// ---------------------------------------------------------------------------
// RemoteConfigService
// ---------------------------------------------------------------------------

export interface RemoteConfigOptions {
  configUrl: string;
  storage: IConfigStorageAdapter;
  http: IConfigHttpAdapter;
  logger: ILogger;
  /** Debounce window for hot push updates in ms. Default: 100. */
  hotPushDebounceMs?: number;
  /** Whether to block init until a fresh fetch completes. Default: false. */
  forceRefreshOnStart?: boolean;
  /** Injectable clock. Default: Date.now. */
  now?: () => number;
}

/**
 * Remote Config service.
 *
 * Holds a typed in-memory config map populated from:
 * 1. Hardcoded defaults (always present — zero network required)
 * 2. Cached AsyncStorage values (applied over defaults on init)
 * 3. Fresh server fetch (applied over cache)
 *
 * `get(key)` is synchronous O(1) — safe to call in hot paths.
 */
export class RemoteConfigService {
  private readonly opts: Required<RemoteConfigOptions>;
  private active: Map<ConfigKey, unknown>;
  private incompatible = false;
  private debounceTimer?: ReturnType<typeof setTimeout>;
  private pendingHotUpdates: Partial<Record<ConfigKey, unknown>> = {};

  constructor(opts: RemoteConfigOptions) {
    this.opts = {
      hotPushDebounceMs: opts.hotPushDebounceMs ?? 100,
      forceRefreshOnStart: opts.forceRefreshOnStart ?? false,
      now: opts.now ?? (() => Date.now()),
      ...opts,
    };
    // Start with hardcoded defaults
    this.active = this.buildDefaultMap();
  }

  /**
   * Initialise the config service.
   * Loads cache from storage, then optionally fetches a fresh copy.
   * Must be awaited before the main menu renders.
   */
  async init(): Promise<void> {
    await this.loadFromStorage();

    if (this.opts.forceRefreshOnStart) {
      await this.fetchAndApply();
    } else {
      void this.fetchAndApply(); // background refresh
    }
  }

  /**
   * Synchronous O(1) read. Returns the active value for `key`, or the
   * hardcoded default if no override is loaded. Never returns null/undefined.
   */
  get<K extends ConfigKey>(key: K): ConfigValue<K> {
    const val = this.active.get(key);
    if (val === undefined || val === null) return getDefault(key);
    return val as ConfigValue<K>;
  }

  /** True if the server returned `config_incompatible` (force-update required). */
  get requiresForceUpdate(): boolean {
    return this.incompatible;
  }

  /**
   * Handle a `config_update` socket event (hot push).
   * Only Hot-tier keys are applied; Cold-tier keys are ignored with a WARN.
   * Type-mismatched values are also ignored with a WARN.
   * Debounced to `hotPushDebounceMs` to batch rapid pushes.
   */
  applyHotPush(updates: Partial<Record<string, unknown>>): void {
    for (const [rawKey, value] of Object.entries(updates)) {
      const key = rawKey as ConfigKey;
      const entry = CONFIG_REGISTRY[key];

      if (!entry) {
        this.opts.logger.warn('Hot push: unknown config key ignored', { key: rawKey });
        continue;
      }

      if (entry.tier === 'Cold') {
        this.opts.logger.warn('Hot push: Cold key ignored', { event: 'hot_push_cold_key_ignored', key: rawKey });
        continue;
      }

      if (!this.typeMatches(value, entry.type)) {
        this.opts.logger.warn('Hot push: type mismatch ignored', { event: 'hot_push_type_mismatch', key: rawKey, expectedType: entry.type, actualType: typeof value });
        continue;
      }

      this.pendingHotUpdates[key] = value;
    }

    // Debounce application
    if (this.debounceTimer) clearTimeout(this.debounceTimer);
    this.debounceTimer = setTimeout(() => {
      for (const [k, v] of Object.entries(this.pendingHotUpdates)) {
        this.active.set(k as ConfigKey, v);
      }
      this.pendingHotUpdates = {};
      this.debounceTimer = undefined;
    }, this.opts.hotPushDebounceMs);
  }

  /**
   * Compute a stable A/B experiment bucket for a userId.
   * Uses a simple hash so the same userId always gets the same bucket (0–99).
   * The assignment does not change within a session or across restarts.
   */
  getExperimentBucket(userId: string, experimentName: string): number {
    return this.fnv1aHash(`${userId}:${experimentName}`) % 100;
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  private buildDefaultMap(): Map<ConfigKey, unknown> {
    const m = new Map<ConfigKey, unknown>();
    for (const [k, entry] of Object.entries(CONFIG_REGISTRY) as [ConfigKey, { default: unknown }][]) {
      m.set(k, entry.default);
    }
    return m;
  }

  private async loadFromStorage(): Promise<void> {
    try {
      const raw = await this.opts.storage.getItem(STORAGE_KEY);
      if (!raw) return;
      const cached: CachedConfig = JSON.parse(raw);

      if (cached.schema_version < CLIENT_SCHEMA_VERSION) {
        this.opts.logger.warn('Remote config cache discarded: schema version too old', {
          cached: cached.schema_version,
          current: CLIENT_SCHEMA_VERSION,
        });
        return;
      }

      this.applyValues(cached.values);
    } catch {
      // Corrupt cache — silently start from defaults
    }
  }

  private async fetchAndApply(): Promise<void> {
    try {
      const res = await this.opts.http.get(this.opts.configUrl, {
        'X-Config-Schema-Version': String(CLIENT_SCHEMA_VERSION),
      });

      if (res.status === 409) {
        this.incompatible = true;
        this.opts.logger.warn('Remote config: server requires force update', { status: 409 });
        return;
      }

      if (res.status < 200 || res.status >= 300) return;

      const payload = res.body as Partial<Record<ConfigKey, unknown>> & { schema_version?: number };
      this.applyValues(payload);

      const toCache: CachedConfig = {
        schema_version: payload.schema_version ?? CLIENT_SCHEMA_VERSION,
        values: payload,
      };
      await this.opts.storage.setItem(STORAGE_KEY, JSON.stringify(toCache));
    } catch {
      // Network failure — keep current values (defaults or cache)
    }
  }

  private applyValues(values: Partial<Record<string, unknown>>): void {
    for (const [rawKey, value] of Object.entries(values)) {
      const key = rawKey as ConfigKey;
      if (!CONFIG_REGISTRY[key]) continue;
      if (value === null || value === undefined) continue;
      this.active.set(key, value);
    }
  }

  private typeMatches(value: unknown, expectedType: ConfigValueType): boolean {
    if (expectedType === 'string[]') return Array.isArray(value);
    return typeof value === expectedType;
  }

  /** FNV-1a hash — stable, deterministic, no external deps. */
  private fnv1aHash(input: string): number {
    let hash = 2166136261;
    for (let i = 0; i < input.length; i++) {
      hash ^= input.charCodeAt(i);
      hash = (hash * 16777619) >>> 0;
    }
    return hash;
  }
}
