# Agent Coordination Rules

1. **Profile-based delegation**: Repository files in `roles/` are guidance
   profiles, not registered custom agent types. A parent may adopt a profile
   locally or inject it into a generic Codex sub-agent prompt.
2. **Vertical delegation**: For complex decisions, leadership profiles may
   coordinate department leads and specialists. Keep ownership and decision
   authority explicit in every delegation.
3. **Horizontal consultation**: Profiles at the same tier may consult each
   other but must not make binding decisions outside their domain.
4. **Conflict resolution**: Escalate unresolved design conflicts to the
   `creative-director` profile and technical conflicts to the
   `technical-director` profile, with both positions and evidence included.
5. **Change propagation**: When a change affects multiple domains, use the
   `producer` profile to coordinate the affected owners and follow-up work.
6. **Scoped writes**: Do not let delegated work modify files outside its stated
   ownership without explicit approval from the parent agent.

## Reasoning Guidance

Choose reasoning depth from task risk and breadth rather than a named model:

| Level | When to use |
|---|---|
| **Light** | Read-only status checks, formatting, simple lookups, and narrow deterministic audits |
| **Default** | Implementation, design authoring, and analysis of one system or a small set of related files |
| **Deep** | Cross-document synthesis, phase-gate verdicts, security-sensitive decisions, and high-impact architecture reviews |

Use the lowest level that can produce a reliable result. Increase depth when
uncertainty, blast radius, or the cost of a wrong decision is high.

## Generic Codex Sub-Agents

Use a generic Codex sub-agent when focused separation materially improves the
work. Repository role profiles do not create custom agent registrations.

Every delegation prompt must:

1. Tell the sub-agent which `roles/<name>.md` profile to read before acting.
2. Include the full task context needed for the assigned scope: objective,
   relevant paths, constraints, decisions already made, and expected output.
3. State file ownership and whether edits are allowed.
4. Require the sub-agent to preserve other agents' and users' existing edits.
5. Return blockers and evidence instead of silently skipping incomplete work.

Do not assume sub-agents inherit conversation context. They share repository
access, but the parent must pass the task context and relevant paths explicitly.

## Safe Parallelism

Run sub-agents in parallel only when their inputs and writes are independent.
Typical safe examples are separate read-only reviews or changes to disjoint
files. Run work serially when one result is needed by the next step, when agents
would edit the same file, or when a shared decision could invalidate later work.

When parallel work is appropriate:

1. Start all independent delegations before waiting for results.
2. Collect and reconcile every result before dependent work begins.
3. Surface any blocked or failed delegation immediately.
4. Produce a partial report when some independent work succeeds.
5. Resolve conflicting recommendations through the documented escalation path.
