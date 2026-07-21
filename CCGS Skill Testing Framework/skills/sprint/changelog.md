# Skill Test Spec: $changelog

## Skill Summary

`$changelog` is a read-only skill that auto-generates a developer-facing
changelog by reading git commit history and closed sprint stories since the
last release tag. It organizes entries into features, fixes, and known issues.
No director gates are used. The skill asks "May I write to `docs/CHANGELOG.md`?"
before persisting. Verdict is always COMPLETE.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" language (skill writes changelog)
- [ ] Has a next-step handoff (e.g., run $patch-notes for player-facing version)

---

## Director Gate Checks

None. Changelog generation is a fast compilation task; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — Multiple sprints since last release tag

**Fixture:**
- Git history has a tag `v0.3.0` three sprints ago
- Since that tag: 12 commits across sprints 006, 007, 008
- Sprint story files reference task IDs matching commit messages
- `docs/CHANGELOG.md` does not yet exist

**Input:** `$changelog`

**Expected behavior:**
1. Skill reads git log since `v0.3.0` tag
2. Skill reads sprint stories to cross-reference task IDs
3. Skill compiles entries into Features, Fixes, and Known Issues sections
4. Skill presents draft to user
5. Skill asks "May I write to `docs/CHANGELOG.md`?"
6. User approves; file written; verdict COMPLETE

**Assertions:**
- [ ] Changelog covers commits since the most recent git tag
- [ ] Entries are organized into Features / Fixes / Known Issues sections
- [ ] Sprint story references are used to enrich commit descriptions
- [ ] "May I write" prompt appears before file write
- [ ] Verdict is COMPLETE after write

---

### Case 2: No Git Tags Found — All commits used, version baseline noted

**Fixture:**
- Git repository has commits but no tags exist
- 20 commits in history across 3 sprints

**Input:** `$changelog`

**Expected behavior:**
1. Skill checks for git tags — finds none
2. Skill uses all commits in history as the baseline
3. Skill notes in the output: "No version tag found — using full commit history; version baseline is unset"
4. Skill still compiles organized changelog from available commits
5. Skill asks "May I write" and writes on approval

**Assertions:**
- [ ] Skill does not error when no git tags exist
- [ ] Output explicitly notes that no version baseline was found
- [ ] Full commit history is used as the source
- [ ] Changelog is still organized into sections despite missing tag

---

### Case 3: Commit Messages Without Task IDs — Grouped by date with note

**Fixture:**
- Git log since last tag has 8 commits
- 5 commits have no task ID in the message (e.g., "fix typo", "tweak values")
- 3 commits reference task IDs matching sprint stories

**Input:** `$changelog`

**Expected behavior:**
1. Skill reads commits and sprint stories
2. 3 commits are matched to sprint stories and placed in appropriate sections
3. 5 untagged commits are grouped by date under a "Misc" or "Other Changes" section
4. Output notes: "5 commits without task IDs — grouped by date"
5. Skill writes changelog on approval

**Assertions:**
- [ ] Commits with task IDs are placed in appropriate sections (Features or Fixes)
- [ ] Commits without task IDs are grouped separately with a note
- [ ] Output flags the number of commits missing task references
- [ ] No commits are silently dropped from the changelog

---

### Case 4: Existing CHANGELOG.md — New section prepended, old entries preserved

**Fixture:**
- `docs/CHANGELOG.md` already exists with sections for `v0.2.0` and `v0.3.0`
- New commits exist since `v0.3.0` tag

**Input:** `$changelog`

**Expected behavior:**
1. Skill detects that `docs/CHANGELOG.md` already exists
2. Skill compiles new entries for the period since `v0.3.0`
3. Skill presents draft with new section prepended above existing content
4. Skill asks "May I write to `docs/CHANGELOG.md`?" (confirming prepend strategy)
5. User approves; new content is prepended, old entries intact; verdict COMPLETE

**Assertions:**
- [ ] Skill reads existing changelog before writing to detect prior content
- [ ] New section is prepended (not appended or overwriting) existing entries
- [ ] Old changelog entries for v0.2.0 and v0.3.0 are preserved in the written file
- [ ] "May I write" prompt reflects the prepend operation

---

### Case 5: Gate Compliance — No gate; read-then-write with approval

**Fixture:**
- Git history has commits since last tag
- `review-mode.txt` contains `full`

**Input:** `$changelog`

**Expected behavior:**
1. Skill compiles changelog in full mode
2. No director gate is invoked (changelog generation is compilation, not a delivery gate)
3. Skill produces the requested changelog without relying on fixed model routing
4. Skill asks user for approval and writes file on confirmation

**Assertions:**
- [ ] No director gate is invoked regardless of review mode
- [ ] Output does not reference any gate result
- [ ] Skill proceeds directly from compilation to "May I write" prompt
- [ ] Verdict is COMPLETE

---

## Protocol Compliance

- [ ] Reads git log and sprint story files before compiling
- [ ] Always asks "May I write" before writing changelog
- [ ] No director gates are invoked
- [ ] Verdict is always COMPLETE
- [ ] Is documented as read-only and lightweight

---

## Coverage Notes

- The case where git is not initialized in the repository is not tested;
  behavior would depend on git command failure handling.
- Merge commits vs. squash commits are not explicitly differentiated in
  these tests; implementation detail of the git log parsing phase.
- The `$patch-notes` skill should be run after `$changelog` for player-facing
  output; that handoff is verified in the patch-notes spec.
