# Migration Guide: v1.0 → v1.1 project.yaml
# 迁移指南：v1.0 → v1.1 的 project.yaml

This guide covers converting an **existing project's config files** to
`project.yaml`. It is distinct from the template-diff instructions in
[UPGRADING.md](../UPGRADING.md) — that file tells you which *skill and agent
files* changed between releases and whether they're safe to overwrite. This
guide covers your *project's own data*: the values you configured in
`production/stage.txt`, `production/review-mode.txt`, and
`.claude/docs/technical-preferences.md`.
本指南讲解如何将**现有项目的配置文件**转换为 `project.yaml`。它与
[UPGRADING.md](../UPGRADING.md) 中的模板差异说明不同 —— 那个文件告诉你各版本之间哪些*技能与智能体文件*发生了变化，以及它们是否可以安全覆盖。本指南关注的是*你项目自身的数据*：你在
`production/stage.txt`、`production/review-mode.txt` 和
`.claude/docs/technical-preferences.md` 中配置的值。

If you're setting up a **brand-new** project on v1.1, you don't need this —
`/start` writes `project.yaml` directly and none of the legacy files apply.
如果你是在 v1.1 上搭建一个**全新**项目，则不需要本指南 ——
`/start` 会直接写入 `project.yaml`，且不涉及任何遗留文件。

---

## Do you need to migrate?
## 你需要迁移吗？

You have a v1.0 project needing migration if `project.yaml` does **not**
exist at your repo root, and at least one of these does:
如果仓库根目录下**不存在** `project.yaml`，而以下文件至少存在一个，那么你的 v1.0 项目需要迁移：

- `production/stage.txt`
- `production/stage.txt`

- `production/review-mode.txt`
- `production/review-mode.txt`

- `.claude/docs/technical-preferences.md` with real values (a copy still
  full of `[TO BE CONFIGURED]` placeholders is the untouched template
  default, not migratable data, and doesn't count)
- `.claude/docs/technical-preferences.md` 且包含真实值（如果副本中仍满是 `[TO BE CONFIGURED]` 占位符，那它就是未经改动的模板默认值，不属于可迁移数据，不算数）

Run `/adopt` and it will detect this automatically (Phase 2g) and walk you
through the steps below. You can also run the converter directly.
运行 `/adopt`，它会自动检测到这一情况（阶段 2g）并引导你完成下面的步骤。你也可以直接运行转换脚本。

---

## What gets preserved
## 哪些内容会被保留

| From | To (`project.yaml`) |
|---|---|
| `production/stage.txt` | `project.stage` |
| `production/review-mode.txt` | `modes.review_mode` |
| `technical-preferences.md` → Engine & Language | `engine.name`, `engine.version`, `engine.language`, `engine.rendering`, `engine.physics` |
| `technical-preferences.md` → Input & Platform | `platform.targets`, `platform.primary_input`, `platform.gamepad_support`, `platform.touch_support` |
| `technical-preferences.md` → Naming Conventions | `naming.classes`, `naming.variables`, `naming.constants`, `naming.signals`, `naming.files`, `naming.scenes` |
| `technical-preferences.md` → Performance Budgets | `performance.target_framerate`, `performance.frame_budget_ms`, `performance.draw_call_limit`, `performance.memory_ceiling_mb` |
| `technical-preferences.md` → Testing | `testing.framework`, `qa.coverage_minimum` |
| `technical-preferences.md` → Engine Specialists | `specialists.code`, `specialists.shader`, `specialists.ui`, `specialists.additional` |

| 来源 | 目标（`project.yaml`） |
|---|---|
| `production/stage.txt` | `project.stage` |
| `production/review-mode.txt` | `modes.review_mode` |
| `technical-preferences.md` → 引擎与语言 | `engine.name`、`engine.version`、`engine.language`、`engine.rendering`、`engine.physics` |
| `technical-preferences.md` → 输入与平台 | `platform.targets`、`platform.primary_input`、`platform.gamepad_support`、`platform.touch_support` |
| `technical-preferences.md` → 命名约定 | `naming.classes`、`naming.variables`、`naming.constants`、`naming.signals`、`naming.files`、`naming.scenes` |
| `technical-preferences.md` → 性能预算 | `performance.target_framerate`、`performance.frame_budget_ms`、`performance.draw_call_limit`、`performance.memory_ceiling_mb` |
| `technical-preferences.md` → 测试 | `testing.framework`、`qa.coverage_minimum` |
| `technical-preferences.md` → 引擎专家 | `specialists.code`、`specialists.shader`、`specialists.ui`、`specialists.additional` |

Settings that don't exist in v1.0 at all (`modes.rigor`, `qa.level`,
`docs.density`, `team.size`, `modes.story_granularity`, and the rest of the
v1.1 modes system) get their hardcoded v1.1 defaults — there's nothing to
preserve for them.
在 v1.0 中完全不存在的设置（`modes.rigor`、`qa.level`、
`docs.density`、`team.size`、`modes.story_granularity`，以及 v1.1 模式系统的其余部分）会采用其硬编码的 v1.1 默认值 —— 它们没有可供保留的内容。

**One value was renamed:** v1.0's `review-mode.txt: none` ("no director
reviews") becomes `modes.review_mode: solo` in v1.1, which is the same tier
under its new name. The converter maps it and calls it out in the migration
report's Warnings, so you'll see the rename rather than have it happen silently.
**有一个值被重命名了：** v1.0 中的 `review-mode.txt: none`（"无总监评审"）在 v1.1 中变为 `modes.review_mode: solo`，这是同一层级在新名称下的表示。转换脚本会映射它，并在迁移报告的"警告"中明确指出，因此你会看到这次重命名，而不是让它悄无声息地发生。

**Not migrated, on purpose:** `technical-preferences.md`'s Forbidden Patterns
and Allowed Libraries sections have no `project.yaml` equivalent. The
converter never deletes this file for that reason — see "Finalizing," below.
**有意不迁移：** `technical-preferences.md` 的"禁止模式"和"允许的库"两个章节在 `project.yaml` 中没有对应项。正因如此，转换脚本绝不会删除此文件 —— 参见下文"收尾"。

---

## Running the migration
## 执行迁移

The conversion is a tested script, not something the AI hand-edits — the
v1.1 plan rated data loss during migration as its highest-severity risk, and
prose migration can't be unit-tested the way a script can. `/adopt` drives
it for you, or you can run it yourself:
转换由经过测试的脚本完成，而不是由 AI 手工编辑 —— v1.1 计划将迁移期间的数据丢失列为最高严重程度的风险，而散文式迁移无法像脚本那样进行单元测试。`/adopt` 会为你驱动它，你也可以自行运行：

```bash
# 1. Preview — writes nothing, just reports what it would do
bash .claude/scripts/migrate-v1-config.sh --dry-run

# 2. Migrate — writes project.yaml + production/migration-report.md
#    Every legacy file is left in place, untouched.
bash .claude/scripts/migrate-v1-config.sh

# 3. Read the report before finalizing
cat production/migration-report.md

# 4. Finalize — deletes legacy files, ONLY after re-verifying each one's
#    value made it into project.yaml. Refuses (exit 4) and deletes nothing
#    on any mismatch.
bash .claude/scripts/migrate-v1-config.sh --finalize
```

Step 4 is optional and separate on purpose. Skipping it is completely fine —
every skill and hook falls back to the legacy files for any key
`project.yaml` doesn't have, so the two can coexist indefinitely. Run it when
you're confident `project.yaml` is correct and want one config file instead
of three.
步骤 4 是可选的，并且特意独立出来。跳过它完全没有问题 ——
对于 `project.yaml` 中不存在的任何键，每个技能和钩子都会回退到遗留文件，因此两者可以无限期共存。当你确信 `project.yaml` 正确、并希望用一个配置文件取代三个文件时，再运行它。

**`technical-preferences.md` is never deleted**, even with `--finalize` —
Forbidden Patterns and Allowed Libraries still live there and always will,
since v1.1 has no equivalent structure for them yet.
**`technical-preferences.md` 永远不会被删除**，即使使用 `--finalize` 也是如此 ——
"禁止模式"和"允许的库"仍在那里，并且将一直如此，因为 v1.1 目前还没有与之对应的结构。

### Reading `production/migration-report.md`
### 阅读 `production/migration-report.md`

The report has five sections:
该报告包含五个章节：

- **Source files detected** — which legacy files the converter found
- **检测到的源文件** —— 转换脚本找到了哪些遗留文件

- **Values preserved** — per source file, per setting, what was written to
  `project.yaml`
- **保留的值** —— 按源文件、按设置，列出写入了 `project.yaml` 的内容

- **Defaults applied** — new v1.1 settings that had nothing to migrate from
- **应用的默认值** —— 没有可供迁移来源的新 v1.1 设置

- **Warnings** — anything the converter couldn't parse cleanly (see below)
- **警告** —— 转换脚本无法干净解析的任何内容（见下文）

- **Manual review** — content it found but declined to guess at (e.g. custom
  sections in a forked `technical-preferences.md`)
- **人工复核** —— 它发现但拒绝猜测的内容（例如分叉的 `technical-preferences.md` 中的自定义章节）

---

## What can go wrong (and what the script does about it)
## 可能出现的问题（以及脚本如何应对）

| Situation | Behavior |
|---|---|
| A legacy file is malformed / unparsable | Warns per-file, leaves it alone, continues migrating everything else it *can* parse. `project.yaml` gets the values it could read plus defaults for the rest. |
| A parsed value doesn't match a v1.1 enum (e.g. a custom fork's `stage: Alpha`) | Written as-is with a warning comment, flagged for manual resolution — the converter does not silently coerce or drop it. |
| Both `project.yaml` **and** legacy files already exist | Refuses to run (exit code 3). Two sources of truth with no way to know which you last edited is not something the script will guess at — resolve it yourself first (decide which is authoritative, delete or rename the other). |
| Custom sections in a forked `technical-preferences.md` | Logged to the migration report as "not migrated — integrate manually." Nothing is silently dropped. |

| 情况 | 行为 |
|---|---|
| 遗留文件格式错误 / 无法解析 | 逐个文件发出警告，保持原样，并继续迁移其余*能*解析的内容。`project.yaml` 会得到能读取的值，其余项使用默认值。 |
| 解析出的值不匹配 v1.1 的枚举（例如自定义分叉中的 `stage: Alpha`） | 按原样写入并附警告注释，标记为需人工解决 —— 转换脚本不会悄悄强制转换或丢弃它。 |
| `project.yaml` **和**遗留文件同时存在 | 拒绝运行（退出码 3）。两个真相来源、又无法知道你最后编辑的是哪一个，这种情况脚本不会去猜 —— 请先自行解决（确定哪个是权威来源，删除或重命名另一个）。 |
| 分叉的 `technical-preferences.md` 中的自定义章节 | 记录到迁移报告中，标注为"未迁移 —— 请手动整合"。不会有任何内容被悄悄丢弃。 |

If you hit the split-brain case (both present), that usually means you
either ran `/start` on a project that also had old legacy files lying
around, or partially migrated by hand. Pick the one with your real values,
remove or back up the other, then re-run `--dry-run`.
如果你遇到"脑裂"情况（两者同时存在），通常意味着你要么在一个还留着旧遗留文件的项目上运行了 `/start`，要么手动做了部分迁移。选择包含你真实值的那一个，
删除或备份另一个，然后重新运行 `--dry-run`。

---

## After migrating
## 迁移之后

1. Spot-check `project.yaml` against your old `technical-preferences.md` —
   engine, naming, and performance values in particular.
1. 抽查 `project.yaml` 与你旧的 `technical-preferences.md` 是否一致 ——
   尤其是引擎、命名和性能方面的值。

2. Run `/settings` to see the effective config the way skills will read it.
2. 运行 `/settings`，以技能读取的方式查看生效配置。

3. Everything else in the framework works identically whether or not you've
   run `--finalize` — there's no rush.
3. 无论你是否运行过 `--finalize`，框架中的其他一切内容都以相同方式工作 —— 不必着急。

For the new settings that didn't exist in v1.0 (`modes.rigor` above all),
see the [Configuration section of the README](../README.md#configuration)
and the full spec in `.claude/docs/effects-map.md`.
关于 v1.0 中不存在的新设置（尤其是 `modes.rigor`），
参见 [README 的配置章节](../README.md#configuration)
以及 `.claude/docs/effects-map.md` 中的完整规范。
