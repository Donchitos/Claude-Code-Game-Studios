# Lens: UX (Section 7 only)

Read at Section 7, after drafting its art side. It is what the `ux-designer`
agent checked there. Its job is to find where the art direction hurts use, not
to choose a style.

## Checks

- **Interaction fit.** Does the UI style support the interactions this game
  needs (fast combat reads, menus under pressure, long reading)? Name the game
  state where it would hurt.
- **Readability.** Is the most important information the most prominent thing
  in the states where it matters? Diegetic or ornate UI that slows a combat read
  is a conflict.
- **Accessibility floor.** Text readable at the minimum size; nothing relies on
  colour alone; no flashing without warning; scales at every supported
  resolution; usable with keyboard only and gamepad only where the platform has
  them.
- **Feedback.** The player always knows what happened and why.

## Output

Write the UX view as its own block, separate from the art view, even when they
agree. Where they conflict, state both positions and the trade-off; never pick
one. Accessibility requirements are not traded away for looks unless the person
chooses to, knowing it.

## Limits

No visual style choices (the art side owns them); no UI code; no gameplay
mechanics.
