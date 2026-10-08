# /architecture-decision — Retrofit Mode

> Part of `/architecture-decision`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

**If the argument starts with `retrofit` followed by a file path**

(e.g., `/architecture-decision retrofit docs/architecture/adr-0001-event-system.md`):

Enter **retrofit mode**:

1. Read the existing ADR file completely.
2. Identify which template sections are present by scanning headings:
   - `## Status` — **BLOCKING if missing**: `/story-readiness` cannot check ADR acceptance
   - `## ADR Dependencies` — HIGH if missing: dependency ordering breaks
   - `## Engine Compatibility` — HIGH if missing: post-cutoff risk unknown
   - `## GDD Requirements Addressed` — MEDIUM if missing: traceability lost
   - `## Date` — MEDIUM if missing, and no `## Last Verified` either: `/create-stories`
     stamps stories with it and `/dev-story` compares against it, so without it a
     story can never tell whether the ADR changed
3. Present to the user:
   ```
   ## Retrofit: [ADR title]
   File: [path]

   Sections already present (will not be touched):
   ✓ Status: [current value, or "MISSING — will add"]
   ✓ [section]

   Missing sections to add:
   ✗ Status — BLOCKING (stories cannot validate ADR acceptance without this)
   ✗ ADR Dependencies — HIGH
   ✗ Engine Compatibility — HIGH
   ```
4. Ask: "Shall I add the [N] missing sections? I will not modify any existing content."
   If no: write nothing, and report the missing sections by name.
5. If yes:
   - For **Status**: ask the user — "What is the current status of this decision?"
     Options: "Proposed", "Accepted", "Deprecated", "Superseded by ADR-XXXX"
     An `Accepted` answer — a decision already in force — is not written as
     given: write `Proposed`, add the other missing sections, then run
     acceptance mode (below) on this ADR. Its dependency check, confirmation and
     story unblocking apply here too; it stays the only path that sets `Accepted`.
   - For **ADR Dependencies**: ask — "Does this decision depend on any other ADR?
     Does it enable or block any other ADR or epic?" Accept "None" for each field.
   - For **Engine Compatibility**: read the engine reference docs (same as Step 1 below)
     and ask the user to confirm the domain. Then generate the table with verified data.
   - For **GDD Requirements Addressed**: ask — "Which GDD systems motivated this decision?
     What specific requirement in each GDD does this ADR address?"
   - Append each missing section to the ADR file using the Edit tool.
   - For **Date** (counted only when there is no `## Last Verified`): append
     `## Date` with today's date — even when it is the only missing section, the
     case `/dev-story` sends you here for — and say that it records the retrofit,
     not when the decision was made.
   - **Never modify any existing section.** Only append or fill absent sections.
6. Suggest: "Run `/architecture-review` to re-validate coverage now that this ADR
   has its Status and Dependencies fields."
