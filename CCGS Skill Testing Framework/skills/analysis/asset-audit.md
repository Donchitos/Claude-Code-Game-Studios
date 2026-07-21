# Skill Test Spec: $asset-audit

## Skill Summary

`$asset-audit` audits the `assets/` directory for naming convention compliance,
missing metadata, and format/size issues. It reads asset files against the
conventions and budgets defined in `technical-preferences.md`. No director gates
are invoked. The skill does not write without user approval. Verdicts: COMPLIANT,
WARNINGS, or NON-COMPLIANT.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLIANT, WARNINGS, NON-COMPLIANT
- [ ] Does NOT require "May I write" language (read-only; optional report requires approval)
- [ ] Has a next-step handoff (what to do after audit results)

---

## Director Gate Checks

None. Asset auditing is a read-only analysis skill; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — All assets follow naming conventions

**Fixture:**
- `technical-preferences.md` specifies naming convention: `snake_case`, e.g., `enemy_grunt_idle.png`
- `assets/art/characters/` contains: `enemy_grunt_idle.png`, `enemy_sniper_run.png`
- `assets/audio/sfx/` contains: `sfx_jump_land.ogg`, `sfx_item_pickup.ogg`
- All files are within size budget (textures ≤2MB, audio ≤500KB)

**Input:** `$asset-audit`

**Expected behavior:**
1. Skill reads naming conventions and size budgets from `technical-preferences.md`
2. Skill scans `assets/` recursively
3. All files match `snake_case` convention; all within budget
4. Audit table shows all rows PASS
5. Verdict is COMPLIANT

**Assertions:**
- [ ] Audit covers both art and audio asset directories
- [ ] Each file is checked against naming convention and size budget
- [ ] All rows show PASS when compliant
- [ ] Verdict is COMPLIANT
- [ ] No files are written

---

### Case 2: Non-Compliant — Textures exceed size budget

**Fixture:**
- `assets/art/environment/` contains 5 texture files
- 3 texture files are 4MB each (budget: ≤2MB)
- 2 texture files are within budget

**Input:** `$asset-audit`

**Expected behavior:**
1. Skill reads size budget from `technical-preferences.md` (2MB for textures)
2. Skill scans `assets/art/environment/` — finds 3 oversized textures
3. Audit table lists each oversized file with actual size and budget
4. Verdict is NON-COMPLIANT
5. Skill recommends compression or resolution reduction for flagged files

**Assertions:**
- [ ] All 3 oversized files are listed by name with actual size and budget size
- [ ] Verdict is NON-COMPLIANT when any file exceeds its budget
- [ ] Optimization recommendation is given for oversized files
- [ ] Within-budget files are also listed (showing PASS) for completeness

---

### Case 3: Format Issue — Audio in wrong format

**Fixture:**
- `technical-preferences.md` specifies audio format: OGG
- `assets/audio/music/theme_main.wav` exists (WAV format)
- `assets/audio/sfx/sfx_footstep.ogg` exists (correct OGG format)

**Input:** `$asset-audit`

**Expected behavior:**
1. Skill reads audio format requirement: OGG
2. Skill scans `assets/audio/` — finds `theme_main.wav` in wrong format
3. Audit table flags `theme_main.wav` as FORMAT ISSUE (expected OGG, found WAV)
4. `sfx_footstep.ogg` shows PASS
5. Verdict is WARNINGS (format issues are correctable)

**Assertions:**
- [ ] `theme_main.wav` is flagged as FORMAT ISSUE with expected and actual format noted
- [ ] Verdict is WARNINGS (not NON-COMPLIANT) for format issues, which are correctable
- [ ] Correct-format assets are shown as PASS
- [ ] Skill does not modify or convert any asset files

---

### Case 4: Missing Asset — Asset referenced by GDD but absent from assets/

**Fixture:**
- `design/gdd/enemies.md` references `enemy_boss_idle.png`
- `assets/art/characters/boss/` directory is empty — file does not exist

**Input:** `$asset-audit`

**Expected behavior:**
1. Skill reads GDD references to find expected assets (cross-references with `$content-audit` scope)
2. Skill scans `assets/art/characters/boss/` — file not found
3. Audit table flags `enemy_boss_idle.png` as MISSING ASSET
4. Verdict is NON-COMPLIANT (missing critical art asset)

**Assertions:**
- [ ] Skill checks GDD references to identify expected assets
- [ ] Missing assets are flagged as MISSING ASSET with the GDD reference noted
- [ ] Verdict is NON-COMPLIANT when critical assets are missing
- [ ] Skill does not create or add placeholder assets

---

### Case 5: Gate Compliance — No gate; technical-artist may be consulted separately

**Fixture:**
- 2 files have naming convention violations (CamelCase instead of snake_case)
- `review-mode.txt` contains `full`

**Input:** `$asset-audit`

**Expected behavior:**
1. Skill scans assets and finds 2 naming violations
2. No director gate is invoked regardless of review mode
3. Verdict is WARNINGS
4. Output notes: "Consider having a Technical Artist review naming conventions"
5. Skill presents findings; offers optional audit report write
6. If user opts in: "May I write to `production/qa/asset-audit-[date].md`?"

**Assertions:**
- [ ] No director gate is invoked in any review mode
- [ ] Technical artist consultation is suggested (not mandated)
- [ ] Findings table is presented before any write prompt
- [ ] Optional audit report write asks "May I write" before writing

---

## Protocol Compliance

- [ ] Reads `technical-preferences.md` for naming conventions, formats, and size budgets
- [ ] Scans `assets/` directory recursively
- [ ] Audit table shows file name, check type, expected value, actual value, and result
- [ ] Does not modify any asset files
- [ ] No director gates are invoked
- [ ] Verdict is one of: COMPLIANT, WARNINGS, NON-COMPLIANT

---

## Coverage Notes

- Metadata checks (e.g., missing texture import settings in Godot `.import` files)
  are not explicitly tested here; they follow the same FORMAT ISSUE flagging pattern.
- The interaction between `$asset-audit` and `$content-audit` (both check GDD
  references vs. assets) is intentional overlap; `$asset-audit` focuses on
  compliance while `$content-audit` focuses on completeness.
