---
name: changelog
description: "Old name of /write-changelog. Prints one line, then runs /write-changelog."
argument-hint: "[version|sprint-number]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Skill(write-changelog)
model: sonnet
---

# /changelog — old name of /write-changelog

Several AI tools keep `/changelog` for a command of their own, so this skill is now
`/write-changelog`.

1. Print this line exactly, as the first line of your reply:

   /changelog is now /write-changelog. Running /write-changelog.

2. Run the `write-changelog` skill with the Skill tool, passing these arguments unchanged
   (none, if this is empty): $ARGUMENTS

Do nothing else here: `/write-changelog` does the work.
