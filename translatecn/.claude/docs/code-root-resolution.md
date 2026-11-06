# Code Root Resolution
# 代码根目录解析

Shared procedure for any skill that reads, scans, counts or writes game source
files. **An unresolved code root means the check did not run.** This file gives
the resolution order.
适用于任何读取、扫描、统计或写入游戏源文件的技能的共享流程。
**代码根目录无法解析意味着检查没有运行。** 本文件给出解析顺序。

`.claude/docs/directory-structure.md` is the authority for which directory holds
code. This file is the procedure for applying it.
`.claude/docs/directory-structure.md` 是代码所在目录的权威来源。
本文件是应用它的流程。

## The roots
## 各根目录

| `engine.name` | Code root | Why it cannot be `src/` |
|---|---|---|
| Godot | `src/` | No constraint; Godot loads from `res://` anywhere under the project root |
| Unity | `Assets/` | Unity compiles **only** `Assets/` and `Packages/` |
| Unreal | `Source/<Module>/` | UnrealBuildTool discovers modules under `Source/`; content lives in `Content/` |

| `engine.name` | 代码根目录 | 为什么不能是 `src/` |
|---|---|---|
| Godot | `src/` | 无约束；Godot 从项目根下任意位置的 `res://` 加载 |
| Unity | `Assets/` | Unity **只**编译 `Assets/` 和 `Packages/` |
| Unreal | `Source/<Module>/` | UnrealBuildTool 在 `Source/` 下发现模块；内容位于 `Content/` |

`src/` is the **Godot row of that table, not a universal path.**
`src/` 是**那张表的 Godot 行，不是通用路径。**

## Resolution order
## 解析顺序

1. `engine.name` from `project.local.yaml`, then `project.yaml`.
1. 先取 `project.local.yaml` 的 `engine.name`，然后取 `project.yaml`。
2. The legacy mirror: an `Engine:` line in
   `.claude/docs/technical-preferences.md`. A value of `[TO BE CONFIGURED]`
   does not count.
2. 旧版镜像：`.claude/docs/technical-preferences.md` 中的 `Engine:` 行。
   值为 `[TO BE CONFIGURED]` 不算数。
3. Derivation from the tree, but **only when it is unambiguous**. Exactly one of
   `src/`, `Assets/` or `Source/` present means that is the root. Two or more
   present means the project is genuinely undecidable — do not guess. Compare the
   names exactly as the directory listing spells them: on Windows and default
   macOS an existence test for `Assets/` also succeeds on Godot's own `assets/`,
   which would make `src/` + `assets/` look ambiguous and a lone `assets/` look
   like Unity.
3. 从目录树推导，但**仅当它无歧义时**。`src/`、`Assets/` 或 `Source/` 中恰好只有一个
   存在，意味着它就是根目录。有两个或更多存在意味着项目确实无法判定 — 不要猜。
   按目录列表的确切拼写比较名称：在 Windows 和默认 macOS 上，
   对 `Assets/` 的存在性测试也会在 Godot 自己的 `assets/` 上成功，
   这会让 `src/` + `assets/` 看起来有歧义，而单独的 `assets/` 看起来像 Unity。
4. Otherwise: **unresolved.**
4. 否则：**未解析。**

The hooks already implement exactly this as `resolve_code_root()` in
`.claude/hooks/yaml-helper.sh`. Skills must match its semantics so that a hook
and a skill never disagree about where the code lives.
钩子已经在 `.claude/hooks/yaml-helper.sh` 中以 `resolve_code_root()`
完全实现了这一点。技能必须匹配其语义，以便钩子
和技能在代码所在位置上永不产生分歧。

## Unresolved does not default to `src/`
## 未解析不会默认成 `src/`

This is the rule the whole file exists for, and it is obligation 2 of
`.claude/rules/skill-authoring.md`: an absent value may not default to the
permissive one.
这就是整个文件存在的规则，它是
`.claude/rules/skill-authoring.md` 的义务 2：缺失的值不得默认成宽松的那个。

**For a read or scan:** report `NOT ASSESSED — code root unresolved` and say
which check did not run. Never report zero hits.
**对于读取或扫描：** 报告 `NOT ASSESSED — code root unresolved`，并说明
哪个检查没有运行。绝不报告零命中。

A scan anchored to a root the project does not use matches nothing, and
**nothing is indistinguishable from a clean result.** A localization check finds
no hardcoded strings; a security scan finds no secrets; a content audit counts
no implemented content; a stage detector counts no source files and calls a
finished project greenfield. Every one of those reads as a pass. This has been
found repeatedly across skills and hooks, which is why the resolution lives in
one place now.
锚定在项目未使用的根目录上的扫描什么都匹配不到，而
**什么都匹配不到与干净的结果无法区分。** 本地化检查找不到硬编码字符串；
安全扫描找不到秘密；内容审计统计不到已实现的内容；阶段检测器统计不到源文件，
并把一个完成的项目称作绿地项目。以上每一项读起来都是通过。这在技能和钩子中
被反复发现，这就是解析现在集中在一个地方的原因。

**For a write:** do not write. Report the unresolved root and stop.
**对于写入：** 不要写入。报告未解析的根目录并停止。

Writing game code to the wrong root is worse than a false pass, because it
produces a project that cannot build: on Unity, source placed outside `Assets/`
is never compiled and never appears in the editor, so the work is silently
inert. Resolving the engine in order to pick a specialist agent is **not** the
same as resolving the code root — a skill can do the first correctly and still
write to the wrong directory.
把游戏代码写到错误的根目录比虚假通过更糟，因为它会产生一个
无法构建的项目：在 Unity 上，放在 `Assets/` 之外的源码永远不会被编译，
也永远不会出现在编辑器中，因此工作是静默无效的。
为了选择专家智能体而解析引擎，与解析代码根目录**并不**相同 —
技能可以正确地完成前者，却仍然写到错误的目录。

## Applying it
## 应用它

Where a skill says `src/`, read it as *the code root* and substitute the table
above. Where a skill greps, glob the resolved root. Where a skill writes,
write under the resolved root and use the engine's own conventions beneath it
(`Assets/Scripts/<System>/` on Unity, `Source/<Module>/<System>/` on Unreal).
当技能说 `src/` 时，把它读作*代码根目录*并替换为上表。
当技能执行 grep 时，对解析出的根目录做 glob。当技能写入时，
写到解析出的根目录下，并在其下使用引擎自身的约定
（Unity 上的 `Assets/Scripts/<System>/`，Unreal 上的 `Source/<Module>/<System>/`）。
