# /prototype — Phase 9: Summary and Next Steps
# /prototype — 第九阶段：总结与下一步

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/prototype` 的一部分。`SKILL.md` 说明了何时阅读本文件；它已解析的设置，以及其后各标题下的规则，在此同样适用。

## Phase 9: Summary and Next Steps
## 第九阶段：总结与下一步

Output a summary: the hypothesis, the result, and the final recommendation.
Link to `prototypes/[concept-name]-concept/REPORT.md`.

输出一段总结：假设、结果以及最终推荐结论。链接到 `prototypes/[concept-name]-concept/REPORT.md`。

**If PROCEED:**
Your concept prototype validated the core idea. Now design it properly, informed by
what you just learned.

**如果是 PROCEED：**
你的概念原型验证了核心想法。现在根据你刚刚学到的内容，正式地设计它。

At `workflow: minimal`: `/create-stories` (from the brief), then `/dev-story`
on the first story — the rest of this list is the `standard`/`full` path.

在 `workflow: minimal` 下：`/create-stories`（从简报出发），然后对第一个故事执行 `/dev-story`——本列表的其余部分属于 `standard`/`full` 路径。

Recommended path (in order, `standard`/`full`):
1. `/design-review design/gdd/game-concept.md` — validate the concept doc against what the prototype revealed
2. `/gate-check` — confirm readiness to advance to Systems Design
3. `/art-bible` — define visual identity (optional but worth doing before GDDs)
4. `/map-systems` — decompose the concept into all game systems
5. `/design-system [mechanic]` — GDD for each MVP system; use prototype learnings
   in the Tuning Knobs and Formulas sections
6. `/review-all-gdds` — cross-system consistency check

推荐路径（按顺序，`standard`/`full`）：
1. `/design-review design/gdd/game-concept.md` —— 对照原型所揭示的内容验证概念文档
2. `/gate-check` —— 确认是否已准备好推进到系统设计
3. `/art-bible` —— 定义视觉识别（可选，但在编写 GDD 之前值得做）
4. `/map-systems` —— 把概念分解为所有游戏系统
5. `/design-system [mechanic]` —— 为每个 MVP 系统编写 GDD；在 Tuning Knobs 和 Formulas 章节中运用原型所学
6. `/review-all-gdds` —— 跨系统一致性检查

**Note:** If you used the HTML path and feel is still uncertain, consider running
a quick engine path prototype targeting feel before writing GDDs.

**注意：** 如果你使用了 HTML 路径且手感仍不确定，考虑在编写 GDD 之前运行一个以手感为目标的快速 Engine 路径原型。

**If PIVOT:**

**如果是 PIVOT：**

Before routing to the next prototype, capture the carry-forward note. Ask these
two questions (plain text, one at a time):

在转到下一个原型之前，先记录结转说明。提出这两个问题（纯文本，一次一个）：

1. "What specifically worked in this prototype that we should preserve in the next version?"
2. "What is the single most important thing to change?"

1. "这个原型中具体哪些地方奏效了，我们应该在下一个版本中保留？"
2. "最重要的一处改变是什么？"

Ask: "May I write this to `prototypes/[concept-name]-concept/PIVOT-NOTE.md`?"

询问："我可以把它写入 `prototypes/[concept-name]-concept/PIVOT-NOTE.md` 吗？"

If yes, write the file with: original hypothesis, what to keep, what to change, and
the revised hypothesis for the next prototype. The next `/prototype` run picks it
up at the start of Phase 1.

如果同意，就写入该文件，包含：原始假设、需要保留的、需要改变的，以及下一个原型修订后的假设。下一次 `/prototype` 运行会在第一阶段开始时读取它。

- Run `/prototype [revised-concept]` to test the adjusted direction
- Or `/brainstorm [hint]` if the concept needs more fundamental rethinking

- 运行 `/prototype [revised-concept]` 来测试调整后的方向
- 或者如果概念需要更根本的重新思考，运行 `/brainstorm [hint]`

**If KILL:**

**如果是 KILL：**

Before moving on, run this check to confirm the verdict is sound and not temporary frustration:

在继续之前，运行这项检查，确认该判定是合理的，而不是一时的挫败感：

- [ ] Core mechanic still unclear to testers after 2+ playtests?
- [ ] No "fun moment" (smile, laugh, or retry by choice) observed in any session?
- [ ] 3+ PIVOT iterations on the same concept with no clear improvement?
- [ ] Concept only works when heavily explained or when the dev guides the player?
- [ ] Building this feels like obligation, not excitement?

- [ ] 经过 2 次以上试玩后，测试者仍不清楚核心机制？
- [ ] 在任何会话中都没有观察到"有趣时刻"（微笑、大笑，或主动重试）？
- [ ] 对同一概念进行了 3 次以上 PIVOT 迭代，且没有明显改善？
- [ ] 概念只有在大量解释或开发者引导玩家时才成立？
- [ ] 构建它的感觉像是义务，而不是兴奋？

If 2+ boxes apply → KILL verdict is sound. If 0–1 apply → consider one more focused PIVOT before killing.

如果有 2 项以上命中 → KILL 判定是合理的。如果命中 0–1 项 → 考虑在终止之前再做一次聚焦的 PIVOT。

**Document the kill in `prototypes/GRAVEYARD.md`** (create if it doesn't exist).
Ask: "May I append this concept to `prototypes/GRAVEYARD.md`?" If yes, add one entry:

**在 `prototypes/GRAVEYARD.md` 中记录这次终止**（如果不存在则创建）。
询问："我可以把这个概念追加到 `prototypes/GRAVEYARD.md` 吗？"如果同意，添加一条记录：

```
## [Concept Name] — YYYY-MM-DD
- **Kill reason:** [specific blocker — not "it was boring" but "players never understood the core action"]
- **What worked:** [2-3 things worth carrying forward to future concepts]
- **What failed:** [the specific mechanic, design decision, or scope issue]
- **Next time:** [one explicit action to try differently on a similar concept]
```

```
## [Concept Name] — YYYY-MM-DD
- **Kill reason（终止原因）:** [具体的阻塞点——不要写"它很无聊"，而要写"玩家始终没理解核心动作"]
- **What worked（奏效之处）:** [2-3 件值得带到未来概念中的事]
- **What failed（失败之处）:** [具体的机制、设计决定或范围问题]
- **Next time（下次）:** [在类似概念上尝试不同做法的某一项明确行动]
```

This file exists so the same mistake doesn't get made twice on the next concept.

这个文件的存在，是为了让同一个错误不在下一个概念上重演。

- Run `/brainstorm open` or `/brainstorm [new-hint]` to explore a different concept
- The prototype report is the deliverable — no further action needed

- 运行 `/brainstorm open` 或 `/brainstorm [new-hint]` 来探索不同的概念
- 原型报告就是交付物——无需进一步行动

**If NOT ASSESSED (nobody has played it):**

**如果是 NOT ASSESSED（无人试玩）：**

There is no fun evidence yet, so PROCEED, PIVOT and KILL are all unreachable —
report NOT ASSESSED and stop here rather than guess.

目前还没有关于趣味性的证据，因此 PROCEED、PIVOT 和 KILL 都无从谈起——报告 NOT ASSESSED 并在此停止，而不是猜测。

- Play it, then run `/prototype [same concept]` again
- The report and the concept index row read NOT ASSESSED until a playtest happens

- 试玩它，然后再次运行 `/prototype [same concept]`
- 在试玩发生之前，报告和概念索引中的那一行都显示 NOT ASSESSED

---

---
