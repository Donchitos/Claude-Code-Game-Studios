---
name: create-control-manifest
description: "Flat must-do/never-do rules sheet per system and layer, extracted from Accepted ADRs. ADRs explain why; this is actionable."
argument-hint: "[update — regenerate from current ADRs]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/create-control-manifest/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`



# Create Control Manifest

The Control Manifest is a flat, actionable rules sheet for programmers. It
answers "what do I do?" and "what must I never do?" — organized by architectural
layer, extracted from all Accepted ADRs, technical preferences, and engine
reference docs. Where ADRs explain *why*, the manifest tells you *what*.

**Output:** `docs/architecture/control-manifest.md`

**When to run:** After `/architecture-review` passes and ADRs are in Accepted
status. Re-run whenever new ADRs are accepted or existing ADRs are revised.

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

## 1. Load All Inputs

### ADRs
**Establish the denominator first.** Glob `docs/architecture/adr-*.md`. Call the
count **N**. If N is 0: "No ADRs found — run `/architecture-decision` before
building a control manifest." Stop.

**Resolve status without reading the ADRs** — the filter must precede the read,
not follow it:
```
Grep pattern="^## Status" glob="docs/architecture/adr-*.md" output_mode="content" -A 3
```
Interpret against N:

| Result | Meaning | Action |
|---|---|---|
| **N matches, some read `Accepted`** | Normal. | The Accepted set is **A**; proceed with A. |
| **N matches, none `Accepted`** | Genuinely no Accepted ADRs. | "[N] ADRs found, none Accepted. A manifest built from Proposed ADRs would encode decisions that may still change." Ask whether to proceed with Proposed or stop. **Do not silently emit an empty manifest.** |
| **0 matches, N > 0** | **Malformed ADRs — not an empty Accepted set.** `## Status` is BLOCKING-if-missing. | "[N] ADRs found, none has a `## Status` section — acceptance cannot be determined. Run `/architecture-decision [file] retrofit` on each." **Stop.** Do not treat all ADRs as Accepted; do not emit a manifest. |

- Note the ADR number and title for every rule sourced.

### Project Config
- Read `naming.*` and `performance.*` from `project.yaml`; for any key absent or
  empty, fall back to `.claude/docs/technical-preferences.md`
- Read approved libraries/addons and forbidden patterns from
  `.claude/docs/technical-preferences.md` (not migrated to project.yaml)

### Engine Reference
- Read `docs/engine-reference/[engine]/VERSION.md` for engine + version
- Read `docs/engine-reference/[engine]/deprecated-apis.md` — these become
  forbidden API entries
- Read `docs/engine-reference/[engine]/current-best-practices.md` if it exists

Report: "Loaded [N] Accepted ADRs, engine: [name + version]."

---

## 2. Extract Rules from Each ADR

Read **only these four sections** per Accepted ADR — not the whole file. Context,
Consequences, Migration Plan and Validation Criteria explain *why* a decision was
made; the manifest records *what to do*, so they are not needed here:
```
Grep pattern="^## (Decision|Alternatives Considered|Performance Implications|Engine Compatibility)" glob="docs/architecture/adr-*.md" output_mode="content" -A 30
```
Filter the results to the Accepted set **A** resolved above. If a section is
absent for a given ADR, note it per ADR and continue; if a section is absent
across **all** of A, report "No Accepted ADR contains a `[section]` section — the
manifest's [category] rules will be empty. Verify this is intended." Escalate to
a full read of one ADR only when its scanned sections cross-reference material
outside them (e.g. a Decision that says "subject to the constraints in Context").

For each Accepted ADR, extract:

### Required Patterns (from the `## Decision` section)
- Every "must", "should", "required to", "always" statement in the Decision body
  — including any `### Implementation Guidelines` sub-heading when the ADR has one
  (newer ADRs emit it; older ones state mandates directly in `## Decision`). Never
  scan for `### Implementation Guidelines` alone — it is absent from many
  skill-authored ADRs, and scanning for it yields an empty Required Patterns
  section on a manifest that should have been full.
- Every specific pattern or approach mandated

### Forbidden Approaches (from "Alternatives Considered" sections)
- Every alternative that was explicitly rejected — *why* it was rejected becomes
  the rule ("never use X because Y")
- Any anti-patterns explicitly called out

### Performance Guardrails (from "Performance Implications" section)
- Budget constraints: "max N ms per frame for this system"
- Memory limits: "this system must not exceed N MB"

### Engine API Constraints (from "Engine Compatibility" section)
- Post-cutoff APIs that require verification
- Verified behaviours that differ from default LLM assumptions
- API fields or methods that behave differently in the pinned engine version

### Layer Classification
Classify each rule by the architectural layer of the system it governs:
- **Foundation**: Scene management, event architecture, save/load, engine init
- **Core**: Core gameplay loops, main player systems, physics/collision
- **Feature**: Secondary systems, secondary mechanics, AI
- **Presentation**: Rendering, audio, UI, VFX, shaders

If an ADR spans multiple layers, duplicate the rule into each relevant layer.

---

## 3. Add Global Rules

Combine rules that apply to all layers:

### From project config (`project.yaml`, else `technical-preferences.md`):
- Naming conventions — `naming.*`: classes, variables, signals/events, files, constants
- Performance budgets — `performance.*`: target framerate, frame budget, draw call limits, memory ceiling

### From deprecated-apis.md:
- Deprecated APIs → Forbidden API entries, **filtered for relevance to this
  project**. Do not copy the deprecation table wholesale.
  > Each entry must apply to what this project actually builds. `deprecated-apis.md`
  > mixes dimensions and subsystems: its `GodotPhysics3D → Jolt Physics 3D` row is
  > **3D-only**, so emitting it unqualified gives a 2D project a global rule about
  > a physics engine it never uses. If you cannot tell whether an entry applies —
  > 2D vs 3D, a module the project does not include — either scope the rule
  > ("when using 3D physics: ...") or omit it and note it as unresolved. A manifest
  > of rules that do not apply is one nobody reads, and `/create-stories` consumes
  > this file.

### From current-best-practices.md (if available):
- Engine-recommended patterns → Required entries

### From technical-preferences.md forbidden patterns:
- Copy any "Forbidden Patterns" entries directly

---

## 4. Present Rules Summary Before Writing

Before writing the manifest, present a summary to the user:

```
## Control Manifest Preview
Engine: [name + version]
ADRs covered: [list ADR numbers]
Total rules extracted:
  - Foundation layer: [N] required, [M] forbidden, [P] guardrails
  - Core layer: [N] required, [M] forbidden, [P] guardrails
  - Feature layer: ...
  - Presentation layer: ...
  - Global: [N] naming conventions, [M] forbidden APIs, [P] approved libraries
```

Use `AskUserQuestion`:
- Prompt: "Does this rule summary look complete?"
- Options:
  - `[A] Yes — looks good, run the director review and write the manifest`
  - `[B] Add rules — I have additional rules to include before writing`
  - `[C] Remove rules — some extracted rules should be dropped`
  - `[D] Stop here — I need to review the ADRs first`

---

## 4b. Director Gate — Technical Review

**Review mode check** — apply before spawning TD-MANIFEST:
- `solo` → skip. Note: "TD-MANIFEST skipped — Solo mode." Proceed to Phase 5.
- `lean` → skip. Note: "TD-MANIFEST skipped — Lean mode." Proceed to Phase 5.
- `full` → spawn as normal.

Spawn `technical-director` via `Agent` using gate **TD-MANIFEST** (`.claude/docs/director-gates/td-manifest.md`).

Pass: the Control Manifest Preview from Phase 4 (rule counts per layer, full extracted rule list), the list of ADRs covered, engine version, and any rules sourced from technical-preferences.md or engine reference docs.

The technical-director reviews whether:
- All mandatory ADR patterns are captured and accurately stated
- Forbidden approaches are complete and correctly attributed
- No rules were added that lack a source ADR or preference document
- Performance guardrails are consistent with the ADR constraints

Apply the verdict:
- **APPROVE** → proceed to Phase 5
- **CONCERNS** → surface via `AskUserQuestion` with options: `Revise flagged rules` / `Accept and proceed` / `Discuss further`
- **REJECT** → do not write the manifest; fix the flagged rules and re-present the summary

---

## 5. Write the Control Manifest

Use `AskUserQuestion`:
- Prompt: "May I write the Control Manifest?"
- Options:
  - `[A] Yes — write to docs/architecture/control-manifest.md`
  - `[B] Show me the full draft first, then ask again`
  - `[C] Not yet — I want to make more changes`

Format:

```markdown
# Control Manifest

> **Engine**: [name + version]
> **Last Updated**: [date]
> **Manifest Version**: [date]
> **ADRs Covered**: [ADR-NNNN, ADR-MMMM, ...]
> **Status**: [Active — regenerate with `/create-control-manifest update` when ADRs change]

`Manifest Version` is the date this manifest was generated. Story files embed
this date when created. `/story-readiness` compares a story's embedded version
to this field to detect stories written against stale rules. Always matches
`Last Updated` — they are the same date, serving different consumers.

This manifest is a programmer's quick-reference extracted from all Accepted ADRs,
technical preferences, and engine reference docs. For the reasoning behind each
rule, see the referenced ADR.

---

## Foundation Layer Rules

*Applies to: scene management, event architecture, save/load, engine initialisation*

### Required Patterns
- **[rule]** — source: [ADR-NNNN]
- **[rule]** — source: [ADR-NNNN]

### Forbidden Approaches
- **Never [anti-pattern]** — [brief reason] — source: [ADR-NNNN]

### Performance Guardrails
- **[system]**: max [N]ms/frame — source: [ADR-NNNN]

---

## Core Layer Rules

*Applies to: core gameplay loop, main player systems, physics, collision*

### Required Patterns
...

### Forbidden Approaches
...

### Performance Guardrails
...

---

## Feature Layer Rules

*Applies to: secondary mechanics, AI systems, secondary features*

### Required Patterns
...

### Forbidden Approaches
...

---

## Presentation Layer Rules

*Applies to: rendering, audio, UI, VFX, shaders, animations*

### Required Patterns
...

### Forbidden Approaches
...

---

## Global Rules (All Layers)

### Naming Conventions
| Element | Convention | Example |
|---------|-----------|---------|
| Classes | [from naming.* in project.yaml, else technical-preferences.md] | [example] |
| Variables | [from naming.* in project.yaml, else technical-preferences.md] | [example] |
| Signals/Events | [from naming.* in project.yaml, else technical-preferences.md] | [example] |
| Files | [from naming.* in project.yaml, else technical-preferences.md] | [example] |
| Constants | [from naming.* in project.yaml, else technical-preferences.md] | [example] |

### Performance Budgets
| Target | Value |
|--------|-------|
| Framerate | [from performance.* in project.yaml, else technical-preferences.md] |
| Frame budget | [from performance.* in project.yaml, else technical-preferences.md] |
| Draw calls | [from performance.* in project.yaml, else technical-preferences.md] |
| Memory ceiling | [from performance.* in project.yaml, else technical-preferences.md] |

### Approved Libraries / Addons
- [library] — approved for [purpose]

### Forbidden APIs ([engine version])
These APIs are deprecated or unverified for [engine + version]:
- `[api name]` — deprecated since [version] / unverified post-cutoff
- Source: `docs/engine-reference/[engine]/deprecated-apis.md`

### Cross-Cutting Constraints
- [constraint that applies everywhere, regardless of layer]
```

---

## 6. Suggest Next Steps

After writing the manifest:

- If epics/stories don't exist yet: "Run `/create-epics layer: foundation` then `/create-stories [epic-slug]` — programmers
  can now use this manifest when writing story implementation notes."
- If this is a regeneration (manifest already existed): "Updated. Recommend
  notifying the team of changed rules — especially any new Forbidden entries."

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **Load silently** — read all inputs before presenting anything
2. **Show the summary first** — let the user see the scope before writing
3. **Ask before writing** — always confirm before creating or overwriting the manifest. On write: Verdict: **COMPLETE** — control manifest written. On decline: Verdict: **BLOCKED** — user declined write.
4. **Source every rule** — never add a rule that doesn't trace to an ADR, a
   technical preference, or an engine reference doc
5. **No interpretation** — extract rules as stated in ADRs; do not paraphrase
   in ways that change meaning
