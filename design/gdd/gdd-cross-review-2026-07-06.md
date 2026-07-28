# Cross-GDD Review Report

**Date:** 2026-07-06
**Mode:** full (3 parallel phases: Consistency, Design Holism, Scenario Walkthrough)
**GDDs Reviewed:** 21 (all MVP-tier system GDDs, all independently reviewed and Approved earlier the same day)
**Systems Covered:** Auth & Account · Time & Decay · Item Database · Data Persistence Layer · Flutter-Flame State Bridge · Pet State Machine · Currency System · Task Library · Push Notification · Seed Buffer · Parent Approval · Gacha/Loot · Shop System · Pet Interaction · Pet Equipment · Pet Leveling & Evolution · Main Navigation Shell · Pet Room Screen UI · Task Management UI · Shop & Reward UI · Parent Dashboard UI
**Entity Registry:** 3 formulas, 21 constants — used as conflict baseline for Phase 2

---

## Verdict: CONCERNS (all three phases)

Every individual GDD in this project has already been independently reviewed and had real defects fixed. This holistic pass — looking at the 21 GDDs *together*, and specifically at how today's many propagated fixes interact with each other — found a further, different class of defect: problems invisible from any single document. None require reopening core architecture; all are targeted fixes.

---

## Phase 2 — Cross-GDD Consistency: CONCERNS

### Blocking

🔴 **B1 — Pet Interaction (#14) missing Pet Room Screen UI (#18) from its Downstream table**, despite #18 depending on #14 and #14 explicitly delegating hit-area implementation to #18. This falsifies #18's own self-reported "7/7 upstream GDDs confirmed bidirectional" claim.

🔴 **B2 — Item Database (#3) missing Pet Room Screen UI (#18) from its Downstream table**, despite #18 reading `itemCatalogProvider` directly for the Wardrobe grid. Same falsification pattern as B1 — 2 of #18's claimed "7/7" are actually wrong.

🔴 **B3 — Parent Dashboard UI (#21) claims "no downstream dependents"**, but Task Management UI (#19) has a hard upstream dependency on #21's `customTasks` collection. The resolution was applied in #21's own Open Questions but never propagated into its formal Dependencies table.

🔴 **B4 — Internal self-contradiction in `auth-account.md`**: the Interactions table correctly documents today's fix (Main Nav Shell reads `sessionStateProvider`, not `authStateProvider`), but the Dependencies → Downstream table further down in the *same file* still says `authStateProvider`. (Main Nav Shell itself implements the correct fixed version — this is a documentation-only inconsistency, not a live bug.)

🔴 **B5 — "Approved" status labeling inconsistency, project-wide.** `systems-index.md` marks all 21 MVP GDDs "Approved," but 9 of them (`push-notification.md`, `seed-buffer.md`, `gacha-loot.md`, `shop-system.md`, `pet-interaction.md`, `pet-equipment.md`, `main-navigation-shell.md`, `shop-reward-ui.md`, `pet-room-screen-ui.md`) have their own status header still reading "Reviewed — NEEDS REVISION/APPROVED WITH CONCERNS ... fixed same day" rather than a clean "Approved." Two cross-references (`shop-system.md`'s citation of Gacha/Loot, `main-navigation-shell.md`'s citation of Shop & Reward UI) mark those GDDs "✅ Approved" when their own headers don't yet say that.

### Warnings

⚠️ W1 — `auth-account.md`'s "App Session States" table uses snake_case (`parent_authed`) while the actual `SessionState` enum uses camelCase (`parentAuthed`) — cosmetic naming drift within one file.
⚠️ W2 — SHOWING_OFF duration (2000ms) is listed as an owned Tuning Knob in both `pet-state-machine.md` and `pet-equipment.md`, with neither disclaiming the other as canonical (values currently agree — no active bug, but no single source of truth).
⚠️ W3 — `currency-system.md` restates item-price Tuning Knobs (10–200 xu) without a "not redefining, see item-database.md" cross-reference.
⚠️ W4 — `currency-system.md`'s per-category `xuReward` table is still labeled "provisional" despite Task Library being Approved with matching locked values.
⚠️ W5 — `currency-system.md`'s Sinks table omits the Paid Chest (50 xu) sink entirely.
⚠️ W6 — Minor "Last Updated" metadata drift in `shop-reward-ui.md` and `push-notification.md` (5 days stale in the latter).
⚠️ W7 — `parent-approval.md`'s chestCount write doesn't state the `FieldValue.increment()` mechanism explicitly the way `gacha-loot.md`'s reasoning does — asymmetric documentation of a correctly-safe composition.

---

## Phase 3 — Game Design Holism: CONCERNS

### Blocking

🔴 **Dominant strategy in the task-reward economy.** Task Library's reward table makes Study/Arts strictly Pareto-dominant over Chores/Sport/Helping on BOTH xu and energy simultaneously (20xu/30energy vs. 10xu/20energy) — a rational child has zero incentive to ever log Helping tasks. This directly undermines the game's own stated goal of encouraging a *balanced* spread of real-world discipline (the elevator pitch treats "làm bài tập, quét nhà, tập đàn" as equally valid). Not fixable by moving values within existing Tuning Knob ranges — the two reward axes are correlated by design, so any point on the current ranges preserves the dominance. Requires a structural change: decouple the axes so each category has a genuine trade-off, or normalize total reward-value and differentiate only by flavor.

🔴 **`main-navigation-shell.md` cites a fabricated Pillar 3.** Its header claims "Pillar 3 — Trải Nghiệm Đơn Giản Cho Bé (navigation simplicity)," but `game-concept.md`'s canonical Pillar 3 is "Khoe Đẹp, Không Đánh Nhau" (show off, don't fight — the anti-PvP social pillar), which has nothing to do with navigation. This masks a legitimate-but-unstated gap: real Pillar 3 has zero MVP implementation (acceptable, since social systems are all Alpha-tier) — but it should say so honestly rather than cite an invented pillar text.

### Warnings

⚠️ Attention budget: ~7–8 concurrently-live systems in MVP alone (task creation, seed-tracking, interaction, wardrobe, shop, gacha, leveling, navigation) — well above even the adult 3–4 comfort baseline, worse for the 6-10yo target age, with no documented progressive-disclosure/onboarding sequencing.
⚠️ Economic content-runway: dual acquisition channels (Shop + frequent free Gacha chests) likely exhaust the 30-item MVP catalog within weeks of engaged play — before Alpha content ships. Combined depletion rate isn't modeled anywhere (each GDD models its own channel in isolation).
⚠️ Pillar 5 ("Mỗi Bé Có Thế Giới Riêng")'s own design test requires "≥3 customization layers" — technically arguable via 3 equip slots, but weak in spirit given Room (the pitch's headline customization vehicle, *"bé trang trí phòng theo ý thích"*) is entirely absent from MVP.
⚠️ Gacha's outcome-randomness is in real tension with Pillar 1/2's "pure merit, effort accurately reflected in appearance" framing — only *access* to chests is merit-gated, not the *specific item* received. Currently addressed narratively, not structurally.
⚠️ NEW drift found: `game-concept.md`'s Long-Term Progression says "Level 1→10 by Month 3," but `pet-leveling-evolution.md` hard-caps MVP at 5 levels / 3 evolution stages. Distinct from the already-known Gacha/Room MVP-scope drift — same root cause (an unreconciled early Draft), different specific claim.

---

## Phase 4 — Cross-System Scenario Walkthrough: CONCERNS

Walked 5 scenarios: (1) the "mega-approve" (level-up + chest milestone in one transaction), (2) chest-purchase → ceremony → equip chain, (3) child switches tabs mid-animation, (4) parent override mid-child-session, (5) offline submission → reconnect → multiple queued approvals.

### Blockers

🔴 **Scenario 1 — Undefined event-type contract for EXCITED.** Parent Approval emits `GameEvent(petMoodChanged → EXCITED)`, but the Bridge's `petMoodChanged` event type is typed for `PetMood` (Base Mood enum: HAPPY/CONTENT/TIRED/SAD/SLEEPING) — EXCITED is a **Triggered State**, a structurally different enum. Per the Bridge's own Edge Cases, a type-mismatched cast throws a runtime `TypeError`. No GDD defines a distinct `GameEventType` for "approve happened → play EXCITED" the way `petLeveledUp`/`itemEquipped`/`petInteracted` each are.

🔴 **Scenario 2 — SHOWING_OFF is architecturally invisible for the two most common equip paths.** Mochi's sprite and the SHOWING_OFF spin live exclusively in Pet Room Screen UI's (#18) FlameGame on `/child/pet-room`. Every equip triggered from Shop & Reward UI (#20) — via direct purchase OR via gacha reveal — happens while the child is on `/child/shop`, which dismisses back to the Shop tab, never navigating to Pet Room. The "equipped overlay spins with Mochi" feature added today during #15's review fix is unobservable through the two most common on-ramps into equipping.

🔴 **Scenario 3 — Chest Open ceremony has no defined behavior for tab-switch interruption.** Main Nav Shell's Core Rule 1 scopes the ceremony's `Navigator.push` to the branch's own Navigator (not root) — meaning the bottom nav bar (owned by the outer shell) most plausibly remains visible/tappable *above* the full-screen, explicitly non-dismissible ceremony. No GDD defines what happens if the child taps a different tab mid-ceremony.

🔴 **Scenario 5 — Mochi's evolution sprite can permanently desync after offline catch-up crossing 2+ level thresholds.** If a child is offline while a parent approves enough tasks to cross 2 level thresholds (e.g., L2→L3) in separate transactions, the child's device likely only observes the *final* `petLevel` snapshot on reconnect, not each intermediate write. Since the evolution-sprite-swap is specified as a one-shot side effect of the transition *event* (not a pure function of current `petLevel`), an intermediate evolution stage (e.g., Baby→Young at L2) can be silently skipped forever — `petLevel` is correct in Firestore, all xu/chest bonuses are correctly credited, but Mochi's sprite is stuck one stage behind with no error signal.

### Warnings

⚠️ The single richest reward moment in the game (level-up + 2 chests in one approve) is visually indistinguishable from a routine approve in Task Management UI's card burst — no distinct callout.
⚠️ Main Nav Shell's generic "unsaved data will be lost" warning fires even when overriding mid-Wardrobe-equip, where nothing is actually unsaved (every equip is individually persisted with no Save button) — a false alarm.
⚠️ "Resume where you left off" after a parent override always returns to `/child/pet-room` (Tab 1 default) regardless of which tab/sub-screen the child was actually on.
⚠️ Whether Flame/widget state survives the `/child/*` ↔ `/parent/*` top-level route boundary (as opposed to sibling-tab switching, which is explicitly guaranteed) is never confirmed by any GDD.
⚠️ Shop & Reward UI's `onAnimationComplete` interface is self-flagged as not yet existing on Shop System's side — the crux of its whole timing contract, worth escalating rather than leaving as a footnote.

---

### GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| pet-interaction.md | Missing #18 in Downstream table | Consistency | Blocking |
| item-database.md | Missing #18 in Downstream table | Consistency | Blocking |
| parent-dashboard-ui.md | "No downstream dependents" claim is false | Consistency | Blocking |
| auth-account.md | Self-contradicting provider reference | Consistency | Blocking |
| 9 GDDs (see B5) | Status header not re-stamped "Approved" after fixes | Consistency | Blocking |
| task-library.md | Dominant-strategy reward structure | Design Theory | Blocking |
| main-navigation-shell.md | Fabricated Pillar 3 citation | Design Theory | Blocking |
| flutter-flame-state-bridge.md | Missing GameEventType for EXCITED trigger | Scenario | Blocking |
| pet-room-screen-ui.md / shop-reward-ui.md | SHOWING_OFF unobservable via Shop/Gacha equip paths | Scenario | Blocking |
| shop-reward-ui.md | No tab-switch guard for Chest Open ceremony | Scenario | Blocking |
| pet-leveling-evolution.md | Evolution stage as side-effect (not pure function) risks desync | Scenario | Blocking |

### Verdict: CONCERNS (all 3 phases — no FAIL, no clean PASS)

---

## Resolution Log (2026-07-06, same day)

All Blocking findings from all 3 phases were resolved same-day:

- **B1, B2** (missing #18 in `pet-interaction.md`/`item-database.md` Downstream tables) — fixed.
- **B3** (`parent-dashboard-ui.md`'s false "no downstream dependents" claim) — fixed, added #19 row.
- **B4** (`auth-account.md` self-contradicting provider reference) — fixed.
- **B5** (9 GDDs' status headers not re-stamped "Approved" after fixes) — all 9 re-stamped: `push-notification.md`, `seed-buffer.md`, `gacha-loot.md`, `shop-system.md`, `pet-interaction.md`, `pet-equipment.md`, `main-navigation-shell.md`, `shop-reward-ui.md`, `pet-room-screen-ui.md`.
- **Dominant strategy in task rewards** — economy-designer consulted. New table: study/arts 25xu/20energy, chores/sport/custom 15xu/25energy, helping 10xu/30energy — a strictly decreasing Pareto frontier (xu↓ as energy↑), no category dominates another on both axes. Propagated to `currency-system.md`, `time-decay.md`, and 5 registry constants (`task_xu_reward_study/arts`, `task_energy_reward_study/arts/helping`).
- **Fabricated Pillar 3 citation** (`main-navigation-shell.md`) — corrected to honestly state this is Foundation/Infrastructure serving Pillars 2/4 structurally, not a direct pillar implementation.
- **Scenario 1** (undefined `EXCITED` event-type, TypeError risk) — new `taskApproved` GameEventType added to the Bridge; `parent-approval.md` and `pet-state-machine.md` updated.
- **Scenario 2** (SHOWING_OFF unobservable via Shop/Gacha equip paths) — `shop-reward-ui.md` now auto-navigates to `/child/pet-room` after "Mặc ngay" from either path.
- **Scenario 3** (no tab-switch guard for Chest Open ceremony) — ceremony now pushed via root navigator (not branch-scoped), which structurally blocks tab-switching while it's open; documented in both `main-navigation-shell.md` and `shop-reward-ui.md`.
- **Scenario 5** (evolution-sprite permanent desync after offline multi-level-skip) — `pet-leveling-evolution.md`'s Core Rule 8 now makes evolution stage a pure function of `petLevel`, recomputed on every load, independent of whether the transition event was witnessed.
- **Warnings W2–W7** (Tuning Knob duplicate ownership, stale "provisional" labels, missing Sinks row, asymmetric write-mechanism documentation) — all fixed.

Warnings not acted on (flagged, left for future attention, not blocking): attention-budget concerns for the 6-10yo age band (no progressive-disclosure design proposed), economic content-runway modeling (dual Shop+Gacha depletion rate), Pillar 5's weak-spirit MVP compliance, Gacha's outcome-randomness tension with Pillar 1/2's merit framing, and `game-concept.md`'s internal drift (Level 1→10 claim vs. the 5-level MVP cap) — this last one folds into the already-planned `game-concept.md` MVP Definition reconciliation.
