# Context Management (OpenCode)

Context is the most critical resource in an OpenCode session. Manage it actively,
especially with open models that have smaller windows.

## File-backed state

**The file is the memory, not the conversation.** Conversations are compacted or
lost; files persist.

Maintain `production/session-state/active.md` as a living checkpoint. Create it
from `.claude/docs/templates/session-state.md`. The file has two regions:

| Region | Read by | Rule |
|---|---|---|
| `<!-- STATUS -->` … `<!-- /STATUS -->` | humans and status displays | keep the markers even when empty |
| `<!-- CHECKPOINT -->` … `<!-- /CHECKPOINT -->` | `session-start.sh` on every start and after compaction | **overwrite, never append**; under ~25 lines |

The checkpoint holds the current task, next step, blockers, files in progress,
and open questions. Write it so a cold reader can resume without opening
anything else.

After any disruption (compaction, crash, restart), read the state file first.

## Compaction

OpenCode compacts automatically. The adapter re-runs `session-start.sh` after
compaction to restore the checkpoint. You can also request compaction manually.

- Compact proactively at ~60–70% usage, not at the limit.
- Use a fresh session between unrelated tasks.
- Natural points: after writing a section to file, after a commit, after a task.
- Prefer file-backed decisions over long chat summaries.

## Context budgets

| Task | Typical startup |
|---|---|
| Light (read/review) | ~3k tokens |
| Medium (implement feature) | ~8k tokens |
| Heavy (multi-system refactor) | ~15k tokens |

The studio adds `AGENTS.md`, three instruction files, agent/skill descriptions,
and the loaded workflow. If a model has a 32k window, run one workflow at a time.

## Deterministic helpers

The cheapest context saving is not summarizing a document; it is not reading it
at all. Shared helpers live in:

| Directory | Purpose | Invoked by |
|---|---|---|
| `.claude/hooks/` | event-driven validation | the Claude Code harness or the OpenCode plugin |
| `.claude/scripts/` | manually invoked observations | `bash .claude/scripts/<name>.sh` |

Two rules:

1. **Emit observations, not verdicts.** A script that scores or judges will
   eventually contradict a tier, mode, or per-system override it cannot see.
2. **Prefer a helper to a full read.** `gdd-structure-check.sh`,
   `review-scope.sh`, `project-state.sh`, and `registry.sh` answer common
   questions without loading a document.

## Subagent delegation

Use subagents for research and exploration to keep the main session clean.
Subagents run in their own context and return summaries. Give each one a
specific question and the files it needs; do not ask it to read the whole repo.

## Tool output

OpenCode retains large tool output and shortens the preview. For small models,
lower the retained output in `opencode.jsonc`:

```jsonc
{
  "tool_output": { "max_lines": 800, "max_bytes": 24000 }
}
```
