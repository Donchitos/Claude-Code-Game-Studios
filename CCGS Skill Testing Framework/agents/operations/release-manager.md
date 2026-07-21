# Agent Test Spec: release-manager

## Agent Summary
- **Domain**: Release pipeline management, platform certification checklists (Nintendo, Sony, Microsoft, Apple, Google), store submission workflows, platform technical requirements compliance, semantic version numbering, release branch management
- **Does NOT own**: Game design decisions, QA test strategy or test case design (qa-lead), QA test execution (qa-tester), build infrastructure (devops-engineer)
No fixed model routing is required; the caller selects the available Codex model.
- **Gate IDs**: May be invoked by `$gate-check` during Release phase; LAUNCH BLOCKED verdict is release-manager's primary escalation output

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references release pipeline, certification, store submission)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over QA strategy, game design, or build infrastructure

---

## Test Cases

### Case 1: In-domain request — platform certification checklist for Nintendo Switch
**Input**: "Generate the certification checklist for our Nintendo Switch submission."
**Expected behavior**:
- Produces a structured checklist covering Nintendo Lotcheck requirements relevant to the game type
- Includes categories: content rating (CERO/PEGI/ESRB as applicable), save data handling, offline mode compliance, error handling (lost connectivity, storage full), controller requirement (Joy-Con, Pro Controller support), sleep/wake behavior, screenshot/video capture compliance
- Formats output as a numbered checklist with pass/fail columns
- Notes that Nintendo's full Lotcheck guidelines require a licensed developer account to access and flags any items that require manual verification against the current guidelines document
- Does NOT produce fabricated requirement IDs — uses known public requirements or clearly marks uncertainty

### Case 2: Out-of-domain request — design test cases
**Input**: "Write test cases for our save system to make sure it passes certification."
**Expected behavior**:
- Does not produce test case specifications
- States clearly: "Test case design is owned by qa-lead (strategy) and qa-tester (execution); I can provide the certification requirements that the save system must meet, which qa-lead can then use to design tests"
- Optionally offers to list the save-system-relevant certification requirements

### Case 3: Domain boundary — certification failure (rating issue)
**Input**: "Our build was rejected by the ESRB. The rejection cites content not reflected in our rating submission: a hidden profanity string in debug output that appeared in a screenshot."
**Expected behavior**:
- Issues a LAUNCH BLOCKED verdict with the specific platform requirement referenced (ESRB submission accuracy requirement)
- Identifies the immediate action required: locate and remove all debug output containing inappropriate content before resubmission
- Notes the resubmission process: corrected build must be resubmitted with updated content descriptor if needed
- Does NOT minimize the issue — a certification rejection is a blocking event, not an advisory
- Escalates to producer: documents the delay impact on release timeline

### Case 4: Version numbering conflict — hotfix vs. release branch
**Input**: "Our release branch is at v1.2.0. A hotfix was applied directly on main and tagged v1.2.1. Now the release branch also has changes that need to ship as v1.2.1 but they're different changes."
**Expected behavior**:
- Identifies the conflict: two different changesets have been assigned the same version tag
- Applies semantic versioning resolution: one must be re-tagged — the release branch changes should become v1.2.2 if v1.2.1 is already published; if v1.2.1 is not yet published, coordinate with devops-engineer to merge or re-tag
- Does NOT accept a state where the same version number refers to two different builds
- Notes that once a version is submitted to a store, it cannot be reused — flags this as a potential store submission blocker

### Case 5: Context pass — release date constraint and certification lead time
**Input context**: Target release date is 2026-06-01. Current date is 2026-04-06. Nintendo Lotcheck typically takes 4-6 weeks.
**Input**: "What should we prioritize on the certification checklist given our timeline?"
**Expected behavior**:
- Calculates the available window: ~8 weeks to release date; Nintendo Lotcheck at 4-6 weeks means submission must be ready by approximately 2026-04-20 to 2026-05-04 to allow for a potential resubmission cycle
- Flags that a single rejection cycle would consume the buffer — prioritizes items historically associated with Lotcheck rejections (save data, offline mode, error handling)
- Orders the checklist by certification lead time impact, not by perceived difficulty
- Does NOT produce a checklist that assumes first-pass certification — builds in resubmission time

---

## Protocol Compliance

- [ ] Stays within declared domain (release pipeline, certification checklists, version numbering, store submission)
- [ ] Redirects test case design requests to qa-lead/qa-tester without producing test specs
- [ ] Issues LAUNCH BLOCKED verdicts for certification failures — does not downgrade to advisory
- [ ] Applies semantic versioning correctly and flags version conflicts as store-blocking issues
- [ ] Uses provided timeline data to prioritize checklist items by certification lead time

---

## Coverage Notes
- Case 3 (LAUNCH BLOCKED verdict) is the most critical test — this agent's primary safety output is blocking bad launches
- Case 5 requires current date and release date context; verify the agent uses actual dates, not placeholder estimates
- Certification requirements change over time — flag if the agent produces specific requirement IDs that may be outdated
- No automated runner; review manually or via `$skill-test`
