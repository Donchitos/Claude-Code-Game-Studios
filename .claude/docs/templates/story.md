# Story [NNN]: [title]

> **Epic**: [epic name]
> **Status**: [Ready | Blocked — BLOCKED: <reason>]
> **Layer**: [Foundation / Core / Feature / Presentation]
> **Type**: [Logic | Integration | Visual/Feel | UI | Config/Data]
> **Estimate**: [S | M | L, or hours — /create-stories proposes one]
> **Build step**: [core | thin — <system> | deepen — <system>; only when the brief lists Your systems, else leave this line out]
> **Manifest Version**: [date from control-manifest.md header]
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/gdd/[filename].md`
**Requirement**: `TR-[system]-NNN`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: [ADR-NNNN: title]
**ADR Decision Summary**: [1-2 sentence summary of what the ADR decided]
**ADR Version**: [the ADR's `## Last Verified` date, else its `## Date`, else `unversioned`]

**Engine**: [name + version] | **Risk**: [LOW / MEDIUM / HIGH]
**Engine Notes**: [from ADR Engine Compatibility section — post-cutoff APIs, verification required]

**Control Manifest Rules (this layer)**:
- Required: [relevant required pattern]
- Forbidden: [relevant forbidden pattern]
- Guardrail: [relevant performance guardrail]

---

## Acceptance Criteria

*From GDD `design/gdd/[filename].md`, scoped to this story:*

- [ ] [criterion 1 — directly from GDD]
- [ ] [criterion 2]
- [ ] [performance criterion if applicable]

---

## Implementation Notes

*Derived from ADR-NNNN Implementation Guidelines:*

[Specific, actionable guidance from the ADR. Do not paraphrase in ways that
change meaning. This is what the programmer reads instead of the ADR.]

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story NNN+1]: [what it handles]

---

## Files

*The code and test files this story creates or changes. `/create-stories` lists the
planned ones; `/dev-story` replaces the list with the files it changed; `/story-done`
checks scope against it.*

- [path under the code root]
- [test path]

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation. (At tiers where the QL-STORY-READY gate is skipped — `minimal`, or `lean`/`solo` review mode — no qa-lead specs exist, and this section reads: N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.)*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: [criterion text]
  - Given: [precondition]
  - When: [action]
  - Then: [assertion]
  - Edge cases: [boundary values / failure states]

**[For Visual/Feel / UI stories — manual verification steps]:**

- **AC-1**: [criterion text]
  - Setup: [how to reach the state]
  - Verify: [what to look for]
  - Pass condition: [unambiguous pass description]

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: [type]
**Required evidence**:
- Logic: `tests/unit/[system]/[story-slug]_test.[ext]` — must exist and pass (`/story-done` checks that it EXISTS; pass/fail is established by `/gate-check` and `/smoke-check`, both later)
- Integration: `tests/integration/[system]/[story-slug]_test.[ext]` OR playtest doc
- Visual/Feel: a retained screenshot in `production/qa/evidence/` + sign-off in `production/qa/evidence/[story-slug]-evidence.md`
- UI: a retained screenshot of each screen touched, in `production/qa/evidence/`
- Config/Data: smoke check pass (`production/qa/smoke-*.md`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: [the path of each story that must be DONE first, e.g. `production/epics/<epic>/story-001-<slug>.md`, or "None"]
- Unlocks: [the path of each story this one unblocks, or "None"]
