# Villager Info UI

> **Status**: Approved (2026-07-11 — reviewed NEEDS REVISION → contract-alignment revision (2 user rulings) → verification pass CLEAN)
> **Author**: user + Claude Code Game Studios agents
> **Last Updated**: 2026-07-11
> **Last Verified**: 2026-07-11
> **Implements Pillar**: Pillar 2 — A settlement that feels alive (reading villagers); Pillar 4 — Clarity over complexity (the why is always one click away)

## Summary

Villager Info UI is how the player reads a villager: click a villager
(while no build tool is armed) and a compact side panel shows their
name, current activity, need levels, mood band, and — most importantly
— the *why* ("tired — no bed", verbatim from the Needs system). Its
only always-on element is the distress indicator: a subtle overhead
icon on villagers in trouble (trapped, ground-sleeping), so problems
are visible without clicking. Like all UI in this project it is a pure
mirror — it owns nothing but the current selection.

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: `Villager AI & Behavior, Needs & Mood System`

## Overview

**Player-facing:** this is the window into Pillar 2. The villager
panel turns simulation state into a person: a name, what they're
doing, how they feel, and what they need from you. Per Pillar 4, the
"why" is always one click away — mood is never a mystery. Per the
quiet-HUD principle (Building UI), nothing villager-related clutters
the screen permanently; only genuine distress earns an overhead icon.

**System-facing:** a presentation layer beside Building UI. It claims
exactly one input niche: in Idle (no build tool armed), a click that
hits a villager selects them; everything else remains untouched
(Building owns armed-tool clicks; empty Idle clicks deselect). It
mirrors Villager AI (activity, distress) and Needs & Mood (values,
band, why-string) by re-reading their state each update on raw delta —
signals serve as wake hints, never as value sources (Rule 3's
state-over-events model).
Out of scope: villager rosters/lists, camera-focus-on-villager,
portraits, renaming — all VS+ (Open Questions).

## Player Fantasy

**"I know my villagers."**

1. **Meeting them.** Click — and the blocks-person becomes *someone*:
   a name, a task, a feeling. The moment attachment starts.
2. **Understanding at a glance.** One panel answers "how are they
   doing and why" without menus or math — care without homework.
3. **Never missing a cry for help.** The distress icon means I don't
   have to patrol my villagers; trouble finds my eyes. (The UI half of
   the Villager AI's never-teleport/visible-distress philosophy.)

Reference feeling: RimWorld's colonist readout stripped to Stonehearth
warmth — informative, never clinical. NOT the fantasy: a stat sheet,
a manage-everything dashboard, or Sims needs-micromanagement.

> `creative-director` not consulted — Lean mode (non-high-risk
> sections). Review manually before production.

## Detailed Design

### Core Rules

1. **Selection** exists only in Idle (no build tool armed): a click
   whose pick hits a villager selects them; a click hitting nothing
   deselects; Esc deselects; clicking another villager switches. [TR-villager-info-ui-028] While
   any build tool is armed, all clicks belong to the Building pipeline
   — selection is untouchable (no accidental villager-clicks
   mid-build). [TR-villager-info-ui-001] **Two routing clauses** *(added 2026-07-11 review)*:
   - **HUD-hover gate**: the villager-hit query honors the SAME shared
     world-pick hover-suppression flag Building UI's Rule 11 defines —
     while the cursor hovers any HUD element, the query does not run:
     a click over the HUD can neither select a villager rendered
     behind it nor deselect (the HUD consumes that click). One flag,
     every world-pick consumer (reciprocal generalization added to
     Building UI Rule 11). [TR-villager-info-ui-002]
   - **Esc routing**: if a Building UI element holds keyboard focus (a
     focused toast, the expanded anchor — its Rule 9b), Esc first
     releases THAT focus; only an Esc pressed with no HUD focus
     deselects the villager. Deterministic two-step, no double-fire. [TR-villager-info-ui-029]
   - **Keyboard-selection exemption** *(explicit, user decision
     2026-07-11)*: selecting a villager is 3D spatial targeting, a
     different class from HUD chrome — MVP ships selection as
     mouse-only, as a STATED exemption from the "no persistent element
     is mouse-only" commitment (Building UI Rule 9b), not an oversight.
     A keyboard selection path (select-cycle / focus-nearest-distressed)
     is committed to the VS revision alongside the roster view (Open
     Question 1). [TR-villager-info-ui-030]
2. **The panel** (right side, compact) shows: name, current activity
   as a player-readable label (**all SIX AI states** — Deciding →
   "Thinking", Traveling → "On the way", Working → "Working", Sleeping
   → "Sleeping", **Breather → "Taking a break"**, Wandering →
   "Strolling"; exact wording to the UX spec, the six-way mapping is
   the contract — *corrected 2026-07-11: the doc said "five", but
   Villager AI's state table gained Breather at its review and its own
   UI Requirements text was stale; "Thinking" exists for mapping
   completeness — near-invisible at MVP, staggered-visible at scale
   per Villager AI Rule 10c*), one bar per active need (MVP: sleep),
   the mood-band icon (3 states), the why-string (Rule 2b), and the
   distress icon-flag when active. [TR-villager-info-ui-031]
2b. **The why-slot is ONE slot** *(added 2026-07-11 — the precedence
   was consumed "verbatim" but never restated)*: it shows text
   whenever a need is urgent or mood is not Happy, and its CONTENT is
   governed by Needs Core Rule 11's precedence, consumed whole —
   distress/trapped cue > need-why > structural string; among multiple
   urgent needs, strongest-drain wins with schema-order tie-break. The
   panel's distress flag is the ICON companion to that slot, never a
   second competing text: when a distress flag is active, the why-slot
   text IS the distress-derived template (Rule 11's "never directs to
   the wrong fix" guarantee). [TR-villager-info-ui-032]
3. **Live mirror — state over events** *(clarified 2026-07-11 — the
   old "via their signals" wording contradicted AC17)*: while
   selected, the panel **re-reads upstream state directly each update
   frame** (raw delta — readable during pause); upstream signals
   (band-change, despawn, distress) are wake/dirty hints and event
   triggers, never the source of displayed values — no cached copies
   (the same state-over-events consumption model Needs established). [TR-villager-info-ui-033]
   It holds selection when the villager walks off-screen (no camera
   follow in MVP — Open Question). Selection is the only state this
   system owns — held as a stable villager id/handle whose identity
   stability across Suspended transitions is `[assumption]` until
   Villager AI's identity work lands (its OQ 5; see Open Questions). [TR-villager-info-ui-010]
4. **Overhead distress icon**: villagers with an active distress flag
   (**trapped, ground-sleeping** — Villager AI Edge Case 2 / Rule 12)
   show a subtle icon above their head, visible unselected,
   disappearing when the cause resolves. **"No-bed" is deliberately
   NOT a third icon state** *(user decision 2026-07-11, resolving the
   flag-count drift)*: chronic bedlessness has no awake-limbo state —
   Villager AI Rule 12 transitions urgent-sleep → ground-sleep
   same-tick, so bedlessness becomes visible as ground-sleeping
   exactly when it matters, and the panel why-string still names the
   precise cause verbatim ("no bed" vs "trapped"); an icon over a
   currently-fine bedless villager would violate "only genuine
   distress earns an icon" (reciprocal fix applied to Villager AI's
   UI Requirements flag list). No permanent mood icons over heads
   (Pillar 4 calm; the panel is where mood lives). [TR-villager-info-ui-034] *Implementation
   note (parallel to Building UI's Edge Case 6 pattern): one manager
   drives all N icons — one Suspended signal hides all, one iteration,
   never N independent subscriptions; distress flags are state-derived
   conditions, not pulses, so flicker is not expected — if playtest
   shows boundary flicker, a hold-time knob is the remedy (Open
   Questions).* [TR-villager-info-ui-035]
5. **Why-strings pass through verbatim** from Needs & Mood (its UI
   contract) — this UI never composes its own explanations. [TR-villager-info-ui-036]
6. The panel design assumes N villagers (VS ~5, ceiling 20–30) from
   day one — selection is per-villager; only the roster/list view is
   deferred (Open Questions). [TR-villager-info-ui-037]

### States and Transitions

| State | Entry | Exit | Behavior |
|-------|-------|------|----------|
| Unselected | Boot, deselect, villager despawn | Villager clicked (Idle mode) | No panel; overhead distress icons still visible |
| Selected(v) | Click hit villager v | Deselect / other villager / Suspended | Panel live-mirrors v; overhead icons unchanged |
| Suspended | Camera & Input Suspended | Reactivation | Panel + icons hidden; selection retained through the transition [TR-villager-info-ui-038] |

### Interactions with Other Systems

- **Villager AI & Behavior** (upstream, MVP): activity state, name,
  distress flags (its Rule 12/Edge Case 2 + Info UI contract); a
  villager-hit query for selection picking.
- **Needs & Mood System** (upstream, MVP): need values, mood band +
  band-change events, why-strings (its UI Requirements contract).
- **Camera & Input** (upstream, MVP): mouse-ray + click actions in
  Idle; Suspended propagation. Selection introduces no new InputMap
  actions (reuses the existing click action in the unclaimed Idle
  niche). [TR-villager-info-ui-039]
- **Building UI** (MVP sibling): mode coordination — armed tool ⇒
  Building pipeline owns clicks; Idle ⇒ this system may claim
  villager hits. One rule, no overlap.
- **Scene/World Management** (upstream): hosting; Suspended.

## Formulas

*(`systems-designer` consulted — mandatory even in Lean mode. Verdict:
zero formulas.)*

**None** — pure mirror; selection is a consumed hit-result, need bars
are raw upstream values on the pre-contracted 0–100 scale, and icon
placement is engine projection, not designed math. See Interactions for
the upstream contracts this UI reads but never computes.

## Edge Cases

1. **Selected villager despawns** (none in MVP; waves later) → graceful
   deselect, panel closes — never a stale panel. [TR-villager-info-ui-040]
2. **Ray hits villager and block** → nearest hit wins by ray-parametric
   distance in world units; "tie" is defined by an explicit tolerance —
   `|t_villager − t_block| < pick_tie_epsilon` (small constant,
   `[assumption]` until implementation) → the villager wins (the
   interactive entity). [TR-villager-info-ui-015] *(Re-specified 2026-07-11: floating-point ties
   never occur naturally across two query mechanisms — the old wording
   was mock-only-testable.)* **Query separation**: villager hit-testing
   is a dedicated physics query on a dedicated villager collision
   layer, distinct from and never consulted by the block-picking query
   (whichever mechanism — physics vs. DDA — the building ADR picks for
   voxel-world's open picking question); the two hits are merged by
   comparing their world-unit distances. Building's own placement
   raycast ignores the villager layer (no ghost flicker from villagers
   walking through the pick). [TR-villager-info-ui-014]
3. **Several villagers along the ray** → nearest wins, deterministic
   (same parametric-distance rule; equal-distance villagers break ties
   by stable villager processing order, matching Villager AI's
   determinism convention). [TR-villager-info-ui-016]
4. **Selection during pause** → fully functional (raw delta); the
   frozen villager's panel reads normally. [TR-villager-info-ui-041]
5. **Distress while selected** → overhead icon and panel flag derive
   from the same signal — they can never disagree. [TR-villager-info-ui-042]
6. **Suspended during selection** → selection retained through the
   transition (the villager kept simulating); panel restores on return. [TR-villager-info-ui-038]
7. **Build tool armed while a villager is selected** (key 1–5) → the
   panel closes and selection clears — clean mode switch, mirroring
   Rule 1's exclusivity. [TR-villager-info-ui-043]
8. **Why-string exceeds panel width** → wraps, never silently truncates
   (Pillar 4). [TR-villager-info-ui-044]
9. **Many distressed villagers far away** → overhead icons may overlap
   at distance; accepted in MVP (clustering → VS+, Open Questions).
10. **Villager behind the bottom toolbar** → overhead icon may be
    occluded by HUD; accepted in MVP (the panel and warnings still
    surface the problem).

## Dependencies

### Upstream (systems this one depends on)

| System | GDD Status | What this system consumes |
|--------|-----------|---------------------------|
| Villager AI & Behavior | ✅ Approved | Activity state (six states incl. Breather), name, distress flags (its Info-UI contract, corrected 2026-07-11); villager-hit query for selection |
| Needs & Mood System | ✅ Approved | Need values (0–100), mood band + change events, why-strings verbatim incl. Core Rule 11's full precedence (Rule 2b) |
| Camera & Input | ✅ Approved | Mouse-ray + click action in Idle; Suspended propagation. No new InputMap actions |
| Scene/World Management | ✅ Approved | Hosting; Suspended during transitions |
| Building UI | ✅ Approved (sibling) | Click-ownership rule (armed tool ⇒ Building pipeline; Idle ⇒ villager hits may select) AND the shared world-pick hover-suppression flag (its Rule 11, Rule 1's HUD-hover gate) |

### Downstream (systems that depend on this one)

| System | Tier | GDD Status | What it consumes |
|--------|------|-----------|------------------|
| Onboarding / Tutorial | Vertical Slice | Undesigned | The "meet your villager" teachable beat *(provisional)* |

## Tuning Knobs

**None gameplay-facing** — every player-visible value here is
presentation (panel metrics, icon sizes, timings → UX spec / art
bible). One implementation constant exists: `pick_tie_epsilon` (Edge
Case 2's villager-vs-block tie tolerance, `[assumption]` until
implementation — a correctness constant, not a tuning knob).

## Visual/Audio Requirements

Mood-band icons (3) and the overhead distress icon are
**differentiated by icon SHAPE + label/tooltip, never by hue alone**
(the Visual Direction Note's §4 day-one pairing rule — the same
commitment the sibling GDDs carry; "colorblind-safe" is the mechanism,
not just a label). [TR-villager-info-ui-045] The distress icon delivers Villager AI's
distress-cue requirement — gentle, cozy-not-alarming per Pillar 3. A
**pre-click hover affordance is required** (cursor change or subtle
highlight when the pointer is over a selectable villager — exact
treatment to the UX spec; without it the "curiosity test" bets on
blind discovery) [TR-villager-info-ui-046], plus a subtle selection outline on the villager
(outline mechanism → godot-shader-specialist at implementation) [TR-villager-info-ui-047], and
the panel in the warm UI style. Audio: a soft select sound only (a
distress-onset audio cue is deferred to the audio spec — Open
Questions). [TR-villager-info-ui-048] **New assets required**: 3 mood icons (distinct
silhouettes), distress icon, hover-affordance treatment,
selection-outline treatment.

## Game Feel

Click → panel the same frame; selecting feels like *touching* a
villager, not opening a menu. Deselection is equally instant. **Feel
acceptance criterion** (playtest): players click a villager unprompted
within their first minutes (curiosity test), and can afterwards say how
the villager is doing and why.

## UI Requirements

This GDD *is* the UI — pointer forward:

> 📌 **UX Flag — Villager Info UI**: In Phase 4 (Pre-Production), run
> `/ux-design villager-panel` before writing epics. Stories should cite
> `design/ux/villager-panel.md`, not this GDD directly.
> **Explicit guidance for that pass** *(2026-07-11 review)*: the MVP
> panel shows ONE need bar — the layout must read as
> minimal-by-design with room to grow (reserved space, generous
> whitespace), never as an incomplete stat sheet; and the pre-click
> hover affordance (Visual/Audio Requirements) is a required
> deliverable, not optional polish. [TR-villager-info-ui-046]

## Cross-References

| Reference | Document | What | Nature |
|-----------|----------|------|--------|
| Info-UI contract: state labels, distress flags; hit query | `design/gdd/villager-ai-behavior.md` | UI Requirements, Rule 12, Edge Case 2 | Order sheet (villager half) |
| UI contract: values, band, why-string verbatim | `design/gdd/needs-mood-system.md` | UI Requirements | Order sheet (needs half) |
| Click ownership, quiet-HUD principle, zones | `design/gdd/building-ui.md` | Rules 1/11 | Sibling coordination |
| Mouse-ray, click actions, Suspended, raw-delta/pause contract | `design/gdd/camera-input.md` | Core Rules 7–10 (Rules 9–10 authored 2026-07-10) | Input contract |
| Blue–orange axis, cozy tone | `design/art/visual-direction-note.md` | State axis | Visual constraint |
| Pillar 2/4, onboarding beat | `design/gdd/game-concept.md` | Pillars, Flow | Scope authority |

## Acceptance Criteria

*(`qa-lead` consulted — mandatory for this high-risk section even in
Lean mode. Review produced 4 rewrites and 3 missing criteria; all
incorporated. The 2026-07-11 full design review rewrote AC6 (six
states) and added AC21–26. Split per the project's test-evidence
table.)*

**Blocking — headless unit tests** [TR-villager-info-ui-023]
1. **GIVEN** Idle mode and a mocked villager hit, **WHEN** click fires, **THEN** that villager is selected and the panel opens. [TR-villager-info-ui-028]
2. **GIVEN** Idle and a mocked empty hit, **WHEN** click fires, **THEN** selection clears; **GIVEN** Esc, **THEN** likewise. [TR-villager-info-ui-028]
3. **GIVEN** villager A selected and a hit on B, **WHEN** click fires, **THEN** selection switches to B in one step. [TR-villager-info-ui-028]
4. **GIVEN** any build tool armed (mocked), **WHEN** a click fires, **THEN** no selection change — clicks belong to Building (Rule 1). [TR-villager-info-ui-001]
5. **GIVEN** a selected villager and a mocked tool-arm event, **THEN** the panel closes and selection clears (Edge Case 7). [TR-villager-info-ui-043]
6. **GIVEN** each of the SIX AI activity states (mocked) in turn — Deciding, Traveling, Working, Sleeping, **Breather**, Wandering, **WHEN** selected, **THEN** the panel shows the correct distinct player-readable label for each; **WHEN** the state changes while selected, **THEN** the label updates the same frame (Rule 2, full six-way mapping — *corrected 2026-07-11 from "five": Breather was untested*; Deciding's label is a mapping-completeness check, not an expected player observation at MVP). [TR-villager-info-ui-031]
7. **GIVEN** mocked need values, **WHEN** rendered, **THEN** each active need bar shows the raw 0–100 value — no UI-side scaling or smoothing. [TR-villager-info-ui-049]
8. **GIVEN** a mood band change event, **WHEN** received, **THEN** the band icon updates (band signal only). [TR-villager-info-ui-031]
9. **GIVEN** mood not Happy or a need urgent, **THEN** the why-string renders verbatim from the Needs payload; **GIVEN** mood Happy AND no urgent need, **THEN** the why-string area is empty/hidden (Rule 2 both directions). [TR-villager-info-ui-032] [TR-villager-info-ui-036]
10. **GIVEN** a mocked distress flag set on any villager (selected or not), **THEN** its overhead icon activates; **WHEN** cleared, **THEN** it deactivates (Rule 4). [TR-villager-info-ui-034]
11. **GIVEN** a distressed villager selected, **THEN** panel flag and overhead icon reflect the same source state — single source, no divergence (Edge Case 5). [TR-villager-info-ui-042]
12. **GIVEN** pause (mocked), **THEN** click-to-select, panel value updates, and Esc-deselect all still fire on the paused frame — raw delta (Edge Case 4). [TR-villager-info-ui-041]
13. **GIVEN** Suspended active with a selection, **THEN** panel and overhead icons are hidden while the selection value persists unchanged; **WHEN** reactivated, **THEN** the same villager is selected and the panel restores (Edge Case 6 + state table). [TR-villager-info-ui-038]
14. **GIVEN** a selected villager despawn event, **THEN** selection clears gracefully — no stale panel, no error (Edge Case 1). [TR-villager-info-ui-040]
15. **GIVEN** a mocked ray with a villager and a nearer block, **THEN** the block wins; **GIVEN** overlap/tie, **THEN** the villager wins (Edge Case 2). [TR-villager-info-ui-015]
16. **GIVEN** a mocked ray hitting villagers A/B/C at different distances, **THEN** the nearest is selected — deterministic and repeatable (Edge Case 3). [TR-villager-info-ui-016]
17. **GIVEN** 20+ mocked villagers, **WHEN** selecting #1 then #17, **THEN** exactly one villager is ever selected and every panel value reflects live upstream state — mutating the upstream mock directly (bypassing signals) never leaves a stale local copy on reselect (Rules 3/6: selection is the ONLY owned state). [TR-villager-info-ui-033] [TR-villager-info-ui-037]

**Added by design review (2026-07-11) — blocking headless**
21. **GIVEN** the shared hover-suppression flag active (mocked cursor-over-HUD), **WHEN** a click fires over a villager rendered behind the HUD, **THEN** no selection change occurs — neither select nor deselect (Rule 1 HUD-hover gate). [TR-villager-info-ui-002]
22. **GIVEN** a villager selected AND a Building UI element holding keyboard focus (mocked), **WHEN** Esc fires, **THEN** the HUD focus releases and the selection is UNCHANGED; **WHEN** Esc fires again with no HUD focus, **THEN** the villager deselects (Rule 1 Esc routing — deterministic two-step). [TR-villager-info-ui-029]
23. **GIVEN** a mocked trapped flag AND an urgent sleep need simultaneously, **WHEN** the panel renders, **THEN** the why-slot shows the distress-derived template ("trapped"), never the need-why — Rule 2b precedence (Needs Core Rule 11's "never directs to the wrong fix"). [TR-villager-info-ui-032]
24. **[Forward-looking — multi-need arrives VS+]** **GIVEN** two mocked urgent needs, **WHEN** the panel renders, **THEN** the why-slot shows the strongest-drain need's string; **GIVEN** equal drains, **THEN** schema order breaks the tie (Rule 2b, Needs Core Rule 11 tie-break). [TR-villager-info-ui-032]
25. **GIVEN** a mocked bedless villager who is AWAKE and not distress-flagged, **WHEN** rendered, **THEN** no overhead icon shows; **WHEN** their sleep turns urgent and they ground-sleep, **THEN** the ground-sleeping icon activates (Rule 4's no-bed fold — the negative half). [TR-villager-info-ui-034]
26. **GIVEN** a mocked villager-hit at distance t₁ and block-hit at t₂ with |t₁−t₂| < `pick_tie_epsilon`, **WHEN** the pick resolves, **THEN** the villager wins; **GIVEN** the block strictly nearer beyond epsilon, **THEN** the block wins (Edge Case 2's explicit tolerance — replaces the untestable float-tie). [TR-villager-info-ui-015]

**Advisory — interaction test / manual walkthrough**
18. **GIVEN** a live viewport, **WHEN** a villager walks behind the toolbar, **THEN** the accepted occlusion is documented (walkthrough, Edge Case 10).
19. **GIVEN** a long why-string, **THEN** it wraps with no silent truncation (visual check, Edge Case 8). [TR-villager-info-ui-044]
20. **GIVEN** a first-time playtester, **THEN** they click a villager unprompted within the first minutes and can afterwards state how it's doing and why (Game Feel — playtest doc).

## Open Questions

1. **Roster/list view** of all villagers — now ALSO carries the
   committed **keyboard selection path** (select-cycle /
   focus-nearest-distressed; the MVP mouse-only exemption in Rule 1 is
   explicitly temporary) → *Vertical Slice, once ~5 villagers exist* [TR-villager-info-ui-030]
2. **Camera focus on selected villager** (requires a new "focus on
   point" API from Camera & Input) → *Vertical Slice, with camera-input*
3. **Distress icon clustering** at distance (Edge Case 9) → *VS+*
4. **Portraits, renaming, identity display** → *with villager identity
   generation (Villager AI OQ 5), Vertical Slice*. Until that lands,
   Rule 3's selection-handle identity stability across Suspended is
   `[assumption]` — verify against Scene/World Management's transition
   mechanics at implementation. [TR-villager-info-ui-010]
5. **UX spec** (incl. hover affordance, minimal-by-design panel layout,
   distress-icon billboard mode — full vs. Y-locked, pending camera
   angle) → */ux-design villager-panel in Pre-Production (see the UX
   Flag)* [TR-villager-info-ui-027]
6. **Proactive distress alerting at population scale** *(2026-07-11
   review)* — the overhead icon is passive/spatial; at VS ~5 and the
   20–30 ceiling, an off-screen trapped villager pings nothing. Whether
   distress should ALSO surface through an active channel (Building
   UI's issues anchor? an audio cue on distress onset?) → *VS revision,
   with the roster view + audio spec*
7. **Distress-icon flicker hold-time** — flags are state-derived, so
   flicker is not expected; if the playtest shows boundary flicker, a
   hold-time knob (parallel to Building UI's grace class) is the
   remedy → *MVP playtest*
