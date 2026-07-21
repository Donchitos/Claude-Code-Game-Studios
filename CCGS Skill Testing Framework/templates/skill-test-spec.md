# Skill Spec: /[skill-name]

> **Category**: [gate | review | authoring | readiness | pipeline | analysis | team | sprint | utility]
> **Priority**: [critical | high | medium | low]
> **Spec written**: [YYYY-MM-DD]

## Skill Summary

[One paragraph describing what this skill does, what inputs it takes, and what outputs it produces.]

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has non-empty `name` and `description`; `agents/openai.yaml` has non-empty `interface.display_name` and `interface.short_description`
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] Write-capable workflows use ask-before-write language (or are explicitly read-only)
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

[Describe which director gates this skill triggers (if any), and under what review mode conditions.]

- **Full mode**: [gates triggered — e.g., CD-PHASE-GATE, TD-PHASE-GATE, PR-PHASE-GATE, AD-PHASE-GATE]
- **Lean mode**: [phase gates only — e.g., CD-PHASE-GATE only, or none]
- **Solo mode**: [no gates — skill runs without director review]
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

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — [brief name]

**Fixture**:
- [missing or invalid condition]

**Expected behavior**:
1. [Skill detects the problem]
2. [Skill reports FAIL/BLOCKED]
3. [Skill does NOT proceed]

**Assertions**:
- [ ] Skill stops early and does not produce output
- [ ] Correct error/block message displayed
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

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

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — [brief name]

**Fixture**:
- [unusual or boundary condition]

**Expected behavior**:
1. [Skill handles gracefully]

**Assertions**:
- [ ] [Edge case handled without crash or silent failure]
- [ ] [Correct output or message]

**Case Verdict**: PASS / FAIL / PARTIAL

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
- [ ] In lean mode: [phase gates only, or skip]
- [ ] In solo mode: no director gates spawn
- [ ] Skill does not auto-advance past a CONCERNS or FAIL verdict

**Case Verdict**: PASS / FAIL / PARTIAL

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
