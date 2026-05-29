# Lobby & Team Formation — Game Design Document
> **System**: Lobby & Team Formation
> **Priority**: MVP
> **Layer**: Presentation
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

The Lobby & Team Formation system is the player's waiting room between the main menu and an active match. It is the first step in the matchmaking funnel and owns the complete lifecycle of a single queue attempt: from mode confirmation through to the handoff to Character/Deck Select.

### Scope — what this system owns

| Responsibility | Description |
|---|---|
| Mode selection confirmation | Player arrives from main menu with a mode already chosen; lobby confirms and locks that choice |
| Queue entry UI | Sends POST /v1/matchmaking/queue and transitions to "Searching…" state |
| Queue status display | Renders elapsed time, estimated wait, and the MMR bracket expansion indicator |
| Cancel queue | Exits the queue gracefully via DELETE /v1/matchmaking/queue and returns to main menu |
| Match-found transition | Handles `match_found` Socket.io event with a brief celebration animation before navigating to Character/Deck Select |
| Queue timeout handling | Handles `queue_timeout` event; presents re-queue or back-to-menu options |
| Connectivity loss overlay | Detects Socket.io disconnect, attempts reconnect, reconciles server state |
| Solo queue labelling | Always shows "Playing Solo" at MVP; shows a greyed-out "Party Up (Coming Soon)" placeholder |

### Out of scope (MVP)

- Party formation and party invites — owned by Party/Presence System (Vertical Slice)
- Friends list or presence display
- Spectator mode entry
- Cross-promotion or ad surfaces inside the lobby screen

---

## 2. Player Fantasy

> *"I tap a mode, I'm searching, I'm in a match — and it all felt fast, alive, and fair."*

The lobby should make the player feel three things in sequence:

**Anticipation** — The moment the search begins, the UI communicates that the system is actively working on their behalf. Animated indicators and a live elapsed-time counter signal forward momentum, not stasis. The player should never feel like the app has frozen or forgotten them.

**Confidence** — The MMR bracket indicator gives players transparent, honest feedback about who they might be matched against and how that range grows over time. This converts a potential source of anxiety ("am I waiting too long?") into a piece of information the player understands and trusts.

**Minimal friction** — The path from "I want to play" to "I am in a match" must have as few mental transitions as possible. Mode is confirmed with a single tap from the main menu. The cancel path is always visible and one tap. The match-found celebration is brief — it rewards the wait without delaying the game.

---

## 3. Detailed Rules

### 3.1 Mode Selection

Players select a game mode from the main menu by tapping a mode card. The available modes at MVP are:

| Mode | Players | Description |
|---|---|---|
| 1v1 Duel | 2 | Head-to-head single-player bracket |
| 3v3 Squad Brawl | 6 | Three-player teams, team deathmatch |
| 8-Player FFA | 8 | Free-for-all, last-player-standing |

Tapping a mode card navigates the player to the Lobby screen with that mode pre-selected and visually confirmed. The mode is considered **locked** the moment the queue entry POST request is sent. The player cannot change mode after this point without cancelling the queue.

### 3.2 Queue Entry Flow

```
[Main Menu — Mode Card Tap]
        │
        ▼
[Lobby Screen — Mode confirmed, "Search" button visible]
        │
        │ Player taps "Find Match"
        ▼
[POST /v1/matchmaking/queue  { gameMode }]
        │
        ├── HTTP error (4xx/5xx) ──► Show inline error toast; remain on Lobby screen; "Find Match" re-enabled
        │
        └── HTTP 200 OK ──► Transition to "Searching…" state
```

Once in the **Searching state**, the following elements are displayed:

- Animated search indicator (pulsing ring or spinning arc — see Tuning Knobs §7 for animation duration)
- Mode name and icon (locked, non-interactive)
- Elapsed time counter (counts up from 0:00, format: `M:SS`)
- Estimated wait label pulled from `queue_status` events (e.g. "Est. ~45s")
- MMR bracket indicator (see §3.4)
- "Playing Solo" label
- "Party Up (Coming Soon)" greyed-out button (non-interactive at MVP)
- "Cancel" button (always visible, always interactive)

### 3.3 Queue Status Display

The Matchmaking Engine emits `queue_status` Socket.io events on a periodic interval (default every 5 seconds — see Tuning Knobs §7). On each event the lobby updates:

| Field | Source | Display |
|---|---|---|
| Elapsed time | Client-side timer (starts at queue entry) | Counting-up, format `M:SS` |
| Estimated wait | `queue_status.estimatedWaitSec` | "Est. ~Xs" or "Est. ~Xm Ys" |
| MMR bracket range | `queue_status.mmrSpread` | Visual bracket indicator (see §3.4) |
| Queue position (if provided) | `queue_status.position` | "#N in queue" — shown only if field is present in payload |

The estimated wait label updates smoothly on each event. If two successive `queue_status` events arrive with identical estimated wait, the display does not flash or reset.

### 3.4 MMR Bracket Indicator

The MMR bracket indicator communicates how broadly the matchmaking engine is currently searching:

- **Initial state**: ±300 MMR spread — bracket progress bar/ring at minimum fill
- **Expansion**: The engine expands toward a ±600 MMR cap over the queue duration. The visual tracks this in real time based on the `mmrSpread` value in each `queue_status` event.
- **Visual language**: A horizontal progress bar (or a segmented ring on mobile) fills from left (narrow) to right (wide) as the spread grows. Two anchor labels sit at the ends: "Tight match" (left) and "Wider search" (right).
- The indicator carries no negative connotation — copy reads "Expanding search to find a match faster."

Formula mapping: see §4.2.

### 3.5 Cancel Queue

The "Cancel" button is rendered at all times while the player is in the Searching state. Tap behaviour:

```
[Player taps Cancel]
        │
        ├── If match_found already received and transition is in progress:
        │       Cancel is ignored — match_found takes priority (see §3.7 race condition)
        │
        └── Otherwise:
                │
                ▼
        [DELETE /v1/matchmaking/queue]
                │
                ├── HTTP 200 OK ──► Navigate to Main Menu (mode select)
                │
                └── HTTP error ──► Show "Could not cancel — try again" toast; remain in Searching state; Cancel re-enabled
```

The "Cancel" button is disabled (greyed, non-tappable) only during the 1.5-second "Match Found!" animation to prevent accidental queue re-entry confusion.

### 3.6 Match Found Transition

When the Socket.io `match_found` event arrives:

1. The Searching state UI is replaced by a full-screen (or modal) **"Match Found!"** animation.
2. The animation plays for **1.5 seconds** (configurable — see §7).
3. The payload `sessionId` is stored in app state / navigation params.
4. After the animation completes, the app navigates to the **Character/Deck Select** screen, passing `sessionId`.

The "Match Found!" animation should feel celebratory but not interruptible. No buttons are shown during this 1.5-second window.

### 3.7 Match-Found / Cancel Race Condition

If the player taps "Cancel" at the same moment a `match_found` event arrives from the server:

- **`match_found` takes priority.** The cancel action is dropped on the client side — no DELETE request is sent to the server.
- The "Match Found!" animation plays immediately.
- Implementation note: the client should gate the cancel DELETE request behind a flag that is set to `false` the instant `match_found` is received. Any cancel tap received after that flag is set is a no-op.

### 3.8 Queue Timeout

When the Socket.io `queue_timeout` event is received (default after 60 seconds of searching):

1. The Searching state transitions to the **Timeout state**.
2. A message is shown: *"No match found — the queue timed out."*
3. Two buttons are presented:
   - **"Try Again"** — re-queues for the same mode (repeats the queue entry flow from §3.2 without returning to main menu)
   - **"Back to Menu"** — navigates to the main menu mode select
4. The timeout message remains displayed until the player takes an action (no auto-dismiss).

### 3.9 Solo Queue Label and Party Placeholder

At MVP, every player queues alone. The Lobby screen always shows:

- A **"Playing Solo"** label beneath the mode name. This is informational only and non-interactive.
- A **"Party Up (Coming Soon)"** button, visually greyed out, with a lock icon or "VS" tier badge. Tapping it shows a tooltip: *"Party play is coming in a future update!"* The button does not navigate anywhere.

These elements set expectations and pre-announce the Party/Presence System without creating false affordances.

### 3.10 Connectivity Loss During Queue

If the Socket.io connection drops while the player is in the Searching state:

1. A **"Connection lost — attempting to reconnect"** overlay is shown on top of the Searching state. The Searching UI remains visible beneath. The Cancel button remains functional.
2. The client attempts Socket.io reconnection using the SDK's built-in reconnection strategy.
3. On successful reconnect:
   - Client calls **GET /v1/matchmaking/queue/status** to reconcile server state.
   - **If server reports still in queue**: Remove overlay, resume Searching state display, reset elapsed time to server-reported value if available.
   - **If server reports dequeued** (server-side timeout or cleanup during disconnect): Remove overlay, navigate to main menu mode select, show message: *"You were removed from the queue due to a connection issue."*
4. If reconnection fails after the retry budget (governed by Socket.io config), the overlay updates to: *"Could not reconnect. Please check your connection."* A **"Go to Menu"** button is shown to allow the player to exit gracefully.

---

## 4. Formulas

### 4.1 Elapsed Time Display Format

```
elapsedSeconds (integer, client-side)
    │
    ├── minutes = Math.floor(elapsedSeconds / 60)
    ├── seconds = elapsedSeconds % 60
    └── display = `${minutes}:${seconds.toString().padStart(2, '0')}`

Examples:
    0s  → "0:00"
   45s  → "0:45"
   90s  → "1:30"
  600s  → "10:00"
```

The counter increments every 1 second via a client-side `setInterval` that starts at queue entry confirmation (HTTP 200 OK from POST /v1/matchmaking/queue). It is cleared on cancel, match found, or timeout.

### 4.2 MMR Bracket Visual — Progress Bar Fill Percentage

The Matchmaking Engine expands from a minimum spread (`mmrSpreadMin = 300`) to a maximum spread (`mmrSpreadCap = 600`). The bracket indicator maps the current `mmrSpread` from `queue_status` onto a 0–100% progress bar fill:

```
fillPercent = clamp(
    (mmrSpread - mmrSpreadMin) / (mmrSpreadCap - mmrSpreadMin) × 100,
    0,
    100
)

where:
    mmrSpreadMin = 300   (initial spread at queue entry)
    mmrSpreadCap = 600   (maximum spread cap)
    mmrSpread    = current spread value from queue_status event

Examples:
    mmrSpread = 300  →  fillPercent = 0%    (tight — bar empty / at minimum)
    mmrSpread = 450  →  fillPercent = 50%
    mmrSpread = 600  →  fillPercent = 100%  (wide — bar full)
```

The visual update is animated with a short ease-in-out transition (200ms default) so the bar does not jump.

### 4.3 Estimated Wait Display Format

```
estimatedWaitSec (integer, from queue_status event)
    │
    ├── if estimatedWaitSec < 60:
    │       display = "Est. ~{estimatedWaitSec}s"
    └── if estimatedWaitSec >= 60:
            minutes = Math.floor(estimatedWaitSec / 60)
            seconds = estimatedWaitSec % 60
            display = seconds > 0
                ? "Est. ~{minutes}m {seconds}s"
                : "Est. ~{minutes}m"

Examples:
    estimatedWaitSec = 30  →  "Est. ~30s"
    estimatedWaitSec = 75  →  "Est. ~1m 15s"
    estimatedWaitSec = 120 →  "Est. ~2m"
```

---

## 5. Edge Cases

### 5.1 Network Loss Mid-Queue

See §3.10 for the full reconnect-and-reconcile flow. Key invariant: the player must never be left in a stale "Searching…" state with no valid server queue entry. The GET /v1/matchmaking/queue/status reconciliation step on reconnect is mandatory.

### 5.2 Queue Timeout While App is Backgrounded

If the `queue_timeout` Socket.io event arrives while the app is in the background:

1. The event is buffered by the Socket.io client (or received on foreground resume depending on OS socket lifecycle).
2. On foreground resume, the app checks its internal state:
   - If the queue was active and a `queue_timeout` was received (or GET /v1/matchmaking/queue/status returns dequeued), navigate to Lobby Timeout state with the standard message and Try Again / Back options.
   - The elapsed time counter is not shown in the timeout state; only the message and buttons are relevant.
3. No background push notification is sent for queue timeout at MVP (push infrastructure is not in scope until the Party/Presence milestone).

### 5.3 Match Found While App is Backgrounded

1. The server sends a push notification with payload `{ type: "match_found", sessionId }`.
2. On tap of the push notification, the app foregrounds and navigates directly to Character/Deck Select with `sessionId`.
3. If the app foregrounds via another path (e.g. app switcher) and the `match_found` event is still pending in the Socket.io buffer, the standard §3.6 flow applies on reconnect.
4. If the session has expired by the time the player foregrounds (e.g. took too long), the Character/Deck Select screen must handle a stale `sessionId` gracefully — this is the responsibility of the Character/Deck Select system, not the Lobby.

Push notification infrastructure is a prerequisite for this edge case. If push is not available at MVP, the behaviour degrades to: on foreground, call GET /v1/matchmaking/queue/status; if `match_found` data is returned, proceed to Character/Deck Select.

### 5.4 Player Already in a Session Tries to Queue

If the POST /v1/matchmaking/queue returns HTTP 409 (Conflict) with an error code indicating the player is already in an active session:

1. The Lobby screen shows an inline error message: *"You are already in an active match."*
2. A **"Rejoin Match"** button navigates to Character/Deck Select (or directly to the match, depending on session state) with the existing `sessionId` from the 409 response body.
3. A **"Cancel"** button in the error state sends DELETE /v1/matchmaking/queue (or a dedicated session-leave endpoint) and returns to main menu. The exact endpoint for abandoning an active session is the responsibility of the Matchmaking Engine spec — the Lobby passes the action and handles the response.

### 5.5 Game Mode Toggled Off via Remote Config While Player is Queued

If the Matchmaking Engine server-side dequeues the player because the mode was disabled via Remote Config:

1. The server emits a Socket.io event (modelled as a `queue_status` or a dedicated `dequeued` event — the exact event shape must be confirmed with the Matchmaking Engine team).
2. The Lobby detects the dequeue and navigates to main menu mode select.
3. The mode card for the disabled mode is greyed out with a "Temporarily Unavailable" label (driven by Remote Config flag delivery to client).
4. A toast notification is shown: *"[Mode Name] is temporarily unavailable — you have been removed from the queue."*

**Dependency note**: The exact Socket.io event for server-side dequeue must be defined in the Matchmaking Engine GDD. This GDD assumes such an event exists and is distinguishable from a standard `queue_timeout`.

---

## 6. Dependencies

### 6.1 Upstream Dependencies

| System | What Lobby Needs | Notes |
|---|---|---|
| **Matchmaking Engine** | POST /v1/matchmaking/queue, DELETE /v1/matchmaking/queue, GET /v1/matchmaking/queue/status; Socket.io events: `queue_status`, `match_found`, `queue_timeout`, and a server-initiated dequeue event | Core dependency — Lobby cannot function without this |
| **Remote Config** | List of available game modes with enabled/disabled flags | Used to grey out unavailable modes before queue entry and to handle server-side dequeue on mode disable |
| **Push Notification Service** | Push payload `{ type: "match_found", sessionId }` for background match delivery | Soft dependency at MVP — degrades gracefully if unavailable |
| **Authentication / Player Profile** | Authenticated player token for queue entry; player MMR for bracket display context | MMR value is passed to Matchmaking Engine; Lobby does not compute MMR |

### 6.2 Downstream Dependencies

| System | What It Needs from Lobby | Notes |
|---|---|---|
| **Character/Deck Select** | Navigation event with `sessionId` from `match_found` payload | Lobby initiates navigation after the 1.5s match-found animation |

### 6.3 Stubbed at MVP

| System | Status | Notes |
|---|---|---|
| **Party/Presence System** | Stubbed — "Party Up (Coming Soon)" placeholder only | Full party formation ships in Vertical Slice tier |

---

## 7. Tuning Knobs

These values can be adjusted without code changes if exposed via Remote Config or a server-side config endpoint. Values listed are defaults.

| Knob | Default | Description | Location |
|---|---|---|---|
| `queueStatusUpdateIntervalSec` | 5 | How often the Matchmaking Engine emits `queue_status` events (server-side) | Matchmaking Engine config |
| `matchFoundAnimationDurationMs` | 1500 | Duration of the "Match Found!" celebration animation before navigating to Character/Deck Select | Client Remote Config |
| `timeoutMessageDisplayMode` | `persistent` | Whether the timeout message auto-dismisses (`autoDismiss`) or persists until player action (`persistent`). Default: persistent | Client Remote Config |
| `timeoutMessageAutoDismissSec` | 10 | Seconds before auto-dismiss if `timeoutMessageDisplayMode` = `autoDismiss` | Client Remote Config |
| `bracketIndicatorTransitionMs` | 200 | Ease-in-out animation duration for MMR bracket progress bar update | Client constant (refactor to Remote Config if needed) |
| `bracketVisualUpdateOnEveryEvent` | `true` | If `false`, bracket visual updates only when spread value changes by ≥ 50 MMR points (reduce visual noise) | Client Remote Config |
| `reconnectRetryBudgetSec` | 30 | How long the client attempts Socket.io reconnection before showing the hard "Could not reconnect" message | Client Remote Config |
| `queueTimeoutSec` | 60 | Duration before `queue_timeout` event is emitted (server-side; matches Matchmaking Engine default) | Matchmaking Engine config |

---

## 8. Acceptance Criteria

All criteria use the format: **Given / When / Then**.

### AC-L-01: Successful Queue Entry

**Given** the player is on the Lobby screen with a valid game mode selected and is authenticated  
**When** the player taps "Find Match"  
**Then** POST /v1/matchmaking/queue is sent with the correct `{ gameMode }` payload; the UI transitions to Searching state showing the animated indicator, elapsed time counter starting at 0:00, an estimated wait label, the MMR bracket indicator, the "Playing Solo" label, and the "Cancel" button

### AC-L-02: Queue Status Updates

**Given** the player is in Searching state  
**When** a `queue_status` Socket.io event is received  
**Then** the estimated wait label updates to reflect `estimatedWaitSec` from the payload; the MMR bracket indicator fill percentage updates according to the formula in §4.2; no UI flash or reset of the elapsed time counter occurs

### AC-L-03: Cancel Queue — Happy Path

**Given** the player is in Searching state (no `match_found` event pending)  
**When** the player taps "Cancel"  
**Then** DELETE /v1/matchmaking/queue is sent; on HTTP 200, the player navigates to the main menu mode select screen

### AC-L-04: Cancel Queue — HTTP Error

**Given** the player is in Searching state  
**When** the player taps "Cancel" and the DELETE request returns a non-200 HTTP response  
**Then** a toast error message is shown; the player remains in Searching state; the "Cancel" button is re-enabled

### AC-L-05: Match Found Transition

**Given** the player is in Searching state  
**When** a `match_found` Socket.io event is received  
**Then** the "Match Found!" animation plays for `matchFoundAnimationDurationMs` (default 1.5s); no buttons are shown during the animation; after the animation, the app navigates to Character/Deck Select with the `sessionId` from the event payload

### AC-L-06: Match-Found / Cancel Race Condition

**Given** the player is in Searching state  
**When** `match_found` is received and the player taps "Cancel" within the same render cycle or during the animation  
**Then** no DELETE /v1/matchmaking/queue request is sent; the "Match Found!" animation plays to completion; the app navigates to Character/Deck Select

### AC-L-07: Queue Timeout

**Given** the player is in Searching state  
**When** a `queue_timeout` Socket.io event is received  
**Then** the Searching state transitions to the Timeout state showing the message "No match found — the queue timed out" and two buttons: "Try Again" and "Back to Menu"

### AC-L-08: Queue Timeout — Try Again

**Given** the player is in the Timeout state  
**When** the player taps "Try Again"  
**Then** the queue entry flow (§3.2) is executed for the same mode without returning to main menu; on HTTP 200 the player enters Searching state with the elapsed counter reset to 0:00

### AC-L-09: Queue Timeout — Back to Menu

**Given** the player is in the Timeout state  
**When** the player taps "Back to Menu"  
**Then** the player navigates to the main menu mode select screen; no DELETE request is sent (server already dequeued the player on timeout)

### AC-L-10: Connectivity Loss — Reconnect Success, Still in Queue

**Given** the player is in Searching state  
**When** the Socket.io connection drops  
**Then** the "Connection lost — attempting to reconnect" overlay is shown; Cancel remains functional  
**And When** the connection is re-established and GET /v1/matchmaking/queue/status returns a queued status  
**Then** the overlay is dismissed and Searching state resumes

### AC-L-11: Connectivity Loss — Reconnect Success, Dequeued by Server

**Given** the player is in Searching state  
**When** the Socket.io connection drops, reconnection succeeds, and GET /v1/matchmaking/queue/status returns a dequeued status  
**Then** the overlay is dismissed; the player navigates to main menu mode select; a message is shown: "You were removed from the queue due to a connection issue."

### AC-L-12: Connectivity Loss — Reconnect Failure

**Given** the player is in Searching state with the connectivity-loss overlay showing  
**When** reconnection fails after `reconnectRetryBudgetSec` seconds  
**Then** the overlay message updates to "Could not reconnect. Please check your connection." and a "Go to Menu" button is shown

### AC-L-13: Queue Timeout While Backgrounded

**Given** the player is in Searching state and the app is sent to the background  
**When** `queue_timeout` is received and the app returns to the foreground  
**Then** the app checks queue status and presents the Timeout state (message + Try Again / Back) rather than Searching state

### AC-L-14: Match Found While Backgrounded

**Given** the player is in Searching state and the app is in the background  
**When** a `match_found` push notification is received and the player taps it  
**Then** the app foregrounds and navigates directly to Character/Deck Select with the `sessionId` from the push payload

### AC-L-15: Player Already in Session

**Given** the player attempts to enter the queue  
**When** POST /v1/matchmaking/queue returns HTTP 409 with an active session error  
**Then** an inline error is shown: "You are already in an active match."; a "Rejoin Match" button navigates to Character/Deck Select or the active match; a "Cancel" option is present to abandon and return to main menu

### AC-L-16: Game Mode Disabled via Remote Config While Queued

**Given** the player is in Searching state  
**When** the server dequeues the player due to Remote Config mode disable  
**Then** the player is navigated to main menu mode select; the disabled mode card is greyed out with "Temporarily Unavailable"; a toast is shown: "[Mode Name] is temporarily unavailable — you have been removed from the queue."

### AC-L-17: Solo Queue Label Always Visible

**Given** any state of the Lobby screen at MVP (pre-queue, searching, timeout)  
**Then** the "Playing Solo" label is visible; the "Party Up (Coming Soon)" button is visible and non-interactive; tapping it shows a tooltip and does not navigate

### AC-L-18: Elapsed Time Counter Format

**Given** the player is in Searching state  
**When** the elapsed time is 0 seconds  
**Then** the counter shows "0:00"  
**When** the elapsed time is 90 seconds  
**Then** the counter shows "1:30"  
**When** the elapsed time is 600 seconds  
**Then** the counter shows "10:00"

---

*End of Document*
