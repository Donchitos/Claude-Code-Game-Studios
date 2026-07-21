# Agent Test Spec: ue-gas-specialist

## Agent Summary
- **Domain**: Gameplay Ability System (GAS) — abilities (UGameplayAbility), gameplay effects (UGameplayEffect), attribute sets (UAttributeSet), gameplay tags, ability tasks (UAbilityTask), ability specs (FGameplayAbilitySpec), GAS prediction and latency compensation
- **Does NOT own**: UI display of ability state (ue-umg-specialist), net replication of GAS data beyond built-in GAS prediction (ue-replication-specialist), art or VFX for ability feedback (vfx-artist)
No fixed model routing is required; the caller selects the available Codex model.
- **Gate IDs**: None; defers cross-domain calls to the appropriate specialist

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references GAS, abilities, GameplayEffects, AttributeSets)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over UI implementation or low-level net serialization

---

## Test Cases

### Case 1: In-domain request — dash ability with cooldown
**Input**: "Implement a dash ability that moves the player forward 500 units and has a 1.5 second cooldown."
**Expected behavior**:
- Produces a GAS AbilitySpec structure or outline: UGameplayAbility subclass with ActivateAbility logic, an AbilityTask for movement (e.g., AbilityTask_ApplyRootMotionMoveToForce or custom root motion), and a UGameplayEffect for the cooldown
- Cooldown GameplayEffect uses Duration policy with the 1.5s duration and a GameplayTag to block re-activation
- Tags clearly named following a hierarchy convention (e.g., Ability.Dash, Cooldown.Ability.Dash)
- Output includes both the ability class outline and the GameplayEffect definition

### Case 2: Out-of-domain request — GAS state replication
**Input**: "How do I replicate the player's ability cooldown state to all clients so the UI updates correctly?"
**Expected behavior**:
- Clarifies that GAS has built-in replication for AbilitySpecs and GameplayEffects via the AbilitySystemComponent's replication mode
- Explains the three ASC replication modes (Full, Mixed, Minimal) and when to use each
- For custom replication needs beyond GAS built-ins, explicitly states: "For custom net serialization of GAS data, coordinate with ue-replication-specialist"
- Does NOT attempt to write custom replication code outside GAS's own systems without flagging the domain boundary

### Case 3: Domain boundary — incorrect GameplayTag hierarchy
**Input**: "We have an ability that applies a tag called 'Stunned' and another that checks for 'Status.Stunned'. They're not matching."
**Expected behavior**:
- Identifies the root cause: tag names must be exact or use hierarchical matching via TagContainer queries
- Flags the naming inconsistency: 'Stunned' is a root-level tag; 'Status.Stunned' is a child tag under 'Status' — these are different tags
- Recommends a project tag naming convention: all status effects under Status.*, all abilities under Ability.*
- Provides the fix: either rename the applied tag to 'Status.Stunned' or update the query to match 'Stunned'
- Notes where tag definitions should live (DefaultGameplayTags.ini or a DataTable)

### Case 4: Conflict — attribute set conflict between two abilities
**Input**: "Our Shield ability and our Armor ability both modify a 'DefenseValue' attribute. They're stacking in ways that aren't intended — after both are active, defense goes well above maximum."
**Expected behavior**:
- Identifies this as a GameplayEffect stacking and magnitude calculation problem
- Proposes a resolution using Execution Calculations (UGameplayEffectExecutionCalculation) or Modifier Aggregators to cap the combined result
- Alternatively recommends using Gameplay Effect Stacking policies (Aggregate, None) to prevent unintended additive stacking
- Produces a concrete resolution: either an Execution Calculation class outline or a change to the Modifier Op (Override instead of Additive for the cap)
- Does NOT propose removing one of the abilities as the solution

### Case 5: Context pass — designing against an existing attribute set
**Input context**: Project has an existing AttributeSet with attributes: Health, MaxHealth, Stamina, MaxStamina, Defense, AttackPower.
**Input**: "Design a Berserker ability that increases AttackPower by 50% when Health drops below 30%."
**Expected behavior**:
- Uses the existing Health, MaxHealth, and AttackPower attributes — does NOT invent new attributes
- Designs a Passive GameplayAbility (or triggered Effect) that fires on Health change, checks Health/MaxHealth ratio via a GameplayEffectExecutionCalculation or Attribute-Based magnitude
- Uses a Gameplay Cue or Gameplay Tag to track the Berserker active state
- References the actual attribute names from the provided AttributeSet (AttackPower, not "Damage" or "Strength")

---

## Protocol Compliance

- [ ] Stays within declared domain (GAS: abilities, effects, attributes, tags, ability tasks)
- [ ] Redirects custom replication requests to ue-replication-specialist with clear explanation of boundary
- [ ] Returns structured findings (ability outline + GameplayEffect definition) rather than vague descriptions
- [ ] Enforces tag hierarchy naming conventions proactively
- [ ] Uses only attributes and tags present in the provided context; does not invent new ones without noting it

---

## Coverage Notes
- Case 3 (tag hierarchy) is a frequent source of subtle bugs; test whenever tag naming conventions change
- Case 4 requires knowledge of GAS stacking policies — verify this case if the GAS integration depth changes
- Case 5 is the most important context-awareness test; failing it means the agent ignores project state
- No automated runner; review manually or via `$skill-test`
