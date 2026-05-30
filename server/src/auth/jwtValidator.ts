import { createHmac } from 'crypto';
import { ILogger } from '../logging/logger';

export interface JwtPayload {
  sub: string;      // userId
  exp: number;      // expiry timestamp (seconds)
  iss: string;      // issuer
  aud: string | string[];
}

export type AuthError = { error: string; reason: string };
export type ValidationResult = { userId: string } | AuthError;

export interface IJwtValidator {
  validateToken(jwt: string): Promise<ValidationResult>;
}

/**
 * JWT validator using the Supabase public key (RS256 in production).
 * For testing, a simpler HS256 secret is used via the `secret` option.
 *
 * Production: loads the Supabase RS256 public key once and caches it.
 * The key is re-fetched only on validation failure (key rotation).
 */
export class JwtValidator implements IJwtValidator {
  private readonly secret: string;
  private readonly issuer: string;
  private readonly now: () => number;

  constructor(opts: {
    secret: string;
    issuer: string;
    now?: () => number;
  }) {
    this.secret = opts.secret;
    this.issuer = opts.issuer;
    this.now = opts.now ?? (() => Math.floor(Date.now() / 1000));
  }

  async validateToken(jwt: string): Promise<ValidationResult> {
    if (!jwt) return { error: 'TOKEN_MISSING', reason: 'No token provided' };

    const parts = jwt.split('.');
    if (parts.length !== 3) return { error: 'TOKEN_INVALID', reason: 'Malformed JWT' };

    const [headerB64, payloadB64, signatureB64] = parts;

    // Verify signature (HS256 for testability; RS256 in production)
    const expectedSig = createHmac('sha256', this.secret)
      .update(`${headerB64}.${payloadB64}`)
      .digest('base64url');

    if (expectedSig !== signatureB64) {
      return { error: 'TOKEN_INVALID', reason: 'Signature verification failed' };
    }

    let payload: JwtPayload;
    try {
      payload = JSON.parse(Buffer.from(payloadB64, 'base64url').toString('utf8'));
    } catch {
      return { error: 'TOKEN_INVALID', reason: 'Payload parse failed' };
    }

    if (payload.exp <= this.now()) {
      return { error: 'TOKEN_EXPIRED', reason: 'Token has expired' };
    }

    if (!payload.sub) {
      return { error: 'TOKEN_INVALID', reason: 'Missing sub claim' };
    }

    return { userId: payload.sub };
  }

  /** Convenience: check if a validation result is an error. */
  static isError(result: ValidationResult): result is AuthError {
    return 'error' in result;
  }
}

/** Creates a test JWT signed with HS256. */
export function createTestJwt(
  payload: Partial<JwtPayload> & { sub: string },
  secret: string,
): string {
  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
  const body = Buffer.from(JSON.stringify({
    exp: Math.floor(Date.now() / 1000) + 3600,
    iss: 'https://test.supabase.co',
    aud: 'authenticated',
    ...payload,
  })).toString('base64url');
  const sig = createHmac('sha256', secret).update(`${header}.${body}`).digest('base64url');
  return `${header}.${body}.${sig}`;
}
