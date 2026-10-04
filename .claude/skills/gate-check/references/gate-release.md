> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other five — one gate applies per invocation.


# Gate: Polish → Release


**Required Artifacts:**
- [ ] All features from milestone plan are implemented
- [ ] Content is complete (all levels, assets, dialogue referenced in design docs exist)
- [ ] Localization strings are externalized (no hardcoded player-facing text in the code root)
- [ ] QA test plan exists (`/qa-plan` output in `production/qa/`)
- [ ] QA sign-off report exists (`/team-qa` output — APPROVED or APPROVED WITH CONDITIONS)
- [ ] All Must Have story test evidence is present (Logic/Integration: test files pass; UI: retained screenshots of each screen touched; Visual/Feel: retained screenshots plus lead sign-off — both in `production/qa/evidence/`, and no `qa.level` waives either)
- [ ] Smoke check passes cleanly (PASS verdict) on the release candidate build
- [ ] No test regressions from previous sprint (test suite passes fully)
- [ ] Balance data has been reviewed (`/balance-check` run)
- [ ] Release checklist completed (`/release-checklist` run)
- [ ] Store metadata prepared (if applicable)
- [ ] Changelog / patch notes drafted

**Quality Checks:**
- [ ] Full QA pass signed off by `qa-lead`
- [ ] All tests passing
- [ ] Performance targets met across all target platforms
- [ ] No known open S1 Critical, S2 High or S3 Medium bugs
- [ ] No open CRITICAL or HIGH findings in the newest `production/security/security-audit-*.md` whose **Scope** is `full`, as updated by any later `quick` report (the re-run `/security-audit` prescribes after remediation). A later `network`, `save` or `input` report adds its open findings but never clears a category it did not scan — any open CRITICAL or HIGH finding means not ready (a blocker). No `full`-scope audit report means the check could not run: this item is NOT ASSESSED, never passed. A report whose release recommendation is itself NOT ASSESSED makes this item NOT ASSESSED too
- [ ] Accessibility basics covered (remapping, text scaling if applicable)
- [ ] Localization verified for all target languages — every translated locale being shipped has a `/localize qa` verdict of PASS or PASS WITH CONDITIONS (`production/localization/loc-qa-[locale]-[date].md`). A FAIL blocks that locale; the others may still ship. A locale with no QA report, or whose QA reported NOT ASSESSED (nobody has played it), has not been verified: this item is NOT ASSESSED, never passed. The source locale (`en`, per `/localize`) is not a target language and needs no `/localize qa` report; a game that ships only its source locale marks this item N/A and says so
- [ ] Legal requirements met (EULA, privacy policy, age ratings if applicable)
- [ ] Build compiles and packages cleanly

## Workflow tier reductions

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier; items not named keep their status above.
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

- **`full`** — all features + content complete + localization + QA sign-off + smoke (PASS) + no open S1–S3 bugs all required
- **`standard`** — content-complete audit + QA sign-off + localization → recommended; **all features + smoke + no open S1 Critical bugs** required; open S2 High and S3 Medium bugs → recommended
- **`minimal`** — only **smoke + no open S1 Critical bugs** required; everything else **drops**
