# Skill Test Spec: /hotfix

## Skill Summary

`/hotfix` runs an emergency fix outside the sprint process, with an audit trail.
It runs only when the user types it (`disable-model-invocation: true`). The flow:

1. **Assess severity** (S1 Critical / S2 High / S3 or lower, on `/bug-triage`'s scale) and confirm it with
   `AskUserQuestion`; S3 or lower stops with `Verdict: **REDIRECTED**`.
2. **Hotfix record** — asks "May I write this to
   `production/hotfixes/hotfix-[date]-[short-name].md`?"
3. **Branch** — checks for a git repo, then asks before running
   `git checkout -b hotfix/[short-name] [base-ref]`. `[base-ref]` is the
   release the bug is in: its tag on `main`, or its `release/*` branch if one
   was cut to stabilise it — never the head of `main`.
4. **Investigate and propose** — root cause and minimal fix, then
   "May I implement this fix?" before any code changes; implement, run targeted tests.
5. **Approvals** — `lead-programmer`, `qa-tester` and `producer` spawned in
   parallel; all three must return APPROVE, and CONCERNS or REJECT blocks deployment.
6. **QA re-entry gate** — `qa-lead` picks smoke check, targeted
   `/team-qa feature: [system]`, or full QA; a smoke-check FAIL sends the fix
   back to Phase 4. A NOT ASSESSED result is not a pass: deploying anyway takes
   an explicit producer decision, logged in the hotfix record.
7. **Deploy** — an unconditional `AskUserQuestion` before any merge, tag or deploy
   (even in `autonomous` mode); merge to `main`, and to the release's
   `release/*` branch only if one exists; tag the patch release and verify the
   backport; ask before updating the bug file, then set it to
   `Fixed — Pending Verification`; print "Hotfix Deployed" (on `[B]`,
   "Hotfix Merged to main — release held", with no Tag); `[C]` stops with no
   merge, tag or bug-file update; then `/bug-report verify` (a CANNOT VERIFY is
   settled by playing the reproduction steps and answering its manual-play
   question) and a post-incident review (recorded with the incident-response
   template — `/retrospective` has no incident mode).

Targeted tests run with `commands.test` from `project.yaml`; when it is unset or
no test covers the system, the hotfix record says `Tests: NOT RUN — [reason]`.
A `/team-qa` pass that returns NOT APPROVED or BLOCKED is handled like a
smoke-check FAIL. S1 is `/bug-triage`'s definition: crash, data loss, or
complete feature failure.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Frontmatter sets `disable-model-invocation: true`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: REDIRECTED, APPROVE / CONCERNS / REJECT (sign-offs), NOT ASSESSED (QA gate)
- [ ] Contains "May I write" (hotfix record), "May I implement this fix?" (code) and "May I update" (bug file) language
- [ ] Has a next-step handoff (`/bug-report verify [BUG-ID]`, a post-incident review)

---

## Director Gate Checks

No named director-gate ID (CD-*, TD-*, AD-*, PR-*) is used and the review mode
does not apply. Phase 5 spawns three **blocking sign-offs** in parallel —
`lead-programmer`, `qa-tester` and `producer` (the only director-tier agent) —
and all three must return APPROVE before deployment. Phase 5b spawns `qa-lead` to
choose the QA scope.

---

## Test Cases

### Case 1: Happy Path — S1 crash fixed with record, branch, approvals and backport

**Fixture:**
- Git repository; the live build is the release tag `v1.2.0` on `main`, and no
  `release/*` branch exists (the trunk default)
- Bug in `src/gameplay/arena.gd` (crash on boss arena entry);
  `production/qa/bugs/BUG-0031.md` exists with `**Status**: Open`
- All three sign-offs return APPROVE; `qa-lead` picks a smoke check, which returns PASS

**Input:** `/hotfix BUG-0031`

**Expected behavior:**
1. Assesses S1 and confirms via `AskUserQuestion`; user picks `[A] S1 (Critical)`
2. Asks "May I write this to `production/hotfixes/hotfix-[date]-boss-arena-crash.md`?" and writes it
3. Runs `git rev-parse --is-inside-work-tree`, asks "Ready to create hotfix branch
   'hotfix/boss-arena-crash' from v1.2.0?", and runs
   `git checkout -b hotfix/boss-arena-crash v1.2.0` only after `[A] Yes — create branch`
4. Presents root cause and minimal fix, asks "May I implement this fix?", then implements and runs targeted tests
5. Spawns `lead-programmer`, `qa-tester` and `producer` in parallel; all APPROVE
6. `qa-lead` → smoke check PASS
7. Asks "Hotfix validated and approved. Merge to `main`, tag v1.2.1 and deploy?"
   (no release branch is named — none exists); user picks `[A]`
8. Merges to `main`, tags `v1.2.1` on the fixed build, and confirms the fix is on `main`
9. Asks "May I update `production/qa/bugs/BUG-0031.md` …?" before setting it to
   `Fixed — Pending Verification`, then prints "Hotfix Deployed: boss-arena-crash"
   with `Tag: v1.2.1` and `Next: /bug-report verify`

**Assertions:**
- [ ] The hotfix record is written before the branch is created
- [ ] The branch starts from the release tag `v1.2.0`, not from the head of `main`
- [ ] The branch is created only after the user picks `[A]`
- [ ] No code is modified before "May I implement this fix?" is approved
- [ ] The three sign-off agents are spawned as simultaneous `Agent` calls
- [ ] No merge happens before the Phase 6 deploy question is answered
- [ ] No `release/*` branch is created or merged; the patch release is tagged
- [ ] The summary's Backport line states presence on `main`
- [ ] The bug file is not edited before the user approves the "May I update" question
- [ ] `BUG-0031.md` Status becomes `Fixed — Pending Verification`

---

### Case 2: Sign-off REJECT — Deployment blocked

**Fixture:**
- Fix implemented for an S1 bug
- `qa-tester` returns REJECT: "Player health clamping regression detected";
  `lead-programmer` and `producer` return APPROVE

**Input:** `/hotfix`

**Expected behavior:**
1. Phase 5 collects all three responses
2. Because one returned REJECT, the skill does not deploy: it surfaces the regression and resolves it first
3. The Phase 5b QA gate and the Phase 6 deploy question are not reached while the REJECT stands
4. No merge, tag or deploy occurs

**Assertions:**
- [ ] The qa-tester's REJECT and its regression are shown to the user
- [ ] Skill does not proceed to deployment with a REJECT outstanding
- [ ] The deploy `AskUserQuestion` is not issued while the REJECT stands
- [ ] No merge is performed

---

### Case 3: Release Branch — Deploy approval holds even in autonomous mode

**Fixture:**
- `project.yaml` sets `modes.automation: autonomous`
- The live release `v1.3.0` has a `release/1.3` branch, cut to stabilise it for
  certification; the hotfix branch was started from `release/1.3`
- An S2 fix has all three APPROVE sign-offs and a smoke check PASS

**Input:** `/hotfix`

**Expected behavior:**
1. Despite `autonomous`, Phase 6 asks "Hotfix validated and approved. Merge to `main`
   and `release/1.3`, tag v1.3.1 and deploy?" with `[A] Yes — merge and deploy` /
   `[B] Merge to main only — hold the release` / `[C] Stop here`
2. User picks `[B]`
3. The fix is merged to `main` only; nothing is merged to `release/1.3`, tagged or deployed
4. The summary is titled "Hotfix Merged to main — release held" and has no Tag line

**Assertions:**
- [ ] The deploy question is asked even though `modes.automation` is `autonomous`
- [ ] The question names `release/1.3`, because this release has one
- [ ] All three options are offered
- [ ] With `[B]`, `release/1.3` is not merged, no tag is created and nothing is deployed
- [ ] With `[B]`, `main` receives the fix
- [ ] With `[B]`, the summary does not say "Deployed" and names no tag

---

### Case 4: Not an Emergency — a cosmetic S4 redirected before any work

**Fixture:**
- User reports a typo on the credits screen

**Input:** `/hotfix typo in the credits screen`

**Expected behavior:**
1. Phase 1 assesses S4 (Low — cosmetic) and asks the user to confirm severity
2. User picks `[C] S3 or lower — redirect to normal bug fix workflow`
3. Skill stops: Verdict REDIRECTED — use the normal bug fix workflow for S3 and below

**Assertions:**
- [ ] Severity is confirmed via `AskUserQuestion` with S1 / S2 / S3-or-lower options
- [ ] Verdict is REDIRECTED
- [ ] No hotfix record is written and no branch is created
- [ ] No code is modified and no agents are spawned

---

### Case 5: Director Gate Check — Producer sign-off, and NOT ASSESSED QA is not a pass

**Fixture:**
- `project.yaml`: `modes.rigor: standard` (so a project with no game tests gets NOT ASSESSED, not WAIVED)
- S1 fix implemented; all three sign-offs APPROVE
- `qa-lead` picks a smoke check; `/smoke-check` returns `NOT ASSESSED — no game tests found`

**Input:** `/hotfix`

**Expected behavior:**
1. `producer` is spawned as a blocking sign-off, not as a named director gate; no gate IDs appear
2. The NOT ASSESSED QA result is treated as unmet, not as a pass
3. The skill either obtains the missing result or takes the decision to the producer
   explicitly as a decision to deploy an unverified hotfix. This escape hatch is
   deliberate: an emergency fix may have to ship before a suite exists, but only
   as a named decision, never as a gate that quietly cleared
4. If the producer decides to deploy unverified, that decision — who made it and
   why — is logged in the hotfix record, and the summary's QA gate line reads
   NOT ASSESSED with why and whose explicit decision it was

**Assertions:**
- [ ] No gate IDs (CD-*, TD-*, AD-*, PR-*) appear in output
- [ ] NOT ASSESSED does not advance to Phase 6 as if the QA gate passed
- [ ] Deployment goes ahead only with the three APPROVE sign-offs plus an explicit producer decision to deploy unverified
- [ ] That decision is logged in the hotfix record
- [ ] The summary records the QA gate as NOT ASSESSED with the reason and whose decision it was

---

### Case 6: Smoke Check FAIL — back to Phase 4, and a CONCERNS sign-off still blocks

**Fixture:**
- S1 fix implemented; all three sign-offs APPROVE; `qa-lead` picks a smoke check
- `/smoke-check` returns FAIL: "Player health clamping regression detected"
- On the revised fix, `lead-programmer` returns CONCERNS ("the clamp now runs on
  the save path too"); `qa-tester` and `producer` return APPROVE

**Input:** `/hotfix`

**Expected behavior:**
1. The FAIL stops deployment: the skill returns to Phase 4 with the failing check,
   presents a revised fix and asks "May I implement this fix?" again before
   changing code
2. After implementing it (Phase 4b), it re-runs all three Phase 5 sign-offs —
   qa-tester's regression run among them — and then the QA step
3. `lead-programmer`'s CONCERNS blocks exactly as a REJECT does: it is shown to the
   user and resolved before the skill continues
4. The Phase 6 deploy question is asked only once all three return APPROVE and a
   re-run smoke check passes

**Assertions:**
- [ ] A smoke-check FAIL never reaches the deploy question
- [ ] The revised fix gets its own "May I implement this fix?" approval
- [ ] All three sign-offs and the QA step are re-run for the revised fix
- [ ] CONCERNS from a sign-off blocks deployment until resolved; it is not treated as an approval
- [ ] No merge, tag or deploy occurs while the FAIL or the CONCERNS stands

---

## Protocol Compliance

- [ ] Confirms severity before any work; S3 or lower is REDIRECTED
- [ ] Asks "May I write" before the hotfix record
- [ ] Asks before creating the branch
- [ ] Asks "May I implement this fix?" before modifying code
- [ ] Runs targeted tests with `commands.test`, never a runner line from memory; with the key unset (or no covering test) records `Tests: NOT RUN — [reason]`
- [ ] Treats a `/team-qa` NOT APPROVED or BLOCKED like a smoke-check FAIL
- [ ] On the deploy question's `[C] Stop here`, merges, tags and updates nothing, and the record stays IN PROGRESS
- [ ] Deploys only with all three APPROVE sign-offs and a QA gate that ran — or,
      when the QA gate was NOT ASSESSED, an explicit producer decision to deploy
      unverified, logged in the hotfix record
- [ ] Asks before any merge, tag or deploy regardless of `modes.automation`
- [ ] Starts the hotfix branch from the release it fixes (its tag, or its `release/*` branch if one exists)
- [ ] Verifies the backport on `main`, and on the release's `release/*` branch only when one exists
- [ ] Asks "May I update" before editing the bug file

---

## Coverage Notes

- A non-git working directory ("Not a git repository — create the branch manually.")
  is not separately tested.
- `qa-lead` choosing a targeted `/team-qa feature: [system]` pass (APPROVED /
  APPROVED WITH CONDITIONS) or full QA is not separately tested.
- Phase 7 post-deploy verification (VERIFIED FIXED → `/bug-report close`; STILL
  PRESENT → re-open and assess rollback; CANNOT VERIFY → the bug stays open until
  its reproduction steps are played in the deployed build and reported through
  `/bug-report verify`'s manual-play question) is not separately tested.
