# Skill Test Spec: /architecture-review

## Skill Summary

`/architecture-review` is an Opus-tier skill that checks whether the whole body
of architectural decisions covers the game's design. It extracts technical
requirements (TR-IDs) from every GDD, maps each one to the ADRs that cover it
in a traceability matrix, detects cross-ADR conflicts, orders ADRs by
dependency (via `.claude/scripts/adr-dep-graph.sh`), audits engine
compatibility against `docs/engine-reference/`, consults the primary engine
specialist, and checks `docs/architecture/architecture.md` coverage of the
systems index. It produces a PASS / CONCERNS / NOT ASSESSED / FAIL verdict.

It takes a focus argument (`full` by default, or `coverage`, `consistency`,
`engine`, `single-gdd [path]`, `rtm`). After the report, it asks via
`AskUserQuestion` before writing the review report
(`docs/architecture/architecture-review-[date].md`), the traceability index and
`docs/architecture/tr-registry.yaml`. It is the quality gate between Technical
Setup and Pre-Production.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: PASS, CONCERNS, NOT ASSESSED, FAIL
- [ ] `allowed-tools` includes Write, so write-approval language is present ("May I update the systems index?", "May I update `docs/architecture/tr-registry.yaml`…")
- [ ] Has a next-step handoff at the end (Phase 9)
- [ ] Documents the argument modes: `full`, `coverage`, `consistency`, `engine`, `single-gdd [path]`, `rtm`

---

## Director Gate Checks

None. This skill resolves no `review_mode` (its config block requests only
`automation` and `workflow`) and spawns no director gate. The only agent it
spawns is the primary engine specialist in Phase 5. The architecture sign-off
gates (TD-ARCHITECTURE, LP-FEASIBILITY) belong to `/create-architecture`, not to
this skill.

---

## Test Cases

### Case 1: Happy Path — every requirement covered by an Accepted ADR

**Fixture:**
- `project.yaml` sets `modes.workflow: full`, `engine.name: Godot`, `engine.version: 4.6`
- `design/gdd/systems-index.md` plus two system GDDs (`combat.md`, `inventory.md`),
  each with a `## Summary` and technical requirements in its Detailed Rules
- `docs/architecture/adr-0001-*.md` … `adr-0003-*.md`, each with `## Status: Accepted`,
  `## GDD Requirements Addressed`, `## Engine Compatibility` and `## ADR Dependencies`,
  whose `**Depends On**` row is filled in — `None` for `adr-0001`, `ADR-0001` for
  `adr-0002` and `adr-0003` — so `adr-dep-graph.sh` finds real edges and lists no
  ADR under `NO_DEPS_SECTION`; together they cover every requirement; no two contradict
- `docs/architecture/architecture.md` exists and names every system in the index
- No prior `docs/architecture/architecture-review-*.md` report
- Pre-gate items all exist: `tests/unit/`, `tests/integration/` (the Godot test root),
  `.github/workflows/tests.yml`, `design/accessibility-requirements.md`,
  `design/ux/interaction-patterns.md`

**Input:** `/architecture-review`

**Expected behavior:**
1. Freshness check prints `RECEIPT: NONE` → full review
2. Skill counts the denominators (N_gdd, N_adr), loads the needed sections with
   targeted Greps rather than whole files, and reports
   "Loaded [N] GDDs, [M] ADRs, engine: Godot 4.6"
3. Skill extracts TR-IDs (reusing any existing `tr-registry.yaml` IDs) and builds the matrix
4. Skill runs `bash .claude/scripts/adr-dep-graph.sh` and prints the recommended implementation order
5. Skill runs the engine audit and consults `godot-specialist`
6. Report ends with `### Verdict: PASS`
7. Phase 8 asks what to write; Phase 9 offers `/gate-check pre-production`

**Assertions:**
- [ ] Output reports "Loaded [N] GDDs, [M] ADRs, engine: [name + version]"
- [ ] A Traceability Matrix lists each TR-ID with its GDD, system, requirement, ADR coverage and status; every row is ✅
- [ ] The ADR dependency order comes from `adr-dep-graph.sh`, not hand-tracing, and puts `adr-0001` first; `NO_DEPS_SECTION` is empty, so the acyclic result is a clean graph rather than a structural gap
- [ ] Verdict is PASS only because all requirements are covered by **Accepted** ADRs, no conflicts exist, and engine references agree
- [ ] The report includes the `review-receipts.sh hash` lines for the ADRs and GDDs reviewed
- [ ] No file is written before the Phase 8 `AskUserQuestion` (`[A]` all three files / `[B]` report only at `docs/architecture/architecture-review-[date].md` / `[C]` nothing yet)
- [ ] The closing widget offers `/gate-check pre-production`, because every pre-gate checklist item is ✅

---

### Case 2: Failure Path — Foundation gap plus a cross-ADR ownership conflict

**Fixture:**
- As Case 1, except:
  - `save-system.md` (a Foundation-layer system) requires "Player progress
    persists between sessions" and no ADR addresses it
  - `adr-0002` and `adr-0004` are both Accepted and both claim authority over the
    player's health value

**Input:** `/architecture-review`

**Expected behavior:**
1. The persistence requirement appears as a `❌ GAP` row
2. The gap appears under "Coverage Gaps" with a suggested `/architecture-decision [title]`, Domain and Engine Risk
3. A conflict block `## Conflict: [ADR-0002] vs [ADR-0004]` is printed
4. Verdict is FAIL; Blocking Issues list at least the Foundation gap
5. Neither ADR is edited; the user decides the resolution

**Assertions:**
- [ ] Verdict is FAIL (a Foundation-layer requirement is uncovered)
- [ ] The gap row names the TR-ID, GDD and requirement, with a suggested `/architecture-decision` command
- [ ] The conflict block names both ADR numbers, a Type (State / Data ownership), what each ADR claims, the Impact, and at least two resolution options
- [ ] Skill does NOT auto-resolve the conflict or edit either ADR
- [ ] If `docs/consistency-failures.md` exists, the Phase 8 `[A]` option names it ("…and append 1 conflict entry to `docs/consistency-failures.md`") and the entry is appended only when the user picks `[A]`; `[B]` (report only) writes the report and nothing else; if the file does not exist, it is not created
- [ ] The closing widget does not offer `/gate-check`; it offers writing the missing ADR via `/architecture-decision [system]`

---

### Case 3: Partial Path — coverage resting on a Proposed ADR

**Fixture:**
- As Case 1, except `adr-0003` (the only ADR covering `TR-inventory-001`) has `## Status: Proposed`
- `adr-0004` (Accepted) has `**Depends On**: ADR-0003` in its `## ADR Dependencies` table

**Input:** `/architecture-review`

**Expected behavior:**
1. `TR-inventory-001` is marked `🟡 Covered (Proposed)`, not ✅
2. The dependency analysis flags "ADR-0004 depends on ADR-0003 — but ADR-0003 is still Proposed"
3. Verdict is capped at CONCERNS and names the way out: `/architecture-decision accept ADR-0003`

**Assertions:**
- [ ] Skill reads each ADR's `## Status` before marking coverage; a Proposed ADR never yields ✅
- [ ] Verdict is CONCERNS (not PASS) when coverage rests on a Proposed ADR
- [ ] Output names `/architecture-decision accept ADR-0003` as the route to clear it
- [ ] The unresolved dependency on a Proposed ADR is flagged

---

### Case 4: Edge Case — missing architecture document; malformed ADRs

**Case 4a — no master architecture document:**
- As Case 1, but `docs/architecture/architecture.md` does not exist

**Assertions (4a):**
- [ ] The report states `Architecture document coverage: NOT ASSESSED — no docs/architecture/architecture.md` as a named line item, rather than showing no Phase 6 findings
- [ ] The overall verdict is NOT ASSESSED, not PASS: Phase 6 is part of the `full` scope and did not run, even though every requirement is covered (a CONCERNS or FAIL finding elsewhere would still outrank it)

**Case 4b — ADRs present but none has a scannable section:**
- As Case 1 (`modes.workflow: full` — at the default `minimal` tier, a `project.yaml` with no `modes` block,
  the skill does not apply), except the three `docs/architecture/adr-*.md` files
  carry none of the six headings the Phase 1b scan looks for: `## Status`,
  `## Decision`, `## GDD Requirements Addressed`, `## Engine Compatibility`,
  `## ADR Dependencies`, `## Performance Implications`

**Assertions (4b):**
- [ ] Skill reports "[N] ADRs found, none carries a scannable section — run `/architecture-decision retrofit [file]` on each" (subcommand first — with the path first, `/architecture-decision` would start authoring a new ADR instead)
- [ ] Skill does NOT report zero coverage or a design failure — it is a format failure
- [ ] Rows whose ADR has no `## Status` are `❓ Not assessed`, and the verdict is not PASS — nor FAIL on coverage grounds, since coverage is unknown rather than absent

---

### Case 5: Engine specialist consultation — configured vs unconfigured engine

**Case 5a — engine configured:** Case 1 fixture (`engine.name: Godot`)

**Expected behavior:**
1. After the Phase 5 engine audit, skill spawns `godot-specialist` via `Agent`,
   passing the engine-specific ADRs, the engine reference docs and the audit findings
2. The specialist's findings appear under `### Engine Specialist Findings` and count toward the verdict

**Assertions (5a):**
- [ ] The specialist is resolved from `engine.name` (Godot → `godot-specialist`)
- [ ] It is spawned after the engine audit, with the audit findings in its prompt
- [ ] Output includes an `### Engine Specialist Findings` section
- [ ] No director gate (TD-ARCHITECTURE, LP-FEASIBILITY or any other gate ID) is spawned or mentioned

**Case 5b — no engine configured:** as Case 1, except `engine.name` is unset in `project.yaml` and `technical-preferences.md` is still `[TO BE CONFIGURED]`

**Assertions (5b):**
- [ ] No engine specialist is spawned
- [ ] Output records `Engine validation: NOT ASSESSED — no engine configured` rather than omitting the step
- [ ] The verdict is NOT ASSESSED, not PASS — the engine audit is part of the `full` scope and had no pinned engine to check against, even though every requirement is covered

---

## Protocol Compliance

- [ ] Shows the full traceability matrix before any write approval (the Phase 1a freshness question and Phase 2's ambiguous-requirement questions may come earlier)
- [ ] Every write approval uses `AskUserQuestion` with labelled options, not a plain-text "May I?"
- [ ] Shows the content to be written (report, systems-index rows) before asking to write it
- [ ] Never renumbers or deletes existing `tr-registry.yaml` entries; marking one deprecated is confirmed with the user
- [ ] Verdict is one of exactly: PASS, CONCERNS, NOT ASSESSED, FAIL
- [ ] Ends with a Phase 9 handoff via `AskUserQuestion`; `/gate-check` is not offered while any pre-gate item is ❌

---

## Coverage Notes

- The `coverage`, `consistency`, `engine`, `single-gdd` and `rtm` modes are not
  individually fixture-tested; Cases 1–5 exercise the default `full` mode.
- Phase 5b (GDD revision flags written to `systems-index.md` as `Needs Revision`)
  is not tested; it needs a HIGH RISK engine finding that contradicts a GDD.
- The freshness receipt paths (everything `UNCHANGED`, some `CHANGED`/`NEW`,
  `UNRESOLVED`) are not fixture-tested.
- The `standard` tier's reduced scope (architecture doc + critical ADRs only) is
  not tested.
- The default `minimal` tier (a `project.yaml` with no `modes` block), where the skill's scope table
  says the review does not apply, is not fixture-tested — every case pins
  `modes.workflow: full`. Nor is `workflow_overrides.system_overrides`: this skill
  does not request that key, so a per-system tier has no effect on it.
