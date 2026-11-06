# Path-Specific Rules
# 路径特定规则

Rules in `.claude/rules/` carry `paths:` frontmatter. Claude Code loads a
path-scoped rule **when it READS a file matching one of those globs** — not on
every tool use, and not when it creates one.
`.claude/rules/` 中的规则带有 `paths:` 前置元数据。Claude Code 在**读取匹配
其中某个 glob 的文件时**加载路径作用域规则 — 不是每次工具使用，
也不是在创建文件时。

Three consequences, and none of them are optional reading:
三个后果，而且没有一个是可以跳过的内容：

1. **Reading, not editing.** A rule scoped to a gameplay folder reaches the
   model when a file there is opened. An agent that writes a brand-new file in that
   directory without opening an existing one never sees it. Most work in this
   framework creates files rather than reads them, so this is the common case,
   not the corner case.
1. **是读取，不是编辑。** 作用于 gameplay 文件夹的规则在该处的文件被打开时才
   到达模型。智能体若在该目录中写入一个全新的文件而从未打开现有文件，就永远看不到它。
   本框架中的大多数工作是创建文件而不是读取文件，所以这是常见情形，
   不是边缘情形。
2. **Context, not enforcement.** A loaded rule is guidance the model weighs, the
   same as `CLAUDE.md`. Anything that must hold regardless of what the model
   decides belongs in a hook — `.claude/hooks/` already enforces JSON validity
   and commit shape that way.
2. **是上下文，不是强制执行。** 已加载的规则是模型权衡的指导，
   与 `CLAUDE.md` 相同。任何无论模型如何决定都必须成立的内容都属于钩子 —
   `.claude/hooks/` 已经用这种方式强制 JSON 有效性和提交格式。
3. **A rule with no `paths:` loads every session**, at the same priority as
   `.claude/CLAUDE.md`. That is the lever for a rule that must always apply; it
   costs context in every session, so it is a deliberate trade, not a default.
3. **没有 `paths:` 的规则会在每个会话加载**，优先级与
   `.claude/CLAUDE.md` 相同。这是让规则始终适用的杠杆；它会在每个会话中
   消耗上下文，因此这是刻意的权衡，不是默认值。

Where a rule duplicates guidance an agent definition already carries, the two
must agree. Contradicting instructions are resolved arbitrarily, so a rule and
an agent stating different versions of the same standard is worse than either
alone.
当规则重复了智能体定义已经携带的指导时，两者必须一致。相互矛盾的指令
会被任意地解决，因此一条规则和一个智能体陈述同一标准的不同版本，
比两者单独存在都更糟。

To see which rules actually load, and why, wire the `InstructionsLoaded` hook —
`.claude/hooks/log-instructions.sh` records every instruction file and its load
reason (`session_start`, `path_glob_match`, `nested_traversal`, `include`,
`compact`) to `production/session-logs/instructions-loaded.log`.
要查看哪些规则实际加载以及为什么加载，接入 `InstructionsLoaded` 钩子 —
`.claude/hooks/log-instructions.sh` 记录每个指令文件及其加载
原因（`session_start`、`path_glob_match`、`nested_traversal`、`include`、
`compact`）到 `production/session-logs/instructions-loaded.log`。

**Globs match regardless of case.** Claude Code 2.1.282 matches `paths:`
gitignore-style and case-insensitively (observed; the docs do not say), so
`Assets/**/UI/**` also matches a Godot project's `assets/ui/` art. That is why
the Unity and Unreal code globs below name their file types.
**Glob 匹配不区分大小写。** Claude Code 2.1.282 以 gitignore 风格且不区分大小写地
匹配 `paths:`（实际观察到；文档未说明），所以
`Assets/**/UI/**` 也会匹配 Godot 项目的 `assets/ui/` 美术资源。这就是
下面 Unity 和 Unreal 的代码 glob 会指明文件类型的原因。

Paths are listed Godot · Unity · Unreal. Folder names are shown in one case;
each rule's own globs list the case variants (`{AI,Ai,ai}`).
路径按 Godot · Unity · Unreal 列出。文件夹名只显示一种大小写；
每条规则自己的 glob 会列出大小写变体（`{AI,Ai,ai}`）。

| Rule File | Path Pattern | Enforces |
| ---- | ---- | ---- |
| `gameplay-code.md` | `src/gameplay/**` · `Assets/**/Gameplay/**/*.cs` · `Source/**/Gameplay/**/*.{h,cpp}` | Data-driven values, delta time, no UI references |
| `engine-code.md` | `src/core/**` · `Assets/**/Core/**/*.cs` · `Source/**/Core/**/*.{h,cpp}` | Zero allocs in hot paths, thread safety, API stability |
| `ai-code.md` | `src/ai/**` · `Assets/**/AI/**/*.cs` · `Source/**/AI/**/*.{h,cpp}` | Performance budgets, debuggability, data-driven params |
| `network-code.md` | `src/networking/**` · `Assets/**/Network(ing)/**/*.cs` · `Source/**/Network(ing)/**/*.{h,cpp}` | Server-authoritative, versioned messages, security |
| `ui-code.md` | `src/ui/**` · `Assets/**/UI/**/*.cs` · `Source/**/UI/**/*.{h,cpp}` | No game state ownership, localization-ready, accessibility |
| `design-docs.md` | `design/gdd/**` | Required sections per `modes.workflow` (8 at `full`, 5 at `standard`), formula format, edge cases |
| `narrative.md` | `design/narrative/**` | Lore consistency, character voice, canon levels |
| `data-files.md` | `assets/data/**/*.json` · `Assets/**/Data/**/*.json` · `Content/**/Data/**/*.json` | JSON validity, naming conventions, schema rules |
| `test-standards.md` | `tests/**` · `Assets/Tests/**/*.cs` · `Source/**/Tests/**/*.{h,cpp}` | Test naming, coverage requirements, fixture patterns |
| `prototype-code.md` | `prototypes/**` | Relaxed standards, README required, hypothesis documented |
| `shader-code.md` | `assets/shaders/**`, `**/*.gdshader` · `Assets/**/*.{shader,hlsl,cginc,compute,shadergraph}` · `Shaders/**`, `**/*.{usf,ush}` | Naming conventions, performance targets, cross-platform rules |
| `scene-files.md` | `**/*.tscn`, `**/*.tres` · `**/*.unity`, `**/*.prefab`, `Assets/**/*.asset` · — | Hand-edit limits for editor-written scene and asset files; Unreal `.uasset`/`.umap` are binary, and `settings.json` denies edits to them |
| `agent-memory.md` | `.claude/agent-memory/**` | The one place an agent may write unasked — and why a temporary absence must never be recorded as a durable fact |
| `skill-authoring.md` | `.claude/skills/**`, `.claude/agents/**` | A check must be able to report that it did not run — the five obligations for verdicts, defaults, skips, sourcing and derived coverage |

| 规则文件 | 路径模式 | 强制执行内容 |
| ---- | ---- | ---- |
| `gameplay-code.md` | `src/gameplay/**` · `Assets/**/Gameplay/**/*.cs` · `Source/**/Gameplay/**/*.{h,cpp}` | 数据驱动数值、delta time、不引用 UI |
| `engine-code.md` | `src/core/**` · `Assets/**/Core/**/*.cs` · `Source/**/Core/**/*.{h,cpp}` | 热路径零分配、线程安全、API 稳定性 |
| `ai-code.md` | `src/ai/**` · `Assets/**/AI/**/*.cs` · `Source/**/AI/**/*.{h,cpp}` | 性能预算、可调试性、数据驱动参数 |
| `network-code.md` | `src/networking/**` · `Assets/**/Network(ing)/**/*.cs` · `Source/**/Network(ing)/**/*.{h,cpp}` | 服务器权威、带版本的消息、安全性 |
| `ui-code.md` | `src/ui/**` · `Assets/**/UI/**/*.cs` · `Source/**/UI/**/*.{h,cpp}` | 不持有游戏状态、可本地化、无障碍 |
| `design-docs.md` | `design/gdd/**` | 按 `modes.workflow` 要求的章节（`full` 为 8 个，`standard` 为 5 个）、公式格式、边缘情况 |
| `narrative.md` | `design/narrative/**` | 世界观一致性、角色口吻、正典等级 |
| `data-files.md` | `assets/data/**/*.json` · `Assets/**/Data/**/*.json` · `Content/**/Data/**/*.json` | JSON 有效性、命名约定、结构模式规则 |
| `test-standards.md` | `tests/**` · `Assets/Tests/**/*.cs` · `Source/**/Tests/**/*.{h,cpp}` | 测试命名、覆盖率要求、夹具模式 |
| `prototype-code.md` | `prototypes/**` | 放宽的标准、必需 README、记录假设 |
| `shader-code.md` | `assets/shaders/**`, `**/*.gdshader` · `Assets/**/*.{shader,hlsl,cginc,compute,shadergraph}` · `Shaders/**`, `**/*.{usf,ush}` | 命名约定、性能目标、跨平台规则 |
| `scene-files.md` | `**/*.tscn`, `**/*.tres` · `**/*.unity`, `**/*.prefab`, `Assets/**/*.asset` · — | 对编辑器编写的场景和资产文件的手工编辑限制；Unreal 的 `.uasset`/`.umap` 是二进制文件，`settings.json` 禁止编辑它们 |
| `agent-memory.md` | `.claude/agent-memory/**` | 智能体唯一可以未经请求写入的地方 — 以及为什么临时缺失绝不能记录为持久事实 |
| `skill-authoring.md` | `.claude/skills/**`, `.claude/agents/**` | 检查必须能够报告它没有运行 — 关于裁决、默认值、跳过、来源和派生覆盖的五项义务 |

Each engine-facing rule loads on all three engines:
每条面向引擎的规则在三个引擎上都会加载：

- **Code rules** (`gameplay`, `engine`, `ai`, `network`, `ui`) match
  `Assets/**/<System>/**/*.cs` and `Source/**/<System>/**/*.{h,cpp}` (`Core`,
  `AI`, `Networking`/`Network`, `UI` for the others).
- **代码规则**（`gameplay`、`engine`、`ai`、`network`、`ui`）匹配
  `Assets/**/<System>/**/*.cs` 和 `Source/**/<System>/**/*.{h,cpp}`（其他规则对应
  `Core`、`AI`、`Networking`/`Network`、`UI`）。
- **`data-files.md`** matches `Assets/**/Data/**/*.json` and `Content/**/Data/**/*.json`
  — JSON only, so C# or C++ in a `Data/` folder does not pick up its file-naming rule.
- **`data-files.md`** 匹配 `Assets/**/Data/**/*.json` 和 `Content/**/Data/**/*.json`
  — 仅限 JSON，因此 `Data/` 文件夹中的 C# 或 C++ 不会套用其文件命名规则。
- **`shader-code.md`** matches shader files by type: `.gdshader`, `.shader`,
  `.hlsl`, `.cginc`, `.compute`, `.shadergraph`, `.usf`, `.ush`, plus `Shaders/**`.
- **`shader-code.md`** 按类型匹配着色器文件：`.gdshader`、`.shader`、
  `.hlsl`、`.cginc`、`.compute`、`.shadergraph`、`.usf`、`.ush`，外加 `Shaders/**`。
- **`test-standards.md`** matches `Assets/Tests/**/*.cs` and `Source/**/Tests/**/*.{h,cpp}`.
- **`test-standards.md`** 匹配 `Assets/Tests/**/*.cs` 和 `Source/**/Tests/**/*.{h,cpp}`。
- **`scene-files.md`** is the exception: Godot and Unity scene and asset files are text and have
  rules; Unreal's are binary, so a deny rule blocks edits instead of a rule guiding them.
- **`scene-files.md`** 是例外：Godot 和 Unity 的场景与资产文件是文本，因此有规则；
  Unreal 的是二进制，所以用拒绝规则阻止编辑，而不是用规则引导它们。

> **`skill-authoring.md` is the odd one out and deliberately so.** Every other
> rule here scopes a *game* directory; that one scopes the **framework's own**
> authoring paths. It exists because one failure shape kept recurring across
> unrelated subsystems — a step that could not run producing output
> indistinguishable from a step that ran and found nothing. The same mistake in
> nine places is a missing design rule, not nine mistakes.
> **`skill-authoring.md` 是异类，而且是刻意的。** 这里其他每条规则都作用于
> *游戏*目录；那一条作用于**框架自身**的创作路径。它的存在是因为一种失败形态
> 在互不相关的子系统中反复出现 — 一个无法运行的步骤产生的输出，
> 与一个运行了却什么也没找到的步骤无法区分。同一个错误出现在九个地方，
> 说明缺少一条设计规则，而不是九个错误。
