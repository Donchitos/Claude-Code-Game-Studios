import { randomUUID } from 'crypto';
import {
  AnalyticsEvent,
  REQUIRED_BASE_FIELDS,
  SAMPLED_EVENTS,
  isTier0,
  makeEventId,
} from './analyticsTypes';
import { ILogger } from '../logging/logger';

// ---------------------------------------------------------------------------
// Adapter interfaces (injected — no direct dependency on AsyncStorage / fetch)
// ---------------------------------------------------------------------------

export interface IStorageAdapter {
  getItem(key: string): Promise<string | null>;
  setItem(key: string, value: string): Promise<void>;
}

export interface IHttpAdapter {
  post(url: string, body: unknown): Promise<{ status: number }>;
}

export interface IAnalyticsServiceOptions {
  /** Authenticated player's userId. */
  userId: string;
  /** Socket connection or app session ID. */
  sessionId: string;
  /** Whether the player has granted analytics consent. */
  analyticsConsent: boolean;
  /** 'ios' | 'android' | 'server' */
  platform: string;
  /** Semver app version string. */
  appVersion: string;
  /** Where to POST batched events. */
  flushUrl: string;
  /** Flush when queue reaches this size. Default: 50. */
  batchSize?: number;
  /** Flush interval in ms. Default: 30 000. */
  flushIntervalMs?: number;
  /** Max flush retries on server error. Default: 3. */
  maxRetries?: number;
  /** AsyncStorage adapter. */
  storage: IStorageAdapter;
  /** HTTP adapter. */
  http: IHttpAdapter;
  /** Logger for WARN/ERROR messages. */
  logger: ILogger;
  /** Injectable clock for deterministic tests. Default: Date.now. */
  now?: () => number;
  /** Injectable random for sample rate. Default: Math.random. */
  random?: () => number;
  /** Sample rate for SAMPLED_EVENTS. Default: 1.0 (all). */
  uiEventSampleRate?: number;
}

const STORAGE_KEY = 'analytics_queue';

/**
 * Client-side analytics service.
 *
 * Enqueues events fire-and-forget (`track()` is void and synchronous for the
 * caller), persists the queue to storage for crash recovery, and flushes to
 * the server endpoint in batches.
 *
 * Usage:
 * ```ts
 * const analytics = new AnalyticsService({ userId, ... });
 * await analytics.loadQueue();  // once on app start
 * analytics.track('MATCH_ENDED', { matchId: '...' });
 * ```
 */
export class AnalyticsService {
  private readonly opts: Required<IAnalyticsServiceOptions>;
  private queue: AnalyticsEvent[] = [];
  private retryCount = 0;
  private intervalHandle?: ReturnType<typeof setInterval>;
  private seenEventIds = new Set<string>(); // server-side dedup (in-memory)

  constructor(opts: IAnalyticsServiceOptions) {
    // Use nullish coalescing for optional fields so callers can omit them
    // without accidentally overriding defaults with `undefined` via spread.
    this.opts = {
      ...opts,
      batchSize: opts.batchSize ?? 50,
      flushIntervalMs: opts.flushIntervalMs ?? 30_000,
      maxRetries: opts.maxRetries ?? 3,
      now: opts.now ?? (() => Date.now()),
      random: opts.random ?? (() => Math.random()),
      uiEventSampleRate: opts.uiEventSampleRate ?? 1.0,
    };
  }

  /**
   * Loads any previously persisted queue from storage.
   * Call once on app start / session init.
   */
  async loadQueue(): Promise<void> {
    try {
      const raw = await this.opts.storage.getItem(STORAGE_KEY);
      if (raw) {
        const saved = JSON.parse(raw) as AnalyticsEvent[];
        this.queue = [...saved, ...this.queue];
      }
    } catch {
      // Storage read failure is non-fatal; start with empty queue
    }
  }

  /** Start the interval-based flush timer. Call after `loadQueue()`. */
  startInterval(): void {
    this.intervalHandle = setInterval(
      () => void this.flush(),
      this.opts.flushIntervalMs,
    );
  }

  /** Stop the interval timer. Call on session end. */
  stopInterval(): void {
    if (this.intervalHandle !== undefined) {
      clearInterval(this.intervalHandle);
      this.intervalHandle = undefined;
    }
  }

  /**
   * Record an analytics event. Fire-and-forget — this method is void.
   *
   * Events are validated and filtered (consent, sample rate) before being
   * enqueued. Invalid events are dropped with a WARN log.
   */
  track(eventName: string, properties: Record<string, unknown> = {}): void {
    // Validate required context fields
    const missing = this.getMissingFields(eventName);
    if (missing.length > 0) {
      this.opts.logger.warn(`Analytics event missing required context: ${missing.join(', ')}`, {
        eventName,
        missingFields: missing,
      });
      return;
    }

    // Consent check: Tier 1 events dropped without consent
    if (!this.opts.analyticsConsent && !isTier0(eventName)) {
      return;
    }

    // Sample rate for UI events
    if (SAMPLED_EVENTS.has(eventName) && this.opts.random() > this.opts.uiEventSampleRate) {
      return;
    }

    const event: AnalyticsEvent = {
      eventId: makeEventId(),
      userId: this.opts.userId,
      sessionId: this.opts.sessionId,
      clientTimestamp: this.opts.now(),
      serverTimestamp: this.opts.now(), // overwritten at flush; set here to satisfy schema
      eventName,
      eventVersion: '1',
      platform: this.opts.platform,
      appVersion: this.opts.appVersion,
      properties,
    };

    this.enqueue(event);
  }

  /**
   * Flush all queued events to the server endpoint.
   * Called by the interval timer, on size threshold, and on app background.
   */
  async flush(): Promise<void> {
    if (this.queue.length === 0) return;

    const batch = this.queue.slice();
    const now = this.opts.now();

    // Stamp server timestamp at flush time
    const stamped = batch.map((e) => ({ ...e, serverTimestamp: now }));

    try {
      const res = await this.opts.http.post(this.opts.flushUrl, { events: stamped });
      if (res.status >= 200 && res.status < 300) {
        // Success — remove flushed events from queue
        this.queue = this.queue.filter((e) => !batch.some((b) => b.eventId === e.eventId));
        this.retryCount = 0;
        await this.persistQueue();
      } else if (res.status >= 500) {
        this.retryCount++;
        if (this.retryCount >= this.opts.maxRetries) {
          this.opts.logger.warn('Analytics flush failed after max retries; keeping events in queue', {
            retryCount: this.retryCount,
            queueSize: this.queue.length,
          });
          this.retryCount = 0;
        }
      }
    } catch {
      // Network error — keep events in queue; retry on next flush
    }
  }

  /**
   * Update the consent state. When set to false, all Tier 1 events are
   * purged from the queue and storage.
   */
  async revokeConsent(): Promise<void> {
    this.opts.analyticsConsent = false;
    this.queue = this.queue.filter((e) => isTier0(e.eventName));
    await this.persistQueue();
  }

  /** Current queue length — useful in tests. */
  get queueSize(): number {
    return this.queue.length;
  }

  /**
   * Server-side: process an incoming batch from the client.
   * Detects clock skew, deduplicates by eventId, and logs each event.
   * Returns the processed events (deduplicated).
   */
  processBatch(
    events: AnalyticsEvent[],
    serverNow: number,
    logger: ILogger,
  ): AnalyticsEvent[] {
    const processed: AnalyticsEvent[] = [];
    for (const event of events) {
      if (this.seenEventIds.has(event.eventId)) {
        continue; // duplicate — silently skip
      }
      this.seenEventIds.add(event.eventId);

      // Clock skew detection
      const skewMs = serverNow - event.clientTimestamp;
      const processed_event: AnalyticsEvent = { ...event, serverTimestamp: serverNow };
      if (Math.abs(skewMs) > 60_000) {
        processed_event.clockSkewSec = Math.round(skewMs / 1000);
        logger.warn('Analytics event clock skew detected', {
          eventId: event.eventId,
          clockSkewSec: processed_event.clockSkewSec,
        });
      }

      logger.info('analytics_event', {
        eventId: processed_event.eventId,
        eventName: processed_event.eventName,
        userId: processed_event.userId,
        serverTimestamp: processed_event.serverTimestamp,
        clockSkewSec: processed_event.clockSkewSec,
        properties: processed_event.properties,
      });

      processed.push(processed_event);
    }
    return processed;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  private enqueue(event: AnalyticsEvent): void {
    this.queue.push(event);
    void this.persistQueue();

    if (this.queue.length >= this.opts.batchSize) {
      void this.flush();
    }
  }

  private getMissingFields(eventName: string): string[] {
    const missing: string[] = [];
    // userId and sessionId are the critical context fields to validate at track time
    if (!this.opts.userId) missing.push('userId');
    if (!this.opts.sessionId) missing.push('sessionId');
    if (!eventName) missing.push('eventName');
    return missing;
  }

  private async persistQueue(): Promise<void> {
    try {
      await this.opts.storage.setItem(STORAGE_KEY, JSON.stringify(this.queue));
    } catch {
      // Persistence failure is non-fatal
    }
  }
}
