# /setup-engine — Section 2: Guided Mode

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 2. Guided Mode (No Arguments)

**In this file:**

- Check for existing game concept
- If the user wants to pick without a concept, ask in this order
- Produce a recommendation

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
