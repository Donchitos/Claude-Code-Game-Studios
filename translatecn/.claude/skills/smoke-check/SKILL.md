---
name: smoke-check
description: "Critical-path smoke gate before QA hand-off — runs the automated suite. A failed check means the build is not QA-ready."
argument-hint: "[sprint | quick | --platform pc|console|mobile|all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash(bash "*/.claude/skills/smoke-check/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/project-coherence.sh*), Bash(command -v *), Bash(uname -s), Bash(godot --headless --path . --import), Bash(timeout 900 godot --headless *), Bash(timeout 1800 godot --headless *), Bash(grep -q 'com.unity.test-framework' Packages/manifest.json), Bash(echo present), Bash(echo ABSENT)
model: sonnet
---
---
name: smoke-check
description: "QA 交接前的关键路径冒烟门禁 — 运行自动化套件。检查失败意味着构建尚未达到 QA 就绪。"
argument-hint: "[sprint | quick | --platform pc|console|mobile|all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash(bash "*/.claude/skills/smoke-check/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/project-coherence.sh*), Bash(command -v *), Bash(uname -s), Bash(godot --headless --path . --import), Bash(timeout 900 godot --headless *), Bash(timeout 1800 godot --headless *), Bash(grep -q 'com.unity.test-framework' Packages/manifest.json), Bash(echo present), Bash(echo ABSENT)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,testing.strict`

# Smoke Check
# 冒烟检查

This skill is the gate between "implementation done" and "ready for QA
hand-off". It runs the automated test suite, checks for test coverage gaps,
batch-verifies critical paths with the developer, and produces a PASS/FAIL
report.
此技能是"实现完成"与"准备好交接给 QA"之间的门禁。它运行自动化测试套件、检查测试覆盖缺口、
与开发者批量验证关键路径，并产出 PASS/FAIL
报告。

The rule is simple: **a build that fails smoke check does not go to QA.**
Handing a broken build to QA wastes their time and demoralises the team.
规则很简单：**未通过冒烟检查的构建不会交给 QA。**
把损坏的构建交给 QA 会浪费他们的时间并打击团队士气。

**Output:** `production/qa/smoke-[date].md`
**输出：** `production/qa/smoke-[date].md`

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（collaborative 始终询问 · guided 仅主要项 · autonomous 记录并继续；
`automation_always_ask` 类别始终提示）。

**`qa.level`**: at `minimal`, smoke-check is **optional** — if
run, a FAIL is advisory and never blocks hand-off, and a project with no game
tests is checked by its build, launch and critical paths alone (Phase 1 step 1); at `standard`, it is required
before a phase transition; at `full`, before every commit. This sits in front of
the Phase 6 `testing.strict.config` resolution (which only matters once a smoke run
gates). Distinct axis from `workflow`.
**`qa.level`**：在 `minimal` 下，冒烟检查是**可选的** — 若
运行，FAIL 仅为建议，绝不阻塞交接，而没有游戏
测试的项目仅通过其构建、启动和关键路径检查（阶段 1 步骤 1）；在 `standard` 下，在阶段过渡之前是必需的；
在 `full` 下，在每次提交之前。这位于
阶段 6 `testing.strict.config` 解析之前（后者仅在冒烟运行
门控时才重要）。与 `workflow` 是不同轴。

## Parse Arguments
## 解析参数

Arguments can be combined: `/smoke-check sprint --platform console`
参数可以组合：`/smoke-check sprint --platform console`

**Base mode** (first argument, default: `sprint`):
- `sprint` — full smoke check against the current sprint's stories
- `quick` — skip coverage scan (Phase 3) and Batch 3; use for rapid re-checks
**基础模式**（第一个参数，默认 `sprint`）：
- `sprint` — 针对当前冲刺故事的完整冒烟检查
- `quick` — 跳过覆盖扫描（阶段 3）和批次 3；用于快速复查

**Platform flag** (`--platform`, default: none):
- `--platform pc` — add PC-specific checks (keyboard, mouse, windowed mode)
- `--platform console` — add console-specific checks (gamepad, TV safe zones,
  platform certification requirements)
- `--platform mobile` — add mobile-specific checks (touch, portrait/landscape,
  battery/thermal behaviour)
- `--platform all` — add all platform variants; output per-platform verdict table
**平台标志**（`--platform`，默认：无）：
- `--platform pc` — 添加 PC 特定检查（键盘、鼠标、窗口模式）
- `--platform console` — 添加主机特定检查（手柄、电视安全区、
  平台认证要求）
- `--platform mobile` — 添加移动端特定检查（触控、竖屏/横屏、
  电池/温度表现）
- `--platform all` — 添加所有平台变体；输出逐平台裁决表

If `--platform` is provided, Phase 4 adds platform-specific batches and
Phase 5 outputs a per-platform verdict table in addition to the overall verdict.
如果提供了 `--platform`，阶段 4 会添加平台特定批次，
阶段 5 会在整体裁决之外输出逐平台裁决表。

---

## Phase 1: Detect Test Setup
## 阶段 1：检测测试设置

**Read `references/1-detect-setup.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/1-detect-setup.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Phase 2: Run Automated Tests
## 阶段 2：运行自动化测试

**Read `references/2-run-tests.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/2-run-tests.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Phase 3: Check Test Coverage
## 阶段 3：检查测试覆盖

**Read `references/3-coverage.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/3-coverage.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Phase 4: Run Manual Smoke Checks
## 阶段 4：运行人工冒烟检查

**Read `references/4-manual-checks.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/4-manual-checks.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Phase 5: Generate Report
## 阶段 5：生成报告

**Read `references/5-report.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/5-report.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Phase 6: Write and Gate
## 阶段 6：写入并门控

**Read `references/6-write-gate.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/6-write-gate.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Collaborative Protocol
## 协作协议

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.
**在 `collaborative` 模式（默认）下适用。** 对于 `guided` 和
`autonomous` 模式，请参阅 `.claude/docs/automation-modes.md` — 下文规则
描述的是协作模式的要求，而非普遍行为。

- **Never treat NOT RUN as automatic FAIL** — record it as NOT RUN and let
  the developer confirm status manually. Unconfirmed NOT RUN yields **NOT
  ASSESSED**, not FAIL — and not a pass verdict either.
- **Never auto-fix failures** — report them and state what must be resolved.
  Do not attempt to edit source code or test files.
- **PASS WITH WARNINGS does not block QA hand-off** — it records advisory
  gaps for `/story-done` to follow up on.
- **`quick` argument** skips Phase 3 (coverage scan) and Phase 4 Batch 3.
  Use it for rapid re-checks after fixing a specific failure.
- Use `AskUserQuestion` for all manual smoke check verification.
- **Never write the report without asking** — Phase 6 requires explicit
  approval before any file is created.
- **绝不把 NOT RUN 视为自动 FAIL** — 将其记录为 NOT RUN，让
  开发者手动确认状态。未确认的 NOT RUN 产出 **NOT
  ASSESSED**，而非 FAIL — 也不是通过裁决。
- **绝不自动修复失败** — 报告它们并说明必须解决什么。
  不要尝试编辑源代码或测试文件。
- **PASS WITH WARNINGS 不阻塞 QA 交接** — 它记录建议性
  缺口，供 `/story-done` 跟进。
- **`quick` 参数**跳过阶段 3（覆盖扫描）和阶段 4 批次 3。
  在修复特定失败后用于快速复查。
- 使用 `AskUserQuestion` 进行所有人工冒烟检查验证。
- **绝不在未询问的情况下写报告** — 阶段 6 要求在创建任何文件之前获得明确批准。
