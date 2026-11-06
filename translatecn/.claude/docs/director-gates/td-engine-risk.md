> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

> 门禁定义。发起该门禁的技能会将此文件的路径传给总监智能体；由智能体读取它——父会话不应读取。

# TD-ENGINE-RISK — Engine Version Risk Review

# TD-ENGINE-RISK — 引擎版本风险评审

Agent: `technical-director` | Model tier: Opus | Domain: Architecture, engine risk, performance

智能体：`technical-director` | 模型层级：Opus | 领域：架构、引擎风险、性能

**Trigger**: When making architecture decisions that touch post-cutoff engine APIs,
or before finalizing any engine-specific implementation approach

**触发时机**：当做出涉及知识截止时间之后的引擎 API 的架构决策时，或在最终确定任何引擎相关实现方案之前

**Context to pass**:
- The specific API or feature being used
- Engine version and LLM knowledge cutoff (from `docs/engine-reference/[engine]/VERSION.md`)
- Relevant excerpt from breaking-changes or deprecated-apis docs

**需传入的上下文**：
- 正在使用的具体 API 或特性
- 引擎版本与 LLM 知识截止时间（来自 `docs/engine-reference/[engine]/VERSION.md`）
- 来自 breaking-changes 或 deprecated-apis 文档的相关摘录

**Prompt**:
> "Review this engine API usage against the version reference. Is this API present
> in [engine version]? Has its signature, behaviour, or namespace changed since the
> LLM knowledge cutoff? Are there known deprecations or post-cutoff alternatives?
> Return APPROVE (safe to use as described), CONCERNS [verify before implementing],
> or REJECT [API has changed — provide corrected approach]."

**提示词**：
> “对照版本参考评审此处的引擎 API 用法。该 API 在 [引擎版本] 中是否存在？自 LLM 知识截止时间以来，其签名、行为或命名空间是否发生变化？是否存在已知的弃用项或截止时间之后的替代方案？返回 APPROVE（按所述方式使用是安全的）、CONCERNS [实现前需核实]，或 REJECT [API 已发生变化——给出修正后的方案]。”

**Verdicts**: APPROVE / CONCERNS / REJECT

**裁定**：APPROVE / CONCERNS / REJECT
