# /smoke-check — Phase 6: Write and Gate

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 6: Write and Gate

**In this file:**

- `qa.level` first
- Resolve the gate enforcement level
- Per verdict: FAIL (blocking or advisory), NOT ASSESSED, PASS WITH WARNINGS, PASS

Present the full report in conversation, then ask:

"May I write this smoke check report to `production/qa/smoke-[date].md`?"

Write only after approval.

**First apply `qa.level` (resolved earlier).** At `qa.level: minimal`, a FAIL is
**advisory** regardless of `testing.strict.config` — skip the resolution below and
deliver the advisory-FAIL outcome (smoke-check is optional at minimal and never
blocks hand-off). Otherwise:

**Resolve the gate enforcement level.** A FAIL verdict either *blocks* QA
hand-off or is *flagged while hand-off proceeds*, governed by the
`testing.strict` block **resolved in the resolved-config block at the top of this skill** (which merges
`project.local.yaml` over `project.yaml` — read that block, not the file, or a
developer's local override is silently ignored):

1. Take `testing.strict.config` from that resolved block. If its value is `true`
   (case-insensitive) → blocking; if `false` → advisory; `unset` → fall through.
2. Else read `testing.strict` as a plain boolean (legacy single-value form) — if
   its value is `true` or `false`, it applies.
3. Else default to **blocking** — an unset `testing.strict.config` keeps
   smoke-check's FAIL gate blocking (behavior unchanged from before this setting
   existed). Smoke check is a build-health gate, so its unset default is strict
   even though the `config` test type defaults to advisory elsewhere. The
   reciprocal carve-out is recorded in `.claude/skills/story-done/SKILL.md` and
   `.claude/docs/coding-standards.md`, which own the per-story evidence table.

Only `true` and `false` (case-insensitive) are recognized at steps 1–2. A key
that is present but holds any other value — `maybe`, `1`, `yes`, etc. — is
treated as unset: continue to the next step, and surface the unrecognized value
to the user.

After writing, deliver the gate verdict:

**If verdict is FAIL and the gate is blocking:**

"The smoke check failed. Do not hand off to QA until these failures are
resolved:

[List each failing automated test or smoke check with a one-line description]

Fix the failures and run `/smoke-check` again to re-gate before QA hand-off."

**If verdict is FAIL and the gate is advisory** (`testing.strict.config: false`):

"The smoke check failed, but `testing.strict.config` is set to advisory — QA
hand-off is not blocked. Resolve these before release:

[List each failing automated test or smoke check with a one-line description]

QA hand-off: share `production/qa/qa-plan-[sprint].md` with the qa-tester
agent to begin manual verification. Re-run `/smoke-check` once the failures
are fixed."

**If verdict is NOT ASSESSED:**

"The smoke check could not establish build health — it did not fail, it did not
run. Do not hand off to QA on this result:

[Name each check that could not execute, and why: suite unconfirmed NOT RUN,
`PlayMode: NOT RUN`, zero tests executed, runner not installed, engine
executable not found, no build, build not launched this session, platform
unavailable]

[For each, the one thing that would make it runnable — e.g. 'confirm the suite
result from your IDE or CI', 'run `/setup-engine`', 'set `engine.path`',
'produce a build', 'launch the build and play the checks'.]

Re-run `/smoke-check` once any of those is resolved."

This outcome is **not governed by `testing.strict.config`**. That setting decides
whether a *failure* blocks hand-off; it has nothing to say about a check that
never produced a result, and reading an unrun check as advisory-therefore-fine is
the exact substitution this verdict exists to prevent. Say what could not be
checked and let the user decide — do not resolve it to either pass or FAIL on
their behalf.

**If verdict is PASS WITH WARNINGS:**

"Smoke check passed with warnings. The build is ready for manual QA.

Advisory items to resolve before running `/story-done` on affected stories:
[list MISSING test evidence entries, and any runner warning — e.g. the orphan
count]

QA hand-off: share `production/qa/qa-plan-[sprint].md` with the qa-tester
agent to begin manual verification."

**If verdict is PASS:**

"Smoke check passed cleanly. The build is ready for manual QA.

QA hand-off: share `production/qa/qa-plan-[sprint].md` with the qa-tester
agent to begin manual verification."

---
