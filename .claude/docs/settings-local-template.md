# settings.local.json Template

Create `.claude/settings.local.json` for personal overrides that should NOT
be committed to version control. The shipped `.gitignore` already ignores it.

## Example settings.local.json

```json
{
  "permissions": {
    "allow": [
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(npm run *)"
    ],
    "deny": [
      "Bash(git push *)"
    ]
  }
}
```

Put the `*` after the subcommand. `Bash(git commit *)` allows only commits;
`Bash(git *)` would allow every git command, `git push` included. Read-only
commands such as `git status`, `git log` and `ls` need no rule: Claude Code runs
them without asking. Your rules add to the shipped ones in
`.claude/settings.json`, so its deny rules still apply.

## Permission Modes

Claude Code has several permission modes. The shipped `.claude/settings.json`
starts terminal sessions in `default`; to start in another, set
`permissions.defaultMode` here. "One setting Claude Code Game Studios does ship" in
`setup-requirements.md` lists what that can and cannot change. You can also
switch during a session. Suggested for game dev:

### During Development — Manual (`default`)
Claude asks before running most commands and before editing files. This is the
safest for production code.

### During Prototyping — `acceptEdits`
File edits and common filesystem commands such as `mkdir` and `mv` are accepted
without asking; other commands still ask. It applies to the whole working
directory, not only `prototypes/`, so switch back when you return to production
code.

### During Code Review — `plan`
Claude reads files and runs read-only commands to explore, but does not edit
your source files.

### `auto`
Runs without routine prompts: a background classifier checks each action before
it runs. A local `defaultMode` cannot start a terminal session in it; switch
during the session instead (`setup-requirements.md` lists the routes).

## Customizing Hooks Locally

You can add personal hooks in `settings.local.json` that extend (not override)
the project hooks. For example, a personal log line each time Claude finishes a
response:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'echo \"Response finished at $(date)\" >> \"$CLAUDE_PROJECT_DIR/production/session-logs/my-stops.log\"'",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

A hook's output reaches Claude for only a few events, such as `SessionStart`
and `UserPromptSubmit`. For the others, including `Stop`, Claude Code writes
stdout to the debug log, so a hook that only prints shows nothing: write to a
file, as above, or to another tool. `Stop` fires at the end of every response,
not once per session.
