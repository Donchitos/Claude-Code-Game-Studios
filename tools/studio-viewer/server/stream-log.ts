import { createWriteStream, existsSync, mkdirSync, renameSync, statSync, type WriteStream } from "node:fs";
import path from "node:path";

const DEFAULT_LIMIT_BYTES = 5 * 1024 * 1024;

export class StreamLog {
  private stream: WriteStream | null = null;
  private writtenBytes = 0;

  constructor(
    private readonly filePath: string,
    private readonly limitBytes = DEFAULT_LIMIT_BYTES,
  ) {}

  write(source: "stdout" | "stderr" | "stdin", line: string): void {
    const entry = `${new Date().toISOString()} ${source} ${line}\n`;
    if (!this.stream) this.open();
    if (this.writtenBytes + entry.length > this.limitBytes) this.rotate();
    this.stream?.write(entry);
    this.writtenBytes += Buffer.byteLength(entry);
  }

  close(): void {
    this.stream?.end();
    this.stream = null;
  }

  private open(): void {
    mkdirSync(path.dirname(this.filePath), { recursive: true });
    this.writtenBytes = existsSync(this.filePath) ? statSync(this.filePath).size : 0;
    this.stream = createWriteStream(this.filePath, { flags: "a" });
  }

  private rotate(): void {
    this.close();
    renameSync(this.filePath, `${this.filePath}.1`);
    this.open();
  }
}
