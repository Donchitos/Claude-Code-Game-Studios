## Release Checklist: [Version] -- [Platform]

Generated: [Date]

### Codebase Health
- Scanned: [N] source files (or `NOT ASSESSED — [reason]`, per Phase 3)
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
- Open bugs (`production/qa/bugs/`): [N] S1, [N] S2, [N] S3 -- or `NOT ASSESSED — no bug records`
- [ ] Zero open S1 (Critical) bugs
- [ ] Zero open S2 (High) bugs, no exceptions -- this row at `workflow: full` only; at `standard`/`minimal` open S2 bugs go in the Rationale as risks
- [ ] Zero S3 (Medium) bugs open, no exceptions -- this row at `workflow: full` only; at `standard`/`minimal` open S3 bugs go in the Rationale as risks
- [ ] All critical path features tested and signed off by QA
- [ ] Performance within budgets:
  - [ ] Target FPS met on minimum spec hardware
  - [ ] Memory usage within budget
  - [ ] Load times within budget
  - [ ] No memory leaks over extended play sessions
- [ ] No regression from previous build
- [ ] Soak test passed (4+ hours continuous play)

> The release gate (`/gate-check release`) blocks any open S1–S3 bug at `workflow: full`,
> with no exceptions; at `standard` and `minimal` it blocks open S1 only, and an open
> S2 or S3 is a risk to record in the Rationale.

### Content Complete
- [ ] All placeholder assets replaced with final versions
- [ ] All TODO/FIXME in content files resolved or documented
- [ ] All player-facing text proofread
- [ ] All text localization-ready (no hardcoded strings)
- [ ] Audio mix finalized and approved
- [ ] Credits complete and accurate

[Platform Requirements: one block per device the platform argument names (`pc`, `console`, `mobile`; `all` is all three), copied from `release-platform-requirements.md`]

[Certification: the one block for this project's `platform.cert_tier`, copied from `certification-none.md`, `certification-itch.md`, `certification-steam.md` or `certification-console.md`; `certification-unknown.md` when the tier cannot be determined]

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

### Go / No-Go: [READY / NOT ASSESSED / NOT READY]

First match wins: **NOT READY** if any blocking item fails; else **NOT ASSESSED**
if any section or item came out `NOT ASSESSED` (name each one); else **READY**. NOT
ASSESSED outranks READY — an unassessed section is not a passed one — and ranks
below NOT READY, so a known blocker is never buried behind it.

**Rationale:**
[Summary of readiness assessment. List any blocking items that must be
resolved before launch. If NOT READY, list the specific items that need
resolution and estimated time to address them.]

**Sign-offs Required:**
- [ ] QA Lead
- [ ] Technical Director
- [ ] Producer
- [ ] Creative Director
