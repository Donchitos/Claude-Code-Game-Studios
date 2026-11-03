# create-epics — GDD+ADR 转史诗（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/create-epics/SKILL.md) ｜ 阶段：Phase 4 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/create-epics [system-name | layer: foundation|core|feature|presentation | all] [--review full|lean|solo]`
- **一句话职责**：把系统 GDD 与架构文档转成史诗（epic），每个架构模块一个史诗，只定义"做什么"和"由哪些决策约束"，"怎么做"留给故事卡。
- **触发前置**：
  - `minimal` 档：存在 `design/game-brief.md`。
  - `standard`/`full` 档：`design/gdd/` 下有系统 GDD（`standard` 需 5 个必需章节；`full` 需全部 8 章节且 Approved），且 `docs/architecture/architecture.md` 必须存在；`full` 还要求 TR registry 与 control manifest 存在。
  - 每个层级（layer）到达时各跑一次；Feature 史诗不得在 Core 接近完成前编写。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`review_mode, review_gate, automation, workflow, docs.density, engine_values, system_overrides`（resolve_config 解析；`--review` 覆盖 `review_mode`；无输出块时按 `.claude/docs/config-resolution.md` 默认值） | `workflow` 定档位（minimal/standard/full），逐系统可被 `system_overrides` 行覆盖；`docs.density` 定 Overview 深度；`review_gate` 定 PR-EPIC 门禁 |
| 读取 | `minimal`：`design/game-brief.md` | MVP 特性列表与 Build order 是史诗来源 |
| 读取 | `standard`/`full`：`gdd-structure-check.sh` 列出的系统 GDD（只取 Overview 与 Acceptance Criteria 章节）、`docs/architecture/architecture.md`、`adr-status.sh`（ADR 状态/层级/缺失章节）+ 在范围 ADR 的 Requirements Addressed/Decision/Engine Compatibility、`docs/architecture/tr-registry.yaml`（在范围系统条目）、control manifest 的 `Manifest Version` 行（standard 有则读、full 必需）、`docs/engine-reference/<engine>/VERSION.md`（引擎风险档） | 全部按章节抽取，禁止整读整猜 |
| 产出 | `production/epics/[epic-slug]/EPIC.md`（每个史诗一个，含 Layer/GDD/Architecture Module/Status/Stories 头字段 + Overview/Governing ADRs/GDD Requirements/Definition of Done）；`production/epics/index.md`（每史诗一行） | 每次写入前都要单独征得同意（its own yes） |
| 派生智能体 | `skill-gates=run` 时派 PR-EPIC 制片人审查智能体（读 `references/pr-epic-gate.md` 与 `.claude/docs/director-gates.md`）；skip 时不加载 | solo/lean 模式无智能体，主会话直接执行 |

## 3. 核心规则
R1. 参数即范围：`all` = 全部系统按层级顺序；`layer: <名>` = 仅该层；系统名 = 仅该系统；无参数时若请求原文点名层级或系统则照用，否则必须先问"要为哪一层或哪个系统生成史诗？"。（Phase 1）
R2. 档位由项目 `workflow` 值决定，每个在范围系统可被其 `system_overrides` 行单独定档；`minimal` 档必须先告知用户：此步在该档可选（`/create-stories` 会自行从 brief 建史诗），用户仍要求时才继续。（Phase 1）
R3. `minimal` 档只读 `design/game-brief.md`；文件缺失即停止并提示先跑 `/start` 或 `/brainstorm`。禁止索要 GDD、systems index、架构文档、ADR、TR registry、control manifest，禁止让用户先跑 `/design-system`、`/map-systems`、`/create-architecture`——该档按设计就没有这些。（Phase 2）
R4. `minimal` 档必须先逐字报告：`Loaded: design/game-brief.md · engine [名 版本]` 及"此步在 minimal 可选"说明；史诗来自 brief 的 MVP 特性列表按 **Build order**；短 brief 只出一个史诗（slug 取 working title）；用户要求分组时每组一个史诗；每个史诗必须写明自己的 slug（`/create-stories` 需要用户输入它）。（Phase 2）
R5. `standard`/`full` 档：用 `gdd-structure-check.sh` 数出系统 GDD 数 N（N=0 停止，提示先 `/design-system`）；范围判定看各 GDD 的 `## Summary` 速查（老 GDD 无 Summary 时从 `systems-index.md` 取层级）；缺失 `## Summary` 绝不等于把系统踢出范围。（Phase 2）
R6. `architecture.md` 在 standard 与 full 都必需：缺失即停止并提示先跑 `/create-architecture`；禁止发明模块边界。（Phase 2）
R7. 定义任何史诗前必须按真实状态报告：`Loaded: [N] system GDDs, [n] in scope ([names]) · [M] ADRs ([A] Accepted, [P] Proposed) · manifest v[date | absent] · engine [名 版本]`。（Phase 2）
R8. 按层级顺序处理：Foundation → Core → Feature → Presentation；同层内按 systems index 顺序（`minimal` 按 brief 的 Build order）；每个系统的模块取自 `architecture.md`（`minimal` 取 brief 的特性组）。（Phase 3）
R9. 需求覆盖判定（`minimal` 不做）：某 TR-ID 只有被一个 **Accepted** ADR 处理才算 covered，其余一律 untraced；仅有 `Proposed` ADR 的需求也是 untraced，其行写 `❌ No ADR (ADR-NNNN Proposed)`，让 `/create-stories` 仍能看到该 ADR 并阻断其故事。Untraced 需求列在 **Untraced Requirements** 下。（Phase 3）
R10. ⚠️ 警告规则：`full` 档每个 untraced 需求都警告；`standard` 档只对 Foundation 层 untraced 需求警告，其余仅作信息列出、不警告。警告文案须引导"先跑 `/architecture-decision`，或接受缺口继续"。（Phase 3）
R11. 每个史诗单独展示标准块（Layer/GDD/Architecture Module/Governing ADRs/Engine Risk/覆盖数/Untraced Requirements）后，只对该史诗问一次："Shall I create Epic: [name]?"，选项：Yes, create it / Skip this epic / Pause — I need to write ADRs first。禁止把多个史诗合并进一个问题；得到答案前不得展示下一个史诗。（Phase 3）
R12. 一个 yes 只覆盖它所回答的那一个史诗，即使用户措辞是"全部"、"都做"：史诗按展示即批准（approved on sight）原则逐个确认。（Phase 3）
R13. PR-EPIC 制片人审查：`skill-gates=skip`（solo 或 lean）不派智能体，在回复与收尾块注明 `PR-EPIC skipped — [Solo | Lean] mode`；`skill-gates=run` 时读 `references/pr-epic-gate.md` 与 `.claude/docs/director-gates.md`，在所有在范围史诗定义完之后、任何写入之前运行；skip 时不加载门禁文件。（Phase 4）
R14. 已存在的 `EPIC.md` 禁止覆盖：必须问"已存在 [name] 的 EPIC.md，就地更新还是跳过？"选项 Update in place / Skip this epic；就地更新只编辑本技能拥有的字段（Stories 以外的头字段、Overview、Governing ADRs、GDD Requirements、Definition of Done），必须原样保留 `**Stories**` 行与 `## Stories` 表（`/create-stories` 写的，重置会孤儿化已有故事卡）。（Phase 5）
R15. 新史诗写入是独立的一次询问（每个史诗一次，在 Phase 3 的 yes 之后）："可否写 `production/epics/[epic-slug]/EPIC.md` 并在 `production/epics/index.md` 加一行[, 需要则创建]？"——Phase 3 的 yes 批准的是史诗本身，不是写文件；只有对这次询问明确 yes 才写。（Phase 5）
R16. 写入前必须跑 `write-guard.sh overwrite production/epics/[epic-slug]/EPIC.md`：它总是打印 `checked` 行；若返回 `OVERWRITE` 行说明文件其实存在，此时禁止写入，改问更新问题。（Phase 5）
R17. `docs.density` 只定 Overview 深度（`terse` 项目符号 / `balanced` 短段落 / `thorough` 带完整 prose、ADR 理由与风险）；表格在任何密度下都保持完整。（Phase 5）
R18. `minimal` 档的 EPIC.md：GDD 行写 `design/game-brief.md`，省略 Governing ADRs 与 GDD Requirements 两张表，用 **Scope** 列表按 Build order 列 MVP 特性。（Phase 5）

R18 对应的 EPIC.md 模板与 index 行模板（保留原文格式约定）：

```markdown
# Epic: [System Name]

> **Layer**: [Foundation | Core | Feature | Presentation]
> **GDD**: design/gdd/[file].md
> **Architecture Module**: [module]
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories [epic-slug]`

## Overview

[What this epic implements, from the GDD Overview and the module's responsibilities]

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-NNNN: [title] | [one line] | LOW/MEDIUM/HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-[system]-001 | [requirement text from the registry] | ADR-NNNN ✅ |
| TR-[system]-002 | [requirement text] | ❌ No ADR (ADR-NNNN Proposed) |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/[file].md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
```

```markdown
# Epics Index

Last Updated: [date]
Engine: [name version]

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| [name] | [layer] | [system] | [file] | Not yet created | Ready |
```
R19. `index.md` 每史诗一行；已有行的史诗就地更新，禁止加第二行、禁止重置其 Stories 单元格。（Phase 5）
R20. `standard`/`full` 档下，一旦 Foundation 与 Core 史诗都已存在，必须补一句："Foundation and Core epics are what the Pre-Production → Production gate needs. `/gate-check production` checks readiness."；`minimal` 档禁止说这句话。（Phase 6）
R21. 所有史诗内容必须来自 GDD、ADR、架构文档（`minimal` 来自 brief）；禁止发明任何内容。（Phase 6）
R22. 运行最后一条回复必须以收尾块结束（重复展示过也要再打）：`Verdict: COMPLETE — [N] epics written: [slugs]` + `Review: [...]` + `Index: production/epics/index.md [created | updated]` + `Next step: /create-stories [first-epic-slug]`。（Phase 6）
R23. 用户跳过/拒绝全部史诗：`Verdict: BLOCKED — no epic written ([why])`；在范围内找不到系统：`Verdict: BLOCKED — no eligible systems in [scope]`。（Phase 6）
R24. 提问规则：有提问工具就用工具；没有则列出编号选项并结束回合等待；被跳过或被关闭的提问不算答案，必须以纯文本再问一次。（全局）

## 4. 门禁与裁决
- **门禁 ID**：PR-EPIC（producer review，制片人审查）。
- **触发**：`review_gate` 的 `skill-gates` 值：`skip`（solo/lean 模式）→ 不派智能体，注明跳过；`run` → 在全部在范围史诗定义完之后、任何写入之前运行。
- **执行依据**：`references/pr-epic-gate.md` + `.claude/docs/director-gates.md`（skip 时禁止加载）。
- **裁决呈现**：收尾块 `Review:` 行写 `PR-EPIC skipped — Solo mode`、`skipped — Lean mode` 或其真实 verdict。

## 5. 移植建议
- **可直接移植**：R1（参数即范围）、R3-R7（输入加载与如实报告）、R8（分层处理顺序）、R9-R10（覆盖判定与警告分档）、R11-R12（逐项确认、一次 yes 只算一个）、R13（门禁 skip/run 二值）、R14-R16（禁覆盖既有文件、写前守卫、独立写入询问）、R17（密度只影响散文不影响表格）、R19（索引行不重复不重置）、R22-R24（收尾块与提问协议）。这些与游戏无关。
- **需替换概念**：GDD → 领域设计文档；ADR → 技术决策记录（Accepted/Proposed 语义保留）；architecture.md → 系统模块划分文档；TR-ID → 需求追踪编号；layer（Foundation/Core/Feature/Presentation）→ 项目的分层维度（如 infra/domain/app/ui）；engine/VERSION.md → 关键外部依赖的风险评级；producer review → 领域负责人审查。
- **改写示例**：
  - "每个模块的史诗必须单独展示后逐一询问'是否创建'，一次 yes 只覆盖它回答的那一个模块；禁止把多个模块合并成一个提问。"
  - "已存在的设计文档禁止覆盖：必须先问'就地更新还是跳过'；就地更新只改本次生成拥有的字段，保留下游工具写入的清单表。"

## 6. 关联文档
- 上游：`/design-system`（产 GDD）、`/create-architecture`（产 architecture.md、ADR、TR registry、control manifest）、`/start`、`/brainstorm`（产 brief）。
- 下游：`/create-stories [epic-slug]`（每史诗一次）；`/gate-check production`（Foundation+Core 就绪检查）。
- 引用：`.claude/docs/config-resolution.md`、`.claude/docs/automation-modes.md`、`.claude/docs/director-gates.md`、`references/pr-epic-gate.md`。
