# /adopt — Phase 5: Present Summary and Ask to Write

# /adopt — 阶段 5：呈现摘要并询问是否写入

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> `/adopt` 的一部分。`SKILL.md` 说明了何时读取本文件；它解析出的设置以及它后续标题下的规则在这里同样适用。

## Phase 5: Present Summary and Ask to Write

## 阶段 5：呈现摘要并询问是否写入

Present a compact summary before writing:

在写入之前呈现一份简明的摘要：

```
## Adoption Audit Summary
Phase detected: [phase]
Engine: [configured / NOT CONFIGURED]
GDDs audited: [N] ([X] fully compliant, [Y] with gaps)
ADRs audited: [N] ([X] fully compliant, [Y] with gaps)
Stories audited: [N]

Gap counts:
  BLOCKING: [N] — template skills will malfunction without these fixes
  HIGH:     [N] — unsafe to run /create-stories or /story-readiness
  MEDIUM:   [N] — quality degradation
  LOW:      [N] — optional improvements

Estimated remediation: [X blocking items × ~Y min each = roughly Z hours]
```

Before asking to write, show a **Gap Preview**:
- List every BLOCKING gap as a one-line bullet describing the actual problem
  (e.g. `systems-index.md: 3 rows have parenthetical status values`,
  `adr-0002.md: missing ## Status section`). No counts — show the actual items.
- Show HIGH / MEDIUM / LOW as counts only (e.g. `HIGH: 4, MEDIUM: 2, LOW: 1`).

在询问是否写入之前，展示一份**缺口预览**：
- 将每个阻断缺口列为一行条目，描述实际问题（例如 `systems-index.md: 3 rows have parenthetical status values`、`adr-0002.md: missing ## Status section`）。不显示计数 —— 显示实际条目。
- 仅以计数形式显示高/中/低（例如 `HIGH: 4, MEDIUM: 2, LOW: 1`）。

This gives the user enough context to judge scope before committing to writing the file.

这让用户在决定写入文件之前有足够的上下文来判断范围。

If a prior adoption plan was detected in Phase 1, add a note:
> "A previous plan exists at `docs/adoption-plan-[prior-date].md`. The new plan will
> reflect current project state — it does not diff against the prior run."

如果在阶段 1 检测到了先前的采纳计划，添加一条说明：
> "已有一份先前计划位于 `docs/adoption-plan-[prior-date].md`。新计划将反映当前项目状态 —— 它不会与先前的运行做差异对比。"

Use `AskUserQuestion`:
- "Ready to write the migration plan?"
  - "Yes — write `docs/adoption-plan-[date].md`"
  - "Show me the full plan preview first (don't write yet)"
  - "Cancel — I'll handle migration manually"

使用 `AskUserQuestion`：
- "准备好写入迁移计划了吗？"
  - "是 —— 写入 `docs/adoption-plan-[date].md`"
  - "先向我展示完整计划预览（暂不写入）"
  - "取消 —— 我将手动处理迁移"

If the user picks "Show me the full plan preview", output the complete plan as a
fenced markdown block. Then ask again with the same three options.

如果用户选择"先向我展示完整计划预览"，将完整计划作为围栏 markdown 代码块输出。然后用同样的三个选项再次询问。

---
