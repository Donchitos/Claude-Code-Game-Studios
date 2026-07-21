# Release Checklist: [Version] -- [Platform]

**Release Date**: [Target Date]
**Release Manager**: [Name]
**Status**: [ ] GO / [ ] NO-GO

---

## Build Verification

- [ ] Clean build succeeds on all target platforms
- [ ] No compiler warnings (zero-warning policy)
- [ ] Build version number set correctly: `[version]`
- [ ] Build is reproducible from tagged commit: `[commit hash]`
- [ ] Build size within budget: [actual] / [budget]
- [ ] All assets included and loading correctly
- [ ] No debug/development features enabled in release build

---

## Quality Gates

### Critical Bugs
- [ ] Zero S1 (Critical) bugs open
- [ ] Zero S2 (Major) bugs -- or documented exceptions below:

| Bug ID | Description | Exception Rationale | Approved By |
| ---- | ---- | ---- | ---- |
| | | | |

### Test Coverage
- [ ] All critical path features tested and signed off
- [ ] Full regression suite passed: [pass rate]%
- [ ] Soak test passed (4+ hours continuous play)
- [ ] Edge case testing complete

### Performance
- [ ] Target FPS met on minimum spec: [actual] / [target] FPS
- [ ] Memory usage within budget: [actual] / [budget] MB
- [ ] Load times within budget: [actual] / [target] seconds
- [ ] No memory leaks over extended play (soak test)
- [ ] No frame drops below [threshold] in normal gameplay

---

## Content Complete

- [ ] All placeholder assets replaced with final versions
- [ ] All player-facing text proofread
- [ ] All text localization-ready (no hardcoded strings)
- [ ] Localization complete for: [list locales]
- [ ] Audio mix finalized and approved
- [ ] Credits complete and accurate
- [ ] Legal notices and third-party attributions complete

---

## Platform: PC

- [ ] Minimum and recommended specs documented
- [ ] Keyboard+mouse controls fully functional
- [ ] Controller support tested (Xbox, PlayStation, generic)
- [ ] Resolution scaling tested: 1080p, 1440p, 4K, ultrawide
- [ ] Windowed, borderless, fullscreen modes working
- [ ] Graphics settings save and load correctly
- [ ] Store SDK integrated and tested: [Steam/Epic/GOG]
- [ ] Achievements functional
- [ ] Cloud saves functional

## Platform: Console (if applicable)

- [ ] TRC/TCR/Lotcheck requirements met
- [ ] Platform controller prompts correct
- [ ] Suspend/resume works
- [ ] User switching handled
- [ ] Network loss handled gracefully
- [ ] Storage full scenario handled
- [ ] Parental controls respected
- [ ] Certification submission prepared

---

## Store and Distribution

- [ ] Store page metadata complete and proofread
- [ ] Screenshots current and meet platform requirements
- [ ] Trailer current
- [ ] Key art and capsule images final
- [ ] Age ratings obtained: [ ] ESRB [ ] PEGI [ ] Other
- [ ] Legal: EULA, Privacy Policy, Terms of Service
- [ ] Pricing configured for all regions

---

## Launch Readiness

- [ ] Analytics/telemetry verified and receiving data
- [ ] Crash reporting configured: [service name]
- [ ] Day-one patch prepared (if needed)
- [ ] On-call team schedule set for first 72 hours
- [ ] Community announcements drafted
- [ ] Press/influencer keys prepared
- [ ] Support team briefed on known issues
- [ ] Rollback plan documented and tested

---

## Sign-offs

| Role | Name | Status | Date |
| ---- | ---- | ---- | ---- |
| QA Lead | | [ ] Approved | |
| Technical Director | | [ ] Approved | |
| Producer | | [ ] Approved | |
| Creative Director | | [ ] Approved | |

---

## Final Decision

**GO / NO-GO**: ____________

**Rationale**: [Summary of readiness. If NO-GO, list specific blocking items and estimated time to resolve.]

**Notes**: [Any additional context, known risks accepted, or conditions on the release.]
