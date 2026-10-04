# Migration Guide: v1.0 → v1.1 project.yaml

This guide covers converting an **existing project's config files** to
`project.yaml`. It is distinct from the template-diff instructions in
[UPGRADING.md](../UPGRADING.md) — that file tells you which *skill and agent
files* changed between releases and whether they're safe to overwrite. This
guide covers your *project's own data*: the values you configured in
`production/stage.txt`, `production/review-mode.txt`, and
`.claude/docs/technical-preferences.md`.

If you're setting up a **brand-new** project on v1.1, you don't need this —
`/start` writes `project.yaml` directly and none of the legacy files apply.

---

## Do you need to migrate?

You have a v1.0 project needing migration if `project.yaml` does **not**
exist at your repo root, and at least one of these does:

- `production/stage.txt`
- `production/review-mode.txt`
- `.claude/docs/technical-preferences.md` with real values (a copy still
  full of `[TO BE CONFIGURED]` placeholders is the untouched template
  default, not migratable data, and doesn't count)

Run `/adopt` and it will detect this automatically (Phase 2g) and walk you
through the steps below. You can also run the converter directly.

---

## What gets preserved

| From | To (`project.yaml`) |
|---|---|
| `production/stage.txt` | `project.stage` |
| `production/review-mode.txt` | `modes.review_mode` |
| `technical-preferences.md` → Engine & Language | `engine.name`, `engine.version`, `engine.language`, `engine.rendering`, `engine.physics` |
| `technical-preferences.md` → Input & Platform | `platform.targets`, `platform.primary_input`, `platform.gamepad_support`, `platform.touch_support` |
| `technical-preferences.md` → Naming Conventions | `naming.classes`, `naming.variables`, `naming.constants`, `naming.signals`, `naming.files`, `naming.scenes` |
| `technical-preferences.md` → Performance Budgets | `performance.target_framerate`, `performance.frame_budget_ms`, `performance.draw_call_limit`, `performance.memory_ceiling_mb` |
| `technical-preferences.md` → Testing | `testing.framework`, `qa.coverage_minimum` |
| `technical-preferences.md` → Engine Specialists | `specialists.code`, `specialists.shader`, `specialists.ui`, `specialists.additional` |

Settings that don't exist in v1.0 at all (`modes.rigor`, `qa.level`,
`docs.density`, `team.size`, `modes.story_granularity`, and the rest of the
v1.1 modes system) get their hardcoded v1.1 defaults — there's nothing to
preserve for them.

**One value was renamed:** v1.0's `review-mode.txt: none` ("no director
reviews") becomes `modes.review_mode: solo` in v1.1, which is the same tier
under its new name. The converter maps it and calls it out in the migration
report's Warnings, so you'll see the rename rather than have it happen silently.

**Not migrated, on purpose:** `technical-preferences.md`'s Forbidden Patterns
and Allowed Libraries sections have no `project.yaml` equivalent. The
converter never deletes this file for that reason — see "Finalizing," below.

---

## Running the migration

The conversion is a tested script, not something the AI hand-edits — the
v1.1 plan rated data loss during migration as its highest-severity risk, and
prose migration can't be unit-tested the way a script can. `/adopt` drives
it for you, or you can run it yourself:

```bash
# 1. Preview — writes nothing, just reports what it would do
bash .claude/scripts/migrate-v1-config.sh --dry-run

# 2. Migrate — writes project.yaml + production/migration-report.md
#    Every legacy file is left in place, untouched.
bash .claude/scripts/migrate-v1-config.sh

# 3. Read the report before finalizing
cat production/migration-report.md

# 4. Finalize — deletes legacy files, ONLY after re-verifying each one's
#    value made it into project.yaml. Refuses (exit 4) and deletes nothing
#    on any mismatch.
bash .claude/scripts/migrate-v1-config.sh --finalize
```

Step 4 is optional and separate on purpose. Skipping it is completely fine —
every skill and hook falls back to the legacy files for any key
`project.yaml` doesn't have, so the two can coexist indefinitely. Run it when
you're confident `project.yaml` is correct and want one config file instead
of three.

**`technical-preferences.md` is never deleted**, even with `--finalize` —
Forbidden Patterns and Allowed Libraries still live there and always will,
since v1.1 has no equivalent structure for them yet.

### Reading `production/migration-report.md`

The report has five sections:

- **Source files detected** — which legacy files the converter found
- **Values preserved** — per source file, per setting, what was written to
  `project.yaml`
- **Defaults applied** — new v1.1 settings that had nothing to migrate from
- **Warnings** — anything the converter couldn't parse cleanly (see below)
- **Manual review** — content it found but declined to guess at (e.g. custom
  sections in a forked `technical-preferences.md`)

---

## What can go wrong (and what the script does about it)

| Situation | Behavior |
|---|---|
| A legacy file is malformed / unparsable | Warns per-file, leaves it alone, continues migrating everything else it *can* parse. `project.yaml` gets the values it could read plus defaults for the rest. |
| A parsed value doesn't match a v1.1 enum (e.g. a custom fork's `stage: Alpha`) | Written as-is with a warning comment, flagged for manual resolution — the converter does not silently coerce or drop it. |
| Both `project.yaml` **and** legacy files already exist | Refuses to run (exit code 3). Two sources of truth with no way to know which you last edited is not something the script will guess at — resolve it yourself first (decide which is authoritative, delete or rename the other). |
| Custom sections in a forked `technical-preferences.md` | Logged to the migration report as "not migrated — integrate manually." Nothing is silently dropped. |

If you hit the split-brain case (both present), that usually means you
either ran `/start` on a project that also had old legacy files lying
around, or partially migrated by hand. Pick the one with your real values,
remove or back up the other, then re-run `--dry-run`.

---

## After migrating

1. Spot-check `project.yaml` against your old `technical-preferences.md` —
   engine, naming, and performance values in particular.
2. Run `/settings` to see the effective config the way skills will read it.
3. Everything else in the framework works identically whether or not you've
   run `--finalize` — there's no rush.

For the new settings that didn't exist in v1.0 (`modes.rigor` above all),
see the [Configuration section of the README](../README.md#configuration)
and the full spec in `.claude/docs/effects-map.md`.
