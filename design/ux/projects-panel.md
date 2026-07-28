# UX Spec: Projects Panel

> **Status**: **Approved** — `/ux-review` 2026-07-23 (first pass: NEEDS REVISION,
> 0 blocking / 4 advisory; all 4 applied and re-review verdict APPROVED, 0/0)
> **Author**: user + ux-designer
> **Last Updated**: 2026-07-23
> **Journey Phase(s)**: unknown — no player journey map yet (shared gap with
> `hud.md` OQ1 / `villager-panel.md` OQ1)
> **Template**: UX Spec
> **Behavioral source of truth**: `design/gdd/building-system.md` (Rules
> 14a–14n, TR-building-system-102..127) + `design/gdd/building-ui.md` (Rule
> 21, TR-building-ui-075..088); entity lifecycle governed by
> `docs/architecture/adr-0016-build-project-entity-lifecycle.md`
> **Binding inputs**: `design/ux/hud.md` (zone system — this spec claims
> **Z7**), `design/ux/villager-panel.md` (sibling on-demand panel, shares the
> left-edge zone group), `design/ux/interaction-patterns.md` (P1, P2, P8, P9,
> P11, P16, B1–B4), `design/ux/accessibility-requirements.md` (A1–A7),
> `design/art/art-bible.md` §7 (panel anatomy §7.5, shape grammar §7.3, motion
> rules §7.4)
> **Provisional predecessor**: `prototypes/last-seal-vertical-slice/hud.gd`
> (slice-validated bottom-left card layout, `_build_projects_panel` /
> `_make_project_row`) — guidance only per Art Bible §7.5/§7.6; this spec is
> the production decision and may deviate where noted.

---

## Purpose & Player Need

**"I know what my settlement is building."** Villagers are people (the
villager panel's job); projects are the *promises the player made to the
world* — a drawn wall, a stamped house, a queued dig — and this panel is
where the player checks whether those promises are being kept. Per
ADR-0016, a project is a persistent entity with a real lifecycle
(Draft → Building ⇄ Paused → Done, plus demolition), and the vertical slice
found this workflow to be **core UX**, not chrome: the tester's strongest
positive reaction ("Ich bin sehr begeistert") came specifically from watching
persistent projects progress. Without this panel, that lifecycle would be
invisible outside the world itself — the player would have no way to check
on a project across a growing settlement without hunting down its cells by
eye.

---

## Player Context on Arrival

First encounter: shortly after the player's first committed build action
(a wall drag, a Room-tool rectangle, or a House stamp) — the panel appears
the instant a project exists, unprompted, so the player discovers it by
building rather than by being told about it. Emotional state to design for:
**orienting, checking-in, mildly proud** — the same "calm, curious" register
as the villager panel, never time-pressured (fully functional while paused,
mirroring P7/P14). Distinct from the villager panel's *voluntary click*
arrival: the projects panel's *first* appearance is a direct **consequence**
of a build action, not a click — after that, it is read-only ambient
information until the player interacts with a card.

---

## Navigation Position

Not a screen — an **in-gameplay overlay**:
`Gameplay → any build commit → panel appears (HUD zone Z7)`. Persists across
Build Mode / World Navigation (Rule 8d's project-selection exception means
projects stay selectable and visible in either mode) and across Idle/tool-armed
states — unlike the villager panel (which closes when a tool arms, P3/Rule 9),
the projects panel is **not selection-scoped to a mode**; it is scoped only to
"does at least one project exist" (see Empty & Edge States).

---

## Entry & Exit Points

| Entry Source | Trigger | Player carries this context |
|---|---|---|
| First project created | Any tool's commit produces a Draft project (wall/floor/roof/Room/Auto-roof/House stamp/dig order) | Panel becomes visible for the first time, no selection |
| Reactivation after Suspended | Transition complete/abort | Panel + its Selection restore exactly as before (P14) |
| World click on a project cell | Any mode, tool armed or not (Rule 8d exception, TR-building-ui-077) | That project becomes the Selection; its card is promoted to a pinned full card if it was overflowed, and scrolled into view |
| Click a visible project card | Panel interaction | That project becomes the Selection; world-space outline renders (reciprocal, Rule 21) |

| Exit Destination | Trigger | Notes |
|---|---|---|
| Selection clears (panel stays open) | Click empty world space / Esc with no higher-priority HUD focus (P11 chain step 3) / villager wins a tied click (Rule 15 precedence) | Card de-highlights; panel itself does not close |
| Panel hides entirely | The last project entity is deleted (ADR-0016 §7: every cell canceled or demolished away) | Graceful, instant — see Empty & Edge States |
| Suspended | Transition-begin | NOT an exit — panel + card list hidden, Selection retained (P14) |

There is no modal exit — a project's card is always recoverable by clicking
any of its cells or scrolling the list, exactly as villager selection is
always recoverable by another click.

---

## Layout Specification

### Information Hierarchy (card content priority)

Per card, in reading order — matches how the player actually asks "what is
this project doing":

1. **Kind icon + Name** — identity and category first (a dig order reads
   differently from a house the instant you see it, before you read status).
2. **Status** — state icon + label text, plus the pending-changes badge when
   a change order is attached (Rule 14h) — "what's happening to it right now."
3. **Progress `X/Y` + bar** — the detail layer; shown for every state that
   has a meaningful cell count (see States & Variants table), never hidden
   to avoid layout jump.
4. **Workers** — who is currently on it; the most granular, most
   volatile info, so it sits last and only appears when it means something
   (BUILDING only).
5. **Action buttons** — the player's next decision, bottom-anchored so the
   reading flow (identity → status → progress → actors) always resolves into
   an action, never the reverse.

This mirrors the villager panel's "name → activity → feeling → detail" flow
(P3) with a fifth beat added for the actions a project (unlike a villager)
actually exposes to the player.

### Layout Zones

**New HUD zone: Z7 — Projects Panel.** Anchored **bottom-left corner**
(screen edge, at the standard 16px-at-720p edge inset shared with every other
zone), stacked **below** Z4's growth envelope. Two separate claims here:
first, `hud.md`'s Z4 rule ("left edge, lower half, grows upward") is
deliberately abstract about what "lower half" is measured from, and this
spec does not rewrite that text. Second, *now that Z7 exists*, this spec
fixes the concrete baseline Z4 grows from in practice: a baseline that sits
one `ZONE_GAP` above Z7's top edge, not the true screen bottom — so a
villager selection and an active project list can be on-screen
simultaneously without ever overlapping. `hud.md` itself is not edited by
this spec; see Open Questions for the required hud.md follow-up (its Zone
table and 8-element Visual Budget need a Z7/E-number added — that is where
this concrete baseline should eventually be folded back into the abstract
rule's own text).

```
┌─────────────────────────────────────────────┐
│                                  [⏸ 1x 2x 3x]│  Z1
│                                  [⚠ Toast]   │  Z2
│                                  [ 3 ! ]     │  Z3
│ ┌──────────┐                                 │
│ │ Villager │        (world)                  │  Z4 (grows upward from
│ │  Panel   │                                 │      just above Z7)
│ └──────────┘                                 │
│ ┌──────────────┐                             │
│ │ Projects (Z7)│                             │  Z7 (bottom-left corner,
│ │ ▣ Haus 3     │                             │      bounded height,
│ │  Im Bau  ▓▓░ │                             │      internal scroll)
│ │  2/12  Hilda │                             │
│ │  [Pause][X]  │                             │
│ │ ──────────── │                             │
│ │ +2 weitere · │                             │
│ │   Fertig  ▸  │                             │
│ └──────────────┘                             │
│         ┌─────────────────────┐              │
│         │ Context panel (Z5)  │              │
│    ┌────┴─────────────────────┴────┐         │
│    │ [1][2][3][4][5]  |  [↩][↪]    │         │
└────┴──────────────────────────────┴──────────┘
```

| Zone | Anchor | Contents | Visibility |
|---|---|---|---|
| **Z7 (new)** | Bottom-left corner | Projects Panel: header + bounded card list + overflow summary row | Contextual — visible iff ≥ 1 project entity exists anywhere |

Layout rules:

- Same relative-anchoring / 1280×720 minimum-layout / 16px-at-720p edge-inset
  discipline as every other zone (hud.md Layout rules — this spec adds no new
  rule, it inherits the existing one).
- Z7's width matches the slice's provisional `260px` and max height `320px`
  as inherited reference values — exact dimensions lock at implementation
  against the final font (same deferral hud.md and villager-panel.md already
  use).
- Z7 never grows into the center third of the screen (hud.md's Visual Budget
  invariant) — its height is hard-bounded; overflow is handled by the
  bounded-visible-count pattern below, never by unbounded panel growth.

### Component Inventory

| # | Component | Type | Interactive | Pattern / Source |
|---|---|---|---|---|
| C1 | Panel header "Projekte" | Text label, section title | No | UI-owned chrome text (P10 — localization-ready, not database-driven), Art Bible §7.5 header-divider rule |
| C2 | Card list (bounded, scrollable) | Container (B3-adjacent) | Scroll only | Art Bible §7.5 panel anatomy |
| C3 | Card — kind icon + name | Icon (shape, tooltip-labeled) + text header ≥18px | Tooltip only | P10 (tooltip), A1 |
| C4 | Card — status row | State icon (shape) + status label text | No | A1; Art Bible §7.3 shape-budget item (proposal below) |
| C5 | Card — pending-changes badge | Small icon + "Änderungen geplant" label, co-occurs with any status | No | Rule 14h, A1 |
| C6 | Card — progress bar + `X/Y` | Value bar (B2-analog) + tabular-numeral count | No | Art Bible §7.4 (no easing, raw value every frame) |
| C7 | Card — workers row | Text, comma-separated names or placeholder | No | Villager AI attribution (ADR-0016 §4), A4 wraps-never-truncates |
| C8 | Card — action button row | 1–2 B1 buttons, state-dependent | Yes | B1, Rule 21 |
| C9 | Card — selection highlight | 2px Hearth-Gold border on the card | No (reflects state) | Art Bible §7.1 channel 2 (transient selection, not Function-tier) |
| C10 | Overflow summary row "+N weitere · Fertig ▸" | Compact row (B3 row shape) | Yes (expand/collapse) | B3 List pattern, same precedent as the issues anchor (Z3) |
| — | Panel container | Flat panel `#262220`, sharp corners, 1px chrome-edge hairline border + header divider | Consumes clicks (no world-pick through panel, P2) | Art Bible §7.5 |

World-space companion owned by this spec (shared mechanism with the villager
panel, not duplicated):

- **Selection outline**: the identical Hearth-Gold world-space outline
  mechanism the villager panel already specifies (villager-panel.md
  "Selection outline"), rendered around the **project's full footprint**
  instead of a single entity — one Selection, two renders, per
  building-ui Rule 21/TR-building-ui-086.
- No new hover-preglow is introduced for project cells beyond the existing
  **always-on hover wireframe + hit-face quad** every pick already renders
  (building-ui Rule 17/TR-building-ui-079) — a dedicated project-hover glow
  is not committed at MVP (see Open Questions).

### ASCII Wireframe (single card, BUILDING state)

```
┌──────────────────────────────┐
│ ▣ Haus 3            ⛭ Im Bau │  C3 kind icon+name · C4 status icon+label
│ ▓▓▓▓▓▓▓▓░░░░░░░░░░  2/12     │  C6 progress bar (no easing) + tabular count
│ Hilda, Toran                 │  C7 workers (wraps, BUILDING only)
│ [ Pause ]  [ Abbrechen ]     │  C8 state-dependent action row
└──────────────────────────────┘
     ↑ 2px Hearth-Gold border only while this card is the Selection (C9)
```

---

## States & Variants

Consolidated for sibling parity with `villager-panel.md`'s "States & Variants"
section. Panel-level states first; the detailed per-project lifecycle states
(Draft/Building/Paused/Done/Done+pending/Demolishing) are specified in full,
with their exact per-state visible content and buttons, in **Per-State
Actions & Button Placement** below — not duplicated here.

| State / Variant | Trigger | What Changes |
|---|---|---|
| Hidden (default) | No project entities exist anywhere | Z7 renders nothing (see Empty & Edge States) |
| Visible (live) | ≥ 1 project entity exists | Card list live-mirrors Building System state every refresh; see the per-project state table below for card-level detail |
| Suspended | Scene transition | Panel, card list, and world-space outline hidden; Selection retained; restores on transition complete/abort (P14) |

**No loading state**: all reads are synchronous per-frame re-queries of
Building System state (mirrors `villager-panel.md`) — there is no
network/disk fetch in the loop, so no spinner/skeleton state is ever needed.
No dedicated "stale handle" state either: a project deleted while selected
is handled as a graceful-deselect edge case (see Empty & Edge States), the
same treatment the villager panel gives an unresolvable retained selection.

---

## Scalability: Bounded Visible Count + Overflow

The slice's flat list assumed a handful of projects; a production settlement
will not. This spec commits to a **priority-ranked bounded list**, the same
structural idea as the toast stack's `toast_max_visible` + issues-anchor
overflow (Z2/Z3, P1) — cap by priority, never by an arbitrary category rule:

- **Sort order**: tier first, then recency within tier.
  1. **BUILDING** (in progress — most actionable)
  2. **PAUSED** (stalled — needs a player decision)
  3. **DRAFT** (awaiting release)
  4. **DONE + pending change order** ("Änderungen geplant" — awaiting release,
     same urgency class as Draft)
  5. **DONE, settled** (no pending changes — lowest priority; nothing left to
     decide except an eventual Abriss)

  *Rationale*: this orders by "how much does the player need to look at this
  right now," matching the HUD philosophy's 30-second decision test — a
  finished, untouched house needs no attention and sinks to the bottom.
  Within a tier, **most-recent state-transition first** (not creation order):
  the project the player most recently touched or that most recently made
  progress surfaces first — the thing you just interacted with is the thing
  you're most likely checking on again.

- **Tuning knob `projects_panel_max_visible_cards`** (proposed default: **6**,
  matching the slice's bounded height at the provisional 260×320 envelope):
  if the total project count is at or below this cap, every project renders
  as a normal full card — **no overflow row exists at zero-pressure**, exactly
  like Z2/Z3's "zero issues → fully hidden" rule.
- **Overflow**: once the count exceeds the cap, the panel renders the
  top `(max_visible_cards − 1)` cards by the sort order above, and bundles
  the remainder into a single **"+N weitere · Fertig ▸"** summary row (C10)
  at the list's bottom — expandable (B3 List pattern, same mechanism as the
  issues-anchor's expanded list) into a compact secondary list: name + kind
  icon + status only, no progress bar/workers (those projects are settled;
  the only remaining action is Abriss). The remainder always drains from the
  **lowest-priority tier first** (settled DONE), then upward through the
  tiers only if settled DONE alone can't fill the overflow — priority order
  is never violated.
- **Selection pin (exception)**: the currently-selected project is **always**
  rendered as a full card, even if its tier/recency rank would otherwise place
  it in the overflow bundle — the game never hides the thing the player is
  currently looking at. Selecting an overflowed project (by clicking one of
  its world cells) promotes it to a pinned full card and scrolls it into
  view, bumping the next-lowest-priority visible card into the overflow
  bundle instead.
- **Within-cap scrolling**: the bounded card list still scrolls internally
  (inherits the slice's `ScrollContainer` + `ensure_control_visible` behavior)
  for the visible, non-overflowed cards — scrolling and the overflow bundle
  are complementary, not competing, mechanisms: scrolling handles "more cards
  than fit on screen but still within the cap," overflow handles "more
  projects than the cap allows to exist as cards at all."

**Candidate pattern-library entry**: this priority-tiered bounded list +
Selection Pin exception is generic enough to outlive this one panel — any
future entity-list HUD surface (e.g. a caravan/expedition roster, a resource
stockpile list) would want the identical "cap by priority, pin the selected
item, drain the lowest tier into an expandable overflow row" behavior. Flagged
here as a candidate addition to `interaction-patterns.md`, extending P1's
cap+overflow-home idea from a flat severity queue to a multi-tier sorted
list; not added to that library by this spec (scope: this document only) —
see Open Questions.

---

## Selection Model

Selection is a **single shared value** with the villager panel's exact
mutual-exclusivity rule generalized (building-ui Rule 15,
TR-building-ui-077): villager XOR project XOR none. Selecting a project never
requires Build Mode to be on (Rule 8d's stated exception) — a project is
selectable from World Navigation with no tool armed, the one interaction that
works outside Build Mode.

- **World click → panel reacts**: clicking any cell belonging to a project
  (in any state, any mode) makes it the Selection; its card highlights
  (Hearth Gold, C9) and scrolls into view in the same frame — this is the
  slice-validated behavior (`_on_project_selected`), carried forward exactly.
- **Panel click → world reacts**: clicking a card selects that project
  identically; the world-space outline renders around its full footprint
  (Rule 21's reciprocal-highlight contract) — one Selection, two renders,
  never two independent states.
- **Villager wins ties**: a villager standing on a project cell claims the
  click (Rule 15 precedence) — unchanged, this spec does not touch that rule.
- **Camera focus on selection: NOT at MVP.** The villager panel already
  flagged optional camera-focus-on-select as an open question (its OQ4,
  deferred to Vertical Slice pending a camera-input API). This spec makes the
  **same call for consistency** rather than introducing new behavior for one
  panel and not its sibling — both should land together once that API exists
  (see Open Questions).
- **Esc chain (the existing 4-step chain, TR-building-ui-076, unchanged by
  this spec — reusing, not re-specifying)**:
  1. If the overflow summary row (C10) is expanded and holds HUD keyboard
     focus, Esc collapses it only (joins the same routing as the
     issues-anchor's expanded list, P11).
  2. Else if a tool is armed, Esc cancels it.
  3. Else if a Selection is active (villager OR project), Esc clears it —
     the panel stays open, only the highlight/outline clear.
  4. Else if Build Mode is on, Esc exits to World Navigation.
  A press with no applicable step is a no-op, exactly as building-ui Rule 14
  already specifies.

---

## Per-State Actions & Button Placement

Buttons always render **name/status first, buttons last** (bottom row),
primary (forward-progressing) action on the left, secondary (regressive)
action on the right — consistent left-to-right reading order across every
state:

| State | Visible content beyond name/kind icon | Buttons | Placement |
|---|---|---|---|
| **DRAFT** ("Geplant") | Progress `0/Y` (or partial) + bar; no workers row | **Bau starten** (primary, left) · **Verwerfen** (secondary, right) | Both instant, no confirmation (see Confirmation Policy) |
| **BUILDING** ("Im Bau", gold status text) | Progress bar/count; workers row (names, or placeholder if none claimed yet) | **Pause** (left) · **Abbrechen** (right); **+ Bau starten** appended if a pending change-order batch exists (releases just that batch) | Up to 3 buttons; wraps to a second row if the card width can't fit 3 (never truncates a label) |
| **PAUSED** ("Pausiert") | Progress bar/count frozen at last value; workers row hidden (claims revoked, nobody currently on it) | **Fortsetzen** (left) · **Abbrechen** (right); **+ Bau starten** if a pending batch exists | Same as BUILDING |
| **DONE, settled** ("Fertig", gold label) | Progress `Y/Y`; workers row hidden | **Abriss** only | If pinned as a full card (selected) or expanded in the overflow row |
| **DONE + pending change order** ("Änderungen geplant" badge, C5) | Progress reflects the WHOLE project incl. the new batch's added cells (e.g. `12/15`, not a separate counter) | **Bau starten** (releases only the pending batch) (left) · **Abriss** (right) | Never collapses to overflow — pending changes make it actionable |
| **Demolishing** ("Wird abgerissen", State-Orange status text+icon) | Kind icon + name + status only — progress bar, count, and workers row are **hidden**, not frozen (a stale "12/12" reading during teardown would misreport reality) | **None** — nothing to click; the card disappears on its own once every cell is gone (mirrors the slice's `demolishing` branch exactly) | — |

### Destructive-Action Confirmation Policy

**Decision: no confirmation modal for Abriss/Abbrechen, at any project
state — consistent with the existing interaction-pattern library, not a new
exception.** The pattern catalog (`interaction-patterns.md`) has no
confirmation-dialog pattern anywhere — P6 is explicit that invalid/blocking
feedback is "never modal," B1 defines no "confirm" button state, and the
whole HUD philosophy is "speed over ornament," instant and forgiving rather
than friction-gated. Introducing a modal here would be a new pattern
invented for one button, contradicting that baseline. Two things already do
the job a confirmation dialog would:

1. **Demolition is job-gated, not instant** (building-system Rule 14j) — a
   torn-down cell takes real simulated time to actually disappear, and the
   card's status flips to "Wird abgerissen" the same frame as visible,
   truthful feedback (Key Responsibility 6: the player always knows what
   happened and why).
2. **MVP has no resource-cost economy yet** (REPORT.md shortcut) — an Abriss
   currently has near-zero permanent cost to the player beyond rebuild time,
   which weakens the case for adding friction now.

**This strengthens, rather than weakens, the no-modal case once undo is
factored in.** Abriss/Abbrechen against a project's **Built** cells creates
**no undo entry at all** — building-ui Rule 23/TR-building-ui-088 states the
undo stack never lists a demolition step, and building-system's Rule 17/
TR-building-system-119 confirms undo has zero effect on fully-Built work.
Once triggered, tearing down Built geometry is only reversible by physically
rebuilding it — there is no "undo my demolished house" path. This is a
**deliberate asymmetry**, distinct from the DRAFT-state **Verwerfen**
button, which discards only never-built plan cells and stays fully
undo-tracked like any other plan edit (P8). A confirmation dialog would
normally exist precisely to guard an irreversible action like this — but per
the Decision above, this project still resolves that need through the
job-gated delay + visible status flip rather than a modal, keeping every
destructive action on the same instant, non-punishing footing the rest of
the HUD already commits to.

This is flagged forward in Open Questions: once a resource-cost economy
ships, revisit whether tearing down a costly, fully-Built project needs a
lightweight non-modal safeguard (e.g. a brief undo-style grace window, not a
dialog) — no MVP action is required today.

---

## Status Communication

### State → shape+label pairing (proposals for Art Bible §7.3's shared
shape-budget table — **not final**, that table is owned by the first
production icon pass and must reconcile these against toast/mood/tool-state/
distress/dig-marker icons so no two unrelated states share a silhouette):

| State | Proposed icon shape | Label text (DE) | Text color |
|---|---|---|---|
| DRAFT | Hollow/dashed square outline — "not committed yet" | "Geplant" | Warm-white `#EDE6DA` |
| BUILDING | Solid filled triangle (upward) — reuses the "in progress" read | "Im Bau" | Hearth Gold |
| PAUSED | Two vertical bars (reuse of the existing pause glyph already established by E3's time-control pause icon — familiarity over novelty) | "Pausiert" | Warm-white |
| DONE (settled) | Solid filled circle | "Fertig" | Hearth Gold |
| DONE + pending changes | Circle with a small corner "+" badge (co-occurs with, does not replace, the circle) | "Fertig" + separate "Änderungen geplant" badge label | Hearth Gold (status) / warm-white (badge) |
| Demolishing | State-Orange filled square with a diagonal strike — deliberately distinct from the world-space dig/demolition marker silhouette (Art Bible §7.1/§7.3 open item), never sharing shade or pulse alone | "Wird abgerissen" | State Orange |
| Kind: build | Small filled square (generic block glyph) | Tooltip "Bauprojekt" | Neutral |
| Kind: dig | Small pick/shovel-style glyph, distinct silhouette from build | Tooltip "Abbauprojekt" | Neutral |

Every state pairs its shape with the status text label — never color alone
(A1). The "Im Bau" gold text and "Wird abgerissen" orange text are
**secondary reinforcement**, not the sole signal; a grayscale pass must still
distinguish every row by shape.

### Progress Bar Behavior

- Renders the **raw value every frame**, straight from Building System's
  `built_cells`/`total_cells` — **no easing**, per Art Bible §7.4 (this is a
  re-read, not an animation, mirroring the villager panel's need-bar rule).
- `X/Y` uses **tabular (fixed-width) numerals** (Art Bible §7.2) since it is
  re-read every refresh tick and must not jitter width.
- Bar + count are paired, never the bar alone (A1's fill-hue rule generalized
  from B2 to this project-progress analog).

### Worker Names Display + Truncation

- Visible only in the **BUILDING** state (matches the slice exactly — a
  paused or done project has no "currently working" claim to show).
- Names render as a **comma-separated single text line that wraps to a
  second line if needed — never truncated, never an ellipsis** (A4
  generalized from the villager panel's why-string rule). Given projects
  typically have 1–3 concurrent workers at MVP settlement scale, two-line
  wrap comfortably covers realistic cases; unbounded worker counts are not
  an MVP concern (see Open Questions if squad-scale building ever changes
  this).
- If BUILDING with **zero currently-claimed workers** (job released but not
  yet picked up), the row shows a quiet placeholder — **"Wartet auf
  Arbeiter"** ("waiting on a worker") — rather than going blank, so a `0/Y`
  progress reading is never left unexplained (Pillar 4: the player always
  gets the "why").

---

## Empty & Edge States

| Situation | Behavior |
|---|---|
| **No projects exist anywhere** | Z7 is **fully hidden** — no chrome, no empty-state placeholder text. Mirrors hud.md's "zero issues → Z2/Z3 fully hidden" rule; the panel earns its screen space only when there is something to report. |
| **20+ projects** | Handled entirely by the bounded-visible-count + overflow pattern above — never an unbounded scroll, never silent truncation of the list itself (only individual long names wrap, per below). |
| **Very long project name** | Names are short by construction (`"Haus %d"`, `"Abbau %d"`, `"Projekt %d"` — system-generated, not free player text at MVP). If a future feature allows player-renamed projects, the name label **wraps to a second line** before the status row, pushing status onto its own line rather than ellipsis-truncating (A4) — this spec commits to the wrap rule now so renaming can land later without a layout redesign. |
| **Project completed while selected** | The Selection Pin exception (Scalability section) keeps it rendered as a full card regardless of tier; only its status icon/label/color update (DRAFT/BUILDING card → "Fertig" card) in the same frame the transition occurs — no flicker, no re-open. |
| **Project demolished/deleted while selected** (ADR-0016 §7: last cell canceled/removed) | Mirrors the villager panel's "stale handle" case exactly: **graceful deselect** — the card and world outline disappear instantly, Selection clears to none, no error surface, no toast. This is the intended, documented way a project's lifetime ends (not a bug state). |
| **A project's cells are entirely hidden by Slice View** | Its card and Selection state are unaffected (building-ui Edge Case 18/TR-building-ui-085, generalized from villager panel precedent) — the card keeps showing/updating even if no world-space outline can render because the relevant cells are cut away. |

---

## Interaction Map

Mapping interactions for: **Keyboard/Mouse (primary), PC only.** Gamepad:
none at MVP (partial, menu/camera only, post-MVP, per technical-preferences).

| Action | Input | Immediate feedback | Outcome |
|---|---|---|---|
| Select project (world) | Left-click a project cell, any mode (Rule 8d) | Card highlights (Hearth Gold) + scrolls into view + world outline, same frame | Selection = that project |
| Select project (panel) | Left-click a card | World outline appears, same frame | Selection = that project |
| Deselect | Left-click empty world space | Card de-highlights instantly | Selection = none |
| Deselect (keyboard) | Esc, no higher-priority HUD focus (P11 chain step 3) | Card de-highlights instantly | Selection = none |
| Release a Draft project | Click "Bau starten" | Status flips "Geplant" → "Im Bau" same frame | Project → BUILDING |
| Discard a Draft project | Click "Verwerfen" | Card removed instantly (no fade, §7.4) | Project deleted (all-Draft, free) |
| Pause a Building project | Click "Pause" | Status flips to "Pausiert", workers row hides | Project → PAUSED |
| Resume a Paused project | Click "Fortsetzen" | Status flips to "Im Bau" | Project → BUILDING |
| Cancel/demolish | Click "Abbrechen"/"Abriss" | Status flips to "Wird abgerissen", buttons disappear | Draft cells freed instantly (undo-tracked, like Verwerfen); Built cells become demolition orders — **no undo entry created, irreversible except by rebuilding** (TR-building-ui-088, TR-building-system-119; no confirmation, see policy above) |
| Expand overflow | Click "+N weitere · Fertig ▸" | Row expands into a compact secondary list, same frame | No Selection change |
| Collapse overflow | Click again, or Esc while it holds focus | Row collapses | — |
| Hover a card | Mouse move | Standard control hover state (B1) | — |
| Hover kind icon | Mouse move | Tooltip ("Bauprojekt"/"Abbauprojekt", P10) | — |
| Click inside panel (non-interactive area) | Left-click | Consumed — no world-pick through the panel (P2) | No-op |

---

## Events Fired

| Player Action | Event Fired | Payload / Data |
|---|---|---|
| Select (world or panel) | `project_selected` (existing signal, building-ui contract) | project id |
| Deselect / switch | project Selection cleared/replaced (mutual-exclusive with villager Selection, Rule 15) | previous id |
| Release / Pause / Resume / Cancel | Building System lifecycle calls (`release_project`, `pause_project`, `queue_demolition` — ADR-0016 Key Interfaces) | project id |
| All other actions (scroll, overflow expand/collapse, hover) | none | — |

- **No analytics events at MVP** — same deliberate omission as the villager
  panel (no analytics system exists yet).
- **Cancel/demolish fires no undo-stack event for Built cells** — a queued or
  executed demolition is never an undo-tracked step (TR-building-ui-088,
  TR-building-system-119), distinct from a DRAFT-state Verwerfen, which
  remains a normal undo-tracked plan edit (P8). This is the same "deliberate
  asymmetry" the Confirmation Policy section already cites — noted here too
  since it is this UI's undo-button/binding that must never list one.
- **No persistent-state writes owned by this UI** — the panel is a pure
  renderer/router over Building System's project entities (ADR-0016,
  building-ui contract: "Building UI ... Owns no project state"). Selection
  itself is UI-local and never serialized, mirroring villager-panel Rule 3.

---

## Transitions & Animations

- **Panel show/hide: instant, zero duration.** Per Art Bible §7.4's explicit
  "Panel show/hide (instant swap)" entry in the **Never animates** table —
  this is a panel, not a toast, so it does **not** inherit the toast's
  optional ≤0.2s retire fade. A project's card appears/disappears the same
  frame its underlying condition changes.
- **Progress bar/count**: raw value every frame, no easing (Art Bible §7.4,
  A5) — identical rule to the villager panel's need bar.
- **Card list reflow** (cards reordering as sort/tier changes, overflow
  promotion/demotion): instant re-layout, no slide/reorder animation —
  consistent with the "speed over ornament" baseline.
- **Selection highlight**: instant appear/clear on the same frame as the
  triggering click, exactly like the villager panel's selection outline.
- **Suspended hide/restore**: instant with the rest of the HUD (P14).
- Zero animation beyond these instant swaps — A5 trivially satisfied, no
  reduced-motion variant needed.

---

## Data Requirements

All reads re-query Building System's project entities every update/refresh
tick (state-over-events, matching the villager panel's mirror model) —
signals are wake/dirty hints, not cached truth. **This UI writes nothing**
except routing player intents (release/pause/resume/cancel) into Building
System's public surface; it owns no project state itself.

| Data | Source System | Read / Write | Notes |
|---|---|---|---|
| Project list, id, name, kind (build/dig) | Building System | Read | `projects_changed` signal triggers a refresh; card list re-sorts |
| Project state (Draft/Building/Paused/Done) + demolishing flag | Building System | Read | Drives status icon/label/color and available buttons |
| Pending change-order batch presence | Building System | Read | Drives the "Änderungen geplant" badge (C5) |
| `built_cells` / `total_cells` | Building System | Read | Progress bar + `X/Y`, raw, no UI-side scaling |
| `worker_ids` | Building System (fed by Villager AI on claim, ADR-0016 §4) | Read | Names resolved via Villager AI lookup, same pattern as villager-panel's identity read |
| Selection state | Building System / ADR-0010 routing | Read + route player intent | Mutual-exclusive with villager Selection (Rule 15) |
| Hover-suppression flag | Building UI | Read | Gates panel-click consumption (P2) |
| Suspended signal | Camera & Input | Read | Hide/restore (P14) |
| Release / Pause / Resume / Cancel intents | Building System (`release_project`, `pause_project`, `queue_demolition`) | Write (routes only — no state ownership) | ADR-0016 Key Interfaces |

No architectural concerns beyond what ADR-0016 already resolves: this spec
adds no new cross-system contract, only presentation.

---

## Accessibility

Per `design/ux/accessibility-requirements.md`:

- **A1**: every project state, kind, and the pending-changes badge pairs an
  icon **shape** with a text **label**, never color alone — gold/orange
  status text is reinforcement, not the sole signal. QA: grayscale
  screenshot pass over every card state (Draft/Building/Paused/Done/Done+
  pending/Demolishing) plus the Kind icons plus the overflow row.
- **A2**: card clicks and card buttons are **mouse-only at MVP** — the
  **same stated exemption** the villager panel already carries (P3/A2),
  extended here rather than re-litigated. Keyboard-reachable project
  selection/buttons are deferred to the same Vertical Slice work that closes
  the villager-selection keyboard gap (villager-panel OQ3) — both should land
  together since they'd share the same input-focus infrastructure. The
  overflow summary row (C10), being a focusable expandable element like the
  issues anchor, gets a named InputMap action once that work lands
  (`projects_overflow_toggle`, default key `P`, `[assumption]` per hud.md's
  own convention for provisional keybindings — mnemonic "Projects," free of
  the existing binding table).
- **A3/A4**: text `#EDE6DA` on `#262220` (≈12:1, inherited); card name/header
  ≥18px, status/meta/progress-count ≥16px with tabular numerals (Art Bible
  §7.2 tiers); all text wraps, never truncates (name, workers, status).
- **A5**: zero panel/card animation — instant swap throughout (Transitions &
  Animations section); progress bar has no easing.
- **A6**: no new audio cue is introduced by this spec; button clicks follow
  the existing "no hover sounds in MVP" convention (Sound Standards). If a
  future "project completed" cue ships, its visible counterpart is already
  satisfied by the "Fertig" status flip.
- **A7**: the one new named action (`projects_overflow_toggle`) is a project
  scope InputMap action per the existing A7 discipline, not a hardcoded key.

---

## Localization Considerations

- **Status labels are UI-owned chrome text** (P10's "screen chrome" carve-out,
  not database `display_name`), German at MVP, localization-ready:
  "Geplant" / "Im Bau" / "Pausiert" / "Fertig" / "Änderungen geplant" /
  "Wird abgerissen." Budget: status label column should tolerate the +40%
  German/French expansion tolerance already established (villager-panel
  precedent) — "Änderungen geplant" (18 chars) is the longest and sets the
  practical floor; verify at final font lock.
- **Worker names** wrap (never truncate) — same rule as the villager panel's
  why-string, generalized.
- **Kind tooltips** ("Bauprojekt"/"Abbauprojekt") are short and safe under
  expansion.
- **Progress `X/Y`** is locale-neutral raw integers, no formatting — same as
  the villager panel's need value.
- **Project names** ("Haus 3", "Abbau 2", "Projekt 5") are system-generated,
  not localized content at MVP (mirrors villager-panel's stance on generated
  villager names).

---

## Acceptance Criteria

Complementing building-ui's behavioral ACs (TR-075..088) with the
presentation level (QA-verifiable without reading other documents):

- [ ] AC-UX1 The panel is fully hidden when zero project entities exist, and
  appears the same frame the first Draft project is created.
- [ ] AC-UX2 Clicking a project's world cell in ANY mode (World Navigation or
  Build Mode, tool armed or not) highlights its card and scrolls it into view
  the same frame.
- [ ] AC-UX3 Clicking a card renders the identical world-space outline a
  world-click selection would produce (one Selection, two renders).
- [ ] AC-UX4 With project count at or below `projects_panel_max_visible_cards`,
  no overflow row renders at all; exceeding the cap produces exactly one
  "+N weitere · Fertig ▸" row draining from the lowest-priority tier first.
- [ ] AC-UX5 The currently-selected project always renders as a full card,
  even if its tier/recency rank would otherwise place it in the overflow
  bundle (Selection Pin exception).
- [ ] AC-UX6 The progress bar renders correctly at `0/Y` and `Y/Y`, with no
  easing and tabular-numeral counts that do not jitter width frame to frame.
- [ ] AC-UX7 Every project state (Draft/Building/Paused/Done/Done+pending/
  Demolishing) remains distinguishable in a grayscale screenshot pass (A1).
- [ ] AC-UX8 All card text (name, status, workers) wraps fully visible at
  1280×720 with no truncation and no overflow outside the card bounds.
- [ ] AC-UX9 Clicking "Bau starten"/"Verwerfen"/"Pause"/"Abbrechen"/
  "Fortsetzen"/"Abriss" resolves with NO confirmation dialog, and the card's
  status updates the same frame the click resolves.
- [ ] AC-UX10 A project demolished (or fully canceled) while selected clears
  the Selection gracefully with no error surface, matching the villager
  panel's stale-handle behavior.
- [ ] AC-UX11 With the game paused: select, release, pause, resume, cancel,
  and overflow expand/collapse all work normally (P7/P14 parity).
- [ ] AC-UX12 A workers row on a BUILDING project with zero current claims
  shows the "Wartet auf Arbeiter" placeholder rather than a blank row.

---

## Open Questions

1. **hud.md follow-up required** — this spec claims a new zone (Z7) and a new
   HUD element; `hud.md`'s Layout Zones table and 8-element Visual Budget
   need a corresponding row/count added in that document's own revision
   (out of scope for this spec to edit).
2. **Player journey map missing** — same gap as hud.md OQ1 / villager-panel
   OQ1; create before the VS UX revision.
3. **Exact panel/card dimensions, paddings, and font-dependent budgets**
   (e.g. the real character count "Änderungen geplant" allows before
   wrapping) — deferred to implementation against the final font, same
   deferral pattern as both sibling specs.
4. **Camera focus on project selection** — deferred alongside villager-panel
   OQ4 (needs the same camera-input API); both should resolve together at
   Vertical Slice.
5. **Keyboard selection + button focus path** — deferred alongside
   villager-panel OQ3 (shares infrastructure); closes the A2 exemption.
6. **Confirmation safeguard for Abriss once resource costs exist** — no MVP
   action needed (see Confirmation Policy); revisit when the economy systems
   land and demolishing a Built project has real sunk cost.
7. **Dedicated project-hover pre-glow** (world-space, beyond the existing
   always-on wireframe hover) — not committed at MVP; revisit if playtesting
   shows the villager panel's dedicated hover pre-glow is missed for
   projects.
8. **Shape-budget proposals in this spec are NOT final** — Art Bible §7.3
   reserves the actual shared assignment table for the first production icon
   pass; this spec's proposed shapes must be reconciled there against toast/
   mood/tool-state/distress/dig-marker icons so no two unrelated states share
   a silhouette.
9. **Door/window discoverability and the demolition world-marker shape**
   remain Art Bible §7.6 handoffs independent of this panel — not duplicated
   here, cross-referenced only where the panel's own demolition icon must
   stay visually distinct from the world-space dig/demolition marker.
