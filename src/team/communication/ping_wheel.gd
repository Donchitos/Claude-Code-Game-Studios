class_name PingWheel
extends RefCounted
## Team tactical communication: Ping Wheel (Danger, Regroup, Help, Loot) and Team Ready Voting.

signal ping_dispatched(type: PingType, world_position: Vector3, label: String)
signal vote_completed(passed: bool)

enum PingType {
	DANGER,    # Red marker: Enemy or hazardous trap
	REGROUP,   # Cyan marker: Objective point or rally here
	NEED_HELP, # Amber marker: Low ammo or downed ally
	LOOT,      # Gold marker: Crate or key item
}

var active_votes: Dictionary = {} # { "voter_id": bool }
var is_voting: bool = false
var vote_timeout: float = 0.0


func dispatch_ping(type: PingType, world_pos: Vector3) -> String:
	var label := _get_ping_label(type)
	ping_dispatched.emit(type, world_pos, label)
	return label


func start_team_vote() -> void:
	is_voting = true
	vote_timeout = 10.0
	active_votes.clear()


func cast_vote(voter_id: String, approve: bool) -> void:
	if not is_voting:
		return
	active_votes[voter_id] = approve


func evaluate_vote(required_approvals: int = 2) -> bool:
	if not is_voting:
		return false

	var yes_count := 0
	for v in active_votes.values():
		if v == true:
			yes_count += 1

	var passed: bool = yes_count >= required_approvals
	is_voting = false
	active_votes.clear()
	vote_completed.emit(passed)
	return passed


func _get_ping_label(type: PingType) -> String:
	match type:
		PingType.DANGER: return "Tehlike!"
		PingType.REGROUP: return "Buraya Toplan"
		PingType.NEED_HELP: return "Yardım Gerekiyor!"
		PingType.LOOT: return "Ganimet Burada"
	return "İşaret"
