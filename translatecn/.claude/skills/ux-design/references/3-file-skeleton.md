# /ux-design — Section 3: Create File Skeleton
# /ux-design — 第 3 节：创建文件骨架

> Part of `/ux-design`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/ux-design` 的组成部分。`SKILL.md` 指明何时读取本文件；它已解析的各项设置，
> 以及其后续标题下所列的规则，在此同样适用。

## 3. Create File Skeleton
## 3. 创建文件骨架

**In this file:**
**本文件内容：**

- Skeleton for UX Spec (screen or flow)
- Skeleton for HUD Design
- Skeleton for Interaction Pattern Library
- Skeleton for Accessibility Requirements

- UX 规格骨架（界面或流程）
- HUD 设计骨架
- 交互模式库骨架
- 无障碍需求骨架

Once the user confirms, **immediately** create the output file with empty section
headers. This ensures incremental writes have a target and work survives interruptions.

用户确认后，**立即**创建带有空分区标题的输出文件。这确保增量写入有目标，
且工作中断后仍能保留。

Ask: "May I create the skeleton file at `design/ux/[filename].md`?" — except in
`accessibility` mode, where the path is `design/accessibility-requirements.md`
(see the mode table in Section 1; it is deliberately not under `design/ux/`).

询问：“我可以创建骨架文件到 `design/ux/[filename].md` 吗？”——但在
`accessibility` 模式下例外，其路径为 `design/accessibility-requirements.md`
（见第 1 节中的模式表；它有意不放在 `design/ux/` 下）。

---

### Skeleton for UX Spec (screen or flow)
### UX 规格骨架（界面或流程）

```markdown
# UX Spec: [Screen/Flow Name]

> **Status**: In Design
> **Author**: [user + ux-designer]
> **Last Updated**: [today's date]
> **Journey Phase(s)**: [from context]
> **Platform Target**: [target platforms and input methods from 2h]
> **Template**: UX Spec

---

## Purpose & Player Need

[To be designed]

---

## Player Context on Arrival

[To be designed]

---

## Navigation Position

[To be designed]

---

## Entry & Exit Points

[To be designed]

---

## Layout Specification

### ASCII Wireframe

[To be designed]

### Layout Zones

[To be designed]

### Component Inventory

[To be designed]

### Information Hierarchy

[To be designed]

---

## States & Variants

[To be designed]

---

## Interaction Map

[To be designed]

---

## Data Requirements

[To be designed]

---

## Events Fired

[To be designed]

---

## Transitions & Animations

[To be designed]

---

## Input Method Completeness Checklist

[To be designed]

---

## Accessibility

[To be designed]

---

## Localization Considerations

[To be designed]

---

## Acceptance Criteria

[To be designed]

---

## Open Questions

[To be designed]
```

---

### Skeleton for HUD Design
### HUD 设计骨架

```markdown
# HUD Design

> **Status**: In Design
> **Author**: [user + ux-designer]
> **Last Updated**: [today's date]
> **Platform Targets**: [target platforms and input methods from 2h]
> **Template**: HUD Design

---

## HUD Philosophy

[To be designed]

---

## Information Architecture

### Full Information Inventory

[To be designed]

### Categorization

[To be designed]

---

## Layout Zones

[To be designed]

---

## HUD Element Specifications

[To be designed]

---

## HUD States by Gameplay Context

[To be designed]

---

## Information Hierarchy

[To be designed]

---

## Visual Budget

[To be designed]

---

## Feedback & Notification Systems

[To be designed]

---

## Platform Adaptation

[To be designed]

---

## Accessibility

[To be designed]

---

## Tuning Knobs

[To be designed]

---

## Acceptance Criteria

[To be designed]

---

## Open Questions

[To be designed]
```

---

### Skeleton for Interaction Pattern Library
### 交互模式库骨架

```markdown
# Interaction Pattern Library

> **Status**: In Design
> **Author**: [user + ux-designer]
> **Last Updated**: [today's date]
> **Template**: Interaction Pattern Library

---

## Overview

[To be designed]

---

## Pattern Catalog

[To be designed]

---

## Patterns

[Individual pattern entries added here as they are defined]

---

## Gaps & Patterns Needed

[To be designed]

---

## Open Questions

[To be designed]
```

---

### Skeleton for Accessibility Requirements
### 无障碍需求骨架

Section list mirrors `.claude/docs/templates/accessibility-requirements.md` — if
the template gains or loses a section, this skeleton follows it, not the reverse.

分区列表与 `.claude/docs/templates/accessibility-requirements.md` 保持一致——若
该模板增加或删除某个分区，本骨架随之变化，而不是反过来。

```markdown
# Accessibility Requirements

> **Status**: In Design
> **Author**: [user + ux-designer]
> **Last Updated**: [today's date]
> **Template**: Accessibility Requirements

## Accessibility Tier Definition

[To be designed]

---

## Visual Accessibility

[To be designed]

---

## Motor Accessibility

[To be designed]

---

## Cognitive Accessibility

[To be designed]

---

## Auditory Accessibility

[To be designed]

---

## Platform Accessibility API Integration

[To be designed]

---

## Per-Feature Accessibility Matrix

[To be designed]

---

## Accessibility Test Plan

[To be designed]

---

## Known Intentional Limitations

[To be designed]

---

## Audit History

[To be designed]

---

## External Resources

[To be designed]

---

## Open Questions

[To be designed]
```

> **The tier commitment is the gated part.** `gate-pre-production.md` requires
> the file to exist *with an accessibility tier committed*, and
> `gate-production.md` checks that tier is addressed in every key screen spec.
> A skeleton whose Tier Definition is still `[To be designed]` satisfies the
> glob but not the gate — author that section first.

> **等级承诺是受关卡约束的部分。** `gate-pre-production.md` 要求
> 该文件存在*且承诺了无障碍等级*，而
> `gate-production.md` 检查每个关键界面规格是否都处理了该等级。
> 若骨架的 Tier Definition 仍为 `[To be designed]`，只满足
> glob 要求，不满足关卡要求——请先编写该分区。

---

After writing the skeleton, update `production/session-state/active.md` with:
- Task: Designing [screen/flow name] UX spec
- Current section: Starting (skeleton created)
- File: design/ux/[filename].md (or `design/accessibility-requirements.md` in `accessibility` mode)

写完骨架后，更新 `production/session-state/active.md`：
- 任务：设计 [screen/flow name] 的 UX 规格
- 当前分区：开始（骨架已创建）
- 文件：design/ux/[filename].md（或在 `accessibility` 模式下为 `design/accessibility-requirements.md`）

---
