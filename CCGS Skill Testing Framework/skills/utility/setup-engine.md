# Skill Test Spec: $setup-engine

## Skill Summary

`$setup-engine` configures the project's engine, language, rendering backend,
physics engine, specialist agent assignments, and naming conventions by
populating `technical-preferences.md`. It accepts an optional engine argument
(e.g., `$setup-engine godot`) to skip the engine-selection step. For each
section of `technical-preferences.md`, the skill presents a draft and asks
"May I write to `technical-preferences.md`?" before updating.

The skill also populates the specialist routing table (file extension → agent
mappings) based on the chosen engine. It has no director gates — configuration
is a technical utility task. The verdict is always COMPLETE when the file is
fully written.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" collaborative protocol language before updating technical-preferences.md
- [ ] Has a next-step handoff (e.g., `$brainstorm` or `$start` depending on flow)

---

## Director Gate Checks

None. `$setup-engine` is a technical configuration skill. No director gates apply.

---

## Test Cases

### Case 1: Godot 4 + GDScript — Full engine configuration

**Fixture:**
- `technical-preferences.md` contains only placeholders
- Engine argument provided: `godot`

**Input:** `$setup-engine godot`

**Expected behavior:**
1. Skill skips engine-selection step (argument provided)
2. Skill presents language options for Godot: GDScript or C#
3. User selects GDScript
4. Skill drafts all engine sections: engine/language/rendering/physics fields,
   naming conventions (snake_case for GDScript), specialist assignments
   (godot-specialist, gdscript-specialist, godot-shader-specialist, etc.)
5. Skill populates the routing table: `.gd` → gdscript-specialist, `.gdshader` →
   godot-shader-specialist, `.tscn` → godot-specialist
6. Skill asks "May I write to `technical-preferences.md`?"
7. File is written after approval; verdict is COMPLETE

**Assertions:**
- [ ] Engine field is set to Godot 4 (not a placeholder)
- [ ] Language field is set to GDScript
- [ ] Naming conventions are GDScript-appropriate (snake_case)
- [ ] Routing table includes `.gd`, `.gdshader`, and `.tscn` entries
- [ ] Specialists are assigned (not placeholders)
- [ ] "May I write" is asked before writing
- [ ] Verdict is COMPLETE

---

### Case 2: Unity + C# — Unity-specific configuration

**Fixture:**
- `technical-preferences.md` contains only placeholders
- Engine argument provided: `unity`

**Input:** `$setup-engine unity`

**Expected behavior:**
1. Skill sets engine to Unity, language to C#
2. Naming conventions are C#-appropriate (PascalCase for classes, camelCase for fields)
3. Specialist assignments reference unity-specialist, csharp-specialist
4. Routing table: `.cs` → csharp-specialist, `.asmdef` → unity-specialist,
   `.unity` (scene) → unity-specialist
5. Skill asks "May I write to `technical-preferences.md`?" and writes on approval

**Assertions:**
- [ ] Engine field is set to Unity (not Godot or Unreal)
- [ ] Language field is set to C#
- [ ] Naming conventions reflect C# conventions
- [ ] Routing table includes `.cs` and `.unity` entries
- [ ] Verdict is COMPLETE

---

### Case 3: Unreal + Blueprint — Unreal-specific configuration

**Fixture:**
- `technical-preferences.md` contains only placeholders
- Engine argument provided: `unreal`

**Input:** `$setup-engine unreal`

**Expected behavior:**
1. Skill sets engine to Unreal Engine 5, primary language to Blueprint (Visual Scripting)
2. Specialist assignments reference unreal-specialist, blueprint-specialist
3. Routing table: `.uasset` → blueprint-specialist or unreal-specialist,
   `.umap` → unreal-specialist
4. Performance budgets are pre-set with Unreal defaults (e.g., higher draw call budget)
5. Skill asks "May I write" and writes on approval; verdict is COMPLETE

**Assertions:**
- [ ] Engine field is set to Unreal Engine 5
- [ ] Routing table includes `.uasset` and `.umap` entries
- [ ] Blueprint specialist is assigned
- [ ] Verdict is COMPLETE

---

### Case 4: Engine Already Configured — Offers to reconfigure specific sections

**Fixture:**
- `technical-preferences.md` has engine set to Godot 4 with all fields populated
- No engine argument provided

**Input:** `$setup-engine`

**Expected behavior:**
1. Skill reads `technical-preferences.md` and detects fully configured engine (Godot 4)
2. Skill reports: "Engine already configured as Godot 4 + GDScript"
3. Skill presents options: reconfigure all, reconfigure specific section only
   (Engine/Language, Naming Conventions, Specialists, Performance Budgets)
4. User selects "Reconfigure Performance Budgets only"
5. Only the performance budget section is updated; all other fields unchanged
6. Skill asks "May I write to `technical-preferences.md`?" and writes on approval

**Assertions:**
- [ ] Skill does NOT overwrite all fields when only a section update was requested
- [ ] User is offered section-specific reconfiguration
- [ ] Only the selected section is modified in the written file
- [ ] Verdict is COMPLETE

---

### Case 5: Director Gate Check — No gate; setup-engine is a utility skill

**Fixture:**
- Fresh project with no engine configured

**Input:** `$setup-engine godot`

**Expected behavior:**
1. Skill completes full engine configuration
2. No director agents are spawned at any point
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Verdict is COMPLETE without any gate check

---

## Protocol Compliance

- [ ] Presents draft configuration before asking to write
- [ ] Asks "May I write to `technical-preferences.md`?" before writing
- [ ] Respects engine argument when provided (skips selection step)
- [ ] Detects existing config and offers partial reconfigure
- [ ] Routing table is populated for all key file types for the chosen engine
- [ ] Verdict is COMPLETE after file is written

---

## Coverage Notes

- Godot 4 + C# (instead of GDScript) follows the same flow as Case 1 with
  different naming conventions and the godot-csharp-specialist assignment.
  This variant is not separately tested.
- The engine-version-specific guidance (e.g., Godot 4.6 knowledge gap warning
  from VERSION.md) is surfaced by the skill but not assertion-tested here.
- Performance budget defaults per engine are noted as engine-specific but
  exact default values are not assertion-tested.
