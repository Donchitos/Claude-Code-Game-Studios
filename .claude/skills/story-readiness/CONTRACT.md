# /story-readiness — Handoff Contract

## Role in Pipeline
Validates that a story file contains everything a developer needs to begin
implementation and produces a READY / NEEDS WORK / BLOCKED / NOT ASSESSED verdict — sits between
`/create-stories` and `/dev-story`, acting as a blocking gate before any code is written.

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `production/epics/[epic-slug]/story-NNN-[slug].md` | All header fields (`Status:`, `Layer:`, `Type:`, `Manifest Version:`), `## Context` (GDD path, TR-ID, ADR reference, Engine Notes, Control Manifest Rules), `## Acceptance Criteria`, `## Test Evidence`, `## Dependencies`, `## Out of Scope` | Yes |
| `docs/architecture/control-manifest.md` | `Manifest Version:` date in header, layer rules | Yes (if exists) |
| `docs/architecture/tr-registry.yaml` | `id`, `status` fields per TR entry | Yes (if exists) |
| `docs/architecture/adr-NNNN-[slug].md` (all ADRs referenced in stories) | `Status:` field | Yes |
| `design/gdd/systems-index.md` | Which systems have approved GDDs | Yes |

> **Tier.** The manifest, TR registry, ADR and systems-index rows are
> `standard`/`full` inputs. At `workflow: minimal` the skill is not on the path
> (`/dev-story` follows `/create-stories` directly); run anyway, it checks
> acceptance criteria and scope only and treats Architecture Completeness as N/A
> except the referenced-ADR rule: an ADR the story references that is missing,
> `Proposed`, `Deprecated` or `Superseded` BLOCKS at every tier (SKILL.md, the tier note above Design
> Completeness).

### Preconditions
- The story file being validated was produced by `/create-stories` (or follows the same format)
- For `sprint` scope: a sprint file exists in `production/sprints/` with story path references
- For `all` scope: `production/epics/` directory exists and contains story files

## Outputs Produced

### Files Written
None. This skill is strictly read-only and produces no file modifications under any circumstance.

### Output Guarantees
- A verdict of READY, NEEDS WORK, BLOCKED or NOT ASSESSED is produced for every story file evaluated. `NOT ASSESSED` is not a synonym for `BLOCKED`: BLOCKED names a real, listable obstacle, while NOT ASSESSED means the story could not be evaluated at all. An empty scope yields `NOT ASSESSED — no stories in scope`, never a `Ready: 0 / Needs Work: 0 / Blocked: 0` summary over an empty list
- Every non-READY verdict includes a specific gap list with fix instructions for each failing checklist item
- Every BLOCKED verdict names the specific blocker (missing dependency story path, Proposed ADR ID, or unresolved design question marker)
- For `sprint` scope: a sprint-level escalation warning is prepended if any Must Have story is not READY (NEEDS WORK, BLOCKED or NOT ASSESSED)
- The skill offers to draft missing sections in conversation but never uses Write or Edit tools

## Immutability Rules
- READS but does NOT modify: story files, `docs/architecture/control-manifest.md`, `docs/architecture/tr-registry.yaml`, all ADR files, `design/gdd/systems-index.md`, sprint files, any referenced asset files (existence-only Glob checks)
- MODIFIES: nothing

## Hard Constraints (Never Violate)
- Never use Write or Edit tools under any circumstances
- Never draft corrections directly into files — offer drafts in conversation only
- Never mark a story READY if its governing ADR has `Status: Proposed`, `Deprecated` or `Superseded`, at any tier
- Never mark a story READY if a dependency story file is missing or has `Status: Draft`
- Never re-read the same ADR file multiple times in one run — cache ADR statuses after the first read
- Never penalize a story for missing `Manifest Version:` if `control-manifest.md` does not exist
- Never penalize a story for missing TR-ID if `tr-registry.yaml` does not exist

## Downstream Skill Expects
**Next skill:** /dev-story

It will rely on this skill's verdict as follows:
- If verdict is READY: `/dev-story` proceeds with implementation using the story file as its source of truth
- If verdict is NEEDS WORK, BLOCKED or NOT ASSESSED: `/dev-story` must not be run until the story is corrected (or, for NOT ASSESSED, made readable) and re-validated — a story nobody could evaluate has not been shown ready
- `/dev-story` reads the same story fields this skill validates — a READY verdict is an implicit guarantee that those fields are present, parseable, and internally consistent:
  - `Type:` field is set to a valid story type
  - `## Acceptance Criteria` contains specific, testable checkbox items
  - `## Test Evidence` specifies a concrete evidence path
  - The governing ADR exists and has `Status: Accepted`
  - `Manifest Version:` matches the current control manifest
  - `TR-ID` in `## Context` is present and resolves in `docs/architecture/tr-registry.yaml` (when the registry exists)
  - `## Dependencies` section is present (may say "None")
  - `## Out of Scope` section is present (checked for existence; `/dev-story` uses it to enforce implementation boundaries)

## Known Fragile Points
- If `control-manifest.md` is regenerated with a new `Manifest Version:` date, every story that embeds the old date will fail the manifest version check — a bulk update of all story `Manifest Version:` fields is required before stories can pass readiness again
- If an ADR is silently renamed or moved after stories reference it by ID, the ADR file-existence check will BLOCK those stories even though the decision content is unchanged
- The manifest version comparison is a string date match, not a semantic version comparison — if the date format changes (e.g., from `2026-01-15` to `Jan 15 2026`), all stories will fail the check regardless of actual currency
- Asset existence checks use Glob — on Windows, path separator mismatches (`\` vs `/`) may cause a Glob miss that incorrectly flags an asset as missing
- The TR-ID status check auto-passes if the registry does not exist, which means stories written before TR tracking was introduced will always pass this check even if they contain invalid or placeholder IDs like `TR-[system]-???`
- For `sprint` scope, the skill depends on sprint file formatting to extract story paths — if the sprint file format changes, story paths may not be parsed and the scope silently reduces to zero stories validated
