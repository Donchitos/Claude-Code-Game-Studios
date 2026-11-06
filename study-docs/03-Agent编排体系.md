# 03 · Agent 编排体系

这一篇拆解 49 个智能体怎么组织、怎么分工、怎么合作、怎么处理冲突。这是整个项目最核心的编排智慧。

---

## 三层层级：模仿真实工作室

来自 [agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md) 和 [README.md](file:///workspace/README.md)：

```
Tier 1 — 总监层（Directors，Opus 模型）
  creative-director    technical-director    producer

Tier 2 — 主管层（Department Leads，Sonnet 模型）
  game-designer        lead-programmer       art-director
  audio-director       narrative-director    qa-lead
  release-manager      localization-lead

Tier 3 — 专家层（Specialists，Sonnet/Haiku 模型）
  gameplay-programmer  engine-programmer     ai-programmer
  network-programmer   tools-programmer      ui-programmer
  systems-designer     level-designer        economy-designer
  ...（共 30+ 个专家）
```

**为什么分三层？** 这是经典的组织设计。总监管"方向和愿景"，主管管"领域和标准"，专家管"具体执行"。每一层只关心自己那一层的事，复杂决策不跳层。

**类比**：医院。院长（总监）定方向，科室主任（主管）管本专业标准，主治医生（专家）看病开方。你不会让院长去开处方，也不会让实习生定科室战略。

---

## 每一层的职责定位

### Tier 1：总监 —— 守愿景、守架构、守进度

| 总监 | 守什么 | 关键职责 |
|------|--------|----------|
| `creative-director` | **愿景** | 游戏核心幻想、支柱、调性、跨部门创意冲突仲裁 |
| `technical-director` | **架构** | 技术栈、架构决策、性能策略、技术冲突仲裁 |
| `producer` | **进度** | 冲刺计划、里程碑、风险、跨部门协调 |

看 [creative-director.md](file:///workspace/.claude/agents/creative-director.md) 的人设开头：

> You are the Creative Director for an indie game project. You are the final authority on all creative decisions. Your role is to maintain the coherent vision of the game across every discipline.

注意"final authority on all creative decisions"——但这个 authority 是**提议权**，不是**最终决定权**。最终决定权在你（人类）。详见 [07 协作协议](file:///workspace/study-docs/07-协作协议与人在环.md)。

### Tier 2：主管 —— 管领域、定标准、带专家

| 主管 | 领域 | 能委派给哪些专家 |
|------|------|-------------------|
| `game-designer` | 游戏设计 | systems-designer, level-designer, economy-designer |
| `lead-programmer` | 代码架构 | gameplay/engine/ai/network/tools/ui-programmer |
| `art-director` | 视觉方向 | technical-artist, ux-designer |
| `audio-director` | 音频方向 | sound-designer |
| `narrative-director` | 叙事 | writer, world-builder |
| `qa-lead` | 质量 | qa-tester |

主管是"承上启下"的枢纽：总监委派任务给主管，主管拆解后委派给专家；专家干完汇报给主管，主管汇总后汇报给总监。

### Tier 3：专家 —— 干具体活

每个专家只管一摊。比如：
- `gameplay-programmer` 只写玩法代码
- `qa-tester` 只写测试和报 bug
- `writer` 只写对话和背景设定
- `economy-designer` 只管经济平衡

**关键设计**：专家的 `tools` 字段是最小权限的。比如 `qa-tester` 用 Haiku 模型（只读+格式化任务），`creative-director` 禁用 `Bash`（总监不跑命令）。

---

## 委派规则：谁能指挥谁

来自 [agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md) 的"Delegation Rules"表。核心是**垂直委派，不能跳层**：

```
creative-director  →  game-designer  →  systems-designer
       ↑                  ↑                    │
       │                  │                    │
       └── 跳过 game-designer 直接找 systems-designer？❌ 不行
```

完整委派关系（节选）：

| 谁委派 | 能委派给 |
|--------|----------|
| `creative-director` | game-designer, art-director, audio-director, narrative-director |
| `technical-director` | lead-programmer, devops-engineer, performance-analyst |
| `producer` | 任何智能体（但只能在对方领域内派活） |
| `game-designer` | systems-designer, level-designer, economy-designer |
| `lead-programmer` | gameplay/engine/ai/network/tools/ui-programmer |
| `qa-lead` | qa-tester |

**为什么不能跳层？** 因为跳层会绕过领域把关。如果创意总监直接找 `systems-designer` 改公式，就绕过了 `game-designer` 的设计审查，容易出设计冲突。

---

## 横向咨询：同级可以问，但不能下命令

来自 [coordination-rules.md](file:///workspace/.claude/docs/coordination-rules.md) 第 2 条：

> **Horizontal Consultation**: Agents at the same tier may consult each other but must not make binding decisions outside their domain.

**类比**：你和隔壁部门的同事可以聊天请教，但你不能命令他改他部门的代码。要跨部门协作，得走正式流程（找共同上级）。

**实例**：`gameplay-programmer` 写战斗代码时，可以问 `ai-programmer`"敌人 AI 那边怎么接收伤害事件"，但不能直接改 `ai-programmer` 的文件。要改，得让 `lead-programmer` 协调。

---

## 冲突升级：谈不拢找共同上级

来自 [agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md) 的"Escalation Paths"表：

| 冲突场景 | 升级给谁 |
|----------|----------|
| 两个设计师对机制有分歧 | `game-designer`（他们的共同上级） |
| 游戏设计 vs 叙事冲突 | `creative-director`（设计和叙事的共同上级） |
| 游戏设计 vs 技术可行性 | `producer` 协调，再升级到 `creative-director` + `technical-director` |
| 代码架构分歧 | `technical-director` |
| 跨系统代码冲突 | `lead-programmer`，再升级 `technical-director` |
| 进度冲突 | `producer` |
| 范围超容量 | `producer`，再升级 `creative-director` 决定砍什么 |
| 质量门禁分歧 | `qa-lead`，再升级 `technical-director` |

**核心原则**：**找共同上级**。两个下属吵架，找管他们俩的那个人。

**类比**：前端和后端吵架，找技术总监；产品和工程吵架，找 CEO。

---

## 变更传播：跨部门改动由 producer 协调

来自 [coordination-rules.md](file:///workspace/.claude/docs/coordination-rules.md) 第 4 条：

> **Change Propagation**: When a design change affects multiple domains, the `producer` agent coordinates the propagation.

**为什么是 producer？** 因为 producer 是唯一"不归任何单一领域"的总协调者。设计改了影响代码、测试、进度，只有 producer 能全盘协调。

**实例**（来自 [agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md) 的"Design Change Notification"）：

> 当设计文档变更时，game-designer 必须通知：
> - lead-programmer（实现影响）
> - qa-lead（测试计划要更新）
> - producer（进度影响评估）
> - 相关专家智能体

---

## 域边界：不许改别人家的文件

来自 [coordination-rules.md](file:///workspace/.claude/docs/coordination-rules.md) 第 5 条：

> **No Unilateral Cross-Domain Changes**: An agent must never modify files outside its designated directories without explicit delegation.

**这是编排的铁律**。`gameplay-programmer` 不能改 `src/ui/` 下的文件，要改得让 `ui-programmer` 来，或者由 `lead-programmer` 显式委派。

**为什么这么严？** 因为 AI 最容易犯的错就是"顺手改了不该改的地方"。明确域边界能防止连锁错误和职责混乱。

---

## 五大反模式（必须避免）

来自 [agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md) 末尾。这是给 AI 看的"不许做的事"：

1. **绕过层级**：专家不该做主管该做的决定，不请示就拍板。
2. **跨域实现**：智能体不该改自己领域外的文件，除非被显式委派。
3. **影子决策**：所有决定必须留文档。口头协议不留痕会导致矛盾。
4. **巨型任务**：每个任务必须 1-3 天能做完。做不完就先拆分。
5. **基于假设的实现**：规格模糊时必须问，不能猜。猜错的代价比问一句高得多。

**这五条是编排的"防呆设计"**。每一条都对应 AI 最容易犯的错。

---

## 引擎专家：可插拔的子团队

这是个很巧妙的设计。项目支持三大引擎（Godot/Unity/Unreal），每个引擎有自己的"子团队"：

| 引擎 | 主管 | 子专家 |
|------|------|--------|
| Godot 4 | `godot-specialist` | GDScript / C# / Shader / GDExtension 专家 |
| Unity | `unity-specialist` | DOTS / Shader / Addressables / UI 专家 |
| Unreal 5 | `unreal-specialist` | GAS / Blueprint / Replication / UMG 专家 |

**关键设计**：你只用其中一组，删掉另外两组。这是"可插拔架构"——核心编排不变，引擎专家按需替换。

**编排启示**：设计编排时，把"可变部分"（引擎、技术栈）和"不变部分"（流程、角色）分开。不变的部分做成骨架，可变的部分做成可替换模块。

---

## 一个完整的委派链示例

来自 [agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md) 的"Pattern 1: New Feature (Full Pipeline)"。这是一个新功能从概念到完成的完整链路：

```
1. creative-director   批准功能概念符合愿景
2. game-designer       写设计文档
3. producer            排期，识别依赖
4. lead-programmer     设计代码架构，画接口草图
5. [专家程序员]         实现功能
6. technical-artist    做视觉特效（如需）
7. writer              写文本内容（如需）
8. sound-designer      列音频事件清单（如需）
9. qa-tester           写测试用例
10. qa-lead            审查测试覆盖
11. lead-programmer    代码审查
12. qa-tester          执行测试
13. producer           标记任务完成
```

**注意几个编排细节**：
- 步骤 6-8 可以**并行**（互不依赖）。
- 步骤 9-10 是**串行**（测试员写完，主管才审查）。
- 步骤 11 和 12 看似可以并行，但实际是**串行**（代码审查可能要求改，改完才测）。
- 每一步都有"把关人"：创意总监管愿景、主管管标准、QA 管质量、制作人管进度。

---

## Subagent vs Agent Team：两种多智能体模式

来自 [coordination-rules.md](file:///workspace/.claude/docs/coordination-rules.md) 的"Subagents vs Agent Teams"。这是进阶概念，但很重要：

### Subagents（当前在用）

通过 `Task` 工具在**单个 Claude Code 会话内**派生子智能体。子智能体共享会话权限，串行或并行运行，结果返回给父会话。

**适用**：绝大多数场景。所有 `team-*` 技能和编排技能都用这个。

### Agent Teams（实验性，需 opt-in）

多个**独立的 Claude Code 会话**同时运行，通过共享任务列表协调。每个会话有独立上下文窗口和 token 预算。需要环境变量 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`。

**适用**：
- 工作跨多个子系统且不碰同一批文件
- 每个工作流要 30 分钟以上，受益于真并行
- 一个高级智能体要协调 3+ 专家会话同时干不同 epic

**不适用**：
- 一个会话的输出是另一个的输入（用串行 subagent）
- 任务塞得进单会话上下文（用 subagent）
- 成本敏感（每个团队成员独立烧 token）

**编排启示**：默认用 subagent（简单、共享上下文、便宜）。只有真并行且任务够大才上 agent team。

---

## 并行任务协议

来自 [coordination-rules.md](file:///workspace/.claude/docs/coordination-rules.md) 末尾。当编排技能派生多个独立智能体时：

1. **先发后等**：所有独立的 Task 调用一起发出，再等结果。
2. **收齐再走**：所有结果收齐再进依赖阶段。
3. **阻塞立即上报**：任何智能体 BLOCKED 立刻告诉用户，不静默跳过。
4. **必出部分报告**：哪怕部分阻塞，也要把已完成的部分汇报出来。

**这是并行的纪律**。AI 最容易犯的错是"一个一个串行等"，浪费时间和 token。

---

## 小测验

**Q1**：`gameplay-programmer` 想改 `src/ui/` 下的文件，应该怎么做？
> **A**：不能直接改（域边界铁律）。要么让 `ui-programmer` 来改，要么由 `lead-programmer` 显式委派给 `gameplay-programmer` 临时跨域。

**Q2**：`game-designer` 和 `narrative-director` 对某个机制有分歧，找谁仲裁？
> **A**：`creative-director`。因为设计和叙事的共同上级是创意总监。看升级路径表。

**Q3**：为什么 `creative-director` 的 `disallowedTools` 里有 `Bash`？
> **A**：最小权限原则。创意总监的职责是守愿景和仲裁创意冲突，不该跑终端命令。跑命令是程序员和运维的活。禁用 Bash 防止总监"越权动手"。

---

## 动手

1. 打开 [agent-coordination-map.md](file:///workspace/.claude/docs/agent-coordination-map.md)，找到"Pattern 2: Bug Fix"和"Pattern 3: Balance Adjustment"，对比三条链路的异同。
2. 打开 [.claude/agents/](file:///workspace/.claude/agents/) 目录，挑三个不同层级的智能体（比如一个总监、一个主管、一个专家），对比它们的 `tools`、`model`、`maxTurns` 字段，想想为什么这么设。

下一篇 → [04 Skill 技能系统](file:///workspace/study-docs/04-Skill技能系统.md)
