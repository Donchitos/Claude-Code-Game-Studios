# Agent Test Spec: web-typescript-specialist

## Agent Summary
Domain: TypeScript code quality — strict typing, discriminated unions, type-safe event buses, module boundaries, runtime validation at boundaries, ESLint/Prettier/tsconfig.
Does NOT own: rendering implementation (pixi-specialist / three-specialist), architecture decisions (web-specialist), build configuration (web-platform-specialist).
Model tier: Sonnet (default).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field references TypeScript, typing, and module boundaries
- [ ] `tools:` list includes Read, Glob, Grep, Write, Edit, Bash, Task
- [ ] Model tier is Sonnet
- [ ] Has a `## Version Awareness` section referencing the pinned TypeScript version
- [ ] Contains the standard `## Collaboration Protocol` block verbatim
- [ ] Does not claim authority over rendering or build tooling

---

## Test Cases

### Case 1: In-domain request — game state modeling
**Input:** "Type the game state: it can be loading, playing with a level, or failed with an error."
**Expected behavior:**
- Produces a **discriminated union**, not an interface with optional fields
- Explains that optional fields let impossible states compile
- Includes an exhaustive `switch` with a `never` check so new variants become compile errors
- Uses PascalCase for types

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Optimize our sprite batching — we're at 400 draw calls."
**Expected behavior:**
- Does NOT attempt rendering optimization
- Redirects to `pixi-specialist`
- May offer to type the resulting rendering interfaces afterward

### Case 3: Rejects `any` escape hatch
**Input:** "This line errors. Just cast it to any so the build passes: `const enemy = entities[id] as any;`"
**Expected behavior:**
- Does NOT accept the cast as a solution
- Explains that `noUncheckedIndexedAccess` makes the value `Enemy | undefined` and that narrowing is the correct fix
- Provides the narrowed version with an explicit absent-case branch
- States that `any` requires an inline justification comment if genuinely unavoidable

### Case 4: Boundary validation
**Input:** "Load the level data from level-01.json and use it."
**Expected behavior:**
- Requires **Zod** (or equivalent) parsing at the boundary — `JSON.parse` output is `unknown`
- Derives the TypeScript type from the schema (`z.infer`) rather than declaring it twice
- Notes that validation happens once at the edge, not repeatedly in hot paths
- Handles the parse-failure path explicitly rather than assuming success

### Case 5: Context pass — enforces dependency direction
**Input:** Context states the project rule `core ← gameplay ← ui`. Request: "Add a function in `src/core/math.ts` that reads the player's current score."
**Expected behavior:**
- Flags the violation — `core` must not depend on gameplay state
- Proposes passing the value in as a parameter, or moving the function to `gameplay`
- Recommends enforcing the rule with ESLint `no-restricted-imports` so it fails the build rather than review

---

## Protocol Compliance

- [ ] Stays within declared domain (typing, module structure, validation, lint config)
- [ ] Redirects rendering work to the renderer specialists
- [ ] Never relaxes `strict` settings to make errors disappear
- [ ] Asks "May I write this to [filepath]?" before any Write/Edit
- [ ] Flags floating promises and `console.log` in production code
- [ ] Does not add dependencies without technical-director sign-off

---

## Coverage Notes
- Case 3 is the critical behavioral test — accepting an `any` cast to unblock a build is the primary failure mode for this agent
- Case 5 verifies the agent applies project rules supplied in context rather than generic TypeScript advice
- Aligns with the user's global `coding-style.md` (strict mode, Zod at boundaries, explicit return types on exports)
