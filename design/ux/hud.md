# HUD Design

> **Status**: Complete — all sections drafted, Cross-Reference Check done (1 real conflict found + resolved: Profile chip added, `main-navigation-shell.md` amended). `/ux-review` 2026-07-18: NEEDS REVISION (1 blocking + 4 advisory) → all fixed inline → APPROVED.
> **Author**: user + ux-designer
> **Last Updated**: 2026-07-18
> **Platform Target**: Mobile (iOS + Android), Touch only — from `technical-preferences.md`
> **Template**: HUD Design

---

## HUD Philosophy

**Minimal but Present.** PetQuest's HUD shows only the information a child needs to decide their next action: how many xu they have, whether any task is pending parent-approval, and which tab they're on. Everything else — mood, energy level — is delegated entirely to Mochi's own animation and body language (Art Bible §1 P3, §5 body-language design), never duplicated as HUD text or icons.

The HUD must never compete for attention with Mochi. If a HUD element draws the eye before Mochi does, it is sized or placed wrong. This directly serves Pillar 2 ("thú cưng là hình ảnh của bé") — the pet, not the interface, is the emotional center of every screen — and Art Bible P1 (Pastel Warmth: no aggressive/urgent visual weight) and P2 (Round Over Sharp: HUD chrome uses the same soft shape language as the world, never a harsh "gamer HUD" overlay).

**Concrete test**: on any screen, cover the HUD chrome with a hand — can the child still tell how Mochi feels and what to do next? If mood is unclear, that's correct (Mochi handles it). If the child can't tell whether they have pending tasks or how much xu they have, that's also correct — those ARE the HUD's job, restored when the hand is removed.

---

## Information Architecture

### Full Information Inventory

Pulled from every GDD's UI Requirements section that names a persistent or semi-persistent chrome element (not screen-specific content, which is owned by each screen's own UX spec):

| # | Information | Owning System |
|---|---|---|
| 1 | Xu balance (số dư) | Currency System (#7) |
| 2 | Seed count (nhiệm vụ đang chờ phụ huynh duyệt) | Seed Buffer (#10) |
| 3 | Chest count (rương may mắn chưa mở) | Gacha/Loot (#12) |
| 4 | Tab hiện tại / điều hướng (Child: 3 tab, Parent: 2 tab) | Main Navigation Shell (#17) |
| 5 | Thông báo FCM (task mới được submit) | Push Notification (#9) / Parent Dashboard UI (#21) |
| 6 | Mood / energy của Mochi | Pet State Machine (#6) |

### Categorization

| Information | Category | Rationale |
|---|---|---|
| Xu balance | **Must Show** | GDD Currency System explicitly requires "Wallet luôn visible" — child needs it to plan (e.g. "còn thiếu bao nhiêu xu để mua mũ"). |
| Nav bar / current tab | **Must Show** (structural, not "data" per se) | The navigation chrome itself — always present so the child can switch tabs at any time and always sees which tab is active. |
| Seed count | **Contextual** | Only shown when `seedCount > 0` (per GDD). No pending tasks = no badge, matching Minimal-but-Present. |
| Chest count | **Contextual** | Only shown when `chestCount > 0` (per GDD), with a pulse animation to draw attention when it appears. |
| FCM foreground banner | **Contextual** | Only appears on a new notification event; Parent Shell only (per `parent-dashboard-ui.md`), global overlay at Parent Shell scaffold level, not tab-specific. |
| Mood / energy | **Hidden** | Deliberately never shown as HUD text/icon/number — communicated entirely through Mochi's own body language and animation (Pet State Machine #6, Art Bible §5). This is the HUD Philosophy's central design choice, not an oversight. |

**No "On Demand" category items at MVP** — there is no HUD element the child must actively toggle/hold to reveal. If a future system needs one (e.g., a detailed stats panel), it would be added here as a new row, not folded into an existing element.

**Conflict check**: the Must Show list is short (2 structural items: xu + nav chrome) — consistent with the "Minimal but Present" philosophy, no reduction needed.

---

## Layout Zones

**Chosen arrangement: Floating chip cluster.** Three independent floating pill-shaped chips (never a connected bar): a top-left **cluster** of two adjacent chips (Profile + Xu), a top-right **Contextual badge** chip, a persistent bottom nav bar, and a fully clear center for Mochi/screen content. This matches the vertical slice's already-tested precedent (`prototypes/petquest-core-loop-vertical-slice/`) and, per Art Bible Section 3's Hero/Supporting hierarchy, treats each chip as an independent small "supporting" element rather than fusing them into one continuous app-bar shape — keeping visual weight low and avoiding a "connected chrome bar" that would read as more HUD-heavy than Minimal-but-Present intends.

**Amendment (2026-07-14, Cross-Reference Check)**: the initial two-corner version of this section omitted the child's avatar/name display and the long-press-to-Parent-Override gesture that `main-navigation-shell.md` (Rule 5/6, AC-6/7/8) requires as a real, binding interaction. Resolved by adding a third chip — **Profile** — grouped with the Xu chip in the top-left cluster (see User Decision below), rather than reverting to a connected app bar. `main-navigation-shell.md` has been amended to reference this floating-chip terminology in place of its original "app bar" wording; the underlying data contracts and ACs are unchanged.

```
┌────────────────────────┐
│ [👤 Bé Na] [🪙 25] [🌱2]│  ← top-left cluster: Profile + Xu (Must Show) — top-right: Contextual (badge)
│                        │
│                        │
│       (Mochi /         │  ← fully clear center —
│      screen content)   │    zone belongs entirely to the screen's own UX spec
│                        │
│                        │
│  [🏠]   [⚡]   [🛍️]    │  ← bottom nav bar (Child Shell, 3 tabs)
└────────────────────────┘
```

**Zone definitions:**

| Zone | Position | Contains | Owner |
|---|---|---|---|
| Top-left cluster | Safe-area top-left, floating (2 adjacent chips, small gap, not fused) | Profile chip (avatar + name) + Xu chip (balance) | Profile chip's interaction logic (long-press → Parent Override) owned by Main Navigation Shell (#17); both chips' visual/animation spec owned by this document |
| Top-right chip | Safe-area top-right, floating | Contextual badge (Seed count on `/child/tasks`-relevant screens, Chest count on `/child/shop`) — only one badge type is relevant per screen, never both simultaneously stacked | This spec (HUD) |
| Bottom nav bar | Fixed bottom, full width | 3 tabs (Child Shell) or 2 tabs (Parent Shell) | Main Navigation Shell (#17) — this spec only defines what floats above it, not the bar's own implementation |
| Center | Everything between the top chips and the nav bar | Screen-specific content (Mochi, task list, shop grid, etc.) | Each screen's own UX spec (e.g. `pet-room-screen.md`) |

**Parent Shell exception**: Parent Shell has no Profile/Xu/badge chips at all (those are child-side concepts — avatar-switching in Parent Shell already lives in its own app bar per `parent-dashboard-ui.md`'s "Chọn bé" action). The top zone is reserved entirely for the FCM foreground banner when a notification is pending (see Dynamic Behaviors).

---

## HUD Elements

### 1. Profile Chip

| Property | Spec |
|---|---|
| Content | Avatar circle (32dp) + child's name, 16sp bold (per `main-navigation-shell.md`'s existing Visual/Audio Requirements) |
| Visual form | Floating pill, grouped adjacent to the Xu chip in the top-left cluster (small visible gap between the two — never rendered as one fused shape) |
| Update behavior | Static per session — re-renders only if the active child profile changes (rare; would require returning to Child Selector) |
| Contextual trigger | Always visible (Must Show, structural — same tier as Xu chip and nav bar) |
| Animation | Long-press (≥600ms, `long_press_duration` tuning knob per `main-navigation-shell.md`) triggers the "Chuyển sang tài khoản bố/mẹ?" bottom sheet (Interaction Pattern P3) — this gesture and its full flow are owned by Main Navigation Shell (#17) Rule 6/AC-8, not redefined here. No idle animation. |

### 2. Xu Balance Chip

| Property | Spec |
|---|---|
| Content | Coin icon + current xu balance as an integer (e.g. `🪙 25`) |
| Visual form | Floating pill, Honey Gold fill, Primary text (`#3D2B1F`), Round-Over-Sharp shape per Art Bible §3 — a "Supporting" shape, smaller and quieter than Mochi |
| Update behavior | Re-renders on any `xuBalanceProvider` change (Currency System #7). On increase, the digits count up over ~400ms rather than snapping — makes an earned reward legible as a *gain*, not just a new number |
| Contextual trigger | Always visible (Must Show) — no show/hide logic |
| Animation | Count-up tween on increase (~400ms ease-out); a brief scale-pulse (1.0→1.15→1.0, ~200ms) exactly when the increase is caused by a task reward, to tie the number change back to the action that caused it. Purchases (decrease) have no pulse — decreases are calm, not spend-anxiety-inducing, in line with a game for children |

### 3. Contextual Badge Chip (Seed / Chest)

| Property | Spec |
|---|---|
| Content | Seed icon + pending-approval count (e.g. `🌱 2`) OR Chest icon + unopened-chest count (e.g. `🎁 1`) — never both at once |
| Visual form | Same floating-pill language as the Xu chip, top-right corner. Uses Honey Gold fill like the Xu chip (not an alert color) — a pending seed or unopened chest is a *positive* pending state for a child, not a warning, so it must not borrow red/urgent color semantics |
| Update behavior | Bound to `seedCount` (Seed Buffer #10) on screens in the task-submission flow, or `chestCount` (Gacha/Loot #12) on Shop-adjacent screens. Exactly one binding is active per screen — determined by the screen's own UX spec, not by this chip |
| Contextual trigger | Hidden entirely when the bound count is 0 (per Information Architecture's Contextual categorization). Appears the instant the count becomes ≥1 |
| Animation | Pop-in with a small overshoot (scale 0→1.1→1.0, ~300ms) when it first appears from 0. A single pulse (not looping/attention-seeking) each time the count increments further, so a second pending seed doesn't go unnoticed while the badge is already visible |

### 4. Bottom Navigation Bar

| Property | Spec |
|---|---|
| Content | Child Shell: 3 tabs (Pet Room, Tasks, Shop). Parent Shell: 2 tabs (Dashboard, Settings) |
| Visual form | Fixed bottom bar, full width, icons + labels, active tab indicated by Honey Gold fill/underline on Primary background |
| Update behavior | Active-tab indicator follows `sessionStateProvider`'s current route — this spec defines what floats above/on the bar, not the bar's routing logic (owned by Main Navigation Shell #17) |
| Contextual trigger | Always visible (Must Show, structural) |
| Animation | Tab-switch: icon scale-bounce (1.0→1.2→1.0, ~150ms) on the newly active tab; no animation on the outgoing tab beyond the instant fill/color change |

### 5. FCM Foreground Banner (Parent Shell only)

| Property | Spec |
|---|---|
| Content | One-line notification text (e.g. "Bé đã nộp nhiệm vụ: Dọn phòng") |
| Visual form | Full-width banner sliding down from the top safe area, Primary background, Primary-on-light text, replaces the (non-existent, for Parent Shell) top-right badge zone |
| Update behavior | Appears on new FCM foreground message (Push Notification #9); tapping navigates to the relevant approval screen and dismisses the banner |
| Contextual trigger | Only on a new notification event — never persistent |
| Animation | Slide down (~250ms ease-out) on appear; dismiss ONLY on tap or manual swipe — **no auto-dismiss timer** (corrected at `/ux-review`, 2026-07-18: this element previously specified a 4s auto-dismiss, contradicting `parent-dashboard-ui.md`'s own deliberate Tuning Knob decision — "FCM banner behavior: Manual dismiss chỉ, không auto-dismiss... quyết định cố ý ở Core Rules 6," matching `accessibility-requirements.md`'s no-timing-pressure baseline more precisely too, since a disappearing-without-action banner would itself be a small timing pressure) |

**Mood/energy is deliberately absent from this table** — per Information Architecture, it is Hidden by design and communicated entirely through Mochi's own animation, not through any HUD element.

---

## HUD States by Gameplay Context

**N/A for this game** *(explicit statement added at `/ux-review`, 2026-07-18)*: PetQuest has no combat, dialogue/cutscene, or paused gameplay states — its structure is tab-based screens (Pet Room / Tasks / Shop for the child, Dashboard / Gia đình for the parent), not a session with distinct gameplay modes. The closest analogues — Child Shell vs. Parent Shell, and the full-screen ceremony overlays that suspend the nav bar (Chest Open, level-up) — are already covered under Layout Zones and Dynamic Behaviors' Show/Hide Rules respectively. This section is intentionally empty, not forgotten.

## Visual Budget

*(added at `/ux-review`, 2026-07-18)* Maximum 3 simultaneous HUD elements on Child Shell (Profile chip + Xu chip + one Contextual badge — Seed and Chest are mutually exclusive per screen, never both), or 0 on Parent Shell outside of a transient FCM banner. No explicit "screen %" budget is set — the floating-chip footprint is small and fixed by the 48×48dp minimum touch target, not a proportional screen coverage rule. This is implicitly enforced by the existing mutual-exclusivity rules (Information Architecture, Dynamic Behaviors' Simultaneous Contextual Events) rather than a separately-tracked numeric budget.

## Tuning Knobs

**None at MVP** *(explicit statement added at `/ux-review`, 2026-07-18)*: no HUD element in this spec is player-adjustable — all timing/sizing values (count-up duration, pulse timing, touch target size) are fixed implementation constants, not exposed settings. `long_press_duration` is a real tuning knob but is owned and defined by `main-navigation-shell.md`, not this document (this spec only consumes the resulting gesture, per HUD Elements §1). If a future accessibility pass adds user-adjustable motion/size settings, this section is where they'd be documented.

## Dynamic Behaviors

### Show / Hide Rules

- **Xu chip**: never hidden on any Child Shell screen. Not present on Parent Shell (xu is a child-side economy concept).
- **Contextual badge**: hidden whenever its bound count is 0; the chip is removed from layout entirely (not just faded/greyed) so it never occupies dead space — consistent with Minimal-but-Present.
- **Nav bar**: never hidden while inside its owning shell. Hidden only during full-screen takeovers that intentionally suspend navigation (e.g. a modal reward-reveal ceremony) — that suppression is owned by the takeover screen's own UX spec, not by this document.
- **FCM banner**: never hidden by default state; appears only on event, dismisses only via tap or manual swipe per Element 5's timing (corrected element reference and auto-dismiss behavior at `/ux-review`, 2026-07-18 — was previously "Element 4" and "auto-dismisses," both wrong).

### Simultaneous Contextual Events

If both a Seed-count change and a Chest-count change could theoretically apply to the same screen, this is treated as a **screen design conflict**, not a HUD conflict — per Element 2's rule, exactly one contextual binding is valid per screen. Each screen's own UX spec must pick the one relevant badge; if a screen genuinely needs to communicate both, that screen's spec must resolve it directly (e.g. Shop screen shows Chest, Tasks screen shows Seed) rather than stacking badges in the HUD.

### Reduced Motion

All animation behaviors in HUD Elements (count-up, pulse, pop-in, tab-bounce, banner slide) must degrade to instant state-changes when the platform's reduced-motion accessibility setting is on (see Accessibility section). This is a hard requirement, not a nice-to-have, given the target age range's variance in sensory sensitivity.

### State Persistence Across Navigation

The Xu chip and active contextual badge must not visibly "reset and reload" when switching tabs — values are read from the already-subscribed Riverpod providers (`xuBalanceProvider`, `seedCount`/`chestCount`), so a tab switch shows the current value immediately with no loading flicker. This depends on the Flutter-Flame Bridge's provider lifecycle (ADR-0004) already keeping these providers warm outside of any single screen's widget tree.

---

## Platform & Input Variants

Per `.claude/docs/technical-preferences.md`: Target Platforms = Mobile (iOS + Android), Primary Input = Touch, full touch support, no gamepad.

- **Touch targets**: both floating chips and all nav-bar tabs meet the 48×48dp minimum tap target (Material guidelines, per technical-preferences.md's Platform Notes), even though the chips themselves are informational, not interactive, at MVP — sized generously in case a future "tap xu chip → open wallet detail" affordance is added, so the visual footprint doesn't need to change later.
- **Safe area**: top chips respect the device safe-area inset (notch/Dynamic Island on iOS, cutout on Android) — never rendered under the status bar or camera cutout.
- **No hover states**: neither chip nor nav bar has a hover-only affordance (touch has no hover) — all interactive feedback is press-state (opacity/scale dip on touch-down) rather than hover-based.
- **Orientation**: PetQuest is portrait-only (implied by the Pet Room's fixed layout in `pet-room-screen-ui.md`); this HUD spec assumes portrait and does not define a landscape variant. If landscape support is added later, this is a required Open Question follow-up.
- **iOS vs. Android**: no platform-specific HUD differences beyond native safe-area handling — Flutter's `SafeArea` widget covers both without divergent logic per `technical-preferences.md`'s Flutter/Flame stack.

---

## Accessibility

Cross-referenced against the committed **Kid-Touch Baseline** tier (`design/accessibility-requirements.md`).

| Baseline requirement | How this HUD spec satisfies it |
|---|---|
| §1 Touch target size (48×48dp min) | Both chips and every nav-bar tab meet 48×48dp (see Platform & Input Variants) — even non-interactive chips, for future-proofing. |
| §2 Color is never the only signal | Every HUD element pairs an icon with its value (🪙 with the number, 🌱/🎁 with the badge count) — no chip communicates state through color alone. The Contextual badge deliberately does NOT use an alert/red color for a pending seed or chest (see HUD Elements §3) — positive-pending states stay in the Honey Gold palette, consistent with this rule's spirit (color never carries meaning alone; the icon does). |
| §3 Text legibility (contrast, min size) | Xu and badge chip text use Primary text (`#3D2B1F`) on Honey Gold fill — passes WCAG AA per the 2026-07-13/07-14 contrast audit. No chip uses On-color/white text (resolved finding #2) or the pre-fix Secondary/Disabled hexes (resolved finding #3). Nav bar labels ≥11sp per baseline, always icon-paired. |
| §4 No timing pressure | The FCM banner has no auto-dismiss timer at all (corrected at `/ux-review` — see HUD Elements §5) — dismissal is entirely tap/swipe-driven, and the underlying notification remains actionable from the Parent Dashboard regardless, so there is no "must act before it disappears" pressure state of any kind. |
| §5 Language & comprehension | HUD elements are numeric/iconographic only (no copy to read) except the FCM banner's one-line text — kept short and concrete per the baseline's simple-language rule. |
| §6 Motion | All HUD animations (count-up, pulse, pop-in, tab-bounce, banner slide) have a reduced-motion fallback to instant state-change, per Dynamic Behaviors' Reduced Motion rule. |
| §7 Interaction robustness | HUD elements are display-only at MVP (no tap targets to double-tap-guard on the chips themselves); nav-bar tab switching is idempotent (re-tapping the active tab is a no-op, not a stacked navigation push) — owned by Main Navigation Shell #17 but noted here as a HUD-adjacent robustness expectation. |

No HUD element introduces a requirement beyond the committed baseline (e.g. no screen-reader-specific work, per the baseline's explicit "out of MVP" deferral) — this spec only needs to satisfy Kid-Touch Baseline, not exceed it.

---

## Open Questions

- **Player journey map not yet created** (`design/player-journey.md` does not exist). This HUD spec was authored without it — assumptions about arrival emotional state and journey-phase context (e.g. first-time-open vs. returning-daily) are inferred from GDDs rather than a documented journey map. Run `/ux-design` Phase 2b or create the journey map manually, then revisit whether the "Minimal but Present" framing and Must Show/Contextual split still hold once real journey data exists.
- **Landscape orientation**: not addressed — PetQuest is assumed portrait-only based on Pet Room's fixed layout. If landscape is ever required, Layout Zones needs a variant pass.
- **Future "tap to expand" affordance on chips**: chips are sized for a 48×48dp tap target even though nothing is currently tappable on them. If a future feature (e.g. "tap xu chip to see transaction history") is added, this spec's Interaction Map (none currently) and Dynamic Behaviors would need a follow-up revision — flagging now so it isn't forgotten if that feature request appears later.
- **Parent Shell HUD is thin by design** (banner only, no xu/badge chips) — confirm this is acceptable once the Parent Dashboard UX spec is authored in full; this HUD spec assumed Parent Shell's needs are covered entirely by that screen's own content rather than by shared chrome.
