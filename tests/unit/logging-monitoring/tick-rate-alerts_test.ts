import { Writable } from 'stream';
import { createLogger } from '../../../server/src/logging/logger';
import { TickRateMonitor } from '../../../server/src/logging/tickRateMonitor';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeCapture(): { stream: Writable; lines: () => string[] } {
  const chunks: string[] = [];
  const stream = new Writable({
    write(chunk: Buffer | string, _enc: BufferEncoding, cb: () => void) {
      chunks.push(chunk.toString());
      cb();
    },
  });
  return {
    stream,
    lines: () =>
      chunks.join('').split('\n').filter((l) => l.trim().length > 0),
  };
}

function parsedLines(lines: string[]): Record<string, unknown>[] {
  return lines.map((l) => JSON.parse(l));
}

/**
 * Simulates N ticks at a given Hz using a controlled clock.
 * Returns the final timestamp.
 */
function simulateTicks(
  monitor: TickRateMonitor,
  hz: number,
  durationSec: number,
  startMs: number,
): number {
  const intervalMs = 1_000 / hz;
  const totalTicks = Math.floor(hz * durationSec);
  let ts = startMs;
  for (let i = 0; i < totalTicks; i++) {
    ts += intervalMs;
    monitor.recordTick();
  }
  return ts;
}

// ---------------------------------------------------------------------------
// AC-initial-state: Monitor starts non-alerting
// ---------------------------------------------------------------------------

describe('TickRateMonitor — initial state (AC-initial-state)', () => {
  it('test_initialState_notAlerting', () => {
    const { stream } = makeCapture();
    const log = createLogger({ level: 'fatal', destination: stream });
    const monitor = new TickRateMonitor(log);

    expect(monitor.isAlertActive).toBe(false);
  });

  it('test_getHz_returnsZeroWithNoTicks', () => {
    const log = createLogger({ level: 'fatal', destination: new Writable({ write: (_c, _e, cb) => cb() }) });
    const monitor = new TickRateMonitor(log);
    expect(monitor.getHz()).toBe(0);
  });

  it('test_noFatalEmittedBeforeThresholdBreach', () => {
    const { stream, lines } = makeCapture();
    const log = createLogger({ level: 'fatal', destination: stream });
    let t = 0;
    const monitor = new TickRateMonitor(log, { now: () => t });

    // Simulate 20 Hz for 20 seconds — well-behaved loop, no alert
    for (let sec = 0; sec < 20; sec++) {
      for (let tick = 0; tick < 20; tick++) {
        t += 50;
        monitor.recordTick();
      }
      monitor.evaluate();
    }

    const parsed = parsedLines(lines());
    const fatals = parsed.filter((p) => p.level === 'fatal');
    expect(fatals).toHaveLength(0);
    expect(monitor.isAlertActive).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// AC-05: CRITICAL alert fires after 30s below threshold
// ---------------------------------------------------------------------------

describe('TickRateMonitor — critical alert (AC-05)', () => {
  it('test_criticalAlert_firesAfterAlertDelay', () => {
    const { stream, lines } = makeCapture();
    const log = createLogger({ level: 'fatal', destination: stream });
    let t = 0;
    const monitor = new TickRateMonitor(log, {
      alertDelaySec: 30,
      alertFraction: 0.80, // threshold = 16 Hz
      now: () => t,
    });

    // Simulate 14 Hz (below 16 Hz threshold) for 31 seconds
    for (let sec = 0; sec < 31; sec++) {
      // 14 ticks per second
      for (let tick = 0; tick < 14; tick++) {
        t += 1_000 / 14;
        monitor.recordTick();
      }
      t = Math.ceil(t); // round to avoid float drift
      monitor.evaluate();
    }

    expect(monitor.isAlertActive).toBe(true);

    const parsed = parsedLines(lines());
    const fatals = parsed.filter((p) => p.level === 'fatal');
    expect(fatals.length).toBeGreaterThanOrEqual(1);
    expect(fatals[0].alert).toBe('TICK_RATE_CRITICAL');
    expect(fatals[0].targetHz).toBe(20);
  });

  it('test_criticalAlert_doesNotFireBeforeAlertDelay', () => {
    const { stream, lines } = makeCapture();
    const log = createLogger({ level: 'fatal', destination: stream });
    let t = 0;
    const monitor = new TickRateMonitor(log, {
      alertDelaySec: 30,
      alertFraction: 0.80,
      now: () => t,
    });

    // Only 29 seconds at 14 Hz — should NOT fire
    for (let sec = 0; sec < 29; sec++) {
      for (let tick = 0; tick < 14; tick++) {
        t += 1_000 / 14;
        monitor.recordTick();
      }
      t = Math.ceil(t);
      monitor.evaluate();
    }

    expect(monitor.isAlertActive).toBe(false);
    const parsed = parsedLines(lines());
    const fatals = parsed.filter((p) => p.level === 'fatal');
    expect(fatals).toHaveLength(0);
  });

  it('test_criticalAlert_firesOnlyOnce', () => {
    const { stream, lines } = makeCapture();
    const log = createLogger({ level: 'fatal', destination: stream });
    let t = 0;
    const monitor = new TickRateMonitor(log, {
      alertDelaySec: 30,
      alertFraction: 0.80,
      now: () => t,
    });

    // 60 seconds at 14 Hz — alert should fire once, not repeatedly
    for (let sec = 0; sec < 60; sec++) {
      for (let tick = 0; tick < 14; tick++) {
        t += 1_000 / 14;
        monitor.recordTick();
      }
      t = Math.ceil(t);
      monitor.evaluate();
    }

    const parsed = parsedLines(lines());
    const fatals = parsed.filter((p) => p.level === 'fatal');
    expect(fatals).toHaveLength(1);
  });
});

// ---------------------------------------------------------------------------
// AC-06: Hysteresis prevents premature alert clearance
// ---------------------------------------------------------------------------

describe('TickRateMonitor — hysteresis (AC-06)', () => {
  it('test_hysteresis_doesNotClearAlertBefore60s', () => {
    const { stream, lines } = makeCapture();
    const log = createLogger({ level: 'debug', destination: stream });
    let t = 0;
    const monitor = new TickRateMonitor(log, {
      alertDelaySec: 30,
      alertFraction: 0.80,
      recoveryHysteresisSec: 60,
      recoveryThresholdHz: 18,
      now: () => t,
    });

    // Phase 1: trigger alert — 31s at 14 Hz
    for (let sec = 0; sec < 31; sec++) {
      for (let tick = 0; tick < 14; tick++) { t += 1_000 / 14; monitor.recordTick(); }
      t = Math.ceil(t);
      monitor.evaluate();
    }
    expect(monitor.isAlertActive).toBe(true);

    // Phase 2: recover to 20 Hz but only for 59 seconds — alert must NOT clear
    for (let sec = 0; sec < 59; sec++) {
      for (let tick = 0; tick < 20; tick++) { t += 50; monitor.recordTick(); }
      monitor.evaluate();
    }
    expect(monitor.isAlertActive).toBe(true);
  });

  it('test_hysteresis_clearsAlertAfter60sRecovery', () => {
    const { stream } = makeCapture();
    const log = createLogger({ level: 'debug', destination: stream });
    let t = 0;
    const monitor = new TickRateMonitor(log, {
      alertDelaySec: 30,
      alertFraction: 0.80,
      recoveryHysteresisSec: 60,
      recoveryThresholdHz: 18,
      now: () => t,
    });

    // Phase 1: trigger alert
    for (let sec = 0; sec < 31; sec++) {
      for (let tick = 0; tick < 14; tick++) { t += 1_000 / 14; monitor.recordTick(); }
      t = Math.ceil(t);
      monitor.evaluate();
    }
    expect(monitor.isAlertActive).toBe(true);

    // Phase 2: recover to 20 Hz for 67 seconds — alert MUST clear.
    // The 5-second rolling window retains old 14 Hz ticks for ~5s after the
    // switch; effective recovery only starts once the window flushes (~5s).
    // 60s hysteresis + 5s flush + 2s buffer = 67s.
    for (let sec = 0; sec < 67; sec++) {
      for (let tick = 0; tick < 20; tick++) { t += 50; monitor.recordTick(); }
      monitor.evaluate();
    }
    expect(monitor.isAlertActive).toBe(false);
  });
});
