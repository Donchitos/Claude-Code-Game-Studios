# Agent Coordination Rules

1. **Vertical Delegation**: Leadership agents delegate to department leads, who
   delegate to specialists. Never skip a tier for complex decisions.
2. **Horizontal Consultation**: Agents at the same tier may consult each other
   but must not make binding decisions outside their domain.
3. **Conflict Resolution**: When two agents disagree, escalate to the shared
   parent. If no shared parent, escalate to `creative-director` for design
   conflicts or `technical-director` for technical conflicts.
4. **Change Propagation**: When a design change affects multiple domains, the
   `producer` agent coordinates the propagation.
5. **No Unilateral Cross-Domain Changes**: An agent must never modify files
   outside its designated directories without explicit delegation.

## Model Tier Assignment

Skills and agents are assigned to model tiers based on task complexity:

Agent and skill frontmatter uses the **family alias** (`haiku` / `sonnet` / `opus`),
never a pinned model ID. Aliases resolve to the current model in that family, so this
table does not need editing every time Anthropic ships a new generation.

| Tier | Frontmatter value | Resolves to (as of 2026-08) | When to use |
|------|-------------------|------------------------------|-------------|
| **Haiku** | `haiku` | `claude-haiku-4-5-20251001` | Read-only status checks, formatting, simple lookups — no creative judgment needed |
| **Sonnet** | `sonnet` | `claude-sonnet-5` | Implementation, design authoring, analysis of individual systems — default for most work |
| **Opus** | `opus` | `claude-opus-5` | Multi-document synthesis, high-stakes phase gate verdicts, cross-system holistic review |

`fable` and `inherit` are also valid frontmatter values. This template assigns neither:
`inherit` would let a specialist silently run on whatever the session happens to be using,
which defeats the point of tiering.

Skills with `model: haiku`: `/help`, `/sprint-status`, `/story-readiness`, `/scope-check`,
`/project-stage-detect`, `/changelog`, `/patch-notes`, `/onboard`

Skills with `model: opus`: `/review-all-gdds`, `/architecture-review`, `/gate-check`

All other skills default to Sonnet. When creating new skills, assign Haiku if the
skill only reads and formats; assign Opus if it must synthesize 5+ documents with
high-stakes output; otherwise leave unset (Sonnet).

## Subagents vs Agent Teams

This project uses two distinct multi-agent patterns:

### Subagents (current, always active)
Spawned via the `Agent` tool within a single Claude Code session (the tool was named
`Task` before Claude Code v2.1.63; `Task` still resolves as an alias, which is why
existing `allowed-tools: ... Task ...` entries keep working). Used by all `team-*` skills
and orchestration skills. Subagents share the session's permission context, run
sequentially or in parallel within the session, and return results to the parent.

**When to spawn in parallel**: If two subagents' inputs are independent (neither
needs the other's output to begin), spawn both Task calls simultaneously rather
than waiting. Example: `/review-all-gdds` Phase 1 (consistency) and Phase 2
(design theory) are independent — spawn both at the same time.

### Agent Teams (experimental — opt-in)
Multiple independent Claude Code *sessions* running simultaneously, coordinated
via a shared task list. Each session has its own context window and token budget.
Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` environment variable.

**Use agent teams when**:
- Work spans multiple subsystems that will not touch the same files
- Each workstream would take >30 minutes and benefits from true parallelism
- A senior agent (technical-director, producer) needs to coordinate 3+ specialist
  sessions working on different epics simultaneously

**Do not use agent teams when**:
- One session's output is required as input for another (use sequential subagents)
- The task fits in a single session's context (use subagents instead)
- Cost is a concern — each team member burns tokens independently

**Current status**: Opt-in via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Document first usage here when adopted.

## Parallel Task Protocol

When an orchestration skill spawns multiple independent agents:

1. Issue all independent Task calls before waiting for any result
2. Collect all results before proceeding to dependent phases
3. If any agent is BLOCKED, surface it immediately — do not silently skip
4. Always produce a partial report if some agents complete and others block
