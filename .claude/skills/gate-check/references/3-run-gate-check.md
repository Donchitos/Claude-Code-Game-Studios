# /gate-check — Section 3: Run the Gate Check

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 3. Run the Gate Check

**In this file:**

- Artifact Checks
- Quality Checks
- Cross-Reference Checks

**Before running artifact checks**, read `docs/consistency-failures.md` if it exists.
Extract entries whose Domain matches the target phase (e.g., if checking
Systems Design → Technical Setup, pull entries in Economy, Combat, or any GDD domain;
if checking Technical Setup → Pre-Production, pull entries in Architecture, Engine).
Carry these as context — recurring conflict patterns in the target domain warrant
increased scrutiny on those specific checks.

For each item in the target gate:

### Artifact Checks

**Resolve existence and counts deterministically — do not open files to find out
what exists:**

```
Bash: bash .claude/scripts/artifact-check.sh --phase [source-phase]
```

Pass the phase being advanced *from* (its steps are the work that must be
complete): `systems-design` for the Systems Design → Technical Setup gate,
`pre-production` for Pre-Production → Production, and so on.

At `workflow: minimal`, also run
`bash .claude/scripts/artifact-check.sh --path minimal`: the brief and stories
live on that path, not on any phase, and its `game-brief` and `create-stories`
rows are this tier's floor.

It reads `workflow-catalog.yaml` — which already encodes each step's `glob`,
`pattern`, `min_count` and `any_of` — and reports per step:

| status | Meaning |
|---|---|
| `PRESENT` | glob matched, `min_count` met, `pattern` found where specified |
| `ABSENT` | nothing matched |
| `SHORT` | matched but fewer than `min_count` (`count=` and `min=` given) |
| `PATTERN_MISS` | files exist but none contains the required marker |
| `NO_CHECK` | the step declares no artifact — **not detectable from disk** |

It emits observations, never a verdict: **you** apply the workflow tier and the
required/optional split from Section 2. An `ABSENT` required artifact is a
blocker at `full` and frequently not one at `minimal`; the script does not know
that and does not decide it.

**`NO_CHECK` is not `PRESENT`.** The header prints a `NO_CHECK:` count before any
row precisely so this cannot be skimmed past. Those steps were *scanned*, not
*satisfied* — carry each into Section 4 (Collaborative Assessment) and ask, or
mark MANUAL CHECK NEEDED. A gate that reports PASS because most of its checklist
was undetectable is the failure mode this count exists to prevent.

**Existence is not adequacy.** The script cannot tell a real document from a
template skeleton. So: for any artifact the verdict actually turns on, spot-read
it and confirm it has real content — the same escalation rule the
`gdd-structure-check.sh` step below uses. Do not spot-read artifacts the verdict
does not turn on.

> **A smoke report is always an artifact the verdict turns on — spot-reading it
> is mandatory, not discretionary.** At `minimal` it is frequently the *only*
> required artifact, so the whole gate rests on one file that nothing generated
> and nothing verifies. Check its claims against the repo, and raise any that the
> tree contradicts:
>
> - It reports a passing automated suite → the engine's test root must actually
>   contain test files and the project must have a runner. "24 passed, 0 failed"
>   in a repo with no test files under that root — `tests/unit/` and
>   `tests/integration/` on Godot, `Assets/Tests/` on Unity,
>   `Source/<Module>/Private/Tests/` on Unreal — and no runner is a finding, not
>   evidence.
> - It marks a critical path PASS → the code for that path must exist in the code
>   root. A PASS on "banking ends the run" with no banking code is a finding.
> - It carries no date, or predates the newest commit touching the code root →
>   say so; a stale smoke report describes a build that no longer exists.
>
> Report a contradiction at the same level the artifact was required at: a
> Blocker where the smoke check is required, CONCERNS where it is recommended.
> Existence plus a verdict-line grep would clear a fabricated report.

For code checks, verify directory structure and file counts.

**Systems Design → Technical Setup gate — cross-GDD review check**:
Use `Glob('design/gdd/gdd-cross-review-*.md')` to find the `/review-all-gdds` report.
If no file matches: at `full` mark the "cross-GDD review report exists" artifact as
**FAIL** and surface it prominently ("No `/review-all-gdds` report found in
`design/gdd/`. Run `/review-all-gdds` before advancing to Technical Setup."); at
`standard` the report is recommended, so mark it **CONCERNS**, not a blocker; at
`minimal` this gate is not applicable (see the gate file). If a file is found, read it and
check the verdict line: a FAIL verdict means the cross-GDD consistency check failed
and must be resolved before advancing. A NOT ASSESSED verdict means that review
could not compare the GDDs, so it satisfies nothing here: mark the item NOT
ASSESSED for this gate, never passed.

### Quality Checks
- For test checks: Run the test suite via `Bash` if a test runner is configured.
  **If no runner is configured, that is `NOT ASSESSED`, not a silent skip** — see
  the trigger in the verdict section. A gate that ran no tests found no test
  failures, which is not the same as passing.
  A test failure's effect on the verdict depends on the `testing.strict` block
  **resolved in Phase 1** (`resolve_config` merges `project.local.yaml` over
  `project.yaml`; reading the file directly would drop a local override), per
  test type:
  - **Logic** — unit-level failures (`tests/unit/` on Godot, Edit Mode on
    Unity), gated by `testing.strict.logic`.
  - **Integration** — failures in `tests/integration/` on Godot, Play Mode on
    Unity, gated by `testing.strict.integration`. On Unreal, where one root
    (`Source/<Module>/Private/Tests/`) holds both, classify a failure by its
    story's Type, or apply the stricter of the two levels when that is unknown.
  - For each type: take `testing.strict.<type>` from that block; use it only
    if its value is `true` or `false` (case-insensitive). If the key is absent,
    empty, or holds any other value, read `testing.strict` as a plain boolean
    (legacy single-value form); if that too is absent or invalid, default to
    `true` (Logic and Integration are both strict by default — behavior unchanged
    from before this setting existed). Surface any unrecognized value to the user.
  - At a strict (`true`) gate level, failures of that type are **Blockers**
    (verdict FAIL). At an advisory (`false`) level, they are **Concerns**
    (verdict minimum CONCERNS, not FAIL) — list them under Recommendations, not
    Blockers.
- For design review checks, gather section presence **deterministically** — do not
  read the GDDs to count headings:

  ```
  Bash: bash .claude/scripts/gdd-structure-check.sh
  ```

  It prints a `PRESENT:` / `ABSENT:` pair per GDD and already accepts
  `## Detailed Design` as satisfying the `Detailed Rules` requirement. It reports
  presence only and makes no REQUIRED/ADVISORY judgment.

  Then apply each GDD's **effective tier** (per-system resolution below) to those
  lists — all 8 sections at `full`, the 5 standard sections (+ conditional
  Formulas) at `standard`. A missing *required* section blocks; a missing section
  that is optional at the effective tier is advisory. A section reported PRESENT
  can still fail review if it is an empty heading — spot-read any section the
  verdict actually turns on.
- For performance checks: read the budgets (`performance.target_framerate`,
  `frame_budget_ms`, `draw_call_limit`, `memory_ceiling_mb`) from `project.yaml`
  (else technical-preferences.md) and compare against any profiling data in
  `tests/performance/` or recent `/perf-profile` output. What a breach *means*
  is set by `performance.enforce`, taken from the Phase 1 resolved block (it is
  locally overridable, so do not read the file for this one):
  - `warn` (default) — breaches are **CONCERNS**, never Blockers.
  - `block` — breaches are **Blockers** from the Polish gate onward.
  - `off` — budgets are informational; do not surface breaches in the verdict.

  Only these three values are recognized. Surface anything else to the user and
  fall back to `warn` rather than guessing.
- For localization checks: `Grep` for hardcoded strings in the **code root** (resolve per `.claude/docs/code-root-resolution.md`). **If the code root is unresolved, report `NOT ASSESSED — code root unresolved` rather than zero hits.**

### Cross-Reference Checks
- Compare `design/gdd/` documents against implementations in the **code root**
- Check that every system referenced in architecture docs has corresponding code
- Verify sprint plans reference real work items

---
