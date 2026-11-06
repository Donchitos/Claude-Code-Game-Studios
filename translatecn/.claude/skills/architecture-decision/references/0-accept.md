# /architecture-decision — Acceptance Mode

# /architecture-decision —— 采纳模式

> Part of `/architecture-decision`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> `/architecture-decision` 的一部分。`SKILL.md` 说明了何时读取本文件；它解析出的设置以及它后续标题下的规则在这里同样适用。

**If the argument starts with `accept` followed by an ADR id**

**如果参数以 `accept` 开头，后跟一个 ADR id**

(e.g., `/architecture-decision accept ADR-0005`):

（例如 `/architecture-decision accept ADR-0005`）：

Enter **acceptance mode**. This is the *only* path in the framework that moves an
ADR from `Proposed` to `Accepted`. Authoring always produces `Proposed`
(Step 5), while
`/create-control-manifest`, `/create-epics`, `/create-stories` and `/gate-check`
all require `Accepted` — so without this mode an ADR would enter a state it
never leaves.

进入**采纳模式**。这是框架中*唯一*能将 ADR 从 `Proposed` 变为 `Accepted` 的路径。编写过程总是产出 `Proposed`（步骤 5），而 `/create-control-manifest`、`/create-epics`、`/create-stories` 和 `/gate-check` 都要求 `Accepted` —— 因此若没有此模式，ADR 将进入一个永远无法离开的状态。

1. **Resolve the id to a file, then read it.** Glob
   `docs/architecture/adr-NNNN-*.md` for the given number. If **no** file matches,
   or **more than one** does, stop and say which — do not pick one. If the file
   has no `## Status` section, stop and say so; a missing Status is exactly what
   retrofit mode is for.

1. **将 id 解析为文件，然后读取它。** 用 Glob 匹配 `docs/architecture/adr-NNNN-*.md` 中给定的编号。如果**没有**文件匹配，或**不止一个**匹配，停止并说明是哪种情况 —— 不要挑一个。如果文件没有 `## Status` 章节，停止并说明；缺少 Status 正是改造模式存在的理由。

2. **Check the current status.** If it is already `Accepted`, say so and stop.
   If it is `Deprecated` or `Superseded`, refuse: reviving a superseded decision
   is a new ADR, not a status edit.

2. **检查当前状态。** 如果它已经是 `Accepted`，说明这一点并停止。如果它是 `Deprecated` 或 `Superseded`，拒绝：恢复一个已被取代的决策应当是一个新的 ADR，而不是一次状态编辑。

3. **Check its dependencies first.** Read `## ADR Dependencies`.

3. **先检查它的依赖项。** 读取 `## ADR Dependencies`。

   **If that section is absent, empty, or reads `UNKNOWN`, do not read it as
   "no dependencies" — refuse and say which:**
   > "ADR-0005's dependency section is [absent / UNKNOWN], so I cannot tell what
   > this decision rests on. An empty dependency list and an unexamined one look
   > identical here, and only one of them is safe to accept. Run
   > `/architecture-decision retrofit <path>` to establish it."

   **如果该章节缺失、为空或写着 `UNKNOWN`，不要把它解读为"没有依赖" —— 拒绝并说明是哪种：**
   > "ADR-0005 的依赖章节[缺失 / 为 UNKNOWN]，因此我无法判断该决策依托于什么。空依赖列表和未经检查的列表在这里看起来完全相同，而其中只有一种可以安全采纳。运行 `/architecture-decision retrofit <path>` 来确立它。"

   A dependency check reading a field that defaults to empty is the vacuous-pass
   shape this gate exists to prevent — the check would examine nothing and report
   clean.

   依赖检查若读取一个默认为空的字段，正是该门禁要防止的"空洞通过"形态 —— 检查将什么都不检查，却报告一切正常。

   If it depends on any ADR that is not itself `Accepted`, **refuse and name them**:
   > "ADR-0005 depends on ADR-0002, which is still Proposed. Accept ADR-0002
   > first — an accepted decision resting on an unaccepted one is not a decision,
   > it is a deferral with a different label."
   This is the same dependency rule `/architecture-review` already flags; here it
   is enforced rather than reported.

   如果它依赖于任何本身尚未 `Accepted` 的 ADR，**拒绝并指出它们**：
   > "ADR-0005 依赖于 ADR-0002，后者仍为 Proposed。请先采纳 ADR-0002 —— 一个建立在未被采纳决策之上的已采纳决策不是决策，而是换了个标签的延期。"
   这与 `/architecture-review` 已经标记的依赖规则相同；在这里它是被强制执行，而不仅仅是报告。

4. **Confirm with the user, always.** Per `CONTRACT.md`, acceptance authority is
   **the user, or `technical-director` on the user's explicit confirmation — no
   other agent, and never this skill on its own.** Use `AskUserQuestion`:
   - Prompt: "Accept ADR-NNNN — [title]? This is what unblocks stories and epics
     that depend on it."
   - Options: `[A] Yes — accept it` / `[B] Not yet — leave it Proposed`
   **This prompt fires regardless of `modes.automation`, including `autonomous`.**
   Acceptance is the decision the whole architecture pipeline gates on; it is not
   a step to be inferred.

4. **始终与用户确认。** 依据 `CONTRACT.md`，采纳权限属于**用户，或在用户明确确认下的 `technical-director` —— 不是任何其他智能体，也绝不是本技能自行决定。** 使用 `AskUserQuestion`：
   - 提示："采纳 ADR-NNNN —— [标题]？这正是为依赖它的故事和史诗解阻的一步。"
   - 选项：`[A] 是 —— 采纳它` / `[B] 还不是 —— 保留为 Proposed`
   **无论 `modes.automation` 如何，包括 `autonomous`，此提示都会触发。** 采纳是整个架构流水线所把关的决策；它不是可以推断的步骤。

5. **Find the stories this will unblock, BEFORE the prompt in step 4.** Grep
   every story for a Blocked Status line —
   `Grep pattern="Status\**:\**\s*Blocked" path="production/epics" glob="**/story-*.md" output_mode="files_with_matches"`,
   which matches `> **Status**: Blocked` (the form `/create-stories` writes),
   `**Status:** Blocked` and `Status: Blocked` — and keep the files that name
   this ADR's id as the reason they are blocked. That pairing is what "blocked
   pending this ADR" means — a story blocked for an unrelated reason will not
   name it. Leave out a story that names this ADR only as the successor to point
   at (`point the story at ADR-NNNN`, the note for a `Deprecated` or
   `Superseded` ADR): it is still governed by the old ADR, and accepting the
   successor does not re-point it.

5. **在步骤 4 的提示之前，先找出此次采纳将解阻的故事。** 用 Grep 在每个故事中查找状态为 Blocked 的行 —— `Grep pattern="Status\**:\**\s*Blocked" path="production/epics" glob="**/story-*.md" output_mode="files_with_matches"`，它会匹配 `> **Status**: Blocked`（`/create-stories` 写入的形式）、`**Status:** Blocked` 和 `Status: Blocked` —— 并保留那些将此 ADR 的 id 列为受阻原因的文件。这种配对正是"因该 ADR 而受阻"的含义 —— 因无关原因受阻的故事不会提到它。排除那些仅将此 ADR 作为后继指引目标而提及的故事（`point the story at ADR-NNNN`，即针对 `Deprecated` 或 `Superseded` ADR 的说明）：它仍受旧 ADR 约束，采纳后继者并不会重新指向它。

   > **Stories live only under `production/epics/`.** A flat top-level stories
   > directory does not exist and no skill creates one — never write or match a
   > path outside `production/epics/`. `/dev-story` matches entries *by file
   > path*, so a story recorded under any other path silently fails to match and
   > never gets picked up.

   > **故事只存放在 `production/epics/` 下。** 不存在扁平的顶层 stories 目录，也没有任何技能会创建它 —— 绝不要在 `production/epics/` 之外写入或匹配路径。`/dev-story` *按文件路径*匹配条目，因此记录在其他任何路径下的故事会静默匹配失败，永远不会被拾取。

   Feed the count into step 4's prompt so it reads *"3 stories become Ready"*
   rather than a generic claim: **the user is being asked to authorise an effect, and should be
   shown the effect.** If none match, say "no stories are waiting on this" — that
   is useful information, not an empty result to omit.

   将该计数注入步骤 4 的提示，使其读作*"3 个故事变为 Ready"*，而不是泛泛的断言：**用户是在被请求批准一个效果，就应当看到这个效果。** 如果没有匹配项，就说"没有故事在等待这个" —— 这是有用的信息，而不是可以省略的空结果。

6. On confirmation, `Edit` the `## Status` line to `Accepted`. Leave an existing
   `## Date` as it is: it records when the ADR was written, and `/create-stories`
   stamps stories with it (or `## Last Verified`), so rewriting it on acceptance
   would make every story drafted against the Proposed ADR look out of date to
   `/dev-story`. **If that section is absent, add it** with today's date — retrofit
   mode already owns this shape, and acceptance must not fail on a template that
   predates the field.

6. 确认后，用 `Edit` 将 `## Status` 行改为 `Accepted`。保留现有的 `## Date` 不变：它记录的是 ADR 的编写时间，而 `/create-stories` 会用它（或 `## Last Verified`）给故事打戳，因此若在采纳时重写它，会让每个基于 Proposed ADR 起草的故事对 `/dev-story` 显得过时。**如果该章节缺失，就添加它**并写入今天的日期 —— 改造模式已经负责这种形态，采纳不能因为模板早于该字段而失败。

7. Then set each story found in step 5 from `Blocked` to `Ready`. Unblocking is a
   consequence of acceptance, never of authoring — see Step 6's note below.

7. 然后将步骤 5 中找到的每个故事从 `Blocked` 改为 `Ready`。解阻是采纳的结果，绝不是编写的结果 —— 见下方步骤 6 的说明。

8. Report what moved: the ADR (and its `## Date`, if one was added), and every
   story that became Ready.

8. 报告哪些内容发生了变化：该 ADR（以及新增的 `## Date`，若有），以及每个变为 Ready 的故事。
