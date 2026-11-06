# /gate-check — Section 2b: Workflow Tier Adjustment

# /gate-check — 第 2b 节：工作流层级调整

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/gate-check`。`SKILL.md` 指明了何时读取本文件；它已解析的设置，以及其后各标题下的规则，在此处仍然适用。

## 2b. Workflow Tier Adjustment

## 2b. 工作流层级调整

**In this file:**

**本文件包括：**

- How to apply a gate file's tier reductions
- `qa.level` and the test items; the smoke check is the floor
- A gate with no required artifacts left is NOT ASSESSED, with one exception
- `performance.enforce`
- Per-system overrides (`workflow_overrides.system_overrides`), and the additive overrides

- 如何应用门禁文件的层级削减
- `qa.level` 与测试项；冒烟检查是下限
- 一个已无必需产物的门禁属于 NOT ASSESSED，但有一个例外
- `performance.enforce`
- 按系统覆盖（`workflow_overrides.system_overrides`），以及叠加式覆盖

Each gate file carries its own tier reductions (see Section 2). Two rules apply
across all of them:

每个门禁文件都自带层级削减（见第 2 节）。以下两条规则适用于全部门禁文件：

> **How to apply:** run the loaded gate's checklist, then apply that file's tier
> reduction for the tier resolved in Section 1. **drop** = not checked at this
> tier; **→ recommended** = absent surfaces as CONCERNS, never a Blocker; items
> not named keep their baseline status. Reductions only ever *relax* a
> requirement — the only thing that adds one is `workflow_overrides` (below).
>
> **`qa.level` (Section 1) further relaxes the test items independently of the
> tier:** at `qa.level: minimal` the test-evidence / unit-test items become
> non-required at every workflow tier (so even `workflow: full` does not require
> them); the Section 3 `testing.strict` check is then a no-op.
>
> **It relaxes tests, not the look.** A UI story's retained screenshots, and a
> Visual/Feel story's screenshots plus lead sign-off, are required at every
> `qa.level` wherever the gate file asks for story evidence
> (`.claude/docs/coding-standards.md`: tests are waived at `minimal`, the look
> is not).
>
> **The smoke check is excluded from that relaxation, and is the floor.**
> `qa.level` relaxes *per-story test evidence*; a smoke check is **build health**,
> not story evidence, and the two are already held apart on exactly this basis in
> `.claude/docs/coding-standards.md` ("`/smoke-check` is a build-health gate, not
> a per-story evidence gate ... This divergence is intentional"). So a gate file
> that requires a smoke report keeps requiring it at every `qa.level`.
>
> Without that exclusion the Production → Polish gate would have **zero
> required artifacts at `rigor: minimal`** and could not fail on artifacts by
> construction: `minimal` reduces the gate to the smoke check alone, `qa.level`
> would then drop the smoke check too, and one `modes.rigor` setting fires both.

> **如何应用：** 先运行已加载门禁的检查清单，然后应用该文件对第 1 节所解析层级的层级削减。**drop（丢弃）** = 在此层级不检查；**→ recommended（转为建议）** = 缺失时呈现为 CONCERNS，绝不为 Blocker；未被点名的项目保持其基线状态。削减只会 *放松* 要求 —— 唯一会新增要求的是 `workflow_overrides`（见下文）。
>
> **`qa.level`（第 1 节）会在层级之外进一步放松测试项：** 在 `qa.level: minimal` 下，测试证据 / 单元测试项在每个工作流层级都变为非必需（因此即便 `workflow: full` 也不要求它们）；第 3 节的 `testing.strict` 检查此时成为空操作。
>
> **它放松的是测试，不是观感。** UI 故事保留的截图，以及 Visual/Feel 故事的截图加主管签核，在每个 `qa.level` 下，只要门禁文件要求故事证据，就都必须提供（`.claude/docs/coding-standards.md`：测试在 `minimal` 下可豁免，观感不可）。
>
> **冒烟检查不受该放松影响，它就是下限。** `qa.level` 放松的是 *按故事的测试证据*；冒烟检查是**构建健康**，不是故事证据，二者在 `.claude/docs/coding-standards.md` 中正是基于这一点被分开的（"`/smoke-check` 是构建健康门禁，不是按故事证据门禁……这一差异是有意为之"）。因此，要求冒烟报告的门禁文件在每个 `qa.level` 下都继续要求它。
>
> 若没有这一排除，Production → Polish 门禁在 `rigor: minimal` 下将**没有任何必需产物**，从构造上就不可能因产物而失败：`minimal` 把门禁削减到只剩冒烟检查，`qa.level` 又会把冒烟检查也丢掉，而这两者由同一个 `modes.rigor` 设置同时触发。

> **A gate with no required artifacts left must say so, and may not return
> PASS.** After applying the tier reduction and the `qa.level` relaxation, count
> what remains required. If the count is zero, report
> **NOT ASSESSED** naming both reducers and the gate — *"Production → Polish at
> `workflow: minimal` + `qa.level: minimal` leaves no required artifact; this
> gate verified nothing"* — rather than a PASS earned by having nothing to check.
> Per `.claude/rules/skill-authoring.md` obligation 1, a run that could not
> assess its scope has not established that the scope is good, and obligation 3
> requires the emptiness to be visible in the output rather than inferable from
> a silent green.
>
> **The one exception: a gate its tier reference file marks "not applicable" at
> this tier** (Systems Design → Technical Setup at `workflow: minimal`). That is
> not a gate with nothing left to check but a transition the tier does not have:
> it PASSes with that file's note, printed in the report. The director panel
> does not run for it — note "Director Panel skipped — gate not applicable at
> `workflow: [tier]`" — and the Section 6 stage write still asks first.

> **一个已无必需产物的门禁必须说明这一点，且不得返回 PASS。** 在应用层级削减和 `qa.level` 放松之后，统计还剩哪些是必需的。若计数为零，则报告 **NOT ASSESSED**，并同时点名两个削减来源与该门禁——*"Production → Polish 在 `workflow: minimal` + `qa.level: minimal` 下没有任何必需产物；此门禁未验证任何内容"*——而不是给出一个因无物可查而获得的 PASS。依据 `.claude/rules/skill-authoring.md` 的义务 1，一次无法评估其范围的运行并未证明该范围是好的；义务 3 要求这种空无必须显现在输出中，而不能只能从一片沉默的绿色中推断。
>
> **唯一的例外：某一门禁被其层级参考文件标记为在"此层级不适用"**（Systems Design → Technical Setup 在 `workflow: minimal` 下）。那不是"无物可查"的门禁，而是该层级并不存在的过渡：它带着该文件的说明 PASS，并在报告中打印出来。导演小组不会为它运行——注明"Director Panel skipped — gate not applicable at `workflow: [tier]`"——而第 6 节的阶段写入仍然会先征询问。

> **`performance.enforce` is likewise independent of the tier, and a tier
> reduction never suppresses it.** The performance check in Section 3 runs at
> every workflow tier, and `block` makes a breach a Blocker at every workflow
> tier. Do **not** read a gate file's *"everything else drops"* as dropping it:
> `off` is the only thing that makes budgets informational, and it is a
> deliberate choice the user makes on the same key.
>
> This matters most on a `rigor: minimal` project: the Polish gate's `minimal`
> reduction drops everything outside its floor, and "Performance is within
> budget" sits in that dropped remainder. Run the check anyway.

> **`performance.enforce` 同样与层级无关，层级削减永远不会抑制它。** 第 3 节的性能检查在每个工作流层级都运行，而 `block` 会让任何越界在每个工作流层级都成为 Blocker。**不要** 把门禁文件中的 *"其余全部丢弃"* 解读为把它也丢弃了：只有 `off` 会让预算变为仅作参考，而那是用户在同一键上做出的有意选择。
>
> 这一点在 `rigor: minimal` 项目上最为要紧：Polish 门禁的 `minimal` 削减会丢弃其下限之外的一切，而"Performance is within budget"正落在被丢弃的剩余项中。无论如何都要运行该检查。

### Per-system overrides (`workflow_overrides.system_overrides`)

### 按系统覆盖（`workflow_overrides.system_overrides`）

Independent of the project-level tier above, and applied **only** on the gates
that validate MVP GDDs (Systems Design → Technical Setup, and the GDD-completeness
checks at Pre-Production → Production). For each system, resolve its effective
tier:

与上述项目级层级相互独立，且**仅**应用于验证 MVP GDD 的门禁（Systems Design → Technical Setup，以及 Pre-Production → Production 处的 GDD 完整性检查）。对每个系统，解析其有效层级：

1. If the block's `system_overrides` lists `<system>` → that tier
2. Else the project-level `workflow`

1. 若该配置块的 `system_overrides` 列出了 `<system>` → 使用该层级
2. 否则使用项目级的 `workflow`

**Before applying any of them, check the block the other way round: does every
KEY match a system?** `<system>` is the GDD filename stem
(`.claude/docs/workflow-modes.md`), so for each key in `system_overrides`, look
for `design/gdd/<key>.md`. Any key with no matching stem is reported, naming the
key and listing the stems that do exist:

**在应用其中任何一项之前，先反过来检查该配置块：每个 KEY 都能匹配到一个系统吗？** `<system>` 是 GDD 文件名的词干（`.claude/docs/workflow-modes.md`），因此对 `system_overrides` 中的每个键，查找 `design/gdd/<key>.md`。任何找不到匹配词干的键都要报告出来，点名该键并列出确实存在的词干：

> `system_overrides key 'no-such-system' matches no GDD in design/gdd/. Available stems: combat, inventory, forge-heat-system. This override is doing nothing.`

> `system_overrides key 'no-such-system' matches no GDD in design/gdd/. Available stems: combat, inventory, forge-heat-system. This override is doing nothing.`（`system_overrides` 中的键 'no-such-system' 在 design/gdd/ 中匹配不到任何 GDD。可用词干：combat、inventory、forge-heat-system。此覆盖未起任何作用。）

Surface it as a **CONCERNS**-level finding, not a Blocker — the project is still
gateable, but an override the user believes is in force and is not is exactly how
a documented escape hatch silently stops working.

将其作为 **CONCERNS** 级别的发现呈现，而非 Blocker——项目仍然可以通过门禁，但一个用户以为生效、实际却未生效的覆盖，正是文档化的逃生口悄悄失灵的方式。

This is the rule in `.claude/docs/workflow-modes.md`: a key that matches no
system is an error, not a no-op. The story skills resolve only in the system →
override direction, so an orphan key is invisible to them; `/gate-check`, which
resolves the whole block, is where it is caught.

这就是 `.claude/docs/workflow-modes.md` 中的规则：匹配不到任何系统的键是错误，不是空操作。故事类技能只按系统 → 覆盖的方向解析，因此孤立键对它们是不可见的；而 `/gate-check` 会解析整个配置块，正是它捕获了这类问题。

Validate each GDD against its own effective tier's section count:

按每个 GDD 自身有效层级的章节数量来校验它：

- A system pinned **higher** than the project (e.g. `system_overrides.combat:
  full` on a `standard` project) **blocks the gate** until that system's GDD
  meets the higher bar (combat → all 8 sections). This is the one case where a
  per-system setting makes the gate *stricter* than the project tier.
- A system pinned **lower** (e.g. `inventory: minimal`) relaxes only that system
  — its GDD is checked at the lower tier; every other system stays at the project
  level. A system pinned **`minimal` imposes no GDD section requirement at all**
  (`minimal` = "game brief replaces GDDs" — `.claude/docs/workflow-modes.md`): it
  never blocks the gate on a missing or incomplete GDD. Do not invent an
  "acceptance-criteria-only" floor for it — there is none.

- 一个被钉在**高于**项目的层级上的系统（例如在 `standard` 项目上设置 `system_overrides.combat: full`）会**阻塞门禁**，直到该系统的 GDD 达到更高的标准（combat → 全部 8 个章节）。这是按系统设置使门禁比项目层级*更严格*的唯一情形。
- 一个被钉在**较低**层级的系统（例如 `inventory: minimal`）只会放松该系统——其 GDD 按较低层级检查；其他所有系统仍保持项目级。一个被钉在 **`minimal`** 的系统**完全不施加 GDD 章节要求**（`minimal` = "游戏简报取代 GDD"——`.claude/docs/workflow-modes.md`）：它绝不会因 GDD 缺失或不完整而阻塞门禁。不要为它臆造一个"仅验收标准"的下限——并不存在这样的下限。

> **Additive overrides (the only things that make the gate stricter).**
> - `workflow_overrides.art_bible_strict: true` forces the complete (9-section)
>   art bible at the Technical Setup → Pre-Production and Pre-Production →
>   Production gates regardless of tier or whether visual-asset stories exist.
> - `workflow_overrides.edge_cases: true` and `workflow_overrides.tuning_knobs:
>   true` force those GDD sections required when validating GDD completeness,
>   additive on top of the resolved tier (e.g. at `standard`, `tuning_knobs: true`
>   makes the otherwise-optional Tuning Knobs section blocking). These never
>   relax — a `false` value is the default/no-op, never a way to drop a section
>   the tier already requires.

> **叠加式覆盖（唯一会让门禁更严格的东西）。**
> - `workflow_overrides.art_bible_strict: true` 会在 Technical Setup → Pre-Production 和 Pre-Production → Production 门禁强制要求完整的（9 章节）美术圣经，无论层级如何，也无论是否存在视觉资产业务的故事。
> - `workflow_overrides.edge_cases: true` 和 `workflow_overrides.tuning_knobs: true` 在验证 GDD 完整性时强制要求那些 GDD 章节，叠加在已解析层级之上（例如在 `standard` 下，`tuning_knobs: true` 会让原本可选的 Tuning Knobs 章节变为阻塞项）。它们永远不会放松——`false` 值是默认值 / 空操作，绝不是用来丢弃层级本已要求的章节的手段。

---
