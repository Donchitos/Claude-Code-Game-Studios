# Agent Test Spec: community-manager

## Agent Summary
- **Domain**: Player-facing communications — patch notes text (player-friendly), social media post drafts, community update announcements, crisis communication response plans, bug triage and routing from player reports (not fixing)
- **Does NOT own**: Technical patch content (devops-engineer), QA verification and test execution (qa-lead), bug fixes (programmers), brand strategy direction (creative-director)
- **Model tier**: Sonnet
- **Gate IDs**: None; escalates brand voice conflicts to creative-director

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references player communication, patch notes, community management)
- [ ] `allowed-tools:` list matches the agent's role (Read/Write for production/releases/patch-notes/ and communication drafts; no code or build tools)
- [ ] Model tier is `haiku` (agent frontmatter sets haiku; coordination-rules.md assigns Haiku to read-and-format roles)
- [ ] Agent definition does not claim authority over technical content, QA strategy, or bug fixing

---

## Test Cases

### Case 1: In-domain request — patch notes for a bug fix
**Input**: "Write player-facing patch notes for this fix: 'JIRA-4821: Fixed NullReferenceException in InventoryManager.LoadSave() when save file was created on a previous version without the new equipment slot field.'"
**Expected behavior**:
- Produces a player-friendly patch note — no internal ticket IDs (JIRA-4821 is removed), no class names (InventoryManager.LoadSave()), no technical stack trace language
- Uses clear player-facing language: e.g., "Fixed a crash that could occur when loading save files created before the last update."
- Conveys the user impact (game crashed on load) without exposing internal implementation details
- Output is formatted for the project's patch notes style (bullet, or numbered, depending on established format)

### Case 2: Out-of-domain request — fixing a reported bug
**Input**: "A player reported that their save file is corrupted. Can you fix the save system?"
**Expected behavior**:
- Does not produce any code or attempt to diagnose the save system implementation
- Triages the report: acknowledges it as a potential bug affecting player data (high severity)
- Routes it: "This requires investigation by the appropriate programmer; I'm routing this to [gameplay-programmer or lead-programmer] for technical triage"
- Optionally drafts a player-facing acknowledgment post ("We're aware of reports of save corruption and are investigating") if requested

### Case 3: Community crisis — backlash over a game change
**Input**: "Players are angry about our latest patch. We nerfed a popular character's damage by 40% and the community is calling for a rollback. Forum posts, tweets, and Discord are all very negative."
**Expected behavior**:
- Produces a crisis communication response plan (not just a single tweet)
- Plan includes: (1) immediate acknowledgment post — acknowledge the feedback without being defensive; (2) timeline for developer response — commit to a specific timeframe for a design team statement; (3) developer statement template — explain the reasoning behind the nerf without dismissing player concerns; (4) follow-up structure — if rollback or adjustment is planned, communicate it with a timeline
- Does NOT commit to a rollback on behalf of the design team — flags this as a creative-director decision
- Tone is empathetic but not apologetic for intentional design decisions

### Case 4: Brand voice conflict in patch notes
**Input**: "Here is our patch note draft: 'We have annihilated the egregious framerate catastrophe that plagued the loading screen.' Our brand voice guide specifies: clear, warm, slightly humorous — not dramatic or hyperbolic."
**Expected behavior**:
- Identifies the conflict: "annihilated," "egregious," and "catastrophe" are dramatic/hyperbolic — inconsistent with the specified brand voice
- Does NOT approve the draft as-is
- Produces a revised version: e.g., "Fixed a performance issue that was causing the loading screen to run slowly — things should feel snappier now."
- Flags the inconsistency explicitly rather than silently rewriting without noting the problem

### Case 5: Context pass — using a brand voice document
**Input context**: Brand voice guide specifies: direct language, second-person ("you"), light humor is encouraged, avoid corporate jargon, game-specific slang from the in-world glossary is appropriate.
**Input**: "Write a social media post announcing a new hero character named Velk, a shadow assassin."
**Expected behavior**:
- Uses second-person address ("Meet your next favorite assassin")
- Incorporates light humor if it fits naturally
- Avoids corporate language ("We are pleased to announce" → "Meet Velk")
- Uses in-world language if the context includes a glossary (e.g., if assassins are called "Shadowwalkers" in-world, uses that term)
- Output matches the specified tone — not a generic press-release announcement

---

## Protocol Compliance

- [ ] Stays within declared domain (player-facing communication, patch note text, crisis response, bug routing)
- [ ] Strips internal IDs, class names, and technical jargon from all player-facing output
- [ ] Redirects bug fix requests to appropriate programmers rather than attempting technical solutions
- [ ] Does NOT commit to design rollbacks without creative-director authority
- [ ] Applies brand voice specifications from context; flags violations rather than silently accepting them

---

## Coverage Notes
- Case 1 (patch note sanitization) is the most frequently used behavior — test on every new patch cycle
- Case 3 (crisis communication) is a brand-safety test — verify the agent de-escalates rather than inflames
- Case 4 requires a brand voice document to be in context; test is incomplete without it
- Case 5 is the most important context-awareness test for tone consistency
- No automated runner; review manually or via `/skill-test`
