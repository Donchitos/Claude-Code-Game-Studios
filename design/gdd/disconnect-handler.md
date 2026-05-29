# Disconnect Handler — Game Design Document
> **System**: Disconnect Handler
> **Priority**: VS
> **Layer**: Core Gameplay
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

The Disconnect Handler is the server-side system that **detects, classifies, and responds to player disconnections during an active match**. It owns the gap between "socket gone" and "match resolved": every decision about what happens to a player's slot, their character, and the match itself when a network drop occurs lives here.

### What This System Owns

- **Disconnect detection**: receiving the `disconnect` signal from the Real-time Transport layer and extracting the context needed to act (session, player, reason, timestamp).
- **Reconnect window management**: holding a disconnected player's slot open for `RECONNECT_GRACE_PERIOD_MS` and marking their character `INACTIVE` so the match continues safely without them.
- **INACTIVE character rules**: defining how a frozen character behaves — hit detection exclusion, movement freeze, continued zone damage exposure — during the window.
- **Per-mode disconnect response**: determining whether to continue the match, fill the slot with a bot, or abandon the session, based on game mode and current player composition.
- **Grace period expiry handling**: permanently eliminating a disconnected character if no reconnect arrives before the window closes.
- **Abandonment triggering**: emitting the session-abandoned signal to the Session Manager when the remaining player composition makes continuation impossible or unfair.
- **Reconnect coordination**: handing off to the Reconnect/Resume System when a player returns within the window, and transitioning the character from `INACTIVE` back to `ACTIVE`.

### What This System Does NOT Own

- Socket.io connection lifecycle (owned by Real-time Transport).
- Session creation, state transitions, or persistence (owned by Session Manager).
- Bot behavior, pathfinding, or AI decision-making (owned by Bot/Fallback AI).
- MMR adjustment logic on abandonment (owned by MMR/Ranked System, triggered by Match Flow's abandonment signal).
- State snapshot reconstruction on reconnect (owned by Reconnect/Resume System).
- Leaver penalty calculations (deferred post-MVP; tracked by Analytics for future design).

### Why This System Is a First-Class Concern

Mobile networks disconnect frequently. Cellular handoffs, backgrounding the app, and tunnel dead-zones are not rare events — they are the daily reality for BRAWLZONE's audience. A system that treats disconnects as exceptional errors will produce a game that feels broken most of the time. The Disconnect Handler treats drops as an ordinary match event with well-defined, fair, and predictable outcomes.

---

## 2. Player Fantasy

### The Disconnecting Player

The worst mobile gaming experience is dropping out of a match and returning to find the game has moved on without giving you a chance to rejoin — or worse, punishing you with a loss and MMR damage for something your network did to you.

The fantasy for the disconnecting player is:

> "I dropped for a few seconds — my phone hit a dead zone in the subway — but the game held my spot. I tapped back in, the screen snapped to the current state, and I was back in the fight. My team didn't lose because of me."

Within `RECONNECT_GRACE_PERIOD_MS` (30 seconds), the player should feel that the game is **waiting for them**, not abandoning them. The slot is theirs. Their character is frozen in place, not being farmed by opponents. The game is giving them a fair shot to return.

If they cannot return in time, the resolution should feel **clear and final**, not ambiguous. A player who misses the window should see a clean "match ended while you were disconnected" result — not a spinning screen or a silent lobby redirect.

### The Remaining Connected Players

The connected players' frustration is real too. Playing a 3v3 match while the opposing team has a frozen character blocking a doorway, or waiting forever for a 1v1 opponent who clearly isn't coming back, is a broken experience.

The fantasy for connected players is:

> "A player dropped, but the game handled it fairly. In my 1v1, I was awarded the win right away — no waiting. In the FFA, the bot took over cleanly. In the 3v3, we played 3v2 — not ideal, but the slot was eventually eliminated and the match resolved. The game didn't cheat me and didn't waste my time."

### The Mobile Network Reality

No disconnect handling design is "nice to have" on mobile — it is the floor of acceptable quality. A BRAWLZONE match that falls apart every time a player's phone briefly loses signal is not a competitive mobile game; it is a frustrating prototype. This system is the reason matches can be trusted to complete.

---

## 3. Detailed Rules

### 3.1 Disconnect Detection

The Real-time Transport layer receives a Socket.io `disconnect` event for every socket that goes offline. When this event fires for a socket that belongs to a player in an active session, the transport layer emits an internal `player_disconnected` notification to the Disconnect Handler.

The notification payload is:

```typescript
interface PlayerDisconnectedEvent {
  sessionId: string;
  playerId: string;
  socketId: string;
  disconnectReason: string;   // Socket.io disconnect reason string
  timestamp: number;           // Unix epoch ms; server clock
}
```

The Disconnect Handler only acts on disconnects for sessions in state `active`. Disconnects during `character_select` or `waiting_for_players` are handled by Session Manager's own grace period rules and do not reach this system.

#### Detection Source: Transport vs. Timeout

Two paths can trigger the Disconnect Handler:

| Path | Condition | Latency |
|---|---|---|
| Immediate | Socket.io `disconnect` event received | ~0ms after TCP close |
| Inferred | Real-time Transport exhausts 5 auto-reconnect attempts (within 30s) | Up to 30s |

In both cases the same `player_disconnected` event is emitted to the Disconnect Handler. The handler does not distinguish between "socket closed cleanly" and "reconnect attempts exhausted" — both initiate the same grace period window.

---

### 3.2 Reconnect Window

When a `player_disconnected` event is received for a player in an active session, the Disconnect Handler:

1. Records the `disconnectTimestamp` for the player in the in-memory session state (Redis ephemeral store).
2. Sets the player's character state to `INACTIVE`.
3. Starts a `RECONNECT_GRACE_PERIOD_MS` countdown timer (default: 30 000ms).
4. Notifies all other players in the session via `player_inactive` event:

```typescript
interface PlayerInactiveEvent {
  playerId: string;
  characterId: string;
  reason: 'disconnect';
  gracePeriodExpiresAt: number;  // Unix epoch ms; for client countdown UI
}
```

The slot remains held open. No replacement, no elimination, no score change occurs until the grace period expires or the player reconnects, whichever comes first.

**Exception — 1v1 Duel:** The grace period does NOT apply in 1v1. See Section 3.4.

---

### 3.3 INACTIVE Character Rules

While a character is in state `INACTIVE`, the following rules apply:

| Behavior | Rule |
|---|---|
| Movement | Character freezes at last known position. No velocity, no drifting. |
| Actions | Character cannot attack, use abilities, or interact with objects. |
| Hit detection | Character is excluded from all ability and projectile hit checks. INACTIVE characters cannot receive ability damage. |
| Zone damage | Character continues to take zone / shrinking-ring damage. Map pressure applies regardless of connection state. |
| Collision | Character remains a solid collision object (blocks movement pathing). |
| HUD visibility | INACTIVE character is shown to all players with a disconnected indicator. |
| Scoring | INACTIVE character does not score points, assist kills, or earn resources. |

**Rationale for INACTIVE invulnerability:** An INACTIVE character cannot dodge, block, or respond to attacks. Allowing ability damage during the window would enable hit-farming — intentionally targeting a helpless character for easy kills or charge. The zone damage exception is preserved because the zone is a systemic map mechanic, not a player-directed action; it represents the passage of time and map pressure, which applies to everyone regardless of connection state.

---

### 3.4 Per-Mode Disconnect Response

#### 3.4.1 1v1 Duel

**Connected player wins immediately** upon disconnect detection. There is no grace period for reconnect in 1v1.

**Rationale:** A 1v1 match is unplayable without both players. Unlike 3v3 or FFA, there are no other participants to continue the match. Holding a grace period in 1v1 means the connected player waits 30 seconds doing nothing. That is not a fair or fun outcome. The connected player did nothing wrong; they win.

**Simultaneous disconnect exception:** If both players disconnect within `SIMULTANEOUS_DISCONNECT_WINDOW_MS` (default: 100ms) of each other (comparing server-received timestamps), neither player wins. The session is abandoned. No MMR change for either player. See Section 5.1.

**Event emitted on 1v1 disconnect:**

```typescript
interface MatchEndedEvent {
  sessionId: string;
  reason: 'opponent_disconnected';
  winnerId: string;           // the connected player
  loserId: string;            // the disconnected player
  mmrApplied: boolean;        // true — normal MMR applies
}
```

---

#### 3.4.2 3v3 Squad Brawl

**Disconnected player's character goes `INACTIVE`.** Match continues with the remaining active players.

**No bot fill at MVP.** The effective team size drops to 2v3 (or lower). This is a known bad experience that is accepted at MVP and is prioritized for post-MVP resolution.

**Partial team disconnect:** If one or two players on a team disconnect, the remaining teammate(s) continue. The INACTIVE characters are frozen at their last position.

**Full team disconnect:** If all three players on one team disconnect (all three `INACTIVE`), the match is abandoned immediately — no grace period countdown needed for the final player, since no active team remains to contest the match. Session state transitions to `abandoned`. No MMR, no rewards for any participant.

**Grace period expiry (individual player, 3v3):**
- If the disconnected player does not return within `RECONNECT_GRACE_PERIOD_MS`, their character is **permanently eliminated** as if their HP reached 0.
- An `elimination_event` is emitted with `reason: 'disconnect_timeout'`.
- If the match was subsequently won by the opposing team after this elimination, normal MMR applies to all remaining active players.
- The disconnected player receives **no MMR penalty** if the match was abandoned; receives a **loss MMR delta** (calculated as if they participated normally) if their team loses with the match continuing.

**Event emitted on full-team disconnect:**

```typescript
interface SessionAbandonedEvent {
  sessionId: string;
  reason: 'all_team_players_disconnected';
  affectedTeam: 'team_a' | 'team_b';
}
```

---

#### 3.4.3 8-Player FFA

**Disconnected player's character goes `INACTIVE`.** Match continues.

**Bot fill (conditional):**
- If `botFillEnabled` Remote Config flag is `true`: after `BOT_FILL_DELAY_MS` (default: 5 000ms) the Disconnect Handler requests a bot slot from the Bot/Fallback AI system. The bot inherits the disconnected player's position, remaining HP, and current zone exposure.
- If `botFillEnabled` is `false` (default at MVP): the slot remains `INACTIVE` until grace period expiry, then the character is permanently eliminated.

**Grace period and bot fill interaction:**
- If the player reconnects within `RECONNECT_GRACE_PERIOD_MS` AND before the bot has been spawned (i.e., within `BOT_FILL_DELAY_MS`): the slot is returned to the player; no bot is spawned.
- If the player reconnects within `RECONNECT_GRACE_PERIOD_MS` BUT after the bot has already spawned: the bot is removed, the player's character is restored to their current position/HP at the moment of bot removal, and the Reconnect/Resume System handles state reconciliation.
- If the player does not reconnect within `RECONNECT_GRACE_PERIOD_MS`: the bot (if enabled) continues until it is eliminated by game logic; if bot fill is disabled, the character is permanently eliminated.

**Full FFA elimination:** If all remaining active players disconnect simultaneously, the session is abandoned. If only one active human player remains (all others are INACTIVE or bots), the match continues to its natural end — the human player can win a bot-filled FFA.

**Minimum active players for FFA abandonment:** `MIN_ACTIVE_PLAYERS_FFA` = 1. If fewer than 1 human player is active and bot fill is disabled, the session is abandoned.

---

### 3.5 Reconnect Within Grace Period

If the player's socket reconnects and the Reconnect/Resume System successfully authenticates and validates the reconnect:

1. Disconnect Handler receives a `player_reconnected` internal event from the Reconnect/Resume System.
2. The grace period timer is cancelled.
3. Character state transitions from `INACTIVE` to `ACTIVE`.
4. A `player_active` event is broadcast to all players in the session.
5. The Reconnect/Resume System delivers the authoritative state snapshot to the returning client.
6. If in FFA with `botFillEnabled` and a bot was spawned: the Disconnect Handler sends a `remove_bot` request to the Bot/Fallback AI system and restores the player's character at the bot's current position/HP.

The Disconnect Handler does not perform state reconciliation itself — it delegates to the Reconnect/Resume System.

---

### 3.6 Grace Period Expiry Without Reconnect

When the `RECONNECT_GRACE_PERIOD_MS` timer expires and no `player_reconnected` event has been received:

**1v1 Duel:** Not applicable — match already ended at the moment of disconnect.

**3v3 Squad Brawl:**
- Emit `elimination_event` for the disconnected player's character with `reason: 'disconnect_timeout'`.
- Character is removed from the active match as if their HP reached 0.
- Match continues with remaining active players.
- Emit `player_eliminated_disconnect` to all session participants.

**8-Player FFA:**
- Emit `elimination_event` for the disconnected player's character with `reason: 'disconnect_timeout'` (if bot fill is disabled or bot has not yet been spawned).
- If `botFillEnabled` and `BOT_FILL_DELAY_MS` has already elapsed: the bot is already in the slot; character ownership is permanently transferred to the bot until eliminated by match logic.
- If `botFillEnabled` and `BOT_FILL_DELAY_MS` has NOT yet elapsed at expiry: spawn bot immediately (skip the remaining delay).

---

### 3.7 Abandonment Conditions Summary

| Mode | Abandonment Condition |
|---|---|
| 1v1 Duel | Both players disconnect within `SIMULTANEOUS_DISCONNECT_WINDOW_MS` |
| 3v3 Squad Brawl | All players on one team are `INACTIVE` simultaneously |
| 8-Player FFA | All human players are `INACTIVE` simultaneously AND `botFillEnabled` = false; OR fewer than `MIN_ACTIVE_PLAYERS_FFA` human players remain |

On abandonment, the Disconnect Handler emits `session_abandoned` to the Session Manager. The Session Manager transitions the session to `abandoned`. Match Flow receives the abandonment event and suppresses MMR, reward, and XP grants for all participants.

---

### 3.8 Disconnect Rate Tracking

At MVP, there is **no explicit leaver penalty system**. Disconnect events are forwarded to Analytics with the following payload:

```typescript
interface DisconnectAnalyticsEvent {
  sessionId: string;
  playerId: string;
  gameMode: 'duel_1v1' | 'squad_3v3' | 'ffa_8';
  disconnectReason: string;
  matchPhaseAtDisconnect: 'active';
  reconnected: boolean;
  reconnectLatencyMs: number | null;
  gracePeriodExpired: boolean;
}
```

Aggregate disconnect rate by player, mode, and time-of-day will inform the leaver penalty design in a post-MVP pass.

---

## 4. Formulas

### 4.1 Reconnect Window Timer

```
windowExpiresAt = disconnectTimestamp + RECONNECT_GRACE_PERIOD_MS

reconnectAllowed = (reconnectTimestamp <= windowExpiresAt)
```

| Variable | Type | Default | Description |
|---|---|---|---|
| `disconnectTimestamp` | `number` (ms) | — | Server-clock time of `player_disconnected` event receipt |
| `RECONNECT_GRACE_PERIOD_MS` | `number` (ms) | 30 000 | Duration the slot is held open after disconnect |
| `reconnectTimestamp` | `number` (ms) | — | Server-clock time of successful `player_reconnected` event |
| `windowExpiresAt` | `number` (ms) | — | Computed expiry; inclusive boundary |

**Inclusive boundary rule:** A reconnect that arrives exactly at `windowExpiresAt` (i.e., `reconnectTimestamp === windowExpiresAt`) is accepted. The reconnect wins the tie.

**Example:**
- `disconnectTimestamp` = 1 000 000ms
- `RECONNECT_GRACE_PERIOD_MS` = 30 000ms
- `windowExpiresAt` = 1 030 000ms
- Reconnect at 1 029 999ms → **accepted**
- Reconnect at 1 030 000ms → **accepted** (inclusive)
- Reconnect at 1 030 001ms → **rejected**

---

### 4.2 Bot Fill Delay

```
botFillAt = disconnectTimestamp + BOT_FILL_DELAY_MS

botShouldSpawn = (currentTime >= botFillAt)
               AND (botFillEnabled == true)
               AND (playerHasNotReconnected == true)
               AND (gracePeriodActive == true)
```

| Variable | Type | Default | Description |
|---|---|---|---|
| `BOT_FILL_DELAY_MS` | `number` (ms) | 5 000 | Wait time before spawning bot in FFA |
| `botFillEnabled` | `boolean` | `false` | Remote Config gate; FFA-only |

**Example:**
- `disconnectTimestamp` = 1 000 000ms
- `BOT_FILL_DELAY_MS` = 5 000ms
- `botFillAt` = 1 005 000ms
- At 1 004 999ms: bot has NOT spawned yet; player can reconnect without bot handoff
- At 1 005 000ms: bot spawns (if conditions met)
- At 1 020 000ms: player reconnects → bot removed, player restored

---

### 4.3 Simultaneous Disconnect Window

```
areSimultaneous = |timestampA - timestampB| <= SIMULTANEOUS_DISCONNECT_WINDOW_MS
```

| Variable | Type | Default | Description |
|---|---|---|---|
| `timestampA` | `number` (ms) | — | Server-received disconnect time for player A |
| `timestampB` | `number` (ms) | — | Server-received disconnect time for player B |
| `SIMULTANEOUS_DISCONNECT_WINDOW_MS` | `number` (ms) | 100 | Max gap to classify as simultaneous; applies to 1v1 only |

**Example:**
- Player A disconnects at 1 000 000ms
- Player B disconnects at 1 000 085ms
- |1 000 000 − 1 000 085| = 85ms ≤ 100ms → **simultaneous; match abandoned**

- Player A disconnects at 1 000 000ms
- Player B disconnects at 1 000 150ms
- |1 000 000 − 1 000 150| = 150ms > 100ms → **not simultaneous; Player B wins**

---

### 4.4 Minimum Active Players Per Mode

Abandonment is triggered when active human players fall below this threshold:

| Mode | `MIN_ACTIVE_PLAYERS` | Notes |
|---|---|---|
| 1v1 Duel | 2 (both players) | Handled by immediate win rule, not this threshold |
| 3v3 Squad Brawl | 1 active team (≥ 1 player on each side) | Full-team disconnect triggers abandonment |
| 8-Player FFA | 1 | 1 human player vs. bots (or INACTIVE) is a valid match state |

Formally, for 3v3:

```
teamAActive = count of players on team_a with state != INACTIVE
teamBActive = count of players on team_b with state != INACTIVE

shouldAbandon_3v3 = (teamAActive == 0) OR (teamBActive == 0)
```

For FFA (bot fill disabled):

```
humanActive = count of players in session with state == ACTIVE and isBot == false

shouldAbandon_FFA = (humanActive < MIN_ACTIVE_PLAYERS_FFA)
```

---

## 5. Edge Cases

### 5.1 Both 1v1 Players Disconnect Simultaneously (< 100ms Apart)

**Scenario:** Both sockets drop within `SIMULTANEOUS_DISCONNECT_WINDOW_MS` of each other. Could be a shared network event (server-side blip), both players backgrounding their apps simultaneously, or genuine coincidence.

**Resolution:**
1. Both `player_disconnected` events arrive at the Disconnect Handler with server timestamps.
2. The handler computes `|timestampA - timestampB|`.
3. If ≤ `SIMULTANEOUS_DISCONNECT_WINDOW_MS`: emit `session_abandoned` with `reason: 'simultaneous_disconnect'`. No winner declared. No MMR change for either player. No leaver flag.
4. If > `SIMULTANEOUS_DISCONNECT_WINDOW_MS`: the second-to-disconnect player is treated as a standard 1v1 disconnect; the first-to-disconnect player's opponent wins immediately.

**Why not give the second player the win in the edge case?** The 100ms window is at the boundary of server-observable resolution. A shared network event could produce two "disconnects" that are causally simultaneous but arrive with up to ~80ms spread due to routing asymmetry. Declaring a winner in this scenario would be arbitrary and would feel unjust to both players.

---

### 5.2 Disconnect at the Exact Moment of Elimination

**Scenario:** A player's HP reaches 0 (elimination event) and their socket disconnects within the same server tick (50ms tick at 20Hz).

**Resolution:** The elimination event takes precedence. If the `elimination_event` is processed in the same tick as the `player_disconnected` event, the server applies elimination logic first. The `player_disconnected` event is discarded for this player because their character is already in `ELIMINATED` state, not `ACTIVE`. No grace period is started. No INACTIVE window opens.

**Implementation note:** The Match Server processes elimination before emitting disconnect events. If both arrive in the same tick, the Match Server's tick processing order must guarantee that HP-to-zero elimination resolves before the Disconnect Handler processes the socket event. The `disconnect` event must be queued, not interrupt the tick loop.

---

### 5.3 Reconnect Arrives Exactly at Grace Period Expiry

**Scenario:** The reconnect authentication completes at `reconnectTimestamp == windowExpiresAt`.

**Resolution:** Reconnect is accepted. The boundary is **inclusive**. The `reconnectAllowed` formula uses `<=`. The grace period timer is cancelled, the character transitions to `ACTIVE`, and the match continues.

**Implementation note:** The timer expiry callback and the reconnect acceptance path must be mutually exclusive (mutex or atomic check on the session state). If both fire simultaneously (timer fires at the same instant as reconnect arrives), the reconnect wins. The implementation must ensure that the timer callback checks whether the player has already reconnected before executing expiry logic.

---

### 5.4 Server Crash During Grace Period

**Scenario:** The game server crashes while one or more players are in the grace period window. The Disconnect Handler's in-memory state (grace period timers, INACTIVE flags) is lost.

**Resolution:** The Disconnect Handler holds only **ephemeral state** — no grace period state is written to PostgreSQL. On server crash, the Session Manager detects the heartbeat timeout and transitions the session to `abandoned`. All players receive a clean session-ended notification. No reconnect attempt succeeds because the session no longer exists on the restored server.

**Consequence:** Players in the grace period window at the time of server crash receive an `abandoned` result (no MMR change, no rewards). This is the correct outcome — the session cannot be meaningfully restored.

**Rationale for no persistent grace-period state:** Persisting timers to Redis and attempting mid-grace-period recovery would add significant complexity for a rare event (server crash). The simpler contract — crash = abandon — is acceptable at MVP. Post-MVP, stateful session recovery could be revisited.

---

### 5.5 Disconnect During Character Select Phase

**Scenario:** A player's socket drops while the session is in `character_select` state.

**Resolution:** **Not handled by the Disconnect Handler.** Character select disconnects are entirely within Session Manager's jurisdiction. The Session Manager maintains its own grace period for pre-match readiness (documented in session-manager.md). The Disconnect Handler only activates when the session is in `active` state.

---

### 5.6 Reconnect Attempt After Grace Period Has Expired

**Scenario:** A player attempts to reconnect after `windowExpiresAt` has passed. Their character has already been eliminated or the match has ended.

**Resolution:** The Reconnect/Resume System rejects the reconnect attempt and returns an error to the client indicating `reconnect_window_expired`. The client is redirected to the post-match results screen with the final match state. If the match is still ongoing (e.g., 3v3 with other players still active), the player receives the match result as an observer, not as a participant.

---

### 5.7 Bot Spawned, Then Player Reconnects After Bot Earns Points

**Scenario (FFA, botFillEnabled = true):** The bot fills the slot, earns elimination credit or score, then the player reconnects within the grace period.

**Resolution:** On bot removal, the player is restored to the **bot's current position and HP**. Points and eliminations earned by the bot are credited to the bot's slot (which is now the player's slot). The player inherits the bot's in-match score for the remainder of the match. This prevents a player from disconnecting intentionally to have a bot "warm up" the slot and then reclaiming clean stats — the bot's actions belong to the slot, not separately to the player.

---

### 5.8 Multiple Rapid Disconnects (Oscillating Connection)

**Scenario:** A player disconnects, triggers the grace period, reconnects at second 20, disconnects again at second 25, and attempts to reconnect again.

**Resolution:** Each disconnect starts a fresh `RECONNECT_GRACE_PERIOD_MS` window from the new `disconnectTimestamp`. There is no "accumulated timeout" penalty at MVP. Each reconnect within the window is accepted. Analytics tracks the reconnect count per session per player, which informs future oscillation-detection and penalty design.

---

## 6. Dependencies

### 6.1 Upstream (Systems This System Depends On)

| System | What Is Consumed | Contract |
|---|---|---|
| **Session Manager** | Notifies Disconnect Handler when a session transitions to `active`; provides session metadata (mode, player list, team assignments). Disconnect Handler only processes events for sessions in `active` state. | Session Manager emits `session_active` on state transition. Session Manager also receives `session_abandoned` signals back from Disconnect Handler. |
| **Real-time Transport** | Delivers `player_disconnected` event when a Socket.io `disconnect` fires for a player in an active session. Delivers `player_reconnected` event when a socket re-authenticates for a player in grace period. | Transport emits events synchronously on socket lifecycle change. One-socket-per-user rule ensures no stale sockets produce phantom disconnect events. |

### 6.2 Downstream (Systems That Consume This System)

| System | What Is Provided | Contract |
|---|---|---|
| **Bot/Fallback AI** | `spawn_bot` request with `{sessionId, playerId, position, currentHp, zoneState}` after `BOT_FILL_DELAY_MS` in FFA when `botFillEnabled = true`. `remove_bot` request when player reconnects. | Bot/Fallback AI must accept `spawn_bot` and `remove_bot` commands. Bot inherits the player's positional and HP state. |
| **Reconnect/Resume System** | Notifies that a player slot is in grace period and eligible for reconnect. Accepts `player_reconnected` events. Coordinates state snapshot delivery to returning client. | Reconnect/Resume System owns state reconstruction; Disconnect Handler owns slot eligibility and grace period timer. |
| **Match Flow** | Emits `session_abandoned` signal when abandonment conditions are met. Match Flow suppresses MMR and reward fan-out on abandonment. | Match Flow listens for `session_abandoned` from Disconnect Handler (routed through Session Manager). |
| **Analytics** | Emits `disconnect_analytics_event` for every disconnect, including outcome (reconnected, grace expired, abandoned). | Analytics is fire-and-forget; failure to deliver does not affect match state. |

### 6.3 Dependency Diagram

```
Session Manager ──────────► Disconnect Handler ──────────► Bot/Fallback AI
Real-time Transport ────────►                  ──────────► Reconnect/Resume System
                                               ──────────► Match Flow (abandonment)
                                               ──────────► Analytics
```

---

## 7. Tuning Knobs

All values are Remote Config–eligible unless noted. Changes take effect on the next server-side disconnect event; no server restart required.

| Knob | Constant Name | Default | Safe Range | Effect on Gameplay |
|---|---|---|---|---|
| **Reconnect grace period** | `RECONNECT_GRACE_PERIOD_MS` | 30 000ms | 15 000 – 60 000ms | Longer = more lenient for reconnecting player, more waiting time for connected players. Must not exceed Real-time Transport's client-side 30s reconnect window (matching windows ensures both systems align). |
| **Bot fill delay** | `BOT_FILL_DELAY_MS` | 5 000ms | 2 000 – 15 000ms | Shorter = bot appears faster, reducing impact of FFA slot drop; longer = more time for player to reconnect before bot spawns. |
| **Simultaneous disconnect window** | `SIMULTANEOUS_DISCONNECT_WINDOW_MS` | 100ms | 50 – 200ms | Narrower = more "wins" declared on edge-case disconnects; wider = more abandonments. Should not exceed typical server-to-client routing asymmetry (~80ms). |
| **Minimum active FFA players** | `MIN_ACTIVE_PLAYERS_FFA` | 1 | 1 – 3 | Lower = more matches complete even with heavy drops; higher = faster abandonment preserving match quality. Bot fill interacts: with bots enabled, bots count against this check only if `botCountsAsActivePlayer = true` (default: false). |
| **Bot fill enabled** | `botFillEnabled` | `false` | `true` / `false` | Remote Config boolean gate. FFA only. Changing to `true` mid-session has no effect; applies to new disconnect events only. |

### Tuning Interactions

- `RECONNECT_GRACE_PERIOD_MS` and `BOT_FILL_DELAY_MS` must satisfy: `BOT_FILL_DELAY_MS < RECONNECT_GRACE_PERIOD_MS`. If equal or inverted, bots would spawn after the reconnect window closes, which is a nonsensical state. A server-side validation check rejects configurations that violate this invariant.
- `RECONNECT_GRACE_PERIOD_MS` should equal the Real-time Transport's `RECONNECT_WINDOW_MS` (30 000ms). If the transport-layer window is shorter than the Disconnect Handler window, the transport will stop retrying before the slot expires — the slot will sit open with no possible reconnect, wasting the remaining window. If the handler window is shorter, the slot expires while the transport is still retrying — the returning socket will be rejected even though the client thinks reconnect is possible. Keep these values synchronized.

---

## 8. Acceptance Criteria

### AC-1: 1v1 Disconnect — Immediate Win

**Given** a 1v1 Duel match is active  
**When** one player's socket disconnects  
**Then** the connected player is declared the winner within one server tick (≤ 50ms)  
**And** an MMR delta is applied as if the disconnected player lost normally  
**And** no grace period timer is started  
**And** the session transitions to `ended`

---

### AC-2: 1v1 Simultaneous Disconnect — Abandon

**Given** a 1v1 Duel match is active  
**When** both players disconnect within `SIMULTANEOUS_DISCONNECT_WINDOW_MS` of each other (server timestamps)  
**Then** the session is abandoned  
**And** no winner is declared  
**And** no MMR change is applied to either player  
**And** both players receive an `abandoned` result screen

---

### AC-3: 3v3 Disconnect — Character Goes INACTIVE

**Given** a 3v3 Squad Brawl match is active  
**When** one player disconnects  
**Then** that player's character transitions to `INACTIVE` within one server tick  
**And** the character stops moving at its last known position  
**And** the character cannot receive ability damage  
**And** the character continues to receive zone damage  
**And** all remaining players receive a `player_inactive` event with `gracePeriodExpiresAt`  
**And** the match continues without interruption

---

### AC-4: 3v3 Full Team Disconnect — Abandon

**Given** a 3v3 Squad Brawl match is active  
**When** all three players on one team disconnect (all three `INACTIVE`)  
**Then** the session is abandoned immediately  
**And** no MMR or rewards are granted to any participant  
**And** all players receive an `abandoned` result screen

---

### AC-5: FFA Disconnect — Bot Fill

**Given** an 8-player FFA match is active  
**And** `botFillEnabled` = true  
**When** one player disconnects  
**Then** that player's character transitions to `INACTIVE` within one server tick  
**And** after `BOT_FILL_DELAY_MS`, a bot is spawned at the character's last position with the character's current HP  
**And** the bot operates independently for the remainder of the match or until the player reconnects

---

### AC-6: FFA Disconnect — No Bot Fill

**Given** an 8-player FFA match is active  
**And** `botFillEnabled` = false  
**When** one player disconnects  
**Then** that player's character transitions to `INACTIVE` within one server tick  
**And** no bot is spawned  
**And** after `RECONNECT_GRACE_PERIOD_MS` without reconnect, the character is permanently eliminated with `reason: 'disconnect_timeout'`

---

### AC-7: Reconnect Within Grace Period

**Given** a player has disconnected and their grace period is active  
**When** the player's socket reconnects and the Reconnect/Resume System authenticates them within `RECONNECT_GRACE_PERIOD_MS`  
**Then** the grace period timer is cancelled  
**And** the character transitions from `INACTIVE` to `ACTIVE`  
**And** all session participants receive a `player_active` event  
**And** the player receives the authoritative match state snapshot from the Reconnect/Resume System

---

### AC-8: Grace Period Expiry Without Reconnect (3v3)

**Given** a player has disconnected from a 3v3 Squad Brawl match  
**When** `RECONNECT_GRACE_PERIOD_MS` elapses without reconnect  
**Then** an `elimination_event` is emitted with `reason: 'disconnect_timeout'`  
**And** the character is removed from the active match  
**And** the match continues with remaining active players

---

### AC-9: Grace Period Inclusive Boundary

**Given** a player has disconnected and their `windowExpiresAt` is timestamp T  
**When** a reconnect arrives at exactly timestamp T (server clock)  
**Then** the reconnect is accepted  
**And** the grace period timer is cancelled  
**And** the character transitions to `ACTIVE`

---

### AC-10: INACTIVE Character Hit Detection Exclusion

**Given** a player's character is in `INACTIVE` state  
**When** an ability or projectile is fired by an active player and its trajectory intersects the INACTIVE character's position  
**Then** the hit detection system reports no collision with the INACTIVE character  
**And** no damage is applied to the INACTIVE character  
**And** no kill credit is awarded to the attacking player

---

### AC-11: Simultaneous Disconnect Window (Numeric)

**Given** a 1v1 Duel is active  
**When** server receives disconnect for Player A at time T and disconnect for Player B at time T + 100ms  
**Then** `|T - (T + 100)| = 100ms ≤ SIMULTANEOUS_DISCONNECT_WINDOW_MS` → match abandoned  
**When** server receives disconnect for Player A at time T and disconnect for Player B at time T + 101ms  
**Then** `|T - (T + 101)| = 101ms > SIMULTANEOUS_DISCONNECT_WINDOW_MS` → Player B wins

---

### AC-12: Disconnect Analytics Event

**Given** any player disconnect occurs during an active match (any mode)  
**Then** a `disconnect_analytics_event` is emitted to Analytics  
**And** the payload includes `sessionId`, `playerId`, `gameMode`, `disconnectReason`, `reconnected` (boolean), `gracePeriodExpired` (boolean)  
**And** the event is emitted regardless of whether the disconnect results in an abandon, a win, or a grace period

---

*End of Document*
