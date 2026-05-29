# Match Results Screen — Game Design Document
> **System**: Match Results Screen
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

The Match Results Screen is the emotional payoff screen displayed immediately after every match ends in BRAWLZONE, across all three game modes: 1v1 Duel, 3v3 Squad Brawl, and 8-player FFA.

Its job is to close the match loop cleanly — delivering outcome feedback, surfacing performance stats, communicating MMR movement, and presenting earned rewards — before returning the player to the idle state or re-queuing them for the next match.

The screen is **read-only and presentation-only at the client level**. All rewards (XP, Diamonds) and MMR updates are computed and persisted server-side at match end, before this screen is ever shown. The client receives the `match_results_payload` from Match Flow and renders it. No reward logic executes here.

### Scope at MVP
- Outcome banner, stats panel, MMR change panel, rewards panel (stub display), and action buttons are all in scope.
- Reward chest animations and spinning-wheel flows are **deferred to Alpha**.
- The Share Result button is visible but non-functional at MVP.
- The screen enforces a 3-second minimum display lock on the "Play Again" action.

### Out of Scope at MVP
- Animated reward chest open sequences
- Friend activity feed ("Your friend also played")
- Post-match social features (report, add friend)
- Share-to-social implementation

---

## 2. Player Fantasy

The Match Results Screen must deliver four distinct emotional beats, in order:

### 2.1 The Outcome Hit (0–800 ms)
The first thing the player sees is the outcome banner — large, immediate, unambiguous. **VICTORY** should feel like a celebration; the gold/green palette and entrance animation (scale-up) trigger a visceral positive response. **DEFEAT** should sting just enough — the muted grey palette is honest without being punishing. The design must avoid making DEFEAT feel clinical or dismissive; the player needs to feel the loss and want to erase it.

**DRAW** is a neutral state. It should feel resolved, not anticlimactic — the blue palette and symmetrical framing communicates "fair outcome."

### 2.2 The Performance Read (stats panel)
After the initial outcome hit, the player wants to know *how they did*. Kills, assists, score, placement, and duration are the raw material for self-assessment. A player who went 8/1 in a losing match still wants to see that 8/1. This panel validates skill even in defeat and fuels the "I was robbed / I'll do better" internal narrative that drives re-queue intent.

For 3v3, the full team scoreboard extends this: players scan for their ranking within their team, giving a secondary performance signal beyond the match outcome.

### 2.3 The Progress Signal (MMR + XP)
The MMR delta is the primary ranked progress signal. Seeing "+18 MMR" in green after a win is a concrete, numerical dopamine hit that quantifies the victory's value. Seeing "-12 MMR" in red after a loss immediately frames the next match as recovery — turning a negative feeling into forward motivation.

The XP bar fill animation communicates long-term progression even when ranked MMR goes down. A player can lose MMR but still see their XP bar tick upward, providing a secondary reward pathway that keeps engagement from bottoming out after losses.

Rank tier change — promotion or demotion — is the peak emotional moment outside of the match itself. The tier badge transition animation must feel earned and cinematic (promotion) or sobering (demotion).

### 2.4 The Re-Queue Pull (action buttons)
The 3-second lock on "Play Again" is not a punishment — it is a design breath that prevents rage-re-queuing while the outcome and stats register. The progress indicator on the button makes the wait feel active, not passive. When the button unlocks, the player is primed to act.

---

## 3. Detailed Rules

### 3.1 Payload Contract

The screen consumes `match_results_payload` exactly as defined by the Match Flow System:

```
match_results_payload = {
  matchId,             // string — unique match identifier
  gameMode,            // "duel_1v1" | "squad_3v3" | "ffa_8"
  outcome,             // "win" | "loss" | "draw"
  placement,           // 1–8 for FFA; 1 or 2 for 1v1; team rank for 3v3
  kills,               // integer ≥ 0
  assists,             // integer ≥ 0
  score,               // integer ≥ 0 (most relevant for FFA)
  mmrDelta,            // signed integer e.g. +18 or -12
  newMmr,              // absolute MMR value after update
  newRankTier,         // string e.g. "Gold", "Diamond", "Bronze"
  xpEarned,            // integer; may be stub value at MVP
  diamondsEarned,      // integer; may be stub value at MVP
  matchDurationSec,    // integer seconds
  bonusFlags: {
    playPassActive,    // boolean
    noAds              // boolean
  }
}
```

The screen must not attempt to re-derive or re-compute any values in this payload. All displayed values come directly from the payload.

---

### 3.2 Screen Layout (Top to Bottom)

The screen is composed of five sections, stacked vertically, with safe area insets applied at top and bottom:

```
┌─────────────────────────────────────┐
│  [SAFE AREA TOP]                    │
│                                     │
│  ① OUTCOME BANNER                   │
│     VICTORY / DEFEAT / DRAW         │
│     game mode label + placement     │
│                                     │
│  ② MATCH STATS PANEL                │
│     kills / assists / score         │
│     duration / placement            │
│     [3v3: full team scoreboard]     │
│                                     │
│  ③ MMR CHANGE PANEL                 │
│     prev MMR → arrow → new MMR      │
│     delta badge (+18 / -12)         │
│     [rank tier badge if changed]    │
│                                     │
│  ④ REWARDS PANEL (MVP stub)         │
│     +X XP  [XP bar]                 │
│     +X 💎  [+25% tag if PlayPass]   │
│                                     │
│  ⑤ ACTION BUTTONS                   │
│     [Play Again]  [Main Menu]       │
│     Share Result (disabled)         │
│                                     │
│  [SAFE AREA BOTTOM]                 │
└─────────────────────────────────────┘
```

All five sections are present for every match outcome and every game mode, with mode-specific content variations noted below.

---

### 3.3 Section ①: Outcome Banner

**Content:**
- Primary text: `VICTORY`, `DEFEAT`, or `DRAW`
- Secondary line: game mode label (e.g., "1v1 Duel", "Squad Brawl", "FFA") + placement string (e.g., "1st Place", "3rd Place", "Top 3 of 8")

**Color coding:**

| Outcome | Primary Color | Background Tint |
|---------|--------------|-----------------|
| WIN     | Gold (#FFD700) / Green accent | Warm gold-green |
| DEFEAT  | Grey (#9E9E9E) / Dark accent | Cool dark grey |
| DRAW    | Blue (#4FC3F7) / Neutral | Neutral blue |

**Entrance animation:**
- Style: scale-up from 0.6x to 1.0x, with an opacity fade from 0 to 1
- Duration: 800 ms (configurable via `OUTCOME_BANNER_ANIM_MS` tuning knob)
- Easing: spring/overshoot on WIN (slight bounce past 1.0x, settles); linear ease-out on DEFEAT; ease-in-out on DRAW
- The outcome banner animates in immediately when the screen mounts — no wait for payload data beyond what is already present in the payload passed by Match Flow

**Placement string rules:**
- FFA (8-player): "1st Place" through "8th Place"
- 1v1 Duel: no placement string shown (outcome is unambiguous from WIN/DEFEAT)
- 3v3 Squad Brawl: "1st Place" / "2nd Place" / "3rd Place" for team rank

---

### 3.4 Section ②: Match Stats Panel

**Common fields (all modes):**
| Field | Source | Display label |
|-------|--------|---------------|
| Kills | `payload.kills` | Kills |
| Assists | `payload.assists` | Assists |
| Match duration | `payload.matchDurationSec` | Duration |

**Mode-specific fields:**

**1v1 Duel:**
- Kills, Assists, Duration
- Placement not shown (redundant with outcome banner)

**FFA (8-player):**
- Kills, Assists, Score, Placement (e.g., "3rd / 8")
- Score is the primary ranking metric; display prominently

**3v3 Squad Brawl:**
- Individual row for the local player: Kills, Assists
- Full team scoreboard below: one row per player (6 rows: 3 friendly + 3 enemy), columns: Player Name, Kills, Assists, Score
- Friendly team rows are visually highlighted (light background tint)
- Enemy team rows are de-emphasized (standard background)
- Local player's row is further distinguished with a highlight border or bold label

**Duration format:** `mm:ss` (e.g., `02:47`). If duration < 60 s: `0:ss`.

---

### 3.5 Section ③: MMR Change Panel

**Layout:**
```
[ prevMmr ]  →  [ newMmr ]
              [ delta badge ]
```

- `prevMmr` = `payload.newMmr - payload.mmrDelta` (derived client-side for display only)
- Arrow: a right-pointing icon between the two MMR values
- `newMmr`: `payload.newMmr`
- Delta badge: displayed below the arrow row

**Delta badge formatting:**
- Positive delta (`mmrDelta > 0`): `+18 MMR`, color green (#4CAF50)
- Negative delta (`mmrDelta < 0`): `-12 MMR`, color red (#F44336)
- Zero delta (draw with no MMR change): `0 MMR`, color neutral grey (#9E9E9E)

**Rank tier badge display:**
- Always show current rank tier badge (`payload.newRankTier`) as a small icon/badge
- If rank tier **did not change**: display `newRankTier` badge statically with no animation
- If rank tier **changed** (promotion or demotion): trigger the tier badge transition animation (see §3.5.1)

**3.5.1 Rank Tier Change Animation:**
- Triggers only when `newRankTier` represents a tier different from the player's pre-match tier (the client must have stored the pre-match tier, sourced from the last known local state or passed by Match Flow — see Dependencies §6.1)
- Sequence:
  1. Old tier badge is displayed (0–400 ms)
  2. Sparkle/burst particle effect plays over old badge (400–900 ms)
  3. New tier badge fades/scales in (900–1800 ms)
  4. Brief hold on new badge (1800–2000 ms)
- Total duration: max 2000 ms (`RANK_TIER_ANIM_MS` tuning knob)
- The tier change animation plays **before** action buttons appear (buttons enter after animation completes or after `RESULTS_MIN_DISPLAY_MS`, whichever is longer — see §3.7)
- Both promotion and demotion use this same animation sequence; the new badge is simply the promoted or demoted tier badge
- If promotion and demotion somehow arrive simultaneously (impossible in practice — see Edge Cases §5.4), use `payload.newRankTier` as ground truth and animate to that value

---

### 3.6 Section ④: Rewards Panel (MVP Stub)

At MVP, the rewards panel displays earned values as clean numeric text. No chest animation, no spinning wheel, no progressive unlock sequence.

**XP display:**
- Label: `+{xpEarned} XP`
- XP bar: a horizontal progress bar showing the player's XP progress toward the next level
- XP bar fill animation: animates from pre-match XP position to post-match XP position over `XP_BAR_FILL_MS` (configurable)
- If the XP bar crosses a level boundary mid-fill, the bar resets to 0% and continues filling to the remainder, showing a "Level Up!" text flash
- XP bar fill animation starts after the outcome banner entrance animation completes (sequenced, not simultaneous)

**Diamonds display:**
- Label: `+{diamondsEarned} 💎`
- If `bonusFlags.playPassActive === true`: show a small tag immediately to the right of the diamond amount reading `+25% bonus` in a distinct accent color (e.g., purple or gold)
- If `bonusFlags.playPassActive === false`: no bonus tag shown

**No "coming soon" messaging is displayed to the player.** The stub values are shown as real earned values. The deferred chest/animation flow is a visual enhancement, not a logical gate — the rewards are already server-persisted.

**Async reward arrival:**
- If the rewards data (xpEarned, diamondsEarned) is not yet present when the screen mounts (e.g., async delivery via a separate call), display placeholder dashes (`—`) in the rewards panel
- When the data arrives, update the values in-place with a brief fade-in transition on the numbers only
- The rest of the screen (outcome banner, stats panel, MMR panel) must not re-animate when rewards data arrives late

---

### 3.7 Action Buttons

**Buttons present:**
1. **Play Again** — re-queues for the same game mode (`payload.gameMode`)
2. **Main Menu** — navigates to the main menu / lobby
3. **Share Result** — visible but disabled at MVP; tooltip on tap: "Coming in a future update"

**Layout:** Play Again and Main Menu are the primary CTAs, displayed as full-width or paired horizontal buttons. Share Result is a tertiary text/icon button below the pair.

**"Play Again" lock timer:**
- On screen mount, "Play Again" is disabled
- A circular or linear progress indicator on/around the button fills over `RESULTS_MIN_DISPLAY_MS` (3000 ms)
- After 3000 ms, the button enables and the progress indicator disappears
- This lock applies regardless of how quickly all data loads; the 3-second wait is a UX intent, not a data-loading gate
- The timer starts on screen mount, not on data arrival

**"Main Menu" button:**
- Always enabled immediately (no lock)
- Tapping before the 3-second lock expires is allowed; player forfeits the "Play Again" convenience but can leave freely

**"Play Again" behavior:**
- Triggers Match Flow re-queue for `payload.gameMode`
- Does not navigate away immediately; Match Flow handles the transition
- If Match Flow is unavailable/errored, display an inline error state on the button ("Could not re-queue — try again")

---

### 3.8 Safe Area & Layout Constraints

- All content must respect safe area insets (top notch/status bar, bottom home indicator) via React Native's `SafeAreaView` or `useSafeAreaInsets`
- The screen must not clip content on devices with notches, dynamic islands, or large bottom insets
- The layout must be scrollable if content overflows the visible area (3v3 scoreboard is the most likely overflow case)
- Minimum touch target for all interactive elements: 44×44 pt (Apple HIG / Android minimum)
- "Play Again" and "Main Menu" buttons must be reachable with one-handed bottom-of-screen interaction; position them in the lower portion of the layout

---

## 4. Formulas

### 4.1 MMR Delta Display

```
prevMmr     = payload.newMmr - payload.mmrDelta
displayDelta = payload.mmrDelta

if displayDelta > 0:
    label = "+" + displayDelta + " MMR"
    color = GREEN (#4CAF50)
else if displayDelta < 0:
    label = displayDelta + " MMR"     // mmrDelta is already negative, renders as "-12 MMR"
    color = RED (#F44336)
else:
    label = "0 MMR"
    color = NEUTRAL_GREY (#9E9E9E)
```

### 4.2 XP Bar Progress Calculation

```
// Requires: player level data (current level, xpAtLevelStart, xpToNextLevel)
// These are sourced from local player profile state, not from match_results_payload

preFillPercent  = (preMatchXp - xpAtLevelStart) / xpToNextLevel   // 0.0–1.0
postFillPercent = (preMatchXp + payload.xpEarned - xpAtLevelStart) / xpToNextLevel

if postFillPercent >= 1.0:
    // Level-up scenario
    fillToEdge      = 1.0 - preFillPercent      // remaining fill to 100%
    overflowPercent = postFillPercent - 1.0     // remainder for next level
    // Animate: fill from preFillPercent to 1.0, then reset to 0.0, fill to overflowPercent
    // Show "Level Up!" text at the 1.0 boundary crossing
else:
    // Normal scenario
    // Animate: fill from preFillPercent to postFillPercent
```

XP bar animation speed is driven by `XP_BAR_FILL_MS`: the bar fills the entire distance (preFill → postFill, normalized to 0–100%) in that many milliseconds. If level-up wraps, the overflow fill plays at the same speed (not doubled).

### 4.3 Results Minimum Display Timer

```
screenMountTime = Date.now()    // recorded on component mount

isPlayAgainEnabled():
    return (Date.now() - screenMountTime) >= RESULTS_MIN_DISPLAY_MS

// Progress indicator value (0.0 to 1.0):
lockProgress():
    elapsed = Date.now() - screenMountTime
    return min(elapsed / RESULTS_MIN_DISPLAY_MS, 1.0)
```

The timer runs via `requestAnimationFrame` or a `setInterval` at 60 fps during the lock period. Once `lockProgress()` reaches 1.0, the "Play Again" button is enabled and the progress indicator is removed.

### 4.4 Duration Formatting

```
formatDuration(sec):
    minutes = floor(sec / 60)
    seconds = sec % 60
    return minutes + ":" + padStart(seconds, 2, "0")
    // e.g., 167 → "2:47", 45 → "0:45"
```

---

## 5. Edge Cases

### 5.1 Rewards Arrive After REWARD_TIMEOUT_MS (Async Delivery)

**Scenario:** The rewards panel data (`xpEarned`, `diamondsEarned`) is not included in the initial payload or arrives via a separate async call that resolves after screen mount.

**Behavior:**
1. On mount, rewards panel shows `—` (em-dash) placeholders for XP and diamond values
2. XP bar shows in an indeterminate or zero-fill state
3. When async data arrives (or when the main payload resolves if delayed), update the rewards panel in-place:
   - Fade in the new numeric values over ~300 ms
   - Trigger the XP bar fill animation at that point
4. If `REWARD_TIMEOUT_MS` elapses without data, continue showing `—` permanently for this session; do not show an error state (rewards are server-persisted regardless)
5. The outcome banner, stats panel, MMR panel, and action buttons are **not affected** and must not re-animate

**`REWARD_TIMEOUT_MS`:** 8000 ms (configurable — see §7 Tuning Knobs). Defined as the maximum time the client waits for an async rewards update before treating the placeholder as final for this session.

---

### 5.2 Player Taps "Play Again" Immediately

**Scenario:** Player taps "Play Again" button within the first 3000 ms.

**Behavior:**
- The button does not respond to the tap (disabled state with no visual feedback beyond the locked appearance)
- The progress indicator continues its fill animation
- No error message or toast is shown
- After `RESULTS_MIN_DISPLAY_MS`, the button enables normally

This is a silent lock, not an error state. The progress indicator on the button communicates the wait implicitly.

---

### 5.3 App Backgrounded on Results Screen

**Scenario:** Player presses the home button or switches apps while the results screen is displayed.

**Behavior:**
- All rewards are already server-side — no client action is required to persist them
- The results screen state is preserved in memory
- On foreground return, the results screen is shown exactly as it was left; no re-fetch, no re-animation of completed animations
- If the `RESULTS_MIN_DISPLAY_MS` timer had not yet elapsed when the app was backgrounded, behavior on return:
  - Option A (recommended): Resume the timer from where it was. If 1500 ms had elapsed before backgrounding, only 1500 ms remain on foreground.
  - The progress indicator updates to reflect remaining time.
- If Match Flow has invalidated the session while backgrounded (e.g., server timeout), "Play Again" should display a connection error state on enable

---

### 5.4 Rank Tier Changes in Both Directions Simultaneously

**Scenario:** A single match theoretically promotes and demotes the player at the same time.

**Reality:** This is impossible in the BRAWLZONE MMR/Ranked System — a single match produces one `mmrDelta` resulting in exactly one `newRankTier`.

**Defensive handling:**
- The screen uses `payload.newRankTier` as the sole source of truth for the post-match tier
- The pre-match tier is read from local player state (the last known tier before this match)
- If `payload.newRankTier !== preMmrTier`: play the tier change animation regardless of direction
- If `payload.newRankTier === preMmrTier`: no animation
- No special case for "both directions" is needed; the payload is authoritative

---

### 5.5 Draw Outcome

**Scenario:** `payload.outcome === "draw"`.

**Behavior:**
- Outcome banner: `DRAW` text, blue palette (`#4FC3F7`), ease-in-out entrance animation (no bounce)
- Placement: show placement string if applicable (FFA) or omit for 1v1 (a draw in 1v1 implies equal placement)
- MMR delta: `mmrDelta` may be 0 or a small non-zero value (system-defined); display using standard delta rules (§4.1)
- Rank tier: use standard tier change logic based on `newRankTier`
- Rewards panel: display normally — draws still earn XP and potentially Diamonds
- Action buttons: standard behavior, same 3-second lock on "Play Again"
- No "WIN" styling or "DEFEAT" styling is applied

---

### 5.6 Missing or Malformed Payload Fields

**Scenario:** A field in `match_results_payload` is null, undefined, or out of expected range.

**Behavior:**
- `outcome` null/invalid → default to `DRAW` display; log error
- `kills` / `assists` / `score` null → display `0`
- `mmrDelta` null → display `0 MMR` in neutral grey; do not show delta badge
- `newMmr` null → omit the MMR panel (do not show incomplete data)
- `xpEarned` / `diamondsEarned` null → show `—` placeholder (same as async pending state)
- `matchDurationSec` null → omit duration field
- `newRankTier` null → show current tier from local state; no tier animation

Field validation occurs at payload ingestion (on screen mount), before any rendering begins.

---

## 6. Dependencies

### 6.1 Upstream Dependencies

| Dependency | What it provides | Contract |
|---|---|---|
| **Match Flow System** | `match_results_payload` (full object per §3.1) | Match Flow navigates to this screen and passes the payload. Screen is a consumer only — it does not call Match Flow APIs. |
| **MMR / Ranked System** | `mmrDelta`, `newMmr`, `newRankTier` (within payload) | Rank tier badge assets (icons/images) must be supplied by the MMR/Ranked System asset pipeline. Badge asset names must map to `newRankTier` string values (e.g., `"Gold"` → `gold_tier_badge.png`). |
| **Player Profile / Progression** | Pre-match XP value and level data for XP bar calculation | Required for §4.2. The results screen reads (does not write) local player profile state. Must be available synchronously on screen mount. |
| **Player Profile / Ranked** | Pre-match rank tier (for tier change detection) | The local rank tier stored before the match starts. Used to compare against `payload.newRankTier` to determine if tier animation plays. |

### 6.2 Downstream Dependencies

| Dependency | What this screen provides | Contract |
|---|---|---|
| **Match Flow (re-queue)** | "Play Again" button tap event + `payload.gameMode` | On "Play Again" tap, this screen calls Match Flow's re-queue entry point with the game mode. Transition is handled by Match Flow. |
| **Main Menu Navigation** | "Main Menu" button tap event | On "Main Menu" tap, this screen triggers the standard navigation stack pop/reset to the main menu. No data is passed. |

### 6.3 Asset Dependencies

- Rank tier badge icons for all tiers defined in the MMR/Ranked System (Bronze, Silver, Gold, Platinum, Diamond, etc.)
- Particle/sparkle effect assets for the tier change animation (or a code-driven particle system)
- XP bar component (can be a shared UI component from the design system)
- Diamond icon (`💎` or a bespoke asset)
- Play Pass bonus tag visual treatment

---

## 7. Tuning Knobs

All values below are defined as named constants in the implementation (e.g., in a `matchResultsConfig.ts` or equivalent configuration file). They must not be hardcoded inline.

| Constant | Default Value | Description |
|---|---|---|
| `RESULTS_MIN_DISPLAY_MS` | `3000` | Minimum time the screen must be shown before "Play Again" is enabled. Also the duration of the "Play Again" progress indicator. |
| `OUTCOME_BANNER_ANIM_MS` | `800` | Duration of the outcome banner entrance animation (scale-up + fade-in). |
| `RANK_TIER_ANIM_MS` | `2000` | Maximum duration of the rank tier badge transition animation. |
| `XP_BAR_FILL_MS` | `1200` | Duration of the XP bar fill animation (from pre-match to post-match position). |
| `REWARD_TIMEOUT_MS` | `8000` | Maximum time to wait for async rewards data before treating `—` placeholders as final. |
| `PLAY_AGAIN_REENABLE_DELAY_MS` | `RESULTS_MIN_DISPLAY_MS` | Alias — the re-enable delay for "Play Again" is driven by `RESULTS_MIN_DISPLAY_MS`. Kept separate for future decoupling. |
| `SHARE_ENABLED` | `false` | Feature flag: controls whether "Share Result" button is interactive. `false` at MVP. |

---

## 8. Acceptance Criteria

All criteria are testable (automated or manual QA).

### AC-01: Correct Outcome Display
- **Given** `payload.outcome === "win"`, the screen displays `VICTORY` in gold/green with WIN styling
- **Given** `payload.outcome === "loss"`, the screen displays `DEFEAT` in grey/dark with DEFEAT styling
- **Given** `payload.outcome === "draw"`, the screen displays `DRAW` in blue with neutral styling
- **None** of the outcome texts or color themes cross-apply to the wrong outcome

### AC-02: MMR Delta Color and Format
- **Given** `payload.mmrDelta === 18`, the delta badge displays `+18 MMR` in green (#4CAF50)
- **Given** `payload.mmrDelta === -12`, the delta badge displays `-12 MMR` in red (#F44336)
- **Given** `payload.mmrDelta === 0`, the delta badge displays `0 MMR` in neutral grey (#9E9E9E)
- `prevMmr` is correctly calculated as `newMmr - mmrDelta` in all three cases

### AC-03: Rank Tier Animation Trigger
- **Given** pre-match tier is `"Silver"` and `payload.newRankTier === "Gold"`, the tier badge transition animation plays automatically
- **Given** pre-match tier is `"Gold"` and `payload.newRankTier === "Silver"`, the tier badge transition animation plays automatically (demotion)
- **Given** pre-match tier is `"Gold"` and `payload.newRankTier === "Gold"`, no animation plays — the badge is displayed statically
- The animation completes within `RANK_TIER_ANIM_MS` (2000 ms)
- Action buttons do not appear until after the tier animation completes (or after `RESULTS_MIN_DISPLAY_MS`, whichever is later)

### AC-04: Rewards Display (MVP Stub)
- **Given** `payload.xpEarned === 250`, the rewards panel displays `+250 XP`
- **Given** `payload.diamondsEarned === 15`, the rewards panel displays `+15 💎`
- **Given** `payload.bonusFlags.playPassActive === true`, a `+25% bonus` tag is displayed adjacent to the diamond amount
- **Given** `payload.bonusFlags.playPassActive === false`, no bonus tag is displayed
- The XP bar animates from the pre-match position to the post-match position
- No chest animation, spinning wheel, or "coming soon" text is shown

### AC-05: "Play Again" Lock Timer
- **Given** the screen has been mounted for fewer than 3000 ms, tapping "Play Again" does nothing
- **Given** the screen has been mounted for exactly 3000 ms (± 100 ms tolerance), "Play Again" becomes tappable
- A progress indicator on the "Play Again" button fills continuously from 0% to 100% over 3000 ms from screen mount
- "Main Menu" is tappable immediately (no lock) from the moment the screen appears

### AC-06: Async Reward Update (Rewards Arrive Late)
- **Given** rewards data is not present at screen mount, the rewards panel shows `—` placeholders
- **Given** rewards data arrives 2000 ms after screen mount, the rewards panel updates in-place with a ~300 ms fade-in on the values
- The outcome banner, stats panel, MMR panel, and action button lock timer are **not affected** by the late rewards arrival — they do not re-animate

### AC-07: Draw Outcome Specifics
- **Given** `payload.outcome === "draw"`, the outcome banner shows `DRAW` with blue styling
- **Given** `payload.mmrDelta === 0` on a draw, the MMR panel shows `0 MMR` in neutral grey
- The rewards panel still shows XP and diamond values on a draw
- The "Play Again" lock timer still applies on a draw

### AC-08: App Background Safety
- **Given** the player backgrounds the app at T=1500 ms (during the 3-second lock), foregrounds at T+2000 ms (app time): the "Play Again" button requires approximately 1500 ms more before enabling (timer resumes from where it was)
- **Given** the player backgrounds and foregrounds the app at any point, no reward re-fetch or re-animation occurs
- **Given** the outcome banner animation was completed before backgrounding, it does not replay on foreground

### AC-09: 3v3 Team Scoreboard
- **Given** `payload.gameMode === "squad_3v3"`, the match stats panel includes a full 6-player scoreboard (3 friendly + 3 enemy)
- Friendly rows have a distinct visual treatment from enemy rows
- The local player's row has a further distinct visual treatment (bold or highlight border)

### AC-10: Safe Area Compliance
- On devices with a notch or dynamic island, the outcome banner is not obscured by the status bar
- On devices with a home indicator, the action buttons are not obscured by the gesture bar
- All interactive elements have a minimum touch target of 44×44 pt

### AC-11: Share Result Button
- The "Share Result" button is visible on the screen at MVP
- The "Share Result" button does not trigger any action when tapped
- A tooltip or brief text appears on tap: "Coming in a future update"

---

*End of Match Results Screen GDD*
