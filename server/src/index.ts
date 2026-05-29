import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import { config } from './config';
import { registerSocketHandlers } from './socket';

const app = express();
app.use(express.json());

app.get('/health', (_req, res) => res.json({ status: 'ok', ts: Date.now() }));

const httpServer = createServer(app);

const io = new Server(httpServer, {
  cors: {
    origin: config.clientOrigin,
    methods: ['GET', 'POST'],
  },
  pingTimeout: 10_000,
  pingInterval: 5_000,
});

registerSocketHandlers(io);

httpServer.listen(config.port, () => {
  console.log(`[brawlzone] server on :${config.port}  env=${process.env.NODE_ENV ?? 'development'}`);
});
