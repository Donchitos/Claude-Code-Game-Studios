# /test-setup — Phase 6: Post-Setup Summary

# /test-setup — 第 6 阶段：搭建后总结

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/test-setup` 的一部分。`SKILL.md` 指明何时阅读本文件；它解析出的设置
> 以及其后续标题下的规则在此仍然适用。

## Phase 6: Post-Setup Summary

## 第 6 阶段：搭建后总结

After writing all files, report:

写入所有文件后，报告：

```
Test infrastructure created for [engine].

Files created:
- tests/README.md
- tests/unit/ and tests/integration/ (Godot) — or the engine's test root:
  Unity Assets/Tests/EditMode/ and PlayMode/, Unreal Source/<Module>/Private/Tests/
- tests/smoke/critical-paths.md
- production/qa/evidence/.gitkeep
[engine-specific files]
- .github/workflows/tests.yml

Next steps:
1. [Engine-specific install step, e.g., "Install GdUnit4 via the Asset Store (AssetLib before Godot 4.7)"]
2. Write your first test in the engine's test root:
   tests/unit/[system]/[system]_[feature]_test.gd (Godot),
   Assets/Tests/EditMode/[System]Tests.cs (Unity), or
   Source/<Module>/Private/Tests/[System]Test.cpp (Unreal)
3. Run `/qa-plan sprint` before your first sprint to classify stories and set
   test evidence requirements. At `workflow: minimal` — the default — skip
   this: there are no sprints. At `qa.level: minimal`, also the default, tests
   are waived, so `/dev-story` writes none. Raise `qa.level` with `/settings`
   to have it write them
4. `/smoke-check` before every QA hand-off

Gate note: /gate-check Technical Setup → Pre-Production now requires:
- the engine's test root: tests/unit/ and tests/integration/ (Godot),
  Assets/Tests/EditMode/ and Assets/Tests/PlayMode/ (Unity), or
  Source/<Module>/Private/Tests/ (Unreal)
- .github/workflows/tests.yml
- At least one example test file
Run /test-setup and write one example test before advancing.
(At `workflow: minimal` that gate requires only the engine.)

Verdict: **COMPLETE** — test framework scaffolded and CI/CD wired up.
```

```
已为 [engine] 创建测试基础设施。

已创建的文件：
- tests/README.md
- tests/unit/ 和 tests/integration/（Godot）—— 或引擎的测试根目录：
  Unity 为 Assets/Tests/EditMode/ 和 PlayMode/，Unreal 为 Source/<Module>/Private/Tests/
- tests/smoke/critical-paths.md
- production/qa/evidence/.gitkeep
[引擎特定文件]
- .github/workflows/tests.yml

后续步骤：
1. [引擎特定的安装步骤，例如“通过 Asset Store 安装 GdUnit4（Godot 4.7 之前为 AssetLib）”]
2. 在引擎的测试根目录中编写你的第一个测试：
   tests/unit/[system]/[system]_[feature]_test.gd（Godot）、
   Assets/Tests/EditMode/[System]Tests.cs（Unity），或
   Source/<Module>/Private/Tests/[System]Test.cpp（Unreal）
3. 在第一个冲刺之前运行 `/qa-plan sprint`，以对故事进行分类并设置
   测试证据要求。在 `workflow: minimal` 模式下 —— 即默认值 —— 跳过
   这一步：没有冲刺。在 `qa.level: minimal` 下（同样是默认值），测试
   被豁免，因此 `/dev-story` 不会编写任何测试。使用 `/settings` 提高 `qa.level`，
   让它编写测试
4. 每次 QA 交接之前运行 `/smoke-check`

闸门说明：/gate-check 的 Technical Setup → Pre-Production 现在要求：
- 引擎的测试根目录：tests/unit/ 和 tests/integration/（Godot）、
  Assets/Tests/EditMode/ 和 Assets/Tests/PlayMode/（Unity），或
  Source/<Module>/Private/Tests/（Unreal）
- .github/workflows/tests.yml
- 至少一个示例测试文件
在推进之前，运行 /test-setup 并编写一个示例测试。
（在 `workflow: minimal` 模式下，该闸门只要求引擎。）

结论：**COMPLETE** —— 测试框架已搭建，CI/CD 已接通。
```

---
