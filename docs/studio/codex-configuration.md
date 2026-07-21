# Codex Project And Personal Configuration

Codex Game Studios separates committed project behavior from personal Codex
preferences. Do not invent a project-local settings file or commit credentials
to make a workflow appear portable.

## Committed Project Configuration

| Path | Purpose |
|---|---|
| `AGENTS.md` | Repository-wide project instructions |
| Nested `AGENTS.md` | Path-scoped instructions with nearest-file precedence |
| `.codex-plugin/plugin.json` | Package metadata for the project |
| `skills/<name>/SKILL.md` | Skill instructions and invocation behavior |
| `skills/<name>/agents/openai.yaml` | Codex-facing skill interface metadata |
| `roles/<name>.md` | Injectable delegated-agent prompt profiles |

Changes to these files affect collaborators and must be reviewed like code.
## Personal Instructions

Use `AGENTS.override.md` for personal, repository-local instructions that should
not be committed. This template already ignores that filename. Keep overrides
small and avoid contradicting team security or approval rules.

Example:

```markdown
# Local Preferences

- Use the locally installed Godot executable at the path I provide in the task.
- Run focused tests before the full suite.
- Never commit or push unless I explicitly request it.
```

Do not put API keys, tokens, private URLs, or credentials in an override file.

## Personal Codex CLI Configuration

User-level Codex configuration belongs under the user's Codex home rather than
in this repository. Locations and supported keys can change, so use the current
official Codex documentation and `codex --help` for the installed version.

The CLI exposes task-level controls such as sandbox mode, approval policy,
working directory, model selection, and profiles. Choose them when launching
Codex or through supported user configuration. Do not commit personal security
relaxations as project defaults.

## Project Validation

This repository does not bundle project lifecycle hooks. Use normal repository
validation commands when changing plugin content.

See `setup-requirements.md` and `unsupported-features.md` for the supported
project behavior.
