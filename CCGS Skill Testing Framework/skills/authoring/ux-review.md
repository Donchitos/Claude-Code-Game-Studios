# Skill Test Spec: $ux-review

## Skill Summary

`$ux-review` validates an existing UX spec or HUD design document against
accessibility and interaction standards. It checks for required sections
(User Flows, Interaction States, Wireframe Description, Accessibility Notes),
completeness of interaction state definitions (hover, focus, disabled, error),
accessibility compliance (keyboard navigation, color contrast notes, screen
reader considerations), and consistency with the art bible or design system
if those documents exist.

The skill is read-only — it produces no file writes. Verdicts: APPROVED
(all checks pass), NEEDS REVISION (fixable issues found), or MAJOR REVISION
NEEDED (structural or accessibility failures). No director gates apply —
`$ux-review` IS the review gate for UX specs.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: APPROVED, NEEDS REVISION, MAJOR REVISION NEEDED
- [ ] Does NOT contain "May I write" language (skill is read-only)
- [ ] Has a next-step handoff (e.g., back to `$ux-design` for revision, or proceed to implementation)

---

## Director Gate Checks

None. `$ux-review` is itself the review gate for UX specs. No additional director
gates are invoked within this skill.

---

## Test Cases

### Case 1: Happy Path — Complete UX spec with all required sections, APPROVED

**Fixture:**
- `design/ux/hud.md` exists with all required sections populated:
  - User Flows: complete player flow diagrams
  - Interaction States: normal, hover, focus, disabled, error all defined
  - Wireframe Description: layout described
  - Accessibility Notes: keyboard nav, contrast ratios, screen reader notes

**Input:** `$ux-review hud`

**Expected behavior:**
1. Skill reads `design/ux/hud.md`
2. Skill checks all 4 required sections — all present and non-empty
3. Skill checks interaction states — all 5 states defined
4. Skill checks accessibility notes — keyboard, contrast, and screen reader covered
5. Skill outputs: checklist of all passed checks
6. Verdict is APPROVED

**Assertions:**
- [ ] All 4 required sections are checked
- [ ] All 5 interaction states are verified present
- [ ] Verdict is APPROVED
- [ ] No files are written

---

### Case 2: Missing Accessibility Section — NEEDS REVISION

**Fixture:**
- `design/ux/hud.md` exists but the Accessibility Notes section is empty
- All other sections are fully populated

**Input:** `$ux-review hud`

**Expected behavior:**
1. Skill reads the file and checks all sections
2. Accessibility Notes section is empty — check fails
3. Skill outputs: "NEEDS REVISION — Accessibility Notes section is empty"
4. Skill lists specific items to add: keyboard navigation, color contrast ratios,
   screen reader labels
5. Verdict is NEEDS REVISION
6. Handoff suggests returning to `$ux-design hud` to fill in the section

**Assertions:**
- [ ] NEEDS REVISION verdict is returned (not APPROVED or MAJOR REVISION NEEDED)
- [ ] Specific missing content items are listed
- [ ] Handoff points back to `$ux-design hud` for revision
- [ ] No files are written

---

### Case 3: Interaction States Incomplete — NEEDS REVISION

**Fixture:**
- `design/ux/settings-menu.md` exists
- Interaction States section only defines: normal and hover
- Missing: focus, disabled, error states

**Input:** `$ux-review settings-menu`

**Expected behavior:**
1. Skill reads the file and checks interaction states
2. Only 2 of 5 required states are defined
3. Skill reports: "NEEDS REVISION — Interaction states incomplete: missing focus, disabled, error"
4. Verdict is NEEDS REVISION with specific missing states named

**Assertions:**
- [ ] NEEDS REVISION verdict returned
- [ ] All 3 missing states are named explicitly in the output
- [ ] Skill does not return MAJOR REVISION NEEDED for a fixable gap
- [ ] Handoff suggests returning to `$ux-design settings-menu`

---

### Case 4: File Not Found — Error with remediation

**Fixture:**
- `design/ux/inventory-screen.md` does not exist

**Input:** `$ux-review inventory-screen`

**Expected behavior:**
1. Skill attempts to read `design/ux/inventory-screen.md` — file not found
2. Skill outputs: "UX spec not found: design/ux/inventory-screen.md"
3. Skill suggests running `$ux-design inventory-screen` to create the spec first
4. No review is performed; no verdict is issued

**Assertions:**
- [ ] Error message names the missing file with full path
- [ ] `$ux-design inventory-screen` is suggested as the remediation
- [ ] No review checklist is produced
- [ ] No verdict is issued (error state, not APPROVED/NEEDS REVISION)

---

### Case 5: Director Gate Check — No gate; ux-review is itself the review

**Fixture:**
- Valid UX spec file

**Input:** `$ux-review hud`

**Expected behavior:**
1. Skill performs the review and issues a verdict
2. No additional director agents are spawned
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Verdict is APPROVED, NEEDS REVISION, or MAJOR REVISION NEEDED — no gate verdict

---

## Protocol Compliance

- [ ] Checks all 4 required sections (User Flows, Interaction States, Wireframe,
     Accessibility Notes)
- [ ] Checks all 5 interaction states (normal, hover, focus, disabled, error)
- [ ] Checks accessibility coverage (keyboard nav, contrast, screen reader)
- [ ] Does not write any files
- [ ] Issues specific, actionable feedback when verdict is not APPROVED
- [ ] Ends with next-step handoff to `$ux-design` for revision or implementation

---

## Coverage Notes

- MAJOR REVISION NEEDED is triggered when structural sections are entirely
  absent (not just empty) or when fundamental interaction flows are missing
  entirely; not tested with a separate fixture here.
- Art bible / design system consistency check (color palette alignment) is
  mentioned as a capability but not separately fixture-tested.
- The case where an existing spec was written for a now-renamed screen is
  not tested; the skill would review the file by path regardless of the name.
