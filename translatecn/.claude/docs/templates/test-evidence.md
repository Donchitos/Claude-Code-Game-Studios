# Test Evidence: [Story Title]
# 测试证据：[故事标题]

> **Story**: `[path to story file]`
> **故事**：`[故事文件路径]`
> **Story Type**: [Visual/Feel | UI]
> **故事类型**：[视觉/手感 | UI]
> **Date**: [date]
> **日期**：[日期]
> **Tester**: [who performed the test]
> **测试者**：[执行测试的人]
> **Build / Commit**: [version or git hash]
> **构建 / 提交**：[版本或 git 哈希]

---

## What Was Tested
## 测试了什么

[One paragraph describing the feature or behaviour that was validated. Include
the acceptance criteria numbers from the story that this evidence covers.]
[用一段话描述所验证的功能或行为。包含本证据所覆盖的故事
验收标准编号。]

**Acceptance criteria covered**: [AC-1, AC-2, AC-3]
**已覆盖的验收标准**：[AC-1、AC-2、AC-3]

---

## Acceptance Criteria Results
## 验收标准结果

| # | Criterion (from story) | Result | Notes |
|---|----------------------|--------|-------|
| AC-1 | [exact criterion text] | PASS / FAIL | [any observations] |
| AC-2 | [exact criterion text] | PASS / FAIL | |
| AC-3 | [exact criterion text] | PASS / FAIL | |

| # | 标准（来自故事） | 结果 | 备注 |
|---|----------------------|--------|-------|
| AC-1 | [标准原文] | 通过 / 失败 | [任何观察] |
| AC-2 | [标准原文] | 通过 / 失败 | |
| AC-3 | [标准原文] | 通过 / 失败 | |

---

## Screenshots / Video
## 截图 / 视频

List all captured evidence below. Store files in the same directory as this
document or in `production/qa/evidence/[story-slug]/`.
在下方列出所有已捕获的证据。将文件存放在本文档所在目录，或
`production/qa/evidence/[story-slug]/`。

**The file must actually be on disk.** Visual/Feel and UI gates are BLOCKING by
default, and `/story-done` and `/test-evidence-review` glob for the image — a
filename listed here with no file beside it does not satisfy the gate.
**文件必须确实存在于磁盘上。** 视觉/手感与 UI 关卡默认是**阻塞性**的，
并且 `/story-done` 与 `/test-evidence-review` 会通配查找该图片——此处列出文件名
但旁边没有对应文件，并不能满足关卡要求。

| # | Filename | What It Shows | Acceptance Criterion |
|---|----------|--------------|----------------------|
| 1 | `[filename.png]` | [brief description of what is visible] | AC-1 |
| 2 | `[filename.png]` | | AC-2 |

| # | 文件名 | 展示了什么 | 验收标准 |
|---|----------|--------------|----------------------|
| 1 | `[filename.png]` | [可见内容的简要描述] | AC-1 |
| 2 | `[filename.png]` | | AC-2 |

*If video: note the timestamp and what it demonstrates.*
*若为视频：注明时间戳及其所示内容。*

---

## Test Conditions
## 测试条件

- **Game state at start**: [e.g., "fresh save, player at level 1, no items"]
- **开始时的游戏状态**：[例如"全新存档，玩家 1 级，无物品"]
- **Platform / hardware**: [e.g., "Windows 11, GTX 1080, 1080p"]
- **平台 / 硬件**：[例如"Windows 11、GTX 1080、1080p"]
- **Framerate during test**: [e.g., "stable 60fps" or "~45fps — within budget"]
- **测试期间帧率**：[例如"稳定 60fps"或"约 45fps — 在预算之内"]
- **Any special setup required**: [e.g., "dev menu used to trigger specific state"]
- **所需特殊设置**：[例如"使用开发菜单触发特定状态"]

---

## Observations
## 观察

[Anything noteworthy that didn't cause a FAIL but should be recorded. Examples:
minor visual jitter, frame dip under load, behaviour that technically passes
but felt slightly off. These become candidates for polish work.]
[任何值得注意但未导致失败、却应记录的事项。例如：
轻微视觉抖动、负载下的帧率下降、技术上通过
但感觉稍有偏差的行为。这些会成为打磨工作的候选项。]

- [Observation 1]
- [观察 1]
- [Observation 2]
- [观察 2]

If nothing notable: *No significant observations.*
若无显著事项：*无重要观察。*

---

## Sign-Off
## 签署确认

A **Visual/Feel** story needs the lead sign-off below — the art-director, or the
designer who owns the feature — before `/story-done` marks it COMPLETE. A **UI**
story is closed by the retained screenshot of each screen it touched; a sign-off
here is welcome but not required (`.claude/docs/coding-standards.md`).
**视觉/手感**类故事需要下方的主负责人签署——艺术总监，或
拥有该功能的设计师——之后 `/story-done` 才会将其标记为完成。**UI**
类故事通过保留其所触及每个界面的截图来关闭；此处签署
欢迎但不必需（`.claude/docs/coding-standards.md`）。

**Solo developers**: you may sign as the lead yourself. The intent is that
someone deliberately reviews the evidence before marking complete.
**独立开发者**：你可以自己以主负责人身份签署。其意图是
在标记完成前，有人刻意审查过证据。

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead (art-director / designer) | | | [ ] Approved |

| 角色 | 姓名 | 日期 | 签署 |
|------|------|------|-----------|
| 主负责人（艺术总监 / 设计师） | | | [ ] 已批准 |

*Optional:* add a row for anyone else whose review your team wants, such as the
developer or the QA lead. `/story-done` and `/test-evidence-review` treat every
row in this table as required, so add one only for someone who will sign.
*可选：* 为团队希望其参与评审的其他人添加一行，例如
开发者或 QA 负责人。`/story-done` 与 `/test-evidence-review` 会将本表中的每一行
视为必需，因此只应为确实会签署的人添加。

**Any sign-off can be marked "Deferred — [reason]"** if the person is
unavailable. Deferred sign-offs must be resolved before the story advances
past the sprint review.
**任何签署都可标记为"延期 — [原因]"**，前提是该人员
无法到场。延期的签署必须在故事推进
至冲刺评审之前解决。

---

*Template: `.claude/docs/templates/test-evidence.md`*
*模板：`.claude/docs/templates/test-evidence.md`*
*Used for: Visual/Feel and UI story type evidence records*
*用于：视觉/手感与 UI 类故事的证据记录*
*Location: `production/qa/evidence/[story-slug]-evidence.md`*
*位置：`production/qa/evidence/[story-slug]-evidence.md`*
