---
name: hotfix
description: "Emergency fix bypassing normal sprint process — hotfix branch, approvals tracked, backport verified, full audit trail."
argument-hint: "[bug-id or description]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion
model: sonnet
---

# Hotfix

> **Explicit invocation only**: This skill should only run when the user explicitly requests it with `/hotfix`. Do not auto-invoke based on context matching.

## Phase 1: Assess Severity

Read the bug description or ID. Assess severity on `/bug-triage`'s scale:

- **S1 (Critical)**: Crash, data loss, or complete feature failure — the game cannot proceed (rate a security issue by that impact)
- **S2 (High)**: Major feature broken, but the game is still playable
- **S3 or lower**: Feature degraded with a workaround, or cosmetic — normal bug fix workflow applies

Confirm with `AskUserQuestion`:
- Prompt: "I've assessed this as **[assessed severity]** — [brief rationale]. Confirm severity to proceed:"
- Options:
  - `[A] S1 (Critical) — crash, data loss, or complete feature failure`
  - `[B] S2 (High) — major feature broken, game still playable`
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

`[base-ref]` is the release the bug is in. Releases are tags on `main` (the
trunk), so it is that release's tag (`git tag --list`; the newest is usually
the live build) — or its `release/*` branch, if one was cut to stabilise that
release (`git branch --list 'release/*'`). Never the head of `main`: it may carry
work that has not shipped.

If the check passes, use `AskUserQuestion` before creating the branch:
- Prompt: "Ready to create hotfix branch 'hotfix/[short-name]' from [base-ref]?"
- Options:
  - `[A] Yes — create branch`
  - `[B] Use a different base ref — I'll specify it`
  - `[C] Skip — I'll create the branch myself`

Only run `git checkout -b hotfix/[short-name] [base-ref]` if user selects [A]. If [B]: ask the user for the base ref, then run the command with that ref. If [C]: skip branch creation and proceed to Phase 4.

---

## Phase 4: Investigate and Propose

Find the root cause. Draft the minimal fix: which files change, what the change does, and what it deliberately leaves alone. Do NOT refactor, clean up, or add features alongside the hotfix.

Present the root cause and proposed fix, then ask: "May I implement this fix?" Do not modify any code before this approval — an emergency flow earns its audit trail by approving the change *before* it exists, not after.

---

## Phase 4b: Implement (only after approval)

Implement the approved minimal change. Validate the fix by running targeted tests for the affected system, with `commands.test` from `project.yaml` (narrowed to the affected suite where the runner allows) — never a runner line written from memory, which drops the flags the engine needs (gdUnit4 hangs without `--remote-debug tcp://127.0.0.1:0`). Check for regressions in adjacent systems. If `commands.test` is unset, or no test covers the affected system, say so and record `Tests: NOT RUN — [reason]` in the hotfix record's Testing section; the Phase 5b QA gate then carries the verification.

Update the hotfix record with root cause, fix details, and test results.

---

## Phase 5: Collect Approvals

Use the `Agent` tool to request sign-off in parallel:

- `subagent_type: lead-programmer` — Review the fix for correctness and side effects
- `subagent_type: qa-tester` — Run targeted regression tests on the affected system
- `subagent_type: producer` — Approve deployment timing and communication plan

All three must return APPROVE before proceeding. If any returns CONCERNS or REJECT, do not deploy — surface the issue and resolve it first.

---

## Phase 5b: QA Re-Entry Gate

After approvals, determine the QA scope required before deploying the hotfix. Spawn `qa-lead` via `Agent` with:
- The hotfix description and affected system
- The regression test results from Phase 5
- A list of all systems that touch the changed files (use Grep to find callers)

Ask qa-lead: **Is a full smoke check sufficient, or does this fix require a targeted team-qa pass?**

Apply the verdict:
- **Smoke check sufficient** — run `/smoke-check` against the hotfix build. If PASS or
  PASS WITH WARNINGS, proceed to Phase 6 (carry the warnings into the hotfix record).
  If **FAIL**, do not deploy: return to Phase 4 with the failing checks, get the
  revised fix approved there, implement it (Phase 4b), then re-run Phase 5's
  approvals — qa-tester's regression run among them — and this QA step. A hotfix
  that breaks the smoke suite is a second incident, not a fix.
- **Targeted QA pass required** — run `/team-qa feature: [affected-system]` scoped to the changed system only. If QA returns APPROVED or APPROVED WITH CONDITIONS, proceed to Phase 6; if NOT APPROVED or BLOCKED, handle it as a smoke-check FAIL above.
- **Full QA required** — S1 fixes that touch core systems may require a full `/team-qa sprint`. This delays deployment but prevents a bad patch.

**If the QA step returns `NOT ASSESSED`, the gate did not run — treat it as unmet,
not as met.** `/smoke-check` returns it when the suite never executed and
`/team-qa` when a cycle produced no executed evidence. **A NOT ASSESSED result is
not a pass** — from either skill — and under time pressure the permissive reading
is the one that will feel reasonable,
which is exactly why it is written down here. Either obtain the missing result —
the verdict names what would make it runnable — or take the decision to the
producer explicitly, as a decision to deploy an unverified hotfix rather than as a
gate that quietly cleared. Log that decision — who made it, and why — in the
hotfix record's Testing section.

Do not skip this gate. A hotfix that breaks something else is worse than the original bug.

---

## Phase 6: Update Bug Status and Deploy

> **STOP — deployment requires explicit approval, unconditionally.** Merging a
> hotfix and tagging the patch release is the one irreversible act in this skill,
> so it is gated even though branch creation (reversible) already is. Before any
> merge, tag, or deploy, use `AskUserQuestion`:
>
> - Prompt: "Hotfix validated and approved. Merge to [targets], tag [patch tag]
>   and deploy?" — `[targets]` is `main`, plus the release's `release/*` branch
>   only if it has one
> - Options: `[A] Yes — merge and deploy` / `[B] Merge to main only — hold
>   the release` / `[C] Stop here`
>
> This holds regardless of `modes.automation`, including `autonomous`. An
> emergency process is exactly where an unreviewed irreversible step is most
> likely and least recoverable.

On `[A]`: merge the hotfix branch to `main`, and to the release's `release/*`
branch if it has one; tag the patch release (the next patch version, e.g.
`v1.2.0` → `v1.2.1`) on the fixed build — the `release/*` branch head if there
is one, else the hotfix branch head — and deploy that tag, not the head of
`main`. On `[B]`: merge to `main` only — no release-branch merge, no tag, no
deploy. On `[C]`: stop — no merge, no tag, no deploy and no bug-file update; the
hotfix record's Status stays IN PROGRESS, and say so.

> **Backport is not verified unless you verify it.** The frontmatter advertises
> "backport verified". After merging, confirm the fix is present on `main` (the
> trunk) — and on the release's `release/*` branch, if it has one — and state
> the result. An unbackported hotfix means the bug returns in the next release
> tagged from `main`, which is the single most common hotfix regression.

Update the original bug file if one exists — find it in `production/qa/bugs/`
by its number, as `/bug-report verify` does. Ask first: "May I update
`production/qa/bugs/[bug file]` with the fix record below and set its Status to
`Fixed — Pending Verification`?"

```markdown
## Fix Record
**Fixed in**: hotfix/[branch-name] — [commit hash or description]
**Fixed date**: [date]
**Status**: Fixed — Pending Verification
```

Set `**Status**: Fixed — Pending Verification` in the bug file header.

Output a deployment summary. Its title follows the Phase 6 answer — `Hotfix
Deployed: [short-name]` on `[A]`, `Hotfix Merged to main — release held:
[short-name]` on `[B]` — and on `[B]` the closing line omits the Tag, since none
was created:

```
## Hotfix Deployed: [short-name]

**Severity**: [S1/S2]
**Root cause**: [one line]
**Fix**: [one line]
**QA gate**: [Smoke check PASS / Team-QA APPROVED / NOT ASSESSED — [why, and whose
             explicit decision it was to deploy anyway]]
**Approvals**: lead-programmer ✓ / qa-tester ✓ / producer ✓
**Backport**: [verified present on `main` (and the `release/*` branch, if the
              release has one) — or NOT VERIFIED, with what was not checked]
**Rollback plan**: [from Phase 2 record]

Merge to: [targets] · Tag: [patch tag]
Next: /bug-report verify [BUG-ID] after deploy to confirm resolution
```

### Rules
- Hotfixes must be the MINIMUM change to fix the issue — no cleanup, no refactoring
- Every hotfix must have a rollback plan documented before deployment
- A hotfix branch starts from the release it fixes — its tag, or its `release/*`
  branch if one exists — and merges to `main` (the trunk), and to that
  `release/*` branch only if it exists; the patch release is tagged
- All hotfixes require a post-incident review within 48 hours
- If the fix is complex enough to need more than 4 hours, escalate to `technical-director`

---

## Phase 7: Post-Deploy Verification

After deploying, run `/bug-report verify [BUG-ID]` to confirm the fix resolved the issue in the deployed build.

If VERIFIED FIXED: run `/bug-report close [BUG-ID]` to formally close it.
If STILL PRESENT: the hotfix failed — immediately re-open, assess rollback, and escalate.
If CANNOT VERIFY: the fix is unconfirmed — do not close the bug; play its reproduction steps in the deployed build, then run `/bug-report verify [BUG-ID]` again and answer its manual-play question to settle it.

Schedule a post-incident review within 48 hours. `/retrospective` reviews a
sprint or milestone, not an incident: record the review with
`.claude/docs/templates/incident-response.md`, and raise its lessons at the next
`/retrospective`.

Use `AskUserQuestion`:
- Prompt: "Hotfix complete. What's the next step?"
- Options:
  - `[A] Run /smoke-check to verify the fix`
  - `[B] Run /patch-notes to document this hotfix`
  - `[C] Stop here`
