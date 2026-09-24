---
name: design-review
description: "Reviews one design document for completeness, internal consistency, implementability, and design standards. Before handing to programmers."
argument-hint: "[path-to-design-doc] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/design-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.


## Phase 0: Parse Arguments


See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`workflow`** for the GDD under review — use the `system_overrides` row for `<system>` if the block lists one, else the project value. Validation scope follows the tier:
- `full` — all 8 sections validated; any missing section blocks approval.
- `standard` — the 5 required sections (Overview, Detailed Rules, Edge Cases,
  Dependencies, Acceptance Criteria) block if missing; Formulas blocks only when
  the system defines numeric rules (rates, curves, thresholds, costs — the
  category is a hint, not the test); Player Fantasy and
  Tuning Knobs are advisory (warn, never block) unless `workflow_overrides`
  require them.
- `minimal` — no GDD is expected; if one exists, validate the 5 standard
  sections advisorily.

Resolved mode controls how thorough this review is:

- **`full`**: Complete review — all phases + specialist agent delegation (Phase 3b)
- **`lean`**: All phases, no specialist agents — faster, single-session analysis
- **`solo`**: Phases 1-4 only, no delegation, no Phase 5 next-step prompt — use when called from within another skill

---

## Phase 1: Load Documents

**Freshness check first — a re-review of an unchanged document costs full
price (~46k tokens, measured) and reproduces the same verdict.** Run:

```
Bash: bash .claude/scripts/review-receipts.sh check "design/gdd/reviews/[doc-name]-review-log.md" "[target-doc-path]" "design/registry/entities.yaml"
```

The registry is in the check because this review consults it for
cross-document facts — an unchanged GDD reviewed against a *changed*
registry can reach different conclusions, so the skip is only safe when
**every** listed line reads `UNCHANGED` (an absent registry simply doesn't
appear in the output and doesn't block the skip).

- **All `UNCHANGED`** and the log's latest entry carries a verdict — surface it:
  *"This document is byte-identical to its last review on [date] (verdict:
  [verdict])."* If that verdict was APPROVED, offer via `AskUserQuestion`:
  `[A] Use the prior verdict (Recommended)` / `[B] Re-review anyway` —
  `guided` proceeds with [A] and notes it; `autonomous` logs via
  `log_decision` and uses the prior verdict. If it was NEEDS REVISION or
  MAJOR REVISION NEEDED, say so plainly: the document has not changed since
  it failed review — the prior findings stand; revising the document is the
  next step, not re-reviewing it. Offer to display the prior findings from
  the log.
- **Only the registry line reads `CHANGED`** (doc `UNCHANGED`) — the prior
  verdict stands except for cross-document facts: re-verify the doc's
  registry-sourced values against the new registry and re-issue the verdict;
  escalate to a full re-review only if a conflict appears.
- **Target doc `CHANGED` or `NEW`, or `RECEIPT: NONE`** — proceed with the
  full review below. **Do not offer a partial/delta re-review that skips
  reading or re-analyzing unchanged sections.** Measured against a full review:
  three independent designs (a straightforward section-scoped pass, one with
  an explicit forced whole-document scan step, and one gated on a
  genuinely thorough two-round prior review) each caught only 2 of 6 real
  defects a full review found on the same document, and the most
  careful version cost *more* tokens than the full review while catching
  the same reduced fraction. "Unchanged since last review" only means
  byte-identical to what was reviewed then — it says nothing about whether
  that prior pass was itself complete, and no amount of "scan everything
  anyway" instruction reliably overcame a model's attention naturally
  narrowing to the flagged change.

Read the target design document in full. Read CLAUDE.md to understand project context and standards.

**For cross-document facts, prefer the registry over sibling GDDs.** If
`design/registry/entities.yaml` exists **and lists entries for this system**,
grep it — these are the established facts this GDD must not contradict, and they
replace reading sibling GDDs to rediscover them:
```
Grep pattern="source: design/gdd/[system].md" path="design/registry/entities.yaml" output_mode="content" -A 6
Grep pattern="design/gdd/[system].md" path="design/registry/entities.yaml" output_mode="content" -B 8
```
The first finds entries this system **owns** — the `-A 6` context includes their
`referenced_by:` block. The second finds entries that **reference** this system —
`referenced_by:` is a block sequence (the key and its paths are on separate
lines), so match the path with `-B 8` context to see the owning entry, not a
`referenced_by.*name` one-liner (which never matches the block form).

**If `design/registry/entities.yaml` does not exist, or lists no entry for this
system** — the file ships as an empty stub, so this is the default until
`/design-system` has populated it — fall back to reading the related GDDs the
target doc names in its Dependencies section. Bound the read to those, not to
everything "implied". Do not glob-read all of `design/gdd/`.

**Dependency graph validation:** For every system listed in the Dependencies section, use Glob to check whether its GDD file exists in `design/gdd/`. Flag any that don't exist yet — these are broken references that downstream authors will hit.

**Lore/narrative alignment:** If `design/gdd/game-concept.md` or any file in `design/narrative/` exists, read it. Note any mechanical choices in this GDD that contradict established world rules, tone, or design pillars. Pass this context to `game-designer` in Phase 3b.

**Prior review check:** Check whether `design/gdd/reviews/[doc-name]-review-log.md` exists. If it does, read the most recent entry — note what verdict was given and what blocking items were listed. This session is a re-review; track whether prior items were addressed.

---

## Phase 2: Completeness Check

**Step 2a — gather section presence deterministically (no document read):**

```
Bash: bash .claude/scripts/gdd-structure-check.sh [target-doc-path]
```

It prints a `PRESENT:` list and, when applicable, an `ABSENT:` list. It reports
**presence only** and makes no REQUIRED/ADVISORY judgment — that is Step 2b's
job. It already accepts `## Detailed Design` as satisfying the `Detailed Rules`
requirement, so do not flag that as missing.

**Step 2b — apply the tier.** Using the Step 2a lists, evaluate against the
Design Document Standard checklist below. **Mark each section REQUIRED or
ADVISORY per the resolved workflow tier (Phase 0).** A missing REQUIRED section
blocks approval; a missing ADVISORY section is surfaced as a recommendation but
does not block.

A section reported PRESENT can still fail review if it is an empty heading —
spot-read any section the verdict actually turns on.

- [ ] Has Overview section (one-paragraph summary) — REQUIRED at all tiers
- [ ] Has Player Fantasy section (intended feeling) — REQUIRED at `full`; ADVISORY at `standard`
- [ ] Has Detailed Rules section (unambiguous mechanics) — REQUIRED at `full`/`standard`. The GDD template titles this section `## Detailed Design` (it carries Core Rules / States / Interactions sub-headings); accept **either** heading as satisfying this requirement — do not flag "Detailed Rules" as missing when a `## Detailed Design` section is present.
- [ ] Has Formulas section (all math defined with variables) — REQUIRED at `full`; at `standard` REQUIRED whenever the system defines numeric rules (rates, curves, thresholds, costs, damage, drop weights), else ADVISORY. The system's `Category` is a hint, not the test — do not clear this on a category token alone
- [ ] Has Edge Cases section (unusual situations handled) — REQUIRED at `full`/`standard`
- [ ] Has Dependencies section (other systems listed) — REQUIRED at `full`/`standard`
- [ ] Has Tuning Knobs section (configurable values identified) — REQUIRED at `full`; ADVISORY at `standard` unless `workflow_overrides.tuning_knobs`
- [ ] Has Acceptance Criteria section (testable success conditions) — REQUIRED at `full`/`standard`

---

## Phase 3: Consistency and Implementability

**Internal consistency:**
- Do the formulas produce values that match the described behavior?
- Do edge cases contradict the main rules?
- Are dependencies bidirectional (does the other system know about this one)?

**Implementability:**
- Are the rules precise enough for a programmer to implement without guessing?
- Are there any "hand-wave" sections where details are missing?
- Are performance implications considered?

**Cross-system consistency:**
- Does this conflict with any existing mechanic?
- Does this create unintended interactions with other systems?
- Is this consistent with the game's established tone and pillars?

---

## Phase 3b: Adversarial Specialist Review (full mode only)

**Skip this phase in `lean` or `solo` mode.**

**This phase is MANDATORY in full mode.** Do not skip it.

**Before spawning any agents**, print this notice:
> "Full review: spawning specialist agents in parallel. This typically takes 8–15 minutes. Use `--review lean` for faster single-session analysis."

### Step 1 — Identify all domains the GDD touches

Using the GDD **already loaded in Phase 1** — do not re-read it — identify every domain present. A GDD can touch multiple domains simultaneously — be thorough. Common signals:

| If the GDD contains... | Spawn these agents |
|------------------------|-------------------|
| Costs, prices, drops, rewards, economy | `economy-designer` |
| Combat stats, damage, health, DPS | `game-designer`, `systems-designer` |
| AI behaviour, pathfinding, targeting | `ai-programmer` |
| Level layout, spawning, wave structure | `level-designer` |
| Player progression, XP, unlocks | `economy-designer`, `game-designer` |
| UI, HUD, menus, player-facing displays | `ux-designer`, `ui-programmer` |
| Dialogue, quests, story, lore | `narrative-director` |
| Animation, feel, timing, juice | `gameplay-programmer` |
| Multiplayer, sync, replication | `network-programmer` |
| Audio cues, music triggers | `audio-director` |
| Performance, draw calls, memory | `performance-analyst` |
| Engine-specific patterns or APIs | Primary engine specialist (`<engine>-specialist` from `engine.name` — Godot→`godot-specialist`, Unity→`unity-specialist`, Unreal→`unreal-specialist`; fall back to the Primary line of `## Engine Specialists` in `technical-preferences.md`) |
| Acceptance criteria, test coverage | `qa-lead` |
| Data schema, resource structure | `systems-designer` |
| Any gameplay system | `game-designer` (always) |

Spawn `game-designer` for all GDDs that describe gameplay mechanics or player-facing rules.
Spawn `systems-designer` for all GDDs that contain formulas or system interaction rules.
These are the most common baselines — but not required for pure UI specs, audio specs, or lore documents. Use the domain table above to determine which specialists are truly relevant.

### Step 2 — Spawn all relevant specialists in parallel

**CRITICAL: `Agent` in this skill spawns a SUBAGENT — a separate independent Claude session
with its own context window. It is NOT task tracking. Do NOT simulate specialist
perspectives internally. Do NOT reason through domain views yourself. You MUST issue
actual `Agent` calls. A simulated review is not a specialist review.**

Issue all `Agent` calls simultaneously. Do NOT spawn one at a time.

**Prompt each specialist adversarially:**
> "Here is the GDD for [system] and the main review's structural findings so far.
> Your job is NOT to validate this design — your job is to find problems.
> Challenge the design choices from your domain expertise. What is wrong,
> underspecified, likely to cause problems, or missing entirely?
> Be specific and critical. Disagreement with the main review is welcome."

**Additional instructions per agent type:**

- **`game-designer`**: Anchor your review to the Player Fantasy stated in Section B of this GDD. Does this design actually deliver that fantasy? Would a player feel the intended experience? Flag any rules that serve implementability but undermine the stated feeling.

- **`systems-designer`**: For every formula in the GDD, plug in boundary values (minimum and maximum plausible inputs). Report whether any outputs go degenerate — negative values, division by zero, infinity, or nonsensical results at the extremes.

- **`qa-lead`**: Review every acceptance criterion. Flag any that are not independently testable — phrases like "feels balanced", "works correctly", "performs well" are not ACs. Suggest concrete rewrites for any that fail this test.

### Step 3 — Senior lead review

After all specialists respond, spawn `creative-director` as the **senior reviewer**:
- Provide: the GDD, all specialist findings, any disagreements between them
- Ask: "Synthesise these findings. What are the most important issues? Do you agree with the specialists? What is your overall verdict on this design?"
- The creative-director's synthesis becomes the **final verdict** in Phase 4.

### Step 4 — Surface disagreements

If specialists disagree with each other or with the creative-director, do NOT silently pick one view. Present the disagreement explicitly in Phase 4 so the user can adjudicate.

Mark every finding with its source: `[game-designer]`, `[economy-designer]`, `[creative-director]` etc.

---

## Phase 4: Output Review

```
## Design Review: [Document Title]
Specialists consulted: [list agents spawned]
Re-review: [Yes — prior verdict was X on YYYY-MM-DD / No — first review]

### Completeness: [X/N sections present, where N is the count REQUIRED at this project's `modes.workflow`]
[List only sections missing that are REQUIRED at this tier. Mark ADVISORY gaps
separately as "advisory at `standard`" — do not list them as missing.]

> **N is not 8 unless `workflow: full`.** The tier table earlier in this skill is
> authoritative: 8 required at `full`, 5 at `standard` (+ Formulas when the system
> defines numeric rules), 0 at `minimal`. Hardcoding `/8` here
> reintroduces the tier confusion in the presentation layer after the logic
> layer already handles it — reporting a `standard` project as "5/8 missing Player
> Fantasy, Formulas, Tuning Knobs" warns about three sections that project's own
> configuration says it does not need, which trains the reader to ignore the
> review.

### Dependency Graph
[List each declared dependency and whether its GDD file exists on disk]
- ✓ enemy-definition-data.md — exists
- ✗ loot-system.md — NOT FOUND (file does not exist yet)

### Required Before Implementation
[Numbered list — blocking issues only. Each item tagged with source agent.]

### Recommended Revisions
[Numbered list — important but not blocking. Source-tagged.]

### Specialist Disagreements
[Any cases where agents disagreed with each other or with the main review.
Present both sides — do not silently resolve.]

### Nice-to-Have
[Minor improvements, low priority.]

### Senior Verdict [creative-director]
[Creative director's synthesis and overall assessment.]

### Scope Signal
Estimate implementation scope based on: dependency count, formula count,
systems touched, and whether new ADRs are required.
- **S** — single system, no formulas, no new ADRs, <3 dependencies
- **M** — moderate complexity, 1-2 formulas, 3-6 dependencies
- **L** — multi-system integration, 3+ formulas, may require new ADR
- **XL** — cross-cutting concern, 5+ dependencies, multiple new ADRs likely
Label clearly: "Rough scope signal: M (producer should verify before sprint planning)"

### Verdict: [APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED / NOT ASSESSED]

> **`NOT ASSESSED` when the review could not actually be performed.**
> The other three verdicts are all claims about the design's quality, so each one
> asserts that the document was read and judged. Use `NOT ASSESSED` instead when
> the target document is absent, unreadable, or empty of the sections being
> reviewed, or when a document it depends on is missing so the criteria cannot be
> applied. **Name what was unavailable and which skill produces it.**
>
> `APPROVED` is the dangerous default here: a review that could not find its
> input has not approved anything, and this verdict is consumed downstream as a
> sign-off. `NOT ASSESSED` outranks `APPROVED` in any aggregate — it does not
> outrank the two revision verdicts, because a known problem is more actionable
> than an unknown one.
```

This skill is read-only — no files are written during Phase 4.

---

## Phase 5: Next Steps

Use `AskUserQuestion` for ALL closing interactions. Never plain text.

**First widget — what to do next:**

If APPROVED (first-pass, no revision needed), proceed directly to the systems-index widget, review-log widget, then the final closing widget. Do not show a separate "what to do" widget — the final closing widget covers next steps.

If NEEDS REVISION or MAJOR REVISION NEEDED, options:
- `[A] Revise the GDD now — address blocking items together`
- `[B] Stop here — revise in a separate session`
- `[C] Accept as-is and move on (only if all items are advisory)`

**If user selects [A] — Revise now:**

Work through all blocking items, asking for design decisions only where you cannot resolve the issue from the GDD and existing docs alone. Group all design-decision questions into a single multi-tab `AskUserQuestion` before making any edits — do not interrupt mid-revision for each blocker individually.

After all revisions are complete, show a summary table (blocker → fix applied) and use `AskUserQuestion` for a **post-revision closing widget**:

- Prompt: "Revisions complete — [N] blockers resolved. What next?"
- Note current context usage: if context is above ~50%, add: "(Recommended: /clear before re-review — this session has used X% context. A full re-review runs 5 agents and needs clean context.)"
- Options:
  - `[A] Re-review in a new session — run /design-review [doc-path] after /clear`
  - `[B] Accept revisions and mark Approved — update systems index, skip re-review`
  - `[C] Move to next system — /design-system [next-system] (#N in design order)`
  - `[D] Stop here`

In collaborative and guided modes, never end the revision flow with plain text —
always close with this widget. In autonomous mode, summarize the outcome and
record via `log_decision`.

**Second widget — tracking records (combined, for APPROVED path):**

When the verdict is APPROVED, use a single `AskUserQuestion` with `multiSelect: true` to batch the two tracking updates:
- Prompt: "Verdict: APPROVED. I can update the tracking records now. Select any you'd like me to complete:"
- Options:
  - `Update systems-index.md status to 'Approved' for [system]`
  - `Append approval entry to design/gdd/reviews/[doc-name]-review-log.md`

If the review-log option is selected, append the same format as below. Execute both selected actions before showing the final closing widget.

When the verdict is NEEDS REVISION or MAJOR REVISION NEEDED, use separate widgets as before:

Use a second `AskUserQuestion`:
- Prompt: "May I update `design/gdd/systems-index.md` to mark [system] as [In Review / Approved]?"
- Options: `[A] Yes — update it` / `[B] No — leave it as-is`

Use a third `AskUserQuestion`:
- Prompt: "May I append this review summary to `design/gdd/reviews/[doc-name]-review-log.md`? This creates a revision history so future re-reviews can track what changed."
- Options: `[A] Yes — append to review log` / `[B] No — skip`

If yes, append an entry in this format:
```
## Review — [YYYY-MM-DD] — Verdict: [APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED]
Scope signal: [S/M/L/XL]
Specialists: [list]
Blocking items: [count] | Recommended: [count]
Summary: [2-3 sentence summary of key findings from creative-director verdict]
Prior verdict resolved: [Yes / No / First review]
Findings:
- [BLOCKING] [section]: [one-line finding]
- [RECOMMENDED] [section]: [one-line finding]
[output of: Bash: bash .claude/scripts/review-receipts.sh hash "[target-doc-path]" — plus "design/registry/entities.yaml" if the registry file exists]
```

Findings rules: one line per finding, named by the section it lives in;
write `- none` when the verdict carried no findings. This is documentation
for a human reader of the revision history, not a mechanism the skill reads
back — a delta re-review that skipped re-analyzing unchanged sections was
tried and reverted (see Phase 1) after measuring it against a full review.

The hash line is the receipt Phase 1 reads on the next run to detect a
byte-identical re-review — the one form of skip that's actually safe,
because the input is provably the same, not merely believed to be adequately
covered by a prior pass. Always include it, whatever the verdict — an
unchanged document that previously FAILED review is exactly the case where
skipping a redundant re-review saves the most (the prior findings stand
verbatim).

---

**Final closing widget — always show after all file writes complete:**

Once the systems-index and review-log widgets are answered, check project state and show one final `AskUserQuestion`:

Before building options, read:
- `design/gdd/systems-index.md` — find any system with Status: In Review or NEEDS REVISION (other than the one just reviewed)
- Count `.md` files in `design/gdd/` (excluding game-concept.md, systems-index.md) to determine if `/review-all-gdds` is worth offering (≥2 GDDs)
- Find the next system with Status: Not Started in design order

Build the option list dynamically — only include options that are genuinely next:
- `[_] Run /design-review [other-gdd-path] — [system name] is still [In Review / NEEDS REVISION]` (include if another GDD needs review)
- `[_] Run /consistency-check — verify this GDD's values don't conflict with existing GDDs` (always include if ≥1 other GDD exists)
- `[_] Run /review-all-gdds — holistic design-theory review across all designed systems` (include if ≥2 GDDs exist)
- `[_] Run /design-system [next-system] — next in design order` (always include, name the actual system)
- `[_] Stop here`

Assign letters A, B, C… only to included options. Mark the most pipeline-advancing option as `(recommended)`.

In collaborative and guided modes, never end the skill with plain text after
file writes — always close with this widget. In autonomous mode, print the next
step and record via `log_decision`.
