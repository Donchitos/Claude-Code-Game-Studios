---
name: setup-engine
description: "Configure engine and version. Pins it in CLAUDE.md; WebSearch fills reference docs when the version is beyond LLM training data."
argument-hint: "[engine] | [engine version] | refresh | upgrade [old-version] [new-version] | no args for guided selection"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, WebSearch, WebFetch, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/setup-engine/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

When this skill is invoked:

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow`

**Tier awareness.** The `workflow` tier resolved above governs which design
artifact this skill expects and the finish path it recommends in §12:
- **`minimal`** — the design artifact is the one-page `design/game-brief.md`
  (no GDDs, systems decomposition, or per-system design at this tier).
  `/setup-engine` runs *first* in the minimal path, so a missing brief here is
  normal, not a gap. The finish path is the 4-step floor.
- **`standard` / `full`** — the design artifact is `design/gdd/game-concept.md`
  and the finish path is the full pipeline.

If the block did not render (shell preprocessing disabled), assume `standard`.

## 1. Parse Arguments

Four modes:

- **Full spec**: `/setup-engine godot 4.6` — engine and version provided
- **Engine only**: `/setup-engine unity` — engine provided, version will be looked up
- **No args**: `/setup-engine` — fully guided mode (engine recommendation + version)
- **Refresh**: `/setup-engine refresh` — update reference docs (see Section 10)
- **Upgrade**: `/setup-engine upgrade [old-version] [new-version]` — migrate to a new engine version (see Section 11)

---

## 2. Guided Mode (No Arguments)

If no engine is specified, run an interactive engine selection process:

### Check for existing game concept
Read the design artifact for the resolved tier (see **Tier awareness** above):
- **`standard` / `full`**: read `design/gdd/game-concept.md` if it exists —
  extract genre, scope, platform targets, art style, team size, and any engine
  recommendation from `/brainstorm`.
- **`minimal`**: read `design/game-brief.md` if it exists — extract genre,
  scope, platform, and art direction from its fields. Its absence is **expected**
  at `minimal` (the brief is authored *after* engine setup in the minimal path), so
  do not treat a missing brief as a gap — proceed straight to guided selection.
- If no concept **or** brief exists, inform the user:
  > "No game concept found. Consider running `/brainstorm` first to discover what
  > you want to build — it will also recommend an engine. Or tell me about your
  > game and I can help you pick."

  (At `minimal` this is optional, not a prerequisite — you can pick an engine now
  and write the brief next.)

### If the user wants to pick without a concept, ask in this order:

**Question 1 — Prior experience** (ask this first, always, via `AskUserQuestion`):
- Prompt: "Have you worked in any of these engines before?"
- Options: `Godot` / `Unity` / `Unreal Engine 5` / `Multiple — I'll explain` / `None of them`
- If they pick a specific engine → recommend that engine. Prior experience outweighs all other factors. Confirm with them and skip the matrix.
- If "None" or "Multiple" → continue to the questions below.

**Questions 2-6 — Decision matrix inputs** (only if no prior engine experience):

**Question 2 — Target platform** (ask this second, always, via `AskUserQuestion` — platform eliminates or heavily weights engines before any other factor):
- Prompt: "What platforms are you targeting for this game?"
- Options: `PC (Steam / Epic)` / `Mobile (iOS / Android)` / `Console` / `Web / Browser` / `Multiple platforms`
- Platform rules that feed directly into the recommendation:
  - Mobile → Unity strongly preferred; Unreal is a poor fit; Godot is viable for simple mobile
  - Console → Unity or Unreal; Godot console support requires third-party publishers or significant extra work
  - Web → Godot exports cleanly to web; Unity WebGL is functional; Unreal has poor web support
  - PC only → all engines viable; other factors decide
  - Multiple → Unity is the most portable across PC/mobile/console

1. **What kind of game?** (2D, 3D, or both?)
2. **Primary input method?** (keyboard/mouse, gamepad, touch, or mixed?)
3. **Team size and experience?** (solo beginner, solo experienced, small team?)
4. **Any strong language preferences?** (GDScript, C#, C++, visual scripting?)
5. **Budget for engine licensing?** (free only, or commercial licenses OK?)

### Produce a recommendation

Do NOT use a simple scoring matrix that eliminates engines. Instead, reason through the user's profile against the honest tradeoffs below, then present 1-2 recommendations with full context. Always end with the user choosing — never force a verdict.

**Engine honest tradeoffs:**

**Godot 4**
- Genuine strengths: 2D (best in class), stylized/indie 3D, rapid iteration, free forever (MIT), open source, gentlest learning curve, best for solo devs who want full control
- Real limitations: 3D ecosystem is thin compared to Unity/Unreal (fewer tutorials, assets, community answers for 3D-specific problems); large open-world 3D is very hard and largely untested in Godot; console export requires third-party publishers or significant extra work; smaller professional job market
- Licensing reality: Truly free with no revenue thresholds ever. MIT license means you own everything.
- Best fit: 2D games of any scope; stylized/atmospheric 3D; contained 3D worlds (not open-world); first game projects where learning curve matters; projects where budget is a hard constraint at any scale

**Unity**
- Genuine strengths: Industry standard for mid-scope 3D and mobile; massive asset store and tutorial ecosystem; C# is a professional language; best console certification support for indie; strong community for almost every genre
- Real limitations: Licensing controversy in 2023 damaged trust (runtime fee was proposed then walked back — the risk of policy changes remains real); C# has a steeper initial curve than GDScript; heavier editor than Godot for simple projects
- Licensing reality: Free under $200K revenue AND 200K installs (Unity Personal/Plus). Only becomes costly if the game is genuinely successful — most indie games never hit this threshold. The 2023 controversy is worth knowing about but the actual current terms are reasonable for most indie developers.
- Best fit: Mobile games; mid-scope 3D; games targeting console; developers with C# background; projects needing large asset store; teams of 2-5

**Unreal Engine 5**
- Genuine strengths: Best-in-class 3D visuals (Lumen, Nanite, Chaos physics); industry standard for AAA and photorealistic 3D; large open-world support is mature and production-tested; Blueprint visual scripting lowers C++ barrier; strong for games targeting high-end PC or console
- Real limitations: Steepest learning curve; heaviest editor (slow compile times, large project sizes); overkill for stylized/2D/small-scope games; C++ is genuinely hard; not suitable for mobile or web; 5% royalty past $1M gross revenue
- Licensing reality: 5% royalty only applies AFTER $1M gross revenue per title. For a first game or any game that doesn't reach $1M, it costs nothing. This threshold is high enough that most indie developers will never pay it.
- Best fit: AAA-quality 3D; large open-world games; photorealistic visuals; developers with C++ experience or willing to use Blueprint; games targeting high-end PC/console where visual fidelity is a core selling point

**Genre-specific guidance** (factor this into the recommendation):
- 2D any style → Godot strongly preferred
- 3D stylized / atmospheric / contained world → Godot viable, Unity solid alternative
- 3D open world (large, seamless) → Unity or Unreal; Godot is not production-proven for this
- 3D photorealistic / AAA-quality → Unreal
- Mobile-first → Unity strongly preferred
- Console-first → Unity or Unreal; Godot console support requires extra work
- Horror / narrative / walking sim → any engine; match to art style and team experience
- Action RPG / Soulslike → Unity or Unreal for 3D; community support and assets matter here
- Platformer 2D → Godot
- Strategy / top-down / RTS → Godot or Unity depending on 2D vs 3D

**Recommendation format:**
1. Show a comparison table with the user's specific factors as rows
2. Give a primary recommendation with honest reasoning
3. Name the best alternative and when to choose it instead
4. Explicitly state: "This is a starting point, not a verdict — you can always migrate engines, and many developers switch between projects."
5. Use `AskUserQuestion` to confirm: "Does this recommendation feel right, or would you like to explore a different engine?"
   - Options: `[Primary engine] (Recommended)` / `[Alternative engine]` / `[Third engine]` / `Explore further` / `Type something`

**If the user picks "Explore further":**
Use `AskUserQuestion` with concept-specific deep-dive topics. Always generate these options from the user's actual concept — do not use generic options. Always include at minimum:
- The primary engine's specific limitations for this concept (e.g., "How far can Godot 3D actually go for [genre]?")
- The alternative engine's specific tradeoffs for this concept
- Language choice impact on this concept's technical challenges
- Any concept-specific technical concern (e.g., adaptive audio, open-world streaming, multiplayer netcode)

The user can select multiple topics. Answer each selected topic in depth before returning to the engine confirmation question.

---

## 3. Look Up Current Version

Once the engine is chosen:

- If version was provided, use it
- If no version provided, use WebSearch to find the latest stable release:
  - Search: `"[engine] latest stable version [current year]"`
  - Confirm with the user: "The latest stable [engine] is [version]. Use this?"

### Check the chosen version against what is actually installed

A version found by web search is what exists, not what the developer has. Pinning
one they cannot run means every later instruction — build, test, smoke, the
engine reference docs — targets an engine that is not on the machine.

Probe for the binary (Bash), and treat failure as unknown, never as absent:

| Engine | Probe |
|--------|-------|
| Godot | `godot --version`, else look for `godot`/`Godot_v*` on PATH or in the platform's usual install location |
| Unity | `Unity -version`, else the Hub's editor directory |
| Unreal | `UnrealEditor-Cmd -version`, else the launcher's install directory |

Then:
- **Match** — say so in one line and continue.
- **Mismatch** — state both versions and ask, offering three options: pin the
  installed version, pin the newer one and upgrade later, or pin the newer one
  deliberately. Record the answer; do not pick silently.
- **Not found / probe failed** — report `installed version NOT DETERMINED` and
  continue with the chosen version. Do **not** report this as "no engine
  installed": a probe that could not run has not established absence.

Whatever the outcome, write it into Section 7's `VERSION.md` as an
`Installed at pin time` row, so a later reader can tell a deliberate
version-ahead pin from an accident.

---

## 4. Update CLAUDE.md Technology Stack

### Language Selection (Godot only)

If Godot was chosen, ask the user which language to use **before** showing the proposed Technology Stack:

> "Godot supports two primary languages:
>
>   **A) GDScript** — Python-like, Godot-native, fastest iteration. Best for beginners, solo devs, and teams coming from Python or Lua.
>   **B) C#** — .NET 8+, familiar to Unity developers, stronger IDE tooling (Rider / Visual Studio), slight performance advantage on heavy logic.
>   **C) Both** — GDScript for gameplay/UI scripting, C# for performance-critical systems. Advanced setup — requires .NET SDK alongside Godot.
>
> Which will this project primarily use?"

Record the choice. It determines the CLAUDE.md template, naming conventions, specialist routing, and which agent is spawned for code files throughout the project.

---

Read `CLAUDE.md` and show the user the proposed Technology Stack changes.
Ask: "May I write these engine settings to `CLAUDE.md`?"

Wait for confirmation before making any edits.

Update the Technology Stack section, replacing the `[CHOOSE]` placeholders with the actual values:

**For Godot** — use the template matching the language chosen above. See `.claude/skills/setup-engine/references/godot-language-config.md` (**A1**) for all three variants (GDScript, C#, Both).

**For Unity:**
```markdown
- **Engine**: Unity [version]
- **Language**: C#
- **Build System**: Unity Build Pipeline
- **Asset Pipeline**: Unity Asset Import Pipeline + Addressables
```

**For Unreal:**
```markdown
- **Engine**: Unreal Engine [version]
- **Language**: C++ (primary), Blueprint (gameplay prototyping)
- **Build System**: Unreal Build Tool (UBT)
- **Asset Pipeline**: Unreal Content Pipeline
```

### Engine reference import

In the same CLAUDE.md write, set the **Engine Version Reference** import to the
chosen engine. Find the line marked `ENGINE-REFERENCE-IMPORT` (an
`@docs/engine-reference/<engine>/VERSION.md` line under its comment) and Edit it
to point at the configured engine:
- Godot → `@docs/engine-reference/godot/VERSION.md`
- Unity → `@docs/engine-reference/unity/VERSION.md`
- Unreal → `@docs/engine-reference/unreal/VERSION.md`

This is why a fresh Unity or Unreal project no longer loads the Godot reference in
every session. It is idempotent — re-running `/setup-engine` for a different
engine rewrites the same line. (The target `docs/engine-reference/<engine>/`
directory is created in Section 8 below if it does not yet exist.)

---

## 5. Populate Technical Preferences

After updating CLAUDE.md, create or update `.claude/docs/technical-preferences.md` with
engine-appropriate defaults. Read the existing template first, then fill in:

### Engine & Language Section
- Fill from the engine choice made in step 4

### Naming Conventions (engine defaults)

**For Godot** — see `.claude/skills/setup-engine/references/godot-language-config.md` (**A2**) for GDScript, C#, and Both variants.

**For Unity (C#):**
- Classes: PascalCase (e.g., `PlayerController`)
- Public fields/properties: PascalCase (e.g., `MoveSpeed`)
- Private fields: _camelCase (e.g., `_moveSpeed`)
- Methods: PascalCase (e.g., `TakeDamage()`)
- Files: PascalCase matching class (e.g., `PlayerController.cs`)
- Constants: PascalCase or UPPER_SNAKE_CASE

**For Unreal (C++):**
- Classes: Prefixed PascalCase (`A` for Actor, `U` for UObject, `F` for struct)
- Variables: PascalCase (e.g., `MoveSpeed`)
- Functions: PascalCase (e.g., `TakeDamage()`)
- Booleans: `b` prefix (e.g., `bIsAlive`)
- Files: Match class without prefix (e.g., `PlayerController.h`)

### Input & Platform Section

Populate `## Input & Platform` using the answers gathered in Section 2 (or extracted
from the game concept). Derive the values using this mapping:

| Platform target | Gamepad Support | Touch Support |
|-----------------|-----------------|---------------|
| PC only | Partial (recommended) | None |
| Console | Full | None |
| Mobile | None | Full |
| PC + Console | Full | None |
| PC + Mobile | Partial | Full |
| Web | Partial | Partial |

For **Primary Input**, use the dominant input for the game genre:
- Action/RPG/platformer targeting console → Gamepad
- Strategy/point-and-click/RTS → Keyboard/Mouse
- Mobile game → Touch
- Cross-platform → ask the user

> **Genre may not exist yet — check before deriving from it.** At `minimal` the
> design artifact is `design/game-brief.md`, and it is authored *after* this
> skill runs (Section 2 says so explicitly). There is no genre to map. The same
> is true at any tier when `/setup-engine` is run before the concept exists.
>
> When genre is unavailable, **ask** — do not infer one from the platform, and do
> not leave the field silently blank:
> - Prompt: "Primary input for a [2D/3D] [platform] game? Genre isn't established
>   yet — the brief comes next — so this can't be derived."
> - Options: the plausible inputs for that platform, plus
>   `Leave as [TO BE CONFIGURED]` — a legitimate answer here, revisited via
>   `/settings` once the brief exists.
>
> Gamepad Support and Touch Support still come from the platform table above;
> only Primary Input depends on genre.

Present the derived values and ask the user to confirm or adjust before writing.

Example filled section:
```markdown
## Input & Platform
- **Target Platforms**: PC, Console
- **Input Methods**: Keyboard/Mouse, Gamepad
- **Primary Input**: Gamepad
- **Gamepad Support**: Full
- **Touch Support**: None
- **Platform Notes**: All UI must support d-pad navigation. No hover-only interactions.
```

### Remaining Sections
- **Performance Budgets**: Use `AskUserQuestion`:
  - Prompt: "Should I set default performance budgets now, or leave them for later?"
  - Options: `[A] Set defaults now (60fps, 16.6ms frame budget, engine-appropriate draw call limit)` / `[B] Leave as [TO BE CONFIGURED] — I'll set these when I know my target hardware`
  - If [A]: populate with the suggested defaults. If [B]: leave as placeholder.
- **Testing**: Suggest the engine-appropriate framework — **gdUnit4** for Godot,
  NUnit for Unity, Automation Spec for Unreal — and ask before adding.
  > **Must match `commands.test` in Section 5.5.1, which writes
  > `godot --headless --script tests/gdunit4_runner.gd`, and
  > `.claude/docs/coding-standards.md`, which names the same runner.** Naming GUT
  > here would have the skill recommend one framework and configure another in the
  > same run.
- **Forbidden Patterns**: Leave as placeholder — do NOT pre-populate.
- **Allowed Libraries**: Leave as placeholder — do NOT pre-populate dependencies the project does not currently need. Only add a library here when it is actively being integrated, not speculatively.

> **Guardrail**: Never add speculative dependencies to Allowed Libraries. For example, do NOT add GodotSteam unless Steam integration is actively beginning in this session. Post-launch integrations should be added to Allowed Libraries when that work begins, not during engine setup.

### Engine Specialists Routing

Also populate the `## Engine Specialists` section in `technical-preferences.md` with the correct routing for the chosen engine:

**For Godot** — see `.claude/skills/setup-engine/references/godot-language-config.md` (**A3**) for the routing table matching the language chosen.

**For Unity:**
```markdown
## Engine Specialists
- **Primary**: unity-specialist
- **Language/Code Specialist**: unity-specialist (C# review — primary covers it)
- **Shader Specialist**: unity-shader-specialist (Shader Graph, HLSL, URP/HDRP materials)
- **UI Specialist**: unity-ui-specialist (UI Toolkit UXML/USS, UGUI Canvas, runtime UI)
- **Additional Specialists**: unity-dots-specialist (ECS, Jobs system, Burst compiler), unity-addressables-specialist (asset loading, memory management, content catalogs)
- **Routing Notes**: Invoke primary for architecture and general C# code review. Invoke DOTS specialist for any ECS/Jobs/Burst code. Invoke shader specialist for rendering and visual effects. Invoke UI specialist for all interface implementation. Invoke Addressables specialist for asset management systems.

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.cs files) | unity-specialist |
| Shader / material files (.shader, .shadergraph, .mat) | unity-shader-specialist |
| UI / screen files (.uxml, .uss, Canvas prefabs) | unity-ui-specialist |
| Scene / prefab / level files (.unity, .prefab) | unity-specialist |
| Native extension / plugin files (.dll, native plugins) | unity-specialist |
| General architecture review | unity-specialist |
```

**For Unreal:**
```markdown
## Engine Specialists
- **Primary**: unreal-specialist
- **Language/Code Specialist**: ue-blueprint-specialist (Blueprint graphs) or unreal-specialist (C++)
- **Shader Specialist**: unreal-specialist (no dedicated shader specialist — primary covers materials)
- **UI Specialist**: ue-umg-specialist (UMG widgets, CommonUI, input routing, widget styling)
- **Additional Specialists**: ue-gas-specialist (Gameplay Ability System, attributes, gameplay effects), ue-replication-specialist (property replication, RPCs, client prediction, netcode)
- **Routing Notes**: Invoke primary for C++ architecture and broad engine decisions. Invoke Blueprint specialist for Blueprint graph architecture and BP/C++ boundary design. Invoke GAS specialist for all ability and attribute code. Invoke replication specialist for any multiplayer or networked systems. Invoke UMG specialist for all UI implementation.

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.cpp, .h files) | unreal-specialist |
| Shader / material files (.usf, .ush, Material assets) | unreal-specialist |
| UI / screen files (.umg, UMG Widget Blueprints) | ue-umg-specialist |
| Scene / prefab / level files (.umap, .uasset) | unreal-specialist |
| Native extension / plugin files (Plugin .uplugin, modules) | unreal-specialist |
| Blueprint graphs (.uasset BP classes) | ue-blueprint-specialist |
| General architecture review | unreal-specialist |
```

### Collaborative Step
Present the filled-in preferences to the user. For Godot, include the chosen language and note where the full naming conventions and routing tables live:
> "Here are the default technical preferences for [engine] ([language if Godot]). The naming conventions and specialist routing are in this skill's references directory — I'll apply the [GDScript/C#/Both] variant. Want to customize any of these, or shall I save the defaults?"

For all other engines, present the defaults directly without referencing the appendix.

Wait for approval before writing the file.

---

## 5.5 Populate `project.yaml` (Primary Config Store)

> **v1.1:** `project.yaml` at the repo root is the **primary** store for project
> configuration. The `.claude/docs/technical-preferences.md` file written in
> Section 5 is kept as a **legacy mirror** for backward compatibility. This step
> is a **dual-write** — the same engine facts go into both files, and
> `project.yaml` wins when a skill reads a key present in both.

After `technical-preferences.md` is written and approved, dual-write the
structured config into `project.yaml`. Four blocks are written: `engine`,
`specialists`, `naming`, and `commands`.

### 5.5.1 Build the four blocks

Derive every value from the engine and language already chosen in Sections 3–4.
Do NOT re-ask for the **engine, version or language** — reuse those decisions.

> **That is not a blanket "never ask".** `rendering` and `physics` below depend on
> two further inputs — target platform and 2D-vs-3D — which **Section 2 collects on
> only one of the four entry paths**. When they were never collected, ask; the
> unavailable-branch under the project-shape table says how.

**`engine` block:**

```yaml
engine:
  name: "<Godot|Unity|Unreal>"
  version: "<version from Section 3>"
  language: "<GDScript|C#|C++|Blueprint>"
  rendering: "<engine default — see table>"
  physics: "<engine default — see table>"
```

**On Godot these two values depend on the answers Section 2 already collected —
the target platform and 2D-vs-3D — so do not pick them from the engine name
alone.** On Unity and Unreal the table has a single `any` row and the engine name
*is* sufficient; take those rows directly.

| Engine | Project shape | `rendering` default | `physics` default |
|--------|---------------|---------------------|-------------------|
| Godot 4.x | 2D · web target | Compatibility | Godot Physics 2D |
| Godot 4.x | 2D · non-web | Forward+ | Godot Physics 2D |
| Godot 4.x | 3D · web target | Compatibility | Jolt |
| Godot 4.x | 3D · non-web | Forward+ | Jolt |
| Unity | any | URP | PhysX |
| Unreal | any | Lumen + Nanite (deferred) | Chaos |

> **Why this table has a shape column and the others do not.** Both Godot
> defaults were wrong for a 2D browser game, and both were wrong from data this
> skill had already collected and then discarded.
> - **Jolt is Godot's default *3D* engine.** `docs/engine-reference/godot/modules/physics.md`:
>   "Jolt Physics is the DEFAULT 3D engine" and "2D physics UNCHANGED (still
>   Godot Physics 2D)". Writing `Jolt` on a 2D project sends the implementer to
>   tune a backend their game does not use.
> - **Forward+ is desktop-focused.** `docs/engine-reference/godot/modules/rendering.md`:
>   Forward+ is "Full featured, desktop-focused"; Compatibility is
>   "OpenGL 3.3 / WebGL 2, broadest hardware support" — the browser path.
>
> If Section 2's platform answer was `Multiple platforms` **including** web, use
> the web row: the renderer must work everywhere the game ships.

> **Godot only — Unity and Unreal have one row each, keyed `any`.** Shape cannot
> change `rendering` or `physics` for those two, so do **not** run the resolution
> below for them: asking an operator a question whose answer you will discard is
> exactly what §5.5.1 opens by forbidding. On Unity write `URP`/`PhysX` and on
> Unreal write `Lumen + Nanite (deferred)`/`Chaos` straight from the table.
>
> **Section 2 did not necessarily run — check before reading its answers.**
> Target platform and 2D-vs-3D are collected under *Questions 2–6, only if no
> prior engine experience*. **Three of the four entry paths never reach them:**
> `/setup-engine <engine> <version>` and `/setup-engine <engine>` skip Section 2
> outright, and guided mode skips the matrix as soon as the user names an engine
> they have worked in before. Only guided mode answered `None` or `Multiple`
> collects both.
>
> Resolve each input in this order and stop at the first that answers:
> 1. **Section 2's answers**, if that path ran.
> 2. **The design artifact** — `design/gdd/game-concept.md` at `standard`/`full`,
>    `design/game-brief.md` at `minimal`. Section 2 already extracts platform
>    targets from these; extract 2D-vs-3D the same way when it is stated.
> 3. **Ask.** Do not infer the shape from the engine name, and do not write a row
>    you could not justify:
>    - Prompt: "`rendering` and `physics` depend on the project's shape, which
>      hasn't been established yet. Is this 2D or 3D, and does it ship to web?"
>    - Options: `2D · non-web` / `2D · web` / `3D · non-web` / `3D · web`, plus
>      `Leave as [TO BE CONFIGURED]` — a legitimate answer here, revisited via
>      `/settings` once the concept exists.
>
> `[TO BE CONFIGURED]` is a valid value for both keys. A wrong `Jolt` on a 2D
> project is worse than an unset one, because nothing downstream questions it.

- `rendering` and `physics` are engine-typical defaults — tell the user they can
  be changed later via `/settings` if the project uses a different setup.
- For Godot **Both**, write `language: "GDScript"` (the primary gameplay
  language); the C# usage is recorded in `technical-preferences.md`.
- For Unreal, write `language: "C++"` — or `"Blueprint"` only if the project is
  Blueprint-primary. Blueprint as a secondary tool does not change this value.

**`specialists` block** — copy directly from the routing table chosen in
Section 5 (**A3** in `.claude/skills/setup-engine/references/godot-language-config.md` for Godot):

| Engine / language | `code` | `shader` | `ui` | `additional` |
|-------------------|--------|----------|------|--------------|
| Godot — GDScript | godot-gdscript-specialist | godot-shader-specialist | godot-specialist | [godot-gdextension-specialist] |
| Godot — C# | godot-csharp-specialist | godot-shader-specialist | godot-specialist | [godot-gdextension-specialist] |
| Godot — Both | godot-gdscript-specialist | godot-shader-specialist | godot-specialist | [godot-csharp-specialist, godot-gdextension-specialist] |
| Unity | unity-specialist | unity-shader-specialist | unity-ui-specialist | [unity-dots-specialist, unity-addressables-specialist] |
| Unreal | unreal-specialist | unreal-specialist | ue-umg-specialist | [ue-gas-specialist, ue-blueprint-specialist, ue-replication-specialist] |

```yaml
specialists:
  code: "<code specialist>"
  shader: "<shader specialist>"
  ui: "<ui specialist>"
  additional: ["<...>"]
```

**`naming` block** — enum values (NOT the prose form used in
`technical-preferences.md`). Use the column matching the engine and, for Godot,
the language:

| Field | Godot GDScript | Godot C# | Unity | Unreal |
|-------|----------------|----------|-------|--------|
| `classes` | PascalCase | PascalCase | PascalCase | PascalCase |
| `variables` | snake_case | camelCase | camelCase | **PascalCase** |
| `constants` | SCREAMING_SNAKE | PascalCase | SCREAMING_SNAKE | SCREAMING_SNAKE |
| `signals` | past_tense | on_event_name | **PascalCase `On<Event>`** | **PascalCase `On<Event>`** |
| `files` | snake_case | PascalCase | PascalCase | PascalCase |
| `scenes` | snake_case | PascalCase | PascalCase | PascalCase |

> **The Unreal column is sourced, not inherited from the table's generic shape.**
> `variables: camelCase` and `signals: on_event_name` are the two rows that shape
> would produce, and both are wrong for Unreal. Checked against this repo's
> pinned reference: `docs/engine-reference/unreal/` contains **zero** camelCase
> variable declarations and uses PascalCase throughout (`int32 Health;`,
> `FVector ServerPosition;`), and the word "signal" **never appears in it at all** —
> it is Godot vocabulary. Unreal has delegates and events, and the reference's
> handlers are PascalCase `On<Event>`.
>
> Two caveats kept rather than smoothed over. (1) `classes: PascalCase` is
> **incomplete** for Unreal, not wrong: UE requires a mandatory type prefix
> (`U`/`A`/`F`/`E`/`I`/`T`) that this enum cannot express, so an Unreal project's
> coding standards must state it separately. (2) `scenes` is a **category
> mismatch** — Unreal has Levels and Maps under World Partition, not scenes — left
> in place because the key is shared across engines and renaming it is a schema
> change, not a value fix.
>
> The blast radius is limited: `naming.*` is currently a
> **documented-but-unread** setting, so wrong values misinform a human reading
> `project.yaml` rather than driving any automated check — today. That is a
> reason to get them right now, while it is cheap.

> **Three further rules for this table.**
>
> **The Unity `build` row must not hardcode `-buildTarget StandaloneLinux64`.**
> A hardcoded target gives every Unity project a **Linux** build command, whatever
> platform it actually ships on. The row reads `<TARGET>`: **ask the operator for
> the build target and write the value they give.** The correct `-buildTarget` identifiers
> are not sourceable from `docs/engine-reference/unity/`, so this skill must not
> emit one from recall — the same call made for `/security-audit`'s save
> patterns and for Unity's release dates. A wrong-but-plausible default is worse
> than an explicit question: it produces a `commands.build` that runs, succeeds,
> and builds the wrong artifact.
>
> **The Godot `build` row must not hardcode `'Linux/X11'` either — same defect,
> same remedy.** A Godot export preset name is **project-defined**: it is whatever
> string the operator typed into `export_presets.cfg`, and the shipped defaults are
> per-platform (`Windows Desktop`, `macOS`, `Web`, `Linux/X11`). Writing
> `'Linux/X11'` gives a Windows-targeting project a build command that fails with
> `Unknown export preset`, and gives a project that *does* have a Linux preset a
> command that silently builds the wrong platform. The row reads `<PRESET>`:
> **ask the operator which export preset to build and write the value they give**,
> exactly as the Unity row does. If no presets exist yet — common, since
> `/setup-engine` usually runs before the Godot project has any — write
> `[TO BE CONFIGURED]` and say so, rather than guessing a name that does not exist.
>
> **The `constants` row must not contradict this skill's own prose.** The table says
> `SCREAMING_SNAKE` for Unity; the Unity section of this same file says
> "Constants: PascalCase or UPPER_SNAKE_CASE". Both cannot be authoritative, and
> an agent following one produces config the other rejects. The row is **left
> unchanged pending sourcing** rather than picked by preference — neither
> `docs/engine-reference/unity/` nor `unreal/` contains a SCREAMING_SNAKE constant
> to confirm or refute it, and the Unreal run flagged the same row as wrong for
> Unreal on the same grounds. Resolve by adding a naming section to the engine
> references, then correct table and prose together. Until then, treat
> `naming.constants` as unverified for Unity and Unreal.
>
> **Write that caveat into `project.yaml`, do not leave it here.** On Unity and
> Unreal, emit the `constants` line with a trailing comment:
> ```yaml
> naming:
>   constants: SCREAMING_SNAKE   # UNVERIFIED — not sourceable from
>                                # docs/engine-reference/<engine>/; confirm before relying on it
> ```
> Without it, a value the skill *knows* is unsourced is recorded as flatly as
> `classes: PascalCase`, which is sourced, and the reader of the primary config
> store cannot tell them apart. The `commands` block nine lines below already does
> exactly this with its `# TODO: confirm these` line — this is the same pattern,
> applied to the value that needs it just as much.

For Godot **Both**, use the GDScript column — `.gd` files dominate gameplay
scripting; `.cs` files follow C# conventions per-file (see **A2** in `.claude/skills/setup-engine/references/godot-language-config.md`).

```yaml
naming:
  classes: <value>
  variables: <value>
  constants: <value>
  signals: <value>
  files: <value>
  scenes: <value>
```

**`commands` block** — engine-default shell commands, simple-string form:

| Engine | `build` | `test` | `run` | `smoke` |
|--------|---------|--------|-------|---------|
| Godot | `godot --headless --export-debug '<PRESET>'` **(ASK — do not default)** | `godot --headless --script tests/gdunit4_runner.gd` | `godot --path . --windowed --resolution 1280x720` | `godot --headless --quit-after 5` |
| Unity | `Unity -batchmode -quit -projectPath . -buildTarget <TARGET>` **(ASK — do not default)** | `Unity -runTests -projectPath . -testPlatform PlayMode` | `Builds/<Target>/<Game>.exe -screen-width 1280 -screen-height 720 -screen-fullscreen 0` | `Unity -batchmode -quit -projectPath . -executeMethod SmokeCheck.Run` |

> **`commands.run` is the one the run-and-observe step depends on.** It must
> launch the **game**, windowed, at a fixed resolution — never the editor, and
> never with a headless / batch / null-RHI flag, which exist to skip rendering.
> `/dev-story` Phase 6 step 4 appends the per-engine capture flags to it
> (`.claude/docs/run-and-observe.md`). `test` and `smoke` feed the parse check
> and `/smoke-check`; `build` is the one row you must ask for.

> **YAML quoting rule — applies to EVERY command value.** `yaml-helper.sh` — the
> parser every config read in this framework goes through — decodes **no**
> escape sequences: neither `\"` inside a double-quoted scalar nor `''` inside a
> single-quoted scalar. It takes the first matching quote character as the end of
> the value and discards the rest, so `"he said \"hi\" now"` parses as
> `he said \`. Verified against the parser, not inferred. The rule is
> preventative here — it applies the moment anything does read `commands.*`, and
> to every other quoted value in `project.yaml` today.
> Pick the quote style that needs **no escaping**:
> - value contains a single quote `'` (e.g. the Godot `build` above) → wrap it in
>   a **double-quoted** YAML scalar: `"... 'Linux/X11' ..."`
> - value contains a double quote `"` (e.g. the Unreal `test`/`smoke` below) →
>   wrap it in a **single-quoted** YAML scalar: `'... "Quit" ...'`
> - value contains neither → use a double-quoted scalar for consistency.
> Never use a quote style that forces an escape (`\"` or `''`) — the parser
> truncates the value at the escape. A value containing BOTH quote types cannot
> be represented for this parser; rewrite the command to drop one.

**Godot / Unity** — write the table values directly, substituting the operator's
answer for `<PRESET>` / `<TARGET>`. Godot's `build` contains a single quote, so it
takes a double-quoted scalar (`Windows Desktop` below is the *example* answer, not
a default — write what the operator said):

```yaml
commands:
  build: "godot --headless --export-debug 'Windows Desktop'"
  test: "godot --headless --script tests/gdunit4_runner.gd"
  run: "godot --path . --windowed --resolution 1280x720"
  smoke: "godot --headless --quit-after 5"
```

> **Also write `engine.path` if the editor is not on `PATH`.** These commands name
> the executable bare, which assumes it resolves — and on Windows none of the three
> engines installs onto `PATH` by default. Ask for or probe the install location and
> record it:
>
> ```yaml
> engine:
>   path: "C:/Program Files/Epic Games/UE_5.7"   # omit if the editor is on PATH
> ```
>
> **This is not cosmetic.** Without it, an agent reports *"no editor on this
> machine"* and ships C++ it never compiled — on a machine where that engine WAS
> installed. Nothing in the project told it where to look, so absence of a path read
> as absence of an engine.

For **Unreal**, UE build/test commands vary by version and project setup. Write
best-effort values and add a `# TODO` comment so the user knows to confirm them.
The `test`/`smoke` commands embed double quotes, so they take single-quoted
scalars:

```yaml
commands:
  # TODO: confirm these for your UE version and project — adjust via /settings
  build: 'RunUAT.bat BuildCookRun -project=<project>.uproject -platform=Win64 -build -cook'
  test: 'UnrealEditor-Cmd.exe <project>.uproject -ExecCmds="Automation RunTests <project>; Quit" -unattended -nullrhi'
  run: 'UnrealEditor.exe <project>.uproject -game -windowed -ResX=1280 -ResY=720'
  smoke: 'UnrealEditor-Cmd.exe <project>.uproject -game -nullrhi -unattended -ExecCmds="Quit"'
```

**Two details are load-bearing.** `smoke` needs `-game`: without it
`UnrealEditor-Cmd` boots the *editor*, where a bare `Quit` console command only
ends a play-in-editor session — the process stays resident and the command
never returns; with `-game` the same line boots headless and exits in seconds.
`test` needs the `; Quit` inside the `Automation` string: the automation
runner handles that trailing `Quit` itself and exits the editor once the tests
finish, and without it the run also never returns.

### 5.5.2 Write the blocks to `project.yaml`

Show the user the full set of four blocks and ask:

> "May I write the `engine`, `specialists`, `naming`, and `commands` blocks to `project.yaml`?"

Wait for confirmation, then apply based on the file's current state:

- **`project.yaml` does not exist** — create it with the Write tool using this
  v1.1 template (the four blocks appended after `framework`; replace `<...>` and
  the date):

  ```yaml
  # CCGS project configuration — single source of truth for project settings.
  # Schema: grep the `## <key>` section of .claude/docs/effects-map.md —
  # it is ~31k tokens whole, ~900 per section. Do not open it entire.

  schema_version: 1

  framework:
    version: 1.1.1
    last_upgraded: <today's date>

  engine:
    name: "<...>"
    version: "<...>"
    language: "<...>"
    rendering: "<...>"
    physics: "<...>"

  specialists:
    code: "<...>"
    shader: "<...>"
    ui: "<...>"
    additional: ["<...>"]

  naming:
    classes: <...>
    variables: <...>
    constants: <...>
    signals: <...>
    files: <...>
    scenes: <...>

  commands:
    build: "<...>"
    test: "<...>"
    run: "<...>"
    smoke: "<...>"
  ```

  Do not seed `modes.review_mode` here. It is a rigor-fronted knob — `modes.rigor`
  supplies its value, so an explicit value would shadow the rigor expansion and pin
  the review mode regardless of the project's rigor. Test Y.6 locks this in.

- **`project.yaml` exists** — Read it first (the Edit tool requires the file to
  have been read this session), then, processing the blocks in the order
  `engine` → `specialists` → `naming` → `commands`, for each block:
  - **Block absent** — insert the whole block, appended after the last existing
    top-level block.
  - **Block already present** (a re-run of `/setup-engine`) — Edit the existing
    keys in place, and add any keys the block is missing (a partial block must
    end up with its full key set). Do NOT add a second copy of the block.

Preserve all other content in `project.yaml` (`schema_version`, `framework`,
`modes`, `project`, etc.) — only the four blocks are touched.

### 5.5.3 Verify the dual-write

Read `project.yaml` back and confirm the four blocks are present and that
`engine.name`, `engine.language`, and the naming values match what was written
to `technical-preferences.md`. If they diverge, report the discrepancy to the
user and stop — a split config corrupts skill and hook reads.

---

## 6. Determine Knowledge Gap

Check whether the engine version is likely beyond the LLM's training data.

**Known approximate coverage** — *last re-checked 2026-08-28*:
- LLM knowledge cutoff: **May 2026**
- Godot: training data likely covers up to ~4.6
- Unity: training data likely covers up to ~6000.x
- Unreal: training data likely covers up to ~5.5

> **This table goes stale silently, and a stale table fails in the dangerous
> direction only if it is too *new*.** A cutoff left unchanged for a year after
> it stopped being true over-classifies risk — safe, but every project then pays
> for full reference docs it may not have needed.
> The opposite error is the harmful one: a cutoff claimed *later* than the model's
> actual one marks post-cutoff versions LOW RISK and suppresses the reference
> docs that exist to stop invented APIs.
>
> **If the date above is more than six months old, do not trust it.** Say so, and
> treat the engine version as `HIGH RISK` regardless of the comparison — an
> unverifiable cutoff is not a cutoff that was met.

Compare the user's chosen version against these baselines:

- **Within training data** → `LOW RISK` — reference docs optional but recommended
- **Near the edge** → `MEDIUM RISK` — reference docs recommended
- **Beyond training data** → `HIGH RISK` — reference docs required

Inform the user which category they're in and why.

---

## 7. Populate Engine Reference Docs

### First: does a reference set already exist for this engine?

**Check before doing anything else.** The template ships
`docs/engine-reference/godot/`, `unity/` and `unreal/` **already populated**, so
"the directory exists and pins a version" is the state of *every* fresh project,
not an edge case. Both branches below say "create", and following either one
literally on a pre-populated directory either overwrites curated content or
leaves `project.yaml` and the CLAUDE.md-imported reference disagreeing.

Read `docs/engine-reference/<engine>/VERSION.md` and compare its
**Engine Version** to the version chosen in Section 3:

- **No directory, or no `VERSION.md`** → create, using the risk branch below.
- **Same version** → nothing to do. Refresh `Last Docs Verified` only if you
  actually re-verified against the docs this run. Do not restamp a date you did
  not check.
- **Directory pins an OLDER version than the one chosen** → **update, do not
  replace.** This is the common case.
  1. Edit `VERSION.md` in place: new **Engine Version**, new **Project Pinned**
     and **Last Docs Verified**, the `Installed at pin time` row from Section 3,
     and a new row in the post-cutoff timeline for each version added.
  2. **Append** to `breaking-changes.md`, `deprecated-apis.md` and
     `current-best-practices.md` under a heading naming the version span
     (`## 4.6 → 4.7`). Never truncate the older spans — a project migrating
     across two versions still needs the earlier one.
  3. Re-grade the older timeline rows if the cutoff moved past them.
- **Directory pins a NEWER version than the one chosen** → stop and ask. Someone
  pinned forward deliberately, or the version choice is wrong. Do not silently
  downgrade a curated reference.

### Sourcing rule for everything written in this section

**Never fill a gap from training data. Write the gap down instead.**

The whole purpose of these files is to be the thing agents consult *instead of*
their training data. A confidently wrong entry here is worse than no entry: it
produces work that looks verified and is not.

- Every claim must come from a page you fetched this run. Record the URL.
- If the official docs do not state something the template asks for — a release
  date, a subsystem's behaviour, web-export specifics — write
  **`NOT SOURCEABLE — <what>, not stated at <url>`** and move on.
- A `NOT SOURCEABLE` line is a successful outcome, not a failure to finish.
- Do not infer one fact from an adjacent one. "The migration guide lists no
  physics change" is not "the physics default is unchanged"; if you record the
  inference, label it as an inference and name what it rests on.

### If WITHIN training data (LOW RISK):

Create a minimal `docs/engine-reference/<engine>/VERSION.md`:

```markdown
# [Engine] — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | [version] |
| **Project Pinned** | [today's date] |
| **LLM Knowledge Cutoff** | May 2025 |
| **Risk Level** | LOW — version is within LLM training data |

## Note

This engine version is within the LLM's training data. Engine reference
docs are optional but can be added later if agents suggest incorrect APIs.

Run `/setup-engine refresh` to populate full reference docs at any time.
```

Do NOT create breaking-changes.md, deprecated-apis.md, etc. — they would
add context cost with minimal value.

### If BEYOND training data (MEDIUM or HIGH RISK):

Create the full reference doc set by searching the web:

1. **Search for the official migration/upgrade guide**:
   - `"[engine] [old version] to [new version] migration guide"`
   - `"[engine] [version] breaking changes"`
   - `"[engine] [version] changelog"`
   - `"[engine] [version] deprecated API"`

2. **Fetch and extract** from official documentation:
   - Breaking changes between each version from the training cutoff to current
   - Deprecated APIs with replacements
   - New features and best practices

Ask: "May I create the engine reference docs under `docs/engine-reference/<engine>/`?"

Wait for confirmation before writing any files.

3. **Create the full reference directory**:
   ```
   docs/engine-reference/<engine>/
   ├── VERSION.md              # Version pin + knowledge gap analysis
   ├── breaking-changes.md     # Version-by-version breaking changes
   ├── deprecated-apis.md      # "Don't use X → Use Y" tables
   ├── current-best-practices.md  # New practices since training cutoff
   └── modules/                # Per-subsystem references (create as needed)
   ```

4. **Populate each file** using real data from the web searches, following
   the format established in existing reference docs. Every file must have
   a "Last verified: [date]" header.

5. **For module files**: Only create modules for subsystems where significant
   changes occurred. Don't create empty or minimal module files.

---

## 7.5 Scaffold the Engine Project

**Without this step the framework produces source files no engine can open.**
`/dev-story` writes `.gd`/`.cs`/`.cpp` under the resolved code root, and the `minimal` path
advertises "four steps to running code" — but nothing anywhere created a project
for the engine to load. Verified by grep across every skill: no `project.godot`,
no Unity project, no `.uproject` was ever written. The files were real and
orphaned.

### Godot — write `project.godot` if one is absent

**Never overwrite an existing `project.godot`.** If the file is already there,
say so and skip to Section 8 — the developer has a project and its settings are
theirs.

Show the proposed file, then ask: *"May I create `project.godot` at the repo
root?"* On approval, write:

```ini
config_version=5

[application]

config/name="<project name>"
config/features=PackedStringArray("<major.minor>", "<renderer feature>")

[rendering]

renderer/rendering_method="<rendering method>"
```

Fill it from decisions already made — do not ask again:

| Field | Source |
|-------|--------|
| `config/name` | the brief's working title, else the repo directory name |
| `<major.minor>` | `engine.version` from Section 3, major and minor only (`4.7.2` → `4.7`) |
| `<renderer feature>` / `<rendering method>` | the `rendering` value chosen in Section 5.5.1 — Compatibility → `"GL Compatibility"` / `gl_compatibility`; Forward+ → `"Forward Plus"` / `forward_plus`; Mobile → `"Mobile"` / `mobile` |

**Leave `run/main_scene` unset.** There is no scene yet at engine-setup time.
Add a comment saying `/dev-story` or the developer sets it once a scene exists;
an empty project with no main scene opens fine in the editor.

**Then verify, and report what the verification actually was.** If the engine
binary was found in Section 3, run its headless import
(`godot --headless --path . --import`) and report the result. If the binary was
not found, or its version differs from the pinned one, write
**`project.godot NOT VERIFIED — <reason>`**. The `config_version` and feature
strings are stable across Godot 4.x, but "stable in the versions I know" is not
the same as "checked against the version you pinned", and only the run
establishes the latter.

### Unity and Unreal — instruct, do not fabricate

A Unity project and an `.uproject` are editor-generated and span many files,
several of them binary or machine-specific. This repo cannot source their
correct contents, and a hand-written scaffold would be the exact failure
Section 7's sourcing rule forbids — something that looks finished and is quietly
wrong.

Tell the user, in one short block, that CCGS does not create the project for
these engines and they should create it first:

- **Unity** — create the project in Unity Hub at the repo root, choosing the
  template matching the 2D/3D answer from Section 2, then re-run `/setup-engine`.
- **Unreal** — create the project in the Epic launcher or via `UnrealEditor`,
  then re-run.

Report the outcome in the Section 12 summary either way — created, already
present, or "not created, engine requires the editor" — so the user leaves this
skill knowing whether a runnable project exists.

> **Deliberately not a `project.yaml` key.** An `engine.project_scaffolded` flag
> would be written here and read by nothing, which is a dead setting — the same
> writer-without-reader defect the config gates exist to catch. The filesystem is
> the source of truth: any skill that needs to know globs for `project.godot`,
> `*.uproject`, or `ProjectSettings/ProjectVersion.txt`.

---

## 8. Verify the CLAUDE.md Import

**This import was already written in Section 4 — do not edit it again and do not
ask again.** Section 4 sets it as part of the same CLAUDE.md write, anchored to
the `ENGINE-REFERENCE-IMPORT` marker. This step only confirms the result.

Read `CLAUDE.md` and confirm the line under the marker reads:

```markdown
@docs/engine-reference/<engine>/VERSION.md
```

with `<engine>` the engine just configured. If it still points at a different
engine, Section 4 did not complete — go back and finish it rather than patching
the line here.

> **Why this is a check and not a second write.** Repeating the edit here with
> its own approval prompt would ask the user twice for one change, and the second
> ask would be for work already done. Locate the line by its marker, never by the
> `## Engine Version Reference` heading — the marker exists precisely so the line
> can still be found when the heading moves or is reworded.

---

## 8.5 Read Back What You Just Wrote

This section exists because prose did not hold. Section 5.5.1's rendering/physics
table already carries an emphatic, source-cited warning naming the two mistakes
most often made here -- and it is still entirely possible to make **both** of
them anyway, writing `Forward+` and `Jolt` for a 2D browser game. Section 3's
`Installed at pin time` row is just as easy to drop silently, because a missing
row leaves no trace.

Neither is fixed by adding more instructions. They are fixed by verifying the
files after writing them:

```bash
bash .claude/scripts/project-coherence.sh
```

It compares `project.yaml` against `docs/engine-reference/<engine>/VERSION.md`,
against `project.godot`, and against the engine binary actually on PATH, and it
checks that the files `commands.build` and `commands.test` name exist.

**Report every `[DIFFERS]` line to the user and resolve it before finishing.**
Each one means two files this skill just wrote disagree, or describe something
that is not there.

**`[NOT CHECKED]` is not a pass.** Each such line names why a comparison could
not be made -- an absent binary, a missing `project.godot`. Say which ones
applied. A comparison that could not run has not established agreement.

The script emits observations and never a verdict, per the convention in
CLAUDE.md. The judgement is yours and the user's.

---

## 9. Update Agent Instructions

Ask: "May I add a Version Awareness section to the engine specialist agent files?" before making any edits.

For the chosen engine's specialist agents, verify they have a
"Version Awareness" section. If not, add one following the pattern in
the existing Godot specialist agents.

The section should instruct the agent to:
1. Read `docs/engine-reference/<engine>/VERSION.md`
2. Check deprecated APIs before suggesting code
3. Check breaking changes for relevant version transitions
4. Use WebSearch to verify uncertain APIs

---

## 10. Refresh Subcommand

If invoked as `/setup-engine refresh`:

1. Read the existing `docs/engine-reference/<engine>/VERSION.md` to get
   the current engine and version
2. Use WebSearch to check for:
   - New engine releases since last verification
   - Updated migration guides
   - Newly deprecated APIs
3. Update all reference docs with new findings
4. Update "Last verified" dates on all modified files
5. Report what changed

---

## 11. Upgrade Subcommand

If invoked as `/setup-engine upgrade [old-version] [new-version]`:

### Step 1 — Read Current Version State

Read `docs/engine-reference/<engine>/VERSION.md` to confirm the current pinned
version, risk level, and any migration note URLs already recorded. If
`old-version` was not provided as an argument, use the pinned version from this
file.

### Step 2 — Fetch Migration Guide

Use WebSearch and WebFetch to locate the official migration guide between
`old-version` and `new-version`:

- Search: `"[engine] [old-version] to [new-version] migration guide"`
- Search: `"[engine] [new-version] breaking changes changelog"`
- Fetch the migration guide URL from VERSION.md if one is already recorded,
  or use the URL found via search.

Extract: renamed APIs, removed APIs, changed defaults, behavior changes, and
any "must migrate" items.

### Step 3 — Pre-Upgrade Audit

Scan the **code root** (resolve per `.claude/docs/code-root-resolution.md`) for code that uses APIs known to be deprecated or changed in the
target version:

- Use Grep to search for deprecated API names extracted from the migration
  guide (e.g., old function names, removed node types, changed property names)
- List each file that matches, with the specific API reference found

Present the audit results as a table:

```
Pre-Upgrade Audit: [engine] [old-version] → [new-version]
==========================================================

Files requiring changes:
  File                              | Deprecated API Found       | Effort
  --------------------------------- | -------------------------- | ------
  src/gameplay/player_movement.gd   | old_api_name               | Low
  src/ui/hud.gd                     | removed_node_type          | Medium

Breaking changes to watch for:
  - [change description from migration guide]
  - [change description from migration guide]

Recommended migration order (dependency-sorted):
  1. [system/layer with fewest dependencies first]
  2. [next system]
  ...
```

If no deprecated APIs are found in the code root, report: "No deprecated API usage
found in the code root — upgrade may be low-risk."

### Step 4 — Confirm Before Updating

Ask the user before making any changes:

> "Pre-upgrade audit complete. Found [N] files using deprecated APIs.
> Proceed with upgrading VERSION.md to [new-version]?
> (This will update the pinned version and add migration notes — it does NOT
> change any source files. Source migration is done manually or via stories.)"

Wait for explicit confirmation before continuing.

### Step 5 — Update VERSION.md

After confirmation:

1. Update `docs/engine-reference/<engine>/VERSION.md`:
   - `Engine Version` → `[new-version]`
   - `Project Pinned` → today's date
   - `Last Docs Verified` → today's date
   - Re-evaluate and update the `Risk Level` and `Post-Cutoff Version Timeline`
     table if the new version falls beyond the LLM knowledge cutoff
   - Add a `## Migration Notes — [old-version] → [new-version]` section
     containing: migration guide URL, key breaking changes, deprecated APIs
     found in this project, and recommended migration order from the audit

2. If `breaking-changes.md` or `deprecated-apis.md` exist in the engine
   reference directory, append the new version's changes to those files.

3. If `project.yaml` exists at the repo root and has an `engine` block, Read it
   first, then update `engine.version` to `[new-version]` so the primary config
   store stays in sync with VERSION.md.

### Step 6 — Post-Upgrade Reminder

After updating VERSION.md, output:

```
VERSION.md updated: [engine] [old-version] → [new-version]

Next steps:
1. Migrate deprecated API usages in the [N] files listed above
2. Run /setup-engine refresh after upgrading the actual engine binary to
   verify no new deprecations were missed
3. Run /architecture-review — the engine upgrade may invalidate ADRs that
   reference specific APIs or engine capabilities
4. If any ADRs are invalidated, run /propagate-design-change to update
   downstream stories
```

---

## 12. Output Summary

After setup is complete, output:

```
Engine Setup Complete
=====================
Engine:          [name] [version]
Language:        [GDScript | C# | GDScript + C# | C# | C++ + Blueprint]
Knowledge Risk:  [LOW/MEDIUM/HIGH]
Reference Docs:  [created/skipped]
CLAUDE.md:       [updated]
Tech Prefs:      [created/updated]
project.yaml:    [created/updated]
Agent Config:    [verified]

Next Steps:
1. Review docs/engine-reference/<engine>/VERSION.md
```

Then print **one** Next-Steps list, matching the resolved `workflow` tier:

**`minimal` — the lean 4-step floor (you are on step 1):**
```
2. Run /brainstorm to produce your one-page design/game-brief.md (the lean-tier design artifact)
3. Run /create-stories to turn the brief's MVP list into stories
4. Run /dev-story — first line of game code
```
(No `/map-systems`, `/design-system`, `/prototype`, or `/sprint-plan` at
`minimal` — the brief replaces the GDDs and its build order is the plan.)

**`standard` / `full` — the full pipeline:**
```
2. [If from /brainstorm] Run /map-systems to decompose your concept into individual systems
3. [If from /brainstorm] Run /design-system to author per-system GDDs (guided, section-by-section)
4. [If from /brainstorm] Run /prototype [core-mechanic] to validate the core idea before writing GDDs
5. [If fresh start] Run /brainstorm to discover your game concept
6. Create your first milestone: /sprint-plan new
```

---

Verdict: **COMPLETE** — engine configured and reference docs populated.

## Guardrails

- NEVER guess an engine version — always verify via WebSearch or user confirmation
- `project.yaml` is the primary config store (v1.1). Always dual-write engine
  config to BOTH `project.yaml` (primary) and `technical-preferences.md` (legacy
  mirror). If the two ever diverge, `project.yaml` is authoritative.
- NEVER overwrite existing reference docs without asking — append or update
- If reference docs already exist for a different engine, ask before replacing
- Always show the user what you're about to change before making CLAUDE.md edits
- If WebSearch returns ambiguous results, show the user and let them decide
- When the user chose **GDScript**: copy the GDScript CLAUDE.md template from **A1** in `.claude/skills/setup-engine/references/godot-language-config.md` exactly. NEVER add "C++ via GDExtension" to the Language field. GDScript projects may use GDExtension, but it is not a primary project language. The `godot-gdextension-specialist` in the routing table is available for when native extensions are needed — it does not make C++ a project language.

---

## Appendix A — Godot Language Configuration

Moved out of this file so it costs nothing on non-Godot runs.

**When the chosen engine is Godot, read**
`.claude/skills/setup-engine/references/godot-language-config.md`
and use the subsection for the chosen language:

- **A1** — CLAUDE.md Technology Stack templates (GDScript / C# / Both)
- **A2** — naming conventions
- **A3** — engine specialist routing and file-extension tables

**Load discipline.** On any engine other than Godot, **never load it** — nothing in Sections 4, 5 or 5.5 needs it, and reading it anyway spends the tokens the split exists to save. On Godot, read it once when you first reach Section 4 and keep using it for Sections 5 and 5.5; do not re-read it at each reference.
