# /prototype — Phase 8: Creative Director Review
# /prototype — 第八阶段：创意总监评审

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/prototype` 的一部分。`SKILL.md` 说明了何时阅读本文件；它已解析的设置，以及其后各标题下的规则，在此同样适用。

## Phase 8: Creative Director Review
## 第八阶段：创意总监评审

**Review mode check:**
- `solo` → skip. Note: "CD-PLAYTEST skipped — Solo mode."
- `lean` → skip. Note: "CD-PLAYTEST skipped — Lean mode."
- `full` → spawn `creative-director` via `Agent` using gate **CD-PLAYTEST** if
  `design/gdd/game-concept.md` exists with game pillars defined, or
  `design/game-brief.md` exists (the `rigor: minimal` brief has no pillars — its
  pitch and "what they feel" line stand in). If neither is available, note:
  "CD-PLAYTEST skipped — game pillars not yet defined at concept prototype stage."

**评审模式检查：**
- `solo` → 跳过。注明："CD-PLAYTEST skipped — Solo mode."（CD-PLAYTEST 已跳过——单人模式。）
- `lean` → 跳过。注明："CD-PLAYTEST skipped — Lean mode."（CD-PLAYTEST 已跳过——精简模式。）
- `full` → 如果 `design/gdd/game-concept.md` 存在且已定义游戏支柱，或 `design/game-brief.md` 存在（`rigor: minimal` 的简报表没有支柱——以其推介语和"他们感受什么"的一句代之），则通过 `Agent` 生成 `creative-director`，使用门禁 **CD-PLAYTEST**。如果两者都不可用，注明："CD-PLAYTEST skipped — game pillars not yet defined at concept prototype stage."（CD-PLAYTEST 已跳过——概念原型阶段尚未定义游戏支柱。）

Pass: the full REPORT.md content, the original hypothesis, and game pillars /
core fantasy from `design/gdd/game-concept.md` (or the brief's pitch and "what
they feel" line from `design/game-brief.md`). Read the concept by section: find the
headings you need with the Grep tool (pattern `^#`, content mode) and Read those
ranges with offset and limit.

传入：完整的 REPORT.md 内容、原始假设，以及来自 `design/gdd/game-concept.md` 的游戏支柱/核心幻想（或来自 `design/game-brief.md` 的简报推介语和"他们感受什么"一句）。按章节阅读概念：用 Grep 工具（模式 `^#`，content 模式）找到你需要的标题，再用 offset 和 limit 读取这些区段。

The creative director evaluates the result against the game's creative vision and
returns one of the gate's verdicts — APPROVE, CONCERNS or REJECT — or NOT
ASSESSED when it could not judge. Apply it to the recommendation:

创意总监会根据游戏的创意愿景评估结果，并返回该门禁的其中一种判定——APPROVE（批准）、CONCERNS（有疑虑）或 REJECT（拒绝）——或在无法判断时返回 NOT ASSESSED（未评估）。将其应用于推荐结论：

- **APPROVE** → the recommendation stands.
- **APPROVE** → 推荐结论维持不变。
- **CONCERNS** → show the concerns alongside the recommendation, then use
  `AskUserQuestion`: `Revise the recommendation` / `Accept with noted concerns` /
  `Discuss further`. The user decides; the director does not.
- **CONCERNS** → 在推荐结论旁展示这些疑虑，然后使用 `AskUserQuestion`：`Revise the recommendation`（修订推荐结论）/ `Accept with noted concerns`（带着已注明的疑虑接受）/ `Discuss further`（进一步讨论）。由用户决定；总监不做决定。
- **REJECT** (the core fantasy is not present) → a PROCEED recommendation cannot
  stand. Use `AskUserQuestion` to ask the user to choose `PIVOT` or `KILL`, and run
  Phase 9 for that choice. A PIVOT or KILL recommendation stands.
- **REJECT**（核心幻想不存在）→ PROCEED 推荐结论不能成立。使用 `AskUserQuestion` 请用户选择 `PIVOT` 或 `KILL`，并针对该选择执行第九阶段。PIVOT 或 KILL 推荐结论维持不变。
- **NOT ASSESSED** (the director lacked an input — `.claude/docs/director-gates.md`)
  → not an approval. Name what was missing; supply it and re-run the gate, or
  record the review as NOT ASSESSED and let the user decide whether the
  recommendation stands unreviewed.
- **NOT ASSESSED**（总监缺少某项输入——`.claude/docs/director-gates.md`）→ 这不是批准。指明缺少什么；补齐后重新运行门禁，或者把评审记录为 NOT ASSESSED，让用户决定该推荐结论是否未经评审仍然成立。

When the director returned CONCERNS, REJECT or NOT ASSESSED, ask "May I update
`prototypes/[concept-name]-concept/REPORT.md` and its `prototypes/index.md`
row?", then record the director's verdict and reason in REPORT.md, and the final
recommendation in both if it changed.

当总监返回 CONCERNS、REJECT 或 NOT ASSESSED 时，询问"我可以更新 `prototypes/[concept-name]-concept/REPORT.md` 及其 `prototypes/index.md` 中的那一行吗？"，然后在 REPORT.md 中记录总监的判定和理由，如果最终推荐结论发生变化，则在两者中都记录。

---
