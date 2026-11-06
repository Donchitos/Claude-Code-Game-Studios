---
name: gate-check
description: "Ready to advance between development phases? PASS/CONCERNS/NOT ASSESSED/FAIL with blockers and required artifacts. 'Can we move to production?'"
argument-hint: "[target-phase: systems-design | technical-setup | pre-production | production | polish | release] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/gate-check/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/artifact-check.sh *), Bash(bash .claude/scripts/gdd-structure-check.sh*), Bash(bash .claude/scripts/adr-dep-graph.sh*), Bash(bash .claude/scripts/set-stage.sh *)
model: opus
---
---
name: gate-check
description: "是否可以推进到下一个开发阶段？给出 PASS/CONCERNS/NOT ASSESSED/FAIL，并附阻塞项和所需制品。'我们可以进入制作了吗？'"
argument-hint: "[target-phase: systems-design | technical-setup | pre-production | production | polish | release] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/gate-check/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/artifact-check.sh *), Bash(bash .claude/scripts/gdd-structure-check.sh*), Bash(bash .claude/scripts/adr-dep-graph.sh*), Bash(bash .claude/scripts/set-stage.sh *)
model: opus
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,workflow,qa.level,testing.strict,performance.enforce,team.size,project.stage,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.
以上已解析 — 直接使用；`--review` 会覆盖 `review_mode`。无配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

# Phase Gate Validation
# 阶段门禁验证

This skill validates whether the project is ready to advance to the next development
phase. It checks for required artifacts, quality standards, and blockers.
此技能验证项目是否已准备好推进到下一个开发阶段。它检查所需制品、质量标准以及阻塞项。

**Distinct from `/project-stage-detect`**: That skill is diagnostic ("where are we?").
This skill is prescriptive ("are we ready to advance?" with a formal verdict).
**与 `/project-stage-detect` 不同**：那个技能是诊断性的（"我们在哪里？"）。
此技能是规定性的（"我们准备好推进了吗？"，并给出正式裁决）。

## Production Stages (7)
## 制作阶段（7 个）

The project progresses through these stages:
项目依次经历这些阶段：

1. **Concept** — Brainstorming, game concept document
2. **Systems Design** — Mapping systems, writing GDDs
3. **Technical Setup** — Engine config, architecture decisions
4. **Pre-Production** — Prototyping, vertical slice validation
5. **Production** — Feature development (Epic/Feature/Task tracking active)
6. **Polish** — Performance, playtesting, bug fixing
7. **Release** — Launch prep, certification
1. **概念** — 头脑风暴、游戏概念文档
2. **系统设计** — 绘制系统地图、编写 GDD
3. **技术搭建** — 引擎配置、架构决策
4. **预制作** — 原型制作、垂直切片验证
5. **制作** — 功能开发（史诗/功能/任务跟踪已启用）
6. **打磨** — 性能、试玩、缺陷修复
7. **发布** — 上线准备、认证

**When a gate passes** (or the user explicitly accepts a CONCERNS verdict's risks — Section 6), update the stage in both `project.yaml` (set `project.stage: <new-stage>`) AND write the new stage name to `production/stage.txt` (single line, e.g. `Production`). Dual-write keeps backward compatibility with hooks that haven't migrated yet. This updates the status line immediately.
**当门禁通过时**（或用户明确接受 CONCERNS 裁决的风险 — 第 6 节），在 `project.yaml` 中更新阶段（设置 `project.stage: <new-stage>`）**并且**将新阶段名写入 `production/stage.txt`（单行，例如 `Production`）。双写可保持与尚未迁移的钩子的向后兼容性。这会立即更新状态栏。

---

## 1. Parse Arguments
## 1. 解析参数

**Target phase:** `$ARGUMENTS` with any `--review <mode>` pair removed (blank = auto-detect current stage, then validate next transition). `/gate-check --review full` names no phase.
**目标阶段：** `$ARGUMENTS`，移除任何 `--review <mode>` 对（留空 = 自动检测当前阶段，然后验证下一次过渡）。`/gate-check --review full` 未指定阶段。

Note: in `solo` mode, director spawns (CD-PHASE-GATE, TD-PHASE-GATE, PR-PHASE-GATE, AD-PHASE-GATE) are skipped — gate-check becomes artifact-existence checks only. In `lean` mode, the phase-gate directors still run (phase gates are the purpose of lean mode); how many of them run is set by `workflow` below.
注意：在 `solo` 模式下，总监启动（CD-PHASE-GATE、TD-PHASE-GATE、PR-PHASE-GATE、AD-PHASE-GATE）会被跳过 — gate-check 变为仅检查制品是否存在。在 `lean` 模式下，阶段门禁总监仍会运行（阶段门禁正是 lean 模式的目的）；运行多少位由下文的 `workflow` 决定。

**`workflow`** (per `.claude/docs/workflow-modes.md`):
**`workflow`**（依据 `.claude/docs/workflow-modes.md`）：

`gate-check` runs project-wide, so it uses the project-level `workflow` for the
gate's overall artifact checklist (the loaded gate file), AND consults
`workflow_overrides.system_overrides.<system>` per-system when validating MVP
GDDs — a system pinned to a higher tier must meet that tier's section count
before the gate passes, regardless of the project-level workflow (see Section 2b,
"Per-system overrides").
`gate-check` 在整个项目范围运行，因此它使用项目级 `workflow` 作为
门禁的整体制品清单（加载的门禁文件），**并且**在验证 MVP
GDD 时按系统查询 `workflow_overrides.system_overrides.<system>` — 被固定到更高层级的系统必须满足该层级的节数
才能通过门禁，无论项目级工作流如何（参见第 2b 节，
"Per-system overrides"）。

> **gate-check honors `workflow` but is exempt from `automation`.** The artifact
> checklist changes per tier; the collaborative prompting protocol (the
> Collaborative Protocol section) always applies — a phase gate is a deliberate
> human checkpoint, never auto-run.
> **gate-check 遵循 `workflow`，但豁免于 `automation`。** 制品
> 清单随层级而变化；协作提示协议（
> 协作协议节）始终适用 — 阶段门禁是刻意设置的
> 人工检查点，绝不自动运行。

**`qa.level`**: controls test enforcement at phase gates, where `workflow`
controls which artifacts are required. `modes.rigor` sets both together; set
`qa.level` explicitly to vary enforcement alone. At `minimal`, no test gates apply — the
test-evidence and unit-test artifact items become non-required and the
Section 3 `testing.strict` check is a no-op; the smoke check is not relaxed (Section 2b) —
but at this level `/smoke-check` runs without game tests (its automated row reads
WAIVED), so the build check (`commands.smoke`, else `commands.build`, when set) and
the launch and critical-path checks are the floor — a build nobody launched is
NOT ASSESSED — and a project with no tests can still pass. At `standard`,
Logic + Integration tests must pass. At `full`, a full coverage check + regression suite are required
(coverage minimum from `qa.coverage_minimum` if set). The retained screenshots
UI and Visual/Feel stories need are not test items: no `qa.level` relaxes them
(Section 2b).
**`qa.level`**：控制阶段门禁处的测试执行，而 `workflow`
控制哪些制品是必需的。`modes.rigor` 会同时设置两者；显式设置
`qa.level` 以单独改变执行强度。在 `minimal` 下，不适用任何测试门禁 —
测试证据和单元测试制品条目变为非必需，第 3 节的 `testing.strict` 检查是空操作；smoke 检查并未放宽（第 2b 节）—
但在该级别下，`/smoke-check` 在没有游戏测试的情况下运行（其自动化行读作
WAIVED），因此构建检查（`commands.smoke`，未设置则用 `commands.build`）以及
启动和关键路径检查构成底线 — 没人启动过的构建是
NOT ASSESSED — 而一个没有测试的项目仍可通过。在 `standard` 下，
逻辑 + 集成测试必须通过。在 `full` 下，需要完整覆盖率检查 + 回归套件
（若设置了 `qa.coverage_minimum` 则以其为覆盖率下限）。UI 和视觉/手感故事所需的保留截图
不是测试条目：任何 `qa.level` 都不会放宽它们
（第 2b 节）。

**`team.size`**: does not change how many directors spawn at a phase gate — panel
width is `workflow`'s axis (Section 4b). This value affects only the
**specialist depth within each director's review**.
`individual` uses the core specialist set; `small` the standard set; `studio`
adds engine sub-specialists. It never skips a director — skipping directors is
`review_mode`'s job. Both `review_mode` and `team.size` are set by
`modes.rigor` — one rigor choice sets both — and each still overrides that axis
when set explicitly (a full-rigor project gets the `studio` set; lighter tiers
get `individual`).
**`team.size`**：不改变阶段门禁处启动多少位总监 — 评审组
宽度是 `workflow` 的轴（第 4b 节）。此值仅影响
**每位总监评审内的专家深度**。
`individual` 使用核心专家集；`small` 使用标准集；`studio`
增加引擎子专家。它从不跳过总监 — 跳过总监是
`review_mode` 的职责。`review_mode` 和 `team.size` 都由
`modes.rigor` 设置 — 一个精度选择同时设置两者 — 但当显式设置时，各自仍会覆盖该轴
（全精度项目获得 `studio` 集；较轻层级
获得 `individual`）。

- **With argument**: `/gate-check production` — validate readiness for that specific phase
- **No argument**: Auto-detect current stage using the same heuristics as
  `/project-stage-detect`, then **confirm with the user before running**:
- **带参数**：`/gate-check production` — 验证该项目特定阶段的就绪度
- **无参数**：使用与 `/project-stage-detect` 相同的启发式方法自动检测当前阶段，
  然后在**运行前与用户确认**：

  Use `AskUserQuestion`:
  - Prompt: "Detected stage: **[current stage]**. Running gate for [Current] → [Next] transition. Is this correct?"
  - Options:
    - `[A] Yes — run this gate`
    - `[B] No — pick a different gate` (if selected, show a second widget listing all gate options: Concept → Systems Design, Systems Design → Technical Setup, Technical Setup → Pre-Production, Pre-Production → Production, Production → Polish, Polish → Release)
  使用 `AskUserQuestion`：
  - 提示："检测到的阶段：**[current stage]**。正在运行 [Current] → [Next] 过渡的门禁。这样正确吗？"
  - 选项：
    - `[A] Yes — 运行此门禁`
    - `[B] No — 选择不同的门禁`（若选择，显示第二个组件列出所有门禁选项：Concept → Systems Design、Systems Design → Technical Setup、Technical Setup → Pre-Production、Pre-Production → Production、Production → Polish、Polish → Release）
  
  Do not skip this confirmation step when no argument is provided.
  在未提供参数时，不要跳过此确认步骤。

---

## 2. Phase Gate Definitions
## 2. 阶段门禁定义

Each gate's checklist — required artifacts, quality checks, and its workflow-tier
reductions — lives in its own file. **Read only the row for the target phase
transition; never load the others.**
每个门禁的清单 — 所需制品、质量检查及其工作流层级
削减 — 存在于各自的文件中。**只读取目标阶段过渡所在的行；绝不加载其他文件。**

| Gate | Definition file |
|------|-----------------|
| Concept → Systems Design | `references/gate-systems-design.md` |
| Systems Design → Technical Setup | `references/gate-technical-setup.md` |
| Technical Setup → Pre-Production | `references/gate-pre-production.md` |
| Pre-Production → Production | `references/gate-production.md` |
| Production → Polish | `references/gate-polish.md` |
| Polish → Release | `references/gate-release.md` |
| 门禁 | 定义文件 |
|------|-----------------|
| Concept → Systems Design | `references/gate-systems-design.md` |
| Systems Design → Technical Setup | `references/gate-technical-setup.md` |
| Technical Setup → Pre-Production | `references/gate-pre-production.md` |
| Pre-Production → Production | `references/gate-production.md` |
| Production → Polish | `references/gate-polish.md` |
| Polish → Release | `references/gate-release.md` |

Each file states the `full` baseline first, then the `standard` and `minimal`
reductions for that gate. Apply the tier resolved in Section 1.
每个文件先陈述 `full` 基线，然后是 `standard` 和 `minimal`
针对该门禁的削减。应用第 1 节中解析的层级。

## 2b. Workflow Tier Adjustment
## 2b. 工作流层级调整

**Read `references/2b-workflow-tier.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/2b-workflow-tier.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## 3. Run the Gate Check
## 3. 运行门禁检查

**Read `references/3-run-gate-check.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/3-run-gate-check.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## 4. Collaborative Assessment
## 4. 协作评估

**Read `references/4-assessment.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/4-assessment.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## 5. Output the Verdict
## 5. 输出裁决

**Read `references/5-verdict.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/5-verdict.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## 6. Update Stage on PASS
## 6. 在 PASS 时更新阶段

**Read `references/6-update-stage.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/6-update-stage.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## 7. Closing Next-Step Widget
## 7. 收尾的后续步骤组件

**Read `references/7-next-steps.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/7-next-steps.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Collaborative Protocol
## 协作协议

This skill follows the collaborative design principle:
此技能遵循协作设计原则：

1. **Scan first**: Check all artifacts and quality gates
2. **Ask about unknowns**: Don't assume PASS for things you can't verify
3. **Present findings**: Show the full checklist with status
4. **User decides**: The verdict is a recommendation — the user makes the final call on
   what to do next; only the stage write is bound to it (Section 6)
5. **Get approval**: "May I write this gate check report to production/gate-checks/?"
6. **Never auto-fix**: If required artifacts are missing, report the FAIL verdict and
   name the skill to run (e.g. "run `/test-setup`"). Do NOT create missing files or
   re-run the gate automatically. Creating files to manufacture a PASS defeats the
   gate's purpose.
1. **先扫描**：检查所有制品和质量门禁
2. **询问未知项**：不要对无法验证的内容假定 PASS
3. **呈现发现**：展示带状态的完整清单
4. **用户决定**：裁决是建议 — 由用户对下一步做什么做出最终决定；
   只有阶段写入受其约束（第 6 节）
5. **获取批准**："我可以把这份门禁检查报告写入 production/gate-checks/ 吗？"
6. **绝不自动修复**：如果缺少必需制品，报告 FAIL 裁决并
   指出要运行的技能（例如 "run `/test-setup`"）。不要创建缺失文件，也不要
   自动重跑门禁。为制造 PASS 而创建文件会破坏
   门禁的目的。

**Never** block a user from working — the verdict decides only whether this skill
writes the new stage. On CONCERNS the user may advance by explicitly accepting the
listed risks, which the report records (Section 6); on FAIL or NOT ASSESSED the
stage stays where it is until a re-run passes, and nothing stops the user working
on the blockers meanwhile.
**绝不**阻止用户工作 — 裁决只决定此技能是否
写入新阶段。在 CONCERNS 下，用户可以通过明确接受
列出的风险来推进，报告会记录这一点（第 6 节）；在 FAIL 或 NOT ASSESSED 下，
阶段保持原样，直到重跑通过，同时没有任何东西阻止用户
处理阻塞项。
