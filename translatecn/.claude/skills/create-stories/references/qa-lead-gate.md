# Phase 5: QA lead review (QL-STORY-READY)

# 阶段 5：QA 负责人评审（QL-STORY-READY）

Read only when the `review_gate` line says `skill-gates=run` (`review_mode: full`).
Run it after the stories are drafted and before the Phase 6 write ask.

仅当 `review_gate` 行写着 `skill-gates=run`（`review_mode: full`）时才读取。在故事起草完成之后、阶段 6 的写入询问之前运行它。

**An existing QA plan first.** Look for the newest `production/qa/qa-plan-*.md`. If
its Automated Tests Required section holds specs for stories in this epic (match by
title or slug), they can stand in for the agent's specs. Where the two differ, ask:
"Which test specs should these stories carry?" Options: The QA plan's / The QA
lead's / None yet. "None yet" writes
`*Test cases not yet defined — run /qa-plan to generate them.*` This never adds a
second hand-off.

**先看现有 QA 计划。** 查找最新的 `production/qa/qa-plan-*.md`。如果它的 Automated Tests Required 章节包含该史诗中故事的规格（按标题或 slug 匹配），它们可以替代智能体给出的规格。两者不同之处，询问："这些故事应携带哪些测试规格？"选项：QA 计划的 / QA 负责人的 / 暂无。选"暂无"则写入 `*Test cases not yet defined — run /qa-plan to generate them.*`。这绝不额外增加第二次交接。

**Hand the review to the `qa-lead` agent, once,** with gate **QL-STORY-READY**. The
agent reads its own gate file; do not read it here. One report carries both the
verdicts and the specs: never hand it a second job for the specs.

**将评审交给 `qa-lead` 智能体，仅一次，** 门禁为 **QL-STORY-READY**。该智能体读取自己的门禁文件；不要在这里读取它。一份报告同时承载裁决和规格：绝不要为规格再交给它第二项任务。

Brief:
- **Objective:** judge each drafted story's acceptance criteria for testability, and
  write test specs for the ones that pass.
- **Give it:** the full story list inline (no story file exists yet, so the stories
  stand in for the gate's paths), each with its acceptance criteria, type, and
  TR-IDs with their requirement text from `tr-registry.yaml`; and the epic GDD's
  acceptance criteria for reference.
- **Return:** per story, ADEQUATE, GAPS, INADEQUATE, or NOT ASSESSED naming a
  missing input. For each ADEQUATE story, its spec block in the formats below: one
  Given/When/Then per criterion for Logic and Integration, manual steps for
  Visual/Feel and UI.
- **Boundaries:** it writes no file.

简报：
- **目标：** 判断每个已起草故事的验收标准是否可测试，并为通过的那些编写测试规格。
- **提供给它的内容：** 内联的完整故事列表（尚不存在故事文件，因此这些故事代替门禁的路径），每个都带有验收标准、类型，以及 TR-ID 及其来自 `tr-registry.yaml` 的需求文本；还有史诗 GDD 的验收标准供参考。
- **返回：** 对每个故事给出 ADEQUATE、GAPS、INADEQUATE，或指出缺失输入的 NOT ASSESSED。对于每个 ADEQUATE 的故事，按下面的格式给出其规格块：Logic 和 Integration 每个标准一条 Given/When/Then，Visual/Feel 和 UI 给出手动步骤。
- **边界：** 它不写入任何文件。

Act on each story's verdict:

根据每个故事的裁决采取行动：

- **ADEQUATE:** keep its specs.
- **GAPS:** ask: "How do you want to handle the flagged criteria?" Options: Revise
  them / Accept and go on / Discuss further. Revise nothing before the answer. On
  Revise: draft the new criteria, show them, and send just those stories back to
  the agent in one follow-up brief. On Accept: the criteria stay, and the story's
  QA Test Cases read `*Test cases not yet defined — run /qa-plan to generate them.*`
- **INADEQUATE:** the story is not written as it stands. Revise its criteria with
  the user (draft, show, confirm), then ask the agent for its specs. If the user
  will not revise it, drop it from this run and name it as dropped in the Phase 6
  list.
- **NOT ASSESSED:** not an ADEQUATE. Name the missing input, then supply it and ask
  again, or write the story without specs (the `/qa-plan` line) and mark it
  `QL-STORY-READY: NOT ASSESSED — [input]` in the Phase 6 list.

- **ADEQUATE：** 保留其规格。
- **GAPS：** 询问："你想如何处理被标记的标准？"选项：修订它们 / 接受并继续 / 进一步讨论。在得到回答之前不要做任何修订。若选修订：起草新标准，展示它们，并在一次后续简报中只把这些故事发回给智能体。若选接受：标准保持不变，故事的 QA Test Cases 读作 `*Test cases not yet defined — run /qa-plan to generate them.*`
- **INADEQUATE：** 该故事不能按现状写入。与用户一起修订其标准（起草、展示、确认），然后向智能体索取规格。如果用户不愿修订，将其从本次运行中移除，并在阶段 6 列表中说明它已被移除。
- **NOT ASSESSED：** 不等于 ADEQUATE。指出缺失的输入，然后补充它并再次询问；或在不带规格的情况下写入故事（`/qa-plan` 那一行），并在阶段 6 列表中将其标记为 `QL-STORY-READY: NOT ASSESSED — [input]`。

A story carries specs only once it is ADEQUATE: untestable criteria cannot be built
correctly. The specs go in the story's `## QA Test Cases`; the user builds
against them and does not invent new ones.

故事只有在达到 ADEQUATE 后才携带规格：不可测试的标准无法被正确构建。规格放入故事的 `## QA Test Cases`；用户依据它们进行构建，而不是自行发明新的。

Logic and Integration:

Logic 和 Integration：

```
Test: [criterion text]
  Given: [precondition]
  When: [action]
  Then: [expected result]
  Edge cases: [boundary values or failure states]
```

Visual/Feel and UI:

Visual/Feel 和 UI：

```
Manual check: [criterion text]
  Setup: [how to reach the state]
  Verify: [what to look for]
  Pass condition: [an unambiguous pass]
```
