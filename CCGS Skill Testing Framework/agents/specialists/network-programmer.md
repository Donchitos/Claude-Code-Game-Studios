# Agent Test Spec: network-programmer

## Agent Summary
Domain: Multiplayer networking, state replication, lag compensation, matchmaking protocol design, and network message schemas.
Does NOT own: gameplay logic (only the networking of it), server infrastructure and deployment (devops-engineer).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references multiplayer / replication / networking)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over gameplay logic or server deployment infrastructure

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Design state replication for player position in a 4-player co-op game."
**Expected behavior:**
- Produces a sync strategy document covering:
  - Replication frequency (e.g., 20Hz with delta compression)
  - Priority tier (e.g., own-player high priority, other players medium)
  - Interpolation approach for remote players (e.g., linear interpolation with 100ms buffer)
  - Bandwidth estimate per player per second
- Does NOT implement the player movement logic itself (defers to gameplay-programmer)
- Proposes dead-reckoning or prediction strategy to reduce visible lag

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Deploy our game server to AWS EC2 and set up auto-scaling."
**Expected behavior:**
- Does NOT produce server deployment configuration, Terraform, or AWS setup scripts
- Explicitly states that server infrastructure belongs to `devops-engineer`
- Redirects the request to `devops-engineer`
- May note it can provide the network protocol spec the server needs to implement once infrastructure is set up

### Case 3: State divergence — rollback/reconciliation
**Input:** "Under high latency, clients are diverging from the authoritative server state for physics objects."
**Expected behavior:**
- Proposes a rollback-and-reconciliation approach (client-side prediction + server authoritative correction)
- Specifies the state snapshot format, reconciliation trigger threshold (e.g., >5 units position error), and correction interpolation speed
- Notes the input buffer pattern for deterministic replay
- Does NOT change the physics simulation itself — documents the interface contract for engine-programmer

### Case 4: Anti-cheat conflict
**Input:** "We want client-authoritative position for smooth movement, but anti-cheat requires server validation."
**Expected behavior:**
- Surfaces the direct conflict: client-authority is fast but exploitable; server-authority is secure but requires latency compensation
- Coordinates with `security-engineer` to agree on the validation boundary
- Proposes a compromise (server validates position within a tolerance band, flags outliers) rather than unilaterally deciding
- Documents the trade-off and escalates the final decision to `technical-director` if security-engineer and network-programmer cannot agree

### Case 5: Context pass — latency budget
**Input:** Technical preferences provided in context: target latency 80ms RTT for 95th percentile players. Request: "Design the input replication scheme for a fighting game."
**Expected behavior:**
- References the 80ms RTT budget explicitly in the design
- Selects replication approach calibrated to that budget (e.g., rollback netcode is preferred for fighting games at this latency)
- Specifies input delay frames calculated from the 80ms budget (e.g., 2 frames at 60fps = 33ms buffer)
- Flags that rollback netcode requires gameplay-programmer to implement deterministic simulation

---

## Protocol Compliance

- [ ] Stays within declared domain (replication, lag compensation, protocol design, matchmaking)
- [ ] Redirects server deployment to devops-engineer
- [ ] Returns structured findings (sync strategies, protocol specs, bandwidth estimates)
- [ ] Does not implement gameplay logic — only specifies the network contract for it
- [ ] Coordinates with security-engineer on anti-cheat boundaries
- [ ] Designs to explicit latency targets from provided context

---

## Coverage Notes
- Replication strategy (Case 1) should include a bandwidth calculation reviewable by technical-director
- Rollback/reconciliation (Case 3) must document the engine-programmer interface contract clearly
- Anti-cheat conflict (Case 4) confirms the agent escalates rather than unilaterally deciding security trade-offs
