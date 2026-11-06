# 01 · design-system 技能详解

`/design-system` 是整个项目中最复杂的 skill 之一，也是学习"主会话编排子智能体"模式的最佳教材。这一篇逐层拆解它的设计思路、实现技巧和细节，目标是让初学者看完能**自己写一个类似的 skill**。

---

## 这个技能是干什么的

`/design-system` 的功能很直白：**引导你一步步写出一个游戏系统的设计文档（GDD）**。

你输入 `/design-system combat`，它就带着你从"这个系统一句话是什么"开始，逐节讨论 Overview、Player Fantasy、Detailed Design、Formulas、Edge Cases……直到所有 8 个必需章节全部写完，最终产出一份完整的 `design/gdd/combat.md`。

但"怎么带"才是关键。它不是自己闷头写完扔给你，而是**每个章节都跟你讨论、让你拍板、等你批准了才写文件**。它还会在需要时**派子智能体（subagent）**去帮你做专业分析（比如让"创意总监"帮你塑造玩家幻想，让"系统设计师"帮你推导公式）。

---

## 前置知识：skill 文件的基本结构

在深入之前，先看 SKILL.md 开头的配置块。

来自 [design-system/SKILL.md](file:///workspace/.claude/skills/design-system/SKILL.md)：

```yaml
---
name: design-system
description: "Guided, section-by-section GDD authoring for a single game system..."
argument-hint: "<system-name> [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion, TodoWrite
model: sonnet
---
```

逐字段解释：

| 字段 | 值 | 含义 |
|------|-----|------|
| `name` | `design-system` | 命令名，用户敲 `/design-system` 触发 |
| `description` | 那一长串英文 | 给 `/help` 和 AI 识别用的简介 |
| `argument-hint` | `<system-name> [--review full\|lean\|solo]` | 参数提示：必须给系统名，可选审核模式 |
| `user-invocable` | `true` | **用户能直接敲命令触发**。如果是 `false`，这个 skill 只能被其他 skill 内部调用 |
| `allowed-tools` | 8 个工具 | 这个 skill 能用哪些工具 |
| `model` | `sonnet` | 用哪个模型跑 |

**第一个关键细节：`allowed-tools` 里有 `Task`。**

`Task` 就是"派生子智能体"的工具。这意味着这个 skill 既能自己干活（主会话），也能派子智能体（subagent）去干活。理解了这一点，就理解了整个 skill 的核心设计：**主会话做编排，子智能体做专业分析**。

---

## 核心概念：主会话 vs 子智能体

这是理解 design-system 最关键的问题。很多初学者会混淆"skill 本身"和"skill 派出的子智能体"。

### 简单类比

```
主会话 = 项目经理（PM）
子智能体 = 设计师 / 工程师 / QA

PM 自己不动手写设计稿，但 PM 知道：
  - 什么时候该找谁
  - 怎么把上下文打包给那个人
  - 怎么把那个人的输出整理好给你看
  - 最终拍板的是你（用户），PM 只负责"问"和"整理"
```

### 具体到 design-system

```
用户敲 /design-system combat
        │
        ▼
   主会话（skill 本身）启动
        │
        │  读取 game-concept.md、systems-index.md、依赖 GDD……
        │  展示上下文摘要，问"准备好了吗？"
        │
        │  用户确认后，创建文件骨架
        │
        │  然后逐节推进：
        │
        ├── Section A: Overview
        │    主会话自己：问问题、给选项、起草、等批准、写文件
        │
        ├── Section B: Player Fantasy
        │    主会话：问"直接体验还是间接体验？"
        │    如果 review mode 不是 solo：
        │      └─ 派生子智能体 creative-director（创意总监）
        │         子智能体分析后返回"2-3 种幻想框架"
        │    主会话：把子智能体的分析展示给你，让你选
        │    主会话：起草、等批准、写文件
        │
        ├── Section C: Detailed Design
        │    主会话：从路由表查出该派哪些专家
        │    如果 review mode 不是 solo：
        │      └─ 并行派生子智能体（如 systems-designer + gameplay-programmer）
        │         各自分析后返回设计建议
        │    主会话：汇总，有分歧就标出来让你处理
        │    主会话：起草、等批准、写文件
        │
        ├── Section D: Formulas
        │    主会话：派 systems-designer 推导公式
        │    （如果是经济系统，还额外派 economy-designer）
        │    主会话：展示公式建议、等批准、写文件
        │
        └── ……
```

### 关键规则

1. **主会话（skill 本身）是唯一写文件的人**。子智能体只做分析，返回建议，不碰文件。
2. **子智能体不知道你的全部对话历史**。每次派生子智能体，主会话必须把需要的上下文打包传过去。
3. **子智能体之间互相不知道对方的存在**。两个子智能体如果意见不一致，是主会话发现矛盾，然后问你。

---

## 派生子智能体的时机：Review Mode 机制

不是每个章节都要派生智能体。design-system 用 **Review Mode** 来控制派生的频率，节省时间和 token。

### 三种模式

来自 [design-system/SKILL.md](file:///workspace/.claude/skills/design-system/SKILL.md) 的 Phase 1：

| 模式 | 参数 | 行为 |
|------|------|------|
| **full** | `--review full` | 所有设计章节都派生专业智能体。每个 Section 都要经过对应的专家审查 |
| **lean**（默认） | `--review lean` 或不指定 | 只在**高风险章节**派生（Section D: Formulas 和 Section H: Acceptance Criteria）。其他章节主会话自己搞定 |
| **solo** | `--review solo` | 完全不派生任何子智能体。主会话自己全部搞定，但会在文档里标注"未经专家审查" |

### 怎么选模式

```python
# 优先级从高到低：
1. 命令行参数（--review full|lean|solo）
2. production/review-mode.txt 文件里的值
3. 默认 lean
```

### 这个设计的精妙之处

**给用户一个"成本旋钮"。**

- 重要系统（战斗、经济）→ `full`：花更多 token 和时间，但设计质量更高
- 普通系统 → `lean`：只在最需要专家的地方派生
- 快速原型、实验性想法 → `solo`：快，但自己要对设计质量负责

这不只是设计模式，更是**工程思维**：编排不是"一刀切"，而是让用户按场景调严格度。

---

## 5 个 Phase 的完整流程

### Phase 1：解析参数并验证

```
输入 → 解析系统名 → 检查 review mode → 验证系统是否存在
                                    ↓
                          如果在 systems-index.md 里 → 继续
                          如果不在 → 警告，问要不要加
                          如果没有 systems-index.md → 报错，提示先跑 /map-systems
```

**额外模式：Retrofit（回填）**

如果参数是 `retrofit` 开头，或者是一个已有的 GDD 文件路径，进入回填模式：

1. 读取已有 GDD，扫描哪些章节写了、哪些是 `[To be designed]` 占位符
2. 列出"已完成（不碰）"和"缺失/不完整（要补）"的章节
3. 问你确认后，只补缺失的章节，**绝不修改已有内容**

这是一个很实用的设计：GDD 不是一次性写完的，后面可以回来补。

### Phase 2：收集上下文（"先读再问"）

这是这个 skill 区别于"你随口问 AI 一个问题"的核心优势。**在问你任何问题之前，它先把所有相关文件读完。**

要读的文件：

| 类别 | 文件 | 用途 |
|------|------|------|
| 必需 | `design/gdd/game-concept.md` | 游戏整体概念 |
| 必需 | `design/gdd/systems-index.md` | 系统优先级和层级 |
| 必需 | `design/registry/entities.yaml` | 已有实体/公式/常量（跨系统事实） |
| 必需 | `docs/consistency-failures.md` | 过去的冲突模式（避免重蹈覆辙） |
| 依赖 | 上游依赖系统的 GDD | 这个系统必须遵守的已有决策 |
| 依赖 | 下游依赖系统的 GDD | 这个系统必须满足的期望 |
| 可选 | `design/gdd/game-pillars.md` | 游戏支柱 |
| 可选 | 已有同名 GDD | 恢复中断的设计 |
| 可选 | 主题相关的其他 GDD | 非正式依赖但范围重叠的 |

**为什么要读这么多？**

因为"上下文不全 = 设计自相矛盾"。如果你不知道战斗系统已经定义了"伤害 = 攻击力 × 1.5 - 防御力"，你设计护甲系统时很可能写一个冲突的公式。

**Phase 2 的最后**，主会话会展示一个"上下文摘要"：

```
Designing: Combat System
- Priority: P0 | Layer: Core
- Depends on: input-system (GDD exists), stats-system (未设计!)
- Depended on by: enemy-system (GDD exists), ui-hud (GDD exists)
- Existing decisions to respect: 伤害公式来自 stats-system……
- Pillar alignment: "Intense Action"

如果上游依赖未设计：警告用户"需要做假设"
```

然后才问："准备好了吗？"

### Phase 3：创建文件骨架

用户确认后，立刻创建 GDD 文件，所有章节用 `[To be designed]` 占位。**这很重要**——后续每个章节写完立即写入，不会丢失。

同时更新 `production/session-state/active.md`，记录"当前在做什么、做到哪了"。这个文件是**中断恢复的关键**。

### Phase 4：逐节设计（核心）

这是整个 skill 最长的部分。8 个必需章节 + 可选章节，每个都遵循同一个循环。

### Phase 5：设计后验证

所有章节写完后：

1. **自检**：重读完整 GDD，确认所有章节有真实内容（不是占位符）
2. **创意总监支柱审查**（full 模式）：派 `creative-director` 验证 GDD 是否对齐游戏支柱
3. **更新实体注册表**：扫描新定义的实体、公式、常量，写入 `entities.yaml`
4. **建议设计审查**：但**强调必须在新的干净会话中跑** `/design-review`（避免审查者被设计者的上下文污染）
5. **更新系统索引**：标记状态为 Designed / Approved
6. **建议下一步**：consistency-check / 设计下一个系统 / gate-check

---

## 逐节设计循环：7 步协议

这是 design-system 最核心的交互模式。每个章节都严格遵循这个流程：

```
Context → Questions → Options → Decision → Draft → Approval → Write
```

### 每一步详解

以 Section B（Player Fantasy）为例：

**Step 1 — Context（背景）**

主会话先说清楚这个章节要写什么，以及从依赖 GDD 中提取的约束条件。

> "Player Fantasy 章节要定义玩家与这个系统交互时的情感体验。战斗系统属于 Core 层，是玩家直接体验的系统。"

**Step 2 — Questions（提问）**

用 `AskUserQuestion` 问关键问题。

> "这个系统是玩家直接体验的，还是底层基础设施？"
> - [A] 直接 —— 玩家主动使用或感受这个系统
> - [B] 间接 —— 玩家感受的是效果，不是系统本身
> - [C] 两者都有

**Step 3 — Options（选项）**

如果章节涉及设计选择（不只是记录），给出 2-4 个方案，每个带利弊分析。

**Step 4 — Decision（决策）**

用户选方案，或提供自定义方向。

**Step 5 — Draft（草稿）**

主会话把起草的内容展示给用户审查。**必须同时展示草稿和批准控件**——这是硬性要求，skill 里明确写了：

> "The draft and the approval widget MUST appear together in one response. If the draft appears without the widget, the user is left at a blank prompt with no path forward — this is a protocol violation."

**Step 6 — Approval（批准）**

用 `AskUserQuestion` 问：

> "Approve the Player Fantasy section?"
> - [A] Approve — write it to file
> - [B] Make changes — describe what to fix
> - [C] Start over

**Step 7 — Write（写入）**

用 `Edit` 工具替换 `[To be designed]` 为批准的内容。

**一个重要的实现细节**：skill 里特别强调，`old_string` 必须包含章节标题，不能只匹配 `[To be designed]`：

```
old_string: "## Player Fantasy\n\n[To be designed]"
new_string: "## Player Fantasy\n\n[批准的内容]"
```

**为什么？** 因为多个章节都有 `[To be designed]`，如果只匹配它，`Edit` 工具会报"不唯一"错误。加上章节标题让匹配唯一。

---

## 子智能体派生的详细模式

### Section B（Player Fantasy）的派生流程

```
主会话：用 AskUserQuestion 问"直接/间接/两者"
        ↓
用户选了 [A] 直接
        ↓
主会话：检查 review mode
  - solo → 跳过派生，自己起草，标注"creative-director 未审查"
  - lean → 不是高风险章节，跳过派生
  - full → 派生 creative-director
        ↓
主会话用 Task 工具：
  subagent_type: creative-director
  传入：
    - 系统名：combat
    - 框架答案：direct
    - 游戏支柱文本
    - 用户提到的参考游戏
    - 游戏概念摘要
  要求：塑造玩家幻想，2-3 种候选框架
        ↓
creative-director 分析后返回：
  "框架 A：肾上腺素飙升的战术对抗……
   框架 B：技巧与时机并重的舞动式战斗……
   框架 C：力量碾压的爽快发泄……"
        ↓
主会话：把 3 种框架展示给你，让你选
        ↓
你选了框架 B
        ↓
主会话：起草 Player Fantasy 章节，融入选中的框架
        ↓
用 AskUserQuestion 问批准
        ↓
批准后写入文件
```

**关键点**：子智能体只负责"分析"和"建议"，**不写文件**。写文件永远是主会话的职责。

### Section C（Detailed Design）的派生流程

这是最复杂的。主会话先查路由表（skill 的 Section 6），根据系统类别决定派哪些专家：

| 系统类别 | 主专家 | 辅助专家 |
|----------|--------|----------|
| 基础/设施（事件总线、存档、场景管理） | `systems-designer` | `gameplay-programmer`、`engine-programmer` |
| 战斗、伤害、生命 | `game-designer` | `systems-designer`、`ai-programmer`、`art-director` |
| 经济、掉落、制造 | `economy-designer` | `systems-designer`、`game-designer` |
| 对话、任务、叙事 | `game-designer` | `narrative-director`、`writer`、`art-director` |
| UI 系统 | `game-designer` | `ux-designer`、`ui-programmer`、`art-director`、`technical-artist` |
| AI、寻路、行为 | `game-designer` | `ai-programmer`、`systems-designer` |
| 视觉特效、粒子、着色器 | `game-designer` | `art-director`、`technical-artist`、`systems-designer` |

**这些子智能体是并行派生的**（如果它们之间没有依赖关系）：

```
主会话：同时派生 systems-designer + gameplay-programmer + engine-programmer
        │
        ├─ systems-designer 分析规则和机制
        ├─ gameplay-programmer 分析可行性
        └─ engine-programmer 分析引擎集成
        │
        ↓ 三个都返回后
主会话：汇总。如果有矛盾：
        "systems-designer 建议用状态机，但 gameplay-programmer 认为
         行为树更合适。你想用哪个？"
        ↓
你拍板
```

### Section D（Formulas）的派生流程

公式章节的特殊之处在于：

1. **总是派生 `systems-designer`**（不管 review mode 是不是 lean，D 和 H 始终是高风险章节）
2. **如果是经济/成本系统，额外派生 `economy-designer`**

skill 里的原话：

> "Do NOT invent formula values or balance numbers without specialist input. A user without balance design expertise cannot evaluate raw numbers — they need the specialists' reasoning."

**这是一个重要的设计哲学**：当用户不具备某个领域的专业知识时，不要直接问用户"你想要什么数值"，而是让专家先给出推理和建议，再让用户选择。

### Section H（Acceptance Criteria）的派生流程

派生 `qa-lead`，传入完整的 C、D、E 章节，让它验证：

- 每个验收标准是否可独立测试
- 是否覆盖了所有核心规则和公式
- 有没有遗漏的边界情况

---

## 上下文预加载策略

这是 design-system 最值得学习的技巧之一。Phase 2 的"先读后问"模式解决了一个核心问题：

**AI 在不知道上下文的情况下提问，会问出愚蠢的问题，浪费用户的回合。**

对比：

```
❌ 不预加载：
  AI: "你的战斗系统是回合制还是实时？"
  User: "实时。"
  AI: "伤害公式里用防御力吗？"
  User: "用。"
  AI: "那你系统里有没有护甲？"
  User: "……你猜。"
  （每轮一问，效率极低）

✅ 预加载后：
  AI: "我看到你的 game-concept.md 里写了'快节奏实时战斗'，
       stats-system 的 GDD 里定义了 HP、ATK、DEF 三个属性，
       护甲系统还没设计但会依赖战斗系统。
       
       基于这些，战斗系统的 Overview 我建议这样写：[draft]
       
       在深入之前，有几个问题需要确认：
       1. 伤害窗口是逐帧检测还是离散事件？
       2. 是否允许多个伤害源同时命中？
       3. ……"
  （带着上下文提问，高效且精准）
```

**技术实现**：Phase 2 用 `Read`、`Glob`、`Grep` 等只读工具，把相关文件全部加载到主会话的上下文中。这样后续的每一次提问都"带着信息来"。

---

## 增量写入与会话状态

### 为什么每个章节写完立刻写入文件

1. **防止丢失**：如果会话中断（compaction / 崩溃 / 新会话），已批准的章节在文件里，不会丢。
2. **支持恢复**：新会话运行 `/design-system combat`，它会读到已有 GDD，跳过已完成的章节，从下一个 `[To be designed]` 继续。
3. **减少上下文占用**：写到文件的内容不需要一直在对话里保留。AI 可以"忘记"已写的内容，腾出上下文给后面的章节。

### 会话状态文件

`production/session-state/active.md` 是一个轻量级的"进度记录"。每次写完一个章节，主会话就更新它：

```markdown
- Task: Designing combat GDD
- Current section: Detailed Design (Core Rules)
- File: design/gdd/combat.md
- Sections complete: Overview, Player Fantasy
```

恢复时，主会话读这个文件就知道"做到哪了"。

**注意 skill 里的一个细节**：更新 `active.md` 时，先用 `Glob` 检查文件是否存在。如果不存在用 `Write`（创建），如果存在用 `Edit`（更新）。不能用 `Edit` 去操作一个不存在的文件——会报错。

---

## 协作协议在 skill 中的落地

design-system 是"协作协议"最密集的落地案例。skill 末尾的 Collaborative Protocol 章节总结了 7 条铁律：

1. **每个章节都走 Question → Options → Decision → Draft → Approval**
2. **每个决策点都用 `AskUserQuestion`**（Phase 2 确认、Phase 3 创建骨架、Phase 4 每个章节的设计问题 + 选项 + 批准、Phase 5 后续步骤）
3. **每次写文件前都问"我可以写到 [路径] 吗？"**
4. **增量写入**：批准后立刻写
5. **会话状态更新**：每写完一个章节就更新
6. **交叉引用**：每个章节都检查已有 GDD 的冲突
7. **专家路由**：复杂章节派专家，输出展示给你，等你拍板

以及三条"永不"：

- **永不**自动生成完整 GDD 直接扔给你（fait accompli）
- **永不**未经批准写章节
- **永不**静默覆盖已有 GDD 的决策

---

## 上下文窗口感知

skill 的倒数第二节有一个很实用的设计：

> "After writing each section, check if the status line shows context at or above 70%. If so, append this notice: **Context is approaching the limit (≥70%). Your progress is saved — all approved sections are written to file. When you're ready to continue, open a fresh Claude Code session and run `/design-system [system-name]` — it will detect which sections are complete and resume from the next one.**"

**为什么 70% 就警告？** 因为 70% 到 100% 之间，compaction（上下文压缩）随时可能触发。提前警告让用户有机会在"干净"的状态下保存进度，而不是在 compaction 边缘硬撑。

**为什么恢复能无缝？** 因为：
- 文件骨架在 Phase 3 就创建了
- 每个章节写完立刻写入文件
- 会话状态文件记录了进度
- 新会话启动时，Phase 2 会读取已有 GDD，Phase 4 会跳过已完成的章节

---

## 设计审查的独立性原则

Phase 5c 有一个很值得注意的设计：

> "**Never run `/design-review` in the same session as `/design-system`.** The reviewing agent must be independent of the authoring context. Running it here would inherit the full design history, making independent critique impossible."

**这揭示了 AI 编排中的一个隐蔽问题**：同一个会话里的 AI 会"看到"所有之前的对话，包括设计过程中的所有讨论和妥协。如果让它审查自己刚设计的东西，它很难做到真正的独立——它会"理解"那些妥协，因为这都在它的上下文里。

**解决方案**：让审查在**全新会话**中运行。新会话的 AI 只看到最终 GDD 文件，没有看到设计过程中的讨论，能做出更客观的评判。

**这是一个通用的编排原则**：**创作和审查必须在不同会话中分离**。任何需要"独立视角"的任务都应该遵循这个原则。

---

## 实体注册表的冲突检查

Phase 4 的 Section C 和 D 写完后，有一个"注册表冲突检查"步骤。

**目的**：一个游戏里，同一个实体（比如"HP"）被多个系统引用。如果战斗系统定义 HP 上限是 100，而升级系统定义 HP 上限是 150，这就冲突了。

**实现**：写完后扫描章节内容，和 `design/registry/entities.yaml` 比对：

```
如果发现同名实体：
  - 值相同 → 记录 "matches registry ✅"
  - 值不同 → 立即报告冲突："Registry conflict: HP 在 stats-system 中注册为 100，
    但本节写了 150。哪个是对的？"

如果是新实体（不在注册表中）：
  - 标记为候选，Phase 5 统一处理
```

**这个设计解决了一个真实问题**：多个 GDD 由不同会话、不同时间编写，数值很容易漂移。注册表是"跨系统事实的单一真相源"。

---

## 完整的架构图

```
┌──────────────────────────────────────────────────────────┐
│                    /design-system combat                  │
│                      用户输入命令                          │
└──────────────────────────┬───────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 1: 解析参数                                        │
│  - 系统名 → kebab-case → combat                           │
│  - review mode → full / lean / solo                       │
│  - 验证系统在 systems-index.md 中                         │
│  - 检查 retrofit 模式                                     │
└──────────────────────────┬───────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 2: 收集上下文（只读）                                │
│  - game-concept.md                                        │
│  - systems-index.md                                       │
│  - entities.yaml（注册表）                                 │
│  - consistency-failures.md                                │
│  - 依赖 GDD（上游 + 下游）                                 │
│  - 可选：game-pillars.md、引擎参考、ADR                    │
│  - 展示上下文摘要 → AskUserQuestion 确认                   │
└──────────────────────────┬───────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 3: 创建文件骨架                                     │
│  - 创建 design/gdd/combat.md（所有章节 [To be designed]）  │
│  - 更新 production/session-state/active.md                │
│  - AskUserQuestion 确认创建                                │
└──────────────────────────┬───────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 4: 逐节设计（核心循环）                              │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  Section Cycle: Context → Questions → Options →     │ │
│  │  Decision → Draft → Approval → Write                │ │
│  │                                                      │ │
│  │  Section A: Overview                                 │ │
│  │  Section B: Player Fantasy ─── 派 creative-director  │ │
│  │  Section C: Detailed Design ─ 派多个专家（并行）     │ │
│  │  Section D: Formulas ──────── 派 systems-designer   │ │
│  │  Section E: Edge Cases ────── 派 systems-designer   │ │
│  │  Section F: Dependencies     （主会话自己）          │ │
│  │  Section G: Tuning Knobs ─── 派 systems-designer    │ │
│  │  Section H: Acceptance Criteria 派 qa-lead          │ │
│  │  可选: Visual/Audio, UI, Open Questions             │ │
│  │                                                      │ │
│  │  每写完一个章节 → 更新 active.md                      │ │
│  │  每写完一个章节 → 检查上下文 ≥70% → 警告              │ │
│  └─────────────────────────────────────────────────────┘ │
└──────────────────────────┬───────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 5: 设计后验证                                       │
│  - 5a: 自检（所有章节有真实内容）                           │
│  - 5a-bis: 创意总监支柱审查（full 模式）                   │
│  - 5b: 更新 entities.yaml 注册表                           │
│  - 5c: 建议独立审查（强调新会话）                           │
│  - 5d: 更新 systems-index.md 状态                          │
│  - 5e: 更新 active.md 状态                                 │
│  - 5f: 建议下一步                                          │
└──────────────────────────────────────────────────────────┘
```

---

## 关键设计技巧总结

### 1. 主会话编排 + 子智能体执行

主会话不自己做专业分析，而是派子智能体。主会话的职责是**编排**：读上下文、问问题、调度专家、汇总结果、写文件。

### 2. 先读后问

在所有交互之前，先把相关文件全部读完。避免"不知道上下文就问出愚蠢问题"。

### 3. 增量写入 + 会话状态

每个章节写完立刻写入文件，同时更新会话状态。这样支持中断恢复，也减少上下文占用。

### 4. 严格度旋钮（Review Mode）

full / lean / solo 三种模式让用户按场景调成本。这是"编排的灵活性"。

### 5. 并行派生

当多个子智能体之间没有依赖关系时，并行派生它们，节省时间。skill 的 Section 6 路由表定义了哪些专家可以并行。

### 6. 协作协议不打折

每一步决策都走 Question → Options → Decision → Draft → Approval。永远不跳步。

### 7. 交叉引用防冲突

每个章节写完后检查注册表、依赖 GDD、游戏支柱，确保不矛盾。

### 8. 创作与审查分离

不在同一会话中审查自己刚设计的东西。独立审查需要干净的上下文。

### 9. 上下文窗口感知

70% 就警告，而不是等到 compaction 触发。给用户一个"优雅退出"的机会。

### 10. 文件即状态机

用文件的存在性和内容来判断进度，而不是依赖 AI 的记忆。`active.md`、`systems-index.md`、`entities.yaml` 都是"文件状态机"的节点。

---

## 小测验

**Q1**：`/design-system` 是主会话在跑还是子智能体在跑？

> **A**：主会话在跑。skill 本身是主会话的"作业指导书"。子智能体只在特定章节（如 Section B、C、D、H）被主会话通过 `Task` 工具派生，做专业分析后返回结果给主会话。主会话始终是唯一写文件的人。

**Q2**：在 `lean` 模式下，哪些章节会派生子智能体？为什么？

> **A**：只有 Section D（Formulas）和 Section H（Acceptance Criteria）会派生。因为这两个是"高风险章节"——公式错了整个系统数值崩，验收标准错了 QA 没法测。其他章节在 lean 模式下主会话自己搞定，节省 token。

**Q3**：为什么 `Edit` 工具的 `old_string` 必须包含章节标题，而不能只匹配 `[To be designed]`？

> **A**：因为多个章节都有 `[To be designed]` 占位符。`Edit` 工具要求 `old_string` 在文件中唯一，只匹配 `[To be designed]` 会导致"不唯一"错误。加上章节标题（如 `## Player Fantasy\n\n[To be designed]`）让匹配唯一。

**Q4**：为什么设计审查必须在新的干净会话中运行？

> **A**：因为同一会话的 AI 会"看到"设计过程中的所有讨论和妥协，无法做到真正的独立审查。新会话的 AI 只看到最终 GDD 文件，没有设计过程的上下文，能做出更客观的评判。这是"创作与审查分离"原则。

**Q5**：`entities.yaml` 注册表解决的是什么问题？

> **A**：解决"多个 GDD 定义同名实体但数值不同"的冲突问题。比如战斗系统定义 HP 上限 100，升级系统定义 HP 上限 150——注册表是"跨系统事实的单一真相源"，任何写入都要跟注册表比对，发现冲突立刻上报。

---

## 动手

1. 打开 [design-system/SKILL.md](file:///workspace/.claude/skills/design-system/SKILL.md)，找到 Section 6（Specialist Agent Routing），看看"战斗系统"需要派生哪些专家，和"对话系统"有什么不同。
2. 对比 Section B（Player Fantasy）和 Section D（Formulas）的"Review mode check"逻辑，看看 `lean` 模式为什么跳过 B 但不跳过 D。
3. 找到 Phase 2e（Technical Feasibility Pre-Check），看看它是怎么根据系统类别映射到引擎域名的——这个映射表的设计思路是什么。
4. 尝试用"主会话编排 + 子智能体执行"的模式，设计一个你自己的 skill 草图（比如"代码审查"或"周报生成"），回答：哪些步骤主会话自己干？哪些步骤派生子智能体？子智能体之间要并行还是串行？