class_name ProductionMovementIngressShield
extends Control

## Fixed-slot consumer-closed touch ownership. It never writes gameplay state.
signal fault_latched(status: int)

const STATUS_INVALID_ARGUMENT := 1

var _capacity: int = 0
var _slot_active := PackedByteArray()
var _slot_epoch := PackedInt64Array()
var _slot_index := PackedInt32Array()
var _epoch: int = 1
var _service_enabled: bool = false
var _fault_reported: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func configure(capacity: int) -> bool:
	if capacity <= 0 or _capacity != 0:
		return false
	_capacity = capacity
	_slot_active.resize(capacity)
	_slot_epoch.resize(capacity)
	_slot_index.resize(capacity)
	return true

func set_service_enabled(enabled: bool, epoch: int) -> void:
	_service_enabled = enabled
	_epoch = maxi(epoch, 1)
	if enabled:
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

func held_count() -> int:
	var count := 0
	for active: int in _slot_active:
		count += active
	return count

func clear_for_rebuild(next_epoch: int) -> void:
	for index in _capacity:
		_slot_active[index] = 0
	_epoch = maxi(next_epoch, 1)
	_fault_reported = false

func _gui_input(event: InputEvent) -> void:
	accept_event()
	if not _service_enabled:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.index < 0:
			_report_invalid_argument()
			return
		if touch.pressed:
			_accept_press(touch.index)
		else:
			_release_touch(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _find_slot(drag.index) < 0:
			_report_invalid_argument()

func _accept_press(touch_index: int) -> void:
	if _find_slot(touch_index) >= 0:
		return
	for slot in _capacity:
		if _slot_active[slot] == 0:
			_slot_active[slot] = 1
			_slot_epoch[slot] = _epoch
			_slot_index[slot] = touch_index
			return
	_report_invalid_argument()

func _release_touch(touch_index: int) -> void:
	var slot := _find_slot(touch_index)
	if slot >= 0 and _slot_epoch[slot] == _epoch:
		_slot_active[slot] = 0

func _find_slot(touch_index: int) -> int:
	for slot in _capacity:
		if _slot_active[slot] != 0 and _slot_index[slot] == touch_index:
			return slot
	return -1

func _report_invalid_argument() -> void:
	if _fault_reported:
		return
	_fault_reported = true
	fault_latched.emit(STATUS_INVALID_ARGUMENT)
