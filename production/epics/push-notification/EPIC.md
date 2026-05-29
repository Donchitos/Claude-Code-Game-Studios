# Epic: Push Notification System

> **Layer**: Feature (Alpha)
> **GDD**: design/gdd/push-notification.md
> **Architecture Module**: Push Notification Service
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories push-notification`

## Overview

Push Notification System collects Expo push tokens from the client after auth, stores them in `player_profiles.push_token`, and sends server-initiated push notifications via the Expo Push API. Notification types include match reminders, event alerts, and quest resets. The `notifications_enabled` flag in `player_profiles` is respected — no push sent to opted-out players. `DeviceNotRegisteredError` from Expo Push API clears the stored token. iOS requires explicit user permission; Android auto-grants at install time.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0014: Push Notification Integration | expo-notifications token collection; Expo Push API; notification_enabled check | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0014 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/push-notification.md` verified
- Push token stored in `player_profiles` after auth on physical device (iOS + Android)
- Notification received within 30s of server send call (manual QA on device)
- No notification sent when `notifications_enabled = false` (integration test)
- Stale token → server clears `push_token` on next `DeviceNotRegisteredError`

## Next Step

Run `/create-stories push-notification` to break this epic into implementable stories.
