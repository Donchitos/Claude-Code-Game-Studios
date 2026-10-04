# CCGS Skill Testing Framework

Quality assurance infrastructure for the **Claude Code Game Studios** framework.
Tests the skills and agents themselves — not any game built with them.

**This ships as part of the template, and it is meant to.** CCGS is a template
you are expected to customize — edit a skill, add your own, retune an agent. This
folder is how you check that what you changed still holds up: `catalog.yaml`
tracks all 74 skills and 49 agents, `quality-rubric.md` defines per-category
pass/fail metrics, and `templates/` gives you the spec format for anything new
you write. Driven by `/skill-test` and `/skill-improve`.

> **If you remove it, two of the four `/skill-test` modes stop working.**
>
> | Mode | Without this folder |
> |------|---------------------|
> | `/skill-test static` | **Works** — the 7 structural checks read `SKILL.md` only |
> | `/skill-test audit` | **Degrades** — reports that no catalog exists |
> | `/skill-test spec` | **Breaks** — the behavioral specs live here |
> | `/skill-test category` | **Breaks** — reads `quality-rubric.md` from here |
> | `/skill-improve` | **Degrades** — its test-fix-retest loop loses the category pass |
>
> `/skill-test` and `/skill-improve` read this folder by path, so removing it is a
> real trade, not a free cleanup — the table above states the actual cost.

---

## What's in here

```
CCGS Skill Testing Framework/
├── README.md              ← you are here
├── CLAUDE.md              ← tells Claude how to use this framework
├── catalog.yaml           ← master registry: all 74 skills + 49 agents, coverage tracking
├── quality-rubric.md      ← category-specific pass/fail metrics for /skill-test category
│
├── skills/                ← behavioral spec files for skills (73 of 74 — settings has none yet)
│   ├── gate/              ← gate category specs
│   ├── review/            ← review category specs
│   ├── authoring/         ← authoring category specs
│   ├── readiness/         ← readiness category specs
│   ├── pipeline/          ← pipeline category specs
│   ├── analysis/          ← analysis category specs
│   ├── team/              ← team category specs
│   ├── sprint/            ← sprint category specs
│   └── utility/           ← utility category specs
│
├── agents/                ← behavioral spec files for agents (one per agent)
│   ├── directors/         ← creative-director, technical-director, producer, art-director
│   ├── leads/             ← lead-programmer, narrative-director, audio-director, game-designer, systems-designer, level-designer, qa-lead
│   ├── specialists/       ← gameplay/engine/network/AI/tools/UI programmers, technical-artist, sound-designer, ux-designer, performance-analyst, prototyper, writer, world-builder
│   ├── engine/            ← engine-specific specialists, split per engine:
│   │   ├── godot/         ← Godot-specific specialists
│   │   ├── unity/         ← Unity-specific specialists
│   │   └── unreal/        ← Unreal-specific specialists
│   ├── operations/        ← devops, release, live-ops, community, analytics, economy, localization
│   └── qa/                ← qa-tester, security-engineer, accessibility-specialist
│
├── templates/             ← spec file templates for writing new specs
│   ├── skill-test-spec.md ← template for skill behavioral specs
│   └── agent-test-spec.md ← template for agent behavioral specs
│
└── results/               ← test run outputs (written by /skill-test spec; not gitignored — add it to .gitignore to keep them out of commits)
```

---

## How to use it

All testing is driven by two skills already in the framework:

### Check structural compliance

```
/skill-test static [skill-name]     # Check one skill (7 checks)
/skill-test static all              # Check all 74 skills
```

### Run a behavioral spec test

```
/skill-test spec gate-check         # Evaluate a skill against its written spec
/skill-test spec design-review
/skill-test spec creative-director  # Agents too: evaluates agents/directors/creative-director.md
```

### Check against category rubric

```
/skill-test category gate-check     # Evaluate one skill against its category metrics
/skill-test category art-director   # Or one agent, against its agent category
/skill-test category all            # Run rubric checks across every categorized skill and agent
```

### See full coverage picture

```
/skill-test audit                   # Skills + agents: has-spec, last tested, result
```

### Improve a failing skill

```
/skill-improve gate-check           # Test → diagnose → propose fix → retest loop
```

---

## Skill categories

| Category | Skills | Key metrics |
|----------|--------|-------------|
| `gate` | gate-check | Review mode read, full/lean/solo director panel, no auto-advance |
| `review` | design-review, architecture-review, review-all-gdds | Read-only, 8-section check, correct verdicts |
| `authoring` | design-system, quick-design, art-bible, create-architecture, … | Section-by-section May-I-write, skeleton-first |
| `readiness` | story-readiness, story-done | Blockers surfaced, director gate in full mode |
| `pipeline` | create-epics, create-stories, dev-story, map-systems, … | Upstream dependency check, handoff path clear |
| `analysis` | consistency-check, balance-check, code-review, tech-debt, … | Read-only report, verdict keyword, no writes |
| `team` | team-combat, team-narrative, team-audio, … | All required agents spawned, blocked surfaced |
| `sprint` | sprint-plan, sprint-status, milestone-review, … | Reads sprint data, status keywords present |
| `utility` | start, adopt, hotfix, localize, setup-engine, … | Passes static checks |

---

## Agent tiers

| Tier (directory) | Agents |
|------|--------|
| `directors` | creative-director, technical-director, producer, art-director |
| `leads` | lead-programmer, narrative-director, audio-director, game-designer, systems-designer, level-designer, qa-lead |
| `specialists` | gameplay-programmer, engine-programmer, network-programmer, ai-programmer, tools-programmer, ui-programmer, ux-designer, technical-artist, sound-designer, performance-analyst, prototyper, writer, world-builder |
| `engine/godot` | godot-specialist, godot-gdscript-specialist, godot-csharp-specialist, godot-shader-specialist, godot-gdextension-specialist |
| `engine/unity` | unity-specialist, unity-ui-specialist, unity-shader-specialist, unity-dots-specialist, unity-addressables-specialist |
| `engine/unreal` | unreal-specialist, ue-gas-specialist, ue-replication-specialist, ue-umg-specialist, ue-blueprint-specialist |
| `operations` | devops-engineer, release-manager, live-ops-designer, community-manager, analytics-engineer, economy-designer, localization-lead |
| `qa` | qa-tester, security-engineer, accessibility-specialist |

---

## Updating the catalog

`catalog.yaml` tracks test coverage for every skill and agent. After running a test:

- `/skill-test spec [name]` will offer to update `last_spec` and `last_spec_result`
- `/skill-test category [name]` will offer to update `last_category` and `last_category_result`
- `last_static` and `last_static_result` are updated manually or via `/skill-improve`

---

## Writing a new spec

1. Find the spec template at `templates/skill-test-spec.md`
2. Copy it to `skills/[category]/[skill-name].md`
3. Update the `spec:` field in `catalog.yaml` to point to the new file
4. Run `/skill-test spec [skill-name]` to validate it

For an agent, copy `templates/agent-test-spec.md` to `agents/[tier]/[agent-name].md`,
set the `spec:` field on its entry under `agents:` in `catalog.yaml`, and run
`/skill-test spec [agent-name]`.

---

## Removing this framework

No hook or import in the main project depends on this folder, but `/skill-test`
and `/skill-improve` read it by path. To remove:

```bash
rm -rf "CCGS Skill Testing Framework"
```

Afterwards `/skill-test static` works as before, `spec` and `category` stop
working, `audit` reports that no catalog exists, and `/skill-improve` skips its
category checks — the table at the top of this file lists the cost per mode.
