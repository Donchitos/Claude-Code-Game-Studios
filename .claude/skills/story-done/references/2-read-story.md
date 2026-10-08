# /story-done — Phase 2: Read the Story

> Part of `/story-done`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 2: Read the Story

Read the full story file. Extract and hold in context:

- **Story name and ID**
- **GDD Requirement TR-ID(s)** referenced (e.g., `TR-combat-001`)
- **Manifest Version** embedded in the story header (e.g., `2026-03-10`)
- **ADR reference(s)** referenced
- **Acceptance Criteria** — the complete list (every checkbox item)
- **Implementation files** — files listed under "files to create/modify"
- **Story Type** — the `Type:` field from the story header (Logic / Integration / Visual/Feel / UI / Config/Data)
- **Engine notes** — any engine-specific constraints noted
- **Definition of Done** — if present, the story-level DoD
- **Estimated vs actual scope** — if an estimate was noted

Also read:
- `docs/architecture/tr-registry.yaml` — grep the story's TR-IDs
  (`Grep pattern="id: <each TR-ID>\s*$" path="docs/architecture/tr-registry.yaml" output_mode="content" -A 6`),
  not a full read of the registry. Read the *current* `requirement` text from each
  matched entry. This is the source of truth for what the GDD required — do not use any
  requirement text that may be quoted inline in the story (it may be stale).
- The referenced GDD section — just the acceptance criteria and key rules, not
  the full document. Use this to cross-check the registry text is still accurate.
- The referenced ADR(s) — **just the `## Decision` and `## Consequences`
  sections, never an unbounded full read.** Map headings first
  (`Grep pattern="^## " path="docs/architecture/[adr-file].md" output_mode="content" -n`),
  then bounded-`Read` only those two spans. This is the exact same content
  Phase 4 item 3's ADR constraints check needs — hold it here, do not
  re-read it there.
- `docs/architecture/control-manifest.md` header — extract the current
  `Manifest Version:` date (used in Phase 4 staleness check)

---
