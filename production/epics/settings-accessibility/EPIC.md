# Epic: Settings & Accessibility

> **Layer**: Presentation
> **GDD**: design/gdd/settings-accessibility.md
> **Architecture Module**: Settings & Accessibility (Presentation)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories settings-accessibility`

## Overview

Settings & Accessibility provides player-configurable options: display name, push notification preferences, sound/music toggles, colorblind mode, touch control layout options, and account management (link account, sign out). All settings are persisted to `player_profiles.settings` via `PATCH /v1/profile/settings`. Push notification toggle updates `notifications_enabled` server-side. Colorblind mode and UI scale are stored locally and applied at app level. Account sign-out clears the JWT from SecureStore, invalidates all stores, and navigates to the login screen.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0006: Client State Management | ProfileStore provides and persists settings | LOW |
| ADR-0004: Authentication Architecture | Sign-out clears JWT from SecureStore; session invalidated | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0006 ✅, ADR-0004 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/settings-accessibility.md` verified
- Push notification toggle persists across app restarts
- Colorblind mode applies to match HUD color coding
- Sign-out clears all local state; next app open shows login screen
- Display name change reflected in Main Menu within 500ms (profile:refresh)
- Settings screen passes basic accessibility audit (font scale, touch target sizes)

## Next Step

Run `/create-stories settings-accessibility` to break this epic into implementable stories.
