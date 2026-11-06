# Directory Structure
# 目录结构

```text
/
├── CLAUDE.md                    # Master configuration
├── project.yaml                 # Machine-readable project config — engine, modes, stage (source of truth)
├── .claude/                     # Agent definitions, skills, hooks, rules, docs
├── <code root>/                 # Game source code — THE PATH IS ENGINE-SPECIFIC, see below
├── assets/                      # Game assets (art, audio, vfx, shaders, data)
├── design/                      # Game design documents (gdd, narrative, levels, balance)
├── docs/                        # Technical documentation (architecture, api, postmortems)
│   └── engine-reference/        # Curated engine API snapshots (version-pinned)
├── tests/                       # Game test suites (unit, integration, performance, playtest)
├── tools/                       # Build and pipeline tools (ci, build, asset-pipeline)
├── prototypes/                  # Throwaway prototypes (outside the code root)
├── production/                  # Production management (sprints, milestones, releases)
│   ├── session-state/           # Ephemeral session state (active.md — gitignored)
│   └── session-logs/            # Session audit trail (gitignored)
└── studio-tests/                # QA for the skills/agents themselves — /skill-test, /skill-improve
```

## The code root is engine-specific
## 代码根因引擎而异

**Two of the three supported engines will not build a project whose code sits in
`src/`.** This is not a style preference — it is a hard constraint of the engine's
own toolchain:
**三种受支持引擎中的两种不会构建代码位于 `src/` 的项目。** 这不是风格偏好 — 而是引擎自身工具链的硬性约束：

| `engine.name` | Code root | Why it cannot be `src/` |
| `engine.name` | 代码根 | 为什么不能是 `src/` |
|---|---|---|
| **Godot** | `src/` | No constraint — Godot loads from `res://` anywhere under the project root. |
| **Godot** | `src/` | 无约束 — Godot 从项目根下任何位置的 `res://` 加载。 |
| **Unity** | `Assets/` | Unity compiles **only** `Assets/` and `Packages/`. Code outside them is invisible to the compiler. |
| **Unity** | `Assets/` | Unity **仅**编译 `Assets/` 和 `Packages/`。它们之外的代码对编译器不可见。 |
| **Unreal** | `Source/<Module>/` | UnrealBuildTool discovers modules under `Source/`; content lives in `Content/`. A module elsewhere is not built. |
| **Unreal** | `Source/<Module>/` | UnrealBuildTool 在 `Source/` 下发现模块；内容位于 `Content/`。其他位置的模块不会被构建。 |

**Resolve the code root from `engine.name` before writing any source file.** A
path shown as `src/…` alone is a Godot example: read it as *"the code root"* and
substitute the row above. `src/` is the table's Godot row, not a universal path.
**在编写任何源文件之前，从 `engine.name` 解析代码根。** 仅显示为 `src/…` 的路径是 Godot 示例：将其读作*"代码根"*并替换为上表中的行。`src/` 是表中的 Godot 行，不是通用路径。

**Tests follow the same rule** — the same compilers decide what they see:
**测试遵循相同规则** — 相同的编译器决定它们能看到什么：

| `engine.name` | Test root | Anywhere else |
| `engine.name` | 测试根 | 其他任何位置 |
|---|---|---|
| **Godot** | `tests/unit/`, `tests/integration/` | — |
| **Godot** | `tests/unit/`、`tests/integration/` | — |
| **Unity** | `Assets/Tests/EditMode/`, `Assets/Tests/PlayMode/` | not compiled: "0 tests, Passed" |
| **Unity** | `Assets/Tests/EditMode/`、`Assets/Tests/PlayMode/` | 不编译："0 tests, Passed" |
| **Unreal** | `Source/<Module>/Private/Tests/` | not built: "No automation tests matched" |
| **Unreal** | `Source/<Module>/Private/Tests/` | 不构建："No automation tests matched" |

Read `tests/unit/[system]/` (or `integration/`) anywhere as the test root plus `[System]/`.
将任何位置的 `tests/unit/[system]/`（或 `integration/`）读作测试根加 `[System]/`。
