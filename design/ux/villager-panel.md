# UX Spec: Villager Panel

> **Status**: Approved (/ux-review 2026-07-12 — verdict APPROVED; both advisories resolved)
> **Author**: user + ux-designer
> **Last Updated**: 2026-07-12
> **Journey Phase(s)**: unknown — no player journey map yet (see Open Questions)
> **Template**: UX Spec
> **Behavioral source of truth**: `design/gdd/villager-info-ui.md` (Approved 2026-07-11)
> **Binding inputs**: `design/ux/hud.md` (zone Z4), `design/ux/interaction-patterns.md`
> (P2, P3, P11, P13), `design/ux/accessibility-requirements.md` (A1-A7),
> `design/art/art-bible.md` §3.4/§4.5

---

## Purpose & Player Need

**"I know my villagers."** The panel turns simulation state into a person:
name, current activity, feeling, and — per Pillar 4 — the *why*, one click
away. The player arrives wanting to **check on this villager**. Without this
panel Pillar 2 would be invisible: mood and needs would exist only as numbers
in memory, and the build→live loop would have no face. The panel is the
attachment moment — the first unprompted click that makes the blocks-person
*someone* (villager-info-ui Game Feel: curiosity test).

---

## Player Context on Arrival

First encounter: within the first minutes of play — the player has just built
a room and a bed and clicks the single MVP villager out of curiosity
(feel AC: unprompted). Emotional state to design for: **calm, curious, proud**
— never time-pressured (real-time with pause; the panel is fully functional
while paused, TR-villager-info-ui-041). Arrival is always voluntary (a click);
the game never forces this panel open.

---

## Navigation Position

Not a screen — an **in-gameplay overlay**:
`Gameplay (Idle mode) → villager selection → panel (HUD zone Z4)`.
Context-dependent: reachable only while no build tool is armed (Rule 1).
No menu path, no alternate entry routes.

---

## Entry & Exit Points

| Entry Source | Trigger | Player carries this context |
|---|---|---|
| Click on villager | Idle + shared hover-suppression gate clear (P2) + hit on the villager collision layer | villager id (stable handle) |
| Switch selection | Click on another villager | new id, single step (AC3) |
| Reactivation after Suspended | transition complete/abort | same id — selection survives the transition (TR-villager-info-ui-038) |

| Exit Destination | Trigger | Notes |
|---|---|---|
| Deselect (panel closes) | Click on empty space / Esc with no HUD focus (P11 two-step) | Instant, no fade |
| Tool armed | Key 1-5 or toolbar click | Panel closes, selection cleared — clean mode switch (TR-villager-info-ui-043) |
| Villager despawns | Despawn event | Graceful close, never a stale panel (TR-villager-info-ui-040); cannot occur in MVP |
| Suspended | Transition-begin | NOT an exit — panel hidden, selection retained (TR-villager-info-ui-038) |

No one-way exits — selection is always recoverable with another click.

---

## Layout Specification

### Information Hierarchy

Order follows the GDD's fantasy sentence ("a name, what they're doing, how they
feel, and what they need"):

1. **Name** — identity, the attachment anchor (header).
2. **Activity label** — what they are doing right now (six states).
3. **Mood icon + why-string** — feeling and reason, always paired, never split
   (the why is the panel's reason to exist — Pillar 4).
4. **Need bar(s)** — the detail layer (MVP: sleep only, reserved growth space).

The distress flag is the ICON companion of the why row (TR-villager-info-ui-032
— never a second competing text).

### Layout Zones

The panel occupies **HUD zone Z4: left edge, lower half, grows upward**
(hud.md, user decision 2026-07-11). **Deliberate deviation from GDD wording**:
villager-info-ui.md Rule 2 says "(right side, compact)" in passing; the HUD
pass placed inspection LEFT so warning toasts (right) never cover the panel of
the villager they are about. The GDD delegates panel layout to this spec —
flag the parenthetical for cleanup at the GDD's next revision.

### Component Inventory

| # | Component | Type | Interactive | Pattern / Source |
|---|---|---|---|---|
| C1 | Name | Text header, >= 18 px | No | Villager AI (name) |
| C2 | Activity row | Icon + player-readable label (6-state mapping) | No | P3, TR-villager-info-ui-031 |
| C3 | Mood row | Band icon (distinct SHAPE) + band label | Tooltip only | P3, A1, TR-045 |
| C4 | Why-slot | Multi-line text; hidden when mood Happy AND no urgent need | No | P3, TR-032/TR-036 |
| C5 | Distress flag | Icon beside C4, only while a flag is active | Tooltip only | P3/P13, TR-042 |
| C6 | Need bar "Sleep" | Value bar (B2) + raw 0-100 value | No | B2, TR-049 |
| — | Panel container | Flat panel `#262220`, sharp corners, warm-white text `#EDE6DA` | Consumes clicks (no world-pick through the panel, P2) | Art bible §3.4/§4.5 |

World-space companions owned by this spec:

- **Hover affordance** (user decision 2026-07-11): "inspect" cursor change
  **plus** a faint outline pre-glow on the hovered villager (reduced-intensity
  reuse of the selection shader). Required deliverable, not polish (TR-046).
- **Selection outline**: full-intensity outline in Hearth Gold `#F5A83C`
  (mechanism → godot-shader-specialist, TR-047).
- **Overhead distress icon**: **full billboard** (user decision 2026-07-11 —
  always camera-facing, equally readable at every orbit pitch 0.15-1.5 rad;
  readability outranks physicality for a distress signal). This resolves
  TR-villager-info-ui-027 / GDD Open Question 5.

### ASCII Wireframe

```
        (zone Z4 — left edge, lower half, compact)
┌────────────────────────────┐
│ Hilda                      │  C1 name header
│ ──────────────────────     │
│ ⚒  Working                 │  C2 activity: icon + label
│                            │
│ ◆  Content                 │  C3 mood: shape icon + band label
│ "tired — no bed"        ⚠  │  C4 why-slot (wraps) + C5 distress flag
│                            │
│ Sleep ▓▓▓▓▓▓▓░░░░ 62       │  C6 need bar (B2) + raw value
│                            │
│  (reserved growth space —  │  deliberate whitespace: reads as
│   grows upward from VS on) │  minimal-by-design, never unfinished
└────────────────────────────┘
```

---

## States & Variants

| State / Variant | Trigger | What Changes |
|---|---|---|
| Hidden (default) | No selection | Nothing rendered; overhead distress icons stay independent |
| Visible (live) | Villager selected | Panel live-mirrors upstream state every frame (raw delta) |
| Paused | Game pause | Values frozen (simulation halted) — panel stays fully interactive (TR-041) |
| Suspended | Scene transition | Panel + overhead icons hidden; selection retained; restores on complete/abort (TR-038) |
| Stale handle (error) | Retained selection id cannot be resolved on reactivation (TR-010 assumption fails) | Treated exactly like despawn: graceful deselect, panel stays closed, no error surface — never a stale or broken panel |
| Why-slot empty | Mood Happy AND no urgent need | C4/C5 collapsed; panel height stays stable — no layout jumping |
| Distress | Distress flag active | C5 icon shows; C4 shows the distress-derived template (precedence per TR-032) |

No loading state (all data is local), no empty state (the panel only opens with
a valid selection), no progression variants at MVP.

**Committed activity-label set** (the GDD delegates exact wording to this spec;
six-way mapping is the contract, TR-031):

| AI state | Player-readable label |
|---|---|
| Deciding | "Thinking" |
| Traveling | "On the way" |
| Working | "Working" |
| Sleeping | "Sleeping" |
| Breather | "Taking a break" |
| Wandering | "Strolling" |

---

## Interaction Map

Mapping interactions for: **Keyboard/Mouse (primary), PC only.** Gamepad: none
at MVP (partial, menu/camera only, post-MVP).

| Action | Input | Immediate feedback | Outcome |
|---|---|---|---|
| Select villager | Left-click on villager (Idle, P2 gate clear) | Panel opens same frame + soft select sound + selection outline | Selection = clicked id |
| Switch selection | Left-click on another villager | Panel re-targets in one step | Selection = new id |
| Deselect | Left-click on empty space | Panel closes instantly | Selection cleared |
| Deselect (keyboard) | Esc with no HUD focus (P11 two-step) | Panel closes instantly | Selection cleared |
| Arm tool | Keys 1-5 / toolbar click | Panel closes, outline clears | Mode switch to Building (TR-043) |
| Hover selectable villager | Mouse move | "Inspect" cursor + faint outline pre-glow, same frame | — |
| Inspect mood/distress icon | Hover C3/C5 | Tooltip (label text, P10) | — |
| Click on panel | Left-click inside Z4 | Consumed — no world pick through the panel (P2) | No-op |

---

## Events Fired

| Player Action | Event Fired | Payload / Data |
|---|---|---|
| Select | `villager_selected` (UI-internal signal: panel + outline + camera-VS-hook) | villager id |
| Deselect / switch | `villager_deselected` (switch = deselect + select) | previous id |
| All other actions | none | — |

- **No analytics events at MVP** — deliberate; no analytics system exists.
- **No persistent-state writes** — selection is the only owned state and is
  never serialized (villager-info-ui Rule 3; save/load never sees it).

---

## Transitions & Animations

- **Panel enter/exit: instant, same frame** as the triggering click — selecting
  feels like *touching* a villager, not opening a menu (GDD Game Feel). No
  slide, no fade (pattern-library animation standards).
- **Value updates**: need bar renders the raw value every frame with NO easing
  (B2, A5 motion restraint); activity label and band icon swap instantly on
  state/band change.
- **Suspended hide/restore**: instant with the rest of the HUD (P14).
- Zero animation in the panel — A5 trivially satisfied; no reduced-motion
  variant needed.

---

## Data Requirements

All reads re-query upstream state every update frame (state-over-events,
raw delta — TR-033); signals are wake/dirty hints only. **This UI writes
nothing** — selection is the only owned state and is never persisted.

| Data | Source System | Read / Write | Notes |
|---|---|---|---|
| Villager name | Villager AI | Read | Identity display; portraits/renaming VS+ |
| Activity state (6 states) | Villager AI | Read | Mapped via the committed label set |
| Distress flags (trapped, ground-sleeping) | Villager AI | Read | Drives C5 + overhead icon from ONE source (TR-042) |
| Villager-hit query | Villager AI (dedicated collision layer) | Read | Separate from block picking (TR-014) |
| Need values (0-100) | Needs & Mood | Read | Raw, no UI-side scaling (TR-049) |
| Mood band + change events | Needs & Mood | Read | Band icon; events trigger, state sources |
| Why-string | Needs & Mood | Read | Verbatim pass-through (TR-036) |
| Hover-suppression flag | Building UI | Read | Gates the hit query (P2) |
| Tool-armed state | Building System | Read | Rule 1 exclusivity |
| Suspended signal | Camera & Input | Read | Hide/restore (P14) |

No architectural concerns: everything follows the established mirror model.

---

## Accessibility

Per `design/ux/accessibility-requirements.md`:

- **A1**: mood-band icons (3 distinct shapes) + distress icon differentiated by
  shape + label/tooltip, never hue alone. QA: grayscale pass over all panel and
  overhead states.
- **A2**: mouse-only villager selection is the STATED, tracked MVP exemption
  (keyboard path committed for VS). The panel itself contains no focusable
  elements at MVP — no focus-order requirements; Esc-deselect works without
  the mouse.
- **A3/A4**: text `#EDE6DA` on `#262220` (≈12:1); body >= 16 px, name/why/labels
  >= 18 px at 1080p; all text wraps, never truncates.
- **A5**: zero panel animation; overhead icon is static (no pulse) at MVP.
- **A6**: the soft select sound's visible counterpart is the panel opening
  itself; fully usable muted.

---

## Localization Considerations

- **Why-strings are the longest text** (template set owned by Needs & Mood).
  C4 is multi-line by design and tolerates +40% expansion (German/French) —
  wraps, never truncates (TR-044).
- **HIGH PRIORITY: activity labels must stay one line.** Budget: the label
  column fits **>= 20 characters** ("Taking a break" = 14 chars + 40% expansion
  ≈ 20); any translation exceeding 20 characters must be shortened editorially,
  never auto-truncated. Verify against the final font at implementation.
- Band labels (Happy/Content/Low) are short; +40% safe.
- Need values are raw 0-100 integers — locale-neutral, no formatting.
- Villager names are generated content, not localized (identity system VS+).

---

## Acceptance Criteria

Complementing the GDD's 26 behavioral ACs with the presentation level
(QA-verifiable without reading other documents):

- [ ] AC-UX1 The panel opens on the SAME frame as the selecting click
  (frame-capture check) and closes instantly on deselect.
- [ ] AC-UX2 The need bar renders correctly at value 0 and value 100 (fill,
  raw number, no easing).
- [ ] AC-UX3 Esc with a focused HUD element releases that focus WITHOUT closing
  the panel; a second Esc (no HUD focus) deselects (two-step routing).
- [ ] AC-UX4 The why-slot is hidden when mood is Happy and no need is urgent;
  otherwise it shows the upstream string verbatim.
- [ ] AC-UX5 A 3+-line why-string wraps fully visible at 1280x720 — no
  truncation, no overflow outside the panel.
- [ ] AC-UX6 Grayscale pass: all mood-band states and the distress state remain
  distinguishable with saturation removed (A1).
- [ ] AC-UX7 All panel text >= 16 px (name/why/labels >= 18 px) at 1080p and
  meets 4.5:1 contrast on the final theme (A3/A4).
- [ ] AC-UX8 Hovering a selectable villager shows the inspect cursor AND the
  outline pre-glow on the same frame; both clear when the cursor leaves.
- [ ] AC-UX9 The overhead distress icon is readable at minimum and maximum
  camera pitch (full-billboard check at 0.15 and 1.5 rad).
- [ ] AC-UX10 With the game paused: select, switch, value display, and
  Esc-deselect all work normally.

---

## Open Questions

1. **Player journey map missing** — template at
   `.claude/docs/templates/player-journey.md`; create before the VS UX revision.
2. **Exact panel dimensions/paddings** — at implementation against the final
   font (this spec fixes hierarchy, anchors, and growth rules).
3. **Roster view + keyboard selection path** — GDD OQ1, Vertical Slice.
4. **Camera focus on selected villager** — GDD OQ2, VS (needs camera-input API;
   `villager_selected` signal is the prepared hook).
5. **Distress-icon clustering at distance** — GDD OQ3, VS+.
6. **Portraits / renaming / identity display** — GDD OQ4, VS; selection-handle
   stability across Suspended stays `[assumption]` until then (TR-010).
7. **Proactive distress alerting at population scale** — GDD OQ6, VS revision
   (issues-anchor channel? audio cue?).
8. **Distress-icon flicker hold-time** — GDD OQ7, MVP playtest.
