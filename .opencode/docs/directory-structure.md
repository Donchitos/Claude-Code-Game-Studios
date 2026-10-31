# Directory Structure (OpenCode)

```text
/
├── AGENTS.md                    # OpenCode master configuration
├── CLAUDE.md                    # Claude Code master configuration
├── opencode.jsonc               # OpenCode config: agents, permissions, plugin, instructions
├── project.yaml                 # Machine-readable project config (source of truth)
├── .opencode/                   # Generated OpenCode adapter + OpenCode-only docs
│   ├── agents/                  # 49 subagents + the primary `studio` agent
│   ├── skills/                  # Generated workflow skills
│   ├── commands/                # 74 slash commands
│   ├── plugins/ccgs/            # OpenCode hook adapter
│   └── docs/                    # OpenCode-specific documentation
├── .claude/                     # Canonical Claude Code layer and shared studio core
│   ├── agents/                  # Canonical agent definitions
│   ├── skills/                  # Canonical workflow skills
│   ├── hooks/ scripts/          # Shared validation and helper scripts
│   ├── rules/                   # Path-scoped coding standards
│   └── docs/                    # Shared process docs and templates
├── <code root>/                 # Game source code — engine-specific, see below
├── assets/                      # Art, audio, VFX, shaders, data
├── design/                      # GDDs, narrative, levels, balance
├── docs/                        # Technical documentation and ADRs
├── tests/                       # Unit, integration, performance, playtest
├── tools/                       # Build/pipeline tools and the OpenCode generator
├── prototypes/                  # Throwaway prototypes (outside the code root)
├── production/                  # Sprints, milestones, releases, session state
└── studio-tests/                # QA for the skills and agents themselves
```

## The code root is engine-specific

| `engine.name` | Code root | Why it cannot be `src/` |
|---|---|---|
| **Godot** | `src/` | Godot loads from `res://` anywhere under the project root. |
| **Unity** | `Assets/` | Unity compiles **only** `Assets/` and `Packages/`. |
| **Unreal** | `Source/<Module>/` | UnrealBuildTool discovers modules under `Source/`. |

Resolve the code root from `engine.name` before writing any source file. A path
shown as `src/…` alone is a Godot example: read it as *"the code root"*.

**Tests follow the same rule:**

| `engine.name` | Test root |
|---|---|
| **Godot** | `tests/unit/`, `tests/integration/` |
| **Unity** | `Assets/Tests/EditMode/`, `Assets/Tests/PlayMode/` |
| **Unreal** | `Source/<Module>/Private/Tests/` |

## Which layer do I edit?

- **Studio behavior**: edit `.claude/agents/` or `.claude/skills/`, then run
  `python3 tools/sync-opencode.py`.
- **Project configuration**: `project.yaml`.
- **OpenCode behavior**: `opencode.jsonc`, `.opencode/docs/`, or
  `.opencode/plugins/`.
- **Generated adapter**: do not edit `.opencode/agents/`, `.opencode/skills/`,
  or `.opencode/commands/` directly.
