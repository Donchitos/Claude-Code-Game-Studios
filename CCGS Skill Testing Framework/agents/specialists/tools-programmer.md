# Agent Test Spec: tools-programmer

## Agent Summary
Domain: Editor extensions, content authoring tools, debug utilities, and pipeline automation scripts.
Does NOT own: game runtime code (gameplay-programmer), engine core systems (engine-programmer), art pipeline requirements (technical-artist).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references editor tools / pipeline / debug utilities)
- [ ] `tools:` list includes Read, Write, Edit, Bash, Glob, Grep
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
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
- Any part it offers is tooling on its side of the line — e.g., a debug overlay that visualizes combo state — never combo logic

### Case 3: Runtime data access — coordination required
**Input:** "The waypoint editor must check at edit time that every patrol segment is walkable, but the collision queries that answer this live in the game's runtime code and the editor cannot call them."
**Expected behavior:**
- Identifies that the tool needs a runtime query the editor cannot yet call, and that adding one is a change to game runtime code
- Does NOT add the runtime hook itself — delegates it to `engine-programmer` (collision queries are engine-level runtime code) and asks before coordinating ("This will require changes to [other system]. Should I coordinate with that first?")
- Documents the read-only interface the tool needs (inputs, outputs, called from editor context) before implementing the tool
- Reports failing segments as clear, actionable errors rather than silently skipping them

### Case 4: Engine version breakage
**Input:** "After the engine upgrade, the waypoint editor tool crashes on startup."
**Expected behavior:**
- Checks the engine version reference (`docs/engine-reference/`) before touching editor plugin APIs, including the pinned version in VERSION.md against the upgraded editor (an `Installed at pin time` of NOT DETERMINED is an unknown gap, not a match)
- Looks for the failing API in the reference's breaking-changes and deprecated-APIs files rather than recalling it from training data; if they do not cover it, says so instead of asserting a cause
- Produces a targeted fix for the breaking change
- Tests the fix on representative data before calling the tool fixed

### Case 5: Context pass — art pipeline requirements
**Input:** Art pipeline requirements provided in context: "All texture imports must set compression to VRAM Compressed, generate mipmaps, and tag with a LOD group." Request: "Build an asset import tool that enforces these settings."
**Expected behavior:**
- References all three requirements from the context: VRAM compression, mipmap generation, LOD group tagging
- Produces an import tool that validates and applies all three settings on import
- Adds a warning or error report for assets that fail to meet the specified settings
- Treats the three settings as given: does NOT change or add requirements itself — any change it thinks is needed is raised with `technical-artist`, its partner for art pipeline tools

---

## Protocol Compliance

- [ ] Stays within declared domain (editor tools, pipeline scripts, debug utilities)
- [ ] Redirects game code requests to appropriate programmer agents
- [ ] Returns structured findings (tool specs, editor extension code, pipeline scripts)
- [ ] Delegates any runtime-code change a tool depends on (e.g., a query API) to engine-programmer or gameplay-programmer instead of making it
- [ ] Checks engine version reference before using editor plugin APIs
- [ ] Builds tools to enforce requirements, does not author the requirements themselves
- [ ] Asks "May I write this to [filepath]?" naming the file before writing

---

## Coverage Notes
- Waypoint editor tool (Case 1) should have a smoke test verifying it loads without errors in the editor
- Runtime data access (Case 3) confirms the agent respects the engine-programmer's ownership of core APIs
- Art pipeline context (Case 5) verifies the agent builds to match provided specs rather than inventing requirements
