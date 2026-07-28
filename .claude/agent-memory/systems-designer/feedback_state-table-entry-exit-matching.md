---
name: feedback-state-table-entry-exit-matching
description: In a markdown States/Transitions table, a state's Exit column must name the SAME condition that the state(s) it transitions into list in their Entry column — mismatched wording between adjacent rows is a real transition-definition bug, not prose variance
metadata:
  type: feedback
---

When a GDD documents a state machine as a markdown table (State | Entry |
Exit | Behavior), each row's Exit condition is really describing an edge
TO another row. Read the table as a graph, not as independent rows: for
every Exit condition, find the row(s) whose Entry condition should describe
the same edge, and verify the wording actually matches (same trigger, same
precondition). If state B's Entry is worded differently from state A's Exit
even though both are clearly describing "A transitions to B," that mismatch
usually hides a real ambiguity — e.g., can B be entered from a state OTHER
than the one described by A's Exit wording? Can A remain active past the
point where B has already been entered?

**Why:** Found in `design/gdd/needs-mood-system.md` (2026-07-10 first full
review), per-need state table (Satisfied / Urgent / Recovering). The
`Urgent` row's Exit is worded "Recovery raises value above it [the
urgency_threshold]" — a value-crossing condition. The `Recovering` row's
Entry is worded "Villager AI reports a recovery activity for this need" — an
external-report condition, with NO value precondition attached in this GDD's
own table (the actual precondition — recovery is only ever reported while
the need is already Urgent — lives in a DIFFERENT GDD, villager-ai-
behavior.md's Rule 12, not in this table at all). Because the two wordings
don't match, the table leaves unstated: (a) whether Urgent and Recovering
can be simultaneously active during the low part of a recovery ramp (very
plausible — the very first tick(s) of any low-rate recovery can leave the
value still at/below urgency_threshold), and (b) what happens if a low-rate
recovery is interrupted before the value ever climbs back above
urgency_threshold — Edge Case 1 and its AC (13) only specify the case where
interruption lands the value ABOVE the threshold, leaving the below-
threshold interruption case as a genuine, unaddressed gap.

**How to apply:** For every state-transition table (3+ states) under
adversarial review: (1) list each row's Exit condition, (2) list each row's
Entry condition, (3) pair them up by which edge they describe, (4) flag any
pair where the wording differs in a way that changes WHEN the transition can
fire — not just cosmetic rephrasing. Also check whether the precondition for
entering a state lives entirely in a DIFFERENT GDD (the consuming system)
rather than in the owning GDD's own table — that's a sign the owning
document's state machine is incomplete on its own terms, even if the
overall system behaves correctly once both docs are read together. Related:
[[feedback-directional-asymmetry-check]] (same "read the transition from
both ends" instinct, applied there to bidirectional load/unload rather than
a 3-state cycle).
