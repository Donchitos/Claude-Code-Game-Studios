# /test-setup — Phase 1: Detect Engine and Existing State

# /test-setup — 第 1 阶段：检测引擎与现有状态

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/test-setup` 的一部分。`SKILL.md` 指明何时阅读本文件；它解析出的设置
> 以及其后续标题下的规则在此仍然适用。

## Phase 1: Detect Engine and Existing State

## 第 1 阶段：检测引擎与现有状态

1. **Read engine config**:
   - Read `engine.name` from `project.yaml`; if that key is absent or empty
     (including when `project.yaml` has no `engine:` block), fall back to the
     `Engine:` value in `.claude/docs/technical-preferences.md`.
   - If neither source yields a configured engine (project.yaml `engine.name`
     absent/empty and technical-preferences.md shows `[TO BE CONFIGURED]` or is
     missing), stop:
     "Engine not configured. Run `/setup-engine` first, then re-run `/test-setup`."

1. **读取引擎配置**：
   - 从 `project.yaml` 读取 `engine.name`；如果该键缺失或为空
     （包括 `project.yaml` 中没有 `engine:` 块的情况），则回退到
     `.claude/docs/technical-preferences.md` 中的 `Engine:` 值。
   - 如果两个来源都没有给出已配置的引擎（project.yaml 的 `engine.name`
     缺失/为空，且 technical-preferences.md 显示 `[TO BE CONFIGURED]` 或
     文件缺失），则停止：
     "Engine not configured. Run `/setup-engine` first, then re-run `/test-setup`."

2. **Check for existing test infrastructure**:
   - Glob `tests/` — does the directory exist?
   - Glob `tests/unit/` and `tests/integration/` — do subdirectories exist?
   - Glob `.github/workflows/` — does a CI workflow file exist?
   - Glob `addons/gdUnit4/bin/GdUnitCmdTool.gd` (Godot — note the capital U) or
     `Assets/Tests/EditMode/` (Unity) or `Source/*/Private/Tests/` (Unreal) for
     engine-specific artifacts. These are the **test roots** in
     `.claude/docs/directory-structure.md`; tests anywhere else are never compiled
     on Unity or Unreal.

2. **检查现有的测试基础设施**：
   - Glob `tests/` —— 该目录是否存在？
   - Glob `tests/unit/` 和 `tests/integration/` —— 子目录是否存在？
   - Glob `.github/workflows/` —— 是否存在 CI 工作流文件？
   - Glob `addons/gdUnit4/bin/GdUnitCmdTool.gd`（Godot —— 注意大写的 U）或
     `Assets/Tests/EditMode/`（Unity）或 `Source/*/Private/Tests/`（Unreal），
     查找引擎特定的产物。这些是
     `.claude/docs/directory-structure.md` 中的**测试根目录**；在 Unity 或 Unreal 上，
     其他任何位置的测试都不会被编译。

3. **Report findings**:
   - "Engine: [engine]. Test directory: [found / not found]. CI workflow: [found / not found]."
   - If everything already exists AND `force` argument was not passed:
     "Test infrastructure appears to be in place. Re-run with `/test-setup force`
     to regenerate. Proceeding will not overwrite existing test files."

3. **报告检查结果**：
   - "Engine: [engine]. Test directory: [found / not found]. CI workflow: [found / not found]."
   - 如果一切都已存在，且未传入 `force` 参数：
     "测试基础设施似乎已经就位。若要重新生成，请使用 `/test-setup force`
     重新运行。继续执行不会覆盖现有的测试文件。"

If the `force` argument is passed, skip the "already exists" early-exit and
proceed — but still do not overwrite files that already exist at a given path.
Only create files that are missing.

如果传入了 `force` 参数，则跳过“已存在”的提前退出并继续执行 —— 但仍然不要
覆盖给定路径上已经存在的文件。只创建缺失的文件。

---
