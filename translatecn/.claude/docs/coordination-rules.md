# Agent Coordination Rules
# 智能体协调规则

1. **Vertical Delegation**: Leadership agents delegate to department leads, who
   delegate to specialists. Never skip a tier for complex decisions.
1. **垂直委派**：领导智能体委派给部门主管，部门主管再委派给专家。对于复杂决策，绝不要跳过层级。
2. **Horizontal Consultation**: Agents at the same tier may consult each other
   but must not make binding decisions outside their domain.
2. **横向咨询**：同一层级的智能体可以相互咨询，但不得做出其领域之外的约束性决策。
3. **Conflict Resolution**: When two agents disagree, escalate to the shared
   parent. If no shared parent, escalate to `creative-director` for design
   conflicts or `technical-director` for technical conflicts.
3. **冲突解决**：当两个智能体意见不一致时，升级到共同上级。如果没有共同上级，设计冲突升级到 `creative-director`，技术冲突升级到 `technical-director`。
4. **Change Propagation**: When a design change affects multiple domains, the
   `producer` agent coordinates the propagation.
4. **变更传播**：当设计变更影响多个领域时，`producer` 智能体协调传播。
5. **No Unilateral Cross-Domain Changes**: An agent must never modify files
   outside its designated directories without explicit delegation.
5. **不得单方面跨领域更改**：智能体绝不得在未获明确委派的情况下修改其指定目录之外的文件。
6. **Read Design Docs by Section**: A brief names the sections an agent needs
   by heading. Find a heading in a GDD, ADR or the art bible with the Grep
   tool (`^#`, content mode) and Read that range with offset and limit; read a doc
   whole only when the task needs all of it, and say why. `validate-read.sh`
   refuses a whole-file read of a doc over 40 KB.
6. **按章节阅读设计文档**：简报以标题指明智能体需要的章节。使用 Grep 工具（`^#`，内容模式）在 GDD、ADR 或美术圣经中找到标题，并用 offset 和 limit 读取该范围；仅当任务需要整份文档时才完整阅读，并说明原因。`validate-read.sh` 会拒绝整文件读取超过 40 KB 的文档。
7. **Nothing Goes Upstream**: Never file, open or comment on an issue or pull
   request in an engine, plugin or vendor repository, even when asked. Write a
   draft (`/bug-report` drafts only) and the user submits it.
7. **不向上游提交任何内容**：绝不在引擎、插件或供应商仓库中提交、开启或评论 issue 或拉取请求，即使被要求也不行。编写草稿（`/bug-report` 只生成草稿），由用户提交。

## Model Tier Assignment
## 模型层级分配

Read `.claude/docs/model-tiers.md` on demand. It carries the tier table, the
per-skill assignments and the authoring rule.
按需阅读 `.claude/docs/model-tiers.md`。它包含层级表、逐技能分配和编写规则。

**Key point:** whether a skill's `model:` is used
depends on how the skill starts. Typed as `/skill-name`: yes, except a `haiku`
pin in auto mode. Started by Claude through the Skill tool: no. Never tell a
user a `haiku` skill saves money; an `opus` skill typed in a Sonnet session
costs more. The agent-side `model:` is a different mechanism, and is applied.
**要点：** 技能的 `model:` 是否被使用取决于技能如何启动。以 `/skill-name` 输入：是，但自动模式下的 `haiku` 固定除外。由 Claude 通过 Skill 工具启动：否。绝不要告诉用户 `haiku` 技能能省钱；在 Sonnet 会话中输入的 `opus` 技能花费更多。智能体侧的 `model:` 是另一种机制，且会被应用。

## Subagents vs Agent Teams
## 子智能体与智能体团队

This project uses two distinct multi-agent patterns:
本项目使用两种不同的多智能体模式：

### Subagents (current, always active)
### 子智能体（当前，始终活动）
Spawned via the `Agent` tool within a single Claude Code session. Used by all
`team-*` skills and orchestration skills. Subagents share the session's
permission context, run sequentially or in parallel within the session, and
return results to the parent.
在单个 Claude Code 会话中通过 `Agent` 工具生成。所有 `team-*` 技能和编排技能都使用它。子智能体共享会话的权限上下文，在会话内顺序或并行运行，并将结果返回给父级。

**When to spawn in parallel**: If two subagents' inputs are independent (neither
needs the other's output to begin), spawn both `Agent` calls simultaneously
rather than waiting. Example: `/review-all-gdds` **Phase 2** (consistency) and
**Phase 3** (design theory) are independent — spawn both at the same time.
Phase 1 loads the GDDs and both depend on it, so it is the one phase here that
must NOT be parallelised.
**何时并行生成**：如果两个子智能体的输入相互独立（两者都不需要对方的输出即可开始），请同时生成两个 `Agent` 调用，而不是等待。示例：`/review-all-gdds` 的 **Phase 2**（一致性）和 **Phase 3**（设计理论）相互独立 — 同时生成两者。Phase 1 加载 GDD，而两者都依赖它，因此它是这里唯一绝不能并行化的阶段。

### Agent Teams (experimental — opt-in)
### 智能体团队（实验性 — 需选择加入）
Multiple independent Claude Code *sessions* coordinated via a shared task list.
Opt-in only — read `.claude/docs/agent-teams.md` on demand before proposing one.
多个独立的 Claude Code *会话*通过共享任务列表协调。仅限选择加入 — 在提议之前按需阅读 `.claude/docs/agent-teams.md`。

## Parallel Task Protocol
## 并行任务协议

When an orchestration skill spawns multiple independent agents:
当编排技能生成多个独立智能体时：

1. Issue all independent `Agent` calls before waiting for any result
1. 在等待任何结果之前发出所有独立的 `Agent` 调用
2. Collect all results before proceeding to dependent phases
2. 在进入依赖阶段之前收集所有结果
3. If any agent is BLOCKED, surface it immediately — do not silently skip
3. 如果任何智能体处于 BLOCKED，立即呈现 — 不要静默跳过
4. Always produce a partial report if some agents complete and others block
4. 如果部分智能体完成而其他被阻塞，始终生成部分报告
