# settings.local.json Template

Create `.claude/settings.local.json` for personal overrides that should NOT
be committed to version control. Add it to `.gitignore`.

## Example settings.local.json

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(npm *)",
      "Read",
      "Glob",
      "Grep"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(git push --force *)"
    ]
  }
}
```

## Permission Modes

Claude Code supports different permission modes. Recommended for game dev:

### During Development (Default)
Use **normal mode** — Claude asks before running most commands. This is safest
for production code.

### During Prototyping
Use **auto-accept mode** with limited scope — faster iteration on throwaway code.
Only use this when working in `prototypes/` directory.

### During Code Review
Use **read-only** permissions — Claude can read and search but not modify files.

## Customizing Hooks Locally

You can add personal hooks in `settings.local.json` that extend (not override)
the project hooks. For example, adding a notification when builds complete:

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'echo Session ended at $(date)'",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```
