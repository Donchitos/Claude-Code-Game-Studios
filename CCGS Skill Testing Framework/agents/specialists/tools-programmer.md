# Agent Test Spec: tools-programmer

## Agent Summary
Domain: Editor extensions, content authoring tools, debug utilities, and pipeline automation scripts.
Does NOT own: game code (gameplay-programmer, ui-programmer, etc.), engine core systems (engine-programmer).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references editor tools / pipeline / debug utilities)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over game source code or engine internals

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Create a custom editor tool for placing enemy patrol waypoints in the level."
**Expected behavior:**
- Produces an editor extension spec and code scaffold for the configured engine (e.g., Godot EditorPlugin, Unity Editor window, Unreal Detail Customization)
- Tool allows designer to click-place waypoints in the scene/viewport
- Waypoints are serialized as engine-native resource (not hardcoded) so level-designer can edit without code
- Includes undo/redo support per editor plugin best practices
- Does NOT modify the AI pathfinding runtime code (that belongs to ai-programmer)

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Implement the enemy melee combo system in code."
**Expected behavior:**
- Does NOT produce gameplay mechanic code
- Explicitly states that combat system implementation belongs to `gameplay-programmer`
- Redirects the request to `gameplay-programmer`
- May note it can build a debug overlay tool to visualize combo state if useful during development

### Case 3: Runtime data access — coordination required
**Input:** "The waypoint editor tool needs to read game data at runtime to validate patrol routes against the AI budget."
**Expected behavior:**
- Identifies that runtime data access from an editor plugin requires a defined, safe interface to the game's runtime systems
- Coordinates with `engine-programmer` to establish a read-only data access pattern (e.g., a resource validation API)
- Does NOT directly read internal engine or game memory structures without an agreed interface
- Documents the required interface before implementing the tool

### Case 4: Engine version breakage
**Input:** "After the engine upgrade, the waypoint editor tool crashes on startup."
**Expected behavior:**
- Checks the engine version reference (`docs/engine-reference/`) for breaking changes in editor plugin APIs
- Identifies the specific API or signal that changed in the new version
- Produces a targeted fix for the breaking change
- Notes any other tools that may be affected by the same API change

### Case 5: Context pass — art pipeline requirements
**Input:** Art pipeline requirements provided in context: "All texture imports must set compression to VRAM Compressed, generate mipmaps, and tag with a LOD group." Request: "Build an asset import tool that enforces these settings."
**Expected behavior:**
- References all three requirements from the context: VRAM compression, mipmap generation, LOD group tagging
- Produces an import tool that validates and applies all three settings on import
- Adds a warning or error report for assets that fail to meet the specified settings
- Does NOT change the art pipeline requirements themselves (those belong to art-director / technical-artist)

---

## Protocol Compliance

- [ ] Stays within declared domain (editor tools, pipeline scripts, debug utilities)
- [ ] Redirects game code requests to appropriate programmer agents
- [ ] Returns structured findings (tool specs, editor extension code, pipeline scripts)
- [ ] Coordinates with engine-programmer before accessing runtime data from editor context
- [ ] Checks engine version reference before using editor plugin APIs
- [ ] Builds tools to enforce requirements, does not author the requirements themselves

---

## Coverage Notes
- Waypoint editor tool (Case 1) should have a smoke test verifying it loads without errors in the editor
- Runtime data access (Case 3) confirms the agent respects the engine-programmer's ownership of core APIs
- Art pipeline context (Case 5) verifies the agent builds to match provided specs rather than inventing requirements
