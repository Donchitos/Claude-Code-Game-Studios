# Concept Prototype Report: Hybrid Voxel Building ("The Last Seal")

> **Date**: 2026-07-09
> **Prototype Path**: Engine (Godot 4.7)
> **Concept File**: design/gdd/game-concept.md

---

## Hypothesis

If the player builds a small house — dragging walls/floors/roofs **and** freely
placing/editing individual blocks, furniture, doors and windows — building feels
**fluid and expressive**. Signal: a first-time player builds an enclosed, furnished
little house within a few minutes without instruction, voluntarily reshapes/decorates
(expression), and placing/dragging feels fluid rather than fiddly.

---

## Riskiest Assumption Tested

That hybrid **drag + free-place** building in a 3D voxel space feels fluid — rather
than fiddly at the camera / snapping / depth-perception level (the concept doc's stated
risk: *"Building must feel better than the predecessor's grid rooms… doors/windows/
build-over-time must land"*).

**Result: the assumption held.** Once the interaction was surface-aware (walls extrude
vertically in one action, placement snaps to the block under the cursor), building read
as fluid and satisfying to the tester. The camera/orbit/snapping did not become the
friction the concept doc feared.

---

## Approach

An engine prototype built as a standalone Godot 4.7 project. Everything is generated in
code (one `main.gd`) so the scene stays trivial. Colored cubes stand in for all art; a
manual grid dictionary (`Vector3i → MeshInstance3D`) holds placed blocks. Verification was
done live through the `godot-mcp` bridge (run scene, read state, screenshot, drive logic).

**Path chosen:** Engine (Godot)
**Reason for path:** Build *feel* in 3D — dragging, snapping, camera, depth — can only be
judged natively; HTML latency would have lied about it.

**Shortcuts taken (intentional):**
- Hardcoded values, placeholder colored cubes, no art/audio
- No villager, needs, mood, or build-over-time (deliberately out of scope — feel only)
- No save/load, menus, or architecture
- A `_debug_house()` helper (MCP-only) used to verify rendering without simulated input

---

## Result

The prototype ran on first launch and was iterated **four times** in response to the
tester's hands-on feedback — each iteration a real feel-finding:

1. **Walls felt wrong built layer-by-layer.** Tester: *"man baut Wände eher aufrecht in
   die Höhe, statt Ebene für Ebene."* → Walls were changed to extrude the full wall-height
   in one drag/click. Tester: *"hochziehen der Wände ist super."*
2. **Fixtures/edits needed surface awareness.** Tester wanted to place a fixture onto a
   wall and select a specific block *without changing the height layer manually.* → Added
   voxel raycast (DDA) block-picking: the block under the cursor is highlighted and
   placement attaches on its face or replaces it in place.
3. **Dragging computed against the ground, not the highlighted block.** Tester found this
   confusing (*"Es hat ansonsten immer auf den Boden alles platziert"*). → Drags now lock
   their build height to the picked block's surface.
4. **Requests that signalled investment, not rejection:** undo/redo ("Zurück/Vorwärts
   Knopf") and *real* roofs instead of a flat slab. Both were added (undo/redo with
   on-screen buttons + Ctrl+Z/Y; four roof formations: Flach/Sattel/Walm/Pult).

Final tester verdict, unprompted: *"Ich finde das super."* Hypothesis check: **Bestätigt**.
The tester was already thinking about future expansion — a sign the core loop is engaging
enough to build on.

---

## Metrics

| Metric | Value |
|--------|-------|
| Path used | Engine (Godot 4.7) |
| Iterations to playable | 1 (ran on first launch; then 4 feel-driven feature iterations) |
| Prototype duration | ~1 session |
| Playtesters | 1 internal (the developer) |
| Feel assessment | Fluid once surface-aware. Key frictions were interaction-model gaps, not camera/latency: walls needed vertical extrusion; placement/drag needed to target the highlighted block, not a fixed ground plane. All resolved. |
| Hypothesis verdict | CONFIRMED |

---

## Recommendation: PROCEED

The core hypothesis is confirmed: hybrid drag + free-place building is fluid and
expressive, and the feared camera/snapping/depth friction did not materialize. Crucially,
the tester's own requests (undo, real roofs, surface-aware editing) are *investment*
signals — they were reaching for more depth, not away from the concept. The building loop
is worth designing properly.

---

## If Proceeding

- **Core tuning values discovered:**
  - Wall extrusion height default **3 blocks** felt right as a starting point (adjustable 1–8).
  - Cell size 1.0, block render size 0.96 (voxel gap reads well).
  - Drag threshold ~6 px to separate click vs drag.
- **Assumptions confirmed:**
  - The furniture/fixture-carries-function *placement* is natural once picking is surface-aware.
  - The voxel/GridMap approach is viable for this interaction (Godot 4.7's stepped cubes read clearly as pitched roofs, walls, etc.).
- **Assumptions disproved / to revise:**
  - **Concept doc Anti-Pillar needs softening.** It currently says *"NOT block-by-block
    sandbox."* The tester explicitly wanted a **hybrid**: drag tools for speed **plus**
    free single-block placement for creative expression. This actually *reinforces* the
    concept's #1 Expression aesthetic — but the anti-pillar wording must change from
    "not block-by-block" to "block-by-block allowed, but gridded & purposeful — not a free
    sandbox." → Flag during `/design-review`.
  - Walls are inherently **vertical**: the design must treat a wall as a one-action,
    full-height object, not a per-layer slab.
- **Emergent mechanics worth formalizing:**
  - **Surface-aware placement/editing** (pick the block under the cursor; attach on its
    face or replace in place) — this is core to how building should feel.
  - **Undo/redo as a first-class building affordance** — it removes the fear of misclicks
    and directly enables the expressive experimentation the concept wants.
  - **Roof formations** (gable/hip/shed/flat) generated over a footprint — a real design
    surface with room to grow (Krüppelwalm, Mansarde, smoother/steeper pitches, etc.).

**Next steps:**
1. `/design-review design/gdd/game-concept.md` (carry the anti-pillar revision + findings)
2. `/gate-check`
3. `/map-systems`
4. `/design-system building` (use these learnings in Tuning Knobs and Formulas)

---

## Lessons Learned

- **What assumptions were broken by actually building this?**
  The friction was never the camera or latency (the concept doc's fear). It was the
  *interaction model*: building only feels right when it is surface-aware (walls extrude
  vertically; placement/drag target the highlighted block, not a fixed ground plane). A
  flat-plane build model felt wrong immediately.

- **What surprised us that didn't show up in the brainstorm?**
  The tester wanted a **genuinely hybrid** builder (drag + free block-by-block) — closer
  to Stonehearth than the concept's grid/room abstraction implied. This aligns with the
  Expression pillar but contradicts the current anti-pillar wording. Also: undo and real
  roof shapes surfaced as must-haves the moment building felt good.

- **What would we test differently next time?**
  Start surface-aware from the first build (block-picking + vertical walls) rather than a
  flat plane — that was the source of every early friction point.

---

## Tooling note

This session also established the project's Godot MCP integration
(`mkdevkit/godot-mcp`) — it let the assistant run the scene, read live state, drive build
logic, and view screenshots directly, tightening the iteration loop. See the
`godot-mcp-setup` memory.

---

> *Prototype code location: `prototypes/building-concept/`*
> *This code is throwaway. Never refactor into production — the production building system
> is written from scratch, informed by this report.*
