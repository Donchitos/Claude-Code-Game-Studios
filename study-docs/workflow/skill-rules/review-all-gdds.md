# review-all-gdds — 跨 GDD 一致性 + 设计理论双阶段审查（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/review-all-gdds/SKILL.md)（含 references/1~7） ｜ 阶段：Phase 2 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/review-all-gdds [focus: full | consistency | design-theory | since-last-review]`
- **一句话职责**：同时读取全部系统 GDD，做两个无法逐文档孤立完成的互补审查——**Cross-GDD Consistency**（文档间矛盾、过时引用、所有权冲突）与 **Game Design Holism**（只在所有系统同框时浮现的问题：主导策略、经济失衡、认知过载、pillar 漂移、竞争进度循环）
- **触发前置**：全部 MVP 档 GDD 单独批准后；任何 GDD 生产中大幅修订后；`/create-architecture` 开始前（在不一致的 GDD 上建架构会继承不一致）。区别于 `/design-review`（单 GDD 内部完整性）——本技能审查 GDD **之间的关系**。`workflow: minimal` 下不适用（无 GDD）。每 GDD 按其有效档验证（`system_overrides` 行覆盖项目值）：`full` 验全部 8 节；`standard` 验 5 必需节，可选节（Player Fantasy、Tuning Knobs、条件 Formulas）仅 advisory

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `automation, workflow, system_overrides` | 决定验证档位 |
| 读取 | `design/gdd/*.md` 的 `## Summary`（L0 扫描）→ 命中节（L1/L2） | 只加载本审查实际消费的节，非全文 |
| 读取 | `design/gdd/game-concept.md`（或 minimal 的 brief）、`game-pillars.md`、`systems-index.md` | 整读（小且全用） |
| 读取 | `design/registry/entities.yaml` | 预建冲突基线 |
| 读取 | `project.yaml` 的 `engine.name`/`engine.version`（各自独立解析）+ `docs/engine-reference/[engine]/VERSION.md` | 随简报传给子代理 |
| 执行 | `bash .claude/scripts/review-scope.sh` | `since-last-review` 模式确定性算范围（PRIOR_REVIEW/CHANGED/DEPS） |
| 产出 | `design/gdd/gdd-cross-review-[date].md`（日期必须 ISO 8601）、systems-index 状态更新、`active.md` Session Extract | 报告含三段问题清单+标记表+裁决 |
| 派生智能体 | **2 个并行 `game-designer` 子代理**（`subagent_type: game-designer`） | 分别跑 Phase 2（一致性）与 Phase 3（设计理论）——GDD 一致性与设计理论审查是其领域 |

## 3. 核心规则（逐条编号 R1、R2……）

**Phase 1 加载（references/1）**
R1. **L0 Summary 扫描**：Grep `## Summary` -A 5 建 manifest 并确立分母 N（glob 计数）。**缺 Summary 时 fail open**：匹配数少于 N 说明那些 GDD 早于 Summary 约定——**绝不把缺失 Summary 当作系统出范围**；零匹配意味着"还没有 GDD 带 Summary"而非"无可审"。扫描只建清单和收窄 `since-last-review`，**绝不缩小审查集**。
R2. `since-last-review` 用 `review-scope.sh` 确定性计算（打印 PRIOR_REVIEW / CHANGED / DEPS 列表；`PRIOR_REVIEW: NONE` 则回退 `full` 模式）；只对 CHANGED 集+DEPS 行命名的 GDD 进 L1。
R3. **注册表预载**：`entities.yaml` 有条目则作预建冲突基线（Phase 2 先 grep 注册名再读文档）；空或缺失则照常进行，报告注记"Entity registry is empty — consistency checks rely on full GDD reads only. Run `/consistency-check` after this review to populate the registry."
R4. **L1/L2 节加载**：整读 concept/pillars/index 三个小文件；每个在范围系统 GDD **只 grep 本审查消费的节**：`^## (Dependencies|Detailed Rules|Detailed Design|Formulas|Tuning Knobs|Acceptance Criteria|Player Fantasy)` -A 40——该清单就是并行契约的并集（Phase 2 要前五者、Phase 3 要 Player Fantasy+进度/奖励结构）；Overview 与 Edge Cases 不加载（前者是 Summary 已扫的重复叙事、后者归 `/design-review`）。接受 `Detailed Rules` 或 `Detailed Design` 两种节名（标准与模板不一致、同义）。**扫描节引用了外部材料或某 GDD 零匹配节时升级为全文读**——零匹配=早于模板的"非结构化"而非"空"；**绝不静默丢弃系统：扫描收窄读取，绝不缩小审查集**。系统 GDD 少于 2 个即停止："Cross-GDD review requires at least 2 system GDDs."
R5. **并行执行契约**：Phase 2 与 Phase 3 相互独立——**同时 spawn 为并行 `game-designer` 子代理**而非串行等待；收齐两者结果再写合并报告。**必须传入内容而非文件路径**（子代理有自己的上下文、无法重读 Phase 1 结果）：各阶段只传自己的切片（Phase 2 传 Dependencies/Detailed Design/Rules/Formulas/Tuning Knobs/Acceptance Criteria；Phase 3 传 Player Fantasy/进度奖励结构/pillars）、完整注册表文本（若已载）、该阶段的检查清单项（Phase 2 得 2a-2f；Phase 3 得 3a-3g）、引擎名+版本+VERSION.md。**禁止依赖子代理自己去重读这些文件。**

**Phase 2 一致性检查（references/2，2a-2f）**
R6. 2a **依赖双向性**：A 列 "depends on B" 则 B 必须列 A 为 dependent，单向即 ⚠️ Dependency Asymmetry。2b **规则矛盾**：扫 floor/ceiling、资源所有权、状态转换、时序（同帧 vs 异步）、堆叠规则五类，矛盾即 🔴 Rule Contradiction（"Which GDD is authoritative?"）。2c **过时引用**：先从 `## Cross-References` 表开始——对每行确认三件事：`Target GDD` 存在、`Specific Element Referenced` 仍以同名存在于其中、声明的 `Nature` 仍准确（表缺失或仍是模板括号示例本身即可报告：说明散文扫描是唯一做过的检查——**不把缺表当"无依赖"**，更常意味着该节从未写）；再**无论有无表都扫正文**。严重性：引用不存在的机制/公式=**Blocking**（架构会继承无人定义的规则）；存在但被设计得不同=Warning（除非差异改变了引用方依赖的规则，则 Blocking）；目标 GDD 未写——索引有列（`Status: Not Started`）=Warning（待其写后再查），GDD 与索引条目皆无=**Blocking**。2d **所有权冲突**：两 GDD 不得都拥有同一数据/knob（双应用 bug 或设计冲突）。2e **公式兼容性**：上游输出范围须落在下游预期输入范围内，不匹配标 CONCERNS（需设计判断，未必是错）。2f **验收标准交叉**：跨 GDD 的标准不得互斥（不能同时通过）。

**Phase 3 设计整体性（references/3，3a-3g）**
R7. 3a **进度循环竞争**：应有一个主导循环+支撑循环；多系统同等自称主循环且发同一主货币即 ⚠️ Competing Progression Loops。3b **注意力预算**：统计典型会话同时主动管理的系统数（active=玩家定期决策 / passive=自动运行）；**超过 3-4 个并发 active 系统即认知过载**，超 4 必须标记 ⚠️ Cognitive Load Risk。3c **主导策略**：查资源垄断、无风险高回报（高风险策略须有成比例更高回报）、无权衡选项、"明显正确"的进度选择 ⚠️ Potential Dominant Strategy。3d **经济循环**：对每个资源映射 sources/sinks，危险条件六种——

   | 条件 | 征兆 | 风险 |
   |------|------|------|
   | 无限源、无汇 | 资源无限累积 | 后期变得 trivially easy |
   | 有汇、无源 | 资源耗到零 | 系统变得不可用 |
   | 源 >> 汇 | 盈余累积 | 资源失去意义 |
   | 汇 >> 源 | 持续稀缺 | 挫折与 gatekeeping |
   | 正反馈循环 | 资源越多越好赚 | 失控领先、雪球 |
   | 无追赶机制 | 落后加速赤字 | 不可恢复状态 |

   命中即 🔴 Economic Imbalance。3e **难度曲线**：比较各系统的缩放对象/方式（linear/exponential/stepped）/触发点，不匹配即 ⚠️ Difficulty Curve Mismatch。3f **Pillar 对齐**：每系统须清晰服务至少一条 pillar，否则是"设计上的范围蔓延"（⚠️ Pillar Drift：加 pillar、重设计服务现有 pillar、或砍掉）；**同时查 anti-pillars**——做了 anti-pillar 明说不做的事即 🔴 Anti-Pillar Violation。3g **玩家幻想连贯**：各系统幻想须兼容并强化同一身份，冲突即身份混乱 ⚠️ Player Fantasy Conflict。

**Phase 4 场景走查（references/4）**
R8. 识别 **3-5 个**最重要的多系统同时激活时刻（战斗+经济、进度+难度、叙事+玩法重叠、3+ 系统链=最高风险路径）；逐场景显式走：Trigger → 激活顺序 → 数据流（每系统输出是否为链中下一系统的合法输入）→ 玩家体验 → 失败模式（race conditions、无上限反馈循环、状态转换破坏、矛盾消息、复合难度尖峰、奖励冲突 double-dipping、未定义行为）。分级：**BLOCKER**（未定义行为/坏状态转换/矛盾消息）、**WARNING**（复合尖峰/无上限循环/奖励冲突）、**INFO**（轻微顺序歧义）。每条发现必须引用：场景名、涉及系统、发生步骤、失败模式性质。

**Phase 5 报告（references/5）**
R9. 报告含：`GDDs Reviewed: [N] of [M] present`、`Not read:`（逐个点名无法读或存在但空的 GDD，或 "none"）、Focus 行、三段问题清单（Consistency / Game Design / Scenario，各分 Blocking 🔴 与 Warnings ⚠️，场景另有 Info ℹ️）、`GDDs Flagged for Revision` 表（`GDD | Reason | Type | Priority`）、Verdict，及两个条件尾节：**If NOT ASSESSED**（逐个命名未运行的阶段及其所需输入、无法读或为空的每个 GDD 文件名）与 **If FAIL**（重跑前哪些 GDD 必须改什么的具体清单）。
R10. **裁决词**：**PASS**=无 blocking 且无 warnings；**NOT ASSESSED**=一或多审查阶段无法运行（下方点名）；**CONCERNS**=有应解决的 warnings 但无 blocking；**FAIL**=存在 blocking、架构开始前必须解决。**NOT ASSESSED 排序高于 PASS、低于 CONCERNS 和 FAIL**。触发 NOT ASSESSED 的条件：可读 GDD 少于 2 个（单文档找矛盾不是交叉审查，干净只说明没比较——**本技能最重要的触发器**）；本应运行的阶段整段没跑——**返回空报告的并行阶段是 NOT ASSESSED 而非 clean**（agent 可能返回流畅句子却什么都没写、烧掉一个阶段）；设计 pillars 未定义（pillar 漂移无参考可漂）；GDD 存在但为空（仅标题或全占位符）或无法读。**focus 参数主动略过的阶段不算此触发器**：用户要求的——给所跑的部分打带标签裁决（如 `PASS (consistency only — design theory not run)`）并填 Focus 行。
R11. **无论裁决如何都要显式报告覆盖集**：`[M]` 只数系统 GDD（不含 concept/pillars/index/早期审查报告）；已读 GDD 中的 FAIL 不使未读的变成已审——**静默跳过一半系统的交叉审查与发现它们一致无法区分**。

**Phase 6/7 写盘与交接（references/6、7）**
R12. 写报告须先问："May I write this review to `design/gdd/gdd-cross-review-[date].md`?"；**[date] 必须是 ISO 8601（YYYY-MM-DD）——这不是风格偏好**：`review-scope.sh` 用 `sort | tail -1` 选上次报告，字典序=时间序只对 ISO 日期成立；写成 `aug-19-2026` 会选错基线、算错变更集，真实上次审查后改过的 GDD 会**静默逃过下一次审查**。
R13. 有被标记 GDD 时第二个问题："Should I update the systems index to mark these GDDs as needing revision?"；同意则把各 GDD 的 Status 改为 **"Needs Revision"（精确字符串，禁止附加括号说明**——其它技能按精确匹配读它）。随后**静默**向 `active.md` 追加 `## Session Extract — /review-all-gdds [date]` 块（Verdict / GDDs reviewed / Phases not run / Flagged / Blocking issues / Recommended next / Report 行——按用户对写盘的回答写 `Report: design/gdd/gdd-cross-review-[date].md` 或 `Report: (not written — user declined at [date])`），并在对话中确认 "Session state updated."
R14. **交接 widget 动态构建**：先查项目状态（有无"30 秒能改"的 Warning 项 / 有无被标记 GDD / 索引里下一个 `Status: Not Started` 系统 / 裁决是否 PASS 或 CONCERNS **且跑了双阶段**）。选项池：`Apply quick fix: [W-XX]`（每条简单 Warning 一项，仅 Warning 级）；`Run /design-review [flagged-gdd-path]`；`Run /design-system [next-system]`（**恒包含**并写出实际系统名）；`Run /create-architecture`（**仅**双阶段审查且 PASS/CONCERNS——绝不在 FAIL、NOT ASSESSED 或 focus 单阶段运行时提供）；`Run /gate-check`（仅双阶段 PASS）；`Stop here`。只给被包含的选项编字母，最推进管道者标 `(recommended)`。collaborative/guided **绝不用纯文本收尾**——必须以此 widget 结束；autonomous 打印裁决与推荐下一步并 `log_decision`（无 widget），但 **PASS/CONCERNS/FAIL 裁决仍要打印和记录**。

**错误恢复与协作**
R15. **先验证工件**：返回契约命名了路径，就先查该路径在盘上存在，再当阶段完成——**命名的工件不在盘上就是失败阶段，无论响应读起来多流畅**（agent 可能烧掉整阶段却返回合理前言，既非 BLOCKED 也非报错，下面的触发器永远不会发射）；点名未满足的契约来恢复它。任何子代理返回 BLOCKED、报错或未完成：**立即上浮、不越过它阻塞的依赖、总要产出部分报告**（重试范围=更少 GDD/单系统）。完整程序见 `.claude/docs/error-recovery-protocol.md`。
R16. 协作六原则：**静默读**（呈现任何东西前先加载全部 GDD）；**展示一切**（任何行动前呈现完整分析）；**区分 blocking 与 advisory**（不是每个问题都该阻塞架构，说清哪些阻塞）；**不做设计决策**（标记矛盾与选项，**绝不单边裁定哪个 GDD "对"**）；**写前问**（报告与索引更新都要确认）；**具体化**（每个问题引用确切的 GDD、节、文本——禁止模糊警告）。

## 4. 门禁与裁决（如适用）
- **裁决词**：`PASS / NOT ASSESSED / CONCERNS / FAIL`（定义见 R10）；取最严：任一 blocking 即 FAIL；NOT ASSESSED 高于 PASS、低于 CONCERNS/FAIL；覆盖不完整时宁可 NOT ASSESSED 不可静默收窄。
- **审查者**：2 个并行 `game-designer` 子代理（Phase 2 / Phase 3），Phase 4 场景走查与 Phase 5 报告由主会话完成。
- 本技能无 director 门禁；错误恢复裁决（BLOCKED/部分报告）见 R15。

## 5. 移植建议
- **可直接移植**：R1（缺摘要 fail open、扫描不缩小审查集）、R4（只加载审查消费的节、零匹配升级全文）、R5（并行子代理传内容不传路径）、R10-R11（NOT ASSESSED 语义与覆盖集显式报告）、R12（文件名日期格式是排序契约）、R13（状态值精确字符串、禁加括号）、R15（命名工件不在盘=失败阶段）、R16（审查者不做裁决、问题必须带引用）。
- **需替换概念**：GDD → 模块/API 规格；pillars/anti-pillars → 项目原则与反原则；MDA/Bartle 类设计理论 → 领域质量模型（如架构权衡属性）；经济 sources/sinks → 资源配额/容量模型；`/create-architecture` → 架构定稿流程；`review-scope.sh` → 基于 git 的变更范围脚本。
- **改写示例**：
  - "跨文档审查的裁决分四档 PASS / NOT ASSESSED / CONCERNS / FAIL；任何本应运行的检查阶段没有产出报告（而非产出空结果）时必须判 NOT ASSESSED——返回空报告的并行检查是没跑，不是干净。无论裁决如何，报告必须写明『实际审查 N / 共 M 份文档』并点名未读的每一份。"
  - "审查报告的文件名日期必须用 ISO 8601：范围计算脚本按字典序取最新报告作基线，非 ISO 日期会选错基线，让真实变更静默逃过下次审查。"

## 6. 关联文档
- 上游：`/design-system`（产出被审 GDD）、`/design-review`（单 GDD 完整性，互补）、`/consistency-check`（填充注册表）
- 下游：`/create-architecture`、`/gate-check`、`/design-system`（修复后继续）
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/workflow-modes.md`、`.claude/docs/error-recovery-protocol.md`、`.claude/scripts/review-scope.sh`、references/1~7
