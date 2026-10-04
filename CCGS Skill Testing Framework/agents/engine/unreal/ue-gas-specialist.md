# Agent Test Spec: ue-gas-specialist

## Agent Summary
- **Domain**: Gameplay Ability System (GAS) — abilities (UGameplayAbility), gameplay effects (UGameplayEffect), attribute sets (UAttributeSet), gameplay tags, ability tasks (UAbilityTask), ability specs (FGameplayAbilitySpec), GAS prediction and latency compensation
- **Does NOT own**: UI display of ability state (ue-umg-specialist), net replication of GAS data beyond built-in GAS prediction (ue-replication-specialist), art or VFX for ability feedback (technical-artist)
- **Gate IDs**: None; defers cross-domain calls to the appropriate specialist

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references GAS, abilities, GameplayEffects, AttributeSets)
- [ ] `tools:` reads Read, Glob, Grep, Write, Edit, Bash — no `Agent` tool
- [ ] Model tier is `sonnet` — frontmatter `model:` reads exactly `sonnet` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over UI implementation or low-level net serialization

---

## Test Cases

### Case 1: In-domain request — dash ability with cooldown
**Input**: "Implement a dash ability that moves the player forward 500 units and has a 1.5 second cooldown."
**Expected behavior**:
- Produces a GAS AbilitySpec structure or outline: an ability deriving from the project's base ability class (not raw UGameplayAbility) with ActivateAbility logic, an AbilityTask for movement (e.g., AbilityTask_ApplyRootMotionMoveToForce or custom root motion), and a UGameplayEffect for the cooldown
- Cooldown GameplayEffect uses Duration policy with the 1.5s duration and a GameplayTag to block re-activation
- Tags clearly named following a hierarchy convention (e.g., Ability.Dash, Cooldown.Ability.Dash)
- Output includes both the ability class outline and the GameplayEffect definition

### Case 2: Mixed-domain request — cooldown replication feeding the UI
**Input**: "How do I replicate the player's ability cooldown state to all clients so the UI updates correctly?"
**Expected behavior**:
- Answers the replication half from GAS built-ins: the cooldown is a Duration Gameplay Effect granting a cooldown tag, replicated through the AbilitySystemComponent
- Explains the three ASC replication modes (Full, Mixed, Minimal) and which clients each one delivers cooldown state to
- Does NOT write custom replication (RepNotify properties or RPCs) for state GAS already replicates — effect-driven attribute changes replicate automatically and must not be double-replicated
- Hands the cooldown-indicator UI to ue-umg-specialist, and names ue-replication-specialist for multiplayer prediction concerns beyond the ASC's built-in handling

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
- Identifies the cause: two different Gameplay Effects both modify DefenseValue, and nothing bounds their combined result
- Resolves it with its own Attribute Set rules: DefenseValue gets a defined min/max, and `PreAttributeChange()` clamps the current value to that range — with `PreAttributeBaseChange()` or `PostGameplayEffectExecute()` for base-value changes from instant effects, as the pinned GAS reference's "Clamping Attributes" says — so no combination of effects can push it past the maximum
- Anything else it proposes (an Execution Calculation, changing how the two effects combine) comes on top of the clamp, not instead of it; it does not offer a stacking policy as the fix — stacking policies govern re-applications of the same effect, not two different effects — and it does not present an Override modifier as a cap
- Does NOT propose removing one of the abilities as the solution

### Case 5: Context pass — designing against an existing attribute set
**Input context**: Project has an existing AttributeSet with attributes: Health, MaxHealth, Stamina, MaxStamina, Defense, AttackPower.
**Input**: "Design a Berserker ability that increases AttackPower by 50% when Health drops below 30%."
**Expected behavior**:
- Uses the existing Health, MaxHealth, and AttackPower attributes — does NOT add an attribute without flagging it as a change to the existing AttributeSet and asking first
- Applies the +50% as an Infinite Gameplay Effect with a Modifier on AttackPower — never by writing AttackPower directly
- Reacts to Health changes (e.g. in `PostGameplayEffectExecute()` or an Ability Task waiting on an event) to apply the effect below 30% of MaxHealth and remove it above
- Documents the effect as its standards require: what it modifies, stacking behavior, duration, and removal condition
- Tracks the active state with a hierarchical Gameplay Tag (e.g. `Effect.Buff.Berserk`), not a boolean
- References the actual attribute names from the provided AttributeSet (AttackPower, not "Damage" or "Strength")

---

## Protocol Compliance

- [ ] Stays within declared domain (GAS: abilities, effects, attributes, tags, ability tasks)
- [ ] Keeps GAS state replication inside the ASC (no double-replication); routes ability UI to ue-umg-specialist and multiplayer prediction concerns to ue-replication-specialist
- [ ] Returns structured findings (ability outline + GameplayEffect definition) rather than vague descriptions
- [ ] Enforces tag hierarchy naming conventions proactively
- [ ] Uses only attributes and tags present in the provided context; flags any new one as a change to the existing set before adding it
- [ ] Asks "May I write this to [filepath]?" naming the file before writing

---

## Coverage Notes
- Case 3 (tag hierarchy) is a frequent source of subtle bugs; test whenever tag naming conventions change
- Case 4 tests the agent's own clamping rule (`PreAttributeChange()` against a defined min/max, and the base-value hooks for instant effects); stacking policies and Override modifiers do not cap two different effects, so they are accepted only as additions
- Case 5 is the most important context-awareness test; failing it means the agent ignores project state
- No automated runner; review manually or via `/skill-test`
