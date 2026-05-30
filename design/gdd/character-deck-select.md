# Character / Deck Select — Game Design Document
> **System**: Character / Deck Select
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

The Character / Deck Select screen is the pre-match preparation phase that occupies the `character_select` session state between the Lobby (match found) and the active match. It is the only moment in BRAWLZONE where the player composes their full configuration — choosing which of their owned characters to play and setting which two active abilities they bring into the fight — before committing to a match that is already locked and waiting.

### What This Screen Owns

| Responsibility | Description |
|---|---|
| **Character browsing** | Scrollable carousel or grid of all 8 characters; locked characters visible with lock icon and unlock tooltip; owned characters fully tappable |
| **Character selection** | Tapping an owned character sets it as the active preview; confirms intent but does not submit to the server until the player taps Confirm |
| **Character detail panel** | Displays selected character's name, archetype icon, passive ability name and description, and the two active ability slots |
| **Loadout editor** | Per-slot ability picker (bottom sheet or modal); ability browsing by archetype; ability details including cooldown, description, and affinity indicator |
| **Confirmation** | "Confirm" button submits `{ characterId, deckId }` to the Session Manager via the `player_select_character` event; transitions the UI to a locked "Waiting" state |
| **Countdown display** | Server-driven countdown timer derived from `countdown_tick` events; displayed prominently in the screen header; visual urgency states at configurable thresholds |
| **Grace period notification** | When the grace period is active and the player has not confirmed, display a "X seconds to auto-select" warning derived from `SESSION_READY_GRACE_MS` |
| **Opponent status panel** | Shows opposing player(s) confirmation status; at MVP, text-based ("Opponent is choosing…"); at stretch, reveals opponent character icon after they confirm |
| **Multi-player layouts** | Mode-specific slot grids for 3v3 Squad Brawl (6 slots, 2 teams) and FFA (8 slots) in addition to the base 1v1 Duel layout |
| **Auto-select notification** | Informs the player when the server auto-submitted their last saved loadout because the grace period expired before they confirmed |
| **Session abandoned navigation** | If the session transitions to `abandoned` while this screen is active, navigate back to Main Menu with a "Match cancelled" toast |

### What This Screen Does NOT Own

- Matchmaking or session creation (owned by Matchmaking Engine and Session Manager)
- Persistent loadout saving outside this match context (owned by Deck/Loadout System and Player Profile)
- Match simulation or in-match state (owned by Match Server)
- Character unlock progression or purchase flow (owned by Character System and IAP layer; this screen surfaces tooltip only)
- Ability unlock progression (owned by Deck/Loadout System and Inventory)
- MMR or ranking display (owned by MMR/Ranked system; not shown on this screen)

---

## 2. Player Fantasy

### The Ritual of Choosing Your Fighter

Every match in BRAWLZONE starts with a moment of intent. The Character / Deck Select screen is that moment made tangible. A player arrives here after the adrenaline spike of "Match Found" — they know a real opponent is waiting, a real match is seconds away — and they have to decide: *Who am I going to be in this fight? What am I going to bring?*

For a new player, this screen is discovery. They scroll through characters they are still learning, look at passive ability descriptions to remember what each fighter does, and pick the one that feels right today. They may not have deeply considered their ability loadout yet; the default configuration is there to give them something valid without friction.

For an experienced player, this screen is a pregame ritual. They already know their main. They open their loadout, glance at the two slots, and make a deliberate decision about which tools match the situation. If the stretch opponent-reveal feature is active, they read the opponent's character choice and adjust. This is the strategic layer of BRAWLZONE expressing itself before a single attack has been thrown. The player who wins the mental game at character select — bringing counters, building synergies, anticipating threats — is already ahead before the match loads.

### The Tension of the Countdown

There is a countdown clock on this screen, and it means something. The match will start whether the player is ready or not. That pressure is intentional: it creates stakes around the preparation ritual, forces decisions, and prevents indefinite deliberation. The right design tension is "enough time to be thoughtful, not enough time to be agonized." At the urgency threshold, the visual design communicates that the window is closing. When time runs out, the auto-select behavior resolves the situation fairly and cleanly, but the player should feel the mild regret of not having controlled their own destiny in that moment.

### The Satisfaction of a Well-Considered Loadout

When a player taps "Confirm" on a loadout they constructed deliberately — one where they considered their character's passive, chose abilities that synergize, and thought about what the opponent might bring — and the confirmation lock appears with "Waiting for opponent…", they should feel *ready*. Not anxious. Ready. The screen has done its job when a player enters the match feeling like a craftsperson who packed the right tools, not a passenger who was assigned a seat.

### The Moment of Commitment

Confirmation is irreversible for this match. That permanence is part of the fantasy. The player made a choice, and now they own it. There is no second-guessing after the lock. This creates accountability — wins feel more earned, losses are learnable moments — and makes the loadout decision itself feel meaningful rather than arbitrarily changeable.

---

## 3. Detailed Rules

### 3.1 Screen Layout

The Character / Deck Select screen is divided into four primary zones, laid out vertically to respect mobile safe area insets (top notch/status bar, bottom home indicator). All zones must be scrollable if content overflows the available safe height.

```
┌─────────────────────────────────────────────┐  ← Safe area top (inset)
│  [Mode Icon]  CHOOSE YOUR FIGHTER  [Timer]  │  ← Header bar
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │          CHARACTER CAROUSEL           │  │  ← Zone 1
│  │  [C1] [C2] [C3] [C4] [C5] [C6] [C7] [C8]│
│  └───────────────────────────────────────┘  │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │        SELECTED CHARACTER DETAIL      │  │  ← Zone 2
│  │  [Character Art]  [Name]  [Archetype] │  │
│  │  Passive: [Name] — [Description]      │  │
│  │  Slot 1: [Ability Name or Empty]      │  │
│  │  Slot 2: [Ability Name or Empty]      │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │         OPPONENT STATUS PANEL         │  │  ← Zone 3
│  │  [Player Name] is choosing...         │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │  [CONFIRM SELECTION]                  │  │  ← Zone 4 (sticky bottom)
│  │  (grayed + "Waiting..." when locked)  │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘  ← Safe area bottom (inset)
```

**Zone 1 — Character Carousel:**
- Horizontally scrollable row of all 8 character card thumbnails.
- Each card shows: character portrait, character name, and ownership state.
- Owned characters: fully colored, tappable.
- Locked characters: desaturated with a lock icon overlay, tappable only to show unlock tooltip (cannot enter selection flow).
- Active selection is highlighted with a selection ring or accent border.
- Carousel snaps to the selected character on load (defaults to the player's most recently played character if one exists, otherwise the first free character).

**Zone 2 — Selected Character Detail Panel:**
- Displays the currently previewed character (updates on every carousel tap, even before Confirm).
- Character name, archetype label (Offensive / Defensive / Utility), and full-height character art or icon.
- Passive ability name and description (read-only; cannot be changed).
- Slot 1 ability display: tappable to open ability picker. Shows ability name, archetype color chip, and affinity indicator if the ability has affinity with the selected character. Shows "Tap to pick ability" placeholder if no ability loaded.
- Slot 2 ability display: identical to Slot 1.
- If a slot contains the character's default ability (not player-customized), a subtle "Default" label may optionally be shown (non-blocking, informational).
- Ability slots are tappable until the player has confirmed. After confirmation, slots show a lock icon and are not interactive.

**Zone 3 — Opponent Status Panel:**
- In 1v1 Duel: single opponent row. Shows opponent display name and status.
  - Before opponent confirms: "{OpponentName} is choosing…" with an animated ellipsis.
  - After opponent confirms (MVP): "{OpponentName} is ready." with a checkmark icon.
  - After opponent confirms (Stretch — counter-preview enabled): opponent's chosen character icon appears alongside their name and a "Ready" indicator. Abilities are NOT shown.
- In 3v3 Squad Brawl: two sections — "Your Team" and "Enemy Team". Each section has 3 player slots, each showing player name and status. Allied players show status inline. Enemy players show only name + status (no character icon at MVP; stretch reveals character icon on confirm).
- In FFA: grid of 8 player slots (including the local player's own slot). Each slot shows player name and choosing/ready status. No character reveals for any slot at MVP.

**Zone 4 — Confirm Button (Sticky Bottom):**
- Full-width primary action button reading "CONFIRM SELECTION".
- Enabled only when: (a) a valid character is selected, (b) both ability slots are filled with unlocked, active abilities.
- Tapping triggers the confirmation flow (see Section 3.2).
- After confirmation: button grays out, label changes to "Waiting for opponent…", and a small spinner or pulsing indicator appears. No further interaction possible from this button.
- Grace period warning: when `SESSION_READY_GRACE_MS` countdown is shown, a secondary label below the button reads "Auto-selecting in X seconds" (see Section 3.4).

**Header Bar:**
- Left: game mode icon and mode name (e.g., "Duel", "Squad Brawl", "Free-for-All").
- Center: "CHOOSE YOUR FIGHTER" title.
- Right: countdown timer in `MM:SS` format. At `COUNTDOWN_URGENCY_THRESHOLD_S` seconds remaining, the timer turns red and pulses.

---

### 3.2 Character Selection Flow

```
Player taps character card in carousel
        │
        ▼
Is character owned?
  ├── No  → Show unlock tooltip (see §3.3). Exit flow.
  └── Yes → Update Zone 2 detail panel to reflect selected character.
             Load that character's saved loadout into Slot 1 and Slot 2.
             If no saved loadout: populate from character's default loadout.
             If saved loadout has a disabled ability in either slot:
               Replace that slot with character's default ability for that slot.
               Show "Ability unavailable — slot reset to default" notification.
        │
        ▼
Player taps an ability slot (Slot 1 or Slot 2)
        │
        ▼
Open Ability Picker (see §3.5)
  → Player selects an ability
  → Slot fills with chosen ability
  → If chosen ability is same as the other slot:
       Show "Duplicate ability — choose a different one" warning.
       Picker remains open. No slot change.
  → Picker closes.
        │
        ▼
Player reviews loadout (may tap again to change either slot)
        │
        ▼
Player taps "CONFIRM SELECTION"
        │
        ▼
Client validates:
  - A character is selected (characterId set)
  - Slot 1 and Slot 2 are filled with different, non-disabled ability IDs
  If validation fails: show inline error; do not submit.
        │
        ▼
Emit `player_select_character { sessionId, playerId, characterId, deckId }` to Session Manager
        │
        ▼
Await server response:
  `character_selected { sessionId, playerId }` — confirmation received
        │
        ▼
Transition to locked state:
  - Both ability slots show lock icons; not tappable
  - Carousel not tappable (character locked)
  - Confirm button disabled; label → "Waiting for opponent…"
  - Show "Your selection is locked in. Get ready!" micro-copy below slots.
        │
        ▼
Await `match_started` from Session Manager
  → Navigate to Match screen
```

**Selection rejection (server rejects `player_select_character`):**
If the server responds with `selection_rejected { reason }`:
- Unlock the confirm button (player may re-attempt).
- Show toast: "Selection failed: [human-readable reason]. Please try again."
- Reason map: `"not_owned"` → "You don't own that character."; `"invalid_deck"` → "One or more selected abilities is not available. Check your loadout."; generic → "Selection could not be confirmed. Please try again."
- Player may change character or loadout and resubmit. Their countdown window is not reset by a rejection.

---

### 3.3 Locked Characters (Not Owned)

Characters the player does not own are displayed in the carousel with a desaturated portrait and a padlock icon. They are visible to create awareness of the full roster and to surface the progression/monetization path.

**On tap of a locked character:**
- A tooltip card appears overlaid on or near the tapped character card.
- Tooltip contains:
  - Character name and a brief tagline.
  - Unlock type:
    - Earnable: "Unlock at [threshold] XP — keep playing to earn this fighter!"
    - Premium: "Available for [N] Diamonds" with a "Get Diamonds" secondary action that navigates to the Diamond store. Does not interrupt the character select session; opens a modal or navigates back to store.
  - A "Close" or tap-outside dismiss action.
- Tapping a locked character does NOT change the active character selection or update the detail panel.
- The locked character cannot receive any selection state; it is display-only.

---

### 3.4 Countdown Timer and Grace Period Behavior

**Countdown display:**
The countdown timer is server-driven. The Session Manager emits `countdown_tick { sessionId, remainingMs }` events via Socket.io once per second. The client renders:
```
remainingDisplay = formatCountdown(remainingMs)
```
(See Section 4.1 for the display formula.)

The countdown is shown in the header bar. When `remainingMs <= COUNTDOWN_URGENCY_THRESHOLD_S * 1000`, the timer display enters urgency mode: color turns red, font weight increases, and a pulse animation plays on each tick.

**Grace period (auto-select) behavior:**
The grace period (`SESSION_READY_GRACE_MS = 5000ms`) is a server-side concept managed by the Session Manager. From the client's perspective, the `countdown_tick` events communicate remaining time throughout the select phase. The client does not independently track the grace period deadline; it relies entirely on server-emitted tick events.

The client shows the grace period warning when both of the following are true:
1. `remainingMs <= GRACE_PERIOD_WARNING_THRESHOLD_MS` (configurable; default = `SESSION_READY_GRACE_MS`)
2. The local player has not yet confirmed their selection.

In this state, a secondary label below the Confirm button reads:
```
"Auto-selecting in X seconds"
```
where `X = ceil(remainingMs / 1000)`, updated each `countdown_tick`.

**At countdown expiry (grace period reached on server without player confirmation):**
- The Session Manager server-side auto-submits the player's last saved loadout for the last character they had selected (or the character's default loadout if neither exists).
- The client receives no special socket event for this auto-submission; it will receive `character_selected { playerId }` (the same confirmation event as a manual confirm).
- The client should transition to locked state upon receiving `character_selected` regardless of whether the submit was manual or automatic.
- Additionally, the client emits a local notification banner: "Auto-selected! Your last loadout was used." — this is a client-side notification triggered by detecting that `character_selected` arrived for the local player while the confirm button was still in its unconfirmed state. Display duration is configurable (`AUTO_SELECT_NOTIFICATION_MS`; default 4000ms).

---

### 3.5 Ability Picker UI

The ability picker opens as a **bottom sheet** (preferred for thumb reach on mobile) or a **modal overlay** on smaller screen sizes. It is invoked when the player taps either ability slot in Zone 2.

**Picker layout:**
```
┌─────────────────────────────────────────────┐
│  CHOOSE ABILITY FOR SLOT [1 or 2]           │  ← Title bar
│  [🔍 Search]  [All ▼] [Offensive] [Defensive] [Utility] │  ← Filter bar
├─────────────────────────────────────────────┤
│  OFFENSIVE                                  │  ← Archetype section header
│  ┌──────────┐ ┌──────────┐ ┌──────────┐   │
│  │ [Icon]   │ │ [Icon]   │ │ [Icon]   │   │
│  │ Name     │ │ Name     │ │ Name     │   │
│  │ CD: 8s   │ │ CD: 10s  │ │ CD: 9s   │   │
│  │ ★ Affinity│ │          │ │          │   │
│  └──────────┘ └──────────┘ └──────────┘   │
│  DEFENSIVE                                  │
│  [ ... ]                                   │
│  UTILITY                                    │
│  [ ... ]                                   │
├─────────────────────────────────────────────┤
│  [SELECTED ABILITY DETAIL PANEL]            │  ← Expands on tap
│  Name · Archetype · CD: Xs                 │
│  Description text full length               │
│  Affinity: [CharacterName] ★               │
└─────────────────────────────────────────────┘
```

**Picker content rules:**
- Abilities are drawn from the Deck/Loadout System's ability pool (18 abilities at MVP), filtered to only show abilities the player has unlocked.
- Locked (not yet unlocked) abilities are not shown in the picker. (They are visible in the main roster view in the Loadout editor from Main Menu, where they show as locked with unlock requirements; the in-match picker shows only what is available to select.)
- The ability currently in the *other* slot is shown but grayed out with a "Already equipped" label. Tapping it shows "Remove from other slot first" toast. It cannot be selected.
- Abilities are grouped by archetype in the scrollable list: Offensive → Defensive → Utility. Each group has a labeled header.
- The "All" filter tab shows all three archetype groups stacked. The Offensive / Defensive / Utility filter tabs show only that archetype's section.
- Affinity indicator: if an ability in the list has affinity with the currently selected character, a star icon (★) or "Affinity" label is shown on the ability card. This is informational only and does not restrict selection.
- Search: a text input filters abilities by name (case-insensitive prefix match). The archetype grouping collapses to show only matching results when a search term is active.
- Tapping an ability card selects it. A "detail panel" expands at the bottom of the picker (or in a sub-region), showing: ability name, archetype, base cooldown, full description text, and affinity character name(s) with star icon if applicable.
- A "SELECT" button in the detail panel (or a double-tap on the card) confirms the selection and closes the picker, filling the slot.
- A dismiss gesture (swipe down on the bottom sheet, or tap outside on modal) closes the picker without changing the slot.

---

### 3.6 Confirmation and Locked State

Once the player taps "CONFIRM SELECTION" and the server responds with `character_selected`:

- **Character carousel:** All character cards become non-interactive. Selected character card shows a "Locked" indicator.
- **Detail panel:** Ability slots show padlock icons. Slot tap does nothing.
- **Confirm button:** Grayed out, label → "Waiting for opponent…", spinner indicator.
- **Micro-copy:** A line below the ability slots reads: "Your loadout is set. Match starting soon."
- **Countdown timer:** Continues to run in the header. The player watches the countdown until all players confirm (or the grace period expires and the session proceeds to active).
- **No re-editing:** From this point until the match starts (or the session is abandoned), the player cannot change their character or loadout. This is enforced both client-side (UI disabled) and server-side (Session Manager ignores further `player_select_character` events from this player — idempotent; duplicate confirmations are silently ignored).

---

### 3.7 3v3 Squad Brawl Layout

In 3v3 mode, the Opponent Status Panel (Zone 3) is expanded into a full team status layout, and the Character Carousel (Zone 1) and Confirm flow remain identical to Duel.

**Team status layout:**
```
┌───────── YOUR TEAM ─────────┐   ┌───────── ENEMY TEAM ─────────┐
│ [You]     [Ally 1] [Ally 2] │   │ [Enemy 1] [Enemy 2] [Enemy 3]│
│  Locked    Choosing  Choosing│   │  Choosing  Choosing  Choosing │
└────────────────────────────-┘   └──────────────────────────────┘
```

- Each player slot shows: player display name, and status (Choosing… / Ready / Disconnected).
- Allied team: after an ally confirms, their slot shows "Ready" with a check.
- Enemy team (MVP): after an enemy confirms, their slot shows "Ready" — no character icon.
- Enemy team (Stretch): after an enemy confirms, their slot shows the chosen character's icon alongside "Ready".
- Abilities are never revealed for any player in any layout.
- The local player's own slot always shows the local player's confirmed state accurately.
- Bot slots (if `BOT_FILL_ENABLED`): labeled "[BOT] Auto" and shown as "Ready" immediately. Bot slots do not show a character icon.

---

### 3.8 FFA Layout

In 8-player Free-for-All, all 8 player slots are shown in a 2×4 or 4×2 grid in the opponent status region. The local player's slot is visually distinguished (highlight, "You" label).

```
┌────────────────────────────────┐
│ [You]      [Player2]           │
│  Locked     Choosing...        │
│ [Player3]  [Player4]           │
│  Ready      Choosing...        │
│ [Player5]  [Player6]           │
│  Choosing   Ready              │
│ [Player7]  [Player8]           │
│  Choosing   Choosing...        │
└────────────────────────────────┘
```

- All slots show: player name + choosing/ready status text.
- No character icon reveals for any player at MVP (all are "Choosing…" → "Ready" only).
- Stretch: all slots reveal chosen character icon when that player confirms.
- The grid must be scrollable if it overflows the safe area on small devices.
- Disconnected or timed-out players show "Left the match" in their slot; their slot is visually dimmed.

---

### 3.9 Session Abandoned Handling

If a `session_state_changed` event is received while on the Character / Deck Select screen with `newState === "abandoned"`:

1. Stop the countdown timer immediately.
2. Dismiss any open ability picker (bottom sheet / modal) without saving changes.
3. Display a full-screen overlay or a prominent toast: "Match Cancelled — Your opponent left or the session could not start."
4. After `SESSION_ABANDONED_RETURN_DELAY_MS` (default: 2000ms), navigate back to the Main Menu.
5. On the Main Menu, show a persistent toast notification: "Match cancelled." with a dismiss action.
6. No MMR or progression impact. The Disconnect Handler and Session Manager own that resolution.

---

## 4. Formulas

### 4.1 Countdown Display Format

The countdown timer converts `remainingMs` from the server's `countdown_tick` event to a human-readable display string.

```
formatCountdown(remainingMs: number): string

  totalSeconds = ceil(remainingMs / 1000)

  if totalSeconds >= 60:
    minutes = floor(totalSeconds / 60)
    seconds = totalSeconds % 60
    return `${minutes}:${String(seconds).padStart(2, '0')}`  // e.g., "1:30"
  else:
    return `${totalSeconds}s`  // e.g., "29s"

  // Special case: at 0, show "0s" (not negative values — clamp at 0)
  if remainingMs <= 0:
    return "0s"
```

| Input (remainingMs) | Display |
|---|---|
| 90000 | "1:30" |
| 60000 | "1:00" |
| 30000 | "30s" |
| 5000 | "5s" |
| 0 | "0s" |

**Urgency threshold:** When `remainingMs <= COUNTDOWN_URGENCY_THRESHOLD_S * 1000`, the timer display switches to urgency styling (red color, bold font, pulse animation). Default `COUNTDOWN_URGENCY_THRESHOLD_S = 10` (10 seconds).

---

### 4.2 Grace Period Warning Display

```
showGracePeriodWarning(remainingMs: number, playerHasConfirmed: boolean): boolean
  return !playerHasConfirmed && remainingMs <= GRACE_PERIOD_WARNING_THRESHOLD_MS

gracePeriodWarningText(remainingMs: number): string
  seconds = max(0, ceil(remainingMs / 1000))
  return `Auto-selecting in ${seconds} second${seconds !== 1 ? 's' : ''}`
```

| Variable | Default Value | Notes |
|---|---|---|
| `GRACE_PERIOD_WARNING_THRESHOLD_MS` | `SESSION_READY_GRACE_MS` = 5000ms | Show warning when ≤ this value remains and player has not confirmed |
| `SESSION_READY_GRACE_MS` | 5000ms | Owned by Session Manager; Character Select reads and displays this |

**Example:**
- `remainingMs = 3200`, player not confirmed → `showGracePeriodWarning = true`, text = "Auto-selecting in 4 seconds"
- `remainingMs = 3200`, player confirmed → `showGracePeriodWarning = false` (no warning shown)

---

### 4.3 Ability Picker Filter State

The ability picker maintains a local filter state object:

```typescript
interface AbilityPickerFilterState {
  activeArchetypeFilter: 'all' | 'offensive' | 'defensive' | 'utility';
  searchQuery: string;  // empty string = no filter
}
```

Filtered ability list computation:

```
filteredAbilities(pool, filterState, selectedCharacterId, otherSlotAbilityId):

  1. Start with player's unlocked ability pool (from Deck/Loadout System)

  2. Apply archetype filter:
     if filterState.activeArchetypeFilter !== 'all':
       keep only abilities where ability.archetype === filterState.activeArchetypeFilter

  3. Apply search filter:
     if filterState.searchQuery.length > 0:
       keep only abilities where ability.name.toLowerCase()
         .startsWith(filterState.searchQuery.toLowerCase())

  4. Sort within each archetype group:
     Primary: affinityCharacters.includes(selectedCharacterId) → affinity abilities first
     Secondary: alphabetical by ability name

  5. Mark as non-selectable (grayed):
     ability.id === otherSlotAbilityId → mark as "Already equipped"

  6. Return grouped result:
     { offensive: [...], defensive: [...], utility: [...] }
     // Empty groups are hidden (no section header rendered)
```

**Default filter state on open:** `{ activeArchetypeFilter: 'all', searchQuery: '' }`. Filter state does not persist between picker openings; it resets each time the picker is opened.

---

## 5. Edge Cases

### 5.1 Saved Loadout Contains a Disabled Ability

**Scenario:** A player's stored loadout for a character references an ability that has been set to `status: "inactive"` in the Content Catalog (e.g., a mid-season ability disable via Remote Config).

**Handling:**
1. When the character detail panel loads with this character's saved loadout, the client queries the ability pool. If an ability ID in the saved loadout resolves to an inactive or missing record, the affected slot is replaced with the character's default ability for that slot (from Content Catalog).
2. The player sees a notification banner: "[Ability Name] is no longer available — Slot [1 or 2] has been reset to [Default Ability Name]. Review your loadout." Banner remains visible for `DISABLED_ABILITY_NOTIFICATION_MS` (default 5000ms) or until dismissed.
3. The replacement is shown in the slot as a pending change — it is NOT automatically written back to the player's stored loadout. The player must tap Confirm (or re-edit the slot and confirm) for any save to occur.
4. If the player does not interact before auto-select fires, the server-side auto-submit uses the last successfully saved loadout from the Player Profile, which may also contain the disabled ability. In that case, the server-side validation at Session Manager (§3.5 of session-manager.md) detects the invalid deck and substitutes the default. No match cancellation occurs.

---

### 5.2 Player Loses Connection During Character Select

**Scenario:** The player's network connection drops while the session is in `character_select`.

**Handling:**
1. The client detects Socket.io disconnection (transport close event) and shows a reconnecting indicator: "Reconnecting… your selection may be auto-submitted."
2. If the player had already confirmed before disconnecting: the server has recorded their selection (`character_selected` was emitted); the session continues without them in the UI sense. If they reconnect before `match_started`, they rejoin the character select screen in locked state. If `match_started` has already fired, they are routed directly to the match.
3. If the player had NOT yet confirmed before disconnecting: the server-side Session Manager runs the grace period and init timeout logic. If the player reconnects before `SESSION_INIT_TIMEOUT_MS` expires, they may still confirm manually. If the grace period expires first, the server auto-submits using last saved loadout (or default). The client receives `character_selected` and `match_started` on reconnection, at which point it navigates to the match.
4. If the player does not reconnect before `SESSION_INIT_TIMEOUT_MS` and the session has insufficient players to start, the session transitions to `abandoned`. On reconnection, the client receives `session_abandoned` and navigates to Main Menu with "Match cancelled" toast.
5. If the player does not reconnect at all: the Disconnect Handler notifies the Session Manager, which applies the rules in session-manager.md §3.5 (disconnect during character select — minimum player evaluation).

---

### 5.3 Two Players Confirm at the Exact Same Tick

**Scenario:** Both players in a 1v1 Duel emit `player_select_character` in the same server-side event processing cycle.

**Handling:** Both submissions are accepted. The Session Manager processes each independently and emits `character_selected` for each player. There is no conflict because character selections do not have a "first-come, first-served" constraint for distinct players. The session immediately transitions to `active` since all players are now confirmed. Both players receive `match_started` and navigate to the match. No special handling required on the client.

---

### 5.4 Player Taps "Confirm" Repeatedly

**Scenario:** Network latency causes the player to tap "Confirm" multiple times before the server response arrives.

**Handling:**
1. On the first tap, the client disables the Confirm button immediately (optimistic UI lock). Subsequent taps are ignored because the button is no longer interactive.
2. The `player_select_character` event is emitted once.
3. If the server's `character_selected` response arrives, the client transitions to full locked state (permanent).
4. If the server's `selection_rejected` response arrives, the client re-enables the Confirm button and shows the rejection reason (see §3.2).
5. Server-side: if a second `player_select_character` event somehow arrives from the same player (network retry, client bug), the Session Manager treats it as idempotent — the second event is silently ignored if the player's `characterSelections[playerId]` is already set. No duplicate `character_selected` events are emitted.

---

### 5.5 Session Abandoned While Player is on Character Select Screen

**Scenario:** The session transitions to `abandoned` (for any `AbandonReason`) while the player is browsing characters or mid-way through loadout editing.

**Handling:**
1. Client receives `session_state_changed { newState: "abandoned" }` or `session_abandoned` from the socket.
2. Any open ability picker (bottom sheet / modal) is dismissed immediately without saving changes.
3. A full-screen overlay appears: "[Reason-appropriate message]" (see reason map below). The overlay is not dismissible by the player — it auto-proceeds after `SESSION_ABANDONED_RETURN_DELAY_MS` (default: 2000ms).
4. After the delay, the client navigates to the Main Menu.
5. On the Main Menu, a toast notification appears: "Match cancelled." with a brief reason if available.

**Reason map for overlay message:**
| `AbandonReason` | Overlay Message |
|---|---|
| `all_players_disconnected` | "All players have left. Match cancelled." |
| `init_timeout` | "Match setup took too long. Match cancelled." |
| `match_server_crash` | "Server issue — match could not start. Please try again." |
| `no_server_capacity` | "No servers available right now. Please try again." |
| `insufficient_players` | "Not enough players to start. Match cancelled." |
| (unknown / generic) | "Match cancelled." |

No MMR or progression penalty is applied for any abandoned session.

---

### 5.6 Player Has No Saved Loadout for Selected Character

**Scenario:** A player selects a character they have never built a loadout for (e.g., just unlocked a new earnable character for the first time, or their Profile data is unavailable).

**Handling:**
1. The detail panel loads with the character's default loadout pre-populated in both slots (from Content Catalog `default_loadout`).
2. Both slots are tappable; the player may change either or both before confirming.
3. If the player confirms without editing, the default loadout is submitted as their selection.
4. No "empty slot" state should ever be visible to the player on initial load — the default loadout is always valid and always pre-populates.
5. If Content Catalog is unavailable and the default loadout cannot be loaded, both slots show "Tap to pick ability" placeholders. The Confirm button remains disabled until both slots are manually filled.

---

### 5.7 Ability Picker Opened with Only One Unlocked Ability of an Archetype

**Scenario:** A player has unlocked very few abilities (e.g., early-stage account with only Starter tier unlocked), and an archetype filter shows only one ability card.

**Handling:** Single-item archetype sections are displayed normally. No minimum count is required per section. If the search filter or archetype filter results in zero matching abilities, the picker shows an empty state message: "No abilities match your filter. Try a different filter or search term." The "All" tab always shows all unlocked abilities regardless of filter state and should always have at least 2 results (minimum: both Starter abilities that fit the character's play context, or whatever is unlocked).

---

### 5.8 Locked Character Tapped During Countdown

**Scenario:** The player taps a locked character while the countdown is in urgency mode (≤ 10 seconds remaining).

**Handling:** The unlock tooltip still appears as normal (see §3.3). The tooltip has an explicit dismiss button. However, the countdown continues to run behind the tooltip. If the grace period fires while the tooltip is visible:
- The tooltip is dismissed automatically.
- The grace period auto-select behavior proceeds normally (server auto-submits last saved loadout for the last *selected* character, which is still the player's previously selected owned character, not the locked one they were viewing).
- The "Auto-selected!" notification appears.
- The screen transitions to locked state.
The locked character tap does not change the active character selection.

---

## 6. Dependencies

### 6.1 Upstream Dependencies (Character / Deck Select Consumes)

| System | What Character / Deck Select Reads | When | If Unavailable |
|---|---|---|---|
| **Character System** | Full roster of 8 characters (id, name, archetype, portrait asset, passive ability description, ability slot count, unlock type); player-specific ownership state (which characters the player owns) | Screen load; carousel render | If ownership data is unavailable, show all non-free characters as locked. Free characters (3) are always shown as owned. Log error and continue — do not block screen render. |
| **Deck / Loadout System** | Saved loadout per character (slot1AbilityId, slot2AbilityId); character default loadout; full active ability pool (18 abilities at MVP) filtered to player's unlocked set | Character selection (load loadout); ability picker open (populate pool) | If saved loadout unavailable, fall back to character default. If ability pool fetch fails, show empty picker with error state: "Abilities could not be loaded. Tap to retry." Block Confirm until resolved. |
| **Lobby / Matchmaking** | `session_created` or `match_found` event that triggers navigation to this screen; sessionId; opponent player name(s) | Navigation trigger | This screen is only reachable via Lobby navigation. Lobby owns the transition. |
| **Session Manager** | `countdown_tick { sessionId, remainingMs }` — drives the countdown display; `character_selected { sessionId, playerId }` — updates opponent status and triggers local locked state; `session_state_changed` / `session_abandoned` — triggers abandoned flow; `match_started { matchServerUrl, playerSlots }` — triggers navigation to match | Real-time via Socket.io throughout the select phase | Socket.io reconnect logic handles transient drops (see Edge Case 5.2). If countdown ticks stop arriving, the last-known value is frozen with a "Reconnecting…" indicator. The screen does not attempt to self-advance the timer independently. |
| **Content Catalog** | Ability records (name, description, archetype, cooldown, affinity character IDs, active/inactive status) | Ability picker open; loadout validation at screen load | Use local cache if available. If no cache and fetch fails, display error in picker and block Confirm. |
| **Player Profile** | Player display name (for own slot in 3v3/FFA layouts); last-used character preference (for default carousel position) | Screen load | Default to blank display name for own slot; default carousel to first free character if preference unavailable. Non-blocking. |

### 6.2 Downstream Consumers (Character / Deck Select Produces)

| System | What It Receives from Character / Deck Select | How It Uses It |
|---|---|---|
| **Session Manager** | `player_select_character { sessionId, playerId, characterId, deckId }` socket event | Records the selection; emits confirmation; transitions session to active when all players ready |
| **Match Server** | Confirmed `{ characterId, deckId }` per player (delivered by Session Manager as part of `MatchConfig`) | Creates `CharacterRuntimeInstance` per player; initializes ability cooldowns; establishes player identity for the match |
| **In-Match HUD** | Character identity (characterId) for the local player and opponents (sourced from `match_started.playerSlots`) | Renders character portrait in HUD, ability slot icons, ability cooldown display, player name labels |

---

## 7. Tuning Knobs

All values are environment-variable or Remote Config configurable. No values are hardcoded in client logic. Client reads configurable values from the server config payload delivered at session creation or app init.

| Knob | Constant / Env Var | Default | Safe Range | Gameplay / UX Effect |
|---|---|---|---|---|
| **Grace period duration** | `SESSION_READY_GRACE_MS` (owned by Session Manager) | 5000ms | 3000–10000ms | How long after the first player confirms before the server auto-submits non-confirmed players. Below 3000ms causes frequent auto-selects on slow mobile connections. Above 10000ms creates unacceptable wait for confirmed players. Character Select reads and displays this value but does not control it. |
| **Grace period warning threshold** | `GRACE_PERIOD_WARNING_THRESHOLD_MS` | 5000ms (= `SESSION_READY_GRACE_MS`) | 3000–8000ms | When to show "Auto-selecting in X seconds" warning to the unconfirmed player. Setting equal to `SESSION_READY_GRACE_MS` means the warning appears exactly when the countdown enters the grace window. Setting lower means the warning appears only closer to expiry (less anxious UX). |
| **Countdown urgency visual threshold** | `COUNTDOWN_URGENCY_THRESHOLD_S` | 10s | 5–20s | When the countdown timer turns red and pulses. Below 5s leaves almost no reaction time. Above 20s may over-alarm players who have plenty of time. |
| **Countdown urgency animation duration** | `COUNTDOWN_URGENCY_PULSE_DURATION_MS` | 400ms | 200–800ms | Duration of one pulse cycle on the urgent countdown timer. Too short feels jittery; too long misses the urgency beat at 1/sec tick rate. |
| **Auto-select notification display duration** | `AUTO_SELECT_NOTIFICATION_MS` | 4000ms | 2000–6000ms | How long the "Auto-selected! Your last loadout was used." banner remains visible. Should be long enough to read, short enough to not clutter the transition to match. |
| **Disabled ability notification display duration** | `DISABLED_ABILITY_NOTIFICATION_MS` | 5000ms | 3000–8000ms | How long the "Ability no longer available" replacement banner remains visible. Longer is safer given the consequential nature of the notification. |
| **Session abandoned return delay** | `SESSION_ABANDONED_RETURN_DELAY_MS` | 2000ms | 1000–4000ms | Time to show the "Match cancelled" overlay before navigating back to Main Menu. Long enough for the player to read the message; short enough to not feel stuck. |
| **Ability picker animation duration** | `ABILITY_PICKER_ANIMATION_DURATION_MS` | 250ms | 150–400ms | Bottom sheet slide-up and dismiss animation duration. Below 150ms feels instant but jarring on lower-end devices. Above 400ms feels sluggish. |
| **Character carousel snap animation duration** | `CAROUSEL_SNAP_DURATION_MS` | 200ms | 100–350ms | Duration of carousel scroll snap when a character card is tapped. Should feel snappy without disorienting. |
| **Unlock tooltip display mode** | `UNLOCK_TOOLTIP_AUTO_DISMISS_MS` | 0 (no auto-dismiss) | 0 or 3000–8000ms | If > 0, the locked character tooltip auto-dismisses after this duration. Default 0 = player must explicitly dismiss. Auto-dismiss may be preferred in high-urgency countdown situations. |

---

## 8. Acceptance Criteria

All criteria are written as Given/When/Then. Each maps to a testable behavior that can be verified by a QA tester or automated test without game simulation knowledge.

---

### 8.1 Character Selection

**AC-CDS-01 — Owned character can be selected**
- Given: The player is on the Character / Deck Select screen with at least one owned character
- When: The player taps an owned character card in the carousel
- Then: The character detail panel updates to display that character's name, passive ability, and last saved (or default) loadout; the character card shows a selection highlight; no server event is emitted yet

**AC-CDS-02 — Locked character cannot be selected; shows unlock tooltip**
- Given: The player is on the Character / Deck Select screen; a locked character is visible in the carousel
- When: The player taps a locked character card
- Then: The character detail panel does NOT update; an unlock tooltip appears on or near the locked card showing either the XP threshold or Diamond price; the tooltip can be dismissed by tapping outside or a Close button

**AC-CDS-03 — Character detail panel reflects the selected character**
- Given: The player selects character Vex
- When: The detail panel renders
- Then: Vex's name, archetype, passive ability description, and saved loadout (or default `ability_burstsurge` / `ability_rollaway`) are displayed accurately

---

### 8.2 Loadout Editing

**AC-CDS-04 — Ability picker opens on slot tap**
- Given: The player has a character selected; they tap the Slot 1 ability display
- When: The tap is registered
- Then: The ability picker bottom sheet or modal appears; it shows the player's unlocked abilities grouped by archetype; the picker title indicates "CHOOSE ABILITY FOR SLOT 1"

**AC-CDS-05 — Archetype filter works in ability picker**
- Given: The ability picker is open with the "All" filter active
- When: The player taps the "Offensive" filter tab
- Then: Only Offensive archetype abilities are shown in the list; Defensive and Utility section headers and abilities are hidden

**AC-CDS-06 — Ability search filters by name prefix**
- Given: The ability picker is open
- When: The player types "Burst" in the search field
- Then: Only abilities whose names start with "Burst" (case-insensitive) appear in the filtered list; other abilities are hidden; archetype headers for empty sections are hidden

**AC-CDS-07 — Duplicate ability cannot be equipped in both slots**
- Given: Slot 1 contains `ability_burstsurge`; the player opens Slot 2's ability picker
- When: The player sees `ability_burstsurge` in the picker
- Then: `ability_burstsurge` is displayed but grayed out with an "Already equipped" label; tapping it shows a toast "Remove from other slot first" and does not change Slot 2

**AC-CDS-08 — Selecting an ability fills the slot and closes the picker**
- Given: The ability picker is open for Slot 2; the player taps `ability_rollaway` and taps SELECT in the detail panel
- When: The selection is confirmed
- Then: Slot 2 in the detail panel now shows `ability_rollaway`; the ability picker is dismissed; no server event is emitted

**AC-CDS-09 — Affinity indicator shown for affinity match**
- Given: Vex is the selected character; the ability picker is open; `ability_burstsurge` has affinity for Vex
- When: The picker renders
- Then: `ability_burstsurge` shows a star icon or "Affinity" label in the picker list

---

### 8.3 Confirmation and Lock

**AC-CDS-10 — Confirm button enabled only when both slots are filled**
- Given: The player has selected a character; Slot 1 is filled; Slot 2 is empty
- When: The player views the Confirm button
- Then: The Confirm button is disabled (grayed, not tappable)

**AC-CDS-11 — Confirm submits character and deck to Session Manager**
- Given: The player has selected a character and filled both ability slots
- When: The player taps "CONFIRM SELECTION"
- Then: A `player_select_character { sessionId, playerId, characterId, deckId }` event is emitted to the Session Manager; the Confirm button is immediately disabled (optimistic lock); no second event is emitted on repeated taps

**AC-CDS-12 — UI transitions to locked state after server confirmation**
- Given: The `player_select_character` event was emitted; the server responds with `character_selected`
- When: The response is processed
- Then: Both ability slots show padlock icons and are not tappable; the character carousel is not tappable; the Confirm button label reads "Waiting for opponent…" and is grayed; micro-copy "Your loadout is set. Match starting soon." is visible

**AC-CDS-13 — Server rejection re-enables confirm and shows reason**
- Given: The player taps Confirm; the server responds with `selection_rejected { reason: "not_owned" }`
- When: The rejection is processed
- Then: The Confirm button is re-enabled; a toast displays "You don't own that character."; the player may change selection and retry

---

### 8.4 Countdown Display

**AC-CDS-14 — Countdown renders correctly from server tick**
- Given: The session is in `character_select`; the server emits `countdown_tick { remainingMs: 90000 }`
- When: The client processes the event
- Then: The header timer displays "1:30"

**AC-CDS-15 — Countdown enters urgency styling at threshold**
- Given: `COUNTDOWN_URGENCY_THRESHOLD_S = 10`; the server emits `countdown_tick { remainingMs: 10000 }`
- When: The client processes the event
- Then: The timer text is rendered in red; a pulse animation is active; the display reads "10s"

**AC-CDS-16 — Countdown displays "0s" at expiry and does not go negative**
- Given: The server emits `countdown_tick { remainingMs: 0 }`
- When: The client processes the event
- Then: The timer displays "0s"; no negative value is shown

---

### 8.5 Grace Period Auto-Select

**AC-CDS-17 — Grace period warning shown when player has not confirmed**
- Given: `GRACE_PERIOD_WARNING_THRESHOLD_MS = 5000`; the server emits `countdown_tick { remainingMs: 4000 }`; the player has NOT yet confirmed
- When: The client processes the event
- Then: A warning label "Auto-selecting in 4 seconds" appears near the Confirm button

**AC-CDS-18 — Grace period warning NOT shown if player has confirmed**
- Given: The player has already confirmed their selection; the server emits `countdown_tick { remainingMs: 2000 }`
- When: The client processes the event
- Then: No grace period warning is displayed; the screen remains in locked state

**AC-CDS-19 — Auto-select notification shown when server auto-submits**
- Given: The player has NOT confirmed; the grace period expires; the server auto-submits and emits `character_selected { playerId }` for the local player
- When: The client receives `character_selected` while the local player's confirm button is in unconfirmed state
- Then: The UI transitions to locked state; a notification banner "Auto-selected! Your last loadout was used." appears and remains for `AUTO_SELECT_NOTIFICATION_MS` milliseconds

---

### 8.6 Disabled Ability Handling

**AC-CDS-20 — Disabled ability in saved loadout triggers slot replacement and notification**
- Given: The player's saved loadout for Vex contains `ability_disruptpulse` which is currently `status: "inactive"`; the player selects Vex
- When: The character detail panel loads
- Then: The affected slot is replaced with Vex's default ability for that slot; a notification banner "Ability no longer available — slot reset to default" appears; the replacement is not auto-saved (player must confirm to persist)

**AC-CDS-21 — Disabled ability is not shown in ability picker**
- Given: `ability_disruptpulse` is `status: "inactive"`
- When: The player opens the ability picker
- Then: `ability_disruptpulse` does not appear in the picker list (not even as a grayed-out option)

---

### 8.7 Session Abandoned Navigation

**AC-CDS-22 — Session abandoned navigates to Main Menu with toast**
- Given: The player is on the Character / Deck Select screen
- When: The client receives `session_state_changed { newState: "abandoned" }` or `session_abandoned`
- Then: Any open ability picker is dismissed; a "Match Cancelled" overlay appears; after `SESSION_ABANDONED_RETURN_DELAY_MS` the player is navigated to the Main Menu; a "Match cancelled." toast is shown on the Main Menu

---

### 8.8 Multi-Player Layout (3v3 and FFA)

**AC-CDS-23 — 3v3 layout shows 6 player slots in 2 teams**
- Given: The session `gameMode` is `"squad_3v3"` (3v3)
- When: The Character / Deck Select screen renders
- Then: The opponent status zone shows exactly 6 player slots divided into "Your Team" and "Enemy Team" sections of 3 slots each; each slot shows the player name and status ("Choosing…" or "Ready")

**AC-CDS-24 — 3v3 ally confirms — slot updates to "Ready"**
- Given: The session is 3v3; ally Player B emits a confirmed selection; the server broadcasts `character_selected { playerId: B }`
- When: The client receives the event
- Then: Player B's slot in "Your Team" updates to show "Ready" with a check indicator; no character icon is shown (MVP)

**AC-CDS-25 — FFA layout shows 8 player slots in a grid**
- Given: The session `gameMode` is `"ffa_8"` (8-player)
- When: The Character / Deck Select screen renders
- Then: The opponent status zone shows exactly 8 player slots in a 2×4 or 4×2 grid; the local player's slot is visually distinguished with a "You" label; all non-local slots show "Choosing…" initially

**AC-CDS-26 — Safe area insets applied on all layouts**
- Given: The player is on a device with a notch (top inset) and home indicator (bottom inset)
- When: The Character / Deck Select screen renders in any mode (Duel, 3v3, FFA)
- Then: No interactive element or critical text is obscured by the safe area; all touch targets are within the safe area bounds; the Confirm button in Zone 4 clears the bottom home indicator

---

*End of Document*
