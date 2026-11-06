# /setup-engine — Section 4: Update CLAUDE.md Technology Stack

# /setup-engine — 第 4 节：更新 CLAUDE.md 技术栈

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/setup-engine` 的一部分。`SKILL.md` 指明了何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此同样适用。

## 4. Update CLAUDE.md Technology Stack

## 4. 更新 CLAUDE.md 技术栈

### Language Selection (Godot only)

If Godot was chosen, ask the user which language to use **before** showing the proposed Technology Stack:

> "Godot supports two primary languages:
>
>   **A) GDScript** — Python-like, Godot-native, fastest iteration. Best for beginners, solo devs, and teams coming from Python or Lua.
>   **B) C#** — .NET 8+, familiar to Unity developers, stronger IDE tooling (Rider / Visual Studio), slight performance advantage on heavy logic.
>   **C) Both** — GDScript for gameplay/UI scripting, C# for performance-critical systems. Advanced setup — requires .NET SDK alongside Godot.
>
> Which will this project primarily use?"

Record the choice. It determines the CLAUDE.md template, naming conventions, specialist routing, and which agent is spawned for code files throughout the project.

### 语言选择（仅 Godot）

如果选择了 Godot，**在**展示建议的技术栈**之前**询问用户使用哪种语言：

> "Godot 支持两种主要语言：
>
>   **A) GDScript** —— 类 Python、Godot 原生、迭代最快。最适合初学者、单人开发者，以及来自 Python 或 Lua 的团队。
>   **B) C#** —— .NET 8+，Unity 开发者熟悉，IDE 工具更强大（Rider / Visual Studio），在重逻辑上略有性能优势。
>   **C) Both** —— GDScript 用于玩法/UI 脚本，C# 用于性能关键系统。进阶配置 —— 需要在 Godot 之外同时安装 .NET SDK。
>
> 这个项目主要使用哪一种？"

记录该选择。它决定 CLAUDE.md 模板、命名约定、专家路由，以及整个项目中代码文件会由哪个智能体生成。

### Primary Language (Unreal)

If Unreal was chosen, ask via `AskUserQuestion`: "Will most gameplay logic live in
C++ or in Blueprints?" — `[A] C++ (Blueprints for tuning and prototyping)` /
`[B] Blueprint-primary (C++ only where needed)`. Default to C++ if the user has no
preference. The answer sets `engine.language` (`"C++"` or `"Blueprint"`).

### 主要语言（Unreal）

如果选择了 Unreal，通过 `AskUserQuestion` 询问："大部分玩法逻辑会放在
C++ 还是 Blueprints 中？" —— `[A] C++ (Blueprints for tuning and prototyping)` /
`[B] Blueprint-primary (C++ only where needed)`。如果用户没有偏好，默认使用 C++。
答案会设置 `engine.language`（`"C++"` 或 `"Blueprint"`）。

---

Read `CLAUDE.md` and show the user the proposed Technology Stack changes.
Ask: "May I write these engine settings to `CLAUDE.md`?"

Wait for confirmation before making any edits.

读取 `CLAUDE.md`，并向用户展示建议的技术栈更改。
询问："我可以把这些引擎设置写入 `CLAUDE.md` 吗？"

在做任何编辑之前等待确认。

Update the Technology Stack section, replacing the `[CHOOSE]` placeholders with the actual values:

**For Godot** — use the template matching the language chosen above. See `references/godot-language-config.md` (**A1**) for all three variants (GDScript, C#, Both).

更新技术栈章节，用实际值替换 `[CHOOSE]` 占位符：

**针对 Godot** —— 使用与上面所选语言相匹配的模板。三种变体（GDScript、C#、Both）见 `references/godot-language-config.md`（**A1**）。

**For Unity:**
```markdown
- **Engine**: Unity [version]
- **Language**: C#
- **Build System**: Unity Build Pipeline
- **Asset Pipeline**: Unity Asset Import Pipeline + Addressables
```

**针对 Unity：**
```markdown
- **Engine**: Unity [version]
- **Language**: C#
- **Build System**: Unity Build Pipeline
- **Asset Pipeline**: Unity Asset Import Pipeline + Addressables
```

**For Unreal:**
```markdown
- **Engine**: Unreal Engine [version]
- **Language**: [C++ (primary), Blueprint (gameplay prototyping) | Blueprint (primary), C++ where needed]
- **Build System**: Unreal Build Tool (UBT)
- **Asset Pipeline**: Unreal Content Pipeline
```
The Language line follows the primary-language answer above: the first form for
`[A]` (`engine.language: "C++"`), the second for `[B]` (`"Blueprint"`).

**针对 Unreal：**
```markdown
- **Engine**: Unreal Engine [version]
- **Language**: [C++ (primary), Blueprint (gameplay prototyping) | Blueprint (primary), C++ where needed]
- **Build System**: Unreal Build Tool (UBT)
- **Asset Pipeline**: Unreal Content Pipeline
```
Language 行遵循上面的主要语言答案：`[A]` 使用第一种形式
（`engine.language: "C++"`），`[B]` 使用第二种形式（`"Blueprint"`）。

### Engine reference import

In the same CLAUDE.md write, set the **Engine Version Reference** import to the
chosen engine. Find the line marked `ENGINE-REFERENCE-IMPORT` (an
`@docs/engine-reference/<engine>/VERSION.md` line under its comment) and Edit it
to point at the configured engine:
- Godot → `@docs/engine-reference/godot/VERSION.md`
- Unity → `@docs/engine-reference/unity/VERSION.md`
- Unreal → `@docs/engine-reference/unreal/VERSION.md`

This keeps a Unity or Unreal project from loading the Godot reference in every
session. It is idempotent — re-running `/setup-engine` for a different
engine rewrites the same line. (The target `docs/engine-reference/<engine>/`
directory is created in Section 7, Populate Engine Reference Docs, if it does not yet exist.)

### 引擎参考导入

在同一次 CLAUDE.md 写入中，将 **Engine Version Reference** 导入设置为所选引擎。
找到标记为 `ENGINE-REFERENCE-IMPORT` 的行（其注释下方的一行
`@docs/engine-reference/<engine>/VERSION.md`），并编辑它
使其指向已配置的引擎：
- Godot → `@docs/engine-reference/godot/VERSION.md`
- Unity → `@docs/engine-reference/unity/VERSION.md`
- Unreal → `@docs/engine-reference/unreal/VERSION.md`

这样可以避免 Unity 或 Unreal 项目在每个会话中都加载 Godot 参考。它是幂等的 ——
为不同引擎重新运行 `/setup-engine` 会重写同一行。（若目标 `docs/engine-reference/<engine>/`
目录尚不存在，它会在第 7 节"填充引擎参考文档"中创建。）

---
