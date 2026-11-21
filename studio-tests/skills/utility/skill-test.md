# Skill Test Spec: /skill-test

## Skill Summary

`/skill-test` validates skills (`.claude/skills/*/SKILL.md`) and agents
(`.claude/agents/*.md`). It has four modes:

- **static** `[name | all]`: runs 7 structural checks on a skill (frontmatter,
  phases, verdict keywords, ask-before-write language, next-step handoff, fork
  complexity, argument hint) and reports each as PASS / WARN / FAIL. A skill split
  into `references/` files is read whole (`SKILL.md` and every references file) for
  checks 2-5; the frontmatter checks (1, 6, 7) read `SKILL.md` only. Per-skill
  results are COMPLIANT, WARNINGS, NON-COMPLIANT or NOT ASSESSED. It also runs
  `.claude/scripts/agent-check.sh` and reports its agent and delegation lines as
  observations that never change a verdict, and runs
  `.claude/scripts/compat-inventory.sh` and reports each place the file depends on
  something only Claude Code provides, by feature, the same way; given an agent
  name, it reports only those observations, with no verdict. Writes nothing.
- **spec** `[skill-or-agent-name]`: resolves the name through
  `studio-tests/catalog.yaml`, reads the file and the spec at the
  entry's `spec:` path, plus `CLAUDE.md` and every file it imports with `@path`,
  and marks each assertion — the spec's Static Assertions included, for a skill
  as for an agent — PASS / PARTIAL / FAIL / NOT ASSESSED. Case and Overall
  Verdicts are the worst result beneath them (FAIL, PARTIAL, NOT ASSESSED,
  PASS). It then asks "May I write these results to
  `studio-tests/results/…` and update `catalog.yaml`?"
- **category** `[name | all]`: scores the skill or agent against its section of
  `studio-tests/quality-rubric.md` (PASS / FAIL / WARN per
  metric) and asks "May I update `catalog.yaml` …?" before recording it.
- **audit** (also the no-argument default): coverage table of every skill and
  every catalogued agent. Writes nothing and issues no verdict.

No director gates apply.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdicts: COMPLIANT, WARNINGS, NON-COMPLIANT, NOT ASSESSED (static mode); PASS, PARTIAL, FAIL, NOT ASSESSED (spec mode)
- [ ] Contains "May I write" before writing spec results, and "May I update" before recording a category check in `catalog.yaml`
- [ ] Has a next-step handoff (Phase 3: contextual follow-up after each mode)

---

## Director Gate Checks

None. `/skill-test` is a meta-utility skill. No director gates apply.

---

## Fixture Defaults

Every case's `project.yaml` sets `modes.rigor: minimal` and
`modes.automation: collaborative`, with no `project.local.yaml`, unless its own
Fixture says otherwise. Rules: `studio-tests/CLAUDE.md` §
Fixture defaults.

---

## Test Cases

### Case 1: Static Mode — Well-formed skill, all 7 checks pass, COMPLIANT

**Fixture:**
- `.claude/skills/brainstorm/SKILL.md` exists and satisfies all 7 checks:
  - Has all 5 required frontmatter fields
  - Has ≥2 phase headings
  - Has verdict keywords
  - Has "May I write" language
  - Ends with a next-step handoff
  - Does not set `context: fork`
  - `argument-hint` matches the modes its Parse Arguments phase documents

**Input:** `/skill-test static brainstorm`

**Expected behavior:**
1. Skill reads `.claude/skills/brainstorm/SKILL.md` fully
2. Skill runs all 7 structural checks
3. Output is the single-skill block `=== Skill Static Check: /brainstorm ===`
   listing Check 1 – Check 7, each PASS
4. Verdict is COMPLIANT
5. Phase 3 follow-up suggests `/skill-test spec brainstorm`

**Assertions:**
- [ ] Exactly 7 structural checks are reported
- [ ] All 7 are marked PASS
- [ ] Verdict is COMPLIANT
- [ ] No files are written and no "May I write" is asked

---

### Case 2: Static Mode — Skill Missing Ask-Before-Write Despite Write Tool in allowed-tools

**Fixture:**
- `.claude/skills/some-skill/SKILL.md` has `Write` in `allowed-tools` frontmatter
- The body has no ask-before-write language in any form Check 4 accepts:
  no "May I write", no "before writing"/"approval" near a write instruction,
  no "ask" and "write" in the same section

**Input:** `/skill-test static some-skill`

**Expected behavior:**
1. Skill reads `some-skill/SKILL.md`
2. Check 4 (collaborative protocol) is FAIL — `Write` is in `allowed-tools` and
   no ask-before-write language is found
3. The other six checks are listed with their own results
4. Verdict is NON-COMPLIANT, with a Recommended line naming the fix

**Assertions:**
- [ ] Check 4 is marked FAIL (not WARN — Write is in allowed-tools)
- [ ] The Check 4 line or the Recommended line names the mismatch (Write tool without ask-before-write language)
- [ ] Verdict is NON-COMPLIANT
- [ ] Other checks are shown (not only the failure)

---

### Case 3: Spec Mode — gate-check Skill Evaluated Against Its Spec

**Fixture:**
- `catalog.yaml` lists `gate-check` under `skills:` with
  `spec: studio-tests/skills/gate/gate-check.md`
- The sandbox's copy of that spec is the live one (9 test cases and a Static
  Assertions list) with one Static Assertion added: "Balance values link to
  their source formula or rationale" — met only by
  `.claude/docs/coding-standards.md` (imported by `CLAUDE.md`), not by the skill
  or its gate files themselves. The live spec has no such line, so the copy is
  edited for the case
- `.claude/skills/gate-check/` holds `SKILL.md` and 12 `references/` files
  (6 phase files, 6 gate files)
- The user declines the results write

**Input:** `/skill-test spec gate-check`

**Expected behavior:**
1. Skill resolves `gate-check` as a skill via the catalog and takes the spec
   path from its `spec:` field
2. Skill reads the skill — `SKILL.md` and all 12 `references/` files — the
   spec, `CLAUDE.md` and its `@`-imported files
3. The spec's Static Assertions are checked against `SKILL.md` and its
   `references/` files in a
   `Static Assertions:` block before Case 1
4. Each assertion is marked PASS / PARTIAL / FAIL / NOT ASSESSED, with a Reason
   for each non-PASS; the balance-values assertion is PASS, citing
   `coding-standards.md`
5. Each case gets a Case Verdict; the report ends with an Overall Verdict, the
   worst result across the static assertions, the cases and Protocol Compliance
6. Skill asks "May I write these results to
   `studio-tests/results/skill-test-spec-gate-check-[date].md`
   and update `studio-tests/catalog.yaml`?"; on decline nothing is written

**Assertions:**
- [ ] The spec path comes from the catalog `spec:` field
- [ ] The spec's Static Assertions are evaluated against `SKILL.md` and its `references/` files, not skipped as "static mode's job"
- [ ] An assertion met only in a `references/` file is PASS, not FAIL for being absent from `SKILL.md`
- [ ] All 9 test cases are evaluated, each with its own Case Verdict
- [ ] The balance-values assertion is PASS, and the report cites `coding-standards.md` as the file it came from
- [ ] Overall verdict is the worst result — FAIL, PARTIAL, NOT ASSESSED or PASS; an assertion-level NOT ASSESSED keeps it from PASS
- [ ] No file is written without approval (declined here, so nothing is written)

---

### Case 4: Audit Mode — Coverage Table of All Skills and Agents

**Fixture:**
- `.claude/skills/` contains 74 skill directories; 73 have a spec at the path
  their catalog entry names (in the sandbox, one skill's catalog `spec:` is
  emptied and its spec file removed — every live skill has a spec)
- `catalog.yaml` has an `agents:` section with 49 entries, all with specs

**Input:** `/skill-test audit` (and, separately, `/skill-test` with no argument)

**Expected behavior:**
1. Both inputs run audit mode — no argument is the audit default, not a usage
   message
2. Skill globs `.claude/skills/*/SKILL.md` for skills and reads the catalog's
   `agents:` section for agents
3. For each skill: Has Spec (from the catalog `spec:` path, or a glob under
   `studio-tests/skills/`), last static/category dates and
   results, category, priority
4. Separate SKILLS and AGENTS tables, a Top 5 Priority Gaps list, and the lines
   `Skill coverage: 73/74 specs (99%)` and `Agent coverage: 49/49 specs (100%)`
5. No verdict line; the output ends with the offer to run `static all`,
   `category all` or `spec [name]`

**Assertions:**
- [ ] `/skill-test` with no argument produces this audit, not usage text
- [ ] All skill directories are enumerated (not just a sample)
- [ ] "Has Spec" column is accurate for each entry
- [ ] Summary coverage counts are correct for skills and for agents
- [ ] No files are written and no verdict is issued in audit mode

---

### Case 5: Category Mode — Gate Skill Evaluated Against Quality Rubric

**Fixture:**
- `studio-tests/quality-rubric.md` has a `### gate` section with
  metrics G1–G5
- `catalog.yaml` gives `gate-check` `category: gate`
- `.claude/skills/gate-check/SKILL.md` meets every metric except G2 — Director
  panel width (only CD-PHASE-GATE is spawned at `workflow: full`)
- The user approves the catalog update

**Input:** `/skill-test category gate-check`

**Expected behavior:**
1. Skill reads the `category:` from the catalog, then the `### gate` section of the rubric
2. Skill reads the skill and the `CLAUDE.md` context, and evaluates G1–G5
3. Each metric is marked PASS, FAIL or WARN; G2 is FAIL with a quoted Gap line
4. Report ends `Verdict: FAIL (1 failure, 0 warnings)` and a Fix line
5. Skill asks "May I update `studio-tests/catalog.yaml` to record
   this category check (`last_category`, `last_category_result`) for gate-check?"

**Assertions:**
- [ ] All gate metrics (G1–G5) from quality-rubric.md are evaluated
- [ ] Each metric has an individual PASS / FAIL / WARN result, with a Gap line for G2
- [ ] Overall verdict reflects the metric results
- [ ] The catalog is updated only after the "May I update" approval

---

### Case 6: Spec Mode — Agent Name Resolves to the Agent

**Fixture:**
- `catalog.yaml` lists `creative-director` under `agents:` with
  `spec: studio-tests/agents/directors/creative-director.md`
- `.claude/agents/creative-director.md` declares `model: opus`; there is no
  `.claude/skills/creative-director/`
- The spec asserts "Model tier is `opus`"
- Suppose one spec case is a redirect: the agent is asked to pick the project's
  engine. The agent's "What This Agent Must NOT Do" list says "Make engine or
  architecture choices (delegate to technical-director)"; it never restates the
  redirect in its own words

**Input:** `/skill-test spec creative-director`

**Expected behavior:**
1. Skill resolves the name through the catalog's `agents:` section — it does not
   report "Skill 'creative-director' not found"
2. Skill reads the agent file and the agent spec
3. Static assertions are compared exactly with the frontmatter: "Model tier is
   `opus`" PASSES against `model: opus`, and would FAIL (not PARTIAL) against
   `model: inherit`
4. Test cases are evaluated against the agent's instructions; Protocol
   Compliance uses the spec's own list
5. The redirect case is met: the loaded `coordination-rules.md` rule 2 covers
   it and the agent's must-not list names technical-director — the report cites
   both
6. Report header is `=== Agent Spec Test: creative-director ===`

**Assertions:**
- [ ] The agent is resolved and evaluated, not refused as a missing skill
- [ ] A literal-value assertion is an exact comparison (near match = FAIL)
- [ ] Every case and the spec's Protocol Compliance list are evaluated
- [ ] The redirect case passes on `coordination-rules.md` plus the agent's own must-not list, both cited — the agent is not required to restate it
- [ ] No files are written without approval

---

### Case 7: Static All — an unreadable skill is NOT ASSESSED and counted

**Fixture:**
- `.claude/skills/` holds 74 skill directories; one `SKILL.md` cannot be
  read (the Read call fails — permission denied), so none of its checks can
  start. (A file that is read but whose frontmatter does not parse is a
  different case: Check 1 fails and it is NON-COMPLIANT.)

**Input:** `/skill-test static all`

**Expected behavior:**
1. The 73 readable skills are checked and listed with their Result
2. The unreadable skill appears in the table as `NOT ASSESSED`, with the
   reason — not omitted, not COMPLIANT
3. The header states the denominator, `73 of 74 skills checked`, and the
   Summary line counts the NOT ASSESSED skill

**Assertions:**
- [ ] The unreadable skill's Result is NOT ASSESSED, with a reason
- [ ] The header or summary reads `73 of 74 skills checked`
- [ ] The Summary counts sum to the skills in the table

---

### Case 8: Spec Mode — an unevaluable assertion makes the run NOT ASSESSED

**Fixture:**
- `.claude/skills/brainstorm/SKILL.md` and its spec exist
- Every assertion in the spec passes except one, which names a fixture file
  the spec never defines
- The user approves the results write

**Input:** `/skill-test spec brainstorm`

**Expected behavior:**
1. That assertion is NOT ASSESSED, with a Reason — never resolved to PASS
   because the skill "probably" handles it
2. Its Case Verdict is NOT ASSESSED; with no PARTIAL or FAIL anywhere, the
   Overall Verdict is NOT ASSESSED
3. On approval, `catalog.yaml` records `last_spec_result: NOT ASSESSED`

**Assertions:**
- [ ] The unevaluable assertion is NOT ASSESSED, not PASS
- [ ] Overall Verdict is NOT ASSESSED, not PASS
- [ ] The catalog records `NOT ASSESSED` as the result

---

### Case 9: Category Mode — no rubric section for the category

**Fixture:**
- `catalog.yaml` gives `some-skill` `category: tooling` — a category added to
  the catalog before its rubric section was written
- `studio-tests/quality-rubric.md` has no `tooling` section

**Input:** `/skill-test category some-skill`

**Expected behavior:**
1. Skill reads the category, then looks for its rubric section and finds none
2. The result is NOT ASSESSED, naming the missing `tooling` section
3. No other category's metrics are borrowed to fill the gap — not even
   `utility`'s

**Assertions:**
- [ ] The result is NOT ASSESSED and names the missing rubric section
- [ ] No metric from another category is evaluated in its place

---

### Case 10: Static Mode — a split skill is read whole, but its frontmatter comes from SKILL.md

**Fixture:**
- `.claude/skills/split-skill/SKILL.md` has all five frontmatter fields, no
  `context:` key, and two phase headings (`## Phase 1: Gather`, `## Phase 2: Report`)
  that each say "Read `references/N-name.md` now and follow it". It holds no verdict
  keyword, no ask-before-write language and no next-step handoff itself
- `.claude/skills/split-skill/references/2-report.md` holds `Verdict: **COMPLETE**`,
  the line "May I write this report to `production/qa/report.md`?" and a closing
  "Next step: `/gate-check`"; `references/1-gather.md` holds only instructions
- Run A: as above. Run B: the same skill, except `argument-hint:` is missing from
  `SKILL.md` and appears only in a frontmatter-style block at the top of
  `references/1-gather.md`

**Input:** `/skill-test static split-skill`

**Expected behavior:**
1. Skill reads `SKILL.md` and every file in `references/` and runs the 7 checks on
   them as one skill
2. Run A: Checks 2, 3, 4 and 5 read the whole skill, so they PASS on the verdict
   keyword, the "May I write" line and the handoff found in `references/2-report.md`;
   Check 3 is not a FAIL for a verdict word absent from `SKILL.md`. Checks 1, 6 and 7
   read the `SKILL.md` frontmatter: all PASS. Verdict COMPLIANT
3. Run B: Check 1 reads `SKILL.md` only, so the missing `argument-hint:` is a FAIL
   although the references file holds one; the verdict is NON-COMPLIANT with a
   `Recommended:` line to add it to the `SKILL.md` frontmatter. Check 7 does not take
   the hint from the references file either

**Assertions:**
- [ ] Run A: Checks 3, 4 and 5 PASS on text that appears only in `references/`
- [ ] Run A: Check 3 is not a FAIL or WARN for a verdict word absent from `SKILL.md`
- [ ] Run A: the verdict is COMPLIANT and nothing is written
- [ ] Run B: Check 1 is FAIL — a frontmatter field found only in a `references/` file does not count
- [ ] Run B: the verdict is NON-COMPLIANT and the `Recommended:` line names the `SKILL.md` frontmatter

---

## Protocol Compliance

- [ ] Static mode checks exactly 7 structural assertions
- [ ] Static mode reads a split skill's `SKILL.md` and `references/` files together for checks 2-5, and `SKILL.md` alone for the frontmatter checks (1, 6, 7)
- [ ] Spec mode evaluates each test case from the spec file individually, and a skill spec's Static Assertions against the SKILL.md and its references/ files
- [ ] Each mode can report NOT ASSESSED — per skill in static mode, per assertion and overall in spec mode, and for a missing rubric section in category mode
- [ ] Audit mode covers all skills AND agents (not just one category)
- [ ] Spec and category modes accept an agent name as well as a skill name
- [ ] Category mode reads quality-rubric.md to get criteria (not hardcoded)
- [ ] Static and audit modes write nothing; spec and category modes write only after "May I write" / "May I update" approval
- [ ] After a spec FAIL, recommends reviewing the failing assertions and updating the skill or agent, or the spec

---

## Coverage Notes

- The skill-test skill is self-referential (it can test itself). The static
  mode case for skill-test's own SKILL.md is not separately fixture-tested to
  avoid infinite recursion in test design.
- The specific 7 structural checks are defined in the skill body; only Check 4
  (ask-before-write) is individually tested here because it has the most
  nuanced logic. The single-skill NOT ASSESSED verdict follows Case 7's
  per-skill rule; not separately tested.
- Audit mode counts are approximate — the exact number of skills and agents will
  change as the system grows; the fixture's numbers are illustrative.
- A spec case that names a director gate ID has the agent evaluated against
  `.claude/docs/director-gates/[gate-id].md`; not separately fixture-tested.
