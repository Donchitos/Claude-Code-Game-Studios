# Upgrading And Migrating Codex Game Studios

This repository is the Codex-native successor to the earlier Claude Code Game
Studios layout. That source history is useful for attribution and migration,
but the current structure is designed for Codex and does not claim one-to-one
feature parity with the historical project.

## Before You Upgrade

1. Commit or stash your project work.
2. Create a backup branch or tag.
3. Record local changes to instructions, skills, hooks, role prompts, and studio
   templates.
4. Review upstream changes before merging; do not blindly overwrite project
   design documents, source code, tests, or engine configuration.

Example:

```bash
git status
git switch -c backup-before-codex-studio-upgrade
git tag codex-studio-backup-YYYY-MM-DD
```

## Historical Source To Current Target

| Historical source | Codex-native target | Migration note |
|---|---|---|
| `CLAUDE.md` | `AGENTS.md` | Rewrite instructions for Codex behavior and scope. |
| `.claude/skills/<name>/SKILL.md` | `skills/<name>/SKILL.md` | Keep `name` and `description` frontmatter; add `agents/openai.yaml` metadata. |
| `.claude/agents/<name>.md` | `roles/<name>.md` | Treat as an injectable prompt profile, not a registered agent type. |
| `.claude/rules/*.md` | Nested `AGENTS.md` files | Place each rule at the nearest directory it governs. |
| `.claude/docs/` | `docs/studio/` | Update links, commands, terminology, and behavior claims. |
| Model-specific agent metadata | Generic role guidance | Remove fixed model routing and unsupported custom-agent registration fields. |

The original project history is available at
https://github.com/Donchitos/Claude-Code-Game-Studios and remains covered by
the repository's MIT license attribution.

## Known Non-Parity Areas

- Historical Notification hooks and status-line scripts are not implemented as
  equivalent Codex features in this repository.
- Historical custom-agent registration metadata does not map directly to Codex.
  The current `roles/` files are prompt profiles supplied to generic delegated
  agents.
- Hook event payloads and availability differ. A migrated script may need new
  input parsing, and live event capture must be verified in the Codex client in
  use.
- Client interaction controls and delegation features can vary; documentation
  uses generic user prompts and task delegation rather than promising a
  particular widget or model-routing behavior.

See `docs/studio/unsupported-features.md` for the maintained degradation notes.

## Upgrade Strategies

### Merge From An Upstream Remote

Use this when your project retains Git history from the template:

```bash
git remote add codex-game-studios https://github.com/nghgdong/Code-Game-Studios.git
git fetch codex-game-studios
git merge codex-game-studios/main
```

Resolve conflicts deliberately. Project-specific `AGENTS.md` content, design
documents, engine choices, hook policy, and edited templates usually require a
manual merge.

### Copy Framework Files Manually

Use this for projects with unrelated history. Compare and selectively copy:

- `.codex-plugin/`
- `.codex/`
- `skills/`
- `roles/`
- framework references under `docs/studio/`
- the 11 path-scoped `AGENTS.md` files documented in
  `docs/studio/rules-reference.md`

Do not replace game-specific `src/`, `design/`, `assets/`, `tests/`,
`production/`, or `prototypes/` content wholesale.

## Merge Guidance

- Keep local engine versions, package choices, source layout, and build commands.
- Reconcile root and nested `AGENTS.md` files from broadest to most specific.
- Preserve project-owned skill customizations only when they remain compatible
  with the current `SKILL.md` format and `$skill-name` invocation.
- Remove obsolete historical directories only after confirming that no current
  document, hook, or local workflow references them.

## Validation After Migration

```bash
# Detect patch whitespace errors
git diff --check
```

Then:

1. Parse `.codex-plugin/plugin.json` as JSON.
2. Run the current Codex plugin manifest validator.
3. Run `$skill-test static all` and exercise the skills your project customized.
4. Search active documentation for historical paths, product instructions, and
   slash-style skill examples.

If a migrated behavior cannot be validated live, document it as a known gap
rather than claiming parity.
