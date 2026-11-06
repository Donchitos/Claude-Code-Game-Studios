# 16 · design 目录指南

## 这篇文档解决什么问题

上一篇（[15 · docs 目录指南](file:///workspace/study-docs/15-docs目录指南.md)）讲了项目根目录下的 `docs/`——那里放的是"技术文档 + 引擎字典 + 案例"。这篇专门讲另一个根目录 [design/](file:///workspace/design/)——它放的是**"游戏设计文档"**（Game Design Documents，简称 GDD）。

读完这篇你会明白：

- `design/` 里每个文件是干什么的（作用）
- 怎么用它（如何使用）
- 为什么需要它（为什么要用）
- 在 7 阶段开发流程的什么时候会碰到它（开发流程中何时被使用）

> ⚠️ **重要前提**：当前项目的 `design/` 目录是"骨架状态"——只有两个规范文件，还没有实际的设计文档。这是正常的：设计文档是在你开始做游戏后、由技能按需产出的。这篇会讲清"现在有什么"和"将来会有什么"。

---

## 一句话定位

> **`design/` = 游戏的"设计大脑"。`docs/` 回答"怎么实现"，`design/` 回答"做什么、为什么这么做"。**

---

## 类比：`design/` vs `docs/`，别搞混

很多人第一次看会混淆这两个目录。用"盖房子"类比：

| | `design/`（设计） | `docs/`（技术） |
|---|---|---|
| 类比 | 建筑师的**设计图纸**（户型、风格、用途） | 工程师的**施工图纸**（承重、管线、材料） |
| 回答什么 | 这个房间是卧室还是厨房？多大？给谁用？ | 这面墙用什么砖？承重多少？电线怎么走？ |
| 游戏里 | 战斗系统怎么玩？伤害怎么算？敌人掉什么？ | 用什么架构？状态归谁管？用哪个引擎 API？ |
| 谁产出 | 游戏设计师（game-designer 等设计师智能体） | 程序员（lead-programmer 等技术智能体） |
| 文件类型 | GDD、UX 规范、quick-spec | ADR、引擎参考、注册表 |

**记住**：先有 `design/`（设计决定做什么），后有 `docs/`（技术决定怎么做）。设计文档是技术文档的输入。

---

## 类比：把 `design/` 想象成游戏公司的"设计部档案柜"

想象你走进游戏公司的设计部，档案柜分几层：

| 档案柜分层 | 对应 `design/` 里的东西 | 你什么时候翻 |
|-----------|----------------------|-------------|
| 柜门贴的"写作须知" | [CLAUDE.md](file:///workspace/design/CLAUDE.md) | 要往这个柜子放新设计文档前 |
| 一本"实体登记册" | [registry/entities.yaml](file:///workspace/design/registry/entities.yaml) | 写新文档时查"哥布林血量是多少？谁也在用这个数？" |
| **还没开的抽屉**（按需创建） | `gdd/`、`ux/`、`quick-specs/`、`narrative/`、`levels/`、`balance/` | 做到对应阶段才会打开 |

关键：**现在只有前两层（写作须知 + 实体登记册），抽屉是空的等你来填**。

---

## 全景地图

```
design/
├── CLAUDE.md                      # 目录级写作规范（写 GDD / UX spec 时遵守）
├── registry/
│   └── entities.yaml              # 游戏世界实体注册表（跨 GDD 一致性的"事实之源"）
│
│   ── 以下子目录在开发流程中按需创建，目前不存在 ──
├── gdd/                           # 游戏设计文档（每个系统一份）
│   ├── systems-index.md           # 系统总索引（所有系统、依赖、优先级）
│   ├── game-concept.md            # 游戏概念文档（立项时产出）
│   └── [system-slug].md           # 各系统 GDD（combat-system.md 等）
├── quick-specs/                   # 轻量规范（小改动、调数值用）
├── ux/                            # UX 规范（每个屏幕一份）
│   ├── [screen-name].md
│   ├── hud.md
│   ├── interaction-patterns.md
│   └── accessibility-requirements.md
├── narrative/                     # 故事、设定、对话
├── levels/                        # 关卡设计文档
└── balance/                       # 平衡性数据表
```

下面逐个讲。**先讲现在就存在的两个文件，再讲将来会出现的子目录**。

---

## 现在就存在的文件

### 1. `design/CLAUDE.md` —— 目录级写作规范

**作用**：这是贴在 `design/` 目录门口的"写作须知"。它告诉 AI（和人类）：在这个目录下写或改设计文档时，必须遵守哪些格式标准。主要管三类东西——**GDD（游戏设计文档）、quick-specs（轻量规范）、UX 规范**。

**关键内容**（来自 [design/CLAUDE.md](file:///workspace/design/CLAUDE.md)）：

GDD 必须包含 **8 个必填章节**，且顺序固定：

| # | 章节 | 写什么 |
|---|------|--------|
| 1 | Overview（概述） | 一段话总结这个系统 |
| 2 | Player Fantasy（玩家幻想） | 玩家用这个系统时想象自己是什么、感受什么 |
| 3 | Detailed Rules（详细规则） | 不含糊的机制规则 |
| 4 | Formulas（公式） | 所有数学计算，带变量定义和取值范围 |
| 5 | Edge Cases（边界情况） | 罕见情况怎么处理，明确写出 |
| 6 | Dependencies（依赖） | 这个系统连着哪些别的系统（双向） |
| 7 | Tuning Knobs（调节旋钮） | 哪些数值设计师可以安全改，安全范围是多少 |
| 8 | Acceptance Criteria（验收标准） | 怎么测试这个系统算"做完了"，具体可衡量 |

其他规则：
- 文件命名：`[system-slug].md`，如 `movement-system.md`、`combat-system.md`
- 系统索引：`design/gdd/systems-index.md`——加新 GDD 时要更新它
- 设计顺序：Foundation（基础）→ Core（核心）→ Feature（功能）→ Presentation（表现）→ Polish（打磨）
- 校验：写完任一 GDD 跑 `/design-review`；写完一批相关的跑 `/review-all-gdds`

**如何使用**：你不用主动"运行"它。Claude Code 进入 `design/` 目录工作时自动读到它（CLAUDE.md 是目录级配置文件）。你只要知道：**当 AI 帮你创建 GDD 或 UX 规范时，它会自动按这里的规矩来**——8 个章节一个不少、顺序不变、命名用 slug。

**为什么要用**：没有它，每个 GDD 长得都不一样，有的漏了边界情况、有的没写验收标准。后续的 `/design-review`、`/create-stories`、`/story-done` 都没法自动解析。统一格式 = 自动化能跑起来的前提，也是质量保证——8 个章节是游戏设计行业的硬经验，漏一个都可能埋雷。

**开发流程中何时被使用**：**Phase 2（系统设计）** 最密集——这是 GDD 集中产出的阶段。Phase 4（预制作）写 UX 规范时也会触发。

> 📌 CLAUDE.md 的机制和 `docs/CLAUDE.md` 完全一样，只是管的文档类型不同。想理解 CLAUDE.md 怎么工作，看 [11-CLAUDE.md 编写指导](file:///workspace/study-docs/11-CLAUDE.md编写指导.md)。

---

### 2. `design/registry/entities.yaml` —— 游戏世界实体注册表

**作用**：这是**跨 GDD 一致性的"事实之源"（single source of truth）**。单个 GDD 只管一个系统，但游戏世界里有些东西会出现在多个文档里——比如"哥布林"这个敌人，在战斗 GDD 里定义血量和伤害，在物品 GDD 里定义它掉什么，在经济 GDD 里定义掉落物值多少钱。这个文件把这些**跨文档共享的事实**登记下来，让写新 GDD 时能提前发现冲突。

**登记四类东西**（来自 [design/registry/entities.yaml](file:///workspace/design/registry/entities.yaml)）：

| 类别 | 防止什么冲突 | 举例 |
|------|-------------|------|
| **entities**（实体） | 两个 GDD 对同一敌人血量写不一样的数 = 玩家体验混乱 | 哥布林血量 40，在 combat.md 定义，inventory.md 引用 |
| **items**（物品） | 同一物品在不同 GDD 里价值/重量不一致 = 经济崩坏 | 哥布林手臂值 5 金、重 1、可堆叠 |
| **formulas**（公式） | 一个 GDD 的公式输出对不上另一个 GDD 的输入 = 集成 bug | 伤害公式输出 0-999，血量系统按这个扣血 |
| **constants**（常量） | 跨系统约定的数值对不上 = 逻辑错误 | 金币携带上限 9999，经济定义、背包执行、HUD 显示 |

**关键规则**：

- 只登记**跨系统边界**的事实。只在一个 GDD 里用的内部细节不用登记。
- **永远不删条目**——作废了标 `status: deprecated`。
- 值改了就更新值、设 `revised` 日期、加注释记旧值和谁改的。
- `source` 是"权威 GDD"（拥有这个事实的文档），其他引用它的 GDD 列在 `referenced_by` 里。
- 新 GDD 引用已有条目时，把自己的路径加到 `referenced_by`，**不要建重复条目**。

**谁写谁读**：

| 角色 | 技能 / 时机 |
|------|------------|
| 写入 | `/design-system`（GDD 章节批准后，Phase 5） |
| 写入 | `/consistency-check`（解决冲突时） |
| 读取 | `/design-system`（写之前查冲突；写完 Section C/D 后再查一次） |
| 读取 | `/consistency-check`（主要输入——先 grep 这个文件，再查 GDD） |
| 读取 | `/review-all-gdds`（Phase 1 建立基线） |
| 读取 | `/architecture-review`（验证数据结构和接口） |

**如何使用**：你**不手动编辑**这个文件。它由 `/design-system` 和 `/consistency-check` 自动维护。文件里还贴心地写了 `Grep` 搜索模式——比如查"所有实体名"用 `Grep pattern="^  - name:"`，查"哥布林"用 `Grep pattern="  - name: goblin"`，查"combat.md 拥有什么"用 `Grep pattern="source: design/gdd/combat.md"`。

**为什么要用**：假设战斗 GDD 写"哥布林血量 40"，后来平衡性调整改成 50，但物品 GDD 里还按 40 算掉落逻辑——玩家就会遇到"血量显示 50 但打死不掉东西"的 bug。有了这个注册表，`/design-system` 写新 GDD 前会先 grep 它，发现"哥布林"已存在就引用而不是重写，`/consistency-check` 能扫出数值不一致。

**开发流程中何时被使用**：

- **Phase 2**（写 GDD）——这是它最活跃的阶段。`/design-system` 写每个 GDD 时都会读写它。
- **Phase 5**（生产）——`/consistency-check` 跨 GDD 检查时读它。

> 📌 这个文件和 [docs/registry/architecture.yaml](file:///workspace/docs/registry/architecture.yaml) 是一对孪生兄弟：那个登记跨 ADR 的**技术约束**（状态归属、接口契约、性能预算），这个登记跨 GDD 的**设计事实**（实体、物品、公式、常量）。机制完全一样，只是管的领域不同。

---

## 将来会出现的子目录（按需创建）

下面这些子目录现在不存在，会在开发流程中由技能按需创建。你只要知道"做到那一步时它们会出现"。

### 3. `design/gdd/` —— 游戏设计文档

**作用**：放每个系统的 GDD，是 `design/` 的核心。每个文件是一个系统的完整设计——8 个章节齐全。

**会出现的文件**：

| 文件 | 何时产出 | 谁产出 |
|------|---------|--------|
| `game-concept.md` | Phase 1（概念） | `/brainstorm` 协作产出 |
| `systems-index.md` | Phase 1 末/Phase 2 初 | `/map-systems` 产出 |
| `[system-slug].md`（如 `combat-system.md`） | Phase 2（系统设计） | `/design-system` 逐节产出 |

**如何使用**：你不手动创建这些文件。`/design-system` 会引导你一节一节写，每写完一节就存盘（防崩溃丢成果）。`systems-index.md` 是总目录，记录所有系统、它们的依赖关系、优先级（MVP/垂直切片/Alpha/完整愿景）。

**为什么要用**：GDD 是整个开发流程的"源头"。`/create-stories` 把 GDD 拆成可实现的故事，`/dev-story` 实现时对照 GDD，`/story-done` 验收时对照 GDD 的验收标准。没有 GDD，后续全是空中楼阁。

**开发流程中何时被使用**：Phase 1 末开始（概念文档、系统索引），Phase 2 集中产出（各系统 GDD），Phase 5 反复引用（实现和验收）。

---

### 4. `design/quick-specs/` —— 轻量规范

**作用**：放小改动、调数值、微调机制用的"轻量规范"——不值得写一整份 8 章节 GDD 的小修改。

**如何使用**：跑 `/quick-design "描述"`，比如 `/quick-design "侧翼攻击加 10% 伤害"`。它在 `design/quick-specs/` 下产出一个轻量 spec，而不是完整 GDD。

**为什么要用**：不是所有改动都值得写 8 章节。调个数值、加个小机制，用 quick-spec 省时间又不丢记录。

**开发流程中何时被使用**：Phase 2 之后随时——生产中调平衡、加小功能时最常用。

---

### 5. `design/ux/` —— UX 规范

**作用**：放每个屏幕的 UX（用户体验）设计规范。GDD 管"系统怎么玩"，UX 规范管"屏幕长什么样、玩家怎么交互"。

**会出现的文件**（来自 [design/CLAUDE.md](file:///workspace/design/CLAUDE.md)）：

| 文件 | 内容 |
|------|------|
| `[screen-name].md` | 每个屏幕一份（主菜单、核心游戏 HUD 等） |
| `hud.md` | HUD（抬头显示）设计 |
| `interaction-patterns.md` | 交互模式库（16 种标准控件 + 游戏专属模式） |
| `accessibility-requirements.md` | 无障碍需求（定一个等级：基础/标准/全面/典范） |

**如何使用**：跑 `/ux-design [屏幕名]` 产出，比如 `/ux-design main-menu`。写完跑 `/ux-review` 校验，过了才能交给 `/team-ui` 实现。

**为什么要用**：不写 UX 规范，程序员做 UI 时只能猜，做出来常常不符合设计意图。UX 规范把"屏幕分区、状态、交互、数据需求、事件、无障碍、本地化"提前定好。无障碍需求尤其重要——它在 Phase 3 就要定等级，Phase 4 的 UX 规范都要符合这个等级。

**开发流程中何时被使用**：`accessibility-requirements.md` 在 Phase 3（技术搭建）就要定；其他 UX 规范在 Phase 4（预制作），写完才能拆故事。

---

### 6. `design/narrative/` —— 故事、设定、对话

**作用**：放世界观、故事弧、角色表、对话等叙事内容。

**如何使用**：用 `world-builder` 智能体建世界观，用 `narrative-director` 设计故事结构，用 `narrative-character-sheet.md` 模板写角色表。

**为什么要用**：有故事的游戏需要把叙事内容和系统设计分开管理，避免混在 GDD 里太乱。

**开发流程中何时被使用**：Phase 2（系统设计）末段——如果游戏有叙事，这是建叙事内容的时候。

---

### 7. `design/levels/` —— 关卡设计文档

**作用**：放每个关卡的设计文档——布局、遭遇、流程。

**如何使用**：用 `level-designer` 智能体产出，参考 `.claude/docs/templates/level-design-document.md` 模板。

**为什么要用**：关卡是游戏体验的载体，需要和系统设计分开文档化。

**开发流程中何时被使用**：Phase 5（生产）——开始做实际关卡时。

---

### 8. `design/balance/` —— 平衡性数据

**作用**：放平衡性电子表格和数据——伤害表、掉落率、经济曲线等。

**如何使用**：配合 `/balance-check` 技能分析平衡数据，找异常值、坏掉的进度曲线、退化策略。

**为什么要用**：平衡数据集中管理，方便 `/balance-check` 自动分析，也方便设计师调数值。

**开发流程中何时被使用**：Phase 5-6（生产和打磨）——有实际数值可调时。

---

## 术语速查表（先读这节，后面才看得懂）

下面这些术语会在讲"实际产出哪些文档"时反复出现。先从字面到内涵讲清楚。

### 文档类型术语

| 术语 | 全称 / 字面 | 内涵 |
|------|------------|------|
| **GDD** | Game Design Document | 游戏设计文档。本系统强制每个系统一份，8 个必填章节，是实现的源头规格。 |
| **LDD** | Level Design Document | 关卡设计文档。描述单个关卡的布局、遭遇、节奏。 |
| **TDD** | Technical Design Document | 技术设计文档。描述系统"怎么实现"（区别于 GDD 的"做什么"）。 |
| **ADR** | Architecture Decision Record | 架构决策记录。每个重要技术决策一份，状态流：Proposed → Accepted → Superseded。 |
| **TR-ID** | Technical Requirement ID | 技术需求编号，格式 `TR-[gdd-slug]-[NNN]`。从 GDD 提取到架构文档，建立"需求→实现"可追溯性。 |
| **slug** | — | kebab-case 文件名标识符（如 `combat-system`）。用于 GDD 文件名、TR-ID、引用。 |

### 设计理论术语

| 术语 | 内涵 | 类比 |
|------|------|------|
| **MDA** | Mechanics-Dynamics-Aesthetics 框架。Aesthetics（玩家感受，8 种：Sensation/Fantasy/Narrative/Challenge/Fellowship/Discovery/Expression/Submission）→ Dynamics（涌现行为）→ Mechanics（规则）。设计从目标感受**倒推**到机制。 | 先定"要让玩家觉得帅"，再倒推"什么机制能让玩家觉得帅" |
| **SDT** | Self-Determination Theory 自我决定理论。三大需求：Autonomy（自主）/ Competence（胜任）/ Relatedness（关联）。每系统至少满足一项。 | 玩家要觉得"我能做主"、"我变强了"、"我属于这里" |
| **Bartle 四分类** | 玩家四类：Achievers（成就者）/ Explorers（探索者）/ Socializers（社交者）/ Killers（竞争者）。 | 你游戏讨好哪类人？ |
| **Flow（心流）** | 挑战与技能匹配时进入心流；过低→无聊，过高→焦虑。难度曲线遵循锯齿模式。 | 乒乓球——对手太弱无聊，太强挫败，刚好就停不下来 |
| **Pillars（支柱）** | 3-5 条不可协商的设计原则。特征：可证伪 / 具约束力 / 跨部门 / 可记忆。每条含 design test。 | 公司使命宣言——所有决策要服从它 |
| **Anti-Pillars（反支柱）** | "我们**不做** X，因为它会破坏支柱 Y"。防止"要是能加 X 就酷了"的范围蔓延。 | 黑名单——明确禁止的诱惑 |
| **Core Loop（核心循环）** | 嵌套模型：30 秒微循环（内在满足的动作）⊂ 5-15 分中循环（目标-奖励）⊂ 30-120 分宏循环（进度+停点）⊂ 长期循环。 | 打怪→掉装备→升级→打更强的怪 |
| **Verb-First Design** | 先定玩家核心动词（build/fight/explore/solve/survive/create/manage/discover），动词即游戏。 | "这游戏的核心动作是探索还是战斗？" |
| **Ludonarrative Harmony** | 玩法-叙事和谐。机制与故事互相强化；dissonance（不和谐）= 故事说一套、玩法奖励另一套。 | 故事讲"和平使者"，玩法却奖励屠杀 = 不和谐 |

### 范围与流程术语

| 术语 | 内涵 |
|------|------|
| **MVP** | Minimum Viable Product 最小可行产品。本系统的 Scope Tier 之一——绝对最小可玩构建，测核心循环是否有趣。 |
| **Vertical Slice（垂直切片）** | 3-5 分钟 polished 连续体验，跨所有层（玩法+美术+音频+UI+关卡）。验证"可生产性"。判决：PROCEED/PIVOT/KILL。 |
| **Alpha / Full Vision** | Scope Tier 三、四层。Alpha 功能完整但内容不全；Full Vision 完整愿景。 |
| **Skeleton-first（骨架先行）** | 先建文件（含所有空 section header + `[To be designed]` 占位符），逐 section 增量写入。崩溃只丢当前 section。 |
| **Retrofit mode（改装模式）** | `/design-system retrofit [路径]` 检测已存在 GDD，识别已写章节（不动）、占位符（只填这些）。 |
| **Section Cycle** | 单 section 写入循环：Context → Questions → Options → Decision → Draft → Approval → Write。 |
| **Director Gate（总监门禁）** | Director 级审查关卡。如 CD-GDD-ALIGN、TD-ARCHITECTURE。判决：APPROVED/CONCERNS/REJECT。 |
| **Review Modes** | 评审模式三档：full（所有总监审）/ lean（只阶段门）/ solo（不审，求快）。存 `production/review-mode.txt`。 |

### 经济与平衡术语

| 术语 | 内涵 |
|------|------|
| **Sink/Faucet Model** | 经济水槽-水龙头模型。faucet = 货币进入源头；sink = 货币离开去向。目标 session 长度内必须平衡。 |
| **Pity System（保底）** | 概率奖励在 N 次内必中，防极端坏运。 |
| **Sawtooth Pattern（锯齿模式）** | 难度曲线健康形态：紧张累积 → 里程碑释放 → 略高基线再起。避免 flat（无聊）和 vertical spike（挫败）。 |
| **Gini Coefficient（基尼系数）** | 衡量经济财富集中度。游戏健康目标 <0.4，>0.5 触发警告。 |
| **TTK / TTC** | Time to Kill / Time to Complete。击杀/完成时间。其他数值从此倒推。 |
| **Tuning Knobs** | 调参旋钮三分类：Feel knobs（手感，靠 playtest）/ Curve knobs（曲线，靠数学）/ Gate knobs（节奏门，靠 session 目标）。 |

---

## 实际开发流程中会产生哪些文档

上面讲了"骨架文件"和"子目录会放什么"。这一节具体讲：**真正做游戏时，每个子目录下会产出哪些文件，每个文件长什么样**。

按子目录分组讲。每个文档给：**一句话作用 + 谁产出 + 何时产出 + 章节结构**。

### A. `design/gdd/` —— 概念、索引、系统设计（核心中的核心）

这个子目录放 3 类文档：概念文档、系统索引、各系统 GDD。

#### A1. `game-concept.md` —— 游戏概念文档

**作用**：立项的"出生证明"。定义游戏是什么、给谁玩、为什么独特。是后续所有设计文档的源头。

**谁产出**：`/brainstorm` 技能（creative-director + art-director 协作）。
**何时产出**：Phase 1（概念阶段）。

**16 个章节**（来自 [game-concept.md](file:///workspace/.claude/docs/templates/game-concept.md) 模板）：

1. **Elevator Pitch** —— 一句话电梯陈述
2. **Core Identity** —— 表格：类型/平台/目标受众/人数/时长/商业模式/规模/对标作品
3. **Core Fantasy** —— 核心幻想（玩家想象自己是什么）
4. **Unique Hook** —— 独特卖点，必须过"and also"测试（像 X **且还** Y）
5. **Player Experience Analysis** —— 基于 MDA 框架（目标 Aesthetics + 关键 Dynamics + 核心 Mechanics）
6. **Player Motivation Profile** —— SDT + Bartle 四类 + Flow 通道
7. **Core Loop** —— 嵌套循环：30s / 5-15m / 30-120m / 长期，含留存钩子
8. **Game Pillars** —— 3-5 条支柱
9. **Anti-Pillars** —— 3+ 条反支柱
10. **Inspiration and References**
11. **Target Player Profile**
12. **Technical Considerations**
13. **Risks and Open Questions**
14. **MVP Definition** —— Scope Tiers：MVP / Vertical Slice / Alpha / Full Vision
15. **Next Steps**
16. **Visual Identity Anchor** —— 视觉方向锚点（brainstorm Phase 4 后追加）

#### A2. `game-pillars.md` —— 游戏支柱文档（可选独立）

**作用**：把概念文档里的 Pillars 单独展开成一份完整文档，给每个部门（设计/美术/音频/叙事/工程）明确"该怎么服从支柱、怎么算违反支柱"。

**谁产出**：`/brainstorm`（creative-director 主导）。
**何时产出**：Phase 1（可嵌入概念文档，也可独立）。

**关键章节**：The Pillars（3-5 条，每条含：一句话定义 / 服务的目标 Aesthetics / design test / 各部门"服从 vs 违反"两栏表）/ Anti-Pillars / Pillar Conflict Resolution（优先级排序）/ Pillar Validation Checklist（11 项）。

#### A3. `systems-index.md` —— 系统索引

**作用**：所有系统的"总目录 + 依赖地图 + 设计顺序"。决定先写哪个 GDD、后写哪个。

**谁产出**：`/map-systems` 技能（game-designer 主导）。
**何时产出**：Phase 1 末 / Phase 2 初。

**关键章节**：Systems Enumeration（表格：# / 系统名 / 分类 / 优先级 / 状态 / 设计文档 / 依赖）/ Categories（Core/Gameplay/Progression/Economy/Persistence/UI/Audio/Narrative/Meta）/ Priority Tiers（MVP/Vertical Slice/Alpha/Full Vision）/ Dependency Map（按 5 层：Foundation → Core → Feature → Presentation → Polish）/ Recommended Design Order（含 Agent 和 Effort S/M/L）。

> 💡 **5 层依赖**是设计顺序的核心：Foundation（事件总线、save/load）无上游 → Core（移动、战斗、背包）→ Feature（进度、经济、制作）→ Presentation（UI/HUD/音频反馈）→ Polish（VFX/juice）。必须从底往上写 GDD。

#### A4. `[system-slug].md` —— 系统级 GDD（最重要）

**作用**：单个系统的完整设计规格。8 个必填章节齐全，是实现的直接源头。

**谁产出**：`/design-system <system-name>` 技能。按"Specialist Agent Routing"决定谁参与——比如 combat 系统会叫上 game-designer + systems-designer + ai-programmer + art-director。
**何时产出**：Phase 2（系统设计阶段），按 systems-index 的 Recommended Design Order 顺序。

**文件命名**：kebab-case，如 `combat-system.md`、`movement-system.md`、`inventory-system.md`。

**Frontmatter（强制）**：Status / Author / Last Updated / Last Verified / Implements Pillar。

**8 个必填章节**（CLAUDE.md 强约束）：

| # | 章节 | 写什么 | 防什么坑 |
|---|------|--------|---------|
| 1 | Overview | 一段总结 | 没全局观，写跑题 |
| 2 | Player Fantasy | 玩家感受 + 目标 MDA 美学 | 只写机制不写体验 |
| 3 | Detailed Design | Core Rules + States and Transitions + Interactions with Other Systems | 规则含糊、状态遗漏、接口不清 |
| 4 | Formulas | 每个公式四要素：表达式 + 变量表（符号/类型/范围/说明）+ 输出范围 + Worked Example | 公式没法实现、变量没范围 |
| 5 | Edge Cases | 格式 "If [condition]: [outcome]. [rationale]" | 罕见情况没考虑，实现时靠猜 |
| 6 | Dependencies | 双向（depends on / depended on by）+ 接口描述 | 集成时才发现接口对不上 |
| 7 | Tuning Knobs | 表格（旋钮/默认值/范围/分类[feel/curve/gate]/理由） | 数值硬编码、调参无边界 |
| 8 | Acceptance Criteria | Given-When-Then 格式，可独立测试 | 没法验收"做没做完" |

**附加章节**（部分强制）：

- **Game Feel** —— 子节：Feel Reference / Input Responsiveness (ms/frames) / Animation Feel Targets (startup/active/recovery) / Impact Moments / Weight Profile / Feel Acceptance Criteria
- **Visual/Audio Requirements** —— 视觉/动画/特效/音频类系统强制
- **UI Requirements** —— 含真实 UI 需求时强制，会触发 UX Flag
- **Cross-References** —— 表格（系统 / 关系性质[Data dependency/State trigger/Rule dependency/Ownership handoff] / 方向 / 描述）。由 `/review-all-gdds` Phase 2c 机器检查
- **Open Questions** —— 含 owner 和 target resolution date

#### A5. `gdd-cross-review-[date].md` —— GDD 交叉评审报告

**作用**：所有 MVP 系统 GDD 单独评审通过后，做一次"跨 GDD 一致性"总评审，产出报告。

**谁产出**：`/review-all-gdds` 技能（game-designer + systems-designer + creative-director）。
**何时产出**：Phase 2 末（所有 MVP GDD 完成后）。

**重点检查**：Cross-References 表双向一致 / entities.yaml 无冲突 / 接口契约对齐 / 循环依赖识别。

---

## 深入：GDD 文件是怎么从无到有的

上面讲了 `design/gdd/` 下会放哪些文档。这一节回答几个初学者最常问的问题：

- 这些文件是**怎么生成**的？我手动写吗？
- 设计阶段的文档**都放这里**吗？
- 文件的**骨架**哪来的？
- AI 怎么**一步一步引导**我填充这个骨架？
- 流程**是怎样的**？有哪些**机制**在引导？
- 文件**结构**为什么是这个样子？这是**标准流程**吗？

### `design/gdd/` 放哪些文档、不放哪些

先澄清一个容易混淆的点：`design/gdd/` 不是"所有设计文档都丢这里"。它是一个**混合目录**，放三类东西：

| 类型 | 例子 | 遵循 8 章节规则？ |
|------|------|-----------------|
| **系统 GDD**（核心） | `combat-system.md`、`movement-system.md` | ✅ 强制遵循 |
| **元文档**（立项级） | `game-concept.md`、`game-pillars.md`、`systems-index.md` | ❌ 各有专用模板 |
| **审查产物** | `gdd-cross-review-[date].md`、`reviews/[doc]-review-log.md` | ❌ 是报告不是 GDD |

**不放这里的**：

- `quick-specs/`（小改动规格）→ 放 `design/quick-specs/`
- `balance/`（平衡数据/报告）→ 放 `design/balance/`
- `difficulty-curve.md` → 放 `design/` 根目录（注意：不在 gdd 子目录里）
- UX 规范 → 放 `design/ux/`
- 美术圣经 → 放 `design/art/`
- 叙事内容 → 放 `design/narrative/`
- 关卡文档 → 放 `design/levels/`

> ⚠️ **重要**：规则文件 [`.claude/rules/design-docs.md`](file:///workspace/.claude/rules/design-docs.md) 的作用域是 `design/gdd/**`，看起来覆盖整个 gdd 目录。但它"8 个必填章节"的硬性要求**实际只针对系统 GDD**（`[system-slug].md`）。`game-concept.md` 和 `systems-index.md` 虽然物理上在 gdd 目录，但用各自专用模板，不要按 8 章节改写它们。

### GDD 文件不是手动写的，是 `/design-system` 技能引导产出的

你**不需要**手动创建 GDD 文件、也不需要手动填 8 个章节。这一切由 [`/design-system`](file:///workspace/.claude/skills/design-system/SKILL.md) 技能（slash command）引导完成。

整个机制可以用一句话概括：

> **`/design-system` 先建一个"空骨架文件"（所有章节标题 + 占位符），然后逐节带你走"问问题→给选项→你决定→起草→你批准→写入"的循环，直到 8 个章节填满。**

下面把这句话拆开讲。

### 机制 1：文件骨架哪来的——Skeleton-first（骨架先行）

#### 骨架来源

骨架来自一个**模板文件**：[`.claude/docs/templates/game-design-document.md`](file:///workspace/.claude/docs/templates/game-design-document.md)。

但有个**重要细节**：`/design-system` 实际写入磁盘的骨架是模板的**简化版**——它从模板取结构，但只写必填章节的 header + 占位符。完整模板还含 `Summary`、`Game Feel`、`Cross-References` 等额外章节，这些在写完 8 个必填章节后按需补。

#### 骨架长什么样

当你跑 `/design-system combat-system` 并批准创建后，磁盘上会立刻出现这个文件：

```markdown
# Combat System

> **Status**: In Design
> **Author**: [user + agents]
> **Last Updated**: [today's date]
> **Implements Pillar**: [from context]

## Overview
[To be designed]
## Player Fantasy
[To be designed]
## Detailed Design
### Core Rules
[To be designed]
### States and Transitions
[To be designed]
### Interactions with Other Systems
[To be designed]
## Formulas
[To be designed]
## Edge Cases
[To be designed]
## Dependencies
[To be designed]
## Tuning Knobs
[To be designed]
## Visual/Audio Requirements
[To be designed]
## UI Requirements
[To be designed]
## Acceptance Criteria
[To be designed]
## Open Questions
[To be designed]
```

**关键点**：

- 每个章节都**已存在**（标题写好了），但内容是占位符 `[To be designed]`
- 这样文件"一出生就完整"——后续只是把占位符**替换**成真实内容，不会"凭空加章节"
- `Detailed Design` 含 3 个子节（Core Rules / States and Transitions / Interactions），都先占位

#### 创建前的强制询问

骨架**不是偷偷创建的**。`/design-system` 会先问你：

> "May I create the skeleton file at `design/gdd/combat-system.md`?"

你说"可以"才创建。如果你拒绝，技能会判 `BLOCKED`（阻塞）并停下——因为没有骨架文件，后续所有步骤都无从谈起。

#### 创建后立即记录进度

骨架一写入磁盘，技能立刻更新一个进度文件：`production/session-state/active.md`，记三件事：

- Task: Designing combat-system GDD
- Current section: Starting (skeleton created)
- File: design/gdd/combat-system.md

这个文件是**崩溃恢复的命脉**（后面讲）。

#### 为什么用骨架先行而不是写完一整篇再存

来自 [`.claude/rules/design-docs.md`](file:///workspace/.claude/rules/design-docs.md) 第 9 条硬性规定：

> "Design documents MUST be written incrementally: create skeleton first, then fill each section one at a time with user approval between sections. Write each approved section to the file immediately to persist decisions and manage context"

三个原因：

1. **崩溃不丢成果**——每节批准后立即写盘，会话崩溃只丢"当前正在讨论的那一节"，已批准的全在文件里
2. **上下文不爆**——8 节加 2-3 轮修改可能累积 30-50k token 对话。增量写入让实时上下文保持 3-5k（只有当前节的讨论），完成的节"在文件里"不在对话里
3. **决策有据可查**——每节写进文件就是"定稿"，后续节引用它时是引用文件而非模糊的记忆

### 机制 2：逐节填充——Section Cycle（章节循环）

骨架建好后，`/design-system` 对**每个章节**重复一个 7 步循环：

```
Context → Questions → Options → Decision → Draft → Approval → Write
```

| 步骤 | 做什么 | 谁来做 |
|------|--------|--------|
| **Context** | 陈述这一节要写什么；呈现依赖 GDD 中会约束本节的已有决策 | AI |
| **Questions** | 问澄清问题（带约束的选项式问题用 AskUserQuestion 工具，开放式探索用对话） | AI 问，你答 |
| **Options** | 给 2-4 个设计方案 + 各自优缺点 + 参考游戏 + pillar 对齐 | AI |
| **Decision** | 你选一个方案或给自定义方向 | **你** |
| **Draft** | AI 按你的决定起草这一节内容，标注任何临时假设 | AI |
| **Approval** | AI 在**同一响应**里弹出"批准/修改/重来"三选项让你选 | **你** |
| **Write** | 你批准后，AI 用 Edit 工具把占位符替换成真实内容 | AI |

#### 为什么 Draft 和 Approval 必须在同一个响应里

这是**硬性协议**，[SKILL.md 第 332-334 行](file:///workspace/.claude/skills/design-system/SKILL.md)原文：

> "The draft and the approval widget MUST appear together in one response. If the draft appears without the widget, the user is left at a blank prompt with no path forward — this is a protocol violation."

翻译：如果 Draft 单独出现不带批准按钮，你会面对一个空白提示符、无路可走——这是协议违规。所以 AI 起草完必须**立刻**在同一回复里给你批准按钮。

#### 写入时的唯一性约束

每节写入用 Edit 工具替换占位符。但所有节的占位符都是 `[To be designed]`，Edit 要求 `old_string` 唯一匹配。所以必须带上**章节标题**保证唯一：

```
old_string: "## Overview\n\n[To be designed]"
new_string: "## Overview\n\n[批准的内容]"
```

#### 每节写完后

- 更新 `production/session-state/active.md` 记录"刚完成 Overview"
- 检查上下文是否 ≥70%，若是，提示你"进度已存盘，开新会话跑 `/design-system combat-system` 可续写"

### 机制 3：专家路由——Specialist Agent Routing

写不同章节时，`/design-system` 会按**系统类别**叫不同专家（agent）参与。你不用记叫谁，技能自动路由。

#### 路由表（来自 [SKILL.md 第 791-805 行](file:///workspace/.claude/skills/design-system/SKILL.md)）

| 系统类别 | Primary Agent | Supporting Agent(s) |
|---------|---------------|---------------------|
| Foundation/Infrastructure | systems-designer | gameplay-programmer（可行性）、engine-programmer（引擎集成） |
| Combat / damage / health | game-designer | systems-designer（公式）、ai-programmer（敌人 AI）、art-director（受击 VFX） |
| Economy / loot / crafting | economy-designer | systems-designer（曲线）、game-designer（循环） |
| Progression / XP / skills | game-designer | systems-designer（曲线）、economy-designer（sink） |
| Dialogue / quests / lore | game-designer | narrative-director（故事）、writer（内容）、art-director（角色视觉） |
| UI systems | game-designer | ux-designer（流程）、ui-programmer（可行性）、art-director（视觉）、technical-artist（渲染） |
| Audio systems | game-designer | audio-director（方向）、sound-designer（规格） |
| AI / pathfinding | game-designer | ai-programmer（实现）、systems-designer（评分） |
| Level/world systems | game-designer | level-designer（空间）、world-builder（背景） |
| Camera / input / controls | game-designer | ux-designer（手感）、gameplay-programmer（可行性） |
| Animation / character movement | game-designer | art-director（动画风格）、technical-artist（rig/blend）、gameplay-programmer（手感） |
| VFX / particles / shaders | game-designer | art-director（VFX 方向）、technical-artist（性能/shader）、systems-designer（触发集成） |
| Character systems | game-designer | art-director（视觉原型）、narrative-director（角色弧）、systems-designer（属性公式） |

#### 各章节叫谁

| 章节 | 强制 spawn 的 agent |
|------|-------------------|
| Overview | 无强制（有 framing 问题） |
| Player Fantasy | **creative-director**（给 2-3 候选 framing） |
| Detailed Design | **按上表路由 Primary + Supporting** |
| Formulas | **systems-designer**；经济系统额外加 economy-designer |
| Edge Cases | systems-designer；叙事系统额外加 narrative-director |
| Tuning Knobs | 若公式复杂，delegate systems-designer 推导 |
| Acceptance Criteria | **qa-lead**（强制） |
| Visual/Audio（条件性） | 视觉相关系统强制 art-director |

#### Review Mode 影响 agent 是否被叫

| 模式 | agent 行为 |
|------|-----------|
| **full** | 按上表 spawn 所有 agent |
| **lean** | 跳过大部分 agent，**除非**该节是 HIGH risk（Formulas 和 Acceptance Criteria 仍 spawn） |
| **solo** | 全跳过，AI 直接起草，加注"XX agent not consulted — Solo mode" |

#### 专家返回什么、谁写文件

- 专家返回**分析/提案**给主会话（不直接写文件）
- 主会话用 AskUserQuestion 把专家意见呈现给你
- **你决定**，主会话写入文件
- **所有文件写入由主会话独占**——专家只动嘴不动手

### 机制 4：技术可行性预检——Technical Feasibility Pre-Check

在开始写任何章节**之前**，`/design-system` 会做一次技术可行性预检（Phase 2e），防止你设计出引擎做不到的东西。

#### 检查什么

1. **引擎域映射**：把系统类别映射到引擎域（Combat→Physics、UI→UI、Audio→Audio 等）
2. **读引擎上下文**：读 `technical-preferences.md` 识别引擎版本 → 读 `docs/engine-reference/[engine]/VERSION.md` → 读对应域的 modules 文档 → 读 breaking-changes → 读相关 ADR
3. **呈现 Feasibility Brief**：列出"引擎已知能力 / 会约束设计的引擎限制 / 知识缺口（标 HIGH/MEDIUM risk）/ 约束本系统的已有 ADR"

#### 不阻塞但标记缺口

预检**不会阻止**你继续设计——它只是把"这里有知识缺口，写之前确认一下"浮出来。如果引擎还没配置，它会跳过并提示"先跑 `/setup-engine`"。

### 机制 5：实体注册表集成——entities.yaml 冲突检测

[`design/registry/entities.yaml`](file:///workspace/design/registry/entities.yaml) 是跨 GDD 共享事实的"户籍系统"。`/design-system` 在三个时机和它交互：

| 时机 | 做什么 |
|------|--------|
| **Phase 2a（开始前读）** | grep 出 referenced_by/source 含本系统的条目，作为"known facts"——这些值是其他 GDD 已锁定的，本 GDD 不能用不同的数 |
| **Section C/D 写完后（主动检测）** | 扫描刚写入的 Detailed Design 和 Formulas，如果出现已注册的 entity/item/formula/constant 名且**值不同**，立即浮出冲突："Registry conflict: 哥布林血量在 combat.md 注册为 40，你这节写了 35，哪个对？"——不能继续直到解决 |
| **Phase 5b（写完后批量注册）** | 扫描完整 GDD 找新出现的跨系统事实，问你"可以更新 entities.yaml 吗"，同意后追加新条目 + 更新 referenced_by |

**铁律**：绝不静默用不同的数。绝不修改已注册的 value 字段（必须作为冲突浮出）。

### 机制 6：改装模式——Retrofit Mode

如果你已经有一个 GDD 文件（可能是手动写的、或上次没写完），`/design-system` 会进入 **retrofit 模式**而不是重建。

#### 触发条件

- 参数以 `retrofit` 开头：`/design-system retrofit design/gdd/combat-system.md`
- 或参数是 `design/gdd/` 下已存在的 .md 文件路径

#### retrofit 怎么工作

1. 读取已存在的 GDD
2. 扫描 8 个必填章节，识别哪些**已写**（有真实内容）、哪些**缺失**、哪些**只是占位符** `[To be designed]`
3. 呈现 Section Status Table：

```
## Retrofit: Combat System
File: design/gdd/combat-system.md

Sections already written (will not be touched):
✓ Overview
✓ Player Fantasy

Missing or incomplete sections (will be authored):
✗ Detailed Design — missing
✗ Formulas — placeholder only
✗ Edge Cases — missing
```

4. 问你："Shall I fill the [N] missing sections? I will not modify any existing content."
5. 你同意后，**跳过骨架创建**（文件已存在），**只对缺失/占位的章节**走 Section Cycle

#### retrofit 的铁律

> "Never overwrite existing section content. Use Edit tool to replace only `[To be designed]` placeholders or empty section bodies."

只能替换占位符或空 body，**绝不覆盖已写好的内容**。这是防止"AI 自作主张改你的设计"。

### 机制 7：崩溃恢复——Crash Recovery

会话崩溃、上下文压缩、或你关掉重开——`/design-system` 都能从断点续写。

#### 恢复流程

1. 读 `production/session-state/active.md`——它记了"在写哪个系统、已完成哪些节"
2. 读 `design/gdd/[system-name].md`——含真实内容的节是完成的，含 `[To be designed]` 的还要写
3. 从**第一个未完成节**恢复，跳过已完成的——无需重新讨论

#### 为什么能恢复

[SKILL.md 第 827-828 行](file:///workspace/.claude/skills/design-system/SKILL.md)原文：

> "This is why incremental writing matters: every approved section survives any disruption."

增量写入是崩溃恢复的根基——每批准一节就立即写盘，任何中断都不丢已批准内容。

### 机制 8：总监门禁——Director Gate

8 个章节都写完后，`/design-system` 会触发一个**创意总监审查门**：**CD-GDD-ALIGN**（GDD 与支柱对齐检查）。

#### 模式区别

| 模式 | CD-GDD-ALIGN |
|------|--------------|
| **full** | spawn creative-director，审"GDD 是否符合游戏 pillars 和 MDA 目标"，给 APPROVED/CONCERNS/REJECT |
| **lean** | 跳过（不是阻塞性门） |
| **solo** | 跳过 |

#### 审查结果记入 GDD

审查完后，GDD 文件头部的 Status 区域会多一行：

```
> **Creative Director Review (CD-GDD-ALIGN)**: APPROVED 2026-06-30
```

### 机制 9：设计评审的独立性——/design-review

GDD 写完后必须跑 [`/design-review`](file:///workspace/.claude/skills/design-review/SKILL.md) 验证。但有个铁律：

> **绝不能和 `/design-system` 在同一个会话跑。**

[SKILL.md 第 740-747 行](file:///workspace/.claude/skills/design-system/SKILL.md)原文：

> "The reviewing agent must be independent of the authoring context. Running it here would inherit the full design history, making independent critique impossible."

同会话会继承完整设计历史，使独立批判不可能。必须**开新会话**跑 `/design-review design/gdd/[system-name].md`。

#### /design-review 检查什么

- **8 章节完整性**：逐项打勾 `[X/8 sections present]`
- **内部一致性**：公式输出匹配描述、edge cases 不矛盾主规则、依赖双向
- **可实现性**：规则精确到程序员无需猜测、无 hand-wave、考虑性能
- **跨系统一致性**：不与既有机制冲突、与 pillars/基调一致
- **判决**：APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED

### 机制 10：下一个系统——/map-systems next

写完一个 GDD 后，`/design-system` 会问你下一步干啥。如果你想继续写下一个系统的 GDD，用 `/map-systems next`。

#### 它怎么决定下一个写谁

读 [`design/gdd/systems-index.md`](file:///workspace/design/gdd/systems-index.md) 的 **Recommended Design Order**（推荐设计顺序），这个顺序是 `/map-systems` 按"依赖排序 + 优先级"双重排出来的：

1. MVP 的 Foundation 系统优先（事件总线、save/load）
2. MVP 的 Core 系统次之（移动、战斗、背包）
3. MVP 的 Feature 系统第三（进度、经济）
4. Vertical Slice 的系统...
5. 以此类推

`/map-systems next` 挑这个顺序里**最高优先级的"未设计"系统**（Status = Not Started），交给 `/design-system`。

### 完整流程时序：从 `/design-system combat-system` 到 GDD 写完

把上面 10 个机制串起来，完整流程是这样的：

```
你输入: /design-system combat-system
         │
         ▼
┌─ Phase 1: 解析参数 ─────────────────────────────────┐
│ 检测 retrofit? 规范化 system name 为 kebab-case    │
│ 读 review-mode (full/lean/solo)                    │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─ Phase 2: 收集上下文 ──────────────────────────────┐
│ 2a 读 game-concept.md (缺失→fail: 先跑 /brainstorm)│
│    读 systems-index.md (缺失→fail: 先跑 /map-systems)│
│    读 entities.yaml → 提取 known facts (锁定值)    │
│    读 consistency-failures.md → 提取历史教训        │
│ 2b 读依赖 GDD (upstream/downstream)                │
│ 2c 可选读 pillars、已有 GDD (resume)               │
│ 2d 呈现 Context Summary (依赖/约束/锁定值/pillar)  │
│ 2e 技术可行性预检 (引擎域→读引擎文档→Feasibility Brief)│
│    问你 "Ready to start designing combat-system?"  │
└─────────────────────────────────────────────────────┘
         │ 你说 Yes
         ▼
┌─ Phase 3: 创建骨架 ────────────────────────────────┐
│ 问 "May I create skeleton at design/gdd/combat-system.md?"│
│ 你拒绝 → BLOCKED, 停                              │
│ 你同意 → Write 骨架文件 (11 节标题 + [To be designed])│
│ 更新 production/session-state/active.md           │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─ Phase 4: 逐节设计 (Section Cycle × 8+) ───────────┐
│                                                    │
│  Section A: Overview                               │
│    Context→Questions→Options→Decision→Draft→Approval│
│    你批准 → Write 替换占位符 → 更新 active.md      │
│                                                    │
│  Section B: Player Fantasy                         │
│    (full 模式 spawn creative-director)             │
│    Cycle... → Write → 更新 active.md               │
│                                                    │
│  Section C: Detailed Design                        │
│    (按路由表 spawn game-designer + systems-designer │
│     + ai-programmer + art-director)                │
│    Cycle... → Write → entities 冲突检测 → 更新      │
│                                                    │
│  Section D: Formulas                               │
│    (spawn systems-designer; 经济系统加 economy-designer)│
│    Cycle... → Write → entities 冲突检测 → 更新      │
│                                                    │
│  Section E: Edge Cases                             │
│    (spawn systems-designer; 叙事加 narrative-director)│
│    Cycle... → Write → 与依赖 GDD 交叉验证 → 更新    │
│                                                    │
│  Section F: Dependencies                           │
│    (部分预填自 Phase 2)                            │
│    Cycle... → Write → 双向一致性检查 → 更新         │
│                                                    │
│  Section G: Tuning Knobs                           │
│    (公式复杂则 delegate systems-designer)          │
│    Cycle... → Write → 与依赖 GDD 交叉引用 → 更新    │
│                                                    │
│  Section H: Acceptance Criteria                    │
│    (强制 spawn qa-lead)                            │
│    Cycle... → Write → 跨系统验证 → 更新             │
│                                                    │
│  Optional: Visual/Audio (视觉系统强制 art-director) │
│  Optional: UI Requirements (触发 UX Flag)          │
│  Optional: Open Questions                          │
│                                                    │
│  每节后检查 context ≥70% → 提示续写               │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─ Phase 5: 写后验证 ────────────────────────────────┐
│ 5a Self-Check: 从文件读回完整 GDD, 验证 8 节有内容 │
│ 5a-bis CD-GDD-ALIGN (full 模式 spawn creative-director)│
│       记录判决到 GDD Status header                 │
│ 5b Update entities.yaml: 扫描新事实→问你→追加      │
│ 5c Offer Design Review: 指引开新会话跑 /design-review│
│ 5d Update systems-index: 改 Status (Approved/In Review)│
│ 5e Update session-state: 标记完成                  │
│ 5f Suggest Next: 问你下一步 (consistency-check /   │
│    design next system / fix review findings / stop)│
└─────────────────────────────────────────────────────┘
```

### 文件结构为什么是这个样子——这是标准流程吗

#### 8 个必填章节的设计依据

这 8 个章节不是随意定的，每章防一类坑：

| 章节 | 防什么坑 | 如果没有会怎样 |
|------|---------|---------------|
| **Overview** | 没全局观，写到跑题 | 20 个 GDD 没法快速扫描，AI 读 GDD 要全读 |
| **Player Fantasy** | 只写机制不写体验 | 做出来的系统"对但没感觉"，不符支柱 |
| **Detailed Design** | 规则含糊、状态遗漏、接口不清 | 程序员实现时靠猜，集成时才发现接口对不上 |
| **Formulas** | 公式没法实现、变量没范围 | 程序员不知道变量取值范围，平衡师无法调参 |
| **Edge Cases** | 罕见情况没考虑 | 上线后玩家发现"血量为 0 还能行动"等 bug |
| **Dependencies** | 集成时才发现接口对不上 | 系统 A 期望信号、系统 B 期望直接调用 = 集成 bug |
| **Tuning Knobs** | 数值硬编码、调参无边界 | 想调伤害找不到在哪改，改了不知道影响什么 |
| **Acceptance Criteria** | 没法验收"做没做完" | "做完了吗"靠主观判断，QA 无法测 |

#### 这是标准流程吗

**是，但是是"本框架的标准"**，不是行业唯一标准。它的设计融合了：

- **游戏设计行业经验**：8 章节对应行业 GDD 常见要素（Overview/Fantasy/Rules/Formulas/Edge Cases/Dependencies/Tuning/AC）
- **软件工程实践**：Acceptance Criteria 用 Given-When-Then（BDD 风格）；Dependencies 双向一致（类似接口契约）
- **MDA 设计框架**：Player Fantasy 显式要求写"目标 Aesthetics"，从感受倒推机制
- **增量写入 + 上下文管理**：针对 AI 协作场景特有——传统 GDD 没有骨架先行和增量写入，因为人类不需要担心"上下文爆"

> 💡 传统游戏行业的 GDD 往往是"一份大文档随便写"，没有强制 8 章节、没有骨架先行、没有 entities 注册表。这套框架的"标准"是**为 AI 协作场景优化过的**——结构化才能被技能解析、增量写入才能防上下文爆、注册表才能防跨文档冲突。

#### 一处需要注意的命名差异

规则文件 [`.claude/rules/design-docs.md`](file:///workspace/.claude/rules/design-docs.md) 写的是 "Detailed **Rules**"，而模板 [game-design-document.md](file:///workspace/.claude/docs/templates/game-design-document.md) 的实际 header 是 "Detailed **Design**"（其下含 Core Rules / States and Transitions / Interactions 三个子节）。**这是同一节**，只是规则和模板用了不同的名字。初学者别误以为是两节。

### B. `design/quick-specs/` —— 轻量规范

#### B1. `[kebab-title]-[YYYY-MM-DD].md` —— 快速设计规格

**作用**：不值得写整份 8 章节 GDD 的小改动——调数值、加小机制、微调规则。

**谁产出**：`/quick-design "描述"` 技能（game-designer）。
**何时产出**：Phase 2 之后随时——生产中调平衡、加小功能最常用。
**文件命名**：`jump-height-tuning-2026-03-10.md`（标题 + 日期）。

**四种变体**（按 Type 分）：

| 变体 | 用途 | 核心内容 |
|------|------|---------|
| **Tuning** | 调数值 | Change 表（参数/旧值/新值/理由）+ Tuning Knob Mapping + 验收标准 |
| **Tweak** | 微调规则 | Change Summary + Motivation + Design Delta（引用 GDD 原文 + 新规则）+ 影响系统表 |
| **Addition** | 加小功能 | 同 Tweak，但加 New Rules / Values |
| **New Small System** | 精简版新系统 | Overview + Core Rules + Tuning Knobs + 验收标准 + 是否纳入索引建议 |

### C. `design/ux/` —— UX 规范

#### C1. `[screen-slug].md` —— UX 屏幕规格

**作用**：单个 UI 屏幕的完整设计——布局、状态、交互、数据、事件、无障碍。

**谁产出**：`/ux-design screen <name>` 或 `/ux-design <name>`（ux-designer）。
**何时产出**：Phase 4（预制作）。

**15 个章节**：Purpose & Player Need / Player Context on Arrival / Navigation Position / Entry & Exit Points / Layout Specification（Wireframe + Zone Definitions + Component Inventory）/ States & Variants / Interaction Map / Data Requirements / Events Fired / Transition & Animation / Input Method Completeness Checklist（键盘/手柄/鼠标/触摸）/ Screen-Level Accessibility Requirements（对比度/色盲/焦点顺序/屏幕阅读器/认知负荷）/ Localization Considerations / Acceptance Criteria / Open Questions。

#### C2. `hud.md` —— HUD 设计文档

**作用**：抬头显示的完整设计——什么信息常驻、什么按需显示、布局分区、平台适配。

**谁产出**：`/ux-design hud`（ux-designer）。
**何时产出**：Phase 4。

**13 个章节**：HUD Philosophy（含 Visibility principle + Rule of Necessity）/ Information Architecture（Always Show / Contextual / On Demand / Hidden 四档表）/ Layout Zones / HUD Element Specifications / HUD States by Gameplay Context / Information Hierarchy / Visual Budget / Feedback & Notification Systems / Platform Adaptation / Accessibility（色盲模式/文字缩放/动效敏感/字幕/HUD 透明度）/ Tuning Knobs / Acceptance Criteria / Open Questions。

#### C3. `interaction-patterns.md` —— 交互模式库

**作用**：统一所有屏幕的控件标准——避免每个屏幕的按钮、滑块、列表长得不一样。

**谁产出**：`/ux-design patterns`（ux-designer）；后续 `/team-ui` 会把新发明的模式（如 inventory drag-drop）追加进来。
**何时产出**：Phase 4。

**内容**：Standard Control Patterns（16 种：按钮/开关/滑块/下拉/列表项/网格项/模态框/确认框/Toast/Tooltip/进度条/输入框/Tab栏/滚动容器）/ Game-Specific UI Patterns（10 种：库存格/技能图标/血量条/小地图/任务追踪/对话框/上下文动作提示/伤害数字/状态效果图标/通知横幅）/ Navigation Patterns / Feedback and Loading Patterns / Animation Standards（统一 timing 表）/ Sound Standards。

#### C4. `accessibility-requirements.md` —— 无障碍需求文档

**作用**：定项目承诺的"无障碍等级"，所有 UX 规范必须符合。这是 Phase 3 就要定的前置。

**谁产出**：producer + ux-designer 协作。
**何时产出**：Phase 3（技术搭建）——比其他 UX 文档早。

**四档等级**：Basic / Standard / Comprehensive / Exemplary（对应 WCAG 2.1 AA 的 4.5:1 对比度到 AAA 的 7:1）。

**12 个章节**：Accessibility Tier Definition / Visual Accessibility（15 features）/ Motor Accessibility（10 features）/ Cognitive Accessibility（8 features）/ Auditory Accessibility（6 features）/ Platform Accessibility API Integration / Per-Feature Accessibility Matrix / Accessibility Test Plan / Known Intentional Limitations / Audit History / External Resources / Open Questions。

### D. `design/art/` —— 美术规范

#### D1. `art-bible.md` —— 美术圣经

**作用**：统一全游戏视觉风格——色彩、风格、角色标准、环境标准、UI 标准、VFX 标准、资产命名。

**谁产出**：`/art-bible` 技能（art-director，强制 spawn 每个 section）。
**何时产出**：Phase 1 末 / Phase 2 初（在 Technical Setup gate 前必须存在）。

**11 个章节**：Document Status / Visual Identity Summary / Reference Board / Color Palette（含按游戏状态的色彩映射：探索/战斗/安全/危险）/ Art Style / Character Art Standards / Environment Art Standards / UI Art Standards / VFX Standards / Asset Production Standards（命名约定 `[category]_[name]_[variant]_[size].[ext]`）/ Accessibility。

### E. `design/narrative/` —— 叙事内容

#### E1. `characters/[character-slug].md` —— 角色卡

**作用**：单个角色的完整设定——外貌、性格、动机、弧光、对话风格、游戏功能。

**谁产出**：narrative-director + writer。
**何时产出**：Phase 2 / Phase 4。

**10 个章节**：Quick Reference（全名/故事角色/游戏角色/首次出场/状态）/ Concept / Appearance（体型/特征/色彩/服装）/ Personality（核心特质 + 语音特征 + 情感范围）/ Motivation and Arc（主动机 + 角色弧表：引入/发展/结局 + 内心冲突）/ Relationships / Gameplay Function（提供什么 + 遭遇设计）/ Dialogue Notes（话题 + 回避/撒谎 + 状态依赖）/ Lore Connections / Cross-References。

#### E2. `factions/[faction-slug].md` —— 阵营设计文档

**作用**：单个阵营的完整设定——身份、历史、信仰、结构、领地、声誉系统、游戏机制。

**谁产出**：world-builder。
**何时产出**：Phase 2 / Phase 4。

**12 个章节**：Identity（全名/通称/类型/阵营/徽章/颜色/箴言）/ Overview / History / Beliefs and Values / Structure and Leadership / Territory and Resources / Relationships / Reputation System（Hostile → Exalted 六档）/ Gameplay Role（玩家互动 + 独有机制 + 任务线）/ Aesthetic Guide / Lore Consistency Notes / Dependencies。

### F. `design/levels/` —— 关卡设计

#### F1. `[level-name].md` —— 关卡设计文档（LDD）

**作用**：单个关卡的完整设计——布局、遭遇、节奏、音频、视觉、收集品。

**谁产出**：level-designer 智能体（在 `/team-level` 中协作）。必读 combat/progression/narrative GDD。
**何时产出**：Phase 4（首个垂直切片关卡）/ Phase 5（全关卡）。

**9 个章节**：Quick Reference（区域/类型/预估时长/难度/前置/状态）/ Narrative Context / Layout（ASCII 地图含符号 `[S]起点 [E]出口 [C]战斗 [P]谜题 [R]休息 [!]危险 [?]秘密 [>]捷径 [=]锁门 [@]NPC [B]Boss` + 关键路径 + 可选路径 + 兴趣点）/ Encounters（战斗 + 非战斗）/ Pacing Chart（ASCII 强度图）/ Audio Direction / Visual Direction / Collectibles and Secrets / Technical Notes。

### G. `design/balance/` —— 平衡数据

#### G1. `difficulty-curve.md` —— 难度曲线

**作用**：定义全游戏难度如何变化——哲学、维度、曲线、新手引导、锯齿模式、调节杠杆。

**谁产出**：game-designer / systems-designer。
**何时产出**：Phase 4 / Phase 5。

**11 个章节**：Difficulty Philosophy（4 种：受虐向/易上手/服务叙事/休闲）/ Difficulty Axes（执行/知识/资源/时间/决策复杂度表）/ Difficulty Curve Overview（1-10 scale 按阶段）/ Onboarding Ramp / Difficulty Spikes and Valleys（sawtooth pattern + 恢复设计）/ Balancing Levers / Player Skill Assumptions / Accessibility Considerations / Cross-System Difficulty Interactions / Validation Checklist / Open Questions。

#### G2. `economy-model.md` —— 经济模型

**作用**：定义游戏内经济——货币、产出（faucet）、消耗（sink）、平衡目标、进度曲线、掉落表、健康指标。

**谁产出**：economy-designer。
**何时产出**：Phase 4 / Phase 5。

**11 个章节**：Overview / Currencies / Sources (Faucets) / Sinks (Drains) / Balance Targets（含 sink-to-source ratio、首购时间等）/ Progression Curves（等级 XP 表 + 物品价格缩放，含公式）/ Loot Tables（掉落源 + 保底系统）/ Economy Health Metrics（含 Gini coefficient、触顶玩家比例、付费转化率）/ Ethical Guardrails / Simulation Results / Dependencies。

### H. `design/player-journey.md` —— 玩家旅程（根目录级）

**作用**：定义玩家从第一次接触到长期游玩的完整体验旅程——6 个阶段、关键时刻、留存钩子。

**谁产出**：ux-designer 协作。
**何时产出**：Phase 1 末 / Phase 4 初。

**9 个章节**：Journey Overview / Target Player Archetype / Journey Phases（6 个：First Contact 0-5min / Orientation 5-30min / First Mastery 30min-2hr / Depth Discovery 2-10hr / Habitual Play 10-50hr / Long-Term Engagement 50+hr）/ Critical Moments（8-15 个）/ Retention Hooks / Player Progression Feel / Anti-Patterns to Avoid / Validation Questions / Open Questions。

### I. 关联但不在 `design/` 下的文档

这些文档由设计流程触发，但存放在别处：

| 文档 | 存放路径 | 触发技能 | 说明 |
|------|---------|---------|------|
| 架构总文档 | `docs/architecture/architecture.md` | `/create-architecture` | 读所有 GDD 产出，含 System Layer Map |
| ADR | `docs/architecture/adr-NNNN-*.md` | `/architecture-decision` | 每个技术决策一份 |
| TR 注册表 | `docs/architecture/tr-registry.yaml` | `/architecture-review` | TR-ID 编号表 |
| 技术设计文档 | `docs/architecture/[system]-tdd.md` | technical-director | 复杂系统的实现规格 |
| 声音圣经 | `docs/sound-bible.md` | audio-director + sound-designer | 音频方向统一规范 |
| 垂直切片报告 | `prototypes/[concept]-vertical-slice/` | `/vertical-slice` | 含 PROCEED/PIVOT/KILL 判决 |
| 投售文档 | `design/pitch-document.md` | brainstorm 阶段 | 外部沟通用 |
| 反思日志 | `docs/consistency-failures.md` | `/consistency-check` | 记录跨系统冲突的反复模式 |

---

## 文档之间的依赖关系

这些文档不是孤立产出的，有严格的依赖链。理解依赖关系，才知道"为什么必须先写 A 才能写 B"。

### 依赖总图

```
game-concept.md（Phase 1，源头）
    │
    ├──> game-pillars.md（嵌入或独立）
    │
    ├──> art-bible.md（/art-bible 必读 concept 的 Visual Identity Anchor）
    │       │
    │       └──> GDD 的 Visual/Audio Requirements 章节（视觉类系统强制引用）
    │
    ├──> player-journey.md（ux-designer 协作）
    │       │
    │       └──> hud.md（必读 player-journey 来 ground HUD 决策）
    │
    └──> systems-index.md（/map-systems 必读 concept）
            │
            └──> 每个 [system-slug].md GDD（按 Recommended Design Order 顺序）
                    │
                    ├── 双向引用其他 GDD（Dependencies 章节强制 bidirectional）
                    │
                    └── 写入 entities.yaml（Phase 5 后台）
                            │
                            └──> 后续 GDD 必读 entities.yaml 做 conflict check
```

### GDD 内部依赖（5 层从底到顶）

来自 `systems-index.md` 的 Dependency Map：

| 层 | 例子 | 依赖 |
|----|------|------|
| **Foundation Layer** | 事件总线、save/load、场景管理、service locator | 无上游 |
| **Core Layer** | movement / combat / inventory | 依赖 Foundation |
| **Feature Layer** | progression / economy / crafting / dialogue | 依赖 Core |
| **Presentation Layer** | UI / HUD / audio feedback | 依赖 Feature |
| **Polish Layer** | VFX / juice / final feel tuning | 依赖 Presentation |

**双向一致规则**：A 的 Dependencies 引用 B，则 B 的 Dependencies 必须反向引用 A。`/review-all-gdds` 会机器检查这个。

### GDD → UX 文档依赖

```
[system].md GDD 含 UI Requirements 章节
        │
        v
/ux-design 触发 UX Flag
        │
        ├──> hud.md（必读：GDD UI Requirements / game-concept / player-journey /
        │              interaction-patterns / art-bible / accessibility-requirements /
        │              technical-preferences）
        │
        ├──> [screen].md（每个 UI 屏幕）
        │
        └──> interaction-patterns.md（/team-ui 后续追加新模式）
```

### GDD → 关卡 / 叙事 / 平衡依赖

```
combat GDD + progression GDD + economy GDD
        │
        v
balance/difficulty-curve.md（引用上述 GDD）
        │
        v
balance/economy-model.md
        │
        v
levels/[level].md（level-designer 必读 combat/progression/narrative GDD）

narrative GDD + world-builder 产出
        │
        v
narrative/characters/[character].md（引用 GDD 中 Gameplay Function）
        │
        v
narrative/factions/[faction].md
```

### Vertical Slice 的关键依赖

垂直切片是 Phase 4 的"大考"，它的前置条件最多：

```
所有 MVP 系统 GDD + architecture.md + 至少 3 个 Foundation ADR +
accessibility-requirements.md + UX specs + HUD + interaction-patterns
        │
        v
/vertical-slice
        │
        v
vertical-slice-report.md（PROCEED / PIVOT / KILL）
        │
        ├── PROCEED → /gate-check pre-production → Phase 5 Production
        ├── PIVOT   → /design-system 修订受影响 GDD + /architecture-decision 修订 ADR
        └── KILL    → /brainstorm 重新探索
```

---

## 在开发流程中何时碰到 `design/`

把所有设计文档映射到 7 阶段开发流程，每个阶段列出会产出哪些文档、用什么技能、谁负责。

### Phase 1：Concept（概念阶段）—— 立项

| 顺序 | 产出文档 | 技能 | 负责人 | Gate 要求 |
|------|---------|------|--------|-----------|
| 1.1 | `design/gdd/game-concept.md`（含 Visual Identity Anchor） | `/brainstorm` | creative-director + art-director | 必须 |
| 1.2 | `design/gdd/game-pillars.md`（可选独立） | `/brainstorm` | creative-director | pillars 必须存在（嵌入或独立） |
| 1.3 | `design/art/art-bible.md` | `/art-bible` | art-director | Technical Setup gate 前必须存在 |
| 1.4 | `design/gdd/systems-index.md` | `/map-systems` | game-designer | 必须，含依赖排序 |
| 1.5 | `design/player-journey.md`（可在 Phase 1 末或 Phase 4 初） | ux-designer 协作 | ux-designer | 推荐 Phase 1 末完成 |
| 1.6 | （可选）`prototypes/[mechanic]-prototype/` + 报告 | `/prototype` | prototyper | 概念未验证时走 Path B |

**Phase 1 Gate（`/gate-check systems-design`）要求**：引擎配置于 technical-preferences / game-concept.md 存在且含 pillars / systems-index.md 存在且含依赖排序。

### Phase 2：Systems Design（系统设计阶段）—— GDD 集中产出

| 顺序 | 产出文档 | 技能 | 负责人 |
|------|---------|------|--------|
| 2.1 | 每个 MVP 系统一份 `design/gdd/[system-slug].md` | `/design-system [system]` 或 `/map-systems next` | 按 Specialist Agent Routing 表（见附录） |
| 2.2 | 每个 GDD 后写入 `design/registry/entities.yaml` | `/design-system` 自动 | 主会话写入 |
| 2.3 | `design/quick-specs/[title]-[date].md`（小改动） | `/quick-design` | game-designer |
| 2.4 | `design/gdd/gdd-cross-review-[date].md`（所有 MVP GDD 完成后） | `/review-all-gdds` | game-designer + systems-designer + creative-director |
| 2.5 | `design/narrative/characters/[character].md` 角色卡 | narrative-director + writer | narrative-director |
| 2.6 | `design/narrative/factions/[faction].md` 阵营文档 | world-builder | world-builder |
| 2.7 | `docs/consistency-failures.md`（反思日志，持续维护） | `/consistency-check` | 主会话 |

**关键约束**：

- GDD 必须按 systems-index 的 Recommended Design Order 顺序产出（Foundation → Core → Feature → Presentation → Polish）
- 每个 GDD 完成后**必须在新会话**运行 `/design-review`（不能同会话，否则丧失独立评审）
- creative-director 的 CD-GDD-ALIGN gate 在 GDD 完成后强制 spawn（full 模式）

**Phase 2 Gate（`/gate-check technical-setup`）要求**：所有 MVP 系统 GDD 完成 + `/review-all-gdds` PASS。

### Phase 3：Technical Setup（技术搭建阶段）—— 设计转技术

| 顺序 | 产出文档 | 技能 | 负责人 |
|------|---------|------|--------|
| 3.1 | `design/ux/accessibility-requirements.md` | producer + ux-designer 协作 | producer + ux-designer |
| 3.2 | （关联）`docs/architecture/architecture.md` | `/create-architecture` | technical-director |
| 3.3 | （关联）`docs/architecture/adr-NNNN-*.md`（至少 3 个 Foundation ADR） | `/architecture-decision` | technical-director |
| 3.4 | （关联）`docs/architecture/tr-registry.yaml` | `/architecture-review` | technical-director |

> 💡 Phase 3 主要在 `docs/` 下产出，但 `accessibility-requirements.md` 是设计文档，归 `design/ux/`，且它是后续所有 UX 规范的前置。

**Phase 3 Gate（`/gate-check pre-production`）要求**：architecture.md + 至少 3 个 Foundation ADR + accessibility-requirements + tr-registry。

### Phase 4：Pre-Production（预制作阶段）—— UX + 垂直切片

| 顺序 | 产出文档 | 技能 | 负责人 |
|------|---------|------|--------|
| 4.1 | `design/ux/hud.md` | `/ux-design hud` | ux-designer |
| 4.2 | `design/ux/interaction-patterns.md` | `/ux-design patterns` | ux-designer |
| 4.3 | `design/ux/[screen-slug].md`（每个 UI 屏幕） | `/ux-design screen [name]` | ux-designer |
| 4.4 | UX 评审报告（对话中输出 APPROVED / NEEDS REVISION） | `/ux-review` | ux-designer（独立会话） |
| 4.5 | `design/levels/[level-name].md`（首个垂直切片关卡） | level-designer（在 `/team-level` 中） | level-designer |
| 4.6 | （关联）`prototypes/[concept]-vertical-slice/` + `vertical-slice-report.md` | `/vertical-slice` | 全 team 协作 |
| 4.7 | （关联）`production/playtests/[date]-[session].md` | `/playtest-report` | qa-lead |
| 4.8 | （关联）`production/epics/` + `production/stories/` | `/create-epics` → `/create-stories` | producer |

**Phase 4 Gate（`/gate-check production`）要求**：UX specs 完成 + `/ux-review` APPROVED + vertical-slice PROCEED + epics/stories 已规划。

### Phase 5：Production（制作阶段）—— 实现 + 补文档

| 顺序 | 产出文档 | 技能 | 负责人 |
|------|---------|------|--------|
| 5.1 | `design/quick-specs/`（实现中发现的小改动，大量） | `/quick-design` | game-designer |
| 5.2 | 修订版 `design/gdd/[system].md`（如 vertical slice 揭示问题） | `/design-system retrofit` | game-designer |
| 5.3 | `design/balance/difficulty-curve.md` | game-designer / systems-designer | game-designer |
| 5.4 | `design/balance/economy-model.md` | economy-designer | economy-designer |
| 5.5 | `design/narrative/characters/` 全角色卡 | narrative-director + writer | narrative-director |
| 5.6 | `design/narrative/factions/` 全阵营 | world-builder | world-builder |
| 5.7 | `design/levels/` 全关卡 | level-designer | level-designer |
| 5.8 | `design/art/art-bible.md` 修订（如发现视觉不一致） | `/art-bible` 增量更新 | art-director |
| 5.9 | （关联）`docs/sound-bible.md` 声音圣经 | audio-director + sound-designer | audio-director |
| 5.10 | （关联）`docs/architecture/[system]-tdd.md`（复杂系统） | technical-director | technical-director |

### Phase 6：Polish（打磨阶段）—— 调参 + 修文档

| 顺序 | 产出文档 | 技能 | 负责人 |
|------|---------|------|--------|
| 6.1 | `design/quick-specs/`（Tuning 变体，大量调参） | `/quick-design` | game-designer |
| 6.2 | 修订版 GDD 的 Tuning Knobs 章节 | `/design-system retrofit` | game-designer |
| 6.3 | `design/balance/economy-model.md` 持续平衡 | `/balance-check` 验证 | economy-designer |
| 6.4 | `design/balance/difficulty-curve.md` 持续调整 | game-designer | game-designer |

### Phase 7：Release（发布阶段）—— 设计文档已稳定

Phase 7 主要靠技能和 `docs/`，设计文档这时已稳定，不再大量产出。仅可能做本地化交付（从设计文档提取字符串）。

### 全景速查

| 阶段 | `design/` 最活跃的子目录 | 一句话 |
|------|------------------------|--------|
| Phase 1 | `gdd/`（concept, index）、`art/` | 立项，定全局方向 |
| Phase 2 | `gdd/`（各系统 GDD）、`narrative/`、`registry/` | **最密集**——GDD 集中产出 |
| Phase 3 | `ux/`（仅 accessibility） | 设计转技术，定无障碍等级 |
| Phase 4 | `ux/`（全量）、`levels/`（首个） | UX 规范 + 垂直切片 |
| Phase 5 | `balance/`、`levels/`、`narrative/`、`gdd/`（修订） | 实现 + 补平衡/关卡/叙事 |
| Phase 6 | `balance/`、`quick-specs/` | 调参打磨 |
| Phase 7 | （稳定） | 设计文档冻结 |

---

## 现在为什么是"骨架"？

你会注意到：当前 `design/` 只有 `CLAUDE.md` 和 `registry/entities.yaml` 两个文件，`gdd/`、`ux/` 等子目录都不存在。原因：

1. **这是模板项目，不是某个具体游戏**。设计文档是"做某个游戏"时才产生的——比如你决定了"做一个 Roguelike 牌组构建游戏"，才会有 `combat-system.md`、`card-system.md` 这些具体 GDD。
2. **子目录按需创建**。WORKFLOW-GUIDE 里说得很清楚："你不需要 day one 就建好所有目录，做到需要它的阶段再建"。系统会在你跑到对应技能时自动创建。
3. **规范先行**。`CLAUDE.md` 和 `entities.yaml` 是"规则"，规则要先于"内容"存在——这样内容产出时才有规矩可循。

所以**当前状态完全正常**。等你开始 `/brainstorm` 立项、`/design-system` 写 GDD 时，这些子目录就会逐个出现。

---

## 常见误区

**误区 1："我得手动创建 `gdd/`、`ux/` 这些子目录。"**
❌ 不用。技能跑到对应步骤会自动创建。你手动建反而可能建错位置或漏建配置。

**误区 2："entities.yaml 我得自己填。"**
❌ 不要手动编辑。它由 `/design-system`（写 GDD 时）和 `/consistency-check`（解决冲突时）自动维护。手动填容易和 GDD 不同步。

**误区 3："GDD 我想怎么写就怎么写。"**
❌ 不行。[CLAUDE.md](file:///workspace/design/CLAUDE.md) 规定 8 个必填章节且顺序固定。`/design-review` 会校验，缺章节会判 NEEDS REVISION。这 8 个章节是行业经验，漏一个都可能埋雷（比如漏了 Edge Cases，实现时遇到罕见情况就得猜）。

**误区 4："`design/` 和 `docs/` 是一回事。"**
❌ 不是。`design/` 管"做什么、为什么"（游戏设计），`docs/` 管"怎么实现"（技术架构）。GDD 是 ADR 的输入——先有设计决策，才有技术决策。

**误区 5："概念文档（game-concept.md）也是 GDD。"**
⚠️ 不完全是。它放在 `design/gdd/` 下，但它是"立项文档"——定义游戏 pillars、核心循环、目标受众，不是某个系统的 8 章节 GDD。系统的 GDD 是 `combat-system.md` 这种。

**误区 6："GDD 想先写哪个就先写哪个。"**
❌ 不行。必须按 systems-index 的 Recommended Design Order，从 Foundation 层往 Polish 层写。因为上层 GDD 的 Dependencies 章节要引用下层——下层没写，上层没法填依赖。

**误区 7："art-bible 是 Phase 4 才需要的，可以晚点写。"**
❌ 不行。art-bible 在 Phase 1 末 / Phase 2 初就要产出，在 Technical Setup gate 前必须存在。因为 Phase 2 写视觉类系统的 GDD 时，Visual/Audio Requirements 章节要强制引用 art-bible。art-bible 晚了会卡住 GDD。

**误区 8："`/design-review` 可以和 `/design-system` 在同一个会话跑。"**
❌ 不行。评审必须独立于创作上下文——同一会话跑会让评审智能体"既当运动员又当裁判"，丧失独立性。每个 GDD 写完后**必须开新会话**跑 `/design-review`。

**误区 9："vertical slice 失败了就得推倒重来。"**
⚠️ 不一定。vertical-slice-report 给三档判决：PROCEED（继续进生产）/ PIVOT（改设计/架构后再切片）/ KILL（项目不可行，重新 brainstorm）。PIVOT 是最常见的——只改受影响的 GDD 和 ADR，不是全推倒。

**误区 10："entities.yaml 只是参考，写 GDD 时不用管它。"**
❌ 必须管。`/design-system` 在 Phase 2（gather context）必读 entities.yaml，写完 Section C（Detailed Design）和 Section D（Formulas）后还要再查一次冲突。值冲突必须立即暴露，不能静默用不同数字。

---

## 附录：智能体与文档产出对应关系

写 GDD 时不是 game-designer 一个人干，不同系统会叫不同专家。这张表来自 `/design-system` 技能的 Specialist Agent Routing：

| 系统类别 | Primary Agent | Supporting Agent(s) |
|---------|---------------|---------------------|
| Foundation/Infrastructure | systems-designer | gameplay-programmer（可行性）、engine-programmer（引擎集成） |
| Combat / damage / health | game-designer | systems-designer（公式）、ai-programmer（敌人 AI）、art-director（受击反馈 VFX） |
| Economy / loot / crafting | economy-designer | systems-designer（曲线）、game-designer（循环） |
| Progression / XP / skills | game-designer | systems-designer（曲线）、economy-designer（sink） |
| Dialogue / quests / lore | game-designer | narrative-director（故事）、writer（内容）、art-director（角色视觉） |
| UI systems (HUD/menus) | game-designer | ux-designer（流程）、ui-programmer（可行性）、art-director（视觉）、technical-artist（渲染约束） |
| Audio systems | game-designer | audio-director（方向）、sound-designer（规格） |
| AI / pathfinding | game-designer | ai-programmer（实现）、systems-designer（评分） |
| Level/world systems | game-designer | level-designer（空间）、world-builder（lore） |
| Camera / input / controls | game-designer | ux-designer（手感）、gameplay-programmer（可行性） |
| Animation / character movement | game-designer | art-director（动画风格）、technical-artist（rig/blend）、gameplay-programmer（手感） |
| VFX / particles / shaders | game-designer | art-director（VFX 方向）、technical-artist（性能/着色器）、systems-designer（触发集成） |

各智能体分工边界（来自智能体定义）：

| 智能体 | 汇报给 | 产出文档 | 不产出 |
|--------|--------|---------|--------|
| **game-designer** | creative-director | GDD、game-concept、systems-index、difficulty-curve、quick-specs | 实现代码、美术/音频方向、架构选型 |
| **systems-designer** | creative-director + technical-director | GDD 的 Formulas/Edge Cases/Tuning Knobs 章节、economy-model 的曲线 | 高层设计方向、代码、关卡、叙事 |
| **narrative-director** | creative-director | story bible、character arcs、narrative GDD、faction overview | 单行 dialogue（委托 writer）、玩法机制决策 |
| **level-designer** | game-designer | `levels/[level].md`（layout/encounter/pacing） | 游戏级系统、故事决策、引擎实现 |
| **ux-designer** | art-director + game-designer | `ux/hud.md`、`ux/[screen].md`、`ux/interaction-patterns.md`、player-journey、accessibility | 视觉风格决策、UI 代码、玩法机制 |
| **world-builder** | narrative-director | `narrative/factions/`、lore 数据库、历史时间线 | 玩家面向文本（委托 writer）、玩法机制 |
| **writer** | narrative-director | dialogue、lore entries、item descriptions、barks | 故事/角色弧决策、代码、quest 设计 |

---

## 小测验

**Q1**：你让 AI 帮你写战斗系统的 GDD，它只写了 5 个章节就存盘了。哪个文件规定了必须有 8 个章节？

<details>
<summary>答案</summary>

[design/CLAUDE.md](file:///workspace/design/CLAUDE.md)——它规定 GDD 必须包含 8 个必填章节（Overview / Player Fantasy / Detailed Design / Formulas / Edge Cases / Dependencies / Tuning Knobs / Acceptance Criteria）且顺序固定。`/design-review` 会校验，缺章节判 NEEDS REVISION。

</details>

**Q2**：你的战斗 GDD 里写"哥布林血量 40"，物品 GDD 里却写"哥布林血量 35"。哪个文件能帮 AI 在写第二个 GDD 时就发现冲突？

<details>
<summary>答案</summary>

[design/registry/entities.yaml](file:///workspace/design/registry/entities.yaml)——它的 `entities` 段登记跨 GDD 共享的实体。`/design-system` 写新 GDD 前会先 grep 它，发现"哥布林"已存在（source 是 combat.md，血量 40）就会引用而不是重写，避免数值不一致。

</details>

**Q3**：你想加一个小改动"侧翼攻击加 10% 伤害"，不值得写整份 GDD。该用什么技能、产物放哪？

<details>
<summary>答案</summary>

用 `/quick-design "侧翼攻击加 10% 伤害"`，产物放在 `design/quick-specs/` 下，文件名如 `flanking-bonus-2026-06-30.md`。这是 Tuning 变体的 quick-spec，含 Change 表（参数/旧值/新值/理由）+ 验收标准。

</details>

**Q4**：`design/` 和 `docs/` 都有 `registry/` 下的 yaml 文件。它们分别管什么？

<details>
<summary>答案</summary>

- [design/registry/entities.yaml](file:///workspace/design/registry/entities.yaml) 管跨 GDD 的**设计事实**（实体、物品、公式、常量）——防"哥布林血量两个文档写不一样的数"。
- [docs/registry/architecture.yaml](file:///workspace/docs/registry/architecture.yaml) 管跨 ADR 的**技术约束**（状态归属、接口契约、性能预算、API 选择、禁止模式）——防"两个 ADR 都说自己管玩家血量"。

机制一样（永久 ID、source/referenced_by、不删只标 deprecated），领域不同。

</details>

**Q5**：你在 Phase 2 写 movement GDD 时，Dependencies 章节引用了 inventory GDD。但 inventory GDD 还没写。这违反了什么规则？

<details>
<summary>答案</summary>

违反了 **5 层依赖顺序**和 **Recommended Design Order**。movement 属于 Core 层，inventory 也属于 Core 层——同层之间引用可以，但 systems-index 会排好顺序，不能跳着写。如果 inventory 排在 movement 后面，说明 movement 不该依赖 inventory（或者依赖关系画反了，该改 systems-index）。`/review-all-gdds` 会机器检查 Cross-References 表的双向一致性。

</details>

**Q6**：你的游戏概念里写了"核心幻想是孤独的太空探险者"，但玩法系统却强推多人组队。这违反了哪个设计原则？

<details>
<summary>答案</summary>

违反了 **Ludonarrative Harmony（玩法-叙事和谐）**。故事说"孤独探险"，玩法奖励"组队"——这是 ludonarrative dissonance（不和谐）。也间接违反了 Pillars——如果"孤独"是支柱之一，多人玩法就直接违反支柱，game-designer 写 GDD 时该被 CD-GDD-ALIGN gate 挡下。

</details>

**Q7**：你跑完 `/vertical-slice`，报告判了 PIVOT。接下来该做什么？

<details>
<summary>答案</summary>

PIVOT 意味着"改设计或架构后再切片"。具体步骤：

1. 看 vertical-slice-report 里指出的"Pipeline blockers / Architecture surprises / Critical fun blockers"
2. 对受影响的系统跑 `/design-system retrofit design/gdd/[system].md` 修订 GDD
3. 对受影响的技术决策跑 `/architecture-decision` 修订 ADR
4. 修订后重跑 `/vertical-slice` 验证

不是推倒重来——只改受影响的部分。

</details>

**Q8**：写 combat GDD 时，谁负责写公式？谁负责写敌人 AI？谁负责写受击 VFX 方向？

<details>
<summary>答案</summary>

来自 Specialist Agent Routing 表：

- **公式**：systems-designer（Supporting）
- **敌人 AI**：ai-programmer（Supporting）
- **受击 VFX 方向**：art-director（Supporting）
- **Primary**：game-designer（主导整个 GDD）

`/design-system` 会按系统类别自动 spawn 这些 Supporting agent。

</details>

**Q9**：你跑 `/design-system combat-system`，AI 直接写了 8 个章节的完整内容存盘，全程没问你。这违反了什么？

<details>
<summary>答案</summary>

违反了多条：

1. **协作五步**（Question→Options→Decision→Draft→Approval）：没有问问题、没有给选项、没有等你决定和批准
2. **"May-I-write" 协议**：创建骨架文件前没问"可以创建吗"，每节写入前没问"可以写吗"
3. **Section Cycle**：每节必须走 Context→Questions→Options→Decision→Draft→Approval→Write，不能跳过
4. **[.claude/rules/design-docs.md](file:///workspace/.claude/rules/design-docs.md) 第 9 条**："create skeleton first, then fill each section one at a time **with user approval between sections**"

这是典型的 **Autonomous Generator**（自主生成器）行为，被 [COLLABORATIVE-DESIGN-PRINCIPLE.md](file:///workspace/docs/COLLABORATIVE-DESIGN-PRINCIPLE.md) 明令禁止。

</details>

**Q10**：你的 combat GDD 写到 Formulas 章节时，AI 发现你写的"哥布林血量 35"和 entities.yaml 里注册的"哥布林血量 40"冲突。AI 该怎么做？

<details>
<summary>答案</summary>

**立即浮出冲突，不能继续到下一节**。AI 应该说："Registry conflict: 哥布林血量在 combat.md 注册为 40（source: design/gdd/combat.md），你这节写了 35。哪个对？"

- 如果你确认 35 对 → 需要更新 entities.yaml 的值（设 revised 日期、注释保留旧值）
- 如果 40 才对 → 改你这节的内容
- **绝不能静默用不同的数继续往下写**

这是 entities.yaml 的铁律：绝不静默用不同的数，绝不修改已注册的 value 字段而不作为冲突浮出。

</details>

**Q11**：你有个半成品 GDD（Overview 和 Player Fantasy 已写，其余是 `[To be designed]`）。你想继续写完它。该用什么命令？AI 会怎么处理已写的两节？

<details>
<summary>答案</summary>

用 `/design-system retrofit design/gdd/[system].md`（或直接传文件路径，技能会检测已存在文件自动进入 retrofit 模式）。

AI 会：
1. 读取文件，扫描 8 个必填章节
2. 呈现 Section Status Table：✓ Overview、✓ Player Fantasy（已写，**不会碰**）；✗ 其余 6 节（缺失或占位符）
3. 问你"Shall I fill the 6 missing sections? I will not modify any existing content."
4. 你同意后，**跳过骨架创建**，只对 6 个缺失节走 Section Cycle

**铁律**：retrofit 绝不覆盖已写内容，只能替换 `[To be designed]` 占位符或空 body。

</details>

**Q12**：你跑完 `/design-system` 写完 GDD，想紧接着在同一会话跑 `/design-review` 验证。这行吗？

<details>
<summary>答案</summary>

**不行**。[SKILL.md 第 740-747 行](file:///workspace/.claude/skills/design-system/SKILL.md)明确："Never run `/design-review` in the same session as `/design-system`. The reviewing agent must be independent of the authoring context."

同会话会继承完整的设计历史上下文，使独立批判不可能——评审智能体"既当运动员又当裁判"。必须**开新会话**跑 `/design-review design/gdd/[system-name].md`。

`/design-system` 在 Phase 5c 会明确指引用户开新会话，绝不在线运行 `/design-review`。

</details>

---

## 动手

1. 打开 [design/CLAUDE.md](file:///workspace/design/CLAUDE.md)，数一下 GDD 的 8 个必填章节，想想每个章节防的是什么坑（比如 Edge Cases 防"罕见情况没考虑"）。
2. 打开 [design/registry/entities.yaml](file:///workspace/design/registry/entities.yaml)，读注释里的示例条目（goblin、goblin_arm、damage_formula、gold_carry_limit），理解"source 是权威 GDD，referenced_by 是引用方"的关系。
3. 对比 [design/registry/entities.yaml](file:///workspace/design/registry/entities.yaml) 和 [docs/registry/architecture.yaml](file:///workspace/docs/registry/architecture.yaml)——看它们的注释结构有多像，体会"设计事实"和"技术约束"的分工。
4. 翻 [docs/WORKFLOW-GUIDE.md](file:///workspace/docs/WORKFLOW-GUIDE.md) 的 Phase 2 部分，看 `/design-system` 怎么一节一节产出 GDD 并更新 entities 注册表。
5. 打开 [.claude/docs/templates/game-concept.md](file:///workspace/.claude/docs/templates/game-concept.md)，看概念文档的 16 个章节，特别是 Core Loop（嵌套循环）和 MVP Definition（Scope Tiers）。
6. 打开 [.claude/docs/templates/game-design-document.md](file:///workspace/.claude/docs/templates/game-design-document.md)，对照 8 个必填章节的详细要求，注意 Formulas 章节强制四要素（表达式 + 变量表 + 输出范围 + Worked Example）。对比实际写入的简化骨架（本文档"骨架长什么样"那一节），理解为什么简化。
7. 读 [docs/examples/session-design-system-skill.md](file:///workspace/docs/examples/session-design-system-skill.md)，看一个真实的 GDD 产出会话——验证 skeleton-first、section cycle、崩溃恢复怎么落地。
8. 读 [docs/examples/session-ux-pipeline.md](file:///workspace/docs/examples/session-ux-pipeline.md)，看 `/ux-design` → `/ux-review` → `/team-ui` 三段式流程，理解"BLOCKING vs ADVISORY"区分。
9. 打开 [.claude/skills/design-system/SKILL.md](file:///workspace/.claude/skills/design-system/SKILL.md) 的 Phase 3（创建骨架，约第 213-298 行）和 Phase 4 Section Cycle（约第 301-344 行），对照本文档的"机制 1"和"机制 2"，验证骨架内容和 7 步循环的精确条文。
10. 读 [.claude/rules/design-docs.md](file:///workspace/.claude/rules/design-docs.md) 的 9 条规则，特别注意第 9 条"create skeleton first, then fill each section one at a time with user approval between sections"——这是骨架先行 + 增量写入的法律依据。

---

## 一句话带走

> **`design/` = 游戏的"设计大脑"。现在只有写作规范（CLAUDE.md）和实体登记册（entities.yaml）两个骨架文件，将来会按需长出 GDD、UX 规范、quick-specs、叙事、关卡、平衡等子目录。规范先行、内容后填——规则立好了，技能产出内容时才不会跑偏。实际做游戏时，Phase 1 产概念和系统索引，Phase 2 集中产 GDD（最密集），Phase 4 产 UX 和垂直切片，Phase 5-6 产关卡/平衡/叙事并持续修订。所有文档有严格依赖链——从 game-concept 一路倒推到关卡和平衡数据。**
>
> **GDD 文件不是手动写的，是 `/design-system` 技能引导产出的：先建空骨架（所有章节标题 + `[To be designed]` 占位符），再对每节走"问问题→给选项→你决定→起草→你批准→写入"的 Section Cycle，配合专家路由、entities 冲突检测、技术可行性预检、崩溃恢复、retrofit 改装等 10 大机制，直到 8 个必填章节填满。这套流程是"为 AI 协作场景优化过的标准"——结构化才能被技能解析、增量写入才能防上下文爆、注册表才能防跨文档冲突。**
