# Agent Test Spec: cocos-ts-specialist

## Agent Summary
Domain: TypeScript component patterns, `@ccclass` / `@property` decorator usage, async asset loading wrappers, type-safe event systems, lifecycle hooks, and TypeScript-to-Cocos Creator integration.
Does NOT own: shader / Effect files (delegates to cocos-shader-specialist), UI component layout (delegates to cocos-ui-specialist), high-level architecture decisions (delegates to cocos-specialist).
Model tier: Sonnet (default).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references TypeScript / decorators / Component / async loading / EventTarget)
- [ ] `allowed-tools:` list includes Read, Write, Edit, Glob, Grep
- [ ] Model tier is Sonnet (default for specialists)
- [ ] Agent definition does not claim authority over shaders, UI layout, or architecture routing

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Create a `PlayerController` component with inspector-exposed fields for move speed and a spawn point node."
**Expected behavior:**
- Produces a TypeScript class extending `Component` from `'cc'`
- Uses `@ccclass('PlayerController')` decorator with string name matching class name exactly
- Uses `@property` decorators with `type` specification:
  - `@property({ type: CCInteger, range: [1, 20, 1] })` for `moveSpeed`
  - `@property({ type: Node, tooltip: "Spawn point root" })` for `spawnRoot`
- Initializes fields with default values
- Names file `PlayerController.ts` (PascalCase)
- Does NOT use `cc.Class({...})` (removed in v3.0)
- Does NOT access `cc.*` global namespace (use ES module imports)

### Case 2: Out-of-domain redirect
**Input:** "Write an Effect file for a water shader."
**Expected behavior:**
- Does NOT produce `.effect` file content or `CCEffect` / `CCProgram` blocks
- Explicitly states that Effect file authoring belongs to `cocos-shader-specialist`
- Redirects the request appropriately
- May note that the TS-side material assignment code (e.g., `renderer.setMaterial(mat, 0)`) is within its domain if a TS integration layer is needed

### Case 3: Async loading wrapper — callback-to-Promise conversion
**Input:** "I need to load a prefab from a bundle and want to use async/await instead of callbacks."
**Expected behavior:**
- Produces a Promise wrapper around `bundle.load()` callback API
- Uses correct TypeScript generic typing: `loadAsync<T extends Asset>(bundle, path, type: new () => T): Promise<T>`
- Casts the loaded asset to `T` in the resolve callback
- Includes error handling via `reject(err)`
- Does NOT use `cc.loader.loadRes()` (removed in v3.0) — uses `bundle.load()` or `resources.load()`
- Shows the usage pattern with `await`

### Case 4: Type-safe event system
**Input:** "Set up a global event bus with type-safe events for player:hit, player:die, level:complete."
**Expected behavior:**
- Produces an `EventMap` type interface mapping event names to callback signatures:
  ```typescript
  type EventMap = {
      'player:hit': (damage: number, source: Node | null) => void;
      'player:die': () => void;
      'level:complete': (levelId: number, stars: number) => void;
  };
  ```
- Implements a wrapper class over `EventTarget` with generic `on<K extends keyof EventMap>`, `off`, `emit`, `once`
- Casts event names to `string` internally (Cocos API constraint) but the public API is type-safe
- Exports a singleton instance
- Does NOT use string-based event names without the type map (anti-pattern)

### Case 5: Context pass — lifecycle hooks
**Input:** Project context: Cocos Creator 3.8.6. Request: "Subscribe to a global event in `onLoad` — should I unsubscribe in `onDestroy`?"
**Expected behavior:**
- Applies 3.8.6 lifecycle context: `onLoad`, `start`, `onEnable`, `onDisable`, `onDestroy`, `update`
- Recommends pairing subscribe in `onLoad` with unsubscribe in `onDestroy` (correct pattern for permanent subscriptions)
- Notes the alternative: subscribe in `onEnable` / unsubscribe in `onDisable` for subscriptions that should pause when component is disabled
- Warns against subscribing in `update()` (creates a new listener every frame — memory leak)
- Uses `this` as the target argument in `on(event, callback, this)` to preserve binding

---

## Protocol Compliance

- [ ] Stays within declared domain (TypeScript patterns, decorators, async loading, type-safe events, lifecycle hooks)
- [ ] Redirects shader / Effect file authoring to cocos-shader-specialist
- [ ] Redirects UI layout to cocos-ui-specialist
- [ ] Redirects architecture decisions to cocos-specialist
- [ ] Never produces `cc.Class({...})`, `cc.loader.*`, or other removed v3.0 APIs
- [ ] Always uses ES module imports (`import { ... } from 'cc'`) — never `cc.*` global access
- [ ] Uses correct decorator syntax with `type` specification for `@property`

---

## Coverage Notes
- Component pattern (Case 1) verifies the agent produces idiomatic v3.8 TypeScript, not legacy `cc.Class` patterns
- Async wrapper (Case 3) confirms the agent can convert callback APIs to Promise-based patterns
- Type-safe events (Case 4) verifies the agent applies advanced TypeScript patterns to Cocos Creator's event system
- Lifecycle (Case 5) confirms the agent understands component lifecycle pairing for subscriptions
