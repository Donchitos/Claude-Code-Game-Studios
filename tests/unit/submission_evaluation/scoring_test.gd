## scoring_test.gd — story-002: 5 subscores + weighted final_score (deterministic).
extends GdUnitTestSuite

const _EvalScript: Script = preload("res://src/services/evaluation_service.gd")

func _svc() -> Node:
	var s: Node = _EvalScript.new()
	get_tree().root.add_child(s)
	auto_free(s)
	return s

# ─── disposition_match ───
func test_disposition_match_exact() -> void:
	assert_float(_svc().compute_disposition_match("파기", "파기")).is_equal_approx(1.0, 0.0001)

func test_disposition_mismatch_zero() -> void:
	assert_float(_svc().compute_disposition_match("기각", "파기")).is_equal_approx(0.0, 0.0001)

# ─── core_citation_coverage (GDD §4.2 example) ───
func test_coverage_gdd_example_half() -> void:
	# correct [law-100, case/holding-1, case-do], player [law-100, case (whole), case-99999]
	# → [1.0, 0.5 (whole vs holding), 0.0] / 3 = 0.5
	var svc: Node = _svc()
	var correct: Array = ["law:civil-act-art-100", "case:2024da12345/holding-1", "case:2024do6789"]
	var player: Array = ["law:civil-act-art-100", "case:2024da12345", "case:2024da99999"]
	assert_float(svc.compute_core_citation_coverage(player, correct)).is_equal_approx(0.5, 0.0001)

func test_coverage_all_exact_one() -> void:
	var svc: Node = _svc()
	var c: Array = ["law:a", "law:b", "case:x/holding-1"]
	assert_float(svc.compute_core_citation_coverage(c.duplicate(), c)).is_equal_approx(1.0, 0.0001)

func test_coverage_none_zero() -> void:
	assert_float(_svc().compute_core_citation_coverage(["law:z"], ["law:a", "law:b"])).is_equal_approx(0.0, 0.0001)

func test_coverage_empty_correct_is_one() -> void:
	assert_float(_svc().compute_core_citation_coverage(["law:a"], [])).is_equal_approx(1.0, 0.0001)

func test_coverage_different_holdings_no_match() -> void:
	# holding-1 vs holding-2 same case → 0.0 (GDD §4.2 Note)
	assert_float(_svc().compute_core_citation_coverage(["case:x/holding-2"], ["case:x/holding-1"])).is_equal_approx(0.0, 0.0001)

# ─── redundant_citation_penalty (GDD §4.3 examples) ───
func test_penalty_50pct_redundant() -> void:
	# 6 player, 3 matched + 3 redundant → ratio 0.5 → -min(0.3, 0.25) = -0.25
	var svc: Node = _svc()
	var correct: Array = ["law:a", "law:b", "law:c"]
	var player: Array = ["law:a", "law:b", "law:c", "law:x", "law:y", "law:z"]
	assert_float(svc.compute_redundant_citation_penalty(player, correct)).is_equal_approx(-0.25, 0.0001)

func test_penalty_100pct_redundant_caps() -> void:
	# all 5 redundant → ratio 1.0 → -min(0.3, 0.5) = -0.3 (cap)
	assert_float(_svc().compute_redundant_citation_penalty(["a", "b", "c", "d", "e"], ["q"])).is_equal_approx(-0.3, 0.0001)

func test_penalty_none_redundant_zero() -> void:
	assert_float(_svc().compute_redundant_citation_penalty(["law:a"], ["law:a", "law:b"])).is_equal_approx(0.0, 0.0001)

# ─── final_score weighted sum + clamp + v1+ weight-0 ───
func test_final_score_weighted_sum() -> void:
	var svc: Node = _svc()
	var subs: Dictionary = {"disposition_match": 1.0, "core_citation_coverage": 0.5, "redundant_citation_penalty": -0.25, "chain_coherence": 0.9, "precedent_seniority_bonus": 0.9}
	var weights: Dictionary = {"disposition_match": 0.4, "core_citation_coverage": 0.4, "redundant_citation_penalty": 0.2, "chain_coherence": 0.0, "precedent_seniority_bonus": 0.0}
	# 1.0*0.4 + 0.5*0.4 + (-0.25)*0.2 + 0 + 0 = 0.4 + 0.2 - 0.05 = 0.55 ; v1+ weight-0 ignored
	assert_float(svc.compute_final_score(subs, weights)).is_equal_approx(0.55, 0.0001)

func test_final_score_clamped_to_one() -> void:
	var svc: Node = _svc()
	var subs: Dictionary = {"disposition_match": 1.0, "core_citation_coverage": 1.0}
	var weights: Dictionary = {"disposition_match": 0.8, "core_citation_coverage": 0.8}  # 1.6 → clamp 1.0
	assert_float(svc.compute_final_score(subs, weights)).is_equal_approx(1.0, 0.0001)

func test_final_score_clamped_to_zero() -> void:
	var svc: Node = _svc()
	var subs: Dictionary = {"redundant_citation_penalty": -0.3}
	var weights: Dictionary = {"redundant_citation_penalty": 1.0}  # -0.3 → clamp 0.0
	assert_float(svc.compute_final_score(subs, weights)).is_equal_approx(0.0, 0.0001)
