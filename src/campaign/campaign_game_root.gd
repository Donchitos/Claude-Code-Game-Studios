class_name CampaignGameRoot
extends Control
## Persistent normal-game owner. Campaign saves deliberately use their own domain.
const UI = preload("res://src/campaign/campaign_ui.gd")
const Audio = preload("res://src/campaign/campaign_audio.gd")
const Storage = preload("res://src/persistence/save_system.gd")
var catalog: Dictionary = {}
var profile: RefCounted
var profile_ready := false
var quitting := false
var arena: Node2D
var world: Node2D
var camera: Camera2D
var ui: Control
var audio: Node
var storage: Node
var input_system: ProductionInputSystem
var context: PcMovementContext
var carrier: ProductionMovementIntentCarrier
var page := "home"
var modal := ""
var tick := 0
var generation := 0
var paused := false
var focused := true
var autosave_clock := 0.0
var last_result: Dictionary = {}
var last_mission := 0
var selected_pill := ""
var error := ""
var selected_challenge := ""
var persistence_blocked := false
var hud_clock := 0.0

func _ready() -> void:
	Input.use_accumulated_input = false
	PcMetaInput.install()
	get_tree().auto_accept_quit = false
	world = Node2D.new()
	add_child(world)
	camera = Camera2D.new()
	world.add_child(camera)
	get_viewport().size_changed.connect(_update_camera_view)
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = UI.new()
	layer.add_child(ui)
	ui.initialize(self)
	audio = Audio.new()
	add_child(audio)
	get_window().focus_exited.connect(_focus_lost)
	get_window().focus_entered.connect(_focus_gained)
	Input.joy_connection_changed.connect(_joy_changed)
	if not ResourceLoader.exists("res://src/campaign/campaign_catalog.gd") or not ResourceLoader.exists("res://src/campaign/campaign_profile.gd"):
		fail("战役模块尚未就绪 / Campaign modules unavailable")
		return
	catalog = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var errors: Array = load("res://src/campaign/campaign_catalog.gd").validate(catalog)
	if not errors.is_empty():
		fail(str(errors))
		return
	storage = Storage.new()
	add_child(storage)
	var memory := DisplayServer.get_name() == "headless" or "--campaign-validation" in OS.get_cmdline_user_args()
	var status: int = storage.initialize("" if memory else "user://campaign_game_a.save", "" if memory else "user://campaign_game_b.save", {})
	if status != 0:
		fail("存档读取失败，保留原档 / Save unavailable; original retained")
		return
	profile = load("res://src/campaign/campaign_profile.gd").new()
	if not profile.initialize(catalog, storage):
		fail(profile.error)
		return
	profile_ready = true
	_apply_preferences()
	show_page("home")
	print("CAMPAIGN_MAIN_BOOT_OK CAMPAIGN_GAMEPLAY_V1")

## Opens a non-battle page without bypassing an active modal or discarding a run.
func show_page(name: String) -> void:
	if arena != null or not modal.is_empty() or persistence_blocked or not profile_ready:
		return
	page = name
	ui.render(name)
	if profile != null:
		audio.apply_settings(profile.data.settings)
	audio.music("menu")

## Persists a new run before creating its playable arena.
func start_mission(index: int, pillid: String = "") -> bool:
	if not profile_ready or profile == null or arena != null or not modal.is_empty() or persistence_blocked:
		return false
	var result: Dictionary = profile.begin_run(index, pillid, selected_challenge)
	if result.get("status") != "OK":
		fail(profile.error)
		return false
	return continue_run()

## Restores the persisted seed or validates a full snapshot without replacing it.
func continue_run() -> bool:
	if not profile_ready or profile == null or arena != null or profile.data.current_run == null or persistence_blocked:
		return false
	var run: Dictionary = profile.data.current_run
	var saved: Dictionary = run.get("snapshot", {})
	if not saved.is_empty() and (saved.get("loadout", {}) != run.loadout or str(saved.get("rng_seed", "")).to_int() != str(run.seed).to_int()):
		fail("本局身份不一致；保留存档 / Saved run identity mismatch; save retained")
		return false
	var candidate: Node2D = load("res://src/campaign/campaign_arena.gd").new()
	if not candidate.configure(catalog, catalog.missions[int(run.mission_index)], run.loadout, int(run.seed), run.get("snapshot", {})):
		candidate.free()
		fail("本局状态无法恢复；存档已保留 / Invalid run snapshot; save retained")
		return false
	arena = candidate
	world.add_child(arena)
	_apply_preferences()
	generation += 1
	context = PcMovementContext.new()
	context.battle_generation = generation
	carrier = ProductionMovementIntentCarrier.new()
	input_system = ProductionInputSystem.new()
	add_child(input_system)
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/config/production_defaults.json"))
	if input_system.initialize(config.input, carrier, context) != 0:
		_destroy_arena()
		fail("输入初始化失败 / Input initialization failed")
		return false
	if input_system.activate() != 0:
		fail("输入激活失败 / Input activation failed")
		return false
	last_mission = int(run.mission_index)
	page = "battle"
	paused = false
	modal = ""
	autosave_clock = 0
	camera.position = arena.player_world_position()
	_update_camera_view()
	ui.render("battle")
	audio.music("boss" if str(catalog.missions[last_mission].kind).to_upper() == "BOSS" else "battle")
	_sync_battle()
	if not focused:
		pause_battle()
	return true

## Keep the visible world inside the deterministic spawn exclusion envelope.
func _update_camera_view() -> void:
	if camera == null: return
	var factor := 1.0
	if is_instance_valid(arena) and arena.mission.has("spawn_view_size"):
		var extent: Array = arena.mission.spawn_view_size
		var viewport_size := get_viewport_rect().size
		factor = maxf(1.0,maxf(viewport_size.x/float(extent[0]),viewport_size.y/float(extent[1])))
	camera.zoom = Vector2.ONE*factor
	camera.force_update_scroll()

## Locks movement before exposing the pause overlay.
func pause_battle() -> void:
	if arena == null or paused:
		return
	if not _lock():
		return
	modal = "pause"
	ui.overlay(modal)

## Resumes only a pause overlay, with the input system's fresh-neutral barrier.
func resume_battle() -> void:
	if arena == null or modal != "pause" or not focused:
		return
	_resume()

## Saves the complete tick and pending choices before removing the battle.
func save_and_home() -> bool:
	if arena == null:
		return false
	if not _lock():
		return false
	if not profile.save_run(arena.snapshot()):
		fail(profile.error)
		return false
	_destroy_arena()
	show_page("home")
	return true

## Applies profile commands only through the transactional public interface.
func command(method: String, value: Variant) -> void:
	if persistence_blocked or not profile_ready:
		return
	if not profile.call(method, value):
		fail(profile.error)
		return
	_apply_preferences()
	ui.render(page)
	if not modal.is_empty():
		ui.overlay(modal)

## Commits a pending choice and its full snapshot before reopening movement.
func choose(value: Variant) -> void:
	if arena == null or modal not in ["upgrade", "event"]:
		return
	var ok: bool = arena.choose_upgrade(str(value)) if modal == "upgrade" else arena.choose_event(bool(value))
	if not ok:
		return
	if not profile.save_run(arena.snapshot()):
		fail(profile.error)
		return
	_resume()
	_sync_battle()

## Presents persistence or validation failure without reporting success.
func fail(message: String) -> void:
	error = message
	if profile != null and profile.is_storage_locked():
		persistence_blocked = true
	if arena != null:
		_lock()
	modal = "error"
	ui.overlay("error")
	push_warning(message)

## Dismisses an error into a safe paused state, allowing save retry.
func dismiss_error() -> void:
	if persistence_blocked:
		return
	error = ""
	modal = "pause" if arena != null else ""
	if arena != null:
		ui.overlay("pause")
	else:
		ui.render(page)

## Window and menu exit share the same complete snapshot transaction.
func quit_game() -> void:
	if quitting:
		return
	if arena != null:
		if not _lock():
			return
		if not profile.save_run(arena.snapshot()):
			fail(profile.error)
			return
	quitting = true
	audio.shutdown()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _physics_process(delta: float) -> void:
	if arena == null or paused:
		return
	hud_clock -= delta
	tick += 1
	if not context.begin(tick):
		fail("输入时序错误 / Input lease failure")
		return
	if input_system.run_phase(&"MOVEMENT_COMMIT", context, context.lease_id) != 0:
		fail("输入提交失败 / Input commit failure")
		return
	arena.advance(delta, carrier.direction)
	context.consumed = true
	if not context.finish():
		fail("输入关闭失败 / Input lease finish failed")
		return
	if arena.mission.get("chapter_c",false) and arena.state.encounter.chapter.error != "":
		fail(arena.state.encounter.chapter.error)
		return
	camera.position = arena.player_world_position()
	_update_camera_view()
	for event: String in arena.sound_events:
		audio.effect(event)
	arena.sound_events.clear()
	autosave_clock += delta
	if autosave_clock >= float(catalog.tuning.get("save_interval", 15)):
		autosave_clock = 0
		if not profile.save_run(arena.snapshot()):
			fail(profile.error)
			return
	_sync_battle()

func _sync_battle() -> void:
	if arena == null:
		return
	if hud_clock <= 0:
		ui.update_hud()
		hud_clock = 0.1
	if arena.state.finished:
		if not _lock():
			return
		var victory: bool = arena.state.victory
		var stats: Dictionary = arena.stats()
		last_result = profile.finish_run(victory, stats)
		if last_result.get("status") != "OK":
			fail(profile.error)
			return
		last_result["victory"] = victory
		last_result["stats"] = stats
		_destroy_arena()
		show_page("result")
		audio.effect("win" if victory else "lose")
	elif not arena.state.offered.is_empty() or str(arena.state.event_id) != "":
		if not _lock():
			return
		modal = "upgrade" if not arena.state.offered.is_empty() else "event"
		if not profile.save_run(arena.snapshot()):
			fail(profile.error)
			return
		ui.overlay(modal)

func _lock() -> bool:
	if not paused and input_system != null:
		paused = true
		if input_system.lock_for_pause(tick) != 0 or input_system.confirm_paused() != 0:
			fail("输入暂停屏障失败 / Input pause barrier failed")
			return false
	paused = true
	return true

func _resume() -> void:
	if not focused or persistence_blocked:
		return
	if input_system.prepare_resume() != 0 or input_system.activate() != 0:
		fail("输入恢复屏障失败 / Input resume barrier failed")
		return
	paused = false
	modal = ""
	ui.render("battle")

func _destroy_arena() -> void:
	if input_system != null:
		input_system.teardown()
		input_system.queue_free()
		input_system = null
	if arena != null:
		world.remove_child(arena)
		arena.queue_free()
		arena = null
	paused = false
	modal = ""

func _input(event: InputEvent) -> void:
	var action := PcMetaInput.action_for(event)
	if action == &"" or not focused:
		return
	get_viewport().set_input_as_handled()
	if action == &"pc_pause":
		if modal.is_empty():
			pause_battle()
	elif action in [&"pc_resume", &"ui_back"]:
		if modal == "pause":
			resume_battle()
		elif modal == "abandon" and action == &"ui_back":
			cancel_abandon()
		elif modal.is_empty() and action == &"ui_back":
			if arena != null:
				pause_battle()
			else:
				show_page("home")
	else:
		ui.navigate(action)

func _focus_lost() -> void:
	focused = false
	pause_battle()
	if input_system != null:
		input_system.set_focused(false)

func _focus_gained() -> void:
	focused = true
	if input_system != null:
		input_system.set_focused(true)

func _joy_changed(_device: int, _connected: bool) -> void:
	if input_system != null:
		input_system.invalidate_sources()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

## Starts a catalog challenge on its authored mission through the profile transaction.
func start_challenge(id: String) -> bool:
	for challenge: Dictionary in catalog.challenges:
		if challenge.id == id:
			for i in catalog.missions.size():
				if catalog.missions[i].id == challenge.mission_id:
					selected_challenge = id
					var result := start_mission(i, "" if not challenge.allow_pills else selected_pill)
					selected_challenge = ""
					return result
	return false

## Persists replacement upgrade candidates before presenting them.
func reroll() -> void:
	if persistence_blocked or arena == null or modal != "upgrade":
		return
	if arena.reroll_upgrades():
		if not profile.save_run(arena.snapshot()):
			fail(profile.error)
			return
		ui.overlay("upgrade")

## Reloads the committed storage state after a failed transaction; never retries rewards.
func reload_profile() -> void:
	_destroy_arena()
	var memory := DisplayServer.get_name() == "headless" or "--campaign-validation" in OS.get_cmdline_user_args()
	var candidate_storage: Node = storage
	if not memory:
		candidate_storage = Storage.new()
		add_child(candidate_storage)
		if candidate_storage.initialize("user://campaign_game_a.save", "user://campaign_game_b.save", {}) != 0:
			candidate_storage.queue_free()
			fail("STORAGE_UNAVAILABLE_RELOAD_REQUIRED")
			return
	var candidate: RefCounted = load("res://src/campaign/campaign_profile.gd").new()
	if not candidate.initialize(catalog, candidate_storage):
		if candidate_storage != storage:
			candidate_storage.queue_free()
		fail(candidate.error)
		return
	if candidate_storage != storage:
		storage.queue_free()
		storage = candidate_storage
	profile = candidate
	profile_ready = true
	_apply_preferences()
	persistence_blocked = false
	error = ""
	modal = ""
	show_page("home")

func _exit_tree() -> void:
	if input_system != null:
		input_system.teardown()

## Requires an explicit in-game confirmation before discarding a persisted run.
func request_abandon() -> void:
	if arena == null and modal.is_empty() and not persistence_blocked:
		modal = "abandon"
		ui.overlay("abandon")

## Cancels the destructive in-game choice without changing profile state.
func cancel_abandon() -> void:
	if modal == "abandon":
		modal = ""
		show_page("home")

## Commits the user-confirmed abandon transaction before showing a new start.
func abandon_current_run() -> void:
	if modal != "abandon" or persistence_blocked:
		return
	if not profile.abandon_run():
		fail(profile.error)
		return
	modal = ""
	show_page("home")

func _apply_preferences() -> void:
	if not profile_ready:
		return
	var settings: Dictionary = profile.data.settings
	audio.apply_settings(settings)
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.get("fullscreen", false) else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
	if arena != null:
		arena.reduce_motion = bool(settings.reduce_motion)
