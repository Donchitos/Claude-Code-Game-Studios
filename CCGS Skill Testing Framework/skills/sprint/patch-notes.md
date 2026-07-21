# Skill Test Spec: $patch-notes

## Skill Summary

`$patch-notes` is a read-only skill that generates player-facing patch notes
from existing changelog content, stripping internal task IDs and technical
jargon in favor of plain language. It filters entries to only those relevant
to players (visible features and bug fixes; internal refactors are excluded).
No director gates are used. The skill asks "May I write to
`docs/patch-notes-vX.X.md`?" before persisting. Verdict is always COMPLETE.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" language (skill writes patch notes file)
- [ ] Has a next-step handoff (e.g., share with community manager)

---

## Director Gate Checks

None. Patch notes generation is a fast compilation task; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — Changelog filtered to player-facing entries

**Fixture:**
- `docs/CHANGELOG.md` exists with 5 entries:
  - "Add dual-wield melee system" (Features — player-facing)
  - "Fix crash on level transition" (Fixes — player-facing)
  - "Add enemy patrol AI" (Features — player-facing)
  - "Refactor input handler to use event bus" (Fixes — internal only)
  - "Update dependency: Godot 4.6" (internal only)
- Version is `v0.4.0`

**Input:** `$patch-notes v0.4.0`

**Expected behavior:**
1. Skill reads `docs/CHANGELOG.md`
2. Skill filters to 3 player-facing entries; excludes 2 internal entries
3. Skill rewrites entries in plain language (no task IDs, no tech jargon)
4. Skill presents draft to user
5. Skill asks "May I write to `docs/patch-notes-v0.4.0.md`?"
6. User approves; file written; verdict COMPLETE

**Assertions:**
- [ ] Only 3 entries appear in the patch notes (2 internal entries excluded)
- [ ] Entries are written in plain language without internal task IDs
- [ ] File path matches `docs/patch-notes-v0.4.0.md`
- [ ] "May I write" prompt appears before file write
- [ ] Verdict is COMPLETE after write

---

### Case 2: No Changelog Found — Directed to run $changelog first

**Fixture:**
- `docs/CHANGELOG.md` does NOT exist

**Input:** `$patch-notes v0.4.0`

**Expected behavior:**
1. Skill attempts to read `docs/CHANGELOG.md` — not found
2. Skill outputs: "No changelog found — run $changelog first to generate one"
3. No patch notes are generated; no file is written

**Assertions:**
- [ ] Skill does not crash when changelog is absent
- [ ] Output explicitly directs user to run `$changelog`
- [ ] No "May I write" prompt appears (nothing to write)
- [ ] Verdict is BLOCKED (dependency not met)

---

### Case 3: Tone Guidance from Design Folder — Incorporated into output

**Fixture:**
- `docs/CHANGELOG.md` exists with player-facing entries
- `design/community/tone-guide.md` exists with guidance: "upbeat, encouraging tone; avoid passive voice"

**Input:** `$patch-notes v0.4.0`

**Expected behavior:**
1. Skill reads changelog
2. Skill detects tone guide at `design/community/tone-guide.md`
3. Skill applies tone guidance when rewriting entries in plain language
4. Patch notes use upbeat, active-voice phrasing
5. Skill presents draft, asks to write, writes on approval

**Assertions:**
- [ ] Skill checks `design/` for a community or tone guidance file
- [ ] Tone guide content influences phrasing of patch note entries
- [ ] Output reflects active voice and upbeat tone where applicable
- [ ] Skill notes that tone guidance was applied

---

### Case 4: Patch Note Template Exists — Used instead of generated structure

**Fixture:**
- `docs/studio/templates/patch-notes-template.md` exists with a structured header format
- `docs/CHANGELOG.md` exists with player-facing entries

**Input:** `$patch-notes v0.4.0`

**Expected behavior:**
1. Skill reads changelog and detects template exists
2. Skill populates the template with player-facing entries
3. Template header/footer structure is preserved in the output
4. Skill asks "May I write" and writes on approval

**Assertions:**
- [ ] Skill checks for a patch notes template before generating from scratch
- [ ] Template structure is used when found (not overridden by default format)
- [ ] Player-facing entries are inserted into the correct template section
- [ ] Output note confirms template was used

---

### Case 5: Gate Compliance — No gate; community-manager is separate

**Fixture:**
- `docs/CHANGELOG.md` exists with player-facing entries
- `review-mode.txt` contains `full`

**Input:** `$patch-notes v0.4.0`

**Expected behavior:**
1. Skill compiles patch notes in full mode
2. No director gate is invoked (community review is a separate, manual step)
3. Skill produces the requested patch notes without relying on fixed model routing
4. Skill notes in output: "Consider sharing draft with community manager before publishing"
5. Skill asks user for approval and writes on confirmation

**Assertions:**
- [ ] No director gate is invoked regardless of review mode
- [ ] Output suggests (but does not require) community manager review
- [ ] Skill proceeds directly from compilation to "May I write" prompt
- [ ] Verdict is COMPLETE

---

## Protocol Compliance

- [ ] Reads `docs/CHANGELOG.md` before generating patch notes
- [ ] Filters entries to player-facing items only
- [ ] Rewrites entries in plain language without internal IDs
- [ ] Always asks "May I write" before writing patch notes file
- [ ] No director gates are invoked
- [ ] Is documented as read-only and lightweight

---

## Coverage Notes

- The case where all changelog entries are internal (zero player-facing items)
  is not tested; behavior is an empty patch notes draft with a warning.
- Version number parsing from the changelog header is an implementation detail
  not verified here.
- The community manager consultation noted in Case 5 is advisory; a separate
  skill or manual review handles that step.
