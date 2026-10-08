# /story-done — Phase 8: Surface the Next Story

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 8: Surface the Next Story

**In this file:**

- No sprint plan — the minimal path
- With a sprint plan

After completion, help the developer keep momentum. Which branch applies depends
on whether there is a sprint at all.

### No sprint plan — the minimal path

**At `workflow: minimal`, or whenever `production/sprints/` holds no sprint
plan, there is no sprint to close out.** The brief's build order is the plan and
the story files carry it:

1. Run `bash .claude/scripts/story-status.sh`, from the project root — after
   Phase 7's story-file write, so this story's new status is in it. It prints
   every unfinished story under `production/epics/`, whatever Status form its
   file uses, **already in the route's order** — `IN_REVIEW`, then `IN_PROGRESS`, then `TODO` (a `Ready` or
   `Not Started` story) in build (file-name) order — then `BLOCKED`, `OTHER`,
   `NO_STATUS` and the `COMPLETE` count. It is the list `/help` and
   `/sprint-status` read, so the three name the same next story; do not re-read
   or re-rank the story files.
2. The first `In Review` story is next (recommend `/story-done [path]` for it —
   its work is written, and closing it first keeps finished work from piling
   up); else the first `In Progress` one; else the first `Ready` or
   `Not Started` one — the story on the script's first `IN_REVIEW`,
   `IN_PROGRESS` or `TODO` line. Name any `Blocked` story with its blocker and pass
   over it.

   ```
   ### Next Up
   **[Story NNN: title]** — [1-line description]
   Run `/story-done [path]` to close it (In Review) — else `/dev-story [path]` to implement it.
   ```

   At `minimal` recommend `/dev-story` directly (or `/story-done` for an In Review
   story) — `/story-readiness` is not on
   the minimal path (engine → brief → stories → code), and it checks fields the
   minimal story template does not carry. With no sprint plan at a higher tier,
   add the `/story-readiness [path]` line from the sprint branch below.
3. **No unfinished story — only `COMPLETE N of N`** → every story is built —
   at `minimal`, the brief's build order is done. Say so, and offer three ways on:
   - play the build and note what feels wrong
   - add the next stories from the brief with `/create-stories`
   - if the game has outgrown a one-page brief, `/settings` to raise `modes.rigor`
4. **No `IN_REVIEW`, `IN_PROGRESS` or `TODO` line, but `BLOCKED`, `OTHER` or
   `NO_STATUS` lines remain** — every unfinished story is `Blocked`, `Draft`, or
   has no status line. There is no Next Up, and the
   build order is **not** done — never say it is. Name each such story with its
   blocker (or `Draft` / `no status`), and suggest clearing the blocker first. For
   a Draft or unstatused story: at `minimal`, finish it and set its Status to
   `Ready`; at a higher tier, `/story-readiness [path]` shows what it still needs.

**Never print the Sprint Close-Out Sequence on this branch** (`/smoke-check
sprint`, `/team-qa sprint`, `/retrospective`, `/gate-check`, `/sprint-plan new`)
— it closes a sprint, and there is none. Each of those still runs if the user
asks for it; do not present them as required.

### With a sprint plan

1. Read the current sprint plan from `production/sprints/`.
2. Find stories that are:
   - Status: READY or NOT STARTED
   - Not blocked by other incomplete stories
   - In the Must Have or Should Have tier

Present:

```
### Next Up
The following stories are ready to pick up:
1. [Story name] — [1-line description] — Est: [X hrs]
2. [Story name] — [1-line description] — Est: [X hrs]

Run `/story-readiness [path]` to confirm a story is implementation-ready
before starting.
```

If no more Must Have stories remain in this sprint (all are Complete or Blocked):

```
### Sprint Close-Out Sequence

All Must Have stories are complete. QA sign-off is required before advancing.
Run these in order:

1. `/smoke-check sprint` — verify the critical path still works end-to-end
2. `/team-qa sprint` — full QA cycle: test case execution, bug triage, sign-off report
3. `/retrospective` — capture what went well, what didn't, and action items for the next sprint
4. `/gate-check` — advance to the next phase once QA approves (only if advancing a phase)
5. `/sprint-plan new` — plan the next sprint, incorporating velocity data and retrospective action items

Do not run `/gate-check` until `/team-qa` returns APPROVED or APPROVED WITH CONDITIONS.
```

If there are Should Have stories still unstarted, surface them alongside the close-out sequence so the user can choose: close the sprint now, or pull in more work first.

If no more stories are ready but Must Have stories are still In Progress (not Complete):
"No more stories ready to start — [N] Must Have stories still in progress. Continue implementing those before sprint close-out."

---
