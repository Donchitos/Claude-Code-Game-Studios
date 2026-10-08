---
name: story-done
description: "End-of-story completion review — verifies each acceptance criterion, checks GDD/ADR deviations, prompts code review, updates status."
argument-hint: "[story-file-path] [--review full|lean|solo]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/story-done/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,story_granularity,qa.level,testing.strict,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Story Done

This skill closes the loop between design and implementation. Run it at the end
of implementing any story. It ensures every acceptance criterion is verified
before the story is marked done, GDD and ADR deviations are explicitly
documented rather than silently introduced, code review is prompted rather than
forgotten, and the story file reflects actual completion status.

**Output:** Updated story file (Status: Complete) + surfaced next story.

---

## Phase 1: Find the Story

**Read `references/1-find-story.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 2: Read the Story

**Read `references/2-read-story.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 3: Verify Acceptance Criteria

**Read `references/3-verify-criteria.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 4: Check for Deviations

**Read `references/4-deviations.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 5: Lead Programmer Code Review Gate

**Read `references/5-code-review-gate.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 6: Present the Completion Report

**Read `references/6-completion-report.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 7: Update Story Status

**Read `references/7-update-status.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 8: Surface the Next Story

**Read `references/8-next-story.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Collaborative Protocol

**In `collaborative` mode (the default).** For `guided` and `autonomous` modes,
see `.claude/docs/automation-modes.md` — the rules below describe collaborative
behavior. The BLOCKED-override close (Phase 7) always prompts regardless of mode
(it's a `scope_changes` always-ask decision).

- **Never mark a story complete without user approval** — Phase 7 requires an
  explicit "yes" before any file is edited.
- **Never auto-fix failing criteria** — report them and ask what to do.
- **Deviations are facts, not judgments** — present them neutrally; the user
  decides if they are acceptable.
- **BLOCKED and NOT ASSESSED verdicts are advisory** — the user can override and
  mark complete anyway; document the risk explicitly if they do. For NOT
  ASSESSED, the documented risk is that the criterion was never evaluated, not
  that it failed — record which criteria those were, so the gap is recoverable
  later rather than closed over.
- Use `AskUserQuestion` for the code review prompt and for batching manual
  criteria confirmations.

---

## Recommended Next Steps

- At `minimal`: run `/dev-story [next-story-path]` (`/story-done` for an In Review one); when every story is Complete, play the build, then `/create-stories` for more or `/settings` to raise `modes.rigor`
- With a sprint plan: run `/story-readiness [next-story-path]` to validate the next story before starting implementation
- If a sprint plan exists and all its Must Have stories are complete: run `/smoke-check sprint` → `/team-qa sprint` → `/gate-check`
- If tech debt was logged: track it via `/tech-debt` to keep the register current
