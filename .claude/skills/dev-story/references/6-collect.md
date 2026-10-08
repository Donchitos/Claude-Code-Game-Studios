# /dev-story — Phase 6: Collect and Summarise

> Part of `/dev-story`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 6: Collect and Summarise

**In this file:**

- First: did the agent actually finish?
- Then collect:

### First: did the agent actually finish?

**Do not assume completion.** A programmer agent can stop at its turn limit
mid-edit, and the work it leaves behind can be syntactically broken — a helper
called but never defined, an import half-moved. Its partial report reads like
progress, and this phase's summary would print "Implementation Complete" over
code that does not load.

Before collecting anything:

1. **Check the agent's own terminal state.** If it reported stopping early, hit a
   turn/step limit, or its report ends mid-task, treat the story as **INCOMPLETE**.
2. **Verify the output parses.** Run the check whose **exit code** answers the
   question — an exit 0 from a command that does not check is how broken code
   gets reported as clean:
   - **Godot:** `godot --headless --path . --import` once (it builds the class
     cache), then one run over every `.gd` the story added or changed:
     `godot --headless --path . -s res://.claude/scripts/godot-parse-check.gd -- res://<file>.gd …`.
     For `godot`, use the executable `commands.test` names, else the editor
     `engine.path` records, else `godot` on `PATH`; if none resolves, write
     `parse NOT VERIFIED — Godot executable not found`.
     Exit 1 means a script did not load — its `PARSE FAIL:` line names it, with
     Godot's error above. Do not use `--check-only`: it fails valid code that
     names an autoload. `--import` and `--quit-after` on their own exit 0 on a
     parse error — they are not parse checks.
   - **Unity:** `commands.smoke` (`-batchmode -quit -projectPath . -logFile -`)
     — exit 1 with `error CS…` lines when a script does not compile.
   - **Unreal:** build the editor target —
     `"<UE root>/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" <Project>Editor Win64 Development -Project="<absolute path>/<Project>.uproject"`
     on Windows; on Linux `"<UE root>/Engine/Build/BatchFiles/Linux/Build.sh" <Project>Editor Linux Development -Project=…`,
     on macOS `…/Mac/Build.sh <Project>Editor Mac Development -Project=…` (from Epic's
     documentation — `docs/engine-reference/unreal/current-best-practices.md`, "Command Line").
     A compile error fails the build (`Result: Failed`, non-zero exit).
   Report what you ran, its exit code, and any error lines.
3. If the engine binary is unavailable, write **`parse NOT VERIFIED — engine
   binary not available`**. Do not infer that the code is fine because it reads
   correctly; that inference is exactly what this step exists to replace.
4. **Run it and look.** A parse check is not a run. For every story that
   changes something a player can see — every Visual/Feel and UI story, and any
   Logic, Integration or Config/Data story with a surface — launch the build
   via `commands.run`, straight into the scene or map the story touched, and
   retain a screenshot under `production/qa/evidence/[story-slug]/`. Then
   `Read` the image and compare it to the acceptance criteria: clipped text,
   an overflowing panel, a missing element are defects, and this is the only
   step that finds them. Procedure per engine, including how to capture
   unattended in Godot, Unity and Unreal: `.claude/docs/run-and-observe.md`.
   **On Unity** the capture needs the `ScreenshotOnArg.cs` script that file gives
   verbatim. If the project has none (Glob `Assets/**/ScreenshotOnArg.cs`), ask
   "May I write `Assets/Scripts/ScreenshotOnArg.cs`?" and write it exactly as
   given there before launching; if the user declines, nothing can capture —
   report `Run result: NOT VERIFIED — ScreenshotOnArg.cs not written`.
   Report exactly one line — `Run result: OBSERVED — <what was on screen>`
   with the retained path, `Run result: NOT VERIFIED — <reason>`, or
   `Run result: N/A — <reason>` for a story with genuinely nothing observable.
   **`NOT VERIFIED` is a blocker at the default gate level for Visual/Feel and
   UI, not a note** — `/story-done` reads this line. This step is **not waived
   at `qa.level: minimal`**; tests are, the look is not.

**If INCOMPLETE:** say so as the headline, list what exists so far, name the
specific breakage, and offer to resume the agent. Do **not** emit
"Implementation Complete", and do not advance the story's status.

### Then collect:

- Files created or modified (with paths)
- **Verification result** — what was run, and its outcome (or why it could not run)
- Test file created (path and number of test functions written) — **or**, at
  `qa.level: minimal`, the waiver line from Phase 5
- Any deviations from the story's Out of Scope boundary (flag these)
- Any questions or blockers the agent surfaced
- Any engine-specific risks the specialist flagged

Present a concise implementation summary:

```
## Implementation Complete: [Story Title]

**Files changed**:
- `<code root>/[path]` — created / modified ([brief description])
- `tests/[path]` — test file ([N] test functions) — *omit this line at
  `qa.level: minimal` and print the Phase 5 waiver line instead (Logic/Integration)*

**Verification**: [what was run] — [result, or `NOT VERIFIED — <reason>`]
**Run result**: [`OBSERVED — <what was on screen>` + retained path | `NOT VERIFIED — <reason>` | `N/A — <reason>`] — see `.claude/docs/run-and-observe.md`

**Acceptance criteria covered**:
- [x] [criterion] — implemented in [file:function]
- [x] [criterion] — covered by test [test_name]
- [x] [criterion] — OBSERVED in `production/qa/evidence/[slug]/01-[what].png` (Visual/UI look)
- [ ] [criterion] — DEFERRED: requires playtest (Visual/Feel *feel* — timing, weight; a still cannot show it)

**Deviations from scope**: [None] or [list files touched outside story boundary]
**Engine risks flagged**: [None] or [specialist finding]
**Blockers**: [None] or [describe]

**Before running `/story-done`:** run your test suite locally and confirm the tests you wrote pass. *(At `qa.level: minimal` no tests were written — print the Phase 5 waiver line here instead of this paragraph for a Logic or Integration story, and omit both for any other type. Telling a user to confirm the passing of tests that do not exist is worse than saying nothing.)* **`/story-done` does NOT re-run them** — its Phase 3 checks that the test FILE exists, with `Glob`, and nothing executes it. A test that exists and fails satisfies that gate. Nothing downstream makes the local run safe to skip. Pass/fail is established by `/gate-check` and `/smoke-check`, both of which execute a suite — and both come later than story closure.

Ready for: `/story-done [story-path]` — at `standard`/`full`, `/code-review [file1] [file2]` first
```

---
