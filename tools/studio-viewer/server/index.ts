import { readFileSync } from "node:fs";
import { readFile } from "node:fs/promises";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createServer as createViteServer } from "vite";
import { WebSocketServer } from "ws";
import type { StudioConfig } from "../shared/protocol.ts";
import { loadRoster } from "./agent-roster.ts";
import { ClaudeSession, isValidModelName, resolveClaudeCommand } from "./claude-session.ts";
import { SessionStore } from "./session-store.ts";
import { StreamLog } from "./stream-log.ts";
import { StudioHub } from "./studio-hub.ts";

const SOCKET_PATH = "/studio-socket";
const HOST = "127.0.0.1";
const HISTORY_LIMIT = 3000;

const toolRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const projectRoot = path.resolve(process.env["CCGS_ROOT"] ?? path.join(toolRoot, "..", ".."));
const port = Number(process.env["STUDIO_PORT"] ?? 5317);
const stateDirectory = path.resolve(process.env["STUDIO_STATE_DIR"] ?? path.join(toolRoot, ".studio"));

function isAllowedOrigin(origin: string | undefined): boolean {
  return origin === `http://${HOST}:${port}` || origin === `http://localhost:${port}`;
}

function readModelOverride(): string | null {
  const model = process.env["STUDIO_MODEL"];
  return isValidModelName(model) ? model : null;
}

function createConfigReader(initial: StudioConfig): () => StudioConfig {
  let lastGood = initial;
  return () => {
    try {
      lastGood = JSON.parse(readFileSync(path.join(toolRoot, "studio-config.json"), "utf8")) as StudioConfig;
    } catch (error) {
      console.warn("studio-config.json could not be read; keeping the previous version.", error);
    }
    return lastGood;
  };
}

async function main(): Promise<void> {
  const config = JSON.parse(await readFile(path.join(toolRoot, "studio-config.json"), "utf8")) as StudioConfig;
  const roster = await loadRoster(projectRoot, config);
  const hub = new StudioHub({
    session: new ClaudeSession(resolveClaudeCommand()),
    store: new SessionStore(path.join(stateDirectory, "session.json"), HISTORY_LIMIT, "auto"),
    roster,
    readConfig: createConfigReader(config),
    projectRoot,
    modelOverride: readModelOverride(),
    streamLog: new StreamLog(path.join(stateDirectory, "stream.log")),
  });

  const vite = await createViteServer({
    configFile: path.join(toolRoot, "vite.config.ts"),
    server: { middlewareMode: true },
    appType: "spa",
  });
  const server = http.createServer((request, response) => vite.middlewares(request, response));
  const sockets = new WebSocketServer({ noServer: true, maxPayload: 1_000_000 });

  server.on("upgrade", (request, socket, head) => {
    if (request.url !== SOCKET_PATH) return;
    if (!isAllowedOrigin(request.headers.origin)) {
      socket.destroy();
      return;
    }
    sockets.handleUpgrade(request, socket, head, (client) => hub.attach(client));
  });

  server.listen(port, HOST, () => {
    console.log(`CCGS Studio: http://localhost:${port}`);
    console.log(`Project root: ${projectRoot}`);
    console.log(`Agents on roster: ${roster.length}`);
  });

  const shutdown = () => {
    hub.shutdown();
    void vite.close();
    server.close();
    setTimeout(() => process.exit(0), 300);
  };
  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
