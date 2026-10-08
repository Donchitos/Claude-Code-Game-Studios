# /dev-story — Phase 5: Test Evidence Requirements

> Part of `/dev-story`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 5: Test Evidence Requirements

The test requirement was included in the Phase 4 programmer agent brief (item 7). This phase summarizes what evidence each story type requires — used when collecting the Phase 6 summary.

**Skip this phase at `qa.level: minimal`** (resolved earlier) — no test evidence
is required, so there is nothing to gate; do not flag the story unverifiable for a
missing test. **The Visual/Feel and UI screenshot line at the end of this phase
still applies** — `qa.level` waives tests, never the look.

> **Say so in the Phase 6 summary.** A skipped phase must announce itself in the
> output, not only in this file (`.claude/rules/skill-authoring.md`, obligation
> 3). For a Logic or Integration story — the types Phase 4 item 7 briefs a test
> for — emit the line:
>
> > *Test evidence: **waived** at `qa.level: minimal` — no test was required or
> > written for this story.*
>
> Without it, a minimal-tier summary that simply lacks a tests row is
> indistinguishable from a `standard`-tier run where the programmer forgot to
> write them — and the permissive reading is the one that gets believed.

Otherwise:

**Resolve the gate level for this story's type** from `testing.strict` in
`project.yaml`. BLOCKING means a missing test marks the story unverifiable;
ADVISORY means a missing test is noted but does not block:

1. Map the Story Type to a `testing.strict` key — Logic→`logic`,
   Integration→`integration`, Visual/Feel→`visual`, UI→`ui`, Config/Data→`config`.
   Take `testing.strict.<key>` from the **the resolved-config block at the top of this skill**, not from
   `project.yaml` directly. If its value is `true` (case-insensitive) →
   BLOCKING; if `false` → ADVISORY; `unset` → fall through.

> `testing.strict.*` is locally overridable (`/settings --local
> testing.strict.logic=false`). Reading `project.yaml` on its own ignores
> `project.local.yaml` entirely, so the override is accepted and then does
> nothing. `resolve_config` merges the two.
2. Else read `testing.strict` as a plain boolean (legacy single-value form) — if
   its value is `true` or `false`, it applies to every type.
3. Else use the **Default Gate Level** column below.

Only `true` and `false` (case-insensitive) are recognized at steps 1–2. A key
that is present but holds any other value — `maybe`, `1`, `yes`, etc. — is
treated as unset: continue to the next step, and surface the unrecognized value
to the user.

| Story Type | Required Evidence | Default Gate Level |
|---|---|---|
| **Logic** | Automated unit test at path from story's Test Evidence section | BLOCKING |
| **Integration** | Integration test OR documented playtest record | BLOCKING |
| **Visual/Feel** | Retained screenshot + evidence doc at `production/qa/evidence/[slug]-evidence.md` | BLOCKING |
| **UI** | Retained screenshot of each screen touched, in `production/qa/evidence/` | BLOCKING |
| **Config/Data** | None — smoke check serves as evidence | ADVISORY |

The test is written alongside the implementation (Phase 4, item 7) regardless of
the gate level — strictness controls only how a *missing* test is reported in the
Phase 6 summary. At a BLOCKING level, a missing test is flagged "story
unverifiable — test required before `/story-done`". At an ADVISORY level it is
noted as a recommendation. The **Default Gate Level** column applies when
`testing.strict` is unset.

Visual/Feel and UI default to **BLOCKING**: for a game the rendered result is the
product, and an advisory visual gate gets deferred in favour of whatever does
block. A project that genuinely does not need it sets `testing.strict.visual` or
`testing.strict.ui` to `false`.

For Visual/Feel and UI stories, include in the Phase 6 summary: "Retained screenshot required under `production/qa/evidence/[story-slug]/` before this story can be closed — at the default BLOCKING level a story with no screenshot on disk is unverifiable." For Visual/Feel, add that the sign-off in `production/qa/evidence/[slug]-evidence.md` is also required.

---
