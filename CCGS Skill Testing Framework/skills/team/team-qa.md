# Skill Test Spec: $team-qa

## Skill Summary

Orchestrates the QA team through a 7-phase structured testing cycle. Coordinates
qa-lead (strategy, test plan, sign-off report) and qa-tester (test case writing,
bug report writing). Covers scope detection, story classification, QA plan
generation, smoke check gate, test case writing, manual QA execution with bug
filing, and a final sign-off report with an APPROVED / APPROVED WITH CONDITIONS /
NOT APPROVED verdict. Parallel qa-tester spawning is used in Phase 5 for
independent stories.

---

## Static Assertions (Structural)

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains verdict keywords for sign-off report: APPROVED, APPROVED WITH CONDITIONS, NOT APPROVED
- [ ] Contains "May I write" language for both the QA plan and the sign-off report
- [ ] Has an Error Recovery Protocol section
- [ ] Uses `AskUserQuestion` at phase transitions to capture user approval before proceeding
- [ ] Phase 4 (smoke check) is a hard gate: FAIL stops the cycle
- [ ] Bug reports are written to `production/qa/bugs/` with `BUG-[NNN]-[short-slug].md` naming
- [ ] Next-step guidance differs by verdict (APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED)
- [ ] Independent qa-tester tasks in Phase 5 are spawned in parallel

---

## Test Cases

### Case 1: Happy Path — All stories pass manual QA, APPROVED verdict

**Fixture:**
- `production/sprints/sprint-03/` exists with 4 story files
- Stories are a mix of types: 1 Logic, 1 Integration, 2 Visual/Feel
- All stories have acceptance criteria populated
- `tests/smoke/` contains a smoke test list; all items are verifiable
- No existing bugs in `production/qa/bugs/`

**Input:** `$team-qa sprint-03`

**Expected behavior:**
1. Phase 1: Reads all story files in `production/sprints/sprint-03/`; reads `production/stage.txt`; reports "Found 4 stories. Current stage: [stage]. Ready to begin QA strategy?"
2. Phase 2: Spawns `qa-lead` via Task; produces strategy table classifying all 4 stories; no blockers flagged; presents to user; AskUserQuestion: user selects "Looks good — proceed to test plan"
3. Phase 3: Produces QA plan document; asks "May I write the QA plan to `production/qa/qa-plan-sprint-03-[date].md`?"; writes after approval
4. Phase 4: Spawns `qa-lead` via Task; reviews `tests/smoke/`; returns PASS; reports "Smoke check passed. Proceeding to test case writing."
5. Phase 5: Spawns `qa-tester` via Task for each Visual/Feel and Integration story (2–3 stories); run in parallel; presents test cases grouped by story; AskUserQuestion per group; user approves
6. Phase 6: Walks through each approved story; user marks all as PASS; result summary: "Stories PASS: 4, FAIL: 0, BLOCKED: 0"
7. Phase 7: Spawns `qa-lead` via Task to produce sign-off report; report shows all stories PASS; no bugs filed; Verdict: APPROVED; asks "May I write this QA sign-off report to `production/qa/qa-signoff-sprint-03-[date].md`?"; writes after approval
8. Verdict: COMPLETE — QA cycle finished

**Assertions:**
- [ ] Phase 1 correctly counts and reports 4 stories with current stage
- [ ] Strategy table in Phase 2 classifies all 4 stories with correct types
- [ ] QA plan written only after "May I write?" approval
- [ ] Smoke check PASS allows pipeline to continue without user intervention
- [ ] Phase 5 qa-tester tasks for independent stories are issued in parallel
- [ ] Sign-off report includes Test Coverage Summary table and Verdict: APPROVED
- [ ] Sign-off report written only after "May I write?" approval
- [ ] Verdict: COMPLETE appears in final output
- [ ] Next step: "Run `$gate-check` to validate advancement."

---

### Case 2: Smoke Check Fail — QA cycle stops at Phase 4

**Fixture:**
- `production/sprints/sprint-04/` exists with 3 story files
- `tests/smoke/` exists with 5 smoke test items; 2 items cannot be verified (e.g., build is unstable, core navigation broken)

**Input:** `$team-qa sprint-04`

**Expected behavior:**
1. Phases 1–3 complete normally; QA plan is written
2. Phase 4: Spawns `qa-lead` via Task; smoke check returns FAIL; two specific failures are identified
3. Skill reports: "Smoke check failed. QA cannot begin until these issues are resolved: [list of 2 failures]. Fix them and re-run `$smoke-check`, or re-run `$team-qa` once resolved."
4. Skill stops immediately after Phase 4 — no Phase 5, 6, or 7 is executed
5. No sign-off report is produced; no "May I write?" for a sign-off is issued

**Assertions:**
- [ ] Smoke check FAIL causes the pipeline to halt at Phase 4 — Phases 5, 6, 7 are NOT executed
- [ ] Failure list is shown to the user explicitly (not summarized vaguely)
- [ ] Skill recommends `$smoke-check` and `$team-qa` re-run as remediation steps
- [ ] No QA sign-off report is written or offered
- [ ] Skill does NOT produce a COMPLETE verdict
- [ ] Any QA plan already written in Phase 3 is preserved (not deleted)

---

### Case 3: Bug Found — Visual/Feel story fails manual QA, bug report filed

**Fixture:**
- `production/sprints/sprint-05/` exists with 2 story files: 1 Logic (passes automated tests), 1 Visual/Feel
- `tests/smoke/` smoke check passes
- The Visual/Feel story's animation timing is visibly wrong (acceptance criterion not met)
- `production/qa/bugs/` directory exists (empty or with existing bugs)

**Input:** `$team-qa sprint-05`

**Expected behavior:**
1. Phases 1–5 complete normally; test cases are written for the Visual/Feel story
2. Phase 6: User marks Visual/Feel story as FAIL; AskUserQuestion collects failure description: "Animation plays at 2x speed — jitter visible on every loop"
3. Phase 6: Spawns `qa-tester` via Task to write a formal bug report; bug report written to `production/qa/bugs/BUG-001-animation-speed-jitter.md` (or next increment if bugs exist); report includes severity field
4. Result summary: "Stories PASS: 1, FAIL: 1 — bugs filed: BUG-001"
5. Phase 7: Spawns `qa-lead` to produce sign-off report; Bugs Found table lists BUG-001 with severity and status Open; Verdict: NOT APPROVED (S1/S2 bug open, or FAIL without documented workaround)
6. Sign-off report write is offered; writes after approval
7. Next step: "Resolve S1/S2 bugs and re-run `$team-qa` or targeted manual QA before advancing."

**Assertions:**
- [ ] FAIL result in Phase 6 triggers AskUserQuestion to collect the failure description before the bug report is written
- [ ] `qa-tester` is spawned via Task to write the bug report — orchestrator does not write it directly
- [ ] Bug report follows naming convention: `BUG-[NNN]-[short-slug].md` in `production/qa/bugs/`
- [ ] Bug report NNN is incremented correctly from existing bugs in the directory
- [ ] Phase 7 sign-off report Bugs Found table includes the bug ID, story name, severity, and status
- [ ] Verdict in sign-off report is NOT APPROVED
- [ ] Next step explicitly mentions re-running `$team-qa`
- [ ] Verdict: COMPLETE is still issued by the orchestrator (the QA cycle finished — the verdict is NOT APPROVED, but the skill completed its pipeline)

---

### Case 4: No Argument — Skill infers active sprint or asks user

**Fixture (variant A — state files present):**
- `production/session-state/active.md` exists and contains a reference to `sprint-06`
- `production/sprint-status.yaml` exists and identifies `sprint-06` as active

**Fixture (variant B — state files absent):**
- `production/session-state/active.md` does NOT exist
- `production/sprint-status.yaml` does NOT exist

**Input:** `$team-qa` (no argument)

**Expected behavior (variant A):**
1. Phase 1: No argument provided; reads `production/session-state/active.md`; reads `production/sprint-status.yaml`
2. Detects `sprint-06` as the active sprint from both sources
3. Proceeds as if `$team-qa sprint-06` was the input; reports "No sprint argument provided — inferred sprint-06 from session state. Found [N] stories."

**Expected behavior (variant B):**
1. Phase 1: No argument provided; attempts to read `production/session-state/active.md` — file missing; attempts to read `production/sprint-status.yaml` — file missing
2. Cannot infer sprint; uses AskUserQuestion: "Which sprint or feature should QA cover?" with options to type a sprint identifier or cancel

**Assertions:**
- [ ] Skill does NOT default to a hardcoded sprint name when no argument is provided
- [ ] Skill reads both `production/session-state/active.md` AND `production/sprint-status.yaml` before asking the user (variant A)
- [ ] When both state files are absent, skill uses AskUserQuestion rather than guessing (variant B)
- [ ] Inferred sprint is reported to the user before proceeding (variant A transparency)
- [ ] Skill does NOT error out when state files are missing — it falls back to asking (variant B)

---

### Case 5: Mixed Results — Some PASS, one FAIL with S1 bug, one BLOCKED

**Fixture:**
- `production/sprints/sprint-07/` exists with 4 story files
- Smoke check passes
- Story A (Logic): automated test passes — PASS
- Story B (UI): manual QA — PASS WITH NOTES (minor text overflow)
- Story C (Visual/Feel): manual QA — FAIL; tester identifies S1 crash on ability activation
- Story D (Integration): cannot test — BLOCKED (dependency system not yet implemented)

**Input:** `$team-qa sprint-07`

**Expected behavior:**
1. Phases 1–5 proceed; Phase 5 test cases cover stories B, C, D
2. Phase 6: User marks Story A as implicitly PASS (automated); Story B: PASS WITH NOTES; Story C: FAIL; Story D: BLOCKED
3. After Story C FAIL: qa-tester spawned to write bug report `BUG-001-crash-ability-activation.md` with S1 severity
4. Result summary presented: "Stories PASS: 1, PASS WITH NOTES: 1, FAIL: 1 — bugs filed: BUG-001 (S1), BLOCKED: 1"
5. Phase 7: qa-lead produces sign-off report covering all 4 stories; BUG-001 listed as S1/Open; Story D listed as BLOCKED; Verdict: NOT APPROVED
6. Sign-off report written after "May I write?" approval
7. Next step: "Resolve S1/S2 bugs and re-run `$team-qa` or targeted manual QA before advancing."

**Assertions:**
- [ ] All 4 stories appear in the Phase 7 sign-off report Test Coverage Summary table — none are silently omitted
- [ ] Story D (BLOCKED) is listed in the report with a BLOCKED status, not silently dropped
- [ ] S1 bug causes Verdict: NOT APPROVED regardless of the other stories passing
- [ ] PASS WITH NOTES stories do not downgrade to FAIL — they are tracked separately
- [ ] BUG-001 severity is listed as S1 in the Bugs Found table
- [ ] Partial results are preserved — the sign-off report is still produced even with failures and blocks
- [ ] Verdict: COMPLETE is issued by the orchestrator (pipeline completed); sign-off verdict is NOT APPROVED

---

## Protocol Compliance

- [ ] `AskUserQuestion` used at Phase 2 (strategy review), Phase 5 (test case approval per group), and Phase 6 (per-story manual QA result)
- [ ] Phase 4 smoke check is a hard gate: FAIL halts the pipeline at Phase 4 with no exceptions
- [ ] "May I write?" asked separately for QA plan (Phase 3) and sign-off report (Phase 7)
- [ ] Bug reports are always written by `qa-tester` via Task — orchestrator does not write directly
- [ ] Phase 5 qa-tester tasks for independent stories are issued in parallel where possible
- [ ] Error recovery: any BLOCKED agent is surfaced immediately with AskUserQuestion options
- [ ] Partial report always produced — no work is discarded because one story failed or blocked
- [ ] Sign-off verdict rules are strictly applied: any S1/S2 bug open = NOT APPROVED; no exceptions
- [ ] Orchestrator-level Verdict: COMPLETE is distinct from the sign-off report's APPROVED/NOT APPROVED verdict

---

## Coverage Notes

- The "APPROVED WITH CONDITIONS" verdict path (S3/S4 bugs, PASS WITH NOTES) is covered implicitly by Case 5's PASS WITH NOTES story (Story B) — if no S1/S2 bugs existed, that case would produce APPROVED WITH CONDITIONS. A dedicated case is not required as the verdict logic is table-driven.
- The `feature: [system-name]` argument form is not separately tested — it follows the same Phase 1 logic as the sprint form, using glob instead of directory read. The no-argument inference path (Case 4) provides sufficient coverage of the detection logic.
- Logic stories with passing automated tests do not need manual QA — this is validated implicitly by Case 5 (Story A) where the Logic story receives no manual QA phase.
- Parallel qa-tester spawning in Phase 5 is validated implicitly by Case 1 (multiple Visual/Feel stories issued simultaneously); no dedicated parallelism case is required beyond the Static Assertions check.
