# Codex Game Studios

Codex-native project scaffolding for running an indie game studio with focused
workflows, role prompts, review gates, and path-scoped instructions.

[![Role profiles: 49](https://img.shields.io/badge/role_profiles-49-2563eb)](roles/)
[![Codex skills: 73](https://img.shields.io/badge/Codex_skills-73-15803d)](skills/)
[![Nested rules: 11](https://img.shields.io/badge/nested_AGENTS_rules-11-b91c1c)](docs/studio/rules-reference.md)

## What Is Included

- **73 Codex skills** in `skills/<name>/SKILL.md` for design, architecture,
  production, implementation, QA, release, and live operations.
- **49 role profiles** in `roles/<name>.md`. These are prompts that can be
  supplied to generic delegated agents; they are not registered custom agent
  types.
- **11 path-scoped instruction sets** implemented as nested `AGENTS.md` files
  for code, data, design, narrative, prototypes, shaders, UI, networking, AI,
  gameplay, and tests.
- Studio references, workflow examples, and reusable templates under `docs/`.

## Prerequisite

Install the [Codex CLI](https://developers.openai.com/codex/cli/) and make sure
the `codex` command is available. Git is required to clone the template.

## Use This Repository As A Project Template

Clone the repository into the game project you want Codex to work in:

```bash
git clone https://github.com/nghgdong/Code-Game-Studios.git my-game
cd my-game
codex
```

You can also create a repository from this template on GitHub, clone that new
repository, and open Codex from its root. Update the engine and language choices
in `AGENTS.md` before beginning engine-specific implementation.

The `.codex-plugin/plugin.json` manifest makes the repository package-ready.
This repository does not currently publish a Codex marketplace entry, so there
is no direct `codex plugin add` installation flow for it. The supported usage is
to clone or copy the repository as a project template.

## Run A Skill

Invoke skills by name with the Codex skill syntax:

```text
$start
$brainstorm a cooperative deck-building game
$setup-engine Godot 4 with GDScript
$gate-check pre-production
```

Use `$help` for a workflow-oriented skill index, or browse
[`docs/studio/skills-reference.md`](docs/studio/skills-reference.md). Skill
arguments are supplied as normal text after the skill name.

## Use A Role Profile

Role files describe expertise, responsibilities, boundaries, and collaboration
behavior. To use one, ask Codex to delegate a bounded task to a generic agent
and inject the relevant profile:

```text
Review the save-system design using roles/security-engineer.md as the role
profile. Return findings only; do not edit files.
```

The coordinating agent remains responsible for scope, user approval, review,
and the final result. See [`docs/studio/agent-roster.md`](docs/studio/agent-roster.md)
and [`docs/studio/agent-coordination-map.md`](docs/studio/agent-coordination-map.md).

## How Project Instructions Work

`AGENTS.md` defines repository-wide guidance. Nested `AGENTS.md` files add or
override instructions for files beneath their directory, with the nearest file
taking precedence. The 11 migrated path rules are:

- `assets/data/AGENTS.md`
- `assets/shaders/AGENTS.md`
- `design/gdd/AGENTS.md`
- `design/narrative/AGENTS.md`
- `prototypes/AGENTS.md`
- `src/ai/AGENTS.md`
- `src/core/AGENTS.md`
- `src/gameplay/AGENTS.md`
- `src/networking/AGENTS.md`
- `src/ui/AGENTS.md`
- `tests/AGENTS.md`

Umbrella instructions also exist at `src/AGENTS.md`, `design/AGENTS.md`, and
`docs/AGENTS.md`. See [`docs/studio/rules-reference.md`](docs/studio/rules-reference.md)
for the precedence model and rule mapping.

## Repository Layout

```text
AGENTS.md                    Repository-wide Codex instructions
.codex-plugin/plugin.json    Package manifest
skills/<name>/               Codex skill plus agents/openai.yaml metadata
roles/<name>.md              Injectable specialist prompt profiles
docs/studio/                 Studio operating references and templates
docs/examples/               End-to-end workflow examples
docs/engine-reference/       Version-pinned engine guidance
design/                      Game design and narrative documents
src/                         Engine and game implementation
tests/                       Automated and manual test assets
```

For the complete layout, see
[`docs/studio/directory-structure.md`](docs/studio/directory-structure.md).

## Collaboration Model

The framework is user-directed. Workflows should present evidence and options,
record the user's decision, show the intended scope, and obtain approval before
writing unless the user has already authorized execution. A role profile or
skill never transfers final responsibility away from the coordinating agent.

Read [`docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`](docs/COLLABORATIVE-DESIGN-PRINCIPLE.md)
for the detailed protocol.

## Validation

- Run `$skill-test static all` in Codex after changing skill definitions.
- Validate `.codex-plugin/plugin.json` with a JSON parser and the current Codex plugin validator used by the project.
- Run `git diff --check` before submitting changes.

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for contribution-specific checks.

## Platform Notes

Hook scripts target POSIX-compatible Bash. Windows contributors should use Git
Bash; macOS and Linux contributors can use their system Bash. Hooks must fail
clearly or exit harmlessly when an optional tool is unavailable.

## License And History

Released under the [MIT License](LICENSE). See [UPGRADING.md](UPGRADING.md) for
the concise migration history and upgrade guidance.
