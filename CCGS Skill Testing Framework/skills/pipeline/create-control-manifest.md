# Skill Test Spec: /create-control-manifest

## Skill Summary

`/create-control-manifest` reads the Accepted ADRs in `docs/architecture/` and
generates a control manifest — a flat, actionable rules sheet that captures the
required patterns, forbidden approaches, performance guardrails and engine API
constraints for each architectural layer (Foundation, Core, Feature,
Presentation), plus global rules from project config and engine reference docs.
Story authors use it so stories inherit the correct architectural rules without
reading every ADR.

The skill counts ADRs first, resolves each ADR's `## Status` with a Grep before
reading any ADR body, and builds the manifest from the Accepted set only. It
previews rule counts per layer, runs the **TD-MANIFEST** director gate when the
review mode is `full` (skipped with a note in `solo` and `lean`), then asks
"May I write the Control Manifest?" before writing
`docs/architecture/control-manifest.md`. Verdicts: COMPLETE on write, BLOCKED
when the user declines the write.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I write" collaborative protocol language (for the control manifest)
- [ ] Has a next-step handoff at the end (`/create-epics` then `/create-stories`)
- [ ] Documents that only Accepted ADRs are included (not Proposed)
- [ ] Names gate TD-MANIFEST and its solo/lean skip notes

---

## Director Gate Checks

One gate: **TD-MANIFEST** (`technical-director`,
`.claude/docs/director-gates/td-manifest.md`), spawned after the user accepts the
Phase 4 rule summary and before the Phase 5 write ask.

- `full` → spawned; receives the Control Manifest Preview, the ADRs covered, the
  engine version and any rules sourced from preferences or engine reference docs
- `lean` → skipped; output notes "TD-MANIFEST skipped — Lean mode."
- `solo` → skipped; output notes "TD-MANIFEST skipped — Solo mode."

Verdict handling: APPROVE → proceed to the write ask; CONCERNS → `AskUserQuestion`
with `Revise flagged rules` / `Accept and proceed` / `Discuss further`; REJECT →
the manifest is not written, flagged rules are fixed and the summary re-presented;
NOT ASSESSED [missing input] → never read as APPROVE: the missing input is named,
then supplied and the gate re-run, or the run goes on with
`TD-MANIFEST: NOT ASSESSED — [input]` stated in the output and the Verdict line.

---

## Test Cases

### Case 1: Happy Path — 4 Accepted ADRs create a correct manifest

**Fixture:**
- `docs/architecture/` contains `adr-0001-*.md` … `adr-0004-*.md`, each with a
  `## Status` section reading `Accepted`
- Each ADR has `## Decision` (with "must"/"always" statements) and
  `## Alternatives Considered` (with rejected alternatives)
- No existing `docs/architecture/control-manifest.md`
- Review mode resolves to `solo`

**Input:** `/create-control-manifest`

**Expected behavior:**
1. Globs `docs/architecture/adr-*.md` (N = 4), then Greps `^## Status` to resolve
   the Accepted set before reading any ADR body
2. Greps only the Decision / Alternatives Considered / Performance Implications /
   Engine Compatibility sections of the Accepted ADRs
3. Reports "Loaded 4 Accepted ADRs, engine: [name + version]."
4. Shows the Control Manifest Preview (rule counts per layer, ADRs covered) and
   asks "Does this rule summary look complete?"
5. Notes "TD-MANIFEST skipped — Solo mode."
6. Asks "May I write the Control Manifest?" with option
   `[A] Yes — write to docs/architecture/control-manifest.md`
7. Writes the manifest after approval; Verdict: COMPLETE

**Assertions:**
- [ ] All 4 Accepted ADRs are listed under `ADRs Covered` in the manifest header
- [ ] Each layer section has `### Required Patterns` and `### Forbidden Approaches`
- [ ] Every rule carries its source — `— source: [ADR-NNNN]` for a layer rule; a global rule names its `project.yaml` / `technical-preferences.md` key or engine-reference file (e.g. `deprecated-apis.md`)
- [ ] Preview is shown and "Does this rule summary look complete?" is asked before any write ask
- [ ] "TD-MANIFEST skipped — Solo mode." appears; no technical-director is spawned
- [ ] Skill does NOT write before the "May I write the Control Manifest?" approval
- [ ] Verdict is COMPLETE after writing

---

### Case 2: Failure Path — No ADRs found

**Fixture:**
- `docs/architecture/` directory exists but contains no `adr-*.md` files

**Input:** `/create-control-manifest`

**Expected behavior:**
1. Glob returns N = 0
2. Skill outputs: "No ADRs found — run `/architecture-decision` before building a
   control manifest."
3. Skill stops — no Status Grep, no preview, no write ask, no file written

**Assertions:**
- [ ] The "No ADRs found" message is printed
- [ ] Skill recommends `/architecture-decision` as the next action
- [ ] No control manifest file is written and no "May I write" ask is shown
- [ ] Verdict COMPLETE is NOT emitted (the skill stops at Phase 1)

---

### Case 3: Mixed ADR Statuses — Only Accepted ADRs included

**Fixture:**
- `docs/architecture/` contains 5 ADRs: 3 with `## Status` Accepted, 2 with
  `## Status` Proposed (ADR-0004, ADR-0005)

**Input:** `/create-control-manifest`

**Expected behavior:**
1. N = 5; the `^## Status` Grep returns 5 matches, 3 reading Accepted — the
   "some Accepted" row applies and the Accepted set A = the 3 ADRs
2. Section extraction is filtered to set A
3. Preview reports "Loaded 3 Accepted ADRs", `ADRs covered` lists only the 3, and
   `ADRs excluded` names ADR-0004 (Proposed) and ADR-0005 (Proposed)
4. Proceeds without asking about Proposed ADRs (that ask is reserved for the
   none-Accepted case)

**Assertions:**
- [ ] Status is resolved with the `^## Status` Grep before any ADR section is read
- [ ] The preview's `ADRs covered` and the manifest's `ADRs Covered` list exactly the 3 Accepted ADRs
- [ ] Both excluded ADRs are named, with their status, in the preview the user sees before approving — the skill does not silently omit them
- [ ] No rule in the manifest is sourced from either Proposed ADR
- [ ] The "none Accepted — proceed with Proposed or stop?" ask is NOT shown for this fixture

---

### Case 4: Edge Case — Regenerating an existing manifest

**Fixture:**
- `docs/architecture/control-manifest.md` already exists with
  `Manifest Version` and `Last Updated` both dated last week
- `docs/architecture/` contains Accepted ADRs, one of them accepted since then
- `production/epics/` already holds epics with stories, so the first-run
  `/create-epics` next step does not apply

**Input:** `/create-control-manifest update`

**Expected behavior:**
1. Skill rebuilds the manifest from the current Accepted ADRs (same Phases 1–4)
2. Asks "May I write the Control Manifest?" before overwriting
3. The new manifest's `Manifest Version` and `Last Updated` are both today's date
4. After writing, prints "Updated. Recommend notifying the team of changed rules —
   especially any new Forbidden entries."

**Assertions:**
- [ ] The existing file is not overwritten before "May I write the Control Manifest?" is approved
- [ ] The newly accepted ADR appears in `ADRs Covered`
- [ ] `Manifest Version` equals `Last Updated` and is the generation date (not a v1→v2 counter)
- [ ] The regeneration next-step ("Updated. Recommend notifying the team…") is shown instead of the first-run `/create-epics` handoff

---

### Case 5: Director Gate — TD-MANIFEST in full review mode returns REJECT

**Fixture:**
- 4 Accepted ADRs exist
- Review mode resolves to `full`
- TD-MANIFEST returns REJECT, naming one rule that has no source ADR

**Input:** `/create-control-manifest`

**Expected behavior:**
1. Skill shows the Phase 4 preview; user picks
   `[A] Yes — looks good, run the director review and write the manifest`
2. Spawns `technical-director` via `Agent` with gate TD-MANIFEST, passing the
   preview (full rule list), ADRs covered and engine version
3. On REJECT: does not write the manifest; fixes the flagged rule and re-presents
   the summary
4. "May I write the Control Manifest?" is not asked while the REJECT stands

**Assertions:**
- [ ] TD-MANIFEST is spawned only after the Phase 4 summary is accepted
- [ ] The gate receives the rule list, ADRs covered and engine version
- [ ] On REJECT no manifest file is written
- [ ] The flagged rule is revised and the summary re-presented before any write ask
- [ ] No "TD-MANIFEST skipped" note appears in `full` mode

---

### Case 6: Edge Case — No Accepted ADR, and ADRs with no `## Status`

**Fixture (none Accepted):**
- `docs/architecture/` contains 3 ADRs, each with `## Status` Proposed

**Fixture (malformed):**
- `docs/architecture/` contains 3 ADRs, none with a `## Status` section

**Input (both fixtures):** `/create-control-manifest`

**Expected behavior (none Accepted):**
1. N = 3; the `^## Status` Grep matches 3, none reading Accepted
2. Reports "3 ADRs found, none Accepted. A manifest built from Proposed ADRs would
   encode decisions that may still change." and asks whether to proceed with the
   Proposed ADRs or stop

**Expected behavior (malformed):**
1. N = 3; the `^## Status` Grep matches nothing
2. Reports "3 ADRs found, none has a `## Status` section — acceptance cannot be
   determined. Run `/architecture-decision retrofit [file]` on each." and stops

**Assertions:**
- [ ] None Accepted: the ask is shown and no empty manifest is written
- [ ] Malformed: the run stops — the ADRs are not treated as Accepted and no manifest is written
- [ ] Malformed: the retrofit command reads `/architecture-decision retrofit [file]` — the form that skill parses
- [ ] In neither fixture is a rule summary previewed or a "May I write" ask shown before the user proceeds

---

## Protocol Compliance

- [ ] Counts ADRs and resolves `## Status` before reading ADR sections
- [ ] Only Accepted ADRs included, and every excluded ADR is named with its status in the preview; the none-Accepted and no-`## Status` cases stop or ask instead of emitting an empty manifest
- [ ] Rule summary shown to user before the gate and before "May I write"
- [ ] "May I write the Control Manifest?" asked before writing `docs/architecture/control-manifest.md`
- [ ] TD-MANIFEST runs in `full`, is skipped with a named note in `lean`/`solo`
- [ ] Ends with next-step handoff: `/create-epics layer: foundation` then `/create-stories [epic-slug]`

---

## Coverage Notes

- The exact section structure of the generated manifest (constraint tables, pattern
  lists) is defined by the skill body and not re-enumerated in test assertions.
- What happens after the user proceeds with Proposed ADRs (Case 6) is not
  fixture-tested.
- TD-MANIFEST APPROVE, CONCERNS and NOT ASSESSED paths, and the `lean` skip note,
  are not separately fixture-tested.
- Relevance filtering of `deprecated-apis.md` entries (2D vs 3D scoping) is not
  covered.
