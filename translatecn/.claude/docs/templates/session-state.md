# Active Session State — [project or branch]
# 活动会话状态 — [project 或 branch]

<!--
  HOW THIS FILE WORKS. Read this before editing it.

  This file has TWO regions and they are not interchangeable:

    1. The CHECKPOINT region below (STATUS + CHECKPOINT blocks) is the part
       machines read. session-start.sh shows it verbatim in the context, so it is
       BOUNDED BY CONSTRUCTION: keep it under ~25 lines. It is OVERWRITTEN on
       every update, never appended to.

    2. Everything after `<!-- /CHECKPOINT -->` is free-form narrative for humans
       and for a returning agent that wants detail. No hook ever injects it, so
       it may grow — but see Rotation below.

  Why the split exists: one append-only file doing both jobs grows without
  bound, and every consumer then reads a different slice of it: the top, the
  bottom, or a block nothing writes. They disagree because there is no contract
  to agree on. With the named regions, every consumer reads the same part.

  ROTATION. When the narrative below grows past ~200 lines, move it to
  `production/session-logs/` and start it fresh:
      bash .claude/scripts/rotate-session-state.sh
  Nothing is lost — and the commit history already records most of what the
  narrative repeats.

  ---------------------------------------------------------------------------

  本文件如何运作。编辑前请先阅读。

  本文件有两个区域，它们不可互换：

    1. 下方的 CHECKPOINT 区域（STATUS + CHECKPOINT 块）是机器读取的部分。
       session-start.sh 会在上下文中逐字显示它，因此它
       在构造上就是受限的：保持在约 25 行以内。它在每次更新时
       被覆盖，绝不追加。

    2. `<!-- /CHECKPOINT -->` 之后的所有内容都是自由形式的叙述，供人类
       以及想要细节的回归智能体阅读。没有任何 hook 会注入它，因此
       它可以增长 —— 但请见下方的轮换说明。

  为何要这样拆分：一个同时承担两项职责的仅追加文件会无限制地增长，
  于是每个消费者读取的切片都不同：顶部、底部，
  或一个没人写入的块。它们之所以不一致，是因为没有可达成一致的契约。
  有了具名区域后，每个消费者读取的都是同一部分。

  轮换。当下方叙述超过约 200 行时，将其移至
  `production/session-logs/` 并重新开始：
      bash .claude/scripts/rotate-session-state.sh
  不会丢失任何内容 —— 而且提交历史已经记录了叙述中重复的大部分内容。
-->

<!-- STATUS -->
Epic:
Feature:
Task:
<!-- /STATUS -->

<!-- CHECKPOINT -->
**Updated:** [YYYY-MM-DD]
**Branch:** `[branch]`
**Current task:** [一行 —— 正在积极处理的内容]
**Next step:** [一行 —— 紧接着的下一项行动，具体到可冷启动恢复]
**Blocked on:** [一行，或 `nothing`]
**Files in progress:** [路径，逗号分隔，或 `none`]
**Run result:** [`/dev-story` 将其 `Run result:` 行逐字写在此处，供 `/story-done` 读取；其他写入者省略此行]
**Open questions:** [每行一个，或 `none`]
<!-- /CHECKPOINT -->

---

## Notes
## 备注

[Free-form. Decisions and their rationale, what was tried and rejected, context
that would be expensive to reconstruct. Not machine-read — write for the person
or agent picking this up cold.]
[自由形式。决策及其理由、尝试过并被否决的方案、重建成本高昂的
上下文。非机器读取 —— 为冷启动接手的人
或智能体书写。]

<!--
  FIELD NOTES

  STATUS block
    Drives the status-line breadcrumb (`Combat System > Melee > Hitboxes`), and
    only at Production / Polish / Release stage. All three fields are optional —
    leave a field blank when it does not apply, and blank all three when there is
    no active focus. Do not delete the markers themselves — `statusline.sh`
    expects them to exist.

  CHECKPOINT block
    The recovery payload. `session-start.sh` shows it when a previous session
    left state, and again after a compaction (SessionStart runs then too).
    It reads THIS region and nothing else, which is what keeps the cost fixed
    no matter how long the narrative gets.

    Keep `Branch` current. This file is not committed, so it stays put when you
    switch branches; session-start.sh compares `Branch` with the branch you are
    on and adds one line when they differ.

    Write it so a cold reader can resume without reading anything else. "Current
    task: fixing the thing" is useless; "Current task: adding wall-jump to
    player_movement.gd" is not.

  ---------------------------------------------------------------------------

  字段说明

  STATUS 块
    驱动状态行面包屑（`Combat System > Melee > Hitboxes`），且
    仅在制作 / 打磨 / 发布阶段使用。三个字段都是可选的 ——
    不适用时留空，没有活动焦点时三个都留空。
    不要删除标记本身 —— `statusline.sh`
    期望它们存在。

  CHECKPOINT 块
    恢复载荷。当上一个会话留下状态时，`session-start.sh` 会显示它，在
    一次压缩之后也会再次显示（此时 SessionStart 同样会运行）。
    它只读取此区域，不读取其他内容，这正是无论叙述变得多长
    都能保持成本固定的原因。

    保持 `Branch` 为最新。本文件不提交，因此当你
    切换分支时它会留在原处；session-start.sh 会将 `Branch` 与你所在的
    分支比较，不一致时增加一行提示。

    书写时应让冷启动读者无需阅读其他内容即可恢复。“当前
    任务：修复那个东西”毫无用处；“当前任务：为
    player_movement.gd 添加蹬墙跳”则不然。
-->
