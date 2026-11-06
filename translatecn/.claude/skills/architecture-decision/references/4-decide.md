# /architecture-decision — Step 4: Guide the Decision Collaboratively

# /architecture-decision —— 步骤 4：协作式引导决策

> Part of `/architecture-decision`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> `/architecture-decision` 的一部分。`SKILL.md` 说明了何时读取本文件；它解析出的设置以及它后续标题下的规则在这里同样适用。

## 4. Guide the decision collaboratively

## 4. 协作式引导决策

Before asking anything, derive the skill's best guesses from the context already
gathered (GDDs read, engine reference loaded, existing ADRs scanned). Then present
a **confirm/adjust** prompt using `AskUserQuestion` — not open-ended questions.

在询问任何内容之前，先从已收集的上下文（已读取的 GDD、已加载的引擎参考、已扫描的现有 ADR）中推导出技能的最佳猜测。然后用 `AskUserQuestion` 呈现一个**确认/调整**提示 —— 而不是开放式问题。

**Derive assumptions first:**
- **Problem**: Infer from the title + GDD context what decision needs to be made
- **Alternatives**: Propose 2-3 concrete options from engine reference + GDD requirements
- **Dependencies**: Scan existing ADRs for upstream dependencies. **If the scan is
  inconclusive, present `UNKNOWN — scan inconclusive, please confirm`, never
  `None`.** The two are not interchangeable: `None` asserts that nothing upstream
  constrains this decision, and a user confirming a prefilled list cannot tell an
  assertion from a guess. This field is load-bearing — `/architecture-review`
  flags unaccepted dependencies, `/dev-story` reads it, and the acceptance route
  in Phase 0 **refuses to accept an ADR whose dependencies are not themselves
  Accepted**. A dependency list that defaulted to empty makes that check pass
  while examining nothing. `UNKNOWN` must be resolved during the confirm/adjust
  prompt; it is a prompt state, never a value written to the file
- **GDD linkage**: Extract which GDD systems the title directly relates to
- **Status**: Always `Proposed` for new ADRs — never ask the user what the status is

**先推导假设：**
- **问题**：从标题 + GDD 上下文推断需要做出什么决策
- **备选方案**：从引擎参考 + GDD 需求中提出 2-3 个具体选项
- **依赖**：扫描现有 ADR 以查找上游依赖。**如果扫描没有结论，呈现 `UNKNOWN — scan inconclusive, please confirm`，绝不呈现 `None`。** 两者不可互换：`None` 断言没有任何上游因素约束该决策，而确认一份预填列表的用户无法分辨断言与猜测。该字段是关键性的 —— `/architecture-review` 会标记未被采纳的依赖，`/dev-story` 会读取它，而阶段 0 的采纳路径**拒绝采纳依赖项本身未被采纳的 ADR**。默认为空的依赖列表会让该检查在什么都不检查的情况下通过。`UNKNOWN` 必须在确认/调整提示期间解决；它是一种提示状态，绝不是写入文件的值
- **GDD 关联**：提取标题直接涉及哪些 GDD 系统
- **状态**：新 ADR 始终为 `Proposed` —— 绝不要询问用户状态是什么

**Scope of assumptions tab**: Assumptions cover only: problem framing, alternative approaches, upstream dependencies, GDD linkage, and status. Schema design questions (e.g., "How should spawn timing work?", "Should data be inline or external?") are NOT assumptions — they are design decisions belonging to a separate step after the assumptions are confirmed. Do not include schema design questions in the assumptions AskUserQuestion widget.

**假设页面的范围**：假设仅涵盖：问题框定、备选方案、上游依赖、GDD 关联和状态。模式设计问题（例如"生成时机应如何工作？"、"数据应内联还是外部？"）不是假设 —— 它们是属于假设确认之后单独一步的设计决策。不要将模式设计问题放入假设的 AskUserQuestion 组件中。

**After assumptions are confirmed**, if the ADR involves schema or data design choices, use a separate multi-tab `AskUserQuestion` to ask each design question independently before drafting.

**在假设得到确认之后**，如果该 ADR 涉及模式或数据设计选择，使用单独的多标签 `AskUserQuestion`，在起草之前独立询问每个设计问题。

**Present assumptions with `AskUserQuestion`:**

**用 `AskUserQuestion` 呈现假设：**

```
Here's what I'm assuming before drafting:

Problem: [one-sentence problem statement derived from context]
Alternatives I'll consider:
  A) [option derived from engine reference]
  B) [option derived from GDD requirements]
  C) [option from common patterns]
GDD systems driving this: [list derived from context]
Dependencies: [upstream ADRs if any, otherwise "None"]
Status: Proposed

[A] Proceed — draft with these assumptions
[B] Change the alternatives list
[C] Adjust the GDD linkage
[D] Add a performance budget constraint
[E] Something else needs changing first
```

Do not generate the ADR until the user confirms assumptions or provides corrections.

在用户确认假设或提供更正之前，不要生成 ADR。

**After engine specialist and TD reviews return** (Step 5.5/5.6), if unresolved
decisions remain, present each one as a separate `AskUserQuestion` with the proposed
options as choices plus a free-text escape:

**在引擎专家和 TD 评审返回之后**（步骤 5.5/5.6），如果仍有未解决的决策，将每个决策作为单独的 `AskUserQuestion` 呈现，把提议的选项作为选择项，外加一个自由文本出口：

```
Decision: [specific unresolved point]
[A] [option from specialist review]
[B] [alternative option]
[C] Different approach — I'll describe it
```

**ADR Dependencies** — derive from existing ADRs, then confirm:
- Does this decision depend on any other ADR not yet Accepted?
- Does it unlock or unblock any other ADR or epic?
- Does it block any specific epic from starting?

**ADR Dependencies** —— 从现有 ADR 推导，然后确认：
- 该决策是否依赖于任何尚未被采纳的其他 ADR？
- 它是否解锁或解阻任何其他 ADR 或史诗？
- 它是否阻止任何特定史诗启动？

Record answers in the **ADR Dependencies** section. Write "None" for each field if no constraints apply.

将答案记录在 **ADR Dependencies** 章节中。如果没有任何约束适用，每个字段都写 "None"。

---
