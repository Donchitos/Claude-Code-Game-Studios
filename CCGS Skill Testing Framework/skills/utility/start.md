# Skill Test Spec: $start

## Skill Summary

`$start` is the first-time onboarding skill for new projects. It guides the
user through naming the project, choosing a game engine, and setting up the
initial directory structure. It creates stub configuration files (AGENTS.md,
technical-preferences.md) and then routes to `$setup-engine` with the chosen
engine as an argument. Each file or directory created is gated behind a
"May I write" ask, following the collaborative protocol.

The skill detects whether a project is already configured and whether a
partial setup exists, offering to resume or restart as appropriate. It has
no director gates — it is a utility setup skill that runs before any agent
hierarchy exists.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I write" collaborative protocol language for each config file
- [ ] Has a next-step handoff at the end (routes to `$setup-engine`)

---

## Director Gate Checks

None. `$start` is a utility setup skill. No director agents exist yet at the
point this skill runs.

---

## Test Cases

### Case 1: Happy Path — Fresh repo, no engine, full onboarding flow

**Fixture:**
- Empty repository: no AGENTS.md overrides, no `production/stage.txt`, no
  `technical-preferences.md` content beyond placeholders
- No existing design docs or source code

**Input:** `$start`

**Expected behavior:**
1. Skill detects no existing configuration and begins fresh onboarding
2. Skill asks for project name
3. Skill presents 3 engine options: Godot 4, Unity, Unreal Engine 5
4. User selects an engine
5. Skill asks "May I write the initial directory structure?"
6. Skill creates all directories defined in `directory-structure.md`
7. Skill asks "May I write AGENTS.md stub?" and writes it on approval
8. Skill routes to `$setup-engine [chosen-engine]` to complete technical config

**Assertions:**
- [ ] Project name is captured before any file is written
- [ ] Exactly 3 engine options are presented
- [ ] "May I write" is asked for each config file individually
- [ ] No file is written without explicit user approval
- [ ] Handoff to `$setup-engine` occurs at the end with the chosen engine argument
- [ ] Verdict is COMPLETE after all files are written and handoff is issued

---

### Case 2: Already Configured — Detects existing config, offers to skip or reconfigure

**Fixture:**
- `technical-preferences.md` has engine already set (not placeholder)
- `production/stage.txt` exists with `Concept`

**Input:** `$start`

**Expected behavior:**
1. Skill reads `technical-preferences.md` and detects configured engine
2. Skill reports: "This project is already configured with [engine]"
3. Skill presents options: skip (exit), reconfigure engine, or reconfigure specific sections
4. If user selects skip: skill exits cleanly with a summary of current config
5. If user selects reconfigure: skill proceeds to the engine-selection step

**Assertions:**
- [ ] Skill does NOT overwrite existing config without user choosing reconfigure
- [ ] Detected engine name is shown to the user in the status message
- [ ] User is offered at least 2 options (skip or reconfigure)
- [ ] Verdict is COMPLETE whether user skips or reconfigures

---

### Case 3: Engine Choice — User picks Godot 4, routes to $setup-engine godot

**Fixture:**
- Fresh repo — no existing configuration

**Input:** `$start`

**Expected behavior:**
1. Skill presents engine options and user selects Godot 4
2. Skill writes initial stubs (directory structure, AGENTS.md) after approval
3. Skill explicitly routes to `$setup-engine godot` as the next step
4. Handoff message clearly names the engine and the next skill invocation

**Assertions:**
- [ ] Handoff command is `$setup-engine godot` (not generic `$setup-engine`)
- [ ] Handoff is issued after all initial stubs are written, not before
- [ ] Engine choice is echoed back to user before writing begins

---

### Case 4: Interrupted Setup — Partial config detected, offers resume or restart

**Fixture:**
- Directory structure exists (was created) but `technical-preferences.md` is
  still all placeholders (engine was never chosen — setup was interrupted)
- No `production/stage.txt`

**Input:** `$start`

**Expected behavior:**
1. Skill detects partial state: directories exist but engine is unconfigured
2. Skill reports: "A partial setup was detected — directories exist but engine is not configured"
3. Skill offers: resume from engine selection, or restart from scratch
4. If resume: skill skips directory creation, proceeds to engine choice
5. If restart: skill asks "May I overwrite existing structure?" before proceeding

**Assertions:**
- [ ] Partial state is correctly identified (directories present, engine absent)
- [ ] User is offered resume vs. restart choice — not forced into one path
- [ ] Resume path skips re-creating directories (no redundant "May I write" for structure)
- [ ] Restart path asks for permission to overwrite before touching any files

---

### Case 5: Director Gate Check — No gate; start is a utility setup skill

**Fixture:**
- Any fixture

**Input:** `$start`

**Expected behavior:**
1. Skill completes full onboarding flow
2. No director agents are spawned at any point
3. No gate IDs (CD-*, TD-*, AD-*, PR-*) appear in the output

**Assertions:**
- [ ] No director gate is invoked during the skill execution
- [ ] No gate skip messages appear (gates are absent, not suppressed)
- [ ] Skill reaches COMPLETE without any gate verdict

---

## Protocol Compliance

- [ ] Asks for project name before any file is written
- [ ] Presents engine options as a structured choice (not free text)
- [ ] Asks "May I write" separately for directory structure and for AGENTS.md stub
- [ ] Ends with a handoff to `$setup-engine` with the engine name as argument
- [ ] Verdict is clearly stated (COMPLETE or BLOCKED) at end of output

---

## Coverage Notes

- The case where the user rejects all engine options and provides a custom
  engine name is not tested — the skill is designed for the three supported
  engines only.
- Git initialization (if any) is not tested here; that is an infrastructure
  concern outside the skill boundary.
- Solo vs. lean mode behavior is not applicable — this skill has no gates and
  mode selection is irrelevant.
