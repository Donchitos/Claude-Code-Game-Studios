# /architecture-review — Phases 3 and 3b: Traceability Matrix and Story Linkage

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Build the Traceability Matrix

**In this file:**

- Step 3b-1 — Load stories
- Step 3b-2 — Load test files
- Step 3b-3 — Build the extended RTM

For each technical requirement extracted in Phase 2, search the ADRs:

1. Use the ADRs **already loaded in Phase 1b** — do not re-read them. Extract each
   ADR's "GDD Requirements Addressed" section from what is already in context.
   (If Phase 1b ran in a mode that did not load every ADR, `Grep pattern="## GDD
   Requirements Addressed" glob="docs/architecture/adr-*.md" output_mode="content"
   -A 15` fills the gap without a full re-read.)
2. Check if it explicitly references the requirement or its GDD
3. Check if the ADR's decision text implicitly covers the requirement
4. Mark coverage status:

| Status | Meaning |
|--------|---------|
| ✅ **Covered** | An **Accepted** ADR explicitly addresses this requirement |
| 🟡 **Covered (Proposed)** | An ADR addresses it, but that ADR is still `Proposed` |
| ⚠️ **Partial** | An ADR partially covers this, or coverage is ambiguous |
| ❌ **Gap** | No ADR addresses this requirement |
| ❓ **Not assessed** | The ADR is unreadable, or has no `## Status` section |

> **Read each ADR's `## Status` before marking coverage — an unaccepted decision
> is not coverage.** If `✅` meant only that *an ADR addresses this*, with no
> status qualification, a requirement covered entirely by `Proposed` ADRs would
> count as covered and this review could return **PASS: All requirements
> covered** over an architecture nobody had accepted. Four skills downstream
> (`create-control-manifest`, `create-epics`, `create-stories`, `gate-check`)
> require `Accepted`, so a PASS on that basis sends work forward that every one
> of them will refuse.
>
> `🟡` is **not** a pass state: it caps the verdict at **CONCERNS**, and names the
> route out — `/architecture-decision accept ADR-NNNN`. That route is the only
> thing that moves an ADR to `Accepted`; without it, grading `Proposed` as
> covered would be the only option, which is why it must never be graded so.

Build the full matrix:

```
## Traceability Matrix

| Requirement ID | GDD | System | Requirement | ADR Coverage | Status |
|---------------|-----|--------|-------------|--------------|--------|
| TR-combat-001 | combat.md | Combat | Hitbox detection < 1 frame | ADR-0003 | ✅ |
| TR-combat-002 | combat.md | Combat | Combo window timing | — | ❌ GAP |
| TR-inventory-001 | inventory.md | Inventory | Persistent item storage | ADR-0005 | ✅ |
```

Count the totals: X covered, Y partial, Z gaps.

---

## Phase 3b: Story and Test Linkage (RTM mode only)

*Skip this phase unless the argument is `rtm` or `full` with stories present.*

This phase extends the Phase 3 matrix to include the story that implements
each requirement and the test that verifies it — producing the full
Requirements Traceability Matrix (RTM).

### Step 3b-1 — Load stories

Glob `production/epics/**/*.md` (excluding EPIC.md index files) to establish the
denominator. Then collect the fields with **targeted section greps, not a full
read of each story** — the same two-grep form `/test-evidence-review` uses for
this identical extraction:

```
Grep pattern="## Test Evidence" glob="production/epics/**/story-*.md" output_mode="content" -A 8
Grep pattern="TR-" glob="production/epics/**/story-*.md" output_mode="content"
```

- **TR-ID** — from the second grep.
- **Test file path** — under `## Test Evidence`, captured by the first grep's `-A 8`.
- **Status** — from the story header; add `Grep pattern="^> \*\*Status\*\*"` if not already captured.
- **Story path and title** — from the file name and path; no read at all.

Full-read a story only when its Test Evidence section is missing or ambiguous.

### Step 3b-2 — Load test files

Glob the engine's test root (`.claude/docs/directory-structure.md`): Godot
`tests/unit/**/*_test.*` and `tests/integration/**/*_test.*`; Unity
`Assets/Tests/**/*Tests.cs`; Unreal `Source/*/Private/Tests/**/*.cpp`. With no
engine configured, say the test index could not be built rather than reading an
empty glob as "no tests". Build an index: system → [test file paths].

For each test file path from Step 3b-1, confirm via Glob whether the file
actually exists. Note MISSING if the stated path does not exist.

### Step 3b-3 — Build the extended RTM

For each TR-ID in the Phase 3 matrix, add:
- **Story**: the story file path(s) that reference this TR-ID (may be multiple)
- **Test File**: the test file path stated in the story's Test Evidence section
- **Test Status**: COVERED (test file exists) / MISSING (path stated but not
  found) / NONE (no test path stated, story type may be Visual/Feel/UI) /
  NO STORY (requirement has no story yet — pre-production gap)

Extended matrix format:

```
## Requirements Traceability Matrix (RTM)

| TR-ID | GDD | Requirement | ADR | Story | Test File | Test Status |
|-------|-----|-------------|-----|-------|-----------|-------------|
| TR-combat-001 | combat.md | Hitbox < 1 frame | ADR-0003 | story-001-hitbox.md | tests/unit/combat/hitbox_test.gd | COVERED |
| TR-combat-002 | combat.md | Combo window | — | story-002-combo.md | — | NONE (Visual/Feel) |
| TR-inventory-001 | inventory.md | Persistent storage | ADR-0005 | — | — | NO STORY |
```

RTM coverage summary:
- COVERED: [N] — requirements with ADR + story + passing test
- MISSING test: [N] — story exists but test file not found
- NO STORY: [N] — requirements with ADR but no story yet
- NO ADR: [N] — requirements without architectural coverage (from Phase 3 gaps)
- Full chain complete (COVERED): [N/total] ([%])

---
