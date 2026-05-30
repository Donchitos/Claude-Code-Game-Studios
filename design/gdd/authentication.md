# Authentication

> **Status**: Complete
> **Author**: game-designer + security-engineer
> **Last Updated**: 2026-05-24
> **Implements Pillar**: Foundation — enables all player-identity-dependent systems

## Summary

Authentication validates player identity through Supabase-issued JWTs, anchoring every player-specific operation in BRAWLZONE — matchmaking, IAP, rewards, and match history — to a persistent account. Players interact with it directly at account creation and login; all subsequent token management is automatic and invisible. It is the identity foundation every downstream system depends on.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `Supabase Auth (external)`

## Overview

Authentication is the system that makes BRAWLZONE personal: when a player creates an account, they gain a persistent identity that ties their MMR, unlocked characters, cosmetics, and match history together across sessions and devices. The system supports email/password registration alongside Google OAuth and Sign in with Apple, which is the safest App Store-compliant privacy-preserving option when third-party login is offered. Once authenticated, the player receives a short-lived JWT access token and a long-lived refresh token, both stored using secure on-device storage; the Supabase client library silently refreshes the access token before expiry, so the player is never interrupted during normal play. The access token is attached to every Socket.io connection handshake and every REST API request, and the Node.js game server validates it against the Supabase public key before processing any privileged operation — match assignment, reward distribution, or purchase fulfillment — ensuring that no client can act on an account it does not own.

## Player Fantasy

Authentication has no direct player fantasy — players do not think about JWTs or session tokens. The fantasy is **what reliable identity enables**: a player who wins a ranked match feels that win counted because their MMR moved, their XP accumulated, and that record belongs to them and no one else. Persistent identity is the silent contract that makes effort meaningful. When a player grinds to unlock a character or spends Diamonds on a skin, the underlying assumption is that their account is safe, persistent, and theirs across every session and device.

The design target for Authentication UX is **frictionlessness**: account creation should take under 60 seconds and never be repeated. The experience of being logged in should be indistinguishable from not being asked about auth at all.

## Detailed Design

### Core Rules

1. **Registration and login methods** — Three auth paths are supported:
   - **Email/password**: Email/password registration creates the account. If Confirm Email is enabled in Supabase, the player must verify their email before first full sign-in; if disabled, the session can begin immediately.
   - **Google OAuth**: user signs in via Google OAuth 2.0; Supabase creates or links an account on first use.
   - **Sign in with Apple**: user signs in via Apple's native flow; Supabase creates or links an account on first use.

2. **Token structure** — Successful authentication produces two tokens:
   - **Access token** (JWT, 1-hour lifetime): contains standard identity/session claims and any approved server-validated custom claims. Held in memory only.
   - **Refresh token** (long-lived session token; lifecycle governed by Supabase session policy and revocation rules): used to obtain new access tokens. Stored in secure on-device storage. Never transmitted to the game server.

3. **Session persistence on app launch** — On cold start, the client reads the stored refresh token. If the session is still valid, it exchanges it for a new access token silently before showing the home screen. If the session has expired or been revoked, the user is shown the login screen.

4. **Silent background token refresh** — The Supabase client monitors access token expiry. Within 60 seconds of expiry, it initiates a background refresh. The new token replaces the old one in memory. This process does not block the UI thread and does not interrupt active matches or in-flight requests.

5. **Mid-match expiry** — If an access token expires during an active match, the background refresh fires without interrupting the socket connection. The active match session continues based on the server-validated connection context, and refreshed credentials are used on reconnect or the next privileged API call.

6. **Server-side validation** — The Node.js game server validates JWTs on every privileged request: signature validity, `exp` claim, `iss` claim (must match Supabase project URL), and non-empty `user_id`. The server never trusts a `user_id` from the request body — it always extracts identity from the validated JWT only.

7. **Account uniqueness and OAuth linking** — Each email address maps to exactly one account. If an OAuth login returns an email that already exists on another account, the system does not automatically merge accounts by email alone. Linking requires an authenticated account-link flow or explicit proof of ownership.

8. **Logout** — Logout calls Supabase's sign-out API, which revokes the current session server-side. The client clears all tokens from secure storage. Any active Socket.io connection is closed. The player is returned to the login screen.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| **Unauthenticated** | Cold start with no valid session; explicit logout | Login/registration initiated | Show login/registration screen; no game access |
| **Authenticating** | User submits credentials or OAuth flow begins | Success → Authenticated; failure → Unauthenticated + error | Block UI; show loading indicator; reject duplicate auth attempts |
| **Authenticated** | Successful credential verification; successful token refresh | Near-expiry trigger → Token Refreshing; explicit logout → Unauthenticated; session expired/revoked → Session Expired | Full game access; access token in memory; refresh token in secure storage |
| **Token Refreshing** | Access token within 60s of expiry; 401 from server triggers retry | Refresh success → Authenticated; refresh failure → Session Expired | Game continues normally; new token written to memory on success; no UI change |
| **Session Expired** | Session expired per Supabase policy or revoked server-side | User logs in again → Authenticating | Show session-expired modal; block game access; preserve navigation context where possible |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Player Profile & Persistence | Auth → Profile | Provides `user_id` on auth success. Profile data is keyed by `user_id`; cannot load without an authenticated session. |
| Real-time Transport | Auth → Transport | Client attaches current access token as the Socket.io `auth` parameter on connection. Server validates JWT before accepting; rejects connection on invalid or expired token. |
| Session Manager | Auth → Session Mgr | Server JWT middleware extracts validated `user_id` and passes it to Session Manager for player-to-session binding. |
| API Client | Auth → API Client | API Client reads the current access token from auth state and attaches it as a Bearer token in the Authorization header on every outbound request. |
| IAP System | Auth → IAP | RevenueCat customer ID is set to the Supabase `user_id` on first authenticated session. All purchase attribution uses this ID. |
| Purchase Fulfillment | Auth → Fulfillment | Server validates the JWT before applying any IAP grant. Fulfillment operations are always account-bound and require a valid authenticated session. |
| Ad System | Auth → Ad System | Ad suppression (`has_no_ads` entitlement) is looked up via the authenticated `user_id`. All ad-related logic requires an authenticated session at MVP. |
| Analytics / Telemetry | Auth → Analytics | Authenticated events are tagged with `user_id`. Pre-login events may use a temporary anonymous identifier that can be associated with the account after login if analytics policy supports it. |
| Remote Config | Auth → Remote Config | `user_id` is passed for user-segment config overrides and A/B cohort assignment. |
| Push Notification System | Auth → Push | Device push token is registered against `user_id` on first login on a new device; updated on each subsequent login. |
| Moderation / Reporting | Auth → Moderation | All reports and moderation actions carry the authenticated `user_id` of the reporting player. |

## Formulas

Authentication does not own game-balance or economy formulas. The only derived value this system defines is:

### Token Refresh Threshold

```
refresh_trigger_time = access_token_expiry - REFRESH_LEAD_SECONDS
```

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Access token expiry | `access_token_expiry` | Unix timestamp | now + 3600s | Expiry time embedded in the JWT `exp` claim |
| Refresh lead window | `REFRESH_LEAD_SECONDS` | int (constant) | 30–300 | Seconds before expiry at which the client initiates background refresh. Default: 60. |
| Refresh trigger time | `refresh_trigger_time` | Unix timestamp | — | The wall-clock time at which background refresh begins |

**Output**: When `current_time >= refresh_trigger_time`, the Supabase client initiates a background token refresh.

**Edge case**: If the device clock is skewed significantly ahead of the server clock, the client may refresh tokens earlier than necessary. This is acceptable; over-refreshing is preferable to serving an expired token.

*No other formulas are owned by Authentication. Downstream systems (Player Profile, IAP, Session Manager) define their own logic using `user_id` as a pass-through key.*

## Edge Cases

1. **Registration with email already in use** — If registration is attempted with an email already in use, the system does not create a second account. The client surfaces the provider response and directs the player to log in or recover access.

2. **OAuth flow cancelled mid-redirect** — The OAuth popup or native flow is dismissed before completing. The auth state remains Unauthenticated. The login screen re-displays with no error (cancellation is not an error).

3. **OAuth login returns email matching existing account on a different provider** — If an OAuth login returns an email that matches an existing account registered via a different provider, the system does not automatically merge accounts by email alone unless verified linking rules explicitly allow it. The player is prompted to use the original method or complete an account-link flow.

4. **Refresh token exchange fails due to network error** — If refresh fails due to transient network loss, the client retries with exponential backoff. Until the access token expires, the session remains usable. Once the token is expired, privileged requests fail and the user is moved to Session Expired unless refresh later succeeds.

5. **Server rejects access token with 401** — The client attempts one immediate background refresh. If the refresh succeeds, the original request is retried with the new token. If the refresh fails, the system transitions to Session Expired.

6. **Logout called while a match is active** — Logout is processed immediately: the session is revoked server-side, all tokens are cleared, and the socket connection is closed. The match is treated as a disconnect server-side. Reward eligibility is then determined by Match Flow / Disconnect / Reward rules, not by Authentication.

7. **Access token belonging to a suspended or banned account** — If the server determines the authenticated account is banned, it rejects privileged operations with a 403 and the client is shown a ban notice. The session may remain locally present long enough to render the message, but no gameplay access is allowed.

8. **Two devices logged in simultaneously** — If two devices log in with the same account simultaneously, both sessions may remain valid until session policy or token refresh invalidates one of them. Downstream systems (Session Manager, Matchmaking) enforce one-active-match-at-a-time constraints independently.

9. **`REFRESH_LEAD_SECONDS` set to 0 or negative** — Treated as a misconfiguration. The client falls back to the default value (60 seconds) and logs a configuration error. Token refresh behavior is unaffected.

10. **Secure on-device token storage unreadable or corrupted on app launch** — If secure on-device token storage is unreadable or corrupted on app launch, the client clears local auth state and returns to Unauthenticated instead of attempting partial recovery.

## Dependencies

### Upstream Dependencies (Authentication depends on these)

| System | Type | Dependency |
|--------|------|------------|
| **Supabase Auth** | External service | Issues JWTs; manages session lifecycle; provides OAuth broker for Google and Apple |
| **Secure On-Device Storage** | Platform capability | Stores and retrieves the refresh token across app sessions |
| **Network Layer** | Platform capability | Required for all auth operations; failures trigger the retry/backoff path |

### Downstream Dependents (these depend on Authentication)

| System | Dependency on Auth |
|--------|--------------------|
| **Player Profile & Persistence** | Cannot load or write profile data without a validated `user_id` |
| **Real-time Transport** | Client must attach a valid access token to every Socket.io connection handshake |
| **Session Manager** | Receives validated `user_id` from JWT middleware; cannot bind player to session without it |
| **API Client** | Reads current access token from auth state; attaches it as Bearer token on every outbound request |
| **IAP System** | RevenueCat customer ID is initialized to `user_id` on first authenticated session |
| **Purchase Fulfillment** | All fulfillment operations require a valid authenticated session |
| **Ad System** | Ad suppression entitlement lookup requires an authenticated `user_id` at MVP |
| **Analytics / Telemetry** | Authenticated events are tagged with `user_id`; anonymous pre-login events may be associated after login |
| **Remote Config** | `user_id` passed for user-segment overrides and A/B cohort assignment |
| **Push Notification System** | Device push token registered against `user_id` on login |
| **Moderation / Reporting** | All reports carry the authenticated `user_id` of the reporting player |

### Bidirectionality Note

Every downstream dependent listed above has a corresponding row in its own GDD's Dependencies section referencing Authentication as an upstream dependency. The Interactions table in Section C captures the interface contract for each pairing.

## Tuning Knobs

| Knob | Symbol | Default | Safe Range | Gameplay Effect |
|------|--------|---------|------------|-----------------|
| **Refresh lead window** | `REFRESH_LEAD_SECONDS` | 60 s | 30–300 s | Controls how early before access token expiry the client initiates a background refresh. Lower values risk serving an expired token on slow networks; higher values increase unnecessary refresh calls but improve safety margins. Values ≤ 0 are invalid and fall back to the default. |
| **Refresh retry count** | `REFRESH_MAX_RETRIES` | 3 | 1–5 | Number of attempts the client makes when a token refresh fails due to network error. Fewer retries means faster transition to Session Expired on intermittent networks; more retries increases resilience at the cost of latency before the user is prompted to re-authenticate. |
| **Refresh retry backoff base** | `REFRESH_BACKOFF_BASE_MS` | 1000 ms | 500–5000 ms | The delay before the first retry; subsequent retries multiply this value. Too low risks hammering the auth service under degraded network conditions; too high increases time before the user is notified of a real session failure. |
| **Session policy** | Supabase dashboard setting | Per project config | N/A | Governs session validity, revocation behavior, and project-level auth controls. JWT expiry is configured separately in Supabase auth settings; refresh tokens do not use a simple client-facing TTL and are managed through session/rotation rules. |

> **Implementation note**: Refresh retries (`REFRESH_MAX_RETRIES`, `REFRESH_BACKOFF_BASE_MS`) should be centrally serialized — multiple concurrent 401 responses must not trigger parallel refresh attempts. A single in-flight refresh queue prevents redundant calls and race conditions on token replacement.

## Visual/Audio Requirements

Authentication has no owned visual or audio assets. The requirements below are constraints on other systems.

- The login and registration screens are owned by the UI system. Authentication provides only the state machine and result callbacks.
- No sound effects or music cues are triggered by auth events directly. The Audio system may play ambient or lobby music while the login screen is shown, but this is driven by screen state, not auth state.
- Error states (wrong password, network failure) must be communicated via UI text — no audio feedback is required at MVP.
- The loading indicator shown during the Authenticating state is a UI component responsibility; Authentication signals state transitions only.

## UI Requirements

Authentication defines behavior contracts for UI; it does not specify visual design.

- The UI must support three auth entry points: email/password form, Google OAuth button, Sign in with Apple button.
- On iOS, the Sign in with Apple entry point must use Apple-compliant button styling and placement per Apple's Sign in with Apple design guidance, and must be at least as prominent as other social sign-in options.
- During the Authenticating state, the UI must block duplicate submission — the login form and OAuth buttons must be disabled until the auth attempt resolves.
- The Session Expired modal must offer a single re-login action. It must not be dismissible without re-authenticating (the player cannot return to gameplay in an expired state).
- Error messages must surface clear, player-facing explanations derived from provider responses, but must never expose raw error codes, token details, stack traces, or internal identifiers.

## Cross-References

- `design/gdd/systems-index.md` — Authentication row (Block 1, MVP Foundation layer)
- `design/gdd/api-client.md` — API Client reads current access token from auth state
- `design/gdd/real-time-transport.md` — Socket.io handshake token attachment and server-side JWT validation
- `design/gdd/session-manager.md` — Receives validated `user_id` from JWT middleware
- `design/gdd/player-profile.md` — Keyed by `user_id`; cannot load without authenticated session
- `design/gdd/iap.md` — RevenueCat customer ID initialized to `user_id` on first session
- `design/gdd/purchase-fulfillment.md` — All fulfillment operations require a valid authenticated session
- `design/gdd/analytics-telemetry.md` — Authenticated events tagged with `user_id`

## Acceptance Criteria

Each criterion is written as a pass/fail condition a QA tester can verify.

**Registration & Login**

- [ ] A new email/password account can be created successfully on a clean install, and the player can reach the authenticated home flow without unnecessary delay
- [ ] Attempting to register with an email already in use does not create a second account and the client displays an appropriate message
- [ ] Google OAuth login successfully authenticates the player on first use and returns them to the authenticated home flow
- [ ] Sign in with Apple login successfully authenticates the player on first use and returns them to the authenticated home flow
- [ ] Submitting invalid credentials (wrong password) does not authenticate the user and surfaces an error

**Session Persistence**

- [ ] Closing and reopening the app while a valid session exists returns the player to the home screen without re-entering credentials
- [ ] After a session has been revoked, reopening the app does not restore gameplay access and redirects the player into the unauthenticated flow

**Token Refresh**

- [ ] With the refresh lead window set to 60 s, a background refresh fires before the access token expires, with no UI interruption
- [ ] If the device is taken offline during refresh, the session remains usable until the access token expires; once expired, the Session Expired modal appears
- [ ] A token-related 401 response triggers one refresh attempt and, if refresh succeeds, retries the original privileged request once

**Logout**

- [ ] Tapping logout revokes the session server-side, clears all local tokens, and returns the player to the login screen
- [ ] After logout, returning to the home screen (e.g., via back gesture) is not possible — the player is blocked at the login screen

**Error & Edge Cases**

- [ ] Cancelling an OAuth flow mid-redirect returns the player to the login screen with no error shown
- [ ] With `REFRESH_LEAD_SECONDS` set to 0, the client falls back to 60 s and a config error is logged
- [ ] If secure on-device auth state is corrupted or unreadable on launch, the app clears local auth state safely and enters the unauthenticated flow without crashing

**Server Validation**

- [ ] A request sent with a forged or expired JWT is rejected by the server with an authentication/authorization failure and does not execute the privileged operation
- [ ] The server never processes a `user_id` from the request body — identity is always extracted from the validated JWT

## Open Questions

1. **Account-link flow design** — The authenticated account-link flow (for linking a second OAuth provider to an existing account) is referenced in Edge Cases but not yet designed. Where does this live — as a sub-flow within Authentication, or as a separate Profile/Settings feature?

2. **Anonymous / guest play** — At MVP, all game access requires authentication. If a future design decision adds guest or anonymous play, how does the auth system accommodate it? Flag for consideration before Alpha.

3. **Email verification UX** — If Confirm Email is enabled in Supabase, the player must verify before first sign-in. The waiting state and resend-verification flow are not yet designed.

4. **Session policy configuration** — Refresh token lifetime and rotation rules are Supabase project settings. The specific values (e.g., rotate on use, inactivity timeout) have not been decided. Needs a decision before server configuration at MVP build.
