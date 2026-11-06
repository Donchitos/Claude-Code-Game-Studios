# Phase 8: The next story when a sprint plan exists

# 阶段 8：存在冲刺计划时的下一个故事

Read only when `production/sprints/` holds a sprint plan.

仅当 `production/sprints/` 中存在冲刺计划时才读取。

1. Read the newest sprint plan in `production/sprints/`.
2. Find the stories that are Ready or Not Started, not waiting on an unfinished
   story, and in the Must Have or Should Have tier.

1. 读取 `production/sprints/` 中最新的冲刺计划。
2. 找出处于 Ready 或 Not Started、不等待任何未完成故事、且属于 Must Have 或 Should Have 层级的故事。

```
### Next Up
The following stories are ready to pick up:
1. [Story name] — [one line] — Est: [estimate]
2. [Story name] — [one line] — Est: [estimate]

Run `/story-readiness [path]` to confirm a story is ready before starting.
```

**Every Must Have story Complete or Blocked:** print the close-out sequence.

**每个 Must Have 故事都已完成或受阻：** 打印收尾序列。

```
### Sprint Close-Out Sequence
All Must Have stories are complete. QA sign-off is required before advancing.
1. `/smoke-check sprint` — the critical path still works end to end
2. `/team-qa sprint` — test case execution, bug triage, sign-off report
3. `/retrospective` — what went well, what didn't, action items
4. `/gate-check` — only when advancing a stage, after `/team-qa` returns
   APPROVED or APPROVED WITH CONDITIONS
5. `/sprint-plan new` — the next sprint
```

Should Have stories still unstarted: list them beside the sequence, so the user can
close the sprint now or pull in more work.

Should Have 故事仍未开始：将它们列在序列旁边，以便用户现在关闭冲刺或拉入更多工作。

**No story ready, Must Have stories still In Progress:** "No more stories ready to
start — [N] Must Have stories still in progress. Finish those before the sprint
close-out."

**没有故事就绪，Must Have 故事仍为进行中：** "没有更多可以开始的故事 —— [N] 个 Must Have 故事仍在进行中。在冲刺收尾之前完成它们。"

The checkpoint's **Next step** names the same story or step the user is shown.

检查点的 **Next step** 指出的，与向用户展示的是同一个故事或步骤。
