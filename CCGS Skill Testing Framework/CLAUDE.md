# CCGS Skill Testing Framework — Claude Instructions

This folder is the quality assurance layer for the Claude Code Game Studios skill/agent
framework. It is self-contained and separate from any game project.

## Key files

| File | Purpose |
|------|---------|
| `catalog.yaml` | Master registry for all 74 skills and 49 agents. Contains category, spec path, and last-test tracking fields. Always read this first when running any test command. |
| `quality-rubric.md` | Category-specific pass/fail metrics. Read the matching `###` section for the skill's category when running `/skill-test category`. |
| `skills/[category]/[name].md` | Behavioral spec for a skill — 5 or more test cases + protocol compliance assertions. |
| `agents/[tier]/[name].md` | Behavioral spec for an agent — 5 or more test cases + protocol compliance assertions. |
| `templates/skill-test-spec.md` | Template for writing new skill spec files. |
| `templates/agent-test-spec.md` | Template for writing new agent spec files. |
| `results/` | Written by `/skill-test spec` when results are saved. Not gitignored — add it to `.gitignore` to keep results out of commits. |

## Path conventions

- Skill specs: `CCGS Skill Testing Framework/skills/[category]/[name].md`
- Agent specs: `CCGS Skill Testing Framework/agents/[tier]/[name].md`
- Catalog: `CCGS Skill Testing Framework/catalog.yaml`
- Rubric: `CCGS Skill Testing Framework/quality-rubric.md`

The `spec:` field in `catalog.yaml` is the authoritative path for each skill/agent spec.
Always read it rather than guessing the path.

## Skill categories

```
gate        → gate-check
review      → design-review, architecture-review, review-all-gdds
authoring   → design-system, quick-design, architecture-decision, art-bible,
              create-architecture, ux-design, ux-review
readiness   → story-readiness, story-done
pipeline    → create-epics, create-stories, dev-story, create-control-manifest,
              propagate-design-change, map-systems, vertical-slice
analysis    → consistency-check, balance-check, content-audit, code-review,
              tech-debt, scope-check, estimate, perf-profile, asset-audit,
              security-audit, test-evidence-review, test-flakiness
team        → team-combat, team-narrative, team-audio, team-level, team-ui,
              team-qa, team-release, team-polish, team-live-ops
sprint      → sprint-plan, sprint-status, milestone-review, retrospective,
              changelog, patch-notes
utility     → all remaining skills
```

## Agent tiers

```
directors      → creative-director, technical-director, producer, art-director
leads          → lead-programmer, narrative-director, audio-director, game-designer,
                 systems-designer, level-designer, qa-lead
specialists    → gameplay-programmer, engine-programmer, network-programmer,
                 ai-programmer, tools-programmer, ui-programmer, ux-designer,
                 technical-artist, sound-designer, performance-analyst, prototyper,
                 writer, world-builder
engine/godot   → godot-specialist, godot-gdscript-specialist, godot-csharp-specialist,
                 godot-shader-specialist, godot-gdextension-specialist
engine/unity   → unity-specialist, unity-ui-specialist, unity-shader-specialist,
                 unity-dots-specialist, unity-addressables-specialist
engine/unreal  → unreal-specialist, ue-gas-specialist, ue-replication-specialist,
                 ue-umg-specialist, ue-blueprint-specialist
operations     → devops-engineer, release-manager, live-ops-designer,
                 community-manager, analytics-engineer, economy-designer,
                 localization-lead
qa             → qa-tester, security-engineer, accessibility-specialist
```

A tier is the directory a spec lives in. The rubric category is the agent's
`category:` in `catalog.yaml` and can differ: `security-engineer` and
`accessibility-specialist` sit in `qa/` but are rated as `specialist`.

## Workflow for testing a skill or agent

1. Read `catalog.yaml` to get the `spec:` path and `category:` — from the
   `skills:` entry for a skill, the `agents:` entry for an agent
2. Read the skill at `.claude/skills/[name]/SKILL.md`, or the agent at
   `.claude/agents/[name].md`
3. Read the project `CLAUDE.md` and the files it imports with `@`: every
   subagent receives them, so a rule stated there (for example a redirect in
   `coordination-rules.md`) counts as the skill's or agent's own
4. Read the spec at the `spec:` path
5. Evaluate the spec's Static Assertions, each case's assertions, and its
   Protocol Compliance list
6. Offer to write results to `results/` and update `catalog.yaml`

## Workflow for improving a skill

Use `/skill-improve [name]`. It handles the full loop:
test → diagnose → propose fix → rewrite → retest → keep or revert.

## Spec validity note

Specs in this folder assert the **correct** behavior, not whatever a skill or agent
does today. A failing assertion means the skill or agent is wrong until shown
otherwise: fix it and re-run, and never weaken an assertion just so it passes.
Specs can be wrong too — when one asserts behavior that is itself incorrect,
correct the spec toward the right behavior, not toward what the skill currently does.

## This folder is deletable

Nothing in `.claude/` imports from here, and every other CCGS skill and agent works
without it — but `/skill-test` and `/skill-improve` read it by path. Without it,
`/skill-test static` still works, `/skill-test spec` and `/skill-test category`
stop working, `/skill-test audit` reports that no catalog exists, and
`/skill-improve` skips its category checks (the table in `README.md` has the detail).
