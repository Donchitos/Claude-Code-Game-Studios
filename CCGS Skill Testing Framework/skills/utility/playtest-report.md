# Skill Test Spec: $playtest-report

## Skill Summary

`$playtest-report` generates a structured playtest report from session notes or
user input. The report is organized into four sections: Feel/Accessibility,
Bugs Observed, Design Feedback, and Next Steps. When multiple testers participated,
the skill aggregates feedback and distinguishes majority opinions from minority
ones. The skill links to existing bug reports when a reported bug matches a file
in `production/bugs/`.

Reports are written to `production/qa/playtest-[date].md` after a "May I write"
ask. No director gates apply here — the CD-PLAYTEST director gate (if needed) is
a separate invocation. The verdict is COMPLETE when the report is written.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" collaborative protocol language before writing the report
- [ ] Has a next-step handoff (e.g., `$bug-report` for new issues found, `$design-review` for feedback)

---

## Director Gate Checks

None. `$playtest-report` is a documentation utility. The CD-PLAYTEST gate is a
separate invocation and not part of this skill.

---

## Test Cases

### Case 1: Happy Path — User provides playtest notes, structured report produced

**Fixture:**
- User provides typed playtest notes from a single session
- Notes cover: game feel, one bug (framerate drop), and a design concern
  (tutorial too long)
- `production/bugs/` exists but is empty (bug not yet reported)

**Input:** `$playtest-report` (user pastes session notes)

**Expected behavior:**
1. Skill reads the provided notes and structures them into the 4-section template
2. Feel/Accessibility: extracts feel observations
3. Bugs: notes the framerate drop with available repro details
4. Design Feedback: notes the tutorial length concern
5. Next Steps: suggests `$bug-report` for the framerate issue and `$design-review`
   for the tutorial feedback
6. Skill asks "May I write to `production/qa/playtest-2026-04-06.md`?"
7. Report is written on approval; verdict is COMPLETE

**Assertions:**
- [ ] All 4 sections are present in the report
- [ ] Bug is listed in the Bugs section (not the Design Feedback section)
- [ ] Next Steps are appropriate (bug report for crash, design review for feedback)
- [ ] "May I write" is asked before writing
- [ ] Verdict is COMPLETE

---

### Case 2: Empty Input — Guided prompting through each section

**Fixture:**
- No notes provided by user at invocation

**Input:** `$playtest-report`

**Expected behavior:**
1. Skill detects empty input
2. Skill prompts through each section:
   a. "Describe the overall feel and any accessibility observations"
   b. "Were any bugs observed? Describe them"
   c. "What design feedback did testers provide?"
3. User answers each prompt
4. Skill compiles report from answers and asks "May I write"
5. Report written on approval; verdict is COMPLETE

**Assertions:**
- [ ] At least 3 guiding questions are asked (one per main section)
- [ ] Report is not created until all sections have input (or user explicitly skips one)
- [ ] Verdict is COMPLETE after file is written

---

### Case 3: Multiple Testers — Aggregated feedback with majority/minority notes

**Fixture:**
- User provides notes from 3 testers
- 2/3 testers found the controls "intuitive"
- 1/3 tester found the UI font too small
- All 3 noted the same bug (player stuck on ledge)

**Input:** `$playtest-report` (3-tester session)

**Expected behavior:**
1. Skill identifies 3 distinct tester perspectives in the input
2. Control intuitiveness → noted as "Majority (2/3): controls intuitive"
3. Font size → noted as "Minority (1/3): UI font size concern"
4. Stuck-on-ledge bug → noted as "All testers: player stuck on ledge (confirmed)"
5. Skill generates aggregated report with majority/minority labels
6. Report written after "May I write" approval; verdict is COMPLETE

**Assertions:**
- [ ] Majority opinion (2/3) is labeled as majority
- [ ] Minority opinion (1/3) is labeled as minority
- [ ] Unanimously reported bug is noted as confirmed by all testers
- [ ] Verdict is COMPLETE

---

### Case 4: Bug Matches Existing Report — Links to existing file

**Fixture:**
- `production/bugs/bug-2026-03-30-player-stuck-ledge.md` exists
- User's playtest notes describe "player gets stuck on ledges near walls"

**Input:** `$playtest-report`

**Expected behavior:**
1. Skill structures the report and identifies the stuck-on-ledge bug
2. Skill scans `production/bugs/` and finds `bug-2026-03-30-player-stuck-ledge.md`
3. In the Bugs section, the report includes: "See existing report:
   production/bugs/bug-2026-03-30-player-stuck-ledge.md"
4. Skill does NOT suggest creating a new bug report for this issue
5. Report written; verdict is COMPLETE

**Assertions:**
- [ ] Existing bug report is found and linked in the playtest report
- [ ] `$bug-report` is NOT suggested for the already-reported issue
- [ ] Cross-reference to existing file appears in the Bugs section
- [ ] Verdict is COMPLETE

---

### Case 5: Director Gate Check — No gate; CD-PLAYTEST is a separate invocation

**Fixture:**
- Playtest notes provided

**Input:** `$playtest-report`

**Expected behavior:**
1. Skill generates and writes the playtest report
2. No director agents are spawned (CD-PLAYTEST is not invoked here)
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No CD-PLAYTEST gate skip message appears
- [ ] Verdict is COMPLETE without any gate check

---

## Protocol Compliance

- [ ] Structures output into all 4 sections (Feel, Bugs, Design Feedback, Next Steps)
- [ ] Labels majority vs. minority opinions when multiple testers are involved
- [ ] Cross-references existing bug reports when bugs match
- [ ] Asks "May I write to `production/qa/playtest-[date].md`?" before writing
- [ ] Verdict is COMPLETE when report is written

---

## Coverage Notes

- The CD-PLAYTEST director gate (creative director reviews playtest insights
  for design implications) is a separate invocation and is not tested here.
- Video recording or screenshot attachments are not tested; the report is a
  text-only document.
- The case where a tester's identity is unknown (anonymous feedback) follows
  the same aggregation pattern as Case 3 without tester labels.
