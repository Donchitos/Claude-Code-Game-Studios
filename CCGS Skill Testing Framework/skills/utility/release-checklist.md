# Skill Test Spec: /release-checklist

## Skill Summary

`/release-checklist [platform: pc|console|mobile|all]` builds a pre-release
checklist scoped to the project. It resolves `modes.rigor`, `modes.workflow`,
`project.stage` and `platform.cert_tier`, reads `CLAUDE.md` and the current
milestone in `production/milestones/`, and reads open bugs from
`production/qa/bugs/` (Severity and Status lines). The bug items use the release
gate's thresholds for the resolved `workflow` — an open S1, S2 or S3 fails at
`full`, only an open S1 at `standard`/`minimal` (an open S2/S3 is a listed risk)
— and with no bug files they read `NOT ASSESSED — no bug records`, never zero.
It scans the code root for TODO / FIXME / HACK,
always stating the denominator (`scanned [N] source files: …`), or
`NOT ASSESSED — code root unresolved` when no root resolves, or
`NOT ASSESSED — no source files found to scan` when the root is absent or empty.
Missing test output is reported as
`Test results: NOT ASSESSED — no test output or CI logs found`.

The checklist has Codebase Health, Build Verification, Quality Gates and Content
Complete sections, device blocks chosen by the argument (default `all`), then a
certification block chosen **only** by `platform.cert_tier`: `none` → a single
"Certification: omitted — cert_tier is 'none' …" line; `itch` → itch.io rows;
`steam` → Steamworks rows; `console` → TRC/XR/Lotcheck rows. Unset `cert_tier`
means asking which platforms are in scope, or
`### Certification: NOT ASSESSED — cert tier unknown`; unset is never treated as
`none`. It ends with Store / Distribution, Launch Readiness and
`### Go / No-Go: [READY / NOT ASSESSED / NOT READY]` — first match NOT READY (a
blocking item fails), then NOT ASSESSED (any section or item NOT ASSESSED), then READY —
then asks "May I write this to
`production/releases/release-checklist-[version].md`?". No director gates apply.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: READY, NOT READY, NOT ASSESSED
- [ ] Contains "May I write" language before writing the checklist
- [ ] Has a next-step handoff (`/gate-check` for the formal verdict, `/team-release` for sign-offs)

---

## Director Gate Checks

None. `/release-checklist` spawns no agents (`Agent` is not in its allowed
tools). The Sign-offs Required list (QA Lead, Technical Director, Producer,
Creative Director) is a checklist for humans, not spawned gates. Formal phase
advancement is `/gate-check`.

---

## Test Cases

### Case 1: Happy Path — PC Build on the Steam Tier

**Fixture:**
- `platform.cert_tier: steam`; `project.stage: Polish`; `engine.name: Godot`
- `src/` has 40 source files containing 3 TODO, 1 FIXME and 0 HACK comments
- `production/milestones/` holds the current milestone
- `production/qa/bugs/` holds `BUG-0003.md` (S1, `**Status**: Closed`) and
  `BUG-0004.md` (S4, `**Status**: Open`); `modes.rigor` is unset (`workflow: minimal`)
- CI test output exists

**Input:** `/release-checklist pc`

**Expected behavior:**
1. Skill reads `CLAUDE.md` and the current milestone
2. Codebase Health states the denominator: `scanned 40 source files: 3 TODO, 1
   FIXME, 0 HACK`, listing the FIXME
3. The PC device block is emitted; no Console or Mobile device block
4. Certification is the Steamworks block only
5. Store / Distribution, Launch Readiness and the Go / No-Go line follow
6. Skill presents total items and known blockers, then asks "May I write this
   to `production/releases/release-checklist-[version].md`?"; next steps name
   `/gate-check` and `/team-release`

**Assertions:**
- [ ] TODO/FIXME/HACK counts are reported with the number of files scanned
- [ ] Only the PC device block appears
- [ ] Certification contains Steamworks rows and no itch.io or console certification rows
- [ ] Go / No-Go is READY or NOT READY — never NOT ASSESSED, since every section in this fixture could be assessed
- [ ] The Quality Gates bug line is counted from `production/qa/bugs/` (0 open S1, S2 or S3); the closed S1 and the open S4 fail nothing
- [ ] Nothing is written before the "May I write" ask naming `production/releases/release-checklist-[version].md`

---

### Case 2: Device Argument and Certification Tier Are Separate Axes

**Fixture:**
- `platform.cert_tier: itch`
- Source files exist in the code root

**Input:** `/release-checklist console`

**Expected behavior:**
1. The `console` argument selects the Console device block (suspend/resume, user
   switching, controller prompts)
2. Certification follows `cert_tier`, not the argument: only the itch.io block
3. No Steamworks rows and no TRC/XR/Lotcheck rows appear

**Assertions:**
- [ ] The Console device block is present
- [ ] The only certification block is itch.io
- [ ] No console certification rows (TRC/Lotcheck, first-party submission) appear
- [ ] No Steamworks rows appear

---

### Case 3: cert_tier none vs Unset — Different Output

**Fixture:**
- Run A: `platform.cert_tier: none`
- Run B: `platform.cert_tier` absent (resolved block shows it as unset) and the
  user cannot say which platforms are in scope

**Input:** `/release-checklist` (no argument → device blocks for `all`)

**Expected behavior:**
1. Run A emits no certification block, only the line "Certification: omitted —
   cert_tier is 'none' (internal build, alpha or jam release)."
2. Run B asks which platforms are in scope instead of emitting every track;
   with no answer it emits `### Certification: NOT ASSESSED — cert tier unknown`
   and says why
3. In neither run does the `all` argument cause every certification track to
   be emitted

**Assertions:**
- [ ] Run A shows the "omitted — cert_tier is 'none'" line and no certification rows
- [ ] Run B asks which platforms are in scope
- [ ] Run B's certification section is `NOT ASSESSED — cert tier unknown`, not the `none` line
- [ ] Neither run emits itch.io, Steamworks and console certification together

---

### Case 4: Edge Case — Nothing to Scan, No Test Output

**Fixture:**
- `platform.cert_tier: steam`
- No `engine.name`, no legacy engine value, and none of `src/`, `Assets/`,
  `Source/` exists (code root unresolved)
- No test output directories or CI logs
- `production/qa/bugs/` holds one bug, `BUG-0002.md` (S2, `**Status**: Closed`)

**Input:** `/release-checklist pc`

**Expected behavior:**
1. The code root is unresolved, so no scan runs
2. Codebase Health reads `NOT ASSESSED — code root unresolved`
   (`.claude/docs/code-root-resolution.md`), not `0` TODO/FIXME/HACK
3. The test line reads `Test results: NOT ASSESSED — no test output or CI logs
   found` rather than being omitted
4. The rest of the checklist is still generated and offered for writing

**Assertions:**
- [ ] No bare `0` count is reported for TODO/FIXME/HACK
- [ ] Codebase Health is `NOT ASSESSED — code root unresolved`
- [ ] The test-results NOT ASSESSED line is present
- [ ] Go / No-Go is never READY: it is NOT ASSESSED naming both unassessed sections,
      or NOT READY if a blocking item failed
- [ ] The write still waits for the "May I write" ask

---

### Case 5: Director Gate Check — None; Sign-Offs Are Listed, Not Spawned

**Fixture:**
- `platform.cert_tier: console`; source files present
- Any review mode

**Input:** `/release-checklist all`

**Expected behavior:**
1. Skill generates the checklist with all device blocks and the console
   certification block
2. The Sign-offs Required list appears as unchecked items
3. No director or other agent is spawned; no gate IDs appear
4. Next steps point to `/gate-check` and `/team-release`

**Assertions:**
- [ ] No director gate is invoked and no gate skip message appears
- [ ] No subagent is spawned, although sign-offs are listed
- [ ] The console certification block is the only certification block
- [ ] Next steps name `/gate-check` and `/team-release`

---

### Case 6: A Known Blocker Outranks an Unassessed Section

**Fixture:**
- `platform.cert_tier: steam`; `project.stage: Polish`
- No `engine.name`, no legacy engine value, and none of `src/`, `Assets/`,
  `Source/` exists (code root unresolved)
- CI test output exists
- `production/qa/bugs/BUG-0007.md` is an S1 (Critical) bug with `**Status**: Open`

**Input:** `/release-checklist pc`

**Expected behavior:**
1. Codebase Health reads `NOT ASSESSED — code root unresolved`
2. Quality Gates' "Zero open S1 (Critical) bugs" fails — a blocking item, at every tier
3. Go / No-Go is NOT READY: first match wins, and NOT READY ranks above
   NOT ASSESSED
4. The Rationale lists the S1 bug as a blocking item; the unassessed Codebase
   Health section still reads NOT ASSESSED rather than being dropped

**Assertions:**
- [ ] Go / No-Go is NOT READY — not NOT ASSESSED
- [ ] The S1 bug is listed in the Rationale as a blocking item
- [ ] Codebase Health still shows `NOT ASSESSED — code root unresolved`

---

### Case 7: Bug Thresholds Follow the Workflow Tier

**Fixture:**
- `platform.cert_tier: steam`; source files present; CI test output exists
- Run A: `modes.rigor: standard` (`workflow: standard`); `production/qa/bugs/BUG-0012.md`
  is an S2 (High) bug with `**Status**: Open`, and no other bug is open
- Run B: `modes.rigor: full` (`workflow: full`); `production/qa/bugs/BUG-0013.md`
  is an S3 (Medium) bug with `**Status**: Open`, and no other bug is open

**Input:** `/release-checklist pc`

**Expected behavior:**
1. Both runs read the bugs from `production/qa/bugs/`, not from the milestone
2. Run A: the open S2 fails no item — at `standard` only an open S1 blocks — and
   is listed in the Rationale as a risk; the S2/S3 row is not emitted
3. Run B: the "Zero open S2 (High) and S3 (Medium) bugs" row fails on the open
   S3, which is named in the Rationale as a blocking item; Go / No-Go is NOT READY

**Assertions:**
- [ ] Run A's Go / No-Go is not NOT READY because of the S2, and the S2 appears in the Rationale as a risk
- [ ] Run B's Go / No-Go is NOT READY, naming BUG-0013 as a blocking item
- [ ] Neither run offers a "documented exception" for the S3 at `workflow: full`

---

### Case 8: No Bug Records — NOT ASSESSED, Not Zero

**Fixture:**
- `platform.cert_tier: steam`; source files present; CI test output exists
- `production/qa/bugs/` does not exist

**Input:** `/release-checklist pc`

**Expected behavior:**
1. The Quality Gates bug line reads `NOT ASSESSED — no bug records`, not `0`
2. The bug items are not ticked
3. Go / No-Go is NOT ASSESSED (naming the bug items), unless a blocking item
   failed elsewhere — never READY
4. The output says bugs are filed with `/bug-report`

**Assertions:**
- [ ] No bare `0` bug count and no ticked "Zero open S1 (Critical) bugs" item
- [ ] `NOT ASSESSED — no bug records` appears
- [ ] Go / No-Go is not READY

---

## Protocol Compliance

- [ ] Resolves `platform.cert_tier` and branches only on `none | itch | steam | console`
- [ ] Treats unset `cert_tier` as a question (or NOT ASSESSED), never as `none`
- [ ] Chooses device blocks from the argument and certification from `cert_tier`
- [ ] States a denominator with every scan count, or reports NOT ASSESSED
- [ ] Reads open bugs from `production/qa/bugs/` and applies the release gate's thresholds for the resolved `workflow` (S1–S3 at `full`, S1 at `standard`/`minimal`); no bug files → `NOT ASSESSED — no bug records`
- [ ] Go / No-Go takes the first match: NOT READY, then NOT ASSESSED, then READY
- [ ] Presents totals and blockers before asking "May I write"
- [ ] Ends with `/gate-check` and `/team-release` as next steps

---

## Coverage Notes

- `project.stage` scoping (items for unreached phases marked out of scope) and
  `modes.rigor: minimal` trimming are not separately tested.
- The mobile device block (App Store / Play Store rows kept in the device block
  by design) is not tested by a dedicated case.
- How READY vs NOT READY is decided depends on the unchecked items and the
  user's inputs; a live run is needed to verify the rationale text.
- A resolved code root that is absent or empty reads
  `NOT ASSESSED — no source files found to scan`; not separately tested.
