import { Server, Socket } from 'socket.io';
import { createClient } from '@supabase/supabase-js';
import { v4 as uuidv4 } from 'uuid';
import { GameMode, MATCH_CONFIGS, Player, PlayerInput, SocketEvents } from '../shared';
import { config } from '../config';
import { MatchmakingQueue } from '../matchmaking/MatchmakingQueue';
import { GameRoomManager } from '../game/GameRoomManager';

const supabase    = createClient(config.supabase.url, config.supabase.serviceKey);
const matchmaking = new MatchmakingQueue();
const roomManager = new GameRoomManager();

// Bot-Fill-Timer: pro Modus ein laufender Timeout
const botFillTimers = new Map<GameMode, ReturnType<typeof setTimeout>>();

/** Erstellt Bot-Spieler um eine Lobby auf die benoettigte Groesse aufzufuellen. */
function fillWithBots(io: Server, mode: GameMode): void {
  const queue   = matchmaking.drain(mode);          // alle wartenden Spieler holen
  if (!queue.length) return;                         // niemand mehr in der Queue

  const needed  = MATCH_CONFIGS[mode].maxPlayers;
  const lobby   = [...queue];

  while (lobby.length < needed) {
    const botId  = `bot-${uuidv4()}`;
    lobby.push({
      id:          botId,
      userId:      botId,
      username:    `BOT_${lobby.length}`,
      characterId: 'warrior',
      rating:      1000,
    });
  }

  const room = roomManager.createRoom(mode, lobby);

  // Nur echte Spieler benachrichtigen
  for (const p of lobby) {
    if (p.id.startsWith('bot-')) continue;
    const s = io.sockets.sockets.get(p.id);
    if (!s) continue;
    s.join(room.id);
    s.emit(SocketEvents.MATCH_FOUND, {
      roomId:      room.id,
      mode,
      players:     lobby,
      countdownMs: config.tick.countdownMs,
    });
  }
  room.startCountdown(io, config.tick.countdownMs);

  if (config.isDev) console.log(`[bot-fill] ${mode}: ${queue.length} Spieler + ${needed - queue.length} Bots -> Room ${room.id}`);
}

/** Startet oder verlaengert den Bot-Fill-Timer fuer einen Modus. */
function scheduleBotFill(io: Server, mode: GameMode): void {
  const existing = botFillTimers.get(mode);
  if (existing) clearTimeout(existing);

  const t = setTimeout(() => {
    botFillTimers.delete(mode);
    fillWithBots(io, mode);
  }, config.tick.botFillDelayMs);

  botFillTimers.set(mode, t);
}

export function registerSocketHandlers(io: Server): void {
  // Globaler Tick
  setInterval(() => roomManager.tick(io), config.tick.rateMs);

  // Auth-Middleware
  io.use(async (socket, next) => {
    const token = socket.handshake.auth.token as string | undefined;
    if (!token) return next(new Error('auth_required'));

    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data.user) return next(new Error('auth_invalid'));

    socket.data.userId   = data.user.id;
    socket.data.username =
      (data.user.user_metadata?.username as string | undefined) ??
      data.user.email ?? 'unknown';
    next();
  });

  io.on('connection', (socket: Socket) => {
    const { userId, username } = socket.data as { userId: string; username: string };
    if (config.isDev) console.log(`[+] ${username} (${userId})`);

    socket.on(SocketEvents.JOIN_QUEUE, (payload: {
      mode: GameMode;
      characterId: string;
      rating?: number;
    }) => {
      const { mode, characterId, rating = 1000 } = payload;
      const player: Player = { id: socket.id, userId, username, characterId, rating };

      matchmaking.enqueue(mode, player);
      socket.emit(SocketEvents.QUEUE_UPDATE, {
        position: matchmaking.getPosition(mode, socket.id),
      });

      // Versuche sofortiges Match (wenn genuegend echte Spieler da sind)
      const lobby = matchmaking.tryMatch(mode);
      if (lobby) {
        // Laufenden Bot-Timer fuer diesen Modus abbrechen
        const t = botFillTimers.get(mode);
        if (t) { clearTimeout(t); botFillTimers.delete(mode); }

        const room = roomManager.createRoom(mode, lobby);
        for (const p of lobby) {
          const s = io.sockets.sockets.get(p.id);
          if (!s) continue;
          s.join(room.id);
          s.emit(SocketEvents.MATCH_FOUND, {
            roomId:      room.id,
            mode,
            players:     lobby,
            countdownMs: config.tick.countdownMs,
          });
        }
        room.startCountdown(io, config.tick.countdownMs);
      } else {
        // Nicht genuegend echte Spieler -> Bot-Fill-Timer starten
        scheduleBotFill(io, mode);
      }
    });

    socket.on(SocketEvents.LEAVE_QUEUE, ({ mode }: { mode: GameMode }) => {
      matchmaking.dequeue(mode, socket.id);
    });

    socket.on(SocketEvents.PLAYER_INPUT, (input: PlayerInput) => {
      roomManager.applyInput(socket.id, input);
    });

    socket.on('disconnect', () => {
      if (config.isDev) console.log(`[-] ${username} (${userId})`);
      matchmaking.dequeueAll(socket.id);
      roomManager.handleDisconnect(socket.id, io);
    });
  });
}
