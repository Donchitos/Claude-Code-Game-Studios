# /review-all-gdds — Phase 2: Cross-GDD Consistency
# /review-all-gdds — 阶段 2：跨 GDD 一致性

> Part of `/review-all-gdds`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/review-all-gdds` 的组成部分。`SKILL.md` 指明何时读取本文件；它已解析的各项设置，
> 以及其后续标题下所列的规则，在此同样适用。

## Phase 2: Cross-GDD Consistency
## 阶段 2：跨 GDD 一致性

**In this file:**
**本文件内容：**

- 2a: Dependency Bidirectionality
- 2b: Rule Contradictions
- 2c: Stale References
- 2d: Data and Tuning Knob Ownership Conflicts
- 2e: Formula Compatibility
- 2f: Acceptance Criteria Cross-Check

- 2a：依赖双向性
- 2b：规则矛盾
- 2c：过期引用
- 2d：数据与调参旋钮归属冲突
- 2e：公式兼容性
- 2f：验收标准交叉核对

Work through every pair and group of GDDs to find contradictions and gaps.

逐一处理每一对、每一组 GDD，找出矛盾与缺口。

### 2a: Dependency Bidirectionality
### 2a：依赖双向性

For every GDD's Dependencies section, check that every listed dependency is
reciprocal:
- If GDD-A lists "depends on GDD-B", check that GDD-B lists GDD-A as a dependent
- If GDD-A lists "depended on by GDD-C", check that GDD-C lists GDD-A as a dependency
- Flag any one-directional dependency as a consistency issue

对每个 GDD 的 Dependencies 分区，检查所列的每一条依赖是否互为对应：
- 如果 GDD-A 列出“依赖 GDD-B”，检查 GDD-B 是否把 GDD-A 列为依赖于它的文档（dependent）
- 如果 GDD-A 列出“被 GDD-C 所依赖”，检查 GDD-C 是否把 GDD-A 列为一项依赖
- 把任何单向依赖标记为一致性问题

```
⚠️  Dependency Asymmetry
[system-a].md lists: Depends On → [system-b].md
[system-b].md does NOT list [system-a].md as a dependent
→ One of these documents has a stale dependency section
```

```
⚠️  依赖不对称
[system-a].md 列出：Depends On → [system-b].md
[system-b].md 未把 [system-a].md 列为 dependent
→ 这两份文档中有一份的依赖分区已过期
```

### 2b: Rule Contradictions
### 2b：规则矛盾

For each game rule, mechanic, or constraint defined in any GDD, check whether
any other GDD defines a contradicting rule for the same situation:

对任何 GDD 中定义的每条游戏规则、机制或约束，检查是否有其他 GDD 针对同一情形定义了
相互矛盾的规则：

Categories to scan:
- **Floor/ceiling rules**: Does any GDD define a minimum value for an output? Does any other say a different system can bypass that floor? These contradict.
- **Resource ownership**: If two GDDs both define how a shared resource accumulates or depletes, do they agree?
- **State transitions**: If GDD-A describes what happens when a character dies,
  does GDD-B's description of the same event agree?
- **Timing**: If GDD-A says "X happens on the same frame", does GDD-B assume
  it happens asynchronously?
- **Stacking rules**: If GDD-A says status effects stack, does GDD-B assume
  they don't?

需扫描的类别：
- **下限/上限规则**：是否有 GDD 为某个输出定义了最小值？是否有另一个 GDD 声称某个不同的
  系统可以绕过该下限？这两者相互矛盾。
- **资源归属**：如果两个 GDD 都定义了某个共享资源如何累积或消耗，它们的说法是否一致？
- **状态转换**：如果 GDD-A 描述了角色死亡时会发生什么，
  GDD-B 对同一事件的描述是否一致？
- **时序**：如果 GDD-A 说“X 在同一帧发生”，GDD-B 是否假设
  它异步发生？
- **叠加规则**：如果 GDD-A 说状态效果会叠加，GDD-B 是否假设
  它们不叠加？

```
🔴 Rule Contradiction
[system-a].md: "Minimum [output] after reduction is [floor_value]"
[system-b].md: "[mechanic] bypasses [system-a]'s rules and can reduce [output] to 0"
→ These rules directly contradict. Which GDD is authoritative?
```

```
🔴 规则矛盾
[system-a].md：“归约后 [output] 的最小值为 [floor_value]”
[system-b].md：“[mechanic] 可绕过 [system-a] 的规则，并可将 [output] 降至 0”
→ 这些规则直接矛盾。以哪个 GDD 为权威？
```

### 2c: Stale References
### 2c：过期引用

**Start from the `## Cross-References` table where a GDD has one.** That table is
the document's own declaration of what it depends on — `templates/guidance/game-design-document-guide.md`
tells authors it is machine-checked here, and `/design-system` requires it
whenever Dependencies names another GDD. For each row, confirm the `Target GDD`
exists and the `Specific Element Referenced` is still present in it under that
name, with the declared `Nature` still accurate.

**从 GDD 的 `## Cross-References` 表开始（若该 GDD 有这张表）。** 这张表是文档对自身所依赖
内容的声明——`templates/guidance/game-design-document-guide.md` 告知作者它会在此被机器校验，
而只要 Dependencies 中提到了另一个 GDD，`/design-system` 就要求存在这张表。对每一行，确认
`Target GDD` 存在，且 `Specific Element Referenced` 仍以该名称存在于其中，并且所声明的
`Nature` 仍然准确。

A table that is absent, or still holding the template's bracketed examples, is
itself reportable: say the GDD declares no cross-references and that the prose
scan below was the only check applied. Do not treat an absent table as "no
dependencies" — it far more often means the section was never authored.

表格缺失，或仍保留模板中的方括号示例，本身也值得报告：说明该 GDD 未声明任何交叉引用，
下方正文扫描是唯一应用的检查。不要把缺失的表格当作“没有依赖”——它更常意味着该分区从未被
编写。

**Then scan the prose regardless**, table or no table: a declared table catches
what the author remembered, and the scan below catches what they did not.

**然后无论如何都扫描正文**，无论有没有表格：声明的表格只能捕捉作者记得的内容，而下方的
扫描能捕捉他们遗漏的内容。

For every cross-document reference (GDD-A mentions a mechanic, value, or
system name from GDD-B), verify the referenced element still exists in GDD-B
with the same name and behaviour:

对于每一处跨文档引用（GDD-A 提到 GDD-B 中的某个机制、数值或系统名称），验证被引用的元素
是否仍以相同名称和行为存在于 GDD-B 中：

- If GDD-A says "combo multiplier from the combat system feeds into score", check
  that the combat GDD actually defines a combo multiplier that outputs to score
- If GDD-A references "the progression curve defined in [system].md", check that
  [system].md actually has that curve, not a different progression model
- If GDD-A was written before GDD-B and assumed a mechanic that GDD-B later
  designed differently, flag GDD-A as containing a stale reference. Severity: a
  reference to a mechanic or formula that **does not exist** is **Blocking** — the
  architecture would inherit a rule nobody defined; one that exists but was
  designed differently is a **Warning**, unless the difference changes a rule the
  referencing GDD depends on (then Blocking)
- If the **target GDD is not written yet** (no file in `design/gdd/`): when
  `systems-index.md` lists that system (e.g. `Status: Not Started`), it is a
  **Warning** — a dependency on planned work, to re-check when that GDD is
  written; when neither a GDD nor a systems-index entry exists for it, it is
  **Blocking** — nothing will ever define it

- 如果 GDD-A 说“战斗系统的连击倍率会输入到得分”，检查
  战斗 GDD 是否确实定义了向得分输出的连击倍率
- 如果 GDD-A 引用“[system].md 中定义的进阶曲线”，检查
  [system].md 是否确实存在该曲线，而不是另一种进阶模型
- 如果 GDD-A 的编写早于 GDD-B，并假设了某个机制，而 GDD-B 后来
  设计得不同，则把 GDD-A 标记为包含过期引用。严重程度：
  引用**不存在**的机制或公式为**阻断级**——
  架构将继承一条无人定义的规则；引用存在但设计不同的为
  **警告级**，除非该差异改变了引用方 GDD 所依赖的规则
  （此时为阻断级）
- 如果**目标 GDD 尚未编写**（`design/gdd/` 中没有文件）：当
  `systems-index.md` 列出了该系统（例如 `Status: Not Started`），则为
  **警告级**——这是对计划中工作的依赖，等该 GDD
  编写后再复查；当既没有 GDD 也没有 systems-index 条目时，则为
  **阻断级**——将永远没有东西去定义它

```
🔴 Stale Reference
inventory.md (written first): "Item weight uses the encumbrance formula
  from movement.md"
movement.md (written later): Defines no encumbrance formula — uses a flat
  carry limit instead
→ inventory.md references a formula that doesn't exist — Blocking
```

```
🔴 过期引用
inventory.md（先编写）：“物品重量使用 movement.md 中的负重公式”
movement.md（后编写）：未定义任何负重公式——改用统一的携带上限
→ inventory.md 引用了一个不存在的公式——阻断级
```

### 2d: Data and Tuning Knob Ownership Conflicts
### 2d：数据与调参旋钮归属冲突

Two GDDs should not both claim to own the same data or tuning knob. Scan all
Tuning Knobs sections across all GDDs and flag duplicates:

两个 GDD 不应同时声称拥有同一份数据或同一个调参旋钮。扫描所有 GDD 中的全部
Tuning Knobs 分区，并标记重复项：

```
⚠️  Ownership Conflict
[system-a].md Tuning Knobs: "[multiplier_name] — controls [output] scaling"
[system-b].md Tuning Knobs: "[multiplier_name] — scales [output] with [factor]"
→ Two GDDs define multipliers on the same output. Which owns the final value?
  This will produce either a double-application bug or a design conflict.
```

```
⚠️  归属冲突
[system-a].md Tuning Knobs："[multiplier_name] —— 控制 [output] 的缩放"
[system-b].md Tuning Knobs："[multiplier_name] —— 以 [factor] 缩放 [output]"
→ 两个 GDD 对同一个输出定义了倍率。最终值归谁所有？
  这要么会产生重复应用类缺陷，要么会产生设计冲突。
```

### 2e: Formula Compatibility
### 2e：公式兼容性

For GDDs whose formulas are connected (output of one feeds input of another),
check that the output range of the upstream formula is within the expected
input range of the downstream formula:

对于公式相互连接的 GDD（一个的输出作为另一个的输入），检查上游公式的输出范围是否落在
下游公式预期的输入范围之内：

- If [system-a].md outputs values between [min]–[max], and [system-b].md is
  designed to receive values between [min2]–[max2], is the mismatch intentional?
- If an economy GDD expects resource acquisition in range X, and the
  progression GDD generates it at range Y, the economy will be trivial or
  inaccessible — is that intended?

- 如果 [system-a].md 输出 [min]–[max] 之间的值，而 [system-b].md 被
  设计为接收 [min2]–[max2] 之间的值，这种不匹配是有意为之吗？
- 如果经济 GDD 期望资源获取量落在范围 X 内，而
  进阶 GDD 按范围 Y 生成，那么经济要么变得毫无挑战，要么
  无法触及——这是有意设计的吗？

Flag incompatibilities as CONCERNS (design judgment needed, not necessarily wrong):

把不兼容情况标记为 CONCERNS（需要设计判断，未必是错的）：

```
⚠️  Formula Range Mismatch
[system-a].md: Max [output] = [value_a] (at max [condition])
[system-b].md: Base [input] = [value_b], max [input] = [value_c]
→ Late-[stage] [scenario] can resolve in a single [event].
  Is this intentional? If not, either [system-a]'s ceiling or [system-b]'s ceiling needs adjustment.
```

```
⚠️  公式范围不匹配
[system-a].md：最大 [output] = [value_a]（在最大 [condition] 时）
[system-b].md：基础 [input] = [value_b]，最大 [input] = [value_c]
→ 后期 [stage] 的 [scenario] 可在单次 [event] 内解决。
  这是有意为之吗？如果不是，则 [system-a] 的上限或 [system-b] 的上限需要调整。
```

### 2f: Acceptance Criteria Cross-Check
### 2f：验收标准交叉核对

Scan Acceptance Criteria sections across all GDDs for contradictions:

扫描所有 GDD 的 Acceptance Criteria 分区，查找矛盾：

- GDD-A criteria: "Player cannot die from a single hit"
- GDD-B criteria: "Boss attack deals 150% of player max health"
These acceptance criteria cannot both pass simultaneously.

- GDD-A 标准：“玩家不能被单次打击致死”
- GDD-B 标准：“Boss 攻击造成玩家最大生命值 150% 的伤害”
这些验收标准无法同时通过。

---
