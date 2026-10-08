# Setup Requirements

This template requires a few tools to be installed for full functionality.
Hooks carry on without an optional tool and lose only the check it powers. The
required ones are required: without Python 3 every setting falls back to its
default and a commit that stages data JSON is blocked, and without Bash no hook
runs at all.

## Required

| Tool | Purpose | Install |
| ---- | ---- | ---- |
| **Git** | Version control, branch management | [git-scm.com](https://git-scm.com/) |
| **Claude Code** | AI agent CLI | Native installer: `curl -fsSL https://claude.ai/install.sh \| bash` (macOS, Linux, WSL) or `irm https://claude.ai/install.ps1 \| iex` (Windows PowerShell). npm also works: `npm install -g @anthropic-ai/claude-code` (Node.js 22+). See [code.claude.com/docs/en/setup](https://code.claude.com/docs/en/setup) |
| **Python 3** | Reads `project.yaml` for every skill and hook | [python.org](https://www.python.org/). Without it every setting silently falls back to its default, and a commit that stages data JSON is blocked because it cannot be validated |
| **Bash** | Runs every hook | Built into macOS and Linux. On Windows, install [Git for Windows](https://git-scm.com/downloads/win) — Claude Code runs without it, but no CCGS hook does |

## Recommended

| Tool | Used By | Purpose | Install |
| ---- | ---- | ---- | ---- |
| **jq** | Hooks (8 of 12) | JSON parsing in commit/push/asset/agent hooks | See below |

### Installing jq

**Windows** (any of these):
```
winget install jqlang.jq
choco install jq
scoop install jq
```

**macOS**:
```
brew install jq
```

**Linux**:
```
sudo apt install jq     # Debian/Ubuntu
sudo dnf install jq     # Fedora
sudo pacman -S jq       # Arch
```

## Platform Notes

### Windows
- Git for Windows includes **Git Bash**, which provides the `bash` command
  used by all hooks in `settings.json`
- If Claude Code can't find Git Bash, set `CLAUDE_CODE_GIT_BASH_PATH` to its
  `bash.exe` in the `env` block of your settings (for example
  `C:\\Program Files\\Git\\bin\\bash.exe` in JSON)
- Hooks use `bash .claude/hooks/[name].sh` — this works on Windows because
  Claude Code invokes commands through a shell that can find `bash.exe`

### macOS / Linux
- Bash is available natively
- Install `jq` via your package manager for full hook support

## Verifying Your Setup

Run these commands to check prerequisites:

```bash
git --version          # Should show git version
bash --version         # Should show bash version
jq --version           # Should show jq version (optional)
python --version       # Required: Python 3 (python3 or py also work)
```

## What Happens Without Optional Tools

| Missing Tool | Effect |
| ---- | ---- |
| **jq** | Nothing is lost: every hook falls back to `grep` to read its JSON input. jq is only more robust with unusual input. |
| **Python 3** | Not optional (see Required). Every setting falls back to its default, because `project.yaml` is read through Python; the asset hook skips JSON validation and says so; a commit that stages data JSON is blocked. |
| **Both** | As without Python. |

## Optional Performance Settings

CCGS deliberately ships **no** values for the settings below. Each one's best
value depends on your machine, your Claude plan and how you work, so a value
committed here would be a guess every user inherits without noticing. Set the
ones you want in `.claude/settings.local.json`, which is gitignored and yours
alone.

| Setting | What it does | When to change it |
| ---- | ---- | ---- |
| `promptCacheTtl` | How long the main conversation's prompt cache lives. | Raise it if you work in long sessions with gaps; the cache surviving a break avoids re-sending context. |
| `subagentPromptCacheTtl` | The same, for subagents and other off-conversation requests. | Worth raising on a 49-agent project like this one, where `team-*` skills spawn repeatedly. |
| `autoCompactWindow` | How full the context gets before Claude Code compacts it. | Lower it if compaction keeps surprising you mid-task; raise it if you would rather compact less often and keep more history. |
| `skillListingBudgetFraction` | How much context the skill listing may occupy. | CCGS ships 74 skills, so the listing is not small. Lower it if you want more room for work; `skillListingMaxDescChars` trims each description instead. |

`sandbox.enabled` isolates shell commands from your filesystem and network. It
is worth turning on, but it runs on **macOS, Linux and WSL2 only** — it is not
available on native Windows, which is CCGS's primary platform.

### One setting CCGS does ship

`permissions.defaultMode` is set to `default` in `.claude/settings.json`, on
purpose. A terminal session started **at the project root** then starts in
Claude Code's ask-first mode, so file edits wait for your approval even if your
own config sets `acceptEdits` or `auto`.

It sets the mode a session starts in. It is a backstop, not a guarantee, and
these routes go around it:

- **Starting in a subfolder** such as `design/` or the code root (`src/`,
  `Assets/` or `Source/`, depending on the engine). Claude Code loads
  `.claude/settings.json` only from the folder it starts in, so that session has
  none of this project's hooks, deny rules or permission mode. Start at the root.
- **Resuming a session.** A resumed session keeps the mode it ended in.
- **Switching during a session**: Shift+Tab, answering "Yes, and switch to auto
  mode", or allowing all edits for the session.
- **`claude --permission-mode auto`** on the command line.
- **The VS Code extension**, which never reads a project's `.claude/settings.json`
  for the mode a conversation starts in. Set `claudeCode.initialPermissionMode`
  to `default` in your VS Code user settings to get the same behaviour.
- **The Desktop app**, which remembers the mode you last picked for a folder and
  uses that instead.

In any mode that accepts edits without asking, the framework's "May I write?" is
an instruction to the model, not a stop.

To start terminal sessions in a different mode, set `permissions.defaultMode` in
`.claude/settings.local.json`, which takes precedence. Terminal sessions accept
any mode from it except `auto` and `bypassPermissions`. Understand what you are
turning off first.

## Recommended IDE

Claude Code works with any editor, but the template is optimized for:
- **VS Code** with the Claude Code extension
- **Cursor** (Claude Code compatible)
- Terminal-based Claude Code CLI
