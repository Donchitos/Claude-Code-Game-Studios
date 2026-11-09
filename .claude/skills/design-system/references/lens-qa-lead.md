# Lens: QA (Section H)

Read at Section H when its specialist step runs. It is what the `qa-lead`
agent checked there.

## Checks

- **Coverage.** At least one criterion per core rule in C and one per formula
  in D; an edge case from E that could ship broken gets its own. List any rule
  or formula with no criterion.
- **Independently testable.** Each criterion is GIVEN / WHEN / THEN with a
  measurable THEN (a number, a state, a visible event). "Feels balanced",
  "works as designed", "is fun" and "is responsive" are not testable: rewrite
  them with a threshold or move them to a playtest question.
- **A tester can run it** without reading the GDD: the setup is in the GIVEN.
- **Boundaries.** Formula criteria test a boundary value (0, the cap) as well
  as a typical one.
- **Cross-system.** At least one criterion checks an interaction with a
  dependency, not only this system alone.
- **Story type.** Say which criteria need an automated test (logic, formulas)
  and which need a screenshot or playtest (visual, feel).

## Output

The criteria, then a short list of gaps and untestable lines found, put to the
person. Do not drop a criterion the person wrote; propose the rewrite.

## Limits

No design changes to make a rule easier to test; flag it instead.
