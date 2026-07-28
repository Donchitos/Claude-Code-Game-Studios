# Story 013: Toast lifecycle A — identity, grace, severity, cap & overflow

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/hud.md` (zones Z2/Z3, element E5, P1)
**Requirement**: `TR-building-ui-050`, `TR-building-ui-051`, `TR-building-ui-052`, `TR-building-ui-053`, `TR-building-ui-054`, `TR-building-ui-055`, `TR-building-ui-063`, `TR-building-ui-014`, `TR-building-ui-015`, `TR-building-ui-074`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (UI Timer & Expiry Management)
**ADR Decision Summary**: A centralized expiry-timestamp manager keyed by whatever identity the caller supplies (a **subject id** for grace timers), one shared `_process` loop, raw-delta and pause-immune, frozen by a single guard flag on Suspended and resuming from untouched remaining time. Never N Godot `Timer` nodes.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Build Validation's emissions for one analysis pass all arrive **synchronously within one frame** (default signal connections are synchronous) — same-frame delivery IS the reconciliation unit. That is a landed engine guarantee, not an assumption; story 014's reconciliation depends on it.

**Control Manifest Rules (this layer)**:
- Required (Presentation): the toast area shows **warnings and info hints only** (`sealed_space_warning`, `unsheltered_furniture_info`); each toast carries its why-string **verbatim**. Room confirmations have **no HUD surface** — the celebration is in-world.
- Forbidden: composing a why-string in the UI; a hidden queue behind the anchor; evicting a visible Warning by a lower-severity arrival; counting re-emissions as a grace clock.
- Guardrail: **nothing ever starves and nothing is ever invisible** — the anchor is the overflow home, and its badge counts everything.

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md` Rule 9 (identity/grace/severity/overflow) + Edge Cases 1/6, scoped to this story:*

- [ ] **AC28 (identity/dedup)**: Given a shown toast, When its key re-emits on N successive passes, Then exactly **one** toast instance exists throughout — no duplicate entries, no Shown→Queued cycling. Every toast is keyed by **(signal type, subject)**: the region for sealed-space warnings, the item for info hints; a re-emission matching a live key **refreshes it in place** — no new entry, no re-queue, no visual change (`TR-building-ui-051`).
- [ ] **AC27 (grace)**: Given exactly **ONE** qualifying emission for a new subject (Build Validation is event-driven — a persisting cause may emit exactly once), When `warning_grace_delay` elapses **as a UI-local wall-clock timer started on that first emission** and the mocked queryable state still holds the cause, Then the toast appears — **no re-emission required**; Given the queryable state shows the cause resolved before expiry, Then **no toast and no anchor entry ever appeared** (`TR-building-ui-052`, `TR-building-ui-014`).
- [ ] **AC40**: Given a subject in Grace, When the game is **PAUSED** past the remaining delay, Then the expiry still fires and the queryable-state check decides surfacing — grace/debounce timers are wall-clock, frozen **only** by Suspended (`TR-building-ui-053`).
- [ ] **Severity**: Warning outranks Info. A visible Warning is **NEVER** evicted by a lower-severity arrival; it leaves only via player dismissal, tier-swap, cause resolution, or the overflow rule (`TR-building-ui-054`).
- [ ] **AC12 (overflow)**: Given `toast_max_visible` visible toasts including at least one Info, When a new Warning arrives, Then the oldest visible Info collapses into the anchor and the Warning shows; Given **every** visible slot holds a Warning, When a new Warning arrives, Then **no visible toast is evicted** and the new Warning appears in the anchor with the badge incremented (`TR-building-ui-055`, Edge Case 1).
- [ ] A new **Info** arriving when full goes directly to the anchor (`TR-building-ui-055`).
- [ ] **AC20**: Given an info-tier hint (unsheltered bed), Then it renders as **dismissible low-key** — visually distinct from warning styling — and its why-string passes through **verbatim** (`TR-building-ui-050`).
- [ ] **AC35**: Given a `room_recognized` event (mocked), Then **zero** toast entries and zero anchor entries are created — confirmations have no HUD surface (Rule 9d, `TR-building-ui-063`).
- [ ] **AC74**: Warning and Info toasts are differentiated by icon **SHAPE + label**, never by hue or intensity alone (Visual Direction Note §4's day-one pairing rule) (`TR-building-ui-074`).
- [ ] Why-strings **wrap, never truncate** (A4).
- [ ] **AC16 (toast half)**: Given Suspended entered, Then the toast/anchor set survives — hidden with the HUD, restored on reactivation — and all grace timers freeze, resuming with **remaining** time, never restarting (Edge Case 6, `TR-building-ui-015`).
- [ ] `toast_max_visible` (default 3, min 2) and `warning_grace_delay` (default 3 s, 1–8 s) come from `BuildingUiConfig`.

---

## Implementation Notes

*Derived from Rule 9's rebuilt toast model (2026-07-10) and ADR-0011:*

- **The grace clock is wall-clock per SUBJECT, not a count of re-emissions.** The original re-emission wording was unsatisfiable and was rewritten precisely because Build Validation may emit exactly once for a persisting cause. Start one `UITimerManager` record keyed by subject on the first qualifying emission; on expiry, **query Build Validation's state** to decide surfacing. Do not count anything.
- Model the toast set as `Dictionary[key, ToastRecord]` where `key = (signal_type, subject)` and `ToastRecord` carries `{severity, why_string, phase: GRACE|SHOWN|ANCHOR_ONLY|DISMISSED, first_seen_at, ...}`. Every AC in this story and story 014 is a transition on that record — write the transition function pure and test it directly.
- The overflow rule has **three** distinct branches (Warning-evicts-Info, all-Warnings-so-anchor, Info-when-full-so-anchor). Test all three; the "no visible toast is evicted" branch is the one that regresses.
- The anchor's **badge count** is derived from the live issue set, not incremented imperatively — story 015 owns the anchor's rendering, but this story owns the set it derives from. Expose the set, don't expose a counter.
- `min_reshow_interval` and the debounce/promotion/reconciliation transitions are **story 014's** — leave the `DISMISSED` phase in the enum but unreachable here.
- Suspended freeze reuses story 001's single `UITimerManager.set_suspended(true)` call. Do not add a second freeze path for toasts.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 014: dismissal debounce, promotion, reconciliation/auto-retire, tier-swap.
- Story 015: the anchor's rendering, its expanded list, and HUD keyboard focus.
- Story 009: the invalid-commit cue (a different channel, Building System's, not Build Validation's).
- `build-validation-navigability` story 008: the emissions and queryable state this story consumes.

---

## QA Test Cases

- **AC28**: Given one subject emitting on 10 successive passes, Then the record dictionary size is 1 throughout and the phase never leaves SHOWN after first surfacing.
- **AC27 (positive)**: Given one emission and a mocked queryable state that still holds, When `warning_grace_delay` of raw delta elapses, Then the phase becomes SHOWN with exactly zero further emissions.
- **AC27 (negative)**: Given one emission and a queryable state that reports resolved at expiry, Then the record is discarded — assert **no** anchor entry was ever created, not merely that none remains.
- **AC40**: Given a mocked paused Time & Tick and a 3 s grace, When 3.1 s of raw delta elapse, Then expiry fired.
- **AC12 (a)**: Given 3 visible = [Info(oldest), Warning, Warning], When a Warning arrives, Then the Info's phase is ANCHOR_ONLY and the new Warning is SHOWN.
- **AC12 (b)**: Given 3 visible Warnings, When a Warning arrives, Then all three remain SHOWN and the new one is ANCHOR_ONLY; assert the badge-source set has 4 entries.
- **AC12 (c)**: Given 3 visible Warnings, When an Info arrives, Then it is ANCHOR_ONLY.
- **AC35**: Given `room_recognized` emitted, Then the record dictionary is unchanged (size and contents).
- **AC16**: Given Suspended with a 1 s-remaining grace record, When 5 s of raw delta elapse while suspended, Then `remaining` is still 1 s; on resume it expires 1 s later.
- **Verbatim**: Given a why-string with punctuation and an em-dash, Then the rendered text is byte-identical to the payload.

---

## Test Evidence

**Story Type**: Logic (state machine over keyed records) — **BLOCKING**.
**Required evidence**: `neues-spiel/tests/unit/ui/toast_lifecycle_identity_grace_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001 (`UITimerManager`, Z2/Z3 zones); `build-validation-navigability` story 008 (warning/info tiers + queryable state) — **Cluster A gate**.
- Unlocks: 014.
