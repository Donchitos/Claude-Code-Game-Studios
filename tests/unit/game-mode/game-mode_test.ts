import * as path from 'path';
import { ContentCatalogService } from '../../../server/src/catalog/contentCatalog';
import {
  WinConditionEvaluator, ScoreTracker, GameModeService,
  MatchPlayerState, GameModeConfig,
} from '../../../server/src/game/gameModeSystem';

const CATALOG_PATH = path.join(__dirname, '../../../server/src/data/content-catalog.json');

function makeService() {
  const catalog = ContentCatalogService.init(CATALOG_PATH);
  return new GameModeService(catalog);
}

function makeEval() { return new WinConditionEvaluator(); }

function makePlayer(id: string, hp: number, maxHp: number, overrides: Partial<MatchPlayerState> = {}): MatchPlayerState {
  return { playerId: id, hp, maxHp, isAlive: hp > 0, score: 0, kills: 0, spawnTime: 0, ...overrides };
}

const DUEL_CONFIG: GameModeConfig = {
  id: 'mode:duel_1v1', type: 'mode', status: 'active',
  displayName: 'Duel', playerCount: 2, teamSize: 1,
  maxDurationSec: 120, winCondition: 'last_standing',
};
const SQUAD_CONFIG: GameModeConfig = {
  id: 'mode:squad_3v3', type: 'mode', status: 'active',
  displayName: 'Squad', playerCount: 6, teamSize: 3,
  maxDurationSec: 180, winCondition: 'team_elimination',
};
const FFA_CONFIG: GameModeConfig = {
  id: 'mode:ffa_8', type: 'mode', status: 'active',
  displayName: 'FFA', playerCount: 8, teamSize: 1,
  maxDurationSec: 300, winCondition: 'score_target',
};

// ---------------------------------------------------------------------------
// Story 001: Win conditions (WC-01 through WC-11)
// ---------------------------------------------------------------------------

describe('game-mode — win conditions', () => {
  const ev = makeEval();

  // WC-01
  it('test_duel_eliminationWin', () => {
    const players = [makePlayer('A', 60, 100), makePlayer('B', 0, 100, { isAlive: false })];
    const result = ev.evaluate(DUEL_CONFIG, players, 50_000);
    expect(result?.winners).toContain('A');
    expect(result?.isDraw).toBe(false);
  });

  // WC-02
  it('test_duel_bothEliminatedSameTick_draw', () => {
    const players = [makePlayer('A', 0, 100, { isAlive: false }), makePlayer('B', 0, 100, { isAlive: false })];
    const result = ev.evaluate(DUEL_CONFIG, players, 50_000);
    expect(result?.isDraw).toBe(true);
  });

  // WC-03
  it('test_duel_timerExpiry_higherHpWins', () => {
    const players = [makePlayer('A', 60, 100), makePlayer('B', 40, 100)];
    const result = ev.evaluate(DUEL_CONFIG, players, 0);
    expect(result?.winners).toContain('A');
  });

  // WC-04
  it('test_duel_timerExpiry_equalHpDraw', () => {
    const players = [makePlayer('A', 50, 100), makePlayer('B', 50, 100)];
    const result = ev.evaluate(DUEL_CONFIG, players, 0);
    expect(result?.isDraw).toBe(true);
  });

  // WC-05
  it('test_squad_allTeamEliminated_otherWins', () => {
    const players = [
      makePlayer('A1', 80, 100, { teamId: 0 }), makePlayer('A2', 60, 100, { teamId: 0 }), makePlayer('A3', 40, 100, { teamId: 0 }),
      makePlayer('B1', 0, 100, { teamId: 1, isAlive: false }), makePlayer('B2', 0, 100, { teamId: 1, isAlive: false }), makePlayer('B3', 0, 100, { teamId: 1, isAlive: false }),
    ];
    const result = ev.evaluate(SQUAD_CONFIG, players, 50_000);
    expect(result?.isDraw).toBe(false);
    expect(result?.winners).toContain('A1');
  });

  // WC-09
  it('test_ffa_lastStanding', () => {
    const players = Array.from({ length: 7 }, (_, i) => makePlayer(`p${i}`, 0, 100, { isAlive: false }));
    players.push(makePlayer('winner', 50, 100));
    const result = ev.evaluate(FFA_CONFIG, players, 50_000);
    expect(result?.winners).toContain('winner');
  });

  // WC-11
  it('test_ffa_timerExpiry_tiedScoresDraw', () => {
    const players = [makePlayer('A', 50, 100, { score: 10 }), makePlayer('B', 50, 100, { score: 10 }), makePlayer('C', 0, 100, { isAlive: false, score: 5 })];
    const result = ev.evaluate(FFA_CONFIG, players, 0);
    expect(result?.isDraw).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// Story 002: Scoring (SC-01 through SC-06)
// ---------------------------------------------------------------------------

describe('game-mode — scoring', () => {
  const tracker = new ScoreTracker();

  it('test_elimination_grantsKillPoints', () => {
    const players = [makePlayer('killer', 80, 100), makePlayer('victim', 0, 100)];
    tracker.recordElimination(players, { killerId: 'killer', eliminatedId: 'victim', assistants: [], nowMs: 5000 });
    expect(players[0].score).toBe(10);
  });

  it('test_assist_grantsAssistPoints', () => {
    const players = [makePlayer('killer', 80, 100), makePlayer('victim', 0, 100), makePlayer('assist', 70, 100)];
    tracker.recordElimination(players, { killerId: 'killer', eliminatedId: 'victim', assistants: ['assist'], nowMs: 5000 });
    expect(players[2].score).toBe(3);
  });

  it('test_survivalBonus_floor10s', () => {
    const player = makePlayer('p', 80, 100, { spawnTime: 0 });
    const bonus = tracker.computeSurvivalBonus(player, 73_000);
    expect(bonus).toBe(7); // floor(73/10) = 7
  });

  it('test_eliminatedPlayer_survivalStopsAtElimination', () => {
    const player = makePlayer('p', 0, 100, { isAlive: false, spawnTime: 0, eliminatedAt: 45_000 });
    const bonus = tracker.computeSurvivalBonus(player, 300_000);
    expect(bonus).toBe(4); // floor(45/10) = 4
  });
});

// ---------------------------------------------------------------------------
// Story 003: Mode availability gating (MA-01 through MA-07)
// ---------------------------------------------------------------------------

describe('game-mode — availability gating', () => {
  it('test_allThreeModes_availableByDefault', () => {
    const svc = makeService();
    expect(svc.isAvailable('mode:duel_1v1')).toBe(true);
    expect(svc.isAvailable('mode:squad_3v3')).toBe(true);
    expect(svc.isAvailable('mode:ffa_8')).toBe(true);
  });

  it('test_setAvailableModes_restricts', () => {
    const svc = makeService();
    svc.setAvailableModes(['mode:duel_1v1']);
    expect(svc.isAvailable('mode:duel_1v1')).toBe(true);
    expect(svc.isAvailable('mode:squad_3v3')).toBe(false);
  });

  it('test_matchDurationCap_applied', () => {
    const svc = makeService();
    const effective = svc.getEffectiveMaxDuration('mode:ffa_8', 600);
    expect(effective).toBeLessThanOrEqual(600);
  });
});

// ---------------------------------------------------------------------------
// Story 004: Timer management (TM-01 through TM-04) — structural
// ---------------------------------------------------------------------------

describe('game-mode — timer management', () => {
  it('test_noWinCondition_whileTimerActive', () => {
    const ev = makeEval();
    const players = [makePlayer('A', 60, 100), makePlayer('B', 40, 100)];
    expect(ev.evaluate(DUEL_CONFIG, players, 5000)).toBeNull();
  });

  it('test_winCondition_triggeredAtZeroMs', () => {
    const ev = makeEval();
    const players = [makePlayer('A', 60, 100), makePlayer('B', 40, 100)];
    expect(ev.evaluate(DUEL_CONFIG, players, 0)).not.toBeNull();
  });
});

// ---------------------------------------------------------------------------
// Story 005: Edge cases (EC-01 through EC-05)
// ---------------------------------------------------------------------------

describe('game-mode — edge cases', () => {
  it('test_ffa_simultaneousFinalElimination_draw', () => {
    const ev = makeEval();
    const players = [makePlayer('A', 0, 100, { isAlive: false }), makePlayer('B', 0, 100, { isAlive: false })];
    const result = ev.evaluate(FFA_CONFIG, players, 50_000);
    expect(result?.isDraw).toBe(true);
  });

  it('test_ffa_1AliveAtTimeout_winner', () => {
    const ev = makeEval();
    const players = [makePlayer('A', 30, 100), ...Array.from({ length: 7 }, (_, i) => makePlayer(`p${i}`, 0, 100, { isAlive: false }))];
    const result = ev.evaluate(FFA_CONFIG, players, 0);
    expect(result?.winners).toContain('A');
    expect(result?.reason).toBe('timeout');
  });
});
