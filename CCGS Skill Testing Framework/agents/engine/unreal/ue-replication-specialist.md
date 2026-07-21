# Agent Test Spec: ue-replication-specialist

## Agent Summary
- **Domain**: Property replication (UPROPERTY Replicated/ReplicatedUsing), RPCs (Server/Client/NetMulticast), client prediction and reconciliation, net relevancy and always-relevant settings, net serialization (FArchive/NetSerialize), bandwidth optimization and replication frequency tuning
- **Does NOT own**: Gameplay logic being replicated (gameplay-programmer), server infrastructure and hosting (devops-engineer), GAS-specific prediction (ue-gas-specialist handles GAS net prediction)
No fixed model routing is required; the caller selects the available Codex model.
- **Gate IDs**: None; escalates security-relevant replication concerns to lead-programmer

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references replication, RPCs, client prediction, bandwidth)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over server infrastructure, game server architecture, or gameplay logic correctness

---

## Test Cases

### Case 1: In-domain request — replicated player health with client prediction
**Input**: "Set up replicated player health that clients can predict locally (e.g., when taking self-inflicted damage) and have corrected by the server."
**Expected behavior**:
- Produces a UPROPERTY(ReplicatedUsing=OnRep_Health) declaration in the appropriate Character or AttributeSet class
- Describes the OnRep_Health function: apply visual/audio feedback, reconcile predicted value with server-authoritative value
- Explains the client prediction pattern: local client applies tentative damage immediately, server authoritative value arrives via OnRep and corrects any discrepancy
- Notes that if GAS is in use, the built-in GAS prediction handles this — recommend coordinating with ue-gas-specialist
- Output is a concrete code structure (property declaration + OnRep outline), not a conceptual description only

### Case 2: Out-of-domain request — game server architecture
**Input**: "Design our game server infrastructure — how many dedicated servers we need, regional deployment, and matchmaking architecture."
**Expected behavior**:
- Does not produce server infrastructure architecture, hosting recommendations, or matchmaking design
- States clearly: "Server infrastructure and deployment architecture is owned by devops-engineer; I handle the Unreal replication layer within a running game session"
- Does not conflate in-game replication with server hosting concerns

### Case 3: Domain boundary — RPC without server authority validation
**Input**: "We have a Server RPC called ServerSpendCurrency that deducts in-game currency. The client calls it and the server just deducts without checking anything."
**Expected behavior**:
- Flags this as a critical security vulnerability: unvalidated server RPCs are exploitable by cheaters sending arbitrary RPC calls
- Provides the required fix: server-side validation before the deduct — check that the player actually has the currency, verify the transaction is valid, reject and log if not
- Uses the pattern: `if (!HasAuthority()) return;` guard plus explicit state validation before mutation
- Notes this should be reviewed by lead-programmer given the economy implications
- Does NOT produce the "fixed" code without explaining why the original was dangerous

### Case 4: Bandwidth optimization — high-frequency movement replication
**Input**: "Our player movement is replicated using a Vector3 position every tick. With 32 players, we're exceeding our bandwidth budget."
**Expected behavior**:
- Identifies tick-rate replication of full-precision Vector3 as bandwidth-expensive
- Proposes quantized replication: use FVector_NetQuantize or FVector_NetQuantize100 instead of raw FVector to reduce bytes per update
- Recommends reducing replication frequency via SetNetUpdateFrequency() for non-owning clients
- Notes that Unreal's built-in Character Movement Component already has optimized movement replication — recommends using or extending it rather than rolling a custom system
- Produces a concrete bandwidth estimate comparison if possible, or explains the tradeoff

### Case 5: Context pass — designing within a network budget
**Input context**: Project network budget is 64 KB/s per player, with 32 players = 2 MB/s total server outbound. Current movement replication already uses 40 KB/s per player.
**Input**: "We want to add real-time inventory replication so all clients can see other players' equipment changes immediately."
**Expected behavior**:
- Acknowledges the existing 40 KB/s movement cost leaves only 24 KB/s for everything else per player
- Does NOT design a naive full-inventory replication approach (would exceed budget)
- Recommends a delta-only or event-driven approach: replicate only changed slots rather than the full inventory array
- Uses FGameplayItemSlot or equivalent with ReplicatedUsing to trigger targeted updates
- Explicitly states the proposed approach's bandwidth estimate relative to the remaining 24 KB/s budget

---

## Protocol Compliance

- [ ] Stays within declared domain (property replication, RPCs, client prediction, bandwidth)
- [ ] Redirects server infrastructure requests to devops-engineer without producing infrastructure design
- [ ] Flags unvalidated server RPCs as security issues and recommends lead-programmer review
- [ ] Returns structured findings (property declarations, bandwidth estimates, optimization options) not freeform advice
- [ ] Uses project-provided bandwidth budget numbers when evaluating replication design choices

---

## Coverage Notes
- Case 3 (RPC security) is a shipping-critical test — unvalidated RPCs are a top-ten multiplayer exploit vector
- Case 5 is the most important context-awareness test; agent must use actual budget numbers, not generic advice
- Case 1 GAS branch: if GAS is configured, agent should detect it and defer to ue-gas-specialist for GAS-managed attributes
- No automated runner; review manually or via `$skill-test`
