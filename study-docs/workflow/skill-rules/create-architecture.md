# create-architecture — 总架构文档（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/create-architecture/SKILL.md) ｜ 阶段：Phase 3 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/create-architecture [focus-area: full | layers | data-flow | api-boundaries | adr-audit] [--review full|lean|solo]`
- **一句话职责**：在写代码前撰写总架构蓝图 `docs/architecture/architecture.md`，把全部已批准 GDD 翻译成具体技术蓝图；对照钉定（pinned）引擎校验决策并标记知识缺口。
- **触发前置**：位于设计与实现之间、必须在 sprint 计划开始前存在。与 `/architecture-decision` 的分工：ADR 记录单个点决策，本技能产出为 ADR 提供上下文的整系统蓝图。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `review_mode`、`automation`、`workflow`、`docs.density`（经 `hooks/yaml-helper.sh resolve_config`；`--review` 参数覆盖 `review_mode`；无输出块则用 `.claude/docs/config-resolution.md` 默认值） | 决定评审模式、提问节奏、蓝图范围与各节深度 |
| 读取 | 全部已批准 GDD、既有 ADR（`docs/architecture/adr-*.md`）、引擎参考（Phase 0，见 `references/0-load-context.md`） | 蓝图的输入 |
| 读取 | `production/session-state/active.md`（协作协议要求随决策记录） | 防崩溃丢决策 |
| 产出 | `docs/architecture/architecture.md`（总架构文档；仅在 Phase 7 一次性写入；Phase 7b Step 4 只更新其 Document Status） | 段落深度按 `docs.density` |
| 派生智能体 | 门禁评审按 `.claude/docs/director-gates.md` 模式派出（`--review` 决定 full/lean/solo）；被派出的智能体自读其 `.claude/docs/director-gates/[gate-id].md` 门禁文件 | 父会话禁止代读门禁文件 |

**配置键档位**：
- `workflow`：`full` = 完整架构（全部层、模块归属、数据流、API 边界、完整 ADR 审计）；`standard` = 简化（仅系统层图 + 关键 ADR 清单）；`minimal` = 不要求（可自愿运行）。
- `docs.density`（控制每节深度，`workflow` 控制哪些节存在；`modes.rigor` 同时设定两者，显式设 `docs.density` 可单独调深度）：`terse`（默认，经 `rigor: minimal`）= 层图 + 决策要点条目，不写散文；`balanced` = 图 + 层选择的段落解释（`rigor: standard`）；`thorough` = 完整散文体，逐层含理由、权衡与备选方案。应用于所撰写的每一节。

## 3. 核心规则（逐条编号 R1、R2……）

**参数模式（Argument modes）**
R1. 必须按参数确定聚焦模式：无参数/`full` = 完整引导走查（全部节，从头到尾）；`layers` = 仅系统层图；`data-flow` = 仅模块间数据流；`api-boundaries` = 仅 API 边界定义；`adr-audit` = 仅审计既有 ADR 的引擎兼容缺口。（出处：Argument modes）
R2. 必须"仅一次写入"：文档在 Phase 7 一次写成；Phase 7b 的 Step 4 只更新 Document Status（且先经其自身的询问）；由 Phase 7b 促成的修订同样只在重新起草的节全部获批准后一次写入；一次更新（Phase 0e）只写它选定要写的节。（出处：Collaborative Protocol 第 6 条）
R3. Phase 0–8（加载上下文 / 系统层映射 / 模块归属 / 数据流 / API 边界 / ADR 审计与追溯检查 / 缺失 ADR 清单 / 写总文档 / 移交）的步骤各在 `references/0-load-context.md` 至 `references/8-handoff.md` 中；进入各阶段时必须立即读取对应文件并遵循之；会话压缩或恢复后处于该阶段时必须重读。（出处：Phases 0–8）
R4. 随决策进行必须把每个已批准节的决策记入 `production/session-state/active.md`，使崩溃不丢任何决策。（出处：Collaborative Protocol 第 6 条）

**协作协议（collaborative 模式，默认；guided/autonomous 见 `.claude/docs/automation-modes.md`）**
R5. 必须静默加载上下文——禁止叙述每次文件读取；发现（知识缺口清单、层提案）要呈现给用户。（出处：Collaborative Protocol 第 1–2 条）
R6. 每个架构选择必须先呈现选项再决策；禁止在无用户输入的情况下做任何有约束力的架构决策；用户不确定时必须先给 2–4 个带利弊的选项再请其裁决。（出处：Collaborative Protocol 第 3 条 / 尾段）
R7. 批准前必须先展示草稿——把将写入的内容内联展示后再请求批准；禁止请求批准用户尚未看过的节。（出处：Collaborative Protocol 第 4 条）
R8. 写入批准必须用 `AskUserQuestion` 结构化工具（带标签选项 [A]/[B]/[C]：现在写 / 先看完整草稿 / 暂不写），纯文本"可以吗？"不足够；多文件变更集必须列全每个文件及其改动后一次性分组询问，禁止逐文件纯文本追问。（出处：Collaborative Protocol 第 5 条）
R9. 每次 `AskUserQuestion` 必须遵循 `.claude/docs/automation-modes.md`（collaborative 恒提问 · guided 仅重大事项 · autonomous 记录后继续；`automation_always_ask` 类别恒提问）。（出处：开头约定）
R10. `docs.density` 必须应用于每一节的撰写深度（档位见"数据依赖"节），它不改变哪些节存在。（出处：docs.density 段）

**门禁与移交**
R11. 派生智能体自读其门禁文件（`.claude/docs/director-gates/[gate-id].md`），父会话禁止读取它；完整检查模式见 `.claude/docs/director-gates.md`。（出处：开头段）

**收尾与后续步骤（Recommended Next Steps）**
R12. 文档写成后的推荐链路必须按序引导：① `/architecture-decision [title]` 逐个撰写 Phase 6 列出的必需 ADR——Foundation 层 ADR 优先；② `/architecture-review`——从刚写的 ADR 自举 Requirements Traceability Matrix 与 TR 注册表，为每个临时 TR-ID 分配永久 ID，Pre-Production 门禁前必需；③ `/test-setup` 脚手架 `tests/unit/`、`tests/integration/`、CI workflow 与示例测试（gate-check 必需）；④ `/ux-design` 初始化 `design/ux/interaction-patterns.md` 与 `design/accessibility-requirements.md`（gate-check 必需）；⑤ 必需 ADR 写完后运行 `/create-control-manifest` 产出场层规则清单；⑥ 全部必需 ADR、`/test-setup`、`/ux-design` 完成后 `/gate-check pre-production`。（出处：Recommended Next Steps）

## 4. 门禁与裁决
- 本技能产出物是下游门禁的输入：`/gate-check pre-production` 要求 architecture.md + 必需 ADR + TR 注册表（经 `/architecture-review` 自举）+ 测试脚手架 + UX 基础文件齐备。
- 派生评审遵循 director-gates 模式；本技能正文未定义自身裁决词（门禁定义在各 `[gate-id].md` 文件中，由被派生智能体执行）。

## 5. 移植建议
- **可直接移植**：R2（一次性写入 + 状态字段单独更新）、R4–R9（静默读、先草稿后批准、结构化写批准、多文件分组询问、无输入不做约束性决策）、R10（三档文档密度）、R12 的流程链思想。
- **需替换概念**：GDD → 需求文档；引擎（pinned engine）→ 技术栈/框架的锁定版本；ADR → 技术决策记录；Foundation/Core/Feature/Presentation 四层 → 项目的分层架构（如基础设施/领域/应用/接口）；sprint 计划 → 迭代排期。
- **改写示例**：
  - "总架构文档必须一次性写成（在写档阶段），此前逐节展示草稿并获用户批准；后续修订同样只在重起草节批准后一次写入，禁止边聊边零碎落盘。"
  - "禁止在没有用户输入的情况下敲定任何有约束力的架构决策；用户犹豫时必须给出 2–4 个带利弊的选项供选择。"

## 6. 关联文档
- 上游：全部已批准 GDD（`design/gdd/`）
- 下游：`/architecture-decision`（按 Phase 6 必需 ADR 清单逐个撰写）、`/architecture-review`（自举追溯矩阵与 TR 注册表）、`/test-setup`、`/ux-design`、`/create-control-manifest`、`/gate-check pre-production`
- 规范文档：`.claude/docs/director-gates.md` 及 `director-gates/[gate-id].md`、`automation-modes.md`、`workflow-modes.md`、`config-resolution.md`
