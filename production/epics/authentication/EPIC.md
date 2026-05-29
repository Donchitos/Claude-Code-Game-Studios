# Epic: Authentication

> **Layer**: Foundation
> **GDD**: design/gdd/authentication.md
> **Architecture Module**: JWT Validator + REST Auth Routes + Supabase Auth Client
> **Status**: Ready
> **Stories**: 6 stories created

## Overview

Authentication covers the full identity lifecycle for BRAWLZONE players: email/password sign-up and sign-in, anonymous guest account creation with a migration path to permanent accounts, JWT issuance by Supabase Auth, and server-side RS256 validation on every HTTP request and Socket.io connection. The client stores the JWT in Expo SecureStore and injects it automatically via the API Client interceptor. Unauthenticated socket connections are terminated after 5 seconds. This epic is the security foundation that all other systems depend on.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: Authentication Architecture | Supabase Auth with RS256 JWT; local validation (no Supabase round-trip per request); guest accounts via anonymous sign-in | LOW |
| ADR-0001: Client-Server Architecture | JWT Validator placed in Server Foundation layer; all routes protected | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0004 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/authentication.md` are verified
- All Logic stories have passing unit tests in `tests/unit/authentication/`
- Valid JWT → 200 on all protected routes
- Invalid/expired JWT → 401 on HTTP; `auth_error` on socket
- Unauthenticated socket disconnected within 5 seconds
- Guest → permanent account migration preserves userId + all entitlements

## Next Step

Run `/create-stories authentication` to break this epic into implementable stories.
