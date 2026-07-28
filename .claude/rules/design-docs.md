---
paths:
  - "design/gdd/**"
---

# Design Document Rules

- Every design document MUST contain these 8 sections: Overview, Player Fantasy, Detailed Rules, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria
- Formulas must include variable definitions, expected value ranges, and example calculations
- Edge cases must explicitly state what happens, not just "handle gracefully"
- Dependencies must be bidirectional — if system A depends on B, B's doc must mention A
- Tuning knobs must specify safe ranges and what gameplay aspect they affect
- Acceptance criteria must be testable — a QA tester must be able to verify pass/fail
- No hand-waving: "the system should feel good" is not a valid specification
- Balance values must link to their source formula or rationale
- Provenance claims must be verifiable: a value may only be labeled
  "playtest-validated" / "from the prototype" if the cited report contains an
  actual finding about THAT value — cite the specific finding per value.
  Values carried over from prototype config without a positive finding, and
  invented defaults, must be labeled `[assumption]` until a playtest confirms
  them. Blanket claims like "all values come from the prototype" are forbidden
  (this pattern caused defects in 3 GDD reviews: building-system, camera-input
  ×2 — see review logs)
- Design documents MUST be written incrementally: create skeleton first, then fill
  each section one at a time with user approval between sections. Write each
  approved section to the file immediately to persist decisions and manage context
