# /gate-check — Sections 5 and 5a: Verdict and Chain-of-Verification

# /gate-check — 第 5 与 5a 节：裁定与验证链

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/gate-check`。`SKILL.md` 指明了何时读取本文件；它已解析的设置，以及其后各标题下的规则，在此处仍然适用。

## 5. Output the Verdict

## 5. 输出裁定

**In this file:**

**本文件包括：**

- 5. Output the Verdict: the report, `NOT ASSESSED`, verdict precedence
- 5a. Chain-of-Verification: Steps 1-4

- 5. 输出裁定：报告、`NOT ASSESSED`、裁定优先级
- 5a. 验证链：步骤 1–4

```
## Gate Check: [Current Phase] → [Target Phase]

**Date**: [date]
**Checked by**: gate-check skill

### Required Artifacts: [X/Y present]
- [x] design/gdd/game-concept.md (design/game-brief.md at `minimal`) — exists, 2.4KB
- [ ] docs/architecture/ — MISSING (no ADRs found)
- [x] production/sprints/ — exists, 1 sprint plan

### Quality Checks: [X/Y passing]
- [x] GDD has 8/8 required sections
- [ ] Tests — FAILED (3 failures in tests/unit/)
- [?] Core loop playtested — MANUAL CHECK NEEDED

### Blockers
1. **No Architecture Decision Records** — Run `/architecture-decision` to create one
   covering core system architecture before entering production.
2. **3 test failures** — Fix failing tests in tests/unit/ before advancing.

### Recommendations
- [Priority actions to resolve blockers]
- [Optional improvements that aren't blocking]

### Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]
- **PASS**: All required artifacts present, all quality checks passing
- **CONCERNS**: Minor gaps exist but can be addressed during the next phase —
  the stage advances only if the user explicitly accepts them (Section 6)
- **FAIL**: Critical blockers must be resolved before advancing
- **NOT ASSESSED**: One or more required checks could not be run at all — name
  which, and why, in the Blockers section

### Accepted Risks (only when the user advanced on CONCERNS)
- [each concern, as listed above] — accepted by the user, [date]
```

```
## Gate Check: [Current Phase] → [Target Phase]

**Date**: [date]
**Checked by**: gate-check skill

### Required Artifacts: [X/Y present]
- [x] design/gdd/game-concept.md (design/game-brief.md at `minimal`) — exists, 2.4KB
- [ ] docs/architecture/ — MISSING (no ADRs found)
- [x] production/sprints/ — exists, 1 sprint plan

### Quality Checks: [X/Y passing]
- [x] GDD has 8/8 required sections
- [ ] Tests — FAILED (3 failures in tests/unit/)
- [?] Core loop playtested — MANUAL CHECK NEEDED

### Blockers
1. **No Architecture Decision Records** — Run `/architecture-decision` to create one
   covering core system architecture before entering production.
2. **3 test failures** — Fix failing tests in tests/unit/ before advancing.

### Recommendations
- [Priority actions to resolve blockers]
- [Optional improvements that aren't blocking]

### Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]
- **PASS**: All required artifacts present, all quality checks passing
- **CONCERNS**: Minor gaps exist but can be addressed during the next phase —
  the stage advances only if the user explicitly accepts them (Section 6)
- **FAIL**: Critical blockers must be resolved before advancing
- **NOT ASSESSED**: One or more required checks could not be run at all — name
  which, and why, in the Blockers section

### Accepted Risks (only when the user advanced on CONCERNS)
- [each concern, as listed above] — accepted by the user, [date]
```

（模板内容对应：门禁检查报告；Required Artifacts 必需产物；Quality Checks 质量检查；Blockers 阻塞项；Recommendations 建议；Verdict 裁定；Accepted Risks 已接受风险；MANUAL CHECK NEEDED 需要人工检查；PASS 通过、CONCERNS 有顾虑、FAIL 不通过、NOT ASSESSED 无法评估。）

**`NOT ASSESSED` — when the gate could not look.** Rank: it **outranks PASS**
(a gate that could not check part of its scope has not established the phase is
ready) and **ranks below CONCERNS and FAIL** (a known blocker is more actionable
than an unknown, and demoting it behind an access problem buries it). It is not a
softer FAIL: "I checked and found a blocker" and "I could not check" need
different fixes — one needs work done, the other needs the input produced or made
readable.

**`NOT ASSESSED`——当门禁无法查看时。** 级别：它**高于 PASS**（一个无法检查其部分范围的门禁，并未证明该阶段已就绪），并且**低于 CONCERNS 与 FAIL**（已知的阻塞项比未知更可操作，而把它降格到访问问题之后会将其掩埋）。它不是更软弱的 FAIL："我检查了并发现了阻塞项"与"我无法检查"需要不同的修复——前者需要完成工作，后者需要产出输入或让其可读。

**Verdict precedence — first matching rule wins**, evaluated in this order:
**FAIL**, then **CONCERNS**, then **NOT ASSESSED**, then **PASS**. A gate with
both a real blocker and an unassessable check is FAIL: the blocker is the
actionable finding. A CONCERNS verdict with an unassessable check still names
that check under Blockers, as NOT ASSESSED with its reason: it is what keeps the
stage from advancing (Section 6), so a reader must see it next to the concerns.

**裁定优先级——首个匹配的规则胜出**，按以下顺序评估：**FAIL**，然后 **CONCERNS**，然后 **NOT ASSESSED**，然后 **PASS**。一个既有真实阻塞项又有无法评估检查的门禁为 FAIL：阻塞项是可操作的发现。一个含无法评估检查的 CONCERNS 裁定，仍会在 Blockers 之下点名该检查，标为 NOT ASSESSED 并附原因：正是它阻止了阶段推进（第 6 节），因此读者必须在顾虑旁边看到它。

Emit it when any of:

在以下任一情形下输出它：

- A **required artifact exists but cannot be assessed** — empty, unreadable, or
  still entirely `[TO BE CONFIGURED]` / template placeholders. Present-but-empty
  is the case that most looks like present.
- A **quality check's input carries no measured data**. Section 3 compares the
  performance budgets against "profiling data in `tests/performance/` or recent
  `/perf-profile` output" — and `/perf-profile`'s report template pre-fills
  `[16.67ms]` as the budget, so it can render ">99% headroom" from zero profiler
  data. Placeholder numbers are not measurements: a budget nobody set is not a
  budget that was met. Absent data already prompts (Section 4 offers to run
  `/perf-profile`); this covers data that is *present and hollow*, which is the
  case that looks like a measurement.
- A **test check the tier requires could not be executed** — no test runner is
  configured, or the runner is configured but failed to start. Section 3 runs the
  suite "if a test runner is configured", and an unconfigured runner produced no
  failures, so the test check contributed nothing to the verdict and the gate
  could still reach PASS. Meanwhile `testing.strict.logic` and
  `.integration` both default to `true`, so the project's own configuration
  called those gates BLOCKING. A blocking gate that never ran is the unknown this
  verdict exists to name. Remediation is already listed under Section 8's follow-up actions
  (`/test-setup`); this is what the verdict does with it.

  > **Scope this to tiers that require tests.** At `qa.level: minimal` no test
  > gates apply at all (see the config block above), so a missing runner there is
  > the configured posture, not a hole — firing the trigger would make every
  > `minimal` gate permanently NOT ASSESSED and stop stage advancement, the same
  > over-broad reading the director trigger below warns against. Fires only where
  > the resolved tier actually asked for the test check.
- A **`MANUAL CHECK NEEDED` item the user never resolved**. Section 4 already
  refuses to assume PASS for unverifiable items and marks them this way, and an
  unresolved one lands here, never inside PASS, CONCERNS or FAIL.
- A director the **resolved tier was supposed to spawn** did not return — it
  errored, produced no verdict, or was interrupted.

- 一个**必需产物存在但无法评估**——空、不可读，或仍完全是 `[TO BE CONFIGURED]` / 模板占位符。"存在但为空"是最像"存在"的那种情形。
- 一项**质量检查的输入不含任何测量数据**。第 3 节将性能预算与"`tests/performance/` 中的剖析数据或近期 `/perf-profile` 输出"相比较——而 `/perf-profile` 的报告模板会把 `[16.67ms]` 预填为预算，因此它能在零剖析数据的情况下渲染出 ">99% headroom"。占位数字不是测量值：没人设定过的预算不是被满足了的预算。数据缺失本已会触发提示（第 4 节提议运行 `/perf-profile`）；此条覆盖的是那些*存在却空洞*的数据，正是那看起来像测量值的情形。
- 一项**层级所要求的测试检查无法执行**——未配置测试运行器，或运行器已配置但启动失败。第 3 节"若配置了测试运行器"才运行套件，而未配置的运行器没有产生任何失败，因此测试检查对裁定毫无贡献，门禁仍可能达到 PASS。与此同时 `testing.strict.logic` 与 `.integration` 默认均为 `true`，所以项目自身的配置把这些门禁称作 BLOCKING。一个从未运行的阻塞性门禁，正是此裁定所要指出的未知项。补救措施已在第 8 节的后续行动下列出（`/test-setup`）；此裁定就是对其作出的处理。

  > **将其限定在要求测试的层级。** 在 `qa.level: minimal` 下完全不适用测试门禁（见上文配置块），因此那里缺少运行器是配置使然的姿态，而不是漏洞——触发该条件会让每个 `minimal` 门禁永久为 NOT ASSESSED 并阻止阶段推进，这正与下文导演触发条件所警告的过度宽泛解读相同。仅在已解析层级确实要求测试检查时才触发。
- 一个**用户从未了结的 `MANUAL CHECK NEEDED` 项**。第 4 节已拒绝对无法核验的项目假定 PASS 并如此标记它们，而未了结的一项就落在这里，绝不在 PASS、CONCERNS 或 FAIL 之内。
- 一个**已解析层级本应生成**的导演没有返回——它报错、未产出裁定，或被中断。

  > **Scope this narrowly, and do not read it as "fewer than four directors ran".**
  > Section 4b narrows the panel *by design* — 1 director at `minimal`, 2 at
  > `standard`, 4 at `full`, and none in `solo` — and that narrowing is a
  > deliberate, announced reduction, not a failure to assess. The broad reading
  > makes every `minimal`, `standard` and `solo` gate permanently NOT ASSESSED,
  > which means the verdict can never be PASS and Section 6 can never advance
  > `project.stage`. **That would break stage advancement for most projects,**
  > since those are the common tiers. The trigger fires only when a director the
  > tier *did* call for fails to come back — a hole in the panel you expected,
  > never the panel you deliberately chose.

  > **要狭义地限定它，不要把它读作"运行中的导演少于四个"。** 第 4b 节是*按设计*收窄小组的——`minimal` 下 1 位导演、`standard` 下 2 位、`full` 下 4 位、`solo` 下无——这种收窄是有意且已声明的削减，不是评估失败。宽泛解读会让每个 `minimal`、`standard` 与 `solo` 门禁永久为 NOT ASSESSED，这意味着裁定永远不可能为 PASS、第 6 节永远无法推进 `project.stage`。**那会破坏大多数项目的阶段推进，** 因为这些正是常见的层级。该触发条件仅在层级*确实*要求的一位导演未能返回时才触发——那是你所预期小组中的缺口，而绝不是你刻意选择的小组。
- A referenced upstream verdict is itself `NOT ASSESSED` — it propagates upward
  rather than resolving to a pass.

- 一个被引用的上游裁定本身为 `NOT ASSESSED`——它会向上传播，而不会被化解为通过。

Never resolve an unknown by assuming the permissive reading. If the check could
not run, that fact is the finding.

绝不要通过假定从宽解读来化解未知。如果检查无法运行，那个事实本身就是发现。

---

## 5a. Chain-of-Verification

## 5a. 验证链

After drafting the verdict in Phase 5, challenge it before finalising.

在第 5 阶段草拟裁定之后、定稿之前，先对它提出挑战。

**Step 1 — Generate 5 challenge questions** designed to disprove the verdict:

**步骤 1——生成 5 个挑战性问题**，旨在证伪该裁定：

> **Tool-action requirement**: At least 2 of the 5 challenge questions below must be answered by re-reading a specific file (Read tool) or re-running a specific check (Grep tool) — not by reflection alone. Mark these with [TOOL ACTION] to indicate a tool was used.

> **工具操作要求**：以下 5 个挑战性问题中，至少 2 个必须通过重读特定文件（Read 工具）或重跑特定检查（Grep 工具）来回答——不能仅凭反思。用 [TOOL ACTION] 标记这些，以表明使用了工具。

For a **PASS** draft:
- "Which quality checks did I verify by actually reading a file, vs. inferring they passed?"
- "Are there MANUAL CHECK NEEDED items I marked PASS without user confirmation? [TOOL ACTION] Re-scan the checklist for any [?] or MANUAL CHECK items."
- "Did I confirm all listed artifacts have real content, not just empty headers? [TOOL ACTION] Re-read the file and check it has non-placeholder content."
- "Could any blocker I dismissed as minor actually prevent the phase from succeeding?"
- "Which single check am I least confident in, and why?"

针对 **PASS** 草稿：
- "哪些质量检查我是通过实际读取文件来核验的，哪些只是推断它们通过了？"
- "有没有我未经用户确认就标为 PASS 的 MANUAL CHECK NEEDED 项？[TOOL ACTION] 重新扫描检查清单，找出任何 [?] 或 MANUAL CHECK 项。"
- "我是否确认了所有列出的产物都有真实内容，而不只是空标题？[TOOL ACTION] 重读该文件并检查其内容不是占位符。"
- "任何被我当作小问题而驳回的阻塞项，是否实际上会妨碍该阶段成功？"
- "我最不确信的单项检查是哪个，为什么？"

For a **CONCERNS** draft:
- "Could any listed CONCERN be elevated to a blocker given the project's current state?"
- "Is the concern resolvable within the next phase, or does it compound over time?"
- "Did I soften any FAIL condition into a CONCERN to avoid a harder verdict?"
- "Are there artifacts I didn't check that could reveal additional blockers?"
- "Do all the CONCERNS together create a blocking problem even if each is minor alone?"

针对 **CONCERNS** 草稿：
- "鉴于项目当前状态，所列的任何 CONCERN 是否应升级为阻塞项？"
- "该顾虑能在下一阶段内解决，还是会随时间累积加重？"
- "我是否把任何 FAIL 条件软化成了 CONCERN，以回避更严厉的裁定？"
- "有没有我未检查、却可能揭示更多阻塞项的产物？"
- "所有 CONCERNS 合在一起是否构成阻塞性问题，即便每一个单独看都很轻微？"

For a **FAIL** draft:
- "Have I accurately separated hard blockers from strong recommendations?"
- "Are there any PASS items I was too lenient about?"
- "Am I missing any additional blockers the user should know about?"
- "Can I provide a minimal path to PASS — the specific 3 things that must change?"
- "Is the fail condition resolvable, or does it indicate a deeper design problem?"

针对 **FAIL** 草稿：
- "我是否准确地区分了硬性阻塞项与强烈建议？"
- "有没有我过于宽松地判为 PASS 的项目？"
- "我是否遗漏了用户应当知道的额外阻塞项？"
- "我能否给出一条通往 PASS 的最小路径——必须改变的具体 3 件事？"
- "该失败条件可解决吗，还是它表明存在更深层的设计问题？"

**Step 2 — Answer each question** independently.
Do NOT reference the draft verdict text — re-check specific files or ask the user.

**步骤 2——独立回答每个问题。** 不要引用草稿裁定的文字——重新检查特定文件或询问用户。

**Step 3 — Revise if needed:**
- If any answer reveals a missed blocker → upgrade verdict (PASS→CONCERNS or CONCERNS→FAIL)
- If any answer reveals a check that **could not be run** rather than one that
  ran and passed → PASS→NOT ASSESSED. The first two PASS-draft questions above
  ("verified by actually reading a file, vs. inferring", "MANUAL CHECK NEEDED
  items I marked PASS") exist to find exactly this, and a yes to either moves
  the verdict here
- If any answer reveals an over-stated blocker → downgrade only if citing specific evidence
- Never revise NOT ASSESSED down to PASS by re-reasoning about the missing input.
  Only obtaining the input clears it
- If answers are consistent → confirm verdict unchanged

**步骤 3——按需修订：**
- 若任何回答揭示了一个被遗漏的阻塞项 → 升级裁定（PASS→CONCERNS 或 CONCERNS→FAIL）
- 若任何回答揭示的是一项**无法运行**的检查，而非已运行且通过的检查 → PASS→NOT ASSESSED。上文针对 PASS 草稿的前两个问题（"通过实际读取文件核验，还是推断"、"我标为 PASS 的 MANUAL CHECK NEEDED 项"）正是为了找出这一点，对任一回答为"是"都会把裁定移到这里
- 若任何回答揭示了一个被夸大的阻塞项 → 仅在引用具体证据时才降级
- 绝不要通过重新推理缺失输入而把 NOT ASSESSED 修订为 PASS。只有取得该输入才能解除它
- 若各回答相互一致 → 确认裁定不变

**Step 4 — Note the verification** in the final report output:
`Chain-of-Verification: [N] questions checked — verdict [unchanged | revised from X to Y]`

**步骤 4——在最终报告输出中注明验证**：
`Chain-of-Verification: [N] questions checked — verdict [unchanged | revised from X to Y]`

---
