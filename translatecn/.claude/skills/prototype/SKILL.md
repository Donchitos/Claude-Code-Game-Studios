---
name: prototype
description: "Concept prototype before GDDs — throwaway HTML, Engine or Paper build, PROCEED/PIVOT/KILL/NOT ASSESSED. After /brainstorm and /setup-engine."
argument-hint: "[concept-description] [--path html|engine|paper] [--review full|lean|solo] [--spike]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/prototype/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: prototype
description: "GDD 之前的概原型 — 一次性 HTML、引擎或纸面构建，PROCEED/PIVOT/KILL/NOT ASSESSED。在 /brainstorm 与 /setup-engine 之后使用。"
argument-hint: "[concept-description] [--path html|engine|paper] [--review full|lean|solo] [--spike]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/prototype/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow`

Resolved above — use as-is; `--review` overrides `review_mode` for this run. No
block → defaults in `.claude/docs/config-resolution.md`.

已在上方解析 — 直接使用；`--review` 覆盖本次运行的 `review_mode`。无配置块
→ 使用 `.claude/docs/config-resolution.md` 中的默认值。

# Prototype

## Purpose

This is the **concept prototype** — a fast, throwaway build that answers one question:
*"Is this core idea actually fun to interact with?"*

# 原型

## 目的

这是**概念原型** — 一个快速、一次性的构建，回答一个问题：
*"这个核心想法与它互动起来真的有趣吗？"*

**Default use** — run right after `/brainstorm` and `/setup-engine`, before writing
GDDs or architecture docs. Its verdict determines whether the concept is worth the
investment of full design documentation.

**默认用途** — 紧接在 `/brainstorm` 与 `/setup-engine` 之后运行，在撰写
GDD 或架构文档之前。它的判定决定该概念是否值得
投入完整的设计文档。

**Mid-production?** You can also run this at any stage to test a specific mechanic,
design change, or technical question. Pass `--spike` to activate spike mode: a
lightweight ~4-hour build with no GDD prerequisites and no phase gate implications.

**生产中期？** 你也可以在任何阶段运行它来测试某个具体机制、
设计变更或技术问题。传入 `--spike` 启用 spike 模式：一个
轻量级约 4 小时的构建，没有 GDD 前提条件，也不涉及阶段门禁。

**Already have GDDs and architecture complete?** To validate the full game loop
before committing to Production, run `/vertical-slice` instead.

**已有完整的 GDD 与架构？** 要在投入生产前验证完整游戏循环，
改为运行 `/vertical-slice`。

---

## Phase 1: Define the Question

**Read `references/1-question.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 阶段 1：定义问题

**现在读取 `references/1-question.md` 并遵循它** — 本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 2: Load Concept Context

**Read `references/2-load-context.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 阶段 2：加载概念上下文

**现在读取 `references/2-load-context.md` 并遵循它** — 本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 3: Choose the Prototype Path

**Read `references/3-choose-path.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 阶段 3：选择原型路径

**现在读取 `references/3-choose-path.md` 并遵循它** — 本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 4: Plan the Prototype

**Read `references/4-plan.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 阶段 4：规划原型

**现在读取 `references/4-plan.md` 并遵循它** — 本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 5: Implement

**Read `references/5-implement.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 阶段 5：实现

**现在读取 `references/5-implement.md` 并遵循它** — 本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 6: Playtest Debrief

**Read `references/6-debrief.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 阶段 6：试玩复盘

**现在读取 `references/6-debrief.md` 并遵循它** — 本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 7: Generate Prototype Report

**Read `references/7-report.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 阶段 7：生成原型报告

**现在读取 `references/7-report.md` 并遵循它** — 本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 8: Creative Director Review

**Read `references/8-cd-review.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 阶段 8：创意总监评审

**现在读取 `references/8-cd-review.md` 并遵循它** — 本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Phase 9: Summary and Next Steps

**Read `references/9-summary.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 阶段 9：总结与后续步骤

**现在读取 `references/9-summary.md` 并遵循它** — 本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

## Spike Mode

**Triggered by:** `--spike` flag OR "Mid-production spike" entry choice in Phase 1.

**Read `references/spike-mode.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Spike 模式

**触发方式：** `--spike` 标志，或阶段 1 中的 "Mid-production spike" 条目选择。

**现在读取 `references/spike-mode.md` 并遵循它** — 本阶段的步骤在那个文件里，不在这里。如果对话在本阶段被压缩或恢复，请再次读取它。

### Important Constraints

- Prototype code must NEVER import from production source files
- Production code must NEVER import from prototype directories
- If the recommendation is PROCEED, production implementation is written from
  scratch — prototype code is never refactored into production
- Total effort is hard-capped at 1 day (concept prototypes test one mechanic)
- Test ONE mechanic — if scope grows, stop and simplify the question
- No polish. No menus, no game over, no music, no UI unless it IS the mechanic
- If stuck after 2 hours of engine iteration, reframe the question or switch paths
- **3 PIVOT iterations → force a KILL decision.** If this is the third time the
  same concept has produced a PIVOT verdict, the concept likely doesn't work.
  Ask: "Is this the right idea, or am I in the sunk cost trap?" A new concept
  prototyped fresh will almost always beat a fourth iteration of a struggling one.
- Building 2-3 different concept variants and picking the best one is a healthier
  strategy than iterating one concept to death. Natural selection between prototypes
  beats willpower.
- **Networked/multiplayer games:** A local prototype cannot validate the feel of a
  networked mechanic. Latency fundamentally changes how combat, movement, and
  prediction feel — a prototype running at 0ms local will feel entirely different at
  80ms network delay. Use a local prototype to validate that the mechanic is
  *interesting*. Do not use it as evidence that it *feels good* under real network
  conditions. Network feel requires real peers or simulated latency (e.g., throttle
  tools, network condition simulators).

### 重要约束

- 原型代码绝不能从生产源码文件导入
- 生产代码绝不能从原型目录导入
- 如果建议是 PROCEED，生产实现从头编写
  — 原型代码绝不重构进生产
- 总投入硬性上限为 1 天（概念原型只测试一个机制）
- 只测试一个机制 — 如果范围变大，停止并简化问题
- 不抛光。没有菜单、没有游戏结束、没有音乐、没有 UI，除非它本身**就是**那个机制
- 如果在 2 小时的引擎迭代后卡住，重新表述问题或切换路径
- **3 次 PIVOT 迭代 → 强制做出 KILL 决定。** 如果同一概念第三次
  产出 PIVOT 判定，该概念很可能不成立。
  问："这是正确的想法吗，还是我陷入了沉没成本陷阱？"一个全新的概念
  重新原型几乎总能胜过同一个挣扎概念的第 4 次迭代。
- 构建 2-3 个不同的概念变体并挑选最好的一个，是比把一个概念迭代到死
  更健康的策略。原型之间的自然选择
  胜过意志力。
- **联网/多人游戏：** 本地原型无法验证
  联网机制的体感。延迟从根本上改变战斗、移动和
  预测的体感 — 一个在 0ms 本地运行的原型在
  80ms 网络延迟下会感觉完全不同。使用本地原型验证该机制是
  *有趣的*。不要用它作为在真实网络
  条件下它*体感良好*的证据。网络体感需要真实对等端或模拟延迟（例如
  限速工具、网络状况模拟器）。
