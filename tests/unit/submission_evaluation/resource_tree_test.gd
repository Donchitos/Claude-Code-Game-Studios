## resource_tree_test.gd — story-001: Resource tree + EvaluationService skeleton + thresholds.
extends GdUnitTestSuite

const _EvalScript: Script = preload("res://src/services/evaluation_service.gd")
const _PlayerSubScript: Script = preload("res://src/data/player_submission.gd")
const _EvalResultScript: Script = preload("res://src/data/evaluation_result.gd")
const _CommentTemplatesScript: Script = preload("res://src/data/comment_templates.gd")

func _svc() -> Node:
	var s: Node = _EvalScript.new()
	get_tree().root.add_child(s)
	auto_free(s)
	return s

func test_player_submission_resource_defaults() -> void:
	var sub: Resource = _PlayerSubScript.new()
	assert_str(sub.case_id).is_equal("")
	assert_str(sub.player_disposition).is_equal("")
	assert_int(sub.player_citations.size()).is_equal(0)
	assert_int(sub.submission_time_ms).is_equal(0)

func test_evaluation_result_resource_defaults() -> void:
	var r: Resource = _EvalResultScript.new()
	assert_float(r.final_score).is_equal_approx(0.0, 0.0001)
	assert_str(r.verdict).is_equal("")
	assert_int(r.subscores.size()).is_equal(0)

func test_comment_templates_resource_defaults() -> void:
	var ct: Resource = _CommentTemplatesScript.new()
	assert_int(ct.templates.size()).is_equal(0)

func test_evaluation_service_skeleton_state_and_thresholds() -> void:
	var svc: Node = _svc()
	assert_int(svc.current_state).is_equal(_EvalScript.State.IDLE)
	assert_float(svc.VERDICT_THRESHOLD_PAGI).is_equal_approx(0.7, 0.0001)
	assert_float(svc.VERDICT_THRESHOLD_LOW).is_equal_approx(0.3, 0.0001)
	assert_bool(svc.has_signal("evaluation_completed")).is_true()
	assert_bool(svc.has_signal("submission_rejected")).is_true()

func test_evaluation_service_autoload_registered() -> void:
	var autoload: Node = get_tree().root.get_node_or_null("EvaluationService")
	assert_object(autoload).is_not_null()
