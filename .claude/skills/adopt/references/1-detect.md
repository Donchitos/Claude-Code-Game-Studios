# /adopt — Phase 1: Detect Project State

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 1: Detect Project State

Emit one line before reading: `"Scanning project artifacts..."` — this confirms the
skill is running during the silent read phase.

Then read silently before presenting anything else.

### Existence check
- `project.stage` in `project.yaml` (fallback `production/stage.txt`) — if either is present, use that value (authoritative phase)
- `design/gdd/game-concept.md` (or, at the minimal tier, `design/game-brief.md`) — concept exists?
- `design/gdd/systems-index.md` — systems index exists?
- Count GDD files: `design/gdd/*.md` (excluding game-concept.md and systems-index.md)
- Count ADR files: `docs/architecture/adr-*.md`
- Count story files: `production/epics/**/*.md` (excluding EPIC.md)
- `project.yaml` (`engine.name`) / `.claude/docs/technical-preferences.md` — engine configured?
- `docs/engine-reference/` — engine reference docs present?
- Glob `docs/adoption-plan-*.md` — note the filename of the most recent prior plan if any exist

### Infer phase (if no project.stage / stage.txt)
Use the same heuristic as `/project-stage-detect`:
- 10+ source files in the code root → Production
- Stories in `production/epics/` → Pre-Production
- ADRs exist → Technical Setup
- systems-index.md exists → Systems Design
- game-concept.md (or `design/game-brief.md`) exists → Concept
- Nothing → Fresh (not a brownfield project — suggest `/start`)

If the project appears fresh (no artifacts at all), use `AskUserQuestion`:
- "This looks like a fresh project — no existing artifacts found. `/adopt` is for
  projects with work to migrate. What would you like to do?"
  - "Run `/start` — begin guided first-time onboarding"
  - "My artifacts are in a non-standard location — help me find them"
  - "Cancel"

`/start` and Cancel end this skill: say which, and stop.

**If they pick "help me find them"**, search before asking anything else:

1. Search the folder they named, if they named one; otherwise the whole
   project, skipping `.claude/`, `.git/`, `docs/engine-reference/`,
   `studio-tests/`, `node_modules/` and the engine's build and
   cache folders.
2. Glob `**/*.md` there, then Grep the matches for the headings each artifact
   carries: a GDD has `## Overview` with `## Detailed Rules` or
   `## Detailed Design`; an ADR `## Status` with `## Decision`; a story
   `## Acceptance Criteria` with a `Status` line; a concept doc
   `## Elevator Pitch` or `## Game Pillars`; a brief `## Core loop` with
   `## Features` (`## MVP` in briefs from before 1.3.0).
3. Show what was found, grouped by type, each with the place every skill reads
   it from: GDD → `design/gdd/[name].md`; ADR →
   `docs/architecture/adr-NNNN-[name].md`; story →
   `production/epics/[epic]/story-NNN-[name].md`; concept →
   `design/gdd/game-concept.md`; brief → `design/game-brief.md`. If nothing
   matched, say so, name the folders and headings searched, and offer `/start`.
4. Ask before moving anything — a move takes the file away from its old path,
   so it is a `file_deletions` decision: "May I move these [N] files to the
   standard folders?" — `[A] Move them all` / `[B] Let me pick which` /
   `[C] Don't move them — I'll do it myself`. Move with `git mv` in a git
   repository (the file's history follows it), plain `mv` otherwise. Never
   overwrite a file already at the target: name the clash and skip that file.
   Files are moved, never edited.
5. After the moves, run Phase 1 again from the top, so the audit reads the files
   where every other skill will. With [C], print the moves as a list and stop.

Report: "Detected phase: [phase]. Found: [N] GDDs, [M] ADRs, [P] stories."

---
