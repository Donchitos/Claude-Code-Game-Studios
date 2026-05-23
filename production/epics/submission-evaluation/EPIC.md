# Epic: Submission & Evaluation

> **Layer**: Feature (Gameplay) / Core
> **GDD**: design/gdd/submission-evaluation.md
> **Architecture Module**: `EvaluationService` autoload (THIRD position) + `PlayerSubmission` / `EvaluationResult` / `CommentTemplates` Resource tree
> **Status**: In Progress
> **Stories**: 5 created 2026-05-23
> **Created**: 2026-05-23

## Overview

Submission & Evaluation is the weighted-grading core (Pillar 1 — *Truth Is Weighted*). It takes a `PlayerSubmission` (chosen disposition + cited Library IDs + chain_data) and grades it against the case's `correct_disposition` / `correct_citations` / `scoring_weights` (data-driven — *algorithm is code, weights are data*, ADR-0003). It computes 5 subscores (MVP active: `disposition_match`, `core_citation_coverage`, `redundant_citation_penalty`; v1+: `chain_coherence`, `precedent_seniority_bonus` — weight-0 locked in MVP), weight-sums them into a single `final_score`, and produces a verdict (파기/파기환송/기각/각하) plus per-subscore one-line comments. The Anti-Pillar guard `case_disposition_match_minimum_weight = 0.4` ensures disposition alone cannot decide the outcome. `EvaluationService` is an autoload (THIRD) running a 5-state machine (IDLE→VALIDATING→COMPUTING→REPORTING→DONE) that emits `evaluation_completed(result: EvaluationResult)`. Responsibility boundary: this system grades only — verdict *presentation* is #10 Verdict Reveal, result *persistence* is #11 Career / Save/Load.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| **ADR-0007: Submission Evaluation Algorithm** (Accepted 2026-05-17) | `EvaluationService` autoload THIRD; `submit(submission: PlayerSubmission)` (TD-001 resolved); PlayerSubmission/EvaluationResult/CommentTemplates Resources; 5-state machine; 5 subscores; verdict thresholds {pagi:0.7, low:0.3} global-locked in `entities.yaml`; per-case threshold override forbidden | None — `class_name`/`@export`/`signal`/`enum`/Autoload all 4.0+ stable (no post-cutoff APIs) |
| ADR-0001 (dependency) | `LibraryService.validate_citations()` (Validating gate) | LOW |
| ADR-0003 (dependency) | `CaseService.get_case()` + `scoring_weights` externalization | LOW |

## GDD Requirements

23 `TR-submission-*` in `tr-registry.yaml` — covered by ADR-0007. Thematic grouping (per-story TR-IDs pulled by `/create-stories`):

| Theme | Coverage |
|-------|----------|
| PlayerSubmission/EvaluationResult/CommentTemplates Resource tree + autoload THIRD | ADR-0007 ✅ |
| 5-subscore definitions (disposition_match / core_citation_coverage / redundant_citation_penalty + v1+ chain_coherence / precedent_seniority_bonus weight-0) | ADR-0007 ✅ |
| final_score weighted sum + [0,1] clamp + Anti-Pillar min-weight guard | ADR-0007 ✅ |
| Verdict function (파기/파기환송/기각/각하) + global thresholds | ADR-0007 ✅ |
| 5-state machine + double-submit reject + Validating gate (validate_citations) | ADR-0007 ✅ |
| Comment-template decision tree (per-subscore key selection) | ADR-0007 ✅ |
| Per-case verdict-threshold-override forbidden pattern | ADR-0007 ✅ |

## Engine / Cross-System Notes

- **No post-cutoff engine risk** — pure GDScript Resource + autoload + signal.
- **Dependencies all present**: `LibraryService.validate_citations` (src/data/library_service.gd:286), `CaseService.get_case` (src/data/case_service.gd:99), `CaseFile.correct_disposition`/`correct_citations`/`scoring_weights` (src/data/case_file.gd), `entities.yaml submission_verdict_thresholds` = {pagi:0.7, low:0.3}.
- **Autoload THIRD**: per ADR-0007 `entry_count()`/`case_count()` heuristic guard avoids signal pre-fire deadlock. Real registration after LibraryService(FIRST)/CaseService — note current project has LibraryService/UIService/CaseService/SaveLoadService; EvaluationService slot is positional intent.
- **TD-001 RESOLVED**: `submit(submission: PlayerSubmission)` is the entry point (control-manifest corrected). Unblocks Save/Load sl-005/006 end-to-end + reasoning-workspace 007/008 submit hand-off.
- **Unblocks**: #10 Verdict Reveal, #11 Career, #14 Retrospective Replay; Save/Load resolution + recovery cascades.

## Definition of Done

This epic is complete when:
- All stories implemented, reviewed, closed via `/story-done`
- All `design/gdd/submission-evaluation.md` §8 acceptance criteria verified
- Scoring algorithm + verdict function have deterministic unit tests (§8.8)
- 5-state machine + double-submit + Validating gate have integration tests
- Per-case-override + min-weight Anti-Pillar guards gated by tests

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Resource tree + autoload + threshold load](story-001-resource-tree-autoload-thresholds.md) | Logic | Complete | ADR-0007 |
| 002 | [Scoring — 5 subscores + weighted final_score](story-002-scoring-subscores-final-score.md) | Logic | Complete | ADR-0007 |
| 003 | [Verdict function (파기/파기환송/기각/각하)](story-003-verdict-function.md) | Logic | Complete | ADR-0007 |
| 004 | [submit() 5-state machine + Validating gate + evaluation_completed](story-004-state-machine-submit-pipeline.md) | Integration | Ready | ADR-0007 |
| 005 | [Comment-template decision tree + per-case-override guard](story-005-comment-templates-decision-tree.md) | Logic | Ready | ADR-0007 |

**Implementation order**: 001 (Resources/autoload/thresholds) → 002 (scoring) → 003 (verdict) → 004 (state machine wires 002/003 + Library/Case integration) → 005 (comments). 001-003 are the deterministic gradable core; 004 wires the pipeline + cross-system integration; 005 adds comment selection.

## Next Step

Run `/story-readiness production/epics/submission-evaluation/story-001-resource-tree-autoload-thresholds.md` then `/dev-story`.
