import { io, Socket } from 'socket.io-client';
import {
  GameMode, GameState, GameEndPayload, MatchFoundPayload,
  PlayerInput, SocketEvents,
} from '@brawlzone/shared';
import Constants from 'expo-constants';

const SERVER_URL =
  (Constants.expoConfig?.extra?.serverUrl as string | undefined) ??
  process.env.EXPO_PUBLIC_SERVER_URL ??
  'http://localhost:3001';

type CB<T> = (payload: T) => void;

class SocketService {
  private socket: Socket | null = null;

  private cbMatchFound:  CB<MatchFoundPayload>[] = [];
  private cbGameState:   CB<GameState>[]          = [];
  private cbGameEnd:     CB<GameEndPayload>[]      = [];
  private cbQueueUpdate: CB<number>[]             = [];

  connect(authToken: string): void {
    if (this.socket?.connected) return;

    this.socket = io(SERVER_URL, {
      auth: { token: authToken },
      transports: ['websocket'],
      reconnection: true,
      reconnectionAttempts: 10,
      reconnectionDelay: 1000,
    });

    this.socket.on('connect',       () => console.log('[socket] connected'));
    this.socket.on('disconnect',    () => console.log('[socket] disconnected'));
    this.socket.on('connect_error', (e) => console.warn('[socket] error', e.message));

    this.socket.on(SocketEvents.MATCH_FOUND, (p: MatchFoundPayload) =>
      this.cbMatchFound.forEach(cb => cb(p)));
    this.socket.on(SocketEvents.GAME_STATE, (s: GameState) =>
      this.cbGameState.forEach(cb => cb(s)));
    this.socket.on(SocketEvents.GAME_END, (p: GameEndPayload) =>
      this.cbGameEnd.forEach(cb => cb(p)));
    this.socket.on(SocketEvents.QUEUE_UPDATE, (data: { position: number }) =>
      this.cbQueueUpdate.forEach(cb => cb(data.position)));
  }

  disconnect(): void {
    this.socket?.disconnect();
    this.socket = null;
  }

  joinQueue(mode: GameMode, characterId: string, rating: number): void {
    this.socket?.emit(SocketEvents.JOIN_QUEUE, { mode, characterId, rating });
  }

  leaveQueue(mode: GameMode): void {
    this.socket?.emit(SocketEvents.LEAVE_QUEUE, { mode });
  }

  sendInput(input: PlayerInput): void {
    this.socket?.emit(SocketEvents.PLAYER_INPUT, input);
  }

  onMatchFound(cb: CB<MatchFoundPayload>): () => void {
    this.cbMatchFound.push(cb);
    return () => { this.cbMatchFound = this.cbMatchFound.filter(c => c !== cb); };
  }

  onGameState(cb: CB<GameState>): () => void {
    this.cbGameState.push(cb);
    return () => { this.cbGameState = this.cbGameState.filter(c => c !== cb); };
  }

  onGameEnd(cb: CB<GameEndPayload>): () => void {
    this.cbGameEnd.push(cb);
    return () => { this.cbGameEnd = this.cbGameEnd.filter(c => c !== cb); };
  }

  onQueueUpdate(cb: CB<number>): () => void {
    this.cbQueueUpdate.push(cb);
    return () => { this.cbQueueUpdate = this.cbQueueUpdate.filter(c => c !== cb); };
  }

  get isConnected(): boolean {
    return this.socket?.connected ?? false;
  }
}

export const socketService = new SocketService();
