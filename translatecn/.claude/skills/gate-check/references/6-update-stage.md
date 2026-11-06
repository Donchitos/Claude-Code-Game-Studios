# /gate-check — Section 6: Update Stage on PASS

# /gate-check — 第 6 节：在 PASS 时更新阶段

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/gate-check`。`SKILL.md` 指明了何时读取本文件；它已解析的设置，以及其后各标题下的规则，在此处仍然适用。

## 6. Update Stage on PASS

## 6. 在 PASS 时更新阶段

When the verdict is **PASS** and the user confirms they want to advance, write the
new stage to BOTH `project.yaml` and the legacy `production/stage.txt`.

当裁定为 **PASS** 且用户确认希望推进时，将新阶段同时写入 `project.yaml` 与旧式的 `production/stage.txt` 两者。

**On CONCERNS, the user may override — explicitly.** Do not offer the stage
write by default. If the user asks to advance anyway, list every concern and
ask: "The gate returned CONCERNS. Accept these risks — [list] — and may I update
`project.stage` in `project.yaml` to '[stage]' (and the legacy
`production/stage.txt`)?" Only on an explicit yes, add the `### Accepted Risks`
section to the gate report (each concern, accepted by the user, with the date)
and write the stage as below. **A FAIL is never overridden into a stage change, and
neither is NOT ASSESSED** — the blockers must be fixed, or the missing input
produced, and the gate re-run. That holds inside a CONCERNS verdict too: CONCERNS
outranks NOT ASSESSED in the verdict, but while any required check is NOT ASSESSED
the override is not offered. Name each such check and what would let it run.

**在 CONCERNS 下，用户可以覆盖——但必须明确。** 默认情况下不要主动提出阶段写入。若用户仍要求推进，则列出每一项顾虑并询问："The gate returned CONCERNS. Accept these risks — [list] — and may I update `project.stage` in `project.yaml` to '[stage]' (and the legacy `production/stage.txt`)?" 仅在得到明确的"是"之后，才向门禁报告添加 `### Accepted Risks` 一节（每项顾虑、由用户接受、附上日期），并按下文写入阶段。**FAIL 永远不会被覆盖为阶段变更，NOT ASSESSED 也一样**——必须修复阻塞项，或产出缺失的输入，然后重跑门禁。这一点在 CONCERNS 裁定内部同样成立：CONCERNS 在裁定中高于 NOT ASSESSED，但只要仍有任何必需检查为 NOT ASSESSED，就不会提供覆盖。点名每一项这样的检查，以及怎样才能让它运行。

### 6.1 Write the stage

### 6.1 写入阶段

After the yes, write both stage files with one command (quote a two-word stage):

在得到"是"之后，用一条命令写入两个阶段文件（两个词的阶段名要加引号）：

```bash
bash .claude/scripts/set-stage.sh "<new-stage>"
```

It sets `project.stage` in `project.yaml`: it edits the `stage:` line, adds a
`project:` block after `framework:` when there is none, or creates the file from
the minimal template when there is no `project.yaml`. It keeps comments, other
keys and line endings. It also writes the legacy `production/stage.txt`, so hooks
that have not migrated still work, then reads both files back. It never seeds
`modes.review_mode`: `modes.rigor` supplies that, and an explicit value would pin
the review mode whatever the project's rigor.

它设置 `project.yaml` 中的 `project.stage`：编辑 `stage:` 行，在无 `project:` 块时于 `framework:` 之后添加一个，或在没有 `project.yaml` 时用最小模板创建该文件。它保留注释、其他键与行尾。它还会写入旧式的 `production/stage.txt`，以便尚未迁移的 hook 仍可工作，然后回读两个文件。它从不预置 `modes.review_mode`：该值由 `modes.rigor` 提供，而显式设定值会把评审模式固定住，无论项目的严格度如何。

### 6.2 Verify both writes

### 6.2 核验两处写入

Show its `stage_yaml` and `stage_txt` rows. Exit 0 means both files hold the new
stage. Exit 4 means they disagree after writing: report the discrepancy to the
user and stop, because a split stage indicator corrupts future auto-detection.
Exit 5 means `project.yaml` has a layout the script will not edit (`project:` as
a one-line value): nothing was written, so say so and edit `project.yaml` with
the user's yes. Any other non-zero exit: report the message and stop.

展示其 `stage_yaml` 与 `stage_txt` 行。退出码 0 表示两个文件都持有新阶段。退出码 4 表示写入后二者不一致：向用户报告该差异并停止，因为分裂的阶段指示会破坏未来的自动检测。退出码 5 表示 `project.yaml` 的布局是脚本不会去编辑的（`project:` 为单行值）：什么都没写入，因此要说明这一点，并在取得用户同意后编辑 `project.yaml`。任何其他非零退出码：报告其消息并停止。

**Always ask before writing**: "Gate passed. May I update `project.stage` in `project.yaml` to 'Production' (and the legacy `production/stage.txt`)?" — on an accepted CONCERNS override, the explicit yes above is that ask.

**写入之前总是先询问**："Gate passed. May I update `project.stage` in `project.yaml` to 'Production' (and the legacy `production/stage.txt`)?"——在已接受 CONCERNS 覆盖的情形下，上文那次明确的"是"就是这次询问。

### 6.3 Rigor-fit check (advisory — never affects the verdict)

### 6.3 严格度适配检查（建议性——绝不影响裁定）

After the stage advance is confirmed, apply the raise trigger in
`.claude/docs/settings-guidance.md § 4`: if the new stage is **Production** (or
later) while the resolved `modes.workflow` is `minimal` (the `rigor: minimal`
posture, from the config block above), add one line:

在阶段推进得到确认之后，应用 `.claude/docs/settings-guidance.md § 4` 中的上调触发条件：若新阶段为 **Production**（或更晚）而已解析的 `modes.workflow` 为 `minimal`（即 `rigor: minimal` 姿态，来自上文配置块），则添加一行：

> "You're entering [stage] on `rigor: minimal` — most projects this size run
> `standard`. Revisit with `/settings modes.rigor=standard`?"

> "你正以 `rigor: minimal` 进入 [stage]——此规模的大多数项目都运行 `standard`。是否用 `/settings modes.rigor=standard` 重新考虑？"

Offer it **once**, here at the gate. Route to `/settings` — never change the
setting yourself.

在门禁这一处**仅提供一次**该提议。路由到 `/settings`——绝不要自行更改设置。

---
