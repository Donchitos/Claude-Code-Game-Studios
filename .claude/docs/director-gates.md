# Director Gates — Shared Review Pattern

Index of all director and lead review gates. Skills reference gate IDs from this
index instead of embedding prompts inline — eliminating drift when prompts need
updating. Each gate's full definition (Trigger, Context to pass, Prompt, Verdicts)
lives in its own file under `.claude/docs/director-gates/`, named after the gate
ID in lowercase.

**Scope**: All 7 production stages (Concept → Release), all 3 Tier 1 directors,
all key Tier 2 leads. Any skill, team orchestrator, or workflow may invoke these gates.

**When a skill spawns a director for a gate, it must NOT read the gate definition
file itself. Include the gate definition file path in the `Agent` prompt and instruct
the director agent to read it first, then pass only the context fields that gate's
row requires. Gate definitions are read by the spawned agent, in the agent's own
context window.**

---

## Gate Index

Agent by prefix: `CD-` creative-director (Opus) · `TD-` technical-director (Opus)
· `PR-` producer (Opus) · `AD-` art-director (Sonnet) · `LP-` lead-programmer ·
`QL-` qa-lead · `ND-` narrative-director (Tier 2 leads: Sonnet).
Definition files below are in `.claude/docs/director-gates/`.

| Gate ID | Purpose | Definition file |
|---------|---------|-----------------|
| CD-PILLARS | Pillar stress test after pillars are defined | cd-pillars.md |
| CD-GDD-ALIGN | GDD pillar alignment after a system GDD is authored | cd-gdd-align.md |
| CD-SYSTEMS | Systems decomposition vision check after `/map-systems` | cd-systems.md |
| CD-NARRATIVE | Narrative consistency of story/lore documents | cd-narrative.md |
| CD-PLAYTEST | Player experience validation of playtest reports | cd-playtest.md |
| CD-PHASE-GATE | Creative readiness at phase transition | cd-phase-gate.md |
| TD-SYSTEM-BOUNDARY | System boundary review before GDD authoring | td-system-boundary.md |
| TD-FEASIBILITY | Technical feasibility of early concept risks | td-feasibility.md |
| TD-ARCHITECTURE | Master architecture document sign-off | td-architecture.md |
| TD-ADR | Individual ADR review before Accepted | td-adr.md |
| TD-ENGINE-RISK | Engine version risk for post-cutoff APIs | td-engine-risk.md |
| TD-PHASE-GATE | Technical readiness at phase transition | td-phase-gate.md |
| TD-MANIFEST | Control manifest review before it is written | td-manifest.md |
| TD-CHANGE-IMPACT | Design-change impact assessment review | td-change-impact.md |
| PR-SCOPE | Scope and timeline validation | pr-scope.md |
| PR-SPRINT | Sprint plan feasibility review | pr-sprint.md |
| PR-MILESTONE | Milestone risk assessment | pr-milestone.md |
| PR-EPIC | Epic structure feasibility before story breakdown | pr-epic.md |
| PR-PHASE-GATE | Production readiness at phase transition | pr-phase-gate.md |
| AD-CONCEPT-VISUAL | Visual identity anchor after pillars lock | ad-concept-visual.md |
| AD-ART-BIBLE | Art bible sign-off before asset production | ad-art-bible.md |
| AD-PHASE-GATE | Visual readiness at phase transition | ad-phase-gate.md |
| LP-FEASIBILITY | Implementation feasibility of the architecture | lp-feasibility.md |
| LP-CODE-REVIEW | Code review of an implemented story | lp-code-review.md |
| QL-STORY-READY | Acceptance-criteria testability before sprint | ql-story-ready.md |
| QL-TEST-COVERAGE | Test coverage review before epic done / advance | ql-test-coverage.md |
| ND-CONSISTENCY | Narrative consistency of writer deliverables | nd-consistency.md |
| AD-VISUAL | Visual consistency of art/tech-art decisions | ad-visual.md |

---

## Review Modes

Review intensity controls whether gates run.

**Global config**: `modes.review_mode` in `project.yaml` — one word: `full`,
`lean`, or `solo`. Legacy fallback: `production/review-mode.txt` (single line,
same values); `project.yaml` wins when both are present. Set once during
`/start`, or change it any time with `/settings modes.review_mode=<value>`.

**Per-run override**: any gate-using skill accepts `--review [full|lean|solo]`,
overriding the global config for that run only.

| Mode | What runs |
|------|-----------|
| `full` | All gates active — every workflow step reviewed |
| `lean` | PHASE-GATEs only (`/gate-check`) — per-skill gates skipped. **Default** |
| `solo` | No director gates anywhere (game jams, prototypes, max speed) |

---

## Invocation Pattern (copy into any skill)

**MANDATORY: apply the review mode before every gate spawn.**

The value is already resolved — skills call
`` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode` ``
(with the matching `allowed-tools` grant — see `config-resolution.md`)
and read `review_mode` from the emitted block. Do **not** re-derive it here. The
full chain (`project.local.yaml` → `project.yaml` → `production/review-mode.txt`
→ `modes.rigor` expansion, `standard`→`lean`), its defaults and its failure modes are specified in
`.claude/docs/config-resolution.md`, and covered by the config test suite.

An inline `--review [mode]` argument, if the skill accepts one, overrides the
resolved value for that run.

Apply the resolved mode:
- `solo` → **skip all gates**. Note: `[GATE-ID] skipped — Solo mode`
- `lean` → **skip unless this is a PHASE-GATE** (CD-PHASE-GATE, TD-PHASE-GATE, PR-PHASE-GATE, AD-PHASE-GATE). Note: `[GATE-ID] skipped — Lean mode`
- `full` → spawn as normal

> **PHASE-GATE panel width is a second, independent axis.** `review_mode` decides
> whether the four PHASE-GATEs run at all; `modes.workflow` decides how many of
> them run — `minimal` → PR only, `standard` → TD + PR, `full` → all four. The
> rule and its rationale live in `/gate-check` Section 4b, the only skill that
> spawns PHASE-GATEs. Every other gate in this index is single-director and
> unaffected. Width never softens a verdict: the escalation rule below applies
> unchanged to whoever ran.

```
# Apply mode check, then:
Spawn `[agent-name]` via `Agent`:
- Gate: [GATE-ID] — `Agent` prompt instructs the agent to read
  `.claude/docs/director-gates/[gate-id].md` FIRST (parent must not read it)
- Context: [fields under that gate's **Context to pass**]
- Await the verdict before proceeding.
```

For parallel spawning (multiple directors at one gate point): apply the mode
check per gate, then spawn all surviving agents simultaneously — issue all `Agent`
calls before waiting for any result; collect all verdicts before proceeding.

---

## Standard Verdict Format

All gates return one of three verdicts. Skills must handle all three:

| Verdict | Meaning | Default action |
|---------|---------|----------------|
| **APPROVE / READY** | No issues. Proceed. | Continue the workflow |
| **CONCERNS [list]** | Issues present but not blocking. | Surface to user via `AskUserQuestion` — options: `Revise flagged items` / `Accept and proceed` / `Discuss further` |
| **REJECT / NOT READY [blockers]** | Blocking issues. Do not proceed. | Surface blockers to user. Do not write files or advance stage until resolved. |

**Escalation rule**: When multiple directors are spawned in parallel, apply the
strictest verdict — one NOT READY overrides all READY verdicts.

---

## Recording Gate Outcomes

After a gate resolves, record the verdict in the relevant document's status header:

```markdown
> **[Director] Review ([GATE-ID])**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date]
```

For phase gates, record in `docs/architecture/architecture.md` or
`production/session-state/active.md` as appropriate.

---

## Parallel Gate Protocol

At checkpoints needing multiple directors (most common at `/gate-check`):

```
Spawn in parallel (issue all `Agent` calls before waiting for any result):
creative-director → CD-PHASE-GATE, technical-director → TD-PHASE-GATE,
producer → PR-PHASE-GATE, art-director → AD-PHASE-GATE

Collect all four verdicts, then apply escalation rules:
- Any NOT READY / REJECT → overall verdict minimum FAIL
- Any CONCERNS → overall verdict minimum CONCERNS
- All READY / APPROVE → eligible for PASS (still subject to artifact checks)
```

---

## Adding New Gates

1. Assign a gate ID: `[DIRECTOR-PREFIX]-[DESCRIPTIVE-SLUG]`. Prefixes: `CD-`
   `TD-` `PR-` `LP-` `QL-` `ND-` `AD-`; add new ones for new agents
   (`audio-director` → `AU-`, `ux-designer` → `UX-`)
2. Create `.claude/docs/director-gates/[gate-id].md` (lowercase), starting with
   the standard "> Gate definition..." header note, with all five fields:
   Trigger, Context to pass, Prompt, Verdicts, special handling notes
3. Add its row to the Gate Index table above
4. Reference it in skills by ID only — never copy the prompt text into the skill

---

## Gate Coverage by Stage

| Stage | Required Gates | Optional Gates |
|-------|---------------|----------------|
| **Concept** | CD-PILLARS, AD-CONCEPT-VISUAL | TD-FEASIBILITY, PR-SCOPE |
| **Systems Design** | TD-SYSTEM-BOUNDARY, CD-SYSTEMS, PR-SCOPE, CD-GDD-ALIGN (per GDD) | ND-CONSISTENCY, AD-VISUAL, TD-CHANGE-IMPACT (on GDD revision) |
| **Technical Setup** | TD-ARCHITECTURE, TD-ADR (per ADR), TD-MANIFEST, LP-FEASIBILITY, AD-ART-BIBLE | TD-ENGINE-RISK |
| **Pre-Production** | PR-EPIC, QL-STORY-READY (per story), PR-SPRINT, all four PHASE-GATEs (via gate-check) | CD-PLAYTEST |
| **Production** | LP-CODE-REVIEW (per story), QL-STORY-READY, PR-SPRINT (per sprint), QL-TEST-COVERAGE (per sprint close-out) | PR-MILESTONE, AD-VISUAL, TD-CHANGE-IMPACT (on GDD revision) |
| **Polish** | QL-TEST-COVERAGE, CD-PLAYTEST, PR-MILESTONE | AD-VISUAL |
| **Release** | All four PHASE-GATEs (via gate-check) | QL-TEST-COVERAGE |
