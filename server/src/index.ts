import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import { createClient } from '@supabase/supabase-js';
import * as path from 'path';
import { config } from './config';
import { registerSocketHandlers } from './socket';
import { createLogger } from './logging/logger';
import { ContentCatalogService, defaultCatalogPath, IContentCatalog } from './catalog/contentCatalog';
import { PlayerProfileService, ISocketServer, IDbAdapter, IRedisAdapter } from './profile/playerProfileService';
import { createApiRouter } from './routes';

// ---------------------------------------------------------------------------
// Logger
// ---------------------------------------------------------------------------

const logger = createLogger();

// ---------------------------------------------------------------------------
// Supabase client (shared)
// ---------------------------------------------------------------------------

const supabase = createClient(config.supabase.url, config.supabase.serviceKey);

// ---------------------------------------------------------------------------
// Content catalog — load at startup; degrade gracefully on failure
// ---------------------------------------------------------------------------

let catalog: IContentCatalog | null = null;
try {
  catalog = ContentCatalogService.init(defaultCatalogPath(), logger);
} catch (err) {
  logger.warn('CATALOG_LOAD_FAILED', { err: String(err), note: 'catalog endpoints will return 503' });
}

// ---------------------------------------------------------------------------
// IDbAdapter — thin wrapper over Supabase postgres client
// ---------------------------------------------------------------------------

const dbAdapter: IDbAdapter = {
  async query<T = unknown>(sql: string, params?: unknown[]): Promise<T[]> {
    const { data, error } = await supabase.rpc('raw_query', { sql, params: params ?? [] });
    if (error) throw new Error(`DB_QUERY_FAILED: ${error.message}`);
    return (data ?? []) as T[];
  },
  async execute(sql: string, params?: unknown[]): Promise<{ rowCount: number }> {
    const { data, error } = await supabase.rpc('raw_execute', { sql, params: params ?? [] });
    if (error) throw new Error(`DB_EXECUTE_FAILED: ${error.message}`);
    return { rowCount: typeof data === 'number' ? data : 0 };
  },
};

// ---------------------------------------------------------------------------
// IRedisAdapter — stub (Redis wired later; no-ops keep the game functional)
// ---------------------------------------------------------------------------

const redisAdapter: IRedisAdapter = {
  async get(_key: string): Promise<string | null> { return null; },
  async set(_key: string, _value: string, _ttl?: number): Promise<void> { /* no-op */ },
  async del(_key: string): Promise<void> { /* no-op */ },
};

// ---------------------------------------------------------------------------
// ISocketServer thin adapter — wired inline once io is created
// ---------------------------------------------------------------------------

/** Deferred adapter: io is assigned after the Server instance is created. */
class DeferredSocketAdapter implements ISocketServer {
  private io: Server | null = null;

  /** Called once the Socket.io Server instance exists. */
  attach(io: Server): void {
    this.io = io;
  }

  emitToUser(userId: string, event: string, data: unknown): void {
    if (!this.io) return;
    this.io.to(`user:${userId}`).emit(event, data);
  }
}

const socketAdapter = new DeferredSocketAdapter();

// ---------------------------------------------------------------------------
// PlayerProfileService
// ---------------------------------------------------------------------------

const profileService = new PlayerProfileService(
  dbAdapter,
  redisAdapter,
  socketAdapter,
  logger,
);

// ---------------------------------------------------------------------------
// Express + HTTP server
// ---------------------------------------------------------------------------

const app = express();
app.use(express.json());

// Health check — no auth required
app.get('/health', (_req, res) => res.json({ status: 'ok', ts: Date.now() }));

// Mount versioned API routes
app.use('/v1', createApiRouter({
  supabase,
  profileService,
  catalog,
  logger,
}));

const httpServer = createServer(app);

// ---------------------------------------------------------------------------
// Socket.io server
// ---------------------------------------------------------------------------

const io = new Server(httpServer, {
  cors: {
    origin: config.clientOrigin,
    methods: ['GET', 'POST'],
  },
  pingTimeout: 10_000,
  pingInterval: 5_000,
});

// Attach the io instance to the deferred adapter so profile pushes work
socketAdapter.attach(io);

registerSocketHandlers(io);

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------

httpServer.listen(config.port, () => {
  logger.info('SERVER_STARTED', {
    port: config.port,
    env: process.env['NODE_ENV'] ?? 'development',
    catalogLoaded: catalog !== null,
  });
});
