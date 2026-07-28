# Story 014: Toast lifecycle B — debounce, promotion, reconciliation & tier-swap

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/hud.md` (element E5 — "per analysis pass (P1 reconcile)", retire fade ≤ 0.2 s)
**Requirement**: `TR-building-ui-018`, `TR-building-ui-056`, `TR-building-ui-057`, `TR-building-ui-058`, `TR-building-ui-053`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (UI Timer & Expiry Management)
**ADR Decision Summary**: The same centralized manager backs the **per-key dismissal debounce window** as backs grace — one `Dictionary[key, TimerRecord]`, one shared loop, raw-delta, pause-immune, Suspended-frozen with exact remaining time. There is no second timer class for debounce.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: **All emissions of one Build Validation analysis pass arrive synchronously within one frame** — same-frame delivery IS the reconciliation unit (its Rule 10's reciprocal note). This is load-bearing: reconcile at the end of a pass's synchronous delivery, not on a timer or a deferred call. Build Validation has a **no-cleared-signal model** — a cause going away produces *silence*, never a "resolved" event.

**Control Manifest Rules (this layer)**:
- Required (Presentation): a key whose emissions cease is **auto-retired** — toast and anchor entry removed within one reconcile. Solved problems never require a manual dismiss.
- Forbidden: requiring a re-emission to re-show a debounced toast (the queryable state decides); carrying a dismissal-debounce window across a tier swap; restarting grace on a tier swap; treating the anchor as a graveyard.
- Guardrail: **dismissal hides a toast, never the record** — the issue stays in the anchor list.

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md` Rule 9 (debounce/promotion/reconciliation/tier-swap) + Edge Case 11, scoped to this story:*

- [ ] **AC11 (debounce)**: Given a dismissed warning toast, When its key re-emits within `min_reshow_interval`, Then the toast stays hidden **while its anchor entry persists**; When the window elapses and the cause still holds in the **queryable state**, Then the toast re-shows — **no re-emission required** (`TR-building-ui-018`).
- [ ] Dismissing a toast starts `min_reshow_interval` for **its key** using the same wall-clock timer class as grace; at window expiry the queryable state decides: cause holds → re-show; cause gone → the entry was already retired by reconciliation (`TR-building-ui-018`).
- [ ] **AC37 (promotion)**: Given `toast_max_visible` Warnings shown and one anchor-only Warning, When a visible Warning retires or is dismissed, Then the **longest-waiting** anchor-only Warning is promoted into the freed slot **immediately** — grace was already served; Given the promotion candidate was previously dismissed with `min_reshow_interval` remaining, Then it is **skipped** and the next-longest eligible key promotes instead (`TR-building-ui-056`).
- [ ] Info promotes **only** when no anchor-only Warning waits (`TR-building-ui-056`).
- [ ] **AC29 (auto-retire)**: Given a shown warning whose emissions cease (cause fixed), When the next reconcile runs, Then the toast and its anchor entry are removed **with no player dismissal** (Edge Case 11, `TR-building-ui-057`).
- [ ] Reconciliation runs against **each analysis pass's emissions plus the queryable state**, with one pass's synchronous same-frame delivery as the unit — never a timer, never a deferred sweep (`TR-building-ui-057`).
- [ ] **AC30 (tier-swap)**: Given a subject whose Warning ceases while an Info begins **in the same pass**, Then the Warning toast retires and the Info toast appears — at **no point** are both visible for that subject (`TR-building-ui-058`).
- [ ] **AC38 (grace credit)**: Given a Warning in Grace with 2 s elapsed of a 3 s `warning_grace_delay`, When it tier-swaps to Info, Then the Info key **inherits the elapsed credit** and surfaces after 1 s more if the cause holds — **no grace restart**, so a flickering cause can never indefinitely suppress surfacing (`TR-building-ui-058`).
- [ ] A tier-swap of an **already-Shown** Warning shows the Info **immediately** (grace was served by the Warning) (`TR-building-ui-058`).
- [ ] An active dismissal-debounce window on the retiring Warning does **NOT** carry to the Info — a tier change is new information the player has not dismissed (`TR-building-ui-058`).
- [ ] Tier-swap bookkeeping is **per SUBJECT across keys**, not per key (`TR-building-ui-058`).
- [ ] Debounce timers freeze on Suspended and resume with remaining time, exactly as grace does (`TR-building-ui-053`, Edge Case 6).
- [ ] `min_reshow_interval` (default 30 s, 10–120 s) comes from `BuildingUiConfig`.
- [ ] Toast **retire** animates with a fade ≤ 0.2 s; appear is instant (hud.md E5, A5 motion restraint).

---

## Implementation Notes

*Derived from Rule 9's seam items 2 and 4 plus the 2026-07-10 re-review's promotion and per-subject rulings:*

- **Per-subject vs per-key is the trap.** Grace credit and tier-swap live on the **subject**; dismissal debounce lives on the **key** (signal type + subject). Keep two maps, or one subject record holding per-key sub-state — but be explicit, because AC38 (credit transfers) and the "debounce does not carry" clause pull in opposite directions on the same swap.
- **Reconciliation is a diff, not a subscription.** Collect the set of keys emitted during one pass's synchronous delivery; at the end of that delivery, every live record whose key is absent **and** whose cause is absent from the queryable state is retired. Build Validation never sends a "cleared" signal — silence is the signal.
- Promotion must run **after** retirement within the same reconcile, so a freed slot is filled in the same frame it opened. "Longest-waiting" = earliest `first_seen_at` among eligible anchor-only records; eligibility excludes keys with a live debounce window.
- Re-show at debounce expiry queries state — do **not** wait for a re-emission. This is the same "wall-clock + state check" shape as grace; reuse the code path, don't fork it.
- Retire fade: the record is removed from the model **immediately** at reconcile; the ≤ 0.2 s fade is the view's exit animation only. Never model a "fading out" phase — that reintroduces the state a solved problem is supposed to leave.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 013: identity/dedup, grace, severity, cap/overflow — this story assumes those transitions exist.
- Story 015: the anchor's rendering and expanded list, keyboard focus cycling, and the focus handoff on retire/promote (Edge Case 13 / AC41).
- `build-validation-navigability` story 008: the emission tiers and queryable state.

---

## QA Test Cases

- **AC11**: Given a dismissed Warning and a re-emission at t+5 s with `min_reshow_interval = 30`, Then phase stays DISMISSED and the anchor entry exists; at t+31 s with the cause still in state, Then phase becomes SHOWN with **zero** further emissions.
- **AC37 (a)**: Given 3 shown Warnings and 2 anchor-only Warnings with different `first_seen_at`, When one shown Warning retires, Then the older anchor-only one is SHOWN in the same reconcile.
- **AC37 (b)**: Given the older anchor-only Warning has 10 s of debounce remaining, Then it is skipped and the newer one promotes.
- **Info promotion**: Given a freed slot, one anchor-only Warning and one anchor-only Info, Then the Warning promotes and the Info does not.
- **AC29**: Given a shown Warning and a pass that emits nothing for its key with the queryable state reporting resolved, Then after one reconcile both the record and the anchor entry are gone; assert no dismissal was called.
- **AC30**: Given a pass emitting Info(subject S) and no Warning(S), with Warning(S) previously SHOWN, Then within that reconcile Warning(S) is retired and Info(S) is SHOWN — assert no intermediate frame has both.
- **AC38**: Given Warning(S) in GRACE with 2 s elapsed of 3 s, When it swaps to Info(S), Then Info(S)'s remaining grace is 1 s (not 3 s); after 1 s with the cause held, Then SHOWN.
- **Debounce does not carry**: Given Warning(S) dismissed with 20 s remaining, When it swaps to Info(S), Then Info(S) has no debounce window and may surface immediately.
- **Suspended**: Given a 20 s-remaining debounce, When suspended for 60 s of raw delta, Then remaining is still 20 s.

---

## Test Evidence

**Story Type**: Logic (state machine transitions) — **BLOCKING**.
**Required evidence**: `neues-spiel/tests/unit/ui/toast_lifecycle_reconciliation_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 013; `build-validation-navigability` story 008 — **Cluster A gate**.
- Unlocks: 015.
