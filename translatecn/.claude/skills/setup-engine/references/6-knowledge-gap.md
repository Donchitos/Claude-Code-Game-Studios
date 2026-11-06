# /setup-engine — Section 6: Determine Knowledge Gap

# /setup-engine — 第 6 节：确定知识缺口

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/setup-engine` 的一部分。`SKILL.md` 指明了何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此同样适用。

## 6. Determine Knowledge Gap

Check whether the engine version is likely beyond the LLM's training data.

**Known approximate coverage** — the same figures the shipped
`docs/engine-reference/*/VERSION.md` files record:
- LLM knowledge cutoff: **May 2025**
- Godot: training data likely covers up to ~4.3
- Unity: training data likely covers up to ~2022 LTS (2022.3)
- Unreal: training data likely covers up to ~5.3

## 6. 确定知识缺口

检查引擎版本是否可能超出了 LLM 的训练数据。

**已知的大致覆盖范围** —— 与随附的
`docs/engine-reference/*/VERSION.md` 文件记录的相同数字：
- LLM 知识截止：**2025 年 5 月**
- Godot：训练数据大致覆盖到 ~4.3
- Unity：训练数据大致覆盖到 ~2022 LTS（2022.3）
- Unreal：训练数据大致覆盖到 ~5.3

> **This table goes stale silently, and a stale table fails in the dangerous
> direction only if it is too *new*.** A cutoff left unchanged for a year after
> it stopped being true over-classifies risk — safe, but every project then pays
> for full reference docs it may not have needed.
> The opposite error is the harmful one: a cutoff claimed *later* than the model's
> actual one marks post-cutoff versions LOW RISK and suppresses the reference
> docs that exist to stop invented APIs.
>
> **If the model running this skill states an earlier training cutoff than the
> one above, do not trust the table.** Say so, and treat the engine version as
> `HIGH RISK` regardless of the comparison — a cutoff the model does not have is
> not a cutoff that was met.

> **本表会悄悄过时，而过时的表只有在其过*新*时才会往危险
> 方向失效。** 一个截止日期在其不再为真之后仍保持不变，会过度
> 归类风险 —— 这很安全，但随后每个项目都会为可能并不需要的完整参考文档
> 付出代价。
> 相反的错误才是有害的：声称的截止日期*晚于*模型的
> 实际截止日期，会把截止后的版本标记为 LOW RISK，并压制那些
> 本用于阻止臆造 API 的参考文档。
>
> **如果运行本技能的模型声明的训练截止早于上面的
> 日期，就不要相信本表。** 如实说明，并无论比较结果如何
> 都将引擎版本视为 `HIGH RISK` —— 模型没有的截止日期，
> 不算满足了截止日期。

Compare the user's chosen version against these baselines:

- **Within training data** → `LOW RISK` — reference docs optional but recommended
- **Near the edge** → `MEDIUM RISK` — reference docs recommended
- **Beyond training data** → `HIGH RISK` — reference docs required

Inform the user which category they're in and why.

将用户选定的版本与这些基线进行比较：

- **在训练数据范围内** → `LOW RISK` —— 参考文档可选，但建议提供
- **接近边界** → `MEDIUM RISK` —— 建议提供参考文档
- **超出训练数据** → `HIGH RISK` —— 必须提供参考文档

告知用户他们属于哪一类以及原因。

---
