# /architecture-review — Phase 2: Extract Technical Requirements

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 2: Extract Technical Requirements from Every GDD

### Pre-load the TR Registry

Before extracting any requirements, read `docs/architecture/tr-registry.yaml`
if it exists. Index existing entries by `id` and by normalized `requirement`
text (lowercase, trimmed). This prevents ID renumbering across review runs.

Then read the Technical Requirements Baseline in `docs/architecture/architecture.md`
if it exists. `/create-architecture` numbers each requirement the registry did not
hold as `(provisional)`, from the registry's next free ID, and ADRs written from
the baseline may already cite those IDs.

For each requirement you extract, the matching rule is:
1. **Exact/near match** to an existing registry entry for the same system →
   reuse that entry's TR-ID unchanged. Update the `requirement` text in the
   registry only if the GDD wording changed (same intent, clearer phrasing) —
   add a `revised: [date]` field.
2. **Match to a provisional baseline row** (same system, same intent) → keep that
   ID when the registry holds no entry with it, active or retired: registering it
   is what makes it permanent. When the ID is taken, assign the next available one
   and list the rename (`TR-[system]-004 (provisional) → TR-[system]-006`) in the
   report, so the ADRs and stories that cite it can be updated.
3. **No match** → assign a new ID: next available `TR-[system]-NNN` for that
   system, starting from the highest existing sequence + 1, skipping any ID a
   provisional baseline row holds.
4. **Ambiguous** (partial match, intent unclear) → ask the user:
   > "Does '[new requirement text]' refer to the same requirement as
   > `TR-[system]-NNN: [existing text]'`, or is it a new requirement?"
   User answers: "Same requirement" (reuse ID) or "New requirement" (new ID).

For any requirement with `status: deprecated` in the registry — skip it.
It was removed from the GDD intentionally.

For each GDD, read it and extract all **technical requirements** — things the
architecture must provide for the system to work. A technical requirement is any
statement that implies a specific architectural decision.

Categories to extract:

| Category | Example |
|----------|---------|
| **Data structures** | "Each entity has health, max health, status effects" → needs a component/data schema |
| **Performance constraints** | "Collision detection must run at 60fps with 200 entities" → physics budget ADR |
| **Engine capability** | "Inverse kinematics for character animation" → IK system ADR |
| **Cross-system communication** | "Damage system notifies UI and audio simultaneously" → event/signal architecture ADR |
| **State persistence** | "Player progress persists between sessions" → save system ADR |
| **Threading/timing** | "AI decisions happen off the main thread" → concurrency ADR |
| **Platform requirements** | "Supports keyboard, gamepad, touch" → input system ADR |

For each GDD, produce a structured list:

```
GDD: [filename]
System: [system name]
Technical Requirements:
  TR-[GDD]-001: [requirement text] → Domain: [Physics/Rendering/etc]
  TR-[GDD]-002: [requirement text] → Domain: [...]
```

This becomes the **requirements baseline** — the complete set of what the
architecture must cover.

---
