# Story 003: Villager body view, hit proxy & slice hook — the substrate three epics are blocked on

> **Epic**: Presentation Experience (Ambient Life & Loop-Payoff Communication)
> **Status: Complete (2026-07-27 — 1298/1298 suite green 0 orphans, parent-verified)
> **Layer**: Presentation
> **Type**: Integration
> **Tier**: **CORE** (a hard blocker for four stories across two other epics)
> **Estimate**: **1.0 agent-day**
> **Owner**: `godot-specialist` (scene / `Node3D` / `Area3D` work), with `godot-gdscript-specialist` review on the `.gd` files
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-26

## Context

**GDD**: N/A — source is `design/art/art-bible.md` §5.2 (2-block scale) + §5.3 (accent channel), the same
GDD-less precedent this epic already uses (see the epic's "Requirements (Art-Bible-traced, no TR-IDs)" note).
**Requirement**: Art-Bible-traced — this story has **no TR-ID of its own**. The downstream requirement it
must satisfy is `TR-villager-info-ui-014` (a dedicated villager collision layer, named by that TR), which
`villager-info-ui-002`'s ACs are written against.

**ADR Governing Implementation**: **ADR-0004** (`Area3D` hit-test, layer 1) · **ADR-0009** (two-layer
position model, `physics_interpolation_mode = OFF`) · **ADR-0001** (injected-tier `setup()`, duck-typed
nil-safe providers)
**ADR Decision Summary**: ADR-0004 — each villager instance carries a child `Area3D` + `CollisionShape3D`
on collision layer 1; the click pick is `intersect_ray()` with `collision_mask = 1`,
`collide_with_areas = true`, `collide_with_bodies = false`, nearest wins, villager wins within
`pick_tie_epsilon`. ADR-0009 — `current_cell` is DISCRETE and the sole authoritative value for every logic
query; `_visual_position` is CONTINUOUS, lerped every frame in `VillagerAi._process` for rendering ONLY and
never read by any logic; the villager's visual node sets `physics_interpolation_mode = OFF` explicitly.
ADR-0001 — injected-tier modules are wired via `setup()`, headless-mockable, and take duck-typed nil-safe
`Object` dependencies.

**Engine**: Godot 4.7-stable | **Risk**: **HIGH** (per this epic's engine-risk table — the work sits on the
rendering domain *and* touches the villager-AI domain, both post-cutoff HIGH-risk areas; cross-reference
`docs/engine-reference/godot/` before using any `Node3D` / `Area3D` / `MeshInstance3D` / physics-query API)
**Engine Notes**:
- `physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF` must be set **explicitly in code** on
  `VillagerBodyView`, defensively, not relied on from a project-wide default (ADR-0009 Risks/Mitigation;
  control manifest line 71). Until this story lands, that manifest rule had no node to apply to.
- Godot does **not** disable an `Area3D`'s collision when an ancestor's `visible` goes false. See Trap 1 in
  Implementation Notes.
- `PhysicsRayQueryParameters3D` default flags are a documented trap (control manifest line 219) —
  `collide_with_areas` defaults such that an areas-only query silently misses. The AC list carries the
  regression guard for it deliberately.

**Control Manifest Rules (this layer)**:
- Required: the villager visual node sets `physics_interpolation_mode = OFF` explicitly (line 71); villagers
  carry a child `Area3D` + `CollisionShape3D` on layer 1, mask 0 (line 64); the layer convention (line 82);
  the click pick = DDA block distance + `intersect_ray()` with `collision_mask = 1`,
  `collide_with_areas = true`, `collide_with_bodies = false`, nearest wins, villager wins within
  `pick_tie_epsilon` (line 152); the `PhysicsRayQueryParameters3D` default-flags trap (line 219).
- Forbidden: reading the interpolated visual position from **any** logic path — occupancy, targeting,
  walled-in, seal-prevention and job-selection all read `get_current_cell()` (ADR-0009 §2); any mutating
  call from the presentation module into `VillagerAi`; any Selection read/write/emit from the view.
- Guardrail: presentation adds **no simulation** — this epic's founding constraint. Tick results with the
  presenter present must be byte-identical to a run without it.

### Ruling provenance — read this before implementing

This story is a **transcription** of technical-director rulings **VB-1** (the ruling) and **VB-2** (the story
spec) in `production/architecture-decisions-m02-preflight-2026-07-26.md`. Those rulings are **PROVISIONAL —
pending user ratification** (away-mode ruling); treat them as the planning assumption until ratified. VB-2
states verbatim: *"Spec only. The producer authors the story file; I have not written one."* Nothing in this
file is invented beyond the two clearly-marked notes in Open Decisions.

**Both rulings were verified by the TD against landed source on 2026-07-26**, not against epic summaries:
`villager_ai.gd:347-348` is `class_name VillagerAi` / `extends Node` (not `Node3D`); one node per villager is
the actual architecture (`:882-884`), which is why `get_state()` and `get_current_cell()` carry no
`villager_id` parameter; `Valley.tscn` hosts exactly one `VillagerAi` of `type="Node"` with `villager_id = 0`
and **no children**, and the scene's only `MeshInstance3D` is the ambient torch indicator;
`_visual_position: Vector3` (`:625`) is private, recomputed every `_process` frame (`:937-941`) from
`_from_cell.lerp(_to_cell, _intra_tick_progress)`, and has **no public getter**; repo-wide, `Area3D` /
`CollisionShape` appear under `src/` **only inside doc comments**; `src/presentation/` already exists as a
populated presentation tier.

**The ruling, stated plainly (VB-1):** *the body is a separate presentation-tier view node, one per villager,
driven by pulling the AI node's visual position every frame.* `VillagerAi` stays `extends Node` and gains
exactly one new public method.

**Why `presentation-experience` and not the two obvious alternatives (VB-2).** Not `villager-ai-behavior`:
that is a Core-layer simulation epic, and putting a mesh story in it is precisely the layering inversion
VB-1 §1 rejects. Not `villager-info-ui`: that epic's own Known Conflict 1 says outright *"it is not a UI
story's job to fix"*, and the body has three consumers (Villager Info UI, Building UI's Slice View, and this
epic's own ambient-life idle behaviors) — a shared substrate owned by a leaf UI epic will be scoped to that
leaf's needs. `presentation-experience` already owns `src/presentation/`, is already Art-Bible-governed, and
its own `presentation-001` Sub-B ("villager idle behaviors") is *invisible without this story*.

**Why not a child `Node3D` of `VillagerAi`, and why not making `VillagerAi` a `Node3D` (VB-1 §1).**
`VillagerAi` is a Core-layer simulation node whose entire test suite constructs it headlessly via
`Node.new()` + mocks (ADR-0001). Giving it mesh children moves rendering responsibility into a Core module,
makes every headless unit test allocate RenderingServer resources, and couples the FSM's node type to a
presentation choice that will be revised the moment the art-bible-faithful villager replaces the placeholder.
Presentation reads Core, never the reverse. Nothing about `VillagerAi`'s instantiation, its tests, or its
`Valley.tscn` entry changes.

**Why not `MultiMesh` (VB-1 §3).** MVP population = 1, Vertical Slice = 5, Full-Vision ceiling **20–30**. At
30 villagers × ~3 mesh parts that is **~90 draw calls against a 2000 draw-call budget** — 4.5% of budget for
the entire cast, and the voxel world is on MultiMesh/chunked geometry precisely so this headroom exists.
`MultiMesh` is rejected on four independent grounds, any one of which is sufficient: it cannot carry a
per-instance `Area3D` (hit-testing would need a parallel collider hierarchy anyway, defeating the
consolidation); per-instance hiding for Slice View becomes transform-hackery instead of `visible = false`;
Art Bible §5.3's accent hue is specified as a **material swap on a shared mesh**, which is the
per-instance-`MeshInstance3D` idiom, and §5.4's squad equipment layer adds *structure* per instance, not just
color; and the overhead-icon anchor (`villager-info-ui-005`) needs a real `Node3D` per villager to parent to.
**Revisit only if the population ceiling moves past ~200** — that is the recorded trigger, not "if it feels
slow".

**On the manifest question — ruled explicitly, because it was raised (VB-1 §4).** There is **no violation and
no new exception**. The manifest's physics prohibitions are scoped by their own text to *block/world*
picking: line 89 ("Zero physics API calls in **Building System's** pick path") and line 98 ("Zero
`PhysicsServer3D`/`RayCast3D` in any picking path (**Voxel World AND Building System**, grep-verifiable)").
Villager hit-testing is separately and affirmatively **required** by the same manifest (lines 64, 82, 152,
219). The two picks are structurally disjoint by construction: Building System's placement pick issues
**zero** physics queries and is therefore *incapable* of hitting a villager, which is what
`TR-villager-info-ui-014` actually asks for. The data-layer alternative (a GDScript ray-vs-AABB sweep over
the roster) was considered and **rejected on reversibility, not on merit** — ADR-0004 is Accepted, the TR
names a dedicated villager collision layer, the manifest encodes the layer convention project-wide, and
`villager-info-ui-002`'s ACs are written to it. **Keep ADR-0004. Do not introduce a data-layer villager
pick.** If someone later wants to remove physics from the project entirely, this is the one call site to
change — it is recorded here as the single physics dependency it is.

---

## Acceptance Criteria

*Transcribed from VB-2's AC list. Blocking ACs are headless unit tests in
`neues-spiel/tests/unit/presentation/`.*

**Blocking (headless unit tests):**

- [ ] `VillagerAi.get_visual_position() -> Vector3` exists, returns the same value `_visual_position` holds
      after a `_process` frame, and **`VillagerAi` still `extends Node`** — asserted, not assumed. Every
      pre-existing villager-ai test passes with **zero test edits**.
- [ ] `VillagerBodyView` is headless-instantiable via `Node3D.new()` + a mock `ai_source`; a `null`
      `ai_source` is inert, not a crash.
- [ ] The view stores **no** position of its own and performs **no** interpolation: grep proves zero `lerp(`
      in `villager_body_view.gd`, and the view's `global_position` after a frame equals
      `ai_source.get_visual_position()` **exactly** (not approximately).
- [ ] `physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF` on the view, set explicitly in
      code (manifest line 71 / ADR-0009 mitigation).
- [ ] The view carries a `VillagerHitProxy` (`Area3D`) with `collision_layer == 1`, `collision_mask == 0`,
      `monitoring == false`, and a `villager_id` matching its view's.
- [ ] A `PhysicsRayQueryParameters3D` query with `collision_mask = 1`, `collide_with_areas = true`,
      `collide_with_bodies = false` aimed at a positioned view **hits** and resolves to the correct
      `villager_id`; the same query with `collide_with_areas` left at its default **misses** (this second
      half is the regression guard for manifest line 219's documented trap — *write it, it will save someone
      a day*).
- [ ] Body height spans **exactly 2 cells** (Art Bible §5.2), asserted against the mesh AABB, not eyeballed.
- [ ] `set_slice_level(y)`: given a villager whose `get_current_cell().y > y`, the view is
      `visible == false` **and** its hit proxy's `collision_layer == 0`; restoring the level restores both.
      The visibility test uses the **discrete** cell, not the interpolated position.
- [ ] The view never reads, writes or emits anything Selection-related — grep proves zero references to
      Selection APIs (`building-ui-016` AC65's precondition).
- [ ] `IconAnchor` exists as a named child `Node3D` at the top of the figure and its world position tracks
      the body every frame.
- [ ] `set_highlight(NONE|HOVER|SELECTED)` exists and is observable (a state getter is enough); the
      treatment itself is out of scope.
- [ ] `VillagerBodyPresenter.setup()` is explicitly callable, asserts nothing it does not need, registers no
      Autoload, and creates exactly one view per roster entry from a **mocked** roster provider; a removed
      villager's view is freed.
- [ ] Grep proves the presentation module makes **zero** mutating calls into `VillagerAi` (pure-mirror
      invariant, same bar as the UI epics).

**Integration (needs real `villager-ai-021`):**

- [ ] With `starting_villager_count = N`, booting `Valley.tscn` produces exactly N visible bodies at the
      spawned villagers' positions, and the simulation's tick results are **byte-identical** to a run with
      the presenter absent (presentation adds no simulation — the epic's founding constraint).

**Advisory (`production/qa/evidence/`):**

- [ ] Screenshot: a villager standing on terrain at settlement-camera distance, readable as a 2-block
      figure. Screenshot: the same villager sliced away at a cutoff below its cell.

---

## Implementation Notes

*Derived from VB-1 §§1–6. The ruling names the nodes and the seams; these notes carry the two traps it
flagged by name.*

**Two new scripts under `neues-spiel/src/presentation/` (VB-1 §1):**

- `villager_body_view.gd` — `class_name VillagerBodyView extends Node3D`. One instance per villager. Holds
  `villager_id: int` and a **duck-typed, nil-safe** `ai_source: Object` (the landed DI precedent:
  `needs_provider`, `job_queue`, `population`), from which it reads exactly three members:
  `get_visual_position()`, `get_current_cell()`, `get_state()`.
- `villager_body_presenter.gd` — `class_name VillagerBodyPresenter extends Node3D`. Valley-hosted,
  injected-tier `setup()`. Owns the create/free lifecycle: one `VillagerBodyView` per roster entry, freed on
  despawn. Injected with a duck-typed, nil-safe roster provider (a `null` provider means "no villagers",
  which is correct and non-crashing exactly as it is for every other landed provider seam). The presenter
  *is* Valley-hosted; the views are its children — that gives one place that knows how many villagers exist
  and one place to free them, which is what `villager-ai-021`'s roster makes necessary.

**The one new method on `VillagerAi` (VB-1 §2):**

```gdscript
## PRESENTATION ONLY. Returns the interpolated render position. Never read this
## from any logic path — occupancy, targeting, walled-in and seal-prevention
## checks all read get_current_cell() (ADR-0009 §2).
func get_visual_position() -> Vector3
```

It is a **read-only accessor over the existing field**. The lerp stays exactly where ADR-0009 put it
(`VillagerAi._process`); the view stores no position, caches nothing, and performs no interpolation of its
own — it assigns `global_position = ai.get_visual_position()` in its own `_process`, **every frame,
pull-only**. That is the same "pure mirror, re-read every frame, signals are hints not values" discipline the
UI layer is already held to. One writer, N readers, zero copies: no second source of truth is created.

**Geometry (VB-1 §3).** Per-villager `MeshInstance3D` children of the view. Placeholder geometry for M02
matching Art Bible §5.2's scale fact and nothing more: a 2-cell-tall figure, box or capsule body + box head
at roughly the 45:55 split, one flat `StandardMaterial3D` per villager so the accent-hue channel has
somewhere to live later. What M02 needs is a readable silhouette that can be **seen, clicked, hidden by a
slice, and hung an icon on**.

**Hit proxy (VB-1 §4).** The `Area3D` + `CollisionShape3D` lives as a child of `VillagerBodyView` — so it
moves with the *visual* position for free, which is the behaviourally correct answer (a click lands where the
player sees the villager, not where their discrete `current_cell` is mid-transit). Concrete form:

```gdscript
class_name VillagerHitProxy
extends Area3D
var villager_id: int = 0
# collision_layer = 1 (ADR-0004 "villagers"), collision_mask = 0,
# monitoring = false (it never needs to detect anything), monitorable = true.
```

A **typed proxy class** rather than `set_meta(&"villager_id", …)`: the picker resolves `intersect_ray()`'s
`collider` to `VillagerHitProxy` and reads a typed `int`, which honours the project's static-typing standard
and is greppable.

**Slice View (VB-1 §5).** The view exposes `set_slice_level(level: int) -> void` and applies
`visible = ai.get_current_cell().y <= level` — the **discrete** cell, not the interpolated one, so a villager
does not flicker in and out mid-lerp at the cutoff boundary. Building UI owns the level; the view receives it
and owns no copy of it beyond the last value pushed.

> **⚑ TRAP 1 — hiding must disable the hit proxy.** Godot does *not* disable an `Area3D`'s collision when an
> ancestor's `visible` goes false. Without an explicit `collision_layer = 0` while hidden (restored to `1`
> when shown), a sliced-away villager stays clickable — a direct violation of `building-ui-016`'s "a cell
> hidden by the cutoff cannot become a NEW hover target or Selection target".

> **⚑ TRAP 2 — hiding must not touch Selection.** `building-ui-016` AC65 requires that slicing away the
> *currently selected* villager leaves Selection intact (Selection is UI state, not render state). The view
> therefore **never reads, writes or signals Selection**. It only stops rendering and stops being pickable.

**Anchors and affordances — surfaces only, treatments later (VB-1 §6).** The view carries a named child
`Node3D` **`IconAnchor`** at the top of the 2-cell figure (local y ≈ 2.0 plus a small clearance), which
`villager-info-ui-005`'s billboard manager parents to or reads a world position from. And it exposes a seam
`set_highlight(mode: HighlightMode) -> void` (`NONE` / `HOVER` / `SELECTED`) whose M02 implementation may be
as crude as a material tint. The actual outline mechanism is `villager-info-ui-006` +
`godot-shader-specialist` and is deliberately **not** decided here — this story owes those stories a **stable
surface to bind to, not a finished treatment**.

**Prototype reference, not precedent.** `prototypes/last-seal-vertical-slice/villager_ai.gd:659-711`
(reference only, **never imported**) used a `Node3D` root per villager with
`physics_interpolation_mode = OFF`, a capsule body + box head, position driven from `visual_position` each
frame, and `visible = current_cell.y <= _slice_level`. It had **no collider at all** — the prototype selected
villagers some other way, so it is *not* precedent for the hit-test question.

---

## Out of Scope

*Explicitly out of scope per VB-2 — handled elsewhere / later, do not implement here:*

- **Art-bible-faithful geometry** — limb blocks, the 45:55 head weight as a finished form, profession gold
  trim, §5.3 individuation palette, §5.6 behavioral tells. That is Art Bible §5.2/§5.3/§5.6 work and belongs
  to an art-production story.
- **The outline/hover *shader*** — `villager-info-ui-006`.
- **The distress billboard itself** — `villager-info-ui-005`; this story provides only the anchor.
- **The Slice View clip-plane mechanism for world geometry** — `building-ui-016`, still undecided. This story
  un-vacuates 016's "characters" clause only; it does **not** resolve 016's *other* blocker (the shared voxel
  material's clip-plane uniform vs. per-chunk re-mesh), which is a separate technical-director +
  `godot-shader-specialist` decision.
- **Villager names** — a tone call, sprint-09 D5, creative-director.
- **Animation of any kind.**

---

## QA Test Cases

- **AC-ACCESSOR**: Given a villager mid-transit, When `_process` has run, Then `get_visual_position()`
  returns exactly the value `_visual_position` holds, and `VillagerAi` is still a `Node` (not `Node3D`). The
  whole pre-existing villager-ai suite runs with **zero test edits** — if any test needs editing, the
  accessor was not additive.
- **AC-MIRROR**: Given a mock `ai_source` returning a known `Vector3`, When a frame elapses, Then the view's
  `global_position` equals it exactly. And: grep `villager_body_view.gd` → zero `lerp(`.
- **AC-NIL-SAFE**: Given `ai_source == null`, When frames elapse, Then the view is inert — no crash, no
  error spam.
- **AC-PROXY**: Given a positioned view, Then its `VillagerHitProxy` has `collision_layer == 1`,
  `collision_mask == 0`, `monitoring == false`, and `villager_id` matching the view's.
- **AC-RAY-HIT / AC-RAY-TRAP**: Given a ray aimed at the view with `collision_mask = 1`,
  `collide_with_areas = true`, `collide_with_bodies = false`, Then it hits and resolves to the correct
  `villager_id`. Given the same ray with `collide_with_areas` left at its **default**, Then it misses — the
  manifest line 219 regression guard.
- **AC-HEIGHT**: Given the placeholder body, Then its mesh AABB spans exactly 2 cells.
- **AC-SLICE**: Given `get_current_cell().y > slice_level`, When `set_slice_level(y)` is called, Then
  `visible == false` **and** the proxy's `collision_layer == 0`. When the level is restored, Then both are
  restored. Edge case: a villager mid-lerp across the cutoff boundary must switch on the **discrete** cell —
  no flicker.
- **AC-NO-SELECTION**: Given the story diff, When grep, Then zero Selection API references anywhere in the
  presentation module's new files.
- **AC-ANCHOR**: Given a moving villager, Then `IconAnchor`'s world position tracks the body every frame at
  the top of the figure.
- **AC-HIGHLIGHT**: Given `set_highlight(HOVER)`, Then the mode is observable via a state getter. Treatment
  not asserted.
- **AC-PRESENTER**: Given a **mocked** roster provider with N entries, When `setup()` runs, Then exactly N
  views exist; When an entry is removed, Then its view is freed. No Autoload registered.
- **AC-PURE-MIRROR**: Given the story diff, When grep, Then zero mutating calls from `src/presentation/` into
  `VillagerAi`.
- **AC-INTEGRATION (needs real `villager-ai-021`)**: Given `starting_villager_count = N`, When `Valley.tscn`
  boots, Then exactly N visible bodies appear at the spawned villagers' positions, and tick results are
  byte-identical to a presenter-absent run.
- **Advisory**: the two screenshots (readable 2-block figure at settlement-camera distance; the same villager
  sliced away).

---

## Test Evidence

**Story Type**: Integration (with the bulk of the ACs exercisable as headless unit tests)
**Required evidence**:
- **Blocking (unit)**: `neues-spiel/tests/unit/presentation/villager_body_view_test.gd` — the accessor,
  pure-mirror, nil-safety, interpolation-mode, hit-proxy, ray-hit + ray-trap, body-height, slice, Selection
  grep, `IconAnchor`, highlight-seam, presenter-lifecycle and pure-mirror-grep assertions. VB-2 names the
  **directory** (`neues-spiel/tests/unit/presentation/`); the filename above follows the suite's
  `[system]_[feature]_test.gd` convention and is the implementer's to confirm.
- **Blocking (integration, gated on `villager-ai-021`)**:
  `neues-spiel/tests/integration/presentation_experience/` — the N-villagers-N-bodies + byte-identical-tick
  assertion. Directory follows this epic's landed integration convention
  (`loop_payoff_surface_test.gd` lives there); VB-2 does not name an integration path.
- **Advisory (Visual/Feel)**: `production/qa/evidence/` — the two screenshots. Art-director / creative-director
  sign-off applies to this epic's visual bar per the epic's Definition of Done.

**Status**: [ ] Not yet created

---

## Dependencies

- **Depends on**: **`villager-ai-021`** (starting-roster spawn) — **Complete/landed**. The dependency is
  **hard for the integration AC only.** 021 is what turns "one hard-wired `VillagerAi` node in `Valley.tscn`"
  into a spawned, enumerable roster with a lifecycle, and the presenter's create/free loop is written against
  exactly that; authoring before it would mean writing the presenter against a single hard-coded node and
  rewriting it a sprint later. **But not *blocked* by 021 for development** — the roster provider is
  duck-typed and nil-safe, so every unit AC is testable against a mock roster; only the end-to-end
  "N villagers spawn, N bodies appear, one despawns, one body frees" AC needs the real 021. Upstream of 021:
  `villager-ai-026`.
- **Sequencing**:
  ```
  villager-ai-026 → villager-ai-021 → presentation-003 → ┬→ villager-info-ui-002 → 005 → 006
                    (roster is plural)                    ├→ building-ui-016 (characters clause)
                                                          └→ presentation-001 Sub-B (idle behaviors)
  ```
  **Sprint fit (VB-2)**: not an S09 Must (nothing in S09 consumed it), but it is the cheapest thing that
  unblocks the largest number of S10/S11 stories. Recommended **S10, early, immediately after 021 lands** —
  which is where it is scheduled.
- **Unlocks**:
  - `villager-info-ui-002` / `005` / `006` — all three blocked on it outright (hit query, icon anchor,
    hover/outline).
  - `building-ui-016` — the **"characters" half** of the cutoff only. 016's shader/clip-plane blocker is
    independent and still open.
  - `presentation-001` **Sub-B** (villager idle behaviors) — *invisible without this story*. **This re-orders
    within this epic**: Sub-B is currently deferred to S10/S11 per sprint-09 Cluster B, so the ordering costs
    nothing — but it is recorded here that Sub-B now has an **in-epic prerequisite it did not have before**
    (TD downstream action #16).
- **Related TD downstream actions** (`production/architecture-decisions-m02-preflight-2026-07-26.md`,
  addendum summary table): **#11** creates this story; **#12** ADR-0004 amendment naming `VillagerBodyView`
  as the `Area3D`'s host; **#13** ADR-0009 amendment adding the `get_visual_position()` accessor and
  re-scoping the `_visual_position` grep guard; **#14** control-manifest update naming
  `VillagerBodyView`/`VillagerHitProxy` as the concrete host for the existing line-64/71/152 rules (they
  currently describe a node that does not exist). All three are **technical-director**-owned doc tasks, none
  of which this story performs.

- **Open decisions this story surfaces (producer → user)**:

  1. ⚑ **The `_visual_position` grep guard named in TD downstream action #13 does not exist as a landed
     test — and this story has no AC that contradicts it.** The producer cross-checked the suite before
     authoring, as instructed. Findings:
     - **What is landed**: the only grep-style guards over `res://src/villager_ai` are in
       `neues-spiel/tests/integration/villager_ai/config_and_scaffold_test.gd`, which concatenates that
       directory's `.gd` files with full-line comments stripped and asserts exactly four things — no
       `func _physics_process(`; `func _process(_delta` **is** present; no
       `NavigationServer3D`/`NavigationAgent3D`/`NavigationRegion3D`; no `WorkerThreadPool`/`Thread`. **None
       of them mentions `_visual_position`.** Every other `_visual_position` occurrence in
       `neues-spiel/tests/` is either a doc comment or a direct field read inside a villager-ai test
       (`deterministic_position_test.gd`, `unstuck_watchdog_test.gd`, `traveling_repath_test.gd`).
     - **Where the guard actually lives**: as *prose only* — ADR-0009's Validation Criteria ("Grep-verifiable:
       `_visual_position` (or equivalent) is never referenced outside the movement/rendering code path"),
       `docs/architecture/control-manifest.md`, and `villager-ai-004`'s own "Forbidden" line (echoed as a doc
       comment in `src/villager_ai/villager_rescue_target_search.gd:64`).
     - **Consequence**: nothing in CI will "trip" when `src/presentation/` reads the visual position, because
       nothing enforces the invariant mechanically today. VB-2's AC list contains **no** `_visual_position`
       grep AC at all — its three grep ACs are (a) zero `lerp(` in `villager_body_view.gd`, (b) zero
       Selection references, (c) zero mutating calls into `VillagerAi`, and **none of them contradicts any
       landed guard or depends on action #13's re-scope**. So the blocker note recorded in
       `sprint-status.yaml` ("without that re-scope this story's own grep AC contradicts a landed guard") is
       **not borne out**: there is no such AC, and there is no such landed guard.
     - **What is genuinely open, for the user/TD**: the substantive invariant ADR-0009 protects is real and
       should stay enforced. Does **this story** own writing the re-scoped guard as an actual test (a
       call-site allowlist over `villager_ai.gd::_process` + `src/presentation/`, so that a *fourth* module
       reading the visual position fails CI), or does TD action #13 remain a documentation-only amendment and
       the invariant stay unenforced-by-test? **The producer has deliberately not written that AC** — it is
       not in VB-2, and inventing it would exceed the transcription mandate. If the answer is "this story
       owns it", it is a small addition to the blocking AC list and roughly +0.1 agent-day.

  2. ⚑ **Two paths not named by the spec** (flagged, not invented): the blocking-unit-test *filename* and the
     *integration-test directory*. VB-2 names only the unit **directory**
     (`neues-spiel/tests/unit/presentation/`). Both proposals above follow existing suite convention and are
     the implementer's to confirm at `/story-readiness`.


### Parent ruling on Open Decision #1 (2026-07-26, away-mode, provisional)

**This story owns writing the guard.** The producer's cross-check found that the
`_visual_position` single-source-of-truth invariant exists only as prose (ADR-0009's
validation criteria, the control manifest, and a doc comment) — no test enforces it
anywhere in the suite. An architectural invariant nothing checks is not an invariant.

Add one blocking AC: a call-site allowlist guard over `res://src/` asserting that
`_visual_position` is read only from within `src/villager_ai/` plus the single sanctioned
presentation accessor introduced here (`VillagerAi.get_visual_position`). It must be a
call-site allowlist, not a filename check, precisely so this story's own legitimate
presentation-tier read passes while an unsanctioned second reader fails. Cost was
estimated at ~0.1 agent-day.

Rationale for doing it here rather than later: this is the first story that legitimately
reads the visual layer from outside villager_ai, so it is the first moment the invariant
can be stated precisely instead of vaguely — and the moment it is most likely to be
quietly broken by whatever comes next.
