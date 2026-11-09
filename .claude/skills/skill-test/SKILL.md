---
name: skill-test
description: "Validate skill files for structural compliance and behavioral correctness. Four modes: static linter, spec, category rubric, audit."
argument-hint: "static [skill-name | all] | spec [skill-or-agent-name] | category [skill-or-agent-name | all] | audit"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(bash "*/.claude/skills/skill-test/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/agent-check.sh*), Bash(bash .claude/scripts/compat-inventory.sh*)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Skill Test

Validates skills (`.claude/skills/*/SKILL.md`) and agents (`.claude/agents/*.md`)
for structural compliance and behavioral correctness. No external dependencies —
runs entirely within the existing skill/hook/template architecture.

**Four modes:**

| Mode | Command | Purpose | Token Cost |
|------|---------|---------|------------|
| `static` | `/skill-test static [name\|all]` | Structural linter — 7 compliance checks per skill, plus agent, delegation and compatibility observations | Low (~1k/skill) |
| `spec` | `/skill-test spec [name]` | Behavioral verifier — evaluates assertions in a skill's or agent's test spec | Medium (~5k each) |
| `category` | `/skill-test category [name\|all]` | Category rubric — checks a skill or agent against its category-specific metrics | Low (~2k each) |
| `audit` | `/skill-test audit` | Coverage report — skills, agent specs, last test dates | Low (~3k total) |

**What a pass proves.** Every mode reads files; none runs the skill. `static`:
the file has the structure a skill needs, not that it behaves. `spec`: read
closely, the instructions cover each case, not that Claude follows them when it
runs. `category`: the skill meets its category's rubric as written. `audit`:
which skills and agents have specs, and when each was last checked. What a skill
does shows only when it runs: a real request in a throwaway copy of the project,
on each model you use, with and without the skill (Anthropic's Agent Skills best
practices, "Build evaluations first").

---

## Phase 1: Parse Arguments

Determine mode from the first argument:

- `static [name]` → run 7 structural checks on one skill, or the agent observations on one agent
- `static all` → run 7 structural checks on all skills (Glob `.claude/skills/*/SKILL.md`), plus the observations for every agent
- `spec [name]` → read the skill or agent + its test spec, evaluate assertions
- `category [name]` → run category-specific rubric from `studio-tests/quality-rubric.md`
- `category all` → run category rubric for every skill and every agent that has a `category:` in catalog
- `audit` (or no argument) → read catalog, list all skills and agents, show coverage

If the argument is unrecognized, output usage and stop.

**The old spec folder.** Glob `CCGS Skill Testing Framework/catalog.yaml`. When
it exists, say so first: "`CCGS Skill Testing Framework/` was renamed
`studio-tests/` in 1.2.0, and this skill reads only `studio-tests/`. Move any
specs you wrote there; UPGRADING.md (v1.1.3 → v1.2.0, `studio-tests/`) says how."
Then go on with `studio-tests/`.

**Resolve the name before `spec` or `category`.** Look it up in
`studio-tests/catalog.yaml`: an entry under `skills:` is a skill
(`.claude/skills/[name]/SKILL.md`); an entry under `agents:` is an agent
(`.claude/agents/[name].md`). With no catalog entry, use whichever of those two
files exists. Only when neither exists, report "'[name]' is neither a skill in
`.claude/skills/` nor an agent in `.claude/agents/`." and stop. A name that is
also an ordinary word is still a name: `/skill-test spec help` tests the `/next-step`
skill, never a request for this skill's usage.

The 7 checks lint SKILL.md structure, so they are skills-only. Given an agent
name, `static` runs only the observations below: an agent file has no
phases or verdict keywords to lint. Never report the agent as missing.

---

## Phase 2A: Static Mode — Structural Linter

For each skill being tested, read its `SKILL.md` and every file in its `references/` folder
fully, and run all 7 checks on them as one skill — the longest skills keep each
phase in `references/`. The frontmatter checks (1, 6 and 7) read `SKILL.md`.

### Check 1 — Required Frontmatter Fields
The file must contain all of these in the YAML frontmatter block:
- `name:`
- `description:`
- `argument-hint:`
- `user-invocable:`
- `allowed-tools:`

**FAIL** if any are absent. A file whose frontmatter does not parse fails Check 1
too — malformed YAML is a structural defect this check exists to catch, not an
unassessable file; see the per-skill result rule below.

### Check 2 — Multiple Phases
The skill must have ≥2 numbered phase headings. Look for patterns like:
- `## Phase N` or `## Phase N:`
- `## N.` (numbered top-level sections)
- At least 2 distinct `##` headings if phases aren't explicitly numbered

**FAIL** if fewer than 2 phase-like headings are found.

### Check 3 — Verdict Keywords

The skill must communicate a clear outcome. Accept any of:

- **Gate / review verdicts** — `PASS`, `FAIL`, `CONCERNS`, `APPROVED`,
  `BLOCKED`, `COMPLETE`, `READY`, `COMPLIANT`, `NON-COMPLIANT`
- **Go / no-go verdicts** — `PROCEED`, `PIVOT`, `KILL`, `GO`, `NO-GO`
- **Severity scales** — `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`. Audit skills rank
  findings by severity instead of issuing one verdict for the whole run.

**FAIL** if none are present **and** the skill produces an assessment — its
description or body promises a review, audit, check, gate, or readiness
judgement.

**WARN** (never FAIL) if none are present and the skill's output is an artifact
or a value rather than a judgement. `/project-settings` is the reference case: it prints
and writes configuration and has no verdict to give. Do not invent one to
satisfy this check.

> A narrower list — gate verdicts only, hard FAIL on anything else — would wrongly
> fail skills for reasons that are not their fault: `/prototype` and
> `/vertical-slice` advertise `PROCEED`/`PIVOT`/`KILL` in their own descriptions,
> `/adopt` and `/security-audit` rank by severity, and `/project-settings` has no verdict
> by design. A linter that produces false failures on legitimate patterns stops
> being trusted.

### Check 4 — Collaborative Protocol Language
The skill must contain ask-before-write language. Look for:
- `"May I write"` (canonical form)
- `"before writing"` or `"approval"` near file-write instructions
- `"ask"` + `"write"` in close proximity (within same section)

**WARN** if absent (some read-only skills legitimately skip this).
**FAIL** if `allowed-tools` includes `Write` or `Edit` but no ask-before-write language is found.

### Check 5 — Next-Step Handoff
The skill must end with a recommended next action or follow-up path. Look for:
- A final section mentioning another skill (e.g., `/story-done`, `/gate-check`)
- "Recommended next" or "next step" phrasing
- A "Follow-Up" or "After this" section

**WARN** if absent.

### Check 6 — Fork Context Complexity
If frontmatter contains `context: fork`, the skill should have ≥5 phase headings
(`##` level or numbered Phase N headers). Fork context is for complex multi-phase
skills; simple skills should not use it.

**WARN** if `context: fork` is set but fewer than 5 phases found.

### Check 7 — Argument Hint Plausibility
`argument-hint` must be non-empty. If the skill body mentions multiple modes
(e.g., "Mode A | Mode B"), the hint should reflect them. Cross-reference the
hint against the first phase's "Parse Arguments" section.

**WARN** if hint is `""` or if documented modes don't match hint.

### Agent and Delegation Observations (not scored)

Run `bash .claude/scripts/agent-check.sh --skill [name]` for a skill,
`bash .claude/scripts/agent-check.sh --agent [name]` for an agent, or
`bash .claude/scripts/agent-check.sh` once for `static all`. It prints
observations, never a verdict, and nothing here changes a skill's verdict. Report
them under `Observations:`, judging each:

- **`DELEGATION:`** a part of the skill that hands work to an agent. Read it and
  say whether the brief gives an objective, an output format, the tools and
  sources, and boundaries, and whether it hands the agent a job of only a few
  tool calls or a re-check of the skill's own work. Its `markers:` are word
  counts that show where to look, not a grade.
- **`AGENT:`** the model, effort and turn limit as set, and the tools beside the
  description: name any tool the job in the description does not need.
- **`NOTE:`** frontmatter that does not parse; `asks-user` (an agent has no
  question tool, so its questions belong at the end of its report); a setting
  that is ignored or does more than it says (`agent-type-list`, `preload-off`,
  `disallowed-specifier`, `memory-grants`).
- **`OVERLAP:`** two descriptions that share distinctive words: say whether each
  still singles out its agent, or which request would reach the wrong one.

If the script cannot run, write `Observations: not run (<reason>)`. Never leave
the section out: a missing section reads the same as a clean one.

### Compatibility Observations (not scored)

Run `bash .claude/scripts/compat-inventory.sh --skill [name]` for a skill,
`bash .claude/scripts/compat-inventory.sh --agent [name]` for an agent, or
`bash .claude/scripts/compat-inventory.sh` once for `static all`. Each `FOUND:`
line is a place the file depends on something only Claude Code provides, with
its feature: questions, subagents, skill-loading, shell-lines, arguments,
frontmatter, instructions, hooks, settings or tools. Claude Code runs all of
them, so none is a defect and none changes a verdict. Report them under
`Compatibility:`, one line per feature with its constructs and line numbers;
for `static all`, give the `COUNT:` totals by feature instead. A `NOT FOUND:`
line means the name matched no file: say so. If the script cannot run, write
`Compatibility: not run (<reason>)`.

---

### Static Mode Output Format

For a single skill:
```
=== Skill Static Check: /[name] ===

Check 1 — Frontmatter Fields:    PASS
Check 2 — Multiple Phases:       PASS (7 phases found)
Check 3 — Verdict Keywords:      PASS (PASS, FAIL, CONCERNS)
Check 4 — Collaborative Protocol: PASS ("May I write" found)
Check 5 — Next-Step Handoff:     WARN (no follow-up section found)
Check 6 — Fork Context Complexity: PASS (8 phases, context: fork set)
Check 7 — Argument Hint:         PASS

Observations (not scored):
  Delegation, "Phase 3: Implementation" (line 202): ux-designer, ui-programmer.
    The brief names the output file and limits but no sources to read.

Compatibility (not scored):
  questions: AskUserQuestion (lines 13, 88) · shell-lines: shell-line (line 10)
  frontmatter: allowed-tools, argument-hint, model, user-invocable (lines 4-7)

Verdict: WARNINGS (1 warning, 0 failures)
Recommended: Add a "Follow-Up Actions" section at the end of the skill.
```

For a single agent there is no verdict, only observations:
```
=== Agent Static Check: qa-lead ===

Model: inherit · Effort: unset · Turn limit: 20
Tools: Read, Glob, Grep, Write, Edit, Bash. Fits the job (it writes test plans).
Observations (not scored):
  asks-user (lines 31, 52): tells the agent to get approval before writing.
  overlap with qa-tester (creation, regression, test): each still singled out.
Compatibility (not scored):
  frontmatter: tools, tools-string, model, maxTurns (lines 4-6)
```

A WARN or FAIL line names its cause in parentheses, and any verdict other than
COMPLIANT ends with a `Recommended:` line naming the fix.

The single-skill `Verdict:` is one of four values, the same as the `static all`
Result column: **COMPLIANT** (no warnings, no failures), **WARNINGS** (warnings,
no failures), **NON-COMPLIANT** (any FAIL), or **NOT ASSESSED** (the file could
not be read or parsed, or its checks could not run — name the reason).

For `static all`, produce a summary table then list any non-compliant skills:
```
=== Skill Static Check: All 75 Skills ===

Skill                  | Result       | Issues
-----------------------|--------------|-------
gate-check             | COMPLIANT    |
design-review          | COMPLIANT    |
story-readiness        | WARNINGS     | Check 5: no handoff
...

Summary: 48 COMPLIANT, 3 WARNINGS, 1 NON-COMPLIANT, 1 NOT ASSESSED
Aggregate Verdict: N WARNINGS / N FAILURES / N NOT ASSESSED

Agents (observations, not scored): 49 read
  asks-user: N agents · agent-type-list: N · preload-off: N · frontmatter: N
  Overlap pairs: [each pair, with whether both are still singled out]
  Delegation blocks: N in N skills; [the ones whose brief lacks a part]

Compatibility (not scored): N FOUND lines in N of N files read
  [feature]: [construct] N files, N hits; ...   (one line per feature)
```

**`NOT ASSESSED` is a per-skill result here, not only an aggregate line.** A skill
whose file is missing or otherwise unreadable (permissions, not found), so no
check could even start, is reported as `NOT ASSESSED` with the reason — never
omitted from the table and never counted as COMPLIANT. Ranked **above
COMPLIANT**, **below WARNINGS and NON-COMPLIANT**. A file that *was* read but
whose frontmatter does not parse is a different case: Check 1 fails on it (see
above), so it is reported **NON-COMPLIANT**, not NOT ASSESSED — the defect is in
the skill, not in the linter's access to it.

**And state the denominator.** `All 75 Skills` in the header must be the number
actually examined, not the number that exist: report `[N] of [M] skills checked`
whenever they differ. A summary whose counts silently sum to less than its own
title is the failure this skill is supposed to catch in others.

No file writes in static mode.

---

## Phase 2B: Spec Mode — Behavioral Verifier

### Step 1 — Locate Files

Use the skill or agent file resolved in Phase 1.
Look up the spec path from `studio-tests/catalog.yaml` — use the
`spec:` field on the matching `skills:` or `agents:` entry.

If either is missing:
- Missing skill or agent: the Phase 1 message.
- Missing spec path in catalog: "No spec path set for '[name]' in catalog.yaml."
- Spec file not found at path: "Spec file missing at [path]. Run `/skill-test audit`
  to see coverage gaps."

### Step 2 — Read Both Files

Read the skill — its `SKILL.md` and every file in its `references/` folder — or
the agent file, and the test spec file, completely.

### Step 3 — Evaluate Assertions

**Evaluate against what the model running it can see.** A skill runs in a
session, and a spawned agent in its own context, and both have the project's
`CLAUDE.md` loaded along with every file it imports on an `@path` line (a
spawned agent quotes `coordination-rules.md` word for word without reading it).
Read those files too. A rule stated there counts for every skill and agent —
cite the file it came from. Where the skill's or agent's own file contradicts
it, the own file wins: it is the more specific instruction.

**For an agent**, the spec's sections are evaluated against the agent file —
and against every skill its frontmatter lists under `skills:`, which Claude
Code loads into the agent at launch:

- **Static Assertions** — check each against the agent's frontmatter and body.
  An assertion that names a literal value (a `model:` alias, a frontmatter key,
  a tool name) is an exact comparison with the file: `model: inherit` does not
  satisfy "Model tier is `sonnet`", and a near match is FAIL, never PARTIAL.
- **Test Cases** — evaluate each case's expected behavior against the agent's
  written instructions, the same way a skill's are evaluated below. A case
  that names a gate ID (`LP-FEASIBILITY`, `CD-PILLARS`, …) is that gate's
  invocation: the spawning skill has the agent read
  `.claude/docs/director-gates/[gate-id].md` first, so that file's Prompt and
  Verdicts are the agent's instructions for the case — read it too.
- **Redirect and escalation cases** — the agent is asked for work another role
  owns, or meets a conflict it cannot settle. The case is met when the loaded
  `coordination-rules.md` covers the step — rule 2 (no binding decisions
  outside its domain), rule 3 (escalate a conflict to the shared parent) or
  rule 5 (no files outside its directories without delegation) — **and** the
  agent's own file names the owning role in its collaborator, delegation,
  escalation or "must not" lists. Cite both; do not require the agent to
  restate the redirect in its own words. It is a FAIL when the agent's file
  claims that work for itself, or when no loaded file names who owns it.
- **Protocol Compliance** — use the spec's own `## Protocol Compliance` list in
  place of the four skill checks below.

**For a skill**, check each of the spec's **Static Assertions** against the
skill's frontmatter and body (`SKILL.md` and its `references/` files) the same
way; a literal value is an exact
comparison. `/skill-test static` runs only its 7 fixed checks, so a spec's own
static lines — a verdict keyword, a phase, "May I write" before a named file —
are evaluated here or nowhere.

The rest of this step applies to skills and agents alike.

For each **Test Case** in the spec:

1. Read the **Fixture** description (assumed state of project files)
2. Read the **Expected behavior** steps
3. Read each **Assertion** checkbox

A case with no **Fixture** reads its **Input** as the fixture; a case with no
**Assertions** list treats each **Expected behavior** bullet as an assertion —
most agent specs are written this way, and a case verdict is not left undefined
just because it has no separate checklist.

For each assertion, evaluate whether the skill's written instructions, if
followed correctly given the fixture state, would satisfy it. This is a
Claude-evaluated reasoning check, not code execution.

Mark each assertion:
- **PASS** — skill instructions clearly satisfy this assertion
- **PARTIAL** — skill instructions partially address it, but with ambiguity
- **FAIL** — skill instructions would NOT satisfy this assertion given the fixture
- **NOT ASSESSED** — the assertion could not be evaluated at all: it names a
  fixture state the spec never defines, depends on runtime behavior no static
  read can settle, or references a file or section that does not exist (a file
  that is merely silent on the behaviour is FAIL or PARTIAL, not this). Rank it
  **above PASS** (an assertion nobody could evaluate has not been satisfied) and
  **below PARTIAL and FAIL** (an ambiguity somebody identified is more actionable
  than one nobody could reach). Do not resolve an unevaluable assertion to PASS
  because the skill "probably" handles it — that judgement is what the spec exists
  to replace.

For a skill's **Protocol Compliance** section (always present), evaluate each line
of the spec's own list against the skill's files exactly as you evaluate a case
assertion — PASS, PARTIAL, FAIL or NOT ASSESSED. Specs put rules there that no
case repeats ("covered by the protocol compliance assertions above"), so a
list that is not evaluated is a set of rules nobody checks. These four checks are
the floor, added when the list does not already cover them:
- Check whether the skill requires "May I write" before file writes
- Check whether the skill presents findings before requesting approval
- Check whether the skill ends with a recommended next step
- Check whether the skill avoids auto-creating files without approval

### Step 4 — Build Report

```
=== Skill Spec Test: /[name] ===
Date: [date]
Spec: studio-tests/skills/[category]/[name].md

Static Assertions:
  [PASS] [assertion text]
  [NOT ASSESSED] [assertion text]
     Reason: [why it could not be evaluated]

Case 1: [Happy Path — name]
  Fixture: [summary]
  Assertions:
    [PASS] [assertion text]
    [FAIL] [assertion text]
       Reason: The skill's Phase 3 says "..." but the fixture state means "..."
  Case Verdict: FAIL

Case 2: [Edge Case — name]
  ...
  Case Verdict: PASS

Protocol Compliance:
  [PASS] Uses "May I write" before file writes
  [PASS] Presents findings before asking approval
  [PARTIAL] No explicit next-step handoff at end

Overall Verdict: FAIL (1 case failed, 1 protocol line partial)
```

A Case Verdict is the worst result among its assertions, and the Overall
Verdict the worst across the static assertions, the cases and Protocol
Compliance, in this order:
FAIL, PARTIAL, NOT ASSESSED, PASS. An assertion nobody could evaluate keeps the
overall result from reading PASS.

For an agent, the header is `=== Agent Spec Test: [name] ===`, `Spec:` is its
path under `studio-tests/agents/`, and a `Static Assertions:`
block comes before Case 1.

### Step 5 — Offer to Write Results

"May I write these results to `studio-tests/results/skill-test-spec-[name]-[date].md`
and update `studio-tests/catalog.yaml`?"

If yes:
- Write results file to `studio-tests/results/`
- Update the skill's or agent's entry in `studio-tests/catalog.yaml`:
  - `last_spec: [date]`
  - `last_spec_result: PASS|PARTIAL|FAIL|NOT ASSESSED` — the Overall Verdict

---

## Phase 2D: Category Mode — Rubric Evaluation

### Step 1 — Locate Skill and Category

Use the skill or agent file resolved in Phase 1.
Look up the `category:` field on its `skills:` or `agents:` entry in
`studio-tests/catalog.yaml`.

If neither file exists: the Phase 1 message.
If no `category:` field: "No category assigned for '[name]' in catalog.yaml.
Add `category: [name]` to its entry first."

For `category all`: collect every skill and every agent with a `category:` field
and process each, reporting skills and agents in separate tables.
`category: utility` skills are evaluated against U1 (static checks pass) and U2
(gate mode correct if applicable) only — skip to the static mode for U1.
Cross-check against `.claude/skills/*/SKILL.md` and `.claude/agents/*.md`
(Audit mode's Step 2 glob): list any skill or agent missing from the catalog, or
catalogued with no `category:`, by name as **NOT ASSESSED** — never silently
excluded from the run.

### Step 2 — Read Rubric Section

Read `studio-tests/quality-rubric.md`.
Extract the section matching the category (e.g., `### gate`, `### team`; an
agent's category is under `## Agent Categories`, e.g. `### director`).
If the rubric has no section for the category, the result is **NOT ASSESSED**:
name the missing section, and never borrow another category's metrics.

### Step 3 — Read Skill

Read the skill's `SKILL.md` and every file in its `references/` folder, or the
agent's `.claude/agents/[name].md`, fully,
and the project context Phase 2B Step 3 describes — a metric met by a rule in
`CLAUDE.md` or a file it imports is met, citing that file. Its rule for
redirect and escalation cases decides the domain, deferral and escalation
metrics too (D2, D3, L2, S1–S3, O2).

### Step 4 — Evaluate Rubric Metrics

For each metric in the category's rubric table:
1. Check whether the skill's or agent's written instructions clearly satisfy the criterion
2. Mark PASS, FAIL, WARN, or NOT ASSESSED (the metric could not be evaluated — name why)
3. For FAIL/WARN/NOT ASSESSED, identify the exact gap in the text (quote the
   relevant section, note its absence, or name what could not be evaluated)

### Step 5 — Output Report

For an agent, the header is `=== Agent Category Check: [name] ([category]) ===`.

```
=== Skill Category Check: /[name] ([category]) ===

Metric G1 — Review mode read:      PASS
Metric G2 — Director panel width:  FAIL
  Gap: Phase 3 spawns only CD-PHASE-GATE at `workflow: full`; TD-PHASE-GATE, PR-PHASE-GATE, AD-PHASE-GATE absent
Metric G3 — Lean mode: PHASE-GATE only: PASS
Metric G4 — Solo mode: no directors:    PASS
Metric G5 — No auto-advance:       PASS

Verdict: FAIL (1 failure, 0 warnings)
Fix: Size the Phase 3 panel from `modes.workflow` — PR at `minimal`, TD + PR at
     `standard`, all four at `full` — and name any perspective a narrower panel leaves out.
```

The category verdict, first match wins: **FAIL** when any metric fails; else
**WARNINGS** when any metric warns; else **NOT ASSESSED** when any metric could
not be evaluated (a rubric section missing, a file unreadable); else **PASS**
when every metric passes — the same ranking as static and spec mode. It is
`last_category_result` in the catalog.

### Step 6 — Offer to Update Catalog

"May I update `studio-tests/catalog.yaml` to record this category check
(`last_category`, `last_category_result`) for [name]?"

---

## Phase 2C: Audit Mode — Coverage Report

### Step 1 — Read Catalog

Read `studio-tests/catalog.yaml`. If missing, note that catalog doesn't exist
yet (first-run state).

### Step 2 — Enumerate All Skills and Agents

Glob `.claude/skills/*/SKILL.md` to get the complete list of skills.
Extract skill name from each path (directory name).

Glob `.claude/agents/*.md` for the complete list of agents — the repo itself,
not the catalog, is the covered set (`.claude/rules/skill-authoring.md` §5:
gates derive their covered set, they do not enumerate it). Compare both globs
against the catalog's `skills:`/`agents:` entries and report any skill or agent
missing from the catalog by name, so an uncatalogued one cannot drop out silently.
Skip the old-name aliases (`changelog`, `help`, `settings`, each described as
"Old name of …"): they are not in the catalog and are not gaps.

### Step 3 — Build Skill Coverage Table

For each skill:
- Check if a spec file exists (use the `spec:` path from catalog, or glob `studio-tests/skills/*/[name].md`)
- Look up `last_static`, `last_static_result`, `last_spec`, `last_spec_result`,
  `last_category`, `last_category_result`, `category` from catalog (or mark as
  "never" / "—" if not in catalog)
- Priority comes from catalog `priority:` field (critical/high/medium/low)

### Step 3b — Build Agent Coverage Table

For each agent in catalog's `agents:` section:
- Check if a spec file exists (use the `spec:` path from catalog, or glob `studio-tests/agents/*/[name].md`)
- Look up `last_spec`, `last_spec_result`, `last_category`,
  `last_category_result`, `category` from catalog

### Step 4 — Output Report

```
=== Skill Test Coverage Audit ===
Date: [date]

SKILLS (75 total)
Specs written: 75 (100%) | Never static tested: 75 | Never category tested: 75

Skill                  | Cat      | Has Spec | Last Static | S.Result | Last Cat | C.Result | Priority
-----------------------|----------|----------|-------------|----------|----------|----------|----------
gate-check             | gate     | YES      | never       | —        | never    | —        | critical
design-review          | review   | YES      | never       | —        | never    | —        | critical
...

AGENTS (49 total)
Agent specs written: 49 (100%)

Agent                  | Category   | Has Spec | Last Spec   | Result | Last Cat | C.Result
-----------------------|------------|----------|-------------|--------|----------|----------
creative-director      | director   | YES      | never       | —      | never    | —
technical-director     | director   | YES      | never       | —      | never    | —
...

Top 5 Priority Gaps (skills with no spec, critical/high priority):
(none if all specs are written)

Skill coverage:  75/75 specs (100%)
Agent coverage:  49/49 specs (100%)
```

No file writes in audit mode.

Offer: "Would you like to run `/skill-test static all` to check structural
compliance across all skills? `/skill-test category all` to run category rubric
checks? Or `/skill-test spec [name]` to run a specific behavioral test?"

---

## Phase 3: Recommended Next Steps

After any mode completes, offer contextual follow-up:

- After `static [name]`: "Run `/skill-test spec [name]` to validate behavioral
  correctness if a test spec exists."
- After `static all` with failures: "Address NON-COMPLIANT skills first. Run
  `/skill-test static [name]` individually for detailed remediation guidance."
- After `spec [name]` PASS: "Update `studio-tests/catalog.yaml` to record this
  pass date. Consider running `/skill-test audit` to find the next spec gap."
- After `spec [name]` FAIL: "Review the failing assertions and update the skill
  or agent, or the test spec, to resolve the mismatch."
- After `audit`: "Start with the critical-priority gaps. Use the spec template
  at `studio-tests/templates/skill-test-spec.md` (agents:
  `agent-test-spec.md`) to create new specs."
