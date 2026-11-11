---
name: new-game
description: "Starts a new game in its own repo, cloned from the Dont-Know-Studios studio template with history kept so studio updates merge cleanly. Use when the user wants to start, create or set up a new game or game project from the studio template, or when /start or /prototype stop because this checkout is the template itself."
argument-hint: "[game-name] [game-repo-url]"
user-invocable: true
allowed-tools: Read, AskUserQuestion, Bash(bash "*/.claude/skills/new-game/../../scripts/studio-check.sh"), Bash(bash .claude/scripts/studio-check.sh*), Bash(bash tools/new-game.sh *)
---

!`bash "${CLAUDE_SKILL_DIR}/../../scripts/studio-check.sh"`

The rows above are this checkout's role (`template`, `game`, `upstream-clone`,
`unknown` or `no-git`), its `origin` and `template` remotes, and the studio repo
and version from `.claude/studio.conf`. No rows → run
`bash .claude/scripts/studio-check.sh` and use its output; if that fails too, the
role is not known: say so and go to Phase 4 with verdict **NOT ASSESSED**.

# New Game — Every Game Gets Its Own Repo

The studio template (`STUDIO.md`) is the one repo every Dont-Know-Studios game
is cloned from. A game is never built inside it: game files committed there end
up in every future game. This skill gives a new game its own repo, cloned from
the template's newest studio release **with its history**, so later studio
updates arrive as one `template-update` issue and merge with a plain
`git merge`. GitHub's "Use this template" button drops that history; never
suggest it.

Ask with the question tool. Without one, list the options numbered and end your
turn to wait. A skipped or dismissed question is not an answer: ask again in
plain text.

## Phase 1: Where are we?

Route by `role`:

- **`template`** — the expected case. Go to Phase 2. If the user came here from
  `/start` or `/prototype` with a game in mind, keep what they said: it is what
  they will build once the repo exists.
- **`game`** — this checkout already is a game (`template` points at the studio
  repo, `origin` is the game's own). Say so, name `origin`, and suggest `/start`
  or `/prototype`. Verdict **COMPLETE**; stop.
- **`upstream-clone`** — `origin` is the upstream framework, not the studio
  template. Say that studio games start from the studio repo
  (`studio_repo`), and go to Phase 2: the script clones the studio repo, not
  this checkout, so it works from here too.
- **`unknown`** or **`no-git`** — not a studio checkout. Say what was found and
  that `/new-game` sets up games from the studio template only. Verdict
  **NOT ASSESSED**; stop.

## Phase 2: Name the game and its repo

If the arguments gave a game name and a repo URL, use them and skip the
questions they answer.

1. Ask for the game's short name, for the folder and the repo: letters, digits,
   `-`, `_`, `.` (for example `sheep-herder`). Offer one built from what the
   user said, if they described a game.
2. The game's repo must exist **and be empty** before anything is pushed. Claude
   cannot create GitHub repos, so the user does it. Say exactly this:

   > Create an empty repo for the game: https://github.com/new — owner
   > **Dont-Know-Studios**, name **`<name>`**, private or public as you like,
   > and **untick** README, .gitignore and licence (the template brings its
   > own). Or, with the GitHub CLI: `gh repo create Dont-Know-Studios/<name> --private`

   Then ask for the repo URL, offering
   `https://github.com/Dont-Know-Studios/<name>.git` as the first option.

## Phase 3: Clone and push

Show the command and where it will put the folder, then ask: "May I run
`bash tools/new-game.sh <name> <url>`? It creates `../<name>` next to this
checkout, clones the studio template's newest release there, and pushes it to
`<url>`." Options: `Yes, run it` / `I'll run it myself` / `Stop`.

- **Yes** → run it. Report its last block (folder, origin, template, the release
  it started from). On a non-zero exit, show its message as it is and stop
  with verdict **BLOCKED**: it says what is left on disk and the one command to
  finish. The usual causes are a repo that is not empty and a machine (or cloud
  session) without push access to the new repo; in a cloud session, the user can
  run the command on their own machine instead.
- **I'll run it myself** → give the command to run from this folder, and say it
  needs push access to the new repo.
- **Stop** → say nothing was created. Verdict **COMPLETE**; stop.

Never write game files in this checkout, and never commit or push here.

## Phase 4: Hand off

Verdicts: **COMPLETE** (the game's repo is set up, or the user will run the one
command), **BLOCKED** (the script failed; its message names what to fix),
**NOT ASSESSED** (this checkout's role could not be read, or it is not a studio
checkout).

On COMPLETE after a run, end with these two lines:

"Open Claude Code in `<folder>` (in a cloud session: start a new session on
`<repo>`), then type `/start` — or `/prototype` with your idea."
"Studio updates arrive in that repo as one `template-update` issue; `STUDIO.md`
has the steps."
