# Skill Test Spec: /balance-check

## Skill Summary

`/balance-check [system-name|path-to-data-file]` identifies the balance domain
(combat, economy, progression, loot, or a data file given directly), reads the
domain's data files from `assets/data/` and `design/balance/`, then reads the
intended values — from `design/registry/entities.yaml` first (its `constants:` and
`formulas:` blocks), and from the system's GDD in `design/gdd/` for anything the
registry does not supply. It compares every data value with its target — a
registry constant's `value`, a registry formula's `output_range`, or the GDD's
range — then runs domain-specific checks, and prints a report with
Data Sources Analyzed, a Health Summary, an Outliers Detected table
(Item/Value | Expected Range | Actual | Issue), Degenerate Strategies, Progression
Analysis, a Priority-ranked Recommendations table and Values That Need Attention.
Inputs it cannot find make the affected section `NOT ASSESSED — NO DATA`, naming
the missing source and `/design-system`, never an estimate; a value with no
target is listed as `no stated range — not judged`. After the report, an
`AskUserQuestion` offers [A] fix now, [B] save the report to
`design/balance/balance-check-[system]-[date].md`, [C] stop; it writes only on
[B]. No director gates are invoked. Health Summary, first match wins: CRITICAL
ISSUES, CONCERNS, NOT ASSESSED, HEALTHY.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: HEALTHY, CONCERNS, CRITICAL ISSUES, NOT ASSESSED
- [ ] Has ask-before-write language: the save is an `AskUserQuestion` option that names its target path, and the Write happens only when that option is chosen
- [ ] Has a next-step handoff (what to do after findings are reviewed)

---

## Director Gate Checks

None. Balance check is an analysis skill; no gates are invoked in any review mode.

---

## Test Cases

### Case 1: Happy Path — All balance values within their intended ranges

**Fixture:**
- `assets/data/combat-balance.json` exists with 6 stat values
- `design/registry/entities.yaml` has no entries (the shipped empty stub)
- `design/gdd/combat-system.md` gives an expected range for all 6 stats
- All 6 values fall inside their ranges; no degenerate strategy exists

**Input:** `/balance-check combat`

**Expected behavior:**
1. Skill identifies the Combat domain from the argument
2. Skill reads `assets/data/combat-balance.json` (and any combat files in `design/balance/`)
3. Registry has no entries, so the skill uses the GDD alone for the intended ranges
4. Each of the 6 values is compared with its GDD range and none falls outside; the combat checks find no dominant option
5. Report lists `assets/data/combat-balance.json` and `design/gdd/combat-system.md` under Data Sources Analyzed; the Outliers Detected table has no rows
6. Health Summary is HEALTHY
7. Phase 6 `AskUserQuestion` offers [A] / [B] / [C]; nothing is written before the user chooses

**Assertions:**
- [ ] Data Sources Analyzed lists every file read, including the data file and the GDD
- [ ] The empty registry is skipped and the GDD supplies the intended ranges
- [ ] The Outliers Detected table has no rows
- [ ] Health Summary is HEALTHY
- [ ] No file is written before the user picks option [B]

---

### Case 2: Outlier — Player damage far above its intended range

**Fixture:**
- `assets/data/combat-balance.json` has `player_damage_base: 140`
- `design/gdd/combat-system.md` gives `player_damage_base` an expected range of 90–110
- All other stats are within range

**Input:** `/balance-check combat`

**Expected behavior:**
1. Skill reads the data file and the GDD range for `player_damage_base`, and compares each value with its range
2. The Outliers Detected table lists `player_damage_base` with Expected Range 90–110, Actual 140 and an Issue description
3. The Recommendations table has a row for it with a Priority, a Suggested Fix and an Impact
4. Values That Need Attention gives a suggested adjustment with rationale
5. Health Summary is CONCERNS — one outlier a tuning pass can fix, with no degenerate strategy, stalled progression or sinkless loop
6. If the user picks [A] and changes `player_damage_base`, which the combat GDD defines, the skill reminds them to run `/propagate-design-change` on that GDD before committing

**Assertions:**
- [ ] `player_damage_base` appears in the Outliers Detected table with Expected Range 90–110 and Actual 140
- [ ] The Recommendations table ranks the fix with a Priority
- [ ] Health Summary is CONCERNS — not HEALTHY, and not CRITICAL ISSUES without a finding of the critical kind
- [ ] On [A], a fix to a GDD-defined value is followed by the `/propagate-design-change` reminder

---

### Case 3: No Design Targets — Data exists but no GDD or registry defines the ranges

**Fixture:**
- `assets/data/economy-balance.yaml` exists with 10 plain stat values (prices and rates, no faucet/sink loop the data alone could show)
- `design/registry/entities.yaml` has no entries
- No GDD in `design/gdd/` covers the economy

**Input:** `/balance-check economy`

**Expected behavior:**
1. Skill records its inputs as FOUND / ABSENT: the data file is FOUND; the registry entries and the economy GDD are ABSENT
2. Skill reads the data file and lists it under Data Sources Analyzed
3. The sections that need intended values (Outliers Detected, and Progression Analysis where it needs a target) are marked `NOT ASSESSED — NO DATA`, naming the missing economy GDD and the empty registry, and naming `/design-system` as the skill that writes them
4. No expected range is invented or inferred from the data itself
5. Health Summary is NOT ASSESSED — the report says the values could not be judged, not that they are fine

**Assertions:**
- [ ] Skill does not fabricate expected ranges when neither the registry nor a GDD supplies them
- [ ] The affected sections are marked `NOT ASSESSED — NO DATA` rather than shown as empty tables
- [ ] Output names the missing design source (economy GDD in `design/gdd/`, empty `design/registry/entities.yaml`) and `/design-system`
- [ ] Health Summary is NOT ASSESSED — not HEALTHY, and not CONCERNS, since nothing was found wrong

---

### Case 4: Registry First — The registry value overrides a contradicting GDD

**Fixture:**
- `design/registry/entities.yaml` `constants:` lists `player_damage_base` with `value: 100`, `unit: damage`, `source: design/gdd/combat-system.md` (a registry constant carries a value, not a range)
- `design/gdd/combat-system.md` still says `player_damage_base` range 100–130 (stale)
- `assets/data/combat-balance.json` has `player_damage_base: 125`

**Input:** `/balance-check combat`

**Expected behavior:**
1. Skill greps `design/registry/entities.yaml` (`^  - name:` with context) before reading the GDD
2. The target for `player_damage_base` is the registry constant's `value`, 100, not the GDD's range
3. 125 differs from the registry value 100, so `player_damage_base` appears in the Outliers Detected table with Expected Range 100 (the registry value) and Actual 125 — although it sits inside the stale GDD range
4. The GDD is still read for any value the registry does not list
5. Data Sources Analyzed lists the registry, the GDD and the data file

**Assertions:**
- [ ] The registry is read before the GDD
- [ ] `player_damage_base` is judged against the registry value (100), not the GDD range (100–130)
- [ ] `player_damage_base: 125` is reported as an outlier
- [ ] Data Sources Analyzed includes `design/registry/entities.yaml`

---

### Case 5: No Argument, Gate Compliance and the Save Path

**Fixture:**
- Combat data, registry and GDD exist; 1 stat is slightly outside its range
- `project.yaml`: `modes.review_mode: full`
- `modes.automation` resolves to `collaborative`

**Input:** `/balance-check` (no argument)

**Expected behavior:**
1. Skill asks the user which system to check; user answers "combat"
2. Skill reads data and design targets and prints the report
3. No director gate is invoked
4. After the report, `AskUserQuestion` offers [A] fix now, [B] save to `design/balance/balance-check-combat-[date].md`, [C] stop
5. On [B]: the report is written to `design/balance/balance-check-combat-[YYYY-MM-DD].md` (directory created if needed), the write is confirmed, and the skill ends with "Re-run `/balance-check` after fixes to verify."
6. On [C]: nothing is written; open issues are summarized and the same re-run line ends the output

**Assertions:**
- [ ] With no argument, the skill asks which system to check before reading data
- [ ] No director gate is invoked in any review mode
- [ ] The report is presented before the save option, and the save option names `design/balance/balance-check-[system]-[date].md`
- [ ] Option [B] writes to that path with the date in YYYY-MM-DD form; option [C] writes nothing
- [ ] Both [B] and [C] end with "Re-run `/balance-check` after fixes to verify."

---

### Case 6: Orphan Stat — A data value no GDD or registry defines

**Fixture:**
- `assets/data/combat-balance.json` holds 6 stats plus `legacy_armor_mult: 1.5`
- `design/registry/entities.yaml` has no entries
- `design/gdd/combat-system.md` gives a range for the 6 stats and nothing for `legacy_armor_mult`
- The 6 stats are inside their ranges; no degenerate strategy exists

**Input:** `/balance-check combat`

**Expected behavior:**
1. Every value is compared with its target; the 6 stats are in range
2. No target exists for `legacy_armor_mult`, so it is listed under Values That Need Attention as `no stated range — not judged`
3. It is not an Outliers Detected row, and it is not dropped from the report
4. Health Summary is NOT ASSESSED, naming `legacy_armor_mult` as the value that could not be judged

**Assertions:**
- [ ] `legacy_armor_mult` is reported as `no stated range — not judged`, apart from any outlier
- [ ] The orphan stat is not skipped silently and not judged against a range inferred from the data
- [ ] Health Summary is NOT ASSESSED, not HEALTHY, naming the unjudged value

---

## Protocol Compliance

- [ ] Reads the domain's data files (Phase 2) and the registry then GDD (Phase 3) before analysis
- [ ] Compares every data value with its target (registry constant `value`, registry formula `output_range`, or GDD range); a value outside it is an Outliers Detected row, a value with none is `no stated range — not judged`
- [ ] Outliers Detected table uses the columns Item/Value, Expected Range, Actual, Issue; Recommendations uses Priority, Issue, Suggested Fix, Impact
- [ ] A section whose inputs are absent is `NOT ASSESSED — NO DATA`, never estimated, and names the missing source and `/design-system`
- [ ] Writes only when the user picks the save option, and only to `design/balance/balance-check-[system]-[date].md`
- [ ] No director gates are invoked
- [ ] Health Summary, first match: CRITICAL ISSUES, CONCERNS, NOT ASSESSED, HEALTHY — HEALTHY only when every value was judged against a stated target

---

## Coverage Notes

- The case where every input is absent (no data files, no registry entries, no
  GDD) is not tested separately; the skill then stops and reports
  `NOT ASSESSED — NO DATA` as the whole verdict, naming what was missing and
  which skill produces it.
- CRITICAL ISSUES (a degenerate strategy, a stalled progression, a loop with no
  sink) is not given its own case; Case 2 pins that an outlier alone is CONCERNS.
- A data-file path argument (Phase 1 "File path given") is not tested; the
  domain is then inferred from the file's content.
