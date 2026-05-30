# ADR-0004: Authentication Architecture (Supabase JWT + Token Lifecycle)

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director, Security Engineer

## Summary

BRAWLZONE uses Supabase Auth as the identity provider, issuing JWTs that the Node.js server validates on every HTTP request and Socket.io connection. Anonymous guest accounts are supported with a migration path to permanent accounts. This ADR defines the full token lifecycle from sign-up through socket authentication and refresh.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | Networking / Core |
| **Knowledge Risk** | LOW — Supabase JS client and JWT patterns are within training data |
| **References Consulted** | `docs/engine-reference/react-native/VERSION.md`, `design/gdd/authentication.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm Supabase JWT RS256 public key endpoint hasn't changed post-May-2025 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (client-server architecture — JWT Validator placement) |
| **Enables** | ADR-0005, ADR-0006, ADR-0009, ADR-0012 |
| **Blocks** | All server endpoints; no API handler may be implemented without JWT validation middleware |
| **Ordering Note** | Must be Accepted before any server route or socket handler is written |

## Context

### Problem Statement

Every Socket.io event and REST endpoint must be authenticated. Anonymous players must be able to start playing immediately without registration friction, with an upgrade path to permanent accounts that preserves progress.

### Current State

New project. `mobile/services/supabase.ts` is scaffolded. No server JWT validation exists yet.

### Constraints

- Supabase Auth is the identity provider (already provisioned)
- JWT must be validated server-side on every request — no client-trusted claims
- Anonymous guest flow required (GDD requirement: players must be able to play without registering)
- React Native Keychain / SecureStore for token persistence on device
- Socket.io unauthenticated connections must be disconnected after 5 seconds

### Requirements

- Sign-up, sign-in, anonymous, and guest-migration flows
- JWT injected automatically in every HTTP request via API Client interceptor
- Socket.io `authenticate` event must be the first event after connection; unauthenticated sockets terminated at 5s
- JWT refresh handled transparently by Supabase client SDK; server never sees expired tokens in normal operation
- Server validates token using Supabase public key (RS256); does not call Supabase on every request

## Decision

Use **Supabase Auth** with RS256 JWTs. The client stores the JWT in Expo SecureStore and injects it on every outbound request. The server validates tokens locally using the cached Supabase RS256 public key — no Supabase round-trip per request.

### Architecture

```
CLIENT                      SUPABASE AUTH           SERVER
  │ signIn(email, pw)           │                     │
  ├────────────────────────────→│                     │
  │←── { jwt, refreshToken } ───│                     │
  │                                                   │
  │ SecureStore.setItem('jwt', jwt)                   │
  │                                                   │
  │ GET /v1/profile ──────────────────────────────────│
  │   Authorization: Bearer {jwt}                     │
  │                             │ validateToken(jwt)  │
  │                             │ (local RS256 verify)│
  │←── PlayerProfile ─────────────────────────────────│
  │                                                   │
  │ socket.connect({ auth: { token: jwt } })          │
  │────────────────────────────────────────────────→  │
  │                             │ socket middleware:  │
  │                             │ validateToken(jwt)  │
  │                             │ attach userId       │
  │←── connected ──────────────────────────────────── │
  │                                                   │
  │ [5s later if no authenticate event]               │
  │────────────────────── disconnect ──────────────── │
```

### Key Interfaces

```typescript
// Server: JWT Validator
interface IJWTValidator {
  validateToken(jwt: string): Promise<{ userId: string } | AuthError>;
  // Caches Supabase RS256 public key in memory; refreshes on 401
}

// Server: Socket middleware
io.use(async (socket, next) => {
  const token = socket.handshake.auth.token;
  const result = await jwtValidator.validateToken(token);
  if ('error' in result) return next(new Error('auth_error'));
  socket.data.userId = result.userId;
  next();
});

// Client: API Client interceptor
// Injects JWT from SecureStore on every outbound HTTP request
axiosInstance.interceptors.request.use(async (config) => {
  const session = await supabase.auth.getSession();
  if (session.data.session) {
    config.headers.Authorization = `Bearer ${session.data.session.access_token}`;
  }
  return config;
});

// REST endpoints
POST /v1/auth/register      { email, password }           → { userId, jwt }
POST /v1/auth/login         { email, password }           → { jwt, profile }
POST /v1/auth/refresh       { refreshToken }              → { jwt }
POST /v1/auth/anonymous                                   → { guestId, jwt }
POST /v1/auth/migrate-guest { jwt, email, password }      → { userId, jwt }
```

### Implementation Guidelines

- JWT validation is a synchronous in-process operation after public key is cached; it must add ≤1ms to every request
- The Supabase client SDK handles token refresh automatically on the client; the server only validates, never issues tokens
- `socket.data.userId` is the canonical user identifier within any socket handler — never trust a userId from the client payload
- Guest accounts have the same `userId` UUID format as permanent accounts; the `is_guest` flag lives in `player_profiles`
- Guest → permanent migration is a server-side operation that preserves the userId; only email/password credentials are added

## Alternatives Considered

### Alternative 1: Custom JWT Issuer (Node.js)

- **Description**: Server issues and validates its own JWTs, no external auth provider.
- **Pros**: No vendor dependency; full control over token claims.
- **Cons**: Must implement refresh token rotation, revocation, email verification, OAuth providers — months of work.
- **Rejection Reason**: Supabase provides all required flows out of the box; no competitive advantage in building auth from scratch.

### Alternative 2: Firebase Auth

- **Description**: Use Firebase Authentication instead of Supabase.
- **Pros**: Mature SDK; excellent React Native support.
- **Cons**: Project already uses Supabase for PostgreSQL and real-time; using Firebase Auth would create a split identity provider and complicate RLS policies.
- **Rejection Reason**: Supabase Auth integrates natively with Supabase PostgreSQL Row Level Security.

## Consequences

### Positive

- RS256 local validation means zero Supabase round-trips per authenticated request
- Guest accounts remove registration friction (GDD requirement satisfied)
- Supabase handles email verification, password reset, OAuth — no custom implementation needed

### Negative

- Supabase Auth is a vendor dependency; migration would require changing every JWT issuance point
- Token refresh on the client must be handled proactively; expired JWTs on long-running sessions need testing

### Neutral

- `userId` is a Supabase UUID; all other tables use it as foreign key

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Supabase RS256 public key endpoint changes | Low | High | Cache key with 24h TTL; fallback to re-fetch on validation failure |
| JWT SecureStore race on cold start | Medium | Medium | Show loading screen until `supabase.auth.getSession()` resolves before any authenticated call |
| Guest account proliferation in DB | Low | Low | Scheduled job purges guest accounts inactive > 90 days |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Auth overhead per HTTP request | — | ≤1ms (local RS256) | 5ms |
| Auth overhead per socket connect | — | ≤1ms | 5ms |
| Token refresh (client) | — | Background, transparent | — |

## Migration Plan

New project — no migration required.

**Rollback plan**: Replace Supabase Auth with Firebase Auth or custom JWT — requires replacing the `IJWTValidator` implementation and `@supabase/supabase-js` auth calls; server-side impact is isolated to `validateToken()`.

## Validation Criteria

- [ ] Valid JWT allows access to `/v1/profile` and socket connection
- [ ] Expired JWT returns 401 on HTTP and `auth_error` on socket
- [ ] Unauthenticated socket is disconnected after exactly 5 seconds
- [ ] Guest → permanent migration preserves `userId`, coins, and entitlements
- [ ] Token refresh happens transparently; user is never shown a re-login screen mid-session

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/authentication.md` | Auth | Supabase Auth with JWT | Supabase Auth chosen; RS256 local validation defined |
| `design/gdd/authentication.md` | Auth | Anonymous guest accounts | `POST /v1/auth/anonymous` and migration endpoint defined |
| `design/gdd/authentication.md` | Auth | Server validates JWT on every request | JWT Validator middleware on all routes and socket connections |
| `design/gdd/player-profile.md` | Player Profile | Profile fetched on login | `GET /v1/profile` defined; requires valid JWT |

## Related

- ADR-0001: Establishes the JWT Validator in the server Foundation layer
- ADR-0005: Database Architecture — `player_profiles` table owns the `is_guest` flag
- ADR-0006: Client State Management — Profile Store reads session from Supabase Auth
