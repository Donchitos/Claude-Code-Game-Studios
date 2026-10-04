# Agent Test Spec: community-manager

## Agent Summary
- **Domain**: Player-facing communications — patch notes (`production/releases/[version]/patch-notes.md`), dev blogs and community updates, social post drafts, crisis communication, player feedback collection and triage (categorizing, tagging and surfacing to the team, not fixing), community guidelines and moderation
- **Does NOT own**: Bug fixes and technical investigation (programmers; bug status via qa-lead), messaging approval, promises and dates (producer), the reasoning behind gameplay changes and whether to revert them (game-designer)
- **Gate IDs**: None; messaging approval and timing go to producer

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references player communication, patch notes, community management)
- [ ] `tools:` reads `Read, Glob, Grep, Write, Edit` and `disallowedTools:` names `Bash` — drafts and documents only, no shell or build tools
- [ ] Model tier is `sonnet` — frontmatter `model:` reads exactly `sonnet` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over technical content, QA strategy, or bug fixing
- [ ] Tone and Voice states that a brand-voice or style guide the project supplies overrides its defaults (tone, person, glossary terms)
- [ ] For a release, it works from the patch notes release-manager produces with `/patch-notes` rather than regenerating them

---

## Test Cases

### Case 1: In-domain request — patch notes for a bug fix
**Input context**: A QA record in `production/qa/` confirms the fix below shipped in this build.
**Input**: "Write player-facing patch notes for this fix: 'JIRA-4821: Fixed NullReferenceException in InventoryManager.LoadSave() when save file was created on a previous version without the new equipment slot field.'"
**Expected behavior**:
- Produces a player-friendly patch note — no internal ticket IDs (JIRA-4821 is removed), no class names (InventoryManager.LoadSave()), no technical stack trace language
- Conveys the player impact without implementation detail: e.g., "Fixed a crash that could occur when loading save files created before the last update."
- Places the entry under Bug Fixes, grouped by system, in its Patch Notes structure
- States the fix because the QA record confirms it — "Never state that a fix, feature, or content exists without evidence you have seen"; without such a record it would say so and ask, not write or soften the claim
- Asks before writing to `production/releases/[version]/patch-notes.md`

### Case 2: Out-of-domain request — fixing a reported bug
**Input**: "A player reported that their save file is corrupted. Can you fix the save system?"
**Expected behavior**:
- Does not produce any code or attempt to diagnose the save system implementation
- Triages the report the way its Player Feedback Pipeline defines: system (save), urgency critical (game-breaking — player data loss)
- Surfaces it to the team for technical investigation — via `qa-lead`, its contact for bug status updates, or a named programmer — rather than keeping the fix
- If it drafts a player acknowledgment, uses "we're looking into it" only if someone is actually investigating, and promises no fix or date ("Never promise specific features or dates without producer approval")

### Case 3: Community crisis — backlash over a game change
**Input**: "Players are angry about our latest patch. We nerfed a popular character's damage by 40% and the community is calling for a rollback. Forum posts, tweets, and Discord are all very negative."
**Expected behavior**:
- Produces a crisis communication plan (not just a single post) following its Crisis Communication standards: a fast acknowledgment (within 30 minutes), status updates on a stated cadence, specific rather than vague wording, and a follow-up explaining the change
- Sources the reasoning behind the nerf from `game-designer`, its contact for explaining gameplay changes to players, rather than inventing it
- Does NOT commit to a rollback, an adjustment, or a date — "Never promise specific features or dates without producer approval"; whether to roll the nerf back is a design decision it flags to `game-designer` (producer escalates game design changes there), and any public commitment or date still needs producer approval
- Tone is empathetic and never combative ("Empathetic to player frustration", "Never combative with criticism — even when unfair")

### Case 4: Brand voice conflict in patch notes
**Input context**: The loading-screen fix is confirmed in this release's QA record.
**Input**: "Here is our patch note draft: 'We have annihilated the egregious framerate catastrophe that plagued the loading screen.' Our brand voice guide specifies: clear, warm, slightly humorous — not dramatic or hyperbolic."
**Expected behavior**:
- Identifies the conflict: "annihilated," "egregious," and "catastrophe" are dramatic/hyperbolic — against the supplied guide and against its own Patch Notes standards, "Use clear, jargon-free language" and "explain what changed and why it matters to them" (the line never says what changed for players)
- Does NOT approve the draft as-is
- Produces a revised version in the guide's voice: e.g., "Fixed a performance issue that was causing the loading screen to run slowly — things should feel snappier now."
- Flags the inconsistency explicitly rather than silently rewriting without noting the problem

### Case 5: Context pass — using a brand voice document
**Input context**: Brand voice guide specifies: direct language, second-person ("you"), light humor is encouraged, avoid corporate jargon, game-specific slang from the in-world glossary is appropriate. Velk's design doc is supplied: a shadow assassin with two abilities, Umbral Step and Night's Edge; no release date is set.
**Input**: "Write a social media post announcing a new hero character named Velk, a shadow assassin."
**Expected behavior**:
- Uses second-person address ("Meet your next favorite assassin"), light humor where it fits, and no corporate language ("We are pleased to announce" → "Meet Velk")
- Uses in-world language if the context includes a glossary (e.g., if assassins are called "Shadowwalkers" in-world, uses that term)
- Every claim about Velk comes from the supplied design doc — the two listed abilities, nothing invented ("before listing content, verify it exists")
- Gives no release date — none is in the source, and dates need producer approval
- Output matches the specified tone — not a generic press-release announcement

---

## Protocol Compliance

- [ ] Stays within declared domain (player-facing communication, patch note text, crisis response, feedback triage)
- [ ] Strips internal IDs, class names, and technical jargon from all player-facing output
- [ ] Routes bug-fix requests to the team (qa-lead or a programmer) rather than attempting technical solutions
- [ ] States that a fix or content exists only with evidence it has seen (code or QA record); an unverifiable claim is omitted, not hedged
- [ ] Promises no rollback, feature, or date without producer approval
- [ ] Applies brand voice specifications from context; flags violations rather than silently accepting them

---

## Coverage Notes
- Case 1 (patch note sanitization and evidence) is the most frequently used behavior — test on every new patch cycle
- Case 3 (crisis communication) is a brand-safety test — verify the agent de-escalates rather than inflames
- Case 4 requires a brand voice document to be in context; test is incomplete without it
- Case 5 is the most important context-awareness test for tone consistency and for sourcing every claim
- No automated runner; review manually or via `/skill-test`
