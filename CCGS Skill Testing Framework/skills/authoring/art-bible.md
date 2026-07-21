# Skill Test Spec: $art-bible

## Skill Summary

`$art-bible` is a guided, section-by-section art bible authoring skill. It
produces a comprehensive visual direction document covering: Visual Style overview,
Color Palette, Typography, Character Design Rules, Environment Style, and UI
Visual Language. The skill follows the skeleton-first pattern: creates the file
with all section headers immediately, then fills each section through discussion
and writes each to disk after user approval.

In `full` review mode, the AD-ART-BIBLE director gate (art director) runs after
the draft is complete and before any section is written. In `lean` and `solo`
modes, AD-ART-BIBLE is skipped and only user approval is required. The verdict
is COMPLETE when all sections are written.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" language per section
- [ ] Documents the AD-ART-BIBLE director gate and its mode behavior
- [ ] Has a next-step handoff (e.g., `$asset-spec` or `$design-system`)

---

## Director Gate Checks

| Gate ID      | Trigger condition              | Mode guard            |
|--------------|--------------------------------|-----------------------|
| AD-ART-BIBLE | After draft is complete        | full only (not lean/solo) |

---

## Test Cases

### Case 1: Happy Path — Full mode, art bible drafted, AD-ART-BIBLE approves

**Fixture:**
- No existing `design/art-bible.md`
- `production/session-state/review-mode.txt` contains `full`
- `design/gdd/game-concept.md` exists with visual tone described

**Input:** `$art-bible`

**Expected behavior:**
1. Skill creates skeleton `design/art-bible.md` with all section headers
2. Skill discusses and drafts each section with user collaboration
3. After all sections are drafted, AD-ART-BIBLE gate is invoked (art director review)
4. AD-ART-BIBLE returns APPROVED
5. Skill asks "May I write section [N] to `design/art-bible.md`?" per section
6. All sections written after approval; verdict is COMPLETE

**Assertions:**
- [ ] Skeleton file is created first (before any section content is written)
- [ ] AD-ART-BIBLE gate is invoked in full mode after draft is complete
- [ ] Gate approval precedes the "May I write" section asks
- [ ] All sections are present in the final file
- [ ] Verdict is COMPLETE

---

### Case 2: AD-ART-BIBLE Returns CONCERNS — Section revised before writing

**Fixture:**
- Art bible draft complete
- `production/session-state/review-mode.txt` contains `full`
- AD-ART-BIBLE gate returns CONCERNS: "Color palette clashes with the dark
  atmospheric tone described in the game concept"

**Input:** `$art-bible`

**Expected behavior:**
1. AD-ART-BIBLE gate returns CONCERNS with specific feedback about palette
2. Skill surfaces feedback to user: "Art director has concerns about the color palette"
3. Skill returns to the Color Palette section for revision
4. User and skill revise the palette to align with game concept tone
5. AD-ART-BIBLE is not re-invoked (user decides to proceed after revision)
6. Revised section is written after "May I write" approval; verdict is COMPLETE

**Assertions:**
- [ ] CONCERNS are shown to user before any section is written
- [ ] Skill returns to the affected section for revision (not all sections)
- [ ] Revised content (not original) is written to file
- [ ] Verdict is COMPLETE after revision and approval

---

### Case 3: Lean Mode — AD-ART-BIBLE Skipped, Written With User Approval Only

**Fixture:**
- No existing art bible
- `production/session-state/review-mode.txt` contains `lean`

**Input:** `$art-bible`

**Expected behavior:**
1. Skill reads review mode — determines `lean`
2. Skill drafts all sections with user collaboration
3. AD-ART-BIBLE gate is skipped: output notes "[AD-ART-BIBLE] skipped — lean mode"
4. Skill asks user for direct approval of each section
5. Sections are written after user confirmation; verdict is COMPLETE

**Assertions:**
- [ ] AD-ART-BIBLE gate is NOT invoked in lean mode
- [ ] Skip is explicitly noted: "[AD-ART-BIBLE] skipped — lean mode"
- [ ] User approval is still required per section (gate skip ≠ approval skip)
- [ ] Verdict is COMPLETE

---

### Case 4: Existing Art Bible — Retrofit Mode

**Fixture:**
- `design/art-bible.md` already exists with all sections populated
- User wants to update the Character Design Rules section

**Input:** `$art-bible`

**Expected behavior:**
1. Skill reads existing art bible and detects all sections populated
2. Skill offers retrofit: "Art bible exists — which section would you like to update?"
3. User selects Character Design Rules
4. Skill drafts updated content; in full mode, AD-ART-BIBLE is invoked for the
   revised section before writing
5. Skill asks "May I write Character Design Rules to `design/art-bible.md`?"
6. Only that section is updated; other sections preserved; verdict is COMPLETE

**Assertions:**
- [ ] Existing art bible is detected and retrofit is offered
- [ ] Only the selected section is updated
- [ ] In full mode: AD-ART-BIBLE gate runs even for single-section retrofit
- [ ] Other sections are preserved
- [ ] Verdict is COMPLETE

---

### Case 5: Solo Mode — AD-ART-BIBLE Skipped, Noted in Output

**Fixture:**
- No existing art bible
- `production/session-state/review-mode.txt` contains `solo`

**Input:** `$art-bible`

**Expected behavior:**
1. Skill reads review mode — determines `solo`
2. Art bible is drafted and written with only user approval
3. AD-ART-BIBLE gate is skipped: output notes "[AD-ART-BIBLE] skipped — solo mode"
4. No director agents are spawned
5. Verdict is COMPLETE

**Assertions:**
- [ ] AD-ART-BIBLE gate is NOT invoked in solo mode
- [ ] Skip is explicitly noted with "solo mode" label
- [ ] No director agents of any kind are spawned
- [ ] Verdict is COMPLETE

---

## Protocol Compliance

- [ ] Creates skeleton file immediately with all section headers
- [ ] Discusses and drafts one section at a time
- [ ] AD-ART-BIBLE gate runs in full mode after all sections are drafted
- [ ] AD-ART-BIBLE is skipped in lean and solo modes — noted by name
- [ ] Asks "May I write section [N]" per section
- [ ] Verdict is COMPLETE when all sections are written

---

## Coverage Notes

- The case where AD-ART-BIBLE returns REJECT (not just CONCERNS) is not
  separately tested; the skill would block writing and ask the user how to
  proceed (revise or override).
- The Typography section is listed as a required art bible section but its
  specific content requirements are not assertion-tested here.
- The art bible feeds into `$asset-spec` — this relationship is noted in the
  handoff but not tested as part of this skill's spec.
