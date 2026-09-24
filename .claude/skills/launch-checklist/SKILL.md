---
name: launch-checklist
description: "Launch readiness across every department: code, content, store, marketing, community, infrastructure, legal, go/no-go sign-offs."
argument-hint: "[launch-date or 'dry-run']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/launch-checklist/../../hooks/yaml-helper.sh" resolve_config *)
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


> **Explicit invocation only**: This skill should only run when the user explicitly requests it with `/launch-checklist`. Do not auto-invoke based on context matching.

## Phase 1: Parse Arguments

Read the argument for the launch date or `dry-run` mode. Dry-run mode generates the checklist without creating sign-off entries or writing files.

---

## Phase 2: Gather Project Context

- Read `CLAUDE.md` for tech stack, target platforms, and team structure
- Read the latest milestone in `production/milestones/`
- Read any existing release checklist in `production/releases/`
- Read the content calendar in `design/live-ops/content-calendar.md` if it exists

---

## Phase 3: Scan Codebase Health

> **Every scan in this phase is a search for something bad, so a zero-hit result
> is ambiguous by construction: it means either "searched and found none" or
> "there was nothing to search". On a launch gate those are opposite findings,
> and a green checkbox renders them identically.**
>
> **Establish the denominator before every scan below, and report it.** Each line
> reads either `scanned [N] files, [M] hits` or
> `NOT ASSESSED — [no src/ | no assets/ | directory empty]`. Never a bare tick.
>
> This is written once, over the whole phase, rather than under **one** of the
> four bullets. All four search `src/` the same way — for placeholder assets,
> TODOs, debug output and hardcoded test values — so if only one carries the
> warning, an empty or absent `src/` returns zero
> hits three times and read as three clean results. The original
> instance shipped: with no `assets/` directory the scan returned zero hits and
> "All placeholder art replaced" was ticked green.

- Count `TODO`, `FIXME`, `HACK` comments and their locations
- Check for any `console.log`, `print()`, or debug output left in production code
- Check for placeholder assets (search for `placeholder`, `temp_`, `WIP_`)
- Check for hardcoded test/dev values (localhost, test credentials, debug flags)

**Carry the distinction into the checklist itself.** An item whose scan returned
`NOT ASSESSED` is written `- [?]`, not `- [ ]`. An unticked box says *work
remains*; a `[?]` says *nobody could check*, and only one of those is closed by
doing the work. Include the legend wherever a `[?]` appears:
`[?] = not assessed — the input to this check was absent`.

---

## Phase 4: Generate the Launch Checklist

```markdown
# Launch Checklist: [Game Title]
Target Launch: [Date or DRY RUN]
Generated: [Date]

---

## 1. Code Readiness

### Build Health
- [ ] Clean build on all target platforms
- [ ] Zero compiler warnings
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] Performance benchmarks within targets
- [ ] No memory leaks (verified via extended soak test)
- [ ] Build size within platform limits
- [ ] Build version correctly set and tagged in source control

### Code Quality
- [ ] TODO count: [N] (zero required for launch, or documented exceptions)
- [ ] FIXME count: [N] (zero required)
- [ ] HACK count: [N] (each must have documented justification)
- [ ] No debug output in production code
- [ ] No hardcoded dev/test values
- [ ] All feature flags set to production values
- [ ] Error handling covers all critical paths
- [ ] Crash reporting integrated and verified

### Security
- [ ] No exposed API keys or credentials in source
- [ ] Save data encrypted
- [ ] Network communication secured (TLS/DTLS)
- [ ] Anti-cheat measures active (if multiplayer)
- [ ] Input validation on all server endpoints (if multiplayer)
- [ ] Privacy policy compliance verified

---

## 2. Content Readiness

### Assets
- [ ] All placeholder art replaced with final assets
- [ ] All placeholder audio replaced with final audio
- [ ] Audio mix finalized and approved by audio director
- [ ] All VFX polished and performance-verified
- [ ] No missing or broken asset references
- [ ] Asset naming conventions enforced

### Text and Localization
- [ ] All player-facing text proofread
- [ ] No hardcoded strings (all externalized for localization)
- [ ] All supported languages translated and verified
- [ ] Text fits UI in all languages (text fitting pass complete)
- [ ] Font coverage verified for all supported languages
- [ ] Credits complete, accurate, and up to date

### Game Content
- [ ] All levels/maps playable from start to finish
- [ ] Tutorial flow complete and tested with new players
- [ ] All achievements/trophies implemented and tested
- [ ] Save/load works correctly for all game states
- [ ] Difficulty settings balanced and tested
- [ ] End-game/credits sequence complete

---

## 3. Quality Assurance

### Testing
- [ ] Full regression test suite passed
- [ ] Zero S1 (Critical) bugs open
- [ ] Zero S2 (Major) bugs open (or documented exceptions)
- [ ] Soak test passed (8+ hours continuous play)
- [ ] Multiplayer stress test passed (if applicable)
- [ ] All critical user paths tested on every platform
- [ ] Edge cases tested (full storage, no network, suspend/resume)

### Platform Certification

**Emit ONLY the block matching `platform.cert_tier`** (resolved in the resolved-config block at the top of this skill — see
the `platform.cert_tier` rule above). Do not emit this section's other blocks, and
do not fall back to emitting all of them.

**At `none`** — omit the section and say so in one line:
`Platform Certification: omitted — cert_tier is 'none' (internal/jam release).`

**At `itch`:**
- [ ] Build size within itch.io upload limits
- [ ] itch.io page complete (cover art, screenshots, description, tags)
- [ ] Age/content tags set honestly
- [ ] Downloadable vs browser build decided and tested

**At `steam`:**
- [ ] Steamworks SDK integrated and tested
- [ ] Store page complete (capsule art, trailer, description, system requirements)
- [ ] Depot build uploaded and installs cleanly from a fresh account
- [ ] Achievements functional
- [ ] Steam common content rules reviewed

**At `console`:**
- [ ] TRC/TCR/Lotcheck submission prepared
- [ ] Save-data rules compliant (corruption, full storage, user switching)
- [ ] Controller-mapping rules met, platform-correct button prompts
- [ ] Suspend/resume verified
- [ ] Age ratings obtained (ESRB, PEGI, regional)

**Every tier**, because these are not certification-gated:
- [ ] Accessibility: minimum standards met (remapping, text scaling, colorblind)

> **Keep this template gated by tier.** An ungated list — PC *and* Console *and*
> Mobile rows emitted at every tier — contradicts the `cert_tier` rule at the top
> of this skill, which says an `itch` project gets no console and no Steamworks
> items. When a rule and a template disagree, the template wins in practice,
> because a template is what gets copied.
>
> Changing the branching vocabulary is only half the job: the rows that branching
> governs have to move with it, or the rule describes behaviour nothing reaches.

### Performance
- [ ] Target FPS met on minimum spec hardware
- [ ] Load times within budget on all platforms
- [ ] Memory usage within budget on all platforms
- [ ] Network bandwidth within targets (if multiplayer)
- [ ] No frame hitches in critical gameplay moments

---

## 4. Store and Distribution

### Store Pages
- [ ] Store page copy finalized and proofread
- [ ] Screenshots current and per-platform resolution
- [ ] Trailers current and approved
- [ ] Key art and capsule images finalized
- [ ] System requirements accurate (PC)
- [ ] Pricing configured for all regions
- [ ] Pre-purchase/wishlist campaigns active (if applicable)

### Legal
- [ ] EULA finalized and approved by legal
- [ ] Privacy policy published and linked
- [ ] Third-party license attributions complete
- [ ] Music/audio licensing verified
- [ ] Trademark/IP clearance confirmed
- [ ] GDPR/CCPA compliance verified (data collection, consent, deletion)

---

## 5. Infrastructure

### Servers (if multiplayer/online)
- [ ] Production servers provisioned and load-tested
- [ ] Auto-scaling configured and tested
- [ ] Database backups configured
- [ ] CDN configured for content delivery
- [ ] DDoS protection active
- [ ] Monitoring and alerting configured

### Analytics and Monitoring
- [ ] Analytics pipeline verified and receiving data
- [ ] Crash reporting active and dashboard accessible
- [ ] Server monitoring dashboards live
- [ ] Key metrics tracked: DAU, session length, retention, crashes
- [ ] Alerts configured for critical thresholds

---

## 6. Community and Marketing

### Community Readiness
- [ ] Community guidelines published
- [ ] Moderation team briefed and tools ready
- [ ] Discord/forum/social channels set up
- [ ] FAQ and known issues page prepared
- [ ] Support email/ticketing system active

### Marketing
- [ ] Launch trailer published
- [ ] Press/influencer review keys distributed
- [ ] Social media launch posts scheduled
- [ ] Launch day blog post/dev update drafted
- [ ] Patch notes for launch version published

---

## 7. Operations

### Team Readiness
- [ ] On-call schedule set for first 72 hours post-launch
- [ ] Incident response playbook reviewed by team
- [ ] Rollback plan documented and tested
- [ ] Hotfix pipeline tested (can ship emergency fix within 4 hours)
- [ ] Communication plan for launch issues (who posts, where, how fast)

### Day-One Plan
- [ ] Day-one patch prepared (if needed)
- [ ] Server unlock/go-live procedure documented
- [ ] Launch monitoring dashboard bookmarked by all leads
- [ ] War room/channel established for launch day

---

## Go / No-Go Decision

**Overall Status**: [READY / NOT READY / CONDITIONAL]

### Blocking Items
[List any items that must be resolved before launch]

### Conditional Items
[List items that have documented workarounds or accepted risk]

### Sign-Offs Required
- [ ] Creative Director — Content and experience quality
- [ ] Technical Director — Technical health and stability
- [ ] QA Lead — Quality and test coverage
- [ ] Producer — Schedule and overall readiness
- [ ] Release Manager — Build and deployment readiness
```

---

## Phase 5: Save Checklist

Present the completed checklist and summary to the user (total items, blocking items count, conditional items count, departments with incomplete sections).

If not in dry-run mode, ask: "May I write this to `production/releases/launch-checklist-[date].md`?"

If yes, write the file, creating directories as needed.

---

## Phase 6: Next Steps

- Run `/gate-check` to get a formal PASS/CONCERNS/FAIL verdict before launch.
- Coordinate sign-offs via `/team-release`.
