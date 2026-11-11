# Skill Test Spec: /new-game

## Skill Summary

`/new-game` is the Dont-Know-Studios studio addition (`STUDIO.md`). It gives a
new game its own repo, cloned from the studio template's newest studio release
with history kept, so studio updates merge with a plain `git merge`. The
frontmatter injects `studio-check.sh`'s rows (role, origin, template remote,
studio repo, studio version). Phase 1 routes by role: `template` and
`upstream-clone` go on; `game` points to `/start` or `/prototype` and stops
COMPLETE; `unknown` and `no-git` stop NOT ASSESSED. Phase 2 asks for the game's
name and has the user create an empty repo (Claude cannot create GitHub repos),
then asks for its URL. Phase 3 asks "May I run `bash tools/new-game.sh <name>
<url>`?" and runs it only on yes; a failed run stops BLOCKED with the script's
message. Phase 4 hands off to `/start` in the new folder. It never writes game
files in, commits in, or pushes from the template checkout, and never suggests
GitHub's "Use this template" button.

`/start` and `/prototype` carry the matching guard: `studio-check.sh --guard`,
injected after their frontmatter, prints an instruction block only in the
template repo, telling them to stop and start `/new-game`.

---

## Static Assertions (Structural)

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED, NOT ASSESSED
- [ ] Asks "May I run" before `tools/new-game.sh`
- [ ] Has a next-step handoff at the end (Phase 4: `/start` in the new folder)
- [ ] `allowed-tools` holds no Write or Edit
- [ ] `.claude/skills/start/SKILL.md` and `.claude/skills/prototype/SKILL.md` each inject `studio-check.sh" --guard` and list it in `allowed-tools`

---

## Director Gate Checks

None. `/new-game` makes no design or technical decision.

---

## Fixture Defaults

- A git checkout with `.claude/studio.conf` holding
  `STUDIO_REPO=Dont-Know-Studios/Claude-Code-Game-Studios` and
  `UPSTREAM_REPO=Donchitos/Claude-Code-Game-Studios`
- `origin` as each case says; no `template` remote unless stated

---

## Test Cases

### Case 1: Happy path — the template repo, the user runs it

**Fixture:** `origin` = `https://github.com/Dont-Know-Studios/Claude-Code-Game-Studios.git`

**Input:** `/new-game` then name `sheep-herder`, URL
`https://github.com/Dont-Know-Studios/sheep-herder.git`, `Yes, run it`; the
script exits 0

**Expected behavior:**
1. Role `template` → Phase 2
2. Asks for the name, then gives the empty-repo instructions (owner
   Dont-Know-Studios, README/.gitignore/licence unticked, the `gh repo create`
   line) and asks for the URL
3. Asks "May I run `bash tools/new-game.sh sheep-herder <url>`?" naming
   `../sheep-herder`
4. Runs it once, reports folder, origin, template and release
5. Ends with the `/start` handoff and the `template-update` issue line

**Assertions:**
- [ ] Nothing runs before the yes
- [ ] No file in the template checkout is written, and nothing is committed or pushed from it
- [ ] Verdict COMPLETE

### Case 2: Already a game

**Fixture:** `origin` = `https://github.com/Dont-Know-Studios/sheep-herder.git`,
`template` = the studio repo

**Input:** `/new-game`

**Expected behavior:** says this checkout is already a game, names `origin`,
suggests `/start` or `/prototype`, asks nothing

**Assertions:**
- [ ] No question, no script run
- [ ] Verdict COMPLETE

### Case 3: The script fails — repo not empty

**Fixture:** as Case 1; `tools/new-game.sh` exits 1 with "the push failed"

**Input:** `/new-game sheep-herder <url>`, `Yes, run it`

**Expected behavior:** the name and URL questions are skipped (arguments); after
the run it shows the script's message as it is, including the command to finish

**Assertions:**
- [ ] Not retried, not "fixed" by force-pushing
- [ ] Verdict BLOCKED

### Case 4: Not a studio checkout

**Fixture:** `origin` = `https://github.com/someone/other-game.git`

**Input:** `/new-game`

**Assertions:**
- [ ] Says `/new-game` works from the studio template only; no question, no run
- [ ] Verdict NOT ASSESSED

### Case 5: The guard — "make me a game" in the template repo

**Fixture:** as Case 1

**Input:** "make me a game where you herd sheep" (routes to `/prototype`)

**Expected behavior:** `/prototype`'s injected guard block is present; it builds
nothing, says a game gets its own repo first, and starts `/new-game` carrying the
idea, which Phase 4 hands back to `/prototype` in the new folder

**Assertions:**
- [ ] No file is written under `prototypes/` or anywhere else in the template
- [ ] The same holds for `/start`

### Case 6: The guard stays silent in a game

**Fixture:** as Case 2

**Input:** `/prototype a sheep game`

**Assertions:**
- [ ] `studio-check.sh --guard` prints nothing; `/prototype` runs normally

---

## Protocol Compliance

- [ ] "May I run" before `tools/new-game.sh`; `I'll run it myself` and `Stop` run nothing
- [ ] Never suggests GitHub's "Use this template" button or `--allow-unrelated-histories`

---

## Coverage Notes

- `upstream-clone` routing and the cloud-session wording of the Phase 4 handoff
  are not separately fixture-tested.
- `tools/new-game.sh` itself is tested by running it against a local bare repo
  (`--template-url`, `--no-push`), not by this spec.
