# Settings & Accessibility — Game Design Document
> **System**: Settings & Accessibility
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
   - 3.1 [Settings Navigation Structure](#31-settings-navigation-structure)
   - 3.2 [Audio Settings](#32-audio-settings)
   - 3.3 [Display Settings](#33-display-settings)
   - 3.4 [Accessibility Settings](#34-accessibility-settings)
   - 3.5 [Controls Settings](#35-controls-settings)
   - 3.6 [Notifications Settings](#36-notifications-settings)
   - 3.7 [Privacy Settings](#37-privacy-settings)
   - 3.8 [Account Management](#38-account-management)
   - 3.9 [Persistence & Apply Model](#39-persistence--apply-model)
   - 3.10 [Colorblind Mode Palette Definitions](#310-colorblind-mode-palette-definitions)
4. [Formulas](#4-formulas)
5. [Edge Cases](#5-edge-cases)
6. [Dependencies](#6-dependencies)
7. [Tuning Knobs](#7-tuning-knobs)
8. [Acceptance Criteria](#8-acceptance-criteria)

---

## 1. Overview

The Settings & Accessibility screen is the player's personal configuration hub for BRAWLZONE. It is a full-screen modal sheet accessible from the **Settings** tab in the Main Menu bottom navigation bar. It does not interrupt active matches; players must navigate to the Main Menu first.

**Owns the following concerns:**

| Category | Scope |
|---|---|
| Audio | Master, music, and SFX volume sliders; mute-all toggle |
| Display | Brightness override, damage numbers, FPS counter, reduce motion |
| Accessibility | Colorblind modes, high contrast, large text, large buttons, screen reader hints |
| Controls | Joystick size, joystick position, auto-aim sensitivity |
| Notifications | Match reminder and event alert toggles (stub at MVP) |
| Privacy | Analytics consent (server-synced) |
| Account | Display name change link, log out, delete account |

**What this system does NOT own:**

- Push notification delivery — owned by Push Notification System (deferred to VS)
- Analytics event emission — owned by Analytics/Telemetry GDD
- Display name cooldown enforcement — enforced by Player Profile API
- Remote Config sync of settings to server — deferred to VS; all storage is local (AsyncStorage) at MVP, except analytics consent

**Entry point:** Main Menu → bottom navigation bar → "Settings" tab.

**Safe area requirement:** All UI must respect iOS and Android safe area insets. The screen uses `SafeAreaView` (Expo SDK) to ensure no content is obscured by notches, home indicators, or status bars.

---

## 2. Player Fantasy

The Settings & Accessibility screen exists to give every player three feelings:

**1. "This game was built for me."**
BRAWLZONE adjusts to the player's body, hardware, and environment — not the other way around. A player with color vision deficiency can activate a remapped palette and never be disadvantaged because a UI element was red vs. green. A player with a small phone and large thumbs can expand all touch targets with one toggle. The game meets the player where they are.

**2. "I am in control of my data and account."**
Players can see exactly what data they share. The analytics consent toggle is labeled plainly ("Share gameplay data to improve BRAWLZONE") with no dark patterns. If a player wants to leave — whether logging out or deleting their account entirely — the path is clear, honest, and irreversible only when the player has explicitly confirmed it. Delete requires typing "DELETE"; there is no accidental departure.

**3. "My preferences are remembered without friction."**
Settings apply immediately on change. There is no Save button. Every slider position and toggle state is written to AsyncStorage before the player lifts their finger, so a closed app or a crash never resets them to defaults. Preferences are restored exactly on every launch.

---

## 3. Detailed Rules

### 3.1 Settings Navigation Structure

The Settings screen is organized as a vertically scrollable list of **category sections**. Each section has a header label and contains its settings items below it. Sections appear in this order:

1. Audio
2. Display
3. Accessibility
4. Controls
5. Notifications
6. Privacy
7. Account

On phones (the primary target), the full list is a single scroll view. No tab bar or drawer is used within Settings — one flat scroll surface reduces navigation friction on small screens.

Each category section header is sticky while that section is in view, allowing the player to always see which section they are in.

### 3.2 Audio Settings

**Section label:** AUDIO

| Setting | Control Type | Range / Options | Default | AsyncStorage Key |
|---|---|---|---|---|
| Master Volume | Slider | 0 – 100 (integer steps) | 80 | `settings.audio.masterVolume` |
| Music Volume | Slider | 0 – 100 (integer steps) | 70 | `settings.audio.musicVolume` |
| SFX Volume | Slider | 0 – 100 (integer steps) | 85 | `settings.audio.sfxVolume` |
| Mute All | Toggle | On / Off | Off | `settings.audio.muteAll` |

**Behavior rules:**

- All four settings are written to AsyncStorage immediately on any change (slider release or toggle flip).
- Audio output applies immediately — the player hears the effect of their slider drag in real time. Slider drag events fire throttled volume updates at most every 50 ms to avoid performance spikes.
- When **Mute All** is toggled ON: all audio output is silenced instantly. The three sliders remain visible and interactive (their values are preserved) but have no audible effect while mute is active.
- When **Mute All** is toggled OFF: audio resumes at the currently stored slider values.
- Volume values are independent percentages. The effective volume for a channel is: `effectiveVolume = muteAll ? 0 : (channelVolume / 100) * (masterVolume / 100)`. Applying master as a multiplier of individual channels is the responsibility of the audio engine, not this screen; the screen stores and exposes raw values only.
- Sliders use a continuous `onValueChange` callback for live preview and a separate `onSlidingComplete` callback for the AsyncStorage write.

### 3.3 Display Settings

**Section label:** DISPLAY

| Setting | Control Type | Options | Default | AsyncStorage Key |
|---|---|---|---|---|
| Screen Brightness Override | Toggle | On (use app override) / Off (use device brightness) | Off | `settings.display.brightnessOverride` |
| Brightness Level | Slider (conditional) | 0 – 100 | 80 | `settings.display.brightnessLevel` |
| Show Damage Numbers | Toggle | On / Off | On | `settings.display.showDamageNumbers` |
| Show FPS Counter | Toggle | On / Off | Off | `settings.display.showFpsCounter` |
| Reduce Motion | Toggle | On / Off | Off | `settings.display.reduceMotion` |

**Behavior rules:**

- **Screen Brightness Override:** When toggled ON, a **Brightness Level** slider appears beneath it (animated in via a height expand, unless Reduce Motion is ON, in which case it appears instantly). Uses Expo `Brightness` API (`expo-brightness`) to set screen brightness. When toggled OFF, brightness control returns to the OS; the stored `brightnessLevel` value is retained for re-enabling.
- **Show Damage Numbers:** Controls whether floating combat text (damage dealt, healing received) renders above characters during a match. Setting is read by the Match HUD system at match start; it does not hot-swap mid-match for performance reasons (see Edge Cases §5).
- **Show FPS Counter:** Renders a small overlay counter in the top-right corner of the game viewport showing current frames per second. Visible in all builds (debug and release). Intended as a QA and community performance-reporting aid. Toggling ON activates the overlay immediately; toggling OFF removes it immediately.
- **Reduce Motion:** When ON, all non-essential animations are disabled. "Non-essential" is defined as: decorative idle animations on menu elements, particle trail effects in the lobby, screen-transition slide animations (replaced with crossfades), and button press scale animations. Essential animations (character attacks, projectile travel, hit effects, death animations) are not suppressed. This setting is read at app launch and whenever the value changes; it applies to menu UI immediately. Match-side UI reads the value at match start.

### 3.4 Accessibility Settings

**Section label:** ACCESSIBILITY

| Setting | Control Type | Options | Default | AsyncStorage Key |
|---|---|---|---|---|
| Colorblind Mode | Segmented / Radio | None / Protanopia / Deuteranopia / Tritanopia | None | `settings.accessibility.colorblindMode` |
| High Contrast Mode | Toggle | On / Off | Off | `settings.accessibility.highContrast` |
| Large Text Mode | Toggle | On / Off | Off | `settings.accessibility.largeText` |
| Button Size | Segmented / Radio | Normal / Large | Normal | `settings.accessibility.buttonSize` |
| Screen Reader Hints | Toggle | On / Off | Off | `settings.accessibility.screenReaderHints` |

**Behavior rules:**

- **Colorblind Mode:** Selects a named color palette that remaps all UI and HUD elements that use color as the primary conveyor of information. Affected elements at minimum: HP bars (player, enemy, boss), team color indicators (player dot on minimap, ring color), zone ring color, status effect icons. When a mode other than None is active, the palette swap is applied globally via a React Context provider (`ColorblindContext`) that all affected components subscribe to. Palette swap applies on next match start; it does not hot-swap mid-match (see §5 Edge Cases). Menu UI palette swap applies immediately on selection.
- **High Contrast Mode:** When ON, all text elements use maximum contrast (white text on black backgrounds or black text on white backgrounds) and UI borders are thickened to 2px minimum. Intended to assist players with low vision. Applies immediately across all menu screens.
- **Large Text Mode:** When ON, all in-game and menu text scales to 1.5× its base size. Implemented via a `TextScaleContext` provider; all `Text` components in the app consume this context. Applies immediately. Layouts must accommodate the larger text to avoid overflow; where fixed-width containers exist, text truncation with ellipsis (`...`) is the fallback.
- **Button Size:** Normal uses default touch target sizes. Large increases all interactive touch target areas to 1.5× their default dimensions (implemented via padding scaling). Large also slightly increases the visible button element for clarity, but the visual growth is capped at 1.25× to avoid layout breaks. Applies immediately.
- **Screen Reader Hints:** When ON, all interactive React Native elements receive `accessible={true}`, `accessibilityLabel`, and `accessibilityHint` props that describe their purpose. This is the ARIA equivalent for React Native. When OFF, these attributes are omitted for performance. Note: iOS VoiceOver and Android TalkBack operate independently of this toggle and function at the OS level regardless; this toggle controls whether the app provides enhanced semantic labels beyond React Native's defaults.

### 3.5 Controls Settings

**Section label:** CONTROLS

| Setting | Control Type | Options | Default | AsyncStorage Key |
|---|---|---|---|---|
| Joystick Size | Segmented / Radio | Small / Medium / Large | Medium | `settings.controls.joystickSize` |
| Joystick Position | Segmented / Radio | Left / Right | Left | `settings.controls.joystickPosition` |
| Auto-Aim Sensitivity | Segmented / Radio | Off / Low / Medium / High | Medium | `settings.controls.autoAimSensitivity` |

**Behavior rules:**

- **Joystick Size:** Changes the rendered diameter of the virtual joystick thumb control. Small, Medium, and Large correspond to device-independent pixel sizes defined in the Tuning Knobs (§7). The change is read by the HUD layout at match start; it does not resize mid-match.
- **Joystick Position:** Left places the movement joystick on the left side of the screen (default, right-handed); Right swaps movement joystick to the right side and the attack button cluster to the left. Applies at next match start.
- **Auto-Aim Sensitivity:** Controls the snap radius of the auto-aim assist system. Off = no snap. Low/Medium/High correspond to increasing angular snap radii and snap strengths defined in the Combat System GDD. Settings screen stores the label; the Combat system maps labels to numeric values. Applies at next match start.

### 3.6 Notifications Settings

**Section label:** NOTIFICATIONS

| Setting | Control Type | Options | Default | AsyncStorage Key | MVP Status |
|---|---|---|---|---|---|
| Match Reminders | Toggle | On / Off | Off | `settings.notifications.matchReminders` | Stub — stored locally, push not wired |
| Event Alerts | Toggle | On / Off | Off | `settings.notifications.eventAlerts` | Stub — stored locally, push not wired |

**Behavior rules:**

- Both toggles are displayed and interactive (they save their state to AsyncStorage).
- Both show a **(Coming Soon)** label rendered in a muted color directly beneath the toggle row. This label is not a separate item; it is part of the row layout.
- No OS permission prompt is triggered at MVP. No push token registration occurs.
- The values stored here will be consumed by the Push Notification System when it is implemented in VS, via a migration that reads these stored preferences.
- These rows are NOT grayed out or disabled — they are fully interactive. The "(Coming Soon)" label is informational only, signaling that the back-end is not yet connected.

### 3.7 Privacy Settings

**Section label:** PRIVACY

| Setting | Control Type | Label | AsyncStorage Key | Server-Sync |
|---|---|---|---|---|
| Analytics Consent | Toggle | "Share gameplay data to improve BRAWLZONE" | `settings.privacy.analyticsConsent` | Yes — writes to Player Profile via API |

**Behavior rules:**

- This is the only settings toggle that is **not** local-only at MVP.
- On **toggle ON → OFF** (revoking consent):
  1. Write `false` to AsyncStorage immediately (optimistic update).
  2. Call `PATCH /v1/players/me` with body `{ "analyticsConsent": false }`.
  3. If API call succeeds: the Analytics/Telemetry system is notified to begin consent revocation flow as defined in the Analytics GDD. Settings screen takes no further action.
  4. If API call fails: revert the toggle to ON; revert AsyncStorage to `true`; show toast "Could not update privacy settings. Please try again."
- On **toggle OFF → ON** (granting consent):
  1. Write `true` to AsyncStorage immediately (optimistic update).
  2. Call `PATCH /v1/players/me` with body `{ "analyticsConsent": true }`.
  3. If API call fails: revert toggle to OFF; revert AsyncStorage to `false`; show toast "Could not update privacy settings. Please try again."
- The initial state of this toggle is read from the Player Profile (fetched on app launch), not from AsyncStorage, to ensure server truth is always reflected. AsyncStorage is a cache; on conflict, the server value wins.
- No dark patterns: the label plainly states what the data is used for. There is no pre-checked opt-in; the default is determined by the Player Profile GDD's consent default (expected: OFF at account creation).

### 3.8 Account Management

**Section label:** ACCOUNT

This section contains three items:

---

#### 3.8.1 Display Name Change

- Rendered as a tappable list row with the player's current display name shown as a subtitle.
- Label: "Display Name"
- Subtitle: `<current display name>`
- Tapping navigates to the display name rename flow (defined in the Player Profile GDD).
- The 30-day cooldown is enforced by the Player Profile API. If the cooldown is active, the rename flow (not this screen) presents the error. This screen links to the flow regardless.
- After a successful rename, the player returns to the Settings screen and the subtitle updates to the new display name.

---

#### 3.8.2 Log Out

- Rendered as a tappable row with a distinct visual treatment (e.g., amber/warning text color) to differentiate it from passive settings rows.
- Label: "Log Out"
- On tap: display a confirmation modal.

**Log Out Confirmation Modal:**

```
Title:   "Log Out?"
Body:    "Are you sure you want to log out?"
Buttons: [Cancel]  [Log Out]
```

- **Cancel:** dismiss modal, no action.
- **Log Out (confirm):**
  1. Call `supabase.auth.signOut()`.
  2. Clear all AsyncStorage auth tokens (keys: `supabase.auth.token`, `supabase.auth.refreshToken`, or whichever keys the Supabase SDK writes — determined by authentication implementation).
  3. Navigate to the Authentication screen (login/sign-up). The navigation stack is reset so the player cannot press Back to return to the app.
  4. No analytics event is emitted (consent may have been revoked).

---

#### 3.8.3 Delete Account

- Rendered as a tappable row with a distinct visual treatment (destructive styling: red text) to signal permanence.
- Label: "Delete Account"
- On tap: display a confirmation modal.

**Delete Account Confirmation Modal:**

```
Title:   "Delete Account"
Body:    "This will permanently delete your account and all data.
          This cannot be undone."
Input:   Text field — placeholder: "Type DELETE to confirm"
Buttons: [Cancel]  [Delete Account — disabled until input matches]
```

- The **Delete Account** confirm button remains **disabled** until the text field contains exactly the string `DELETE` (case-sensitive, no leading/trailing whitespace).
- **Cancel:** dismiss modal; clear the text field.
- **Delete Account (confirm, after typing "DELETE"):**
  1. Check: is the player currently in an active match? If yes: dismiss delete modal; show toast "Cannot delete account while in a match." No further action.
  2. If not in a match:
     a. Call `DELETE /v1/account`.
     b. On success: call `supabase.auth.signOut()`; clear all AsyncStorage auth tokens; navigate to the Authentication screen (stack reset).
     c. On API failure: show toast "Account deletion failed. Please try again."; keep the modal open (player can retry or cancel).

---

### 3.9 Persistence & Apply Model

**Storage:** All settings except analytics consent are stored in AsyncStorage under the `settings.*` key namespace (see keys listed in each section above). Settings are loaded on app launch before any game screens render (blocking read during splash screen phase). Loading failure (unlikely but possible on first install before any write) falls back silently to all defaults.

**Apply timing:**

| Category | Apply Timing |
|---|---|
| Audio (volume / mute) | Immediate — on every change event |
| Display (FPS counter, reduce motion) | Immediate |
| Display (damage numbers) | Next match |
| Display (brightness override) | Immediate |
| Accessibility (colorblind mode) | Menu UI: immediate; Match HUD: next match |
| Accessibility (high contrast, large text, button size, screen reader hints) | Immediate |
| Controls (all) | Next match |
| Notifications | N/A at MVP |
| Privacy (analytics consent) | Immediate (with API sync) |

**No Save button exists.** Every change is written immediately. If an AsyncStorage write fails, the system shows a toast ("Settings could not be saved") and reverts the UI control to its previous value so the displayed state always matches the stored state.

**Write failure revert pattern:**
1. User changes control (e.g., flips a toggle).
2. New value is optimistically reflected in UI.
3. AsyncStorage write is attempted.
4. If write fails: revert UI control to previous value; show toast.
5. If write succeeds: no further action (no confirmation toast for normal success).

### 3.10 Colorblind Mode Palette Definitions

The following table defines the color remapping applied for each colorblind mode. At MVP, these palettes are **defined and shipped**; full implementation in all match HUD elements is advisory (not a blocking MVP requirement). Menu-side application is required at MVP.

The base palette uses the BRAWLZONE standard game colors. Remapped values use colorblind-safe equivalents widely validated in game accessibility literature.

**Affected UI elements:**
- Player HP bar (green)
- Enemy HP bar (red)
- Allied team indicator (blue)
- Enemy team indicator (orange/red)
- Zone ring (green)
- Status effect icons that use color-only coding (poison = green, burn = red, freeze = blue)

**Palette remapping table (hex values are indicative; final values set by Art Bible):**

| Element | Base Color | Protanopia Remap | Deuteranopia Remap | Tritanopia Remap |
|---|---|---|---|---|
| Player HP bar | `#22C55E` (green) | `#2563EB` (blue) | `#2563EB` (blue) | `#D97706` (amber) |
| Enemy HP bar | `#EF4444` (red) | `#F59E0B` (amber) | `#F59E0B` (amber) | `#DC2626` (red-safe) |
| Allied team indicator | `#3B82F6` (blue) | `#3B82F6` (blue) | `#3B82F6` (blue) | `#F59E0B` (amber) |
| Enemy team indicator | `#F97316` (orange) | `#F59E0B` (amber-yellow) | `#F59E0B` (amber-yellow) | `#A21CAF` (purple) |
| Zone ring | `#22C55E` (green) | `#F59E0B` (amber) | `#F59E0B` (amber) | `#2563EB` (blue) |
| Poison status | `#86EFAC` (light green) | `#93C5FD` (light blue) | `#93C5FD` (light blue) | `#FCD34D` (yellow) |
| Burn status | `#FCA5A5` (light red) | `#FDE68A` (yellow) | `#FDE68A` (yellow) | `#FCA5A5` (light red) |
| Freeze status | `#93C5FD` (light blue) | `#93C5FD` (light blue) | `#BFDBFE` (lighter blue) | `#FDE68A` (yellow) |

**Implementation note:** All palette-dependent components must receive their colors from `ColorblindContext` rather than hardcoded hex values. The context exposes a `getColor(semanticKey)` function. When mode is None, the base color is returned. When a mode is active, the remapped color is returned. The semantic key names correspond to the Element column above (e.g., `"playerHpBar"`, `"zoneRing"`).

---

## 4. Formulas

Settings are discrete selections or bounded sliders. No derived game-balance formulas are required. The acceptable ranges and their interpretations are documented below.

**Audio slider ranges:**

| Slider | Min | Max | Step | Unit | Notes |
|---|---|---|---|---|---|
| Master Volume | 0 | 100 | 1 | Integer percentage | 0 = silence; 100 = maximum output |
| Music Volume | 0 | 100 | 1 | Integer percentage | Relative to master |
| SFX Volume | 0 | 100 | 1 | Integer percentage | Relative to master |

**Effective volume formula (audio engine contract — not computed in this screen):**

```
effectiveChannelVolume = muteAll ? 0 : (channelVolume / 100) × (masterVolume / 100)
```

This is documented here as a contract definition for the audio integration layer, not as a formula this screen implements.

**Display brightness range:**

| Slider | Min | Max | Step | Notes |
|---|---|---|---|---|
| Brightness Level | 0 | 100 | 1 | Integer percentage; mapped to `expo-brightness` 0.0–1.0 float by dividing by 100 |

**Text scale factor (Large Text Mode):** Fixed multiplier of `1.5` applied to all base `fontSize` values via `TextScaleContext`. Not a slider; binary On/Off.

**Button size scale factor (Large Button Size):** Touch target padding scaled by `1.5`; visible element scaled by `1.25`. Not a slider; binary Normal/Large.

**Joystick pixel sizes (device-independent pixels):**

| Size | Diameter (dp) |
|---|---|
| Small | 80 |
| Medium | 110 |
| Large | 140 |

These values are Tuning Knobs (see §7) and may be adjusted without design review.

---

## 5. Edge Cases

### EC-01: AsyncStorage Write Failure

**Trigger:** AsyncStorage.setItem throws or rejects (e.g., device storage full, OS I/O error).

**Response:**
1. Revert the UI control to its previous value immediately.
2. Show a non-blocking toast at the bottom of the screen: *"Settings could not be saved."*
3. Toast auto-dismisses after 3 seconds.
4. No crash; no data corruption. The in-memory state that was successfully changed is also reverted so the displayed state matches what is persisted.

**Does not apply to:** Analytics consent — that toggle has its own revert logic on API failure (§3.7).

---

### EC-02: Analytics Consent Revocation Mid-Session

**Trigger:** Player toggles Analytics Consent from ON to OFF while a match is in progress or events are queued.

**Response:** The Settings screen calls the API to record consent revocation. The Analytics/Telemetry GDD owns all behavior from that point: queue draining, in-flight event cancellation, and future event suppression. Settings does not need to coordinate with the analytics system beyond triggering the revocation. Settings screen behavior is complete once the API call succeeds.

---

### EC-03: Delete Account While in an Active Match

**Trigger:** Player opens Settings (via Main Menu), enters the Delete Account flow, and has an active match running in a background session (e.g., was disconnected from a match and returned to the menu, match not yet marked finished by the server).

**Detection:** Before executing the delete API call, query the local session state (via the Session Manager or Match Flow context) to determine whether a match session is active.

**Response:** Dismiss the delete confirmation modal; show a toast: *"Cannot delete account while in a match."* The player must wait for the match to conclude (or be timed out by the server) before deletion is allowed.

**Note:** If the session state check is unavailable (e.g., Session Manager not initialized), err on the side of allowing deletion — the server-side `DELETE /v1/account` endpoint is responsible for blocking deletions on active match sessions as a server-enforced guard.

---

### EC-04: Display Name Change Within Cooldown

**Trigger:** Player taps the Display Name row and navigates to the rename flow; the 30-day cooldown has not expired.

**Response:** This edge case is handled by the Player Profile rename flow (not by the Settings screen). The Settings screen always allows navigation to the rename flow. The rename flow reads the cooldown status from the Player Profile API and displays: *"You can change your name in X days."* The Settings screen does not need to pre-check the cooldown.

---

### EC-05: Colorblind Mode Change During an Active Match

**Trigger:** Player exits a match mid-game (returns to menu), navigates to Settings, and changes the Colorblind Mode selection. The match is still running server-side (they may rejoin).

**Response:** The new palette selection is written to AsyncStorage immediately and applies to all menu UI immediately. It does **not** hot-swap in the match HUD. If the player rejoins or starts the next match, the new palette is read at match HUD initialization. Mid-match palette hot-swap is deferred — the HUD color system does not subscribe to live context changes during an active match for performance reasons.

---

### EC-06: Settings Not Yet Written (First Launch)

**Trigger:** First app launch on a new install; no AsyncStorage values exist yet.

**Response:** All settings load from their hardcoded default values (see §7 Tuning Knobs and the default columns in §3). This is entirely silent to the player; the defaults represent a playable baseline. Defaults are written to AsyncStorage on first change; they are not pre-written on launch (lazy initialization).

---

### EC-07: Log Out During Pending API Call

**Trigger:** Player initiates log out while the analytics consent toggle is mid-API-call (race condition).

**Response:** The log out flow does not wait for in-flight API calls to complete. `supabase.auth.signOut()` is called immediately on log-out confirmation. Any in-flight PATCH for analytics consent will fail with an auth error; this is acceptable — the account session is ending. The Analytics GDD handles this gracefully.

---

### EC-08: Delete Account API Returns Non-2xx

**Trigger:** `DELETE /v1/account` returns an error (4xx / 5xx).

**Response:** The confirmation modal remains open. A toast is shown: *"Account deletion failed. Please try again."* The player may retry (without re-typing "DELETE" — the text field retains its value) or cancel.

---

## 6. Dependencies

### 6.1 Upstream Dependencies (systems this screen consumes)

| System | Dependency | MVP or VS |
|---|---|---|
| **Authentication** (Supabase) | `supabase.auth.signOut()` for Log Out flow; session state for auth token clearing | MVP |
| **Player Profile API** | `PATCH /v1/players/me` for analytics consent; `DELETE /v1/account` for account deletion; display name read for Account section subtitle; rename flow navigation target | MVP |
| **Session Manager / Match Flow** | Query active match status before Delete Account (to enforce EC-03) | MVP |
| **Push Notification System** | Toggle storage only — no functional dependency at MVP; will consume stored preferences in VS | VS |
| **Remote Config** | Server-sync of settings preferences — deferred entirely to VS; not required at MVP | VS |
| **Analytics/Telemetry GDD** | Consent revocation handoff — Settings triggers revocation; Analytics owns the rest | MVP |

### 6.2 Downstream Dependents (systems that consume what this screen produces)

| System | What It Consumes | When |
|---|---|---|
| **Main Menu** | Display name (read from Player Profile after rename) — reflected in main menu header | After rename, on settings dismiss |
| **Match HUD** | Colorblind mode palette, damage numbers toggle, joystick size/position, auto-aim sensitivity, button size, reduce motion | At match start |
| **Audio Engine** | Master/music/SFX volume values, mute-all state | Continuously (AsyncStorage is source of truth, read on app launch) |
| **Analytics/Telemetry** | `analyticsConsent` field — governs whether events are emitted | On consent state change and on app launch |
| **Push Notification System** | Notification preference toggles stored in AsyncStorage — consumed when push system is implemented (VS) | VS |

---

## 7. Tuning Knobs

All values below are configurable without design review. Changes require an engineer to update the relevant constant file and rebuild. These are not exposed via Remote Config at MVP.

| Knob | Default Value | Unit / Type | Notes |
|---|---|---|---|
| Audio: Master Volume default | 80 | Integer 0–100 | Applied on first launch |
| Audio: Music Volume default | 70 | Integer 0–100 | Applied on first launch |
| Audio: SFX Volume default | 85 | Integer 0–100 | Applied on first launch |
| Audio: Mute All default | Off | Boolean | |
| Audio: Slider update throttle | 50 | Milliseconds | Min interval between live volume updates during drag |
| Joystick size: Small | 80 | dp (device-independent pixels) | |
| Joystick size: Medium | 110 | dp | Default |
| Joystick size: Large | 140 | dp | |
| Joystick position default | Left | Enum (Left / Right) | |
| Auto-aim sensitivity default | Medium | Enum (Off / Low / Medium / High) | |
| Large Text scale factor | 1.5 | Multiplier | Applied to all base font sizes via TextScaleContext |
| Large Button touch target scale | 1.5 | Multiplier | Applied to interactive element padding |
| Large Button visual scale cap | 1.25 | Multiplier | Visual size growth is capped to avoid layout breaks |
| Toast auto-dismiss duration | 3000 | Milliseconds | For "Settings could not be saved" and other non-modal toasts |
| Delete confirm string | `DELETE` | Exact string, case-sensitive | String the player must type to enable delete button |
| Display Brightness default (override) | 80 | Integer 0–100 | Used when brightness override is toggled ON |
| FPS counter default | Off | Boolean | Visible in all builds |
| Reduce Motion default | Off | Boolean | |
| Colorblind Mode default | None | Enum | |
| High Contrast Mode default | Off | Boolean | |
| Large Text Mode default | Off | Boolean | |
| Button Size default | Normal | Enum (Normal / Large) | |
| Screen Reader Hints default | Off | Boolean | |

---

## 8. Acceptance Criteria

Each criterion is independently testable. Pass/fail with no partial credit.

---

### AC-01: Audio Controls — Sliders Apply Immediately

**Given** the player is on the Settings screen, Audio section
**When** they drag the Master Volume slider to value 40
**Then** the audio engine's master channel output is reduced to 40% within 50 ms of the value change

**Given** the player sets Master Volume to 60 and SFX Volume to 50 and then closes and reopens the app
**Then** the sliders display 60 and 50 respectively on the Audio settings screen

---

### AC-02: Audio Controls — Mute All

**Given** the player has Master Volume at 80, Music Volume at 70, SFX Volume at 85
**When** they toggle Mute All ON
**Then** all audio output is silenced; sliders retain their values (80, 70, 85) visually

**When** they toggle Mute All OFF
**Then** audio resumes at the stored slider values without requiring any additional interaction

---

### AC-03: Accessibility — Large Text Mode

**Given** the player toggles Large Text Mode ON
**Then** all visible text in the Settings screen increases to 1.5× its base size immediately (no app restart required)

**Given** Large Text Mode is ON and the player navigates to the Main Menu
**Then** Main Menu text is also displayed at 1.5× base size

---

### AC-04: Accessibility — High Contrast Mode

**Given** the player toggles High Contrast Mode ON
**Then** all text elements in the app switch to maximum contrast (white-on-black or black-on-white as appropriate) immediately

---

### AC-05: Accessibility — Colorblind Mode (Menu UI)

**Given** the player selects Colorblind Mode: Deuteranopia
**Then** all menu UI elements that use color to convey information (HP bars in preview, team color swatches) display using the Deuteranopia remapped palette immediately

**Given** the player selects Colorblind Mode: None
**Then** the base palette is restored immediately

---

### AC-06: Accessibility — Colorblind Mode (Match Apply-On-Next-Match)

**Given** a match is in progress and the player changes the Colorblind Mode setting via the menu
**Then** the match HUD does not change palette during the in-progress match

**Given** the player starts a new match after changing the Colorblind Mode setting
**Then** the new match HUD renders using the updated palette

---

### AC-07: Analytics Consent — API Call on Toggle Change

**Given** the player's analytics consent is currently ON (as read from Player Profile on launch)
**When** the player toggles Analytics Consent OFF
**Then** a `PATCH /v1/players/me` request is sent with body `{ "analyticsConsent": false }` within 500 ms

**Given** the `PATCH /v1/players/me` call returns HTTP 200
**Then** the toggle remains in the OFF position and no error is shown

---

### AC-08: Analytics Consent — API Failure Revert

**Given** the player's analytics consent is currently ON
**When** the player toggles Analytics Consent OFF and the `PATCH /v1/players/me` call returns HTTP 500
**Then** the toggle reverts to the ON position
**And** a toast "Could not update privacy settings. Please try again." is shown

---

### AC-09: Log Out Flow

**Given** the player taps "Log Out"
**Then** a confirmation modal appears with title "Log Out?" and buttons [Cancel] and [Log Out]

**Given** the player taps [Cancel]
**Then** the modal is dismissed and the player remains on the Settings screen

**Given** the player taps [Log Out] in the confirmation modal
**Then** `supabase.auth.signOut()` is called
**And** AsyncStorage auth tokens are cleared
**And** the navigation stack is reset and the player is taken to the Authentication screen
**And** pressing the Back button does not return the player to Settings or any authenticated screen

---

### AC-10: Delete Account — Confirmation Gate

**Given** the player taps "Delete Account"
**Then** a confirmation modal appears with the text "This will permanently delete your account and all data. This cannot be undone." and a text input field

**Given** the text field is empty or contains any string other than "DELETE"
**Then** the [Delete Account] button is disabled and cannot be tapped

**Given** the player types "DELETE" (exact, case-sensitive) in the text field
**Then** the [Delete Account] button becomes enabled

**Given** the player types "delete" (lowercase)
**Then** the [Delete Account] button remains disabled

---

### AC-11: Delete Account — Execution Flow

**Given** the player has typed "DELETE" and taps [Delete Account], and no active match session exists
**Then** `DELETE /v1/account` is called
**And** on HTTP 200: `supabase.auth.signOut()` is called, AsyncStorage auth tokens are cleared, and the player is navigated to the Authentication screen with the stack reset

**Given** `DELETE /v1/account` returns HTTP 500
**Then** the confirmation modal remains open
**And** a toast "Account deletion failed. Please try again." is shown
**And** the text field retains the value "DELETE" (player need not re-type)

---

### AC-12: Delete Account — Blocked During Match

**Given** the player has an active match session
**When** the player completes the Delete Account confirmation (types "DELETE" and taps confirm)
**Then** `DELETE /v1/account` is NOT called
**And** the modal is dismissed
**And** a toast "Cannot delete account while in a match." is shown

---

### AC-13: AsyncStorage Persistence Across App Restarts

**Given** the player sets SFX Volume to 42, enables Colorblind Mode: Protanopia, and sets Button Size to Large
**When** the app is fully closed and relaunched
**Then** on the Settings screen: SFX Volume slider shows 42, Colorblind Mode shows Protanopia selected, Button Size shows Large selected

---

### AC-14: Settings Revert on AsyncStorage Write Failure

**Given** AsyncStorage writes are failing (simulated by mocking `AsyncStorage.setItem` to reject)
**When** the player flips the High Contrast Mode toggle from OFF to ON
**Then** the toggle visually reverts to OFF within 500 ms
**And** a toast "Settings could not be saved." is shown

---

### AC-15: Notification Stubs Display

**Given** the player views the Notifications section
**Then** both "Match Reminders" and "Event Alerts" rows are visible and interactive
**And** each row shows a "(Coming Soon)" label in a muted color
**And** toggling either toggle saves the value to AsyncStorage without triggering any OS permission prompt

---

### AC-16: Screen Reader Hints Toggle

**Given** Screen Reader Hints is toggled ON
**Then** all interactive elements in the Settings screen expose non-empty `accessibilityLabel` and `accessibilityHint` props as verifiable via the React Native accessibility inspector

**Given** Screen Reader Hints is toggled OFF
**Then** interactive elements do not expose the enhanced custom accessibility labels (they may still expose React Native default accessibility behavior)

---

*End of document.*
