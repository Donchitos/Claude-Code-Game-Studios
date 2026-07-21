# Agent Spec: [agent-name]

> **Tier**: [directors | leads | specialists | godot | unity | unreal | operations | creative]
> **Category**: [director | lead | specialist | engine | operations | creative]
> **Spec written**: [YYYY-MM-DD]

## Agent Summary

[One paragraph describing this agent's domain, what decisions it owns, and what it
delegates vs. handles directly. Include which gates it triggers (if any).]

**Domain**: [files/directories this agent owns]
**Escalates to**: [parent agent — e.g., creative-director for design conflicts]
**Delegates to**: [sub-agents this agent typically spawns]

---

## Static Assertions

- [ ] Role profile exists at `roles/[name].md`
- [ ] Frontmatter has non-empty `name` and `description` fields
- [ ] Profile states that it is injected into a generic Codex sub-agent; it does not claim fixed model routing or automatic registration
- [ ] Domain clearly stated
- [ ] Escalation path documented
- [ ] Does not make decisions outside its domain

---

## Test Cases

### Case 1: In-Domain Request — [brief name]

**Scenario**: A request that is clearly within this agent's domain.

**Fixture**:
- [relevant project state]
- [input provided to agent]

**Expected behavior**:
1. Agent accepts the request
2. Agent produces [specific output type]
3. Agent asks before writing files (if applicable)

**Assertions**:
- [ ] Agent handles request within its domain without escalating
- [ ] Output format matches expected structure
- [ ] Collaborative protocol followed (ask → draft → approve)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — [brief name]

**Scenario**: A request that falls outside this agent's domain.

**Fixture**:
- [request that belongs to a different agent]

**Expected behavior**:
1. Agent identifies the request is out of domain
2. Agent redirects to the correct agent
3. Agent does NOT attempt to handle it

**Assertions**:
- [ ] Agent declines and redirects (does not silently handle cross-domain work)
- [ ] Correct agent named in redirect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — [brief name]

**Scenario**: Agent is invoked as part of a director gate check.

**Fixture**:
- [project state presented for review]
- [gate ID: e.g., CD-PHASE-GATE]

**Expected behavior**:
1. Agent reads the relevant documents
2. Agent produces a PASS / CONCERNS / FAIL verdict
3. Agent does not auto-advance on CONCERNS or FAIL

**Assertions**:
- [ ] Verdict keyword present in output (PASS, CONCERNS, FAIL)
- [ ] Reasoning provided for verdict
- [ ] On CONCERNS/FAIL: work is blocked, not silently continued

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — [brief name]

**Scenario**: This agent's domain conflicts with another agent's decision.

**Fixture**:
- [conflicting decisions from two agents at same tier]

**Expected behavior**:
1. Agent identifies the conflict
2. Agent escalates to the shared parent (or creative-director / technical-director)
3. Agent does NOT unilaterally resolve cross-domain conflicts

**Assertions**:
- [ ] Conflict surfaced explicitly
- [ ] Correct escalation path followed
- [ ] No unilateral cross-domain changes made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — [brief name]

**Scenario**: Agent receives a task with full context from a parent agent.

**Fixture**:
- [context block passed from parent]
- [specific sub-task to execute]

**Expected behavior**:
1. Agent reads and uses the provided context
2. Agent completes the sub-task
3. Agent returns result to parent (does not prompt user unnecessarily)

**Assertions**:
- [ ] Agent uses provided context rather than re-asking for it
- [ ] Result is scoped to the sub-task, not expanded beyond it
- [ ] Output format suitable for parent agent consumption

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — no unilateral cross-domain changes
- [ ] Escalates conflicts to correct parent
- [ ] Uses `"May I write"` before file writes (or is read-only)
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy

---

## Coverage Notes

[Any gaps in coverage, known edge cases not tested, or behaviors that require
a live agent invocation to verify.]
