# Phase 8: The next story when a sprint plan exists

Read only when `production/sprints/` holds a sprint plan.

1. Read the newest sprint plan in `production/sprints/`.
2. Find the stories that are Ready or Not Started, not waiting on an unfinished
   story, and in the Must Have or Should Have tier.

```
### Next Up
The following stories are ready to pick up:
1. [Story name] — [one line] — Est: [estimate]
2. [Story name] — [one line] — Est: [estimate]

Run `/story-readiness [path]` to confirm a story is ready before starting.
```

**Every Must Have story Complete or Blocked:** print the close-out sequence.

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

**No story ready, Must Have stories still In Progress:** "No more stories ready to
start — [N] Must Have stories still in progress. Finish those before the sprint
close-out."

The checkpoint's **Next step** names the same story or step the user is shown.
