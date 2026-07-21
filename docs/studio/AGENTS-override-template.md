# AGENTS.override.md Template

Copy the fenced content into `AGENTS.override.md` at the project root for
personal, uncommitted instructions. The template `.gitignore` excludes that
file.

```markdown
# Personal Preferences

## Workflow

- Run focused tests after code changes.
- Use a new Codex thread for unrelated work.
- Use `codex resume` to continue the same objective.
- Use `codex fork` before exploring a materially different approach.
- Never commit or push unless I explicitly request it.

## Local Environment

- Python command: [python / py / python3]
- Bash command: [bash path if not on PATH]
- Game engine executable: [local path]
- IDE: [editor]

## Communication

- Keep responses concise.
- Include exact file paths in code references.
- Explain architectural decisions and verification results.

## Shortcuts

- When I say "review", use `$code-review` on the changed files.
- When I say "status", show Git status and current sprint state.
```

Do not store credentials, API keys, private URLs, or security-policy bypasses in
the override. Personal Codex CLI configuration belongs in the user's Codex home;
see `codex-configuration.md`.
