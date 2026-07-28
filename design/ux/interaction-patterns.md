# Interaction Pattern Library

> **Status**: Initialized (2026-07-08) — seeded by extraction from the 21 MVP GDDs' UI Requirements + Visual/Audio sections. Refine per-pattern during screen UX specs + `/ux-review`.
> **Author**: derived from `design/gdd/*.md` (factual extraction, not new design)
> **Template**: Interaction Pattern Library

---

## Overview

This catalog formalizes the recurring interaction patterns the MVP GDDs already rely on, so screen UX specs reference a pattern by name instead of reinventing it — and so cross-cutting rules (single-flight guards, color-independent feedback, confirm-on-destructive) are defined once and inherited everywhere. Every entry cites the GDD(s)/ADR(s) it comes from. Where a pattern's *look* is taste-dependent, that's deferred to the per-screen specs + Art Bible; this library fixes the *behavior contract*.

Input context (from `technical-preferences.md`): **touch-only**, no hover, minimum 48×48dp targets, no gamepad. Accessibility baseline: `design/accessibility-requirements.md` (Kid-Touch Baseline).

---

## Pattern Catalog

| # | Pattern | Category | Primary sources |
|---|---------|----------|-----------------|
| P1 | Single-flight action guard | Input / Feedback | ADR-0008, gacha #12, parent-approval #11, shop #13 |
| P2 | Confirm-before-destructive dialog | Modal | auth #1, parent-dashboard #21 |
| P3 | Inline bottom sheet (detail / create) | Modal / Overlay | shop #13, parent-dashboard #21, nav #17 |
| P4 | Full-screen ceremony modal (root-nav, non-dismissible) | Overlay | gacha #12, shop-reward #20, pet-leveling #16 |
| P5 | Skeleton-shimmer loading state | Feedback | data-persistence #4, parent-dashboard #21 |
| P6 | Empty state | Data display | parent-dashboard #21, task-mgmt #19 |
| P7 | Coalescing in-app banner (foreground FCM) | Feedback / Overlay | parent-dashboard #21, push #10 |
| P8 | Icon+color state feedback (never color-alone) | Feedback | parent-dashboard #21, Art Bible §4 |
| P9 | Canvas sprite tap/swipe with per-type cooldown | Input | pet-interaction #14, pet-room #18 |
| P10 | PIN entry (dot display + numpad + lockout) | Input | auth #1 |
| P11 | Task submit ("Đã xong!") → seed drop | Input / Feedback | task-library #8, seed-buffer #10 |
| P12 | Reactive counter/wallet display | Data display | currency #7, nav #17 |
| P13 | Bottom-nav tab shell (branches never disposed) | Navigation | nav #17 |
| P14 | Post-acquisition "Equip now?" prompt (reused) | Modal | shop #13, gacha #12, shop-reward #20 |
| P15 | Deep-link entry → route to target | Navigation | push #10, nav #17 |
| P16 | Long-press to enter privileged mode | Navigation | nav #17 |
| P17 | Disruption-not-destruction confirm dialog | Modal | nav #17 |
| P18 | Conditional selector (hide when only one choice exists) | Input | parent-dashboard #21 |

---

## Patterns

### P1 — Single-flight action guard
**Category**: Input / Feedback · **Used In**: Shop purchase, Gacha chest open, Parent approve/reject
**Description**: For any action that fires a write and could be double-triggered, disable the control (and, for balance-affecting actions, ALL sibling controls that read the same balance) from the first tap until the write resolves or fails. Prevents double-spend / double-approve / double-open.
**Specification**:
- On first tap: set an in-flight flag in **screen-scoped** state (Riverpod), not the widget's local `State` (survives animation/rebuild) — ADR-0008.
- Disable the tapped control immediately; for purchases disable *all* "Mua"/buy controls on the screen (the honest-client double-tap-two-cards race — ADR-0008).
- Re-enable on completion OR failure. A fallback timeout is a ceiling, never the primary release (shop-reward #20).
- Only one full-screen ceremony auto-navigate pending at a time (shop-reward #20 Edge Case 7).
**When to use**: any Firestore write triggered by a tap (purchase, approve, reject, chest open, equip).
**When NOT to use**: pure navigation/read actions with no write and no cost.
**Accessibility**: children tap repeatedly — this pattern is an accessibility requirement, not only a correctness one (accessibility-requirements §7).

### P2 — Confirm-before-destructive dialog
**Category**: Modal · **Used In**: Delete child profile, Reset PIN
**Description**: A sensitive/irreversible action shows a confirm dialog stating the consequence in plain language before executing.
**Specification**: Material 3 `AlertDialog`; confirm button uses Lavender Soft accent + icon, **never red** (Art Bible §4). Copy states the irreversible consequence ("Không thể hoàn tác — toàn bộ dữ liệu của bé sẽ bị xóa"). Cancel is always available and has no side effect.
**When to use**: delete, reset, or anything irreversible/economy-affecting.
**When NOT to use**: reversible actions (equip — the old item stays in inventory).

### P3 — Inline bottom sheet (detail / create)
**Category**: Modal / Overlay · **Used In**: Shop item interaction, Create-custom-task, Wardrobe, Parent-override confirm
**Description**: Contextual detail or a short form slides up over the current screen instead of navigating to a sub-route (the GDDs deliberately removed item-detail / task-detail sub-routes in favor of sheets — nav #17).
**Specification**: slide-up 250ms ease-out, scrim dim 40% (nav #17 canonical motion — reuse verbatim, don't invent per-screen). Corner radius 12–20dp (Art Bible §3). Dismiss by scrim tap / swipe-down / explicit action. **Modal-exclusivity**: never stack two sheets; a context menu and the Wardrobe sheet are never both mounted (pet-room #18 Rule).
**When to use**: quick detail/confirm/short form tied to the current screen's context.
**When NOT to use**: a full destination the player should be able to deep-link to or navigate back to (use a route).

### P4 — Full-screen ceremony modal (root-nav, non-dismissible)
**Category**: Overlay · **Used In**: Chest Open, Level-up
**Description**: A celebratory, briefly-uninterruptible full-screen moment.
**Specification**: pushed via the **root navigator** (bypasses the branch Navigator) so the bottom nav bar is structurally un-tappable for its duration (nav #17 exception; shop-reward #20). Completion is driven by an `onAnimationComplete` callback, not a fixed timer (shop-reward #20). Honors reduced-motion (accessibility §6) with a shortened/cross-fade variant.
**When to use**: reward/level ceremonies that must not be interrupted mid-play.
**When NOT to use**: routine feedback (use a banner/snackbar).

### P5 — Skeleton-shimmer loading state
**Category**: Feedback · **Used In**: Child profile load, task list, pending list, wallet
**Description**: While a Firestore stream's first snapshot is pending, show subtle grey placeholder bars, never a blank screen or a spinner-with-character.
**Specification**: shimmer placeholder matching the eventual layout; wallet shows "…" not "0" while loading (currency #7). No `NullPointerException` on null-before-first-snapshot (data-persistence #4 AC).
**When to use**: any `snapshots()`/`FutureProvider`-backed content on cold start.
**When NOT to use**: instant local computations (energy) — no perceptible wait.

### P6 — Empty state
**Category**: Data display · **Used In**: Pending tasks (parent), task history, shop (unseeded)
**Description**: A data list with zero items shows a friendly message, not a blank area or error.
**Specification**: short reassuring copy ("Chưa có nhiệm vụ nào chờ duyệt"); primary actions remain available (e.g., FAB "+" still usable). Never an error styling — empty is normal.
**When to use**: every data-dependent list/grid.
**When NOT to use**: n/a — every data list needs one (cross-reference check enforces this).

### P7 — Coalescing in-app banner (foreground FCM)
**Category**: Feedback / Overlay · **Used In**: Parent Dashboard foreground notification
**Description**: When a push arrives while the app is foregrounded, show one lightweight banner that live-updates in place rather than stacking.
**Specification**: `MaterialBanner` slide-down + fade 200ms; **exactly one banner** — a 2nd/3rd message live-updates its text via `unseenCount` ("N nhiệm vụ mới đang chờ"), never spawns a second banner (parent-dashboard #21 Core Rule 6). **Defers** while any modal (sheet/dialog) is open; shows after the modal closes. Manual-dismiss only (tap/swipe) — no auto-dismiss; coalesced banner uses the *same* visual weight as a single one (no escalating alarm — Pillar 4).
**When to use**: foreground push while parent is in-app.
**When NOT to use**: background push (OS tray handles it, grouped).

### P8 — Icon+color state feedback (never color-alone)
**Category**: Feedback · **Used In**: Approve/reject flash, warnings, mood/energy
**Description**: Any state communicated with color also carries an icon/shape.
**Specification**: approve = Mint Breeze 20% flash + ✓; reject = neutral peach-grey + ✕ (**not red**); warnings use ⚠️ (Art Bible Colorblind Safety). 150ms flash → 200ms collapse for resolved task cards (parent-dashboard #21). No particle/confetti here — that vocabulary is reserved for Mochi celebration.
**When to use**: every success/failure/warning indication.
**When NOT to use**: never rely on color alone (WCAG 1.4.1 — accessibility §2).

### P9 — Canvas sprite tap/swipe with per-type cooldown
**Category**: Input · **Used In**: Petting/interacting with Mochi
**Description**: Direct manipulation of the Flame sprite via `TapCallbacks`/`DragCallbacks`, each interaction type independently rate-limited.
**Specification**: tap cooldown 1.0s, swipe 2.0s, independent (pet-interaction #14). Swipe = distance ≥40dp AND duration ≤300ms. **Hit-area ≥80×80dp** regardless of sprite size (accessibility §1). Emits `petInteracted` directly into `GameEventBus` (ADR-0004 §3b). Never `TapDetector` (deprecated).
**When to use**: direct play interactions on the canvas.
**When NOT to use**: Flutter-widget controls (use standard gesture widgets).

### P10 — PIN entry (dot display + numpad + lockout)
**Category**: Input · **Used In**: Child profile selection
**Description**: 4-digit PIN entry tuned for children.
**Specification**: 4 chibi dot slots that fill as digits are entered (not a text field); chibi numpad; on 3 wrong attempts, 60s lockout with a visible countdown (auth #1). Verified client-side via PBKDF2 (ADR-0002). Reset PIN dialog uses a real PIN-entry field, not a bare confirm (parent-dashboard #21).
**When to use**: child profile auth only.
**When NOT to use**: parent auth (email/password), which uses standard fields.

### P11 — Task submit ("Đã xong!") → seed drop
**Category**: Input / Feedback · **Used In**: Task submission
**Description**: Completing a task instance is one decisive tap with immediate, satisfying local feedback while approval is pending.
**Specification**: pick preset/custom or type a title → "Đã xong!" CTA → creates the `pending` task and plays a local seed-drop burst + independently-reactive seed counter (task-mgmt #19 simplified the cross-widget choreography). Reward is NOT granted here (only on parent approve). Staggered catch-up on multi-approve: `total = burst + (N−1)×stagger`, N≤10 (task-mgmt #19).
**When to use**: child task submission.
**When NOT to use**: parent-side task creation (that writes a *template*, no seed drop — parent-dashboard #21).

### P12 — Reactive counter/wallet display
**Category**: Data display · **Used In**: xu wallet (floating chip), seed count, chest count
**Description**: A number bound to a realtime provider, always visible, updates in place.
**Specification (amended 2026-07-14 — see `design/ux/hud.md` HUD Elements #2)**: xu wallet always visible as a floating chip (top-left cluster, grouped with the Profile chip — no longer an "app bar," per nav #17's HUD-spec correction); integer only, no decimals; Honey Gold `#FFD060` coin icon 18dp + value 14sp (nav #17); clamps a negative value to 0 in display (ADR-0008 §5). Earn/spend micro-animation now specified concretely: count-up tween (~400ms) plus a reward-triggered scale-pulse — see HUD spec for full detail.
**When to use**: persistent economy counters the child should always see.
**When NOT to use**: transient values.

### P13 — Bottom-nav tab shell (branches never disposed)
**Category**: Navigation · **Used In**: Child (3-tab) + Parent (2-tab) shells
**Description**: `go_router` `StatefulShellRoute` with per-branch navigators; switching tabs never disposes the other branch.
**Specification**: "is this screen active" must be read from `activeChildBranchIndexProvider`, NOT widget lifecycle (branches stay mounted — nav #17 / ADR-0002-adjacent). Child nav: icon 28dp, label 11sp, active = Peach Glow. Route guard is a pure function of `sessionStateProvider` (ADR-0002).
**When to use**: top-level tabbed navigation.
**When NOT to use**: ephemeral overlays (use P3/P4).

### P14 — Post-acquisition "Equip now?" prompt (reused verbatim)
**Category**: Modal · **Used In**: Shop purchase result, Gacha reveal result
**Description**: After acquiring an equippable item, offer to equip it immediately — the SAME prompt for both shop and gacha paths (not redesigned per source).
**Specification**: shown ~250ms after the reveal so the child can read the item name first (shop-reward #20 Formula 2). "Mặc ngay" auto-navigates to Pet Room so the equip is actually visible (review-all-gdds Scenario fix; shop-reward #20 Core Rule 6b). Reused verbatim by gacha (gacha #12 owns trigger, shop #13 owns the prompt UI).
**When to use**: acquiring an equippable item.
**When NOT to use**: acquiring xu/consolation (nothing to equip).

### P15 — Deep-link entry → route to target
**Category**: Navigation · **Used In**: Notification tap
**Description**: An external `petquest://` URI opens the app at a specific destination, respecting the session-state route guard.
**Specification**: `petquest://parent/tasks/pending` → parent pending-tasks view (push #10 / ADR-0010 owns the URI; nav #17 owns the `go_router` route resolution + OS scheme registration). If not in parent session, the route guard mediates (may require parent override).
**When to use**: notification / external entry points.
**When NOT to use**: in-app navigation (use P13 / normal routes).

### P16 — Long-press to enter privileged mode
**Category**: Navigation · **Used In**: Main Navigation Shell (Profile chip → Parent Override)
**Description**: A long-press (not a tap) on an otherwise-informational element reveals a hidden path into a more privileged/adult session, gated by a password confirm.
**Specification**: Hold duration ≥600ms (tunable — `long_press_duration` knob, 400–1000ms safe range). Triggers a confirm bottom sheet (P3) stating what's about to happen in plain language, not an immediate mode switch. The underlying session is never disposed by entering privileged mode — it's a state overlay, not a logout. Wrong credentials show an inline error and leave the sheet open; no lockout is currently defined for this path (see main-navigation-shell.md Open Questions).
**When to use**: a casual, low-friction gesture must not accidentally reveal a more powerful/adult surface to the primary (child) user — the long-press duration is deliberately longer than a normal tap to avoid accidental triggers, but shorter than requiring a separate menu.
**When NOT to use**: any action that should be quick/frequent (long-press adds friction by design here) or that doesn't need a privilege boundary.

### P17 — Disruption-not-destruction confirm dialog
**Category**: Modal · **Used In**: Main Navigation Shell (Child tab root back-press → "Thoát PetQuest?")
**Description**: A confirm dialog for an action that's disruptive/easy to trigger by accident (e.g. a stray back-press) but not actually destructive or irreversible — distinct from **P2** (Confirm-before-destructive dialog), which is reserved for genuinely irreversible/economy-affecting actions.
**Specification**: Kid-styled copy and tone (short, friendly, no consequence-framing language like "cannot be undone" — because nothing is being undone). [Cancel/stay] always first or equally prominent, no red/alarming color (same Art Bible no-red rule as P2, but for a different reason — this isn't a warning, it's a friendly check-in). Only shown on tab-root screens, not on every back-press.
**When to use**: exiting a flow that's easy to trigger accidentally (an app-level back-press) where the "cost" of the action is disruption (losing your place) rather than data loss.
**When NOT to use**: anything that actually deletes, resets, or spends something — use P2 instead.

### P18 — Conditional selector (hide when only one choice exists)

**Category**: Input · **Used In**: Parent Dashboard create-custom-task sheet (child selector, parent-dashboard #21)
**Description**: A selector control that is only rendered when there is more than one real choice — if the underlying set has exactly one member, the control is hidden entirely and that single value is auto-assigned, rather than showing a disabled or pre-filled single-option picker.
**Specification**: Compute the candidate set's length first. If `length == 1`: hide the control, auto-assign that single value to the target field at save/commit time — do not render a disabled dropdown or a picker pre-set to the only option. If `length > 1`: render the full selector, no default pre-selection unless the GDD specifies one. Verify the auto-assigned value via a read-back check when it feeds a write path with no other validation (parent-dashboard #21 Core Rule 3 — a wrong auto-assigned ID silently corrupts data with zero observable UI symptom).
**When to use**: any selector whose candidate set can legitimately be exactly one member in normal use (e.g. single-child families) — not for sets that are merely temporarily empty or loading.
**When NOT to use**: sets that can be zero (need an empty state, not a hidden selector) or where showing the single option is itself informative (e.g. confirming *which* item you're about to act on).

---

## Gaps & Patterns Needed
- **Onboarding / first-run flow** patterns (account creation, first child profile, permission request framing) — Onboarding (#24) is Alpha-tier, not yet designed. The notification-permission request (positive framing) is referenced by push #10 but its screen isn't specced.
- **Reduced-motion variants** for P4 ceremonies — newly required by accessibility §6; each ceremony spec must define one.
- ✅ **RESOLVED 2026-07-14**: Contrast-verified color tokens — the WCAG audit ran 2026-07-13/07-14 (`design/accessibility-requirements.md` §3); Primary/Secondary/Disabled/On-color roles are all now AA-safe. Patterns referencing text color (P8, P10, P12) should use the corrected hexes.

## Open Questions
- These patterns are extracted from GDDs, not yet validated by `/ux-review` — run it on the first authored screen spec to confirm the pattern contracts hold in a concrete layout.
- P3 vs P4 boundary (sheet vs full-screen ceremony) is clear for current screens; confirm it holds when new screens are added.
- Player journey map (`design/player-journey.md`) doesn't exist — patterns assume journey context that should be validated when it's created.
