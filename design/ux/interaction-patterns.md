# Interaction Pattern Library

> **Status**: Committed (autonomous draft 2026-07-11 — user delegated decisions; review on next session)
> **Author**: ux-designer (Claude) — user-delegated autonomous run
> **Last Updated**: 2026-07-11
> **Template**: Interaction Pattern Library
> **Sources**: Extracted from the 11 approved MVP GDDs (UI Requirements +
> Detailed Rules of building-ui, villager-info-ui, camera-input,
> building-system). No UX screen specs existed yet at extraction time.

---

## Overview

This library names every recurring interaction pattern the MVP GDDs specify,
so screen-level UX specs can reference patterns instead of re-inventing them.
The GDDs remain the behavioral source of truth — each pattern entry cites its
owner GDD. When a screen spec needs behavior that differs from a pattern here,
that is a design conflict to surface, not a local override.

Input context (from technical-preferences.md): **Keyboard/Mouse primary,
PC only, no touch; partial gamepad deferred (menu/camera only, post-MVP).**
All patterns below are specified for keyboard/mouse.

---

## Pattern Catalog

| # | Pattern | Category | Owner GDD |
|---|---|---|---|
| P1 | Toast / Notification Subsystem | Feedback / Overlay | building-ui |
| P2 | Shared World-Pick Hover-Suppression Gate | Input (arbitration) | building-ui (ADR-0010) |
| P3 | Selection + Live Info Panel | Data Display | villager-info-ui |
| P4 | Pick → Preview → Commit (Drag Placement) | Input | building-system |
| P5 | Ghost / Preview Overlay | Overlay | building-system |
| P6 | Invalid-Action Cue (Non-Punishing) | Feedback | building-ui |
| P7 | Time Controls (Pause + Speed) | Input / Data Display | building-ui (state: time-tick) |
| P8 | Undo / Redo (Command-Level) | Input | building-system |
| P9 | Modal Tool Palette / Mode Switching | Navigation | building-ui |
| P10 | Data-Driven Tooltips & Labels | Data Display | resource-item-database |
| P11 | Two-Step Esc Routing | Modal / Input | building-ui + villager-info-ui |
| P12 | Loading Transition Overlay + Error Surface | Overlay | scene-world-management |
| P13 | Overhead World-Space Status Icon | Overlay | villager-info-ui |
| P14 | Suspended-Hide (Transition Arbitration) | Input / Overlay | camera-input |
| P15 | Discrete Stepper Control | Input | building-ui |
| P16 | Keyboard Access Actions | Input / Accessibility | building-ui Rule 9b |
| B1–B4 | Base controls: Button, Value Bar, List, Icon Radio Group | Input / Data Display | (composite sources — see Base Control Patterns) |

---

## Patterns

### P1 — Toast / Notification Subsystem

**Category**: Feedback / Overlay
**Used In**: Building UI (owner), fed by Build Validation (warnings) and Needs/Mood (why-strings)

**Description**: Top-right toast stack for warnings and info hints, backed by
an issues anchor ("N ⚠" counter) as the overflow home. Room confirmations are
explicitly NOT toasts (in-world celebration only).

**Specification** (full model: building-ui.md Rules 9–9d):
- Identity: every toast keyed by (signal type, subject); re-emission of a live
  key refreshes in place — no duplicates, no re-queue.
- First-appearance grace (`warning_grace_delay` 3s, wall-clock): on expiry the
  UI checks queryable validation state — cause resolved meanwhile → toast
  never appears (prevents transient-seal flicker).
- Severity: Warning outranks Info; a visible Warning is never evicted by a
  lower-severity arrival.
- Cap + overflow (`toast_max_visible` 3): overflow goes to the anchor —
  nothing is ever invisible; badge increments.
- Dismissal debounce (`min_reshow_interval` 30s) per key; dismissal hides a
  toast, never deletes the anchor record.
- Promotion: freed slot → longest-waiting anchor Warning first; Info only when
  no Warning waits.
- Reconciliation: keys whose emissions cease auto-retire within one analysis
  pass — solved problems never need manual dismissal. Warning↔Info tier-swap
  transfers elapsed grace credit.
- Focus handoff: focus never dangles — moves to next toast or the anchor.
- Timers freeze during Suspended only, never during ordinary pause (ADR-0011
  centralized expiry manager).

**When to Use**: Ambient, non-blocking problem/state notifications with a
queryable underlying cause.
**When NOT to Use**: Celebrations (in-world), fatal errors (P12), per-action
feedback (P6).

---

### P2 — Shared World-Pick Hover-Suppression Gate

**Category**: Input (arbitration)
**Used In**: Building UI (owner, Rule 11), Villager Info UI (Rule 1), Building System ghost pick, Camera & Input ray consumers. Resolved in ADR-0010.

**Description**: ONE queryable flag: "cursor is over HUD". While true, every
world-pick consumer suppresses its pick *start* — the build ghost hides, the
villager-selection query does not run, a click over HUD neither builds behind
the toolbar nor (de)selects a villager.

**Specification**:
- Single owner (Building UI) exposes the flag; consumers query, never derive
  their own hover state.
- Does NOT suppress an in-progress drag's release: a drag begun in the world
  commits on release even over HUD (locked preview, see P4).
- Exactly one owner per click (camera-input.md AC19): a UI-consumed click is
  never also emitted as a world action.

**When to Use**: Any new system that picks into the world under the cursor.
**When NOT to Use**: Keyboard-triggered world actions (not cursor-gated).

---

### P3 — Selection + Live Info Panel

**Category**: Data Display
**Used In**: Villager Info UI (owner); sources: Villager AI (state labels, distress flags), Needs & Mood (need bars, mood band, why-string)

**Description**: Click a world entity (Idle only, no build tool armed) → a
compact side panel opens the same frame and live-mirrors upstream state every
frame on raw delta (readable during pause). The panel's only owned state is
the selection itself.

**Specification**:
- Select: click villager (requires P2 gate clear + Idle). Switch: click
  another. Deselect: click empty, Esc (via P11), or arming a build tool.
- Panel contents (MVP): name, six-state activity label, sleep-need bar
  (raw 0–100), mood-band icon (shape+label, A1), why-string (wraps, never
  truncates), distress flag.
- Hover affordance required: cursor change / subtle highlight pre-click;
  selection outline while selected.
- No cached copies of upstream data — state-over-events (read each frame).
- MVP mouse-only selection is a stated exemption (accessibility-requirements.md A2).

**When to Use**: Inspectable world entities with live state.
**When NOT to Use**: Static/aggregate info (use dedicated screens).

---

### P4 — Pick → Preview → Commit (Drag Placement)

**Category**: Input
**Used In**: Building System (owner); surfaced by Building UI; consumes Voxel World raycasts

**Description**: The core building interaction. Armed tool → ghost preview
follows the pick every frame → drag defines the shape (wall segment / floor
rect / roof footprint), re-rasterized every frame → release commits. Nothing
is ever created without a visible preview.

**Specification**:
- Drag starts at ≥ `drag_threshold_px`; working plane locks to the surface
  under the drag start.
- Preview re-rasterizes every frame; above `preview_degradation_threshold`
  cells it degrades to an outline (perf guard).
- Release commits; right-click/Esc cancels (Esc via P11); a drag begun in
  the world commits over HUD (P2 exception).
- One committed drag = one undo step (P8).
- Invalid commit → P6 cue, never a modal.

**When to Use**: Any spatial multi-cell placement.
**When NOT to Use**: Single-target actions (plain click) or menu choices.

---

### P5 — Ghost / Preview Overlay

**Category**: Overlay
**Used In**: Building System + Building UI; Voxel World supplies cell data

**Description**: Non-solid ghost cells rendered as the pending result of the
armed tool at the current pick. Hidden in Idle and while P2 suppresses the pick.

**Specification**: Ghost is never solid/collidable; visually distinct from
committed voxels; follows pick each frame; disappears on cancel/disarm.

**When to Use**: Previewing any world mutation before commit.
**When NOT to Use**: UI-space previews (use inline component states).

---

### P6 — Invalid-Action Cue (Non-Punishing)

**Category**: Feedback
**Used In**: Building UI (owner); required by Building System

**Description**: Transient at-cursor marker for an invalid commit: orange
accent + gentle negative sound, auto-fades (~1s, `invalid_cue_fade`),
optional one-line reason. Never modal, never blocks input, never punishes
experimentation.

**When to Use**: Rejected player actions where the fix is obvious or stated.
**When NOT to Use**: Persistent problems (P1 toasts), fatal errors (P12).

---

### P7 — Time Controls (Pause + Speed)

**Category**: Input / Data Display
**Used In**: Building UI (owner of controls, Rules 1/10); Time & Tick System (state owner); all simulation systems obey

**Description**: The one global HUD element (top-right): pause toggle (Space)
+ 1x/2x/3x speed radio. Displays the state returned by the Time & Tick API —
never a UI-local toggle.

**Specification**:
- Pause and speed are independent (speed editable while paused).
- Paused state visually unmistakable; always shows current state.
- UI itself runs on raw delta — fully responsive during pause (camera too).
- Forbidden: `SceneTree.paused`, `Engine.time_scale` (technical-preferences).

**When to Use**: This exact element; new speed tiers extend the radio.
**When NOT to Use**: Any other system pausing itself locally.

---

### P8 — Undo / Redo (Command-Level)

**Category**: Input
**Used In**: Building System (owner); Building UI (buttons)

**Description**: One player command (e.g. one wall drag) = one undo step.
Toolbar buttons mirror the stack and disable when empty.

**Specification**: Ctrl+Z / Ctrl+Y; held key repeats at OS rate, one step per
repeat, no acceleration; stack bounded (~50), cleared on scene-transition
COMPLETE only (never on begin/abort — undo-abort trap ruling), never persisted
to save files.

**When to Use**: All reversible world-mutating commands.
**When NOT to Use**: Irreversible side effects (those fire on COMPLETE only —
Core Rule 7).

---

### P9 — Modal Tool Palette / Mode Switching

**Category**: Navigation
**Used In**: Building UI (owner); Building System (tool state source)

**Description**: Bottom toolbar with five modal tool buttons (Wall, Floor,
Roof, Block, Furniture). Exactly one tool active; arming swaps the center
context panel; Idle hides it.

**Specification**:
- Keys 1–5 or click; last-input-wins; exactly one highlight; no stale panel.
- Arming a tool clears villager selection (P3) and closes its panel.
- Right-click/Esc → Idle (Esc via P11).
- Context panels: material palette (+ per-tool session memory), wall-height
  stepper (P15), roof-formation picker, furniture list.

**When to Use**: Mutually exclusive interaction modes.
**When NOT to Use**: Stackable/combinable options (use toggles).

---

### P10 — Data-Driven Tooltips & Labels

**Category**: Data Display
**Used In**: Building UI palette, Villager Info UI; source: Resource & Item Database

**Description**: All display text/icons come from database fields
(`display_name`, `visual_asset`) — never hardcoded in UI scenes.

**Specification**: `display_name` is localization-ready (MVP English);
palette icons derive from `visual_asset`; RID AC29: tier-0 materials
identifiable without opening a tooltip; tooltips are supplements, never the
only carrier of identity (A1).

**When to Use**: Any UI text describing a data-defined entity.
**When NOT to Use**: Screen chrome (section titles etc. — those are UI-owned,
still localization-ready).

---

### P11 — Two-Step Esc Routing

**Category**: Modal / Input
**Used In**: Building UI Rule 9b + Villager Info UI Rule 1 (reciprocal contract); Camera & Input dispatches

**Description**: Esc first releases HUD keyboard focus (focused toast,
expanded issues anchor); only an Esc with NO HUD focus falls through to the
world layer (cancel armed tool / deselect villager). Deterministic, no
double-fire.

**When to Use**: Every new focusable HUD element joins this routing.
**When NOT to Use**: Never bypass — a new "Esc closes X directly" behavior
must integrate with the chain, not race it.

---

### P12 — Loading Transition Overlay + Error Surface

**Category**: Overlay
**Used In**: Scene & World Management (owner)

**Description**: Full-screen non-interactive overlay during the Transitioning
state; on entry-load failure, an error surface (full-screen or toast) after
ALL reversible begin-effects unwind (camera un-Suspends, UI restores, overlay
fades — mirror-defect rulings).

**When to Use**: Scene transitions only.
**When NOT to Use**: In-scene waits (use inline loading states).

---

### P13 — Overhead World-Space Status Icon

**Category**: Overlay
**Used In**: Villager Info UI (owner); Villager AI (distress source)

**Description**: Subtle billboarded icon above a villager with an active
distress flag (trapped, ground-sleeping). Visible without selection;
disappears when the cause resolves.

**Specification**: One manager drives all N icons (a single Suspended signal
hides all); differentiated by shape+label, never hue (A1); deliberately NO
"no-bed" icon and no permanent mood icons (anti-noise ruling).

**When to Use**: Urgent, actionable, per-entity states the player must notice
unprompted.
**When NOT to Use**: Ambient mood display (panel-only) — overhead space is
reserved for distress.

---

### P14 — Suspended-Hide (Transition Arbitration)

**Category**: Input / Overlay
**Used In**: Camera & Input (owner of Suspended); Building UI, Villager Info UI, Scene & World Management

**Description**: On scene-transition begin, HUD + panels + overhead icons hide
and input dispatch halts; UI timers freeze. Restored on transition complete
or abort (camera returns to exact prior pose, ≤1e-4).

**Specification**: Suspended ≠ Pause — game pause does NOT suspend camera or
UI (both fully usable while paused, raw delta); Suspended is exclusively the
transition state. Toast grace/debounce timers freeze during Suspended only.

**When to Use**: Anything that must not react during a transition.
**When NOT to Use**: Ordinary pause behavior — pausing is P7's domain.

---

### P15 — Discrete Stepper Control

**Category**: Input
**Used In**: Building UI (wall-height stepper 1–8; range from Building System)

**Description**: +/− buttons, mousewheel-over-control, and keyboard actions
(`height_step_up/down`) step a clamped discrete value; current value always
displayed.

**When to Use**: Small bounded integer ranges (≤ ~10 steps).
**When NOT to Use**: Large/continuous ranges (needs slider + direct entry —
no such pattern committed yet, see Gaps).

---

### P16 — Keyboard Access Actions

**Category**: Input / Accessibility
**Used In**: Building UI Rule 9b (owner); all future HUD elements

**Description**: Every persistent HUD element gets named InputMap actions
(`toast_focus_cycle`, `toast_dismiss`, `toggle_issues`, `palette_next/prev`,
`formation_next/prev`, `height_step_up/down`). The ACTIONS are the
commitment; default keys are `[assumption]` until the screen-level UX pass.

**Specification**: Actions registered at project scope in `project.godot`
(camera-input.md Core Rule 11); Esc releases HUD focus (P11); avoid the
Tab/`ui_focus_next` collision (building-ui OQ7, Godot 4.6 dual-focus system).

**When to Use**: Mandatory for every new persistent HUD element (A2).
**When NOT to Use**: n/a — the stated MVP exemption (mouse-only villager
selection) is tracked in accessibility-requirements.md.

---

## Base Control Patterns

Compact entries for the primitive controls the composite patterns above are
built from. State vocabulary for ALL controls: `normal / hover / pressed /
focused / disabled` — focus visuals required per accessibility-requirements.md
A2; hover never carries information focus doesn't (keyboard parity).

### B1 — Button
**Used In**: tool palette (P9), undo/redo (P8), pause/speed (P7), toast dismiss (P1)
- States: all five; `disabled` shown greyed + non-interactive (undo/redo mirror
  stack emptiness). Icon buttons carry tooltips (P10) and a label or shape
  distinction (A1). Activation: click, or focus + `ui_accept`.

### B2 — Value Bar
**Used In**: villager need bars (P3; MVP: sleep 0–100)
- Read-only display; fill + numeric/label pairing (never fill-hue alone, A1);
  updates every frame from upstream state (raw delta, readable during pause);
  no animation easing on value changes in MVP (motion restraint, A5).

### B3 — List (Expandable)
**Used In**: issues-anchor expanded list (P1), furniture list (P9 context panel)
- Vertical list; keyboard: cycle via the owning element's actions (P16),
  focused row visibly outlined; rows are compact (icon + label + optional
  action); list is live (rows retire when their cause resolves, P1
  reconciliation); empty list ⇒ owning element hidden (anchor at zero issues).

### B4 — Icon Radio Group
**Used In**: speed control 1x/2x/3x (P7), roof-formation picker (P9)
- Exactly one active; active state shown by outline + label, not hue alone
  (A1); click or cycle actions (P16); state always mirrors the owning system's
  returned state, never a UI-local latch (P7 rule generalized).

---

## Animation Standards

| Context | Standard | Source |
|---|---|---|
| HUD panel show/hide | Instant swap — no slide/fade in MVP | building-ui.md Game Feel ("speed over ornament") |
| Toast appear/retire | Instant appear; retire may fade ≤ 0.2s `[assumption]` | P1; A5 motion restraint |
| Invalid-commit cue | Fade-out ~1s (`invalid_cue_fade`) | building-ui.md |
| Camera motion | Instant start/stop, no ease-in/out | camera-input.md |
| Transition overlay | Fade per scene-world-management spec; must fully unwind on abort | P12 |
| Screen shake / flash > 3 Hz / parallax | Forbidden in MVP | accessibility-requirements.md A5 |
| All UI animation clocks | Raw delta; Tweens pause ONLY on Suspended via `tween.pause()` | ADR-0011 |

## Sound Standards

| Context | Standard | Source |
|---|---|---|
| Invalid commit | Gentle negative cue, paired with visual marker | building-ui.md, P6 |
| Warning toast appears | Soft alert `[assumption — sound palette undefined]` | P1; A6 audio pairing |
| Commit success | In-world placement sound `[assumption]` | building-system.md feel |
| Room recognized | In-world celebration audio (NOT a toast) | building-ui.md Rule 9d |
| UI hover/click | No hover sounds in MVP `[assumption — anti-noise]` | A5/A6 spirit |
| Global rule | Every audio cue has a visible counterpart; game fully playable muted | accessibility-requirements.md A6 |

---

## Gaps & Patterns Needed

| Gap | Needed by | Notes |
|---|---|---|
| Main menu / settings navigation pattern | Alpha (Main Menu & Settings) | Includes rebinding UI, sensitivity, UI scale |
| Slider / continuous-value control | Alpha settings | P15 covers only small discrete ranges |
| Save/load slot picker | Save system UI (post-MVP surface) | ADR-0012 defines data layer only |
| Keyboard entity-selection path | Vertical Slice | Closes the P3/A2 exemption |
| Gamepad navigation layer | Post-MVP (partial support) | Menu/camera only per technical-preferences |
| Combat/squad command patterns | Combat GDDs (post-MVP) | Entirely unspecified |

## Open Questions

1. Default key bindings for all P16 actions — first screen-level UX pass
   (building-ui OQ1/OQ7).
2. Time HUD placement/size spec — needs `design/ux/hud.md` session
   (time-tick-system defers placement to /ux-design).
3. Does the issues-anchor expanded list need its own pattern entry once
   designed (list navigation, per-row focus)? Revisit at `/ux-design hud`.
