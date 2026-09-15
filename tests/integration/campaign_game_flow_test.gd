extends SceneTree
## Real root lifecycle test. No direct victory, XP or profile state assignments.
class FaultProxy extends Node:
	var backing: Node
	func profile_snapshot() -> Dictionary:
		return backing.profile_snapshot()
	func commit_domain_after_images(_images: Dictionary) -> int:
		return 1

var failures := 0
var checks := 0
var game: Control
func _initialize() -> void:
	_run.call_deferred()
func _expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMPAIGN_FLOW_FAIL " + label)
func _run() -> void:
	var c = load("res://src/campaign/campaign_catalog.gd")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(c.PATH))
	print("CATALOG_ERRORS ", c.validate(raw), " hash=", FileAccess.get_file_as_string(c.PATH).sha256_text())
	game = load("res://src/campaign/CampaignGame.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_expect(game.profile != null and game.error.is_empty(), "normal boot")
	if game.profile == null:
		quit(1)
		return
	_expect(game.audio.streams.size() == 11, "all imported audio resources")
	for cue: String in game.audio.streams:
		_expect(game.audio.streams[cue] != null and game.audio.streams[cue].get_length() > 0, "audio " + cue)
	game.set_physics_process(false)
	game.command("update_settings", {"master": 0.0})
	game.command("update_settings", {"fullscreen": true, "reduce_motion": true})
	_expect(game.profile.data.settings.fullscreen, "fullscreen saved")
	game.command("update_settings", {"fullscreen": false})
	game.show_page("codex")
	await process_frame
	_expect(game.ui.buttons.size() > 100, "codex cards keyboard reachable")
	game.ui.buttons[-1].grab_focus()
	await process_frame
	await process_frame
	var scroll: ScrollContainer = game.ui.content.get_parent()
	_expect(scroll.scroll_vertical > 0, "codex focus scrolls to tail")
	game.show_page("challenges")
	_expect(game.ui.buttons.size() >= 85, "achievement cards keyboard reachable")
	game.ui.data.stats.character_wins["S1-C01"] = 2
	_expect(game.ui.achievement_progress({"stat": "character_win", "id": "S1-C01"}) == 2, "ID-specific progress alias")
	var healthy_profile: RefCounted = game.profile
	var bad_storage: Node = load("res://src/persistence/save_system.gd").new()
	bad_storage.initialize()
	bad_storage.commit_domain_after_images({"campaign_game": {"schema": -1}})
	var bad_profile: RefCounted = load("res://src/campaign/campaign_profile.gd").new()
	_expect(not bad_profile.initialize(game.catalog, bad_storage), "corrupt domain refused")
	game.profile = bad_profile
	game.profile_ready = false
	game.fail(bad_profile.error)
	_expect(game.modal == "error" and game.ui.buttons.size() >= 2, "uninitialized profile error UI safe")
	game.profile = healthy_profile
	game.profile_ready = true
	game.modal = ""
	game.error = ""
	bad_storage.free()
	game.show_page("home")
	seed(9214)
	_expect(game.start_mission(0), "persisted start")
	if game.arena == null:
		quit(1)
		return
	_expect(game.arena.reduce_motion, "reduce motion reaches renderer")
	for i in 10:
		game._physics_process(1.0 / 60)
	game.pause_battle()
	_expect(game.paused and game.modal == "pause" and game.input_system.state == ProductionInputSystem.State.FROZEN, "pause barrier")
	var saved: Dictionary = game.arena.snapshot()
	_inspect_json(saved, "snapshot")
	_expect(game.save_and_home() and game.arena == null, "save exit")
	_expect(game.continue_run(), "resume snapshot")
	_expect(game.arena.snapshot() == saved, "exact snapshot restored")
	game.pause_battle()
	game._focus_lost()
	game._focus_gained()
	_expect(game.paused, "refocus does not resume")
	game.resume_battle()
	_expect(not game.paused, "manual resume")
	var choices := 0
	var events := 0
	for i in 24000:
		if game.arena == null:
			break
		if game.modal == "upgrade":
			choices += 1
			_release_movement()
			game.choose(game.arena.state.offered[0])
			game._physics_process(1.0 / 60)
		elif game.modal == "event":
			events += 1
			_release_movement()
			game.choose(false)
			game._physics_process(1.0 / 60)
		elif game.modal == "error":
			break
		# Actual production tick, stationary strategy, no direct state mutation.
		game._physics_process(1.0 / 60)
		if i % 120 == 0:
			await process_frame
	_expect(game.arena == null and game.page == "result", "natural battle resolves")
	print("NATURAL_RESULT ", game.last_result, " choices=", choices, " events=", events)
	seed(9215)
	_expect(game.start_mission(0), "retry after natural result")
	for i in 18000:
		if game.arena == null:
			break
		if game.modal == "upgrade":
			_release_movement()
			game.choose(game.arena.state.offered[0])
			game._physics_process(1.0 / 60)
		elif game.modal == "event":
			_release_movement()
			game.choose(false)
			game._physics_process(1.0 / 60)
		elif game.modal == "error":
			break
		var pos: Vector2 = game.arena.player_world_position()
		var target: Array = game.catalog.missions[0].target_positions[0]
		var target_seconds := float(game.catalog.missions[0].target_seconds)
		var goal := Vector2(target[0], target[1])
		if float(game.arena.state.elapsed) < target_seconds:
			goal = Vector2(cos(i * .003), sin(i * .003)) * 300
			var nearest := INF
			for pickup: Dictionary in game.arena.state.pickups:
				var point := Vector2(pickup.x, pickup.y)
				if pos.distance_squared_to(point) < nearest:
					nearest = pos.distance_squared_to(point)
					goal = point
		var direction := pos.direction_to(goal)
		for enemy: Dictionary in game.arena.state.entities:
			var offset := pos - Vector2(enemy.x, enemy.y)
			if float(game.arena.state.elapsed) < target_seconds and offset.length() < 110 and offset.length() > 0:
				direction += offset.normalized() * (110 - offset.length()) / 25
		for rock: Dictionary in game.arena.state.obstacles:
			var toward := Vector2(rock.x, rock.y) - pos
			if toward.length() < float(rock.radius) + 80 and direction.dot(toward.normalized()) > 0:
				direction += toward.normalized().orthogonal() * 1.6 - toward.normalized() * .5
		for pair in [["move_left", direction.x < -.2], ["move_right", direction.x > .2], ["move_up", direction.y < -.2], ["move_down", direction.y > .2]]:
			if pair[1]:
				_key_event(pair[0], true)
			else:
				_key_event(pair[0], false)
		game._physics_process(1.0 / 60)
		if i % 120 == 0:
			await process_frame
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		_key_event(action, false)
	print("BOT_NATURAL_RESULT ", game.last_result)
	_expect(game.arena == null and game.last_result.get("victory", false), "input-driven natural extraction victory")
	_expect(game.profile.data.completed == 1, "first-clear unlock persisted")
	for page in ["home", "chapters", "characters", "cultivation", "codex", "challenges", "settings", "ending"]:
		game.show_page(page)
		await process_frame
		_expect(game.ui.buttons.size() > 0, "page " + page)
	if game.arena == null:
		var proxy := FaultProxy.new()
		proxy.backing = game.storage
		var locked_profile: RefCounted = load("res://src/campaign/campaign_profile.gd").new()
		_expect(locked_profile.initialize(game.catalog, proxy), "fault fixture loaded committed domain")
		game.profile = locked_profile
		game.command("update_settings", {"music": 0.2})
		_expect(game.persistence_blocked and game.modal == "error", "IO failure locks UI")
		var previous: String = game.page
		game.show_page("home")
		_expect(game.page == previous, "IO failure blocks navigation")
		game.reload_profile()
		_expect(not game.persistence_blocked and game.profile_ready and game.modal.is_empty(), "reload committed domain after IO failure")
		proxy.free()
	print("CAMPAIGN_FLOW checks=", checks, " failures=", failures)
	game.audio.shutdown()
	await create_timer(0.1).timeout
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

func _inspect_json(value: Variant, path: String) -> void:
	if value is Dictionary:
		for key in value:
			if not key is String: print("BAD_JSON_KEY ", path, " ", key, " type=", typeof(key))
			_inspect_json(value[key], path + "." + str(key))
	elif value is Array:
		for i in value.size(): _inspect_json(value[i], path + "[" + str(i) + "]")
	elif value is float or value is int:
		if not is_finite(float(value)) or abs(float(value)) > 9007199254740991: print("BAD_JSON_NUMBER ", path, " ", value)
	elif value != null and not value is bool and not value is String:
		print("BAD_JSON_VALUE ", path, " ", value, " type=", typeof(value))

func _release_movement() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		_key_event(action, false)

func _key_event(action: String, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = {"move_left": KEY_A, "move_right": KEY_D, "move_up": KEY_W, "move_down": KEY_S}[action]
	event.keycode = event.physical_keycode
	event.pressed = pressed
	Input.parse_input_event(event)
