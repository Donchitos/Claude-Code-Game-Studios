# Skill Test Spec: $day-one-patch

## Skill Summary

`$day-one-patch` prepares a day-one patch plan for issues that are known at
launch but deferred from the v1.0 release. It reads open bug reports in
`production/bugs/`, deferred acceptance criteria from story files (stories
marked `Status: Done` but with noted deferred ACs), and produces a prioritized
patch plan with estimated fix timelines per issue.

The patch plan is written to `production/releases/day-one-patch.md` after a
"May I write" ask. If a P0 (critical post-ship) issue is discovered, the skill
triggers guidance to run `$hotfix` before the patch. No director gates apply.
The verdict is always COMPLETE.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" collaborative protocol language before writing the plan
- [ ] Has a next-step handoff (e.g., `$hotfix` for P0 issues, `$release-checklist` for follow-up)

---

## Director Gate Checks

None. `$day-one-patch` is a release planning utility. No director gates apply.

---

## Test Cases

### Case 1: Happy Path — 3 Known Issues, Patch Plan With Fix Estimates

**Fixture:**
- `production/bugs/` contains 3 open bugs with severities: 1 MEDIUM, 2 LOW
- No deferred ACs in sprint stories
- All bugs have repro steps and system identifications

**Input:** `$day-one-patch`

**Expected behavior:**
1. Skill reads all 3 open bugs
2. Skill assigns fix effort estimates: MEDIUM bug = 1-2 days, LOW bugs = 4 hours each
3. Skill produces a patch plan prioritizing MEDIUM bug first
4. Plan includes: priority order, estimated timeline, responsible system, fix description
5. Skill asks "May I write to `production/releases/day-one-patch.md`?"
6. File written; verdict is COMPLETE

**Assertions:**
- [ ] All 3 bugs appear in the plan
- [ ] Bugs are prioritized by severity (MEDIUM before LOW)
- [ ] Fix estimates are provided per issue
- [ ] "May I write" is asked before writing
- [ ] Verdict is COMPLETE

---

### Case 2: Critical Issue Discovered Post-Ship — P0, Triggers $hotfix Guidance

**Fixture:**
- A CRITICAL severity bug is found in `production/bugs/` after the v1.0 release
- The bug causes data loss for all save files

**Input:** `$day-one-patch`

**Expected behavior:**
1. Skill reads bugs and identifies the CRITICAL severity issue
2. Skill escalates: "P0 ISSUE DETECTED — data loss bug requires immediate hotfix
   before patch planning can proceed"
3. Skill does NOT include the P0 issue in the patch plan timeline
4. Skill explicitly directs: "Run `$hotfix` to resolve this issue first"
5. After P0 guidance is issued: plan for remaining lower-severity bugs is still
   generated and written; verdict is COMPLETE

**Assertions:**
- [ ] P0 escalation message appears prominently before the patch plan
- [ ] `$hotfix` is explicitly directed for the P0 issue
- [ ] P0 issue is NOT scheduled in the patch plan timeline (it needs immediate action)
- [ ] Non-P0 issues are still planned; verdict is COMPLETE

---

### Case 3: Deferred AC From Story-Done — Pulled Into Patch Plan Automatically

**Fixture:**
- `production/sprints/sprint-008.md` has a story with `Status: Done` and a note:
  "DEFERRED AC: Gamepad vibration on damage — deferred to post-launch patch"
- No open bugs for the same system

**Input:** `$day-one-patch`

**Expected behavior:**
1. Skill reads sprint stories and detects the deferred AC note
2. Deferred AC is automatically included in the patch plan as a work item
3. Plan entry: "Deferred from sprint-008: Gamepad vibration on damage"
4. Fix estimate is assigned; patch plan written after "May I write" approval
5. Verdict is COMPLETE

**Assertions:**
- [ ] Deferred ACs from story files are automatically pulled into the plan
- [ ] Deferred items are labeled by their source story (sprint-008)
- [ ] Deferred AC gets a fix estimate like bug entries
- [ ] Verdict is COMPLETE

---

### Case 4: No Known Issues — Empty Plan With Template Note

**Fixture:**
- `production/bugs/` is empty
- No stories have deferred ACs

**Input:** `$day-one-patch`

**Expected behavior:**
1. Skill reads bugs — none found
2. Skill reads story deferred ACs — none found
3. Skill produces an empty patch plan with a note: "No known issues at launch"
4. Template structure is preserved (headers intact) for future use
5. Skill asks "May I write to `production/releases/day-one-patch.md`?"
6. File written; verdict is COMPLETE

**Assertions:**
- [ ] "No known issues at launch" note appears in the written file
- [ ] Template headers are present in the empty plan
- [ ] Skill does NOT error out when there are no issues to plan
- [ ] Verdict is COMPLETE

---

### Case 5: Director Gate Check — No gate; day-one-patch is a planning utility

**Fixture:**
- Known issues present in production/bugs/

**Input:** `$day-one-patch`

**Expected behavior:**
1. Skill generates and writes the patch plan
2. No director agents are spawned
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Verdict is COMPLETE without any gate check

---

## Protocol Compliance

- [ ] Reads open bugs from `production/bugs/` before generating the plan
- [ ] Scans story files for deferred AC notes
- [ ] Escalates CRITICAL (P0) bugs with explicit `$hotfix` guidance
- [ ] Produces an empty plan with note when no issues exist (not an error)
- [ ] Asks "May I write to `production/releases/day-one-patch.md`?" before writing
- [ ] Verdict is COMPLETE in all paths

---

## Coverage Notes

- The case where multiple CRITICAL bugs exist is handled the same as Case 2;
  all P0 issues are escalated together.
- Timeline estimation for the patch (e.g., "patch available in 3 days")
  requires manual QA and build time estimates; the skill uses rough estimates
  based on severity, not actual team velocity.
- The patch notes player communication document (`$patch-notes`) is a separate
  skill invoked after the patch plan is executed.
