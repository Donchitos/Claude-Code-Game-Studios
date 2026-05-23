## EvaluationService — autoload THIRD. Weighted-grading core (Pillar 1, ADR-0007).
##
## Stories 001-003 scope: Resource tree (separate files) + autoload skeleton + threshold
## load + the deterministic scoring algorithm (5 subscores + weighted final_score) +
## verdict function. The submit() 5-state pipeline + Library/Case integration is story 004;
## comment-template selection is story 005.
##
## [b]Registration[/b]: `project.godot` [autoload] as
## `EvaluationService="*res://src/services/evaluation_service.gd"` — THIRD per ADR-0007
## (after LibraryService/CaseService; `entry_count()`/`case_count()` heuristic guards avoid
## signal pre-fire deadlock). class_name is `EvaluationServiceClass` (autoload-name-collision).
##
## [b]Algorithm is code, weights are data[/b] (ADR-0003): the scoring functions are pure;
## the per-subscore weights come from `case.scoring_weights`. Verdict thresholds are global
## (`entities.yaml submission_verdict_thresholds` = {pagi:0.7, low:0.3}) — never per-case.
##
## ADR: docs/architecture/adr-0007-submission-evaluation-algorithm.md
## TR:  TR-submission-*
class_name EvaluationServiceClass extends Node


# ─── State machine (story 001; transitions in story 004) ──────────────────────

enum State { IDLE, VALIDATING, COMPUTING, REPORTING, DONE }
var current_state: State = State.IDLE


# ─── Constants ────────────────────────────────────────────────────────────────

## Verdict thresholds — GLOBAL lock (entities.yaml submission_verdict_thresholds = {pagi:0.7, low:0.3}).
## Per-case override is forbidden (per_case_verdict_threshold_override — Pillar 1: same rule for all cases).
const VERDICT_THRESHOLD_PAGI: float = 0.7
const VERDICT_THRESHOLD_LOW: float = 0.3

## Redundant-citation penalty cap (GDD §7.3 / §4.3).
const REDUNDANT_PENALTY_CAP: float = -0.3
const REDUNDANT_PENALTY_SLOPE: float = 0.5

## The 5 subscore keys (ADR-0007 §3.1.3). v1+ keys are computed but weight-0 in MVP.
const SUBSCORE_KEYS: Array[String] = [
	"disposition_match",
	"core_citation_coverage",
	"redundant_citation_penalty",
	"chain_coherence",            # v1+ — weight 0 in MVP
	"precedent_seniority_bonus",  # v1+ — weight 0 in MVP
]


# ─── Signals ──────────────────────────────────────────────────────────────────

signal evaluation_completed(result: EvaluationResult)
signal submission_rejected(reason: String)


# ─── Comment templates (story 005) ────────────────────────────────────────────

## Externalized comment bodies (assets/data/evaluation/comment_templates.tres — content
## task). Empty default: [method select_comments] then yields no comments (graceful).
## The algorithm decides WHICH key per subscore; content lives here.
var _comment_templates: CommentTemplates = CommentTemplates.new()


# ─── Scoring — story 002 (pure functions) ─────────────────────────────────────

## AC §8.2 — discrete 1.0 (disposition matches) or 0.0.
func compute_disposition_match(player_disposition: String, correct_disposition: String) -> float:
	return 1.0 if player_disposition == correct_disposition else 0.0


## AC §8.2 — recall over correct citations: Σ_c max_p similarity(p,c) / |C| (natural [0,1]).
## Iterates the CORRECT side (review BLOCKING #2 fix — avoids >1.0 from |P|>|C|).
## Empty correct set → 1.0 (no correct citations to miss; vacuously covered).
func compute_core_citation_coverage(player_citations: Array, correct_citations: Array) -> float:
	if correct_citations.is_empty():
		return 1.0
	var total: float = 0.0
	for c: String in correct_citations:
		var best: float = 0.0
		for p: String in player_citations:
			best = maxf(best, _citation_similarity(p, c))
		total += best
	return total / float(correct_citations.size())


## AC §8.2 — negative penalty for cited-but-irrelevant citations. [-0.3, 0.0].
## redundant_ratio = |unmatched player citations| / |P|; penalty = -min(0.3, ratio × 0.5).
func compute_redundant_citation_penalty(player_citations: Array, correct_citations: Array) -> float:
	if player_citations.is_empty():
		return 0.0
	var redundant: int = 0
	for p: String in player_citations:
		var matched: bool = false
		for c: String in correct_citations:
			if _citation_similarity(p, c) > 0.0:
				matched = true
				break
		if not matched:
			redundant += 1
	var ratio: float = float(redundant) / float(player_citations.size())
	return -minf(-REDUNDANT_PENALTY_CAP, ratio * REDUNDANT_PENALTY_SLOPE)


## AC §8.3 — weighted sum of all 5 subscores, clamped to [0,1]. v1+ subscores contribute
## only if their weight is non-zero (MVP locks chain_coherence/precedent_seniority_bonus = 0).
func compute_final_score(subscores: Dictionary, scoring_weights: Dictionary) -> float:
	var sum: float = 0.0
	for k: String in SUBSCORE_KEYS:
		sum += float(subscores.get(k, 0.0)) * float(scoring_weights.get(k, 0.0))
	return clampf(sum, 0.0, 1.0)


## Per-subscore weighted contribution map (EvaluationResult.weighted_contributions; sum==final_score pre-clamp).
func compute_weighted_contributions(subscores: Dictionary, scoring_weights: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k: String in SUBSCORE_KEYS:
		out[k] = float(subscores.get(k, 0.0)) * float(scoring_weights.get(k, 0.0))
	return out


# ─── Verdict — story 003 (pure function) ──────────────────────────────────────

## AC §4.7 / §8.3 — maps (disposition match, final_score) → verdict. Global thresholds.
##   파기      : match AND score ≥ 0.7
##   파기환송  : match AND score ≥ 0.3 (< 0.7)
##   기각      : NOT match AND score ≥ 0.3
##   각하      : score < 0.3 (regardless of match)
func determine_verdict(player_disposition: String, correct_disposition: String, final_score: float) -> String:
	var matched: bool = player_disposition == correct_disposition
	if final_score < VERDICT_THRESHOLD_LOW:
		return "각하"
	if matched:
		return "파기" if final_score >= VERDICT_THRESHOLD_PAGI else "파기환송"
	return "기각"


# ─── Citation similarity helper (GDD §4.2) ────────────────────────────────────

## σ(p, c): 1.0 exact; 0.5 same case_id with one whole-case + one holding; else 0.0.
## (Different holdings of the same case → 0.0 — GDD §4.2 Note.)
func _citation_similarity(p: String, c: String) -> float:
	if p == c:
		return 1.0
	var p_case: String = p.get_slice("/", 0)
	var c_case: String = c.get_slice("/", 0)
	if p_case != c_case:
		return 0.0
	var p_whole: bool = not p.contains("/")
	var c_whole: bool = not c.contains("/")
	# one whole-case, the other a holding of the same case → partial match
	if p_whole != c_whole:
		return 0.5
	return 0.0


# ─── submit() pipeline + state machine — story 004 ────────────────────────────

## Entry point (TD-001: PlayerSubmission). Runs the 5-state pipeline:
## IDLE → VALIDATING (empty/invalid citation gate) → COMPUTING ([method evaluate]) →
## REPORTING ([signal evaluation_completed]) → DONE → IDLE.
##
## AC-18: re-submit while not IDLE → push_warning + ignored (no second pipeline in flight).
## AC-1/EC-1: empty player_citations → submission_rejected("empty_citations").
## AC-2/EC-2: a citation failing LibraryService.validate_citations → submission_rejected("invalid_citation").
## Missing case → submission_rejected("case_not_found"). Services looked up at /root (guarded).
func submit(submission: PlayerSubmission) -> void:
	if current_state != State.IDLE:
		push_warning("EvaluationService.submit: evaluation in progress — re-submit ignored")
		return
	current_state = State.VALIDATING
	if submission.player_citations.size() < 1:
		_reject("empty_citations")
		return
	var library: Node = get_node_or_null("/root/LibraryService")
	if library != null:
		var invalid: Array = library.validate_citations(submission.player_citations)
		if not invalid.is_empty():
			_reject("invalid_citation")
			return
	var case_service: Node = get_node_or_null("/root/CaseService")
	var case_file: CaseFile = case_service.get_case(submission.case_id) if case_service != null else null
	if case_file == null:
		_reject("case_not_found")
		return
	current_state = State.COMPUTING
	var result: EvaluationResult = evaluate(submission, case_file)
	current_state = State.REPORTING
	evaluation_completed.emit(result)
	current_state = State.DONE
	current_state = State.IDLE

## Emits submission_rejected and returns the machine to IDLE.
func _reject(reason: String) -> void:
	submission_rejected.emit(reason)
	current_state = State.IDLE

## Pure COMPUTING step: grades [param submission] against [param case_file] and builds the
## EvaluationResult (subscores + weighted contributions + final_score + verdict + citation sets).
## Deterministic except [member EvaluationResult.evaluated_at] (timestamp — AC-23 excluded).
func evaluate(submission: PlayerSubmission, case_file: CaseFile) -> EvaluationResult:
	var correct_disp: String = case_file.correct_disposition
	var correct_cites: Array = case_file.correct_citations
	var weights: Dictionary = case_file.scoring_weights
	var subs: Dictionary = {
		"disposition_match": compute_disposition_match(submission.player_disposition, correct_disp),
		"core_citation_coverage": compute_core_citation_coverage(submission.player_citations, correct_cites),
		"redundant_citation_penalty": compute_redundant_citation_penalty(submission.player_citations, correct_cites),
		"chain_coherence": 0.0,            # v1+ (weight-0 in MVP)
		"precedent_seniority_bonus": 0.0,  # v1+ (weight-0 in MVP)
	}
	var final_score: float = compute_final_score(subs, weights)
	var result := EvaluationResult.new()
	result.case_id = submission.case_id
	result.subscores = subs
	result.weighted_contributions = compute_weighted_contributions(subs, weights)
	result.final_score = final_score
	result.verdict = determine_verdict(submission.player_disposition, correct_disp, final_score)
	result.correct_set = _matched_citations(submission.player_citations, correct_cites)
	result.missed_set = _missed_citations(submission.player_citations, correct_cites)
	result.redundant_set = _redundant_citations(submission.player_citations, correct_cites)
	result.comments = select_comments(compute_comment_keys(subs), _comment_templates)
	result.evaluated_at = int(Time.get_unix_time_from_system() * 1000.0)
	return result


# ─── Comment decision tree + selection — story 005 ────────────────────────────

## Per-subscore decision tree → one template key each (GDD §3.1.5, 7-key set).
## disposition_match: 1.0→comment.disp.match / 0.0→comment.disp.miss.
## core_citation_coverage: ≥0.8→high / 0.4–0.8→mid / <0.4→low.
## redundant_citation_penalty: ≥-0.05→clean / <-0.05→bloat.
func compute_comment_keys(subscores: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	keys.append("comment.disp.match" if float(subscores.get("disposition_match", 0.0)) >= 1.0 else "comment.disp.miss")
	var cov: float = float(subscores.get("core_citation_coverage", 0.0))
	if cov >= 0.8:
		keys.append("comment.core.high")
	elif cov >= 0.4:
		keys.append("comment.core.mid")
	else:
		keys.append("comment.core.low")
	var pen: float = float(subscores.get("redundant_citation_penalty", 0.0))
	keys.append("comment.redund.clean" if pen >= -0.05 else "comment.redund.bloat")
	return keys

## Maps selected template keys to their Korean bodies via [param templates]. A key with no
## body is skipped gracefully (no crash) — the comment_templates.tres content is authored
## separately, so MVP without it simply yields no comments.
func select_comments(keys: Array, templates: CommentTemplates) -> Array[String]:
	var out: Array[String] = []
	if templates == null:
		return out
	for key: String in keys:
		if templates.templates.has(key):
			out.append(String(templates.templates[key]))
	return out

## Player citations that matched a correct citation (similarity > 0).
func _matched_citations(player_citations: Array, correct_citations: Array) -> Array[String]:
	var out: Array[String] = []
	for p: String in player_citations:
		for c: String in correct_citations:
			if _citation_similarity(p, c) > 0.0:
				out.append(p)
				break
	return out

## Correct citations the player did not cover (no player citation matched them).
func _missed_citations(player_citations: Array, correct_citations: Array) -> Array[String]:
	var out: Array[String] = []
	for c: String in correct_citations:
		var covered: bool = false
		for p: String in player_citations:
			if _citation_similarity(p, c) > 0.0:
				covered = true
				break
		if not covered:
			out.append(c)
	return out

## Player citations that matched nothing correct (irrelevant).
func _redundant_citations(player_citations: Array, correct_citations: Array) -> Array[String]:
	var out: Array[String] = []
	for p: String in player_citations:
		var matched: bool = false
		for c: String in correct_citations:
			if _citation_similarity(p, c) > 0.0:
				matched = true
				break
		if not matched:
			out.append(p)
	return out
