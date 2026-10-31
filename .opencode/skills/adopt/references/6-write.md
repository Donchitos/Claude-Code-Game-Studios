# /adopt — Phases 6 and 6b: Write the Adoption Plan and Report Review Mode

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 6: Write the Adoption Plan

**In this file:**

- Phase 6: the adoption plan template, then the write
- Phase 6b: Report Review Mode

If approved, write `docs/adoption-plan-[date].md` with this structure:

```markdown
# Adoption Plan

> **Generated**: [date]
> **Project phase**: [phase]
> **Engine**: [name + version, or "Not configured"]
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Step 1: Fix Blocking Gaps

[One sub-section per blocking gap with problem, fix command, time estimate, checkbox]

---

## Step 2: Fix High-Priority Gaps

[One sub-section per high gap]

---

## Step 3: Bootstrap Infrastructure

[At `workflow: minimal`, replace 3a–3d with one line: "Not on the minimal path —
the brief's build order is the plan. Next: `/create-stories` (or `/dev-story`
once stories exist)."]

### 3a. Register existing requirements (creates tr-registry.yaml)
Run `/architecture-review` — even if ADRs already exist, this run bootstraps
the TR registry from your existing GDDs and ADRs.
**Time**: 1 session (review can be long for large codebases)
- [ ] tr-registry.yaml created

### 3b. Create control manifest
Run `/create-control-manifest`
**Time**: 30 min
- [ ] docs/architecture/control-manifest.md created

### 3c. Create sprint tracking file
Run `/sprint-plan update`
**Time**: 5 min (if sprint plan already exists as markdown)
- [ ] production/sprint-status.yaml created

### 3d. Set authoritative project stage
Run `/gate-check [current-phase]` (the gate into the phase the project is in;
at Concept there is none — Concept is the default stage, nothing to run)
**Time**: 5 min
- [ ] `project.stage` in `project.yaml` written (legacy `production/stage.txt` also updated)

---

## Step 4: Medium-Priority Gaps

[One sub-section per medium gap]

---

## Step 5: Optional Improvements

[One sub-section per low gap]

---

## What to Expect from Existing Stories

Existing stories continue to work with all template skills. New format checks
(TR-ID validation, manifest version staleness) auto-pass when the fields are
absent — so nothing breaks. They won't benefit from staleness tracking until
regenerated. Do not regenerate stories that are in progress or done.

---

## Re-run

Run `/adopt` again after completing Step 3 to verify all blocking and high gaps
are resolved. The new run will reflect the current state of the project.
```

---

## Phase 6b: Report Review Mode

**Do not write a review mode.** `modes.review_mode` is one of the six knobs
`modes.rigor` fronts: pinning it in `project.yaml` shadows the rigor expansion, and
the legacy `production/review-mode.txt` sits *above* that expansion in resolution,
so either write would freeze director-review depth for good — the rule `/start`
and `project.yaml`'s header comment both state.

Report the value the bootstrap above resolved instead: "Review mode resolves to
`[value]` — from `modes.rigor`, unless something pins it." If the user wants a
different depth, point them to changing `modes.rigor`, or to pinning it on purpose
with `/settings --local modes.review_mode=<full|lean|solo>` (a personal override in
`project.local.yaml`).

---
