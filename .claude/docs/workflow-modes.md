# Workflow Modes — Shared Skill Pattern

This document defines `modes.workflow` and `workflow_overrides` — how much
design documentation is REQUIRED before code can begin — for every skill that
authors, reviews, gates, or plans against project artifacts. Skills reference
this document instead of embedding the tier tables inline.

**Companion spec**: `.claude/docs/effects-map.md`
sections `modes.workflow` and `workflow_overrides` are the source of
truth for behavior. This document is the implementation pattern.

> **Do not read `effects-map.md` during a skill run.** It is many times the
> size of everything CLAUDE.md loads per session combined — and it is a
> reference for *authoring and changing the spec*, not a runtime input.
> **This document is self-sufficient** for resolving
> the tier and applying it: the resolution chain, the three tiers, the required
> sections, and the override rules are all here. If you hit a case this document
> genuinely does not cover, read only the one `effects-map.md` section for the
> knob in question — never the file.

**Related shared docs**: `.claude/docs/automation-modes.md` (how skills prompt),
`.claude/docs/director-gates.md` (which reviewers spawn). `workflow` is
orthogonal to both — it controls *what artifacts must exist*, not *how the
skill prompts* or *who reviews*.

---

## How to Use This Document

A skill that authors, reviews, or gates a design artifact resolves the
effective workflow tier at startup, then applies the required-section /
required-artifact set for that tier.

**Resolution (per skill):**

```
Resolve the workflow tier (store the result; see scope note below):
1. If the resolution is for a named system AND
   `workflow_overrides.system_overrides.<system>` is set → use that tier
2. Else read `modes.workflow` from `project.yaml` → use that value
3. Else → use the tier implied by `modes.rigor`
   (`minimal`→`minimal`, `standard`→`standard`, `full`→`full`;
    `rigor` itself defaults to `minimal`)
```

`modes.workflow` has **no terminal default** — step 3 is the `rigor` expansion,
not a hardcoded `standard`. The resolved value is the same for an unconfigured
project, so nothing observable changed; but a skill that hardcodes `standard` as
its fallback will ignore `rigor: minimal` and `rigor: full` entirely.

### What `<system>` is — one derivation, everywhere

**`<system>` is the GDD filename stem**: `design/gdd/forge-heat-system.md` →
`forge-heat-system`. That is the key to write under
`workflow_overrides.system_overrides`, and every skill must derive it the same
way.

A `TR-[system]-NNN` ID's `[system]` segment is **an alias, not the key**. Accept
it as a fallback match when the GDD stem yields nothing, but never derive the key
from it in preference to the stem.

> **Why this is stated here rather than per skill.** Reading *"the `[system]`
> segment of its `TR-[system]-NNN` ID (else its `design/gdd/` path)"* — TR-ID
> **first** — is the wrong order. A system whose GDD is `forge-heat-system.md` and
> whose requirements are `TR-forge-001` would then have **two different override
> keys depending on whether a registry entry existed**, and the documented remedy
> for a missing GDD section — "set
> `workflow_overrides.system_overrides.forge-heat-system: full`" — would be looked
> up under `forge`, find nothing, and continue at the project tier **silently**.
> The escape hatch would exist and could not be reached.

**A key that matches no system is an error, not a no-op.** If
`workflow_overrides.system_overrides` contains a key that resolves to no GDD stem
in `design/gdd/`, say so — naming the unmatched key and the stems available.
Silently ignoring it would leave an override that does nothing, unnoticed.

> **Checked where GDDs are expected to already exist — not by the skill that
> writes them.** `/gate-check` is the single implementing site (see
> `.claude/skills/gate-check/SKILL.md` §"Per-system overrides"), and it runs at a
> phase boundary, by which point every in-scope GDD should be on disk. An
> unmatched key there is genuinely suspicious.
>
> `/design-system` **creates** `design/gdd/<system>.md`, so before its first run
> the override key matches no stem *by definition* — that is the healthy case,
> not an error. It must not report the key as orphaned, and must not refuse to
> apply the tier it names. The same holds for any other authoring skill running
> before the GDD exists. Applying this rule there would fire on exactly the
> configuration it was written to protect.

---

Step 1 (the per-system override) applies to skills that act on a named system:
- **Single-system, resolve once per run**: `design-system`, `design-review`,
  `dev-story`, `story-done`, `create-stories` (one story/epic per invocation).
- **Multi-system, resolve once per item**: `story-readiness` (per story across
  `all`/`sprint` scope), `qa-plan` and `regression-suite` audit (per GDD/system).
  These do NOT freeze a single tier for the run — different systems in one run
  may resolve to different tiers.

Skills that operate project-wide (`gate-check`, `create-epics`) use the
project-level `workflow` plus consider per-system overrides where the tier table
says so.

> **"Critical ADR" (used in the tier tables):** an ADR governing a
> **Foundation-layer** system (scene management, event architecture, save/load,
> and the like — the systems whose decisions everything else depends on). At
> `standard`, only critical ADRs are required/blocking; non-critical ADRs are
> advisory. When in doubt about an ADR's layer, treat it as critical (fail safe
> toward requiring it).

`modes.workflow` reads via **`resolve_config --keys workflow`** (or
`resolve_setting modes.workflow`), which applies the whole chain including the
`rigor` expansion. Do **not** use `get_effective_yaml_key modes.workflow`: it
reads the two YAML files only, so on a project that sets `modes.rigor` and not
`modes.workflow` it returns **empty** while the effective tier is whatever rigor
implies. (`project.local.yaml` is not allowed to override workflow — it is locked
to `project.yaml` per the whitelist — so the only sources are `project.yaml` and
the expansion.) Per-system overrides read via
`get_yaml_key project.yaml workflow_overrides.system_overrides.<system>`.

---

## The Three Tiers

| Tier | Token/time cost | Required before code | Best for |
|------|----------------|---------------------|----------|
| `full` | High | All 8 GDD sections per system, full architecture, all ADRs, art bible, UX specs per screen | Teams, commercial titles, learning the full pipeline |
| `standard` | Balanced | 5 GDD sections per system, one architecture doc, critical ADRs, game concept, systems index | Projects that outgrew a brief - several interacting systems, or a design someone else implements |
| `minimal` | Low | One-page `design/game-brief.md` + engine choice (its build-order field is the plan — no separate sprint plan) | **Default.** Jam projects, small scope, design already in your head |

**Default**: `minimal` (the rationale block above `_yaml_helper_defaults` in
`.claude/hooks/yaml-helper.sh` carries the reasoning and the ordering
constraint). **Set by**: `/start` (via `modes.rigor`), `/settings`. **Locked to
`project.yaml`** (not locally overridable — divergence would change which
artifacts must exist on disk).

> **Permissive, not restrictive.** `workflow` controls what is REQUIRED, not
> what is ALLOWED. Any skill can run at any tier. The setting changes what
> `gate-check` enforces and what completeness checks validate — never what the
> user can invoke.

> **`minimal` floor.** Even at minimal, engine choice and a filled
> **`design/game-brief.md`** are required before code starts — the brief's
> build-order field is the plan, so there is no separate `sprint-plan` step.
> Everything else can be skipped.

> **"Game brief" is a real artifact at `minimal`: `design/game-brief.md`.**
> `/brainstorm` writes it from the one-page template
> (`.claude/docs/templates/game-brief.md`) when the effective tier is `minimal`,
> in place of the full-length `design/gdd/game-concept.md` it writes at
> `standard`/`full`. The two are distinct files for distinct tiers: any check,
> gate, or glob for the `minimal` design artifact must target
> **`design/game-brief.md`**; `game-concept.md` remains the `standard`/`full`
> concept doc.

---

## GDD Required Sections per Tier

The 8 GDD sections: Overview, Player Fantasy, Detailed Rules, Formulas,
Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria.

> **Section-name alias.** "Detailed Rules" is the canonical name in the design
> standard, but the GDD template (`.claude/docs/templates/game-design-document.md`)
> and `/design-system` author this section under the heading `## Detailed Design`
> (with Core Rules / States / Interactions sub-headings). The two names denote the
> **same required section** — any skill that detects or validates section presence
> (`design-review`, `gate-check`, `adopt`, `project-stage-detect`) must accept
> either heading. Do not treat "Detailed Rules" as missing when `## Detailed
> Design` is present.

| Tier | Required GDD sections |
|------|----------------------|
| `full` | All 8 |
| `standard` | **5 required**: Overview, Detailed Rules, Edge Cases, Dependencies, Acceptance Criteria. **Conditional**: Formulas — required when the system **defines numeric rules** (rates, curves, thresholds, costs, damage, drop weights — anything a balance pass would tune); optional only when it defines none. The `Category` column is a hint, not the test. **Skipped**: Player Fantasy, Tuning Knobs. |
| `minimal` | None — `design/game-brief.md` replaces GDDs. A GDD may still be authored voluntarily. |

> **Edge Cases is required at `standard`** (it was promoted from optional —
> skipping it produced "what happens if X is null?" debt during implementation).

> **Art bible is conditional at `standard`** — required only if visual asset
> stories exist in the project. Code-focused projects skip it. At `full`, all
> 9 art bible sections are required. (`workflow_overrides.art_bible_strict:
> true` forces all 9 regardless of tier.)

---

## `workflow_overrides`

This key holds two mechanisms with **different directional rules**. Read the one
you are using — conflating them is a known and easy mistake.

```yaml
workflow_overrides:
  # --- the three boolean FLAGS: additive, stricter-only ---
  edge_cases: false          # force Edge Cases required (no-op at standard/full; relevant at minimal)
  tuning_knobs: false        # force Tuning Knobs required (relevant at standard, no-op at full)
  art_bible_strict: false    # force all 9 art bible sections regardless of asset stories

  # --- system_overrides: replaces a tier, BOTH directions ---
  system_overrides: {}       # per-system tier overrides (see below)
```

**The three boolean flags are additive on top of the chosen `workflow` level —
they make requirements STRICTER, never looser.** Each one only ever forces a
requirement *on*; setting a flag cannot opt out of a requirement the tier
imposes. There is no value of `edge_cases`, `tuning_knobs` or `art_bible_strict`
that removes anything.

**`system_overrides` is not a flag and is not additive.** It *replaces* the
effective tier for one named system, in **either** direction — see the next
section. A loosening override genuinely loosens: on a `full` project,
`system_overrides.inventory: minimal` drops that system's required sections to
zero. That is the intended design (it is what makes "one trivial system inside a
serious project" expressible), but it means an override is **not** a safe
no-op — do not leave one in place assuming the stricter-only rule protects you.

### Per-system overrides

```yaml
workflow_overrides:
  system_overrides:
    combat: full              # combat GDD requires all 8 sections regardless of project workflow
    inventory: minimal        # inventory needs no GDD — the game brief covers it (minimal = no required sections)
```

`system_overrides` is a map of `system_name: workflow_level`. The named system
uses the override tier; all other systems use the project-level `workflow`.
A skill acting on a named system resolves its effective tier via step 1 of the
resolution chain above.

---

## Effective-Tier Resolution Worked Example

Project has `modes.workflow: standard`, `workflow_overrides.system_overrides.combat: full`.

- `/design-system combat` → effective tier **full** → requires all 8 sections
- `/design-system inventory` → no override → effective tier **standard** → 5 sections + conditional Formulas
- `/gate-check` (Systems Design → Technical Setup) → requires the combat GDD at 8 sections AND every other MVP GDD at 5 sections before passing

---

## Per-Skill Behavior (the working summary — sufficient at runtime)

**Authoring** — branch on the effective tier for required sections (and, for
`brainstorm`, for which design artifact is produced — `design/game-brief.md` at
`minimal` vs `design/gdd/game-concept.md` at `standard`/`full`):
`brainstorm`, `design-system`, `art-bible`, `create-architecture`, `ux-design`,
`map-systems`, `architecture-decision`.

**Review/validation** — validate against the effective tier; missing
*required* sections block, missing *optional* sections warn:
`design-review`, `review-all-gdds`, `architecture-review`, `consistency-check`,
`content-audit`.

**Gate enforcement** — `gate-check` uses a different artifact checklist per
stage per tier (the highest-visibility impact). Each gate's own checklist and
tier reductions live in `.claude/skills/gate-check/references/gate-<phase>.md`,
and `/gate-check` loads only the one gate it is running — that is the right
place to look, not `effects-map.md`.

**Planning/implementation** — adjust artifact prerequisites:
`create-epics`, `create-stories`, `dev-story`, `story-readiness`, `story-done`,
`qa-plan`, `regression-suite`.

**Support** — adjust "what's missing" expectations so optional docs aren't
flagged as gaps: `project-stage-detect`, `adopt`, `reverse-document`,
`propagate-design-change`, `help`.

---

## Workflow Change Mid-Project

When `workflow` changes via `/settings`, emit an informational note:

> "Workflow changed from [old] to [new]. Run `/content-audit` to see what's now
> required or extra. No automatic migration — existing files stay in place."

No documents are auto-deleted, auto-generated, or blocked. The setting only
affects *new* enforcement going forward.

---

## Companion Settings

These are separate settings that compose with `workflow`. The summaries below
are what a skill needs at runtime; `effects-map.md` carries the exhaustive
per-skill tables for spec authors, and is not worth loading to apply a knob.

> **All four below are fronted by `modes.rigor`** (`docs.density`,
> `modes.story_granularity`, `qa.level`, `team.size` — along with `workflow` itself,
> and `modes.review_mode`, for six fronted knobs total). One question at `/start`
> sets all of them; setting any explicitly overrides just that one and leaves its
> siblings on the rigor level. `team.size` and `modes.review_mode` are the two that
> also stay overridable from `project.local.yaml` (they are personal-experience
> knobs, not on-disk artifacts).

- **`docs.density`** (`terse` | `balanced` | `thorough`) — `workflow` controls
  *which sections exist*; `density` controls *how deep each section goes*.
  `rigor` sets the two together; override `docs.density` alone to get
  `full` + `terse` = "all 8 sections, each compact."
- **`modes.story_granularity`** (`coarse` | `balanced` | `fine`) — how big
  each story is and how many per epic/sprint.
- **`qa.level`** (`minimal` | `standard` | `full`) — what test evidence is
  required to mark stories Done. Composes with `testing.strict`:
  `qa.level` = is evidence required; `testing.strict` = do failures block.
- **`team.size`** (`individual` | `small` | `studio`) — which agents are active by
  default. Different axis from workflow: workflow controls *what docs are
  required*, team.size controls *which agents exist to make them*.
