# Agent Teams (experimental — opt-in)

> On-demand reference. Demoted out of `coordination-rules.md` (an always-loaded
> CLAUDE.md import) in v1.1 — read this when actually considering a team, not
> on every turn.

Multiple independent Claude Code *sessions* running simultaneously, coordinated
via a shared task list. Each session has its own context window and token budget.
Requires the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` environment variable.

## Use agent teams when

- Work spans multiple subsystems that will not touch the same files
- Each workstream would take >30 minutes and benefits from true parallelism
- A senior agent (technical-director, producer) needs to coordinate 3+ specialist
  sessions working on different epics simultaneously

## Do not use agent teams when

- One session's output is required as input for another (use sequential subagents)
- The task fits in a single session's context (use subagents instead)
- Cost is a concern — each team member burns tokens independently

## Current status

Opt-in via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Document first usage here
when adopted.
