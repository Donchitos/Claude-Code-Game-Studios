import { ILogger } from './logger';

/** Constants — all values tunable at construction time for testability. */
export interface TickRateMonitorOptions {
  /** Target tick rate in Hz. Default: 20. */
  targetHz?: number;
  /** Fraction of targetHz below which an alert fires. Default: 0.80 (→ 16 Hz). */
  alertFraction?: number;
  /** Seconds below threshold before alert fires. Default: 30. */
  alertDelaySec?: number;
  /** Seconds above recovery threshold before alert clears. Default: 60. */
  recoveryHysteresisSec?: number;
  /** Hz at or above which recovery is counted. Default: 18. */
  recoveryThresholdHz?: number;
  /** Clock function — injectable for deterministic tests. Default: `Date.now`. */
  now?: () => number;
}

/**
 * Monitors the server game loop tick rate and fires a FATAL log alert when
 * the measured rate falls below the critical threshold for a sustained period.
 *
 * Usage in the game loop:
 * ```ts
 * const monitor = new TickRateMonitor(logger);
 * setInterval(() => {
 *   monitor.recordTick();
 *   monitor.evaluate();
 * }, 50); // 20 Hz
 * ```
 *
 * The monitor is decoupled from `setInterval` to enable deterministic unit
 * testing without fake timers — callers control when `evaluate()` is called.
 */
export class TickRateMonitor {
  private readonly log: ILogger;
  private readonly targetHz: number;
  private readonly criticalThresholdHz: number;
  private readonly alertDelaySec: number;
  private readonly recoveryHysteresisSec: number;
  private readonly recoveryThresholdHz: number;
  private readonly now: () => number;

  /** Tick timestamps recorded in the current measurement window. */
  private tickTimestamps: number[] = [];
  /** Millisecond timestamp when the rate first dropped below threshold. */
  private belowThresholdSince: number | null = null;
  /** Whether a CRITICAL alert is currently active. */
  public isAlertActive = false;
  /** Millisecond timestamp when recovery started (rate rose above recoveryThresholdHz). */
  private recoverySince: number | null = null;

  constructor(logger: ILogger, opts: TickRateMonitorOptions = {}) {
    this.log = logger;
    this.targetHz = opts.targetHz ?? 20;
    const fraction = opts.alertFraction ?? 0.80;
    this.criticalThresholdHz = this.targetHz * fraction;
    this.alertDelaySec = opts.alertDelaySec ?? 30;
    this.recoveryHysteresisSec = opts.recoveryHysteresisSec ?? 60;
    this.recoveryThresholdHz = opts.recoveryThresholdHz ?? 18;
    this.now = opts.now ?? (() => Date.now());
  }

  /**
   * Record that one tick has occurred. Call this at the top of each game tick.
   * Uses the injected clock for testability.
   */
  recordTick(): void {
    const ts = this.now();
    this.tickTimestamps.push(ts);
    // Prune timestamps older than 5 seconds to keep the window bounded
    const cutoff = ts - 5_000;
    while (this.tickTimestamps.length > 0 && this.tickTimestamps[0] < cutoff) {
      this.tickTimestamps.shift();
    }
  }

  /**
   * Evaluate the current tick rate and update alert state.
   * Call this once per second (or at a regular interval shorter than the alert delay).
   */
  evaluate(): void {
    const currentHz = this.getHz();
    const now = this.now();

    if (currentHz < this.criticalThresholdHz) {
      // Rate is below threshold
      if (this.belowThresholdSince === null) {
        this.belowThresholdSince = now;
      }
      // Reset recovery window when rate drops
      this.recoverySince = null;

      const secondsBelow = (now - this.belowThresholdSince) / 1_000;
      if (!this.isAlertActive && secondsBelow >= this.alertDelaySec) {
        this.isAlertActive = true;
        this.log.fatal('Tick rate critical — game loop is below target', {
          alert: 'TICK_RATE_CRITICAL',
          currentHz: Math.round(currentHz * 10) / 10,
          targetHz: this.targetHz,
          thresholdHz: this.criticalThresholdHz,
          secondsBelow: Math.round(secondsBelow),
        });
      }
    } else if (currentHz >= this.recoveryThresholdHz) {
      // Rate is at or above recovery threshold
      this.belowThresholdSince = null;

      if (this.isAlertActive) {
        if (this.recoverySince === null) {
          this.recoverySince = now;
        }
        const secondsRecovering = (now - this.recoverySince) / 1_000;
        if (secondsRecovering >= this.recoveryHysteresisSec) {
          this.isAlertActive = false;
          this.recoverySince = null;
          this.log.info('Tick rate recovered — alert cleared', {
            currentHz: Math.round(currentHz * 10) / 10,
            targetHz: this.targetHz,
          });
        }
      }
    }
  }

  /**
   * Returns the current measured tick rate in Hz based on the rolling 5-second
   * window of recorded ticks.
   */
  getHz(): number {
    if (this.tickTimestamps.length < 2) return 0;
    const windowMs = this.tickTimestamps[this.tickTimestamps.length - 1] - this.tickTimestamps[0];
    if (windowMs === 0) return 0;
    return ((this.tickTimestamps.length - 1) / windowMs) * 1_000;
  }
}
