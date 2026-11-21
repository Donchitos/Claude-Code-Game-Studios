# /setup-engine — Section 12: Output Summary

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 12. Output Summary

After setup is complete, output:

```
Engine Setup Complete
=====================
Engine:          [name] [version]
Language:        [GDScript | C# | GDScript + C# | C# | C++ + Blueprint | Blueprint + C++ | TypeScript]
Knowledge Risk:  [LOW/MEDIUM/HIGH]
Reference Docs:  [created/skipped]
CLAUDE.md:       [updated]
Tech Prefs:      [created/updated]
project.yaml:    [created/updated]
Agent Config:    [verified]

Next Steps:
1. Review docs/engine-reference/<engine>/VERSION.md
```

Then print **one** Next-Steps list: the main path, at every tier, in `/next-step`'s
order (make a game, change it after you play it, grow it). Pick it by `/next-step`'s
test: is there a game yet (`prototypes/*/index.html`, or 10 or more source files in
the code root)?

**No game yet:**
```
2. Make a game: run /prototype and say the game in one line. On Web it is
   playable; on an engine it is a quick test build.
3. Play it, then ask for changes in plain words ("make the jump higher").
4. Not sure what comes next? /next-step names the one next step.
```

**A game is here already:**
```
2. Play it, then ask for changes in plain words ("make the jump higher").
3. When it is worth keeping, /next-step names the one next step to grow it.
```

At `standard` or `full`, add this line under the list:
```
Studio mode (design documents first): /brainstorm, then /map-systems and
/design-system, then /sprint-plan new.
```

---

Verdict: **COMPLETE** — engine configured and reference docs populated.
