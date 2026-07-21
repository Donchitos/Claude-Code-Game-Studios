# Lead Programmer — Agent Memory

## Skill Authoring Conventions

### Frontmatter
- Fields: exactly `name` and `description`
- `name` must match the `skills/<name>/` folder
- `description` explains what the skill does and when Codex should use it
- Document invocation syntax, expected input, and missing-input behavior in the skill body
- At decision points, pause and ask the user a focused question with concise choices when useful

### File Layout
- Skills live in `skills/<name>/SKILL.md` (subdirectory per skill, never flat .md)
- Section headers use `##` for phases, `###` for sub-sections
- Phase names follow "Phase N: Verb Noun" pattern (e.g., "Phase 1: Find the Story")
- Output format templates go in fenced code blocks

### Known Canonical Paths (verify before referencing in new skills)
- Tech debt register: `docs/tech-debt-register.md` (NOT `production/tech-debt.md`)
- Sprint files: `production/sprints/`
- Epic story files: `production/epics/[epic-slug]/story-[NNN]-[slug].md`
- Control manifest: `docs/architecture/control-manifest.md`
- Session state: `production/session-state/active.md`
- Systems index: `design/gdd/systems-index.md`
- Engine reference: `docs/engine-reference/[engine]/VERSION.md`

### Skills Completed
- `story-done` — end-of-story completion handshake (Phase 1-8, writes story file)
