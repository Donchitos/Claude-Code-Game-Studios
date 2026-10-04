# Skill Test Spec: /changelog

## Skill Summary

`/changelog` is a Sonnet-tier skill that generates two changelogs — an internal
one and a player-facing one — from the git commits since the last release tag.
Before using the injected history it classifies every commit as Game or
Framework / maintenance (Unclear counts as Framework), uses only the Game
commits, and says how many of how many it used; with zero Game commits it stops.
With no history at all (not a git repository, or no commits) it skips that check
and stops at Phase 1. It reads sprint plans in `production/sprints/` and GDDs in
`design/gdd/` for context, and sorts changes into New Features, Improvements, Bug
Fixes, Balance Changes, Technical Debt / Refactoring (internal changelog only),
Known Issues and Miscellaneous. The internal changelog ends with a Metrics
section that counts commits without a task reference. With no tags it bounds the
range to `git log --oneline -n 100` rather than reading the full log. No director
gates are used. The skill asks "May I write this changelog to
`docs/CHANGELOG.md`?" with append / overwrite / decline options. Verdicts:
CHANGELOG WRITTEN after a write, COMPLETE when the user declines the write,
BLOCKED when there is no history or none of it is the game's.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: CHANGELOG WRITTEN, COMPLETE, BLOCKED
- [ ] Contains "May I write" language (skill writes changelog)
- [ ] Has a next-step handoff (`/patch-notes` for a player-facing release, `/release-checklist`)

---

## Director Gate Checks

None. Changelog generation is a fast compilation task; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — Multiple sprints since last release tag

**Fixture:**
- Git history has a tag `v0.3.0`; it is the newest tag in the injected tag list
- Since that tag: 12 commits across sprints 006, 007, 008 — all Game commits
  (mechanics, content, bug fixes) naming systems that appear in `design/`
- `production/sprints/sprint-006.md` through `sprint-008.md` exist and list the
  stories whose task IDs appear in the commit messages
- `docs/CHANGELOG.md` does not yet exist

**Input:** `/changelog`

**Expected behavior:**
1. Skill classifies the injected commits as Game or Framework / maintenance and
   states how many of how many it used
2. Skill reads `git log --oneline v0.3.0..HEAD`
3. Skill reads the sprint plans for sprints 006–008 in `production/sprints/`
   for the context behind the changes
4. Skill categorizes changes into New Features, Improvements, Bug Fixes,
   Balance Changes, Technical Debt / Refactoring, Known Issues and
   Miscellaneous, with a Metrics section
5. Skill outputs both the internal and the player-facing changelog
6. Skill asks "May I write this changelog to `docs/CHANGELOG.md`?" with options
   [A] append, [B] overwrite, [C] no
7. User selects [B]; the file is created; verdict CHANGELOG WRITTEN

**Assertions:**
- [ ] Changelog covers the commits in `v0.3.0..HEAD`, and the output states how many of how many injected commits it used
- [ ] Entries use the skill's section set — New Features, Improvements, Bug Fixes, Balance Changes, Technical Debt / Refactoring, Known Issues, Miscellaneous — not a generic Features/Fixes split
- [ ] Sprint plans in `production/sprints/` for the covered sprints are read for context before categorizing
- [ ] Both changelogs are presented before the "May I write" prompt, and nothing is written before approval
- [ ] Verdict is CHANGELOG WRITTEN after the write

---

### Case 2: No Git Tags Found — Bounded range used

**Fixture:**
- Git repository has 20 commits and no tags; all 20 are Game commits
- The injected tag list is empty
- `docs/CHANGELOG.md` does not exist

**Input:** `/changelog`

**Expected behavior:**
1. Skill finds no tag to anchor the range
2. Skill bounds the range with `git log --oneline -n 100` — it does not read an
   unbounded full log
3. All 20 commits fall inside the 100-commit bound, so the window reaches the
   start of history and the skill does not need to ask for a start ref
4. Skill states how many of the commits it used
5. Skill compiles the categorized changelog and asks "May I write" before writing

**Assertions:**
- [ ] Skill does not error when no git tags exist
- [ ] The range is read with the bounded `git log --oneline -n 100`, never an unbounded full log
- [ ] All 20 commits are covered, and the skill does not ask for a start ref (the bound reaches the first commit)
- [ ] Output states how many of the 20 commits were used
- [ ] Changelog is still organized into sections despite the missing tag

---

### Case 3: Commit Messages Without Task IDs — Categorized by content, counted in Metrics

**Fixture:**
- Git log since the last tag has 8 Game commits
- 3 commits reference task IDs (e.g. `[STORY-012]`) matching sprint stories
- 5 commits have no task ID: "tweak dash cooldown 0.8 -> 0.6",
  "fix player clipping through ledge", "add footstep sounds", "level tweaks",
  "combat cleanup"

**Input:** `/changelog`

**Expected behavior:**
1. Skill categorizes every commit by what it changed, whether or not it has a
   task ID
2. "tweak dash cooldown 0.8 -> 0.6" goes to Balance Changes; "fix player
   clipping through ledge" goes to Bug Fixes
3. "combat cleanup" says it cleans up and names no fix, feature or tuning, so it
   goes to Technical Debt / Refactoring — in the internal changelog only
4. "level tweaks" is too vague to classify confidently and goes to
   Miscellaneous
5. The Metrics section reports `Commits without task reference: 5`
6. Skill asks "May I write" and writes on approval

**Assertions:**
- [ ] Commits are categorized by content with or without a task ID — the untagged "tweak dash cooldown 0.8 -> 0.6" lands in Balance Changes, not in a separate no-ID group
- [ ] "combat cleanup" is listed under Technical Debt / Refactoring in the internal changelog and does not appear in the player-facing changelog
- [ ] "level tweaks", too vague to classify, is listed under Miscellaneous
- [ ] Metrics section contains `Commits without task reference: 5`
- [ ] No commits are silently dropped — all 8 appear in a section

---

### Case 4: Existing CHANGELOG.md — New entry at the top, old entries preserved

**Fixture:**
- `docs/CHANGELOG.md` already exists with sections for `v0.2.0` and `v0.3.0`
- New Game commits exist since the `v0.3.0` tag

**Input:** `/changelog`

**Expected behavior:**
1. Skill compiles new entries for the period since `v0.3.0`
2. Before asking, skill checks whether `docs/CHANGELOG.md` exists — it does, so
   it recommends [A] append
3. Skill asks "May I write this changelog to `docs/CHANGELOG.md`?" with
   [A] append (recommended), [B] overwrite, [C] no
4. User selects [A]; the new entry is placed at the top of the file (newest
   first); the `v0.2.0` and `v0.3.0` sections are intact; verdict CHANGELOG WRITTEN

**Assertions:**
- [ ] Skill checks whether `docs/CHANGELOG.md` exists before asking, and recommends [A] append because it does
- [ ] The prompt offers append, overwrite and decline as distinct options
- [ ] On [A], the new entry is placed at the top of the file (newest first), not at the bottom and not replacing the file
- [ ] Existing `v0.2.0` and `v0.3.0` entries are preserved in the written file

---

### Case 5: Gate Compliance — No gate; declined write ends COMPLETE

**Fixture:**
- Git history has Game commits since the last tag
- `project.yaml` sets `modes.review_mode: full`

**Input:** `/changelog`

**Expected behavior:**
1. Skill compiles both changelogs; no director gate is spawned (the skill
   resolves only `automation`, never `review_mode`)
2. Skill goes straight from presenting the changelogs to the write prompt
3. User selects [C] No — I'll copy it manually
4. Skill stops without writing; verdict COMPLETE

**Assertions:**
- [ ] No director gate is invoked regardless of review mode
- [ ] Output does not reference any gate result
- [ ] Skill proceeds directly from presenting the changelogs to the "May I write" prompt
- [ ] On [C], no file is written and the verdict is COMPLETE, not CHANGELOG WRITTEN

---

### Case 6: Provenance Stop — Zero Game commits

**Fixture:**
- The 30 injected commits all touch the framework or tooling — subjects such as
  "fix: session-start hook timeout", "docs: skill catalog", "ci: cache the test
  runner" — and none names a game system in `design/` or the code root
- `docs/CHANGELOG.md` does not exist

**Input:** `/changelog`

**Expected behavior:**
1. Skill classifies every injected commit: 0 Game, 30 Framework / maintenance
2. Skill stops with "The git history in this repo does not appear to belong to
   [game] …", describing what the commits actually cover
3. No changelog is generated and nothing is written; verdict BLOCKED

**Assertions:**
- [ ] Output names the classification result — 0 of 30 commits are Game commits
- [ ] Output contains the "does not appear to belong to" stop, not a changelog built from framework commits (no "Fixed an issue where …" copy from a hook fix)
- [ ] No "May I write" prompt appears and no file is written
- [ ] Verdict is BLOCKED — not COMPLETE and not CHANGELOG WRITTEN

---

### Case 7: No History — Not a git repository

**Fixture:**
- The project directory is not a git repository, so both injected history
  blocks are empty
- `docs/CHANGELOG.md` does not exist

**Input:** `/changelog`

**Expected behavior:**
1. The injected commit list is empty, so the provenance check is skipped —
   there is nothing to classify
2. Phase 1's `git rev-parse --is-inside-work-tree` fails; skill outputs "No git
   history found. A changelog is built from commits …"
3. Nothing is generated or written; verdict BLOCKED

**Assertions:**
- [ ] The "does not appear to belong to" provenance stop is NOT shown — an empty history is not a wrong history
- [ ] Output says no git history was found and offers committing the work or supplying the change list directly
- [ ] No changelog is generated, no "May I write" prompt appears, and no file is written
- [ ] Verdict is BLOCKED

---

## Protocol Compliance

- [ ] Classifies the injected commits as Game or Framework / maintenance and uses only Game commits
- [ ] Reads the git log and the sprint plans in `production/sprints/` before compiling
- [ ] Always asks "May I write" before writing the changelog
- [ ] No director gates are invoked
- [ ] Verdict is CHANGELOG WRITTEN after a write, COMPLETE when the write is declined, and BLOCKED when there is no history or no Game commit
- [ ] Declares `model: sonnet` — it writes player-facing copy

---

## Coverage Notes

- A git repository with no commits yet (the same Phase 1 stop as Case 7) is not
  separately tested.
- More than 100 commits with no tag (the skill says so and asks for a start ref
  instead of widening the range) is not tested.
- Merge commits vs. squash commits are not explicitly differentiated in
  these tests; implementation detail of the git log parsing phase.
- The `/patch-notes` skill should be run after `/changelog` for player-facing
  output; that handoff is verified in the patch-notes spec.
