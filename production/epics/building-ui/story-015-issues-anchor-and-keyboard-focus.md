# Story 015: Issues anchor & HUD keyboard focus cycling

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/hud.md` (zone Z3, element E6, B3 List pattern, A2 keyboard access, Default Key Bindings N / X / I)
**Requirement**: `TR-building-ui-061`, `TR-building-ui-062`, `TR-building-ui-059`, `TR-building-ui-060`, `TR-building-ui-073`, `TR-building-ui-065`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (UI Timer & Expiry Management) — the debounce windows the anchor's live set must still include; ADR-0010 — Esc routing precedence
**ADR Decision Summary**: The anchor stores **nothing but its expanded/collapsed flag**; its list is built live from Build Validation's queryable state, never from a UI-cached copy. Esc releases HUD keyboard focus **without dismissing** — a focused toast or expanded anchor loses focus on Esc, and only an Esc with NO HUD focus falls through to world-level handlers (this is Esc chain step 1 and the reciprocal clause villager-info-ui's Rule 1 depends on).

**Engine**: Godot 4.7-stable | **Risk**: **HIGH — BLOCKING**
**Engine Notes**: **⚑ GDD Open Question 7 is BLOCKING for this story specifically.** Godot 4.6 introduced a **dual-focus system** (mouse/touch focus separate from keyboard/gamepad focus) that postdates the model's training data, and Edge Case 13's explicit focus handoff depends on its exact semantics. Godot does **not** auto-transfer focus from a freed `Control` — the handoff must be explicit. This is the first feature in the project requiring focus to survive dynamic Control add/remove. **`godot-specialist` must verify against the pinned 4.7 docs before this story starts.** Tab is never used (`ui_focus_next` collision).

**Control Manifest Rules (this layer)**:
- Required (Presentation): the anchor is visible **iff** at least one active warning/info exists anywhere (shown, dismissed-within-window, or overflowed) and **hidden entirely at zero** — no dead chrome (Pillar 4 calm).
- Forbidden: a UI-cached copy of the issue list; Esc dismissing anything; focus ever dangling null while a focusable notification element exists.
- Guardrail: `toast_dismiss` via keyboard has semantics **identical** to a click dismissal, including the debounce window.

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md` Rules 9b/9c + Edge Case 13, scoped to this story:*

- [ ] **AC32**: Given zero active issues, Then the anchor is **fully hidden** — no badge, no dead chrome (`TR-building-ui-061`).
- [ ] The anchor renders as a compact counter chip ("N ⚠") at the top of the notification zone, visible iff ≥ 1 active issue exists in **any** phase — shown, dismissed-within-window, or overflowed (`TR-building-ui-061`).
- [ ] **AC31**: Given any set of active issues (shown, dismissed-in-window, and overflowed), Then the anchor **badge equals the live issue count** and the expanded list matches Build Validation's **queryable state exactly** — mutating upstream state directly (bypassing signals) never leaves a stale list entry (`TR-building-ui-062`).
- [ ] Activating the anchor (click or `toggle_issues`) expands a compact list of **ALL** active issues with verbatim why-strings, built live; the anchor stores nothing but its expanded/collapsed flag (`TR-building-ui-062`).
- [ ] Expanded rows **retire with their cause** — a row whose issue is auto-retired (story 014) disappears from the open list within one reconcile.
- [ ] **AC33**: Given visible toasts, When `toast_focus_cycle` then `toast_dismiss` fire, Then the focused toast is dismissed with semantics **identical** to a click dismissal, **including the debounce window** (`TR-building-ui-059`).
- [ ] **AC41**: Given the focused toast auto-retires, is promoted away, or tier-swaps, Then keyboard focus transfers to the **next visible toast**, or the **anchor** if none remains — **never null** while any focusable notification element exists (Edge Case 13, `TR-building-ui-073`).
- [ ] **Esc chain step 1**: Given a focused toast or the expanded anchor holds HUD keyboard focus, When Esc fires, Then that focus is released **without dismissing**, and the press does **not** fall through to world-level handlers or resolve any later chain step (`TR-building-ui-060`).
- [ ] Focus indicators are visible on all five control states, in Hearth Gold (hud.md A2).
- [ ] **AC36 (partial)**: Given the InputMap at boot, Then `toast_focus_cycle`, `toast_dismiss`, `toggle_issues` exist as registered actions (`TR-building-ui-065`).
- [ ] Every interactive notification control is reachable and operable **without the mouse** (A2) — the anchor, its rows, and every visible toast.

---

## Implementation Notes

*Derived from Rule 9c, Edge Case 13 and the 4.6 dual-focus warning:*

- **Verify the engine facts first.** Before writing focus code, `godot-specialist` must confirm against `docs/engine-reference/godot/`: (a) how 4.6/4.7's dual-focus split routes `grab_focus()` and `ui_focus_next`, (b) what happens to keyboard focus when the focused `Control` is `queue_free()`d, (c) whether a focus-ring theme override behaves the same across both focus channels. Record the answers in the story before implementing — they are the story's real design input.
- **The anchor is a derivation, not a store.** Given story 013/014's record map plus Build Validation's queryable state, the anchor's badge and list are one pure function of both. Test the function; the Control is a thin renderer.
- AC31's "mutating upstream state directly (bypassing signals)" is the test that catches a cached copy. Write it as a direct mock mutation with no emission, then re-render — if the list changes, there is no cache.
- Focus handoff must be **explicit and ordered**: on removal of the focused element, pick (next visible toast in display order) else (anchor) else (release focus entirely). Compute the successor **before** freeing the Control, not in a `tree_exited` callback.
- Esc's step-1 behavior must consume the event so nothing downstream sees it. Story 002 owns the chain; this story owns the "does HUD focus exist" predicate the chain reads.
- Keyboard dismissal must call the **same** dismissal path as a click — a second path is how the debounce window silently diverges (AC33's real point).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Stories 013/014: the toast lifecycle itself — this story renders the anchor over it and adds the focus layer.
- Story 002: the Esc chain's later steps (2/3/4).
- Story 012: the Projects Panel's overflow row, which reuses this B3 List pattern but is its own control.
- Rebinding UI (Alpha) and gamepad navigation (post-MVP).

---

## QA Test Cases

- **AC32**: Given zero records, Then the anchor node is not visible and occupies no layout space.
- **AC31**: Given 2 shown + 1 dismissed-in-window + 2 overflowed, Then the badge reads 5 and the expanded list has 5 rows matching the queryable state's entries in order; mutate the mock state to remove one **without emitting**, re-render, Then 4 rows.
- **Row retire**: Given the anchor expanded and one issue auto-retired by reconcile, Then that row is gone in the same reconcile and no other row shifted identity.
- **AC33**: Given 3 visible toasts, When `toast_focus_cycle` fires twice then `toast_dismiss`, Then toast #2 is dismissed and its key has a live `min_reshow_interval` window — identical to a click dismissal of the same toast in a parallel run.
- **AC41 (retire)**: Given focus on toast #2 and #2 auto-retires, Then focus is on the next visible toast; Given it was the last one, Then focus is on the anchor; Given the anchor is also hidden (zero issues), Then focus is released with no error.
- **AC41 (promotion)**: Given focus on toast #2 and #2 is promoted away, Then the same successor rule applies.
- **Esc step 1**: Given focus on a toast **and** a tool armed **and** an active Selection, When Esc fires, Then focus is released and the tool is still armed and the Selection is unchanged.
- **AC36**: Given the InputMap at boot, Then all three actions exist.

---

## Test Evidence

**Story Type**: Logic (derivation + focus state machine) — **BLOCKING**.
**Required evidence**: `neues-spiel/tests/unit/ui/issues_anchor_and_focus_test.gd` — must exist and pass.
**Also**: `production/qa/evidence/building-ui-015-keyboard-only-walkthrough.md` (ADVISORY) — a mouse-free pass over the anchor and toasts (A2), plus the 4.6 dual-focus verification note.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 013, 014; **the Godot 4.6 dual-focus verification (GDD Open Question 7) must be closed by `godot-specialist` before this story starts** — it is BLOCKING for this story specifically.
- Unlocks: —
