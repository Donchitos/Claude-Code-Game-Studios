# Skill Test Spec: $milestone-review

## Skill Summary

`$milestone-review` generates a comprehensive review of a completed milestone:
what shipped, velocity metrics, deferred items, risks surfaced, and retrospective
seeds. In full mode the PR-MILESTONE director gate runs after the review is
compiled (producer reviews scope delivery). In lean and solo modes the gate is
skipped. The skill asks "May I write to `production/milestones/review-milestone-N.md`?"
before persisting. Verdicts: MILESTONE COMPLETE or MILESTONE INCOMPLETE.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: MILESTONE COMPLETE, MILESTONE INCOMPLETE
- [ ] Contains "May I write" language (skill writes review document)
- [ ] Has a next-step handoff (what to do after review is written)

---

## Director Gate Checks

| Gate ID       | Trigger condition              | Mode guard              |
|---------------|--------------------------------|-------------------------|
| PR-MILESTONE  | After review document compiled | full only (not lean/solo) |

---

## Test Cases

### Case 1: Happy Path — Nearly complete milestone with one deferred story

**Fixture:**
- `production/milestones/milestone-03.md` exists with 8 stories
- 7 stories have `Status: Complete`
- 1 story has `Status: Deferred` (deferred to milestone-04)
- `review-mode.txt` contains `full`

**Input:** `$milestone-review milestone-03`

**Expected behavior:**
1. Skill reads `milestone-03.md` and all referenced sprint files
2. Skill compiles: 7 shipped, 1 deferred; velocity; no blockers
3. Skill presents review draft to user
4. PR-MILESTONE gate invoked; producer approves
5. Skill asks "May I write to `production/milestones/review-milestone-03.md`?"
6. User approves; file is written; verdict MILESTONE COMPLETE

**Assertions:**
- [ ] Deferred story is noted in the review with its target milestone
- [ ] Verdict is MILESTONE COMPLETE despite the one deferred story
- [ ] PR-MILESTONE gate is invoked after draft compilation in full mode
- [ ] Skill asks "May I write" before writing review file
- [ ] Review document path matches `production/milestones/review-milestone-03.md`

---

### Case 2: Blocked Milestone — Multiple blocked stories

**Fixture:**
- `production/milestones/milestone-03.md` exists with 5 stories
- 2 stories have `Status: Complete`
- 3 stories have `Status: Blocked` (named blockers listed in each story)
- `review-mode.txt` contains `full`

**Input:** `$milestone-review milestone-03`

**Expected behavior:**
1. Skill reads milestone and sprint files
2. Skill finds 3 blocked stories; compiles blocker details
3. Verdict is MILESTONE INCOMPLETE
4. PR-MILESTONE gate runs; producer notes the unresolved blockers
5. Review is written with blocker list on approval

**Assertions:**
- [ ] Verdict is MILESTONE INCOMPLETE when any stories are Blocked
- [ ] Each blocked story's name and blocker reason is listed in the review
- [ ] PR-MILESTONE gate is still invoked in full mode even for INCOMPLETE verdict
- [ ] "May I write" prompt still appears before file write

---

### Case 3: Full Mode — PR-MILESTONE returns CONCERNS

**Fixture:**
- Milestone-03 has 6 complete stories but 2 were not in the original scope (added mid-sprint)
- `review-mode.txt` contains `full`

**Input:** `$milestone-review milestone-03`

**Expected behavior:**
1. Skill compiles review; notes 2 out-of-scope stories shipped
2. PR-MILESTONE gate invoked; producer returns CONCERNS about scope drift
3. Skill surfaces the CONCERNS to the user and adds a "scope drift" note to the review
4. User approves revised review; file written as MILESTONE COMPLETE with caveat

**Assertions:**
- [ ] CONCERNS from PR-MILESTONE gate are shown to user before write
- [ ] Scope drift is explicitly noted in the written review document
- [ ] Verdict is MILESTONE COMPLETE (stories shipped) with CONCERNS annotation
- [ ] Skill does not suppress gate feedback

---

### Case 4: Edge Case — No milestone file found for specified milestone

**Fixture:**
- User calls `$milestone-review milestone-07`
- `production/milestones/milestone-07.md` does NOT exist

**Input:** `$milestone-review milestone-07`

**Expected behavior:**
1. Skill attempts to read `production/milestones/milestone-07.md`
2. File not found; skill outputs an error message
3. Skill suggests checking available milestones in `production/milestones/`
4. No gate is invoked; no file is written

**Assertions:**
- [ ] Skill does not crash when milestone file is absent
- [ ] Output names the expected file path in the error message
- [ ] Output suggests checking `production/milestones/` for valid milestone names
- [ ] Verdict is BLOCKED (cannot review a non-existent milestone)

---

### Case 5: Lean/Solo Mode — PR-MILESTONE gate skipped

**Fixture:**
- `production/milestones/milestone-03.md` exists with 5 complete stories
- `review-mode.txt` contains `solo`

**Input:** `$milestone-review milestone-03`

**Expected behavior:**
1. Skill reads review mode — determines `solo`
2. Skill compiles review draft
3. PR-MILESTONE gate is skipped; output notes "[PR-MILESTONE] skipped — Solo mode"
4. Skill asks user for direct approval of the review
5. User approves; review file is written; verdict MILESTONE COMPLETE

**Assertions:**
- [ ] PR-MILESTONE gate is NOT invoked in solo (or lean) mode
- [ ] Skip is explicitly noted in skill output
- [ ] User direct approval is still required before write
- [ ] Verdict is MILESTONE COMPLETE after successful write

---

## Protocol Compliance

- [ ] Shows compiled review draft before invoking PR-MILESTONE or asking to write
- [ ] Always asks "May I write" before writing review document
- [ ] PR-MILESTONE gate only runs in full mode
- [ ] Skip message appears in lean and solo output
- [ ] Verdict is MILESTONE COMPLETE or MILESTONE INCOMPLETE, stated clearly

---

## Coverage Notes

- The case where the milestone has zero stories is not tested; it follows the
  MILESTONE INCOMPLETE pattern with a note suggesting the milestone may not
  have been planned.
- Velocity calculation specifics (story points vs. story count) are not
  verified here; they are implementation details of the review compilation phase.
