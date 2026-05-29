# Match Flow System — Game Design Document
> **System**: Match Flow System
> **Priority**: MVP
> **Layer**: Compound Features
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

The Match Flow System is the **end-to-end orchestrator** of the match experience for every player in BRAWLZONE. It owns the state machine that carries a player from pressing "Play" through matchmaking, character select, active combat, and the post-match results screen — and returns them safely to the idle lobby, ready to queue again.

Match Flow does **not** own any game logic. It does not calculate MMR deltas, distribute rewards, advance quest progress, or run match simulation. Its sole responsibility is **sequencing**: it knows which state a player is in, which events trigger transitions, and which downstream systems to notify — and in what order — when a match concludes.

This distinction is deliberate. Every feature system that fires at match end (MMR, Rewards, XP, Quests, Analytics) fans out from Match Flow. Match Flow is the hub; the others are spokes. None of the spokes talk to each other through Match Flow — Match Flow fires parallel events and each spoke handles its own concern independently, with one critical exception: **MMR update is synchronous and must complete before the parallel fan-out fires**, per the MMR GDD's acceptance criteria. This ordering ensures the rank tier is committed before the Reward System reads it.

**Scope at MVP:**
- 1v1 Duel, 3v3 Squad Brawl, 8-player FFA
- Solo queue only (party queue deferred to Vertical Slice)
- XP and Diamond grant stubs on the results payload (populated in Alpha when those systems ship)
- No reconnect mid-flow (deferred to Vertical Slice Disconnect/Reconnect System)

---

## 2. Player Fantasy

### The Arc: "Found → Fighting → Rewarded"

The Match Flow experience is the primary game loop rhythm. Done right, it feels like:

> You tap Play. A heartbeat later, a match is found. You pick your character quickly — the countdown is already ticking — and then you're in. The fight ends, the screen fades, and your results appear: your rank went up, a number flashes. You tap Play Again before the music even finishes. The loop keeps moving.

There should be **no dead time** between any two phases. Every transition is animated, every state change is communicated. Players never wonder "is it frozen?" or "did my selection go through?" At every moment they are either acting, reacting, or watching something happen.

Specific beats the player must feel clearly:

- **Match found**: instant relief — the wait is over, something is happening.
- **Character select**: urgency without pressure — the countdown gives structure, not anxiety. Players who have a preferred character know exactly what to tap.
- **Countdown**: anticipation — 3, 2, 1 feels ceremonial. It is the moment before the drop.
- **Match start**: clarity — the arena appears, the HUD is up, the player knows what to do.
- **Match end**: resolution — win or lose, the result is acknowledged with appropriate weight. The screen does not feel like a dead end.
- **Results**: satisfaction — numbers feel earned. The XP bar ticking up, the rank delta flashing — these are the reward for everything that just happened. At MVP these are stubs; the architecture is already in place so they populate fully in Alpha.
- **Play Again**: momentum — re-queuing from the results screen should feel like a natural continuation of the session, not starting from scratch.

The player should never feel the machinery. State transitions are scaffolding; what the player feels is flow.

---

## 3. Detailed Rules

### 3.1 Match Flow State Machine

#### States

| State | Description |
|---|---|
| `idle` | Player is in the main lobby. No active match, no active queue. Starting state and recovery state after every match. |
| `queuing` | Player has tapped "Play" and entered the matchmaking queue for a specific mode. Matchmaking Engine is searching. |
| `match_found` | Matchmaking Engine has found a group. Players are notified; session creation is in progress. Transitional — very short-lived. |
| `character_select` | Session is in the `character_select` state (per Session Manager GDD §3.5). Players choose character + deck. Countdown has not yet started. |
| `countdown` | All players have confirmed character selections. Server-driven 3-second countdown is in progress. |
| `active` | Match is running. Session is in `active` state. Players are in the arena. |
| `ended` | Session Manager has reported `session_ended`. Match Flow is executing the post-match sequence (snapshot → MMR → fan-out → payload send). |
| `results` | `match_results_payload` has been delivered to clients. Match Results Screen is visible to the player. Awaiting player action or auto-timeout. |
| `rewarding` | Reward System is distributing grants server-side. Player is still on the results screen; reward values are populated as they arrive (or from stub after timeout). |
| `abandoned` | Terminal state. Session was abandoned at any point before `ended`. Player returns to `idle` after brief notification. |

#### Valid Transitions

```
idle             ──► queuing           Player taps "Play"
queuing          ──► match_found       Matchmaking Engine emits match_found event
queuing          ──► idle              Player taps "Cancel" / queue timeout
match_found      ──► character_select  Session Manager emits session_created; session enters character_select
character_select ──► countdown         All players submit valid selections (server confirms all)
character_select ──► abandoned         Session abandoned during character select (disconnect, timeout)
countdown        ──► active            Countdown reaches tick 0; Match Server confirms match_started
countdown        ──► abandoned         Match Server fails to start within SESSION_INIT_TIMEOUT_MS after countdown completes
active           ──► ended             Session Manager emits session_ended (Match Server reported win condition met)
active           ──► abandoned         Session Manager emits session_abandoned (all disconnected, heartbeat timeout)
ended            ──► results           match_results_payload delivered to client
results          ──► rewarding         Reward System fan-out confirmed received (or auto-advance on timeout)
rewarding        ──► idle              Reward grants confirmed (or REWARD_TIMEOUT_MS exceeded); player may re-queue
rewarding        ──► queuing           Player taps "Play Again" before rewarding completes (reward delivery continues server-side)
idle             ◄── abandoned         After brief abandoned notification, player returns to idle
```

No backward transitions except the `rewarding → queuing` shortcut (Play Again while rewards are still in-flight). All state is server-authoritative.

#### State Machine Invariants

- A player is in exactly one Match Flow state at all times.
- State is stored server-side (keyed by `playerId`). The client receives `match_flow_state_changed { playerId, state, ts }` on every transition.
- Terminal states (`abandoned`) auto-transition to `idle` after `ABANDONED_DISPLAY_MS` (default 3000ms) via a server-scheduled timer.
- A player in `rewarding` who taps "Play Again" immediately transitions to `queuing`; reward delivery continues server-side and is written to the player profile independent of client state. See Edge Case 5.1.

---

### 3.2 Pre-Match MMR Snapshot

At the moment Match Flow receives the `session_created` event from Session Manager (transition: `match_found → character_select`), Match Flow reads and stores each player's current MMR in the session object.

```typescript
// Written to session object at character_select entry
mmrSnapshot: {
  [playerId: string]: {
    mmr: number;             // Player's current MMR at snapshot time
    is_provisional: boolean;
    snapshotTs: string;      // ISO 8601 timestamp
  }
}
```

**Purpose:** The MMR delta calculation at match end uses the snapshot value, not the player's current MMR at that time. This makes the delta immune to season resets, admin corrections, or concurrent matches that might modify a player's MMR between match start and match end. The snapshot is the source of truth for the delta.

**Season boundary safety:** If a season reset fires while a match is in progress, the player's live MMR is adjusted, but the snapshot value held in the session is not changed. The delta is calculated from `snapshotMmr`, so the delta reflects only the performance in this specific match, not the season reset adjustment.

**Storage:** The snapshot is written to the session object in Redis (merged into `session:{sessionId}` key) immediately when `character_select` is entered. It is also persisted to PostgreSQL in the session record so it survives Redis eviction during long matches.

---

### 3.3 Countdown Phase

The countdown is the transition from character select confirmation to match start. It is server-driven, not client-driven.

#### Trigger
The countdown begins when **all present players in the session** have submitted valid character+deck selections. Session Manager emits an internal `all_selections_confirmed { sessionId }` signal to Match Flow. Match Flow transitions the flow state to `countdown` and starts a server-side 3-second countdown timer.

#### Countdown Events
Match Flow emits `countdown_tick` via Socket.io to all players in the session room at each 1-second interval:

```typescript
countdown_tick {
  sessionId: string;
  matchId: string;
  tick: number;            // 3, 2, 1, 0
  serverTimestamp: string; // ISO 8601; clients sync display timer to this
}
```

- Tick 3: emitted immediately when countdown starts.
- Tick 2: emitted 1000ms after tick 3.
- Tick 1: emitted 2000ms after tick 3.
- Tick 0: emitted 3000ms after tick 3 (countdown complete; match start imminent).

#### Why Server-Driven
Countdowns are server-driven to ensure all players enter the match simultaneously regardless of device clock differences or network jitter. A client that receives tick 0 late is still synchronized to the server timestamp embedded in the event and can display an accurate countdown from receipt. Client-side countdown animation is always governed by `serverTimestamp`, never by `Date.now()`.

#### Match Start
At tick 0, Match Flow signals Session Manager to activate the session (see Session Manager GDD §3.6). Session Manager allocates a Match Server and emits `match_started` to all players with the following payload:

```typescript
match_started {
  sessionId: string;
  matchId: string;
  gameMode: "duel_1v1" | "squad_3v3" | "ffa_8";
  mapId: string;
  players: Array<{
    playerId: string;
    characterId: string;
    deckId: string;
  }>;
  matchServerUrl: string;  // Client connects game socket here
  serverTimestamp: string;
}
```

Match Flow transitions to `active` when `match_started` is confirmed broadcast.

#### Countdown Failure
If Session Manager fails to activate the match (Match Server allocation failure or `SESSION_INIT_TIMEOUT_MS` exceeded) after tick 0, Match Flow transitions all players to `abandoned`. See Edge Case 5.5.

---

### 3.4 Match End Sequence

The match end sequence is **ordered and partially asynchronous**. Steps 1–4 are sequential (each waits for the previous). Steps 5–6 fire in parallel. Steps 7–8 close the loop.

#### Step 1 — Match Server Reports Win Condition
The Match Server emits `match_ended { matchId, result: MatchResult }` to Session Manager. This is a Match Server → Session Manager event, not a Match Flow event.

#### Step 2 — Session Manager Transitions and Notifies Match Flow
Session Manager transitions the session state to `ended`, writes the final record to PostgreSQL and Redis (per Session Manager GDD §3.8), then emits `session_ended { sessionId, result }` to Match Flow.

Match Flow transitions the flow state from `active` to `ended`.

#### Step 3 — Match Flow Snapshots Final Match State
Match Flow reads from the `session_ended` result payload and assembles the **raw match state record**:

```typescript
interface RawMatchState {
  matchId: string;
  sessionId: string;
  gameMode: GameMode;
  mapId: string;
  matchDurationSec: number;    // Derived: (endedAt - startedAt) in seconds
  terminationReason: "natural_end" | "disconnect" | "timeout";
  disconnectCause: boolean;    // true when terminationReason is "disconnect"
  playerResults: Array<{
    playerId: string;
    placement: number;           // 1-based rank (1 = winner/first place)
    outcome: "win" | "loss" | "draw";
    eliminations: number;
    assists: number;
    score: number;
    mmrSnapshot: number;         // From §3.2 snapshot; used for delta calculation
    is_provisional: boolean;     // From §3.2 snapshot
  }>;
  winConditionType: string;      // From Game Mode System: "elimination" | "score" | "survival" etc.
}
```

This snapshot is **immutable** after this step. Downstream systems receive a read-only copy.

#### Step 4 — MMR Update (Synchronous, Must Complete Before Fan-Out)

Match Flow calls the MMR System synchronously. **Match Flow awaits MMR completion before proceeding to Step 5.** This ordering ensures the rank tier is committed before the Reward System reads it.

```
Match Flow → MMR System: updateRatings(mmrUpdateRequest)

mmrUpdateRequest {
  matchId: string;
  gameMode: GameMode;
  matchDurationSec: number;    // Used to enforce 60-second minimum rule (§3.4.1)
  disconnectCause: boolean;    // false for natural match end
  playerRatings: Array<{
    playerId: string;
    currentMmr: number;            // From §3.2 mmrSnapshot
    is_provisional: boolean;       // From §3.2 mmrSnapshot
    placement: number;
    outcome: "win" | "loss" | "draw";
  }>
}

MMR System returns: Array<{
  playerId: string;
  mmrDelta: number;        // e.g., +18, -12
  newMmr: number;
  newRankTier: RankTier;
  previousRankTier: RankTier;
}>
```

Match Flow stores the MMR update results in memory to merge into the results payload.

#### Step 4.1 — Minimum Match Duration for MMR
Match Flow enforces the 60-second minimum match rule before calling the MMR System:

```
if (rawMatchState.matchDurationSec < MIN_MATCH_DURATION_FOR_MMR_S   // 60s
    AND rawMatchState.disconnectCause === true) {
  // Skip MMR update entirely
  // mmrDelta = 0 for all players
  // newMmr = mmrSnapshot value for all players
  // Analytics event: MATCH_SKIPPED_MMR { matchId, reason: "below_min_duration_disconnect", matchDurationSec }
} else {
  // Call MMR System synchronously
}
```

This rule applies **only** when `disconnectCause === true`. A match that ends naturally under 60 seconds (e.g., an unusually fast 1v1 elimination) still awards MMR. Only disconnection-caused short matches are excluded.

#### Step 5 — Parallel Fan-Out (Fire and Forget, Except Reward Is Tracked)

After MMR update completes (or is skipped), Match Flow fires the following events **in parallel** (non-blocking):

| Target | Event | Contents |
|---|---|---|
| Reward System | `match_result_for_rewards` | Per-player outcome for reward calculation |
| XP & Progression | `match_result_for_xp` | Per-player outcome for XP calculation |
| Quest/Mission System | `match_result_for_quests` | Full per-player stats for quest evaluation |
| Analytics/Telemetry | `MATCH_ENDED` | Full match summary with MMR deltas |

**XP and Reward are independent — neither depends on the other. Both fan out from this single event. This is the Model B architecture decision (systems-index.md).** Match Flow does not couple them.

**Match Flow does not wait for XP, Quest, or Analytics** fan-out confirmation. These are fire-and-forget at this step.

**Match Flow DOES track the Reward System fan-out** via a response promise with `REWARD_TIMEOUT_MS` timeout (default 5000ms). The reward grants are needed to populate the final results payload.

#### Step 6 — Initial Match Results Payload Sent to Clients

Match Flow sends the **initial** `match_results_payload` to all players in the session room via Socket.io immediately after MMR completes (or times out). At this point, reward values are stub/null because the Reward System fan-out has not yet confirmed.

See §4.1 for the full payload schema. The initial send has `rewardsReady: false` and `diamondsEarned: null`.

Match Flow transitions the flow state from `ended` to `results` when the initial payload is sent.

The client enforces a minimum display time of `RESULTS_MIN_DISPLAY_MS` (default 3000ms) — even if rewards arrive instantly, the results screen holds for at least this long before the "Play Again" button becomes active.

#### Step 7 — Await Reward System Response (or Timeout Fallback)

Match Flow waits up to `REWARD_TIMEOUT_MS` (default 5000ms) for the Reward System to confirm grant distribution.

**If confirmation arrives within REWARD_TIMEOUT_MS:**
1. Match Flow receives `reward_grants_confirmed { matchId, playerGrants[] }`.
2. Match Flow sends `match_results_reward_update { matchId, playerRewards[] }` to all players still on the results screen.
3. Flow state transitions to `rewarding`.

**If REWARD_TIMEOUT_MS is exceeded:**
1. Match Flow transitions to `rewarding` with stub values for display (`diamondsEarned: null`).
2. A server-side async task continues monitoring Reward System completion with exponential backoff.
3. Once Reward System confirms (even after client has navigated away), grants are written to Player Profile directly. The player sees the updated balance on their next profile load.
4. If the player is still on the results screen when the late confirmation arrives, `match_results_reward_update` is sent.
5. Analytics event `MATCH_REWARD_DELAYED { matchId, delayMs }` is emitted.

#### Step 8 — Updated Payload Sent to Clients (If Rewards Confirmed)

When Reward System confirms within the timeout window, Match Flow sends a follow-up `match_results_reward_update` to update the results screen in-place with real reward values (`diamondsEarned`, `xpEarned`). If timeout fired, this step is skipped for the current session; the client already shows stubs.

---

### 3.5 Abandoned Match Flow

Abandonment can occur from two states: `character_select` or `active`.

#### Trigger Sources
- `session_abandoned` event from Session Manager (any `AbandonReason`).
- Player explicitly quits (client-side "Quit Match" action, which triggers a Session Manager disconnect event first).

#### Deduplication
If both `match_ended` and `session_abandoned` arrive for the same `sessionId` (race condition), Match Flow uses **first-one-wins** deduplication. The second event is logged and dropped. A Redis distributed lock keyed on `match_flow_lock:{sessionId}` is acquired before processing either terminal event; the second caller finds the lock held and discards its event.

#### Abandoned Flow Sequence

```
session_abandoned event received
  │
  ├─ [Deduplicate] Acquire match_flow_lock:{sessionId}
  │     If lock already held → discard event, log DUPLICATE_TERMINAL_EVENT warning, exit
  │
  ├─ [Transition] Flow state → abandoned
  │
  ├─ [MMR check]
  │     Phase = character_select → no MMR change (match never started)
  │     Phase = active AND matchDurationSec < MIN_MATCH_DURATION_FOR_MMR_S AND disconnectCause=true
  │         → no MMR change (§3.4.1 minimum duration rule)
  │     Phase = active AND (matchDurationSec >= 60s OR natural end)
  │         → normal MMR update applies
  │
  ├─ [Analytics] Emit MATCH_DISCONNECTED {
  │       matchId, sessionId, gameMode,
  │       abandonReason,
  │       matchDurationSec,          // 0 if abandoned before active
  │       phaseAtAbandon: "character_select" | "active"
  │     }
  │
  ├─ [Notify clients] Socket.io emit to session room:
  │     match_abandoned { sessionId, reason, phaseAtAbandon }
  │
  ├─ [No rewards, no XP] Fan-out NOT fired for Reward System or XP & Progression.
  │   Quest System MAY receive MATCH_ABANDONED event for quest tracking (fire-and-forget).
  │
  └─ [Auto-transition] Schedule flow state → idle after ABANDONED_DISPLAY_MS (3000ms)
```

**No MMR change for abandonments before `active` phase.** This is enforced by Match Flow — Session Manager does not emit to MMR for abandoned sessions, and Match Flow does not call the MMR System for character_select abandonments.

---

### 3.6 Re-Queue (Play Again)

After the results screen is shown (flow state `results` or `rewarding`), the player may tap "Play Again". This:

1. Transitions the flow state back to `queuing` for the same `gameMode` as the completed match.
2. Enqueues the player in the Matchmaking Engine queue for that mode.
3. The results screen fades to lobby UI while the player is queuing — the player does not need to navigate manually.
4. Reward delivery continues server-side regardless of whether the player has already re-queued. See Edge Case 5.1.

**Re-queue is not offered** if the match was abandoned. After an abandoned match, the player returns to `idle` at the main lobby. The "Play Again" button is not shown on the abandoned notification screen. The player may manually choose a mode from the main lobby.

**Minimum display time gate:** The "Play Again" button is not enabled until `RESULTS_MIN_DISPLAY_MS` (default 3000ms) has elapsed since the initial payload was delivered. This prevents accidental re-queue before the player has processed their results.

**Auto-offer highlight:** After `RESULTS_AUTO_OFFER_MS` (default 8000ms) from initial results delivery, if the player has not interacted, the UI may visually highlight the "Play Again" button. The button does NOT auto-queue — tapping is always required.

---

### 3.7 Match Flow Public API

The following methods are the public interface Match Flow exposes to other server-side systems. All methods are server-to-server calls (not client-facing).

| Method | Signature | Description | Scope |
|---|---|---|---|
| `onPlayerReconnected` | `onPlayerReconnected(playerId: string): void` | Called by the Reconnect/Resume system when a disconnected player reconnects. Match Flow verifies the match is still active and triggers a state snapshot push to the reconnected player so their client can resume from the correct flow state. | Wired in Vertical Slice |

> **Note — `onPlayerReconnected`:** Full reconnect/resume support is deferred to the Vertical Slice Disconnect/Reconnect System (see §1 scope). At MVP, this stub is registered but its implementation is a no-op. In Vertical Slice, the implementation will: (1) look up the player's current flow state from Redis; (2) if flow state is `active`, push `match_flow_state_changed` + the latest session snapshot to the reconnected client; (3) if the match has already ended, deliver the `match_results_payload` directly.

---

## 4. Formulas

### 4.1 Match Results Payload Schema

The payload is assembled over the match end sequence (Steps 3–8) and delivered in two passes: an initial send after MMR (Step 6) and a follow-up update after rewards (Step 8).

```typescript
interface MatchResultsPayload {
  matchId: string;
  gameMode: "duel_1v1" | "squad_3v3" | "ffa_8";
  mapId: string;
  matchDurationSec: number;

  // Per-player results (one entry per player in the session)
  playerResults: Array<{
    playerId: string;
    outcome: "win" | "loss" | "draw";
    placement: number;          // 1-based; 1 = winner/first
    kills: number;              // eliminations this match
    assists: number;
    score: number;

    // MMR fields — always populated after Step 4
    mmrDelta: number;           // 0 if MMR was skipped; non-zero after normal match end
    newMmr: number;
    newRankTier: RankTier;
    previousRankTier: RankTier;

    // XP progression context — populated by XP & Progression system at match end
    xpAtLevelStart: number;          // Player's XP value at the start of their current level before this match
    xpToNextLevel: number;           // XP needed to reach the next level from the start of the current level

    // Economy fields — stub at MVP; populated when Reward + XP systems ship in Alpha
    xpEarned: number | null;         // null = stub
    diamondsEarned: number | null;   // null = stub

    // Time alive — used for FFA scoring and quest progress
    timeAliveSec: number;            // Seconds the player was alive during the match

    // Bonus flags (read from Player Profile at match end)
    bonusFlags: {
      playPassActive: boolean;
      noAds: boolean;
    };
  }>;

  // Payload state flags
  rewardsReady: boolean;  // false on initial send; true after reward grants confirmed
}
```

**Payload construction timing:**

```
matchDurationSec = (session.endedAt - session.startedAt) in seconds

For each player in session.playerResults:
  mmrDelta       = MMRSystem.result[playerId].mmrDelta     (0 if MMR skipped)
  newMmr         = MMRSystem.result[playerId].newMmr       (snapshotMmr if MMR skipped)
  newRankTier    = MMRSystem.result[playerId].newRankTier
  xpEarned       = null   (stub at MVP; XPSystem.result[playerId].xpEarned in Alpha)
  diamondsEarned = null   (stub at MVP; RewardSystem.result[playerId].diamonds in Alpha)
  bonusFlags     = PlayerProfile.getFlags(playerId)        (read at match end)
```

---

### 4.2 Reward Calculation (from game-concept.md — Match Flow reproduces for payload assembly)

These formulas are owned by the Reward System. Match Flow applies them only to construct the `diamondsEarned` field in Alpha when the Reward System is live. Reproduced here for self-contained reference.

```
diamonds_earned = base_reward × win_multiplier × play_pass_bonus

Variables:
  base_reward     = 3        (outcome = loss | draw)
                  = 5        (outcome = win)
  win_multiplier  = 1.0      (outcome = loss | draw)
                  = 2.0      (outcome = win)
  play_pass_bonus = 1.0      (bonusFlags.playPassActive = false)
                  = 1.25     (bonusFlags.playPassActive = true)

Example — Win, Play Pass active:
  diamonds_earned = 5 × 2.0 × 1.25 = 12.5 → floor → 12 diamonds

Example — Loss, no Play Pass:
  diamonds_earned = 3 × 1.0 × 1.0 = 3 diamonds
```

---

### 4.3 XP Calculation (from game-concept.md — Match Flow reproduces for payload assembly)

These formulas are owned by XP & Progression. Reproduced here for self-contained reference and payload construction in Alpha.

```
xp_earned = 100 + (50 × kills) + (200 × win_bonus)

Variables:
  kills     = number of eliminations by this player this match
  win_bonus = 1    (outcome = win)
            = 0    (outcome = loss | draw)

Example — Win, 3 kills:
  xp_earned = 100 + (50 × 3) + (200 × 1) = 100 + 150 + 200 = 450 XP

Example — Loss, 1 kill:
  xp_earned = 100 + (50 × 1) + (200 × 0) = 100 + 50 + 0 = 150 XP
```

---

### 4.4 Fan-Out Event Schemas

```typescript
// Sent to Reward System (Step 5)
interface MatchResultForRewards {
  matchId: string;
  gameMode: GameMode;
  matchStartedAt: string;           // ISO 8601 timestamp when the match started (not ended)
  playerResults: Array<{
    playerId: string;
    outcome: "win" | "loss" | "draw";
    placement: number;
    matchDurationSec: number;
  }>;
}

// Sent to XP & Progression (Step 5)
interface MatchResultForXP {
  matchId: string;
  gameMode: GameMode;
  matchDurationSec: number;
  matchStartedAt: string;           // ISO 8601 timestamp when the match started (not ended)
  playerResults: Array<{
    playerId: string;
    outcome: "win" | "loss" | "draw";
    placement: number;
    eliminations: number;
    assists: number;
  }>;
}

// Sent to Quest/Mission System (Step 5)
interface MatchResultForQuests {
  matchId: string;
  gameMode: GameMode;
  matchDurationSec: number;
  matchStartedAt: string;           // ISO 8601 timestamp when the match started (not ended)
  playerResults: Array<{
    playerId: string;
    characterId: string;
    outcome: "win" | "loss" | "draw";
    placement: number;
    eliminations: number;
    assists: number;
    score: number;
    damageDealt: number;            // Total damage dealt by the player
    abilityUseCounts: Record<string, number>; // Map of abilityId → use count
    survived: boolean;              // Whether the player was alive when the match ended
  }>;
}

// Sent to Analytics (Step 5)
interface MatchEndedAnalyticsEvent {
  event: "MATCH_ENDED";
  matchId: string;
  sessionId: string;
  gameMode: GameMode;
  mapId: string;
  matchDurationSec: number;
  matchStartedAt: string;           // ISO 8601 timestamp when the match started (not ended)
  playerCount: number;
  playerResults: Array<{
    playerId: string;
    outcome: "win" | "loss" | "draw";
    placement: number;
    mmrDelta: number;
  }>;
  serverTimestamp: string;
}
```

---

### 4.5 Fan-Out Timeout Policy

Match Flow waits for downstream systems according to this budget:

| Target | Wait Mode | Timeout | Fallback |
|---|---|---|---|
| MMR System (Step 4) | Synchronous — awaited | `MMR_UPDATE_TIMEOUT_MS` = 3000ms | mmrDelta=0 for all; emit `MATCH_MMR_TIMEOUT`; proceed to Step 5 |
| Reward System (Steps 5–8) | Async — tracked promise | `REWARD_TIMEOUT_MS` = 5000ms | Stub values in payload; server-side async retry; see §5.2 |
| XP & Progression (Step 5) | Fire-and-forget | None | XP system owns its own retry logic |
| Quest/Mission System (Step 5) | Fire-and-forget | None | Quest system owns its own retry logic |
| Analytics/Telemetry (Step 5) | Fire-and-forget | None | Best-effort; no retry from Match Flow |

**Total maximum sequential time before initial results payload is sent to client:**

```
MAX_SEQUENTIAL_TIME = MMR_UPDATE_TIMEOUT_MS + network_overhead
                    ≈ 3000ms + ~100ms
                    ≈ 3.1 seconds worst case (MMR timeout path)
                    ≈ <500ms typical (MMR responds in under 200ms under normal load)
```

---

### 4.6 MMR Skip Condition

```
MMR update is SKIPPED when ALL of the following are true:
  1. rawMatchState.matchDurationSec < MIN_MATCH_DURATION_FOR_MMR_S  (default 60)
  2. rawMatchState.disconnectCause === true

MMR update PROCEEDS if EITHER:
  - matchDurationSec >= MIN_MATCH_DURATION_FOR_MMR_S
  - disconnectCause === false  (natural match end, regardless of duration)
```

---

## 5. Edge Cases

### 5.1 Player Closes App During Results Screen

**Scenario:** A player completes a match, sees the results screen, and closes the app (force-kill or background). The Reward System has not yet confirmed grant distribution.

**Problem:** If reward distribution were client-triggered, a closed app would mean no rewards.

**Resolution:**
- Reward distribution is entirely server-side. Match Flow triggers it in Step 5 by emitting to the Reward System — this happens regardless of client connection state.
- The Reward System writes grants directly to the Player Profile in the database. The client does not need to be connected.
- When the player reopens the app and loads their profile, the updated Diamond balance and XP are already applied.
- Match Flow does not require client acknowledgment before transitioning the flow state to `rewarding`. The server-side state machine runs to completion independently of the client.

**At MVP (stub rewards):** The MMR delta is written to Player Profile by the MMR System directly in Step 4 — server-side. There is no reward data to lose from a closed app at MVP.

---

### 5.2 Reward System Times Out During Fan-Out

**Scenario:** Match Flow fires the Reward System fan-out event (Step 5) and waits up to `REWARD_TIMEOUT_MS` (5000ms). The Reward System does not respond within that window.

**Resolution:**
1. After `REWARD_TIMEOUT_MS`, Match Flow sends the initial `match_results_payload` to clients with `rewardsReady: false` and stub reward values (`diamondsEarned: null`).
2. Match Flow transitions flow state to `rewarding`.
3. Match Flow schedules a server-side async task that subscribes for Reward System confirmation with exponential backoff (up to `REWARD_ASYNC_RETRY_TOTAL_MS` = 60000ms).
4. When Reward System eventually confirms grants, they are applied to Player Profile directly. If the player is still on the results screen, `match_results_reward_update` is sent. If they have navigated away, the balance is updated silently on their next profile load.
5. Analytics event `MATCH_REWARD_DELAYED { matchId, delayMs }` is emitted when the timeout fires.
6. If Reward System never confirms within `REWARD_ASYNC_RETRY_TOTAL_MS`, an ops alert fires and the match record is flagged `reward_pending: true` for manual recovery.

---

### 5.3 `match_ended` and `session_abandoned` Arrive Simultaneously

**Scenario:** The Match Server sends `match_ended` at the exact same moment all players disconnect. Session Manager may emit both `session_ended` and `session_abandoned` for the same session within milliseconds.

**Resolution:**
- Match Flow uses a Redis distributed lock: `match_flow_lock:{sessionId}` with TTL of 10 seconds.
- Whichever event arrives first acquires the lock and begins processing.
- The second event attempts to acquire the lock, finds it held, logs `DUPLICATE_TERMINAL_EVENT` with both events' details, and exits without processing.
- **Race mitigation:** Session Manager applies a 50ms debounce before emitting `session_abandoned` when a heartbeat timeout fires concurrently with a received `match_ended` signal. This reduces the probability of `session_abandoned` winning the race over a valid natural match end. This is a Session Manager implementation detail, not a Match Flow rule.

---

### 5.4 Player in `character_select` When Opponent Abandons

**Scenario:** In a 1v1 Duel, both players have entered character select. One player closes the app before submitting a character selection.

**Resolution:**
1. Disconnect Handler notifies Session Manager.
2. Session Manager re-evaluates minimum players for `duel_1v1` mode. With 1 remaining, minimum is not met. Session Manager transitions to `abandoned`.
3. Session Manager emits `session_abandoned { sessionId, reason: "insufficient_players" }` to Match Flow.
4. Match Flow transitions flow state to `abandoned` for both players.
5. **No MMR change for either player** — the match never reached the `active` phase.
6. The remaining player receives `match_abandoned` and is returned to `idle`.

**3v3 / FFA:** In modes where minimum players can still be met with fewer than the full roster, Session Manager may proceed to activation. Match Flow follows whatever Session Manager decides. If Session Manager proceeds, Match Flow continues normally. If Session Manager abandons, Match Flow runs the abandoned flow.

---

### 5.5 Countdown Completes but Match Server Fails to Start

**Scenario:** Countdown reaches tick 0, but Session Manager's `POST /match/start` to the Match Server fails or returns an error. No `match_started` event is emitted.

**Resolution:**
1. Session Manager detects the failure (error response or `SESSION_INIT_TIMEOUT_MS` exceeded).
2. Session Manager transitions the session to `abandoned` with `abandonReason: "no_server_capacity"` or `"match_server_crash"`.
3. Session Manager emits `session_abandoned` to Match Flow.
4. Match Flow transitions flow state from `countdown` to `abandoned`.
5. All players receive `match_abandoned { reason: "server_unavailable" }` — a user-friendly reason is surfaced, not the internal code.
6. No MMR change. No rewards.
7. Analytics event `MATCH_SERVER_START_FAILED { sessionId, matchId, reason }` is emitted.
8. Players are returned to `idle` after `ABANDONED_DISPLAY_MS`.

**Client UX:** The countdown completes (tick 0 fires), then a brief "Connecting..." state appears. After `match_abandoned` arrives (expected < 500ms after tick 0), the error notification replaces "Connecting...". The player never sees a hanging screen.

---

### 5.6 Both Players Disconnect Simultaneously Below the 60-Second Threshold

**Scenario:** In a 1v1 Duel, both players disconnect simultaneously at 59 seconds (`matchDurationSec = 59`, `disconnectCause = true`).

**Resolution:**
1. Session Manager detects both players disconnected and emits `session_abandoned { sessionId, reason: "all_disconnected", matchDurationSec: 59 }`.
2. Match Flow receives `session_abandoned`. Deduplication lock is acquired normally (no race with `session_ended` since neither player was connected to send a win condition).
3. `disconnectCause = true` AND `matchDurationSec (59) < MIN_MATCH_DURATION_FOR_MMR_S (60)` → MMR skip condition is met.
4. **No MMR change for either player.** `mmrDelta = 0` for both.
5. No reward fan-out. No XP fan-out.
6. Analytics event `MATCH_DISCONNECTED` is emitted with `matchDurationSec: 59` and `phaseAtAbandon: "active"`.
7. Both players return to `idle` after `ABANDONED_DISPLAY_MS`.

**Intentional behavior:** The 60-second threshold protects against farming MMR via staged disconnects. A legitimate match ending in under 60 seconds is only possible via a natural win condition (e.g., instant elimination), not a mutual disconnect.

---

## 6. Dependencies

### 6.1 Upstream — Match Flow Consumes

| System | What Match Flow Needs | Interface | Notes |
|---|---|---|---|
| **Game Mode System** | Win condition result embedded in `match_ended` signal | Via Session Manager's `session_ended` payload: `winConditionType`, player placements, final scores | Match Flow reads but does not interpret the win condition; it passes placements to MMR and Reward Systems |
| **Matchmaking Engine** | `match_found` event when a group is assembled | Event: `match_found { sessionId, playerIds[], gameMode, mapId }` | Match Flow transitions from `queuing` to `match_found` on this event |
| **Session Manager** | `session_ended { sessionId, result }` and `session_abandoned { sessionId, reason }` | Server-to-server event bus (internal message queue or Socket.io server-to-server) | The two primary signals that drive the post-match sequence and abandoned flow |

### 6.2 Downstream — Match Flow Produces / Notifies

| System | What Match Flow Provides | Interface | Coupling Model |
|---|---|---|---|
| **MMR / Ranked System** | `updateRatings` call with match result and MMR snapshots | Synchronous RPC call; Match Flow awaits response before fan-out | Synchronous — Step 4 must complete before Step 5 |
| **Reward System** | `match_result_for_rewards` event at match end | Async event (internal message queue); Match Flow tracks response with `REWARD_TIMEOUT_MS` | Parallel fan-out from Step 5; tracked but not blocking after Step 4 |
| **XP & Progression** | `match_result_for_xp` event at match end | Async event (internal message queue); fire-and-forget from Match Flow | Parallel fan-out from Step 5; no coupling with Reward System |
| **Quest/Mission System** | `match_result_for_quests` event at match end | Async event; fire-and-forget | Parallel fan-out from Step 5; also receives `MATCH_ABANDONED` event |
| **Match Results Screen** | `match_results_payload` (initial) + `match_results_reward_update` (follow-up) | Socket.io emit to session player rooms | Client-facing; initial send at Step 6; follow-up at Step 8 |
| **Analytics/Telemetry** | `MATCH_ENDED`, `MATCH_DISCONNECTED`, `MATCH_SKIPPED_MMR`, `MATCH_MMR_TIMEOUT`, `MATCH_REWARD_DELAYED`, `MATCH_SERVER_START_FAILED` | Async event; fire-and-forget | Best-effort; no retry from Match Flow |

### 6.3 Architectural Note: Model B Fan-Out

XP & Progression and Reward System both fan out from Match Flow **independently** at Step 5. This is the **Model B (parallel fan-out)** architecture decision documented in `design/gdd/systems-index.md`. Neither system depends on the other. Match Flow fires both events simultaneously. Any perceived sequencing (e.g., displaying XP before diamonds) is a client-side UI concern handled by the Match Results Screen, not an architectural dependency.

This was an explicit correction to an earlier design where Reward System was downstream of XP & Progression. Model B eliminates that coupling.

---

## 7. Tuning Knobs

All values are environment-variable configurable and overridable via Remote Config for live tuning. Defaults shown.

| Parameter | Env Var | Default | Description | Safe Range |
|---|---|---|---|---|
| Countdown duration | `COUNTDOWN_DURATION_S` | `3` | Seconds of countdown before match start; number of `countdown_tick` events equals this value + 1 (including tick 0) | 2–5s. Below 2s: players feel rushed on slow connections. Above 5s: dead time increases. |
| Countdown tick interval | `COUNTDOWN_TICK_INTERVAL_MS` | `1000` | Milliseconds between countdown tick events | Fixed at 1000ms; do not tune. |
| MMR update timeout | `MMR_UPDATE_TIMEOUT_MS` | `3000` | Max milliseconds Match Flow awaits MMR System synchronous response before using zero-delta fallback | 1000–5000ms. Below 1000ms: false timeouts on congested servers. Above 5000ms: unacceptable results screen delay. |
| Reward fan-out timeout | `REWARD_TIMEOUT_MS` | `5000` | Max milliseconds Match Flow waits for Reward System confirmation before sending initial payload with stubs | 2000–10000ms. Below 2000ms: false timeouts increase. Above 10000ms: player waits too long for initial results. |
| Reward async retry ceiling | `REWARD_ASYNC_RETRY_TOTAL_MS` | `60000` | Max total milliseconds for server-side async reward retry after initial timeout | 30000–300000ms. Lower values increase unresolved reward risk; higher values delay ops alerts. |
| Results screen minimum display time | `RESULTS_MIN_DISPLAY_MS` | `3000` | Milliseconds before "Play Again" button becomes tappable | 1500–5000ms. Below 1500ms: players accidentally re-queue before reading results. Above 5000ms: slows loop for experienced players. |
| Play Again auto-offer delay | `RESULTS_AUTO_OFFER_MS` | `8000` | Milliseconds after results display before "Play Again" is visually highlighted (not auto-queued) | 5000–15000ms. Tune based on observed player re-queue timing from analytics. |
| Abandoned display time | `ABANDONED_DISPLAY_MS` | `3000` | Milliseconds the abandoned notification is shown before auto-transitioning to idle | 2000–5000ms. |
| Minimum match duration for MMR | `MIN_MATCH_DURATION_FOR_MMR_S` | `60` | Minimum match duration in seconds; disconnect-caused matches shorter than this skip MMR update | 30–120s. Must stay consistent with MMR GDD. Treat changes as ranked balance changes, not tuning knob adjustments. |
| Play Pass bonus multiplier | `PLAY_PASS_BONUS_MULTIPLIER` | `1.25` | Diamond reward multiplier for active Play Pass subscribers | 1.0–2.0. Below 1.0 is invalid. Above 2.0: risks economic imbalance between free and paid players. Coordinate with Economy team. |

---

## 8. Acceptance Criteria

All criteria are written as Given/When/Then and are independently verifiable by automated test or documented manual QA.

### 8.1 Full Match Lifecycle

**AC-MF-01 — Happy Path: Full Match from Idle to Idle (Duel)**
- Given: Two players in `idle`; both tap Play for Duel mode
- When: The full lifecycle completes (queue → match_found → character_select → countdown → active → ended → results → rewarding → idle)
- Then: Each state transition fires `match_flow_state_changed` in the correct order; both players receive `match_results_payload` with `mmrDelta` populated and `rewardsReady` toggled to `true` within `REWARD_TIMEOUT_MS`; both players transition to `idle` after the results screen

**AC-MF-02 — Countdown Is Server-Driven**
- Given: All players confirm character selections in a session
- When: Countdown begins
- Then: `countdown_tick` events with ticks 3, 2, 1, 0 are received by all players in the session room; each tick arrives exactly `COUNTDOWN_TICK_INTERVAL_MS` ± 100ms after the previous; tick timestamps reflect server time; no tick is skipped

**AC-MF-03 — Match Start Payload Is Complete**
- Given: Countdown reaches tick 0 and Session Manager activates the session
- When: `match_started` is emitted
- Then: Payload contains `sessionId`, `matchId`, `gameMode`, `mapId`, `players` array (with all `playerId`, `characterId`, and `deckId` values), `matchServerUrl`, and `serverTimestamp`; all players in the session room receive it within 200ms of tick 0

---

### 8.2 Pre-Match MMR Snapshot

**AC-MF-04 — MMR Snapshot at Character Select Entry**
- Given: Match Flow transitions from `match_found` to `character_select`
- When: `session_created` is received from Session Manager
- Then: Each player's `mmr` and `is_provisional` are read from Player Profile and stored in the session object's `mmrSnapshot`; snapshot timestamp is set to `now`; snapshot is written to both Redis and PostgreSQL

**AC-MF-05 — Snapshot Isolates from Season Reset**
- Given: A match is in `active` state; a season reset fires mid-match that modifies player MMR values
- When: The match ends and Match Flow calculates the MMR update
- Then: Match Flow passes the `snapshotMmr` (captured at character_select entry) to MMR System, not the post-reset live MMR; the MMR delta reflects only match performance, not the season reset adjustment

---

### 8.3 MMR Ordering and Correctness

**AC-MF-06 — MMR Update Fires Before Fan-Out**
- Given: A match ends normally
- When: Match Flow executes the post-match sequence
- Then: Match Flow calls `updateRatings` (Step 4) and awaits its response before emitting any fan-out event to Reward System, XP & Progression, or Analytics (Step 5); log timestamps confirm Step 4 completes before Step 5 fires

**AC-MF-07 — MMR Timeout Does Not Block Results**
- Given: MMR System does not respond within `MMR_UPDATE_TIMEOUT_MS`
- When: Timeout fires
- Then: Match Flow sets `mmrDelta = 0` for all players; logs `MATCH_MMR_TIMEOUT` analytics event; proceeds to Step 5 fan-out; results payload is sent to clients with `mmrDelta: 0`; total time from `session_ended` to results payload delivery does not exceed `MMR_UPDATE_TIMEOUT_MS + 500ms`

**AC-MF-08 — Minimum Match Duration Enforced for Disconnects**
- Given: A match in `active` phase where all players disconnect after 45 seconds (`matchDurationSec = 45 < MIN_MATCH_DURATION_FOR_MMR_S = 60`, `disconnectCause = true`)
- When: Match Flow processes the abandonment
- Then: MMR System is NOT called; `mmrDelta = 0` for all players; analytics event `MATCH_SKIPPED_MMR` is emitted with `reason: "below_min_duration_disconnect"` and `matchDurationSec: 45`

**AC-MF-09 — Short Natural Match Still Awards MMR**
- Given: A 1v1 Duel that ends via natural win condition after 35 seconds (`disconnectCause = false`)
- When: Match Flow processes the match end
- Then: MMR System IS called with the match result; `mmrDelta` is non-zero for both players; the 60-second minimum does not apply because `disconnectCause = false`

---

### 8.4 Fan-Out Correctness

**AC-MF-10 — Reward and XP Fan-Out Are Independent**
- Given: A match ends normally
- When: Step 5 fan-out fires
- Then: `match_result_for_rewards` and `match_result_for_xp` are emitted as independent events; neither event contains a reference to the other system; both fire within 100ms of MMR update completion; neither blocks the other

**AC-MF-11 — Reward Timeout Sends Stub Payload Then Delivers Async**
- Given: Reward System does not respond within `REWARD_TIMEOUT_MS`
- When: Timeout fires during Step 7
- Then: `match_results_payload` is sent to clients with `rewardsReady: false` and `diamondsEarned: null`; analytics event `MATCH_REWARD_DELAYED` is emitted; server-side async retry task is scheduled; when Reward System eventually confirms, grants are applied to Player Profile; if player is still on results screen, `match_results_reward_update` is sent; if player has navigated away, balance is updated silently

---

### 8.5 Abandoned Flow

**AC-MF-12 — Abandoned in Character Select: No MMR Change**
- Given: A 1v1 Duel session in `character_select`; one player disconnects; Session Manager abandons the session
- When: Match Flow receives `session_abandoned`
- Then: Flow state transitions to `abandoned`; MMR System is NOT called; `match_abandoned` is sent to all players in the session room; analytics event `MATCH_DISCONNECTED` is emitted with `phaseAtAbandon: "character_select"`; both players transition to `idle` after `ABANDONED_DISPLAY_MS`

**AC-MF-13 — Abandoned During Active Match: No Rewards**
- Given: A match in `active` state is abandoned (all players disconnect)
- When: Match Flow receives `session_abandoned`
- Then: Flow state transitions to `abandoned`; Reward System fan-out is NOT fired; XP fan-out is NOT fired; no reward grants are written for this match; players return to `idle`; analytics `MATCH_DISCONNECTED` event is emitted

**AC-MF-14 — Duplicate Terminal Event Deduplication**
- Given: `session_ended` and `session_abandoned` both arrive for the same `sessionId` within 50ms of each other
- When: Both events are processed
- Then: Exactly one event is processed (the first to acquire `match_flow_lock:{sessionId}`); the second is logged as `DUPLICATE_TERMINAL_EVENT` and discarded; no double MMR update or double fan-out occurs; player profile is modified exactly once

**AC-MF-15 — Both Players Disconnect Below 60-Second Threshold: No MMR**
- Given: A 1v1 Duel where both players disconnect simultaneously at 59 seconds (`matchDurationSec = 59`, `disconnectCause = true`)
- When: Match Flow processes the abandonment
- Then: MMR System is NOT called; `mmrDelta = 0` for both players; `MATCH_DISCONNECTED` analytics event is emitted with `matchDurationSec: 59`; no reward fan-out fires; both players return to `idle`

---

### 8.6 Reward Delivery Guarantee

**AC-MF-16 — Rewards Delivered Server-Side Even After Client Disconnect**
- Given: A match ends; Match Flow fires Reward System fan-out; the player closes the app before `match_results_reward_update` arrives
- When: The Reward System confirms grants (even after the client is offline)
- Then: Grants are written to Player Profile in the database; when the player reopens the app and loads their profile, the updated Diamond balance reflects the match rewards; no rewards are lost due to client disconnect

---

### 8.7 Play Again

**AC-MF-17 — Play Again Re-Queues for Same Mode**
- Given: A player is in `results` or `rewarding` state after completing a Duel match
- When: Player taps "Play Again"
- Then: Flow state transitions to `queuing`; player is enqueued in the Matchmaking Engine for `duel_1v1` mode; reward delivery (if still in progress) continues server-side uninterrupted; "Play Again" button is not enabled before `RESULTS_MIN_DISPLAY_MS` has elapsed since initial payload delivery

**AC-MF-18 — Play Again Not Offered After Abandonment**
- Given: A session was abandoned and the player received the `match_abandoned` notification
- When: The abandoned notification screen is displayed
- Then: No "Play Again" button is shown; after `ABANDONED_DISPLAY_MS`, player transitions to `idle` at the main lobby with all mode-select options available

---

### 8.8 Reward Calculation Correctness

**AC-MF-19 — Diamond Reward Formula: Win with Play Pass**
- Given: A player wins a match with an active Play Pass subscription
- When: The Reward System confirms grant for this player
- Then: `diamondsEarned = floor(5 × 2.0 × 1.25) = 12`; `bonusFlags.playPassActive = true` is present in the payload

**AC-MF-20 — Diamond Reward Formula: Loss without Play Pass**
- Given: A player loses a match with no active Play Pass subscription
- When: The Reward System confirms grant for this player
- Then: `diamondsEarned = floor(3 × 1.0 × 1.0) = 3`; `bonusFlags.playPassActive = false` is present in the payload

---

*End of Document*
