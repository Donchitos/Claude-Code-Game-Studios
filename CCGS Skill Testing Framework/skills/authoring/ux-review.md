# Skill Test Spec: /ux-review

## Skill Summary

`/ux-review` validates UX documents before they enter the implementation
pipeline. It takes a file path, `hud` (`design/ux/hud.md`), `patterns`
(`design/ux/interaction-patterns.md`), `all` (every file in `design/ux/`, with a
summary table first), or no argument (it asks which spec).

Phase 2 loads cross-reference context: input methods from the `project.yaml`
`platform` block (the authority for input coverage checks), the accessibility
tier committed in `design/accessibility-requirements.md`, the pattern library,
the UI Requirements of GDDs named in the spec header, and the player journey.
It then runs the checklist for the document type — Phase 3A for a UX spec
(15 completeness items plus quality checks), 3B for a HUD design, 3C for the
pattern library — and outputs a structured report. The type comes from the
file's `> **Template**:` header line (which `/ux-design` writes); a file without
one is classified by name (`hud.md` → 3B, `interaction-patterns.md` → 3C, else
3A), and the report says which checklist was assumed.

Verdicts: **APPROVED**, **NOT ASSESSED** (the spec could not be read, or a
dimension had no criterion — e.g., no committed accessibility tier), **NEEDS
REVISION**, **MAJOR REVISION NEEDED**. The skill is read-only
(`allowed-tools: Read, Glob, Grep`, plus the one `resolve_config` call that
resolves `workflow` for the Pattern Library rule), spawns no agents, and its
verdict is advisory. Handoffs: APPROVED → `/team-ui` Phase 2; NEEDS REVISION → fix and
re-run `/ux-review`; MAJOR REVISION NEEDED → back to `/ux-design`.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: `APPROVED`, `NOT ASSESSED`, `NEEDS REVISION`, `MAJOR REVISION NEEDED`
- [ ] Does NOT contain "May I write" language, and `allowed-tools` has no Write or Edit (skill is read-only)
- [ ] Has a verdict-specific next-step handoff (`/team-ui`, the missing input for NOT ASSESSED, re-run `/ux-review`, `/ux-design`)

---

## Director Gate Checks

None. `/ux-review` is itself the review step for UX specs; it has no `Agent`
tool and invokes no director gate.

---

## Test Cases

### Case 1: Happy Path — Complete UX spec, APPROVED

**Fixture:**
- `design/ux/inventory.md` follows `.claude/docs/templates/ux-spec.md`: header with Status, Author, Platform Target (PC, Console), Related GDDs (`design/gdd/inventory.md`), Accessibility Tier and `> **Template**: UX Spec`; every section populated, including States & Variants (loading, empty, populated, error), keyboard and d-pad navigation with focus order, an Input Method Completeness Checklist block for keyboard/mouse and for gamepad with every item ticked, and at least 5 testable acceptance criteria
- `design/accessibility-requirements.md` commits the Standard tier
- `design/ux/interaction-patterns.md` exists, and every interactive component in the spec names a pattern from it
- `project.yaml` `platform` block: `targets: [PC, Console]`, `gamepad_support: Full`
- `design/gdd/inventory.md` UI Requirements are all addressed by the spec

**Input:** `/ux-review design/ux/inventory.md`

**Expected behavior:**
1. Phase 2 derives input methods (keyboard/mouse, gamepad) from the `platform` block, reads the committed tier, the pattern library if present, and the UI Requirements of `design/gdd/inventory.md`
2. Phase 3A runs the completeness items and quality checks
3. The report names Phase 3A as the checklist (from the Template line) and shows "Completeness: [X/Y sections present]", Quality Issues, "GDD Alignment: ALIGNED", "Accessibility: COMPLIANT" against the Standard tier, and "Pattern Library: CONSISTENT"
4. Verdict: APPROVED — "This spec is ready for handoff to `/team-ui` Phase 2 (Visual Design)."
5. Phase 5 suggests running `/team-ui`

**Assertions:**
- [ ] Input method coverage is checked against the `project.yaml` platform block, not only the spec header
- [ ] The UX spec checklist (Phase 3A) is used, including States & Variants, Interaction Map coverage and the Input Method Completeness Checklist item
- [ ] Every review dimension has something to check against — the committed tier, the pattern library, the referenced GDD — so none is NOT ASSESSED
- [ ] Accessibility is checked against the tier committed in `design/accessibility-requirements.md`
- [ ] Verdict is APPROVED with the `/team-ui` handoff
- [ ] No files are written

---

### Case 2: Empty Accessibility Section — NEEDS REVISION

**Fixture:**
- Same as Case 1, but the spec's Accessibility section is empty
- `design/accessibility-requirements.md` commits the Standard tier

**Input:** `/ux-review design/ux/inventory.md`

**Expected behavior:**
1. The Accessibility Requirements completeness item fails, and the Standard-tier text-contrast check cannot be met; the focus-order check still passes, because the spec still defines keyboard and d-pad focus order (Case 1's fixture)
2. Each finding is listed as a numbered quality issue with BLOCKING/ADVISORY, "What's wrong", "Where" and "Fix"
3. Verdict: NEEDS REVISION — "Address the [N] blocking issues above, then re-run `/ux-review`."
4. The skill offers to help draft the missing content but does not edit the file; it waits for the user

**Assertions:**
- [ ] NEEDS REVISION is returned (not APPROVED or MAJOR REVISION NEEDED)
- [ ] Findings name the section and give a specific fix
- [ ] The handoff is to fix the issues and re-run `/ux-review`
- [ ] The skill offers help but does not auto-fix, and no files are written

---

### Case 3: Incomplete States — NEEDS REVISION outranks NOT ASSESSED

**Fixture:**
- `design/ux/settings-menu.md` follows the UX spec template, carries `> **Template**: UX Spec`, and is otherwise complete
- Its States & Variants section documents only the populated state — no loading, empty or error state; the screen fetches its data asynchronously
- `design/ux/interaction-patterns.md` exists and the spec's components name patterns from it
- No `design/accessibility-requirements.md`, so there is no committed tier

**Input:** `/ux-review design/ux/settings-menu.md`

**Expected behavior:**
1. The States & Variants completeness item fails ("at minimum: loading, empty/populated, and error states")
2. The Completeness list marks it, e.g. "States & Variants — MISSING: error state not documented", and names each missing state (loading, empty, error)
3. The report shows "Accessibility: NOT ASSESSED — no committed tier (design/accessibility-requirements.md absent)" and lists it under "Dimensions not assessed"
4. The verdict is NEEDS REVISION: a gap that was found outranks a dimension that could not be checked. It is not NOT ASSESSED, and not MAJOR REVISION NEEDED for this fixable gap
5. The handoff is to fix the gaps and re-run `/ux-review`

**Assertions:**
- [ ] NEEDS REVISION is returned, not NOT ASSESSED — NOT ASSESSED ranks below the revision verdicts
- [ ] The not-assessed Accessibility dimension is still named in the report
- [ ] The missing loading, empty and error states are each named in the output
- [ ] MAJOR REVISION NEEDED is not returned for this fixable gap
- [ ] The handoff is to re-run `/ux-review` after the fix

---

### Case 4: Nothing to Assess Against — NOT ASSESSED

**Fixture:**
- Scenario (a): `design/ux/inventory-screen.md` does not exist
- Scenario (b): `design/ux/inventory.md` is complete (as in Case 1), but `design/accessibility-requirements.md` does not exist; the spec header states "Accessibility Tier: Standard"

**Input:** (a) `/ux-review design/ux/inventory-screen.md` (b) `/ux-review design/ux/inventory.md`

**Expected behavior:**
1. (a) The spec cannot be read: the verdict is NOT ASSESSED, the missing path is named, and no checklist is produced
2. (b) The report shows "Accessibility: NOT ASSESSED — no committed tier (design/accessibility-requirements.md absent)" — never COMPLIANT
3. (b) The header's Standard tier is carried forward and stated as an assumption, not a commitment
4. (b) `/ux-design accessibility` is recommended to establish the tier
5. The verdict is NOT ASSESSED, the dimensions not assessed are named with what would make them checkable, and handoff to `/team-ui` is not recommended

**Assertions:**
- [ ] (a) A missing spec yields NOT ASSESSED naming the path, with no checklist output
- [ ] (b) Accessibility is reported NOT ASSESSED, not COMPLIANT, when no tier is committed
- [ ] (b) `/ux-design accessibility` is recommended
- [ ] The report does not recommend handing off to `/team-ui` on a NOT ASSESSED result
- [ ] No files are written

---

### Case 5: `all` Argument and No Director Gate

**Fixture:**
- `design/ux/` contains `hud.md` (written by `/ux-design hud`, header line `> **Template**: HUD Design`), `inventory.md` (written by `/ux-design inventory`, `> **Template**: UX Spec`) and `pause-menu.md` (hand-written from `.claude/docs/templates/ux-spec.md`, with no Template line)
- `project.yaml` has `modes.review_mode: full`

**Input:** `/ux-review all`

**Expected behavior:**
1. The skill finds every file in `design/ux/` and outputs a summary table first (file | verdict | primary issue), then the full report for each
2. `hud.md` is checked with the HUD checklist (Phase 3B) and `inventory.md` with the UX spec checklist (Phase 3A), each from its Template line
3. `pause-menu.md` has no Template line and is not `hud.md` or `interaction-patterns.md`, so it gets Phase 3A, and its report says the checklist was assumed from the file name
4. No agent is spawned and no gate ID or gate skip message appears; the review mode has no effect
5. Each verdict is one of APPROVED / NOT ASSESSED / NEEDS REVISION / MAJOR REVISION NEEDED

**Assertions:**
- [ ] A summary table (file | verdict | primary issue) comes before the per-file detail
- [ ] Each document's checklist comes from its Template line (HUD vs UX spec)
- [ ] A file without a Template line is classified by name, and the report says which checklist was assumed
- [ ] No director gate is invoked and no gate skip messages appear
- [ ] Every verdict comes from the skill's four-verdict set

---

## Protocol Compliance

- [ ] Loads cross-reference context (platform config, accessibility tier, pattern library, referenced GDDs, player journey) before validating
- [ ] Uses the checklist that matches the document type (UX spec, HUD, pattern library) — from the Template line, or by file name with the assumption stated
- [ ] Checks accessibility against the committed tier, and reports NOT ASSESSED — never COMPLIANT — when no tier is committed
- [ ] Ranks NOT ASSESSED above APPROVED and below NEEDS REVISION and MAJOR REVISION NEEDED
- [ ] Does not write or edit any files
- [ ] Gives specific findings (What's wrong / Where / Fix, BLOCKING or ADVISORY) for NEEDS REVISION and MAJOR REVISION NEEDED; for NOT ASSESSED, names each dimension not assessed and the input that would make it checkable
- [ ] Ends with the verdict-specific handoff: `/team-ui` (APPROVED), the missing input per dimension and no `/team-ui` handoff (NOT ASSESSED), re-run `/ux-review` (NEEDS REVISION), `/ux-design` (MAJOR REVISION NEEDED)

---

## Coverage Notes

- MAJOR REVISION NEEDED (fundamental issues with scope, player need or
  completeness) is not tested with a dedicated fixture.
- The pattern library checklist (Phase 3C, `patterns` argument) is not
  fixture-tested.
- The no-argument prompt ("which spec to validate") is not tested.
- The fallback to `.claude/docs/technical-preferences.md`, and then to the spec
  header, when `project.yaml` has no `platform` block is not tested.
