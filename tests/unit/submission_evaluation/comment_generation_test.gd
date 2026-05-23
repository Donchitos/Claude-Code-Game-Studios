## comment_generation_test.gd — story-005: comment-template decision tree + selection.
extends GdUnitTestSuite

const _EvalScript: Script = preload("res://src/services/evaluation_service.gd")
const _CommentTemplatesScript: Script = preload("res://src/data/comment_templates.gd")

func _svc() -> Node:
	var s: Node = _EvalScript.new()
	get_tree().root.add_child(s)
	auto_free(s)
	return s

func _all_template_keys() -> Dictionary:
	return {
		"comment.disp.match": "처분 일치", "comment.disp.miss": "처분 불일치",
		"comment.core.high": "핵심 인용 충실", "comment.core.mid": "인용 일부 누락", "comment.core.low": "핵심 인용 대부분 누락",
		"comment.redund.clean": "무관 인용 거의 없음", "comment.redund.bloat": "무관 인용 다수",
	}

# ─── decision tree (GDD §3.1.5 boundaries) ───
func test_keys_disposition_match() -> void:
	var k: Array = _svc().compute_comment_keys({"disposition_match": 1.0, "core_citation_coverage": 0.9, "redundant_citation_penalty": 0.0})
	assert_bool(k.has("comment.disp.match")).is_true()
	assert_bool(k.has("comment.core.high")).is_true()
	assert_bool(k.has("comment.redund.clean")).is_true()

func test_keys_disposition_miss() -> void:
	assert_bool(_svc().compute_comment_keys({"disposition_match": 0.0}).has("comment.disp.miss")).is_true()

func test_keys_coverage_boundaries() -> void:
	var svc: Node = _svc()
	assert_bool(svc.compute_comment_keys({"core_citation_coverage": 0.8}).has("comment.core.high")).is_true()   # ≥0.8
	assert_bool(svc.compute_comment_keys({"core_citation_coverage": 0.79}).has("comment.core.mid")).is_true()   # 0.4–0.8
	assert_bool(svc.compute_comment_keys({"core_citation_coverage": 0.4}).has("comment.core.mid")).is_true()    # ≥0.4
	assert_bool(svc.compute_comment_keys({"core_citation_coverage": 0.39}).has("comment.core.low")).is_true()   # <0.4

func test_keys_redundant_boundaries() -> void:
	var svc: Node = _svc()
	assert_bool(svc.compute_comment_keys({"redundant_citation_penalty": -0.05}).has("comment.redund.clean")).is_true()  # ≥-0.05
	assert_bool(svc.compute_comment_keys({"redundant_citation_penalty": -0.06}).has("comment.redund.bloat")).is_true()  # <-0.05

func test_keys_exactly_three() -> void:
	# one key per active subscore (disp + core + redund)
	assert_int(_svc().compute_comment_keys({"disposition_match": 1.0, "core_citation_coverage": 0.5, "redundant_citation_penalty": -0.1}).size()).is_equal(3)

# ─── selection ───
func test_select_comments_maps_keys_to_bodies() -> void:
	var svc: Node = _svc()
	var ct: Resource = _CommentTemplatesScript.new()
	ct.templates = _all_template_keys()
	var comments: Array = svc.select_comments(["comment.disp.match", "comment.core.high"], ct)
	assert_int(comments.size()).is_equal(2)
	assert_bool(comments.has("처분 일치")).is_true()
	assert_bool(comments.has("핵심 인용 충실")).is_true()

func test_select_comments_skips_absent_keys_gracefully() -> void:
	var svc: Node = _svc()
	var ct: Resource = _CommentTemplatesScript.new()   # empty templates
	var comments: Array = svc.select_comments(["comment.disp.match"], ct)
	assert_int(comments.size()).is_equal(0)   # absent → skipped, no crash

func test_select_comments_null_templates_safe() -> void:
	assert_int(_svc().select_comments(["comment.disp.match"], null).size()).is_equal(0)

# ─── per-case-override forbidden pattern registered ───
func test_per_case_verdict_threshold_override_registered() -> void:
	var f: FileAccess = FileAccess.open("res://docs/registry/architecture.yaml", FileAccess.READ)
	assert_object(f).is_not_null()
	var content: String = f.get_as_text()
	f.close()
	assert_bool(content.contains("per_case_verdict_threshold_override")).is_true()
