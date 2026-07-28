# Review Log: Building UI

Target: `design/gdd/building-ui.md`

## Review — 2026-07-10 — Verdict: MAJOR REVISION NEEDED
Scope signal: L
Specialists: game-designer, ux-designer, ui-programmer, systems-designer, godot-specialist, qa-lead + creative-director (synthesis)
Blocking items: 4 (merged clusters) | Recommended: 6
Summary: The toolbar/palette/stepper/undo/time-controls ~70% of the doc is
strong (minor findings only). But the toast/notification subsystem was
internally incoherent (Rule 9 vs Edge Case 1 contradicted on eviction —
append-starvation vs bump-livelock; no identity/dedup key → Shown→Queued
flicker on level-triggered re-emits; no severity priority — Info could
evict an undismissed Warning; stale warnings had NO retirement path),
failed Build Validation's four-item UI seam contract IN FULL (0/4 — item
2 was the named, pre-flagged Rule 9 contradiction), and AC11/12 actively
VALIDATED the prohibited behavior. All six specialists converged on the
toast subsystem. CD: cannot be patched, only redesigned → MAJOR (focused
— one subsystem rebuilt, the rest stands).
Prior verdict resolved: First review

### Blockers (all fixed in-session, grep-verified)
1. **Toast subsystem rebuild** [ALL SIX specialists]: Rule 9 rebuilt as
   identity → severity → lifecycle model: (signal, subject) dedup key
   (re-emits idempotent); `warning_grace_delay` first-appearance grace
   (seam 3); `min_reshow_interval` dismissal debounce (seam 2 — the
   named contradiction retired); auto-retire on cause cessation +
   Warning→Info tier-swap reconcile (seam 4); severity-tiered eviction
   with **USER RULING: warnings never evicted**, anchor = overflow home,
   hidden FIFO queue deleted (no starvation/livelock). New Rule 9c
   **issues anchor** (**USER RULING: toast-area anchor + expandable live
   list** from queryable state, hidden at zero) = seam item 1. Per-key
   lifecycle table rewritten. AC11/12 rewritten + AC27-32 added.
2. **Rule 2 self-contradiction** [ui-programmer + qa-lead]: rewritten to
   "no simulation-authoritative state" + exhaustive presentation-memory
   carve-out (material memory / toast state / timers — verified to have
   no upstream home).
3. **Celebration double-presentation** [game-designer]: **USER RULING:
   in-world only** — new Rule 9d: `room_recognized` not consumed, no
   confirmation toast, `toast_confirm_fade` deleted, AC35; reciprocal
   note in build-validation-navigability.md (its seam flag marked
   RESOLVED).
4. **Accessibility** [ux-designer]: **USER RULING: minimal keyboard
   set** — Rule 9b actions (toast_focus_cycle/toast_dismiss/
   toggle_issues/palette_next/prev; bindings [assumption] → /ux-design),
   Rule 12 registration, AC33/34/36; toast tiers differentiated by icon
   SHAPE + label (hue-alone retired, Visual Direction Note §4).

### Recommended items applied
R1 Rule 11 event-routing requirement (suppression = queryable flag on
pick starts; HUD never consumes a drag's release — godot) · R2 Edge Case
6 explicit Suspended-tied timer pause, resume-with-remaining, Godot
Tween/Timer note · R3 Rule 7 key-repeat scoping (rate untested by
design) + OQ6 velocity cap · R4 OQ7 post-4.3 verification (mouse_filter,
4.6 dual-focus, 4.5 AccessKit) · R5 pause-mirror reconciled (signals +
returned state, Rule 2) + Edge Case 12 double-tap race · R6 stale
upstream rows → Approved. Minors: AC3 un-highlight, Summary/Cross-Refs
updated, toast_max_visible min 2.

### CD notes
- Inspection surface ruled a SCOPE-decision blocker (new HUD surface),
  resolved by user choice, not silent authoring.
- Celebration fix ruled "likely deletion" — confirmed by user.
- Cluster F (engine mechanisms) explicitly non-blocking/authorable.

### State after revision
ACs 26 → 36 (22+10 blocking / 4 advisory). Core Rules 12 → 12+9b/9c/9d.
Edge Cases 10 → 12. Knobs: +min_reshow_interval(30s), +warning_grace_delay(3s),
−toast_confirm_fade; toast_max_visible range 2–5. New OQ6/OQ7. Files:
building-ui.md + build-validation-navigability.md (seam-resolution note).
**Re-review pending in a fresh session** (rebuilt Rules 9–9d are new
design — needs fresh adversarial eyes).

## Review — 2026-07-10 — Verdict: NEEDS REVISION (narrow) → revised → APPROVED
Scope signal: M (down from L — the rebuild held)
Specialists: game-designer, ux-designer, ui-programmer, systems-designer, godot-specialist, qa-lead + creative-director (synthesis) + fresh qa-lead verification pass (14 points)
Blocking items: 6 | Recommended: 5 (+minors)
Summary: RE-REVIEW. All 4 prior blockers + the four-item seam contract
VERIFIED RESOLVED by 6 specialists — the rebuilt identity→severity→
lifecycle model held structurally. New findings all sat inside the
rebuilt subsystem: the grace clause was UNSATISFIABLE as worded
(re-emission-counting vs. event-driven upstream that emits once — qa-lead
blocking, interlocking with systems-designer's pause degeneracy);
anchor→visible promotion undefined (4-way convergence — the round's one
design fork); mid-Grace tier-swap bookkeeping undefined (3-way); AC30's
same-pass detection had no spec basis; pause-mirror two-writer race
RE-OPENED; keyboard still partial (stepper + roof picker). CD: one user
ruling + one authorable cluster → build-validation round-2 pattern.
Prior verdict resolved: Yes (all 4 held)

### Fixes applied (all verified by the 14-point fresh pass — CLEAN)
1. **Grace clock rewrite** (the blocker): grace + debounce = UI-local
   WALL-CLOCK timers per subject, started on first emission, expiry
   checked against queryable state (no re-emissions required); freeze
   only on Suspended, never game pause. AC27 rewritten + AC40.
2. **Promotion — USER RULING: auto-promote**: longest-waiting
   anchor-only Warning promotes into a freed slot immediately (grace
   served); dismissed keys respect remaining debounce and are skipped;
   Info promotes only when no Warning waits. Lifecycle table + AC37.
3. **Tier-swap bookkeeping per SUBJECT**: Shown→swap = Info immediate;
   Grace→swap = credit transfers, no restart; debounce never carries.
   AC38.
4. **Same-pass grounding**: reciprocal build-validation Rule 10 note —
   all emissions of one pass delivered synchronously in one frame =
   the reconciliation unit (warning/info signals carry no pass id).
5. **Pause-mirror single-writer**: time-control display written
   exclusively from returned state; stale signals never overwrite
   (Rule 2 + Edge Case 12).
6. **Keyboard completed**: +formation_next/prev, height_step_up/down
   (9 actions total, Rule 9b/12, AC36/39) — "no persistent element is
   mouse-only" now true.
Also: Edge Case 13 (focus handoff on toast retire — OQ7 upgraded to
BLOCKING for Rule 9b implementation, + echo semantics); OQ8 (central
timer manager); celebration zero-persistence asymmetry acknowledged in
Rule 9d; Rule 2 scoped list completed; toast_max_visible=2 rationale
corrected (rotating-Info slot = best-effort); AC31 schema [assumption];
OQ1 + onboarding beats + Tab collision; stale-status sweep across BOTH
docs (6 building-ui upstream rows + 4 build-validation rows — second
recurrence of the staleness class, swept by grep this time).

### Verification pass
Fresh qa-lead, 14 points, rewritten state machine walked as NEW LOGIC
(grace satisfiability, promotion coherence, tier-swap key bookkeeping):
**OVERALL: CLEAN** on first pass. ACs now 41 (26 → 36 → 41).

**Building UI = APPROVED 2026-07-10** (user pre-authorized
approve-on-clean via the re-review path decision). 10/11 MVP GDDs
approved. Remaining: villager-info-ui (its review must confirm the
sibling click-ownership contract and its half of the Build Validation
room-status seam).
