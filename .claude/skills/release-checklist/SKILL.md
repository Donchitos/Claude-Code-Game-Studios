---
name: release-checklist
description: "Pre-release checklist — build verification, certification requirements, store metadata, launch readiness."
argument-hint: "[platform: pc|console|mobile|all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/release-checklist/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys rigor,project.stage,cert_tier,automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Scope this checklist to the project.** Emitting every item for every platform
trains the reader to skip the list, which defeats the gate:

- **`project.stage`** — items for phases this project has not reached are out of
  scope; say so rather than listing them unchecked.
- **`modes.rigor`** — at `minimal`, drop items whose only justification is process
  weight this project has opted out of.
- **`platform.cert_tier`** — emit certification items **only** for the tier the
  project targets. If it is **unset**, **ask which platforms are in scope**
  rather than emitting all of them — an unset value is a question, not a licence
  to emit every certification track. If it cannot be determined, mark the section
  **`NOT ASSESSED — cert tier unknown`**. **Unset is not `none`:** `none` is a
  decision, unset is a missing one, and they must not produce the same output.
  Branch on the **four values this key takes** — `none | itch | steam | console` —
  and not on platform names; `.claude/docs/effects-map.md` holds the full
  requirement table and is the source, so read it rather than restating it.
  - `none` — **emit no certification section at all.** Internal release, alpha or
    jam game. Say the section was omitted and why; do not leave it blank.
  - `itch` — itch.io upload requirements only: build size, page setup, age tags.
    **No console and no Steamworks items.**
  - `steam` — Steamworks: store page, depot build, achievements, system
    requirements, common content rules. **No console certification items.**
  - `console` — full platform certification (TRC / XR / Lotcheck), save-data
    rules, controller-mapping rules, age-rating boards. The heaviest tier.

  > **Branch on the `cert_tier` values above, not on platform names.** "Emit
  > console/mobile certification items only for the platforms the project targets"
  > is the wrong test: it treats an `itch` project and a `steam` project
  > identically, conflates `none` with unset, and keys on `mobile`, which is not a
  > `cert_tier` value at all. Use the vocabulary the config defines.

If an item cannot be scoped because the config is absent, mark it
**`NOT ASSESSED — platform/stage unknown`**. Do not silently include it: a
`rigor: standard`, single-platform project would otherwise receive a ~150-item
checklist demanding PC **and** console **and** mobile certification plus age
ratings, of which ~140 are unassessable.

---


> **Explicit invocation only**: This skill should only run when the user explicitly requests it with `/release-checklist`. Do not auto-invoke based on context matching.

## Phase 1: Parse Arguments

Read the argument for the target platform (`pc`, `console`, `mobile`, or `all`). If no platform is specified, default to `all`.

**The argument selects DEVICE requirements. It never selects the certification
track.** Certification is decided by `platform.cert_tier`, resolved in the resolved-config block at the top of this skill —
see the `platform.cert_tier` rule above. The two axes are different lists that
happen to share one word: `pc`/`console`/`mobile` are hardware shapes, while
`none|itch|steam|console` are certification regimes. They agree on `console` and
nowhere else — `itch` and `none` have no device block at all, and `mobile` is not
a `cert_tier` value. So emitting a device block says nothing about which
certification block to emit, and `all` is **not** a licence to emit every
certification track.

---

## Phase 2: Load Project Context

- Read `CLAUDE.md` for project context, version information, and platform targets.
- Read the current milestone from `production/milestones/` to understand what features and content should be included in this release.

---

## Phase 3: Scan Codebase

> **State the denominator with every count.** These scans look for something bad,
> so `0` means either "searched and found none" or "there was nothing to search",
> and on a release gate those are opposite findings. Report
> `scanned [N] source files: [M] TODO, [M] FIXME, [M] HACK` — or, when `src/` is
> absent or holds no source files,
> **`NOT ASSESSED — no source files found to scan`**. A bare `0` is not a result.
>
> `/launch-checklist` scans the same way and is most often run beside this one.
> Keep the two consistent: changing the rule in one and not the other leaves a
> route to the same misleading `0`.

Scan for outstanding issues:

- Count `TODO` comments
- Count `FIXME` comments
- Count `HACK` comments
- Note their locations and severity

Check for test results in any test output directories or CI logs if available.
**If none are found, say so** — `Test results: NOT ASSESSED — no test output or
CI logs found` — rather than omitting the line. An absent test result and a
passing one must not produce the same release checklist.

---

## Phase 4: Generate the Release Checklist

```markdown
## Release Checklist: [Version] -- [Platform]
Generated: [Date]

### Codebase Health
- TODO count: [N] ([list top 5 if many])
- FIXME count: [N] ([list all -- these are potential blockers])
- HACK count: [N] ([list all -- these need review])

### Build Verification
- [ ] Clean build succeeds on all target platforms
- [ ] No compiler warnings (zero-warning policy)
- [ ] All assets included and loading correctly
- [ ] Build size within budget ([target size])
- [ ] Build version number correctly set ([version])
- [ ] Build is reproducible from tagged commit

### Quality Gates
- [ ] Zero S1 (Critical) bugs
- [ ] Zero S2 (Major) bugs -- or documented exceptions with producer approval
- [ ] All critical path features tested and signed off by QA
- [ ] Performance within budgets:
  - [ ] Target FPS met on minimum spec hardware
  - [ ] Memory usage within budget
  - [ ] Load times within budget
  - [ ] No memory leaks over extended play sessions
- [ ] No regression from previous build
- [ ] Soak test passed (4+ hours continuous play)

### Content Complete
- [ ] All placeholder assets replaced with final versions
- [ ] All TODO/FIXME in content files resolved or documented
- [ ] All player-facing text proofread
- [ ] All text localization-ready (no hardcoded strings)
- [ ] Audio mix finalized and approved
- [ ] Credits complete and accurate
```

Add **device** sections based on the argument. These carry no certification or
storefront-SDK items — those are gated on `platform.cert_tier` in the next
subsection, and duplicating them here is what let an `itch` project receive
Steamworks rows.

**For `pc`:**
```markdown
### Platform Requirements: PC
- [ ] Minimum and recommended specs verified and documented
- [ ] Keyboard+mouse controls fully functional
- [ ] Controller support tested (Xbox, PlayStation, generic)
- [ ] Resolution scaling tested (1080p, 1440p, 4K, ultrawide)
- [ ] Windowed, borderless, and fullscreen modes working
- [ ] Graphics settings save and load correctly
```

**For `console`:**
```markdown
### Platform Requirements: Console
- [ ] Platform-specific controller prompts display correctly
- [ ] Suspend/resume works correctly
- [ ] User switching handled properly
- [ ] Network connectivity loss handled gracefully
- [ ] Storage full scenario handled
```

**For `mobile`:**
```markdown
### Platform Requirements: Mobile
- [ ] App store guidelines compliance verified
- [ ] All required device permissions justified and documented
- [ ] Privacy policy linked and accurate
- [ ] Data safety/nutrition labels completed
- [ ] Touch controls tested on multiple screen sizes
- [ ] Battery usage within acceptable range
- [ ] Background behavior correct (pause, resume, terminate)
- [ ] Push notification permissions handled correctly
- [ ] In-app purchase flow tested (if applicable)
- [ ] App size within store limits
```

> **Mobile storefront rows stay here on purpose.** `platform.cert_tier` models
> `none|itch|steam|console` and has no mobile regime, so App Store / Play Store
> compliance cannot be gated on it. Leaving these in the device block is a
> deliberate choice, not an oversight — do not "fix" it by inventing a `mobile`
> tier, which is the exact wrong vocabulary the `cert_tier` rule warns against.

**Certification — emit ONLY the block matching `platform.cert_tier`** (resolved in
the resolved-config block at the top of this skill). Do not emit this subsection's other blocks, and do not fall back to
emitting all of them because the platform argument was `all`.

**At `none`** — emit no certification block at all. Emit exactly this one line in
its place, so the omission is visible rather than looking like a missing section:
```markdown
Certification: omitted — cert_tier is 'none' (internal build, alpha or jam release).
```

**At `itch`:**
```markdown
### Certification: itch.io
- [ ] Build size within itch.io upload limits
- [ ] itch.io page complete (cover art, screenshots, description)
- [ ] Age/content tags set honestly
- [ ] Downloadable vs browser build decided and tested
- [ ] Butler channel names correct for each platform uploaded
```

**At `steam`:**
```markdown
### Certification: Steamworks
- [ ] Steamworks SDK integrated and tested
- [ ] Depot build uploaded and installs cleanly from a fresh account
- [ ] Achievements functional
- [ ] Cloud saves functional
- [ ] Steam Deck compatibility verified (if targeting)
- [ ] Steam common content rules reviewed
```

**At `console`:**
```markdown
### Certification: Console
- [ ] TRC/TCR/Lotcheck requirements checklist complete
- [ ] First-party certification submission prepared
- [ ] Platform-specific achievement/trophy integration tested
- [ ] Parental controls respected
- [ ] Save-data rules compliant (corruption, full storage, user switching)
- [ ] Age ratings obtained (ESRB, PEGI, regional)
```

If `cert_tier` is **unset**, ask which platforms are in scope rather than
emitting every track; if it cannot be determined, emit
`### Certification: NOT ASSESSED — cert tier unknown` and say why. **Unset is not
`none`** — `none` is a decision and unset is a missing one.

> **Certification rows belong here, in one `cert_tier`-gated subsection.** Do not
> spread them back through the PC, Console and Mobile device blocks: those are
> selected by the command argument and default to `all`, so an `itch` project
> running `/release-checklist` with no argument would be handed the Steamworks SDK
> rows *and* the Lotcheck rows — exactly what the `cert_tier` rule at the top of
> this skill forbids.
>
> **`console` means two different things in this file.** It is a device-block
> argument value *and* a `cert_tier` value, colliding on one word out of four. A
> `**For \`console\`:**` heading is argument-gating, not tier-gating — do not read
> it as evidence that certification is already scoped by tier.

**Store and launch sections (all platforms):**
```markdown
### Store / Distribution
- [ ] Store page metadata complete and proofread
  - [ ] Short description
  - [ ] Long description
  - [ ] Feature list
  - [ ] System requirements (PC)
- [ ] Screenshots up to date and per-platform resolution requirements met
- [ ] Trailers up to date
- [ ] Key art and capsule images current
- [ ] Age rating obtained and configured:
  - [ ] ESRB
  - [ ] PEGI
  - [ ] Other regional ratings as required
- [ ] Legal notices, EULA, and privacy policy in place
- [ ] Third-party license attributions complete
- [ ] Pricing configured for all regions

### Launch Readiness
- [ ] Analytics / telemetry verified and receiving data
- [ ] Crash reporting configured and dashboard accessible
- [ ] Day-one patch prepared and tested (if needed)
- [ ] On-call team schedule set for first 72 hours
- [ ] Community launch announcements drafted
- [ ] Press/influencer keys prepared for distribution
- [ ] Support team briefed on known issues and FAQ
- [ ] Rollback plan documented (if critical issues found post-launch)

### Go / No-Go: [READY / NOT READY]

**Rationale:**
[Summary of readiness assessment. List any blocking items that must be
resolved before launch. If NOT READY, list the specific items that need
resolution and estimated time to address them.]

**Sign-offs Required:**
- [ ] QA Lead
- [ ] Technical Director
- [ ] Producer
- [ ] Creative Director
```

---

## Phase 5: Save Checklist

Present the checklist to the user with: total checklist items, number of known blockers (FIXME/HACK counts, known bugs).

Ask: "May I write this to `production/releases/release-checklist-[version].md`?"

If yes, write the file, creating the directory if needed.

---

## Phase 6: Next Steps

- Run `/gate-check` for a formal phase gate verdict before proceeding to release.
- Coordinate final sign-offs via `/team-release`.
