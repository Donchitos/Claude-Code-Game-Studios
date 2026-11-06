# Concept Prototype Report: [Concept Name]
# 概念原型报告：[概念名称]

> **Date**: [YYYY-MM-DD]
> **Prototype Path**: [HTML / Engine / Paper]
> **Concept File**: design/gdd/game-concept.md, or design/game-brief.md (if either exists)
> **日期**：[YYYY-MM-DD]
> **原型路径**：[HTML / 引擎 / 纸面]
> **概念文件**：design/gdd/game-concept.md，或 design/game-brief.md（若存在其一）

---

## Hypothesis
## 假设

[The falsifiable hypothesis this prototype set out to test:
"If the player [does X], they will feel [Y] — evidenced by [measurable signal Z]."]
[本原型旨在检验的可证伪假设：
“若玩家[做 X]，他们将感受到 [Y] —— 由[可测量的信号 Z]佐证。”]

---

## Riskiest Assumption Tested
## 检验的最高风险假设

[What was identified as the biggest risk in the concept, and whether it proved out.]
[概念中被识别为最大风险的内容，以及它是否得到验证。]

---

## Approach
## 方法

[What was built, how long it took, what shortcuts were taken deliberately.]
[构建了什么、耗时多久、有意采取了哪些简化。]

**Path chosen:** [HTML / Engine / Paper]
**Reason for path:** [Why this path was appropriate for this hypothesis]
**所选路径**：[HTML / 引擎 / 纸面]
**选择该路径的原因**：[为何该路径适合此假设]

**Shortcuts taken (intentional):**
- [e.g., hardcoded values, placeholder art, no menus, etc.]
**有意采取的简化：**
- [例如硬编码数值、占位美术、无菜单等]

---

## Result
## 结果

[What actually happened — specific observations, not opinions. Quote playtesters
directly where possible.]
[实际发生了什么 —— 具体的观察，而非主观意见。尽可能
直接引用试玩者原话。]

---

## Metrics
## 指标

| Metric | Value |
|--------|-------|
| Path used | [HTML / Engine / Paper] |
| Iterations to playable | [N — Engine path only; N/A otherwise] |
| Prototype duration | [e.g., 4 hours] |
| Playtesters | [N internal / N external] |
| Feel assessment | [Specific — "response felt sluggish at 200ms" not "felt bad"] |
| Hypothesis verdict | [CONFIRMED / PARTIALLY CONFIRMED / REFUTED] |

| 指标 | 数值 |
|--------|-------|
| 使用的路径 | [HTML / 引擎 / 纸面] |
| 到可玩状态的迭代次数 | [N —— 仅引擎路径；其他情况为 N/A] |
| 原型时长 | [例如 4 小时] |
| 试玩者 | [N 名内部 / N 名外部] |
| 手感评估 | [具体 —— “200ms 时响应感觉迟滞”，而非“感觉不好”] |
| 假设判定 | [已证实 / 部分证实 / 已推翻] |

---

## Recommendation: [PROCEED / PIVOT / KILL / NOT ASSESSED — built but nobody has played it]
## 建议：[PROCEED / PIVOT / KILL / NOT ASSESSED —— 已构建但无人试玩]

[One paragraph explaining the recommendation with evidence from the result above.]
[一段文字，依据上述结果的证据解释该建议。]

---

## If Proceeding
## 若继续推进

[What the prototype revealed that should directly inform GDD writing:]
[原型所揭示的、应直接指导 GDD 撰写的内容：]

- **Core tuning values discovered:** [e.g., "jump height of 3.5 units felt best"]
- **Assumptions confirmed:** [What the concept doc assumed that proved true]
- **Assumptions disproved:** [What the concept doc assumed that proved wrong]
- **Emergent mechanics:** [Behaviors that appeared during testing worth formalizing]
- **发现的核心调校数值**：[例如“3.5 单位的跳跃高度感觉最佳”]
- **已证实的假设**：[概念文档中假设并被证明为真的内容]
- **已推翻的假设**：[概念文档中假设并被证明为错误的内容]
- **涌现机制**：[测试中出现、值得正式化的行为]

> Note: If HTML path was used and feel is uncertain, consider an engine prototype
> targeting feel specifically before committing to GDDs.
> 备注：若使用了 HTML 路径且手感不确定，考虑在定稿 GDD 之前，
> 专门针对手感做一个引擎原型。

**Next steps:**
1. `/design-review design/gdd/game-concept.md`
2. `/gate-check`
3. `/map-systems`
4. `/design-system [mechanic]` (use learnings in Tuning Knobs and Formulas sections)
**后续步骤：**
1. `/design-review design/gdd/game-concept.md`
2. `/gate-check`
3. `/map-systems`
4. `/design-system [mechanic]`（在调校旋钮和公式章节中使用所学内容）

---

## If Pivoting
## 若转向

[What alternative direction the results suggest — what felt almost right and what
to adjust. Be specific about what to change, not just that something needs changing.]
[结果暗示了何种替代方向 —— 什么几乎对了、什么需要调整。
具体说明要改什么，而不只是说某处需要改。]

**Pivot direction:** [What to try differently]
**What to keep:** [What worked and should be preserved]
**Next step:** `/prototype [revised-concept]`
**转向方向**：[要尝试的不同之处]
**保留内容**：[有效且应保留的内容]
**后续步骤**：`/prototype [revised-concept]`

---

## If Killing
## 若终止

[Why this concept does not work — what specific signal led to this verdict.
This report is the deliverable; no further action needed on this concept.]
[为何此概念不可行 —— 是什么具体信号导致此判定。
本报告即为交付物；此概念无需进一步行动。]

**Next step:** `/brainstorm [new-direction]`
**后续步骤**：`/brainstorm [new-direction]`

---

## Lessons Learned
## 经验教训

- **What assumptions were broken by actually building this?**
  [...]
- **实际构建打破了哪些假设？**
  [...]

- **What surprised us that didn't show up in the brainstorm?**
  [...]
- **有哪些在头脑风暴中未出现、却让我们意外的地方？**
  [...]

- **What would we test differently next time?**
  [...]
- **下次我们会如何以不同方式测试？**
  [...]

---

> *Prototype code location: `prototypes/[concept-name]-concept/`*
> *This code is throwaway. Never refactor into production.*
> *原型代码位置：`prototypes/[concept-name]-concept/`*
> *此代码是一次性的。永远不要重构进生产代码。*
