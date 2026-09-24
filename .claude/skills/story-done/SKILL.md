---
name: story-done
description: "End-of-story completion review — verifies each acceptance criterion, checks GDD/ADR deviations, prompts code review, updates status."
argument-hint: "[story-file-path] [--review full|lean|solo]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/story-done/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,story_granularity,qa.level,testing.strict,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.


# Story Done

This skill closes the loop between design and implementation. Run it at the end
of implementing any story. It ensures every acceptance criterion is verified
before the story is marked done, GDD and ADR deviations are explicitly
documented rather than silently introduced, code review is prompted rather than
forgotten, and the story file reflects actual completion status.

**Output:** Updated story file (Status: Complete) + surfaced next story.

---

## Phase 1: Find the Story


See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Workflow tier**: resolved per the story's system (per
`.claude/docs/workflow-modes.md`) — **the GDD filename stem** of the story's
`GDD:` path (`design/gdd/<stem>.md` → `<stem>`), with the `[system]` segment of
its `TR-[system]-NNN` ID accepted only as a fallback alias: use the
`system_overrides` row for that system if the block lists one, else the
project value. It governs which Phase 4 deviation checks run — see Phase 4.

**Workflow companion — `modes.story_granularity`** (resolved above — supplied by
`modes.rigor` unless set explicitly): cadence expectation only — story-done fires **every 3–5 days** at
`coarse`, **every 1–2 days** at `balanced`, **multiple times/day** at `fine`. It
does not change any completion check.

**`qa.level`**: controls whether test *evidence is required*, where
`testing.strict` controls whether a failure blocks and `workflow` controls which
docs exist. `modes.rigor` sets `qa.level` and `workflow` together; set either
explicitly to vary it alone. `testing.strict` is not fronted by `rigor` at all.
At `minimal`, no evidence is required → skip the Test Evidence
Requirement check (Phase 3), the >50%-untested traceability escalation, and the
Phase 4b QA gate entirely; the acceptance-criteria verification still runs. At
`standard`, the story's own type requires evidence; at `full`, every type does.
`testing.strict` then decides whether present-but-failing evidence blocks.
(`rigor: minimal` sets both; `qa.level: minimal` on its own leaves the workflow
tier where it was.)

**If a file path is provided** (e.g., `/story-done production/epics/core/story-damage-calculator.md`):
read that file directly.

**If no argument is provided:**

1. Check `production/session-state/active.md` for the currently active story.
2. If not found there, read the most recent file in `production/sprints/` and
   look for stories marked IN PROGRESS.
3. If multiple in-progress stories are found, use `AskUserQuestion`:
   - "Which story are we completing?"
   - Options: list the in-progress story file names.
4. If no story can be found, ask the user to provide the path.

---

## Phase 2: Read the Story

Read the full story file. Extract and hold in context:

- **Story name and ID**
- **GDD Requirement TR-ID(s)** referenced (e.g., `TR-combat-001`)
- **Manifest Version** embedded in the story header (e.g., `2026-03-10`)
- **ADR reference(s)** referenced
- **Acceptance Criteria** — the complete list (every checkbox item)
- **Implementation files** — files listed under "files to create/modify"
- **Story Type** — the `Type:` field from the story header (Logic / Integration / Visual/Feel / UI / Config/Data)
- **Engine notes** — any engine-specific constraints noted
- **Definition of Done** — if present, the story-level DoD
- **Estimated vs actual scope** — if an estimate was noted

Also read:
- `docs/architecture/tr-registry.yaml` — grep the story's TR-IDs
  (`Grep pattern="id: <each TR-ID>" path="docs/architecture/tr-registry.yaml" output_mode="content" -A 6`),
  not a full read of the registry. Read the *current* `requirement` text from each
  matched entry. This is the source of truth for what the GDD required — do not use any
  requirement text that may be quoted inline in the story (it may be stale).
- The referenced GDD section — just the acceptance criteria and key rules, not
  the full document. Use this to cross-check the registry text is still accurate.
- The referenced ADR(s) — **just the `## Decision` and `## Consequences`
  sections, never an unbounded full read.** Map headings first
  (`Grep pattern="^## " path="docs/architecture/[adr-file].md" output_mode="content" -n`),
  then bounded-`Read` only those two spans. This is the exact same content
  Phase 4 item 3's ADR constraints check needs — hold it here, do not
  re-read it there.
- `docs/architecture/control-manifest.md` header — extract the current
  `Manifest Version:` date (used in Phase 4 staleness check)

---

## Phase 3: Verify Acceptance Criteria

For each acceptance criterion in the story, attempt verification using one of
three methods:

### Automatic verification (run without asking)

- **File existence check**: `Glob` for files the story said would be created.
- **Test pass check**: if a test file path is mentioned, run it via `Bash`.
- **No hardcoded values check**: `Grep` for numeric literals in gameplay code
  paths that should be in config files.
- **No hardcoded strings check**: `Grep` for player-facing strings in the **code root** (resolve per `.claude/docs/code-root-resolution.md`). **If the code root is unresolved, report `NOT ASSESSED — code root unresolved` rather than zero hits.**
  that should be in localization files.
- **Dependency check**: if a criterion says "depends on X", check that X exists.

### Manual verification with confirmation (use `AskUserQuestion`)

- Criteria about subjective qualities ("feels responsive", "animations play correctly")
- Criteria about gameplay behaviour ("player takes damage when...", "enemy responds to...")
- Performance criteria ("completes within Xms") — ask if profiled or accept as assumed

Batch up to 4 manual verification questions into a single `AskUserQuestion` call:

```
question: "Does [criterion]?"
options: "Yes — passes", "No — fails", "Not tested yet"
```

### Unverifiable (flag without blocking)

- Criteria that require a full game build to test (end-to-end gameplay scenarios)
- Mark as: `DEFERRED — requires playtest session`

### Test-Criterion Traceability

After completing the pass/fail/deferred check above, map each acceptance
criterion to the test that covers it:

For each acceptance criterion in the story:

1. Ask: is there a test — unit, integration, or confirmed manual playtest — that
   directly verifies this criterion?
   - **Unit test**: check `tests/unit/` for a test file or function name that
     matches the criterion's subject (use `Glob` and `Grep`)
   - **Integration test**: check `tests/integration/` similarly
   - **Manual confirmation**: if the criterion was verified via `AskUserQuestion`
     above with a "Yes — passes" answer, count that as a manual test
   - **Retained screenshot**: if the criterion names something on screen and a
     retained image under `production/qa/evidence/[story-slug]/` shows it (the
     `Run result: OBSERVED` from `/dev-story` Phase 6 step 4), count that as
     covered — put the image path in the Test column. A visual criterion
     verified by looking is not UNTESTED; without this row every UI story
     reads as >50% untested and false-escalates.

2. Produce a traceability table:

```
| Criterion | Test | Status |
|-----------|------|--------|
| AC-1: [criterion text] | tests/unit/test_foo.gd::test_bar | COVERED |
| AC-2: [criterion text] | Manual playtest confirmation | COVERED |
| AC-3: [criterion text] | production/qa/evidence/[slug]/01-shop-open.png | COVERED |
| AC-4: [criterion text] | — | UNTESTED |
```

3. Apply these escalation rules (skip entirely at `qa.level: minimal` — no
   evidence is required, so untested criteria never escalate):

   - If **>50% of criteria are UNTESTED**: escalate to **BLOCKING** — test
     coverage is insufficient to confirm the story is actually done. The verdict
     in Phase 6 cannot be COMPLETE until coverage improves.
   - If **some (≤50%) criteria are UNTESTED**: remain ADVISORY — does not block
     completion, but must appear in Completion Notes.
   - If **all criteria are COVERED**: no action needed beyond including the
     table in the report.

4. For any ADVISORY untested criteria, add to the Completion Notes in Phase 7:
   `"Untested criteria: [AC-N list]. Recommend adding tests in a follow-up story."`

### Test Evidence Requirement

**First apply `qa.level` (resolved in Phase 1).** At `minimal`, no evidence is
required — skip this entire subsection (no gate from test evidence; the verdict
rests on acceptance-criteria verification alone). At `standard`, require evidence
for the story's own type. At `full`, require evidence for every story type. Only
when evidence is required does the `testing.strict` resolution below apply.

Based on the Story Type extracted in Phase 2, check for required evidence.

**Resolve the gate level for this story's type.** A gate level is either
BLOCKING (a gap prevents the COMPLETE verdict in Phase 6) or ADVISORY (a gap is
noted in the Completion Notes but does not block). Resolve it from the
`testing.strict` block **already resolved in the resolved-config block at the top of this skill** — not by reading
`project.yaml` yourself:

1. Map the Story Type to a `testing.strict` key — Logic→`logic`,
   Integration→`integration`, Visual/Feel→`visual`, UI→`ui`, Config/Data→`config`.
   Take `testing.strict.<key>` from that resolved block. If its value is `true`
   (case-insensitive) → BLOCKING; if `false` → ADVISORY; `unset` → fall through.
2. Else read `testing.strict` as a plain boolean (legacy single-value form). If
   its value is `true` → BLOCKING or `false` → ADVISORY, it applies to every type.
3. Else use the default in the table below.

> **Use that resolved block, never `project.yaml` directly.** `testing.strict.*` is
> on the `/settings --local` whitelist, so a developer can set
> `testing.strict.logic=false` in `project.local.yaml` for fast WIP commits —
> `effects-map.md` specifies exactly this ("stricter dev's local `/story-done`
> blocks earlier"). Reading `project.yaml` alone silently ignores that file: the
> setting is accepted, displayed by `/settings`, and has no effect. The
> `resolve_config` block at the top of this skill already merges local over base.

Only `true` and `false` (case-insensitive) are recognized at steps 1–2. A key
that is present but holds any other value — `maybe`, `1`, `yes`, etc. — is
treated as unset: continue to the next step, and surface the unrecognized value
to the user.

| Story Type | Required Evidence | Default Gate Level |
|---|---|---|
| **Logic** | Automated unit test in `tests/unit/[system]/` — must exist and pass (this skill verifies **existence**; see the note below Phase 3) | BLOCKING |
| **Integration** | Integration test in `tests/integration/[system]/` OR playtest doc | BLOCKING |
| **Visual/Feel** | Retained screenshot + sign-off in `production/qa/evidence/` | BLOCKING |
| **UI** | Retained screenshot of each screen touched, in `production/qa/evidence/` | BLOCKING |
| **Config/Data** | Smoke check pass report in `production/qa/smoke-*.md` | ADVISORY |

The **Default Gate Level** column applies when `testing.strict` is unset (the
common case). When `testing.strict` is configured, the resolved value from
steps 1–2 overrides it. Visual/Feel and UI default to BLOCKING because for a
game the rendered result is the product; set `testing.strict.visual` or
`testing.strict.ui` to `false` for an advisory gate.

> **Exception — `/smoke-check`.** The ADVISORY default for **Config/Data** above
> governs *per-story evidence* gates, which is what this skill checks.
> `/smoke-check` is a build-health gate, not a per-story evidence gate, so its own
> unset default for `testing.strict.config` is **BLOCKING** — see
> `.claude/skills/smoke-check/SKILL.md` § "Resolve the gate enforcement level".
> The divergence is intentional; do not "fix" either side to match the other.

> **This phase checks that evidence EXISTS. It does not run anything.** The
> `Default Gate Level` table above, and `.claude/docs/coding-standards.md`, both
> say a Logic story's test "must exist **and pass**". The checks below establish
> only the first half — every one of them is a `Glob` or a `Grep`. A unit test
> that exists and fails, or that contains no assertions, satisfies them.
>
> Say which half you verified when you report. "Test file present at `<path>`"
> is the honest claim; "tests pass" is not one this phase can make. Pass/fail is
> established by `/gate-check` (runs the suite at a phase gate) and
> `/smoke-check` (runs it before QA hand-off), both of which do execute.
>
> Unlike `/regression-suite` and `/launch-checklist`, which stop at existence
> because their `allowed-tools` has no `Bash`, this skill HAS `Bash` — the limit
> here is the instruction, not the grant. Running the story's own test before
> closing it is a live option; it is not enabled because it needs a configured
> runner and a decision about what a missing runner should mean.

**For Logic stories**: first read the story's **Test Evidence** section to extract the
exact required file path. Use `Glob` to check that exact path. If the exact path is not
found, also search `tests/unit/[system]/` broadly (the file may have been placed at a
slightly different location). If no test file is found at either location:
- Flag at the resolved gate level: "Logic story has no unit test file. Story
  requires it at `[exact-path-from-Test-Evidence-section]`. Create and run the
  test before marking this story Complete."

**For Integration stories**: read the story's **Test Evidence** section for the exact
required path. Use `Glob` to check that exact path first, then search
`tests/integration/[system]/` broadly, then check `production/session-logs/` for a
playtest record referencing this story.
If none found: flag at the resolved gate level (same rule as Logic).

**For Visual/Feel and UI stories**: glob `production/qa/evidence/` for both an
evidence doc referencing this story and a retained screenshot for it (`*.png`,
`*.jpg`, `*.gif`).
- If neither is found: flag at the resolved gate level — "No visual evidence found. Capture a screenshot of each screen or effect this story touched, save it under `production/qa/evidence/`, create `production/qa/evidence/[story-slug]-evidence.md` using the test-evidence template, and obtain sign-off before final closure."
- If the evidence doc exists but no screenshot is retained beside it: flag at the resolved gate level — "Evidence doc found at `[path]` but no screenshot is retained. A described check is an assertion, not evidence — capture the screen and save the image under `production/qa/evidence/` before final closure."
- If found: read the file and check the sign-off table for unchecked boxes. Grep for lines matching `| .* | .* | .* | \[ \] Approved` (a sign-off row with an unchecked checkbox). If any unchecked sign-off rows are found: flag at the resolved gate level — "Evidence file found at `[path]` but [N] sign-off(s) are still pending (shown as `[ ] Approved` in the sign-off table). Obtain required sign-offs before final closure. Note: for solo developers, all roles may be signed off by the same person."
- If the doc, the screenshot and all `[x] Approved` sign-off rows are present: note "Evidence doc and retained screenshot found, all sign-offs complete — gate satisfied."

The retained image **is** the `Run result: OBSERVED` from `/dev-story` Phase 6
step 4 (`.claude/docs/run-and-observe.md`); its absence means the run was
`NOT VERIFIED` or never happened, and the flag above is the consequence. The
run is not waived at `qa.level: minimal`.

**For every other story type**, read the `Run result:` line from the
`/dev-story` summary (the session extract in `production/session-state/active.md`,
or the story's `## Completion Notes`). `OBSERVED` with a retained path: note
it. `N/A — <reason>`: accept only if the reason names why nothing is
observable — "it's a Logic story" is not a reason. `NOT VERIFIED — <reason>`
on a story whose acceptance criteria name anything on screen: flag at the
resolved gate level for the story's type. No `Run result:` line at all: flag
as ADVISORY — "the implementation summary carries no run result; confirm the
build was launched and looked at before closure."

**For Config/Data stories**: check for any `production/qa/smoke-*.md` file.
If none: flag at the resolved gate level — "No smoke check report found. Run `/smoke-check`."

**If no Story Type is set**: flag as **ADVISORY** —
"Story Type not declared. Add `Type: [Logic|Integration|Visual/Feel|UI|Config/Data]`
to the story header to enable test evidence gate enforcement in future stories."

Any BLOCKING test evidence gap prevents the COMPLETE verdict in Phase 6.

---

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

The qa-lead reviews whether the tests actually cover what was specified — not just whether files exist.

Apply the verdict:
- **ADEQUATE** → proceed to Phase 5
- **GAPS** → flag as **ADVISORY**: "QA lead identified coverage gaps: [list]. Story can complete but gaps should be addressed in a follow-up story."
- **INADEQUATE** → flag as **BLOCKING**: "QA lead: critical logic is untested. Verdict cannot be COMPLETE until coverage improves. Specific gaps: [list]."

Skip this phase for Config/Data stories (no code tests required).

---

## Phase 5: Lead Programmer Code Review Gate

**Review mode check** — apply before spawning LP-CODE-REVIEW:
- `solo` → skip. Note: "LP-CODE-REVIEW skipped — Solo mode." Proceed to Phase 6 (completion report).
- `lean` → use `AskUserQuestion` before proceeding:
  - Prompt: "Code review is skipped in lean mode. Did you run `/code-review` on the implemented files?"
  - Options:
    - `Yes — /code-review passed or was approved with suggestions`
    - `No — skipping code review for this story`
    - `No — I'll run /code-review before the sprint close-out`
  - Record the answer in the completion notes (Phase 7). All three options proceed to Phase 6.
- `full` → spawn as normal.

Spawn `lead-programmer` via `Agent` using gate **LP-CODE-REVIEW** (`.claude/docs/director-gates/lp-code-review.md`).

Pass: implementation file paths, story file path, relevant GDD section, governing ADR.

Present the verdict to the user. If CONCERNS, surface them via `AskUserQuestion`:
- Options: `Revise flagged issues` / `Accept and proceed` / `Discuss further`
If REJECT, do not proceed to Phase 6 verdict until the issues are resolved.

If the story has no implementation files yet (verdict is being run before coding is done), skip this phase and note: "LP-CODE-REVIEW skipped — no implementation files found. Run after implementation is complete."

---

## Phase 6: Present the Completion Report

Before updating any files, present the full report:

```markdown
## Story Done: [Story Name]
**Story**: [file path]
**Date**: [today]

### Acceptance Criteria: [X/Y passing]
- [x] [Criterion 1] — auto-verified (test passes)
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
**Required evidence**: [unit test file | integration test or playtest | screenshot + sign-off | walkthrough doc | smoke check pass]
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
- **COMPLETE WITH NOTES**: all criteria pass, advisory deviations documented
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

## Phase 7: Update Story Status

**Reached one of two ways**: normally, immediately after a COMPLETE or
COMPLETE-WITH-NOTES verdict in Phase 6; or, after a BLOCKED **or NOT ASSESSED**
verdict, only if the user explicitly asks to close the story despite the
blockers (Phase 6 does not advance here on its own in either case).

**Automation note**: This is the story-completion gate. Closing a story whose
verdict is BLOCKED (failing acceptance criteria) **or NOT ASSESSED** (criteria
nobody could evaluate) — the "Accept deviations as-is and close anyway" option —
is a `scope_changes` decision. Call
`is_always_ask_category scope_changes`; when it returns 0 (the default), this
gate prompts via `AskUserQuestion` **regardless of `modes.automation`** —
autonomous mode must NOT silently close a BLOCKED story, even when the user's
own request is what got you here. For a COMPLETE or COMPLETE-WITH-NOTES
verdict, autonomous mode may pick "Close the story (Recommended)" and record
it via `log_decision`.

Use `AskUserQuestion` before writing anything:
- Prompt: "Verification complete. How do you want to proceed?"
- Options:
  - `Close the story — update file, mark Complete, log notes (Recommended)`
  - `Close and log advisory deviations as tech debt in docs/tech-debt-register.md`
  - `There are issues I want to fix first — don't close yet`
  - `Accept deviations as-is and close anyway`

If "Close", "Close and log tech debt", or "Accept deviations": edit the story file.
If "Close and log tech debt": after updating the story file, also append the advisory deviations to `docs/tech-debt-register.md` (create the file if it does not exist).
If "Fix first": stop here and list what the user flagged. Do not write any files.

1. Update the status field: `Status: Complete`
2. Update the `Last Updated:` field in the story header to today's date (format: `YYYY-MM-DD`). If the field does not exist, add it after the `Status:` line.
3. Add a `## Completion Notes` section at the bottom:

```markdown
## Completion Notes
**Completed**: [date]
**Criteria**: [X/Y passing] ([any deferred items listed])
**Deviations**: [None] or [list of advisory deviations]
**Test Evidence**: [Logic: test file at path | Visual/Feel: evidence doc at path | None required (Config/Data)]
**Code Review**: [Pending / Complete / Skipped]
```

4. If the user chose "Close and log tech debt": append each advisory deviation to `docs/tech-debt-register.md` in this format:
   ```
   - **[date]** ([story title]): [deviation description] — tracked from [story file path]
   ```
   Create the file with a `# Tech Debt Register` heading if it does not exist.

5. **Update `production/sprint-status.yaml`** (if it exists):
   - Find the entry matching this story's file path or ID
   - Set `status: done` and `completed: [today's date]`
   - Update the top-level `updated` field
   - This is a silent update — no extra approval needed (already approved in step above)

6. **Suggest a git commit**: Output a ready-to-use commit command covering the implementation files from the dev-story summary and the updated story file:

```
Suggested commit:
git add [code-root and tests/ files changed during implementation] [story-file-path]
git commit -m "feat: [story title] ([TR-ID])"
```

The `validate-commit.sh` hook will verify design doc references and check for hardcoded values automatically.

### Session State Update

After updating the story file, silently append to
`production/session-state/active.md`:

    ## Session Extract — /story-done [date]
    - Verdict: [COMPLETE / COMPLETE WITH NOTES / NOT ASSESSED / BLOCKED]
    - Story: [story file path] — [story title]
    - Tech debt logged: [N items, or "None"]
    - Next recommended: [next ready story title and path, or "None identified"]

If `active.md` does not exist, create it with this block as the initial content.
Confirm in conversation: "Session state updated."

---

## Phase 8: Surface the Next Story

After completion, help the developer keep momentum:

1. Read the current sprint plan from `production/sprints/`.
2. Find stories that are:
   - Status: READY or NOT STARTED
   - Not blocked by other incomplete stories
   - In the Must Have or Should Have tier

Present:

```
### Next Up
The following stories are ready to pick up:
1. [Story name] — [1-line description] — Est: [X hrs]
2. [Story name] — [1-line description] — Est: [X hrs]

Run `/story-readiness [path]` to confirm a story is implementation-ready
before starting.
```

If no more Must Have stories remain in this sprint (all are Complete or Blocked):

```
### Sprint Close-Out Sequence

All Must Have stories are complete. QA sign-off is required before advancing.
Run these in order:

1. `/smoke-check sprint` — verify the critical path still works end-to-end
2. `/team-qa sprint` — full QA cycle: test case execution, bug triage, sign-off report
3. `/retrospective` — capture what went well, what didn't, and action items for the next sprint
4. `/gate-check` — advance to the next phase once QA approves (only if advancing a phase)
5. `/sprint-plan new` — plan the next sprint, incorporating velocity data and retrospective action items

Do not run `/gate-check` until `/team-qa` returns APPROVED or APPROVED WITH CONDITIONS.
```

If there are Should Have stories still unstarted, surface them alongside the close-out sequence so the user can choose: close the sprint now, or pull in more work first.

If no more stories are ready but Must Have stories are still In Progress (not Complete):
"No more stories ready to start — [N] Must Have stories still in progress. Continue implementing those before sprint close-out."

---

## Collaborative Protocol

**In `collaborative` mode (the default).** For `guided` and `autonomous` modes,
see `.claude/docs/automation-modes.md` — the rules below describe collaborative
behavior. The BLOCKED-override close (Phase 7) always prompts regardless of mode
(it's a `scope_changes` always-ask decision).

- **Never mark a story complete without user approval** — Phase 7 requires an
  explicit "yes" before any file is edited.
- **Never auto-fix failing criteria** — report them and ask what to do.
- **Deviations are facts, not judgments** — present them neutrally; the user
  decides if they are acceptable.
- **BLOCKED and NOT ASSESSED verdicts are advisory** — the user can override and
  mark complete anyway; document the risk explicitly if they do. For NOT
  ASSESSED, the documented risk is that the criterion was never evaluated, not
  that it failed — record which criteria those were, so the gap is recoverable
  later rather than closed over.
- Use `AskUserQuestion` for the code review prompt and for batching manual
  criteria confirmations.

---

## Recommended Next Steps

- Run `/story-readiness [next-story-path]` to validate the next story before starting implementation
- If all Must Have stories are complete: run `/smoke-check sprint` → `/team-qa sprint` → `/gate-check`
- If tech debt was logged: track it via `/tech-debt` to keep the register current
