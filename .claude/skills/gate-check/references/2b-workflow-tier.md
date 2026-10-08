# /gate-check — Section 2b: Workflow Tier Adjustment

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 2b. Workflow Tier Adjustment

**In this file:**

- How to apply a gate file's tier reductions
- `qa.level` and the test items; the smoke check is the floor
- A gate with no required artifacts left is NOT ASSESSED, with one exception
- `performance.enforce`
- Per-system overrides (`workflow_overrides.system_overrides`), and the additive overrides

Each gate file carries its own tier reductions (see Section 2). Two rules apply
across all of them:

> **How to apply:** run the loaded gate's checklist, then apply that file's tier
> reduction for the tier resolved in Section 1. **drop** = not checked at this
> tier; **→ recommended** = absent surfaces as CONCERNS, never a Blocker; items
> not named keep their baseline status. Reductions only ever *relax* a
> requirement — the only thing that adds one is `workflow_overrides` (below).
>
> **`qa.level` (Section 1) further relaxes the test items independently of the
> tier:** at `qa.level: minimal` the test-evidence / unit-test items become
> non-required at every workflow tier (so even `workflow: full` does not require
> them); the Section 3 `testing.strict` check is then a no-op.
>
> **It relaxes tests, not the look.** A UI story's retained screenshots, and a
> Visual/Feel story's screenshots plus lead sign-off, are required at every
> `qa.level` wherever the gate file asks for story evidence
> (`.claude/docs/coding-standards.md`: tests are waived at `minimal`, the look
> is not).
>
> **The smoke check is excluded from that relaxation, and is the floor.**
> `qa.level` relaxes *per-story test evidence*; a smoke check is **build health**,
> not story evidence, and the two are already held apart on exactly this basis in
> `.claude/docs/coding-standards.md` ("`/smoke-check` is a build-health gate, not
> a per-story evidence gate ... This divergence is intentional"). So a gate file
> that requires a smoke report keeps requiring it at every `qa.level`.
>
> Without that exclusion the Production → Polish gate had **zero required
> artifacts at `rigor: minimal`** and could not fail on artifacts by
> construction: `minimal` reduced the gate to the smoke check alone, `qa.level`
> then dropped the smoke check too, and one `modes.rigor` setting fires both.

> **A gate with no required artifacts left must say so, and may not return
> PASS.** After applying the tier reduction and the `qa.level` relaxation, count
> what remains required. If the count is zero, report
> **NOT ASSESSED** naming both reducers and the gate — *"Production → Polish at
> `workflow: minimal` + `qa.level: minimal` leaves no required artifact; this
> gate verified nothing"* — rather than a PASS earned by having nothing to check.
> Per `.claude/rules/skill-authoring.md` obligation 1, a run that could not
> assess its scope has not established that the scope is good, and obligation 3
> requires the emptiness to be visible in the output rather than inferable from
> a silent green.
>
> **The one exception: a gate its tier reference file marks "not applicable" at
> this tier** (Systems Design → Technical Setup at `workflow: minimal`). That is
> not a gate with nothing left to check but a transition the tier does not have:
> it PASSes with that file's note, printed in the report. The director panel
> does not run for it — note "Director Panel skipped — gate not applicable at
> `workflow: [tier]`" — and the Section 6 stage write still asks first.
>
> **`performance.enforce` is likewise independent of the tier, and a tier
> reduction never suppresses it.** The performance check in Section 3 runs at
> every workflow tier, and `block` makes a breach a Blocker at every workflow
> tier. Do **not** read a gate file's *"everything else drops"* as dropping it:
> `off` is the only thing that makes budgets informational, and it is a
> deliberate choice the user makes on the same key.
>
> Without this, `performance.enforce: block` is **inert on every `rigor: minimal`
> project** — the Polish gate's `minimal` reduction drops everything outside its
> floor, and "Performance is within budget" sits in the dropped remainder. A
> setting that works only when a rule is disregarded is not wired.

### Per-system overrides (`workflow_overrides.system_overrides`)

Independent of the project-level tier above, and applied **only** on the gates
that validate MVP GDDs (Systems Design → Technical Setup, and the GDD-completeness
checks at Pre-Production → Production). For each system, resolve its effective
tier:

1. If the block's `system_overrides` lists `<system>` → that tier
2. Else the project-level `workflow`

**Before applying any of them, check the block the other way round: does every
KEY match a system?** `<system>` is the GDD filename stem
(`.claude/docs/workflow-modes.md`), so for each key in `system_overrides`, look
for `design/gdd/<key>.md`. Any key with no matching stem is reported, naming the
key and listing the stems that do exist:

> `system_overrides key 'no-such-system' matches no GDD in design/gdd/. Available stems: combat, inventory, forge-heat-system. This override is doing nothing.`

Surface it as a **CONCERNS**-level finding, not a Blocker — the project is still
gateable, but an override the user believes is in force and is not is exactly how
a documented escape hatch silently stops working.

This is the rule in `.claude/docs/workflow-modes.md`: a key that matches no
system is an error, not a no-op. The story skills resolve only in the system →
override direction, so an orphan key is invisible to them; `/gate-check`, which
resolves the whole block, is where it is caught.

Validate each GDD against its own effective tier's section count:

- A system pinned **higher** than the project (e.g. `system_overrides.combat:
  full` on a `standard` project) **blocks the gate** until that system's GDD
  meets the higher bar (combat → all 8 sections). This is the one case where a
  per-system setting makes the gate *stricter* than the project tier.
- A system pinned **lower** (e.g. `inventory: minimal`) relaxes only that system
  — its GDD is checked at the lower tier; every other system stays at the project
  level. A system pinned **`minimal` imposes no GDD section requirement at all**
  (`minimal` = "game brief replaces GDDs" — `.claude/docs/workflow-modes.md`): it
  never blocks the gate on a missing or incomplete GDD. Do not invent an
  "acceptance-criteria-only" floor for it — there is none.

> **Additive overrides (the only things that make the gate stricter).**
> - `workflow_overrides.art_bible_strict: true` forces the complete (9-section)
>   art bible at the Technical Setup → Pre-Production and Pre-Production →
>   Production gates regardless of tier or whether visual-asset stories exist.
> - `workflow_overrides.edge_cases: true` and `workflow_overrides.tuning_knobs:
>   true` force those GDD sections required when validating GDD completeness,
>   additive on top of the resolved tier (e.g. at `standard`, `tuning_knobs: true`
>   makes the otherwise-optional Tuning Knobs section blocking). These never
>   relax — a `false` value is the default/no-op, never a way to drop a section
>   the tier already requires.

---
