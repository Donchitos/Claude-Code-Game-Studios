# Skill Test Spec: /[skill-name]

## Skill Summary

[One paragraph describing what this skill does, what inputs it takes, and what outputs it produces.]

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] Contains the skill's verdict keywords — any that `/skill-test static` Check 3 accepts (gate or review verdicts, go/no-go verdicts, or a severity scale), plus `NOT ASSESSED` when anything depends on the verdict; none needed when the skill outputs an artifact rather than a judgement
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

[Describe which director gates this skill triggers (if any), and under what review mode conditions.]

- **Full mode**: [gates triggered — e.g., CD-PHASE-GATE, TD-PHASE-GATE, PR-PHASE-GATE, AD-PHASE-GATE]
- **Lean mode**: [phase gates only — for `/gate-check`, the panel `modes.workflow` sets (PR only at `minimal`, TD + PR at `standard`, all four at `full`); other skills skip their non-phase gates, each noted `[GATE-ID] skipped — Lean mode`]
- **Solo mode**: [no gates — skill runs without director review; each skip is noted, e.g. `[GATE-ID] skipped — Solo mode`]
- **N/A**: [if this skill never triggers gates, explain why]

---

## Test Cases

### Case 1: Happy Path — [brief name]

**Fixture** (assumed project state):
- [file/condition 1]
- [file/condition 2]

**Expected behavior**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Assertions**:
- [ ] [Assertion 1]
- [ ] [Assertion 2]
- [ ] [Assertion 3]

**Case Verdict**: PASS / FAIL / PARTIAL / NOT ASSESSED

---

### Case 2: Failure / Blocked — [brief name]

**Fixture**:
- [missing or invalid condition]

**Expected behavior**:
1. [Skill detects the problem]
2. [Skill reports FAIL/BLOCKED]
3. [Skill does NOT proceed]

**Assertions**:
- [ ] Skill stops before producing the artifact and reports BLOCKED or NOT ASSESSED, naming the missing input
- [ ] Correct error/block message displayed
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL / NOT ASSESSED

---

### Case 3: Mode Variant — [brief name]

**Fixture**:
- [standard project state]
- [specific mode or flag set]

**Expected behavior**:
1. [Behavior differs from happy path because of mode]

**Assertions**:
- [ ] [Mode-specific assertion]
- [ ] [Output differs correctly from Case 1]

**Case Verdict**: PASS / FAIL / PARTIAL / NOT ASSESSED

---

### Case 4: Edge Case — [brief name]

**Fixture**:
- [unusual or boundary condition]

**Expected behavior**:
1. [Skill handles gracefully]

**Assertions**:
- [ ] [Edge case handled without crash or silent failure]
- [ ] [Correct output or message]

**Case Verdict**: PASS / FAIL / PARTIAL / NOT ASSESSED

---

### Case 5: Director Gate — [brief name]

**Fixture**:
- [project state that triggers a gate check]
- Review mode: [full | lean | solo]

**Expected behavior**:
1. [Gate fires / does not fire based on mode]
2. [Correct director agents spawned or skipped]

**Assertions**:
- [ ] In full mode: [specific gates spawn]
- [ ] In lean mode: [phase gates only, at the width `modes.workflow` sets — or each gate skipped with `[GATE-ID] skipped — Lean mode`]
- [ ] In solo mode: no director gates spawn, and the output names each skip
- [ ] Skill does not auto-advance past a CONCERNS, FAIL or NOT ASSESSED verdict

**Case Verdict**: PASS / FAIL / PARTIAL / NOT ASSESSED

---

### Case 6: Could Not Assess — [brief name]

**Fixture**:
- [an input the skill needs is missing, unreadable, empty or placeholder-only — or a check it must run cannot run]

**Expected behavior**:
1. [Skill detects that part of its scope could not be evaluated]
2. [Skill reports NOT ASSESSED, naming what it could not assess and why]
3. [Skill does NOT resolve the unknown to a pass]

**Assertions**:
- [ ] Verdict is NOT ASSESSED — never the pass value — and names the missing or unreadable input
- [ ] A failure found alongside it still takes the failure verdict (NOT ASSESSED ranks above the pass value, below the failure values)
- [ ] The check that could not run is named in the output, not silently omitted

**Case Verdict**: PASS / FAIL / PARTIAL / NOT ASSESSED

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

[Any gaps in coverage, known edge cases not tested, or conditions that would require
a live skill run to verify.]
