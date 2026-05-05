---
name: localize
description: "Full localization pipeline: scan for hardcoded strings, extract and manage string tables, validate translations, generate translator briefings, run cultural/sensitivity review, manage VO localization, test RTL/platform requirements, enforce string freeze, and report coverage."
argument-hint: "[scan|extract|validate|status|brief|cultural-review|vo-pipeline|rtl-check|freeze|qa]"
user-invocable: true
agent: localization-lead
allowed-tools: Read, Glob, Grep, Write, Bash, Task, AskUserQuestion
model: sonnet
---

# Localization Pipeline

Localization is not just translation — it is the full process of making a game
feel native in every language and region. Poor localization breaks immersion,
confuses players, and blocks platform certification. This skill covers the
complete pipeline from string extraction through cultural review, VO recording,
RTL layout testing, and localization QA sign-off.

**Modes:**
- `scan` — Find hardcoded strings and localization anti-patterns (read-only)
- `extract` — Extract strings and generate translation-ready tables
- `validate` — Check translations for completeness, placeholders, and length
- `status` — Coverage matrix across all locales
- `brief` — Generate translator context briefing document for an external team
- `cultural-review` — Flag culturally sensitive content, symbols, colours, idioms
- `vo-pipeline` — Manage voice-over localization: scripts, recording specs, integration
- `rtl-check` — Validate RTL language layout, mirroring, and font support
- `freeze` — Enforce string freeze; lock source strings before translation begins
- `qa` — Run the full localization QA cycle before release

If no subcommand is provided, output usage and stop. Verdict: **FAIL** — missing required subcommand.

---

## Phase 2A: Scan Mode

Search `src/` for hardcoded user-facing strings:

- String literals in UI code not wrapped in a localization function (`tr()`, `Tr()`, `NSLocalizedString`, `GetText`, etc.)
- Concatenated strings that should be parameterized
- Strings with positional placeholders (`%s`, `%d`) instead of named ones (`{playerName}`)
- Format strings that mix locale-sensitive data (numbers, dates, currencies) without locale-aware formatting

Search for localization anti-patterns:

- Date/time formatting not using locale-aware functions
- Number formatting without locale awareness (`1,000` vs `1.000`)
- Text embedded in images or textures (flag asset files in `assets/`)
- Strings that assume left-to-right text direction (positional layout, string assembly order)
- Gender/plurality assumptions baked into string logic (must use plural forms or gender tokens)
- Hardcoded punctuation (e.g. `"You won!"` — exclamation styles vary by locale)

Report all findings with file paths and line numbers. This mode is read-only — no files are written.

---

## Phase 2B: Extract Mode

- Scan all source files for localized string references
- Compare against the existing string table in `assets/data/strings/`
- Generate new entries for strings not yet keyed
- Suggest key names following the convention: `[category].[subcategory].[description]`
  - Example: `ui.hud.health_label`, `dialogue.npc.merchant.greeting`, `menu.main.play_button`
- Each new entry must include a `context` field — a translator comment explaining:
  - Where it appears (which screen, which scene)
  - Maximum character length
  - Any placeholder meaning (`{playerName}` = the player's chosen display name)
  - Gender/plurality context if applicable

Output a diff of new strings to add to the string table.

Present the diff to the user. Ask: "May I write these new entries to `assets/data/strings/strings-en.json`?"

If yes, write only the diff (new entries), not a full replacement. Verdict: **COMPLETE** — strings extracted and written.

---

## Phase 2C: Validate Mode

Read all string table files in `assets/data/strings/`. For each locale, check:

- **Completeness** — key exists in source (en) but no translation for this locale
- **Placeholder mismatches** — source has `{name}` but translation omits it or adds extras
- **String length violations** — translation exceeds the character limit recorded in the source `context` field
- **Plural form count** — locale requires N plural forms; translation provides fewer
- **Orphaned keys** — translation exists but nothing in `src/` references the key
- **Stale translations** — source string changed after translation was written (flag for re-translation)
- **Encoding** — non-ASCII characters present and font atlas supports them (flag if uncertain)

Report validation results grouped by locale and severity. This mode is read-only — no files are written.

---

## Phase 2D: Status Mode

- Count total localizable strings in the source table
- Per locale: count translated, untranslated, stale (source changed since translation)
- Generate a coverage matrix:

```markdown
## Localization Status
Generated: [Date]
String freeze: [Active / Not yet called / Lifted]

| Locale | Total | Translated | Missing | Stale | Coverage |
|--------|-------|-----------|---------|-------|----------|
| en (source) | [N] | [N] | 0 | 0 | 100% |
| [locale] | [N] | [N] | [N] | [N] | [X]% |

### Issues
- [N] hardcoded strings found in source code (run /localize scan)
- [N] strings exceeding character limits
- [N] placeholder mismatches
- [N] orphaned keys
- [N] strings added after freeze was called (freeze violations)
```

This mode is read-only — no files are written.

---

## Phase 2E: Brief Mode

Generate a translator context briefing document. This document is sent to the
external translation team or localisation vendor alongside the string table export.

Read:
- `design/gdd/` — extract game genre, tone, setting, character names
- `assets/data/strings/strings-en.json` — the source string table
- Any existing lore or narrative documents in `design/narrative/`

Generate `production/localization/translator-brief-[locale]-[date].md`:

```markdown
# Translator Brief — [Game Name] — [Locale]

## Game Overview
[2-3 paragraph summary of the game, genre, tone, and audience]

## Tone and Voice
- **Overall tone**: [e.g., "Darkly comic, not slapstick — think Terry Pratchett, not Looney Tunes"]
- **Player address**: [e.g., "Second person, informal. Never formal 'vous' — always 'tu' for French"]
- **Profanity policy**: [e.g., "Mild — PG-13 equivalent. Match intensity to source, do not soften or escalate"]
- **Humour**: [e.g., "Wordplay exists — if a pun cannot translate, invent an equivalent local joke; do not translate literally"]

## Character Glossary
| Name | Role | Personality | Notes |
|------|------|-------------|-------|
| [Name] | [Role] | [Personality] | [Do not translate / transliterate as X] |

## World Glossary
| Term | Meaning | Notes |
|------|---------|-------|
| [Term] | [What it means] | [Keep in English / translate as X] |

## Do Not Translate List
The following must appear verbatim in all locales:
- [Game name]
- [UI terms that match in-engine labels]
- [Brand or trademark names]

## Placeholder Reference
| Placeholder | What it represents | Example |
|-------------|-------------------|---------|
| `{playerName}` | Player's chosen display name | "Shadowblade" |
| `{count}` | Integer quantity | "3" |

## Character Limits
Tight UI fields with hard limits are marked in the string table `context` field.
Where no limit is stated, target ±30% of the English length as a guideline.

## Contact
Direct questions to: [placeholder for user/team contact]
Delivery format: JSON, same schema as strings-en.json
```

Ask: "May I write this translator brief to `production/localization/translator-brief-[locale]-[date].md`?"

---

## Phase 2F: Cultural Review Mode

Spawn `localization-lead` via Task. Ask them to audit the following for cultural sensitivity across the target locales (read from `assets/data/strings/` and `assets/`):

### Content Areas to Review

**Symbols and gestures**
- Thumbs up, OK hand, peace sign — meanings vary by region
- Religious or spiritual symbols in art, UI, or audio
- National flags, map representations, disputed territories

**Colours**
- White (mourning in some Asian cultures), green (political associations in some regions), red (luck vs danger)
- Alert/warning colours that conflict with cultural associations

**Numbers**
- 4 (death in Japanese/Chinese), 13, 666 — flag use in UI (room numbers, item counts, prices)

**Humour and idioms**
- Idioms that translate as offensive in other locales
- Toilet/bodily humour that is inappropriate in some markets (notably Japan, Germany, Middle East)
- Dark humour around topics that are culturally sensitive in specific regions

**Violence and content ratings**
- Content that would require ratings changes in DE (Germany), AU (Australia), CN (China), or AE (UAE)
- Blood colour, gore level, drug references — flag all for region-specific asset variants if needed

**Names and representations**
- Character names that are offensive, profane, or carry negative meaning in target locales
- Stereotyped representation of nationalities, religions, or ethnic groups

Present findings as a table:

| Finding | Locale(s) Affected | Severity | Recommended Action |
|---------|--------------------|----------|--------------------|
| [Description] | [Locale] | [BLOCKING / ADVISORY / NOTE] | [Change / Flag for review / Accept] |

BLOCKING = must fix before shipping that locale. ADVISORY = recommend change. NOTE = informational only.

Ask: "May I write this cultural review report to `production/localization/cultural-review-[date].md`?"

---

## Phase 2G: VO Pipeline Mode

Manage the voice-over localization process. Determine the sub-task from the argument:

- `vo-pipeline scan` — identify all dialogue lines that require VO recording
- `vo-pipeline script` — generate recording scripts with director notes
- `vo-pipeline validate` — check that all recorded VO files are present and correctly named
- `vo-pipeline integrate` — verify VO files are correctly referenced in code/assets

### VO Pipeline: Scan

Read `assets/data/strings/` and `design/narrative/`. Identify:
- All dialogue lines (keys matching `dialogue.*`) with source text
- Lines already recorded (audio file exists in `assets/audio/vo/`)
- Lines not yet recorded

Output a recording manifest:

```
## VO Recording Manifest — [Date]

| Key | Character | Source Line | Status |
|-----|-----------|-------------|--------|
| dialogue.npc.merchant.greeting | Merchant | "Welcome, traveller." | Recorded |
| dialogue.npc.merchant.haggle | Merchant | "That's my final offer." | Needs recording |
```

### VO Pipeline: Script

Generate a recording script document for each character, grouped by scene. Include:

- Character name and brief personality note
- Full dialogue line with pronunciation guide for unusual proper nouns
- Emotion/direction note for each line (`[Warm, welcoming]`, `[Annoyed, clipped]`)
- Any lines that are responses in a conversation (provide context: "Player just said X")

Ask: "May I write the VO recording scripts to `production/localization/vo-scripts-[locale]-[date].md`?"

### VO Pipeline: Validate

Glob `assets/audio/vo/[locale]/` for all `.wav`/`.ogg` files. Cross-reference against the VO manifest. Report:
- Missing files (line in script, no audio file)
- Extra files (audio file exists, no matching string key)
- Naming convention violations

### VO Pipeline: Integrate

Grep `src/` for VO audio references. Verify each referenced path exists in `assets/audio/vo/[locale]/`. Report broken references.

---

## Phase 2H: RTL Check Mode

Right-to-left languages (Arabic, Hebrew, Persian, Urdu) require layout mirroring beyond
just translating text. This mode validates the implementation.

Read `.claude/docs/technical-preferences.md` to determine the engine. Then check:

**Layout mirroring**
- Is RTL layout enabled in the engine? (Godot: `Control.layout_direction`, Unity: `RTL Support` package, Unreal: text direction flags)
- Are all UI containers set to auto-mirror, or are positions hardcoded?
- Do progress bars, health bars, and directional indicators mirror correctly?

**Text rendering**
- Are fonts loaded that support Arabic/Hebrew character sets?
- Is Arabic text rendered with correct ligatures (connected script)?
- Are numbers displayed as Eastern Arabic numerals where required?

**String assembly**
- Are there any string concatenations that assume left-to-right reading order?
- Do `{placeholder}` positions in sentences work correctly when sentence structure is reversed?

**Asset review**
- Are there UI icons with directional arrows or asymmetric designs that need mirrored variants?
- Do any text-in-image assets exist that require RTL versions?

Grep patterns to check:
- Engine-specific RTL flags in scene/prefab files
- Any `HBoxContainer`, `LinearLayout`, `HorizontalBox` nodes — verify layout_direction settings
- String concatenation with `+` near dialogue or UI code

Report findings. Flag BLOCKING issues (content unreadable without fix) vs ADVISORY (cosmetic improvements).

Ask: "May I write this RTL check report to `production/localization/rtl-check-[date].md`?"

---

## Phase 2I: Freeze Mode

String freeze locks the source (English) string table so that translations can proceed
without the source changing under the translators.

### freeze call

Check current freeze status in `production/localization/freeze-status.md` (if it exists).

If already frozen:
> "String freeze is currently ACTIVE (called [date]). [N] strings have been added or modified since freeze. These are freeze violations — they require re-translation or an approved freeze lift."

If not frozen, present the pre-freeze checklist:

```
Pre-Freeze Checklist
[ ] All planned UI screens are implemented
[ ] All dialogue lines are final (no further narrative revisions planned)
[ ] All system strings (error messages, tutorial text) are complete
[ ] /localize scan shows zero hardcoded strings
[ ] /localize validate shows no placeholder mismatches in source (en)
[ ] Marketing strings (store description, achievements) are final
```

Use `AskUserQuestion`:
- Prompt: "Are all items above confirmed? Calling string freeze locks the source table."
- Options: `[A] Yes — call string freeze now` / `[B] No — I still have strings to add`

If [A]: Write `production/localization/freeze-status.md`:

```markdown
# String Freeze Status

**Status**: ACTIVE
**Called**: [date]
**Called by**: [user]
**Total strings at freeze**: [N]

## Post-Freeze Changes
[Any strings added or modified after freeze are listed here automatically by /localize extract]
```

### freeze lift

If argument includes `lift`: update `freeze-status.md` Status to `LIFTED`, record the reason and date. Warn: "Lifting the freeze requires re-translation of all modified strings. Notify the translation team."

### freeze check (auto-integrated into extract)

When `extract` mode finds new or modified strings and `freeze-status.md` shows Status: ACTIVE — append the new keys to `## Post-Freeze Changes` and warn:
> "⚠️ String freeze is active. [N] new/modified strings have been added. These are freeze violations. Notify your localization vendor before proceeding."

---

## Phase 2J: QA Mode

Localization QA is a dedicated pass that runs after translations are delivered but
before any locale ships. This is not the same as `/validate` (which checks completeness)
— this is a structured playthrough-based quality check.

Spawn `localization-lead` via Task with:
- The target locale(s) to QA
- The list of all screens/flows in the game (from `design/gdd/` or `/content-audit` output)
- The current `/localize validate` report
- The cultural review report (if it exists)

Ask the localization-lead to produce a QA plan covering:

1. **Functional string check** — every string displays in-game without truncation, placeholder errors, or encoding corruption
2. **UI overflow check** — translated strings that exceed UI bounds (even if within character limits, some languages expand)
3. **Contextual accuracy** — a sample of 10% of strings reviewed in-game for translation accuracy and natural phrasing
4. **Cultural review items** — verify all BLOCKING items from the cultural review are resolved
5. **VO sync check** — if VO exists, verify lip sync or subtitle timing is acceptable after translation
6. **Platform cert requirements** — check platform-specific localization requirements (age ratings text, legal notices, ESRB/PEGI/CERO text)

Output a QA verdict per locale:

```
## Localization QA Verdict — [Locale]

**Status**: PASS / PASS WITH CONDITIONS / FAIL
**Reviewed by**: localization-lead
**Date**: [date]

### Findings
| ID | Area | Description | Severity | Status |
|----|------|-------------|----------|--------|
| LOC-001 | UI Overflow | "Settings" button text overflows on [Screen] | BLOCKING | Open |
| LOC-002 | Translation | [Key] translation is literal — sounds unnatural | ADVISORY | Open |

### Conditions (if PASS WITH CONDITIONS)
- [Condition 1 — must resolve before ship]

### Sign-Off
[ ] All BLOCKING findings resolved
[ ] Producer approves shipping [Locale]
```

Ask: "May I write this localization QA report to `production/localization/loc-qa-[locale]-[date].md`?"

**Gate integration**: The Polish → Release gate requires a PASS or PASS WITH CONDITIONS verdict for every locale being shipped. A FAIL blocks release for that locale only — other locales may still proceed if their QA passes.

---

## Phase 3: Rules and Next Steps

### Rules
- English (en) is always the source locale
- Every string table entry must include a `context` field with translator notes, character limits, and placeholder meaning
- Never modify translation files directly — generate diffs for review
- Character limits must be defined per-UI-element and enforced in validate mode
- String freeze must be called before sending strings to translators — never translate a moving target
- RTL support must be designed in from the start — retrofitting RTL layout is expensive
- Cultural review is required for any locale where the game will be sold commercially
- VO scripts must include director notes — raw dialogue lines produce flat recordings

### Recommended Workflow

```
/localize scan            → find hardcoded strings
/localize extract         → build string table
/localize freeze          → lock source before sending to translators
/localize brief           → generate translator briefing document
[Send to translators]
/localize validate        → check returned translations
/localize cultural-review → flag culturally sensitive content
/localize rtl-check       → if shipping Arabic / Hebrew / Persian
/localize vo-pipeline     → if shipping dubbed VO
/localize qa              → full localization QA pass
```

After `qa` returns PASS for all shipping locales, include the QA report path when running `/gate-check release`.
