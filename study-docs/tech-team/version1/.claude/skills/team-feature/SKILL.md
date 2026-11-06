---
name: team-feature
description: "Orchestrate a multi-agent team to design, implement, and validate a complex UE 5.8 feature end-to-end. Coordinates lead-programmer, unreal-specialist, gameplay-programmer, ai-programmer, ui-programmer, network-programmer, and qa-tester through a 6-phase pipeline (design → architecture → parallel-impl → integration → validation → signoff)."
argument-hint: "[feature description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion, run_mcp
model: sonnet
---

# Team Feature (UE 5.8 Multi-Agent Orchestration)

This is the single general-purpose team orchestration skill for the UE 5.8
technical team. The original project had 9 domain teams (`/team-combat`,
`/team-narrative`, `/team-ui`, …). A technical implementation team does not need
domain-split teams — it needs one general orchestrator that dispatches the right
programmer + UE specialist per sub-task.

**Argument check:** If no feature description is provided, output:
> "Usage: `/team-feature [feature description]` — Provide a description of the
> feature to design and implement (e.g., `cover system with lean and blind
> fire`, `inventory drag-drop with replication`)."
Then stop immediately without spawning any subagents or reading any files.

When this skill is invoked with a valid argument, orchestrate the team through
the 6-phase pipeline below.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
The user must approve before moving to the next phase.

---

## Phase 0: Resolve Review Mode

1. If `--review [mode]` was passed as an argument, use that mode.
2. Else read `production/review-mode.txt` — use whatever is written there.
3. Else default to `lean`.

Modes:
- `full` — spawn all lead/director gates as described
- `lean` — skip director gates unless they are PHASE-GATE type (only
  `TD-PHASE-GATE` survives in this project — CD/PR/AD/ND gates are removed)
- `solo` — skip all director gate spawning entirely; run the skill without any
  agent gates

Store the resolved mode for use in all subsequent phases.

---

## Team Composition

- **lead-programmer** — Owns architecture sketch, integration, and cross-domain
  coordination (the producer role from the original project is folded into this
  role — producer was cut from this team).
- **unreal-specialist** — UE 5.8 total authority. Validates engine idioms and
  verifies every UE API via Context7. Dispatches sub-specialists
  (`ue-gas-specialist`, `ue-blueprint-specialist`, `ue-umg-specialist`,
  `ue-replication-specialist`) when a sub-domain is touched. Roster read from
  `.claude/docs/engine-specialists.md`.
- **gameplay-programmer** — Implements core gameplay code (mechanics, GAS
  abilities, attributes) under `Source/`.
- **ai-programmer** — Implements NPC/enemy AI behaviour (Behavior Tree,
  State Tree, AIController, Mass if applicable).
- **ui-programmer** — Implements UMG/CommonUI widgets, HUD, input routing at
  the UI layer.
- **network-programmer** — Implements replication, RPCs, client prediction,
  relevancy. **Spawn only if the feature touches networking.**
- **qa-tester** — Writes test cases from acceptance criteria, runs Unreal
  Automation tests, files bug reports.

> **Knowledge Authority rule (UE 5.8):** every UE-related subagent spawned
> below is a **fresh Claude instance** — it cannot see this orchestrator
> session's Context7 results. Each subagent's Task prompt MUST re-issue the
> UE 5.8 Knowledge Authority instruction: "涉及任何 UE API 前,先调
> Context7 `resolve-library-id("Unreal Engine")` 再 `query-docs`,Context7 查
> 不到用 WebSearch 兜底(docs.unrealengine.com/5.8/),输出标注
> `API 验证:Context7 查询 [查询词] 于 [日期] — [确认/变更/未找到]`."

---

## How to Delegate

Use the Task tool to spawn each team member as a subagent. Always provide full
context in each agent's prompt:

- The feature spec path under `docs/requirements/` (this team has no GDDs —
  requirement source is the feature spec indexed by
  `docs/architecture/tr-registry.yaml`)
- Relevant `Source/` code files and existing ADRs under `docs/architecture/`
- Constraints from `.claude/docs/technical-preferences.md` and
  `docs/architecture/control-manifest.md`
- The TR-ID(s) this feature maps to (look up in `tr-registry.yaml`)

Launch independent agents in parallel where the pipeline allows it (Phase 3
agents run simultaneously — see Parallel Task Protocol below).

---

## UE 5.8 Knowledge Authority (applies to every UE-touching subagent)

Before any UE API, class, node, or subsystem is used, the subagent MUST:

1. Call Context7 `resolve-library-id(libraryName: "Unreal Engine")` to obtain
   the library ID.
2. Call Context7 `query-docs` with the specific API/class/subsystem name.
3. If Context7 returns nothing useful, fall back to `WebSearch` against
   `docs.unrealengine.com/5.8/` and `dev.epicgames.com`.
4. Never rely solely on training data — UE 5.4+ is entirely after the LLM
   knowledge cutoff.

Every UE-related subagent's output MUST include the stamp:
`API 验证:Context7 查询 [查询词] 于 [日期] — [确认/变更/未找到]`

---

## Pipeline

### Phase 1: Design / Requirements Clarification

Resolve the requirement source BEFORE spawning anyone:

1. Read `docs/architecture/tr-registry.yaml` and locate the TR-ID(s) the
   feature argument maps to.
2. Read the corresponding feature spec(s) under `docs/requirements/`
   (the `spec:`/`source:` field in the registry entry gives the file path).
3. If no TR-ID matches the feature description, ask the user: "Which feature
   spec in `docs/requirements/` does this map to? Or should we draft a minimal
   spec first?" — do NOT guess.

Delegate to **lead-programmer**:
- Read the feature spec and current architecture
- Produce a *requirements boundary doc*: scope in / scope out, key rules,
  acceptance criteria extracted from the spec, integration points with
  existing systems, open questions that need user clarification
- Output: requirements boundary doc (written to
  `production/features/[feature-slug]/requirements.md` by the subagent, after
  asking "May I write to [path]?")

Surface the boundary doc + open questions to the user via `AskUserQuestion`.
Resolve the open questions before proceeding to Phase 2.

### Phase 2: Architecture

Delegate to **lead-programmer**:
- Review the requirements boundary doc
- Design the code architecture: class structure (UE Actor/Component/UObject
  layout), interfaces, data flow, file list under `Source/`
- Identify integration points with existing systems
- Identify which UE sub-specialists will be needed in Phase 3
- Output: architecture sketch with file list and interface definitions

Then spawn the **unreal-specialist** (with relevant sub-specialists as needed)
to validate the proposed architecture **using Context7**:
- Resolve `resolve-library-id("Unreal Engine")` and `query-docs` for every UE
  API/class the sketch proposes (e.g., `UAbilitySystemComponent`,
  `APlayerController`, `UEnhancedInputComponent`, `UUserWidget`,
  `UActorComponent`)
- Is the Actor/Component/UObject structure idiomatic for UE 5.8?
- Are there engine-native systems (GAS, Enhanced Input, CommonUI, Mass,
  Gameplay Tasks) that should be used instead of custom implementations?
- Any proposed APIs that are deprecated or changed in UE 5.4–5.8? (These are
  all post-cutoff — must verify, not assume.)
- Output: engine architecture notes with Context7 verification stamps —
  incorporate into the architecture before Phase 3 begins

Use `AskUserQuestion`:
- Prompt: "Architecture sketch complete with Context7-verified UE 5.8 idioms.
  Approve to proceed with parallel implementation."
- Options:
  - `[A] Proceed — spawn implementation agents (gameplay-programmer,
    ai-programmer, ui-programmer, [network-programmer])`
  - `[B] Revise the architecture first — I'll describe what needs to change`
  - `[C] Stop here — I'll continue later`

Only spawn implementation agents if user selects [A].

### Phase 3: Implementation (parallel)

Apply the **Parallel Task Protocol** (see Error Recovery Protocol section):

1. **先发后等** — Issue all independent Task calls in a single batch. Do NOT
   wait for one before issuing the next.
2. **收齐再走** — Collect ALL results before advancing to Phase 4 (integration
   depends on every piece).
3. **阻塞立即上报** — If any agent returns BLOCKED, surface it immediately
   (see Error Recovery Protocol).
4. **必出部分报告** — Even if some agents block, produce a partial report of
   what completed.

Delegate in parallel (only spawn agents whose domain the feature touches):

- **gameplay-programmer**: Implement core mechanic code under `Source/`
  (gameplay ability, attribute, component). Subagent prompt MUST include the
  UE 5.8 Knowledge Authority block above.
- **ai-programmer**: Implement AI behaviors (Behavior Tree / State Tree /
  AIController tasks). Subagent prompt MUST include the UE 5.8 Knowledge
  Authority block. Skip if the feature has no AI component.
- **ui-programmer**: Implement UMG/CommonUI widgets, HUD, input routing.
  Subagent prompt MUST include the UE 5.8 Knowledge Authority block. Skip if
  the feature has no UI.
- **network-programmer**: Implement replication, RPCs, client prediction.
  Subagent prompt MUST include the UE 5.8 Knowledge Authority block. Skip if
  the feature is single-player or has no networking.

Each implementation subagent:
- Reads the architecture sketch from Phase 2
- Writes only within its domain (domain boundary铁律 — see coordination rules)
- Asks "May I write to [path]?" before each file write
- Includes Context7 verification stamps for every UE API used in its output

### Phase 4: Integration

Delegate to **lead-programmer**:
- Wire together gameplay, AI, UI, and (if present) network code
- Ensure all tuning knobs are exposed and data-driven (config files / data
  tables, not hardcoded literals)
- Verify the feature works with existing systems per the architecture sketch
- Resolve any cross-domain seams (the lead-programmer is the coordination
  owner — producer was cut, this duty folds here)
- Output: integration notes + list of any seams that need a follow-up ADR

If integration reveals an architectural gap, do NOT silently re-architect —
surface it via `AskUserQuestion` and consider spawning `/architecture-decision`
for the gap before continuing.

### Phase 5: Validation

Delegate to **qa-tester**:
- Write test cases from the acceptance criteria (Phase 1 boundary doc)
- Write Unreal Automation tests under `tests/unit/` and `tests/integration/`
  (mapped to `Source/` test modules)
- Test all edge cases documented in the feature spec
- Verify performance impact is within budget (read
  `.claude/docs/technical-preferences.md` targets)
- File bug reports for any issues found under `production/qa/bugs/`
- Output: test results + bug list

Any UE API used in test stubs/mocks must also carry a Context7 verification
stamp — test code is still UE-touching code.

### Phase 6: Sign-off

Collect results from all team members. Present the final report:

```
## Team Feature: [Feature Name]
**Feature spec**: [path]
**TR-ID(s)**: [list]
**Date**: [today]

### Phase Completion
- Phase 1 Requirements:    [COMPLETE / PARTIAL / BLOCKED]
- Phase 2 Architecture:    [COMPLETE / PARTIAL / BLOCKED]  (Context7 verified: Y/N)
- Phase 3 Implementation:  [per-agent status]
  - gameplay-programmer:   [COMPLETE / PARTIAL / BLOCKED]
  - ai-programmer:         [COMPLETE / SKIPPED / BLOCKED]
  - ui-programmer:         [COMPLETE / SKIPPED / BLOCKED]
  - network-programmer:    [COMPLETE / SKIPPED / BLOCKED]
- Phase 4 Integration:     [COMPLETE / PARTIAL / BLOCKED]
- Phase 5 Validation:      [tests passed/failed count, bugs filed]
- Phase 6 Sign-off:        [verdict below]

### UE 5.8 API Verification Summary
- Context7 queries run: [N]
- APIs confirmed: [list]
- APIs changed in 5.x: [list]
- WebSearch fallbacks: [list]
- Unverified: [list — these are blockers]

### Open Issues
1. [issue] — owner: [agent]
2. ...

### Verdict: [COMPLETE / NEEDS WORK / BLOCKED]
```

- **COMPLETE** — feature designed, implemented, integrated, and validated.
- **NEEDS WORK** — implemented but validation found issues; list owners.
- **BLOCKED** — one or more phases could not complete; partial report produced
  with unresolved items listed.

---

## Error Recovery Protocol

If any spawned agent (via Task) returns BLOCKED, errors, or cannot complete:

1. **Surface immediately** — Report "[AgentName]: BLOCKED — [reason]" to the
   user before continuing to dependent phases. (阻塞立即上报)
2. **Assess dependencies** — Check whether the blocked agent's output is
   required by subsequent phases. If yes, do not proceed past that dependency
   point without user input.
3. **Offer options** via `AskUserQuestion` with choices:
   - Skip this agent and note the gap in the final report
   - Retry with narrower scope
   - Stop here and resolve the blocker first
4. **Always produce a partial report** — output whatever was completed. Never
   discard work because one agent blocked. (必出部分报告)

Common blockers:
- Feature spec missing or TR-ID not in `tr-registry.yaml` → redirect: draft a
  minimal spec under `docs/requirements/` first
- ADR status is `Proposed` (not `Accepted`) → do not implement; run
  `/architecture-decision` first to move it to Accepted
- UE API not found in Context7 AND not confirmable via WebSearch → BLOCKING;
  flag for `/architecture-decision` to record the uncertainty
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and feature spec → surface the conflict,
  do not guess; escalate to `technical-director` via `TD-PHASE-GATE` if needed

---

## Parallel Task Protocol

This orchestrator follows the four-rule parallel protocol (原样保留):

1. **先发后等** — All independent Task calls are issued together in one batch.
2. **收齐再走** — Wait for all results before advancing to the dependent phase.
3. **阻塞立即上报** — Any agent BLOCKED is reported to the user immediately.
4. **必出部分报告** — A partial report is always produced, even if some agents
   block.

---

## File Write Protocol

All file writes (requirements boundary docs, architecture sketches,
implementation files, test cases) are delegated to sub-agents spawned via Task.
Each sub-agent enforces the "May I write to [path]?" protocol. This orchestrator
does not write files directly.

---

## Domain Boundary Rule (铁律)

`gameplay-programmer` cannot edit files under `Source/UI/`; `ui-programmer`
cannot edit files under `Source/AI/`; etc. Cross-domain changes are coordinated
by `lead-programmer` (the producer's coordination duty folds here — producer was
cut from this team). See `.claude/docs/coordination-rules.md` rule 5.

---

## Next Steps

After verdict is rendered:

- Run `/code-review` on the implemented code before closing any stories.
- Run `/story-done [story-path]` for each story this feature decomposed into.
- If the feature surfaced an architectural gap, run
  `/architecture-decision [topic]` to record it as an ADR.
- Run `/gate-check implementation` if this feature was the last item needed to
  advance the project phase.
