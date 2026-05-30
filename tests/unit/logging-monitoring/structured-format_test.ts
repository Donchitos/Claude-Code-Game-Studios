import { Writable } from 'stream';
import { createLogger } from '../../../server/src/logging/logger';

/** Captures pino's newline-delimited JSON output into parseable lines. */
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
      chunks
        .join('')
        .split('\n')
        .filter((l) => l.trim().length > 0),
  };
}

describe('structured-format — ILogger', () => {
  // AC-01: valid JSON with timestamp, level (string), service, message
  it('test_structuredFormat_containsRequiredFields', () => {
    const { stream, lines } = makeCapture();
    const log = createLogger({ level: 'info', destination: stream });

    log.info('Server started');

    const emitted = lines();
    expect(emitted).toHaveLength(1);

    let parsed: Record<string, unknown>;
    expect(() => { parsed = JSON.parse(emitted[0]); }).not.toThrow();

    // AC-01 field contract
    expect(parsed!).toHaveProperty('timestamp');
    expect(typeof parsed!.timestamp).toBe('string');
    // ISO 8601 rough check
    expect(String(parsed!.timestamp)).toMatch(/^\d{4}-\d{2}-\d{2}T/);

    expect(parsed!).toHaveProperty('level', 'info');   // string, not integer
    expect(parsed!).toHaveProperty('service', 'brawlzone-server');
    expect(parsed!).toHaveProperty('message', 'Server started');
  });

  // AC-02: debug suppressed when level = 'info'
  it('test_debugSuppressedInProduction', () => {
    const { stream, lines } = makeCapture();
    const log = createLogger({ level: 'info', destination: stream });

    log.debug('Debug detail');

    expect(lines()).toHaveLength(0);
  });

  // AC-02 complement: debug emitted when level permits
  it('test_debugEmittedWhenLevelIsDebug', () => {
    const { stream, lines } = makeCapture();
    const log = createLogger({ level: 'debug', destination: stream });

    log.debug('Debug detail');

    const emitted = lines();
    expect(emitted).toHaveLength(1);
    expect(JSON.parse(emitted[0])).toHaveProperty('level', 'debug');
  });

  // AC-all-levels: all five callable without error; fatal produces JSON
  it('test_allLevelsCallableWithoutError', () => {
    const { stream, lines } = makeCapture();
    // trace is below debug — use debug as floor so all five required levels pass
    const log = createLogger({ level: 'debug', destination: stream });

    expect(() => log.debug('d')).not.toThrow();
    expect(() => log.info('i')).not.toThrow();
    expect(() => log.warn('w')).not.toThrow();
    expect(() => log.error('e')).not.toThrow();
    expect(() => log.fatal('f')).not.toThrow();

    const emitted = lines();
    // All five levels emitted (pino does NOT call process.exit on fatal by default)
    expect(emitted).toHaveLength(5);

    // fatal specifically produces valid JSON
    const fatalLine = emitted.find((l) => {
      try { return JSON.parse(l).message === 'f'; } catch { return false; }
    });
    expect(fatalLine).toBeDefined();
    expect(JSON.parse(fatalLine!)).toHaveProperty('level', 'fatal');
  });

  // withCorrelation: binds correlationId to every child log line
  it('test_withCorrelation_bindsCorrelationId', () => {
    const { stream, lines } = makeCapture();
    const log = createLogger({ level: 'debug', destination: stream });
    const correlated = log.withCorrelation('req-abc-123');

    correlated.info('first');
    correlated.warn('second');

    const emitted = lines();
    expect(emitted).toHaveLength(2);
    for (const line of emitted) {
      expect(JSON.parse(line)).toHaveProperty('correlationId', 'req-abc-123');
    }
  });

  // withCorrelation: parent logger is not mutated
  it('test_withCorrelation_doesNotAffectParent', () => {
    const { stream, lines } = makeCapture();
    const log = createLogger({ level: 'debug', destination: stream });
    log.withCorrelation('child-only');

    log.info('parent log');

    const emitted = lines();
    expect(emitted).toHaveLength(1);
    expect(JSON.parse(emitted[0])).not.toHaveProperty('correlationId');
  });
});
