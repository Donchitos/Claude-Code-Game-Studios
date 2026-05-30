# Tutorial / Onboarding — Game Design Document
> **System**: Tutorial / Onboarding
> **Priority**: VS
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

### Purpose

The Tutorial / Onboarding system is BRAWLZONE's first-session gate. It transforms a confused new player into a confident one within a single uninterrupted session of approximately 5–8 minutes. Because mobile PvP retention is binary at the first session — the player either comes back or never does — the tutorial is treated as a Priority VS (vital system) and gates access to the full main menu flow.

### What the Tutorial Teaches

The tutorial covers the minimum viable skill set required to play a real match without frustration:

1. Moving with the virtual joystick
2. Landing a basic attack on a target
3. Understanding the two ability slots
4. Selecting a loadout (the Deck/Loadout System — the game's strategic differentiator)
5. Recognizing and triggering a passive ability
6. Winning a 1v1 match against a scripted bot
7. (Optional) Understanding the three game modes
8. (Optional) Awareness of cosmetic customization options

### Skip Option

After completing Step 2 (Basic Attack), a **Skip Tutorial** button becomes visible. A player who taps it is offered a brief confirmation dialog: "Skip the rest? You'll still get your starter rewards." Confirming jumps directly to the Mode Introduction step (Step 7) or to the main menu if the player declines the mode intro. Skipping is not penalized — it grants identical rewards to full completion.

### Tutorial Match

Step 6 is a controlled offline-style 1v1 match against a scripted bot. It does not use matchmaking, does not update MMR, and issues no real match rewards. The bot is deliberately scripted to pause at key moments so that the player wins if they engage meaningfully. The match is designed to last approximately 90 seconds.

### Completion Rewards

Upon winning the tutorial match (Step 6) — or upon skipping the tutorial — the player receives:

- **200 XP**
- **10 Diamonds**
- **"Rookie" cosmetic badge** (unlocked once; not available again)

These rewards are granted server-side as an idempotent operation tied to the player's account, ensuring they are issued exactly once regardless of connection interruptions.

### Re-Entry Path

Players who skipped or who wish to replay the tutorial can do so via **Settings → Gameplay → Replay Tutorial**. Re-entry replays Steps 1–6 only. The Mode Introduction and Shop Teaser steps are omitted on replay. No additional rewards are granted on replay.

---

## 2. Player Fantasy

### The Journey: From Confusion to Confidence

BRAWLZONE's new player arrives with expectations shaped by every mobile brawler they have played before. They expect chaos — small text, unclear icons, and a match thrown at them before they understand anything. The tutorial is designed to subvert that expectation entirely.

**The opening moment is calm.** A single character (Vex) stands in an open arena with soft lighting. A single prompt appears: "Move here." Nothing else is on screen. The player discovers that they already know what to do.

**Each step builds forward, never backward.** The player is never shown a mechanic and then forced to forget it. Movement flows into attacking. Attacking flows into abilities. Abilities flow into deck selection. Every step is a consequence of the last, not an interruption of it.

**The "aha moment" — when the loadout clicks.** This is the tutorial's most important beat. When the player reaches Step 4 (Deck Selection), they are not handed a wall of stats. They are shown three archetypes in plain language:

- *Aggressor* — hits harder, dies faster
- *Defender* — hits softer, survives longer
- *Balanced* — somewhere in between

They pick one. Immediately, their ability slots visually update. They feel the difference before they are told the difference. That feeling — "I made my character mine" — is the strategic hook of BRAWLZONE landing for the first time. Players who reach this moment with a positive emotional valence are far more likely to return to the loadout editor after the tutorial and experiment further.

**The scripted win is earned, not handed over.** The tutorial bot is scripted to lose, but it does not stand still. It moves, attacks, and uses one ability. The player must actually engage to win. When the victory screen appears after approximately 90 seconds, the player feels capable, not patronized. The win condition requires the player to use what they just learned.

**The world opens.** After the match, the Mode Introduction cards reveal that this was just one format. There are two more modes. The player's reaction is curiosity, not overwhelm, because they have just proven to themselves that they can handle the game.

The player who completes this tutorial does not feel like a beginner who passed a test. They feel like a fighter who just won their first fight.

---

## 3. Detailed Rules

### 3.1 Tutorial Trigger

The tutorial flow is triggered **automatically on first login**, immediately after the player completes profile creation (username + avatar selection). The transition from profile creation to the tutorial is seamless — no main menu is shown in between.

**Remote Config bypass:** If the Remote Config key `onboarding.tutorialEnabled` evaluates to `false` at the point the tutorial would launch, the system skips the entire tutorial flow and navigates the player directly to the main menu. When bypassed this way, Vex's default loadout (Balanced archetype) is pre-configured on the player's account. The bypass is intended for QA environments and emergency use only; it must not be pushed to production without a corresponding incident or test-flag justification.

**Resume on crash:** If `tutorialCompleted` is `false` and `tutorialStepsCompleted` is non-empty in the Player Profile, the tutorial resumes from the last entry in `tutorialStepsCompleted` on next app launch. The player is shown a brief "Welcome back — pick up where you left off?" prompt before resuming.

---

### 3.2 Tutorial Steps

The tutorial consists of 8 steps. Steps 1–6 are core and required for reward grant. Steps 7–8 are optional and skippable independently.

---

#### Step 1 — Movement

**Objective:** Player moves their character to a highlighted zone using the virtual joystick.

**Screen state:** Empty arena. No enemies. One circular highlighted zone in the distance. A translucent joystick graphic pulses on the left side of the screen. All other UI elements are hidden.

**Instruction overlay:** "Move to the glowing area."

**Completion condition:** Player's character enters the highlighted zone.

**Fallback:** If the player does not move within 8 seconds, the joystick graphic animates more aggressively (bouncing arrow). If no movement after 15 seconds, a coach character (Vex's trainer silhouette) appears in corner and says: "Try dragging your thumb here."

**Analytics:** `ONBOARDING_STEP_COMPLETED { step: 1, timeToComplete: <seconds> }`

**Skip button visible:** No

---

#### Step 2 — Basic Attack

**Objective:** Player taps the basic attack button to hit a stationary training dummy 3 times.

**Screen state:** Training dummy spawns at center. Attack button pulses on right side of screen. Health bar visible above dummy.

**Instruction overlay:** "Tap the attack button to hit the dummy."

**Completion condition:** Training dummy health reaches 0 (3 hits required at tutorial damage values).

**Fallback:** If no attack within 6 seconds, the attack button pulses with an expanding ring. A label "Tap here" appears next to the button.

**Skip button visible:** Yes — appears after the first successful hit lands. Positioned top-right with low visual priority (ghost button style) so it does not distract from the primary action.

**Analytics:** `ONBOARDING_STEP_COMPLETED { step: 2, timeToComplete: <seconds> }`

---

#### Step 3 — Ability Introduction

**Objective:** Player learns what the two ability slots are and what they do conceptually.

**Screen state:** Pause-style overlay appears. Two ability slots are highlighted with animated rings. A short callout box for each slot explains its role.

**Slot 1 label:** "Active Ability — your main skill. Tap to use it in a fight."

**Slot 2 label:** "Support Ability — defensive or utility. Use it strategically."

**Instruction overlay:** "You have two ability slots. They make every fighter unique."

**Completion condition:** Player taps "Got it" on the overlay.

**No skip option on this step** — it is a non-interactive callout that completes in approximately 5 seconds of reading time. An auto-advance timer (10 seconds) completes the step if the player does not tap.

**Analytics:** `ONBOARDING_STEP_COMPLETED { step: 3, timeToComplete: <seconds> }`

---

#### Step 4 — Deck Selection

**Objective:** Player selects their first loadout by choosing an archetype, experiencing the strategic core of the game.

**Screen state:** The Deck Selection screen opens in a guided mode. Only three pre-built loadout options are shown (one per archetype). The full deck editor is locked behind a "More Options" button that is visually deprioritized. Each option card shows:

- Archetype name (Aggressor / Defender / Balanced)
- A one-line description in plain language
- A visual preview of the two abilities that come with it (icon + name only, no stat numbers)
- A colored border (red / blue / yellow) for quick visual differentiation

**Instruction overlay:** "Pick your fighting style. You can change this later."

**Completion condition:** Player taps "Select" on one of the three options and confirms.

**Edge case — player does not choose:** If no selection is made within 30 seconds, the Balanced archetype is auto-selected with a brief "We picked Balanced for you — you can change this anytime" toast. This ensures the tutorial match in Step 6 always has a valid loadout.

**Post-selection beat:** After confirming, the ability slots in the HUD visually populate with the chosen abilities. A brief flash animation plays on each slot. This is the "aha moment" described in the Player Fantasy section — the player sees their choice reflected immediately.

**Analytics:** `ONBOARDING_STEP_COMPLETED { step: 4, timeToComplete: <seconds>, archetypeSelected: <string> }`

---

#### Step 5 — Passive Ability

**Objective:** Player learns about their character's passive ability by observing it trigger in a controlled scenario.

**Screen state:** A second training dummy spawns. The player's passive ability icon (bottom-left HUD area) is highlighted. An instruction overlay explains what the passive does for the selected character (Vex's default passive: "Every 3rd hit deals bonus damage — watch for the glow").

**Instruction overlay:** "Your passive ability activates automatically. Watch the glow on hit 3."

**Completion condition:** Player lands 3 hits on the training dummy and the passive triggers (visual effect fires). The step auto-completes 1.5 seconds after passive trigger.

**Character variance note:** All three starter characters (Vex, Zook, Sera) have passives that can be demonstrated via basic attacks on a dummy within 3–5 hits. If Vex is not the selected tutorial character (future-proofing), this step's instruction text is pulled from Content Catalog keyed on `tutorialPassiveDescription_<characterId>`.

**Analytics:** `ONBOARDING_STEP_COMPLETED { step: 5, timeToComplete: <seconds> }`

---

#### Step 6 — Tutorial Match

**Objective:** Player wins a 1v1 match against a scripted bot to prove they have internalized the core combat loop.

**Match configuration:**

| Parameter | Value |
|---|---|
| Match type | Tutorial (not FFA, not Duel, not Squad) |
| Player character | Player's selected character (default: Vex) |
| Bot character | Zook (or Vex if Zook asset unavailable) |
| Bot AI profile | Easy + scripted pause script (see below) |
| Arena | Tutorial Arena (flat, no obstacles, no hazards) |
| Match duration cap | 120 seconds (bot concedes if match reaches cap) |
| MMR effect | None |
| Real rewards | None (tutorial rewards issued separately) |
| Matchmaking | Bypassed entirely |

**Scripted bot behavior:**

The bot executes the Easy AI profile (reduced reaction time, predictable movement patterns) overlaid with a scripted pause schedule:

- At match start, bot moves toward player slowly for 3 seconds before attacking.
- After taking 30% health damage, bot pauses for 2 seconds (simulating "retreating to think").
- At 50% health, bot uses its one scripted ability (a non-damaging dash away from player).
- At 70% health, bot pauses for 1 second before each attack (giving the player time to react and counter).
- Bot never uses defensive abilities. Bot never heals.
- If the player's health drops below 20%, the bot's attack frequency is halved for 10 seconds (giving the player a recovery window).

**Player win guarantee:** The scripted bot's total DPS output is tuned so that even a player who lands only 50% of their attacks will win the match within 90 seconds. A player who engages normally will win in approximately 60–75 seconds.

**Failure state:** There is no "lose" state in the tutorial match. If the player's health reaches 0, they are immediately revived with 50% health and a brief overlay: "You're back in it — keep going!" The bot does not regenerate health when the player is revived. A player can be revived a maximum of 2 times before the match's scripted difficulty drops to its minimum floor.

**Victory screen:** On win, the standard victory screen is replaced by a tutorial-specific victory screen showing:
- "First Win!" headline
- Reward summary (200 XP, 10 Diamonds, Rookie Badge)
- A brief "You're ready to brawl" tagline
- Two CTA buttons: "Continue" (proceeds to Step 7) and "Go to Menu" (skips Steps 7–8)

**Analytics:** `ONBOARDING_STEP_COMPLETED { step: 6, timeToComplete: <seconds>, reviveCount: <int> }` and on full tutorial path: `ONBOARDING_COMPLETED { completionType: "full" | "skip", totalTimeSeconds: <int> }`

---

#### Step 7 — Mode Introduction (Optional)

**Objective:** Introduce the three game modes so the player understands what content is available beyond their first match.

**Screen state:** Three illustrated cards, one per mode, displayed in a swipeable horizontal carousel:

- **1v1 Duel** — "Pure 1v1. Your skills vs. theirs. No excuses."
- **3v3 Squad Brawl** — "Team up with two friends or be matched with allies. Coordination wins."
- **8-Player FFA** — "Chaos. Pure chaos. Last fighter standing."

Each card includes a simple illustration, mode name, short description (max 20 words), and a "player count" indicator.

**Instruction overlay:** "Three ways to brawl. Pick your battle."

**Completion condition:** Player swipes through all three cards and taps "Let's Go" — or taps the skip ("×") button in the top-right corner at any point.

**Analytics:** `ONBOARDING_STEP_COMPLETED { step: 7, timeToComplete: <seconds>, skipped: <bool> }`

---

#### Step 8 — Play Pass / Shop Teaser (Optional)

**Objective:** Create awareness of cosmetic customization without creating purchase pressure.

**Screen state:** A single illustrated card showing a customized version of Vex (alternate skin, badge equipped). Two bullet points:

- "Unlock new looks for your fighters"
- "Earn rewards just by playing"

**Tone mandate:** This step must not feel like an advertisement. No price points are shown. No limited-time language. No urgency. The CTA is "Check It Out Later" (not "Buy Now"). The goal is planting curiosity, not converting.

**Completion condition:** Player taps "Check It Out Later" or dismisses the card. Auto-advances after 12 seconds if no interaction.

**Analytics:** `ONBOARDING_STEP_COMPLETED { step: 8, timeToComplete: <seconds>, skipped: <bool> }`

---

### 3.3 Skip Flow

The skip mechanism is available from Step 2 onward. Its behavior is as follows:

1. **Skip button appearance:** Visible from Step 2 onward as a ghost-style button in the top-right corner of the screen. Label: "Skip Tutorial."
2. **Skip confirmation dialog:** Tapping the button triggers a modal: "Skip the rest? You'll still get your starter rewards." Two options: "Skip" and "Keep Going."
3. **Skip destination:** Confirming skip jumps to Step 7 (Mode Introduction). If the player also dismisses or skips Step 7, they proceed to Step 8 or directly to the main menu.
4. **Reward grant on skip:** Identical to full completion: 200 XP, 10 Diamonds, Rookie Badge. The `ONBOARDING_COMPLETED` event fires with `completionType: "skip"`.
5. **Loadout handling on skip:** If the player skipped before reaching Step 4 (Deck Selection), Vex's default Balanced loadout is auto-assigned. A toast message informs the player: "We set up a starter loadout for you — customize it anytime in your Profile."
6. **tutorialCompleted flag:** Set to `true` on skip, identical to full completion. The player will not be re-prompted on next session.

---

### 3.4 Tutorial State Persistence

Tutorial state is stored in two locations for redundancy and offline resilience:

| Field | Storage | Type | Notes |
|---|---|---|---|
| `tutorialCompleted` | Player Profile (server) | `boolean` | Source of truth |
| `tutorialStepsCompleted` | Player Profile (server) | `number[]` | Array of step indices completed |
| `tutorialCompleted` | AsyncStorage (local) | `boolean` | Offline fallback; synced on next session |
| `tutorialStepsCompleted` | AsyncStorage (local) | `number[]` | Offline fallback |
| `contextualHintsSeen` | AsyncStorage (local) | `string[]` | Array of hint IDs shown; never server-synced |

**Sync priority:** On session start, server state is the source of truth. Local AsyncStorage is used only when the server is unreachable. On reconnect, server state overwrites local state (server wins in conflict).

---

### 3.5 Contextual Hints (Post-Tutorial)

After the tutorial completes, the player encounters contextual one-time hints during their first interactions with key screens. These are dismissible tooltips — not pop-ups that block interaction.

**Hint trigger rules:**
- Each hint is shown at most once (tracked by hint ID in `contextualHintsSeen` in AsyncStorage).
- Hints are shown on top of the relevant UI element, pointing to it with a small arrow.
- Each hint has a display duration of 6 seconds before auto-dismissing. Player can dismiss earlier by tapping the hint or tapping elsewhere.
- A maximum of 3 hints may appear in a single session (to avoid hint fatigue).

**Hint catalog (initial set):**

| Hint ID | Trigger | Text |
|---|---|---|
| `hint_loadout_editor` | First time opening Loadout Editor | "Try swapping your Slot 2 ability for a Defensive option!" |
| `hint_deck_archetype` | First time viewing archetype comparison | "Each archetype changes how your abilities interact — experiment!" |
| `hint_match_result` | First real match result screen | "Check your match stats to see what's working." |
| `hint_squad_invite` | First time opening Squad Brawl lobby | "Invite friends to Squad Brawl for bonus XP." |
| `hint_passive_indicator` | First real match, passive triggers | "That's your passive — build combos around it!" |

---

## 4. Formulas

### 4.1 Skip Reward Equality

The skip path must always produce identical rewards to the full completion path. No design change or A/B test may break this invariant without explicit producer sign-off.

```
rewardOnSkip == rewardOnCompletion
```

Specifically:

```
reward_xp_skip         = 200   == reward_xp_complete
reward_diamonds_skip   = 10    == reward_diamonds_complete
reward_badge_skip      = "Rookie" == reward_badge_complete
```

This equality is enforced in the reward grant service by issuing both paths through the same grant function (`grantTutorialReward(playerId)`), which does not accept a `completionType` parameter — it issues the same reward regardless of skip or full-completion path.

### 4.2 Tutorial Completion Rate Target

```
target_completion_rate = 0.60   // 60% of new players complete Step 6 within first session
```

This is an advisory metric, not a hard gate. It is monitored via the `ONBOARDING_COMPLETED` event. If the rate drops below 0.60 over a 7-day rolling average, the onboarding team is notified to investigate drop-off by step using `ONBOARDING_STEP_SKIPPED` event data.

The step-level funnel target (advisory):

| Step | Target Reach Rate (of players who started tutorial) |
|---|---|
| Step 1 (Movement) | 100% |
| Step 2 (Basic Attack) | 98% |
| Step 3 (Ability Introduction) | 92% |
| Step 4 (Deck Selection) | 85% |
| Step 5 (Passive Ability) | 80% |
| Step 6 (Tutorial Match) | 70% |
| Step 7 (Mode Intro) | 55% (optional) |
| Step 8 (Shop Teaser) | 45% (optional) |

### 4.3 Step Completion Time Targets

These are advisory targets used to detect friction. Steps that consistently exceed target time are flagged for UX review.

| Step | Target Completion Time | Alert Threshold |
|---|---|---|
| Step 1 — Movement | ≤ 15 seconds | > 30 seconds |
| Step 2 — Basic Attack | ≤ 20 seconds | > 45 seconds |
| Step 3 — Ability Intro | ≤ 10 seconds | > 20 seconds |
| Step 4 — Deck Selection | ≤ 25 seconds | > 60 seconds |
| Step 5 — Passive Ability | ≤ 20 seconds | > 45 seconds |
| Step 6 — Tutorial Match | ≤ 120 seconds | > 150 seconds |
| Step 7 — Mode Intro | ≤ 20 seconds | > 40 seconds |
| Step 8 — Shop Teaser | ≤ 15 seconds | > 30 seconds |

### 4.4 Bot Difficulty Floor for Revive Recovery

```
revive_count >= 2  →  bot_attack_frequency_multiplier = 0.3  (30% of base Easy AI attack rate)
revive_count == 1  →  bot_attack_frequency_multiplier = 0.5
revive_count == 0  →  bot_attack_frequency_multiplier = 1.0  (standard Easy AI)
```

Player health at revive: `50% of max_health`
Maximum revives in tutorial match: `2`

---

## 5. Edge Cases

### EC-01: App Crash Mid-Tutorial

**Scenario:** The player's app crashes or is backgrounded and killed between completing Step N and completing Step N+1.

**Behavior:**
1. On next app launch, the session start routine checks `tutorialCompleted` (server, fallback to AsyncStorage).
2. If `tutorialCompleted == false`, the tutorial resumes.
3. Resume prompt: "Welcome back! Want to pick up where you left off?" with options "Resume" and "Start Over."
4. Resuming loads from `max(tutorialStepsCompleted)`.
5. Starting over resets `tutorialStepsCompleted` to `[]` and begins at Step 1.
6. The tutorial match (Step 6) always restarts from the beginning if interrupted — partial match state is not persisted.

---

### EC-02: Player Skips Before Deck Selection (Step 4)

**Scenario:** Player activates skip during Steps 2 or 3, before ever reaching the Deck Selection step.

**Behavior:**
1. Skip confirmation dialog appears as normal.
2. On confirm, Vex's Balanced default loadout is auto-assigned to the player's account.
3. Toast message: "We set up a starter loadout for you — customize it anytime in your Profile."
4. `tutorialStepsCompleted` records the steps completed before skip.
5. Rewards are granted as normal.
6. The loadout editor contextual hint (`hint_loadout_editor`) is prioritized to appear at the first opportunity after the player reaches the main menu.

---

### EC-03: `tutorialEnabled = false` Pushed Mid-Tutorial

**Scenario:** A QA or emergency Remote Config push sets `onboarding.tutorialEnabled = false` while the player is actively in the tutorial flow.

**Behavior:**
1. The system does not interrupt the player mid-step.
2. At the next step boundary (i.e., after the current step completes), the system checks the Remote Config value.
3. If `tutorialEnabled` is now `false`, the tutorial exits gracefully to the main menu after displaying a brief transition animation.
4. Any steps already completed are preserved in `tutorialStepsCompleted`.
5. If the player had already completed Step 6, full rewards are granted before exiting.
6. If the player had not completed Step 6, no rewards are granted (rewards require the match win; the mid-tutorial Remote Config push is an exceptional operational event and should not trigger reward grants for partial completion).
7. On next session, if `tutorialEnabled` is still `false`, the player bypasses the tutorial entirely.

---

### EC-04: Player Completes Tutorial but Reward Grant Fails

**Scenario:** The server-side reward grant call for 200 XP, 10 Diamonds, and Rookie Badge fails due to a network error or server fault.

**Behavior:**
1. The failure is caught client-side. The tutorial victory screen still shows the reward summary (optimistic UI).
2. A local pending-reward flag is written to AsyncStorage: `{ pendingTutorialReward: true }`.
3. On next successful session start, the client reads `pendingTutorialReward` and retries the grant call.
4. The server-side grant function is idempotent: it checks whether the player has already received tutorial rewards before issuing them. Duplicate calls are safe.
5. The Rookie Badge is also issued idempotently — if the badge already exists on the player's account, the grant is a no-op.
6. If the retry also fails, the flag persists and retries again on the next session. There is no expiry on this retry — the player will eventually receive their rewards.

---

### EC-05: Player Completes Tutorial Then Requests Replay

**Scenario:** A player who completed the tutorial (full or skip) navigates to Settings → Gameplay → Replay Tutorial.

**Behavior:**
1. The replay flow runs Steps 1–6 only. Steps 7 and 8 are omitted (player has already seen or skipped them).
2. `tutorialCompleted` remains `true` on the server. It is not reset.
3. `tutorialStepsCompleted` is not modified by replay.
4. No rewards are granted on replay. The victory screen on replay shows: "Great run! (Rewards already claimed.)"
5. The contextual hint system is not reset by replay — hints already dismissed remain dismissed.
6. Deck selection in the replay (Step 4) allows the player to switch their archetype. Any archetype change made during replay is persisted to their actual loadout.

---

### EC-06: `tutorialEnabled = false` on First Login

**Scenario:** A new player's first login occurs when `onboarding.tutorialEnabled = false`.

**Behavior:**
1. Tutorial flow is never entered. Player proceeds directly to the main menu.
2. Vex's Balanced default loadout is pre-configured on the account.
3. `tutorialCompleted` is set to `true` on the server (to prevent the tutorial from triggering if `tutorialEnabled` is later flipped back to `true`).
4. No rewards are granted (the tutorial bypass is a QA/operational tool, not a player-facing feature; reward grants require tutorial interaction).

---

### EC-07: Player Force-Quits During Tutorial Match

**Scenario:** Player closes the app during the tutorial match (Step 6) without completing it.

**Behavior:**
1. The match instance is abandoned server-side (no MMR or reward impact — tutorial match has none).
2. On next app launch, the tutorial resumes from Step 6 (tutorial match restart). `tutorialStepsCompleted` does not include 6.
3. The tutorial match restarts from the beginning; no partial match state is preserved.
4. Resume prompt: "Welcome back! Ready to finish your first match?"

---

## 6. Dependencies

### 6.1 Upstream Dependencies

| System | Dependency | Notes |
|---|---|---|
| **Main Menu** | Tutorial launches from the first-login flow, which is owned by Main Menu. Main Menu must not render until tutorial returns control. | Tutorial blocks main menu entry on first session. |
| **Character System** | Tutorial uses Vex (default starter character) and the bot character (Zook). Character assets, animations, ability data, and passive data must be available at tutorial launch. | Tutorial must gracefully handle missing character data with a fallback to Vex vs. Vex. |
| **Match Flow** | Tutorial match (Step 6) uses a simplified Match Server instance. The Match Flow system provides the match lifecycle (start, tick, end) and the HUD. Tutorial match bypasses matchmaking and MMR update hooks. | Tutorial match must be explicitly flagged as `matchType: "tutorial"` in all match lifecycle calls. |
| **Content Catalog** | Tutorial content (step instructions, archetype descriptions, mode intro copy, hint text) is served as static data from the Content Catalog. | Allows localization and copy updates without app builds. |
| **Remote Config** | `onboarding.tutorialEnabled` boolean controls whether the tutorial runs on first login. Checked at session start. | Must be checked before the tutorial flow begins. Default value: `true`. |

### 6.2 Downstream Dependencies

| System | Dependency | Notes |
|---|---|---|
| **Analytics** | Tutorial emits `ONBOARDING_STARTED`, `ONBOARDING_STEP_COMPLETED`, `ONBOARDING_STEP_SKIPPED`, and `ONBOARDING_COMPLETED` events. These are used to monitor funnel health and inform balance decisions. | Events must fire reliably. Failed event emissions should be retried or queued. |
| **Quest / Mission** | Completing the tutorial (Step 6 win or skip) triggers the Starter Quest chain. The Quest system listens for `tutorialCompleted == true` on the Player Profile or subscribes to `ONBOARDING_COMPLETED` event. | Tutorial completion must set `tutorialCompleted = true` before the Quest system evaluates starter quest unlock conditions. |
| **Player Profile** | Tutorial writes `tutorialCompleted` and `tutorialStepsCompleted` to the Player Profile. These fields are read at session start to determine tutorial state. | Player Profile API must expose a tutorial state update endpoint. The endpoint must be idempotent. |

---

## 7. Tuning Knobs

The following parameters are tunable without code changes. Items marked [Remote Config] can be adjusted live via Remote Config. Items marked [Content Catalog] can be adjusted via Content Catalog updates. Items marked [Design Data] require a Content Catalog or data layer update.

| Parameter | Current Value | Range | Location | Notes |
|---|---|---|---|---|
| `tutorialEnabled` | `true` | `true` / `false` | [Remote Config] | Emergency disable for QA/ops. |
| Bot AI difficulty profile | Easy + scripted pauses | Easy / VeryEasy + pause schedule | [Design Data] | Adjust if completion rate drops below target. |
| Bot scripted pause durations | See Step 6 spec | 0–5 seconds per pause | [Design Data] | Reduce pauses if tutorial feels too slow; increase if players are losing. |
| Tutorial match duration cap | 120 seconds | 90–180 seconds | [Design Data] | Bot concedes at cap. |
| Player revive health | 50% of max | 30–75% | [Design Data] | Adjust if Step 6 failure rate is high. |
| Max revives in tutorial match | 2 | 1–3 | [Design Data] | |
| Bot attack frequency multiplier (post-revive) | 0.5 / 0.3 | 0.2–0.8 | [Design Data] | Tuned to recovery window for struggling players. |
| Completion reward — XP | 200 | 100–500 | [Design Data] | Must be equal for skip and full paths. |
| Completion reward — Diamonds | 10 | 5–25 | [Design Data] | Must be equal for skip and full paths. |
| Contextual hint display duration | 6 seconds | 3–10 seconds | [Design Data] | Auto-dismiss timer. |
| Max hints per session | 3 | 1–5 | [Design Data] | Caps hint frequency to avoid fatigue. |
| Total contextual hints in catalog | 5 | 3–10 | [Content Catalog] | Additional hints added via Content Catalog update. |
| Deck selection auto-advance timer | 30 seconds | 15–60 seconds | [Design Data] | Time before Balanced is auto-selected. |
| Step 8 (Shop Teaser) auto-advance timer | 12 seconds | 8–20 seconds | [Design Data] | |
| Movement fallback animation trigger | 8 seconds | 5–15 seconds | [Design Data] | Time before coaching animation appears. |
| Movement coaching trigger (voice) | 15 seconds | 10–20 seconds | [Design Data] | Time before coach character appears. |

---

## 8. Acceptance Criteria

Each criterion is written as a testable condition. QA should be able to verify each criterion in isolation.

---

### AC-01: Tutorial Triggers on First Login

**Given** a new player account with no `tutorialCompleted` record  
**And** `onboarding.tutorialEnabled = true`  
**When** the player completes profile creation and their session starts  
**Then** the tutorial flow launches automatically before the main menu is shown  
**And** `ONBOARDING_STARTED` event fires with the player's ID and session timestamp  

---

### AC-02: Tutorial Bypassed When Remote Config Disabled

**Given** a new player account with no `tutorialCompleted` record  
**And** `onboarding.tutorialEnabled = false`  
**When** the player's session starts  
**Then** the tutorial flow is not entered  
**And** the player is taken directly to the main menu  
**And** Vex's Balanced default loadout is configured on the account  
**And** `tutorialCompleted` is set to `true` on the Player Profile  
**And** no tutorial rewards are granted  

---

### AC-03: Step 1 (Movement) Completion

**Given** the tutorial is at Step 1  
**When** the player moves their character into the highlighted zone  
**Then** the step completes  
**And** `ONBOARDING_STEP_COMPLETED { step: 1 }` fires  
**And** the tutorial advances to Step 2  

---

### AC-04: Step 2 (Basic Attack) and Skip Button Appearance

**Given** the tutorial is at Step 2  
**When** the player lands the first hit on the training dummy  
**Then** the Skip Tutorial ghost button becomes visible  
**When** the player lands 3 total hits (dummy health reaches 0)  
**Then** the step completes  
**And** `ONBOARDING_STEP_COMPLETED { step: 2 }` fires  
**And** the tutorial advances to Step 3  

---

### AC-05: Step 3 (Ability Introduction) Auto-Advance

**Given** the tutorial is at Step 3  
**When** the player does not tap "Got it" within 10 seconds  
**Then** the step auto-completes  
**And** `ONBOARDING_STEP_COMPLETED { step: 3 }` fires  
**And** the tutorial advances to Step 4  

---

### AC-06: Step 4 (Deck Selection) — Player Chooses Archetype

**Given** the tutorial is at Step 4  
**When** the player selects and confirms an archetype (Aggressor, Defender, or Balanced)  
**Then** the step completes  
**And** `ONBOARDING_STEP_COMPLETED { step: 4, archetypeSelected: <chosen> }` fires  
**And** the HUD ability slots update to reflect the chosen loadout  
**And** the tutorial advances to Step 5  

---

### AC-07: Step 4 (Deck Selection) — Auto-Select on Timeout

**Given** the tutorial is at Step 4  
**When** the player does not select any archetype within 30 seconds  
**Then** the Balanced archetype is auto-selected  
**And** a toast "We picked Balanced for you — you can change this anytime" is displayed  
**And** the step completes  
**And** `ONBOARDING_STEP_COMPLETED { step: 4, archetypeSelected: "Balanced" }` fires  

---

### AC-08: Step 5 (Passive Ability) Completion

**Given** the tutorial is at Step 5  
**When** the player lands 3 hits on the training dummy and the passive triggers  
**Then** 1.5 seconds after the passive visual fires, the step auto-completes  
**And** `ONBOARDING_STEP_COMPLETED { step: 5 }` fires  
**And** the tutorial advances to Step 6  

---

### AC-09: Step 6 (Tutorial Match) — Scripted Win Path

**Given** the tutorial is at Step 6  
**When** the player engages the tutorial bot and deals damage  
**Then** the bot health decreases according to the Easy AI + scripted pause profile  
**And** the bot does not use defensive abilities  
**And** the bot does not regenerate health  
**And** the match resolves in a player win within 120 seconds  
**And** the tutorial victory screen is shown (not the standard match result screen)  
**And** `ONBOARDING_STEP_COMPLETED { step: 6 }` fires  
**And** `ONBOARDING_COMPLETED { completionType: "full" }` fires  
**And** rewards (200 XP, 10 Diamonds, Rookie Badge) are granted to the player's account  
**And** `tutorialCompleted = true` is written to Player Profile  

---

### AC-10: Step 6 — No MMR or Matchmaking Impact

**Given** the tutorial match is in progress or has completed  
**Then** no MMR update is applied to the player's account  
**And** no matchmaking record is created for this match  
**And** the match does not appear in the player's match history  

---

### AC-11: Step 6 — Revive on Player Death

**Given** the tutorial match is in progress  
**When** the player's health reaches 0  
**Then** the player is immediately revived with 50% health  
**And** an overlay "You're back in it — keep going!" appears briefly  
**And** the bot's attack frequency is reduced per the revive multiplier formula  
**And** the revive count is incremented  
**And** the maximum of 2 revives is enforced (no third revive)  

---

### AC-12: Skip Flow — Skip Before Deck Selection

**Given** the player is at Step 2 or Step 3  
**When** the player taps "Skip Tutorial" and confirms  
**Then** Vex's Balanced default loadout is auto-assigned  
**And** a toast informs the player of the auto-assigned loadout  
**And** `ONBOARDING_COMPLETED { completionType: "skip" }` fires  
**And** rewards (200 XP, 10 Diamonds, Rookie Badge) are granted  
**And** `tutorialCompleted = true` is written to Player Profile  

---

### AC-13: Skip Flow — Rewards Equal to Full Completion

**Given** a player who completed via skip  
**And** a player who completed the full tutorial  
**Then** both players have received exactly 200 XP, 10 Diamonds, and the Rookie Badge  
**And** neither has received more than the other  

---

### AC-14: Crash Resume

**Given** a player who completed Steps 1–4 and then the app crashed before completing Step 5  
**When** the player relaunches the app  
**Then** a resume prompt is displayed: "Welcome back! Want to pick up where you left off?"  
**When** the player selects "Resume"  
**Then** the tutorial begins at Step 5  
**And** Steps 1–4 are not re-played  

---

### AC-15: Re-Entry from Settings

**Given** a player whose `tutorialCompleted = true`  
**When** the player navigates to Settings → Gameplay → Replay Tutorial and confirms  
**Then** the tutorial replay begins at Step 1  
**And** the replay covers Steps 1–6 only (Steps 7 and 8 are not shown)  
**And** on completing Step 6, the victory screen shows "Great run! (Rewards already claimed.)"  
**And** no additional rewards are granted  
**And** `tutorialCompleted` remains `true` and is not reset  

---

### AC-16: Reward Grant Failure and Retry

**Given** the player won the tutorial match  
**And** the reward grant server call failed  
**Then** the tutorial victory screen still displays the reward summary  
**And** `pendingTutorialReward: true` is written to AsyncStorage  
**When** the player starts their next session and the server is reachable  
**Then** the grant is retried automatically  
**And** the server processes the grant idempotently (no duplicate rewards)  

---

### AC-17: `tutorialEnabled` Flipped to False Mid-Tutorial

**Given** a player actively in the tutorial at Step 3  
**And** `onboarding.tutorialEnabled` is pushed to `false` via Remote Config  
**When** Step 3 completes  
**Then** the tutorial exits to the main menu with a transition animation  
**And** `tutorialStepsCompleted` retains the steps completed before exit  
**And** no rewards are granted (Step 6 was not completed)  

---

### AC-18: Contextual Hint — First Loadout Editor Open

**Given** a player who has completed or skipped the tutorial  
**And** `hint_loadout_editor` has not appeared before (`contextualHintsSeen` does not contain it)  
**When** the player opens the Loadout Editor for the first time  
**Then** the hint "Try swapping your Slot 2 ability for a Defensive option!" appears  
**And** the hint auto-dismisses after 6 seconds or on player tap  
**And** `hint_loadout_editor` is added to `contextualHintsSeen` in AsyncStorage  
**And** the hint does not appear again in any subsequent session  

---

*End of Tutorial / Onboarding GDD*
