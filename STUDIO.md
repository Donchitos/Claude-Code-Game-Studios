# Dont-Know-Studios Studio Template

This repo is the **studio template**: our copy of
[Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)
(upstream), with our own additions. Every Dont-Know-Studios game starts as a
clone of it, and every game takes later template improvements by merging a
**studio release**.

```
Donchitos/Claude-Code-Game-Studios          upstream: the framework
        │  upstream release (v1.4.0) → issue here → review → merge → studio release
        ▼
Dont-Know-Studios/Claude-Code-Game-Studios  the studio template (this repo)
        │  studio release (studio-v1.1.0) → issue in each game → merge when ready
        ▼
Dont-Know-Studios/<game>                    one repo per game, made by /new-game
```

Two rules keep this working:

1. **Games are never built in this repo.** A game gets its own repo from
   `/new-game` (or `tools/new-game.sh`). Claude is told this in `CLAUDE.md`, by
   the session-start line, and by a guard in `/start` and `/prototype`.
2. **History is never cut.** Games are *cloned* from this repo, never made with
   GitHub's "Use this template" button, so an update is a plain `git merge` that
   only conflicts where a game changed the same file.

Studio settings live in [`.claude/studio.conf`](.claude/studio.conf): the
studio repo, the upstream repo, the release tag prefix and `STUDIO_VERSION`.

---

## Contents

- [One-time setup](#one-time-setup)
- [Starting a new game](#starting-a-new-game)
- [Taking a studio update (in a game)](#taking-a-studio-update-in-a-game)
- [Taking an upstream update (in this repo)](#taking-an-upstream-update-in-this-repo)
- [Cutting a studio release](#cutting-a-studio-release)
- [Customising the template](#customising-the-template)
- [What the studio adds](#what-the-studio-adds)
- [No shared history](#no-shared-history)
- [Troubleshooting](#troubleshooting)

---

## One-time setup

In **this repo** on GitHub:

1. **Settings → General → Features → Issues: on.** Forks start with Issues off,
   and the update check reports through an issue.
2. **Actions tab → enable workflows.** Forks start with Actions off.
3. No token or secret is needed: the workflow asks for `issues: write` on its
   own built-in token. Leave the Actions permission settings at their default.
4. Publish the first studio release, `studio-v1.0.0`
   ([Cutting a studio release](#cutting-a-studio-release)). Until one exists,
   `tools/new-game.sh` falls back to `main` with a warning, and the update check
   in games reports "NOT CHECKED".
5. **Actions → Template update check → Run workflow** once, to see it work. Here
   it compares this repo with upstream's newest release.

In **each game repo**, after `/new-game`: turn Actions on if they are off, then
run the same workflow once. Nothing else — the workflow and its script came with
the clone.

---

## Starting a new game

In Claude Code, in a checkout of this repo, type `/new-game` (or just say
"start a new game"). It walks through it. By hand, it is:

1. **Create an empty repo** on GitHub: owner Dont-Know-Studios, any name,
   private or public, with **no** README, .gitignore or licence.
   CLI: `gh repo create Dont-Know-Studios/<name> --private`
2. **Run, from this repo:**
   ```bash
   bash tools/new-game.sh <name> https://github.com/Dont-Know-Studios/<name>.git
   ```
   It clones this repo at its newest studio release into `../<name>`, renames
   the clone's remote to `template`, sets `origin` to the game's repo, and
   pushes `main`. Options: `--dir`, `--ref <tag>`, `--no-push` (`--help`).
3. **Open Claude Code in `../<name>`** (a cloud session: start one on the new
   repo) and run `/start`, or `/prototype` with an idea.

---

## Taking a studio update (in a game)

When a studio release is out, the game repo's **Template update check**
workflow (weekly, or run by hand) opens **one** issue labelled
`template-update`. If another release comes out before you merge, the same
issue is rewritten for the newer release — there is never more than one. Once
`main` contains the release, the next run closes it. Sessions also show one line
at start (`Update: studio template … is out`).

The issue carries the exact commands. In short:

```bash
git fetch template --tags
git checkout main && git pull
git checkout -b template-update/studio-vX.Y.Z
git merge studio-vX.Y.Z
# resolve conflicts, run the game and its tests, push, open a PR into main
```

**Conflicts to expect, and what to keep:**

| File | Keep |
|---|---|
| `CLAUDE.md` | the game's Technology Stack and anything it added; take the template's other changes |
| `project.yaml` | the game's values; take new keys from the template |
| `.claude/docs/technical-preferences.md` | the game's |
| anything under `.claude/` the game edited | decide per file: `git diff studio-vX.Y.Z -- <file>` |

`.claude/studio.conf` should not conflict (games do not edit it); after the
merge its `STUDIO_VERSION` is the release you merged, which stops the notice.

---

## Taking an upstream update (in this repo)

When upstream publishes a release, the **Template update check** in this repo
opens (or rewrites) its one `template-update` issue. Do **not** use GitHub's
"Sync fork" button: it merges upstream's `main` straight into ours, unreviewed
and between releases.

```bash
# once per clone
git remote add upstream https://github.com/Donchitos/Claude-Code-Game-Studios.git

git fetch upstream --tags
git checkout main && git pull
git checkout -b upstream-update/vX.Y.Z
git merge vX.Y.Z
```

Read upstream's notes first: `UPGRADING.md` (its `vA → vB` section) and
`CHANGELOG.md`, both arriving in the merge.

**Conflicts to expect** — each is a studio edit to an upstream file, kept
deliberately small:

| File | Our change | Resolve |
|---|---|---|
| `CLAUDE.md` | the "Dont-Know-Studios: one repo per game" section | keep ours, take theirs around it |
| `.claude/hooks/session-start.sh` | the "Studio notices" block, and `[ ! -f .claude/hooks/studio-session.sh ] &&` on the update-alert `if` | keep both |
| `.claude/skills/start/SKILL.md`, `.claude/skills/prototype/SKILL.md` | the `studio-check.sh --guard` line after the frontmatter, and its entry at the end of `allowed-tools` | keep both, on top of their new text |
| `README.md`, `UPGRADING.md`, `SECURITY.md` | repo URLs pointing here; the note at the top | keep ours |
| `studio-tests/catalog.yaml` | the `new-game` entry | keep it |
| `.github/CODEOWNERS` | deleted | keep it deleted (`git rm .github/CODEOWNERS`) |

Then check, before merging the branch:

```bash
bash .claude/scripts/studio-check.sh            # role: template
bash .claude/hooks/studio-session.sh notice     # the template line
bash .claude/scripts/skill-lint.sh new-game     # frontmatter=ok
grep -c 'studio-check.sh" --guard' .claude/skills/start/SKILL.md .claude/skills/prototype/SKILL.md   # 2 each
```

Merge the PR, then [cut a studio release](#cutting-a-studio-release) so games
receive it. The issue closes itself on the next run.

---

## Cutting a studio release

A studio release is what games receive. Cut one after an upstream merge, or
after studio changes worth sending out.

**Version:** `studio-vMAJOR.MINOR.PATCH`, our own numbering (not upstream's).
PATCH for fixes, MINOR for an upstream release or new studio features, MAJOR when
games must do something by hand to take it (say so in the release notes).

1. On a branch: set `STUDIO_VERSION` in `.claude/studio.conf` to the new version,
   and add a row to [the release history](#release-history). Merge to `main`.
2. Tag that commit and push the tag:
   ```bash
   git checkout main && git pull
   git tag studio-vX.Y.Z
   git push origin studio-vX.Y.Z
   ```
   **A pushed `studio-v` tag is live**: `tools/new-game.sh` starts new games
   from the newest one at once. Push it only when the release is approved.
3. **Releases → Draft a new release** → choose the tag → notes: what changed,
   which upstream version it includes, and anything a game must do by hand →
   publish (not a pre-release; "Set as latest release" ticked). Game repos pick
   it up on their next weekly check.

Never move or delete a pushed release tag: games may already have merged it.
Fix forward with a new PATCH release.

### Release history

| Studio release | Upstream included | Notes |
|---|---|---|
| studio-v1.0.0 | v1.3.0 | Studio template setup: `/new-game`, update issues, template guard |

---

## Customising the template

Every edit to an upstream file is a merge conflict at every upstream release.
So:

- **Add, don't edit.** New agents, skills, rules, docs and scripts go in **new
  files**; upstream never touches them. Name studio skills and agents so they
  cannot clash with upstream's (e.g. a `studio-` prefix where it reads well).
- **When an upstream file must change,** keep the change small, in one place,
  marked with a comment naming the studio, and add it to the conflict table in
  [Taking an upstream update](#taking-an-upstream-update-in-this-repo).
- **No game content here.** `project.yaml`, the engine choice and `CLAUDE.md`'s
  Technology Stack stay as placeholders; each game sets them.
- **Never file upstream** (coordination rule 7). Ideas for upstream go to the
  person who maintains this template, who decides what to do with them.

---

## What the studio adds

| File | What it is |
|---|---|
| `STUDIO.md` | this guide |
| `.claude/studio.conf` | studio repo, upstream repo, tag prefix, `STUDIO_VERSION` |
| `.claude/scripts/studio-check.sh` | which repo is this: `template`, `game`, `upstream-clone`, `unknown` |
| `.claude/hooks/studio-session.sh` | session-start line: the template guard, or the studio update notice |
| `.claude/skills/new-game/` | the `/new-game` skill (spec: `studio-tests/skills/utility/new-game.md`) |
| `tools/new-game.sh` | clone, re-point remotes, push |
| `tools/template-update-check.sh` | the one-issue update check |
| `.github/workflows/template-update-check.yml` | runs it weekly and on demand |

The skill counts in `README.md` and `studio-tests/README.md` are upstream's (75)
and are left alone to avoid a conflict at every upstream release; `/new-game` is
the studio's one addition.

The session-start update notice in games comes from `studio-session.sh` and
announces **studio** releases; upstream's own notice (`update-check.sh`) is
switched off whenever `studio-session.sh` is present. Both honour
`updates.check: false`.

---

## No shared history

A repo made with "Use this template", a zip download or `git init` shares no
history with this one, so `git merge` refuses (`unrelated histories`). Do not
force it with `--allow-unrelated-histories`: every file becomes a conflict.

The fix is to give the game a real clone and move its own files across once:

1. Make a new repo with `/new-game`.
2. Copy the game's own content into it (code root, `assets/`, `design/`, `docs/`
   it wrote, `production/`, `prototypes/`, `tests/`, and its `project.yaml`
   values), commit, push.
3. Archive the old repo.

The update-check issue says so when it finds a repo like this.

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| No issue ever appears | Issues off in the repo (Settings → Features), or Actions off. Run the workflow by hand and read its log. |
| Workflow log: `NOT CHECKED — … has no release tagged …` | No studio release published yet (or only pre-releases / drafts). |
| Workflow stopped running | GitHub pauses scheduled workflows in a public repo after 60 days without commits. Re-enable it on the Actions tab. |
| `new-game.sh`: push failed | The game repo is not empty, or this machine (or cloud session) cannot push to it. The folder is set up; push by hand. |
| `/start` or `/prototype` says this is the studio template | Working as intended in this repo — run `/new-game`. If you are maintaining the template, say so and it carries on. |
| A game's sessions announce upstream releases | `.claude/hooks/studio-session.sh` is missing in that game; merge the newest studio release. |
