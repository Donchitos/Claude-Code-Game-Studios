# Phase 4: Producer review (PR-EPIC)

# 阶段 4：制作人评审（PR-EPIC）

Read only when the `review_gate` line says `skill-gates=run` (`review_mode: full`).
Run it once every epic in scope is defined and before any write. The agent reads its
own gate file; do not read it here.

仅当 `review_gate` 行写着 `skill-gates=run`（`review_mode: full`）时才读取。在范围内每个史诗都定义完成之后、任何写入之前运行它。该智能体读取自己的门禁文件；不要在这里读取它。

Hand the review to the `producer` agent with gate **PR-EPIC**. Brief:

将评审交给 `producer` 智能体，门禁为 **PR-EPIC**。简报：

- **Objective:** judge whether the epic structure for this layer is realistic to
  deliver.
- **Give it:** every epic defined in Phase 3 with its scope summary and governing
  ADR count, the layer being processed, the milestone timeline and the team's
  capacity (from `production/milestones/` and `project.yaml`'s `team.size`, or
  "none recorded").
- **Return:** REALISTIC, CONCERNS, UNREALISTIC, or NOT ASSESSED naming a missing
  input, with reasons.
- **Boundaries:** it writes no file.

- **目标：** 判断该层级的史诗结构是否现实可交付。
- **提供给它的内容：** 阶段 3 中定义的每个史诗及其范围摘要和管辖 ADR 数量、正在处理的层级、里程碑时间线和团队产能（来自 `production/milestones/` 和 `project.yaml` 的 `team.size`，或 "none recorded"）。
- **返回：** REALISTIC、CONCERNS、UNREALISTIC，或指出缺失输入的 NOT ASSESSED，并附上理由。
- **边界：** 它不写入任何文件。

Act on the verdict:

根据裁决采取行动：

- **REALISTIC:** go to Phase 5.
- **CONCERNS:** ask "The producer raised concerns about the epic structure. How do
  you want to go on?" Options: Go on as planned — I accept the concerns / Revise the
  epic boundaries / Stop — I want to rethink the scope. Revise: change the epics,
  show them again, and run the review again. Stop: `Verdict: BLOCKED — user is
  rethinking the epic scope`.
- **UNREALISTIC:** offer to split overscoped epics or merge underscoped ones,
  show the revised epics, and run the review again before writing.
- **NOT ASSESSED:** it is not REALISTIC. Name what was missing, then supply it and
  run it again; or, when the user chooses to go on without it, go to Phase 5 and
  state `PR-EPIC: NOT ASSESSED — [input]` in the reply and the closing block.

- **REALISTIC：** 进入阶段 5。
- **CONCERNS：** 询问"制作人对史诗结构提出了顾虑。你想如何继续？"选项：按计划继续 —— 我接受这些顾虑 / 修订史诗边界 / 停止 —— 我想重新考虑范围。若选修订：修改史诗，再次展示，并再次运行评审。若选停止：`Verdict: BLOCKED — user is rethinking the epic scope`。
- **UNREALISTIC：** 提供拆分范围过大的史诗或合并范围过小的史诗的选项，展示修订后的史诗，并在写入之前再次运行评审。
- **NOT ASSESSED：** 不等于 REALISTIC。指出缺失了什么，然后补充它并再次运行；或者当用户选择在其他情况下继续时，进入阶段 5，并在回复和结尾块中声明 `PR-EPIC: NOT ASSESSED — [input]`。

Write no epic until the review resolves.

在评审得到解决之前，不要写入任何史诗。
