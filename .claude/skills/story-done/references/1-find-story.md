# /story-done — Phase 1: Find the Story

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 1: Find the Story

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Workflow tier**: resolved per the story's system (per
`.claude/docs/workflow-modes.md`) — **the GDD filename stem** of the story's
`GDD:` path (`design/gdd/<stem>.md` → `<stem>`), with the `[system]` segment of
its `TR-[system]-NNN` ID accepted only as a fallback alias: use the
`system_overrides` row for that system if the block lists one, else the
project value. It governs which Phase 4 deviation checks run — see Phase 4.

**Workflow companion — `modes.story_granularity`** (resolved above — supplied by
`modes.rigor` unless set explicitly): cadence expectation only — story-done fires **every 3–5 days** at
`coarse`, **every 1–2 days** at `balanced`, **multiple times/day** at `fine`. It
does not change any completion check.

**`qa.level`**: controls whether test *evidence is required*, where
`testing.strict` controls whether a failure blocks and `workflow` controls which
docs exist. `modes.rigor` sets `qa.level` and `workflow` together; set either
explicitly to vary it alone. `testing.strict` is not fronted by `rigor` at all.
At `minimal`, no *test* evidence is required → skip the Logic, Integration and
Config/Data evidence checks (Phase 3), the >50%-untested traceability escalation,
and the Phase 4b QA gate; the acceptance-criteria verification still runs, and so
do the Visual/Feel and UI screenshot gate and the `Run result:` check for other
story types — the look is never waived. At
`standard`, the story's own type requires evidence; at `full`, every type does.
`testing.strict` then decides whether present-but-failing evidence blocks.
(`rigor: minimal` sets both; `qa.level: minimal` on its own leaves the workflow
tier where it was.)

**If a file path is provided** (e.g., `/story-done production/epics/core/story-damage-calculator.md`):
read that file directly.

**If no argument is provided:**

1. Check `production/session-state/active.md` for the currently active story.
2. If not found there, read the most recent file in `production/sprints/` and
   look for stories marked IN PROGRESS.
3. If multiple in-progress stories are found, use `AskUserQuestion`:
   - "Which story are we completing?"
   - Options: list the in-progress story file names.
4. If no story can be found, ask the user to provide the path.

---
