# 06 · Rules 路径规则

这一篇讲 11 条规则怎么"按目录"生效。规则是编排里最"细"的一层——它管的是具体代码怎么写。

---

## Rule 是什么

Rule = **按路径生效的编码规范**。每个 `.md` 文件 = 一条规则，靠 frontmatter 的 `paths` 字段决定只在哪些路径下生效。

位置：[.claude/rules/](file:///workspace/.claude/rules/)

**和 hook 的区别**：
- Hook 是"事件触发"的脚本，在提交/推送时跑。
- Rule 是"路径触发"的规范，在 AI 写那个路径下的代码时自动加载进上下文。

**类比**：hook 是"门口安检"（进出时检查），rule 是"区域法规"（在那个区域活动时适用）。

---

## Rule 的结构

看 [gameplay-code.md](file:///workspace/.claude/rules/gameplay-code.md)：

```markdown
---
paths:
  - "src/gameplay/**"
---

# Gameplay Code Rules

- ALL gameplay values MUST come from external config/data files, NEVER hardcoded
- Use delta time for ALL time-dependent calculations (frame-rate independence)
- NO direct references to UI code — use events/signals for cross-system communication
- Every gameplay system must implement a clear interface
- State machines must have explicit transition tables with documented states
- Write unit tests for all gameplay logic — separate logic from presentation
- Document which design doc each feature implements in code comments
- No static singletons for game state — use dependency injection

## Examples

**Correct** (data-driven):
\`\`\`gdscript
var damage: float = config.get_value("combat", "base_damage", 10.0)
\`\`\`

**Incorrect** (hardcoded):
\`\`\`gdscript
var damage: float = 25.0   # VIOLATION: hardcoded gameplay value
\`\`\`
```

**两部分**：

1. **YAML frontmatter**：`paths` 字段决定生效范围。`src/gameplay/**` = `src/gameplay/` 下所有文件。
2. **正文**：规则条文 + 正反例。

**关键设计**：规则带**正反例**。AI 看了就知道"这样对、那样错"。比纯条文强得多。

---

## 11 条规则的路径分工

来自 [README.md](file:///workspace/README.md) 的 Path-Scoped Rules 表：

| 路径 | 规则文件 | 强制什么 |
|------|----------|----------|
| `src/gameplay/**` | [gameplay-code.md](file:///workspace/.claude/rules/gameplay-code.md) | 数据驱动、delta time、不引用 UI、依赖注入 |
| `src/core/**` | [engine-code.md](file:///workspace/.claude/rules/engine-code.md) | 热路径零分配、线程安全、API 稳定性 |
| `src/ai/**` | [ai-code.md](file:///workspace/.claude/rules/ai-code.md) | 性能预算、可调试性、数据驱动参数 |
| `src/networking/**` | [network-code.md](file:///workspace/.claude/rules/network-code.md) | 服务器权威、版本化消息、安全 |
| `src/ui/**` | [ui-code.md](file:///workspace/.claude/rules/ui-code.md) | 不持有游戏状态、本地化就绪、无障碍 |
| `design/gdd/**` | [design-docs.md](file:///workspace/.claude/rules/design-docs.md) | 必需 8 章节、公式格式、边界情况 |
| `tests/**` | [test-standards.md](file:///workspace/.claude/rules/test-standards.md) | 测试命名、覆盖率、fixture 模式 |
| `prototypes/**` | [prototype-code.md](file:///workspace/.claude/rules/prototype-code.md) | 放松标准、要 README、记录假设 |
| `assets/**` | [data-files.md](file:///workspace/.claude/rules/data-files.md) | 数据文件规范 |
| `shaders/**` | [shader-code.md](file:///workspace/.claude/rules/shader-code.md) | 着色器规范 |
| 叙事相关 | [narrative.md](file:///workspace/.claude/rules/narrative.md) | 叙事文档规范 |

---

## 路径作用域的精妙之处

**核心思想**：不同路径有不同的"严格度"。生产代码严，原型代码松。

对比 [gameplay-code.md](file:///workspace/.claude/rules/gameplay-code.md)（生产玩法代码）和 [prototype-code.md](file:///workspace/.claude/rules/prototype-code.md)（原型代码）：

| 维度 | gameplay-code（严） | prototype-code（松） |
|------|---------------------|----------------------|
| 数值 | 必须数据驱动，禁止硬编码 | 允许硬编码（快速验证） |
| 测试 | 必须写单元测试 | 不强制测试 |
| 文档 | 必须注释对应设计文档 | 只要 README 和假设记录 |
| 架构 | 必须接口、依赖注入 | 随便写，能跑就行 |

**为什么这么设？** 因为原型是"用完即扔"的，要求它遵守生产标准反而拖慢验证。生产代码是要长期维护的，必须严。

**编排启示**：规则要"因地制宜"。一刀切的规则要么太严（拖慢原型）要么太松（生产代码失控）。按路径分级是正解。

---

## Rule 怎么被加载

Claude Code 在写文件时，会检查：

1. 这个文件路径匹配哪些规则的 `paths`？
2. 把匹配的规则正文加载进当前上下文。
3. AI 写代码时遵守这些规则。

**这是隐式的**。AI 不需要"调用"规则，规则自动生效。你只要在 `.claude/rules/` 放对文件，写对应路径时规则就来了。

---

## Rule 和 Hook 的配合

规则和钩子经常配合守护同一件事。以"硬编码数值"为例：

| 层 | 谁 | 干什么 |
|----|-----|--------|
| **Rule** | [gameplay-code.md](file:///workspace/.claude/rules/gameplay-code.md) | 写 `src/gameplay/` 时告诉 AI"必须数据驱动"，带正反例 |
| **Hook** | [validate-commit.sh](file:///workspace/.claude/hooks/validate-commit.sh) | 提交时 grep 检测 `damage = 25.0` 这种模式，警告 |

**双重守护**：规则是"写之前的教育"，钩子是"提交时的抽查"。AI 即使没遵守规则，钩子也会在提交时抓住。

**编排启示**：重要规范要"双保险"。软约束（rule）+ 硬约束（hook）组合，比单一约束可靠得多。

---

## Rule 和 Agent 的配合

不同智能体写不同路径，自然受不同规则约束：

| 智能体 | 主要写哪 | 受哪些规则约束 |
|--------|----------|----------------|
| `gameplay-programmer` | `src/gameplay/` | gameplay-code |
| `engine-programmer` | `src/core/` | engine-code |
| `ai-programmer` | `src/ai/` | ai-code |
| `network-programmer` | `src/networking/` | network-code |
| `ui-programmer` | `src/ui/` | ui-code |
| `game-designer` | `design/gdd/` | design-docs |
| `qa-tester` | `tests/` | test-standards |
| `prototyper` | `prototypes/` | prototype-code |

**这是域边界的另一层保障**。不仅 agent 的人设限定它能写哪，规则还限定它在那儿必须怎么写。

---

## 设计文档规则：8 章节强制

看 [design-docs.md](file:///workspace/.claude/rules/design-docs.md) 和 [validate-commit.sh](file:///workspace/.claude/hooks/validate-commit.sh) 的配合。GDD 必须有 8 个章节：

1. Overview
2. Player Fantasy
3. Detailed（规则）
4. Formulas（公式）
5. Edge Cases（边界情况）
6. Dependencies（依赖）
7. Tuning Knobs（调参旋钮）
8. Acceptance Criteria（验收标准）

**规则**告诉 AI 写 GDD 时要包含这 8 章。**钩子**在提交时检查这 8 章是否存在，缺了警告。

**为什么这么严？** 因为 GDD 是后续所有工作的源头。缺章节意味着设计不完整，会导致实现时猜测、测试时无据。强制 8 章保证设计文档"够用"。

---

## 小测验

**Q1**：为什么 `prototypes/` 下的规则比 `src/gameplay/` 松？
> **A**：因为原型是"用完即扔"的快速验证，要求生产级标准会拖慢验证节奏。生产代码要长期维护，必须严。规则按路径分级，因地制宜。

**Q2**：规则和钩子怎么配合守护"数据驱动"？
> **A**：规则（gameplay-code.md）在 AI 写 `src/gameplay/` 代码时教育它"必须数据驱动，带正反例"；钩子（validate-commit.sh）在提交时 grep 检测硬编码模式并警告。软约束 + 硬约束双保险。

**Q3**：`paths: ["src/gameplay/**"]` 里的 `**` 是什么意思？
> **A**：glob 通配符，匹配任意层级子目录。`src/gameplay/**` = `src/gameplay/` 下所有文件（含子目录）。如果写 `src/gameplay/*` 则只匹配直接子文件，不含子目录。

---

## 动手

1. 打开 [.claude/rules/](file:///workspace/.claude/rules/)，对比 [gameplay-code.md](file:///workspace/.claude/rules/gameplay-code.md) 和 [prototype-code.md](file:///workspace/.claude/rules/prototype-code.md) 的规则条文，感受"严"和"松"的差异。
2. 打开 [design-docs.md](file:///workspace/.claude/rules/design-docs.md)，看 8 章节的具体要求。
3. 想一想：如果你做一个 Web 项目，你会怎么按路径分规则？比如 `src/components/`、`src/api/`、`src/utils/` 各该有什么规则？

下一篇 → [07 协作协议与人在环](file:///workspace/study-docs/07-协作协议与人在环.md)
