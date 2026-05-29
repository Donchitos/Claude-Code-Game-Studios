# Epic: Main Menu & Navigation

> **Layer**: Presentation
> **GDD**: design/gdd/main-menu.md
> **Architecture Module**: Main Menu (Presentation Layer — React Native Expo Router)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories main-menu`

## Overview

Main Menu is the post-auth home screen and navigation hub. It shows the player's display name, coin balance, diamond balance, level, and current profile photo. Navigation leads to: Play (→ Lobby), Collection (→ Character/Deck Select pre-match config), Shop, Battle Pass, and Settings. The screen subscribes to `ProfileStore` (Zustand) and reflects economy changes via `profile:refresh` in real time. It handles the initial `fetchProfile()` on auth success and shows a loading state while the profile loads.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0006: Client State Management | ProfileStore provides profile data; invalidated by profile:refresh | LOW |
| ADR-0004: Authentication Architecture | Screen only renders after auth session resolves | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0006 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/main-menu.md` verified
- Coin and diamond balances update within 500ms of `profile:refresh` (manual QA)
- Navigation to all 5 destinations works on iOS and Android (manual walkthrough)
- Safe area insets handled correctly (notch + home indicator)
- Loading state shown while profile fetches; no flash of stale data

## Next Step

Run `/create-stories main-menu` to break this epic into implementable stories.
