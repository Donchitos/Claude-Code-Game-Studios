# /create-epics — Handoff Contract

## Role in Pipeline
Translates approved GDDs and architecture documents into one EPIC.md file per
architectural module, defining scope, ADR governance, engine risk, and requirement
traceability — sits between architecture review and story decomposition.

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `design/gdd/systems-index.md` | System list, layer assignments, priority order | Yes |
| `design/gdd/[system].md` | `## Summary`, `## Acceptance Criteria`, `## Overview` (all 8 required sections) | Yes |
| `docs/architecture/architecture.md` | Module ownership, API boundaries | Yes |
| `docs/architecture/adr-NNNN-[slug].md` (all governing ADRs) | `Status:`, `GDD Requirements Addressed`, `Decision`, `Engine Compatibility` | Yes |
| `docs/architecture/control-manifest.md` | `Manifest Version:` date in header | Yes |
| `docs/architecture/tr-registry.yaml` | TR-IDs with `id`, `system`, requirement text | Yes |
| `docs/engine-reference/[engine]/VERSION.md` | Engine name, version, risk levels | Yes |

> **Tier.** The rows above and the preconditions below are the `full` inputs.
> SKILL.md relaxes them by `workflow`: at `standard`, GDDs need the 5 required
> sections (+ conditional Formulas), only critical (Foundation-layer) ADRs are
> expected and traced, and the control manifest is read if present, not required.
> At `minimal` the skill is optional and off the path (`/create-stories`
> synthesizes the epic itself); if run, it skips Steps 2a and 2b, reads only
> `design/game-brief.md` (stopping if that is missing), takes its order from the
> brief's Build order instead of `systems-index.md`, and requires no GDD, ADR,
> architecture document, TR registry or control manifest.

### Preconditions
- `/create-control-manifest` has been run and `docs/architecture/control-manifest.md` exists
- `/architecture-review` has passed (at minimum Foundation and Core ADRs are Accepted)
- All in-scope GDDs have status `Approved` or `Designed` in `systems-index.md`
- The target layer's GDDs are stable — do not run for Feature layer until Core is nearly complete

## Outputs Produced

### Files Written
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `production/epics/[epic-slug]/EPIC.md` | `Layer`, `GDD` path, `Architecture Module`, `Status: Ready`, `## Governing ADRs` table, `## GDD Requirements` table with TR-IDs and ADR coverage, `## Definition of Done`, `## Overview` | Created per approved epic |
| `production/epics/index.md` | `Epic`, `Layer`, `System`, `GDD`, `Stories`, `Status` columns | Created, or a row added per new epic; an existing epic's row is updated in place and keeps its `Stories` value |

### Output Guarantees
- Every EPIC.md contains a `## Governing ADRs` table with at least one row (or a documented note if none apply)
- Every EPIC.md contains a `## GDD Requirements` table where each row has a `TR-ID` and an `ADR Coverage` cell (either `ADR-NNNN ✅` or `❌ No ADR`)
- The `GDD:` field in the EPIC.md header is a valid relative path to the source GDD
- The `Layer:` field is one of: Foundation, Core, Feature, Presentation
- The `Status:` field is set to `Ready`
- The `Stories:` field reads `Not yet created — run /create-stories [epic-slug]` on a new epic; an EPIC.md that already existed is updated in place (after an update-or-skip ask) and keeps its `Stories:` line and `## Stories` table
- Untraced requirements (TR-IDs with no ADR) are flagged in the GDD Requirements table with `❌ No ADR`
- `production/epics/index.md` has an entry for every epic written in this run
- A PR-EPIC review that could not judge the epics (no milestone timeline or team capacity) is reported as `PR-EPIC: NOT ASSESSED — [input]` and never read as REALISTIC

## Immutability Rules
- READS but does NOT modify: `design/gdd/systems-index.md`, all GDD files, `docs/architecture/architecture.md`, all ADR files in `docs/architecture/adr-NNNN-[slug].md` pattern, `docs/architecture/control-manifest.md`, `docs/architecture/tr-registry.yaml`, `docs/engine-reference/[engine]/VERSION.md`
- MODIFIES: `production/epics/[epic-slug]/EPIC.md` (creates, or updates in place keeping its Stories table), `production/epics/index.md` (creates or updates)

## Hard Constraints (Never Violate)
- Never create story files — this skill stops at the epic level
- Never invent content not sourced from GDDs, ADRs, or architecture docs
- Never skip the per-epic approval prompt before writing
- Never write an EPIC.md without first presenting the epic definition to the user
- Never overwrite an existing EPIC.md or reset its `## Stories` table — update it in place, or skip it
- Never mark a TR-ID as covered by an ADR unless that ADR's `Status:` is `Accepted`
- Never create epics for a layer whose dependency layer is not yet substantially complete

## Downstream Skill Expects
**Next skill:** /create-stories

It will read:
- `production/epics/[epic-slug]/EPIC.md` — specifically: `Layer:`, `GDD:` path, `Architecture Module:`, the full `## Governing ADRs` table (ADR IDs and summaries), and the full `## GDD Requirements` table (TR-IDs and ADR coverage status)
- `production/epics/index.md` — to enumerate available epics when no argument is given

It assumes:
- The `GDD:` path in EPIC.md resolves to a readable file
- Every ADR listed in `## Governing ADRs` exists as a file and has an `Accepted` status
- TR-IDs in `## GDD Requirements` match entries in `docs/architecture/tr-registry.yaml`
- The epic slug used in the directory name matches the slug referenced in `index.md`
- `Status: Ready` does not by itself mean no stories exist — an EPIC.md updated in place keeps its stories; read its `Stories:` line

## Known Fragile Points
- If the EPIC.md template structure changes (section names, header field names, table column order), `/create-stories` will silently fail to parse governance data and may produce incomplete or incorrect stories
- If `tr-registry.yaml` is regenerated with renumbered IDs after EPIC.md files are written, the TR-IDs in existing EPIC.md files become stale and mislead `/create-stories`
- If an ADR is retroactively changed from `Accepted` to `Proposed` after the epic is written, the EPIC.md will still show it as governing — `/create-stories` will embed it without a BLOCKED flag
- If `systems-index.md` layer assignments change after epics are created, the `Layer:` field in existing EPIC.md files will be incorrect and `/create-stories` will use the wrong layer context
- `production/epics/index.md` rows are matched to epics by slug — an epic whose slug changes gets a new row, and the old row stays behind
