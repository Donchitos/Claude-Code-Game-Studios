# /setup-engine — Section 2: Guided Mode

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 2. Guided Mode (No Arguments)

**In this file:**

- An engine already there
- Check for existing game concept
- No engine named: offer web first
- Help me choose
- Produce a recommendation

### An engine already there

An existing project keeps its engine. Web is the default for a new project only,
never a change to an existing one.

- **`engine.name` is set** in `project.yaml`: say which engine it is and carry on
  with it, as if `/setup-engine <that engine>` had been typed. Offer no other
  engine, web included. Changing it is the user's own call, typed as
  `/setup-engine <engine>`.
- **No engine set, but its files are on disk:** `project.godot` is Godot,
  `ProjectSettings/ProjectVersion.txt` is Unity, a `*.uproject` is Unreal, and a
  `package.json` is Web (`references/web.md` W1 records it as it is). Say what
  you found and carry on with that engine; offer no other first.

Only a project with neither goes on below.

### Check for existing game concept
Read the design artifact for the resolved tier (see **Tier awareness** above), by
section: list its headings with `bash .claude/scripts/md-section.sh list <file>` and read only
the ones you need with `md-section.sh extract <file> "<heading>"`:
- **`standard` / `full`**: read `design/gdd/game-concept.md` if it exists —
  extract genre, scope, platform targets, art style, team size, and the engine
  preference `/brainstorm` recorded (an engine the user named, or "undecided":
  `/brainstorm` never recommends one, so the recommendation is made here).
- **`minimal`**: read `design/game-brief.md` if it exists — extract genre,
  scope, platform, and art direction from its fields. Its absence is **expected**
  at `minimal` (the brief is authored *after* engine setup in the minimal path), so
  do not treat a missing brief as a gap.

An engine the user named, here or in the concept or brief, is the engine: go on
with it (Section 1, Engine only). Otherwise no engine is named.

### No engine named: offer web first

Say one line first: "Godot, Unity or Unreal fit better for a big 3D game, a
console or phone-store release, or an engine you already know."

Ask with the question tool: "Which engine? Web is the quickest start: the game
runs in any browser, and Node is the only install." Options, Web always first:
`Web (Recommended)` / `Godot` / `Unity` / `Unreal Engine 5`. The user may also
type "help me choose" (without the question tool, list it as option 5).

When the concept or brief needs what web does not do (a console or phone-store
release, a large 3D open world, photoreal 3D), Web stays first but loses
`(Recommended)`: mark the engine that fits, and make the one line say why from
their words ("Your brief says console: Unity or Unreal fit that better").

- **Web:** read `references/web.md` and follow it, as `/setup-engine web`.
- **Godot, Unity or Unreal:** go on with it (Section 1, Engine only).
- **Help me choose:** the questions below.

### Help me choose

**Question 1 — Prior experience.** Ask: "Have you made a game in any of these
before?" Options: `Web (TypeScript or JavaScript)` / `Godot` / `Unity` /
`Unreal Engine 5`; a typed "none" or "several" is an answer too.
- A specific engine → recommend it. Prior experience outweighs all other factors. Confirm with them and skip the rest.
- None or several → continue below.

**Question 2 — Target platform.** Ask: "Where should the game be played?" Options:
`Browser or PC` / `Phone` / `Console` / `Several`. Platform weighs engines before
any other factor:
  - Browser → Web; Godot exports to the web too; Unity's web build works; Unreal has no web build
  - Mobile → Unity strongly preferred; Unreal is a poor fit; Godot is viable for simple mobile; Web needs a wrapper for the stores
  - Console → Unity or Unreal; Godot console support requires third-party publishers or significant extra work; Web cannot
  - PC only → all engines viable; other factors decide
  - Several → Unity is the most portable across PC, mobile and console

Then, in plain text:
1. **What kind of game?** (2D, 3D, or both?)
2. **Primary input method?** (keyboard/mouse, gamepad, touch, or mixed?)
3. **Team size and experience?** (solo beginner, solo experienced, small team?)
4. **Any strong language preferences?** (TypeScript, GDScript, C#, C++, visual scripting?)
5. **Budget for engine licensing?** (free only, or commercial licenses OK?)

### Produce a recommendation

Do not use a simple scoring matrix that eliminates engines. Instead, reason through the user's profile against the honest tradeoffs below, then present 1-2 recommendations with full context. Always end with the user choosing — never force a verdict.

**Engine honest tradeoffs:**

**Web** (TypeScript, Vite, Canvas 2D and Web Audio; `docs/engine-reference/web/VERSION.md`)
- Genuine strengths: plays in any browser, shared with one link or on itch.io; the quickest start (`/prototype` builds the same kind of game); no editor to learn; tests run headless; free and open source
- Real limitations: no visual editor or asset store; heavy 3D and large worlds are limited by the browser; no console release; phone stores need a wrapper
- Best fit: 2D and light 3D; first games, jams and games meant to be shared by link

**Godot 4**
- Genuine strengths: 2D (best in class), stylized/indie 3D, rapid iteration, free forever (MIT), open source, gentlest learning curve, best for solo devs who want full control
- Real limitations: 3D ecosystem is thin compared to Unity/Unreal (fewer tutorials, assets, community answers for 3D-specific problems); large open-world 3D is very hard and largely untested in Godot; console export requires third-party publishers or significant extra work; smaller professional job market
- Licensing reality: Truly free with no revenue thresholds ever. MIT license means you own everything.
- Best fit: 2D games of any scope; stylized/atmospheric 3D; contained 3D worlds (not open-world); first game projects where learning curve matters; projects where budget is a hard constraint at any scale

**Unity**
- Genuine strengths: Industry standard for mid-scope 3D and mobile; massive asset store and tutorial ecosystem; C# is a professional language; best console certification support for indie; strong community for almost every genre
- Real limitations: Licensing controversy in 2023 damaged trust (runtime fee was proposed then walked back — the risk of policy changes remains real); C# has a steeper initial curve than GDScript; heavier editor than Godot for simple projects
- Licensing reality: Unity Personal is free below a revenue ceiling; the terms changed several times in 2023–2024, so check Unity's current pricing page before quoting a threshold, and cite it.
- Best fit: Mobile games; mid-scope 3D; games targeting console; developers with C# background; projects needing large asset store; teams of 2-5

**Unreal Engine 5**
- Genuine strengths: Best-in-class 3D visuals (Lumen, Nanite, Chaos physics); industry standard for AAA and photorealistic 3D; large open-world support is mature and production-tested; Blueprint visual scripting lowers C++ barrier; strong for games targeting high-end PC or console
- Real limitations: Steepest learning curve; heaviest editor (slow compile times, large project sizes); overkill for stylized/2D/small-scope games; C++ is genuinely hard; not suitable for mobile or web; 5% royalty past USD 1M gross revenue
- Licensing reality: 5% royalty only applies AFTER USD 1M gross revenue per title. For a first game or any game that doesn't reach USD 1M, it costs nothing. This threshold is high enough that most indie developers will never pay it.
- Best fit: AAA-quality 3D; large open-world games; photorealistic visuals; developers with C++ experience or willing to use Blueprint; games targeting high-end PC/console where visual fidelity is a core selling point

**Genre-specific guidance** (factor this into the recommendation):
- Small 2D, puzzle, arcade or jam game, or one to share by link → Web
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
5. Ask: "Does this recommendation feel right, or would you like to explore a different engine?"
   - Options: `[Primary engine] (Recommended)` / `[Alternative engine]` / `[Third engine]` / `Explore further`

**If the user picks "Explore further":**
Ask about concept-specific deep-dive topics; more than one may be picked. Always generate these options from the user's actual concept — do not use generic options. Always include at minimum:
- The primary engine's specific limitations for this concept (e.g., "How far can Godot 3D actually go for [genre]?")
- The alternative engine's specific tradeoffs for this concept
- Language choice impact on this concept's technical challenges
- Any concept-specific technical concern (e.g., adaptive audio, open-world streaming, multiplayer netcode)

The user can select multiple topics. Answer each selected topic in depth before returning to the engine confirmation question.

---
