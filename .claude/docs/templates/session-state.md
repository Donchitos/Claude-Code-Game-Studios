# Active Session State — [project or branch]

<!--
  THE CONTRACT. Read this before editing the file or any hook that consumes it.

  This file has TWO regions and they are not interchangeable:

    1. The CHECKPOINT region below (STATUS + CHECKPOINT blocks) is the part
       machines read. session-start.sh shows it verbatim in the context, so it is
       BOUNDED BY CONSTRUCTION: keep it under ~25 lines. It is OVERWRITTEN on
       every update, never appended to.

    2. Everything after `<!-- /CHECKPOINT -->` is free-form narrative for humans
       and for a returning agent that wants detail. No hook ever injects it, so
       it may grow — but see Rotation below.

  Why the split exists: before it, `active.md` was one append-only file doing
  both jobs. It reached 712 lines / 44 KB, and each consumer invented its own
  slice of it — the status line parsed for a STATUS block nothing wrote,
  pre-compact injected `head -100` (12.7 KB), and session-start previewed
  `tail -20`, the opposite end. They disagreed because there was no contract to
  agree on. Now every consumer reads the named region.

  ROTATION. When the narrative below grows past ~200 lines, move it to
  `production/session-logs/` and start it fresh:
      bash .claude/scripts/rotate-session-state.sh
  Nothing is lost — and the commit history already records most of what the
  narrative repeats.
-->

<!-- STATUS -->
Epic:
Feature:
Task:
<!-- /STATUS -->

<!-- CHECKPOINT -->
**Updated:** [YYYY-MM-DD]
**Branch:** `[branch]`
**Current task:** [one line — what is actively being worked on]
**Next step:** [one line — the very next action, concrete enough to resume cold]
**Blocked on:** [one line, or `nothing`]
**Files in progress:** [paths, comma-separated, or `none`]
**Run result:** [`/dev-story` writes its `Run result:` line here, verbatim, for `/story-done` to read; other writers leave this line out]
**Open questions:** [one line each, or `none`]
<!-- /CHECKPOINT -->

---

## Notes

[Free-form. Decisions and their rationale, what was tried and rejected, context
that would be expensive to reconstruct. Not machine-read — write for the person
or agent picking this up cold.]

<!--
  FIELD NOTES

  STATUS block
    Drives the status-line breadcrumb (`Combat System > Melee > Hitboxes`), and
    only at Production / Polish / Release stage. All three fields are optional —
    leave a field blank when it does not apply, and blank all three when there is
    no active focus. Do not delete the markers themselves — `statusline.sh`
    expects them to exist.

  CHECKPOINT block
    The recovery payload. `session-start.sh` shows it when a previous session
    left state, and again after a compaction (SessionStart runs then too).
    `pre-compact.sh` reads it as well, for the debug log. Both read THIS
    region and nothing else, which is what keeps the cost fixed no matter how
    long the narrative gets.

    Write it so a cold reader can resume without reading anything else. "Current
    task: fixing the thing" is useless; "Current task: wiring modes.rigor into
    /gate-check section 6.4" is not.
-->
