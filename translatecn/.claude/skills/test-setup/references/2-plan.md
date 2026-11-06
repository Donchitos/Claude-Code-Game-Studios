# /test-setup — Phase 2: Present Plan

# /test-setup — 第 2 阶段：呈现计划

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/test-setup` 的一部分。`SKILL.md` 指明何时阅读本文件；它解析出的设置
> 以及其后续标题下的规则在此仍然适用。

## Phase 2: Present Plan

## 第 2 阶段：呈现计划

Based on the engine detected and the existing state, present a plan:

根据检测到的引擎和现有状态，呈现一份计划：

```
## Test Setup Plan — [Engine]

I will create the following (skipping any that already exist):

tests/
  unit/           — Isolated unit tests for formulas, state, and logic   (Godot only)
  integration/    — Cross-system tests and save/load round-trips         (Godot only)
  smoke/          — Critical path test list (15-minute manual gate)
  README.md       — Test framework documentation

[Unity/Unreal: unit and integration tests go under the engine's test root
 instead — Unity Assets/Tests/EditMode|PlayMode/, Unreal
 Source/<Module>/Private/Tests/ — because neither compiles code in tests/]

production/qa/
  evidence/       — Screenshot and manual test sign-off records

[Engine-specific files — see per-engine details below]

.github/workflows/tests.yml  — CI: run tests on every push to main

Estimated time: ~5 minutes to create all files.
```

```
## 测试搭建计划 — [Engine]

我将创建以下内容（已存在的项将跳过）：

tests/
  unit/           — 针对公式、状态和逻辑的隔离单元测试   （仅 Godot）
  integration/    — 跨系统测试以及存档/读档往返测试      （仅 Godot）
  smoke/          — 关键路径测试清单（15 分钟人工闸门）
  README.md       — 测试框架文档

[Unity/Unreal：单元测试和集成测试改放到引擎的测试根目录下
 —— Unity 为 Assets/Tests/EditMode|PlayMode/，Unreal 为
 Source/<Module>/Private/Tests/ —— 因为两者都不会编译 tests/ 中的代码]

production/qa/
  evidence/       — 截图与人工测试签核记录

[引擎特定文件 —— 见下方各引擎详情]

.github/workflows/tests.yml  — CI：每次推送到 main 时运行测试

预计时间：创建所有文件约需 5 分钟。
```

Ask: "May I create these files? I will not overwrite any test files that
already exist at these paths."

询问："我可以创建这些文件吗？我不会覆盖这些路径下已经存在的任何测试文件。"

**At `collaborative` and `guided`** — do not proceed without approval. These are
**new** files, and `automation-modes.md:81` gates new-file writes in `guided` too,
so the answer is the same in both modes. **At `autonomous`** — create them and log
the decision; do not block.

**在 `collaborative` 和 `guided` 模式下** —— 未经批准不要继续。这些是**新**文件，
而 `automation-modes.md:81` 在 `guided` 模式下同样会拦截新文件的写入，
因此两种模式下的结论相同。**在 `autonomous` 模式下** —— 创建它们并记录
该决定；不要阻塞。

---
