# Skill Test Spec: /playtest-report

## Skill Summary

`/playtest-report` has two modes. `new` outputs a blank playtest report template
and stops with Verdict COMPLETE, saving nothing;
`analyze [path]` reads raw notes from a file, cross-references the design
documents, fills the template with structured findings and flags observations
that conflict with design intent. Defects (crashes, framerate drops) go in the
Bugs Encountered table, not under Gameplay Flow → Pain points. The template has these sections: Session Info,
Test Focus, First Impressions, Gameplay Flow (what worked, pain points,
confusion, delight), Bugs Encountered, Feature-Specific Feedback, Quantitative
Data, Overall Assessment, and Top 3 Priorities.

Findings are sorted into four buckets and routed: design changes to
`/propagate-design-change [path]`, balance adjustments to `/balance-check
[system]`, bugs to `/bug-report`, polish items to the `production/` backlog. In
`full` review mode the skill spawns `creative-director` for gate **CD-PLAYTEST**;
in `lean` and `solo` it skips the gate with a note. It then asks "May I write
this playtest report to `production/qa/playtests/playtest-[date]-[tester].md`?".
Verdict is **COMPLETE**.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" collaborative protocol language before writing the report
- [ ] Has a next-step handoff (`/design-review` after design changes, `/bug-triage` after bug fixes)

---

## Director Gate Checks

- **Full mode**: CD-PLAYTEST — `creative-director` reviews the report against the
  game pillars and core fantasy (APPROVE / CONCERNS / REJECT, or NOT ASSESSED
  when it lacked an input), after findings are categorised and before the report
  is saved
- **Lean mode**: CD-PLAYTEST skipped (not a PHASE-GATE); note
  "CD-PLAYTEST skipped — Lean mode."
- **Solo mode**: CD-PLAYTEST skipped; note "CD-PLAYTEST skipped — Solo mode."

---

## Test Cases

### Case 1: Happy Path — Analyze Notes, Findings Routed by Bucket

**Fixture:**
- `production/qa/notes/session-01.md` holds one tester's notes: "framerate
  drops every time the forest area loads", "I could not work out how to open
  the first door", and "the second boss hits far too hard"
- `design/gdd/` holds the tutorial and combat GDDs; the tutorial GDD says the
  first door teaches the interact key
- Review mode: `solo`

**Input:** `/playtest-report analyze production/qa/notes/session-01.md`

**Expected behavior:**
1. Skill reads the notes and cross-references the design documents
2. Skill fills the template; the framerate drop goes in the Bugs Encountered table
3. Phase 3 presents findings in four buckets: the door confusion as a design
   change, the boss damage as a balance adjustment, the framerate drop as a bug
4. Routing: `/propagate-design-change` on the tutorial GDD, `/balance-check` for
   combat, `/bug-report` for the framerate drop
5. Skill notes "CD-PLAYTEST skipped — Solo mode." and asks "May I write this
   playtest report to `production/qa/playtests/playtest-[date]-[tester].md`?"
6. On approval the file is written; verdict is COMPLETE

**Assertions:**
- [ ] The framerate drop appears in the Bugs Encountered table, not under Gameplay Flow
- [ ] Findings are presented in the four buckets (design, balance, bug, polish)
- [ ] Each bucket is routed to its named skill (`/propagate-design-change`, `/balance-check`, `/bug-report`)
- [ ] "May I write" names `production/qa/playtests/playtest-[date]-[tester].md` before writing
- [ ] Verdict is COMPLETE

---

### Case 2: New Mode — Blank Template Output

**Fixture:**
- Any project state

**Input:** `/playtest-report new`

**Expected behavior:**
1. Skill selects `new` mode
2. Skill outputs the blank template with every section heading and its
   bracketed placeholders unfilled
3. No notes file is read and no findings are invented
4. The mode ends after the template: no routing, no director gate, no save
   ask, and the verdict is COMPLETE — blank template output; nothing saved

**Assertions:**
- [ ] Output contains the headings Session Info, Test Focus, First Impressions, Gameplay Flow, Bugs Encountered, Feature-Specific Feedback, Quantitative Data, Overall Assessment and Top 3 Priorities
- [ ] Placeholders (e.g. `[Date]`, `[Name/ID]`) are left unfilled
- [ ] No notes file is read and no findings are fabricated
- [ ] No "May I write" ask and no file written
- [ ] Verdict is COMPLETE

---

### Case 3: Observation Conflicts With Design Intent

**Fixture:**
- `design/gdd/crafting.md` states crafting is a core loop players engage with
  every session
- `production/qa/notes/session-02.md` records that the tester never opened the
  crafting menu in 40 minutes
- Review mode: `solo`

**Input:** `/playtest-report analyze production/qa/notes/session-02.md`

**Expected behavior:**
1. Skill reads the notes and cross-references `design/gdd/crafting.md`
2. Skill flags the observation as conflicting with design intent
3. Phase 3 puts it in the "Design changes needed" bucket
4. Routing names `/propagate-design-change` on `design/gdd/crafting.md`
5. Report saved after the "May I write" ask; verdict COMPLETE

**Assertions:**
- [ ] The crafting observation is explicitly flagged as conflicting with the GDD's intent
- [ ] It is categorised as a design change, not a polish item
- [ ] `/propagate-design-change` is suggested on the affected GDD
- [ ] Verdict is COMPLETE after the write

---

### Case 4: Edge Case — Full Review Mode With No Pillars Available

**Fixture:**
- Review mode: `full`
- Neither `design/gdd/game-concept.md` nor `design/game-brief.md` exists
- `production/qa/notes/session-03.md` holds playtest notes

**Input:** `/playtest-report analyze production/qa/notes/session-03.md`

**Expected behavior:**
1. Skill structures and categorises the findings
2. Skill spawns `creative-director` for CD-PLAYTEST with the report content and
   the hypothesis being tested
3. Because neither pillars source exists, the prompt states "No pillars
   available — assess against the hypothesis alone." rather than omitting pillars
4. The director's assessment is presented before the save ask

**Assertions:**
- [ ] CD-PLAYTEST is spawned (review mode is `full`)
- [ ] The gate prompt says no pillars are available instead of passing none silently
- [ ] Pillars are not invented by the skill
- [ ] The assessment is shown before "May I write"

---

### Case 5: Director Gate — CD-PLAYTEST by Review Mode

**Fixture:**
- `design/gdd/game-concept.md` exists with pillars
- `production/qa/notes/session-04.md` holds playtest notes
- Run three times: `--review full`, `--review lean`, `--review solo`
- In the full run, `creative-director` returns CONCERNS

**Input:** `/playtest-report analyze production/qa/notes/session-04.md --review [mode]`

**Expected behavior:**
1. Full: after Phase 3 categorisation, `creative-director` is spawned for
   CD-PLAYTEST with the report content, pillars from `game-concept.md` and the
   hypothesis; its CONCERNS assessment is presented and a
   `## Creative Director Assessment` section is added to the report
2. Lean: no director spawned; note "CD-PLAYTEST skipped — Lean mode."
3. Solo: no director spawned; note "CD-PLAYTEST skipped — Solo mode."
4. All three runs then ask "May I write" and end with verdict COMPLETE

**Assertions:**
- [ ] In full mode, CD-PLAYTEST spawns `creative-director` before the report is saved
- [ ] On CONCERNS, the report gains a `## Creative Director Assessment` section with the verdict and feedback
- [ ] In lean mode, the skip note names CD-PLAYTEST and Lean mode
- [ ] In solo mode, the skip note names CD-PLAYTEST and Solo mode
- [ ] No other director gate is spawned in any mode

---

## Protocol Compliance

- [ ] `analyze` reads the notes file and cross-references design documents before filling the template
- [ ] Findings are categorised into design / balance / bug / polish and routed to the named follow-up
- [ ] Applies the review mode before spawning CD-PLAYTEST and prints the skip note when skipped
- [ ] Presents the director's assessment (full mode) before asking to save
- [ ] Asks "May I write this playtest report to `production/qa/playtests/playtest-[date]-[tester].md`?" before writing
- [ ] Ends with verdict COMPLETE and next steps (`/design-review`, `/bug-triage`)

---

## Coverage Notes

- A REJECT verdict from CD-PLAYTEST follows the same path as CONCERNS (an
  assessment section is added) and is not separately tested; APPROVE only adds
  an approval note. NOT ASSESSED (the director lacked an input) adds the section
  naming what was missing and is never read as an approval; not separately tested.
- At `modes.workflow: minimal`, where `design/game-brief.md` replaces
  `game-concept.md`, the brief has no pillars: its one-sentence pitch and "Who
  it's for / what they feel" line are passed in their place; not separately tested.
- Video or screenshot attachments are not tested; the report is text only.
