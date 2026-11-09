# Lens: systems design (Sections D, E, G)

Read at the first of Sections D, E or G that runs its specialist step. It is
what the `systems-designer` agent (and `economy-designer`, for costs) checked
there. Read it once; it stays in context for the rest of the run.

## Section D: formulas

- **Every formula is complete**: named expression, the Variables table in the
  skill's columns, Output Range, worked Example. Prose without a table is not a
  formula.
- **Run the boundaries yourself.** For each formula, put every variable at its
  minimum, its maximum and at 0 (level 0, empty inventory, zero stat) and work
  out the result. Flag any input that gives a value the system cannot use: a
  division by zero, a negative cost or damage, an unbounded result, an output
  that makes another variable inert. Show the input that breaks it and offer
  ways to bound it as options; never fix it silently.
- **Registry first.** A value for a registered entity starts from
  `design/registry/entities.yaml`; a different number is a proposed registry
  change, put to the person, never a quiet override.
- **Feedback loops.** Name each positive loop (the rich get richer) and say
  whether it is intended and what damps it.
- **Costs (economy-designer).** For a cost, price or reward: check the curve
  against the progression it sits in (time to afford at early, mid and late
  play), every faucet has a sink, and no item is strictly better at the same
  price. Name the dominant purchase if there is one.
- Output: formulas with reasoning the person can judge, not raw numbers; where
  you chose a number, say why.

## Section E: edge cases

- Walk the rule and formula space from C and D: zero, maximum, out of range,
  two rules at once, the order of simultaneous events, a dependency's floor or
  cap this system could break.
- Look for degenerate strategies: a loop the player can repeat for unbounded
  gain, a choice that is always right.
- Each case is "If [condition]: [exact outcome]". One without a resolution is an
  open question; list it as one.
- Present the found cases and let the person choose which go in.

## Section G: tuning knobs

- Derive the knobs from D's Variables table: every `data file` variable is a
  knob; `constant` ones are not.
- For each: safe range, what breaks too high, what breaks too low.
- Name knobs that interact (changing A makes B inert) and say so in both rows.
- A knob owned by a dependency GDD is pointed to, not duplicated.

## Limits

No high-level design direction (the person and the concept own it), no level
or encounter layout, no narrative or art choices, no code.
