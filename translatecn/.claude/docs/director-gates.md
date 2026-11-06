# Director Gates — Shared Review Pattern
# 总监门禁 — 共享评审模式

Index of all director and lead review gates. Skills reference gate IDs from this
index instead of embedding prompts inline — eliminating drift when prompts need
updating. Each gate's full definition (Trigger, Context to pass, Prompt, Verdicts)
lives in its own file under `.claude/docs/director-gates/`, named after the gate
ID in lowercase.
所有总监和主管评审门禁的索引。技能从本索引引用门禁 ID，而不是内嵌提示词 — 当提示词需要更新时消除漂移。每个门禁的完整定义（Trigger、Context to pass、Prompt、Verdicts）都存放在 `.claude/docs/director-gates/` 下以门禁 ID 小写命名的独立文件中。

**Scope**: All 7 production stages (Concept → Release), all 3 Tier 1 directors,
all key Tier 2 leads. Any skill, team orchestrator, or workflow may invoke these gates.
**范围**：所有 7 个生产阶段（概念 → 发布）、所有 3 位层级 1 总监、所有关键层级 2 主管。任何技能、团队编排器或工作流均可调用这些门禁。

**When a skill spawns a director for a gate, it must NOT read the gate definition
file itself. Include the gate definition file path in the `Agent` prompt and instruct
the director agent to read it first, then pass only the context fields that gate's
row requires. Gate definitions are read by the spawned agent, in the agent's own
context window.**
**当技能为某个门禁生成总监时，它绝不能自己读取门禁定义文件。将门禁定义文件路径包含在 `Agent` 提示词中，并指示总监智能体先读取它，然后只传递该门禁行所需的上下文字段。门禁定义由被生成的智能体在其自己的上下文窗口中读取。**

---

## Gate Index
## 门禁索引

Agent by prefix: `CD-` creative-director · `TD-` technical-director ·
`PR-` producer · `AD-` art-director · `LP-` lead-programmer · `QL-` qa-lead ·
`ND-` narrative-director. Definition files below are in
`.claude/docs/director-gates/`; each one's header names its agent's model tier.
按前缀对应智能体：`CD-` creative-director · `TD-` technical-director ·
`PR-` producer · `AD-` art-director · `LP-` lead-programmer · `QL-` qa-lead ·
`ND-` narrative-director。下面的定义文件位于
`.claude/docs/director-gates/`；每个文件的头部都会标明其智能体的模型层级。

| Gate ID | Purpose | Definition file |
| 门禁 ID | 用途 | 定义文件 |
|---------|---------|-----------------|
| CD-PILLARS | Pillar stress test after pillars are defined | cd-pillars.md |
| CD-PILLARS | 支柱定义后的支柱压力测试 | cd-pillars.md |
| CD-GDD-ALIGN | GDD pillar alignment after a system GDD is authored | cd-gdd-align.md |
| CD-GDD-ALIGN | 系统 GDD 编写后的 GDD 支柱对齐 | cd-gdd-align.md |
| CD-SYSTEMS | Systems decomposition vision check after `/map-systems` | cd-systems.md |
| CD-SYSTEMS | `/map-systems` 之后的系统分解愿景检查 | cd-systems.md |
| CD-NARRATIVE | Narrative consistency of story/lore documents | cd-narrative.md |
| CD-NARRATIVE | 故事/设定文档的叙事一致性 | cd-narrative.md |
| CD-PLAYTEST | Player experience validation of playtest reports | cd-playtest.md |
| CD-PLAYTEST | 对试玩报告的玩家体验验证 | cd-playtest.md |
| CD-PHASE-GATE | Creative readiness at phase transition | cd-phase-gate.md |
| CD-PHASE-GATE | 阶段转换时的创意就绪度 | cd-phase-gate.md |
| TD-SYSTEM-BOUNDARY | System boundary review before GDD authoring | td-system-boundary.md |
| TD-SYSTEM-BOUNDARY | GDD 编写前的系统边界评审 | td-system-boundary.md |
| TD-FEASIBILITY | Technical feasibility of early concept risks | td-feasibility.md |
| TD-FEASIBILITY | 早期概念风险的技术可行性 | td-feasibility.md |
| TD-ARCHITECTURE | Master architecture document sign-off | td-architecture.md |
| TD-ARCHITECTURE | 主架构文档签核 | td-architecture.md |
| TD-ADR | Individual ADR review before Accepted | td-adr.md |
| TD-ADR | 单个 ADR 在标记为 Accepted 前的评审 | td-adr.md |
| TD-ENGINE-RISK | Engine version risk for post-cutoff APIs | td-engine-risk.md |
| TD-ENGINE-RISK | 针对训练截止后 API 的引擎版本风险 | td-engine-risk.md |
| TD-PHASE-GATE | Technical readiness at phase transition | td-phase-gate.md |
| TD-PHASE-GATE | 阶段转换时的技术就绪度 | td-phase-gate.md |
| TD-MANIFEST | Control manifest review before it is written | td-manifest.md |
| TD-MANIFEST | 控制清单写入前的评审 | td-manifest.md |
| TD-CHANGE-IMPACT | Design-change impact assessment review | td-change-impact.md |
| TD-CHANGE-IMPACT | 设计变更影响评估评审 | td-change-impact.md |
| PR-SCOPE | Scope and timeline validation | pr-scope.md |
| PR-SCOPE | 范围与时间线验证 | pr-scope.md |
| PR-SPRINT | Sprint plan feasibility review | pr-sprint.md |
| PR-SPRINT | 冲刺计划可行性评审 | pr-sprint.md |
| PR-MILESTONE | Milestone risk assessment | pr-milestone.md |
| PR-MILESTONE | 里程碑风险评估 | pr-milestone.md |
| PR-EPIC | Epic structure feasibility before story breakdown | pr-epic.md |
| PR-EPIC | 故事拆分前的史诗结构可行性 | pr-epic.md |
| PR-PHASE-GATE | Production readiness at phase transition | pr-phase-gate.md |
| PR-PHASE-GATE | 阶段转换时的生产就绪度 | pr-phase-gate.md |
| AD-CONCEPT-VISUAL | Visual identity anchor after pillars lock | ad-concept-visual.md |
| AD-CONCEPT-VISUAL | 支柱锁定后的视觉身份锚点 | ad-concept-visual.md |
| AD-ART-BIBLE | Art bible sign-off before asset production | ad-art-bible.md |
| AD-ART-BIBLE | 资源生产前的美术圣经签核 | ad-art-bible.md |
| AD-PHASE-GATE | Visual readiness at phase transition | ad-phase-gate.md |
| AD-PHASE-GATE | 阶段转换时的视觉就绪度 | ad-phase-gate.md |
| LP-FEASIBILITY | Implementation feasibility of the architecture | lp-feasibility.md |
| LP-FEASIBILITY | 架构的实现可行性 | lp-feasibility.md |
| LP-CODE-REVIEW | Code review of an implemented story | lp-code-review.md |
| LP-CODE-REVIEW | 对已实现故事的代码评审 | lp-code-review.md |
| QL-STORY-READY | Acceptance-criteria testability before sprint | ql-story-ready.md |
| QL-STORY-READY | 冲刺前验收标准的可测试性 | ql-story-ready.md |
| QL-TEST-COVERAGE | Test coverage review for one story before it closes (`/story-done`) | ql-test-coverage.md |
| QL-TEST-COVERAGE | 单个故事关闭前的测试覆盖评审（`/story-done`） | ql-test-coverage.md |
| ND-CONSISTENCY | Narrative consistency of writer deliverables | nd-consistency.md |
| ND-CONSISTENCY | 编剧交付物的叙事一致性 | nd-consistency.md |
| AD-VISUAL | Visual consistency of art/tech-art decisions | ad-visual.md |
| AD-VISUAL | 美术/技术美术决策的视觉一致性 | ad-visual.md |

---

## Review Modes
## 评审模式

Review intensity controls whether gates run.
评审强度控制门禁是否运行。

**Global config**: `modes.review_mode` in `project.yaml` — one word: `full`,
`lean`, or `solo`. Legacy fallback: `production/review-mode.txt` (single line,
same values); `project.yaml` wins when both are present. `/start` never writes
it: left unset, it follows `modes.rigor` (`minimal` → `solo`, `standard` →
`lean`, `full` → `full`). Set it explicitly only with
`/settings modes.review_mode=<value>`.
**全局配置**：`project.yaml` 中的 `modes.review_mode` — 一个单词：`full`、`lean` 或 `solo`。旧版回退：`production/review-mode.txt`（单行，取值相同）；两者同时存在时 `project.yaml` 优先。`/start` 从不写入它：若不设置，它跟随 `modes.rigor`（`minimal` → `solo`，`standard` → `lean`，`full` → `full`）。仅在明确设置时使用 `/settings modes.review_mode=<value>`。

**Per-run override**: any gate-using skill accepts `--review [full|lean|solo]`,
overriding the global config for that run only.
**按运行覆盖**：任何使用门禁的技能都接受 `--review [full|lean|solo]`，仅覆盖该次运行的全局配置。

| Mode | What runs |
| 模式 | 运行内容 |
|------|-----------|
| `full` | All gates active — every workflow step reviewed |
| `full` | 所有门禁激活 — 每个工作流步骤都评审 |
| `lean` | PHASE-GATEs only (`/gate-check`) — per-skill gates skipped. The `rigor: standard` value |
| `lean` | 仅 PHASE-GATE（`/gate-check`）— 跳过各技能内门禁。即 `rigor: standard` 的取值 |
| `solo` | No director gates anywhere (game jams, prototypes, max speed). **Default** — the `rigor: minimal` value |
| `solo` | 任何地方都不运行总监门禁（游戏开发挑战赛、原型、最大速度）。**默认** — 即 `rigor: minimal` 的取值 |

**One exception:** `/team-narrative` runs ND-CONSISTENCY in every review mode
whenever narrative-director is on the team — it is that pipeline's only
narrative consistency check, not an optional review.
**一个例外：** 只要 narrative-director 在团队中，`/team-narrative` 在每种评审模式下都会运行 ND-CONSISTENCY — 它是该流水线唯一的叙事一致性检查，不是可选的评审。

---

## Invocation Pattern (copy into any skill)
## 调用模式（复制到任何技能中）

**MANDATORY: apply the review mode before every gate spawn.**
**强制：在每次生成门禁前应用评审模式。**

The value is already resolved — skills call
`` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode` ``
(with the matching `allowed-tools` grant — see `config-resolution.md`)
and read `review_mode` from the emitted block. Do **not** re-derive it here. The
full chain (`project.local.yaml` → `project.yaml` → `production/review-mode.txt`
→ `modes.rigor` expansion, `standard`→`lean`), its defaults and its failure modes are specified in
`.claude/docs/config-resolution.md`, and covered by the config test suite.
该值已被解析 — 技能调用
`` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode` ``
（使用匹配的 `allowed-tools` 授权 — 见 `config-resolution.md`），
并从输出的块中读取 `review_mode`。**不要**在这里重新推导它。完整链路
（`project.local.yaml` → `project.yaml` → `production/review-mode.txt`
→ `modes.rigor` 展开，`standard`→`lean`）、其默认值和失败模式在
`.claude/docs/config-resolution.md` 中有详细说明，并由配置测试套件覆盖。

An inline `--review [mode]` argument, if the skill accepts one, overrides the
resolved value for that run.
如果技能接受内联 `--review [mode]` 参数，它会覆盖该次运行的已解析值。

Apply the resolved mode:
应用解析后的模式：
- `solo` → **skip all gates**. Note: `[GATE-ID] skipped — Solo mode`
- `solo` → **跳过所有门禁**。注明：`[GATE-ID] skipped — Solo mode`
- `lean` → **skip unless this is a PHASE-GATE** (CD-PHASE-GATE, TD-PHASE-GATE, PR-PHASE-GATE, AD-PHASE-GATE). Note: `[GATE-ID] skipped — Lean mode`
- `lean` → **除非是 PHASE-GATE 否则跳过**（CD-PHASE-GATE、TD-PHASE-GATE、PR-PHASE-GATE、AD-PHASE-GATE）。注明：`[GATE-ID] skipped — Lean mode`
- `full` → spawn as normal
- `full` → 正常生成

> **PHASE-GATE panel width is a second, independent axis.** `review_mode` decides
> whether the four PHASE-GATEs run at all; `modes.workflow` decides how many of
> them run — `minimal` → PR only, `standard` → TD + PR, `full` → all four. The
> rule and its rationale live in `/gate-check` Section 4b, the only skill that
> spawns PHASE-GATEs. Every other gate in this index is single-director and
> unaffected. Width never softens a verdict: the escalation rule below applies
> unchanged to whoever ran.
> **PHASE-GATE 面板宽度是第二条独立的轴。** `review_mode` 决定四个 PHASE-GATE 是否运行；`modes.workflow` 决定其中有多少个运行 — `minimal` → 仅 PR，`standard` → TD + PR，`full` → 全部四个。该规则及其理由位于 `/gate-check` 第 4b 节，这是唯一生成 PHASE-GATE 的技能。本索引中的其他门禁都是单总监门禁，不受影响。宽度从不会软化裁决：下方的升级规则对实际运行者同样适用。

```
# Apply mode check, then:
Spawn `[agent-name]` via `Agent`:
- Gate: [GATE-ID] — `Agent` prompt instructs the agent to read
  `.claude/docs/director-gates/[gate-id].md` FIRST (parent must not read it)
- Context: [fields under that gate's **Context to pass**]
- Await the verdict before proceeding.
```

For parallel spawning (multiple directors at one gate point): apply the mode
check per gate, then spawn all surviving agents simultaneously — issue all `Agent`
calls before waiting for any result; collect all verdicts before proceeding.
对于并行生成（同一门禁点有多个总监）：对每个门禁应用模式检查，然后同时生成所有幸存智能体 — 在等待任何结果之前发出所有 `Agent` 调用；在继续之前收集所有裁决。

---

## Standard Verdict Format
## 标准裁决格式

Every gate returns one of its three verdicts — or NOT ASSESSED when it could not
judge. Skills must handle all four. The three judgement words are each gate's
own — its definition file's **Verdicts** line is the authority — and the rows
below are their meanings (TD-FEASIBILITY's VIABLE / CONCERNS / HIGH RISK,
PR-MILESTONE's ON TRACK / AT RISK / OFF TRACK). NOT ASSESSED is the same word at
every gate, so no Verdicts line lists it:
每个门禁返回其三种裁决之一 — 当无法判断时返回 NOT ASSESSED。技能必须处理全部四种。三个判断词因门禁而异 — 其定义文件的 **Verdicts** 行是权威 — 下面的行是它们的含义（TD-FEASIBILITY 的 VIABLE / CONCERNS / HIGH RISK，PR-MILESTONE 的 ON TRACK / AT RISK / OFF TRACK）。NOT ASSESSED 在每个门禁都是同一个词，因此没有 Verdicts 行会列出它：

| Verdict | Meaning | Default action |
| 裁定 | 含义 | 默认动作 |
|---------|---------|----------------|
| **APPROVE / READY** | No issues. Proceed. | Continue the workflow |
| **APPROVE / READY** | 无问题。继续。 | 继续工作流 |
| **CONCERNS [list]** | Issues present but not blocking. | Surface to user via `AskUserQuestion` — options: `Revise flagged items` / `Accept and proceed` / `Discuss further`. Revise flagged items: the specialist who drafted the section re-drafts it; the revision goes through the skill's normal approve-then-write step, and the header records `REVISED [date]`. |
| **CONCERNS [list]** | 存在问题但不阻塞。 | 通过 `AskUserQuestion` 呈现给用户 — 选项：`Revise flagged items` / `Accept and proceed` / `Discuss further`。Revise flagged items：起草该章节的专家重新起草；修订会经过技能正常的先批准后写入步骤，头部记录 `REVISED [date]`。 |
| **REJECT / NOT READY [blockers]** | Blocking issues. Do not proceed. | Surface blockers to user. Do not write files or advance stage until resolved. |
| **REJECT / NOT READY [blockers]** | 阻塞性问题。不要继续。 | 向用户呈现阻塞项。在解决之前不要写入文件或推进阶段。 |
| **NOT ASSESSED [what was missing]** | An input the gate names was missing or unreadable, so no judgement was made. | Name what was missing. Never treat it as APPROVE/READY: supply the input and re-run the gate, or record NOT ASSESSED and let the skill's own verdict reflect it. |
| **NOT ASSESSED [what was missing]** | 门禁指定的某个输入缺失或无法读取，因此未做出判断。 | 说明缺失了什么。绝不要把它当作 APPROVE/READY：提供该输入并重新运行门禁，或记录 NOT ASSESSED 并让技能自身的裁决反映它。 |

**Rank**: NOT ASSESSED sits below REJECT / NOT READY and CONCERNS, and above
APPROVE / READY — a known problem is more actionable than an unknown, and a gate
that could not look has approved nothing. A director that found a problem and
also lacked an input answers with the problem's word and names the missing
input in its rationale. An artifact the skill reports as absent is information,
not a missing input. At a phase gate,
a missing artifact the target phase requires is a finding (NOT READY or
CONCERNS); one `/gate-check` passes as "not expected before [phase]" or "not
required at `workflow: [tier]`" is not a finding — a phase gate judges
readiness for the phase being entered, not a later one.
**排序**：NOT ASSESSED 位于 REJECT / NOT READY 和 CONCERNS 之下、APPROVE / READY 之上 — 已知问题比未知问题更可操作，而一个无法查看的门禁什么也没有批准。发现问题的总监若同时缺少某个输入，应以问题的判断词作答，并在其理由中说明缺失的输入。技能报告为缺失的产物是信息，不是缺失的输入。在阶段门禁中，目标阶段要求的产物缺失是一个问题项（NOT READY 或 CONCERNS）；以"不在 [阶段] 之前预期"或"在 `workflow: [层级]` 下不要求"通过 `/gate-check` 的，则不构成问题项 — 阶段门禁判断的是即将进入阶段（而非更晚阶段）的就绪度。

**Escalation rule**: When multiple directors are spawned in parallel, apply the
strictest verdict by that rank — one NOT READY overrides all READY verdicts, and
one NOT ASSESSED keeps the result from being READY.
**升级规则**：当并行生成多个总监时，依据该排序应用最严格的裁决 — 一个 NOT READY 覆盖所有 READY 裁决，一个 NOT ASSESSED 则使结果不能为 READY。

---

## Recording Gate Outcomes
## 记录门禁结果

After a gate resolves, record the verdict in the relevant document's status header:
门禁结束后，将裁决记录在相关文档的状态头部：

```markdown
> **[Director] Review ([GATE-ID])**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date] / NOT ASSESSED [date] — [missing input]
```

For phase gates, record in `docs/architecture/architecture.md` or
`production/session-state/active.md` as appropriate.
对于阶段门禁，酌情记录在 `docs/architecture/architecture.md` 或
`production/session-state/active.md` 中。

---

## Parallel Gate Protocol
## 并行门禁协议

At checkpoints needing multiple directors (most common at `/gate-check`):
在需要多个总监的检查点（最常见于 `/gate-check`）：

```
Spawn in parallel (issue all `Agent` calls before waiting for any result):
creative-director → CD-PHASE-GATE, technical-director → TD-PHASE-GATE,
producer → PR-PHASE-GATE, art-director → AD-PHASE-GATE

Collect every verdict from the directors that ran, then apply escalation rules:
- Any NOT READY / REJECT → overall verdict minimum FAIL
- Any CONCERNS → overall verdict minimum CONCERNS
- Any NOT ASSESSED (and no NOT READY / REJECT or CONCERNS) → overall verdict at best NOT ASSESSED
- All READY / APPROVE → eligible for PASS (still subject to artifact checks)
```

---

## Gate Coverage by Stage
## 各阶段门禁覆盖

| Stage | Required Gates | Optional Gates |
| 阶段 | 必需门禁 | 可选门禁 |
|-------|---------------|----------------|
| **Concept** | CD-PILLARS, AD-CONCEPT-VISUAL | TD-FEASIBILITY, PR-SCOPE |
| **概念** | CD-PILLARS、AD-CONCEPT-VISUAL | TD-FEASIBILITY、PR-SCOPE |
| **Systems Design** | TD-SYSTEM-BOUNDARY, CD-SYSTEMS, PR-SCOPE, CD-GDD-ALIGN (per GDD) | ND-CONSISTENCY, AD-VISUAL, TD-CHANGE-IMPACT (on GDD revision) |
| **系统设计** | TD-SYSTEM-BOUNDARY、CD-SYSTEMS、PR-SCOPE、CD-GDD-ALIGN（每个 GDD） | ND-CONSISTENCY、AD-VISUAL、TD-CHANGE-IMPACT（GDD 修订时） |
| **Technical Setup** | TD-ARCHITECTURE, TD-ADR (per ADR), TD-MANIFEST, LP-FEASIBILITY, AD-ART-BIBLE | TD-ENGINE-RISK |
| **技术搭建** | TD-ARCHITECTURE、TD-ADR（每个 ADR）、TD-MANIFEST、LP-FEASIBILITY、AD-ART-BIBLE | TD-ENGINE-RISK |
| **Pre-Production** | PR-EPIC, QL-STORY-READY (per story), PR-SPRINT, the PHASE-GATE panel (via gate-check — PR at `minimal`, TD + PR at `standard`, all four at `full`) | CD-PLAYTEST |
| **预生产** | PR-EPIC、QL-STORY-READY（每个故事）、PR-SPRINT、PHASE-GATE 面板（通过 gate-check — `minimal` 下 PR，`standard` 下 TD + PR，`full` 下全部四个） | CD-PLAYTEST |
| **Production** | LP-CODE-REVIEW (per story), QL-STORY-READY, PR-SPRINT (per sprint), QL-TEST-COVERAGE (per story, via `/story-done`) | PR-MILESTONE, AD-VISUAL, TD-CHANGE-IMPACT (on GDD revision) |
| **生产** | LP-CODE-REVIEW（每个故事）、QL-STORY-READY、PR-SPRINT（每个冲刺）、QL-TEST-COVERAGE（每个故事，通过 `/story-done`） | PR-MILESTONE、AD-VISUAL、TD-CHANGE-IMPACT（GDD 修订时） |
| **Polish** | CD-PLAYTEST, PR-MILESTONE | AD-VISUAL |
| **打磨** | CD-PLAYTEST、PR-MILESTONE | AD-VISUAL |
| **Release** | The PHASE-GATE panel (via gate-check — PR at `minimal`, TD + PR at `standard`, all four at `full`) | — |
| **发布** | PHASE-GATE 面板（通过 gate-check — `minimal` 下 PR，`standard` 下 TD + PR，`full` 下全部四个） | — |
