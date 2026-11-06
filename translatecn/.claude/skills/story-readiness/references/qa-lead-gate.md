# Phase 5: QA lead review (QL-STORY-READY)

# 阶段 5：QA 负责人评审（QL-STORY-READY）

Read only when the `review_gate` line says `skill-gates=run` (`review_mode: full`).

仅当 `review_gate` 行写着 `skill-gates=run`（`review_mode: full`）时才读取。

Hand the review to the `qa-lead` agent, once per story, with gate
**QL-STORY-READY**. The agent reads its own gate file; do not read it here.

将评审交给 `qa-lead` 智能体，每个故事一次，门禁为 **QL-STORY-READY**。该智能体读取自己的门禁文件；不要在这里读取它。

Brief:
- **Objective:** judge whether this story's acceptance criteria are testable enough
  to implement against.
- **Give it:** the story path; its type (Logic / Integration / Visual/Feel / UI /
  Config/Data), which the gate branches on; every acceptance criterion, verbatim;
  the requirement it covers (TR-ID and text); each dependency and its state
  (exists, Draft, missing); this run's verdict.
- **Return:** ADEQUATE, GAPS with the list, INADEQUATE with the list, or NOT
  ASSESSED naming the missing input.
- **Boundaries:** it reads the story and the files the brief names; it edits
  nothing.

简报：
- **目标：** 判断该故事的验收标准是否足够可测试，以便据此实现。
- **提供给它的内容：** 故事路径；其类型（Logic / Integration / Visual/Feel / UI / Config/Data），门禁据此分支；每一条验收标准，逐字提供；它所覆盖的需求（TR-ID 和文本）；每个依赖及其状态（存在、Draft、缺失）；本次运行的裁决。
- **返回：** ADEQUATE、带列表的 GAPS、带列表的 INADEQUATE，或指出缺失输入的 NOT ASSESSED。
- **边界：** 它读取故事和简报指明的文件；它不编辑任何内容。

Act on its report:

根据其报告采取行动：

- **ADEQUATE**: the story is cleared.
- **GAPS**: show the gaps, then ask: "How do you want to handle these?" Options:
  Draft the fixes / Accept and go on / Discuss further.
- **INADEQUATE**: the story is not READY. The verdict becomes at least NEEDS WORK
  (BLOCKED stays BLOCKED). List the gaps, restate the verdict, then ask whether to
  draft fixes or go on anyway. If the user goes on, the verdict stays and the
  report says "proceeding despite QL-STORY-READY: INADEQUATE (user override)".
  Never a silent READY.
- **NOT ASSESSED**: the gate judged nothing; never read it as ADEQUATE. Name the
  missing input and offer to supply it and run the gate again. Otherwise a READY
  verdict becomes NOT ASSESSED; NEEDS WORK and BLOCKED stand.

- **ADEQUATE**：该故事已通过。
- **GAPS**：展示缺口，然后询问："你想如何处理这些？"选项：起草修复 / 接受并继续 / 进一步讨论。
- **INADEQUATE**：该故事不是 READY。裁决至少变为 NEEDS WORK（BLOCKED 保持 BLOCKED）。列出缺口，重述裁决，然后询问是起草修复还是照旧继续。如果用户选择继续，裁决保持不变，报告写明 "proceeding despite QL-STORY-READY: INADEQUATE (user override)"。绝不静默地标记为 READY。
- **NOT ASSESSED**：该门禁没有做出任何判断；绝不要把它读作 ADEQUATE。指出缺失的输入，并提供补充它、再次运行门禁的选项。否则，READY 裁决变为 NOT ASSESSED；NEEDS WORK 和 BLOCKED 保持不变。
