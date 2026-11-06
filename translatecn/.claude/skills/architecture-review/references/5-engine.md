# /architecture-review — Phases 5 and 5b: Engine Cross-Check and Design Revision Flags
# /architecture-review — 阶段 5 与 5b：引擎交叉检查与设计修订标记

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/architecture-review` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 5: Engine Compatibility Cross-Check
## 阶段 5：引擎兼容性交叉检查

**In this file:**
**本文件内容：**

- Version Consistency
- 版本一致性
- Post-Cutoff API Consistency
- 训练截止后 API 一致性
- Deprecated API Check
- 废弃 API 检查
- Missing Engine Compatibility Sections
- 缺失的引擎兼容性小节
- Engine Specialist Consultation
- 引擎专家咨询

Across all ADRs, check for engine consistency:
跨所有 ADR，检查引擎一致性：

### Version Consistency
### 版本一致性
- Do all ADRs that mention an engine version agree on the same version?
- 所有提及引擎版本的 ADR 是否都一致认可同一个版本？
- If any ADR was written for an older engine version, flag it as potentially stale
- 若有任何 ADR 是为较旧的引擎版本编写的，将其标记为可能已过时

### Post-Cutoff API Consistency
### 训练截止后 API 一致性
- Collect all "Post-Cutoff APIs Used" fields from all ADRs
- 收集所有 ADR 中的全部 "Post-Cutoff APIs Used" 字段
- For each, verify against the relevant module reference doc
- 对每一个，对照相关模块参考文档进行验证
- Check that no two ADRs make contradictory assumptions about the same post-cutoff API
- 检查没有两个 ADR 对同一训练截止后 API 作出相互矛盾的假设

### Deprecated API Check
### 废弃 API 检查
- Grep all ADRs for API names listed in `deprecated-apis.md`
- 在所有 ADR 中 Grep `deprecated-apis.md` 列出的 API 名称
- Flag any ADR referencing a deprecated API
- 标记任何引用废弃 API 的 ADR

### Missing Engine Compatibility Sections
### 缺失的引擎兼容性小节
- List all ADRs that are missing the Engine Compatibility section entirely
- 列出所有完全缺少 Engine Compatibility 小节的 ADR
- These are blind spots — their engine assumptions are unknown
- 这些是盲区 — 它们的引擎假设未知

Output format:
输出格式：
```
### Engine Audit Results
Engine: [name + version]
ADRs with Engine Compatibility section: X / Y total

Deprecated API References:
  - ADR-0002: uses [deprecated API] — deprecated since [version]

Stale Version References:
  - ADR-0001: written for [older version] — current project version is [version]

Post-Cutoff API Conflicts:
  - ADR-0004 and ADR-0007 both use [API] with incompatible assumptions
```

---

### Engine Specialist Consultation
### 引擎专家咨询

After completing the engine audit above, spawn the **primary engine specialist** via `Agent` for a domain-expert second opinion:
完成上述引擎审计后，通过 `Agent` 启动**主引擎专家**，以获取领域专家的第二意见：
- Resolve the primary specialist: `<engine>-specialist` derived from `engine.name` in `project.yaml` (Godot→`godot-specialist`, Unity→`unity-specialist`, Unreal→`unreal-specialist`); if `engine.name` is absent or empty, read the Primary line of the `## Engine Specialists` section in `.claude/docs/technical-preferences.md`
- 确定主专家：由 `project.yaml` 中的 `engine.name` 推导出的 `<engine>-specialist`（Godot→`godot-specialist`，Unity→`unity-specialist`，Unreal→`unreal-specialist`）；若 `engine.name` 缺失或为空，读取 `.claude/docs/technical-preferences.md` 中 `## Engine Specialists` 小节的 Primary 行
- If no engine is configured (neither source yields an engine), skip this consultation **Record ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)`` in this run's output.** A skipped check that says nothing is indistinguishable from a check that passed; the reader cannot tell engine guidance was never sought.
- 若未配置引擎（两个来源都未给出引擎），跳过本次咨询 **在本次运行的输出中记录 ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)``。** 一项什么都不说的被跳过检查，与一项通过了的检查无法区分；读者无法得知从未寻求过引擎指导。
- Spawn `subagent_type: [primary specialist]` with: all ADRs that contain engine-specific decisions or `Post-Cutoff APIs Used` fields, the engine reference docs, and the Phase 5 audit findings. Ask them to:
  1. Confirm or challenge each audit finding — specialists may know of engine nuances not captured in the reference docs
  2. Identify engine-specific anti-patterns in the ADRs that the audit may have missed (e.g., using the wrong Godot node type, Unity component coupling, Unreal subsystem misuse)
  3. Flag ADRs that make assumptions about engine behaviour that differ from the actual pinned version
- 以 `subagent_type: [primary specialist]` 启动，并传入：所有包含引擎相关决策或 `Post-Cutoff APIs Used` 字段的 ADR、引擎参考文档，以及阶段 5 的审计发现。请他们：
  1. 确认或质疑每项审计发现 — 专家可能了解参考文档未捕获的引擎细节
  2. 找出审计可能遗漏的 ADR 中的引擎相关反模式（例如使用了错误的 Godot 节点类型、Unity 组件耦合、Unreal 子系统误用）
  3. 标记那些对引擎行为作出与实际固定版本不符的假设的 ADR

Incorporate additional findings under `### Engine Specialist Findings` in the Phase 5 output. These feed into the final verdict — specialist-identified issues carry the same weight as audit-identified issues.
将额外的发现纳入阶段 5 输出中的 `### Engine Specialist Findings`。这些会汇入最终裁决 — 专家识别的问题与审计识别的问题具有同等权重。

---

## Phase 5b: Design Revision Flags (Architecture → GDD Feedback)
## 阶段 5b：设计修订标记（架构 → GDD 反馈）

For each **HIGH RISK engine finding** from Phase 5, check whether any GDD makes an
assumption that the verified engine reality contradicts.
对阶段 5 中的每项 **HIGH RISK 引擎发现**，检查是否有任何 GDD 作出了与已核实
引擎现实相矛盾的假设。

Specific cases to check:
需要检查的具体情形：

1. **Post-cutoff API behaviour differs from training-data assumptions**: If an ADR
   records a verified API behaviour that differs from the default LLM assumption,
   check all GDDs that reference the related system. Look for design rules written
   around the old (assumed) behaviour.
1. **训练截止后 API 行为与训练数据假设不同**：若某个 ADR 记录了与 LLM 默认
   假设不同的、已核实的 API 行为，检查所有引用相关系统的 GDD。寻找围绕旧的
   （假设的）行为编写的设计规则。
2. **Known engine limitations in ADRs**: If an ADR records a known engine limitation
   (e.g. "Jolt ignores HingeJoint3D damp", "D3D12 is now the default backend"), check
   GDDs that design mechanics around the affected feature.
2. **ADR 中的已知引擎限制**：若某个 ADR 记录了已知的引擎限制
   （例如 "Jolt ignores HingeJoint3D damp"、"D3D12 is now the default backend"），
   检查围绕受影响特性设计机制的 GDD。
3. **Deprecated API conflicts**: If Phase 5 flagged a deprecated API used in an ADR,
   check whether any GDD contains mechanics that assume the deprecated API's behaviour.
3. **废弃 API 冲突**：若阶段 5 标记了某个 ADR 中使用的废弃 API，检查是否有任何
   GDD 包含假定该废弃 API 行为的机制。

For each conflict found, record it in the GDD Revision Flags table:
对发现的每个冲突，将其记录在 GDD Revision Flags 表中：

```
### GDD Revision Flags (Architecture → Design Feedback)
These GDD assumptions conflict with verified engine behaviour or accepted ADRs.
The GDD should be revised before its system enters implementation.

| GDD | Assumption | Reality (from ADR/engine-reference) | Action |
|-----|-----------|--------------------------------------|--------|
| combat.md | "Use HingeJoint3D damp for weapon recoil" | Jolt ignores damp — ADR-0003 | Revise GDD |
```

If no revision flags are found, write: "No GDD revision flags — all GDD assumptions
are consistent with verified engine behaviour."
若未发现修订标记，写入："No GDD revision flags — all GDD assumptions
are consistent with verified engine behaviour."（无 GDD 修订标记 — 所有 GDD
假设都与已核实的引擎行为一致。）

Before asking, display the proposed change inline — show the current systems-index row for each flagged GDD and the proposed updated row side by side so the user can see exactly what will change.
在询问之前，内联展示拟议的变更 — 并排显示每个被标记 GDD 当前的 systems-index
行与拟议的更新行，以便用户确切看到将发生什么变化。

Then use `AskUserQuestion`:
然后使用 `AskUserQuestion`：
- "I found [N] GDD revision flag(s). May I update the systems index?"
  - [A] Yes — apply all [N] updates to the systems index now
  - [B] Show me the full diff first, then ask again
  - [C] No — leave the systems index unchanged for now
- "I found [N] GDD revision flag(s). May I update the systems index?"
  （我发现 [N] 个 GDD 修订标记。我可以更新 systems index 吗？）
  - [A] Yes — apply all [N] updates to the systems index now
    （是 — 立即将所有 [N] 项更新应用到 systems index）
  - [B] Show me the full diff first, then ask again
    （先给我看完整 diff，然后再问一次）
  - [C] No — leave the systems index unchanged for now
    （不 — 暂时保持 systems index 不变）

If [A]: apply the updates. Status field must be exactly `Needs Revision` — no parentheticals
(other skills match that exact string and parentheticals break the match).
If [B]: display the complete proposed systems-index section, then re-ask with `AskUserQuestion`.
若 [A]：应用这些更新。Status 字段必须恰好为 `Needs Revision` — 不得有任何括注
（其它技能会匹配该精确字符串，括注会破坏匹配）。
若 [B]：显示完整的拟议 systems-index 小节，然后用 `AskUserQuestion` 再次询问。

---
