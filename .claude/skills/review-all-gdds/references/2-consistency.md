# /review-all-gdds — Phase 2: Cross-GDD Consistency

> Part of `/review-all-gdds`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 2: Cross-GDD Consistency

**In this file:**

- 2a: Dependency Bidirectionality
- 2b: Rule Contradictions
- 2c: Stale References
- 2d: Data and Tuning Knob Ownership Conflicts
- 2e: Formula Compatibility
- 2f: Acceptance Criteria Cross-Check

Work through every pair and group of GDDs to find contradictions and gaps.

### 2a: Dependency Bidirectionality

For every GDD's Dependencies section, check that every listed dependency is
reciprocal:
- If GDD-A lists "depends on GDD-B", check that GDD-B lists GDD-A as a dependent
- If GDD-A lists "depended on by GDD-C", check that GDD-C lists GDD-A as a dependency
- Flag any one-directional dependency as a consistency issue

```
⚠️  Dependency Asymmetry
[system-a].md lists: Depends On → [system-b].md
[system-b].md does NOT list [system-a].md as a dependent
→ One of these documents has a stale dependency section
```

### 2b: Rule Contradictions

For each game rule, mechanic, or constraint defined in any GDD, check whether
any other GDD defines a contradicting rule for the same situation:

Categories to scan:
- **Floor/ceiling rules**: Does any GDD define a minimum value for an output? Does any other say a different system can bypass that floor? These contradict.
- **Resource ownership**: If two GDDs both define how a shared resource accumulates or depletes, do they agree?
- **State transitions**: If GDD-A describes what happens when a character dies,
  does GDD-B's description of the same event agree?
- **Timing**: If GDD-A says "X happens on the same frame", does GDD-B assume
  it happens asynchronously?
- **Stacking rules**: If GDD-A says status effects stack, does GDD-B assume
  they don't?

```
🔴 Rule Contradiction
[system-a].md: "Minimum [output] after reduction is [floor_value]"
[system-b].md: "[mechanic] bypasses [system-a]'s rules and can reduce [output] to 0"
→ These rules directly contradict. Which GDD is authoritative?
```

### 2c: Stale References

**Start from the `## Cross-References` table where a GDD has one.** That table is
the document's own declaration of what it depends on — `templates/game-design-document.md`
tells authors it is machine-checked here, and `/design-system` requires it
whenever Dependencies names another GDD. For each row, confirm the `Target GDD`
exists and the `Specific Element Referenced` is still present in it under that
name, with the declared `Nature` still accurate.

A table that is absent, or still holding the template's bracketed examples, is
itself reportable: say the GDD declares no cross-references and that the prose
scan below was the only check applied. Do not treat an absent table as "no
dependencies" — it far more often means the section was never authored.

**Then scan the prose regardless**, table or no table: a declared table catches
what the author remembered, and the scan below catches what they did not.

For every cross-document reference (GDD-A mentions a mechanic, value, or
system name from GDD-B), verify the referenced element still exists in GDD-B
with the same name and behaviour:

- If GDD-A says "combo multiplier from the combat system feeds into score", check
  that the combat GDD actually defines a combo multiplier that outputs to score
- If GDD-A references "the progression curve defined in [system].md", check that
  [system].md actually has that curve, not a different progression model
- If GDD-A was written before GDD-B and assumed a mechanic that GDD-B later
  designed differently, flag GDD-A as containing a stale reference. Severity: a
  reference to a mechanic or formula that **does not exist** is **Blocking** — the
  architecture would inherit a rule nobody defined; one that exists but was
  designed differently is a **Warning**, unless the difference changes a rule the
  referencing GDD depends on (then Blocking)
- If the **target GDD is not written yet** (no file in `design/gdd/`): when
  `systems-index.md` lists that system (e.g. `Status: Not Started`), it is a
  **Warning** — a dependency on planned work, to re-check when that GDD is
  written; when neither a GDD nor a systems-index entry exists for it, it is
  **Blocking** — nothing will ever define it

```
🔴 Stale Reference
inventory.md (written first): "Item weight uses the encumbrance formula
  from movement.md"
movement.md (written later): Defines no encumbrance formula — uses a flat
  carry limit instead
→ inventory.md references a formula that doesn't exist — Blocking
```

### 2d: Data and Tuning Knob Ownership Conflicts

Two GDDs should not both claim to own the same data or tuning knob. Scan all
Tuning Knobs sections across all GDDs and flag duplicates:

```
⚠️  Ownership Conflict
[system-a].md Tuning Knobs: "[multiplier_name] — controls [output] scaling"
[system-b].md Tuning Knobs: "[multiplier_name] — scales [output] with [factor]"
→ Two GDDs define multipliers on the same output. Which owns the final value?
  This will produce either a double-application bug or a design conflict.
```

### 2e: Formula Compatibility

For GDDs whose formulas are connected (output of one feeds input of another),
check that the output range of the upstream formula is within the expected
input range of the downstream formula:

- If [system-a].md outputs values between [min]–[max], and [system-b].md is
  designed to receive values between [min2]–[max2], is the mismatch intentional?
- If an economy GDD expects resource acquisition in range X, and the
  progression GDD generates it at range Y, the economy will be trivial or
  inaccessible — is that intended?

Flag incompatibilities as CONCERNS (design judgment needed, not necessarily wrong):

```
⚠️  Formula Range Mismatch
[system-a].md: Max [output] = [value_a] (at max [condition])
[system-b].md: Base [input] = [value_b], max [input] = [value_c]
→ Late-[stage] [scenario] can resolve in a single [event].
  Is this intentional? If not, either [system-a]'s ceiling or [system-b]'s ceiling needs adjustment.
```

### 2f: Acceptance Criteria Cross-Check

Scan Acceptance Criteria sections across all GDDs for contradictions:

- GDD-A criteria: "Player cannot die from a single hit"
- GDD-B criteria: "Boss attack deals 150% of player max health"
These acceptance criteria cannot both pass simultaneously.

---
