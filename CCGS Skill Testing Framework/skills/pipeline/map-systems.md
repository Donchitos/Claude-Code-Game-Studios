# Skill Test Spec: /map-systems

## Skill Summary

`/map-systems` decomposes a game concept into a systems index. It reads
`design/gdd/game-concept.md` (at `minimal`, `design/game-brief.md`) and the pillars,
enumerates explicit and implicit systems, maps dependencies into layers
(Foundation → Core → Feature → Presentation → Polish), assigns priority tiers
(MVP / Vertical Slice / Alpha / Full Vision), derives a design order, and writes
`design/gdd/systems-index.md` from `.claude/docs/templates/systems-index.md` after
approval. Each collaborative phase ends with an `AskUserQuestion`.

Three director gates run in sequence, each in its own phase:
TD-SYSTEM-BOUNDARY (technical-director) after the dependency map is approved,
PR-SCOPE (producer) after priorities are approved and before the write, and
CD-SYSTEMS (creative-director) after the index is written. In `lean` and `solo`
each is skipped with a named note. It is required before `/design-system` at
`standard`/`full` and optional at `minimal`. Verdicts: COMPLETE (index written) or
BLOCKED (user declined the write).

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I write" collaborative protocol language (for `design/gdd/systems-index.md`)
- [ ] Has a next-step handoff at the end (`/design-system`)
- [ ] Documents three gates at their phases: TD-SYSTEM-BOUNDARY (Phase 3), PR-SCOPE (Phase 4), CD-SYSTEMS (Phase 5, after the write)

---

## Director Gate Checks

In `full` mode, sequentially:
1. **TD-SYSTEM-BOUNDARY** (`technical-director`) — after the dependency ordering is
   approved, before priority assignment. REJECT → revise boundaries with the user;
   CONCERNS → noted inline in the index.
2. **PR-SCOPE** (`producer`) — after priorities are approved, before the index is
   written. UNREALISTIC → offer to revise tier assignments before writing;
   OPTIMISTIC → show the suggested adjustments and ask whether to apply them.
3. **CD-SYSTEMS** (`creative-director`) — after the index is written; it receives
   the index path, the pillars and core fantasy (the brief's pitch and "what they
   feel" line at `minimal`), every tier's assignments and the high-risk and
   bottleneck systems. REJECT → revise the system set before GDD authoring;
   CONCERNS → `AskUserQuestion` (`Revise the system set` / `Accept — record them
   in the index` / `Discuss further`); on Accept they are recorded as a
   `> **Creative Director Note** (<tier>): …` directly beneath the
   `## Priority Tiers` table.

Any of the three may answer NOT ASSESSED [missing input]; it is never read as
approval — the input is supplied and the gate re-run, or the run goes on with
`[GATE-ID]: NOT ASSESSED — [input]` recorded in the index.

In `lean` mode each is skipped with a note: "TD-SYSTEM-BOUNDARY skipped — Lean
mode.", "PR-SCOPE skipped — Lean mode.", "CD-SYSTEMS skipped — Lean mode."

In `solo` mode the same three notes appear with "Solo mode."

---

## Test Cases

### Case 1: Happy Path — Concept decomposed and index written in full review mode

**Fixture:**
- `project.yaml`: `modes.workflow: standard`, `modes.review_mode: full`
- `design/gdd/game-concept.md` exists with Core Mechanics naming combat and an
  inventory, and an MVP Definition section
- `design/gdd/game-pillars.md` exists with 2 pillars
- No `design/gdd/systems-index.md` exists yet
- TD-SYSTEM-BOUNDARY returns APPROVE, PR-SCOPE returns REALISTIC, CD-SYSTEMS
  returns APPROVE

**Input:** `/map-systems`

**Expected behavior:**
1. Reads the concept and pillars; globs `design/gdd/*.md`
2. Presents systems by category — name, category, one-sentence description,
   explicit or implicit (e.g. combat implies health, damage calculation, hit
   detection, combat UI) — and asks about missing / combined / unneeded systems
3. Presents the layered dependency map (bottlenecks, leaf nodes, any cycles) and
   asks "Does this dependency ordering look right?…"
4. After approval spawns TD-SYSTEM-BOUNDARY, passing the dependency graph (each
   system → what it depends on), the layer assignments, the bottleneck systems and
   any cycles with their proposed resolutions
5. Presents priority tiers with reasoning that cites this project's pillars; after
   approval spawns PR-SCOPE
6. Presents the summary (counts by category, MVP count, first 3 in design order,
   high-risk items) and asks "May I write the systems index to
   `design/gdd/systems-index.md`?"
7. Writes the index, then spawns CD-SYSTEMS with the index path, pillars/core
   fantasy, every tier's system assignments and the high-risk and bottleneck
   systems
8. Updates `production/session-state/active.md`; Verdict: COMPLETE; offers
   `/design-system [first-system-in-order]`

**Assertions:**
- [ ] Implicit systems are inferred and labelled implicit, with the reason given
- [ ] TD-SYSTEM-BOUNDARY spawns after the dependency map is approved and before priorities are presented, and is passed the full dependency graph — not a summary
- [ ] PR-SCOPE spawns after priorities are approved and before the write ask
- [ ] "May I write the systems index to `design/gdd/systems-index.md`?" is asked and nothing is written before approval
- [ ] CD-SYSTEMS spawns only after the index is written, and receives all four tiers and the high-risk systems — not the MVP list alone
- [ ] The Systems Enumeration table keeps the template's columns (`# / System Name / Category / Priority / Status / Design Doc / Depends On`) — no added column
- [ ] `active.md` is updated and the verdict is COMPLETE

---

### Case 2: Failure Path — No game concept found

**Fixture:**
- `project.yaml`: `modes.workflow: standard`
- Neither `design/gdd/game-concept.md` nor `design/game-brief.md` exists

**Input:** `/map-systems`

**Expected behavior:**
1. Phase 1 finds no concept
2. Skill outputs: "No game concept found. Run `/brainstorm` first to create one,
   then come back to decompose it into systems."
3. Skill stops — no enumeration, no gates, no index

**Assertions:**
- [ ] The "No game concept found" message is printed
- [ ] Skill recommends `/brainstorm` as the next action
- [ ] No systems enumeration is presented and no gate is spawned
- [ ] No `design/gdd/systems-index.md` is created and Verdict COMPLETE is not emitted

---

### Case 3: Director Gate — CD-SYSTEMS returns CONCERNS after the write

**Fixture:**
- Game concept and pillars exist; no index yet
- `project.yaml`: `modes.workflow: standard`, `modes.review_mode: full`
- TD-SYSTEM-BOUNDARY returns APPROVE, PR-SCOPE returns REALISTIC
- CD-SYSTEMS returns CONCERNS: an MVP system implied by the core fantasy is missing
- At the CONCERNS question the user picks `Accept — record them in the index`

**Input:** `/map-systems`

**Expected behavior:**
1. The index is written after "May I write" approval
2. CD-SYSTEMS is spawned and returns CONCERNS
3. The concerns are shown with `AskUserQuestion`: `Revise the system set` /
   `Accept — record them in the index` / `Discuss further`
4. On Accept, the concern is recorded in the index as
   `> **Creative Director Note** (MVP): …` directly beneath the `## Priority Tiers`
   table
5. Session state is updated; Verdict: COMPLETE

**Assertions:**
- [ ] CD-SYSTEMS is spawned only after the index is written, not before the write ask
- [ ] The CONCERNS go to the user as a choice — the index is not edited before the user picks
- [ ] Only the Accept choice, which names the edit, leads to the note being written; it sits directly beneath the `## Priority Tiers` table and names the MVP tier
- [ ] Had the user picked `Revise the system set`, the affected systems would be reworked with the user and the re-write of the index asked again
- [ ] CONCERNS do not trigger a full re-decomposition (that path is REJECT's)
- [ ] Verdict is COMPLETE

---

### Case 4: Edge Case — Systems index already exists

**Fixture:**
- `project.yaml`: `modes.workflow: standard`
- `design/gdd/game-concept.md` exists
- `design/gdd/systems-index.md` already exists with 8 systems, 3 of them designed

**Input:** `/map-systems`

**Expected behavior:**
1. Skill reads the existing index and presents its current status
2. Skill asks: "The systems index already exists with 8 systems (3 designed, 5 not
   started). What would you like to do?" with "Update the index with new systems",
   "Design the next undesigned system", "Review and revise priorities"
3. User chooses an action
4. Skill resumes from the existing index rather than recreating it

**Assertions:**
- [ ] Skill detects and reads the existing index before proceeding
- [ ] The system count with designed / not-started split is presented
- [ ] All three options are offered — the index is not auto-overwritten
- [ ] Skill does NOT re-run a full decomposition from scratch without the user choosing to

---

### Case 5: Director Gate — Lean and solo modes skip all three gates, noted

**Fixture (lean mode):**
- Game concept exists
- `project.yaml`: `modes.workflow: standard`, `modes.review_mode: lean`

**Lean mode expected behavior:**
1. Systems, dependencies and priorities are presented and approved as in Case 1
2. Notes "TD-SYSTEM-BOUNDARY skipped — Lean mode." and "PR-SCOPE skipped — Lean
   mode." at their phases
3. "May I write" is asked; the index is written after approval
4. Notes "CD-SYSTEMS skipped — Lean mode."
5. Session state is updated and Verdict: COMPLETE is printed

**Assertions (lean mode):**
- [ ] All three skip notes appear, each at its own phase
- [ ] No director agent is spawned
- [ ] The "May I write" ask still precedes the write
- [ ] `active.md` is updated and Verdict: COMPLETE is printed even though CD-SYSTEMS was skipped

**Fixture (solo mode):**
- Same concept, `project.yaml`: `modes.workflow: standard`, `modes.review_mode: full`
- Input: `/map-systems --review solo`

**Solo mode expected behavior:**
1. `--review solo` overrides the resolved `full`
2. The same three gates are skipped, noted with "Solo mode."

**Assertions (solo mode):**
- [ ] All three skip notes carry the "Solo mode." label
- [ ] Behavior is otherwise identical to lean mode for this skill

---

### Case 6: Guided mode — a new index is still asked for; an update is not

**Fixture (new index):**
- `project.yaml`: `modes.workflow: standard`, `modes.review_mode: solo`,
  `modes.automation: guided`
- Game concept exists; no `design/gdd/systems-index.md`

**Fixture (update):**
- Same, but `design/gdd/systems-index.md` exists and the user chose "Update the
  index with new systems"

**Input (both fixtures):** `/map-systems`

**Expected behavior:**
1. New index: after the summary, asks "May I write the systems index to
   `design/gdd/systems-index.md`?" and writes only after yes — `guided` asks
   "May I write?" for new files
2. Update: presents the summary, names `design/gdd/systems-index.md`, writes the
   update without waiting for an explicit yes, and says what it wrote

**Assertions:**
- [ ] New index at `guided`: the write ask is shown and nothing is written before it is answered
- [ ] Update at `guided`: no write ask; the summary and destination are shown before the write and the result is reported after it

---

### Case 7: Director Gate — TD-SYSTEM-BOUNDARY returns REJECT

**Fixture:**
- `project.yaml`: `modes.workflow: standard`, `modes.review_mode: full`
- Game concept and pillars exist; no index yet
- TD-SYSTEM-BOUNDARY returns REJECT: two systems share one responsibility and
  must be merged

**Input:** `/map-systems`

**Expected behavior:**
1. The dependency map is approved and TD-SYSTEM-BOUNDARY is spawned
2. The REJECT is presented, naming the two systems
3. The boundaries are revised with the user; the revised dependency map is shown
4. Only then are priorities presented and PR-SCOPE spawned

**Assertions:**
- [ ] Priority assignment does not start while the REJECT is unresolved
- [ ] The revised boundaries are shown to the user before priorities are presented
- [ ] PR-SCOPE is not spawned and nothing is written before the revision
- [ ] The REJECT is not recorded as a note and passed over — that handling is CONCERNS'

---

## Protocol Compliance

- [ ] Reads the game concept (or brief at `minimal`) and pillars before any decomposition
- [ ] `AskUserQuestion` at enumeration, dependencies, priorities and the write
- [ ] "May I write the systems index to `design/gdd/systems-index.md`?" asked before writing — at `collaborative`, and at `guided` for a new index
- [ ] CD-SYSTEMS's CONCERNS reach the written index only through the user's choice; TD-SYSTEM-BOUNDARY's CONCERNS are noted inline in the index
- [ ] Gates run sequentially at their own phases in full mode, never before their inputs exist
- [ ] Skipped gates noted by name and mode in lean/solo output
- [ ] Ends with next-step handoff: `/design-system [next-system]`

---

## Coverage Notes

- Circular dependency detection and its proposed resolutions are part of Phase 3 —
  not independently fixture-tested here.
- PR-SCOPE UNREALISTIC, the CD-SYSTEMS REJECT path and a NOT ASSESSED answer from
  any of the three gates are not given fixtures.
- `autonomous` (records the enumeration via `log_decision` and writes without
  asking) is not tested.
- The `next` and `[system-name]` argument modes (handoff to `/design-system`) are
  not tested here — they are post-index conveniences.
- `docs.density` depth (where per-system prose goes) is not fixture-locked.
