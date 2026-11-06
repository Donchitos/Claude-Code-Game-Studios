# Agent Teams (experimental — opt-in)
# 智能体团队（实验性 — 需选择加入）

> On-demand reference. Demoted out of `coordination-rules.md` (an always-loaded
> CLAUDE.md import) in v1.1 — read this when actually considering a team, not
> on every turn.
> 按需参考。在 v1.1 中从 `coordination-rules.md`（一个始终加载的 CLAUDE.md 导入）中降级 — 在实际考虑团队时阅读，而不是每一轮都读。

Multiple independent Claude Code *sessions* running simultaneously, coordinated
via a shared task list. Each session has its own context window and token budget.
Requires the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` environment variable.
多个独立的 Claude Code *会话* 同时运行，通过共享任务列表进行协调。每个会话都有自己的上下文窗口和 token 预算。需要 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 环境变量。

## Use agent teams when
## 何时使用智能体团队

- Work spans multiple subsystems that will not touch the same files
- 工作跨越多个子系统，且它们不会触碰相同的文件
- Each workstream would take >30 minutes and benefits from true parallelism
- 每个工作流需要超过 30 分钟，并能从真正的并行中受益
- A senior agent (technical-director, producer) needs to coordinate 3+ specialist
  sessions working on different epics simultaneously
- 高级智能体（technical-director、producer）需要同时协调 3 个以上处理不同史诗的专家会话

## Do not use agent teams when
## 何时不要使用智能体团队

- One session's output is required as input for another (use sequential subagents)
- 一个会话的输出是另一个会话的输入（使用顺序子智能体）
- The task fits in a single session's context (use subagents instead)
- 任务能放进单个会话的上下文（改为使用子智能体）
- Cost is a concern — each team member burns tokens independently
- 成本是顾虑 — 每个团队成员独立消耗 token

## Current status
## 当前状态

Opt-in via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Document first usage here
when adopted.
通过 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 选择加入。采用时在此记录首次使用情况。
