# Phase 6: Review gates at review mode full

# 阶段 6：在评审模式 full 下的评审门禁

Read only when the `review_gate` line says `skill-gates=run`. Run both gates before
the Phase 7 report. Each agent reads its own gate file; do not read it here.

仅当 `review_gate` 行写着 `skill-gates=run` 时才读取。在阶段 7 报告之前运行两个门禁。每个智能体读取自己的门禁文件；不要在这里读取它。

## QL-TEST-COVERAGE

## QL-TEST-COVERAGE

Skip it at `qa.level: minimal` (note `QL-TEST-COVERAGE skipped — qa.level minimal`)
and for a Config/Data story (no code tests).

在 `qa.level: minimal` 时跳过它（注明 `QL-TEST-COVERAGE skipped — qa.level minimal`），对于配置/数据类故事（没有代码测试）也跳过。

Hand the review to the `qa-lead` agent with gate **QL-TEST-COVERAGE**. Brief:

将评审交给 `qa-lead` 智能体，门禁为 **QL-TEST-COVERAGE**。简报：

- **Objective:** judge whether the story's tests cover what was specified, not
  only whether the files exist.
- **Give it:** the story path and type; the test files Phase 4 found (exact paths,
  or "none found"); the story's `## QA Test Cases` and `## Acceptance Criteria`;
  the GDD's acceptance criteria and edge cases for the system, or "no GDD for this
  system" (at `workflow: minimal` the story's own criteria are the spec).
- **Return:** ADEQUATE, GAPS, INADEQUATE, or NOT ASSESSED naming a missing input,
  with the gaps listed.
- **Boundaries:** it writes no file.

- **目标：** 判断该故事的测试是否覆盖了所规定的内容，而不仅仅是文件是否存在。
- **提供给它的内容：** 故事路径和类型；阶段 4 找到的测试文件（确切路径，或 "none found"）；故事的 `## QA Test Cases` 和 `## Acceptance Criteria`；该系统的 GDD 验收标准和边缘情况，或 "no GDD for this system"（在 `workflow: minimal` 下，故事自身的标准就是规格）。
- **返回：** ADEQUATE、GAPS、INADEQUATE，或指出缺失输入的 NOT ASSESSED，并列出缺口。
- **边界：** 它不写入任何文件。

Act on the verdict:

根据裁决采取行动：

- **ADEQUATE:** go on.
- **GAPS:** ADVISORY — "QA lead found coverage gaps: [list]. The story can close;
  address them in a follow-up story."
- **INADEQUATE:** BLOCKING — "critical logic is untested: [list]."
- **NOT ASSESSED:** never ADEQUATE. Supply the input and run it again, or carry it
  to the verdict, where it keeps the story at best NOT ASSESSED.

- **ADEQUATE：** 继续。
- **GAPS：** 建议性 —— "QA 负责人发现覆盖缺口：[列表]。该故事可以关闭；在后续故事中解决它们。"
- **INADEQUATE：** 阻断 —— "关键逻辑未经测试：[列表]。"
- **NOT ASSESSED：** 绝不能当作 ADEQUATE。补充输入并再次运行，或将其带到裁决中，在那里它最多让故事保持在 NOT ASSESSED。

## LP-CODE-REVIEW

## LP-CODE-REVIEW

No implementation file yet: skip it, note `LP-CODE-REVIEW skipped — no
implementation files found`, and Reviewed by is `self, no independent review`.

尚无实现文件：跳过它，注明 `LP-CODE-REVIEW skipped — no implementation files found`，Reviewed by 为 `self, no independent review`。

Hand the review to the `lead-programmer` agent with gate **LP-CODE-REVIEW**. Brief:

将评审交给 `lead-programmer` 智能体，门禁为 **LP-CODE-REVIEW**。简报：

- **Objective:** review the story's implementation against its GDD section and
  governing ADR.
- **Give it:** the implementation file paths, the story path, the GDD path and
  section, the ADR path. It reads the GDD and ADR by section, never whole.
- **Return:** APPROVE, CONCERNS, REJECT, or NOT ASSESSED naming a missing input.
- **Boundaries:** it edits no file.

- **目标：** 对照故事的 GDD 章节和管辖 ADR 评审其实现。
- **提供给它的内容：** 实现文件路径、故事路径、GDD 路径和章节、ADR 路径。它按章节读取 GDD 和 ADR，绝不整篇读取。
- **返回：** APPROVE、CONCERNS、REJECT，或指出缺失输入的 NOT ASSESSED。
- **边界：** 它不编辑任何文件。

Act on the verdict:

根据裁决采取行动：

- **APPROVE:** Reviewed by is `lead-programmer`.
- **CONCERNS:** ask: "The lead programmer raised concerns. How do you want to go
  on?" Options: Revise the flagged issues / Accept and go on / Discuss further.
- **REJECT:** no COMPLETE verdict until the issues are fixed.
- **NOT ASSESSED:** never APPROVE. Supply the input and run it again, or carry it
  to the verdict, where it keeps the story at best NOT ASSESSED.

- **APPROVE：** Reviewed by 为 `lead-programmer`。
- **CONCERNS：** 询问："主程序员提出了顾虑。你想如何继续？"选项：修订被标记的问题 / 接受并继续 / 进一步讨论。
- **REJECT：** 在问题修复之前不能有 COMPLETE 裁决。
- **NOT ASSESSED：** 绝不能当作 APPROVE。补充输入并再次运行，或将其带到裁决中，在那里它最多让故事保持在 NOT ASSESSED。
