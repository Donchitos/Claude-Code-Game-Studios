# Quick Start

Codex Game Studios is a project template containing 73 Codex skills, 49
injectable role profiles, 11 project hook scripts, and 11 path-scoped
`AGENTS.md` rule sets.

## 1. Create Your Project

Install the Codex CLI, then clone this repository or create a new GitHub
repository from it:

```bash
git clone https://github.com/nghgdong/Code-Game-Studios.git my-game
cd my-game
codex
```

The supported workflow is to run Codex from the cloned project root. Although
`.codex-plugin/plugin.json` makes the repository package-ready, this repository
does not publish a marketplace entry and cannot be installed directly with
`codex plugin add`.

## 2. Review Before Trusting

Before approving project trust, inspect:

- root and nested `AGENTS.md` files
- any skill or role profile you plan to use

## 3. Configure The Project

Edit the technology placeholders in `AGENTS.md`:

- engine and version
- implementation language
- build and test commands
- asset pipeline and platform targets

Then update the matching version file under `docs/engine-reference/`. Keep
project-specific instruction changes in `AGENTS.md` or the nearest nested
`AGENTS.md`; see `rules-reference.md` for precedence.

For personal, uncommitted guidance, copy `AGENTS.md` content selectively into
`AGENTS.override.md`. That file is ignored by this template. See
`codex-configuration.md` for the boundary between project and personal config.

## 4. Start The Studio Workflow

Use exact `$skill-name` syntax in your Codex prompt:

```text
$start
```

`$start` is the main entry point when the project concept or engine is not yet
configured. Common follow-ups include:

```text
$brainstorm a compact tactics game for two players
$setup-engine Godot 4 and GDScript
$map-systems
$gate-check pre-production
```

Use `$help` when you know the current situation but not the next workflow. The
full catalog is in `skills-reference.md`.

## 5. Delegate With A Role Profile

Files in `roles/` are prompt profiles, not registered custom Codex agent types.
Ask the coordinating agent to give a generic delegated agent a bounded task and
the appropriate profile:

```text
Delegate a read-only architecture review using roles/technical-director.md.
Review design/gdd/ and return risks, evidence, and open decisions.
```

The coordinating agent validates delegated findings and remains responsible for
the final recommendation and any file changes. Browse `agent-roster.md` for all
49 profiles.

## 6. Use The Collaboration Protocol

The default sequence is:

**Question -> Options -> Decision -> Draft -> Approval -> Write**

If your prompt already authorizes implementation, Codex can proceed within that
approved scope. Otherwise, workflows should present a short SPEC or draft and
wait before writing. Use narrow tasks, inspect outputs, and keep project history
in Git.

## 8. Validate Changes

- Run `$skill-test static all` after changing skill definitions.
- Run focused engine tests, builds, linters, or manual checks after code changes.
- Check referenced local paths and Markdown links after documentation changes.
- Run `git diff --check` before commit.

Continue with `WORKFLOW-GUIDE.md` for the full production lifecycle.
