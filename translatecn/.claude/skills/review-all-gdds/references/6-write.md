# /review-all-gdds — Phase 6: Write Report and Flag GDDs
# /review-all-gdds — 阶段 6：撰写报告并标记 GDD

> Part of `/review-all-gdds`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/review-all-gdds` 的组成部分。`SKILL.md` 指明何时读取本文件；它已解析的各项设置，
> 以及其后续标题下所列的规则，在此同样适用。

## Phase 6: Write Report and Flag GDDs
## 阶段 6：撰写报告并标记 GDD

Use `AskUserQuestion` for write permission:
- Prompt: "May I write this review to `design/gdd/gdd-cross-review-[date].md`?"
- Options: `[A] Yes — write the report` / `[B] No — skip`

使用 `AskUserQuestion` 获取写入许可：
- 提示：“我可以把本次审查写入 `design/gdd/gdd-cross-review-[date].md` 吗？”
- 选项：`[A] 是——写入报告` / `[B] 否——跳过`

> **`[date]` here means ISO 8601 — `YYYY-MM-DD`, e.g.
> `gdd-cross-review-2026-08-19.md`. This is not a style preference.**
> `.claude/scripts/review-scope.sh` picks the prior review with
> `sort | tail -1`, so lexical order IS chronological order only for ISO dates.
> Written as `aug-19-2026` or `19-08-2026`, the wrong file is chosen as the
> baseline, the changed-set is computed from it, and GDDs modified since the
> real last review silently escape the next one. That is the same
> quiet-escape failure the three fixes documented at the top of that script
> exist to prevent.

> **此处的 `[date]` 指 ISO 8601 格式——`YYYY-MM-DD`，例如
> `gdd-cross-review-2026-08-19.md`。这不是风格偏好。**
> `.claude/scripts/review-scope.sh` 用
> `sort | tail -1` 选取上一份审查，因此只有当日期为 ISO 格式时，字典序才等于时间序。
> 若写成 `aug-19-2026` 或 `19-08-2026`，就会选错基线文件，
> 变更集也据此计算，真正的上次审查之后修改过的 GDD 会悄悄逃过下一次审查。
> 这与该脚本顶部所记录的三处修复旨在防止的
> “悄悄逃逸”失效是同一种问题。

If any GDDs are flagged for revision, use a second `AskUserQuestion`:
- Prompt: "Should I update the systems index to mark these GDDs as needing revision? ([list of flagged GDDs])"
- Options: `[A] Yes — update systems index` / `[B] No — leave as-is`
- If yes: update each flagged GDD's Status field in systems-index.md to "Needs Revision".
  (Do NOT append parentheticals to the status value — other skills match "Needs Revision"
  as an exact string and parentheticals break that match.)

如果有 GDD 被标记为需要修订，使用第二次 `AskUserQuestion`：
- 提示：“我是否应更新系统索引，把这些 GDD 标记为需要修订？（[被标记 GDD 的列表]）”
- 选项：`[A] 是——更新系统索引` / `[B] 否——保持原样`
- 若是：把 systems-index.md 中每个被标记 GDD 的 Status 字段更新为 “Needs Revision”。
  （不要在状态值后附加括号说明——其他技能会把 “Needs Revision”
  当作精确字符串匹配，附加括号会破坏匹配。）

### Session State Update
### 会话状态更新

After writing the report (and updating systems index if approved), silently
append to `production/session-state/active.md`:

在写入报告（以及若获批准则更新系统索引）之后，静默追加到
`production/session-state/active.md`：

    ## Session Extract — /review-all-gdds [date]
    - Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]
    - GDDs reviewed: [N of M present]
    - Phases not run: [names, or "None"]
    - Flagged for revision: [comma-separated list, or "None"]
    - Blocking issues: [N — brief one-line descriptions, or "None"]
    - Recommended next: [the Phase 7 handoff action, condensed to one line]
    - Report: design/gdd/gdd-cross-review-[date].md   ← only if user approved the write
    - Report: (not written — user declined at [date])  ← only if user declined the write

Use the appropriate line based on the user's response to the write-permission
widget in Phase 6.

根据用户对阶段 6 中写入许可控件的回应，使用相应的那一行。

If `active.md` does not exist, create it with this block as the initial content.
Confirm in conversation: "Session state updated."

如果 `active.md` 不存在，就以该块作为初始内容创建它。
在对话中确认：“会话状态已更新。”

---
