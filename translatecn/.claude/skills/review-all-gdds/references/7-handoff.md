# /review-all-gdds — Phase 7: Handoff
# /review-all-gdds — 阶段 7：交接

> Part of `/review-all-gdds`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/review-all-gdds` 的组成部分。`SKILL.md` 指明何时读取本文件；它已解析的各项设置，
> 以及其后续标题下所列的规则，在此同样适用。

## Phase 7: Handoff
## 阶段 7：交接

After all file writes are complete, use `AskUserQuestion` for a closing widget.

所有文件写入完成后，使用 `AskUserQuestion` 作为收尾控件。

Before building options, check project state:
- Are there any Warning-level items that are simple edits (flagged with "30-second edit", "brief addition", or similar)? → offer inline quick-fix option
- Are any GDDs in the "Flagged for Revision" table? → offer /design-review option for each
- Read systems-index.md for the next system with Status: Not Started → offer /design-system option
- Is the verdict PASS or CONCERNS on a review that ran both passes? → offer /gate-check or /create-architecture. A focus run (`consistency` or `design-theory`) checked one pass, so it never offers either

在构建选项之前，先检查项目状态：
- 是否有警告级条目属于简单修改（被标注为 “30-second edit”、“brief addition” 或类似字样）？→ 提供就地快速修复选项
- “Flagged for Revision” 表中是否有 GDD？→ 为每个提供 /design-review 选项
- 从 systems-index.md 中读取下一个 Status: Not Started 的系统 → 提供 /design-system 选项
- 若判定为 PASS 或 CONCERNS，且该审查运行了两轮？→ 提供 /gate-check 或 /create-architecture。focus 运行（`consistency` 或 `design-theory`）只检查了一轮，因此绝不会提供这两者

Build the option list dynamically — only include options that apply:

动态构建选项列表——只包含适用的选项：

**Option pool:**
- `[_] Apply quick fix: [W-XX description] in [gdd-name].md — [effort estimate]` (one option per simple-edit warning; only for Warning-level, not Blocking)
- `[_] Run /design-review [flagged-gdd-path] — address flagged warnings` (one per flagged GDD, if any)
- `[_] Run /design-system [next-system] — next in design order` (always include, name the actual system)
- `[_] Run /create-architecture — begin architecture (verdict is PASS/CONCERNS)` (include only if the verdict is PASS or CONCERNS on a review that ran both passes — never on FAIL, NOT ASSESSED or a focus run)
- `[_] Run /gate-check — validate Systems Design phase gate` (include if verdict is PASS on a review that ran both passes)
- `[_] Stop here`

**选项池：**
- `[_] 应用快速修复：[W-XX 描述]（位于 [gdd-name].md）—— [工作量估算]`（每个简单修改类警告一个选项；仅限警告级，不含阻断级）
- `[_] 运行 /design-review [flagged-gdd-path]——处理被标记的警告`（每个被标记的 GDD 一个，若有）
- `[_] 运行 /design-system [next-system]——设计顺序中的下一个`（始终包含，并写出实际的系统名）
- `[_] 运行 /create-architecture——开始架构（判定为 PASS/CONCERNS）`（仅当判定为 PASS 或 CONCERNS 且审查运行了两轮时包含——FAIL、NOT ASSESSED 或 focus 运行时绝不包含）
- `[_] 运行 /gate-check——校验系统设计阶段关卡`（若判定为 PASS 且审查运行了两轮则包含）
- `[_] 到此为止`

Assign letters A, B, C… only to included options. Mark the most pipeline-advancing option as `(recommended)`.

只给被包含的选项分配字母 A、B、C……。把最能推进流水线的选项标记为 `(recommended)`。

In collaborative and guided modes, never end the skill with plain text — always
close with this widget. In autonomous mode, print the verdict and recommended
next step, then record via `log_decision` (no widget).

在协作模式与引导模式下，绝不要以纯文本结束技能——始终
用该控件收尾。在自主模式下，打印判定与推荐的
下一步，然后用 `log_decision` 记录（不使用控件）。

---
