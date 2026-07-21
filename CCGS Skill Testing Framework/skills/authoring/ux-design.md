# Skill Test Spec: $ux-design

## Skill Summary

`$ux-design` is a guided, section-by-section UX spec authoring skill. It produces
user flow diagrams (described textually), interaction state definitions, wireframe
descriptions, and accessibility notes for a specified screen or HUD element. The
skill follows the skeleton-first pattern: it creates the file with all section
headers immediately, then fills each section through discussion and writes each
section to disk after user approval.

The skill has no inline director gates — `$ux-review` is the separate review step.
Each section requires a "May I write section [N] to [filepath]?" ask. If a UX spec
already exists for the named screen, the skill offers to retrofit individual sections
rather than replace. Verdict is COMPLETE when all sections are written.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" language per section
- [ ] Has a next-step handoff (e.g., `$ux-review` to validate the completed spec)

---

## Director Gate Checks

None. `$ux-design` has no inline director gates. `$ux-review` is the separate
review skill invoked after this skill completes.

---

## Test Cases

### Case 1: Happy Path — New HUD spec, all sections authored and written

**Fixture:**
- No existing HUD UX spec in `design/ux/`
- Engine and rendering preferences configured

**Input:** `$ux-design hud`

**Expected behavior:**
1. Skill creates a skeleton file `design/ux/hud.md` with all section headers
2. Skill discusses and drafts each section: User Flows, Interaction States
   (normal/hover/focus/disabled), Wireframe Description, Accessibility Notes
3. After each section is drafted and user confirms, skill asks "May I write
   section [N] to `design/ux/hud.md`?"
4. Each section is written in sequence after approval
5. After all sections are written, verdict is COMPLETE
6. Skill suggests running `$ux-review` as the next step

**Assertions:**
- [ ] Skeleton file is created first (with empty section bodies)
- [ ] "May I write section [N]" is asked per section (not once at the end)
- [ ] All required sections are present: User Flows, Interaction States,
     Wireframe Description, Accessibility Notes
- [ ] Handoff to `$ux-review` is at the end
- [ ] Verdict is COMPLETE

---

### Case 2: Existing UX Spec — Retrofit: user picks section to update

**Fixture:**
- `design/ux/hud.md` already exists with all sections populated
- User wants to update only the Accessibility Notes section

**Input:** `$ux-design hud`

**Expected behavior:**
1. Skill reads existing `design/ux/hud.md` and detects all sections are populated
2. Skill reports: "UX spec already exists for HUD — offering to retrofit"
3. Skill lists all sections and asks which to update
4. User selects Accessibility Notes
5. Skill drafts updated accessibility content and asks "May I write section
   Accessibility Notes to `design/ux/hud.md`?"
6. Only that section is updated; other sections are preserved; verdict is COMPLETE

**Assertions:**
- [ ] Existing spec is detected and retrofit is offered
- [ ] User selects which section(s) to update
- [ ] Only the selected section is updated — other sections unchanged
- [ ] "May I write" is asked for the updated section
- [ ] Verdict is COMPLETE

---

### Case 3: Dependency Gap — Spec references a system with no design doc

**Fixture:**
- User is authoring a UX spec for the inventory screen
- `design/gdd/inventory.md` does not exist

**Input:** `$ux-design inventory-screen`

**Expected behavior:**
1. Skill begins authoring the inventory screen UX spec
2. During the User Flows section, skill attempts to reference inventory system rules
3. Skill detects: "No GDD found for inventory system — UX spec has a DEPENDENCY GAP"
4. The dependency gap is flagged in the spec (noted inline: "DEPENDENCY GAP: inventory GDD")
5. Skill continues authoring with placeholder notes for the missing rules
6. Verdict is COMPLETE with advisory note about the dependency gap

**Assertions:**
- [ ] DEPENDENCY GAP label appears in the spec for the missing system doc
- [ ] Skill does NOT block on the missing GDD — it continues with placeholders
- [ ] Dependency gap is also noted in the skill output (not just in the file)
- [ ] Handoff suggests both `$ux-review` and writing the missing GDD

---

### Case 4: No Argument Provided — Usage error

**Fixture:**
- No argument provided with the skill invocation

**Input:** `$ux-design`

**Expected behavior:**
1. Skill detects no screen name or argument provided
2. Skill outputs a usage error: "Screen name required. Usage: `$ux-design [screen-name]`"
3. Skill provides examples: `$ux-design hud`, `$ux-design main-menu`, `$ux-design inventory`
4. No file is created; no "May I write" is asked

**Assertions:**
- [ ] Usage error is clearly stated
- [ ] Example invocations are provided
- [ ] No file is created
- [ ] Skill does not attempt to proceed without an argument

---

### Case 5: Director Gate Check — No gate; ux-review is the separate review skill

**Fixture:**
- New screen spec with argument provided

**Input:** `$ux-design settings-menu`

**Expected behavior:**
1. Skill authors all sections of the settings menu UX spec
2. No director agents are spawned
3. No gate IDs appear in output during authoring

**Assertions:**
- [ ] No director gate is invoked during ux-design
- [ ] No gate skip messages appear
- [ ] Verdict is COMPLETE without any gate check

---

## Protocol Compliance

- [ ] Creates skeleton file with all section headers before discussing content
- [ ] Discusses and drafts one section at a time
- [ ] Asks "May I write section [N]" after each section is approved
- [ ] Detects existing spec and offers retrofit path
- [ ] Ends with handoff to `$ux-review`
- [ ] Verdict is COMPLETE when all sections are written

---

## Coverage Notes

- Interaction state enumeration (normal/hover/focus/disabled/error) is a core
  requirement of each spec; the `$ux-review` skill checks for completeness.
- Wireframe descriptions are text-only (no images); image references may be
  added manually by a designer after the fact.
- Responsive layout concerns (different screen sizes) are noted as optional
  content and not assertion-tested here.
