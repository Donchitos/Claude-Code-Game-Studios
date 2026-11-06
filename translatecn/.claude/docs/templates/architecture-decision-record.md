# ADR-[NNNN]: [Title]
# ADR-[NNNN]：[标题]

## Status
## 状态

[Proposed | Accepted | Deprecated | Superseded by ADR-XXXX]
[提议中 | 已接受 | 已弃用 | 已被 ADR-XXXX 取代]

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> **谁可以将其改为 `Accepted`：用户，或经用户明确确认后的 `technical-director`。
> 其他任何智能体都不可以，任何技能也不能自行改动。**
> Why this is stated here: stories referencing a `Proposed` ADR are set `Blocked`,
> and epics require `Accepted`, so the field needs a named owner.
> `technical-director` is the role `coordination-rules.md` already escalates
> technical conflicts to, and an ADR is that decision made durable.
> 为何在此写明：引用 `Proposed` 状态 ADR 的故事会被置为 `Blocked`，
> 而史诗要求 `Accepted`，因此该字段需要一个明确的负责人。
> `technical-director` 正是 `coordination-rules.md` 已将技术冲突
> 升级到的角色，而 ADR 就是使该决策持久化。
>
> This does **not** relax the existing rule that `Status: Accepted` is never set
> without explicit user confirmation — it narrows *which agent* may set it once
> that confirmation exists. An agent that believes an ADR is ready says so and
> escalates; it does not edit this field.
> 这**并不**放宽既有规则，即未经用户明确确认绝不设置 `Status: Accepted`
> ——它只是收窄了在该确认存在之后*哪个智能体*可以设置它。认为某 ADR 已就绪的
> 智能体应说明并上报，而不是编辑此字段。

## Date
## 日期

[Date of decision]
[决策日期]

## Last Verified
## 最后验证

[YYYY-MM-DD — when this ADR was last confirmed accurate against the current
engine version and design. Update this date when you re-read and confirm it is
still correct, even if nothing changed.]
[YYYY-MM-DD — 本 ADR 最后一次被确认与当前引擎版本和设计相符的时间。当你重读并
确认它仍然正确时更新此日期，即使没有任何变化。]

## Decision Makers
## 决策者

[Who was involved in this decision]
[谁参与了本决策]

## Summary
## 摘要

[2 sentences: what problem this ADR solves, and what was decided. Written for
tiered context loading — a skill scanning 20 ADRs uses this to decide whether to
read the full decision. Be specific: name the system, the problem, and the
chosen approach.]
[2 句话：本 ADR 解决什么问题，以及决定了什么。为分层上下文加载而写
——扫描 20 个 ADR 的技能用此判断是否要读取完整决策。要具体：指明系统、
问题与所选方法。]

## Engine Compatibility
## 引擎兼容性

| Field | Value |
|-------|-------|
| **Engine** | [e.g. Godot 4.7] |
| **Domain** | [Physics / Rendering / UI / Audio / Navigation / Animation / Networking / Core / Input] |
| **Layer** | [Foundation / Core / Feature / Presentation] |
| **Knowledge Risk** | [LOW / MEDIUM / HIGH — from VERSION.md] |
| **References Consulted** | [List engine-reference docs read, e.g. `docs/engine-reference/godot/modules/physics.md`] |
| **Post-Cutoff APIs Used** | [Any APIs from post-LLM-cutoff versions this decision depends on, or "None"] |
| **Verification Required** | [Specific behaviours to test before shipping, or "None"] |

| 字段 | 值 |
|-------|-------|
| **引擎** | [例如 Godot 4.7] |
| **领域** | [物理 / 渲染 / UI / 音频 / 导航 / 动画 / 网络 / 核心 / 输入] |
| **层** | [基础 / 核心 / 功能 / 表现] |
| **知识风险** | [低 / 中 / 高 — 来自 VERSION.md] |
| **已查阅参考** | [列出已阅读的引擎参考文档，例如 `docs/engine-reference/godot/modules/physics.md`] |
| **使用的截止后 API** | [本决策依赖的任何 LLM 知识截止日期之后版本的 API，或"无"] |
| **需要的验证** | [发布前需测试的具体行为，或"无"] |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.
> **注意**：若知识风险为中或高，项目升级引擎版本时必须重新验证本 ADR。
> 将其标记为"已被取代"并编写新的 ADR。

> **`Layer` is the ADR's own layer, not the referencing epic's — and it is a
> different taxonomy from `Domain`.** Several sites branch on whether an ADR is
> *critical (Foundation-layer)*: `/create-stories`, `/create-epics`,
> `/architecture-decision`, `/story-readiness`, `/propagate-design-change` and
> `gate-pre-production.md`; a missing row counts as critical. At `standard`,
> `/create-stories` **stops** for a missing critical ADR and only **warns** for a
> non-critical one, so this row decides whether a run halts. Do not infer the
> layer from the referencing epic: a Foundation-layer ADR is commonly referenced
> by a Core-layer epic, which would give the wrong answer.
> **`Layer` 是 ADR 自身的层，而非引用它的史诗的层——并且它与 `Domain` 属于
> 不同的分类体系。** 多个位置会根据 ADR 是否为*关键（基础层）*进行分支：
> `/create-stories`、`/create-epics`、`/architecture-decision`、
> `/story-readiness`、`/propagate-design-change` 以及
> `gate-pre-production.md`；缺失该行会被视为关键。在 `standard` 下，
> `/create-stories` 对缺失的关键 ADR 会**停止**，对非关键 ADR 仅**警告**，
> 因此这一行决定一次运行是否中止。不要从引用它的史诗推断层：基础层 ADR
> 常被核心层史诗引用，那样会得出错误答案。
>
> The vocabulary is the same `Foundation / Core / Feature / Presentation` that
> epics and stories already carry — do not invent a fifth value, and do not
> reuse a `Domain` value here. `Domain` says *what part of the engine this
> touches*; `Layer` says *how early in the build it must exist*.
> 词汇与史诗和故事已使用的 `Foundation / Core / Feature / Presentation` 相同
> ——不要发明第五个值，也不要在此复用 `Domain` 的值。`Domain` 说明*这触及
> 引擎的哪个部分*；`Layer` 说明*它必须在构建的多早阶段存在*。

## ADR Dependencies
## ADR 依赖

| Field | Value |
|-------|-------|
| **Depends On** | [ADR-NNNN (must be Accepted before this can be implemented), or "None"] |
| **Enables** | [ADR-NNNN (this ADR unlocks that decision), or "None"] |
| **Blocks** | [Epic/Story name — cannot start until this ADR is Accepted, or "None"] |
| **Ordering Note** | [Any sequencing constraint that isn't captured above] |

| 字段 | 值 |
|-------|-------|
| **依赖于** | [ADR-NNNN（必须先被接受，本 ADR 才能实施），或"无"] |
| **使能** | [ADR-NNNN（本 ADR 解锁该决策），或"无"] |
| **阻塞** | [史诗/故事名称 — 在本 ADR 被接受前无法开始，或"无"] |
| **顺序说明** | [任何未在上述体现的排序约束] |

## Context
## 上下文

### Problem Statement
### 问题陈述
[What problem are we solving? Why does this decision need to be made now?]
[我们在解决什么问题？为何此决策需要现在做出？]

### Current State
### 当前状态
[How does the system work today? What is wrong with the current approach?]
[系统目前如何运作？当前方法有什么问题？]

### Constraints
### 约束
- [Technical constraints]
- [技术约束]
- [Timeline constraints]
- [时间线约束]
- [Resource constraints]
- [资源约束]
- [Compatibility requirements]
- [兼容性要求]

### Requirements
### 需求
- [Must support X]
- [必须支持 X]
- [Must perform within Y budget]
- [必须在 Y 预算内运行]
- [Must integrate with Z]
- [必须与 Z 集成]

## Decision
## 决策

[The specific technical decision made, described in enough detail for someone
to implement it.]
[所做出的具体技术决策，描述详细到足以让他人实现。]

### Architecture Diagram
### 架构图
[ASCII diagram or description of the system architecture this creates]
[本决策所产生的系统架构的 ASCII 图或描述]

### Key Interfaces
### 关键接口
[API contracts or interface definitions this decision creates]
[本决策创建的 API 契约或接口定义]

### Implementation Guidelines
### 实现指南
[Specific guidance for the programmer implementing this decision — the rules a
`/create-control-manifest` or `/dev-story` run should follow. State mandates as
"must / must never" so they extract cleanly.]
[为实施本决策的程序员提供的具体指导——`/create-control-manifest` 或
`/dev-story` 运行应遵循的规则。以"必须 / 绝不"陈述强制要求，以便清晰提取。]

## Alternatives Considered
## 考虑过的备选方案

### Alternative 1: [Name]
### 备选方案 1：[名称]
- **Description**: [How this would work]
- **描述**：[它将如何运作]
- **Pros**: [Advantages]
- **优点**：[优势]
- **Cons**: [Disadvantages]
- **缺点**：[劣势]
- **Estimated Effort**: [Relative effort compared to the chosen approach]
- **预估工作量**：[与所选方法相比的相对工作量]
- **Rejection Reason**: [Why this was not chosen]
- **否决原因**：[为何未被选择]

### Alternative 2: [Name]
### 备选方案 2：[名称]
- **Description**: [How this would work]
- **描述**：[它将如何运作]
- **Pros**: [Advantages]
- **优点**：[优势]
- **Cons**: [Disadvantages]
- **缺点**：[劣势]
- **Estimated Effort**: [Relative effort compared to the chosen approach]
- **预估工作量**：[与所选方法相比的相对工作量]
- **Rejection Reason**: [Why this was not chosen]
- **否决原因**：[为何未被选择]

## Consequences
## 后果

### Positive
### 正面
- [Good outcomes of this decision]
- [本决策的良好结果]

### Negative
### 负面
- [Trade-offs and costs accepted]
- [已接受的权衡与成本]

### Neutral
### 中性
- [Changes that are neither good nor bad, just different]
- [无所谓好坏、只是不同的变化]

## Risks
## 风险
- [Things that could go wrong]
- [可能出错的事项]
- [Mitigation for each risk]
- [每项风险的缓解措施]

## GDD Requirements Addressed
## 已覆盖的 GDD 需求

<!-- This section is MANDATORY. Every ADR must trace back to at least one GDD
     requirement, or explicitly state it is a foundational decision with no GDD
     dependency. Traceability is audited by /architecture-review. -->
<!-- 本节为强制内容。每个 ADR 都必须追溯到至少一项 GDD
     需求，或明确说明它是无 GDD 依赖的基础性决策。
     可追溯性由 /architecture-review 审计。 -->

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [system-name].md | [specific rule, formula, or performance constraint from that GDD] | [how this decision satisfies it] |

| GDD 系统 | 需求 | 本 ADR 如何满足它 |
|------------|-------------|--------------------------|
| [system-name].md | [来自该 GDD 的具体规则、公式或性能约束] | [本决策如何满足它] |

> If this is a foundational decision with no direct GDD dependency, write:
> "Foundational — no GDD requirement. Enables: [list what GDD systems this
> decision unlocks or constrains]"
> 若这是无直接 GDD 依赖的基础性决策，请写：
> "基础性 — 无 GDD 需求。使能：[列出本决策解锁或约束的 GDD 系统]"

## Performance Implications
## 性能影响
- **CPU**: [Expected impact]
- **CPU**：[预期影响]
- **Memory**: [Expected impact]
- **内存**：[预期影响]
- **Load Time**: [Expected impact]
- **加载时间**：[预期影响]
- **Network**: [Expected impact, if applicable]
- **网络**：[预期影响，如适用]

## Migration Plan
## 迁移计划
[If this changes existing code, how do we get from here to there?]
[若这会改变现有代码，我们如何从这里到达那里？]

**Rollback plan**: [How to revert if this decision proves wrong]
**回滚计划**：[若该决策被证明有误，如何回退]

## Validation Criteria
## 验证标准
[How will we know this decision was correct? What metrics or tests?]
[我们将如何知道该决策是正确的？用什么指标或测试？]

## Related
## 相关
- [Links to related ADRs — note if supersedes, contradicts, or depends on]
- [相关 ADR 链接 — 注明是否取代、矛盾或依赖]
- [Links to related design documents]
- [相关设计文档链接]
- [Links to relevant code files once implemented]
- [实现后相关代码文件链接]
