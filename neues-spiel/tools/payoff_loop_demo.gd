## Payoff-loop demo — proves the build-a-room-and-a-villager-uses-it loop END
## TO END, in the real shipped game, and photographs every stage.
##
## WHY THIS TOOL EXISTS NOW, not before: this demo was structurally
## impossible until three fixes landed in the SAME shipped scene the other
## capture tools already photograph. The whole build-interaction tier
## (BuildEditorMode, the five placement tools, the project-lifecycle
## RefCounted collaborators) was ship-green-and-uncalled -- built, tested,
## and reachable by NOTHING in `src/` -- until scene-007 (commit 6d1d696)
## hosted it on the real `Valley`. The shipped game had no camera at all
## until cam-013 (5793812). The shipped game rendered pitch black until
## presentation-004 (1502baa). All three are now real, hosted, wired
## children of the SAME `Valley.tscn` -- so this is the first day the payoff
## loop can be driven and PHOTOGRAPHED through the real running game rather
## than a headless assertion.
##
## Modelled closely on `tools/settlement_overview_capture.gd`: same evidence
## directory, same wall-clock self-quit safety cap, same "await every shot or
## the last camera position wins" discipline, same rule of supplying NO
## lighting and NO ground plane of this tool's own -- the real, unmodified
## `res://src/scene_world_management/game_world.tscn` lights and grounds
## itself, or it does not, and either way that is what gets photographed.
##
## **The one deliberate difference from every other capture tool here**:
## every screenshot in this file goes through the SHIPPED [Camera3D]
## ([method Valley.get_valley_camera]) -- never a tool-supplied one. This
## tool owns no camera node of its own. The only camera control it performs
## is a single, real [method CameraInput.set_target] pan onto the build
## site -- the SAME sanctioned API [method GameWorld._run_world_genesis]
## already uses to frame the starting roster -- never a raw transform write.
##
## **How the build chain is driven**: exclusively through [Valley]'s own
## getters, exactly as instructed. [method BuildEditorMode.arm_tool] is the
## ONLY arming call site used (scene-007's own grep guard already proves zero
## `arm_tool(` calls anywhere in `valley.gd` itself -- production arms tools
## through this gate only). Wall geometry comes from
## [method WallTool.resolve_cell_set] reading [member WallToolConfig.wall_height]
## LIVE from the hosted config -- never a hardcoded `3`. Commits go through
## [method CommitPipeline.commit] directly, the SAME direct-call convention
## this codebase's own `gameworld_e2e_loop_test.gd` and that class's own doc
## comment ("Callable directly by a future tool story... and by tests")
## already establish as sanctioned -- this tool drives [PlacementPick] with an
## explicit downward ray via [method PlacementPick.resolve_pick] rather than a
## synthetic mouse-drag rig, exactly as that same E2E test's own
## `test_ac_e2e_gate_typed_array_param_rejects_plain_untyped_array_caller`
## does for the identical reason: [method CommitPipeline.commit] only ever
## gates on the pick's `hit` flag, not on which exact cell it names.
##
## **Honesty rules this tool exists to enforce on itself**:
##  * NEVER a direct [VoxelWorldGrid] write. Every cell in the finished room
##    (and the bed) reaches Voxel World data ONLY via
##    [ConstructionTickLoop]'s own real completion write, tick-driven, exactly
##    as a real villager would produce it.
##  * NEVER a tool-supplied light or ground plane -- whatever renders is the
##    real, hosted [WorldLighting] and the real meshed voxel terrain, or nothing.
##  * Every stage prints a REPORT before its screenshot, including exactly
##    which cells were rejected and why, if any were. A stage that fails
##    prints WHY and the tool moves on to the next one rather than faking a
##    result.
##
## Story scene-009 ("The payoff loop's last step, IN THE GAME") extends this
## file with stages 6 (claim) and 7 (sleep): the villager claims the bed
## stage 5 just finished, then sleeps in it — both driven entirely by the
## villager's own real Rest need under the real [TimeTickSystem.set_warp]
## already requested above, never a tool-written need value (see
## [method _attempt_claim_and_sleep_stages]'s own doc comment, Open Decision
## 1). `06-claimed`/`07-sleeping` follow the SAME honesty rule as `05-furnished`
## above: a stage that does not reach its own real condition inside its wait
## cap prints why and skips its screenshot.
##
## Story villager-ai-024 ("A villager cannot finish a wall") fixes TWO
## independent reasons this demo's bed had never been sheltered: (1) job
## selection could not reach a wall's 3rd layer and above at all (fixed in
## [VillagerAi]/[VillagerSealPreventionGate], out of THIS file's own scope);
## (2) this demo built walls only, never a roof, so even completed walls
## could never classify as a Room (`CandidateCellRules.
## is_candidate_interior_cell` requires a roofed cell). This revision adds
## [method _attempt_roof_stage] — a `04b-roofed` stage, driven through the
## SAME real [RoofTool] -> [CommitPipeline] -> [ConstructionTickLoop] chain
## every other stage already uses — and reports the REAL hosted
## [BuildValidation]'s own Room-classification verdict for the interior,
## rather than assuming "walls + roof both finished" implies it.
##
## Run WINDOWED (a real viewport is required):
##   Godot_v4.7-stable_win64_console.exe --path neues-spiel res://tools/payoff_loop_demo.tscn
extends Node3D

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")

const EVIDENCE_DIR := "res://../production/qa/evidence"

## The real RID entries this demo selects -- `wood_block` (tier-0
## `building_material`, `data/items/wood_block.tres`) for the walls, `bed`
## (`furniture_fixture`, 1x2 footprint, `data/items/bed.tres`) for the
## furniture stage. Never invented ids -- both are real, shipped data.
const WALL_MATERIAL_ID: StringName = &"wood_block"
const BED_ITEM_ID: StringName = &"bed"

## Real seconds to let the simulation tick after ACTIVE before the first
## shutter, so the villager has actually been placed and decided at least
## once (mirrors `settlement_overview_capture.gd`'s own `SETTLE_SEC`).
const SETTLE_SEC := 2.0

## Hard wall-clock safety cap for the WHOLE tool run — force an early quit if
## anything ever stalls, mirroring every other tool scene's self-quit
## precedent. Generous because real construction is tick-driven and this
## tool deliberately never fakes a faster outcome, but bounded so the process
## always exits on its own. Story scene-009 raised this from 480 -> 780 to
## cover its own two new stages' wait caps below on top of the five that
## already existed. Story villager-ai-024 raises this again, 780 -> 900, to
## cover its own new [constant ROOF_WAIT_CAP_SEC] stage — a change to the
## OVERALL safety net, never to [constant WALL_WAIT_CAP_SEC]/[constant
## FURNITURE_WAIT_CAP_SEC]/[constant ROOF_WAIT_CAP_SEC] themselves (Sprint 12
## plan: a stalled construction plateau is a finding for `spike-plateau` to
## diagnose, never a cap this tool quietly raises to route around it).
const SAFETY_CAP_SEC := 900.0

## Sub-caps for the two tick-driven waits (walls, then the bed) — bounded
## independently of the overall cap so a stalled wall build cannot silently
## eat the bed stage's entire budget.
const WALL_WAIT_CAP_SEC := 220.0
const FURNITURE_WAIT_CAP_SEC := 120.0

## Story villager-ai-024 (AC5/AC6) — wall-clock cap for the ROOF stage. A
## flat roof over this demo's small 3x4 footprint is 12 cells (identical
## shape/order-of-magnitude to the wall run itself), so this mirrors
## [constant FURNITURE_WAIT_CAP_SEC] rather than the larger wall cap.
const ROOF_WAIT_CAP_SEC := 120.0

## Story scene-009 — wall-clock cap for the CLAIM stage: how long this run
## waits for the villager's OWN real Rest need to reach urgency (driven
## purely by real F1 decay under [constant DEMO_TIME_WARP], never a
## tool-written need value — Open Decision 1(a)) and claim the bed
## [method _attempt_furniture_stage] just finished. Generous: construction
## itself already consumes some of the villager's decay budget, but a fast,
## honest construction run can still owe most of the ~1,000-tick decay from a
## fresh spawn's 100.0 down to [member NeedsMoodConfig.urgency_threshold].
const CLAIM_WAIT_CAP_SEC := 300.0

## Story scene-009 — wall-clock cap for the SLEEP stage once a bed is
## claimed: travel to the bed plus [method NeedsMood.start_recovery] taking
## hold is short relative to [constant CLAIM_WAIT_CAP_SEC]'s own decay wait.
const SLEEP_WAIT_CAP_SEC := 60.0

## Story scene-009 — how long this run waits to collect at least two real
## per-tick recovery-value samples via the real [signal TimeTickSystem.tick]
## broadcast once Recovering is observed, bounded independently so a stall
## here cannot silently hang the run.
const RECOVERY_SAMPLE_WAIT_CAP_SEC := 15.0

## Real time-warp this demo requests via the SANCTIONED [TimeTickSystem.set_warp]
## API (never `Engine.time_scale`, Forbidden per `technical-preferences.md`) —
## the same speed a player could select from the UI, just held throughout
## this run so tick-driven construction finishes inside the caps above.
const DEMO_TIME_WARP := 3

var _world: Node
var _boot_start_usec: int = 0
var _active_usec: int = 0
var _phase: int = 0  # 0 = waiting for boot, 1 = settling, 2 = run, 3 = done

## Collector for [signal CommitPipeline.commit_rejected] — populated fresh
## around each commit attempt below, read immediately after, never left
## connected across stages (see [method _commit_with_report]).
var _commit_rejected_this_batch: Array[Dictionary] = []

## Story scene-009 — edge-triggered log of every distinct entry into
## [constant VillagerAi.State.SLEEPING] observed anywhere in this run,
## ground/unsheltered sleeps included (GDD D10's own "the villager's first
## sleep is always the unsheltered one" pacing finding,
## AC-D10-IS-REPORTED-NOT-SUPPRESSED). Populated by
## [method _sample_sleep_transition], which every wait loop in this file now
## calls every frame it waits (room-wall wait, bed wait, and the two new
## stages below) — no SLEEPING episode this run passes through goes
## unrecorded, never only the one the sleep stage itself is waiting for.
## Each entry: `{"owned_bed": Variant, "sheltered": bool, "cell": Vector3i}`.
var _sleep_event_log: Array[Dictionary] = []

## Story scene-009 — tracks whether the LAST sampled frame already read
## [constant VillagerAi.State.SLEEPING], [method _sample_sleep_transition]'s
## own edge-trigger guard so a multi-frame sleep episode is logged exactly
## once, at entry, never once per frame it persists.
var _was_sleeping_last_sample: bool = false


func _ready() -> void:
	_boot_start_usec = Time.get_ticks_usec()
	_world = GameWorldScene.instantiate()
	add_child(_world)


func _process(_delta: float) -> void:
	var elapsed: float = (Time.get_ticks_usec() - _boot_start_usec) / 1000000.0
	if elapsed > SAFETY_CAP_SEC and _phase != 3:
		push_warning("payoff_loop_demo: SAFETY CAP hit (%0.1fs) — forcing quit" % elapsed)
		get_tree().quit()
		return

	match _phase:
		0:
			_wait_for_boot_active(elapsed)
		1:
			if (Time.get_ticks_usec() - _active_usec) / 1000000.0 >= SETTLE_SEC:
				_phase = 2
		2:
			# Set the phase FIRST — _run_demo() awaits repeatedly; without
			# this, _process would re-enter it on the very next frame and
			# start a second, interleaved run (settlement_overview_capture's
			# own established fix for the identical hazard).
			_phase = 3
			_run_demo()


func _wait_for_boot_active(elapsed: float) -> void:
	if not _world.has_method("get_boot_state"):
		return
	# BootState.ACTIVE == 2 in game_world.gd's own enum.
	if int(_world.get_boot_state()) != 2:
		return
	_active_usec = Time.get_ticks_usec()
	_phase = 1
	print("payoff_loop_demo: real GameWorld reached ACTIVE after %0.2fs" % elapsed)


# ---------------------------------------------------------------------------
# The demo itself
# ---------------------------------------------------------------------------

func _run_demo() -> void:
	var valley: Node = _world.get_valley() if _world.has_method("get_valley") else null
	if valley == null:
		print("payoff_loop_demo: REPORT — no Valley attached at all; the payoff loop cannot be demonstrated. Aborting.")
		get_tree().quit()
		return

	# ---- 01-before ----------------------------------------------------
	await _shoot_through_game_camera("01-before")

	var villagers: Array = valley.get_villagers()
	print("payoff_loop_demo: REPORT — villagers spawned: %d" % villagers.size())
	if villagers.is_empty():
		print("payoff_loop_demo: REPORT — zero villagers hosted; nothing can claim or build a job. Aborting the rest of the loop.")
		get_tree().quit()
		return
	var villager: VillagerAi = villagers[0]
	var villager_cell: Vector3i = villager.get_current_cell()
	print("payoff_loop_demo: REPORT — using villager id=%d, currently at cell %s, state=%s" % [
		villager.get_villager_id(), str(villager_cell), str(villager.get_state()),
	])

	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	var wall_tool: WallTool = valley.get_wall_tool()
	var wall_height: int = wall_tool.config.wall_height
	print("payoff_loop_demo: REPORT — WallToolConfig.wall_height read live from the hosted config = %d (never hardcoded)" % wall_height)

	var site: Dictionary = _find_build_site(villager_cell, wall_height, voxel_world)
	var anchor: Vector3i = site["anchor"]
	if site["clear"]:
		print("payoff_loop_demo: REPORT — build site anchor resolved to %s (verified clear for the whole room + bed footprint)" % str(anchor))
	else:
		print("payoff_loop_demo: REPORT — WARNING: no fully clear candidate site found near the villager after %d tries; using %s anyway. If the commits below get rejected, that rejection reason is the honest reason, not a tool bug." % [site["tries"], str(anchor)])

	# Real camera pan onto the build site — the SAME sanctioned
	# CameraInput.set_target() API GameWorld's own boot genesis uses, never a
	# raw transform write on the Camera3D itself.
	var camera_input: CameraInput = valley.get_camera_input()
	if camera_input != null:
		camera_input.set_target(VoxelWorldGrid.cell_to_world(anchor + Vector3i(1, 0, 2)))

	# Warp time (sanctioned player-facing feature, never Engine.time_scale) so
	# the tick-driven stages below finish comfortably inside their caps.
	var time_tick_system: Object = get_node_or_null(^"/root/TimeTickSystem")
	if time_tick_system != null and time_tick_system.has_method("set_warp"):
		time_tick_system.set_warp(DEMO_TIME_WARP)
		print("payoff_loop_demo: REPORT — TimeTickSystem.set_warp(%d) requested (the same player-facing speed control, not a tool-only hack)" % DEMO_TIME_WARP)

	var build_editor_mode: BuildEditorMode = valley.get_build_editor_mode()
	var commit_pipeline: CommitPipeline = valley.get_commit_pipeline()
	var placement_pick: PlacementPick = valley.get_placement_pick()
	var build_project_registry: BuildProjectRegistry = valley.get_build_project_registry()
	var construction_job_queue: ConstructionJobQueue = valley.get_construction_job_queue()

	# ---- Draft the room -------------------------------------------------
	# BuildEditorMode.arm_tool is the ONLY sanctioned arming path (scene-007's
	# own grep guard: zero arm_tool( calls in valley.gd itself).
	build_editor_mode.arm_tool(ToolStateMachine.TOOL_ID_WALL)
	commit_pipeline.set_selected_item(WALL_MATERIAL_ID)
	# A real DDA pick, straight down onto the site — commit() only ever gates
	# on the pick's hit flag (AC38), not which exact cell it names, so one
	# pick above the anchor's own ground is all four segment commits need.
	placement_pick.resolve_pick(VoxelWorldGrid.cell_to_world(anchor) + Vector3(0.0, 60.0, 0.0), Vector3.DOWN)
	if not placement_pick.get_current_pick().hit:
		print("payoff_loop_demo: REPORT — WARNING: the placement pick found no surface above the build site; every commit below will legitimately no-op (Edge Case 4).")

	var wall_cells: Array[BlueprintCell] = []
	var segment_index: int = 0
	for segment: Array in _wall_segments(anchor):
		segment_index += 1
		var press: Vector3i = segment[0]
		var release: Vector3i = segment[1]
		var candidate_cells: Array[Vector3i] = wall_tool.resolve_cell_set(true, press, release)
		var created: Array[BlueprintCell] = _commit_with_report(commit_pipeline, candidate_cells)
		wall_cells.append_array(created)
		print("payoff_loop_demo: REPORT — wall segment %d/4 (%s -> %s): %d/%d cells drafted" % [
			segment_index, str(press), str(release), created.size(), candidate_cells.size(),
		])

	print("payoff_loop_demo: REPORT — TOTAL wall cells drafted: %d (expected up to %d = 10 perimeter cells x wall_height %d)" % [
		wall_cells.size(), 10 * wall_height, wall_height,
	])

	# ---- Story villager-ai-025 lever 1 geometry: a ground-level doorway ----
	# Erases ONE ground-layer, non-corner wall cell via the REAL RemovalTool
	# (Branch 1 -- Draft/not-yet-released, instant cancel, no job ever
	# created) — what a player does before starting construction. Without
	# this the room seals completely and lever 1 (the crown stall) never
	# reproduces (a fully sealed room gives 30/30; the story's own measured
	# stall needs the opening).
	var door_cell: Vector3i = anchor + Vector3i(0, 0, 1)
	var removal_tool: RemovalTool = valley.get_removal_tool()
	var door_removed: bool = removal_tool.remove_cell(door_cell)
	if door_removed:
		var filtered_wall_cells: Array[BlueprintCell] = []
		for c: BlueprintCell in wall_cells:
			if c.cell != door_cell:
				filtered_wall_cells.append(c)
		wall_cells = filtered_wall_cells
		print("payoff_loop_demo: REPORT — DOORWAY (villager-ai-025 lever 1): erased ground cell %s via the real RemovalTool before release. Remaining wall cells: %d." % [
			door_cell, wall_cells.size(),
		])
	else:
		print("payoff_loop_demo: REPORT — DOORWAY (villager-ai-025 lever 1): RemovalTool.remove_cell(%s) returned false — no doorway created this run." % door_cell)

	await _shoot_through_game_camera("02-drafted")

	# ---- Release the project(s) -----------------------------------------
	var released_ids: Array[int] = _release_projects_for(wall_cells, build_project_registry)
	print("payoff_loop_demo: REPORT — %d distinct BuildProject(s) released: %s" % [released_ids.size(), str(released_ids)])
	print("payoff_loop_demo: REPORT — jobs now queued and villager-claimable: %d" % construction_job_queue.get_available_jobs().size())
	await _shoot_through_game_camera("03-released")

	# ---- Tick the REAL construction loop / villager AI until it finishes ----
	# Story scene-008 ("Hosting the gates that make work honest") closed the
	# deviation this tool's own reading of valley.gd used to surface here:
	# VillagerOnSiteGate/VillagerSealPreventionGate are now constructed and
	# wired by Valley, so ConstructionTickLoop only credits a claimed job's
	# cell while the claiming villager is actually on site. This tool
	# observes and reports whatever that real, now-honest behavior actually
	# produces — it does not paper over it either way.
	await _wait_for_built(wall_cells, WALL_WAIT_CAP_SEC, "room walls", valley, villager, villager_cell)
	var built_wall_count: int = _count_built(wall_cells)
	print("payoff_loop_demo: REPORT — construction result: %d / %d wall cells reached BUILT" % [built_wall_count, wall_cells.size()])
	print("payoff_loop_demo: REPORT — villager after construction wait: state=%s pursued_activity=%s current_cell=%s" % [
		str(villager.get_state()), str(villager.get_pursued_activity()), str(villager.get_current_cell()),
	])
	var solid_cell_count: int = voxel_world.get_solid_cell_count() if voxel_world.has_method("get_solid_cell_count") else -1
	if solid_cell_count >= 0:
		print("payoff_loop_demo: REPORT — real VoxelWorldGrid solid cell count after construction: %d (this is the ONLY write path used — ConstructionTickLoop's own batched bulk_write, never this tool)" % solid_cell_count)
	await _shoot_through_game_camera("04-built")

	# ---- Roof: close the room over, so it can actually classify as a Room ----
	# (Story villager-ai-024, AC5/AC6): walls alone never roof the interior --
	# CandidateCellRules.is_candidate_interior_cell requires a cell to be
	# ROOFED (solid within max_room_height directly above) before it is even a
	# Room candidate. This stage builds the roof through the SAME real
	# RoofTool -> CommitPipeline -> ConstructionTickLoop chain the walls just
	# went through -- never a direct VoxelWorldGrid write.
	await _attempt_roof_stage(valley, anchor, wall_height, villager, build_editor_mode, commit_pipeline, placement_pick, build_project_registry, villager_cell)

	# Story villager-ai-025 Anti-Vacuity Lever 2 (ROOF) -- AC1's own wording,
	# verbatim: "after ANY construction job completes, the claiming villager
	# has a path back to standable settlement ground." Checked here,
	# regardless of whether the roof stage above reached DONE or its own wait
	# cap — the story's own measured finding is that the villager finishes at
	# y=10 with an EMPTY path either way.
	_report_roof_descent_lever(valley, villager, villager_cell)

	# BuildValidation prominent finding — printed here because this is
	# exactly the moment a human would ask "is the room sheltered now?"
	_report_build_validation_gap()

	# ---- Furniture: place a bed inside the finished room, if reachable ----
	await _attempt_furniture_stage(valley, anchor, villager, build_editor_mode, commit_pipeline, placement_pick, build_project_registry)

	# ---- Claim + sleep: the payoff loop's last step (Story scene-009) ----
	await _attempt_claim_and_sleep_stages(valley, villager, build_project_registry)

	_report_sleep_event_log()
	_report_climb_telemetry()
	print("payoff_loop_demo: REPORT — run complete. Quitting.")
	get_tree().quit()


## Wraps [method CommitPipeline.commit] with a temporary
## [signal CommitPipeline.commit_rejected] listener so every rejection this
## SPECIFIC call produces is captured and printed, never silently absorbed.
## Connected and disconnected around exactly one commit call — this tool
## never leaves a stale listener attached across stages.
func _commit_with_report(commit_pipeline: CommitPipeline, candidate_cells: Array[Vector3i]) -> Array[BlueprintCell]:
	_commit_rejected_this_batch = []
	commit_pipeline.commit_rejected.connect(_on_commit_rejected)
	var created: Array[BlueprintCell] = commit_pipeline.commit(candidate_cells)
	commit_pipeline.commit_rejected.disconnect(_on_commit_rejected)
	for rejection: Dictionary in _commit_rejected_this_batch:
		print("payoff_loop_demo: REPORT —   REJECTED: reason=%s cells=%s" % [
			_reject_reason_name(int(rejection["reason"])), str(rejection["cells"]),
		])
	return created


func _on_commit_rejected(reason: int, cells: Array[Vector3i]) -> void:
	_commit_rejected_this_batch.append({"reason": reason, "cells": cells.duplicate()})


func _reject_reason_name(reason: int) -> String:
	var keys: Array = CommitPipeline.RejectReason.keys()
	if reason >= 0 and reason < keys.size():
		return String(keys[reason])
	return "UNKNOWN(%d)" % reason


## Resolves every distinct [BuildProject] touching [param blueprint_cells] via
## the real reverse index ([method BuildProjectRegistry.project_at_cell]) and
## releases each one exactly once via the real registry-level
## [method BuildProjectRegistry.release_project] — never a direct
## [BuildProject.release] bypass.
func _release_projects_for(blueprint_cells: Array[BlueprintCell], registry: BuildProjectRegistry) -> Array[int]:
	var touched_ids: Dictionary[int, bool] = {}
	for cell: BlueprintCell in blueprint_cells:
		var project_id: int = registry.project_at_cell(cell.cell)
		if project_id != -1:
			touched_ids[project_id] = true
	var released_ids: Array[int] = []
	for project_id: int in touched_ids.keys():
		if registry.release_project(project_id):
			released_ids.append(project_id)
	return released_ids


## Waits, real frame by real frame, until every cell in [param blueprint_cells]
## reads [constant BlueprintCell.MicroState.BUILT] or [param cap_sec] real
## seconds elapse — whichever comes first. Never advances the loop itself:
## the REAL [TimeTickSystem]/[ConstructionTickLoop]/villager AI already
## running inside the live scene tree are the only things that ever move
## [member BlueprintCell.state] forward. Prints a periodic progress line so a
## human watching the console can see the loop is alive, not stalled.
## Story scene-009 — also samples [method _sample_sleep_transition] every
## frame this loop waits, so a GROUND (D10) sleep episode occurring mid-
## construction is recorded even though this method's own focus is the
## build, not the villager's needs.
## Story villager-ai-025 -- [param ground_cell] is a real standable cell (the
## villager's OWN pre-build spawn cell, captured once at the very start of
## this run, before anything was built) used ONLY as the Anti-Vacuity Lever
## 1 diagnostic's own "is the villager stranded above the structure" probe
## (see [method _stall_diag]) -- optional (defaults to a sentinel meaning "no
## lever 1 diagnostic this call"), so the bed-furniture stage below can keep
## calling this method unchanged.
const _NO_GROUND_CELL := Vector3i(-2147483648, -2147483648, -2147483648)


func _wait_for_built(
	blueprint_cells: Array[BlueprintCell], cap_sec: float, label: String, valley: Node, villager: VillagerAi,
	ground_cell: Vector3i = _NO_GROUND_CELL,
) -> void:
	if blueprint_cells.is_empty():
		return
	var start_usec: int = Time.get_ticks_usec()
	var deadline_usec: int = start_usec + int(cap_sec * 1000000.0)
	var last_report_usec: int = start_usec
	# Story villager-ai-025 -- the LAST PERIODIC sample's built count, so the
	# STALLDIAG probe below fires only when the count did NOT advance between
	# two 5s samples ("at every poll where the built count does not advance"),
	# never on every single frame this loop spins.
	var last_periodic_built_count: int = -1
	while true:
		_sample_sleep_transition(valley, villager)
		var built_count: int = _count_built(blueprint_cells)
		if built_count == blueprint_cells.size():
			print("payoff_loop_demo: REPORT — %s: all %d cells reached BUILT after %0.1fs real time" % [
				label, blueprint_cells.size(), (Time.get_ticks_usec() - start_usec) / 1000000.0,
			])
			return
		var now_usec: int = Time.get_ticks_usec()
		if now_usec >= deadline_usec:
			print("payoff_loop_demo: REPORT — %s: WAIT CAP (%0.0fs) hit with %d/%d cells BUILT — stopping honestly, not faking the rest." % [
				label, cap_sec, built_count, blueprint_cells.size(),
			])
			return
		if now_usec - last_report_usec >= 5000000:
			last_report_usec = now_usec
			print("payoff_loop_demo: REPORT — %s: still waiting — %d/%d BUILT, %0.1fs elapsed" % [
				label, built_count, blueprint_cells.size(), (now_usec - start_usec) / 1000000.0,
			])
			if ground_cell != _NO_GROUND_CELL and built_count == last_periodic_built_count:
				_stall_diag(label, blueprint_cells, villager)
			last_periodic_built_count = built_count
		await get_tree().process_frame


## Story villager-ai-025 Anti-Vacuity Lever 1 (CROWN) -- printed (never a
## crashing engine `assert()`, so this run continues on to record Lever 2's
## own evidence too, in the SAME run, per the story's own "record BOTH
## observed failures verbatim... neither can mask the other" instruction)
## every time [method _wait_for_built]'s own periodic sample finds the built
## count unchanged since the LAST sample -- "measure in the stall window,"
## never the run's aftermath. Reports the villager's current cell/state and
## up to 5 still-pending (non-BUILT) cells, the same evidence shape this
## story's own commit body records.
func _stall_diag(label: String, blueprint_cells: Array[BlueprintCell], villager: VillagerAi) -> void:
	var pending: Array[Vector3i] = []
	for cell: BlueprintCell in blueprint_cells:
		if cell.state != BlueprintCell.MicroState.BUILT:
			pending.append(cell.cell)
			if pending.size() >= 5:
				break
	print("payoff_loop_demo: STALLDIAG %s villager=%s state=%d pending=%d %s" % [
		label, str(villager.get_current_cell()), villager.get_state(), pending.size(), str(pending),
	])


func _count_built(blueprint_cells: Array[BlueprintCell]) -> int:
	var count: int = 0
	for cell: BlueprintCell in blueprint_cells:
		if cell.state == BlueprintCell.MicroState.BUILT:
			count += 1
	return count


## Reports the BuildValidation/gate wiring state this tool's own preparation
## used to surface as two FINDING lines (story scene-008's own "found by this
## tool" origin). Story scene-008 closed both: Valley now constructs and
## hosts [BuildValidation] (wired into [FurnitureBedProvider], replacing the
## `null` `Open Decision 3, resolved (a)` used to record) and both
## [VillagerOnSiteGate]/[VillagerSealPreventionGate] (wired into
## [ConstructionJobQueue]'s own occupancy/seal-prevention predicate seams).
## This method now reports the FIXED state — never the word "FINDING" — so a
## future regression that silently un-hosts any of the three would need to
## touch this print too, not just this tool's own text, before it could
## misrepresent the shipped game as honest again.
func _report_build_validation_gap() -> void:
	print("payoff_loop_demo: REPORT — BuildValidation is hosted and wired: is_bed_sheltered() now answers for real against the actual built room, never structurally false.")
	print("payoff_loop_demo: REPORT — VillagerOnSiteGate and VillagerSealPreventionGate are hosted and wired: ConstructionTickLoop only credits a claimed job's progress while the claiming villager is actually on site — the timing above reflects that real, now-honest behavior.")


## Best-effort furniture stage (task step 7: "if it is reachable within the
## same run"). A bed is a real 1x2 RID footprint (`data/items/bed.tres`) —
## the anchor is chosen so both footprint cells sit inside the SAME interior
## this run's own site search already verified clear.
func _attempt_furniture_stage(
	valley: Node,
	anchor: Vector3i,
	villager: VillagerAi,
	build_editor_mode: BuildEditorMode,
	commit_pipeline: CommitPipeline,
	placement_pick: PlacementPick,
	build_project_registry: BuildProjectRegistry
) -> void:
	var furniture_tool: FurnitureTool = valley.get_furniture_tool()
	var bed_anchor: Vector3i = anchor + Vector3i(1, 0, 1)

	build_editor_mode.arm_tool(ToolStateMachine.TOOL_ID_FURNITURE)
	commit_pipeline.set_selected_item(BED_ITEM_ID)
	placement_pick.resolve_pick(VoxelWorldGrid.cell_to_world(bed_anchor) + Vector3(0.0, 60.0, 0.0), Vector3.DOWN)
	if not placement_pick.get_current_pick().hit:
		print("payoff_loop_demo: REPORT — stage 5 (furniture) UNREACHABLE this run: no placement pick hit above the bed anchor %s." % str(bed_anchor))
		return

	var footprint: Vector2i = commit_pipeline.get_selected_item_footprint()
	print("payoff_loop_demo: REPORT — bed footprint read live from RID = %s (never hardcoded)" % str(footprint))
	var bed_candidate_cells: Array[Vector3i] = furniture_tool.resolve_cell_set(false, bed_anchor, bed_anchor)
	var bed_cells: Array[BlueprintCell] = _commit_with_report(commit_pipeline, bed_candidate_cells)

	if bed_cells.is_empty():
		print("payoff_loop_demo: REPORT — stage 5 (furniture) UNREACHABLE this run: CommitPipeline.commit rejected the bed at %s (see the REJECTED line above for the exact reason). Not faking a bed." % str(bed_anchor))
		return

	print("payoff_loop_demo: REPORT — bed drafted: %d/%d cells at %s" % [bed_cells.size(), bed_candidate_cells.size(), str(bed_candidate_cells)])
	var released_ids: Array[int] = _release_projects_for(bed_cells, build_project_registry)
	print("payoff_loop_demo: REPORT — bed project(s) released: %s" % str(released_ids))

	await _wait_for_built(bed_cells, FURNITURE_WAIT_CAP_SEC, "bed", valley, villager)
	var built_bed_count: int = _count_built(bed_cells)
	print("payoff_loop_demo: REPORT — bed construction result: %d / %d cells reached BUILT" % [built_bed_count, bed_cells.size()])

	if built_bed_count == bed_cells.size():
		await _shoot_through_game_camera("05-furnished")
	else:
		print("payoff_loop_demo: REPORT — stage 5 screenshot skipped: the bed did not finish inside its wait cap, so '05-furnished' would not actually show a furnished room. Honesty over a picture.")

	var furniture_registry: FurnitureRegistry = valley.get_furniture_registry()
	var bed_provider: FurnitureBedProvider = valley.get_furniture_bed_provider()
	if furniture_registry != null:
		print("payoff_loop_demo: REPORT — FurnitureRegistry now holds %d placed item(s): %s" % [
			furniture_registry.get_placed_furniture().size(), str(furniture_registry.get_placed_furniture()),
		])
	if bed_provider != null:
		print("payoff_loop_demo: REPORT — unowned/claimable bed cells right now: %s" % str(bed_provider.get_unowned_bed_cells()))
	var owned_bed: Variant = villager.get_owned_bed_cell()
	if owned_bed != null:
		print("payoff_loop_demo: REPORT — villager id=%d has claimed a bed at %s" % [villager.get_villager_id(), str(owned_bed)])
	else:
		print("payoff_loop_demo: REPORT — villager id=%d has NOT claimed a bed this run (needs a real Rest-need trigger this demo's timeframe did not necessarily reach — reported honestly, not assumed)." % villager.get_villager_id())


# ---------------------------------------------------------------------------
# Story villager-ai-024 (AC5/AC6) — the roof: without it, the finished walls
# can never classify as a Room (CandidateCellRules.is_candidate_interior_cell
# requires a roofed cell, `max_room_height` directly above), so
# is_bed_sheltered() could never read true no matter how honest the wall
# construction above is. Driven through the SAME real
# RoofTool -> CommitPipeline -> ConstructionTickLoop chain as the walls —
# never a direct VoxelWorldGrid write, per this file's own honesty rules.
# ---------------------------------------------------------------------------

## Builds a flat roof ([enum RoofTool.Formation.FLAT], this sprint's only
## built formation) over the room's FULL outer footprint — one plane above
## the finished walls' own top layer ([method RoofTool.flat_roof_cell_set]'s
## own "press_cell.y + 1" rule, so passing the wall top's Y as the roof's
## `press_cell.y` lands it exactly one cell above the last wall layer,
## closing the walls in too, not merely capping the interior). Reports
## whether the interior now classifies as a Room via the REAL hosted
## [BuildValidation]'s own verdict (AC6) — never assumed from "the walls and
## roof both finished," always the actual classifier's own answer.
func _attempt_roof_stage(
	valley: Node,
	anchor: Vector3i,
	wall_height: int,
	villager: VillagerAi,
	build_editor_mode: BuildEditorMode,
	commit_pipeline: CommitPipeline,
	placement_pick: PlacementPick,
	build_project_registry: BuildProjectRegistry,
	villager_cell: Vector3i = _NO_GROUND_CELL,
) -> void:
	var roof_tool: RoofTool = valley.get_roof_tool()
	var roof_base: Vector3i = anchor + Vector3i(0, wall_height - 1, 0)
	var roof_far: Vector3i = roof_base + Vector3i(2, 0, 3)

	build_editor_mode.arm_tool(ToolStateMachine.TOOL_ID_ROOF)
	commit_pipeline.set_selected_item(WALL_MATERIAL_ID)
	placement_pick.resolve_pick(VoxelWorldGrid.cell_to_world(roof_base) + Vector3(0.0, 60.0, 0.0), Vector3.DOWN)
	if not placement_pick.get_current_pick().hit:
		print("payoff_loop_demo: REPORT — stage roof UNREACHABLE this run: no placement pick hit above the roof base %s." % str(roof_base))
		return

	var roof_candidate_cells: Array[Vector3i] = roof_tool.resolve_cell_set(true, roof_base, roof_far)
	var roof_cells: Array[BlueprintCell] = _commit_with_report(commit_pipeline, roof_candidate_cells)
	if roof_cells.is_empty():
		print("payoff_loop_demo: REPORT — stage roof UNREACHABLE this run: CommitPipeline.commit rejected the roof at %s (see the REJECTED line above for the exact reason). Not faking a roof." % str(roof_base))
		return

	print("payoff_loop_demo: REPORT — roof drafted: %d/%d cells on the plane one above the finished walls (y=%d)" % [
		roof_cells.size(), roof_candidate_cells.size(), roof_base.y + 1,
	])
	var released_ids: Array[int] = _release_projects_for(roof_cells, build_project_registry)
	print("payoff_loop_demo: REPORT — roof project(s) released: %s" % str(released_ids))

	await _wait_for_built(roof_cells, ROOF_WAIT_CAP_SEC, "roof", valley, villager, villager_cell)
	var built_roof_count: int = _count_built(roof_cells)
	print("payoff_loop_demo: REPORT — roof construction result: %d / %d cells reached BUILT" % [built_roof_count, roof_cells.size()])
	_report_scaffold_state("roof stage")

	if built_roof_count == roof_cells.size():
		await _shoot_through_game_camera("04b-roofed")
	else:
		print("payoff_loop_demo: REPORT — stage roof screenshot skipped: the roof did not finish inside its wait cap, so '04b-roofed' would not actually show a roofed room. Honesty over a picture.")

	# AC6: the demo's own report of whether the finished room actually
	# classifies as a Room now — the real hosted BuildValidation's own
	# verdict, never assumed from "walls + roof both finished."
	var build_validation: BuildValidation = valley.get_build_validation()
	if build_validation == null:
		print("payoff_loop_demo: REPORT — AC6: cannot check Room classification — BuildValidation is not hosted this run.")
		return
	var interior_cell: Vector3i = anchor + Vector3i(1, 0, 1)
	var verdict: BuildValidationReachability.Verdict = build_validation.get_region_status(interior_cell)
	var is_room: bool = verdict == BuildValidationReachability.Verdict.ROOM
	print("payoff_loop_demo: REPORT — AC6: interior cell %s classifies as a Room = %s (BuildValidation verdict = %s)." % [
		str(interior_cell), str(is_room), BuildValidationReachability.Verdict.keys()[verdict],
	])


# ---------------------------------------------------------------------------
# Story scene-009 — the payoff loop's last step: claim the bed, then sleep
# in it. Both stages are driven ENTIRELY by the villager's own real Rest
# need and the real, hosted FurnitureBedProvider/BuildValidation chain — this
# section claims nothing on the villager's behalf and writes no need value
# (Open Decision 1: the only acceleration is the real, player-facing
# TimeTickSystem.set_warp() already requested above, never a tool-written
# NeedsMood.set_need_value() — Open Decision 1(c), rejected).
# ---------------------------------------------------------------------------

## Edge-triggered sleep-episode recorder — called every frame every wait loop
## in this file spins (room-wall wait, bed wait, and the two stages below), so
## ANY SLEEPING episode this run passes through is captured, not only the one
## the sleep stage itself is waiting for (GDD D10's "the villager's first
## sleep is always unsheltered" pacing finding). Read-only: queries
## [method VillagerAi.get_state]/[method VillagerAi.get_owned_bed_cell] and the
## real, hosted [FurnitureBedProvider] — writes nothing.
func _sample_sleep_transition(valley: Node, villager: VillagerAi) -> void:
	var is_sleeping: bool = villager.get_state() == VillagerAi.State.SLEEPING
	if is_sleeping and not _was_sleeping_last_sample:
		var owned_bed: Variant = villager.get_owned_bed_cell()
		var sheltered: bool = false
		if owned_bed != null:
			var bed_provider: FurnitureBedProvider = valley.get_furniture_bed_provider()
			if bed_provider != null:
				sheltered = bed_provider.is_bed_sheltered(owned_bed)
		_sleep_event_log.append({
			"owned_bed": owned_bed,
			"sheltered": sheltered,
			"cell": villager.get_current_cell(),
		})
	_was_sleeping_last_sample = is_sleeping


## Prints every SLEEPING episode [method _sample_sleep_transition] recorded
## this run, distinguishing GROUND (no owned bed — GDD D10's "unsheltered
## first sleep" pacing finding) from BED episodes, and BED episodes'
## sheltered/unsheltered verdict — AC-D10-IS-REPORTED-NOT-SUPPRESSED: this
## story reports D10, it does not retune, suppress, or work around it.
func _report_sleep_event_log() -> void:
	if _sleep_event_log.is_empty():
		print("payoff_loop_demo: REPORT — D10 check: zero SLEEPING episodes observed this run.")
		return
	print("payoff_loop_demo: REPORT — D10 check: %d SLEEPING episode(s) observed this run:" % _sleep_event_log.size())
	for i in range(_sleep_event_log.size()):
		var entry: Dictionary = _sleep_event_log[i]
		if entry["owned_bed"] == null:
			# Say BEDLESS, never "GROUND". The old wording said "GROUND sleep",
			# meaning only "no bed owned" — and it was read literally, by me,
			# as "asleep on the ground". It was not: the cells were y=9 and y=10
			# against a build site at y=6, i.e. the villager was stranded on top
			# of its own structure. That misreading sent a pacing question to the
			# creative director that was never the real cause. A label that can
			# be read as a location must not describe an inventory fact.
			print("payoff_loop_demo: REPORT —   episode %d: BEDLESS sleep at cell %s (no bed owned — note the CELL, especially its height: a villager asleep above the build site is stranded, not merely tired)." % [
				i + 1, str(entry["cell"]),
			])
		else:
			print("payoff_loop_demo: REPORT —   episode %d: BED sleep at %s, sheltered=%s." % [
				i + 1, str(entry["owned_bed"]), str(entry["sheltered"]),
			])


## Drives stages 6 (claim) and 7 (sleep). Never advances the loop itself — the
## real TimeTickSystem/NeedsMood/VillagerAi already running under
## [constant DEMO_TIME_WARP] are the only things that move the villager toward
## a claim and a sheltered sleep. If a wait cap is hit, prints exactly why and
## returns without capturing the corresponding screenshot — never a picture
## that does not match its own report (the `05-furnished` precedent,
## generalized here to `06`/`07`).
func _attempt_claim_and_sleep_stages(
	valley: Node, villager: VillagerAi, build_project_registry: BuildProjectRegistry
) -> void:
	print("payoff_loop_demo: REPORT — need-trigger mechanism this run uses: (a) TimeTickSystem.set_warp(%d), the real player-facing time-warp control (already requested above) — never a tool-written NeedsMood.set_need_value() (Open Decision 1(c), rejected)." % DEMO_TIME_WARP)

	# ---- Stage 6: claim ---------------------------------------------------
	var claimed: Variant = await _wait_for_claim(valley, villager, CLAIM_WAIT_CAP_SEC)
	if claimed == null:
		print("payoff_loop_demo: REPORT — stage 6 (claim) NOT REACHED this run: villager id=%d has not claimed a bed within the %0.0fs wait cap (needs its own real Rest need to reach urgency — reported honestly, not assumed). Skipping '06-claimed' and stage 7 (sleep)." % [
			villager.get_villager_id(), CLAIM_WAIT_CAP_SEC,
		])
		return
	var claimed_cell: Vector3i = claimed

	var project_id: int = build_project_registry.project_at_cell(claimed_cell)
	print("payoff_loop_demo: REPORT — stage 6 (claim): villager id=%d claimed bed cell %s, owned by BuildProject id=%d." % [
		villager.get_villager_id(), str(claimed_cell), project_id,
	])
	if project_id != -1:
		var project: BuildProject = build_project_registry.get_project(project_id)
		var built_by_this_villager: bool = project != null and project.worker_ids.has(villager.get_villager_id())
		print("payoff_loop_demo: REPORT — stage 6 (claim): BuildProject id=%d worker_ids=%s — built by claiming villager id=%d: %s." % [
			project_id, str(project.worker_ids if project != null else []), villager.get_villager_id(), str(built_by_this_villager),
		])

	var bed_provider: FurnitureBedProvider = valley.get_furniture_bed_provider()
	var shelter_verdict: bool = bed_provider.is_bed_sheltered(claimed_cell) if bed_provider != null else false
	print("payoff_loop_demo: REPORT — stage 6 (claim): hosted BuildValidation's shelter verdict for %s (via the real FurnitureBedProvider) = %s." % [str(claimed_cell), str(shelter_verdict)])

	await _shoot_through_game_camera("06-claimed")

	# ---- Stage 7: sleep ----------------------------------------------------
	var reached_sleep: bool = await _wait_for_sleeping_at(valley, villager, claimed_cell, SLEEP_WAIT_CAP_SEC)
	var needs_mood: NeedsMood = valley.get_needs_mood()
	if not reached_sleep:
		print("payoff_loop_demo: REPORT — stage 7 (sleep) NOT REACHED this run: villager id=%d did not reach SLEEPING at its claimed bed cell %s (with sleep need_state RECOVERING) within the %0.0fs wait cap. Skipping '07-sleeping'. Honesty over a picture." % [
			villager.get_villager_id(), str(claimed_cell), SLEEP_WAIT_CAP_SEC,
		])
		return

	print("payoff_loop_demo: REPORT — stage 7 (sleep): villager id=%d is SLEEPING at %s, sleep need_state=%s." % [
		villager.get_villager_id(), str(claimed_cell), str(needs_mood.get_need_state(villager.get_villager_id(), &"sleep")),
	])

	await _report_recovery_rate(needs_mood, villager)
	await _shoot_through_game_camera("07-sleeping")


## Waits, real frame by real frame, until [method VillagerAi.has_owned_bed]
## reads `true`, or [param cap_sec] real seconds elapse. Returns the claimed
## cell, or `null` if the cap is hit first — never assumes a claim that did
## not happen. Samples [method _sample_sleep_transition] every frame so a
## GROUND (D10) sleep occurring while this stage waits is still recorded.
func _wait_for_claim(valley: Node, villager: VillagerAi, cap_sec: float) -> Variant:
	var start_usec: int = Time.get_ticks_usec()
	var deadline_usec: int = start_usec + int(cap_sec * 1000000.0)
	var last_report_usec: int = start_usec
	while true:
		_sample_sleep_transition(valley, villager)
		if villager.has_owned_bed():
			return villager.get_owned_bed_cell()
		var now_usec: int = Time.get_ticks_usec()
		if now_usec >= deadline_usec:
			return null
		if now_usec - last_report_usec >= 10000000:
			last_report_usec = now_usec
			print("payoff_loop_demo: REPORT — stage 6 (claim): still waiting for a real Rest-need-driven claim — %0.1fs elapsed, villager state=%s." % [
				(now_usec - start_usec) / 1000000.0, str(villager.get_state()),
			])
		await get_tree().process_frame
	# Unreachable: the loop above only exits via return. GDScript's static
	# analyser does not treat that as exhaustive, so without this line the
	# whole script fails to PARSE — which is how this tool sat broken in the
	# repo, committed but never once load()-ed.
	return null


## Waits until [param villager] reads [constant VillagerAi.State.SLEEPING] AT
## [param claimed_cell] specifically, with [method NeedsMood.get_need_state]
## reading [constant NeedsMood.NeedState.RECOVERING] for its `sleep` need —
## AC-SLEEP-STAGE-IS-REAL's own two-part observation, never merely "reached
## SLEEPING somewhere" (which a D10 ground-sleep episode can also produce).
func _wait_for_sleeping_at(valley: Node, villager: VillagerAi, claimed_cell: Vector3i, cap_sec: float) -> bool:
	var needs_mood: NeedsMood = valley.get_needs_mood()
	var start_usec: int = Time.get_ticks_usec()
	var deadline_usec: int = start_usec + int(cap_sec * 1000000.0)
	while true:
		_sample_sleep_transition(valley, villager)
		var at_claimed_bed: bool = (
			villager.get_state() == VillagerAi.State.SLEEPING
			and villager.get_current_cell() == claimed_cell
			and needs_mood.get_need_state(villager.get_villager_id(), &"sleep") == NeedsMood.NeedState.RECOVERING
		)
		if at_claimed_bed:
			return true
		if Time.get_ticks_usec() >= deadline_usec:
			return false
		await get_tree().process_frame
	# Unreachable, same reason as _wait_for_claim above.
	return false


## Samples the REAL, per-tick credited recovery rate by connecting a temporary
## listener directly to the real [signal TimeTickSystem.tick] broadcast (the
## SAME real Autoload every hosted module already binds to at boot — never a
## tool-owned clock) for up to [constant RECOVERY_SAMPLE_WAIT_CAP_SEC], then
## reports the observed per-tick delta against
## [member NeedsMoodConfig.base_recovery_per_tick_sleep] and
## [member NeedsMoodConfig.unsheltered_bed_multiplier] — BOTH read LIVE from
## the shipped config, never a literal (AC-RECOVERY-CREDITS-THE-SHELTERED-RATE).
func _report_recovery_rate(needs_mood: NeedsMood, villager: VillagerAi) -> void:
	var time_tick_system: Object = get_node_or_null(^"/root/TimeTickSystem")
	if time_tick_system == null or not time_tick_system.has_signal(&"tick"):
		print("payoff_loop_demo: REPORT — stage 7 (sleep): cannot sample the credited recovery rate — the real TimeTickSystem Autoload is unreachable.")
		return

	var samples: Array[float] = []
	var sampler := func() -> void:
		samples.append(needs_mood.get_need_value(villager.get_villager_id(), &"sleep"))
	time_tick_system.tick.connect(sampler)

	var start_usec: int = Time.get_ticks_usec()
	var deadline_usec: int = start_usec + int(RECOVERY_SAMPLE_WAIT_CAP_SEC * 1000000.0)
	while samples.size() < 3 and Time.get_ticks_usec() < deadline_usec:
		await get_tree().process_frame

	time_tick_system.tick.disconnect(sampler)

	if samples.size() < 2:
		print("payoff_loop_demo: REPORT — stage 7 (sleep): fewer than 2 real ticks observed while Recovering inside the %0.0fs sample cap — cannot report a per-tick rate." % RECOVERY_SAMPLE_WAIT_CAP_SEC)
		return

	var config: NeedsMoodConfig = needs_mood.config
	var sheltered_rate: float = config.base_recovery_per_tick_sleep
	var unsheltered_rate: float = config.base_recovery_per_tick_sleep * config.unsheltered_bed_multiplier
	var observed_delta: float = samples[samples.size() - 1] - samples[samples.size() - 2]
	var matches_sheltered: bool = is_equal_approx(observed_delta, sheltered_rate)
	var matches_unsheltered: bool = is_equal_approx(observed_delta, unsheltered_rate)
	print(
		"payoff_loop_demo: REPORT — stage 7 (sleep): credited per-tick recovery delta = %0.4f. Shipped config: base_recovery_per_tick_sleep (sheltered, x1.0) = %0.4f, unsheltered (x%0.2f) = %0.4f. Matches SHELTERED: %s. Matches UNSHELTERED: %s." % [
			observed_delta, sheltered_rate, config.unsheltered_bed_multiplier, unsheltered_rate, str(matches_sheltered), str(matches_unsheltered),
		]
	)


# ---------------------------------------------------------------------------
# Build-site geometry — a small room, outer footprint 3 (X) x 4 (Z), interior
# exactly 1 (X) x 2 (Z): the smallest footprint that both reads as a real
# room and fits a real 1x2 bed without any cell overlap between the four
# wall-tool drag segments (overlapping segments would reject each other via
# CommitPipeline's own CELL_OCCUPIED gate — this geometry avoids that by
# construction, never by suppressing the check).
# ---------------------------------------------------------------------------

## Every wall-tool drag segment (press, release) needed to enclose the room's
## perimeter with zero cell overlap between segments — south and north rows
## carry both corners each; west and east columns carry only the two
## interior-z cells, deliberately excluding the corners the north/south rows
## already drafted.
func _wall_segments(anchor: Vector3i) -> Array:
	var ax: int = anchor.x
	var ay: int = anchor.y
	var az: int = anchor.z
	return [
		[Vector3i(ax, ay, az), Vector3i(ax + 2, ay, az)],
		[Vector3i(ax, ay, az + 3), Vector3i(ax + 2, ay, az + 3)],
		[Vector3i(ax, ay, az + 1), Vector3i(ax, ay, az + 2)],
		[Vector3i(ax + 2, ay, az + 1), Vector3i(ax + 2, ay, az + 2)],
	]


## The 10 perimeter footprint cells (one Y layer) that make up the room's
## outer ring — used both for the clear-site search and to describe the
## geometry above.
func _perimeter_footprint_cells(anchor: Vector3i) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	for dx: int in range(3):
		cells.append(anchor + Vector3i(dx, 0, 0))
		cells.append(anchor + Vector3i(dx, 0, 3))
	for dz: int in [1, 2]:
		cells.append(anchor + Vector3i(0, 0, dz))
		cells.append(anchor + Vector3i(2, 0, dz))
	return cells


## Searches a handful of candidate anchors near [param villager_cell] (same Y)
## for one whose ENTIRE room footprint (perimeter ring x wall_height, plus
## both interior bed cells and their ground support) currently reads clear in
## the REAL, already-generated Voxel World grid — a real player would look
## for a clear patch of ground the same way; this is that same judgment,
## automated. Returns the first candidate anyway if none is fully clear
## (`"clear": false`), so the tool always proceeds and lets the real commit
## gate report the truth rather than stalling on a perfect site.
func _find_build_site(villager_cell: Vector3i, wall_height: int, voxel_world: VoxelWorldGrid) -> Dictionary:
	var offsets: Array[Vector3i] = [
		Vector3i(3, 0, -1), Vector3i(4, 0, -1), Vector3i(-6, 0, -1),
		Vector3i(0, 0, 4), Vector3i(0, 0, -7), Vector3i(3, 0, 3), Vector3i(-4, 0, -4),
	]
	var fallback: Vector3i = villager_cell + offsets[0]
	var tries: int = 0
	for offset: Vector3i in offsets:
		tries += 1
		var anchor: Vector3i = villager_cell + offset
		if _site_is_clear(anchor, wall_height, voxel_world):
			return {"anchor": anchor, "clear": true, "tries": tries}
	return {"anchor": fallback, "clear": false, "tries": tries}


func _site_is_clear(anchor: Vector3i, wall_height: int, voxel_world: VoxelWorldGrid) -> bool:
	for footprint_cell: Vector3i in _perimeter_footprint_cells(anchor):
		for h: int in range(wall_height):
			var cell: Vector3i = footprint_cell + Vector3i(0, h, 0)
			if not voxel_world.is_in_bounds(cell) or not voxel_world.get_cell(cell).is_empty():
				return false
	var interior_cells: Array[Vector3i] = [anchor + Vector3i(1, 0, 1), anchor + Vector3i(1, 0, 2)]
	for interior_cell: Vector3i in interior_cells:
		if not voxel_world.is_in_bounds(interior_cell) or not voxel_world.get_cell(interior_cell).is_empty():
			return false
		var ground_cell: Vector3i = interior_cell + Vector3i(0, -1, 0)
		if not voxel_world.is_in_bounds(ground_cell) or voxel_world.get_cell(ground_cell).is_empty():
			return false
	return true


# ---------------------------------------------------------------------------
# Screenshot capture — always through the SHIPPED camera, never a tool camera.
# ---------------------------------------------------------------------------

## Captures through the real, hosted [Camera3D] ([method Valley.get_valley_camera]
## since cam-013) — this tool owns no camera of its own and supplies no
## lighting or ground plane (presentation-004 AC6). Prints WHY and returns
## without saving anything if the shipped scene hosts no camera, rather than
## silently substituting one.
func _shoot_through_game_camera(name_stem: String) -> void:
	var valley: Node = _world.get_valley() if _world.has_method("get_valley") else null
	var game_camera: Camera3D = _find_camera(valley) if valley != null else null
	if game_camera == null:
		print("payoff_loop_demo: REPORT — cannot capture '%s': the shipped scene hosts no camera right now." % name_stem)
		return
	game_camera.current = true
	# Force the just-panned camera's own frame to be the one rendered — same
	# "await or the last camera position wins" discipline as every other
	# capture tool in this directory.
	await RenderingServer.frame_post_draw
	_save(get_viewport().get_texture().get_image(), name_stem)


func _find_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node as Camera3D
	for child: Node in node.get_children():
		var found: Camera3D = _find_camera(child)
		if found != null:
			return found
	return null


## Story villager-ai-025 Anti-Vacuity Lever 2 (ROOF) -- see [method _run_demo]'s
## own call-site comment. AC1's own wording, verbatim: "after ANY construction
## job completes, the claiming villager has a path back to standable
## settlement ground." [param settlement_ground_cell] is the villager's own
## pre-build spawn cell (captured once, before anything was built) -- a real,
## verified-standable cell, deliberately independent of any production API
## this story's own fix might add, so this diagnostic compares identically
## pre-fix and post-fix.
func _report_roof_descent_lever(valley: Node, villager: VillagerAi, settlement_ground_cell: Vector3i) -> void:
	var nav_graph: VillagerNavGraph = valley.get_villager_nav_graph() if valley.has_method("get_villager_nav_graph") else null
	if nav_graph == null:
		print("payoff_loop_demo: REPORT — ROOFDESCENT lever (villager-ai-025): no nav graph hosted, cannot check.")
		return
	var villager_cell_now: Vector3i = villager.get_current_cell()
	var path: Array[Vector3i] = nav_graph.find_path(villager_cell_now, settlement_ground_cell)
	print("payoff_loop_demo: REPORT — ROOFDESCENT lever (villager-ai-025 AC1/AC2): villager=%s state=%d find_path(villager, settlement_ground=%s).size()=%d empty=%s" % [
		str(villager_cell_now), villager.get_state(), str(settlement_ground_cell), path.size(), str(path.is_empty()),
	])


func _save(image: Image, name_stem: String) -> void:
	var evidence_dir: String = ProjectSettings.globalize_path(EVIDENCE_DIR)
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	var path: String = "%s/%s.png" % [evidence_dir, name_stem]
	var err: Error = image.save_png(path)
	if err != OK:
		push_warning("payoff_loop_demo: save failed (%d) for %s" % [err, path])
		return
	print("payoff_loop_demo: saved %s" % path)


## DIAGNOSTIC (2026-07-28): did scaffolding ever serve the ROOF, or did the
## villager get up there through ADR-0009's climb mutation instead?
##
## The roof has stalled at 10/12 across two runs, with the villager asleep at
## y=10 — on top of the roof plane, unable to descend. Three hypotheses read
## plausibly and all three were refuted by bisect, so this run measures instead
## of guessing. Non-zero counters mean the climb hack carried the villager up
## and scaffolding never served the roof at all — which would move the defect
## from the dismantle side to the erection trigger.
func _report_climb_telemetry() -> void:
	var valley: Node = _world.get_valley() if _world.has_method("get_valley") else null
	if valley == null or not valley.has_method("get_villager_unstuck_telemetry"):
		print("payoff_loop_demo: REPORT — climb telemetry unavailable (no accessor)")
		return
	var telemetry: Object = valley.get_villager_unstuck_telemetry()
	if telemetry == null:
		print("payoff_loop_demo: REPORT — climb telemetry unavailable (null)")
		return
	@warning_ignore("unsafe_method_access")
	print("payoff_loop_demo: REPORT — ADR-0009 climb mutations this run: self_seal_climb=%d marooned_relocation=%d (both MUST be 0 once scaffolding serves every reachable-by-construction cell)" % [
		telemetry.get_self_seal_climb_total(), telemetry.get_marooned_relocation_total(),
	])


## DIAGNOSTIC companion: what the scaffold registry actually holds at a given
## stage. Empty during the roof stage would say the erection trigger never fires
## for roof cells — either the persistence gate is never satisfied for them, or
## no supported column exists within the cantilever limit above a finished room.
func _report_scaffold_state(stage_label: String) -> void:
	var valley: Node = _world.get_valley() if _world.has_method("get_valley") else null
	if valley == null or not valley.has_method("get_scaffold_registry"):
		return
	var registry: Object = valley.get_scaffold_registry()
	if registry == null:
		print("payoff_loop_demo: REPORT — scaffold registry unavailable at %s" % stage_label)
		return
	@warning_ignore("unsafe_method_access")
	var cells: Array = registry.get_cells()
	print("payoff_loop_demo: REPORT — scaffold cells standing at %s: %d %s" % [
		stage_label, cells.size(), str(cells.slice(0, mini(8, cells.size()))),
	])
