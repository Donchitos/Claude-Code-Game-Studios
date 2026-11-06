---
name: test-setup
description: "Scaffold the test framework and CI — tests/ directory, engine test runner, GitHub Actions workflow. Once, before the first sprint."
argument-hint: "[force]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(grep -q 'com.unity.test-framework' Packages/manifest.json), Bash(bash "*/.claude/skills/test-setup/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: test-setup
description: "搭建测试框架与 CI——tests/ 目录、引擎测试运行器、GitHub Actions 工作流。一次，在首个冲刺之前。"
argument-hint: "[force]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(grep -q 'com.unity.test-framework' Packages/manifest.json), Bash(bash "*/.claude/skills/test-setup/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用和每次文件写入都遵循 `.claude/docs/automation-modes.md`（collaborative 始终询问 · guided 仅重大问题 · autonomous 记录并继续；`automation_always_ask` 类别始终提示）。

# Test Setup
# 测试搭建

This skill scaffolds the automated testing infrastructure for the project.
It detects the configured engine, generates the appropriate test runner
configuration, creates the standard directory layout, and wires up CI/CD
so tests run on every push.
本技能为项目搭建自动化测试基础设施。它检测所配置的引擎，生成相应的测试运行器配置，创建标准目录布局，并接入 CI/CD，使测试在每次推送时运行。

Run this once during the Technical Setup phase, before any implementation
begins. A test framework installed at sprint start costs 30 minutes.
A test framework installed at sprint four costs 3 sprints.
在技术搭建阶段、任何实现开始之前运行一次。在冲刺开始时安装测试框架只需 30 分钟。在第四个冲刺才安装测试框架要花 3 个冲刺。

**Output:** `tests/` directory structure + `.github/workflows/tests.yml`
**产出：** `tests/` 目录结构 + `.github/workflows/tests.yml`

---

## Phase 1: Detect Engine and Existing State
## 阶段 1：检测引擎与现有状态

**Read `references/1-detect.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/1-detect.md` 并遵循它**——本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 2: Present Plan
## 阶段 2：呈现计划

**Read `references/2-plan.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/2-plan.md` 并遵循它**——本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 3: Create Directory Structure
## 阶段 3：创建目录结构

**Read `references/3-directories.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/3-directories.md` 并遵循它**——本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 4: Create CI/CD Workflow
## 阶段 4：创建 CI/CD 工作流

**Read `references/4-ci.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/4-ci.md` 并遵循它**——本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 5: Create Smoke Test Seed
## 阶段 5：创建冒烟测试种子

**Read `references/5-smoke-seed.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/5-smoke-seed.md` 并遵循它**——本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 6: Post-Setup Summary
## 阶段 6：搭建后摘要

**Read `references/6-summary.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**现在读取 `references/6-summary.md` 并遵循它**——本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Collaborative Protocol
## 协作协议

- **Never overwrite existing test files** — only create files that are missing.
  If a test runner file exists, leave it as-is.
- **Always ask before creating files** — Phase 2 requires explicit approval.
- **Engine detection is non-negotiable** — if the engine is not configured,
  stop and redirect to `/setup-engine`. Do not guess.
- **`force` flag skips the "already exists" early-exit but never overwrites.**
  It means "create any missing files even if the directory already exists."
- For Unity CI, note that the `UNITY_LICENSE` secret must be configured
  manually. Do not attempt to automate license management.
- **绝不覆盖现有测试文件**——只创建缺失的文件。如果测试运行器文件已存在，保持原样。
- **创建文件前始终询问**——阶段 2 需要明确批准。
- **引擎检测不可协商**——如果引擎未配置，停止并重定向到 `/setup-engine`。不要猜测。
- **`force` 标志跳过“已存在”的提前退出，但绝不覆盖。** 它意味着“即使目录已存在，也创建任何缺失的文件。”
- 对于 Unity CI，请注意 `UNITY_LICENSE` 机密必须手动配置。不要试图自动化许可证管理。
