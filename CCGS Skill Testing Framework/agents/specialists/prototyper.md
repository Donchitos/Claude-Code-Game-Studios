# Agent Test Spec: prototyper

## Agent Summary
- **Domain**: Rapid throwaway prototypes in the `prototypes/` directory, concept validation experiments, mechanical feasibility tests. Standards intentionally relaxed for speed — prototypes are not production code.
- **Does NOT own**: Production source code in `src/` (gameplay-programmer), design documents (game-designer), production-grade architecture decisions (lead-programmer / technical-director)
No fixed model routing is required; the caller selects the available Codex model.
- **Gate IDs**: None; produces recommendation docs after prototype conclusion; does not participate in phase gates

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references rapid prototyping, prototypes/ directory, throwaway code)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition explicitly states that prototype code is not production code and must not be copied to src/

---

## Test Cases

### Case 1: In-domain request — prototype a card-drawing mechanic
**Input**: "Prototype a card-drawing mechanic in 2 hours. The core question: does drawing 3 cards per turn with hand-size limit of 7 feel good? I need something to test in a playtest today."
**Expected behavior**:
- Produces a minimal working prototype written in the project's engine scripting language, scoped to `prototypes/card-draw-mechanic/`
- Code prioritizes speed over correctness: no unit tests, no doc comments required, global state is acceptable for a prototype
- Implements the minimal viable mechanic: a deck, a draw function (draw N cards), a hand container with a size limit, and a simple UI or debug print to verify state
- Does NOT implement production patterns (dependency injection, signals, data-driven config) unless they take less time than not using them
- Includes a `README.md` in the prototype folder: hypothesis being tested, how to run, what to observe in the playtest

### Case 2: Out-of-domain request — production-grade implementation
**Input**: "The card mechanic prototype worked great. Now write the production implementation of the card system for src/gameplay/cards/."
**Expected behavior**:
- Does not write production code to `src/`
- States clearly: "Prototyper produces throwaway code in prototypes/ to validate concepts; production implementation of validated mechanics is handled by gameplay-programmer"
- Offers to produce a transition document: what the prototype proved, what the production implementation should preserve (the mechanic), and what it should discard (the throwaway implementation patterns)
- Does NOT copy the prototype code into src/ or suggest it as a starting point without warning about its non-production quality

### Case 3: Prototype validates the mechanic — recommendation output
**Input**: "The card-draw prototype playtested well. Three sessions all enjoyed drawing 3 cards/turn with hand limit 7. No confusion observed. What's next?"
**Expected behavior**:
- Produces a prototype conclusion document in `prototypes/card-draw-mechanic/conclusion.md` (or equivalent)
- Document includes: hypothesis that was tested, playtest method (sessions, duration, observer notes), result verdict (VALIDATED), key findings (what worked, any minor issues observed), recommendation for production (specific mechanic parameters to preserve: 3 cards/turn, hand limit 7), and a flag to route the production implementation request to gameplay-programmer
- Does NOT begin writing production code
- Output is structured as a decision-ready recommendation, not a narrative summary

### Case 4: Prototype reveals the mechanic is unworkable — abandonment note
**Input**: "The prototype for the physics-based lock-picking mechanic is done. After 4 playtest sessions, all testers found it frustrating — too much precision required, not fun. One tester rage-quit."
**Expected behavior**:
- Produces a prototype abandonment note in `prototypes/lock-picking-physics/conclusion.md`
- Document includes: hypothesis that was tested, result verdict (ABANDONED), specific reasons (precision barrier too high, negative emotional response, rage-quit incident as evidence), and a recommendation for alternative approaches to explore (simplified key-tumbler mechanic, rhythm-based alternative, removal of the mechanic entirely)
- Does NOT recommend persisting with the prototype mechanic because of sunk cost
- Does NOT mark the result as inconclusive — after 4 sessions with consistent negative responses, abandonment is the correct verdict

### Case 5: Context pass — using the project's engine scripting language
**Input context**: Project uses Godot 4.6 with GDScript (configured in technical-preferences.md).
**Input**: "Prototype a basic grid movement system — player clicks a tile and the character moves to it."
**Expected behavior**:
- Produces the prototype in GDScript — not Python, C#, or pseudocode
- Uses Godot 4.6 node types appropriate for a grid: TileMap or a custom grid manager node, CharacterBody2D or Node2D for the player
- Does NOT apply production coding standards (no required test coverage, no doc comments, global state acceptable)
- Writes the output to `prototypes/grid-movement/` not to `src/`
- If a Godot 4.6 API is uncertain (given the LLM knowledge cutoff noted in VERSION.md), flags the specific API with a note to verify against the Godot 4.6 docs

---

## Protocol Compliance

- [ ] Stays within declared domain (prototypes/ directory only; throwaway code for concept validation)
- [ ] Redirects production implementation requests to gameplay-programmer with a transition document offer
- [ ] Produces structured conclusion documents (VALIDATED or ABANDONED verdict) after prototype evaluation
- [ ] Does not recommend preserving prototype code in production form without explicit warnings
- [ ] Uses the project's configured engine and scripting language; flags version uncertainty

---

## Coverage Notes
- Case 2 (production redirect) is critical — prototype code leaking into src/ is a common quality problem
- Case 4 (abandonment honesty) tests whether the agent avoids sunk-cost bias — prototypes that fail should be cleanly abandoned
- Case 5 requires that technical-preferences.md has the engine and language configured; test is incomplete if not configured
- The intentional relaxation of coding standards is a feature, not a gap — do not flag missing tests or doc comments as failures in prototype output
- No automated runner; review manually or via `$skill-test`
