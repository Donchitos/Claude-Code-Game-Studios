## verdict_test.gd — story-003: verdict function (파기/파기환송/기각/각하), GDD §4.7.
extends GdUnitTestSuite

const _EvalScript: Script = preload("res://src/services/evaluation_service.gd")

func _svc() -> Node:
	var s: Node = _EvalScript.new()
	get_tree().root.add_child(s)
	auto_free(s)
	return s

func test_match_high_is_pagi() -> void:
	assert_str(_svc().determine_verdict("파기", "파기", 0.7)).is_equal("파기")

func test_match_just_below_pagi_is_hwansong() -> void:
	assert_str(_svc().determine_verdict("파기", "파기", 0.69)).is_equal("파기환송")

func test_match_at_low_is_hwansong() -> void:
	assert_str(_svc().determine_verdict("파기", "파기", 0.3)).is_equal("파기환송")

func test_match_just_below_low_is_gakha() -> void:
	assert_str(_svc().determine_verdict("파기", "파기", 0.29)).is_equal("각하")

func test_mismatch_at_low_is_gigak() -> void:
	assert_str(_svc().determine_verdict("기각", "파기", 0.3)).is_equal("기각")

func test_mismatch_high_is_gigak_never_pagi() -> void:
	# mismatch can never reach 파기 even at high score
	assert_str(_svc().determine_verdict("기각", "파기", 0.95)).is_equal("기각")

func test_mismatch_below_low_is_gakha() -> void:
	assert_str(_svc().determine_verdict("기각", "파기", 0.1)).is_equal("각하")

func test_all_four_verdicts_reachable() -> void:
	var svc: Node = _svc()
	var verdicts: Array = [
		svc.determine_verdict("파기", "파기", 0.8),   # 파기
		svc.determine_verdict("파기", "파기", 0.4),   # 파기환송
		svc.determine_verdict("기각", "파기", 0.4),   # 기각
		svc.determine_verdict("파기", "파기", 0.1),   # 각하
	]
	assert_bool(verdicts.has("파기")).is_true()
	assert_bool(verdicts.has("파기환송")).is_true()
	assert_bool(verdicts.has("기각")).is_true()
	assert_bool(verdicts.has("각하")).is_true()
