---
name: balance-check
description: "Find balance outliers, broken progressions, degenerate strategies, economy imbalances in formulas and data. 'Check game balance'."
argument-hint: "[system-name|path-to-data-file]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash(bash "*/.claude/skills/balance-check/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: balance-check
description: "发现公式与数据中的平衡性异常值、断裂的成长曲线、退化策略、经济失衡。'检查游戏平衡性'。"
argument-hint: "[system-name|path-to-data-file]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash(bash "*/.claude/skills/balance-check/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

# Balance Check

# 平衡性检查

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

每一次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（collaborative 总是询问 · guided 仅询问重大事项 · autonomous 记录并继续；
`automation_always_ask` 类目始终提示询问）。

## Insufficient input — check this before producing any report

## 输入不足 — 在生成任何报告前先检查此处

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

**如果此技能所需的输入并不存在，那么答案就是"无法运行"——而不是一份填写完整的报告。**
先检查，若检查不通过即停止。

1. List the inputs this skill reads (data files, prior reports, profiler output,
   test results, registries, source code).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill produces it.

1. 列出此技能读取的输入（数据文件、既有报告、性能分析器输出、
   测试结果、注册表、源代码）。
2. 对每一项记录 `FOUND` 或 `ABSENT`——而不是"假定存在"。
3. 若某章节所需的任一输入为 ABSENT，该章节即为
   **`NOT ASSESSED — NO DATA`**。不要估算它，不要从
   相邻产物推断它，也不要留下一个强制单元格等着下一位
   读取模板的人来填写。
4. 若**每一项**必需的输入都是 ABSENT，则停止，并将
   **`NOT ASSESSED — NO DATA`** 作为整体裁决报告，说明缺失了什么以及
   由哪个技能产出它。

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific: a report whose verdict enum has no "could not run" state produces
**false clean passes** — an asset audit returning COMPLIANT on a project with no
assets and no standards, or a performance profile reporting ">99% headroom against
a 16.67ms budget" with zero profiler data and no budget ever set.

**`NOT ASSESSED` 的裁决是一种成功。** 在没有数据时，它是对
"数据说明了什么？"正确且有价值的回答。它防止的失效模式是
具体的：一个裁决枚举中不存在"无法运行"状态的报告，会产生
**虚假的干净通过**——一次资产审计在没有资产、也没有标准的项目上返回
COMPLIANT，或一份性能分析报告在零性能分析器数据、从未设定预算的情况下
报告"相对 16.67ms 预算有 >99% 的余量"。

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

**证据的缺失永远不是缺失的证据。** 一次因为无文件可扫描而找不到
任何匹配的扫描，并没有验证任何东西。说明二者之中
发生了哪一种——读者无法从一个绿色的结果中分辨。

---

## Phase 1: Identify Balance Domain

## 阶段 1：识别平衡性领域

Determine the balance domain from `$ARGUMENTS` — the whole string, since a data-file path may contain spaces:

从 `$ARGUMENTS` 确定平衡性领域——使用整个字符串，因为数据文件路径可能包含空格：

- **Combat** → weapon/ability DPS, time-to-kill, damage type interactions
- **Economy** → resource faucets/sinks, acquisition rates, item pricing
- **Progression** → XP/power curves, dead zones, power spikes
- **Loot** → rarity distribution, pity timers, inventory pressure
- **File path given** → load that file directly and infer domain from content

- **战斗（Combat）** → 武器/技能 DPS、击杀时间、伤害类型交互
- **经济（Economy）** → 资源来源/消耗、获取速率、物品定价
- **成长（Progression）** → XP/战力曲线、死区、战力尖峰
- **掉落（Loot）** → 稀有度分布、保底计时器、库存压力
- **给出文件路径** → 直接加载该文件并从内容推断领域

If no argument, ask the user which system to check.

若无参数，则询问用户要检查哪个系统。

---

## Phase 2: Read Data Files

## 阶段 2：读取数据文件

Read relevant files from `assets/data/` and `design/balance/` for the identified domain.
Note every file read — they will appear in the Data Sources section of the report.

读取 `assets/data/` 与 `design/balance/` 中与已识别领域相关的文件。
记录每一个读取过的文件——它们将出现在报告的 Data Sources 章节中。

---

## Phase 3: Read Design Document

## 阶段 3：读取设计文档

**Registry first.** If `design/registry/entities.yaml` exists, read it before the
GDD. Its `constants` and `formulas` sections hold the cross-GDD named values and
output ranges — the balance targets — already distilled, each with a `source:`
GDD and any `revised:` date:

**优先查看注册表。** 若 `design/registry/entities.yaml` 存在，应在 GDD 之前
读取它。其 `constants` 与 `formulas` 章节保存着跨 GDD 的命名值和
输出范围——即平衡性目标——且已提炼好，每项都带有 `source:` 所指向的
GDD 以及任何 `revised:` 日期：

```
Grep pattern="^  - name:" path="design/registry/entities.yaml" output_mode="content" -A 6
```

Take the intended values from the registry for any constant or formula it lists
(the `constants:` and `formulas:` blocks); these are the authoritative cross-doc
figures a GDD must not contradict. **If `design/registry/entities.yaml` does not
exist or has no entries** (it ships as an empty stub until `/design-system`
populates it), skip this and use the GDD alone.

对于注册表列出的任何常量或公式（`constants:` 与 `formulas:` 块），从中取其
目标值；这些是权威的跨文档数值，GDD 不得与之矛盾。**若 `design/registry/entities.yaml`
不存在或无条目**（它以空存根形式随附，直到 `/design-system`
填充它），则跳过此步，仅使用 GDD。

Then read the GDD for the system from `design/gdd/` to understand intended design
targets, tuning knobs, and expected value ranges — for anything the registry did
not already supply. This is the baseline for "correct" behaviour. Read it by section:
find the headings you need with the Grep tool (pattern `^#`, content mode) and
Read those ranges with offset and limit.

接着从 `design/gdd/` 读取该系统的 GDD，以理解预期的设计
目标、调参旋钮和期望数值范围——用于注册表尚未提供的任何内容。
这是判断"正确"行为的基线。按章节读取：
用 Grep 工具（模式 `^#`，content 模式）找出所需的标题，再
以 offset 和 limit 读取那些范围。

If the data files are FOUND but neither source gives targets for this domain,
the sections that judge against targets (Outliers Detected, and Progression
Analysis where the domain has a curve) are `NOT ASSESSED — NO DATA`. Each one names what was missing — the
GDD it looked for in `design/gdd/`, and whether the registry was absent or empty
— and names `/design-system`, which writes both.

若数据文件为 FOUND，但两个来源都未给出该领域的目标值，
则那些依据目标评判的章节（Outliers Detected，以及在该领域存在曲线时的
Progression Analysis）为 `NOT ASSESSED — NO DATA`。每一处都说明缺失了什么——它在 `design/gdd/` 中查找的
GDD，以及注册表是不存在还是为空
——并指明 `/design-system`，它负责写出二者。

---

## Phase 4: Perform Analysis

## 阶段 4：执行分析

**Every domain: compare each value with its target.** For each named value in the
data files, take its target from Phase 3 — a registry constant's `value`, a
registry formula's `output_range`, or the range the GDD states — and compare. A
value outside its target is a row in Outliers Detected (`player_damage_base` 140
against 90–110). A value with no target anywhere is neither in range nor an
outlier: list it under Values That Need Attention as `no stated range — not judged`.

**每个领域：将每个值与其目标对比。** 对数据文件中的每个命名值，
从阶段 3 取其目标——注册表常量的 `value`、注册表公式的 `output_range`、
或 GDD 所述的范围——并进行比较。超出其目标的值
是 Outliers Detected 中的一行（`player_damage_base` 为 140，
而目标为 90–110）。任何地方都找不到目标的值既不算在范围内，也不算
异常值：将其列入 Values That Need Attention，标注为 `no stated range — not judged`。

Then run domain-specific checks:

接着运行各领域专属检查：

**Combat balance:**
- Calculate DPS for all weapons/abilities at each power tier
- Check time-to-kill at each tier
- Identify any options that dominate all others (strictly better)
- Check if defensive options can create unkillable states
- Verify damage type/resistance interactions are balanced

**战斗平衡：**
- 计算每个战力层级下所有武器/技能的 DPS
- 检查每个层级的击杀时间
- 找出任何压倒其他所有选项的选项（严格更优）
- 检查防御选项是否会造成无法被击杀的状态
- 验证伤害类型/抗性交互是否平衡

**Economy balance:**
- Map all resource faucets and sinks with flow rates
- Project resource accumulation over time
- Check for infinite resource loops
- Verify gold sinks scale with gold generation
- Check if any items are never worth purchasing

**经济平衡：**
- 梳理所有资源来源与消耗及其流动速率
- 预测资源随时间的累积
- 检查是否存在无限资源循环
- 验证金币消耗是否随金币产出同比缩放
- 检查是否有任何物品从不值得购买

**Progression balance:**
- Plot the XP curve and power curve
- Check for dead zones (no meaningful progression for too long)
- Check for power spikes (sudden jumps in capability)
- Verify content gates align with expected player power
- Check if skip/grind strategies break intended pacing

**成长平衡：**
- 绘制 XP 曲线和战力曲线
- 检查死区（过长时间没有有意义的成长）
- 检查战力尖峰（能力突然跃升）
- 验证内容门禁是否与预期玩家战力对齐
- 检查跳过/刷本策略是否破坏了预期节奏

**Loot balance:**
- Calculate expected time to acquire each rarity tier
- Check pity timer math
- Verify no loot is strictly useless at any stage
- Check inventory pressure vs acquisition rate

**掉落平衡：**
- 计算获取每个稀有度层级的预期时间
- 检查保底计时器的数学
- 验证没有任何掉落在任何阶段是严格无用的
- 检查库存压力与获取速率的对比

---

## Phase 5: Output the Analysis

## 阶段 5：输出分析

```
## Balance Check: [System Name]

### Data Sources Analyzed
- [List of files read]

### Health Summary: [NOT ASSESSED / HEALTHY / CONCERNS / CRITICAL ISSUES]

### Outliers Detected
| Item/Value | Expected Range | Actual | Issue |
|-----------|---------------|--------|-------|

### Degenerate Strategies Found
- [Strategy description and why it is problematic]

### Progression Analysis
[Graph description or table showing progression curve health]

### Recommendations
| Priority | Issue | Suggested Fix | Impact |
|----------|-------|--------------|--------|

### Values That Need Attention
[Specific values with suggested adjustments and rationale]
```

Choose the Health Summary by the worst finding, first match wins:
- **CRITICAL ISSUES** — a degenerate strategy (one choice dominates every
  alternative), a progression that stalls or cannot be completed, or an economy
  loop with no sink
- **CONCERNS** — outliers or curve problems a tuning pass can fix, with no
  finding of the critical kind
- **NOT ASSESSED** — nothing to analyze (the no-data path above), a section that
  needs targets is `NOT ASSESSED — NO DATA`, or a value had no stated range to
  judge it against; name which. It ranks below the two finding verdicts, because
  a measured problem is more actionable than a gap, and above HEALTHY
- **HEALTHY** — every value judged against a stated target, no outliers, no
  degenerate strategies, progression within the stated targets

按最严重的发现来选择 Health Summary，先匹配者胜:
- **CRITICAL ISSUES** — 存在退化策略（某一选择压倒所有
  其他选择）、成长停滞或无法完成、或经济
  循环没有消耗端
- **CONCERNS** — 存在异常值或曲线问题，可通过一次调参修复，且没有
  关键类别的发现
- **NOT ASSESSED** — 无可分析内容（上文的无数据路径）、需要
  目标值的章节为 `NOT ASSESSED — NO DATA`，或某个值没有可据以
  评判的已声明范围；指明是哪一种。它排在两个发现型裁决之下，因为
  已测量的问题比一段空白更可操作，同时排在 HEALTHY 之上
- **HEALTHY** — 每个值都依据已声明的目标评判，无异常值，无
  退化策略，成长处于已声明目标之内

---

## Phase 6: Fix & Verify Cycle

## 阶段 6：修复与验证循环

After presenting the report, use `AskUserQuestion`:
- Prompt: "Balance check complete. What would you like to do next?"
- Options:
  - `[A] Fix highest-priority issue now — walk me through it`
  - `[B] Save report to design/balance/balance-check-[system]-[date].md`
  - `[C] Stop here — I'll review the findings manually`

在呈现报告后，使用 `AskUserQuestion`：
- 提示："平衡性检查完成。接下来你想做什么？"
- 选项：
  - `[A] 现在修复最高优先级的问题 — 带我逐步处理`
  - `[B] 把报告保存到 design/balance/balance-check-[system]-[date].md`
  - `[C] 到此为止 — 我会自己审阅这些发现`

**Run as a subagent?** `game-designer` preloads this skill, and a subagent has
no `AskUserQuestion`. End your reply with the question and these three options
as a short list, and stop: whoever called you asks the user and passes the
answer back.

**作为子智能体运行？** `game-designer` 预加载了此技能，而子智能体
没有 `AskUserQuestion`。在回复末尾以问题加这三个选项
的简短列表结束，然后停止：调用你的一方会去询问用户并把
答案传回。

If [A]:
- Ask which issue to address first (refer to the Recommendations table by priority row)
- Guide the user to update the relevant data file in `assets/data/` or formula in `design/balance/`
- After each fix, offer to re-run the relevant balance checks to verify no new outliers were introduced
- If the fix changes a tuning knob defined in a GDD or referenced by an ADR, remind the user:
  > "This value is defined in a design document. Run `/propagate-design-change [path]` on the affected GDD to find downstream impacts before committing."

若选 [A]：
- 询问先处理哪个问题（按优先级行参考 Recommendations 表格）
- 指导用户更新 `assets/data/` 中相关的数据文件，或 `design/balance/` 中的公式
- 每次修复后，提议重新运行相关的平衡性检查，以验证没有引入新的异常值
- 若该修复改动了 GDD 中定义或被 ADR 引用的调参旋钮，提醒用户：
  > "此值在设计文档中定义。对受影响的 GDD 运行 `/propagate-design-change [path]`，在提交前查找下游影响。"

If [B]:
- Write the report to `design/balance/balance-check-[system]-[date].md` (create the directory if needed). Use the current date for [date] in YYYY-MM-DD format.
- Confirm the file was written, then end with: "Re-run `/balance-check` after fixes to verify."

若选 [B]：
- 将报告写入 `design/balance/balance-check-[system]-[date].md`（如需则创建目录）。用当前日期以 YYYY-MM-DD 格式填入 [date]。
- 确认文件已写入，然后以这句话结束："修复后重新运行 `/balance-check` 以验证。"

If [C]:
- Summarize open issues and end with: "Re-run `/balance-check` after fixes to verify."

若选 [C]：
- 汇总未解决的问题，并以这句话结束："修复后重新运行 `/balance-check` 以验证。"
