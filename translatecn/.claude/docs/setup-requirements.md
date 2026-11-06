# Setup Requirements
# 安装要求

This template requires a few tools to be installed for full functionality.
Hooks carry on without an optional tool and lose only the check it powers. The
required ones are required: without Python 3 every setting falls back to its
default and a commit that stages data JSON is blocked, and without Bash no hook
runs at all.
此模板需要安装一些工具以获得完整功能。缺少可选工具时钩子仍会继续运行，只会失去该工具所支持的检查。必需的工具就是必需的：没有 Python 3，每个设置都会回退到默认值，且暂存数据 JSON 的提交会被阻塞；没有 Bash，则任何钩子都不会运行。

## Required
## 必需工具

| Tool | Purpose | Install |
| 工具 | 用途 | 安装 |
| ---- | ---- | ---- |
| **Git** | Version control, branch management | [git-scm.com](https://git-scm.com/) |
| **Git** | 版本控制、分支管理 | [git-scm.com](https://git-scm.com/) |
| **Claude Code** | AI agent CLI | Native installer: `curl -fsSL https://claude.ai/install.sh \| bash` (macOS, Linux, WSL) or `irm https://claude.ai/install.ps1 \| iex` (Windows PowerShell). npm also works: `npm install -g @anthropic-ai/claude-code` (Node.js 22+). See [code.claude.com/docs/en/setup](https://code.claude.com/docs/en/setup) |
| **Claude Code** | AI 智能体 CLI | 原生安装器：`curl -fsSL https://claude.ai/install.sh \| bash`（macOS、Linux、WSL）或 `irm https://claude.ai/install.ps1 \| iex`（Windows PowerShell）。npm 也可用：`npm install -g @anthropic-ai/claude-code`（Node.js 22+）。见 [code.claude.com/docs/en/setup](https://code.claude.com/docs/en/setup) |
| **Python 3** | Reads `project.yaml` for every skill and hook | [python.org](https://www.python.org/). Without it every setting silently falls back to its default, and a commit that stages data JSON is blocked because it cannot be validated |
| **Python 3** | 为每个技能和钩子读取 `project.yaml` | [python.org](https://www.python.org/)。没有它，每个设置都会静默回退到默认值，且暂存数据 JSON 的提交会被阻塞，因为无法验证 |
| **Bash** | Runs every hook | Built into macOS and Linux. On Windows, install [Git for Windows](https://git-scm.com/downloads/win) — Claude Code runs without it, but no CCGS hook does |
| **Bash** | 运行每个钩子 | macOS 和 Linux 自带。在 Windows 上，安装 [Git for Windows](https://git-scm.com/downloads/win) — Claude Code 可在没有它的情况下运行，但没有任何 CCGS 钩子可以 |

## Recommended
## 推荐工具

| Tool | Used By | Purpose | Install |
| 工具 | 使用方 | 用途 | 安装 |
| ---- | ---- | ---- | ---- |
| **jq** | Hooks (8 of 12) | JSON parsing in commit/push/asset/agent hooks | See below |
| **jq** | 钩子（12 个中的 8 个） | commit/push/资源/智能体钩子中的 JSON 解析 | 见下文 |

### Installing jq
### 安装 jq

**Windows** (any of these):
**Windows**（任选其一）：
```
winget install jqlang.jq
choco install jq
scoop install jq
```

**macOS**:
**macOS**：
```
brew install jq
```

**Linux**:
**Linux**：
```
sudo apt install jq     # Debian/Ubuntu
sudo dnf install jq     # Fedora
sudo pacman -S jq       # Arch
```

## Platform Notes
## 平台说明

### Windows
### Windows
- Git for Windows includes **Git Bash**, which provides the `bash` command
  used by all hooks in `settings.json`
- Git for Windows 包含 **Git Bash**，提供 `settings.json` 中所有钩子使用的 `bash` 命令
- If Claude Code can't find Git Bash, set `CLAUDE_CODE_GIT_BASH_PATH` to its
  `bash.exe` in the `env` block of your settings (for example
  `C:\\Program Files\\Git\\bin\\bash.exe` in JSON)
- 如果 Claude Code 找不到 Git Bash，请在其设置的 `env` 块中将 `CLAUDE_CODE_GIT_BASH_PATH` 设置为其 `bash.exe`（例如 JSON 中的 `C:\\Program Files\\Git\\bin\\bash.exe`）
- Hooks use `bash .claude/hooks/[name].sh` — this works on Windows because
  Claude Code invokes commands through a shell that can find `bash.exe`
- 钩子使用 `bash .claude/hooks/[name].sh` — 这在 Windows 上可行，因为 Claude Code 通过能找到 `bash.exe` 的 shell 调用命令

### macOS / Linux
### macOS / Linux
- Bash is available natively
- Bash 原生可用
- Install `jq` via your package manager for full hook support
- 通过包管理器安装 `jq` 以获得完整钩子支持

## Verifying Your Setup
## 验证你的安装

Run these commands to check prerequisites:
运行以下命令检查前置条件：

```bash
git --version          # Should show git version
bash --version         # Should show bash version
jq --version           # Should show jq version (optional)
python --version       # Required: Python 3 (python3 or py also work)
```

## What Happens Without Optional Tools
## 没有可选工具会怎样

| Missing Tool | Effect |
| 缺失工具 | 影响 |
| ---- | ---- |
| **jq** | Nothing is lost: every hook falls back to `grep` to read its JSON input. jq is only more robust with unusual input. |
| **jq** | 不会损失任何功能：每个钩子都会回退到 `grep` 来读取其 JSON 输入。jq 仅在处理异常输入时更稳健。 |
| **Python 3** | Not optional (see Required). Every setting falls back to its default, because `project.yaml` is read through Python; the asset hook skips JSON validation and says so; a commit that stages data JSON is blocked. |
| **Python 3** | 不是可选的（见必需工具）。每个设置都会回退到默认值，因为 `project.yaml` 通过 Python 读取；资源钩子会跳过 JSON 验证并说明这一点；暂存数据 JSON 的提交会被阻塞。 |
| **Both** | As without Python. |
| **两者** | 与缺少 Python 时相同。 |

## Optional Performance Settings
## 可选性能设置

CCGS deliberately ships **no** values for the settings below. Each one's best
value depends on your machine, your Claude plan and how you work, so a value
committed here would be a guess every user inherits without noticing. Set the
ones you want in `.claude/settings.local.json`, which is gitignored and yours
alone.
CCGS 刻意不为下面的设置提供**任何**值。每一项的最佳值取决于你的机器、你的 Claude 套餐以及你的工作方式，因此在此提交的值会是每个用户都在不知不觉中继承的猜测。在 `.claude/settings.local.json` 中设置你想要的项，该文件被 gitignore，且只属于你。

| Setting | What it does | When to change it |
| 设置 | 作用 | 何时更改 |
| ---- | ---- | ---- |
| `promptCacheTtl` | How long the main conversation's prompt cache lives. | Raise it if you work in long sessions with gaps; the cache surviving a break avoids re-sending context. |
| `promptCacheTtl` | 主对话提示缓存的存活时间。 | 如果你在带有间隙的长会话中工作，请提高它；缓存熬过中断可避免重新发送上下文。 |
| `subagentPromptCacheTtl` | The same, for subagents and other off-conversation requests. | Worth raising on a 49-agent project like this one, where `team-*` skills spawn repeatedly. |
| `subagentPromptCacheTtl` | 同上，但针对子智能体和其他非对话请求。 | 在像本项目这样有 49 个智能体的项目中值得提高，这里 `team-*` 技能会反复生成。 |
| `autoCompactWindow` | How full the context gets before Claude Code compacts it. | Lower it if compaction keeps surprising you mid-task; raise it if you would rather compact less often and keep more history. |
| `autoCompactWindow` | 上下文在 Claude Code 压缩它之前会变得多满。 | 如果压缩经常在任务中途让你措手不及，请降低它；如果你宁愿少压缩、保留更多历史，请提高它。 |
| `skillListingBudgetFraction` | How much context the skill listing may occupy. | CCGS ships 74 skills, so the listing is not small. Lower it if you want more room for work; `skillListingMaxDescChars` trims each description instead. |
| `skillListingBudgetFraction` | 技能列表可占用的上下文比例。 | CCGS 提供 74 个技能，因此该列表并不小。如果你想要更多工作空间，请降低它；`skillListingMaxDescChars` 则会改为精简每个描述。 |

`sandbox.enabled` isolates shell commands from your filesystem and network. It
is worth turning on, but it runs on **macOS, Linux and WSL2 only** — it is not
available on native Windows, which is CCGS's primary platform.
`sandbox.enabled` 将 shell 命令与你的文件系统和网络隔离。它值得开启，但仅在 **macOS、Linux 和 WSL2** 上运行 — 在原生 Windows 上不可用，而原生 Windows 是 CCGS 的主要平台。

### One setting CCGS does ship
### CCGS 确实提供的一项设置

`permissions.defaultMode` is set to `default` in `.claude/settings.json`, on
purpose. A terminal session started **at the project root** then starts in
Claude Code's ask-first mode, so file edits wait for your approval even if your
own config sets `acceptEdits` or `auto`.
`permissions.defaultMode` 在 `.claude/settings.json` 中被有意设置为 `default`。**在项目根目录**启动的终端会话随后会以 Claude Code 的先询问模式启动，因此即使你自己的配置设置了 `acceptEdits` 或 `auto`，文件编辑也会等待你的批准。

It sets the mode a session starts in. It is a backstop, not a guarantee, and
these routes go around it:
它设置的是会话启动时所在的模式。它是兜底，而不是保证，以下路径会绕过它：

- **Starting in a subfolder** such as `design/` or the code root (`src/`,
  `Assets/` or `Source/`, depending on the engine). Claude Code loads
  `.claude/settings.json` only from the folder it starts in, so that session has
  none of this project's hooks, deny rules or permission mode. Start at the root.
- **从子文件夹启动**，例如 `design/` 或代码根（`src/`、`Assets/` 或 `Source/`，取决于引擎）。Claude Code 仅从它启动的文件夹加载 `.claude/settings.json`，因此该会话没有本项目的任何钩子、拒绝规则或权限模式。请从根目录启动。
- **Resuming a session.** A resumed session keeps the mode it ended in.
- **恢复会话。** 恢复的会话保持其结束时的模式。
- **Switching during a session**: Shift+Tab, answering "Yes, and switch to auto
  mode", or allowing all edits for the session.
- **会话期间切换**：Shift+Tab、回答 "Yes, and switch to auto mode"，或允许该会话的所有编辑。
- **`claude --permission-mode auto`** on the command line.
- **`claude --permission-mode auto`** 命令行参数。
- **The VS Code extension**, which never reads a project's `.claude/settings.json`
  for the mode a conversation starts in. Set `claudeCode.initialPermissionMode`
  to `default` in your VS Code user settings to get the same behaviour.
- **VS Code 扩展**，它从不为对话启动模式读取项目的 `.claude/settings.json`。在你的 VS Code 用户设置中将 `claudeCode.initialPermissionMode` 设置为 `default` 以获得相同行为。
- **The Desktop app**, which remembers the mode you last picked for a folder and
  uses that instead.
- **桌面应用**，它会记住你上次为某个文件夹选择的模式并改用它。

In any mode that accepts edits without asking, the framework's "May I write?" is
an instruction to the model, not a stop.
在任何无需询问即接受编辑的模式中，框架的 "May I write?" 是对模型的指令，而不是停止。

To start terminal sessions in a different mode, set `permissions.defaultMode` in
`.claude/settings.local.json`, which takes precedence. Terminal sessions accept
any mode from it except `auto` and `bypassPermissions`. Understand what you are
turning off first.
要在不同模式下启动终端会话，请在 `.claude/settings.local.json` 中设置 `permissions.defaultMode`，它优先。终端会话接受其中的任何模式，除了 `auto` 和 `bypassPermissions`。请先理解你正在关闭什么。

## Recommended IDE
## 推荐 IDE

Claude Code works with any editor, but the template is optimized for:
Claude Code 可与任何编辑器配合，但模板针对以下进行了优化：
- **VS Code** with the Claude Code extension
- **VS Code** 配合 Claude Code 扩展
- **Cursor** (Claude Code compatible)
- **Cursor**（兼容 Claude Code）
- Terminal-based Claude Code CLI
- 基于终端的 Claude Code CLI
