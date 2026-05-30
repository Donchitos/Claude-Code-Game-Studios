# Push Notification System — Game Design Document

> **System**: Push Notification System
> **Priority**: Alpha
> **Layer**: Feature
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-28
> **Last Updated**: 2026-05-28

---

## Table of Contents

1. [Overview](#1-overview)
2. [Player Fantasy](#2-player-fantasy)
3. [Detailed Rules](#3-detailed-rules)
   - 3.1 [Notification Categories](#31-notification-categories)
   - 3.2 [Per-Category Opt-In](#32-per-category-opt-in)
   - 3.3 [Device Token Registration Flow](#33-device-token-registration-flow)
   - 3.4 [Token Refresh and Rotation](#34-token-refresh-and-rotation)
   - 3.5 [Notification Payload Structure](#35-notification-payload-structure)
   - 3.6 [Deep Link Handling](#36-deep-link-handling)
   - 3.7 [Foreground Suppression](#37-foreground-suppression)
   - 3.8 [Rate Limits Per Player Per Category](#38-rate-limits-per-player-per-category)
   - 3.9 [GDPR and Consent](#39-gdpr-and-consent)
   - 3.10 [Server-Side Send Architecture](#310-server-side-send-architecture)
4. [Formulas](#4-formulas)
5. [Edge Cases](#5-edge-cases)
6. [Dependencies](#6-dependencies)
7. [Tuning Knobs](#7-tuning-knobs)
8. [Acceptance Criteria](#8-acceptance-criteria)

---

## 1. Overview

The Push Notification System delivers timely, relevant, and consent-gated push notifications to BRAWLZONE players on iOS and Android via Expo's managed push service (which routes to APNs on iOS and FCM on Android). The system owns the complete lifecycle of a push notification: OS permission prompting, device token registration and rotation, per-category player preference storage (server-synced), server-side send logic (Node.js → Expo Push API), payload structure, deep link routing on tap, foreground suppression during active matches, and per-player rate limiting to prevent spam. Five notification categories are defined — `match_found`, `daily_reset`, `event_start`, `friend_activity`, and `promotional` — each with independent opt-in defaults and trigger conditions. All sends originate server-side; the client is purely a receiver and preference manager. No notification is ever sent before the player has explicitly granted OS-level push permission, and push opt-in is a Tier 1 consent signal as defined in the Analytics / Telemetry GDD.

---

## 2. Player Fantasy

A great push notification feels like a tap on the shoulder from a friend who happens to know exactly when you want to play — not an advertiser hammering your lock screen at random. The push notification system exists to serve one specific player feeling: **"The game found me at the right moment."**

When a player joins the matchmaking queue and then tabs away to check messages, they should not have to keep returning to BRAWLZONE to see if a match was found. The notification arrives the instant a game is ready, the player taps it, and they are already in the countdown. Zero wasted seconds. Zero missed matches.

When the daily quest reset fires, a player who has been away for 18 hours gets a quiet reminder that fresh objectives are waiting — not a guilt-trip, not a streaks-will-break warning, just an honest "new quests are here." When a limited-time event goes live, the notification feels like a friend texting "it started," not a promotional email.

The system must never overstep. A player who disabled promotional notifications should never see one. A player in an active match should never be interrupted by a notification. A player who has not opened the app in 30 days should not be getting daily pings. The measure of success is not volume sent — it is the ratio of taps to sends: a high tap-through rate means every notification was worth the player's attention.

**User Story:** As a player who backgrounded the app while waiting in queue, I want to receive a push notification the instant my match is found so that I never miss a match or have to re-queue.

---

## 3. Detailed Rules

### 3.1 Notification Categories

Five categories are defined. Each category has a unique `categoryId`, a trigger condition, a default opt-in state, and a per-player rate limit (enforced server-side). Every outgoing notification belongs to exactly one category.

#### 3.1.1 `match_found`

| Field | Value |
|-------|-------|
| Category ID | `match_found` |
| Default opt-in | **ON** |
| Trigger | Matchmaking Engine has assembled a valid match for the player's pending queue entry and the player is no longer foregrounded (confirmed via `foreground_status` in the player presence record — see §3.7) |
| Condition for send | Player has an active queue entry, the match was found, and the player's app is in background or terminated |
| Rate limit | Maximum 3 per hour per player (prevents spam if player re-queues repeatedly without accepting) |
| Priority | High (APNs critical priority; FCM `priority: high`) — must arrive and wake device |
| TTL | 120 seconds — if undelivered by the time the match countdown expires, the notification is meaningless and should be dropped |

**Exact trigger sequence:**
1. Matchmaking Engine confirms a full lobby.
2. Server checks `player_presence.foreground` for each player.
3. For each player where `foreground = false`: enqueue a `match_found` push send job.
4. Push send job checks: (a) player has `push_enabled = true`, (b) category `match_found` is enabled for that player, (c) OS permission token exists, (d) rate limit not exceeded.
5. If all checks pass: send immediately via Expo Push API.

#### 3.1.2 `daily_reset`

| Field | Value |
|-------|-------|
| Category ID | `daily_reset` |
| Default opt-in | **OFF** |
| Trigger | Server-side scheduled job fires daily at the reset time (see §4.1) |
| Condition for send | Player's account has at least one daily quest that was incomplete at reset time AND player has been active in the past `DAILY_RESET_ACTIVE_DAYS_THRESHOLD` days (default: 7) |
| Rate limit | Maximum 1 per 23 hours per player (prevents double-fire on DST transitions or job retries) |
| Priority | Normal (APNs `apns-priority: 5`; FCM `priority: normal`) |
| TTL | 18 hours — if undelivered after 18 hours, the notification is stale |

**Activity gate:** A player inactive for more than `DAILY_RESET_ACTIVE_DAYS_THRESHOLD` days (default: 7) does not receive `daily_reset` notifications, even if opted in. This prevents re-engagement spam for churned players (dedicated re-engagement campaigns are handled via `promotional`).

#### 3.1.3 `event_start`

| Field | Value |
|-------|-------|
| Category ID | `event_start` |
| Default opt-in | **ON** |
| Trigger | A limited-time event goes live (Remote Config key `gameMode.eventModeActive` flips to `true` on the server, or a scheduled event job fires) |
| Condition for send | Player has been active in the past `EVENT_START_ACTIVE_DAYS_THRESHOLD` days (default: 14) |
| Rate limit | Maximum 2 per 24 hours per player (a single event may produce multiple notifications only if two distinct events start in the same day, which is an exceptional operational case) |
| Priority | Normal |
| TTL | Duration of the event or 48 hours, whichever is less |

**Note:** The server event dispatch system determines when `event_start` jobs are queued. If the Remote Config key is updated, the server webhook fires immediately; if a scheduled event, the cron job fires at the scheduled start time. The push system is a downstream consumer of either trigger — it does not initiate event launches.

#### 3.1.4 `friend_activity`

| Field | Value |
|-------|-------|
| Category ID | `friend_activity` |
| Default opt-in | **OFF** |
| Trigger | A social trigger occurs: friend comes online for the first time in `FRIEND_ACTIVITY_OFFLINE_THRESHOLD_HOURS` hours (default: 24), or friend sends a party invite |
| Condition for send | Social feature flag `featureFlags.socialEnabled` must be `true` in Remote Config; player must have opted in to this category |
| Rate limit | Maximum 5 per hour per player across all friends (prevents notification storms when multiple friends log in simultaneously) |
| Priority | Normal |
| TTL | 30 minutes — friend activity is time-sensitive and rapidly becomes irrelevant |
| MVP status | **Disabled at MVP.** `friend_activity` category sends are gated by `featureFlags.socialEnabled = false`. The category exists in the schema, preferences can be saved server-side, but no sends are dispatched until the social system is implemented |

#### 3.1.5 `promotional`

| Field | Value |
|-------|-------|
| Category ID | `promotional` |
| Default opt-in | **OFF** |
| Trigger | Manually dispatched by the live-ops team via an internal operator dashboard job; or triggered by a server-side campaign scheduler |
| Condition for send | Player has been active in the past `PROMO_ACTIVE_DAYS_THRESHOLD` days (default: 30) AND rate limit not exceeded |
| Rate limit | Maximum 1 per `PROMO_MIN_INTERVAL_HOURS` hours per player (default: 72h — see §4.2) |
| Priority | Normal |
| TTL | 24 hours |

**Promotional notifications are the highest-regulation category.** Default is OFF. The rate limit is strictly enforced server-side before any send is attempted — the operator dashboard cannot override the rate limit without changing the Remote Config key.

---

### 3.2 Per-Category Opt-In

Each player has a server-side record storing their notification preferences per category. The client's Settings screen (see Settings / Accessibility GDD §3.6) exposes category toggles. Preference writes are not local-only — they are server-synced immediately via `PATCH /v1/players/me/notification-preferences`.

**Preference record schema (server-side, PostgreSQL):**

```typescript
interface NotificationPreferences {
  userId: string;                    // FK to players table
  pushEnabled: boolean;              // Master push toggle (OS permission granted + player master toggle)
  categories: {
    match_found: boolean;            // default: true
    daily_reset: boolean;            // default: false
    event_start: boolean;            // default: true
    friend_activity: boolean;        // default: false
    promotional: boolean;            // default: false
  };
  updatedAt: string;                 // ISO 8601 UTC
}
```

**Default opt-in states applied at account creation:**

| Category | Default |
|----------|---------|
| `match_found` | ON |
| `daily_reset` | OFF |
| `event_start` | ON |
| `friend_activity` | OFF |
| `promotional` | OFF |

**Client-side toggle behavior:**
1. Player flips a category toggle in Settings → Notifications.
2. Client optimistically updates the local UI.
3. Client issues `PATCH /v1/players/me/notification-preferences` with the updated preferences object via the API Client.
4. On HTTP 200: preference is committed; UI remains in the new state.
5. On HTTP 4xx / 5xx or network failure: UI reverts to previous state; toast: *"Could not update notification settings. Please try again."*

**Important:** The master `pushEnabled` flag is derived from AND of the OS-level permission state and the player's master in-app toggle. If the player has denied OS permission, `pushEnabled` is always `false` regardless of in-app toggle state (see §3.9).

---

### 3.3 Device Token Registration Flow

Device token registration maps a player's `userId` to their Expo push token. The flow uses `expo-notifications` on the client and a dedicated server endpoint.

**Step-by-step registration sequence:**

```
Client                                    Server
  │                                          │
  │── 1. Request OS permission ──────────────│
  │   (expo-notifications.requestPermissionsAsync)
  │                                          │
  │── 2. Get Expo push token ────────────────│
  │   (expo-notifications.getExpoPushTokenAsync)
  │   Returns: "ExponentPushToken[xxxxxx]"   │
  │                                          │
  │── 3. POST /v1/players/me/device-token ──►│
  │   Body: { token, platform, appVersion }  │
  │                                          │
  │                          4. Upsert token │
  │                             in DB ───────│
  │                                          │
  │◄── 5. HTTP 200 OK ──────────────────────│
```

**Step 1 — OS permission request:**
- Called once per app lifecycle after the player completes onboarding (Tutorial / Onboarding GDD §3.x defines the exact moment — Push system defers to Onboarding's permission prompt timing decision).
- If permission is `denied`: set `pushEnabled = false` on the local preference record; do not proceed to step 2; do not show another permission prompt in the same session.
- If permission is `granted` or `undetermined` → proceed.
- If `expo-notifications.getPermissionsAsync()` returns `granted` on a subsequent cold start, skip the permission prompt and proceed directly to token fetch.

**Step 2 — Token fetch:**
- Call `expo-notifications.getExpoPushTokenAsync({ projectId: EXPO_PROJECT_ID })`.
- `EXPO_PROJECT_ID` is read from the Expo public manifest (`process.env.EXPO_PUBLIC_EXPO_PROJECT_ID`). This is required for bare/managed workflow token generation.
- Token format: `ExponentPushToken[<alphanumeric string>]`.
- If the token fetch throws (e.g., device has no internet): log a WARN; schedule a retry on next app foreground (up to `TOKEN_REGISTRATION_MAX_RETRIES` attempts — default: 3).

**Step 3 — Server registration:**
- Send `POST /v1/players/me/device-token` via the API Client (JWT auto-attached).
- Request body:

```typescript
interface DeviceTokenRegistrationRequest {
  token: string;          // Expo push token
  platform: 'ios' | 'android';
  appVersion: string;     // Expo manifest version
  deviceId: string;       // Deterministic device ID (see note below)
}
```

- `deviceId` is derived from `expo-device.osBuildId` (iOS) or `expo-device.modelId` + `expo-device.osBuildId` (Android), hashed via SHA-256. It is a stable, non-PII device identifier used to associate multiple tokens per player (tablet + phone) and to detect token rotation.

**Step 4 — Server upsert:**
- Server performs an `UPSERT` into the `device_tokens` table on `(userId, deviceId)`. If a record exists for that `(userId, deviceId)` pair, the `token` and `updatedAt` are updated. If not, a new row is inserted.
- Multiple rows per `userId` are allowed (one per device).

**Database schema (`device_tokens` table):**

```sql
CREATE TABLE device_tokens (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  device_id     VARCHAR(64) NOT NULL,      -- SHA-256 of device identifiers
  token         VARCHAR(256) NOT NULL,     -- Expo push token
  platform      VARCHAR(8) NOT NULL,       -- 'ios' | 'android'
  app_version   VARCHAR(32) NOT NULL,
  is_active     BOOLEAN NOT NULL DEFAULT true,
  registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, device_id)
);
```

**Step 5 — Registration on every launch:**
Token registration is attempted on every authenticated cold start, not just first-time installs. This is intentional: tokens can change (APNs rotation, app reinstall), and re-registering on each launch ensures the server always has the current token. The server upsert is idempotent — sending the same token again is a no-op.

---

### 3.4 Token Refresh and Rotation

Push tokens are not permanent. APNs silently rotates tokens; FCM tokens can expire or change on reinstall.

**Client-side rotation detection:**
- On each app foreground, the client calls `expo-notifications.getExpoPushTokenAsync()` and compares the returned token to the locally stored token (in AsyncStorage under key `push.deviceToken`).
- If the token has changed: immediately `POST /v1/players/me/device-token` with the new token (same flow as §3.3 Step 3).
- If the token is unchanged: skip the API call (no unnecessary network traffic).
- Check interval: every app foreground, but no more frequently than `TOKEN_CHECK_INTERVAL_MS` (default: 3 600 000 ms = 1 hour). Store `push.lastTokenCheck` timestamp in AsyncStorage; if `now - lastTokenCheck < TOKEN_CHECK_INTERVAL_MS`, skip.

**Server-side invalidation handling:**
- When the Expo Push API returns a delivery receipt with error `DeviceNotRegistered` (HTTP 410 equivalent — the token is no longer valid on the platform), the server immediately sets `device_tokens.is_active = false` for that token row.
- Inactive tokens are excluded from all future send queries.
- Inactive tokens are not deleted (retained for 30 days for audit purposes, then purged by a nightly cleanup job).
- A `WARN` is logged with `userId` and `platform` (never the raw token in logs — PII policy, see §3.10).

**APNs token invalidation on iOS:**
- APNs silently rotates the device token without notification when certain system events occur (OS update, app reinstall). The client-side rotation detection (above) handles this: on the next app foreground after the rotation, the new token is registered.
- If a send attempt fails with `DeviceNotRegistered` for an iOS device, the server marks the token inactive and waits for the client to re-register. No retry of the failed send is attempted.

---

### 3.5 Notification Payload Structure

All push notifications sent through Expo's push service use a standardized payload. The `data` object is always present and drives deep link routing on the client.

**TypeScript interface (server-side send model):**

```typescript
interface BrawlzonePushMessage {
  to: string;                          // Expo push token
  title: string;                       // Notification title (max 65 chars)
  body: string;                        // Notification body text (max 178 chars)
  data: BrawlzonePushData;             // Structured data payload
  sound?: 'default' | null;           // 'default' for audible; null for silent
  badge?: number;                      // iOS badge count (optional)
  priority?: 'default' | 'normal' | 'high';
  ttlSeconds?: number;                 // Per-category TTL (see §3.1)
  channelId?: string;                  // Android notification channel ID
  categoryIdentifier?: string;         // iOS category for interactive notifications (future)
}

interface BrawlzonePushData {
  category: NotificationCategory;      // 'match_found' | 'daily_reset' | 'event_start' | 'friend_activity' | 'promotional'
  deepLink: string;                    // Deep link URI (see §3.6)
  notificationId: string;             // UUID — server-generated; used for receipt tracking
  sendTimestamp: string;              // ISO 8601 UTC — server send time
  // Category-specific fields:
  matchId?: string;                    // match_found: the match UUID to join
  gameMode?: string;                   // match_found: 'duel_1v1' | 'squad_3v3' | 'ffa_8'
  eventId?: string;                    // event_start: the event mode ID
  campaignId?: string;                 // promotional: operator campaign identifier
}

type NotificationCategory =
  | 'match_found'
  | 'daily_reset'
  | 'event_start'
  | 'friend_activity'
  | 'promotional';
```

**Per-category payload examples:**

`match_found`:
```json
{
  "title": "Match Found!",
  "body": "Your 1v1 Duel is ready. Get in there!",
  "data": {
    "category": "match_found",
    "deepLink": "brawlzone://match/join?matchId=abc-123&mode=duel_1v1",
    "notificationId": "uuid-v4",
    "sendTimestamp": "2026-05-28T14:32:00Z",
    "matchId": "abc-123",
    "gameMode": "duel_1v1"
  },
  "priority": "high",
  "ttlSeconds": 120,
  "sound": "default"
}
```

`daily_reset`:
```json
{
  "title": "New Daily Quests",
  "body": "Fresh challenges are waiting. Come earn your rewards.",
  "data": {
    "category": "daily_reset",
    "deepLink": "brawlzone://quests",
    "notificationId": "uuid-v4",
    "sendTimestamp": "2026-05-28T00:00:05Z"
  },
  "priority": "normal",
  "ttlSeconds": 64800,
  "sound": "default"
}
```

`event_start`:
```json
{
  "title": "Limited Event: Blitz Mode is LIVE",
  "body": "A new limited-time mode just dropped. Play now before it ends!",
  "data": {
    "category": "event_start",
    "deepLink": "brawlzone://play?eventMode=blitz",
    "notificationId": "uuid-v4",
    "sendTimestamp": "2026-05-28T18:00:00Z",
    "eventId": "blitz"
  },
  "priority": "normal",
  "ttlSeconds": 172800,
  "sound": "default"
}
```

`promotional`:
```json
{
  "title": "Double XP Weekend Starts Now",
  "body": "Earn twice the XP on every match this weekend only.",
  "data": {
    "category": "promotional",
    "deepLink": "brawlzone://home",
    "notificationId": "uuid-v4",
    "sendTimestamp": "2026-05-28T09:00:00Z",
    "campaignId": "double-xp-may-2026"
  },
  "priority": "normal",
  "ttlSeconds": 86400,
  "sound": "default"
}
```

**Character limits:** `title` is capped at 65 characters; `body` at 178 characters. The server truncates with `…` if content exceeds these limits before sending. These limits are conservative maximums safe for both iOS and Android lock screen display.

**Android notification channel:** All notifications are sent with `channelId: "brawlzone_default"`. The Android channel is registered on first app launch via `expo-notifications.setNotificationChannelAsync()` with importance level `IMPORTANCE_HIGH` for `match_found` and `IMPORTANCE_DEFAULT` for all other categories.

---

### 3.6 Deep Link Handling

When a player taps a push notification, the app receives the notification's `data.deepLink` value and routes to the appropriate screen. The deep link scheme is `brawlzone://`.

**Supported deep link routes:**

| Deep Link URI | Destination Screen | Conditions |
|--------------|-------------------|------------|
| `brawlzone://match/join?matchId=<id>&mode=<mode>` | Match lobby / countdown for `matchId` | Match must still be in lobby state; if expired, route to Main Menu with toast |
| `brawlzone://quests` | Quests / Mission screen | Always navigable |
| `brawlzone://play?eventMode=<eventId>` | Play screen with event mode pre-selected | Event must still be active; if ended, route to Play screen with default mode |
| `brawlzone://home` | Main Menu (home tab) | Always navigable; fallback for `promotional` |
| `brawlzone://social/friends` | Friends list screen | Only when `featureFlags.socialEnabled = true`; otherwise route to Main Menu |

**Handling flow on notification tap:**

1. `expo-notifications.addNotificationResponseReceivedListener` fires on notification tap (works whether app was backgrounded or terminated).
2. Listener extracts `data.deepLink` from the notification response.
3. The client validates the deep link scheme (`brawlzone://`). Unknown schemes are discarded; a WARN is logged with `notificationId`.
4. Navigation router attempts to navigate to the resolved screen.
5. If the player is not authenticated at the time of tap (session expired): complete authentication first, then replay the deep link navigation.
6. If the target resource is no longer available (match expired, event ended): navigate to the fallback route (defined in the table above) and show an inline toast explaining why (e.g., *"That match is no longer available."*).

**Cold-start deep link:** If the app was terminated and the player taps the notification, `expo-notifications.getLastNotificationResponseAsync()` is called during the app initialization phase (before Main Menu renders) to check for a pending notification tap. If a pending response exists, the deep link is processed after authentication completes.

---

### 3.7 Foreground Suppression

Push notifications must not interrupt a player who is actively in a match.

**Definition of "active match":** The player has an active entry in the client-side match session state (Match Flow GDD) — i.e., the `MatchContext` is mounted and `matchPhase` is not `ended` or `null`.

**Client-side foreground handler:**
- `expo-notifications.addNotificationReceivedListener` fires when a notification arrives while the app is foregrounded.
- The listener checks `MatchContext.matchPhase`:
  - If `matchPhase` is active (any value other than `null` or `ended`): **suppress** the notification entirely. Do not show a banner, do not play a sound, do not show an in-app notification UI. Log a DEBUG entry with `notificationId` and `category`.
  - If `matchPhase` is `null` or `ended` (in menus): show the notification as an in-app banner using `expo-notifications` local notification presentation (title + body displayed at the top of screen for 4 seconds). The banner is tappable and triggers the same deep link routing as §3.6.

**Server-side foreground avoidance (best-effort):**
The server maintains a `player_presence` record with a `foreground` boolean, updated by the client via the Real-time Transport (Socket.io) on `app-foregrounded` and `app-backgrounded` events. Before sending any non-`match_found` push notification, the server checks `player_presence.foreground`:
- If `foreground = true` and `player_presence.in_match = true`: skip the send entirely for that player and log a DEBUG entry.
- If `foreground = true` but `player_presence.in_match = false`: send normally (player is in menus; client-side handler will show an in-app banner).
- If `foreground` status is stale (last updated more than `PRESENCE_STALE_THRESHOLD_SEC` seconds ago — default: 30s): treat as unknown and send anyway.

**`match_found` is exempt from server-side foreground suppression** because by definition the player is in the queue (not in an active match) and the notification's purpose is to return them to the app.

---

### 3.8 Rate Limits Per Player Per Category

Rate limits are enforced server-side, evaluated before each send attempt. They are stored in Redis with TTL-based rolling windows.

**Rate limit table:**

| Category | Window | Max Sends | Redis Key Pattern |
|----------|--------|-----------|-------------------|
| `match_found` | 1 hour | 3 | `ratelimit:push:match_found:<userId>` |
| `daily_reset` | 23 hours | 1 | `ratelimit:push:daily_reset:<userId>` |
| `event_start` | 24 hours | 2 | `ratelimit:push:event_start:<userId>` |
| `friend_activity` | 1 hour | 5 (across all friends) | `ratelimit:push:friend_activity:<userId>` |
| `promotional` | 72 hours | 1 | `ratelimit:push:promotional:<userId>` |

**Enforcement logic (per send attempt):**
```
count = INCR ratelimit:push:<category>:<userId>
IF count == 1:
  EXPIRE ratelimit:push:<category>:<userId> <windowSeconds>
IF count > maxSends:
  DROP send; log WARN with userId, category, count
  RETURN
ELSE:
  PROCEED with send
```

**The rate limit check runs after preference checks.** If the player has opted out of the category, the rate limit counter is never incremented (the send is dropped before reaching rate limit evaluation).

---

### 3.9 GDPR and Consent

Push notifications are an explicit OS-level permission feature. The system enforces a strict consent hierarchy.

**Consent layers (in order of precedence):**

1. **OS-level permission (highest authority):** iOS and Android require explicit player approval to send push notifications. This OS permission is the system's legal basis for sending. If OS permission is `denied`, **no notification of any category is ever sent**, regardless of in-app settings. This is enforced by the token not existing (the registration flow in §3.3 only proceeds on `granted` permission). There is no workaround.

2. **Player master push toggle:** An in-app master toggle in Settings → Notifications. When OFF, all categories are effectively disabled and no sends are dispatched. When ON, individual category toggles apply.

3. **Per-category opt-in:** Individual category toggles (see §3.2). Categories default to the values in §3.2. Player can disable any category at any time.

**Permission prompt rules:**
- The OS permission prompt is shown exactly once per installation, at the point defined by the Tutorial / Onboarding GDD.
- If the player dismisses without choosing (iOS `notDetermined`): do not re-prompt in the same session. Re-check on the next cold start; if still `notDetermined` after `PERMISSION_REPROMPT_MAX_ATTEMPTS` cold starts (default: 3), stop prompting and treat as implicitly denied.
- If the player denies at the OS level: the Settings → Notifications section shows a banner: *"Push notifications are disabled in your device settings. To receive match alerts, enable notifications for BRAWLZONE in Settings."* Tapping the banner opens the OS app settings via `Linking.openSettings()`.
- **No notification is sent before OS permission is granted.** This is not configurable and cannot be overridden by the operator.

**GDPR right to erasure:** When `DELETE /v1/account` is processed server-side, all rows in `device_tokens` for that `userId` are hard-deleted (the `ON DELETE CASCADE` on the `players` FK handles this). All `notification_preferences` rows are also cascade-deleted. No future sends can occur for the deleted account.

**Analytics / Telemetry consent:** Push opt-in state is a Tier 1 signal per the Analytics / Telemetry GDD (§3.3). If the player revokes Tier 1 analytics consent, this does not disable push notifications — analytics consent and push notification consent are independent decisions. However, the server does not log or report per-player push engagement metrics (open rates, tap-through rates attributed to an individual player) unless that player has Tier 1 analytics consent. Aggregate push metrics (category send count, delivery rate) are Tier 0 operational data.

---

### 3.10 Server-Side Send Architecture

All push sends originate on the Node.js server. The client is never the sender — it only receives notifications and manages preferences.

**Send pipeline:**

```
Trigger (Matchmaking / Cron / Event system / Operator)
    │
    ▼
[1] Resolve recipients
    - Query player IDs who should receive this notification
    - Filter: pushEnabled = true, category opted in, rate limit not exceeded
    - Filter: active token(s) in device_tokens where is_active = true
    │
    ▼
[2] Construct payloads
    - One payload per token (not per player — a player with 2 devices gets 2 sends)
    - Populate title, body, data, priority, ttlSeconds per §3.5
    │
    ▼
[3] Batch to Expo Push API
    - POST https://exp.host/--/api/v2/push/send
    - Batch size: up to EXPO_PUSH_BATCH_SIZE per request (default: 100, Expo limit: 100)
    - Multiple batches if recipients > 100
    - Request body: array of BrawlzonePushMessage objects
    │
    ▼
[4] Process receipts (async, via Expo Push Receipt API)
    - After send, Expo returns a ticketId per message
    - Server stores ticketId → notificationId mapping in Redis (TTL: 24h)
    - A background job polls GET https://exp.host/--/api/v2/push/getReceipts
      every RECEIPT_POLL_INTERVAL_MINUTES (default: 15 min)
    - Receipts with status 'error':
        'DeviceNotRegistered' → mark token inactive (§3.4)
        'MessageTooBig' → log ERROR; investigate payload size
        'MessageRateExceeded' → log WARN; backoff and retry
        'InvalidCredentials' → log ERROR; alert on-call team
    │
    ▼
[5] Log outcome
    - Log send attempt: userId (UUID only — no display name per PII policy), 
      category, notificationId, platform, outcome
    - Never log raw push token in server logs
```

**Expo Push API error handling (step 3):**
- HTTP 200 with ticket errors: handled in step 4 (receipts).
- HTTP 429 (Expo rate limit): backoff exponentially starting at `EXPO_RATE_LIMIT_BACKOFF_BASE_MS` (default: 5 000 ms), up to `EXPO_RATE_LIMIT_BACKOFF_MAX_MS` (default: 60 000 ms). Retry the batch.
- HTTP 5xx: retry up to `EXPO_SEND_MAX_RETRIES` (default: 3) times with exponential backoff. On exhaustion: log ERROR; drop the batch; do NOT re-queue (a missed push notification is acceptable; a system-halting retry loop is not).
- HTTP 4xx (excluding 429): log ERROR with response body; drop batch; do NOT retry (malformed request — retrying would produce the same error).

---

## 4. Formulas

### 4.1 Daily Quest Reset Time

Daily quests reset at **UTC midnight (00:00:00 UTC) every day**. This is a fixed-clock reset, not a rolling 24-hour window from the player's first login.

**Rationale:** Fixed UTC midnight enables a single server-side cron job that fires once and dispatches `daily_reset` notifications to all opted-in players simultaneously, rather than per-player rolling timers that would require per-player scheduled jobs at scale.

**Cron expression:** `0 0 * * *` (runs at 00:00 UTC daily).

**`daily_reset` notification send window:** The send job runs at `00:00:00 UTC` + `DAILY_RESET_SEND_DELAY_MS` (default: 5 000 ms — a 5-second buffer to ensure the reset has been committed to the database before notifications fire).

**Example:**
- Player A is in UTC+9 (Tokyo). UTC midnight = 09:00 local time. They receive the daily reset notification at 09:00:05 local time.
- Player B is in UTC-5 (New York). UTC midnight = 19:00 local time (previous day). They receive the notification at 19:00:05 local time.

This means players in western time zones receive the notification in the evening. This is acceptable at MVP. A localized per-player reset window (e.g., local midnight) is a post-MVP enhancement that requires per-player scheduled jobs and is deferred.

**Rate limit window for `daily_reset` is 23 hours** (not 24) to be tolerant of cron drift and clock skew between the job scheduler and the rate limit Redis check. A 23-hour window guarantees that two legitimate consecutive daily reset notifications (24 hours apart real-world) never collide.

---

### 4.2 Promotional Notification Max Frequency

```
canSendPromo(userId) =
  (now - lastPromoSendTime[userId]) >= PROMO_MIN_INTERVAL_HOURS × 3600 seconds
```

Where:
- `PROMO_MIN_INTERVAL_HOURS` = 72 (default) — configurable via Remote Config (see §7)
- `lastPromoSendTime[userId]` = Redis key `ratelimit:push:promotional:<userId>` TTL expiry anchor

**Enforcement:** Redis `INCR` + `EXPIRE` pattern (§3.8). Once a promotional notification is sent to a player, the key is set with `EXPIRE = PROMO_MIN_INTERVAL_HOURS × 3600`. Any attempt to send another `promotional` notification within that window is dropped.

**Example:**
- PROMO_MIN_INTERVAL_HOURS = 72
- Player received a promotional notification at 2026-05-28T09:00:00Z.
- Redis key TTL = 72 × 3600 = 259 200 seconds.
- Next promotional send to this player is allowed no earlier than 2026-05-31T09:00:00Z.
- If the operator schedules a campaign for 2026-05-29T09:00:00Z, this player is excluded (rate limit counter = 1, max = 1, within window).

---

### 4.3 Token Refresh Check Interval

```
shouldCheckToken(lastCheckTimestamp) =
  (now - lastCheckTimestamp) >= TOKEN_CHECK_INTERVAL_MS
```

Where:
- `TOKEN_CHECK_INTERVAL_MS` = 3 600 000 ms (1 hour, default)
- `lastCheckTimestamp` = value stored in AsyncStorage under `push.lastTokenCheck`

**Example:**
- App foregrounded at 14:00. `lastTokenCheck` = 13:10 (50 minutes ago). `now - lastTokenCheck` = 50 min < 60 min → **skip token check**.
- App foregrounded again at 14:15. `lastTokenCheck` = 13:10 (65 minutes ago). `now - lastTokenCheck` = 65 min > 60 min → **perform token check**, update `lastTokenCheck` to 14:15.

---

### 4.4 `match_found` Rate Limit

```
matchFoundRateLimit(userId) =
  sendsInLastHour(userId, 'match_found') < MATCH_FOUND_MAX_PER_HOUR
```

Where:
- `MATCH_FOUND_MAX_PER_HOUR` = 3 (default)
- `sendsInLastHour` = value of Redis key `ratelimit:push:match_found:<userId>` (expires after 3600s from first increment)

**Example:**
- Player queues, backgrounds, gets match found → 1 send. Doesn't accept; re-queues. Match found again → 2 sends. Re-queues again. Match found → 3 sends. Re-queues a 4th time. Match found at 4th attempt → counter = 4 > 3 → send is **dropped**. Player will not receive a push for this 4th match; they must foreground the app themselves or the match is forfeited.

---

### 4.5 Activity Gate Formula

For `daily_reset`, `event_start`, and `promotional` categories, the server checks whether a player is recently active before sending:

```
isRecentlyActive(userId, thresholdDays) =
  (now - lastActiveTimestamp[userId]) <= thresholdDays × 86400 seconds
```

Where:
- `lastActiveTimestamp[userId]` = `last_active_at` column in `players` table, updated on every authenticated session start.
- `thresholdDays` is category-specific (see §3.1).

**Example (daily_reset):**
- DAILY_RESET_ACTIVE_DAYS_THRESHOLD = 7
- Player last active: 2026-05-20T10:00:00Z. Today: 2026-05-28T00:00:05Z.
- Delta = 8 days > 7 days → player is **excluded** from daily reset notification.
- If the same player logs in on 2026-05-28 at any time, `last_active_at` updates and they qualify for the **next** day's reset notification.

---

## 5. Edge Cases

### EC-01: Device Token Invalidated (APNs/FCM Returns `DeviceNotRegistered`)

**Trigger:** Expo Push API receipt polling (§3.10 Step 4) returns a receipt with `status: 'error'` and `details.error: 'DeviceNotRegistered'` for a given token.

**Response:**
1. Server executes `UPDATE device_tokens SET is_active = false, updated_at = NOW() WHERE token = $1`.
2. The token is excluded from all future send queries immediately (query filter: `is_active = true`).
3. Log WARN: `[PUSH] Token invalidated — userId: <uuid>, platform: <ios|android>` (raw token NOT logged — PII policy).
4. No notification is retried. The send is dropped.
5. The token remains in the database for 30 days (audit retention), then is purged by a nightly cleanup job.
6. When the player next opens the app, the registration flow (§3.3) runs, generates a new valid token, and re-registers. Sends resume normally after re-registration.

---

### EC-02: Player Uninstalls the App

**Trigger:** Player uninstalls BRAWLZONE. The OS deregisters the push token from APNs/FCM. Expo's platform will begin returning `DeviceNotRegistered` for that token on the next send attempt.

**Response:** Same as EC-01. The server discovers the invalidation via receipt polling and marks the token inactive. There is no proactive "uninstall" signal from the OS — invalidation is discovered lazily via send failure. This is expected behavior for APNs/FCM and requires no special handling beyond EC-01.

---

### EC-03: Player Opts Out at OS Level But Not in In-App Settings

**Trigger:** Player disables BRAWLZONE notifications in the device OS settings (iOS Settings → Notifications → BRAWLZONE → Allow Notifications: OFF) without touching the in-app Settings → Notifications toggles. In-app toggles remain in their previous state.

**Response:**
- At the OS level, APNs/FCM silently drops all push notifications for the app. The Expo Push API will not receive a `DeviceNotRegistered` error in this case — it will return a successful ticket, and the OS simply never displays the notification to the player.
- This is a known limitation of APNs/FCM: the sender receives no signal that the player opted out at the OS level.
- On the next app foreground after the OS permission change, the client calls `expo-notifications.getPermissionsAsync()`. If the returned status is `denied`: the client sets `pushEnabled = false` locally and issues a `PATCH /v1/players/me/notification-preferences` with `pushEnabled: false`. Future sends are suppressed server-side.
- The in-app toggles are NOT automatically toggled off — they retain their values. If the player re-enables OS notifications, the in-app preferences remain intact and sends resume automatically on next token re-registration.
- Until the client foregrounds and checks permission status: the server may continue dispatching notifications (which are silently dropped by the OS). This is acceptable — the window of "wasted sends" is bounded by when the player next opens the app.

---

### EC-04: Notification Arrives While Player Is in Active Match

**Trigger:** A push notification arrives (foreground delivery) while the player is in a `match_found` or non-`match_found` notification and `MatchContext.matchPhase` is active.

**Response:**
- Client's `addNotificationReceivedListener` fires.
- Listener checks `MatchContext.matchPhase`. If active: **suppress entirely** — no banner, no sound, no badge increment. Log a DEBUG entry.
- The notification is not queued for deferred display. It is silently dropped client-side.
- Exception: if the player had their device in their pocket (app backgrounded, not foreground), the OS delivered the notification to the lock screen directly. The client foreground handler does not fire for notifications delivered to the lock screen while backgrounded. This is unavoidable. The player will see the notification on their lock screen. Tapping it after the match will attempt deep link routing (§3.6 fallback logic handles stale matchIds gracefully).
- Server-side foreground suppression (§3.7) handles the case where `player_presence.in_match = true` for most categories.

---

### EC-05: Multiple Devices for the Same `userId` (Tablet + Phone)

**Trigger:** A player is registered on both a phone and a tablet (or two phones). Both have valid, active tokens in `device_tokens`.

**Response:**
- The server sends to **all active tokens for the `userId`**. Each device gets its own push notification.
- This is intentional for `match_found`: the player may be on either device when they are backgrounded; both devices should notify.
- For `daily_reset`, `event_start`, and `promotional`: the same notification appears on all devices. This is acceptable — the player sees it once on whichever device they pick up first. The deep link routes to the correct screen on whichever device they tap from.
- Rate limits are per-`userId`, not per-token. A `promotional` send to a player with two devices counts as 1 against their rate limit (the rate limit is checked once per `userId`, then tokens are resolved). This prevents the rate limit being "spent" twice for what is logically one player notification.
- Exception: if the player only has one device active (`is_active = true`), only one send occurs as normal.

---

### EC-06: Send Fails — Expo Push API Returns Error

**Trigger:** The Expo Push API returns an error during the batch send (§3.10 Step 3).

**Retry vs. drop policy:**

| Error Type | Action |
|-----------|--------|
| HTTP 429 (Expo rate limit) | Retry with exponential backoff: base `EXPO_RATE_LIMIT_BACKOFF_BASE_MS` (default: 5 000 ms), multiplier 2.0, max `EXPO_RATE_LIMIT_BACKOFF_MAX_MS` (default: 60 000 ms). Retry up to `EXPO_SEND_MAX_RETRIES` times |
| HTTP 5xx (Expo server error) | Retry with exponential backoff. Up to `EXPO_SEND_MAX_RETRIES` (default: 3) attempts. On exhaustion: **drop** the batch, log ERROR |
| HTTP 4xx excluding 429 (bad request) | **Drop immediately** — do not retry. Log ERROR with response body |
| Network timeout to Expo | Retry with exponential backoff. Same limits as HTTP 5xx |
| Ticket-level error (receipt polling) | See EC-01 (`DeviceNotRegistered`) or category-specific handling in §3.10 |

**On drop:** A missed push notification is a degraded experience, not a critical failure. The game is still playable. Dropping is always preferred over unbounded retry loops that could exhaust server resources or cause Expo rate limit escalation. Log ERROR with: `notificationId`, `category`, `recipientCount`, `failureReason`.

**`match_found` on exhausted retries:** If a `match_found` notification batch fails after all retries, the match proceeds without the notification. The Matchmaking Engine does not know or care — match lifecycle continues. The player either foregrounds on their own or forfeits the queue slot per the Matchmaking GDD's queue-timeout rules.

---

### EC-07: Expo Project ID Missing at Token Fetch

**Trigger:** `process.env.EXPO_PUBLIC_EXPO_PROJECT_ID` is undefined or empty when the client calls `getExpoPushTokenAsync()`.

**Response:**
1. Token fetch throws `Error: Must provide projectId`.
2. Client catches the error, logs WARN: `[PUSH] Token fetch failed — missing EXPO_PROJECT_ID`.
3. Token registration is not attempted. `push.deviceToken` in AsyncStorage remains unset or unchanged.
4. Client schedules retry on next app foreground (up to `TOKEN_REGISTRATION_MAX_RETRIES` attempts — default: 3).
5. On 3 consecutive failures, log ERROR and stop retrying until the next cold start.
6. No crash; no user-visible error. Push simply does not work for this device until the configuration is corrected in the app build.

---

### EC-08: Player Taps a `match_found` Notification for an Expired Match

**Trigger:** Player receives a `match_found` notification, does not tap it immediately. The match countdown expires server-side (the player is removed from the match; the match is disbanded or filled with a bot). Player taps the notification later.

**Response:**
1. Deep link `brawlzone://match/join?matchId=<id>&mode=<mode>` is received by the app.
2. Client calls `GET /v1/matches/<matchId>/status` (or checks the match state via the API Client).
3. Server returns 404 (match not found) or a status indicating the match is `disbanded` / `in_progress` / `completed`.
4. Client navigates to Main Menu (home tab) instead of the match screen.
5. Toast displayed: *"That match is no longer available. Start a new search to play."*
6. No crash; no stuck loading screen.

---

### EC-09: `daily_reset` Cron Job Fires Twice (Duplicate Send Prevention)

**Trigger:** Due to a cron scheduler restart or infrastructure failover, the `daily_reset` cron job fires twice within the same 23-hour rate limit window.

**Response:**
- On the second invocation, for each player, the Redis rate limit check (§3.8) returns `count = 2 > maxSends (1)`.
- All sends on the second invocation are dropped.
- Log WARN per dropped send: `[PUSH] daily_reset rate limit exceeded — duplicate cron execution suspected`.
- No player receives two `daily_reset` notifications within 23 hours. The 23-hour window (not 24) was chosen specifically to absorb this scenario.

---

### EC-10: Server-Side `player_presence` Record Is Stale

**Trigger:** Player's real-time connection drops unexpectedly without sending `app-backgrounded`. Server's `player_presence.foreground` remains `true` (stale) after the player has actually left.

**Response:**
- Server-side foreground suppression check (§3.7) uses `PRESENCE_STALE_THRESHOLD_SEC` (default: 30s).
- If `player_presence.updated_at < now - 30s`: treat presence as **unknown** and send the notification anyway.
- This means a small number of notifications may be sent to players who are technically foregrounded but whose presence is stale. The client-side foreground handler (`addNotificationReceivedListener`) provides the final suppression gate for non-match contexts.

---

## 6. Dependencies

### 6.1 Upstream Dependencies

| System | Dependency | Notes |
|--------|-----------|-------|
| **Authentication** (`authentication.md`) | Supabase JWT provides `userId` for token registration and all server-side operations. Device token is registered against authenticated `userId`. No token registration occurs for unauthenticated sessions. | Required |
| **API Client** (`api-client.md`) | All client-to-server calls in this system (`POST /v1/players/me/device-token`, `PATCH /v1/players/me/notification-preferences`) route through the API Client singleton with JWT auto-attach and offline queue. | Required |
| **Analytics / Telemetry** (`analytics-telemetry.md`) | Push opt-in state is a Tier 1 consent signal. Per-player push engagement metrics (tap-through rate) require Tier 1 analytics consent. Aggregate delivery metrics are Tier 0. | Required |
| **Settings / Accessibility** (`settings-accessibility.md`) | Settings screen owns the notification category toggle UI. Preferences stored in AsyncStorage at MVP migrate to server-synced preferences when this system activates. Canonical consent record lives server-side in `notification_preferences` table. | Required |
| **Remote Config** (`remote-config.md`) | `featureFlags.socialEnabled` gates `friend_activity` sends. `gameMode.eventModeActive` triggers `event_start` sends. Operator-configurable tuning knobs (promo interval, batch size) may be added as Hot keys in a future iteration. | Required |
| **Logging / Monitoring** (`logging-monitoring.md`) | ILogger interface for all WARN/ERROR/DEBUG logs. PII policy: no raw push tokens, no display names in logs — `userId` UUID only. | Required |
| **Tutorial / Onboarding** | Defines the exact moment in the onboarding flow when the OS permission prompt is shown. Push system defers to Onboarding for the prompt timing decision. | Required |
| **Matchmaking Engine** | Triggers `match_found` notification when a queue entry is fulfilled and the player is backgrounded. Provides `matchId` and `gameMode` for the payload. | Required |
| **Match Flow** | Provides `MatchContext.matchPhase` to the client-side foreground suppression handler. | Required |
| **Real-time Transport** | `player_presence.foreground` and `player_presence.in_match` are maintained via Socket.io events — used for server-side foreground suppression. | Required |

### 6.2 Downstream Dependents

| System | What It Consumes |
|--------|-----------------|
| **Settings / Accessibility** | Reads stored notification preferences from server (`GET /v1/players/me/notification-preferences`) to populate toggle states in the UI. |
| **Player Profile** | `device_tokens` and `notification_preferences` are cascade-deleted on `DELETE /v1/account` (FK constraint). |
| **Analytics / Telemetry** | Aggregate push delivery and tap-through metrics flow into analytics dashboards for live-ops decisions. |

### 6.3 External Dependencies

| Dependency | Purpose | Notes |
|-----------|---------|-------|
| **Expo Push Notification Service** | Routes messages from Node.js server to APNs (iOS) and FCM (Android). API: `https://exp.host/--/api/v2/push/send` and `getReceipts`. | Rate limit: 600 requests/sec per project (Expo docs). Batch size: 100 messages per request. |
| **APNs (Apple Push Notification service)** | Delivers to iOS devices. Credentials managed by Expo (uses Expo's APNs certificate pool in managed workflow). | Token-based auth (`.p8` key). Expo manages the credential; BRAWLZONE does not hold raw APNs credentials. |
| **FCM (Firebase Cloud Messaging)** | Delivers to Android devices. Credentials managed by Expo. | Expo manages the FCM server key. |
| **Redis** | Rate limit counters (rolling window via `INCR` + `EXPIRE`). Expo ticket ID → notification ID mapping (receipt tracking). | Same Redis instance as other game systems. |
| **expo-notifications** | Client-side SDK for permission prompting, token retrieval, notification received/response listeners. | `expo-notifications` package, Expo SDK. |

---

## 7. Tuning Knobs

All client-side constants live in `mobile/src/config/pushNotifications.ts`. All server-side constants live in `server/src/config/pushNotifications.ts`.

| Constant | Side | Default | Safe Range | Description |
|----------|------|---------|------------|-------------|
| `MATCH_FOUND_MAX_PER_HOUR` | Server | 3 | 1 – 10 | Max `match_found` sends per player per hour. Raise to allow aggressive re-queue notification; lower to reduce spam. |
| `DAILY_RESET_ACTIVE_DAYS_THRESHOLD` | Server | 7 | 1 – 30 | Days of inactivity before `daily_reset` notifications stop. Raise to re-engage longer-absent players; lower to focus on recently active players only. |
| `EVENT_START_ACTIVE_DAYS_THRESHOLD` | Server | 14 | 3 – 60 | Days of inactivity before `event_start` notifications stop. Events should reach players who have been away a few weeks. |
| `PROMO_ACTIVE_DAYS_THRESHOLD` | Server | 30 | 7 – 90 | Days of inactivity before `promotional` notifications stop. |
| `PROMO_MIN_INTERVAL_HOURS` | Server | 72 | 24 – 168 | Minimum hours between two promotional sends to the same player. 72h = 3-day minimum. Setting below 24h risks regulatory scrutiny and opt-out spike. |
| `FRIEND_ACTIVITY_OFFLINE_THRESHOLD_HOURS` | Server | 24 | 1 – 72 | Hours a friend must have been offline before a "friend came online" notification is triggered. Prevents notification on every brief absence. |
| `PRESENCE_STALE_THRESHOLD_SEC` | Server | 30 | 10 – 120 | Seconds after which `player_presence.updated_at` is considered stale; server treats presence as unknown and sends anyway. |
| `DAILY_RESET_SEND_DELAY_MS` | Server | 5000 | 0 – 30000 | Milliseconds after UTC midnight before the daily reset cron dispatches notifications. Provides buffer for DB reset job to commit. |
| `EXPO_PUSH_BATCH_SIZE` | Server | 100 | 1 – 100 | Messages per Expo Push API request. 100 is the Expo maximum; reducing lowers throughput. Do not exceed 100. |
| `EXPO_SEND_MAX_RETRIES` | Server | 3 | 0 – 5 | Retry attempts on Expo Push API 5xx / timeout. 0 = no retries (drop on first failure). |
| `EXPO_RATE_LIMIT_BACKOFF_BASE_MS` | Server | 5000 | 1000 – 30000 | First backoff interval on Expo 429. |
| `EXPO_RATE_LIMIT_BACKOFF_MAX_MS` | Server | 60000 | 10000 – 300000 | Maximum backoff interval on Expo 429. |
| `RECEIPT_POLL_INTERVAL_MINUTES` | Server | 15 | 5 – 60 | How frequently the server polls Expo's receipt API. Expo recommends polling no more frequently than every 15 minutes for large volumes. |
| `TOKEN_CHECK_INTERVAL_MS` | Client | 3600000 | 300000 – 86400000 | Minimum milliseconds between client-side token freshness checks on app foreground (1h default). |
| `TOKEN_REGISTRATION_MAX_RETRIES` | Client | 3 | 0 – 10 | Max token registration attempts before giving up until next cold start. |
| `PERMISSION_REPROMPT_MAX_ATTEMPTS` | Client | 3 | 1 – 5 | Max cold starts on which to retry the OS permission prompt when status is `notDetermined`. |
| `NOTIFICATION_BANNER_DURATION_MS` | Client | 4000 | 2000 – 8000 | Duration in ms for in-app notification banners (foreground, non-match state). |

---

## 8. Acceptance Criteria

**AC-01: OS Permission Required Before Any Send**
Given a player who has not yet granted OS-level push permission.
When any notification category is triggered for that player.
Then no push notification is sent. The `device_tokens` table has no active token row for that player. Zero calls to the Expo Push API are made for that player.

**AC-02: Token Registration on First Permission Grant**
Given a player grants OS push permission for the first time.
When the registration flow completes.
Then `POST /v1/players/me/device-token` is called with a valid Expo push token, platform, and appVersion within 5 seconds.
And the `device_tokens` table contains exactly one active row for that `(userId, deviceId)` pair.

**AC-03: Token Registration Is Idempotent**
Given a player already has a registered active token.
When the player cold-starts the app and the token is unchanged.
Then `POST /v1/players/me/device-token` is called.
And the `device_tokens` table still contains exactly one row for that `(userId, deviceId)` pair (upsert, not duplicate insert).

**AC-04: Token Rotation on Change**
Given a player's Expo push token changes (simulated by mocking `getExpoPushTokenAsync` to return a different token).
When the player foregrounds the app and `TOKEN_CHECK_INTERVAL_MS` has elapsed since the last check.
Then `POST /v1/players/me/device-token` is called with the new token.
And the `device_tokens` row for that `(userId, deviceId)` is updated with the new token value.

**AC-05: `match_found` Notification Delivered When Backgrounded**
Given a player has an active queue entry, OS permission granted, `match_found` opted in, and the app is backgrounded.
When the Matchmaking Engine assembles a match for that player.
Then a push notification is sent via Expo Push API with `category: 'match_found'`, correct `matchId`, and `priority: 'high'` within 3 seconds of match assembly.

**AC-06: `match_found` Not Sent When Foregrounded**
Given a player has an active queue entry and the app is foregrounded (`player_presence.foreground = true`).
When the Matchmaking Engine assembles a match for that player.
Then no push notification is sent to that player. Zero calls to the Expo Push API for `match_found` for that `userId`.

**AC-07: Category Opt-Out Prevents Send**
Given a player has `promotional` category opted out (`promotional: false` in `notification_preferences`).
When a promotional notification is dispatched.
Then the player is excluded from the recipient list. Zero calls to the Expo Push API for that `userId` for that send.

**AC-08: Rate Limit Enforced for `promotional`**
Given `PROMO_MIN_INTERVAL_HOURS = 72` and a player received a promotional notification at T=0.
When a second promotional notification is dispatched at T=48 hours.
Then the player is excluded from the send (rate limit active). Redis key `ratelimit:push:promotional:<userId>` has `count = 1` and TTL > 0.
When a third promotional notification is dispatched at T=73 hours.
Then the player is included in the send (rate limit window expired).

**AC-09: Per-Category Preferences Synced Server-Side**
Given a player toggles `daily_reset` from OFF to ON in Settings → Notifications.
When the toggle is saved.
Then `PATCH /v1/players/me/notification-preferences` is called with `{ categories: { daily_reset: true } }` within 1 second.
And subsequent GET of `/v1/players/me/notification-preferences` returns `daily_reset: true`.

**AC-10: Preference Sync Failure Reverts Toggle**
Given the API returns HTTP 500 on `PATCH /v1/players/me/notification-preferences`.
When the player toggles a category.
Then the toggle reverts to its previous state within 500 ms.
And a toast *"Could not update notification settings. Please try again."* is displayed.

**AC-11: Foreground Suppression During Active Match**
Given the player is in an active match (`MatchContext.matchPhase` is not null or ended) and the app is foregrounded.
When a push notification is received by the client.
Then no banner is shown, no sound is played, no badge is incremented.
And a DEBUG log entry is written with the notification's `notificationId` and `category`.

**AC-12: Deep Link Routes to Match Screen**
Given a player taps a `match_found` push notification and the match is still in lobby state.
When the app opens (cold start or foreground).
Then the app navigates to the match lobby screen for `matchId` within 2 seconds of the tap event.

**AC-13: Deep Link Falls Back on Expired Match**
Given a player taps a `match_found` push notification and the match has expired (404 or disbanded).
When the deep link is processed.
Then the app navigates to Main Menu (home tab).
And a toast *"That match is no longer available. Start a new search to play."* is displayed.
And no crash or stuck loading state occurs.

**AC-14: DeviceNotRegistered Marks Token Inactive**
Given a send receipt from Expo contains `status: 'error'` with `details.error: 'DeviceNotRegistered'` for token T.
When the receipt poller processes this receipt.
Then `device_tokens.is_active` is set to `false` for the row with `token = T`.
And subsequent send queries do not include that token.
And the raw token value does not appear in server logs (PII policy).

**AC-15: Multiple Devices — Both Receive Notification**
Given a player has two active tokens in `device_tokens` (phone and tablet).
When a `match_found` notification is dispatched for that player.
Then both tokens receive a send request via Expo Push API.
And the rate limit counter for `match_found` increments by 1 (per player, not per token).

**AC-16: `daily_reset` Fires at UTC Midnight**
Given the daily reset cron job is configured with `0 0 * * *`.
When UTC midnight passes on any day.
Then the cron job fires within `DAILY_RESET_SEND_DELAY_MS` + 10 seconds.
And all eligible players (opted in, `daily_reset`, recently active per `DAILY_RESET_ACTIVE_DAYS_THRESHOLD`, incomplete quests) receive a `daily_reset` notification.

**AC-17: Duplicate Cron — Rate Limit Prevents Double Send**
Given the `daily_reset` cron fires twice within the same calendar day (duplicate execution simulation).
When the second invocation processes the same players.
Then all sends in the second invocation are dropped (rate limit `count = 2 > 1`).
And no player receives two `daily_reset` notifications within 23 hours.

**AC-18: `friend_activity` Suppressed When Feature Flag Off**
Given `featureFlags.socialEnabled = false` in Remote Config.
When a `friend_activity` trigger occurs.
Then zero sends are dispatched. No Expo Push API calls for `friend_activity` category.

**AC-19: OS Permission Denied — In-App Banner Shown**
Given a player has denied push notifications at the OS level.
When the player views Settings → Notifications.
Then a banner is displayed: *"Push notifications are disabled in your device settings. To receive match alerts, enable notifications for BRAWLZONE in Settings."*
And tapping the banner opens the device OS settings via `Linking.openSettings()`.

**AC-20: Account Deletion Clears All Tokens and Preferences**
Given a player with two active device tokens and saved notification preferences.
When `DELETE /v1/account` is processed server-side.
Then all rows in `device_tokens` for that `userId` are hard-deleted (via `ON DELETE CASCADE`).
And all rows in `notification_preferences` for that `userId` are hard-deleted.
And no future send attempts match that `userId`.

**AC-21: `match_found` TTL Enforced**
Given a `match_found` notification with `ttlSeconds: 120` is sent.
When the notification has not been delivered within 120 seconds (APNs / FCM respects the TTL).
Then the push platform discards the notification and does not deliver it to the device.
(Verified by confirming `ttl` field is present in the Expo Push API request payload with value 120.)

**AC-22: No Raw PII in Server Logs**
Given push notification operations generate server-side log entries.
When any WARN, ERROR, or DEBUG log entry related to the push system is inspected.
Then the raw Expo push token string does not appear in any log entry.
And no display names or email addresses appear. Only `userId` UUIDs are present for player identification.

---

*End of document.*
