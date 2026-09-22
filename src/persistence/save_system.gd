class_name ProductionSaveSystem
extends Node

enum Status {
	OK,
	INVALID_ARGUMENT,
	IO_ERROR,
	READBACK_FAILED,
	NOT_INITIALIZED,
	CORRUPT_PROFILE,
	CONFLICTING_SLOTS,
	WRITE_BLOCKED,
}

const PROFILE_SCHEMA_VERSION := 1

var _initialized := false
var _slot_a_path: String = ""
var _slot_b_path: String = ""
var _profile: Dictionary = {}
var _default_domains: Dictionary = {}
var _active_slot := ""
var _write_blocked := false
var recovered_from_single_slot := false

func initialize(slot_a_path: String = "", slot_b_path: String = "", default_domains: Dictionary = {}) -> int:
	if _initialized or (slot_a_path.is_empty() != slot_b_path.is_empty()) or (not slot_a_path.is_empty() and ProjectSettings.globalize_path(slot_a_path).simplify_path() == ProjectSettings.globalize_path(slot_b_path).simplify_path()):
		return Status.INVALID_ARGUMENT
	_slot_a_path = slot_a_path
	_slot_b_path = slot_b_path
	_default_domains = default_domains.duplicate(true)
	var slot_a := _read_slot(_slot_a_path) if not _slot_a_path.is_empty() else {"valid": false}
	var slot_b := _read_slot(_slot_b_path) if not _slot_b_path.is_empty() else {"valid": false}
	if bool(slot_a.get("valid", false)) and bool(slot_b.get("valid", false)):
		if int(slot_a["generation"]) == int(slot_b["generation"]) and slot_a["profile"] != slot_b["profile"]:
			return Status.CONFLICTING_SLOTS
		_profile = slot_a["profile"] if int(slot_a["generation"]) >= int(slot_b["generation"]) else slot_b["profile"]
		_active_slot = _slot_a_path if int(slot_a["generation"]) >= int(slot_b["generation"]) else _slot_b_path
	elif bool(slot_a.get("valid", false)):
		_profile = slot_a["profile"]
		_active_slot = _slot_a_path
		recovered_from_single_slot = true
	elif bool(slot_b.get("valid", false)):
		_profile = slot_b["profile"]
		_active_slot = _slot_b_path
		recovered_from_single_slot = true
	else:
		if not _slot_a_path.is_empty() and (FileAccess.file_exists(_slot_a_path) or FileAccess.file_exists(_slot_b_path) or DirAccess.dir_exists_absolute(_slot_a_path) or DirAccess.dir_exists_absolute(_slot_b_path)):
			return Status.CORRUPT_PROFILE
		_profile = _empty_profile()
	var domains: Dictionary = _profile.get("domains", {}).duplicate(true)
	for domain_key: Variant in _default_domains:
		if not domains.has(domain_key):
			domains[domain_key] = (_default_domains[domain_key] as Dictionary).duplicate(true)
	_profile["domains"] = domains
	_initialized = true
	return Status.OK

func commit_battle_result(victory: bool, level: int, kills: int, elapsed_seconds: float, domain_after_images: Dictionary = {}) -> int:
	if not _initialized:
		return Status.NOT_INITIALIZED
	if level < 1 or kills < 0 or not is_finite(elapsed_seconds) or elapsed_seconds < 0.0:
		return Status.INVALID_ARGUMENT
	var next_profile := _profile.duplicate(true)
	next_profile["generation"] = int(_profile["generation"]) + 1
	next_profile["total_runs"] = int(_profile["total_runs"]) + 1
	next_profile["victories"] = int(_profile["victories"]) + (1 if victory else 0)
	next_profile["best_level"] = maxi(int(_profile["best_level"]), level)
	next_profile["best_kills"] = maxi(int(_profile["best_kills"]), kills)
	next_profile["best_seconds"] = maxf(float(_profile["best_seconds"]), elapsed_seconds)
	if not _apply_domain_after_images(next_profile, domain_after_images):
		return Status.INVALID_ARGUMENT
	return _write_profile(next_profile)

## Persists opaque feature-owned after-images without interpreting their semantics.
func commit_domain_after_images(domain_after_images: Dictionary) -> int:
	if not _initialized:
		return Status.NOT_INITIALIZED
	if domain_after_images.is_empty():
		return Status.INVALID_ARGUMENT
	var next_profile := _profile.duplicate(true)
	next_profile["generation"] = int(_profile["generation"]) + 1
	if not _apply_domain_after_images(next_profile, domain_after_images):
		return Status.INVALID_ARGUMENT
	return _write_profile(next_profile)

func _write_profile(next_profile: Dictionary) -> int:
	if _write_blocked:
		return Status.WRITE_BLOCKED
	if not _valid_profile(next_profile):
		return Status.INVALID_ARGUMENT
	if _slot_a_path.is_empty():
		_profile = next_profile
		return Status.OK
	var target_path := _slot_b_path if _active_slot == _slot_a_path else _slot_a_path
	var payload_json := JSON.stringify(next_profile, "", true, true)
	var envelope := {
		"schema_version": PROFILE_SCHEMA_VERSION,
		"generation": int(next_profile["generation"]),
		"payload_sha256": payload_json.sha256_text(),
		"payload_json": payload_json,
	}
	_write_checkpoint(&"before_open")
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	if file == null:
		_write_blocked = true
		return Status.IO_ERROR
	_write_checkpoint(&"after_open")
	file.store_string(JSON.stringify(envelope, "", true, true))
	_write_checkpoint(&"after_store")
	file.flush()
	_write_checkpoint(&"after_flush")
	var write_error := file.get_error()
	file = null
	if write_error != OK:
		_write_blocked = true
		return Status.IO_ERROR
	var readback := _read_slot(target_path)
	if not bool(readback.get("valid", false)) \
			or String(readback.get("payload_sha256", "")) != payload_json.sha256_text():
		_write_blocked = true
		return Status.READBACK_FAILED
	_write_checkpoint(&"after_readback")
	_profile = next_profile
	_active_slot = target_path
	return Status.OK

# No-op seam for subprocess crash tests; production installs no callback.
func _write_checkpoint(_point: StringName) -> void:
	pass

func _apply_domain_after_images(profile: Dictionary, domain_after_images: Dictionary) -> bool:
	var domains_value: Variant = profile.get("domains", {})
	if not domains_value is Dictionary:
		return false
	var domains := (domains_value as Dictionary).duplicate(true)
	for domain_key: Variant in domain_after_images:
		if not domain_key is String or String(domain_key).is_empty():
			return false
		var after_image: Variant = domain_after_images[domain_key]
		if not after_image is Dictionary or (after_image as Dictionary).is_empty():
			return false
		domains[domain_key] = (after_image as Dictionary).duplicate(true)
	profile["domains"] = domains
	return true

func profile_snapshot() -> Dictionary:
	return _profile.duplicate(true)

func _read_slot(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {"valid": false}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"valid": false}
	var envelope_parser := JSON.new()
	if envelope_parser.parse(file.get_as_text()) != OK:
		return {"valid": false}
	var envelope_value: Variant = envelope_parser.data
	if not envelope_value is Dictionary:
		return {"valid": false}
	var envelope := envelope_value as Dictionary
	if int(envelope.get("schema_version", 0)) != PROFILE_SCHEMA_VERSION:
		return {"valid": false}
	var payload_json := String(envelope.get("payload_json", ""))
	if payload_json.is_empty() or String(envelope.get("payload_sha256", "")) != payload_json.sha256_text():
		return {"valid": false}
	var profile_parser := JSON.new()
	if profile_parser.parse(payload_json) != OK:
		return {"valid": false}
	var profile_value: Variant = profile_parser.data
	if not profile_value is Dictionary:
		return {"valid": false}
	var profile := profile_value as Dictionary
	if not _valid_profile(profile) or int(envelope.get("generation", -1)) != int(profile["generation"]):
		return {"valid": false}
	return {"valid": true, "generation": int(profile["generation"]), "profile": profile, "payload_sha256": payload_json.sha256_text()}

func _valid_profile(profile: Dictionary) -> bool:
	if int(profile.get("schema_version", 0)) != PROFILE_SCHEMA_VERSION:
		return false
	for field: String in ["generation", "total_runs", "victories", "best_level", "best_kills"]:
		var value: Variant = profile.get(field)
		if not (value is int or value is float):
			return false
		if not is_finite(float(value)) or float(value) < 0.0 or float(value) > 9007199254740991.0 or float(value) != floorf(float(value)):
			return false
	var generation := int(profile.get("generation", -1))
	var total_runs := int(profile.get("total_runs", -1))
	var victories := int(profile.get("victories", -1))
	var best_seconds := float(profile.get("best_seconds", -1.0))
	var domains_value: Variant = profile.get("domains", {})
	return generation >= total_runs \
			and victories <= total_runs \
			and is_finite(best_seconds) \
			and best_seconds >= 0.0 \
			and domains_value is Dictionary

func _empty_profile() -> Dictionary:
	return {
		"schema_version": PROFILE_SCHEMA_VERSION,
		"generation": 0,
		"total_runs": 0,
		"victories": 0,
		"best_level": 0,
		"best_kills": 0,
		"best_seconds": 0.0,
		"domains": {},
	}
