/** Config key tiers: Hot = updatable via socket push; Cold = requires app restart. */
export type ConfigTier = 'Hot' | 'Cold';
export type ConfigValueType = 'number' | 'boolean' | 'string' | 'string[]';

export interface ConfigKeyEntry<T = unknown> {
  default: T;
  type: ConfigValueType;
  tier: ConfigTier;
  description: string;
}

/**
 * Canonical registry of all remote config keys.
 *
 * RULES:
 * - Every key used in `configService.get(key)` MUST appear here.
 * - Every key MUST have a non-null, non-undefined default.
 * - Hot keys can be patched via `config_update` socket event without restart.
 * - Cold keys require a full app/server restart to take effect.
 */
export const CONFIG_REGISTRY = {
  // Matchmaking
  'matchmaking.maxSkillSpreadMMR':      { default: 300,    type: 'number',   tier: 'Hot',  description: 'Max MMR delta between players in a match bracket' },
  'matchmaking.mmrKFactorProvisional':  { default: 32,     type: 'number',   tier: 'Hot',  description: 'Elo K-factor for provisional players (<30 matches)' },
  'matchmaking.mmrKFactorEstablished':  { default: 16,     type: 'number',   tier: 'Hot',  description: 'Elo K-factor for established players (≥30 matches)' },
  'matchmaking.botFillDelaySec':        { default: 45,     type: 'number',   tier: 'Hot',  description: 'Seconds to wait before backfilling bots' },
  'matchmaking.mmrWidenPerSec':         { default: 50,     type: 'number',   tier: 'Hot',  description: 'MMR bracket widens by this value every 15s of wait' },

  // Game modes
  'gameMode.availableModes':            { default: ['duel_1v1', 'squad_3v3', 'ffa_8'], type: 'string[]', tier: 'Hot', description: 'Active queue-able game modes' },
  'gameMode.matchDurationCapSec':       { default: 600,    type: 'number',   tier: 'Hot',  description: 'Hard cap on match duration across all modes' },

  // Server
  'server.maintenanceModeEnabled':      { default: false,  type: 'boolean',  tier: 'Hot',  description: 'When true: show maintenance banner; disable queue entry points' },
  'server.maxConcurrentMatches':        { default: 100,    type: 'number',   tier: 'Cold', description: 'Max simultaneous active GameRoom instances' },

  // Tick / networking (Cold — changes require server restart)
  'tick.rateHz':                        { default: 20,     type: 'number',   tier: 'Cold', description: 'Server game loop frequency' },
  'tick.reconnectGracePeriodSec':       { default: 30,     type: 'number',   tier: 'Cold', description: 'Seconds a disconnected player slot is held before bot takeover' },
  'tick.alertThresholdFraction':        { default: 0.80,   type: 'number',   tier: 'Cold', description: 'Fraction of target Hz below which a CRITICAL alert fires' },

  // Analytics
  'analytics.uiEventSampleRate':        { default: 1.0,    type: 'number',   tier: 'Hot',  description: 'Sampling fraction for high-volume UI events (0.0–1.0)' },
  'analytics.flushIntervalMs':          { default: 30000,  type: 'number',   tier: 'Hot',  description: 'How often to flush the analytics event queue to the server' },

  // Rewards
  'rewards.baseMatchCoins':             { default: 20,     type: 'number',   tier: 'Hot',  description: 'Baseline coins awarded per completed match' },
  'rewards.winBonusCoins':              { default: 30,     type: 'number',   tier: 'Hot',  description: 'Additional coins for a match win' },
  'rewards.adRewardCoins':              { default: 25,     type: 'number',   tier: 'Hot',  description: 'Coins granted for watching a rewarded ad' },
} as const satisfies Record<string, ConfigKeyEntry>;

export type ConfigKey = keyof typeof CONFIG_REGISTRY;
export type ConfigValue<K extends ConfigKey> = (typeof CONFIG_REGISTRY)[K]['default'];

/** Returns the hardcoded default for a key (never null, never undefined). */
export function getDefault<K extends ConfigKey>(key: K): ConfigValue<K> {
  return CONFIG_REGISTRY[key].default as ConfigValue<K>;
}
