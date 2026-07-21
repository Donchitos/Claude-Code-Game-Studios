# Setup Requirements

## Required

| Tool | Purpose | Check |
|---|---|---|
| Codex CLI | Runs the project workflows | `codex --version` |
| Git | Clones the template and tracks changes | `git --version` |
| Bash | Runs the project hook scripts | `bash --version` |

Install Codex CLI using the current instructions in the
[official Codex documentation](https://developers.openai.com/codex/cli/).
This repository intentionally does not duplicate an installation command that
may change across Codex releases.

On Windows, install Git for Windows and make Git Bash's `bash.exe` available on
`PATH`. The hook configuration uses the same Bash commands on Windows, macOS,
and Linux.

## Project Trust

When hooks do not appear to run, check these conditions before editing scripts:

1. Codex was opened from the repository root.
2. The project was trusted after the current hook configuration was reviewed.
3. `bash` is available on `PATH`.
4. The event and matcher are supported by the installed Codex version.
5. The real event payload contains the fields the script expects.

## Optional Tools

Some hook validation paths use an available JSON parser. The scripts can detect
common choices such as `jq`, Python, or Node.js and should emit a clear advisory
when no supported parser is available. Install at least one if you expect hooks
to validate JSON content.

Game-engine requirements depend on the project:

- Godot 4 and the matching GDScript or .NET toolchain
- Unity and its selected editor/toolchain version
- Unreal Engine 5 plus the selected C++ or Blueprint workflow

Record the chosen engine version under `docs/engine-reference/<engine>/VERSION.md`
and replace the placeholders in `AGENTS.md`.

## Codex Permissions And Sandbox

Choose approvals and sandbox settings appropriate to the task and environment.
Use `codex --help` for options supported by the installed CLI. Prefer limited
permissions for reviews and unfamiliar repositories, and grant broader access
only when the task requires it and the environment is understood.

Project instructions cannot guarantee that every client exposes the same
interaction controls, delegation features, or hook events. Keep workflows
usable through ordinary prompts and verify client-dependent behavior live.

## Repository Setup Checklist

- [ ] `codex --version` succeeds.
- [ ] `git --version` succeeds.
- [ ] Engine and language placeholders in `AGENTS.md` were replaced.
- [ ] The matching engine version reference was updated.
- [ ] `$start` or another selected skill is discoverable in the project.
- [ ] Project-specific build and test commands are documented.
