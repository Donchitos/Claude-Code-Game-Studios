# Skill Quality Rubric

Used by `/skill-test category [name|all]` to evaluate skills beyond structural compliance.
Each category defines 4–5 binary PASS/FAIL metrics specific to the skill's job.

A metric is PASS when the skill's written instructions clearly satisfy the criterion.
A metric is FAIL when the instructions are absent, ambiguous, or contradictory.
A metric is WARN when the instructions partially address the criterion.
A metric is NOT ASSESSED when it could not be evaluated at all — the rubric
has no section for the category, or the skill or agent file could not be read.

---

## Skill Categories

### `gate`

**Skills**: gate-check

Gate skills control phase transitions. They must enforce correctness without
auto-advancing stage and must respect the three review modes.

| Metric | PASS criteria |
|---|---|
| **G1 — Review mode read** | Skill reads `review_mode` (and `workflow`) from its resolved config block — `modes.review_mode`, the legacy `production/review-mode.txt`, else the `modes.rigor` value — before deciding which directors to spawn |
| **G2 — Director panel width** | Unless `solo`, the PHASE-GATE panel runs in parallel at the width `modes.workflow` sets — `minimal` PR only, `standard` TD + PR, `full` all 4 (CD, TD, PR, AD) — and the output names the perspectives a narrower panel left out |
| **G3 — Lean mode: PHASE-GATE only** | In `lean` mode, only `*-PHASE-GATE` gates run; inline gates (CD-PILLARS, TD-ARCHITECTURE, etc.) are skipped |
| **G4 — Solo mode: no directors** | In `solo` mode, no director gates spawn; each is noted as "skipped — Solo mode" |
| **G5 — No auto-advance** | Skill never writes `project.stage` in `project.yaml`, or the legacy `production/stage.txt`, without explicit user confirmation via a "May I" question |

---

### `review`

**Skills**: design-review, architecture-review, review-all-gdds

Review skills read documents and produce structured verdicts. They are primarily
read-only and must not trigger director gates during the analysis phase.

| Metric | PASS criteria |
|---|---|
| **R1 — Read-only enforcement** | Skill does not modify the reviewed document without explicit user approval; any write operations (review logs, index updates) are gated behind "May I write" |
| **R2 — 8-section check** | Skill evaluates all 8 required GDD sections (or equivalent architectural sections) explicitly |
| **R3 — Correct verdict vocabulary** | Verdict is exactly one of: APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED / NOT ASSESSED (design-review, ux-review) or PASS / CONCERNS / FAIL / NOT ASSESSED (architecture-review, review-all-gdds) |
| **R4 — No director gates during analysis** | Skill does not spawn director gates during its analysis phases; post-analysis director review is acceptable when the skill's scope and stakes warrant it |
| **R5 — Structured findings** | Output contains a per-section status table or checklist before the final verdict |

> **Exceptions:**
> - `design-review`: Has `Write, Edit` in allowed-tools to support an optional "Revise now" path (all writes gated behind user approval) and to write review logs. R1 is satisfied because the reviewed document is never silently modified.

---

### `authoring`

**Skills**: design-system, quick-design, architecture-decision, ux-design, ux-review, art-bible, create-architecture

Authoring skills create or update design documents collaboratively. Full GDD/UX
authoring skills use a section-by-section cycle; lightweight authoring skills use
a single-draft pattern appropriate to their smaller scope.

| Metric | PASS criteria |
|---|---|
| **A1 — Section-by-section cycle** | Full authoring skills (design-system, ux-design, art-bible) author one section at a time, presenting content for approval before proceeding to the next. Lightweight skills (quick-design, architecture-decision, create-architecture) may draft the complete document then ask for approval — single-draft is acceptable for documents under about one week of implementation scope. |
| **A2 — May-I-write per section** | Full authoring skills ask "May I write this to [filepath]?" before each section write. Lightweight skills ask once for the complete document. |
| **A3 — Retrofit mode** | Skill detects if the target file already exists and offers to update specific sections rather than overwriting the whole document. Lightweight skills (quick-design) that always create new files are exempt. |
| **A4 — Director gate at correct tier** | If a director gate is defined for this skill (e.g., CD-GDD-ALIGN, TD-ADR), it runs in `full` only; in `lean` and `solo` it is skipped with a named note (`[GATE-ID] skipped — Lean mode` / `— Solo mode`) |
| **A5 — Skeleton-first** | Full authoring skills create a file skeleton with all section headers before filling content, to preserve progress on session interruption. Lightweight skills are exempt. |

> **Full authoring skills** (must pass all 5 metrics): `design-system`, `ux-design`, `art-bible`
> **Lightweight authoring skills** (A1, A2, A5 use single-draft pattern; A3 exempt for new-file-only skills): `quick-design`, `architecture-decision`, `create-architecture`
> **Review-mode skill** (evaluated against review metrics): `ux-review`

---

### `readiness`

**Skills**: story-readiness, story-done

Readiness skills validate stories before or after implementation. They must produce
multi-dimensional verdicts and integrate correctly with director gate mode.

| Metric | PASS criteria |
|---|---|
| **RD1 — Multi-dimensional check** | Skill checks ≥3 independent dimensions (e.g., Design, Architecture, Scope, DoD) and reports each separately |
| **RD2 — Four verdict levels** | Verdict hierarchy is clearly defined, with NOT ASSESSED between the pass values and the failure values: READY > NOT ASSESSED > NEEDS WORK > BLOCKED (story-readiness); COMPLETE > COMPLETE WITH NOTES > NOT ASSESSED > BLOCKED (story-done) |
| **RD3 — BLOCKED requires external action** | BLOCKED verdict is reserved for issues that cannot be fixed by the story author alone (e.g., Proposed ADR, unresolvable dependency) |
| **RD4 — Director gate at correct mode** | QL-STORY-READY or LP-CODE-REVIEW gate spawns in `full` mode, skips in `lean`/`solo` with a noted skip message |
| **RD5 — Next-story handoff** | After completion, skill surfaces the next READY story from the active sprint. With no sprint plan, `/story-done` names the next story in the build order, and `/story-readiness` says no sprint file was found |

---

### `pipeline`

**Skills**: create-epics, create-stories, dev-story, create-control-manifest, propagate-design-change, map-systems, vertical-slice

Pipeline skills produce artifacts that other skills consume. They must write files
with correct schema, respect layer/priority ordering, and gate before writing.

| Metric | PASS criteria |
|---|---|
| **P1 — Correct output schema** | Each produced file follows the project template (EPIC.md, story frontmatter, etc.); skill references the template path |
| **P2 — Layer/priority ordering** | Skills that produce epics or stories respect layer ordering (foundation → core → feature → presentation) and priority fields |
| **P3 — May-I-write before each artifact** | Skill asks "May I write …?" before creating output files — one question per file, or one approval that names every file in the changeset; it never writes a file the approval did not name |
| **P4 — Director gate at correct tier** | In-scope gates (PR-EPIC, QL-STORY-READY, LP-CODE-REVIEW, etc.) run in `full`, skip in `lean`/`solo` with noted skip |
| **P5 — Reads before writes** | Skill reads the relevant GDD/ADR/manifest before producing artifacts to ensure alignment |

---

### `analysis`

**Skills**: consistency-check, balance-check, content-audit, code-review, tech-debt,
scope-check, estimate, perf-profile, asset-audit, security-audit, test-evidence-review, test-flakiness

Analysis skills scan the project and surface findings. They are read-only during
analysis and must ask before recommending any file writes.

| Metric | PASS criteria |
|---|---|
| **AN1 — Read-only scan** | Analysis phase changes nothing: no Write or Edit and no mutating Bash during the scan itself (read-only commands such as `git log` or file-size measurement are fine) |
| **AN2 — Structured findings table** | Output includes a findings table or checklist (not prose only) with severity/priority per finding |
| **AN3 — No auto-write** | Any suggested file writes (e.g., tech-debt register, fix patches) are gated behind "May I write" |
| **AN4 — No director gates during analysis** | Analysis skills do not spawn director gates; they produce findings for human review |

---

### `team`

**Skills**: team-combat, team-narrative, team-audio, team-level, team-ui, team-qa,
team-release, team-polish, team-live-ops

Team skills orchestrate multiple specialist agents for a department. They must
spawn the right agents, run independent ones in parallel, and surface blocks immediately.

| Metric | PASS criteria |
|---|---|
| **T1 — Named agent list** | Skill explicitly names which agents it spawns and in what order |
| **T2 — Parallel where independent** | Agents whose inputs don't depend on each other are spawned in parallel (single message, multiple `Agent` calls) |
| **T3 — BLOCKED surfacing** | If any spawned agent returns BLOCKED or fails, skill surfaces it immediately and halts dependent work — never silently skips |
| **T4 — Collect all verdicts before proceeding** | Dependent phases wait for all parallel agents to complete before proceeding |
| **T5 — Usage error on no argument** | If a required argument (e.g., feature name) is missing, skill either outputs a usage hint and stops, or infers the argument (e.g., the release version, the active sprint) and confirms it with the user — in both cases before spawning any agent |

---

### `sprint`

**Skills**: sprint-plan, sprint-status, milestone-review, retrospective, changelog, patch-notes

Sprint skills read production state and produce reports or planning artifacts.
They have a PR-SPRINT or PR-MILESTONE gate at specific mode thresholds.

| Metric | PASS criteria |
|---|---|
| **SP1 — Reads sprint/milestone state** | Skill reads `production/sprints/` or `production/milestones/` before producing output |
| **SP2 — Correct sprint gate** | PR-SPRINT (for planning) or PR-MILESTONE (for milestone review) gate runs in `full` mode, skips in `lean`/`solo` |
| **SP3 — Structured output** | Output uses a consistent structure (velocity table, risk list, action items) rather than free prose |
| **SP4 — No auto-commit** | Skill never writes sprint files or milestone records without "May I write" |

---

### `utility`

**Skills**: start, help, brainstorm, onboard, adopt, hotfix, prototype, localize,
launch-checklist, release-checklist, smoke-check, soak-test, test-setup, test-helpers,
regression-suite, qa-plan, bug-triage, bug-report, playtest-report, asset-spec,
reverse-document, project-stage-detect, setup-engine, skill-test, skill-improve,
day-one-patch, and any other skills not in categories above

Utility skills pass the 7 standard static checks. If they happen to spawn director
gates, the gate mode logic must also be correct.

| Metric | PASS criteria |
|---|---|
| **U1 — Passes all 7 static checks** | `/skill-test static [name]` returns COMPLIANT with 0 FAILs |
| **U2 — Gate mode correct (if applicable)** | If the skill spawns any director gate, it reads review-mode and applies full/lean/solo logic correctly |

---

## Agent Categories

Used by `/skill-test category [agent-name]` to evaluate an agent definition in
`.claude/agents/` against its category's metrics.

No category fixes a model. Each agent's tier is its own frontmatter `model:`,
and its spec in `agents/` asserts that alias; see `.claude/docs/model-tiers.md`.

### `director`

**Agents**: creative-director, technical-director, art-director, producer

| Metric | PASS criteria |
|---|---|
| **D1 — Correct verdict vocabulary** | Returns `[GATE-ID]: [word]` as its first line, the word taken from the invoked gate's **Verdicts** line — or `NOT ASSESSED`, naming the missing input, when an input the gate names was not given |
| **D2 — Domain boundary respected** | Does not make binding decisions outside its declared domain |
| **D3 — Conflict escalation** | When two departments conflict, escalates to correct parent (creative-director or technical-director) rather than unilaterally deciding |

### `lead`

**Agents**: lead-programmer, qa-lead, narrative-director, audio-director, game-designer,
systems-designer, level-designer

| Metric | PASS criteria |
|---|---|
| **L1 — Gate verdict or findings** | A lead invoked for a gate (lead-programmer's LP-, qa-lead's QL-, narrative-director's ND- gates) returns that gate's **Verdicts** words — or `NOT ASSESSED`, naming a missing input; a lead without a gate returns findings and leaves the verdict to the calling skill |
| **L2 — Escalates to shared parent** | Out-of-domain conflicts escalate to creative-director (design) or technical-director (tech) |

### `specialist`

**Agents**: gameplay-programmer, ai-programmer, technical-artist, sound-designer,
engine-programmer, tools-programmer, network-programmer, security-engineer,
accessibility-specialist, ux-designer, ui-programmer, performance-analyst, prototyper,
writer, world-builder

| Metric | PASS criteria |
|---|---|
| **S1 — Stays in domain** | Explicitly scopes itself to its declared domain; defers out-of-domain requests |
| **S2 — No binding cross-domain decisions** | Does not unilaterally decide matters owned by another specialist |
| **S3 — Defers correctly** | Out-of-domain requests are redirected to the correct agent, not refused silently |

### `engine`

**Agents**: godot-specialist, godot-gdscript-specialist, godot-csharp-specialist,
godot-shader-specialist, godot-gdextension-specialist, unity-specialist, unity-ui-specialist,
unity-shader-specialist, unity-dots-specialist, unity-addressables-specialist,
unreal-specialist, ue-blueprint-specialist, ue-gas-specialist, ue-umg-specialist,
ue-replication-specialist

| Metric | PASS criteria |
|---|---|
| **E1 — Version-aware** | References engine version from `docs/engine-reference/` before suggesting API calls; flags post-cutoff risk |
| **E2 — File routing** | Routes file types to the correct sub-specialist (e.g., `.gdshader` → godot-shader-specialist, not godot-gdscript-specialist) |
| **E3 — Engine-specific patterns** | Enforces engine-specific idioms (e.g., GDScript static typing, C# attribute exports, Blueprint function libraries) |

### `qa`

**Agents**: qa-tester

| Metric | PASS criteria |
|---|---|
| **Q1 — Produces artifacts not code** | Primary output is test cases, bug reports, or coverage gaps — not implementation code |
| **Q2 — Evidence format** | Test cases follow the project's test evidence format (unit/integration/visual/UI per coding-standards.md) |
| **Q3 — No scope creep** | Does not propose new features; flags gaps for humans to decide |

### `operations`

**Agents**: devops-engineer, release-manager, live-ops-designer, community-manager,
analytics-engineer, economy-designer, localization-lead

| Metric | PASS criteria |
|---|---|
| **O1 — Domain ownership clear** | Agent description clearly states what it owns (pipeline, releases, economy, etc.) |
| **O2 — Defers implementation** | Does not write game logic or engine code; delegates to appropriate specialist |
| **O3 — Toolset matches role** | `tools:` in frontmatter matches the operational (not coding) nature of the role |
