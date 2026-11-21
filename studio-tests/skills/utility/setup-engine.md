# Skill Test Spec: /setup-engine

## Skill Summary

`/setup-engine` pins the project's engine, version and language. It accepts
`[engine]`, `[engine] [version]`, `refresh`, `upgrade [old] [new]`, or no
argument for guided selection: an existing project keeps its engine, and a new
one with no engine named is offered web first. For Godot it asks which language (GDScript, C#
or Both) before showing the Technology Stack. It then:

- writes the Technology Stack and the `ENGINE-REFERENCE-IMPORT` line to
  `CLAUDE.md` after "May I write these engine settings to `CLAUDE.md`?"
- fills `.claude/docs/technical-preferences.md` (the legacy mirror: naming
  conventions, specialist routing table, input/platform, performance budgets)
  after the user approves the presented defaults
- dual-writes the `engine`, `specialists`, `naming` and `commands` blocks to
  `project.yaml` — the primary config store — after "May I write the `engine`,
  `specialists`, `naming`, and `commands` blocks to `project.yaml`?"
- updates or creates `docs/engine-reference/<engine>/`, scaffolds
  `project.godot` for Godot (never for Unity or Unreal), and reads everything
  back with `project-coherence.sh`

On a re-run it edits existing `project.yaml` blocks in place rather than
duplicating them. No director gates apply. The verdict is COMPLETE when the
engine is configured.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" language before writing `CLAUDE.md` and before writing the `project.yaml` blocks
- [ ] Has a next-step handoff (Section 12 prints one Next-Steps list in `/next-step`'s order: `/prototype` first when there is no game yet, studio mode added at `standard` and `full`)

---

## Director Gate Checks

None. `/setup-engine` is a technical configuration skill. No director gates apply.

---

## Fixture Defaults

Every case's `project.yaml` sets `modes.rigor: minimal` and
`modes.automation: collaborative`, with no `project.local.yaml`, unless its own
Fixture says otherwise. Rules: `studio-tests/CLAUDE.md` §
Fixture defaults.

---

## Test Cases

### Case 1: Godot 4 + GDScript — Full engine configuration

**Fixture:**
- `project.yaml` has no `engine` block; `technical-preferences.md` holds only placeholders
- No `design/gdd/game-concept.md` and no `design/game-brief.md`
- `docs/engine-reference/godot/VERSION.md` already pins 4.7
- No `project.godot` at the repo root; the user approves every write

**Input:** `/setup-engine godot 4.7`

**Expected behavior:**
1. Full-spec mode: Section 2's guided selection is skipped
2. Skill asks the Godot language question (A GDScript / B C# / C Both); user picks GDScript
3. Skill shows the Technology Stack and asks "May I write these engine settings to `CLAUDE.md`?"
4. Technical preferences are presented with GDScript naming (snake_case files and
   variables) and the A3 routing table: `.gd` → godot-gdscript-specialist,
   `.gdshader` → godot-shader-specialist, `.tscn` → godot-specialist
5. Because Section 2 never ran and no design artifact exists, the skill asks
   the project-shape question (2D/3D, web or not) instead of writing
   `Forward+`/`Jolt` from the engine name
6. `commands.build` export preset is asked, never defaulted; `commands.test` is
   the gdUnit4 `GdUnitCmdTool.gd` command
7. Skill asks "May I write the `engine`, `specialists`, `naming`, and `commands` blocks to `project.yaml`?"
8. Section 6 reads its coverage table: 4.7 is beyond the Godot row (~4.3), so
   the knowledge risk is HIGH
9. VERSION.md already pins 4.7 → nothing to regenerate; only its
   `Installed at pin time` row is written, from the Section 3 probe
10. Skill proposes `project.godot` and asks before creating it; verdict COMPLETE

**Assertions:**
- [ ] `engine.name` is Godot and `engine.language` is GDScript in `project.yaml`
- [ ] `naming.variables` and `naming.files` are `snake_case`
- [ ] Routing table includes `.gd`, `.gdshader`, and `.tscn` entries; `specialists.code` is `godot-gdscript-specialist`
- [ ] The rendering/physics shape is asked, not inferred from the engine name
- [ ] "May I write" is asked before `CLAUDE.md` and before `project.yaml` are written
- [ ] Knowledge Risk is HIGH — the Section 6 table's cutoff is May 2025 and its Godot row ~4.3, as in the shipped VERSION.md
- [ ] Verdict is COMPLETE

---

### Case 2: Unity + C# — Unity-specific configuration

**Fixture:**
- Placeholders only in `technical-preferences.md`; no `engine` block in `project.yaml`
- The user supplies the version and the build target when asked

**Input:** `/setup-engine unity`

**Expected behavior:**
1. Engine-only mode: version looked up and confirmed with the user
2. No language question (Unity is C#); CLAUDE.md Language is `C#`
3. Naming: PascalCase classes/methods, `_camelCase` private fields
4. Routing: `.cs` → unity-specialist, `.shader`/`.shadergraph` → unity-shader-specialist,
   `.unity`/`.prefab` → unity-specialist, `.uxml`/`.uss` → unity-ui-specialist
5. `rendering: URP`, `physics: PhysX` written directly — no shape question
6. `commands.build` target is asked (no hardcoded `StandaloneLinux64`);
   `naming.constants` carries the `# UNVERIFIED` comment
7. No Unity project is scaffolded; the user is told to create it in Unity Hub

**Assertions:**
- [ ] Engine field is set to Unity and Language to C#
- [ ] Naming conventions reflect C# conventions
- [ ] Routing table includes `.cs` and `.unity` entries
- [ ] No project-shape question is asked for Unity
- [ ] No Unity project files are written
- [ ] Verdict is COMPLETE

---

### Case 3: Unreal — C++ primary, Blueprint routed to its specialist

**Fixture:**
- Placeholders only; the user never states that the project is Blueprint-primary
- The session runs on Windows (`uname -s` is neither `Linux` nor `Darwin`), so the Windows `commands` block applies

**Input:** `/setup-engine unreal 5.8`

**Expected behavior:**
1. The primary-language question defaults to C++, so CLAUDE.md Language reads
   `C++ (primary), Blueprint (gameplay prototyping)` — the line follows the
   answer, and a Blueprint-primary answer would write
   `Blueprint (primary), C++ where needed`
2. `project.yaml` gets `engine.language: "C++"` (Blueprint only when the project is Blueprint-primary)
3. Routing: `.uasset` BP classes → ue-blueprint-specialist; `.umap`/`.uasset` → unreal-specialist;
   `specialists.additional` includes ue-blueprint-specialist
4. `commands` are written as single-quoted scalars under a
   `# TODO: confirm these` comment; `engine.path` is recorded
5. Performance budgets are asked via `AskUserQuestion` (set defaults / leave
   `[TO BE CONFIGURED]`), not pre-filled
6. No `.uproject` is scaffolded; verdict COMPLETE

**Assertions:**
- [ ] Engine field is set to Unreal Engine 5.8 and `engine.language` is `C++`
- [ ] Routing table includes `.uasset` and `.umap` entries
- [ ] ue-blueprint-specialist is assigned for Blueprint graphs
- [ ] `commands` carry the `# TODO: confirm these` comment
- [ ] Verdict is COMPLETE

---

### Case 4: Re-run on a Configured Project — blocks edited in place

**Fixture:**
- `project.yaml` already has `engine` (Godot 4.7), `specialists`, `naming`, a
  `modes` block, and a `commands` block missing its `smoke` key
- `project.godot` exists at the repo root
- `docs/engine-reference/godot/VERSION.md` pins 4.7

**Input:** `/setup-engine godot 4.7`

**Expected behavior:**
1. Skill reads `project.yaml` before editing it
2. Each existing block is edited in place; `commands.smoke` is added to the
   partial block; no second copy of any block is appended
3. `modes` and every other non-engine block are preserved untouched
4. The existing `project.godot` is not overwritten — the skill says so and skips
5. VERSION.md pins the same version → nothing to regenerate: Engine Version,
   Project Pinned and Last Docs Verified are left as they are, and only the
   `Installed at pin time` row is written with the Section 3 probe result
6. Verdict COMPLETE

**Assertions:**
- [ ] No block is duplicated in `project.yaml`, and the missing `commands.smoke` key is added
- [ ] `modes` (and all other non-engine content) is unchanged
- [ ] `project.godot` is not overwritten
- [ ] For a same-version pin, Engine Version, Project Pinned and Last Docs Verified are untouched and `Installed at pin time` is written
- [ ] Verdict is COMPLETE

---

### Case 5: Director Gate Check — No gate; setup-engine is a utility skill

**Fixture:**
- Fresh project with no engine configured

**Input:** `/setup-engine godot`

**Expected behavior:**
1. Skill completes full engine configuration
2. No director agents are spawned at any point
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Verdict is COMPLETE without any gate check

---

### Case 6: Installed Editor Older Than the Chosen Version — ask, then record

**Fixture:**
- As Case 1; `docs/engine-reference/godot/VERSION.md` pins 4.7
- `godot --version` reports `4.5.1.stable`
- The user picks "pin the newer one and upgrade later"

**Input:** `/setup-engine godot 4.7`

**Expected behavior:**
1. Section 3 probes the installed editor and finds 4.5.1 — a mismatch
2. Skill states both versions and asks, offering three options: pin the
   installed version, pin the newer one and upgrade later, or pin the newer one
   deliberately
3. The answer is recorded; the skill does not pick for the user
4. VERSION.md already pins 4.7, so nothing is regenerated, but its
   `Installed at pin time` row is written with 4.5.1
5. Verdict COMPLETE

**Assertions:**
- [ ] Both versions are stated and all three options are offered
- [ ] The skill waits for the user's choice rather than picking silently
- [ ] `Installed at pin time` records 4.5.1 — the same-version branch does not skip it
- [ ] Engine Version, Project Pinned and Last Docs Verified are not restamped

---

### Case 7: Godot not on PATH — the probed executable goes into `commands.*`

**Fixture:**
- As Case 1, on Windows; `godot --version` fails — `godot` is not on `PATH`
- The probe finds `C:/Program Files/Godot/Godot_v4.7.2-stable_win64.exe`, which reports `4.7.2.stable`
- The user names the export preset `Windows Desktop`

**Input:** `/setup-engine godot 4.7`

**Expected behavior:**
1. Section 3 reads the version from the executable it found — it does not report "no engine installed"
2. `build`, `test`, `run` and `smoke` each start with the quoted full path, as single-quoted scalars; `build` quotes its preset with double quotes:
   `build: '"C:/Program Files/Godot/Godot_v4.7.2-stable_win64.exe" --headless --export-debug "Windows Desktop"'`
3. `test` keeps `--remote-debug tcp://127.0.0.1:0` and the gdUnit4 runner arguments after the path
4. `engine.path` records the executable
5. Verdict COMPLETE

**Assertions:**
- [ ] No `commands.*` value names bare `godot`
- [ ] Every Godot command value is a single-quoted scalar and none holds both quote types
- [ ] `engine.path` records the editor executable
- [ ] Variant — the probe finds nothing and the user does not know where Godot is: bare `godot` is kept under a `# TODO: godot is not on PATH here` comment, and the skill says the commands will not run until the path is set

---

### Case 8: A skipped question is not an answer

**Fixture:**
- Fresh project: no engine configured, no `project.yaml` engine block
- The engine question comes back skipped: the user closes it, or a headless run
  returns every question as skipped
- The sandbox carries the framework's `CLAUDE.md`. The rule this case checks is
  stated there ("A skipped or dismissed question is not an answer") and in
  `.claude/docs/automation-modes.md`, not in `/setup-engine`'s own files; a rule
  `CLAUDE.md` loads counts as the skill's own (`/skill-test` spec mode, Step 3),
  so a sandbox without it is set up wrong, not a skill FAIL

**Input:** `/setup-engine`

**Expected behavior:**
1. The skill does not choose an engine, language or version itself
2. It asks again in plain text, saying what is waiting on the answer, and waits
3. Nothing is written to `CLAUDE.md`, `project.yaml`, `technical-preferences.md`
   or `VERSION.md` before the user answers
4. In a run where nobody can answer, it stops and reports what is waiting

**Assertions:**
- [ ] No engine, language or version is picked on the user's behalf
- [ ] The question is asked again in plain text
- [ ] No file is written before an answer arrives

---

### Case 9: An existing web project — recorded as it is, no game file changed

**Fixture:**
- A git repository holding a web game committed before Claude Code Game Studios: `package.json`
  (scripts `dev`, `build` = `webpack --config webpack/config.prod.js`, `test` =
  `jest`), `package-lock.json`, `src/`, `tests/score.test.js`, webpack and Jest in
  `devDependencies`, Phaser in `dependencies`, no `tsconfig.json`, no
  `window.game`; Claude Code Game Studios' files added in a later commit; no `node_modules/`
- Variant A — `package.json` has `"workspaces": ["packages/*"]`

**Input:** `/setup-engine web`

**Expected behavior:**
1. Reads the project with `web-detect.sh` and never runs `web-scaffold.sh`
2. Shows the record before writing: npm (from `package-lock.json`); `npm run dev`,
   `npm run build`, `npm test`, smoke = the build; `src/` and `tests/` (nothing
   extra to write); JavaScript; webpack and its version; Jest; Phaser; hook absent
3. Says the reference describes the template's versions, not this project's
4. On a yes, writes only `CLAUDE.md`, `technical-preferences.md` and
   `project.yaml` (`engine.name: "Web"`, webpack's version, `commands`; no
   `rendering`, no `physics`)
5. Asks before `npm ci`, then runs the build and `test-run.sh web`
   (`runner jest`) and keeps one screenshot of the build's `index.html` with
   `--file-access`
6. Offers the hook as one question with `Not now` recommended; adds nothing
   unasked
7. Variant A: says monorepos are not covered and stops, writing nothing

**Assertions:**
- [ ] `git status` after the run lists no file from the game's own commit
- [ ] No scaffold file is copied and no `npm install` runs
- [ ] The commands written are the project's own scripts in npm's form
- [ ] The hook is not added without a yes
- [ ] Variant A writes no file

---

### Case 10: A new project, no engine named — web is offered first

**Fixture:**
- Fresh project: no `engine` block, no `project.godot`, no `ProjectSettings/`,
  no `*.uproject`, no `package.json`; no concept or brief
- Variant A — `design/game-brief.md` says the game is for console and names no engine

**Input:** `/setup-engine`

**Expected behavior:**
1. One line before the question says when Godot, Unity or Unreal fit better
   (a big 3D game, a console or phone-store release, an engine already known)
2. The engine question lists `Web (Recommended)` first, then Godot, Unity and
   Unreal Engine 5; "help me choose" is still open
3. On Web, the skill follows `references/web.md` (the scaffold, W2-W7)
4. Variant A: Web is still listed first but not marked Recommended; Unity or
   Unreal is, and the one line says why from the brief ("console")

**Assertions:**
- [ ] Web is the first option, and marked `(Recommended)` in the base case
- [ ] The one line on Godot, Unity and Unreal comes before the question
- [ ] Nothing is written before the user picks
- [ ] Variant A: Web first, not Recommended; the line cites the brief's console

---

### Case 11: An existing project keeps its engine — web is never offered over it

**Fixture:**
- Variant A — `project.yaml` has `engine.name: "Godot"` (4.7)
- Variant B — no `engine` block, but `project.godot` is at the repo root

**Input:** `/setup-engine`

**Expected behavior:**
1. Variant A: says the engine is Godot and carries on with Godot, as
   `/setup-engine godot`; no engine question
2. Variant B: says it found `project.godot` and carries on with Godot
3. Neither variant offers web or another engine, and neither writes `engine.name`
   as anything but Godot

**Assertions:**
- [ ] No engine question is asked and web is not offered
- [ ] `project.yaml`'s `engine.name` is Godot after the run
- [ ] The output names what told it the engine (`project.yaml` or `project.godot`)

---

## Protocol Compliance

- [ ] Presents draft configuration before asking to write
- [ ] Asks "May I write" before writing `CLAUDE.md` and the `project.yaml` blocks; technical preferences are written only after the user approves the presented defaults
- [ ] Respects engine argument when provided (skips guided selection)
- [ ] Dual-writes `project.yaml` and `technical-preferences.md`, then reads `project.yaml` back to confirm they agree
- [ ] On re-run, edits existing `project.yaml` blocks in place without duplicating them
- [ ] Writes the probed editor path into `commands.*` — for Unity always, for Godot whenever `godot` is not on `PATH` — never a bare executable that does not resolve
- [ ] Never defaults the Godot export preset or the Unity build target — asks for it; Unreal's `commands` are best-effort values matched to the machine's OS (`-platform=Win64` on Windows, `Linux` on Linux) under a `# TODO` comment; on macOS only `build` is written, and `test`, `run` and `smoke` stay TODO lines
- [ ] Writes the Section 3 probe into VERSION.md's `Installed at pin time` row whatever the outcome, after asking "May I record `Installed at pin time: …` in `docs/engine-reference/<engine>/VERSION.md`?"
- [ ] Verdict is COMPLETE after configuration is written

---

## Coverage Notes

- Godot C# and Both follow Case 1 with the A1/A2/A3 variants from
  `references/godot-language-config.md`; not separately tested.
- The `refresh` and `upgrade` subcommands (Sections 10–11) are not tested here.
- The Unreal Linux and macOS `commands` blocks (chosen by `uname -s`) are not
  fixture-tested; Case 3 pins Windows.
- Section 6 is a lookup against the skill's own coverage table, asserted in
  Case 1. The Section 7 reference docs for a version with no reference set yet
  depend on WebSearch results; not assertion-tested.
- A probe that cannot run reports `installed version NOT DETERMINED` — never
  "no engine installed"; not separately tested.
- A Blueprint-primary Unreal answer (`engine.language: "Blueprint"`) follows
  Case 3 with the other Language line; not separately tested.
