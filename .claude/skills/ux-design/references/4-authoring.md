# /ux-design — Section 4: Section-by-Section Authoring

> Part of `/ux-design`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 4. Section-by-Section Authoring

Walk through each section in order. For **each section**, follow this cycle:

```
Context  ->  Questions  ->  Options  ->  Decision  ->  Draft  ->  Approval  ->  Write
```

1. **Context**: State what this section needs to contain and surface any relevant
   constraints from context gathered in Phase 2.
2. **Questions**: Ask what is needed to draft this section. Use `AskUserQuestion`
   for constrained choices, conversational text for open-ended exploration.
3. **Options**: Where design choices exist, present 2-4 approaches with pros/cons.
   Explain reasoning in conversation, then use `AskUserQuestion` to capture the decision.
4. **Decision**: User picks an approach or provides custom direction.
5. **Draft**: Write the section content in conversation for review. Flag provisional
   assumptions explicitly.
6. **Approval**: Use `AskUserQuestion`:
   - "Does this capture the [section name] correctly?"
   - Options: "Yes — write it to the file", "Small changes needed (describe below)", "Major rethink needed"
   Do not proceed to step 7 until the user selects "Yes".
7. **Write**: Use `AskUserQuestion`: "May I write the [section name] section to `[filepath]`?"
   - Options: "Yes, write it", "Wait — one more change"
   Once confirmed, use `Edit` to replace the `[To be designed]` placeholder with approved content.

After writing each section, update `production/session-state/active.md`.
