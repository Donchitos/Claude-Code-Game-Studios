# Agent Test Spec: writer

## Agent Summary
- **Domain**: In-game written content — NPC dialogue (including branching trees), lore codex entries, item and ability descriptions, environmental text (signs, books, notes), quest text, tutorial text, in-world written documents
- **Does NOT own**: Story architecture and narrative structure (narrative-director), world lore and world rules (world-builder), UX copy and UI labels (ux-designer), patch notes (community-manager)
No fixed model routing is required; the caller selects the available Codex model.
- **Gate IDs**: None; flags lore inconsistencies to narrative-director rather than resolving them autonomously

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references dialogue, lore entries, item descriptions, in-game text)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over narrative structure, world rules, or UX copy direction

---

## Test Cases

### Case 1: In-domain request — NPC merchant dialogue
**Input**: "Write dialogue for Mira, a traveling merchant NPC. She sells general supplies. Players can ask her about her wares, the road ahead, and rumors."
**Expected behavior**:
- Produces a dialogue tree with at least three top-level conversation options: [Wares], [The Road Ahead], [Rumors]
- Each branch has a distinct conversational response in Mira's voice — not generic merchant filler
- Includes at least one response that has a follow-up branch (showing tree structure, not just flat responses)
- Mira's voice is consistent across branches: if she's warm and chatty in one branch, she's not brusque in another without reason
- Output is formatted as a structured dialogue tree: node label, NPC line, player options, next node

### Case 2: Out-of-domain request — world history design
**Input**: "Design the history of the world — when the first kingdom was founded, what the great wars were, and why magic was banned."
**Expected behavior**:
- Does not produce world history, lore architecture, or world rules
- States clearly: "World history, lore, and world rules are owned by world-builder; once the history is established, I can write in-game texts, books, and dialogue that reference those events"
- Does not produce even partial world history as a "placeholder"

### Case 3: Dialogue contradicts established lore — flag to narrative-director
**Input**: "Write Mira's dialogue line where she mentions that dragons have been extinct for 200 years." [Context includes existing lore: dragons are alive and revered in the northern provinces, not extinct.]
**Expected behavior**:
- Identifies the contradiction: established lore states dragons are alive and revered; dialogue stating they're extinct directly conflicts
- Does NOT write the requested line as given
- Flags the inconsistency to narrative-director: "Mira's dialogue as requested contradicts established lore (dragons are alive per world-builder's document); requires narrative-director resolution before I can write this line"
- Offers an alternative: a line that references dragons in a way consistent with the established lore (e.g., Mira expresses awe about a dragon sighting in the north)

### Case 4: Item description references an undesigned mechanic
**Input**: "Write a description for the 'Berserker's Chalice' — a consumable that triggers the Berserker state when drunk."
**Expected behavior**:
- Identifies the dependency gap: "Berserker state" is not defined in any provided game design document
- Flags the missing dependency: "This description references a 'Berserker state' mechanic that has no GDD entry — I cannot write accurate flavor text for a mechanic whose rules are undefined, as the description may create incorrect player expectations"
- Does NOT write a description that invents mechanic details (duration, effects) that may conflict with the eventual design
- Offers two paths: (a) write a vague, non-mechanical description that creates no false expectations, flagged as temporary; (b) wait for game-designer to define the Berserker state first

### Case 5: Context pass — character voice guide
**Input context**: Character voice guide for Mira: She speaks in short, energetic sentences. Uses merchant slang ("a fine bargain," "coin well spent"). Drops pronouns occasionally ("Good wares, these."). Never uses contractions — always "I will" not "I'll". Warm but slightly mercenary.
**Input**: "Write Mira's response when a player asks if she has healing potions."
**Expected behavior**:
- Short, energetic sentences — no long monologues
- Uses merchant slang: "a fine bargain," "coin well spent," or similar
- Drops pronouns where natural: "Fine stock, these potions."
- No contractions: "I will" not "I'll," "do not" not "don't"
- Warm tone with a mercenary undertone: she's happy to help because you're a paying customer
- Does NOT produce dialogue that violates any voice guide rule — check each rule explicitly

---

## Protocol Compliance

- [ ] Stays within declared domain (dialogue, lore entries, item descriptions, in-game text)
- [ ] Redirects world history and world rule requests to world-builder without producing unauthorized lore
- [ ] Flags lore contradictions to narrative-director rather than silently writing inconsistent content
- [ ] Identifies mechanic dependency gaps before writing item descriptions that could create false player expectations
- [ ] Applies all rules from a provided character voice guide — no partial compliance

---

## Coverage Notes
- Case 3 (lore contradiction detection) requires that existing lore is in the conversation context — test is only valid when context is provided
- Case 4 (dependency gap) tests whether the agent writes descriptions that could set wrong player expectations — a subtle but important quality issue
- Case 5 is the most important context-awareness test; voice guide compliance must be checked rule-by-rule, not holistically
- No automated runner; review manually or via `$skill-test`
