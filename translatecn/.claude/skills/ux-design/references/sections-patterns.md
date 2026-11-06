> Section-authoring guidance, loaded by `/ux-design` for the ACTIVE MODE ONLY.
> Never load the other two — one mode applies per invocation.

> 分区编写指导，由 `/ux-design` 仅在当前激活模式下加载。
> 绝不要加载另外两个——每次调用只适用一个模式文件。

# Section Guidance — Interaction Pattern Library Mode
# 分区指导 — 交互模式库模式

Pattern library authoring is additive and catalog-driven, not linear.

交互模式库的编写是增量式、由目录驱动的，而不是线性的。

#### Phase 1: Catalog Existing Patterns
#### 阶段 1：编目已有交互模式

Glob `design/ux/*.md` (excluding `interaction-patterns.md`) and read the Component
Inventory and Interaction Map sections of each spec. Extract every interaction
pattern used.

用 glob 匹配 `design/ux/*.md`（排除 `interaction-patterns.md`），并读取每个规格的
Component Inventory 与 Interaction Map 分区。提取所有被使用的交互
模式。

Present the extracted list: "Based on existing UX specs, these patterns are already
in use in the game:"
- [Pattern name]: used in [screen], [screen]
- [etc.]

呈现提取出的清单：“基于现有 UX 规格，以下模式已在游戏中使用：”
- [模式名称]：用于 [screen]、[screen]
- [等等]

Ask: "Are there patterns you know exist but aren't in existing specs yet? List any
additional ones now."

询问：“是否有你知道已存在、但尚未出现在现有规格中的模式？现在把
额外的那些列出来。”

---

#### Phase 2: Formalize Each Pattern
#### 阶段 2：形式化每个模式

For each pattern (existing or new), document:

对每个模式（已有的或新的），记录：

```markdown
### [Pattern Name]

**Category**: Navigation / Input / Feedback / Data Display / Modal / Overlay / [other]
**Used In**: [list of screens]

**Description**: [One paragraph explaining what this pattern is and when to use it]

**Specification**:
- [Component behavior]
- [Input mapping]
- [Visual/audio feedback]
- [Accessibility requirements for this pattern]

**When to Use**: [Conditions where this pattern is appropriate]
**When NOT to Use**: [Conditions where another pattern is more appropriate]

**Reference**: [Screenshot path or ASCII example, if available]
```

Work through patterns in groups. Use `AskUserQuestion`:
- "How do you want to work through these patterns?"
- Options: "Draft the first batch from existing specs (faster)", "Define them one by one (more control)", "Start with the most-used pattern first"

分组推进这些模式。使用 `AskUserQuestion`：
- “你希望如何推进这些模式？”
- 选项：“从现有规格起草第一批（更快）”、“逐个定义（更强掌控）”、“先处理使用最多的模式”

---

#### Phase 3: Identify Gaps
#### 阶段 3：识别缺口

After cataloging known patterns, ask:
- "Are there screens or interactions planned that would need patterns not yet
  in this library?"
- "Are there any patterns in existing specs that feel inconsistent with each
  other and should be consolidated?"

在完成已知模式的编目后，询问：
- “是否有计划中的界面或交互需要本库尚未包含的模式？”
- “现有规格中是否有彼此感觉不一致、应当合并的模式？”

Document gaps in the Gaps section for follow-up.

把缺口记录在 Gaps 分区，以便后续跟进。
