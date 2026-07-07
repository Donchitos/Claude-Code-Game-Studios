# 19 · Claude Code 工具系统详解 —— 以 AskUserQuestion 为核心

这一篇回答两个问题：

1. **Claude Code 的 `AskUserQuestion` 工具到底是什么？怎么用？设计思想和技术原理是什么？**
2. **除了 `AskUserQuestion`，Claude Code 还有哪些工具？分别用在什么场景？**

读完这篇你能：

- 看懂项目里 70+ 个 skill / 16 个 agent 的 `allowed-tools` 字段为什么那么写
- 自己写 skill 时知道每个决策点该用哪个工具
- 把 `AskUserQuestion` 的 "Explain→Capture" 模式用到自己的项目里
- 理解 Claude Code "工具调用 + 正文循环" 的工程模型

---

## 第一部分：工具系统总览

### 1. 什么是 Claude Code 工具

Claude Code 不只是"聊天 + 文件读写"。它给大模型暴露了一组**结构化工具**（tools），每个工具有：

- **名字**（如 `Read`、`AskUserQuestion`）
- **参数 schema**（必填、类型、约束）
- **执行体**（由 Claude Code 引擎实现，不是大模型生成）
- **返回值**（结构化数据，进到大模型上下文）

大模型决定**调什么工具、传什么参数**，Claude Code 引擎**执行**并把结果塞回上下文，大模型再基于结果决定下一步。这就是 Anthropic 的 **tool use** 机制。

```
大模型：我决定调 AskUserQuestion，参数是 {...}
       ↓
Claude Code 引擎：收到，执行工具（弹 UI、收集用户输入）
       ↓
引擎：用户选了 [A]，把 [A] 返回给大模型
       ↓
大模型：基于 [A] 起草下一节……
```

**关键区分**：工具不是 prompt。Prompt 是"建议大模型怎么做"，工具是"大模型只能这么做才能产生副作用"。大模型可以"想"读文件，但不调 `Read` 工具就真读不到。

---

### 2. 工具 vs Skill vs Hook vs Rules —— 别搞混

这四个概念在 Claude Code 里分工明确，初学者最容易混。一张表理清：

| 概念 | 本质 | 谁写 | 谁触发 | 能否绕过 | 例子 |
|------|------|------|--------|----------|------|
| **Tool** | 引擎提供的原子能力 | Anthropic | 大模型主动调 | 能（不调就没有这个能力） | `Read`、`Write`、`AskUserQuestion` |
| **Skill** | 一段 prompt 模板 + 元数据 | 你（项目作者） | 用户敲 `/命令` 或大模型主动 | 能（大模型可以不调） | `/design-system`、`/brainstorm` |
| **Hook** | 事件触发的 shell 脚本 | 你 | 引擎在事件点自动跑 | **不能**（除非删 settings.json） | `session-start.sh`、`validate-commit.sh` |
| **Rules** | 路径相关的编码约束 | 你 | 大模型读到时"自觉遵守" | 能（probability-driven） | `.claude/rules/typescript.md` |

**一句话**：**工具是能力，skill 是流程，hook 是强制，rules 是风格**。

`AskUserQuestion` 是**工具**——它给大模型一个"结构化问问题"的能力。但"什么时候问、问什么、用户答完怎么办"是 **skill 正文**规定的。工具不提供流程，流程靠 skill 拼。

---

### 3. 项目里实际用到的工具清单

看项目里 73 个 skill 和 16 个 agent 的 `allowed-tools` 字段，把所有出现过的工具列出来：

| 工具 | 类别 | 作用 | 出现频率 |
|------|------|------|----------|
| `Read` | 文件 | 读文件 | 几乎所有 skill |
| `Write` | 文件 | 写新文件 | 几乎所有 skill |
| `Edit` | 文件 | 改已有文件 | 大部分 skill |
| `Glob` | 搜索 | 按文件名模式找文件 | 大部分 skill |
| `Grep` | 搜索 | 按内容找文件 | 大部分 skill |
| `Bash` | 执行 | 跑 shell 命令 | 涉及构建/测试的 skill |
| `Task` | 委派 | 启动子 agent | team-* 系列、复杂 skill |
| `AskUserQuestion` | 交互 | 结构化问问题 | 所有"人在环"skill |
| `TodoWrite` | 规划 | 写任务清单 | 长流程 skill |
| `WebSearch` | 网络 | 搜网页 | `brainstorm`、`setup-engine` |
| `WebFetch` | 网络 | 抓网页内容 | `setup-engine` |

下面分章节详解，**重点讲 `AskUserQuestion`**（用户的核心问题），其它工具简要带过。

---

## 第二部分：AskUserQuestion 详解

### 1. 工具是什么

`AskUserQuestion` 是 Claude Code 提供的一个**结构化交互工具**。大模型调它时，Claude Code 引擎会在终端弹出一个**可选 UI**：

- 列出 2-4 个预设选项（用户可点选）
- 自带一个 **"Other"** 出口（用户可输入自由文本）
- 收集用户选择后返回给大模型

**和纯文本提问的区别**：

| 方式 | 用户体验 | 大模型解析 | 适合场景 |
|------|----------|------------|----------|
| 纯文本提问 "选 A/B/C？" | 用户手动敲 "A" | 大模型要解析自然语言，可能误解 | 开放式问题 |
| `AskUserQuestion` | 用户点选项或点 Other 输入 | 结构化返回，无歧义 | 收敛式决策 |

---

### 2. 参数 schema

工具接受一个 `questions` 数组，每个 question 包含：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `question` | string | ✅ | 完整问题文本 |
| `header` | string | ✅ | 短标签（≤12 字符），显示为 chip/tag |
| `options` | array | ✅ | 2-4 个选项 |
| `multiSelect` | bool | ❌ | 默认 `false`，设 `true` 允许多选 |
| `options[].label` | string | ✅ | 1-5 词的短标签 |
| `options[].description` | string | ✅ | 1 句话说明 / 取舍 |

**约束**：

- 每个 question 2-4 个 option（不能多不能少）
- 不需要手动加 "Other" —— 工具**自动提供**
- `header` ≤ 12 字符
- 一次调用可批量问 1-4 个独立问题

---

### 3. 在项目里的真实使用示例

下面三个示例全部从项目源码抽取，逐个讲解。

#### 示例 A：单选决策（最常见）

来源：[.claude/skills/brainstorm/SKILL.md](file:///workspace/.claude/skills/brainstorm/SKILL.md#L112-128)

```
AskUserQuestion(
  prompt: "Which concept resonates with you? You can pick one, combine elements, or ask for fresh directions.",
  options: [
    "Concept 1 — [Title]",
    "Concept 2 — [Title]",
    "Concept 3 — [Title]",
    "Combine elements across concepts",
    "Generate fresh directions"
  ]
)
```

**讲解**：

- **三个真实选项** + **两个"逃离选项"**
- "Combine elements" 和 "Generate fresh directions" 是预设的"用户不满意"出口
- 即使这五个都不合用户意，用户还能点 Other 输入自由文本
- 这就是"选项 ↔ 澄清循环"的入口（详见 [18 篇](file:///workspace/study-docs/18-会话状态保存与选项澄清机制.md) 第二部分）

#### 示例 B：批量问多个独立问题

来源：[docs/COLLABORATIVE-DESIGN-PRINCIPLE.md](file:///workspace/docs/COLLABORATIVE-DESIGN-PRINCIPLE.md#L377-398)

```
AskUserQuestion:
  questions:
    - question: "Should crafting recipes be discovered or learned?"
      header: "Discovery"
      options:
        - label: "Experimentation"
          description: "Players discover by trying combinations — high mystery"
        - label: "NPC/Book Learning"
          description: "Recipes taught explicitly — accessible, lower mystery"
        - label: "Tiered Hybrid"
          description: "Basic recipes learned, advanced discovered — best of both"
    - question: "How punishing should failed crafts be?"
      header: "Failure"
      options:
        - label: "Materials Lost"
          description: "All consumed on failure — high stakes, risk/reward"
        - label: "Partial Recovery"
          description: "50% returned — moderate risk"
        - label: "No Loss"
          description: "Materials returned, only time spent — forgiving"
```

**讲解**：

- **一次调用问两个独立问题** —— 减少 round-trip
- 每个问题有 3 个选项，用户每个都可选 / 输 Other
- `header` 是 "Discovery" / "Failure"（短标签显示在 UI 上）
- `description` 一句话讲取舍 —— 用户不用读长文就能决策

#### 示例 C：入职分流（路径选择）

来源：[.claude/skills/start/SKILL.md](file:///workspace/.claude/skills/start/SKILL.md#L36-43)

```
- Prompt: "Welcome to Claude Code Game Studios! Before I suggest anything,
  I'd like to understand where you're starting from.
  Where are you at with your game idea right now?"

- Options:
  - A) No idea yet — I don't have a game concept at all. I want to explore and figure out what to make.
  - B) Vague idea — I have a rough theme, feeling, or genre in mind (e.g., "something with space" or "a cozy farming game") but nothing concrete.
  - C) Clear concept — I know the core idea — genre, basic mechanics, maybe a pitch sentence — but haven't formalized it into documents yet.
  - D) Existing work — I already have design docs, prototypes, code, or significant planning done. I want to organize or continue the work.
```

**讲解**：

- **4 个互斥路径**，每个对应后续不同 skill
- 选项描述长一些没关系 —— 这是入职分流，用户需要清楚每个选项的含义
- 用户选 A → 走 `/brainstorm`；选 C → 走 `/setup-engine`；选 D → 走 `/adopt`
- 用户也可以点 Other 说"我介于 B 和 C 之间" —— skill 正文规定了这种澄清怎么处理

---

### 4. 什么时候该用、什么时候不该用

[COLLABORATIVE-DESIGN-PRINCIPLE.md](file:///workspace/docs/COLLABORATIVE-DESIGN-PRINCIPLE.md#L350-364) 给了明确清单：

#### ✅ 该用：

- **2-4 个收敛选项的决策点**（"用方案 A/B/C？"）
- **初始澄清问题**，答案有约束（"游戏类型：动作 / 策略 / 解谜？"）
- **批量问 ≤4 个独立问题**（一次调用减少 round-trip）
- **下一步选择**（"先写公式还是先写规则？"）
- **架构决策**（"静态工具类 / 单例 / MonoBehavior？"）
- **战略选择**（"简化范围 / 推迟 deadline / 砍功能？"）

#### ❌ 不该用：

- **开放式探索问题**（"你对 roguelike 的什么感兴趣？"）—— 用纯文本
- **单一 yes/no 确认**（"可以写文件了吗？"）—— 用纯文本就够，弹 UI 反而打断节奏
- **Task 子 agent 内部** —— 子 agent 可能没有这个工具，调了会报错

---

### 5. Explain → Capture 三步法（核心设计模式）

这是项目里最重要的工具使用模式，写在 [COLLABORATIVE-DESIGN-PRINCIPLE.md](file:///workspace/docs/COLLABORATIVE-DESIGN-PRINCIPLE.md#L338-348)。

**为什么需要这个模式**：`AskUserQuestion` 的 `label` 只能 1-5 词，`description` 只能 1 句话，装不下完整推理。所以分两步：

```
┌─────────────────────────────────────────────────┐
│  第 1 步：Explain（在对话文本里）                │
│  写完整分析：pros/cons、理论引用、参考游戏、     │
│  和 pillar 的对齐、推荐理由                     │
│  ↓ 这是"为什么"，可以很长                       │
├─────────────────────────────────────────────────┤
│  第 2 步：Capture（用 AskUserQuestion）          │
│  选项 label 短（1-5 词）                        │
│  选项 description 1 句话                        │
│  ↓ 这是"选什么"，让用户快速点                   │
├─────────────────────────────────────────────────┤
│  第 3 步：循环                                   │
│  用户选 → 起草 → AskUserQuestion 问批准          │
│  → 用户改 → 重新 Explain → 重新 Capture          │
│  → 用户批准 → 写文件                            │
└─────────────────────────────────────────────────┘
```

**完整示例（在 design-system skill 里）**：

```
[Agent 在对话文本里写完整分析 —— Explain]

"战斗系统有三种风格可选：

A. 实时动作战斗
   pros: 紧张感强、有打击反馈、符合 'Pillar: 沉浸感'
   cons: 平衡难度高、需要复杂动画
   参考游戏: Hades、Diablo
   理论: Mihaly Csikszentmihalyi 的 flow theory 支持

B. 回合制战术
   pros: 思考深度高、易平衡
   cons: 节奏慢、不符合 'Pillar: 沉浸感'
   参考游戏: Into the Breach
   理论: Heuristic Evaluation 的 visibility 原则

C. 即时带暂停
   pros: 兼顾动作和策略
   cons: 实现复杂、UI 设计难
   参考游戏: Baldur's Gate 3
   理论: 支持 'Pillar: 沉浸感' 和 'Pillar: 策略性'

基于你的 pillar '沉浸感'，我推荐 A。"

[Agent 在同一个响应里调 AskUserQuestion —— Capture]

AskUserQuestion:
  questions:
    - question: "Which combat style fits your vision?"
      header: "Combat Style"
      options:
        - label: "Real-Time Action (Recommended)"
          description: "Hades-style — immersive, hard to balance"
        - label: "Turn-Based Tactical"
          description: "Into the Breach-style — deep, slow"
        - label: "Real-Time with Pause"
          description: "BG3-style — flexible, complex"
```

**关键**：草稿（Explain）和 widget（Capture）**必须在同一个响应里**。这是 [design-system SKILL.md](file:///workspace/.claude/skills/design-system/SKILL.md) 明确规定的 protocol，违反会导致用户面对空白提示符没路径走。

---

### 6. 设计思想与技术原理

#### 设计思想一：把"决策权"还给用户

大模型有"自动做完"的本能 —— 给它任务，它倾向于一路干到底。`AskUserQuestion` 强制在决策点停下来，让用户拍板。

**这不是技术问题，是产品哲学**：

> AI 提议，人类决策。AI 永远不能代替用户做"产品方向"类的决策。

#### 设计思想二：结构化降低歧义

纯文本问"选 A/B/C？"，用户可能回 "a"、"A"、"第一个"、"我用 A 吧"…… 大模型要解析，可能误解。

`AskUserQuestion` 返回结构化数据（用户选了哪个 option 对象，或 Other 的文本），**零歧义**。

#### 设计思想三：预留"逃离口"

工具自带 Other 出口。这承认了一件事：

> 预设选项永远覆盖不全用户的真实想法。给用户一个"我说点别的"的口子，比让他被迫选最接近的更尊重。

但工具只提供"出口"，"用户走 Other 后怎么办"是 skill 正文的责任 —— 这就是 18 篇讲的"选项 ↔ 澄清循环"。

#### 技术原理：tool use 协议

底层是 Anthropic 的 tool use 协议：

```
1. Claude Code 引擎启动时，把可用工具的 schema 注入系统 prompt
2. 大模型看到 schema，知道"有 AskUserQuestion 这个工具，参数是 {...}"
3. 大模型决定调用 → 输出 tool_use block（包含工具名 + 参数）
4. Claude Code 引擎检测到 tool_use → 执行工具（弹 UI / 收集输入）
5. 工具执行完 → 引擎把结果作为 tool_result block 注入回上下文
6. 大模型看到 tool_result → 基于结果决定下一步
```

**关键**：

- 大模型**只生成"调什么 + 参数"**，不执行工具
- 工具的执行体在 **Claude Code 引擎**里，大模型无法篡改
- 这就是为什么 skill 的 `allowed-tools` 字段能限制大模型能力 —— 引擎只注入被允许的工具 schema

---

### 7. `allowed-tools` 字段：精细控制能力

每个 skill 和 agent 的 frontmatter 里有 `allowed-tools` 字段：

```yaml
---
name: design-system
argument-hint: "<system-name> [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion, TodoWrite
model: sonnet
---
```

**含义**：这个 skill 跑起来时，大模型**只能用这 8 个工具**，其它工具（如 `Bash`、`WebSearch`）的 schema 不会被注入，大模型看不到、调不了。

**为什么这么设计**：最小权限原则。一个设计 skill 不需要跑 shell 命令，所以不给 `Bash`；不需要上网，所以不给 `WebSearch`。这降低了 skill 误用的风险。

**项目里的精细控制示例**：

| Skill | allowed-tools | 为什么 |
|-------|---------------|--------|
| `start`（入职） | `Read, Glob, Grep, Write, AskUserQuestion` | 入职只需要问问题 + 写一个配置文件，不给 Edit/Bash |
| `sprint-status`（看状态） | `Read, Glob, Grep` | 只读不写，最安全 |
| `prototype`（做原型） | `Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion` | 要写代码、跑构建、可能调子 agent |
| `setup-engine`（装引擎） | `..., WebSearch, WebFetch, ...` | 要查引擎文档，所以给网络工具 |
| `test-flakiness` | `Read, Glob, Grep, Write, Edit, Bash` | 不需要问用户，没给 AskUserQuestion |

---

## 第三部分：其它工具详解

### 1. 文件三件套：Read / Write / Edit

#### `Read` —— 读文件

**参数**：`file_path`（必填）、`offset`、`limit`（用于大文件分段读）

**特点**：

- 返回带行号的格式（`cat -n` 风格）
- 大文件可分段读，避免一次塞太多进上下文
- **必须用绝对路径**

**项目用法**：几乎所有 skill 第一步都是 `Read` 上下文文件。例：[design-system SKILL.md](file:///workspace/.claude/skills/design-system/SKILL.md) 启动时读概念文档、系统索引、依赖 GDD。

#### `Write` —— 写新文件（或整体覆盖）

**参数**：`file_path`、`content`

**特点**：

- 写新文件或**整体覆盖**已有文件
- **如果是已存在文件，必须先 `Read` 一次**，否则工具会报错（防误改）
- 不要用来做小修改 —— 用 `Edit`

**项目用法**：创建 GDD 骨架、写 active.md 首次内容、写 ADR。

#### `Edit` —— 改已有文件（精确替换）

**参数**：`file_path`、`old_string`、`new_string`、`replace_all`（可选）

**特点**：

- 精确字符串替换，不是正则
- `old_string` 必须在文件里**唯一**，否则报错（除非 `replace_all: true`）
- 同样要求先 `Read` 过文件
- 改大文件的小片段比 `Write` 省得多

**项目用法**：增量写入 GDD 章节、勾掉 active.md 的 checklist 项、改 frontmatter。

**关键设计**：项目要求"每节批准即写入"靠的是 `Edit`。骨架用 `Write` 一次写完，之后每节内容用 `Edit` 把 `[To be designed]` 占位符替换成真实内容。这是"增量写入"的底层操作。

---

### 2. 搜索双胞胎：Glob / Grep

#### `Glob` —— 按文件名找

**参数**：`pattern`（如 `**/*.ts`、`design/gdd/*.md`）、`path`（可选）

**特点**：

- 只匹配**文件名**，不看内容
- 速度快，适合"找哪些文件"
- 返回文件路径列表，按修改时间排序

**项目用法**：[design-system SKILL.md](file:///workspace/.claude/skills/design-system/SKILL.md) 用 `Glob` 检查 `production/session-state/active.md` 是否存在；用 `Glob design/gdd/*.md` 列出所有 GDD。

#### `Grep` —— 按内容找

**参数**：`pattern`（正则）、`path`、`glob`（过滤文件类型）、`output_mode`（`files_with_matches` / `content` / `count`）、`-A`/`-B`/`-C`（上下文行）

**特点**：

- 基于 ripgrep，支持完整正则
- 三种输出模式：只文件名 / 含匹配行 / 计数
- 可按 glob 过滤（`*.md`、`*.ts`）

**项目用法**：[pre-compact.sh](file:///workspace/.claude/hooks/pre-compact.sh) 用 `grep -n -E "TODO|WIP|PLACEHOLDER|[TO BE|[TBD]"` 扫 WIP 标记（脚本里直接 grep，但 skill 里会用 `Grep` 工具）；skill 里用 `Grep` 找某决策在哪些 GDD 提到过。

**Glob vs Grep**：

| 需求 | 用 |
|------|----|
| "项目里有哪些 .md 文件？" | `Glob` |
| "哪些文件提到了 combat？" | `Grep` |
| "design/gdd/ 下的文件列表" | `Glob` |
| "active.md 里 'Section' 出现在哪几行" | `Grep` |

---

### 3. 执行工具：Bash

**参数**：`command`、`cwd`（可选）、`blocking`（默认 true）

**特点**：

- 跑任意 shell 命令
- 大模型最强大也最危险的工具
- 项目里通过 `settings.json` 的 `permissions.allow` / `deny` 精细控制（如允许 `git status*`、禁止 `rm -rf *`）

**项目用法**：

- `prototype` skill 跑 `npm test` / `godot --build`
- `test-flakiness` 跑测试多次收集 flaky 数据
- `gate-check` 跑 lint / type check / test

**安全设计**：[.claude/settings.json](file:///workspace/.claude/settings.json) 里：

```json
"permissions": {
  "allow": [
    "Bash(git status*)",
    "Bash(git diff*)",
    "Bash(python -m pytest*)"
  ],
  "deny": [
    "Bash(rm -rf *)",
    "Bash(git push --force*)",
    "Bash(git reset --hard*)",
    "Bash(sudo *)"
  ]
}
```

allow 白名单 + deny 黑名单，双重保护。

---

### 4. 委派工具：Task

**参数**：`subagent_type`（如 `general-purpose-task`、`search`）、`description`、`query`（任务描述）

**特点**：

- 启动一个**子 agent** 处理子任务
- 子 agent 有独立上下文窗口，不占主会话
- 子 agent 完成后返回**单条结果**给主会话

**项目用法**：team-* 系列 skill 用 `Task` 启动多个专家 agent 并行工作。例：

```
[team-combat skill]
  ↓
Task(subagent_type=general-purpose-task, description="game-designer analysis",
     query="分析战斗系统的三种方案...")
  ↓
[子 agent 跑完，返回分析文本]
  ↓
主会话拿到分析，用 AskUserQuestion 让用户选
```

**关键设计**：子 agent **不能调 `AskUserQuestion`**（[COLLABORATIVE-DESIGN-PRINCIPLE.md](file:///workspace/docs/COLLABORATIVE-DESIGN-PRINCIPLE.md#L363) 明确说 "Don't use it when running as a Task subagent"）。子 agent 只做分析、起草，决策权永远在主会话。这是"人在环"的硬保证。

---

### 5. 规划工具：TodoWrite

**参数**：`todos`（数组，每项含 `id`、`content`、`status`、`priority`）、`merge`

**特点**：

- 写一个结构化任务清单
- 每项有 `pending` / `in_progress` / `completed` 三态
- 同一时刻**只能有一个 in_progress**

**项目用法**：长流程 skill（如 [team-level](file:///workspace/.claude/skills/team-level/SKILL.md)、[map-systems](file:///workspace/.claude/skills/map-systems/SKILL.md)）用 `TodoWrite` 把流程拆成可追踪的步骤。

**和 active.md 的区别**：

| 维度 | TodoWrite | active.md |
|------|-----------|-----------|
| 存在哪 | 大模型上下文（短期） | 磁盘文件（持久） |
| 跨会话 | 不保留 | 保留 |
| 用途 | 当前会话内的任务追踪 | 跨会话的状态恢复 |
| 谁看 | 大模型自己 | 大模型 + 用户 + hook |

**关键**：TodoWrite 是"短期记忆"，active.md 是"长期记忆"。压缩时 TodoWrite 可能丢，active.md 不会。所以重要进度必须**同时**写进 active.md。

---

### 6. 网络工具：WebSearch / WebFetch

#### `WebSearch`

**参数**：`query`、`num`（结果数）、`lr`（语言）

**项目用法**：[brainstorm](file:///workspace/.claude/skills/brainstorm/SKILL.md) 搜参考游戏；[setup-engine](file:///workspace/.claude/skills/setup-engine/SKILL.md) 查引擎最新文档。

#### `WebFetch`

**参数**：`url`

**特点**：抓指定 URL 内容，转 markdown 给大模型。**只读**，无副作用。

**项目用法**：抓引擎官方文档页、GitHub README。

**注意**：[setup-engine SKILL.md](file:///workspace/.claude/skills/setup-engine/SKILL.md) 的 `allowed-tools` 同时给了 `WebSearch` 和 `WebFetch`，但大多数 skill 没给 —— 因为大部分工作不需要上网，最小权限原则。

---

## 第四部分：工具组合模式

单个工具是积木，**组合**才有威力。下面是项目里反复出现的几种组合模式。

### 模式 1：读 → 问 → 写（最常见）

```
Read (读上下文)
  ↓
AskUserQuestion (问决策)
  ↓
[用户选]
  ↓
Edit (写决策到文件)
  ↓
更新 active.md
```

这是 design-system / brainstorm / start 等 skill 的主循环。每个决策点都走一遍。

### 模式 2：Explain → Capture → Approve

```
[在对话文本里写完整分析]   ← Explain
  ↓
AskUserQuestion (出选项)   ← Capture
  ↓
[用户选 A]
  ↓
[起草内容]
  ↓
AskUserQuestion (Approve / Make changes / Start over)
  ↓
[用户 Approve]
  ↓
Edit (写入文件)
```

这是 18 篇讲的"选项 ↔ 澄清循环"的完整流程。

### 模式 3：搜 → 读 → 决策

```
Glob (找文件)
  ↓
Grep (在文件里找关键词)
  ↓
Read (读相关段落)
  ↓
AskUserQuestion (基于读到的内容出选项)
```

例：design-system 启动时 `Glob design/gdd/*.md` → `Grep` 找依赖关系 → `Read` 读依赖 GDD → 基于这些出"先做哪个系统"的选项。

### 模式 4：委派 → 收集 → 决策

```
Task (启动子 agent 做分析)
  ↓
Task (启动另一个子 agent 做另一视角分析)
  ↓
[两个子 agent 都返回]
  ↓
[主会话综合分析]
  ↓
AskUserQuestion (出选项让用户选)
```

这是 team-* 系列 skill 的核心模式。子 agent 干活，主会话决策。

### 模式 5：批处理问 → 一次性收集

```
[Explain 多个独立维度]
  ↓
AskUserQuestion (批量问 4 个问题)
  ↓
[用户一次答完 4 个]
  ↓
[基于 4 个答案综合起草]
```

减少 round-trip。例：crafting 系统设计时一次问"发现方式 + 失败惩罚 + 配方数量 + 学习曲线"4 个独立维度。

---

## 第五部分：使用教程 —— 怎么在自己的 skill 里用

### 1. 第一步：在 skill frontmatter 声明

```yaml
---
name: my-skill
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion
model: sonnet
---
```

**关键**：只有声明在 `allowed-tools` 里的工具，大模型才能调。漏写 = 大模型看不到这个工具。

### 2. 第二步：在 skill 正文规定"何时调"

光给工具不够，要在正文写明调用点：

```markdown
## Phase 2: Choose Architecture

After reading the existing code, present 3 architecture options with full
pros/cons analysis in conversation text.

Then use AskUserQuestion:
- question: "Which architecture fits the project?"
- header: "Architecture"
- options:
  - label: "Singleton (Recommended)"
    description: "..."
  - label: "Static Utility"
    description: "..."
  - label: "Service Class"
    description: "..."

Wait for user's choice. Do NOT proceed until they respond.
```

**关键**：用 "use AskUserQuestion" / "Wait for user's choice" 这种**指令性语言**。否则大模型可能在对话里问纯文本。

### 3. 第三步：写循环退出条件

```markdown
After user picks, draft the architecture document.

Then use AskUserQuestion again:
- question: "Approve this architecture doc?"
- options:
  - "Approve — write to file"
  - "Make changes — describe what to fix"
  - "Start over"

If user picks "Approve": use Edit to write to file, then proceed to Phase 3.
If user picks "Make changes": apply changes, then ask approval again.
If user picks "Start over": restart Phase 2.

Repeat until user picks "Approve".
```

**关键**：每个循环都要写**退出条件**（"Repeat until user picks Approve"）。

### 4. 第四步：处理 Other 输入

```markdown
If user picks "Other" and types custom input:
1. Acknowledge their input
2. Restate it in your own words to confirm understanding
3. Use AskUserQuestion:
   - question: "Did I understand correctly?"
   - options: ["Yes, that's right", "Close, but more details", "No, let me rephrase"]
4. If confirmed: regenerate options based on their input
5. If not: ask them to rephrase
```

**关键**：**收到 Other 后先复述确认，再重新出选项**。这是 18 篇讲的"澄清 → 复述 → 重出选项"循环。

### 5. 第五步：用 Explain → Capture

不要把完整分析塞进 `AskUserQuestion` 的 description。description 装不下，用户也读不快。

```markdown
## Pattern: Explain then Capture

When presenting options:

1. FIRST write full analysis in conversation text:
   - Pros/cons for each option
   - References to theory, examples, pillars
   - Your recommendation with reasoning

2. THEN call AskUserQuestion with:
   - Short labels (1-5 words)
   - 1-sentence descriptions
   - "(Recommended)" on your preferred option

The analysis lives in the conversation; the widget captures the decision.
```

---

## 第六部分：常见误区与避坑

### 坑 1：把分析塞进 description

**错**：

```
- label: "Real-Time Action"
  description: "Hades-style real-time combat with high immersion,
  strong feedback, but hard to balance and requires complex animation.
  Aligns with Pillar: Immersion. References: Hades, Diablo.
  Theory: Flow theory by Csikszentmihalyi."
```

**对**：把这段写进对话文本，description 只留 `"Hades-style — immersive, hard to balance"`。

### 坑 2：忘了写 allowed-tools

**症状**：skill 跑起来，大模型说"我没有 AskUserQuestion 工具"。

**原因**：frontmatter 漏了 `AskUserQuestion`。

**避坑**：每个 skill 写完先检查 `allowed-tools` 是否包含所有用到的工具。

### 坑 3：在子 agent 里调 AskUserQuestion

**症状**：子 agent 报错 "tool not available"。

**原因**：`Task` 启动的子 agent 默认没有 `AskUserQuestion`（[COLLABORATIVE-DESIGN-PRINCIPLE.md](file:///workspace/docs/COLLABORATIVE-DESIGN-PRINCIPLE.md#L363) 明确禁止）。

**避坑**：子 agent 只做分析、起草。决策由主会话做，主会话调 `AskUserQuestion`。

### 坑 4：选项超过 4 个

**症状**：工具调用失败 "Invalid tool parameters"。

**原因**：每个 question 最多 4 个 option。

**避坑**：超过 4 个时合并相近选项，或拆成两个 question。

### 坑 5：单一 yes/no 也用 AskUserQuestion

**症状**：用户觉得每个小事都弹 UI，节奏被打断。

**避坑**：单一确认（"可以写文件吗？"）用纯文本。`AskUserQuestion` 留给"2-4 个有意义的取舍"的决策点。

### 坑 6：忘了写 "Wait for user's choice"

**症状**：大模型调完 `AskUserQuestion` 后自己接着往下走，不等用户答。

**原因**：skill 正文没写"Wait"。

**避坑**：每个 `AskUserQuestion` 调用点后面都写 "Wait for user's response. Do not proceed until they answer."

### 坑 7：把 TodoWrite 当 active.md

**症状**：会话压缩后任务清单丢了，进度也丢了。

**原因**：误以为 TodoWrite 是持久化存储。

**避坑**：TodoWrite 是会话内追踪，重要进度必须**同时**写进 active.md。

---

## 第七部分：工具速查表

| 工具 | 一句话 | 关键约束 | 何时用 |
|------|--------|----------|--------|
| `Read` | 读文件 | 绝对路径；大文件用 offset/limit | 任何需要看文件内容的场景 |
| `Write` | 写新文件或整体覆盖 | 已存在文件须先 Read | 创建骨架、写新文件 |
| `Edit` | 精确替换 | old_string 必须唯一 | 改已有文件的小片段 |
| `Glob` | 按文件名找 | 不看内容 | "有哪些 .md 文件" |
| `Grep` | 按内容找 | 支持正则 | "哪些文件提到 combat" |
| `Bash` | 跑 shell | 受 permissions 控制 | 构建、测试、git 操作 |
| `Task` | 启动子 agent | 子 agent 无 AskUserQuestion | 委派独立子任务 |
| `AskUserQuestion` | 结构化问问题 | 2-4 选项/问，1-4 问/次 | 收敛式决策点 |
| `TodoWrite` | 写任务清单 | 同时只能 1 个 in_progress | 长流程任务追踪 |
| `WebSearch` | 搜网页 | 返回摘要 + 链接 | 查参考、查文档 |
| `WebFetch` | 抓网页 | 只读，无副作用 | 读特定 URL 内容 |

---

## 附录：关键源码索引

| 文件 | 看什么 |
|------|--------|
| [docs/COLLABORATIVE-DESIGN-PRINCIPLE.md](file:///workspace/docs/COLLABORATIVE-DESIGN-PRINCIPLE.md#L332-434) | AskUserQuestion 的 Explain→Capture 模式 + 三个完整示例 |
| [.claude/skills/brainstorm/SKILL.md](file:///workspace/.claude/skills/brainstorm/SKILL.md#L112-128) | 概念选择的"逃离选项"用法 |
| [.claude/skills/start/SKILL.md](file:///workspace/.claude/skills/start/SKILL.md#L36-43) | 入职分流的 4 选项路径选择 |
| [.claude/skills/design-system/SKILL.md](file:///workspace/.claude/skills/design-system/SKILL.md) | 章节批准循环 + allowed-tools 实例 |
| [.claude/settings.json](file:///workspace/.claude/settings.json) | permissions.allow/deny 控制 Bash 权限 |
| [18-会话状态保存与选项澄清机制.md](file:///workspace/study-docs/18-会话状态保存与选项澄清机制.md) | AskUserQuestion 配合 skill 正文构成"选项 ↔ 澄清循环" |

---

## 小测验

1. `AskUserQuestion` 工具的 "Other" 出口是项目自己实现的还是工具自带的？
   <details><summary>答案</summary>
   工具自带。Claude Code 的 AskUserQuestion 自动在每个 question 后提供 "Other" 入口，用户可输入自由文本。项目不需要在 options 里手动加 "Other"。但"用户走 Other 后怎么处理"是 skill 正文的责任，工具只负责收集输入。
   </details>

2. 为什么 `Explain → Capture` 要分两步，不能把分析塞进 description？
   <details><summary>答案</summary>
   description 只能 1 句话，装不下完整分析（pros/cons、参考游戏、pillar 对齐、理论引用）。硬塞会让 UI 不可读。所以把分析写进对话文本（Explain），UI 只放短选项（Capture）。两者在同一响应里，用户既能看到完整推理，又能快速点选。
   </details>

3. skill 的 `allowed-tools` 字段漏写 `AskUserQuestion` 会怎样？
   <details><summary>答案</summary>
   大模型看不到这个工具的 schema，无法调用。即使 skill 正文写了"use AskUserQuestion"，大模型也只会 fallback 到纯文本提问。所以写完 skill 要检查 allowed-tools 包含所有用到的工具。
   </details>

4. 子 agent（用 `Task` 启动的）能调 `AskUserQuestion` 吗？为什么？
   <details><summary>答案</summary>
   不能。COLLABORATIVE-DESIGN-PRINCIPLE 明确规定 "Don't use it when running as a Task subagent"。设计意图是：子 agent 只做分析和起草，决策权永远在主会话。主会话拿到子 agent 的分析后，自己调 AskUserQuestion 让用户决策。这是"人在环"的硬保证。
   </details>

5. `TodoWrite` 和 `active.md` 都能记任务，区别是什么？
   <details><summary>答案</summary>
   TodoWrite 在大模型上下文里（短期），不跨会话，压缩可能丢。active.md 是磁盘文件（持久），跨会话保留。TodoWrite 适合当前会话内的步骤追踪，active.md 适合跨会话的状态恢复。重要进度必须同时写进 active.md。
   </details>

6. `Edit` 工具的 `old_string` 不唯一会怎样？
   <details><summary>答案</summary>
   工具报错，拒绝执行。这是防误改设计 —— 如果 old_string 在文件里出现多次，工具不知道改哪个。解决方法：提供更多上下文让 old_string 唯一，或用 `replace_all: true` 改所有出现。
   </details>

7. 为什么大部分 skill 的 allowed-tools 不给 `WebSearch`？
   <details><summary>答案</summary>
   最小权限原则。大部分工作（设计 GDD、写代码、跑测试）不需要上网。只给确实需要的 skill（brainstorm 查参考游戏、setup-engine 查引擎文档）。这降低了 skill 误用网络、引入不可控信息的风险。
   </details>

8. **`AskUserQuestion` 适合问"你对 roguelike 的什么感兴趣？"吗？为什么？**
   <details><summary>答案</summary>
   不适合。这是开放式探索问题，没有 2-4 个收敛选项。硬塞选项会限制用户思路。这种问题用纯文本提问更好，让用户自由表达。AskUserQuestion 留给"有明确收敛选项的决策点"。
   </details>
