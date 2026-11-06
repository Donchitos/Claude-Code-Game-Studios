# /design-system — Phase 3: Create File Skeleton
# /design-system — 第三阶段：创建文件骨架

> Part of `/design-system`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/design-system` 的一部分。`SKILL.md` 说明了何时阅读本文件；它已解析的设置，以及其后各标题下的规则，在此同样适用。

## 3. Create File Skeleton
## 3. 创建文件骨架

**In this file:**

**本文件内容：**

- Which sections to scaffold at the resolved tier
- 在已解析层级下要搭建哪些章节
- The GDD skeleton
- GDD 骨架
- Writing the file, then the session state update
- 写入文件，然后更新会话状态

Once the user confirms, **immediately** create the GDD file with empty section
headers. This ensures incremental writes have a target.

用户确认后，**立即**创建带有空章节标题的 GDD 文件。这能确保增量写入有目标。

**Scaffold only the sections required at the resolved tier** (§1): at
`standard`, omit Player Fantasy and Tuning Knobs (and Formulas only when the
system defines no numeric rule — see §1; the category is a hint, not the test);
at `full`, scaffold all 8.
**Only the sections §1 named as omitted are skipped** — do not leave empty
`[To be designed]` placeholders for those. Every other section in the template
is scaffolded with its placeholder, including the ones §4 has not decided yet.
This sentence governs the three tier omissions above (Player Fantasy, Tuning
Knobs, and Formulas when no numeric rule exists) and nothing else: it is not a
licence to strip a section because it looks optional, and §4 cannot fill a
section §3 never created.

**只搭建已解析层级所要求的章节**（§1）：在 `standard` 下，省略 Player Fantasy 和 Tuning Knobs（只有当系统不定义数值规则时才省略 Formulas——见 §1；类目是提示，不是判定标准）；在 `full` 下，搭建全部 8 个。
**只有 §1 指明要省略的章节才被跳过**——不要为这些章节留下空的 `[To be designed]` 占位符。模板中的其他每个章节都用其占位符搭建，包括 §4 尚未决定的那些。这句话管辖的是上面这三处层级省略（Player Fantasy、Tuning Knobs，以及无数值规则时的 Formulas），仅此而已：它不是允许你因为某章节看起来可选就删掉它的许可，而且 §4 无法填补 §3 从未创建的章节。

Use the template structure from `.claude/docs/templates/game-design-document.md`:

使用 `.claude/docs/templates/game-design-document.md` 中的模板结构：

```markdown
# [System Name]

> **Status**: In Design
> **Author**: [user + agents]
> **Last Updated**: [today's date]
> **Last Verified**: [today's date]
> **Implements Pillar**: [from context]

## Summary

[To be designed]

> **Quick reference** — Layer: `[Foundation | Core | Feature | Presentation]` · Priority: `[MVP | Vertical Slice | Alpha | Full Vision]` · Key deps: `[System names or "None"]`

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

## Game Feel

[To be designed]

## UI Requirements

[To be designed]

## Cross-References

[To be designed]

## Acceptance Criteria

[To be designed]

## Open Questions

[To be designed]
```

Ask: "May I create the skeleton file at `design/gdd/[system-name].md`?"

询问："我可以在 `design/gdd/[system-name].md` 创建骨架文件吗？"

If the user declines: Stop with the following message:
> "Verdict: **BLOCKED** — skeleton creation declined. The design session cannot proceed without the skeleton file, as all subsequent phases use it as the base. Re-run `/design-system [system]` when ready to create the file."
Do not proceed to Section A.

如果用户拒绝：以以下消息停止：
> "判定：**BLOCKED** —— 骨架创建被拒绝。没有骨架文件，设计会话无法继续，因为所有后续阶段都以它为基础。准备好创建文件时，请重新运行 `/design-system [system]`。"
不要进入 Section A。

After writing, update `production/session-state/active.md`:
- Use Glob to check if the file exists.
- If it **does not exist**: use the **Write** tool to create it. Never attempt Edit on a file that may not exist.
- If it **already exists**: use the **Edit** tool to update the relevant fields.

写入之后，更新 `production/session-state/active.md`：
- 使用 Glob 检查该文件是否存在。
- 如果它**不存在**：使用 **Write** 工具创建它。绝不要对可能不存在的文件尝试 Edit。
- 如果它**已经存在**：使用 **Edit** 工具更新相关字段。

File content:
- Task: Designing [system-name] GDD
- Current section: Starting (skeleton created)
- File: design/gdd/[system-name].md

文件内容：
- Task: Designing [system-name] GDD（任务：设计 [system-name] 的 GDD）
- Current section: Starting (skeleton created)（当前章节：开始（骨架已创建））
- File: design/gdd/[system-name].md

---
