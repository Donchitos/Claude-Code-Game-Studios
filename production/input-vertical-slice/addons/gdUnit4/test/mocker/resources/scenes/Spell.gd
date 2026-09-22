class_name Spell
extends Node

signal spell_explode(spell: Spell)

const SPELL_LIVE_TIME = 1000

@warning_ignore("unused_private_class_variable")
var _spell_fired :bool = false
var _spell_live_time :float = 0
var _spell_pos :Vector3 = Vector3.ZERO

# helper counter for testing simulate_frames
@warning_ignore("unused_private_class_variable")
var _debug_process_counted := 0

func _ready() -> void:
	set_name("Spell")

# only comment in for debugging reasons
#func _notification(what):
#	prints("Spell", GdObjects.notification_as_string(what))

func _process(delta :float) -> void:
	# added pseudo yield to check `simulate_frames` works wih custom yielding
	await get_tree().process_frame
	_spell_live_time += delta * 1000
	if _spell_live_time < SPELL_LIVE_TIME:
		move(delta)
	else:
		explode()

func move(delta :float) -> void:
	#await get_tree().create_timer(0.1).timeout
	_spell_pos.x += delta

func explode() -> void:
	spell_explode.emit(self)

