# /architecture-decision — Steps 3a and 3b: Gather Context

> Part of `/architecture-decision`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 3. Gather context

### 3a: Architecture Registry Check (BLOCKING gate) — do this FIRST

Read `docs/registry/architecture.yaml`. Extract entries relevant to this ADR's
domain and decision (grep by system name, domain keyword, or state being touched).
Run this before reading any existing ADR — the registry exists specifically so a
new ADR's author does not need to open prior ADRs to learn their binding facts
(state ownership, interface contracts, forbidden patterns).

Present any relevant stances to the user **before** the collaborative design
begins, as locked constraints:

```
## Existing Architectural Stances (must not contradict)

State Ownership:
  player_health → owned by health-system (ADR-0001)
  Interface: HealthComponent.current_health (read-only float)
  → If this ADR reads or writes player health, it must use this interface.

Interface Contracts:
  damage_delivery → signal pattern (ADR-0003)
  Signal: damage_dealt(amount, target, is_crit)
  → If this ADR delivers or receives damage events, it must use this signal.

Forbidden Patterns:
  ✗ autoload_singleton_coupling (ADR-0001)
  ✗ direct_cross_system_state_write (ADR-0000)
  → The proposed approach must not use these patterns.
```

If the user's proposed decision would contradict any registered stance, surface
the conflict immediately:

> "⚠️ Conflict: This ADR proposes [X], but ADR-[NNNN] established that [Y] is
> the accepted pattern for this purpose. Proceeding without resolving this will
> produce contradictory ADRs and inconsistent stories.
> Options: (1) Align with the existing stance, (2) Supersede ADR-[NNNN] with
> an explicit replacement, (3) Explain why this case is an exception."

Do not proceed to Step 4 (collaborative design) until any conflict is resolved
or explicitly accepted as an intentional exception.

### 3b: Existing ADRs and Related GDDs — registry-scoped, never unbounded

The registry (3a) covers *what* prior decisions bind — not always *why*. If the
registry surfaced a directly relevant ADR and its reasoning matters here (not
just its stated facts), read that specific ADR — never glob-and-read every
ADR in `docs/architecture/` on the chance one is relevant:

1. **Map its headings first** (cheap):
   ```
   Grep pattern="^## " path="docs/architecture/[adr-file].md" output_mode="content" -n
   ```
2. **Under ~50KB** (`Bash: wc -c "docs/architecture/[adr-file].md"`) — one full
   `Read` is fine; per-call overhead exceeds the savings from bounded reads at
   this size.
3. **~50KB or larger** — bounded-read only `## Context`, `## Decision`, and
   `## Consequences` (the sections that carry reasoning, not just facts) via
   `Read(offset, limit)` from the heading map.

Read GDDs the same way `/design-system` Step 2b does: only GDDs the registry
or the ADR list names as directly relevant, and only their `## Dependencies`,
`## Formulas`, and `## Edge Cases` sections
(`Grep pattern="^## (Dependencies|Formulas|Edge Cases)" ... -A 40`) — never a
speculative full read of `design/gdd/*.md` looking for anything that might
relate.

Skip 3b entirely if the registry already answers everything this decision
needs — most ADRs will.

---
