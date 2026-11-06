# Error Recovery Protocol
# 错误恢复协议

Shared procedure for any skill that spawns agents via the `Agent` tool, used by
the `## Error Recovery Protocol` section of each orchestration and review skill.
Two imperatives apply to all of them: **surface a blocked agent immediately, and
produce a partial report.** Each skill's own **Common blockers** list is
skill-specific and is not repeated here.
适用于任何通过 `Agent` 工具生成智能体的技能的共享流程，由每个编排与评审
技能的 `## Error Recovery Protocol` 章节引用。两条铁律适用于所有这些技能：
**立即暴露被阻塞的智能体，并生成部分报告。** 每个技能自己的 **Common blockers**
列表是技能特定的，这里不重复。

## Trigger 0 — verify the artifact before reading the response
## 触发器 0 — 在读取响应之前先验证产物

**Before applying anything below, and before treating a phase as complete: if
the return contract named a path, check that the path exists.** A named
artifact that is not on disk is a FAILED PHASE, no matter how the agent's
response reads.
**在应用以下任何内容之前，以及在将一个阶段视为完成之前：如果返回契约
指明了路径，就检查该路径是否存在。** 一个被指明但不在磁盘上的产物
是一个失败的阶段，无论智能体的响应读起来如何。

This trigger exists because the three below are not sufficient. They fire on
BLOCKED, on an error, and on "cannot complete" — and an agent can fail in a way
that is none of those. A parallel agent can do a lot of work and then return a
single fluent preamble — "I'll verify the build infrastructure…" — with no
path, no summary, no BLOCKED item, and **no file written**. Nothing in
steps 1–4 matches that shape. An orchestrator reading the transcript sees a
plausible response and advances, and half a parallel phase disappears with no
signal at all.
这个触发器之所以存在，是因为下面三个触发器并不充分。它们会在 BLOCKED、出错
以及“无法完成”时触发 — 而智能体可能以一种不属于这些情况的方式失败。
一个并行智能体可以做大量工作，然后只返回一段流畅的开场白 ——
“我会验证构建基础设施……” —— 没有路径、没有摘要、没有 BLOCKED 项，
并且**没有写入任何文件**。步骤 1–4 中没有任何一项匹配这种形态。
阅读转录的编排者看到一个看似合理的响应便继续推进，
而半个并行阶段就这样毫无信号地消失了。

The work is usually not lost. Resume the agent with an explicit "you did not
honour the return contract" message. Its investigation is still in context, so
it only has to do the write-and-return step it skipped. So the recovery is
cheap; the detection is the hard part, and the detection cannot come from
reading the response.
工作通常没有丢失。用明确的“你没有遵守返回契约”消息恢复该智能体。
它的调查仍在上下文中，所以它只需执行跳过的写入并返回步骤。
因此恢复是廉价的；检测才是困难的部分，而检测无法通过
读取响应来完成。

**A fluent response is not evidence that a phase ran.** The artifact is —
observe the artifact, not the transcript. The rule applies to sub-agents
exactly as it does to skills.
**流畅的响应不是阶段已运行的证据。** 产物才是 —
观察产物，而不是转录。该规则对子智能体的适用方式与对技能完全相同。

When the path is missing:
当路径缺失时：

1. Do **not** advance the pipeline or summarise the phase as done.
1. **不要**推进流程，也不要把该阶段总结为已完成。
2. Resume the agent, naming the unmet contract explicitly and telling it that
   "I could not write" is a valid answer but silence is not. Prefer resuming
   over re-spawning — the context is usually still there, and a re-spawn pays
   for the whole investigation again.
2. 恢复该智能体，明确说出未满足的契约，并告诉它
   “我无法写入”是有效答案，但沉默不是。优先恢复而非重新生成 —
   上下文通常还在，重新生成要为整个调查再付一次代价。
3. If the second attempt also produces nothing, treat it as BLOCKED and apply
   steps 1–5 below.
3. 如果第二次尝试仍没有任何产物，将其视为 BLOCKED 并应用
   下面的步骤 1–5。

---

If any spawned agent returns BLOCKED, errors, or cannot complete:
如果任何被生成的智能体返回 BLOCKED、出错或无法完成：

1. **Surface immediately** — report "[AgentName]: BLOCKED — [reason]" to the user
   before continuing to dependent phases. The reason names what is missing and
   where it was expected (the path or the input), so the user can supply it.
1. **立即暴露** — 在继续依赖阶段之前向用户报告
   “[AgentName]: BLOCKED — [原因]”。原因要指明缺少什么以及
   在哪里被期望（路径或输入），以便用户提供它。
2. **Assess dependencies** — check whether the blocked agent's output is required
   by subsequent phases. If yes, do not proceed past that dependency point without
   user input.
2. **评估依赖关系** — 检查后续阶段是否需要该阻塞智能体的输出。
   如果是，在没有用户输入的情况下不要越过该依赖点。
3. **Offer options** via `AskUserQuestion`:
   - Skip this agent and note the gap in the final report — never fill the skipped agent's section with content of your own
   - Retry with narrower scope
   - Stop here and resolve the blocker first
3. 通过 `AskUserQuestion` **提供选项**：
   - 跳过此智能体并在最终报告中注明缺口 — 绝不要用自己的内容填补被跳过智能体的章节
   - 以更窄的范围重试
   - 在此停止并先解决阻塞项
4. **Always produce a partial report** — output whatever was completed. Never
   discard work because one agent blocked.
4. **始终生成部分报告** — 输出已完成的所有内容。绝不要
   因为一个智能体被阻塞就丢弃工作。
5. **A skip does not clear the block.** In a `/team-*` pipeline, choosing "skip
   this agent and note the gap" lets the remaining phases run, but the skipped
   agent's work is missing from what the pipeline delivers: the final verdict is
   BLOCKED, naming the skipped agent and its gap — never COMPLETE.
5. **跳过并不清除阻塞。** 在 `/team-*` 流程中，选择“跳过
   此智能体并注明缺口”会让剩余阶段继续运行，但被跳过
   智能体的工作从流程交付的内容中缺失：最终裁决是
   BLOCKED，并指出被跳过的智能体及其缺口 — 绝不是 COMPLETE。
