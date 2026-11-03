# create-stories — 史诗拆故事卡（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/create-stories/SKILL.md) ｜ 阶段：Phase 4 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/create-stories [epic-slug | epic-path] [--review full|lean|solo]`
- **一句话职责**：把一个史诗拆成可实现的故事卡（story），每张卡含验收标准、TR-ID 追踪、ADR 引用与 ADR Version 戳，并给出 Ready/Blocked 状态。
- **触发前置**：
  - `minimal` 档：`design/game-brief.md` 存在（缺失则停止，提示 `/brainstorm`；代码根已有 ≥10 个源文件时改指 `/reverse-document design [code root]`）。
  - `standard`/`full` 档：`production/epics/[epic-slug]/EPIC.md` 存在；史诗引用的 ADR 文件存在（`full` 档全部必需；`standard` 档仅 Foundation 层 ADR 缺失才停）。
  - 每个史诗跑一次，按依赖顺序：Foundation → Core → Feature → Presentation。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`review_mode, review_gate, automation, workflow, docs.density, story_granularity, qa.level, system_overrides`（resolve_config；`--review` 覆盖 `review_mode`；无块 → `.claude/docs/config-resolution.md` 默认） | `workflow`+`system_overrides` 定档；`story_granularity` 定每卡 AC 数；`docs.density` 定散文深度；`qa.level` 定测试豁免；`review_gate` 定 QL-STORY-READY |
| 读取 | `minimal`：仅 `design/game-brief.md` 整读（一页） | 禁止读 GDD、control manifest、TR registry、ADR |
| 读取 | `standard`/`full`：`EPIC.md` 整读；GDD 按章节抽（Acceptance Criteria、Formulas、Edge Cases、Detailed Design——exit 3 时试 `Detailed Rules`；`full` 再加其余必需章节）；control manifest 只抽 `[Layer] Layer Rules` + `Manifest Version` 行；TR registry 只抽 `system: <slug>\s*$` 匹配行（锚定防 `combat` 误配 `combat-ai`，`\s*` 兼容 Windows 行尾）；`adr-status.sh ADR-0001 ADR-0003 ...` 一次查全部引用 ADR，再只读各 ADR 的 Summary、Decision（含 Implementation Guidelines）、Engine Compatibility | Engine Notes 是故事字段（取自 Engine Compatibility），不是 ADR 章节；无这些章节的老 ADR 整读一次并标记给 `/architecture-decision retrofit [file]` |
| 产出 | `production/epics/[epic-slug]/story-[NNN]-[slug].md`（按 `.claude/docs/templates/story.md` 布局）；`EPIC.md` 的 `## Stories` 表；`production/epics/index.md` 的 Stories 单元格 | 一次询问批量写；`index.md` 不存在时明说未更新 |
| 派生智能体 | `skill-gates=run` 时派 QL-STORY-READY QA 主审智能体（读 `references/qa-lead-gate.md` + `.claude/docs/director-gates.md`） | skip 时无智能体，主会话直接执行 |

## 3. 核心规则
R1. 档位判定：取该史诗系统的 `system_overrides` 行（无则项目 `workflow` 值）。（Phase 1）
R2. `story_granularity` 决定每张卡的验收标准负载，通过组合或拆分命中：`coarse`（默认，`rigor: minimal`）= 每卡 5-10 条 AC，整特性、多天；`balanced`（`rigor: standard`）= 2-4 条，一个任务、约一个会话；`fine` = 1 条，卡名复述该标准。（Phase 1）
R2 对应的粒度表（保留原文格式约定）：

| `story_granularity` | ACs per story | Size |
|---|---|---|
| `coarse`（默认，`rigor: minimal`） | 5-10 | a whole feature, multi-day |
| `balanced`（`rigor: standard`） | 2-4 | one task, about one session |
| `fine` | 1 | one criterion; the story name restates it |

R3. `docs.density` 只定散文（context、implementation notes、ADR summary）深度——`terse`（默认）项目符号无前言 / `balanced` 短背景段+笔记 / `thorough` 完整背景+指引+ADR 理由；禁止用它裁剪 AC 数量或 AC 文本，TR-ID、ADR Version、验收标准永远不裁。（Phase 1）
R4. 定位史诗：入参去掉 `--review` 对后是 slug 或路径；没输入但请求点名了史诗（"the loot epic"）算点名。点名但 `EPIC.md` 不在：`standard`/`full` 停止并提示先 `/create-epics` 或 `ls production/epics/` 核对，禁止凭猜测拆解；`minimal` 说明该档无需史诗、走 minimal 分支并报告所用 slug。空白输入：`minimal` 走 minimal 分支；`standard`/`full` 列出全部 `production/epics/*/EPIC.md` 及状态后每史诗一个选项来问；一个史诗都没有时停止并提示先跑 `/create-epics layer: foundation`；禁止提出没有选项的问题。（Phase 1）
R5. `minimal` 分支：slug 取 brief 的 working title（无则 `mvp`）或用户点名；已有 `EPIC.md` 就用它（scope 仍追溯到 brief，禁止重写）；没有则起草（Goal=一句话 pitch，scope=MVP 特性表，order=Build order），只在 Phase 6 询问点名后才在 Phase 7 写。一个 MVP 特性一张卡，按 Build order，每张追溯到 brief；该档没有任何因 ADR 被 Blocked 的卡。回访时禁止重写已有 `story-*.md`，只为未覆盖的 brief 项或用户点名的新项补卡，编号从已有最高 `story-NNN` 续。（Phase 2）
R6. ADR 缺失（`NOT_FOUND`）处理：`full` 档在拆任何卡之前停止；`standard` 档只有该 ADR 是关键（Foundation 层）才停止，否则警告后继续、把它管的卡写成 `Blocked` 直到文件出现；停止时照抄提示文案（指向 `/architecture-decision`）。（Phase 2）
R7. 起草前必须按真实状态报告，每个 ADR 单列状态：`Loaded: epic [name] · GDD [file] · manifest v[date], [layer] rules` + `ADRs: ADR-0001 Accepted · ...`；禁止在缺件时说"all present"、禁止在没有 manifest 时报版本。（Phase 2）
R8. 每张卡按其 AC 引用的内容定类型：**Logic**（公式/阈值/状态转移/AI 决策/计算）、**Integration**（≥2 系统、跨边界信号、存读档往返）、**Visual/Feel**（动画/VFX/"手感"/时序/震屏/音频同步）、**UI**（菜单/HUD/按钮/屏幕/对话框/提示）、**Config/Data**（仅平衡值与数据文件、无新逻辑）；混合卡取实现风险最高的类型；类型决定 `/story-done` 需要的证据。（Phase 3）
R9. 分组规则：需要相同核心实现的需求合成一张卡，负载对准 `story_granularity`；排序：基础行为在前、边缘情况在后、UI 最后。（Phase 4）
R10. Requirement 字段：TR-ID 取自 registry、经史诗 GDD Requirements 表匹配；仅当无条目匹配时写 `TR-[system]-???` 并说明。（Phase 4）
R11. ADR 字段规则：`Accepted` → 内嵌；`Proposed` → `Status: Blocked`，注明"BLOCKED: ADR-NNNN is Proposed — accept it with `/architecture-decision accept ADR-NNNN` once decided"；`Deprecated`/`Superseded` → `Status: Blocked`，注明指向后继 ADR（本技能禁止重写已有卡，需手工改 ADR 字段）；`Accepted` 但 `depends_on` 指向非 Accepted ADR → 同样 Blocked 并点名该 ADR；多个适用 → 全列、最直接的在前；无适用 → `ADR: N/A — [原因]`，禁止留空（空 = 未检查）。（Phase 4）
R12. **ADR Version 戳**：故事卡的 ADR Version = 该 ADR 的 `## Last Verified` 日期，否则 `## Date`，否则 `unversioned`（即 adr-status 的 `version` 列）；`/dev-story` 信任卡内 ADR 摘要的前提是此戳仍与 ADR 匹配。（Phase 4）
R13. Engine risk 取自 ADR 的 Engine Compatibility（knowledge risk）；Estimate 提议 t-shirt 尺码：`S`（数小时）/ `M`（约一天）/ `L`（数天），Phase 6 展示且用户可改；禁止把 Estimate 留成模板括号——`/story-readiness` 会直接判 FAIL。（Phase 4）
R14. QL-STORY-READY 审查：`skill-gates=skip`（solo/lean）不审，在 Phase 6 列表与收尾块注明 `QL-STORY-READY skipped — [Solo | Lean] mode`；`skill-gates=run` 时读 `references/qa-lead-gate.md` + `.claude/docs/director-gates.md`，在 Phase 6 询问前运行；skip 时不加载。（Phase 5）
R15. Phase 6 按标准格式列出全部故事（标题—类型—ADR—Ready/BLOCKED—Estimate、Covers 的 TR-ID、Test/Evidence required），附类型统计与 Blocked 计数、QL-STORY-READY 结论；然后**只问一次**："可否把这 [N] 张卡写入 `production/epics/[epic-slug]/`，并 [create | update] 其 `EPIC.md`、更新 `production/epics/index.md`？"选项：Yes, write all [N] / Not yet, I want to adjust first（调整可改任何 estimate）；必须点名 Phase 7 会碰的每个文件：`EPIC.md` 只在不存在时 create，`index.md` 不存在就不提；yes 之前禁止写任何东西。（Phase 6）
R15 对应的 Phase 6 列表格式（保留原文格式约定）：

```
## Stories for Epic: [name]
ADRs: ADR-0001 Accepted · ADR-0002 Accepted · ADR-0004 Proposed   (every ADR, from Phase 2)

Story 001: [title] — Logic — ADR-0001 — Ready — Estimate M
  Covers: TR-[system]-001 ([one-line requirement])
  Test required: tests/unit/[system]/[slug]_test.[ext]

Story 002: [title] — Integration — ADR-0004 — BLOCKED (ADR-0004 is Proposed) — Estimate L
  Covers: TR-[system]-002, TR-[system]-003
  Test required: tests/integration/[system]/[slug]_test.[ext]

Story 003: [title] — Visual/Feel — ADR-0001 — Ready — Estimate S
  Covers: TR-[system]-004
  Evidence required: retained screenshot + sign-off in production/qa/evidence/[slug]-evidence.md

[N stories: N Logic, N Integration, N Visual/Feel, N UI, N Config/Data; N Blocked]
QL-STORY-READY: [skipped — Solo mode | its verdicts]
```

R16. `minimal` 档的 Phase 6 列表：每行追溯到 `Brief MVP feature N`、无 ADRs 行、每个 MVP 特性恰好一张卡，禁止给 MVP 清单之外的 brief 项加卡。（Phase 6）
R17. 故事文件路径 `production/epics/[epic-slug]/story-[NNN]-[slug].md`，按 `.claude/docs/templates/story.md` 布局；编号禁止复用；必须作为文件写出，禁止经 shell 命令写（shell 写会绕过项目的写检查）。（Phase 7）
R18. `minimal` 档字段精确取值：GDD=`design/game-brief.md`；Requirement=`Brief MVP feature N`（禁止 TR-ID）；ADR 三字段=`N/A (minimal — no ADRs)`；Manifest 两字段=`N/A (minimal — no control manifest)`；Engine=`engine.name`+`engine.version`；Risk=VERSION.md 对锁定版本给的档（时间线行或总评），无文件或无档写 `NOT ASSESSED (no VERSION.md risk rating)` 禁止猜（`/dev-story` 把 NOT ASSESSED 读作 HIGH）；Engine Notes=`none (no ADR engine-compatibility analysis at minimal)`；AC 来自 brief 的 **Player goal & fail state** 与该 MVP 特性，做成具体可测，禁止凭光秃秃的 bullet 编造。（Phase 7）
R19. 各档通用字段：QA Test Cases 在审查被跳过时写 `*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*`，禁止即兴编测试用例；Test Evidence 由 `qa.level` 决定——`qa.level: minimal` 测试豁免（advisory），但 Visual/Feel 或 UI 卡的留存截图不豁免；Estimate 用 Phase 6 定稿值（含用户改动）；Dependencies 按路径点名依赖卡；Files 列计划创建/改动的代码与测试文件（`/dev-story` 会换成真实清单）。（Phase 7）
R20. `EPIC.md`：`minimal` 无文件时写 Phase 2 草稿加 `## Stories` 表；否则把 "Stories: Not yet created" 行替换为该表，回访时每张新卡追加一行、其余原样不动。表列：`| # | Story | Type | Status | ADR |`。（Phase 7）
R21. `index.md`：把该史诗的 Stories 单元格设为 `[N] stories`（本次运行后的总数）；文件不存在时明说 `Epics index not updated: production/epics/index.md absent`。（Phase 7）
R22. 收尾：其它史诗还没有卡时列出来，然后问"接下来做什么？"——选项按适用给：开始实现（`minimal` 直接 `/dev-story [path]`，否则推荐先 `/story-readiness [path]`）；给下一个无卡史诗跑 `/create-stories [slug]`；全部史诗有卡且非 `minimal` 时才给 `/sprint-plan new`（`minimal` 禁止，brief 的 build order 即计划）；或本次到此为止。本技能禁止开始实现或写代码，止步于故事文件。（Phase 8）
R23. AC 来自 GDD（`minimal` 来自 brief）、实现注记来自 ADR、规则来自 manifest；禁止发明。（Phase 8）
R24. 上述问题得到回答后，最后一条回复以收尾块结束：`Verdict: COMPLETE — [N] stories written to production/epics/[epic-slug]/ ([N] Ready, [N] Blocked)` + `Review: [QL-STORY-READY skipped — Solo mode | skipped — Lean mode | its verdicts]` + `Index: [production/epics/index.md updated | Epics index not updated: ... absent]` + `Next step: [/dev-story [path] | /story-readiness [path]]`。用户拒绝写入：`Verdict: BLOCKED — user declined. No story files written.`（Phase 8）
R25. 提问规则：有提问工具就用工具；没有则编号列选项并结束回合等待；被跳过/关闭的提问不算答案，纯文本再问。（全局）

## 4. 门禁与裁决
- **门禁 ID**：QL-STORY-READY（QA 主审审查）。
- **触发**：`review_gate` 的 `skill-gates`：`skip`（solo/lean）→ 不审并注明；`run` → 在 Phase 6 询问之前运行（读 `references/qa-lead-gate.md` + `.claude/docs/director-gates.md`；skip 时不加载）。
- **裁决呈现**：Phase 6 列表 `QL-STORY-READY: [skipped — Solo mode | its verdicts]` 行 + 收尾块 `Review:` 行。

## 5. 移植建议
- **可直接移植**：R2-R3（粒度/密度对 AC 的边界）、R4（目标不存在时禁止猜测拆解、无选项不提问）、R6-R7（引用缺失的分档停止策略与如实报告）、R8-R9（类型判定与分组排序）、R11-R13（引用状态→Blocked 规则、版本戳、估 禁留模板括号）、R14-R15（门禁二值 + 一次批量写入询问）、R17（编号不复用、禁 shell 写文件）、R19-R21（回访只追加、索引只更新计数）、R24-R25（收尾块与提问协议）。
- **需替换概念**：GDD → 领域规格文档；ADR（Accepted/Proposed/Deprecated/Superseded）→ 技术决策记录；TR registry → 需求追踪表；control manifest → 变更控制清单；engine VERSION.md → 关键依赖版本风险表；Visual/Feel、UI 等故事类型 → 按项目交付物重定义证据类型；QA lead → 质量负责人。
- **改写示例**：
  - "每张任务卡的决策引用必须带版本戳：取该决策文档的 Last Verified 日期（无则 Date，再无则 unversioned）；执行技能只在戳仍匹配时信任卡内摘要。"
  - "引用处于 Proposed 状态的决策时任务卡必须置为 Status: Blocked，并写明解锁命令；已有任务卡永不重写，改引用需手工编辑。"

## 6. 关联文档
- 上游：`/create-epics`（产 EPIC.md）、`/brainstorm`（产 brief）、`/reverse-document`（补文档）。
- 下游：`/story-readiness [story-path]`（非 minimal 推荐）、`/dev-story [story-path]`（实现）、`/sprint-plan new`（全部史诗有卡后）、`/architecture-decision`（accept/retrofit ADR）。
- 引用：`.claude/docs/templates/story.md`、`.claude/docs/config-resolution.md`、`.claude/docs/automation-modes.md`、`.claude/docs/director-gates.md`、`references/qa-lead-gate.md`。
