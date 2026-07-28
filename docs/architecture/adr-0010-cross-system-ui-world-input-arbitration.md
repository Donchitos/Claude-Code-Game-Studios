# ADR-0010: Cross-System UI/World Input Arbitration

## Status
Accepted (2026-07-11 — per architecture-review-2026-07-11 recommendation; user-delegated decision. Not spike-gated and no dependency on a spike-gated ADR.)

**(Slice propagation 2026-07-23)** Remains Accepted. Extended in place (Decision §4) to cover the vertical-slice batch: the **Build Mode master toggle** gating whether a world click is placement or Selection, and **any-mode Selection routing** (villager vs project) — both expressed as extensions of the existing hover-suppression gate, not new mechanisms. See `change-impact-2026-07-23-slice-batch.md`.

## Date
2026-07-11

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7-stable |
| **Domain** | UI / Input |
| **Knowledge Risk** | HIGH per the Phase 0 inventory — 4.6's dual-focus system (mouse/touch focus separate from keyboard/gamepad focus) is the flagged risk; this ADR's mechanism relies on `_input()`/`_gui_input()`/`_unhandled_input()` propagation order and `mouse_entered`/`mouse_exited` hover signals, which are about mouse hover and input routing, not keyboard focus — verified as unaffected below rather than assumed |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md`, `modules/input.md`, `modules/ui.md` |
| **Post-Cutoff APIs Used** | None identified |
| **Verification Required** | Confirmed via `godot-specialist` validation (2026-07-11) — propagation order, hover-vs-focus independence, and `set_input_as_handled()` semantics all verified accurate for 4.7, unchanged 4.4→4.7. See Engine Specialist Validation note in Consequences. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Building UI, Building System, and Villager Info UI `/dev-story` implementation, specifically their click/drag/hover handling |
| **Blocks** | The specific code paths in all three systems that arbitrate world-vs-UI input ownership |
| **Ordering Note** | None |

## Context

### Problem Statement
Three GDDs jointly specify a shared contract with no single owner: Camera & Input must guarantee "exactly one owner per click" without ever interpreting the click itself (TR-camera-input-020); Building UI owns a hover-suppression flag that gates new world-picks from starting (TR-building-ui-028) but must not let that suppression swallow the release event of an already-in-progress world-space drag (TR-building-ui-029, which explicitly warns "a naive whole-zone `mouse_filter = STOP` would break this"); Villager Info UI consumes the same flag Building UI defines (TR-villager-info-ui-002). No GDD specifies the concrete Godot input-propagation mechanism that makes all three true simultaneously — that's this ADR's job.

### Constraints
- Camera & Input's existing, already-accepted contract: it reports only "action fired" via signal and must never interpret/branch on the action name (`architecture.md` API Boundaries) — this ADR must not require violating that
- Building UI has three HUD zones (bottom toolbar, top-right time controls, top-right notification area) — the hover flag is the OR of hover state across all three
- A world-space drag, once started, must be able to complete (commit or cancel) even if its release event's cursor position happens to be over an HUD zone at release time
- Godot's default per-event mouse routing is positional, not capture-based — a press and its corresponding release are routed independently based on wherever the cursor is at the moment each specific event fires, not tied to where the interaction "started"

### Requirements
- A click landing on an HUD Control must never also trigger a world-action (Camera & Input's exactly-one-owner guarantee)
- Starting a NEW world-pick or selection while hovering the HUD must be suppressed
- An ALREADY-in-progress world-space drag must never lose its release event to the HUD, regardless of where the cursor is when released
- The hover flag itself must be event-driven (this project's stated "event-driven, not polled" principle), not a per-frame mouse-position poll

## Decision

**Godot's native GUI-before-unhandled-input propagation handles new-click ownership by construction — Camera & Input needs no special logic. Building UI's hover flag (updated via `mouse_entered`/`mouse_exited` signals, ORed across its three zones) is an explicit, redundant safety net checked only when STARTING a new pick/selection. An already-in-progress world-space drag's release is tracked via `_input()` (which fires before Control consumption, on every node), not `_unhandled_input()`, so it is never swallowed by the HUD regardless of cursor position at release — and claims exclusive ownership of that event via `set_input_as_handled()`.**

**1. New-click ownership is structural, not a Camera & Input responsibility.** Godot routes input in a fixed order: `_input()` (every node, tree order) → GUI `_gui_input()` (Control tree, if not yet handled) → `_unhandled_input()` (every node, if still not handled). Camera & Input listens on `_unhandled_input()` for its InputMap actions — a click that lands on an HUD Control with the default `mouse_filter = STOP` is consumed during the GUI stage and never reaches Camera & Input's `_unhandled_input()` handler at all. TR-camera-input-020's "exactly one owner per click" therefore holds by construction, with zero code in Camera & Input dedicated to checking anything — it simply never sees an HUD-consumed event, preserving its existing "never interpret the action name" contract unchanged.

**2. The hover-suppression flag is a redundant, explicit safety net for starting NEW interactions — not the primary consumption mechanism.** Building UI's three HUD zones each connect their outer container's `mouse_entered`/`mouse_exited` signals to update one shared boolean (`_is_hover_suppressing = zone1_hovered or zone2_hovered or zone3_hovered`), exposed via `is_hover_suppressing_world_pick() -> bool` (already specified in `architecture.md`'s API Boundaries). Building System's placement-pick and Villager Info UI's selection query both check this flag at the moment a NEW press event reaches their own `_unhandled_input()` handler, before starting any new pick/drag/selection. This is deliberately redundant with point 1's native GUI consumption — it covers edge cases native routing alone might miss (e.g., a transparent gap within an HUD zone's bounding container that a designer wants suppressed for consistency, even without an individual Control physically there to consume the click), and it also gates GHOST PREVIEW updates (which should stop refreshing while hovering the HUD even without a click at all — a case native click-routing doesn't cover, since hover alone generates no consumable click event).

**3. An in-progress world-space drag's release is tracked via `_input()`, immune to HUD hover entirely.** Once Building System's placement tool enters its `Dragging` state (from a press that was validly received via `_unhandled_input`, i.e., was NOT over the HUD when it started), it switches its release-listening to `_input()` for the duration of that drag. `_input()` fires on every node, for every event, BEFORE any Control's `_gui_input()` gets a chance to consume it — so the release event reaches Building System's drag-completion logic regardless of whether the cursor is currently positioned over an HUD zone. Building System's `_input()` handler calls `get_viewport().set_input_as_handled()` immediately upon claiming this release, preventing it from ALSO being reinterpreted as, say, an accidental click on whatever HUD button happens to be under the cursor at release time — the in-progress drag exclusively owns its own release event. Once the drag completes (or is cancelled), Building System reverts to listening via `_unhandled_input()` for the next NEW press, restoring normal hover-suppression for new interactions.

**4. (Slice propagation 2026-07-23) Build-Mode-gated click routing + Selection arbitration — an extension of the same gate, not a new mechanism.** The vertical slice added a master **Build Mode** ("Bauen") toggle and, outside it, a **Selection** outcome (villager or project). This is a *routing* decision (which consumer's query owns a world click), the same class of arbitration this ADR already owns for hover suppression — it does NOT reinterpret placement (Camera & Input → Building System still own that pipeline) and adds no new event-routing primitive.

   - **Mode gate.** Building UI exposes the current interaction mode (WorldNav vs Build Mode). When an armed tool is consuming picks (Build Mode, ToolArmed), a world press routes to Building System's placement pipeline exactly as Decision §1–§3 already specify. When no tool is consuming the pick (WorldNav, or Build Mode Idle), a world press that survives the hover-suppression gate routes to **Selection** instead of placement. The mode is checked at the same point, and with the same precedence, as `is_hover_suppressing_world_pick()` — one additional gate condition on the NEW-press path, not a second dispatch mechanism.
   - **Selection resolution.** A qualifying world press resolves to at most one of: a **villager** selection (via ADR-0004's villager `Area3D` hit-test) or a **project** selection (via the ADR-0014 §4 DDA block pick → the owning project of the hit block). Nearest-wins with **villager-winning ties** — identical to ADR-0004's `pick_tie_epsilon` villager-wins rule (building-ui Rule 15). Clicking empty terrain/water clears Selection.
   - **Ownership.** Building UI owns this routing/Selection state (it is UI/mirror state, not placement interpretation) and shares the Selection outcome with Villager Info UI, consistent with the shared-gate pattern this ADR already establishes for hover suppression. The in-progress-drag `_input()` release rule (§3) is unaffected — mode gating applies only to NEW presses.

### Architecture Diagram
```
Input event routing order (fixed, Godot 4.7):
  _input()  (every node, tree order — Building System listens HERE only
             while mid-drag, to catch the release regardless of HUD hover)
        │  (if not yet handled)
        ▼
  Control._gui_input()  (GUI tree — HUD Controls consume clicks landing
                         on them via default mouse_filter = STOP; this is
                         what makes Camera & Input never see HUD clicks)
        │  (if not yet handled)
        ▼
  _unhandled_input()  (every node — Camera & Input's InputMap actions;
                       Building System's NEW-press detection when NOT
                       mid-drag; Villager Info UI's click-to-select)

Hover flag (event-driven, updated via mouse_entered/exited, OR of 3 zones):
  BuildingUI.is_hover_suppressing_world_pick()
        │
        ├─► checked by Building System BEFORE starting a new pick/drag
        │    (redundant safety net alongside native GUI consumption)
        └─► checked by Villager Info UI BEFORE a new select/deselect

In-progress drag release (immune to hover, by _input() propagation order):
  Building System enters Dragging (press validly received via
  _unhandled_input, i.e. was not over HUD)
        │
        ▼ switches release-listening to _input() for this drag's duration
  Release event fires — _input() sees it FIRST, regardless of current
  cursor position — Building System claims it, calls
  set_input_as_handled(), completes/cancels the drag
        │
        ▼
  reverts to _unhandled_input()-based new-press detection
```

### Key Interfaces
```gdscript
# Building UI's hover flag (already in architecture.md's API Boundaries):
func is_hover_suppressing_world_pick() -> bool

# Building UI's internal hover tracking (implementation detail):
var _zone_hovered: Array[bool] = [false, false, false]  # toolbar, time controls, notifications
func _on_zone_mouse_entered(zone_index: int) -> void:
    _zone_hovered[zone_index] = true
func _on_zone_mouse_exited(zone_index: int) -> void:
    _zone_hovered[zone_index] = false
func is_hover_suppressing_world_pick() -> bool:
    return _zone_hovered.any(func(h): return h)

# Building System's drag lifecycle (implementation detail):
func _unhandled_input(event: InputEvent) -> void:
    if _tool_state == ToolState.IDLE_OR_ARMED and event is InputEventMouseButton and event.pressed:
        if BuildingUI.is_hover_suppressing_world_pick():
            return  # new pick suppressed — redundant safety net
        _start_drag(event)
        set_process_input(true)  # switch to _input() for this drag's release

func _input(event: InputEvent) -> void:
    if _tool_state == ToolState.DRAGGING and event is InputEventMouseButton and not event.pressed:
        _complete_or_cancel_drag(event)
        get_viewport().set_input_as_handled()  # exclusive ownership of this release
        set_process_input(false)  # revert to _unhandled_input for the next new press
```

## Alternatives Considered

### Alternative A: Native GUI consumption + explicit hover flag (new interactions) + `_input()`-based drag-release (in-progress interactions) — CHOSEN
- **Description**: as detailed in Decision above.
- **Pros**: Camera & Input needs zero new code (its existing contract is preserved exactly as-is); the hover flag stays simple (event-driven, OR of 3 zones); the drag-release fix is scoped narrowly (only active during an in-progress drag, reverting immediately after) rather than restructuring the HUD's mouse_filter zones at all.
- **Cons**: two distinct mechanisms (native GUI consumption for simple clicks, `_input()` override for in-progress drags) to understand, rather than one uniform rule.
- **Rejection Reason**: N/A — chosen.

### Alternative B: Restructure HUD mouse_filter zones (narrow STOP regions, PASS/IGNORE gaps)
- **Description**: instead of `_input()`-based drag-release tracking, carefully shape the HUD's `mouse_filter` so only the exact interactive-widget rectangles use STOP, with all surrounding areas set to PASS or IGNORE, hoping a drag's release rarely lands exactly on a widget.
- **Pros**: no `_input()` override needed in Building System.
- **Cons**: doesn't actually solve the problem — a drag's release CAN legitimately land exactly on an interactive widget (e.g., the player drags toward the toolbar and releases on a button by mistake), and the fix would then depend on precise, brittle mouse_filter geometry rather than a robust ownership rule. TR-building-ui-029 explicitly frames this as the wrong direction ("a naive whole-zone `mouse_filter = STOP` would break this" implies the fix is NOT about getting the zone shape "less naive," but about a different event-routing strategy entirely).
- **Rejection Reason**: doesn't structurally guarantee the release is caught — still probabilistic based on cursor geometry at release time.

### Alternative C: Godot input capture / `set_mouse_mode(MOUSE_MODE_CAPTURED)` during drags
- **Description**: use Godot's mouse-capture mode to lock cursor tracking to Building System during a drag, bypassing Control routing entirely.
- **Pros**: a very strong guarantee of exclusive ownership.
- **Cons**: `MOUSE_MODE_CAPTURED` hides and locks the cursor to the viewport center (a common use is FPS-style camera look, not drag-and-place UI) — it would also change cursor visibility/behavior in ways that don't match this project's drag-to-place interaction feel (the cursor needs to remain visible and free-moving during a placement drag, just with guaranteed release delivery).
- **Rejection Reason**: solves the release-delivery problem by introducing an unrelated and unwanted behavior change (cursor capture/hiding).

## Consequences

### Positive
- Camera & Input's existing, already-accepted API contract needs zero changes — this ADR resolves a 3-GDD seam without touching the one system whose contract was explicitly protected elsewhere.
- The drag-release fix is scoped and temporary (active only during `Dragging` state) rather than a permanent restructuring of HUD input routing.
- The hover flag stays simple and event-driven, consistent with `architecture.md`'s "event-driven, not polled" principle.

### Negative
- Building System's placement tool must correctly toggle between `_unhandled_input()` and `_input()` listening depending on its own state — a stateful input-routing switch that must be tested for both directions (entering and reverting).
- Two complementary mechanisms (native GUI consumption, explicit flag check) protect the "new interaction" case — a future contributor must understand both are needed, not just one.

### Risks
- **Risk**: none identified beyond the general "two mechanisms to understand" maintenance cost already noted in Consequences → Negative — engine-specialist validation found no correctness gap in the propagation-order/hover/`set_input_as_handled()` mechanics themselves.

**Engine Specialist Validation** (2026-07-11, `godot-specialist`, run before finalizing this ADR): confirmed all three load-bearing claims. (1) `_input() → Control._gui_input() → _unhandled_input()` is the correct Godot 4.7 propagation order, unchanged across 4.4→4.7 — the only input-routing changes in that window (4.7 device-ID constants, 4.6 dual-focus) don't touch this dispatch order or `mouse_filter` semantics. (2) `mouse_entered`/`mouse_exited` hover signals are confirmed independent of the 4.6 dual-focus system — that change separates keyboard/gamepad focus from mouse/touch focus, but hover-boundary detection is neither and has behaved identically since 4.0. (3) `get_viewport().set_input_as_handled()` called from `_input()` is confirmed to correctly stop the same event instance from reaching later stages (`_gui_input()`, `_unhandled_input()`) within a single dispatch. Verdict: "safe to accept as written." No corrections were needed.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|----------------------------|
| camera-input.md | TR-camera-input-020: "Exactly one owner per click... this system must not also emit the corresponding world-action signal" | Satisfied structurally via Godot's GUI-before-unhandled-input routing — Camera & Input never sees an HUD-consumed click, Decision §1 |
| building-ui.md | TR-building-ui-028: "Hover-over-HUD sets a queryable flag that gates world-pick starts" | `is_hover_suppressing_world_pick()`, event-driven via `mouse_entered`/`mouse_exited`, Decision §2 |
| building-ui.md | TR-building-ui-029: "Hover suppression must not swallow the pointer-release event of an in-progress world-space drag" | `_input()`-based release tracking during `Dragging` state, immune to HUD hover, Decision §3 |
| villager-info-ui.md | TR-villager-info-ui-002: "Villager-hit query must honor the SAME shared world-pick hover-suppression flag defined by Building UI" | Villager Info UI checks the same `is_hover_suppressing_world_pick()` flag before selecting/deselecting, Decision §2 |

## Performance Implications
- **CPU**: Negligible — `mouse_entered`/`mouse_exited` are already-existing Godot Control signals, fired only on actual boundary crossings, not polled. `_input()` is only actively listened to during the narrow window of an in-progress drag, not continuously.
- **Memory**: Negligible — one `Array[bool]` of size 3 for zone hover state.
- **Load Time**: N/A.
- **Network**: N/A — single-player project.

## Migration Plan
N/A — no existing code.

## Validation Criteria
- A unit test simulates a press starting in world-space, a mouse move over an HUD zone, and a release over that zone — asserts the release is still delivered to and handled by Building System's drag-completion logic, not swallowed by the HUD.
- A unit test simulates a press directly on an HUD Control — asserts Camera & Input's `_unhandled_input` handler never fires for that event (no world-action signal emitted).
- A unit test simulates hovering (no click) over each of the 3 HUD zones independently — asserts `is_hover_suppressing_world_pick()` returns true for each, and false when hovering none.

## Related Decisions
- Protects Camera & Input's existing "opaque passthrough, never interprets action names" contract (`architecture.md` API Boundaries) — this ADR resolves the seam without amending that contract.
