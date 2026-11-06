# 04 · Skill 技能系统

上一篇讲了"谁"（agent）。这一篇讲"怎么干"（skill）。73 个 `/slash` 命令是怎么定义、怎么触发、怎么串成流水线的。

---

## Skill 是什么

Skill = **可复用的标准作业流程（SOP）**，用 `/命令` 触发。

每个 skill 是 [.claude/skills/](file:///workspace/.claude/skills/) 下的一个子目录，里面有一个 `SKILL.md`。比如 `/dev-story` 对应 [skills/dev-story/SKILL.md](file:///workspace/.claude/skills/dev-story/SKILL.md)。

**Skill 和 Agent 的关系**：

- **Agent** 是"员工"——有人设、有工具权限、归某个主管管。
- **Skill** 是"作业流程"——分阶段、有路由、调度员工去干活。

一个 skill 可以调度多个 agent，一个 agent 可以被多个 skill 调用。比如 `gameplay-programmer` 会被 `/dev-story`、`/team-combat`、`/hotfix` 等多个 skill 调用。

---

## SKILL.md 的结构

看 [dev-story/SKILL.md](file:///workspace/.claude/skills/dev-story/SKILL.md) 的开头：

```markdown
---
name: dev-story
description: "Read a story file and implement it. Loads the full context..."
argument-hint: "[story-path]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, Task, AskUserQuestion
model: sonnet
---

# Dev Story
## Phase 1: Find the Story
## Phase 2: Load Full Context
## Phase 3: Route to the Right Programmer
## Phase 4: Implement
## Phase 5: Test Evidence Requirements
## Phase 6: Collect and Summarise
## Phase 7: Update Session State
```

**关键字段**：

| 字段 | 作用 |
|------|------|
| `name` | 命令名（`/dev-story`） |
| `description` | 一句话说明，给 `/help` 和 AI 识别用 |
| `argument-hint` | 参数提示（`[story-path]`） |
| `user-invocable: true` | 用户能直接敲命令触发 |
| `allowed-tools` | 这个 skill 能用哪些工具。注意 `Task` = 能派生子智能体 |
| `model` | 用哪个模型跑这个 skill |

**正文**：分 Phase 的执行流程。这是给 AI 读的"作业指导书"，告诉它每一步做什么、读什么文件、什么时候问用户、什么时候派子智能体。

---

## 73 个 Skill 的分类

来自 [README.md](file:///workspace/README.md) 的 Slash Commands 章节。按用途分 11 类：

| 类别 | 代表命令 | 干什么 |
|------|----------|--------|
| **入门导航** | `/start` `/help` `/project-stage-detect` | 引导你从零开始，判断你在哪一步 |
| **游戏设计** | `/brainstorm` `/design-system` `/map-systems` | 头脑风暴、系统地图、写 GDD |
| **美术资产** | `/art-bible` `/asset-spec` `/asset-audit` | 美术圣经、资产规格、审计 |
| **UX 界面** | `/ux-design` `/ux-review` | UX 规格和评审 |
| **架构** | `/create-architecture` `/architecture-decision` `/architecture-review` | 架构文档、ADR、评审 |
| **故事与冲刺** | `/create-epics` `/create-stories` `/dev-story` `/sprint-plan` | 史诗、故事、实现、冲刺 |
| **评审分析** | `/code-review` `/balance-check` `/scope-check` `/gate-check` | 代码/平衡/范围/门禁评审 |
| **QA 测试** | `/qa-plan` `/smoke-check` `/regression-suite` `/test-setup` | 测试计划、冒烟、回归、框架 |
| **生产管理** | `/milestone-review` `/retrospective` `/bug-report` | 里程碑、复盘、bug |
| **发布** | `/release-checklist` `/launch-checklist` `/changelog` `/hotfix` | 发布清单、变更日志、热修 |
| **团队编排** | `/team-combat` `/team-narrative` `/team-ui` `/team-qa` ... | 多智能体协同做某个功能 |

**编排启示**：skill 不是随便堆的，是按**软件开发生命周期**分类的。从概念到发布，每个阶段都有对应技能。这就是"流程编排"。

---

## 7 阶段流水线：workflow-catalog

这是整个项目的"主流程骨架"。来自 [workflow-catalog.yaml](file:///workspace/.claude/docs/workflow-catalog.yaml)。

```
1. concept          概念      → 把想法变成文档化的概念
2. systems-design   系统设计  → 为每个系统写 GDD
3. technical-setup  技术设置  → 架构决策、ADR、控制清单
4. pre-production   预制作    → UX 规格、资产规格、原型、史诗、故事
5. production       制作      → 冲刺循环：实现故事、代码审查、关闭
6. polish           打磨      → 性能、平衡、playtest
7. release          发布      → 发布清单、上线清单
```

**每个阶段有这些属性**：

```yaml
phases:
  concept:
    label: "Concept"
    description: "Develop your game idea into a documented concept"
    next_phase: systems-design      # 下一阶段
    steps:
      - id: brainstorm
        name: "Brainstorm"
        command: /brainstorm
        required: false              # 是否必需
        description: "..."
      - id: engine-setup
        command: /setup-engine
        required: true
        artifact:                    # 怎么判断这一步完成了
          glob: ".claude/docs/technical-preferences.md"
          pattern: "Engine: [^[]"
```

**关键设计**：

1. **`required: true/false`**：必需步骤阻塞进入下一阶段，可选步骤只是建议。
2. **`artifact`**：用文件 glob 模式自动检测"这一步做完了没"。比如 `engine-setup` 完成的标志是 `technical-preferences.md` 里有 `Engine: xxx` 字样。
3. **`repeatable: true`**：可重复步骤（比如每个系统都要写一个 GDD）。
4. **门禁是建议性的**：`/gate-check` 的判定是 ADVISORY，不硬阻塞。**用户永远有权决定是否前进**。

---

## `/help` 怎么用这个 catalog

`/help` 命令读 `workflow-catalog.yaml`，然后：

1. 检查每个阶段的 `artifact`（文件存不存在、模式匹不匹配）。
2. 判断"你大概在哪个阶段"。
3. 列出"当前阶段的下一步是什么"。

**这是编排的精妙之处**：AI 不靠猜，靠**文件存在性**判断进度。文件就是状态机。

---

## Skill 的内部结构：以 `/dev-story` 为例

`/dev-story` 是最核心的实现技能。我们拆它的 7 个 Phase（来自 [dev-story/SKILL.md](file:///workspace/.claude/skills/dev-story/SKILL.md)）：

### Phase 1: 找故事
- 有参数 → 直接读那个文件
- 没参数 → 查 `production/session-state/active.md` 找当前故事，或列出所有 `Status: Ready` 的故事让用户选

### Phase 2: 加载完整上下文
**关键设计**：实现前必须把所有上下文加载齐。要读：
- 故事文件（标题、ID、层、类型、TR-ID、验收标准、依赖）
- TR registry（`docs/architecture/tr-registry.yaml`，需求真源）
- 治理 ADR（决策和实现指南）
- 控制清单（`docs/architecture/control-manifest.md`，层级规则）
- 引擎偏好（命名规范、性能预算）

**还做依赖校验**：故事的依赖如果没完成，会停下来问用户"要继续吗、停下来、还是标记依赖完成"。

**还做清单版本校验**：故事的清单版本和当前清单版本不一致，会问用户"用新规则还是旧规则"。

### Phase 3: 路由到正确的程序员
**核心是路由表**：

| 故事上下文 | 派给谁 |
|------------|--------|
| Foundation 层 | `engine-programmer` |
| 任何层 - UI 类型 | `ui-programmer` |
| 任何层 - Visual/Feel 类型 | `gameplay-programmer` |
| Core/Feature - 玩法机制 | `gameplay-programmer` |
| Core/Feature - AI 行为 | `ai-programmer` |
| Core/Feature - 网络 | `network-programmer` |
| Config/Data - 无代码 | 不派 agent，直接改数据文件 |

**还会派引擎专家做副手**：当 ADR 标记引擎风险为 HIGH 时，强制派引擎专家验证。

### Phase 4: 实现
通过 `Task` 工具派生子智能体，把上下文包打包给它。子智能体写代码、写测试。

**关键指令**：实现必须遵循 ADR 的实现指南，尊重控制清单规则，不越界（不碰 Out of Scope 的文件）。

### Phase 5: 测试证据要求
不同故事类型要求不同证据：

| 类型 | 必需证据 |
|------|----------|
| Logic | 自动化单元测试（阻塞） |
| Integration | 集成测试或 playtest 记录（阻塞） |
| Visual/Feel | 证据文档（建议） |
| UI | 手动走查文档或交互测试（建议） |
| Config/Data | 无（冒烟检查即证据） |

### Phase 6: 汇总
收集：改了哪些文件、测试文件、是否越界、引擎风险、阻塞。输出结构化摘要。

### Phase 7: 更新会话状态
悄悄往 `production/session-state/active.md` 追加一条记录。这是"文件即记忆"的体现（详见 [08 上下文管理](file:///workspace/study-docs/08-上下文管理艺术.md)）。

---

## Skill 的协作协议

每个 skill 都遵守 [COLLABORATIVE-DESIGN-PRINCIPLE.md](file:///workspace/docs/COLLABORATIVE-DESIGN-PRINCIPLE.md) 的五步：

```
Question → Options → Decision → Draft → Approval
```

`/dev-story` 在 Phase 2 的清单版本校验就是典型：

1. **Question**：检测到版本不一致
2. **Options**：用 `AskUserQuestion` 给三个选项（用新规则/用旧规则/停下来看 diff）
3. **Decision**：用户选
4. **Draft**：按选择更新故事文件的清单版本字段
5. **Approval**：进入下一阶段前隐含确认

详见 [07 协作协议](file:///workspace/study-docs/07-协作协议与人在环.md)。

---

## Team Skill：多智能体协同

`/team-*` 系列是编排的高阶形态。以 [team-combat/SKILL.md](file:///workspace/.claude/skills/team-combat/SKILL.md) 为例，它编排 7 个智能体做一个战斗功能：

```
game-designer        设计机制
gameplay-programmer  实现核心代码
ai-programmer        实现 NPC AI
technical-artist     做 VFX
sound-designer       定义音频事件
engine specialist    验证引擎惯用法
qa-tester            写测试、验证
```

**6 阶段流水线**：

```
Phase 1: 设计      → game-designer 写设计文档
Phase 2: 架构      → gameplay-programmer 画架构草图 + 引擎专家验证
                     [用户批准才进下一阶段]
Phase 3: 并行实现  → 4 个智能体同时干（gameplay + ai + tech-artist + sound）
Phase 4: 集成      → 把各子系统接起来
Phase 5: 验证      → qa-tester 写测试、跑测试
Phase 6: 签字      → 汇总状态：COMPLETE / NEEDS WORK / BLOCKED
```

**关键编排细节**：

1. **Phase 间有用户批准门**：每个 Phase 转换都要 `AskUserQuestion` 让用户确认。
2. **Phase 3 是并行**：4 个独立子智能体同时派生，符合"并行任务协议"（先发后等）。
3. **错误恢复协议**：任何子智能体 BLOCKED 立即上报，给用户三个选项（跳过/重试/停下）。
4. **文件写入委托**：编排器自己不写文件，所有写操作委托给子智能体，每个子智能体单独执行"我可以写到这个路径吗"协议。

---

## Review Mode：可调节的严格度

来自 [team-combat/SKILL.md](file:///workspace/.claude/skills/team-combat/SKILL.md) 的 Phase 0。这是个很实用的设计：

| 模式 | 行为 |
|------|------|
| `full` | 派所有总监和主管门禁 |
| `lean` | 只派阶段门禁（跳过中间总监门禁） |
| `solo` | 跳过所有门禁，技能自己跑 |

**怎么选**：
- 命令行加 `--review solo` 单次覆盖
- 否则读 `production/review-mode.txt`
- 否则默认 `lean`

**编排启示**：编排不是"一刀切"。给用户一个"严格度旋钮"，让用户按场景调。重要功能用 full，快速原型用 solo。

---

## Skill 的错误恢复协议

几乎所有 skill 末尾都有"Error Recovery Protocol"。来自 [dev-story/SKILL.md](file:///workspace/.claude/skills/dev-story/SKILL.md)：

```
如果任何派生的 agent 返回 BLOCKED、出错、或无法完成：

1. 立即上报：在继续依赖阶段前，先告诉用户"[AgentName]: BLOCKED — [原因]"
2. 评估依赖：检查被阻塞 agent 的输出是否被后续阶段需要。如果是，不要越过那个依赖点
3. 用 AskUserQuestion 给选项：
   - 跳过这个 agent，在最终报告里标注缺口
   - 用更窄的范围重试
   - 停下来先解决阻塞
4. 总是产出部分报告：哪怕部分阻塞，也要把已完成的部分汇报出来
```

**核心原则**：
- **不静默吞错**：BLOCKED 必须告诉用户。
- **不因部分失败丢弃已完成**：总要出部分报告。
- **依赖链断了就停**：不要在缺依赖的情况下硬走。

**这是编排的"韧性设计"**。AI 编排最容易出的错就是"某个子任务失败，整个流程崩了或静默继续"。这个协议两头堵死。

---

## 小测验

**Q1**：`/dev-story` 在实现前为什么要读那么多文件（故事、TR registry、ADR、控制清单、引擎偏好）？
> **A**：因为"上下文不全 = 代码漂离设计"。故事的验收标准可能过时（要查 TR registry 的最新需求），实现方式必须遵循 ADR，编码必须符合控制清单的层级规则。少读一个，就可能写出不符合设计的代码。

**Q2**：`/team-combat` 的 Phase 3 为什么能并行派 4 个智能体？
> **A**：因为这 4 个智能体（gameplay-programmer / ai-programmer / technical-artist / sound-designer）的输入互不依赖——玩法代码、AI、VFX、音频可以同时开工。符合"并行任务协议"：独立就并行，依赖就串行。

**Q3**：`workflow-catalog.yaml` 里的 `artifact` 字段是干什么的？
> **A**：自动检测"这一步做完了没"。用文件 glob 模式（必要时加文本 pattern）判断。比如 `engine-setup` 完成的标志是 `technical-preferences.md` 里有 `Engine: xxx`。这让 `/help` 能靠文件存在性判断进度，不靠 AI 猜。

---

## 动手

1. 打开 [workflow-catalog.yaml](file:///workspace/.claude/docs/workflow-catalog.yaml)，找到 `production` 阶段，数数它有几个 step，哪些 `required: true`，哪些 `repeatable: true`。
2. 打开 [skills/start/SKILL.md](file:///workspace/.claude/skills/start/SKILL.md)，看看 `/start` 这个入门命令是怎么"问你在哪一步"的。
3. 对比 [skills/dev-story/SKILL.md](file:///workspace/.claude/skills/dev-story/SKILL.md) 和 [skills/team-combat/SKILL.md](file:///workspace/.claude/skills/team-combat/SKILL.md)，看单个智能体调度和多智能体协同的 skill 写法有什么不同。

下一篇 → [05 Hook 自动化守卫](file:///workspace/study-docs/05-Hook自动化守卫.md)
