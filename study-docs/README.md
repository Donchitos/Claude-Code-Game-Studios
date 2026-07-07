# Claude Code 智能体编排学习文档

> 以 [Claude Code Game Studios](file:///workspace/README.md) 项目为范例，带你从零理解 Claude Code 的智能体编排（Agent Orchestration）。

---

## 这套文档是给谁的

给**小白**。你不需要懂游戏开发，也不需要写过智能体。只要你：

- 大致知道 Claude Code 是一个能在终端里读写文件、跑命令的 AI 编程助手；
- 想搞明白"一个 AI 怎么变成一支团队"这件事。

我们会用这个项目当"活教材"——它把一个 Claude Code 会话编排成了 **49 个智能体、73 个技能、12 个钩子、11 条规则**的虚拟游戏工作室。这是目前公开范围内最完整、最工程化的 Claude Code 编排范例之一。

---

## 为什么用这个项目学编排

市面上大部分 Claude Code 教程停留在"写个好 prompt"。这个项目不一样，它示范了**真正的工程化编排**：

| 维度 | 这个项目示范了什么 | 你能学到什么 |
|------|---------------------|--------------|
| **角色分工** | 49 个智能体分三层（总监/主管/专家） | 如何用 subagent 做职责隔离 |
| **流程编排** | 7 阶段流水线（概念→发布） | 如何用 skill 串成可控的工作流 |
| **自动守卫** | 12 个 hook 在提交/推送/会话事件自动校验 | 如何让 AI"不敢"犯错 |
| **规则约束** | 11 条按路径生效的编码规则 | 如何让规则只在该管的地方管 |
| **人在环中** | Question→Options→Decision→Draft→Approval | 如何让 AI 提议而非独断 |
| **上下文管理** | 文件即记忆 + 增量写入 + 压缩恢复 | 如何让长会话不"失忆" |

---

## 文档地图

建议按顺序读，每篇都自包含。

| # | 文档 | 核心问题 | 关键概念 |
|---|------|----------|----------|
| 01 | [项目概览](file:///workspace/study-docs/01-项目概览.md) | 这是什么？为什么值得学？ | 49/73/12/11、工作室隐喻 |
| 02 | [Claude Code 基础概念](file:///workspace/study-docs/02-Claude-Code基础概念.md) | Claude Code 的"配置文件"长啥样？ | `CLAUDE.md`、`.claude/`、`settings.json` |
| 03 | [Agent 编排体系](file:///workspace/study-docs/03-Agent编排体系.md) | 49 个智能体怎么分工合作？ | 三层层级、委派规则、升级路径 |
| 04 | [Skill 技能系统](file:///workspace/study-docs/04-Skill技能系统.md) | `/dev-story` 这种命令怎么来的？ | slash 命令、7 阶段流水线、路由 |
| 05 | [Hook 自动化守卫](file:///workspace/study-docs/05-Hook自动化守卫.md) | 怎么让 AI 自动守规矩？ | 8 类钩子、退出码语义 |
| 06 | [Rules 路径规则](file:///workspace/study-docs/06-Rules路径规则.md) | 规则怎么"按目录"生效？ | `paths` frontmatter |
| 07 | [协作协议与人在环](file:///workspace/study-docs/07-协作协议与人在环.md) | AI 怎么提议而不越权？ | 五步协作、`AskUserQuestion` |
| 08 | [上下文管理艺术](file:///workspace/study-docs/08-上下文管理艺术.md) | 长会话怎么不失忆？ | 文件即记忆、增量写入、压缩 |
| 09 | [实战案例剖析](file:///workspace/study-docs/09-实战案例剖析.md) | 一个功能从设计到上线全流程 | `/dev-story`、`/team-combat` |
| 10 | [学习路径与练习](file:///workspace/study-docs/10-学习路径与练习.md) | 我该怎么练？ | 阶梯任务、自检清单 |
| 11 | [CLAUDE.md 编写指导](file:///workspace/study-docs/11-CLAUDE.md编写指导.md) | CLAUDE.md 怎么写？ | 定位、`@` 引用、分层、反模式 |
| 12 | [从零编排智能体协作](file:///workspace/study-docs/12-从零编排智能体协作.md) | 主会话怎么触发智能体？工作室怎么从零搭？ | `Task` 工具、三层规则源、调用流程、8 步搭建、9 种编排模式 |
| 13 | [术语对照表](file:///workspace/study-docs/13-术语对照表.md) | TD-ENGINE-RISK 是什么？ADR Approve 是什么？ | 门禁 ID 体系、游戏开发流程术语、智能体编排术语、25 个门禁速查 |
| 14 | [四大机制协作工作流](file:///workspace/study-docs/14-四大机制协作工作流.md) | Agent/skill/门禁/hook 怎么配合？大模型怎么触发它们？ | 用 /dev-story 例子串起四机制、触发方式、返回原节点、流程定位 |
| 18 | [会话状态保存与选项澄清机制](file:///workspace/study-docs/18-会话状态保存与选项澄清机制.md) | 中断后怎么接着干？选项 + 澄清循环怎么转？ | active.md 状态环、4 个 hook、Question→Options→Approval 循环、Explain→Capture 三步法 |
| 19 | [Claude Code 工具系统详解](file:///workspace/study-docs/19-Claude-Code工具系统详解.md) | AskUserQuestion 怎么用？还有哪些工具？ | 工具 vs Skill vs Hook vs Rules、AskUserQuestion 三步法、Read/Write/Edit/Glob/Grep/Bash/Task/TodoWrite/Web 工具、5 种组合模式 |

---

## 一句话总览

> **Claude Code 编排 = 用 `CLAUDE.md` 定方向 + 用 `agents/` 分角色 + 用 `skills/` 串流程 + 用 `hooks/` 守底线 + 用 `rules/` 管细节 + 用文件当记忆。**

这套文档就是把这六个部件一个一个拆给你看。

---

## 阅读约定

- **代码引用**：所有提到项目里文件的地方都是可点击链接，形如 [creative-director.md](file:///workspace/.claude/agents/creative-director.md)，点开就能看原文。
- **类比**：每讲一个抽象概念，都会配一个生活化的类比，帮你建立直觉。
- **"小测验"**：部分章节末尾有 1-2 个小问题，答案就在当节，帮你自检。
- **"动手"**：标着"动手"的小节是建议你亲自去项目里翻一翻的地方。

开始吧 → [01 项目概览](file:///workspace/study-docs/01-项目概览.md)
