import { GameMode, MATCH_CONFIGS, Player } from '../shared';

export class MatchmakingQueue {
  private queues = new Map<GameMode, Player[]>();

  constructor() {
    for (const mode of Object.values(GameMode)) {
      this.queues.set(mode, []);
    }
  }

  enqueue(mode: GameMode, player: Player): void {
    const queue = this.queues.get(mode)!;
    if (!queue.find(p => p.id === player.id)) {
      queue.push(player);
    }
  }

  dequeue(mode: GameMode, socketId: string): void {
    const queue = this.queues.get(mode)!;
    const idx   = queue.findIndex(p => p.id === socketId);
    if (idx !== -1) queue.splice(idx, 1);
  }

  dequeueAll(socketId: string): void {
    for (const mode of Object.values(GameMode)) {
      this.dequeue(mode, socketId);
    }
  }

  getPosition(mode: GameMode, socketId: string): number {
    return this.queues.get(mode)!.findIndex(p => p.id === socketId) + 1;
  }

  /** Gibt eine vollstaendige Lobby zurueck oder null wenn nicht genug Spieler. */
  tryMatch(mode: GameMode): Player[] | null {
    const queue  = this.queues.get(mode)!;
    const needed = MATCH_CONFIGS[mode].maxPlayers;
    if (queue.length < needed) return null;
    return queue.splice(0, needed);
  }

  /**
   * Entfernt ALLE wartenden Spieler eines Modus und gibt sie zurueck.
   * Wird vom Bot-Fill-Timer aufgerufen um unvollstaendige Lobbys zu starten.
   */
  drain(mode: GameMode): Player[] {
    const queue = this.queues.get(mode)!;
    return queue.splice(0, queue.length);
  }
}
