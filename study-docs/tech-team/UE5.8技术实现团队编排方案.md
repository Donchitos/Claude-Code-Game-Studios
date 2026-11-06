# UE 5.8 技术实现团队编排方案

> 从 [Claude Code Game Studios](file:///workspace/README.md) 项目裁剪出"需求 → 技术实现"的 Agent 协作编排,以 **Unreal Engine 5.8** 为开发技术栈,以 **Context7 MCP** 作为引擎知识的运行时权威源。

---

## 0. 这份方案解决什么问题

原项目把一个 Claude Code 会话编排成 49 agent / 73 skill / 12 hook / 11 rule 的完整虚拟工作室(见 [01-项目概览](file:///workspace/study-docs/01-项目概览.md))。完整工作室覆盖概念→发布的全流程,但大多数角色(创意/美术/音频/叙事/发行/本地化)不产生代码。

本方案的诉求很窄:**只要"需求 → 技术实现"这一段,用 agent 协作把代码做出来**。所以保留原项目的"技术骨架",砍掉所有非代码域,并把引擎专家固定为 UE 5.8 子团队。

| 维度 | 原项目 | 本方案 |
|------|--------|--------|
| Agent | 49 | 12 核心 + 4 可选(+4 UE 子专家) |
| Skill | 73 | 12 核心 + 5 可选 |
| 阶段 | 7(概念→发布) | 3(技术准备→需求拆解→实现循环) |
| 引擎 | Godot/Unity/Unreal 三选一 | 固定 UE 5.8 |
| 知识源 | 静态 `docs/engine-reference/` 目录 | Context7 MCP 运行时查询 |

**核心心智模型不变**(见 [12-从零编排智能体协作](file:///workspace/study-docs/12-从零编排智能体协作.md)):

> 编排 = `CLAUDE.md` 定方向 + `agents/` 分角色 + `skills/` 串流程 + `hooks/` 守底线 + `rules/` 管细节 + 文件当记忆。

---

## 1. Context7 与引擎设置技能的关系(关键澄清)

用户已确定 UE 5.8,并约定用 Context7 MCP 提供最新知识库。这引出一个问题:**还需要 `/setup-engine` 吗?**

**答案:需要,但职能变了。**

Context7 解决的是"UE 5.8 API 知识获取"——通过 `resolve-library-id` + `query-docs` 两个工具运行时查最新官方文档。它替代了原项目的静态知识校验机制([docs/engine-reference/unreal/](file:///workspace/docs/engine-reference/unreal/) 目录 + `VERSION.md` 的知识缺口警告)。

但 Context7 解决不了三件事,这三件事正是 `/setup-engine` 保留的理由:

| Context7 能做 | Context7 做不了(需 `/setup-engine`) |
|---------------|--------------------------------------|
| 查 UE 5.8 某 API 是否存在/签名 | 固化项目级命名规范(class/变量/文件命名) |
| 查 GAS/Enhanced Input 用法 | 固化性能预算(帧率、帧预算、内存上限) |
| 查 5.8 破坏性变更 | 固化目标平台与输入方式 |
| — | 固化测试框架与最低覆盖率 |
| — | 固化 UE 子专家路由表(哪个文件类型派哪个 `ue-*-specialist`) |

**改造后的 `/setup-engine`(轻量版)**:

- 引擎字段预填 `Unreal Engine 5.8`,不再问
- 知识源预填 `Context7 MCP`,不再维护静态 `docs/engine-reference/` 目录
- 只问 5 个问题:目标平台、输入方式、命名规范、性能预算、测试框架
- 产物:`.claude/docs/technical-preferences.md`(被 dev-story / code-review / architecture-decision 读取的配置契约)
- 同时写 `.claude/docs/engine-specialists.md`:UE 子专家路由表

**编排点**:把"用 Context7 查 UE API"这条规则写进 `CLAUDE.md` 和每个 UE 相关 agent 的描述里(见第 10 节)。

---

## 2. 精简后的流水线(3 阶段 + 1 验收环)

把原 7 阶段(见 [workflow-catalog.yaml](file:///workspace/.claude/docs/workflow-catalog.yaml))压缩为 3 阶段。砍掉 Concept / Systems Design 的设计文档环节(需求由用户直接给)、Pre-Production 的 UX/资产/原型环节、Polish 的 playtest 环节、Release 环节。

```
┌──────────────────┐   ┌──────────────────────┐   ┌─────────────────────────────────┐
│ 阶段 A 技术准备    │ → │ 阶段 B 需求拆解        │ → │ 阶段 C 实现循环(可重复)          │
│ Technical Setup   │   │ Requirements Breakdown│   │ Implementation Loop             │
└──────────────────┘   └──────────────────────┘   └─────────────────────────────────┘
  /setup-engine(轻量)    /create-architecture       ┌→ /story-readiness
  /architecture-          /architecture-decision    │  /dev-story       ← 核心主链
  decision(≥3 ADR)        /create-control-manifest  │  /code-review
  /architecture-review    /create-epics             │  /story-done    ──┘
                          /create-stories           │  (每轮 sprint 循环)
                                                    │
                                                    └─→ /team-feature(复杂功能多 agent 并行)
                                                        /gate-check(阶段切换,只过 TD 门)
```

**关键设计(沿袭原项目)**:

1. **文件即状态机**——`/help` 靠 artifact glob 判断你走到哪一步(见 [04-Skill技能系统](file:///workspace/study-docs/04-Skill技能系统.md#L83-L124))。例:`architecture-review` 完成的标志是 `docs/architecture/architecture-review-*.md` 存在。
2. **`required: true` 阻塞下一阶段**,`required: false` 只是建议。
3. **门禁是建议性的**——`/gate-check` 裁决是 ADVISORY,不硬阻塞。**用户永远有权决定是否推进**(见 [04 文档](file:///workspace/study-docs/04-Skill技能系统.md#L120-L124))。
4. **每个故事走四步闭环**(见 [dev-story/SKILL.md](file:///workspace/.claude/skills/dev-story/SKILL.md#L17-L23)):
   ```
   /story-readiness [path]   ← 实现前校验
   /dev-story [path]         ← 实现(核心)
   /code-review [files]      ← 审查
   /story-done [path]        ← 验收关单
   ```

**精简版 workflow-catalog.yaml 骨架**:

```yaml
phases:
  technical-setup:
    label: "Technical Setup"
    next_phase: requirements-breakdown
    steps:
      - id: setup-engine
        command: /setup-engine
        required: true
        artifact: { glob: ".claude/docs/technical-preferences.md", pattern: "Engine: Unreal Engine 5.8" }
      - id: architecture-decision
        command: /architecture-decision
        required: true
        repeatable: true
        artifact: { glob: "docs/architecture/adr-*.md", min_count: 3 }
      - id: create-architecture
        command: /create-architecture
        required: true
        artifact: { glob: "docs/architecture/architecture.md" }
      - id: create-control-manifest
        command: /create-control-manifest
        required: true
        artifact: { glob: "docs/architecture/control-manifest.md" }
      - id: architecture-review
        command: /architecture-review
        required: true
        artifact: { glob: "docs/architecture/architecture-review-*.md" }

  requirements-breakdown:
    label: "Requirements Breakdown"
    next_phase: implementation
    steps:
      - id: create-epics
        command: /create-epics
        required: true
        repeatable: true
        artifact: { glob: "production/epics/*/EPIC.md", min_count: 1 }
      - id: create-stories
        command: /create-stories
        required: true
        repeatable: true
        artifact: { glob: "production/epics/**/*.md", min_count: 2 }

  implementation:
    label: "Implementation"
    next_phase: null
    steps:
      - id: story-readiness
        command: /story-readiness
        required: false
      - id: dev-story
        command: /dev-story
        required: true
        repeatable: true
      - id: code-review
        command: /code-review
        required: false
        repeatable: true
      - id: story-done
        command: /story-done
        required: true
        repeatable: true
      - id: team-feature
        required: false
        repeatable: true
        description: "复杂功能多 agent 并行编排"
      - id: gate-check
        command: /gate-check
        required: false
        description: "阶段切换前技术门禁(只过 TD-PHASE-GATE)"
```

---

## 3. Agent 清单(三层结构)

保留原项目三层架构(总监/主管/专家,见 [03-Agent编排体系](file:///workspace/study-docs/03-Agent编排体系.md#L7-L71)),垂直委派不跳层。砍掉所有非技术域角色。

### Tier 1 — 总监(1)

| Agent | 模型 | 职责 | 来源 |
|-------|------|------|------|
| `technical-director` | opus | 架构所有权、ADR 审批、技术冲突仲裁、性能预算、引擎风险把关 | [technical-director.md](file:///workspace/.claude/agents/technical-director.md) |

> 砍掉 `creative-director`、`producer`。所有"愿景/进度/范围"决策由你(人类)直接做,不再有 agent 介入。`technical-director` 的 `memory: user` 保留,跨会话记住你的技术偏好。

### Tier 2 — 主管(2)

| Agent | 模型 | 职责 | 来源 |
|-------|------|------|------|
| `lead-programmer` | sonnet | 代码架构、code review、委派专家、模式执行 | [lead-programmer.md](file:///workspace/.claude/agents/lead-programmer.md) |
| `qa-lead` | sonnet | 测试计划、可测性审查、QA 门禁 | qa-lead.md |

> `lead-programmer` 的 `memory: project` 保留,跨会话记住架构决策上下文(原项目有 [.claude/agent-memory/lead-programmer/MEMORY.md](file:///workspace/.claude/agent-memory/lead-programmer/MEMORY.md))。

### Tier 3 — 程序员专家(6 核心 + 4 可选)

| Agent | 模型 | 职责 | 可选 |
|-------|------|------|------|
| `engine-programmer` | sonnet | Foundation 层、引擎系统、子系统封装 | — |
| `gameplay-programmer` | sonnet | 玩法机制、状态机、输入、Visual/Feel | — |
| `ai-programmer` | sonnet | AI 行为、行为树、寻路 | — |
| `ui-programmer` | sonnet | UMG/CommonUI 实现 | — |
| `qa-tester` | haiku/sonnet | 写测试、跑测试、报 bug | — |
| `network-programmer` | sonnet | 复制、预测、RPC | 多人时启用 |
| `tools-programmer` | sonnet | 开发工具、编辑器扩展、Slates | 可选 |
| `performance-analyst` | sonnet | Unreal Insights 性能分析、瓶颈定位 | 可选 |

### UE 5.8 子团队(4 核心 + 1 可选)——可插拔引擎模块

这是原项目"可插拔引擎"设计的直接应用(见 [03 文档](file:///workspace/study-docs/03-Agent编排体系.md#L177-L190))——把 Godot/Unity 两个团队整个删掉,只留 Unreal 团队。

| Agent | 职责 | 来源 |
|-------|------|------|
| `unreal-specialist` | UE 总权威,BP/C++ 边界、子系统把关、派子专家 | [unreal-specialist.md](file:///workspace/.claude/agents/unreal-specialist.md) |
| `ue-gas-specialist` | GAS、Gameplay Effects、Attribute Sets、Tags | ue-gas-specialist.md |
| `ue-blueprint-specialist` | Blueprint 架构、BP/C++ 边界、图标准 | ue-blueprint-specialist.md |
| `ue-umg-specialist` | UMG、CommonUI、控件层级、数据绑定 | ue-umg-specialist.md |
| `ue-replication-specialist` | 属性复制、RPC、预测、相关性 | 多人时启用 |

> 这 5 个 agent 都具备 `Task` 工具,可被 `unreal-specialist` 进一步委派(原设计,见 [unreal-specialist.md](file:///workspace/.claude/agents/unreal-specialist.md#L154-L163))。

### 委派关系(精简后)

```
technical-director (opus, memory: user)
  ├─ lead-programmer (sonnet, memory: project)
  │    ├─ engine-programmer
  │    ├─ gameplay-programmer
  │    ├─ ai-programmer
  │    ├─ ui-programmer
  │    ├─ network-programmer (opt)
  │    └─ tools-programmer (opt)
  ├─ qa-lead (sonnet)
  │    └─ qa-tester
  └─ unreal-specialist (sonnet)
       ├─ ue-gas-specialist
       ├─ ue-blueprint-specialist
       ├─ ue-umg-specialist
       └─ ue-replication-specialist (opt)
```

**冲突升级路径(精简后)**:

| 冲突场景 | 升级给谁 |
|----------|----------|
| 两个程序员对实现有分歧 | `lead-programmer` |
| 代码架构分歧 | `technical-director` |
| UE 子专家与 gameplay-programmer 对 GAS 用法分歧 | `unreal-specialist` → `technical-director` |
| 引擎 API 风险(Context7 查证后仍有分歧) | `technical-director` |
| 性能预算冲突 | `technical-director` |
| 跨系统代码冲突 | `lead-programmer` → `technical-director` |

---

## 4. Skill 清单(按阶段)

| 阶段 | Skill | 作用 | 改动 |
|------|-------|------|------|
| 入口 | `/start`(简化) | 检测项目状态,路由到正确阶段 | **改**:不问"游戏创意",只问"有无现成需求/feature spec" |
| 入口 | `/help` | 读 workflow-catalog,告诉你下一步 | 原样,读精简版 catalog |
| A | `/setup-engine`(轻量) | 固化技术契约 + UE 子专家路由表 | **改**:UE 5.8 + Context7 预填,只问 5 项 |
| A | `/architecture-decision` | 写 ADR(≥3 个 Foundation 层) | 原样,见 [architecture-decision/SKILL.md](file:///workspace/.claude/skills/architecture-decision/SKILL.md) |
| A | `/create-architecture` | 主架构文档 | 原样 |
| A | `/create-control-manifest` | 从 ADR 生成扁平程序员规则表 | 原样 |
| A | `/architecture-review` | 验证 ADR 覆盖度、依赖顺序、引擎兼容 | **改**:引擎兼容检查改用 Context7 |
| B | `/create-epics` | 拆 epic(按架构模块) | **改**:需求来源改为用户 feature spec,不依赖 GDD |
| B | `/create-stories` | epic 拆 story | 原样 |
| C | `/story-readiness` | 实现前校验 story 就绪 | 原样 |
| C | `/dev-story` | **核心主链**:加载上下文→路由→实现→测试→汇总 | 路由表保留,见第 9 节 |
| C | `/code-review` | 架构+质量+ADR 合规审查 | 原样,见 [code-review/SKILL.md](file:///workspace/.claude/skills/code-review/SKILL.md) |
| C | `/story-done` | 验收标准核对、关单 | 原样 |
| C | `/qa-plan` | 每个 epic/sprint 的测试计划 | 原样 |
| C | `/team-feature`(新) | 复杂功能多 agent 并行编排 | **新建**:把 9 个 `team-*` 压成 1 个通用编排 |
| 门禁 | `/gate-check` | 阶段切换裁决 | **改**:只过 TD 门,砍掉 CD/PR/AD 门 |
| 可选 | `/test-setup` | 测试框架脚手架 | 原样 |
| 可选 | `/smoke-check` | 冒烟测试 | 原样 |
| 可选 | `/regression-suite` | 回归测试 | 原样 |
| 可选 | `/project-stage-detect` | 褐地项目阶段检测 | 原样 |
| 可选 | `/adopt` | 褐地项目格式审计 | 原样 |

### `/team-feature` —— 通用多 agent 编排(关键新建)

原项目有 9 个领域团队 skill(`/team-combat` `/team-narrative` `/team-ui` 等,见 [team-combat/SKILL.md](file:///workspace/.claude/skills/team-combat/SKILL.md))。技术实现场景不需要按"战斗/叙事/UI"分,只需要一个通用编排。

**6 阶段流水线**(直接对应 [team-combat](file:///workspace/.claude/skills/team-combat/SKILL.md) 的模式 2+3+8+9):

```
Phase 1: 设计/需求澄清  → 用户 + lead-programmer 澄清需求边界
Phase 2: 架构            → lead-programmer 画架构 + unreal-specialist 验证引擎惯用法
                          [AskUserQuestion 批准才进下一阶段]
Phase 3: 并行实现        → gameplay-programmer + ai-programmer + ui-programmer + (network-programmer)
                          4 个独立子智能体同时派生(先发后等)
Phase 4: 集成            → lead-programmer 把各子系统接起来
Phase 5: 验证            → qa-tester 写测试、跑测试
Phase 6: 签字            → 汇总:COMPLETE / NEEDS WORK / BLOCKED
```

**沿用原项目的四条铁律**(见 [04 文档](file:///workspace/study-docs/04-Skill技能系统.md#L273-L294)):
- 每个 Phase 间 `AskUserQuestion` 让用户确认
- Phase 3 并行派生符合"并行任务协议"(先发后等、收齐再走)
- 任何子智能体 BLOCKED 立即上报,给用户三选项(跳过/重试/停下)
- 文件写入委托给子智能体,每个单独执行"May I write to [path]?"

---

## 5. 三层规则源(精简后)

沿用原项目三层架构(见 [12 文档](file:///workspace/study-docs/12-从零编排智能体协作.md#L74-L92)),只保留技术相关。

```
第 1 层  agents/[name].md         员工档案(第 3 节已列)
第 2 层  skills/[name]/SKILL.md    作业指导书(第 4 节已列)
第 3 层  docs/                     公司制度
           coordination-rules.md   5 条核心规则 + 并行协议
           agent-coordination-map  精简委派/升级表(第 3 节末)
           director-gates.md       只留 TD-*/LP-*/QL-* 门(第 7 节)
           workflow-catalog.yaml   3 阶段流水线(第 2 节)
           technical-preferences   UE 5.8 配置(/setup-engine 写)
           engine-specialists.md   UE 子专家路由表(/setup-engine 写)
```

**三层关系**(沿袭原项目,见 [12 文档](file:///workspace/study-docs/12-从零编排智能体协作.md#L211-L229)):

```
用户敲 /dev-story path
   ↓
主会话读 skills/dev-story/SKILL.md(第 2 层:作业指导书)
   ↓ SKILL.md 说"派 gameplay-programmer"
主会话读 agents/gameplay-programmer.md(第 1 层:员工档案)
   → 知道它用 Sonnet、能用 Read/Write/Edit/Bash、maxTurns 20
   ↓ SKILL.md 说"并行派 4 个实现智能体"
主会话查 coordination-rules.md(第 3 层:公司制度)
   → 确认并行协议:先发后等、收齐再走、阻塞立即上报
   ↓
主会话发 4 个 Task 调用(并行)
```

---

## 6. 协调规则(只留 5 条核心)

原样保留(见 [coordination-rules.md](file:///workspace/.claude/docs/coordination-rules.md)),技术团队完全适用:

1. **垂直委派不跳层**——主管委派给专家,不跳层。`technical-director` 不能直接派 `gameplay-programmer`,要走 `lead-programmer`。
2. **同级可咨询不能下命令**——`gameplay-programmer` 可问 `ai-programmer`"敌人 AI 怎么接收伤害事件",但不能直接改它的文件。
3. **冲突找共同上级**——两个程序员吵架找 `lead-programmer`;程序员和 UE 子专家吵架找 `technical-director`。
4. **跨域改动协调**——一个改动影响多个子系统,由 `lead-programmer` 协调(原项目是 producer,本方案 producer 被砍,职责归 lead-programmer)。
5. **不许改别人家的文件(域边界铁律)**——`gameplay-programmer` 不能改 `src/ui/` 下的文件,要改得让 `ui-programmer` 来或由 `lead-programmer` 显式委派。

**并行任务协议**(原样保留,见 [03 文档](file:///workspace/study-docs/03-Agent编排体系.md#L249-L258)):
1. 先发后等:所有独立的 Task 调用一起发出
2. 收齐再走:所有结果收齐再进依赖阶段
3. 阻塞立即上报:任何智能体 BLOCKED 立刻告诉用户
4. 必出部分报告:哪怕部分阻塞也要汇报已完成的部分

**五大反模式**(原样保留,见 [03 文档](file:///workspace/study-docs/03-Agent编排体系.md#L163-L173)):
绕过层级 / 跨域实现 / 影子决策 / 巨型任务 / 基于假设的实现。

---

## 7. 门禁清单(只留技术域)

从 [director-gates.md](file:///workspace/.claude/docs/director-gates.md) 砍掉所有 `CD-*`(创意)、`PR-*`(制作人)、`AD-*`(美术)、`ND-*`(叙事)门。保留:

| 门禁 ID | Agent | 触发时机 | 作用 |
|---------|-------|----------|------|
| `TD-ARCHITECTURE` | technical-director | 主架构文档草拟后 | 架构签收 |
| `TD-ADR` | technical-director | 每个 ADR 写完后 | ADR 审查 |
| `TD-FEASIBILITY` | technical-director | 早期技术风险识别 | 可行性评估 |
| `TD-ENGINE-RISK` | technical-director | 涉及 UE API 决策时 | **改用 Context7 验证**(第 10 节) |
| `TD-PHASE-GATE` | technical-director | `/gate-check` 阶段切换 | 技术就绪裁决 |
| `LP-FEASIBILITY` | lead-programmer | 架构文档写完后 | 实现可行性 |
| `LP-CODE-REVIEW` | lead-programmer | 每个 dev-story 后 | 代码审查 |
| `QL-STORY-READY` | qa-lead | story 入 sprint 前 | 可测性检查 |
| `QL-TEST-COVERAGE` | qa-lead | sprint 收尾 | 测试覆盖审查 |

**三态裁决**(原样保留,见 [director-gates.md](file:///workspace/.claude/docs/director-gates.md#L97-L108)):`APPROVE/READY` / `CONCERNS [list]` / `REJECT/NOT READY [blockers]`。多个门并行时取最严——一个 NOT READY 全部 FAIL。

**Review Mode**(原样保留,见 [director-gates.md](file:///workspace/.claude/docs/director-gates.md#L26-L63)):
- `production/review-mode.txt` 全局配置,`--review` 单次覆盖
- `full` = 所有门 / `lean`(默认)= 只 PHASE-GATE / `solo` = 全跳过

---

## 8. Rule / Hook / 权限清单

### Rules(按 src/ 子目录生效)

原项目 rule 用 frontmatter `paths` 字段按目录生效(见 [engine-code.md](file:///workspace/.claude/rules/engine-code.md) 的 `paths: ["src/core/**"]`)。技术团队保留:

| Rule 文件 | 生效路径 | 核心约束 |
|-----------|----------|----------|
| `engine-code.md` | `src/core/**` | 零分配热路径、引擎不依赖玩法、API 线程安全、改前查 Context7 |
| `gameplay-code.md` | `src/gameplay/**` | 数据驱动、状态机显式转换、帧率无关、不直接引用 UI |
| `ai-code.md` | `src/ai/**` | 行为树/状态机分离、感知与决策解耦 |
| `network-code.md`(opt) | `src/network/**` | 服务端权威、客户端预测、最小复制 |
| `ui-code.md` | `src/ui/**` | UI 不持有游戏状态、事件驱动、CommonUI 规范 |
| `test-standards.md` | `tests/**` | 无随机种子、无时间依赖、无外部 I/O |
| `data-files.md` | `**/*.json` `**/*.yaml` `**/Data/**` | 数据驱动配置、schema 校验 |

每条 rule 末尾加一条 UE 5.8 专属:**"写 UE API 前先用 Context7 查证,不得仅依赖训练数据"**(见第 10 节)。

### Hooks(只留代码相关)

从 [.claude/hooks/](file:///workspace/.claude/hooks/) 12 个脚本里保留:

| Hook | 事件 | 作用 |
|------|------|------|
| `log-agent.sh` | SubagentStart | 审计日志:谁被派了、什么时候 |
| `log-agent-stop.sh` | SubagentStop | 审计日志:派了多久 |
| `validate-commit.sh` | PreToolUse(Bash) | 提交前校验:无硬编码、JSON 合法、ADR 引用 |
| `validate-push.sh` | PreToolUse(Bash) | 推送前校验:测试通过、无禁用模式 |
| `session-start.sh` | SessionStart | 告知当前分支、最近提交 |
| `session-stop.sh` | SessionStop | 会话结束清理 |
| `pre-compact.sh` / `post-compact.sh` | 上下文压缩前后 | 保存/恢复关键状态(见第 11 节) |

砍掉:`validate-assets.sh`(资产审计,美术域)、`validate-skill-change.sh`、`notify.sh`、`detect-gaps.sh`(可选保留用于技术债检测)。

### 权限(settings.json)

```json
{
  "permissions": {
    "allow": [
      "Bash(git status*)", "Bash(git diff*)", "Bash(git log*)", "Bash(git add*)",
      "Bash(git commit*)",
      "Bash(./Build/*)", "Bash(./RunUAT*)", "Bash(Engine/Binaries/*)",
      "Bash(python*automation*)",
      "Read(Source/**)", "Read(Content/**)"
    ],
    "deny": [
      "Bash(rm -rf *)", "Bash(git push --force*)", "Bash(git reset --hard*)",
      "Bash(git clean -f*)",
      "Read(**/.env*)", "Read(**/Saved/**)", "Read(**/Intermediate/**)",
      "Write(Engine/**)", "Write(Plugins/Marketplace/**)"
    ]
  }
}
```

UE 5.8 特有:放行 `Build`/`RunUAT`/UAT 自动化命令;禁止写 `Engine/` 和 `Plugins/Marketplace/`(只读引擎源码)。

---

## 9. 协作流程详解

### 9.1 单故事实现链(/dev-story)

以 `/dev-story production/epics/combat/melee-hitbox.md` 为例(沿用 [dev-story/SKILL.md](file:///workspace/.claude/skills/dev-story/SKILL.md#L136-L187)):

```
1. /dev-story 读故事 → 提取 TR-ID、ADR、验收标准、依赖、Out of Scope
2. 校验必需文件(tr-registry / ADR / control-manifest)
   ↓ 缺失则 STOP,引导用户先跑对应 skill
3. 并行加载上下文(5 个独立读,先发后等):
   - docs/architecture/tr-registry.yaml        需求真源(TR-ID 查 requirement 字段)
   - docs/architecture/adr-xxx-melee.md        治理 ADR(读 Decision + Implementation Guidelines)
   - docs/architecture/control-manifest.md     层级规则(Required/Forbidden patterns)
   - .claude/docs/technical-preferences.md     UE 5.8 命名规范、性能预算
   - Glob production/epics/**/*.md             依赖故事状态校验
4. 清单版本不一致 / 依赖未完成 → AskUserQuestion 三选项
5. 路由表(UE 5.8 版):
   | 故事上下文            | 主 agent            | 副手(引擎风险 HIGH 时)
   | Foundation 层         | engine-programmer   | unreal-specialist
   | UI 类型               | ui-programmer       | ue-umg-specialist
   | Visual/Feel           | gameplay-programmer | unreal-specialist
   | 玩法机制              | gameplay-programmer | ue-gas-specialist(若涉 GAS)
   | AI 行为               | ai-programmer       | unreal-specialist
   | 网络/复制             | network-programmer  | ue-replication-specialist
   | Config/Data           | 无 agent,直接改数据文件
6. Task 派生子智能体(prompt 给路径不给内容——见 [12 文档](file:///workspace/study-docs/12-从零编排智能体协作.md#L413-L420))
   → 子智能体:读文件 → 按 ADR 实现 → 写测试 → 遵守"May I write to [path]?"
   → 涉及 UE API 时先调 Context7 查证(第 10 节)
7. SubagentStart/Stop hook 自动记审计日志
8. /code-review [files] → lead-programmer + 并行派 unreal-specialist + qa-tester
9. /story-done [path]   → 核对验收标准、关单
```

**TR-ID 需求源**:原项目靠 `tr-registry.yaml` 索引 GDD 需求。技术实现场景没有 GDD,需求来自用户提供的 feature spec。两种做法:
- **轻量版**:feature spec 直接作为 TR 源,`tr-registry.yaml` 索引这些 spec 文件路径 + requirement 摘要
- **最简版**:不用 TR-ID,故事文件直接内联需求文本(但会失去 dev-story 的"查最新需求"防漂离机制)

推荐轻量版——保留 `tr-registry.yaml`,但 requirement 字段指向用户的 feature spec 而非 GDD。

### 9.2 复杂功能多 agent(/team-feature)

沿用 [team-combat](file:///workspace/.claude/skills/team-combat/SKILL.md) 的 6 阶段(第 4 节已述)。关键编排细节:

- **Phase 3 并行扇出**:4 个独立实现智能体同时派生,符合"先发后等"
- **Phase 2 引擎验证**:`unreal-specialist` 用 Context7 验证架构草图是否惯用 UE 5.8 模式
- **每个 Phase 间 `AskUserQuestion`**:用户批准才进下一阶段
- **错误恢复**:任何子智能体 BLOCKED 立即上报,给三选项(跳过/重试/停下),必出部分报告

### 9.3 三种触发模式对比

| 模式 | 命令 | 派几个 | 并行/串行 | 人在环 |
|------|------|--------|-----------|--------|
| 单智能体 | `/dev-story` | 1(+1 副手) | 串行 | 派之前确认上下文 |
| 编排团队 | `/team-feature` | 4-6 | 混合(Phase 3 并行) | 每 Phase 间确认 |
| 总监门禁 | `/gate-check` | 1(TD) | 串行 | 收裁决后用户决定是否推进 |

---

## 10. UE 5.8 + Context7 集成(新编排点,重点)

⚠️ **这是本方案最大的技术风险**。Context7 提供 `resolve-library-id` + `query-docs` 两个 MCP 工具(见工具描述),运行时查最新官方文档。

### 10.1 知识权威源约定

**原项目**靠静态 `docs/engine-reference/unreal/VERSION.md` + `breaking-changes.md` 校验知识缺口(见 [VERSION.md](file:///workspace/docs/engine-reference/unreal/VERSION.md) 的知识缺口警告)。

**本方案**改为 Context7 运行时查询。在 `CLAUDE.md` 顶部写死这条铁律:

```markdown
## UE 5.8 知识权威源(KNOWLEDGE AUTHORITY)

涉及任何 Unreal Engine API、类、节点、子系统前,必须:
1. 先调 Context7 MCP 的 resolve-library-id 查 "Unreal Engine",获取 library ID
2. 再调 query-docs 用具体 API 名/子系统名查询
3. Context7 查不到时,用 WebSearch 兜底(docs.unrealengine.com/5.8/)
4. 严禁仅依赖训练数据建议 UE API——5.4+ 全部在 LLM 知识截止之后

每个 UE 相关 agent 的实现/审查输出里,必须标注:
"API 验证:Context7 查询 [查询词] 于 [日期] — [确认/变更/未找到]"
```

### 10.2 TD-ENGINE-RISK 门禁改造

原 [TD-ENGINE-RISK](file:///workspace/.claude/docs/director-gates.md#L371-L388) 门读静态引擎参考文件。改造为:

```
触发:任何 ADR / dev-story / code-review 涉及 UE API 决策时
流程:
1. technical-director 调 Context7 resolve-library-id "Unreal Engine"
2. 用 query-docs 查具体 API/子系统
3. 裁决:
   - APPROVE:API 在 5.8 存在且签名与决策一致
   - CONCERNS:API 存在但有 5.4+ 变更,需调整实现
   - REJECT:API 在 5.8 已废弃/签名变更,决策不可行
```

### 10.3 在哪些地方接入 Context7

| 位置 | 何时调 Context7 |
|------|-----------------|
| `CLAUDE.md` 顶部 | 写死铁律(10.1) |
| 每个 UE 相关 agent 描述 | `unreal-specialist` / `ue-gas-specialist` / `ue-blueprint-specialist` / `ue-umg-specialist` / `ue-replication-specialist` / `engine-programmer` / `gameplay-programmer` / `ui-programmer` / `ai-programmer` 正文加"Engine Version Safety"段(原 [gameplay-programmer.md](file:///workspace/.claude/agents/gameplay-programmer.md#L81-L93) 已有,改为调 Context7) |
| `/architecture-decision` Step 1 | 原"读 VERSION.md"改为"调 Context7 查域内 API"(见 [architecture-decision/SKILL.md](file:///workspace/.claude/skills/architecture-decision/SKILL.md#L74-L115)) |
| `/architecture-review` | 引擎兼容检查改用 Context7 |
| `/code-review` Phase 2 | engine specialist 审查时用 Context7 核实 API 用法 |
| `/dev-story` Phase 3 | 引擎风险 HIGH 时派 unreal-specialist,后者必须先调 Context7 |
| 每条 rule 末尾 | 加"写 UE API 前先查 Context7" |

### 10.4 Context7 查询规范

- **先 resolve-library-id**:用 `libraryName: "Unreal Engine"` + `query: "<具体问题>"`。UE 官方文档可能在 Context7 有收录(需实测),若无则用 library ID 兜底或转 WebSearch。
- **再 query-docs**:用具体 API/类/子系统名作为 query,如 `"UAbilitySystemComponent ApplyGameplayEffectToTarget 5.8 signature"`。
- **限额**:Context7 两个工具各自每问题最多 3 次调用(见工具描述),query 要具体。
- **查不到的兜底**:`WebSearch` 查 `docs.unrealengine.com/5.8/` + `dev.epicgames.com`。

---

## 11. 上下文管理与记忆

沿用原项目"文件即记忆"机制(见 [08-上下文管理艺术](file:///workspace/study-docs/08-上下文管理艺术.md))。

### 11.1 文件即状态机

| 文件 | 作用 |
|------|------|
| `production/session-state/active.md` | 当前会话状态(dev-story Phase 7 追加) |
| `production/stage.txt` | 当前阶段(technical-setup/requirements-breakdown/implementation) |
| `production/review-mode.txt` | review 模式(full/lean/solo) |
| `docs/architecture/tr-registry.yaml` | 需求真源索引 |
| `docs/architecture/control-manifest.md` | ADR 扁平化规则表 |

### 11.2 Agent Memory(跨会话)

| Agent | memory 类型 | 记什么 |
|-------|-------------|--------|
| `technical-director` | `user` | 你的技术偏好、历史架构决策、性能预算取向 |
| `lead-programmer` | `project` | 项目架构约定、已完成 ADR、已知技术债 |

对应文件:`.claude/agent-memory/lead-programmer/MEMORY.md`(原项目已有,见 [MEMORY.md](file:///workspace/.claude/agent-memory/lead-programmer/MEMORY.md))。

### 11.3 压缩恢复

`pre-compact.sh` / `post-compact.sh` 在上下文压缩前后保存/恢复关键状态(原项目已有,保留)。

---

## 12. 目录结构(精简后)

```
CLAUDE.md                           项目章程(UE 5.8 技术栈 + 人在环协议 + Context7 铁律)
.claude/
  settings.json                     权限白/黑名单 + 代码类 hook
  agents/                           12-16 个 agent(只留技术域 + UE 团队)
  skills/                           12-17 个 skill
  hooks/                            log-agent*.sh / validate-commit.sh / validate-push.sh / session-*.sh / pre-post-compact.sh
  rules/                            engine/gameplay/ai/network/ui/test/data 规则
  agent-memory/
    lead-programmer/MEMORY.md       lead-programmer 跨会话记忆
  docs/
    coordination-rules.md           5 条核心规则 + 并行协议
    agent-coordination-map.md       精简委派/升级表
    director-gates.md               只留 TD-*/LP-*/QL-* 门
    workflow-catalog.yaml           3 阶段流水线
    technical-preferences.md        UE 5.8 配置(/setup-engine 写)
    engine-specialists.md           UE 子专家路由表(/setup-engine 写)
docs/
  architecture/                     architecture.md + adr-*.md + control-manifest.md + tr-registry.yaml
production/
  epics/                            epic 定义
  stories/  (或 epics/[slug]/story-*.md)
  sprints/                          sprint 计划
  session-state/active.md           会话状态
  review-mode.txt                   review 模式
  stage.txt                         当前阶段
src/
  core/                             Foundation 层(engine-programmer)
  gameplay/                         玩法层(gameplay-programmer)
  ai/                               AI 层(ai-programmer)
  ui/                               UI 层(ui-programmer)
  network/  (opt)                   网络层(network-programmer)
Content/                            UE 资产(只读于代码 agent)
Source/                             UE C++ 源码(对应 src/ 的 UE 工程结构)
tests/                              测试
```

> **src/ vs Source/**:UE 项目里 C++ 代码在 `Source/`,`src/` 可作为本编排的"逻辑层"概念映射。建议直接用 `Source/` 作为代码根,rule 的 `paths` 改为 `Source/core/**` 等。

---

## 13. 落地步骤(8 步)

对应 [12 文档第三部分](file:///workspace/study-docs/12-从零编排智能体协作.md#L452-L771)的搭建流程,精简适配。

### 步骤 1:写 CLAUDE.md(定方向)

```markdown
# UE 5.8 技术实现项目

## Technology Stack
- Engine: Unreal Engine 5.8
- Language: C++(主) + Blueprint(内容/原型)
- Knowledge Source: Context7 MCP(UE API 运行时权威源)
- VCS: Git

## UE 5.8 知识权威源
@.claude/docs/knowledge-authority.md   (第 10.1 节铁律)

## Coordination Rules
@.claude/docs/coordination-rules.md

## Collaboration Protocol
User-driven, not autonomous. Every task: Question → Options → Decision → Draft → Approval
```

### 步骤 2:建 `.claude/` 骨架(空目录)

照第 12 节结构建空目录。**不要一次堆 10 个 agent——先跑通一个,再扩展**(原项目反复强调,见 [12 文档](file:///workspace/study-docs/12-从零编排智能体协作.md#L771))。

### 步骤 3:定义第一个 agent(`gameplay-programmer`)

复制原 [gameplay-programmer.md](file:///workspace/.claude/agents/gameplay-programmer.md),把"Engine Version Safety"段改为调 Context7(第 10 节)。验证 `Task` 工具能派生:

```
Agent(subagent_type: "gameplay-programmer", description: "探索项目",
      prompt: "读 README.md,总结项目结构,涉及 UE API 时先调 Context7 查证")
```

### 步骤 4:定义第一个 skill(`/dev-story` 最小版)

复制原 [dev-story/SKILL.md](file:///workspace/.claude/skills/dev-story/SKILL.md),保留 7 Phase + 路由表 + 错误恢复协议。`allowed-tools` 必须含 `Task`。

### 步骤 5:配 `settings.json`(权限 + hook)

照第 8 节配置。白名单放行 git/UE 构建,黑名单拦 `rm -rf`/强推/写 Engine。

### 步骤 6:写协调规则(5 条)+ 委派表 + 门禁

照第 5、6、7 节写。规则要少而硬。

### 步骤 7:跑通第一个端到端故事

1. 写最小故事 `production/epics/test/story-001.md`(Type: Logic, 1-2 条验收标准)
2. 敲 `/dev-story production/epics/test/story-001.md`
3. 验证:
   - 主会话按 Phase 1→7 走?
   - 派对了 `gameplay-programmer`?
   - `agent-audit.log` 有记录?
   - 子智能体调了 Context7 查 UE API?
   - 遵守"May I write to [path]?"?
   - 输出汇总 + 下一步推荐?

**跑不通的常见原因**(见 [12 文档](file:///workspace/study-docs/12-从零编排智能体协作.md#L750-L755)):
- skill 的 `allowed-tools` 没含 `Task` → 不能派子智能体
- agent 名拼错 → `subagent_type` 找不到
- `maxTurns` 太小 → 子智能体没干完
- 没写协作协议 → 子智能体直接写文件不问

### 步骤 8:增量扩展

1. 加 `unreal-specialist` + 4 个 UE 子专家
2. 加 `/architecture-decision` + `/create-architecture` + `/create-control-manifest` + `/architecture-review`
3. 加 `/code-review` + `/story-done` + `/qa-plan`
4. 加 `/team-feature`(通用编排)
5. 加 `/gate-check`(只 TD-PHASE-GATE)
6. 加路径规则(rule 文件)
7. 加 TD/LP/QL 门禁

**每加一层先验证不破坏已有流程**。

---

## 14. 可选模块

### 14.1 多人游戏

启用 4 个额外件,其余不变:
- `network-programmer` + `ue-replication-specialist`(agent)
- `network-code.md`(rule,路径 `Source/network/**`)
- dev-story 路由表加"网络/复制 → network-programmer"行
- ADR 模板 Performance Implications 增加 Network 字段

### 14.2 性能专项

- `performance-analyst`(agent,Unreal Insights)
- `/perf-profile`(skill)
- TD-FEASIBILITY 门关注性能预算

### 14.3 开发工具

- `tools-programmer`(agent,编辑器扩展、Slate、Automation Tool)
- 用于构建自定义编辑器窗口、数据表导入导出工具

### 14.4 褐地接入

- `/project-stage-detect` + `/adopt`:已有 UE 项目接入本编排时,审计现有代码/ADR 格式合规性

---

## 15. 与原项目的对照表

| 维度 | 原项目 | 本方案 |
|------|--------|--------|
| 定位 | 完整虚拟工作室 | 技术实现团队 |
| Agent 数 | 49 | 12 核心 + 4 可选 + 4 UE 子专家(可 +1) |
| Skill 数 | 73 | 12 核心 + 5 可选 |
| 阶段数 | 7 | 3 |
| 总监 | creative/technical/producer | 只 technical |
| 主管 | 10 个 | 2(lead-programmer/qa-lead) |
| 引擎团队 | Godot/Unity/Unreal 三选一 | 固定 Unreal |
| 知识源 | 静态 docs/engine-reference/ | Context7 MCP 运行时 |
| 门禁 | CD/TD/PR/AD/ND/LP/QL 全套 | 只 TD/LP/QL |
| Review Mode | full/lean/solo | 同(只影响 TD 门) |
| 协作协议 | Question→Options→Decision→Draft→Approval | 同 |
| 并行协议 | 先发后等/收齐再走/阻塞上报/部分报告 | 同 |
| 五大反模式 | 绕层/跨域/影子/巨型/假设 | 同 |
| 文件即记忆 | active.md/stage.txt/review-mode.txt | 同 |
| Agent memory | lead-programmer: project / technical-director: user | 同 |
| dev-story 主链 | 7 Phase + 路由表 + 错误恢复 | 同(路由表 UE 化) |
| team-* 编排 | 9 个领域 skill | 1 个 /team-feature 通用 |
| gate-check | 4 总监并行 | 1 个 TD 串行 |

---

## 16. 小测验

**Q1**:Context7 能查 UE 5.8 API,为什么还要保留 `/setup-engine`?
> **A**:Context7 解决"知识获取",解决不了"项目级配置固化"——命名规范、性能预算、目标平台、测试框架、UE 子专家路由表。这些是 dev-story/code-review/architecture-decision 读取的配置契约,必须固化成文件。

**Q2**:`technical-director` 想直接派 `gameplay-programmer` 改代码,允许吗?
> **A**:不允许。垂直委派不跳层(第 6 节规则 1)。TD 要走 `lead-programmer` 再派 `gameplay-programmer`。

**Q3**:UE 5.8 的 GAS 用法,gameplay-programmer 该信训练数据还是 Context7?
> **A**:Context7。CLAUDE.md 铁律(第 10.1 节):5.4+ 全在 LLM 知识截止之后,严禁仅依赖训练数据。必须先 resolve-library-id 再 query-docs,查不到用 WebSearch 兜底。

**Q4**:`/team-feature` Phase 3 为什么要并行派 4 个智能体?
> **A**:这 4 个(gameplay/ai/ui/network)输入互不依赖,符合并行任务协议(第 6 节):独立就并行,先发后等,收齐再走。串行要等 4 倍时间。

**Q5**:子智能体能看到主会话之前调 Context7 查的结果吗?
> **A**:不能。子智能体是全新 Claude 实例,父子只有 `Task` 的 `prompt` 一根通道(见 [12 文档](file:///workspace/study-docs/12-从零编排智能体协作.md#L294-L316))。所以 skill 给子智能体的 prompt 要写明"涉及 UE API 时自己调 Context7 查证"。

**Q6**:从零搭建,为什么要先跑通单 agent 再扩展?
> **A**:每加一层验证不破坏已有流程(第 13 节步骤 8)。一次堆 10 个 agent,出问题不知道是哪个的锅。增量验证是工程化基本纪律。

---

## 一句话总结

> **保留原项目技术骨架(三层 agent + 三层规则 + dev-story 主链 + 代码类 hook/rule + 人在环五步 + 文件即记忆),砍掉所有非代码域,7 阶段压成 3 阶段,9 个 team-* 压成 1 个 /team-feature,Godot/Unity 团队换成 UE 5.8 子团队,静态引擎参考换成 Context7 运行时查询。最关键风险是 UE 5.8 远超 LLM 知识截止——必须强制走 Context7,不能信训练数据。**

---

## 参考文档

- [01-项目概览](file:///workspace/study-docs/01-项目概览.md)
- [03-Agent编排体系](file:///workspace/study-docs/03-Agent编排体系.md)
- [04-Skill技能系统](file:///workspace/study-docs/04-Skill技能系统.md)
- [12-从零编排智能体协作](file:///workspace/study-docs/12-从零编排智能体协作.md)
- [dev-story/SKILL.md](file:///workspace/.claude/skills/dev-story/SKILL.md)
- [team-combat/SKILL.md](file:///workspace/.claude/skills/team-combat/SKILL.md)
- [architecture-decision/SKILL.md](file:///workspace/.claude/skills/architecture-decision/SKILL.md)
- [code-review/SKILL.md](file:///workspace/.claude/skills/code-review/SKILL.md)
- [director-gates.md](file:///workspace/.claude/docs/director-gates.md)
- [workflow-catalog.yaml](file:///workspace/.claude/docs/workflow-catalog.yaml)
- [technical-director.md](file:///workspace/.claude/agents/technical-director.md)
- [unreal-specialist.md](file:///workspace/.claude/agents/unreal-specialist.md)
