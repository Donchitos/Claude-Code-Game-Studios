# /ux-design — Section 4: Section-by-Section Authoring
# /ux-design — 第 4 节：逐分区编写

> Part of `/ux-design`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/ux-design` 的组成部分。`SKILL.md` 指明何时读取本文件；它已解析的各项设置，
> 以及其后续标题下所列的规则，在此同样适用。

## 4. Section-by-Section Authoring
## 4. 逐分区编写

Walk through each section in order. For **each section**, follow this cycle:

按顺序走查每个分区。对**每个分区**，遵循此循环：

```
Context  ->  Questions  ->  Options  ->  Decision  ->  Draft  ->  Approval  ->  Write
```

```
上下文  ->  提问  ->  选项  ->  决策  ->  草稿  ->  批准  ->  写入
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

1. **上下文**：说明本分区需要包含什么，并揭示第 2 阶段收集的上下文中
   任何相关约束。
2. **提问**：询问起草本分区所需的信息。对有约束的选择使用 `AskUserQuestion`，
   对开放式探索使用对话式文本。
3. **选项**：凡存在设计选择之处，给出 2-4 种方法及其优缺点。
   在对话中解释理由，然后用 `AskUserQuestion` 捕获决策。
4. **决策**：用户选择一种方法，或给出自定义方向。
5. **草稿**：在对话中写出分区内容以供审阅。明确
   标出暂定假设。
6. **批准**：使用 `AskUserQuestion`：
   - “这是否正确捕捉了 [section name]？”
   - 选项：“是——写入文件”、“需要小幅修改（在下方描述）”、“需要大幅重新考虑”
   在用户选择“是”之前，不要进入第 7 步。
7. **写入**：使用 `AskUserQuestion`：“我可以把 [section name] 分区写入 `[filepath]` 吗？”
   - 选项：“是，写入”、“等等——还要改一处”
   确认后，使用 `Edit` 把 `[To be designed]` 占位符替换为已批准的内容。

After writing each section, update `production/session-state/active.md`.

每写完一个分区后，更新 `production/session-state/active.md`。
