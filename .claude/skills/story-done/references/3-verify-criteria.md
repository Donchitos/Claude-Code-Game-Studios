# /story-done — Phase 3: Verify Acceptance Criteria

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Verify Acceptance Criteria

**In this file:**

- Automatic verification (run without asking)
- Manual verification with confirmation (use `AskUserQuestion`)
- Unverifiable (flag without blocking)
- Test-Criterion Traceability
- Test Evidence Requirement

For each acceptance criterion in the story, attempt verification using one of
three methods:

### Automatic verification (run without asking)

- **File existence check**: `Glob` for files the story said would be created.
- **Test file check**: if a test file path is mentioned, confirm the file exists
  with `Glob`. Do not run it — this skill establishes existence only (see the
  note under Test Evidence Requirement), so report "test file present", never
  "test passes".
- **No hardcoded values check**: `Grep` for numeric literals in gameplay code
  paths that should be in config files.
- **No hardcoded strings check**: `Grep` for player-facing strings in the **code root** (resolve per `.claude/docs/code-root-resolution.md`). **If the code root is unresolved, report `NOT ASSESSED — code root unresolved` rather than zero hits.**
  that should be in localization files.
- **Dependency check**: if a criterion says "depends on X", check that X exists.

### Manual verification with confirmation (use `AskUserQuestion`)

- Criteria about subjective qualities ("feels responsive", "animations play correctly")
- Criteria about gameplay behaviour ("player takes damage when...", "enemy responds to...")
  — these are asked, never marked verified from reading the code: the code says
  what should happen, not what the build does
- Performance criteria ("completes within Xms") — ask if profiled or accept as assumed

Batch up to 4 manual verification questions into a single `AskUserQuestion` call:

```
question: "Does [criterion]?"
options: "Yes — passes", "No — fails", "Not tested yet"
```

Map each answer: `Yes — passes` → confirmed; `No — fails` → FAILS;
`Not tested yet` → not evaluated — UNTESTED in the traceability table below, and
the verdict is NOT ASSESSED (Phase 6) until someone checks it. If the criterion
genuinely needs a full-build playtest, mark it `DEFERRED — requires playtest
session` instead.

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
     reads as >50% untested and false-escalates. "Shows it" means you opened
     the image with `Read` and saw it; a checkpoint's `Run result: OBSERVED —
     <text>` is `/dev-story`'s description, to quote as such, not yours.
     **Never describe an image you have not opened.**

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

**First apply `qa.level` (resolved in Phase 1).** At `minimal`, no *test*
evidence is required — skip the Logic, Integration and Config/Data checks below.
But still run the Visual/Feel and UI check and the `Run result:` check: the look
is not waived at minimal, only the tests are. At `standard`, require evidence
for the story's own type. At `full`, require evidence for every story type. The
`testing.strict` resolution below applies to every check that runs.

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
> and carry no general `Bash` pre-approval, this skill has `Bash` pre-approved —
> the limit here is the instruction, not the grant (a pre-approval never
> restricts). Running the story's own test before closing it is a live option;
> it is not enabled because it needs a configured runner and a decision about
> what a missing runner should mean.

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

**For Visual/Feel and UI stories**: glob `production/qa/evidence/` for a
retained screenshot for this story (`*.png`, `*.jpg`, `*.gif`) and for an
evidence doc referencing it. What closes the story follows the evidence table
in `.claude/docs/coding-standards.md`, the same at every `qa.level`:
- A **UI** story is satisfied by the retained screenshot of each screen it
  touched. No evidence doc or sign-off is required; note one if it exists.
- A **Visual/Feel** story also needs the sign-off: the evidence doc
  (`production/qa/evidence/[story-slug]-evidence.md`, from the test-evidence
  template) with every sign-off row `[x] Approved`.

Flag at the resolved gate level:
- No screenshot: "No visual evidence found. Capture a screenshot of each screen or effect this story touched and save it under `production/qa/evidence/` before final closure." For Visual/Feel add: "then record sign-off in `production/qa/evidence/[story-slug]-evidence.md` using the test-evidence template."
- An evidence doc but no screenshot retained beside it: "Evidence doc found at `[path]` but no screenshot is retained. A described check is an assertion, not evidence — capture the screen and save the image under `production/qa/evidence/` before final closure."
- Visual/Feel with a screenshot but no evidence doc: "Screenshot found but no sign-off is recorded. Create `production/qa/evidence/[story-slug]-evidence.md` using the test-evidence template and obtain sign-off before final closure."
- Visual/Feel sign-off rows still unchecked — grep the doc for `| .* | .* | .* | \[ \] Approved`: "Evidence file found at `[path]` but [N] sign-off(s) are still pending (shown as `[ ] Approved` in the sign-off table). Obtain required sign-offs before final closure. Note: for solo developers, all roles may be signed off by the same person."

Otherwise note "Retained screenshot found[, sign-offs complete] — gate satisfied."

The retained image **is** the `Run result: OBSERVED` from `/dev-story` Phase 6
step 4 (`.claude/docs/run-and-observe.md`); its absence means the run was
`NOT VERIFIED` or never happened, and the flag above is the consequence. The
run is not waived at `qa.level: minimal`.

**For every other story type**, read the `Run result:` line from the
`/dev-story` checkpoint in `production/session-state/active.md` — only when its
**Current task** names this story; a later `/dev-story` overwrites it — or from
the story's `## Completion Notes`. `OBSERVED` with a retained path: note
it. `N/A — <reason>`: accept only if the reason names why nothing is
observable — "it's a Logic story" is not a reason. `NOT VERIFIED — <reason>`
on a story whose acceptance criteria name anything on screen: flag at the
resolved gate level for the story's type. No `Run result:` line at all: flag
as ADVISORY — "the implementation summary carries no run result; confirm the
build was launched and looked at before closure." The exception: when the
acceptance criteria name something on screen and no retained image for this
story is under `production/qa/evidence/`, nothing observed the story — a user's
`Yes — passes` to such a criterion is an assertion, not the retained observation
`.claude/docs/run-and-observe.md` requires — so flag it at the resolved gate
level for the story's type, as for `NOT VERIFIED`.

**For Config/Data stories**: check for any `production/qa/smoke-*.md` file.
If none: flag at the resolved gate level — "No smoke check report found. Run `/smoke-check`."

**If no Story Type is set**: flag as **ADVISORY** —
"Story Type not declared. Add `Type: [Logic|Integration|Visual/Feel|UI|Config/Data]`
to the story header to enable test evidence gate enforcement in future stories."

Any BLOCKING test evidence gap prevents the COMPLETE verdict in Phase 6.

---
