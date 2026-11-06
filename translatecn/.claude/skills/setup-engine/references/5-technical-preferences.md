# /setup-engine — Section 5: Populate Technical Preferences

# /setup-engine — 第 5 节：填充技术偏好

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/setup-engine` 的一部分。`SKILL.md` 指明了何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此同样适用。

## 5. Populate Technical Preferences

## 5. 填充技术偏好

**In this file:**

- Engine & Language Section
- Naming Conventions (engine defaults)
- Input & Platform Section
- Remaining Sections
- Engine Specialists Routing
- Collaborative Step

**本文件内容：**

- 引擎与语言章节
- 命名约定（引擎默认值）
- 输入与平台章节
- 其余章节
- 引擎专家路由
- 协作步骤

After updating CLAUDE.md, create or update `.claude/docs/technical-preferences.md` with
engine-appropriate defaults. Read the existing template first, then fill in:

更新 CLAUDE.md 之后，创建或更新 `.claude/docs/technical-preferences.md`，
填入适合引擎的默认值。先读取现有模板，然后填写：

### Engine & Language Section
- Fill from the engine choice made in step 4

### 引擎与语言章节
- 根据第 4 步做出的引擎选择填写

### Naming Conventions (engine defaults)

**For Godot** — see `references/godot-language-config.md` (**A2**) for GDScript, C#, and Both variants.

**For Unity (C#):**
- Classes: PascalCase (e.g., `PlayerController`)
- Public fields/properties: PascalCase (e.g., `MoveSpeed`)
- Private fields: _camelCase (e.g., `_moveSpeed`)
- Methods: PascalCase (e.g., `TakeDamage()`)
- Files: PascalCase matching class (e.g., `PlayerController.cs`)
- Constants: PascalCase or UPPER_SNAKE_CASE

**For Unreal (C++):**
- Classes: Prefixed PascalCase (`A` for Actor, `U` for UObject, `F` for struct)
- Variables: PascalCase (e.g., `MoveSpeed`)
- Functions: PascalCase (e.g., `TakeDamage()`)
- Booleans: `b` prefix (e.g., `bIsAlive`)
- Files: Match class without prefix (e.g., `PlayerController.h`)

### 命名约定（引擎默认值）

**针对 Godot** —— GDScript、C# 和 Both 变体见 `references/godot-language-config.md`（**A2**）。

**针对 Unity（C#）：**
- 类：PascalCase（例如 `PlayerController`）
- 公共字段/属性：PascalCase（例如 `MoveSpeed`）
- 私有字段：_camelCase（例如 `_moveSpeed`）
- 方法：PascalCase（例如 `TakeDamage()`）
- 文件：与类名一致的 PascalCase（例如 `PlayerController.cs`）
- 常量：PascalCase 或 UPPER_SNAKE_CASE

**针对 Unreal（C++）：**
- 类：带前缀的 PascalCase（Actor 用 `A`，UObject 用 `U`，结构体用 `F`）
- 变量：PascalCase（例如 `MoveSpeed`）
- 函数：PascalCase（例如 `TakeDamage()`）
- 布尔值：`b` 前缀（例如 `bIsAlive`）
- 文件：与去掉前缀的类名一致（例如 `PlayerController.h`）

### Input & Platform Section

Populate `## Input & Platform` using the answers gathered in Section 2 (or extracted
from the game concept). Derive the values using this mapping:

| Platform target | Gamepad Support | Touch Support |
|-----------------|-----------------|---------------|
| PC only | Partial (recommended) | None |
| Console | Full | None |
| Mobile | None | Full |
| PC + Console | Full | None |
| PC + Mobile | Partial | Full |
| Web | Partial | Partial |

### 输入与平台章节

使用第 2 节收集的答案（或从游戏概念中提取的内容）填充 `## Input & Platform`。
用以下映射推导取值：

| 目标平台 | 手柄支持 | 触控支持 |
|-----------------|-----------------|---------------|
| 仅 PC | 部分（推荐） | 无 |
| 主机 | 完整 | 无 |
| 移动 | 无 | 完整 |
| PC + 主机 | 完整 | 无 |
| PC + 移动 | 部分 | 完整 |
| Web | 部分 | 部分 |

For **Primary Input**, use the dominant input for the game genre:
- Action/RPG/platformer targeting console → Gamepad
- Strategy/point-and-click/RTS → Keyboard/Mouse
- Mobile game → Touch
- Cross-platform → ask the user

对于 **Primary Input**，使用该游戏品类的主导输入方式：
- 面向主机的动作/RPG/平台跳跃 → Gamepad
- 策略/点击式/RTS → Keyboard/Mouse
- 移动游戏 → Touch
- 跨平台 → 询问用户

> **Genre may not exist yet — check before deriving from it.** At `minimal` the
> design artifact is `design/game-brief.md`, and it is authored *after* this
> skill runs (Section 2 says so explicitly). There is no genre to map. The same
> is true at any tier when `/setup-engine` is run before the concept exists.
>
> When genre is unavailable, **ask** — do not infer one from the platform, and do
> not leave the field silently blank:
> - Prompt: "Primary input for a [2D/3D] [platform] game? Genre isn't established
>   yet — the brief comes next — so this can't be derived."
> - Options: the plausible inputs for that platform, plus
>   `Leave as [TO BE CONFIGURED]` — a legitimate answer here, revisited via
>   `/settings` once the brief exists.
>
> Gamepad Support and Touch Support still come from the platform table above;
> only Primary Input depends on genre.

> **品类可能尚不存在 —— 在据此推导前先检查。** 在 `minimal` 档位，设计资产是
> `design/game-brief.md`，而它是在本技能运行*之后*才撰写的
> （第 2 节已明确说明）。没有品类可供映射。在任何档位下，当 `/setup-engine`
> 在概念存在之前运行时，情况同样如此。
>
> 当品类不可用时，**询问** —— 不要从平台推断品类，也不要
> 让该字段悄悄留空：
> - 提示："一个 [2D/3D] [platform] 游戏的主要输入是什么？品类尚未确定
>   —— 简报随后就来 —— 所以无法推导。"
> - 选项：该平台合理可行的输入，外加
>   `Leave as [TO BE CONFIGURED]` —— 在这里是合理答案，待简报存在后
>   通过 `/settings` 重新审视。
>
> 手柄支持和触控支持仍来自上面的平台表格；
> 只有 Primary Input 取决于品类。

Present the derived values and ask the user to confirm or adjust before writing.

展示推导出的取值，并在写入前请用户确认或调整。

Example filled section:
```markdown
## Input & Platform
- **Target Platforms**: PC, Console
- **Input Methods**: Keyboard/Mouse, Gamepad
- **Primary Input**: Gamepad
- **Gamepad Support**: Full
- **Touch Support**: None
- **Platform Notes**: All UI must support d-pad navigation. No hover-only interactions.
```

填写后的章节示例：
```markdown
## Input & Platform
- **Target Platforms**: PC, Console
- **Input Methods**: Keyboard/Mouse, Gamepad
- **Primary Input**: Gamepad
- **Gamepad Support**: Full
- **Touch Support**: None
- **Platform Notes**: All UI must support d-pad navigation. No hover-only interactions.
```

### Remaining Sections
- **Performance Budgets**: Use `AskUserQuestion`:
  - Prompt: "Should I set default performance budgets now, or leave them for later?"
  - Options: `[A] Set defaults now (60fps, 16.6ms frame budget, engine-appropriate draw call limit)` / `[B] Leave as [TO BE CONFIGURED] — I'll set these when I know my target hardware`
  - If [A]: populate with the suggested defaults. If [B]: leave as placeholder.
- **Testing**: Suggest the engine-appropriate framework — **gdUnit4** for Godot,
  NUnit for Unity, Automation Spec for Unreal — and ask before adding.
  > **Must match `commands.test` in Section 5.5.1, which writes gdUnit4's own
  > runner (`res://addons/gdUnit4/bin/GdUnitCmdTool.gd`), and
  > `.claude/docs/coding-standards.md`, which names the same runner.** Naming GUT
  > here would have the skill recommend one framework and configure another in the
  > same run.
- **Forbidden Patterns**: Leave as placeholder — do NOT pre-populate.
- **Allowed Libraries**: Leave as placeholder — do NOT pre-populate dependencies the project does not currently need. Only add a library here when it is actively being integrated, not speculatively.

### 其余章节
- **性能预算**：使用 `AskUserQuestion`：
  - 提示："我现在就设置默认的性能预算，还是留待以后？"
  - 选项：`[A] Set defaults now (60fps, 16.6ms frame budget, engine-appropriate draw call limit)` / `[B] Leave as [TO BE CONFIGURED] — I'll set these when I know my target hardware`
  - 如果选 [A]：用建议的默认值填充。如果选 [B]：留作占位符。
- **测试**：建议使用适合引擎的框架 —— Godot 用 **gdUnit4**、
  Unity 用 NUnit、Unreal 用 Automation Spec —— 并在添加前询问。
  > **必须与第 5.5.1 节的 `commands.test` 一致，那里写的是 gdUnit4 自带的
  > 运行器（`res://addons/gdUnit4/bin/GdUnitCmdTool.gd`），并且要与
  > `.claude/docs/coding-standards.md` 一致，那里命名的是同一个运行器。**
  > 此处写 GUT 会导致技能在同一次运行中推荐一个框架却配置另一个。
- **禁止模式**：留作占位符 —— **不要**预先填充。
- **允许的库**：留作占位符 —— **不要**预先填充项目当前并不需要的依赖。只有当一个库正在被实际集成时才在此添加，而非凭推测添加。

> **护栏**：绝不要向"允许的库"添加推测性的依赖。例如，除非本会话正在开始 Steam 集成，否则**不要**添加 GodotSteam。发布后的集成本应在该项工作开始时才加入"允许的库"，而不是在引擎设置期间。

### Engine Specialists Routing

Also populate the `## Engine Specialists` section in `technical-preferences.md` with the correct routing for the chosen engine:

**For Godot** — see `references/godot-language-config.md` (**A3**) for the routing table matching the language chosen.

**For Unity:**
```markdown
## Engine Specialists
- **Primary**: unity-specialist
- **Language/Code Specialist**: unity-specialist (C# review — primary covers it)
- **Shader Specialist**: unity-shader-specialist (Shader Graph, HLSL, URP/HDRP materials)
- **UI Specialist**: unity-ui-specialist (UI Toolkit UXML/USS, UGUI Canvas, runtime UI)
- **Additional Specialists**: unity-dots-specialist (ECS, Jobs system, Burst compiler), unity-addressables-specialist (asset loading, memory management, content catalogs)
- **Routing Notes**: Invoke primary for architecture and general C# code review. Invoke DOTS specialist for any ECS/Jobs/Burst code. Invoke shader specialist for rendering and visual effects. Invoke UI specialist for all interface implementation. Invoke Addressables specialist for asset management systems.

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.cs files) | unity-specialist |
| Shader / material files (.shader, .shadergraph, .mat) | unity-shader-specialist |
| UI / screen files (.uxml, .uss, Canvas prefabs) | unity-ui-specialist |
| Scene / prefab / level files (.unity, .prefab) | unity-specialist |
| Native extension / plugin files (.dll, native plugins) | unity-specialist |
| General architecture review | unity-specialist |
```

**For Unreal:**
```markdown
## Engine Specialists
- **Primary**: unreal-specialist
- **Language/Code Specialist**: ue-blueprint-specialist (Blueprint graphs) or unreal-specialist (C++)
- **Shader Specialist**: unreal-specialist (no dedicated shader specialist — primary covers materials)
- **UI Specialist**: ue-umg-specialist (UMG widgets, CommonUI, input routing, widget styling)
- **Additional Specialists**: ue-gas-specialist (Gameplay Ability System, attributes, gameplay effects), ue-replication-specialist (property replication, RPCs, client prediction, netcode)
- **Routing Notes**: Invoke primary for C++ architecture and broad engine decisions. Invoke Blueprint specialist for Blueprint graph architecture and BP/C++ boundary design. Invoke GAS specialist for all ability and attribute code. Invoke replication specialist for any multiplayer or networked systems. Invoke UMG specialist for all UI implementation.

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.cpp, .h files) | unreal-specialist |
| Shader / material files (.usf, .ush, Material assets) | unreal-specialist |
| UI / screen files (.umg, UMG Widget Blueprints) | ue-umg-specialist |
| Scene / prefab / level files (.umap, .uasset) | unreal-specialist |
| Native extension / plugin files (Plugin .uplugin, modules) | unreal-specialist |
| Blueprint graphs (.uasset BP classes) | ue-blueprint-specialist |
| General architecture review | unreal-specialist |
```

### 引擎专家路由

还要用适合所选引擎的正确路由，填充 `technical-preferences.md` 中的 `## Engine Specialists` 章节：

**针对 Godot** —— 与所选语言相匹配的路由表见 `references/godot-language-config.md`（**A3**）。

**针对 Unity：**
```markdown
## Engine Specialists
- **Primary**: unity-specialist
- **Language/Code Specialist**: unity-specialist (C# review — primary covers it)
- **Shader Specialist**: unity-shader-specialist (Shader Graph, HLSL, URP/HDRP materials)
- **UI Specialist**: unity-ui-specialist (UI Toolkit UXML/USS, UGUI Canvas, runtime UI)
- **Additional Specialists**: unity-dots-specialist (ECS, Jobs system, Burst compiler), unity-addressables-specialist (asset loading, memory management, content catalogs)
- **Routing Notes**: Invoke primary for architecture and general C# code review. Invoke DOTS specialist for any ECS/Jobs/Burst code. Invoke shader specialist for rendering and visual effects. Invoke UI specialist for all interface implementation. Invoke Addressables specialist for asset management systems.

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.cs files) | unity-specialist |
| Shader / material files (.shader, .shadergraph, .mat) | unity-shader-specialist |
| UI / screen files (.uxml, .uss, Canvas prefabs) | unity-ui-specialist |
| Scene / prefab / level files (.unity, .prefab) | unity-specialist |
| Native extension / plugin files (.dll, native plugins) | unity-specialist |
| General architecture review | unity-specialist |
```

**针对 Unreal：**
```markdown
## Engine Specialists
- **Primary**: unreal-specialist
- **Language/Code Specialist**: ue-blueprint-specialist (Blueprint graphs) or unreal-specialist (C++)
- **Shader Specialist**: unreal-specialist (no dedicated shader specialist — primary covers materials)
- **UI Specialist**: ue-umg-specialist (UMG widgets, CommonUI, input routing, widget styling)
- **Additional Specialists**: ue-gas-specialist (Gameplay Ability System, attributes, gameplay effects), ue-replication-specialist (property replication, RPCs, client prediction, netcode)
- **Routing Notes**: Invoke primary for C++ architecture and broad engine decisions. Invoke Blueprint specialist for Blueprint graph architecture and BP/C++ boundary design. Invoke GAS specialist for all ability and attribute code. Invoke replication specialist for any multiplayer or networked systems. Invoke UMG specialist for all UI implementation.

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.cpp, .h files) | unreal-specialist |
| Shader / material files (.usf, .ush, Material assets) | unreal-specialist |
| UI / screen files (.umg, UMG Widget Blueprints) | ue-umg-specialist |
| Scene / prefab / level files (.umap, .uasset) | unreal-specialist |
| Native extension / plugin files (Plugin .uplugin, modules) | unreal-specialist |
| Blueprint graphs (.uasset BP classes) | ue-blueprint-specialist |
| General architecture review | unreal-specialist |
```

### Collaborative Step
Present the filled-in preferences to the user. For Godot, include the chosen language and note where the full naming conventions and routing tables live:
> "Here are the default technical preferences for [engine] ([language if Godot]). The naming conventions and specialist routing are in this skill's references directory — I'll apply the [GDScript/C#/Both] variant. Want to customize any of these, or may I save them to `.claude/docs/technical-preferences.md`?"

For all other engines, present the defaults directly without referencing the appendix.

Wait for approval before writing the file.

### 协作步骤
将填写好的偏好展示给用户。对于 Godot，包含所选语言，并说明完整的命名约定和路由表位于何处：
> "以下是 [engine]（[language if Godot]）的默认技术偏好。命名约定和专家路由位于本技能的 references 目录中 —— 我将应用 [GDScript/C#/Both] 变体。你想自定义其中任何一项吗，还是我可以把它们保存到 `.claude/docs/technical-preferences.md`？"

对于所有其他引擎，直接展示默认值，无需引用附录。

在写入文件之前等待批准。

---
