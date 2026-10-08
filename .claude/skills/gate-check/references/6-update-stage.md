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
produced, and the gate re-run.

### 6.1 Primary write — `project.yaml`

Set `project.stage` to the new stage name in `project.yaml` at the repo root.

- **If a `project:` block already exists**: Read `project.yaml` first (the Edit
  tool requires the file to have been read in this session), then use the Edit
  tool to change its `stage:` value.
- **If `project.yaml` exists but has no `project:` block**: Read `project.yaml`
  first, then use the Edit tool to insert the block immediately after the
  `framework:` block (before `modes:`). Insert exactly (replace `<new-stage>`):
  ```yaml
  project:
    stage: <new-stage>
  ```
- **If `project.yaml` does not exist at all**: create it with the Write tool using
  this v1.1 minimal template (replace `<new-stage>` and the date):
  ```yaml
  # CCGS project configuration — single source of truth for project settings.
  # Schema: grep the `## <key>` section of .claude/docs/effects-map.md —
  # it is ~31k tokens whole, ~900 per section. Do not open it entire.

  schema_version: 1

  framework:
    version: 1.1.3
    last_upgraded: <YYYY-MM-DD>

  project:
    stage: <new-stage>
  ```
  Do not seed `modes.review_mode` here. It is a rigor-fronted knob — `modes.rigor`
  supplies its value, so an explicit value would shadow the rigor expansion and pin
  the review mode regardless of the project's rigor.

### 6.2 Legacy fallback write — `production/stage.txt`

Also write the single-line stage name (no trailing newline) so hooks that have not
migrated still work. Ensure the `production/` directory exists first:
```bash
mkdir -p production && printf '%s' "Production" > production/stage.txt
```

### 6.3 Verify both writes

After both writes, Read `project.yaml` and `production/stage.txt` and confirm both
show the new stage. If they diverge, report the discrepancy to the user and stop —
a split stage indicator corrupts future auto-detection.

**Always ask before writing**: "Gate passed. May I update `project.stage` in `project.yaml` to 'Production' (and the legacy `production/stage.txt`)?" — on an accepted CONCERNS override, the explicit yes above is that ask.

### 6.4 Rigor-fit check (advisory — never affects the verdict)

After the stage advance is confirmed, apply the raise trigger in
`.claude/docs/settings-guidance.md § 4`: if the new stage is **Production** (or
later) while the resolved `modes.workflow` is `minimal` (the `rigor: minimal`
posture, from the config block above), add one line:

> "You're entering [stage] on `rigor: minimal` — most projects this size run
> `standard`. Revisit with `/settings modes.rigor=standard`?"

Offer it **once**, here at the gate. Route to `/settings` — never change the
setting yourself.

---
