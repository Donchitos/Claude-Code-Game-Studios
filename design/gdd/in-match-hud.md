# In-Match HUD — Game Design Document
> **System**: In-Match HUD
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

### 1.1 System Ownership

The In-Match HUD is a **read-only Presentation layer system**. It consumes server-authoritative state snapshots delivered at 20 Hz by the Real-time Transport layer and renders them to the player. The HUD never generates or forwards game input; all touch input is handled exclusively by the touch/joystick input layer. The HUD has no authority over game state.

### 1.2 Read-Only Contract

| Direction | Data Flow |
|-----------|-----------|
| Upstream → HUD | State snapshots (20 Hz): HP values, ability cooldowns, status effects, match timer, zone elapsed ms, elimination events, player positions, score |
| HUD → Downstream | None — the HUD is terminal; it produces no output that other systems consume |

Any visual discrepancy between HUD display and server state is corrected on the next received snapshot. Client-side interpolation exists solely to smooth animation between snapshots; it is never authoritative.

### 1.3 Per-Mode Layout Variants

The HUD has three layout variants sharing a common core:

| Variant | Mode | Key Additions |
|---------|------|---------------|
| **Duel** | 1v1 Duel | Opponent HP bar (top), opponent character icon + name |
| **Squad** | 3v3 Squad Brawl | Team HP summary strip, team score, teammate alive/eliminated indicators |
| **FFA** | 8-player FFA | Player count remaining, personal score, collapsible leaderboard, zone shrink ring overlay, force_end_countdown |

Layout selection is determined once at match start from the Game Mode System state and does not change mid-match.

### 1.4 Performance Requirements

- The HUD renderer must not cause the frame rate to drop below **60 fps** on target devices (iPhone 12 / Pixel 5 class hardware and above).
- HUD React Native components must be mounted in a separate top-level overlay view to avoid triggering re-renders of the game canvas.
- Animated values (HP bars, cooldown overlays, damage numbers) must use the React Native `Animated` API (or Reanimated 2 worklets) so interpolation runs on the UI thread, not the JS thread.
- No HUD component may perform network requests, file I/O, or blocking computation. All data arrives pre-parsed from the snapshot deserialization layer.
- Maximum HUD JS bundle impact: HUD-related components must not add more than 15 ms to JS thread frame time under worst-case simultaneous update (8-player FFA: 8 HP bars updating, 4 elimination feed entries, damage numbers).

### 1.5 Safe Area Policy

All HUD elements must be positioned relative to safe area insets provided by `react-native-safe-area-context`. Hard-coded pixel offsets from screen edges are prohibited. This ensures correct rendering on notched, punch-hole, and Dynamic Island devices on both iOS and Android.

---

## 2. Player Fantasy

### 2.1 The Ideal HUD Experience

The best HUD is the one you forget is there. A player deep in a 1v1 duel should see nothing but their opponent and the arena. The HUD exists at the periphery of attention — present, readable at a glance, but never competing with the action.

The fantasy is **situational awareness without interruption**: the HUD tells you everything you need to know exactly when you need to know it, and stays out of the way when you don't.

### 2.2 Critical-Moment Surfacing

The HUD escalates information at critical moments:

| Moment | HUD Response |
|--------|-------------|
| Own HP drops below 50% | HP bar shifts yellow; subtle pulse on bar edge |
| Own HP drops below 25% | HP bar shifts red; urgent flash animation |
| Ability becomes ready | Ability slot pulses with a ready glow |
| Teammate is eliminated (Squad) | Teammate slot greys out immediately; elimination feed entry fires |
| Zone is closing in (FFA) | Zone ring visible on minimap tightens; in-world ring becomes visible |
| Zone at minimum radius | Large center-screen force_end_countdown: "ZONE CLOSING IN Xs" |
| Match timer ≤ 10 seconds | Timer turns red, shakes |
| Own player eliminated | Full-screen dim; "ELIMINATED" overlay; spectate prompt stub |

### 2.3 Peripheral Design Principles

- **Hierarchy**: Own HP > Ability readiness > Match timer > Opponent HP > Everything else. The eye naturally falls to the most critical element.
- **Color language**: Green = safe, Yellow = caution, Red = danger. Used consistently across HP, zone proximity, and timer.
- **Animation as signal, not decoration**: Every animation on the HUD communicates a state change. Idle animations are prohibited (no pulsing icons when nothing is happening, no looping idle effects that compete with gameplay).
- **Opacity and scale discipline**: HUD elements should be legible at full opacity but never feel like they cover more screen than they earn. The minimap, connection indicator, and passive icon operate at reduced scale to respect screen real estate.

---

## 3. Detailed Rules

### 3.1 HUD Update Cadence

- The HUD updates on every received state snapshot from the Real-time Transport layer (nominally 20 Hz, one update per 50 ms).
- HP bar fills, ability cooldown overlays, and status effect duration countdowns are **smoothly interpolated between consecutive snapshots** over a 50 ms window. Interpolation is linear unless otherwise specified.
- If a snapshot is missed (packet loss), the HUD holds the last known value and continues client-side interpolation (cooldown countdown advances, HP holds).
- On receipt of the next snapshot, values are **corrected via smooth interpolation** over 100 ms (not hard-snapped) to avoid jarring visual pops. Exception: HP corrections from damage (HP decreased by server) snap immediately and trigger the damage flash animation.
- The match timer always reflects the value from the most recent snapshot; it does not advance client-side between snapshots (timer drift would be misleading at MVP).

### 3.2 Own HP Bar

**Layout**: Large, prominent bar. Bottom-center in Duel; bottom-left in Squad and FFA to leave room for team strips.

**Color thresholds**:
- HP > 50% of max: **Green** (`#4CAF50`)
- HP ≤ 50% and > 25%: **Yellow** (`#FFC107`) — animated transition over 200 ms
- HP ≤ 25%: **Red** (`#F44336`) — animated transition over 200 ms

**On damage taken** (HP decreased between snapshots):
- Immediate hard snap to new HP value
- Flash animation: bar flashes white (`#FFFFFF`) for 120 ms then returns to appropriate color
- Screen edge vignette: subtle red vignette at screen edges for 300 ms when HP < 25%

**On healing** (HP increased between snapshots):
- Smooth interpolation over 200 ms (no flash)

**Empty bar**: At 0 HP the bar is empty. The own-player-eliminated overlay fires (see §3.13).

**Bar structure**: [Character icon thumbnail] [HP bar fill] [HP value text: "current / max"]

### 3.3 Ability Slots

Two active ability slots are displayed at the bottom of the screen, flanking or below the HP bar (layout per platform guidelines). One passive ability icon is shown adjacent to the active slots.

**Active ability slot anatomy**:
- Background: rounded square tile
- Center: ability icon (full color when ready; greyscale when on cooldown)
- Cooldown state — **on cooldown**:
  - Greyscale icon
  - Arc (circular sweep) overlay depleting clockwise from full to empty as cooldown expires
  - Seconds remaining displayed center (integer, rounds up): e.g., "3", "2", "1"
  - Seconds display interpolated client-side: decrements by elapsed time since last snapshot
  - Server snapshot corrects client countdown: smooth interpolation over 100 ms if delta > 0.2 s
- Cooldown state — **ready**:
  - Full-color icon
  - Pulse glow animation (scale 1.0 → 1.08 → 1.0, 400 ms loop, stops after 3 loops or on ability use)
  - No countdown text
- Ability name: abbreviated label below icon (max 6 characters, e.g., "SURGE", "BLAST")

**Passive ability slot anatomy**:
- Smaller icon (60% of active slot size)
- Always visible; no cooldown arc (passives have no cooldown)
- **Passive trigger glow**: when the passive condition activates (e.g., stacking hit threshold reached), icon pulses with a golden glow (`#FFD700`) for 600 ms
- For stacking passives (e.g., Vex's hit counter): small numeric badge on corner of passive icon showing current stack count

### 3.4 Status Effect Icons

A horizontal strip of status effect icons is displayed below the own HP bar.

| Effect | Icon | Color |
|--------|------|-------|
| STUNNED | Skull | `#9C27B0` (purple) |
| SLOWED | Snail | `#2196F3` (blue) |
| SHIELDED | Bubble | `#00BCD4` (cyan) |
| BURNING | Flame | `#FF5722` (deep orange) |
| INVISIBLE | Ghost | `#9E9E9E` (grey) |

**Per-icon display**:
- Icon displayed at 24×24 dp
- Duration countdown in seconds displayed below or beside icon (integer, rounds up)
- Duration depletes client-side; corrected from server snapshot
- Icons appear and disappear with a 150 ms fade animation
- If > 4 status effects are active simultaneously, overflow "+N" badge replaces the 4th+ icons

**Opponent status effects** (Duel mode): mirrored strip below opponent HP bar; same icon set.

### 3.5 Match Timer

**Position**: Top-center, prominent. 

**Display format**: `MM:SS` (e.g., `02:47`). When time < 60 seconds: `SS` only (e.g., `47`).

**Normal state**: White text, medium weight, legible at a glance.

**Warning state** (≤ 10 seconds remaining):
- Text color transitions to **red** (`#F44336`)
- Shake animation: ±3 dp horizontal oscillation, 8 Hz, for entire remaining duration
- Sound cue: handled by Audio system (not HUD scope)

**End state**: Timer stops at `0` when the match_end event arrives. Timer is frozen at its final value during the 1.5 s results transition.

**Overtime / tie-break**: If the game mode extends beyond the nominal timer, the display shows `OT` and counts up from 0.

### 3.6 Elimination Feed

**Position**: Right side of screen, vertically stacked list.

**Entry format**: `{killerName} ⚔ {victimName}`

- Killer name color: white
- Sword icon: `#FFC107` (gold)
- Victim name color: `#F44336` (red)
- Own player's name highlighted in **bold** in either position

**Behavior**:
- Each entry slides in from the right on arrival
- Entry is automatically dismissed after **4 seconds**
- Maximum **4 entries visible simultaneously**; when a 5th arrives, the oldest is pushed off (slide out left) immediately
- At match end, all entries fade out with the HUD freeze

**Data source**: `elimination` events from server snapshot event list (not derived from HP delta — sourced directly from authoritative elimination events).

### 3.7 Minimap

**Position**: Top corner (top-right in Duel and FFA; top-left in Squad to balance team strip placement).

**Size**: Maximum **20% of screen width** (capped at 80 dp on large screens). Square aspect ratio. Circular mask preferred.

**Content**:
- Own player: larger dot, team color (or white in FFA), pulsing ring
- Ally positions (Squad/FFA allies): colored dots matching team color
- Enemy positions: red dots (no fog of war at MVP — all enemy positions visible)
- Zone boundary: white ring on minimap (FFA) or neutral boundary ring (Squad/Duel)
- Dot positions update every received snapshot (20 Hz); dots tween smoothly to new positions over 50 ms

**Zone boundary on minimap**:
- Derived client-side from `zone_elapsed_ms` in snapshot (see §4.3 for radius formula)
- Ring radius scaled proportionally to minimap size
- Ring animates inward as zone shrinks

**Interaction**: Minimap is non-interactive at MVP (no tap-to-ping).

**Background**: Semi-transparent dark fill (`rgba(0,0,0,0.6)`) to ensure dot visibility against any arena backdrop.

### 3.8 Zone Indicator (FFA Only)

**In-world ring**:
- Translucent ring rendered at zone boundary in world space (handled by the game renderer; HUD provides zone radius value derived from `zone_elapsed_ms`)
- Ring color: `rgba(255, 100, 50, 0.4)` (translucent orange-red)
- **Outside zone**: ring edge glows red (`#FF1744`) with a 1 Hz pulse; own HP bar gains a red zone-damage tick indicator

**Zone shrink animation**:
- Ring smoothly animates inward between snapshots at the rate derived from the zone shrink formula (§4.3)
- No hard snaps on ring position — always interpolated

**force_end_countdown** (zone at minimum radius):
- Triggered by `force_end_countdown` event from server (Game Mode System requirement)
- Large center-screen overlay: text "ZONE CLOSING IN **Xs**" (e.g., "ZONE CLOSING IN 5s")
- Font size: 48 sp, bold, white with red drop shadow
- Background: semi-transparent dark panel
- Countdown decrements client-side from the value provided in the event; corrected each snapshot
- At 0: display "0" for one frame, then transition to match-end results flow
- Overlay does not block touch input to the ability/movement layer

### 3.9 Damage Numbers

Floating text appears above the target character on each hit. Damage numbers are spawned by hit confirmation events in the snapshot.

| Type | Color | Trigger |
|------|-------|---------|
| Normal hit | White (`#FFFFFF`) | Standard melee/ranged hits |
| Critical / ability hit | Orange (`#FF9800`) | Crit flag or ability_damage flag in hit event |
| Zone damage | Red (`#F44336`) | zone_damage event |

**Animation**:
- Spawn position: above target character (world-space origin, projected to screen)
- Rise: float upward 40 dp over 1 second
- Fade: linear fade from opacity 1.0 to 0.0 over the last 400 ms of the 1 s lifetime
- Scale: spawn at 1.2× scale, shrink to 1.0× over 150 ms (pop effect)
- Simultaneous hits: offset horizontally by ±12 dp to avoid stacking

**Performance cap**: Maximum 12 simultaneous damage number instances (oldest are culled if exceeded).

### 3.10 Connection Quality Indicator

**Position**: Corner (opposite side from minimap), small.

**Display**: Three-bar signal icon, colored by RTT threshold:
- Green (`#4CAF50`): RTT < 80 ms — "Good"
- Yellow (`#FFC107`): 80 ms ≤ RTT < 150 ms — "Fair"
- Red (`#F44336`): RTT ≥ 150 ms — "Poor"

**Interaction**: Tap on indicator shows tooltip: `"Ping: Xms"` (X = current RTT in integer milliseconds). Tooltip dismisses after 3 seconds or on next tap.

**RTT source**: Provided by Real-time Transport layer; updated each snapshot. HUD uses a rolling 3-snapshot moving average to avoid rapid flickering.

**Packet loss indication**: If ≥ 2 consecutive snapshots are missed, icon switches to a disconnected state (grey bars with X) for the missed duration.

### 3.11 1v1 Duel Additions

**Opponent HP bar**:
- Mirrored layout at top of screen (above match timer or flanking it)
- Same color threshold rules as own HP bar (§3.2)
- Damage flash on opponent taking damage (same flash animation — confirms hits)
- No screen-edge vignette for opponent damage

**Opponent character icon + name**:
- Character portrait thumbnail (40×40 dp) left of opponent HP bar
- Character name label (max 12 characters, truncated with ellipsis)
- Player name label below character name (smaller font, grey)

### 3.12 3v3 Squad Brawl Additions

**Team HP summary strip**:
- Compact horizontal or vertical strip
- Ally strip: own team's 2 other players + self (3 slots) displayed with small HP bars and character thumbnails
- Enemy strip: 3 opponent slots with HP bars (enemy HP values from server state — no fog of war at MVP)
- Each slot: 32×32 dp character thumbnail + compact HP bar beneath it
- Eliminated players: thumbnail greyed out + translucent "X" overlay; HP bar emptied

**Team score**:
- Displayed top-center or adjacent to match timer
- Format: `OWN_TEAM_ELIMS — ENEMY_TEAM_ELIMS` (e.g., `2 — 1`)

**Teammate status indicators**:
- Each ally slot in team HP strip has a status badge: small colored dot (green = alive, grey = eliminated)
- On elimination: badge transitions grey with 300 ms fade; slot thumbnail gains "X" overlay

### 3.13 8-Player FFA Additions

**Player count remaining**:
- Top area, near match timer
- Format: `"5 LEFT"` (or `"LAST 2"` when 2 players remain)
- Updates on each elimination event

**Personal score**:
- Formula: `(kills × 10) + survival_points` (see §4.4)
- Displayed below match timer or in top region
- Format: `"Score: 240"`
- Score increments with a brief flash (+value) when kills or survival points are awarded

**Leaderboard panel**:
- Collapsible side panel (default: collapsed during active play; auto-expands at match end)
- Shows all 8 players ranked by current personal score
- Own entry highlighted
- Player tap: no action at MVP
- Auto-show: panel slides in automatically on match_end event
- Manual toggle: tap the leaderboard icon (persistent in FFA HUD corner)

**Zone shrink ring**: see §3.8.

**force_end_countdown**: see §3.8.

### 3.14 "You Are Eliminated" Overlay

Triggered when the own player's HP reaches 0 (confirmed by server elimination event for own player).

**Layout**:
- Full-screen dim: `rgba(0, 0, 0, 0.7)` overlay
- Center text: `"ELIMINATED"` — 64 sp, bold, red (`#F44336`)
- Sub-text: `"Spectating until match ends..."` — 18 sp, white, grey-tinted
- Spectate prompt is a **stub at MVP**: the screen displays this text but spectating is not functional; the player sees the eliminated screen until the match ends
- Ability buttons are non-interactive while eliminated overlay is active (pointer events disabled)
- All other HUD elements remain visible but dimmed behind the overlay (match timer, elimination feed continue to update for context)

---

## 4. Formulas

### 4.1 HP Bar Color Threshold

```
function getHpBarColor(currentHp, maxHp):
    ratio = currentHp / maxHp
    if ratio > 0.50:
        return GREEN   // #4CAF50
    elif ratio > 0.25:
        return YELLOW  // #FFC107
    else:
        return RED     // #F44336
```

Color transitions are animated over **200 ms** using linear interpolation in HSL color space to avoid the muddied intermediate that RGB interpolation produces across the green→yellow boundary.

### 4.2 Cooldown Display Interpolation

The cooldown seconds remaining shown on an ability slot is computed as:

```
displayCooldown(t) = serverCooldownRemaining - (t - snapshotTimestamp)
```

Where:
- `serverCooldownRemaining` = cooldown seconds from last received snapshot
- `t` = current client time (ms)
- `snapshotTimestamp` = client timestamp when the snapshot was received

Display value is clamped to `[0, maxCooldown]`. Displayed as integer ceiling: `ceil(displayCooldown(t))`.

**Server correction interpolation**: When a new snapshot arrives with a cooldown value that differs from the client's predicted value by more than **0.2 seconds**:

```
correctedCooldown(t) = lerp(clientPredicted, serverValue, min(1.0, (t - correctionStart) / 100ms))
```

Interpolation runs over **100 ms**. If the delta is ≤ 0.2 s, the client value is accepted without correction (sub-threshold jitter suppressed).

### 4.3 Zone Ring Radius Mapping (Logical Game Units → Screen Pixels)

Zone radius is recomputed client-side from `zone_elapsed_ms` using the same shrink curve as the server (Game Mode GDD). The formula:

```
zoneRadius_LGU(elapsed_ms) = R_initial × max(0, 1 - (elapsed_ms / shrink_duration_ms) ^ shrink_exponent)
```

Where `R_initial`, `shrink_duration_ms`, and `shrink_exponent` are constants from the Game Mode GDD (exposed as tuning knobs in §7).

**LGU to screen pixels** (minimap):
```
ringRadius_px_minimap = (zoneRadius_LGU / mapRadius_LGU) × (minimapSize_px / 2)
```

**LGU to screen pixels** (in-world ring, via camera projection):
```
ringRadius_px_world = zoneRadius_LGU × (screenHeight_px / cameraViewHeight_LGU)
```

Camera view height is provided by the rendering layer.

### 4.4 Personal Score Formula (FFA)

```
personalScore = (killCount × KILL_POINT_VALUE) + survivalPoints
```

Where:
- `KILL_POINT_VALUE` = 10 (tuning knob)
- `survivalPoints` = points awarded by server for time survived (Game Mode GDD defines rate; HUD displays, does not compute)

HUD displays the `personalScore` value directly from the snapshot. It does not independently compute kill or survival points.

### 4.5 Damage Number Fade Timing

```
opacity(t) = 1.0                            if t ≤ 0.6s
           = lerp(1.0, 0.0, (t - 0.6) / 0.4)   if 0.6s < t ≤ 1.0s
           = 0.0 (despawn)                  if t > 1.0s

verticalOffset_dp(t) = 40 × (t / 1.0s)    // rises 40dp over 1 second
```

Where `t` is time since the damage number was spawned.

---

## 5. Edge Cases

### 5.1 All Teammates Eliminated (3v3 Solo Survivor)

When both teammates are eliminated and the own player is the last survivor on their team:

- All teammate slots in the team HP summary strip display greyed-out thumbnails with the "X" overlay
- Teammate status indicators both show grey dead dots
- Team score continues to update if the solo player secures eliminations
- No special solo-survivor UI badge at MVP (considered a V2 feature)
- HUD continues to operate normally; the solo survivor can still play, use abilities, and see the full match HUD

### 5.2 Match Ends While HUD Is Visible

On receiving the `match_end` event:

1. HUD state is **frozen** at the last received snapshot values (no further interpolation updates)
2. Ability slot animations stop; cooldown countdowns pause
3. Match timer stops at its final value
4. After **1.5 seconds**, the results screen overlay slides in (handled by the UI Navigation layer; HUD is unmounted)
5. If a damage number animation is in progress during freeze, it completes its remaining animation before despawning (no hard cutoff mid-animation)

### 5.3 Own Player Eliminated

On receiving an elimination event identifying the own player as victim:

- `ELIMINATED` overlay fires immediately (§3.14)
- Ability slots become non-interactive (touch events disabled on those components)
- Own HP bar remains visible at 0, showing the empty-red state
- Other HUD elements (match timer, elimination feed, minimap) continue to receive snapshot updates and update normally
- If the match ends while eliminated, the eliminated overlay is replaced by the results screen after the 1.5 s transition

### 5.4 Status Effect Applied and Removed in Same Tick

If a status effect appears and disappears between two consecutive snapshots (duration < 50 ms tick window), the HUD never received the "active" state:

- **Suppress**: Do not show the icon. The HUD only displays status effects present in the most recently received snapshot. Sub-tick transient effects are not surfaced.
- **Minimum display rule**: If the effect duration in the snapshot is > 0 ms but the expected remaining duration at render time is < **200 ms** (below the perception threshold), still suppress the icon to avoid flicker.
- This matches the risk note in the Ability/Skill GDD that very short-duration debuffs may not be perceptible.

### 5.5 force_end_countdown Arrives with 0 Seconds Remaining

If the `force_end_countdown` event arrives with a `countdown_seconds` value of 0 (server sent it on the same tick the countdown expired):

1. Display "ZONE CLOSING IN **0s**" for exactly **one rendered frame** (approximately 16 ms)
2. Immediately transition to the match_end flow (the `match_end` event should arrive on the same or next snapshot; if it does not arrive within 500 ms, display a "Waiting for results..." placeholder)
3. Do not leave the countdown overlay stuck at 0 indefinitely

### 5.6 Snapshot Arrives Out of Order

If a snapshot with a lower sequence number arrives after a higher one (late packet):

- Discard the out-of-order snapshot; do not apply it to HUD state
- Continue displaying the most recent authoritative state

### 5.7 Character Data Missing at HUD Mount

If the Character/Deck Select data has not been fully received when the HUD is first mounted (e.g., fast reconnect):

- Display placeholder grey silhouette in character icon positions
- Ability slot icons show a loading spinner for up to 2 seconds
- If data arrives within 2 seconds, animate icons in with a 150 ms fade; if not, show an error state (generic icon, no ability name)

### 5.8 RTT Spike During Active Match

If RTT exceeds 500 ms (packet effectively lost for 10+ tick cycles):

- Connection indicator shows red disconnected state
- HUD holds last known snapshot; client-side cooldown interpolation continues
- After 3 consecutive missed snapshots, display a subtle "Reconnecting..." banner (top-center, below match timer)
- Banner dismisses 1 s after snapshot delivery resumes

---

## 6. Dependencies

### 6.1 Upstream Dependencies

| System | Data Provided | Required For |
|--------|---------------|-------------|
| **Combat System** | HP values (current + max), status effects (type + duration), hit events (damage value + type), elimination events | HP bar, status icons, damage numbers, elimination feed |
| **Game Mode System** | Match timer value, mode-specific scoring (team score, personal score, player count), zone state (`zone_elapsed_ms`), `force_end_countdown` event | Match timer, score displays, zone ring, FFA countdown |
| **Real-time Transport** | State snapshots at 20 Hz, RTT/ping values, packet loss detection | All HUD update cadence; connection quality indicator |
| **Character/Deck Select** | Character identity (icon, name, ability icons, ability names, passive details) | Character icon, ability slot icons, passive icon, opponent identity |

### 6.2 Downstream Dependencies

None. The In-Match HUD is a terminal display system. No other system reads from or depends on HUD state.

### 6.3 Peer Interactions (No Dependency, Coordination Required)

| System | Interaction |
|--------|-------------|
| **Touch/Joystick Input Layer** | Shares screen space; HUD must not occlude the movement joystick or primary attack button zones. Layout coordinates required during integration. |
| **Game Renderer** | Zone ring in-world overlay: HUD provides zone radius value; renderer draws the ring. Interface contract must be defined (props vs. shared state). |
| **UI Navigation / Results Screen** | On match_end, HUD triggers the 1.5 s freeze then yields to Results Screen. Handoff contract: HUD fires an `onMatchEndTransition` callback after the freeze. |
| **Audio System** | HUD state changes (low HP, ability ready, zone closing) may trigger audio cues. HUD publishes events; Audio System subscribes. HUD does not call Audio APIs directly. |

---

## 7. Tuning Knobs

All values below are defined in a single configuration object (e.g., `hud-config.ts`) and must not be hardcoded in component files.

| Knob | Default Value | Description |
|------|---------------|-------------|
| `HP_COLOR_YELLOW_THRESHOLD` | `0.50` | HP ratio below which bar turns yellow |
| `HP_COLOR_RED_THRESHOLD` | `0.25` | HP ratio below which bar turns red |
| `HP_COLOR_TRANSITION_MS` | `200` | Duration of HP bar color transition animation |
| `HP_DAMAGE_FLASH_MS` | `120` | Duration of white flash on damage taken |
| `COOLDOWN_CORRECTION_THRESHOLD_S` | `0.2` | Delta above which client cooldown is corrected from server |
| `COOLDOWN_CORRECTION_LERP_MS` | `100` | Duration of cooldown correction interpolation |
| `DAMAGE_NUMBER_LIFETIME_MS` | `1000` | Total display time for floating damage numbers |
| `DAMAGE_NUMBER_FADE_START_MS` | `600` | Time into lifetime at which fade begins |
| `DAMAGE_NUMBER_RISE_DP` | `40` | Vertical rise distance in density-independent pixels |
| `DAMAGE_NUMBER_MAX_INSTANCES` | `12` | Maximum simultaneous damage number instances |
| `ELIMINATION_FEED_DURATION_S` | `4` | Seconds each elimination feed entry remains visible |
| `ELIMINATION_FEED_MAX_VISIBLE` | `4` | Maximum simultaneously visible elimination feed entries |
| `MINIMAP_MAX_WIDTH_PERCENT` | `0.20` | Minimap width as a fraction of screen width |
| `MINIMAP_MAX_WIDTH_DP` | `80` | Hard cap on minimap width in dp |
| `ZONE_RING_OPACITY` | `0.4` | In-world zone ring opacity (translucent channel) |
| `ZONE_RING_OUTSIDE_GLOW_OPACITY` | `0.8` | Zone ring red glow opacity when player is outside |
| `FORCE_END_COUNTDOWN_THRESHOLD_S` | `0` | Zone radius value (in LGU) below which countdown is displayed (0 = minimum radius event from server) |
| `STATUS_EFFECT_MIN_DISPLAY_MS` | `200` | Minimum effect duration to display icon (shorter durations suppressed) |
| `MATCH_END_FREEZE_MS` | `1500` | Freeze duration before results screen transition |
| `TIMER_WARNING_SECONDS` | `10` | Match timer threshold for red flash + shake |
| `CONNECTION_RTT_GOOD_MS` | `80` | RTT below which connection is shown as green |
| `CONNECTION_RTT_FAIR_MS` | `150` | RTT below which connection is shown as yellow (above = red) |
| `CONNECTION_RTT_AVERAGE_WINDOW` | `3` | Number of snapshots used for RTT moving average |
| `KILL_POINT_VALUE` | `10` | Points per kill in FFA personal score |

---

## 8. Acceptance Criteria

### 8.1 HP Bar Updates and Color Shifts

- [ ] **AC-HUD-001**: Given a state snapshot where own HP = 600 and maxHP = 1000 (60%), the HP bar fill is green and displays "600 / 1000".
- [ ] **AC-HUD-002**: Given a state snapshot where own HP = 450 and maxHP = 1000 (45%), the HP bar fill is yellow.
- [ ] **AC-HUD-003**: Given a state snapshot where own HP = 200 and maxHP = 1000 (20%), the HP bar fill is red.
- [ ] **AC-HUD-004**: When a damage event causes HP to decrease, the HP bar flashes white for 120 ms (±20 ms tolerance) then returns to the appropriate color.
- [ ] **AC-HUD-005**: HP bar color transitions (green→yellow, yellow→red) animate over 200 ms; no instant color change without animation.
- [ ] **AC-HUD-006**: In 1v1 Duel mode, opponent HP bar appears at the top of the screen and reflects opponent HP from server snapshots.

### 8.2 Ability Cooldown Display and Server Correction

- [ ] **AC-HUD-010**: When an ability has 3.0 s cooldown remaining (per snapshot), the slot displays "3" and the arc overlay is 3/maxCooldown depleted.
- [ ] **AC-HUD-011**: Between snapshots, the displayed countdown decrements smoothly (client-side interpolation); it does not jump.
- [ ] **AC-HUD-012**: When the server snapshot arrives with a cooldown value that differs from client prediction by > 0.2 s, the display corrects to the server value over 100 ms (no hard snap).
- [ ] **AC-HUD-013**: When cooldown reaches 0, the ability icon returns to full color and a pulse glow plays (3 loops).
- [ ] **AC-HUD-014**: The passive ability icon shows a golden glow for 600 ms when the passive trigger condition fires.

### 8.3 Elimination Feed

- [ ] **AC-HUD-020**: When an elimination event arrives, an entry "{killerName} ⚔ {victimName}" appears in the right-side feed within one rendered frame.
- [ ] **AC-HUD-021**: Each elimination feed entry is removed from display after 4 seconds (±200 ms tolerance).
- [ ] **AC-HUD-022**: When 5 elimination events arrive in rapid succession, the oldest entry is removed and the new entry is shown; never more than 4 entries visible simultaneously.
- [ ] **AC-HUD-023**: When the own player is the killer or victim, their name is displayed in bold.

### 8.4 Zone Ring Rendering (FFA)

- [ ] **AC-HUD-030**: In FFA mode, the minimap displays a white ring representing the zone boundary, derived from `zone_elapsed_ms`.
- [ ] **AC-HUD-031**: As `zone_elapsed_ms` increases across snapshots, the minimap ring radius decreases proportionally (zone shrinks inward).
- [ ] **AC-HUD-032**: When the own player is outside the zone boundary (server indicates zone damage), the zone ring edge pulses red.
- [ ] **AC-HUD-033**: The in-world zone ring opacity matches `ZONE_RING_OPACITY` tuning knob (default 0.4).

### 8.5 force_end_countdown Display

- [ ] **AC-HUD-040**: When a `force_end_countdown` event is received with countdown_seconds = 5, the center-screen overlay displays "ZONE CLOSING IN 5s".
- [ ] **AC-HUD-041**: The countdown decrements client-side each second; each subsequent snapshot corrects the value.
- [ ] **AC-HUD-042**: When countdown reaches 0, "ZONE CLOSING IN 0s" displays for one frame, then the match_end transition begins.
- [ ] **AC-HUD-043**: The force_end_countdown overlay does not block ability touch targets.

### 8.6 Eliminated Overlay

- [ ] **AC-HUD-050**: When an elimination event identifies the own player as victim, the full-screen dim overlay and "ELIMINATED" text appear within one rendered frame of the event.
- [ ] **AC-HUD-051**: Ability slot buttons are non-interactive while the eliminated overlay is active.
- [ ] **AC-HUD-052**: The match timer and elimination feed continue to update behind the eliminated overlay.
- [ ] **AC-HUD-053**: The spectate prompt stub text "Spectating until match ends..." is visible.

### 8.7 Safe Area Compliance

- [ ] **AC-HUD-060**: On an iPhone with Dynamic Island (notched), all HUD elements are positioned within the safe area insets; no element is clipped or obscured by the notch/island.
- [ ] **AC-HUD-061**: On an Android device with a punch-hole camera, all HUD elements are within safe area insets.
- [ ] **AC-HUD-062**: No HUD element uses a hard-coded pixel offset from any screen edge; all offsets are derived from `useSafeAreaInsets()`.

### 8.8 60fps Performance Budget

- [ ] **AC-HUD-070**: In 8-player FFA with maximum simultaneous HUD activity (8 HP bars updating, 4 elimination feed entries, 12 damage numbers, zone countdown active), the JS thread frame time does not exceed 15 ms (measured via React DevTools Profiler on target hardware: iPhone 12 / Pixel 5 class).
- [ ] **AC-HUD-071**: HP bar and cooldown animations run on the UI thread (Reanimated worklet or `Animated.Value` with `useNativeDriver: true`), verified by confirming no JS thread activity during isolated animation playback.
- [ ] **AC-HUD-072**: Sustained match play (5 minutes) does not produce a measurable memory leak in HUD components (damage number instances are properly despawned; no growing list of unmounted component references).

---

*End of Document*
