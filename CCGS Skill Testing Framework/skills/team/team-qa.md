# Skill Test Spec: /team-qa

## Skill Summary

Orchestrates the QA team through a 6-phase structured testing cycle. Coordinates
qa-lead (strategy, smoke check assessment, sign-off report) and qa-tester (test case
writing, bug report writing). Phase 1 loads scope (sprint file, `feature:` form, or
inferred from session state) and the project stage; Phase 2 classifies stories and
takes the smoke check verdict from the latest `production/qa/smoke-*.md` report
(UNKNOWN when none exists; NOT ASSESSED when the report says so — both continue
with a warning and rule out APPROVED; FAIL stops the cycle); at `qa.level:
minimal`, where tests are waived, a Logic, Integration or Config/Data story
without a test is WAIVED and its evidence is the acceptance-criteria walk in
manual QA; Phase 3 writes the QA plan after
asking; Phase 4 spawns qa-tester with a named output path per manual-QA story —
one spawn per story in parallel at `team.size: studio`, one for the whole group
below it; Phase 5 walks manual QA, files bugs, has the tester retain screenshots
and writes evidence artifacts after asking; Phase 6 produces a sign-off report,
with a row for every story in scope, and a NOT ASSESSED / APPROVED / APPROVED WITH
CONDITIONS / NOT APPROVED verdict. Phase 0 resolves `team.size` and the skill announces the
active set before Phase 1. The orchestrator-level verdict is COMPLETE or BLOCKED.

---

## Static Assertions (Structural)

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings (Phase 1 through Phase 6)
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains sign-off verdict keywords: NOT ASSESSED, APPROVED, APPROVED WITH CONDITIONS, NOT APPROVED
- [ ] Contains "May I write" language for every orchestrator write: the QA plan (Phase 3), the evidence artifacts (Phase 5) and the sign-off report (Phase 6)
- [ ] Has an Error Recovery Protocol section
- [ ] Uses `AskUserQuestion` at phase transitions to capture user approval before proceeding
- [ ] Phase 2 takes the smoke verdict from the most recent `production/qa/smoke-*.md` report, and a FAIL stops the cycle before Phase 3
- [ ] Phase 4 names each qa-tester's output path: `production/qa/test-cases/[story-slug]-cases.md`
- [ ] Bug reports are written to `production/qa/bugs/` with `BUG-[NNNN].md` naming — `/bug-report`'s numbering, so `/bug-report verify` finds them
- [ ] Visual/Feel and UI stories that pass get a retained screenshot of each screen or effect touched under `production/qa/evidence/[story-slug]/`, confirmed on disk, and an evidence artifact at `production/qa/evidence/[story-slug]-evidence.md` that references it — the screenshot closes a UI story; a Visual/Feel story also needs the lead sign-off
- [ ] Next-step guidance differs by verdict (NOT ASSESSED / APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED)
- [ ] Phase 0 resolves `team.size`, and the skill requires a one-line active-set announcement before Phase 1
- [ ] Phase 0 resolves `qa.level`; at `minimal` a Logic, Integration or Config/Data story without a test gets its acceptance criteria walked in Phase 4–5 — tests WAIVED, never counted as missing evidence
- [ ] The Phase 2 smoke verdict list includes NOT ASSESSED, which continues with a warning like UNKNOWN and makes the sign-off NOT ASSESSED
- [ ] Phase 1 reads the Open bugs in scope from `production/qa/bugs/` (open unless `Closed` or `Verified Fixed`) and passes them into the Phase 2 and Phase 6 briefs
- [ ] The Phase 6 brief carries the evidence and the verdict rules and names no verdict; the orchestrator checks the qa-lead's verdict against the rules before writing
- [ ] Phase 4 spawns one qa-tester per story, in parallel, at `team.size: studio`; at `small` and `individual` one qa-tester spawn covers the whole group
- [ ] The Phase 6 sign-off gives every story in scope a Test Coverage Summary row — BLOCKED and unexecuted stories included — and its template shows a BLOCKED row

---

## Test Cases

### Case 1: Happy Path — All stories pass manual QA, APPROVED verdict

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`
- `production/sprints/sprint-03.md` lists 4 stories whose story files exist
- Stories are a mix of types: 1 Logic (its unit test exists and passes), 1 Integration (no automated test), 2 Visual/Feel
- All stories have acceptance criteria populated
- The most recent `production/qa/smoke-[date].md` report has verdict PASS
- `production/qa/bugs/` contains no bugs

**Input:** `/team-qa sprint-03`

**Expected behavior:**
1. Before any spawn, one line announces the active set for `team.size: small`
2. Phase 1: Globs `production/sprints/sprint-*.md`, matches sprint number 3 (`sprint-03.md`) and reads it; reads `project.stage` from `project.yaml` (fallback `production/stage.txt`); reads the open bugs in scope (none on file); reports "QA cycle starting for sprint-03. Found 4 stories. Open bugs in scope: none on file. Current stage: [stage]. Ready to begin QA strategy?"
3. Phase 2: Spawns `qa-lead` via Agent; classifies all 4 stories in the strategy table; reads the smoke report and records `Smoke Check: PASS — source: production/qa/smoke-[date].md` without re-interviewing the user; presents the strategy; `AskUserQuestion` "QA Strategy Review": user selects "Looks good — proceed to test plan"
4. Phase 3: Produces QA plan (scope, classification table, automated/manual scope, entry and exit criteria); asks "May I write the QA plan to `production/qa/qa-plan-sprint-03-[date].md`?"; writes after approval
5. Phase 4: Spawns one `qa-tester` via Agent for the Integration and both Visual/Feel stories (per-story parallel spawns are the `studio` shape), its prompt naming `production/qa/test-cases/[story-slug]-cases.md` for each story; test cases presented grouped by story; `AskUserQuestion` per group; user approves
6. Phase 5: `AskUserQuestion` per story (PASS / PASS WITH NOTES / FAIL / BLOCKED); user marks all as PASS; for each Visual/Feel story the tester saves a screenshot under `production/qa/evidence/[story-slug]/` and the orchestrator confirms it is on disk; after "May I write the evidence for [story titles] to `production/qa/evidence/`?" it writes `production/qa/evidence/[story-slug]-evidence.md`, referencing the screenshots, with sign-off rows left unchecked unless signed off in this session; result summary: "Stories PASS: 4, PASS WITH NOTES: 0, FAIL: 0, BLOCKED: 0"
7. Phase 6: Spawns `qa-lead` via Agent to produce sign-off report; every story has executed evidence; no bugs filed; Verdict: APPROVED; asks "May I write this QA sign-off report to `production/qa/qa-signoff-sprint-03-[date].md`?"; writes after approval
8. Verdict: COMPLETE — QA cycle finished

**Assertions:**
- [ ] Active-set line naming `team.size: small` appears before the first agent is spawned
- [ ] Phase 1 correctly counts and reports 4 stories with current stage
- [ ] Strategy table in Phase 2 classifies all 4 stories with correct types
- [ ] Smoke check verdict is taken from the existing `production/qa/smoke-*.md` report and its source is shown
- [ ] QA plan written only after "May I write?" approval
- [ ] Phase 4 spawns a single qa-tester at `team.size: small`, and its prompt names each story's `production/qa/test-cases/` path
- [ ] Each passing Visual/Feel story has a retained screenshot on disk under `production/qa/evidence/[story-slug]/`, and its evidence artifact references it and is written only after the "May I write" ask
- [ ] Sign-off report includes Test Coverage Summary table and Verdict: APPROVED
- [ ] Sign-off report written only after "May I write?" approval
- [ ] Verdict: COMPLETE appears in final output
- [ ] Next step: "Run `/gate-check` to validate advancement."

---

### Case 2: Smoke Check Fail — QA cycle stops at Phase 2

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`
- `production/sprints/sprint-04.md` lists 3 stories
- The most recent `production/qa/smoke-[date].md` report has verdict FAIL with 2 listed failures (build unstable on launch, core navigation broken)

**Input:** `/team-qa sprint-04`

**Expected behavior:**
1. Phase 1 completes normally
2. Phase 2: Spawns `qa-lead` via Agent; qa-lead reads the smoke report and records `Smoke Check: FAIL` with both failures listed prominently
3. `AskUserQuestion` "QA Strategy Review" is presented, including the option "Smoke check failed — fix issues and re-run /team-qa"
4. Skill does not proceed to Phase 3: it surfaces the failures from the smoke report and stops — the user must fix them, re-run `/smoke-check sprint`, and then re-run `/team-qa`
5. No QA plan, test cases, manual QA or sign-off report is produced; a partial report is given
6. Verdict: BLOCKED — smoke check failed

**Assertions:**
- [ ] Smoke check verdict comes from the `production/qa/smoke-*.md` report — qa-lead does not re-derive it or re-interview the user
- [ ] Smoke check FAIL halts the pipeline at Phase 2 — Phases 3, 4, 5, 6 are NOT executed
- [ ] Failure list is shown to the user explicitly (not summarized vaguely)
- [ ] Skill recommends `/smoke-check sprint` and a `/team-qa` re-run as remediation steps
- [ ] No QA plan and no QA sign-off report is written or offered
- [ ] Orchestrator verdict is BLOCKED, not COMPLETE

---

### Case 3: Bug Found — Visual/Feel story fails manual QA, bug report filed

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`
- `production/sprints/sprint-05.md` lists 2 stories: 1 Logic (its automated test passes), 1 Visual/Feel
- The most recent `production/qa/smoke-[date].md` report has verdict PASS
- The Visual/Feel story's animation timing is visibly wrong (acceptance criterion not met)
- `production/qa/bugs/` already contains `BUG-0001.md` and `BUG-0002.md`

**Input:** `/team-qa sprint-05`

**Expected behavior:**
1. Phases 1–4 complete normally; test cases are written for the Visual/Feel story
2. Phase 5: User marks Visual/Feel story as FAIL; `AskUserQuestion` collects failure description: "Animation plays at 2x speed — jitter visible on every loop"
3. Phase 5: Spawns `qa-tester` via Agent to write a formal bug report at `production/qa/bugs/BUG-0003.md`; report includes severity field
4. Result summary: "Stories PASS: 1, PASS WITH NOTES: 0, FAIL: 1 — bugs filed: BUG-0003, BLOCKED: 0"
5. Phase 6: Spawns `qa-lead` to produce sign-off report; every story has executed evidence; Bugs Found table lists BUG-0003 with story, severity and status Open; Verdict: NOT APPROVED (a story FAILed without documented workaround)
6. Sign-off report write is offered; writes after approval
7. Next step: "Resolve S1/S2 bugs and re-run `/team-qa` or targeted manual QA before advancing."

**Assertions:**
- [ ] FAIL result in Phase 5 triggers `AskUserQuestion` to collect the failure description before the bug report is written
- [ ] `qa-tester` is spawned via Agent to write the bug report — orchestrator does not write it directly
- [ ] Bug report follows `/bug-report`'s naming: `BUG-[NNNN].md` in `production/qa/bugs/`
- [ ] The ID is one past the highest existing bug, zero-padded to four digits (BUG-0003)
- [ ] Phase 6 sign-off report Bugs Found table includes the bug ID, story name, severity, and status
- [ ] Verdict in sign-off report is NOT APPROVED
- [ ] Next step explicitly mentions re-running `/team-qa`
- [ ] Verdict: COMPLETE is still issued by the orchestrator (the QA cycle finished — the sign-off verdict is NOT APPROVED, but the skill completed its pipeline)

---

### Case 4: No Argument — Skill infers active sprint or asks user

**Fixture (variant A — state files present):**
- `production/session-state/active.md` exists and contains a reference to `sprint-06`
- `production/sprint-status.yaml` exists and identifies `sprint-06` as active
- `production/sprints/sprint-06.md` exists

**Fixture (variant B — no sprint, as at `rigor: minimal`):**
- `production/session-state/active.md` does NOT exist
- `production/sprint-status.yaml` does NOT exist
- No sprint files exist; epics exist under `production/epics/`

**Input:** `/team-qa` (no argument)

**Expected behavior (variant A):**
1. Phase 1: No argument provided; reads `production/session-state/active.md` and `production/sprint-status.yaml`
2. Detects `sprint-06` as the active sprint
3. Proceeds as if `/team-qa sprint-06` was the input; the Phase 1 report line names it: "QA cycle starting for sprint-06. Found [N] stories. Open bugs in scope: [N or none on file]. Current stage: [stage]. Ready to begin QA strategy?"

**Expected behavior (variant B):**
1. Phase 1: No argument provided; attempts to read both state files — both missing; no sprint exists
2. Asks the user which epic to cover, then scopes the run as `feature: [epic-slug]` — it does not invent a sprint

**Assertions:**
- [ ] Skill does NOT default to a hardcoded sprint name when no argument is provided
- [ ] Skill reads both `production/session-state/active.md` AND `production/sprint-status.yaml` before asking the user (variant A)
- [ ] When no sprint can be inferred, skill asks which epic to cover and uses the `feature: [epic-slug]` form rather than guessing (variant B)
- [ ] The inferred sprint is named in the Phase 1 report line before Phase 2 begins (variant A)
- [ ] Skill does NOT error out when state files are missing — it falls back to asking (variant B)

---

### Case 5: Mixed Results — Some PASS, one FAIL with S1 bug, one BLOCKED

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`
- `production/sprints/sprint-07.md` lists 4 stories
- The most recent `production/qa/smoke-[date].md` report has verdict PASS
- Story A (Logic): automated test passes — PASS
- Story B (UI): manual QA — PASS WITH NOTES (minor text overflow)
- Story C (Visual/Feel): manual QA — FAIL; tester identifies S1 crash on ability activation
- Story D (Integration): cannot test — BLOCKED (dependency system not yet implemented)
- `production/qa/bugs/` is empty

**Input:** `/team-qa sprint-07`

**Expected behavior:**
1. Phases 1–4 proceed; Phase 4 test cases cover stories B, C, D
2. Phase 5: Story A is PASS from its automated test; user marks Story B: PASS WITH NOTES; Story C: FAIL; Story D: BLOCKED
3. Story B (UI) gets a retained screenshot of each screen it touched, saved by the tester under `production/qa/evidence/[story-slug]/` and confirmed on disk; its evidence artifact at `production/qa/evidence/[story-slug]-evidence.md` references them and is written only after the "May I write" ask
4. After Story C FAIL: failure description collected; qa-tester spawned to write bug report `BUG-0001.md` with S1 severity
5. Result summary presented: "Stories PASS: 1, PASS WITH NOTES: 1, FAIL: 1 — bugs filed: BUG-0001, BLOCKED: 1"
6. Phase 6: qa-lead produces sign-off report covering all 4 stories; BUG-0001 listed as S1/Open; Story D listed as BLOCKED with no executed evidence; Verdict: NOT APPROVED — the open S1 is a known failure and is reported as such, not demoted to NOT ASSESSED by the unexecuted Story D
7. Sign-off report written after "May I write?" approval
8. Next step: "Resolve S1/S2 bugs and re-run `/team-qa` or targeted manual QA before advancing."

**Assertions:**
- [ ] All 4 stories appear in the Phase 6 sign-off report Test Coverage Summary table — none are silently omitted
- [ ] Story D (BLOCKED) is listed in the report with a BLOCKED status and named as lacking executed evidence, not silently dropped
- [ ] S1 bug causes Verdict: NOT APPROVED regardless of the other stories passing, and regardless of Story D being unexecuted
- [ ] PASS WITH NOTES stories do not downgrade to FAIL — they are tracked separately
- [ ] Story B's evidence is its retained screenshots — a UI story needs no lead sign-off to close
- [ ] BUG-0001 severity is listed as S1 in the Bugs Found table
- [ ] Partial results are preserved — the sign-off report is still produced even with failures and blocks
- [ ] Verdict: COMPLETE is issued by the orchestrator (pipeline completed); sign-off verdict is NOT APPROVED

---

### Case 6: `qa.level: minimal` — a Logic story with no test is evidenced by its acceptance-criteria walk

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`, `qa.level: minimal (rigor:minimal)`
- No sprint files and no `production/sprint-status.yaml`; `production/epics/combat/` holds 2 story files, both `In Review`: story-001 (Logic, no test file anywhere) and story-002 (UI)
- The most recent `production/qa/smoke-[date].md` report has verdict PASS (its automated row WAIVED)
- `production/qa/bugs/` contains no bugs

**Input:** `/team-qa feature: combat`

**Expected behavior:**
1. Phase 2: qa-lead's strategy table marks story-001's Automated Required as `WAIVED` — tests are waived at `qa.level: minimal` — and puts it in manual QA; it is not flagged as missing test evidence or as a blocker
2. Phase 3: the QA plan lists no automated test requirements; its entry criteria take the stories' status from the story files (feature scope), not from `production/sprint-status.yaml`
3. Phase 4: test cases are written for both stories — story-001's walk its acceptance criteria
4. Phase 5: the tester answers PASS for both; story-002's retained screenshot is saved and confirmed on disk
5. Phase 6: the Test Coverage Summary shows story-001 as `WAIVED (qa.level: minimal)` under Auto Test with its criteria walked; every story has executed evidence, so the verdict is APPROVED

**Assertions:**
- [ ] story-001 is never reported as missing its test, and its acceptance-criteria walk is its executed evidence
- [ ] The sign-off verdict is APPROVED, not NOT ASSESSED
- [ ] The UI story still needs its retained screenshot — `qa.level: minimal` waives tests, not the look
- [ ] Entry criteria at `feature:` scope read the story files' Status, not `production/sprint-status.yaml`
- [ ] No next step tells the user to write Logic tests

---

### Case 7: Smoke report NOT ASSESSED — continue with a warning, sign-off NOT ASSESSED

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`, `qa.level: standard`
- `production/sprints/sprint-008.md` lists 2 stories: 1 Logic (its unit test exists and passes) and 1 Visual/Feel
- The most recent `production/qa/smoke-[date].md` report has verdict NOT ASSESSED — Batch 3 was offered and skipped
- `production/qa/bugs/` contains no bugs

**Input:** `/team-qa sprint-8`

**Expected behavior:**
1. Phase 1 matches `sprint-008.md` by its number
2. Phase 2: records `Smoke Check: NOT ASSESSED — Batch 3 skipped — source: production/qa/smoke-[date].md` and warns that the last smoke check could not assess it, recommending a `/smoke-check sprint` re-run; the cycle continues
3. Phases 3–5 run; both stories PASS and the Visual/Feel story's evidence is retained
4. Phase 6: every story has executed evidence, but the smoke check was NOT ASSESSED, so the sign-off verdict is **NOT ASSESSED** — never APPROVED

**Assertions:**
- [ ] The NOT ASSESSED smoke verdict is taken from the report and shown with its source — not read as PASS or UNKNOWN
- [ ] The cycle does not stop at Phase 2 on NOT ASSESSED (only FAIL stops it)
- [ ] The sign-off verdict is NOT ASSESSED even though every story passed
- [ ] The next step names re-running `/smoke-check` before `/team-qa`

---

### Case 8: An open S1 already on file — known before sign-off, and the brief names no verdict

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`, `qa.level: standard`
- `production/sprints/sprint-009.md` lists 2 stories in the Combat system: 1 Logic (its unit test passes) and 1 UI
- `production/qa/bugs/BUG-0004.md`: System Combat, `**Severity**: S1-Critical`, `**Status**: Open` — filed before this cycle; `BUG-0002.md` (Combat, S2) has `**Status**: Closed`
- The most recent `production/qa/smoke-[date].md` report has verdict PASS

**Input:** `/team-qa sprint-9`

**Expected behavior:**
1. Phase 1 greps the bug files and reports "Open bugs in scope: 1 — S1: 1"; the closed BUG-0002 is not counted
2. Phase 2's brief to qa-lead carries BUG-0004, and the strategy lists it under **Open bugs in scope** as a known failure
3. Phases 3–5 run; both stories PASS and the UI story's screenshots are retained
4. Phase 6's brief passes the strategy, the smoke verdict, both stories' results, BUG-0004 and the verdict rules — it names no verdict, pre-fills no `### Verdict:` line and does not say which fact decides it
5. The qa-lead returns NOT APPROVED (an open S1 bug in scope); the Bugs Found table lists BUG-0004; the orchestrator checks that verdict against the rules, then asks to write

**Assertions:**
- [ ] BUG-0004 is known from Phase 1 and appears in the Phase 2 strategy — not first discovered at sign-off, and never missed
- [ ] The sign-off verdict is NOT APPROVED although every story passed — never NOT ASSESSED or APPROVED
- [ ] The Phase 6 brief names no verdict and no deciding fact; the qa-lead reaches NOT APPROVED from the rules
- [ ] A closed bug is not counted as open

---

## Protocol Compliance

- [ ] A manual-QA result is recorded only as the tester gave it — never filled in for them; an unanswered story stays unexecuted
- [ ] In Phase 6 the qa-lead returns the sign-off text and writes no file; the orchestrator writes it after the ask
- [ ] A bug filed in Phase 5 uses `/bug-report`'s Severity and Priority labels exactly
- [ ] At the default `team.size: individual`, the run opens with an active-set line naming qa-tester as the always-active agent and stating that qa-lead is spawned only at phase gates (the decision points the pipeline lists, whatever the `automation` mode) — before any agent is spawned
- [ ] `AskUserQuestion` used at Phase 2 (strategy review), Phase 4 (test case approval per group), and Phase 5 (per-story manual QA result and failure description)
- [ ] Phase 2 smoke check is a hard gate: FAIL halts the pipeline before Phase 3
- [ ] When no `production/qa/smoke-*.md` report exists, the smoke status is UNKNOWN, the warning "No smoke check report found. Recommend running `/smoke-check sprint` before QA. Proceeding with caution." is shown, and the cycle continues
- [ ] A smoke report whose verdict is NOT ASSESSED is surfaced with what did not run, and the cycle continues as for UNKNOWN
- [ ] With no smoke report (UNKNOWN), or one that is NOT ASSESSED, the sign-off verdict is NOT ASSESSED even when every story passes — never APPROVED or APPROVED WITH CONDITIONS — unless an open S1/S2 bug, or a FAIL without a documented workaround, makes it NOT APPROVED
- [ ] "May I write?" is asked before every orchestrator write: the QA plan (Phase 3), each group's evidence artifacts (Phase 5) and the sign-off report (Phase 6)
- [ ] Bug reports are always written by `qa-tester` via Agent — orchestrator does not write them directly
- [ ] Every Phase 4 qa-tester prompt names each story's output path; per-story parallel spawns happen only at `team.size: studio`
- [ ] Evidence artifacts never carry pre-ticked sign-off rows for a sign-off that did not happen in the session
- [ ] Error recovery: any BLOCKED agent is surfaced immediately with AskUserQuestion options
- [ ] Partial report always produced — no work is discarded because one story failed or blocked
- [ ] Open bugs already on file are read in Phase 1 and reach both qa-lead briefs; no brief to qa-lead names the sign-off verdict
- [ ] Sign-off verdict rules are strictly applied: any S1/S2 bug open = NOT APPROVED; APPROVED and APPROVED WITH CONDITIONS require executed evidence for every story in scope
- [ ] Orchestrator-level Verdict: COMPLETE is distinct from the sign-off report's verdict

---

## Coverage Notes

- The "APPROVED WITH CONDITIONS" verdict path (S3/S4 bugs, PASS WITH NOTES with every story executed) is not given a dedicated case; Case 5's Story B would produce it if no S1/S2 bug were open and Story D had been executed.
- The NOT ASSESSED verdict with no known failure is covered for a NOT ASSESSED smoke report (Case 7); one story BLOCKED with the rest PASS, or no smoke report at all, is not given a dedicated case — the smoke-UNKNOWN rule is asserted in Protocol Compliance.
- The `studio` shape (one qa-tester per story, in parallel) is asserted structurally but not given a case; Cases 1, 3 and 5 run at `small`.
- The `feature: [system-name]` argument form is exercised by Case 6 — it follows the same Phase 1 logic as the sprint form, using glob instead of the sprint file. Case 4 variant B exercises the epic fallback.
- Logic stories with passing automated tests do not need manual QA — this is validated implicitly by Case 5 (Story A) where the Logic story receives no manual QA phase.
- The session-state append to `production/session-state/active.md` after the final phase is not asserted.
