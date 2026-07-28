# UX Spec: Main Menu & Settings

> **Status**: **Approved** — `/ux-review` 2026-07-23 (first pass: NEEDS REVISION,
> 2 blocking / 4 advisory; all 6 applied, re-review verdict APPROVED, 0/0)
> **Author**: ux-designer (Claude) — autonomous draft, delegated authoring session
> **Last Updated**: 2026-07-23
> **Journey Phase(s)**: unknown — no player journey map yet (shared gap with
> `hud.md` OQ1 / `villager-panel.md` OQ1 / `projects-panel.md` OQ2)
> **Template**: UX Spec
> **Scope**: Main Menu (top-level) + Settings sub-panel (Audio/Display/
> Controls/Accessibility groups) + the New Game overwrite-confirmation modal.
> Does NOT include: the in-gameplay Pause/system menu (specified separately in design/ux/pause-menu.md), a
> save-slot picker (ADR-0012 defines a single save file only), or a
> world-generation/seed system (not yet designed anywhere).
> **Behavioral source of truth**: **this document** — no dedicated GDD exists
> for a menu/settings system; Main Menu behavior is UX-owned pending any
> future menu-system GDD. Individual setting VALUES are owned elsewhere (see
> Data Requirements): the audio mixer, display/window, InputMap actions,
> `accessibility-requirements.md`'s Alpha commitments.
> **Binding inputs**: `design/ux/hud.md` / `design/ux/villager-panel.md` /
> `design/ux/projects-panel.md` (structural siblings — section structure and
> rigor matched; this spec claims no HUD zone since it is a full-screen
> replacement, not an overlay). From `design/ux/interaction-patterns.md`:
> **reused as-is** — P12 (Loading Transition Overlay), P15 (Discrete
> Stepper, reused for the UI-scale control), B1 (Button), B4 (Icon Radio
> Group, reused for Fullscreen/Windowed), B3-as-basis (List mechanics
> underlying the new Resolution Dropdown); **baseline this spec deliberately
> excepts/contrasts** — P6 ("never modal" — this spec's New-Game
> overwrite-confirmation modal is a reasoned, flagged exception, see
> Confirmation Policy) and P16 (persistent-HUD InputMap-action convention —
> this screen instead uses Godot's native `ui_*` focus actions, a deliberate
> contrast for a full-screen menu with no world-hotkey collision risk to
> dodge, see Interaction Map). `design/ux/accessibility-requirements.md` (A1–A7, including the
> Alpha-tier commitments this screen exists to deliver), `design/art/art-bible.md`
> §2.1 (Settlement warmth), §2.5 (Menus/Pause mood target), §3.4 (UI shape
> grammar), §4.5 (UI palette), §7 (typography/panel anatomy/motion),
> `design/gdd/game-concept.md` (title/fantasy/tone), `design/gdd/scene-world-management.md`
> (boot/scene-flow this menu sits in front of), `docs/architecture/adr-0012-save-load-serialization-strategy.md`
> (save/load contract — see Open Questions for a flagged conflict)
> **Milestone placement (flag up front)**: Main Menu & Settings is named as an
> **Alpha-tier** deliverable in three existing documents
> (`interaction-patterns.md` Gaps, `accessibility-requirements.md` Tier
> Commitment table, ADR-0012's Enables/Blocks). At MVP and Vertical Slice,
> `scene-world-management.md` Core Rule 1 boots **directly into the Valley
> scene with no menu at all**. This spec is authored ahead of that tier so
> the design exists before implementation begins — see Open Questions #1–#2
> for the two upstream documents that need a companion revision before this
> screen can actually ship.

---

## Purpose & Player Need

**"Get me into my village, or get me back to it — with the fewest possible
decisions in between."** The player arrives at the Main Menu wanting to do
exactly one of four things: start fresh, resume what they already built,
adjust a setting that's bothering them (too loud, wrong resolution, wrong
keybind), or leave. Per Art Bible §2.5, this screen is deliberately **not** a
mood piece — "neutral competence — a tool, not a mood... get in, decide, get
out" — a direct contrast to the Villager Panel's "attachment moment" or the
Projects Panel's "promises kept" framing. Where every other UX spec in this
project earns its place by deepening Pillar 1 or Pillar 2, this screen's job
is to get out of the way of them as fast as possible. If the Main Menu were
slow, cluttered, or made the player hunt for Continue, every session would
start on the wrong foot — a "quiet pride" game (§2.1) undercut by its own
front door.

TR-main-menu-001: The Main Menu's four top-level intents (New Game, Continue,
Settings, Quit) must each be reachable in exactly one click/press from the
top-level screen — no nested "Play" submenu, no confirmation gate on entry.

---

## Player Context on Arrival

Two genuinely different arrivals, both handled by the same screen:

- **First-time player**: no save exists yet. Calm, mildly curious,
  low-investment — nothing to protect yet. New Game is the only meaningful
  action; the screen should not make them hunt for it or explain a Continue
  option that doesn't apply to them.
- **Returning player**: a save exists. The dominant feeling is
  impatience-to-return — "I know what I want, let me back into my village."
  This is the opposite arrival mood from the Villager Panel/Projects Panel
  (voluntary, curious, mid-session); here the player has already decided
  before the screen even renders.

Unlike every sibling spec, arrival at the Main Menu is **not voluntary** — it
is the mandatory first screen the game shows (post-Alpha; see Milestone
placement above). This is closer to `scene-world-management.md`'s Booting
state than to any in-gameplay overlay: the player didn't ask for this screen,
they asked to launch the game, and this is what launching produces. The
design implication is the opposite of the villager/projects panels'
"worth lingering over" framing — every extra second here is friction, not
attachment.

Never time-pressured (no diegetic countdown, no auto-advance) — but the
screen itself should never make the player feel like it's stalling them.

---

## Navigation Position

Root of the navigation tree: `Boot → Main Menu → { New Game | Continue |
Settings | Quit }`. Settings is a same-screen sub-panel (not a scene
transition — see Layout Specification); New Game and Continue are the only
actions that leave this screen via a real scene transition (into `InValley`,
`scene-world-management.md`'s existing state).

TR-main-menu-002: Main Menu is reachable **only** at game launch at this
tier — there is currently no "quit to main menu" action from gameplay (no
Pause Menu UX spec exists yet; `hud.md`'s pause treatment is world-dim +
time-stop, not a menu overlay). See Open Questions #9.

---

## Entry & Exit Points

| Entry Source | Trigger | Player carries this context |
|---|---|---|
| Game launch | Boot sequence completes (post-Resource-DB-Ready, `scene-world-management.md` Booting state) | None — this is the first screen the player sees |
| *(future, unspec'd)* Quit-to-menu from gameplay | Not yet designed — no Pause Menu UX spec exists | — (Open Questions #9) |

| Exit Destination | Trigger | Notes |
|---|---|---|
| New game (into `InValley`) | Click/press **Neues Spiel**, no existing save | Instant, no confirmation — nothing to lose (TR-main-menu-003) |
| New game, OVERWRITING an existing save | Click/press **Neues Spiel** with a save present → confirm the overwrite modal | The one destructive, confirmed action in this spec — see States & Variants and Open Questions #5 |
| Continue (into `InValley`) | Click/press **Fortsetzen** (only rendered if a save exists) | Loads the existing save via the Save/Load orchestrator (ADR-0012) — see Open Questions #2 for a flagged sequencing conflict |
| Quit application | Click/press **Beenden** | Instant, no confirmation (see States & Variants rationale) — the OS/engine quit call, not a scene transition |
| (no exit) Settings | Click/press **Einstellungen** | Same-screen sub-panel swap, not an exit |

No one-way exits at the top level beyond Quit itself (which ends the process,
by design). Settings is always recoverable via **Zurück** (Back).

---

## Layout Specification

### Information Hierarchy

1. **Primary actions** (New Game / Continue / Settings / Quit) — the reason
   the screen exists; the player's eye and input should land here first.
2. **Title/wordmark** — identity anchor ("The Last Seal" — provisional
   working title, `game-concept.md`), secondary to the actions themselves;
   this is a tool, not a title card (§2.5).
3. **Background art** — mood/warmth carrier (§2.1), lowest information
   priority: pure atmosphere, never gates a decision, never conveys state
   (nothing here is subject to A1 color-independence since it carries no
   gameplay information).
4. **Build/version tag** — smallest, corner-anchored, QA/support utility
   only.

### Layout Zones

**TASTE CHOICE — flagged, not fully resolved.** Two candidate arrangements:

- **Option A — Center-screen stack.** Logo above, buttons centered,
  background full-bleed behind everything. Industry-standard, simplest to
  build, scales awkwardly if Settings or New Game ever need inline
  sub-controls (a seed field, a difficulty picker) since the center column
  has no natural "grows into" direction without recentering everything.
- **Option B (recommended) — Left-half content column, right-half/full-bleed
  background.** Buttons + logo anchored in a fixed-width left column; the
  right two-thirds of the screen stays uninterrupted background art —
  specifically so §2.1's "warmest pixel cluster" carrying element (a lit
  window, per the same principle the settlement itself uses) stays visible
  and unobstructed, the same way the HUD keeps its center third
  world-visible. Gives the action list room to grow downward (Settings
  sub-panel, a future seed field) without ever needing to recenter.

Recommending **Option B** for the reason above; flagged for confirmation
before lock (see Open Questions #8).

**Resolution floor**: this screen inherits the project-wide minimum
supported layout, **1280×720** (`hud.md`'s Layout rules,
TR-building-ui-071) — no exception for the Settings sub-panel. All four
groups (Audio, Anzeige, Steuerung, Barrierefreiheit) must render with no
clipping or overlap at that floor; this is the binding constraint AC-UX10
tests against.

### Component Inventory

| # | Component | Type | Interactive | Pattern / Source |
|---|---|---|---|---|
| M1 | Wordmark/title | Static text/logo | No | Art-director asset; provisional title per `game-concept.md` |
| M2 | Primary action list (4 items, Continue conditional) | Vertical button stack | Yes | **New pattern needed**: none of P1–P16/B1–B4 cover a full-screen keyboard-focus-navigable menu list (B3 is a HUD-embedded expandable list, not a root navigation surface) — reuses B1 Button per-item, adds Godot's native `ui_up`/`ui_down`/`ui_accept`/`ui_focus_next`/`ui_focus_prev` focus chain (see Interaction Map) |
| M3 | Background art | Static image | No | Art-director asset — see Open Questions #7 (TASTE CHOICE) |
| M4 | Build/version tag | Static text | No | UI-owned chrome text (P10 carve-out) |
| M5 | Overwrite-confirmation modal | Modal dialog | Yes | **New pattern**: "Destructive Confirmation Modal" — first legitimate exception to the project's established no-modal baseline (P6); see Open Questions #5 |
| S1 | Settings sub-panel header + Back button | Panel header + B1 button | Yes | Art Bible §7.5 panel anatomy |
| S2 | Audio group: Master/Music/SFX sliders | 3× continuous slider | Yes | **New pattern**: "Continuous Slider" — this is the first real consumer of the Slider gap already tracked in `interaction-patterns.md` Gaps |
| S3 | Display group: Resolution select + Fullscreen/Windowed | Dropdown (new, B3-derived) + B4 Icon Radio Group (2-option) | Yes | Fullscreen reuses B4 as-is (2 mutually exclusive states, no new pattern); Resolution is a **new Dropdown pattern** built on B3's list mechanics, closed by default |
| S4 | Controls group: rebinding entry point | Row list + per-row "rebind" button | Yes | Delivers `accessibility-requirements.md` A2/A7's Alpha commitment; granular remap-capture flow deferred (Open Questions #4b) |
| S5 | Accessibility group: UI/font scale | Discrete stepper (preset %) | Yes | Reuses **P15 Discrete Stepper** as-is — a small bounded range (e.g. 90/100/110/125%), no new pattern needed |
| S6 | Accessibility group: camera sensitivity | Continuous slider | Yes | Reuses the new S2-class slider pattern |

### ASCII Wireframe

**Top-level menu (Option B layout, save exists):**

```
┌──────────────────────────────────────────────────────────┐
│ THE LAST SEAL                              (background   │
│ ─────────────                               art fills    │
│                                              the right    │
│  [ Fortsetzen ]      <- default focus        two-thirds,  │
│  [ Neues Spiel ]                             a warm lit-  │
│  [ Einstellungen ]                           window scene │
│  [ Beenden ]                                 per §2.1)    │
│                                                            │
│                                                            │
│                                          v0.1.0-dev  (M4) │
└──────────────────────────────────────────────────────────┘
```

**Settings sub-panel (same screen, content swapped):**

```
┌──────────────────────────────────────────────────────────┐
│ ‹ Zurück      EINSTELLUNGEN                               │
│ ──────────────────────────                                │
│  Audio                                                     │
│   Master   ▓▓▓▓▓▓▓░░░  70%                                │
│   Musik    ▓▓▓▓▓░░░░░  50%                                │
│   Effekte  ▓▓▓▓▓▓▓▓░░  80%                                │
│                                                             │
│  Anzeige                                                    │
│   Auflösung        [ 1920×1080  ▾ ]                         │
│   Fenstermodus     ( Vollbild ) ( Fenster )                 │
│                                                              │
│  Steuerung                                                   │
│   [ Tasten neu belegen… ]                                    │
│                                                               │
│  Barrierefreiheit                                             │
│   UI-Skalierung          [ − ] 100% [ + ]                      │
│   Kamera-Empfindlichkeit ▓▓▓▓▓░░░░░  50%                        │
└──────────────────────────────────────────────────────────┘
```

**Overwrite-confirmation modal (New Game, save already exists):**

```
        ┌──────────────────────────────────────┐
        │ Neues Spiel starten?                  │
        │                                        │
        │ Dein bestehender Spielstand wird       │
        │ überschrieben und kann nicht           │
        │ wiederhergestellt werden.              │
        │                                        │
        │      [ Abbrechen ]*  [ Neu starten ]   │
        └──────────────────────────────────────┘
```
\* default keyboard focus on open — safety-first, never the destructive
option (matches `pause-menu.md`'s identical convention for its own Quit
confirmation modal).

---

## States & Variants

| State / Variant | Trigger | What Changes |
|---|---|---|
| First-boot / no save | No save file present | **Fortsetzen is fully hidden**, not disabled — same "absence over disabled-with-no-explanation" convention already established (`hud.md` Z2/Z3 "zero issues → fully hidden," `projects-panel.md` "no projects → fully hidden," TR-main-menu-004). Neues Spiel becomes the sole, obviously-primary, default-focused action. |
| Returning player | Save file present | Fortsetzen renders and receives default keyboard focus (top of the list, the most likely intent per Player Context on Arrival). |
| Settings open | Einstellungen clicked/pressed | Content area swaps instantly (§7.4 "instant swap, zero duration" — matches every sibling spec's panel-swap rule) to the Settings sub-panel; Back (Zurück) returns instantly to the top-level list, previous focus restored. **Default keyboard focus on open lands on Zurück**, not on the first settings control — the same safety-first default this spec uses everywhere a surface can be entered without an explicit prior focus target (matches the overwrite modal's default below and `pause-menu.md`'s identical convention). |
| New-Game overwrite confirmation | Neues Spiel clicked/pressed WITH a save present | Modal dialog (M5) appears; the list behind it is inert but visible (dimmed) — the one screen in this spec that pauses interaction. **Default keyboard focus lands on Abbrechen, never Neu starten** (safety-first, matching `pause-menu.md`'s identical convention for its own Quit confirmation modal). |
| Transitioning | New Game or Continue confirmed | Full-screen transition overlay takes over (P12, existing pattern) — Main Menu itself has no loading state of its own; it hands off to the existing Scene/World Management transition. |
| Continue load failure (new edge case) | Save file exists but fails to load (corrupt/unreadable) | Returns to the top-level Main Menu with an inline error message near Fortsetzen (**not** a full boot HALT — the menu already loaded successfully; only the load attempt failed). Fortsetzen stays visible but the player is told the load failed rather than silently retried. This exact failure path is not yet defined by any existing document — see Open Questions #12. |
| Settings value out of range / corrupt config | Config file missing/corrupt at boot | Every control falls back to its documented default (not an error state — no error surface shown, since this is a cosmetic/audio concern, not data loss) |

No loading state for the menu's own render (instant, all data local); no
progression/locked-content variants at this tier (no DLC/unlock system
exists).

**Why Beenden needs no confirmation (unlike `pause-menu.md`'s Quit):** Main
Menu is never mid-session — any progress that exists has already been
persisted by the last transition-complete savepoint (ADR-0012), or no save
exists yet. Quitting from here risks losing nothing, which is the opposite
risk profile from Pause Menu's Quit (which can end an active, unsaved
session — see Confirmation Policy below for the New-Game overwrite's
matching but distinct reasoning).

---

## Confirmation Policy

**Decision: only the New-Game overwrite crosses the no-modal baseline (P6)
— Quit (Beenden) does not.** This project now has two confirmation-modal
precedents to reconcile this spec against: `projects-panel.md`'s Abriss/
Abbrechen (explicitly **no modal**) and `pause-menu.md`'s Quit (explicitly
**modal**, default focus Abbrechen). The New-Game overwrite modal sits on
the same side as Pause Menu's Quit, and the reasoning is categorical, not
cosmetic — the same distinction `projects-panel.md` itself draws, applied
here:

- **Whole-save loss, not single-project loss.** Demolishing a project costs
  that one project's rebuild time (`projects-panel.md`'s own "near-zero
  permanent cost" reasoning); overwriting the save costs the **entire**
  settlement — every project, every villager, every furnished room — in one
  action.
- **No job-gated grace window.** A demolition order takes real simulated
  time to execute and its status visibly flips to "Wird abgerissen" before
  anything is actually gone (`projects-panel.md`'s Confirmation Policy,
  point 1) — that delay plus visible status change is itself a form of soft
  confirmation. A save overwrite has no equivalent gradual step to catch a
  misclick partway through.
- **Atomic and instant, not gradual.** The overwrite either has not
  happened (still on the confirmation modal) or has fully happened (new
  save written) — there is no partial, observable, still-cancelable middle
  state the way a queued demolition provides.

**This is the same category of exception `pause-menu.md`'s Quit
confirmation already established** ("no partial-recovery path... a
strictly larger and less-recoverable category than anything the no-modal
precedent was established against") — both are navigation-out-of-progress
actions, not in-loop build/demolish decisions, which is exactly the
boundary the no-modal philosophy was never meant to cover. **Default focus
on Abbrechen** (never the destructive option) follows the identical
safety-first convention `pause-menu.md` already set for its own
confirmation modal.

**Flagged forward**: this project now has three confirmation-adjacent
decisions in three different specs (`projects-panel.md`'s no-modal Abriss,
`pause-menu.md`'s modal Quit, this spec's modal New-Game overwrite) that
should be reconciled into one named pattern-library entry — a "Destructive
Confirmation Modal" pattern with an explicit decision rule for when it
applies — rather than each spec re-deriving the same reasoning
independently. Not added to `interaction-patterns.md` by this spec (scope:
this document only); see Open Questions #5.

---

## Interaction Map

Mapping interactions for: **Keyboard/Mouse (primary), PC only.** Unlike the
Villager Panel and Projects Panel (which carry a stated MVP mouse-only
exemption for world-entity selection, A2), **the Main Menu carries no such
exemption** — it is a traditional menu screen with no world-click affordance
to fall back on, so full keyboard operability is required from day one, not
deferred to Vertical Slice.

**Gamepad note** (per `technical-preferences.md`'s "partial gamepad support
may be added later for menu/camera navigation only"): this is explicitly the
first place partial gamepad support is expected to land. TR-main-menu-005:
designing keyboard navigation on Godot's **native Control focus system**
(`ui_up`/`ui_down`/`ui_accept`/`ui_cancel`/`ui_focus_next`/`ui_focus_prev`)
rather than bespoke HUD-style actions (contrast with the HUD's custom P16
actions, built specifically to dodge world-hotkey collisions) means gamepad
support is close to free later: binding a gamepad D-pad/face-button to the
same `ui_*` actions in the InputMap requires no new menu-side code.

| Action | Input | Immediate feedback | Outcome |
|---|---|---|---|
| Navigate action list | ↑/↓ or Tab/Shift+Tab (`ui_up`/`ui_down`/`ui_focus_next`/`ui_focus_prev`) | Focus ring moves (Hearth Gold outline, A2) | Focus moves to next/prev item, no wrap past the ends |
| Activate focused action | Enter/Space (`ui_accept`) or click | Button pressed-state flash | Fires that action's Events Fired row |
| Click a button directly | Mouse click | Pressed-state flash | Same as keyboard activation |
| Settings panel opens | (automatic, on Einstellungen) | Focus lands on Zurück, same frame | Consistent safety-first default across every focus-bearing surface in this spec |
| Navigate within Settings (any group) | ↑/↓ or Tab/Shift+Tab | Focus ring moves | Chain runs Zurück → Audio sliders → Anzeige controls → Steuerung → Barrierefreiheit, top to bottom; **does not wrap** — Up from Zurück and Down from the last control (camera sensitivity) are both no-ops, identical to the top-level list's no-wrap rule |
| Back out of Settings | Esc (`ui_cancel`) or click Zurück | Instant swap back | Settings closes, top-level list regains focus at its prior position |
| Esc at top-level (nothing to back out of) | Esc | None | No-op (TR-main-menu-008) — mirrors P11's "a press with no applicable step is a no-op" convention; Esc never triggers Quit |
| Overwrite modal opens | (automatic, on Neues Spiel with an existing save) | Focus lands on Abbrechen, same frame | Cancel is one Enter-press away by default; reaching Neu starten requires a deliberate focus move (TR-main-menu-011) |
| Cancel the overwrite modal | Esc or click Abbrechen | Modal closes instantly | Returns to top-level list, nothing changed |
| Confirm the overwrite modal | Click Neu starten (mouse or keyboard-focused + Enter) | Modal closes, transition begins | Existing save is replaced; New Game proceeds (TR-main-menu-006) |
| Drag/arrow-key a slider (S2/S6) | Mouse drag, or ←/→ while focused | Value updates live, no easing (§7.4) | Value applies AND persists immediately — no separate Save/Apply step (TR-main-menu-007) |
| Step the UI-scale stepper (S5) | Click +/− or ←/→ while focused (P15 reuse) | Value updates instantly | Applies immediately |
| Open the Resolution dropdown (S3) | Click, or Enter/Space while focused | List expands below the control (B3-derived) | No value change until a row is chosen |
| Choose a resolution row | Click a row, or ↑/↓ + Enter within the open list | List collapses, value updates | Applies immediately; a resolution change never requires a restart-confirmation dialog in this design (flagged as a possible future exception if a real windowing edge case demands it) |
| Toggle Fullscreen/Windowed (B4) | Click either option, or ←/→ while focused | Instant state swap | Applies immediately |
| Begin a keybind rebind (S4) | Click "Tasten neu belegen…" row's rebind button | Row enters a "press any key" listening state (visual: pulsing focus ring only, sub-3Hz per A5) | Next input captured and bound — granular flow deferred, Open Questions #4b |

---

## Events Fired

| Player Action | Event Fired | Payload / Data |
|---|---|---|
| Confirm New Game (no save, or after overwrite confirm) | `new_game_requested` | none (or a provisional seed, if/when that system exists — Open Questions #3) |
| Confirm Continue | `continue_requested` | none — the Save/Load orchestrator resolves "the" save (single-file, no slot picker at this tier, ADR-0012) |
| Any settings control changed | `setting_changed` (UI-internal) | (setting key, new value) → written immediately to the settings/config store (see Data Requirements, Open Questions #4a) |
| Quit | none — direct engine call | `get_tree().quit()`, not a game-state event |
| Settings opened/closed | none | Pure UI navigation, no game-state implication |

- **No analytics events at MVP/VS tier** — same deliberate omission as every
  sibling spec (no analytics system exists yet).
- **`new_game_requested` and `continue_requested` are the two actions this
  spec identifies as needing a `scene-world-management.md` revision** to
  actually fire a transition — see Open Questions #1/#2. This UI does not
  itself own or write game-save state; it only requests the transition and
  reports settings changes to their own store.

---

## Transitions & Animations

- **Menu appears**: instant on boot completion, no fade —
  `scene-world-management.md`'s existing MVP boot rule ("no intermediate
  menu or loading screen... near-instant") already sets this precedent; the
  Menu itself should feel like the same "near-instant, no ceremony" boot
  moment, just with a screen now attached to it.
- **Settings panel swap**: instant, zero duration (§7.4's "Panel show/hide
  (instant swap)" — Never Animates table, identical rule to every HUD
  panel).
- **Overwrite-confirmation modal**: instant appear/dismiss — no fade-in.
  This is the one place a NEW motion decision has to be made explicit: the
  project's animation standards table (`interaction-patterns.md`) has no
  modal-appearance entry at all (there are no modals anywhere else).
  Recommending **instant, matching every other panel**, rather than
  inventing a new fade-in-just-for-modals rule — consistency over novelty
  (flagged in Open Questions #5 alongside the pattern addition itself).
- **Slider/value changes**: raw value every frame, no easing (§7.4, matches
  every value-bar rule elsewhere in the project).
- **Transition into gameplay**: the existing full-screen transition overlay
  (P12) — owned by `scene-world-management.md`, not re-specified here.
- Zero motion in the background art itself (Art Bible §2.5's "zero ambient
  motion (no parallax, per A5)" — binding, not a Menu-specific new rule) —
  see Open Questions #7 for the resulting background-treatment TASTE CHOICE.

---

## Data Requirements

| Data | Source System | Read / Write | Notes |
|---|---|---|---|
| Save file existence (boolean) | Filesystem / Save-Load orchestrator (ADR-0012) | Read | Drives the Fortsetzen hidden/shown state |
| Save file contents (on Continue) | Save-Load orchestrator `.load()` (ADR-0012) | Read | Triggers deserialize into a freshly-instantiated Valley — see Open Questions #2 for the sequencing conflict this exposes in ADR-0012's current text |
| New save (on New Game) | Save-Load orchestrator (indirectly, via the subsequent transition-complete savepoint per ADR-0012) | Write (not owned by this UI — routed only) | This UI does not itself write the save; it requests the transition that leads to one |
| Audio levels (master/music/sfx) | **Settings/config store — not yet architecture-defined** | Read + Write | See Open Questions #4a: no ADR currently covers a settings-persistence mechanism distinct from ADR-0012's game-save file; this spec assumes a small `user://settings.cfg`-style store |
| Resolution / fullscreen state | Settings/config store + engine `DisplayServer` | Read + Write | Same store as audio; applied live via `DisplayServer` calls |
| Keybind overrides | Settings/config store + project-scope InputMap (A7) | Read + Write | Must round-trip through named InputMap actions, never hardcoded scancodes (A7, unchanged from every other spec) |
| UI/font scale | Settings/config store | Read + Write | Feeds the Alpha-tier UI-scale feature every other spec's Open Questions already anticipated (`hud.md`, `accessibility-requirements.md` Alpha row) |
| Camera sensitivity | Settings/config store → Camera & Input system | Read + Write | Consumed by `camera-input.md` (not re-derived here — out of scope) |

No architectural concerns beyond the two flagged conflicts (Open Questions
#1/#2) and the one flagged gap (#4a) — everything else follows the
established "this UI writes nothing except routing player intent" pattern
from the sibling specs.

---

## Accessibility

Per `design/ux/accessibility-requirements.md`:

- **A1**: no gameplay-critical color-only signals exist on this screen
  (buttons differentiate by position/label/focus-ring, not hue); N/A beyond
  the general discipline.
- **A2**: **no MVP exemption on this screen** (TR-main-menu-009) — every
  control (top-level buttons, all Settings controls, the confirmation modal)
  is fully keyboard-operable with a visible focus ring (Hearth Gold outline,
  matching every other spec's focus-visual convention) — this is the FIRST
  screen in the project where A2 has zero stated exemption.
- **A3/A4**: text `#EDE6DA` on `#262220` (inherited, ≈12:1); button labels
  ≥18px (header tier), settings labels/values ≥16px floor, tabular numerals
  on any percentage/resolution value that re-renders (audio %, UI scale %).
- **A5**: zero background motion (Art Bible §2.5, binding); zero panel-swap
  animation; the rebind-listening state's pulsing focus ring stays sub-3Hz
  per the existing distress-icon precedent (§2.3).
- **A6**: no audio-only cue on this screen beyond an optional slider-drag
  preview tone (flagged as deferred/optional, not blocking); fully usable
  muted, as everywhere else.
- **A7**: every keybind lives in a named, project-scope InputMap action —
  this screen is literally A7's Alpha-tier delivery mechanism (the rebinding
  UI), not merely a consumer of it.

**This screen is the intended home for three of
`accessibility-requirements.md`'s Alpha-tier commitments** (input rebinding,
camera sensitivity, UI scale) — its existence is itself an accessibility
deliverable, not just a subject of the checklist.

---

## Localization Considerations

- **UI language convention note**: `villager-panel.md`'s committed
  activity-label set is English ("Thinking," "On the way," …), while
  `projects-panel.md` (authored later, same day as this spec) commits to
  German UI chrome ("Geplant," "Im Bau," …). This spec follows the **more
  recent, German convention** for consistency with the project's current
  direction — flagged in Open Questions #10 as a likely-needed follow-up
  revision to `villager-panel.md`.
- **Button labels** (Neues Spiel / Fortsetzen / Einstellungen / Beenden,
  Zurück, section headers Audio/Anzeige/Steuerung/Barrierefreiheit) are
  short, UI-owned chrome text (P10 carve-out) — safe under +40% expansion at
  this length, but verify at final font lock (same deferral every sibling
  spec uses).
- **The overwrite-confirmation modal body text** is the longest string on
  this screen — budget it to wrap across 2–3 lines comfortably (matches the
  why-string/worker-names wrap-never-truncate rule generalized from the
  villager/projects panels).
- **Resolution values** (e.g. "1920×1080") are locale-neutral numeric
  strings, no formatting needed.
- **Percentage values** (volume, UI scale, sensitivity) are locale-neutral
  integers.

---

## Acceptance Criteria

- [ ] AC-UX1 The Main Menu renders within one frame of boot completion, with
  no visible loading state of its own.
- [ ] AC-UX2 With no save file present, Fortsetzen is fully absent (not
  disabled) and Neues Spiel receives default keyboard focus.
- [ ] AC-UX3 With a save file present, Fortsetzen renders, receives default
  keyboard focus, and clicking/pressing it loads the existing save and
  transitions into the Valley.
- [ ] AC-UX4 Clicking/pressing Neues Spiel with an existing save present
  shows the overwrite-confirmation modal; confirming proceeds to a fresh
  game and replaces the existing save; canceling (button or Esc) returns to
  the Main Menu with the existing save fully intact.
- [ ] AC-UX5 Every interactive element on this screen (top-level buttons, all
  Settings controls, the confirmation modal's two buttons) is reachable and
  operable using ONLY the keyboard, with a visible focus indicator on each.
- [ ] AC-UX6 Any settings value changed (a slider, the resolution dropdown,
  fullscreen toggle, UI scale stepper) applies immediately with no separate
  Save/Apply step, and persists correctly across an application relaunch.
- [ ] AC-UX7 A Continue attempt against a corrupted/unreadable save file
  returns the player to the Main Menu with a visible inline error — never a
  hard crash, never a silent no-op.
- [ ] AC-UX8 Esc at the top-level menu is a no-op; Esc inside Settings
  returns to the top-level list; Esc while the overwrite modal is open
  cancels it — all three verified in one pass.
- [ ] AC-UX9 Grayscale screenshot pass over every state this screen renders
  (default, no-save, Settings open, modal open, rebind-listening) confirms
  no information is conveyed by hue alone (A1).
- [ ] AC-UX10 The Settings sub-panel renders with no clipping/overlap across
  all 4 groups (Audio, Anzeige, Steuerung, Barrierefreiheit) at 1280×720.
- [ ] AC-UX11 The overwrite-confirmation modal opens with default keyboard
  focus on Abbrechen, never on Neu starten, on every open.

---

## Open Questions

1. **Milestone/architecture gap — scene-world-management.md needs a
   MainMenu state.** `scene-world-management.md`'s Booting state currently
   transitions straight into `InValley` (Core Rule 1,
   TR-scene-world-management-034) with explicitly "no intermediate menu."
   Once this screen ships, that document's States table needs a new
   `MainMenu` state inserted between `Booting` and
   `Transitioning`/`InValley`, and Core Rule 1's wording needs revision.
   Owner: technical-director, via a `scene-world-management.md` revision
   pass. **Not resolved by this spec** — flagged, not designed here, per
   this project's own conflict-surfacing convention (mirrors
   `projects-panel.md`'s hud.md follow-up flag).
2. **ADR-0012 conflict — automatic vs. menu-triggered load.** ADR-0012's
   Decision section currently states loading happens "at boot if a save
   exists" (automatic, no player choice) — directly incompatible with a menu
   that offers a deliberate New Game vs. Continue choice. ADR-0012 needs an
   amendment making `.load()` a **Continue-button-triggered** action, not a
   boot-automatic one, once this screen ships. Owner: technical-director,
   ADR-0012 revision.
3. **World seed / New Game options — genuinely open per the task brief.** No
   GDD currently commits to a procedural world-generation or seed system
   (`game-concept.md` only mentions "seed variety" as an aspirational
   Full-Vision aesthetic, not a committed MVP/VS/Alpha system). This spec
   ships New Game as a single no-option action; if/when a Voxel World
   generation-with-seed system is designed, this spec needs a revision
   adding a seed input control (candidate new Text Input pattern, see #6).
   Owner: game-designer / a future `voxel-world` generation GDD.
4. **Settings persistence mechanism undefined.** (a) No ADR currently
   defines a settings/config store distinct from ADR-0012's game-save file;
   this spec assumes a small `user://settings.cfg`-style ConfigFile
   mechanism exists — needs architecture confirmation (technical-director).
   (b) The granular keybind-rebind capture flow (listen-for-next-input,
   conflict detection against existing bindings) is deferred — this spec
   only commits to the entry point and top-level behavior.
5. **New pattern-library candidates from this spec** — recommend adding at
   the next `interaction-patterns.md` session: (a) **Destructive
   Confirmation Modal** — this spec's New-Game overwrite is now the SECOND
   reasoned exception to the project's "never modal" baseline (P6),
   alongside `pause-menu.md`'s Quit confirmation and `projects-panel.md`'s
   deliberate no-modal Abriss/Abbrechen; see Confirmation Policy above —
   these three decisions should be reconciled into one named pattern with
   an explicit decision rule, rather than left as three independently
   re-derived judgment calls; (b) **Continuous Slider** — already tracked as
   a Gap in `interaction-patterns.md`, this spec is its first real
   consumer; (c) **Dropdown/Select** (resolution list) — a closed-by-default
   variant of B3. Not added to that library by this spec (scope: this
   document only).
6. **Text Input pattern** — only needed if #3 (world seed) is ever adopted;
   not designed here.
7. **Background art treatment — art-director TASTE CHOICE, not
   UX-decidable.** Art Bible §2.5 locks "zero ambient motion" for the
   Menus/Pause mood, which rules out any live/orbiting camera treatment.
   Within that constraint, the choice between a fully painted/rendered
   keyart vignette vs. a single static captured frame from the actual
   in-engine settlement (both satisfy zero-motion) is a stylistic call
   belonging to art-director, not this spec — flagged per the same handoff
   convention as Art Bible §7.6's other open items.
8. **Layout arrangement (Option A center-stack vs. Option B left-column) —
   TASTE CHOICE.** Option B recommended above; flagged for confirmation
   before this spec locks its Layout Zones section as final.
9. **No "quit to main menu" path exists yet.** This screen's only entry
   point at this tier is game launch. If/when a Pause/system menu is
   designed, it should add a return-to-Main-Menu entry point here —
   cross-reference this spec at that time.
10. **`villager-panel.md`'s English UI-chrome labels vs. this spec's (and
    `projects-panel.md`'s) German convention** — flagged for a
    `villager-panel.md` follow-up revision to align project-wide UI
    language, rather than silently leaving the inconsistency.
11. **Player journey map missing** — same shared gap as every sibling spec;
    template at `.claude/docs/templates/player-journey.md`.
12. **Continue-load-failure path is newly invented by this spec, not yet
    corroborated elsewhere.** Neither `scene-world-management.md` (which
    only defines a boot-time DB-failure HALT and a dungeon-entry-transition
    abort) nor ADR-0012 (which has no failure path for a menu-triggered load
    at all) currently describes what happens when a Continue click's load
    fails. This spec proposes a menu-level inline error, recoverable without
    restarting the application — needs corroboration from both documents
    once #1/#2 are resolved.
