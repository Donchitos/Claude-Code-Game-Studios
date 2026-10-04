# Skill Test Spec: /asset-audit

## Skill Summary

`/asset-audit` audits the engine's asset root — `assets/` (art, audio, vfx,
shaders, data) on Godot, `Assets/` on Unity, `Content/` on Unreal — for naming
convention compliance, size budgets, format standards, orphaned assets and
missing assets. It reads the art bible or asset standards from the design docs
(Phase 1), resolves the engine and its code root and scans the asset root with
Glob (Phase 2), measures sizes and formats with the pre-approved read-only
commands (`stat`, `file`, `od`, `wc`, `du`), and checks Godot names against its
own patterns — art `[category]_[name]_[variant]_[size].[ext]`, audio
`[category]_[context]_[name]_[variant].[ext]`, all lowercase with underscores —
and Unity and Unreal names only against a rule the art bible states. Orphaned
and missing assets are found by searching the **code root** for asset
references; GDD-level completeness is `/content-audit`'s job. The report lists
violations only, in one table per category, and names every section it could
not assess. A measurement it cannot take is `NOT ASSESSED`, never an estimate.
The skill is read-only: it writes no files and invokes no director gates.
Verdicts, first match wins: NON-COMPLIANT, WARNINGS, NOT ASSESSED, COMPLIANT —
COMPLIANT only when at least one asset was scanned and every section assessed.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLIANT, WARNINGS, NON-COMPLIANT, NOT ASSESSED
- [ ] Does NOT require "May I write" language (read-only: `allowed-tools` has no Write/Edit and the skill states it does not write files)
- [ ] Has a next-step handoff (what to do after audit results)

---

## Director Gate Checks

None. Asset auditing is a read-only analysis skill; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — All assets follow naming conventions

**Fixture:**
- `project.yaml`: `engine.name: godot`, so the asset root is `assets/` and the code root `src/`
- `design/art/art-bible.md` Asset Standards: textures PNG, power-of-two, ≤2MB; SFX OGG, 44.1 kHz, ≤500KB (no duration budget)
- `assets/art/characters/` contains: `char_grunt_idle_512.png`, `char_sniper_run_512.png` (512×512 PNG, 300KB each)
- `assets/audio/sfx/` contains: `sfx_player_jump_01.ogg`, `sfx_item_pickup_01.ogg` (OGG, 44.1 kHz, 80KB and under 1 s each)
- `src/` references all four files

**Input:** `/asset-audit`

**Expected behavior:**
1. Skill reads the asset standards from `design/art/art-bible.md` (Phase 1)
2. Skill resolves the engine to Godot and globs `assets/art/**/*` and `assets/audio/**/*` (Phase 2)
3. Every name matches the Phase 3 art or audio pattern; every file is within budget and in the expected format; every file is referenced from code
4. Summary shows 4 assets scanned, 0 in every violation count and no section not assessed; the violation tables are empty
5. Verdict is COMPLIANT

**Assertions:**
- [ ] Audit covers both art and audio asset directories
- [ ] Each file is checked against the Phase 3 naming pattern and the size budget from the art bible
- [ ] Summary reports `Total assets scanned: 4` with zero naming, size, format, orphaned and missing counts, and `Sections not assessed: none`
- [ ] Verdict is COMPLIANT
- [ ] No files are written

---

### Case 2: Non-Compliant — Textures exceed size budget

**Fixture:**
- `project.yaml`: `engine.name: godot`
- `design/art/art-bible.md` asset standards: textures PNG, power-of-two, ≤2MB
- `assets/art/environment/` contains 5 correctly named power-of-two PNG textures, all referenced from code
- 3 of them are 4096×4096 at 4MB each; 2 are 1024×1024 at 1MB each

**Input:** `/asset-audit`

**Expected behavior:**
1. Skill reads the 2MB texture budget from the art bible
2. Skill measures each file's size with `stat` or `du` — not by estimate
3. The Size Violations table lists the 3 oversized files with Budget, Actual and Overage
4. The 2 within-budget files do not appear in the Size Violations table; `Total assets scanned` counts all 5
5. Recommendations give each oversized file its own fix, naming the target — a resolution (such as 2048×2048) or a compression setting that brings it under 2MB
6. Verdict is NON-COMPLIANT

**Assertions:**
- [ ] All 3 oversized files appear in the Size Violations table with Budget (2MB), Actual (4MB) and Overage
- [ ] Sizes come from a measuring command (`stat`/`du`), not an estimate
- [ ] Verdict is NON-COMPLIANT when any file exceeds its budget
- [ ] Each oversized file has a recommendation that names its target resolution or compression, not only "reduce size"
- [ ] The 2 within-budget files are counted in `Total assets scanned` but are not listed as violations

---

### Case 3: Format Issue — Music in wrong format

**Fixture:**
- `project.yaml`: `engine.name: godot`
- `design/art/art-bible.md` asset standards: SFX OGG ≤500KB; music OGG or MP3 ≤8MB
- `assets/audio/music/music_menu_theme_01.wav` exists (WAV format, 6MB), referenced from code
- `assets/audio/sfx/sfx_player_footstep_01.ogg` exists (OGG format, 40KB), referenced from code

**Input:** `/asset-audit`

**Expected behavior:**
1. Skill applies the Phase 3 audio format standard (OGG for SFX, OGG/MP3 for music)
2. Skill identifies the WAV file's format with `file` or a header read
3. The Format Violations table lists `music_menu_theme_01.wav` with expected OGG/MP3 and actual WAV
4. `sfx_player_footstep_01.ogg` does not appear in any violation table; both files are within their size budgets
5. Recommendations name the target format for the WAV file (re-export as OGG or MP3)
6. Verdict is WARNINGS (a format issue is correctable)

**Assertions:**
- [ ] `music_menu_theme_01.wav` appears in the Format Violations table with Expected Format OGG/MP3 and Actual Format WAV
- [ ] The recommendation for the WAV file names OGG or MP3 as its target format
- [ ] Verdict is WARNINGS (not NON-COMPLIANT) for a format issue alone
- [ ] `sfx_player_footstep_01.ogg` is not listed in any violation table
- [ ] Skill does not modify or convert any asset files

---

### Case 4: Missing Asset — Referenced by code but absent from assets/

**Fixture:**
- `project.yaml`: `engine.name: godot`; `design/art/art-bible.md` sets texture budgets
- `assets/art/characters/` holds 3 other correctly named textures, within budget and referenced from code
- `src/enemies/boss.gd` loads `res://assets/art/characters/boss/char_boss_idle_512.png`
- `assets/art/characters/boss/` is empty — the file does not exist
- `design/gdd/enemies.md` also names `char_boss_roar_512.png`, which no code references

**Input:** `/asset-audit`

**Expected behavior:**
1. Skill searches code for asset references (Phase 3 "Missing assets") and checks each path exists
2. `char_boss_idle_512.png` is not found
3. The Missing Assets table lists Reference Location `src/enemies/boss.gd` and the Expected Path
4. The GDD-only name `char_boss_roar_512.png` is not reported — the missing-asset check searches code, not GDDs
5. Verdict is NON-COMPLIANT
6. Next steps point to `/content-audit` for the GDD cross-check

**Assertions:**
- [ ] The Missing Assets table lists `src/enemies/boss.gd` as the reference location and `assets/art/characters/boss/char_boss_idle_512.png` as the expected path
- [ ] The GDD-only asset name is not reported as missing
- [ ] Verdict is NON-COMPLIANT when a code-referenced asset is missing
- [ ] Next steps name `/content-audit` for GDD-vs-asset completeness
- [ ] Skill does not create or add placeholder assets

---

### Case 5: No Data — No assets and no asset standards

**Fixture:**
- `project.yaml`: `engine.name: godot`, `modes.review_mode: full`
- `assets/` does not exist
- `design/art/art-bible.md` does not exist; no design doc defines asset standards

**Input:** `/asset-audit`

**Expected behavior:**
1. Skill runs its insufficient-input check before producing a report: records each input as FOUND or ABSENT
2. Every required input is ABSENT, so the skill stops
3. Verdict is `NOT ASSESSED — NO DATA`, naming what was missing and which skill produces it
4. The skill does not report COMPLIANT and does not render zero-count violation tables as a clean pass
5. No director gate is invoked in any review mode; no file is written and no write is offered

**Assertions:**
- [ ] Inputs are listed as FOUND / ABSENT before any report section
- [ ] Verdict is `NOT ASSESSED — NO DATA`, not COMPLIANT
- [ ] The report names the missing inputs (`assets/`, asset standards) and the skill that produces the standards (`/art-bible`)
- [ ] No director gate is invoked, even with review mode `full`
- [ ] No "May I write" prompt appears and no file is written

---

### Case 6: Zero Assets — Standards exist, nothing to audit

**Fixture:**
- `project.yaml`: `engine.name: godot`
- `design/art/art-bible.md` asset standards: textures PNG ≤2MB; SFX OGG ≤500KB
- `assets/` does not exist; `src/` holds gameplay code that loads no asset yet

**Input:** `/asset-audit`

**Expected behavior:**
1. The art bible is FOUND, so the insufficient-input check does not stop the run
2. Phase 2 globs `assets/` and matches nothing: `Total assets scanned: 0`
3. Naming, Size, Format and Orphaned are `NOT ASSESSED — no assets under assets/`, and the Summary lists them; the missing-asset search runs and finds no reference
4. Verdict is NOT ASSESSED — zero violations over zero files is not compliance

**Assertions:**
- [ ] `Total assets scanned` is 0 and the four file checks are NOT ASSESSED with that reason
- [ ] Verdict is NOT ASSESSED, not COMPLIANT
- [ ] No file is written

---

### Case 7: No Standards — Assets exist, no size budget anywhere

**Fixture:**
- `project.yaml`: `engine.name: godot`
- `design/art/art-bible.md` does not exist; no design doc states asset standards
- `assets/art/ui/` holds 3 correctly named power-of-two PNGs; `src/` references all three

**Input:** `/asset-audit`

**Expected behavior:**
1. Assets are FOUND and standards ABSENT, so the skill runs rather than stopping
2. Naming, Format, Orphaned and Missing are checked; none finds a violation
3. Size is `NOT ASSESSED — no size budget set`, and the report names `/art-bible` as the skill that writes the standards
4. The Summary lists Size under Sections not assessed
5. Verdict is NOT ASSESSED, naming Size

**Assertions:**
- [ ] No size is judged against an invented budget
- [ ] The Size section is `NOT ASSESSED — no size budget set` and `/art-bible` is named
- [ ] Verdict is NOT ASSESSED, not COMPLIANT

---

### Case 8: Unreal Project — Assets under `Content/`

**Fixture:**
- `project.yaml`: `engine.name: unreal`, so the code root is `Source/<Module>/`
- `design/art/art-bible.md` asset standards: textures ≤4MB; no naming convention stated
- `Content/Characters/Grunt/` holds `T_Grunt_D.uasset` (2.5MB) and `T_Grunt_N.uasset` (2.1MB)
- `assets/` does not exist
- `Source/Arena/Private/GruntCharacter.cpp` loads `/Game/Characters/Grunt/T_Grunt_D`

**Input:** `/asset-audit`

**Expected behavior:**
1. Phase 2 globs `Content/**/*.uasset` and `Content/**/*.umap`, not `assets/`: `Total assets scanned: 2`
2. Both sizes are measured against the 4MB texture budget; neither is over
3. The PascalCase names are not checked against the Godot lowercase patterns; with no naming rule in the art bible, Naming is `NOT ASSESSED — no naming rule for Unreal`, and `/art-bible` is named
4. Format is NOT ASSESSED (an Unreal asset file does not keep its source format) and Orphaned is NOT ASSESSED (Unreal assets are referenced from other assets, not only from code)
5. The code reference resolves to an existing asset, so Missing has no finding
6. Verdict is NOT ASSESSED, naming Naming, Format and Orphaned

**Assertions:**
- [ ] The scan covers `Content/` and counts 2 assets, not 0
- [ ] No naming violation is raised from the Godot lowercase patterns
- [ ] Naming, Format and Orphaned are each listed as NOT ASSESSED with a reason
- [ ] Verdict is NOT ASSESSED, never COMPLIANT and never a report of zero assets

---

### Case 9: Engine Unresolved — Stop before scanning

**Fixture:**
- `project.yaml` has no `engine.name`; `.claude/docs/technical-preferences.md` reads `[TO BE CONFIGURED]`
- Both `src/` and `Source/` exist, so the tree does not decide the engine
- `design/art/art-bible.md` has asset standards; `assets/art/` holds PNG files

**Input:** `/asset-audit`

**Expected behavior:**
1. Phase 2 cannot resolve the engine or its code root per `.claude/docs/code-root-resolution.md`
2. The skill stops with `NOT ASSESSED — engine unresolved`, naming `/setup-engine`
3. No asset root is guessed, so the Godot naming patterns are not applied and no section is reported clean

**Assertions:**
- [ ] Verdict is `NOT ASSESSED — engine unresolved`, not COMPLIANT
- [ ] Output names `/setup-engine`
- [ ] No violation table is filled from an assumed `assets/` layout

---

## Protocol Compliance

- [ ] Reads the art bible or asset standards design docs before scanning (Phase 1)
- [ ] Resolves the engine and its code root, then scans that engine's asset root with Glob (`assets/` subfolders on Godot, `Assets/` on Unity, `Content/` on Unreal); an unresolved engine stops the run as NOT ASSESSED
- [ ] Report uses one table per category: Naming (File, Expected Pattern, Issue), Size (File, Budget, Actual, Overage), Format (File, Expected Format, Actual Format), Orphaned (File, Last Modified, Size, Recommendation), Missing (Reference Location, Expected Path)
- [ ] A size or format it cannot measure is `NOT ASSESSED`, never an estimate, and every section not assessed is named with its reason
- [ ] Each recommendation names the change for its violation (target resolution or compression, corrected name, target format)
- [ ] Does not modify any asset files and writes no report file
- [ ] No director gates are invoked
- [ ] Verdict, first match: NON-COMPLIANT, WARNINGS, NOT ASSESSED, COMPLIANT — COMPLIANT only with at least one asset scanned and every section assessed

---

## Coverage Notes

- The skill does not check import metadata (Godot `.import` files, Unity `.meta`
  files, Unreal import settings); a missing import setting is not reported.
- Orphan detection on Godot (an asset no code references) is not given its own
  case; it uses the same code search as Case 4 in the other direction. On Unity
  and Unreal it is NOT ASSESSED (Case 8).
- Unity follows Case 8's naming and orphan rules, with Format still checked on
  the source files under `Assets/`; it is not tested separately.
- `/asset-audit` checks compliance against code references; `/content-audit`
  checks completeness against the GDDs. Case 4 pins that boundary.
- An audio duration budget is not measurable with the skill's tools, so it makes
  that check NOT ASSESSED; Case 1's fixture sets none, and the path is not given
  its own case.
