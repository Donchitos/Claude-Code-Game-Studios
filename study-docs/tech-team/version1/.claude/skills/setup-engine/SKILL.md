---
name: setup-engine
description: "Lightweight setup for the UE 5.8 technical contract. Engine is pinned to Unreal Engine 5.8 and knowledge source to Context7 MCP — those are NOT asked. Asks only 5 project-level questions (target platforms, input method, naming conventions, performance budget, test framework) and writes technical-preferences.md plus the UE sub-specialist routing table."
argument-hint: "[no arguments — engine and knowledge source are pre-filled]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, run_mcp
model: sonnet
---

# Setup Engine (Lightweight, UE 5.8)

This skill is the technical setup entry point. Unlike a generic engine picker, the
engine and knowledge source are **already decided** for this project:

- **Engine**: Unreal Engine 5.8 (fixed — do not ask)
- **Knowledge Source**: Context7 MCP (fixed — runtime UE API authority, no static `docs/engine-reference/` directory is maintained)

What this skill still does — the three things Context7 cannot do:
1. Pin project-level **naming conventions** (class/variable/file naming)
2. Pin **performance budgets** (framerate, frame budget, memory ceiling)
3. Pin **target platforms** and **input method**
4. Pin the **test framework** and minimum coverage
5. Write the **UE sub-specialist routing table** (which file type dispatches to which `ue-*-specialist`)

**Outputs:**
- `.claude/docs/technical-preferences.md` — the config contract read by `/dev-story`, `/code-review`, `/architecture-decision`, `/architecture-review`
- `.claude/docs/engine-specialists.md` — the UE 5.8 sub-specialist routing table

---

## 1. Confirm the Fixed Stack

Before asking anything, state the fixed stack so the user knows what is not negotiable:

```
Engine:          Unreal Engine 5.8 (fixed)
Language:        C++ (primary), Blueprint (content/prototyping)
Build System:    Unreal Build Tool (UBT)
Asset Pipeline:  Unreal Content Pipeline
Knowledge Source: Context7 MCP (resolve-library-id + query-docs)
                   Context7 查不到时用 WebSearch 兜底(docs.unrealengine.com/5.8/)
```

Read `CLAUDE.md` and show the user the proposed Technology Stack block. Ask: "May I write these engine settings to `CLAUDE.md`?" Wait for confirmation, then update the Technology Stack section (replacing any `[CHOOSE]` placeholders).

If `CLAUDE.md` already has the UE 5.8 stack written, skip the write and note it.

---

## 2. Ask the 5 Project-Level Questions

Use `AskUserQuestion` for each. These are the only things left to configure.

### Question 1 — Target platforms

- Prompt: "What platforms are you targeting for this UE 5.8 project?"
- Options: `PC (Windows)` / `PC + Console` / `Console only` / `PC + Mobile` / `Multiple platforms`
- Record the answer. Console/Mobile imply additional packaging and certification constraints noted later.

### Question 2 — Primary input method

- Prompt: "What is the primary input method?"
- Options: `Keyboard/Mouse` / `Gamepad` / `Keyboard/Mouse + Gamepad` / `Touch`
- Record. Determines Enhanced Input setup and UI navigation requirements.

### Question 3 — Naming conventions

UE 5.8 C++ naming defaults are presented as the recommendation:

- Classes: Prefixed PascalCase (`A` Actor, `U` UObject, `F` struct, `I` interface, `E` enum, `S` SlateWidget)
- Variables: PascalCase (e.g., `MoveSpeed`)
- Functions: PascalCase (e.g., `TakeDamage()`)
- Booleans: `b` prefix (e.g., `bIsAlive`)
- Files: match class without prefix (e.g., `PlayerController.h`)
- Blueprint assets: PascalCase, prefixed by type (`BP_`, `WBP_`, `DT_`, `GA_`, `GE_`, `AS_`)

- Prompt: "Use the UE 5.8 standard naming conventions above, or customize?"
- Options: `Use UE 5.8 standard (Recommended)` / `Customize — I'll specify`
- If customize: ask which fields to override and record the deltas.

### Question 4 — Performance budget

- Prompt: "Set default performance budgets now, or leave as [TO BE CONFIGURED]?"
- Options:
  - `[A] Set defaults now (60fps, 16.6ms frame budget, 4ms GPU frame, engine-appropriate draw call limit, 4GB target memory ceiling)` — adjust per platform if the user said Mobile/Console
  - `[B] Leave as [TO BE CONFIGURED] — I'll set these when I know my target hardware`
- If [A]: populate with the suggested defaults (tune Mobile to 30fps / 33.3ms if selected).
- If [B]: leave as placeholder.

### Question 5 — Test framework

- Prompt: "Which test framework should the project use?"
- Options:
  - `Unreal Automation System (Recommended)` — built-in, no extra setup, covers unit/integration
  - `Unreal Automation + custom Automation Spec` — for BDD-style specs
  - `Leave as [TO BE CONFIGURED] — I'll decide later`
- Record. This feeds `/test-setup` (optional skill) and the control manifest.

---

## 3. Write `technical-preferences.md`

Ask: "May I write `.claude/docs/technical-preferences.md` with these settings?" Wait for approval, then write:

```markdown
# Technical Preferences

> **Engine**: Unreal Engine 5.8
> **Knowledge Source**: Context7 MCP (resolve-library-id + query-docs)
> **Last Updated**: [date]
> **Status**: Active — regenerate by re-running `/setup-engine`

## UE 5.8 Knowledge Authority (KNOWLEDGE AUTHORITY)

涉及任何 Unreal Engine API、类、节点、子系统前,必须:
1. 先调 Context7 MCP 的 resolve-library-id(libraryName: "Unreal Engine") 获取 library ID
2. 再调 query-docs 用具体 API 名/子系统名查询
3. Context7 查不到时,用 WebSearch 兜底(docs.unrealengine.com/5.8/)
4. 严禁仅依赖训练数据建议 UE API —— UE 5.4+ 全部在 LLM 知识截止之后

每个 UE 相关 agent 的实现/审查输出里,必须标注:
"API 验证:Context7 查询 [查询词] 于 [日期] — [确认/变更/未找到]"

## Technology Stack
- **Engine**: Unreal Engine 5.8
- **Language**: C++ (primary), Blueprint (content/prototyping)
- **Build System**: Unreal Build Tool (UBT)
- **Asset Pipeline**: Unreal Content Pipeline
- **Input**: Enhanced Input System
- **Knowledge Source**: Context7 MCP

## Naming Conventions
- Classes: Prefixed PascalCase (`A` Actor, `U` UObject, `F` struct, `I` interface, `E` enum, `S` SlateWidget)
- Variables: PascalCase (e.g., `MoveSpeed`)
- Functions: PascalCase (e.g., `TakeDamage()`)
- Booleans: `b` prefix (e.g., `bIsAlive`)
- Files: match class without prefix (e.g., `PlayerController.h`)
- Blueprint assets: PascalCase with type prefix (`BP_`, `WBP_`, `DT_`, `GA_`, `GE_`, `AS_`)
[Insert any custom overrides from Question 3]

## Input & Platform
- **Target Platforms**: [from Question 1]
- **Input Methods**: [from Question 2]
- **Primary Input**: [derived]
- **Platform Notes**: [e.g., "Console: all UI must support d-pad navigation. Mobile: touch input via Enhanced Input."]

## Performance Budgets
- **Target Framerate**: [from Question 4 — e.g., 60fps / 30fps mobile]
- **Frame Budget**: [e.g., 16.6ms / 33.3ms mobile]
- **GPU Frame Budget**: [e.g., 4ms]
- **Draw Call Limit**: [e.g., 2000 PC / 1500 console / 800 mobile]
- **Memory Ceiling**: [e.g., 4GB target]
[Or "[TO BE CONFIGURED]" if Question 4 = B]

## Testing
- **Framework**: [from Question 5]
- **Minimum Coverage**: Logic and Integration stories must have automated tests; coverage tracked via `/qa-plan` and `/story-done`
- **Test Directory**: `tests/` mapped to Unreal Automation tests under `Source/` test modules

## Forbidden Patterns
[TO BE CONFIGURED — populated by `/create-control-manifest` from Accepted ADRs]

## Allowed Libraries
[TO BE CONFIGURED — add a library only when actively being integrated, never speculatively]
```

> **Guardrail**: Never add speculative plugins to Allowed Libraries. Only add a plugin when integration is actively beginning in this session.

---

## 4. Write `engine-specialists.md`

Ask: "May I write `.claude/docs/engine-specialists.md` (the UE sub-specialist routing table)?" Wait for approval, then write:

```markdown
# UE 5.8 Engine Specialist Routing

> **Primary**: unreal-specialist (UE total authority — BP/C++ boundary, subsystems, delegates to sub-specialists)
> **Last Updated**: [date]

## Specialist Roster

| Specialist | Domain |
|------------|--------|
| `unreal-specialist` | UE total authority, C++ architecture, broad engine decisions, dispatches sub-specialists |
| `ue-gas-specialist` | Gameplay Ability System — Gameplay Effects, Attribute Sets, Gameplay Tags, Abilities |
| `ue-blueprint-specialist` | Blueprint architecture, BP/C++ boundary, graph standards |
| `ue-umg-specialist` | UMG, CommonUI, widget hierarchy, data binding, input routing at the UI layer |
| `ue-replication-specialist` | Property replication, RPCs, client prediction, relevancy (enable for multiplayer) |

## Routing Notes

- Invoke `unreal-specialist` for C++ architecture, ADR validation, and cross-cutting engine review.
- Invoke `ue-blueprint-specialist` for Blueprint graph architecture and BP/C++ boundary design.
- Invoke `ue-gas-specialist` for ALL ability, attribute, and gameplay effect code.
- Invoke `ue-umg-specialist` for ALL UI implementation (UMG widgets, CommonUI, input routing).
- Invoke `ue-replication-specialist` for ANY multiplayer or networked system.
- All five specialists have the `Task` tool and can be further delegated by `unreal-specialist`.

## File Extension / Type Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.cpp, .h files) | unreal-specialist |
| Shader / material files (.usf, .ush, Material assets) | unreal-specialist |
| UI / screen files (.umg, UMG Widget Blueprints, CommonUI) | ue-umg-specialist |
| Scene / level files (.umap, .uasset) | unreal-specialist |
| Plugin files (.uplugin, modules) | unreal-specialist |
| Blueprint graphs (.uasset BP classes) | ue-blueprint-specialist |
| GAS code (AbilitySystemComponent, GameplayEffect, AttributeSet) | ue-gas-specialist |
| Networked code (replicated properties, RPCs, prediction) | ue-replication-specialist |
| General architecture review | unreal-specialist |

## Context7 Rule (applies to every specialist)

Every UE sub-specialist must, before recommending any UE API:
1. Call Context7 `resolve-library-id(libraryName: "Unreal Engine")` to get the library ID.
2. Call `query-docs` with the specific API/class/subsystem name.
3. Fall back to `WebSearch` against `docs.unrealengine.com/5.8/` if Context7 returns nothing.
4. NEVER rely on training data alone — UE 5.4+ is beyond the LLM knowledge cutoff.
5. Stamp output: "API 验证:Context7 查询 [查询词] 于 [日期] — [确认/变更/未找到]".
```

Also add a short `## Engine Specialists` section to `technical-preferences.md` pointing at this file (single line: `See .claude/docs/engine-specialists.md for the full routing table.`).

---

## 5. Output Summary

```
Engine Setup Complete (Lightweight)
====================================
Engine:          Unreal Engine 5.8 (pre-filled)
Knowledge Source: Context7 MCP (pre-filled)
CLAUDE.md:       [updated / already set]
Tech Prefs:      .claude/docs/technical-preferences.md [created]
Specialist Map:  .claude/docs/engine-specialists.md [created]

Configured this session:
  Target platforms: [answer]
  Input method:     [answer]
  Naming:           [UE 5.8 standard / custom]
  Performance:      [defaults / deferred]
  Test framework:   [answer]

Next Steps:
1. Write your feature spec(s) under docs/requirements/ (if not already)
2. Run /architecture-decision [title] for each Foundation-layer decision (≥3)
3. Run /create-architecture to produce the master architecture blueprint
4. Run /create-control-manifest to flatten ADRs into programmer rules
5. Run /architecture-review to validate coverage and engine compatibility (via Context7)
```

Verdict: **COMPLETE** — UE 5.8 technical contract configured.

---

## Guardrails

- NEVER ask which engine to use — it is fixed at Unreal Engine 5.8.
- NEVER maintain a static `docs/engine-reference/` directory or `VERSION.md` — Context7 is the runtime authority.
- NEVER add speculative plugins to Allowed Libraries.
- Always show the user what you are about to change before editing `CLAUDE.md`.
- If the user wants to change the engine version (e.g., upgrade to 5.9 later), re-run this skill and update the version field — Context7 will be queried against the new version at runtime by each UE specialist.
