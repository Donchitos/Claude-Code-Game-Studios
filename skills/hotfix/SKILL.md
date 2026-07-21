---
name: hotfix
description: "Emergency fix workflow that bypasses normal sprint processes with a full audit trail. Creates hotfix branch, tracks approvals, and ensures the fix is backported correctly."
---

## Invocation

- Canonical syntax: `$hotfix`
- Expected input: `[bug-id or description]`. Input is the text supplied by the user's invoking prompt.

## User interaction

At every decision point described below, pause and ask the user a focused question. Offer concise choices when useful and wait for the answer before continuing.

## Specialist delegation

Use generic Codex sub-agents; repository role profiles do not register custom agent types. For every named specialist delegated below, instruct the sub-agent to read the matching profile before acting, and include full task context, relevant paths, constraints, and expected output.

- [qa-lead](../../roles/qa-lead.md)

> **Explicit invocation only**: This skill should only run when the user explicitly requests it with `$hotfix`. Do not auto-invoke based on context matching.

## Phase 1: Assess Severity

Read the bug description or ID. Assess severity using these criteria:

- **S1 (Critical)**: Game unplayable, data loss, security vulnerability
- **S2 (Major)**: Significant feature broken, workaround exists
- **S3 or lower**: Minor issue — normal bug fix workflow applies

Confirm with a focused user question:
- Prompt: "I've assessed this as **[assessed severity]** — [brief rationale]. Confirm severity to proceed:"
- Options:
  - `[A] S1 (Critical) — game unplayable, data loss, or security issue`
  - `[B] S2 (Major) — significant feature broken, workaround exists`
  - `[C] S3 or lower — redirect to normal bug fix workflow`

If [C]: stop. Verdict: **REDIRECTED** — use the normal bug fix workflow for S3 and below.

---

## Phase 2: Create Hotfix Record

Draft the hotfix record:

```markdown
## Hotfix: [Short Description]
Date: [Date]
Severity: [S1/S2]
Reporter: [Who found it]
Status: IN PROGRESS

### Problem
[Clear description of what is broken and the player impact]

### Root Cause
[To be filled during investigation]

### Fix
[To be filled during implementation]

### Testing
[What was tested and how]

### Approvals
- [ ] Fix reviewed by lead-programmer
- [ ] Regression test passed (qa-tester)
- [ ] Release approved (producer)

### Rollback Plan
[How to revert if the fix causes new issues]
```

Ask: "May I write this to `production/hotfixes/hotfix-[date]-[short-name].md`?"

If yes, write the file, creating the directory if needed.

---

## Phase 3: Create Hotfix Branch

Check whether this is a git repository:

`Bash: git rev-parse --is-inside-work-tree 2>/dev/null`

If this command fails or returns empty: note "Not a git repository — create the branch manually." and skip branch creation.

If the check passes, pause and ask the user a focused question before creating the branch:
- Prompt: "Ready to create hotfix branch 'hotfix/[short-name]' from [base-ref]?"
- Options:
  - `[A] Yes — create branch`
  - `[B] Use a different base ref — I'll specify it`
  - `[C] Skip — I'll create the branch myself`

Only run `git checkout -b hotfix/[short-name] [base-ref]` if user selects [A]. If [B]: ask the user for the base ref, then run the command with that ref. If [C]: skip branch creation and proceed to Phase 4.

---

## Phase 4: Investigate and Implement

Focus on the minimal change that resolves the issue. Do NOT refactor, clean up, or add features alongside the hotfix.

Validate the fix by running targeted tests for the affected system. Check for regressions in adjacent systems.

Update the hotfix record with root cause, fix details, and test results.

---

## Phase 5: Collect Approvals

Use the generic sub-agent mechanism to request sign-off in parallel:

- [lead-programmer](../../roles/lead-programmer.md) role profile — Review the fix for correctness and side effects
- [qa-tester](../../roles/qa-tester.md) role profile — Run targeted regression tests on the affected system
- [producer](../../roles/producer.md) role profile — Approve deployment timing and communication plan

All three must return APPROVE before proceeding. If any returns CONCERNS or REJECT, do not deploy — surface the issue and resolve it first.

---

## Phase 5b: QA Re-Entry Gate

After approvals, determine the QA scope required before deploying the hotfix. Spawn `qa-lead` through generic sub-agent delegation with:
- The hotfix description and affected system
- The regression test results from Phase 5
- A list of all systems that touch the changed files (use `rg` and code references to find callers)

Ask qa-lead: **Is a full smoke check sufficient, or does this fix require a targeted team-qa pass?**

Apply the verdict:
- **Smoke check sufficient** — run `$smoke-check` against the hotfix build. If PASS, proceed to Phase 6.
- **Targeted QA pass required** — run `$team-qa [affected-system]` scoped to the changed system only. If QA returns APPROVED or APPROVED WITH CONDITIONS, proceed to Phase 6.
- **Full QA required** — S1 fixes that touch core systems may require a full `$team-qa sprint`. This delays deployment but prevents a bad patch.

Do not skip this gate. A hotfix that breaks something else is worse than the original bug.

---

## Phase 6: Update Bug Status and Deploy

Update the original bug file if one exists:

```markdown
## Fix Record
**Fixed in**: hotfix/[branch-name] — [commit hash or description]
**Fixed date**: [date]
**Status**: Fixed — Pending Verification
```

Set `**Status**: Fixed — Pending Verification` in the bug file header.

Output a deployment summary:

```
## Hotfix Ready to Deploy: [short-name]

**Severity**: [S1/S2]
**Root cause**: [one line]
**Fix**: [one line]
**QA gate**: [Smoke check PASS / Team-QA APPROVED]
**Approvals**: lead-programmer ✓ / qa-tester ✓ / producer ✓
**Rollback plan**: [from Phase 2 record]

Merge to: release branch AND development branch
Next: $bug-report verify [BUG-ID] after deploy to confirm resolution
```

### Rules
- Hotfixes must be the MINIMUM change to fix the issue — no cleanup, no refactoring
- Every hotfix must have a rollback plan documented before deployment
- Hotfix branches merge to BOTH the release branch AND the development branch
- All hotfixes require a post-incident review within 48 hours
- If the fix is complex enough to need more than 4 hours, escalate to `technical-director`

---

## Phase 7: Post-Deploy Verification

After deploying, run `$bug-report verify [BUG-ID]` to confirm the fix resolved the issue in the deployed build.

If VERIFIED FIXED: run `$bug-report close [BUG-ID]` to formally close it.
If STILL PRESENT: the hotfix failed — immediately re-open, assess rollback, and escalate.

Schedule a post-incident review within 48 hours using `$retrospective hotfix`.

Pause and ask the user a focused question:
- Prompt: "Hotfix complete. What's the next step?"
- Options:
  - `[A] Run $smoke-check to verify the fix`
  - `[B] Run $patch-notes to document this hotfix`
  - `[C] Stop here`
