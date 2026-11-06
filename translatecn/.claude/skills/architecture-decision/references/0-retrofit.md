# /architecture-decision — Retrofit Mode

# /architecture-decision —— 改造模式

> Part of `/architecture-decision`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> `/architecture-decision` 的一部分。`SKILL.md` 说明了何时读取本文件；它解析出的设置以及它后续标题下的规则在这里同样适用。

**If the argument starts with `retrofit` followed by a file path**

**如果参数以 `retrofit` 开头，后跟一个文件路径**

(e.g., `/architecture-decision retrofit docs/architecture/adr-0001-event-system.md`):

（例如 `/architecture-decision retrofit docs/architecture/adr-0001-event-system.md`）：

Enter **retrofit mode**:

进入**改造模式**：

1. Read the existing ADR file completely. This step needs the whole ADR: read it
   in ranges by its headings (found with the Grep tool: pattern `^#`, content
   mode), since a whole-file Read over 40 KB is refused.

1. 完整读取现有的 ADR 文件。这一步需要整个 ADR：按标题分段读取（用 Grep 工具查找，模式 `^#`，内容模式），因为超过 40 KB 的整文件 Read 会被拒绝。

2. Identify which template sections are present by scanning headings:
   - `## Status` — **BLOCKING if missing**: `/story-readiness` cannot check ADR acceptance
   - `## ADR Dependencies` — HIGH if missing: dependency ordering breaks
   - `## Engine Compatibility` — HIGH if missing: post-cutoff risk unknown. A
     present table with no **Layer** row is HIGH too: the ADR counts as critical
     wherever it is read, so at `standard` its advisory items become blockers
   - `## GDD Requirements Addressed` — MEDIUM if missing: traceability lost
   - `## Date` — MEDIUM if missing, and no `## Last Verified` either: `/create-stories`
     stamps stories with it and `/dev-story` compares against it, so without it a
     story can never tell whether the ADR changed

2. 通过扫描标题来识别哪些模板章节存在：
   - `## Status` —— **缺失则阻断**：`/story-readiness` 无法检查 ADR 的采纳状态
   - `## ADR Dependencies` —— 缺失则为高：依赖排序失效
   - `## Engine Compatibility` —— 缺失则为高：截止点之后的风险未知。表存在但没有 **Layer** 行同样算高：该 ADR 在被读取的任何地方都被计为关键，因此在 `standard` 下其建议项会变为阻断项
   - `## GDD Requirements Addressed` —— 缺失则为中：追溯性丢失
   - `## Date` —— 缺失且也没有 `## Last Verified` 则为中：`/create-stories` 用它给故事打戳，`/dev-story` 用它作比较，因此没有它，故事永远无法判断 ADR 是否发生了变化

3. Present to the user:
   ```
   ## Retrofit: [ADR title]
   File: [path]

   Sections already present (will not be touched):
   ✓ Status: [current value, or "MISSING — will add"]
   ✓ [section]

   Missing sections to add:
   ✗ Status — BLOCKING (stories cannot validate ADR acceptance without this)
   ✗ ADR Dependencies — HIGH
   ✗ Engine Compatibility — HIGH
   ```

3. 向用户呈现（格式如上所示）。

4. Ask: "Shall I add the [N] missing sections? I will not modify any existing content."
   If no: write nothing, and report the missing sections by name.

4. 询问："我可以添加这 [N] 个缺失的章节吗？我不会修改任何现有内容。"如果回答否：什么都不写，并按名称报告缺失的章节。

5. If yes:
   - For **Status**: ask the user — "What is the current status of this decision?"
     Options: "Proposed", "Accepted", "Deprecated", "Superseded by ADR-XXXX"
     An `Accepted` answer — a decision already in force — is not written as
     given: write `Proposed`, add the other missing sections, then run
     acceptance mode (below) on this ADR. Its dependency check, confirmation and
     story unblocking apply here too; it stays the only path that sets `Accepted`.
   - For **ADR Dependencies**: ask — "Does this decision depend on any other ADR?
     Does it enable or block any other ADR or epic?" Accept "None" for each field.
   - For **Engine Compatibility**: read the engine reference docs (same as Step 1 below)
     and ask the user to confirm the domain. Then generate the table with verified data,
     its Layer row included.
   - For a present Engine Compatibility table with no **Layer** row: find the
     layer as `references/5-generate.md` says under "Always write the Layer row",
     and add the row under **Domain**. It adds a row and changes none.
   - For **GDD Requirements Addressed**: ask — "Which GDD systems motivated this decision?
     What specific requirement in each GDD does this ADR address?"
   - Append each missing section to the ADR file using the Edit tool.
   - For **Date** (counted only when there is no `## Last Verified`): append
     `## Date` with today's date — even when it is the only missing section, the
     case `/dev-story` sends you here for — and say that it records the retrofit,
     not when the decision was made.
   - **Never modify any existing section.** Only append or fill absent sections.

5. 如果是：
   - 对于 **Status**：询问用户 —— "该决策当前的状态是什么？"选项："Proposed"、"Accepted"、"Deprecated"、"Superseded by ADR-XXXX"。若回答 `Accepted` —— 一个已经生效的决策 —— 不会按原样写入：写入 `Proposed`，添加其他缺失的章节，然后对该 ADR 运行采纳模式（见下文）。其依赖检查、确认和故事解阻在这里同样适用；它仍是唯一设置 `Accepted` 的路径。
   - 对于 **ADR Dependencies**：询问 —— "该决策是否依赖于任何其他 ADR？它是否启用或阻断了任何其他 ADR 或史诗？"每个字段都接受 "None"。
   - 对于 **Engine Compatibility**：读取引擎参考文档（同下方步骤 1），并请用户确认领域。然后用已验证的数据生成表格，包括其 Layer 行。
   - 对于存在但没有 **Layer** 行的 Engine Compatibility 表：按 `references/5-generate.md` 中"Always write the Layer row"所述找到层级，并在 **Domain** 下添加该行。它只添加一行，不改变任何内容。
   - 对于 **GDD Requirements Addressed**：询问 —— "哪些 GDD 系统促成了该决策？该 ADR 涉及每个 GDD 中的哪条具体需求？"
   - 使用 Edit 工具将每个缺失章节追加到 ADR 文件。
   - 对于 **Date**（仅在没有 `## Last Verified` 时计入）：追加 `## Date` 并写入今天的日期 —— 即使它是唯一缺失的章节，也就是 `/dev-story` 把你送到这里的情形 —— 并说明它记录的是改造时间，而不是决策作出的时间。
   - **绝不修改任何现有章节。**只追加或填充缺失的章节。

6. Suggest: "Run `/architecture-review` to re-validate coverage now that this ADR
   has its Status and Dependencies fields."

6. 建议："既然该 ADR 已经有了 Status 和 Dependencies 字段，运行 `/architecture-review` 来重新验证覆盖情况。"
