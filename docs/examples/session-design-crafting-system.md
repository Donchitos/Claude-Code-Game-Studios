# Example Session: Designing the Crafting System

**Context:** Solo indie dev, week 2 of project, needs to design the crafting system mentioned in the game pillars.

**Starting State:**
- Game concept and pillars defined
- Engine set up (Godot 4.6)
- Core combat system designed but not implemented yet
- Pillar 2: "Emergent Discovery Through Experimentation"

**Session Duration:** ~45 minutes
**Turns:** 12
**Outcome:** Complete crafting system GDD ready for implementation

---

## Turn 1: User Initiates Design

**User:**
> I need to design the crafting system. Pillar 2 is "Emergent Discovery Through Experimentation", so I want players to discover recipes by trying combinations.

## Turn 2: Agent Asks Clarifying Questions

**Agent (game-designer):**
> I'll help design the crafting system with discovery at its core. Before proposing mechanics, I need to understand your vision:
>
> 1. **Discovery Method**: Should recipes be pure trial-and-error, or should there be hints/clues to guide players?
> 2. **Failure Punishment**: When players try an invalid combination, what happens?
>    - Materials completely lost (harsh)
>    - Materials partially refunded (moderate)
>    - No cost to experiment (forgiving)
> 3. **Progression**: Does crafting skill improve over time? If so, what does higher skill unlock?
> 4. **Scope**: How central is crafting to the game? Core pillar feature or supporting system?
> 5. **Reference Games**: Any crafting systems you love or hate? (Minecraft, Terraria, Stardew Valley, Potion Craft?)

## Turn 3: User Provides Context

**User:**
> 1. I want hints that unlock gradually - start with pure discovery, earn hints through skill
> 2. Moderate punishment - waste materials but gain partial XP
> 3. Yes, skill unlocks hint system and improves success rates
> 4. Core feature - one of the three main loops (combat, exploration, crafting)
> 5. Love Potion Craft's deduction mechanic. Hate Minecraft wikis being mandatory.

## Turn 4: Agent Presents Options

**Agent:**
> Perfect context! Based on "emergent discovery" + "deduction over wikis" + "Potion Craft inspiration", here are three mechanical approaches:
>
> **Option A: Pure Randomized Discovery**
> - **Mechanics**: Try any 2-4 ingredient combo, roll for success based on compatibility
> - **Hint System**: None - players document discoveries manually
> - **Pros**:
>   - Maximum emergent discovery
>   - Community can share findings without breaking core loop
>   - Aligns strongly with "experimentation" pillar
> - **Cons**:
>   - High frustration for completionists
>   - Low skill expression (mostly RNG)
>   - Players may feel "wiki is required" despite your intent
> - **Aligns with Pillars**: ✅✅ Emergent Discovery, ⚠️ Meaningful Choices (randomness reduces agency)
>
> **Option B: Tag-Based Deduction System (Potion Craft-style)**
> - **Mechanics**: Each ingredient has hidden "tags" (Fire, Water, Healing, Damage, etc.)
>   - Recipes require specific tag combinations
>   - At Skill 0: No tags visible, pure experimentation
>   - At Skill 5: Can inspect items to see 1 tag
>   - At Skill 10: See 2 tags, etc.
> - **Hint System**: Tags ARE the hint system, unlocked by skill
> - **Pros**:
>   - Rewards observation and pattern recognition (skill expression!)
>   - Progressive scaffolding - accessible to all player types
>   - Creates "aha!" moments when patterns click
>   - No wiki needed - everything discoverable in-game
> - **Cons**:
>   - More complex to implement (tag system + UI)
>   - Requires careful tag design to avoid degeneracy
> - **Aligns with Pillars**: ✅✅ Emergent Discovery, ✅✅ Meaningful Choices
>
> **Option C: Ingredient Compatibility Matrix**
> - **Mechanics**: Each ingredient pairs well/poorly with others
>   - Success rate = compatibility score
>   - Skill 0: No compatibility shown, ~30% base success
>   - Higher skill: See color-coded compatibility (red/yellow/green)
> - **Hint System**: Visual compatibility indicators unlock with skill
> - **Pros**:
>   - Simple to implement and understand
>   - Clear progression arc (skill = more information)
>   - Feels fair (players understand why they failed)
> - **Cons**:
>   - Less emergent than tag system (more prescriptive)
>   - Optimal recipes more obvious once you have hints
> - **Aligns with Pillars**: ✅ Emergent Discovery, ✅ Meaningful Choices
>
> **My Recommendation: Option B (Tag-Based Deduction)**
>
> **Reasoning:**
> - It's the only option that creates TRUE emergent discovery through systems interaction
> - Players develop mastery by learning tag patterns, not memorizing recipes
> - The progressive reveal (tags unlock with skill) serves both Explorers (discovery) and Achievers (progression)
> - Potion Craft proved this works and is satisfying
> - Avoids wiki-dependency because the deduction is solvable in-game
>
> Which option resonates with your vision? Or should I explore a hybrid?

## Turn 5: User Decides with Modification

**User:**
> Option B feels perfect, but I want to add: failed attempts should give hints about which tags were WRONG, not just which were right. Like "You added Fire, but this recipe needs Water instead."

## Turn 6: Agent Incorporates Feedback and Drafts

**Agent:**
> Excellent modification! That adds a deduction game on TOP of the tag discovery. Now failed attempts aren't just "waste" - they're valuable information.
>
> Let me draft the **Overview** and **Player Fantasy** sections:
>
> ---
>
> ## Overview
>
> The crafting system uses a tag-based deduction mechanic where players experiment with ingredient combinations to discover recipes. Each ingredient has 1-3 hidden tags (Fire, Water, Earth, Air, Healing, Damage, Poison, etc.). Recipes require specific tag combinations. Failed attempts waste materials but provide feedback ("This needs Water, not Fire") that teaches players tag patterns. As crafting skill increases, players unlock the ability to inspect ingredients to see their tags directly, transforming pure experimentation into informed deduction.
>
> ## Player Fantasy
>
> "I'm an alchemist-scientist discovering nature's hidden patterns. Each failed potion teaches me something new about how elements interact. Over time, I develop intuition - I can look at a mushroom and KNOW it contains Earth and Poison tags before even testing it. I don't need recipes from a wiki; I understand the RULES that generate recipes, and I can create my own solutions."
>
> **Target MDA Aesthetics**:
> - Discovery (primary): Uncovering hidden tag patterns
> - Challenge (secondary): Deduction puzzle
> - Expression (tertiary): Creating custom recipes once rules are mastered
>
> ---
>
> Does this capture your intent? Should I continue to **Detailed Rules**?

## Turn 7: User Approves and Requests Next Section

**User:**
> Yes, that's perfect! Continue to Detailed Rules.

## Turn 8: Agent Drafts Rules, Asks About Edge Case

**Agent:**
> Drafting Detailed Rules...
>
> ---
>
> ## Detailed Rules
>
> ### Core Loop
> 1. Player selects 2-4 ingredients from inventory
> 2. Player activates crafting station
> 3. System checks ingredient tags against recipe database
> 4. **If exact tag match**: Success! Recipe learned, item created, full XP awarded
> 5. **If partial match** (some tags correct): Failure. Feedback: "Close! This needs [missing tag]." Materials consumed, 40% XP awarded, recipe marked as "Discovered (Incomplete)"
> 6. **If no match**: Failure. Feedback: "Incompatible. Try replacing [wrong tag] with [needed tag]." Materials consumed, 15% XP awarded
>
> ### Tag System
> - 12 core tags: Fire, Water, Earth, Air, Healing, Damage, Poison, Light, Dark, Metal, Plant, Magic
> - Each ingredient has 1-3 tags (simple ingredients have 1, rare ingredients have 3)
> - Each recipe requires 2-6 total tags (basic potions need 2, advanced need 6)
> - Tag combinations must be unique (no two recipes with identical tag sets)
>
> ### Skill Progression
> - Skill 0-4: No inspection ability. Pure experimentation.
> - Skill 5-9: Can inspect ingredients to see 1 tag
> - Skill 10-14: Can see 2 tags per ingredient
> - Skill 15+: Can see all tags per ingredient
>
> ### XP Gain
> ```
> success_xp = base_xp * recipe_complexity^1.3
> failure_xp_partial = success_xp * 0.40
> failure_xp_none = success_xp * 0.15
> ```
>
> Where `recipe_complexity` = number of unique tags required (2-6)
>
> ---
>
> **Question before I continue:** What happens if a player discovers a tag combination that DOESN'T match any recipe in the database? Should we:
> A) Allow it and create "junk items" (player wasted materials)
> B) Always provide feedback steering toward valid recipes
> C) Procedurally generate a minor potion for any valid tag combo not in the DB
>
> This affects the "experimentation" feel - option A is harsh but realistic, option C rewards all experimentation.

## Turn 9: User Resolves Edge Case

**User:**
> Option C - let's procedurally generate minor potions. If someone finds Fire+Water (not a designed recipe), give them "Warm Water" that restores 5 HP. Rewards experimentation even when "off the beaten path."

## Turn 10: Agent Completes Remaining Sections

**Agent:**
> Perfect! That keeps experimentation always rewarding. Updating rules with that edge case...
>
> [Agent continues drafting Formulas, Edge Cases, Dependencies, Tuning Knobs, and Acceptance Criteria sections, showing each and incorporating minor feedback]
>
> [After all sections complete]
>
> Complete crafting system GDD ready. Here's the summary:
>
> **8 Required Sections:**
> ✅ Overview - Tag-based deduction system
> ✅ Player Fantasy - Alchemist-scientist discovering patterns
> ✅ Detailed Rules - Core loop with tag matching and feedback system
> ✅ Formulas - XP curves, success rates, skill thresholds
> ✅ Edge Cases - Procedural minor potions for non-recipe combos, inventory full, skill at max
> ✅ Dependencies - Requires inventory system, integrates with progression system
> ✅ Tuning Knobs - XP rates, skill thresholds, tag count per ingredient, feedback verbosity
> ✅ Acceptance Criteria - Players discover 10 recipes in 30 minutes without wiki, skill progression feels meaningful
>
> **Delegations Made:**
> - Consulted `systems-designer` for XP curve formula validation
> - Consulted `economy-designer` for material cost balancing
>
> May I write this to `design/gdd/crafting-system.md`?

## Turn 11: User Approves Writing

**User:**
> Yes, write it!

## Turn 12: Agent Writes File and Offers Next Steps

**Agent:**
> ✅ Created `design/gdd/crafting-system.md`
>
> **Next Steps:**
> 1. Run `$design-review design/gdd/crafting-system.md` to validate against 8-section standard
> 2. Create data file structure in `assets/data/` for ingredients and recipes
> 3. When ready to implement, use `$team-combat` pattern but for crafting (game-designer → gameplay-programmer → ui-programmer → qa-tester)
>
> Would you like me to run the design review now, or would you prefer to read it first?

---

## Session Summary

**What Worked Well:**
- Agent asked clarifying questions upfront instead of guessing
- Presented 3 distinct options with clear pros/cons and pillar alignment
- User's modification ("wrong tag feedback") was incorporated immediately
- Edge case (non-recipe combos) was flagged proactively, not assumed
- Each section was shown for approval before moving to next
- Explicit permission requested before writing file

**Key Collaborative Moments:**
- Turn 2: Agent asked 5 questions to understand vision
- Turn 4: Agent presented 3 options, made recommendation but deferred to user
- Turn 5: User modified recommended option, agent incorporated it
- Turn 8: Agent caught edge case and asked rather than assuming
- Turn 9: User's choice (procedural potions) changed design direction
- Turn 10: Agent requested approval before writing file

**Files Created:**
- `design/gdd/crafting-system.md` (complete 8-section GDD)

**Context Usage:** ~35% (estimated)
**User Satisfaction:** High - user made all creative decisions, agent provided expert guidance
