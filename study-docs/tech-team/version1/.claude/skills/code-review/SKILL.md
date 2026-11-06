---
name: code-review
description: "Performs an architectural and quality code review on a specified file or set of files. Checks for coding standard compliance, architectural pattern adherence, SOLID principles, testability, UE 5.8 API correctness (verified via Context7), and performance concerns."
argument-hint: "[path-to-file-or-directory]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Task, AskUserQuestion, run_mcp
model: sonnet
agent: lead-programmer
---

## Phase 1: Load Target Files

Read the target file(s) in full. Read CLAUDE.md for project coding standards.

---

## Phase 2: Identify Engine Specialists

Read `.claude/docs/technical-preferences.md`, section `## Engine Specialists`
(or `.claude/docs/engine-specialists.md`). Note:

- The **Primary** specialist (`unreal-specialist` — UE total authority)
- The **GAS Specialist** (`ue-gas-specialist`)
- The **Blueprint Specialist** (`ue-blueprint-specialist`)
- The **UI Specialist** (`ue-umg-specialist`)
- The **Replication Specialist** (`ue-replication-specialist` — only if multiplayer)

If the section reads `[TO BE CONFIGURED]`, no engine is pinned — skip engine
specialist steps. (In this team the engine is always Unreal Engine 5.8, so this
branch should not occur.)

---

## Phase 3: ADR Compliance Check

**Argument:** `/code-review [file(s)]` may optionally include a story file path as the last argument (e.g., `/code-review Source/Combat/Attack.cpp production/epics/combat/story-001.md`). If a story path is provided, read it to extract the governing ADR reference.

Search for ADR references in, in priority order:
1. The story file (if provided as argument)
2. Header comments at the top of the implementation files
3. Commit messages referencing these files (`git log --oneline -- [file]`)

Look for patterns like `ADR-NNN` or `docs/architecture/ADR-`.

If no ADR references found, note: "No ADR references found — ADR compliance check skipped. For full ADR compliance review, provide the story path: `/code-review [files] [story-path]`."

For each referenced ADR: read the file, extract the **Decision** and **Consequences** sections, then classify any deviation:

- **ARCHITECTURAL VIOLATION** (BLOCKING): Uses a pattern explicitly rejected in the ADR
- **ADR DRIFT** (WARNING): Meaningfully diverges from the chosen approach without using a forbidden pattern
- **MINOR DEVIATION** (INFO): Small difference from ADR guidance that doesn't affect overall architecture

---

## Phase 4: Standards Compliance

Identify the system category (engine, gameplay, AI, networking, UI, tools) and evaluate:

- [ ] Public methods and classes have doc comments
- [ ] Cyclomatic complexity under 10 per method
- [ ] No method exceeds 40 lines (excluding data declarations)
- [ ] Dependencies are injected (no static singletons for game state)
- [ ] Configuration values loaded from data files
- [ ] Systems expose interfaces (not concrete class dependencies)

---

## Phase 5: Architecture and SOLID

**Architecture:**
- [ ] Correct dependency direction (engine <- gameplay, not reverse)
- [ ] No circular dependencies between modules
- [ ] Proper layer separation (UI does not own game state)
- [ ] Events/delegates used for cross-system communication (UE multicast delegates, not direct calls)
- [ ] Consistent with established patterns in the codebase

**SOLID:**
- [ ] Single Responsibility: Each class has one reason to change
- [ ] Open/Closed: Extendable without modification
- [ ] Liskov Substitution: Subtypes substitutable for base types
- [ ] Interface Segregation: No fat interfaces
- [ ] Dependency Inversion: Depends on abstractions, not concretions

---

## Phase 6: UE 5.8 Game-Specific Concerns

- [ ] Frame-rate independence (delta time usage — UE `DeltaTime` parameter)
- [ ] No allocations in hot paths (Tick loops, gameplay ability activation)
- [ ] Proper null/empty state handling (UObject nullptr checks, IsValid() for Actors)
- [ ] Thread safety where required (Async tasks, UPROPERTY thread safety)
- [ ] Resource cleanup (no leaks — UE garbage collection boundaries respected)
- [ ] Replication correctness (if applicable — server authority, client prediction)
- [ ] GAS correctness (if applicable — Attribute, Effect, Ability lifecycle)

---

## Phase 7: Specialist Reviews (Parallel)

Spawn all applicable specialists simultaneously via Task — do not wait for one before starting the next.

### Engine Specialists (UE 5.8 sub-specialists)

The engine is **Unreal Engine 5.8** (always pinned in this team). Determine which specialist applies to each file and spawn in parallel:

- Game code (.cpp, .h files — Actor, Component, Subsystem) → `unreal-specialist`
- GAS code (AbilitySystemComponent, GameplayEffect, AttributeSet, GameplayTag) → `ue-gas-specialist`
- Blueprint graph files / BP architecture review → `ue-blueprint-specialist`
- UI / widget code (UMG, CommonUI, Slate) → `ue-umg-specialist`
- Networked code (replicated properties, RPCs, prediction) → `ue-replication-specialist`
- Cross-cutting or unclear → `unreal-specialist`

Also always spawn `unreal-specialist` for any file touching engine architecture
(subsystem registration, module setup, lifecycle hooks).

**Critical — Context7 UE API Verification (mandatory for every specialist)**:

Each spawned UE sub-specialist is a fresh Claude instance and cannot see this
session's prior Context7 queries. Instruct each specialist to:

1. Call Context7 `resolve-library-id(libraryName: "Unreal Engine")` to get the
   UE library ID (do this once at the start of the review).
2. For every UE API, class, or subsystem referenced in the file(s) under review,
   call Context7 `query-docs` with a specific query like
   `"UAbilitySystemComponent ApplyGameplayEffectToTarget 5.8 signature"` to
   verify the API exists in UE 5.8 with the expected signature.
3. Fall back to `WebSearch` against `docs.unrealengine.com/5.8/` and
   `dev.epicgames.com` if Context7 returns nothing.
4. NEVER accept "I know this API from training data" as justification — UE 5.4+
   is beyond the LLM knowledge cutoff.
5. Stamp every API verification in the review output:
   `API 验证:Context7 查询 [查询词] 于 [日期] — [确认/变更/未找到]`

Specialist review should cover:
- Is the UE API usage correct for 5.8? (signature, semantics, threading)
- Are there deprecated APIs in use? (flag any 5.x deprecation)
- Are there engine-native systems that should be used instead of custom implementations?
- Are there UE 5.8 anti-patterns (e.g., GAS misuse, BP/C++ boundary violations, subsystem coupling)?
- Do ADR `Engine Compatibility` assumptions still hold for this code?

### QA Testability Review

For Logic and Integration stories, also spawn `qa-tester` via Task in parallel with the engine specialists. Pass:
- The implementation files being reviewed
- The story's `## QA Test Cases` section (the pre-written test specs from qa-lead)
- The story's `## Acceptance Criteria`

Ask the qa-tester to evaluate:
- [ ] Are all test hooks and interfaces exposed (not hidden behind private/internal access)?
- [ ] Do the QA test cases from the story's `## QA Test Cases` section map to testable code paths?
- [ ] Are any acceptance criteria untestable as implemented (e.g., hardcoded values, no seam for injection)?
- [ ] Does the implementation introduce any new edge cases not covered by the existing QA test cases?
- [ ] Are there any observable side effects that should have a test but don't?

For Visual/Feel and UI stories: qa-tester reviews whether the manual verification steps in `## QA Test Cases` are achievable with the implementation as written — e.g., "is the state the manual checker needs to reach actually reachable?"

Collect all specialist findings before producing output.

---

## Phase 8: Output Review

```
## Code Review: [File/System Name]

### Engine Specialist Findings: [CLEAN / ISSUES FOUND]
[Findings from UE sub-specialist(s), each with Context7 API verification stamps]
[Examples: "UAbilitySystemComponent::ApplyGameplayEffectSpecToTarget 5.8 signature confirmed via Context7 query on [date]"]

### Testability: [N/A — Visual/Feel or Config story / TESTABLE / GAPS / BLOCKING]
[qa-tester findings: test hooks, coverage gaps, untestable paths, new edge cases]
[If BLOCKING: implementation must expose [X] before tests in ## QA Test Cases can run]

### ADR Compliance: [NO ADRS FOUND / COMPLIANT / DRIFT / VIOLATION]
[List each ADR checked, result, and any deviations with severity]

### Standards Compliance: [X/6 passing]
[List failures with line references]

### Architecture: [CLEAN / MINOR ISSUES / VIOLATIONS FOUND]
[List specific architectural concerns]

### SOLID: [COMPLIANT / ISSUES FOUND]
[List specific violations]

### UE 5.8 Game-Specific Concerns
[List game development specific issues — GAS, replication, threading, etc.]

### Positive Observations
[What is done well -- always include this section]

### Required Changes
[Must-fix items before approval — ARCHITECTURAL VIOLATIONs and deprecated-API usages always appear here]

### Suggestions
[Nice-to-have improvements]

### Verdict: [APPROVED / APPROVED WITH SUGGESTIONS / CHANGES REQUIRED]
```

This skill is read-only — no files are written.

---

## Phase 9: Next Steps

Use `AskUserQuestion`:
- Prompt: "Code review complete — verdict: [APPROVED / CHANGES REQUIRED / MAJOR REVISION]. How would you like to proceed?"
- Options (adjust based on verdict):
  - If APPROVED:
    - `[A] Run /story-done to mark the story complete`
    - `[B] Stop here`
  - If CHANGES REQUIRED or MAJOR REVISION:
    - `[A] Fix the issues and re-run /code-review`
    - `[B] Run /story-done anyway with noted exceptions`
    - `[C] Stop here`

If an ARCHITECTURAL VIOLATION is found:
- If the violation contradicts an **existing ADR**: fix the implementation to comply with `docs/architecture/[adr-file].md`. If the design has legitimately changed, run `/architecture-decision` to formally *revise* the existing ADR — do not create a competing one.
- If **no ADR exists** for the pattern that was violated: run `/architecture-decision` to document the correct approach before fixing the code.

If a UE 5.8 deprecated/changed API usage is found (Context7-verified):
- Surface the deprecation prominently. Replace the API with the 5.8-recommended
  equivalent. If the ADR specified the deprecated API, run `/architecture-decision`
  to revise the ADR with the verified 5.8 alternative.
