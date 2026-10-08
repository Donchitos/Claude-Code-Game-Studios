# /story-done — Phase 6: Present the Completion Report

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 6: Present the Completion Report

**In this file:**

- The completion report template
- Verdict definitions
- `NOT ASSESSED` and verdict precedence

Before updating any files, present the full report:

```markdown
## Story Done: [Story Name]
**Story**: [file path]
**Date**: [today]

### Acceptance Criteria: [X/Y passing]
- [x] [Criterion 1] — auto-verified (test file present)
- [x] [Criterion 2] — confirmed
- [ ] [Criterion 3] — FAILS: [reason]
- [?] [Criterion 4] — DEFERRED: requires playtest

### Test-Criterion Traceability
| Criterion | Test | Status |
|-----------|------|--------|
| AC-1: [text] | [test file::test name] | COVERED |
| AC-2: [text] | Manual confirmation | COVERED |
| AC-3: [text] | — | UNTESTED |

### Test Evidence
**Story Type**: [Logic | Integration | Visual/Feel | UI | Config/Data | Not declared]
**Required evidence**: [unit test file | integration test or playtest | screenshot + sign-off | screenshot of each screen touched | smoke check pass]
**Evidence found**: [YES — `[path]` | NO — BLOCKING | NO — ADVISORY]

### Deviations
[NONE] OR:
- BLOCKING: [description] — [GDD/ADR reference]
- ADVISORY: [description] — user accepted / flagged for tech debt

### Scope
[All changes within stated scope] OR:
- Extra files touched: [list] — [note whether valid or scope creep]

### Verdict: COMPLETE / COMPLETE WITH NOTES / NOT ASSESSED / BLOCKED
```

**Verdict definitions:**
- **COMPLETE**: all criteria pass, no blocking deviations
- **COMPLETE WITH NOTES**: every criterion passes or is `DEFERRED` (Phase 3 —
  evaluable, awaiting a playtest), with advisory deviations or deferred criteria
  documented — list each DEFERRED criterion so it is not lost
- **NOT ASSESSED**: one or more acceptance criteria could not be evaluated at
  all — name which, and why
- **BLOCKED**: failing criteria or blocking deviations must be resolved first

**`NOT ASSESSED` — the story nobody could verify.** Rank: it **outranks COMPLETE
and COMPLETE WITH NOTES** (a review that could not evaluate a criterion has not
shown the criterion is met) and **ranks below BLOCKED** (a criterion known to
fail is more actionable than one nobody could check, and demoting it would bury
it). It is not a gentler BLOCKED: "this acceptance criterion fails" and "I could
not tell whether it passes" send the reader to different fixes.

**Verdict precedence — first matching rule wins**, evaluated in this order:
**BLOCKED**, then **NOT ASSESSED**, then **COMPLETE WITH NOTES**, then
**COMPLETE**. A run with both a failing criterion and an unassessable one is
BLOCKED. Stating the order mechanically, rather than leaving it to be inferred
from the rank sentence, is what keeps two reviewers from grading the same story
differently.

Emit it when any of:

- An acceptance criterion **cannot be evaluated at all** — it names no observable
  outcome, so no evidence could settle it either way.
  > **Not the same as Phase 3's `DEFERRED`.** A criterion that is evaluable but
  > needs a playtest is `DEFERRED — requires playtest session`, it does **not**
  > block, and Phase 3 keeps ownership of it. This trigger is for a criterion no
  > session could ever settle as written. If Phase 3 already marked it DEFERRED,
  > that classification stands and this trigger does not fire.
- A criterion the user answered **`Not tested yet`** (Phase 3) — it could be
  checked, but nobody has. Name it and what would settle it: launch the build,
  check it, then re-run `/story-done`.
- QL-TEST-COVERAGE or LP-CODE-REVIEW returned **NOT ASSESSED** and the input it
  named was not supplied.
- The **test evidence is present but unreadable or unclassifiable** — corrupt,
  empty, or of a type that cannot be determined.
  > **Absent evidence is Phase 3's, not this trigger's.** Phase 3 resolves a
  > missing file through `testing.strict`: BLOCKING types produce **BLOCKED**,
  > ADVISORY types produce **COMPLETE WITH NOTES**. Both outrank or are already
  > decided, so re-routing "absent" here would silently override an explicit
  > advisory ruling. *Unreadable* is the genuinely unassessable case, and it is
  > the only one this trigger claims.
- **`/test-evidence-review` returned `NOT ASSESSED`** for this story — applicable
  only when that skill was actually run against it, which this skill does not do
  itself. It
  propagates: that skill's whole point is that "could not check" is not
  "checked and fine", and collapsing its unknown into a COMPLETE here would undo
  the distinction one skill downstream. `coding-standards.md` marks Logic and
  Integration evidence BLOCKING, so this is the path where an unverifiable story
  would otherwise acquire a verdict saying somebody verified it.
- A **deviation's severity cannot be determined** because the GDD or ADR it
  would be judged against is missing.

A `NOT ASSESSED` verdict takes the same Phase 7 path as BLOCKED: do not
automatically proceed, list what could not be checked and what would make it
checkable. Closing anyway remains the user's explicit call, and stays gated by
Phase 7's `scope_changes` always-ask rule.

If the verdict is **BLOCKED**: do not *automatically* proceed to Phase 7. List
what must be fixed and offer to help fix the blocking items. This is the
default path, not an absolute stop — the user may still explicitly ask to
close the story anyway despite the blockers. That request is what routes to
Phase 7's menu below, and Phase 7's own `scope_changes` always-ask rule is
exactly what stands between that request and a silent close in autonomous
mode. Do not treat "do not automatically proceed" as "Phase 7 is now
unreachable" — it is reachable, on request, and gated when reached.

---
