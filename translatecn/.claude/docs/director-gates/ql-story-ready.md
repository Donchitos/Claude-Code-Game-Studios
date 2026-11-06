> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起技能会将该文件的路径传给总监智能体；由该智能体读取此文件——父会话不应读取。

# QL-STORY-READY — QA Lead Story Readiness Check

# QL-STORY-READY — QA 主管的故事就绪检查

Agent: `qa-lead` | Model tier: session (inherit)

智能体：`qa-lead` | 模型层级：会话（继承）

**Trigger**: Before a story is accepted into a sprint — invoked by `/create-stories`
and `/story-readiness`

**触发**：在一个故事被接纳进入冲刺之前——由 `/create-stories` 与 `/story-readiness` 调用

**Context to pass**:
- Story file path — or, from `/create-stories` (which runs this gate before any
  story is written), the story inline
- Story type (Logic / Integration / Visual/Feel / UI / Config/Data)
- Acceptance criteria list (verbatim from the story)
- The GDD requirement (TR-ID and text) the story covers

**需传入的上下文**：
- 故事文件路径——或者，从 `/create-stories` 调用时（它会在写入任何故事之前运行此门禁），内联提供该故事
- 故事类型（Logic / Integration / Visual/Feel / UI / Config/Data）
- 验收标准列表（逐字取自该故事）
- 该故事所覆盖的 GDD 需求（TR-ID 与文本）

**Prompt**:
> "Review this story's acceptance criteria for testability before it enters the
> sprint. Are all criteria specific enough that a developer would know unambiguously
> when they are done? For Logic-type stories: can every criterion be verified with
> an automated test? For Integration stories: is each criterion observable in a
> controlled test environment? Flag criteria that are too vague to implement
> against, and flag criteria that require a full game build to test (mark these
> DEFERRED, not BLOCKED). Return ADEQUATE (criteria are implementable as written),
> GAPS [specific criteria needing refinement], or INADEQUATE [criteria are too
> vague — story must be revised before sprint inclusion]."

**提示词**：
> "在该故事进入冲刺之前，评审其验收标准的可测试性。所有标准是否都足够具体，使开发者能明确知道何时算完成？对于 Logic 类型的故事：每一条标准能否通过自动化测试验证？对于 Integration 类型的故事：每一条标准能否在受控测试环境中被观察到？标出过于模糊而无法据此实现的标准，并标出需要完整游戏构建才能测试的标准（将其标为 DEFERRED，而非 BLOCKED）。返回 ADEQUATE（标准按现有写法可实现）、GAPS［需要细化的具体标准］，或 INADEQUATE［标准过于模糊——故事必须在纳入冲刺前修订］。"

**Verdicts**: ADEQUATE / GAPS / INADEQUATE

**裁定**：ADEQUATE / GAPS / INADEQUATE
