# OpenCode Game Studios — Game Studio Agent Architecture

Indie game development managed through 49 coordinated OpenCode subagents and 74
workflow commands. Each agent owns a specific domain, enforcing separation of
concerns and quality.

This is the **OpenCode entry point**. `.claude/CLAUDE.md` is the Claude Code
equivalent. The studio is dual-harness: `.claude/` is the canonical source, and
`.opencode/` is generated from it by `python3 tools/sync-opencode.py`.

## Technology Stack

- **Engine**: read `engine.name` from `project.yaml`; `/setup-engine` writes it
- **Language**: read `engine.language` from `project.yaml`
- **Version Control**: Git with trunk-based development
- **Build System / Asset Pipeline**: recorded by `/setup-engine`

Engine-specialist agents exist for Godot, Unity, and Unreal with dedicated
sub-specialists. Use the set matching the project's engine.

## Project Structure

The full guide is loaded from `.opencode/docs/directory-structure.md` by
`opencode.jsonc`. In short:

```
.claude/                 canonical Claude Code layer and shared studio core
  agents/ skills/        canonical agent and skill definitions
  hooks/ scripts/        shared validation and helper scripts
  rules/                 path-scoped coding standards
  docs/                  shared process docs and templates
.opencode/               generated OpenCode adapter
  agents/                subagents + the primary studio agent
  skills/                generated skill copies
  commands/              slash commands
  plugins/ccgs/          OpenCode hook adapter
  docs/                  OpenCode-specific guidance
AGENTS.md                this file
opencode.jsonc           OpenCode configuration
design/ docs/ src/       project artifacts
production/              sprint plans, milestones, release tracking
studio-tests/            QA for the skills and agents themselves
```

## Engine Version Reference

The model's training data predates the pinned engine version. Read
`docs/engine-reference/<engine>/VERSION.md` using the engine in `project.yaml`
before using any engine API. Do not guess at post-cutoff API signatures.

## Technical Preferences

`project.yaml` at the repository root is the primary config store: engine,
specialists, naming, platform, performance, and modes. Skills resolve it through
the shared helper scripts in `.claude/scripts/` and `.claude/hooks/`.

`.claude/docs/technical-preferences.md` is the legacy fallback, read on demand
when a key is absent from `project.yaml`.

## Coordination Rules

1. **Vertical delegation** — directors delegate to leads, leads to specialists.
   Use the `subagent` tool. OpenCode's `experimental.subagent_depth` is set to 3
   so the full chain works.
2. **Horizontal consultation** — same-tier agents may consult each other but
   cannot make binding cross-domain decisions.
3. **Conflict resolution** — escalate to the shared parent; design conflicts go
   to `creative-director`, technical conflicts to `technical-director`.
4. **Change propagation** — `producer` coordinates changes that cross domains.
5. **Domain boundaries** — do not modify files outside an agent's domain without
   explicit delegation.
6. **Read design docs by section** — use `grep` to find a heading and `read` with
   `offset`/`limit`. A whole-file read of a doc over 40 KB is refused by
   `validate-read.sh`; read the section you need.
7. **Nothing goes upstream** — never file, open, or comment on an issue or pull
   request in an engine, plugin, or vendor repository. Write a draft and let the
   user submit it.

The long-form version is loaded from `.opencode/docs/coordination-rules.md`.

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**

Every task follows: **Question → Options → Decision → Draft → Approval**.

- Use the `question` tool for structured choices. If it is unavailable, list
  the options numbered and end your turn. A dismissed question is not an answer:
  ask again in plain text and wait.
- Show drafts or summaries before requesting approval.
- Ask **"May I write this to [filepath]?"** before using `write` or `edit`.
  Exemptions: appends to `production/session-state/active.md`, agent memory under
  `.claude/agent-memory/`, and a subagent's new file at the path its
  orchestrating skill named.
- Multi-file changes require approval for the full changeset.
- No commits without user instruction.
- A subagent returns options to its caller; the caller puts them to the user.

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for the full protocol.

## Model Selection

The studio does **not** pin models. Every agent and command inherits the model
selected in OpenCode. This is intentional: the template must work with local
open-weight models as well as hosted models.

- A model used for editing workflows needs reliable tool calling and instruction
  following.
- 64k context is recommended; 32k is the practical minimum for the larger skills.
- To assign different models by role, set `model` under `agents.<name>` in
  `opencode.jsonc`. Generated agent files are not edited by hand; if you need a
  role-specific prompt change, edit `.claude/agents/` and regenerate.
- Provider examples and context-saving tips: `.opencode/docs/model-selection.md`.

## Commands

Type `/` in OpenCode to access the 74 workflow commands. Each command loads the
matching generated skill and passes `$ARGUMENTS` to it.

Start with `/start`. The command asks where you are, sets `project.yaml`, and
names the next step. It never runs that step for you.

Representative commands:

- `/start`, `/help`, `/project-stage-detect`, `/setup-engine`, `/settings`
- `/brainstorm`, `/map-systems`, `/design-system`, `/quick-design`
- `/create-architecture`, `/architecture-decision`, `/architecture-review`
- `/create-epics`, `/create-stories`, `/dev-story`, `/story-done`
- `/gate-check`, `/design-review`, `/code-review`, `/smoke-check`
- `/team-combat`, `/team-narrative`, `/team-ui`, `/team-release`

## Context Management

`production/session-state/active.md` is the session checkpoint. The file is the
memory, not the conversation. Read it first after compaction, a crash, or a
restart. The OpenCode adapter re-injects the session-start context after
compaction.

Helpers in `.claude/scripts/` emit observations, never verdicts. A script that
scores or judges will eventually contradict a mode or override it cannot see.

## Coding Standards

The long-form standards are loaded from `.opencode/docs/coding-standards.md`.
The load-bearing rules:

- Gameplay values come from external config/data files, never hardcoded.
- All public APIs require doc comments.
- Prefer dependency injection over singletons.
- Write tests for gameplay logic; verify player-visible changes by running the
  game and retaining a screenshot in `production/qa/evidence/`.
- Commits use Conventional Commits and reference the story or design document.
- ADRs live in `docs/architecture/`; how many are required depends on
  `modes.workflow` in `project.yaml`.

## OpenCode-Specific Notes

- **Agents**: `.opencode/agents/` contains the `studio` primary agent and 49
  subagents. Agent permissions enforce each role's tool posture.
- **Skills and commands**: `.opencode/skills/` and `.opencode/commands/` are
  generated. Edit `.claude/skills/` and run the generator; do not edit generated
  files.
- **Hooks**: `.opencode/plugins/ccgs/` translates OpenCode events into the
  canonical `.claude/hooks/` scripts. See `.opencode/docs/hooks-reference.md`.
- **Rules**: path-scoped rules from `.claude/rules/` are injected when an agent
  first reads or edits a matching file. See `.opencode/docs/rules-reference.md`.
- **Permissions**: `.opencode/docs/permissions.md` explains the ask/allow/deny
  policy and how to customize it.
- **Sync**: after changing a canonical agent or skill, run
  `python3 tools/sync-opencode.py`. CI runs `--check`.

## First Session

If the project has no engine configured and no game concept, run `/start`.
