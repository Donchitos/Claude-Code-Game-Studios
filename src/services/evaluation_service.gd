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
