# /architecture-review — Phase 1: Load Everything

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 1: Load Everything

**In this file:**

- Phase 1a — L0: Summary Scan (fast, low tokens)
- Phase 1b — L1/L2: Targeted Section Load
- Design Documents
- Architecture Documents
- Engine Reference
- Project Standards

### Phase 1a — L0: Summary Scan (fast, low tokens)

**Freshness check before any scan.** A prior report can stand in for this run
only if nothing it rests on has changed: the documents, the engine reference,
the project config, this skill, and the kind of review that produced it.

In `rtm` mode, skip the check and say so — *"Freshness check: not run — rtm
builds the matrix fresh, because stories and tests change without any review
input changing."*

Otherwise locate the latest prior report — Glob
`docs/architecture/architecture-review-*.md` and take the newest — and check
**the review inputs**: every file the phases below read that can change a
finding or the verdict. `[engine]` is the lowercased `engine.name` from
`project.yaml`, the value Phase 5 uses; with no engine configured, leave the two
engine-reference paths out.

```
Bash: bash .claude/scripts/review-receipts.sh check "[latest-report]" docs/architecture/adr-*.md design/gdd/*.md docs/architecture/tr-registry.yaml docs/architecture/architecture.md docs/engine-reference/[engine]/*.md docs/engine-reference/[engine]/modules/*.md project.yaml .claude/docs/technical-preferences.md docs/consistency-failures.md .opencode/skills/architecture-review/SKILL.md .opencode/skills/architecture-review/references/*.md
```

Phase 8 stamps the same list into this run's report; keep the two identical,
and add any file a phase starts reading to both. The check also compares every
file the prior report stamped, named here or not, and prints `GONE:` for one
that no longer exists.

Then read the prior report's `Mode:` and `Workflow:` lines. It **covers** this
run only when its Mode is this run's mode (for `single-gdd`, the same path) or
`full`, and its Workflow is this run's resolved `workflow` or `full`. A report
without those lines was written before they existed and covers nothing.

- **Any `UNRESOLVED`** — check this FIRST; it disqualifies every option
  below. A glob matched no file, so that whole document class was never
  examined and the comparison covered less than it appears to. Say which
  pattern came back unresolved, and neither stand on the prior report nor
  scope a re-run from it: an ADR or GDD directory that is empty, renamed or
  misspelled is a finding about the project. Run the review as asked; its
  verdict is NOT ASSESSED for the missing class (Phase 7), never a stop with
  no report. Never read a set of `UNCHANGED` lines as
  "everything is current" while an `UNRESOLVED` line is present — the set
  compared was not the set requested.
- **The prior report does not cover this run** — check this second, whatever
  the other lines say. Say why: *"The last report was a [mode] review at
  workflow [tier]; it does not cover this run."* Run the review as asked.
  Never offer to stand on it or to scope a re-run from it.
- **Everything `UNCHANGED`** — nothing this review reads has changed since
  that report; re-running reproduces it. Surface the prior report's date,
  mode and verdict and offer with the `question` tool: `[A] Stand on the prior
  report (Recommended)` / `[B] Re-run the full review anyway` — `guided`
  proceeds with [A] and notes it; `autonomous` logs via `log_decision` and
  stands on the prior report.
- **Only GDDs or ADRs `CHANGED`/`NEW`** — name them, then scope instead of
  re-running everything: recommend `/architecture-review single-gdd [path]`
  for just the changed systems. A full re-run stays available on request, and
  a `NEW` ADR warrants one.
- **Anything else `CHANGED`, `NEW` or `GONE`** — a deleted GDD or ADR, the TR
  registry, `architecture.md`, the engine reference, `project.yaml`,
  `technical-preferences.md`, `consistency-failures.md`, or this skill's own
  files. These reach every phase, so recommend re-running the review as
  asked, never a `single-gdd` scope, and name each input with what it
  affects — e.g. *"The engine reference changed after the
  last report: its deprecated-API audit, which `/gate-check` reads, was made
  against the old one."*
- **`RECEIPT: NONE`** — no prior report, or one written before receipts
  existed. Proceed with the full review; this run's report will carry the
  first stamps.

Before reading any full document, use Grep to extract `## Summary` sections
from all GDDs and ADRs:

```
Grep pattern="## Summary" glob="design/gdd/*.md" output_mode="content" -A 4
Grep pattern="## Summary" glob="docs/architecture/adr-*.md" output_mode="content" -A 3
```

**Fail open on a missing Summary.** Establish the denominator: glob
`design/gdd/*.md` and count **N**. A scan matching fewer than N means those GDDs
predate `## Summary` (`/design-system` emits it, but older GDDs lack it) — never
treat an absent Summary as a system out of scope. A zero-match scan means "no GDD
carries a Summary yet", not "nothing to review": full-read the unmatched set.

For `single-gdd [path]` mode: use the target GDD's summary to identify which
ADRs reference the same system (Grep ADRs for the system name), then load only
those ADRs' sections per Phase 1b. Skip unrelated GDDs entirely.

For `engine` mode: load ADR sections only — GDDs are not needed for engine checks.
In practice this is the `## Engine Compatibility` scan alone.

For `coverage` or `full` mode: proceed to Phase 1b for the full in-scope set.
**This is a section load, not a full-file load** — see below for why, and for the
narrow cases that still justify escalating to a whole document.

### Phase 1b — L1/L2: Targeted Section Load

Load the sections the later phases actually consume — **not whole files**. This
skill reads the two largest document sets in the project (every GDD *and* every
ADR); at realistic sizes a full load of both exhausts the context window before
Phase 2 starts, and most of what it loads is narrative this skill never uses.

**Establish the denominator first.** Glob `design/gdd/*.md` and count **N_gdd**;
glob `docs/architecture/adr-*.md` and count **N_adr**. Report both. A section
scan matching fewer than the denominator means those documents lack the section —
**never treat an absent section as an absent document.** The scan narrows the
*read* set; it never shrinks the *in-scope* set.

### Design Documents

Phase 2 extracts *technical requirements* — data structures, performance
constraints, engine capabilities, cross-system communication, persistence,
threading, platform needs. Those live in a known set of sections; Overview and
Player Fantasy are narrative and yield none.

```
Grep pattern="^## (Detailed Rules|Detailed Design|Formulas|Dependencies|Tuning Knobs|Acceptance Criteria)" glob="design/gdd/*.md" output_mode="content" -A 40
```

Accept **either** `## Detailed Rules` or `## Detailed Design` — the design
standard and the GDD template disagree on the name and they denote the same
required section. Full-read a single GDD only when a scanned section
cross-references material outside itself, or when a GDD matched zero sections
(it predates the template — read it whole and say so).

- `design/gdd/systems-index.md` — the authoritative list of systems; read whole (small, and it is an index)

### Architecture Documents

Phases 3–5 need the traceability table, the decision itself, engine claims, and
the dependency edges — not Context, Consequences, Alternatives, Migration Plan or
Validation Criteria, which explain *why* a decision was made.

```
Grep pattern="^## (Status|Decision|GDD Requirements Addressed|Engine Compatibility|ADR Dependencies|Performance Implications)" glob="docs/architecture/adr-*.md" output_mode="content" -A 30
```

Interpret against **N_adr**, and distinguish the two zero-match cases — they are
not the same finding:

| Result | Meaning | Action |
|---|---|---|
| N_adr matches | Normal. | Proceed on the scanned sections. |
| Some ADRs match, some do not | Those ADRs are missing sections. | Record each as a **structural gap** in the Phase 7 report — a missing `## GDD Requirements Addressed` is itself a traceability finding. |
| **0 matches, N_adr > 0** | **Malformed ADRs**, not "no architecture". | "[N_adr] ADRs found, none carries a scannable section — run `/architecture-decision retrofit [file]` on each." Do **not** report zero coverage; that would read as a design failure when it is a format failure. |

Escalate to a full read of one ADR only when judging a conflict needs its
reasoning (Phase 4) — that is a per-ADR decision, not a blanket load.

- `docs/architecture/architecture.md` if it exists

### Engine Reference
- `docs/engine-reference/[engine]/VERSION.md`
- `docs/engine-reference/[engine]/breaking-changes.md`
- `docs/engine-reference/[engine]/deprecated-apis.md`
- **Only the module docs the in-scope ADRs actually name** — take the union of
  each ADR's `References Consulted` and `Post-Cutoff APIs Used` fields (already
  captured by the `## Engine Compatibility` scan above) and read those files.
  Reading the whole `modules/` directory loads engine subsystems the project may
  not use at all. If no ADR names any module, read none and note it: Phase 5
  cannot cross-check engine claims that were never made.

### Project Standards
- `project.yaml` — `naming.*` and `performance.*`; plus `.claude/docs/technical-preferences.md` for those keys when absent and for forbidden patterns / allowed libraries

Report a count: "Loaded [N] GDDs, [M] ADRs, engine: [name + version]."

**Also read `docs/consistency-failures.md`** if it exists. Extract entries with
Domain matching the systems under review (Architecture, Engine, or any GDD domain
being covered). Surface recurring patterns as a "Known conflict-prone areas" note
at the top of the Phase 4 conflict detection output.

---
