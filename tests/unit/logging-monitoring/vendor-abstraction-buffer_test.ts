import { Writable } from 'stream';
import { createLogger, ILogger } from '../../../server/src/logging/logger';
import { BufferedTransport } from '../../../server/src/logging/bufferedTransport';

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

// ---------------------------------------------------------------------------
// AC-11: Buffer during outage, flush on recovery
// ---------------------------------------------------------------------------

describe('BufferedTransport — buffer and recovery (AC-11)', () => {
  it('test_buffersWhileDown_flushesOnRecovery', () => {
    const { stream, lines } = makeCapture();
    const base = createLogger({ level: 'debug', destination: stream });
    const transport = new BufferedTransport(base);

    transport.setDown(true);
    for (let i = 0; i < 100; i++) {
      transport.info(`line ${i}`);
    }

    // Nothing written yet
    expect(lines()).toHaveLength(0);
    expect(transport.bufferSize).toBe(100);

    // Recovery
    transport.setDown(false);
    transport.flush();

    const emitted = lines();
    expect(emitted).toHaveLength(100);

    // Verify FIFO order
    const parsed = parsedLines(emitted);
    for (let i = 0; i < 100; i++) {
      expect(parsed[i].message).toBe(`line ${i}`);
    }
  });

  it('test_bufferClearedAfterFlush', () => {
    const { stream } = makeCapture();
    const base = createLogger({ level: 'debug', destination: stream });
    const transport = new BufferedTransport(base);

    transport.setDown(true);
    transport.info('msg1');
    transport.info('msg2');
    transport.setDown(false);
    transport.flush();

    expect(transport.bufferSize).toBe(0);
  });

  it('test_passesThrough_whenUp', () => {
    const { stream, lines } = makeCapture();
    const base = createLogger({ level: 'debug', destination: stream });
    const transport = new BufferedTransport(base);

    transport.info('direct line');

    expect(lines()).toHaveLength(1);
    expect(transport.bufferSize).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// AC-overflow: Buffer overflow drops oldest
// ---------------------------------------------------------------------------

describe('BufferedTransport — overflow (AC-overflow)', () => {
  it('test_overflow_dropsOldestEntry', () => {
    const { stream, lines } = makeCapture();
    const base = createLogger({ level: 'debug', destination: stream });
    const transport = new BufferedTransport(base, { maxBufferSize: 5 });

    transport.setDown(true);
    for (let i = 0; i < 5; i++) {
      transport.info(`entry ${i}`);
    }
    expect(transport.bufferSize).toBe(5);

    // Add one more — oldest should drop
    transport.info('entry 5 — newest');
    expect(transport.bufferSize).toBe(5); // still at max

    transport.setDown(false);
    transport.flush();

    const emitted = parsedLines(lines());
    expect(emitted).toHaveLength(5);
    // entry 0 was dropped; entries 1–5 remain in order
    expect(emitted[0].message).toBe('entry 1');
    expect(emitted[4].message).toBe('entry 5 — newest');
  });

  it('test_overflow_bufferNeverExceedsMax', () => {
    const base = createLogger({ level: 'debug', destination: new Writable({ write: (_c, _e, cb) => cb() }) });
    const transport = new BufferedTransport(base, { maxBufferSize: 10 });

    transport.setDown(true);
    for (let i = 0; i < 100; i++) {
      transport.info(`msg ${i}`);
    }

    expect(transport.bufferSize).toBe(10);
  });
});

// ---------------------------------------------------------------------------
// AC-12: ILogger abstraction — vendor swap transparency
// ---------------------------------------------------------------------------

describe('ILogger vendor abstraction (AC-12)', () => {
  it('test_callerUsesILogger_notConcreteType', () => {
    // This test verifies that the ILogger interface is sufficient to write all
    // log levels. Any conforming implementation (pino, winston, mock) can be
    // substituted — the call site only needs ILogger.
    const received: Array<{ level: string; msg: string }> = [];

    const mockLogger: ILogger = {
      debug: (msg) => received.push({ level: 'debug', msg }),
      info: (msg) => received.push({ level: 'info', msg }),
      warn: (msg) => received.push({ level: 'warn', msg }),
      error: (msg) => received.push({ level: 'error', msg }),
      fatal: (msg) => received.push({ level: 'fatal', msg }),
      withCorrelation: () => mockLogger,
    };

    // Simulate a game system that only depends on ILogger
    function gameSystem(log: ILogger): void {
      log.info('match started');
      log.debug('tick 1');
      log.warn('slow tick');
      log.error('player state invalid', { errorCode: 'BAD_STATE' });
    }

    gameSystem(mockLogger);

    expect(received).toHaveLength(4);
    expect(received[0]).toEqual({ level: 'info', msg: 'match started' });
    // Mock implementation has no pino dependency — swap is transparent
    expect(typeof mockLogger.info).toBe('function');
  });

  it('test_bufferedTransport_implementsILogger', () => {
    const base = createLogger({ level: 'debug', destination: new Writable({ write: (_c, _e, cb) => cb() }) });
    const transport: ILogger = new BufferedTransport(base);

    // BufferedTransport satisfies ILogger — TypeScript enforces this at compile time
    expect(typeof transport.debug).toBe('function');
    expect(typeof transport.info).toBe('function');
    expect(typeof transport.warn).toBe('function');
    expect(typeof transport.error).toBe('function');
    expect(typeof transport.fatal).toBe('function');
    expect(typeof transport.withCorrelation).toBe('function');
  });
});
