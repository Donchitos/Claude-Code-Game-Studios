import { IContentCatalog, CatalogRecord } from '../catalog/contentCatalog';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface GameModeConfig extends CatalogRecord {
  type: 'mode';
  displayName: string;
  playerCount: number;
  teamSize: number;
  maxDurationSec: number;
  winCondition: 'last_standing' | 'team_elimination' | 'score_target';
}

export type GameModeId = 'mode:duel_1v1' | 'mode:squad_3v3' | 'mode:ffa_8';

export interface MatchPlayerState {
  playerId: string;
  teamId?: number; // 0 or 1 for team modes; undefined for FFA
  hp: number;
  maxHp: number;
  isAlive: boolean;
  eliminatedAt?: number; // server time ms
  spawnTime: number; // server time ms when player spawned
  kills: number;
  score: number;
}

export type WinReason = 'elimination' | 'timeout' | 'last_standing' | 'draw';

export interface WinResult {
  winners: string[]; // playerIds; empty = draw
  reason: WinReason;
  isDraw: boolean;
}

// ---------------------------------------------------------------------------
// WinConditionEvaluator
// ---------------------------------------------------------------------------

const SURVIVAL_BONUS_TICKS = 200; // every 200 ticks (10s at 20Hz) = 1 survival point

export class WinConditionEvaluator {
  evaluate(
    mode: GameModeConfig,
    players: MatchPlayerState[],
    timerRemainingMs: number,
  ): WinResult | null {
    const alivePlayers = players.filter((p) => p.isAlive);
    const effectiveMax = Math.min(mode.maxDurationSec, 600); // matchDurationCapSec = 600

    if (mode.winCondition === 'last_standing' || mode.id === 'mode:duel_1v1') {
      return this.evalLastStanding(alivePlayers, timerRemainingMs, players);
    }

    if (mode.id === 'mode:squad_3v3') {
      return this.evalSquad(alivePlayers, timerRemainingMs, players);
    }

    if (mode.id === 'mode:ffa_8') {
      return this.evalFFA(alivePlayers, timerRemainingMs, players);
    }

    return null;
  }

  private evalLastStanding(
    alive: MatchPlayerState[],
    timerRemainingMs: number,
    all: MatchPlayerState[],
  ): WinResult | null {
    if (alive.length === 0) {
      return { winners: [], reason: 'elimination', isDraw: true };
    }
    if (alive.length === 1) {
      return { winners: [alive[0].playerId], reason: 'last_standing', isDraw: false };
    }
    if (timerRemainingMs <= 0) {
      return this.tiebreakerByHpPercent(alive, 'timeout');
    }
    return null;
  }

  private evalSquad(
    alive: MatchPlayerState[],
    timerRemainingMs: number,
    all: MatchPlayerState[],
  ): WinResult | null {
    const teams = [0, 1].map((teamId) => ({
      teamId,
      alive: alive.filter((p) => p.teamId === teamId),
    }));

    // Team fully eliminated
    for (const team of teams) {
      if (team.alive.length === 0) {
        const winners = alive.map((p) => p.playerId);
        return { winners, reason: 'elimination', isDraw: false };
      }
    }

    if (timerRemainingMs <= 0) {
      if (teams[0].alive.length !== teams[1].alive.length) {
        const winning = teams[0].alive.length > teams[1].alive.length ? teams[0] : teams[1];
        return { winners: winning.alive.map((p) => p.playerId), reason: 'timeout', isDraw: false };
      }
      // Same survivor count — compare total HP%
      const hpPct = (team: typeof teams[0]) =>
        team.alive.reduce((s, p) => s + p.hp / p.maxHp, 0);
      const h0 = Math.round(hpPct(teams[0]) * 100) / 100;
      const h1 = Math.round(hpPct(teams[1]) * 100) / 100;
      if (h0 !== h1) {
        const winning = h0 > h1 ? teams[0] : teams[1];
        return { winners: winning.alive.map((p) => p.playerId), reason: 'timeout', isDraw: false };
      }
      return { winners: [], reason: 'draw' as WinReason, isDraw: true };
    }
    return null;
  }

  private evalFFA(
    alive: MatchPlayerState[],
    timerRemainingMs: number,
    all: MatchPlayerState[],
  ): WinResult | null {
    if (alive.length <= 1) {
      if (alive.length === 0) return { winners: [], reason: 'draw' as WinReason, isDraw: true };
      return { winners: [alive[0].playerId], reason: timerRemainingMs <= 0 ? 'timeout' : 'last_standing', isDraw: false };
    }
    if (timerRemainingMs <= 0) {
      // Highest scorer wins
      const sorted = [...alive].sort((a, b) => b.score - a.score);
      if (sorted[0].score !== sorted[1].score) {
        return { winners: [sorted[0].playerId], reason: 'timeout', isDraw: false };
      }
      // Tie on score — draw
      return { winners: [], reason: 'draw' as WinReason, isDraw: true };
    }
    return null;
  }

  private tiebreakerByHpPercent(alive: MatchPlayerState[], reason: WinReason): WinResult {
    const sorted = [...alive].sort((a, b) => b.hp / b.maxHp - a.hp / a.maxHp);
    const topHpPct = Math.round((sorted[0].hp / sorted[0].maxHp) * 100) / 100;
    const secondHpPct = alive.length > 1 ? Math.round((sorted[1].hp / sorted[1].maxHp) * 100) / 100 : -1;
    if (topHpPct !== secondHpPct) {
      return { winners: [sorted[0].playerId], reason, isDraw: false };
    }
    return { winners: [], reason: 'draw' as WinReason, isDraw: true };
  }
}

// ---------------------------------------------------------------------------
// ScoreTracker
// ---------------------------------------------------------------------------

export interface ScoreEvent {
  killerId: string;
  eliminatedId: string;
  assistants: string[];
  nowMs: number;
}

export class ScoreTracker {
  private readonly ELIMINATION_POINTS = 10;
  private readonly ASSIST_POINTS = 3;
  private readonly SURVIVAL_BONUS_PER_10S = 1;

  recordElimination(players: MatchPlayerState[], event: ScoreEvent): void {
    const killer = players.find((p) => p.playerId === event.killerId);
    if (killer) killer.score += this.ELIMINATION_POINTS;

    for (const assistId of event.assistants) {
      const assistant = players.find((p) => p.playerId === assistId && p.isAlive);
      if (assistant) assistant.score += this.ASSIST_POINTS;
    }

    const eliminated = players.find((p) => p.playerId === event.eliminatedId);
    if (eliminated) {
      eliminated.isAlive = false;
      eliminated.eliminatedAt = event.nowMs;
    }
  }

  computeSurvivalBonus(player: MatchPlayerState, matchEndMs: number): number {
    const survivalMs = (player.eliminatedAt ?? matchEndMs) - player.spawnTime;
    return Math.floor(survivalMs / 10_000) * this.SURVIVAL_BONUS_PER_10S;
  }
}

// ---------------------------------------------------------------------------
// GameModeService
// ---------------------------------------------------------------------------

export class GameModeService {
  private readonly catalog: IContentCatalog;
  private availableModes: Set<string>;

  constructor(catalog: IContentCatalog) {
    this.catalog = catalog;
    this.availableModes = new Set(['mode:duel_1v1', 'mode:squad_3v3', 'mode:ffa_8']);
  }

  getConfig(modeId: string): GameModeConfig | null {
    return this.catalog.get<GameModeConfig>(modeId);
  }

  isAvailable(modeId: string): boolean {
    return this.availableModes.has(modeId);
  }

  setAvailableModes(modes: string[]): void {
    this.availableModes = new Set(modes);
  }

  getEffectiveMaxDuration(modeId: string, capSec = 600): number {
    const config = this.getConfig(modeId);
    if (!config) return capSec;
    return Math.min(config.maxDurationSec, capSec);
  }
}
