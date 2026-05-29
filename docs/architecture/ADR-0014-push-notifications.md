# ADR-0014: Push Notification Integration (Expo Notifications)

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director

## Summary

BRAWLZONE uses Expo Notifications (`expo-notifications`) for push notifications on iOS and Android. Push tokens are collected on the client and stored server-side. The server sends notifications via the Expo Push API for match reminders, event alerts, and quest completions. This ADR defines the token lifecycle, server-side sending, and opt-in flow.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | Networking / Core |
| **Knowledge Risk** | LOW — Expo Notifications is within training data |
| **References Consulted** | `design/gdd/push-notification.md`, `docs/engine-reference/react-native/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm `expo-notifications` API for push token retrieval hasn't changed post-May-2025 (low risk) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0004 (userId for token storage) |
| **Enables** | Push notification implementation |
| **Blocks** | Push Notification system implementation |
| **Ordering Note** | Deferrable to Alpha milestone — not required for Vertical Slice |

## Context

### Problem Statement

Players who leave the app need to be re-engaged via push notifications (daily quest resets, match reminders, limited-time events). Push tokens must be collected, stored, and used server-side — never sent from the client directly.

### Constraints

- Push token collection requires user permission on iOS; Android requests at install time
- Expo Notifications unifies APNs (iOS) and FCM (Android) under a single API
- Push tokens expire and must be refreshed on re-registration
- Players can opt out of notifications; `notifications_enabled` flag in `player_profiles`

### Requirements

- Collect push token after auth; store in `player_profiles.push_token`
- Server sends push via Expo Push API: `https://exp.host/--/api/v2/push/send`
- Notification types: `match_reminder`, `event_start`, `quest_reset`, `friend_invite`
- Respect `notifications_enabled = false` — never send if opted out

## Decision

Use `expo-notifications` on the client for token collection. Store token in `player_profiles`. Server calls Expo Push API directly (HTTP POST) when a notification event occurs.

### Architecture

```
CLIENT (after auth):
  const token = await Notifications.getExpoPushTokenAsync({ projectId: EXPO_PROJECT_ID });
  await apiClient.post('/v1/profile/push-token', { token: token.data });

SERVER:
  PATCH /v1/profile/push-token  { token: string }
  → UPDATE player_profiles SET push_token = $token WHERE user_id = $userId

SERVER (notification send):
  PushNotificationService.send(userId, type, data):
    profile = await getProfile(userId)
    if !profile.notifications_enabled || !profile.push_token: return
    await fetch('https://exp.host/--/api/v2/push/send', {
      method: 'POST',
      body: JSON.stringify({
        to: profile.push_token,
        title: NOTIFICATION_TEMPLATES[type].title,
        body: NOTIFICATION_TEMPLATES[type].body(data),
        data: { type, ...data },
      })
    })
```

### Key Interfaces

```typescript
interface IPushNotificationService {
  send(userId: string, type: NotificationType, data?: Record<string, unknown>): Promise<void>;
  // No-ops silently if notifications_enabled=false or push_token is null
}

type NotificationType = 'match_reminder' | 'event_start' | 'quest_reset' | 'friend_invite';
```

### Implementation Guidelines

- Request notification permission before calling `getExpoPushTokenAsync`; if denied, skip token collection gracefully
- Expo push tokens are strings starting with `ExponentPushToken[...]`; validate format before storing
- Expo Push API returns a ticket per notification; check for errors in the ticket (`status: 'error'`) and log them
- If `DeviceNotRegisteredError` received in ticket: clear `push_token` from `player_profiles`

## Alternatives Considered

### Alternative 1: Direct APNs + FCM Integration

- **Description**: Server sends to APNs and FCM directly using platform-specific SDKs.
- **Pros**: No Expo dependency; lower cost at scale.
- **Cons**: Two separate server-side integrations; certificate management for APNs.
- **Rejection Reason**: Expo Notifications abstracts both platforms; engineering cost advantage clear at MVP scale.

## Consequences

### Positive

- Single API for iOS and Android push
- Expo manages APNs/FCM credentials via project settings

### Negative

- Expo Push API is a vendor-managed service; outages affect notification delivery
- Expo push tokens are specific to the Expo managed workflow; ejecting to bare workflow requires migration

### Neutral

- Notification delivery is best-effort; no delivery confirmation required for MVP

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Token expiry (stale push_token) | Medium | Low | Clear token on DeviceNotRegisteredError; re-collect on next app open |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Token registration (client) | — | On app start, async | — |
| Notification send (server) | — | ≤500ms (Expo API round-trip) | — |

## Migration Plan

New project.

**Rollback plan**: Replace Expo Push API with direct FCM/APNs — change `PushNotificationService.send()` implementation only; token format changes required (FCM token ≠ Expo push token).

## Validation Criteria

- [ ] Push token stored in `player_profiles` after auth on physical device
- [ ] Notification received within 30s of server send call
- [ ] No notification sent when `notifications_enabled = false`
- [ ] Stale token → server clears `push_token` on next `DeviceNotRegisteredError`

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/push-notification.md` | Push | Expo Notifications for iOS + Android | `expo-notifications` + Expo Push API defined |
| `design/gdd/push-notification.md` | Push | Respect opt-out | `notifications_enabled` flag check before send |

## Related

- ADR-0004: `userId` used for token storage in `player_profiles`
- ADR-0005: `push_token` column in `player_profiles` table
