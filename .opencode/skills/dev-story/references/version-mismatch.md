# Phase 2: When the ADR or the manifest changed after the story was written

Read only when Phase 2 found a version mismatch.

## The ADR

The ADR's `version` (from `adr-status.sh`: its Last Verified date, else its Date,
else `unversioned`) differs from the story's `ADR Version`, or the ADR is
`unversioned` while the story names a date. Its decision may have changed.

Ask: "Story was written against ADR v[story date]. The ADR is now v[current].
How do you want to go on?" Options:

- **Re-read the changed ADR and refresh the story (Recommended).** Read the ADR's
  Decision, Engine Compatibility and ADR Dependencies sections with
  `bash .claude/scripts/md-section.sh extract <adr> "Decision"` and the same for
  the other two. Then edit the story: `ADR Version` becomes the ADR's `version`
  (never today's date, or the next run mismatches again), and the ADR Decision
  Summary and `## Implementation Notes` are replaced with the guidance you read.
  The programmer's brief carries the new guidance, never the old summary.
- **Implement from the story's summary — I accept the drift.** The brief carries the
  summary and tells the agent it predates the current ADR. Note it under Deviations.
- **Stop — I want to review the ADR first.** No agent runs.

## The control manifest

The story's `Manifest Version` differs from the manifest's. New rules may apply.

Ask: "Story was written against manifest v[story date]. The current manifest is
v[current]. How do you want to go on?" Options:

- **Update the story's manifest version and use the current rules (Recommended).**
  Set the story's `Manifest Version` to the current date, then read the layer's
  rules for the brief.
- **Use the old rules — I accept the risk.** Set `Manifest Version` to the current
  date and add `Manifest-Note: Proceeded with old manifest rules on [date] —
  non-compliance risk accepted.` to the story header. Note it under Deviations;
  `/story-done` carries the note into its deviations.
- **Stop — I want to review the manifest first.** No agent runs.

Each option names the story edit it makes, so choosing it is the ask.
