# HUD Design

> **Status**: Approved (/ux-review 2026-07-12 — verdict APPROVED after Visual-Budget + edge-margin revision)
> **Author**: user + ux-designer
> **Last Updated**: 2026-07-11
> **Template**: HUD Design
> **Scope**: MVP HUD (Building UI + Time HUD + Villager Info UI surfaces + transition overlays)
> **Binding inputs**: `design/ux/interaction-patterns.md` (P1-P16, B1-B4),
> `design/ux/accessibility-requirements.md` (A1-A7),
> `design/art/art-bible.md` §3.4 UI Shape Grammar + §4.5 UI Palette Divergence,
> GDD UI Requirements of all 11 MVP systems (behavioral source of truth)

---

## HUD Philosophy

> **Minimal but present** — the HUD permanently shows only what the player needs
> for the next decision, and grows contextually with the player's intent.

At rest (no tool armed, nothing selected, no active issues) exactly **two quiet
permanent elements** are visible: the **bottom toolbar** (the mouse entry point
into the game's core verb — permanent per the three-zone commitment) and the
**time-control element** top-right. The rest of the screen belongs to the
settlement. Everything else appears either because the player asked for it
(tool armed → toolbar context panel; villager clicked → info panel) or because
the simulation reports something that must be noticed unprompted (warning
toasts, issues anchor, overhead distress icons).

**Design test for every future HUD element** (Pillar 4): *Does the player need
this information for a decision in the next ~30 seconds — and can it NOT be told
by the world itself?* Only then may it live permanently on the HUD. In-world
communication (warm light as quality feedback, ghost previews, room celebration,
overhead distress icons) always outranks HUD chrome — the HUD is the last resort,
not the first.

Consequences:

- No permanent resource/statistics band (MVP has no scarcity; revisit with the
  economy systems).
- No minimap (camera + world are the map; revisit for 2000×2000 expeditions at
  Vertical Slice).
- No permanent room-status overlay (on-demand via the issues anchor;
  `room_recognized` has NO HUD surface per building-ui.md Rule 9d — celebration
  is in-world only).
- The HUD runs on raw delta and stays fully usable during pause (P7/P14); it
  disappears entirely only in the Suspended state (scene transitions).
- The three committed zones (bottom toolbar, top-right time controls,
  notification area below them — TR-building-ui-041) are an UPPER BOUND, not a
  build-out target.

---

## Information Architecture

### Full Information Inventory

Aggregated from the UI Requirements sections of all 11 MVP GDDs. Each item cites
its behavioral source of truth — this spec decides placement and presentation,
never behavior.

### Categorization

**Must Show (permanent):**

| # | Information | Source |
|---|---|---|
| 1 | Toolbar: 5 modal tool buttons (Wall, Floor, Roof, Block, Furniture — keys 1-5) + undo/redo button pair (non-modal, disabled when stack empty) | building-system TR-042/TR-101, P9/P8 |
| 2 | Time controls: pause toggle + 1x/2x/3x speed radio; current state always visible | time-tick TR-043, P7 |

**Contextual (auto-appears on simulation/interaction state):**

| # | Information | Trigger | Source |
|---|---|---|---|
| 3 | Armed tool's context panel (material palette / wall-height stepper / roof-formation picker / furniture list) | Tool armed; hidden in Idle | building-ui TR-045, P9/P15 |
| 4 | Warning/Info toasts carrying why-strings verbatim | Build Validation emissions (grace/debounce per P1) | P1, build-validation |
| 5 | Issues anchor "N !" counter | Visible iff >= 1 active issue; hidden at zero | building-ui TR-061 |
| 6 | Invalid-commit cue at cursor (orange accent + gentle sound, auto-fade) | Rejected commit | P6 |
| 7 | Pause indicator incl. world dim/desaturation treatment | Paused state | time-tick Visual/Audio Reqs |
| 8 | Transition overlay + load-error surface (full-screen) | Transitioning state / load failure | P12, scene-world TR-032/TR-057 |
| 9 | Overhead distress icons, world-space (trapped, ground-sleeping) | Active distress flag | P13, villager-info TR-034 |
| 10 | Villager hover affordance + selection outline (world-space) | Cursor over selectable villager / selection active | villager-info TR-046/TR-047 |
| 10b | Cursor states: grab/orbit icon during rotate-drag; ghost hidden + cursor state on pick-miss | Rotate-drag active / ray misses world | camera-input TR-045, building-system TR-086 |

**On Demand (player-requested):**

| # | Information | Source |
|---|---|---|
| 11 | Villager info panel: name, six-state activity label, sleep-need bar (raw 0-100), mood-band icon, why-string, distress flag | P3, villager-info TR-031 |
| 12 | Issues-anchor expanded list (live from queryable state) | building-ui TR-062, B3 |
| 13 | Tooltips (display_name from the item database) | P10 |

**Hidden (world/audio only — never HUD text):**

| # | Information | Source |
|---|---|---|
| 14 | Room recognition (in-world highlight + chime — explicitly NO toast/HUD surface) | building-ui Rule 9d |
| 15 | Build quality / warmth (interior light temperature) | Art bible Principle 1 |
| 16 | Construction progress (Planned ghost vs. visible per-cell progress, in-world) | building-system TR-069 |

**Conflict check** (philosophy vs. Must Show): 2 permanent elements +
contextual growth — "minimal but present" holds. No GDD requirement dropped.

---

## Layout Zones

**Chosen arrangement: "Quiet left edge"** (user decision 2026-07-11) —
messages right, inspection left, tools bottom. A warning toast never covers the
panel of the villager it is about; screen center and the upper-left corner
always stay clear for the world.

```
┌─────────────────────────────────────────────┐
│                                  [⏸ 1x 2x 3x]│  Z1 Time controls (top-right)
│                                  [⚠ Toast 1] │  Z2 Toast stack (below Z1)
│                                  [⚠ Toast 2] │
│                                  [ 3 ! ]     │  Z3 Issues anchor (below Z2)
│ ┌──────────┐                                 │
│ │ Villager │        (world)                  │  Z4 Villager info panel
│ │  Panel   │                                 │     (left edge, lower half,
│ └──────────┘                                 │      grows upward)
│         ┌─────────────────────┐              │
│         │ Context panel       │              │  Z5 Context panel (docked
│    ┌────┴─────────────────────┴────┐         │      above toolbar)
│    │ [1][2][3][4][5]  |  [↩][↪]    │         │  Z6 Toolbar (bottom-center)
└────┴──────────────────────────────┴──────────┘
```

| Zone | Anchor | Contents | Visibility |
|---|---|---|---|
| Z1 | Top-right | Time controls (P7): pause toggle + speed radio | Permanent |
| Z2 | Top-right, below Z1 | Toast stack (P1), max `toast_max_visible` (3) | Contextual |
| Z3 | Top-right, below Z2 | Issues anchor "N !" + expanded list (B3) | Contextual (>= 1 issue) |
| Z4 | Left edge, lower half | Villager info panel (P3) | On demand (selection) |
| Z5 | Bottom-center, docked above Z6 | Armed tool's context panel (P9) | Contextual (tool armed) |
| Z6 | Bottom-center | Toolbar: 5 tools + undo/redo (P9/P8) | Permanent |
| — | At cursor | Invalid-commit cue (P6), tooltips (P10) | Transient |
| — | Full-screen | Transition overlay / load-error surface (P12), pause dim | Contextual |
| — | World-space | Overhead distress icons (P13), hover/selection affordances, ghosts | Contextual |

Layout rules (from GDD commitments):

- Relative anchoring only — no fixed pixel positions; minimum supported layout
  holds at **1280x720** (TR-building-ui-071); design target 1080p/1440p
  comfortable unscaled (A4 — no UI-scale slider at MVP).
- Z4 is sized for the MVP's ONE need bar but must read as
  **minimal-by-design with room to grow** (reserved space, generous
  whitespace, grows upward as needs are added at VS/Alpha) — never as an
  incomplete stat sheet (villager-info-ui UX flag).
- Z2/Z3 growth is bounded: overflow goes into the anchor, never further down
  the screen edge (P1 cap + overflow-home rule).
- Z5 swaps content instantly on tool switch (last-input-wins, no stale panel —
  TR-building-ui-067); it never exceeds the toolbar's width envelope.
- Toolbar is the mouse entry point into the core verb and stays permanent; it
  is the widest element and defines the bottom safe margin for world picking.
- **Edge margin**: every HUD zone keeps a minimum inset of **16 px at 720p**
  (scales proportionally with resolution) from its screen edge — nothing sits
  flush against the border.

### Visual Budget

Hard ceilings for simultaneous on-screen HUD (checkable in QA):

- **Worst case = 8 elements**: toolbar + context panel + time controls +
  3 toasts + issues anchor + villager panel. Nothing else may appear
  concurrently at MVP; any new element must displace or fold into an existing
  zone (philosophy design test).
- **Screen coverage <= ~25%** of total area across all HUD zones combined at
  1280x720 (the tightest supported layout); the **center third of the screen
  is always HUD-free** — only transient at-cursor cues (invalid cue, tooltip)
  and world-space overlays may enter it.
- Toast stack is capped at `toast_max_visible` (3); overflow lives in the
  anchor (P1) — the budget cannot be exceeded by message volume.

---

## HUD Elements

Behavior for every element is owned by its pattern/GDD (cited) — this table
decides presentation. Visual form follows art-bible §3.4 (flat, sharp corners,
no skeuomorphism; varied icon SHAPES for states) and §4.5 (chrome `#262220`,
highlight Hearth Gold `#F5A83C`, text `#EDE6DA`, State Blue/Orange for status
only).

| El. | Element (zone) | Category | Form | Update behavior | Animation |
|---|---|---|---|---|---|
| E1 | Toolbar — 5 modal tool buttons, keys 1-5 (Z6) | Must Show | Flat sharp-cornered icon buttons (B1); armed tool = Hearth Gold highlight + pressed state, never hue alone (A1) | Event-driven from Building System tool state (P9) | Instant swap, no slides |
| E2 | Undo/redo pair (Z6) | Must Show | Icon buttons (B1); disabled greyed, mirrors stack (P8) | Event-driven | Instant |
| E3 | Time controls (Z1) | Must Show | Pause toggle + 1x/2x/3x icon radio (B4); displays the API's RETURNED state, never a UI-local latch (P7) | Event-driven (returned state) | Instant; paused state visually unmistakable |
| E4 | Context panel, 4 variants: material palette / height stepper (P15) / roof picker (B4) / furniture list (B3) (Z5) | Contextual | Flat panel `#262220`; icons derive from `visual_asset` (P10); per-tool session memory; an empty palette/list renders an explicit empty state, never a broken panel (TR-resource-item-database-044) | Event-driven on tool arm/switch | Instant swap (TR-building-ui-067) |
| E5 | Toast stack (Z2) | Contextual | Warning outranks Info, icon SHAPE + label per tier (A1); why-string verbatim, wraps never truncates | Per analysis pass (P1 reconcile; grace/debounce timers per ADR-0011) | Instant appear; retire fade <= 0.2s |
| E6 | Issues anchor "N !" (Z3) | Contextual | Counter chip; expandable live list (B3), rows retire with cause | Live from queryable state (TR-building-ui-062) | Instant |
| E7 | Villager info panel (Z4) | On Demand | Name, six-state activity label, sleep-need bar (B2, raw 0-100), mood-band icon (shape+label), why-string, distress flag; minimal-by-design with reserved growth space | Re-read every frame on raw delta — live during pause (P3) | Instant open/close |
| E8 | Invalid-commit cue (cursor) | Contextual | Orange accent marker + gentle negative sound, optional one-line reason; never modal (P6) | Transient on rejected commit | Fade ~1s (`invalid_cue_fade`) |
| E9 | Transition overlay + load-error surface (full-screen) | Contextual | Non-interactive overlay; error surface only after ALL begin-effects unwind (P12) | Suspended-bound | Fade per scene-world-management spec |
| E10 | Overhead distress icons (world-space) | Contextual | Billboarded, shape+label differentiated (A1); ONE manager drives all N (P13); trapped + ground-sleeping only | State-derived | Appear/vanish with cause |
| E11 | Pause treatment (full-screen + E3) | Contextual | World dim/desaturation + pause icon state in E3 | Pause state | Instant |

### Default Key Bindings (P16 actions)

Committed as `[assumption]` defaults 2026-07-11 (user decision) — final after
playtest; rebinding UI arrives at Alpha (A7 keeps them InputMap actions). Tab is
never used (Godot `ui_focus_next` collision, building-ui OQ7). QWERTZ-friendly,
clustered around WASD + Q/E camera keys:

| Action | Default key | Mnemonic |
|---|---|---|
| `tool_select_1..5` | 1-5 | committed (building-ui) |
| `time_pause` | Space | committed (building-ui) |
| `time_speed_up` / `down` | + / - | committed (building-ui) |
| undo / redo | Ctrl+Z / Ctrl+Y | committed (building-system) |
| HUD focus release / world fallthrough | Esc | committed (P11 two-step) |
| `height_step_up` / `height_step_down` | R / F | classic up/down pair next to WASD |
| `palette_next` / `palette_prev` | T / G | second vertical pair |
| `formation_next` / `formation_prev` | B / V | adjacent, rarely used |
| `toast_focus_cycle` | N | *N*otifications |
| `toast_dismiss` | X (while a toast is focused) | dismiss |
| `toggle_issues` | I | *I*ssues |

---

## Dynamic Behaviors

What changes HUD density mid-gameplay (all triggers are GDD-committed):

1. **Tool armed** → Z5 context panel appears (instant swap per variant);
   arming clears any villager selection and closes Z4 (TR-villager-info-ui-043);
   cursor block highlight + ghost preview activate in world space.
2. **Villager selected** → Z4 opens the same frame; live-mirrors upstream state
   every frame on raw delta. Deselect (empty click / Esc / tool arm /
   despawn) closes it — never a stale panel (TR-villager-info-ui-040).
3. **Issues appear** → Z2 grows up to `toast_max_visible`; overflow goes into
   the Z3 anchor (badge increments), never further down the edge. Zero issues →
   Z2 and Z3 fully hidden.
4. **Pause** → E11 world dim/desaturation + pause state in E3; the entire HUD
   stays fully usable (raw delta — building, selection, dismissal all work
   while paused).
5. **Suspended (scene transition)** → the ENTIRE HUD hides and input is
   ignored; toast grace/debounce timers freeze; everything restores on
   transition-complete OR -abort (P14). Suspended ≠ Pause.
6. **Esc chain** (P11): first Esc releases HUD keyboard focus (focused toast,
   expanded anchor); an Esc with no HUD focus falls through to the world layer
   (cancel armed tool / deselect villager). Deterministic, no double-fire.

---

## Platform & Input Variants

PC only, keyboard/mouse primary — **no platform variants at MVP**.

- Minimum supported layout: **1280x720** (TR-building-ui-071); design targets
  1080p and 1440p comfortable unscaled (A4 — UI-scale slider is an Alpha item).
- Relative anchoring only; wide/ultrawide simply gains world view (HUD zones
  stay edge-anchored, toolbar stays bottom-centered).
- **Partial gamepad** (menu/camera only) is post-MVP per technical-preferences —
  tracked as a pattern-library gap, no HUD provisions needed now beyond the
  InputMap-action discipline (A7) that makes later mapping possible.
- No touch support.

---

## Accessibility

Applies `design/ux/accessibility-requirements.md` A1-A7 to the HUD:

- **A1 color-independence**: every stateful element pairs icon shape + label
  with its color (armed tool = gold + pressed state; Warning vs Info = distinct
  shapes; mood bands = 3 distinct icon shapes). QA: grayscale screenshot pass
  over all E1-E11 states.
- **A2 keyboard access**: all P16 actions bound (defaults above); every
  interactive control reachable and operable without the mouse EXCEPT the
  tracked MVP exemption (mouse-only villager selection; commit gestures are
  mouse-bound by design). Focus indicators visible on all five control states
  (focus ring in Hearth Gold).
- **A3 contrast**: text `#EDE6DA` on chrome `#262220` ≈ 12:1 — passes 4.5:1
  with margin. OPEN: State Orange / State Blue on `#262220` must be verified
  >= 3:1 against the final theme (blocked by font/theme, see Open Questions).
- **A4 text size**: body >= 16 px at 1080p, why-string and activity labels
  >= 18 px; all text wraps, never truncates.
- **A5 motion restraint**: only three animated moments exist (toast retire
  fade <= 0.2s, invalid cue fade ~1s, transition overlay fade) — no shake, no
  flashing above 3 Hz, no parallax. Instant-swap everywhere else.
- **A6 audio pairing**: every HUD sound (invalid cue, toast alert) has its
  visible counterpart; the HUD is fully usable muted.
- **A7 input stability**: every binding above is a named InputMap action
  registered at project scope — no hardcoded scancodes.

---

## Open Questions

1. **Player journey map missing** — designed without journey context; template
   at `.claude/docs/templates/player-journey.md`. Create it before the VS UX
   revision.
2. **Final font family + rendered sizes** — blocks A3/A4 verification and the
   art bible's §7 UI/HUD Visual Direction (still `[To be designed]`); this spec
   provides §7's layout basis. Owner: art-director.
3. **Exact panel dimensions/paddings** — deferred to implementation against the
   real font; this spec fixes anchors, bounds, and growth rules only.
4. **Issues-anchor expanded list as its own pattern** — pattern library OQ3;
   decide when implementing (list navigation, per-row focus are specified via
   B3 + P16 for now).
5. **Z4 growth spec** (multiple need bars, VS+) — reserved-space rule is
   committed; the concrete multi-bar layout is the VS revision's job.
6. **Pause dim/desaturation values** — exact strength delegated to art bible §7
   (art-director); behavior (instant, full HUD usability) is fixed here.
7. **Default key bindings are `[assumption]`** — revisit after the first MVP
   playtest; rebinding UI lands at Alpha.
