# /smoke-check — Phase 5: Generate Report

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 5: Generate Report

**In this file:**

- The report template, with the verdict rules
- `NOT ASSESSED` and where it ranks

Assemble the full smoke check report:

````markdown
## Smoke Check Report
**Date**: [date]
**Sprint**: [sprint name / number, or "Not identified"]
**Engine**: [engine]
**QA Plan**: [path, or "Not found — run /qa-plan first"]
**Argument**: [sprint | quick | blank]

---

### Automated Tests

**Status**: [PASS ([N] tests, [N] passing) | PASS WITH WARNINGS ([N] tests
passing; [the runner's warning, e.g. [N] orphan nodes leaked]) | FAIL ([N]
failures, or did not complete: [timeout | compile, parse or build error | no
results file]) | NOT ASSESSED ([reason, e.g. zero tests executed, runner could
not run]) | NOT RUN ([reason]) | WAIVED (qa.level: minimal — no game tests)]

[Unity: one Status line per test platform — `EditMode:` and `PlayMode:`.]

[WAIVED only:] **Build check**: [PASS — `[command]` exit 0 | FAIL — [reason] |
NOT RUN — [commands.smoke and commands.build unset | executable not found]]

[If FAIL, list failing tests:]
- `[test name]` — [brief failure description from runner output]

[If NOT RUN:]
"Manual confirmation required: did tests pass in your local IDE or CI? This
will determine whether the automated test row contributes to a FAIL verdict."

---

### Test Coverage

| Story | Type | Test File | Coverage Status |
|-------|------|-----------|----------------|
| [title] | Logic | `tests/unit/[system]/[slug]_test.[ext]` | COVERED |
| [title] | Visual/Feel | `production/qa/evidence/[slug]-screenshots.md` | MANUAL |
| [title] | Logic | — | MISSING ⚠ |
| [title] | Config/Data | — | EXPECTED |

**Summary**: [N] covered, [N] manual, [N] missing, [N] expected.

---

### Manual Smoke Checks

- [x] Build launched this session — yes [or: `NOT RUN — build not launched this session`; the batches below were not asked]
- [x] Game launches without crash — PASS
- [x] New game starts — PASS
- [x] [Core mechanic] — PASS
- [ ] [Other check] — FAIL: [user's description]
- [x] Save / load — PASS
- [-] Performance — not checked this session

---

### Missing Test Evidence

Stories that must have test evidence before they can be marked COMPLETE via
`/story-done`:

- **[story title]** (`[path]`) — Logic story has no test file.
  Expected location: `tests/unit/[system]/[story-slug]_test.[ext]`

[If none:] "All Logic and Integration stories have test coverage."

---

### Platform-Specific Results *(only if `--platform` was provided)*

| Platform | Checks Run | Passed | Failed | Platform Verdict |
|----------|-----------|--------|--------|-----------------|
| PC | [N] | [N] | [N] | PASS / FAIL |
| Console | [N] | [N] | [N] | PASS / FAIL |
| Mobile | [N] | [N] | [N] | PASS / FAIL |

**Platform notes**: [any platform-specific observations not captured in pass/fail]

Any platform with one or more FAIL checks contributes to the overall FAIL verdict.

---

### Verdict: [PASS | PASS WITH WARNINGS | NOT ASSESSED | FAIL]

[Verdict rules — first matching rule wins:]

**FAIL** if ANY of:
- Automated test suite ran and reported one or more test failures
- The automated suite did not complete: a timeout, a compile, parse or build
  error, or no results file after the run (Phase 2 names each engine's form)
- The build check (WAIVED path) failed: a non-zero exit, a timeout, or a Godot
  `SCRIPT ERROR` or no-main-scene line
- Any Batch 1 (core stability) check returned FAIL
- Any Batch 2 (primary sprint mechanic or regression check) returned FAIL

**NOT ASSESSED** if ANY of:
- The automated suite is **unconfirmed NOT RUN** — nobody has reported a result
- The runner could not run (gdUnit4 103 or 104, gdUnit4 or the Unity Test
  Framework not installed), or it ran and executed zero tests
  (`No test cases found`, `testcasecount="0"`, `No automation tests matched`)
- Unity Play Mode tests exist and are `PlayMode: NOT RUN`, unconfirmed — the
  Edit Mode result does not cover them
- A Batch 1 or Batch 2 check could not be executed (no build, engine not
  configured, platform unavailable) as opposed to executing and failing —
  including a Batch 1 answer that the build was not launched this session
- **Any story's coverage row is `UNKNOWN`** (Phase 3: story file missing or
  unreadable). A story nobody could read is not a story with no gaps — without
  this line, a run where *every* row is UNKNOWN and the suite passes matches
  **PASS**, because PASS only requires "no MISSING entries"
- **Batch 3 was offered and skipped** ("Performance not checked this session").
  It is not a FAIL, not an execution failure, and not "PASS or N/A", so without
  this line it matches no rule at all and renders as `[-]` beside a PASS

**PASS WITH WARNINGS** if ALL of:
- Automated tests PASS or PASS WITH WARNINGS, WAIVED at `qa.level: minimal`, or
  NOT RUN **and the developer has confirmed the result from their local IDE or CI**
- All Batch 1 and Batch 2 smoke checks PASS
- At least one warning: a Logic/Integration story with MISSING test evidence,
  a runner warning on a passing suite (gdUnit4 101 — orphan nodes leaked), or
  a NOT RUN suite the developer confirmed

**PASS** if ALL of:
- Automated tests PASS, or WAIVED (`qa.level: minimal` and no game tests exist —
  the build check, when `commands.smoke` or `commands.build` is set, and the
  launch and critical-path batches below then carry the verdict)
- All smoke checks in all batches PASS or N/A
- No MISSING test evidence entries
````

**`NOT ASSESSED` — the build nobody could check.** Rank: it **outranks PASS and
PASS WITH WARNINGS** and **ranks below FAIL**. A suite that never ran has not
shown the build is healthy; a suite that ran and failed is the more actionable
finding and must not be demoted behind one that did not run.

This is a change in where unconfirmed `NOT RUN` lands, and it is deliberate. The
rule below — **never treat NOT RUN as an automatic FAIL** — is unchanged and
still correct: NOT ASSESSED is not a FAIL, and it ranks below one. What changes
is that an unrun suite no longer resolves to a *pass* verdict while waiting for a
confirmation that may never come. Confirmed NOT RUN (the developer reports the
result from their own IDE or CI) still lands at PASS WITH WARNINGS, because
somebody did look.

---
