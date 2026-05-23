# Story 002: Scoring — 5 subscores + weighted final_score

> **Epic**: Submission & Evaluation
> **Status**: Complete (2026-05-23)
> **Layer**: Feature (Gameplay) / Core
> **Type**: Logic
> **Manifest Version**: 2026-05-18
> **Estimated Effort**: 4h (M)
> **Performance**: ≤50ms per evaluation (AC-21); 5 subscore + Set ops O(|P|·|C|) < 1ms typical

## Context
**GDD**: `design/gdd/submission-evaluation.md` §4.1-4.3 (MVP subscores), §4.6 (final_score), §3.1.3 (5 subscore defs), §7.3 (penalty cap)
**Requirement**: `TR-submission-*` (subscore formulas + weighted sum)
**ADR Governing Implementation**: ADR-0007 §Decision (scoring algorithm)
**ADR Decision Summary**: 5 subscores [0,1] (penalty [-0.3,0]). MVP active: `disposition_match` (discrete 1.0/0.0 = player_disposition==correct_disposition), `core_citation_coverage` (Set recall over correct_citations — iterate CORRECT side for natural [0,1] cap per review BLOCKING #2 fix), `redundant_citation_penalty` (negative, over player\correct). v1+ (weight-0): chain_coherence, precedent_seniority_bonus. `final_score = clamp(Σ subscore[k]×case.scoring_weights[k], 0, 1)`.
**Engine**: Godot 4.6 | **Risk**: None
**Control Manifest Rules**: Feature Layer — Anti-Pillar `case_disposition_match_minimum_weight=0.4` (disposition alone can't decide); penalty cap [-0.3,0]

## Acceptance Criteria
- [ ] AC (§8.2) — `disposition_match` = 1.0 iff player_disposition==correct_disposition else 0.0
- [ ] AC (§8.2) — `core_citation_coverage` = |player ∩ correct| / |correct| (iterate correct side; [0,1]; correct empty→define per GDD)
- [ ] AC (§8.2) — `redundant_citation_penalty` ∈ [-0.3, 0.0] over player citations not in correct (penalty cap §7.3)
- [ ] AC (§8.3) — `final_score = clamp(Σ subscore[k] × scoring_weights[k], 0.0, 1.0)`; v1+ subscores (chain_coherence/precedent_seniority_bonus) computed but weight-0 in MVP → no effect

## Implementation Notes
Per ADR-0007 + GDD §4: pure functions on (player_disposition, player_citations, correct_disposition, correct_citations, scoring_weights). All 5 keys computed (v1+ weight-0). Use Dictionary/Array Set ops. Deterministic (§8.8) — no time/random. Penalty cap clamp.

## Out of Scope
- Story 003 (verdict fn maps final_score→verdict), 004 (state machine), 001 (Resources)

## QA Test Cases
- disposition_match: match→1.0, mismatch→0.0. coverage: 3/6 correct cited→0.5; all→1.0; none→0.0; correct empty→GDD-defined. penalty: 2 redundant→within [-0.3,0]; cap respected at many redundant. final_score: weighted sum + clamp; v1+ weight-0 confirmed no-effect. Boundary values exact.

## Test Evidence
**Story Type**: Logic | **Required**: `tests/unit/submission_evaluation/scoring_test.gd`
**Status**: [ ] Not yet created

## Dependencies
- Depends on: Story 001 (EvaluationResult subscores Dict)
- Unlocks: 003 (verdict consumes final_score), 004

## Completion Notes
**Completed**: 2026-05-23. 4/4 ACs. EvaluationService pure functions: compute_disposition_match / compute_core_citation_coverage (correct-side recall, citation_similarity 1.0/0.5/0.0, GDD §4.2 example=0.5 verified) / compute_redundant_citation_penalty (-min(0.3, ratio×0.5), §4.3 examples -0.25/-0.3 verified) / compute_final_score (clamp[0,1], v1+ weight-0 no-effect verified) / compute_weighted_contributions. Tests: scoring_test.gd 13/13. Deterministic (§8.8). Reviewed by orchestrator.
