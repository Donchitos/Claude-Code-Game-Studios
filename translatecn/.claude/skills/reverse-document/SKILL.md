---
name: reverse-document
description: "Generate missing design or architecture docs from existing implementation — works backwards from code and prototypes."
argument-hint: "<type> <path> (e.g., 'design src/gameplay/combat' or 'architecture Assets/Scripts/Core')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(bash "*/.claude/skills/reverse-document/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
# Read-only diagnostic skill — no specialist agent delegation needed
---

---
name: reverse-document
description: "从已有实现中生成缺失的设计或架构文档 —— 从代码和原型反推。"
argument-hint: "<type> <path> (e.g., 'design src/gameplay/combat' or 'architecture Assets/Scripts/Core')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(bash "*/.claude/skills/reverse-document/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
# 只读诊断技能 —— 无需委派给专家智能体
---

# Reverse Documentation

This skill analyzes existing implementation (code, prototypes, systems) and generates
appropriate design or architecture documentation. Use this when:
- You built a feature without writing a design doc first
- You inherited a codebase without documentation
- You prototyped a mechanic and need to formalize it
- You need to document "why" behind existing code

# 反向补文档

本技能分析已有实现（代码、原型、系统）并生成
合适的设计或架构文档。在以下情形使用：
- 你先构建了功能，却没有先写设计文档
- 你接手了一个没有文档的代码库
- 你原型验证了一个机制，需要把它正式化
- 你需要记录既有代码背后的"为什么"

---

## Workflow

## Phase 1: Parse Arguments

**Format**: `/reverse-document <type> <path>`

**Type options**:
- `design` → Generate a game design document (GDD section)
- `architecture` → Generate an Architecture Decision Record (ADR)
- `concept` → Generate a concept document from prototype

**Path**: Directory or file to analyze, under the code root — `src/` Godot,
`Assets/` Unity, `Source/<Module>/` Unreal (`.claude/docs/code-root-resolution.md`)
- `src/gameplay/combat/` → All combat-related code (Godot)
- `Assets/Scripts/Core/EventSystem.cs` → Specific file (Unity)
- `Source/MyGame/Private/AI/` → A module folder (Unreal)
- `prototypes/stealth-mech/` → Prototype directory

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,system_overrides,automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

**Resolve the workflow tier** for the target system: map `<path>` to a system
name, then use the `system_overrides` row for that system if the block above
lists one, else the project `workflow` value. It sets how much document is
generated — see Phase 5. Semantics of each tier are in
`.claude/docs/workflow-modes.md`.

> **Resolve the tier — do not assume it.** `workflow-modes.md` defines what each
> tier *means*, but it cannot say what *this project* is set to; take that from
> the block above. The consequence is large here — at `full` this skill
> writes an 8-section GDD and at `minimal` a one-page brief, so a wrong tier
> produces the wrong artifact entirely.

**Examples**:
```bash
/reverse-document design src/gameplay/magic-system
/reverse-document architecture Source/MyGame/Private/EntityComponent
/reverse-document concept prototypes/vehicle-combat
```

## 工作流

## 阶段 1：解析参数

**格式**：`/reverse-document <type> <path>`

**类型选项**：
- `design` → 生成游戏设计文档（GDD 章节）
- `architecture` → 生成架构决策记录（ADR）
- `concept` → 从原型生成概念文档

**路径**：要分析的目录或文件，位于代码根目录之下 —— `src/` Godot、
`Assets/` Unity、`Source/<Module>/` Unreal（`.claude/docs/code-root-resolution.md`）
- `src/gameplay/combat/` → 所有战斗相关代码（Godot）
- `Assets/Scripts/Core/EventSystem.cs` → 特定文件（Unity）
- `Source/MyGame/Private/AI/` → 一个模块文件夹（Unreal）
- `prototypes/stealth-mech/` → 原型目录

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,system_overrides,automation`

**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用和
每次写文件都遵循 `.claude/docs/automation-modes.md`
（collaborative 总是询问 · guided 仅重大事项询问 · autonomous 记录并继续；
`automation_always_ask` 类别始终提示）。

已在上面解析 —— 直接使用。无配置块 → 采用
`.claude/docs/config-resolution.md` 中的默认值。

**为目标系统解析工作流档位**：把 `<path>` 映射到一个系统
名称，然后如果上面的配置块列出了该系统，使用该系统对应的 `system_overrides` 行，
否则使用项目的 `workflow` 值。它决定生成多少文档 —— 见阶段 5。每个档位的语义见
`.claude/docs/workflow-modes.md`。

> **解析档位 —— 不要臆断。** `workflow-modes.md` 定义了每个
> 档位*意味着*什么，但它无法说明*这个项目*被设置成什么；从上面的
> 配置块中获取。这里后果很大 —— 在 `full` 下本技能
> 写出 8 节的 GDD，而在 `minimal` 下写一页简报，所以错误的档位
> 会产出完全错误的资产。

**示例**：
```bash
/reverse-document design src/gameplay/magic-system
/reverse-document architecture Source/MyGame/Private/EntityComponent
/reverse-document concept prototypes/vehicle-combat
```

## Phase 2: Analyze Implementation

**Read and understand the code/prototype**:

**For design docs (GDD):**
- Identify mechanics, rules, formulas
- Extract gameplay values (damage, cooldowns, ranges)
- Find state machines, ability systems, progression
- Detect edge cases handled in code
- Map dependencies (what systems interact?)

**For architecture docs (ADR):**
- Identify patterns (ECS, singleton, observer, etc.)
- Understand technical decisions (threading, serialization, etc.)
- Map dependencies and coupling
- Assess performance characteristics
- Find constraints and trade-offs

**For concept docs (prototype analysis):**
- Identify core mechanic
- Extract emergent gameplay patterns
- Note what worked vs what didn't
- Find technical feasibility insights
- Document player fantasy / feel

## 阶段 2：分析实现

**阅读并理解代码/原型**：

**对于设计文档（GDD）：**
- 识别机制、规则、公式
- 提取玩法数值（伤害、冷却、范围）
- 查找状态机、能力系统、成长系统
- 检测代码中处理的边界情况
- 映射依赖关系（哪些系统相互作用？）

**对于架构文档（ADR）：**
- 识别模式（ECS、单例、观察者等）
- 理解技术决策（线程、序列化等）
- 映射依赖与耦合
- 评估性能特征
- 找出约束与权衡

**对于概念文档（原型分析）：**
- 识别核心机制
- 提取涌现式玩法模式
- 记录哪些奏效、哪些不奏效
- 找出技术可行性的洞见
- 记录玩家幻想 / 手感

## Phase 3: Ask Clarifying Questions

**DO NOT** just describe the code. **ASK** about intent:

**Design questions**:
- "I see a [resource] system that depletes during [activity]. Was this for:
  - Pacing (prevent spam)?
  - Resource management (strategic depth)?
  - Or something else?"
- "The [mechanic] seems central. Is this a core pillar, or supporting feature?"
- "[Value] scales exponentially with [factor]. Intentional design, or needs rebalancing?"

**Architecture questions**:
- "You're using a service locator pattern. Was this chosen for:
  - Testability (mock dependencies)?
  - Decoupling (reduce hard references)?
  - Or inherited from existing code?"
- "I see manual memory management instead of smart pointers. Performance requirement, or legacy?"

**Concept questions**:
- "The prototype emphasizes stealth over combat. Is that the intended pillar?"
- "Players seem to exploit the grappling hook for speed. Feature or bug?"

## 阶段 3：提出澄清性问题

**不要**只是描述代码。而应**询问**意图：

**设计问题**：
- "我看到一个 [resource] 系统会在 [activity] 期间耗尽。这是为了：
  - 节奏（防止滥用）？
  - 资源管理（策略深度）？
  - 还是别的什么？"
- "[mechanic] 看起来是核心。这是核心支柱，还是辅助功能？"
- "[Value] 随 [factor] 指数增长。是有意设计，还是需要重新平衡？"

**架构问题**：
- "你在使用服务定位器模式。这是为了：
  - 可测试性（模拟依赖）？
  - 解耦（减少硬引用）？
  - 还是承袭自既有代码？"
- "我看到手动内存管理而不是智能指针。性能要求，还是遗留问题？"

**概念问题**：
- "原型的重点是潜行而非战斗。那是预期的支柱吗？"
- "玩家似乎利用抓钩来加速。这是特性还是缺陷？"

## Phase 3b: Sufficiency Check — is there enough here to document?

**Run this before Phase 4, and stop here if it fails.** This skill infers a
design from an implementation, so when the implementation is thin there is
nothing to infer *from* — and the template below will happily accept invented
content, because every section of it is mandatory.

Count what Phase 2 actually found:

| Signal | What counts |
|---|---|
| Mechanics | A named behaviour with observable rules — not a stub, not an empty class |
| Formulas | An expression computing a gameplay value from inputs |
| Values | A tuning constant with a use site |

**If all three counts are zero, or the target path holds fewer than ~20 lines of
non-boilerplate code, stop and say so:**

> "[path] does not contain enough implementation to reverse-document.
> Found: [N] mechanics, [N] formulas, [N] tuning values.
> Reverse-documentation infers design from behaviour; with no behaviour to read,
> anything I produce would be invention wearing the format of a design document.
> If the design exists only in your head, `/design-system [name]` is the skill
> that captures it — it asks rather than infers."

**Do not proceed on a partial count by filling the rest.** A path with two
mechanics and no formulas gets a document with two mechanics and an explicit
`FORMULAS DISCOVERED: none found in the source` — see Phase 4.

## 阶段 3b：充分性检查 —— 这里有足够的内容可以记录吗？

**在阶段 4 之前运行此检查，如果失败就停在这里。** 本技能是从实现推断
设计，所以当实现内容单薄时，就没有可*据以推断*的东西 —— 而下面的模板会很乐意接受编造
内容，因为它的每一节都是强制性的。

统计阶段 2 实际找到的内容：

| 信号 | 计入什么 |
|---|---|
| 机制 | 一个有名称、规则可观察的行为 —— 不是占位符，不是空类 |
| 公式 | 一个根据输入计算玩法数值的表达式 |
| 数值 | 一个带使用位置的调参常量 |

**如果三项计数全为零，或目标路径的样板之外代码少于约 20 行，停下并说明：**

> "[path] 没有足够的实现可用来反向补文档。
> 找到：[N] 个机制，[N] 个公式，[N] 个调参数值。
> 反向补文档是从行为推断设计；没有可读的行为，
> 我产出的任何内容都只是披着设计文档格式的发明。
> 如果设计只存在于你脑中，`/design-system [name]` 才是
> 捕获它的技能 —— 它提问而非推断。"

**不要以部分计数为前提把其余部分填满来继续。** 一个有两个
机制、没有公式的路径，得到的文档就有两个机制，并显式写明
`FORMULAS DISCOVERED: none found in the source` —— 见阶段 4。

## Phase 4: Present Findings

Before drafting, show what you discovered:

```
I've analyzed [path]/. Here's what I found:

MECHANICS IMPLEMENTED:
- [mechanic-a] with [property] (e.g. timing windows, cooldowns)
- [mechanic-b] (e.g. interaction between two states)
- [resource] system (depletes on [action], regens on [condition])
- [state] system (builds up, triggers [effect])

FORMULAS DISCOVERED:
- [Output] = [formula using discovered variables]
- [Secondary output] = [formula]

UNCLEAR INTENT AREAS:
1. [Resource] system — pacing or resource management?
2. [Mechanic] — core pillar or supporting feature?
3. [Value] scaling — intentional design or needs tuning?

Before I draft the design doc, could you clarify these points?
```

> **Every section above may be empty, and an empty one must say so.** Write
> `none found in the source` under the heading — never omit the heading (which
> reads as "not looked for") and never populate it from what a system like this
> usually has. The bracketed rows are *shapes*, not quotas: a source with one
> mechanic yields one row, not four.
>
> This matters more here than in a report, because the output of this skill is not
> a report — it is a **design document**, and `/design-review`, `/create-epics` and
> `/create-stories` will read it as a statement of authored intent. A fabricated
> formula in a GDD does not stay a documentation error; it becomes a requirement,
> and then a story, and then code written to satisfy it.

Wait for user to clarify intent before drafting.

**If the user does not answer the `UNCLEAR INTENT AREAS` questions, do not draft
the resolved version anyway.** Those questions exist because **code cannot tell
you why** — it records what was built, never what was intended, and the gap
between them is the entire content of a design document. Unanswered items are
carried into the draft verbatim as open questions, in the document, marked
`INTENT UNKNOWN — inferred from implementation, not confirmed`. An inferred
intent presented as a settled one is the failure mode of this whole skill.

## 阶段 4：呈现发现

在起草之前，展示你发现的内容：

```
I've analyzed [path]/. Here's what I found:

MECHANICS IMPLEMENTED:
- [mechanic-a] with [property] (e.g. timing windows, cooldowns)
- [mechanic-b] (e.g. interaction between two states)
- [resource] system (depletes on [action], regens on [condition])
- [state] system (builds up, triggers [effect])

FORMULAS DISCOVERED:
- [Output] = [formula using discovered variables]
- [Secondary output] = [formula]

UNCLEAR INTENT AREAS:
1. [Resource] system — pacing or resource management?
2. [Mechanic] — core pillar or supporting feature?
3. [Value] scaling — intentional design or needs tuning?

Before I draft the design doc, could you clarify these points?
```

```
我已分析 [path]/。以下是我的发现：

已实现的机制：
- [mechanic-a]，带有 [property]（例如时机窗口、冷却）
- [mechanic-b]（例如两个状态之间的交互）
- [resource] 系统（在 [action] 时耗尽，在 [condition] 时恢复）
- [state] 系统（累积，触发 [effect]）

发现的公式：
- [Output] = [使用所发现变量的公式]
- [Secondary output] = [公式]

意图不明的区域：
1. [Resource] 系统 —— 节奏还是资源管理？
2. [Mechanic] —— 核心支柱还是辅助功能？
3. [Value] 缩放 —— 有意设计还是需要调参？

在我起草设计文档之前，你能澄清这几点吗？
```

> **上面每一节都可能是空的，而空的节必须说明它是空的。** 在标题下写
> `none found in the source` —— 绝不省略标题（省略会被读作"没有查找过"），也绝不根据这类系统
> 通常具备的内容来填充它。方括号中的行是*形状*，不是配额：只有
> 一个机制的源产出一行，而不是四行。
>
> 这在这里比在报告中更重要，因为本技能的输出不是
> 报告 —— 它是一份**设计文档**，而 `/design-review`、`/create-epics` 和
> `/create-stories` 会把它当作作者意图的陈述来阅读。GDD 中编造的
> 公式不会止于文档错误；它会变成一项需求，
> 然后变成一个故事，然后变成为满足它而写的代码。

在起草前等待用户澄清意图。

**如果用户没有回答 `UNCLEAR INTENT AREAS` 中的问题，也不要强行起草
已解决的版本。** 这些问题存在是因为**代码无法告诉你为什么** —— 它记录被构建了什么，
从不记录被意图了什么，而两者之间的差距正是设计文档的全部内容。未回答的条目
会原样带入草稿作为开放问题，在文档中标记为
`INTENT UNKNOWN — inferred from implementation, not confirmed`。把推断出的
意图呈现为已确定的意图，正是整个技能的失败模式。

## Phase 5: Draft Document Using Template

Based on type, use appropriate template:

| Type | Template | Output Path |
|------|----------|-------------|
| `design` | `templates/design-doc-from-implementation.md` | `design/gdd/[system-name].md` |
| `architecture` | `templates/architecture-doc-from-code.md` | `docs/architecture/[decision-name].md` |
| `concept` | `templates/concept-doc-from-prototype.md` | `prototypes/[name]/CONCEPT.md` or `design/concepts/[name].md` |

**The `design` output scales with the workflow tier** (resolved in Phase 1):
- **`full`** — generate a full 8-section GDD.
- **`standard`** — generate a 5-section GDD (Overview, Detailed Design, Edge Cases,
  Dependencies, Acceptance Criteria; + Formulas when the recovered system defines
  numeric rules). Skip Player Fantasy and Tuning Knobs.
- **`minimal`** — generate a **game brief** in the one-page format
  (`.claude/docs/templates/game-brief.md`), not a GDD. For the whole game
  (the path is the code root itself) write `design/game-brief.md`; for a single
  reverse-engineered system write
  `design/[system-name]-brief.md`.

(`architecture` and `concept` outputs are tier-independent.)

**Draft structure**:
- Capture **what exists** (mechanics, patterns, implementation)
- Document **why it exists** (intent clarified with user)
- Identify **what's missing** (edge cases not handled, gaps in design)
- Flag **follow-up work** (balance tuning, missing features)

## 阶段 5：使用模板起草文档

根据类型，使用相应的模板：

| 类型 | 模板 | 输出路径 |
|------|----------|-------------|
| `design` | `templates/design-doc-from-implementation.md` | `design/gdd/[system-name].md` |
| `architecture` | `templates/architecture-doc-from-code.md` | `docs/architecture/[decision-name].md` |
| `concept` | `templates/concept-doc-from-prototype.md` | `prototypes/[name]/CONCEPT.md` 或 `design/concepts/[name].md` |

**`design` 输出随工作流档位变化**（在阶段 1 解析）：
- **`full`** —— 生成完整的 8 节 GDD。
- **`standard`** —— 生成 5 节 GDD（概述（Overview）、详细设计（Detailed Design）、边界情况（Edge Cases）、
  依赖（Dependencies）、验收标准（Acceptance Criteria）；当恢复的系统定义了数值规则时
  + 公式（Formulas））。跳过玩家幻想（Player Fantasy）和调参旋钮（Tuning Knobs）。
- **`minimal`** —— 生成**游戏简报**，采用一页格式
  （`.claude/docs/templates/game-brief.md`），而不是 GDD。对于整个游戏
  （路径就是代码根目录本身）写 `design/game-brief.md`；对于单个
  反向工程的系统写
  `design/[system-name]-brief.md`。

（`architecture` 和 `concept` 的输出与档位无关。）

**草稿结构**：
- 记录**存在什么**（机制、模式、实现）
- 记录**它为何存在**（与用户澄清的意图）
- 识别**缺少什么**（未处理的边界情况、设计中的缺口）
- 标记**后续工作**（平衡调参、缺失功能）

### Stamp the provenance — required, at the top of every document this skill writes

A document produced here lands at the same path, in the same format, as one a
designer wrote by hand, and **every downstream consumer treats the two
identically**. `/design-review` checks it for completeness, `/create-epics`
derives epics from it, `/create-stories` turns its lines into acceptance
criteria. Nothing anywhere asks where it came from.

The difference is not cosmetic: an authored GDD states **intent**, and this one
states **observed behaviour plus inference**. When they disagree, the code is
what needs changing in the first case and the document in the second — and a
reader cannot tell which they are holding unless the document says.

Emit this immediately under the title:

```markdown
> **Reverse-documented from implementation** — generated by `/reverse-document`
> from `[path]` on `[date]`, at commit `[short-sha]`.
> This records what the code **does**; intent marked `INTENT UNKNOWN` below was
> inferred, not confirmed by the author. Where this document and the code
> disagree, do not assume the document is the requirement.
```

Keep the banner on revision. If a human later confirms the intent and adopts the
document as authored design, removing it is their explicit act — not a
side effect of the next edit.

### 标注来源 —— 必需，位于本技能写出的每份文档顶部

此处产出的文档会落在与设计师手写文档相同的路径、相同的格式，并且
**每个下游消费者对两者一视同仁**。`/design-review` 会检查它的完整度，`/create-epics`
会从它推导史诗，`/create-stories` 会把它的行转成验收
标准。任何地方都不会问它从哪里来。

区别不是表面功夫：手写的 GDD 陈述**意图**，而这份文档
陈述**观察到的行为加上推断**。当二者不一致时，前一种情况下要改的是代码，
后一种情况下要改的是文档 —— 而除非文档自己说明，否则
读者无法分辨手中拿的是哪一种。

在标题正下方输出这段：

```markdown
> **Reverse-documented from implementation** — generated by `/reverse-document`
> from `[path]` on `[date]`, at commit `[short-sha]`.
> This records what the code **does**; intent marked `INTENT UNKNOWN` below was
> inferred, not confirmed by the author. Where this document and the code
> disagree, do not assume the document is the requirement.
```

```markdown
> **Reverse-documented from implementation** —— 由 `/reverse-document`
> 于 `[date]` 从 `[path]` 生成，提交为 `[short-sha]`。
> 本文件记录代码**做什么**；下方标记为 `INTENT UNKNOWN` 的意图是
> 推断的，未经作者确认。凡本文件与代码不一致之处，
> 不要假定本文件就是需求。
```

在修订时保留该横幅。如果之后有人确认了意图并把
文档采纳为作者设计，移除它是他们的显式行为 —— 而不是下一次编辑的
副作用。

## Phase 6: Show Draft and Request Approval

**Collaborative protocol**:
```
I've drafted the [system-name] design doc based on your code and clarifications.

[Show key sections: Overview, Mechanics, Formulas, Design Intent]

ADDITIONS I MADE:
- Documented [mechanic] as "[intent]" per your clarification
- Added edge cases not in code (e.g., what if [resource] hits 0 mid-[action]?)
- Flagged balance concern: [scaling type] scaling at [boundary condition]

SECTIONS MARKED AS INCOMPLETE:
- "[System] interaction with [other-system]" (not fully implemented yet)
- "[Variant or feature]" (only [subset] implemented so far)

May I write this to [output path]?
```

Use the tier-correct output path in the prompt: `design/gdd/[system-name].md` for
a `full`/`standard` GDD, or `design/[system-name]-brief.md` for a `minimal` brief.

**At `collaborative`** — wait for approval; the user may request changes before
writing. **At `guided`** — this is a *new* file, so `automation-modes.md:81`
still has it asked ("May I write?" is asked for new files only); if the target
already exists, present the diff and proceed without waiting for an explicit
"yes". **At `autonomous`** — write and log the decision.

## 阶段 6：展示草稿并请求批准

**协作协议**：
```
I've drafted the [system-name] design doc based on your code and clarifications.

[Show key sections: Overview, Mechanics, Formulas, Design Intent]

ADDITIONS I MADE:
- Documented [mechanic] as "[intent]" per your clarification
- Added edge cases not in code (e.g., what if [resource] hits 0 mid-[action]?)
- Flagged balance concern: [scaling type] scaling at [boundary condition]

SECTIONS MARKED AS INCOMPLETE:
- "[System] interaction with [other-system]" (not fully implemented yet)
- "[Variant or feature]" (only [subset] implemented so far)

May I write this to [output path]?
```

```
我已根据你的代码和澄清，起草了 [system-name] 设计文档。

[展示关键章节：概述、机制、公式、设计意图]

我做的补充：
- 按你的澄清，把 [mechanic] 记录为"[intent]"
- 添加了代码中没有的边界情况（例如，如果 [resource] 在 [action] 中途降到 0 会怎样？）
- 标记了平衡顾虑：[scaling type] 在 [boundary condition] 处的缩放

标记为不完整的章节：
- "[System] 与 [other-system] 的交互"（尚未完全实现）
- "[Variant or feature]"（目前只实现了 [subset]）

我可以把它写入 [output path] 吗？
```

提示中使用档位对应的输出路径：`full`/`standard` GDD 用 `design/gdd/[system-name].md`，
或 `minimal` 简报用 `design/[system-name]-brief.md`。

**在 `collaborative` 下** —— 等待批准；用户在写入前可以要求更改。
**在 `guided` 下** —— 这是一个*新*文件，所以 `automation-modes.md:81`
仍要求询问它（"May I write?" 只对新文件询问）；如果目标
已存在，展示差异并继续，无需等待显式的"yes"。**在 `autonomous` 下** —— 写入并记录决策。

## Phase 7: Write Document with Metadata

When approved, write the file with special markers:

```markdown
---
status: reverse-documented
source: [path/]
date: [today]
verified-by: [User name]
---

# [System Name] Design

> **Note**: This document was reverse-engineered from the existing implementation.
> It captures current behavior and clarified design intent. Some sections may be
> incomplete where implementation is partial or intent was unclear.

[Rest of document...]
```

## 阶段 7：带元数据写入文档

获得批准后，带特殊标记写入文件：

```markdown
---
status: reverse-documented
source: [path/]
date: [today]
verified-by: [User name]
---

# [System Name] Design

> **Note**: This document was reverse-engineered from the existing implementation.
> It captures current behavior and clarified design intent. Some sections may be
> incomplete where implementation is partial or intent was unclear.

[Rest of document...]
```

```markdown
---
status: reverse-documented
source: [path/]
date: [today]
verified-by: [User name]
---

# [System Name] 设计

> **注**：本文件是从既有实现反向工程的。
> 它记录了当前行为以及澄清后的设计意图。在实现不完整或意图
> 不明之处，部分章节可能不完整。

[文档的其余部分……]
```

## Phase 8: Flag Follow-Up Work

After writing, suggest next steps:

```
✅ Written to design/gdd/combat-system.md

FOLLOW-UP RECOMMENDED:
1. Run /balance-check on combat formulas (exponential scaling concern)
2. Create ADR for stamina system architecture decision
3. Implement missing edge cases:
   - Stamina depletion mid-combo behavior
   - Stagger state during dodge
4. Extend design doc when weapon variety is implemented

Would you like me to tackle any of these now?
```

---

## 阶段 8：标记后续工作

写入后，建议下一步：

```
✅ Written to design/gdd/combat-system.md

FOLLOW-UP RECOMMENDED:
1. Run /balance-check on combat formulas (exponential scaling concern)
2. Create ADR for stamina system architecture decision
3. Implement missing edge cases:
   - Stamina depletion mid-combo behavior
   - Stagger state during dodge
4. Extend design doc when weapon variety is implemented

Would you like me to tackle any of these now?
```

```
✅ 已写入 design/gdd/combat-system.md

建议的后续：
1. 对战斗公式运行 /balance-check（指数缩放顾虑）
2. 为耐力系统架构决策创建 ADR
3. 实现缺失的边界情况：
   - 连招中途耐力耗尽的行为
   - 闪避期间的硬直状态
4. 在实现武器多样性后扩展设计文档

你想让我现在处理其中任何一项吗？
```

---

## Template Selection Logic

| If analyzing... | Use template... | Because... |
|----------------|-----------------|------------|
| `<code root>/gameplay/*` | design-doc-from-implementation.md | Gameplay mechanics → GDD |
| `<code root>/core/*`, `<code root>/ai/*` | architecture-doc-from-code.md | Core systems → ADR |
| `prototypes/*` | concept-doc-from-prototype.md | Experiments → concept doc |
| `<code root>/networking/*` | architecture-doc-from-code.md | Technical systems → ADR |
| `<code root>/ui/*` | design-doc-from-implementation.md | UI/UX → design spec |

---

## 模板选择逻辑

| 若分析的是…… | 使用模板…… | 因为…… |
|----------------|-----------------|------------|
| `<code root>/gameplay/*` | design-doc-from-implementation.md | 玩法机制 → GDD |
| `<code root>/core/*`、`<code root>/ai/*` | architecture-doc-from-code.md | 核心系统 → ADR |
| `prototypes/*` | concept-doc-from-prototype.md | 实验 → 概念文档 |
| `<code root>/networking/*` | architecture-doc-from-code.md | 技术系统 → ADR |
| `<code root>/ui/*` | design-doc-from-implementation.md | UI/UX → 设计规格 |

---

## Example Session: Reverse-Document a System

```
User: /reverse-document design <code root>/gameplay/[system]

Agent: I'll analyze your [system] implementation to create a design doc.
       [Reads code, discovers mechanics, formulas]

Agent: I've analyzed <code root>/gameplay/[system]/. Here's what I found:
       [Shows mechanics, formulas, unclear areas]

       Before drafting, could you clarify:
       1. [Resource] system intent?
       2. Is [mechanic] a core pillar?
       3. [Value] scaling — intentional or needs tuning?

User: 1. [Resource] is for pacing, prevent [unwanted behavior]
      2. [Mechanic] is core — I want [design intent]
      3. Yeah, exponential is too much, should be linear

Agent: Perfect, that clarifies the vision. Let me draft the design doc.
       [Shows draft with clarified intent]

       May I write this to design/gdd/[system-name].md?

User: Yes, write it.

Agent: ✅ Written to design/gdd/[system-name].md
       ✅ Marked as [REVERSE-DOCUMENTED]
       ✅ Flagged [value] scaling for rebalancing

       Next steps:
       - Update [formula] to [corrected scaling]
       - Run /balance-check to validate [curve]
       - Document [mechanic] as core pillar in game-pillars.md
```

---

## 示例会话：反向补文档一个系统

```
User: /reverse-document design <code root>/gameplay/[system]

Agent: I'll analyze your [system] implementation to create a design doc.
       [Reads code, discovers mechanics, formulas]

Agent: I've analyzed <code root>/gameplay/[system]/. Here's what I found:
       [Shows mechanics, formulas, unclear areas]

       Before drafting, could you clarify:
       1. [Resource] system intent?
       2. Is [mechanic] a core pillar?
       3. [Value] scaling — intentional or needs tuning?

User: 1. [Resource] is for pacing, prevent [unwanted behavior]
      2. [Mechanic] is core — I want [design intent]
      3. Yeah, exponential is too much, should be linear

Agent: Perfect, that clarifies the vision. Let me draft the design doc.
       [Shows draft with clarified intent]

       May I write this to design/gdd/[system-name].md?

User: Yes, write it.

Agent: ✅ Written to design/gdd/[system-name].md
       ✅ Marked as [REVERSE-DOCUMENTED]
       ✅ Flagged [value] scaling for rebalancing

       Next steps:
       - Update [formula] to [corrected scaling]
       - Run /balance-check to validate [curve]
       - Document [mechanic] as core pillar in game-pillars.md
```

```
User: /reverse-document design <code root>/gameplay/[system]

Agent: 我将分析你的 [system] 实现，以创建设计文档。
       [读取代码，发现机制、公式]

Agent: 我已分析 <code root>/gameplay/[system]/。以下是我的发现：
       [展示机制、公式、不明区域]

       在起草之前，你能澄清：
       1. [Resource] 系统的意图？
       2. [mechanic] 是核心支柱吗？
       3. [Value] 缩放 —— 有意还是需要调参？

User: 1. [Resource] 是为了节奏，防止 [unwanted behavior]
      2. [Mechanic] 是核心 —— 我想要 [design intent]
      3. 对，指数太大了，应该是线性

Agent: 完美，这澄清了愿景。让我起草设计文档。
       [展示带澄清意图的草稿]

       我可以把它写入 design/gdd/[system-name].md 吗？

User: 可以，写入吧。

Agent: ✅ 已写入 design/gdd/[system-name].md
       ✅ 已标记为 [REVERSE-DOCUMENTED]
       ✅ 已标记 [value] 缩放以供重新平衡

       下一步：
       - 把 [formula] 更新为 [corrected scaling]
       - 运行 /balance-check 验证 [curve]
       - 在 game-pillars.md 中把 [mechanic] 记录为核心支柱
```

---

## Collaborative Protocol

This skill follows the collaborative design principle:

1. **Analyze First**: Read code, understand implementation
2. **Question Intent**: Ask about "why", not just "what"
3. **Present Findings**: Show discoveries, highlight unclear areas
4. **User Clarifies**: Separate intent from accidents
5. **Draft Document**: Create doc based on reality + intent
6. **Show Draft**: Display key sections, explain additions
7. **Get Approval**: "May I write to [filepath]?" On approval: Verdict: **COMPLETE** — document generated. On decline: Verdict: **BLOCKED** — user declined write.
8. **Flag Follow-Up**: Suggest related work, don't auto-execute

**Never assume intent. Always ask before documenting "why".**

## 协作协议

本技能遵循协作式设计原则：

1. **先分析**：阅读代码，理解实现
2. **询问意图**：问"为什么"，而不仅仅是"是什么"
3. **呈现发现**：展示发现，突出不明区域
4. **用户澄清**：把意图与偶然区分开
5. **起草文档**：基于现实 + 意图创建文档
6. **展示草稿**：显示关键章节，解释补充内容
7. **获得批准**："我可以写入 [filepath] 吗？" 批准后：结论：**COMPLETE** —— 文档已生成。拒绝后：结论：**BLOCKED** —— 用户拒绝写入。
8. **标记后续**：建议相关工作，不要自动执行

**绝不要臆断意图。记录"为什么"之前始终先询问。**
