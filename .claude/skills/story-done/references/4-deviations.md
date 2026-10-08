# /story-done — Phases 4 and 4b: Deviations and QA Coverage Gate

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: Check for Deviations

Compare the implementation against the design documents.

> **Workflow tier adjustment** (resolved in Phase 1, per the story's system).
> Checks 1 (GDD rules) and 3 (ADR constraints) below are the `full` baseline:
> - **`full`** — run both: full GDD traceability against the current TR text +
>   the ADR constraints check.
> - **`standard`** — run the GDD rules check against the **5 required sections**;
>   run the ADR constraints check only where a **critical ADR** governs the story.
> - **`minimal`** — **acceptance-criteria check only**: skip checks 1 and 3 (no
>   GDD/ADR traceability expected). Checks 2 (manifest), 4 (hardcoded values), and
>   5 (scope) still run as written.
>
> This adjustment governs only the Phase 4 *deviation* checks. The test-evidence
> gates (Phase 3 traceability, Phase 4b QA coverage) are governed by `qa.level`
> and `testing.strict`, not `workflow` — they run independently of the tier here.

Run these checks automatically:

1. **GDD rules check**: Using the current requirement text from `tr-registry.yaml`
   (looked up by the story's TR-ID), check that the implementation reflects what
   the GDD actually requires now — not what it required when the story was written.
   `Grep` the implemented files for key function names, data structures, or class
   names mentioned in the current GDD section.

2. **Manifest version staleness check**: Compare the `Manifest Version:` date
   embedded in the story header against the `Manifest Version:` date in the
   current `docs/architecture/control-manifest.md` header.
   - If they match → pass silently.
   - If the story's version is older → flag as ADVISORY:
     `ADVISORY: Story was written against manifest v[story-date]; current manifest
     is v[current-date]. New rules may apply. Run /story-readiness to check.`
   - If control-manifest.md does not exist → skip this check.

3. **ADR constraints check**: Use the ADR's `## Decision` section already
   loaded in Phase 2 — do not read the ADR file again. Check for forbidden
   patterns from `docs/architecture/control-manifest.md` (if it exists).
   `Grep` for patterns explicitly forbidden in the ADR.

4. **Hardcoded values check**: `Grep` the implemented files for numeric literals
   in gameplay logic that should be in data files.

5. **Scope check**: Did the implementation touch files outside the story's stated
   scope? (files not listed in "files to create/modify")

For each deviation found, categorize:

- **BLOCKING** — implementation contradicts the GDD or ADR (must fix before
  marking complete)
- **ADVISORY** — implementation drifts slightly from spec but is functionally
  equivalent (document, user decides)
- **OUT OF SCOPE** — additional files were touched beyond the story's stated
  boundary (flag for awareness — may be valid or scope creep)

---

## Phase 4b: QA Coverage Gate

**Skip this phase entirely at `qa.level: minimal`** (resolved in Phase 1) — no
test evidence is required, so there is no coverage to review. Note: "QL-TEST-COVERAGE
skipped — qa.level minimal." Proceed to Phase 5.

**Review mode check** — apply before spawning QL-TEST-COVERAGE:
- `solo` → skip. Note: "QL-TEST-COVERAGE skipped — Solo mode." Proceed to Phase 5.
- `lean` → skip (not a PHASE-GATE). Note: "QL-TEST-COVERAGE skipped — Lean mode." Proceed to Phase 5.
- `full` → spawn as normal.

After completing the deviation checks in Phase 4, spawn `qa-lead` via `Agent` using gate **QL-TEST-COVERAGE** (`.claude/docs/director-gates/ql-test-coverage.md`).

Pass:
- The story file path and story type
- Test file paths found during Phase 3 (exact paths, or "none found")
- The story's `## QA Test Cases` section (the pre-written test specs from story creation)
- The story's `## Acceptance Criteria` list
- The GDD acceptance criteria and Edge Cases for the story's system, from the GDD
  section read in Phase 2 — or "no GDD for this system" when there is none (at
  `workflow: minimal` the story's own criteria are the spec); an absent GDD is
  information for the gate, not a missing input

The qa-lead reviews whether the tests actually cover what was specified — not just whether files exist.

Apply the verdict:
- **ADEQUATE** → proceed to Phase 5
- **GAPS** → flag as **ADVISORY**: "QA lead identified coverage gaps: [list]. Story can complete but gaps should be addressed in a follow-up story."
- **INADEQUATE** → flag as **BLOCKING**: "QA lead: critical logic is untested. Verdict cannot be COMPLETE until coverage improves. Specific gaps: [list]."
- **NOT ASSESSED [missing input]** → no judgement was made; never read it as ADEQUATE. Name the missing input — supply it and re-run the gate, or carry it to Phase 6, where it keeps the verdict at best NOT ASSESSED.

Skip this phase for Config/Data stories (no code tests required).

---
