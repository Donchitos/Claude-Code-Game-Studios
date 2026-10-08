---
name: bug-report
description: "Structured bug report from a description, or analyze code for potential bugs. Reproduction steps, severity."
argument-hint: "[description] | analyze [path-to-file] | verify [BUG-ID] | close [BUG-ID]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/bug-report/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Bug Report

## Phase 1: Parse Arguments

Determine the mode from the argument:

- No keyword → **Description Mode**: generate a structured bug report from the provided description
- `analyze [path]` → **Analyze Mode**: read the target file(s) and identify potential bugs
- `verify [BUG-ID]` → **Verify Mode**: confirm a reported fix actually resolved the bug
- `close [BUG-ID]` → **Close Mode**: mark a verified bug as closed with resolution record

If no argument is provided, ask the user for a bug description before proceeding.

---

## Phase 2A: Description Mode

1. **Parse the description** for key information: what broke, when, how to reproduce it, and what the expected behavior is.

2. **Search the codebase** for related files using Grep/Glob to add context (affected system, likely files).

3. **Draft the bug report**:

```markdown
# Bug Report

## Summary
**Title**: [Concise, descriptive title]
**ID**: BUG-[NNNN]
**Severity**: [S1-Critical / S2-High / S3-Medium / S4-Low]
**Priority**: [P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix]
**Status**: Open
**Reported**: [Date]
**Reporter**: [the reporter's name as the user gives it, else `—`; never an email address or account ID taken from the session]

## Classification
- **Category**: [Gameplay / UI / Audio / Visual / Performance / Crash / Network]
- **System**: [Which game system is affected — when the bug spans systems, the one whose code must change; the others go under Related systems]
- **Frequency**: [Always / Often (>50%) / Sometimes (10-50%) / Rare (<10%)]
- **Regression**: [Yes/No/Unknown -- was this working before?]

## Environment
- **Build**: [Version or commit hash]
- **Platform**: [OS, hardware if relevant]
- **Scene/Level**: [Where in the game]
- **Game State**: [Relevant state -- inventory, quest progress, etc.]

## Reproduction Steps
**Preconditions**: [Required state before starting]

1. [Exact step 1]
2. [Exact step 2]
3. [Exact step 3]

**Expected Result**: [What should happen]
**Actual Result**: [What actually happens]

## Technical Context
- **Likely affected files**: [List of files based on codebase search]
- **Related systems**: [What other systems might be involved]
- **Possible root cause**: [If identifiable from the description]

## Evidence
- **Logs**: [Relevant log output if available]
- **Visual**: [Description of visual evidence]

## Related Issues
- [Links to related bugs or design documents]

## Notes
[Any additional context or observations]
```

The **Severity** and **Priority** labels use `/bug-triage`'s S and P numbers and
names, which it parses out of this file. `P4-Won't fix` is its `P4 — Won't fix /
Deferred` (an accepted risk), not a wishlist. If you change either ladder, change
`.claude/skills/bug-triage/SKILL.md` too.

---

## Phase 2B: Analyze Mode

1. **Read the target file(s)** specified in the argument.

2. **Identify potential bugs**: null references, off-by-one errors, race conditions, unhandled edge cases, resource leaks, incorrect state transitions.

3. **For each potential bug**, generate a bug report using the template above, with the likely trigger scenario and recommended fix filled in.

---

## Phase 2C: Verify Mode

**Find the bug file by its number**, here and in close mode: Glob
`production/qa/bugs/BUG-*.md` and take the file whose number matches `[BUG-ID]`,
whatever its zero-padding — an older three-digit file with a slug is found by
its number too. If none
matches, stop: "No bug [BUG-ID] in `production/qa/bugs/`." Verdict: **BLOCKED**
— no such bug.

Read that file. Extract the reproduction steps and expected result.

1. **Re-run reproduction steps** — use Grep/Glob to check whether the root cause code path still exists as described. If the fix removed or changed it, note the change.
2. **Run the related test** — if the bug's system has a test file in the engine's test root (`tests/` Godot, `Assets/Tests/` Unity, `Source/<Module>/Private/Tests/` Unreal — `.claude/docs/directory-structure.md`), run it via Bash with `commands.test` from `project.yaml`, narrowed to the affected suite where the runner allows — never a runner line written from memory, which drops the flags the engine needs (gdUnit4 hangs without `--remote-debug tcp://127.0.0.1:0`) — and report pass/fail. `commands.test` unset → no test ran: name the unset key and go on to step 3.
3. **Check for regression** — grep the codebase for any new occurrence of the pattern that caused the bug.
4. **Manual verification** — when no related test ran (none covers the bug — the usual case where `qa.level` waives tests — `commands.test` is unset, or the run did not complete), or the bug's Category is Visual or UI, whose look no automated test checks, ask via `AskUserQuestion`: "Did you play the reproduction steps in [bug file] on a build with the fix? Which build?" —
   `[No longer occurs]` / `[Still occurs]` / `[Not played yet]`.
   Record the answer and the build as the user gives them; a changed code path is never taken as their answer.

Produce a verification verdict:

- **VERIFIED FIXED** — the bug is gone by every check that applies: any related test ran and passed, and, where step 4 asked, the user answered `[No longer occurs]` for a named build. With no test run, that play alone is the verification — a manual one, recorded as such: `[user], manual, build [X]`. A changed code path on its own is never a pass
- **STILL PRESENT** — a related test fails on the bug's case, or the user answered `[Still occurs]`; the fix did not resolve the issue
- **CANNOT VERIFY** — step 4 was answered `[Not played yet]`: name what is missing or could not run (no related test, `commands.test` unset, a run that did not complete, a Visual or UI bug), and say that playing the reproduction steps settles it — run `/bug-report verify [BUG-ID]` again once played

Ask: "May I update `production/qa/bugs/[bug file]` to set Status: Verified Fixed / Still Present / Cannot Verify?" — naming the file found above, whatever its padding or slug. With the Status, write a `**Verified by**:` line under it: `[test file(s)] — ran and passed`, or `[user], manual, build [X]` for a manual verification.

If STILL PRESENT: reopen the bug, set Status back to Open, and suggest re-running `/hotfix [BUG-ID]`.

---

## Phase 2D: Close Mode

Read the bug file, found by its number as in verify mode. Confirm Status is `Verified Fixed` before closing. If status is anything else, stop: "Bug [ID] must be Verified Fixed before it can be closed. Run `/bug-report verify [BUG-ID]` first."

Show the closure record below and the Status change, then ask: "May I update `production/qa/bugs/[bug file]` to mark it Closed?" Nothing is written before a yes; on no, stop — the bug stays Verified Fixed.

On yes, append the closure record to the bug file:

```markdown
## Closure Record
**Closed**: [date]
**Resolution**: Fixed — [one-line description of what was changed]
**Fix commit / PR**: [if known]
**Verified by**: [the verify record's `**Verified by**:` line — the test that ran and passed, or "[user], manual, build [X]"]
**Closed by**: [user]
**Regression test**: [test file path, or "Manual verification" when verify recorded a manual play]
**Status**: Closed
```

Then update the top-level `**Status**:` field to `**Status**: Closed`.

After closing, check `production/qa/bug-triage-*.md` — if the bug appears in an open triage report, note: "Bug [ID] is referenced in the triage report. Run `/bug-triage` to refresh the open bug count."

---

## Phase 3: Save Report

Present the completed bug report(s) to the user.

**Allocate the ID** before asking: Glob `production/qa/bugs/BUG-*.md`, take the
highest number and add 1, zero-padded to four digits (`BUG-0001` when there are
none). Several reports in one run (analyze mode) take consecutive IDs from
there, one each — never the same ID twice.

Ask: "May I write this to `production/qa/bugs/BUG-[NNNN].md`?" For several
reports, ask once and name every file: "May I write these to
`production/qa/bugs/BUG-[NNNN].md`, `production/qa/bugs/BUG-[NNNN+1].md`, …?"

If yes, write the file, creating the directory if needed. Verdict: **COMPLETE** — bug report filed.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 4: Next Steps

After saving, suggest based on mode:

**After filing (Description/Analyze mode):**
- Run `/bug-triage` to prioritize alongside existing open bugs
- If S1 or S2: run `/hotfix [BUG-ID]` for emergency fix workflow

**After fixing the bug (developer confirms fix is in):**
- Run `/bug-report verify [BUG-ID]` — confirm the fix actually works before closing
- Never mark a bug closed without verification — a fix that doesn't verify is still Open

**After verify returns CANNOT VERIFY:**
- Play the reproduction steps on a build with the fix, then run `/bug-report verify [BUG-ID]` again and answer its question

**After verify returns VERIFIED FIXED:**
- Run `/bug-report close [BUG-ID]` — write the closure record and update status
- Run `/bug-triage` to refresh the open bug count and remove it from the active list
