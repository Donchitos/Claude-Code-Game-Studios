# 20 · .claude/docs 目录指南

## 这篇文档解决什么问题

[第 15 篇](file:///workspace/study-docs/15-docs目录指南.md) 讲的是项目根目录下的 `docs/`（引擎字典、注册表、案例库）。这篇专门讲 **`.claude/docs/`**——它藏在 `.claude/` 配置目录里，是整套智能体工作室的**"操作手册室"**。

读完这篇你会明白：

- `.claude/docs/` 里每个文件是干什么的（作用）
- 怎么用它（如何使用）
- 为什么需要它（为什么要用）
- 在 7 阶段开发流程的什么时候会碰到它（开发流程中何时被使用）

---

## 一句话定位

> **`.claude/docs/` 存的是"让 49 个智能体、73 个技能、12 个钩子能协调运转"的规则手册：谁干什么、怎么委派、写代码守什么规矩、长会话怎么不失忆、写文档套哪个模板。**

它和项目根 `docs/` 的分工是：

| 目录 | 性质 | 谁读它 |
|------|------|--------|
| `docs/`（根目录） | **项目内容**的参考资料——引擎 API、注册表、案例 | AI 写代码/写架构时查 |
| `.claude/docs/` | **编排骨架**的操作规则——协作规则、模板、流程目录 | AI 决定"怎么干活"时读 |

一句话：`docs/` 告诉 AI"游戏该长啥样"，`.claude/docs/` 告诉 AI"团队该怎么干"。

---

## 类比：把 `.claude/docs/` 想象成游戏公司的"行政办公室"

想象你走进一家游戏公司的行政办公室，里面有这些柜子：

| 办公室里的柜子 | 对应 `.claude/docs/` 里的文件 | 你什么时候去翻 |
|--------------|----------------------------|--------------|
| 门口贴的《新员工手册》 | [quick-start.md](file:///workspace/.claude/docs/quick-start.md) | 第一天上班，想知道公司怎么运作 |
| 墙上挂的《组织架构图》 | [agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md) | 想知道"这事该找哪个部门" |
| 《员工花名册》 | [agent-roster.md](file:///workspace/.claude/docs/agent-roster.md) | 想知道"每个岗位有谁、什么级别" |
| 《部门协作规章》 | [coordination-rules.md](file:///workspace/.claude/docs/coordination-rules.md) | 想知道"部门之间怎么配合、谁能指挥谁" |
| 《总监审批清单》 | [director-gates.md](file:///workspace/.claude/docs/director-gates.md) | 想知道"总监什么时候要签字、签什么" |
| 《代码规范手册》 | [coding-standards.md](file:///workspace/.claude/docs/coding-standards.md) | 写代码前，要知道守什么规矩 |
| 《项目专属偏好表》 | [technical-preferences.md](file:///workspace/.claude/docs/technical-preferences.md) | 要知道"这个项目用哪个引擎、命名怎么定" |
| 《按目录生效的规章》 | [rules-reference.md](file:///workspace/.claude/docs/rules-reference.md) | 想知道"在哪个目录写代码，自动套哪条规则" |
| 《长会话不失忆手册》 | [context-management.md](file:///workspace/.claude/docs/context-management.md) | 会话很长，怕 AI 忘事 |
| 《73 个斜杠命令索引》 | [skills-reference.md](file:///workspace/.claude/docs/skills-reference.md) | 想知道"有哪些命令可以跑" |
| 《7 阶段流程目录》 | [workflow-catalog.yaml](file:///workspace/.claude/docs/workflow-catalog.yaml) | `/help` 靠它判断"现在到哪步了" |
| 《项目目录结构图》 | [directory-structure.md](file:///workspace/.claude/docs/directory-structure.md) | 想知道"文件该放哪" |
| 《环境准备清单》 | [setup-requirements.md](file:///workspace/.claude/docs/setup-requirements.md) | 装环境，想知道要装什么 |
| 《代码评审流程》 | [review-workflow.md](file:///workspace/.claude/docs/review-workflow.md) | 改了东西，谁要审 |
| 《钩子总览》 | [hooks-reference.md](file:///workspace/.claude/docs/hooks-reference.md) | 想知道"哪些操作会自动触发校验" |
| 《钩子详解》柜子 | [hooks-reference/](file:///workspace/.claude/docs/hooks-reference/) | 想看某个钩子的具体实现 |
| 《文档模板》柜子 | [templates/](file:///workspace/.claude/docs/templates/) | 要写 GDD/ADR/测试计划，先拿模板 |
| 《个人配置》模板柜 | [CLAUDE-local-template.md](file:///workspace/.claude/docs/CLAUDE-local-template.md)、[settings-local-template.md](file:///workspace/.claude/docs/settings-local-template.md) | 想做只属于自己的本地配置 |

记住这张表，下面逐个拆。

---

## 全景地图

```
.claude/docs/
├── quick-start.md                 # 快速上手指南（新手第一篇）
├── agent-roster.md                # 49 个智能体花名册（三层 + 引擎专家）
├── agent-coordination-map.md      # 组织架构图 + 委派规则 + 9 种工作流模式
├── coordination-rules.md          # 协作规则 5 条 + 模型分级 + 并行协议
├── director-gates.md              # 总监门禁（25 个门禁 ID + 三种评审模式）
├── coding-standards.md            # 代码/设计文档/测试三大标准
├── technical-preferences.md       # 项目专属偏好（由 /setup-engine 填充）
├── rules-reference.md             # 11 条按路径生效的规则索引
├── context-management.md          # 上下文管理：文件即记忆 + 增量写入 + 压缩恢复
├── skills-reference.md            # 73 个斜杠命令按阶段分类索引
├── workflow-catalog.yaml          # 7 阶段流水线定义（/help 读它）
├── directory-structure.md         # 项目目录布局
├── setup-requirements.md          # 环境依赖（Git/jq/Python/Bash）
├── review-workflow.md             # 评审流程 4 条
├── hooks-reference.md             # 12 个钩子总览表
├── hooks-reference/               # 钩子详解（6 篇）
│   ├── hook-input-schemas.md      #   钩子收到的 JSON 数据格式
│   ├── pre-commit-code-quality.md #   提交前代码质量检查
│   ├── pre-commit-design-check.md #   提交前设计文档检查
│   ├── pre-push-test-gate.md      #   推送前测试门禁
│   ├── post-merge-asset-validation.md  # 合并后资产校验
│   └── post-sprint-retrospective.md    # 冲刺后回顾
├── templates/                     # 38 个文档模板 + 3 个协作协议
│   ├── collaborative-protocols/   #   智能体协作协议（设计/实现/领导三层）
│   ├── game-design-document.md    #   GDD 模板（8 必填章节）
│   ├── architecture-decision-record.md  # ADR 模板
│   └── ... (35 个其他模板)
├── CLAUDE-local-template.md       # 个人 CLAUDE.local.md 模板
└── settings-local-template.md     # 个人 settings.local.json 模板
```

---

## 术语速查表（先读这节，后面才看得懂）

`.claude/docs/` 里塞满了智能体编排、软件工程的术语。初学者最容易卡住的术语这里讲清楚。

> 💡 这张表和 [第 13 篇术语表](file:///workspace/study-docs/13-术语对照表.md) 互补：第 13 篇是全项目术语总表，这里只讲 `.claude/docs/` 语境下的要点。

### A. 智能体编排术语

| 术语 | 字面 / 全称 | 内涵 | 类比 |
|------|------------|------|------|
| **Agent** | 智能体 | 一个有专门职责的 AI 角色，定义在 `.claude/agents/` 里。49 个智能体模拟一个游戏工作室。 | 公司里的一个岗位 |
| **Tier 1/2/3** | 三层层级 | 智能体分三层：Tier 1 总监（Opus 模型，做高层决策）、Tier 2 主管（Sonnet，管一个部门）、Tier 3 专家（Sonnet/Haiku，执行具体活）。 | 总监→经理→员工 |
| **Opus / Sonnet / Haiku** | （模型名） | Claude 的三个模型档次：Opus 最强最贵（多文档综合、高风险判断）、Sonnet 中等（默认主力）、Haiku 最轻最便宜（只读查询、格式化）。 | 高级顾问 / 资深员工 / 实习生 |
| **Delegation** | 委派 | 上级智能体把任务交给下级。规则：只能往下一层委派，不能跨层（总监不直接指挥专家）。 | 经理把活派给员工 |
| **Escalation** | 升级 | 下级解决不了的冲突往上报。两个专家意见不合 → 找共同的主管；主管也定不了 → 找总监。 | 员工搞不定找经理，经理定不了找总监 |
| **Subagent** | 子智能体 | 主会话用 `Task` 工具临时召唤的智能体，跑在独立上下文里，干完活把结果摘要返回。 | 临时叫人来帮忙，干完就走 |
| **Agent Team** | 智能体团队（实验性） | 多个独立的 Claude Code 会话同时跑，靠共享任务列表协调。需开环境变量开启。 | 多个独立工位同时开工 |
| **Coordinator / Orchestrator** | 协调者 / 编排者 | 主会话的角色——调度子智能体、收集结果、在决策点请用户定夺。 | 项目经理 |

### B. 门禁与评审术语（来自 [director-gates.md](file:///workspace/.claude/docs/director-gates.md)）

| 术语 | 字面 / 全称 | 内涵 | 类比 |
|------|------------|------|------|
| **Gate** | 门禁 | 工作流关键节点的检查点，由总监智能体执行。过了才能继续。 | 楼层验收——不签字不上下一层 |
| **Gate ID** | 门禁 ID | 形如 `CD-PILLARS`、`TD-ARCHITECTURE`。前缀代表总监（CD=创意总监、TD=技术总监、PR=制作人、AD=美术总监、LP=主程、QL=QA 主管、ND=叙事总监）。 | 检查单上的编号项 |
| **Verdict** | 判决 | 门禁的三种结果：APPROVE/READY（通过）、CONCERNS（有顾虑但不阻塞）、REJECT/NOT READY（阻塞，不能继续）。 | 验收意见：合格/有瑕疵/不合格返工 |
| **Phase Gate** | 阶段门 | 7 阶段之间的门禁（`/gate-check`），四位总监并行评审，取最严判决。 | 大工序之间的总验收 |
| **Review Mode** | 评审模式 | 三档：`full`（每步都审）、`lean`（只审阶段门，默认）、`solo`（全跳过，冲刺用）。 | 严审/简审/免审 |
| **Parallel Spawning** | 并行召唤 | 同一门禁点同时召唤多个总监（如阶段门同时召唤 4 位），加快速度。 | 多个监理同时验收 |

### C. 软件工程术语（来自 [coding-standards.md](file:///workspace/.claude/docs/coding-standards.md) 等）

| 术语 | 字面 / 全称 | 内涵 | 类比 |
|------|------------|------|------|
| **Conventional Commits** | 约定式提交 | 提交信息格式：`feat:` 新功能、`fix:` 修 bug、`chore:` 杂务、`docs:` 文档、`test:` 测试、`refactor:` 重构。机器可解析。 | 快递单上的"品类"标签 |
| **Data-driven** | 数据驱动 | 玩法数值（伤害、血量、速度）不放代码里，放外部配置文件（JSON/YAML）。改数值不用改代码。 | 菜谱和食材分开——换配方不动锅 |
| **Dependency Injection** | 依赖注入 | 不在代码里直接 new 一个对象，而是从外面传进来。好处：好测（测试时传假的）。 | 不自己买工具，公司发什么用什么 |
| **Verification-driven dev** | 验证驱动开发 | 标记完成前必须有证据：玩法系统写测试、UI 改动截图对比。 | 作业写完要对答案 |
| **TR-ID** | 技术需求 ID | 见 [第 15 篇](file:///workspace/study-docs/15-docs目录指南.md)，需求→架构→故事的追溯编号。 | 物流单号 |
| **ADR** | 架构决策记录 | 每个技术决策一份文档，记"为什么选这个、放弃了什么、后果是什么"。 | 决策备忘录 |

### D. 上下文管理术语（来自 [context-management.md](file:///workspace/.claude/docs/context-management.md)）

| 术语 | 字面 / 全称 | 内涵 | 类比 |
|------|------------|------|------|
| **Context** | 上下文 | AI 一次能"记住"的内容总量，有上限（token 预算）。超了就要压缩。 | AI 的"工作记忆"，像桌面大小 |
| **Compaction** | 压缩 | 上下文快满时，系统自动把早期对话总结成摘要，腾出空间。 | 桌面满了，把旧文件归档 |
| **File-backed state** | 文件即记忆 | 核心策略：重要决策写进文件，不靠对话记住。文件比对话持久。 | 记笔记本，不靠脑子 |
| **Session state** | 会话状态 | `production/session-state/active.md`，记录"当前在干啥、到哪了"。会话崩溃后靠它恢复。 | 便利贴——记当前进度 |
| **Incremental writing** | 增量写入 | 长文档（如 GDD）先建骨架，再一节节讨论、一节节写盘。每节写完就存，不攒到最后。 | 盖楼——浇一层干一层 |

---

## 逐个讲解

为方便理解，把 17 个主文件 + 2 个子目录分成 6 组来讲。

---

### 第 1 组：入门与导航

#### 1. `quick-start.md` —— 快速上手指南

**作用**：这是 `.claude/docs/` 的"新员工手册"。它用一篇文档讲清楚整套架构是什么、智能体怎么分层、73 个命令能干啥、41 个模板在哪、5 条协作规则是什么。**新手第一篇就读这个。**

**关键内容**（来自 [quick-start.md](file:///workspace/.claude/docs/quick-start.md)）：

- 三层智能体层级（Tier 1 总监 / Tier 2 主管 / Tier 3 专家）
- "我需要干 X，该用哪个智能体"对照表（30+ 场景）
- 73 个斜杠命令速查表（按用途分组）
- 模板清单（41 个）
- 4 条入门路径（Path A/B/C/D，对应"没想法/有想法/有概念没引擎/已有项目"）
- 5 条协作规则（工作往下流、冲突往上交、跨部门靠 producer、不越权、决策要留档）

**如何使用**：

- **第一次用这个项目**：从头到尾读一遍，建立全局观
- **想找命令**：翻"Slash Commands"表
- **不知道用哪个智能体**：翻"I need to..."表
- **不知道从哪开始**：看"First Steps for a New Project"的 4 条路径

**为什么要用**：没有它，49 个智能体和 73 个命令就是一堆散装零件，你不知道哪个配哪个。它把零件拼成"能上手的东西"。

**开发流程中何时被使用**：**开始前**。新手第一次接触项目时读。之后偶尔查命令或智能体对照表。

---

#### 2. `skills-reference.md` —— 73 个命令索引

**作用**：把 73 个斜杠命令（如 `/brainstorm`、`/dev-story`）按**阶段和用途**分类列成表，每个命令一句话说明。比 quick-start 里的命令表更全、更细。

**关键内容**（来自 [skills-reference.md](file:///workspace/.claude/docs/skills-reference.md)）：

命令分 11 类：入门导航、游戏设计、美术资产、UX 设计、架构、故事与冲刺、评审与分析、QA 测试、生产管理、发布、创意内容、团队编排。

**如何使用**：

- 想跑某个命令但记不住名字：来这里按用途找
- 想知道某阶段有哪些命令：看分类
- `/team-*` 系列在这里能看到每个团队命令协调哪些智能体

**为什么要用**：73 个命令记不住。这张表是"命令黄页"。

**开发流程中何时被使用**：**全程**。需要跑命令时就来查。`/help` 命令也会动态读你的阶段告诉你下一步，但人脑记不住时翻这个表。

---

#### 3. `workflow-catalog.yaml` —— 7 阶段流水线定义

**作用**：这是 `/help` 命令的"大脑"。它用 YAML 把 7 个阶段（Concept → Systems Design → Technical Setup → Pre-Production → Production → Polish → Release）的**每一步**都定义清楚：跑哪个命令、是不是必须（`required`）、可否重复（`repeatable`）、怎么检查完成（`artifact` 的 glob/pattern）。

**关键内容**（来自 [workflow-catalog.yaml](file:///workspace/.claude/docs/workflow-catalog.yaml)）：

每个阶段有 `steps`，每个 step 有：

- `id` / `name`：步骤标识和名字
- `command`：要跑的斜杠命令
- `required`：true=必须做（阻塞下一阶段），false=可选
- `repeatable`：true=可重复跑（如每个系统跑一次）
- `artifact`：怎么判断这步做完了——`glob`（文件匹配）、`pattern`（文件内文字）、`min_count`（最少几个文件）、`note`（人工判断说明）
- `description`：这步干什么

**如何使用**：你**不手动编辑**它。它由 `/help` 自动读。你只要知道：当 `/help` 告诉你"下一步该跑 X"时，它就是查的这个文件。

**为什么要用**：没有它，`/help` 不知道"现在到哪了、下一步干啥"。它是流程的"事实之源"。`required: true` 的步骤没做，`/gate-check` 会拦你。

**开发流程中何时被使用**：**全程**。每次跑 `/help` 都读它；`/gate-check` 也读它判断阶段门禁要查哪些产出物。

---

#### 4. `directory-structure.md` —— 项目目录结构

**作用**：一张图说清楚整个项目的目录布局——代码放 `src/`、资产放 `assets/`、设计放 `design/`、技术文档放 `docs/`、测试放 `tests/`、原型放 `prototypes/`、生产管理放 `production/`。

**关键内容**（来自 [directory-structure.md](file:///workspace/.claude/docs/directory-structure.md)）：

```
src/          游戏源码（core/gameplay/ai/networking/ui/tools）
assets/       游戏资产（art/audio/vfx/shaders/data）
design/       设计文档（gdd/narrative/levels/balance）
docs/         技术文档（architecture/api/postmortems）+ engine-reference/
tests/        测试（unit/integration/performance/playtest）
prototypes/   一次性原型（和 src/ 隔离）
production/   生产管理（sprints/milestones/releases）+ session-state/（临时）
```

**如何使用**：

- 创建文件前看一眼"该放哪"
- 理解为什么原型放 `prototypes/` 不放 `src/`（隔离，规则更松）
- 理解为什么 `session-state/` 要 gitignored（临时状态，不进版本库）

**为什么要用**：统一目录结构是规则按路径生效的前提（见 [rules-reference.md](file:///workspace/.claude/docs/rules-reference.md)）。代码在 `src/gameplay/` 才套"玩法规则"，在 `src/ai/` 才套"AI 规则"。目录乱了，规则就乱套。

**开发流程中何时被使用**：**Phase 3 技术搭建**（建目录结构）最相关。之后每次新建文件时隐式遵守。

---

#### 5. `setup-requirements.md` —— 环境依赖清单

**作用**：告诉你要装哪些工具才能让全套功能（尤其 12 个钩子）正常跑。分"必需"和"推荐"。

**关键内容**（来自 [setup-requirements.md](file:///workspace/.claude/docs/setup-requirements.md)）：

- **必需**：Git、Claude Code
- **推荐**：jq（7 个钩子要用，解析 JSON）、Python 3（2 个钩子用，校验 JSON 数据）、Bash（所有钩子用）
- 跨平台说明（Windows 用 Git Bash、macOS/Linux 原生有 Bash）
- 验证命令（`git --version` 等）
- "没装可选工具会怎样"——钩子静默跳过，不报错但没保护

**如何使用**：

- 第一次搭环境时照着装
- 钩子没生效时来这里查是不是缺 jq/Python
- 用 `git --version && bash --version && jq --version` 一键自检

**为什么要用**：钩子是"安全网"，缺了 jq 等于"裸奔"——提交时不校验、推送时不挡、资产不查。这个清单让你知道缺什么、怎么补。

**开发流程中何时被使用**：**开始前**（装环境）最相关。后续钩子失效时回来查。

---

### 第 2 组：智能体协作

#### 6. `agent-roster.md` —— 智能体花名册

**作用**：49 个智能体的"花名册"，按三层（Tier 1/2/3）+ 引擎专家列出每个智能体的领域、模型级别、什么时候用。

**关键内容**（来自 [agent-roster.md](file:///workspace/.claude/docs/agent-roster.md)）：

- Tier 1（Opus）：creative-director、technical-director、producer
- Tier 2（Sonnet）：game-designer、lead-programmer、art-director 等 8 个部门主管
- Tier 3（Sonnet/Haiku）：systems-designer、gameplay-programmer 等 20+ 专家
- 引擎专家：UE/Unity/Godot 各 1 个 lead + 4 个子专家

**如何使用**：

- "这活该找谁"——翻表找领域匹配的
- 想知道某智能体什么级别（决定成本和速度）——看 Model 列
- Haiku 的活（只读、格式化）别用 Opus，浪费钱

**为什么要用**：49 个智能体记不住谁是谁。花名册是"通讯录"。它还帮你做成本控制——简单查询用 Haiku，复杂综合用 Opus。

**开发流程中何时被使用**：**全程**。需要委派任务时查。`/team-*` 命令也隐式用它决定召唤谁。

---

#### 7. `agent-coordination-map.md` —— 组织架构与委派图

**作用**：比花名册更进一步——画出**组织架构图**（谁向谁汇报）、**委派规则**（谁能派活给谁）、**升级路径**（冲突往上报给谁）、**9 种常见工作流模式**（新功能/修 bug/平衡调整/新区域/冲刺/里程碑/发布/概念原型/垂直切片/线上活动）。

**关键内容**（来自 [agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md)）：

- ASCII 组织架构图（Human → 三总监 → 主管 → 专家）
- 委派规则表（creative-director 能派给谁、producer 能派给谁……）
- 升级路径表（两个设计师吵架→找 game-designer；设计 vs 技术冲突→producer 主持……）
- 9 个工作流模式（每个是一串智能体调用顺序）
- 4 个跨部门通知协议（设计变更/架构变更/资产标准变更要通知谁）
- 5 个反模式（越级指挥、跨域改文件、口头决策不记档、任务过大不拆、靠猜不问）

**如何使用**：

- 想知道"这事该找谁、走什么流程"——查工作流模式
- 智能体冲突了——查升级路径
- 想理解为什么不能越级——看反模式

**为什么要用**：没有它，智能体会"乱指挥"——总监直接派活给专家跳过主管，或两个智能体改同一个文件打架。这张图规定了"谁指挥谁、谁通知谁"，是协调的规则。

**开发流程中何时被使用**：**全程**。`/team-*` 编排命令内部按这些模式调度。新手理解协作时通读一遍。

---

#### 8. `coordination-rules.md` —— 协作规则

**作用**：5 条简短的协作规则 + 模型分级 + 子智能体 vs 团队 + 并行协议。是 [agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md) 的"精简口诀版"。

**关键内容**（来自 [coordination-rules.md](file:///workspace/.claude/docs/coordination-rules.md)）：

- 5 条规则：垂直委派、同级咨询不越权、冲突升级找共同上级、变更传播靠 producer、不越域改文件
- 模型分级表：Haiku（只读查询）/ Sonnet（默认主力）/ Opus（多文档综合、高风险门禁）
- 子智能体（当前默认，单会话内 Task 召唤）vs 智能体团队（实验性，多会话并行，需开环境变量）
- 并行任务协议：独立任务同时发、收齐再继续、阻塞要立即上报

**如何使用**：

- 快速查"模型怎么选"——看模型分级表
- 决定"该用子智能体还是团队"——看对比
- 写新技能时——参考并行协议决定是否并行召唤

**为什么要用**：5 条规则是协作的"宪法"，简短好记。模型分级帮你控制成本（别用 Opus 干 Haiku 的活）。

**开发流程中何时被使用**：**全程**。技能和智能体设计时参考。日常用不到，但理解它才能理解为什么这么编排。

---

#### 9. `director-gates.md` —— 总监门禁

**作用**：这是 `.claude/docs/` 里**最长、最核心**的文件之一。它定义了 **25 个总监门禁**——每个门禁是一段标准化的评审 prompt，技能用"门禁 ID"引用它，而不是把 prompt 抄进技能里。这样改 prompt 只改一处，所有技能自动同步。

**关键内容**（来自 [director-gates.md](file:///workspace/.claude/docs/director-gates.md)）：

- 3 种评审模式：`full`（每步都审）、`lean`（默认，只审阶段门）、`solo`（全跳过）
- 标准判决格式：APPROVE/READY、CONCERNS、REJECT/NOT READY
- 25 个门禁，按总监分组：
  - 创意总监（CD-）：PILLARS、GDD-ALIGN、SYSTEMS、NARRATIVE、PLAYTEST、PHASE-GATE
  - 技术总监（TD-）：SYSTEM-BOUNDARY、FEASIBILITY、ARCHITECTURE、ADR、ENGINE-RISK、PHASE-GATE
  - 制作人（PR-）：SCOPE、SPRINT、MILESTONE、EPIC、PHASE-GATE
  - 美术总监（AD-）：CONCEPT-VISUAL、ART-BIBLE、PHASE-GATE
  - 主管级：LP-FEASIBILITY、LP-CODE-REVIEW、QL-STORY-READY、QL-TEST-COVERAGE、ND-CONSISTENCY、AD-VISUAL
- 并行门禁协议（阶段门同时召唤 4 位总监）
- 门禁按阶段覆盖表（每个阶段哪些必须、哪些可选）

**如何使用**：

- 你不直接"运行"门禁。技能（如 `/gate-check`、`/architecture-decision`）在关键节点自动召唤总监跑对应门禁
- 想知道某阶段要过哪些门——查"Gate Coverage by Stage"表
- 想改门禁 prompt——改这里，别改技能（避免漂移）
- 想加新门禁——按"Adding New Gates"的规则分配 ID

**为什么要用**：没有它，每个技能各自写一段"让创意总监审一下"的 prompt，措辞不一、改起来要改 73 处。门禁集中定义 + ID 引用 = 单一事实源。

**开发流程中何时被使用**：**全程**，尤其阶段转换时。`/gate-check` 跑 4 个 PHASE-GATE；`/architecture-decision` 跑 TD-ADR；`/design-system` 跑 CD-GDD-ALIGN。详见"Gate Coverage by Stage"表。

---

#### 10. `review-workflow.md` —— 评审流程

**作用**：极简的 4 条评审规则——代码改动由对应主管审、设计改动由 game-designer + creative-director 签字、架构改动由 technical-director 签字、跨域改动由 producer 签字。

**关键内容**（来自 [review-workflow.md](file:///workspace/.claude/docs/review-workflow.md)）：

```
1. 代码改动 → 对应部门主管审
2. 设计改动 → game-designer + creative-director 签字
3. 架构改动 → technical-director 签字
4. 跨域改动 → producer 签字
```

**如何使用**：改了东西后，按这 4 条判断"该找谁签字"。

**为什么要用**：防止"改了没人审"导致问题溜进主干。签字制度是质量底线。

**开发流程中何时被使用**：**Phase 5 生产**最密集（每次 `/dev-story` 后 `/code-review`）。全程改东西都适用。

---

### 第 3 组：标准与偏好

#### 11. `coding-standards.md` —— 代码/设计/测试三大标准

**作用**：规定代码怎么写、设计文档怎么写、测试怎么做。是项目的"质量底线"。

**关键内容**（来自 [coding-standards.md](file:///workspace/.claude/docs/coding-standards.md)）：

- **代码标准**：公开 API 必须有文档注释、每个系统要有 ADR、玩法数值必须数据驱动（不硬编码）、公开方法必须可单测（用依赖注入不用单例）、提交信息用 Conventional Commits、验证驱动开发（先写测试）
- **设计文档标准**：用 Markdown、每个机制一份 GDD 放 `design/gdd/`、必填 8 节（Overview/Player Fantasy/Detailed Rules/Formulas/Edge Cases/Dependencies/Tuning Knobs/Acceptance Criteria）、平衡值要链接到公式
- **测试标准**：按故事类型分证据——Logic（自动单测，阻塞）、Integration（集成测试或试玩记录，阻塞）、Visual/Feel（截图+主管签字，建议）、UI（手动走查或交互测试，建议）、Config/Data（冒烟测试，建议）
- 自动化测试规则：命名规范、确定性（每次结果一样）、隔离性（不依赖顺序）、不硬编码数据
- 不该自动化的：视觉保真度、"手感"、平台渲染、完整对局
- CI/CD 规则：每次推送和 PR 跑测试、测试失败不让合并、绝不跳过失败测试

**如何使用**：

- 写代码前看"代码标准"
- 写 GDD 前看"设计文档标准"的 8 节
- 写测试前看"测试标准"判断该写哪种证据
- 提交时按 Conventional Commits 写信息

**为什么要用**：没有统一标准，每个智能体写的代码风格不一、GDD 长得不一样，后续的 `/code-review`、`/architecture-review`、`/story-done` 都没法自动判断。

**开发流程中何时被使用**：**全程**。写代码（Phase 5）、写 GDD（Phase 2）、写测试（Phase 5）都直接适用。`validate-commit.sh` 钩子在提交时自动检查部分标准。

---

#### 12. `technical-preferences.md` —— 项目专属偏好

**作用**：这是**项目专属的"配置表"**——记录这个项目用哪个引擎、什么语言、目标平台、输入方式、命名规范、性能预算、测试框架、禁止模式、允许的库、引擎专家路由。**初始全是 `[TO BE CONFIGURED]`，由 `/setup-engine` 填充。**

**关键内容**（来自 [technical-preferences.md](file:///workspace/.claude/docs/technical-preferences.md)）：

- 引擎与语言（Engine/Language/Rendering/Physics）
- 输入与平台（Target Platforms/Input Methods/Primary Input/Gamepad/Touch）
- 命名规范（Classes/Variables/Signals/Files/Scenes/Constants）
- 性能预算（Target Framerate/Frame Budget/Draw Calls/Memory Ceiling）
- 测试（Framework/Minimum Coverage/Required Tests）
- 禁止模式、允许的库、ADR 日志
- 引擎专家路由（哪个文件类型找哪个专家）+ 文件扩展名路由表

**如何使用**：

- 你**不手动编辑初始值**——跑 `/setup-engine` 让它问你问题再填
- 之后可以手动改（如加了新 ADR 后更新"禁止模式"和"允许的库"）
- 写代码/设计 UX/搭测试时，AI 会读它知道"这个项目的规矩"

**为什么要用**：每个项目引擎不同、平台不同、命名不同。没有这个文件，AI 会用默认假设（可能是错的）。它是"项目个性"的集中记录。

**开发流程中何时被使用**：

- **Phase 1**（`/setup-engine`）首次填充
- **Phase 3**（写 ADR）后更新"禁止模式""允许的库"
- **Phase 4-5**（`/ux-design` 读输入方式、`/dev-story` 读命名规范、`/test-setup` 读测试框架）反复读

---

#### 13. `rules-reference.md` —— 路径规则索引

**作用**：11 条规则的索引表——每条规则在哪个文件、匹配哪个路径模式、强制什么。

**关键内容**（来自 [rules-reference.md](file:///workspace/.claude/docs/rules-reference.md)）：

| 规则文件 | 路径 | 强制 |
|---------|------|------|
| gameplay-code.md | src/gameplay/** | 数据驱动、用 delta time、不引用 UI |
| engine-code.md | src/core/** | 热路径零分配、线程安全、API 稳定 |
| ai-code.md | src/ai/** | 性能预算、可调试、参数数据驱动 |
| network-code.md | src/networking/** | 服务端权威、消息版本化、安全 |
| ui-code.md | src/ui/** | 不持有游戏状态、可本地化、无障碍 |
| design-docs.md | design/gdd/** | 必填 8 节、公式格式、边界情况 |
| narrative.md | design/narrative/** | 设定一致、角色声音、正典级别 |
| data-files.md | assets/data/** | JSON 合法、命名规范、schema |
| test-standards.md | tests/** | 测试命名、覆盖率、fixture |
| prototype-code.md | prototypes/** | 标准放宽、要 README、记假设 |
| shader-code.md | assets/shaders/** | 命名、性能目标、跨平台 |

**如何使用**：你不直接"运行"规则。Claude Code 编辑对应路径的文件时**自动**套用对应规则。你只要知道"在哪个目录写代码，自动守哪条规矩"。

**为什么要用**：规则按路径生效 = 精准。玩法代码和 AI 代码规矩不一样，UI 代码和着色器规矩不一样。一刀切规则会让原型代码也背上生产代码的包袱。

**开发流程中何时被使用**：**Phase 5 生产**（写代码）最密集。每次编辑文件自动触发。Phase 2 写 GDD 时套 design-docs 规则。

> 📌 想深入了解规则怎么按路径生效，看 [06-Rules路径规则](file:///workspace/study-docs/06-Rules路径规则.md)。

---

#### 14. `context-management.md` —— 上下文管理

**作用**：这是**长会话不"失忆"的核心秘籍**。它教 AI 怎么管理上下文（工作记忆）：用文件当记忆、增量写入、主动压缩、用子智能体分担。

**关键内容**（来自 [context-management.md](file:///workspace/.claude/docs/context-management.md)）：

- **文件即记忆**：对话是临时的（会被压缩/丢失），文件是持久的。重要决策写文件，不靠对话记
- **会话状态文件**：`production/session-state/active.md` 记"当前任务、进度清单、关键决策、在改的文件、开放问题"。每次小里程碑后更新
- **状态行块**（生产阶段+）：active.md 里嵌 `<!-- STATUS -->` 块，状态栏脚本解析显示面包屑
- **增量分节写入**：长文档先建骨架→讨论一节→写盘一节→更新状态。每节写完，该节的讨论可安全压缩
- **主动压缩**：60-70% 上下文用量就压（别等到极限），任务间用 `/clear`，自然压缩点（写完一节/提交后/完成任务）
- **上下文预算**：轻任务~3k、中任务~8k、重任务~15k token
- **子智能体分担**：跨多文件研究、陌生代码探索用子智能体（独立上下文，只返回摘要）
- **压缩时保留**：状态文件引用、改过的文件清单、架构决策、冲刺任务状态、测试结果、阻塞问题、当前步骤
- **崩溃恢复**：session-start.sh 钩子自动检测并预览 active.md → 读全状态文件 → 读未完成的文件 → 接着干

**如何使用**：

- 你**不手动写** active.md（AI 写），但要知道它存在——崩溃后 AI 靠它恢复
- 写长文档时让 AI"增量分节写入"，别一次性整篇
- 发现 AI 开始"忘事"，提醒它"读 active.md 恢复状态"

**为什么要用**：长会话（写一个 GDD 可能几十轮对话）必然触发压缩。不增量写入，压缩一发生，前面的决策就丢了，AI 会重复问或推翻已定的事。

**开发流程中何时被使用**：**全程**，尤其长任务（写 GDD、写架构、实现复杂故事）。pre-compact.sh 和 post-compact.sh 钩子在压缩前后自动按它操作。

> 📌 想深入了解，看 [08-上下文管理艺术](file:///workspace/study-docs/08-上下文管理艺术.md)。

---

### 第 4 组：个人配置模板

#### 15. `CLAUDE-local-template.md` —— 个人 CLAUDE.local.md 模板

**作用**：给你抄的模板，抄到项目根变成 `CLAUDE.local.md`——只属于你的本地配置（gitignored，不进版本库）。

**关键内容**（来自 [CLAUDE-local-template.md](file:///workspace/.claude/docs/CLAUDE-local-template.md)）：

- 模型偏好（复杂设计用 Opus、快速查询用 Haiku）
- 工作流偏好（改完代码跑测试、60% 主动压缩、任务间 `/clear`）
- 本地环境（Python 命令、Shell、IDE）
- 沟通风格（简洁、显示文件路径、简要解释架构决策）
- 个人快捷方式（说"review"就跑 `/code-review`、说"status"就显示 git 状态+冲刺进度）

**如何使用**：

```bash
cp .claude/docs/CLAUDE-local-template.md CLAUDE.local.md
# 然后编辑 CLAUDE.local.md 填你的偏好
```

**为什么要用**：团队共享 `CLAUDE.md`，但每个人都有自己的习惯（IDE、快捷语、模型偏好）。`CLAUDE.local.md` 让你本地定制而不污染团队配置。

**开发流程中何时被使用**：**开始前**（个人配置）。之后偶尔调。

---

#### 16. `settings-local-template.md` —— 个人 settings.local.json 模板

**作用**：给你抄的模板，抄成 `.claude/settings.local.json`——本地的权限和钩子覆盖（gitignored）。

**关键内容**（来自 [settings-local-template.md](file:///workspace/.claude/docs/settings-local-template.md)）：

- 权限示例：allow（`Bash(git *)`、`Bash(npm *)`、Read、Glob、Grep）、deny（`Bash(rm -rf *)`、`Bash(git push --force *)`）
- 三种权限模式：开发（默认，问再跑）、原型（auto-accept，限 `prototypes/`）、代码评审（只读）
- 本地钩子扩展（不覆盖项目钩子，如会话结束时记日志）

**如何使用**：抄成 `.claude/settings.local.json`，按你的安全需求改 allow/deny。

**为什么要用**：团队共享 `settings.json`（项目钩子），但你可能想要更松/更紧的个人权限。本地文件让你定制而不影响队友。

**开发流程中何时被使用**：**开始前**（个人配置）。原型阶段可切 auto-accept 加速。

---

### 第 5 组：钩子参考

#### 17. `hooks-reference.md` —— 钩子总览

**作用**：12 个钩子的一览表——每个钩子什么事件触发、触发条件、干什么。

**关键内容**（来自 [hooks-reference.md](file:///workspace/.claude/docs/hooks-reference.md)）：

| 钩子 | 事件 | 干什么 |
|------|------|--------|
| validate-commit.sh | 提交前 | 校验设计文档章节、JSON、硬编码值、TODO 格式 |
| validate-push.sh | 推送前 | 警告推送到保护分支 |
| validate-assets.sh | 写资产后 | 检查命名和 JSON 合法性 |
| session-start.sh | 会话开始 | 加载冲刺/里程碑/git 上下文，预览 active.md |
| detect-gaps.sh | 会话开始 | 检测新项目（建议 /start）和缺文档（建议 /reverse-document） |
| pre-compact.sh | 压缩前 | 把会话状态倒进对话，让压缩不丢 |
| post-compact.sh | 压缩后 | 提醒从 active.md 恢复状态 |
| notify.sh | 通知 | Windows 弹通知 |
| session-stop.sh | 会话结束 | 总结成果，更新日志 |
| log-agent.sh | 子智能体启动 | 审计日志开始 |
| log-agent-stop.sh | 子智能体停止 | 审计日志结束 |
| validate-skill-change.sh | 改技能后 | 建议跑 /skill-test |

**如何使用**：你不直接运行钩子。它们由 `settings.json` 配置，对应事件自动触发。想知道"某操作会不会触发校验"——查这张表。

**为什么要用**：钩子是"自动守卫"——提交时查质量、推送时挡保护分支、压缩前保状态。没有它们，全靠 AI 自觉，必然出错。

**开发流程中何时被使用**：**全程自动**。提交/推送（Phase 5）、会话开始/结束（任何阶段）、压缩（长任务）都触发。

> 📌 想深入了解，看 [05-Hook自动化守卫](file:///workspace/study-docs/05-Hook自动化守卫.md)。

---

#### 18. `hooks-reference/` 子目录 —— 钩子详解

**作用**：6 篇文档，逐个讲钩子的触发、目的、实现代码、失败时该召唤哪个智能体。是"实现级参考"。

**6 个文件**：

| 文件 | 讲什么 |
|------|--------|
| [hook-input-schemas.md](file:///workspace/.claude/docs/hooks-reference/hook-input-schemas.md) | 每类钩子收到的 JSON 数据格式（PreToolUse/PostToolUse/SubagentStart/SessionStart/PreCompact/Stop）+ 退出码语义 |
| [pre-commit-code-quality.md](file:///workspace/.claude/docs/hooks-reference/pre-commit-code-quality.md) | 提交前查 src/ 代码：硬编码玩法值、TODO 无归属、跑 linter |
| [pre-commit-design-check.md](file:///workspace/.claude/docs/hooks-reference/pre-commit-design-check.md) | 提交前查设计文档：8 必填章节、格式合规 |
| [pre-push-test-gate.md](file:///workspace/.claude/docs/hooks-reference/pre-push-test-gate.md) | 推送前：构建、单测、（保护分支）集成测试+冒烟+性能回归 |
| [post-merge-asset-validation.md](file:///workspace/.claude/docs/hooks-reference/post-merge-asset-validation.md) | 合并后查 assets/：命名（小写下划线）、纹理尺寸（2 的幂）、文件大小预算 |
| [post-sprint-retrospective.md](file:///workspace/.claude/docs/hooks-reference/post-sprint-retrospective.md) | 冲刺后触发回顾 |

**如何使用**：

- 想改某个钩子的检查逻辑——读对应文件改 `.claude/hooks/*.sh`
- 钩子报错了不知为啥——读详解看它查什么
- 想加新钩子——参考这些文件的格式

**为什么要用**：钩子脚本是"可执行的规则"。详解让你知道每个钩子具体查什么、怎么改、失败该找谁。`hook-input-schemas.md` 还是写新钩子的必备参考（要知道收到的 JSON 长啥样）。

**开发流程中何时被使用**：维护钩子时读。日常开发不直接读，但钩子按这些逻辑自动跑。

---

### 第 6 组：文档模板

#### 19. `templates/` 子目录 —— 38 个文档模板 + 3 个协作协议

**作用**：这是 `.claude/docs/` 里**文件最多**的子目录。38 个模板覆盖游戏开发要写的几乎所有文档——GDD、ADR、测试计划、冲刺计划、里程碑、关卡设计、美术圣经、音效圣经、风险登记、事故响应……写文档时套模板，保证格式统一、章节齐全。

**为什么用模板**：

1. **格式统一**：所有 GDD 都有 8 节、所有 ADR 都有 Status/Context/Decision/Consequences
2. **不漏章节**：模板强制必填项（如 GDD 的 Edge Cases、ADR 的 Alternatives Considered）
3. **自动化能解析**：`/architecture-review`、`/story-done` 靠统一格式才能机器检查
4. **降低门槛**：新手不用从零设计文档结构

**38 个模板分类**（来自 [templates/](file:///workspace/.claude/docs/templates/)）：

| 类别 | 模板 |
|------|------|
| **设计** | game-concept、game-pillars、game-design-document、systems-index、level-design-document、difficulty-curve、player-journey、faction-design、economy-model |
| **架构** | architecture-decision-record、architecture-traceability、technical-design-document、architecture-doc-from-code、design-doc-from-implementation、concept-doc-from-prototype |
| **美术/音效** | art-bible、sound-bible |
| **UX** | ux-spec、hud-design、interaction-pattern-library、accessibility-requirements |
| **生产管理** | sprint-plan、milestone-definition、project-stage-report、risk-register-entry、post-mortem |
| **测试** | test-plan、test-evidence、skill-test-spec |
| **发布** | release-checklist-template、release-notes、changelog-template、incident-response |
| **叙事** | narrative-character-sheet |
| **原型** | prototype-report、vertical-slice-report |

**3 个协作协议**（在 [templates/collaborative-protocols/](file:///workspace/.claude/docs/templates/collaborative-protocols/)）：

| 文件 | 用于 | 核心模式 |
|------|------|---------|
| design-agent-protocol.md | 设计类智能体 | 提问→给选项→起草→求批准 |
| implementation-agent-protocol.md | 实现类智能体 | 接故事→澄清→实现→/story-done |
| leadership-agent-protocol.md | 领导层智能体 | 跨部门委派与升级 |

**如何使用**：

- 你不手动复制模板。技能（`/design-system`、`/architecture-decision`）自动用对应模板创建文件
- 想知道某文档该有什么结构——翻对应模板
- 想改文档格式——改模板（影响之后所有用该模板的文档）

**为什么要用**：见上面"为什么用模板"。关键是**自动化前提**——`/review-all-gdds` 能批量审 GDD，是因为所有 GDD 都套同一个模板，章节名一致。

**开发流程中何时被使用**：**全程**。Phase 1（game-concept）、Phase 2（game-design-document）、Phase 3（architecture-decision-record）、Phase 4（ux-spec、sprint-plan）、Phase 5（test-plan）、Phase 6（post-mortem）、Phase 7（release-checklist-template）都套模板。

---

## 关键机制：这些文档运行时怎么"生效"？被 `@` 引用 vs 给人读

读到这里你可能有疑问：上面说了 `coordination-rules.md` 的 5 条规则"对所有智能体生效"，但**怎么生效的**？而 [agent-roster.md](file:///workspace/.claude/docs/agent-roster.md)、[agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md) 这两个文件，翻遍 CLAUDE.md、agents/、skills/ 都看不到对它们的引用——那它们到底什么时候发挥作用？

这是这套架构里**最容易让初学者困惑**的一点。答案是：`.claude/docs/` 里的文件分**两类**，生效方式完全不同。

### 两类文件的分野

| 类别 | 生效方式 | 谁读它 | 例子 |
|------|---------|--------|------|
| **A. 运行时注入类** | 被 CLAUDE.md 用 `@路径` 引用 → 每次会话启动，内容被自动注入 AI 上下文 → 对所有智能体生效 | AI（自动） | coordination-rules、coding-standards、technical-preferences、context-management、directory-structure |
| **B. 人读参考类** | 不被 `@` 引用，不进运行时上下文 → 给**人**理解全局用，或给维护者改架构时参考 | 人（手动翻） | agent-roster、agent-coordination-map、quick-start、skills-reference、hooks-reference、director-gates、templates、两个 local-template |

验证方法：打开根 [CLAUDE.md](file:///workspace/CLAUDE.md)，看它的 `@` 引用——

```
@.claude/docs/directory-structure.md
@.claude/docs/technical-preferences.md
@.claude/docs/coordination-rules.md      ← 5 条规则从这里进上下文
@.claude/docs/coding-standards.md
@.claude/docs/context-management.md
```

**只有这 5 个文件被 `@` 引用**。它们的内容会在每次会话启动时注入 AI 的上下文窗口，所以它们的规则"对所有智能体自动生效"——不需要智能体主动去读。

### 那 `agent-roster.md` 和 `agent-coordination-map.md` 呢？

这两个文件**没有被 `@` 引用，也没有被任何 agent 定义文件或 skill 文件引用**。我用搜索验证过：它们只出现在 `CONTRIBUTING.md`、`UPGRADING.md`、`.github/PULL_REQUEST_TEMPLATE.md`、`docs/examples/README.md` 这些**项目维护/人读**文档里。

那它们是不是没用？**不是**。它们是**给人读的"全局参考图"**——

- **你是人**，你想一眼看清"49 个智能体怎么分工、谁向谁汇报、9 种工作流怎么走"时，翻这两个文件。AI 不需要读它们，因为 AI 运行时用的是**另一套机制**（见下）。
- **类比**：公司的组织架构图挂在墙上给员工看。但员工实际干活时，不需要每次抬头看图——他知道"我是游戏设计师，我向创意总监汇报，我能找系统设计师帮忙"，因为这些信息**写在每个岗位的岗位职责书里**（内嵌），不必查墙上的图。

### 运行时委派规则到底从哪来？——内嵌在每个 agent 文件里

这是关键。每个智能体定义文件（`.claude/agents/*.md`）底部都有一段 **"Delegation Map"**，**内嵌**了"我能委派给谁、我向谁汇报、我是谁的升级目标"。智能体被召唤时，Claude Code 读它的定义文件，它就知道自己的委派边界——**不需要读 `agent-coordination-map.md`**。

举例（来自 [lead-programmer.md](file:///workspace/.claude/agents/lead-programmer.md) 第 100-111 行）：

```markdown
### Delegation Map

Delegates to:
- `gameplay-programmer` for gameplay feature implementation
- `engine-programmer` for core engine systems
- `ai-programmer` for AI and behavior systems
- `network-programmer` for networking features
- `tools-programmer` for development tools
- `ui-programmer` for UI system implementation

Reports to: `technical-director`
Coordinates with: `game-designer` for feature specs, `qa-lead` for testability
```

我搜索过，**38 处** "Delegation Map / Delegates to / Escalation" 散落在各个 agent 文件里。每个智能体自带"我能找谁、我向谁报"的局部视图。

`agent-coordination-map.md` 是把这些**局部视图汇总成一张全局图**，方便**你**一眼看懂。它和 agent 文件里的 Delegation Map 是**同一套信息的两种呈现**：

| | agent-coordination-map.md | 各 agent 文件的 Delegation Map |
|---|---------------------------|------------------------------|
| 形式 | 一张全局图 | 49 份局部片段 |
| 谁读 | 人（理解全局） | AI（被召唤时读自己的那份） |
| 更新时 | 改一处全图更新 | 要改 49 处（容易漂移） |
| 风险 | 和实际 agent 定义可能不同步 | 这才是运行时"事实之源" |

> ⚠️ **维护提醒**：因为运行时用的是 agent 文件里的内嵌 Delegation Map，如果你改了 `agent-coordination-map.md` 但没改对应 agent 文件，**实际行为不会变**。`agent-coordination-map.md` 是"地图"，agent 文件是"地形"——地图可能过时，地形才是真的。

### 运行时怎么知道"该召唤哪个智能体"？

这是另一个相关问题。`.claude/docs/` 里没有任何文件告诉 AI "现在该召唤谁"。召唤发生在**技能（skill）文件**里，靠两种机制：

1. **技能文件显式写死**：像 [team-combat/SKILL.md](file:///workspace/.claude/skills/team-combat/SKILL.md) 第 45-51 行那样，直接写 `subagent_type: game-designer`、`subagent_type: gameplay-programmer`——技能编排时按这个列表召唤。
2. **靠 agent 的 `description` 字段路由**：每个 agent 文件 frontmatter 有 `description`（如 creative-director 的描述）。当主会话用 `Task` 工具且没指定具体 agent 时，Claude Code 根据 description 判断"用户这个请求该找谁"。`/dev-story` 这种路由型技能也靠 description 把任务派给"正确的程序员"。

所以"有哪些智能体、各自干什么"的信息**存在每个 agent 文件的 frontmatter 里**，不靠 `agent-roster.md`。`agent-roster.md` 同样是给人看的汇总表。

### 一张表总结：17 个文件各自怎么"生效"

| 文件 | 类别 | 生效方式 |
|------|------|---------|
| [coordination-rules.md](file:///workspace/.claude/docs/coordination-rules.md) | **A 运行时** | CLAUDE.md `@` 引用 → 注入上下文 → 5 条规则对所有智能体自动生效 |
| [coding-standards.md](file:///workspace/.claude/docs/coding-standards.md) | **A 运行时** | CLAUDE.md `@` 引用 → 注入上下文 → 写代码/文档/测试时自动遵守 |
| [technical-preferences.md](file:///workspace/.claude/docs/technical-preferences.md) | **A 运行时** | CLAUDE.md `@` 引用 → 注入上下文 → AI 知道项目用哪个引擎、什么命名 |
| [context-management.md](file:///workspace/.claude/docs/context-management.md) | **A 运行时** | CLAUDE.md `@` 引用 → 注入上下文 → AI 知道"文件即记忆、增量写入" |
| [directory-structure.md](file:///workspace/.claude/docs/directory-structure.md) | **A 运行时** | CLAUDE.md `@` 引用 → 注入上下文 → AI 知道文件该放哪 |
| [agent-roster.md](file:///workspace/.claude/docs/agent-roster.md) | **B 人读** | 不注入。给人查"有哪些智能体、什么级别"。运行时靠 agent 文件 frontmatter 的 `description` |
| [agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md) | **B 人读** | 不注入。给人看全局组织图+9 种工作流。运行时靠各 agent 文件内嵌的 Delegation Map |
| [quick-start.md](file:///workspace/.claude/docs/quick-start.md) | **B 人读** | 不注入。给新手入门读 |
| [skills-reference.md](file:///workspace/.claude/docs/skills-reference.md) | **B 人读** | 不注入。给人查"有哪些命令"。AI 靠 `/help` 读 workflow-catalog 知道下一步 |
| [workflow-catalog.yaml](file:///workspace/.claude/docs/workflow-catalog.yaml) | **B 但被技能读** | 不被 `@` 注入，但 `/help`、`/gate-check` 等技能**主动 Read 它**判断阶段和下一步 |
| [director-gates.md](file:///workspace/.claude/docs/director-gates.md) | **B 但被技能读** | 不被 `@` 注入，但技能（如 `/architecture-decision`、`/gate-check`）**主动 Read 它**按门禁 ID 取 prompt |
| [rules-reference.md](file:///workspace/.claude/docs/rules-reference.md) | **B 人读索引** | 不注入。它是 11 条规则的**索引表**。真正的规则在 `.claude/rules/*.md`，Claude Code 编辑对应路径文件时**自动套用**（机制独立于 `@`） |
| [hooks-reference.md](file:///workspace/.claude/docs/hooks-reference.md) | **B 人读** | 不注入。钩子由 `settings.json` 配置自动触发，不靠 AI 读这个文件 |
| [review-workflow.md](file:///workspace/.claude/docs/review-workflow.md) | **B 人读** | 不注入。评审靠技能（`/code-review`、`/story-done`）和门禁（LP-CODE-REVIEW）执行 |
| [setup-requirements.md](file:///workspace/.claude/docs/setup-requirements.md) | **B 人读** | 不注入。给人装环境时查 |
| [templates/](file:///workspace/.claude/docs/templates/) | **B 但被技能读** | 不被 `@` 注入，但技能（`/design-system`、`/architecture-decision`）**主动 Read 对应模板**创建文件 |
| [hooks-reference/](file:///workspace/.claude/docs/hooks-reference/) | **B 人读** | 不注入。给维护钩子的人看。实际钩子脚本在 `.claude/hooks/*.sh` |
| [CLAUDE-local-template.md](file:///workspace/.claude/docs/CLAUDE-local-template.md) | **B 人读模板** | 不注入。给人抄成 `CLAUDE.local.md`（这个文件才会被 Claude Code 读） |
| [settings-local-template.md](file:///workspace/.claude/docs/settings-local-template.md) | **B 人读模板** | 不注入。给人抄成 `settings.local.json` |

**三层生效机制**总结：

1. **`@` 注入层**（最强）：CLAUDE.md `@` 引用的 5 个文件 → 每次会话自动进上下文 → 全局自动生效
2. **技能主动读层**（按需）：workflow-catalog、director-gates、templates → 技能跑到需要时主动 Read → 该次调用生效
3. **机制独立层**（不靠文档）：rules（按路径自动套）、hooks（settings.json 触发）、agent 的 description/Delegation Map（召唤时读 agent 文件）→ 各有独立机制，不依赖 `.claude/docs/` 里的索引或参考图

`agent-roster.md` 和 `agent-coordination-map.md` 属于**第 3 层的"人读镜像"**——运行时事实在 agent 文件里，这两个文档是把运行时事实"翻译成人能一眼看懂的全局图"。

---

## 在开发流程中何时碰到 `.claude/docs/`

把所有文件映射到 7 阶段开发流程：

| 阶段 | 主要碰到的 `.claude/docs/` 文件 | 干什么 |
|------|-------------------------------|--------|
| **开始前** | [quick-start.md](file:///workspace/.claude/docs/quick-start.md)、[setup-requirements.md](file:///workspace/.claude/docs/setup-requirements.md)、[CLAUDE-local-template.md](file:///workspace/.claude/docs/CLAUDE-local-template.md)、[settings-local-template.md](file:///workspace/.claude/docs/settings-local-template.md) | 读入门指南、装环境、做个人配置 |
| **Phase 1 概念** | [technical-preferences.md](file:///workspace/.claude/docs/technical-preferences.md)（/setup-engine 填充）、[templates/game-concept.md](file:///workspace/.claude/docs/templates/game-concept.md)、[templates/game-pillars.md](file:///workspace/.claude/docs/templates/game-pillars.md) | 配引擎、写概念文档套模板 |
| **Phase 2 系统设计** | [templates/game-design-document.md](file:///workspace/.claude/docs/templates/game-design-document.md)、[rules-reference.md](file:///workspace/.claude/docs/rules-reference.md)（design-docs 规则）、[director-gates.md](file:///workspace/.claude/docs/director-gates.md)（CD-GDD-ALIGN、CD-SYSTEMS） | 写 GDD 套模板、遵守设计文档规则、过创意总监门禁 |
| **Phase 3 技术搭建** | [coding-standards.md](file:///workspace/.claude/docs/coding-standards.md)、[templates/architecture-decision-record.md](file:///workspace/.claude/docs/templates/architecture-decision-record.md)、[director-gates.md](file:///workspace/.claude/docs/director-gates.md)（TD-ARCHITECTURE、TD-ADR）、[technical-preferences.md](file:///workspace/.claude/docs/technical-preferences.md)（更新禁止模式/允许库） | 写 ADR 套模板、守代码标准、过技术总监门禁 |
| **Phase 4 预制作** | [templates/ux-spec.md](file:///workspace/.claude/docs/templates/ux-spec.md)、[templates/sprint-plan.md](file:///workspace/.claude/docs/templates/sprint-plan.md)、[templates/milestone-definition.md](file:///workspace/.claude/docs/templates/milestone-definition.md)、[director-gates.md](file:///workspace/.claude/docs/director-gates.md)（PR-EPIC、QL-STORY-READY、PR-SPRINT） | 写 UX/冲刺/里程碑套模板、过制作人和 QA 门禁 |
| **Phase 5 生产** | [coding-standards.md](file:///workspace/.claude/docs/coding-standards.md)、[rules-reference.md](file:///workspace/.claude/docs/rules-reference.md)（所有代码规则）、[context-management.md](file:///workspace/.claude/docs/context-management.md)、[templates/test-plan.md](file:///workspace/.claude/docs/templates/test-plan.md)、[director-gates.md](file:///workspace/.claude/docs/director-gates.md)（LP-CODE-REVIEW） | 写代码守规则、管上下文、写测试、过主程评审 |
| **Phase 6 打磨** | [coding-standards.md](file:///workspace/.claude/docs/coding-standards.md)（测试标准）、[director-gates.md](file:///workspace/.claude/docs/director-gates.md)（QL-TEST-COVERAGE、CD-PLAYTEST） | 跑测试、试玩、过 QA 和创意总监门禁 |
| **Phase 7 发布** | [templates/release-checklist-template.md](file:///workspace/.claude/docs/templates/release-checklist-template.md)、[templates/release-notes.md](file:///workspace/.claude/docs/templates/release-notes.md)、[templates/incident-response.md](file:///workspace/.claude/docs/templates/incident-response.md)、[director-gates.md](file:///workspace/.claude/docs/director-gates.md)（4 个 PHASE-GATE） | 发布检查套模板、过四总监阶段门 |
| **全程** | [agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md)、[agent-roster.md](file:///workspace/.claude/docs/agent-roster.md)、[coordination-rules.md](file:///workspace/.claude/docs/coordination-rules.md)、[skills-reference.md](file:///workspace/.claude/docs/skills-reference.md)、[workflow-catalog.yaml](file:///workspace/.claude/docs/workflow-catalog.yaml)、[hooks-reference.md](file:///workspace/.claude/docs/hooks-reference.md)、[review-workflow.md](file:///workspace/.claude/docs/review-workflow.md) | 协作规则、命令索引、流程目录、钩子、评审全程生效 |

**一句话总结**：`.claude/docs/` 里**最常被自动读的是 `workflow-catalog.yaml`**（`/help` 每次都读）、**最该人手通读的是 `quick-start.md`**、**最常被套用的是 `templates/`**、**最长最核心的是 `director-gates.md`**。

---

## 常见误区

**误区 1："这些文档我都要手动写。"**
❌ 错。`technical-preferences.md` 由 `/setup-engine` 填充；`workflow-catalog.yaml` 是预设的不用改；两个注册表（在根 `docs/`）由技能自动维护。你主要写的是 GDD 和 ADR（套模板）。

**误区 2："`technical-preferences.md` 初始全是 `[TO BE CONFIGURED]`，是没写完。"**
❌ 那是**故意的**。它是模板，等你跑 `/setup-engine` 回答问题后才填。没跑 `/setup-engine` 之前 AI 会用默认假设（可能错）。

**误区 3："规则（rules）和编码标准（coding-standards）是一回事。"**
⚠️ 不完全。`coding-standards.md` 是**全局**代码标准（所有代码都适用）；`rules/` 是**按路径**的细化规则（`src/gameplay/` 有玩法专属规则、`src/ai/` 有 AI 专属规则）。两者互补。

**误区 4："门禁（director-gates）是建议，可以跳过。"**
⚠️ 半对。门禁判决是 ADVISORY（建议性，用户最终决定），但**默认 lean 模式下阶段门（PHASE-GATE）仍会跑**。想全跳过得显式设 `solo` 模式。别为了快把 `solo` 当默认，那是给 game jam 用的。

**误区 5："`context-management.md` 是给 AI 看的，我不用管。"**
❌ 你要管。它教你**怎么和 AI 配合**——写长文档时让 AI 增量分节写入、任务间用 `/clear`、发现 AI 忘事提醒它读 active.md。你配合得好，AI 才不失忆。

**误区 6："模板（templates）只是起步骨架，可以随便改章节。"**
❌ 危险。模板的章节名是**自动化检查的依据**。`/review-all-gdds` 找"Edge Cases"章节，你改成"特殊情况"它就找不到。要改格式，连检查逻辑一起改。

**误区 7："`agent-roster.md` 和 `agent-coordination-map.md` 重复了。"**
❌ 不重复。roster 是"花名册"（谁在、什么级别）；map 是"组织架构+流程"（谁向谁汇报、怎么委派、9 种工作流）。前者查人，后者查关系。

**误区 8："钩子详解（hooks-reference/）只是文档，不影响行为。"**
❌ 那些详解里的 bash 代码**就是**`.claude/hooks/` 里实际跑的脚本逻辑。改详解不改脚本，行为不变；改脚本不更新详解，文档就过时。两边要同步。

**误区 9："`workflow-catalog.yaml` 里的 `required: false` 就是'不用做'。"**
❌ 是"可选"不是"不用做"。如 `/prototype` 标 `required: false`，但首次做高风险机制时**强烈建议做**。`required` 只决定是否阻塞下一阶段，不决定值不值得做。

**误区 10（关键）："`agent-roster.md` 和 `agent-coordination-map.md` 没被引用，是没用的死文档。"**
❌ 错。它们是**给人读的全局参考图**，不是给 AI 运行时读的。AI 运行时用的是：每个 agent 文件 frontmatter 的 `description`（决定路由）+ 每个 agent 文件底部的内嵌 `Delegation Map`（决定能委派给谁）。这两个汇总文档把分散在 49 个 agent 文件里的信息"翻译成人能一眼看懂的全局图"。判断一个 `.claude/docs/` 文件是否运行时生效，看它**有没有被 CLAUDE.md 用 `@` 引用**，或**有没有被技能主动 Read**——`agent-roster` 和 `agent-coordination-map` 两者都不是，所以是纯人读。

**误区 11："改了 `agent-coordination-map.md` 的委派关系，智能体行为就会变。"**
❌ 不会。运行时事实在 `.claude/agents/*.md` 各文件的内嵌 `Delegation Map` 里。`agent-coordination-map.md` 是"地图"，agent 文件是"地形"——改地图不动地形，行为不变。要改委派关系，必须改对应 agent 文件的 Delegation Map 段。这也是为什么地图可能和地形漂移——维护时要两边同步。

**误区 12："所有规则都靠 AI 自觉读 `.claude/docs/` 生效。"**
❌ 错。生效有三层机制（见上方"关键机制"一节）：① CLAUDE.md `@` 引用的 5 个文件自动注入；② 技能主动 Read 的文件（workflow-catalog、director-gates、templates）；③ 完全独立机制（rules 按路径套、hooks 由 settings.json 触发、agent 的 description/Delegation Map）。大多数规则**不靠 AI 主动读 `.claude/docs/`**，而是靠注入或独立机制。

---

## 小测验

**Q1**：你跑 `/help`，它告诉你"下一步跑 `/design-system`"。`/help` 是查哪个文件知道你该干啥的？

<details>
<summary>答案</summary>

[workflow-catalog.yaml](file:///workspace/.claude/docs/workflow-catalog.yaml)。它定义了 7 阶段每一步的命令和产出物检查。`/help` 读你的当前阶段，查这个文件找下一个未完成的必须步骤。

</details>

**Q2**：你写了一段 Godot 玩法代码，提交时被钩子警告"可能含硬编码玩法值"。这个检查依据哪个文档的标准？

<details>
<summary>答案</summary>

[coding-standards.md](file:///workspace/.claude/docs/coding-standards.md) 的"代码标准"——"Gameplay values must be data-driven (external config), never hardcoded"。`validate-commit.sh` 钩子据此检查 `src/gameplay/` 下的文件。

</details>

**Q3**：你让 AI 帮你写一个 GDD，它没问你就直接写完存盘了。你该提醒它参考哪个文档里的协议？

<details>
<summary>答案</summary>

[templates/collaborative-protocols/design-agent-protocol.md](file:///workspace/.claude/docs/templates/collaborative-protocols/design-agent-protocol.md)——它规定设计类智能体的"提问→给选项→起草→求批准"四步。核心是"写文件前必须问'可以写到 [路径] 吗？'"。

</details>

**Q4**：你升级引擎版本后，想确认某个 API 是否还可用。该读哪个文档知道技术总监门禁会查什么？

<details>
<summary>答案</summary>

[director-gates.md](file:///workspace/.claude/docs/director-gates.md) 的 **TD-ENGINE-RISK** 门禁——它专门评审"post-cutoff 引擎 API 使用"。结合根 [docs/engine-reference/](file:///workspace/docs/engine-reference/) 的版本快照一起看。

</details>

**Q5**：会话很长，AI 开始重复问已经定过的事。你该让它读哪个文件恢复状态？

<details>
<summary>答案</summary>

`production/session-state/active.md`——[context-management.md](file:///workspace/.claude/docs/context-management.md) 规定的"会话状态文件"，记录当前任务、进度、关键决策。压缩或崩溃后第一件事就是读它。

</details>

**Q6**：你想在 `src/ai/` 下写 AI 代码，但不知道有什么特殊规矩。该查哪个文档？

<details>
<summary>答案</summary>

[rules-reference.md](file:///workspace/.claude/docs/rules-reference.md)——`ai-code.md` 规则匹配 `src/ai/**`，强制"性能预算、可调试、参数数据驱动"。Claude Code 编辑该路径文件时会自动套用。

</details>

**Q7**：你跑 `/gate-check` 想从 Phase 4 进 Phase 5，四位总监并行评审。创意总监说 NOT READY，其他三位说 READY。最终判决是什么？

<details>
<summary>答案</summary>

**FAIL（或 NOT READY）**。[director-gates.md](file:///workspace/.claude/docs/director-gates.md) 的"并行门禁协议"规定：取**最严**判决——一个 NOT READY/REJECT 就覆盖所有 READY。整体至少是 FAIL/NOT READY。

</details>

**Q8**：你是 solo 开发者，觉得每步都过门禁太慢。该把评审模式设成什么？怎么设？

<details>
<summary>答案</summary>

设成 **`lean`**（默认就是）。[director-gates.md](file:///workspace/.claude/docs/director-gates.md) 规定：lean 模式只跑阶段门（PHASE-GATE），跳过每步的技能级门禁。设置方法：编辑 `production/review-mode.txt` 写 `lean`，或单次跑命令时加 `--review lean`。**不建议**用 `solo`（全跳），那是给 game jam 用的，失去所有总监反馈。

</details>

**Q9**：你发现 `agent-coordination-map.md` 里写"creative-director 能委派给 prototyper"，但你想改成"creative-director 不能直接委派给 prototyper，必须经过 producer"。你改了 `agent-coordination-map.md`，智能体行为会变吗？该改哪里？

<details>
<summary>答案</summary>

**不会变**。`agent-coordination-map.md` 是给人读的全局图（"地图"），运行时事实在每个 agent 文件的内嵌 `Delegation Map` 里（"地形"）。要真正改变行为，必须改 [.claude/agents/creative-director.md](file:///workspace/.claude/agents/creative-director.md) 底部的 "Delegates to" 段，把 prototyper 从列表里移除。改完 agent 文件后，**再同步更新 `agent-coordination-map.md`** 保持地图和地形一致，否则文档会漂移误导后来人。

</details>

**Q10**：为什么 `coordination-rules.md` 的 5 条规则对所有智能体自动生效，而 `agent-roster.md` 的智能体清单不会自动被 AI 读取？

<details>
<summary>答案</summary>

因为 `coordination-rules.md` 被 CLAUDE.md 用 `@.claude/docs/coordination-rules.md` **引用**，每次会话启动时内容自动注入 AI 上下文，对所有智能体可见。而 `agent-roster.md` **没有被 `@` 引用**，不进运行时上下文——它是给人读的汇总表。AI 运行时知道"有哪些智能体"靠的是每个 agent 文件 frontmatter 的 `description` 字段（Claude Code 用它路由请求），不需要读 roster。判断一个 `.claude/docs/` 文件是否运行时生效，看它有没有被 `@` 引用或被技能主动 Read。

</details>

---

## 动手

1. 打开 [quick-start.md](file:///workspace/.claude/docs/quick-start.md)，把"I need to..."表和"Slash Commands"表各扫一遍，建立"有啥能用"的全局观。
2. 打开 [agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md)，看 ASCII 组织架构图，再挑一个工作流模式（如 Pattern 1: New Feature）顺一遍，理解"一个功能从设计到完成经过哪些智能体"。
3. 打开 [director-gates.md](file:///workspace/.claude/docs/director-gates.md)，翻到"Gate Coverage by Stage"表，对照 7 阶段看每阶段要过哪些门。
4. 打开 [workflow-catalog.yaml](file:///workspace/.claude/docs/workflow-catalog.yaml)，找到 `concept` 阶段，看每个 step 的 `required` 和 `artifact` 字段，理解"必须做啥、怎么判断做完了"。
5. 打开 [templates/game-design-document.md](file:///workspace/.claude/docs/templates/game-design-document.md)，数一下必填的 8 节是哪些，理解为什么每节都要（特别是 Edge Cases 和 Acceptance Criteria）。
6. 打开 [context-management.md](file:///workspace/.claude/docs/context-management.md)，重点读"Incremental File Writing"和"Recovery After Session Crash"两节，理解长会话怎么不失忆。
7. 打开 [coding-standards.md](file:///workspace/.claude/docs/coding-standards.md)，看"Test Evidence by Story Type"表，理解为什么 Logic 故事要自动单测而 Visual/Feel 只要截图。
8. **验证运行时生效机制**：打开根 [CLAUDE.md](file:///workspace/CLAUDE.md)，数一下有几个 `@.claude/docs/...` 引用——这些才是运行时自动注入的文件。然后打开 [.claude/agents/lead-programmer.md](file:///workspace/.claude/agents/lead-programmer.md) 翻到底部 "Delegation Map" 段，对比 [.claude/docs/agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md) 的委派表，体会"内嵌局部视图（运行时用）" vs "全局汇总图（人读）"的关系。
9. 在 [.claude/agents/](file:///workspace/.claude/agents/) 目录里用编辑器搜 "Delegation Map"，数一下有多少个 agent 文件自带这段——这就是"运行时委派事实"的真正所在。

---

## 一句话带走

> **`.claude/docs/` = 入门手册（quick-start）+ 花名册与组织图（roster/map/rules）+ 总监门禁（director-gates）+ 三大标准（coding-standards/rules-reference/technical-preferences）+ 上下文秘籍（context-management）+ 流程目录（workflow-catalog）+ 钩子参考（hooks-reference）+ 38 个模板（templates）+ 个人配置模板。前半部分给 AI 读着协调，后半部分（模板）给 AI 套着写文档。**
