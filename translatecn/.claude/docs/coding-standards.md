# Coding Standards
# 编码标准

- All game code must include doc comments on public APIs
- 所有游戏代码必须在公共 API 上包含文档注释

- Architecture decisions are recorded as ADRs in `docs/architecture/`. **How many is
  set by `modes.workflow`** — all ADRs at `full`, *critical* ADRs only at `standard`,
  and none required at `minimal`, where the decision log and `design/game-brief.md`
  carry the rationale instead. See `.claude/docs/workflow-modes.md`.
- 架构决策以 ADR 形式记录在 `docs/architecture/` 中。**记录多少由 `modes.workflow` 决定** —
  `full` 记录全部 ADR，`standard` 只记录*关键* ADR，`minimal` 不要求任何 ADR，
  改由决策日志和 `design/game-brief.md` 承载理由。参见 `.claude/docs/workflow-modes.md`。

- Gameplay values must be data-driven (external config), never hardcoded
- 游戏玩法数值必须是数据驱动（外部配置），绝不硬编码

- All public methods must be unit-testable (dependency injection over singletons)
- 所有公共方法必须可单元测试（依赖注入优于单例）

- Commits must reference the relevant design document or task ID
- 提交必须引用相关设计文档或任务 ID

- **Commit messages**: Use Conventional Commits format — `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`. Reference the story or task ID in the body (e.g., `Story: EPIC-001-S02`).
- **提交信息**：使用 Conventional Commits 格式 — `feat:`、`fix:`、`chore:`、`docs:`、`test:`、`refactor:`。在正文中引用 story 或任务 ID（例如 `Story: EPIC-001-S02`）。

- **Verification-driven development**: Write tests first when adding gameplay systems.
  For UI changes, verify with screenshots. Compare expected output to actual output
  before marking work complete. Every implementation should have a way to prove it works.
- **验证驱动开发**：添加游戏玩法系统时先写测试。
  UI 变更用截图验证。在标记工作完成前，将预期输出与实际输出进行对比。
  每个实现都应有方法证明其有效。

- **A parse check is not a run.** Every story that changes something
  player-observable is launched and observed before it closes, and the
  observation is a retained screenshot in `production/qa/evidence/`. Procedure
  per engine: `.claude/docs/run-and-observe.md`. Not waived at
  `qa.level: minimal` — tests are, the look is not.
- **解析检查不等于运行。** 每个改变了玩家可观察内容的 story 在关闭前都必须被启动并观察，
  观察结果是一张保留在 `production/qa/evidence/` 中的截图。各引擎的操作流程见
  `.claude/docs/run-and-observe.md`。在 `qa.level: minimal` 时也不豁免 —
  测试可以豁免，但观察不能。

# Design Document Standards
# 设计文档标准

- All design docs use Markdown
- 所有设计文档使用 Markdown

- Each mechanic has a dedicated document in `design/gdd/`
- 每个机制在 `design/gdd/` 中有专门文档

- **How many of the 8 sections are required depends on `modes.workflow`** —
  all 8 at `full`, 5 (+ Formulas when the system defines numeric rules — rates,
  curves, thresholds, costs; the system's `Category` is a hint, not the test) at
  `standard`, and no
  GDD at all at `minimal`, where `design/game-brief.md` is the design record.
  See `.claude/docs/workflow-modes.md`. The 8 sections:
- **8 个章节中要求几个取决于 `modes.workflow`** —
  `full` 要求全部 8 个，`standard` 要求 5 个（当系统定义数值规则时另加 Formulas — 速率、
  曲线、阈值、成本；系统的 `Category` 只是提示，不是判断依据），
  而 `minimal` 完全不要求 GDD，改由 `design/game-brief.md` 作为设计记录。
  参见 `.claude/docs/workflow-modes.md`。这 8 个章节是：
  1. **Overview** -- one-paragraph summary
  1. **Overview** — 一段摘要
  2. **Player Fantasy** -- intended feeling and experience
  2. **Player Fantasy** — 预期的感觉和体验
  3. **Detailed Rules** -- unambiguous mechanics
  3. **Detailed Rules** — 明确无歧义的机制
  4. **Formulas** -- all math defined with variables
  4. **Formulas** — 所有数学公式用变量定义
  5. **Edge Cases** -- unusual situations handled
  5. **Edge Cases** — 处理的特殊情况
  6. **Dependencies** -- other systems listed
  6. **Dependencies** — 列出其他系统
  7. **Tuning Knobs** -- configurable values identified
  7. **Tuning Knobs** — 标识可配置值
  8. **Acceptance Criteria** -- testable success conditions
  8. **Acceptance Criteria** — 可测试的成功条件

- Balance values must link to their source formula or rationale
- 平衡数值必须链接到其源公式或理由

# Testing Standards
# 测试标准

## Test Evidence by Story Type
## 按 story 类型的测试证据

All stories must have appropriate test evidence before they can be marked Done:
所有 story 在标记为 Done 前必须有适当的测试证据：

| Story Type | Required Evidence | Location | Default Gate Level |
|---|---|---|---|
| **Logic** (formulas, AI, state machines) | Automated unit test — must pass | `tests/unit/[system]/` | BLOCKING |
| **Integration** (multi-system) | Integration test OR documented playtest | `tests/integration/[system]/` | BLOCKING |
| **Visual/Feel** (animation, VFX, feel) | Retained screenshot + lead sign-off | `production/qa/evidence/` | BLOCKING |
| **UI** (menus, HUD, screens) | Retained screenshot of each screen touched | `production/qa/evidence/` | BLOCKING |
| **Config/Data** (balance tuning) | Smoke check pass | `production/qa/smoke-[date].md` | ADVISORY |

| Story 类型 | 必需证据 | 位置 | 默认门禁级别 |
|---|---|---|---|
| **Logic**（公式、AI、状态机） | 自动化单元测试 — 必须通过 | `tests/unit/[system]/` | BLOCKING |
| **Integration**（多系统） | 集成测试或有记录的试玩 | `tests/integration/[system]/` | BLOCKING |
| **Visual/Feel**（动画、VFX、手感） | 保留的截图 + 主管签字 | `production/qa/evidence/` | BLOCKING |
| **UI**（菜单、HUD、画面） | 每个被改动画面的保留截图 | `production/qa/evidence/` | BLOCKING |
| **Config/Data**（平衡调参） | 冒烟检查通过 | `production/qa/smoke-[date].md` | ADVISORY |

The **Default Gate Level** applies when `testing.strict` is not set in
`project.yaml`. A project may override it per test type: `testing.strict.logic`,
`.integration`, `.visual`, `.ui`, and `.config` each take `true` (BLOCKING) or
`false` (ADVISORY). `/story-done`, `/story-readiness`, `/dev-story`,
`/gate-check`, and `/smoke-check` resolve the effective level from that setting,
falling back to the defaults above when it is absent.
当 `project.yaml` 中未设置 `testing.strict` 时，适用**默认门禁级别**。
项目可按测试类型覆盖它：`testing.strict.logic`、`.integration`、`.visual`、`.ui`
和 `.config` 各自取 `true`（BLOCKING）或 `false`（ADVISORY）。`/story-done`、
`/story-readiness`、`/dev-story`、`/gate-check` 和 `/smoke-check` 会从该设置解析
生效级别，在缺失时回退到上述默认值。

> **Why Visual and UI block.** "Retained" is load-bearing — the screenshot must
> still be on disk in `production/qa/evidence/` when the story is closed. One
> that was captured and discarded is an assertion, not evidence. These two rows
> block because for a game the way it looks *is* the product: an advisory visual
> gate gets deferred in favour of whatever does block, and the result is a
> well-tested game that looks wrong.
> **为什么 Visual 与 UI 会阻塞。** “保留”是承重条件 — story 关闭时截图必须
> 仍然存在于 `production/qa/evidence/` 磁盘上。截取后丢弃的截图只是断言，不是证据。
> 这两行会阻塞，因为对游戏而言外观*就是*产品：建议性的视觉门禁总会被推迟，
> 让位给任何真正阻塞的事项，结果就是一个测试完善但外观错误的游戏。

> **Exception — `/smoke-check`.** The ADVISORY default for **Config/Data** above
> applies to *per-story evidence* gates. `/smoke-check` is a build-health gate,
> not a per-story evidence gate, so its own unset default for
> `testing.strict.config` is **BLOCKING**. The two defaults differ on purpose.
> **例外 — `/smoke-check`。** 上述 **Config/Data** 的 ADVISORY 默认值适用于
> *按 story 的证据*门禁。`/smoke-check` 是构建健康门禁，不是按 story 的证据门禁，
> 因此它自身对 `testing.strict.config` 的未设置默认值是 **BLOCKING**。
> 这两个默认值刻意不同。

## Automated Test Rules
## 自动化测试规则

- **Naming**: per engine — `.claude/rules/test-standards.md`
- **命名**：按引擎 — `.claude/rules/test-standards.md`

- **Determinism**: Tests must produce the same result every run — no random seeds, no time-dependent assertions
- **确定性**：测试每次运行必须产生相同结果 — 无随机种子、无时间相关断言

- **Isolation**: Each test sets up and tears down its own state; tests must not depend on execution order
- **隔离性**：每个测试建立并清理自己的状态；测试不得依赖执行顺序

- **No hardcoded data**: Test fixtures use constant files or factory functions, not inline magic numbers
  (exception: boundary value tests where the exact number IS the point)
- **无硬编码数据**：测试夹具使用常量文件或工厂函数，而非内联魔法数字
  （例外：边界值测试中具体数字本身就是测试目的）

- **Independence**: Unit tests do not call external APIs, databases, or file I/O — use dependency injection
- **独立性**：单元测试不调用外部 API、数据库或文件 I/O — 使用依赖注入

## What NOT to Automate
## 不应自动化的内容

- Visual fidelity (shader output, VFX appearance, animation curves)
- 视觉保真度（着色器输出、VFX 外观、动画曲线）

- "Feel" qualities (input responsiveness, perceived weight, timing)
- “手感”特性（输入响应、感知重量、时序）

- Platform-specific rendering (test on target hardware, not headlessly)
- 平台特定渲染（在目标硬件上测试，而非无头模式）

- Full gameplay sessions (covered by playtesting, not automation)
- 完整游戏会话（由试玩覆盖，而非自动化）

## CI/CD Rules
## CI/CD 规则

- Automated test suite runs on every push to main and every PR
- 自动化测试套件在每次推送到 main 和每个 PR 时运行

- No merge if tests fail — tests are a blocking gate in CI
- 测试失败则禁止合并 — 测试是 CI 中的阻塞性门禁

- Never disable or skip failing tests to make CI pass — fix the underlying issue
- 绝不通过禁用或跳过失败测试来让 CI 通过 — 修复根本问题

- Engine-specific CI commands:
- 引擎特定的 CI 命令：
  - **Godot**: `godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode`
  - **Godot**: `godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode`
  - **Unity**: `game-ci/unity-test-runner@v4` (GitHub Actions)
  - **Unity**: `game-ci/unity-test-runner@v4`（GitHub Actions）
  - **Unreal**: headless runner with `-nullrhi` flag
  - **Unreal**: 带 `-nullrhi` 标志的无头运行器
