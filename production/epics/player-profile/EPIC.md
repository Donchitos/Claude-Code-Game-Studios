# Epic: Player Profile & Persistence

> **Layer**: Foundation
> **GDD**: design/gdd/player-profile.md
> **Architecture Module**: Player Profile Service (server) + Profile Store (client)
> **Status**: Ready
> **Stories**: 9 stories created

## Overview

Player Profile & Persistence covers the 26-field `player_profiles` table, the Redis profile cache (TTL 60s), the `GET /v1/profile` and `PATCH /v1/profile/settings` endpoints, and the `profile:refresh` Socket.io push mechanism that is the single client cache invalidation trigger. The client-side Profile Store (Zustand) reads from this and exposes `useProfile()` to all screens. No screen polls for profile data; all updates arrive via `profile:refresh`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0005: Database Architecture | PostgreSQL player_profiles table; Redis profile cache (TTL 60s); profile:refresh on write | LOW |
| ADR-0006: Client State Management | ProfileStore (Zustand); invalidated by profile:refresh; fetchProfile on init | LOW |
| ADR-0004: Authentication Architecture | userId (Supabase UUID) is the primary key | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0005 ✅, ADR-0006 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/player-profile.md` verified
- Profile read (Redis warm): ≤1ms p99
- Profile read (Redis cold): ≤20ms p99
- `profile:refresh` → UI shows updated data within 500ms
- No profile polling anywhere in client codebase (code review gate)

## Next Step

Run `/create-stories player-profile` to break this epic into implementable stories.
