# /architecture-decision — Step 5: Generate the ADR

# /architecture-decision —— 步骤 5：生成 ADR

> Part of `/architecture-decision`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> `/architecture-decision` 的一部分。`SKILL.md` 说明了何时读取本文件；它解析出的设置以及它后续标题下的规则在这里同样适用。

## 5. Generate the ADR

## 5. 生成 ADR

**In this file:**

**本文件内容：**

- The ADR template
- 5.5 Engine Specialist Validation
- 5.6 Technical Director Strategic Review, with the review mode check
- 5.7 GDD Sync Check: found, none found, could not check
- Write approval
- Update Architecture Registry, and the registry append logic

- ADR 模板
- 5.5 引擎专家验证
- 5.6 技术总监战略评审，含评审模式检查
- 5.7 GDD 同步检查：发现、未发现、无法检查
- 写入批准
- 更新架构注册表，以及注册表追加逻辑

Following this format:

遵循此格式：

```markdown
# ADR-[NNNN]: [Title]

## Status
[Proposed | Accepted | Deprecated | Superseded by ADR-XXXX]

## Date
[Date of decision]

## Last Verified
[YYYY-MM-DD — when this ADR was last confirmed accurate against the current
engine version and design. Update this date when you re-read and confirm it is
still correct, even if nothing changed.]

## Decision Makers
[Who was involved in this decision]

## Summary
[2 sentences: what problem this ADR solves, and what was decided. Written for
tiered context loading — a skill scanning 20 ADRs uses this to decide whether to
read the full decision. Be specific: name the system, the problem, and the
chosen approach.]

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | [e.g. Godot 4.7] |
| **Domain** | [Physics / Rendering / UI / Audio / Navigation / Animation / Networking / Core / Input] |
| **Layer** | [Foundation / Core / Feature / Presentation] |
| **Knowledge Risk** | [LOW / MEDIUM / HIGH — from VERSION.md] |
| **References Consulted** | [List engine-reference docs read, e.g. `docs/engine-reference/godot/modules/physics.md`] |
| **Post-Cutoff APIs Used** | [Any APIs from post-LLM-cutoff versions this decision depends on, or "None"] |
| **Verification Required** | [Specific behaviours to test before shipping, or "None"] |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | [ADR-NNNN (must be Accepted before this can be implemented), or "None"] |
| **Enables** | [ADR-NNNN (this ADR unlocks that decision), or "None"] |
| **Blocks** | [Epic/Story name — cannot start until this ADR is Accepted, or "None"] |
| **Ordering Note** | [Any sequencing constraint that isn't captured above] |

## Context

### Problem Statement
[What problem are we solving? Why does this decision need to be made now?]

### Constraints
- [Technical constraints]
- [Timeline constraints]
- [Resource constraints]
- [Compatibility requirements]

### Requirements
- [Must support X]
- [Must perform within Y budget]
- [Must integrate with Z]

## Decision

[The specific technical decision made, described in enough detail for someone
to implement it.]

### Architecture Diagram
[ASCII diagram or description of the system architecture this creates]

### Key Interfaces
[API contracts or interface definitions this decision creates]

### Implementation Guidelines
[Specific guidance for the programmer implementing this decision — the rules a
`/create-control-manifest` or `/dev-story` run should follow. State mandates as
"must / must never" so they extract cleanly.]

## Alternatives Considered

### Alternative 1: [Name]
- **Description**: [How this would work]
- **Pros**: [Advantages]
- **Cons**: [Disadvantages]
- **Rejection Reason**: [Why this was not chosen]

### Alternative 2: [Name]
- **Description**: [How this would work]
- **Pros**: [Advantages]
- **Cons**: [Disadvantages]
- **Rejection Reason**: [Why this was not chosen]

## Consequences

### Positive
- [Good outcomes of this decision]

### Negative
- [Trade-offs and costs accepted]

## Risks
- [Things that could go wrong]
- [Mitigation for each risk]

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [system-name].md | [specific rule, formula, or performance constraint from that GDD] | [how this decision satisfies it] |

## Performance Implications
- **CPU**: [Expected impact]
- **Memory**: [Expected impact]
- **Load Time**: [Expected impact]
- **Network**: [Expected impact, if applicable]

## Migration Plan
[If this changes existing code, how do we get from here to there?]

## Validation Criteria
[How will we know this decision was correct? What metrics or tests?]

## Related
- [Links to related ADRs — note if supersedes, contradicts, or depends on]
- [Links to related design documents]
```

**Always write the Layer row.** An ADR with no Layer row counts as critical
(Foundation) wherever it is read, so at `standard` its advisory items become
blockers. The value is the ADR's own layer, how early in the build it must
exist: the layer `docs/architecture/architecture.md`'s layer map gives the
system this decision governs. With no layer map, or no system in it, ask the
user, with the four values as options. Never take it from an epic that
references the ADR, and never reuse a `Domain` value (the template's note under
Engine Compatibility says why).

**始终写入 Layer 行。** 没有 Layer 行的 ADR 在被读取的任何地方都被计为关键（Foundation），因此在 `standard` 下其建议项会变为阻断项。该值是该 ADR 自身的层级，即它必须在构建中多早存在：由 `docs/architecture/architecture.md` 的层级地图为该决策所治理的系统给出的层级。如果没有层级地图，或其中没有该系统，则询问用户，并以四个值作为选项。绝不要从引用该 ADR 的史诗中获取它，也绝不要复用 `Domain` 的值（模板在 Engine Compatibility 下的注释说明了原因）。

5.5. **Engine Specialist Validation** — Before saving, spawn the **primary engine specialist** via `Agent` to validate the drafted ADR:
   - Resolve the primary specialist: `<engine>-specialist` derived from `engine.name` in `project.yaml` (Godot→`godot-specialist`, Unity→`unity-specialist`, Unreal→`unreal-specialist`); if `engine.name` is absent or empty, read the Primary line of the `## Engine Specialists` section in `.claude/docs/technical-preferences.md`
   - If no engine is configured (neither source yields an engine), skip this step **Record ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)`` in this run's output.** A skipped check that says nothing is indistinguishable from a check that passed; the reader cannot tell engine guidance was never sought.
   - Spawn `subagent_type: [primary specialist]` with: the ADR's Engine Compatibility section, Decision section, Key Interfaces, and the engine reference docs path. Ask them to:
     1. Confirm the proposed approach is idiomatic for the pinned engine version
     2. Flag any APIs or patterns that are deprecated or changed post-training-cutoff
     3. Identify engine-specific risks or gotchas not captured in the current ADR draft
   - If the specialist identifies a **blocking issue** (wrong API, deprecated approach, engine version incompatibility): revise the Decision and Engine Compatibility sections accordingly, then confirm the changes with the user before proceeding
   - If the specialist finds **minor notes** only: incorporate them into the ADR's Risks subsection

5.5. **引擎专家验证** —— 在保存之前，通过 `Agent` 启动**主引擎专家**来验证已起草的 ADR：
   - 解析主专家：由 `project.yaml` 中的 `engine.name` 推导 `<engine>-specialist`（Godot→`godot-specialist`，Unity→`unity-specialist`，Unreal→`unreal-specialist`）；如果 `engine.name` 缺失或为空，读取 `.claude/docs/technical-preferences.md` 中 `## Engine Specialists` 章节的 Primary 行
   - 如果没有配置任何引擎（两个来源都无法给出引擎），跳过此步骤。**在本次运行的输出中记录 ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)``。** 一个什么都不说的跳过检查，与一个通过的检查无法区分；读者无法得知从未寻求过引擎指导。
   - 启动 `subagent_type: [primary specialist]`，传入：该 ADR 的 Engine Compatibility 章节、Decision 章节、Key Interfaces，以及引擎参考文档路径。要求它：
     1. 确认所提议的方法对于固定的引擎版本是符合惯例的
     2. 标记任何已弃用或在训练截止点之后发生变更的 API 或模式
     3. 识别当前 ADR 草案未捕捉到的引擎特有风险或陷阱
   - 如果专家识别出**阻断性问题**（错误的 API、已弃用的方法、引擎版本不兼容）：相应修订 Decision 和 Engine Compatibility 章节，然后在继续之前与用户确认更改
   - 如果专家只发现**次要说明**：将它们纳入该 ADR 的 Risks 子章节

**Review mode check** — apply before spawning TD-ADR:
- `solo` → skip. Note: "TD-ADR skipped — Solo mode." Proceed to Step 5.7 (GDD sync check).
- `lean` → skip (not a PHASE-GATE). Note: "TD-ADR skipped — Lean mode." Proceed to Step 5.7 (GDD sync check).
- `full` → spawn as normal.

**评审模式检查** —— 在启动 TD-ADR 之前应用：
- `solo` → 跳过。注明："TD-ADR skipped — Solo mode." 继续步骤 5.7（GDD 同步检查）。
- `lean` → 跳过（不是阶段门禁）。注明："TD-ADR skipped — Lean mode." 继续步骤 5.7（GDD 同步检查）。
- `full` → 照常启动。

5.6. **Technical Director Strategic Review** — After the engine specialist validation, spawn `technical-director` via `Agent` using gate **TD-ADR** (`.claude/docs/director-gates/td-adr.md`):
   - Pass: the ADR file path (or draft content), engine version, domain, any existing ADRs in the same domain
   - The TD validates architectural coherence (is this decision consistent with the whole system?) — distinct from the engine specialist's API-level check
   - On CONCERNS: show them to the user verbatim and ask with the standard options from `director-gates.md` — `Revise flagged items` / `Accept and proceed` / `Discuss further`. Revise the flagged Decision or Alternatives sections only on `Revise flagged items`.
   - On REJECT: show the blockers verbatim and revise the Decision or Alternatives sections before proceeding.
   - A revised draft still reaches the user through the write approval below; nothing is written before it. A `NOT ASSESSED` answer is not an approval — name the missing input (`director-gates.md`).

5.6. **技术总监战略评审** —— 在引擎专家验证之后，通过 `Agent` 启动 `technical-director`，使用门禁 **TD-ADR**（`.claude/docs/director-gates/td-adr.md`）：
   - 传入：ADR 文件路径（或草案内容）、引擎版本、领域、同领域中任何现有 ADR
   - TD 验证架构一致性（该决策是否与整个系统一致？）—— 与引擎专家的 API 级检查不同
   - 若为 CONCERNS：原样展示给用户，并用 `director-gates.md` 中的标准选项询问 —— `Revise flagged items` / `Accept and proceed` / `Discuss further`。仅在 `Revise flagged items` 时修订被标记的 Decision 或 Alternatives 章节。
   - 若为 REJECT：原样展示阻断项，并在继续之前修订 Decision 或 Alternatives 章节。
   - 修订后的草案仍要通过下面的写入批准才能到达用户；在此之前什么都不写入。`NOT ASSESSED` 的回答不是批准 —— 指出缺失的输入（`director-gates.md`）。

5.7. **GDD Sync Check** — Before presenting the write approval, scan all GDDs
referenced in the "GDD Requirements Addressed" section for naming inconsistencies
with the ADR's Key Interfaces and Decision sections (renamed signals, API methods,
or data types). If any are found, surface them as a **prominent warning block**
immediately before the write approval — not as a footnote:

5.7. **GDD 同步检查** —— 在呈现写入批准之前，扫描 "GDD Requirements Addressed" 章节中引用的所有 GDD，查找与该 ADR 的 Key Interfaces 和 Decision 章节的命名不一致之处（被重命名的信号、API 方法或数据类型）。如果发现任何不一致，在写入批准之前立即将其作为**醒目的警告块**呈现 —— 而不是脚注：

```
⚠️ GDD SYNC REQUIRED
[gdd-filename].md uses names this ADR has renamed:
  [old_name] → [new_name_from_adr]
  [old_name_2] → [new_name_2_from_adr]
The GDD must be updated before or alongside writing this ADR to prevent
developers reading the GDD from implementing the wrong interface.
```

**This check has three outcomes, not two.** The two above are "found" and "none
found"; the third is **could not check**, which must never take the silent
branch and render like a clean result.

**该检查有三种结果，而不是两种。** 上面两种是"发现"和"未发现"；第三种是**无法检查**，它绝不能走静默分支并呈现为干净的结果。

- **None found** — print one line, do not stay silent:
  `GDD sync: checked [N] referenced GDD(s), no naming inconsistencies.`
  A silent pass is indistinguishable from a check that never ran, and this one
  guards against developers implementing the wrong interface from a stale GDD.
- **Could not check** — the ADR has no `GDD Requirements Addressed` section, it
  names no GDDs, or a named GDD does not exist on disk. Print:
  `GDD sync: NOT ASSESSED — [which reason, and which files]`
  Do **not** treat an ADR that references no GDDs as one whose GDDs are
  consistent. Nothing was compared.

- **未发现** —— 打印一行，不要保持沉默：`GDD sync: checked [N] referenced GDD(s), no naming inconsistencies.` 一个静默通过，与从未运行的检查无法区分，而这一项正是防止开发者照着过时的 GDD 实现错误接口。
- **无法检查** —— 该 ADR 没有 `GDD Requirements Addressed` 章节、没有指定任何 GDD，或指定的 GDD 在磁盘上不存在。打印：`GDD sync: NOT ASSESSED — [which reason, and which files]`。**不要**把未引用任何 GDD 的 ADR 当作其 GDD 一致的 ADR。什么都没有比较。

Only the warning block itself is conditional; the check always reports.

只有警告块本身是有条件的；该检查始终会报告。

5. **Write approval** — Use `AskUserQuestion`:

5. **写入批准** —— 使用 `AskUserQuestion`：

If GDD sync issues were found:
- "ADR draft is complete. How would you like to proceed?"
  - [A] Write ADR + update GDD in the same pass
  - [B] Write ADR only — I'll update the GDD manually
  - [C] Not yet — I need to review further

如果发现了 GDD 同步问题：
- "ADR 草案已完成。你想如何继续？"
  - [A] 写入 ADR + 同时更新 GDD
  - [B] 只写入 ADR —— 我会手动更新 GDD
  - [C] 还不是 —— 我需要进一步审查

If no GDD sync issues:
- "ADR draft is complete. May I write it?"
  - [A] Write ADR to `docs/architecture/adr-[NNNN]-[slug].md`
  - [B] Not yet — I need to review further

如果没有 GDD 同步问题：
- "ADR 草案已完成。我可以写入它吗？"
  - [A] 将 ADR 写入 `docs/architecture/adr-[NNNN]-[slug].md`
  - [B] 还不是 —— 我需要进一步审查

If yes to any write option, write the file, creating the directory if needed.
For option [A] with GDD update: also update the GDD file(s) to use the new names.

如果对任何写入选项回答是，则写入文件，必要时创建目录。对于带 GDD 更新的选项 [A]：同时更新 GDD 文件以使用新名称。

6. **Update Architecture Registry**

6. **更新架构注册表**

Scan the written ADR for new architectural stances that should be registered:
- State it claims ownership of
- Interface contracts it defines (signal signatures, method APIs)
- Performance budget it claims
- API choices it makes explicitly
- Patterns it bans (Consequences → Negative or explicit "do not use X")

扫描已写入的 ADR，查找应注册的新架构立场：
- 它声明拥有的状态
- 它定义的接口契约（信号签名、方法 API）
- 它主张的性能预算
- 它明确做出的 API 选择
- 它禁止的模式（Consequences → Negative 或明确的 "do not use X"）

Present candidates:
```
Registry candidates from this ADR:
  NEW state ownership:      player_stamina → stamina-system
  NEW interface contract:   stamina_depleted signal
  NEW performance budget:   stamina-system: 0.5ms/frame
  NEW forbidden pattern:    polling stamina each frame (use signal instead)
  EXISTING (referenced_by update only): player_health → already registered ✅
```

呈现候选（格式如上所示）。

**Registry append logic**: When writing to `docs/registry/architecture.yaml`, do NOT assume sections are empty. The file may already have entries from previous ADRs written in this session. Before each Edit call:
1. Read the current state of `docs/registry/architecture.yaml`
2. Find the correct section (state_ownership, interfaces, forbidden_patterns, api_decisions)
3. If the section is still the empty list (`state_ownership: []`), replace `[]` with the first entry: the key alone on its line, the entry below it indented two spaces as in the file's commented example. An entry appended after `[]` makes the file invalid YAML. Otherwise append the new entry AFTER the last existing entry in that section
4. If the section has entries already, use the closing content of the last entry as the `old_string` anchor, and append the new entry after it

**注册表追加逻辑**：写入 `docs/registry/architecture.yaml` 时，不要假设各章节为空。文件中可能已经存在本会话中先前 ADR 写入的条目。在每次 Edit 调用之前：
1. 读取 `docs/registry/architecture.yaml` 的当前状态
2. 找到正确的章节（state_ownership、interfaces、forbidden_patterns、api_decisions）
3. 如果该章节仍是空列表（`state_ownership: []`），用第一个条目替换 `[]`：键独占一行，条目在其下缩进两个空格，如文件中的注释示例所示。在 `[]` 之后追加条目会使文件成为无效的 YAML。否则将新条目追加到该章节最后一个现有条目之后
4. 如果该章节已有条目，使用最后一个条目的结束内容作为 `old_string` 锚点，并在其后追加新条目

**BLOCKING — do not write to `docs/registry/architecture.yaml` without explicit user approval.**

**阻断 —— 未经用户明确批准，不要写入 `docs/registry/architecture.yaml`。**

Ask using `AskUserQuestion`:
- "May I update `docs/registry/architecture.yaml` with these [N] new stances?"
  - Options: "Yes — update the registry", "Not yet — I want to review the candidates", "Skip registry update"

使用 `AskUserQuestion` 询问：
- "我可以把这些 [N] 个新立场更新到 `docs/registry/architecture.yaml` 吗？"
  - 选项："是 —— 更新注册表"、"还不是 —— 我想审查这些候选"、"跳过注册表更新"

Only proceed if the user selects yes. If yes: append new entries. Never modify existing entries — if a stance is
changing, set the old entry to `status: "superseded_by: ADR-[NNNN]"` and add the new entry. Keep the quotes:
unquoted, the second colon makes the file invalid YAML.

只有在用户选择是时才继续。如果是：追加新条目。绝不修改现有条目 —— 如果某个立场正在变化，将旧条目设置为 `status: "superseded_by: ADR-[NNNN]"` 并添加新条目。保留引号：若不加引号，第二个冒号会使文件成为无效的 YAML。

After writing, run `bash .claude/scripts/registry.sh validate` and fix every row about an entry this write added
or changed (a DUPLICATE, STATUS or LAYOUT row, an UNQUOTED row (quote the value it names), or a PATH_MISSING row for a path it named) before you go on; name
rows about other entries to the user rather than fixing them unasked. If the script is missing or prints nothing,
say the registry check did not run, then re-read the entries you wrote against the rules in the file's header.

写入之后，运行 `bash .claude/scripts/registry.sh validate`，并在继续之前修复关于本次写入新增或更改的条目的每一行（DUPLICATE、STATUS 或 LAYOUT 行、UNQUOTED 行（给它指明的值加上引号），或关于它指明的路径的 PATH_MISSING 行）；关于其他条目的行，向用户指出，而不是未经请求就去修复。如果脚本缺失或没有输出，说明注册表检查未运行，然后对照文件头部的规则重新阅读你写入的条目。

---
