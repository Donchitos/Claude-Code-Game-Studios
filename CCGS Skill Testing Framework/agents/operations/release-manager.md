# Agent Test Spec: release-manager

## Agent Summary
- **Domain**: Release pipeline (Build → Test → Cert → Submit → Verify → Launch), platform certification checklists scoped by `platform.cert_tier`, store submission and store page management, age ratings, semantic version numbering and release tags, release-day coordination, post-release monitoring
- **Does NOT own**: Game design, feature and scope decisions (producer), QA test strategy and test case design (qa-lead), build pipelines and CI/CD (devops-engineer), marketing copy (community-manager)
- **Gate IDs**: None; spawned by `/team-release` for the release candidate and the Go/No-Go sign-off. Its blocking output is a `NOT READY` Go/No-Go verdict from the preloaded `/release-checklist`, reported to producer

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references release pipeline, certification, store submission)
- [ ] `tools:` reads `Read, Glob, Grep, Write, Edit, Bash` — Bash for release tagging ("Version tags must be applied to the git repository at every release point")
- [ ] `skills:` preloads `release-checklist`, `changelog` and `patch-notes`
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over QA strategy, game design, or build infrastructure
- [ ] Its next-step offer runs `/patch-notes [version]` itself and hands the result to community-manager for the announcement — never a brief for community-manager to write the patch notes
- [ ] The pipeline's Test step takes the release gate's tier: QA sign-off at `workflow: full` (recommended at `standard`), no open S1 at any tier, no open S2 or S3 either at `full`

---

## Test Cases

### Case 1: In-domain request — certification checklist for a console submission
**Input context**: `project.yaml` sets `platform.cert_tier: console`; the game ships on Nintendo Switch.
**Input**: "Generate the certification checklist for our Nintendo Switch submission."
**Expected behavior**:
- Emits the console certification block its preloaded `/release-checklist` defines for `cert_tier: console` — TRC/TCR/Lotcheck requirements checklist, first-party submission, achievement/trophy integration, parental controls, save-data rules (corruption, full storage, user switching), age ratings — plus the console device requirements (controller prompts, suspend/resume, user switching, connectivity loss, storage full)
- Tracks every requirement individually with pass / fail / not-applicable status (Platform Certification Requirements)
- Emits no itch.io or Steamworks certification rows — the certification block follows `cert_tier`, not the platform named in the request
- Ends with the Go / No-Go line in `/release-checklist`'s three words (READY / NOT ASSESSED / NOT READY, first match wins) — here NOT ASSESSED or NOT READY, never READY, because the fixture supplies no build or test evidence — and asks "May I write this to `production/releases/release-checklist-[version].md`?" before writing

### Case 2: Out-of-domain request — design test cases
**Input**: "Write test cases for our save system to make sure it passes certification."
**Expected behavior**:
- Does not produce test case specifications
- Routes test design to `qa-lead`, which its Delegation Map names for quality gates, test results, and release readiness sign-off
- Offers what it does own: the save-data certification requirements the tests must cover (the console block's "Save-data rules compliant (corruption, full storage, user switching)"), as input for qa-lead

### Case 3: Domain boundary — age-rating rejection blocks the release
**Input**: "Our build was rejected by the ESRB. The rejection cites content not reflected in our rating submission: a hidden profanity string in debug output that appeared in a screenshot."
**Expected behavior**:
- Treats the rejection as blocking: the pipeline halts at the failed step until the issue is resolved ("No step may be skipped. If a step fails, the pipeline halts and the issue is resolved before proceeding")
- Returns the Go / No-Go verdict as NOT READY, listing the rating issue as a blocking item with an estimated time to resolve (`/release-checklist` Go / No-Go rationale)
- Identifies the action required: remove all debug output containing the content, then resubmit the rating questionnaire and track receipt of the new certificate (Store Page Management: age ratings)
- Does NOT minimize the issue or propose launching around it — a rating rejection is a blocking event, not an advisory
- Reports the delay's impact on the release date to producer, which it reports to for scheduling

### Case 4: Version numbering conflict — hotfix vs. release branch
**Input**: "Our release branch is at v1.2.0. A hotfix was applied directly on main and tagged v1.2.1. Now the release branch also has changes that need to ship as v1.2.1 but they're different changes."
**Expected behavior**:
- Identifies the conflict: two different changesets have been assigned the same version
- Resolves it with semantic versioning: `v1.2.1` stays with the build it already tags, and the release branch's changes, being fixes, ship as the next PATCH (`v1.2.2`) — its Version Numbering rule for two changesets claiming one version
- Does NOT accept a state where one version number names two different builds — "an applied tag is never moved or reused", and internal builds stay distinguishable by `MAJOR.MINOR.PATCH.BUILD`
- Coordinates the hotfix-branch side with `lead-programmer`, which its Delegation Map names for hotfix branch management

### Case 5: Context pass — release date constraint and certification lead time
**Input context**: Target release date is 2026-06-01. Current date is 2026-04-06. Nintendo Lotcheck typically takes 4-6 weeks.
**Input**: "What should we prioritize on the certification checklist given our timeline?"
**Expected behavior**:
- Works from the supplied dates and lead time, not placeholders: 8 weeks to release, so the first Lotcheck submission is due between 2026-04-20 (if it takes 6 weeks) and 2026-05-04 (if it takes 4) — before any resubmission
- Keeps the pipeline order and every step — Build → Test → Cert → Submit → Verify → Launch, "No step may be skipped" — and schedules backward from the release date rather than compressing or dropping a step to fit
- Plans for at least one certification iteration (Cert is "Submit to platform certification, track feedback, iterate") and flags that a single rejection would consume the remaining buffer
- Recommends an order but hands the schedule call to `producer` — it reports to producer for scheduling and prioritization, and cutting scope is producer's ("Decide what features to include or exclude (escalate to producer)")

---

## Protocol Compliance

- [ ] Stays within declared domain (release pipeline, certification checklists, version numbering, store submission)
- [ ] Routes test case design requests to qa-lead without producing test specs
- [ ] Returns NOT READY for a certification or rating failure and halts the pipeline — does not downgrade to advisory
- [ ] Applies semantic versioning and never lets one version number name two builds
- [ ] Scopes certification to `platform.cert_tier` and schedules from provided dates without skipping pipeline steps

---

## Coverage Notes
- Case 3 (NOT READY on a rating rejection) is the most critical test — this agent's primary safety output is blocking bad launches
- Case 1 assumes `platform.cert_tier: console`; with the key unset, the expected output is a question about which platforms are in scope or `NOT ASSESSED — cert tier unknown`, never every certification track
- Case 5 requires current date and release date context; verify the agent uses actual dates, not placeholder estimates
- Certification requirements change over time — flag if the agent produces specific requirement IDs that may be outdated
- No automated runner; review manually or via `/skill-test`
