# /gate-check — Section 6: Update Stage on PASS

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 6. Update Stage on PASS

When the verdict is **PASS** and the user confirms they want to advance, write the
new stage to BOTH `project.yaml` and the legacy `production/stage.txt`.

**On CONCERNS, the user may override — explicitly.** Do not offer the stage
write by default. If the user asks to advance anyway, list every concern and
ask: "The gate returned CONCERNS. Accept these risks — [list] — and may I update
`project.stage` in `project.yaml` to '[stage]' (and the legacy
`production/stage.txt`)?" Only on an explicit yes, add the `### Accepted Risks`
section to the gate report (each concern, accepted by the user, with the date)
and write the stage as below. **A FAIL is never overridden into a stage change, and
neither is NOT ASSESSED** — the blockers must be fixed, or the missing input
produced, and the gate re-run. That holds inside a CONCERNS verdict too: CONCERNS
outranks NOT ASSESSED in the verdict, but while any required check is NOT ASSESSED
the override is not offered. Name each such check and what would let it run.

### 6.1 Write the stage

After the yes, write both stage files with one command (quote a two-word stage):

```bash
bash .claude/scripts/set-stage.sh "<new-stage>"
```

It sets `project.stage` in `project.yaml`: it edits the `stage:` line, adds a
`project:` block after `framework:` when there is none, or creates the file from
the minimal template when there is no `project.yaml`. It keeps comments, other
keys and line endings. It also writes the legacy `production/stage.txt`, so hooks
that have not migrated still work, then reads both files back. It never seeds
`modes.review_mode`: `modes.rigor` supplies that, and an explicit value would pin
the review mode whatever the project's rigor.

### 6.2 Verify both writes

Show its `stage_yaml` and `stage_txt` rows. Exit 0 means both files hold the new
stage. Exit 4 means they disagree after writing: report the discrepancy to the
user and stop, because a split stage indicator corrupts future auto-detection.
Exit 5 means `project.yaml` has a layout the script will not edit (`project:` as
a one-line value): nothing was written, so say so and edit `project.yaml` with
the user's yes. Any other non-zero exit: report the message and stop.

**Always ask before writing**: "Gate passed. May I update `project.stage` in `project.yaml` to 'Production' (and the legacy `production/stage.txt`)?" — on an accepted CONCERNS override, the explicit yes above is that ask.

### 6.3 Rigor-fit check (advisory — never affects the verdict)

After the stage advance is confirmed, apply the raise trigger in
`.claude/docs/settings-guidance.md § 4`: if the new stage is **Production** (or
later) while the resolved `modes.workflow` is `minimal` (the `rigor: minimal`
posture, from the config block above), add one line:

> "You're entering [stage] on `rigor: minimal` — most projects this size run
> `standard`. Revisit with `/settings modes.rigor=standard`?"

Offer it **once**, here at the gate. Route to `/settings` — never change the
setting yourself.

---
