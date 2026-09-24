---
name: patch-notes
description: "Player-facing patch notes from git history and changelogs. Translates developer language into player communication."
argument-hint: "[version] [--style brief|detailed|full]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, Bash(bash "*/.claude/skills/patch-notes/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

## Provenance check — before reading any history

**Confirm the history you are about to read belongs to THIS game.** Run this
before Phase 2 and stop if it fails.

1. Sample the recent log: `git log --oneline -20`.
2. **Classify every commit in the range, one at a time**, into exactly one of:
   - **Game** — changes the game the player plays: mechanics, content, balance,
     art, audio, UI, a bug in any of those.
   - **Framework / maintenance** — changes CCGS itself or the project's tooling:
     subjects naming skills, hooks, agents, the test plan, CI, the framework's
     own docs. **Excluded from player-facing notes, but not a reason to stop.**
   - **Unclear** — treat as framework. A commit you cannot confidently place is
     not one to write player copy from.
3. Then decide from the counts:
   - **At least one Game commit** → proceed, using **only** those. Say how many
     of how many you used, so the reader can see the filter ran.
   - **Zero Game commits** → stop, using the message below.

> **Filter per commit; do not stop on a repo that merely contains maintenance
> work.** Every project built on this framework accumulates commits touching
> hooks, CI and skills — the game repo *is* the framework repo. An earlier
> version of this check listed "subjects naming the framework, its skills, hooks,
> agents or test plan" as a hard STOP, which fires on virtually every real
> project and contradicted its own step 2 whenever a history was mostly the
> game's. The danger was never that such commits *exist*; it is that they get
> **rendered as player-facing copy**. Excluding them addresses that exactly, and
> a repo-level stop does not.

Corroborate before you proceed, cheaply: the Game commits should name systems
that appear in `design/` and `src/`. If they name a product those directories
never mention, that is the real wrong-history signal — stop.

If **no** commit in the range is this game's, say so and stop:

> "The git history in this repo does not appear to belong to [game]. The recent
> commits describe [what they actually describe]. I cannot generate release notes
> from it — point me at the right history, or supply the change list directly."

**Why this is a hard stop, not a warning.** This exact failure is real, not
hypothetical: a batch of framework-internal commits produced player-facing copy
reading *"Fixed an issue where progress from your last session could be lost on launch"*
— a session-hook timeout rendered as a gameplay fix for a game with **no save
system**. It was fluent, plausible, and entirely false. A reader cannot tell the
difference; only this check can.

---

## Phase 1: Parse Arguments

- `version`: the release version to generate notes for (e.g., `1.2.0`)
- `--style`: output style — `brief` (bullet points), `detailed` (with context), `full` (with developer commentary). Default: `detailed`.

If no version is provided, ask the user before proceeding.

---

## Phase 2: Gather Change Data

- Read the internal changelog at `production/releases/[version]/changelog.md` if it exists
- Also check `docs/CHANGELOG.md` for the relevant version entry
- Run `git log` between the previous release tag and current tag/HEAD as a fallback
- Read sprint retrospectives in `production/sprints/` for context
- Read any balance change documents in `design/balance/`
- Read bug fix records from QA if available

**If no changelog data is available** (neither `production/releases/[version]/changelog.md`
nor a `docs/CHANGELOG.md` entry for this version exists, and git log is empty or unavailable):

> "No changelog data found for [version]. Run `/changelog [version]` first to generate the
> internal changelog, then re-run `/patch-notes [version]`."

Verdict: **BLOCKED** — stop here without generating notes.

---

## Phase 2b: Detect Tone Guide and Template

**Tone guide detection** — before drafting notes, check for writing style guidance:

1. Check `.claude/docs/technical-preferences.md` for any "tone", "voice", or "style"
   fields or sections.
2. Check `docs/PATCH-NOTES-STYLE.md` if it exists.
3. Check `design/community/tone-guide.md` if it exists.
4. If any source contains tone/voice/style instructions, extract them and apply
   them to the language and framing of the generated notes.
5. If no tone guidance is found anywhere, default to:
   player-friendly, non-technical language; enthusiastic but not hyperbolic;
   focus on what the player experiences, not what the developer changed.

**Template detection** — check whether a patch notes template exists:

1. Glob for `docs/patch-notes-template.md` and `.claude/docs/templates/patch-notes-template.md`.
2. If found at either location, read it and use it as the output structure for Phase 4
   instead of the built-in style templates (Brief / Detailed / Full). Fill in the
   template's sections with the categorized data.
3. If not found, use the built-in style templates as defined in Phase 4.

---

## Phase 3: Categorize and Translate

Categorize all changes into player-facing categories:

- **New Content**: new features, maps, characters, items, modes
- **Gameplay Changes**: balance adjustments, mechanic changes, progression changes
- **Quality of Life**: UI improvements, convenience features, accessibility
- **Bug Fixes**: grouped by system (combat, UI, networking, etc.)
- **Performance**: optimization improvements players might notice
- **Known Issues**: transparency about unresolved problems

Translate developer language to player language:

- "Refactored damage calculation pipeline" → "Improved hit detection accuracy"
- "Fixed null reference in inventory manager" → "Fixed a crash when opening inventory"
- "Reduced GC allocations in combat loop" → "Improved combat performance"
- Remove purely internal changes that don't affect players
- Preserve specific numbers for balance changes (damage: 50 → 45)

---

## Phase 4: Generate Patch Notes

### Brief Style
```markdown
# Patch [Version] — [Title]

**New**
- [Feature 1]
- [Feature 2]

**Changes**
- [Balance/mechanic change with before → after values]

**Fixes**
- [Bug fix 1]
- [Bug fix 2]

**Known Issues**
- [Issue 1]
```

### Detailed Style
```markdown
# Patch [Version] — [Title]
*[Date]*

## Highlights
[1-2 sentence summary of the most exciting changes]

## New Content
### [Feature Name]
[2-3 sentences describing the feature and why players should be excited]

## Gameplay Changes
### Balance
| Change | Before | After | Reason |
| ---- | ---- | ---- | ---- |
| [Item/ability] | [old value] | [new value] | [brief rationale] |

### Mechanics
- **[Change]**: [explanation of what changed and why]

## Quality of Life
- [Improvement with context]

## Bug Fixes
### Combat
- Fixed [description of what players experienced]

### UI
- Fixed [description]

### Networking
- Fixed [description]

## Performance
- [Improvement players will notice]

## Known Issues
- [Issue and workaround if available]
```

### Full Style
Includes everything from Detailed, plus:
```markdown
## Developer Commentary
### [Topic]
> [Developer insight into a major change — why it was made, what was considered,
> what the team learned. Written in first-person team voice.]
```

---

## Phase 5: Review Output

Check the generated notes for:

- No internal jargon (replace technical terms with player-friendly language)
- No references to internal systems, tickets, or sprint numbers
- Balance changes include before/after values
- Bug fixes describe the player experience, not the technical cause
- Tone matches the game's voice (adjust formality based on game style)

---

## Phase 6: Save Patch Notes

Present the completed patch notes to the user along with: a count of changes by category, and any internal changes that were excluded (for review).

Ask: "May I write these patch notes to `docs/patch-notes/[version].md`?"

If yes, write the file to `docs/patch-notes/[version].md`, creating the directory
if needed. Also write to `production/releases/[version]/patch-notes.md` as the
internal archive copy.

---

## Phase 7: Next Steps

Verdict: **COMPLETE** — patch notes generated and saved.

- Run `/release-checklist` to verify all other release gates are met before publishing.
- Share the patch notes draft with the community-manager for tone review before posting publicly.
