---
name: studio-init
description: "Scaffold the project-side files a Claude Code Game Studios project needs — CLAUDE.md, path-scoped rules, document templates, engine reference docs, settings, and the directory tree. Run this once after installing the plugin. Harmless to run in a cloned template: it detects that everything is already in place."
argument-hint: "[no arguments]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion
model: sonnet
---

# Studio Init

The plugin ships the **studio brain**: agents, skills, and hooks. It cannot ship the
**project side** — CLAUDE.md, path-scoped rules, document templates, engine reference
docs, and the directory tree — because those live in *your* repository and you edit them.

This skill copies the project side into place, once. After that the plugin updates
independently (`/plugin update claude-code-game-studios`) and never touches your files,
which is the whole point of the split: **no more merge conflicts on template upgrades.**

Nothing is written without your approval. Existing files are never silently overwritten.

---

## Phase 1: Locate the Source

The files to copy live next to this skill. `${CLAUDE_SKILL_DIR}` resolves to the
directory containing this `SKILL.md`, in both install modes:

- **Plugin install** → `<plugin cache>/.claude/skills/studio-init`
- **Cloned template** → `<your project>/.claude/skills/studio-init`

The source root is three levels up from `${CLAUDE_SKILL_DIR}`. Compute it and store it
as `SOURCE_ROOT`:

```bash
cd "${CLAUDE_SKILL_DIR}/../../.." && pwd
```

Then compare `SOURCE_ROOT` with the project root (`${CLAUDE_PROJECT_DIR}`).

**If they are the same path**, you are running inside a cloned template. Everything is
already in place. Tell the user exactly that, note that they can still use the plugin
distribution for future projects, and stop — do not copy anything onto itself.

**If they differ**, you are running as a plugin. Continue to Phase 2.

---

## Phase 2: Survey What Is Missing

Check each target below and classify it as `MISSING`, `PRESENT`, or `MODIFIED`
(present but different from the source). Do not write anything yet.

| Target | What it is | If present |
|--------|-----------|------------|
| `CLAUDE.md` | Master configuration; imports the docs below | Never overwrite — offer a merge instead |
| `.claude/docs/` | Templates, workflow catalog, coordination rules, technical preferences, agent roster | Overwrite only unmodified files |
| `.claude/rules/` | 11 path-scoped coding standards | Overwrite only unmodified files |
| `.claude/statusline.sh` | Status line script | Overwrite if unmodified |
| `.claude/settings.json` | Permissions and status line config | Never overwrite — see Phase 4 |
| `docs/engine-reference/` | Version-pinned engine API snapshots | Never overwrite — these get re-pinned per project |
| Directory tree | `src/ assets/ design/ docs/ tests/ tools/ prototypes/ production/` | Create only missing directories |

Report the survey as a short table before asking for anything.

---

## Phase 3: Propose the Changeset

Present one consolidated list: every file that would be created, every directory that
would be made, and — separately and explicitly — anything that would be overwritten.

Ask: **"May I write this changeset?"**

If the user declines any part, drop it and proceed with the rest. If the user wants a
subset, honor exactly that subset.

---

## Phase 4: Write

Copy from `SOURCE_ROOT` to the project root. Preserve directory structure.

Two special cases:

**`.claude/settings.json`** — do **not** copy the source file wholesale. The source
contains a `hooks` block, and when the plugin is installed **the plugin already supplies
those hooks**. Copying them in makes every hook fire twice: two session-start banners,
two audit-log lines per agent, two copies of `active.md` archived at session end.

Write a settings file containing only the `permissions` and `statusLine` blocks from the
source, and omit `hooks` entirely. If the project already has a `settings.json`, do not
overwrite it — show the user the `permissions` and `statusLine` blocks to merge in, and
explicitly warn them not to copy the `hooks` block.

**`CLAUDE.md`** — if one already exists, never overwrite. Show the `@`-import lines the
studio skills depend on and ask whether to append them:

```markdown
@.claude/docs/directory-structure.md
@docs/engine-reference/godot/VERSION.md
@.claude/docs/technical-preferences.md
@.claude/docs/coordination-rules.md
@.claude/docs/coding-standards.md
@.claude/docs/context-management.md
```

(The engine-reference import should name the engine the project actually uses. If no
engine is configured yet, leave it out and let `/setup-engine` add it.)

---

## Phase 5: Report and Hand Off

Confirm what was written. Then state the two facts the user needs:

1. **Updating the studio**: `/plugin update claude-code-game-studios` — pulls new agents,
   skills, and hooks. It will not touch anything this skill wrote.
2. **The files are yours**: everything under `.claude/docs/`, `.claude/rules/`, and
   `CLAUDE.md` is now project-owned. Edit freely; upgrades will not fight you.

Finish by routing to `/start`, which asks where the user is and picks the workflow.

---

## Verification

Before reporting success, confirm:

- [ ] `.claude/settings.json` contains no `hooks` block (plugin mode)
- [ ] `CLAUDE.md` exists and its `@` imports resolve to files that exist
- [ ] `.claude/rules/` contains 11 `.md` files
- [ ] `.claude/docs/templates/` contains the template set
- [ ] The eight top-level directories exist

Report any check that fails rather than reporting success.
