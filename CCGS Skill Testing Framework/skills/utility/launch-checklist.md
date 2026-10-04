# Skill Test Spec: /launch-checklist

## Skill Summary

`/launch-checklist` generates a launch-readiness checklist across code, content,
QA, store, legal, infrastructure, community and operations, scoped to the
project. It is handed the resolved `rigor`, `project.stage`, `platform.cert_tier`
and `automation`, and scopes by them: out-of-reach phases are declared out of
scope, `rigor: minimal` drops process-weight items, and the Platform
Certification section is emitted **only** for the `cert_tier` value
(`none | itch | steam | console`). An unset `cert_tier` is a question, not a
licence to emit every track; if it cannot be determined the section is marked
`NOT ASSESSED — cert tier unknown`.

Phase 2 reads `CLAUDE.md`, the latest milestone, any existing checklist in
`production/releases/` and the content calendar. Phase 3 scans the code root for
TODO/FIXME/HACK, debug output, placeholder assets and hardcoded dev values, and
reports every scan with its denominator (`scanned [N] files, [M] hits`) or
`NOT ASSESSED — [reason]`; an unassessable item is written `- [?]` with a legend,
never a bare box or tick. The bug rows follow `workflow`: S1 and S2 (or a
documented exception), and at `full` S1–S3 with no exceptions. Phase 4b asks one
`AskUserQuestion` per section about the items no scan or file settled, each
answered yes / no / not yet / N/A: yes ticks it, no or not yet is a failed item
(Blocking, or Conditional with a workaround or accepted risk), N/A leaves it out;
it is skipped, and says so, in `dry-run` and in `autonomous` mode. The checklist
ends in a Go / No-Go section. **Blocking Items** are every FAIL or unresolved
finding with no documented workaround or accepted risk; **Conditional Items** are
shortfalls with a documented workaround or an explicitly accepted risk. **Overall
Status** is computed from them, first match wins: `NOT READY` (any blocking item)
→ `NOT ASSESSED` (any `[?]` item, `NOT ASSESSED` section or unconfirmed item, each
named) → `CONDITIONAL` (any conditional item) → `READY`. Unless the argument is
`dry-run`, it asks "May I write this to
`production/releases/launch-checklist-[date].md`?" and creates nothing — not
even the directory — before the answer. Next steps: `/gate-check release` first
if `project.stage` is not `Release` (`Polish`, an earlier stage, or unset), then
`/team-release`. No director gates are spawned.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: READY, CONDITIONAL, NOT ASSESSED, NOT READY (Overall Status, first match NOT READY → NOT ASSESSED → CONDITIONAL → READY), and NOT ASSESSED for unassessable scans and cert tier
- [ ] Contains "May I write" language before writing the checklist, and creates no file or directory before the answer
- [ ] Has a Phase 4b that asks one `AskUserQuestion` per section, answers yes / no / not yet / N/A, with no / not yet a failed item and N/A excluded
- [ ] Has a next-step handoff (`/gate-check release` only when `project.stage` is not `Release`, and `/team-release`)

---

## Director Gate Checks

None. `/launch-checklist` has no `Agent` tool and spawns no director. The
"Sign-Offs Required" list (Creative Director, Technical Director, QA Lead,
Producer, Release Manager) is checklist text for humans, coordinated later via
`/team-release`; the formal gate verdict comes from `/gate-check`.

---

## Test Cases

### Case 1: Happy Path — Steam project, clean scans, every section confirmed, READY

**Fixture:**
- `project.yaml`: `project.stage: Release`, `modes.rigor: standard`, `platform.cert_tier: steam`,
  engine Godot (code root `src/`); a single-player game with no servers
- `src/` has 40 source files with no TODO/FIXME/HACK, no debug output, no placeholder or hardcoded dev values
- `assets/` exists with final assets
- `production/releases/` does not exist yet
- In Phase 4b the user answers `Yes — all of them` for every section, except the
  Infrastructure question, where `Some differ` gives each Servers item N/A and
  every Analytics and Monitoring item yes

**Input:** `/launch-checklist 2026-11-01`

**Expected behavior:**
1. Target Launch reads 2026-11-01
2. Phase 3 reports each scan as `scanned [N] files, 0 hits`
3. Platform Certification contains only the Steam block (Steamworks SDK, store page,
   depot build, achievements, common content rules) plus the every-tier accessibility row
4. The soak-test item asks for the longest soak `/soak-test` runs (or a longer
   one run by hand), not a fixed duration `/soak-test` cannot produce
5. Phase 4b asks one `AskUserQuestion` per section, listing only the items no
   scan or file settled (not the Phase 3 counts), each answered yes / no /
   not yet / N/A
6. The confirmed items are ticked `(confirmed by the user)`; the Servers items are
   written `- N/A — [item]` and left out of the status. Nothing is Blocking,
   Conditional or unconfirmed, so the first-match rule gives READY
7. Skill presents the checklist with a summary (Overall Status, total items, blocking
   count, conditional count, not-assessed count, departments with incomplete sections)
8. Asks "May I write this to `production/releases/launch-checklist-[date].md`?";
   `production/releases/` is not created before the answer
9. Next steps: `/team-release` — the stage already reads `Release`, so `/gate-check`
   is not offered

**Assertions:**
- [ ] Every Phase 3 scan line shows its denominator (`scanned [N] files, [M] hits`)
- [ ] No console (TRC/Lotcheck) or itch.io items appear
- [ ] The soak-test item does not require a soak longer than `/soak-test` offers
- [ ] Phase 4b asks at most one question per section, and no Phase 3 count is asked about
- [ ] Overall Status is READY — every item is ticked on evidence or on a Phase 4b answer, or marked N/A
- [ ] The summary gives total, blocking, conditional and not-assessed counts
- [ ] "May I write" names `production/releases/launch-checklist-[date].md`, and no directory exists before the user answers it
- [ ] Next steps name `/team-release` and do not offer `/gate-check`

---

### Case 2: Blocking Findings — FIXMEs and debug output

**Fixture:**
- As Case 1, but `src/` contains 3 `FIXME` comments and one `print()` debug call in production code
- `src/` also has one `HACK` comment whose justification is documented beside it

**Input:** `/launch-checklist 2026-11-01`

**Expected behavior:**
1. Phase 3 counts the FIXMEs with their locations and finds the debug output
2. Code Quality shows "FIXME count: 3 (zero required)" and the "No debug output" item unticked
3. These appear under Blocking Items — findings with no workaround or accepted risk
4. The justified HACK appears under Conditional Items, with its justification
5. Overall Status is NOT READY — a blocking item outranks everything else
6. "May I write" is still asked before saving

**Assertions:**
- [ ] FIXME count is 3, with file locations
- [ ] The debug `print()` is reported and its item is not ticked
- [ ] Blocking Items lists the FIXMEs and the debug output
- [ ] The documented HACK is under Conditional Items, not Blocking Items
- [ ] Overall Status is NOT READY (not READY, CONDITIONAL or NOT ASSESSED)

---

### Case 3: Cert Tier Unset — Ask, do not emit every track

**Fixture:**
- `project.yaml`: `project.stage: Release`, `modes.rigor: standard`, no `platform.cert_tier`
- Config block shows `platform.cert_tier: (unset -- ask which platforms are in scope)`

**Input:** `/launch-checklist 2026-11-01`

**Expected behavior:**
1. Skill asks which platforms are in scope instead of emitting all certification tracks
2. If the user answers, only the matching tier block is emitted
3. If it cannot be determined, the section is marked `NOT ASSESSED — cert tier unknown`
4. Unset is not treated as `none` — the section is not silently omitted

**Assertions:**
- [ ] Skill asks which platforms are in scope
- [ ] Console, Steam and itch.io blocks are never all emitted together
- [ ] Without an answer, the section reads `NOT ASSESSED — cert tier unknown`
- [ ] The "omitted — cert_tier is 'none'" line does not appear

---

### Case 4: Nothing to Scan — `[?]` items, not green ticks

**Fixture:**
- `project.yaml`: `project.stage: Release`, `platform.cert_tier: itch`, engine Godot
- `src/` exists but is empty; no `assets/` directory

**Input:** `/launch-checklist 2026-11-01`

**Expected behavior:**
1. Phase 3 reports the code scans as `NOT ASSESSED — no source files` (or
   `directory empty`) and the placeholder-asset scan as
   `NOT ASSESSED — no asset folder`, instead of zero hits
2. The affected items (e.g. "All placeholder art replaced with final assets",
   "No debug output in production code") are written `- [?]`
3. The legend `[?] = not assessed — the input to this check was absent` is included
4. Platform Certification contains only the itch.io block
5. Nothing was found, so Blocking Items is empty — and the `[?]` items make the
   Overall Status **NOT ASSESSED**, naming the scans that could not run, never
   READY

**Assertions:**
- [ ] No scan with no input is reported as zero hits
- [ ] "All placeholder art replaced with final assets" is `- [?]`, not ticked and not `- [ ]`
- [ ] The `[?]` legend appears
- [ ] No Steamworks or console items appear
- [ ] Overall Status is NOT ASSESSED and names the `[?]` scans (code and placeholder-asset scans); it is not READY or CONDITIONAL

---

### Case 5: Director Gate Check — Dry run, cert tier `none`

**Fixture:**
- `project.yaml`: `project.stage: Release`, `platform.cert_tier: none`
- Code root with source files

**Input:** `/launch-checklist dry-run`

**Expected behavior:**
1. Target Launch reads DRY RUN
2. Platform Certification is replaced by the one line
   `Platform Certification: omitted — cert_tier is 'none' (internal/jam release).`
3. Phase 4b is skipped and the output says so; the items it would have asked stay
   unconfirmed, so the Overall Status is NOT ASSESSED
4. The checklist is presented but no "May I write" ask is made and no file is written
5. No director or other agent is spawned; no gate IDs appear
6. Next steps name `/team-release`; the stage reads `Release`, so `/gate-check` is not offered

**Assertions:**
- [ ] The "omitted — cert_tier is 'none'" line appears and no certification rows are emitted
- [ ] No Phase 4b question is asked in dry-run, the skip is stated, and the Overall Status is NOT ASSESSED
- [ ] No "May I write" ask and no file written in dry-run mode
- [ ] No director gate is invoked and no gate skip messages appear
- [ ] Next steps name `/team-release` and do not offer `/gate-check`

---

### Case 6: Stage Still Polish — Answers Make It CONDITIONAL, or NOT ASSESSED

**Fixture:**
- As Case 1, but `project.stage: Polish` and `modes.rigor: full` (`workflow: full`)
- Variant A: in Phase 4b the Marketing items all get yes except "Press/influencer
  review keys distributed", answered `not yet` — the user says the keys go out on
  launch morning and the producer accepts the risk; every other section is `Yes —
  all of them` (Servers N/A as in Case 1)
- Variant B: as Variant A, but the user leaves the Legal question unanswered

**Input:** `/launch-checklist 2026-11-01`

**Expected behavior:**
1. The Testing bug rows are the `workflow: full` ones: zero S1, and zero S2 and S3
   with no exceptions
2. Variant A: the press-keys item is a failed item with an accepted risk, so it goes
   under Conditional Items naming who accepted it; nothing is Blocking or
   unconfirmed; Overall Status is CONDITIONAL
3. Variant B: the Legal items stay unconfirmed and are named; Overall Status is
   NOT ASSESSED (it outranks CONDITIONAL)
4. Next steps: run `/gate-check release` first — the stage still reads `Polish` —
   then `/team-release`

**Assertions:**
- [ ] A `not yet` answer is never ticked; with an accepted risk it is listed under Conditional Items
- [ ] Variant A's Overall Status is CONDITIONAL
- [ ] Variant B's Overall Status is NOT ASSESSED and names the unanswered Legal items
- [ ] No "documented exception" is offered for an S2 or S3 at `workflow: full`
- [ ] Next steps name `/gate-check release` before `/team-release`

---

## Protocol Compliance

- [ ] Scopes the checklist by `project.stage`, `modes.rigor` and `platform.cert_tier`
- [ ] Branches certification on the four `cert_tier` values, not on platform names
- [ ] Reports every scan with a denominator or `NOT ASSESSED — [reason]`
- [ ] Writes unassessable items as `- [?]` with the legend
- [ ] Asks "May I write" before saving (skipped entirely in dry-run), and creates no file or directory before the answer
- [ ] Asks one Phase 4b question per section for the items only a person can confirm, never answering them itself; skips Phase 4b, and says so, in `dry-run` and `autonomous` mode
- [ ] Names `/gate-check release` in next steps whenever `project.stage` is not `Release`
- [ ] Puts findings with no workaround or accepted risk under Blocking Items, and shortfalls with a documented workaround or accepted risk under Conditional Items
- [ ] Overall Status is READY, CONDITIONAL, NOT ASSESSED or NOT READY, first match NOT READY → NOT ASSESSED → CONDITIONAL → READY

---

## Coverage Notes

- `cert_tier: console` (TRC/Lotcheck, save-data, controller-mapping, age ratings)
  is not separately tested.
- Stage scoping (items for phases not yet reached are declared out of scope) and
  `rigor: minimal` trimming are not separately tested.
- An existing checklist in `production/releases/` is read as context only; no
  comparison against it is tested.
