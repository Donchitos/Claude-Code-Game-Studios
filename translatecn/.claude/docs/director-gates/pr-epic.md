> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起该门禁的技能会将此文件的路径传给总监智能体；由智能体读取它——父会话不应读取。

# PR-EPIC — Epic Structure Feasibility Review

# PR-EPIC — 史诗结构可行性评审

Agent: `producer` | Model tier: Opus | Domain: Scope, timeline, dependencies, production risk

智能体：`producer` | 模型层级：Opus | 领域：范围、时间线、依赖、制作风险

**Trigger**: After epics are defined by `/create-epics`, before stories are
broken out — validates the epic structure is producible before `/create-stories`
is invoked

**触发时机**：`/create-epics` 定义史诗之后、故事拆分之前——在调用 `/create-stories` 之前验证史诗结构可生产

**Context to pass**:
- The epic structure for the layer, inline — every epic's scope summary and
  governing-ADR count. `/create-epics` runs this gate *before* writing any epic
  file, so there are no paths yet.
- Milestone timeline and target dates
- Team capacity (solo / small team / size)
- Layer being epiced (Foundation / Core / Feature / etc.)

**需传入的上下文**：
- 该层级的史诗结构，以内联方式提供——每个史诗的范围摘要与管辖 ADR 数量。`/create-epics` 会在写入任何史诗文件*之前*运行该门禁，因此此时尚无文件路径。
- 里程碑时间线与目标日期
- 团队产能（单人 / 小团队 / 规模）
- 正在划分史诗的层级（Foundation / Core / Feature 等）

**Prompt**:
> "Review this epic structure for production feasibility before story breakdown
> begins. Are the epic boundaries scoped appropriately — could each epic realistically
> complete before a milestone deadline? Are epics correctly ordered by system
> dependency — does any epic require another epic's output before it can start?
> Are any epics underscoped (too small, should merge) or overscoped (too large,
> should split into 2-3 focused epics)? Are the Foundation-layer epics scoped to
> allow Core-layer epics to begin at the start of the next sprint after Foundation
> completes? Return REALISTIC (epic structure is producible), CONCERNS [specific
> structural adjustments before stories are written], or UNREALISTIC [epics must
> be split, merged, or reordered — story breakdown cannot begin until resolved]."

**提示词**：
> “在故事拆分开始之前，评审此史诗结构的制作可行性。史诗边界划分是否恰当——每个史诗是否都有现实可能在一个里程碑截止日期前完成？史诗是否按系统依赖正确排序——是否有史诗需要另一个史诗的产出才能开始？是否有史诗范围过小（太小，应当合并）或范围过大（太大，应拆分为 2-3 个聚焦的史诗）？Foundation 层史诗的范围划分，是否允许 Core 层史诗在 Foundation 完成后、下一个冲刺开始时启动？返回 REALISTIC（史诗结构可生产）、CONCERNS [写故事前需做的具体结构调整]，或 UNREALISTIC [史诗必须拆分、合并或重排——问题解决前不能开始故事拆分]。”

**Verdicts**: REALISTIC / CONCERNS / UNREALISTIC

**裁定**：REALISTIC / CONCERNS / UNREALISTIC
