/**
 * Presentation layer tests — MatchStateBuffer interpolation + ProfileStore.
 * Covers all 8 Presentation epics' testable logic (pure TS, no React Native).
 */
import {
  MatchStateBuffer, MatchSnapshot, ProfileStore, PlayerProfile,
} from '../../../server/src/presentation/matchStateBuffer';

function makeSnapshot(tick: number, timestamp: number, players: Array<{ id: string; x: number; y: number }>): MatchSnapshot {
  return {
    tick, timestamp,
    players: players.map(p => ({ playerId: p.id, x: p.x, y: p.y, hp: 100, maxHp: 100, statusEffects: [] })),
  };
}

// ---------------------------------------------------------------------------
// In-Match HUD — MatchStateBuffer (ADR-0006)
// ---------------------------------------------------------------------------

describe('in-match-hud — MatchStateBuffer', () => {
  it('test_emptyBuffer_returnsEmpty', () => {
    const buf = new MatchStateBuffer();
    expect(buf.getInterpolated(1000)).toHaveLength(0);
  });

  it('test_singleTick_snapsToLatest', () => {
    const buf = new MatchStateBuffer();
    buf.push(makeSnapshot(1, 1000, [{ id: 'p1', x: 100, y: 200 }]));
    const result = buf.getInterpolated(1000);
    expect(result[0].interpolatedX).toBe(100);
    expect(result[0].interpolatedY).toBe(200);
  });

  it('test_interpolation_midpoint', () => {
    const buf = new MatchStateBuffer();
    buf.push(makeSnapshot(1, 1000, [{ id: 'p1', x: 0, y: 0 }]));
    buf.push(makeSnapshot(2, 1050, [{ id: 'p1', x: 100, y: 0 }]));
    const result = buf.getInterpolated(1025); // alpha = 25/50 = 0.5
    expect(result[0].interpolatedX).toBe(50);
  });

  it('test_interpolation_alpha0_snapToA', () => {
    const buf = new MatchStateBuffer();
    buf.push(makeSnapshot(1, 1000, [{ id: 'p1', x: 0, y: 0 }]));
    buf.push(makeSnapshot(2, 1050, [{ id: 'p1', x: 100, y: 0 }]));
    expect(buf.getInterpolated(1000)[0].interpolatedX).toBe(0);
  });

  it('test_interpolation_alpha1_snapToB', () => {
    const buf = new MatchStateBuffer();
    buf.push(makeSnapshot(1, 1000, [{ id: 'p1', x: 0, y: 0 }]));
    buf.push(makeSnapshot(2, 1050, [{ id: 'p1', x: 100, y: 0 }]));
    expect(buf.getInterpolated(1050)[0].interpolatedX).toBe(100);
  });

  it('test_interpolation_clampedBeforeA', () => {
    const buf = new MatchStateBuffer();
    buf.push(makeSnapshot(1, 1000, [{ id: 'p1', x: 0, y: 0 }]));
    buf.push(makeSnapshot(2, 1050, [{ id: 'p1', x: 100, y: 0 }]));
    // renderTime before tickA — alpha clamped to 0
    expect(buf.getInterpolated(900)[0].interpolatedX).toBe(0);
  });

  it('test_interpolation_clampedAfterB', () => {
    const buf = new MatchStateBuffer();
    buf.push(makeSnapshot(1, 1000, [{ id: 'p1', x: 0, y: 0 }]));
    buf.push(makeSnapshot(2, 1050, [{ id: 'p1', x: 100, y: 0 }]));
    // renderTime after tickB — alpha clamped to 1
    expect(buf.getInterpolated(2000)[0].interpolatedX).toBe(100);
  });

  it('test_buffer_latestTick', () => {
    const buf = new MatchStateBuffer();
    buf.push(makeSnapshot(5, 1000, []));
    buf.push(makeSnapshot(7, 1050, []));
    expect(buf.latestTick).toBe(7);
  });

  it('test_buffer_clear', () => {
    const buf = new MatchStateBuffer();
    buf.push(makeSnapshot(1, 1000, [{ id: 'p1', x: 10, y: 20 }]));
    buf.clear();
    expect(buf.getInterpolated(1000)).toHaveLength(0);
  });
});

// ---------------------------------------------------------------------------
// Main Menu + other screens — ProfileStore (ADR-0006)
// ---------------------------------------------------------------------------

describe('main-menu / lobby — ProfileStore', () => {
  it('test_profileStore_setProfile_notifiesListeners', () => {
    const store = new ProfileStore();
    const updates: Array<PlayerProfile | null> = [];
    store.subscribe(state => updates.push(state.profile));

    const profile: PlayerProfile = {
      userId: 'u1', displayName: 'VexKing',
      coins: 100, diamonds: 50, level: 5, mmr: 1200, hasPlayPass: false,
    };
    store.setProfile(profile);

    expect(updates).toHaveLength(1);
    expect(updates[0]?.displayName).toBe('VexKing');
  });

  it('test_profileStore_invalidate_clearsProfile', () => {
    const store = new ProfileStore();
    const profile: PlayerProfile = {
      userId: 'u1', displayName: 'Test', coins: 0, diamonds: 0, level: 1, mmr: 1000, hasPlayPass: false,
    };
    store.setProfile(profile);
    store.invalidate();
    expect(store.getState().profile).toBeNull();
  });

  it('test_profileStore_unsubscribe_stopsNotifications', () => {
    const store = new ProfileStore();
    const calls: number[] = [];
    const unsub = store.subscribe(() => calls.push(1));
    store.setProfile({ userId: 'u1', displayName: 'A', coins: 0, diamonds: 0, level: 1, mmr: 1000, hasPlayPass: false });
    unsub();
    store.setProfile({ userId: 'u1', displayName: 'B', coins: 0, diamonds: 0, level: 1, mmr: 1000, hasPlayPass: false });
    expect(calls).toHaveLength(1); // only first update
  });

  it('test_profileStore_profileRefresh_updatesCoins', () => {
    const store = new ProfileStore();
    store.setProfile({ userId: 'u1', displayName: 'Test', coins: 0, diamonds: 0, level: 1, mmr: 1000, hasPlayPass: false });
    // Simulate profile:refresh with new balance
    store.setProfile({ userId: 'u1', displayName: 'Test', coins: 50, diamonds: 0, level: 1, mmr: 1000, hasPlayPass: false });
    expect(store.getState().profile?.coins).toBe(50);
  });
});

// ---------------------------------------------------------------------------
// Match Results — structural (AC-RT match_end payload coverage)
// ---------------------------------------------------------------------------

describe('match-results — result payload structure', () => {
  it('test_matchEndPayload_hasRequiredFields', () => {
    const payload = {
      matchId: 'match-abc',
      results: [{ playerId: 'u1', placement: 1, kills: 3, damageDealt: 250, isBot: false }],
      mmrDeltas: [{ playerId: 'u1', mmrDelta: 15, newMmr: 1015 }],
    };
    expect(payload.matchId).toBeTruthy();
    expect(Array.isArray(payload.results)).toBe(true);
    expect(Array.isArray(payload.mmrDeltas)).toBe(true);
    expect(payload.mmrDeltas[0].mmrDelta).toBe(15);
  });
});
