# Agent Teams (OpenCode)

> On-demand reference. Read this when considering multiple simultaneous
> sessions, not on every turn.

Multiple independent OpenCode sessions can work in parallel, coordinated through
a shared task list or a shared set of state files. Each session has its own
context window and token budget.

## Use agent teams when

- Work spans multiple subsystems that will not touch the same files.
- Each workstream would take more than 30 minutes and benefits from true
  parallelism.
- A senior agent (technical-director, producer) needs to coordinate three or more
  specialist sessions on different epics.

## Do not use agent teams when

- One session's output is required as input for another (use sequential
  subagents).
- The task fits in one session's context (use subagents).
- Cost is a concern — each team member burns tokens independently.

## How to set one up

1. Create a worktree per workstream:

   ```bash
   opencode
   ```

   Then use the worktree tools, or from a shell:

   ```bash
   git worktree add ../my-game-combat -b combat
   git worktree add ../my-game-ui -b ui
   ```

2. Start one OpenCode session in each worktree.
3. Give each session a single epic or subsystem and a named output file.
4. Coordinate through `production/session-state/active.md` or a shared task list;
   do not assume sessions can see each other's conversations.

OpenCode isolates sessions by default. Unlike Claude Code, there is no
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable to enable; use
separate sessions and worktrees.

## Current status

Optional and manual. Document the first real use here when adopted.
