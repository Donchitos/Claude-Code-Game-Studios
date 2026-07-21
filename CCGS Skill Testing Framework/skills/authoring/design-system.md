# Skill Test Spec: $design-system

## Skill Summary

`$design-system` guides the user through section-by-section authoring of a Game
Design Document (GDD) for a single game system. All 8 required sections must be
authored: Overview, Player Fantasy, Detailed Rules, Formulas, Edge Cases,
Dependencies, Tuning Knobs, and Acceptance Criteria. The skill uses a
skeleton-first approach — it creates the GDD file with all 8 section headers
before filling any content — and writes each section individually after approval.

The CD-GDD-ALIGN gate (creative-director) runs in both `full` AND `lean` modes.
It is only skipped in `solo` mode. If an existing GDD file is found, the skill
offers a retrofit mode to update specific sections rather than rewriting the whole
document.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: APPROVED, NEEDS REVISION, MAJOR REVISION
- [ ] Contains "May I write" collaborative protocol language (per-section approval)
- [ ] Has a next-step handoff at the end
- [ ] Documents skeleton-first approach (file created with headers before content)
- [ ] Documents CD-GDD-ALIGN gate: active in full AND lean mode; skipped in solo only
- [ ] Documents retrofit mode for existing GDD files

---

## Director Gate Checks

In `full` mode: CD-GDD-ALIGN (creative-director) gate runs after each section is
drafted, before writing. If MAJOR REVISION is returned, the section must be
rewritten before proceeding.

In `lean` mode: CD-GDD-ALIGN still runs (this gate is NOT skipped in lean mode —
it runs in both full and lean). Only solo mode skips it.

In `solo` mode: CD-GDD-ALIGN is skipped. Output notes:
"CD-GDD-ALIGN skipped — solo mode". Sections are written with only user approval.

---

## Test Cases

### Case 1: Happy Path — New GDD, skeleton-first, CD-GDD-ALIGN in lean mode

**Fixture:**
- No existing GDD for the target system in `design/gdd/`
- `production/session-state/review-mode.txt` contains `lean`

**Input:** `$design-system [system-name]`

**Expected behavior:**
1. Skill creates skeleton file `design/gdd/[system-name].md` with all 8 section headers (empty bodies)
2. For each section: discusses with user, drafts content, shows draft
3. CD-GDD-ALIGN gate runs on each section draft (lean mode — gate is active)
4. Gate returns APPROVED for each section
5. "May I write [section]?" asked after gate approval
6. Section written to file after user approval
7. Process repeats for all 8 sections

**Assertions:**
- [ ] Skeleton file is created with all 8 section headers before any content is written
- [ ] CD-GDD-ALIGN runs on each section in lean mode (not skipped)
- [ ] "May I write" is asked per section (not once for all sections)
- [ ] Each section is written individually after gate + user approval
- [ ] All 8 sections are present in the final GDD file

---

### Case 2: Retrofit Mode — Existing GDD, update specific section

**Fixture:**
- `design/gdd/[system-name].md` already exists with all 8 sections populated

**Input:** `$design-system [system-name]`

**Expected behavior:**
1. Skill detects existing GDD file and reads its current content
2. Skill offers retrofit mode: "GDD already exists. Which section would you like to update?"
3. User selects a specific section (e.g., Formulas)
4. Skill authors only that section, runs CD-GDD-ALIGN, asks "May I write?"
5. Only the selected section is updated — other sections are not modified

**Assertions:**
- [ ] Skill detects and reads existing GDD before offering retrofit mode
- [ ] User is asked which section to update — not asked to rewrite the whole document
- [ ] Only the selected section is rewritten — others remain unchanged
- [ ] CD-GDD-ALIGN still runs on the updated section
- [ ] "May I write" is asked before updating the section

---

### Case 3: Director Gate — CD-GDD-ALIGN returns MAJOR REVISION

**Fixture:**
- New GDD being authored
- `production/session-state/review-mode.txt` contains `lean`
- CD-GDD-ALIGN gate returns MAJOR REVISION on the Player Fantasy section

**Input:** `$design-system [system-name]`

**Expected behavior:**
1. Player Fantasy section is drafted
2. CD-GDD-ALIGN gate runs and returns MAJOR REVISION with specific feedback
3. Skill surfaces the feedback to the user
4. Section is NOT written to file while MAJOR REVISION is unresolved
5. User rewrites the section in collaboration with the skill
6. CD-GDD-ALIGN runs again on the revised section
7. If revised section passes, "May I write?" is asked and section is written

**Assertions:**
- [ ] Section is NOT written when CD-GDD-ALIGN returns MAJOR REVISION
- [ ] Gate feedback is shown to the user before requesting revision
- [ ] CD-GDD-ALIGN runs again after the section is revised
- [ ] Skill does NOT auto-proceed to the next section while MAJOR REVISION is unresolved

---

### Case 4: Solo Mode — CD-GDD-ALIGN skipped; sections written with user approval only

**Fixture:**
- New GDD being authored
- `production/session-state/review-mode.txt` contains `solo`

**Input:** `$design-system [system-name]`

**Expected behavior:**
1. Skeleton file is created with 8 section headers
2. For each section: drafted, shown to user
3. CD-GDD-ALIGN is skipped — noted per section: "CD-GDD-ALIGN skipped — solo mode"
4. "May I write [section]?" asked after user reviews draft
5. Section written after user approval
6. No gate review at any stage

**Assertions:**
- [ ] "CD-GDD-ALIGN skipped — solo mode" noted for each section
- [ ] Sections are written after user approval alone (no gate required)
- [ ] Skill does NOT spawn any CD-GDD-ALIGN gate in solo mode
- [ ] Full GDD is written with only user approval in solo mode

---

### Case 5: Director Gate — Empty sections not written to file

**Fixture:**
- GDD authoring in progress
- User and skill discuss one section but do not produce any approved content
  (e.g., discussion ends without a decision, or user says "skip for now")

**Input:** `$design-system [system-name]`

**Expected behavior:**
1. Section discussion produces no approved content
2. Skill does NOT write an empty or placeholder body to the section
3. The section header remains in the skeleton file but the body stays empty
4. Skill moves to the next section without writing the empty one
5. At the end, incomplete sections are listed and user is reminded to return to them

**Assertions:**
- [ ] Empty or unapproved sections are NOT written to the file
- [ ] Skeleton section header remains (preserves structure)
- [ ] Skill tracks and lists incomplete sections at the end of the session
- [ ] Skill does NOT write "TBD" or placeholder content without user approval

---

## Protocol Compliance

- [ ] Skeleton file created with all 8 headers before any content is written
- [ ] CD-GDD-ALIGN runs in both full AND lean mode (not just full)
- [ ] CD-GDD-ALIGN skipped only in solo mode — noted per section
- [ ] "May I write [section]?" asked per section (not once for the whole document)
- [ ] MAJOR REVISION from CD-GDD-ALIGN blocks section write until resolved
- [ ] Only approved, non-empty sections are written to the file
- [ ] Ends with next-step handoff: `$review-all-gdds` or `$map-systems next`

---

## Coverage Notes

- The 8 required sections are validated against the project's design document
  standards defined in `AGENTS.md` — not re-enumerated here.
- The skill's internal section-ordering logic (which section to author first) is
  not independently tested — the order follows the standard GDD template.
- Pillar alignment checking within CD-GDD-ALIGN is evaluated holistically by
  the gate agent — specific pillar checks are not fixture-tested here.
