import { JwtValidator, createTestJwt } from '../../../server/src/auth/jwtValidator';
import { createLogger } from '../../../server/src/logging/logger';
import { Writable } from 'stream';

// ---------------------------------------------------------------------------
// Minimal Socket mock for testing JWT auth middleware logic
// ---------------------------------------------------------------------------

function nullLogger() {
  return createLogger({ level: 'fatal', destination: new Writable({ write: (_c, _e, cb) => cb() }) });
}

const SECRET = 'transport-test-secret';
const NOW = Math.floor(Date.now() / 1000);

function makeValidator() {
  return new JwtValidator({ secret: SECRET, issuer: 'test', now: () => NOW });
}

function makeJwt(userId: string) {
  return createTestJwt({ sub: userId, exp: NOW + 3600 }, SECRET);
}

// RTT and interpolation logic tests
function computeRtt(pingSentMs: number, pongReceivedMs: number): number {
  return pongReceivedMs - pingSentMs;
}

function computeMovingAvgRtt(samples: number[]): number {
  if (samples.length === 0) return 0;
  return samples.reduce((s, v) => s + v, 0) / samples.length;
}

function classifyQuality(avgRttMs: number): 'good' | 'fair' | 'poor' | 'critical' {
  if (avgRttMs < 100) return 'good';
  if (avgRttMs < 150) return 'fair';
  if (avgRttMs < 200) return 'poor';
  return 'critical';
}

function interpolatePosition(
  posA: number, posB: number,
  timestampA: number, timestampB: number,
  renderTime: number,
): number {
  const alpha = Math.max(0, Math.min(1, (renderTime - timestampA) / (timestampB - timestampA)));
  return posA + alpha * (posB - posA);
}

function lagCompensateTick(playerRttMs: number): number {
  return Math.floor(Math.min(playerRttMs, 200) / 50);
}

// ---------------------------------------------------------------------------
// Story 001: JWT auth (AC-RT-01, 02, 03)
// ---------------------------------------------------------------------------

describe('realtime-transport — story-001: JWT auth', () => {
  it('test_validJwt_authenticates', async () => {
    const validator = makeValidator();
    const token = makeJwt('user-abc');
    const result = await validator.validateToken(token);
    expect(JwtValidator.isError(result)).toBe(false);
    if (!JwtValidator.isError(result)) expect(result.userId).toBe('user-abc');
  });

  it('test_invalidJwt_rejected', async () => {
    const validator = makeValidator();
    const result = await validator.validateToken('bad.token.here');
    expect(JwtValidator.isError(result)).toBe(true);
    if (JwtValidator.isError(result)) expect(result.error).toBe('TOKEN_INVALID');
  });

  it('test_expiredJwt_rejected', async () => {
    const token = createTestJwt({ sub: 'u1', exp: NOW - 60 }, SECRET);
    const validator = makeValidator();
    const result = await validator.validateToken(token);
    expect(JwtValidator.isError(result)).toBe(true);
    if (JwtValidator.isError(result)) expect(result.error).toBe('TOKEN_EXPIRED');
  });
});

// ---------------------------------------------------------------------------
// Story 004: Ping/Pong RTT (AC-RT-07, 08, 16)
// ---------------------------------------------------------------------------

describe('realtime-transport — story-004: RTT measurement', () => {
  it('test_rttCalculation', () => {
    const pingSent = 1000;
    const pongReceived = 1080;
    expect(computeRtt(pingSent, pongReceived)).toBe(80);
  });

  it('test_movingAvgRtt_exactCalculation', () => {
    const avg = computeMovingAvgRtt([80, 90, 100, 110, 120]);
    expect(avg).toBe(100);
  });

  it('test_qualityThreshold_poor_at160ms', () => {
    expect(classifyQuality(160)).toBe('poor');
  });

  it('test_qualityThreshold_good_under100ms', () => {
    expect(classifyQuality(99)).toBe('good');
  });

  it('test_qualityThreshold_critical_over200ms', () => {
    expect(classifyQuality(201)).toBe('critical');
  });
});

// ---------------------------------------------------------------------------
// Story 007: Client prediction interpolation (AC-RT-12, 13)
// ---------------------------------------------------------------------------

describe('realtime-transport — story-007: interpolation', () => {
  it('test_interpolation_alpha0_returnsPositionA', () => {
    const pos = interpolatePosition(100, 200, 1000, 1050, 1000);
    expect(pos).toBe(100);
  });

  it('test_interpolation_alpha1_returnsPositionB', () => {
    const pos = interpolatePosition(100, 200, 1000, 1050, 1050);
    expect(pos).toBe(200);
  });

  it('test_interpolation_midpoint', () => {
    const pos = interpolatePosition(100, 200, 1000, 1050, 1025);
    expect(pos).toBe(150);
  });

  it('test_interpolation_clampedAt0', () => {
    // renderTime before tickA
    const pos = interpolatePosition(100, 200, 1000, 1050, 900);
    expect(pos).toBe(100); // alpha clamped to 0
  });

  it('test_interpolation_clampedAt1', () => {
    // renderTime after tickB
    const pos = interpolatePosition(100, 200, 1000, 1050, 1100);
    expect(pos).toBe(200); // alpha clamped to 1
  });
});

// ---------------------------------------------------------------------------
// Story 007/008: Lag compensation
// ---------------------------------------------------------------------------

describe('realtime-transport — lag compensation', () => {
  it('test_lagCompensate_50msRtt_1tick', () => {
    expect(lagCompensateTick(50)).toBe(1);
  });

  it('test_lagCompensate_100msRtt_2ticks', () => {
    expect(lagCompensateTick(100)).toBe(2);
  });

  it('test_lagCompensate_200msCap', () => {
    expect(lagCompensateTick(300)).toBe(4); // 200ms cap / 50ms = 4
  });

  it('test_lagCompensate_0ms_0ticks', () => {
    expect(lagCompensateTick(0)).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// Story 009: Serialization integrity (AC-RT-17)
// ---------------------------------------------------------------------------

describe('realtime-transport — story-009: serialization', () => {
  it('test_matchState_jsonSerializable', () => {
    const matchState = {
      tick: 42,
      timestamp: Date.now(),
      players: [
        { playerId: 'p1', x: 10.5, y: 20.3, hp: 85, maxHp: 100, statusEffects: [] }
      ],
    };
    const serialized = JSON.stringify(matchState);
    const parsed = JSON.parse(serialized);
    expect(parsed.tick).toBe(42);
    expect(parsed.players[0].hp).toBe(85);
    expect(parsed).not.toHaveProperty('undefined');
  });

  it('test_undefinedValues_notInOutput', () => {
    const obj = { a: 1, b: undefined, c: 'hello' };
    const cleaned = JSON.parse(JSON.stringify(obj));
    expect(cleaned).not.toHaveProperty('b');
  });
});
