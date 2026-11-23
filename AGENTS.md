# Claude Code Game Studios in Codex

Use `$start` for guided onboarding, `$prototype` to build a playable concept,
or `$next-step` to find the next workflow for an existing project. Codex entry
files point to the studio's canonical workflows and role definitions in `.claude/`.

## Studio workflow

- The user is the creative director. Follow the Collaboration Protocol in
  `CLAUDE.md` for decisions and proposed writes. Honor approval the user has
  already given for the same scope. Get explicit authorization for publishing,
  committing, or destructive operations.
- Before delegating or making a cross-domain decision, read
  `.claude/docs/coordination-rules.md`. Use Codex custom subagents for named
  `Agent` or `Task` calls. Keep role boundaries and pass the relevant artifact
  paths and required return format. If a role cannot be spawned, report that
  and preserve its review gate.
- For `isolation: worktree`, delegate in a separate Git worktree and pass its
  path to the agent. If isolation is unavailable, stop that delegation before
  any edits to the shared checkout.
- Translate `AskUserQuestion` to a question in chat or the available user input
  tool. Translate `Skill` and legacy `/skill-name` references to Codex
  `$skill-name` invocations. Use Codex file, search, and editing tools for
  `Read`, `Glob`, `Grep`, `Write`, and `Edit`.
- Apply the workflow or role's Markdown body. Claude-specific tool, model,
  permission, and execution metadata does not configure the Codex runtime.
  Respect the role's documented scope and capability limits.

## Project context and verification

- Resolve project settings from the repository root. Use `project.yaml` as the
  shared configuration and honor `project.local.yaml` only for the keys in
  `.claude/docs/config-resolution.md`. Consult `.claude/docs/technical-preferences.md`
  for legacy engine settings and constraints. For Claude `!` command blocks and
  shell helpers, follow [the Codex command mapping](docs/CODEX.md#workflow-commands).
- Read `.claude/docs/directory-structure.md` when locating or creating artifacts
  and `.claude/docs/coding-standards.md` before implementing or verifying code.
  For engine APIs, read `docs/engine-reference/<engine>/VERSION.md` and check
  current official documentation when the pinned version differs or the API is
  uncertain.
- Before reading or editing scoped project files, match the repo-relative paths
  against the `paths:` frontmatter in `.claude/rules/*.md`. Read the body of each
  matching rule, including all matches for new files. Use syntax-specific globs
  from the rules for Godot, Web, Unity, and Unreal projects.
- After a compaction or restart, read `production/session-state/active.md` if
  present. Use `.claude/docs/context-management.md` for checkpoint conventions.
- On Windows, use native PowerShell 7 (`pwsh`) and Windows paths. Translate
  POSIX reads and searches to file tools, `Get-Content`, `rg`, and `rg --files`.
  For an unported helper use the documented native equivalent or report the
  unavailable check. Keep required gates pending when their evidence is missing.

## Maintaining the adapter

Change the source workflow or role in `.claude/`, then regenerate the Codex
entries with `pwsh -NoProfile -File .codex/scripts/sync-adapter.ps1`. Run
`pwsh -NoProfile -File .codex/scripts/test-adapter.ps1` before submitting changes.
