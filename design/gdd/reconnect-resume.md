# Reconnect / Resume System — Game Design Document
> **System**: Reconnect / Resume System
> **Priority**: VS ⚠️
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

The Reconnect / Resume System owns the complete protocol for restoring a player's participation in an active match or character-select session after a socket disconnection. It sits at the intersection of the Real-time Transport's reconnect mechanics (which own the socket-level retry loop) and the Session Manager's grace-period window (which holds a player's slot open on the server). The Reconnect / Resume System is the coordination layer that bridges those two concerns and defines the exact handshake, the state restoration protocol, and the client-side recovery UX.

### What This System Owns

- **The reconnect handshake protocol**: the exact sequence of client re-authentication, server session lookup, and admission or rejection — including the fields in the `reconnect_ack` and `reconnect_rejected` payloads.
- **State restoration from snapshot**: on a successful reconnect, the client receives a full `MatchState` snapshot and uses it to reinstate the correct HUD state, character-select lock state, or navigation target. This system defines which fields are mandatory in that snapshot and how each session phase maps to a client-side restoration action.
- **Client-side reconnect UX**: the "Reconnecting…" overlay, the attempt counter, and the cancel path (give up and return to main menu).
- **Post-reconnect input behaviour**: the lenient staleness window that the Match Server applies for the first two ticks after reconnect, allowing the client's input pipeline to recover without immediate input discards.
- **Coordination with the Disconnect Handler's grace period**: the system defines the inclusive boundary condition at grace period expiry and the `reconnect_rejected` response paths.
- **Character / Deck Select phase recovery**: the `isConfirmed` field in the `reconnect_ack` payload resolves the locked-vs-editable state that Character / Deck Select must display on reconnect. This directly addresses Character / Deck Select Risk 2.

### What This System Does NOT Own

- The socket-level reconnection loop (backoff delays, attempt counts, connection establishment): owned by Real-time Transport GDD §3.9.
- The decision to abandon a session when the grace period expires: owned by the Disconnect Handler and Session Manager.
- JWT issuance or token storage: owned by the Authentication system.
- In-match game simulation or state advancement during the reconnect window: the Match Server continues ticking at 20 Hz regardless of whether the reconnecting client has completed the handshake.
- Post-match results or MMR update: owned by Match Flow and MMR / Ranked system.

### Core Design Principle

**Restore from snapshot, never reconstruct from events.** When a player reconnects, the server sends a complete, authoritative `MatchState` snapshot. The client discards any local state it may have accumulated during the disconnect, applies the snapshot wholesale, and resumes from there. Event-log replay is explicitly prohibited: it is fragile, order-dependent, and would require the server to buffer an unbounded event log per disconnected player. The snapshot model is simpler, safer, and already mandated by the Match Server GDD (§3.5 "Full State Snapshot on Reconnect") and the Map / Arena hard requirement (snapshot must include `zone_elapsed_ms` and obstacle states).

---

## 2. Player Fantasy

### Coming Back to the Fight

Picture the most common reconnect scenario: a mobile player walks into an elevator mid-match. The connection drops. On the client, a translucent overlay slides in — "Reconnecting…" — with a small attempt counter ticking quietly in the corner. The match is still happening; the player knows it. There is a cancel button available but they do not tap it yet. The phone finds signal. The overlay resolves. Their character is still alive, in the position the server left them, HP intact or perhaps a little lower. The HUD is live. They jump straight back into the fight.

That is the fantasy: **a stumble, not a fall**. The disconnect was an interruption, not a loss.

The relief when the overlay resolves is proportional to the stakes. In a tight Duel with the opponent at low HP, coming back matters enormously. The player's pulse quickens when the HUD reappears. That emotional beat — the "I'm back" moment — is what this system is designed to deliver cleanly, every time.

### The Frustration of Missing the Window

The inverse fantasy is equally important to design for. If a player cannot reconnect in time, the system must tell them honestly and quickly: "You were removed from the match." Not a dead screen. Not a spinning loader that never resolves. Not a silent return to the main menu with no explanation. The rejection message names the reason (`grace_period_expired`, `session_ended`, `match_not_found`). If the session ended while they were gone, they are sent to the results screen rather than main menu — the match still happened, and they deserve to see the outcome.

There is dignity in a well-handled failure. A clean `reconnect_rejected` path that returns the player to an appropriate screen is far better than an ambiguous stuck state.

### The Character Select Recovery

The third scenario is less dramatic but equally disruptive: a player disconnects during the character-select phase. When they reconnect, there is a choice: did they already confirm their loadout before the drop? If yes, they land in the locked "Waiting for opponent…" state — their decision stands. If no, they land in the editable select screen with their saved loadout pre-loaded. The `isConfirmed` field in the reconnect payload makes this choice unambiguous. The player never faces a mismatch between what they see and what the server believes their state to be.

---

## 3. Detailed Rules

### 3.1 Reconnect Handshake Protocol

The reconnect handshake is a seven-step sequence. It begins when the client's Socket.io reconnect loop (Real-time Transport GDD §3.9) successfully re-establishes a socket connection after a disconnect.

```
CLIENT                                          SERVER
  │                                               │
  │  1. Socket.io reconnect established           │
  │     (Real-time Transport reconnect loop)      │
  │                                               │
  │  2. Client checks JWT expiry                  │
  │     If expired → silent HTTP refresh first    │
  │     (see §3.2 for JWT path)                   │
  │                                               │
  │  3. emit reconnect_request {                  │
  │       userId,                                 │
  │       correlationId,    // reuses correlation │
  │       matchId,          // last known         │
  │       jwt,              // fresh or existing  │
  │     }                  ──────────────────────►│
  │                                               │
  │                        4. Server validates JWT │
  │                           (signature + expiry) │
  │                                               │
  │                        5. Server checks Redis: │
  │                           player_session:{userId}│
  │                           session:{sessionId} │
  │                           → is grace period   │
  │                             still active?     │
  │                                               │
  │  ◄──────────────────── 6a. reconnect_ack      │
  │     (if session valid)    (full snapshot)     │
  │                                               │
  │  ◄──────────────────── 6b. reconnect_rejected │
  │     (if session ended     (reason code)       │
  │      or grace expired)                        │
  │                                               │
  │  7. Client applies snapshot / handles         │
  │     rejection (see §3.4)                      │
  │                                               │
```

**Step-by-step rules:**

**Step 1 — Socket re-established.** The Socket.io client has completed a TCP/WebSocket handshake. No game-level data has been exchanged yet. This step is entirely owned by Real-time Transport; this system picks up from here.

**Step 2 — JWT pre-flight.** Before emitting `reconnect_request`, the client checks the JWT's `exp` claim against the current client clock. If the token has expired or will expire within `JWT_REFRESH_PREEMPT_MS` (default: 60 000ms), the client performs a silent HTTP token refresh (POST `/auth/refresh`) via the API Client. The socket reconnect proceeds only after a valid token is in hand. If the refresh fails (e.g., refresh token also expired), the reconnect attempt is aborted: the client shows a "Session expired — please log in again" message and navigates to the login screen. This is not counted as a failed reconnect attempt for the purpose of the `MAX_RECONNECT_ATTEMPTS` counter; it is a terminal auth failure.

**Step 3 — Client emits `reconnect_request`.** Payload:

```typescript
interface ReconnectRequest {
  userId: string;           // Authenticated player UUID (from JWT sub claim)
  correlationId: string;    // Reused from the original connection (Real-time Transport GDD §3.9 — reuses correlation ID within 300s)
  matchId: string;          // Last known matchId from before the disconnect (may be stale if session ended)
  jwt: string;              // Valid JWT (refreshed if necessary in Step 2)
}
```

**Step 4 — Server validates JWT.** The server applies the same JWT validation middleware as the initial connection (Real-time Transport GDD §3.2): signature check, `exp` check, Redis blacklist check. If validation fails, the server emits `auth_error { reason: "TOKEN_INVALID" | "TOKEN_EXPIRED" }` and closes the socket. The client handles this as it would any auth error on initial connect — not a game-level reconnect rejection.

**Step 5 — Server checks session state.** After successful JWT validation, the server looks up the player's session:

1. Query Redis: `player_session:{userId}` → `sessionId`. If key does not exist, the player has no active session.
2. Query Redis: `session:{sessionId}` → session object. If key does not exist, the session has expired or been cleaned up.
3. Check `session.state`:
   - `"waiting_for_players"` or `"character_select"` or `"active"`: session is live. Proceed to Step 6a.
   - `"ended"`: match concluded while the player was disconnected. Proceed to Step 6b with `reason: "session_ended"`.
   - `"abandoned"`: session was abandoned. Proceed to Step 6b with `reason: "session_ended"` (no distinction from the client's perspective).
   - Key not found / player has no active session: proceed to Step 6b with `reason: "match_not_found"`.
4. Check grace period: if `session.state === "active"` or `"character_select"`, verify the Disconnect Handler's grace period timer for this player has not expired. If expired (the server's timer fired before this reconnect arrived), proceed to Step 6b with `reason: "grace_period_expired"`.
5. If all checks pass: apply one-socket-per-user dedup (Real-time Transport GDD §3.2, Step 5) — evict any existing zombie socket for this `userId`. Admit the new socket to the Socket.io match room. Mark player as `ACTIVE` in the session state. Proceed to Step 6a.

**Step 6a — Server emits `reconnect_ack`.** See §3.3 for the complete payload specification.

**Step 6b — Server emits `reconnect_rejected`.** Payload:

```typescript
interface ReconnectRejected {
  reason: "session_ended" | "grace_period_expired" | "match_not_found";
  // "session_ended" also carries a resultsPayload for navigation to results screen (see §3.4.3)
  resultsPayload?: MatchResultSummary;  // populated only when reason === "session_ended"
}

interface MatchResultSummary {
  matchId: string;
  sessionId: string;
  winnerId: string | null;
  reason: string;           // e.g. "last_standing", "time_limit"
  playerStats: PlayerEndStats[];
}
```

**Step 7 — Client handles ack or rejection.** See §3.4.

---

### 3.2 JWT Expiry During Reconnect

The JWT expiry scenario is the highest-risk timing edge case in the reconnect flow. It is handled at Step 2 of the handshake, before the socket reconnect is attempted. The sequence is:

```
Client disconnect occurs
       │
       ▼
Real-time Transport backoff timer fires
       │
       ▼
Before socket.connect():
  Check: now() >= jwt.exp - JWT_REFRESH_PREEMPT_MS ?
       │
       ├── No (JWT still valid) → proceed with socket.connect()
       │
       └── Yes (JWT expired or near-expiry)
               │
               ▼
         HTTP POST /auth/refresh
               │
               ├── 200 OK, new JWT → update stored JWT → proceed with socket.connect()
               │
               └── 4xx/5xx (refresh failed)
                       │
                       ▼
                 Abort reconnect attempt.
                 Show "Session expired" screen.
                 Navigate to login.
```

**Important constraint**: the silent HTTP refresh consumes wall-clock time from the `RECONNECT_WINDOW_S` budget (30s). If the refresh is slow (>2s), it narrows the remaining window for socket reconnect attempts. The client must track `elapsed_since_disconnect` and abort the entire reconnect flow if `elapsed_since_disconnect >= RECONNECT_WINDOW_S` even mid-refresh. This prevents a slow refresh from silently exhausting the window.

**Server-side note**: if a client somehow presents an expired JWT in Step 4 despite the client-side Step 2 pre-flight (e.g., clock skew, race condition between refresh response and token check), the server emits `auth_error { reason: "TOKEN_EXPIRED" }`. The client must not retry with the same expired token; it must perform the HTTP refresh before attempting again. The Real-time Transport's reconnect loop must be extended to handle this specific auth_error as a "refresh and retry" signal rather than a terminal failure.

---

### 3.3 The `reconnect_ack` Payload

The `reconnect_ack` is the single most important event in this system. It carries everything the client needs to restore state without relying on any prior local state.

```typescript
interface ReconnectAck {
  // Session and match identity
  sessionId: string;                  // The player's active session UUID
  matchId: string;                    // The active match UUID
  sessionPhase: SessionPhase;         // "character_select" | "active"

  // Full authoritative match state (snapshot, not delta)
  // Required when sessionPhase === "active"
  matchState?: MatchState;            // Full MatchState as defined in Match Server GDD §3.3
                                      // MUST include zone_elapsed_ms and obstacle states
                                      // (Map/Arena hard requirement)

  // Character and deck identity (always present)
  yourCharacterId: string;            // The characterId this player selected or had auto-selected
  yourDeckIds: string[];              // [slot1AbilityId, slot2AbilityId] in order

  // Character select phase state (required when sessionPhase === "character_select")
  isConfirmed: boolean;               // true = player had confirmed before disconnecting;
                                      // false = player had not yet confirmed
                                      // Resolves Character/Deck Select Risk 2

  // Timing metadata
  serverTimestamp: number;            // Unix epoch ms at the moment this ack was generated
  stateAge: number;                   // ms since the matchState snapshot was taken.
                                      // 0 if using live state (process running).
                                      // Up to CHECKPOINT_INTERVAL_SEC * 1000 if using
                                      // Redis checkpoint (process restarted).

  // Post-reconnect leniency signal
  leniencyTicks: number;              // Number of ticks post-reconnect during which the
                                      // Match Server applies lenient input staleness checking.
                                      // Always RECONNECT_LENIENCY_TICKS (default: 2).
}

type SessionPhase = "character_select" | "active";
```

**Field-level requirements:**

| Field | Required When | Notes |
|---|---|---|
| `sessionId` | Always | |
| `matchId` | Always | |
| `sessionPhase` | Always | Drives client-side restoration branch |
| `matchState` | `sessionPhase === "active"` | Full MatchState; never a delta |
| `yourCharacterId` | Always | Set from `session.characterSelections[userId].characterId` |
| `yourDeckIds` | Always | Set from `session.characterSelections[userId].deckId` (resolved to two abilityIds) |
| `isConfirmed` | Always | Server-authoritative; client cannot infer this reliably |
| `serverTimestamp` | Always | Used by client for clock-sync reference |
| `stateAge` | Always | `0` if live process; >0 if from checkpoint. Never omitted. |
| `leniencyTicks` | Always | Client passes this value as metadata; Match Server is authoritative on leniency |

**`matchState` snapshot requirements (from Match Server GDD §3.5):**
- All `PlayerState[]` entries with current `position`, `hp`, `velocity`, `statusEffects`, `abilityCooldowns`, `passiveState`, `isAlive`, `respawnTimer`.
- `ZoneState` with current `currentRadius`, `targetRadius`, `damagePerSec`, `phaseIndex`, `finalHoldActive`, `finalHoldRemainingMs`.
- `zone_elapsed_ms` (Map/Arena GDD hard requirement — must be present so client can recompute zone boundary independently on high-latency connections).
- Obstacle states for all destructible obstacles in the arena (alive/destroyed) — Map/Arena GDD hard requirement.
- `matchTimer`, `tick`, `timestamp`, `phase`.

---

### 3.4 Client-Side State Restoration

On receipt of `reconnect_ack` or `reconnect_rejected`, the client takes one of three paths based on `sessionPhase` and rejection reason.

#### 3.4.1 Active Match Phase Restoration

```
reconnect_ack received
  sessionPhase === "active"
        │
        ▼
1. Discard all local in-progress interpolation state and pending-inputs buffer.
   (Do not attempt to merge local state with snapshot. Replace entirely.)

2. Apply matchState snapshot to the authoritative game state store:
   - Set all PlayerState entries from snapshot
   - Set ZoneState from snapshot
   - Set matchTimer, tick, zone_elapsed_ms from snapshot
   - Set obstacle states from snapshot
   - Render character positions, HP, cooldowns from snapshot data

3. Resume the HUD display:
   - Show the match HUD (if it was hidden by the reconnect overlay)
   - Apply connection-quality indicator data (reset to unknown until next ping/pong)
   - Set local player character from yourCharacterId

4. Enable input pipeline:
   - Client resumes emitting input_move and input_ability events immediately
   - For the first leniencyTicks ticks, attach reconnect: true flag to each input
     (see §3.5 for how Match Server handles this flag)

5. Dismiss the reconnect overlay.

6. Show a brief "Back in the game!" notification for RECONNECT_SUCCESS_NOTIFICATION_MS
   (default: 2000ms). This is optional and dismissible.

7. Log reconnect success telemetry:
   { userId, matchId, stateAge, totalReconnectTimeMs, attemptNumber }
```

**stateAge handling on the client**: if `stateAge > CHECKPOINT_AGE_TOLERANCE_MS` (default: 6000ms), the client shows a brief warning: "Reconnected — some actions may have occurred while you were away." This is informational only; the game state is applied regardless. The `stateAge` threshold is one second beyond `CHECKPOINT_INTERVAL_SEC * 1000` to allow for Redis write latency.

#### 3.4.2 Character Select Phase Restoration

```
reconnect_ack received
  sessionPhase === "character_select"
        │
        ▼
Read isConfirmed:

  ┌── isConfirmed === true ──────────────────────────────────────┐
  │  The player had already confirmed before disconnecting.      │
  │  The server has their selection locked in.                   │
  │                                                              │
  │  1. Navigate to (or remain on) Character / Deck Select       │
  │     screen.                                                  │
  │  2. Pre-load yourCharacterId and yourDeckIds into the        │
  │     detail panel as the locked selection.                    │
  │  3. Apply locked state immediately:                          │
  │     - Both ability slots show padlock icons (not tappable)   │
  │     - Character carousel not tappable                        │
  │     - Confirm button: "Waiting for opponent…" (disabled)     │
  │  4. Show notification: "Your selection was saved — back      │
  │     in line!" for RECONNECT_SUCCESS_NOTIFICATION_MS.         │
  │  5. Continue waiting for match_started from Session Manager. │
  └──────────────────────────────────────────────────────────────┘

  ┌── isConfirmed === false ─────────────────────────────────────┐
  │  The player had NOT confirmed before disconnecting.          │
  │  They may still edit their selection.                        │
  │                                                              │
  │  1. Navigate to (or remain on) Character / Deck Select       │
  │     screen in editable state.                                │
  │  2. Pre-load the player's saved loadout for yourCharacterId  │
  │     into the detail panel (same as normal screen entry).     │
  │     If no saved loadout: default loadout for yourCharacterId.│
  │  3. Confirm button enabled if both slots filled.             │
  │  4. Countdown continues from server-emitted countdown_tick   │
  │     events (Character / Deck Select GDD §3.4).               │
  │  5. Show notification: "Reconnected — choose your fighter    │
  │     before time runs out!" for RECONNECT_SUCCESS_            │
  │     NOTIFICATION_MS.                                         │
  └──────────────────────────────────────────────────────────────┘
```

**Why `isConfirmed` is server-authoritative**: the client cannot reliably determine this because the disconnect may have occurred after the `player_select_character` event was sent but before the `character_selected` acknowledgement was received. The server's `session.characterSelections[userId]` is the only reliable record.

#### 3.4.3 Reconnect Rejection Handling

```
reconnect_rejected received
        │
        ├── reason === "session_ended"
        │       │
        │       ├── resultsPayload present?
        │       │     └── Yes → Navigate to Match Results screen with resultsPayload.
        │       │              Show "Your match ended while you were away." header.
        │       │     └── No  → Navigate to Main Menu.
        │       │              Show toast: "Your match has ended."
        │
        ├── reason === "grace_period_expired"
        │       │
        │       └── Dismiss reconnect overlay.
        │           Show full-screen message: "You were removed from the match."
        │           After REJECTION_DISPLAY_MS (default: 3000ms), navigate to Main Menu.
        │           Show persistent toast on Main Menu: "Disconnected too long — match forfeited."
        │
        └── reason === "match_not_found"
                │
                └── Dismiss reconnect overlay.
                    Show toast: "Match no longer available."
                    Navigate to Main Menu immediately.
```

---

### 3.5 Reconnect Overlay (Client UX)

The reconnect overlay is displayed immediately when an unexpected socket disconnect occurs (any disconnect reason other than intentional `session_leave`, `match_end`, or explicit cancel). It overlays the current screen without destroying it, so the match continues to render in the background during reconnect attempts.

**Overlay components:**

```
┌─────────────────────────────────────────────────┐
│                                                 │
│           [Animated connection icon]            │
│                                                 │
│              Reconnecting...                    │
│           Attempt 2 of 5 (8s)                   │
│                                                 │
│    [       Cancel and Return to Menu       ]    │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Overlay rules:**

- **Appears**: immediately on socket `disconnect` event (transport close, not intentional leave).
- **Background**: the match or character-select screen remains visible behind a translucent dark overlay (`rgba(0, 0, 0, 0.65)`). The background is rendered but all touch events are captured by the overlay — no accidental input to the underlying screen.
- **Attempt counter**: displays `"Attempt N of MAX_RECONNECT_ATTEMPTS (Xs elapsed)"`. `N` increments on each `reconnect_attempt` event from the Real-time Transport layer. Elapsed time ticks from the moment of disconnect.
- **Cancel button**: always visible. Tapping cancel:
  1. Stops the client-side reconnect loop (signals Real-time Transport to abort remaining attempts).
  2. Dismisses the overlay.
  3. Navigates to the Main Menu.
  4. Shows toast: "You left the match."
  5. **Server is NOT notified by cancel.** The server's grace period timer continues running until it expires naturally. The server does not distinguish between "player cancelled" and "player's device went dark." The Disconnect Handler owns the grace period expiry path regardless.
- **Auto-dismiss on success**: when `reconnect_ack` is received, the overlay animates out and state restoration begins (§3.4).
- **Auto-dismiss on rejection**: when `reconnect_rejected` is received, the overlay animates out and the appropriate rejection path executes (§3.4.3).
- **Auto-dismiss on exhaustion**: when the Real-time Transport exhausts all reconnect attempts without success (5 attempts / 30s), the overlay transitions to an error state: "Could not reconnect to match." with a single "Return to Menu" button (no retry option from this state — the grace period will have expired or be near-expiry by this point).

**Important UX constraint**: the overlay must not block background activity. The match continues ticking on the server during reconnect. If the player was in `character_select` phase, the countdown continues server-side. The overlay shows the elapsed time to create a sense of urgency without freezing the game world visually.

---

### 3.6 Post-Reconnect Input Leniency

When a player reconnects after a socket drop, their input pipeline needs a brief recovery window. The moment the `reconnect_ack` is received, the client begins sending `input_move` and `input_ability` events again. However, the client's internal clock may be slightly out of sync, and the first inputs may carry timestamps that fall close to or slightly beyond the normal staleness threshold of 150ms (3 ticks at 20 Hz).

**Leniency protocol:**

- For the first `RECONNECT_LENIENCY_TICKS` (default: 2) ticks after the server processes the reconnect, the Match Server doubles the staleness threshold for inputs from that player: from 150ms (3 ticks) to 300ms (6 ticks).
- The client attaches a `reconnect: true` flag to each input event for the first `RECONNECT_LENIENCY_TICKS` ticks to signal the Match Server that leniency applies.
- After `RECONNECT_LENIENCY_TICKS` ticks, the standard `INPUT_STALE_THRESHOLD_TICKS = 3` rule resumes for that player.
- The leniency window is player-specific: other players in the match are unaffected.

**Why 2 ticks**: the reconnect_ack delivery, client-side state application, and first input generation take approximately 1–2 ticks (50–100ms) under normal conditions. Two ticks of leniency ensures the player can send their first real input without it being discarded as stale. Larger windows risk accepting genuinely stale inputs from clients intentionally delaying their reconnect_ack processing.

```
Tick timeline (post-reconnect_ack delivery):
  Tick T:   reconnect_ack processed by server; player marked ACTIVE;
            leniency window opens (stale threshold = 6 ticks)
  Tick T+1: client's first inputs arrive (may have timestamps from just before reconnect_ack)
            → stale threshold is 6 ticks → inputs accepted
  Tick T+2: leniency window closes; standard stale threshold = 3 ticks resumes
```

---

### 3.7 Grace Period Interaction and Expiry

The Disconnect Handler owns the grace period timer (started when the player's socket disconnects). The Reconnect / Resume System interacts with the grace period at two points:

**1. Successful reconnect within grace period:**
- The server receives `reconnect_request` and the player's grace period timer has not fired.
- The Disconnect Handler is notified to cancel the grace period timer for this player.
- Session Manager marks the player as `ACTIVE`.
- `reconnect_ack` is sent. The match resumes as if the disconnect was a brief pause.

**2. Reconnect arrives at the exact grace period boundary:**
- If the server processes the `reconnect_request` event before running the grace period expiry job for this player, the reconnect succeeds (inclusive boundary rule).
- If the grace period expiry job has already fired and transitioned the session (or removed the player from the session), `reconnect_rejected { reason: "grace_period_expired" }` is sent.
- Race condition resolution: the Disconnect Handler's grace period expiry and the Session Manager's reconnect admission are protected by a Redis SETNX lock per player during the transition. Whichever operation acquires the lock first wins. There is no undefined intermediate state.

**3. Grace period expires before reconnect completes:**
- The Disconnect Handler fires the grace period expiry.
- If the session still has enough players to continue (per Session Manager §3.7 minimum player rules), the session continues without the disconnected player.
- If the reconnecting player subsequently completes a socket connection and sends `reconnect_request`, the server returns `reconnect_rejected { reason: "grace_period_expired" }` (the `player_session:{userId}` Redis key was deleted at expiry).

---

### 3.8 Redis Checkpoint Fallback

If the Match Server process crashed and restarted between the player's disconnect and their reconnect, the live `MatchState` is no longer in memory. The Session Manager reconstitutes from the Redis checkpoint (key: `match_checkpoint:{matchId}`, written every `CHECKPOINT_INTERVAL_SEC = 5s`).

**Fallback path:**

```
Player sends reconnect_request
        │
        ▼
Server checks if Match Server process is running:
  ├── Running → use live MatchState → stateAge = 0 in reconnect_ack
  │
  └── Not running (was restarted) → read match_checkpoint:{matchId} from Redis
              │
              ├── Checkpoint found → deserialize MatchState
              │     stateAge = now() - checkpoint.timestamp  (in ms)
              │     Emit reconnect_ack with checkpoint MatchState and stateAge > 0
              │
              └── Checkpoint not found (crash during write, TTL expired)
                    → Emit reconnect_rejected { reason: "match_not_found" }
                    → Navigate client to Main Menu
```

**`stateAge` communication to the client**: the `stateAge` field in `reconnect_ack` tells the client how stale the snapshot is. `stateAge = 0` means live state. `stateAge > 0` means the server was using a checkpoint. The client always applies the snapshot regardless of `stateAge`; the field is informational (used in UX notification and telemetry).

**Checkpoint staleness guarantee**: because checkpoints are written every `CHECKPOINT_INTERVAL_SEC = 5s`, the maximum `stateAge` from a checkpoint is approximately `CHECKPOINT_INTERVAL_SEC * 1000 + CHECKPOINT_WRITE_LATENCY_MS`. In practice, with the async non-blocking write model from Match Server GDD §3.7, the write latency is typically <20ms, so the effective maximum stateAge is ~5020ms.

---

## 4. Formulas

### 4.1 Post-Reconnect Lenient Staleness Threshold

The staleness threshold extended for the first `RECONNECT_LENIENCY_TICKS` ticks after reconnect:

```
NORMAL_STALE_THRESHOLD_MS  = INPUT_STALE_THRESHOLD_TICKS * TICK_INTERVAL_MS
                           = 3 * 50 = 150ms

LENIENT_STALE_THRESHOLD_MS = NORMAL_STALE_THRESHOLD_MS * RECONNECT_STALE_MULTIPLIER
                           = 150ms * 2 = 300ms

Variables:
  INPUT_STALE_THRESHOLD_TICKS    = 3       (from Match Server GDD §4.5)
  TICK_INTERVAL_MS               = 50ms    (1000 / TICK_RATE_HZ = 1000 / 20)
  RECONNECT_STALE_MULTIPLIER     = 2       (tunable; doubles the threshold)
  RECONNECT_LENIENCY_TICKS       = 2       (number of ticks leniency applies)

Per-tick leniency check:
  isLenient(playerState) =
    playerState.reconnecting === true
    AND (currentTick - playerState.reconnectTick) <= RECONNECT_LENIENCY_TICKS

staleness_threshold(playerId) =
  isLenient(players[playerId])
    ? LENIENT_STALE_THRESHOLD_MS
    : NORMAL_STALE_THRESHOLD_MS
```

**Example:**
- Player reconnects. Match Server marks `reconnectTick = T`.
- Tick T+1: `isLenient = true` → threshold = 300ms. Input with timestamp `serverTime - 280ms` → accepted.
- Tick T+2: `isLenient = true` → threshold = 300ms. Input with timestamp `serverTime - 280ms` → accepted.
- Tick T+3: `isLenient = false` → threshold = 150ms. Input with timestamp `serverTime - 280ms` → discarded.

---

### 4.2 State Age Tolerance Formula

The threshold at which the client shows an informational "actions may have occurred while away" warning:

```
CHECKPOINT_AGE_TOLERANCE_MS = (CHECKPOINT_INTERVAL_SEC * 1000) + CHECKPOINT_WRITE_LATENCY_BUFFER_MS

Default values:
  CHECKPOINT_INTERVAL_SEC              = 5s
  CHECKPOINT_WRITE_LATENCY_BUFFER_MS   = 1000ms   (1s buffer for async write delay)
  CHECKPOINT_AGE_TOLERANCE_MS          = 6000ms

If stateAge > CHECKPOINT_AGE_TOLERANCE_MS:
  Show warning: "Reconnected — some actions may have occurred while you were away."

Rationale: stateAge > 6000ms implies either (a) two or more checkpoint intervals were
missed (Redis write failures) or (b) the process restarted near the end of a checkpoint
interval AND the write was delayed. This is an unusual condition worth surfacing.
```

---

### 4.3 Reconnect Attempt Backoff (from Real-time Transport GDD §4.5)

The backoff schedule is owned by Real-time Transport and reproduced here for reference:

```
delay_n = min(BASE_RECONNECT_DELAY_MS * 2^(n-1) + rand(0, JITTER_CAP_MS),
              MAX_RECONNECT_DELAY_MS)

Variables:
  n                       = attempt number (1-indexed)
  BASE_RECONNECT_DELAY_MS = 500ms
  JITTER_CAP_MS           = 200ms
  MAX_RECONNECT_DELAY_MS  = 8000ms

Attempt schedule (base delay, no jitter):
  Attempt 1 → 500ms
  Attempt 2 → 1000ms
  Attempt 3 → 2000ms
  Attempt 4 → 4000ms
  Attempt 5 → 8000ms

Total max elapsed (no jitter): 15 500ms — well within RECONNECT_WINDOW_S = 30s.
Total max elapsed (max jitter on all attempts): 15 500 + (5 × 200) = 16 500ms.

Both totals are within the 30s window, ensuring the client can always attempt all
5 reconnects before the grace period expires.
```

---

### 4.4 Reconnect Window vs. Grace Period Alignment

These two values must be equal to ensure the client never exhausts reconnect attempts before the server's grace period has also expired:

```
RECONNECT_WINDOW_S         = 30s   (Real-time Transport: RECONNECT_WINDOW_S)
RECONNECT_GRACE_PERIOD_S   = 30s   (Real-time Transport: RECONNECT_GRACE_PERIOD_S,
                                     Disconnect Handler: grace period duration)

Invariant: RECONNECT_WINDOW_S === RECONNECT_GRACE_PERIOD_S

If RECONNECT_WINDOW_S < RECONNECT_GRACE_PERIOD_S:
  The client gives up before the server's slot is reclaimed.
  A player who stops trying to reconnect cannot re-enter even if the slot is still open.
  → Violation: client gives up too early.

If RECONNECT_WINDOW_S > RECONNECT_GRACE_PERIOD_S:
  The server reclaims the slot before the client stops trying.
  Post-expiry reconnect attempts will receive grace_period_expired rejection.
  → Acceptable but wasteful. Permitted if grace period is deliberately shorter.
```

---

## 5. Edge Cases

### 5.1 JWT Expires During the Reconnect Window

**Scenario:** A player disconnects at T=0. Their JWT expires at T=25s. The reconnect backoff reaches attempt 5 at T≈16s. On attempt 5, the socket reconnects successfully, but by the time Step 2 (JWT pre-flight check) runs, the token is near or past expiry.

**Resolution:**
1. Client detects `jwt.exp - now() < JWT_REFRESH_PREEMPT_MS`.
2. Client pauses the socket connect attempt and performs HTTP POST `/auth/refresh`.
3. If refresh succeeds: new JWT in hand; socket connect proceeds. This counts against `RECONNECT_WINDOW_S` elapsed time. If elapsed time is now ≥ 30s, abort: show "Could not reconnect in time" message, navigate to main menu.
4. If refresh fails: treat as terminal auth failure. Show "Session expired — please log in again." Navigate to login screen. Do not show the reconnect failed path (this is auth failure, not reconnect failure).

**Key invariant**: the JWT pre-flight (Step 2) is performed on every reconnect attempt, not just the first. A token that was valid on attempt 1 may expire before attempt 5.

---

### 5.2 Reconnect Arrives at Exact Grace Period Boundary

**Scenario:** The Disconnect Handler schedules grace period expiry at `T + RECONNECT_GRACE_PERIOD_S`. A reconnect request from the player arrives at the server at precisely `T + RECONNECT_GRACE_PERIOD_S` (same millisecond as the expiry job fires).

**Resolution:** Inclusive boundary rule — if the server processes the `reconnect_request` handler **before** the grace period expiry job runs, the reconnect succeeds. The Redis lock (SETNX keyed by `{playerId}:reconnect_lock`) ensures only one of these operations can proceed:

- If the reconnect_request handler acquires the lock first: the player is admitted, the grace period timer is cancelled, `reconnect_ack` is sent.
- If the grace period expiry job acquires the lock first: the player slot is removed, `reconnect_rejected { reason: "grace_period_expired" }` is sent when the reconnect_request arrives and finds no active session.

There is no state where both succeed or both fail simultaneously. The lock TTL is `RECONNECT_LOCK_TTL_MS = 2000ms` (sufficient for the transition to complete).

---

### 5.3 Server Process Crashed and Restarted Mid-Reconnect

**Scenario:** The Match Server crashes at T=5s. The player disconnects (or was disconnected by the crash). The process restarts at T=18s. The player's reconnect attempt arrives at T=22s, within the 30s grace period.

**Resolution:**
1. On restart, the Match Server reads `match_checkpoint:{matchId}` from Redis. The checkpoint was written at T≈5s (up to `CHECKPOINT_INTERVAL_SEC` before the crash), so `stateAge ≈ 17 000ms` when the reconnect arrives at T=22s.
2. Since `stateAge > CHECKPOINT_AGE_TOLERANCE_MS (6000ms)`, this is a high-staleness reconnect. The server still emits `reconnect_ack` with the checkpoint state.
3. The client receives `reconnect_ack` with `stateAge = 17000`. The informational warning is shown: "Reconnected — some actions may have occurred while you were away."
4. The match resumes from the checkpointed state. Note: `stateAge` of 17s means significant action has occurred on the server (that the reconnecting client missed and will catch up via subsequent state deltas). The snapshot restores the client to the state at T=5s, and the server's subsequent deltas bring it up to the current tick.

**Note on delta vs. snapshot post-reconnect**: the Match Server always sends a full snapshot on reconnect (Match Server GDD §3.5 rule). After the snapshot, the server resumes sending deltas at 20 Hz. The client does not need to explicitly request catch-up deltas; the next delta after the snapshot carries the current tick and the client rebuilds interpolation from there.

---

### 5.4 Player Reconnects to a Session That Ended While They Were Disconnected

**Scenario:** Match ends while the player is disconnected (opponent won during the grace period). The `session:{sessionId}` Redis key transitions to state `"ended"` with a `resultsPayload`. The player reconnects at T=28s, still within 30s.

**Resolution:**
1. Server receives `reconnect_request`.
2. Redis lookup finds `session.state === "ended"` and `resultsPayload` present.
3. Server emits `reconnect_rejected { reason: "session_ended", resultsPayload: <MatchResultSummary> }`.
4. Client receives rejection. Because `resultsPayload` is present, the client navigates to the **Match Results screen** (not main menu) with the results payload populated.
5. The player sees the match result: who won, their stats, MMR change (if any). They can tap "Back to Menu" from the results screen normally.

**Why results screen, not main menu:** returning a player to a blank main menu when their match ended gives them no closure and forces them to hunt for their result. Routing to the results screen directly is the correct UX — the match happened and the player deserves to see the outcome, even if they were absent for the end.

---

### 5.5 Player Abandons Reconnect (Taps Cancel)

**Scenario:** The player is in the reconnect overlay and deliberately taps "Cancel and Return to Menu."

**Resolution:**
1. Client stops the Socket.io reconnect loop (signals Real-time Transport to abort remaining attempts).
2. Client dismisses the overlay, shows toast: "You left the match."
3. Client navigates to the Main Menu.
4. **Server behaviour is unchanged.** The server has not been notified of the cancel. The Disconnect Handler's grace period timer for this player continues running normally. When the timer fires:
   - If the session still has minimum players, the match continues without the player.
   - The session transitions according to its normal abandonment or continuation rules.
5. If the player later navigates back into a match context (e.g., taps Play before the grace period expires), the server will find their `player_session:{userId}` key still active. The client must handle this case: on session creation, if the server returns a `SESSION_ALREADY_EXISTS` or HTTP 409, the client should offer: "You have an active match — Reconnect or Forfeit?" This is a Match Flow / Lobby responsibility, not Reconnect / Resume's.

---

### 5.6 Redis Checkpoint Not Found After Server Restart

**Scenario:** The Match Server crashes, Redis is also briefly unavailable (or the checkpoint TTL expired due to an unusually long outage), and a player attempts to reconnect.

**Resolution:**
1. Server receives `reconnect_request` and the process has restarted.
2. Read attempt on `match_checkpoint:{matchId}` returns null (key not found).
3. Server emits `reconnect_rejected { reason: "match_not_found" }`.
4. Client receives rejection. No `resultsPayload` is present (the match state is genuinely lost).
5. Client shows toast: "Match no longer available." Navigates to Main Menu.
6. Server logs an alert: `RECONNECT_CHECKPOINT_MISSING { matchId, userId, ts }`. This is a data-loss event requiring investigation.

**Mitigation**: the `CHECKPOINT_TTL_BUFFER_SEC = 60s` (Match Server GDD §4.4) ensures the checkpoint survives the full match duration plus a buffer. A Redis outage lasting longer than 60s after match end is the only scenario where this path fires in normal operation.

---

## 6. Dependencies

### 6.1 Upstream Dependencies (Reconnect / Resume Consumes)

| System | What Reconnect / Resume Needs | Interface | Notes |
|---|---|---|---|
| **Session Manager** | `session:{sessionId}` Redis key — session phase, player list, `characterSelections[userId]` (to populate `yourCharacterId`, `yourDeckIds`, `isConfirmed`); `player_session:{userId}` Redis index — to look up active session on reconnect | Redis read; Session Manager API | Session Manager is the authoritative source for whether a session is active and what the player's confirmed character state is |
| **Session Manager (grace period)** | Grace period state per disconnected player — whether the timer has fired before the reconnect arrives | Redis lock / Disconnect Handler coordination; `player_reconnect_grace:{userId}` status | Must coordinate with Disconnect Handler to resolve boundary-condition races |
| **Real-time Transport** | Socket.io reconnect events (client-side: `reconnect_attempt`, socket re-established); server-side: new socket admission, one-socket-per-user dedup, correlationId reuse within 300s | `transport.onPlayerReconnect(cb)` callback; `socket.join(roomId)` | Real-time Transport owns the socket-level reconnect loop (backoff, attempt count). Reconnect / Resume owns the application-level handshake that fires after the socket is established. |
| **Match Server** | Live `MatchState` for the `reconnect_ack` snapshot (if process running); Redis checkpoint (`match_checkpoint:{matchId}`) as fallback (if process restarted); `getPlayerRtt(playerId)` for leniency application | `matchServer.getLiveState(matchId)` or Redis read | Match Server GDD §3.7 defines the checkpoint key structure and TTL |
| **Authentication (JWT)** | JWT validation on reconnect request (same as initial connect); token refresh endpoint for expired tokens | Auth middleware; HTTP POST `/auth/refresh` | JWT expiry handling in §3.2 |

### 6.2 Downstream Consumers (Systems That Depend on Reconnect / Resume)

| System | What They Receive | Interface |
|---|---|---|
| **Disconnect Handler** | Notification to cancel the grace period timer when a reconnect is admitted. Reconnect / Resume emits `player_reconnected { userId, sessionId, matchId }` on successful admission. | Event callback: `disconnectHandler.onPlayerReconnected(userId)` |
| **Match Server** | Per-player reconnect tick (`reconnectTick`) and leniency flag so it applies doubled staleness threshold for `RECONNECT_LENIENCY_TICKS`. Input events from the reconnecting client carry `reconnect: true` for the first two ticks. | Match Server reads the per-player reconnect state from session; inputs carry inline `reconnect: true` field |
| **Character / Deck Select** | `isConfirmed` field from `reconnect_ack` determines whether the screen renders in locked or editable state on reconnect. This field resolves Character / Deck Select Risk 2 (locked state recovery). | `reconnect_ack.isConfirmed` read by Character / Deck Select screen logic |
| **Match Flow** | Match Flow is notified when a player reconnects during the character_select or active phase (so it can update its internal flow state for this player). If the reconnect is rejected with `session_ended`, Match Flow is bypassed and the client navigates directly to Match Results. | Event: `matchFlow.onPlayerReconnected(userId, sessionId)` |
| **In-Match HUD** | After reconnect in active phase, the HUD must refresh from the snapshot state (character portrait, HP, cooldowns, zone state). The HUD reads the restored `MatchState` from the game state store; no special HUD-level event is required beyond the state store update. | Reactive store updated by reconnect state restoration (§3.4.1) |

---

## 7. Tuning Knobs

All values are environment-variable configurable unless marked `[client]`. Server-side values can be updated via Remote Config. Defaults shown.

| Parameter | Env Var / Constant | Default | Safe Range | Effect |
|---|---|---|---|---|
| **Reconnect attempt count** | `MAX_RECONNECT_ATTEMPTS` | `5` | `3–10` | Maximum socket reconnect attempts before the client declares failure and shows the "Could not reconnect" error state. Must be sufficient to exhaust within `RECONNECT_WINDOW_S`. Lower = faster failure detection; higher = more attempts on flaky connections. |
| **Reconnect window** | `RECONNECT_WINDOW_S` | `30` s | `15–120` s | Wall-clock time the client spends attempting reconnect. **Must equal `RECONNECT_GRACE_PERIOD_S`** (Disconnect Handler grace period) — see §4.4. Raising this extends match slot reservation; lowering it reduces dead-slot time at cost of reconnect coverage. |
| **Reconnect grace period (server)** | `RECONNECT_GRACE_PERIOD_S` | `30` s | `15–120` s | How long the server holds the player's slot after disconnect. Must equal `RECONNECT_WINDOW_S`. Owned by the Disconnect Handler; referenced here for alignment. |
| **Post-reconnect leniency ticks** | `RECONNECT_LENIENCY_TICKS` | `2` | `1–5` | Ticks after reconnect during which the Match Server doubles the input staleness threshold. 1 = very tight; 5 = generous (risks accepting genuinely stale inputs). 2 covers typical client recovery time (50–100ms). |
| **Reconnect stale threshold multiplier** | `RECONNECT_STALE_MULTIPLIER` | `2` | `1.5–3` | Multiplier applied to normal staleness threshold during leniency window. 2× = 300ms from normal 150ms. Values >3× risk accepting inputs that arrived from a different network path than the reconnected socket. |
| **Checkpoint age tolerance** | `CHECKPOINT_AGE_TOLERANCE_MS` | `6000` ms | `5000–15000` ms | Threshold above which the client shows the "actions may have occurred" warning. Set to `CHECKPOINT_INTERVAL_SEC * 1000 + write_latency_buffer`. Do not set below `CHECKPOINT_INTERVAL_SEC * 1000`. |
| **JWT refresh preempt window** | `JWT_REFRESH_PREEMPT_MS` | `60 000` ms | `30 000–120 000` ms | How far before JWT expiry the client proactively refreshes during reconnect. 60s gives adequate buffer for a slow refresh call on a weak connection. |
| **reconnect_ack timeout** | `RECONNECT_ACK_TIMEOUT_MS` [client] | `5000` ms | `2000–10000` ms | How long the client waits for `reconnect_ack` or `reconnect_rejected` after sending `reconnect_request`. If neither arrives in time, the client treats the attempt as failed and moves to the next backoff attempt. Prevents indefinite waiting on a server that accepted the socket but crashed before sending the ack. |
| **Rejection display delay** | `REJECTION_DISPLAY_MS` [client] | `3000` ms | `1500–5000` ms | How long the "You were removed from the match" message is shown before navigating to Main Menu after `grace_period_expired` rejection. Long enough to read; short enough not to feel stuck. |
| **Reconnect success notification** | `RECONNECT_SUCCESS_NOTIFICATION_MS` [client] | `2000` ms | `1000–4000` ms | How long "Back in the game!" or "Your selection was saved" notification shows after successful reconnect. Brief; should not distract from re-engaging with the match. |
| **Reconnect lock TTL** | `RECONNECT_LOCK_TTL_MS` | `2000` ms | `500–5000` ms | TTL of the Redis lock used to serialize reconnect_request vs. grace period expiry boundary race (§5.2). Must be long enough for both paths to complete; short enough not to hold the lock across unrelated operations. |

---

## 8. Acceptance Criteria

All criteria are written as Given/When/Then. Criteria marked `[automated]` require an automated integration test. Criteria marked `[manual]` require QA verification. Criteria marked `[contract]` are cross-system interface checks.

---

### 8.1 Successful Reconnect — Active Match

**AC-RR-01 — Happy path reconnect in active match [manual]**
- Given: A player is in an active match; their network drops for 10 seconds; the socket reconnects on attempt 2
- When: The `reconnect_ack` is received
- Then: The reconnect overlay dismisses; the match HUD is visible with correct HP, cooldowns, and zone state matching the server's authoritative snapshot; the player can send inputs and receive `state_delta` events within 2 ticks (100ms) of the overlay dismissing

**AC-RR-02 — Full snapshot sent on reconnect (not delta) [automated]**
- Given: A player disconnects and reconnects within the grace period during an active match
- When: The server sends the reconnect response
- Then: The response is a `reconnect_ack` containing a complete `MatchState` (all `PlayerState[]` entries, full `ZoneState`, `zone_elapsed_ms`, obstacle states); no fields are omitted; a `state_delta` event is NOT used as the reconnect response

**AC-RR-03 — stateAge = 0 when using live Match Server state [automated]**
- Given: The Match Server process is running and has live state; a player reconnects
- When: `reconnect_ack` is emitted
- Then: `reconnect_ack.stateAge === 0`

**AC-RR-04 — Post-reconnect leniency window applied for 2 ticks [automated]**
- Given: A player reconnects during an active match; `RECONNECT_LENIENCY_TICKS = 2`
- When: The player sends inputs in ticks T+1 and T+2 with `reconnect: true` flag and timestamps that would be stale under the normal 150ms threshold but within the lenient 300ms threshold
- Then: Those inputs are processed by the Match Server (not discarded); on tick T+3, an input with the same staleness is discarded under the normal threshold

---

### 8.2 Reconnect — Character Select Phase

**AC-RR-05 — Reconnect to character_select with isConfirmed=true shows locked state [automated]**
- Given: A player confirmed their character selection; their network drops; they reconnect within the grace period
- When: The `reconnect_ack` is received with `sessionPhase: "character_select"` and `isConfirmed: true`
- Then: The Character / Deck Select screen shows the locked state (padlock icons on ability slots, carousel non-interactive, Confirm button reads "Waiting for opponent…"); the character and deck shown match `reconnect_ack.yourCharacterId` and `reconnect_ack.yourDeckIds`

**AC-RR-06 — Reconnect to character_select with isConfirmed=false shows editable state [automated]**
- Given: A player disconnected before confirming their character selection; they reconnect within the grace period
- When: The `reconnect_ack` is received with `sessionPhase: "character_select"` and `isConfirmed: false`
- Then: The Character / Deck Select screen shows the editable state; the last saved loadout for `yourCharacterId` is pre-populated in both ability slots; the Confirm button is enabled (if both slots are filled); the countdown timer continues from the server's current `countdown_tick` events

**AC-RR-07 — isConfirmed is server-authoritative (not inferred from client state) [contract]**
- Given: A player sends `player_select_character` and the socket drops before receiving `character_selected`; the player reconnects
- When: The server emits `reconnect_ack`
- Then: `isConfirmed` reflects the server's authoritative record (`session.characterSelections[userId] !== null`) — `true` if the selection was recorded server-side before the disconnect, `false` otherwise; the client must accept this field without overriding it with local inference

---

### 8.3 Grace Period Expiry

**AC-RR-08 — reconnect_rejected with grace_period_expired when reconnect arrives after expiry [automated]**
- Given: A player disconnects; `RECONNECT_GRACE_PERIOD_S = 30s` elapses without the player reconnecting; the session continues without the player; the player reconnects at T=35s
- When: The server processes the `reconnect_request`
- Then: The server emits `reconnect_rejected { reason: "grace_period_expired" }`; the `player_session:{userId}` Redis key does not exist; no `reconnect_ack` is sent

**AC-RR-09 — Client shows "You were removed from the match" and navigates to Main Menu [manual]**
- Given: The client receives `reconnect_rejected { reason: "grace_period_expired" }`
- When: The rejection is processed
- Then: The reconnect overlay dismisses; a "You were removed from the match." full-screen message is shown for `REJECTION_DISPLAY_MS` milliseconds; the player is then navigated to the Main Menu; a persistent toast "Disconnected too long — match forfeited." appears on the Main Menu

---

### 8.4 JWT Expiry During Reconnect

**AC-RR-10 — Silent HTTP refresh succeeds and reconnect proceeds [automated]**
- Given: The player's JWT expires at T=20s; the player disconnects at T=15s; reconnect attempt 2 fires at T=16.5s
- When: The client detects `jwt.exp - now() < JWT_REFRESH_PREEMPT_MS` and calls POST `/auth/refresh`
- Then: A new JWT is obtained; the socket reconnect proceeds with the new JWT; `reconnect_request` is emitted with the refreshed token; `reconnect_ack` is received within `RECONNECT_WINDOW_S`

**AC-RR-11 — Refresh failure triggers login screen, not reconnect failure [automated]**
- Given: The player's JWT and refresh token have both expired; the client attempts a token refresh during reconnect
- When: POST `/auth/refresh` returns `401 Unauthorized`
- Then: The reconnect loop is aborted; the reconnect overlay is replaced with "Session expired — please log in again."; the player is navigated to the login screen; the normal reconnect-exhaustion error state is NOT shown

---

### 8.5 Crash Recovery via Redis Checkpoint

**AC-RR-12 — Reconnect succeeds using Redis checkpoint when process restarted [manual]**
- Given: The Match Server process crashes; Redis checkpoint `match_checkpoint:{matchId}` exists with a valid MatchState; the process restarts within the 30s grace period; the player reconnects at T=22s
- When: The server processes `reconnect_request` using the checkpoint
- Then: `reconnect_ack` is sent with `stateAge > 0`; the client restores from the checkpoint state; the client shows "Reconnected — some actions may have occurred while you were away." if `stateAge > CHECKPOINT_AGE_TOLERANCE_MS`

**AC-RR-13 — reconnect_rejected when checkpoint is missing after crash [automated]**
- Given: The Match Server process crashed; Redis checkpoint `match_checkpoint:{matchId}` does not exist (TTL expired or write failure during crash); the player reconnects
- When: The server processes `reconnect_request`
- Then: `reconnect_rejected { reason: "match_not_found" }` is emitted; a `RECONNECT_CHECKPOINT_MISSING` alert is logged; the client navigates to the Main Menu with "Match no longer available." toast

---

### 8.6 Cancel Reconnect

**AC-RR-14 — Player cancels reconnect; navigates to Main Menu; server unaffected [manual]**
- Given: The reconnect overlay is active; the player taps "Cancel and Return to Menu" on attempt 2 of 5
- When: The cancel is processed
- Then: The Socket.io reconnect loop is stopped (no further reconnect attempts); the player is navigated to the Main Menu; a toast "You left the match." appears; the server's grace period timer continues running uninterrupted; no `player_disconnected_cancel` event or any server-side notification is sent

---

### 8.7 Session Ended While Disconnected

**AC-RR-15 — Player reconnects after match ended; routed to results screen [automated]**
- Given: A player disconnects at T=10s; the match ends at T=25s (opponent won); the player reconnects at T=28s
- When: The server processes `reconnect_request`
- Then: `reconnect_rejected { reason: "session_ended", resultsPayload: <MatchResultSummary> }` is emitted; the client navigates to the Match Results screen (not Main Menu); the results payload is rendered correctly (winner, player stats, MMR delta if applicable); `session.state === "ended"` in Redis and the `resultsPayload` is populated

---

### 8.8 Reconnect Overlay UX

**AC-RR-16 — Reconnect overlay appears immediately on disconnect and shows attempt counter [automated]**
- Given: A player is in an active match
- When: The Socket.io connection drops unexpectedly (network loss, not intentional leave)
- Then: The reconnect overlay appears within one render frame of the disconnect event; the overlay shows "Reconnecting… Attempt 1 of 5"; the underlying match screen is visible behind the overlay; all touch events to the match screen are blocked by the overlay

**AC-RR-17 — Reconnect overlay counter increments correctly across attempts [automated]**
- Given: Reconnect attempts 1, 2, 3 have all failed (socket connected but `reconnect_ack` not received within timeout)
- When: Attempt 4 begins
- Then: The overlay displays "Attempt 4 of 5"; elapsed time has incremented from the original disconnect time; the cancel button remains visible and functional

---

*End of Document*
