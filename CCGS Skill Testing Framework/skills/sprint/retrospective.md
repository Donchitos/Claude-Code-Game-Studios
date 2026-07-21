# Skill Test Spec: $retrospective

## Skill Summary

`$retrospective` generates a structured sprint or milestone retrospective
covering three categories: what went well, what didn't, and action items.
It reads sprint files and session logs to compile observations, then produces
a retrospective document. No director gates are used — retrospectives are
team self-reflection artifacts. The skill asks "May I write to
`production/retrospectives/retro-sprint-NNN.md`?" before persisting.
Verdict is always COMPLETE (retrospective is structured output, not a pass/fail
assessment).

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" language (skill writes retrospective document)
- [ ] Has a next-step handoff (what to do after retrospective is written)

---

## Director Gate Checks

None. Retrospectives are team self-reflection documents; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — Sprint with mixed outcomes

**Fixture:**
- `production/sprints/sprint-005.md` exists with 6 stories (4 Complete, 1 Blocked, 1 Deferred)
- `production/session-logs/` contains log entries for the sprint period
- No prior retrospective exists for sprint-005

**Input:** `$retrospective sprint-005`

**Expected behavior:**
1. Skill reads sprint-005 and session logs
2. Skill compiles three retrospective categories: went well (4 stories shipped), 
   didn't (1 blocked, 1 deferred), and action items (address blocker root cause)
3. Skill presents retrospective draft to user
4. Skill asks "May I write to `production/retrospectives/retro-sprint-005.md`?"
5. User approves; file is written; verdict COMPLETE

**Assertions:**
- [ ] Retrospective contains all three categories (went well / didn't / actions)
- [ ] Blocked and deferred stories appear in the "what didn't" section
- [ ] At least one action item is generated from the blocked story
- [ ] Skill asks "May I write" before writing file
- [ ] Verdict is COMPLETE after successful write

---

### Case 2: No Sprint Data — Manual input fallback

**Fixture:**
- User calls `$retrospective sprint-009`
- `production/sprints/sprint-009.md` does NOT exist
- No session logs reference sprint-009

**Input:** `$retrospective sprint-009`

**Expected behavior:**
1. Skill attempts to read sprint-009 — not found
2. Skill informs user that no sprint data was found for sprint-009
3. Skill prompts user to provide retrospective input manually (went well, didn't, actions)
4. User provides input; skill formats it into the retrospective structure
5. Skill asks "May I write" and writes the document on approval

**Assertions:**
- [ ] Skill does not crash or produce an empty document when sprint file is absent
- [ ] User is prompted to provide manual input
- [ ] Manual input is formatted into the three-category structure
- [ ] "May I write" prompt still appears before file write

---

### Case 3: Prior Retrospective Exists — Offer to append or replace

**Fixture:**
- `production/retrospectives/retro-sprint-005.md` already exists with content
- User re-runs `$retrospective sprint-005` after changes

**Input:** `$retrospective sprint-005`

**Expected behavior:**
1. Skill detects that `retro-sprint-005.md` already exists
2. Skill presents user with choice: append new observations or replace existing file
3. User selects "replace"; skill compiles fresh retrospective
4. Skill asks "May I write to `production/retrospectives/retro-sprint-005.md`?" (confirming overwrite)
5. File is overwritten; verdict COMPLETE

**Assertions:**
- [ ] Skill checks for existing retrospective file before compiling
- [ ] User is offered append or replace choice — not silently overwritten
- [ ] "May I write" prompt reflects the overwrite scenario
- [ ] Verdict is COMPLETE after write regardless of append vs. replace

---

### Case 4: Edge Case — Unresolved action items from previous retrospective

**Fixture:**
- `production/retrospectives/retro-sprint-004.md` exists with 2 action items marked `[ ]` (not done)
- User runs `$retrospective sprint-005`

**Input:** `$retrospective sprint-005`

**Expected behavior:**
1. Skill reads the most recent prior retrospective (retro-sprint-004)
2. Skill detects 2 unchecked action items from sprint-004
3. Skill includes a "Carry-over from Sprint 004" section in the new retrospective
4. The unresolved items are listed with a note that they were not followed up

**Assertions:**
- [ ] Skill reads the most recent prior retrospective to check for open action items
- [ ] Unresolved action items appear in the new retrospective under a carry-over section
- [ ] Carry-over items are distinct from newly generated action items
- [ ] Output notes that these items were not followed up in the previous sprint

---

### Case 5: Gate Compliance — No gate invoked in any mode

**Fixture:**
- `production/sprints/sprint-005.md` exists with complete stories
- `production/session-state/review-mode.txt` contains `full`

**Input:** `$retrospective sprint-005`

**Expected behavior:**
1. Skill compiles retrospective in full mode
2. No director gate is invoked (retrospectives are team self-reflection, not delivery gates)
3. Skill asks user for approval and writes file on confirmation
4. Verdict is COMPLETE

**Assertions:**
- [ ] No director gate is invoked regardless of review mode
- [ ] Output does not contain any gate invocation or gate result notation
- [ ] Skill proceeds directly from compilation to "May I write" prompt
- [ ] Review mode file content is irrelevant to this skill's behavior

---

## Protocol Compliance

- [ ] Always shows retrospective draft before asking to write
- [ ] Always asks "May I write" before writing retrospective file
- [ ] No director gates are invoked
- [ ] Verdict is always COMPLETE (not a pass/fail skill)
- [ ] Checks prior retrospective for unresolved action items

---

## Coverage Notes

- Milestone retrospectives (as opposed to sprint retrospectives) follow the
  same pattern but read milestone files instead of sprint files; not
  separately tested here.
- The case where session logs are empty is similar to Case 2 (no data);
  the skill falls back to manual input in both situations.
