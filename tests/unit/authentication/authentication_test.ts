import { JwtValidator, createTestJwt, JwtPayload } from '../../../server/src/auth/jwtValidator';

const SECRET = 'test-secret-key-12345';
const ISSUER = 'https://test.supabase.co';
const NOW = Math.floor(Date.now() / 1000);

function makeValidator(now?: number) {
  return new JwtValidator({
    secret: SECRET,
    issuer: ISSUER,
    now: now !== undefined ? () => now : undefined,
  });
}

function makeToken(payload: Partial<JwtPayload> & { sub: string }, exp?: number) {
  return createTestJwt({ ...payload, exp: exp ?? NOW + 3600 }, SECRET);
}

// ---------------------------------------------------------------------------
// Story 001: Email/password + Token structure (AC auth)
// ---------------------------------------------------------------------------

describe('authentication — story-001/006: JWT validation', () => {
  // AC: Valid JWT → validation succeeds
  it('test_validJwt_returnsUserId', async () => {
    const token = makeToken({ sub: 'user-abc-123' });
    const validator = makeValidator(NOW);
    const result = await validator.validateToken(token);
    expect(JwtValidator.isError(result)).toBe(false);
    if (!JwtValidator.isError(result)) expect(result.userId).toBe('user-abc-123');
  });

  // AC: Expired JWT → TOKEN_EXPIRED
  it('test_expiredJwt_returnsTokenExpired', async () => {
    const token = makeToken({ sub: 'user-1' }, NOW - 1); // expired
    const validator = makeValidator(NOW);
    const result = await validator.validateToken(token);
    expect(JwtValidator.isError(result)).toBe(true);
    if (JwtValidator.isError(result)) expect(result.error).toBe('TOKEN_EXPIRED');
  });

  // AC: Tampered JWT → TOKEN_INVALID
  it('test_tamperedSignature_returnsTokenInvalid', async () => {
    const token = makeToken({ sub: 'user-1' }) + 'tampered';
    const validator = makeValidator(NOW);
    const result = await validator.validateToken(token);
    expect(JwtValidator.isError(result)).toBe(true);
    if (JwtValidator.isError(result)) expect(result.error).toBe('TOKEN_INVALID');
  });

  // AC: Missing JWT → TOKEN_MISSING
  it('test_emptyJwt_returnsTokenMissing', async () => {
    const validator = makeValidator(NOW);
    const result = await validator.validateToken('');
    expect(JwtValidator.isError(result)).toBe(true);
    if (JwtValidator.isError(result)) expect(result.error).toBe('TOKEN_MISSING');
  });

  // AC: Malformed JWT → TOKEN_INVALID
  it('test_malformedJwt_returnsTokenInvalid', async () => {
    const validator = makeValidator(NOW);
    const result = await validator.validateToken('not.a.valid.jwt.format');
    expect(JwtValidator.isError(result)).toBe(true);
  });

  // AC: userId always from JWT sub claim, never from body
  it('test_userId_alwaysFromSubClaim', async () => {
    const token = makeToken({ sub: 'real-user-id' });
    const validator = makeValidator(NOW);
    const result = await validator.validateToken(token);
    if (!JwtValidator.isError(result)) {
      expect(result.userId).toBe('real-user-id');
    }
  });
});

// ---------------------------------------------------------------------------
// Story 003/004: Session persistence + token refresh concepts
// ---------------------------------------------------------------------------

describe('authentication — token lifecycle concepts', () => {
  it('test_freshToken_doesNotExpireImmediately', async () => {
    const token = makeToken({ sub: 'u1' }, NOW + 3600); // 1 hour valid
    const validator = makeValidator(NOW);
    const result = await validator.validateToken(token);
    expect(JwtValidator.isError(result)).toBe(false);
  });

  it('test_tokenAt_exactExpiryBoundary_isExpired', async () => {
    const token = makeToken({ sub: 'u1' }, NOW); // exp === now → expired
    const validator = makeValidator(NOW);
    const result = await validator.validateToken(token);
    expect(JwtValidator.isError(result)).toBe(true);
    if (JwtValidator.isError(result)) expect(result.error).toBe('TOKEN_EXPIRED');
  });

  it('test_createTestJwt_producesValidToken', async () => {
    const token = createTestJwt({ sub: 'test-user', exp: NOW + 60 }, SECRET);
    const parts = token.split('.');
    expect(parts.length).toBe(3);
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString());
    expect(payload.sub).toBe('test-user');
  });
});
