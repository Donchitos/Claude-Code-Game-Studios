import { ILogger, LoggerOptions, createLogger } from './logger';

export interface BufferedTransportOptions {
  /** Max lines held in the buffer before oldest entries are dropped. Default: 1000. */
  maxBufferSize?: number;
  /** Injectable clock for deterministic tests. Default: `Date.now`. */
  now?: () => number;
}

interface BufferedLine {
  level: string;
  msg: string;
  meta?: Record<string, unknown>;
  ts: number;
}

/**
 * A log transport wrapper that buffers log lines when the downstream target is
 * unavailable, then flushes them in FIFO order on recovery.
 *
 * MVP usage: the underlying `ILogger` writes to stdout (Railway captures it).
 * `BufferedTransport` wraps it to allow graceful degradation if the downstream
 * aggregator (Datadog, Logtail, etc.) is temporarily unreachable — lines are
 * held in memory and flushed once the target is healthy again.
 *
 * When the buffer reaches `maxBufferSize`, the oldest entry is dropped to make
 * room for the new one (ring-buffer semantics).
 *
 * Usage:
 * ```ts
 * const base = createLogger();
 * const transport = new BufferedTransport(base);
 * transport.setDown(true);   // aggregator unreachable
 * transport.info('msg');     // buffered
 * transport.setDown(false);  // aggregator recovered
 * await transport.flush();   // all buffered lines replayed to base logger
 * ```
 */
export class BufferedTransport implements ILogger {
  private readonly inner: ILogger;
  private readonly maxBufferSize: number;
  private readonly now: () => number;

  private down = false;
  private readonly buffer: BufferedLine[] = [];

  constructor(inner: ILogger, opts: BufferedTransportOptions = {}) {
    this.inner = inner;
    this.maxBufferSize = opts.maxBufferSize ?? 1_000;
    this.now = opts.now ?? (() => Date.now());
  }

  /** Mark the transport as down (buffer writes) or up (pass through). */
  setDown(isDown: boolean): void {
    this.down = isDown;
  }

  /** Number of lines currently buffered. */
  get bufferSize(): number {
    return this.buffer.length;
  }

  /**
   * Flush all buffered lines to the underlying logger in FIFO order.
   * Clears the buffer after flushing.
   */
  flush(): void {
    const toFlush = this.buffer.splice(0, this.buffer.length);
    for (const line of toFlush) {
      const fn = this.inner[line.level as keyof ILogger] as
        | ((msg: string, meta?: Record<string, unknown>) => void)
        | undefined;
      if (typeof fn === 'function') {
        fn.call(this.inner, line.msg, line.meta);
      }
    }
  }

  private enqueue(level: string, msg: string, meta?: Record<string, unknown>): void {
    if (this.buffer.length >= this.maxBufferSize) {
      this.buffer.shift(); // drop oldest
    }
    this.buffer.push({ level, msg, meta, ts: this.now() });
  }

  private emit(level: string, msg: string, meta?: Record<string, unknown>): void {
    if (this.down) {
      this.enqueue(level, msg, meta);
    } else {
      const fn = this.inner[level as keyof ILogger] as
        | ((msg: string, meta?: Record<string, unknown>) => void)
        | undefined;
      if (typeof fn === 'function') {
        fn.call(this.inner, msg, meta);
      }
    }
  }

  debug(msg: string, meta?: Record<string, unknown>): void { this.emit('debug', msg, meta); }
  info(msg: string, meta?: Record<string, unknown>): void { this.emit('info', msg, meta); }
  warn(msg: string, meta?: Record<string, unknown>): void { this.emit('warn', msg, meta); }
  error(msg: string, meta?: Record<string, unknown>): void { this.emit('error', msg, meta); }
  fatal(msg: string, meta?: Record<string, unknown>): void { this.emit('fatal', msg, meta); }

  withCorrelation(correlationId: string): ILogger {
    return new BufferedTransport(
      this.inner.withCorrelation(correlationId),
      { maxBufferSize: this.maxBufferSize, now: this.now },
    );
  }
}

/**
 * Factory for the project's logger.
 *
 * Swap the underlying implementation here (pino → winston, or add a remote
 * sink) without touching any call site. All call sites depend on `ILogger`,
 * not on the concrete implementation returned here.
 */
export function createProjectLogger(opts: LoggerOptions = {}): ILogger {
  return createLogger(opts);
}
