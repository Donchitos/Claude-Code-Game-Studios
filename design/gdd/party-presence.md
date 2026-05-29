# Party / Presence System — Game Design Document
> **System**: Party / Presence System
> **Priority**: VS
> **Layer**: Core Data
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-28
> **Last Updated**: 2026-05-28

---

## Table of Contents

1. [Overview](#1-overview)
2. [Player Fantasy](#2-player-fantasy)
3. [Detailed Rules](#3-detailed-rules)
4. [Formulas](#4-formulas)
5. [Edge Cases](#5-edge-cases)
6. [Dependencies](#6-dependencies)
7. [Tuning Knobs](#7-tuning-knobs)
8. [Acceptance Criteria](#8-acceptance-criteria)

---

## 1. Overview

The **Party / Presence System** is a VS-tier addition that ships as a Core Data layer alongside the Matchmaking Engine update enabling party queue. It owns two related but distinct concerns:

### 1.1 Presence Layer

Presence tracks each player's real-time activity state and makes that state visible to their friends and party members. The system does not broadcast presence to all players — only to the social circle of each player (currently: party members and friends who have shared an invite code this session). Presence data is ephemeral: states are held in Redis and synced over Socket.io; nothing is persisted to PostgreSQL beyond session bookkeeping.

Presence enables contextual UI for the party system (e.g., "Alex is In Match — can't invite right now") and gives the Lobby UI the signal it needs to render party member status badges.

### 1.2 Party System

A party is a temporary group of 2–3 players who agree to queue together for 3v3 Squad Brawl. The party system manages the full lifecycle:

```
CREATE → INVITE → JOIN → READY CHECK → QUEUE → [MATCH] → DISBAND
```

Parties are ephemeral and session-scoped. They are disbanded automatically on match completion or when any member leaves the group. There is no persistent party data between sessions.

### 1.3 Relationship to Matchmaking

At MVP, all modes use solo queue. With this VS system shipped, the Matchmaking Engine is extended to accept a **party queue unit** — a bundle of 2–3 players with a computed average MMR — for 3v3 Squad Brawl only. The 1v1 Duel and 8-player FFA modes remain solo-queue-only even after VS.

The "Coming Soon" placeholder in the Lobby UI is replaced by full party formation UI once this system is live.

---

## 2. Player Fantasy

### 2.1 The Core Fantasy

The party system is about the **social contract of "let's go"** — the moment a group of friends decides to play together and executes on that decision with minimal friction. In a mobile context this is especially loaded: players are often in different physical locations, coordinating over a chat app. The system must feel immediate and trustworthy — tap a button, share a code, your friend is in.

### 2.2 Fantasy Moments

**"I can see you're free."**
A player opens BRAWLZONE and sees their friend's presence badge: *In Menu*. That green dot is an invitation before any words are spoken. Presence collapses the "are you playing right now?" overhead of mobile coordination.

**"Code sent. You're in."**
The invite code flow mirrors how players already coordinate on mobile — copy a short code, paste it in the chat they're already in. There is no friend-list registration step, no account linking. It just works across any communication channel the players already use.

**"Ready? Let's go."**
The ready-check is the ritual that makes the squad feel like a squad. All three members see the same countdown. Everyone taps Ready. The queue animation starts for the whole group at once. It is the shared commitment moment.

**"We won — together."**
Party wins are qualitatively different from solo wins. The post-match screen shows all party members' contributions side by side. The victory belongs to the group, not just the individual. This social context gives 3v3 wins disproportionate emotional weight.

**"You're in a match — I'll wait."**
Seeing a friend's status as *In Match* sets correct expectations. The player knows not to spam invites; they know their friend will be free soon. Presence turns waiting into anticipation rather than frustration.

---

## 3. Detailed Rules

### 3.1 Presence States

Each player has exactly one presence state at any given time.

| State | Enum Value | Description | Visible Detail |
|---|---|---|---|
| Offline | `OFFLINE` | Not connected to the socket server | Last seen timestamp |
| Online — Menu | `ONLINE_MENU` | Connected, in main menu or lobby UI | None |
| Online — Queue | `ONLINE_QUEUE` | Searching for a match | Mode name (e.g., "In Queue: Squad Brawl") |
| Online — Match | `ONLINE_MATCH` | In an active match | "In Match" only — matchId is **not** exposed to prevent spectator-sniping |
| Away | `AWAY` | App backgrounded for longer than `AWAY_TIMEOUT_MS` | None |

**Notes:**
- `ONLINE_QUEUE` includes a `modeId` field server-side but clients only receive the human-readable mode label.
- `ONLINE_MATCH` carries a `matchId` field server-side for internal routing but this field is stripped from all outbound presence events sent to other players.
- Transitioning from `OFFLINE` to any other state requires an active authenticated Socket.io connection.

### 3.2 Presence Update Triggers

| Event | New State | Notes |
|---|---|---|
| Socket connection established | `ONLINE_MENU` | On authenticated handshake |
| Socket disconnection (clean or timeout) | `OFFLINE` | After disconnect grace period |
| App backgrounded | Start `AWAY` timer | If still backgrounded after `AWAY_TIMEOUT_MS`, transition to `AWAY` |
| App foregrounded | `ONLINE_MENU` | Cancel `AWAY` timer; if timer had already fired, update back to ONLINE_MENU |
| Player enters matchmaking queue | `ONLINE_QUEUE` (with modeId) | Triggered by Matchmaking Engine event |
| Player leaves matchmaking queue | `ONLINE_MENU` | Triggered by queue cancel or timeout |
| Match starts | `ONLINE_MATCH` (with matchId, redacted) | Triggered by Matchmaking Engine on match creation |
| Match ends | `ONLINE_MENU` | Triggered by Match Server on match completion |

### 3.3 Presence Delivery

**Audience:** Presence updates are sent only to a player's presence audience — currently defined as: party members + players who have exchanged invite codes with the player in the current session. This is **not** a global broadcast.

**Mechanism:**
1. The player's home Socket.io server processes the state change.
2. The server publishes a `presence_update` message to a Redis pub/sub channel keyed by `player:{playerId}:presence`.
3. All Socket.io servers subscribed to that channel fan the event out to connected audience members.
4. Clients receive a `presence_update` socket event with the payload `{ playerId, state, label, updatedAt }`.

**Debounce:** Rapid state flaps (e.g., app switching quickly) are debounced server-side by `PRESENCE_DEBOUNCE_MS` before publishing. This prevents noisy presence churn.

**Payload schema:**
```json
{
  "event": "presence_update",
  "playerId": "uuid",
  "state": "ONLINE_MENU | ONLINE_QUEUE | ONLINE_MATCH | AWAY | OFFLINE",
  "label": "In Menu | In Queue: Squad Brawl | In Match | Away | Offline",
  "updatedAt": "ISO-8601 timestamp"
}
```

### 3.4 Party Creation

1. Player A (the future party leader) taps **Create Party** in the Lobby UI.
2. Server generates a unique `partyId` (UUID) and a 6-character alphanumeric **invite code** (see §4.2 for generation).
3. Server stores the party record in Redis:
   - `party:{partyId}` hash: `{ partyId, leaderId, members: [playerAId], status: "WAITING", region, createdAt }`
   - `invite:{inviteCode}` key: `partyId` with TTL = `INVITE_CODE_TTL_SEC`
4. Player A receives `party_created` event with `{ partyId, inviteCode, expiresAt }`.
5. The invite code is displayed in the UI with a one-tap **Copy Code** button. The player shares it out-of-band (messaging app, voice chat, etc.).

### 3.5 Party Join Flow

1. Player B receives the invite code out-of-band and enters it in the **Join Party** dialog.
2. Client sends `join_party_request` to server with `{ inviteCode }`.
3. Server validates:
   - Invite code exists and has not expired → else return `invite_expired`
   - Party is not full (< `MAX_PARTY_SIZE`) → else return `party_full`
   - Player B is not already in a party → else return `already_in_party`
   - Player B is online (active socket connection) → else return `player_offline`
   - Player B is in the same region as the party (if region-based matchmaking enabled) → else return `region_mismatch`
4. Server sends a `party_invite` event to Player A (the leader): `{ inviteCode, requesterId: playerBId, requesterName, requesterMMR }`.
5. Player A sees an invite notification: **"[PlayerB] wants to join your party. Accept?"**
6. Player A accepts (`party_invite_accept`) or declines (`party_invite_decline`).
   - **Accept:** Player B is added to the party `members` array. Both players receive `party_state_update`.
   - **Decline:** Player B receives `party_invite_declined`.
7. Player B's presence state is now tracked by the party room; all party members receive B's presence updates.

> **Design note (accept step):** The two-step flow (request → leader accept) is intentional for VS. It prevents griefing via uninvited code sharing and keeps the leader in control. A "direct join on code entry" fast path may be considered post-VS if friction proves too high.

### 3.6 Party Roles

| Role | Assigned To | Permissions |
|---|---|---|
| **Leader** | Party creator (Player A) | Queue as party; kick members; disband party |
| **Member** | All others | Leave party; see party state |

**Leader promotion:** Leadership is not transferable in this VS implementation. If the leader disconnects, the party is disbanded (see §5.1). Post-VS, automatic leader promotion to the next member may be considered.

### 3.7 Party Size Limit

- Maximum party size: `MAX_PARTY_SIZE` = 3 (hardcoded to match 3v3 Squad Brawl slot count).
- Attempting to invite a 4th player while the party has 3 members returns `party_full` to the requesting client.
- Parties of size 2 are valid for queue entry (see §5.6 for how the third slot is filled).

### 3.8 Party Ready-Check and Queue Entry

1. Leader taps **Queue as Party** in the Party Lobby UI.
2. Server validates:
   - All members' presence states are `ONLINE_MENU` (not in queue, not in match, not away) → else return `members_not_ready` with a list of blocking member IDs.
   - Party mode = 3v3 Squad Brawl → enforced server-side regardless of UI state.
3. Server broadcasts `party_ready_check` to all party members: `{ partyId, timeoutMs: PARTY_READY_TIMEOUT_MS, expiresAt }`.
4. Each member's client shows a **Ready / Not Ready** prompt with a countdown timer.
5. Each member sends `party_ready_confirm` or `party_ready_decline` within `PARTY_READY_TIMEOUT_MS`.
6. **All-ready path:** All members confirm → server sends `party_queued` to all members → party is submitted to Matchmaking Engine as a single queue unit with `{ partyId, memberIds, averageMMR, region }`.
7. **Failure paths:**
   - Any member declines → ready-check cancelled; `party_ready_cancelled` broadcast to all; party state returns to `WAITING`; the party is not disbanded.
   - Any member times out (no response within `PARTY_READY_TIMEOUT_MS`) → treated as decline; same outcome as above.
   - Leader disconnects during ready-check → party disbanded; `party_disbanded` broadcast to remaining members.

### 3.9 Party MMR

The party is submitted to the Matchmaking Engine with a single **average MMR** computed at queue entry time:

```
partyMMR = floor( sum(memberMMR_i for all i in party) / partySize )
```

- MMR values used are the **current values at the moment `party_queued` is sent**, not at the time members joined the party (see §5.5).
- Individual MMR updates after the match follow existing MMR GDD rules, applied to each player's actual outcome individually. The party MMR is used only for the Matchmaking bracket; it does not persist.

### 3.10 Party Disbanding Rules

A party is disbanded (all records removed from Redis) on any of the following events:

| Trigger | Mechanism |
|---|---|
| Match ends | Matchmaking Engine sends `match_complete` → party service auto-disbands |
| Any member leaves voluntarily | Member sends `party_leave`; server disbands and notifies all |
| Leader disconnects | Socket timeout detected; server disbands and notifies all |
| Any member disconnects | Socket timeout detected; server disbands and notifies all |
| Invite code expires with no members joined | TTL expiry cleans up the party record |

On disbanding, the server broadcasts `party_disbanded` to all remaining connected members and removes:
- `party:{partyId}` from Redis
- `invite:{inviteCode}` from Redis (if not already expired)

### 3.11 Invite Code Expiry

- Invite codes expire after `INVITE_CODE_TTL_SEC` seconds (default: 300 / 5 minutes).
- Expiry is enforced via Redis TTL on the `invite:{inviteCode}` key.
- An attempt to join with an expired code returns `invite_expired`.
- The party itself persists after code expiry (the leader can generate a new code via **Regenerate Code** if needed — this is a post-VS UI nicety; at VS, the leader must create a new party).

> **VS scope note:** Code regeneration without disbanding the party is deferred to post-VS. At VS, the leader must disband and re-create the party if the code expires before all members join.

### 3.12 Mode Restriction

- Party queue is only available for **3v3 Squad Brawl**.
- If a player in an active party attempts to enter solo queue for 1v1 Duel or FFA, the client prompts: **"You're in a party. Leave the party to queue solo?"**
  - Confirm: player leaves party (triggers party disband per §3.10) and enters solo queue.
  - Cancel: no action taken; player remains in party.
- This restriction is enforced on both the client (UI gate) and server (queue entry validation).

---

## 4. Formulas

### 4.1 Party Average MMR

```
partyMMR = floor( (MMR_1 + MMR_2 + ... + MMR_n) / n )
```

Where `n` = current party size (2 or 3) and `MMR_i` = each member's current MMR at the instant `party_queued` is processed by the server.

**Example:**
- Player A: 1400 MMR
- Player B: 1600 MMR
- Player C: 1550 MMR
- partyMMR = floor((1400 + 1600 + 1550) / 3) = floor(1516.67) = **1516**

### 4.2 Invite Code Generation

```
CHARSET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"   // 32 chars; excludes I, O, 0, 1 (visual ambiguity)
CODE_LENGTH = 6
code = ""
for i in range(CODE_LENGTH):
    code += CHARSET[cryptoRandom(0, len(CHARSET))]
```

**Collision handling:**
1. Generate candidate code.
2. Check `EXISTS invite:{code}` in Redis.
3. If key exists (collision), regenerate. Retry up to 5 times.
4. If 5 consecutive collisions occur (astronomically unlikely at current scale), log an alert and return a `server_error` to the client.

**Entropy:** 32^6 = ~1.07 billion possible codes. With a 300-second TTL and expected concurrent parties in the hundreds at launch, collision probability is negligible.

### 4.3 Presence Update Debounce

```
on presenceStateChange(playerId, newState):
    clearTimeout(debounceTimers[playerId])
    debounceTimers[playerId] = setTimeout(
        () => publishPresenceUpdate(playerId, newState),
        PRESENCE_DEBOUNCE_MS   // default: 500ms
    )
```

- Rapid consecutive state changes within `PRESENCE_DEBOUNCE_MS` result in only the final state being published.
- Exception: `OFFLINE` state (disconnect) bypasses debounce and publishes immediately to ensure friends see disconnects promptly.

### 4.4 Away Timer

```
on appBackground(playerId):
    awayTimers[playerId] = setTimeout(
        () => setPresence(playerId, AWAY),
        AWAY_TIMEOUT_MS   // default: 300_000ms (5 min)
    )

on appForeground(playerId):
    clearTimeout(awayTimers[playerId])
    setPresence(playerId, ONLINE_MENU)
```

---

## 5. Edge Cases

### 5.1 Party Leader Disconnects

**Scenario:** The leader's socket connection is lost (network drop, app kill, etc.) while the party is in `WAITING` or `READY_CHECK` state.

**Handling:**
- The Socket.io server detects the disconnect after the connection timeout.
- The party service is notified via the leader's `disconnect` event.
- The party is immediately disbanded.
- All remaining members receive `party_disbanded` with reason `"leader_disconnected"`.
- If a ready-check was in progress, it is also cancelled.

**Rationale:** Leadership is not automatically transferred at VS to keep the system simple. The cost of rebuild (re-create party, share new code) is low for the current scale.

### 5.2 Party Member Attempts Solo Queue While in Party

**Scenario:** Player B is in a party with Player A but taps the solo queue button for 1v1 or FFA.

**Handling:**
- Client-side: A modal prompt appears — "You're in a party. Leave the party to queue solo?" with Confirm / Cancel.
- Server-side: If a `queue_enter` request arrives for a player with an active `partyId` in Redis and the mode is not the party's designated mode, the server rejects it with `in_party_cannot_solo_queue`.
- If confirmed, the player sends `party_leave`, triggering a full party disband (§3.10), then proceeds to solo queue.

**Note:** A player cannot be simultaneously in a party and in a solo queue. These states are mutually exclusive.

### 5.3 All Party Members Decline Ready-Check

**Scenario:** The leader starts the queue, ready-check is sent, and all members (or the leader themselves) tap Not Ready or let the timer expire.

**Handling:**
- Ready-check is cancelled.
- `party_ready_cancelled` is broadcast to all members with reason `"declined"` or `"timeout"`.
- Party status returns to `WAITING`.
- **The party is NOT disbanded.** Members remain in the party room and can retry.

### 5.4 Invite Code Collision

**Scenario:** A newly generated 6-char code already exists in Redis (an active party is using it).

**Handling:**
- Regenerate the code (§4.2 retry loop, up to 5 attempts).
- On 5 consecutive failures, return `server_error` to the client and log a monitoring alert.
- In practice, at the expected scale of concurrent parties at launch, this case should never occur given the ~1.07B code space with a 5-minute TTL.

### 5.5 Party Member's MMR Changes Between Join and Queue Entry

**Scenario:** Player B joins the party at MMR 1400. Player B finishes a solo-ranked match (which is blocked — see §5.2 — so this scenario is moot for active solo queuing). However, MMR could theoretically be adjusted server-side (e.g., integrity correction, de-ranking) between join and queue.

**Handling:**
- MMR is read from the database at the moment the server processes `party_queued`, not at the time the member joined.
- This is the canonical rule: **use MMR at queue entry time**.
- No client-side MMR caching is trusted for this calculation.

### 5.6 Party Size = 2 Queuing for 3v3

**Scenario:** A party of 2 players queues for 3v3 Squad Brawl.

**Handling:**
- This is explicitly allowed.
- The party is submitted to the Matchmaking Engine as a 2-player unit.
- The Matchmaking Engine fills the third team slot with a solo-queue player whose individual MMR is within the bracket defined by the party's average MMR.
- The solo fill player is treated as a full team member; no UI distinction is made on the team roster beyond the absence of party badge indicators.
- If no suitable solo fill is found within the matchmaking timeout, standard timeout handling applies (bracket expansion, etc.) per the Matchmaking GDD.

### 5.7 Presence Spam / Rapid App Switching

**Scenario:** A player rapidly backgrounds and foregrounds the app multiple times (e.g., notification-checking behavior), generating many presence state changes.

**Handling:**
- `PRESENCE_DEBOUNCE_MS` absorbs rapid flips (§4.3).
- The away timer is reset on each foreground event, so the player does not transition to `AWAY` during brief background periods.
- Only the final settled state is published to the audience, preventing presence noise for friends.

### 5.8 Player Receives Invite While In Match

**Scenario:** Player B is in state `ONLINE_MATCH` and an invite code is entered for their connection.

**Handling:**
- Server validates presence state during join flow (§3.5, step 3).
- A player in `ONLINE_MATCH` state returns `player_in_match` error to the requesting client.
- The `party_invite` is not forwarded to the leader.
- UI shows Player B's status as "In Match" with no invite affordance visible.

---

## 6. Dependencies

### 6.1 Upstream Dependencies (What This System Needs)

| System | Dependency | Notes |
|---|---|---|
| **Authentication** | Authenticated user identity (userId, JWT) | All party and presence operations are keyed to authenticated player IDs. Party invites by code ultimately resolve to authenticated player sessions. |
| **Real-time Transport (Socket.io)** | Persistent socket connections; room management; event routing | Presence pub/sub, party state events, ready-checks, and disband notifications all ride Socket.io. The server-side Redis adapter for Socket.io must be configured for cross-server fan-out. |
| **Redis** | Ephemeral state store for presence, party records, invite codes | Party records, invite code → partyId mappings, presence state, debounce timers, away timers, and pub/sub channels all live in Redis. No party or presence data is written to PostgreSQL at VS. |

### 6.2 Downstream Dependencies (What Consumes This System)

| System | Interface | Notes |
|---|---|---|
| **Matchmaking Engine** | `queue_party(partyId, memberIds, averageMMR, region, modeId)` | The party service hands off a fully formed party unit when all members are ready-checked. The Matchmaking Engine treats this as a single bracket entry. Party queue is only enabled for modeId = `SQUAD_BRAWL_3V3`. |
| **Lobby & Team Formation UI** | `presence_update` socket events; `party_state_update` events; REST endpoint `GET /party/{partyId}` for initial state hydration | The Lobby UI replaces its "Coming Soon" placeholder with party member roster, presence badges, invite code display, and ready-check UI. The UI is a pure consumer — all state mutations go through the party service. |

### 6.3 Peer Interactions

| System | Interaction |
|---|---|
| **Match Server** | Sends `match_complete` event to party service to trigger auto-disband on match end. |
| **MMR System** | Party service reads current MMR values from the database (or a fast cache) at queue entry time to compute partyMMR. No writes to the MMR system. |

---

## 7. Tuning Knobs

All values are configurable via environment variables / server config. Defaults are VS-appropriate; they should be revisited based on observed player behavior in the VS period.

| Parameter | Env Variable | Default | Range | Effect of Change |
|---|---|---|---|---|
| **Party Ready Timeout** | `PARTY_READY_TIMEOUT_MS` | 30 000 ms (30 s) | 15 000 – 60 000 ms | Too low → more timeout failures; too high → long wait for the group to queue. 30s mirrors industry standard for mobile play sessions. |
| **Invite Code TTL** | `INVITE_CODE_TTL_SEC` | 300 s (5 min) | 60 – 900 s | Too low → code expires before friend can join in async coordination; too high → more Redis key churn and marginally higher collision surface. |
| **Presence Debounce** | `PRESENCE_DEBOUNCE_MS` | 500 ms | 100 – 2 000 ms | Too low → noisy presence events; too high → presence feels stale/delayed. |
| **Away Timeout** | `AWAY_TIMEOUT_MS` | 300 000 ms (5 min) | 60 000 – 600 000 ms | Too low → players marked Away during short notification checks; too high → ghost-online players clutter party invite flow. |
| **Max Party Size** | `MAX_PARTY_SIZE` | 3 | 2 – 3 | Currently locked to 3 for 3v3; changing to 2 would require a new mode. Not intended as a runtime tuning knob — a code change. |
| **Code Charset** | `INVITE_CODE_CHARSET` | `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` | — | Change only if accessibility research indicates different characters are preferred. Currently excludes visually ambiguous characters (I, O, 0, 1). |
| **Code Length** | `INVITE_CODE_LENGTH` | 6 | 4 – 8 | Shorter → faster entry, more collisions; longer → fewer collisions, more typing friction on mobile. |
| **Disconnect Grace Period** | `SOCKET_DISCONNECT_GRACE_MS` | 5 000 ms (5 s) | 2 000 – 15 000 ms | Allows brief network interruptions to reconnect without disbanding the party. Too high → zombie party members not cleaned up promptly. |

---

## 8. Acceptance Criteria

Criteria are organized by feature area. All criteria must pass before the system is marked **VS Complete**.

### 8.1 Party Creation

- **AC-PP-01:** Given an authenticated online player taps "Create Party," the server responds with a `party_created` event containing a non-null `partyId`, a 6-character alphanumeric `inviteCode` (matching charset `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`), and an `expiresAt` timestamp approximately `INVITE_CODE_TTL_SEC` seconds in the future.
- **AC-PP-02:** The invite code is unique — no active party in Redis shares the same code at the time of creation.
- **AC-PP-03:** A player who is already a member of an active party cannot create a second party; the server returns `already_in_party`.

### 8.2 Invite Flow

- **AC-PP-04:** Given a valid, non-expired invite code is entered by Player B, the server sends `party_invite` to the party leader (Player A) with Player B's `playerId` and display name.
- **AC-PP-05:** Given Player A accepts, Player B receives `party_state_update` showing them as a party member; Player A's client also receives the updated party roster.
- **AC-PP-06:** Given Player A declines, Player B receives `party_invite_declined` and is not added to the party.
- **AC-PP-07:** Given an expired invite code is entered, the server returns `invite_expired` and no invite is sent to the leader.
- **AC-PP-08:** Given the party is already at `MAX_PARTY_SIZE` (3), an additional join attempt returns `party_full`.
- **AC-PP-09:** Given Player B is already in an active party, a join attempt returns `already_in_party`.
- **AC-PP-10:** Given Player B's region does not match the party's region (when region-based matchmaking is enabled), the server returns `region_mismatch`.

### 8.3 Ready-Check

- **AC-PP-11:** Given the leader taps "Queue as Party," all party members receive a `party_ready_check` event with a countdown of `PARTY_READY_TIMEOUT_MS` milliseconds.
- **AC-PP-12:** Given all members send `party_ready_confirm` within the timeout, the server emits `party_queued` to all members and submits the party to the Matchmaking Engine.
- **AC-PP-13:** Given any member sends `party_ready_decline`, the server emits `party_ready_cancelled` to all members with reason `"declined"`, and the party status returns to `WAITING` without disbanding.
- **AC-PP-14:** Given any member's timer expires without a response, the server treats it as a decline (AC-PP-13 behavior applies).
- **AC-PP-15:** Given all members decline or time out, the party is NOT disbanded; members can retry the ready-check.

### 8.4 Queue Entry

- **AC-PP-16:** The Matchmaking Engine receives a party queue entry containing: `partyId`, an array of `memberIds`, `averageMMR` (computed as floor of mean MMR at queue time), `region`, and `modeId` = `SQUAD_BRAWL_3V3`.
- **AC-PP-17:** A party queue entry for a mode other than `SQUAD_BRAWL_3V3` is rejected by the server with `invalid_mode_for_party`.
- **AC-PP-18:** Given a party of size 2 queues for 3v3, the Matchmaking Engine accepts the entry and fills the third slot with a suitable solo player.

### 8.5 Disbanding

- **AC-PP-19:** When a match ends, the party is automatically disbanded within 5 seconds of the `match_complete` event; all members receive `party_disbanded` with reason `"match_complete"`.
- **AC-PP-20:** When any member (including the leader) sends `party_leave`, the party is disbanded immediately; all other members receive `party_disbanded` with reason `"member_left"`.
- **AC-PP-21:** When the leader disconnects (socket timeout), the party is disbanded; remaining members receive `party_disbanded` with reason `"leader_disconnected"`.
- **AC-PP-22:** When any non-leader member disconnects, the party is disbanded; remaining members receive `party_disbanded` with reason `"member_disconnected"`.
- **AC-PP-23:** After disbanding, all Redis keys for the party (`party:{partyId}`, `invite:{inviteCode}`) are removed.

### 8.6 Presence States

- **AC-PP-24:** On authenticated socket connection, the player's presence state is set to `ONLINE_MENU` and a `presence_update` event is published to their audience.
- **AC-PP-25:** On clean socket disconnection, the player's presence state is set to `OFFLINE` immediately (no debounce) and a `presence_update` is published to their audience.
- **AC-PP-26:** When the app is backgrounded and remains backgrounded for `AWAY_TIMEOUT_MS`, the player's presence transitions to `AWAY`.
- **AC-PP-27:** When the app is foregrounded before `AWAY_TIMEOUT_MS` elapses, the away timer is cancelled and the player remains `ONLINE_MENU`.
- **AC-PP-28:** When a player enters queue, their presence transitions to `ONLINE_QUEUE`; when they exit queue, it returns to `ONLINE_MENU`.
- **AC-PP-29:** When a match starts, the player's presence transitions to `ONLINE_MATCH`; the `presence_update` event delivered to audience members contains `"In Match"` as the label and does NOT contain the `matchId`.
- **AC-PP-30:** Presence `presence_update` events are NOT delivered to players outside the audience (non-party members, non-invite-exchanged players).
- **AC-PP-31:** Rapid presence state changes within `PRESENCE_DEBOUNCE_MS` result in only the final state being published (debounce verified by observing a single event after rapid flaps).

### 8.7 Mode Restriction

- **AC-PP-32:** A player in an active party who attempts to solo-queue for 1v1 Duel or FFA is shown the prompt "You're in a party. Leave the party to queue solo?" before any queue action is taken.
- **AC-PP-33:** If the player confirms the leave prompt, they are removed from the party (triggering disband) and successfully enter solo queue.
- **AC-PP-34:** If the player cancels the leave prompt, no state change occurs; they remain in the party.
- **AC-PP-35:** A server-side `queue_enter` request from a party member for a non-party mode is rejected with `in_party_cannot_solo_queue`, regardless of client UI state.

### 8.8 Edge Cases

- **AC-PP-36:** A join attempt for a player in state `ONLINE_MATCH` returns `player_in_match`; no `party_invite` is sent to the leader.
- **AC-PP-37:** If invite code generation produces a collision, the system retries up to 5 times and ultimately returns a unique code. If 5 consecutive collisions occur, a monitoring alert is triggered and `server_error` is returned to the client.
- **AC-PP-38:** The `averageMMR` in the party queue entry reflects each member's MMR as read at queue entry time, not at party join time — verified by modifying a member's MMR between join and queue and confirming the updated value is used.

---

*End of Document*
