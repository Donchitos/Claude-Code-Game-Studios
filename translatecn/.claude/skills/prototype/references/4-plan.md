# /prototype — Phase 4: Plan the Prototype
# /prototype — 第四阶段：规划原型

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/prototype` 的一部分。`SKILL.md` 说明了何时阅读本文件；它已解析的设置，以及其后各标题下的规则，在此同样适用。

## Phase 4: Plan the Prototype
## 第四阶段：规划原型

Define in 3–5 bullet points the minimum viable prototype:

用 3–5 个要点定义最小可行原型：

- What is the falsifiable hypothesis?
- 可证伪的假设是什么？
- What is the riskiest assumption — and how does this prototype test it first?
- 风险最大的假设是什么——这个原型如何首先测试它？
- What is the absolute minimum needed to answer the question?
- 回答这个问题所需的绝对最低限度是什么？
- What is explicitly cut? (menus, save systems, error handling, polish, architecture — all of it)
- 明确砍掉了什么？（菜单、存档系统、错误处理、打磨、架构——全部砍掉）

**Scope constraint:** A concept prototype tests ONE mechanic — not the whole game.
If scope covers more than one mechanic, cut it down. When in doubt, cut more.

**范围约束：** 概念原型只测试一个机制——不是整个游戏。如果范围覆盖了不止一个机制，就削减它。拿不准时，砍得更多。

Present this plan to the user before building. Get confirmation before proceeding.
Name the checkpoint file in that confirmation: "May I record this plan in
`production/session-state/active.md`?"

在构建之前把这个计划呈现给用户。在继续之前取得确认。在确认中指明检查点文件："我可以把这个计划记录到 `production/session-state/active.md` 吗？"

Once confirmed, write a session checkpoint to `production/session-state/active.md`
(create `production/session-state/` if it does not exist). Include: concept name,
hypothesis, path chosen, scope bullet points, and current phase ("Phase 5 —
Implement"). This lets the next session resume without starting over if the session
ends mid-build — especially important for multi-day Engine path work.

一旦确认，就向 `production/session-state/active.md` 写入会话检查点（如果 `production/session-state/` 不存在，则创建它）。包含：概念名称、假设、所选路径、范围要点，以及当前阶段（"Phase 5 — Implement"）。这样即使会话在构建中途结束，下一次会话也能接着做而无需从头开始——这对需要多天的 Engine 路径工作尤为重要。

---
