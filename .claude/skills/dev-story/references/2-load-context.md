# /dev-story — Phase 2: Load Full Context

> Part of `/dev-story`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 2: Load Full Context

**In this file:**

- The story file
- The TR registry
- The governing ADR
- The control manifest
- Dependency validation
- Engine reference
- Mark Story In Progress

**Before loading any context, resolve the workflow tier for this story's system** (see the Workflow tier note above), then **verify required files exist.** Extract the ADR path from the story's `ADR Governing Implementation` field. The "If missing — `full`" column is the baseline; the tier columns relax it:

| File | Path | If missing — `full` | `standard` | `minimal` |
|------|------|---------------------|-----------|-----------|
| TR registry | `docs/architecture/tr-registry.yaml` | **STOP** — "TR registry not found at `docs/architecture/tr-registry.yaml`. Run `/architecture-review` to bootstrap the registry from your GDDs and ADRs." | optional — proceed without it | not expected — proceed |
| Governing ADR | path from story's ADR field | **STOP** — "ADR file [path] not found. Run `/architecture-decision` to create it, or correct the filename in the story's ADR field." Also STOP if its `## Status` is `Proposed` — "ADR [path] is still Proposed. Accept it with `/architecture-decision accept [ADR-id]` before implementing." A story whose ADR field reads `N/A` (`N/A — [reason]`) references none — proceed. | **STOP only if the story references an ADR** and its file is missing/Proposed/Deprecated/Superseded; if it references none, proceed | no ADR required — proceed; **STOP only if the story references an ADR** whose file is missing/Proposed/Deprecated/Superseded |
| Control manifest | `docs/architecture/control-manifest.md` | **WARN and continue** — "Control manifest not found — layer rules cannot be checked. Run `/create-control-manifest`." | WARN and continue | skip — not expected |

At `full`, if the TR registry is missing, or a referenced governing ADR is missing or `Proposed`, set the story status to **BLOCKED** in the session state and do not spawn any programmer agent. At `standard`/`minimal`, only a story that references an ADR whose file is **missing, `Proposed`, `Deprecated` or `Superseded`** is set BLOCKED; a missing TR registry, or an absent-by-design ADR, does **not** block — implement against the story's acceptance criteria + the GDD/brief.

Read the story file and the TR registry simultaneously — these two are
genuinely independent, unconditional reads. **The governing ADR is not part
of this batch — do not include it in the same parallel tool-call group as
these two.** Its own section below is a gate, not a read: whether the ADR
gets opened at all depends on a freshness check that itself depends on the
story file already being read. Do not start implementation until this phase
is fully resolved:

### The story file
Extract and hold:
- **Story title, ID, layer, type** (Logic / Integration / Visual/Feel / UI / Config/Data)
- **TR-ID** — the GDD requirement identifier
- **Governing ADR** reference
- **ADR Version** stamp embedded in story header (absent on pre-stamp stories)
- **ADR Decision Summary** and **Implementation Notes** — the distilled ADR
  guidance; this is the primary source for what the ADR decided
- **Manifest Version** embedded in story header
- **Acceptance Criteria** — every checkbox item, verbatim
- **Implementation Notes** — the ADR guidance section in the story
- **Out of Scope** boundaries
- **Test Evidence** — the required test file path
- **Dependencies** — what must be DONE before this story

### The TR registry
Grep the story's TR-ID from `docs/architecture/tr-registry.yaml`
(`Grep pattern="id: <TR-ID>\s*$" path="docs/architecture/tr-registry.yaml" output_mode="content" -A 6`)
rather than reading the whole cross-system registry. Read the matched entry's current
`requirement` text — this is the source of truth for what the GDD requires now. Do not
rely on any inline text in the story file (may be stale).

### The governing ADR

**Do not open the ADR by default.** `/create-stories` already distilled it into
this story's `**ADR Decision Summary**` + `## Implementation Notes`, and its
template states the contract outright: *"This is what the programmer reads
instead of the ADR."* Re-reading the source here discards that work and, on an
ADR past the 25k `Read` cap, costs a failed read plus offset/limit retries
before implementation even starts.

**Check status and freshness with one line, not one file.** Resolve the ADR path
from the story, then:

```
Grep pattern="^## (Status|Last Verified|Date)" path="docs/architecture/[adr-file].md" output_mode="content" -A 2
```

The `## Status` line decides first: if it reads `Proposed`, the story is BLOCKED
per the file-check table above — stop here, before any freshness comparison.
`Deprecated` or `Superseded by ADR-XXXX` blocks the same way, at every tier:
"ADR [path] is [status]; point the story at [successor] (edit its ADR field —
`/create-stories` never rewrites an existing story) before implementing."

Then resolve the ADR's **current version** the way `/create-stories` stamped it:
its `## Last Verified` date, else its `## Date`, else `unversioned`. Compare that
value against the story's `**ADR Version**` field:

| Result | Meaning | Action |
|---|---|---|
| Versions **match** (a date on both sides) | The summary was distilled from the ADR as it stands. | **Trust the story.** Do not read the ADR. |
| Story has **no `ADR Version`** field | A story written before the stamp existed — *not* evidence of staleness. | **Trust the story**, and note in the Phase 6 summary: "Story predates the ADR Version stamp; summary trusted unverified." |
| Both read `unversioned` | The ADR has neither `## Last Verified` nor `## Date`. Consistent, not stale — but nothing to compare. | **Trust the story**; note "ADR carries no date; summary trusted unverified." in the Phase 6 summary, and recommend `/architecture-decision retrofit [file]`, which adds a missing `## Date`. |
| The ADR resolves to `unversioned` but the story names a date | Ambiguous — the ADR lost the field the story was stamped from. | Treat as **mismatch** (below). |
| Versions **differ** | The ADR changed after this story was written. | **Mismatch** — resolve below. |

**Never treat an absent stamp as a stale one.** A missing field means "unknown",
and the fallback for unknown is the story, not a 35k-token re-read — the two
staleness gates that already exist (`/story-readiness` on Manifest Version,
`/code-review` post-implementation) are what make that safe.

**On mismatch**, use `AskUserQuestion` — same shape as the Manifest Version
check below:
- Prompt: "Story was written against ADR v[story-date]. The ADR is now
  v[current-date]. Its decision may have changed. How do you want to proceed?"
- Options:
  - `[A] Re-read the changed ADR sections, implement against current guidance, and refresh this story's ADR summary and ADR Version (Recommended)`
  - `[B] Implement from the story's summary — I accept the drift risk`
  - `[C] Stop — I want to review the ADR diff first`

If **[A]**: first check the ADR's size — `Bash: wc -c "docs/architecture/[adr-file].md"`:

- **Under ~50KB** — read the whole file with one `Read` call. At this size one
  read is *cheaper* than the multi-grep path — per-call overhead outweighs the
  content saved. Targeted reading only pays for itself on files big enough
  to threaten the 25k-token `Read` cap.
- **~50KB or larger** — read *only* the sections that govern implementation,
  never the whole file:
  ```
  Grep pattern="^## (Decision|Engine Compatibility|ADR Dependencies)" path="docs/architecture/[adr-file].md" output_mode="content" -A 40
  ```
  Escalate to a bounded `Read(offset, limit)` on one section only if a scanned
  section cross-references material outside itself.

Then make the story edit that option [A] names: set its `ADR Version` to the ADR's
current version resolved above — not today's date, or the next run mismatches
again — and replace its `**ADR Decision Summary**` and `## Implementation Notes`
with the guidance you just read, so a later run that trusts the stamp is trusting
current guidance.
If **[B]**: proceed on the summary; record it in the Phase 6 "Deviations" summary.
If **[C]**: stop. Do not spawn any agent.

### The control manifest
Read only this story's layer from `docs/architecture/control-manifest.md` — grep that one
section (`Grep pattern="^## <layer> Layer Rules" path="docs/architecture/control-manifest.md" output_mode="content" -A 40`) rather than a full read of every layer. Extract the rules for this story's layer:
- Required patterns
- Forbidden patterns
- Performance guardrails

Check: does the story's embedded Manifest Version match the current manifest header date?
If they differ, use `AskUserQuestion` before proceeding:
- Prompt: "Story was written against manifest v[story-date]. Current manifest is v[current-date]. New rules may apply. How do you want to proceed?"
- Options:
  - `[A] Update story manifest version and implement with current rules (Recommended)`
  - `[B] Implement with old rules — I accept the risk of non-compliance (the story records the current Manifest Version and a Manifest-Note)`
  - `[C] Stop here — I want to review the manifest diff first`

If [A]: edit the story file's `Manifest Version:` field to the current manifest date before spawning the programmer. Then read the manifest carefully for new rules.
If [B]: edit the story file's `Manifest Version:` field to the current manifest date AND add a `Manifest-Note: Proceeded with old manifest rules on [date] — non-compliance risk accepted.` line to the story header. Read the manifest for new rules anyway. Note the decision in the Phase 6 summary under "Deviations". `/story-done` will include the Manifest-Note in its deviations section without re-checking staleness.
If [C]: stop. Do not spawn any agent. Let the user review and re-run `/dev-story`.

### Dependency validation

After extracting the **Dependencies** list from the story file, validate each:

1. Glob `production/epics/**/*.md` to find each dependency story file.
2. Read its `Status:` field.
3. If any dependency has Status other than `Complete` or `Done`:
   - Use `AskUserQuestion`:
     - Prompt: "Story '[current story]' depends on '[dependency title]' which is currently [status], not Complete. How do you want to proceed?"
     - Options:
       - `[A] Proceed anyway — I accept the dependency risk`
       - `[B] Stop — I'll complete the dependency first`
       - `[C] The dependency is done but status wasn't updated — mark it Complete and continue`
   - If [B]: set story status to **BLOCKED** in session state and stop. Do not spawn any programmer agent.
   - If [C]: ask "May I update [dependency path] Status to Complete?" before continuing.
   - If [A]: note in Phase 6 summary under "Deviations": "Implemented with incomplete dependency: [dependency title] — [status]."

If a dependency file cannot be found: warn "Dependency story not found: [path]. Verify the path or create the story file."

---

### Engine reference
Read from `project.yaml` first, falling back to `.claude/docs/technical-preferences.md` for any key absent or empty:
- `specialists.*` — the project's chosen specialist agents; **read before**
  `engine.name` when selecting an agent (see Phase 3)
- `engine.name` (else the `Engine:` value) — the generic engine specialist, and
  the fallback when `specialists` is absent
- `naming.*` (else Naming conventions) — class names, file names, signal/event names
- `performance.*` (else Performance budgets) — frame budget, memory ceiling
- Forbidden patterns — from `.claude/docs/technical-preferences.md` (not migrated to project.yaml)

### Mark Story In Progress

Before spawning any agent, mark the story In Progress. In `collaborative` mode
ask once first — "May I mark this story In Progress? This sets `Status:` and
`Last Updated:` in `[story-path]` and its entry in `production/sprint-status.yaml`."
(leave the sprint-status file out of the question when it does not exist);
`guided` and `autonomous` update these existing files without asking
(`.claude/docs/automation-modes.md`). If the user declines, change neither file,
print `Story not marked In Progress — declined` in the Phase 6 summary, and
continue. Otherwise update two things:

1. **`production/sprint-status.yaml`** (if it exists): find the entry matching this story's file path and set `status: in-progress`. Update the top-level `updated` field to today's date. If the file does not exist, say so in one line — `Sprint status not updated: production/sprint-status.yaml absent` — and continue. Do not skip silently: `/sprint-status` reads that file to report progress, so a story that never gets marked `in-progress` is invisible to the very command a producer uses to ask what is moving.

2. **The story file itself**: set the story header's `Status:` field to `In Progress`, and edit its `Last Updated:` field to today's date (format: `YYYY-MM-DD`; if the field does not exist, add it after the `Status:` line). Setting `Status:` here is what actually marks the story In Progress — at `minimal` the `sprint-status.yaml` in step 1 is absent, so the story file is the only record of progress at that tier.

---
