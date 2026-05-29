# Main Menu & Navigation — Game Design Document
> **System**: Main Menu & Navigation
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

### Purpose

The Main Menu & Navigation system is the **root hub** of BRAWLZONE. Every player session passes through it: it is the first fully-interactive screen a logged-in player sees, and it is the persistent shell that wraps every top-level feature area of the game.

### Screen Ownership

This system owns or gates the following surfaces:

| Surface | Ownership |
|---|---|
| Root navigator configuration (React Navigation) | Owned |
| Auth navigator (Login / Register screens) | Gated — renders when session is invalid |
| Main tab navigator (4 tabs) | Owned |
| Modal navigator (full-screen overlays) | Owned |
| Persistent header (avatar, name, rank, diamonds) | Owned |
| Bottom nav bar (4 tab icons + badges) | Owned |
| Profile fetch loading screen | Owned |
| Deep link routing entry point | Owned |

This system does **not** own the internal content of the Play, Profile, Shop, or Settings tabs — those are owned by their respective systems. It owns the shell, the navigation transitions, and the conditions under which each tab renders.

### Authentication Gate

The main menu is **strictly gated** behind a valid Supabase session and a successfully fetched player profile. The app boot sequence is:

```
App Launch
  └─ Check Supabase session
       ├─ Invalid/absent session → Auth Navigator (Login/Register)
       └─ Valid session → Fetch player profile (10s timeout)
              ├─ Success → Render Main Tab Navigator
              ├─ Timeout/error → Show branded loading screen + Retry UI
              └─ Session expired during fetch → Auth Navigator + "Session expired" toast
```

No partial renders. No stale data. The player either sees a fully-loaded main menu or a clear loading/error state.

---

## 2. Player Fantasy

### The Feeling

A player opens BRAWLZONE after a day away. The app loads fast. Within two seconds of their session being confirmed, they are standing in their lobby — their avatar and display name in the top-left, their diamond balance glinting in the top-right, their rank badge asserting their place in the competitive ladder. The three mode cards pulse with live queue times. One tap on "Play" and they are in queue.

This is not a menu. It is a **staging area** — the place a fighter goes before stepping into the arena.

### Identity Clarity

The moment the main menu renders, the player knows:
- **Who they are**: display name and avatar visible without scrolling.
- **Where they stand**: rank tier badge (Bronze, Silver, Gold, Diamond, etc.) visible at a glance.
- **What they have**: diamond balance in the persistent header corner, always current.

There is no hunt for this information. It is ambient. The player's identity is the frame around everything else.

### Readiness Path

The path from "app open" to "in queue" must never exceed 3 taps for a returning player:
1. App opens → main menu renders (0 taps needed — it just appears).
2. Play tab is default — mode cards are already visible.
3. Player taps "Play" on their preferred mode → in queue.

The menu does not demand attention. It offers a clear, obvious next action at every moment.

### Live-Service Feel

Even at MVP, the main menu should feel **alive**:
- Mode cards show real-time queue estimates from the Matchmaking Engine.
- Notification badges appear on tab icons when there is something worth the player's attention.
- Transitions between tabs are fluid, not jarring — consistent easing, no layout flicker.

The polish of the navigation shell signals to the player that this is a maintained, cared-for product.

---

## 3. Detailed Rules

### 3.1 Navigation Stack Structure (React Navigation)

The app uses React Navigation with the following navigator hierarchy:

```
RootNavigator (Stack)
  ├─ AuthNavigator (Stack)                  [when session invalid]
  │    ├─ LoginScreen
  │    └─ RegisterScreen
  ├─ LoadingScreen                          [during profile fetch]
  └─ MainTabNavigator (Bottom Tab)          [when session valid + profile loaded]
       ├─ Tab: Play       → PlayScreen (Stack)
       │    └─ ModeSelectScreen             [default]
       ├─ Tab: Profile    → ProfileScreen (Stack)
       │    └─ ProfileHomeScreen            [default]
       ├─ Tab: Shop       → ShopScreen (Stack)
       │    └─ ShopHomeScreen               [default, stub at MVP]
       └─ Tab: Settings   → SettingsScreen (Stack)
            └─ SettingsHomeScreen           [default]

ModalNavigator (Stack, presented over MainTabNavigator)
  ├─ ComingSoonModal                        [used for unimplemented features]
  ├─ SessionExpiredModal                    [force-logout overlay]
  └─ RetryProfileModal                      [profile fetch failure]
```

**Navigator naming conventions (PascalCase, as required):**
All screen components are named in PascalCase: `LoginScreen`, `PlayScreen`, `ModeSelectScreen`, `ProfileScreen`, `ShopScreen`, `SettingsScreen`, `ComingSoonModal`, `SessionExpiredModal`, `RetryProfileModal`, `LoadingScreen`.

**Tab ordering (left to right):** Play | Profile | Shop | Settings.

The Play tab is the **initial route** of `MainTabNavigator`.

### 3.2 Authentication Gate

#### Boot Sequence Detail

1. App launches → `RootNavigator` mounts.
2. `RootNavigator` calls `supabase.auth.getSession()` asynchronously.
3. While the session check is pending, a **splash/branding screen** is shown (this is the OS-level splash, not a React screen — keep it consistent with app branding).
4. **If session is invalid or absent:**
   - Navigate to `AuthNavigator` → `LoginScreen`.
   - No profile fetch is attempted.
5. **If session is valid:**
   - Navigate to `LoadingScreen` (branded, with app logo and a progress indicator).
   - Begin player profile fetch (see Section 3.3).
6. On successful login via `AuthNavigator`:
   - Begin player profile fetch → navigate to `LoadingScreen` → then `MainTabNavigator`.
7. On successful registration via `AuthNavigator`:
   - Create profile → begin profile fetch → navigate to `LoadingScreen` → then `MainTabNavigator`.

#### Session Persistence

Supabase session tokens are persisted in device secure storage (via `@supabase/supabase-js` with `AsyncStorage` adapter for React Native). On app re-open, the session is restored automatically if not expired.

### 3.3 Profile Fetch Gate

The main menu (`MainTabNavigator`) **must not render** until the player profile is fully loaded. This prevents partially-hydrated UI (e.g., empty display name, zero diamond balance) from ever being visible.

#### Profile Fetch Flow

```
LoadingScreen mounts
  └─ Dispatch: fetchPlayerProfile(userId)
       ├─ Success (profile arrives within timeout)
       │    └─ Navigate to MainTabNavigator (initial tab: Play)
       ├─ Timeout (10 000ms elapsed, no response)
       │    └─ Show RetryProfileModal on LoadingScreen
       │         ├─ "Retry" tapped → repeat fetch (reset timer)
       │         └─ "Log Out" tapped → clear session → navigate to AuthNavigator
       └─ Network/server error (non-timeout failure)
            └─ Same as Timeout path above
```

**LoadingScreen design:**
- App logo centered.
- Subtle animated progress indicator (not a spinner that implies "almost done" — use a pulsing logo or indeterminate bar).
- No numeric countdown shown to the player.
- After timeout, the progress indicator stops and `RetryProfileModal` content appears inline (no separate modal navigation required for MVP — can be an in-screen state change).

**No stale data rule:** If a previous profile fetch result exists in local state (e.g., from a previous session in the same app process), it must not be displayed. Always re-fetch on session validation.

### 3.4 Main Menu Layout

The main menu is the content of the **Play tab** as the default landing screen. The persistent header and bottom nav bar are present on all tabs.

#### Persistent Header (all tabs)

The persistent header is rendered by `MainTabNavigator` and overlays all tab content from the top. It respects safe area insets (notch/status bar on iOS; status bar on Android).

| Element | Position | Behavior |
|---|---|---|
| Player avatar (thumbnail) | Top-left | Tappable → navigates to Profile tab |
| Display name | Top-left, next to avatar | Truncated at 16 characters with ellipsis |
| Rank tier badge | Below display name | Shows tier icon + tier name (e.g., "Gold II") |
| Diamond balance | Top-right | Always current; updates live when balance changes |
| Notification bell (MVP stub) | Top-right, left of diamonds | Badge dot when unread; tappable (no-op at MVP) |

**Safe area requirement:** Header top padding = `insets.top` (from `useSafeAreaInsets()`). This must be applied on both iOS (notch devices) and Android (status bar). Tested device matrix: iPhone 15 Pro (Dynamic Island), iPhone SE 3rd gen, Pixel 7, Samsung Galaxy S24.

#### Bottom Nav Bar (all tabs)

The bottom nav bar is rendered by React Navigation's `createBottomTabNavigator`. It respects safe area insets (home indicator on iPhone, navigation bar on Android).

| Tab | Icon | Badge Logic |
|---|---|---|
| Play | sword/fist icon | No badge at MVP |
| Profile | person icon | Red dot if unread progression events |
| Shop | diamond/store icon | Red dot if unclaimed shop offer |
| Settings | gear icon | No badge |

Active tab: icon + label both use brand accent color. Inactive tabs: muted/secondary color.

**Bottom safe area requirement:** Tab bar bottom padding = `insets.bottom`. Tested on iPhone 15 Pro (home indicator) and Android devices with gesture navigation.

#### Play Tab Content (ModeSelectScreen)

Three mode cards displayed vertically (scroll if needed, though 3 cards should fit on all target viewports without scrolling at MVP).

**Mode card anatomy:**

```
┌─────────────────────────────────┐
│  [Mode Icon]   Mode Name        │
│                Player Range     │
│                Est. Queue: ~Xs  │
│                [PLAY button]    │
└─────────────────────────────────┘
```

| Mode | Player Range | Icon |
|---|---|---|
| Duel | 1v1 | sword-crossed icon |
| Squad Brawl | 3v3 | group icon |
| Free-For-All | 8 players | crown/chaos icon |

**Play button:** Full-width CTA within the card. On tap: transition to queue entry (owned by Matchmaking system — this system only handles the navigation call).

### 3.5 Queue Time Estimate Display

Queue time estimates are fetched from the Matchmaking Engine and polled while the player is on the Play tab (polling interval: see Section 7 — Tuning Knobs).

| Condition | Display Text |
|---|---|
| Estimate < 60 seconds | `~Xs` (e.g., `~12s`, `~45s`) |
| Estimate ≥ 60 seconds | `>1 min` |
| Player is in queue for this mode | `Searching...` |
| Estimate unavailable / fetch failed | `--` (en-dash, no error state shown) |
| Matchmaking Engine unreachable | `--` on all cards; no toast/error |

Queue time text is **not** the primary call-to-action. It is supporting context. The Play button is always tappable regardless of queue time estimate state.

### 3.6 Deep Link Handling

Push notifications and external links may deep-link the player directly to a specific screen. The deep link routing logic lives in `RootNavigator`.

#### Deep Link Flow

```
Push notification / external URL received
  └─ App brought to foreground (or cold-launched)
       └─ RootNavigator intercepts link
            ├─ Session valid + profile loaded → navigate to target screen
            ├─ Session valid, profile not yet loaded → load profile, then navigate
            └─ Session invalid → navigate to AuthNavigator
                  └─ On login success → navigate to original deep link target
```

**Deep link target is stored** (pending navigation target) when auth is required. After successful login, the pending target is consumed and navigation occurs. The pending target is cleared on logout.

**Supported deep link schemes at MVP:**

| Link Target | Route |
|---|---|
| `brawlzone://play` | Play tab, ModeSelectScreen |
| `brawlzone://profile` | Profile tab |
| `brawlzone://shop` | Shop tab |
| `brawlzone://settings` | Settings tab |

Universal links (HTTPS) follow the same routing logic via React Navigation's linking configuration.

### 3.7 Badge System

Badges are red dot indicators on tab bar icons. They are **not** numeric counters at MVP (just presence/absence).

| Badge | Tab | Trigger | Dismiss |
|---|---|---|---|
| Shop offer badge | Shop | Unclaimed offer exists in player's shop state | Viewing the Shop tab clears it |
| Profile progression badge | Profile | Unread progression event (level-up, achievement) | Viewing the Profile tab clears it |

**Badge freshness:** Badges are checked on:
1. App foreground event (app returns from background).
2. Periodic interval while app is active (see Section 7).
3. After any action that could generate a new badge trigger (e.g., completing a match).

Badges are stored in local React state (not persisted to disk at MVP). On cold launch, badge state is fetched as part of the profile fetch.

### 3.8 Back Navigation

**Android hardware back button:**
- On any tab within `MainTabNavigator`: pressing back does **nothing** (the main menu is the navigation floor; pressing back from here would background the app, which is default Android behavior — this is acceptable).
- On a modal (e.g., `ComingSoonModal`): back button dismisses the modal.
- On a screen nested inside a tab stack (future screens, not MVP): back button pops to the tab root.

**iOS swipe-back gesture:**
- Swipe-back is **disabled** on the `MainTabNavigator` itself (cannot swipe back to auth screens).
- Swipe-back is **enabled** for screens nested within tab stacks where appropriate.

**Implementation note:** Use `gestureEnabled: false` on `MainTabNavigator`'s stack entry in `RootNavigator`. Use `headerShown: false` with manual back button implementation on screens where custom back behavior is needed.

### 3.9 Session Expiry While Active

A Supabase session may expire while the player is actively using the main menu (e.g., app left open overnight).

**Detection:** Subscribe to `supabase.auth.onAuthStateChange()` in `RootNavigator`. On `SIGNED_OUT` or `TOKEN_REFRESH_FAILED` event:

1. Immediately clear all local player state (profile, diamond balance, etc.).
2. Navigate to `AuthNavigator` → `LoginScreen`.
3. Display a toast notification: **"Session expired, please log in again."**
4. Toast duration: 4 seconds. Non-blocking (player can interact with login form while toast is visible).

**No data leak:** After logout navigation, ensure all sensitive player state (display name, balance, etc.) is cleared from React context/Redux store before the auth screens render.

---

## 4. Formulas

### 4.1 Profile Fetch Timeout

```
PROFILE_FETCH_TIMEOUT_MS = 10_000   // 10 seconds
```

If the profile API call does not resolve within `PROFILE_FETCH_TIMEOUT_MS`, the fetch is considered failed. The `LoadingScreen` transitions to retry state.

On retry, the timer resets to `PROFILE_FETCH_TIMEOUT_MS` from the moment the retry is initiated.

### 4.2 Badge Freshness Check Interval

```
BADGE_POLL_INTERVAL_MS = 60_000     // 60 seconds (while app is active)
```

Badges are re-fetched every `BADGE_POLL_INTERVAL_MS` while the app is in the foreground. When the app is backgrounded, polling stops. Polling resumes on foreground with an immediate fetch (no waiting for next interval).

### 4.3 Queue Time Display Thresholds

```
QUEUE_TIME_SHORT_THRESHOLD_S = 60   // seconds; below this: show "~Xs"
                                     // at or above: show ">1 min"
```

Queue time values are integers (seconds). Display rounding: show the raw value as returned by the Matchmaking Engine (no client-side rounding). If the engine returns `0`, display `~0s` (edge case, acceptable at MVP).

### 4.4 Queue Time Poll Interval

```
QUEUE_TIME_POLL_INTERVAL_MS = 15_000  // 15 seconds, while Play tab is active
```

Queue time estimates are only polled when the Play tab is the active tab. Polling pauses when the player navigates to another tab or backgrounds the app.

### 4.5 Loading Screen Minimum Display Duration

```
LOADING_SCREEN_MIN_DURATION_MS = 800  // milliseconds
```

Even if the profile fetch completes in < 800ms, the `LoadingScreen` is shown for at least `LOADING_SCREEN_MIN_DURATION_MS` to prevent a jarring flash of the loading state. This is a UX smoothing measure, not a hard requirement — it can be reduced to 0 if performance testing shows the transition is smooth without it.

---

## 5. Edge Cases

### EC-001: Profile Fetch Timeout

**Scenario:** Player has a valid session, but the profile API is slow or unreachable.

**Behavior:**
1. `LoadingScreen` shows branded animation for up to `PROFILE_FETCH_TIMEOUT_MS` (10s).
2. On timeout: progress animation stops; inline retry UI appears: message "Couldn't load your profile" + "Retry" button + "Log Out" button.
3. The screen does **not** go blank. The app logo remains visible at all times.
4. "Retry" resets the timer and re-attempts the fetch.
5. "Log Out" clears the session and navigates to `AuthNavigator`.

**What must NOT happen:** The main menu must never render with empty or zeroed profile data. No silent failure.

### EC-002: Supabase Session Expires Mid-Session

**Scenario:** Player is actively using the main menu when their Supabase token expires (e.g., after a very long session or a token refresh failure).

**Behavior:**
1. `onAuthStateChange` fires `SIGNED_OUT` or `TOKEN_REFRESH_FAILED`.
2. All player state is cleared immediately (synchronously before navigation).
3. Navigation transitions to `AuthNavigator` → `LoginScreen`.
4. Toast shown: "Session expired, please log in again." (4s duration).

**What must NOT happen:** Player must never remain on main menu tabs with a dead session. No silent session expiry. No stale player data visible on auth screens.

### EC-003: Deep Link Requires Auth

**Scenario:** Player taps a push notification deep link (`brawlzone://shop`) but is not logged in (cold launch with no session, or session expired).

**Behavior:**
1. Deep link target (`shop`) is stored as pending navigation target.
2. App routes to `AuthNavigator` → `LoginScreen`.
3. Player logs in successfully.
4. On login success, pending navigation target is consumed: navigate to Shop tab.
5. If player registers instead of logging in, same pending target consumption applies.

**What must NOT happen:** Deep link target must not be lost. Player must not land on Play tab after logging in from a Shop deep link.

### EC-004: Shop Tab Tapped at MVP (Unimplemented)

**Scenario:** Player taps the Shop tab. Shop is stubbed at MVP — it is not functional.

**Behavior:**
1. Navigation proceeds normally to the Shop tab (no blocking at the nav level).
2. `ShopHomeScreen` renders a `ComingSoonModal` or an in-screen "Coming Soon" placeholder with:
   - App/mode artwork as background.
   - Text: "Shop — Coming Soon"
   - Subtext: "Diamonds, skins, and the Play Pass are on the way."
   - "Back to Play" button that navigates to the Play tab.
3. Badge on Shop tab is suppressed while Shop is in "Coming Soon" state (no point surfacing a badge for a non-functional screen).

**What must NOT happen:** A blank white screen. An unhandled navigation error. The app crashing on Shop tab tap.

### EC-005: Diamond Balance Updates While on Another Tab

**Scenario:** Player receives a diamond balance update (e.g., from a background server push or after a match completes) while they are on the Profile or Settings tab.

**Behavior:**
1. Diamond balance in the persistent header updates silently (state update triggers re-render of header component only).
2. No navigation occurs. No toast. No interruption.
3. The updated balance is visible the moment the player glances at the header — they do not need to return to the Play tab or refresh.

**What must NOT happen:** Diamond balance update triggers a full re-render of the active tab content. Navigation to another tab occurs automatically.

### EC-006: App Backgrounded and Foregrounded (Session Still Valid)

**Scenario:** Player backgrounds BRAWLZONE for < session expiry duration and returns.

**Behavior:**
1. App resumes on the tab it was left on (React Navigation preserves state).
2. Badge freshness check fires immediately on foreground.
3. Queue time estimates re-poll if Play tab is active.
4. No loading screen shown (profile is already in memory).

**What must NOT happen:** App returns to `LoadingScreen` unnecessarily. Player is kicked to the Play tab from wherever they were.

### EC-007: Network Offline at Launch

**Scenario:** Player launches the app with no network connectivity.

**Behavior:**
1. Session check: Supabase local session may be available (cached by Supabase client). If so, session is considered valid locally.
2. Profile fetch: fails (network error, not timeout). `LoadingScreen` shows retry UI immediately (not after 10s — network error is detected faster than timeout).
3. Retry UI: same as EC-001. Player can retry once connectivity is restored.

**What must NOT happen:** App hangs for 10 full seconds on a detectable network-offline condition. (Implementation note: use `NetInfo` from `@react-native-community/netinfo` to detect offline state and fail fast.)

---

## 6. Dependencies

### 6.1 Upstream Dependencies (this system consumes)

| System | What This System Needs | Failure Mode Handled By |
|---|---|---|
| **Authentication** (Supabase) | Valid session token; `onAuthStateChange` event stream; `getSession()` on launch | Auth gate: routes to `AuthNavigator` if session absent/invalid |
| **Player Profile** | `GET /player/profile/{userId}`: display name, avatar URL, MMR, rank tier, diamond balance, badge state | Profile fetch gate: `LoadingScreen` + retry UI on failure |
| **Matchmaking Engine** | Queue time estimates per mode: `GET /matchmaking/queue-times` | Graceful degradation: shows `--` if unavailable; does not block navigation |
| **Push Notification Service** | Deep link payloads on notification tap; background notification handling | Deep link routing: auth-first if session invalid; pending target preserved |

### 6.2 Downstream Consumers (systems that rely on this system)

| System | What It Needs From Main Menu |
|---|---|
| **Lobby / Queue** (Play tab) | Navigation entry point from mode card "Play" button; queue state propagated back to mode cards for "Searching..." display |
| **Profile Screen** | Mounted inside Profile tab stack; receives no props from main menu (uses shared auth context) |
| **Shop Screen** | Mounted inside Shop tab stack; badge state managed by main menu badge system |
| **Settings Screen** | Mounted inside Settings tab stack; logout action in Settings triggers session expiry flow owned by main menu |
| **All future screens** | All new top-level features must register in `MainTabNavigator` or `ModalNavigator`; deep link routes must be registered in `RootNavigator` linking config |

### 6.3 Shared Context / State

The following are provided by `MainTabNavigator`'s React context (or equivalent state management layer) and consumed by child screens:

- `playerProfile` — full profile object (read-only for child screens at MVP)
- `diamondBalance` — live-updated balance (separate from profile for update frequency)
- `sessionStatus` — `'active' | 'expired' | 'loading'`
- `badgeState` — `{ shop: boolean, profile: boolean }`

---

## 7. Tuning Knobs

These values are defined as named constants in a central `config/navigation.ts` (or equivalent) file. They must **not** be hardcoded inline. Changing them requires only a single edit to the config file.

| Knob | Constant Name | Default Value | Effect of Increasing | Effect of Decreasing |
|---|---|---|---|---|
| Profile fetch timeout | `PROFILE_FETCH_TIMEOUT_MS` | 10 000 ms | Player waits longer before seeing retry UI; better for slow networks | Player sees retry UI sooner; may false-positive on fast-but-slow-starting servers |
| Badge freshness interval | `BADGE_POLL_INTERVAL_MS` | 60 000 ms | Badges may be stale longer; less server load | More up-to-date badges; more frequent API calls |
| Queue time poll interval | `QUEUE_TIME_POLL_INTERVAL_MS` | 15 000 ms | Queue time estimates are less current | More current estimates; more Matchmaking Engine calls |
| Loading screen minimum duration | `LOADING_SCREEN_MIN_DURATION_MS` | 800 ms | Loading screen flash is never jarring; logo always visible briefly | May allow visual flash of loading → content transition |
| Queue time short threshold | `QUEUE_TIME_SHORT_THRESHOLD_S` | 60 s | More estimates shown as ">1 min" rather than "~Xs" | More estimates shown as "~Xs"; `>1 min` only for very long queues |
| Session expiry toast duration | `SESSION_EXPIRED_TOAST_DURATION_MS` | 4 000 ms | Toast stays on screen longer | Toast dismisses faster; player may not read it |

---

## 8. Acceptance Criteria

All criteria use Given/When/Then format. All criteria must pass on both iOS (iPhone 15 Pro) and Android (Pixel 7) before the system is marked Done.

---

### AC-001: Authentication Gate — No Session

**Given** the app is launched cold with no Supabase session stored  
**When** `RootNavigator` mounts and `getSession()` returns null  
**Then** the `AuthNavigator` is rendered with `LoginScreen` as the initial route, and no profile fetch is initiated, and no main menu content is visible

---

### AC-002: Authentication Gate — Valid Session

**Given** the app is launched with a valid, non-expired Supabase session  
**When** `RootNavigator` mounts and `getSession()` returns a valid session  
**Then** `LoadingScreen` is shown immediately (not `AuthNavigator`), and a player profile fetch is dispatched within 200ms of session confirmation

---

### AC-003: Profile Fetch Gate — Success

**Given** a valid session and a responsive player profile API  
**When** the profile fetch returns successfully within 10 seconds  
**Then** `MainTabNavigator` renders with the Play tab as the active tab, displaying the player's correct display name, avatar, rank badge, and diamond balance in the persistent header

---

### AC-004: Profile Fetch Gate — Timeout

**Given** a valid session and a player profile API that does not respond  
**When** 10 000ms elapses without a profile response  
**Then** `LoadingScreen` remains visible (no blank screen), retry UI appears with "Retry" and "Log Out" options, and `MainTabNavigator` is not rendered

---

### AC-005: Profile Fetch Gate — Retry Success

**Given** the retry UI is shown after a profile fetch timeout  
**When** the player taps "Retry" and the profile API responds successfully within 10 seconds  
**Then** `MainTabNavigator` renders normally as per AC-003

---

### AC-006: Navigation — All Four Tabs Reachable

**Given** the player is on the main menu (any tab)  
**When** the player taps each of the four bottom nav bar icons in sequence (Play, Profile, Shop, Settings)  
**Then** each corresponding tab content screen renders without error, the active tab icon is highlighted, and no navigation error or blank screen occurs

---

### AC-007: Navigation — Play Tab Is Default

**Given** the player completes authentication and the profile fetch succeeds  
**When** `MainTabNavigator` renders for the first time in the session  
**Then** the Play tab is the active tab and `ModeSelectScreen` is displayed with three mode cards

---

### AC-008: Deep Link — Authenticated Player

**Given** the player is logged in with a loaded profile  
**When** a deep link `brawlzone://shop` is received (e.g., from a push notification)  
**Then** the app navigates to the Shop tab without requiring re-authentication, and the Shop tab is the active tab

---

### AC-009: Deep Link — Unauthenticated Player

**Given** the player is not logged in (no session)  
**When** a deep link `brawlzone://profile` is received via a push notification that cold-launches the app  
**Then** `AuthNavigator` → `LoginScreen` is shown, and after successful login, the app navigates to the Profile tab (not the default Play tab)

---

### AC-010: Session Expiry Mid-Session

**Given** the player is actively on the Profile tab  
**When** `supabase.auth.onAuthStateChange` fires a `SIGNED_OUT` event  
**Then** all player state is cleared, the app navigates to `AuthNavigator` → `LoginScreen`, and a toast with the text "Session expired, please log in again" is displayed for approximately 4 seconds

---

### AC-011: Badge Display — Shop Tab

**Given** the player's shop state contains an unclaimed offer  
**When** `MainTabNavigator` renders or badge state is refreshed  
**Then** a red dot badge is visible on the Shop tab icon, and the badge is not visible on any other tab icon as a result of this trigger

---

### AC-012: Badge Dismiss — Shop Tab

**Given** a red dot badge is visible on the Shop tab icon  
**When** the player taps the Shop tab (tab becomes active)  
**Then** the red dot badge on the Shop tab icon is dismissed (removed) within one render cycle

---

### AC-013: Diamond Balance Live Update

**Given** the player is on the Settings tab  
**When** the player's diamond balance is updated in the shared state (e.g., after a simulated purchase or match reward)  
**Then** the diamond balance in the persistent header updates to the new value without navigating away from Settings and without a full-screen reload

---

### AC-014: Shop Tab — Coming Soon State

**Given** the Shop is in "Coming Soon" MVP stub state  
**When** the player taps the Shop tab  
**Then** a "Coming Soon" screen or modal renders with explanatory text and a "Back to Play" action, and no blank screen or crash occurs

---

### AC-015: Back Navigation — Cannot Return to Auth Screens

**Given** the player is on the main menu (any tab)  
**When** the Android hardware back button is pressed (or equivalent back gesture)  
**Then** the app does not navigate to `AuthNavigator` or any auth screen; the app either remains on the current tab or backgrounds normally

---

### AC-016: Safe Area Insets — Persistent Header

**Given** the app is running on an iPhone 15 Pro (Dynamic Island notch) and a Pixel 7 (status bar)  
**When** `MainTabNavigator` renders  
**Then** the persistent header top edge clears the notch/Dynamic Island on iOS and the status bar on Android, with no UI elements obscured by system chrome

---

### AC-017: Safe Area Insets — Bottom Nav Bar

**Given** the app is running on an iPhone 15 Pro (home indicator) and a Pixel 7 (gesture navigation bar)  
**When** `MainTabNavigator` renders  
**Then** the bottom nav bar bottom edge clears the home indicator on iOS and the gesture navigation bar on Android, with no tab icons obscured

---

### AC-018: Queue Time Display — Short Queue

**Given** the Play tab is active and the Matchmaking Engine returns an estimate of 23 seconds for Duel mode  
**When** the mode cards render  
**Then** the Duel mode card displays "~23s" (not ">1 min", not "23 seconds", not "0:23")

---

### AC-019: Queue Time Display — Long Queue

**Given** the Play tab is active and the Matchmaking Engine returns an estimate of 90 seconds for FFA mode  
**When** the mode cards render  
**Then** the FFA mode card displays ">1 min"

---

### AC-020: Queue Time Display — Engine Unreachable

**Given** the Play tab is active and the Matchmaking Engine API is unreachable  
**When** the queue time fetch fails  
**Then** all three mode cards display "--" for queue time, the Play buttons remain tappable, and no error toast or blocking UI is shown

---

*End of document.*
