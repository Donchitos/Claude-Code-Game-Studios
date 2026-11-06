# Hook: post-sprint-retrospective
# 钩子：post-sprint-retrospective

## Trigger
## 触发条件

Manual trigger at the end of each sprint (typically invoked by the producer
agent or the human developer).
在每个冲刺结束时手动触发（通常由 producer 智能体或人类开发者调用）。

## Purpose
## 目的

Automatically generates a retrospective starting point by analyzing the sprint
data: what was planned vs completed, velocity changes, bug trends, and common
blockers. This is not a git hook but a workflow hook invoked through the
`producer` agent.
通过分析冲刺数据自动生成回顾的起点：计划与完成的对比、速率变化、缺陷趋势和常见阻碍项。这不是 git 钩子，而是通过 `producer` 智能体调用的工作流钩子。

## Implementation
## 实现

This is a workflow hook, not a git hook. It is invoked by running:
这是工作流钩子，而不是 git 钩子。通过运行以下命令调用：

```
@producer Generate sprint retrospective for Sprint [N]
```

The producer agent should:
producer 智能体应：

1. **Read the sprint plan** from `production/sprints/sprint-[N].md`
1. 从 `production/sprints/sprint-[N].md` **读取冲刺计划**
2. **Calculate metrics**:
2. **计算指标**：
   - Tasks planned vs completed
   - 计划任务与完成任务对比
   - Story points planned vs completed (if used)
   - 计划故事点与完成故事点对比（如使用）
   - Carryover items from previous sprint
   - 上一冲刺的结转项
   - New tasks added mid-sprint
   - 冲刺中途新增的任务
   - Average task completion time
   - 平均任务完成时间
3. **Analyze patterns**:
3. **分析模式**：
   - Most common blockers
   - 最常见的阻碍项
   - Which agent/area had the most incomplete work
   - 哪个智能体/领域有最多的未完成工作
   - Which estimates were most inaccurate
   - 哪些估算最不准确
4. **Generate the retrospective**:
4. **生成回顾**：

```markdown
# Sprint [N] Retrospective

## Metrics
| Metric | Value |
|--------|-------|
| Tasks Planned | [N] |
| Tasks Completed | [N] |
| Completion Rate | [X%] |
| Carryover from Previous | [N] |
| New Tasks Added | [N] |
| Bugs Found | [N] |
| Bugs Fixed | [N] |

## Velocity Trend
[Sprint N-2]: [X] | [Sprint N-1]: [Y] | [Sprint N]: [Z]
Trend: [Improving / Stable / Declining]

## What Went Well
- [Automatically detected: tasks completed ahead of estimate]
- [Facilitator adds team observations]

## What Went Poorly
- [Automatically detected: tasks that were carried over or cut]
- [Automatically detected: areas with significant estimate overruns]
- [Facilitator adds team observations]

## Blockers
| Blocker | Frequency | Resolution Time | Prevention |
|---------|-----------|----------------|-----------|

## Action Items for Next Sprint
| # | Action | Owner | Priority |
|---|--------|-------|----------|

## Estimation Accuracy
| Area | Avg Planned | Avg Actual | Accuracy |
|------|------------|-----------|----------|
```

5. **Save** to `production/sprints/sprint-[N]-retro.md`
5. **保存**到 `production/sprints/sprint-[N]-retro.md`
