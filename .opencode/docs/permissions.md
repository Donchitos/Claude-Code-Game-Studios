# Permissions and Safety (OpenCode)

OpenCode permissions are ordered rules. The **last matching rule wins**, so broad
rules come first and specific exceptions come after them. Rules are matched
against tool actions (`read`, `edit`, `shell`, `subagent`, `skill`, ...) and a
resource (a path, command, agent ID, or skill ID).

The project policy lives in `opencode.jsonc`. Agent-level rules are generated
from each agent's Claude-side tool list.

## Default posture

| Action | Posture |
|---|---|
| `read`, `glob`, `grep` | allowed |
| `edit` (write/edit/patch) | allowed, with hard denies below |
| `shell` | **ask** by default; routine inspection and studio helpers are allowed |
| `websearch`, `webfetch` | allowed; denied per-agent where Claude withheld the tool |
| `subagent` | allowed; denied per-agent where Claude withheld the Agent tool |
| `skill`, `question` | allowed for the primary agent |
| `execute` (Code Mode) | denied globally |
| `external_directory` | ask |

## Hard denies

- `rm -rf`, `rm -fr`, `rm -r -f`, `rm -Rf`, and the long `--recursive --force`
  forms.
- Force push, `git reset --hard`, and forced `git clean`.
- `sudo`, `chmod 777`.
- Reading, editing, or running a shell command that names a `.env` file
  (`.env.example` is allowed through the read/edit tools; the shell pattern is
  intentionally broad).
- Editing `.uasset` / `.umap`.
- Editing generated `.opencode/agents/`, `.opencode/skills/`, or
  `.opencode/commands/` — edit the `.claude/` source and regenerate.

## Agent-level posture

The generator translates the Claude `tools:` list into OpenCode rules:

- Agents without `Write`/`Edit` get `edit: deny`.
- Agents without `Bash` get `shell: deny`.
- Agents without `WebSearch`/`WebFetch` get the matching deny.
- Agents without `Agent` get `subagent: deny`.
- Every subagent gets `question: deny` and `execute: deny`.

We deny the tools an agent did **not** have rather than denying everything and
re-allowing. A broad `shell: allow` on an agent would override the global safety
denies, because agent rules are appended after global ones.

## What is not enforced per skill

OpenCode permissions are agent-level. A skill's Claude `allowed-tools` list does
not become a per-skill permission set. The generated skills document their
intended posture, and read-only agents hard-deny edits, but a read-only skill run
inside the primary `studio` agent still has the primary's tools.

If you need hard enforcement for a specific workflow, run it under a read-only
agent:

```jsonc
{
  "agents": {
    "review-only": {
      "mode": "primary",
      "description": "Read-only studio reviewer",
      "permissions": [
        { "action": "edit", "resource": "*", "effect": "deny" },
        { "action": "shell", "resource": "*", "effect": "deny" }
      ]
    }
  }
}
```

## Adding an allow rule

Add it after the broad `shell: ask` rule and before the deny block:

```jsonc
{ "action": "shell", "resource": "godot --headless*", "effect": "allow" }
```

Keep allows narrow. Shell commands run with the host user's filesystem, process,
and network authority. Prefer a specific command prefix over a pattern that
recognizes "safe" commands by shape.

## The safety plugin

The plugin in `.opencode/plugins/ccgs/` is not a permission bypass. It runs the
canonical validation scripts and blocks the same critical operations as Claude
Code. See `hooks-reference.md`.

## Saved approvals

When OpenCode asks for a permission and you choose "Allow always", it saves a
project-scoped allow rule. Saved approvals never override a configured deny.
Review them occasionally; remove broad approvals you no longer need.
