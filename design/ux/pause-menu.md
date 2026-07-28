# UX Spec: Pause Menu

> **Status**: **Approved** — `/ux-review` 2026-07-23 (first pass: NEEDS REVISION,
> 1 blocking / 5 advisory; all 6 applied, re-review verdict APPROVED, 0/0)**Author**: user + ux-designer
> **Last Updated**: 2026-07-23
> **Journey Phase(s)**: unknown — no player journey map yet (shared gap with
> `hud.md` OQ1 / `villager-panel.md` OQ1 / `projects-panel.md` OQ2)
> **Template**: UX Spec
> **Behavioral source of truth**: `design/gdd/time-tick-system.md` (pause =
> `game_delta = 0`, Core Rules 1/3/4, Forbidden Patterns) + `design/gdd/
> building-ui.md` Rule 13 (Build Mode/WorldNav) + Rule 14/TR-building-ui-076
> (the existing 4-step Esc chain, extended — not edited — by this spec)
> **Binding inputs**: `design/ux/hud.md` (zones Z1/full-screen tier),
> `design/ux/interaction-patterns.md` (P1, P2, P6, P7, P11, P14, B1, B3),
> `design/ux/accessibility-requirements.md` (A1–A7), `design/art/art-bible.md`
> §2.5 (Menus/Pause mood contract) and §7.6 (pause-dim provisional values —
> this spec is their UX home), `docs/architecture/adr-0012-save-load-
> serialization-strategy.md` (Save is VS-tier, not MVP), `design/gdd/
> systems-index.md` row 27/187 + `design/gdd/scene-world-management.md` Core
> Rule 1 (Main Menu & Settings does not exist until Alpha; MVP boots directly
> into the Valley, no menu)
> **Cross-doc dependencies introduced by this spec** (not edited here — see
> Open Questions): `building-ui.md` Rule 14 (proposed 5th Esc-chain step),
> `camera-input.md` (a second input-halt trigger distinct from Suspended),
> `docs/architecture/adr-0011-ui-timer-expiry-management-pattern.md` (a
> second timer-freeze trigger distinct from Suspended), `hud.md` (a new Z1
> element + a full-screen overlay zone row, and E11's ordinary-pause dim
> being superseded while this screen is open), `design/ux/main-menu.md`
> (sibling — this spec is the "Pause/system menu" its OQ9 anticipated; its
> M5/OQ5a Destructive Confirmation Modal is the sibling precedent to
> reconcile with this spec's own confirmation modal, see Open Questions)

---

## Purpose & Player Need

**"Let me step out for a second, without losing my place."** The Pause Menu
is the game's one guaranteed, mode-independent exit hatch: no matter what the
player is doing — mid-drag, tool armed, a villager or project selected, deep
in Build Mode — one action always gets them to "the game is fully stopped,
here are my options," and one action always gets them back to exactly where
they were. Per Art Bible §2.5 this is deliberately **the least characterful
screen in the game**: "quiet, flat, immediate, unadorned... a tool, not a
mood." Its whole job is to get out of the way as fast as it appeared.

Without this screen the game would have no answer to "I need to stop right
now" that works uniformly across every HUD/Build Mode state — Building UI's
own Esc chain (Rule 14) is explicitly scoped to *in-game* mode-stepping
(tool → selection → Build Mode → WorldNav), not to leaving the game itself.
This spec is where "leaving the game" gets its own, single, always-available
door.

---

## Player Context on Arrival

Arrival is always **voluntary and deliberate** — never triggered by the game.
Unlike the villager/project panels' "curious, calm" register, the Pause
Menu's target emotional state is **neutral, brief, transactional**: the
player wants to check settings, step away from the keyboard, or leave, and
wants that decision handled with zero ceremony. It must feel exactly as fast
whether the player is mid-drag in Build Mode or standing idle in WorldNav —
the screen does not get to have an opinion about *why* the player paused.

---

## Navigation Position

Not a screen in the normal sense — a **full-screen modal overlay** reachable
from anywhere in gameplay:
`Gameplay (any state) → Pause Menu (full-screen overlay, mutually exclusive
with normal HUD interaction)`.

Unlike every other spec in this project, the Pause Menu is **not
mode-scoped** — it is the one surface explicitly designed to be reachable
from World Navigation, Build Mode (tool armed or Idle), and with an active
Selection (villager or project), all alike. It has exactly one child
destination that exists in this project today: none — `Einstellungen`
("Settings") and `Zum Hauptmenü` ("Quit to Menu") are both disabled at MVP
because their targets (`Main Menu & Settings`) are Alpha-tier and not yet
started (see States & Variants and Open Questions).

---

## Entry & Exit Points

| Entry Source | Trigger | Player carries this context |
|---|---|---|
| HUD Menu button click | Any state, any time (new HUD element, see World Freeze section) | Whatever Build Mode/tool/Selection state was active — fully preserved |
| `pause_menu_toggle` key (default `M`, `[assumption]`) | Any state, any time | Same as above |
| Esc, chain terminal step (proposed) | Only when Building UI's existing Esc chain (Rule 14) has no applicable step — i.e. WorldNav, no Selection, no tool | Same as above (this case is already "nothing left to back out of") |
| Reactivation after Suspended | N/A — the Pause Menu cannot be open going into a scene transition (see States & Variants) | — |

| Exit Destination | Trigger | Notes |
|---|---|---|
| Resume (menu closes) | Click "Fortsetzen" / Esc (while menu open, no modal on top) / re-press `pause_menu_toggle` | World unfreezes, camera/input restore exactly, Time & Tick pause state restores to whatever it was before the menu forced it (see World Freeze section) |
| Confirmation modal (sub-state, not an exit) | Click "Spiel beenden" or (once enabled) "Zum Hauptmenü" | Pause Menu stays open underneath; see Destructive-Action Confirmation |
| Quit to Desktop | Confirm in the modal | `SceneTree.quit()` — the session ends, nothing to carry |
| Quit to Menu (disabled at MVP) | Confirm in the modal, once Main Menu & Settings exists | Routes through Scene/World Management's normal transition (P12); out of scope for MVP |

There is no accidental exit — every destructive path (both Quit actions)
requires passing through the confirmation modal first (see below); Resume is
always one action away, from anywhere.

---

## Layout Specification

### Information Hierarchy

1. **A single word telling the player where they are** — "Pause" header.
   Per §2.5's "neutral competence" target, this is deliberately the least
   interesting line on the whole screen.
2. **The menu list itself**, in the order a player actually wants it: get
   back in first (Fortsetzen), then the two things that take you further
   from the game in increasing order of finality (Einstellungen is
   reversible and instant; Zum Hauptmenü and Spiel beenden both end the
   session and sit at the bottom, visually separated as the "leaving"
   group).
3. **Nothing else.** No stats, no session summary, no achievements — the
   background freeze-frame already tells the player "your settlement is
   still here" (§2.5's "carrying element") without any additional UI text
   needing to say so.

### Layout Zones

**New full-screen tier**, analogous to `hud.md`'s existing Transition
Overlay row (P12) — not a normal HUD zone, and not counted against the
Visual Budget's 8-element cap, since it is mutually exclusive with ordinary
gameplay HUD interaction the same way the transition overlay already is.
This spec also claims **one new element in HUD zone Z1** (top-right, beside
the existing time controls) as the mouse entry point. Both additions require
a `hud.md` follow-up revision (its own Layout Zones table + Visual Budget
notes) — not edited by this spec, see Open Questions.

```
┌─────────────────────────────────────────────┐
│                                  [⏸ 1x 2x 3x][☰]│  Z1 (existing time controls
│                                                  │      + NEW Menu button)
│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
│▒▒▒▒▒▒▒▒▒▒▒▒▒▒  (dimmed, desaturated,  ▒▒▒▒▒▒▒▒▒│
│▒▒▒▒▒▒▒▒▒▒▒▒▒▒   frozen world + HUD)   ▒▒▒▒▒▒▒▒▒│
│▒▒▒▒▒▒▒▒▒▒▒  ┌───────────────────────┐  ▒▒▒▒▒▒▒▒│
│▒▒▒▒▒▒▒▒▒▒▒  │        Pause          │  ▒▒▒▒▒▒▒▒│
│▒▒▒▒▒▒▒▒▒▒▒  │ ───────────────────── │  ▒▒▒▒▒▒▒▒│
│▒▒▒▒▒▒▒▒▒▒▒  │   Fortsetzen          │  ▒▒▒▒▒▒▒▒│
│▒▒▒▒▒▒▒▒▒▒▒  │   Einstellungen       │  ▒▒▒▒▒▒▒▒│  (greyed at MVP)
│▒▒▒▒▒▒▒▒▒▒▒  │ ───────────────────── │  ▒▒▒▒▒▒▒▒│
│▒▒▒▒▒▒▒▒▒▒▒  │   Zum Hauptmenü       │  ▒▒▒▒▒▒▒▒│  (greyed at MVP)
│▒▒▒▒▒▒▒▒▒▒▒  │   Spiel beenden       │  ▒▒▒▒▒▒▒▒│
│▒▒▒▒▒▒▒▒▒▒▒  └───────────────────────┘  ▒▒▒▒▒▒▒▒│
│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
└─────────────────────────────────────────────┘
```

Layout rules:

- Minimum supported layout **1280×720**, same discipline as every other zone
  (inherits `hud.md`'s existing rule, adds none new).
- Panel is centered, fixed-width, flat `#262220`, sharp corners, 1px
  chrome-edge hairline (Art Bible §7.5 panel anatomy) — the ONE piece of
  chrome on an otherwise empty screen, per §2.5's "unadorned" adjective.
- The frozen backdrop consumes 100% of the screen behind the panel — no
  world-pick, no HUD-pick reaches anything underneath (generalizes P2's
  hover-suppression gate to the whole screen, not just cursor-over-HUD).

### Component Inventory

| # | Component | Type | Interactive | Pattern / Source |
|---|---|---|---|---|
| C1 | Panel header "Pause" | Text label | No | UI-owned chrome text (P10 carve-out), Art Bible §7.5 header-divider rule |
| C2 | Menu list | Vertical list container | No (rows are) | B3-adjacent (fixed 4-row list, no scroll/overflow — never grows) |
| C3 | Row: "Fortsetzen" | B1 button | Yes | B1; always enabled |
| C4 | Row: "Einstellungen" | B1 button | Yes (MVP: disabled) | B1; disabled state + tooltip "Bald verfügbar" until Main Menu & Settings ships |
| C5 | Row: "Zum Hauptmenü" | B1 button | Yes (MVP: disabled) | B1; disabled state + tooltip "Bald verfügbar", same reason as C4 |
| C6 | Row: "Spiel beenden" | B1 button | Yes | B1; always enabled — opens the confirmation modal (C8) |
| C7 | Frozen world+HUD backdrop | Full-screen static image | Consumes all clicks (no-op) | New — see World Freeze section |
| C8 | Confirmation modal | Secondary overlay panel | Yes (its 2 buttons) | New — see Destructive-Action Confirmation |
| C9 | Confirmation message text | Text, multi-line | No | New — states the reason verbatim (Pillar 4) |
| C10 | Confirmation buttons "Abbrechen" / "Trotzdem beenden" | 2× B1 buttons | Yes | B1; default focus = "Abbrechen" (safety-first, see Destructive-Action Confirmation) |
| — | New HUD element: Menu button (Z1) | Icon button (B1) | Yes | New — hud.md follow-up (element numbering continues from E11) |

---

## States & Variants

| State / Variant | Trigger | What Changes |
|---|---|---|
| Closed (default) | No trigger fired | Nothing rendered; game runs normally |
| Open — WorldNav | Menu button / `M` / Esc-terminal, from WorldNav | Frame freezes/dims; menu shows all 4 rows (2 greyed at MVP) |
| Open — Build Mode, tool armed | Menu button / `M` (Esc-terminal is NOT reachable here — the chain would first need to resolve the armed tool) | Identical panel; frozen backdrop happens to show the armed tool's ghost/context panel exactly as it looked the instant the menu opened |
| Open — Build Mode, Selection active (villager or project) | Menu button / `M` | Identical panel; frozen backdrop shows the Selection's highlight/outline exactly as it looked |
| Open, Confirmation modal shown | Click "Spiel beenden" / "Zum Hauptmenü" | C8–C10 appear on top of the Pause Menu panel (not replacing it); Pause Menu's own rows are inert until the modal resolves |
| Cannot open — Suspended | Attempted trigger while Camera & Input is already Suspended (scene transition in progress) | No-op — mirrors P14; the Pause Menu is never available mid-transition |
| Quitting — Menu is closing itself | Confirmation resolved to "Trotzdem beenden" | Pause Menu (and its confirmation modal) close instantly, same frame the destination action fires — no lingering overlay under the transition/quit (see Transitions & Animations) |

**"Paused-while-Build-Mode" and "paused-during-transition" (explicitly
required states)**:

- **Paused while Build Mode is active**: fully supported and behaves
  identically to any other open state — see the two Build Mode rows above.
  Nothing about Build Mode's own state (armed tool, ghost pick, ghost
  position, Selection) is altered by opening or closing the Pause Menu; only
  simulation time, camera, and world/HUD input are held for the duration.
  Resuming restores control at the exact frame it was frozen (mirrors
  `camera-input.md`'s existing "no snap, no catch-up" guarantee for its own
  Suspended state, TR-camera-input-042 — same contract, different trigger).
- **Paused during a transition**: **not a real state** — it cannot occur.
  The Pause Menu's every entry point is a no-op while Camera & Input is
  Suspended (scene transition), and Suspended state hides/ignores the entire
  HUD already (P14) — including the new Z1 Menu button. There is no path to
  open the Pause Menu mid-transition, and no path for a scene transition to
  begin while the Pause Menu is open at MVP (its only transition-triggering
  action, "Zum Hauptmenü," is disabled). This is a deliberate simplification,
  not an oversight — flagged in Open Questions for re-verification once Quit
  to Menu is enabled at Alpha.

No loading state (nothing is fetched), no empty state (the menu's 4 rows are
fixed and never data-dependent), no progression variants at MVP.

---

## World Freeze, Time-Pause & Esc-Chain Behavior

This is the section where the task's three hardest cross-cutting questions
get resolved: how the world visually freezes, how the existing Time & Tick
pause is reused (never re-invented), and how this screen's entry points
coexist with Building UI's existing 4-step Esc chain without swallowing it.

**1. Time-pause reuses the existing API — never `SceneTree.paused` /
`Engine.time_scale`.** Opening the Pause Menu calls the exact same pause
toggle Space already calls (`time-tick-system.md` Core Rule 3, `game_delta =
0`) — it does not introduce a second pause mechanism. A small UI-local,
never-serialized flag (`_menu_forced_pause`) records whether the menu itself
had to call pause (game was running) or found the game already paused
(player had pressed Space earlier): closing the menu only calls *unpause* if
the flag is true. This preserves the existing "pause is a player-toggled,
independent state" contract (`time-tick-system.md` Core Rule 3, `P7`)
exactly — the Pause Menu orchestrates that one existing API, it does not own
a competing pause state. **Both project-wide forbidden patterns
(`SceneTree.paused`, `Engine.time_scale`) remain untouched by this screen,**
matching `technical-preferences.md`'s Forbidden Patterns exactly.

**2. The background is a genuine frozen frame, not a live (but paused) 3D
view — this is new, and deliberately diverges from ordinary Pause.** Per
Art Bible §2.5, the Pause Menu's background is "a dimmed/blurred freeze of
the last world frame... paused, not left" with "zero ambient motion." Unlike
ordinary time-pause (P7/`time-tick-system.md`), where Camera & Input and the
HUD explicitly **stay live** on raw delta (so the player can still orbit the
camera and inspect panels while paused), the Pause Menu additionally halts
camera movement and all world/HUD input for as long as it is open. This is
a deliberate, new divergence from P7's "camera stays responsive during
pause" rule — worth stating plainly rather than leaving implicit, since it
is the one place in the game where pause ≠ "still fully interactive." The
practical value: freezing the actual last rendered frame (rather than
continuing to render a technically-static-but-still-live 3D scene) is
**simpler to build and matches "instant open/close" for free** — there is no
need to individually hide each HUD zone the way Suspended does (P14); the
last frame already shows whatever the toolbar/panels/toasts looked like, so
it becomes the backdrop as-is, then gets dimmed and desaturated on top.
- **Values** (Art Bible §7.6, provisional, this spec is their UX home): dim
  to **~60% brightness**; desaturate the frozen frame **except**
  state-carrying markers (distress icons, unreachable-ghost markers, the
  invalid-commit afterglow) — those stay in full color so A1's
  color-independence guarantee survives the dim treatment. Exact values
  tuned on screenshots at implementation, per §7.6.
- **This supersedes E11 — the two dim treatments never stack.** `hud.md`'s
  E11 (ordinary-pause dim/desaturation, shown whenever `paused=true` via
  Space/the time-control button) is a live, continuously-rendered treatment
  over a still-interactive scene. The instant the Pause Menu opens — whether
  the game was already running or already paused via E11 — the captured
  backdrop and its ~60% value (this section) become the ONLY dim/
  desaturation treatment on screen; E11's own dim is not additionally
  applied on top of it. This explicitly covers the
  player-paused-then-opened-menu branch (E11 active at capture time): the
  frame is captured already showing E11's dim, but from that point on the
  Pause Menu's own treatment owns the visual, not a stack of both. On
  Resume, E11 reasserts normally from whatever `paused` state Time & Tick
  actually holds (see `_menu_forced_pause` above) — there is no double-dim
  moment in either direction.
- This is functionally closest to `camera-input.md`'s existing Suspended
  contract (full input halt, exact-state restore on exit) but **must NOT be
  implemented as Suspended** — that GDD explicitly reserves Suspended
  "exclusively [for] the scene-transition state." This spec therefore
  requires `camera-input.md` to gain a **second, distinct halt trigger**
  with the same behavioral contract, fired by Pause Menu open/close rather
  than a scene transition. Not edited here — flagged in Open Questions.

**3. Esc-chain integration (P11) — the Pause Menu never swallows Building
UI's existing chain.** `building-ui.md` Rule 14 (TR-building-ui-076) already
defines a strict 4-step priority chain — itself the concrete, screen-level
implementation of `interaction-patterns.md`'s **P11 (Two-Step Esc Routing)**,
generalized from two steps to four (HUD focus release → cancel armed
tool → clear Selection → exit Build Mode to WorldNav) — ending in an explicit
**no-op** when none of those apply. This spec deliberately does **not**
hijack Esc to jump that queue — doing so would violate the chain's own
"never skipped or combined" invariant and the task's explicit constraint.
Instead:
- **Primary, guaranteed entry point**: the new HUD Menu button (mouse) and
  a new dedicated keyboard action, `pause_menu_toggle` (default key **`M`**,
  `[assumption]`, mnemonic "Menu" — free of the existing binding table).
  Both work identically from **any** state — WorldNav, Idle, tool armed, an
  active Selection — with zero interaction with the Esc chain. This is the
  reliable path; a player should never need to fight through 3 Esc presses
  just to reach the Pause Menu.
- **Secondary, convention-following entry point**: Esc, but *only* as a
  proposed **5th step appended to the end of the existing chain** — i.e.
  the chain's current terminal "no-op" case (WorldNav, no Selection, no
  tool, no HUD focus) becomes "open the Pause Menu" instead of doing
  nothing. This never fires ahead of, or instead of, any of the 4 existing
  steps — it only fires when literally nothing else in that chain applies,
  which is exactly the state where a no-op currently exists to be replaced.
  **This IS a change to `building-ui.md`'s own contract (TR-building-ui-076)
  and is not made by this spec** — it is proposed here and must land in that
  GDD's own revision (see Open Questions; `/propagate-design-change`
  recommended, matching the project's existing convention for this kind of
  cross-doc dependency).
- **While the Pause Menu is open**, Esc has exactly one meaning: close/
  Resume. It does not run Building UI's chain at all while the menu holds
  focus — that chain (and all world/HUD input generally) is itself halted
  for the duration (see point 2 above), so there is nothing for Esc to
  route to but the topmost surface.

**4. Toast/expiry timers (P1) should freeze too — a second flagged
architecture dependency.** `docs/architecture/adr-0011-...md`'s centralized
UI timer manager is currently gated by a single `_suspended` boolean tied
only to Scene/World Management's Suspended signal (transitions), not to
ordinary pause — this manager is what backs `interaction-patterns.md`'s
**P1 (Toast/Notification Subsystem)**'s grace/debounce/reconciliation
timers. Since the Pause Menu's background is a **static captured frame**
(not a live, still-updating HUD), any P1 timer that kept running underneath
would either (a) cause a toast to visibly pop or vanish the instant the menu
closes with no felt cause, or (b) be invisible anyway since nothing is
rendered — but (a) is a real, avoidable "why did that change while I wasn't
looking" moment that conflicts with Pillar 4. This
spec's decision: **freeze the UI timer manager for the duration the Pause
Menu is open**, functionally identical to its existing Suspended-triggered
freeze. This requires `ADR-0011` to accept a **second freeze trigger**
alongside Suspended — not implemented by this spec, flagged in Open
Questions as an architecture follow-up.

---

## Destructive-Action Confirmation Policy

**Decision: both Quit actions (Spiel beenden, and Zum Hauptmenü once
enabled) require passing through a confirmation modal — the first
confirmation-dialog pattern introduced anywhere in this project.**

This is a deliberate, justified exception to the established no-modal
precedent (P6: invalid feedback "never modal"; `projects-panel.md`'s
Confirmation Policy: "the pattern catalog has no confirmation-dialog pattern
anywhere... a new exception would contradict that baseline"). The
distinction that justifies it here is categorical, not cosmetic:

1. **Every other irreversible action in this game (Abriss, Verwerfen) costs
   at most one project's worth of rebuild time** — `projects-panel.md`
   explicitly cites "near-zero permanent cost" as part of why no
   confirmation is needed there. **Quitting, at MVP, costs the entire play
   session, unconditionally, every single time** — per ADR-0012, Save/Load
   is VS-tier and does not exist yet ("VS-tier, not MVP-blocking"), so there
   is no partial-recovery path whatsoever. This is not "might lose some
   progress" — it is "will always lose all progress," a strictly larger and
   less-recoverable category than anything the no-modal precedent was
   established against.
2. **Quitting is a navigation action out of the game entirely**, not an
   in-game build/demolish decision the player can immediately retry or
   rebuild from. The no-modal philosophy ("speed over ornament," instant
   and forgiving) is about *not punishing experimentation inside the core
   loop* — it was never a blanket claim that the game may never ask "are
   you sure" about leaving it.

**Honesty over vagueness (Pillar 4)**: rather than a generic "Are you sure?"
the message states the actual, current reason plainly: *"Es gibt noch kein
Speichersystem – dein Fortschritt geht beim Beenden verloren."* ("There's no
save system yet — your progress will be lost when you quit.") This tells
the player exactly what is true right now, not a vague warning.

**Default focus = "Abbrechen" (Cancel), never the destructive option** — a
deliberate error-prevention choice (the safe action sits on the path of
least resistance for an accidental Enter-press or gamepad confirm, once
gamepad menu support lands). The destructive button is labeled distinctly
from the menu row that opened it ("Trotzdem beenden" — "quit anyway" —
rather than repeating "Spiel beenden" verbatim), so the two are never
visually or textually confusable at a glance.

**Forward note (flagged in Open Questions, not resolved here)**: once
Save/Load & World Persistence ships (VS+), "progress is always lost" stops
being universally true. At that point this policy should evolve into a
standard dirty-flag check (only confirm if there are unsaved changes since
the last save) rather than always showing the modal — this spec's decision
is scoped to the current, no-save MVP reality.

This is also flagged as a **candidate new pattern-library entry**
("Destructive Navigation Confirmation") for `interaction-patterns.md` — not
added there by this spec (scope: this document only), mirroring how
`projects-panel.md` flagged its own bounded-list pattern as a candidate
addition without editing that library directly.

---

## Interaction Map

Mapping interactions for: **Keyboard/Mouse (primary), PC only.** Gamepad:
none at MVP (partial, menu/camera only, post-MVP, per technical-preferences
— this screen is exactly the kind of "menu" context that support would
eventually target, see Open Questions).

| Action | Input | Immediate feedback | Outcome |
|---|---|---|---|
| Open Pause Menu | Click HUD Menu button (Z1) | Frame freezes/dims same frame, panel appears | Pause Menu open |
| Open Pause Menu | `pause_menu_toggle` (`M`) | Same | Pause Menu open, from any state |
| Open Pause Menu | Esc, chain terminal step (proposed) | Same | Only reachable once Building UI's chain has nothing else to resolve |
| Resume | Click "Fortsetzen" | Frame unfreezes same frame, camera/input restore exactly | Pause Menu closed |
| Resume | Esc (menu open, no modal) | Same | Pause Menu closed |
| Resume | Re-press `M` | Same | Pause Menu closed |
| Open Settings (MVP: disabled) | Click "Einstellungen" | No-op; tooltip "Bald verfügbar" on hover/focus | — |
| Quit to Menu (MVP: disabled) | Click "Zum Hauptmenü" | No-op; tooltip "Bald verfügbar" on hover/focus | — |
| Request Quit to Desktop | Click "Spiel beenden" | Confirmation modal appears same frame, default focus on "Abbrechen" | — |
| Cancel quit | Click "Abbrechen" / Esc / Enter (default focus) | Modal closes instantly, Pause Menu underneath unaffected | Back to Pause Menu |
| Confirm quit | Click "Trotzdem beenden" (requires deliberate focus move + Enter, or click) | Instant — no fade | `SceneTree.quit()` (or, post-Alpha, routes to Scene/World Management's transition for Zum Hauptmenü) |
| Navigate menu rows | `ui_up` / `ui_down` (Godot defaults) | Focus ring moves between enabled rows only — disabled rows are skipped, never focusable | — |
| Hover any row | Mouse move | Standard B1 hover; disabled rows show hover + tooltip but no press state | — |
| Click frozen backdrop | Left-click anywhere outside the panel | Consumed — no-op | — |

### Keyboard-Only Path (explicit walkthrough)

1. Press `M` from anywhere → Pause Menu opens, focus lands on "Fortsetzen"
   (first enabled row).
2. `ui_down` once → focus lands directly on "Spiel beenden" (the single
   MVP-actual outcome: both "Einstellungen" and "Zum Hauptmenü" are disabled
   and are never a focus stop, consistent with B1's disabled-state
   contract — the enabled rows at MVP are only "Fortsetzen" and "Spiel
   beenden").
3. `ui_accept` (Enter) on "Spiel beenden" → confirmation modal opens, focus
   on "Abbrechen" (default, safety-first).
4. `ui_left`/`ui_right` or `ui_down` moves focus to "Trotzdem beenden";
   `ui_accept` confirms; or `Esc` at any point cancels back to the Pause
   Menu with zero side effects.
5. `Esc` from the Pause Menu (no modal open) → Resume, game continues
   exactly as before.

This screen carries **no MVP keyboard exemption** — unlike the villager and
project panels (both stated, tracked A2 exemptions), the Pause Menu is fully
keyboard-operable at MVP with no gap, since it is a conventional focus-order
menu list rather than a world-entity-selection surface.

---

## Events Fired

| Player Action | Event Fired | Payload / Data |
|---|---|---|
| Open Pause Menu | Time & Tick `pause()` call (only if not already paused) + local `_menu_forced_pause` flag set | none persisted |
| Resume | Time & Tick `unpause()` call (only if `_menu_forced_pause` was true) | none persisted |
| Confirm "Trotzdem beenden" (desktop) | `SceneTree.quit()` | — |
| Confirm "Trotzdem beenden" (menu, post-Alpha) | Scene/World Management transition trigger | destination = Main Menu scene |
| Cancel quit | none | — |
| All navigation/hover actions | none | — |

- **No analytics events at MVP** — same deliberate omission as the villager
  and project panels (no analytics system exists yet).
- **No persistent-state writes** — `_menu_forced_pause` is UI-local and
  ephemeral, never serialized; Time & Tick's own pause/warp state is global
  and already excluded from this UI's ownership (this screen only calls its
  existing public API, per the World Freeze section).

---

## Transitions & Animations

- **Panel open/close: instant, zero duration** — per Art Bible §2.5 ("instant
  open/close") and the project-wide "Never animates: Panel show/hide
  (instant swap)" rule (`art-bible.md` §7.4, already cited by
  `projects-panel.md`). No fade, no scale-in.
- **World freeze/dim: instant** — the dim/desaturation applies the same
  frame the menu opens; no fade-to-dim. Matches "zero ambient motion" (§2.5)
  and A5 motion restraint exactly.
- **Confirmation modal: instant appear/dismiss**, consistent with the same
  rule — this is a second panel, not a toast, so it does not inherit any
  toast-style fade.
- **Quit execution**: instant — the Pause Menu and its modal close the same
  frame "Trotzdem beenden" resolves; for Quit to Menu (post-Alpha), the
  standard Scene/World Management transition overlay (P12) takes over
  immediately after, with no double-overlay moment.
- Zero animation beyond these instant swaps — A5 trivially satisfied, no
  reduced-motion variant needed.

---

## Data Requirements

| Data | Source System | Read / Write | Notes |
|---|---|---|---|
| Pause state (`paused`) | Time & Tick System | Read + Write (existing `pause()`/`unpause()` API) | This screen calls the same API Space already calls — no new pause mechanism |
| Time-warp value | Time & Tick System | Read only | Never touched — orchestration only forces/restores `paused`, never the stored warp speed (Core Rule 3) |
| Suspended signal | Camera & Input | Read | Gates every entry point — Pause Menu cannot open while Suspended (mirrors P14) |
| Last rendered frame (for freeze/dim/desaturate) | Rendering (new capability) | Read | Implementation approach (viewport capture vs. render-halt) deferred to `godot-specialist`/`ui-programmer` — see Open Questions |
| UI timer/expiry manager freeze flag | ADR-0011's centralized manager | Write (new trigger) | Cross-doc dependency — see World Freeze section point 4 |
| Scene transition trigger (Quit to Menu, post-Alpha) | Scene/World Management | Write | Disabled at MVP — no Main Menu scene exists yet |
| OS quit (Quit to Desktop) | Engine (`SceneTree.quit()`) | Write | No game-system dependency |

No architectural concerns beyond the two explicitly flagged cross-doc
dependencies above (ADR-0011's freeze trigger, camera-input.md's new halt
trigger) — both are additive, not redesigns of either system.

---

## Accessibility

Per `design/ux/accessibility-requirements.md`:

- **A1**: the confirmation modal's message text is the sole carrier of the
  "why" — no color-only signal exists on this screen at all (disabled rows
  are greyed AND non-activatable AND tooltip-labeled, never grey alone).
  QA: grayscale pass over the Pause Menu panel, disabled-row state, and the
  confirmation modal.
- **A2 keyboard access**: **no MVP exemption on this screen** — every row
  and every confirmation button is reachable and operable via
  `ui_up`/`ui_down`/`ui_accept`/`Esc` with no mouse dependency (see Keyboard-
  Only Path above). This is a stronger accessibility position than either
  sibling panel and worth stating explicitly as a positive, not a gap.
- **A3/A4**: text `#EDE6DA` on `#262220` (≈12:1, inherited); menu row labels
  and the confirmation message ≥18px; all text wraps, never truncates.
- **A5 motion restraint**: zero animation anywhere on this screen (Transitions
  & Animations section); the dim/desaturation treatment applies instantly,
  with **no flash** — a single, instant step-change in brightness, not a
  strobe. State-carrying world markers stay undesaturated through the dim
  per Art Bible §7.6, preserving A1's hue channel through the frozen
  backdrop specifically (this is the reason §7.6's exemption exists at all).
- **A6**: no new audio cue is introduced by this spec; if a future "menu
  open/close" sound ships, its visible counterpart is already satisfied by
  the instant panel swap (game fully playable muted).
- **A7**: `pause_menu_toggle` is a named, project-scope InputMap action per
  the existing A7 discipline — no hardcoded key.

---

## Localization Considerations

- **Menu row labels are UI-owned chrome text** (P10 carve-out), German at
  MVP: "Fortsetzen" (10), "Einstellungen" (13), "Zum Hauptmenü" (13),
  "Spiel beenden" (13) — all short, safe under the +40% expansion tolerance.
- **The confirmation message is the longest text on this screen** and the
  HIGH PRIORITY item for localization: "Es gibt noch kein Speichersystem –
  dein Fortschritt geht beim Beenden verloren." is multi-line by design and
  must wrap, never truncate — same rule as every other why-string in this
  project (villager-panel's C4, projects-panel's status labels).
- **Confirmation button labels** ("Abbrechen" / "Trotzdem beenden") are
  short; "Trotzdem beenden" (16 chars) is the longer of the two and sets the
  practical floor for that button's minimum width — verify at final font
  lock.
- **Disabled-row tooltip** ("Bald verfügbar") is short and safe.
- No numeric/date/currency content anywhere on this screen.

---

## Acceptance Criteria

- [ ] AC-UX1 The Pause Menu opens within 1 frame of either of its two
  guaranteed entry points at MVP (HUD button, `M`), from any game state
  (WorldNav, Build Mode Idle, tool armed, an active Selection) — plus, via
  Esc-terminal, once `building-ui.md` Rule 14's proposed 5th step lands
  (Open Question 2; QA must not fail this criterion against the current
  4-step chain, where Esc-terminal is not yet wired).
- [ ] AC-UX2 Opening the Pause Menu calls Time & Tick's existing pause API
  (never `SceneTree.paused`/`Engine.time_scale`) and correctly restores the
  prior pause state on close — still paused if it was already paused before
  opening, running if it wasn't.
- [ ] AC-UX3 The background renders as a dimmed (~60% brightness) and
  desaturated freeze of the last rendered frame, EXCEPT state-carrying
  markers (distress icons, unreachable ghosts, invalid-cue afterglow) which
  remain in full color (Art Bible §7.6) — including when the game was
  already paused (E11 active) before the Pause Menu opened: only this
  screen's ~60% treatment is visible, never E11's dim stacked on top of it.
- [ ] AC-UX4 Camera movement and all world/HUD input are fully suppressed
  while the Pause Menu is open; closing it restores camera pose and input
  with no snap, mirroring `camera-input.md`'s existing exact-state-restore
  guarantee.
- [ ] AC-UX5 Clicking "Spiel beenden," or "Zum Hauptmenü" once enabled,
  always shows the confirmation modal first — no quit path executes without
  passing through it.
- [ ] AC-UX6 The confirmation modal's default focus is "Abbrechen," never
  the destructive option, on every open.
- [ ] AC-UX7 Every interactive element on this screen (menu rows,
  confirmation buttons) is reachable and operable via keyboard only
  (`ui_up`/`ui_down`/`ui_accept`/`Esc`), with zero MVP exemption.
- [ ] AC-UX8 "Einstellungen" and "Zum Hauptmenü" render visibly greyed,
  non-activatable, and show the "Bald verfügbar" tooltip on hover/focus at
  MVP — never silently missing or clickable-but-broken.
- [ ] AC-UX9 The Pause Menu cannot be opened while Camera & Input is
  Suspended (scene transition in progress) — all three entry points are
  no-ops during that state.
- [ ] AC-UX10 All text on this screen (menu labels, confirmation message)
  remains fully visible at 1280×720 with no truncation.
- [ ] AC-UX11 A grayscale screenshot pass confirms state-carrying world
  markers stay distinguishable through the pause-dim treatment (A1, citing
  the §7.6 exemption).

---

## Open Questions

1. **`hud.md` follow-up required** — this spec claims a new Z1 element (the
   Menu button) and a new full-screen overlay tier (the Pause Menu itself,
   analogous to the existing Transition Overlay row); `hud.md`'s Layout
   Zones table needs a corresponding update in its own revision (out of
   scope for this spec to edit).
2. **`building-ui.md` Rule 14 (TR-building-ui-076) needs its proposed 5th
   Esc-chain step** — turning the chain's current terminal no-op (WorldNav,
   no Selection, no tool) into "open the Pause Menu." This is a real
   behavioral change to that GDD's own contract and must land in its next
   revision, not this document. Recommend running
   `/propagate-design-change`, matching this project's existing convention
   for this kind of cross-doc dependency (see `building-ui.md`'s own Open
   Question 10 for a precedent example of the same propagation pattern).
3. **`camera-input.md` needs a second input-halt trigger** distinct from
   Suspended (which that GDD explicitly reserves for scene transitions
   only) — fired by Pause Menu open/close, same exact-state-restore
   contract. Not added by this spec.
4. **`docs/architecture/adr-0011-...md` needs a second timer-freeze
   trigger** distinct from Suspended, so toast grace/debounce timers freeze
   while the Pause Menu is open (World Freeze section, point 4). This is an
   architecture-level change, flagged here for the ADR's own revision.
5. **Settings and Quit-to-Menu are both blocked on the same not-yet-built
   system.** `Main Menu & Settings` is Alpha-tier and "Not Started"
   (`systems-index.md` rows 27/187); `scene-world-management.md` Core Rule 1
   confirms MVP boots directly into the Valley with no menu at all. Both
   rows are reserved/disabled at MVP by this spec's own decision and become
   functional together once that system ships — not a gap in this spec, a
   documented dependency on work that hasn't started. **This spec IS the
   "Pause/system menu" `design/ux/main-menu.md`'s own Open Question 9
   anticipated** ("If/when a Pause/system menu is designed, it should add a
   return-to-Main-Menu entry point here — cross-reference this spec at that
   time") — this document's "Zum Hauptmenü" row is exactly that
   return-to-Main-Menu entry point, and `main-menu.md` should cross-link
   back to this spec at its own next revision.
6. **Save row intentionally omitted, not merely disabled** — per ADR-0012,
   Save/Load & World Persistence is VS-tier, not MVP-blocking. Add a "Speichern"
   row once that system exists, and revisit the Destructive-Action
   Confirmation Policy at the same time (it should become a dirty-flag
   check rather than an unconditional warning once saving is possible).
7. **Player journey map missing** — same shared gap as `hud.md` OQ1 /
   `villager-panel.md` OQ1 / `projects-panel.md` OQ2; create before the VS
   UX revision.
8. **Frozen-frame implementation approach** (viewport texture capture vs.
   halting re-render and reusing the last framebuffer, plus the dim/
   desaturate shader) is an engine-feasibility question for
   `godot-specialist`/`ui-programmer`, not decided by this spec.
9. **Gamepad entry point** — technical-preferences names "menu/camera only"
   as the post-MVP partial gamepad scope; the Pause Menu is exactly that
   kind of context and a natural first target once gamepad work begins.
   Not designed now.
10. **"Destructive Navigation Confirmation" as a candidate new pattern** for
    `interaction-patterns.md` — flagged, not added by this spec (scope: this
    document only). **Reconcile with `design/ux/main-menu.md`'s sibling
    precedent** at the same future pattern-library session: that spec's M5/
    Open Question 5a ("Destructive Confirmation Modal," its New Game
    overwrite confirmation) reasons through the identical exception to the
    P6 no-modal baseline independently of this spec. The two should likely
    converge into ONE named pattern (e.g. "Destructive Confirmation Modal")
    with two documented consumers (New Game overwrite; Quit-with-unsaved-
    progress) rather than shipping as two separately-justified one-offs.
11. **Paused-during-transition re-verification at Alpha** — this spec's
    "not a real state, cannot occur" conclusion depends on Quit to Menu
    being disabled; re-verify once that path is enabled and a scene
    transition can genuinely begin while quitting from within the Pause
    Menu.
