# /adopt — Phase 7: Offer First Action

# /adopt — 阶段 7：提供首要操作

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> `/adopt` 的一部分。`SKILL.md` 说明了何时读取本文件；它解析出的设置以及它后续标题下的规则在这里同样适用。

## Phase 7: Offer First Action

## 阶段 7：提供首要操作

After writing the plan, don't stop there. Pick the single highest-priority gap
and offer to handle it immediately using `AskUserQuestion`. Choose the first
branch that applies:

写完计划之后，不要就此停止。挑出单个最高优先级的缺口，并使用 `AskUserQuestion` 提供立即处理它的选项。选择第一个适用的分支：

**If Phase 2g found a v1.0 project needing migration:** offer the converter run
described there — report what the dry run listed and ask "May I run the
converter? It writes `project.yaml` and `production/migration-report.md`."
Every other fix reads config through it, so it comes first.

**如果阶段 2g 发现了一个需要迁移的 v1.0 项目：** 提供那里描述的转换器运行 —— 报告试运行列出的内容，并询问"我可以运行转换器吗？它会写入 `project.yaml` 和 `production/migration-report.md`。"其他每一项修复都通过它读取配置，因此它排在最前。

**If there are parenthetical status values in systems-index.md:**
Use `AskUserQuestion`:
- "The most urgent fix is `systems-index.md` — [N] rows have parenthetical status
  values (e.g. `Needs Revision (see notes)`) that break /gate-check,
  /create-stories, and /architecture-review right now. I can fix these in-place."
  - "Fix it now — edit systems-index.md"
  - "I'll fix it myself"
  - "Done — leave me with the plan"

**如果 systems-index.md 中存在带括号的状态值：**
使用 `AskUserQuestion`：
- "最紧急的修复是 `systems-index.md` —— 有 [N] 行带有带括号的状态值（例如 `Needs Revision (see notes)`），它们现在就会破坏 /gate-check、/create-stories 和 /architecture-review。我可以原地修复这些。"
  - "现在就修复 —— 编辑 systems-index.md"
  - "我自己来修复"
  - "完成 —— 把计划留给我就好"

**If ADRs are missing `## Status` (and no parenthetical issue):**
Use `AskUserQuestion`:
- "The most urgent fix is adding `## Status` to [N] ADR(s): [list filenames].
  Without it, /story-readiness silently passes all ADR checks. Start with
  [first affected filename]?"
  - "Yes — retrofit [first affected filename] now"
  - "Retrofit all [N] ADRs one by one"
  - "I'll handle ADRs myself"

**如果 ADR 缺少 `## Status`（且没有括号问题）：**
使用 `AskUserQuestion`：
- "最紧急的修复是为 [N] 个 ADR 添加 `## Status`：[列出文件名]。没有它，/story-readiness 会静默通过所有 ADR 检查。先从 [第一个受影响文件名] 开始吗？"
  - "是 —— 现在就改造 [第一个受影响文件名]"
  - "逐个改造全部 [N] 个 ADR"
  - "我自己来处理 ADR"

**If GDDs are missing Acceptance Criteria (and no blocking issues above):**
Use `AskUserQuestion`:
- "The most urgent gap is missing Acceptance Criteria in [N] GDD(s):
  [list filenames]. Without them, /create-stories can't generate stories.
  Start with [highest-priority GDD filename]?"
  - "Yes — add Acceptance Criteria to [GDD filename] now"
  - "Do all [N] GDDs one by one"
  - "I'll handle GDDs myself"

**如果 GDD 缺少验收标准（且上面没有阻断性问题）：**
使用 `AskUserQuestion`：
- "最紧急的缺口是 [N] 个 GDD 缺少验收标准：[列出文件名]。没有它们，/create-stories 无法生成故事。先从 [优先级最高的 GDD 文件名] 开始吗？"
  - "是 —— 现在就为 [GDD 文件名] 添加验收标准"
  - "逐个处理全部 [N] 个 GDD"
  - "我自己来处理 GDD"

**Otherwise, if any BLOCKING or HIGH gap remains** (one no branch above names —
e.g. a missing TR registry):
Use `AskUserQuestion`:
- "The most urgent remaining gap is [first BLOCKING or HIGH item in the plan] —
  [one line on what it breaks]. Start on it now?"
  - "Yes — start on [item]"
  - "Show me that plan item first"
  - "Done — leave me with the plan"

**否则，如果仍存在任何阻断或高缺口**（上面没有任何分支提到的那种 —— 例如缺少 TR 注册表）：
使用 `AskUserQuestion`：
- "剩下最紧急的缺口是 [计划中第一个阻断或高优先级条目] —— [用一行说明它会破坏什么]。现在就着手处理吗？"
  - "是 —— 开始处理 [条目]"
  - "先给我看看那个计划条目"
  - "完成 —— 把计划留给我就好"

**If no BLOCKING or HIGH gaps exist:**
Use `AskUserQuestion`:
- "No blocking gaps — this project is template-compatible. What next?"
  - "Walk me through the medium-priority improvements"
  - "Run /project-stage-detect for a broader health check"
  - "Done — I'll work through the plan at my own pace"

**如果不存在阻断或高缺口：**
使用 `AskUserQuestion`：
- "没有阻断性缺口 —— 该项目与模板兼容。接下来做什么？"
  - "带我过一遍中优先级改进"
  - "运行 /project-stage-detect 做一次更全面的健康检查"
  - "完成 —— 我会按自己的节奏推进计划"

> **Adoption plan saved to `docs/adoption-plan-[date].md`.** Re-run `/adopt` at any time to re-check remaining gaps as you complete them.

> **采纳计划已保存到 `docs/adoption-plan-[date].md`。** 随时重新运行 `/adopt`，以在你完成时复查剩余缺口。

---
