# Story 001: Email/Password Registration & Login

> **Epic**: Authentication
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/authentication.md`
**Requirement**: `TR-auth-???` *(TR registry not yet populated — run `/architecture-review`)*

**ADR Governing Implementation**: ADR-0004: Authentication Architecture
**ADR Decision Summary**: Supabase Auth with RS256 JWT; local server validation; guest accounts supported. Client stores JWT in Expo SecureStore; server validates on every request using cached Supabase public key.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW
**Engine Notes**: `@supabase/supabase-js` and Expo SecureStore are within training data. Verify `expo-secure-store` API hasn't changed post-May-2025.

**Control Manifest Rules (this layer)**:
- Required: All REST routes must be protected by JWT middleware
- Forbidden: No `userId` from request body trusted — always from validated JWT
- Guardrail: Auth validation must add ≤1ms overhead per request

---

## Acceptance Criteria

*From GDD `design/gdd/authentication.md`, scoped to this story:*

- [x] A new email/password account can be created successfully on a clean install, and the player reaches the authenticated home flow without unnecessary delay
- [x] Attempting to register with an email already in use does not create a second account; client displays an appropriate message
- [x] Submitting invalid credentials (wrong password) does not authenticate the user and surfaces an error
- [x] `supabase.auth.signUp()` + `supabase.auth.signInWithPassword()` are the implementation paths — no custom auth server
- [x] JWT stored in Expo SecureStore after successful authentication
- [x] `POST /v1/auth/register` and `POST /v1/auth/login` return `{ userId, jwt }` on success

---

## Implementation Notes

*From ADR-0004 Implementation Guidelines:*

- Use `supabase.auth.signUp({ email, password })` for registration; `supabase.auth.signInWithPassword({ email, password })` for login
- On success, store JWT via `SecureStore.setItemAsync('jwt', session.access_token)`
- Server routes `POST /v1/auth/register` and `POST /v1/auth/login` create the profile row (via Supabase trigger or explicit API call) and return the full JWT
- Duplicate email → Supabase returns `AuthApiError`; surface as HTTP 409 with player-friendly message
- Wrong password → Supabase returns `AuthApiError`; surface as HTTP 401 with "Invalid credentials" message (never expose which field was wrong)

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 002: Google OAuth and Sign in with Apple flows
- Story 003: Session persistence on cold start
- Story 004: Token refresh lifecycle

---

## QA Test Cases

- **AC-1**: New email/password registration succeeds
  - Given: Clean install, unique email address
  - When: `supabase.auth.signUp({ email, password })` called with valid credentials
  - Then: Returns session with non-null `access_token`; user row created in Supabase Auth; player profile row created
  - Edge cases: Email with special characters (allowed by RFC 5321); password at minimum length boundary

- **AC-2**: Duplicate email registration rejected
  - Given: Email `test@example.com` already exists in Supabase Auth
  - When: `signUp()` called with the same email
  - Then: `AuthApiError` thrown; HTTP 409 returned to client; no duplicate row in `auth.users`
  - Edge cases: Email case-insensitivity (`TEST@EXAMPLE.COM` = `test@example.com`)

- **AC-3**: Wrong password login rejected
  - Given: Valid email exists; wrong password submitted
  - When: `signInWithPassword()` called
  - Then: `AuthApiError` thrown; HTTP 401 returned; no JWT issued; no session created

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/authentication/email-password-auth_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (first story)
- Unlocks: Story 002 (OAuth), Story 003 (session persistence), Story 006 (server JWT validation)
