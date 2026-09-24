---
name: changelog
description: "Auto-generate a changelog from git commits and sprint data. Internal and player-facing versions."
argument-hint: "[version|sprint-number]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Bash(bash "*/.claude/skills/changelog/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

## Recent History

Recent commits:

!`git log --oneline -30 2>/dev/null || true`

Recent tags (newest first):

!`git tag --list --sort=-v:refname 2>/dev/null | head -5`

## Provenance check — before trusting the history above

**The commits above may not belong to this game.** This skill's history blocks are
auto-resolved *before* the body runs, so the read has already happened — what this
check governs is whether that output is usable, not whether it is fetched.

1. Read the injected commit subjects above.
2. **Classify each one** as **Game** (mechanics, content, balance, art, audio,
   UI, or a bug in those), **Framework / maintenance** (subjects naming skills,
   hooks, agents, the test plan, CI, or the framework's own docs), or **Unclear**
   — and treat Unclear as Framework.
3. Decide from the counts:
   - **At least one Game commit** → proceed using only those, and state how many
     of how many you used.
   - **Zero Game commits** → stop, using the message below.

> **Filter per commit; a repo containing maintenance work is not a wrong repo.**
> Every project on this framework accumulates commits touching hooks, CI and
> skills — the game repo *is* the framework repo. Listing those as a hard STOP
> fires on virtually every real project and contradicts step 2 whenever the
> history is mostly the game's. The harm is those commits becoming release copy,
> and excluding them prevents that precisely.
>
> This rule is kept identical to `/patch-notes`' on purpose — the two read the
> same history for different audiences, and they must not disagree about whose
> history it is. Change both together.

The genuine wrong-history signal is different: Game commits naming a product that
`design/` and `src/` never mention. If you see that, stop.

If **no** commit in the range is this game's, say so and stop:

> "The git history in this repo does not appear to belong to [game]. The recent
> commits describe [what they actually describe]. I cannot generate a changelog
> from it — point me at the right history, or supply the change list directly."

**Why this is a hard stop, not a warning.** This exact failure is real, not
hypothetical: a batch of framework-internal commits produced player-facing copy
reading *"Fixed an issue where progress from your last session could be lost on
launch"* — a
session-hook timeout rendered as a gameplay fix for a game with **no save
system**. It was fluent, plausible, and entirely false. A reader cannot tell the
difference; only this check can.

**Do not treat the preamble's existence as evidence.** Injected output means the
command ran, never that its subject is your game.

---

Both blocks are resolved before this skill runs. Use them as the starting point
for Phase 2 rather than re-running the same commands.

---

## Phase 1: Parse Arguments

Read the argument for the target version or sprint number. If a version is given, use the corresponding git tag. If a sprint number is given, use the sprint date range.

Verify the repository is initialized: run `git rev-parse --is-inside-work-tree` to confirm git is available. If not a git repo, inform the user and abort gracefully.

---

## Phase 2: Gather Change Data

Read the git log since the last tag or release:

```
git log --oneline [last-tag]..HEAD
```

If no tags exist, bound the range explicitly — `git log --oneline -n 100`. Do not
fall back to the full log: on an established repo that is thousands of lines for
a changelog covering one release, and the oldest of them are the least relevant.
If 100 commits does not reach far enough back, say so and ask for a start ref
rather than widening blindly.

Read sprint reports from `production/sprints/` for the relevant period to understand planned work and context behind changes.

Read completed design documents from `design/gdd/` for any new features implemented during this period.

---

## Phase 3: Categorize Changes

Categorize every change into one of these categories:

- **New Features**: Entirely new gameplay systems, modes, or content
- **Improvements**: Enhancements to existing features, UX improvements, performance gains
- **Bug Fixes**: Corrections to broken behavior
- **Balance Changes**: Tuning of gameplay values, difficulty, economy
- **Known Issues**: Issues the team is aware of but have not yet resolved
- **Miscellaneous**: Changes that do not fit the above categories, or commits whose messages are too vague to classify confidently

For each commit, check whether the message contains a task ID or story reference
(e.g. `[STORY-123]`, `TR-`, `#NNN`, or similar). Count commits that lack any task reference
and include this count in the Phase 4 Metrics section as: `Commits without task reference: [N]`.

---

## Phase 4: Generate Internal Changelog

```markdown
# Internal Changelog: [Version]
Date: [Date]
Sprint(s): [Sprint numbers covered]
Commits: [Count] ([first-hash]..[last-hash])

## New Features
- [Feature Name] -- [Technical description, affected systems]
  - Commits: [hash1], [hash2]
  - Owner: [who implemented it]
  - Design doc: [link if applicable]

## Improvements
- [Improvement] -- [What changed technically and why]
  - Commits: [hashes]
  - Owner: [who]

## Bug Fixes
- [BUG-ID] [Description of bug and root cause]
  - Fix: [What was changed]
  - Commits: [hashes]
  - Owner: [who]

## Balance Changes
- [What was tuned] -- [Old value -> New value] -- [Design intent]
  - Owner: [who]

## Technical Debt / Refactoring
- [What was cleaned up and why]
  - Commits: [hashes]

## Miscellaneous
- [Change that didn't fit other categories, or vague commit message]
  - Commits: [hashes]

## Known Issues
- [Issue description] -- [Severity] -- [ETA for fix if known]

## Metrics
- Total commits: [N]
- Files changed: [N]
- Lines added: [N]
- Lines removed: [N]
- Commits without task reference: [N]
```

---

## Phase 5: Generate Player-Facing Changelog

```markdown
# What is New in [Version]

## New Features
- **[Feature Name]**: [Player-friendly description of what they can now do
  and why it is exciting. Focus on the experience, not the implementation.]

## Improvements
- **[What improved]**: [How this makes the game better for the player.
  Be specific but avoid jargon.]

## Bug Fixes
- Fixed an issue where [describe what the player experienced, not what was
  wrong in the code]
- Fixed [player-visible symptom]

## Balance Changes
- [What changed in player-understandable terms and the design intent.
  Example: "Healing potions now restore 50 HP (up from 30) -- we felt
  players needed more recovery options in late-game encounters."]

## Known Issues
- We are aware of [issue description in player terms] and are working on a
  fix. [Workaround if one exists.]

---
Thank you for playing! Your feedback helps us make the game better.
Report issues at [link].
```

---

## Phase 6: Output

Output both changelogs to the user. The internal changelog is the primary working document. The player-facing changelog is ready for community posting after review.

---

## Phase 7: Offer File Write

After presenting the changelogs, ask the user:

> "May I write this changelog to `docs/CHANGELOG.md`?
> [A] Yes, append this entry (recommended if the file already exists)
> [B] Yes, overwrite the file entirely
> [C] No — I'll copy it manually"

- Check whether `docs/CHANGELOG.md` exists before asking. If it does, default the
  recommendation to **[A] append**.
- If the user selects [A]: append the new internal changelog entry to the top of
  the existing file (newest entries first).
- If the user selects [B]: overwrite the file with the new changelog.
- If the user selects [C]: stop here without writing.

After a successful write: Verdict: **CHANGELOG WRITTEN** — changelog saved to `docs/CHANGELOG.md`.
If the user declines: Verdict: **COMPLETE** — changelog generated.

---

## Phase 7: Next Steps

- Use `/patch-notes [version]` to generate a styled, saved version for public release.
- Use `/release-checklist` before publishing the changelog externally.

### Guidelines

- Never expose internal code references, file paths, or developer names in the player-facing changelog
- Group related changes together rather than listing individual commits
- If a commit message is unclear, check the associated files and sprint data for context
- Balance changes should always include the design reasoning, not just the numbers
- Known issues should be honest — players appreciate transparency
- If the git history is messy (merge commits, reverts, fixup commits), clean up the narrative rather than listing every commit literally
