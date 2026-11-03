# tech-debt — 技术债扫描与优先级（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/tech-debt/SKILL.md) ｜ 阶段：Phase 6 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/tech-debt [scan|add|prioritize|report]`
- **一句话职责**：扫描代码库技术债指标、维护 `docs/tech-debt-register.md` 债务登记册（TD-NNN 条目、六类分类、impact÷effort 评分排序）并生成趋势报告。
- **触发前置**：子命令必填——缺省时输出用法并停止，Verdict: **FAIL** — missing required subcommand；配置经 `resolve_config --keys automation,workflow` 解析。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 代码根（按 `.claude/docs/code-root-resolution.md` 解析：`src/`、`Assets/` 或 `Source/`，按引擎）；`docs/tech-debt-register.md`（prioritize/report 模式）；用户输入（add 模式：描述与受影响文件） | 扫描对象 / 登记册 |
| 产出 | `docs/tech-debt-register.md`（scan 追加/更新、add 追加、prioritize 重排序写回；**永不覆盖**） | 十列固定格式（见 R12） |
| 派生智能体 | 无独立 spawn；但 `lead-programmer` 预载本技能——在子代理中运行时无 `AskUserQuestion`，按 R8 回传问题 | 模型档位 sonnet |

## 3. 核心规则（逐条编号 R1、R2……）

### Phase 1 — 解析子命令
R1. 四模式：`scan` 扫代码库技术债指标；`add` 手工添加债务条目；`prioritize` 重排现有登记册；`report` 生成当前债务状态摘要报告。无子命令 → 输出用法并停止，Verdict: **FAIL** — missing required subcommand。（Phase 1）

### Phase 2A — Scan 模式
R2. 在代码根搜七类指标：`TODO` 注释（计数并分类）、`FIXME`（伪装成债务的 bug）、`HACK`（待正规方案的工作绕行）、`@deprecated` 标记、重复代码块（多文件相似模式）、超 500 行的文件（潜在 god object）、超 50 行的函数（潜在复杂度）。每条发现归入六类之一：**Architecture**（错误抽象、缺失模式、耦合）、**Code Quality**（重复、复杂度、命名、缺失类型）、**Test**（缺测试、flaky、未测边缘）、**Documentation**（缺文档/过期/未记录 API）、**Dependency**（过期包、废弃 API、版本冲突）、**Performance**（已知慢路径、未优化查询、内存问题）。（Phase 2A）
R3. **呈现任何结果前先确认有东西可扫**：统计扫描实际覆盖的源文件数。代码根未解析 → 报 `NOT ASSESSED — code root unresolved` 并按下述停止。覆盖数为**零**（代码根缺席或无源文件）→ 报 "**NOT ASSESSED — no source files to scan.** 代码根里没有代码，'no debt indicators found' 是关于空搜索的陈述而非关于代码库的"并停止——**禁止**写登记册、**禁止**输出 COMPLETE 裁决。（Phase 2A）
R4. 区分即扫描的全部意义：**400 个文件上的零发现是干净代码库；零文件上的零发现是零信息**。两者都渲染成 "COMPLETE — scan findings written to register" 会读成前者。报告发现时**必须**陈述分母——包括分母很大且计数确实为零的时候。（Phase 2A）
R5. 呈现发现后征询："May I write these findings to `docs/tech-debt-register.md`？" 获准则更新登记册（永不覆盖）：**先匹配再追加**——同文件同债务类型的发现更新既有 `Open` 条目而非加重复行；既有 `Open` 条目的模式已不在其文件中 → 提议标 `Resolved [date]`，逐条列出并纳入同一次批准。Verdict: **COMPLETE** — scan findings written to register。被拒 → 停止，Verdict: **BLOCKED** — user declined write。（Phase 2A）

### Phase 2B — Add 模式
R6. 先用纯文本提示问用户描述与受影响文件。（Phase 2B）
R7. **子代理运行**：`lead-programmer` 预载本技能而子代理没有 `AskUserQuestion`——把下面三个问题（category、effort、impact）在一次回复里返回（每个问题附其选项的短清单）并停止：由调用方去问用户。答案回来之前**任何东西都不进登记册**。（Phase 2B）
R8. 三问（均 `AskUserQuestion`）：
   - **category**："What category does this tech debt belong to?" — `[A] Architecture` / `[B] Code Quality` / `[C] Test` / `[D] Documentation` / `[E] Dependency` / `[F] Performance`（各带一句定义）；
   - **effort**："What is the estimated effort to fix this item?" — `[A] S — Small (under 1 day)` / `[B] M — Medium (1–3 days)` / `[C] L — Large (3–7 days)` / `[D] XL — Extra Large (over 1 week)`；
   - **impact**（登记册 Impact 列，`prioritize` 打分依据）："What does this cost if it is never fixed?" — `[A] Low` / `[B] Med` / `[C] High` / `[D] Critical`。（Phase 2B）
R9. 向用户呈现完整新条目；**先匹配再追加**：既有 `Open` 条目同文件同 category → 展示给用户并问是否更新该条目而非加重复项。征询 "May I append this entry to `docs/tech-debt-register.md`？"（匹配时改问 "May I update the existing entry instead?"）。获准 → 追加/更新，Verdict: **COMPLETE** — entry added to register；被拒 → 停止，Verdict: **BLOCKED** — user declined write。（Phase 2B）

### Phase 2C — Prioritize 模式
R10. 读 `docs/tech-debt-register.md`；不存在 → Verdict: **NOT ASSESSED** — no register at `docs/tech-debt-register.md`; run `/tech-debt scan` first. 停止。（Phase 2C）
R11. **按条目自身两列打分**：`impact ÷ effort`，Impact 取值 Low=1 / Med=2 / High=3 / Critical=4，Effort 取值 S=1 / M=2 / L=3 / XL=4，四舍五入到一位小数写入 Priority 列。分数高者在前；同分取 `Added` 日期更早者。Impact 或 Effort 为 `—` 的条目**不打分**：列在打分条目之后，标 "not scored — [column] not judged"，禁止猜分。按分数重排登记册并建议下个 sprint 纳入哪些条目（`workflow: minimal` 无 sprint——建议接下来构建哪些）。呈现重排结果，征询 "May I write the re-prioritized register back?"；获准 → 写回，Verdict: **COMPLETE** — register re-prioritized and saved；被拒 → Verdict: **BLOCKED**。（Phase 2C）

### Phase 2D — Report 模式
R12. 读登记册；不存在 → Verdict: **NOT ASSESSED** — no register to report on; run `/tech-debt scan` first. 停止。生成统计：各 category 的 Open 条目及其总估算修复投入；本 sprint 内新增与解决的条目数（按各条目 `Added` 日期与 `Resolved [date]` 状态）；趋势方向（growing / stable / shrinking——窗口内 added vs resolved）。**标记在登记册中超过 3 个 sprint 的条目**。报告输出给用户；本模式只读、不写文件。Verdict: **COMPLETE** — debt report generated。（Phase 2D）

### 登记册格式（所有写入方共用）
R13. 表头：`## Technical Debt Register` + Last updated + Total items | Estimated total effort（T-shirt 尺寸求和）。表列固定十列按序：**ID | Category | Description | Files | Effort | Impact | Priority | Status | Added | Sprint**。任何添加行的技能（本技能、以及把偏差记为债的 `/story-done`）都必须按此顺序写全十列；创建文件的技能先写头部与表头。各列约定：
   - **ID** — `TD-` + 三位数字，取登记册中最高 ID 之上一个（新册首条 `TD-001`）；**ID 永不复用**；
   - **Category** — 六类之一，**不带 "Debt" 后缀**：`Architecture` / `Code Quality` / `Test` / `Documentation` / `Dependency` / `Performance`——与 `/story-done` 的拼写一致，Report Mode 才能一次分组；
   - **Files** — 受影响路径，逗号分隔；无单一文件时 `—`；
   - **Effort** — `S`/`M`/`L`/`XL`；未估 `—`；
   - **Impact** — `Low`/`Med`/`High`/`Critical`；未判 `—`；
   - **Priority** — `prioritize` 写的分数；未跑 `—`；
   - **Status** — 添加时 `Open`；`Resolved YYYY-MM-DD` 记修复日；`Accepted — reason` 记有意识的保留决定；
   - **Added** — 行写入日 `YYYY-MM-DD`（Report Mode 由此 + Resolved 日期统计增减）；
   - **Sprint** — 计划修复的 sprint，或 `Backlog`。（Debt Register Format）

### Phase 3 与原则
R14. 后续：`/sprint-plan` 把高优先级债排进下个 sprint（`workflow: minimal` 加进 brief 的 build order）；每个 sprint 开始时跑 `/tech-debt report` 追踪趋势。（Phase 3）
R15. 原则：技术债本身不是坏事——是工具，登记册追踪的是有意识的决定；每条债务必须解释**为什么**被接受（deadline、prototype、缺信息）；`scan` 每 sprint 至少跑一次以捕获新债；超过 3 个 sprint 无行动的条目要么修掉、要么带书面理由有意识地接受。（Rules）

## 4. 门禁与裁决
- **裁决词（按模式）**：scan/add/prioritize → `COMPLETE` / `BLOCKED`（用户拒写）；scan 另有 `NOT ASSESSED`（代码根未解析或零源文件）；report → `COMPLETE` / `NOT ASSESSED`（无登记册）；无子命令 → `FAIL`。
- **关键裁决纪律**：`NOT ASSESSED`（零文件可扫）不得渲染成 COMPLETE——零发现于零文件是零信息；拒绝写盘是 BLOCKED 而非静默放弃。
- **消费方**：`/sprint-plan`（排期高优先级债）、`/story-done`（写 TD 行的另一方，共用十列格式）。

## 5. 移植建议
- **可直接移植**：R3-R4（分母陈述纪律："400 文件零发现是干净；零文件零发现是零信息"）、R5/R9（先匹配再追加、既有条目自动提议 Resolved）、R11（impact÷effort 评分、`—` 不打分不猜分）、R13 十列表结构与 ID 永不复用、R15（3 sprint 未动要么修要么书面接受）。
- **需替换概念**：`TODO/FIXME/HACK/@deprecated` 指标 → 语言生态等价物（`// TODO`、`@SuppressWarnings`、`#nosec`）；引擎代码根 → 项目的源码根；sprint → 迭代周期；`/story-done` → 把实现偏差记为债的任务完结流程。
- **改写示例**：
  - R4 → "报告扫描发现时必须同时陈述分母（扫描覆盖的文件数）：零发现于大量文件是干净，零发现于零文件是零信息——两者不得渲染成同一结论。"
  - R11 → "优先级 = impact ÷ effort（Low..Critical 映射 1..4，S..XL 映射 1..4，一位小数）；未评 effort 或 impact 的条目列在打分项之后并标 'not scored'——绝不代猜。"

## 6. 关联文档
- 上游：`/tech-debt scan` 自身（登记册的创建者）。
- 下游：`/sprint-plan`（排期）、`/tech-debt report`（每 sprint 趋势）。
- 关联：`/story-done`（以同一十列格式把实现偏差写为 TD 行）、`.claude/docs/code-root-resolution.md`（代码根解析）。
