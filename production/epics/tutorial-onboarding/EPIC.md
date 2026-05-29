# Epic: Tutorial / Onboarding

> **Layer**: Presentation (VS milestone)
> **GDD**: design/gdd/tutorial-onboarding.md
> **Architecture Module**: Tutorial / Onboarding (Presentation client + Feature server state)
> **Status**: Ready
> **Stories**: 2/2 Complete

## Overview

Tutorial / Onboarding guides new players through their first experience: account creation, basic movement and combat controls, the deck-building system, and completing their first match (against bots). Tutorial state is tracked server-side in `player_profiles.tutorial_state` to survive reinstalls. Tutorial completion awards starter coins and unlocks the default deck for the starter character. The tutorial is skippable after the first screen. Remote Config controls the tutorial flow version (A/B test capability). Tutorial matches use Bot AI opponents with reduced difficulty.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0006: Client State Management | ProfileStore provides tutorial_state; tutorial_complete flag | LOW |
| ADR-0012: Session & Match Lifecycle | Tutorial match is a standard session with all-bot opponents | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0006 ✅, ADR-0012 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/tutorial-onboarding.md` verified
- New player sees tutorial on first launch; sees normal Main Menu on second launch
- Tutorial state persists after app reinstall (server-side storage)
- Tutorial match uses bot opponents at reduced difficulty setting
- Tutorial completion grants starter coins (idempotent — re-running tutorial does not re-grant)
- "Skip" button works from the first screen; skips directly to Main Menu

## Next Step

Run `/create-stories tutorial-onboarding` to break this epic into implementable stories.
