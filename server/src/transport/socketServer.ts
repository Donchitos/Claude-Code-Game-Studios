import { Server as SocketIoServer, Socket } from 'socket.io';
import { IJwtValidator, JwtValidator } from '../auth/jwtValidator';
import { ILogger } from '../logging/logger';

export type GameMode = 'duel_1v1' | 'squad_3v3' | 'ffa_8';

export interface AuthenticatedSocket extends Socket {
  data: {
    userId: string;
    correlationId?: string;
  };
}

export interface ITransportCallbacks {
  onPlayerConnect(socket: AuthenticatedSocket): void;
  onPlayerDisconnect(socket: AuthenticatedSocket): void;
  onPlayerInput(socket: AuthenticatedSocket, event: string, data: unknown): void;
}

/**
 * Bootstraps Socket.io with JWT authentication middleware.
 * Unauthenticated sockets are disconnected after 5 seconds.
 */
export function bootstrapSocketServer(
  io: SocketIoServer,
  validator: IJwtValidator,
  logger: ILogger,
  callbacks?: Partial<ITransportCallbacks>,
): void {
  // JWT auth middleware
  io.use(async (socket, next) => {
    const token = (socket.handshake.auth as Record<string, string>).token;
    if (!token) {
      socket.emit('auth_error', { reason: 'TOKEN_MISSING' });
      socket.disconnect(true);
      return next(new Error('TOKEN_MISSING'));
    }

    const result = await validator.validateToken(token);
    if (JwtValidator.isError(result)) {
      socket.emit('auth_error', { reason: result.error });
      socket.disconnect(true);
      return next(new Error(result.error));
    }

    (socket.data as AuthenticatedSocket['data']).userId = result.userId;
    next();
  });

  io.on('connection', (socket) => {
    const s = socket as AuthenticatedSocket;

    // 5-second disconnect if socket doesn't emit authenticate (belt-and-suspenders)
    const authTimeout = setTimeout(() => {
      if (!s.data.userId) {
        s.emit('auth_error', { reason: 'TOKEN_MISSING' });
        s.disconnect(true);
      }
    }, 5000);

    // User room for profile:refresh pushes
    s.join(`user:${s.data.userId}`);

    s.on('disconnect', () => {
      clearTimeout(authTimeout);
      callbacks?.onPlayerDisconnect?.(s);
    });

    ['BASIC_ATTACK', 'USE_ABILITY', 'queue_join', 'queue_cancel', 'character_confirmed'].forEach((evt) => {
      s.on(evt, (data: unknown) => callbacks?.onPlayerInput?.(s, evt, data));
    });

    clearTimeout(authTimeout);
    callbacks?.onPlayerConnect?.(s);

    logger.info('socket_connected', { userId: s.data.userId });
  });
}
