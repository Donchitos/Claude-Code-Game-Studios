# /design-system — Phase 3: Create File Skeleton

> Part of `/design-system`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 3. Create File Skeleton

**In this file:**

- Which sections to scaffold at the resolved tier
- The GDD skeleton
- Writing the file, then the session state update

Once the user confirms, **immediately** create the GDD file with empty section
headers. This ensures incremental writes have a target.

**Scaffold only the sections required at the resolved tier** (§1): at
`standard`, omit Player Fantasy and Tuning Knobs (and Formulas only when the
system defines no numeric rule — see §1; the category is a hint, not the test);
at `full`, scaffold all 8.
**Only the sections §1 named as omitted are skipped** — do not leave empty
`[To be designed]` placeholders for those. Every other section in the template
is scaffolded with its placeholder, including the ones §4 has not decided yet.
This sentence governs the three tier omissions above (Player Fantasy, Tuning
Knobs, and Formulas when no numeric rule exists) and nothing else: it is not a
licence to strip a section because it looks optional, and §4 cannot fill a
section §3 never created.

Use the template structure from `.claude/docs/templates/game-design-document.md`:

```markdown
# [System Name]

> **Status**: In Design
> **Author**: [user + agents]
> **Last Updated**: [today's date]
> **Last Verified**: [today's date]
> **Implements Pillar**: [from context]

## Summary

[To be designed]

> **Quick reference** — Layer: `[Foundation | Core | Feature | Presentation]` · Priority: `[MVP | Vertical Slice | Alpha | Full Vision]` · Key deps: `[System names or "None"]`

## Overview

[To be designed]

## Player Fantasy

[To be designed]

## Detailed Design

### Core Rules

[To be designed]

### States and Transitions

[To be designed]

### Interactions with Other Systems

[To be designed]

## Formulas

[To be designed]

## Edge Cases

[To be designed]

## Dependencies

[To be designed]

## Tuning Knobs

[To be designed]

## Visual/Audio Requirements

[To be designed]

## Game Feel

[To be designed]

## UI Requirements

[To be designed]

## Cross-References

[To be designed]

## Acceptance Criteria

[To be designed]

## Open Questions

[To be designed]
```

> **This skeleton and the template must stay identical in section set and
> order.** They diverged once and it was invisible: the skeleton omitted
> `## Game Feel` and `## Cross-References`, so §3's own rule — *"§4 cannot fill a
> section §3 never created"* — made both unreachable **at every tier, `full`
> included**, while §3's prose above still said *"every other section in the
> template is scaffolded"*. Two agents authoring a combat GDD noticed the gap
> only by opening the template. If you add a section to one file, add it to the
> other in the same commit.

Ask: "May I create the skeleton file at `design/gdd/[system-name].md`?"

If the user declines: Stop with the following message:
> "Verdict: **BLOCKED** — skeleton creation declined. The design session cannot proceed without the skeleton file, as all subsequent phases use it as the base. Re-run `/design-system [system]` when ready to create the file."
Do not proceed to Section A.

After writing, update `production/session-state/active.md`:
- Use Glob to check if the file exists.
- If it **does not exist**: use the **Write** tool to create it. Never attempt Edit on a file that may not exist.
- If it **already exists**: use the **Edit** tool to update the relevant fields.

File content:
- Task: Designing [system-name] GDD
- Current section: Starting (skeleton created)
- File: design/gdd/[system-name].md

---
