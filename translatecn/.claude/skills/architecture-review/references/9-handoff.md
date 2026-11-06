# /architecture-review — Phase 9: Handoff
# /architecture-review — 阶段 9：交接

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/architecture-review` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 9: Handoff
## 阶段 9：交接

After completing the review and writing approved files, present:
在完成评审并写入已批准的文件之后，呈现：

1. **Immediate actions**: List the top 3 ADRs to create (highest-impact gaps first,
   Foundation layer before Feature layer)
1. **即时行动**：列出要创建的前 3 个 ADR（影响最大的缺口优先，Foundation 层先于
   Feature 层）
2. **Pre-gate checklist**: Check whether these exist via Glob and mark each ✅ or ❌:
   - the engine's test root — `tests/unit/` and `tests/integration/` (Godot), `Assets/Tests/EditMode/` and `Assets/Tests/PlayMode/` (Unity), `Source/<Module>/Private/Tests/` (Unreal) — if ❌: run `/test-setup`
   - `.github/workflows/tests.yml` — if ❌: run `/test-setup`
   - `design/accessibility-requirements.md` — if ❌: run `/ux-design`
   - `design/ux/interaction-patterns.md` — if ❌: run `/ux-design`
   Present ❌ items as required steps before gate-check. Do not offer `/gate-check`
   as an option if any item is ❌ — offer the missing skill to run instead.
2. **门禁前检查清单**：通过 Glob 检查这些是否存在，并各自标记 ✅ 或 ❌：
   - 引擎的测试根目录 — `tests/unit/` 和 `tests/integration/`（Godot）、
     `Assets/Tests/EditMode/` 和 `Assets/Tests/PlayMode/`（Unity）、
     `Source/<Module>/Private/Tests/`（Unreal）— 若为 ❌：运行 `/test-setup`
   - `.github/workflows/tests.yml` — 若为 ❌：运行 `/test-setup`
   - `design/accessibility-requirements.md` — 若为 ❌：运行 `/ux-design`
   - `design/ux/interaction-patterns.md` — 若为 ❌：运行 `/ux-design`
   把 ❌ 条目呈现为 gate-check 之前的必需步骤。若任何条目为 ❌，不要把
   `/gate-check` 作为选项提供 — 而是提供缺失的技能来运行。
3. **Rerun trigger**: "Re-run `/architecture-review` after each new ADR is written
   to verify coverage improves"
3. **重跑触发条件**："每写入一个新 ADR 后就重跑 `/architecture-review`，以验证
   覆盖有所改善"（Re-run `/architecture-review` after each new ADR is written
   to verify coverage improves）

Then close with `AskUserQuestion` tailored to the pre-gate checklist state:
然后以针对门禁前检查清单状态量身定制的 `AskUserQuestion` 收尾：
- If ADR gaps remain or any pre-gate item is ❌:
  - "Architecture review complete. What would you like to do next?"
    - [A] Write a missing ADR — open a fresh session and run `/architecture-decision [system]`
    - [B] Run `/test-setup` — required before gate-check (only show if test infrastructure is ❌)
    - [C] Run `/ux-design` — required before gate-check (only show if UX/accessibility files are ❌)
    - [D] Stop here for this session
- 若仍有 ADR 缺口或任何门禁前条目为 ❌：
  - "Architecture review complete. What would you like to do next?"
    （架构评审完成。你接下来想做什么？）
    - [A] Write a missing ADR — open a fresh session and run `/architecture-decision [system]`
      （编写缺失的 ADR — 打开新会话并运行 `/architecture-decision [system]`）
    - [B] Run `/test-setup` — required before gate-check (only show if test infrastructure is ❌)
      （运行 `/test-setup` — gate-check 之前必需，仅在测试基础设施为 ❌ 时显示）
    - [C] Run `/ux-design` — required before gate-check (only show if UX/accessibility files are ❌)
      （运行 `/ux-design` — gate-check 之前必需，仅在 UX/无障碍文件为 ❌ 时显示）
    - [D] Stop here for this session
      （本次会话到此为止）
- If all pre-gate checklist items are ✅ and no blocking ADR gaps remain:
  - "Architecture review complete. All pre-gate items confirmed. What would you like to do next?"
    - [A] Run `/gate-check pre-production`
    - [B] Write a missing ADR — open a fresh session and run `/architecture-decision [system]`
    - [C] Stop here for this session
- 若所有门禁前检查清单条目均为 ✅ 且没有阻塞性 ADR 缺口：
  - "Architecture review complete. All pre-gate items confirmed. What would you like to do next?"
    （架构评审完成。所有门禁前条目均已确认。你接下来想做什么？）
    - [A] Run `/gate-check pre-production`
      （运行 `/gate-check pre-production`）
    - [B] Write a missing ADR — open a fresh session and run `/architecture-decision [system]`
      （编写缺失的 ADR — 打开新会话并运行 `/architecture-decision [system]`）
    - [C] Stop here for this session
      （本次会话到此为止）

---
