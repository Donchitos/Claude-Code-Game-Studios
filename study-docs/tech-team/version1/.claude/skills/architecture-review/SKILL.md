---
name: architecture-review
description: "Validates completeness and consistency of the project architecture against all feature specs. Builds a traceability matrix mapping every requirement (TR-ID) to ADRs, identifies coverage gaps, detects cross-ADR conflicts, verifies UE 5.8 API compatibility via Context7, and produces a PASS/CONCERNS/FAIL verdict."
argument-hint: "[focus: full | coverage | consistency | engine | single-spec path/to/spec.md]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion, run_mcp
agent: technical-director
model: opus
---

# Architecture Review

The architecture review validates that the complete body of architectural decisions
covers all feature spec requirements, is internally consistent, and correctly targets
**Unreal Engine 5.8** (verified via Context7 at runtime). It is the quality gate at
the end of Technical Setup.

**Argument modes:**
- **No argument / `full`**: Full review — all phases
- **`coverage`**: Traceability only — which requirements have no ADR
- **`consistency`**: Cross-ADR conflict detection only
- **`engine`**: UE 5.8 compatibility audit only (via Context7)
- **`single-spec [path]`**: Review architecture coverage for one specific feature spec
- **`rtm`**: Requirements Traceability Matrix — extends the standard matrix
  to include story file paths and test file paths; outputs
  `docs/architecture/requirements-traceability.md` with the full
  requirement → ADR → Story → Test chain. Use in Implementation phase when
  stories and tests exist.

---

## Phase 1: Load Everything

### Phase 1a — L0: Summary Scan (fast, low tokens)

Before reading any full document, use Grep to extract `## Summary` sections
from all feature specs and ADRs:

```
Grep pattern="## Summary" glob="docs/requirements/*.md" output_mode="content" -A 4
Grep pattern="## Summary" glob="docs/architecture/adr-*.md" output_mode="content" -A 3
```

For `single-spec [path]` mode: use the target spec's summary to identify which
ADRs reference the same system (Grep ADRs for the system name), then full-read
only those ADRs. Skip full-reading unrelated specs entirely.

For `engine` mode: only full-read ADRs — specs are not needed for engine checks.

For `coverage` or `full` mode: proceed to full-read everything below.

### Phase 1b — L1/L2: Full Document Load

Read all inputs appropriate to the mode:

### Feature Specs (Requirement Source)
- All in-scope feature specs in `docs/requirements/` — read every file completely
- `docs/architecture/tr-registry.yaml` — the authoritative index mapping TR-IDs
  to feature spec requirement text (replaces the old GDD/systems-index dependency)

### Architecture Documents
- All in-scope ADRs in `docs/architecture/` — read every file completely
- `docs/architecture/architecture.md` if it exists
- `docs/architecture/control-manifest.md` if it exists

### Engine Reference (Context7 runtime — NO static docs/engine-reference/)
- Do NOT read a static `docs/engine-reference/` directory — it is not maintained.
  The runtime authority is **Context7 MCP**.
- For `engine` mode, resolve the UE library ID via Context7 once
  (`resolve-library-id(libraryName: "Unreal Engine")`), then use `query-docs`
  to verify each post-cutoff API referenced across the ADRs (see Phase 5).

### Project Standards
- `.claude/docs/technical-preferences.md`

Report a count: "Loaded [N] feature specs, [M] ADRs, engine: Unreal Engine 5.8
(knowledge source: Context7 MCP)."

**Also read `docs/consistency-failures.md`** if it exists. Extract entries with
Domain matching the systems under review (Architecture, Engine, or any spec domain
being covered). Surface recurring patterns as a "Known conflict-prone areas" note
at the top of the Phase 4 conflict detection output.

---

## Phase 2: Extract Technical Requirements from Every Feature Spec

### Pre-load the TR registry

Before extracting any requirements, read `docs/architecture/tr-registry.yaml`
if it exists. Index existing entries by `id` and by normalized `requirement`
text (lowercase, trimmed). This prevents ID renumbering across review runs.

For each requirement you extract, the matching rule is:
1. **Exact/near match** to an existing registry entry for the same system →
   reuse that entry's TR-ID unchanged. Update the `requirement` text in the
   registry only if the spec wording changed (same intent, clearer phrasing) —
   add a `revised: [date]` field.
2. **No match** → assign a new ID: next available `TR-[system]-NNN` for that
   system, starting from the highest existing sequence + 1.
3. **Ambiguous** (partial match, intent unclear) → ask the user:
   > "Does '[new requirement text]' refer to the same requirement as
   > `TR-[system]-NNN: [existing text]'`, or is it a new requirement?"
   User answers: "Same requirement" (reuse ID) or "New requirement" (new ID).

For any requirement with `status: deprecated` in the registry — skip it.
It was removed from the spec intentionally.

For each feature spec, read it and extract all **technical requirements** —
things the architecture must provide for the system to work. A technical
requirement is any statement that implies a specific architectural decision.

Categories to extract:

| Category | Example |
|----------|---------|
| **Data structures** | "Each entity has health, max health, status effects" → needs a component/data schema |
| **Performance constraints** | "Collision detection must run at 60fps with 200 entities" → physics budget ADR |
| **Engine capability** | "Inverse kinematics for character animation" → IK system ADR |
| **Cross-system communication** | "Damage system notifies UI and audio simultaneously" → event/signal architecture ADR |
| **State persistence** | "Player progress persists between sessions" → save system ADR |
| **Threading/timing** | "AI decisions happen off the main thread" → concurrency ADR |
| **Platform requirements** | "Supports keyboard, gamepad, touch" → input system ADR |

For each spec, produce a structured list:

```
Spec: [filename]
System: [system name]
Technical Requirements:
  TR-[system]-001: [requirement text] → Domain: [Physics/Rendering/etc]
  TR-[system]-002: [requirement text] → Domain: [...]
```

This becomes the **requirements baseline** — the complete set of what the
architecture must cover.

---

## Phase 3: Build the Traceability Matrix

For each technical requirement extracted in Phase 2, search the ADRs:

1. Read every ADR's "Requirements Addressed" section
2. Check if it explicitly references the requirement or its spec
3. Check if the ADR's decision text implicitly covers the requirement
4. Mark coverage status:

| Status | Meaning |
|--------|---------|
| ✅ **Covered** | An ADR explicitly addresses this requirement |
| ⚠️ **Partial** | An ADR partially covers this, or coverage is ambiguous |
| ❌ **Gap** | No ADR addresses this requirement |

Build the full matrix:

```
## Traceability Matrix

| Requirement ID | Spec | System | Requirement | ADR Coverage | Status |
|---------------|------|--------|-------------|--------------|--------|
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

Glob `production/epics/**/*.md` (excluding EPIC.md index files). For each
story file:
- Extract `TR-ID` from the story's Context section
- Extract story file path, title, Status
- Extract `## Test Evidence` section — the stated test file path

### Step 3b-2 — Load test files

Glob `tests/unit/**/*_test.*` and `tests/integration/**/*_test.*`.
Build an index: system → [test file paths].

For each test file path from Step 3b-1, confirm via Glob whether the file
actually exists. Note MISSING if the stated path does not exist.

### Step 3b-3 — Build the extended RTM

For each TR-ID in the Phase 3 matrix, add:
- **Story**: the story file path(s) that reference this TR-ID (may be multiple)
- **Test File**: the test file path stated in the story's Test Evidence section
- **Test Status**: COVERED (test file exists) / MISSING (path stated but not
  found) / NONE (no test path stated, story type may be Visual/Feel/UI) /
  NO STORY (requirement has no story yet — pre-implementation gap)

Extended matrix format:

```
## Requirements Traceability Matrix (RTM)

| TR-ID | Spec | Requirement | ADR | Story | Test File | Test Status |
|-------|------|-------------|-----|-------|-----------|-------------|
| TR-combat-001 | combat.md | Hitbox < 1 frame | ADR-0003 | story-001-hitbox.md | tests/unit/combat/hitbox_test.cpp | COVERED |
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

## Phase 4: Cross-ADR Conflict Detection

Compare every ADR against every other ADR to detect contradictions. A conflict
exists when:

- **Data ownership conflict**: Two ADRs claim exclusive ownership of the same data
- **Integration contract conflict**: ADR-A assumes System X has interface Y, but
  ADR-B defines System X with a different interface
- **Performance budget conflict**: ADR-A allocates N ms to physics, ADR-B allocates
  N ms to AI, together they exceed the total frame budget
- **Dependency cycle**: ADR-A says System X initialises before Y; ADR-B says Y
  initialises before X
- **Architecture pattern conflict**: ADR-A uses event-driven communication for a
  subsystem; ADR-B uses direct function calls to the same subsystem
- **State management conflict**: Two ADRs define authority over the same game state
  (e.g. both Combat ADR and Character ADR claim to own the health value)

For each conflict found:

```
## Conflict: [ADR-NNNN] vs [ADR-MMMM]
Type: [Data ownership / Integration / Performance / Dependency / Pattern / State]
ADR-NNNN claims: [...]
ADR-MMMM claims: [...]
Impact: [What breaks if both are implemented as written]
Resolution options:
  1. [Option A]
  2. [Option B]
```

### ADR Dependency Ordering

After conflict detection, analyse the dependency graph across all ADRs:

1. **Collect all `Depends On` fields** from every ADR's "ADR Dependencies" section
2. **Topological sort**: Determine the correct implementation order — ADRs with no
   dependencies come first (Foundation), ADRs that depend on those come next, etc.
3. **Flag unresolved dependencies**: If ADR-A's "Depends On" field references an ADR
   that is still `Proposed` or does not exist, flag it:
   ```
   ⚠️  ADR-0005 depends on ADR-0002 — but ADR-0002 is still Proposed.
       ADR-0005 cannot be safely implemented until ADR-0002 is Accepted.
   ```
4. **Cycle detection**: If ADR-A depends on ADR-B and ADR-B depends on ADR-A (directly
   or transitively), flag it as a `DEPENDENCY CYCLE`:
   ```
   🔴 DEPENDENCY CYCLE: ADR-0003 → ADR-0006 → ADR-0003
      This cycle must be broken before either can be implemented.
   ```
5. **Output recommended implementation order**:
   ```
   ### Recommended ADR Implementation Order (topologically sorted)
   Foundation (no dependencies):
     1. ADR-0001: [title]
     2. ADR-0003: [title]
   Depends on Foundation:
     3. ADR-0002: [title] (requires ADR-0001)
     4. ADR-0005: [title] (requires ADR-0003)
   Feature layer:
     5. ADR-0004: [title] (requires ADR-0002, ADR-0005)
   ```

---

## Phase 5: UE 5.8 Engine Compatibility Cross-Check (via Context7)

Across all ADRs, check for engine consistency. **The runtime authority is
Context7 MCP — do NOT read a static `docs/engine-reference/` directory.**

### Step 5a — Resolve UE Library ID (once)

Call Context7 `resolve-library-id(libraryName: "Unreal Engine")`. Capture the
library ID. If Context7 cannot resolve it, fall back to `WebSearch` against
`docs.unrealengine.com/5.8/` and warn the user that API verification is degraded.

### Step 5b — Collect APIs to Verify

Across all ADRs, collect:
- All APIs listed in any ADR's "APIs Verified" or "Context7 Queries" fields
- All APIs in the "Engine Compatibility" tables
- All UE class/subsystem names referenced in Decision / Key Interfaces sections
- All "Post-Cutoff APIs Used" entries

Deduplicate. This is your verification queue.

### Step 5c — Verify Each API via Context7

For each unique API, call Context7 `query-docs` with a specific query like
`"UAbilitySystemComponent ApplyGameplayEffectToTarget 5.8 signature"`. Each
tool is capped at ~3 calls per question — batch by domain.

Record results:
- **Confirmed**: API exists in 5.8 with the signature the ADR assumes
- **Changed**: API exists but signature/behaviour differs in 5.4+ (flag risk)
- **Not Found**: Context7 returns nothing → fall back to `WebSearch` against
  `docs.unrealengine.com/5.8/` + `dev.epicgames.com`. If still not found, mark
  as `UNVERIFIED — high risk`.

Each finding carries the stamp: `API 验证:Context7 查询 [查询词] 于 [日期] — [确认/变更/未找到]`.

### Version Consistency
- Do all ADRs that mention an engine version agree on **Unreal Engine 5.8**?
- If any ADR was written for an older UE version, flag it as potentially stale.

### Post-Cutoff API Consistency
- Collect all "Post-Cutoff APIs Used" fields from all ADRs
- For each, verify against Context7 (Step 5c)
- Check that no two ADRs make contradictory assumptions about the same post-cutoff API

### Deprecated API Check
- For each API flagged `Changed` by Context7 with a deprecation note, list the ADRs
  that reference it.
- Flag any ADR referencing a deprecated-in-5.8 API.

### Missing Engine Compatibility Sections
- List all ADRs that are missing the Engine Compatibility section entirely
- These are blind spots — their engine assumptions are unknown

Output format:
```
### Engine Audit Results
Engine: Unreal Engine 5.8 (verified via Context7)
ADRs with Engine Compatibility section: X / Y total

Context7 Queries Run: [N] across [M] unique APIs
  - [API 1] → 确认 (Context7 查询 [query] 于 [date])
  - [API 2] → 变更 (5.4+ signature change) (Context7 查询 [query] 于 [date])
  - [API 3] → 未找到 (WebSearch fallback used)

Deprecated API References:
  - ADR-0002: uses [deprecated API] — deprecated since 5.x

Stale Version References:
  - ADR-0001: written for [older version] — current project version is UE 5.8

Post-Cutoff API Conflicts:
  - ADR-0004 and ADR-0007 both use [API] with incompatible assumptions
```

---

### Engine Specialist Consultation

After completing the engine audit above, spawn the **primary engine specialist**
(`unreal-specialist`) via Task for a domain-expert second opinion:
- Read `.claude/docs/engine-specialists.md` (or `.claude/docs/technical-preferences.md`
  Engine Specialists section) to confirm the primary specialist.
- Spawn `subagent_type: unreal-specialist` with: all ADRs that contain
  engine-specific decisions or Post-Cutoff APIs Used fields, the Phase 5 audit
  findings, and a list of the APIs that need re-verification.
- **Critical**: instruct the specialist to **re-verify each UE API by calling
  Context7 itself** (`resolve-library-id` + `query-docs`). The sub-agent is a
  fresh Claude instance and cannot see this session's Context7 results.
  Ask the specialist to:
  1. Confirm or challenge each audit finding — they may know of UE nuances not
     captured by Context7 queries alone
  2. Identify UE 5.8-specific anti-patterns in the ADRs that the audit may have
     missed (e.g., subsystem misuse, BP/C++ boundary violations, GAS misuse)
  3. Flag ADRs that make assumptions about engine behaviour that differ from
     actual UE 5.8 reality
  4. Stamp output: `API 验证:Context7 查询 [查询词] 于 [日期] — [确认/变更/未找到]`

Incorporate additional findings under `### Engine Specialist Findings` in the
Phase 5 output. These feed into the final verdict — specialist-identified issues
carry the same weight as audit-identified issues.

---

## Phase 5b: Design Revision Flags (Architecture → Spec Feedback)

For each **HIGH RISK engine finding** from Phase 5, check whether any feature spec
makes an assumption that the verified engine reality contradicts.

Specific cases to check:

1. **Post-cutoff API behaviour differs from training-data assumptions**: If an ADR
   records a verified API behaviour that differs from the default LLM assumption,
   check all feature specs that reference the related system. Look for spec rules
   written around the old (assumed) behaviour.

2. **Known engine limitations in ADRs**: If an ADR records a known UE 5.8 limitation
   (e.g., a GAS quirk, a replication edge case), check specs that design mechanics
   around the affected feature.

3. **Deprecated API conflicts**: If Phase 5 flagged a deprecated API used in an ADR,
   check whether any spec contains mechanics that assume the deprecated API's
   behaviour.

For each conflict found, record it in the Spec Revision Flags table:

```
### Spec Revision Flags (Architecture → Requirement Feedback)
These spec assumptions conflict with verified UE 5.8 behaviour or accepted ADRs.
The spec should be revised before its system enters implementation.

| Spec | Assumption | Reality (from ADR / Context7) | Action |
|------|------------|-------------------------------|--------|
| combat.md | "Use UGameplayEffectSpec for instant damage" | GAS 5.8 instant application changed — ADR-0003 | Revise spec |
```

If no revision flags are found, write: "No spec revision flags — all spec
assumptions are consistent with verified UE 5.8 behaviour."

Then use `AskUserQuestion`:
- "I found [N] spec revision flag(s). How do you want to proceed?"
  - [A] Yes — flag them in the report so I can revise the specs
  - [B] Show me the full conflict detail first, then ask again
  - [C] No — leave the specs unchanged for now

If [A] or [C]: include the flags in the final report (do not silently drop them).
If [B]: display the full conflict table, then re-ask with `AskUserQuestion`.

---

## Phase 6: Architecture Document Coverage

If `docs/architecture/architecture.md` exists, validate it against feature specs:

- Does every system referenced in the specs appear in the architecture layers?
- Does the data flow section cover all cross-system communication defined in specs?
- Do the API boundaries support all integration requirements from specs?
- Are there systems in the architecture doc that have no corresponding spec
  (orphaned architecture)?

---

## Phase 7: Output the Review Report

```
## Architecture Review Report
Date: [date]
Engine: Unreal Engine 5.8 (knowledge source: Context7 MCP)
Specs Reviewed: [N]
ADRs Reviewed: [M]

---

### Traceability Summary
Total requirements: [N]
✅ Covered: [X]
⚠️ Partial: [Y]
❌ Gaps: [Z]

### Coverage Gaps (no ADR exists)
For each gap:
  ❌ TR-[id]: [spec] → [system] → [requirement]
     Suggested ADR: "/architecture-decision [suggested title]"
     Domain: [Physics/Rendering/etc]
     Engine Risk: [LOW/MEDIUM/HIGH — per Context7 verification]

### Cross-ADR Conflicts
[List all conflicts from Phase 4]

### ADR Dependency Order
[Topologically sorted implementation order from Phase 4 — dependency ordering section]
[Unresolved dependencies and cycles if any]

### Spec Revision Flags
[Spec assumptions that conflict with verified UE 5.8 behaviour — from Phase 5b]
[Or: "None — all spec assumptions consistent with verified UE 5.8 behaviour"]

### Engine Compatibility Issues
[List all engine issues from Phase 5 — Context7 verification results]

### Architecture Document Coverage
[List missing systems and orphaned architecture from Phase 6]

---

### Verdict: [PASS / CONCERNS / FAIL]

PASS: All requirements covered, no conflicts, UE 5.8 consistent
CONCERNS: Some gaps or partial coverage, but no blocking conflicts
FAIL: Critical gaps (Foundation/Core layer requirements uncovered),
      or blocking cross-ADR conflicts detected

### Blocking Issues (must resolve before PASS)
[List items that must be resolved — FAIL verdict only]

### Required ADRs
[Prioritised list of ADRs to create, most foundational first]
```

---

## Phase 8: Write and Update Traceability Index

Use `AskUserQuestion` for the write approval:
- "Review complete. What would you like to write?"
  - [A] Write all three files (review report + traceability index + TR registry)
  - [B] Write review report only — `docs/architecture/architecture-review-[date].md`
  - [C] Don't write anything yet — I need to review the findings first

### RTM Output (rtm mode only)

For `rtm` mode, use `AskUserQuestion`:
- "May I write the full Requirements Traceability Matrix?"
  - [A] Yes — write to `docs/architecture/requirements-traceability.md`
  - [B] Not yet — show me the full RTM data first, then ask again

RTM file format:

```markdown
# Requirements Traceability Matrix (RTM)

> Last Updated: [date]
> Mode: /architecture-review rtm
> Engine: Unreal Engine 5.8
> Coverage: [N]% full chain complete (Spec → ADR → Story → Test)

## How to read this matrix

| Column | Meaning |
|--------|---------|
| TR-ID | Stable requirement ID from tr-registry.yaml |
| Spec | Source feature spec document |
| ADR | Architectural decision governing implementation |
| Story | Story file that implements this requirement |
| Test File | Automated test file path |
| Test Status | COVERED / MISSING / NONE / NO STORY |

## Full Traceability Matrix

| TR-ID | Spec | Requirement | ADR | Story | Test File | Status |
|-------|------|-------------|-----|-------|-----------|--------|
[Full matrix rows from Phase 3b]

## Coverage Summary

| Status | Count | % |
|--------|-------|---|
| COVERED — full chain complete | [N] | [%] |
| MISSING test — story exists, no test | [N] | [%] |
| NO STORY — ADR exists, not yet implemented | [N] | [%] |
| NO ADR — architectural gap | [N] | [%] |
| **Total requirements** | **[N]** | **100%** |

## Uncovered Requirements (Priority Fix List)

Requirements where the full chain is broken, prioritised by layer:

### Foundation layer gaps
[list with suggested action per gap]

### Core layer gaps
[list]

### Feature / Presentation layer gaps
[list — lower priority]

## History

| Date | Full Chain % | Notes |
|------|-------------|-------|
| [date] | [%] | Initial RTM |
```

### TR Registry Update

Also ask: "May I update `docs/architecture/tr-registry.yaml` with new requirement
IDs from this review?"

If yes:
- **Append** any new TR-IDs that weren't in the registry before this review
- **Update** `requirement` text and `revised` date for any entries whose spec
  wording changed (ID stays the same)
- **Mark** `status: deprecated` for any registry entries whose spec requirement
  no longer exists (confirm with user before marking deprecated)
- **Never** renumber or delete existing entries
- Update the `last_updated` and `version` fields at the top

This ensures all future story files can reference stable TR-IDs that persist
across every subsequent architecture review.

### Reflexion Log Update

After writing the review report, append any 🔴 CONFLICT entries found in Phase 4
to `docs/consistency-failures.md` (if the file exists):

```markdown
### [YYYY-MM-DD] — /architecture-review — 🔴 CONFLICT
**Domain**: Architecture / [specific domain e.g. State Ownership, Performance]
**Documents involved**: [ADR-NNNN] vs [ADR-MMMM]
**What happened**: [specific conflict — what each ADR claims]
**Resolution**: [how it was or should be resolved]
**Pattern**: [generalised lesson for future ADR authors in this domain]
```

Only append CONFLICT entries — do not log GAP entries (missing ADRs are expected
before the architecture is complete). Do not create the file if missing — only
append when it already exists.

### Session State Update

After writing all approved files, silently append to
`production/session-state/active.md`:

    ## Session Extract — /architecture-review [date]
    - Verdict: [PASS / CONCERNS / FAIL]
    - Requirements: [N] total — [X] covered, [Y] partial, [Z] gaps
    - New TR-IDs registered: [N, or "None"]
    - Spec revision flags: [comma-separated spec names, or "None"]
    - Top ADR gaps: [top 3 gap titles from the report, or "None"]
    - UE 5.8 APIs verified via Context7: [N, or "0"]
    - Report: docs/architecture/architecture-review-[date].md

If `active.md` does not exist, create it with this block as the initial content.
Confirm in conversation: "Session state updated."

The traceability index format:

```markdown
# Architecture Traceability Index
Last Updated: [date]
Engine: Unreal Engine 5.8 (knowledge source: Context7 MCP)

## Coverage Summary
- Total requirements: [N]
- Covered: [X] ([%])
- Partial: [Y]
- Gaps: [Z]

## Full Matrix
[Complete traceability matrix from Phase 3]

## Known Gaps
[All ❌ items with suggested ADRs]

## Superseded Requirements
[Requirements whose spec was changed after the ADR was written]
```

---

## Phase 9: Handoff

After completing the review and writing approved files, present:

1. **Immediate actions**: List the top 3 ADRs to create (highest-impact gaps first,
   Foundation layer before Feature layer)
2. **Pre-gate checklist**: Check whether these exist via Glob and mark each ✅ or ❌:
   - `tests/unit/` and `tests/integration/` directories — if ❌: run `/test-setup`
   - `.github/workflows/tests.yml` — if ❌: run `/test-setup`
   Present ❌ items as required steps before gate-check. Do not offer `/gate-check`
   as an option if any item is ❌ — offer the missing skill to run instead.
3. **Rerun trigger**: "Re-run `/architecture-review` after each new ADR is written
   to verify coverage improves"

Then close with `AskUserQuestion` tailored to the pre-gate checklist state:
- If ADR gaps remain or any pre-gate item is ❌:
  - "Architecture review complete. What would you like to do next?"
    - [A] Write a missing ADR — open a fresh session and run `/architecture-decision [system]`
    - [B] Run `/test-setup` — required before gate-check (only show if test infrastructure is ❌)
    - [C] Stop here for this session
- If all pre-gate checklist items are ✅ and no blocking ADR gaps remain:
  - "Architecture review complete. All pre-gate items confirmed. What would you like to do next?"
    - [A] Run `/gate-check requirements-breakdown`
    - [B] Write a missing ADR — open a fresh session and run `/architecture-decision [system]`
    - [C] Stop here for this session

---

## Error Recovery Protocol

If any spawned agent returns BLOCKED, errors, or fails to complete:

1. **Surface immediately**: Report "[AgentName]: BLOCKED — [reason]" before continuing
2. **Assess dependencies**: If the blocked agent's output is required by a later phase, do not proceed past that phase without user input
3. **Offer options** via AskUserQuestion with three choices:
   - Skip this agent and note the gap in the final report
   - Retry with narrower scope (fewer specs, single-system focus)
   - Stop here and resolve the blocker first
4. **Always produce a partial report** — output whatever was completed so work is not lost

If Context7 cannot resolve the Unreal Engine library or returns no useful results
for all verification queries: warn the user explicitly that the engine audit is
**degraded** — fall back to WebSearch but flag in the report that ADR engine
compatibility has not been authoritatively verified.

---

## Collaborative Protocol

1. **Read silently** — do not narrate every file read
2. **Show the matrix** — present the full traceability matrix before asking for
   anything; let the user see the state
3. **Don't guess** — if a requirement is ambiguous, ask: "Is [X] a technical
   requirement or a design preference?"
4. **Draft before approval** — always show the content that will be written (the
   report, the updated ADR section, the spec flag) inline in the conversation
   before requesting approval. Never ask to write something the user has not yet seen.
5. **Use `AskUserQuestion` for write approvals** — plain text "May I?" is not
   sufficient. Use the structured tool with labeled options [A]/[B]/[C] so the
   user can choose between "write now", "show full draft first", and "not yet".
   Multi-file changesets must list every file and what changes, then ask once
   with grouped options — not a separate plain-text question per file.
6. **Non-blocking** — the verdict is advisory; the user decides whether to continue
   despite CONCERNS or even FAIL findings
