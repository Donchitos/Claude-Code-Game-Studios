# Agent Coordination Rules (OpenCode)

1. **Vertical Delegation**: Leadership agents delegate to department leads, who
   delegate to specialists. Never skip a tier for complex decisions. Use the
   `subagent` tool; `opencode.jsonc` sets `experimental.subagent_depth` to 3 so
   the full primary → director → lead → specialist chain works.
2. **Horizontal Consultation**: Agents at the same tier may consult each other
   but must not make binding decisions outside their domain.
3. **Conflict Resolution**: When two agents disagree, escalate to the shared
   parent. If there is no shared parent, escalate to `creative-director` for
   design conflicts or `technical-director` for technical conflicts.
4. **Change Propagation**: When a design change affects multiple domains, the
   `producer` agent coordinates the propagation.
5. **No Unilateral Cross-Domain Changes**: An agent must never modify files
   outside its designated directories without explicit delegation.
6. **Read Design Docs by Section**: A brief names the sections an agent needs
   by heading. Find a heading with `grep` and read that range with `read` and
   `offset`/`limit`; read a doc whole only when the task needs all of it, and
   say why. `validate-read.sh` refuses a whole-file read of a doc over 40 KB.
7. **Nothing Goes Upstream**: Never file, open, or comment on an issue or pull
   request in an engine, plugin, or vendor repository, even when asked. Write a
   draft (`/bug-report` drafts only) and the user submits it.

## Model Assignment

OpenCode has no session-wide model tiers and the generated layer does not pin
models. Every agent and command inherits the model selected in OpenCode.

- To give one role a different model, set `model: provider/model` in that
  agent's `.opencode/agents/<name>.md` or in `opencode.jsonc`.
- When a model is changed, re-test any skill that depends on tool calling.
- See `.opencode/docs/model-selection.md` for local provider examples and
  context guidance.

## Subagents vs Agent Teams

### Subagents (default)

Spawned with the `subagent` tool in one OpenCode session. Used by the `team-*`
skills and the orchestration skills. Subagents have their own context and return
a result to the parent. OpenCode nests up to three subagent levels by default in
this project.

**When to spawn in parallel**: if two subagents' inputs are independent, issue
both `subagent` calls before waiting. Example: `/review-all-gdds` Phase 2
(consistency) and Phase 3 (design theory) are independent; Phase 1 loads the
GDDs and must finish first.

### Agent Teams (optional)

Multiple independent OpenCode sessions coordinated through a shared task list.
Read `.opencode/docs/agent-teams.md` before proposing one. OpenCode does not
require Claude Code's experimental environment variable; use separate sessions
or worktrees and coordinate through files.

## Parallel Task Protocol

1. Issue all independent `subagent` calls before waiting for any result.
2. Collect all results before proceeding to dependent phases.
3. If any agent is BLOCKED, surface it immediately — do not silently skip it.
4. Always produce a partial report if some agents complete and others block.
