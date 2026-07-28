# Building UI

> **Status**: Approved (2026-07-10 — MAJOR REVISION NEEDED → toast model rebuilt; re-review NEEDS REVISION (narrow) → grace-clock rewrite + patches; verification pass CLEAN) — **Slice revision 2026-07-23**: scope expanded from "pure toolbar HUD" to the full build-mode interaction layer (build mode entry, picking/hover contracts, ghost presentation, higher-level tools, slice view, projects panel) per the vertical slice's Stonehearth-style build workflow; USER-CONFIRMED 2026-07-22/23, slice-validated.
> **Author**: user + Claude Code Game Studios agents
> **Last Updated**: 2026-07-23
> **Last Verified**: 2026-07-23 (Slice revision — see `prototypes/last-seal-vertical-slice/REPORT.md`)
> **Implements Pillar**: Pillar 4 — Clarity over complexity (primary); Pillar 1 — The building IS the game (the toolset's face)

## Summary

Building UI is the MVP's entire heads-up display: the build toolbar
(six tools), the material and furniture palette (fed by the Resource &
Item Database), the wall-height stepper and roof-formation picker,
undo/redo controls, validity and validation feedback (invalid-commit
cues, Build Validation's warning/info toasts + the issues anchor — room
confirmations are celebrated in-world, not in the HUD), and — as the
MVP's one global HUD element — the time controls (pause + 1x/2x/3x,
resolving the Time & Tick GDD's open UI-trigger question). It renders
and triggers; it owns no state — every displayed value lives in the
system it mirrors (Building System, Build Validation, Time & Tick).

**(Slice revision 2026-07-23)** The vertical slice validated a much larger
build-interaction surface than the MVP toast/toolbar model above, and this
GDD's scope now covers it: **Build Mode** as the explicit entry point
(a master "Bauen" toggle gating every build tool), the **picking and
always-on hover contract** (ghost cells pick as solid, dig-orders and
water do not), **ghost/marker presentation** (material-tinted alpha
ghosts, inflated-box replace/dig markers), the **higher-level tools**
(Room, Auto-roof, House stamp) as HUD/interaction surfaces over Building
System's cell-generation, the **Slice View** (world horizontal cutoff for
interiors), and the **Projects Panel** (per-project cards driving the
Stonehearth-style draft → release → build → demolish workflow). The
slice's own verdict: this workflow "emerged as CORE UX during the slice
and must be first-class in the building GDDs, not an afterthought"
(REPORT.md). See Detailed Rules 13–23.

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: `Building System, Build Validation & Navigability, Resource & Item Database, Time & Tick System, Art Bible §7 (visual direction — Slice revision 2026-07-23)`

## Overview

**Player-facing:** this is the hand the player builds with. Per Pillar
4, it must stay *calm and legible*: a compact toolbar, a readable
palette, feedback that appears near the action (invalid cues at the
cursor, warnings as gentle toasts), and nothing permanently cluttering
the cozy valley view. Per Pillar 1, the toolbar IS the game's verb list
— if the UI feels bureaucratic, building feels bureaucratic.

**System-facing:** a pure presentation layer. It subscribes to state
(active tool, selected material, wall height, roof formation, undo/redo
availability, time state, validation events) and sends player intents
back as the same InputMap actions and calls the source systems already
define — it never interprets world clicks *for placement* itself
(Camera & Input → Building System own that pipeline) and never stores
gameplay state. **(Slice revision 2026-07-23)** It DOES own click-routing
**arbitration** and the resulting **Selection** state once a tool is not
consuming the pick: outside Build Mode, a world click resolves to either
a villager selection or a project selection (Rule 15) — this is a
routing/mirroring decision (which consumer's query wins), not placement
interpretation, and stays consistent with the existing shared-gate
pattern this GDD already owns for hover suppression (Rule 11). MVP scope
is exactly one screen context: the Valley build HUD, now spanning two
top-level interaction modes (World Navigation and Build Mode — Rule 13).
Menus, settings, and additional HUDs (combat, township) are separate
future systems.

## Player Fantasy

**"My workbench is always at hand — and it never gets in the way."**

1. **Everything within reach.** Tool, material, height, roof shape —
   one glance, one click, back to building. The UI feels like a
   craftsman's belt, not an office form.
2. **The world stays the star.** The HUD frames the valley instead of
   covering it; feedback happens where I'm looking (at the cursor, at
   the building), not in a corner I must check.
3. **It speaks softly.** Invalid actions get a gentle nudge, warnings
   arrive as calm notes I can dismiss — the UI is a helpful workshop
   assistant, never an alarm panel (Pillar 3's cozy tone).

Reference feeling: Stonehearth's build toolbar (compact, iconic) and
Timberborn's bottom bar (readable at a glance). NOT the fantasy: a
dense RTS command card, nested ribbon menus, or modal dialog churn.

> `creative-director` not consulted — Lean mode (non-high-risk
> sections). Review manually before production.

## Detailed Design

### Core Rules

**Layout (bottom bar + one global element)**

1. The HUD has exactly three zones in MVP:
   - **Bottom toolbar**: left — the five modal tool buttons (Wall, Floor,
     Roof, Block, Furniture); center — the context panel (swaps per armed
     tool); right — undo/redo buttons.
   - **Top-right: time controls** — pause toggle + 1x/2x/3x speed
     (radio-style, current state always visible). This resolves the Time
     & Tick GDD's open UI-trigger question.
   - **Top-right, below time controls: notification area** — Build
     Validation's warning/info toasts + the issues anchor (Rules 9–9c).
   Everything else is world view. No permanent panels beyond these
   (Pillar 4). [TR-building-ui-041]
2. The UI is a **pure mirror of simulation state**: every control
   reflects its source system's state (active tool, selected material,
   wall height, undo availability, time state) — no UI-owned
   *simulation-authoritative* state, ever. **UI-local presentation
   memory IS owned here by design and is exhaustively scoped**: the
   per-tool last-selected material (Rule 5), toast/anchor presentation
   state (shown/dismissed flags, grace/debounce timers, focus, toast
   display order/age, and the anchor's expanded/collapsed flag — Rules
   9–9c), and nothing else; none of it is serialized, none of it is
   consumed by any other system. [TR-building-ui-042] *(Revised 2026-07-10 — the original
   "no UI-owned state, ever" claim contradicted Rules 5 and 9.)*
   Mirroring uses each source's signals — except the **time controls,
   whose display is written EXCLUSIVELY from the pause/warp API's
   returned state** (Rule 10, Edge Case 12); Time & Tick state signals
   are consumed only for changes not initiated by this HUD, and a
   signal never overwrites a newer returned state (no stale-writer
   race — re-review fix, 2026-07-10). [TR-building-ui-043]
   The HUD runs on raw delta (fully responsive during pause, same
   pattern as Camera & Input). [TR-building-ui-005]

**Tools and context panel**

3. Tool buttons fire the tool-select InputMap actions (also bound to
   keys **1–5**); the armed tool is visibly highlighted; cancel
   (Esc/right-click, owned by the Building System) returns to Idle and
   clears the highlight. Exactly one tool ever appears active (mirrors
   Building AC 2). [TR-building-ui-044]
4. The **context panel** shows only what the armed tool needs: material
   palette (Wall/Floor/Roof/Block), wall-height stepper (Wall only),
   roof-formation picker (Roof only, 4 icons), furniture list (Furniture
   — MVP: `bed`). Hidden in Idle. [TR-building-ui-045]
5. The **material palette** is built from Resource & Item Database
   queries (`building_material`, tier-0 rule; `furniture_fixture` for
   the Furniture tool) — icon from `visual_asset`, tooltip from
   `display_name`. [TR-building-ui-008] The palette shows exactly what the database offers
   (Building AC 18); the last selection per tool is remembered within
   the session. [TR-building-ui-046]
6. The **wall-height stepper** shows 1–8 with +/− buttons (and
   mousewheel over the stepper, and the `height_step_up/down` actions —
   Rule 9b); it is the only player-facing tuning knob (Building Tuning
   Knobs). [TR-building-ui-047]
7. **Undo/redo buttons** mirror stack state (disabled when empty —
   mirroring Building's stack exactly); click = one step; **Ctrl+Z /
   Ctrl+Y** bindings; a held key repeats at the OS key-repeat rate, one
   step per repeat (Building UI Requirements). [TR-building-ui-048] *(Scoping note,
   2026-07-10: the repeat RATE is OS-configured — `InputEventKey.echo`
   — and deliberately neither asserted nor tested; AC 9 tests
   count-fidelity with synthetic events only. A repeat-velocity cap is
   an Open Question.)*

**Feedback**

8. **Invalid-commit cue**: a transient marker at the cursor (orange
   accent per the state axis + the gentle negative sound), auto-fading
   in ~1s, optionally carrying a one-line reason ("occupied", "too many
   cells"). Never modal, never blocking input. [TR-building-ui-049]
9. **Build Validation toasts — identity, severity, lifecycle**
   *(REBUILT 2026-07-10 — the original rule contradicted Build
   Validation's four-item seam contract and itself; this model
   implements all four seam items)*. The toast area shows **warnings
   and info hints only** (`sealed_space_warning`,
   `unsheltered_furniture_info`) — room confirmations are not toasts
   (Rule 9d). Each toast carries the why-string verbatim. [TR-building-ui-050]
   - **Identity/dedup**: every toast is keyed by (signal type, subject)
     — the region for sealed-space warnings, the item for info hints.
     A re-emission matching a live key **refreshes that toast in
     place**: no new entry, no re-queue, no visual change. Build
     Validation's level-triggered per-pass re-emits are idempotent for
     presentation. [TR-building-ui-051]
   - **First-appearance grace** (seam item 3): the grace timer is a
     **UI-local wall-clock timer per SUBJECT, started on the subject's
     first qualifying emission — NOT a count of re-emissions** (Build
     Validation is event-driven, its Rule 7: a persisting cause may
     emit exactly once; rewritten 2026-07-10 — the original re-emission
     wording was unsatisfiable). [TR-building-ui-052] When `warning_grace_delay` expires,
     the UI checks Build Validation's queryable state: cause still
     holds → the toast (or anchor entry) appears; cause resolved
     meanwhile → nothing ever surfaces (a transient seal fixed within
     the same build gesture never appears at all). [TR-building-ui-014] These timers (grace
     AND the debounce below) freeze only during Suspended (Edge Case
     6), never during ordinary game pause — the expiry check reads
     current queryable state, which stays correct while paused
     (removal/undo still fire analysis in pause). [TR-building-ui-053]
   - **Severity**: Warning outranks Info. A visible Warning is NEVER
     evicted by a lower-severity arrival; it leaves the screen only via
     player dismissal, tier-swap, cause resolution, or the overflow
     rule below. [TR-building-ui-054]
   - **Cap and overflow — the anchor is the overflow home; there is no
     hidden queue**: at most `toast_max_visible` toasts show. When
     full: a new Warning evicts the oldest visible Info (which
     collapses into the anchor); if every visible slot holds a Warning,
     the NEW warning goes directly to the anchor (badge increments — it
     is never invisible, so nothing starves). A new Info arriving when
     full goes directly to the anchor. [TR-building-ui-055]
   - **Dismissal + re-show debounce** (seam item 2): dismissing a toast
     hides it and starts `min_reshow_interval` for its key (same
     wall-clock timer class as grace); re-emissions inside the window
     do NOT re-show it (the issue stays in the anchor list — dismissal
     hides a toast, never the record). At window expiry the queryable
     state decides: cause still holds → the toast re-shows (no
     re-emission required); cause gone → the entry was already retired
     by reconciliation. [TR-building-ui-018]
   - **Promotion** *(2026-07-10 re-review ruling)*: when a visible slot
     frees (dismissal, retirement, or tier-swap), the longest-waiting
     anchor-only Warning is promoted into it as a toast — grace was
     already served, so it surfaces immediately; a previously-dismissed
     key still respects its remaining `min_reshow_interval` (the
     next-longest-waiting eligible key promotes instead). Info promotes
     only when no anchor-only Warning waits. The anchor is a true
     overflow buffer, never a graveyard. [TR-building-ui-056]
   - **Reconciliation — resolution and tier-swap** (seam item 4): the
     toast/anchor set reconciles against each analysis pass's emissions
     plus Build Validation's queryable state (its no-cleared-signal
     model, its Rule 10; all emissions of one pass arrive synchronously
     in one frame — same-frame delivery IS the reconciliation unit, per
     the reciprocal note in its Rule 10). A key whose emissions cease
     is **auto-retired** — toast and anchor entry removed within one
     reconcile; solved problems never require a manual dismiss. [TR-building-ui-057] A
     subject whose Warning ceases while an Info begins in the same pass
     swaps tiers: the Warning retires, the Info appears — never both
     for one subject. **Tier-swap bookkeeping is per SUBJECT across
     keys** *(added 2026-07-10 re-review)*: a swap of an already-Shown
     Warning shows the Info immediately (grace was served by the
     Warning); a swap during Grace transfers the elapsed grace credit
     to the Info key — no restart, so a flickering cause can never
     indefinitely suppress surfacing; an active dismissal-debounce
     window on the retiring Warning does NOT carry to the Info (a tier
     change is new information the player has not dismissed). [TR-building-ui-058]
9b. **Keyboard access** *(2026-07-10 decision — no persistent element
   is mouse-only; completed at the re-review, which found the stepper
   and roof picker still keyboard-less)*: `toast_focus_cycle` steps
   focus through visible toasts; `toast_dismiss` dismisses the focused
   toast with semantics identical to a click; `toggle_issues`
   opens/closes the anchor list (Rule 9c); `palette_next`/`palette_prev`
   cycle the armed tool's material/furniture palette selection;
   `formation_next`/`formation_prev` cycle the roof-formation picker
   (Roof armed); `height_step_up`/`height_step_down` drive the
   wall-height stepper (Wall armed — +/− keys are time-owned and
   unavailable). [TR-building-ui-059] Default bindings are `[assumption]` until the
   /ux-design pass — the ACTIONS are the commitment, not the keys
   (Q/E are camera-owned and avoided; Tab collides with Godot's
   built-in `ui_focus_next` and needs explicit resolution there).
   **Esc releases HUD keyboard focus WITHOUT dismissing** (distinct
   from `toast_dismiss`): a focused toast or expanded anchor loses
   focus on Esc, and only an Esc pressed with NO HUD focus falls
   through to world-level handlers — e.g., Villager Info UI's deselect
   (its Rule 1 Esc routing; reciprocal clause added 2026-07-11). [TR-building-ui-060]
9c. **The issues anchor** *(seam item 1 — the on-demand inspection
   surface)*: a compact counter at the top of the notification zone
   ("N ⚠"), visible iff at least one active warning/info exists
   anywhere (shown, dismissed-within-window, or overflowed); hidden
   entirely at zero issues (Pillar 4 calm — no dead chrome). [TR-building-ui-061] Activating
   it (click or `toggle_issues`) expands a compact list of ALL active
   issues with verbatim why-strings, built live from Build Validation's
   queryable state (its Rule 10 state+events contract) — never a
   UI-cached copy. The anchor stores nothing but its expanded/collapsed
   flag. [TR-building-ui-062]
9d. **Room confirmations have no HUD surface**: the room-recognized
   celebration is entirely in-world (Build Validation's Visual/Audio —
   highlight tracing the room + chime, honoring its
   one-celebration/anti-stacking rule). This HUD does not consume
   `room_recognized` and renders no confirmation toast *(2026-07-10
   decision — deletes the original auto-fading confirmation toast and
   the `toast_confirm_fade` knob)*. [TR-building-ui-063] **Accepted asymmetry** *(re-review
   acknowledgment)*: warnings are durable (the anchor); a missed
   in-world celebration is unrecoverable — deliberate,
   cozy-over-completionist; revisit only if the MVP playtest shows
   players missing their move-in moments.
10. **Time controls**: pause toggle bound to **Space**; speed cycling on
    **+/−** (or clicking 1x/2x/3x directly); the control always shows
    the current state (paused state visually unmistakable). Calls Time &
    Tick's pause/warp API; displays its state — never computes time
    itself. [TR-building-ui-064]

**Input boundaries**

11. The HUD never interprets world clicks: pointer events over HUD
    elements are UI-local; while the cursor hovers the HUD, the world
    pick is suppressed (the Building System's ghost hides — no
    accidental building behind the toolbar). Everything else flows
    through the established Camera & Input → Building System pipeline
    untouched. **Event-routing requirement** *(added 2026-07-10;
    generalized 2026-07-11)*: hover suppression gates pick *starts*
    via a queryable flag consumed by the world-pick pipeline — **the
    flag is the SHARED gate for EVERY world-pick consumer**: the
    Building System's ghost/placement pick AND Villager Info UI's
    villager-selection query (its Rule 1 HUD-hover gate) both honor
    it; the ghost hiding is one consequence, not the flag's scope. [TR-building-ui-028] The
    HUD must NOT consume the pointer-release event of an in-progress
    world drag (Edge Case 5 depends on the drag owner still observing
    the release; a naive whole-zone mouse-filter=STOP would swallow
    it) — **RESOLVED 2026-07-11 via ADR-0010**: Building System tracks
    an in-progress drag's release via `_input()` (fires before Control
    consumption) rather than `_unhandled_input()`, immune to HUD hover
    regardless of the HUD's own mouse_filter configuration. [TR-building-ui-029]
12. New InputMap actions introduced by this GDD (`tool_select_1..5`,
    `time_pause`, `time_speed_up/down`, and — added 2026-07-10 —
    `toast_focus_cycle`, `toast_dismiss`, `toggle_issues`,
    `palette_next`, `palette_prev`, `formation_next`, `formation_prev`,
    `height_step_up`, `height_step_down` per Rule 9b) are registered
    under Camera & Input's action ownership (its Core Rule 7 — it owns
    definitions, consumers own meaning). [TR-building-ui-065] **(Slice
    revision 2026-07-23)** extends this list with `build_mode_toggle`,
    `slice_up`, `slice_down`, `slice_reset`, and tool-select actions for
    the three higher-level tools (Room, Auto-roof, House stamp — Rule
    19); same ownership model as Rule 9b — `slice_up`/`slice_down`/
    `slice_reset` retain their slice-validated `PageUp`/`PageDown`/`Home`
    defaults pending a `/ux-design` collision check, while the
    higher-level-tool keys are `[assumption]` (Open Question 13).

**Build Mode, picking, ghosts, higher-level tools, slice view, projects
panel** *(Rules 13–23 added 2026-07-23 — vertical slice validation;
USER-CONFIRMED 2026-07-22/23. The vertical slice ran this workflow as a
single always-on build layer; the rules below formalize it as two
top-level interaction modes, World Navigation and Build Mode, per the
production requirement that clicks outside building intent must resolve
to villager/project selection instead.)*

13. **Build Mode is the explicit entry point** for every build tool: a
    master **"Bauen"** toggle (button in the toolbar zone + a bound key,
    `build_mode_toggle`) switches the HUD between **World Navigation**
    (default — camera/selection only, no build chrome) and **Build
    Mode** (toolbar tools + higher-level tools + the build grid become
    available). None of the six base tools, nor Room/Auto-roof/House
    stamp (Rule 19), can arm while in World Navigation. [TR-building-ui-075]
    **Arming auto-enters**: firing a tool-select action (button, key
    1–5, or a higher-level-tool key) while in World Navigation enters
    Build Mode AND arms that tool in the same frame — one player action,
    not two — so a player never has to consciously "turn on building"
    before using a tool; the toggle exists for the reverse action
    (leaving build context explicitly) and for players who prefer to
    browse the toolbar before choosing a tool. [TR-building-ui-075]
14. **The Esc chain** resolves exactly one step per press, highest
    priority first, and is never skipped or combined: (1) if a toast/
    anchor holds HUD keyboard focus, Esc releases that focus only (old
    Rule 9b, unchanged); else (2) if a tool is armed, Esc cancels it back
    to Build Mode with no tool armed (old Rule 3, unchanged); else (3) if
    a Selection is active (villager or project, Rule 15), Esc clears it;
    else (4) if Build Mode is on, Esc exits to World Navigation. A press
    with no applicable step (World Navigation, nothing selected) is a
    no-op. [TR-building-ui-076]
15. **Outside Build Mode, world clicks route to Selection.** In World
    Navigation, a world click resolves to exactly one outcome:
    - If the picked cell is occupied by a villager, the villager claims
      the selection (Villager Info UI's existing query, its Rule 1) —
      **villager wins ties**: a villager standing on/in a project cell
      takes selection precedence over the project underneath it, since a
      person is always the more specific target than the space they
      occupy.
    - Else, if the picked cell belongs to any Building System project
      (a Draft, Released, UnderConstruction, or Built cell that is part
      of a persistent project — pending that GDD's own project-lifecycle
      propagation, see Dependencies), that project becomes the Selection:
      its world-space outline renders around the project's full
      footprint and its Projects Panel card highlights in the same frame
      (Rule 21's reciprocal highlight).
    - Else (bare terrain, water, or empty space), the click clears any
      existing Selection.
    Selection is mutually exclusive (villager XOR project XOR none) —
    selecting one clears the other, mirroring the existing "exactly one
    tool active" invariant (old Rule 3/AC 21). [TR-building-ui-077]
16. **Picking treats blueprint/ghost cells as solid geometry, with two
    exemptions.** The shared pick ray (Building System's pick contract)
    resolves a Planned or Released ghost cell's face exactly as it would
    a real block's — this is what lets a roof tool target a drafted
    (not-yet-built) wall run. Two cell classes are exempt from
    pickable-solid:
    - **Dig-order cells** ("holes-to-be" — a queued excavation/removal
      marker) are never a solid pick target; the ray passes through to
      whatever lies behind or beneath them.
    - **Water** is never pickable-solid regardless of any marker/ghost
      state layered over it — a player cannot target a build action at
      a water surface as if it were solid ground.
    A ray that resolves nothing after these exemptions behaves exactly as
    the existing no-pick case (old Building System Edge Case 4: hidden
    ghost, no-op). [TR-building-ui-078]
17. **Always-on hover feedback.** Whenever the pick ray resolves to a
    valid target cell — in World Navigation OR Build Mode, tool armed or
    not — the target cell renders a wireframe outline plus a hit-face
    quad showing which face was hit, reusing the same pick-ray data any
    active tool preview or Selection query already consumes (one source
    of truth, several presentation consumers; extends the shared-gate
    principle of old Rule 11). In Build Mode specifically, an additional
    **build grid** — cell-edge lines on the picked working plane around
    the cursor — renders at `build_grid_opacity` (Tuning Knobs) in the
    Valley-Ochre-family per Art Bible §7.1; the grid never renders in
    World Navigation, where Pillar 4's calm valley view takes priority
    over a placement aid nobody is using yet. [TR-building-ui-079]
18. **Ghost and marker presentation.** Ghosts render as a translucent
    tint of the ACTUAL material selected for placement (not a generic
    "blueprint" hue) — a Draft (not-yet-Released) ghost renders at
    `ghost_alpha_draft`, a Released ghost (queued, no longer an editable
    draft) at the higher `ghost_alpha_released` (Tuning Knobs); the alpha
    step itself communicates commitment level, no new hue needed.
    **Invalid** placement, in any state, overrides the material tint with
    the State Orange tint (reuses old Rule 8's invalid-signal language —
    one invalid channel, not two). **Replace and dig/demolition markers**
    (terrain-replace, e.g. the floor tool flushing terrain; and
    dig/demolition orders) both render as an **inflated overlay box**
    around the affected cell — visibly larger than a flush ghost, the
    shared "this cell's content is changing to something not-yet-real"
    tell. Within that shared inflated-box language the two marker kinds
    still differ by **shape**, never shade or pulse alone (Art Bible
    §7.1's same-hue-differs-by-shape rule): both sit in the State-Orange
    family (the slice's red demolition tint does **not** survive — Art
    Bible §9 Prohibition 2), and their exact silhouette pairing is an
    Art Bible §7.3 shape-budget item (Open Question 12), not decided
    here. [TR-building-ui-080] [TR-building-ui-081]
19. **Higher-level tools** — HUD/interaction surface only; the
    mechanical cell-generation algorithms are Building System's domain
    and require that GDD's own propagation (Open Question 9). All three
    arm only in Build Mode (Rule 13) and follow the same pick → preview →
    commit pipeline as the base tools (Building System Core Rule 2):
    - **Room tool**: drags a ground-plane rectangle (minimum 3×3 cells);
      commit generates a full-height perimeter wall run at the current
      `wall_height` around the rectangle's edge, with one 1-cell door
      gap automatically omitted from whichever perimeter edge faces the
      camera **at commit time** (recomputed on commit, not drag start —
      the player may orbit mid-drag). The whole result is ONE draft
      project (Rule 21), not N separate wall commands.
    - **Auto-roof tool**: one click on any cell belonging to an existing
      project computes that project's footprint bounding box and
      generates a Flat-formation roof (Building System F5) at the bbox's
      top height, joining the SAME project — the slice-validated
      "cap the box" affordance that removes per-edge roof dragging for
      simple huts.
    - **House template stamp**: one click centers a fixed 7×7 footprint —
      flush floor + perimeter walls with one camera-facing door gap (Room
      rule) + a Flat roof at wall-height above — and creates ALL of it as
      ONE draft project in a single action. Precondition: the 7×7
      footprint must sit on uniform terrain height (no internal
      height-step) and have a clear volume up to roof height; an
      ineligible footprint shows the standard invalid-commit cue (old
      Rule 8) and commits nothing. [TR-building-ui-082] [TR-building-ui-083] [TR-building-ui-084]
20. **Slice View** — a player-controlled horizontal world cutoff: cells
    above the current level are hidden from render (world geometry,
    ghosts, and characters — simulation is unaffected, this is
    presentation-only). Controlled by `PageUp`/`PageDown` (step one
    cell) and `Home` (reset to show everything), plus a HUD **"Ebene"**
    indicator with +/− buttons mirroring the keys (same interaction
    pattern as the wall-height stepper, old Rule 6). Available in BOTH
    World Navigation and Build Mode — it is a camera/visibility aid, not
    a build-exclusive tool — and is the essential path to furnishing
    interiors once a roof is on. A cell hidden by the cutoff cannot
    become a NEW hover target (Rule 17) or Selection target (Rule 15)
    simply because it is not there to click; anything already selected
    or armed is unaffected by slicing (Edge Case 18). [TR-building-ui-085]
21. **Projects Panel** — a new screen-space chrome zone (joining the
    toolbar/time-controls/toast zones of old Rule 1), showing one card
    per Building System project: name, status text (e.g. "Geplant" /
    "Im Bau" / "Pausiert" / "Änderungen geplant" / "Wird abgerissen" /
    "Fertig" — exact string set pending Building System's own
    project-lifecycle propagation, Open Question 9), a progress readout
    `X/Y` cells built plus a bar (no easing — raw value every frame, Art
    Bible §7.4), the names of villagers currently working the project,
    and state-dependent action buttons (Bau starten / Verwerfen while
    Draft; Pause / Abbrechen while active; Fortsetzen while paused;
    Abriss once built). Clicking a card selects that project identically
    to clicking one of its world cells (Rule 15) — the world outline and
    the panel highlight are two renders of one Selection, never two
    independent states. **Provisional layout flag**: functionally
    slice-validated but with **no written UX spec** — production layout
    must not lock until `design/ux/projects-panel.md` exists (via
    `/ux-design`); the slice's card arrangement is provisional guidance
    only (Art Bible §7.5/§7.6 handoff). [TR-building-ui-086]
22. **Door-gap discoverability.** Confirmed playtest failure
    (`REPORT.md`, 2026-07-23): a wall gap functioning as a door was not
    discoverable without explanation. This GDD requires a dedicated
    visual affordance class marking "this gap is a functional doorway,"
    distinct from an unfinished or accidental gap — obeying the existing
    shape+label-never-hue convention (old Rule 9's icon rule, Art Bible
    §4.6/§7.1). Exact treatment is undesigned pending the Art Bible §7.6
    handoff; this rule commits only to the requirement existing. It is
    explicitly **superseded, not duplicated**, the moment door/window
    ITEMS ship (a building-system.md production requirement per
    `REPORT.md`) — a placed door object is its own affordance, and this
    rule retires at that point (Open Question 11). [TR-building-ui-087]
23. **Undo/redo scope: plan entries only.** Undo/redo (old Rule 7)
    reaches ONLY Draft commands not yet Released and Released-but-not-
    yet-Built blueprint cells, per Building System's per-command undo
    model (its Core Rule 17). Once a cell is Built, undo can never reach
    it again — reverting built work is exclusively a demolition order
    (the Projects Panel's Abriss button, Rule 21), a worker-executed job,
    never an instant undo. **Consequence this GDD owns** (the UX surface
    of a Building System rule): there is no "undo my demolished house"
    path — a queued or executed demolition is never an undo-tracked step,
    and the undo button/binding never lists one. Deliberate asymmetry,
    mirroring the already-accepted room-recognition-celebration asymmetry
    (old Rule 9d). [TR-building-ui-088]

### States and Transitions

| State | Entry | Exit | Behavior |
|-------|-------|------|----------|
| **WorldNav** *(Slice revision 2026-07-23)* | Boot, Build Mode toggled off, Esc chain's final step (Rule 14) | Build Mode entered (toggle, or auto-enter via tool-arm, Rule 13) | Only the "Bauen" toggle + time controls visible; no context panel, no build grid; world clicks route to Selection (Rule 15); always-on hover highlight still active (Rule 17) |
| Idle *(Build Mode, no tool)* | Build Mode entered with no tool armed; tool canceled (Rule 14 step 2) | Tool selected (arms); Esc exits to WorldNav (Rule 14 step 4) | Toolbar + tool buttons + higher-level tools + time controls visible; context panel hidden; build grid visible around cursor (Rule 17) |
| ToolArmed(tool) | Tool selected (button, key 1–5, or auto-enter from WorldNav) | Cancel / other tool / Suspended | Context panel for that tool; active button highlighted; ghost preview follows the pick (Rule 18) |
| Suspended | Camera & Input enters Suspended (scene transition) | Reactivation | Entire HUD hidden; all input ignored (mirrors Building's tool state machine) [TR-building-ui-066] |

**Selection lifecycle (orthogonal to the states above, added 2026-07-23):**
None ↔ VillagerSelected ↔ ProjectSelected — mutually exclusive (Rule 15).
Entered by a qualifying world click or a Projects Panel card click;
cleared by clicking empty terrain/water, selecting the other kind, or
the Esc chain's third step (Rule 14). Selection persists across a Build
Mode toggle (selecting a project, then entering Build Mode to edit it,
keeps it selected) and across Slice View changes (Edge Case 18) — it is
UI state, not render state.

**Esc priority chain (Rule 14):** each press resolves exactly the
highest-priority applicable step and never more than one: (1) HUD
keyboard focus release if a toast/anchor holds it (old Rule 9b — never
dismisses, never falls through) → (2) armed tool cancels to Idle → (3)
active Selection clears → (4) Build Mode exits to WorldNav. A press with
no applicable step is a no-op (Edge Case 19).

**Per-key toast lifecycle (Rule 9):** Grace(new key, hidden — wall-clock
timer) → Shown | AnchorOnly(overflow) → Dismissed(debounce window —
anchor entry stays) → re-Shown(window elapsed + cause persists in
queryable state) — plus **AnchorOnly → Shown via promotion** (a visible
slot frees, Rule 9) — with two universal exits from any state:
**Retired** (cause gone → auto-removed within one reconcile) and
**Tier-swapped** (Warning→Info for the same subject; per-subject grace
credit transfers, debounce does not). Same-key re-emissions never
create a second instance (Rule 9 identity).
**Anchor:** Hidden(0 issues) ↔ Badge(N) ↔ Expanded — pure derivation
from the live issue set plus one expanded/collapsed flag.

### Interactions with Other Systems

- **Building System** (upstream, MVP): displays its
  tool/material/height/formation/undo state; triggers it exclusively via
  the shared InputMap actions and its existing selection calls. Mirrors,
  never owns (its UI Requirements section is this GDD's contract).
  **(Slice revision 2026-07-23)** also the source of the pick-solid/
  dig-order/water exemption contract (Rule 16), the per-command undo
  scope this GDD surfaces as a UX consequence (Rule 23), and — pending
  that GDD's own propagation — the project/draft/release/demolition
  lifecycle the Projects Panel (Rule 21) and higher-level tools (Rule
  19) render; this GDD documents the UI-visible contract now, the
  mechanical ownership needs formal propagation there (Open Question 9).
- **Build Validation & Navigability** (upstream, MVP): consumes its
  warning/info events + why-strings (Rule 9) and its queryable state
  for the issues anchor (Rule 9c); implements all four items of its UI
  seam contract (its UI Requirements — resolved 2026-07-10 by this
  review). Does NOT consume `room_recognized` (Rule 9d — the
  celebration is in-world per its Visual/Audio anti-stacking rule).
  Owns only presentation state (Rule 2's scoped carve-out).
- **Resource & Item Database** (upstream, MVP): palette contents, icons,
  display names.
- **Time & Tick System** (upstream, MVP): pause/warp API calls + state
  display. Resolves its Core Rule 2 open trigger ("Building UI/HUD") —
  noted for a cross-reference patch.
- **Camera & Input** (upstream, MVP): action ownership for the new
  bindings (Rule 12); Suspended state propagation; HUD-hover pick
  suppression coordinates with its mouse-ray consumers.
- **Villager Info UI** (MVP sibling, undesigned): separate GDD —
  villager-related display lives there; this GDD is strictly the
  build-and-time HUD. **(Slice revision 2026-07-23)** the two GDDs now
  share the Selection outcome of Rule 15 (villager-wins-ties precedence)
  and the extended 4-step Esc chain (Rule 14, step 3) — a reciprocal
  update to that GDD's Rule 1 is flagged (Open Question 10), mirroring
  the existing reciprocal-clause pattern between these two documents.
- **Art Bible** (upstream, MVP — **new dependency, Slice revision
  2026-07-23**): §7.1 governs ghost/marker tint, alpha-as-commitment,
  build-grid color family, and the same-hue-differs-by-shape rule for
  replace/dig markers (Rule 18); §7.5 governs panel anatomy (Rule 21);
  §7.2/§7.4 govern the Projects Panel's typography and no-easing
  progress-bar convention. Supersedes the Visual Direction Note as this
  GDD's presentation authority per the Art Bible's own foundation note
  (its rules carry forward where not explicitly revised).
- **Scene/World Management** (upstream): hosting; Suspended during
  transitions.

## Formulas

*(`systems-designer` consulted — mandatory even in Lean mode. Verdict:
zero formulas.)*

**None.** This GDD renders and triggers but computes nothing — every
number the player sees (wall height, time speed, undo depth) is owned
and derived by an upstream system; the only UI-local numeric behaviors
(toast cap, fade durations, FIFO overflow) are authored constants and
ordering rules — recorded in Tuning Knobs and Edge Cases respectively,
not as formulas. **(Slice revision 2026-07-23)** the same verdict holds
for the new Rules 13–23: the Room tool's 3×3 minimum, the House stamp's
fixed 7×7 footprint, and the ghost alpha/grid-opacity values are
authored constants (Tuning Knobs), not derived math; the mechanical cell
counts the Room/Auto-roof/House-stamp tools generate reuse Building
System's existing F1/F2/F5 formulas over a computed footprint — no new
formula is introduced here.

## Edge Cases

1. **Toast overflow.** More than `toast_max_visible` simultaneous
   issues → the anchor absorbs the excess (Rule 9): a new Warning
   evicts the oldest visible Info into the anchor; when every visible
   slot holds a Warning, new arrivals go straight to the anchor (the
   badge counts them — nothing is ever invisible, nothing starves; the
   original hidden FIFO queue is deleted). [TR-building-ui-055]
2. **Rapid tool switching** (spamming keys 1–5). The context panel swaps
   cleanly with last-input-wins; no flicker of stale panels, no orphaned
   highlight (mirrors Building AC 2's exactly-one-active guarantee). [TR-building-ui-067]
3. **Palette integrity.** The palette can never show a broken entry: the
   item database fails at boot on missing `visual_asset` (its AC 22),
   and the reserved `missing_item` is never palette-eligible (not
   tier-0, reserved id). No UI fallback path needed — by upstream design.
4. **Undo clicked as the stack empties concurrently.** The button
   mirrors state via signals; a click racing a just-disabled state is a
   silent no-op — the UI never issues an action the source system would
   reject noisily. [TR-building-ui-068]
5. **Drag released over the HUD.** *(mechanism RESOLVED 2026-07-11 via
   ADR-0010)* Hover suppression (Rule 11) applies to *starting* picks,
   not active drags: a drag begun in the world commits on release even
   over the HUD, using the last valid world preview (the preview locks
   when the cursor enters HUD space). No accidental aborts from brushing
   the toolbar. Mechanism: once dragging, Building System listens for the
   release via Godot's `_input()` (fires before any Control's `_gui_input`
   consumption, regardless of cursor position) instead of
   `_unhandled_input()`, and claims the event via
   `set_input_as_handled()` — so the release is never swallowed by the
   HUD's own click-consumption, and the commit uses the locked preview
   position rather than re-deriving one from the (HUD-positioned) release
   point. [TR-building-ui-069]
6. **Suspended with live toasts.** The toast/anchor set survives
   Suspended: hidden with the HUD, restored on reactivation; all UI
   timers (grace, debounce windows, the invalid-cue fade) pause while
   Suspended and resume with REMAINING time — never restart. [TR-building-ui-015]
   *Implementation note: hiding a Control does not pause Godot
   Tweens/Timers — the pause is an explicit call tied to the Suspended
   transition, not a visibility side effect; the SAME Suspended-entry
   signal from Camera & Input drives both the HUD-hide and the
   timer-pause, one trigger, no drift.* Ordinary game PAUSE never
   freezes these timers (Rule 9's wall-clock semantics — analysis can
   still run while paused, since removal/undo fire signals in pause). [TR-building-ui-053]
   (Issue records would re-derive anyway — Build Validation re-emits.)
7. **Speed changed while paused.** Pressing +/− while paused updates the
   *stored* speed without unpausing (mirrors Time & Tick's independent
   pause/speed state); the control displays both facts (paused + pending
   speed). [TR-building-ui-070]
8. **Window resize / aspect ratio.** The bottom bar anchors to the
   bottom edge (centered, max-width), time controls and toasts to the
   top-right corner — no fixed pixel positions; minimum supported layout
   must hold at 1280×720. [TR-building-ui-071]
9. **Toast dismissal click.** The click is consumed by the toast — it
   never falls through to the world or the toolbar beneath. [TR-building-ui-072]
10. **No text input exists in MVP** — keys 1–5/Space/+/− are always
    live. When any text field arrives (VS+: save names, villager
    renaming), shortcut suppression while typing becomes a requirement —
    flagged in Open Questions so it isn't forgotten.
11. **Warning resolves while its toast is shown.** The cause is fixed
    (emissions cease) → the toast and its anchor entry auto-retire
    within one reconcile pass — the player never has to dismiss a
    solved problem (Rule 9 reconciliation). [TR-building-ui-057]
12. **Rapid pause double-tap.** Two Space presses faster than one
    mirrored update: each press is a synchronous API call whose
    returned state updates the display (Rules 2/10) — the control shows
    Time & Tick's authoritative state after the second call; no
    UI-local toggle exists to diverge, and per Rule 2 a queued state
    SIGNAL from press 1 can never overwrite press 2's newer returned
    state (returned-state-only writer for time controls). [TR-building-ui-043]
13. **Focused toast retires mid-interaction.** When the toast holding
    keyboard focus auto-retires, is promoted away, or tier-swaps, focus
    moves to the next visible toast (or the anchor if none remains) —
    never a dangling null focus. [TR-building-ui-073] *(Godot does not auto-transfer focus
    from a freed Control; the handoff is explicit. This is the first
    feature requiring focus to survive dynamic Control add/remove —
    OQ7's 4.6 dual-focus verification is BLOCKING for Rule 9b's
    implementation specifically.)*
14. **Selection precedence tie** *(added 2026-07-23)*: a villager
    standing on/in a cell that also belongs to a project. The villager
    claims the selection; the project underneath is not selected (Rule
    15) — the player can still select that project by clicking a
    different one of its cells. [TR-building-ui-077]
15. **Dig-order pick-through with nothing behind it** *(added
    2026-07-23)*: the ray passes through the dig-order marker (Rule 16)
    and, finding no further geometry, resolves as a miss — identical to
    the existing no-pick case (hidden ghost, no-op commit). [TR-building-ui-078]
16. **Auto-roof clicked on a cell belonging to no project** *(added
    2026-07-23)*: bare terrain or an unowned lone block gives the tool no
    bounding box to compute. The invalid-commit cue appears (old Rule 8)
    and nothing is created. [TR-building-ui-083]
17. **House stamp on an ineligible footprint** *(added 2026-07-23)*: any
    height-stepped cell within the 7×7 area, or any obstruction up to
    roof height, fails the precondition (Rule 19). The invalid-commit cue
    appears and no project is created — never a partial stamp. [TR-building-ui-084]
18. **Selection persists under a Slice-View cutoff** *(added 2026-07-23)*:
    if the current Selection (villager or project) is hidden by the
    slice level, the Selection state itself is untouched — it is UI
    state, not render state (States and Transitions). The world-space
    outline simply does not render while hidden; the Projects Panel
    highlight (or Villager Info UI's panel) still shows normally. [TR-building-ui-085]
19. **Rapid Esc presses through the full chain** *(added 2026-07-23)*: a
    tool armed, a Selection active, and Build Mode on, all at once — each
    Esc press consumes exactly one chain step in priority order (Rule
    14); three presses are required to reach WorldNav, never fewer, and
    no press ever resolves two steps at once. [TR-building-ui-076]
20. **Room tool dragged below the 3×3 minimum** *(added 2026-07-23)*: the
    invalid-commit cue appears (old Rule 8) and no project is created —
    mirrors the existing clamped-drag feedback language elsewhere in this
    GDD (e.g. Edge Case 1). [TR-building-ui-082]

## Dependencies

### Upstream (systems this one depends on)

| System | GDD Status | What this system consumes |
|--------|-----------|---------------------------|
| Building System | ✅ Approved (project/draft/release/demolition lifecycle, room/auto-roof/house-stamp cell generation, and the pick-solid/dig-order/water contract are slice-validated but **not yet propagated into that GDD's text** — Slice revision 2026-07-23; Open Question 9) | Tool/material/height/formation/undo state + the UI Requirements contract; triggered via shared InputMap actions; **(Slice revision)** project lifecycle state for the Projects Panel (Rule 21), higher-level tool cell generation (Rule 19), and the pick-solid/dig-order/water exemption (Rule 16) |
| Build Validation & Navigability | ✅ Approved | Warning/info events + why-strings + queryable state (its Rule 10); the four-item UI seam contract (its UI Requirements) — implemented by Rules 9–9c |
| Resource & Item Database | ✅ Approved | Palette contents, `visual_asset` icons, `display_name` tooltips, tier-0 rule |
| Time & Tick System | ✅ Approved | Pause/warp API + state display (resolves its Core Rule 2 UI-trigger question) |
| Camera & Input | ✅ Approved | InputMap action ownership for new bindings (Rule 12); Suspended state; raw-delta pattern |
| Scene/World Management | ✅ Approved | Hosting; Suspended during transitions |
| Art Bible | ✅ COMPLETE (§7 — **new dependency, Slice revision 2026-07-23**) | Ghost/marker tint + alpha-as-commitment rules, build-grid color family, same-hue-differs-by-shape rule for replace/dig markers (§7.1); panel anatomy (§7.5); typography/no-easing progress convention (§7.2/§7.4) |

### Downstream (systems that depend on this one)

| System | Tier | GDD Status | What it consumes |
|--------|------|-----------|------------------|
| Villager Info UI | MVP | ✅ Designed (reciprocal update pending — Open Question 10) | The click-ownership rule (armed tool ⇒ Building pipeline; Idle ⇒ villager selection may claim hits — its Rule 1) (added 2026-07-10, cross-review bidirectional fix); **(Slice revision 2026-07-23)** the extended Selection routing (villager-wins-ties, Rule 15) and the 4-step Esc chain (Rule 14) |
| Onboarding / Tutorial | Vertical Slice | Undesigned | The toolbar as the teachable surface *(provisional)*; **(Slice revision)** the Build Mode entry point and door-gap discoverability gap (Rule 22) are confirmed onboarding-relevant findings |
| Projects Panel UX Spec | Pre-Production | Undesigned — **new downstream, Slice revision 2026-07-23** | This GDD's provisional card content/behavior (Rule 21) as its starting contract; `/ux-design` must formalize layout before production lock (Art Bible §7.5/§7.6 handoff) |

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|-----------|---------|
| `toast_max_visible` | 3 | 2–5 | Simultaneous toasts — more = noisier (Pillar 4). **Minimum 2**: keeps one slot rotating for Info in the common case; when every slot holds a Warning, Info is anchor-only until promotion frees a slot (Rule 9 — the rotating-Info slot is best-effort, not guaranteed; rationale corrected at the re-review) |
| `min_reshow_interval` | 30s | 10–120s | Dismissal debounce (Rule 9, seam item 2): how long a dismissed toast stays hidden through re-emissions. `[assumption]` until playtest |
| `warning_grace_delay` | 3s | 1–8s | First-appearance grace (Rule 9, seam item 3): how long a new issue must persist before surfacing at all. `[assumption]` until playtest |
| `invalid_cue_fade` | 1s | 0.5–2s | Duration of the at-cursor invalid marker |
| `ghost_alpha_draft` *(Slice revision 2026-07-23)* | 0.50 | 0.30–0.70 | Draft-ghost translucency (Rule 18) — slice-validated value |
| `ghost_alpha_released` *(Slice revision 2026-07-23)* | 0.70 | `ghost_alpha_draft`–0.90 (floor is the current draft value, not a fixed number) | Released-ghost translucency (Rule 18) — the floor tracks `ghost_alpha_draft` so retuning one can never collapse the draft→released ordering invariant that carries the "increased commitment" read (cross-parameter coherence check) |
| `build_grid_opacity` *(Slice revision 2026-07-23)* | 0.30 | 0.15–0.45 | Build-mode cursor grid opacity (Rule 17) — user-tuned in the slice; too high competes with the calm valley view (Pillar 4), too low fails as a placement aid |
| Slice View keys *(Slice revision 2026-07-23)* | `PageUp`/`PageDown` (step one level) / `Home` (reset to show-all) | — | Slice-validated as a working scheme in the prototype (REPORT.md — no confusion reported); retained as the default pending a `/ux-design` collision check against every other binding (same status class as Rule 9b's bindings, Open Question 13) — the ACTIONS (`slice_up`/`slice_down`/`slice_reset`) are the commitment, not the keys |

*(`toast_confirm_fade` deleted 2026-07-10 — room confirmations are no
longer toasts, Rule 9d.)*

Layout anchors/sizes carry no gameplay effect — they belong to the UX
spec / art bible, not this GDD. All values data-driven per the coding
standard. [TR-building-ui-037]

## Visual/Audio Requirements

Iconography follows the Visual Direction Note: palette icons derive from
`visual_asset` (material↔meaning color families); the blue–orange state
axis governs UI states (armed tool blue-accented, warnings orange —
never red-green). **Warning and Info toasts are differentiated by icon
SHAPE + label, never by hue or intensity alone** (the Note's §4 day-one
pairing rule — the two silhouettes are the same warning/info icon
assets Build Validation's Visual/Audio already mandates); the armed
tool pairs its blue accent with a pressed/highlight state, not hue
alone. [TR-building-ui-074] The paused state must be visually unmistakable (e.g. icon +
subtle vignette — treatment to the art bible). Audio: subtle UI clicks
only; commit/invalid sounds are owned by the Building System, the
room-recognized chime by Build Validation (no duplication — Rule 9d).
**New assets required**: 5 tool icons, 4 roof-formation icons,
time-control icons, toast frames (2 severity tiers — warning / info),
issues-anchor icon + badge.

**(Slice revision 2026-07-23)** Art Bible §7 now governs this section's
world-space additions (superseding the Visual Direction Note where
revised, per its own foundation note): the material-tinted ghost shader
(alpha per Tuning Knobs), the always-on hover wireframe + hit-face quad,
the build grid (Valley-Ochre family, §7.1), the inflated-box replace/dig
markers (shared shape language, distinct silhouettes per marker kind —
§7.1/§7.3), 3 higher-level tool icons (Room, Auto-roof, House stamp), the
Projects Panel's card frame + status icon set (Draft/Released/Paused/
Built/DemolitionQueued — §7.3's shape-budget table), the "Ebene" slice
indicator icon, and the (undesigned pending §7.6 handoff) door-gap
affordance icon.

## Game Feel

Every UI reaction lands the same frame as its input (raw-delta path) [TR-building-ui-005];
context-panel swaps are snappy (no slide animations in MVP — speed over
ornament); the HUD never disappears unexpectedly. **Feel acceptance
criteria** (playtest): a first-time player finds tool + material
unaided in under a minute (covers the concept's onboarding beat);
nobody calls the HUD "in the way." **(Slice revision 2026-07-23)**
Confirmed by the vertical slice (REPORT.md): the tester discovered the
Build Mode toolbar and the draft → release → build project workflow
unaided ("mehr als genug für einen Prototypen") and reacted with
unprompted enthusiasm to the persistent-projects build ("Ich bin sehr
begeistert"). **One confirmed failure to carry forward**: the door-gap
affordance (Rule 22) was NOT discoverable without explanation — now a
tracked requirement, not an assumption of "it'll be obvious."

## UI Requirements

This GDD *is* the UI — this section points forward instead:

> 📌 **UX Flag — Building UI**: In Phase 4 (Pre-Production), run
> `/ux-design` to create the build-HUD UX spec before writing epics.
> Stories should cite `design/ux/build-hud.md`, not this GDD directly.

## Cross-References

| Reference | Document | What | Nature |
|-----------|----------|------|--------|
| UI Requirements contract (toolbar, stepper, undo, feedback) | `design/gdd/building-system.md` | UI Requirements | This GDD's order sheet |
| Warning/info events, why-strings, queryable state, no-cleared-signal model, four-item seam contract | `design/gdd/build-validation-navigability.md` | Rules 8/10/11, AC 22, UI Requirements | Event contract — seam items 1–4 implemented here (Rules 9–9c); `room_recognized` deliberately NOT consumed (Rule 9d) |
| Pause/warp trigger ("Building UI/HUD") | `design/gdd/time-tick-system.md` | Core Rule 2 | **Resolved by this GDD** (Rules 1/10 — patch note there) |
| Action ownership, Suspended, raw-delta pattern | `design/gdd/camera-input.md` | Core Rules 7–10 (Rules 9–10 authored 2026-07-10) | New actions under its ownership (Rule 12) |
| Palette data (`display_name`, `visual_asset`, tier-0) | `design/gdd/resource-item-database.md` | Core Rules 4–8 | Data contract |
| Blue–orange axis, material colors | `design/art/visual-direction-note.md` | State axis | Visual constraint (superseded where revised by Art Bible §7 — Slice revision 2026-07-23) |
| Ghost/marker tint + alpha, build grid, same-hue-differs-by-shape, panel anatomy, typography/no-easing bars | `design/art/art-bible.md` | §7.1, §7.2, §7.3, §7.4, §7.5, §7.6 | **New (Slice revision 2026-07-23)** — this GDD's presentation authority for Rules 16–21 |
| Vertical slice validation, playtest findings, propagation list | `prototypes/last-seal-vertical-slice/REPORT.md` | Playtest Results, Observations, "If Proceeding" | **New (Slice revision 2026-07-23)** — source of Rules 13–23 and Open Questions 9–13 |

## Acceptance Criteria

*(`qa-lead` consulted — mandatory for this high-risk section even in Lean
mode. Review produced 5 rewrites and 6 missing criteria; all
incorporated. The 2026-07-10 full design review rebuilt the toast model:
AC11/12 rewritten (the originals validated the seam-contract violation)
and AC27–36 added. The same-day re-review rewrote AC27 (wall-clock grace
— the re-emission wording was unsatisfiable), extended AC31/36, and
added AC37–41. Split per the project's test-evidence table: headless
unit-testable mirror/event logic is BLOCKING; rendering/viewport/layout
checks are ADVISORY (interaction test or walkthrough doc).)* [TR-building-ui-038]

**Blocking — headless unit tests (state-mirror & event logic)**
1. **GIVEN** any tool selected in the Building System (mocked signal), **WHEN** it arrives, **THEN** the matching button highlights and all others un-highlight, same frame. [TR-building-ui-044]
2. **GIVEN** key 1–5 pressed, **WHEN** the action fires, **THEN** the corresponding tool-select action is emitted — the UI sends intents, never sets Building state directly. [TR-building-ui-044]
3. **GIVEN** a tool armed, **WHEN** cancel fires, **THEN** the UI returns to Idle, the context panel hides, and the previously-armed button un-highlights. [TR-building-ui-044]
4. **GIVEN** Wall armed → palette + stepper; Roof armed → palette + 4 formation icons; Furniture armed → furniture list (`bed` only); Idle → no panel (Rule 4). [TR-building-ui-045]
5. **GIVEN** the mocked MVP dataset, **WHEN** the palette renders, **THEN** exactly the tier-0 materials appear for placement tools and exactly `bed` for Furniture. [TR-building-ui-008]
6. **GIVEN** a material selected for tool A, **WHEN** switching to B and back, **THEN** A's last selection is restored (session-scoped). [TR-building-ui-046]
7. **GIVEN** the stepper at 8, **WHEN** + fires, **THEN** it stays 8; same at 1 with − (clamped display of Building's range). [TR-building-ui-047]
8. **GIVEN** an empty undo stack (mocked), **THEN** undo is disabled; **GIVEN** a redo branch, **THEN** redo enables — mirroring only. [TR-building-ui-048]
9. **GIVEN** N synthetic undo action-pressed events in sequence, **THEN** exactly N undo intents are emitted — none added or dropped (no debounce, no acceleration). [TR-building-ui-048]
10. **GIVEN** an invalid-commit event, **THEN** the at-cursor cue appears and auto-fades within `invalid_cue_fade` ±10 %, blocking no input. [TR-building-ui-049]
11. **GIVEN** a dismissed warning toast, **WHEN** its key re-emits within `min_reshow_interval`, **THEN** the toast stays hidden while its anchor entry persists; **WHEN** a qualifying re-emission arrives after the window and the cause still holds, **THEN** the toast re-shows (Rule 9 debounce — *rewritten 2026-07-10: the original AC validated the seam-contract violation*). [TR-building-ui-018]
12. **GIVEN** `toast_max_visible` visible toasts including at least one Info, **WHEN** a new Warning arrives, **THEN** the oldest visible Info collapses into the anchor and the Warning shows; **GIVEN** every visible slot holding a Warning, **WHEN** a new Warning arrives, **THEN** no visible toast is evicted and the new Warning appears in the anchor with the badge incremented (Rule 9 overflow — warnings never evicted by severity, nothing starves). [TR-building-ui-055]
13. **GIVEN** Space pressed, **THEN** Time & Tick's pause toggle is called and the control reflects the *returned* state — never a UI-local pause. [TR-building-ui-064]
14. **GIVEN** paused at stored 2x, **WHEN** + fires, **THEN** the stored speed changes without unpausing; the control shows both facts (Edge Case 7). [TR-building-ui-070]
15. **GIVEN** the cursor over any HUD element, **THEN** hover-suppression reports active and the Building ghost hides (Rule 11). [TR-building-ui-028]
16. **GIVEN** Suspended entered, **THEN** the HUD hides, ignores input, and toast timers freeze — restoring on reactivation (Edge Case 6). [TR-building-ui-066]
17. **GIVEN** rapid interleaved tool-select events (spam 1–5), **THEN** last-input-wins with exactly one highlight and no stale panel at every step (Edge Case 2). [TR-building-ui-067]
18. **GIVEN** an undo click racing a same-frame disable signal, **THEN** silent no-op — no action emitted, no error (Edge Case 4). [TR-building-ui-068]
19. **GIVEN** mousewheel over the stepper, **THEN** it steps identically to the +/− buttons within 1–8 (Rule 6). [TR-building-ui-047]
20. **GIVEN** an info-tier hint (unsheltered bed), **THEN** it renders as dismissible low-key — distinct from warning styling — and its why-string passes through verbatim (Rule 9). [TR-building-ui-050]
21. **GIVEN** arbitrary interleaved mocked state sequences, **THEN** at no point do two tools appear active simultaneously (invariant over AC 1). [TR-building-ui-044]
22. **GIVEN** the InputMap at boot, **THEN** `tool_select_1..5`, `time_pause`, `time_speed_up/down` exist as registered actions (smoke check, Rule 12). [TR-building-ui-065]

**Added by design review (2026-07-10) — blocking headless (toast model rebuild + keyboard parity)**
27. **GIVEN** exactly ONE qualifying emission for a new subject (no further emissions — Build Validation is event-driven), **WHEN** `warning_grace_delay` elapses and the mocked queryable state still holds the cause, **THEN** the toast appears (wall-clock grace + state check, no re-emission required); **GIVEN** the queryable state shows the cause resolved before expiry, **THEN** no toast and no anchor entry ever appeared (Rule 9 grace — rewritten at the re-review: the original re-emission-count wording was unsatisfiable). [TR-building-ui-052] [TR-building-ui-014]
28. **GIVEN** a shown toast, **WHEN** its key re-emits on N successive passes, **THEN** exactly one toast instance exists throughout — no duplicate entries, no Shown→Queued cycling (Rule 9 identity/dedup). [TR-building-ui-051]
29. **GIVEN** a shown warning whose emissions cease (cause fixed), **WHEN** the next reconcile runs, **THEN** the toast and its anchor entry are removed with no player dismissal (Edge Case 11). [TR-building-ui-057]
30. **GIVEN** a subject whose Warning ceases while an Info begins in the same pass, **THEN** the Warning toast retires and the Info toast appears — at no point are both visible for that subject (Rule 9 tier-swap). [TR-building-ui-058]
31. **GIVEN** any set of active issues (shown, dismissed-in-window, and overflowed), **THEN** the anchor badge equals the live issue count and the expanded list matches Build Validation's queryable state exactly — mutating upstream state directly (bypassing signals) never leaves a stale list entry (Rule 9c — no cached copy; the queryable-state schema itself is `[assumption]` until the technical spec pass). [TR-building-ui-062]
32. **GIVEN** zero active issues, **THEN** the anchor is fully hidden — no badge, no dead chrome (Rule 9c). [TR-building-ui-061]
33. **GIVEN** visible toasts, **WHEN** `toast_focus_cycle` then `toast_dismiss` fire, **THEN** the focused toast is dismissed with semantics identical to a click dismissal, including the debounce window (Rule 9b keyboard parity). [TR-building-ui-059]
34. **GIVEN** a placement tool armed, **WHEN** `palette_next`/`palette_prev` fire, **THEN** the selection cycles through exactly the palette's entries, identically to clicking them (Rule 9b). [TR-building-ui-059]
35. **GIVEN** a `room_recognized` event (mocked), **THEN** zero toast entries and zero anchor entries are created — confirmations have no HUD surface (Rule 9d). [TR-building-ui-063]
36. **GIVEN** the InputMap at boot, **THEN** `toast_focus_cycle`, `toast_dismiss`, `toggle_issues`, `palette_next`, `palette_prev`, `formation_next`, `formation_prev`, `height_step_up`, `height_step_down` exist as registered actions (extends AC 22; Rules 9b/12). [TR-building-ui-065]

**Added by re-review (2026-07-10) — blocking headless**
37. **GIVEN** `toast_max_visible` Warnings shown and one anchor-only Warning, **WHEN** a visible Warning retires or is dismissed, **THEN** the longest-waiting anchor-only Warning is promoted into the freed slot immediately (Rule 9 promotion); **GIVEN** the promoted candidate was previously dismissed with `min_reshow_interval` remaining, **THEN** it is skipped and the next-longest eligible key promotes instead. [TR-building-ui-056]
38. **GIVEN** a Warning in Grace with 2s elapsed of a 3s `warning_grace_delay`, **WHEN** it tier-swaps to Info, **THEN** the Info key inherits the elapsed credit and surfaces after 1s more if the cause holds — no grace restart (Rule 9 per-subject bookkeeping; a flickering cause cannot indefinitely suppress surfacing). [TR-building-ui-058]
39. **GIVEN** Wall armed, **WHEN** `height_step_up`/`height_step_down` fire, **THEN** the stepper changes identically to +/− button clicks within 1–8; **GIVEN** Roof armed, **WHEN** `formation_next`/`formation_prev` fire, **THEN** the formation selection cycles identically to clicking the icons (Rule 9b keyboard completion). [TR-building-ui-059]
40. **GIVEN** a subject in Grace, **WHEN** the game is PAUSED past the remaining delay, **THEN** the expiry still fires and the queryable-state check decides surfacing — grace/debounce timers are wall-clock, frozen only by Suspended (Rule 9, Edge Case 6). [TR-building-ui-053]
41. **GIVEN** the focused toast auto-retires or is promoted away, **THEN** keyboard focus transfers to the next visible toast, or the anchor if none — never null while any focusable notification element exists (Edge Case 13). [TR-building-ui-073]

**Added by Slice revision (2026-07-23) — blocking headless (Build Mode, picking, ghosts, higher-level tools, slice view, projects panel, undo scope)**
42. **GIVEN** WorldNav, **WHEN** the `build_mode_toggle` action fires, **THEN** the state becomes Build-Mode/Idle and tool/higher-level-tool buttons become available (Rule 13). [TR-building-ui-075]
43. **GIVEN** WorldNav, **WHEN** any tool-select action fires (button, key 1–5, or a higher-level-tool key), **THEN** Build Mode enters AND the tool arms in the same frame — no intermediate Build-Mode/Idle frame is ever observable (Rule 13 auto-enter). [TR-building-ui-075]
44. **GIVEN** a tool armed inside Build Mode, **WHEN** Esc fires, **THEN** the state returns to Build-Mode/Idle only — never further (Rule 14, chain step 2). [TR-building-ui-076]
45. **GIVEN** Build-Mode/Idle with no tool armed and an active Selection, **WHEN** Esc fires, **THEN** the Selection clears and Build Mode remains ON (Rule 14, chain step 3). [TR-building-ui-076]
46. **GIVEN** Build-Mode/Idle with no tool armed and no active Selection, **WHEN** Esc fires, **THEN** the state returns to WorldNav (Rule 14, chain step 4). [TR-building-ui-076]
47. **GIVEN** WorldNav, **WHEN** a world click resolves to a cell occupied by both a villager and a project, **THEN** the villager claims the Selection and the project is NOT selected (Rule 15 precedence, Edge Case 14). [TR-building-ui-077]
48. **GIVEN** WorldNav, **WHEN** a world click resolves to a project cell with no villager on it, **THEN** that project becomes the Selection, its world-space outline renders, and its Projects Panel card highlights the same frame (Rule 15). [TR-building-ui-077]
49. **GIVEN** a project selected via its Projects Panel card, **THEN** the identical world-space outline appears as a world-click selection would produce — one Selection, two renders (Rule 21 reciprocal highlight). [TR-building-ui-086]
50. **GIVEN** a Planned or Released (not yet Built) blueprint ghost cell, **WHEN** the pick ray targets its face, **THEN** it resolves exactly as picking solid geometry would (Rule 16). [TR-building-ui-078]
51. **GIVEN** a dig-order marker cell, **WHEN** the pick ray targets it, **THEN** the ray passes through to whatever lies behind/beneath it — the dig-order cell is never the resolved pick target (Rule 16 exemption, Edge Case 15). [TR-building-ui-078]
52. **GIVEN** a water cell, **WHEN** the pick ray targets its surface, **THEN** it never resolves as a solid pick target regardless of any overlaid marker/ghost state (Rule 16). [TR-building-ui-078]
53. **GIVEN** any valid pick resolution in ANY mode (WorldNav or Build Mode), **THEN** the target cell renders its wireframe + hit-face quad highlight the same frame (Rule 17, always-on). [TR-building-ui-079]
54. **GIVEN** Build Mode, **THEN** the build grid renders around the cursor at `build_grid_opacity`; **GIVEN** WorldNav, **THEN** the build grid does not render (Rule 17). [TR-building-ui-079]
55. **GIVEN** a Draft ghost cell, **THEN** it renders at `ghost_alpha_draft`; **GIVEN** the same cell Released, **THEN** it renders at `ghost_alpha_released` — a visibly different alpha, same material tint (Rule 18). [TR-building-ui-080]
56. **GIVEN** any tool's preview resolves invalid, **THEN** the ghost renders in the State-Orange tint regardless of the selected material (Rule 18 override). [TR-building-ui-080]
57. **GIVEN** a terrain-replace marker and a dig/demolition marker both visible, **THEN** both render as inflated overlay boxes but with distinct icon/overlay SHAPE — never distinguished by shade or pulse-timing alone (Rule 18). [TR-building-ui-081]
58. **GIVEN** the Room tool with a 4×5 ground-plane drag, **WHEN** committed, **THEN** a single draft project is created containing the full perimeter wall run plus exactly one camera-facing door-gap cell omitted from that run (Rule 19). [TR-building-ui-082]
59. **GIVEN** the Room tool dragged below the 3×3 minimum, **WHEN** committed, **THEN** the invalid-commit cue appears and no project is created (Edge Case 20). [TR-building-ui-082]
60. **GIVEN** Auto-roof clicked on a cell belonging to an existing project, **WHEN** committed, **THEN** a Flat roof is generated over that project's bounding box at its top height and joins the SAME project id (Rule 19). [TR-building-ui-083]
61. **GIVEN** Auto-roof clicked on a cell belonging to no project, **WHEN** committed, **THEN** the invalid-commit cue appears and nothing is created (Edge Case 16). [TR-building-ui-083]
62. **GIVEN** the House stamp tool clicked on a 7×7-eligible footprint (uniform terrain height, clear volume), **WHEN** committed, **THEN** exactly ONE new draft project is created containing the flush floor, perimeter walls with one door gap, and roof (Rule 19). [TR-building-ui-084]
63. **GIVEN** the House stamp tool clicked on a footprint with a height-stepped cell or an obstruction, **WHEN** committed, **THEN** the invalid-commit cue appears and no project is created (Edge Case 17). [TR-building-ui-084]
64. **GIVEN** any slice level, **WHEN** `slice_up`/`slice_down`/`slice_reset` fire, **THEN** the render cutoff changes by exactly one cell / resets to show-all, and the "Ebene" HUD indicator reflects the new level the same frame (Rule 20). [TR-building-ui-085]
65. **GIVEN** a slice level hiding the villager or project that is the current Selection, **THEN** the Selection state is unchanged (still queryable, panel highlight still shows) even though no world-space outline renders (Edge Case 18). [TR-building-ui-085]
66. **GIVEN** a project transitions between lifecycle states (Draft/Released/Paused/Built/DemolitionQueued), **THEN** its Projects Panel card's status text and available action buttons update to match exactly that state, same frame (Rule 21). [TR-building-ui-086]
67. **GIVEN** a project with 0 of Y cells built, **THEN** its progress readout renders `0/Y`; **GIVEN** Y of Y, **THEN** `Y/Y` and the status text reflects completion — no easing on the bar (Rule 21, Art Bible §7.2/§7.4). [TR-building-ui-086]
68. **GIVEN** a Built cell (no surviving undo entry — already retired or beyond `undo_stack_depth`), **WHEN** undo fires, **THEN** it is a silent no-op — Built cells are never reachable by undo regardless of stack state (Rule 23, extends AC8/old Edge Case 4). [TR-building-ui-088]
69. **GIVEN** a project queued for or undergoing demolition, **THEN** no undo entry for it exists at any point in its demolition lifecycle — the undo button/stack never lists a demolition step (Rule 23). [TR-building-ui-088]

**Advisory — interaction test / manual walkthrough (UI evidence gate)**
23. **GIVEN** a drag begun in the world, **WHEN** the cursor enters HUD space, **THEN** the drag is NOT canceled (UI half); **WHEN** released over the HUD, **THEN** the commit uses the last valid world preview (integration with Camera & Input/Building — Edge Case 5, Rule 11's event-routing requirement). [TR-building-ui-069]
24. **GIVEN** a toast dismissal click in a live viewport, **THEN** the click is consumed — nothing beneath receives it (Edge Case 9). [TR-building-ui-072]
25. **GIVEN** a 1280×720 window, **THEN** the three zones' bounding rects lie fully in-viewport and do not intersect (screenshot/rect assertion — Edge Case 8). [TR-building-ui-071]
26. **GIVEN** a first-time playtester, **THEN** tool + material found unaided in under a minute (Game Feel criterion — playtest evidence doc).

**Added by Slice revision (2026-07-23) — advisory**
27. **GIVEN** a first-time player in WorldNav, **THEN** the "Bauen" toggle is discovered and Build Mode entered unaided within the existing one-minute Game Feel criterion (extends AC 26; Rule 13). [TR-building-ui-075]
28. **GIVEN** a completed house with its door gap, **THEN** a first-time player without prior explanation identifies the gap as a functional doorway — the confirmed 2026-07-23 playtest failure this AC is designed to catch (Rule 22). [TR-building-ui-087]
29. **GIVEN** the Projects Panel's provisional slice layout at 1280×720, **THEN** a walkthrough confirms cards remain legible and usable pending the formal `design/ux/projects-panel.md` spec (Rule 21 provisional flag). [TR-building-ui-086]

## Open Questions

1. **UX spec details** (exact layout metrics, icon design, arrangement,
   the default key bindings for the Rule 9b actions — currently
   `[assumption]`, including the Tab/`ui_focus_next` collision — and
   two onboarding beats the re-review flagged: first-time issues-anchor
   discoverability and badge-only-warning comprehension) →
   */ux-design build-hud in Pre-Production (see the UX Flag in UI
   Requirements)*
2. **Shortcut suppression when text input arrives** (Edge Case 10)
   → *Vertical Slice, with the first text field*
3. **Gamepad menu navigation** (technical-preferences: "partial, later")
   → *Alpha, shared with the Camera & Input open question*
4. **Exact toast styling per severity tier** (shape pairing committed
   in Visual/Audio; exact treatment) → *art bible*
5. **Where do future HUD elements live** (combat/wave, township)? Own
   systems slotting into these zones — → *their GDDs (VS/Alpha)*
6. **Undo repeat-velocity cap** — held-key repeat rides the OS rate
   (Rule 7); whether a max-undos-per-second cap is needed to prevent
   runaway repeat on aggressive OS settings → *MVP playtest*
7. **Godot 4.5–4.7 Control/input verification** — `mouse_filter`
   consumption semantics (Rule 11's event-routing requirement), the 4.6
   dual-focus system (**BLOCKING for Rule 9b's focus-cycling
   implementation** — Edge Case 13's explicit focus handoff depends on
   it), `InputEventKey.echo` key-repeat semantics (Rule 7/AC9), and
   4.5's AccessKit accessibility APIs postdate the model's training
   data; verify against the pinned 4.7 docs before implementing the
   HUD input layer → *Technical Setup / building ADR*
9. **Cross-GDD propagation (Slice revision, 2026-07-23)** — Building
   System needs its own revision to formally own: the project/draft/
   release/demolition lifecycle (Rule 21), the room/auto-roof/
   house-stamp cell-generation algorithms (Rule 19, reusing F1/F2/F5
   over a computed footprint), and the ghost pick-solid/dig-order/water
   picking contract (Rule 16) — this GDD documents the UI-visible
   contract now, but the mechanical ownership is not yet formalized
   there. → `/propagate-design-change` per REPORT.md's recommendation.
10. **Villager Info UI reciprocal update (Slice revision, 2026-07-23)** —
   its Rule 1 (Esc/selection) needs a reciprocal update for the new
   4-step Esc chain (Rule 14) and the villager-wins-ties Selection
   precedence (Rule 15), mirroring the existing reciprocal-clause
   pattern between these two GDDs. → next revision of that GDD.
11. **Door/window ITEMS vs. the door-gap affordance (Slice revision,
   2026-07-23)** — door/window items (a building-system.md production
   requirement) may fully supersede Rule 22's affordance requirement;
   track together, do not design the visual language twice.
12. **Replace/dig marker shape pairing (Slice revision, 2026-07-23)** —
   exact orange-family shade + silhouette pairing for terrain-replace vs.
   dig/demolition markers (Rule 18) → Art Bible §7.3's shape-budget
   table, first production icon pass.
13. **Default keybindings for the new actions (Slice revision,
   2026-07-23)** — `build_mode_toggle` and the Room/Auto-roof/
   House-stamp tool-selects are `[assumption]` until `/ux-design`;
   `slice_up`/`slice_down`/`slice_reset` retain their slice-validated
   `PageUp`/`PageDown`/`Home` defaults pending only a collision check
   against every other binding — same status class as Rule 9b's
   bindings (the ACTIONS are the commitment, not the keys).
14. **Timer architecture** — **RESOLVED 2026-07-11 via ADR-0011**: a
   single centralized expiry-timestamp manager (`Dictionary[key,
   TimerRecord]` + one shared `_process` loop), not N Godot `Timer`
   nodes — chosen for zero per-timer Node-lifecycle overhead at
   potentially-dozens-of-simultaneous-subjects scale, and for direct
   consistency with Time & Tick System's own "no per-consumer timers
   anywhere" precedent. [TR-building-ui-040] Correction to this GDD's original rationale:
   Godot's `Timer.paused` property actually DOES preserve and
   auto-resume `time_left` natively (confirmed via ADR-0011's engine
   validation) — N Timer nodes would NOT have required "fragile
   time_left reconstruction" as originally assumed here; the real
   reasons for the centralized choice are Node-overhead and
   project-precedent-consistency, not pause-fidelity (both approaches
   achieve exact pause fidelity equally well).
