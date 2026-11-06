> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起该门禁的技能会将此文件的路径传给总监智能体；由智能体读取它——父会话不应读取。

# LP-CODE-REVIEW — Lead Programmer Code Review

# LP-CODE-REVIEW — 主程序代码评审

Agent: `lead-programmer` | Model tier: Sonnet

智能体：`lead-programmer` | 模型层级：Sonnet

**Trigger**: After a dev story is implemented (`/dev-story`, `/story-done`), or
as part of `/code-review`

**触发时机**：开发故事实现完成后（`/dev-story`、`/story-done`），或作为 `/code-review` 的一部分

**Context to pass**:
- Implementation file paths
- Story file path (for acceptance criteria)
- Relevant GDD section
- ADR that governs this system

**需传入的上下文**：
- 实现文件路径
- 故事文件路径（用于验收标准）
- 相关 GDD 章节
- 管辖该系统的 ADR

**Prompt**:
> "Review this implementation against the story acceptance criteria and governing
> ADR. Does the code match the architecture boundary definitions? Are there
> violations of the coding standards or forbidden patterns? Is the public API
> testable and documented? Are there any correctness issues against the GDD rules?
> Return APPROVE, CONCERNS [specific issues], or REJECT [must be revised before merge]."

**提示词**：
> “对照故事验收标准与管辖 ADR 评审此实现。代码是否与架构边界定义相符？是否存在对编码标准或禁用模式的违反？公共 API 是否可测试并有文档？是否存在任何与 GDD 规则不符的正确性问题？返回 APPROVE、CONCERNS [具体问题]，或 REJECT [必须在合并前修订]。”

**Verdicts**: APPROVE / CONCERNS / REJECT

**裁定**：APPROVE / CONCERNS / REJECT
