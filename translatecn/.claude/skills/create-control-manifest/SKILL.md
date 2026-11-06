---
name: create-control-manifest
description: "Builds a short list of must-do and never-do coding rules per system from accepted ADRs. Use when the user wants programmer rules or a cheat sheet from the ADRs, or needs it regenerated after ADR changes."
argument-hint: "[update — regenerate from current ADRs] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/create-control-manifest/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/adr-status.sh*), Bash(bash .claude/scripts/md-section.sh *)
model: sonnet
---
---
name: create-control-manifest
description: "依据已接受的 ADR 为每个系统构建一份简短的必做与绝不做编码规则清单。当用户需要程序员规则或 ADR 速查表，或在 ADR 变更后需要重新生成时使用。"
argument-hint: "[update — regenerate from current ADRs] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/create-control-manifest/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/adr-status.sh*), Bash(bash .claude/scripts/md-section.sh *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,review_gate,automation`

Resolved above — use as-is; `--review` overrides `review_mode` for this run. No
block → defaults in `.claude/docs/config-resolution.md`.

以上已解析 — 直接使用；本次运行 `--review` 覆盖 `review_mode`。无
配置块 → 使用 `.claude/docs/config-resolution.md` 中的默认值。

Ask with the question tool. Without one, list the options numbered and end your turn
to wait. A skipped or dismissed question is not an answer: ask again in plain text.

用询问工具提问。若无该工具，将选项编号列出并结束回合等待。被跳过或关闭的问题不算回答：
请用纯文本再次询问。

# Create Control Manifest

# 创建控制清单

The control manifest is a flat rules sheet for programmers: what to do and what
never to do, by architectural layer, taken from the Accepted ADRs, the project's
technical preferences and the engine reference docs. The ADRs say *why*; the
manifest says *what*.

控制清单是一份面向程序员的平铺规则表：按架构分层，说明该做什么、绝不该做什么，内容取自已接受的
ADR、项目的技术偏好与引擎参考文档。ADR 说明*为什么*；清单说明*做什么*。

**Writes:** `docs/architecture/control-manifest.md`, after the user's yes.
**When:** after `/architecture-review` passes and the ADRs are Accepted. Run it
again whenever an ADR is accepted or revised.

**写入：** 在用户同意后写入 `docs/architecture/control-manifest.md`。
**时机：** 在 `/architecture-review` 通过且 ADR 已被接受之后。每当有 ADR 被接受或修订时再次运行。

Asks follow `.claude/docs/automation-modes.md` (collaborative always asks, guided
asks on major choices, autonomous logs and goes on; `automation_always_ask`
categories always ask).

询问遵循 `.claude/docs/automation-modes.md`（协作模式始终询问，引导模式就重大选择询问，
自主模式记录并继续；`automation_always_ask` 类别始终询问）。

## Phase 1: Load the inputs

## 阶段 1：加载输入

### ADRs

### ADR

`bash .claude/scripts/adr-status.sh` reads every `docs/architecture/adr-*.md` in one
pass: the counts first (`adrs`, then `accepted`, `proposed`, `deprecated`,
`superseded`, `unfilled`, `other`, `no_status`), then one row per ADR with its
status and layer. Establish the denominator first: decide from the counts, before
reading any ADR:

`bash .claude/scripts/adr-status.sh` 一次性读取所有 `docs/architecture/adr-*.md`：
先给出计数（`adrs`，然后是 `accepted`、`proposed`、`deprecated`、
`superseded`、`unfilled`、`other`、`no_status`），再为每个 ADR 给出一行，含其
状态与分层。先确立分母：在读取任何 ADR 之前，根据计数决定：

| Counts | Meaning | Action |
|---|---|---|
| `adrs 0` | No ADRs. | "No ADRs found — run `/architecture-decision` before building a control manifest." Stop. |
| `accepted` ≥ 1 | Normal. | The Accepted rows are the set **A**. Name every other ADR, with its status, in the Phase 4 preview: the user approves a manifest knowing what it leaves out. |
| `accepted 0`, some with a status | No Accepted ADRs. | "[N] ADRs found, none Accepted. A manifest built from Proposed ADRs would encode decisions that may still change." Ask whether to go on with the Proposed ones or stop. **Never write an empty manifest silently.** |
| every ADR `no_status` | **Malformed ADRs, not an empty Accepted set.** | "[N] ADRs found, none has a `## Status` section, so acceptance cannot be told. Run `/architecture-decision retrofit [file]` on each." Stop. Never treat them as Accepted. |

| 计数 | 含义 | 动作 |
|---|---|---|
| `adrs 0` | 无 ADR。 | “未找到 ADR — 在构建控制清单之前请运行 `/architecture-decision`。”停止。 |
| `accepted` ≥ 1 | 正常。 | Accepted 行为集合 **A**。在阶段 4 预览中点名其他每一个 ADR 及其状态：让用户在知悉被排除内容的情况下批准清单。 |
| `accepted 0`，部分有状态 | 无已接受 ADR。 | “找到 [N] 个 ADR，无一已接受。基于 Proposed ADR 构建的清单会固化可能仍会变化的决策。”询问是继续使用 Proposed 的 ADR，还是停止。**绝不悄悄写入空清单。** |
| 每个 ADR 都 `no_status` | **ADR 格式错误，而非 Accepted 集为空。** | “找到 [N] 个 ADR，均无 `## Status` 小节，因此无法判断是否已接受。请对每一个运行 `/architecture-decision retrofit [file]`。”停止。绝不可将它们视为 Accepted。 |

Each stop above ends with `Verdict: BLOCKED — [the reason]`. Note the number and
title of every ADR a rule comes from.

上述每次停止都以 `Verdict: BLOCKED — [the reason]` 结束。记录每条规则来源 ADR 的编号与标题。

### Project config

### 项目配置

- `naming.*` and `performance.*` from `project.yaml`; for any key absent or empty,
  `.claude/docs/technical-preferences.md`.
- Approved libraries and forbidden patterns from
  `.claude/docs/technical-preferences.md` (not migrated to `project.yaml`).

- 来自 `project.yaml` 的 `naming.*` 与 `performance.*`；任何缺失或为空的键，改取
  `.claude/docs/technical-preferences.md`。
- 已批准库与禁用模式来自
  `.claude/docs/technical-preferences.md`（尚未迁移到 `project.yaml`）。

### Engine reference

### 引擎参考

- `docs/engine-reference/[engine]/VERSION.md` for the engine and version.
- `docs/engine-reference/[engine]/deprecated-apis.md`: these become forbidden APIs.
- `docs/engine-reference/[engine]/current-best-practices.md`, when it exists.

- `docs/engine-reference/[engine]/VERSION.md` 提供引擎与版本。
- `docs/engine-reference/[engine]/deprecated-apis.md`：这些成为禁用 API。
- `docs/engine-reference/[engine]/current-best-practices.md`，若存在。

### What exists already

### 已有内容

`docs/architecture/control-manifest.md` present: this run regenerates it; read it
before the Phase 5 write, which replaces it. `production/epics/*/EPIC.md` present:
epics exist. Phase 6 picks its next step from both.

若存在 `docs/architecture/control-manifest.md`：本次运行将重新生成它；在阶段 5 写入（会将其替换）
之前先读取它。若存在 `production/epics/*/EPIC.md`：已有史诗。阶段 6 依据二者选择后续步骤。

Report: "Loaded [A] Accepted ADRs of [N], engine: [name + version]."

报告：“已加载 [N] 个 ADR 中的 [A] 个 Accepted，引擎：[名称 + 版本]。”

## Phase 2: Extract the rules from each ADR

## 阶段 2：从每个 ADR 提取规则

For each ADR in **A**, read only four sections, never the whole file:

对 **A** 中的每个 ADR，只读取四个小节，绝不读取整个文件：

```
bash .claude/scripts/md-section.sh extract docs/architecture/[adr-file].md "Decision"
```

and the same for `Alternatives Considered`, `Performance Implications` and `Engine
Compatibility`. Context, Consequences, Migration Plan and Validation Criteria say why
a decision was made; the manifest records what to do. A section an ADR lacks: note
it for that ADR and go on. A section missing from **every** ADR in A: report "No
Accepted ADR has a `[section]` section — the manifest's [category] rules will be
empty. Verify this is intended." Read beyond the four only when a section points
outside itself ("subject to the constraints in Context"), and then that one section.

对 `Alternatives Considered`、`Performance Implications` 与 `Engine
Compatibility` 同理。Context、Consequences、Migration Plan 与 Validation Criteria 说明为何
做出某决策；清单记录该做什么。某 ADR 缺少某小节：为该 ADR 记录并继续。某个小节在 A 中**每一个**
ADR 都缺失：报告“没有 Accepted ADR 具有 `[section]` 小节 — 清单的 [category] 规则将为空。
请确认这是有意为之。”仅当某小节指向自身之外（“受 Context 中的约束限制”）时才读这四个之外的内容，
且只读那一小节。

From each ADR:

从每个 ADR 提取：

- **Required patterns** (Decision): every "must", "should", "required to",
  "always", and every pattern or approach it mandates, including any `### Implementation
  Guidelines` inside it. Never look for that sub-heading alone: many ADRs state
  their mandates directly under Decision, and a scan for the sub-heading alone
  yields an empty section.
- **Forbidden approaches** (Alternatives Considered): every rejected alternative,
  with why it was rejected as the rule ("never use X because Y"), and any named
  anti-pattern.
- **Performance guardrails** (Performance Implications): budgets ("max N ms per
  frame for this system") and memory limits.
- **Engine API constraints** (Engine Compatibility): post-cutoff APIs that need
  verifying, behaviour that differs from what a model would assume, fields or
  methods that changed in the pinned version.

- **必需模式**（Decision）：每一个 “must”、“should”、“required to”、“always”，以及其强制的每个模式
  或方法，包括其中任何 `### Implementation Guidelines`。绝不可只查找该子标题：许多 ADR 直接在
  Decision 下陈述其强制要求，仅扫描子标题会得到空小节。
- **禁用方法**（Alternatives Considered）：每一个被否决的备选方案，连同否决理由作为规则
  （“绝不使用 X，因为 Y”），以及任何被点名的反模式。
- **性能护栏**（Performance Implications）：预算（“该系统每帧最多 N ms”）与内存限制。
- **引擎 API 约束**（Engine Compatibility）：需要验证的 cutoff 后 API、与模型会假设的行为不同的行为、
  在固定版本中发生变化的字段或方法。

**Layer.** Each rule goes under the layer of the system it governs, the ADR's
`layer` column where it has one:

**分层。** 每条规则归入其所治理系统所属的分层，ADR 有 `layer` 列时以该列为准：

- **Foundation:** scene management, event architecture, save/load, engine start-up
- **Core:** core gameplay loop, main player systems, physics and collision
- **Feature:** secondary systems and mechanics, AI
- **Presentation:** rendering, audio, UI, VFX, shaders

- **Foundation（基础层）：** 场景管理、事件架构、存档/读档、引擎启动
- **Core（核心层）：** 核心玩法循环、主要玩家系统、物理与碰撞
- **Feature（功能层）：** 次级系统与机制、AI
- **Presentation（表现层）：** 渲染、音频、UI、VFX、着色器

An ADR that spans layers puts its rule in each one.

跨层的 ADR 将其规则归入每一个相关分层。

## Phase 3: Add the global rules

## 阶段 3：添加全局规则

Rules for every layer, each with its source (the `project.yaml` key,
`technical-preferences.md`, or the engine-reference file), as a layer rule has:

适用于所有分层的规则，每条都标注来源（`project.yaml` 键、`technical-preferences.md`，
或引擎参考文件），与分层规则一样：

- **Naming** from `naming.*`: classes, variables, signals and events, files,
  constants.
- **Performance budgets** from `performance.*`: target frame rate, frame budget,
  draw calls, memory ceiling.
- **Forbidden APIs** from `deprecated-apis.md`, **only those that apply to what this
  project builds.** Never copy the table whole: its `GodotPhysics3D → Jolt Physics
  3D` row is 3D-only, and a 2D project does not use that engine. When you cannot
  tell whether an entry applies (2D or 3D, a module the project may not include),
  scope the rule ("when using 3D physics: …") or leave it out and list it as
  unresolved. `/create-stories` reads this file, and rules that do not apply are
  rules nobody reads.
- **Required patterns** from `current-best-practices.md`, when it exists.
- **Forbidden patterns** from `technical-preferences.md`, copied as written.

- **命名**来自 `naming.*`：类、变量、信号与事件、文件、常量。
- **性能预算**来自 `performance.*`：目标帧率、帧预算、绘制调用、内存上限。
- **禁用 API**来自 `deprecated-apis.md`，**仅限适用于本项目所构建内容的那些。** 绝不可整表复制：
  其中 `GodotPhysics3D → Jolt Physics 3D` 一行仅适用于 3D，而 2D 项目不使用该引擎。当你无法
  判断某条目是否适用（2D 或 3D、项目可能未包含的模块）时，给规则加上限定（“使用 3D 物理时：……”），
  或将其排除并列为未解决。`/create-stories` 会读取此文件，而不适用的规则就是没人会读的规则。
- **必需模式**来自 `current-best-practices.md`，若存在。
- **禁用模式**来自 `technical-preferences.md`，照原文复制。

## Phase 4: Show the summary, then the review

## 阶段 4：展示摘要，然后评审

```
## Control Manifest Preview
Engine: [name + version]
ADRs covered: [ADR numbers]
ADRs left out: [ADR-NNNN ([status]), … — every ADR not in A, or "None"]
Rules extracted:
  - Foundation layer: [N] required, [M] forbidden, [P] guardrails
  - Core layer: [N] required, [M] forbidden, [P] guardrails
  - Feature layer: …
  - Presentation layer: …
  - Global: [N] naming conventions, [M] forbidden APIs, [P] approved libraries
Unresolved: [engine entries left out because whether they apply is unclear, or "None"]
```

Ask: "Does this rule summary look complete?" Options: Yes — review and write it /
Add rules — I have more to include / Remove rules — some should be dropped / Stop —
I need to review the ADRs first.

询问：“这份规则摘要看起来完整吗？”选项：Yes — 评审并写入 / Add rules — 我还有要加入的 /
Remove rules — 有些应当删掉 / Stop — 我需要先审阅这些 ADR。

**The technical review.** Read the `review_gate` line above. `skill-gates=skip`
(solo or lean): no agent; note `TD-MANIFEST skipped — [Solo | Lean] mode`.
`skill-gates=run`: hand the review to the `technical-director` agent with gate
**TD-MANIFEST** (`.claude/docs/director-gates/td-manifest.md`; the agent reads it
itself). Brief:

**技术评审。** 读取上方的 `review_gate` 行。`skill-gates=skip`（solo 或 lean）：不启用智能体；
注明 `TD-MANIFEST skipped — [Solo | Lean] mode`。`skill-gates=run`：将评审交给
`technical-director` 智能体，门禁为 **TD-MANIFEST**（`.claude/docs/director-gates/td-manifest.md`；
该智能体会自行读取）。简报：

- **Objective:** check the extracted rules before they are written.
- **Give it:** the preview above with the full rule list, the ADRs covered, the
  engine version, and the rules taken from technical preferences or the engine
  reference.
- **Check:** every mandatory ADR pattern is captured and stated accurately; the
  forbidden approaches are complete and correctly attributed; no rule lacks a source
  ADR or preference document; the guardrails agree with the ADRs' constraints.
- **Return:** APPROVE, CONCERNS, REJECT, or NOT ASSESSED naming a missing input.
- **Boundaries:** it writes no file.

- **目标：** 在写入之前检查已提取的规则。
- **提供：** 上面的预览，含完整规则列表、所涵盖的 ADR、引擎版本，以及取自技术偏好或引擎
  参考的规则。
- **检查：** 每条强制 ADR 模式都被捕获并准确陈述；禁用方法完整且归属正确；没有规则缺少来源
  ADR 或偏好文档；护栏与 ADR 的约束一致。
- **返回：** APPROVE、CONCERNS、REJECT，或点明缺失输入的 NOT ASSESSED。
- **边界：** 不写入任何文件。

Act on the verdict:

根据判定行动：

- **APPROVE:** go to Phase 5.
- **CONCERNS:** ask: "The technical director raised concerns. How do you want to go
  on?" Options: Revise the flagged rules / Accept and go on / Discuss further.
- **REJECT:** write nothing; fix the flagged rules and show the summary again.
- **NOT ASSESSED:** it is not an approval (`.claude/docs/director-gates.md`). Name
  what was missing, then supply it and run the review again; or, when the user
  chooses to go on without it, go to Phase 5 and state `TD-MANIFEST: NOT ASSESSED —
  [input]` in the reply and the final verdict line.

- **APPROVE：** 进入阶段 5。
- **CONCERNS：** 询问：“技术总监提出了疑虑。你希望如何继续？”选项：Revise the flagged rules /
  Accept and go on / Discuss further。
- **REJECT：** 不写入任何内容；修复被标记的规则并再次展示摘要。
- **NOT ASSESSED：** 这不是批准（`.claude/docs/director-gates.md`）。点明缺失内容，然后补齐并
  重新运行评审；或者，当用户选择不带它继续时，进入阶段 5，并在答复与最终判定行中声明
  `TD-MANIFEST: NOT ASSESSED — [input]`。

## Phase 5: Write the control manifest

## 阶段 5：写入控制清单

Ask: "May I write the control manifest to `docs/architecture/control-manifest.md`?"
Options: Yes, write it / Show me the full draft first, then ask again / Not yet — I
want more changes. Write only on an explicit yes.

询问：“我可以将控制清单写入 `docs/architecture/control-manifest.md` 吗？”
选项：Yes, write it / Show me the full draft first, then ask again / Not yet — I
want more changes。仅在明确同意时写入。

```markdown
# Control Manifest

> **Engine**: [name + version]
> **Last Updated**: [date]
> **Manifest Version**: [date]
> **ADRs Covered**: [ADR-NNNN, ADR-MMMM, ...]
> **Status**: Active — regenerate with `/create-control-manifest update` when ADRs change

`Manifest Version` is the date this manifest was generated. Stories embed it when
they are written, and `/story-readiness` compares a story's version with this one
to find stories written against old rules. It always equals `Last Updated`: the
same date, for different readers.

This manifest is a programmer's quick reference taken from the Accepted ADRs, the
technical preferences and the engine reference docs. For the reason behind a rule,
read its ADR.

---

## Foundation Layer Rules

*Applies to: scene management, event architecture, save/load, engine start-up*

### Required Patterns
- **[rule]** — source: [ADR-NNNN]

### Forbidden Approaches
- **Never [anti-pattern]** — [brief reason] — source: [ADR-NNNN]

### Performance Guardrails
- **[system]**: max [N]ms/frame — source: [ADR-NNNN]

---

## Core Layer Rules

*Applies to: core gameplay loop, main player systems, physics, collision*

### Required Patterns
...

### Forbidden Approaches
...

### Performance Guardrails
...

---

## Feature Layer Rules

*Applies to: secondary mechanics, AI systems, secondary features*

### Required Patterns
...

### Forbidden Approaches
...

---

## Presentation Layer Rules

*Applies to: rendering, audio, UI, VFX, shaders, animations*

### Required Patterns
...

### Forbidden Approaches
...

---

## Global Rules (All Layers)

### Naming Conventions
| Element | Convention | Example | Source |
|---------|-----------|---------|--------|
| Classes | [convention] | [example] | [`naming.classes` in project.yaml, or technical-preferences.md] |
| Variables | [convention] | [example] | [`naming.variables` in project.yaml, or technical-preferences.md] |
| Signals/Events | [convention] | [example] | [`naming.signals` in project.yaml, or technical-preferences.md] |
| Files | [convention] | [example] | [`naming.files` in project.yaml, or technical-preferences.md] |
| Constants | [convention] | [example] | [`naming.constants` in project.yaml, or technical-preferences.md] |

### Performance Budgets
| Target | Value | Source |
|--------|-------|--------|
| Framerate | [value] | [`performance.target_framerate` in project.yaml, or technical-preferences.md] |
| Frame budget | [value] | [`performance.frame_budget_ms` in project.yaml, or technical-preferences.md] |
| Draw calls | [value] | [`performance.draw_call_limit` in project.yaml, or technical-preferences.md] |
| Memory ceiling | [value] | [`performance.memory_ceiling_mb` in project.yaml, or technical-preferences.md] |

### Approved Libraries / Addons
- [library] — approved for [purpose] — source: technical-preferences.md

### Forbidden APIs ([engine version])
These APIs are deprecated or unverified for [engine + version]:
- `[api name]` — deprecated since [version] / unverified post-cutoff
- Source: `docs/engine-reference/[engine]/deprecated-apis.md`

### Cross-Cutting Constraints
- [constraint that applies in every layer] — source: [ADR-NNNN, preference key or engine-reference file]
```

## Phase 6: Next steps

## 阶段 6：后续步骤

- No epics yet: "Run `/create-epics layer: foundation`, then `/create-stories
  [epic-slug]`: stories embed this manifest's rules and version."
- A regeneration: "Updated. Tell the team about the changed rules, above all any
  new Forbidden entries."

- 尚无史诗：“运行 `/create-epics layer: foundation`，然后 `/create-stories
  [epic-slug]`：故事会嵌入本清单的规则与版本。”
- 一次重新生成：“已更新。请告知团队变更的规则，尤其是任何新的 Forbidden 条目。”

Every rule traces to an ADR, a technical preference or an engine reference doc;
none is invented, and none is paraphrased in a way that changes its meaning. End
with `Verdict: COMPLETE — control manifest written` after the write, or `Verdict:
BLOCKED — user declined the write` when declined.

每条规则都可追溯到 ADR、技术偏好或引擎参考文档；没有一条是凭空编造的，也没有一条被改写而改变原意。
写入后以 `Verdict: COMPLETE — control manifest written` 结束，或在被拒绝时以
`Verdict: BLOCKED — user declined the write` 结束。
