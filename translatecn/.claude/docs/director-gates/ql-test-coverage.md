> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起该门禁的技能会将此文件的路径传给总监智能体；由智能体读取它——父会话不应读取。

# QL-TEST-COVERAGE — QA Lead Test Coverage Review

# QL-TEST-COVERAGE — QA 主管测试覆盖评审

Agent: `qa-lead` | Model tier: session (inherit)

智能体：`qa-lead` | 模型层级：session（继承）

**Trigger**: After implementation stories are complete — `/story-done` runs it for
each story before marking it Complete

**触发时机**：实现故事完成后——`/story-done` 在将每个故事标记为 Complete 之前对其运行该门禁

**Context to pass**:
- List of implemented stories with story types (Logic / Integration / Visual / UI / Config)
- Test file paths in `tests/`
- GDD acceptance criteria for the system

**需传入的上下文**：
- 已实现故事清单及其故事类型（Logic / Integration / Visual / UI / Config）
- `tests/` 中的测试文件路径
- 该系统的 GDD 验收标准

**Prompt**:
> "Review the test coverage for these implementation stories. Are all Logic stories
> covered by passing unit tests? Are Integration stories covered by integration
> tests or documented playtests? Are the GDD acceptance criteria each mapped to at
> least one test? Are there untested edge cases from the GDD Edge Cases section?
> Return ADEQUATE (coverage meets standards), GAPS [specific missing tests], or
> INADEQUATE [critical logic is untested — do not advance]."

**提示词**：
> “评审这些实现故事的测试覆盖。所有 Logic 故事是否都由通过的单元测试覆盖？Integration 故事是否由集成测试或有记录的试玩覆盖？GDD 验收标准是否每条都至少映射到一个测试？GDD 边界情况章节中是否存在未测试的边界情况？返回 ADEQUATE（覆盖达标）、GAPS [具体缺失的测试]，或 INADEQUATE [关键逻辑未测试——不得推进]。”

**Verdicts**: ADEQUATE / GAPS / INADEQUATE

**裁定**：ADEQUATE / GAPS / INADEQUATE
