# Agent Test Spec: prototyper

## Agent Summary
- **Domain**: Rapid throwaway prototypes in the `prototypes/` directory, concept validation experiments, mechanical feasibility tests. Standards intentionally relaxed for speed — prototypes are not production code.
- **Does NOT own**: Production source code in `src/` (gameplay-programmer), design documents (game-designer), production-grade architecture decisions (lead-programmer / technical-director)
- **Gate IDs**: None; produces recommendation docs after prototype conclusion; does not participate in phase gates

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references throwaway builds / concept prototypes / speed over standards)
- [ ] `tools:` reads Read, Glob, Grep, Write, Edit, Bash (it writes and runs throwaway builds) and `isolation:` reads `worktree` — frontmatter cannot scope writes to a directory, so the boundary to `prototypes/` is the body's Isolation Requirements (next assertion)
- [ ] Model tier is `sonnet` — frontmatter `model:` reads exactly `sonnet` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition explicitly states that prototype code is not production code and must not be copied into the production code root

---

## Test Cases

### Case 1: In-domain request — prototype a card-drawing mechanic
**Input**: "Prototype a card-drawing mechanic in 2 hours. The core question: does drawing 3 cards per turn with hand-size limit of 7 feel good? I need something to test in a playtest today."
**Expected behavior**:
- States the falsifiable hypothesis ("If the player draws 3 cards per turn with a hand limit of 7, they will feel [Y] — evidenced by [Z]") and the riskiest assumption before building
- Recommends a prototype path with rationale — a card mechanic where timing precision is not the question points to the HTML or Paper path, not the Engine path
- Proposes scope in 3–5 bullets (deck, draw N, hand limit 7, a minimal state display) and gets confirmation before building
- Output goes to `prototypes/card-draw-concept/` (e.g., a single self-contained `prototype.html` that opens by double-click, or `rules.md` + `play-log.md` on the Paper path); every code file starts with the `PROTOTYPE - NOT FOR PRODUCTION` header naming the question and date
- Code prioritizes speed over correctness: no unit tests, no doc comments required, global state is acceptable; no menus or polish
- Does NOT implement production patterns (dependency injection, signals, data-driven config) unless they take less time than not using them
- Asks "May I write this to [filepath]?" before writing

### Case 2: Out-of-domain request — production-grade implementation
**Input**: "The card mechanic prototype worked great. Now write the production implementation of the card system for src/gameplay/cards/."
**Expected behavior**:
- Does not write production code to `src/`
- States clearly that prototype code is throwaway: production implementation of a validated mechanic is written from scratch to proper standards, and the prototype is reference only
- Points to the prototype's `REPORT.md` (hypothesis, result, recommendation, tuning values discovered, lessons learned) as what carries into production — offering to write it if it does not exist yet — so the knowledge transfers, not the code
- Routes production architecture questions to `lead-programmer`
- Does NOT copy the prototype code into src/ or suggest it as a starting point without warning about its non-production quality

### Case 3: Prototype validates the mechanic — recommendation output
**Input**: "The card-draw prototype playtested well. Three sessions all enjoyed drawing 3 cards/turn with hand limit 7. No confusion observed. What's next?"
**Expected behavior**:
- Produces `prototypes/card-draw-concept/REPORT.md` from the concept prototype report template, asking for approval before writing it
- Report includes: the hypothesis tested, riskiest assumption, Result as specific observations (3 sessions, no confusion observed), playtester count and a hypothesis verdict of CONFIRMED, **Recommendation: PROCEED** with that evidence, the tuning values to preserve (3 cards/turn, hand limit 7), and lessons learned
- Updates `prototypes/index.md` after the report is written
- Presents PROCEED as a recommendation — the decision belongs to the user / creative-director, not the prototyper
- Does NOT begin writing production code; the next step it points to is design work (GDDs), not implementation
- Output is structured as a decision-ready recommendation, not a narrative summary

### Case 4: Prototype reveals the mechanic is unworkable — abandonment note
**Input**: "The prototype for the physics-based lock-picking mechanic is done. After 4 playtest sessions, all testers found it frustrating — too much precision required, not fun. One tester rage-quit."
**Expected behavior**:
- Produces `prototypes/lock-picking-physics-concept/REPORT.md` from the concept prototype report template, asking for approval before writing it
- Report includes: the hypothesis tested, a hypothesis verdict of REFUTED, and specific reasons as observations (precision barrier too high, negative emotional response across all 4 sessions, rage-quit incident as evidence)
- **Recommendation: KILL** for the physics-based approach — or PIVOT only with a concrete pivot direction and what to keep (e.g., a simplified key-tumbler or rhythm-based mechanic); never PROCEED
- Does NOT recommend persisting with the prototype mechanic because of sunk cost — the verdict is based on evidence, not effort invested
- Does NOT mark the result as inconclusive — after 4 sessions with consistent negative responses, the evidence supports a decision

### Case 5: Context pass — using the project's engine scripting language
**Input context**: Project uses Godot 4.6 with GDScript (`engine.name` and `engine.language` in `project.yaml`); the user has chosen the Engine path.
**Input**: "Prototype a basic grid movement system — player clicks a tile and the character moves to it."
**Expected behavior**:
- Produces the prototype in GDScript — not Python, C#, or pseudocode
- Uses Godot 4.6 node types appropriate for a grid: TileMapLayer (not TileMap, which `docs/engine-reference/godot/deprecated-apis.md` lists as deprecated since 4.3) or a custom grid manager node, CharacterBody2D or Node2D for the player
- Does NOT apply production coding standards (no required test coverage, no doc comments, global state acceptable)
- Writes the output to `prototypes/grid-movement-concept/` not to `src/`
- After writing, hands control back: asks the user to run the project and paste any errors or describe what they observe, rather than assuming it worked
- If a Godot 4.6 API is uncertain, flags the specific API with a note to verify against the Godot 4.6 docs — `docs/engine-reference/godot/VERSION.md` reaches the agent through `CLAUDE.md`'s import, and its Knowledge Gap Warning says to cross-reference that directory before suggesting Godot API calls

---

## Protocol Compliance

- [ ] Stays within declared domain (prototypes/ directory only; throwaway code for concept validation)
- [ ] Declines production implementation requests, stating production is written from scratch and pointing to the prototype's REPORT.md as the hand-off
- [ ] Produces a structured REPORT.md with a PROCEED / PIVOT / KILL recommendation, backed by evidence, after prototype evaluation
- [ ] Does not recommend preserving prototype code in production form without explicit warnings
- [ ] Uses the project's configured engine and scripting language; flags version uncertainty, per the Knowledge Gap Warning in the `VERSION.md` that `CLAUDE.md` imports

---

## Coverage Notes
- Case 2 (production redirect) is critical — prototype code leaking into src/ is a common quality problem
- Case 4 (abandonment honesty) tests whether the agent avoids sunk-cost bias — prototypes that fail should be cleanly abandoned
- Case 5 requires that `project.yaml` has `engine.name` and `engine.language` configured; test is incomplete if not configured. With neither `project.yaml` nor `.claude/docs/technical-preferences.md` naming them, the expected output is a question about the engine and language, not a guess
- The intentional relaxation of coding standards is a feature, not a gap — do not flag missing tests or doc comments as failures in prototype output
- No automated runner; review manually or via `/skill-test`
