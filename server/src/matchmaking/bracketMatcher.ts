export interface QueueEntry {
  userId: string;
  mmr: number;
  queuedAtMs: number;
  isBot?: boolean;
}

export interface MatchFormation {
  players: QueueEntry[];
  matchId: string;
}

export interface BracketMatcherOptions {
  maxSkillSpreadMMR?: number; // default 300
  mmrWidenPerSec?: number;    // default 50 — MMR spread widens this much per 15s
  botFillDelaySec?: number;   // default 45
  now?: () => number;
  generateMatchId?: () => string;
}

/**
 * In-memory bracket matching algorithm.
 *
 * Per ADR-0009:
 * - Maintains a queue per game mode
 * - Polls every ~2s for viable brackets
 * - Widens MMR spread by 50 every 15s of wait
 * - Backfills with bots after 45s if bracket cannot be filled
 */
export class BracketMatcher {
  private readonly maxSpread: number;
  private readonly mmrWidenPerSec: number;
  private readonly botFillDelaySec: number;
  private readonly now: () => number;
  private readonly generateMatchId: () => string;

  constructor(opts: BracketMatcherOptions = {}) {
    this.maxSpread = opts.maxSkillSpreadMMR ?? 300;
    this.mmrWidenPerSec = opts.mmrWidenPerSec ?? 50;
    this.botFillDelaySec = opts.botFillDelaySec ?? 45;
    this.now = opts.now ?? (() => Date.now());
    this.generateMatchId = opts.generateMatchId ?? (() => Math.random().toString(36).slice(2));
  }

  /**
   * Attempts to form a match from the queue.
   * Returns a MatchFormation if successful, null if not enough players.
   *
   * Algorithm:
   * 1. Find the player who has waited longest
   * 2. Compute their effective spread (base + wait escalation)
   * 3. Find players within that spread
   * 4. If enough players: form the match
   * 5. If 45s elapsed and partial bracket: backfill with bots
   */
  tryMatch(queue: QueueEntry[], requiredPlayers: number): MatchFormation | null {
    if (queue.length === 0) return null;

    const now = this.now();

    // Sort by queue time (oldest first)
    const sorted = [...queue].sort((a, b) => a.queuedAtMs - b.queuedAtMs);
    const pivot = sorted[0]; // longest-waiting player
    const waitSec = (now - pivot.queuedAtMs) / 1000;

    // Widen spread by 50 MMR per 15 seconds of wait
    const widening = Math.floor(waitSec / 15) * this.mmrWidenPerSec;
    const effectiveSpread = this.maxSpread + widening;

    // Find candidates within the effective spread
    const candidates = sorted.filter(
      (p) => Math.abs(p.mmr - pivot.mmr) <= effectiveSpread / 2,
    );

    if (candidates.length >= requiredPlayers) {
      const selected = candidates.slice(0, requiredPlayers);
      return { players: selected, matchId: this.generateMatchId() };
    }

    // Bot backfill after 45s
    if (waitSec >= this.botFillDelaySec && candidates.length > 0) {
      const botsNeeded = requiredPlayers - candidates.length;
      const bots: QueueEntry[] = Array.from({ length: botsNeeded }, (_, i) => ({
        userId: `bot-${this.generateMatchId()}-${i}`,
        mmr: pivot.mmr,
        queuedAtMs: now,
        isBot: true,
      }));
      return { players: [...candidates, ...bots], matchId: this.generateMatchId() };
    }

    return null;
  }

  /**
   * Removes the given player IDs from the queue (atomic dequeue).
   */
  dequeue(queue: QueueEntry[], playerIds: string[]): QueueEntry[] {
    const idSet = new Set(playerIds);
    return queue.filter((p) => !idSet.has(p.userId));
  }
}
