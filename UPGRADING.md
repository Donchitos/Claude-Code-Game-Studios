# Upgrading Claude Code Game Studios

This guide covers upgrading your existing game project repo from one version
of the template to the next.

**Find your current version** in your git log:
```bash
git log --oneline | grep -i "release\|setup"
```
Or check `README.md` for the version badge.

---

## Table of Contents

- [Upgrade Strategies](#upgrade-strategies)
- [v1.0.0-beta → v1.0](#v100-beta--v10)
- [v0.4.x → v1.0](#v04x--v10)
- [v0.4.0 → v0.4.1](#v040--v041)
- [v0.3.0 → v0.4.0](#v030--v040)
- [v0.2.0 → v0.3.0](#v020--v030)
- [v0.1.0 → v0.2.0](#v010--v020)

---

## Upgrade Strategies

There are three ways to pull in template updates. Choose based on how your
repo is set up.

### Strategy A — Git Remote Merge (recommended)

Best when: you cloned the template and have your own commits on top of it.

```bash
# Add the template as a remote (one-time setup)
git remote add template https://github.com/Donchitos/Claude-Code-Game-Studios.git

# Fetch the new version
git fetch template main

# Merge into your branch
git merge template/main --allow-unrelated-histories
```

Git will flag conflicts only in files that both the template *and* you have
changed. Resolve each one — your game content goes in, structural improvements
come along for the ride. Then commit the merge.

**Tip:** The files most likely to conflict are `CLAUDE.md` and
`.claude/docs/technical-preferences.md`, because you've filled them in with
your engine and project settings. Keep your content; accept the structural changes.

---

### Strategy B — Cherry-pick specific commits

Best when: you only want one specific feature (e.g., just the new skill, not
the full update).

```bash
git remote add template https://github.com/Donchitos/Claude-Code-Game-Studios.git
git fetch template main

# Cherry-pick the specific commit(s) you want
git cherry-pick <commit-sha>
```

Commit SHAs for each version are listed in the version sections below.

---

### Strategy C — Manual file copy

Best when: you didn't use git to set up the template (just downloaded a zip).

1. Download or clone the new version alongside your repo.
2. Copy the files listed under **"Safe to overwrite"** directly.
3. For files under **"Merge carefully"**, open both versions side-by-side
   and manually merge the structural changes while keeping your content.

---

## v0.4.1

**Released:** 2026-04-02
**Key themes:** Art direction integration, asset specification pipeline

### What Changed

| Category | Changes |
|----------|---------|
| **New skill** | `/art-bible` — guided section-by-section visual identity authoring (9 sections). Mandatory art-director Task spawn per section. AD-ART-BIBLE sign-off gate. Required at Technical Setup phase. |
| **New skill** | `/asset-spec` — per-asset visual spec and AI generation prompt generator. Reads art bible + GDD/level/character docs. Writes `design/assets/specs/` files and `design/assets/asset-manifest.md`. Full/lean/solo modes. |
| **New director gates (3)** | `AD-CONCEPT-VISUAL` (brainstorm Phase 4), `AD-ART-BIBLE` (art bible sign-off), `AD-PHASE-GATE` (gate-check panel) |
| **`/brainstorm` update** | Added `Task` to allowed-tools (was missing — blocked all director spawning). Art-director now spawns in parallel with creative-director after pillars lock. Visual Identity Anchor written to game-concept.md. |
| **`/gate-check` update** | Art-director added as 4th parallel director (AD-PHASE-GATE). Visual artifact checks: Visual Identity Anchor (Concept gate), art bible (Technical Setup gate), AD-ART-BIBLE sign-off + character visual profiles (Pre-Production gate). |
| **`/team-level` update** | Art-director added to Step 1 parallel spawn (visual direction before layout). Level-designer now receives art-director targets as explicit constraints. Step 4 art-director role corrected to production-concepts only. |
| **`/team-narrative` update** | Art-director added to Phase 2 parallel spawn (character visual design, environmental storytelling, cinematic tone). |
| **`/design-system` update** | Routing table expanded with art-director + technical-artist for Combat, UI, Dialogue, Animation/VFX, Character categories. Visual/Audio section now mandatory (with art-director Task spawn) for 7 system categories. |
| **`workflow-catalog.yaml`** | `/art-bible` added to Technical Setup (required). `/asset-spec` added to Pre-Production (optional, repeatable). |

### Files: Safe to Overwrite

**New files to add:**
```
.claude/skills/art-bible/SKILL.md
.claude/skills/asset-spec/SKILL.md
.claude/docs/director-gates.md
```

**Existing files to overwrite (no user content):**
```
.claude/skills/brainstorm/SKILL.md
.claude/skills/gate-check/SKILL.md
.claude/skills/team-level/SKILL.md
.claude/skills/team-narrative/SKILL.md
.claude/skills/design-system/SKILL.md
.claude/docs/workflow-catalog.yaml
README.md
UPGRADING.md
```

### Files: Merge Carefully

None — all changes are to infrastructure files with no user content.

---

## v1.0.0-beta → v1.0

**Released:** 2026-05-13
**Commit range:** `49d1e45..HEAD`
**Key themes:** New `/vertical-slice` gate, skill polish & bug fixes, contributor docs

### What Changed

| Category | Changes |
|----------|---------|
| **New skill** | `/vertical-slice` — Pre-Production gate that validates the full game loop with a production-quality end-to-end build before Production. Pairs with the overhauled `/prototype` (concept validation right after `/brainstorm`). |
| **New flow** | Entity inventory step in `/map-systems` — surfaces all named entities up front for cleaner downstream GDD authoring. |
| **UX polish** | Added missing `AskUserQuestion` widgets to 7 skills; comprehensive skill audit for consistency, prompts, and flow gaps; exposed `--review` flag in `argument-hints` for all `team-*` skills. |
| **Bug fixes** | `#21` log-agent hooks logged "unknown" `agent_type`; `#36` missing `allowed-tools` in `/architecture-decision` and `/story-done`; `#42` `rg --type gdscript` is invalid (now uses `--glob *.gd`); `#43` session-start preview showed oldest state instead of newest; `#45` duplicate `## 0.` heading and broken step numbering in `/architecture-decision`. |
| **Project docs** | Added `CONTRIBUTING.md` (framework contribution guidelines) and `SECURITY.md` (coordinated disclosure policy). |
| **Counts/refs** | Synced agent/skill/hook counts across `WORKFLOW-GUIDE.md`, `README.md`, and agent rosters; fixed stale agent names and skill model-tier fields. |

---

### Files: Safe to Overwrite

**New files to add:**
```
.claude/skills/vertical-slice/SKILL.md
CONTRIBUTING.md
SECURITY.md
```

**Existing files to overwrite (no user content):**
- All files under `.claude/skills/` modified in the commit range (skill audit + AskUserQuestion widgets + `--review` argument-hints)
- `.claude/hooks/log-agent.sh` (fix #21)
- `README.md`, `docs/WORKFLOW-GUIDE.md`, `docs/examples/skill-flow-diagrams.md`
- `UPGRADING.md`

---

### Files: Merge Carefully

None — all changes are to infrastructure files with no user content.

---

## v0.4.x → v1.0

**Released:** 2026-03-29
**Commit range:** `6c041ac..HEAD`
**Key themes:** Director gates system, gate intensity modes, Godot C# specialist

### What Changed

| Category | Changes |
|----------|---------|
| **New system** | Director gates — named review checkpoints shared across all workflow skills. Defined in `.claude/docs/director-gates.md` |
| **New feature** | Gate intensity modes: `full` (all director gates), `lean` (phase gates only), `solo` (no directors). Set globally via `production/review-mode.txt` during `/start`, or override per-run with `--review [mode]` on any gate-using skill |
| **New agent** | `godot-csharp-specialist` — C# code quality in Godot 4 projects |
| **Skill updates (13)** | All gate-using skills now parse `--review [full\|lean\|solo]` and include it in their argument-hint: `brainstorm`, `map-systems`, `design-system`, `architecture-decision`, `create-architecture`, `create-epics`, `create-stories`, `sprint-plan`, `milestone-review`, `playtest-report`, `prototype`, `story-done`, `gate-check` |
| **`/start` update** | Added Phase 3b — sets review mode during onboarding, writes `production/review-mode.txt` |
| **`/setup-engine` update** | Language selection step for Godot (GDScript vs C#) |
| **Docs** | `director-gates.md` — full gate catalog; `WORKFLOW-GUIDE.md` — Director Review Modes section; `README.md` — review intensity customization |

---

### Files: Safe to Overwrite

**New files to add:**
```
.claude/agents/godot-csharp-specialist.md
.claude/docs/director-gates.md
```

**Existing files to overwrite (no user content):**
```
.claude/skills/brainstorm/SKILL.md
.claude/skills/map-systems/SKILL.md
.claude/skills/design-system/SKILL.md
.claude/skills/architecture-decision/SKILL.md
.claude/skills/create-architecture/SKILL.md
.claude/skills/create-epics/SKILL.md
.claude/skills/create-stories/SKILL.md
.claude/skills/sprint-plan/SKILL.md
.claude/skills/milestone-review/SKILL.md
.claude/skills/playtest-report/SKILL.md
.claude/skills/prototype/SKILL.md
.claude/skills/story-done/SKILL.md
.claude/skills/gate-check/SKILL.md
.claude/skills/start/SKILL.md
.claude/skills/quick-design/SKILL.md
.claude/skills/setup-engine/SKILL.md
README.md
docs/WORKFLOW-GUIDE.md
UPGRADING.md
```

---

### Files: Merge Carefully

No files require manual merging in this release. All changes are to infrastructure files with no user content.

---

### New Features

#### Director Gates System

All major workflow skills now reference named gate checkpoints defined in
`.claude/docs/director-gates.md`. Gates are identified by domain prefix and name
(e.g., `CD-CONCEPT`, `TD-ARCHITECTURE`, `LP-CODE-REVIEW`). Each gate defines
which director to spawn, what inputs to pass, what verdicts mean, and how
lean/solo modes affect it.

Skills spawn gates using `Task` with the gate ID and documented inputs, rather
than embedding director prompts inline. This keeps skill bodies clean and makes
gate behavior consistent across all workflow phases.

#### Gate Intensity Modes

Three modes let you control how much director review you get:

- **`full`** (default) — all director gates run at every review checkpoint
- **`lean`** — per-skill director reviews are skipped; phase gates at `/gate-check` still run
- **`solo`** — no director gates anywhere; `/gate-check` checks artifact existence only

Set globally during `/start` (writes `production/review-mode.txt`). Override any
individual run with `--review [mode]` on any gate-using skill:

```
/design-system combat --review lean
/gate-check concept --review full
/brainstorm my-game-idea --review solo
```

---

### After Upgrading

1. Run `/start` once to set your preferred review mode — or create `production/review-mode.txt` manually with `full`, `lean`, or `solo`.
2. If you're mid-project, review `.claude/docs/director-gates.md` to understand which gates apply to your current phase.
3. Run `/skill-test static all` to verify all skills pass structural checks.

---

## v0.4.0 → v0.4.1

**Released:** 2026-03-26
**Commit range:** `04ed5d5..HEAD`
**Key themes:** Genre-agnostic agents, new skills, skill fixes

### What Changed

| Category | Changes |
|----------|---------|
| **New skills (1)** | `/consistency-check` — cross-GDD entity consistency scanner |
| **Skill fixes (all team-*)** | Added no-argument guards, formal `Verdict: COMPLETE / BLOCKED` keywords, per-step AskUserQuestion gates, adjacent area dependency checks (team-level), ethics enforcement (team-live-ops), NO-GO path with Phase skip (team-release) |
| **Agent fixes (4)** | Genre-agnostic language in game-designer, systems-designer, economy-designer, live-ops-designer — removed RPG-specific terms |

---

### Files: Safe to Overwrite

**New files to add:**
```
.claude/skills/consistency-check/SKILL.md
```

**Existing files to overwrite (no user content):**
```
.claude/skills/team-combat/SKILL.md      ← no-arg guard, verdict keywords, gate improvements
.claude/skills/team-narrative/SKILL.md   ← no-arg guard, verdict keywords, gate improvements
.claude/skills/team-ui/SKILL.md          ← no-arg guard, verdict keywords, gate improvements
.claude/skills/team-release/SKILL.md     ← no-arg guard, verdict keywords, NO-GO path
.claude/skills/team-polish/SKILL.md      ← no-arg guard, verdict keywords, gate improvements
.claude/skills/team-audio/SKILL.md       ← no-arg guard, verdict keywords, gate improvements
.claude/skills/team-level/SKILL.md       ← no-arg guard, verdict keywords, adjacent area checks
.claude/skills/team-live-ops/SKILL.md    ← no-arg guard, verdict keywords, ethics enforcement
.claude/skills/team-qa/SKILL.md          ← no-arg guard, verdict keywords, gate improvements
.claude/skills/map-systems/SKILL.md      ← verdict keywords
.claude/skills/create-epics/SKILL.md     ← "May I write" protocol fix, verdict keywords
.claude/skills/create-stories/SKILL.md   ← verdict keywords
.claude/agents/game-designer.md          ← genre-agnostic language
.claude/agents/systems-designer.md       ← genre-agnostic language
.claude/agents/economy-designer.md       ← genre-agnostic language
.claude/agents/live-ops-designer.md      ← genre-agnostic language
```

---

### Files: Merge Carefully

No files require manual merging in this release. All changes are to infrastructure files with no user content.

---

### After Upgrading

1. Run `/skill-test catalog` to verify all skills are indexed.
2. Run `/skill-test lint [skill-name]` after any skill edits to check structural compliance.
3. If you've customized any team-* skills, review the updated versions — no-argument guard and `Verdict:` keywords are now required for all team-* skills.

---

## v0.3.0 → v0.4.0

**Released:** 2026-03-21
**Commit range:** `b1cad29..HEAD`
**Key themes:** Full UX/UI pipeline, complete story lifecycle, brownfield adoption, comprehensive QA/testing framework, pipeline integrity, 29 new skills

### What Changed

| Category | Changes |
|----------|---------|
| **New skills (17)** | `/ux-design`, `/ux-review`, `/help`, `/quick-design`, `/review-all-gdds`, `/story-readiness`, `/story-done`, `/sprint-status`, `/adopt`, `/create-architecture`, `/create-control-manifest`, `/create-epics`, `/create-stories`, `/dev-story`, `/propagate-design-change`, `/content-audit`, `/architecture-review` |
| **New skills QA (12)** | `/qa-plan`, `/smoke-check`, `/soak-test`, `/regression-suite`, `/test-setup`, `/test-helpers`, `/test-evidence-review`, `/test-flakiness`, `/skill-test`, `/bug-triage`, `/team-live-ops`, `/team-qa` |
| **New hooks (4)** | `log-agent-stop.sh` — agent audit trail stop; `notify.sh` — Windows toast notifications; `post-compact.sh` — session recovery reminder after compaction; `validate-skill-change.sh` — advises `/skill-test` after skill edits |
| **New templates (8)** | `ux-spec.md`, `hud-design.md`, `accessibility-requirements.md`, `interaction-pattern-library.md`, `player-journey.md`, `difficulty-curve.md`, and 2 adoption plan templates |
| **New infrastructure** | `workflow-catalog.yaml` (7-phase pipeline, read by `/help`), `docs/architecture/tr-registry.yaml` (stable TR-IDs), `production/sprint-status.yaml` schema |
| **Skill updates** | `/gate-check` — 3 gates now require UX artifacts; Pre-Production gate requires vertical slice (HARD gate) |
| **Skill updates** | `/sprint-plan` — writes `sprint-status.yaml`; `/sprint-status` reads it |
| **Skill updates** | `/story-done` — 8-phase completion review, updates story file, surfaces next ready story |
| **Skill updates** | `/design-review` — removed architecture gap check (wrong stage) |
| **Skill updates** | `/team-ui` — full UX pipeline (ux-design → ux-review → team phases) |
| **Agent updates** | 14 specialist agents — `memory: project` added |
| **Agent updates** | `prototyper` — `isolation: worktree` (throwaway work in isolated git branch) |
| **Model routing** | Haiku/Sonnet/Opus tier assignments documented in coordination rules; skills declare their tier in frontmatter |
| **Directory CLAUDE.md** | Scaffolded `design/CLAUDE.md`, `src/CLAUDE.md`, `docs/CLAUDE.md` — path-scoped instructions for each directory |
| **Pipeline integrity** | TR-ID stability, manifest versioning, ADR status gates, TR-ID reference not quote |
| **GDD template** | `## Game Feel` section added (input responsiveness, animation targets, impact moments) |

---

### Files: Safe to Overwrite

**New files to add:**
```
.claude/skills/ux-design/SKILL.md
.claude/skills/ux-review/SKILL.md
.claude/skills/help/SKILL.md
.claude/skills/quick-design/SKILL.md
.claude/skills/review-all-gdds/SKILL.md
.claude/skills/story-readiness/SKILL.md
.claude/skills/story-done/SKILL.md
.claude/skills/sprint-status/SKILL.md
.claude/skills/adopt/SKILL.md
.claude/skills/create-architecture/SKILL.md
.claude/skills/create-control-manifest/SKILL.md
.claude/skills/create-epics/SKILL.md
.claude/skills/create-stories/SKILL.md
.claude/skills/dev-story/SKILL.md
.claude/skills/propagate-design-change/SKILL.md
.claude/skills/content-audit/SKILL.md
.claude/skills/architecture-review/SKILL.md
.claude/skills/qa-plan/SKILL.md
.claude/skills/smoke-check/SKILL.md
.claude/skills/soak-test/SKILL.md
.claude/skills/regression-suite/SKILL.md
.claude/skills/test-setup/SKILL.md
.claude/skills/test-helpers/SKILL.md
.claude/skills/test-evidence-review/SKILL.md
.claude/skills/test-flakiness/SKILL.md
.claude/skills/skill-test/SKILL.md
.claude/skills/bug-triage/SKILL.md
.claude/skills/team-live-ops/SKILL.md
.claude/skills/team-qa/SKILL.md
.claude/hooks/log-agent-stop.sh
.claude/hooks/notify.sh
.claude/hooks/post-compact.sh
.claude/hooks/validate-skill-change.sh
.claude/docs/workflow-catalog.yaml
.claude/docs/templates/ux-spec.md
.claude/docs/templates/hud-design.md
.claude/docs/templates/accessibility-requirements.md
.claude/docs/templates/interaction-pattern-library.md
.claude/docs/templates/player-journey.md
.claude/docs/templates/difficulty-curve.md
design/CLAUDE.md
src/CLAUDE.md
docs/CLAUDE.md
```

**Existing files to overwrite (no user content):**
```
.claude/skills/gate-check/SKILL.md
.claude/skills/sprint-plan/SKILL.md
.claude/skills/sprint-status/SKILL.md
.claude/skills/design-review/SKILL.md
.claude/skills/team-ui/SKILL.md
.claude/skills/story-readiness/SKILL.md
.claude/skills/story-done/SKILL.md
.claude/docs/templates/game-design-document.md    ← adds Game Feel section
README.md
docs/WORKFLOW-GUIDE.md
UPGRADING.md
```

**Agent files to overwrite** (if you haven't written custom prompts into them):
```
.claude/agents/prototyper.md         ← adds isolation: worktree
.claude/agents/art-director.md       ← adds memory: project
.claude/agents/audio-director.md     ← adds memory: project
.claude/agents/economy-designer.md   ← adds memory: project
.claude/agents/game-designer.md      ← adds memory: project
.claude/agents/gameplay-programmer.md ← adds memory: project
.claude/agents/lead-programmer.md    ← adds memory: project
.claude/agents/level-designer.md     ← adds memory: project
.claude/agents/narrative-director.md ← adds memory: project
.claude/agents/systems-designer.md   ← adds memory: project
.claude/agents/technical-artist.md   ← adds memory: project
.claude/agents/ui-programmer.md      ← adds memory: project
.claude/agents/ux-designer.md        ← adds memory: project
.claude/agents/world-builder.md      ← adds memory: project
```

---

### Files: Merge Carefully

#### `.claude/settings.json`

Four new hooks are registered in this version. If you haven't customized `settings.json`, overwriting is safe. Otherwise, add the following hook entries manually:

- `log-agent-stop.sh` — `SubagentStop` event (agent audit trail stop)
- `notify.sh` — `Notification` event (Windows toast notification)
- `post-compact.sh` — `PostCompact` event (session recovery reminder)
- `validate-skill-change.sh` — `PostToolUse` event filtered to `.claude/skills/` writes

#### Customized agent files

If you've added project-specific knowledge to agent `.md` files, do a diff and manually add the `memory: project` line to the YAML frontmatter where appropriate. Creative and technical director agents intentionally keep `memory: user` — only specialist agents get `memory: project`.

---

### New Features

#### Complete Story Lifecycle

Stories now have a formal lifecycle enforced by two skills:

- **`/story-readiness`** — validates a story is implementation-ready before a developer picks it up. Checks Design (GDD req linked), Architecture (ADR accepted), Scope (criteria testable), and DoD (manifest version current). Verdict: READY / NEEDS WORK / BLOCKED.
- **`/story-done`** — 8-phase completion review after implementation. Verifies each acceptance criterion, checks for GDD/ADR deviations, prompts code review, updates the story file to `Status: Complete`, and surfaces the next ready story.

Flow: `/story-readiness` → implement → `/story-done` → next story

#### Full UX/UI Pipeline

- **`/ux-design`** — guided section-by-section UX spec authoring. Three modes: screen/flow, HUD, or interaction pattern library. Reads GDD UI requirements and player journey. Output to `design/ux/`.
- **`/ux-review`** — validates UX specs against GDD alignment, accessibility tier, and pattern library. Verdict: APPROVED / NEEDS REVISION / MAJOR REVISION.
- **`/team-ui`** updated: Phase 1 now runs `/ux-design` + `/ux-review` as a hard gate before visual design begins.

#### Brownfield Adoption

**`/adopt`** onboards existing projects to the template format. Audits internal structure of GDDs, ADRs, stories, systems-index, and infra. Classifies gaps (BLOCKING/HIGH/MEDIUM/LOW). Builds an ordered migration plan. Never regenerates existing artifacts — only fills gaps.

Argument modes: `full | gdds | adrs | stories | infra`

Also: `/design-system retrofit [path]` and `/architecture-decision retrofit [path]` detect existing files and add only missing sections.

#### Sprint Tracking YAML

`production/sprint-status.yaml` is now the authoritative story tracking format:
- Written by `/sprint-plan` (initializes all stories) and `/story-done` (sets status to `done`)
- Read by `/sprint-status` (fast snapshot) and `/help` (per-story status in production phase)
- Status values: `backlog | ready-for-dev | in-progress | review | done | blocked`
- Falls back gracefully to markdown scanning if file doesn't exist

#### `/help` — Context-Aware Next Step

`/help` reads your current stage and in-progress work, checks which artifacts are complete, and tells you exactly what to do next — one primary required step, plus optional opportunities. Distinct from `/start` (first-time only) and `/project-stage-detect` (full audit).

#### Comprehensive QA and Testing Framework

Nine new QA/testing skills covering the full testing lifecycle:

- **`/test-setup`** — scaffolds the test framework and CI/CD pipeline for your engine
- **`/test-helpers`** — generates engine-specific test helper libraries (GDUnit4, NUnit, etc.)
- **`/qa-plan`** — generates a QA test plan for a sprint or feature, classifying stories by test type
- **`/smoke-check`** — runs the critical path smoke test gate before QA hand-off
- **`/soak-test`** — generates a soak test protocol for extended play sessions (stability, memory leaks)
- **`/regression-suite`** — maps test coverage to GDD critical paths, identifies fixed bugs lacking regression tests
- **`/test-evidence-review`** — quality review of test files and manual evidence documents
- **`/test-flakiness`** — detects non-deterministic tests by reading CI run logs
- **`/skill-test`** — validates skill files for structural compliance and behavioral correctness (three modes: lint, spec, catalog)

Also new: **`/bug-triage`** re-evaluates all open bugs for priority, severity, and ownership.

#### Skill Validator (`/skill-test`)

`/skill-test` is a meta-skill for validating the harness itself. Run it after editing any skill file. Three modes:
- `lint` — validates YAML frontmatter and required fields
- `spec [skill-name]` — runs behavioral spec tests against a specific skill
- `catalog` — checks that all skills in `.claude/skills/` are indexed in the catalog

The new `validate-skill-change.sh` hook reminds you to run `/skill-test` automatically when a skill file is modified.

#### Team Live-Ops and Team QA Orchestration

- **`/team-live-ops`** — coordinates live-ops-designer + economy-designer + community-manager + analytics-engineer for post-launch content planning (seasonal events, battle pass, retention)
- **`/team-qa`** — orchestrates qa-lead + qa-tester + gameplay-programmer + producer through a full QA cycle: strategy, execution, coverage, and sign-off

#### Model Tier Routing

Skills are now explicitly assigned to Haiku, Sonnet, or Opus tiers based on task complexity. Read-only status checks use Haiku; complex multi-document synthesis uses Opus; everything else defaults to Sonnet. Tier assignments are documented in `.claude/docs/coordination-rules.md`.

#### Directory CLAUDE.md Files

Three new directory-scoped CLAUDE.md files (`design/`, `src/`, `docs/`) provide path-specific instructions to agents working in those directories. These load automatically when Claude Code reads files in that directory.

---

### After Upgrading

1. **Verify new hooks** are registered in `.claude/settings.json` — check for all four: `log-agent-stop.sh`, `notify.sh`, `post-compact.sh`, `validate-skill-change.sh`.

2. **Test the audit trail** by spawning any subagent — both start and stop events should appear in `production/session-logs/`.

3. **Generate sprint-status.yaml** if you're in active production:
   ```
   /sprint-plan status
   ```

4. **Run `/adopt`** if you have existing GDDs or ADRs that predate this template version — it will identify which sections need to be added without overwriting your content.

5. **Validate your skills** after any skill edits with `/skill-test` — the new `validate-skill-change.sh` hook will automatically remind you to do this.

---

## v0.2.0 → v0.3.0

**Released:** 2026-03-09
**Commit range:** `e289ce9..HEAD`
**Key themes:** `/design-system` GDD authoring, `/map-systems` rename, custom status line

### Breaking Changes

#### `/design-systems` renamed to `/map-systems`

The `/design-systems` skill was renamed to `/map-systems` for clarity
(decomposing = *mapping*, not *designing*).

**Action required:** Update any documentation, notes, or scripts that invoke
`/design-systems`. The new invocation is `/map-systems`.

### What Changed

| Category | Changes |
|----------|---------|
| **New skills** | `/design-system` (guided GDD authoring, section-by-section) |
| **Renamed skills** | `/design-systems` → `/map-systems` (breaking rename) |
| **New files** | `.claude/statusline.sh`, `.claude/settings.json` statusline config |
| **Skill updates** | `/gate-check` — writes `production/stage.txt` on PASS, new phase definitions |
| **Skill updates** | `brainstorm`, `start`, `design-review`, `project-stage-detect`, `setup-engine` — cross-reference fixes |
| **Bug fixes** | `log-agent.sh`, `validate-commit.sh` — hook execution fixed |
| **Docs** | `UPGRADING.md` added, `README.md` updated, `WORKFLOW-GUIDE.md` updated |

---

### Files: Safe to Overwrite

**New files to add:**
```
.claude/skills/design-system/SKILL.md
.claude/statusline.sh
```

**Existing files to overwrite (no user content):**
```
.claude/skills/map-systems/SKILL.md      ← was design-systems/SKILL.md
.claude/skills/gate-check/SKILL.md
.claude/skills/brainstorm/SKILL.md
.claude/skills/start/SKILL.md
.claude/skills/design-review/SKILL.md
.claude/skills/project-stage-detect/SKILL.md
.claude/skills/setup-engine/SKILL.md
.claude/hooks/log-agent.sh
.claude/hooks/validate-commit.sh
README.md
docs/WORKFLOW-GUIDE.md
UPGRADING.md
```

**Delete (replaced by rename):**
```
.claude/skills/design-systems/   ← entire directory; replaced by map-systems/
```

---

### Files: Merge Carefully

#### `.claude/settings.json`

The new version adds a `statusLine` configuration block pointing to
`.claude/statusline.sh`. If you haven't customized `settings.json`, overwriting
is safe. Otherwise, add this block manually:

```json
"statusLine": {
  "script": ".claude/statusline.sh"
}
```

---

### New Features

#### Custom Status Line

`.claude/statusline.sh` displays a 7-stage production pipeline breadcrumb in
the terminal status line:

```
ctx: 42% | claude-sonnet-4-6 | Systems Design
```

In Production/Polish/Release stages, it also shows the active Epic/Feature/Task
from `production/session-state/active.md` if a `<!-- STATUS -->` block is present:

```
ctx: 42% | claude-sonnet-4-6 | Production | Combat System > Melee Combat > Hitboxes
```

The current stage is auto-detected from project artifacts, or can be pinned by
writing a stage name to `production/stage.txt`.

#### `/gate-check` Stage Advancement

When a gate PASS verdict is confirmed, `/gate-check` now writes the new stage
name to `production/stage.txt`. This immediately updates the status line for all
future sessions without requiring manual file edits.

---

### After Upgrading

1. **Delete the old skill directory:**
   ```bash
   rm -rf .claude/skills/design-systems/
   ```

2. **Test the status line** by starting a Claude Code session — you should see
   the stage breadcrumb in the terminal footer.

3. **Verify hook execution** still works:
   ```bash
   bash .claude/hooks/log-agent.sh '{}' '{}'
   bash .claude/hooks/validate-commit.sh '{}' '{}'
   ```

---

## v0.1.0 → v0.2.0

**Released:** 2026-02-21
**Commit range:** `ad540fe..e289ce9`
**Key themes:** Context Resilience, AskUserQuestion integration, `/map-systems` skill

### What Changed

| Category | Changes |
|----------|---------|
| **New skills** | `/start` (onboarding), `/map-systems` (systems decomposition), `/design-system` (guided GDD authoring) |
| **New hooks** | `session-start.sh` (recovery), `detect-gaps.sh` (gap detection) |
| **New templates** | `systems-index.md`, 3 collaborative-protocol templates |
| **Context management** | Major rewrite — file-backed state strategy added |
| **Agent updates** | 14 design/creative agents — AskUserQuestion integration |
| **Skill updates** | All 7 `team-*` skills + `brainstorm` — AskUserQuestion at phase transitions |
| **CLAUDE.md** | Slimmed from ~159 to ~60 lines; 5 doc imports instead of 10 |
| **Hook updates** | All 8 hooks — Windows compatibility fixes, new features |
| **Docs removed** | `docs/IMPROVEMENTS-PROPOSAL.md`, `docs/MULTI-STAGE-DOCUMENT-WORKFLOW.md` |

---

### Files: Safe to Overwrite

These are pure infrastructure — you have not customized them. Copy the new
versions directly with no risk to your project content.

**New files to add:**
```
.claude/skills/start/SKILL.md
.claude/skills/map-systems/SKILL.md
.claude/skills/design-system/SKILL.md
.claude/docs/templates/systems-index.md
.claude/docs/templates/collaborative-protocols/design-agent-protocol.md
.claude/docs/templates/collaborative-protocols/implementation-agent-protocol.md
.claude/docs/templates/collaborative-protocols/leadership-agent-protocol.md
.claude/hooks/detect-gaps.sh
.claude/hooks/session-start.sh
production/session-state/.gitkeep
docs/examples/README.md
.github/ISSUE_TEMPLATE/bug_report.md
.github/ISSUE_TEMPLATE/feature_request.md
.github/PULL_REQUEST_TEMPLATE.md
```

**Existing files to overwrite (no user content):**
```
.claude/skills/brainstorm/SKILL.md
.claude/skills/design-review/SKILL.md
.claude/skills/gate-check/SKILL.md
.claude/skills/project-stage-detect/SKILL.md
.claude/skills/setup-engine/SKILL.md
.claude/skills/team-audio/SKILL.md
.claude/skills/team-combat/SKILL.md
.claude/skills/team-level/SKILL.md
.claude/skills/team-narrative/SKILL.md
.claude/skills/team-polish/SKILL.md
.claude/skills/team-release/SKILL.md
.claude/skills/team-ui/SKILL.md
.claude/hooks/log-agent.sh
.claude/hooks/pre-compact.sh
.claude/hooks/session-stop.sh
.claude/hooks/validate-assets.sh
.claude/hooks/validate-commit.sh
.claude/hooks/validate-push.sh
.claude/rules/design-docs.md
.claude/docs/hooks-reference.md
.claude/docs/skills-reference.md
.claude/docs/quick-start.md
.claude/docs/directory-structure.md
.claude/docs/context-management.md
docs/COLLABORATIVE-DESIGN-PRINCIPLE.md
docs/WORKFLOW-GUIDE.md
README.md
```

**Agent files to overwrite** (if you haven't written custom prompts into them):
```
.claude/agents/art-director.md
.claude/agents/audio-director.md
.claude/agents/creative-director.md
.claude/agents/economy-designer.md
.claude/agents/game-designer.md
.claude/agents/level-designer.md
.claude/agents/live-ops-designer.md
.claude/agents/narrative-director.md
.claude/agents/producer.md
.claude/agents/systems-designer.md
.claude/agents/technical-director.md
.claude/agents/ux-designer.md
.claude/agents/world-builder.md
.claude/agents/writer.md
```

If you *have* customized agent prompts, see "Merge carefully" below.

---

### Files: Merge Carefully

These files contain both template structure and your project-specific content.
Do **not** overwrite them — merge the changes manually.

#### `CLAUDE.md`

The template version was slimmed from ~159 lines to ~60 lines. The key
structural change: 5 doc imports were removed because they're auto-loaded
by Claude Code anyway (agent-roster, skills-reference, hooks-reference,
rules-reference, review-workflow).

**What to keep from your version:**
- The `## Technology Stack` section (your engine/language choices)
- Any project-specific additions you made

**What to adopt from the new version:**
- Slimmer imports list (drop the 5 redundant `@` imports if present)
- Updated collaboration protocol wording

#### `.claude/docs/technical-preferences.md`

If you ran `/setup-engine`, this file has your engine config, naming
conventions, and performance budgets. Keep all of it. The template version
is just the empty placeholder.

#### `.claude/docs/templates/game-concept.md`

Minor structural update — a `## Next Steps` section was added pointing to
`/map-systems`. Add that section to your copy if you want the updated
guidance, but it's not required.

#### `.claude/settings.json`

Check whether the new version adds any permission rules you want. The change
was minor (schema update). If you haven't customized your `settings.json`,
overwriting is safe.

#### Customized agent files

If you've added project-specific knowledge or custom behavior to any agent
`.md` file, do a diff and manually add the new AskUserQuestion integration
sections rather than overwriting. The change in each agent is a standardized
collaborative protocol block at the end of the system prompt.

---

### Files: Delete

These files were removed in v0.2.0. If present in your repo, you can safely
delete them — they're replaced by better-organized alternatives.

```
docs/IMPROVEMENTS-PROPOSAL.md      → superseded by WORKFLOW-GUIDE.md
docs/MULTI-STAGE-DOCUMENT-WORKFLOW.md → content merged into context-management.md
```

---

### After Upgrading

1. **Run `/project-stage-detect`** to verify the system reads your project
   correctly with the new detection logic.

2. **Run `/start`** once if you haven't used it — it now correctly identifies
   your stage and skips onboarding steps you've already done.

3. **Check `production/session-state/`** exists and is gitignored:
   ```bash
   ls production/session-state/
   cat .gitignore | grep session-state
   ```

4. **Test hook execution** — if you're on Windows, verify the new hooks run
   without errors in Git Bash:
   ```bash
   bash .claude/hooks/detect-gaps.sh '{}' '{}'
   bash .claude/hooks/session-start.sh '{}' '{}'
   ```

---

*Each future version will have its own section in this file.*
