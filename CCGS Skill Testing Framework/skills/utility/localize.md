# Skill Test Spec: $localize

## Skill Summary

`$localize` manages the full localization pipeline: it extracts all player-facing
strings from source files, manages translation files in `assets/localization/`,
and validates completeness across all locale files. For new languages, it creates
a locale file skeleton with all current strings as keys and empty values. For
existing locale files, it produces a diff showing additions, removals, and
changed keys.

Translation files are written to `assets/localization/[locale-code].csv` (or
engine-appropriate format) after a "May I write" ask. No director gates apply.
Verdicts: LOCALIZATION COMPLETE (all locales are complete) or GAPS FOUND (at
least one locale is missing string keys).

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: LOCALIZATION COMPLETE, GAPS FOUND
- [ ] Contains "May I write" collaborative protocol language before writing locale files
- [ ] Has a next-step handoff (e.g., send locale skeletons to translators)

---

## Director Gate Checks

None. `$localize` is a pipeline utility. No director gates apply. Localization
lead agent may review separately but is not invoked within this skill.

---

## Test Cases

### Case 1: New Language — String Extraction and Locale Skeleton Created

**Fixture:**
- Source code in `src/` contains player-facing strings (UI text, tutorial messages)
- Existing locale: `assets/localization/en.csv`
- No French locale exists

**Input:** `$localize fr`

**Expected behavior:**
1. Skill extracts all player-facing strings from source files
2. Skill finds the same strings in `en.csv` as a reference
3. Skill generates `fr.csv` skeleton with all string keys and empty values
4. Skill asks "May I write to `assets/localization/fr.csv`?"
5. File written on approval; verdict is GAPS FOUND (file created but empty values)
6. Skill notes: "fr.csv created — send to translator to fill values"

**Assertions:**
- [ ] All string keys from `en.csv` are present in `fr.csv`
- [ ] All values in `fr.csv` are empty (not copied from English)
- [ ] "May I write" is asked before creating the file
- [ ] Verdict is GAPS FOUND (file is created but untranslated)

---

### Case 2: Existing Locale Diff — Additions, Removals, and Changes Listed

**Fixture:**
- `assets/localization/fr.csv` exists with 20 string keys translated
- Source code has changed: 3 new strings added, 1 string removed, 2 strings
  with changed English source text

**Input:** `$localize fr`

**Expected behavior:**
1. Skill extracts current strings from source
2. Skill diffs against existing `fr.csv`
3. Skill produces diff report:
   - 3 new keys (need translation — listed as empty in fr.csv)
   - 1 removed key (marked as obsolete — suggest removal)
   - 2 changed keys (English source changed — French may need update, flagged)
4. Skill asks "May I update `assets/localization/fr.csv`?"
5. File updated with new empty keys added, obsolete keys marked; verdict is GAPS FOUND

**Assertions:**
- [ ] New keys appear as empty in the updated file (not auto-translated)
- [ ] Removed keys are flagged as obsolete (not silently deleted)
- [ ] Changed source strings are flagged for translator review
- [ ] Verdict is GAPS FOUND (new empty keys exist)

---

### Case 3: String Missing in One Locale — GAPS FOUND With Missing Key List

**Fixture:**
- 3 locale files exist: `en.csv`, `fr.csv`, `de.csv`
- `de.csv` is missing 4 keys that exist in both `en.csv` and `fr.csv`

**Input:** `$localize`

**Expected behavior:**
1. Skill reads all 3 locale files and cross-references keys
2. `de.csv` is missing 4 keys
3. Skill produces GAPS FOUND report listing the 4 missing keys by locale:
   "de.csv missing: [key1], [key2], [key3], [key4]"
4. Skill offers to add the missing keys as empty values to `de.csv`
5. After approval: file updated; verdict remains GAPS FOUND (values still empty)

**Assertions:**
- [ ] Missing keys are listed explicitly (not just a count)
- [ ] Missing keys are attributed to the specific locale file
- [ ] Verdict is GAPS FOUND (not LOCALIZATION COMPLETE)
- [ ] Missing keys are added as empty (not auto-translated from English)

---

### Case 4: Translation File Has Syntax Error — Error With Line Reference

**Fixture:**
- `assets/localization/fr.csv` has a malformed line at line 47
  (missing quote closure)

**Input:** `$localize fr`

**Expected behavior:**
1. Skill reads `fr.csv` and encounters a parse error at line 47
2. Skill outputs: "Parse error in fr.csv at line 47: [error detail]"
3. Skill cannot diff or validate the file until the error is fixed
4. Skill does NOT attempt to overwrite or auto-fix the malformed file
5. Skill suggests fixing the file manually and re-running `$localize`

**Assertions:**
- [ ] Error message includes line number (line 47)
- [ ] Error detail describes the nature of the parse error
- [ ] Skill does NOT overwrite or modify the malformed file
- [ ] Manual fix + re-run is suggested as remediation

---

### Case 5: Director Gate Check — No gate; localization is a pipeline utility

**Fixture:**
- Source code with player-facing strings

**Input:** `$localize fr`

**Expected behavior:**
1. Skill extracts strings and manages locale files
2. No director agents are spawned
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Verdict is LOCALIZATION COMPLETE or GAPS FOUND — no gate verdict

---

## Protocol Compliance

- [ ] Extracts strings from source before operating on locale files
- [ ] Creates new locale files with all keys as empty values (not auto-translated)
- [ ] Diffs existing locale files against current source strings
- [ ] Flags missing keys by locale and by key name
- [ ] Asks "May I write" before creating or updating any locale file
- [ ] Verdict is LOCALIZATION COMPLETE (all locales fully translated) or GAPS FOUND

---

## Coverage Notes

- LOCALIZATION COMPLETE is only achievable when all locale files have all keys
  with non-empty values; new-language skeleton creation always results in GAPS FOUND.
- Engine-specific locale formats (Godot `.translation`, Unity `.po` files) are
  handled by the skill body; `.csv` is used as the canonical format in tests.
- The case where source strings change at a very high rate (continuous integration
  of new UI text) is not tested; the diff logic handles this case.
