import { Server } from 'socket.io';
import {
  GameMode, GameState, Player, PlayerInput, PlayerState,
  SocketEvents, MATCH_CONFIGS,
} from '../shared';
import { generateBotInput } from './BotAI';

const ARENA_W      = 1000;
const ARENA_H      = 1000;
const PLAYER_SPEED = 5;    // units per tick at full input
const BASE_HEALTH  = 100;

export class GameRoom {
  readonly id: string;
  readonly mode: GameMode;

  private state: GameState;
  private inputs        = new Map<string, PlayerInput>(); // socketId -> latest input
  private socketToPlayer= new Map<string, string>();      // socketId -> userId
  private botSocketIds  = new Set<string>();              // bots brauchen keinen echten Socket

  constructor(id: string, mode: GameMode, players: Player[]) {
    this.id   = id;
    this.mode = mode;

    const playerStates: Record<string, PlayerState> = {};
    players.forEach((p, i) => {
      this.socketToPlayer.set(p.id, p.userId);
      playerStates[p.userId] = {
        id:        p.userId,
        x:         (ARENA_W / (players.length + 1)) * (i + 1),
        y:         ARENA_H / 2,
        health:    BASE_HEALTH,
        maxHealth: BASE_HEALTH,
        score:     0,
        alive:     true,
        lastInput: null,
      };
      if (p.id.startsWith('bot-')) this.botSocketIds.add(p.id);
    });

    this.state = {
      roomId:    id,
      mode,
      players:   playerStates,
      status:    'waiting',
      startedAt: null,
      endsAt:    null,
      tick:      0,
    };
  }

  startCountdown(io: Server, countdownMs: number): void {
    this.state.status = 'countdown';
    setTimeout(() => this.start(io), countdownMs);
  }

  private start(io: Server): void {
    const now = Date.now();
    this.state.status    = 'active';
    this.state.startedAt = now;
    this.state.endsAt    = now + MATCH_CONFIGS[this.mode].maxDuration * 1000;
    io.to(this.id).emit(SocketEvents.GAME_START, { startsAt: now });
  }

  applyInput(socketId: string, input: PlayerInput): void {
    this.inputs.set(socketId, input);
  }

  tick(io: Server): void {
    if (this.state.status !== 'active') return;

    if (this.state.endsAt && Date.now() >= this.state.endsAt) {
      this.finish(io);
      return;
    }

    // Bot-Inputs generieren (vor den echten Spieler-Inputs)
    for (const botSocketId of this.botSocketIds) {
      const botUserId = this.socketToPlayer.get(botSocketId);
      if (!botUserId) continue;
      const botState = this.state.players[botUserId];
      if (!botState?.alive) continue;
      this.inputs.set(botSocketId, generateBotInput(botState, this.state.players));
    }

    // Alle Inputs (echte Spieler + Bots) verarbeiten
    for (const [socketId, input] of this.inputs) {
      const playerId = this.socketToPlayer.get(socketId);
      if (!playerId) continue;
      const ps = this.state.players[playerId];
      if (!ps?.alive) continue;

      ps.x = Math.max(0, Math.min(ARENA_W, ps.x + input.dx * PLAYER_SPEED));
      ps.y = Math.max(0, Math.min(ARENA_H, ps.y + input.dy * PLAYER_SPEED));
      ps.lastInput = input;

      // Einfaches Kampf-System: Angriff trifft alle Gegner im Nahbereich
      if (input.action === 'attack') {
        for (const [otherId, other] of Object.entries(this.state.players)) {
          if (otherId === playerId || !other.alive) continue;
          const dist = Math.hypot(other.x - ps.x, other.y - ps.y);
          if (dist < 80) {
            other.health = Math.max(0, other.health - 10);
            if (other.health === 0) {
              other.alive = false;
              ps.score   += 1;
            }
          }
        }
      }
    }

    this.state.tick++;
    io.to(this.id).emit(SocketEvents.GAME_STATE, this.state);

    // Pruefe ob nur noch 1 oder 0 Spieler leben (FFA / Duel)
    const aliveHumans = Object.values(this.state.players).filter(
      p => p.alive && !this.isBot(p.id),
    );
    if (aliveHumans.length <= 1 && this.state.tick > 20) {
      this.finish(io);
    }
  }

  handleDisconnect(socketId: string, io: Server): void {
    const playerId = this.socketToPlayer.get(socketId);
    if (playerId && this.state.players[playerId]) {
      this.state.players[playerId].alive = false;
    }
    this.inputs.delete(socketId);

    const aliveHumans = Object.values(this.state.players)
      .filter(p => p.alive && !this.isBot(p.id));
    if (aliveHumans.length <= 1 && this.state.status === 'active') {
      this.finish(io);
    }
  }

  private isBot(userId: string): boolean {
    return userId.startsWith('bot-');
  }

  private finish(io: Server): void {
    this.state.status = 'finished';
    const scores  = Object.fromEntries(
      Object.entries(this.state.players).map(([id, p]) => [id, p.score]),
    );
    const sorted  = Object.entries(scores).sort((a, b) => b[1] - a[1]);
    const winner  = sorted[0]?.[0] ?? null;
    const isHumanWinner = winner && !this.isBot(winner);

    io.to(this.id).emit(SocketEvents.GAME_END, {
      roomId:          this.id,
      winner,
      scores,
      rewardsDiamonds: isHumanWinner ? 15 : 5,
      xpGained:        isHumanWinner ? 300 : 100,
    });
  }

  get isFinished(): boolean {
    return this.state.status === 'finished';
  }
}
