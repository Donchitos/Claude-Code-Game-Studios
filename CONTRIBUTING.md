# Contributing to Game Studios

Game Studios is a coordination framework for indie game development that runs in
Claude Code and OpenCode. Contributions are welcome — bug fixes, new workflows
that fill a real gap, agent improvements, OpenCode adapter fixes, and hook fixes.
PRs that don't fit the framework's direction will be closed without a lengthy
explanation.

## What Makes a Good PR

- **Bug fixes** — something is broken, here's the fix
- **New workflows** that address a gap not already covered
- **Improvements** to existing agents, skills, hooks, or the OpenCode adapter
- **Documentation corrections** — wrong info, broken references, outdated steps
- **Open-model fixes** — a workflow that fails on a tool-capable local model

Feature requests submitted as PRs will be closed. Open an issue instead.

**What this repo isn't:** this is the system that helps you build games, not a
place to store the games you build with it. GDDs, ADRs, PRDs, game concepts,
level designs, narrative docs, or any other output generated for your own project
won't be merged here.

## Dual-Harness Rule

The repository is dual-harness:

```
.claude/     canonical source, used by Claude Code and the shared core
.opencode/   generated adapter, used by OpenCode
```

**Edit `.claude/`, then regenerate.** Do not hand-edit `.opencode/agents/`,
`.opencode/skills/`, or `.opencode/commands/`.

```bash
python3 tools/sync-opencode.py
python3 tools/validate-opencode.py
```

CI runs `python3 tools/sync-opencode.py --check` and fails when the adapter is
stale. See `.opencode/docs/sync-and-maintenance.md`.

## The Non-Negotiable Technical Rules

**Skill files (canonical)**

- Skills live in `.claude/skills/<name>/SKILL.md` — the subdirectory format is
  required.
- SKILL.md must include YAML frontmatter: `name`, `description`,
  `argument-hint`, `allowed-tools`, and `model`.
- Model tier: `haiku` for read-only status checks, `opus` for multi-document
  synthesis and phase gates, `sonnet` for everything else.
- OpenCode removes the model tier and generates a command with `$ARGUMENTS`; do
  not add OpenCode-specific fields to the canonical file.

**Hooks**

- Use `grep -E` — never `grep -P` (Perl regex breaks on Windows Git Bash).
- Include fallbacks for systems without `jq` or `python`.
- Hooks run on every session start — they must exit quickly and gracefully
  (`exit 0`) when not applicable.
- When adding a hook, wire it for Claude Code in `.claude/settings.json` **and**
  for OpenCode in `.opencode/plugins/ccgs/index.ts`.

**Agents**

- New agents must include a **Collaboration Protocol** section that describes
  how the agent asks questions and defers decisions to the user.
- Agents must not modify files outside their documented domain without explicit
  user delegation.
- The OpenCode generator turns the Claude `tools:` list into permissions. Check
  that the generated agent denies the tools the role should not have.

**Reference docs**

- If your PR adds or changes a skill, agent, or hook, update the matching
  reference doc (agent-roster, skills-reference, hooks-reference, or
  rules-reference). PRs that add things without updating the index will be sent
  back.
- OpenCode-specific docs live in `.opencode/docs/`.

## The Collaborative Principle

Game Studios is not an autonomous system. Every workflow follows:
**Question → Options → Decision → Draft → Approval → Write**

Skills and agents must ask before acting. Nothing writes to files without
explicit user confirmation. If your contribution has an agent making decisions
or writing files unilaterally, it won't be merged.

## Testing Your Changes

Run it in **both** harnesses where the change applies:

- **Claude Code** — invoke the skill, trigger the agent, or fire the hook.
- **OpenCode** — run `/start` and the changed workflow with a tool-capable model.
  Confirm the command loads the skill, the agent's permissions match its role,
  and the hook fires.

For skills, verify the output matches what the skill claims to do. For hooks,
trigger the event and confirm the hook fires and exits cleanly. Include a brief
note in your PR description describing what you tested and what the output
looked like.

## Commit Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add /retrospective workflow for end-of-sprint reviews
fix: correct grep -P usage in session-start hook
docs: update OpenCode model-selection guide
```

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`

## PR Process

- Your PR will be auto-assigned to the maintainer via CODEOWNERS.
- Reviews happen when they happen — this is a solo-maintained project.
- If your PR sits open without feedback for a few weeks, a nudge comment is fine.
- Merged contributors are credited in release notes.

## Platform Compatibility

Game Studios must work on Windows (Git Bash), macOS, and Linux. If your hook or
script uses anything platform-specific, it will be rejected. When in doubt, test
on Windows.
