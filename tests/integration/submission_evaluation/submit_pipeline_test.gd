## submit_pipeline_test.gd — story-004: submit() 5-state machine + Validating gate + emit.
##
## Loads Library + Case fixtures into the autoloads (mirrors case_service_load_test) so the
## Validating gate (LibraryService.validate_citations) and COMPUTING (CaseService.get_case)
## run against real data.
extends GdUnitTestSuite

const _EvalScript: Script = preload("res://src/services/evaluation_service.gd")
const _PlayerSubScript: Script = preload("res://src/data/player_submission.gd")

const LIBRARY_FIXTURES: String = "res://tests/fixtures/library/seed/"
const CASE_FIXTURES: String = "res://tests/fixtures/cases/seed/"
const SAMPLE_CASE_ID: String = "case_data:2026-001"
const CORRECT_CITATIONS: Array[String] = [
	"law:criminal-act-art-250", "law:criminal-act-art-35",
	"case:2025do10910/holding-1", "case:2025do10910/holding-2",
]

var _lib: Node
var _cases: Node

func before_test() -> void:
	_lib = get_tree().root.get_node("LibraryService")
	_lib.load_all(LIBRARY_FIXTURES)
	_cases = get_tree().root.get_node("CaseService")
	_cases.load_all(CASE_FIXTURES)

func _svc() -> Node:
	var s: Node = _EvalScript.new()
	get_tree().root.add_child(s)
	auto_free(s)
	return s

func _submission(case_id: String, disp: String, cites: Array[String]) -> Resource:
	var sub: Resource = _PlayerSubScript.new()
	sub.case_id = case_id
	sub.player_disposition = disp
	sub.player_citations = cites
	return sub

# ─── AC-18 double-submit ───
func test_resubmit_while_busy_ignored() -> void:
	var svc: Node = _svc()
	svc.current_state = _EvalScript.State.VALIDATING   # simulate in-flight
	var emitted: Array = []
	svc.evaluation_completed.connect(func(_r: Object) -> void: emitted.append(true))
	svc.submit(_submission(SAMPLE_CASE_ID, "파기환송", CORRECT_CITATIONS.duplicate()))
	assert_int(svc.current_state).is_equal(_EvalScript.State.VALIDATING)  # unchanged
	assert_int(emitted.size()).is_equal(0)

# ─── AC-1 empty citations ───
func test_empty_citations_rejected() -> void:
	var svc: Node = _svc()
	var rejected: Array = []
	svc.submission_rejected.connect(func(reason: String) -> void: rejected.append(reason))
	var empty: Array[String] = []
	svc.submit(_submission(SAMPLE_CASE_ID, "파기환송", empty))
	assert_int(rejected.size()).is_equal(1)
	assert_str(rejected[0]).is_equal("empty_citations")
	assert_int(svc.current_state).is_equal(_EvalScript.State.IDLE)

# ─── AC-2 invalid citation ───
func test_invalid_citation_rejected() -> void:
	var svc: Node = _svc()
	var rejected: Array = []
	svc.submission_rejected.connect(func(reason: String) -> void: rejected.append(reason))
	var bad: Array[String] = ["law:does-not-exist-99999"]
	svc.submit(_submission(SAMPLE_CASE_ID, "파기환송", bad))
	assert_int(rejected.size()).is_equal(1)
	assert_str(rejected[0]).is_equal("invalid_citation")
	assert_int(svc.current_state).is_equal(_EvalScript.State.IDLE)

# ─── case not found ───
func test_unknown_case_rejected() -> void:
	var svc: Node = _svc()
	var rejected: Array = []
	svc.submission_rejected.connect(func(reason: String) -> void: rejected.append(reason))
	svc.submit(_submission("case_data:does-not-exist", "파기환송", CORRECT_CITATIONS.duplicate()))
	assert_int(rejected.size()).is_equal(1)
	assert_str(rejected[0]).is_equal("case_not_found")
	assert_int(svc.current_state).is_equal(_EvalScript.State.IDLE)

# ─── happy path ───
func test_valid_submission_emits_evaluation_completed_and_returns_idle() -> void:
	var svc: Node = _svc()
	var results: Array = []
	svc.evaluation_completed.connect(func(r: Object) -> void: results.append(r))
	svc.submit(_submission(SAMPLE_CASE_ID, "파기환송", CORRECT_CITATIONS.duplicate()))
	assert_int(results.size()).is_equal(1)
	var result: Object = results[0]
	assert_str(result.case_id).is_equal(SAMPLE_CASE_ID)
	assert_str(result.verdict).is_not_empty()
	assert_bool(result.subscores.has("disposition_match")).is_true()
	# disposition matches (파기환송 == correct) → disposition_match subscore 1.0
	assert_float(result.subscores["disposition_match"]).is_equal_approx(1.0, 0.0001)
	# all 4 correct citations covered → coverage 1.0, redundant 0
	assert_float(result.subscores["core_citation_coverage"]).is_equal_approx(1.0, 0.0001)
	assert_int(result.missed_set.size()).is_equal(0)
	assert_int(result.redundant_set.size()).is_equal(0)
	# state returned to IDLE after the pipeline
	assert_int(svc.current_state).is_equal(_EvalScript.State.IDLE)
