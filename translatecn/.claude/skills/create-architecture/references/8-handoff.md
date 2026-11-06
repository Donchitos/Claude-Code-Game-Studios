# /create-architecture — Phase 8: Handoff
# /create-architecture — 阶段 8：交接

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/create-architecture` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 8: Handoff
## 阶段 8：交接

**Step 1 — Update session state**: Write a summary to `production/session-state/active.md` covering: artifact written, TD/LP sign-off verdicts, any blockers, required ADRs remaining, and next step.
**步骤 1 — 更新会话状态**：向 `production/session-state/active.md` 写入摘要，涵盖：
已写入的制品、TD/LP 签核裁决、任何阻塞项、剩余的必要 ADR，以及下一步。

**Step 2 — Output the handoff** using exactly this template (no freeform prose, no rephrasing of section titles):
**步骤 2 — 输出交接内容**，严格使用以下模板（不得自由行文，不得改写小节标题）：

---

## Architecture Complete

`docs/architecture/architecture.md` v[N] — [TD-ARCHITECTURE: APPROVE / CONCERNS (accepted) / REVISED after CONCERNS / REVISED after REJECT / NOT ASSESSED / skipped — [mode] mode]. [One sentence on what the architecture covers.]

---

## Run These ADRs Next

**1. `/architecture-decision "[Title]"` → ADR-[XXXX]**
[One sentence: what it defines and what it unblocks.]

**2. `/architecture-decision "[Title]"` → ADR-[XXXX]**
[One sentence.]

**3. `/architecture-decision "[Title]"` → ADR-[XXXX]**
[One sentence.]

**Then:** `/architecture-review`, and `/create-control-manifest` once it passes and those ADRs are Accepted — it turns them into the layer rules manifest.

List top 3 from Phase 6 in priority order. If fewer than 3 remain, list only what's outstanding.

---

## Gate-Check Readiness

> **Required before `/gate-check pre-production`:**
> - [ ] Accept ADRs: [list Proposed ADR IDs that must be Accepted]
> - [ ] Write ADRs: [list ADR IDs that must still be written]
> - [ ] Run `/architecture-review` — writes the review report and the traceability index (`docs/architecture/requirements-traceability.md`) the gate reads
> - [ ] Run `/test-setup` — scaffolds `tests/unit/`, `tests/integration/`, CI workflow, and an example test file
> - [ ] Run `/ux-design` — creates `design/ux/interaction-patterns.md` and `design/accessibility-requirements.md`
>
> Run `/gate-check pre-production` when all boxes are checked.

If nothing is blocking, write instead:
> No blockers — run `/gate-check pre-production` now.

---

## Open Questions to Watch

| ID | Summary | Priority | Resolution Path |
|----|---------|----------|-----------------|
| QQ-XX | [short description] | High / Medium / Low | [ADR or system that resolves it] |

Omit this section entirely if there are no open QQs.

---

(End of handoff. Do not add trailing commentary after the closing rule.)

---

## 架构完成

`docs/architecture/architecture.md` v[N] — [TD-ARCHITECTURE: APPROVE / CONCERNS (accepted) / REVISED after CONCERNS / REVISED after REJECT / NOT ASSESSED / skipped — [mode] mode]。[一句话说明架构覆盖了什么。]

---

## 接下来运行这些 ADR

**1. `/architecture-decision "[Title]"` → ADR-[XXXX]**
[一句话：它定义了什么，以及它解除了什么阻塞。]

**2. `/architecture-decision "[Title]"` → ADR-[XXXX]**
[一句话。]

**3. `/architecture-decision "[Title]"` → ADR-[XXXX]**
[一句话。]

**然后：** `/architecture-review`，以及在其通过且那些 ADR 被接受之后的 `/create-control-manifest` — 后者会将其转化为分层规则清单。

按优先级顺序列出阶段 6 中的前 3 项。若剩余不足 3 项，则只列出尚待完成的部分。

---

## 门禁检查就绪情况

> **`/gate-check pre-production` 之前必需：**
> - [ ] 接受 ADR：[列出必须被接受的 Proposed ADR ID]
> - [ ] 编写 ADR：[列出仍必须编写的 ADR ID]
> - [ ] 运行 `/architecture-review` — 写入门禁所读取的评审报告和可追溯性索引（`docs/architecture/requirements-traceability.md`）
> - [ ] 运行 `/test-setup` — 搭建 `tests/unit/`、`tests/integration/`、CI 工作流以及一个示例测试文件
> - [ ] 运行 `/ux-design` — 创建 `design/ux/interaction-patterns.md` 和 `design/accessibility-requirements.md`
>
> 当所有框都勾选后，运行 `/gate-check pre-production`。

若没有阻塞，则改写为：
> 无阻塞 — 现在运行 `/gate-check pre-production`。

---

## 需关注的开放问题

| ID | 摘要 | 优先级 | 解决路径 |
|----|---------|----------|-----------------|
| QQ-XX | [简短描述] | High / Medium / Low | [解决它的 ADR 或系统] |

若没有开放的 QQ，则完全省略此小节。

---

（交接结束。不要在结尾分隔线之后添加任何尾随评论。）

---
