extends SceneTree
## Unit tests for EventDeck: 10 event types, premonition-active-cleanup lifecycle, and resource freeing.

const EventDeckScript = preload("res://src/world/events/event_deck.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred(&"_run_tests")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)


func _run_tests() -> void:
	var deck = EventDeckScript.new()

	# 1. Initialization
	_check(deck.active_event == -1, "Deck starts with no active event")

	# 2. Event lifecycle (Premonition -> Active -> Cleanup)
	var warning_seen := [false, ""]
	deck.event_warning.connect(func(n, p):
		warning_seen[0] = true
		warning_seen[1] = p
	)
	var started_seen := [false]
	deck.event_started.connect(func(n, d): started_seen[0] = true)

	deck.trigger_event(EventDeckScript.EventType.FIRE_OUTBREAK, 6.0)
	_check(warning_seen[0] and warning_seen[1].contains("aşırı ısı"), "Premonition warning emitted immediately")
	_check(not started_seen[0], "Event does not activate during premonition grace period")

	# Advance through premonition (2.5s)
	deck.advance(2.6)
	_check(started_seen[0], "Event officially starts after premonition timer expires")

	# 3. Harmless event distinction
	_check(deck.is_harmless(EventDeckScript.EventType.FALSE_ALARM), "False Alarm is classified harmless")
	_check(deck.is_harmless(EventDeckScript.EventType.CONFETTI), "Confetti is classified harmless")
	_check(not deck.is_harmless(EventDeckScript.EventType.FIRE_OUTBREAK), "Fire Outbreak is classified hazardous")

	# 4. Spawned resource tracking and cleanup
	var dummy_node := Node.new()
	root.add_child(dummy_node)
	deck.spawned_nodes.append(dummy_node)

	var ended_seen := [false]
	deck.event_ended.connect(func(n): ended_seen[0] = true)

	# Advance through event duration (6.0s)
	deck.advance(6.2)
	_check(ended_seen[0], "Event cleanup emitted after duration expires")
	_check(deck.active_event == -1, "Active event reset to -1")
	_check(deck.spawned_nodes.is_empty(), "Spawned nodes array cleared")

	await process_frame
	_check(not is_instance_valid(dummy_node), "Associated event nodes freed from memory")

	print("EventDeck tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
