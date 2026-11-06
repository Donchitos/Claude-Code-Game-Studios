# 02 · Claude Code 基础概念

在拆解 49 个智能体怎么协作之前，我们先认识 Claude Code 的"配置零件"。这一篇是后续所有章节的地基。

---

## Claude Code 是什么

Claude Code 是 Anthropic 出的**命令行 AI 编程助手**。你在终端敲 `claude`，它就开一个会话，能读写文件、跑命令、上网搜、调用各种工具。

但裸的 Claude Code 只是一个"全能但无结构的助手"。要把它变成"一支有分工的团队"，需要靠**配置文件**告诉它：你是谁、能用什么、该怎么做、不能做什么。

这些配置文件几乎都集中在一个地方：**`.claude/` 目录**，外加一个项目根目录的 `CLAUDE.md`。

---

## 两大配置入口

### 1. `CLAUDE.md` —— 项目章程

位置：[CLAUDE.md](file:///workspace/CLAUDE.md)

这是 Claude Code 启动时**第一个读**的项目级文件。你可以理解为"公司章程"——它告诉 AI 这个项目是什么、技术栈是什么、要遵守哪些总原则。

看这个项目的 `CLAUDE.md` 节选：

```markdown
# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 49 coordinated Claude Code subagents.

## Technology Stack
- **Engine**: [CHOOSE: Godot 4 / Unity / Unreal Engine 5]
- **Language**: [CHOOSE: GDScript / C# / C++ / Blueprint]
- **Version Control**: Git with trunk-based development

## Coordination Rules
@.claude/docs/coordination-rules.md

## Collaboration Protocol
**User-driven collaboration, not autonomous execution.**
Every task follows: Question -> Options -> Decision -> Draft -> Approval
```

**两个关键语法**：

- `@路径` —— **引用语法**。`@.claude/docs/coordination-rules.md` 表示"把那个文件的内容也加载进来"。这样 `CLAUDE.md` 可以保持精简，把细节拆到子文件。
- 普通文本 —— 直接是给 AI 的指令。

**类比**：`CLAUDE.md` 就像公司章程，开篇定调子（"我们是 49 个智能体的工作室"），然后用 `@` 引用各部门的规章制度。

### 2. `.claude/settings.json` —— 机器配置

位置：[.claude/settings.json](file:///workspace/.claude/settings.json)

这是 JSON 格式的"机器可读配置"，管三件事：**状态栏、权限、钩子**。

```json
{
  "statusLine": { "command": "bash .claude/statusline.sh" },
  "permissions": {
    "allow": ["Bash(git status*)", "Bash(git diff*)", ...],
    "deny":  ["Bash(rm -rf *)", "Bash(git push --force*)", "Read(**/.env*)"]
  },
  "hooks": { ... }
}
```

- **`statusLine`**：底部状态栏显示什么（上下文用量、模型、当前阶段）。
- **`permissions.allow`**：自动放行的安全操作（`git status`、跑测试）。
- **`permissions.deny`**：永远禁止的危险操作（`rm -rf`、强推、读 `.env`）。
- **`hooks`**：在哪些事件触发哪些脚本。详见 [05 Hook 自动化守卫](file:///workspace/study-docs/05-Hook自动化守卫.md)。

**类比**：`settings.json` 是公司的"门禁系统 + 安检规则"。白名单的进，黑名单的拦，特定时刻自动巡检。

---

## `.claude/` 目录的六大部件

这是整个编排的核心。逐一认识：

### 部件 1：`agents/` —— 员工档案

每个 `.md` 文件 = 一个智能体。文件名就是智能体名。比如 [creative-director.md](file:///workspace/.claude/agents/creative-director.md) 定义了"创意总监"。

每个档案由两部分组成：

```markdown
---
name: creative-director
description: "The Creative Director is the highest-level creative authority..."
tools: Read, Glob, Grep, Write, Edit, WebSearch
model: opus
maxTurns: 30
disallowedTools: Bash
skills: [brainstorm, design-review]
---

You are the Creative Director for an indie game project...
（下面是给这个智能体的详细人设和职责说明）
```

- **YAML frontmatter**（`---` 之间的部分）：机器配置。名字、能用哪些工具、用哪个模型、最多几轮、禁用什么、关联哪些技能。
- **正文**：人设和职责。这是给 AI 读的"岗位说明书"。

**关键设计**：每个智能体的 `tools` 字段是**最小权限原则**的体现。`creative-director` 禁用了 `Bash`——创意总监不该跑终端命令，那是程序员和运维的活。

### 部件 2：`skills/` —— 标准作业流程（SOP）

每个子目录 = 一个 `/slash` 命令。比如 [skills/dev-story/SKILL.md](file:///workspace/.claude/skills/dev-story/SKILL.md) 定义了 `/dev-story` 命令。

```markdown
---
name: dev-story
description: "Read a story file and implement it..."
argument-hint: "[story-path]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, Task, AskUserQuestion
model: sonnet
---

# Dev Story
This skill bridges planning and code...
## Phase 1: Find the Story
## Phase 2: Load Full Context
## Phase 3: Route to the Right Programmer
...
```

- **`user-invocable: true`**：用户能直接敲 `/dev-story` 触发。
- **`allowed-tools`**：这个技能能用哪些工具（含 `Task` = 能派生子智能体）。
- **正文**：分阶段的执行流程。这是"作业指导书"。

**类比**：`agents/` 是"员工档案"，`skills/` 是"SOP 手册"。员工按 SOP 干活，SOP 调度员工。

### 部件 3：`hooks/` —— 自动质检脚本

每个 `.sh` 文件 = 一个钩子脚本。在特定事件自动触发。比如 [validate-commit.sh](file:///workspace/.claude/hooks/validate-commit.sh) 在每次 `git commit` 前自动检查。

钩子靠**退出码**说话：

- `exit 0` = 放行
- `exit 2` = 阻止（stderr 内容会反馈给 AI）
- 其他 = 非阻塞警告

详见 [05 Hook 自动化守卫](file:///workspace/study-docs/05-Hook自动化守卫.md)。

### 部件 4：`rules/` —— 路径作用域规范

每个 `.md` 文件 = 一条规则，靠 frontmatter 的 `paths` 字段决定**只在哪些路径生效**。比如 [gameplay-code.md](file:///workspace/.claude/rules/gameplay-code.md)：

```markdown
---
paths:
  - "src/gameplay/**"
---

# Gameplay Code Rules
- ALL gameplay values MUST come from external config/data files, NEVER hardcoded
- Use delta time for ALL time-dependent calculations
- NO direct references to UI code — use events/signals
...
```

**关键设计**：规则**只在该管的地方管**。写 `src/gameplay/` 下的代码时强制数据驱动；写 `prototypes/` 下的代码时规则放松（原型就该快糙猛）。详见 [06 Rules 路径规则](file:///workspace/study-docs/06-Rules路径规则.md)。

### 部件 5：`docs/` —— 内部参考文档

不是给用户读的，是给 AI 和 skill 读的"参考资料"。重要的几个：

- [workflow-catalog.yaml](file:///workspace/.claude/docs/workflow-catalog.yaml)：7 阶段流水线定义，`/help` 命令读它来判断"你在哪一步"。
- [agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md)：智能体协作地图，谁能委派谁、冲突找谁。
- [coordination-rules.md](file:///workspace/.claude/docs/coordination-rules.md)：协作规则（垂直委派、横向咨询、冲突升级）。
- [context-management.md](file:///workspace/.claude/docs/context-management.md)：上下文管理策略。
- `templates/`：41 个文档模板（GDD、ADR、Sprint 计划等）。

### 部件 6：`statusline.sh` —— 状态栏脚本

底部状态栏显示什么。会显示上下文用量百分比、当前模型、项目阶段、当前在做的 Epic/Feature/Task 面包屑。

---

## 四件套怎么协同（核心图）

```
用户敲 /dev-story [path]
        │
        ▼
   skills/dev-story/SKILL.md          ← SOP：分 7 个 Phase 执行
        │
        │ Phase 3: 路由到 gameplay-programmer
        ▼
   Task(subagent_type=gameplay-programmer)
        │
        ▼
   agents/gameplay-programmer.md      ← 员工档案：人设 + 工具权限
        │
        │ 写代码到 src/gameplay/xxx
        ▼
   rules/gameplay-code.md 自动生效    ← 路径规则：必须数据驱动
        │
        │ 用户敲 git commit
        ▼
   hooks/validate-commit.sh 自动跑    ← 质检：检查硬编码、JSON、章节
        │
        ▼
   exit 0 放行 / exit 2 阻止
```

**这就是编排的本质**：skill 调度 agent，agent 受 rules 约束，hooks 在关键节点守门，全部由 `CLAUDE.md` 和 `settings.json` 统一配置。

---

## 模型分层（一个常被忽略的细节）

这个项目还示范了**按任务难度选模型**，来自 [coordination-rules.md](file:///workspace/.claude/docs/coordination-rules.md)：

| 层 | 模型 | 用途 | 成本 |
|----|------|------|------|
| **Haiku** | `claude-haiku-4-5` | 只读状态检查、格式化、简单查询 | 低 |
| **Sonnet** | `claude-sonnet-4-6` | 实现、设计撰写、单系统分析（默认） | 中 |
| **Opus** | `claude-opus-4-6` | 多文档综合、高风险门禁、跨系统评审 | 高 |

比如 `/help`、`/sprint-status` 这种只读命令用 Haiku（省钱），`/review-all-gdds`、`/gate-check` 这种高风险综合判断用 Opus（保质量），其余默认 Sonnet。

**这是编排的进阶智慧**：不是所有任务都需要最贵的模型。把简单任务下放给便宜模型，是规模化编排必备的成本意识。

---

## 小测验

**Q1**：`CLAUDE.md` 里的 `@.claude/docs/coordination-rules.md` 是什么意思？
> **A**：引用语法。表示把那个文件的内容也加载进上下文。这样 `CLAUDE.md` 保持精简，细节拆到子文件。

**Q2**：一个智能体的 `tools: Read, Glob, Grep, Write, Edit, WebSearch` 和 `disallowedTools: Bash` 是什么关系？
> **A**：`tools` 是白名单（能用这些），`disallowedTools` 是显式黑名单（额外禁掉 Bash）。两者叠加 = 这个智能体能读能写能搜网，但不能跑终端命令。这是最小权限原则。

**Q3**：`skills/` 和 `agents/` 的关系是什么？
> **A**：`skills/` 是 SOP（标准作业流程），`agents/` 是员工档案。skill 调度 agent，agent 按 skill 的流程干活。一个 skill 可以调度多个 agent，一个 agent 可以被多个 skill 调用。

---

## 动手

1. 打开 [.claude/settings.json](file:///workspace/.claude/settings.json)，找到 `permissions.deny`，看看哪些操作被永远禁止。
2. 打开 [.claude/agents/qa-tester.md](file:///workspace/.claude/agents/qa-tester.md)，对比 [creative-director.md](file:///workspace/.claude/agents/creative-director.md)，看看"测试员"和"创意总监"的 `tools` 和 `model` 有什么不同，想想为什么。

下一篇 → [03 Agent 编排体系](file:///workspace/study-docs/03-Agent编排体系.md)
