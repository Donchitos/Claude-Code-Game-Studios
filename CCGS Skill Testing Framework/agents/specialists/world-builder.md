# Agent Test Spec: world-builder

## Agent Summary
- **Domain**: World lore architecture — factions and their cultures/governments/motivations, world history, geography and ecology, cosmology and metaphysics, world rules (how magic works, what is and is not possible), internal consistency enforcement across the world document
- **Does NOT own**: Specific NPC or quest dialogue (writer), game mechanics rules derived from world rules (game-designer/systems-designer), narrative story structure and arc design (narrative-director)
No fixed model routing is required; the caller selects the available Codex model.
- **Gate IDs**: None; escalates world rule/mechanic conflicts to narrative-director and game-designer jointly

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references world lore, factions, history, world rules, ecology)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over dialogue writing, mechanic design, or narrative arc structure

---

## Test Cases

### Case 1: In-domain request — faction culture and government design
**Input**: "Design the Ironveil Merchant Consortium — a powerful trading faction in our world. I need their culture, government structure, and internal motivations."
**Expected behavior**:
- Produces a faction profile document with: cultural values and norms, government structure (how decisions are made, who holds power, succession or appointment process), internal factions or tensions within the consortium, relationship to other factions (allies, rivals, neutral parties), and primary motivations (what they want and why)
- The faction is internally consistent: a merchant consortium's government is driven by economic logic, not feudal or religious logic, unless a deliberate hybrid is specified
- Output includes at least one internal tension or contradiction within the faction — factions without internal complexity are flat
- Formatted as a structured faction profile, not a narrative essay

### Case 2: Out-of-domain request — dialogue writing
**Input**: "Write the dialogue for a Ironveil Consortium merchant NPC that the player meets at the city gates."
**Expected behavior**:
- Does not produce NPC dialogue
- States clearly: "Dialogue writing is owned by writer; I provide the world and faction context that informs the dialogue, including the faction's culture, tone, and speaking style"
- Offers to produce the faction's speaking style notes and cultural context that writer would need to write consistent dialogue

### Case 3: New lore entry contradicts established history — conflict flagging
**Input**: "Add a lore entry stating the Ironveil Consortium was founded 50 years ago by a single merchant family." [Context includes existing lore: the Consortium has existed for 300 years and was founded as a collective by 12 rival trading houses.]
**Expected behavior**:
- Identifies the contradiction: existing lore states 300-year history and a founding coalition of 12 houses; the new entry claims 50 years and a single founding family
- Does NOT write the new entry as requested
- Flags the conflict: states both versions, identifies which is established and which is the proposed change
- Proposes resolution options: (a) the new entry is wrong and should be corrected; (b) the existing lore should be updated if the new version is the intended canon; (c) there is an in-world explanation (the current family claims founding credit despite the collective origin — a deliberate narrative unreliable narrator)
- Routes the resolution to narrative-director if no clear answer exists

### Case 4: World rule has gameplay implications — coordination with game-designer
**Input**: "I want to establish a world rule: magic users who cast spells near iron ore are weakened. Iron disrupts arcane energy."
**Expected behavior**:
- Produces the world rule as a lore entry: the metaphysical explanation, how it is understood in-world, historical implications
- Identifies the gameplay implication: this world rule has direct mechanical consequences (players near iron ore deposits are debuffed, level design must account for iron placement)
- Flags the coordination requirement: "This world rule has gameplay mechanics implications — game-designer needs to define how this translates into player-facing mechanics; proceeding with the lore without the mechanics definition risks inconsistency"
- Does NOT unilaterally design the game mechanic — describes the lore rule and the mechanical territory it implies, then defers to game-designer

### Case 5: Context pass — using established world documents
**Input context**: Existing world document states: the world uses a dual-sun system, one sun is the source of arcane energy (the White Sun), and arcane magic ceases to function during the 3-day lunar eclipse period (the Darkening).
**Input**: "Add a lore entry about the Mages' College and how they prepare for the Darkening."
**Expected behavior**:
- Uses the established dual-sun cosmology: references the White Sun as the source of arcane energy
- Uses the established Darkening event: 3-day eclipse, magic ceases
- Does NOT invent a different eclipse mechanism, duration, or name
- Produces a lore entry where the Mages' College's Darkening preparations are consistent with the established rules: they cannot cast during the Darkening, so preparations are practical (stockpiling non-magical supplies, scheduling, shutting down ongoing magical processes)
- Does not contradict any established fact from the context document

---

## Protocol Compliance

- [ ] Stays within declared domain (factions, world history, geography, ecology, world rules, cosmology)
- [ ] Redirects dialogue writing requests to writer with contextual faction notes
- [ ] Flags lore contradictions with both versions stated and resolution options offered — does not silently overwrite established lore
- [ ] Identifies gameplay implications of world rules and flags coordination with game-designer
- [ ] Uses all established world facts from context; does not invent alternatives to stated lore

---

## Coverage Notes
- Case 3 (contradiction detection) requires existing lore to be in context — this is the most important consistency test
- Case 4 (world rule/mechanic coordination) tests cross-domain awareness; verify the agent identifies the mechanic boundary without crossing it
- Case 5 is the most important context-awareness test; the agent must use established facts, not creative alternatives
- No automated runner; review manually or via `$skill-test`
