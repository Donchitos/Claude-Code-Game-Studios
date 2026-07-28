# Story 007: Build-tool & project-lifecycle hosting in the Valley scene — the player can actually build

> **Epic**: Scene / World Management
> **Status: Complete (2026-07-27 — 1461/1461 suite green 0 orphans, parent-verified; Sprint 11 gate G2 — the shipped game now hosts the whole build chain)
> **Layer**: Foundation (boot sequencing / scene topology) → drives Core (Building System interaction tier)
> **Type**: Integration
> **Estimate**: **2.0 days** *(relative-complexity anchor, not a calendar prediction — sprint-09.md sizing convention)*. ⚑ **The sprint plan anchored this at 1.0; authoring raised it to 2.0 — that discovery is exactly what gate G2 exists for.** See **Sizing and the descope ladder** below; the ladder is pre-declared so a mid-sprint trim is a choice, not an accident.
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-27

## Context

**The gap this closes (verified on disk 2026-07-27, by reading `Valley.tscn`'s node list and `src/` — not a table):**

`Valley.tscn` hosts 14 child nodes and `Valley.get_injected_tier_modules()` reports **12** modules
(`VoxelWorldGrid`, `VoxelWorldMesher`, `VoxelWorldMeshStreamer`, `CameraInput`, `ToolStateMachine`,
`PlacementPick`, `CommitPipeline`, `ConstructionTickLoop`, `NeedsMood`, `VillagerAi`, `TorchFlicker`,
`VillagerBodyPresenter`). Not one of the following is in any scene or constructed anywhere in `src/`:

| Module | Kind | State on disk |
|---|---|---|
| `BuildEditorMode` | `Node` | in no scene; `tool_state_machine` unwired |
| `WallTool` / `FloorTool` / `RoofTool` / `BlockTool` | `Node` | in no scene; **no `set_cell_set_resolver` call anywhere in `src/`** |
| `FurnitureTool` | `Node` | in no scene; **no `set_furniture_support_predicate` call anywhere in `src/`** |
| `GhostPreview` | `Node` | in no scene; nothing is connected to `CommitPipeline.blueprint_cells_created` |
| `UndoRedoStack` | `Node` | in no scene; **`record_command()` is called from nowhere in `src/`** |
| `BuildProjectRegistry` | `RefCounted` | **constructed nowhere in `src/`** — `assign_cells()` has zero production callers |
| `ConstructionJobQueue` | `RefCounted` | **constructed nowhere in `src/`** — `VillagerAi.job_queue` is never assigned |
| `PlanOnlyUndoGate` | `RefCounted` | **constructed nowhere in `src/`** |

**Consequence, stated without softening: in the running game the player cannot build anything.**
`CommitPipeline` is hosted and green, but its cell-set resolver is the deliberately-labelled
`_default_cell_set` placeholder (a click commits one cell; a drag commits press + release, nothing
in between) — so even the geometry a commit produces is the placeholder's, not any tool's F1/F2/F5
formula. The blueprint cells that commit does create are tracked only inside `CommitPipeline` and
belong to **no project**, because nothing listens to `blueprint_cells_created`. No project means no
job; no job means `VillagerAi.job_queue` (unassigned) has nothing to offer anyway.

building-ui's **Known Conflict 3** recorded this on 2026-07-26. It is **still true after
`building-001` (build/editor mode) landed on top of it** — `BuildEditorMode` shipped green, fully
tested, and joined the list of things in no scene.

### ⚑ The fourth ship-green-and-uncalled — and the first that is a whole subsystem

`scene-006` recorded the running tally. This is entry #4, and it is a different order of magnitude:

| # | API | Shipped by | Found by | Fixed by |
|---|---|---|---|---|
| 1 | `VoxelWorldGrid.generate_terrain()` | vox-006 | the Valley booting an empty grid, S9 | `scene-005` |
| 2 | `Valley.spawn_starting_roster()` | villager-ai-021 | the Valley booting with zero villagers, S9 | `scene-005` |
| 3 | `NeedsMood.initialize_villager()` | needs-mood-006 | `scene-006` | `scene-006` |
| 4 | **the entire build-interaction tier** (8 `Node`s + 3 `RefCounted`s) | building-001/011/016/021–033 | building-ui KC3, 2026-07-26 | **this story** |

`scene-006` also predicted where the next one would land: *"[the boot-invariant block] covers boot,
not mid-session. Mid-session dead code stays a review responsibility."* That is precisely where this
one lives. The build tier is not reachable from any boot assertion — it is only reachable from a
player's mouse, and no test in this repo drives a player's mouse through a **hosted** pipeline.

The S10 sign-off's rule — *"a new production API needs a proven caller in the same sprint"* — is
what produced this story. It is also why this story's ACs are shaped the way they are: **an
assertion that a node exists proves nothing here.** Every module in the table above already exists,
is already green, and has been for sprints.

### ⚑ This story answers the SAME question as sprint-11's open decision D9 and the TD's HUD-hosting ruling

D9 asks whether the hosting story gets scheduled. building-ui **Known Conflict 1** (no `src/ui/`, no
Control anywhere, `Valley.tscn` hosts no HUD) and **Known Conflict 3** (this story's list) are the
same architectural question asked twice: **which scene owns a node that is neither a world object
nor a config Resource — the Valley, or `GameWorld`?** `building-ui-001` (HUD host scaffold) is
blocked on the technical-director's answer for the HUD tier; this story answers it for the tool
tier. **Decide once, apply twice.** This story therefore records its own answer explicitly (see
AC-HOSTED-BEFORE-ACTIVE's rationale and Open Decision 1) so `building-ui-001` inherits a precedent
rather than re-litigating it — and it is deliberately sequenced *before* `building-ui-001` in the
sprint for that reason.

**GDD**: `design/gdd/scene-world-management.md` (Booting state / boot orchestration) +
`design/gdd/building-system.md` (Build Mode state machine Rule 8a–8d; F1/F2/F5 tool cell sets;
Core Rules 11/14/17)
**Requirement**:
- `TR-scene-world-management-004` / `-034` — boot gate: Valley attaches after RID Ready, all
  injected-tier initialization completes before ACTIVE.
- `TR-scene-world-management-035` / `-036` — the Valley is the structural parent every
  Foundation/Core system needing a session-lifetime root attaches under. **The build tier is such a
  system and has never been attached.**
- `TR-building-system-044` / `-077` — F1's wall cell set is produced *in one action*. **`WallTool`
  satisfied this in the module; this story is the only place it can be satisfied in the shipped
  game.**
- `TR-building-system-052` — a valid commit creates blueprint cells.
- `TR-building-system-102` / `-103` — cell → owning-project reverse index (needs a live registry).
- `TR-building-system-102`–`-105` — Build Mode Off/On gate (needs a live `BuildEditorMode`).
- `TR-building-system-089` — bounded undo depth (needs a live `UndoRedoStack`).

*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time.)*

**ADR Governing Implementation**: **ADR-0005** (Boot Sequencing & Initialization Gate) — primary;
**ADR-0001** (Inter-System Reference & DI) — primary; **ADR-0016** (Build-Project Entity Lifecycle) —
primary for *what* the registry/queue tier must be wired into; **ADR-0010** (Cross-System UI/World
Input Arbitration) — secondary; **ADR-0002** (config-driven tunables) — secondary.

**ADR Decision Summary**: ADR-0005 makes `GameWorld._on_database_settled()` the single ordering
authority — Valley attaches, `_gather_valley_tier_modules()` collects the list, `_setup_injected_tier()`
sweeps every module's `setup()` in array order, `_run_world_genesis()` runs, then ACTIVE. ADR-0001
splits Autoload-tier from injected-tier and puts *all* wiring in `setup()`, never `_ready()`.
CONTRACTS.md §1 states the invariant this story must not break: **"the sole `module.setup()` call
site in `src/` is `GameWorld._setup_injected_tier()`."** ADR-0016 Decision §1 names Building System
as the project entity's sole owner, §2 the 26-neighborhood grouping/merge on commit, §5 plan-only
undo. This story authors **no** lifecycle logic — it constructs the owners and connects the seams
each landed module's own doc comment already names as *"a future scene-assembly story's job"*
(that phrase appears verbatim in `wall_tool.gd`, `furniture_tool.gd`, `ghost_preview.gd`,
`undo_redo_stack.gd`, `build_editor_mode.gd` and `tool_state_machine.gd`).

**Engine**: Godot 4.7-stable | **Risk**: **MEDIUM** — no new algorithm and no post-cutoff API is
expected, but this is the largest single change to the boot module list the project has made, it
moves two count assertions, and the failure mode of getting a `setup()` order wrong is a boot-time
assert rather than a red unit test.

**Control Manifest Rules (this layer — boot sequencing / scene topology):**
- **Required**: every newly hosted `Node` is reported through `Valley.get_injected_tier_modules()`
  and receives its `setup()` from `GameWorld._setup_injected_tier()` — **hosting is not DI**;
  Node-typed cross-references between hosted siblings are code-assigned in
  `Valley._wire_hosted_modules()` (the established precedent — a hand-authored `.tscn` cannot
  resolve a `NodePath` literal into a Node-typed `@export`, verified against the running engine and
  recorded in `valley.gd`'s class doc); each module's own config `Resource` is Inspector-wired on
  `Valley.tscn` from the already-existing `.tres` (`wall_tool_config.tres`, `ghost_preview_config.tres`,
  `undo_redo_stack_config.tres` all exist); `RefCounted` collaborators are constructed in a
  `Valley` wiring method on the `_wire_villager_population()` precedent (which already constructs
  `VillagerDecidingScheduler`/`VillagerNavGraph`/`VillagerUnstuckTelemetry` this way).
- **Forbidden**: a second `setup()` call site (ADR-0005 / CONTRACTS.md §1 — `spawn_starting_roster`'s
  on-demand call is villager-ai-021's already-sanctioned exception, **not** a licence for a new one);
  calling any hosted child's `setup()` from `valley.gd`; writing to a config `Resource` field at
  runtime (CONTRACTS.md §2 — this is building-ui **KC2**, `wall_height`'s runtime holder, and it is
  **not** this story's to solve); reaching into any private member of a hosted module;
  reimplementing any tool formula, grouping rule, or lifecycle transition here; adding a
  `_process`/`_physics_process` path to `valley.gd` beyond the one vox-018/scene-005 already own.
- **Guardrail**: **an acceptance assertion that passes on today's build is not an assertion.** Every
  AC below must fail if the wiring it covers is removed. See AC-PROBE-IS-NON-VACUOUS — and note the
  trap this story's own shape sets: *every module named here already exists and is already green*,
  so "the node is in the scene" and "the getter returns non-null" are exactly the vacuous shapes to
  avoid.

---

## Sizing and the descope ladder (pre-declared, per the sprint's named lever)

The work is three separable sub-scopes. They are listed in **descending order of how much of this
story's own purpose they carry**, which is deliberately *not* the order the sprint plan's lever
assumed:

| Sub-scope | Contents | Anchor | Carries |
|---|---|---|---|
| **A — the tool tier** | `BuildEditorMode`, the five tools, `GhostPreview`, the armed-tool → resolver router | 0.75 | The player can *aim* and see a real ghost; `rid-009`'s bed becomes selectable |
| **B — the project-lifecycle tier** | `BuildProjectRegistry`, `ConstructionJobQueue`, the `blueprint_cells_created → assign_cells → add_project` chain, `VillagerAi.job_queue` | 0.75 | **The C1 demolition chain's production caller.** Without it, `building-009/012/015/017/031` ship with none |
| **C — the undo tier** | `UndoRedoStack`, `PlanOnlyUndoGate`, the shared `BuildingSystemWriteTag`, `game_world` + `voxel_world_write_source` assignment, `record_command` on commit | 0.5 | Plan-only undo becomes reachable by a player (criterion #12's production half) |

⚑ **Producer finding — the sprint plan's named lever is pointed at the wrong sub-scope.**
sprint-11.md's buffer entry reads: *"host the tool tier only and defer `BuildProjectRegistry` /
`ConstructionJobQueue` / `UndoRedoStack` hosting to S12."* Verified against the C1 stories' own
files: `building-031`'s ACs are *"Planned→Canceled + job revoke"* (it reads the owning project's
cells and revokes a claim through the queue) and `building-009`'s are demolition **orders** —
worker-executed **jobs**. **Sub-scope B is the C1 chain's caller.** Cutting B while keeping A would
leave the five demolition stories exactly as uncalled as they are today, which is the one outcome
this story exists to prevent.

**Recommended ladder if a trim is needed** (decide on signal, not by default):
1. **Cut Sub-scope C** → 1.5 days. Named debt: *"plan-only undo is unreachable by a player; a
   `UndoRedoStack` hosting follow-on is owed in S12."* Record it in the commit body and in the epic.
2. **Cut C and A's `GhostPreview` only** → 1.25 days. Named debt: no live ghost; the player commits
   blind. Ugly but honest, and it does not re-orphan anything.
3. **Never** cut Sub-scope B. If B cannot land, this story has not closed the fourth occurrence and
   should be reported as such rather than closed green.

---

## Acceptance Criteria

- [ ] **AC-HOSTED-BEFORE-ACTIVE**: At the instant `GameWorld`'s boot state first reads
      `BootState.ACTIVE`, every module in Sub-scopes A and B (and C, if it lands) is present, has had
      `setup()` called exactly once by `GameWorld._setup_injected_tier()`, and reports
      `is_set_up() == true` where it exposes that predicate. Each `Node` is reached through a new
      `Valley` getter on the established `get_*()` naming precedent; each `RefCounted` is reached the
      same way. `setup()` order is such that no module's `setup()` runs before a module it holds a
      reference to — in particular `GhostPreview` after `ToolStateMachine`/`PlacementPick`/
      `CommitPipeline`, and `FurnitureTool` after `CommitPipeline`. A boot that HALTs (RID `Failed`,
      or a BLOCKING config invariant) never reaches any of this — existing halt semantics unchanged
      and still terminal. ⚑ **This AC alone is close to vacuous and is not allowed to stand alone** —
      it exists to pin ordering and the halt path; the ACs below are what prove the wiring does
      something. [ADR-0005, ADR-0001, TR-scene-world-management-004]
- [ ] **AC-TOOL-RESOLVER-IS-LIVE** ⚑ *primary non-vacuity lever*: with the hosted `BuildEditorMode`
      armed to the wall tool, **a single click** committed through the hosted `PlacementPick` →
      `CommitPipeline` path produces exactly **`WallToolConfig.wall_height`** blueprint cells forming
      one vertical column anchored at the picked cell — read from the config, **never a literal**.
      The shipped `wall_tool_config.tres` carries `wall_height = 3`; `CommitPipeline`'s unwired
      `_default_cell_set` placeholder produces **1** cell for a click. **The assertion therefore
      discriminates wired from unwired by construction**, and the test config must keep
      `wall_height > 1` or the AC is void. Re-arming to the block tool and clicking again produces
      that tool's own cell set, proving the router re-points on `tool_armed` rather than latching the
      first tool. [TR-building-system-044/-077, ADR-0016]
- [ ] **AC-COMMIT-REACHES-THE-REGISTRY**: after that same commit, **every** cell it produced is owned
      by exactly one project in the **hosted** `BuildProjectRegistry` —
      `registry.project_at_cell(cell) != -1` for each, all returning the **same** id, and
      `registry.get_projects().size()` grew by exactly 1. A second commit adjacent to the first
      merges into the same project (ADR-0016 §2's 26-neighborhood rule, driven — not reimplemented);
      a second commit far away creates a second project. **Without the
      `blueprint_cells_created → assign_cells` connection every one of these reads `-1` / `0`.**
      [TR-building-system-102/-103, ADR-0016 §2]
- [ ] **AC-RELEASED-PROJECT-REACHES-THE-JOB-QUEUE**: releasing that project through the landed
      `BuildProjectRegistry.release_project(project_id)` makes the hosted `ConstructionJobQueue`
      report its cells: `has_available_job()` becomes `true` and `get_available_jobs()` contains the
      committed cells. The hosted `VillagerAi.job_queue` is the **same instance** the registry feeds,
      so the villager's own duck-typed `_has_available_job()` path sees it too. Before release the
      queue reports nothing (Draft is not BUILDING-eligible — drive the landed state machine, do not
      assert a state name this story invents). ⚑ **This is the assertion that makes the C1 demolition
      chain called rather than merely green.** [ADR-0016 §3, TR-villager-ai-behavior-054]
- [ ] **AC-GHOST-MIRRORS-THE-ARMED-TOOL**: with a tool armed and a valid pick, the hosted
      `GhostPreview` reports `is_live_preview_visible() == true` and
      `get_live_preview_cells().size()` equal to the **armed tool's** cell count (i.e. `wall_height`
      for the wall tool, not 1) — the same discriminator as AC-TOOL-RESOLVER-IS-LIVE, observed one
      layer up. Cancelling (Esc through the hosted `BuildEditorMode.handle_escape()`) hides it.
      Assert through `GhostPreview`'s own read-only observability accessors, **never** by counting
      `MeshInstance3D` children or sampling pixels. Reuse
      `tests/integration/scene_world/gameworld_e2e_loop_test.gd`'s established analytic-yaw
      `SubViewport` camera rig rather than inventing a second one.
- [ ] **AC-BUILD-MODE-IS-THE-ONLY-ARMING-PATH**: `build_editor_mode.gd`'s class doc states its Rule
      8a/8d guarantee holds *"provided every future caller arms tools exclusively through this class
      rather than `tool_state_machine` directly (a documented contract, not a compiler-enforced
      one)"*. **This story is the first code that could violate it.** Grep-guarded by test on the
      established non-writer-guard precedent: zero `arm_tool(` call sites in `neues-spiel/src/`
      outside `build_editor_mode.gd`'s own body. Behaviourally: from a fresh boot,
      `BuildEditorMode.get_mode()` is `OFF` and `ToolStateMachine.get_state()` is `IDLE`; a click
      through the hosted pick commits **nothing**; after `arm_tool(&"wall")` the identical click
      commits. [TR-building-system-102/-105, ADR-0010]
- [ ] **AC-UNDO-IS-PLAN-ONLY-THROUGH-THE-HOSTED-STACK** *(Sub-scope C — drop this AC with the
      sub-scope, and record the debt if you do)*: a commit through the hosted pipeline records
      exactly **one** undo command (`get_undo_stack_size()` grows by 1 for a whole wall drag — Core
      Rule 17's *"one wall drag = one command = one undo step"*, so the count must be **1**, not
      `wall_height`); `undo()` through the hosted stack returns those cells to unowned
      (`project_at_cell` reads `-1`) via the hosted `PlanOnlyUndoGate`; and a cell driven to
      `MicroState.BUILT` is **never** mutated by `undo()` (ADR-0016 §5, `TR-building-system-088`).
      The `BuildingSystemWriteTag` instance shared with `ConstructionTickLoop` is the **same object**
      — otherwise the tick loop's own completion write registers as external and silently
      invalidates the player's undo history. [TR-building-system-088/-089, ADR-0016 §5]
- [ ] **AC-HOSTING-IS-NOT-DI**: `valley.gd` calls **no** hosted child's `setup()` — grep-guarded by
      test, extending the existing precedent: the only `\.setup()` call sites in `neues-spiel/src/`
      remain `GameWorld._setup_injected_tier()` and `Valley.spawn_starting_roster()`'s
      already-sanctioned per-villager exception. No new exception is introduced. `Valley` reports the
      list; `GameWorld` calls `setup()`. [CONTRACTS.md §1, ADR-0005]
- [ ] **AC-PROBE-IS-NON-VACUOUS** ⚑ *the `scene-006` discipline, restated*: the test proving
      AC-TOOL-RESOLVER-IS-LIVE **and** the test proving AC-COMMIT-REACHES-THE-REGISTRY each **fail
      when their wiring line is removed**, and this is **demonstrated, not asserted** — two deliberate
      removal runs, each re-run in isolation, with the observed failure output recorded in the commit
      body, then restored verbatim and re-run green (`git diff` clean). The two removals are:
      (a) the `commit_pipeline.set_cell_set_resolver(...)` wiring — expected failure: the click
      produces 1 cell instead of `wall_height`; (b) the `blueprint_cells_created` → registry
      connection — expected failure: `project_at_cell` reads `-1`. ⚑ **Vacuous shapes explicitly
      banned here, because every module in this story already exists and is already green**:
      `assert(valley.get_wall_tool() != null)`, `assert_int(valley.get_child_count()).is_equal(22)`
      as the *only* evidence, `assert(registry != null)`, and any assertion whose expected value does
      not change when the wiring is deleted.
- [ ] **AC-COUNT-ASSERTIONS-UPDATED-NOT-LOOSENED**: the two landed count assertions this story moves
      —`tests/integration/scene_world_management/world_root_valley_attach_test.gd`'s
      `assert_int(valley.get_child_count()).is_equal(14)` (line ~196) and
      `tests/integration/scene_world/gameworld_e2e_loop_test.gd`'s
      `assert_int(world.injected_tier_modules.size()).is_equal(12)` (line ~131) — are **updated to
      the new exact values with the delta explained in the adjacent comment block** (both files
      already carry a running "11 → 12 → 13" style comment history; continue it). **Neither may be
      deleted, commented out, or relaxed to a `>=`/`is_greater` form.** Their whole value is that
      they fail loudly when the hosted set changes silently — which is the class of change this
      story is.
- [ ] **AC-SUITE-GREEN-AND-DIAGNOSED**: the full blocking suite is green headless with 0 orphans at
      the story's close. Any pre-existing test that must change to accommodate correct production
      behaviour is **named individually in the commit body with the reason** — a test that changes
      because the game now does something it previously did not is legitimate; a test that changes
      because it was asserting the absence of this wiring must be called out by name. ⚑ **Lane C
      hygiene (S10 §5 process finding): this story lands fifth on a serial lane in one working tree.
      A red run must be re-run in isolation (clean stash or separate branch) before any change is
      reverted on its basis.**

---

## Implementation Notes

*Derived from ADR-0005 (the one boot orchestration site), ADR-0001 + CONTRACTS.md §1 (hosting vs DI),
ADR-0016 (what the lifecycle tier connects to), and the landed code read on 2026-07-27:*

- **Where each piece goes.** The eight `Node`s become children of `Valley.tscn` with their config
  `.tres` Inspector-wired (all three needed configs already exist: `wall_tool_config.tres`,
  `ghost_preview_config.tres`, `undo_redo_stack_config.tres`; `FloorTool`/`RoofTool`/`BlockTool`/
  `FurnitureTool`/`BuildEditorMode` declare no config at all — verified). Node-typed
  cross-references (`BuildEditorMode.tool_state_machine`, `FurnitureTool.voxel_world`/
  `commit_pipeline`, `GhostPreview.tool_state_machine`/`placement_pick`/`commit_pipeline`) are
  code-assigned in `Valley._wire_hosted_modules()`, exactly like the twelve assignments already
  there. The three `RefCounted`s are constructed in a `Valley` wiring method on
  `_wire_villager_population()`'s precedent.
- **The armed-tool → resolver router is the one genuinely new piece of code, and it is small.**
  `CommitPipeline.set_cell_set_resolver()` takes **one** `Callable`; there are five tools. The
  natural shape is a `StringName → Callable` map consulted from a `ToolStateMachine.tool_armed`
  handler on `Valley`, re-pointing the resolver on each arm. ⚑ **Tool-id strings are a convention,
  not a landed constant set** — `&"wall"`, `&"floor"`, `&"roof"`, `&"block"` appear only in tests
  (`gameworld_e2e_loop_test.gd`, `block_tool_test.gd`, `build_editor_mode_test.gd`,
  `commit_pipeline_test.gd`); there is no furniture id anywhere and no `const` for any of them. See
  Open Decision 2 — **do not silently invent a fifth id and bury it in `valley.gd`**.
- **`FurnitureTool` needs its second seam too.** `commit_pipeline.set_furniture_support_predicate(furniture_tool.is_cell_supported)`
  — `furniture_tool.gd`'s own doc comment names this wiring as the future scene-assembly story's job,
  and without it Rule 8's support check is permissive-by-default in production.
- **Correction to the sprint plan's wording, recorded rather than absorbed.** sprint-11.md says the
  registry and queue *"are handed to the already-hosted `ConstructionTickLoop`"*. On disk it is the
  reverse: `ConstructionJobQueue._init(p_tick_loop: ConstructionTickLoop)` **takes** the tick loop,
  and `ConstructionTickLoop` has *"zero `ConstructionJobQueue` awareness"* by its own documented
  invariant. Construct the queue **with** the hosted tick loop; do not add a queue reference to the
  tick loop.
- **`PlanOnlyUndoGate` wires itself.** Its `_init(undo_redo_stack, registry, voxel_world, job_queue = null, tick_loop = null)`
  calls `set_cancel_cell_callable`/`set_recreate_cell_callable` on construction. Pass all five —
  `job_queue`/`tick_loop` default to `null` and a `null` there silently degrades claim revocation.
- **`game_world` back-references.** `ToolStateMachine.game_world` and `UndoRedoStack.game_world` are
  both nullable `@export`s that no-op when unwired — **and `ToolStateMachine.game_world` is `null` in
  production today**, so the transition-suspend contract is already inert. Assigning both (the Valley
  can reach `GameWorld` through the parent it was attached to, or `GameWorld` can assign them in
  `_gather_valley_tier_modules()` — implementer's call, state which in the commit body) is in scope
  and fixes a pre-existing silent gap. If you choose not to, say so explicitly rather than leaving it
  unmentioned.
- **⚑ Two count assertions move significantly, and one of them is load-bearing for other stories.**
  `world_root_valley_attach_test.gd:~196` asserts `valley.get_child_count() == 14`; hosting Sub-scopes
  A + C adds 8 `Node`s → **22**, plus **one more** if `building-031` lands a `RemovalTool` node
  (sequence after it — the sprint schedules this story last on lane C for exactly that reason).
  `gameworld_e2e_loop_test.gd:~131` asserts `injected_tier_modules.size() == 12` → **20** (+1).
  Update both to the exact realised numbers with a comment explaining the delta; see
  AC-COUNT-ASSERTIONS-UPDATED-NOT-LOOSENED for why neither may be loosened.
- **`GhostPreview extends Node`, not `Node3D`, and parents `MeshInstance3D` children with local
  `.position`.** That is this codebase's established convention (`PlacementPick._update_highlight()`
  does the same and is already hosted under `Valley`, a `Node3D` at the origin) — so hosting it as a
  plain child is correct and needs no transform work. Do not "fix" it to a `Node3D`.
- **`setup()` ordering is load-bearing and enforced by asserts, not by tests.** `GhostPreview.setup()`
  asserts four wired dependencies and immediately reflects `tool_state_machine.is_ghost_visible()`;
  `FurnitureTool.setup()` asserts two; `BuildEditorMode.setup()` asserts one. A wrong position in
  `get_injected_tier_modules()`'s returned array produces a boot-time assert, not a red unit test —
  place dependents after their dependencies.
- Cross-reference `docs/engine-reference/godot/` before touching any engine API (**BLOCKING**, as in
  M01, S09, S10). Scene hosting is a post-cutoff-change domain (4.7's dedicated MeshLibrary/GridMap
  editor work touched scene tooling); this story is expected to use no new engine API at all, and
  any that appears must be verified against the reference before use.

---

## Out of Scope

*Handled elsewhere, or surfaced as missing — do not implement here:*

- **Any tool formula, grouping rule, lifecycle transition or validation.** `WallTool`'s F1,
  `BuildProjectRegistry`'s 26-neighborhood merge, `CommitPipeline`'s four validity gates,
  `PlanOnlyUndoGate`'s plan-only invariant — all landed, all green. This story **drives** them. If
  any of them needs a change to be wireable, that is a finding to record and escalate, not a fix to
  make here.
- **The HUD / any `Control` node** (building-ui **KC1**). `src/ui/` does not exist. `building-ui-001`
  owns the HUD host and is blocked on the technical-director's KC1/KC3 ruling — the same ruling this
  story's precedent informs. **This story adds no UI.** A player still needs a keyboard/test harness
  to arm a tool; making arming clickable is `building-ui-003`/`004`.
- **The runtime `wall_height` stepper** (building-ui **KC2**). `wall_height` is an `@export` on a
  config `Resource` and CONTRACTS.md §2 forbids runtime writes to config fields. A runtime holder on
  `WallTool` is owed by technical-director + building-system. **This story reads the config value; it
  must not write it.**
- **`BuildProject`'s missing lifecycle surface** (building-ui **KC4**): no Demolishing state, no
  `pause_project`, no `queue_demolition`, no `name` field, no `built_cells`/`total_cells` accessors.
  Owned by `building-006` (C3) and `building-010` (C4), both on the cut lever. Hosting the registry
  does **not** create them, and this story must not stub them.
- **The pick-solid ghost predicate** (building-ui **KC5**): `PlacementPick.set_extra_solid()` is a
  live seam with no data model behind it (no dig-order cell class, no water cell type). Leave it
  unwired — wiring an invented predicate is exactly the "drive it from a fake signal" move
  `valley.gd`'s own honest scope note refuses for `ChimneySmokeEmitter`.
- **`FurnitureRegistry` construction and the furniture view.** ⚑ **Found while reading, recorded not
  absorbed**: `FurnitureRegistry` is *also* constructed nowhere in `src/`, so
  `ConstructionTickLoop.furniture_registry` and `FurnitureBedProvider.furniture_registry` are both
  `null` in production — a completed furniture cell registers nothing, and `VillagerAi.bed_provider`
  is never assigned either. That is the same defect class as this story's, one layer further in, and
  it is the *other* half of sprint-11's **F7** (no furniture view). **Whether it belongs in this
  story is Open Decision 3.** Do not silently pull it in, and do not silently leave it unnamed.
- **Multi-cell furniture REDO atomicity** (S10 sign-off §4.2) — no story, named trigger is a second
  multi-cell item. Untouched.
- **Save/load of any of this** (ADR-0012, VS-tier) — the undo/redo stack is explicitly excluded from
  save (ADR-0016 §7).

---

## QA Test Cases

- **AC-HOSTED-BEFORE-ACTIVE**: Given a headless boot of the real `GameWorld` with a
  `MockResourceItemDatabase` configured ready-immediately, When boot state first reads `ACTIVE`, Then
  every new `Valley` getter returns a non-null instance and each exposing `is_set_up()` returns
  `true`. Given a RID `Failed` outcome, Then no `setup()` ran and the halt stays terminal.
- **AC-TOOL-RESOLVER-IS-LIVE**: Given a booted world with `wall_height = 3`, When the wall tool is
  armed through `BuildEditorMode` and one click is committed through the hosted pick, Then exactly 3
  blueprint cells exist, forming a column at the picked cell. When the block tool is armed and the
  same click repeats, Then that tool's own cell set results. **Negative control (run once by hand,
  recorded in the commit body):** with `set_cell_set_resolver` removed, the same test FAILS with 1
  cell.
- **AC-COMMIT-REACHES-THE-REGISTRY**: Given that commit, Then all its cells share one non-`-1`
  project id and `get_projects().size()` grew by 1. Given a second adjacent commit, Then it merges
  into the same id. Given a distant commit, Then a second project exists. **Negative control:** with
  the `blueprint_cells_created` connection removed, `project_at_cell` reads `-1`.
- **AC-RELEASED-PROJECT-REACHES-THE-JOB-QUEUE**: Given a committed, unreleased project, Then
  `has_available_job()` is `false`. When `release_project(id)` runs, Then `get_available_jobs()`
  contains the committed cells and the hosted `VillagerAi.job_queue` is the same instance.
- **AC-GHOST-MIRRORS-THE-ARMED-TOOL**: Given a booted world with a valid pick and the wall tool
  armed, Then `is_live_preview_visible()` is `true` and `get_live_preview_cells().size() == 3`. When
  `handle_escape()` runs, Then the preview is hidden.
- **AC-BUILD-MODE-IS-THE-ONLY-ARMING-PATH**: Given the source tree, When `neues-spiel/src/` is
  scanned for `arm_tool(` call sites, Then only `build_editor_mode.gd`'s own is found. Given a fresh
  boot, Then mode is `OFF` and a click commits nothing; after arming, the same click commits.
- **AC-UNDO-IS-PLAN-ONLY-THROUGH-THE-HOSTED-STACK**: Given a wall drag committed through the hosted
  pipeline, Then `get_undo_stack_size() == 1`. When `undo()` runs, Then every cell reads
  `project_at_cell == -1`. Given a cell driven to `BUILT`, When `undo()` runs, Then that cell is
  unchanged.
- **AC-HOSTING-IS-NOT-DI**: Given the source tree, When `.setup()` call sites in `neues-spiel/src/`
  are enumerated, Then only `GameWorld._setup_injected_tier()` and
  `Valley.spawn_starting_roster()`'s per-villager call are found.
- **AC-COUNT-ASSERTIONS-UPDATED-NOT-LOOSENED**: Given both landed count assertions, Then each holds
  an exact integer matching the realised hosted set, with a comment recording the delta; neither uses
  an inequality.
- **AC-SUITE-GREEN-AND-DIAGNOSED**: Given the full headless suite (`tests/run-tests.cmd`), Then exit
  code 0 with 0 errors, 0 failures, 0 orphans.

---

## Test Evidence

**Story Type**: Integration (BLOCKING)
**Required evidence**:
- `neues-spiel/tests/integration/scene_world/build_tool_hosting_boot_test.gd` — a **new** file on
  `scene-006`'s precedent (`villager_need_seeding_boot_test.gd` was created new rather than extending
  `world_genesis_boot_test.gd`, because that file bundles one expensive real production boot into a
  single test). This story's AC cluster is at least as independent; state which choice was made and
  why in the commit body.
- Grep-guard tests for AC-BUILD-MODE-IS-THE-ONLY-ARMING-PATH and AC-HOSTING-IS-NOT-DI, on the
  established non-writer/literal-guard precedent (`building-023`, `build-validation-002`, and
  `shelter_recovery_live_pair_test.gd`'s `_find_files_assigning` helper — reuse it, it already
  generalises).
- Updates to `tests/integration/scene_world_management/world_root_valley_attach_test.gd` and
  `tests/integration/scene_world/gameworld_e2e_loop_test.gd` count assertions.
- **The two AC-PROBE-IS-NON-VACUOUS negative-control results, recorded in the commit body** — not a
  separate artifact. `scene-006`'s entry is the format to copy: name the removed line, quote the
  observed failure (test name, counts, exit code), confirm the restore was verbatim, confirm the
  re-run was green.

**Status**: [ ] Not yet created

---

## Dependencies

- **Depends on** (all Complete unless noted): `scene-004` (the `GameWorld` assembly seam +
  `get_injected_tier_modules()`), **`scene-005`** (the `_run_world_genesis()` boot phase and the real
  terrain a pick needs to hit — an empty grid means the DDA finds no cell and nothing can be
  committed at all), **`scene-006`** (the non-vacuity discipline this story copies verbatim),
  `building-001` (`BuildEditorMode`), `building-011` (plan-only undo/redo, Complete 2026-07-27),
  `building-016` (multi-cell furniture footprint), `building-019`–`021` (`ToolStateMachine`,
  `PlacementPick`, `CommitPipeline` — already hosted), `building-022`/`028` (validity gates,
  furniture identity), `building-023` (`GhostPreview`), `building-024`–`027` (the four block tools),
  `building-029`/`030`/`032`/`033` (tick loop, project entity, registry/queue, write tag),
  `vox-020`/`021` (the boot window `scene-005` measures against).
- **Blocked on**: **`building-031`** (in-sprint, removal-tool base) — **ordering, not a compile
  dependency**: sequenced after it so the removal tool is hosted in the same pass rather than
  becoming occurrence #5. ⚑ **This is the last story on lane C** (`building-009 → 012 → 015 → 017 →
  scene-007`), landing after the entire demolition chain **by design**: it is the chain's production
  caller, and a caller written before the thing it calls would have nothing to assert against.
- **Unlocks**:
  - **The player can build in the shipped game.** Today they cannot. This is milestone criterion
    #6's player-facing half — *"the player places a bed"* — on the tool side. (Its remaining halves
    are `rid-009`'s palette content and the **missing furniture view**, sprint-11 F7 — after this
    story the bed is placeable and still invisible. State that honestly; do not let this story be
    read as closing #6.)
  - **The C1 demolition chain (`building-009`/`012`/`015`/`017`/`031`) gets a production caller** —
    without this story all five ship green and uncalled.
  - `building-ui-003`/`004`/`005`/`011` — KC3 names them explicitly as blocked on this hosting.
  - Criterion #12's production half: plan-only undo becomes reachable by a player (Sub-scope C).
- **Open decisions this story surfaces (producer → user / technical-director)**:

  1. **⚑ Which scene owns a non-world, non-config node — Valley or `GameWorld`? (technical-director;
     this is building-ui KC1/KC3 and sprint-11 D9, and it is one question, not three.)** This story
     answers it for the tool tier by following the only landed precedent: **the Valley hosts, and
     `GameWorld` calls `setup()`.** Every one of the twelve current modules works this way and
     `valley.gd`'s class doc calls the distinction out explicitly. The HUD tier may reasonably differ
     (a `CanvasLayer` is not a world child), which is precisely why the ruling should be made once,
     with both tiers on the table, **before `building-ui-001` starts**. *Producer recommendation:
     ratify the Valley-hosts precedent for anything with a `setup()`, and rule separately on the
     `CanvasLayer`/`Control` tier.* **We will know this was right if** `building-ui-001` can state
     its host in one sentence citing this story, instead of re-opening KC1.

  2. **Tool-id constants have no owner.** `&"wall"`/`&"floor"`/`&"roof"`/`&"block"` exist only in
     test files; there is **no furniture tool id anywhere in the repo** and no `const` for any of
     them. The router this story adds is the first production code that must know them. Options:
     (a) a `const` block on `ToolStateMachine` (it owns `_armed_tool_id`); (b) a `const` block on
     `BuildEditorMode` (it owns the arming entry point); (c) leave them as bare literals in
     `valley.gd`. *Producer recommendation: (a)* — the ids are the state machine's own vocabulary and
     building-ui will need to name them too. **This is a small technical-director call, not an
     invention this story should make unilaterally**; it is flagged here rather than decided.

  3. **`FurnitureRegistry` is a fifth uncalled construction site, found while reading for this
     story.** It is `RefCounted`, constructed nowhere in `src/`; `ConstructionTickLoop.furniture_registry`
     and `FurnitureBedProvider.furniture_registry` are `null` in production, and
     `VillagerAi.bed_provider` is never assigned — so a completed furniture cell registers nothing and
     no villager can ever claim a bed in the shipped game. **This is the production-side twin of
     sprint-11's F7** and it is what makes criterion #5's payoff loop still unreachable outside a
     fixture. Options: (a) pull it into this story's Sub-scope B (+~0.25, and it makes the crown's
     loop production-reachable); (b) a separate S12 story alongside the missing furniture view;
     (c) record and defer. *Producer recommendation: (a) if Sub-scope C is being cut anyway — the two
     trades are roughly cost-neutral and (a) buys strictly more.* **User/TD call; recorded, not
     assumed.**

  4. **The sprint's named descope lever points at the wrong sub-scope** — see *Sizing and the descope
     ladder*. sprint-11.md would cut the registry/queue tier, which is the C1 chain's caller. This
     story recommends cutting the **undo tier** instead. Producer-owned correction, surfaced here so
     the sprint's buffer entry can be amended rather than followed off a cliff.

---

## Deletion-Probe Record (2026-07-27, performed late — QA condition #1)

The Sprint 11 QA plan makes this recording binding, and `scene-006` is the named
template. Story-007's original commit (`6d1d696`) did NOT carry it, even though
the test file's own doc comment claimed it did. The QA sign-off caught that. The
probe was therefore run afterwards, and this is its record.

**Production call removed:** `valley.gd`, the armed-tool → resolver router's own
subscription —

    _tool_state_machine.tool_armed.connect(_on_tool_armed)

commented out, nothing else touched.

**Observed failure, verbatim:**

    res://tests/integration/scene_world/build_tool_hosting_boot_test.gd >
      test_ac_tool_resolver_is_live_wall_click_produces_wall_height_cells_from_config
      FAILED 12s 848ms
        line 201: Expecting:
    Statistics: 3 test cases | 0 errors | 1 failures | 0 flaky | 0 skipped | 0 orphans

Line 201 is the anti-vacuity assertion itself:
`assert_int(cells.size()).is_equal(wall_config.wall_height)`. With the router
unsubscribed, an armed wall tool never re-points `CommitPipeline`'s resolver, so
a click yields the wrong cell count — exactly the pre-story behaviour.

**Restore:** the file was restored from a byte-for-byte copy taken before the
probe; `git diff` on `valley.gd` is empty. The suite file then ran green again:
13 test cases, 0 errors, 0 failures, 0 orphans.

The probe is what makes AC-TOOL-RESOLVER-IS-LIVE non-vacuous in fact and not
merely in intent.
