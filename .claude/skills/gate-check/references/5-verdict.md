# /gate-check — Sections 5 and 5a: Verdict and Chain-of-Verification

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 5. Output the Verdict

**In this file:**

- 5. Output the Verdict: the report, `NOT ASSESSED`, verdict precedence
- 5a. Chain-of-Verification: Steps 1-4

```
## Gate Check: [Current Phase] → [Target Phase]

**Date**: [date]
**Checked by**: gate-check skill

### Required Artifacts: [X/Y present]
- [x] design/gdd/game-concept.md (design/game-brief.md at `minimal`) — exists, 2.4KB
- [ ] docs/architecture/ — MISSING (no ADRs found)
- [x] production/sprints/ — exists, 1 sprint plan

### Quality Checks: [X/Y passing]
- [x] GDD has 8/8 required sections
- [ ] Tests — FAILED (3 failures in tests/unit/)
- [?] Core loop playtested — MANUAL CHECK NEEDED

### Blockers
1. **No Architecture Decision Records** — Run `/architecture-decision` to create one
   covering core system architecture before entering production.
2. **3 test failures** — Fix failing tests in tests/unit/ before advancing.

### Recommendations
- [Priority actions to resolve blockers]
- [Optional improvements that aren't blocking]

### Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]
- **PASS**: All required artifacts present, all quality checks passing
- **CONCERNS**: Minor gaps exist but can be addressed during the next phase —
  the stage advances only if the user explicitly accepts them (Section 6)
- **FAIL**: Critical blockers must be resolved before advancing
- **NOT ASSESSED**: One or more required checks could not be run at all — name
  which, and why, in the Blockers section

### Accepted Risks (only when the user advanced on CONCERNS)
- [each concern, as listed above] — accepted by the user, [date]
```

**`NOT ASSESSED` — when the gate could not look.** Rank: it **outranks PASS**
(a gate that could not check part of its scope has not established the phase is
ready) and **ranks below CONCERNS and FAIL** (a known blocker is more actionable
than an unknown, and demoting it behind an access problem buries it). It is not a
softer FAIL: "I checked and found a blocker" and "I could not check" need
different fixes — one needs work done, the other needs the input produced or made
readable.

**Verdict precedence — first matching rule wins**, evaluated in this order:
**FAIL**, then **CONCERNS**, then **NOT ASSESSED**, then **PASS**. A gate with
both a real blocker and an unassessable check is FAIL: the blocker is the
actionable finding. Stating the order mechanically removes the inference — the
rank sentence above says what outranks what, but only an ordered list says what
to do when two conditions hold at once.

Emit it when any of:

- A **required artifact exists but cannot be assessed** — empty, unreadable, or
  still entirely `[TO BE CONFIGURED]` / template placeholders. Present-but-empty
  is the case that most looks like present.
- A **quality check's input carries no measured data**. Section 3 compares the
  performance budgets against "profiling data in `tests/performance/` or recent
  `/perf-profile` output" — and `/perf-profile`'s report template pre-fills
  `[16.67ms]` as the budget, so it can render ">99% headroom" from zero profiler
  data. Placeholder numbers are not measurements: a budget nobody set is not a
  budget that was met. Absent data already prompts (Section 4 offers to run
  `/perf-profile`); this covers data that is *present and hollow*, which is the
  case that looks like a measurement.
- A **test check the tier requires could not be executed** — no test runner is
  configured, or the runner is configured but failed to start. Section 3 runs the
  suite "if a test runner is configured", and an unconfigured runner produced no
  failures, so the test check contributed nothing to the verdict and the gate
  could still reach PASS. Meanwhile `testing.strict.logic` and
  `.integration` both default to `true`, so the project's own configuration
  called those gates BLOCKING. A blocking gate that never ran is the unknown this
  verdict exists to name. Remediation is already listed under Common Gaps
  (`/test-setup`); this is what the verdict does with it.

  > **Scope this to tiers that require tests.** At `qa.level: minimal` no test
  > gates apply at all (see the config block above), so a missing runner there is
  > the configured posture, not a hole — firing the trigger would make every
  > `minimal` gate permanently NOT ASSESSED and stop stage advancement, the same
  > over-broad reading the director trigger below warns against. Fires only where
  > the resolved tier actually asked for the test check.
- A **`MANUAL CHECK NEEDED` item the user never resolved**. Section 4 already
  refuses to assume PASS for unverifiable items and marks them this way — but
  until now the verdict vocabulary had nowhere to put one, so an unresolved
  manual check had to land inside PASS, CONCERNS or FAIL anyway. This is where it
  goes.
- A director the **resolved tier was supposed to spawn** did not return — it
  errored, produced no verdict, or was interrupted.

  > **Scope this narrowly, and do not read it as "fewer than four directors ran".**
  > Section 4b narrows the panel *by design* — 1 director at `minimal`, 2 at
  > `standard`, 4 at `full`, and none in `solo` — and that narrowing is a
  > deliberate, announced reduction, not a failure to assess. The broad reading
  > makes every `minimal`, `standard` and `solo` gate permanently NOT ASSESSED,
  > which means the verdict can never be PASS and Section 6 can never advance
  > `project.stage`. **That would break stage advancement for most projects,**
  > since those are the common tiers. The trigger fires only when a director the
  > tier *did* call for fails to come back — a hole in the panel you expected,
  > never the panel you deliberately chose.
- A referenced upstream verdict is itself `NOT ASSESSED` — it propagates upward
  rather than resolving to a pass.

Never resolve an unknown by assuming the permissive reading. If the check could
not run, that fact is the finding.

---

## 5a. Chain-of-Verification

After drafting the verdict in Phase 5, challenge it before finalising.

**Step 1 — Generate 5 challenge questions** designed to disprove the verdict:

> **Tool-action requirement**: At least 2 of the 5 challenge questions below must be answered by re-reading a specific file (Read tool) or re-running a specific check (Grep tool) — not by reflection alone. Mark these with [TOOL ACTION] to indicate a tool was used.

For a **PASS** draft:
- "Which quality checks did I verify by actually reading a file, vs. inferring they passed?"
- "Are there MANUAL CHECK NEEDED items I marked PASS without user confirmation? [TOOL ACTION] Re-scan the checklist for any [?] or MANUAL CHECK items."
- "Did I confirm all listed artifacts have real content, not just empty headers? [TOOL ACTION] Re-read the file and check it has non-placeholder content."
- "Could any blocker I dismissed as minor actually prevent the phase from succeeding?"
- "Which single check am I least confident in, and why?"

For a **CONCERNS** draft:
- "Could any listed CONCERN be elevated to a blocker given the project's current state?"
- "Is the concern resolvable within the next phase, or does it compound over time?"
- "Did I soften any FAIL condition into a CONCERN to avoid a harder verdict?"
- "Are there artifacts I didn't check that could reveal additional blockers?"
- "Do all the CONCERNS together create a blocking problem even if each is minor alone?"

For a **FAIL** draft:
- "Have I accurately separated hard blockers from strong recommendations?"
- "Are there any PASS items I was too lenient about?"
- "Am I missing any additional blockers the user should know about?"
- "Can I provide a minimal path to PASS — the specific 3 things that must change?"
- "Is the fail condition resolvable, or does it indicate a deeper design problem?"

**Step 2 — Answer each question** independently.
Do NOT reference the draft verdict text — re-check specific files or ask the user.

**Step 3 — Revise if needed:**
- If any answer reveals a missed blocker → upgrade verdict (PASS→CONCERNS or CONCERNS→FAIL)
- If any answer reveals a check that **could not be run** rather than one that
  ran and passed → PASS→NOT ASSESSED. The first two PASS-draft questions above
  ("verified by actually reading a file, vs. inferring", "MANUAL CHECK NEEDED
  items I marked PASS") exist to find exactly this, and until now a yes to either
  had no verdict to move to
- If any answer reveals an over-stated blocker → downgrade only if citing specific evidence
- Never revise NOT ASSESSED down to PASS by re-reasoning about the missing input.
  Only obtaining the input clears it
- If answers are consistent → confirm verdict unchanged

**Step 4 — Note the verification** in the final report output:
`Chain-of-Verification: [N] questions checked — verdict [unchanged | revised from X to Y]`

---
