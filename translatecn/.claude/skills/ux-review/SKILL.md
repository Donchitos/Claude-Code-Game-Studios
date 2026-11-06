---
name: ux-review
description: "Validate a UX spec, HUD design or pattern library — accessibility, GDD alignment, readiness. APPROVED / NOT ASSESSED / NEEDS REVISION / MAJOR REVISION NEEDED."
argument-hint: "[file-path or 'all' or 'hud' or 'patterns']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(bash "*/.claude/skills/ux-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: ux-review
description: "验证 UX 规格、HUD 设计或模式库 — 无障碍、GDD 对齐、就绪度。APPROVED / NOT ASSESSED / NEEDS REVISION / MAJOR REVISION NEEDED。"
argument-hint: "[file-path or 'all' or 'hud' or 'patterns']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(bash "*/.claude/skills/ux-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

以上已解析 — 直接使用。无配置块 → 使用
`.claude/docs/config-resolution.md` 中的默认值。

# UX Review

# UX 评审

## Overview

## 概述

Validates UX design documents before they enter the implementation pipeline.
Acts as the quality gate between UX Design and Visual Design/Implementation in
the `/team-ui` pipeline.

在 UX 设计文档进入实现流水线之前对其进行验证。
在 `/team-ui` 流水线中充当 UX 设计与视觉设计/实现之间的质量门禁。

**Run this skill:**
- After completing a UX spec with `/ux-design`
- Before handing off to `ui-programmer` or `art-director`
- Before the Pre-Production to Production gate check (which requires key screens
  to have reviewed UX specs)
- After major revisions to a UX spec

**运行本技能的情形：**
- 用 `/ux-design` 完成一份 UX 规格之后
- 交接给 `ui-programmer` 或 `art-director` 之前
- 预生产到生产的门禁检查之前（该检查要求关键界面已有
  经评审的 UX 规格）
- 对 UX 规格进行重大修订之后

**Verdict levels:**
- **APPROVED** — spec is complete, consistent, and implementation-ready
- **NOT ASSESSED** — one or more review dimensions had no criterion to check
  against, or the spec could not be read; name which
- **NEEDS REVISION** — specific gaps found; fix before handoff but not a full redesign
- **MAJOR REVISION NEEDED** — fundamental issues with scope, player need, or
  completeness; needs significant rework

**结论级别：**
- **APPROVED** — 规格完整、一致且可实现
- **NOT ASSESSED** — 一个或多个评审维度没有可供比对的准则，或规格无法读取；指明是哪项
- **NEEDS REVISION** — 发现具体缺口；交接前修复，但不需要全面重设计
- **MAJOR REVISION NEEDED** — 范围、玩家需求或完整性方面存在根本问题；
  需要显著重做

**`NOT ASSESSED` ranks above APPROVED and below the two revision verdicts.** A
review that could not evaluate a dimension has not shown the spec is
implementation-ready; but a gap somebody found is more actionable than one nobody
could look for, so it must not displace them. Emit it when the spec file cannot
be read, when a checklist dimension has no source of truth to compare against, or
when the accessibility tier is uncommitted (below).

**`NOT ASSESSED` 排在 APPROVED 之上、两种修订结论之下。** 一次
无法评估某个维度的评审，并未证明规格
可实现；但有人找到的缺口比没人能查找的缺口更可行动，
因此它不能取代后者。当规格文件无法读取、清单维度没有可比对的真实基准、
或无无障碍层级未确定（见下）时，发出它。

---

## Phase 1: Parse Arguments

## 阶段 1：解析参数

- **Specific file path** (e.g., `/ux-review design/ux/inventory.md`): validate
  that one document
- **`all`**: find all files in `design/ux/` and validate each
- **`hud`**: validate `design/ux/hud.md` specifically
- **`patterns`**: validate `design/ux/interaction-patterns.md` specifically
- **No argument**: ask the user which spec to validate

- **特定文件路径**（例如 `/ux-review design/ux/inventory.md`）：验证
  该单个文档
- **`all`**：查找 `design/ux/` 中的所有文件并逐一验证
- **`hud`**：专门验证 `design/ux/hud.md`
- **`patterns`**：专门验证 `design/ux/interaction-patterns.md`
- **无参数**：询问用户要验证哪份规格

For `all`, output a summary table first (file | verdict | primary issue) then
full detail for each.

对于 `all`，先输出摘要表（file | verdict | primary issue），然后
为每个文件输出完整细节。

**Which checklist a file gets** (a file path, or each file under `all`): its
`> **Template**:` header line, which `/ux-design` writes — `UX Spec` → Phase 3A,
`HUD Design` → 3B, `Interaction Pattern Library` → 3C. A file without that line
is classified by name — `hud.md` → 3B, `interaction-patterns.md` → 3C, anything
else → 3A — and the report says which checklist it assumed, and why.

**文件使用哪份清单**（一个文件路径，或 `all` 下的每个文件）：看它由
`/ux-design` 写入的 `> **Template**:` 头行 — `UX Spec` → 阶段 3A，
`HUD Design` → 3B，`Interaction Pattern Library` → 3C。没有该行的文件
按名称分类 — `hud.md` → 3B，`interaction-patterns.md` → 3C，其他任何
→ 3A — 并且报告会说明它假定了哪份清单，以及原因。

---

## Phase 2: Load Cross-Reference Context

## 阶段 2：加载交叉引用上下文

Before validating any spec, load:

在验证任何规格之前，加载：

1. **Input & Platform config**: Read the `platform` block from `project.yaml`
   (`platform.targets`, `platform.primary_input`, `platform.gamepad_support`,
   `platform.touch_support`); if `project.yaml` has no `platform` block, fall
   back to the `## Input & Platform` section of
   `.claude/docs/technical-preferences.md`. For the set of supported input
   methods: when reading from `project.yaml`, derive it — keyboard/mouse if
   `PC` or `Web` is in `targets`; gamepad if `gamepad_support` is Full or
   Partial; touch if `touch_support` is Full or Partial; plus `primary_input`.
   When falling back to `technical-preferences.md`, use its explicit Input
   Methods field instead. This is the authoritative source for the Input Method
   Coverage checks in Phase 3A — not the spec's own header. If neither source is
   configured, fall back to the spec header.
2. The accessibility tier committed to in `design/accessibility-requirements.md`
   (if it exists)
3. The interaction pattern library at `design/ux/interaction-patterns.md` (if
   it exists)
4. The GDDs referenced in the spec's header (read their UI Requirements sections:
   find the headings with the Grep tool (pattern `^#`, content mode) and Read
   those ranges with offset and limit)
5. The player journey map at `design/player-journey.md` (if it exists) for
   context-arrival validation

1. **输入与平台配置**：从 `project.yaml` 读取 `platform` 块
   （`platform.targets`、`platform.primary_input`、`platform.gamepad_support`、
   `platform.touch_support`）；如果 `project.yaml` 没有 `platform` 块，回退到
   `.claude/docs/technical-preferences.md` 的 `## Input & Platform` 章节。
   对于受支持的输入方式集合：从 `project.yaml` 读取时，推导它 — 若
   `targets` 含 `PC` 或 `Web` 则为键盘/鼠标；若 `gamepad_support` 为 Full 或
   Partial 则为手柄；若 `touch_support` 为 Full 或 Partial 则为触摸；再加上 `primary_input`。
   回退到 `technical-preferences.md` 时，改用其显式的 Input
   Methods 字段。这是阶段 3A 中输入方式
   覆盖检查的权威来源 — 而非规格自身的头部。若两个来源都
   未配置，回退到规格头部。
2. `design/accessibility-requirements.md` 中承诺的无障碍层级
   （若存在）
3. `design/ux/interaction-patterns.md` 处的交互模式库（若
   存在）
4. 规格头部引用的 GDD（读取它们的 UI Requirements 章节：
   用 Grep 工具（pattern `^#`，content 模式）找到标题，再用 offset 和 limit
   读取那些区间）
5. `design/player-journey.md` 处的玩家旅程图（若存在），用于
   上下文到达验证

---

## Phase 3A: UX Spec Validation Checklist

## 阶段 3A：UX 规格验证清单

Run all checks against a `ux-spec.md`-based document.

对基于 `ux-spec.md` 的文档运行所有检查。

### Completeness (required sections)

### 完整性（必需章节）

- [ ] Document header present with Status, Author, Platform Target
- [ ] Purpose & Player Need — has a player-perspective need statement (not
  developer-perspective)
- [ ] Player Context on Arrival — describes player's state and prior activity
- [ ] Navigation Position — shows where screen sits in hierarchy
- [ ] Entry & Exit Points — all entry sources and exit destinations documented
- [ ] Layout Specification — zones defined, component inventory table present
- [ ] States & Variants — at minimum: loading, empty/populated, and error states
  documented
- [ ] Interaction Map — covers all target input methods (check platform target
  in header)
- [ ] Data Requirements — every displayed data element has a source system and owner
- [ ] Events Fired — every player action has a corresponding event or null
  explanation
- [ ] Transitions & Animations — at least enter/exit transitions specified
- [ ] Input Method Completeness Checklist — a block for each input method in
  the Platform Target line; any unticked item is listed under Open Questions
- [ ] Accessibility Requirements — screen-level requirements present
- [ ] Localization Considerations — max character counts for text elements
- [ ] Acceptance Criteria — at least 5 specific testable criteria

- [ ] 文档头部包含 Status、Author、Platform Target
- [ ] Purpose & Player Need — 具有玩家视角的需求陈述（不是
  开发者视角）
- [ ] Player Context on Arrival — 描述玩家状态和先前活动
- [ ] Navigation Position — 显示界面在层级中的位置
- [ ] Entry & Exit Points — 记录所有进入来源和退出目标
- [ ] Layout Specification — 定义区域、存在组件清单表
- [ ] States & Variants — 至少记录：加载、空/有数据、错误状态
- [ ] Interaction Map — 覆盖所有目标输入方式（检查头部的平台目标）
- [ ] Data Requirements — 每个显示的数据元素都有来源系统和所有者
- [ ] Events Fired — 每个玩家动作都有对应事件或 null
  说明
- [ ] Transitions & Animations — 至少指定进入/退出转场
- [ ] Input Method Completeness Checklist — 对 Platform Target 行中的每种输入方式
  各有一个块；任何未勾选项列在 Open Questions 下
- [ ] Accessibility Requirements — 呈现屏幕级需求
- [ ] Localization Considerations — 文本元素的最大字符数
- [ ] Acceptance Criteria — 至少 5 条具体的可测试标准

### Quality Checks

### 质量检查

**Player Need Clarity**
- [ ] Purpose is written from player perspective, not system/developer perspective
- [ ] Player goal on arrival is unambiguous ("The player arrives wanting to ___")
- [ ] The player context on arrival is specific (not just "they opened the
  inventory")

**玩家需求清晰度**
- [ ] 目的是从玩家视角而非系统/开发者视角书写的
- [ ] 玩家到达时的目标明确无歧义（"The player arrives wanting to ___"）
- [ ] 玩家到达时的上下文具体（不仅仅是"they opened the
  inventory"）

**Completeness of States**
- [ ] Error state is documented (not just happy path)
- [ ] Empty state is documented (no data scenario)
- [ ] Loading state is documented if the screen fetches async data
- [ ] Any state with a timer or auto-dismiss is documented with duration

**状态完整性**
- [ ] 错误状态已记录（不仅限于顺利路径）
- [ ] 空状态已记录（无数据场景）
- [ ] 若界面获取异步数据，则加载状态已记录
- [ ] 任何带计时器或自动消失的状态都记录了时长

**Input Method Coverage**
- [ ] If platform includes PC: keyboard-only navigation is fully specified
- [ ] If platform includes console/gamepad: d-pad navigation and face button
  mapping documented
- [ ] No interaction requires mouse-like precision on gamepad
- [ ] Focus order is defined (Tab order for keyboard, d-pad order for gamepad)

**输入方式覆盖**
- [ ] 若平台包含 PC：仅键盘导航已完整指定
- [ ] 若平台包含主机/手柄：方向键导航和面键
  映射已记录
- [ ] 没有交互在手柄上要求鼠标式精度
- [ ] 焦点顺序已定义（键盘为 Tab 顺序，手柄为方向键顺序）

**Data Architecture**
- [ ] No data element has "UI" listed as the owner (UI must not own game state)
- [ ] Update frequency is specified for all real-time data (not just "realtime" —
  what triggers update?)
- [ ] Null handling is specified for all data elements (what shows when data is
  unavailable?)

**数据架构**
- [ ] 没有数据元素将 "UI" 列为所有者（UI 不得拥有游戏状态）
- [ ] 所有实时数据都指定了更新频率（不只是 "realtime" —
  什么触发更新？）
- [ ] 所有数据元素都指定了 null 处理（数据不可用时
  显示什么？）

**Accessibility**
- [ ] Accessibility tier from `accessibility-requirements.md` is matched or exceeded
- [ ] If Basic tier: no color-only information indicators
- [ ] If Standard tier+: focus order documented, text contrast ratios specified
- [ ] If Comprehensive tier+: screen reader announcements for key state changes
- [ ] Colorblind check: any color-coded elements have non-color alternatives

**无障碍**
- [ ] 达到或超过 `accessibility-requirements.md` 中的无障碍层级
- [ ] 若为 Basic 层级：没有仅靠颜色的信息指示
- [ ] 若为 Standard 层级及以上：焦点顺序已记录、文本对比度已指定
- [ ] 若为 Comprehensive 层级及以上：关键状态变化有屏幕阅读器播报
- [ ] 色盲检查：任何颜色编码元素都有非颜色替代方案

**GDD Alignment**
- [ ] Every GDD UI Requirement referenced in the header is addressed in this spec
- [ ] No UI element displays or modifies game state without a corresponding GDD
  requirement
- [ ] No GDD UI Requirement is missing from this spec (cross-check the referenced
  GDD sections)

**GDD 对齐**
- [ ] 头部引用的每条 GDD UI Requirement 都在本规格中得到处理
- [ ] 没有 UI 元素在没有对应 GDD
  要求的情况下显示或修改游戏状态
- [ ] 本规格没有遗漏任何 GDD UI Requirement（交叉检查所引用的
  GDD 章节）

**Pattern Library Consistency**
- [ ] All interactive components reference the pattern library (or note they are
  new patterns)
- [ ] No pattern behavior is re-specified from scratch if it already exists in
  the pattern library
- [ ] Any new patterns invented in this spec are flagged for addition to the
  pattern library

**模式库一致性**
- [ ] 所有交互组件都引用模式库（或注明它们是
  新模式）
- [ ] 如果模式库中已存在某模式行为，则不从零重新指定
- [ ] 本规格中发明的任何新模式都被标记为待加入
  模式库

**Localization**
- [ ] Character limit warnings present for all text-heavy elements
- [ ] Any layout-critical text has been flagged for 40% expansion accommodation

**本地化**
- [ ] 所有文本较多的元素都有字符数上限警告
- [ ] 任何对布局至关重要的文本都被标记为需容纳 40% 扩展

**Acceptance Criteria Quality**
- [ ] Criteria are specific enough for a QA tester who hasn't seen the design docs
- [ ] Performance criterion present (screen opens within Xms)
- [ ] Resolution criterion present
- [ ] No criterion requires reading another document to evaluate

**验收标准质量**
- [ ] 标准足够具体，供未看过设计文档的 QA 测试人员使用
- [ ] 存在性能标准（界面在 Xms 内打开）
- [ ] 存在分辨率标准
- [ ] 没有标准需要阅读另一份文档才能评估

---

## Phase 3B: HUD Validation Checklist

## 阶段 3B：HUD 验证清单

Run all checks against a `hud-design.md`-based document.

对基于 `hud-design.md` 的文档运行所有检查。

### Completeness

### 完整性

- [ ] HUD Philosophy defined
- [ ] Information Architecture table covers ALL systems with UI Requirements in GDDs
- [ ] Layout Zones defined with safe zone margins for all target platforms
- [ ] Every HUD element has a full specification (zone, visibility trigger, data
  source, priority)
- [ ] HUD States by Gameplay Context covers at minimum: exploration, combat,
  dialogue/cutscene, paused
- [ ] Information Hierarchy gives every HUD element a priority tier (MUST KEEP /
  SHOULD KEEP / CAN HIDE / ALWAYS HIDE)
- [ ] Visual Budget defined (max simultaneous elements, max screen %)
- [ ] Platform Adaptation covers all target platforms
- [ ] Tuning Knobs present for player-adjustable elements
- [ ] Acceptance Criteria — at least 5 specific testable criteria

- [ ] HUD 理念已定义
- [ ] 信息架构表覆盖 GDD 中所有带 UI Requirements 的系统
- [ ] 布局区域已定义，并为所有目标平台设置安全区边距
- [ ] 每个 HUD 元素都有完整规格（区域、可见性触发、数据
  来源、优先级）
- [ ] 按玩法上下文的 HUD 状态至少覆盖：探索、战斗、
  对话/过场、暂停
- [ ] 信息层级为每个 HUD 元素给出优先级层级（MUST KEEP /
  SHOULD KEEP / CAN HIDE / ALWAYS HIDE）
- [ ] 视觉预算已定义（最大同时元素数、最大屏幕占比 %）
- [ ] 平台适配覆盖所有目标平台
- [ ] 为玩家可调元素提供调优旋钮
- [ ] Acceptance Criteria — 至少 5 条具体的可测试标准

### Quality Checks

### 质量检查

- [ ] No HUD element covers the center play area without a visibility rule to
  hide it
- [ ] Every information item that exists in any GDD is either in the HUD or
  explicitly categorized as "hidden/demand"
- [ ] All color-coded HUD elements have colorblind variants
- [ ] HUD elements in the Feedback & Notification section have queue/priority
  behavior defined
- [ ] Visual Budget compliance: total simultaneous elements is within budget

- [ ] 没有 HUD 元素覆盖中央游玩区域却没有隐藏它的
  可见性规则
- [ ] 任何 GDD 中存在的每个信息项要么在 HUD 中，要么
  被明确归类为 "hidden/demand"
- [ ] 所有颜色编码的 HUD 元素都有色盲变体
- [ ] Feedback & Notification 章节中的 HUD 元素定义了队列/优先级
  行为
- [ ] 视觉预算合规：同时元素总数在预算之内

### GDD Alignment

### GDD 对齐

- [ ] All systems in `design/gdd/systems-index.md` with UI category have
  representation in HUD (or justified absence)

- [ ] `design/gdd/systems-index.md` 中所有 UI 类别的系统都在
  HUD 中有体现（或有正当理由的缺席）

---

## Phase 3C: Pattern Library Validation Checklist

## 阶段 3C：模式库验证清单

- [ ] Pattern catalog index is current (matches actual patterns in document)
- [ ] All standard control patterns are specified: button variants, toggle,
  slider, dropdown, list, grid, modal, dialog, toast, tooltip, progress bar,
  input field, tab bar, scroll
- [ ] All game-specific patterns needed by current UX specs are present
- [ ] Each pattern has: When to Use, When NOT to Use, full state specification,
  accessibility spec, implementation notes
- [ ] Animation Standards table present
- [ ] Sound Standards table present
- [ ] No conflicting behaviors between patterns (e.g., "Back" behavior consistent
  across all navigation patterns)

- [ ] 模式目录索引是最新的（与文档中的实际模式一致）
- [ ] 所有标准控件模式都已指定：按钮变体、开关、
  滑块、下拉、列表、网格、模态、对话框、提示条、工具提示、进度条、
  输入框、标签栏、滚动
- [ ] 当前 UX 规格所需的所有游戏专属模式都存在
- [ ] 每个模式都具有：何时使用、何时不使用、完整状态规格、
  无障碍规格、实现说明
- [ ] 存在动画标准表
- [ ] 存在音效标准表
- [ ] 模式之间没有冲突行为（例如 "Back" 行为在所有导航模式中
  保持一致）

---

## Phase 4: Output the Verdict

## 阶段 4：输出结论

```markdown
## UX Review: [Document Name]
**Date**: [date]
**Reviewer**: ux-review skill
**Document**: [file path]
**Checklist**: [3A / 3B / 3C — from its Template line, or assumed from the file name]
**Platform Target**: [from header]
**Accessibility Tier**: [from header or accessibility-requirements.md]

### Completeness: [X/Y sections present]
- [x] Purpose & Player Need
- [ ] States & Variants — MISSING: error state not documented

### Quality Issues: [N found]
1. **[Issue title]** [BLOCKING / ADVISORY]
   - What's wrong: [specific description]
   - Where: [section name]
   - Fix: [specific action to take]

### GDD Alignment: [ALIGNED / GAPS FOUND]
- GDD [name] UI Requirements — [X/Y requirements covered]
- Missing: [list any uncovered GDD requirements]

### Accessibility: [COMPLIANT / GAPS / NON-COMPLIANT / NOT ASSESSED]
- Target tier: [tier]
- [list specific accessibility findings]

> **If `design/accessibility-requirements.md` is absent there is no committed
> tier, so this dimension has no criterion.** Report
> `Accessibility: NOT ASSESSED — no committed tier (design/accessibility-requirements.md absent)`
> and do NOT report it as COMPLIANT — a gate compared against an absent standard
> passes the way an assertion that can never fail passes. The same rule lives in
> `/team-ui` Phase 4 and is mirrored here so the two cannot drift. If the spec's own
> header states a tier, carry it forward as an **assumption** and say plainly that
> it was assumed rather than committed. Recommend `/ux-design accessibility` to
> establish the tier.

### Pattern Library: [CONSISTENT / INCONSISTENCIES FOUND / N/A]
- [findings]

> **For a HUD design there is no Pattern Library checklist to run it against (Phase 3B has none), so Pattern Library is N/A, excluded from the dimension count.**
> Report `Pattern Library: N/A — no pattern library checklist for this document
> type`.
>
> For a UX spec, this dimension does have a checklist — it is checked against
> `design/ux/interaction-patterns.md`. If that file is absent: N/A only where
> the workflow tier does not require the library (`minimal`) — report
> `Pattern Library: N/A — interaction pattern library not required at this
> tier`. At any tier that requires or recommends it (`standard`, `full`), report
> `Pattern Library: NOT ASSESSED — design/ux/interaction-patterns.md not found`
> instead: the library is missing, not out of scope, and NOT ASSESSED counts it
> against the verdict as the unresolved item it is.

### Verdict: APPROVED / NOT ASSESSED / NEEDS REVISION / MAJOR REVISION NEEDED
**Blocking issues**: [N] — must be resolved before implementation
**Advisory issues**: [N] — recommended but not blocking
**Dimensions not assessed**: [N] — [name each, and what would make it checkable]

[For APPROVED]: This spec is ready for handoff to `/team-ui` Phase 2
(Visual Design).

[For NOT ASSESSED]: [N] of the four review dimensions could not be evaluated:
[name them]. The spec may well be sound — this review cannot say either way for
those dimensions. [For each: the one input that would make it checkable.]
Handoff to `/team-ui` is not recommended on this result.

[For NEEDS REVISION]: Address the [N] blocking issues above, then re-run
`/ux-review`.

[For MAJOR REVISION NEEDED]: The spec has fundamental gaps in [areas].
Recommend returning to `/ux-design` to rework [sections].
```

---

## Phase 5: Collaborative Protocol

## 阶段 5：协作协议

This skill is READ-ONLY — it never edits or writes files. It reports findings only.

本技能为只读 — 它绝不编辑或写入文件。它只报告发现。

After delivering the verdict:
- For **APPROVED**: suggest running `/team-ui` to begin implementation coordination
- For **NOT ASSESSED**: name the missing input per dimension and offer to help
  produce it (`/ux-design accessibility` for an uncommitted tier, the GDD path
  for absent UI requirements). Do not re-run the review against the same missing
  inputs and report a different verdict — only new inputs change this one
- For **NEEDS REVISION**: offer to help fix specific gaps ("Would you like me to
  help draft the missing error state?") — but do not auto-fix; wait for user
  instruction
- For **MAJOR REVISION NEEDED**: suggest returning to `/ux-design` with the
  specific sections to rework

交付结论后：
- 对于 **APPROVED**：建议运行 `/team-ui` 以开始实现协调
- 对于 **NOT ASSESSED**：按维度指明缺失的输入，并提议帮助
  产出它（未确定的层级用 `/ux-design accessibility`，缺失的 UI 需求用
  GDD 路径）。不要用同样的缺失输入重跑评审并
  报告不同的结论 — 只有新的输入才会改变这一结论
- 对于 **NEEDS REVISION**：提议协助修复具体缺口（"Would you like me to
  help draft the missing error state?"）— 但不要自动修复；等待用户
  指示
- 对于 **MAJOR REVISION NEEDED**：建议返回 `/ux-design`，并给出
  需重做的具体章节

Never block the user from proceeding — the verdict is advisory. Document risks,
present findings, let the user decide whether to proceed despite concerns. A user
who chooses to proceed with a NEEDS REVISION spec takes on the documented risk.

绝不阻止用户继续 — 结论是建议性的。记录风险、
呈现发现，让用户决定是否在存在顾虑的情况下继续。选择
带着 NEEDS REVISION 规格继续的用户自行承担已记录的风险。
