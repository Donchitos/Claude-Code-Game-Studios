# Directory Structure

The current repository is a Codex project template. Paths shown here exist in a
fresh checkout unless marked as runtime-generated.

```text
/
|-- AGENTS.md                    Repository-wide Codex instructions
|-- .codex/
|-- .codex-plugin/
|   `-- plugin.json              Package-ready plugin manifest
|-- skills/                      73 Codex skills
|   `-- <name>/
|       |-- SKILL.md             Skill instructions
|       `-- agents/openai.yaml   Codex-facing skill metadata
|-- roles/                       49 injectable role prompt profiles
|   `-- memory/                  Optional role-specific project memory
|-- docs/
|   |-- AGENTS.md                Documentation-specific instructions
|   |-- studio/                  Studio references and templates
|   |-- examples/                End-to-end workflow examples
|   |-- architecture/            Architecture requirement registry data
|   |-- registry/                Documentation registries
|   `-- engine-reference/        Godot, Unity, and Unreal references
|-- design/
|   |-- AGENTS.md                Shared design instructions
|   |-- gdd/AGENTS.md            Game-design-document rules
|   |-- narrative/AGENTS.md      Narrative rules
|   `-- registry/                Design registries
|-- src/
|   |-- AGENTS.md                Shared source instructions
|   |-- ai/AGENTS.md             AI code rules
|   |-- core/AGENTS.md           Core and engine code rules
|   |-- gameplay/AGENTS.md       Gameplay code rules
|   |-- networking/AGENTS.md     Networking code rules
|   `-- ui/AGENTS.md             UI code rules
|-- assets/
|   |-- data/AGENTS.md           Data-file rules
|   `-- shaders/AGENTS.md        Shader rules
|-- tests/AGENTS.md              Test rules
|-- prototypes/AGENTS.md         Prototype rules
|-- production/
|   `-- session-state/           Optional project-owned handoff state
`-- CCGS Skill Testing Framework/  Legacy test specifications pending migration
```

Hooks may create `production/session-logs/` at runtime. The directory is ignored
by Git and should contain navigation or audit metadata only.

## Instruction Boundaries

The root `AGENTS.md` applies repository-wide. Nested files apply recursively and
the nearest file takes precedence. The framework's 11 scoped rule sets are the
files under `assets/data`, `assets/shaders`, `design/gdd`, `design/narrative`,
`prototypes`, five `src/` subsystems, and `tests/`. See `rules-reference.md`.

## Skills And Roles

Skills are discovered from `skills/<name>/SKILL.md` and invoked with
`$skill-name`. The adjacent `agents/openai.yaml` describes the skill interface.

Role files under `roles/` are not automatically registered agent types. They
are prompt profiles supplied to generic delegated agents with a bounded task.

## Hooks And Packaging

`.codex-plugin/plugin.json` describes a package-ready plugin, but the repository
does not contain a marketplace entry or support direct installation with
`codex plugin add`. Use the repository as a cloned project template.

## Project-Owned Additions

Game projects can add source, assets, design documents, tests, production
records, and engine configuration beneath these directories. Add new framework
directories only when the current project needs them, and document any new
instruction boundary with an `AGENTS.md` and an update to this reference.
