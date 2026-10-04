# Skill Test Spec: /patch-notes

## Skill Summary

`/patch-notes` is a Sonnet-tier skill that turns a release's changes into
player-facing patch notes. Before reading any history it classifies recent
commits as Game or Framework / maintenance (Unclear counts as Framework), uses
only the Game commits, and says how many of how many it used. It gathers change
data from `production/releases/[version]/changelog.md`, the version's entry in
`docs/CHANGELOG.md`, and — as a fallback — `git log` from the previous release
tag. It checks for a tone guide (`.claude/docs/technical-preferences.md`,
`docs/PATCH-NOTES-STYLE.md`, `design/community/tone-guide.md`) and a patch-notes
template (`docs/patch-notes-template.md`,
`.claude/docs/templates/patch-notes-template.md`), removes internal-only
changes, and translates the rest into player language in Brief, Detailed
(default) or Full style — or in the template's structure when one exists, saying
which template it used. No director gates are used. The skill asks "May I write
these patch notes to `docs/patch-notes/[version].md`, and an archive copy to
`production/releases/[version]/patch-notes.md`?" — naming both files — and on
approval writes both. Verdicts:
COMPLETE (notes generated and saved) or BLOCKED (no changelog data and no git
history, or no Game commit in the history).

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I write" language (skill writes patch notes file)
- [ ] Has a next-step handoff (`/release-checklist`, community-manager tone review)

---

## Director Gate Checks

None. Patch notes generation is a fast compilation task; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — Changelog filtered to player-facing entries

**Fixture:**
- `docs/CHANGELOG.md` has a `v0.4.0` entry with 5 items:
  - "Add dual-wield melee system" (player-facing)
  - "Fix crash on level transition" (player-facing)
  - "Add enemy patrol AI" (player-facing)
  - "Refactor input handler to use event bus" (internal only)
  - "Update dependency: Godot 4.6" (internal only)
- Git history since the previous tag holds the Game commits behind those items
- No tone guide and no patch-notes template exist

**Input:** `/patch-notes v0.4.0`

**Expected behavior:**
1. Skill classifies the recent commits and says how many of how many it used
2. Skill reads the `v0.4.0` entry in `docs/CHANGELOG.md`
3. No tone guide is found, so the default tone applies; no template is found,
   so the built-in Detailed style (the default `--style`) is used
4. Skill keeps the 3 player-facing items and removes the 2 internal ones
5. Skill rewrites the items in player language (no task IDs, no internal system
   names)
6. Skill presents the notes with a count of changes by category and the list of
   excluded internal changes
7. Skill asks "May I write these patch notes to `docs/patch-notes/v0.4.0.md`, and an archive copy to `production/releases/v0.4.0/patch-notes.md`?"
8. User approves; both files are written; verdict COMPLETE

**Assertions:**
- [ ] Only the 3 player-facing items appear in the notes; the 2 internal items are listed separately as excluded, for review
- [ ] Entries are written in plain language without internal task IDs or system names
- [ ] Notes use the built-in Detailed style (Highlights, New Content, … Known Issues) — the default when no `--style` is given and no template exists
- [ ] "May I write" prompt naming `docs/patch-notes/v0.4.0.md` appears before any file is written
- [ ] Verdict is COMPLETE after the write

---

### Case 2: No Changelog File — Falls back to git history

**Fixture:**
- Neither `production/releases/v0.4.0/changelog.md` nor `docs/CHANGELOG.md` exists
- Tag `v0.3.0` exists; the range `v0.3.0..HEAD` holds 6 Game commits and 2
  Framework / maintenance commits (one touching a hook, one touching CI)

**Input:** `/patch-notes v0.4.0`

**Expected behavior:**
1. Skill classifies the commits, keeps the Game commits, excludes the 2
   framework commits, and says how many of how many it used
2. Skill finds no changelog source and uses `git log` from `v0.3.0` to HEAD as
   the fallback
3. Skill does NOT stop with BLOCKED — the "No changelog data found … Run
   `/changelog [version]` first" path requires the git history to be empty or
   unavailable as well
4. Skill generates notes from the Game commits only
5. Skill asks "May I write" before writing

**Assertions:**
- [ ] Skill does not crash and does not stop with BLOCKED while git history is available
- [ ] Skill falls back to `git log` from the previous tag (`v0.3.0`) to HEAD
- [ ] Output states how many of how many commits were used
- [ ] The 2 framework / maintenance commits do not appear in the patch notes
- [ ] "May I write" prompt appears before any file is written

---

### Case 3: Tone Guidance from Design Folder — Incorporated into output

**Fixture:**
- `docs/CHANGELOG.md` has a `v0.4.0` entry with player-facing items; git history
  holds the matching Game commits
- `design/community/tone-guide.md` exists with guidance: "upbeat, encouraging tone; avoid passive voice"
- `docs/PATCH-NOTES-STYLE.md` does not exist and
  `.claude/docs/technical-preferences.md` has no tone, voice or style fields
- No patch-notes template exists

**Input:** `/patch-notes v0.4.0`

**Expected behavior:**
1. Skill reads the changelog entry
2. Skill checks the three tone sources and finds `design/community/tone-guide.md`
3. Skill extracts the guide's instructions and applies them to the language and
   framing of the notes, in place of the built-in default tone
4. Structure stays the built-in Detailed style
5. Skill presents the notes, asks "May I write", writes on approval

**Assertions:**
- [ ] Skill checks the tone sources in Phase 2b, including `design/community/tone-guide.md`
- [ ] The tone guide's instructions are applied in place of the built-in default tone
- [ ] Entries use active voice ("Fixed a crash when…", "You can now…"), not passive ("A crash was fixed")
- [ ] Tone guidance changes wording only — the output structure is still the Detailed style

---

### Case 4: Patch Note Template Exists — Used instead of the built-in styles

**Fixture:**
- `.claude/docs/templates/patch-notes-template.md` exists with a header block,
  the sections `## New`, `## Fixed` and `## Known Issues`, and a footer
- `docs/CHANGELOG.md` has a `v0.4.0` entry with one new feature and one bug fix,
  both player-facing; git history holds the matching Game commits

**Input:** `/patch-notes v0.4.0 --style full`

**Expected behavior:**
1. Skill globs `docs/patch-notes-template.md` and
   `.claude/docs/templates/patch-notes-template.md`; finds and reads the second
2. Skill uses the template as the output structure instead of the built-in
   Brief / Detailed / Full templates — even though `--style full` was passed
3. The new feature goes under `## New`, the fix under `## Fixed`
4. The template's header and footer are preserved
5. The output says the template was used and that it replaced `--style full`
6. Skill asks "May I write" and writes on approval

**Assertions:**
- [ ] Skill globs both template locations before generating
- [ ] The template's structure replaces the built-in style — no "Developer Commentary" section from the Full style despite `--style full`
- [ ] The new feature is placed under `## New` and the fix under `## Fixed`
- [ ] The template's header and footer are preserved in the output
- [ ] Output notes that `.claude/docs/templates/patch-notes-template.md` was used, and that it replaced the requested `--style full`

---

### Case 5: Gate Compliance — No gate; community-manager is separate

**Fixture:**
- `docs/CHANGELOG.md` has a `v0.4.0` entry with player-facing items; git history
  holds the matching Game commits
- `project.yaml` sets `modes.review_mode: full`

**Input:** `/patch-notes v0.4.0`

**Expected behavior:**
1. Skill compiles patch notes; no director gate is spawned (the skill resolves
   only `automation`, never `review_mode`)
2. Skill self-reviews the notes (Phase 5), then presents them and asks to write
3. Next steps suggest `/release-checklist` and sharing the draft with the
   community-manager for tone review before posting publicly
4. User approves; notes are written; verdict COMPLETE

**Assertions:**
- [ ] No director gate is invoked regardless of review mode
- [ ] Output suggests (but does not require) a community-manager tone review before posting
- [ ] Skill proceeds directly from compilation and self-review to the "May I write" prompt
- [ ] Verdict is COMPLETE

---

### Case 6: Provenance Stop — Zero Game commits

**Fixture:**
- `git log --oneline -20` shows 20 commits, all touching the framework or
  tooling — subjects such as "fix: session-start hook timeout", "docs: skill
  catalog", "ci: cache the test runner" — and none names a game system in
  `design/` or the code root
- Neither `production/releases/v0.4.0/changelog.md` nor `docs/CHANGELOG.md` exists

**Input:** `/patch-notes v0.4.0`

**Expected behavior:**
1. Before Phase 2, skill classifies the sampled commits: 0 Game, 20 Framework /
   maintenance
2. Skill stops with "The git history in this repo does not appear to belong to
   [game] …", describing what the commits actually cover
3. No notes are generated and nothing is written; verdict BLOCKED

**Assertions:**
- [ ] Output names the classification result — 0 of 20 commits are Game commits
- [ ] Output contains the "does not appear to belong to" stop, not notes written from framework commits (no "Fixed an issue where …" line from a hook fix)
- [ ] No "May I write" prompt appears and no file is written
- [ ] Verdict is BLOCKED, not COMPLETE

---

### Case 7: No Changelog Data — No changelog and no git history

**Fixture:**
- Neither `production/releases/v0.4.0/changelog.md` nor `docs/CHANGELOG.md` exists
- The project directory is not a git repository, so `git log` returns nothing

**Input:** `/patch-notes v0.4.0`

**Expected behavior:**
1. The sampled log is empty, so the provenance check is skipped — there is
   nothing to classify
2. Phase 2 finds no changelog source and no git history; skill outputs "No
   changelog data found for v0.4.0. Run `/changelog v0.4.0` first to generate
   the internal changelog, then re-run `/patch-notes v0.4.0`."
3. Nothing is generated or written; verdict BLOCKED

**Assertions:**
- [ ] The "does not appear to belong to" provenance stop is NOT shown — an empty history is not a wrong history
- [ ] Output contains "No changelog data found for v0.4.0" and recommends `/changelog v0.4.0`
- [ ] No notes are generated, no "May I write" prompt appears, and no file is written
- [ ] Verdict is BLOCKED

---

## Protocol Compliance

- [ ] Runs the provenance check before reading history, uses only Game commits, and says how many were used
- [ ] Reads the version's changelog entry (`production/releases/[version]/changelog.md`, `docs/CHANGELOG.md`) before falling back to `git log`
- [ ] Filters entries to player-facing items only, and lists the excluded internal changes for review
- [ ] Rewrites entries in plain language without internal IDs
- [ ] Always asks "May I write" before writing patch notes
- [ ] No director gates are invoked
- [ ] Declares `model: sonnet` — it writes player-facing copy

---

## Coverage Notes

- A missing version argument (the skill asks before proceeding) is not tested.
- The case where all changelog entries are internal (zero player-facing items)
  is not tested.
- The community manager consultation noted in Case 5 is advisory; a separate
  skill or manual review handles that step.
