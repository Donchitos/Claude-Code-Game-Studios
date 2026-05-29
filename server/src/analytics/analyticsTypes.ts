import { randomUUID } from 'crypto';

/** All 10 required base fields every analytics event must carry. */
export interface AnalyticsEvent {
  eventId: string;          // UUID v4 — unique per event
  userId: string;           // Supabase userId
  sessionId: string;        // session identifier (socket connection ID or app session UUID)
  clientTimestamp: number;  // ms since epoch, client clock
  serverTimestamp: number;  // ms since epoch, server clock — set at flush time
  eventName: string;        // e.g. 'MATCH_ENDED'
  eventVersion: string;     // schema version, e.g. '1'
  platform: string;         // 'ios' | 'android' | 'server'
  appVersion: string;       // semver string from package.json
  properties: Record<string, unknown>;
  clockSkewSec?: number;    // set server-side if |server - client| > 60s
}

/** Required field names for client-side validation. */
export const REQUIRED_BASE_FIELDS: ReadonlyArray<keyof AnalyticsEvent> = [
  'eventId',
  'userId',
  'sessionId',
  'clientTimestamp',
  'serverTimestamp',
  'eventName',
  'eventVersion',
  'platform',
  'appVersion',
  'properties',
];

/**
 * Tier 0 events — always collected regardless of analyticsConsent.
 * These are game-critical, non-PII events needed for operational telemetry.
 */
export const TIER_0_EVENTS: ReadonlySet<string> = new Set([
  'MATCH_STARTED',
  'MATCH_ENDED',
  'MATCH_ABANDONED',
  'PLAYER_CONNECTED',
  'PLAYER_DISCONNECTED',
  'SERVER_STARTED',
  'TICK_OVERRUN',
  'QUEUE_JOINED',
  'QUEUE_CANCELLED',
  'MATCH_FOUND',
]);

/**
 * Events that are sampled at a configurable rate (default 1.0 = all).
 * Set to a fraction to reduce volume for high-frequency UI events.
 */
export const SAMPLED_EVENTS: ReadonlySet<string> = new Set([
  'UI_SCREEN_VIEWED',
  'UI_BUTTON_TAPPED',
  'UI_TAB_CHANGED',
]);

/** Returns true if the event is Tier 0 (always collected). */
export function isTier0(eventName: string): boolean {
  return TIER_0_EVENTS.has(eventName);
}

/** Creates the base fields for a new event; caller fills in properties. */
export function makeEventId(): string {
  return randomUUID();
}
