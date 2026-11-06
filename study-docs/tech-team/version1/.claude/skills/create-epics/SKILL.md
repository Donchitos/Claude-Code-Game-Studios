---
name: create-epics
description: "Translate approved feature specs + architecture into epics — one epic per architectural module. Defines scope, governing ADRs, UE 5.8 engine risk, and untraced requirements. Does NOT break into stories — run /create-stories [epic-slug] after each epic is created."
argument-hint: "[system-name | layer: foundation|core|feature|presentation | all] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
model: sonnet
agent: technical-director
---

# Create Epics

An epic is a named, bounded body of work that maps to one architectural module.
It defines **what** needs to be built and **who owns it architecturally**. It
does not prescribe implementation steps — that is the job of stories.

**Run this skill once per layer** as you approach that layer in development.
Do not create Feature layer epics until Core is nearly complete — the
requirements will have changed.

**Output:** `production/epics/[epic-slug]/EPIC.md` + `production/epics/index.md`

**Next step after each epic:** `/create-stories [epic-slug]`

**When to run:** After `/create-control-manifest` and `/architecture-review` pass.

---

## 1. Parse Arguments

Resolve the review mode (once, store for all gate spawns this run):
1. If `--review [full|lean|solo]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

See `.claude/docs/director-gates.md` for the full check pattern.

**Modes:**
- `/create-epics all` — process all systems in layer order
- `/create-epics layer: foundation` — Foundation layer only
- `/create-epics layer: core` — Core layer only
- `/create-epics layer: feature` — Feature layer only
- `/create-epics layer: presentation` — Presentation layer only
- `/create-epics [system-name]` — one specific system
- No argument — ask: "Which layer or system would you like to create epics for?"

---

## 2. Load Inputs

### Step 2a — Summary scan (fast)

Grep all feature specs for their `## Summary` sections before reading anything fully:

```
Grep pattern="## Summary" glob="docs/requirements/*.md" output_mode="content" -A 5
```

For `layer:` or `[system-name]` modes: filter to only in-scope specs based on
the Summary quick-reference. Skip full-reading anything out of scope.

### Step 2b — Full document load (in-scope systems only)

Using the Step 2a grep results, identify which systems are in scope. Read full documents **only for in-scope systems** — do not read specs or ADRs for out-of-scope systems or layers.

Read for in-scope systems:

- In-scope feature specs only (under `docs/requirements/`) — these are the
  requirement source (there are no GDDs in this team)
- `docs/architecture/tr-registry.yaml` — authoritative TR-ID index mapping
  requirement IDs to spec requirement text and spec file paths
- `docs/architecture/architecture.md` — module ownership and API boundaries
- Accepted ADRs **whose domains cover in-scope systems only** — read the
  "Requirements Addressed", "Decision", and "Engine Compatibility" sections;
  skip ADRs for unrelated domains
- `docs/architecture/control-manifest.md` — manifest version date from header
- `.claude/docs/technical-preferences.md` — engine pinned to UE 5.8

Report: "Loaded [N] feature specs, [M] ADRs, engine: Unreal Engine 5.8
(knowledge source: Context7 MCP)."

> **Note**: Do NOT read a static `docs/engine-reference/` directory — it is not
> maintained. The runtime UE API authority is Context7 MCP, queried lazily by
> individual UE specialists when ADRs are written or reviewed. Epic creation
> reads ADR `Engine Compatibility` sections which already carry Context7-stamped
> verification results.

---

## 3. Processing Order

Process in dependency-safe layer order:
1. **Foundation** (no dependencies)
2. **Core** (depends on Foundation)
3. **Feature** (depends on Core)
4. **Presentation** (depends on Feature + Core)

Within each layer, use the order from `architecture.md`.

---

## 4. Define Each Epic

For each system, map it to an architectural module from `architecture.md`.

Check ADR coverage against the TR registry:
- **Traced requirements**: TR-IDs that have an Accepted ADR covering them
- **Untraced requirements**: TR-IDs with no ADR — warn before proceeding

Present to user before writing anything:

```
## Epic: [System Name]

**Layer**: [Foundation / Core / Feature / Presentation]
**Feature Spec**: docs/requirements/[filename].md
**Architecture Module**: [module name from architecture.md]
**Governing ADRs**: [ADR-NNNN, ADR-MMMM]
**Engine Risk**: [LOW / MEDIUM / HIGH — highest risk among governing ADRs, from Context7 verification]
**Requirements Covered by ADRs**: [N / total]
**Untraced Requirements**: [list TR-IDs with no ADR, or "None"]
```

If there are untraced requirements:
> "⚠️ [N] requirements in [system] have no ADR. The epic can be created, but
> stories for these requirements will be marked Blocked until ADRs exist.
> Run `/architecture-decision` first, or proceed with placeholders."

Use `AskUserQuestion`:
- Prompt: "Shall I create Epic: [name]?"
- Options:
  - `[A] Yes, create it`
  - `[B] Skip this epic`
  - `[C] Pause — I need to write ADRs first`

---

## 5. Write Epic Files

After approval, ask: "May I write the epic file to `production/epics/[epic-slug]/EPIC.md`?"

After user confirms, write:

### `production/epics/[epic-slug]/EPIC.md`

```markdown
# Epic: [System Name]

> **Layer**: [Foundation / Core / Feature / Presentation]
> **Feature Spec**: docs/requirements/[filename].md
> **Architecture Module**: [module name]
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories [epic-slug]`

## Overview

[1 paragraph describing what this epic implements, derived from the feature spec
Overview and the architecture module's stated responsibilities]

## Governing ADRs

| ADR | Decision Summary | UE 5.8 Engine Risk |
|-----|------------------|--------------------|
| ADR-NNNN: [title] | [1-line summary] | LOW/MEDIUM/HIGH |

## Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-[system]-001 | [requirement text from registry] | ADR-NNNN ✅ |
| TR-[system]-002 | [requirement text] | ❌ No ADR |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `docs/requirements/[filename].md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories [epic-slug]` to break this epic into implementable stories.
```

### Update `production/epics/index.md`

Create or update the master index:

```markdown
# Epics Index

Last Updated: [date]
Engine: Unreal Engine 5.8

| Epic | Layer | System | Feature Spec | Stories | Status |
|------|-------|--------|--------------|---------|--------|
| [name] | Foundation | [system] | [file] | Not yet created | Ready |
```

---

## 6. Gate-Check Reminder

After writing all epics for the requested scope:

- **Foundation + Core complete**: These are required for the Requirements
  Breakdown → Implementation gate. Run `/gate-check implementation` to check
  readiness.
- **Reminder**: Epics define scope. Stories define implementation steps. Run
  `/create-stories [epic-slug]` for each epic before developers can pick up work.

---

## Collaborative Protocol

1. **One epic at a time** — present each epic definition before asking to create it
2. **Warn on gaps** — flag untraced requirements before proceeding
3. **Ask before writing** — per-epic approval before writing any file
4. **No invention** — all content comes from feature specs, ADRs, and architecture docs
5. **Never create stories** — this skill stops at the epic level

After all requested epics are processed:

- **Verdict: COMPLETE** — [N] epic(s) written. Run `/create-stories [epic-slug]` per epic.
- **Verdict: BLOCKED** — user declined all epics, or no eligible systems found.
