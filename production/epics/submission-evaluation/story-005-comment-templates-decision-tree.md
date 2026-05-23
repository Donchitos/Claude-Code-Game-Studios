# Story 005: Comment-template decision tree + per-case-override guard

> **Epic**: Submission & Evaluation
> **Status**: Complete (2026-05-23)
> **Layer**: Feature (Gameplay) / Core
> **Type**: Logic
> **Manifest Version**: 2026-05-18
> **Estimated Effort**: 3h (M)
> **Performance**: trivial (per-subscore key lookup)

## Context
**GDD**: `design/gdd/submission-evaluation.md` §3.1.5 (comment templates), §7.4 (comment content knob)
**Requirement**: `TR-submission-*` (comment generation + threshold override guard)
**ADR Governing Implementation**: ADR-0007 §Decision (CommentTemplates .tres in assets/data/evaluation/), §Risk 2 (per_case_verdict_threshold_override)
**ADR Decision Summary**: per-subscore decision tree → template key; 한국어 본문 external (CommentTemplates Dictionary[key→String], assets/data/evaluation/comment_templates.tres). Algorithm decides WHICH key, not content.
**Engine**: Godot 4.6 | **Risk**: None
**Control Manifest Rules**: per_case_verdict_threshold_override forbidden (case .tres must not carry verdict_threshold_* — Pillar 1)

## Acceptance Criteria
- [ ] AC (§3.1.5) — per-subscore decision tree selects exactly one template key (e.g. disposition match/mismatch; coverage high/partial/missed-core; redundant present/absent)
- [ ] AC (§8.4) — EvaluationResult.comments populated from CommentTemplates by selected keys (graceful if a key is absent → skip/empty, no crash)
- [ ] AC (§Risk 2) — `per_case_verdict_threshold_override` forbidden_pattern registered (case .tres carrying verdict_threshold_* rejected/flagged)

## Implementation Notes
Per ADR-0007 + GDD §3.1.5: comment key selection is a pure decision tree per subscore; content lives in CommentTemplates Resource. MVP may ship template keys + placeholder 한국어 (content authoring later). Verify per_case_verdict_threshold_override in architecture.yaml.

## Out of Scope
- Stories 002/003/004; actual 한국어 comment content authoring (content task)

## QA Test Cases
- decision tree: disposition match→key_disp_match; mismatch→key_disp_mismatch; coverage 1.0→key_core_full, partial→key_core_partial, 0→key_core_missed; redundant→key_redundant. comments assembled from keys. absent key → no crash. per_case_verdict_threshold_override registered (registry-read test).

## Test Evidence
**Story Type**: Logic | **Required**: `tests/unit/submission_evaluation/comment_generation_test.gd`
**Status**: [ ] Not yet created

## Dependencies
- Depends on: Story 001 (CommentTemplates), 002 (subscores drive keys)
- Unlocks: #10 Verdict Reveal (displays comments)

## Completion Notes
**Completed**: 2026-05-23. 3/3 ACs. `EvaluationService.compute_comment_keys` (per-subscore decision tree → 7-key set, GDD §3.1.5 boundaries: disp match/miss, core high≥0.8/mid≥0.4/low, redund clean≥-0.05/bloat) + `select_comments` (key→body via CommentTemplates, absent/null graceful) + wired into `evaluate()`. `_comment_templates` empty default (assets/data/evaluation/comment_templates.tres Korean content is a separate content task). per_case_verdict_threshold_override registered (architecture.yaml line 1133). `comment_generation_test.gd` 9/9. Full suite 434/0-fail. Reviewed by orchestrator.
