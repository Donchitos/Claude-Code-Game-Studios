# Contributing To Codex Game Studios

Contributions are welcome when they fix a real problem, improve an existing
workflow, add a well-scoped capability, or correct documentation. Keep game
content generated for your own project in that project rather than submitting
it to this framework repository.

## Before Opening A Pull Request

- Open an issue first for substantial features or changes to public behavior.
- Keep the change focused; do not bundle unrelated refactors or generated game
  content.
- Inspect the nearest `AGENTS.md` before editing a path.
- Preserve the user-directed collaboration protocol: evidence and options first,
  approval before writes unless execution was already authorized.

## Component Conventions

### Skills

- Store each skill at `skills/<name>/SKILL.md`.
- Use YAML frontmatter with at least `name` and `description`. The `name` must
  match the directory name and the description must state when the skill should
  be used.
- Keep Codex-facing interface metadata in `skills/<name>/agents/openai.yaml`.
- Document invocation with exact `$skill-name` syntax and use that terminology
  consistently.
- Update `docs/studio/skills-reference.md` and relevant examples when behavior,
  arguments, or output paths change.

### Role Profiles

- Store profiles at `roles/<name>.md`.
- Treat a role as an injectable prompt profile for a generic delegated agent,
  not as a registered custom Codex agent type.
- Define its domain, responsibilities, boundaries, expected evidence, and
  collaboration behavior.
- Do not hard-code model selection or claim automatic role registration.
- Update `docs/studio/agent-roster.md` and the coordination map when a profile is
  added, removed, or materially changed.

### Project Instructions

- Put repository-wide instructions in `AGENTS.md`.
- Put path-scoped instructions in the nearest applicable nested `AGENTS.md`.
  Instructions apply recursively below their directory; a nearer file takes
  precedence over broader guidance.
- Add a new nested file only when a real path needs distinct rules. Avoid
  duplicating the root instructions.
- Update `docs/studio/rules-reference.md` when the rule map changes.

### Documentation And Templates

- Use current repository paths and `$skill-name` invocation examples.
- Describe role delegation generically and truthfully; interaction controls and
  model selection can vary by Codex client.
- Verify relative Markdown links and referenced local paths.
- Update indexes when adding or renaming a document.

## Collaboration Protocol

The framework is collaborative rather than autonomous:

**Question -> Options -> Decision -> Draft -> Approval -> Write**

Contributed workflows should expose assumptions, present meaningful choices,
and retain user control over scope and writes. A workflow may proceed without a
second confirmation only when the user's request already grants that authority.
Delegated agents stay within their assigned scope and return evidence to the
coordinating agent for validation.

## Validation

Run checks appropriate to the changed component:

```bash
# Whitespace and patch errors
git diff --check
```

For skill changes, open Codex in the repository and run:

```text
$skill-test static <skill-name>
$skill-test spec <skill-name>
```

Use `$skill-test static all` for a full structural pass. Validate
`.codex-plugin/plugin.json` with a JSON parser, and run
the current plugin manifest validator before changing package metadata. For
documentation changes, audit legacy terminology, skill invocation syntax,
local paths, and Markdown links.

Include the commands run, relevant output, and any skipped checks in the pull
request description.

## Commit Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```text
feat: add retrospective workflow
fix: handle Windows paths in a skill helper
docs: update qa-plan skill examples
```

Common types are `feat`, `fix`, `docs`, `chore`, `refactor`, and `test`.

## Pull Request Review

- CODEOWNERS assigns the maintainer for affected paths.
- Review focuses on correctness, security, path accuracy, backward
  compatibility, and cross-platform behavior.
- Critical and important findings must be resolved before merge.
- Maintainers may ask for a smaller changeset when a pull request combines
  independent concerns.
