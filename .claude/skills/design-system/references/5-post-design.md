# /design-system — Phase 5: Post-Design Validation

> Part of `/design-system`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 5. Post-Design Validation

**In this file:**

- 5-pre: Author the Summary
- 5a: Self-Check
- 5a-bis: Creative Director Pillar Review
- 5b: Update Entity Registry
- 5c: Offer Design Review
- 5d: Update Systems Index
- 5e: Update Session State
- 5f: Suggest Next Steps

After all sections are written:

### 5-pre: Author the Summary

Write `## Summary` and its `> **Quick reference**` line now — after the design
exists, so the summary distils real content rather than intentions. This runs
**at every tier**, including `standard` and a voluntary `minimal` GDD: the
Summary is what lets a later skill scan 20 GDDs and decide which to read in full
(`/create-epics`, `/architecture-review`, `/review-all-gdds` all grep it), so a
GDD without it silently forces those consumers back to full reads.

- **Summary body**: 2–3 sentences — what this system is, what it does for the
  player, why it exists in this game. No jargon; a reader who has not seen the
  GDD should learn whether it is relevant to their task.
- **Quick reference**: `Layer` and `Priority` from the systems index
  (`design/gdd/systems-index.md`); `Key deps` from the Dependencies section just
  written (system names, or `None`).

Replace the `[To be designed]` Summary placeholder in the skeleton. Then apply
the section cycle's Write step as for any other section.

### 5a: Self-Check

Read back the complete GDD from file (not from conversation memory — the file is
the source of truth). Verify:
- The `## Summary` and its Quick reference are populated (not the placeholder)
- Every section **required at this system's effective tier** has real content
  (not placeholders) — §1: 8 at `full`, 5 + conditional Formulas at `standard`,
  5 at a voluntary `minimal`. Do not verify against a fixed count of 8: below
  `full` that reports a correctly-authored GDD as incomplete, which is the same
  error already corrected in the optional-sections prompt above
- Formulas reference defined variables
- Edge cases have resolutions
- Dependencies are listed with interfaces
- Acceptance criteria are testable

### 5a-bis: Creative Director Pillar Review

**Review mode check** — apply before spawning CD-GDD-ALIGN:
- `solo` → skip. Note: "CD-GDD-ALIGN skipped — Solo mode." Proceed to Step 5b.
- `lean` → skip (not a PHASE-GATE). Note: "CD-GDD-ALIGN skipped — Lean mode." Proceed to Step 5b.
- `full` → spawn as normal.

Before finalizing the GDD, spawn `creative-director` via `Agent` using gate **CD-GDD-ALIGN** (`.claude/docs/director-gates/cd-gdd-align.md`).

Pass: completed GDD file path, game pillars (from `design/gdd/game-concept.md` or `design/gdd/game-pillars.md`; if there is neither, the pitch and "what they feel" line of `design/game-brief.md`), MDA aesthetics target, and the GDD's Player Fantasy section — or, when this tier did not author one, say so.

Handle verdict per the standard rules in `director-gates.md`.
On `Revise flagged items`, or to resolve a REJECT, each flagged section runs its
section cycle again — its specialist consulted as that section's review-mode
check says — and is re-approved through its "Approve the [Section Name]
section?" widget before the Edit that writes it; then record `REVISED [date]`.
A `NOT ASSESSED` answer is never an approval: name the missing input, then
supply it and re-run the gate, or record `NOT ASSESSED`.
After resolution, record the verdict in the GDD Status header:
`> **Creative Director Review (CD-GDD-ALIGN)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date] / NOT ASSESSED [date] — [missing input]`

---

### 5b: Update Entity Registry

Scan the completed GDD for cross-system facts that should be registered:
- Named entities (enemies, NPCs, bosses) with stats or drops
- Named items with values, weights, or categories
- Named formulas with defined variables and output ranges
- Named constants referenced by value in more than one place

**First check the registry exists** — §2a reads it *"if it exists"*, and this
step never carried the same guard. At `standard` and below the file is often
absent, and a grep against a missing path returns nothing, which is
indistinguishable from "no candidate is registered yet":

- **Absent** — say so, and ask whether to create it:
  *"`design/registry/entities.yaml` does not exist. May I create it with these
  [N] entries?"* If the user declines, skip 5b and say the registry was not
  written — do not treat the skip as a clean pass.
- **Present but empty** — every list is `[]`, or the only matches are inside
  comment blocks. Treat it as present, register the candidates, but say which
  state you found: *"registry exists and is empty — all [N] entries are new."*
  The shipped template's comments carry fully-formed examples referencing
  `design/gdd/inventory.md` with real-looking values (`base_inventory_slots: 20`,
  `gold_carry_limit: 9999`), so §2a's registry greps return **comment
  lines** on an empty registry — and §2d would then present those invented numbers to the user as
  *"These values are locked."* Match entries under a live `entities:`/`items:`/
  `formulas:`/`constants:` key, never a commented example.
- **Present** — for each candidate, check whether it is already registered:

```
Grep pattern="  - name: [candidate_name]" path="design/registry/entities.yaml"
```

Present a summary:
```
Registry candidates from this GDD:
  NEW (not yet registered):
    - [entity_name] [entity]: [attribute]=[value], [attribute]=[value]
    - [item_name] [item]: [attribute]=[value], [attribute]=[value]
    - [formula_name] [formula]: variables=[list], output=[min–max]
  ALREADY REGISTERED (referenced_by will be updated):
    - [constant_name] [constant]: value=[N] ← matches registry ✅
```

Ask: "May I update `design/registry/entities.yaml` with these [N] new entries
and update `referenced_by` for the existing entries?" (If the file was absent
and the user approved creating it, the wording is *create*, not *update*, and
there are no `referenced_by` arrays to merge.)

If yes: append new entries and update `referenced_by` arrays. Never modify
existing `value` / attribute fields without surfacing it as a conflict first.

### 5c: Offer Design Review

Present a completion summary:

> **GDD Complete: [System Name]**
> - Sections written: [list]
> - Provisional assumptions: [list any assumptions about undesigned dependencies]
> - Cross-system conflicts found: [list or "none"]

> **To validate this GDD, open a fresh Claude Code session and run:**
> `/design-review design/gdd/[system-name].md`
>
> **Never run `/design-review` in the same session as `/design-system`.** The reviewing
> agent must be independent of the authoring context. Running it here would inherit
> the full design history, making independent critique impossible.

**NEVER offer to run `/design-review` inline.** Always direct the user to a fresh window.

### 5d: Update Systems Index

After the GDD is complete (and optionally reviewed):

**First check the systems index exists.** §2a skips it at `minimal` because it is
never written at that tier, and this step never carried the same guard — the same
class of bug §5b was patched for. It bites hardest on a `minimal` project with a
`system_overrides` bump, where the effective tier is `standard` or `full` and
nothing else in §5 hints the file may be absent.

- **Absent** — say so in one line (*"no `design/gdd/systems-index.md` at this
  workflow tier; nothing to update"*) and skip to §5e. Do **not** offer to create
  one: `/map-systems` owns that file, and a stub written here would be a systems
  index listing exactly one system.
- **Present** — continue:

- Read the systems index
- Update the target system's row:
  - If design-review was run and verdict is APPROVED: Status → "Approved"
  - If design-review was run and verdict is NEEDS REVISION or MAJOR REVISION NEEDED: Status → "Needs Revision" (that exact string — `/design-review` sets "In Review" only once the revisions are applied)
  - If design-review was skipped: Status → "Designed" (pending review)
  - If the user chose "I'll review it myself first": Status → "Designed"
  - Design Doc: link to `design/gdd/[system-name].md`
- Update the Progress Tracker counts

Ask: "May I update the systems index at `design/gdd/systems-index.md`?"

### 5e: Update Session State

Update `production/session-state/active.md` with:
- Task: [system-name] GDD
- Status: Complete (or In Review if design-review was run)
- File: design/gdd/[system-name].md
- Sections: [list the sections actually authored, by name] — **never a fixed
  count**; §5a forbids verifying against `/8`, and the same reasoning applies to
  recording it. Below `full` a correctly-authored GDD has fewer than 8 sections,
  and writing "All 8 written" into session state makes the next reader believe
  a complete GDD is incomplete
- Next: [suggest next system from design order]

### 5f: Suggest Next Steps

Use `AskUserQuestion`:
- "What's next?"
  - Options:
    - "Run `/consistency-check` — verify this GDD's values don't conflict with existing GDDs (recommended before designing the next system)"
    - "Design next system ([next-in-order])" — if undesigned systems remain
    - "Fix review findings" — if design-review flagged issues
    - "Stop here for this session"
    - "Run `/gate-check`" — if enough MVP systems are designed

---
