# UX Spec: Main Navigation Shell

> **Status**: Complete — all sections drafted, Cross-Reference Check done (1 real conflict found + resolved: Seed Badge tap-to-navigate contradicted `hud.md`'s display-only-at-MVP decision; `seed-buffer.md` corrected). `/ux-review` 2026-07-18: NEEDS REVISION (2 blocking + 3 advisory) → all fixed inline → APPROVED.
> **Author**: User + ux-designer
> **Last Updated**: 2026-07-18
> **Journey Phase(s)**: unknown — no `design/player-journey.md` yet
> **Platform Target**: Mobile (iOS + Android), Touch only — from `technical-preferences.md`
> **Template**: UX Spec

---

## Purpose & Player Need

The Main Navigation Shell is the structural skeleton every screen lives inside — it reads session state and renders the correct UI tree for whichever actor (child or parent) is using the device. The child (6–10) arrives wanting to get where they're going without reading: three big icons, no instructions needed — *"Đây là thế giới của mình — mình biết đi đâu."* The parent arrives wanting a fast, low-distraction way to see what needs approving — *"Đơn giản. Tôi biết mình cần làm gì."* If this screen didn't exist or was hard to use, the two experiences would bleed into each other: a child could stumble into the Parent Dashboard, or a parent would have to navigate a colorful game UI to do a 30-second bedtime task. The shell's entire purpose is keeping those two worlds structurally separate while giving each actor an instantly legible way to move around their own world.

---

## Player Context on Arrival

The child encounters this shell constantly — it's the persistent wrapper for the entire session after PIN entry succeeds, every single app open (the daily ritual). They arrive having just typed the correct PIN on Child Selector; emotional state is calm/curious, sometimes anticipatory (e.g. after submitting a task, waiting to see if it's been approved). Never time-pressured — no timers anywhere in this shell.

The parent encounters it after logging in (email/password), or by long-pressing the Profile chip from inside an active child session (Parent Override). Arrival is either routine (checking in before bed) or prompted by a push notification about a pending task. Emotional state: efficiency-focused — the GDD's own framing is a "30-second routine before bed," so the parent shell must never make them hunt for anything.

Both actors always arrive **voluntarily** in the sense that a real action triggered entry (PIN success, login success, override toggle) — the shell is never something either actor is dropped into without having just done something that means "enter this world now."

---

## Navigation Position

This screen lives at: **[root]** — the Main Navigation Shell is not nested inside anything; it *is* the root `GoRouter` widget wrapping the entire app (GDD Core Rule 1). Every other screen lives *inside* one of its two branches (Child tree: Pet Room / Tasks / Shop, or Parent tree: Dashboard / Gia đình). There is no "reaching" the shell from elsewhere in the normal navigation sense — which branch (and which tab within it) is shown is derived entirely from `sessionStateProvider`, not from any screen-level navigation action. The closest thing to "arriving at the shell" is the moment `sessionStateProvider` flips to `childSelected` or `parentView`, at which point the shell is already there, just rendering a different branch.

---

## Entry & Exit Points

**Entry:**

| Entry Source | Trigger | Player carries |
|---|---|---|
| Login screen | Correct email/password | `parentId` scope, session → `parentAuthed` |
| Child Selector | Correct PIN entered | `childId` scope, session → `childSelected` |
| Profile chip long-press (from an active child session) | Parent password confirmed in bottom sheet | `parentOverrideProvider = true`, session → `parentView`, child session preserved underneath, untouched |
| Deep link (e.g. push notification tap) | FCM notification tap | Intended target route; routed through the auth guard first if session is `unauthenticated` |

**Exit:**

| Exit Destination | Trigger | Notes |
|---|---|---|
| Login screen | Session → `unauthenticated` (token expires, at any point, on any screen) | Immediate redirect, no flash, no confirmation — any unsaved sub-screen draft is lost (acceptable per GDD Edge Cases) |
| App exit (OS) | Back-press on a **Child** tab root screen | Kid-styled confirm dialog first ("Thoát PetQuest?") — only from tab roots, not sub-screens |
| App exit (OS) | Back-press on a **Parent** tab root screen, NOT in override | Direct exit, no confirmation dialog (adult tone — a kid-styled dialog would be wrong here) |
| Child session (Pet Room) | Back-press on Parent tab root **while in override** (`parentView`) | `parentOverrideProvider = false`, NOT app exit — child session was never disposed underneath |
| Child session (Pet Room) | "Xong"/"Quay lại" tap on Parent Dashboard **while in override** | Same as above — no re-PIN needed, session is fully intact |

None of these exits are one-way/destructive except the token-expiry redirect, which can lose an in-progress sub-screen draft (explicitly accepted by the GDD as harmless).

---

## Layout Specification

### Information Hierarchy

This shell's own owned elements (screen content itself belongs to the hosted screens, not this shell):

**Child shell**, ranked by what a child needs to see first:
1. **Bottom nav tabs** — the entire point of this screen; always visible, largest touch targets
2. **Contextual badge chip** (when present) — signals "something is waiting" (a seed about to bloom, a chest to open); should catch the eye when it appears
3. **Xu chip** — persistent wealth display, glanceable but not urgent
4. **Profile chip** — mostly just confirms "this is me"; its long-press-to-parent-mode function is a *hidden* action, not something a child needs to notice

**Parent shell**, ranked:
1. **Bottom nav tabs** (2 tabs: Nhiệm vụ, Gia đình) — same top priority, professional tone
2. No floating chips on the parent side — the GDD specifies none; parent screen content (task cards) is owned by Parent Dashboard UI (#21), not this shell

### Layout Zones

This part isn't an open choice — `hud.md` already made this decision (Approved, "Chosen arrangement: Floating chip cluster"). Adopted directly rather than re-litigated here:

**Child shell:**
- **Top-left**: chip cluster — Profile chip + Xu chip, two adjacent floating pills (never fused into one bar)
- **Top-right**: Contextual badge chip — floating pill, Seed or Chest icon+count, only rendered when its bound count > 0 (removed from layout entirely at 0, not just hidden)
- **Bottom**: persistent Child bottom nav bar (3 tabs), Material 3 `NavigationBar`
- **Center**: fully clear — hosts whatever the active tab's screen renders

**Parent shell:**
- **Top**: nothing — no floating chips on the parent side (GDD specifies none)
- **Bottom**: persistent Parent bottom nav bar (2 tabs), Material 3 `NavigationBar`, Navy-toned, more subdued
- **Center**: fully clear — hosts Dashboard / Gia đình content

### Component Inventory

| Zone | Component | Content | Interactive? | Pattern |
|---|---|---|---|---|
| Child: bottom | Bottom nav bar (3 tabs) | Icon 28dp + minimal label 11sp per tab (Nhà/Nhiệm vụ/Shop) | Yes — tap switches tab | **P13** (Bottom-nav tab shell) |
| Child: top-left cluster | Profile chip | Avatar 32dp circle + child name, bold 16sp | Yes — but only via **long-press ≥600ms** (not tap) | **P16** (Long-press to enter privileged mode) |
| Child: top-left cluster | Xu chip | Xu icon 18dp + balance, 14sp Honey Gold | No — display-only | **P12** (Reactive counter/wallet display); full visual/animation owned by `hud.md` |
| Child: top-right | Contextual badge chip | Seed 🌱 or Chest 🎁 icon + count; exactly one binding active per screen | **No — display-only at MVP** (resolved 2026-07-17 — see Open Questions / seed-buffer.md sync) | Full visual/animation owned by `hud.md` |
| Child: overlay | Exit confirm dialog ("Thoát PetQuest?") | Kid-styled `AlertDialog`, [Ở lại] / [Thoát] | Yes — triggered by back-press on a Child tab root | **P17** (Disruption-not-destruction confirm dialog) |
| Child: overlay | Switch-mode bottom sheet ("Chuyển sang tài khoản bố/mẹ?") | Confirm prompt → parent password field → confirm/cancel | Yes — triggered by Profile chip long-press | **P3** (Inline bottom sheet) for the sheet mechanic; password flow is this GDD's own |
| Parent: bottom | Bottom nav bar (2 tabs) | Icon 24dp + label 12sp per tab (Nhiệm vụ/Gia đình), Navy-toned | Yes — tap switches tab | **P13** (Bottom-nav tab shell) |

### ASCII Wireframe

```
CHILD SHELL
┌─────────────────────────────────────┐
│ ┌──────────────┐         ┌────────┐ │
│ │ 👤 Bé Na 🪙75│         │ 🌱 2   │ │  ← floating chips (top-left cluster, top-right badge)
│ └──────────────┘         └────────┘ │
│                                       │
│                                       │
│         [ active tab content ]       │  ← fully clear center, hosted screen renders here
│                                       │
│                                       │
│                                       │
├─────────────────────────────────────┤
│   🏠        ⚡         🛍️            │  ← bottom nav bar, 3 tabs
│  Nhà     Nhiệm vụ    Shop            │
└─────────────────────────────────────┘

PARENT SHELL
┌─────────────────────────────────────┐
│                                       │  ← no floating chips
│                                       │
│                                       │
│         [ active tab content ]       │  ← Dashboard / Gia đình
│                                       │
│                                       │
│                                       │
├─────────────────────────────────────┤
│      📋              👨‍👩‍👧            │  ← bottom nav bar, 2 tabs, Navy-toned
│   Nhiệm vụ         Gia đình          │
└─────────────────────────────────────┘
```

---

## States & Variants

| State / Variant | Trigger | What Changes |
|---|---|---|
| Cold start / resolving *(added at `/ux-review`)* | App just launched, `sessionStateProvider`'s first value not yet emitted (Firebase Auth's async initial check) | Blank `Scaffold` in the app's base background color, no nav bar, no chips, no spinner — same "no flash" treatment as the Unauthenticated state below, just for the resolution gap itself. Not a distinct visual state a user should ever consciously perceive; this is a real state existing code must handle regardless (a `null`/loading `AsyncValue` on `sessionStateProvider`), and it must resolve to one of the states below in well under a second on any reasonable connection. |
| Unauthenticated | No session / token expired | No nav bar, no chips — full-screen Login |
| Parent authed, no child selected | Login success, no child chosen yet | No nav bar, no chips — full-screen Child Selector |
| Child selected (default) | Correct PIN entered | Child bottom nav (3 tabs) + chip cluster appear; default tab = Pet Room |
| Parent override | Long-press Profile chip + password confirmed | Parent bottom nav (2 tabs), no chips; child session preserved untouched underneath |
| Xu chip — error | `xuBalanceProvider` throws | Chip still renders, shows `"— xu"` instead of crashing |
| Contextual badge — empty | `seedCount == 0` AND `chestCount == 0` | Chip fully removed from layout (not faded/greyed) |
| Contextual badge — seed | `seedCount > 0` on task-flow-relevant screens | 🌱 + count shown |
| Contextual badge — chest | `chestCount > 0` on shop-adjacent screens | 🎁 + count shown — never both at once |
| Switch-mode sheet — wrong password | Parent enters wrong password during override attempt | Inline error "Mật khẩu không đúng"; sheet stays open, no navigation, no logout |

Open item (see Open Questions): the GDD specifies a PIN lockout for the *child's* PIN (owned by Auth & Account), but doesn't specify any lockout for a parent mistyping their password during override.

---

## Interaction Map

Mapping interactions for: **Touch only** (mobile iOS+Android, no gamepad — per `technical-preferences.md`).

| Component | Action | Feedback | Outcome |
|---|---|---|---|
| Child/Parent bottom nav tab | Tap | Tab-switch fade-through animation 200ms (Material 3); active tab highlight moves | `StatefulNavigationShell.goBranch(index)` + `activeChildBranchIndexProvider` updated; branch never disposed |
| Profile chip | Long-press ≥600ms | Switch-mode bottom sheet slides up (250ms ease-out), background dims 40% | Sheet shown: "Chuyển sang tài khoản bố/mẹ?" |
| Switch-mode sheet — Confirm (with correct password) | Tap | Soft chime sound | `parentOverrideProvider = true`, navigate to `/parent/dashboard`, child session untouched |
| Switch-mode sheet — Confirm (wrong password) | Tap | Inline error text "Mật khẩu không đúng" | Sheet stays open, no navigation, no logout |
| Switch-mode sheet — Cancel / dismiss | Tap outside / swipe down | Sheet slides away | No state change |
| Back-press, Child tab root | System back gesture/button | Exit confirm dialog appears | Dialog: "Thoát PetQuest?" |
| Exit dialog — [Thoát] | Tap | — | App exits |
| Exit dialog — [Ở lại] | Tap | Dialog dismisses | No other change |
| Back-press, Parent tab root (not override) | System back | — | App exits directly, **no dialog** (adult tone) |
| Back-press, Parent tab root (in override / `parentView`) | System back | — | `parentOverrideProvider = false`, navigate to `/child/pet-room`, no dialog, no re-PIN |
| "Xong"/"Quay lại" button (owned by Parent Dashboard #21, triggers Nav Shell logic) | Tap | — | Same as override back-press: return to `/child/pet-room`, session intact |

---

## Events Fired

Checked `GameEventBus` (ADR-0004) — Main Navigation Shell isn't a listed producer or consumer, so no bus events apply here. No analytics events are specified anywhere in this GDD or related docs — none invented; flagged as an open gap instead.

| Player Action | Event Fired | Payload / Data |
|---|---|---|
| Tab switch (either shell) | None | — |
| Profile chip long-press | None | — |
| Switch-mode confirm (success) | None | — |
| Switch-mode confirm (failure) | None | — |
| Exit dialog confirm/cancel | None | — |
| Override back-press / "Xong" | None | — |

No action in this shell writes persistent (Firestore) state — `parentOverrideProvider` is in-memory only, not persisted, so no architecture-team flag is needed here. Analytics event instrumentation is an explicit gap, not a deliberate "no event" choice — see Open Questions.

---

## Transitions & Animations

**Tab switch** (both shells): fade-through, 200ms (Material 3 pattern). Optional subtle "tick" sound (0.1s), off by default.

**Switch-mode bottom sheet**: slide-up, 250ms ease-out, background dims to 40% opacity. Soft chime sound on successful confirm.

**Shell-level screen enter/exit**: not specified by the GDD — the shell itself doesn't animate in/out (it's the root, always present once session state resolves). The route transition *into* the shell (Login→Selector, Selector→Child Shell) is owned by those screens' own specs (`login-screen.md`, `child-profile-selection-screen.md`, `pin-entry-screen.md`), not this one. The transition *between* Child Shell and Parent Shell (on override toggle) isn't specified here either — defaults to the platform's standard `go_router` push transition unless a future revision specifies otherwise. Flagged as an Open Question rather than invented.

**Reduced motion**: both animations here are short utility transitions (200ms fade, 250ms slide), not the "ceremony" style `accessibility-requirements.md` calls out (Chest Open, level-up, etc.) — but should still honor `MediaQuery.disableAnimations` for consistency with the pattern used elsewhere in this codebase (e.g. PIN entry's shake/flash reduced-motion handling): fade/slide durations collapse to a near-instant cross-fade when reduced motion is on, rather than being skipped as "not applicable."

---

## Data Requirements

| Data | Source System | Read/Write | Notes |
|---|---|---|---|
| `sessionState` | Auth & Account #1 (`sessionStateProvider`) | Read | Route guard decisions — **hard dependency**, shell cannot route without it |
| Active child (name, avatar) | Auth & Account #1 (`activeChildProvider`) | Read | Profile chip content |
| `xuBalance` | Currency System #7 (`xuBalanceProvider`) | Read | Xu chip — **soft dependency**, degrades gracefully to `"— xu"` on error |
| `seedCount` | Seed Buffer #10 (`seedCountProvider`, ADR-0012) | Read | Contextual badge, seed variant |
| `chestCount` | Gacha/Loot #12 (provider not yet ADR'd — architecture gap, see `architecture.md`) | Read | Contextual badge, chest variant |
| `parentOverrideProvider` | Auth & Account #1 | **Write** | The only write this shell performs — set `true` on long-press+password-confirm, `false` on override-exit |
| `activeChildBranchIndexProvider` | **Owned by this system (#17)** | Read/Write | Written on every tab switch; read by other screens (e.g. Task Mgmt UI #19's interrupt-detection) |

`chestCount`'s source provider isn't ADR-covered yet (Gacha/Loot Roll Architecture is still unwritten — same gap category Seed Buffer was in before ADR-0012); this spec can still reference it by name since the GDD does, but the read contract isn't locked down yet. `activeChildBranchIndexProvider` is genuinely owned here (not just consumed) — this shell's one piece of exported state that other screens depend on.

**Loading/null handling** *(added at `/ux-review`)*: before `seedCountProvider`/`chestCount`'s first snapshot resolves, the Contextual badge chip treats the value the same as `0` (chip absent from layout) rather than showing a placeholder or spinner — consistent with the chip's own "removed at 0, not faded" rule, and avoiding a flash-then-appear on every cold start.

---

## Accessibility

Checked against the committed Kid-Touch Baseline (`design/accessibility-requirements.md`):

**1. Touch target size**: Material 3 `NavigationBar` destinations meet the 48×48dp minimum by default; explicitly confirmed here since the GDD only specifies icon sizes (28dp child / 24dp parent), not full tap-target size. Profile chip, exit-dialog buttons, and switch-mode sheet buttons must also each meet 48×48dp.

**2. Color never the only signal**: active/inactive tab state is conveyed via icon fill change + always-visible label, not color alone (Peach Glow/Navy accent is a *reinforcement*, not the sole cue). Xu chip and Contextual badge already use icon+number pairing (established in `hud.md`), not color alone.

**3. Text legibility**: child nav labels at 11sp meet the Art Bible's stated floor exactly (only acceptable when paired with an icon — it is here). Any text placed directly on the Peach Glow (active tab accent) or Navy (parent tone) backgrounds must use **Primary text** (`#3D2B1F`) per the resolved 2026-07-13/14 contrast audit — the only text role that passes 4.5:1 against every palette color.

**4. No timing pressure**: no countdown timers anywhere in this shell. The switch-mode confirm sheet has `switch_mode_confirm_timeout = 0` (no auto-dismiss, per the GDD's own Tuning Knob) — a parent is never rushed through re-entering their password.

**5. Language**: Vietnamese, minimal-text tab labels (icon-led) already matches the simple-language requirement.

**6. Motion**: covered in Transitions & Animations above (reduced-motion cross-fade for both the 200ms tab fade and 250ms sheet slide).

**7. Interaction robustness**: touch-only, no hover states. Re-tapping the *already-active* tab must be a no-op (not a stacked navigation push) — `hud.md` explicitly delegates ownership of this exact requirement to this spec (its §7 note), so it's locked in here. The switch-mode sheet (parent password) and exit dialog both already require an explicit confirm step, satisfying the destructive/sensitive-action rule — though exiting the app isn't really "destructive" so much as disruptive; the confirm step exists for accidental-back-press protection, not data-loss protection.

---

## Localization Considerations

**Longest/layout-critical elements**: the 3 child tab labels ("Nhà", "Nhiệm vụ", "Shop") and 2 parent tab labels ("Nhiệm vụ", "Gia đình") must stay on one line at their specified sizes (11sp/12sp) within a narrow tab-bar column — flagged **HIGH PRIORITY** for the localization engineer, since Material `NavigationBar` labels wrap or truncate awkwardly when translated text runs longer than the Vietnamese source (a real risk at the 40%-expansion German/French benchmark).

**Profile chip child name**: no maximum length is specified anywhere in the GDD for a child's display name. At 16sp bold in a fixed-width floating chip, a long name will overflow — this needs a truncation strategy (ellipsis, most likely) that isn't currently defined by any spec. Flagged as an Open Question rather than invented here, since name-length limits are more naturally Auth & Account's concern (where the name is entered) than this shell's.

**Dialog copy**: "Chuyển sang tài khoản bố/mẹ?", "Thoát PetQuest?", and the inline "Mật khẩu không đúng" error are all short enough to tolerate normal translation expansion inside a standard `AlertDialog`/bottom sheet, which reflows freely — not layout-critical.

**Numbers**: Xu chip displays a plain integer, no decimals, no locale-specific formatting currently specified (per the GDD's `displayXu` formula) — fine at MVP balance ranges, but flag for revisit if locale-specific thousands separators become relevant at higher values.

---

## Acceptance Criteria

Reused directly from the GDD's own 14 ACs (already well-formed and testable for this exact system), converted to checkbox format, plus one new accessibility criterion the GDD didn't have:

- [ ] GIVEN app starts with session `unauthenticated`, THEN GoRouter redirects to `/login` — no other screen flashes. (AC-1)
- [ ] GIVEN parent logs in successfully with no child selected yet, THEN auto-redirect to `/select-child`. (AC-2)
- [ ] GIVEN child enters correct PIN on Child Selector, THEN redirect to `/child/pet-room` with Child bottom nav (3 tabs) visible. (AC-3)
- [ ] GIVEN child is on `/child/pet-room`, WHEN tapping "Nhiệm vụ" tab, THEN navigate to `/child/tasks` within 200ms; "Nhà" tab no longer active. (AC-4)
- [ ] GIVEN child is on `/child/tasks`, WHEN tapping "Nhà" tab back, THEN Pet Room resumes immediately — no rebuild, Flame game loop still running. (AC-5)
- [ ] GIVEN `xuBalanceProvider` holds 75, THEN Xu chip displays "75 xu". (AC-6)
- [ ] GIVEN `xuBalanceProvider` throws an error, THEN Xu chip displays "— xu" — no crash. (AC-7)
- [ ] GIVEN child long-presses the Profile chip avatar ≥600ms, THEN the "Chuyển sang tài khoản bố/mẹ?" bottom sheet appears. (AC-8)
- [ ] GIVEN parent enters the correct password in the switch-mode flow, THEN `parentOverrideProvider = true`, navigate to `/parent/dashboard`, Parent bottom nav (2 tabs) shown, AND child session is not logged out (`activeChildProvider` unchanged). (AC-9)
- [ ] GIVEN child back-presses on a Child tab root screen, THEN "Thoát PetQuest?" dialog appears — [Ở lại] dismisses, [Thoát] exits. (AC-10)
- [ ] GIVEN session expires while child is on `/child/shop`, THEN redirect to `/login` — never stuck on `/child/shop`. (AC-11)
- [ ] GIVEN child is on `/child/tasks/new` (sub-screen), WHEN back-pressing, THEN navigate to `/child/tasks` — not to Pet Room. (AC-12)
- [ ] GIVEN `sessionState == parentView`, WHEN parent back-presses on `/parent/dashboard`, THEN return to `/child/pet-room` (`parentOverrideProvider = false`) — no app exit, no kid-styled dialog. (AC-13)
- [ ] GIVEN parent is on `/parent/dashboard` post-override, WHEN tapping "Xong"/"Quay lại", THEN return directly to `/child/pet-room` without passing through `/select-child` — no re-PIN required. (AC-14)
- [ ] **[NEW]** Every interactive element in both shells (nav tabs, Profile chip, dialog/sheet buttons) meets the 48×48dp minimum touch target, and re-tapping the already-active tab is a no-op (verified — no stacked navigation push).
- [ ] **[NEW, added at `/ux-review`]** Bottom nav bars, floating chip cluster, and contextual badge render correctly without overlap or clipping on both small (iPhone SE, ~375dp width) and large (tablet-size Android, ~600dp+ width) screens.

---

## Open Questions

- **RESOLVED at `/ux-review` (2026-07-18)**: this spec and the GDD both originally used `/child-selector` as the child-selection route path. The actually-built code (Auth & Account epic, Complete) defines `AppRoutes.selectChild = '/select-child'` instead — a real path-string mismatch, found while implementing Parent Dashboard UI's Story 001. Resolved by updating this spec to `/select-child` to match the already-shipped, already-tested code, rather than renaming the working code to match the doc. `design/gdd/main-navigation-shell.md`'s own Route Map still says `/child-selector` and should be corrected to match on its next touch, but is not blocking implementation of this spec.
- Player journey map not yet created. Template available at `.claude/docs/templates/player-journey.md`. Run `/ux-design` Phase 2b or create it manually to establish player context for this screen.
- **Shell-to-shell transition** (Child Shell ↔ Parent Shell on override toggle) has no specified route-transition animation — defaults to platform standard. Revisit if a future revision wants something more deliberate.
- **Analytics event instrumentation** is entirely unspecified for this shell's interactions (tab switches, override toggles, exit dialog) — a gap, not a deliberate choice.
- **Parent password lockout**: no lockout/rate-limit policy is defined for repeated wrong-password attempts during Parent Override (unlike the child PIN's 3-strikes/60s lockout, owned by Auth & Account). Confirm whether this is intentional (parent already holds the device, lower risk) or a gap to close.
- **Profile chip child-name truncation**: no maximum name length or truncation strategy (ellipsis, etc.) is specified anywhere — likely belongs to Auth & Account (where the name is entered) rather than this shell, but needs an owner.
- `chestCount`'s source provider (Gacha/Loot #12) isn't ADR-covered yet — this spec references it by name per the GDD, but the read contract isn't locked down until that ADR is written.

## Cross-Reference Check Results

- **GDD requirements**: all 14 ACs + all 5 UI Requirements bullets covered (Child Selector / Login screens correctly cross-referenced to their own existing specs, not duplicated here)
- **New patterns added to library**: P16 (Long-press to enter privileged mode), P17 (Disruption-not-destruction confirm dialog) — both written to `design/ux/interaction-patterns.md`
- **Navigation mismatches**: none found
- **Accessibility gaps**: none — all 7 Kid-Touch Baseline items addressed
- **Missing empty states**: none for this shell's own elements (screen-content empty states belong to the hosted screens, not this shell)
