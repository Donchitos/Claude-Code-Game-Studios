# Skill Test Spec: /team-release

## Skill Summary

Orchestrates the release team through a 7-phase pipeline from release candidate to
deployment and post-release monitoring. Coordinates release-manager, qa-lead,
devops-engineer, producer, security-engineer (required for online/multiplayer/player
data), network-programmer (required for multiplayer), analytics-engineer,
localization-lead, performance-analyst and community-manager. Phase 0 resolves
`review_mode`, `automation`, `team.size`, `workflow` and `project.stage`.
`/gate-check release` is the readiness gate that must pass before a release, so
when `project.stage` is not `Release` the skill stops before Phase 1, spawns
nothing, says "run `/gate-check release` first", and offers an explicit override
that is recorded (`Stage override: …`) in the go/no-go record and the report — it
never sets `project.stage` itself. The skill announces the active set before
Phase 1 — the default `individual` spawns release-manager alone. Each agent writes
to its own named file under `production/releases/` (patch notes under
`docs/patch-notes/`). Phase 3 agents run in parallel. Ends with a go/no-go
decision; deployment (Phase 6) is skipped if the producer calls NO-GO and, on GO,
still requires an explicit `AskUserQuestion` approval in every automation mode.
Closes with a post-release monitoring plan.

---

## Static Assertions (Structural)

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] File Write Protocol distinguishes sub-agents (bounded exception: named path, new artifact under `production/`, `docs/` or `tests/`, gated phase — no per-write prompt) from sub-skills (normal protocol — they ask before writing), and requires explicit confirmation for tags, pushes, builds and storefront changes
- [ ] File Write Protocol section states that the orchestrator does not write files directly
- [ ] Names a destination per agent, so no two parallel agents share a file: `production/releases/release-plan-[version].md`, `release-checklist-[version].md`, `qa-gate-[version].md`, `build-[version].md`, `security-signoff-[version].md`, `netcode-signoff-[version].md`, `localization-signoff-[version].md`, `performance-signoff-[version].md`, `analytics-signoff-[version].md`, `go-no-go-[version].md`, `announcement-[version].md`, `release-report-[version].md`, and `docs/patch-notes/[version].md`
- [ ] Error Recovery Protocol section is present: verify a named artifact is on disk, surface BLOCKED immediately, always produce a partial report, full procedure (surface / assess / offer options / partial report) in `.claude/docs/error-recovery-protocol.md`
- [ ] Phase 0 resolves `project.stage`, and a stage check before Phase 1 stops when it is not `Release` ("run `/gate-check release` first"), spawning nothing; the only way past it is an explicit `AskUserQuestion` override, asked in every `automation` mode and recorded as a `Stage override:` line in the go/no-go record and the final report
- [ ] Has a next-step handoff referencing post-release monitoring and `/retrospective`; the skill does not write `project.stage` or `production/stage.txt` itself
- [ ] qa-lead checks open bugs at the release gate's thresholds for the resolved `workflow`: S1 at every tier, S2 and S3 too at `full`
- [ ] A "phase gate" is a decision point the pipeline itself lists, whatever the `automation` mode; no clause says directors spawn at phase gates
- [ ] Phase 2 is trunk-based: the release candidate is a commit on `main`, and a `release/*` branch is cut only when the release needs stabilising (freeze / certification), with every fix also landing on `main`
- [ ] `/patch-notes` is run by release-manager in Phase 6, and community-manager writes the announcement from its output
- [ ] Uses `AskUserQuestion` at phase transitions requiring user approval before proceeding
- [ ] Phase 0 resolves `team.size`, and the skill requires a one-line active-set announcement before Phase 1
- [ ] Phase 3 agents (qa-lead, devops-engineer, and optionally security-engineer, network-programmer) are explicitly stated to run in parallel
- [ ] Phase 6 (Deployment) is conditional on a GO decision from Phase 5 and on an explicit `AskUserQuestion` approval regardless of `modes.automation`
- [ ] security-engineer is described as conditional on `platform.online` / `platform.multiplayer` and player data — not always spawned, and an absent key is asked about rather than read as `false`

---

## Test Cases

### Case 1: Happy Path (Single-Player) — All phases complete, version deployed

**Fixture:**
- Resolved config block: `review_mode: full`, `team.size: studio`, `automation: collaborative`
- `project.stage` in `project.yaml` is `Release` (`/gate-check release` has passed)
- Milestone acceptance criteria are all met (producer can confirm)
- `project.yaml` sets `platform.online: false` and `platform.multiplayer: false`; the game collects no player data
- No freeze or platform certification is planned for this release
- All CI builds are clean on `main`
- No open S1/S2 bugs; all strings translated

**Input:** `/team-release v1.0.0`

**Expected behavior:**
1. The stage check passes (`project.stage: Release`); before any spawn, one line announces the active set for `team.size: studio`
2. Phase 1: Spawns `producer` via Agent; confirms all milestone acceptance criteria met; identifies any deferred scope; writes `production/releases/release-plan-v1.0.0.md`; AskUserQuestion: user approves before Phase 2
3. Phase 2: Spawns `release-manager` via Agent; bumps version numbers on `main`, and that commit is the release candidate; finds no release checklist from Polish, so invokes `/release-checklist` (`production/releases/release-checklist-v1.0.0.md`); cuts no `release/*` branch, since nothing needs stabilising; AskUserQuestion: user approves before Phase 3
4. Phase 3 (parallel): Issues Agent calls simultaneously for `qa-lead` (regression suite, critical path sign-off, `production/releases/qa-gate-v1.0.0.md`) and `devops-engineer` (build artifacts, CI verification, `production/releases/build-v1.0.0.md`); security-engineer is NOT spawned (`platform.online: false`, no player data) and network-programmer is NOT spawned (`platform.multiplayer: false`), and the Phase 3 output names each skip with its reason
5. Phase 4: localization-lead verifies all strings are translated (`production/releases/localization-signoff-v1.0.0.md`); performance-analyst benchmarks the release build (`performance-signoff-v1.0.0.md`); `analytics-engineer` verifies telemetry fires correctly on the release build (`analytics-signoff-v1.0.0.md`) — each agent writes its own file
6. Phase 5: Spawns `producer` via Agent; collects sign-offs from qa-lead, release-manager, devops-engineer and technical-director; no open blocking issues; producer declares GO (`production/releases/go-no-go-v1.0.0.md`)
7. Phase 6: `AskUserQuestion` "Producer verdict is GO. Execute Phase 6 — tag, deploy to staging, deploy to production?" with [A] Yes, deploy / [B] Staging only — hold production / [C] Stop here; user selects [A]
8. Phase 6: release-manager + devops-engineer tag the release, finalize the changelog via `/changelog`, deploy to staging, then production; in parallel release-manager finalizes patch notes via `/patch-notes v1.0.0` (`docs/patch-notes/v1.0.0.md`), and `community-manager` writes the launch announcement from them (`production/releases/announcement-v1.0.0.md`)
9. Phase 7: release-manager generates the release report (`production/releases/release-report-v1.0.0.md`); producer updates milestone tracking; qa-lead monitors for regressions; community-manager publishes; analytics-engineer confirms live dashboards healthy
10. Next steps: monitor dashboards for 48 hours; `/retrospective` if significant issues occurred
11. Verdict: COMPLETE — release executed and deployed

**Assertions:**
- [ ] Active-set line naming `team.size: studio` appears before the first agent is spawned
- [ ] Phase 2 cuts no `release/*` branch: the release candidate is the version-bump commit on `main`
- [ ] Phase 3 qa-lead and devops-engineer Agent calls are issued simultaneously, not sequentially
- [ ] security-engineer is NOT spawned when `platform.online` and `platform.multiplayer` are false and there is no player data, and the Phase 3 output says so by name (e.g. `security-engineer: not spawned — platform.online: false, platform.multiplayer: false, no player data`) — the skip is never silent
- [ ] Each agent is told its own named output file — parallel Phase 3 and Phase 4 agents never share one — and the orchestrator confirms the file exists before treating the phase as done
- [ ] Phase 5 producer collects sign-offs from qa-lead, release-manager, devops-engineer and technical-director before declaring GO
- [ ] Phase 6 deployment only begins after the user picks [A] in the Phase 6 `AskUserQuestion`
- [ ] `/changelog` is invoked by release-manager in Phase 6 (not written directly)
- [ ] `/patch-notes v1.0.0` is invoked by release-manager in Phase 6, and community-manager writes the announcement from its output — community-manager is never asked to run `/patch-notes`
- [ ] Phase 7 monitoring plan includes a 48-hour post-release monitoring commitment
- [ ] No stop and no override question at the stage check, because `project.stage` reads `Release`; the skill writes neither `project.stage` nor `production/stage.txt`, and no post-launch stage value is invented
- [ ] Verdict: COMPLETE appears in the final output

---

### Case 2: Go/No-Go: NO — S1 bug found in Phase 3, deployment skipped

**Fixture:**
- Resolved config block: `team.size: small`, `automation: collaborative`, `project.stage: Release`
- The v0.9.0 release candidate is a commit on `main`
- qa-lead discovers a previously unreported S1 crash in the main menu during Phase 3 regression testing
- devops-engineer build is clean and artifacts are ready

**Input:** `/team-release v0.9.0`

**Expected behavior:**
1. Phases 1–2 complete normally; the release candidate commit is identified
2. Phase 3 (parallel): devops-engineer returns clean build sign-off; qa-lead returns with an S1 bug identified and regression suite failing; qa-lead declares quality gate: NOT PASSED
3. At the Phase 3 → 4 transition the orchestrator writes qa-lead's full result in conversation — "QA-LEAD: S1 bug found — [crash description]. Quality gate: NOT PASSED." — and captures the decision via `AskUserQuestion`
4. Phase 5: Spawns `producer` via Agent; producer receives qa-lead's NOT PASSED verdict; producer declares NO-GO with rationale: "S1 bug [ID] is open and unresolved. Releasing is not safe."
5. Orchestrator surfaces "PRODUCER: NO-GO — [rationale]" and uses `AskUserQuestion` with options: fix the blocker and re-run the affected phase, defer the release, or override NO-GO with documented rationale
6. Phase 6 (Deployment) is SKIPPED entirely — no tagging, no deploy to staging, no deploy to production
7. Neither Phase 6 copy step runs — release-manager does not run `/patch-notes` and community-manager is NOT spawned (no deployment to announce)
8. Skill ends with a partial report summarizing what was completed (Phases 1–5) and what was skipped (Phase 6) and why
9. Verdict: BLOCKED — release not deployed

**Assertions:**
- [ ] qa-lead S1 bug finding is surfaced to the user immediately after Phase 3 completes — not suppressed until Phase 5
- [ ] producer's NO-GO decision explicitly references the S1 bug and the quality gate result
- [ ] Phase 6 Deployment is completely skipped when producer declares NO-GO
- [ ] No patch notes or launch announcement are produced on NO-GO — `/patch-notes` is not run and community-manager is NOT spawned
- [ ] The partial report clearly states which phases completed and which were skipped, with reasons
- [ ] Verdict: BLOCKED (not COMPLETE) when deployment is skipped due to NO-GO
- [ ] AskUserQuestion offers the user resolution options (fix and re-run / defer / override with rationale)
- [ ] Override path (if chosen) asks for a written justification and embeds it as an "Override Justification" field in the record before any Phase 6 action

---

### Case 3: Security Audit for Online Game — security-engineer is spawned in Phase 3

**Fixture:**
- Resolved config block: `review_mode: full`, `team.size: studio`, `automation: collaborative`, `project.stage: Release`
- `project.yaml` sets `platform.multiplayer: true` and `platform.online: true`; the game stores player account data
- Release candidate exists for v2.1.0
- qa-lead and devops-engineer both return clean sign-offs

**Input:** `/team-release v2.1.0`

**Expected behavior:**
1. Phases 1–2 complete normally
2. Phase 3 (parallel): Orchestrator reads `platform.multiplayer: true` and `platform.online: true` from `project.yaml` and notes the stored player data; issues Agent calls simultaneously for `qa-lead`, `devops-engineer`, `security-engineer` and `network-programmer`
3. security-engineer conducts pre-release security audit: reviews authentication flows, anti-cheat presence, data privacy compliance; returns sign-off
4. network-programmer verifies lag compensation, reconnect handling, and bandwidth under load; returns sign-off
5. All four Phase 3 agents complete; their results are collected before Phase 4 begins
6. Phase 5: producer collects sign-offs from qa-lead, release-manager, devops-engineer, security-engineer, network-programmer and technical-director before making the go/no-go call
7. Remaining phases proceed normally to COMPLETE

**Assertions:**
- [ ] security-engineer IS spawned in Phase 3 when the game has online features, multiplayer, or player data — this is not skipped
- [ ] network-programmer IS spawned in Phase 3 when the game has multiplayer
- [ ] All four Phase 3 Agent calls (qa-lead, devops-engineer, security-engineer, network-programmer) are issued simultaneously
- [ ] security-engineer audit covers authentication, anti-cheat, and data privacy compliance
- [ ] Phase 5 producer sign-off collection includes security-engineer and network-programmer alongside qa-lead, release-manager, devops-engineer and technical-director
- [ ] Phase 6 deployment does not begin until security-engineer has signed off
- [ ] Skill does NOT treat security-engineer as optional for a game with player data

---

### Case 4: Localization Miss — Untranslated strings reach the go/no-go call

**Fixture:**
- Resolved config block: `team.size: studio`, `automation: collaborative`, `project.stage: Release`
- `project.yaml` sets `platform.online: false` and `platform.multiplayer: false`; no player data
- Release candidate exists for v1.2.0
- Phase 3 (qa-lead, devops-engineer) complete with clean sign-offs
- Phase 4: localization-lead finds 47 untranslated strings in the French locale (a supported language) and returns it as a BLOCKED/CONCERNS item
- producer judges the miss release-blocking and declares NO-GO

**Input:** `/team-release v1.2.0`

**Expected behavior:**
1. Phases 1–3 complete with clean sign-offs
2. Phase 4: the translation check is delegated to localization-lead (active at `studio`); its sign-off is written to `production/releases/localization-signoff-v1.2.0.md` and the orchestrator confirms the file exists
3. At the Phase 4 → 5 transition the orchestrator writes the localization finding in conversation and captures the decision via `AskUserQuestion` — it does not auto-advance
4. Phase 5: producer evaluates the untranslated strings as an open issue and declares NO-GO
5. Orchestrator surfaces "PRODUCER: NO-GO — [rationale naming the untranslated French strings]" and offers via `AskUserQuestion`: fix the blocker and re-run the affected phase / defer the release / override NO-GO with documented rationale
6. Phase 6 is skipped entirely; a partial report lists Phases 1–5 as completed and Phase 6 as skipped with the reason
7. Verdict: BLOCKED — release not deployed

**Assertions:**
- [ ] Phase 4 delegates the translation check to localization-lead when it is in the active set
- [ ] The localization finding is presented at the Phase 4 → 5 transition via `AskUserQuestion` before the go/no-go runs
- [ ] The producer's NO-GO rationale names the untranslated-strings issue
- [ ] The resolution options include re-running the affected phase — the skill does not require restarting from Phase 1
- [ ] If the user overrides, the written justification is embedded in the record before any Phase 6 action
- [ ] The orchestrator writes no files itself — it does not produce translations to unblock the release
- [ ] Verdict is BLOCKED and Phase 6 does not run on NO-GO

---

### Case 5: No Argument — Skill infers version or asks

In both variants `project.stage` is `Release`.

**Fixture (variant A — milestone data present):**
- `production/milestones/` exists with a milestone file; most recent milestone is "v1.1.0 — Gold"
- `production/session-state/active.md` references a version or milestone

**Fixture (variant B — no discoverable version):**
- `production/milestones/` does not exist
- `production/session-state/active.md` does not reference a version
- No git tags are present from which to infer a version

**Input:** `/team-release` (no argument)

**Expected behavior (variant A):**
1. Argument check: no version provided; reads `production/session-state/active.md` and the most recent milestone file in `production/milestones/`
2. Infers v1.1.0 as the target version; reports "No version argument provided — inferred v1.1.0 from milestone data. Proceeding."
3. Confirms with AskUserQuestion before beginning Phase 1: "Releasing v1.1.0. Is this correct?"
4. Proceeds as if `/team-release v1.1.0` was the input

**Expected behavior (variant B):**
1. Argument check: no version provided; reads available state files — no version discoverable
2. Uses AskUserQuestion: "What version number should be released? (e.g., v1.0.0)"
3. Waits for user input before proceeding

**Assertions:**
- [ ] Skill does NOT default to a hardcoded version string when no argument is provided
- [ ] Skill reads `production/session-state/active.md` and milestone files before asking (variant A)
- [ ] Inferred version is confirmed with the user via AskUserQuestion before proceeding (variant A)
- [ ] When no version is discoverable, AskUserQuestion is used — skill does not guess (variant B)
- [ ] Skill does NOT error out when milestone files are absent — it falls back to asking (variant B)

---

### Case 6: Stage Still Polish — Stops Before Phase 1, Nothing Spawned

**Fixture:**
- Resolved config block: `review_mode: full`, `team.size: studio`, `automation: autonomous`, `project.stage: Polish`
- `/gate-check release` has not been run; a release candidate exists for v1.0.0

**Input:** `/team-release v1.0.0`

**Expected behavior (variant A — the user stops):**
1. Phase 0 resolves `project.stage: Polish`; the stage check stops before Phase 1: "The release readiness gate has not passed (project.stage: Polish) — run `/gate-check release` first."
2. `AskUserQuestion` offers `[A] Stop — I'll run /gate-check release (recommended)` / `[B] Proceed anyway — override the stage check` — asked even though `automation` is `autonomous`
3. User picks `[A]`: no agent is spawned, no file is written, nothing is tagged or deployed
4. Verdict: BLOCKED — release gate not passed

**Expected behavior (variant B — the user overrides):**
1. Same stop and question; user picks `[B]` and, asked why, answers "cert window closes Friday"
2. The run continues to Phase 1 with the override in the producer's brief
3. The go/no-go record (`production/releases/go-no-go-v1.0.0.md`) and the final report carry `Stage override: project.stage was Polish — release gate not passed; the user chose to proceed: cert window closes Friday`
4. `project.stage` still reads `Polish` at the end of the run

**Assertions:**
- [ ] No `Agent` call is issued before the stage-check question is answered
- [ ] The stop message names `/gate-check release` as the step to run first
- [ ] The question is asked in `autonomous` mode — the override is never taken automatically
- [ ] On `[A]` the verdict is BLOCKED and no agent is spawned at all (not even release-manager)
- [ ] On `[B]` the override and its reason appear in the go/no-go record and in the final report
- [ ] The skill writes neither `project.stage` nor `production/stage.txt` in either variant

---

## Protocol Compliance

- [ ] At the default `team.size: individual`, the run opens with `Active set (team.size: individual): release-manager.` and a `Not spawned this run:` line naming every other agent the pipeline names, consulted through release-manager — before any agent is spawned
- [ ] In `collaborative` mode, `AskUserQuestion` used at each phase transition gate (post-Phase 1, post-Phase 2, post-Phase 3, post-Phase 4, post-Phase 5 go/no-go)
- [ ] Phase 3 agents in the active set are always issued as parallel Agent calls — qa-lead and devops-engineer are never sequential
- [ ] security-engineer is conditionally spawned from `platform.online` / `platform.multiplayer` and player data — never silently skipped: an absent key is asked about, and a skip is named in the Phase 3 output
- [ ] At `review_mode: lean` or `solo`, technical-director is not spawned for the Phase 5 sign-off, and the go/no-go record says `technical-director sign-off: not run (review_mode: <mode>)` rather than listing it as given
- [ ] A technical-director `NOT ASSESSED [missing input]` answer is recorded as such in the go/no-go record and never counted as a sign-off
- [ ] When a `release/*` branch is cut to stabilise a release, it takes bug fixes only and every fix also lands on `main`
- [ ] File Write Protocol: orchestrator never calls Write/Edit directly — sub-agents write their named paths under the bounded exception, sub-skills ask before writing
- [ ] Phase 6 Deployment is strictly conditional on a GO verdict from Phase 5 and an explicit `AskUserQuestion` approval — never auto-triggered, including in `autonomous` mode
- [ ] Error recovery: any BLOCKED agent is surfaced immediately before continuing to dependent phases
- [ ] A phase whose named artifact is missing on disk is treated as failed, not done
- [ ] Partial reports are always produced if any phase fails or the pipeline is halted (Cases 2 and 4)
- [ ] Verdict: COMPLETE only when deployment completes; BLOCKED when the stage check stops the run, go/no-go is NO, or a hard blocker is unresolved
- [ ] Stage check: when `project.stage` is not `Release`, nothing is spawned until the user answers the stop question; proceeding takes the explicit `[B]` override, which is recorded (Case 6)
- [ ] Next steps always include 48-hour post-release monitoring and a `/retrospective` recommendation — never a direct `project.stage` write

---

## Coverage Notes

- Phase 7 post-release actions (release report, milestone tracking, community publishing, dashboard monitoring) are validated implicitly by Case 1. No separate edge case is required as Phase 7 is non-gated and does not have a blocking failure mode.
- The "devops-engineer build fails" path is not separately tested — it would surface as a BLOCKED result in Phase 3 and follow the standard error recovery protocol (surface → assess → AskUserQuestion options).
- The parallel Phase 4 path (running alongside Phase 3 "if resources available") is left to the skill's judgment; Case 4 tests Phase 4 as a sequential phase.
- The `[B] Staging only — hold production` Phase 6 option is not separately tested.
- A release that needs stabilising (a freeze or platform certification, so a `release/*` branch is cut) is not given its own case; the rule is asserted in Protocol Compliance.
- The "override NO-GO with documented rationale" path is checked for its justification step in Cases 2 and 4 but not followed through a full deployment.
