# Skill Test Spec: /art-bible

## Skill Summary

`/art-bible` authors the art bible at `design/art/art-bible.md` in nine
sections: 1 Visual Identity Statement, 2 Mood & Atmosphere, 3 Shape Language,
4 Color System, 5 Character Design Direction, 6 Environment Design Language,
7 UI/HUD Visual Direction, 8 Asset Standards, 9 Reference Direction.

It first reads `design/gdd/game-concept.md` (or `design/game-brief.md` at
`rigor: minimal`) and stops if neither exists. A two-tab `AskUserQuestion`
frames the session: **Scope** (with the option the resolved `workflow` tier
requires marked Recommended) and **References** (free text). Authoring is
progressive: sections 1–4 and 9 are drafted by a spawned `art-director`
(2–4 in one call); sections 5–8 are drafted by the skill itself under the lenses
in `references/` (`lens-art-director.md`; plus `lens-ux-designer.md` for section
7 and `lens-technical-artist.md` for section 8, each view shown as its own
block). Each section is presented, approved, and written to the file immediately
before the next starts; nothing else spawns. Sections 5–6 are one draft, but
their approvals and writes stay one section at a time, as do 2–4's. The first write asks "May I create `design/art/art-bible.md` from the
art bible template?"; each section is written only after an approval whose
option names the write (`[A] Lock this in and write it to design/art/art-bible.md`).
Only the sections in the chosen scope are authored, and the close names the
sections left out and why.

If the file already exists, the skill builds a section status table from two
Greps (headings and placeholder markers) without reading the document, and
authors only Empty or Placeholder sections.

After the scoped sections are written, Phase 5 runs the AD-ART-BIBLE sign-off in
`full` review mode only and records the verdict in the art bible's status
header. Phase 6 closes with an `AskUserQuestion` of next steps filtered by
project state.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains gate verdict keywords recorded in the status header: `APPROVED`, `CONCERNS`
- [ ] Contains ask-before-write language: "May I create `design/art/art-bible.md` from the art bible template?" before the file exists, and a per-section approval option that names the write (`Lock this in and write it to design/art/art-bible.md`)
- [ ] Documents the AD-ART-BIBLE director gate and its mode behavior
- [ ] Has a next-step handoff (e.g., `/map-systems`, `/create-architecture`)

---

## Director Gate Checks

| Gate ID      | Trigger condition                                        | Mode guard |
|--------------|----------------------------------------------------------|------------|
| AD-ART-BIBLE | Phase 5 — after all sections in the Phase 1 scope are written | full only; lean notes "AD-ART-BIBLE skipped — Lean mode.", solo notes "AD-ART-BIBLE skipped — Solo mode." |

The skill runs the gate itself, reading its definition
(`.claude/docs/director-gates/ad-art-bible.md`) as a checklist, against the bible
on disk, with the four inputs that definition lists: the art bible path, the game pillars and core
fantasy, the platform and performance constraints (`platform.*` and
`performance.*`), and the visual identity anchor. From a one-page brief it uses
the brief's pitch and "what they feel" line as the pillars and fantasy, and its
Label line ("Art & audio direction" in older briefs) as the anchor.

Drafting under the lenses is not a gate: it runs in every review mode.

---

## Fixture Defaults

Every case's `project.yaml` sets `modes.rigor: minimal` and
`modes.automation: collaborative`, with no `project.local.yaml`, unless its own
Fixture says otherwise. Rules: `studio-tests/CLAUDE.md` §
Fixture defaults.

---

## Test Cases

### Case 1: Happy Path — Full mode, full workflow, all nine sections, AD-ART-BIBLE approves

**Fixture:**
- No `design/art/art-bible.md`
- `design/gdd/game-concept.md` exists with pillars and a Visual Identity Anchor section
- `project.yaml` has `modes.review_mode: full` and `modes.workflow: full`
- AD-ART-BIBLE returns APPROVE

**Input:** `/art-bible`

**Expected behavior:**
1. Phase 0 reads the game concept and extracts title, pitch, pillars, the Visual Identity Anchor and platform
2. Phase 1 asks one `AskUserQuestion` with a Scope tab (Full bible marked Recommended, because `full` requires all 9 sections) and a free-text References tab, and notes the anchor it found
3. Section 1: `art-director` drafts it; the user picks from `[A] Lock this in and write it to design/art/art-bible.md` / `[B] Revise the one-liner` / `[C] Revise a supporting principle` / `[D] Describe my own direction`; after "May I create `design/art/art-bible.md` from the art bible template?", the file is created from `.claude/docs/templates/art-bible.md` and the approved section replaces Section 1's `[To be designed]` line
4. Sections 2–4: one `art-director` call returns three labelled blocks; Section 2 is presented, approved with the option that names the write, and written before Section 3 is presented, and so on
5. Sections 5–6: drafted together; presented, approved and written one at a time
6. Section 7: an art view and a UX view (UX lens) as separate blocks; Section 8: an art view and a technical view (technical-art lens) as separate blocks; Section 9: `art-director`
7. Phase 5: the skill runs AD-ART-BIBLE after the ninth section is written, with the art bible path, the pillars and core fantasy, the platform and performance constraints, and the visual identity anchor
8. The status header records `> **Art Director Sign-Off (AD-ART-BIBLE)**: APPROVED [date]`
9. Phase 6: `AskUserQuestion` of next steps that always includes `/create-architecture` and "Stop here"

**Assertions:**
- [ ] The Scope tab marks "Full bible — all 9 sections" as Recommended and says why
- [ ] Sections 1–4 and 9 come from a spawned `art-director`; sections 5–8 are drafted under their lenses with no spawn
- [ ] Sections 2–4 come from a single `art-director` call but are presented, approved and written one section at a time
- [ ] No section is written before an approval whose option names the write (`Lock this in and write it to design/art/art-bible.md`), and each is written immediately after it
- [ ] The file is created from `.claude/docs/templates/art-bible.md` only after "May I create `design/art/art-bible.md` from the art bible template?" — an ask that names the file — so its nine `## N. Name` headings are the ones retrofit mode (Case 4) reads
- [ ] AD-ART-BIBLE runs only after all nine sections are written, its verdict token printed first on its own line
- [ ] AD-ART-BIBLE uses all four context items: the art bible path, the pillars and core fantasy, the platform and performance constraints, and the visual identity anchor
- [ ] The APPROVE verdict is recorded in the art bible's status header line
- [ ] The closing options include `/create-architecture` and "Stop here"

---

### Case 2: AD-ART-BIBLE Returns CONCERNS or NOT ASSESSED

**Fixture:**
- All nine sections have been written to `design/art/art-bible.md`
- `project.yaml` has `modes.review_mode: full` and `modes.workflow: full`
- Scenario (a): AD-ART-BIBLE returns CONCERNS: "Color System does not match the Mood & Atmosphere targets for combat"
- Scenario (b): AD-ART-BIBLE returns NOT ASSESSED — no platform or performance constraints were available to check the asset standards against

**Input:** `/art-bible` (reaching Phase 5)

**Expected behavior:**
1. (a) The CONCERNS are surfaced to the user via `AskUserQuestion` with the standard options from `director-gates.md`: `Revise flagged items` / `Accept and proceed` / `Discuss further`
2. (a) If "Accept and proceed": the status header records `CONCERNS (accepted) [date]`
3. (a) If "Revise flagged items": `art-director` re-drafts Section 4; it is shown to the user and approved with the option that names the write before it is written; the status header then records `REVISED [date]`
4. (b) The missing input is named, and the status header records `NOT ASSESSED [date] — [missing input]`, never `APPROVED`
5. Phase 6 runs only after the verdict is recorded

**Assertions:**
- [ ] (a) CONCERNS are shown to the user with the three standard options, not auto-accepted
- [ ] (a) "Accept and proceed" records `CONCERNS (accepted) [date]` in the status header
- [ ] (a) The flagged section is re-drafted under its own lens and approved before it is written; the header records `REVISED [date]`
- [ ] (b) NOT ASSESSED is recorded as such, naming the missing input — not as an approval
- [ ] Phase 6 next steps are not presented before the verdict is recorded

---

### Case 3: Lean Mode, Standard Workflow — Core sections only, gate skipped

**Fixture:**
- No existing art bible
- `design/gdd/game-concept.md` exists
- `project.yaml` has `modes.review_mode: lean` and `modes.workflow: standard`
- User picks the Recommended scope

**Input:** `/art-bible`

**Expected behavior:**
1. The Scope tab marks "Visual identity core (sections 1–4 only)" as Recommended and says "Sections 1–4 are what `standard` requires; 5–9 are available if you want them."
2. Sections 1–4 are drafted by `art-director`, each approved and written before the next
3. Phases 3 and 4 (sections 5–9) are not run, because they are outside the chosen scope
4. Phase 5 does not run AD-ART-BIBLE and prints "AD-ART-BIBLE skipped — Lean mode."
5. Phase 6 first names sections 5–9 as not authored this run (outside the chosen scope), then presents next steps

**Assertions:**
- [ ] The Scope recommendation is sections 1–4, with the `standard` explanation
- [ ] Only sections 1–4 are authored
- [ ] The close names sections 5–9 as not authored and says why, so the four-section bible does not read as complete
- [ ] AD-ART-BIBLE does not run in lean mode, and the skip note reads "AD-ART-BIBLE skipped — Lean mode."
- [ ] Per-section user approval is still required before each write

---

### Case 4: Existing Art Bible — Retrofit of incomplete sections only

**Fixture:**
- `design/art/art-bible.md` exists with sections 1–4 fully written
- Section 5's heading is followed by `[To be designed]`
- Sections 6–9 have headings with nothing between them
- `design/gdd/game-concept.md` exists; `project.yaml` has `modes.workflow: full` and `modes.review_mode: full`
- At the Scope tab the user picks `Resume — fill in missing sections`
- AD-ART-BIBLE returns APPROVE

**Input:** `/art-bible`

**Expected behavior:**
1. Phase 0 Globs `design/art/art-bible.md` and finds it
2. The skill runs two Greps — `^## ` headings and placeholder markers (`[To be designed]`, `[TBD]`, `[To be written]`, `TODO`) — and does not read the whole document; an ambiguous section is read by line range only
3. It builds a status table (sections 1–4 Complete, 5 Placeholder, 6–9 Empty) and says: "Found existing art bible at `design/art/art-bible.md`. 4 sections are complete, 5 need content. I'll work on the incomplete sections only — existing content will not be touched."
4. Only sections 5–9 are authored, approved and written; sections 1–4 are not re-authored or rewritten
5. After the ninth section is written, Phase 5 runs AD-ART-BIBLE — a retrofit still ends in the sign-off in `full` review mode — and the status header records `APPROVED [date]`
6. Phase 6 names sections 1–4 as not authored this run (already complete)

**Assertions:**
- [ ] Section status comes from the two Greps, not from a full read of the file
- [ ] The retrofit message states the complete and incomplete counts and that existing content will not be touched
- [ ] Only Empty and Placeholder sections are authored; Complete sections are left unchanged
- [ ] The status table rows use the section names the skill authors (e.g., `Mood & Atmosphere`, `Shape Language`, `Reference Direction`)
- [ ] AD-ART-BIBLE runs after the retrofitted sections are written, as it does after a fresh run

---

### Case 5: Solo Mode and Missing Concept

**Fixture:**
- Scenario (a): no `design/gdd/game-concept.md`; `design/game-brief.md` exists; `project.yaml` has `modes.review_mode: solo` and `modes.workflow: minimal`
- Scenario (b): neither `design/gdd/game-concept.md` nor `design/game-brief.md` exists

**Input:** `/art-bible`

**Expected behavior:**
1. (a) Phase 0 reads the one-page brief (working title, pitch, "what they feel" line, Label line) in place of the concept
2. (a) Before the Scope question, the skill says no art bible is required at `minimal` and offers sections 1–4 rather than defaulting to all 9
3. (a) Each authored section is still drafted as in full mode (`art-director` for 1–4) — the solo review mode skips the sign-off, not the drafting
4. (a) Phase 5 prints "AD-ART-BIBLE skipped — Solo mode." and the gate does not run; on "May I record the skipped sign-off in `design/art/art-bible.md`'s header?" answered yes, the status header records `> **Art Director Sign-Off (AD-ART-BIBLE)**: SKIPPED [date] — solo mode`
5. (a) Phase 6, at `workflow: minimal`, offers `/create-stories`, `/dev-story [next story]` and Stop here — not `/create-architecture` or the GDD/`/map-systems` pool
6. (b) The skill stops with: "No game concept found. Run `/brainstorm` first — the art bible is authored after the game concept is approved." No file is created

**Assertions:**
- [ ] (a) The game brief is used when the game concept is absent
- [ ] (a) The skill states no art bible is required at `minimal` before asking the Scope question
- [ ] (a) `art-director` still drafts sections 1–4 in solo mode
- [ ] (a) AD-ART-BIBLE does not run; the skip note reads "AD-ART-BIBLE skipped — Solo mode.", and the header records the SKIPPED sign-off line with the mode and date
- [ ] (a) The Phase 6 option pool is the `workflow: minimal` set, not the `standard`/`full` GDD pool
- [ ] (b) The skill stops with the `/brainstorm` message and writes nothing

---

## Protocol Compliance

- [ ] Reads the game concept (or game brief) before authoring; stops with the `/brainstorm` message if neither exists
- [ ] Sections 1–4 and 9 are drafted by `art-director`, sections 5–8 under their lenses; the orchestrator never drafts from taste alone
- [ ] Each section is presented, approved and written one at a time — approvals and writes are never batched
- [ ] The file is created only after the "May I create `design/art/art-bible.md`…" ask, and each section is written only after an approval option that names the write
- [ ] Only the sections in the chosen scope are authored, and the close names every section left out and why
- [ ] Conflicts between the art view and the UX or technical view are surfaced to the user, never silently resolved
- [ ] AD-ART-BIBLE runs only in full mode, after the scoped sections are written; lean and solo print a skip note naming the gate and mode
- [ ] Ends with an `AskUserQuestion` of next steps filtered by project state — at `standard`/`full` always including `/create-architecture` and "Stop here"; at `workflow: minimal`, `/create-stories` or `/dev-story [next story]` plus Stop here

---

## Coverage Notes

- An AD-ART-BIBLE REJECT verdict is not separately tested; per the standard
  verdict rules the skill surfaces the blockers and does not advance until they
  are resolved, the flagged sections re-drafted the way they were first drafted and
  re-approved as in Case 2 (a).
- At `workflow: standard` the art bible is required only when visual asset
  stories exist. That condition is not fixture-tested; Case 3 covers only the
  `standard` scope recommendation.
- The Section 7 (art vs UX) and Section 8
  (art vs technical) conflict handling is covered only by
  Protocol Compliance, not by a dedicated fixture.
- The "Asset standards only (section 8)" scope option is not fixture-tested
  (Case 4 covers "Resume").
- `docs.density` depth variations and `guided` / `autonomous` automation modes
  are not tested.
- The Phase 6 option filtering (skip `/map-systems` when
  `design/gdd/systems-index.md` exists, etc.) is not individually tested.
