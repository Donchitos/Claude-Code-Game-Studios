# Docs Directory
# 文档目录

When authoring or editing files in this directory, follow these standards.
在编写或编辑此目录中的文件时，请遵循以下标准。

## Architecture Decision Records (`docs/architecture/`)
## 架构决策记录（`docs/architecture/`）

Use the ADR template: `.claude/docs/templates/architecture-decision-record.md`
使用 ADR 模板：`.claude/docs/templates/architecture-decision-record.md`

**Required sections:** Title, Status, Context, Decision, Consequences,
ADR Dependencies, Engine Compatibility, GDD Requirements Addressed
**必填章节：** 标题、状态、背景、决策、后果、ADR 依赖、引擎兼容性、所满足的 GDD 需求

**Status lifecycle:** `Proposed` → `Accepted` → `Superseded`
**状态生命周期：** `Proposed` → `Accepted` → `Superseded`

- Never skip `Accepted` — stories referencing a `Proposed` ADR are auto-blocked
- 切勿跳过 `Accepted` —— 引用 `Proposed` 状态 ADR 的故事会被自动拦截

- Use `/architecture-decision` to create ADRs through the guided flow
- 使用 `/architecture-decision` 通过引导式流程创建 ADR

**TR Registry:** `docs/architecture/tr-registry.yaml`
**TR 注册表：** `docs/architecture/tr-registry.yaml`

- Stable requirement IDs (e.g. `TR-movement-001`) that link GDD requirements to stories
- 稳定的需求 ID（例如 `TR-movement-001`），用于将 GDD 需求关联到故事

- Never renumber existing IDs — only append new ones
- 切勿重新编号现有 ID —— 只能追加新的 ID

- Updated by `/architecture-review` Phase 8
- 由 `/architecture-review` 的第 8 阶段更新

**Control Manifest:** `docs/architecture/control-manifest.md`
**控制清单：** `docs/architecture/control-manifest.md`

- Flat programmer rules sheet: Required / Forbidden / Guardrails per layer
- 扁平化的程序员规则表：按层级列出"必须使用 / 禁止使用 / 防护规则"

- Date-stamped `Manifest Version:` in header
- 在头部带有日期戳的 `Manifest Version:`

- Stories embed this version; `/story-done` checks for staleness
- 故事会嵌入此版本号；`/story-done` 会检查其是否过期

**Validation:** Run `/architecture-review` after completing a set of ADRs.
**校验：** 完成一组 ADR 后，运行 `/architecture-review`。

## Engine Reference (`docs/engine-reference/`)
## 引擎参考文档（`docs/engine-reference/`）

Version-pinned engine API snapshots. **Always check here before using any
engine API** — the LLM's training data predates the pinned engine version.
按版本锁定的引擎 API 快照。**在使用任何引擎 API 之前，请务必先查阅此处** —— LLM 的训练数据早于所锁定的引擎版本。

Current engine: see `docs/engine-reference/<engine>/VERSION.md` (`<engine>` is
`godot`, `unity` or `unreal`, matching `engine.name` in `project.yaml`)
当前引擎：参见 `docs/engine-reference/<engine>/VERSION.md`（`<engine>` 为 `godot`、`unity` 或 `unreal`，与 `project.yaml` 中的 `engine.name` 相对应）
