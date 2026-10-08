# /gate-check — Sections 7 and 8: Next Step and Follow-Up

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 7. Closing Next-Step Widget

**In this file:**

- 7. Closing Next-Step Widget: per gate, and the `workflow: minimal` route
- 8. Follow-Up Actions

After the verdict is presented and any stage update is complete (project.yaml + stage.txt), close with a structured next-step prompt using `AskUserQuestion`.

**Tailor the options to the gate that just ran.** The argument names the phase
being entered, so `/gate-check systems-design` is the Concept → Systems Design gate.

**At `workflow: minimal`, skip the menus below.** They walk the phase ladder, and
the minimal route is not the ladder: offer the first incomplete step of
`paths.minimal` instead (the `--path minimal` rows from Section 3):
`/setup-engine`, then `/brainstorm`, then `/create-stories`, then `/dev-story`
on the next story — the route `/help` gives.

For **Concept → Systems Design** (`/gate-check systems-design`) PASS — option [A] is
`/map-systems` when `design/gdd/systems-index.md` does not exist yet (many
projects write it during Concept, as the workflow catalog orders it), otherwise
`/design-system [first system in the index's design order]`:
```
Gate passed. What would you like to do next?
[A] Run /map-systems — decompose the concept into systems and a design order (recommended next step)
    — or, when the systems index already exists: Run /design-system [first system] — author its GDD
[B] Revisit the concept first — return here when it is settled
[C] Stop here for this session
```

For **Systems Design → Technical Setup** (`/gate-check technical-setup`) PASS:
```
Gate passed. What would you like to do next?
[A] Run /create-architecture — produce your master architecture blueprint and ADR work plan (recommended next step)
[B] Design more GDDs first — return here when all MVP systems are complete
[C] Stop here for this session
```

> **Note for the Systems Design → Technical Setup PASS**: `/create-architecture` is the required next step before writing any ADRs. It produces the master architecture document and a prioritized list of ADRs to write. Running `/architecture-decision` without this step means writing ADRs without a blueprint — skip it at your own risk.

For **Technical Setup → Pre-Production** (`/gate-check pre-production`) PASS:
```
Gate passed. What would you like to do next?
[A] Run /create-control-manifest — generate the layer rules manifest from your Accepted ADRs (first, if docs/architecture/control-manifest.md does not exist yet)
[B] Run /vertical-slice — build the Vertical Slice (do this before writing epics — validate fun first)
[C] Write more ADRs first — run /architecture-decision [next-system]
[D] Stop here for this session
```

> **Note for the Technical Setup → Pre-Production PASS**: The Pre-Production sequence is deliberately ordered
> to validate fun before committing to detailed planning:
>
> 1. `/create-control-manifest` — extract technical rules from Accepted ADRs, if not done yet (`/create-epics` requires it at `full`)
> 2. `/vertical-slice` — build the Vertical Slice **FIRST**, before writing epics or stories
> 3. Playtest → `/playtest-report` — at least 1 documented session, 3+ better before committing the full team. `/gate-check production` treats the slice as recommended: skipped → CONCERNS, unplayed → NOT ASSESSED
> 4. `/ux-design [screen]` — UX specs for main menu, core HUD, pause menu (if not done)
> 5. `/create-epics layer:foundation` then `/create-epics layer:core` — plan after fun is validated
> 6. `/create-stories [epic-slug]` for each epic
> 7. `/sprint-plan new`
>
> **Why prototype before epics?** If the prototype reveals the core loop needs to change,
> epics written before that discovery will be partially wrong. Validate fun cheaply first,
> then plan in detail. This is the #1 lesson from GDC postmortem data.

For all other gates, offer the two most logical next steps for that phase plus "Stop here".

---

## 8. Follow-Up Actions

Based on the verdict, suggest specific next steps:

- **No art bible?** → `/art-bible` to create the visual identity specification
- **Art bible exists but no asset specs?** → `/asset-spec system:[name]` to generate per-asset visual specs and generation prompts from approved GDDs
- **No game concept?** → `/brainstorm` to create one
- **No systems index?** → `/map-systems` to decompose the concept into systems
- **Missing design docs?** → `/reverse-document` or delegate to `game-designer`
- **Small design change needed?** → `/quick-design` for changes under about one week of implementation (bypasses full GDD pipeline)
- **No UX specs?** → `/ux-design [screen name]` to author specs, or `/team-ui [feature]` for full pipeline
- **UX specs not reviewed?** → `/ux-review [file]` or `/ux-review all` to validate
- **No accessibility requirements doc?** → run `/ux-design` which creates both `design/accessibility-requirements.md` and `design/ux/interaction-patterns.md` in one step
- **No interaction pattern library?** → `/ux-design patterns` to initialize it
- **Concept or a GDD not reviewed?** → `/design-review [doc]`
- **GDDs not cross-reviewed?** → `/review-all-gdds` (run after all MVP GDDs are individually approved)
- **Cross-GDD consistency issues?** → fix flagged GDDs, then re-run `/review-all-gdds`
- **No test framework?** → `/test-setup` to scaffold the framework for your engine
- **No QA plan for current sprint?** → `/qa-plan sprint` to generate one before implementation begins
- **Missing ADRs?** → `/architecture-decision` for individual decisions
- **No master architecture doc?** → `/create-architecture` for the full blueprint
- **ADRs missing engine compatibility sections?** → Re-run `/architecture-decision`
  or manually add Engine Compatibility sections to existing ADRs
- **Missing control manifest?** → `/create-control-manifest` (requires Accepted ADRs)
- **Missing epics?** → `/create-epics layer: foundation` then `/create-epics layer: core` (requires control manifest)
- **Missing stories for an epic?** → `/create-stories [epic-slug]` (run after each epic is created)
- **Stories not implementation-ready?** → `/story-readiness` to validate stories before developers pick them up
- **Tests failing?** → delegate to `lead-programmer` or `qa-tester`
- **No playtest data?** → `/playtest-report`
- **No playtest sessions beyond the minimum?** → Additional sessions give more reliable signal. 3+ total is recommended before committing the full team. Use `/playtest-report` to structure findings.
- **No Difficulty Curve doc?** → Author `design/difficulty-curve.md` by hand from the template at `.claude/docs/templates/difficulty-curve.md`. (`/quick-design` is a related session but writes to `design/quick-specs/`, not to this path — use it to think the curve through, then copy the outcome here.)
- **No player journey map?** → Author `design/player-journey.md` by hand from the template at `.claude/docs/templates/player-journey.md`.

> **Neither of these has a skill that writes it — the remediations must not imply
> otherwise.** Naming "`/ux-design` Phase 2b" would point at the step that *reads*
> `design/player-journey.md`, landing the user back at the check that just
> failed. Naming `/quick-design` would point at a skill that writes
> `design/quick-specs/[name]-[date].md` and would leave this gate still failing.
> Both docs are hand-authored from their templates; say so plainly rather than
> naming a skill that cannot produce them.
- **Need a quick sprint check?** → `/sprint-status` for current sprint progress snapshot
- **Performance unknown?** → `/perf-profile`
- **Not localized?** → `/localize`
- **No security audit, or open CRITICAL/HIGH findings?** → `/security-audit` (after fixes, `/security-audit quick` to confirm)
- **Ready for release?** → `/launch-checklist`

---
